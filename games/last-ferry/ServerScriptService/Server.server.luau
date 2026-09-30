--!strict
-- Server entry: build the harbor, then open the ticket booth.

local Players = game:GetService("Players")

local ProgressService = require("./Services/ProgressService")
local ShiftService = require("./Services/ShiftService")
local WorldService = require("./Services/WorldService")

-- Players watch from inside the booth, so nobody needs an avatar on the dock. The project
-- file sets this too; this covers a place synced without it.
Players.CharacterAutoLoads = false
for _, player in Players:GetPlayers() do
	if player.Character then
		player.Character:Destroy()
	end
end

local markers = WorldService.build()
ProgressService.start()
ShiftService.start(markers)
