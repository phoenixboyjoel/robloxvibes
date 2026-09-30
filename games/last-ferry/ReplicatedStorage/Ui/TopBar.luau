--!strict
--[[
	TopBar: the shift's status, up in Roblox's own top bar row beside Roblox's buttons
	(a ScreenGui with ScreenInsets.TopbarSafeInsets), drawn as pills the way Roblox
	draws its own there: the night, the clock and the date on the left; the ledger,
	the queue and the lanterns on the right. A lantern going out or a torn page being
	found shows across the row for a few seconds instead.

	Up there it leaves the whole screen below it to the booth: the passenger's face,
	their speech bubble and the planks, even on the smallest phone.

	The row is Roblox's: 58 px tall (taller on a TV), and narrower while Roblox's own
	buttons take more room. The pills fit themselves to whatever room there is: the
	date goes first, then the queue, the ledger's label and the clock. If there's no
	top bar row, or it's too short for the pills, the row sits at the top of the HUD
	instead (`fallback`), at the HUD's scale.
]]

local GuiService = game:GetService("GuiService")

local Theme = require("./Theme")
local Ui = require("./Ui")
local Widgets = require("./Widgets")

local C = Theme.Colors
local F = Theme.Fonts

export type TopBar = {
	gui: ScreenGui,
	row: Frame, -- the status pills or the alert, wherever the row is
	bar: Frame, -- the status pills
	night: TextLabel,
	clock: TextLabel,
	date: TextLabel,
	queue: TextLabel,
	lanterns: { Frame },
	ledger: TextButton,
	ledgerLabel: TextLabel, -- the pages found: "2/5"
	alert: Frame,
	-- Fills in the alert: a bold title, a line of text and an icon ("bang" or "page").
	setAlert: (title: string, text: string, icon: string, color: Color3, background: Color3) -> (),
	-- Shows or hides the whole row (it's only up on shift).
	setShown: (shown: boolean) -> (),
	-- Fits the pills to the room there is: if need be the date goes, then the queue, then
	-- the word LEDGER (its icon and page count stay), then the clock.
	fit: () -> (),
	-- Whether the row is up in Roblox's top bar (or, if not, at the top of the HUD).
	inRow: () -> boolean,
	-- Calls `callback` whenever the row moves between the two.
	onPlaced: (callback: () -> ()) -> (),
}

-- Roblox's top bar, from its client scripts: a 58 px row (87 on a TV, where everything
-- is 1.5 times the size), 44 px buttons 12 px down from the top, 8 px apart, and pills of
-- near-black (Foundation's OverMedia_0), 8% see-through times the player's
-- PreferredTransparency setting, fully rounded, with Builder Sans in near-white.
local ROW = 58
local PILL = 44
local PILL_TOP = 12
local ALERT = 52 -- a little taller than the pills, so two lines fit on a phone
local GAP = 8
local EDGE_LEFT = 8 -- after Roblox's own buttons
local EDGE_RIGHT = 16 -- from the side of the screen, as Roblox's buttons are
local LEDGER_PADDING = 28 -- left and right, inside the ledger's pill
local LEDGER_GAP = 6
-- Less than this, and the pills would be too small to see or tap (Roblox's old 36 px top
-- bar), or couldn't fit the night and the lanterns.
local MIN_ROW = 50
local MIN_WIDTH = 300
local PILL_FILL = Color3.fromRGB(18, 18, 21)
local PILL_SEE_THROUGH = 0.08
local INK = Color3.fromRGB(247, 247, 248)
local INK_MUTED = Color3.fromRGB(188, 190, 200)
-- Roblox's highlight over a button under the mouse, and while it's pressed.
local HOVER = Color3.fromRGB(208, 217, 251)
local HOVER_SEE_THROUGH, PRESSED_SEE_THROUGH = 0.92, 0.88

local TopBar = {}

local function pill(parent: Instance, name: string, order: number): Frame
	local frame = Ui.frame(parent, name, UDim2.fromOffset(0, PILL))
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.BackgroundColor3 = PILL_FILL
	frame.LayoutOrder = order
	Ui.corner(frame, UDim.new(1, 0))
	Ui.padding(frame, 0, 16, 0, 16)
	Ui.list(frame, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	return frame
end

local function text(parent: Instance, name: string, font: Font, size: number, color: Color3): TextLabel
	return Ui.label(parent, name, {
		font = font,
		size = size,
		color = color,
		frameSize = UDim2.fromOffset(0, PILL),
		autoSize = Enum.AutomaticSize.X,
		order = 2,
	})
end

-- `fallback` is where the row goes when there's no top bar row: the HUD's play area.
function TopBar.new(parent: Instance, fallback: GuiObject): TopBar
	local gui = Instance.new("ScreenGui")
	gui.Name = "LastFerryTopBar"
	gui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
	gui.DisplayOrder = 6
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = parent

	local row = Ui.frame(gui, "Row", UDim2.fromScale(1, 1))
	row.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = row

	-- The status pills, level with Roblox's buttons.
	local bar =
		Ui.frame(row, "TopBar", UDim2.new(1, -(EDGE_LEFT + EDGE_RIGHT), 0, PILL), UDim2.fromOffset(EDGE_LEFT, PILL_TOP))
	local left = Ui.frame(bar, "Left", UDim2.fromScale(1, 1))
	Ui.list(left, Enum.FillDirection.Horizontal, GAP, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local right = Ui.frame(bar, "Right", UDim2.fromScale(1, 1))
	Ui.list(right, Enum.FillDirection.Horizontal, GAP, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

	local nightPill = pill(left, "NightPill", 1)
	local night = text(nightPill, "Night", F.bodyBold, 18, C.lamp)
	local clockPill = pill(left, "ClockPill", 2)
	local clock = text(clockPill, "Clock", F.bodyBold, 18, INK)
	local datePill = pill(left, "DatePill", 3)
	local date = text(datePill, "Date", F.body, 15, INK_MUTED)

	-- The ledger: a pill that can be pressed, like Roblox's own buttons up here.
	local ledger = Instance.new("TextButton")
	ledger.Name = "Ledger"
	ledger.Text = ""
	ledger.AutoButtonColor = false
	ledger.Selectable = true
	ledger.Size = UDim2.fromOffset(0, PILL)
	ledger.AutomaticSize = Enum.AutomaticSize.X
	ledger.BackgroundColor3 = PILL_FILL
	ledger.LayoutOrder = 1
	ledger.Visible = false
	Ui.corner(ledger, UDim.new(1, 0))
	-- What it says, lined up inside; the pill is as wide as that.
	local content = Ui.frame(ledger, "Content", UDim2.fromOffset(0, PILL))
	content.AutomaticSize = Enum.AutomaticSize.X
	Ui.padding(content, 0, LEDGER_PADDING - 12, 0, 12)
	Ui.list(
		content,
		Enum.FillDirection.Horizontal,
		LEDGER_GAP,
		Enum.HorizontalAlignment.Left,
		Enum.VerticalAlignment.Center
	)
	local ledgerIcon = Ui.icon(content, "page", 22, C.paper)
	ledgerIcon.LayoutOrder = 1
	local ledgerWord = text(content, "Word", F.bodyBold, 16, INK)
	ledgerWord.Text = "LEDGER"
	local ledgerLabel = text(content, "Count", F.bodyBold, 16, C.lamp)
	ledgerLabel.LayoutOrder = 3
	-- Roblox's highlight, over the whole pill while the mouse is on it or it's pressed.
	local highlight = Ui.frame(ledger, "Highlight", UDim2.fromScale(1, 1))
	highlight.BackgroundColor3 = HOVER
	highlight.ZIndex = 2
	Ui.corner(highlight, UDim.new(1, 0))
	local hovering = false
	local function lightUp(pressed: boolean)
		highlight.BackgroundTransparency = if pressed
			then PRESSED_SEE_THROUGH
			elseif hovering then HOVER_SEE_THROUGH
			else 1
	end
	ledger.MouseEnter:Connect(function()
		hovering = true
		lightUp(false)
	end)
	ledger.MouseLeave:Connect(function()
		hovering = false
		lightUp(false)
	end)
	ledger.MouseButton1Down:Connect(function()
		lightUp(true)
	end)
	ledger.MouseButton1Up:Connect(function()
		lightUp(false)
	end)
	ledger.Parent = right

	local queuePill = pill(right, "QueuePill", 2)
	local queue = text(queuePill, "Queue", F.bodyBold, 16, INK)
	local lanternPill = pill(right, "Lanterns", 3)
	local lanterns: { Frame } = {}
	for i = 1, 3 do
		table.insert(lanterns, Widgets.lantern(lanternPill, i))
	end

	-- The alert: across the row, ending level with the pills, with a round badge saying which
	-- kind at a glance.
	local alert = Ui.frame(
		row,
		"Alert",
		UDim2.new(1, -(EDGE_LEFT + EDGE_RIGHT), 0, ALERT),
		UDim2.fromOffset(EDGE_LEFT, PILL_TOP + PILL - ALERT)
	)
	alert.BackgroundTransparency = 0.08
	alert.Visible = false
	Ui.corner(alert, UDim.new(0, ALERT / 2))
	Ui.padding(alert, 4, 22, 4, 52)
	local badge = Ui.frame(alert, "Badge", UDim2.fromOffset(32, 32), UDim2.new(0, -44, 0.5, 0), Vector2.new(0, 0.5))
	badge.BackgroundTransparency = 0
	Ui.corner(badge, UDim.new(0.5, 0))
	local icons: { [string]: Frame } = {}
	for _, kind in { "bang", "page" } do
		local icon = Ui.icon(badge, kind, 20, C.text)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icons[kind] = icon
	end
	local caption = Ui.label(alert, "Caption", {
		font = F.title,
		size = 14,
		frameSize = UDim2.new(1, 0, 0, 15),
	})
	local paragraph = Ui.label(alert, "Paragraph", {
		font = F.body,
		size = 14,
		color = INK,
		wrap = true,
		yAlign = Enum.TextYAlignment.Top,
		frameSize = UDim2.new(1, 0, 0, 29),
		position = UDim2.fromOffset(0, 15),
	})
	paragraph.TextTruncate = Enum.TextTruncate.AtEnd

	local inRow = false
	local placed: (() -> ())? = nil
	local function place()
		local size = gui.AbsoluteSize
		local wasInRow = inRow
		inRow = size.Y >= MIN_ROW and size.X / (size.Y / ROW) >= MIN_WIDTH
		if inRow then
			local height = size.Y
			-- At Roblox's size for the row, scaled with it (up on a TV).
			local s = height / ROW
			scale.Scale = s
			row.Size = UDim2.fromScale(1 / s, 1 / s)
			row.Position = UDim2.new()
			row.Parent = gui
		else
			scale.Scale = 1
			row.Size = UDim2.new(1, -32, 0, ROW)
			row.Position = UDim2.fromOffset(16, 0)
			row.Parent = fallback
		end
		if placed and inRow ~= wasInRow then
			placed()
		end
	end

	local topBar: TopBar
	topBar = {
		gui = gui,
		row = row,
		bar = bar,
		night = night,
		clock = clock,
		date = date,
		queue = queue,
		lanterns = lanterns,
		ledger = ledger,
		ledgerLabel = ledgerLabel,
		alert = alert,
		setAlert = function(title: string, line: string, icon: string, color: Color3, background: Color3)
			caption.Text = title
			caption.TextColor3 = color
			paragraph.Text = line
			alert.BackgroundColor3 = background
			badge.BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.25)
			for kind, frame in icons do
				frame.Visible = kind == icon
			end
		end,
		setShown = function(shown: boolean)
			row.Visible = shown
		end,
		fit = function()
			-- The row's scale on screen: Roblox's (up on a TV), or the HUD's in the fallback.
			local s = row.AbsoluteSize.Y / ROW
			if s <= 0 then
				return
			end
			local room = row.AbsoluteSize.X / s - EDGE_LEFT - EDGE_RIGHT
			-- How wide a pill is. The ledger's is added up from what's showing in it, as its
			-- own size only catches up with the word going next frame.
			local function widthOf(item: GuiObject): number
				if item ~= ledger then
					return item.AbsoluteSize.X / s
				end
				local width, count = LEDGER_PADDING, 0
				for _, child in content:GetChildren() do
					if child:IsA("GuiObject") and child.Visible then
						width += child.AbsoluteSize.X / s
						count += 1
					end
				end
				return width + math.max(count - 1, 0) * LEDGER_GAP
			end
			local function need(): number
				local total, count = 0, 0
				for _, group in { left, right } do
					for _, child in group:GetChildren() do
						if child:IsA("GuiObject") and child.Visible then
							total += widthOf(child)
							count += 1
						end
					end
				end
				return total + math.max(count - 1, 0) * GAP + 2 * GAP
			end
			-- Least needed first; the night and the lanterns always stay.
			local extras: { GuiObject } = { datePill, queuePill, ledgerWord, clockPill }
			for _, extra in extras do
				extra.Visible = true
			end
			for _, extra in extras do
				if need() <= room then
					return
				end
				extra.Visible = false
			end
		end,
		inRow = function(): boolean
			return inRow
		end,
		onPlaced = function(callback: () -> ())
			placed = callback
		end,
	}
	-- Roblox's own see-through pills follow the player's transparency setting; so do these.
	local pills: { GuiObject } = { nightPill, clockPill, datePill, ledger, queuePill, lanternPill }
	local function seeThrough()
		for _, each in pills do
			each.BackgroundTransparency = PILL_SEE_THROUGH * GuiService.PreferredTransparency
		end
	end
	seeThrough()
	GuiService:GetPropertyChangedSignal("PreferredTransparency"):Connect(seeThrough)

	place()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		place()
		topBar.fit()
	end)
	return topBar
end

return TopBar
