--!strict
--[[
	Small typed builders for the HUD, in Roblox's chunky house style: rounded
	corners, thick dark outlines, a hard drop shadow (UIShadow), a light-to-dark
	gloss (UIGradient) and white bold type with a dark stroke. Every property is
	set through a typed assignment, so luau-lsp catches a misspelt property or a
	wrong value type before the game ever runs.
]]

local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Net = require("../Shared/Net")
local Sfx = require("./Sfx")
local Theme = require("./Theme")

local C = Theme.Colors

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
	-- Kept from growing past `size` at the player's Text Size setting (see Ui.holdTextSize)?
	-- By default, only if its box can't make room for bigger text: it doesn't grow the way
	-- its text needs, down for text that wraps and across for text that doesn't.
	hold: boolean?,
	-- Held at this size rather than `size`: a little bigger, where its box has room.
	holdAt: number?,
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

-- A dark outline round the letters of a label or button, so white text reads on
-- anything: fog, lamplight or a bright button.
function Ui.textStroke(label: GuiObject, thickness: number?, color: Color3?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = color or C.outline
	stroke.Thickness = thickness or 2
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return stroke
end

-- A hard drop shadow straight below, in Roblox's cartoon style (no blur).
function Ui.shadow(parent: GuiObject, depth: number, color: Color3?): UIShadow
	local shadow = Instance.new("UIShadow")
	shadow.Offset = UDim2.fromOffset(0, depth)
	shadow.Color = color or C.shadow
	shadow.BlurRadius = UDim.new(0, 0)
	shadow.Transparency = 0
	shadow.Parent = parent
	return shadow
end

-- Lighter at the top, darker at the bottom: the gloss on chunky Roblox buttons.
function Ui.gloss(parent: GuiObject, strength: number?): UIGradient
	local dark = 1 - (strength or 0.22)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(dark, dark, dark))
	gradient.Parent = parent
	return gradient
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

-- A dark rounded panel with a thick outline and a hard shadow. It swallows clicks, so
-- dragging on it doesn't turn the camera.
function Ui.panel(parent: Instance, name: string, size: UDim2, position: UDim2?, anchor: Vector2?): Frame
	local panel = Ui.frame(parent, name, size, position, anchor)
	panel.BackgroundColor3 = C.panel
	panel.BackgroundTransparency = 0.06
	panel.Active = true
	Ui.corner(panel, UDim.new(0, 14))
	Ui.stroke(panel, C.outline, 3)
	Ui.gloss(panel, 0.3)
	Ui.shadow(panel, 5)
	return panel
end

