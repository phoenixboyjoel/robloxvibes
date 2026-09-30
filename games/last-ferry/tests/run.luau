--!strict
-- Runs the pure-logic test suite outside Roblox: `lune run tests/run.luau`

local process = require("@lune/process")

local TestLib = require("./TestLib")

require("./Rng.spec")
require("./Rules.spec")
require("./Generator.spec")
require("./Run.spec")
require("./Director.spec")
require("./Game.spec")

if not TestLib.summary() then
	process.exit(1)
end
