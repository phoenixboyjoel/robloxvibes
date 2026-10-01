--!strict
--[[
	Overlay: the cards between the action. (Between shifts, "waiting", there's no card:
	everyone is out on the pier and the HUD shows only the lobby banner.)
		intro   - "Night 3": tonight's rules (new ones marked) and Pike on the radio
		summary - every call from the night, and why it was right or wrong
		failed  - the tide came in (no button; the night restarts on a timer)
		ending  - the ending, the ledger epilogue if earned, and endings found so far.
		          For the first few seconds only a title strip shows, so the ending's
		          scene (the lighthouse, the Marigold, the ferry leaving) is seen first.

	Continue marks this player ready; the phase moves on when everyone is ready
	or its timer runs out. The HUD decides what is blurred or dimmed behind.
]]

local View = require("../Shared/Types")
local Theme = require("./Theme")
local Ui = require("./Ui")
local Widgets = require("./Widgets")

export type Overlay = {
	root: Frame,
	render: (state: View.State, progress: View.Progress?) -> (),
	tick: (state: View.State) -> (),
	onContinue: (callback: () -> ()) -> (),
	pressContinue: () -> boolean, -- the Continue key or gamepad button; true if it pressed
	resize: (designSize: Vector2) -> (),
}

local C = Theme.Colors
local F = Theme.Fonts

local HEADER, FOOTER, PAD = 92, 76, 20
local ENDING_SCENE_TIME = 7 -- seconds of ending scene before the text card rises

local Overlay = {}

local CONTINUE_TEXT: { [string]: string } = {
	intro = "OPEN THE WINDOW",
	summary = "NEXT NIGHT",
	ending = "CLOCK OUT",
}

local TIMER_TEXT: { [string]: string } = {
	intro = "The window opens by itself in %ds",
	summary = "The next night starts in %ds",
	failed = "The night starts again in %ds",
	ending = "Back to the pier in %ds",
}

local function isOverlayPhase(phase: string): boolean
	return phase == "intro" or phase == "summary" or phase == "failed" or phase == "ending"
end

local function column(parent: Instance, name: string, width: UDim, x: UDim): Frame
	local frame = Ui.frame(parent, name, UDim2.new(width, UDim.new(0, 0)), UDim2.new(x, UDim.new(0, 0)))
	frame.AutomaticSize = Enum.AutomaticSize.Y
	Ui.list(frame, Enum.FillDirection.Vertical, 8)
	return frame
end

local caption = Widgets.caption
local paragraph = Widgets.paragraph

local function summaryRow(parent: Instance, index: number, row: View.SummaryRow)
	local frame = Ui.frame(parent, "Call", UDim2.fromScale(1, 0))
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.LayoutOrder = index
	frame.BackgroundTransparency = 0.3
	frame.BackgroundColor3 = C.panelLight
	Ui.corner(frame, UDim.new(0, 10))
	Ui.stroke(frame, C.outline, 2)

	-- A round green check or red cross: was the call right?
	local mark = Ui.frame(frame, "Mark", UDim2.fromOffset(30, 30), UDim2.fromOffset(8, 8))
	mark.BackgroundTransparency = 0
	mark.BackgroundColor3 = if row.correct then C.board else C.deny
	Ui.corner(mark, UDim.new(0.5, 0))
	Ui.stroke(mark, C.outline, 2.5)
	local icon = Ui.icon(mark, if row.correct then "check" else "cross", 18, C.text)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)

	local lines = Ui.frame(frame, "Lines", UDim2.new(1, -54, 0, 0), UDim2.fromOffset(46, 0))
	lines.AutomaticSize = Enum.AutomaticSize.Y
	Ui.padding(lines, 6, 0, 8, 0)
	Ui.list(lines, Enum.FillDirection.Vertical, 2)
	Ui.label(lines, "Line", {
		text = `<font face="SpecialElite">{row.name}</font>   <font color="#{(if row.correct then C.good else C.bad):ToHex()}">{row.call}</font>`,
		font = F.title,
		size = 17,
		rich = true,
		wrap = true,
		frameSize = UDim2.new(1, 0, 0, 23),
		autoSize = Enum.AutomaticSize.Y,
		order = 1,
	})
	paragraph(lines, row.note, { size = 15, color = C.muted, order = 2 })
