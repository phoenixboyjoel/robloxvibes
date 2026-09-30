--!strict
--[[
	HudController: everything on screen, wired to the server's remotes.

	On the pier between shifts there's only a banner: the game's name, how to start
	(hold E at the time clock by the booth door) and the endings found so far. Roblox's
	own UI does the rest: the player list, chat, emotes, the touch controls.

	On shift, on a canvas at least 960 x 420 scaled to fit the screen (see Theme):
		top bar        night, date and clock · lanterns, queue, ledger; a lost lantern
		               or a found page shows as a banner over it for a few seconds
		left "desk"    the ticket, the window countdown, BOARD / TURN AWAY
		right          the rules card and, from night 3, the manifest (can be hidden);
		               the ledger opens over it without blocking anything. On touch
		               screens it stops short of Roblox's jump button.
		top centre     Pike's radio, only while nobody is at the window, so nothing
		               covers a passenger's face or breath
		bottom centre  kept clear: that's where the planks and the shadows are
	While on shift an invisible Modal button keeps the mouse cursor free, so the HUD
	can be clicked in first person (hold the right button to look around).

	Passengers talk the Roblox way: each line is a chat bubble over their head
	(TextChatService:DisplayBubble) and a line in the chat window, so it can be
	read again. "{name}" becomes the local player's display name.

	Keys, bound with ContextActionService above Roblox's own controls, and only taken
	when they do something (otherwise gamepad A still jumps): B / gamepad A board,
	T / B turn away, P / X take a torn page, Enter, Space or A continue.

	The server sends the whole screen state on every change (ShiftState) plus
	one-off effects (ShiftFx). Nothing here decides anything; it only draws what
	it's told and sends the player's presses back.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require("../Shared/Config")
local Net = require("../Shared/Net")
local View = require("../Shared/Types")
local Overlay = require("../Ui/Overlay")
local Theme = require("../Ui/Theme")
local Ticket = require("../Ui/Ticket")
local Ui = require("../Ui/Ui")
local Widgets = require("../Ui/Widgets")
local CameraController = require("./CameraController")
local EffectsController = require("./EffectsController")

local C = Theme.Colors
local F = Theme.Fonts

local DESK_WIDTH = 250
local SIDE_WIDTH = 250
local TOP = 70 -- below the top bar
local JUMP_CLEARANCE = 112 -- screen px kept clear above the bottom-right corner (Roblox's jump button)

local CALL_INK: { [string]: Color3 } = {
	BOARDED = Color3.fromRGB(38, 112, 70),
	["TURNED AWAY"] = C.stampRed,
	["WINDOW CLOSED"] = C.paperMuted,
}

local KEYS = {
	board = { Enum.KeyCode.B, Enum.KeyCode.ButtonA },
	deny = { Enum.KeyCode.T, Enum.KeyCode.ButtonB },
	page = { Enum.KeyCode.P, Enum.KeyCode.ButtonX },
	continue = { Enum.KeyCode.Return, Enum.KeyCode.Space, Enum.KeyCode.ButtonA },
}

-- How to start a shift, by input: the time clock's ProximityPrompt keys.
local CLOCK_IN_HOW: { [string]: string } = {
	Touch = "Walk to the time clock by the booth door and hold <b>Clock in</b>.",
	Gamepad = "Walk to the time clock by the booth door and hold <b>X</b>.",
	KeyboardAndMouse = "Walk to the time clock by the booth door and hold <b>E</b>.",
}

-- Looking down into the booth while the tide comes in (degrees).
local FLOOD_VIEW = Vector2.new(0, -26)

-- Where the camera turns for each ending (degrees; positive yaw is left).
local ENDING_VIEWS: { [string]: Vector2 } = {
	CLEAN_SHIFT = Vector2.new(24, 12), -- the lighthouse
	MARA_HOME = Vector2.new(14, 6), -- the Marigold, with the lighthouse behind
	LOW_IN_THE_WATER = Vector2.new(-30, 0), -- the Petrel, riding low
}

local HudController = {}

-- Roblox's own UI stays (player list, chat, emotes, touch controls); there are no tools
-- and no damage, so the backpack and health bar go.
local function setUpCoreGui()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	-- The chat window opens top left by default, right over the ticket.
	local chat = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
	if chat then
		chat.HorizontalAlignment = Enum.HorizontalAlignment.Left
		chat.VerticalAlignment = Enum.VerticalAlignment.Bottom
		chat.HeightScale = 0.6
	end
	-- Passengers' lines stay up a while (the engine default is 15 s), and a passenger at
	-- the window is never far enough away to shrink to "...".
	local bubbles = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
	if bubbles then
		bubbles.Enabled = true
		bubbles.BubbleDuration = 20
		bubbles.MaxDistance = 100
		bubbles.MinimizeDistance = 60
	end
end

local function screenGui(parent: Instance, name: string, order: number, insets: Enum.ScreenInsets): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = insets
	gui.DisplayOrder = order
	gui.Parent = parent
	return gui
end

local function tabButton(parent: Instance, text: string, width: number, order: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = text
	button.Size = UDim2.fromOffset(width, 56)
	button.BackgroundColor3 = C.panelLight
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = text
	button.FontFace = F.title
	button.TextSize = 17
	button.TextColor3 = C.muted
	button.LayoutOrder = order
	button.Selectable = true
	Ui.corner(button, UDim.new(0, 6))
	button.Parent = parent
	return button
end

local function setTabSelected(button: TextButton, selected: boolean)
	button.BackgroundTransparency = if selected then 0 else 1
	button.TextColor3 = if selected then C.lamp else C.muted
end

function HudController.start()
	setUpCoreGui()

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

	local stateRemote = Net.event(Config.Remotes.State)
	local fxRemote = Net.event(Config.Remotes.Fx)
	local progressRemote = Net.event(Config.Remotes.Progress)
	local actionRemote = Net.event(Config.Remotes.Action)

	-- Full-screen layers behind the HUD: a dim for the cards, a red flash, and a blackout
	-- that hides the jump between the pier and the booth.
	local backdrop = screenGui(playerGui, "LastFerryBackdrop", 5, Enum.ScreenInsets.None)
	local dim = Ui.frame(backdrop, "Dim", UDim2.fromScale(1, 1))
	dim.BackgroundColor3 = C.ink
	local flash = Ui.frame(backdrop, "Flash", UDim2.fromScale(1, 1))
	flash.BackgroundColor3 = Color3.fromRGB(150, 16, 16)
	local blackout = Ui.frame(backdrop, "Blackout", UDim2.fromScale(1, 1))
	blackout.BackgroundColor3 = Color3.new(0, 0, 0)
	blackout.ZIndex = 10

	-- The HUD itself stays inside the safe area (clear of notches and Roblox's buttons),
	-- laid out at design size and scaled to fit.
	local hud = screenGui(playerGui, "LastFerryHud", 6, Enum.ScreenInsets.CoreUISafeInsets)
	local root = Ui.frame(hud, "Root", UDim2.fromScale(1, 1))
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = root

	-- In first person Roblox locks the mouse to the middle of the screen. A visible Modal
	-- button frees it, so the HUD can be clicked; holding the right button still looks around.
	local cursor = Instance.new("TextButton")
	cursor.Name = "FreeCursor"
	cursor.Size = UDim2.fromOffset(1, 1)
	cursor.BackgroundTransparency = 1
	cursor.Text = ""
	cursor.AutoButtonColor = false
	cursor.Selectable = false
	cursor.Modal = true
	cursor.Visible = false
	cursor.Parent = hud

	local play = Ui.frame(root, "Play", UDim2.fromScale(1, 1))
	play.ZIndex = 1
	local overlay = Overlay.new(root)
	overlay.root.ZIndex = 5

	-- The pier: the game's name, how to start a shift, and the endings found so far.
	local lobby = Ui.panel(root, "Lobby", UDim2.fromOffset(560, 0), UDim2.new(0.5, 0, 0, 10), Vector2.new(0.5, 0))
	lobby.AutomaticSize = Enum.AutomaticSize.Y
	lobby.BackgroundColor3 = C.ink
	lobby.BackgroundTransparency = 0.2
	lobby.Visible = false
	Ui.padding(lobby, 10, 18)
	Ui.list(lobby, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center)
	local lobbyTitle = Ui.label(lobby, "Title", {
		text = "LAST FERRY",
		font = F.title,
		size = 34,
		color = C.lamp,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 40),
		order = 1,
	})
	Widgets.outline(lobbyTitle)
	local lobbyHow = Ui.label(lobby, "How", {
		font = F.body,
		size = 18,
		rich = true,
		wrap = true,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 0),
		autoSize = Enum.AutomaticSize.Y,
		order = 2,
	})
	local lobbyFound = Ui.label(lobby, "Found", {
		font = F.body,
		size = 15,
		color = C.muted,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 20),
		order = 3,
	})

	-- Top bar -------------------------------------------------------------------
	local topBar = Ui.frame(play, "TopBar", UDim2.new(1, -32, 0, 56), UDim2.fromOffset(16, 6))
	local topLeft = Ui.frame(topBar, "Left", UDim2.fromScale(0.62, 1))
	Ui.list(topLeft, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local nightLabel = Ui.label(topLeft, "Night", {
		font = F.title,
		size = 26,
		color = C.lamp,
		frameSize = UDim2.fromScale(0, 1),
		autoSize = Enum.AutomaticSize.X,
		order = 1,
	})
	local whenLabel = Ui.label(topLeft, "When", {
		font = F.body,
		size = 17,
		frameSize = UDim2.fromScale(0, 1),
		autoSize = Enum.AutomaticSize.X,
		order = 2,
	})
	Widgets.outline(nightLabel)
	Widgets.outline(whenLabel)

	local topRight = Ui.frame(topBar, "Right", UDim2.fromScale(0.38, 1), UDim2.fromScale(1, 0), Vector2.new(1, 0))
	Ui.list(topRight, Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
	local ledgerButton = Ui.button(topRight, "Ledger", "LEDGER", UDim2.fromOffset(130, 56), {
		fill = C.panelLight,
		textSize = 17,
	})
	ledgerButton.LayoutOrder = 1
	ledgerButton.Visible = false
	local queueLabel = Ui.label(topRight, "Queue", {
		font = F.title,
		size = 18,
		frameSize = UDim2.fromScale(0, 1),
		autoSize = Enum.AutomaticSize.X,
		order = 2,
	})
	Widgets.outline(queueLabel)
	local lanternRow = Ui.frame(topRight, "Lanterns", UDim2.fromOffset(64, 24))
	lanternRow.LayoutOrder = 3
	Ui.list(lanternRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local lanterns: { { frame: Frame, glow: UIStroke } } = {}
	for i = 1, 3 do
		local lantern = Ui.frame(lanternRow, `Lantern{i}`, UDim2.fromOffset(16, 22))
		lantern.BackgroundTransparency = 0
		lantern.LayoutOrder = i
		Ui.corner(lantern, UDim.new(0, 5))
		table.insert(lanterns, { frame = lantern, glow = Ui.stroke(lantern, C.lamp, 2, 0.35) })
	end

	-- A banner over the top bar: a lantern going out, or a page someone found.
	local alert = Ui.panel(play, "Alert", UDim2.new(1, -32, 0, 0), UDim2.fromOffset(16, 6))
	alert.AutomaticSize = Enum.AutomaticSize.Y
	alert.BackgroundTransparency = 0.04
	alert.ZIndex = 3
	alert.Visible = false
	Ui.padding(alert, 8, 14)
	Ui.list(alert, Enum.FillDirection.Vertical, 2)
	local alertTitle = Widgets.caption(alert, "", C.bad, 1)
	local alertText = Widgets.paragraph(alert, "", { size = 16, order = 2 })

	-- Desk: ticket, countdown, and the two calls -----------------------------------
	local desk = Ui.frame(play, "Desk", UDim2.fromOffset(DESK_WIDTH, 300), UDim2.fromOffset(16, TOP))
	local ticket = Ticket.new(desk, UDim2.fromOffset(0, 0))
	local idle = Ui.label(desk, "Idle", {
		text = "The next passenger is coming up the dock...",
		font = F.body,
		size = 17,
		color = C.muted,
		wrap = true,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(DESK_WIDTH, 44),
		position = UDim2.fromOffset(0, 70),
	})
	Widgets.outline(idle)

	local track = Ui.frame(desk, "Countdown", UDim2.fromOffset(DESK_WIDTH, 6), UDim2.fromOffset(0, 200))
	track.BackgroundTransparency = 0.35
	track.BackgroundColor3 = C.panel
	Ui.corner(track, UDim.new(0, 3))
	local trackFill = Ui.frame(track, "Fill", UDim2.fromScale(1, 1))
	trackFill.BackgroundTransparency = 0
	trackFill.BackgroundColor3 = C.lamp
	Ui.corner(trackFill, UDim.new(0, 3))
	local countdownLabel = Ui.label(desk, "CountdownLabel", {
		font = F.title,
		size = 15,
		frameSize = UDim2.fromOffset(DESK_WIDTH, 18),
		position = UDim2.fromOffset(0, 210),
	})
	Widgets.outline(countdownLabel)

	local half = (DESK_WIDTH - 12) / 2
	local boardButton = Ui.button(desk, "Board", "BOARD", UDim2.fromOffset(half, 64), { fill = C.board, textSize = 26 })
	boardButton.Position = UDim2.fromOffset(0, 236)
	local denyButton =
		Ui.button(desk, "Deny", "TURN AWAY", UDim2.fromOffset(half, 64), { fill = C.deny, textSize = 22 })
	denyButton.Position = UDim2.fromOffset(half + 12, 236)
	local keyHints: { [TextButton]: TextLabel } = {}
	for _, button in { boardButton, denyButton } do
		local key = Ui.label(button, "Key", {
			font = F.title,
			size = 14,
			color = C.text,
			xAlign = Enum.TextXAlignment.Right,
			frameSize = UDim2.new(1, -8, 0, 16),
			position = UDim2.new(0, 0, 1, -18),
		})
		key.TextTransparency = 0.35
		keyHints[button] = key
	end

	-- Side panel: rules and manifest -----------------------------------------------
	local side =
		Ui.panel(play, "Side", UDim2.new(0, SIDE_WIDTH, 1, -(TOP + 16)), UDim2.new(1, -16, 0, TOP), Vector2.new(1, 0))
	local tabs = Ui.frame(side, "Tabs", UDim2.new(1, -16, 0, 56), UDim2.fromOffset(8, 8))
	Ui.list(tabs, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local rulesTab = tabButton(tabs, "RULES", 72, 1)
	local manifestTab = tabButton(tabs, "MANIFEST", 100, 2)
	local hideTab = tabButton(tabs, "HIDE", 50, 3)
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Scroller"
	scroller.Position = UDim2.fromOffset(10, 72)
	scroller.Size = UDim2.new(1, -16, 1, -80)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.CanvasSize = UDim2.new()
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.ScrollBarThickness = 5
	scroller.ScrollBarImageColor3 = C.line
	scroller.Parent = side
	local rulesList = Ui.frame(scroller, "Rules", UDim2.new(1, -8, 0, 0))
	rulesList.AutomaticSize = Enum.AutomaticSize.Y
	Ui.list(rulesList, Enum.FillDirection.Vertical, 10)
	local manifestList = Ui.frame(scroller, "Manifest", UDim2.new(1, -8, 0, 0))
	manifestList.AutomaticSize = Enum.AutomaticSize.Y
	manifestList.Visible = false
	Ui.list(manifestList, Enum.FillDirection.Vertical, 4)
	local showSide =
		Ui.button(play, "ShowRules", "RULES", UDim2.fromOffset(110, 64), { fill = C.panelLight, textSize = 18 })
	showSide.AnchorPoint = Vector2.new(1, 0)
	showSide.Position = UDim2.new(1, -16, 0, TOP)
	showSide.Visible = false

	-- Top centre: Pike's radio -----------------------------------------------------------
	local center = Ui.frame(play, "Center", UDim2.fromOffset(300, 0), UDim2.new(0.5, 30, 0, 56), Vector2.new(0.5, 0))
	center.AutomaticSize = Enum.AutomaticSize.Y
	Ui.list(center, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center)

	local function bubble(name: string, order: number): Frame
		local frame = Ui.panel(center, name, UDim2.fromScale(1, 0))
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.LayoutOrder = order
		frame.Visible = false
		Ui.padding(frame, 10, 14)
		Ui.list(frame, Enum.FillDirection.Vertical, 4)
		return frame
	end

	local radio = bubble("Radio", 1)
	Widgets.caption(radio, "RADIO · PIKE, AT THE LIGHTHOUSE", C.radio, 1)
	local radioText = Widgets.paragraph(radio, "", { size = 16, order = 2 })

	-- Bottom centre: how to look around, on the first night only.
	local hint = Ui.label(play, "Hint", {
		font = F.body,
		size = 16,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(560, 22),
		position = UDim2.new(0.5, 0, 1, -12),
		anchor = Vector2.new(0.5, 1),
	})
	Widgets.outline(hint)

	-- Ledger: the harbormaster's torn pages found this run. It opens over the rules
	-- panel and blocks nothing else, so the window can still be worked.
	local ledger =
		Ui.frame(play, "Ledger", UDim2.new(0, SIDE_WIDTH, 1, -(TOP + 16)), UDim2.new(1, -16, 0, TOP), Vector2.new(1, 0))
	ledger.ZIndex = 2
	ledger.Visible = false
	ledger.BackgroundTransparency = 0
	ledger.BackgroundColor3 = C.paper
	ledger.Active = true
	Ui.corner(ledger, UDim.new(0, 8))
	Ui.stroke(ledger, C.paperShade, 2)
	Ui.padding(ledger, 12)
	local sheet = ledger
	Ui.label(sheet, "Heading", {
		text = "HARBORMASTER'S LEDGER",
		font = F.title,
		size = 18,
		color = C.paperInk,
		frameSize = UDim2.new(1, 0, 0, 24),
	})
	local ledgerCount = Ui.label(sheet, "Count", {
		font = F.title,
		size = 14,
		color = C.paperMuted,
		frameSize = UDim2.new(1, 0, 0, 18),
		position = UDim2.fromOffset(0, 24),
	})
	local pages = Instance.new("ScrollingFrame")
	pages.Name = "Pages"
	pages.Position = UDim2.fromOffset(0, 48)
	pages.Size = UDim2.new(1, 0, 1, -48 - 72)
	pages.BackgroundTransparency = 1
	pages.BorderSizePixel = 0
	pages.CanvasSize = UDim2.new()
	pages.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pages.ScrollingDirection = Enum.ScrollingDirection.Y
	pages.ScrollBarThickness = 5
	pages.ScrollBarImageColor3 = C.paperShade
	pages.Parent = sheet
	local closeLedger = Ui.button(sheet, "Close", "PUT IT AWAY", UDim2.new(1, 0, 0, 64), {
		fill = C.paperInk,
		text = C.paper,
		textSize = 20,
	})
	closeLedger.AnchorPoint = Vector2.new(0, 1)
	closeLedger.Position = UDim2.fromScale(0, 1)

	-- State -------------------------------------------------------------------------
	local lastState: View.State? = nil
	local progress: View.Progress? = nil
	local calledFor: number? = nil -- passenger id this player already made a call for
	local rulesKey = ""
	local manifestKey = ""
	local showingManifest = false
	local sideHidden = false
	local speechPassenger: number? = nil -- the passenger who last came to the window
	local speaker = "" -- their name, for the chat log
	local radioUntil = 0
	local alertUntil = 0
	local ledgerToken = 0
	local previousPhase = ""
	local myName = player.DisplayName

	local function personalize(line: string): string
		return (string.gsub(line, "{name}", function()
			return myName
		end))
	end

	-- Rich text in the chat window: keep names and lines literal.
	local function escape(text: string): string
		return (
			string.gsub(text, "[&<>\"']", {
				["&"] = "&amp;",
				["<"] = "&lt;",
				[">"] = "&gt;",
				['"'] = "&quot;",
				["'"] = "&apos;",
			})
		)
	end

	local passengers = workspace:WaitForChild("World"):WaitForChild("Passengers")
	local function logToChat(who: string, color: string, text: string)
		local channels = TextChatService:FindFirstChild("TextChannels")
		local system = channels and channels:FindFirstChild("RBXSystem")
		if system and system:IsA("TextChannel") then
			system:DisplaySystemMessage(`<font color="{color}"><b>{escape(who)}</b></font>: {escape(text)}`)
		end
	end

	-- A passenger says something: a bubble over them, and a line in the chat. The bubble goes
	-- on the whole model (always the same instance for the same passenger), so Roblox floats
	-- it above their hat.
	local function speak(passengerId: number?, who: string, text: string)
		local line = personalize(text)
		local model = if passengerId then passengers:FindFirstChild(`Passenger{passengerId}`) else nil
		if model and model:IsA("Model") then
			TextChatService:DisplayBubble(model, line)
		end
		logToChat(who, "#FFC684", line)
	end

	local function touchControls(): boolean
		return UserInputService.PreferredInput == Enum.PreferredInput.Touch
	end

	-- The rules panel and the ledger run down the right side, stopping short of Roblox's
	-- jump button on touch screens.
	local function layoutSide()
		local bottom = 16
		if touchControls() then
			bottom += math.ceil(JUMP_CLEARANCE / uiScale.Scale)
		end
		side.Size = UDim2.new(0, SIDE_WIDTH, 1, -(TOP + bottom))
		ledger.Size = side.Size
	end

	local function rescale()
		local size = hud.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local scale = math.clamp(
			math.min(size.X / Theme.DesignWidth, size.Y / Theme.DesignHeight),
			Theme.MinScale,
			Theme.MaxScale
		)
		uiScale.Scale = scale
		root.Size = UDim2.fromScale(1 / scale, 1 / scale)
		overlay.resize(size / scale)
		layoutSide()
	end

	local function refreshHint()
		local input = UserInputService.PreferredInput
		local boardKey, denyKey = "", ""
		if input == Enum.PreferredInput.Touch then
			hint.Text = "Drag to look around · Pinch to lean in"
		elseif input == Enum.PreferredInput.Gamepad then
			hint.Text = "Right stick to look · Hold R2 to lean in · A board · B turn away · X take a page"
			boardKey, denyKey = "A", "B"
		else
			hint.Text =
				"Hold the right mouse button to look · Scroll to lean in · B board · T turn away · P take a page"
			boardKey, denyKey = "B", "T"
		end
		keyHints[boardButton].Text = boardKey
		keyHints[denyButton].Text = denyKey
		lobbyHow.Text = CLOCK_IN_HOW[input.Name] or CLOCK_IN_HOW.KeyboardAndMouse
		layoutSide()
	end

	local function refreshLobby()
		local found = if progress then #progress.found else 0
		local total = if progress then progress.total else 0
		lobbyFound.Text = if total > 0 then `Endings found: {found} of {total}` else ""
		lobbyFound.Visible = total > 0
	end

	local function showAlert(title: string, text: string, color: Color3, background: Color3, seconds: number)
		alertTitle.Text = title
		alertTitle.TextColor3 = color
		alertText.Text = text
		alert.BackgroundColor3 = background
		alertUntil = os.clock() + seconds
	end

	local function refreshSide()
		side.Visible = not sideHidden
		showSide.Visible = sideHidden
		rulesList.Visible = not showingManifest
		manifestList.Visible = showingManifest
		setTabSelected(rulesTab, not showingManifest)
		setTabSelected(manifestTab, showingManifest)
		scroller.CanvasPosition = Vector2.zero
	end

	local function renderRules(state: View.State)
		local key = `{state.night}|{state.date}|{#state.rules}`
		if key ~= rulesKey then
			rulesKey = key
			for _, child in rulesList:GetChildren() do
				if child:IsA("GuiObject") then
					child:Destroy()
				end
			end
			for i, rule in state.rules do
				Widgets.ruleRow(rulesList, i, rule, 16)
			end
		end

		local manifest = state.manifest
		manifestTab.Interactable = manifest ~= nil
		manifestTab.TextTransparency = if manifest then 0 else 0.6
		local newKey = if manifest then table.concat(manifest, "|") else ""
		if newKey ~= manifestKey then
			manifestKey = newKey
			for _, child in manifestList:GetChildren() do
				if child:IsA("GuiObject") then
					child:Destroy()
				end
			end
			if manifest then
				Widgets.caption(manifestList, `TONIGHT'S MANIFEST · {state.date}`, C.muted, 0)
				for i, name in manifest do
					Ui.label(manifestList, "Name", {
						text = name,
						font = F.ticket,
						size = 17,
						order = i,
					})
				end
			elseif showingManifest then
				showingManifest = false
				refreshSide()
			end
		end
	end

	local function renderLedger(state: View.State)
		for _, child in pages:GetChildren() do
			if child:IsA("GuiObject") or child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		Ui.list(pages, Enum.FillDirection.Vertical, 12)
		ledgerCount.Text = `{#state.ledger} OF {state.finalNight} PAGES`
		for i, page in state.ledger do
			local entry = Ui.frame(pages, "Page", UDim2.new(1, -10, 0, 0))
			entry.AutomaticSize = Enum.AutomaticSize.Y
			entry.LayoutOrder = page.night
			Ui.list(entry, Enum.FillDirection.Vertical, 2)
			Widgets.caption(entry, `PAGE {page.night}`, if i == #state.ledger then C.stampRed else C.paperMuted, 1)
			Widgets.paragraph(entry, page.text, { font = F.ticket, size = 16, color = C.paperInk, order = 2 })
		end
	end

	local function openLedger(autoClose: boolean)
		local state = lastState
		if state == nil or #state.ledger == 0 then
			return
		end
		renderLedger(state)
		ledger.Visible = true
		ledgerToken += 1
		local token = ledgerToken
		if autoClose then
			task.delay(14, function()
				if ledgerToken == token then
					ledger.Visible = false
				end
			end)
		end
	end

	local function refreshButtons()
		local state = lastState
		local passenger = if state and state.phase == "window" then state.passenger else nil
		local canCall = passenger ~= nil and calledFor ~= passenger.id
		boardButton.Interactable = canCall
		denyButton.Interactable = canCall
	end

	local function refreshSpeech()
		local now = os.clock()
		local state = lastState
		-- The radio never covers someone at the window: the shift pauses for it.
		radio.Visible = now < radioUntil and not (state and state.phase == "window")
		alert.Visible = now < alertUntil
		topBar.Visible = not alert.Visible and state ~= nil and state.night > 0
	end

	local function render(state: View.State)
		lastState = state
		local phase = state.phase

		-- Layers and screen effects for the phase. Between shifts ("waiting") everyone is
		-- out on the pier with only the lobby banner up.
		local cardPhase = phase == "intro" or phase == "summary"
		play.Visible = phase == "queue" or phase == "window" or phase == "failed"
		lobby.Visible = phase == "waiting"
		dim.BackgroundTransparency = if cardPhase then 0.45 elseif phase == "ending" then 0.8 else 1
		EffectsController.setBlur(cardPhase)
		EffectsController.setFlooded(phase == "failed")
		overlay.render(state, progress)
		if cardPhase or phase == "ending" or phase == "waiting" then
			ledger.Visible = false
		end

		if phase ~= previousPhase then
			if phase == "intro" then
				-- Every night starts looking out of the window (after the flood, too).
				CameraController.faceWindow()
				calledFor = nil
			elseif phase == "failed" then
				CameraController.lookTo(FLOOD_VIEW.X, FLOOD_VIEW.Y)
			elseif phase == "ending" and state.ending then
				local view = ENDING_VIEWS[state.ending.id]
				if view then
					CameraController.lookTo(view.X, view.Y)
				end
			end
			previousPhase = phase
		end

		-- Top bar.
		nightLabel.Text = `NIGHT {state.night} OF {state.finalNight}`
		whenLabel.Text = `{state.date} · {state.clock}`
		queueLabel.Text = `IN LINE: {state.waiting}`
		for i, lantern in lanterns do
			local lit = i <= state.lanterns
			lantern.frame.BackgroundColor3 = if lit then C.lamp else C.panel
			lantern.glow.Transparency = if lit then 0.35 else 0.85
			lantern.frame.Visible = i <= state.maxLanterns
		end
		ledgerButton.Visible = #state.ledger > 0
		ledgerButton.Text = `LEDGER {#state.ledger}/{state.finalNight}`
		if ledger.Visible then
			renderLedger(state)
		end

		-- Desk.
		local passenger = if phase == "window" then state.passenger else nil
		if passenger then
			ticket.show(passenger)
			if passenger.id ~= speechPassenger then
				-- Someone new at the window says their piece.
				speechPassenger = passenger.id
				speaker = passenger.ticket.name
				speak(passenger.id, speaker, passenger.line)
			end
		else
			ticket.clear()
		end
		idle.Visible = phase == "queue" and passenger == nil and not ticket.root.Visible
		track.Visible = passenger ~= nil
		countdownLabel.Visible = passenger ~= nil
		refreshButtons()

		renderRules(state)
		hint.Visible = state.night == 1 and (phase == "window" or phase == "queue")
		refreshSpeech()
	end

	local function onFx(fx: View.Fx)
		local text = fx.text or ""
		if fx.kind == "call" then
			ticket.stamp(text, CALL_INK[text] or C.paperMuted)
		elseif fx.kind == "lanternOut" then
			showAlert("A LANTERN GOES OUT", text, C.bad, Color3.fromRGB(58, 18, 18), 6)
			EffectsController.lanternOut()
			CameraController.shake(1.4, 0.5)
			flash.BackgroundTransparency = 0.55
			TweenService:Create(flash, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
		elseif fx.kind == "say" then
			-- What the passenger just called says as they leave the window.
			speak(speechPassenger, speaker, text)
		elseif fx.kind == "radio" then
			logToChat("Radio · Pike", "#AAD6BE", text)
			radioText.Text = text
			radioText.MaxVisibleGraphemes = 0
			radioUntil = os.clock() + 16
			task.spawn(function()
				local total = utf8.len(text) or #text
				for shown = 1, total do
					if radioText.Text ~= text then
						return
					end
					radioText.MaxVisibleGraphemes = shown
					task.wait(0.025)
				end
				radioText.MaxVisibleGraphemes = -1
			end)
		elseif fx.kind == "page" then
			if fx.by == player.UserId then
				-- The state with the new page arrives right after; open the ledger then.
				task.defer(openLedger, true)
			else
				showAlert(
					"A TORN PAGE",
					"Someone found a page tucked behind a ticket. It's in the LEDGER.",
					C.lamp,
					C.panel,
					5
				)
			end
		end
		refreshSpeech()
	end

	-- Wiring -------------------------------------------------------------------------
	-- Each returns whether it did anything, so a key that does nothing here passes on to
	-- Roblox's own controls.
	local function call(kind: string): boolean
		local state = lastState
		local passenger = if state and state.phase == "window" then state.passenger else nil
		if passenger == nil or calledFor == passenger.id then
			return false
		end
		calledFor = passenger.id
		actionRemote:FireServer(kind, passenger.id)
		refreshButtons()
		return true
	end
	boardButton.Activated:Connect(function()
		call("board")
	end)
	denyButton.Activated:Connect(function()
		call("deny")
	end)
	local function takePage(): boolean
		local state = lastState
		local passenger = if state and state.phase == "window" then state.passenger else nil
		if passenger and passenger.hasPage then
			actionRemote:FireServer("page", passenger.id)
			return true
		end
		return false
	end
	ticket.onTakePage(function()
		takePage()
	end)

	-- Shortcuts sit above Roblox's controls (which bind at Medium priority) and sink a key
	-- only when they use it: gamepad A boards at the window, continues on a card, and
	-- jumps the rest of the time.
	local function bindKey(name: string, keys: { Enum.KeyCode }, handler: () -> boolean)
		ContextActionService:BindActionAtPriority(
			name,
			function(_action: string, inputState: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
				if inputState == Enum.UserInputState.Begin and handler() then
					return Enum.ContextActionResult.Sink
				end
				return Enum.ContextActionResult.Pass
			end,
			false,
			Enum.ContextActionPriority.High.Value,
			table.unpack(keys)
		)
	end
	bindKey("LastFerryContinue", KEYS.continue, function(): boolean
		return overlay.pressContinue()
	end)
	bindKey("LastFerryBoard", KEYS.board, function(): boolean
		return call("board")
	end)
	bindKey("LastFerryDeny", KEYS.deny, function(): boolean
		return call("deny")
	end)
	bindKey("LastFerryPage", KEYS.page, takePage)
	overlay.onContinue(function()
		actionRemote:FireServer("continue")
	end)

	-- Clocking in or out: a moment of black hides the jump between the pier and the booth,
	-- and the cursor is freed for the HUD while on shift.
	local function onShiftChanged()
		local onShift = player:GetAttribute("OnShift") == true
		cursor.Visible = onShift
		blackout.BackgroundTransparency = 0
		TweenService:Create(blackout, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
	end
	player:GetAttributeChangedSignal("OnShift"):Connect(onShiftChanged)
	cursor.Visible = player:GetAttribute("OnShift") == true
	rulesTab.Activated:Connect(function()
		showingManifest = false
		refreshSide()
	end)
	manifestTab.Activated:Connect(function()
		if manifestTab.Interactable then
			showingManifest = true
			refreshSide()
		end
	end)
	hideTab.Activated:Connect(function()
		sideHidden = true
		refreshSide()
	end)
	showSide.Activated:Connect(function()
		sideHidden = false
		refreshSide()
	end)
	ledgerButton.Activated:Connect(function()
		openLedger(false)
	end)
	closeLedger.Activated:Connect(function()
		ledgerToken += 1
		ledger.Visible = false
	end)

	hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshHint)
	rescale()
	refreshHint()
	refreshSide()

	-- The countdown bar and the timers on the cards.
	local lastTick = 0
	RunService.Heartbeat:Connect(function()
		local state = lastState
		if state == nil then
			return
		end
		local passenger = if state.phase == "window" then state.passenger else nil
		if passenger then
			local left = math.max(0, passenger.deadline - workspace:GetServerTimeNow())
			local share = math.clamp(left / Config.DecisionTime, 0, 1)
			trackFill.Size = UDim2.fromScale(share, 1)
			trackFill.BackgroundColor3 = if left < 10 then C.bad else C.lamp
			countdownLabel.Text = `THE WINDOW CLOSES IN {math.ceil(left)}s`
		end
		local now = os.clock()
		if now - lastTick > 0.25 then
			lastTick = now
			overlay.tick(state)
			refreshSpeech()
		end
	end)

	stateRemote.OnClientEvent:Connect(render)
	fxRemote.OnClientEvent:Connect(onFx)
	progressRemote.OnClientEvent:Connect(function(payload: View.Progress)
		progress = payload
		refreshLobby()
		local state = lastState
		if state then
			overlay.render(state, progress)
		end
	end)
	-- Ask for the current screen now that we're listening.
	actionRemote:FireServer("sync")
end

return HudController
