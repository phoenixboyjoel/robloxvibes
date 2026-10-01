--!strict
-- Server entry point: the only server Script (RunContext = Server). All other
-- server code is ModuleScripts in Services/ with a start() function, started
-- here in dependency order.

local ServerScriptService = game:GetService("ServerScriptService")

local StoryService = require(ServerScriptService.Services.StoryService)

StoryService.start()
