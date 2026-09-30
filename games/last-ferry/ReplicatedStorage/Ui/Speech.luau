--!strict
--[[
	Speech: what a passenger says, in a bubble over their head drawn to look just
	like Roblox's own chat bubble (BubbleChatConfiguration's defaults: white,
	rounded, 16 pt type in dark grey, with Roblox's tail pointing at them).

	It's ours rather than Roblox's (TextChatService:DisplayBubble) because on the
	last night what they say is a rule, so it has to be readable for as long as
	they're at the window, on every device. Roblox's bubbles fade after
	BubbleDuration, they're BillboardGuis, which every ScreenGui covers (so the HUD
	would hide them), and consoles don't show Roblox's chat at all. This one stays
	up until they leave and works everywhere, bigger on a TV.

	It's drawn on its own layer over the HUD and follows their head every frame. It
	sits over their head as Roblox's do, then moves to stay inside the part of the
	screen the HUD leaves free (the `room` HudController gives it): sideways or up
	as far as it needs, but down only as far as the top of their head, so it never
	covers their face. If there's no room at all, it goes over the top bar rather
	than under it. Something in the way lower down (the ticket's page tab) it goes
	beside, or over if there's no room beside it.

	The line is as big as the player's Text Size setting draws it, unless that would
	run the bubble off the top of the screen (the longest lines, on the smallest
	phones): then it's drawn a step smaller at a time, down to its designed size.
]]

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Ui = require("./Ui")

-- A part of the screen, in pixels.
export type Area = { left: number, top: number, right: number, bottom: number }

