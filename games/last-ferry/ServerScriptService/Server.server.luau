--!strict
-- Server entry: build the harbor, open the pier to the players, then run shifts.

local CrewService = require("./Services/CrewService")
local ProgressService = require("./Services/ProgressService")
local ShiftService = require("./Services/ShiftService")
local WorldService = require("./Services/WorldService")

local markers = WorldService.build()
ProgressService.start()
CrewService.start(markers)
ShiftService.start(markers)
