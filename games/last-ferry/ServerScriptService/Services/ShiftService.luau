--!strict
--[[
	ShiftService: the Roblox side of the shift. It gives the Director a Stage
	made of real things (passenger figures, the world, remotes) and a Clock on
	server time, and passes player actions through to it.

	The queue on the dock: the passenger at the window, and behind them up to
	#markers.queue more waiting in line. Everyone else is still out in the fog.
]]

local Players = game:GetService("Players")

local Config = require("../../ReplicatedStorage/Shared/Config")
local Net = require("../../ReplicatedStorage/Shared/Net")
local View = require("../../ReplicatedStorage/Shared/Types")
local Director = require("../Shift/Director")
local Types = require("../Shift/Types")
local PassengerService = require("./PassengerService")
local ProgressService = require("./ProgressService")
local WorldService = require("./WorldService")

local ACTIONS: { [string]: boolean } = {
	board = true,
	deny = true,
	page = true,
	continue = true,
	sync = true, -- a client asking for the current screen, e.g. right after joining
}

local ShiftService = {}

function ShiftService.start(markers: WorldService.Markers)
	local stateRemote = Net.event(Config.Remotes.State)
	local fxRemote = Net.event(Config.Remotes.Fx)
	local actionRemote = Net.event(Config.Remotes.Action)
	local allow = Net.rateLimiter(Config.ActionsPerSecond, Config.ActionBurst)
	local folder = WorldService.passengerFolder()
	local random = Random.new()

	local tonight: { Types.Passenger } = {}
	local figures: { [number]: Model } = {}
	local slots = #markers.queue
	-- Players whose game has loaded and asked for the screen. Only they count as present,
	-- so the first intro's timer doesn't run down while a phone is still loading.
	local synced: { [Player]: boolean } = {}
	Players.PlayerRemoving:Connect(function(player)
		synced[player] = nil
	end)

	-- The figure for tonight's passenger `index`, spawned out in the fog if it isn't yet.
	local function figure(index: number): Model?
		local passenger = tonight[index]
		if passenger == nil then
			return nil
		end
		local existing: Model? = figures[index]
		if existing then
			return existing
		end
		local jitter = Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-2, 2))
		local model = PassengerService.spawn(passenger, markers.spawn + jitter, Vector3.zAxis, folder)
		figures[index] = model
		return model
	end

	-- The passengers behind `index` step up into the queue slots.
	local function stepUp(index: number)
		for slot = 1, slots do
			local model = figure(index + slot)
			if model then
				task.spawn(PassengerService.walk, model, { markers.queue[slot] }, Config.WalkSpeed, Vector3.zAxis)
			end
		end
	end

	local function clearQueue()
		for _, model in figures do
			PassengerService.vanish(model, 0.8)
		end
		table.clear(figures)
		tonight = {}
	end

	local stage: Director.Stage = {
		actors = function(): { number }
			local ids = {}
			for _, player in Players:GetPlayers() do
				if synced[player] then
					table.insert(ids, player.UserId)
				end
			end
			return ids
		end,
		newSeed = function(): number
			return random:NextInteger(1, 2 ^ 31 - 2)
		end,
		broadcast = function(state: View.State)
			stateRemote:FireAllClients(state)
		end,
		fx = function(fx: View.Fx)
			fxRemote:FireAllClients(fx)
		end,
		recordEnding = ProgressService.recordEnding,

		resetWorld = WorldService.reset,
		setLanterns = WorldService.setLanterns,
		setFerryLoad = WorldService.setFerryLoad,
		setFlood = WorldService.setFlood,
		endingScene = WorldService.endingScene,

		beginQueue = function(passengers: { Types.Passenger })
			clearQueue()
			tonight = passengers
			stepUp(0)
		end,
		callToWindow = function(index: number)
			local model = figure(index)
			stepUp(index)
			if model then
				local passenger = tonight[index]
				if passenger.wet then
					PassengerService.footprints(model, markers.window, Config.WalkSpeed)
				end
				PassengerService.walk(model, { markers.window }, Config.WalkSpeed, Vector3.zAxis)
				PassengerService.setPuddle(model, passenger.wet)
				PassengerService.setShadowMark(model, if passenger.shadow then markers.lamp else nil)
			end
		end,
		sendOff = function(index: number, exit: Director.Exit)
			local model: Model? = figures[index]
			if model == nil then
				return
			end
			figures[index] = nil
			local path = if exit == "board"
				then markers.board
				elseif exit == "water" then markers.water
				else markers.away
			local passenger = tonight[index]
			task.spawn(function()
				PassengerService.setPuddle(model, false)
				PassengerService.setShadowMark(model, nil)
				if passenger and passenger.wet then
					-- A wet trail off to the side, where it can be seen.
					PassengerService.footprints(model, path[1], Config.WalkSpeed)
				end
				if PassengerService.walk(model, path, Config.WalkSpeed) then
					-- The drowned sink back into the harbor; everyone else fades into the fog.
					PassengerService.vanish(model, if exit == "water" then 2.5 else 1.2, exit == "water")
				end
			end)
		end,
		removePage = function(index: number)
			local model: Model? = figures[index]
			if model then
				PassengerService.removePage(model)
			end
		end,
		clearQueue = clearQueue,
	}

	local director = Director.new({
		now = function(): number
			return workspace:GetServerTimeNow()
		end,
		sleep = function(seconds: number)
			task.wait(seconds)
		end,
	}, stage)

	actionRemote.OnServerEvent:Connect(function(player: Player, kind: unknown, value: unknown)
		if not allow(player) or type(kind) ~= "string" or not ACTIONS[kind] then
			return
		end
		if kind == "sync" then
			synced[player] = true
			stateRemote:FireClient(player, Director.state(director))
			ProgressService.send(player)
			return
		end
		Director.action(director, player.UserId, kind, value)
	end)

	task.spawn(function()
		while true do
			Director.waitForPlayers(director)
			local ok, err = xpcall(Director.playRun, debug.traceback, director)
			if not ok then
				-- A bug shouldn't strand players in a frozen booth: start a fresh run.
				warn(`[Last Ferry] The shift hit an error and is starting over:\n{err}`)
				clearQueue()
				task.wait(2)
			end
		end
	end)
end

return ShiftService
