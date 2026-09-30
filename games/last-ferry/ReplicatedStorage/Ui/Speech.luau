--!strict
--[[
	Speech: what a passenger says, in a bubble over their head drawn to look just
	like Roblox's own chat bubble (BubbleChatConfiguration's defaults: white,
	rounded, GothamSSm Medium 16 in dark grey, with Roblox's tail pointing at them).

	It's ours rather than Roblox's (TextChatService:DisplayBubble) because on the
	last night what they say is a rule, so it has to be readable for as long as
	they're at the window, on every device. Roblox's bubbles fade after
	BubbleDuration, the wall above the window can hide them from the back of the
	booth, and consoles don't show Roblox's chat at all. This one stays up until
	they leave, is drawn over walls, and works everywhere, bigger on a TV.
]]

local GuiService = game:GetService("GuiService")

local Ui = require("./Ui")

export type Speech = {
	-- Shows `text` over `model` until release() or clear(), or for `seconds` if given.
	say: (model: Model, text: string, seconds: number?) -> (),
	-- The passenger left the window: a line with no time limit fades shortly after.
	release: () -> (),
	clear: () -> (),
	billboard: BillboardGui,
}

local BUBBLE = Color3.fromRGB(250, 250, 250)
local INK = Color3.fromRGB(57, 59, 61)
local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local CARET = "rbxasset://textures/ui/InGameChat/Caret.png"
local LINGER = 1.5 -- seconds a line stays up once they've left the window

local Speech = {}

-- How far above `root` the top of `model` is, as Roblox works it out for a bubble.
local function heightAbove(model: Model, root: BasePart): number
	local box, size = model:GetBoundingBox()
	return size.Y / 2 - box:PointToObjectSpace(root.Position).Y
end

function Speech.new(parent: Instance): Speech
	local tv = GuiService:IsTenFootInterface()
	local textSize = if tv then 24 else 16
	local maxWidth = if tv then 420 else 300
	-- Narrower on a phone, where there's less room between the top bar and a head.
	local function widest(): number
		local viewport = workspace.CurrentCamera.ViewportSize
		return if not tv and math.min(viewport.X, viewport.Y) <= 500 then 260 else maxWidth
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PassengerSpeech"
	billboard.Size = UDim2.fromOffset(maxWidth + 40, 240)
	-- Sitting on a point just above the head, as Roblox places bubbles, but closer: Roblox
	-- leaves a stud for a name tag, and passengers have none. So it stays clear of the top
	-- bar on a phone.
	billboard.SizeOffset = Vector2.new(0, 0.5)
	billboard.StudsOffset = Vector3.new(0, 0.4, 0.1)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Enabled = false
	billboard.Parent = parent

	local stack = Ui.frame(billboard, "Stack", UDim2.new(), UDim2.fromScale(0.5, 1), Vector2.new(0.5, 1))
	stack.AutomaticSize = Enum.AutomaticSize.XY
	-- UICorner leaves a pixel's gap under the bubble; Roblox closes it the same way.
	Ui.list(stack, Enum.FillDirection.Vertical, -1, Enum.HorizontalAlignment.Center)

	local bubble = Ui.frame(stack, "Bubble", UDim2.new())
	bubble.AutomaticSize = Enum.AutomaticSize.XY
	bubble.BackgroundColor3 = BUBBLE
	bubble.BackgroundTransparency = 0.1
	bubble.LayoutOrder = 1
	Ui.corner(bubble, UDim.new(0, 12))
	Ui.padding(bubble, 8, 16, 8, 16)
	local line = Ui.label(bubble, "Line", {
		font = FONT,
		size = textSize,
		color = INK,
		wrap = true,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(),
	})

	-- Each line is measured wrapped at the widest a bubble goes, and the bubble fits it:
	-- how Roblox sizes its own bubbles (a hidden label's TextBounds).
	local sizer = Instance.new("ScreenGui")
	sizer.Name = "SpeechSizer"
	sizer.Enabled = false
	sizer.ResetOnSpawn = false
	sizer.Parent = parent
	local measure = Ui.label(sizer, "Measure", {
		font = FONT,
		size = textSize,
		wrap = true,
		frameSize = UDim2.fromOffset(maxWidth, 10000),
	})

	local caret = Instance.new("ImageLabel")
	caret.Name = "Caret"
	caret.Size = if tv then UDim2.fromOffset(14, 9) else UDim2.fromOffset(9, 6)
	caret.BackgroundTransparency = 1
	caret.Image = CARET
	caret.ImageColor3 = BUBBLE
	caret.ImageTransparency = 0.1
	caret.LayoutOrder = 2
	caret.Parent = stack

	local token = 0
	local timed = false
	local watch: RBXScriptConnection? = nil

	local function clear()
		token += 1
		if watch then
			watch:Disconnect()
			watch = nil
		end
		billboard.Enabled = false
	end

	local function hideAfter(seconds: number)
		token += 1
		local mine = token
		task.delay(seconds, function()
			if token == mine then
				clear()
			end
		end)
	end

	return {
		billboard = billboard,
		say = function(model: Model, text: string, seconds: number?)
			local root = model:FindFirstChild("HumanoidRootPart")
			if not (root and root:IsA("BasePart")) then
				return
			end
			clear()
			measure.Size = UDim2.fromOffset(widest(), 10000)
			measure.Text = text
			local bounds = measure.TextBounds
			line.Text = text
			line.Size = UDim2.fromOffset(math.ceil(bounds.X), math.ceil(bounds.Y))
			billboard.Adornee = root
			billboard.StudsOffsetWorldSpace = Vector3.new(0, heightAbove(model, root), 0)
			billboard.Enabled = true
			timed = seconds ~= nil
			if seconds then
				hideAfter(seconds)
			end
			-- Gone with them if they're taken away before it's over.
			watch = model.AncestryChanged:Connect(function()
				if not model:IsDescendantOf(workspace) then
					clear()
				end
			end)
		end,
		release = function()
			if billboard.Enabled and not timed then
				timed = true
				hideAfter(LINGER)
			end
		end,
		clear = clear,
	}
end

return Speech
