--!strict
--[[
	DialogueController: draws whatever dialogue node the server sends and
	reports the option the player picks. It never decides story state; the
	server validates every choice (see StoryService).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

type Payload = {
	nodeId: string,
	speaker: string,
	text: string,
	options: { string },
}

local DialogueController = {}

local gui: ScreenGui
local body: TextLabel
local optionList: Frame
local chooseRemote: RemoteEvent

local function buildGui()
	gui = Instance.new("ScreenGui")
	gui.Name = "Dialogue"
	gui.ResetOnSpawn = false
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -24)
	panel.Size = UDim2.new(1, -32, 0, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	panel.BackgroundTransparency = 0.15
	panel.Parent = gui

	local maxWidth = Instance.new("UISizeConstraint")
	maxWidth.MaxSize = Vector2.new(720, math.huge)
	maxWidth.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	body = Instance.new("TextLabel")
	body.Name = "Body"
	body.LayoutOrder = 1
	body.Size = UDim2.fromScale(1, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextColor3 = Color3.new(1, 1, 1)
	body.TextSize = 20
	body.Parent = panel

	optionList = Instance.new("Frame")
	optionList.Name = "Options"
	optionList.LayoutOrder = 2
	optionList.Size = UDim2.fromScale(1, 0)
	optionList.AutomaticSize = Enum.AutomaticSize.Y
	optionList.BackgroundTransparency = 1
	optionList.Parent = panel

	local optionLayout = Instance.new("UIListLayout")
	optionLayout.Padding = UDim.new(0, 6)
	optionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionLayout.Parent = optionList
end

local function render(payload: Payload?)
	for _, child in optionList:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	if payload == nil then
		gui.Enabled = false
		return
	end

	body.Text = `{payload.speaker}: {payload.text}`

	for index, label in payload.options do
		local button = Instance.new("TextButton")
		button.Name = `Option{index}`
		button.LayoutOrder = index
		button.Size = UDim2.new(1, 0, 0, 44) -- 44px keeps it tappable on phones
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 62)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextSize = 18
		button.Text = `{index}. {label}`
		button.Parent = optionList

		local nodeId = payload.nodeId
		button.Activated:Connect(function()
			chooseRemote:FireServer(nodeId, index)
		end)
	end

	gui.Enabled = true
end

function DialogueController.start()
	buildGui()
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	chooseRemote = Net.event(Config.Remotes.DialogueChoose)
	local showRemote = Net.event(Config.Remotes.DialogueShow)
	showRemote.OnClientEvent:Connect(function(payload: Payload?)
		render(payload)
	end)
end

return DialogueController