-- Where the bubble may go, in GUI coordinates (GuiObject.AbsolutePosition's): `area`, which
-- the HUD leaves clear from top to bottom, less any of the `obstacles` it would otherwise
-- run into (a piece of the HUD lower down, beside it, like the ticket's page tab).
export type Room = { area: Area, obstacles: { Area } }

export type Speech = {
	-- Shows `text` over `model` until release() or clear(), or for `seconds` if given.
	say: (model: Model, text: string, seconds: number?) -> (),
	-- The passenger left the window: a line with no time limit fades shortly after.
	release: () -> (),
	clear: () -> (),
	gui: ScreenGui,
}

local BUBBLE = Color3.fromRGB(250, 250, 250)
local INK = Color3.fromRGB(57, 59, 61)
-- Roblox's bubble font: the Gotham SSm family, as its own bubbles ask for it. Gotham is no
-- longer shipped and Roblox draws it as Montserrat, for its bubbles and this one alike.
local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local CARET = "rbxasset://textures/ui/InGameChat/Caret.png"
local CORNER = 12
local PAD_X, PAD_Y = 16, 8
local ABOVE = 0.4 -- studs from the top of their head (or hat) to the tip of the tail
local LINGER = 1.5 -- seconds a line stays up once they've left the window
local MIN_TEXT = 120 -- the narrowest a line is wrapped at, however little room there is
local NARROWEST = MIN_TEXT + 2 * PAD_X -- so the narrowest a bubble gets
-- A little more room than the line measures, so the line as drawn never needs one more.
local SLACK = 2
local REMEASURE_EVERY = 0.25 -- seconds, at most, while the line doesn't fit its bubble
local NO_LIMIT = 1000 -- a UITextSizeConstraint's MaxTextSize that holds nothing back

local Speech = {}

-- Where a bubble of `size` goes, as its top-left corner, and where along its bottom edge
-- its tail goes (nil if the speaker is off to one side of it). `tip` is the point the
-- tail should touch, just over the speaker's head; `head` is the top of their head; `tail`
-- is how far the tail reaches below the bubble. All in pixels, in one coordinate system.
--
-- Centred over the tip, like Roblox's own bubbles, then kept inside `room`, tail and all:
-- moved along or up as far as it takes, and down only until the tail touches the top of
-- their head.
function Speech.place(tip: Vector2, head: Vector2, size: Vector2, tail: number, room: Area): (Vector2, number?)
	local width = room.right - room.left
	local x = tip.X - size.X / 2
	x = if size.X <= width then math.clamp(x, room.left, room.right - size.X) else room.left + (width - size.X) / 2
	local over = tip.Y - tail - size.Y -- sitting on the tip
	local lowest = head.Y - tail - size.Y -- sitting on their head
	local y = math.max(math.min(over, room.bottom - tail - size.Y), math.min(room.top, lowest))
	local along = tip.X - x
	if along < 0 or along > size.X then
		return Vector2.new(x, y), nil
	end
	-- Clear of the rounded corners.
	local inset = math.min(CORNER + tail, size.X / 2)
	return Vector2.new(x, y), math.clamp(along, inset, size.X - inset)
end

-- Whether two parts of the screen overlap by more than a rounding error: the bubble is drawn
-- at whole pixels, and a Vector2 holds only single-precision numbers.
local function overlap(a: Area, b: Area): boolean
	local e = 0.5
	return a.left < b.right - e and b.left < a.right - e and a.top < b.bottom - e and b.top < a.bottom - e
end

-- Where a bubble goes in `room`: as Speech.place puts it in the whole area, unless that
-- covers one of the obstacles. Then it goes beside that obstacle on the side the tip is on,
-- beside it on the other side, or over it: the first of those with room for it clear of
-- every obstacle (or, if none has room, the first clear of them), with the room it had
-- narrowed to that side. `sizeFor` gives the bubble's size in a part of the room (its line
-- wraps to fit). Returns its size, its top-left corner, and where along it its tail goes.
function Speech.placeInRoom(
	tip: Vector2,
	head: Vector2,
	tail: number,
	room: Room,
	sizeFor: (Area) -> Vector2
): (Vector2, Vector2, number?)
	-- Where the bubble and its tail are on screen.
	local function spot(size: Vector2, at: Vector2): Area
		return { left = at.X, top = at.Y, right = at.X + size.X, bottom = at.Y + size.Y + tail }
	end
	local function blockedBy(box: Area): Area?
		for _, block in room.obstacles do
			if overlap(box, block) then
				return block
			end
		end
		return nil
	end
	local function inside(box: Area, area: Area): boolean
		return box.left >= area.left - 0.5
			and box.right <= area.right + 0.5
			and box.top >= area.top - 0.5
			and box.bottom <= area.bottom + 0.5
	end
	local area = room.area
	local size = sizeFor(area)
	local at, along = Speech.place(tip, head, size, tail, area)
	for _ = 1, 2 * #room.obstacles do
		local block = blockedBy(spot(size, at))
		if block == nil then
			break
		end
		local left, right, over = table.clone(area), table.clone(area), table.clone(area)
		left.right = math.min(area.right, block.left)
		right.left = math.max(area.left, block.right)
		over.bottom = math.min(area.bottom, block.top)
		local sides = if (block.left + block.right) / 2 < tip.X then { right, left } else { left, right }
		local candidates = { sides[1], sides[2], over }
		local chosen, roomy = nil, false
		for _, candidate in candidates do
			if candidate == over or candidate.right - candidate.left >= NARROWEST then
				local candidateSize = sizeFor(candidate)
				local candidateAt, candidateAlong = Speech.place(tip, head, candidateSize, tail, candidate)
				local box = spot(candidateSize, candidateAt)
				if blockedBy(box) == nil then
					local fits = inside(box, candidate)
					if chosen == nil or (fits and not roomy) then
						chosen = { area = candidate, size = candidateSize, at = candidateAt, along = candidateAlong }
						roomy = fits
					end
					if fits then
						break
					end
				end
			end
		end
		if chosen == nil then
			local overSize = sizeFor(over)
			local overAt, overAlong = Speech.place(tip, head, overSize, tail, over)
			chosen = { area = over, size = overSize, at = overAt, along = overAlong }
		end
		area, size, at, along = chosen.area, chosen.size, chosen.at, chosen.along
	end
	return size, at, along
end

-- How far above `root` the top of `model` is, hat and all.
local function heightAbove(model: Model, root: BasePart): number
	local box, size = model:GetBoundingBox()
	return size.Y / 2 - box:PointToObjectSpace(root.Position).Y
end

-- `room` gives the part of the screen the bubble may use, or nil to hide it for now.
function Speech.new(parent: Instance, room: () -> Room?): Speech
	-- How big it's drawn (set by applyDisplay).
	local textSize = 16
	local maxWidth = 300 -- widest a line runs before it wraps
	local caretSize = Vector2.new(9, 6)

	-- Over the HUD (LastFerryHud is DisplayOrder 6), across the whole screen. Positions on
	-- it are GUI coordinates (where the camera draws a point, from WorldToScreenPoint, and
	-- where the HUD is, from AbsolutePosition) less where it starts.
	local gui = Instance.new("ScreenGui")
	gui.Name = "LastFerrySpeech"
	gui.DisplayOrder = 7
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	gui.ResetOnSpawn = false
	gui.Parent = parent

	-- The bubble and its tail, moved as one. The tail overlaps the bubble by a pixel:
	-- UICorner leaves a pixel's gap under it, and Roblox closes it the same way.
	local stack = Ui.frame(gui, "Stack", UDim2.new())
	stack.Visible = false
	local bubble = Ui.frame(stack, "Bubble", UDim2.fromScale(1, 0))
	bubble.BackgroundColor3 = BUBBLE
	bubble.BackgroundTransparency = 0.1
	Ui.corner(bubble, UDim.new(0, CORNER))
	local line = Ui.label(bubble, "Line", {
		font = FONT,
		size = textSize,
		color = INK,
		wrap = true,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -2 * PAD_X, 1, -2 * PAD_Y),
		position = UDim2.fromOffset(PAD_X, PAD_Y),
	})
	local caret = Instance.new("ImageLabel")
	caret.Name = "Caret"
	caret.Size = UDim2.fromOffset(caretSize.X, caretSize.Y)
	caret.AnchorPoint = Vector2.new(0.5, 0)
	caret.BackgroundTransparency = 1
	caret.Image = CARET
	caret.ImageColor3 = BUBBLE
	caret.ImageTransparency = 0.1
	caret.Parent = stack

	-- Each line is measured wrapped at the widest the bubble may go, and the bubble fits
	-- it: how Roblox sizes its own bubbles (a hidden label's TextBounds).
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

	-- The line is drawn as big as the player's Text Size setting draws it, unless the bubble
	-- would then run off the top of the screen: then a step smaller at a time (`limits`, the
	-- first no limit at all), but never smaller than designed. A UITextSizeConstraint on each
	-- label holds it there, as Roblox's docs say that setting never draws text past one.
	local limits: { number } = {}
	local lineLimit = Instance.new("UITextSizeConstraint")
	lineLimit.MaxTextSize = NO_LIMIT
	lineLimit.Parent = line
	local measureLimit = Instance.new("UITextSizeConstraint")
	measureLimit.MaxTextSize = NO_LIMIT
	measureLimit.Parent = measure

	local model: Model? = nil
	local root: BasePart? = nil
	local height = 0 -- from the root to the top of their head
	-- The bubble's size for the line, by the limit on its text's size, then its wrap width.
	local measured: { [number]: { [number]: Vector2 } } = {}
	local bubbleSize = Vector2.zero
	local token = 0
	local timed = false
	local tail = 0 -- how far the tail reaches below the bubble
	local lastRemeasure = 0

	-- Bigger on a TV, read from across the room. Roblox's docs say to tell a TV by the
	-- display's size (not by whether it's a console) and to follow it as it changes.
	local function applyDisplay()
		local tv = GuiService.ViewportDisplaySize == Enum.DisplaySize.Large
		textSize = if tv then 24 else 16
		maxWidth = if tv then 420 else 300
		caretSize = if tv then Vector2.new(14, 9) else Vector2.new(9, 6)
		-- The tail overlaps the bubble by a pixel, so it reaches that much less below it.
		tail = caretSize.Y - 1
		limits = { NO_LIMIT, textSize + 6, textSize + 4, textSize + 2, textSize }
		line.TextSize = textSize
		measure.TextSize = textSize
		caret.Size = UDim2.fromOffset(caretSize.X, caretSize.Y)
		table.clear(measured)
	end
	applyDisplay()
	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(applyDisplay)

	-- Roblox loads a font the first time it's needed, and text measured before then comes
	-- out the size of a stand-in font's. So the line is measured again once the bubble's
	-- font has loaded, whenever the player changes their text size, and (as preloading
	-- isn't always enough) whenever the line doesn't fit its bubble after all.
	task.spawn(function()
		ContentProvider:PreloadAsync({ measure })
		table.clear(measured)
	end)
	GuiService:GetPropertyChangedSignal("PreferredTextSize"):Connect(function()
		table.clear(measured)
	end)

	-- How big the bubble is with its line wrapped for `area`: as wide as Roblox's bubbles
	-- go, or as the area is (but never too narrow to read). Its text is no bigger than the
	-- limit on the measuring label.
	local function sizeFor(area: Area): Vector2
		local fits = math.floor(math.min(maxWidth + 2 * PAD_X, area.right - area.left)) - 2 * PAD_X
		local width = math.max(fits, MIN_TEXT)
		local limit = measureLimit.MaxTextSize
		local byWidth = measured[limit]
		if byWidth == nil then
			byWidth = {}
			measured[limit] = byWidth
		end
		local known: Vector2? = byWidth[width]
		if known then
			return known
		end
		measure.Size = UDim2.fromOffset(width - SLACK, 10000)
		measure.Text = "" -- laid out afresh, even if the text is the same as last time
		measure.Text = line.Text
		local bounds = measure.TextBounds
		local size = Vector2.new(math.ceil(bounds.X) + SLACK + 2 * PAD_X, math.ceil(bounds.Y) + 2 * PAD_Y)
		byWidth[width] = size
		return size
	end

	local function clear()
		token += 1
		model = nil
		root = nil
		stack.Visible = false
		stack:SetAttribute("Speaker", nil)
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

	-- Every frame, once the camera has moved: over their head, inside the room.
	RunService:BindToRenderStep("LastFerrySpeech", Enum.RenderPriority.Camera.Value + 2, function()
		local speaker, part = model, root
		if speaker == nil or part == nil then
			return
		end
		if not speaker:IsDescendantOf(workspace) then
			-- Gone with them if they're taken away before it's over.
			clear()
			return
		end
		local free = room()
		local camera = workspace.CurrentCamera
		local top = part.Position + Vector3.new(0, height, 0)
		local tipPoint = camera:WorldToScreenPoint(top + Vector3.new(0, ABOVE, 0))
		if free == nil or tipPoint.Z <= 0 then
			stack.Visible = false -- no room for now, or they're behind the camera
			return
		end
		-- Everything from GUI coordinates to this layer's own.
		local origin = gui.AbsolutePosition
		local function onLayer(area: Area): Area
			return {
				left = area.left - origin.X,
				top = area.top - origin.Y,
				right = area.right - origin.X,
				bottom = area.bottom - origin.Y,
			}
		end
		local headPoint = camera:WorldToScreenPoint(top)
		local tip = Vector2.new(tipPoint.X, tipPoint.Y) - origin
		local head = Vector2.new(headPoint.X, headPoint.Y) - origin
		local obstacles: { Area } = {}
		for _, obstacle in free.obstacles do
			table.insert(obstacles, onLayer(obstacle))
		end
		local layerRoom = { area = onLayer(free.area), obstacles = obstacles }
		-- The biggest text that keeps the bubble on screen (the top of this layer is the top
		-- of the screen), or the smallest there is.
		measureLimit.MaxTextSize = limits[1]
		local size, at, along = Speech.placeInRoom(tip, head, tail, layerRoom, sizeFor)
		for i = 2, #limits do
			if at.Y >= -0.5 then
				break
			end
			measureLimit.MaxTextSize = limits[i]
			size, at, along = Speech.placeInRoom(tip, head, tail, layerRoom, sizeFor)
		end
		if lineLimit.MaxTextSize ~= measureLimit.MaxTextSize then
			lineLimit.MaxTextSize = measureLimit.MaxTextSize
		end
		if size ~= bubbleSize then
			bubbleSize = size
			stack.Size = UDim2.fromOffset(size.X, size.Y + tail)
			bubble.Size = UDim2.fromOffset(size.X, size.Y)
		end
		stack.Position = UDim2.fromOffset(math.round(at.X), math.round(at.Y))
		caret.Visible = along ~= nil
		if along then
			caret.Position = UDim2.fromOffset(math.round(along), size.Y - 1)
		end
		stack.Visible = true
		local now = os.clock()
		if not line.TextFits and now - lastRemeasure >= REMEASURE_EVERY then
			lastRemeasure = now
			table.clear(measured)
		end
	end)

	return {
		gui = gui,
		say = function(speaker: Model, text: string, seconds: number?)
			local part = speaker:FindFirstChild("HumanoidRootPart")
			if not (part and part:IsA("BasePart")) then
				return
			end
			clear()
			model = speaker
			root = part
			height = heightAbove(speaker, part)
			line.Text = text
			table.clear(measured) -- measured on the next frame, for the room there is then
			stack:SetAttribute("Speaker", speaker.Name)
			timed = seconds ~= nil
			if seconds then
				hideAfter(seconds)
			end
		end,
		release = function()
			if model and not timed then
				timed = true
				hideAfter(LINGER)
			end
		end,
		clear = clear,
	}
end

return Speech
