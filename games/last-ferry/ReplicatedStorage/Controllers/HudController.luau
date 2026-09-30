--!strict
--[[
	HudController: everything on screen while you work the window, wired to the
	server's remotes.

	Layout, on a canvas at least 960 x 480 scaled to fit the screen (see Theme):
		top bar        night, date and clock · lanterns, queue, ledger
		left "desk"    the ticket, the window countdown, BOARD / TURN AWAY
		right          the rules card and, from night 3, the manifest (can be hidden)
		top centre     what the passenger says, the radio, lost-lantern notes
		bottom centre  kept clear: that's where the planks and the shadows are

	The server sends the whole screen state on every change (ShiftState) plus
	one-off effects (ShiftFx). Nothing here decides anything; it only draws what
	it's told and sends the player's presses back.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
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

local CALL_INK: { [string]: Color3 } = {
	BOARDED = Color3.fromRGB(38, 112, 70),
	["TURNED AWAY"] = C.stampRed,
	["WINDOW CLOSED"] = C.paperMuted,
}

-- Where the camera turns for each ending (degrees; positive yaw is left).
local ENDING_VIEWS: { [string]: Vector2 } = {
	CLEAN_SHIFT = Vector2.new(24, 12), -- the lighthouse
	MARA_HOME = Vector2.new(14, 6), -- the Marigold, with the lighthouse behind
	LOW_IN_THE_WATER = Vector2.new(-30, 0), -- the Petrel, riding low
}

local HudController = {}

local function quietCoreGui()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	GuiService.TouchControlsEnabled = false
	-- There's no avatar to reset. SetCore fails until the core scripts are ready, so retry.
	task.spawn(function()
		for _ = 1, 30 do
			local ok = pcall(function()
				StarterGui:SetCore("ResetButtonCallback", false)
			end)
			if ok then
				return
			end
			task.wait(0.5)
		end
	end)
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
	quietCoreGui()

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

	local stateRemote = Net.event(Config.Remotes.State)
	local fxRemote = Net.event(Config.Remotes.Fx)
	local progressRemote = Net.event(Config.Remotes.Progress)
	local actionRemote = Net.event(Config.Remotes.Action)

	-- Full-screen layers behind the HUD: a dim for the cards, and a red flash.
	local backdrop = screenGui(playerGui, "LastFerryBackdrop", 5, Enum.ScreenInsets.None)
	local dim = Ui.frame(backdrop, "Dim", UDim2.fromScale(1, 1))
	dim.BackgroundColor3 = C.ink
	local flash = Ui.frame(backdrop, "Flash", UDim2.fromScale(1, 1))
	flash.BackgroundColor3 = Color3.fromRGB(150, 16, 16)

	-- The HUD itself stays inside the safe area (clear of notches and Roblox's buttons),
	-- laid out at design size and scaled to fit.
	local hud = screenGui(playerGui, "LastFerryHud", 6, Enum.ScreenInsets.CoreUISafeInsets)
	local root = Ui.frame(hud, "Root", UDim2.fromScale(1, 1))
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = root

	local play = Ui.frame(root, "Play", UDim2.fromScale(1, 1))
	play.ZIndex = 1
	local overlay = Overlay.new(root)
	overlay.root.ZIndex = 5

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

	-- Top centre: speech, radio, lost lanterns -----------------------------------------
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

	local speech = bubble("Speech", 1)
	local speechText =
		Widgets.paragraph(speech, "", { font = F.speech, size = 19, xAlign = Enum.TextXAlignment.Center })
	local radio = bubble("Radio", 2)
	Widgets.caption(radio, "RADIO · PIKE, AT THE LIGHTHOUSE", C.radio, 1)
	local radioText = Widgets.paragraph(radio, "", { size = 16, order = 2 })
	local message = bubble("Message", 3)
	message.BackgroundColor3 = Color3.fromRGB(58, 18, 18)
	Widgets.caption(message, "A LANTERN GOES OUT", C.bad, 1)
	local messageText = Widgets.paragraph(message, "", { size = 16, order = 2 })

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

	-- Ledger: the harbormaster's torn pages found this run ---------------------------------
	local ledger = Ui.frame(root, "LedgerModal", UDim2.fromScale(1, 1))
	ledger.ZIndex = 10
	ledger.Active = true
	ledger.Visible = false
	local sheet =
		Ui.frame(ledger, "Sheet", UDim2.fromOffset(470, 380), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	sheet.BackgroundTransparency = 0
	sheet.BackgroundColor3 = C.paper
	sheet.Active = true
	Ui.corner(sheet, UDim.new(0, 8))
	Ui.stroke(sheet, C.paperShade, 2)
	Ui.padding(sheet, 16)
	Ui.label(sheet, "Heading", {
		text = "HARBORMASTER'S LEDGER · R. VELL",
		font = F.title,
		size = 18,
		color = C.paperInk,
		frameSize = UDim2.new(1, 0, 0, 24),
	})
	local ledgerCount = Ui.label(sheet, "Count", {
		font = F.title,
		size = 15,
		color = C.paperMuted,
		xAlign = Enum.TextXAlignment.Right,
		frameSize = UDim2.new(1, 0, 0, 24),
	})
	local pages = Instance.new("ScrollingFrame")
	pages.Name = "Pages"
	pages.Position = UDim2.fromOffset(0, 32)
	pages.Size = UDim2.new(1, 0, 1, -32 - 72)
	pages.BackgroundTransparency = 1
	pages.BorderSizePixel = 0
	pages.CanvasSize = UDim2.new()
	pages.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pages.ScrollingDirection = Enum.ScrollingDirection.Y
	pages.ScrollBarThickness = 5
	pages.ScrollBarImageColor3 = C.paperShade
	pages.Parent = sheet
	local closeLedger = Ui.button(sheet, "Close", "PUT IT AWAY", UDim2.fromOffset(190, 64), {
		fill = C.paperInk,
		text = C.paper,
		textSize = 20,
	})
	closeLedger.AnchorPoint = Vector2.new(1, 1)
	closeLedger.Position = UDim2.fromScale(1, 1)

	-- State -------------------------------------------------------------------------
	local lastState: View.State? = nil
	local progress: View.Progress? = nil
	local calledFor: number? = nil -- passenger id this player already made a call for
	local rulesKey = ""
	local manifestKey = ""
	local showingManifest = false
	local sideHidden = false
	local sayText: string? = nil
	local sayUntil = 0
	local radioUntil = 0
	local messageUntil = 0
	local ledgerToken = 0
	local previousPhase = ""
	local myName = player.DisplayName

	local function personalize(line: string): string
		return (string.gsub(line, "{name}", function()
			return myName
		end))
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
	end

	local function refreshHint()
		local input = UserInputService.PreferredInput
		if input == Enum.PreferredInput.Touch then
			hint.Text = "Drag to look around · Pinch to lean in"
		elseif input == Enum.PreferredInput.Gamepad then
			hint.Text = "Right stick to look around · Hold R2 to lean in"
		else
			hint.Text = "Drag to look around · Scroll to lean in · Arrow keys work too"
		end
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
		local text: string? = nil
		if sayText and now < sayUntil then
			text = sayText
		elseif state and state.phase == "window" and state.passenger then
			text = personalize(state.passenger.line)
		end
		speech.Visible = text ~= nil
		if text then
			speechText.Text = `“{text}”`
		end
		radio.Visible = now < radioUntil
		message.Visible = now < messageUntil
	end

	local function render(state: View.State)
		lastState = state
		local phase = state.phase

		-- Layers and screen effects for the phase.
		local cardPhase = phase == "waiting" or phase == "intro" or phase == "summary"
		play.Visible = phase == "queue" or phase == "window" or phase == "failed"
		dim.BackgroundTransparency = if cardPhase then 0.45 elseif phase == "ending" then 0.8 else 1
		EffectsController.setBlur(cardPhase)
		EffectsController.setFlooded(phase == "failed")
		overlay.render(state, progress)
		if cardPhase or phase == "ending" then
			ledger.Visible = false
		end

		if phase ~= previousPhase then
			if phase == "intro" then
				CameraController.lookTo(0, 0)
			elseif phase == "ending" and state.ending then
				local view = ENDING_VIEWS[state.ending.id]
				if view then
					CameraController.lookTo(view.X, view.Y)
				end
			end
			previousPhase = phase
		end

		-- Top bar.
		topBar.Visible = state.night > 0
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
			messageText.Text = text
			messageUntil = os.clock() + 6
			EffectsController.lanternOut()
			CameraController.shake(1.4, 0.5)
			flash.BackgroundTransparency = 0.55
			TweenService:Create(flash, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
		elseif fx.kind == "say" then
			sayText = text
			sayUntil = os.clock() + 5
		elseif fx.kind == "radio" then
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
			-- The state with the new page arrives right after; open the ledger then.
			task.defer(openLedger, true)
		end
		refreshSpeech()
	end

	-- Wiring -------------------------------------------------------------------------
	local function call(kind: string)
		local state = lastState
		local passenger = if state and state.phase == "window" then state.passenger else nil
		if passenger == nil or calledFor == passenger.id then
			return
		end
		calledFor = passenger.id
		actionRemote:FireServer(kind, passenger.id)
		refreshButtons()
	end
	boardButton.Activated:Connect(function()
		call("board")
	end)
	denyButton.Activated:Connect(function()
		call("deny")
	end)
	ticket.onTakePage(function()
		local state = lastState
		local passenger = if state then state.passenger else nil
		if passenger and passenger.hasPage then
			actionRemote:FireServer("page", passenger.id)
		end
	end)
	overlay.onContinue(function()
		actionRemote:FireServer("continue")
	end)
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
		local state = lastState
		if state then
			overlay.render(state, progress)
		end
	end)
	-- Ask for the current screen now that we're listening.
	actionRemote:FireServer("sync")
end

return HudController
