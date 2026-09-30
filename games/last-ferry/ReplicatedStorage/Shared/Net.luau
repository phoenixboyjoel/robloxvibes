--!strict
--[[
	Net: the one place remotes are created and looked up.

	The server creates each RemoteEvent on first use; clients wait for it.
	Server handlers receive the calling Player first. Treat every other argument
	as hostile: check its type and range, and check that this player is allowed
	to do this right now. See AGENTS.md, "Security rules".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

export type RateLimiter = (player: Player) -> boolean

local Net = {}

local function remotesFolder(): Instance
	if not RunService:IsServer() then
		return ReplicatedStorage:WaitForChild(FOLDER_NAME)
	end

	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

-- The server's clock (workspace:GetServerTimeNow()), or nil on a client that has been
-- disconnected, where it throws: for code that reads it every frame.
function Net.serverTime(): number?
	local ok, now = pcall(function(): number
		return workspace:GetServerTimeNow()
	end)
	return if ok then now else nil
end

-- Returns the RemoteEvent called `name`, creating it on the server if needed.
function Net.event(name: string): RemoteEvent
	local folder = remotesFolder()

	if not RunService:IsServer() then
		local remote = folder:WaitForChild(name)
		assert(remote:IsA("RemoteEvent"), `Remote {name} is not a RemoteEvent`)
		return remote :: RemoteEvent
	end

	local existing = folder:FindFirstChild(name)
	if existing then
		assert(existing:IsA("RemoteEvent"), `Remote {name} is not a RemoteEvent`)
		return existing :: RemoteEvent
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

-- Server only. Returns a per-player token bucket: on average `perSecond`
-- actions per second, with bursts of up to `burst`. Call it first in every
-- client -> server handler and drop the request when it returns false.
function Net.rateLimiter(perSecond: number, burst: number): RateLimiter
	assert(RunService:IsServer(), "Net.rateLimiter is server-only")

	local buckets: { [Player]: { tokens: number, updated: number } } = {}

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)

	return function(player: Player): boolean
		local now = os.clock()
		local bucket = buckets[player]
		if bucket == nil then
			bucket = { tokens = burst, updated = now }
			buckets[player] = bucket
		end

		bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.updated) * perSecond)
		bucket.updated = now

		if bucket.tokens < 1 then
			return false
		end
		bucket.tokens -= 1
		return true
	end
end

return Net
