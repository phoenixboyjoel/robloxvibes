--!strict
--[[
	StoryService: conversations with NPCs tagged Config.StoryNpcTag.

	1. The player triggers the NPC's ProximityPrompt (a server-side event).
	2. The server checks the player is actually near it, then sends the node's
	   speaker, line, and option labels to that player only.
	3. The client sends back (nodeId, optionIndex). The server accepts it only
	   if it matches the node this player is on, then moves on or closes.

	The server is the only authority on where a player is in a conversation.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Dialogues = require(ServerScriptService.Story.Dialogues)
local Net = require(ReplicatedStorage.Shared.Net)

type Session = {
	dialogueId: string,
	nodeId: string,
	prompt: ProximityPrompt,
}

local StoryService = {}

local sessions: { [Player]: Session } = {}
local showRemote: RemoteEvent
local allowChoice: Net.RateLimiter

local function promptPosition(prompt: ProximityPrompt): Vector3?
	local parent = prompt.Parent
	if parent == nil then
		return nil
	elseif parent:IsA("BasePart") then
		return (parent :: BasePart).Position
	elseif parent:IsA("Attachment") then
		return (parent :: Attachment).WorldPosition
	elseif parent:IsA("Model") then
		return (parent :: Model):GetPivot().Position
	end
	return nil
end

-- Exploits can fire prompts from anywhere, so re-check distance on the server.
local function isInRange(player: Player, prompt: ProximityPrompt): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local target = promptPosition(prompt)
	if root == nil or not root:IsA("BasePart") or target == nil then
		return false
	end

	local limit = prompt.MaxActivationDistance + Config.InteractDistanceSlack
	return ((root :: BasePart).Position - target).Magnitude <= limit
end

local function show(player: Player, session: Session)
	local node = Dialogues[session.dialogueId].nodes[session.nodeId]

	local labels = {}
	for index, option in node.options do
		labels[index] = option.text
	end

	showRemote:FireClient(player, {
		nodeId = session.nodeId,
		speaker = node.speaker,
		text = node.text,
		options = labels,
	})
end

local function close(player: Player)
	sessions[player] = nil
	showRemote:FireClient(player, nil)
end

local function onTriggered(npc: Instance, prompt: ProximityPrompt, player: Player)
	if not isInRange(player, prompt) then
		return
	end

	local dialogueId = npc:GetAttribute(Config.DialogueAttribute)
	if type(dialogueId) ~= "string" or Dialogues[dialogueId] == nil then
		warn(`{npc:GetFullName()} needs a valid "{Config.DialogueAttribute}" string attribute`)
		return
	end

	local session: Session = {
		dialogueId = dialogueId,
		nodeId = Dialogues[dialogueId].start,
		prompt = prompt,
	}
	sessions[player] = session
	show(player, session)
end

local function onChoose(player: Player, nodeId: unknown, optionIndex: unknown)
	if not allowChoice(player) then
		return
	end

	local session = sessions[player]
	if session == nil or nodeId ~= session.nodeId then
		return -- stale (double click) or forged
	end
	if type(optionIndex) ~= "number" or optionIndex % 1 ~= 0 then
		return -- also rejects NaN and infinity
	end

	local node = Dialogues[session.dialogueId].nodes[session.nodeId]
	local option = node.options[optionIndex]
	if option == nil then
		return
	end

	if option.to == nil or not isInRange(player, session.prompt) then
		close(player)
		return
	end

	session.nodeId = option.to
	show(player, session)
end

local function createPrompt(npc: Instance, parent: Instance): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = npc.Name
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function setUpNpc(npc: Instance)
	local parent: Instance? = nil
	if npc:IsA("BasePart") or npc:IsA("Attachment") then
		parent = npc
	elseif npc:IsA("Model") then
		parent = (npc :: Model).PrimaryPart
	end
	if parent == nil then
		warn(`{npc:GetFullName()} is tagged {Config.StoryNpcTag} but has no Part, Attachment, or PrimaryPart`)
		return
	end

	local prompt = parent:FindFirstChildWhichIsA("ProximityPrompt") or createPrompt(npc, parent)
	prompt.Triggered:Connect(function(player)
		onTriggered(npc, prompt, player)
	end)
end

local function spawnDemoNpc()
	local part = Instance.new("Part")
	part.Name = "Keeper"
	part.Anchored = true
	part.Size = Vector3.new(2, 5, 2)
	part.Position = Vector3.new(0, 2.5, -12)
	part.Color = Color3.fromRGB(245, 205, 48)
	part:SetAttribute(Config.DialogueAttribute, "Lighthouse")
	part:AddTag(Config.StoryNpcTag)
	part.Parent = workspace
end

function StoryService.start()
	showRemote = Net.event(Config.Remotes.DialogueShow)
	local chooseRemote = Net.event(Config.Remotes.DialogueChoose)
	allowChoice = Net.rateLimiter(Config.ChoicesPerSecond, Config.ChoiceBurst)

	chooseRemote.OnServerEvent:Connect(onChoose)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)

	if Config.SpawnDemoNpc and #CollectionService:GetTagged(Config.StoryNpcTag) == 0 then
		spawnDemoNpc()
	end
	for _, npc in CollectionService:GetTagged(Config.StoryNpcTag) do
		setUpNpc(npc)
	end
	CollectionService:GetInstanceAddedSignal(Config.StoryNpcTag):Connect(setUpNpc)
end

return StoryService
