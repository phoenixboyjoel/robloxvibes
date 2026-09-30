--!strict
--[[
	Small typed builders for the HUD. Every property is set through a typed
	assignment, so luau-lsp catches a misspelt property or a wrong value type
	before the game ever runs.
]]

local TweenService = game:GetService("TweenService")

local Theme = require("./Theme")

export type TextProps = {
	text: string?,
	font: Font?,
	size: number?,
	color: Color3?,
	xAlign: Enum.TextXAlignment?,
	yAlign: Enum.TextYAlignment?,
	wrap: boolean?,
	rich: boolean?,
	frameSize: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	autoSize: Enum.AutomaticSize?,
	order: number?,
	lineHeight: number?,
}

local Ui = {}

function Ui.frame(parent: Instance, name: string, size: UDim2, position: UDim2?, anchor: Vector2?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position or UDim2.new()
	frame.AnchorPoint = anchor or Vector2.zero
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

function Ui.corner(parent: Instance, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
end

function Ui.stroke(parent: Instance, color: Color3, thickness: number, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function Ui.padding(parent: Instance, top: number, right: number?, bottom: number?, left: number?)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingRight = UDim.new(0, right or top)
	padding.PaddingBottom = UDim.new(0, bottom or top)
	padding.PaddingLeft = UDim.new(0, left or right or top)
	padding.Parent = parent
end

function Ui.list(
	parent: Instance,
	direction: Enum.FillDirection,
	gap: number,
	horizontal: Enum.HorizontalAlignment?,
	vertical: Enum.VerticalAlignment?
): UIListLayout
	local list = Instance.new("UIListLayout")
	list.FillDirection = direction
	list.Padding = UDim.new(0, gap)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left
	list.VerticalAlignment = vertical or Enum.VerticalAlignment.Top
	list.Parent = parent
	return list
end

-- A dark rounded panel that swallows clicks, so dragging on it doesn't turn the camera.
function Ui.panel(parent: Instance, name: string, size: UDim2, position: UDim2?, anchor: Vector2?): Frame
	local panel = Ui.frame(parent, name, size, position, anchor)
	panel.BackgroundColor3 = Theme.Colors.panel
	panel.BackgroundTransparency = 0.12
	panel.Active = true
	Ui.corner(panel, UDim.new(0, 10))
	Ui.stroke(panel, Theme.Colors.line, 1, 0.3)
	return panel
end

-- Typed as TextLabel so every property below is checked. TextButton has the same text
-- properties, so buttons go through here too (see Ui.button).
local function applyText(label: TextLabel, props: TextProps)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = props.text or ""
	label.FontFace = props.font or Theme.Fonts.body
	label.TextSize = props.size or 18
	label.TextColor3 = props.color or Theme.Colors.text
	label.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
	label.TextYAlignment = props.yAlign or Enum.TextYAlignment.Center
	label.TextWrapped = props.wrap == true
	label.RichText = props.rich == true
	label.Size = props.frameSize or UDim2.new(1, 0, 0, math.ceil((props.size or 18) * 1.3))
	label.Position = props.position or UDim2.new()
	label.AnchorPoint = props.anchor or Vector2.zero
	label.AutomaticSize = props.autoSize or Enum.AutomaticSize.None
	label.LayoutOrder = props.order or 0
	label.LineHeight = props.lineHeight or 1
end

function Ui.label(parent: Instance, name: string, props: TextProps): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	applyText(label, props)
	label.Parent = parent
	return label
end

export type ButtonStyle = {
	fill: Color3,
	text: Color3?,
	font: Font?,
	textSize: number?,
}

-- A solid rounded button with a hover and press response.
function Ui.button(parent: Instance, name: string, text: string, size: UDim2, style: ButtonStyle): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	applyText((button :: any) :: TextLabel, {
		text = text,
		font = style.font or Theme.Fonts.title,
		size = style.textSize or 22,
		color = style.text or Theme.Colors.text,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = size,
	})
	button.BackgroundTransparency = 0
	button.BackgroundColor3 = style.fill
	button.AutoButtonColor = false
	button.Selectable = true
	Ui.corner(button, UDim.new(0, 10))
	local stroke = Ui.stroke(button, style.fill:Lerp(Color3.new(1, 1, 1), 0.25), 1.5, 0.2)

	local base = style.fill
	local function tint(color: Color3)
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = color }):Play()
	end
	button.MouseEnter:Connect(function()
		if button.Interactable then
			tint(base:Lerp(Color3.new(1, 1, 1), 0.12))
		end
	end)
	button.MouseLeave:Connect(function()
		tint(base)
	end)
	button.MouseButton1Down:Connect(function()
		if button.Interactable then
			tint(base:Lerp(Color3.new(0, 0, 0), 0.2))
		end
	end)
	button.MouseButton1Up:Connect(function()
		tint(base)
	end)
	button:GetPropertyChangedSignal("Interactable"):Connect(function()
		button.BackgroundTransparency = if button.Interactable then 0 else 0.55
		button.TextTransparency = if button.Interactable then 0 else 0.45
		stroke.Transparency = if button.Interactable then 0.2 else 0.7
	end)
	button.Parent = parent
	return button
end

-- "12s" style countdown text from a server-time deadline.
function Ui.secondsLeft(deadline: number?): number
	if deadline == nil then
		return 0
	end
	return math.max(0, math.ceil(deadline - workspace:GetServerTimeNow()))
end

return Ui