end

function Overlay.new(parent: Instance): Overlay
	local root = Ui.frame(parent, "Overlay", UDim2.fromScale(1, 1))
	root.Visible = false

	local card = Ui.panel(root, "Card", UDim2.fromOffset(760, 440), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	card.BackgroundTransparency = 0.02
	Ui.padding(card, PAD)

	local header = Ui.frame(card, "Header", UDim2.new(1, 0, 0, HEADER))
	Ui.list(header, Enum.FillDirection.Vertical, 0)
	local kicker = Ui.label(header, "Kicker", { font = F.title, size = 15, color = C.muted, order = 1 })
	local title = Ui.label(header, "Title", {
		font = F.display,
		size = 42,
		color = C.lamp,
		order = 2,
		frameSize = UDim2.new(1, 0, 0, 50),
	})
	title.TextTruncate = Enum.TextTruncate.AtEnd
	Ui.textStroke(title, 3)
	local subtitle = Ui.label(header, "Subtitle", { font = F.body, size = 17, color = C.muted, order = 3 })

	local body = Instance.new("ScrollingFrame")
	body.Name = "Body"
	body.Position = UDim2.fromOffset(0, HEADER + 6)
	body.Size = UDim2.new(1, 0, 1, -(HEADER + 6 + FOOTER))
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.CanvasSize = UDim2.new()
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ScrollingDirection = Enum.ScrollingDirection.Y
	body.ScrollBarThickness = 6
	body.ScrollBarImageColor3 = C.line
	body.Parent = card

	local footer = Ui.frame(card, "Footer", UDim2.new(1, 0, 0, FOOTER - 6), UDim2.fromScale(0, 1), Vector2.new(0, 1))
	local status = Ui.label(footer, "Status", {
		font = F.body,
		size = 16,
		color = C.muted,
		wrap = true,
		frameSize = UDim2.new(1, -250, 1, 0),
	})
	local continue = Ui.button(footer, "Continue", "CONTINUE", UDim2.fromOffset(250, 64), {
		fill = C.board,
		deep = C.boardDeep,
		textSize = 21,
		icon = "play",
	})
	local continueLabel = Ui.buttonLabel(continue)
	continue.AnchorPoint = Vector2.new(1, 1)
	continue.Position = UDim2.fromScale(1, 1)

	-- The ending's title alone, shown while its scene plays.
	local strip = Ui.panel(root, "EndingStrip", UDim2.fromOffset(560, 0), UDim2.new(0.5, 0, 0, 14), Vector2.new(0.5, 0))
	strip.AutomaticSize = Enum.AutomaticSize.Y
	strip.Visible = false
	Ui.padding(strip, 10, 16)
	Ui.list(strip, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center)
	Ui.label(strip, "Kicker", {
		text = "5:00 AM",
		font = F.title,
		size = 15,
		color = C.muted,
		xAlign = Enum.TextXAlignment.Center,
		order = 1,
	})
	local stripTitle = Ui.label(strip, "Title", {
		font = F.display,
		size = 36,
		color = C.lamp,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 44),
		order = 2,
	})
	Ui.textStroke(stripTitle, 3)

	local contentKey = ""
	local phase = ""
	local phaseStarted = 0
	local lastState: View.State? = nil
	-- The hold (identified by its end time) this player pressed Continue in, so the
	-- button stays pressed until the next one.
	local pressedFor: number? = nil
	local continueCallback: (() -> ())? = nil
	local designSize = Vector2.new(Theme.DesignWidth, Theme.DesignHeight)

	local function layout()
		local width = math.min(if phase == "failed" then 560 else 780, designSize.X - 32)
		if phase == "failed" then
			card.AnchorPoint = Vector2.new(0.5, 0)
			card.Position = UDim2.new(0.5, 0, 0, 64)
			card.Size = UDim2.fromOffset(width, math.min(320, designSize.Y - 80))
		elseif phase == "ending" then
			-- Low on the screen, so the top of the harbor stays in view behind it.
			card.AnchorPoint = Vector2.new(0.5, 1)
			card.Position = UDim2.new(0.5, 0, 1, -12)
			card.Size = UDim2.fromOffset(math.min(700, width), math.min(420, designSize.Y - 24))
		else
			card.AnchorPoint = Vector2.new(0.5, 0.5)
			card.Position = UDim2.fromScale(0.5, 0.5)
			card.Size = UDim2.fromOffset(width, math.min(520, designSize.Y - 24))
		end
	end

	local function rebuild(state: View.State, progress: View.Progress?)
		for _, child in body:GetChildren() do
			child:Destroy()
		end
		local content = Ui.frame(body, "Content", UDim2.new(1, -10, 0, 0))
		content.AutomaticSize = Enum.AutomaticSize.Y

		if state.phase == "intro" then
			kicker.Text = "GULL HARBOR · NIGHT FERRY TICKETS"
			title.Text = state.title or `Night {state.night}`
			title.TextColor3 = C.lamp
			subtitle.Text = `{state.date} · night {state.night} of {state.finalNight} · 11 PM to 5 AM`

			local rules = column(content, "Rules", UDim.new(0.5, -10), UDim.new(0, 0))
			caption(rules, "TONIGHT'S RULES", C.muted, 1)
			for i, rule in state.rules do
				Widgets.ruleRow(rules, i, rule, 17)
			end
			if state.manifest then
				paragraph(rules, "Tonight's manifest is on your desk (the MANIFEST tab).", {
					size = 15,
					color = C.muted,
					order = 50,
				})
			end
			if state.night == 1 then
				local tip = paragraph(
					rules,
					"<b>HOW TO WORK THE WINDOW</b>\nRead the ticket, look at the passenger, check the rules, "
						.. "then press BOARD or TURN AWAY. Look around with the right mouse button, a finger or "
						.. "the right stick; scroll, pinch or hold R2 to lean in.\n"
						.. "Each wrong call puts out a lantern. Lose all three and the tide comes in.",
					{ size = 15, color = C.text, order = 60, rich = true }
				)
				tip.BackgroundTransparency = 0.3
				tip.BackgroundColor3 = C.panelLight
				Ui.padding(tip, 8)
				Ui.corner(tip, UDim.new(0, 6))
			end

			local radio = column(content, "Radio", UDim.new(0.5, -10), UDim.new(0.5, 10))
			caption(radio, "ON THE RADIO · PIKE, AT THE LIGHTHOUSE", C.radio, 1)
			paragraph(radio, state.text or "", { size = 17, order = 2 })
		elseif state.phase == "summary" then
			local pages = #state.ledger
			kicker.Text = "END OF SHIFT · 5:00 AM"
			title.Text = state.title or "Shift over"
			title.TextColor3 = C.lamp
			subtitle.Text =
				`Lanterns still lit: {state.lanterns} of {state.maxLanterns} · Ledger pages found: {pages} of {state.finalNight}`
			Ui.list(content, Enum.FillDirection.Vertical, 6)
			local rows: { View.SummaryRow } = state.summary or {}
			for i, row in rows do
				summaryRow(content, i, row)
			end
		elseif state.phase == "failed" then
			kicker.Text = ""
			title.Text = state.title or "The Tide Came In"
			title.TextColor3 = C.bad
			subtitle.Text = ""
			Ui.list(content, Enum.FillDirection.Vertical, 6)
			paragraph(content, state.text or "", { size = 17 })
		elseif state.phase == "ending" then
			local ending = state.ending
			kicker.Text = "THE MORNING AFTER · 5:00 AM"
			title.Text = if ending then ending.title else ""
			title.TextColor3 = C.lamp
			subtitle.Text = ""
			Ui.list(content, Enum.FillDirection.Vertical, 10)
			if ending then
				paragraph(content, ending.text, { size = 18, order = 1 })
				if ending.secretTitle and ending.secretText then
					local note = Ui.frame(content, "Ledger", UDim2.fromScale(1, 0))
					note.AutomaticSize = Enum.AutomaticSize.Y
					note.LayoutOrder = 2
					note.BackgroundTransparency = 0
					note.BackgroundColor3 = C.paper
					Ui.corner(note, UDim.new(0, 6))
					Ui.padding(note, 10, 12, 12, 12)
					Ui.list(note, Enum.FillDirection.Vertical, 4)
					caption(note, string.upper(ending.secretTitle), C.paperInk, 1)
					paragraph(note, ending.secretText, { font = F.ticket, size = 16, color = C.paperInk, order = 2 })
				end
			end
			if progress then
				local found = if #progress.found > 0 then " · " .. table.concat(progress.found, " · ") else ""
				paragraph(content, `Endings found: {#progress.found} of {progress.total}{found}`, {
					size = 15,
					color = C.muted,
					order = 3,
				})
			end
		end
		body.CanvasPosition = Vector2.zero
	end

	-- During the ending's first seconds, only the title strip shows.
	local function updateEndingReveal(state: View.State)
		local scene = state.phase == "ending" and os.clock() - phaseStarted < ENDING_SCENE_TIME
		strip.Visible = scene
		card.Visible = not scene
		if scene and state.ending then
			stripTitle.Text = state.ending.title
		end
	end

	local function updateFooter(state: View.State)
		local label = CONTINUE_TEXT[state.phase]
		local ready = state.ready
		continue.Visible = label ~= nil and ready ~= nil
		if label then
			if state.phase == "summary" and state.night >= state.finalNight then
				label = "SEE THE MORNING"
			end
			local pressed = pressedFor ~= nil and pressedFor == state.phaseEnds
			continueLabel.Text = if pressed then "WAITING..." else label
			continue.Interactable = not pressed
		end

		local parts: { string } = {}
		if ready and ready.total > 1 then
			table.insert(parts, `{ready.count} of {ready.total} ready`)
		end
		local timer = TIMER_TEXT[state.phase]
		if timer and state.phaseEnds then
			table.insert(parts, string.format(timer, Ui.secondsLeft(state.phaseEnds)))
		end
		status.Text = table.concat(parts, " · ")
	end

	-- Returns whether Continue was pressed (it can only be while it's on screen and enabled).
	local function press(): boolean
		local state = lastState
		if
			state
			and root.Visible
			and card.Visible
			and continue.Visible
			and continue.Interactable
			and continueCallback
		then
			pressedFor = state.phaseEnds
			continueCallback()
			updateFooter(state)
			return true
		end
		return false
	end
	continue.Activated:Connect(function()
		press()
	end)

	local overlay: Overlay = {
		root = root,
		render = function(state: View.State, progress: View.Progress?)
			lastState = state
			local visible = isOverlayPhase(state.phase)
			root.Visible = visible
			if not visible then
				phase = state.phase
				contentKey = ""
				strip.Visible = false
				return
			end
			if state.phase ~= phase then
				phase = state.phase
				phaseStarted = os.clock()
				layout()
			end
			local key = table.concat({
				state.phase,
				tostring(state.night),
				state.title or "",
				state.text or "",
				if state.ending then state.ending.id else "",
				tostring(#(state.summary or {})),
				tostring(if progress then #progress.found else -1),
			}, "|")
			if key ~= contentKey then
				contentKey = key
				rebuild(state, progress)
			end
			updateFooter(state)
			updateEndingReveal(state)
		end,
		tick = function(state: View.State)
			if root.Visible then
				updateFooter(state)
				updateEndingReveal(state)
			end
		end,
		onContinue = function(callback: () -> ())
			continueCallback = callback
		end,
		pressContinue = press,
		resize = function(size: Vector2)
			designSize = size
			layout()
		end,
	}
	return overlay
end

return Overlay
