--!strict
-- Client entry. Lives in ReplicatedStorage with RunContext Client, so it runs once per
-- player (a Client script under StarterPlayerScripts would run twice).

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local CameraController = require("./Controllers/CameraController")
local CrowdController = require("./Controllers/CrowdController")
local EffectsController = require("./Controllers/EffectsController")
local GlideController = require("./Controllers/GlideController")
local HudController = require("./Controllers/HudController")

-- Each start waits on something different (the world, the remotes), so none holds up the others.
GlideController.start()
EffectsController.start()
task.spawn(CameraController.start)
task.spawn(CrowdController.start)
task.spawn(HudController.start)
