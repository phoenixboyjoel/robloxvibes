--!strict
--[[
	ProgressService: which endings each player has found, kept in a DataStore
	and shown on the intro and ending screens.

	Saving happens once per ending, with UpdateAsync merging into whatever is
	stored (a union of endings), so a failed load or a second server can never
	wipe progress. Nothing is saved on leave because nothing is ever unsaved.

	In Studio without "Enable Studio Access to API Services", the DataStore is
	unavailable: progress then lasts for the session only, with one warning.

	Badges: create them on the Creator Dashboard and put their ids in BADGES.
	0 means "no badge yet" and is skipped.
]]

local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require("../../ReplicatedStorage/Shared/Config")
local Net = require("../../ReplicatedStorage/Shared/Net")
local View = require("../../ReplicatedStorage/Shared/Types")
local Content = require("../Shift/Content")

type Data = {
	endings: { [string]: boolean },
	runs: number,
}

local STORE_NAME = "LastFerryProgress_v1"
local ATTEMPTS = 3

local BADGES: { [string]: number } = {
	CLEAN_SHIFT = 0,
	MARA_HOME = 0,
	LOW_IN_THE_WATER = 0,
	THE_LEDGER = 0,
}

local ProgressService = {}

local store: DataStore? = nil
local progress: { [Player]: Data } = {}
local remote: RemoteEvent

local function key(player: Player): string
	return `u_{player.User.Id}`
end

local function blank(): Data
	return { endings = {}, runs = 0 }
end

-- Accepts only the shape we write, so a corrupted or hand-edited entry can't break a join.
local function sanitize(raw: unknown): Data
	local data = blank()
	if type(raw) ~= "table" then
		return data
	end
	local record = raw :: { [unknown]: unknown }
	local endings = record.endings
	if type(endings) == "table" then
		for id in endings :: { [unknown]: unknown } do
			if type(id) == "string" and Content.Endings[id] then
				data.endings[id] = true
			end
		end
	end
	local runs = record.runs
	if type(runs) == "number" and runs >= 0 then
		data.runs = math.floor(runs)
	end
	return data
end

local function merge(stored: Data, extra: Data): Data
	local merged = blank()
	for id in stored.endings do
		merged.endings[id] = true
	end
	for id in extra.endings do
		merged.endings[id] = true
	end
	merged.runs = math.max(stored.runs, extra.runs)
	return merged
end

-- Retries a yielding DataStore call with a short backoff. Returns ok and the result.
local function retry<T>(label: string, call: () -> T): (boolean, T?)
	local lastError: unknown = nil
	for attempt = 1, ATTEMPTS do
		local ok, result = pcall(call)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < ATTEMPTS then
			task.wait(attempt * 2)
		end
	end
	warn(`[Last Ferry] {label} failed after {ATTEMPTS} tries: {lastError}`)
	return false, nil
end

local function send(player: Player)
	local data = progress[player]
	if data == nil or player.Parent == nil then
		return
	end
	local found: { string } = {}
	for _, id in Content.EndingOrder do
		if data.endings[id] then
			table.insert(found, Content.Endings[id].title)
		end
	end
	local payload: View.Progress = { found = found, total = #Content.EndingOrder }
	remote:FireClient(player, payload)
end

local function load(player: Player)
	local data = blank()
	local dataStore = store
	if dataStore then
		local ok, raw = retry(`Loading progress for {player.Name}`, function()
			return dataStore:GetAsync(key(player))
		end)
		if ok then
			data = sanitize(raw)
		elseif RunService:IsStudio() then
			-- Almost always Studio without API access. Stop trying for this session.
			store = nil
			warn(
				"[Last Ferry] Progress won't be saved in this Studio session. To test saving, turn on "
					.. "Game Settings > Security > Enable Studio Access to API Services."
			)
		end
	end
	if player.Parent == nil then
		return
	end
	-- Anything found while the load was in flight is kept.
	local current = progress[player]
	progress[player] = if current then merge(data, current) else data
	send(player)
end

local function award(player: Player, ending: string)
	local badge = BADGES[ending]
	if badge == nil or badge == 0 then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			BadgeService:AwardBadgeAsync(player.User, badge)
		end)
		if not ok then
			warn(`[Last Ferry] Badge {ending} for {player.Name} failed: {err}`)
		end
	end)
end

local function save(player: Player, found: { string })
	local dataStore = store
	if dataStore == nil then
		return
	end
	local update = blank()
	for _, id in found do
		update.endings[id] = true
	end
	task.spawn(function()
		retry(`Saving progress for {player.Name}`, function()
			return dataStore:UpdateAsync(key(player), function(old: unknown)
				local stored = sanitize(old)
				local merged = merge(stored, update)
				merged.runs = stored.runs + 1
				return merged
			end)
		end)
	end)
end

-- Every player in the server when an ending plays gets it.
function ProgressService.recordEnding(ending: string, secret: boolean)
	local found = { ending }
	if secret then
		table.insert(found, "THE_LEDGER")
	end
	for _, player in Players:GetPlayers() do
		local data = progress[player] or blank()
		progress[player] = data
		for _, id in found do
			data.endings[id] = true
			award(player, id)
		end
		data.runs += 1
		send(player)
		save(player, found)
	end
end

function ProgressService.send(player: Player)
	send(player)
end

function ProgressService.start()
	remote = Net.event(Config.Remotes.Progress)

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn(`[Last Ferry] Progress won't be saved this session (DataStore unavailable): {result}`)
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(load, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		progress[player] = nil
	end)
end

return ProgressService
