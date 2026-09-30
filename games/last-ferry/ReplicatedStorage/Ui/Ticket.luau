--!strict
--[[
	The ticket on the counter: passenger, destination, date and stamp, typed on
	paper. A torn ledger page can be tucked behind it. After a call the ticket
	gets a rubber stamp (BOARDED / TURNED AWAY) and slides off the desk.

	Stamps are drawn from frames, so there are no image assets:
		gull   - red ring with a gull (the harbor's stamp; the only valid one)
		anchor - blue ring with an anchor (the old Marigold Line stamp)
		none   - an empty, faint ring where a stamp should be
]]

local TweenService = game:GetService("TweenService")

local View = require("../Shared/Types")
local Theme = require("./Theme")
local Ui = require("./Ui")

export type Ticket = {
	root: Frame,
	show: (view: View.PassengerView) -> (),
	clear: () -> (),
	stamp: (text: string, color: Color3) -> (),
	onTakePage: (callback: () -> ()) -> (),
}

local WIDTH, HEIGHT = 250, 190

local C = Theme.Colors

local Ticket = {}

local function bar(parent: Instance, size: Vector2, offset: Vector2, rotation: number, color: Color3)
	local f = Ui.frame(
		parent,
		"Bar",
		UDim2.fromOffset(size.X, size.Y),
		UDim2.new(0.5, offset.X, 0.5, offset.Y),
		Vector2.new(0.5, 0.5)
	)
	f.BackgroundTransparency = 0
	f.BackgroundColor3 = color
	f.Rotation = rotation
	Ui.corner(f, UDim.new(0, 2))
end

local function ring(parent: Instance, diameter: number, position: UDim2, color: Color3, thickness: number): Frame
	local f = Ui.frame(parent, "Ring", UDim2.fromOffset(diameter, diameter), position, Vector2.new(0.5, 0.5))
	Ui.corner(f, UDim.new(0.5, 0))
	Ui.stroke(f, color, thickness)
	return f
end

local function drawGull(stamp: Frame)
	local red = C.stampRed
	ring(stamp, 56, UDim2.fromScale(0.5, 0.5), red, 3)
	-- Two wings in a shallow V, the way everyone draws a gull.
	bar(stamp, Vector2.new(19, 4), Vector2.new(-8, -5), 24, red)
	bar(stamp, Vector2.new(19, 4), Vector2.new(8, -5), -24, red)
	Ui.label(stamp, "Word", {
		text = "GULL",
		font = Theme.Fonts.title,
		size = 12,
		color = red,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(40, 14),
		position = UDim2.new(0.5, 0, 0.5, 12),
		anchor = Vector2.new(0.5, 0.5),
	})
end

local function drawAnchor(stamp: Frame)
	local blue = C.stampBlue
	ring(stamp, 56, UDim2.fromScale(0.5, 0.5), blue, 3)
	ring(stamp, 9, UDim2.new(0.5, 0, 0.5, -17), blue, 2) -- eye
	bar(stamp, Vector2.new(4, 30), Vector2.new(0, 2), 0, blue) -- shank
	bar(stamp, Vector2.new(18, 4), Vector2.new(0, -9), 0, blue) -- stock
	-- Crown: a flat bottom and two arms curving up, drawn with bars. (ClipsDescendants
	-- would be simpler, but it's ignored under the stamp's rotated frame.)
	local crown = Ui.frame(stamp, "Crown", UDim2.fromOffset(30, 14), UDim2.new(0.5, 0, 0.5, 6), Vector2.new(0.5, 0))
	bar(crown, Vector2.new(12, 4), Vector2.new(0, 5), 0, blue)
	bar(crown, Vector2.new(12, 4), Vector2.new(-9, 1), -50, blue)
	bar(crown, Vector2.new(12, 4), Vector2.new(9, 1), 50, blue)
end

local function drawEmpty(stamp: Frame)
	local faint = ring(stamp, 56, UDim2.fromScale(0.5, 0.5), C.paperMuted, 1.5)
	local stroke = faint:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0.45
	end
	Ui.label(stamp, "Word", {
		text = "STAMP",
		font = Theme.Fonts.title,
		size = 11,
		color = C.paperMuted,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(44, 14),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
	}).TextTransparency =
		0.45
end

local function field(parent: Instance, name: string, caption: string, y: number, valueSize: number): TextLabel
	Ui.label(parent, name .. "Caption", {
		text = caption,
		font = Theme.Fonts.title,
		size = 12,
		color = C.paperMuted,
		frameSize = UDim2.new(1, -80, 0, 14),
		position = UDim2.fromOffset(0, y),
	})
	return Ui.label(parent, name, {
		font = Theme.Fonts.ticket,
		size = valueSize,
		color = C.paperInk,
		frameSize = UDim2.new(1, -80, 0, valueSize + 4),
		position = UDim2.fromOffset(0, y + 14),
	})
end

-- `home` is where the ticket rests on the desk; it slides in from the left of it.
function Ticket.new(parent: Instance, home: UDim2): Ticket
	local away = home - UDim2.fromOffset(WIDTH + 140, 0)
	-- The holder keeps the page tab behind the paper (lower ZIndex, same parent).
	local root = Ui.frame(parent, "TicketHolder", UDim2.fromOffset(WIDTH, HEIGHT), away)
	root.Visible = false

	-- A torn page poking out of the right edge: 72 x 76 showing, big enough to tap.
	local tab = Instance.new("TextButton")
	tab.Name = "PageTab"
	tab.Size = UDim2.fromOffset(100, 76)
	tab.Position = UDim2.fromOffset(WIDTH - 28, 40)
	tab.Rotation = 5
	tab.BackgroundColor3 = C.paperShade
	tab.BorderSizePixel = 0
	tab.AutoButtonColor = false
	tab.Text = "TAKE\nPAGE"
	tab.FontFace = Theme.Fonts.ticket
	tab.TextSize = 16
	tab.TextColor3 = C.paperInk
	tab.TextXAlignment = Enum.TextXAlignment.Center
	tab.ZIndex = 1
	tab.Visible = false
	tab.Selectable = true
	Ui.padding(tab, 0, 0, 0, 28)
	Ui.corner(tab, UDim.new(0, 4))
	local tabStroke = Ui.stroke(tab, C.lamp, 2, 0.2)
	tab.Parent = root

	local paper = Ui.frame(root, "Ticket", UDim2.fromOffset(WIDTH, HEIGHT))
	paper.BackgroundTransparency = 0
	paper.BackgroundColor3 = C.paper
	paper.Active = true
	paper.ZIndex = 2
	Ui.corner(paper, UDim.new(0, 6))
	Ui.stroke(paper, C.paperShade, 1.5)
	local body = Ui.frame(paper, "Body", UDim2.fromScale(1, 1))
	Ui.padding(body, 10, 12, 10, 12)

	Ui.label(body, "Company", {
		text = "GULL HARBOR FERRY CO.",
		font = Theme.Fonts.title,
		size = 14,
		color = C.paperMuted,
		frameSize = UDim2.new(1, 0, 0, 18),
	})
	Ui.label(body, "Admit", {
		text = "ADMIT ONE",
		font = Theme.Fonts.title,
		size = 14,
		color = C.paperMuted,
		xAlign = Enum.TextXAlignment.Right,
		frameSize = UDim2.new(1, 0, 0, 18),
	})
	local rule = Ui.frame(body, "Rule", UDim2.new(1, 0, 0, 1), UDim2.fromOffset(0, 22))
	rule.BackgroundTransparency = 0
	rule.BackgroundColor3 = C.paperShade

	local nameValue = field(body, "Passenger", "PASSENGER", 28, 22)
	nameValue.Size = UDim2.new(1, 0, 0, 26)
	nameValue.TextTruncate = Enum.TextTruncate.AtEnd
	local destination = field(body, "Destination", "TO", 72, 18)
	local date = field(body, "Date", "DATE", 110, 18)
	local serial = Ui.label(body, "Serial", {
		font = Theme.Fonts.ticket,
		size = 12,
		color = C.paperMuted,
		frameSize = UDim2.new(1, 0, 0, 14),
		position = UDim2.new(0, 0, 1, -14),
	})

	local stampHolder = Ui.frame(body, "Stamp", UDim2.fromOffset(64, 64), UDim2.new(1, 2, 1, -2), Vector2.new(1, 1))
	stampHolder.Rotation = -10

	-- The rubber stamp slammed onto the ticket after a call.
	local callStamp = Ui.label(paper, "CallStamp", {
		font = Theme.Fonts.title,
		size = 34,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(220, 52),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
	})
	callStamp.Rotation = -12
	callStamp.ZIndex = 3
	callStamp.Visible = false
	local callStroke = Instance.new("UIStroke")
	callStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	callStroke.Thickness = 3
	callStroke.Parent = callStamp
	Ui.corner(callStamp, UDim.new(0, 6))
	local callScale = Instance.new("UIScale")
	callScale.Parent = callStamp

	local currentId: number? = nil
	local currentStamp: string? = nil
	local hideToken = 0
	local takePage: (() -> ())? = nil

	-- The tab's outline pulses so a page is hard to miss once you know to look.
	task.spawn(function()
		while true do
			task.wait(0.05)
			if tab.Visible then
				tabStroke.Transparency = 0.15 + 0.6 * (0.5 + 0.5 * math.sin(os.clock() * 4))
			end
		end
	end)

	local function slide(target: UDim2, seconds: number)
		TweenService:Create(root, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = target,
		}):Play()
	end

	local function drawStamp(kind: string)
		if currentStamp == kind then
			return
		end
		currentStamp = kind
		for _, child in stampHolder:GetChildren() do
			child:Destroy()
		end
		if kind == "gull" then
			drawGull(stampHolder)
		elseif kind == "anchor" then
			drawAnchor(stampHolder)
		else
			drawEmpty(stampHolder)
		end
	end

	tab.Activated:Connect(function()
		if takePage and tab.Visible then
			takePage()
		end
	end)

	local ticket: Ticket = {
		root = root,
		show = function(view: View.PassengerView)
			hideToken += 1
			local isNew = view.id ~= currentId
			currentId = view.id
			nameValue.Text = view.ticket.name
			destination.Text = view.ticket.destination
			date.Text = view.ticket.date
			serial.Text = string.format("No. %06d", 4127 + view.id * 37)
			drawStamp(view.ticket.stamp)
			tab.Visible = view.hasPage
			if isNew then
				callStamp.Visible = false
				root.Visible = true
				root.Position = away
				slide(home, 0.35)
			end
		end,
		-- The passenger has gone: leave the stamped ticket up for a moment, then slide it away.
		clear = function()
			if currentId == nil then
				return
			end
			currentId = nil
			tab.Visible = false
			hideToken += 1
			local token = hideToken
			task.delay(1.1, function()
				if hideToken == token then
					slide(away, 0.3)
					task.delay(0.3, function()
						if hideToken == token then
							root.Visible = false
						end
					end)
				end
			end)
		end,
		stamp = function(text: string, color: Color3)
			callStamp.Text = text
			callStamp.TextColor3 = color
			callStroke.Color = color
			callStamp.Visible = true
			callScale.Scale = 1.5
			TweenService:Create(callScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
		end,
		onTakePage = function(callback: () -> ())
			takePage = callback
		end,
	}
	return ticket
end

return Ticket
