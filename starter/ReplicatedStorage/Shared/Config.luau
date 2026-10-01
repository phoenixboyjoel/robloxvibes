--!strict
-- Tunable constants shared by server and client.
-- Everything in ReplicatedStorage is readable by players, so keep secrets and
-- unreleased story content on the server (ServerScriptService or ServerStorage).

local Config = {
	-- Tag any Part, Attachment, or Model (with a PrimaryPart) to make it talkable.
	StoryNpcTag = "StoryNPC",
	-- String attribute on the tagged instance naming a dialogue in Story/Dialogues.
	DialogueAttribute = "DialogueId",

	Remotes = {
		DialogueShow = "DialogueShow", -- server -> client
		DialogueChoose = "DialogueChoose", -- client -> server
	},

	-- Studs allowed beyond a prompt's MaxActivationDistance, to absorb latency.
	InteractDistanceSlack = 6,
	-- Rate limit for dialogue choices, per player.
	ChoicesPerSecond = 4,
	ChoiceBurst = 4,

	-- Spawn a talkable demo NPC when the place has none, so a blank Baseplate
	-- proves the whole loop works. Turn off once real NPCs exist.
	SpawnDemoNpc = true,
}

return Config
