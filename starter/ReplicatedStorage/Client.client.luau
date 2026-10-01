--!strict
-- Client entry point: the only client Script. It is a Script with
-- RunContext = Client placed in ReplicatedStorage, so it runs exactly once per
-- player. (In StarterPlayerScripts it would run twice: the original and the
-- copy.) All other client code is ModuleScripts in Controllers/.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = ReplicatedStorage:WaitForChild("Controllers")
local DialogueController = require(Controllers:WaitForChild("DialogueController"))

DialogueController.start()