-- Players can have Roblox draw all text bigger (GuiService.PreferredTextSize, the Text Size
-- setting): 4, 10 or 14 pixels bigger, as measured. The text meant for reading wraps, or
-- grows its box, to make room. Text in a box that can't grow would spill out of it, so it's
-- held at its size by a UITextSizeConstraint, which that setting never draws text past
-- (Roblox's accessibility docs). As in Roblox's own Foundation icons, the constraint is
-- there only while the player has asked for bigger text: at the usual size nothing is held.
--
-- Roblox's docs don't say whether a constraint holds text on screen, after any UIScale (as
-- a DevForum bug report has it: "UIScale/UITextSizeConstraint Precedence"), or in the
-- label's own pixels. So the game asks Roblox when it starts (Ui.findWhereTextIsHeld), and
-- until then goes by the report. On screen, a label is held at its size times the layout
-- scales above it (Ui.layoutScale), worked out again when the label moves and whenever one
-- of those scales changes (Ui.refreshHeldText); in its own pixels, at its size.
--
-- The size is fixed here: change the label's TextSize later and it's still held at this.
type Held = { constraint: UITextSizeConstraint, size: number }
local held: { [Instance]: Held } = setmetatable({}, { __mode = "k" }) :: any
-- The UIScales that lay the HUD out at a size for the screen, as against the ones that
-- animate something (a button's bounce, the stamp's pop): held text follows only these.
local layoutScales: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
-- Whether Roblox holds text on screen, after any UIScale (or in the label's own pixels).
local heldOnScreen = true

-- How much the layout scales above an object scale it.
local function scaleOf(object: Instance): number
	local scale = 1
	local cursor: Instance? = object
	while cursor and not cursor:IsA("LayerCollector") do
		local uiScale = cursor:FindFirstChildOfClass("UIScale")
		if uiScale and layoutScales[uiScale] then
			scale *= uiScale.Scale
		end
		cursor = cursor.Parent
	end
	return scale
end

local function applyHold(object: Instance, entry: Held)
	if not object:IsDescendantOf(game) then
		return -- not shown yet (it's held once it is), or destroyed
	elseif GuiService.PreferredTextSize == Enum.PreferredTextSize.Medium then
		entry.constraint.Parent = nil
	else
		-- A whole number of pixels, rounded down: never bigger than the box was made for.
		local scale = if heldOnScreen then scaleOf(object) else 1
		entry.constraint.MaxTextSize = math.max(1, math.floor(entry.size * scale + 0.001))
		entry.constraint.Parent = object
	end
end

function Ui.holdTextSize(object: TextLabel | TextButton, size: number)
	local entry: Held = { constraint = Instance.new("UITextSizeConstraint"), size = size }
	held[object] = entry
	applyHold(object, entry)
	object.AncestryChanged:Connect(function()
		applyHold(object, entry)
	end)
end

-- Holds every held label again, for the layout scales above it: call it after changing one.
function Ui.refreshHeldText()
	for object, entry in held do
		applyHold(object, entry)
	end
end
GuiService:GetPropertyChangedSignal("PreferredTextSize"):Connect(Ui.refreshHeldText)

-- A UIScale that lays `parent` and everything in it out at a size for the screen (the HUD's,
-- the top bar row's): held text follows it. After changing its Scale, call
-- Ui.refreshHeldText.
function Ui.layoutScale(parent: Instance): UIScale
	local scale = Instance.new("UIScale")
	layoutScales[scale] = true
	scale.Parent = parent
	return scale
end

-- Where Roblox holds text: on screen, after any UIScale, or in the label's own pixels.
function Ui.setTextHeldOnScreen(onScreen: boolean)
	if onScreen ~= heldOnScreen then
		heldOnScreen = onScreen
		Ui.refreshHeldText()
	end
end

-- The probe's text size and the UIScale it's under: far enough apart that the two answers
-- can't be taken for each other at any Text Size (see below).
local PROBE_SIZE = 30
local PROBE_SCALE = 3

export type HeldWhere = "screen" | "label"

-- Asks Roblox where it holds text: "screen" if a UITextSizeConstraint holds text on screen,
-- after any UIScale; "label" if in the label's own pixels; nil if it can't tell. Also returns
-- what it measured. It waits a frame or more for Roblox to lay things out.
--
-- It measures labels no one sees, in pairs, one held and one not, by their TextBounds (each
-- pair in the same pixels, whichever pixels Roblox gives TextBounds in):
-- - held at half their size: drawn half as wide or less (with a bigger Text Size, less).
--   If not, TextBounds don't show what a constraint does, and it can't tell;
-- - under a UIScale of 3, held at their own size: drawn a third as wide or less if Roblox
--   holds text on screen (30 px on screen is 10 of theirs); if in their own pixels, as wide,
--   or at the biggest Text Size still over two thirds as wide (30 against 30 + 14).
function Ui.findWhereTextIsHeld(parent: Instance): (HeldWhere?, number?)
	local gui = Instance.new("ScreenGui")
	gui.Name = "LastFerryTextCheck"
	gui.ResetOnSpawn = false
	local function probe(where: Instance, name: string, max: number?): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.fromOffset(10, 10)
		label.BackgroundTransparency = 1
		label.TextTransparency = 1
		label.FontFace = Theme.Fonts.body
		label.TextSize = PROBE_SIZE
		label.Text = "MMMM"
		if max then
			local constraint = Instance.new("UITextSizeConstraint")
			constraint.MaxTextSize = max
			constraint.Parent = label
		end
		label.Parent = where
		return label
	end
	local free = probe(gui, "Free")
	local halved = probe(gui, "Halved", PROBE_SIZE / 2)
	local scaled = Ui.frame(gui, "Scaled", UDim2.fromOffset(10, 10))
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = PROBE_SCALE
	uiScale.Parent = scaled
	local scaledFree = probe(scaled, "Free")
	local scaledHeld = probe(scaled, "Held", PROBE_SIZE)
	gui.Parent = parent

	-- How wide a held label is drawn, as a share of how wide one that isn't is, once both
	-- have been measured.
	local function share(heldLabel: TextLabel, freeLabel: TextLabel): number?
		local heldWidth, freeWidth = heldLabel.TextBounds.X, freeLabel.TextBounds.X
		return if heldWidth > 0 and freeWidth > 0 then heldWidth / freeWidth else nil
	end
	local answer: HeldWhere? = nil
	local measured: number? = nil
	local last: HeldWhere? = nil
	for _ = 1, 30 do
		task.wait()
		-- Once the UIScale is laid out: the same answer two frames running.
		if scaled.AbsoluteSize.X >= 10 * PROBE_SCALE - 0.5 then
			local seen, underScale = share(halved, free), share(scaledHeld, scaledFree)
			local now: HeldWhere? = nil
			if seen and underScale and seen < 0.75 then
				now = if underScale < 0.5 then "screen" else "label"
			end
			measured = underScale
			if now ~= nil and now == last then
				answer = now
				break
			end
			last = now
		end
	end
	gui:Destroy()
	return answer, measured
end

-- Typed as TextLabel so every property below is checked. TextButton has the same text
-- properties, so the tab buttons go through here too.
local function applyText(label: TextLabel, props: TextProps)
	local size = props.size or 18
	local autoSize = props.autoSize or Enum.AutomaticSize.None
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = props.text or ""
	label.FontFace = props.font or Theme.Fonts.body
	label.TextSize = size
	label.TextColor3 = props.color or C.text
	label.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
	label.TextYAlignment = props.yAlign or Enum.TextYAlignment.Center
	label.TextWrapped = props.wrap == true
	label.RichText = props.rich == true
	label.Size = props.frameSize or UDim2.new(1, 0, 0, math.ceil(size * 1.3))
	label.Position = props.position or UDim2.new()
	label.AnchorPoint = props.anchor or Vector2.zero
	label.AutomaticSize = autoSize
	label.LayoutOrder = props.order or 0
	label.LineHeight = props.lineHeight or 1
	local hold = props.hold
	if hold == nil then
		local across = autoSize == Enum.AutomaticSize.X or autoSize == Enum.AutomaticSize.XY
		local down = autoSize == Enum.AutomaticSize.Y or autoSize == Enum.AutomaticSize.XY
		hold = if props.wrap == true then not down else not across
	end
	if hold then
		Ui.holdTextSize(label, props.holdAt or size)
	end
end

function Ui.label(parent: Instance, name: string, props: TextProps): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	applyText(label, props)
	label.Parent = parent
	return label
end

function Ui.applyText(button: TextButton, props: TextProps)
	applyText((button :: any) :: TextLabel, props)
end

-- Icons drawn from rounded bars, so they need no image assets.
-- check ✓, cross ✕, play ▶ (as a chevron), bang !, and page (a sheet with lines).
function Ui.icon(parent: Instance, kind: string, size: number, color: Color3): Frame
	local holder = Ui.frame(parent, "Icon", UDim2.fromOffset(size, size))
	local thick = math.max(3, math.floor(size * 0.2 + 0.5))
	-- A bar from (x1, y1) to (x2, y2), in fractions of the icon's size.
	local function bar(x1: number, y1: number, x2: number, y2: number)
		local dx, dy = (x2 - x1) * size, (y2 - y1) * size
		local b = Ui.frame(
			holder,
			"Stroke",
			UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + thick, thick),
			UDim2.fromOffset((x1 + x2) / 2 * size, (y1 + y2) / 2 * size),
			Vector2.new(0.5, 0.5)
		)
		b.BackgroundTransparency = 0
		b.BackgroundColor3 = color
		b.Rotation = math.deg(math.atan2(dy, dx))
		Ui.corner(b, UDim.new(0.5, 0))
	end
	if kind == "check" then
		bar(0.14, 0.54, 0.4, 0.8)
		bar(0.4, 0.8, 0.88, 0.22)
	elseif kind == "cross" then
		bar(0.2, 0.2, 0.8, 0.8)
		bar(0.8, 0.2, 0.2, 0.8)
	elseif kind == "play" then
		bar(0.32, 0.18, 0.74, 0.5)
		bar(0.74, 0.5, 0.32, 0.82)
	elseif kind == "bang" then
		bar(0.5, 0.14, 0.5, 0.58)
		bar(0.5, 0.86, 0.5, 0.86)
	elseif kind == "page" then
		local sheet =
			Ui.frame(holder, "Sheet", UDim2.fromScale(0.7, 0.9), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		sheet.BackgroundTransparency = 0
		sheet.BackgroundColor3 = color
		Ui.corner(sheet, UDim.new(0, 3))
		for i = 1, 3 do
			local line = Ui.frame(
				sheet,
				"Line",
				UDim2.new(0.6, 0, 0, math.max(2, math.floor(size * 0.08))),
				UDim2.fromScale(0.5, 0.18 + i * 0.18),
				Vector2.new(0.5, 0)
			)
			line.BackgroundTransparency = 0
			line.BackgroundColor3 = C.ink
		end
	end
	return holder
end

export type ButtonStyle = {
	fill: Color3,
	deep: Color3?, -- the colour of its drop shadow (defaults to the fill, darkened)
	text: Color3?,
	font: Font?,
	textSize: number?,
	icon: string?, -- see Ui.icon
	stack: boolean?, -- the icon above the label rather than beside it
}

-- The label inside a button made by Ui.button.
function Ui.buttonLabel(button: GuiButton): TextLabel
	return button:FindFirstChild("Label", true) :: TextLabel
end

-- The visible body of a button made by Ui.button (a frame that scales from its centre).
function Ui.buttonFace(button: GuiButton): Frame
	return button:FindFirstChild("Face") :: Frame
end

-- A chunky Roblox button: saturated fill, thick outline, gloss, a hard shadow, an
-- optional drawn icon and a stroked label. It squashes when pressed and springs back,
-- grows a little under the mouse, clicks, and fades when it can't be pressed.
--
-- The TextButton itself is invisible and takes the input and the layout; everything
-- you see is on its "Face", which is centred so it scales from the middle.
function Ui.button(parent: Instance, name: string, text: string, size: UDim2, style: ButtonStyle): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Selectable = true

	local face = Ui.frame(button, "Face", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	face.BackgroundTransparency = 0
	face.BackgroundColor3 = style.fill
	Ui.corner(face, UDim.new(0, 14))
	local outline = Ui.stroke(face, C.outline, 3)
	Ui.gloss(face)
	Ui.shadow(face, 5, style.deep or style.fill:Lerp(Color3.new(0, 0, 0), 0.45))
	local scale = Instance.new("UIScale")
	scale.Name = "Bounce"
	scale.Parent = face

	local content = Ui.frame(face, "Content", UDim2.fromScale(1, 1))
	Ui.list(
		content,
		if style.stack then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
		if style.stack then 2 else 8,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Center
	)
	local textSize = style.textSize or 22
	local textColor = style.text or C.text
	if style.icon then
		local icon = Ui.icon(content, style.icon, math.floor(textSize * 1.15), textColor)
		icon.LayoutOrder = 1
	end
	local label = Ui.label(content, "Label", {
		text = text,
		font = style.font or Theme.Fonts.title,
		size = textSize,
		color = textColor,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(0, textSize + 6),
		autoSize = Enum.AutomaticSize.X,
		order = 2,
		hold = true, -- the button doesn't grow with it
	})
	if textColor == C.text then
		Ui.textStroke(label, 2)
	end

	local hovering = false
	local function springTo(target: number, seconds: number, easing: Enum.EasingStyle)
		TweenService:Create(scale, TweenInfo.new(seconds, easing, Enum.EasingDirection.Out), { Scale = target }):Play()
	end
	button.MouseEnter:Connect(function()
		hovering = true
		if button.Interactable then
			springTo(1.05, 0.12, Enum.EasingStyle.Quad)
		end
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		springTo(1, 0.15, Enum.EasingStyle.Quad)
	end)
	button.MouseButton1Down:Connect(function()
		if button.Interactable then
			springTo(0.92, 0.06, Enum.EasingStyle.Quad)
		end
	end)
	button.MouseButton1Up:Connect(function()
		springTo(if hovering then 1.05 else 1, 0.3, Enum.EasingStyle.Back)
	end)
	button.Activated:Connect(Sfx.click)
	button:GetPropertyChangedSignal("Interactable"):Connect(function()
		local on = button.Interactable
		face.BackgroundTransparency = if on then 0 else 0.5
		label.TextTransparency = if on then 0 else 0.45
		outline.Transparency = if on then 0 else 0.5
		if not on then
			scale.Scale = 1
		end
	end)
	button.Parent = parent
	return button
end

-- "12s" style countdown text from a server-time deadline.
function Ui.secondsLeft(deadline: number?): number
	local now = Net.serverTime()
	if deadline == nil or now == nil then
		return 0
	end
	return math.max(0, math.ceil(deadline - now))
end

return Ui
