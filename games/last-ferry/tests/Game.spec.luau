--!nonstrict
--[[
	End to end: the real server and client scripts running together in the
	headless simulator (tests/sim/Roblox.luau).

	The bot plays like a person: it reads the ticket, the rules card, the
	manifest and the speech line off the HUD, looks at the passenger's model for
	breath, dripping water and a shadow, and presses the real buttons. If it can
	finish clean, everything a player needs reaches the screen and every button
	does what it says.
]]

local roblox = require("@lune/roblox")

local Sim = require("./sim/Roblox")
local T = require("./TestLib")

T.suite("Game (headless)")

local ROOT = "."

type Bot = {
	sim: any,
	player: any,
	name: string,
	policy: { [string]: any },
	seenTicket: { [string]: number },
	decided: { [string]: boolean },
	cardSince: number,
	lastCard: string,
	checkedCard: string?, -- the last card whose text was checked for fit
	ending: string?,
	endingText: string,
	lanternsLost: number,
	lit: number,
	alerts: { string },
	pagesTaken: number,
	nights: { [number]: boolean },
	sawFailed: boolean,
	sawRetry: boolean,
	sawLedger: boolean?,
	atPage: boolean?, -- stopped at a passenger with a torn page (policy stopAtPage)
	nextTextCheck: number?, -- when to check the text on screen next (policy checkText)
	calls: number,
	clockIns: number,
}

local function hud(bot: Bot)
	local gui = bot.player.PlayerGui:FindFirstChild("LastFerryHud")
	return gui and gui:FindFirstChild("Root")
end

-- The shift's status (Ui/TopBar): up in Roblox's top bar row, or at the top of the HUD
-- where there's no row for it.
local function topRow(player)
	return player.PlayerGui.LastFerryTopBar:FindFirstChild("Row") or player.PlayerGui.LastFerryHud.Root.Play.Row
end

-- Everything the ticket, the rules card, the manifest and the speech bubble say.
local function readDesk(root)
	local desk = root.Play.Desk
	local body = desk.TicketHolder.Ticket.Body
	local stampFrame = body.Stamp
	local word = stampFrame:FindFirstChild("Word")
	local stamp = if word and word.Text == "GULL"
		then "gull"
		elseif word and word.Text == "STAMP" then "none"
		elseif stampFrame:FindFirstChild("Crown") then "anchor"
		else "?"

	local rules = {}
	for _, row in root.Play.Side.Scroller.Rules:GetChildren() do
		if row.Name == "Rule" then
			rules[row.LayoutOrder] = row.Text.Text
		end
	end
	local ordered = {}
	for order = 1, 99 do
		if rules[order] then
			table.insert(ordered, rules[order])
		end
	end
	local manifest = {}
	for _, label in root.Play.Side.Scroller.Manifest:GetChildren() do
		if label.Name == "Name" then
			table.insert(manifest, label.Text)
		end
	end
	return {
		name = body.Passenger.Text,
		destination = body.Destination.Text,
		date = body.Date.Text,
		stamp = stamp,
		rules = ordered,
		tonight = string.match(ordered[1] or "", "date: (.-)%.$"),
		manifest = manifest,
		speech = "", -- read from the passenger's chat bubble (see tick)
		night = tonumber(
			string.match(topRow(root.Parent.Parent.Parent).TopBar.Left.NightPill.Night.Text, "NIGHT (%d+)")
		),
	}
end

-- The passenger's speech bubble on this player's screen (Ui/Speech): the bubble and its
-- tail, moved as one.
local function speechBubble(player)
	local gui = player.PlayerGui:FindFirstChild("LastFerrySpeech")
	return gui and gui:FindFirstChild("Stack")
end
-- What the bubble over this passenger says on the bot's screen, or "" if there's none.
local function heard(bot: Bot, model): string
	local bubble = speechBubble(bot.player)
	if bubble and bot.sim:shown(bubble) and bubble:GetAttribute("Speaker") == model.Name then
		return bubble.Bubble.Line.Text
	end
	return ""
end

local CLOCK_SPOT = roblox.Vector3.new(2.7, 0, 11) -- on the pier, in front of the time clock

local function clockPrompt(sim)
	return sim.workspace.World.Booth.TimeClock.PromptPoint.ClockIn
end

-- Walks up to the time clock and holds its prompt, if it's up.
local function clockIn(bot: Bot): boolean
	local sim = bot.sim
	local prompt = clockPrompt(sim)
	if not prompt.Enabled or bot.player.Character == nil or bot.player:GetAttribute("OnShift") then
		return false
	end
	sim:moveCharacter(bot.player, CLOCK_SPOT, roblox.Vector3.new(2.7, 0, 8))
	sim:triggerPrompt(bot.player, prompt)
	bot.clockIns += 1
	return true
end

-- Where a character's feet are.
local function feet(player)
	local root = player.Character.HumanoidRootPart
	return root.Position - roblox.Vector3.new(0, 2.35, 0)
end

local function inBooth(player): boolean
	local at = feet(player)
	return math.abs(at.X) < 4.8 and at.Z > 1.75 and at.Z < 7.8 and math.abs(at.Y - 0.2) < 0.01
end

local function onPier(player): boolean
	local at = feet(player)
	return at.Z > 8.5 and at.Z < 46 and math.abs(at.X) < 14 and math.abs(at.Y) < 0.01
end

-- What you can see of the passenger standing at the window.
local function lookAtPassenger(sim)
	local folder = sim.workspace.World.Passengers
	for _, model in folder:GetChildren() do
		local rootPart = model:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local position = rootPart.Position
			if math.abs(position.X) < 0.5 and math.abs(position.Z + 3.2) < 0.5 then
				local breath = model:FindFirstChild("Breath", true)
				local drips = model:FindFirstChild("Drips", true)
				return {
					breath = breath ~= nil and breath.Enabled,
					wet = drips ~= nil and drips.Enabled,
					shadow = model.Torso.CastShadow,
					model = model,
				}
			end
		end
	end
	return nil
end

-- Where each clerk stands in the booth (feet), front first (WorldService's stands).
local STANDS = {
	front = roblox.Vector3.new(0, 0.2, 2.7),
	left = roblox.Vector3.new(-2.8, 0.2, 3),
	right = roblox.Vector3.new(2.8, 0.2, 3),
	backLeft = roblox.Vector3.new(-2, 0.2, 5.6),
	backRight = roblox.Vector3.new(2, 0.2, 5.6),
	back = roblox.Vector3.new(0, 0.2, 6.6),
}
local STAND_ORDER = { "front", "left", "right", "backLeft", "backRight", "back" }
-- The face of a passenger at the window, which every stand's view is aimed at.
local WINDOW_TARGET = roblox.Vector3.new(0, 4.4, -4)

-- Puts a clerk at a stand facing the window, as the server does when it gives them that
-- stand, and turns their view to the passenger as it is at the start of a night.
local function standAt(sim, player, stand)
	player:SetAttribute("Stand", stand)
	sim:moveCharacter(player, stand, roblox.Vector3.new(stand.X, stand.Y, -1))
	sim:executeClient(player, [[require("./Controllers/CameraController").faceWindow()]])
	sim:run(0.3)
end

-- Where a GUI object is on screen, in GUI pixels.
local function box(object)
	local at, size = object.AbsolutePosition, object.AbsoluteSize
	return { left = at.X, top = at.Y, right = at.X + size.X, bottom = at.Y + size.Y }
end
local function overlap(a, b): boolean
	return a.left < b.right and b.left < a.right and a.top < b.bottom and b.top < a.bottom
end
local function describe(r): string
	return string.format("(%d, %d)-(%d, %d)", r.left, r.top, r.right, r.bottom)
end

-- Text measured letter by letter, as the simulator measures it, can be a few percent off
-- Roblox's kerned text: text in a box that can't grow keeps that much room to spare.
local KERNING = 1.04

-- The nearest box around an object that doesn't grow along `axis` ("X" across, "Y" down)
-- to fit what's in it: the one whose size bounds it that way.
local function boundsAlong(object, axis: string)
	local A = roblox.Enum.AutomaticSize
	local outer = object.Parent
	while outer:IsA("GuiObject") do
		local automatic = outer.AutomaticSize
		if not (automatic == A.XY or automatic == (if axis == "X" then A.X else A.Y)) then
			break
		end
		outer = outer.Parent
	end
	return outer
end

-- Which way a label that grows across to fit its text grows, within `around` (the nearest
-- box that doesn't grow across): by how a list there lines up what's in it, or else by the
-- anchor of whatever in it holds the label (the label itself, if nothing between grows).
-- "right", "left" or "both".
local function growthSide(object, around): string
	local placed = object
	while placed.Parent ~= around do
		placed = placed.Parent
	end
	local list = around:FindFirstChildOfClass("UIListLayout")
	local x = placed.AnchorPoint.X
	if list then
		local h = list.HorizontalAlignment
		x = if h == roblox.Enum.HorizontalAlignment.Left
			then 0
			elseif h == roblox.Enum.HorizontalAlignment.Right then 1
			else 0.5
	end
	return if x == 0 then "right" elseif x == 1 then "left" else "both"
end

-- One label fits its box (see checkTextFits).
local function checkLabelFits(sim, object, label: string)
	local where = `{label}: {object:GetFullName()} ("{object.Text}")`
	local bounds, width, height = sim:textRoom(object)
	if object.TextTruncate ~= roblox.Enum.TextTruncate.None then
		-- Cut short with "…" when it's too long, by design, but no taller than its box, and
		-- every line drawn if it wraps.
		T.expect(
			bounds.Y <= height + 0.5 and (not object.TextWrapped or bounds.X <= width + 0.5),
			`{where} needs {bounds.X} x {bounds.Y}, and has {width} x {height}`
		)
		return
	end
	local automatic = object.AutomaticSize
	local growsX = automatic == roblox.Enum.AutomaticSize.X or automatic == roblox.Enum.AutomaticSize.XY
	local growsY = automatic == roblox.Enum.AutomaticSize.Y or automatic == roblox.Enum.AutomaticSize.XY
	local needed = if object.TextWrapped then bounds.X else bounds.X * KERNING
	T.expect(
		(growsX or needed <= width + 0.5) and (growsY or bounds.Y <= height + 0.5),
		`{where} needs {needed} x {bounds.Y}, and has {width} x {height}`
	)
	if not (growsX or growsY) then
		return
	end
	-- Inside the nearest box that doesn't grow, across and down: a list that scrolls makes
	-- room the way it scrolls, so not that way.
	local inner = box(object)
	local function scrolls(frame, axis: string): boolean
		if not frame:IsA("ScrollingFrame") then
			return false
		end
		local direction = frame.ScrollingDirection
		return direction == roblox.Enum.ScrollingDirection.XY
			or direction
				== (if axis == "X" then roblox.Enum.ScrollingDirection.X else roblox.Enum.ScrollingDirection.Y)
	end
	local acrossIn, downIn = boundsAlong(object, "X"), boundsAlong(object, "Y")
	if acrossIn:IsA("GuiObject") and not scrolls(acrossIn, "X") then
		local around = box(acrossIn)
		T.expect(
			inner.left >= around.left - 0.5 and inner.right <= around.right + 0.5,
			`{where} {describe(inner)} runs out of {acrossIn:GetFullName()} {describe(around)} sideways`
		)
		if growsX and not object.TextWrapped then
			local towards = growthSide(object, acrossIn)
			local left, right = inner.left - around.left, around.right - inner.right
			local spare = if towards == "right"
				then right
				elseif towards == "left" then left
				else 2 * math.min(left, right)
			local wanted = (inner.right - inner.left) * (KERNING - 1)
			T.expect(
				spare >= wanted - 0.5,
				`{where} has {spare} px to spare towards the {towards} in {acrossIn:GetFullName()}, less than {wanted}`
			)
		end
	end
	if downIn:IsA("GuiObject") and not scrolls(downIn, "Y") then
		local around = box(downIn)
		T.expect(
			inner.top >= around.top - 0.5 and inner.bottom <= around.bottom + 0.5,
			`{where} {describe(inner)} runs out of {downIn:GetFullName()} {describe(around)} downwards`
		)
	end
end

-- Where a label's text can be: where it's drawn, or for text that wraps, its whole box (its
-- lines can fill it).
local function inkOf(sim, object)
	return if object.TextWrapped then box(object) else sim:textRect(object)
end

-- Every piece of text showing on this player's screen fits in its box, as the fonts measure
-- it, with room to spare for kerning: Roblox doesn't draw the lines of wrapped text that
-- don't fit, and text that doesn't wrap spills out. A label that grows to fit its text
-- (AutomaticSize) fits the other way, and inside the nearest box around it that doesn't
-- grow (sideways, for a list that scrolls up and down), with that room to spare on the side
-- it grows towards. Text meant to be cut short with "…" (TextTruncate) is checked for its
-- height, and for every line if it wraps. And no two labels side by side run into each
-- other (inkOf). Text drawn wholly see-through shows nothing to fit.
local function checkTextFits(sim, player, label: string)
	for _, gui in player.PlayerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui.Enabled then
			local byParent = {}
			for _, object in gui:GetDescendants() do
				if
					(object:IsA("TextLabel") or object:IsA("TextButton"))
					and object.Text ~= ""
					and object.TextTransparency < 1
					and sim:shown(object)
				then
					checkLabelFits(sim, object, label)
					local siblings = byParent[object.Parent] or {}
					byParent[object.Parent] = siblings
					table.insert(siblings, object)
				end
			end
			for _, siblings in byParent do
				for i = 1, #siblings - 1 do
					for j = i + 1, #siblings do
						local a, b = siblings[i], siblings[j]
						local inkA, inkB = inkOf(sim, a), inkOf(sim, b)
						T.expect(
							not (
									inkA.left < inkB.right - 0.5
									and inkB.left < inkA.right - 0.5
									and inkA.top < inkB.bottom - 0.5
									and inkB.top < inkA.bottom - 0.5
								),
							`{label}: {a:GetFullName()} ("{a.Text}") {describe(inkA)} runs into {b.Name} ("{b.Text}") {describe(
								inkB
							)}`
						)
					end
				end
			end
		end
	end
end

-- The player's Text Size setting draws the text meant for reading bigger, as big as it
-- asks: none of it is held back (Ui.holdTextSize is for text in a box that can't grow).
local function checkGrown(sim, objects: { any }, label: string)
	for _, object in objects do
		local drawn, asked = sim:drawnTextSize(object), sim:drawnTextSize(object, true)
		T.expect(
			drawn > object.TextSize and math.abs(drawn - asked) < 0.01,
			`{label}: {object:GetFullName()} ("{object.Text}") is drawn at {drawn}, not {asked}`
		)
	end
end

-- The text meant for reading in a card, a panel or a list: its captions, paragraphs, lines
-- and rules (not the badges and tags beside them).
local function readingText(parent): { any }
	local found = {}
	for _, object in parent:GetDescendants() do
		if
			object:IsA("TextLabel")
			and object.Text ~= ""
			and table.find({ "Caption", "Paragraph", "Line", "Text", "Name" }, object.Name)
		then
			table.insert(found, object)
		end
	end
	return found
end

-- The ending card, once its scene has played (the card shows after ENDING_SCENE_TIME, 7 s,
-- in Ui/Overlay): it's up, with its words, and they fit.
local function checkEndingCard(sim, player, label: string)
	local card = player.PlayerGui.LastFerryHud.Root.Overlay.Card
	sim:run(7.5)
	local words = 0
	for _, object in card.Body:GetDescendants() do
		if object:IsA("TextLabel") and object.Text ~= "" and sim:shown(object) then
			words += 1
		end
	end
	T.expect(sim:shown(card) and words > 0, `{label}: the card is up with its words ({words} shown)`)
	checkTextFits(sim, player, label)
end

-- On the first night the hint along the bottom is up, clear of the desk and of the rules
-- panel (or the ledger in its place).
local function checkHint(sim, player, label: string)
	local play = player.PlayerGui.LastFerryHud.Root.Play
	T.expect(sim:shown(play.Hint), `{label}: the first night's hint is up`)
	local hint = box(play.Hint)
	for _, piece in { play.Desk, play.Side, play.Ledger } do
		if sim:shown(piece) then
			local r = box(piece)
			T.expect(
				not overlap(hint, r),
				`{label}: the hint {describe(hint)} runs into the {piece.Name} {describe(r)}`
			)
		end
	end
end

-- The pieces of the shift HUD on a player's screen now, by their parent's name and their
-- own ("Play.Ledger", "Right.Ledger"): everything showing at its top level, the ticket's
-- page tab, and the status pills (or the alert) up in the top bar row.
local function hudPieces(sim, player)
	local pieces = {}
	local play = player.PlayerGui.LastFerryHud.Root.Play
	local candidates = play:GetChildren()
	table.insert(candidates, play.Desk.TicketHolder.PageTab)
	local row = topRow(player)
	for _, group in { row.TopBar.Left, row.TopBar.Right } do
		for _, pill in group:GetChildren() do
			table.insert(candidates, pill)
		end
	end
	table.insert(candidates, row.Alert)
	for _, piece in candidates do
		if piece:IsA("GuiObject") and sim:shown(piece) then
			local r = box(piece)
			if r.right > r.left and r.bottom > r.top then
				pieces[`{piece.Parent.Name}.{piece.Name}`] = r
			end
		end
	end
	return pieces
end

local function rightCall(bot: Bot, desk, tells): string
	local count = #desk.rules
	local ok = desk.date == desk.tonight and desk.destination == "GULL ISLAND"
	if count >= 4 then
		ok = ok and desk.stamp == "gull" and not tells.wet
	end
	if count >= 6 then
		ok = ok and table.find(desk.manifest, desk.name) ~= nil and tells.breath
	end
	if count >= 7 then
		ok = ok and tells.shadow
	end
	if count >= 8 then
		ok = ok and string.find(desk.speech, bot.name, 1, true) == nil
	end
	return if ok then "board" else "deny"
end

local function newBot(sim, player, policy): Bot
	return {
		sim = sim,
		player = player,
		name = player.DisplayName,
		policy = policy or {},
		seenTicket = {},
		decided = {},
		cardSince = 0,
		lastCard = "",
		ending = nil,
		endingText = "",
		lanternsLost = 0,
		lit = 3,
		alerts = {},
		pagesTaken = 0,
		nights = {},
		sawFailed = false,
		sawRetry = false,
		calls = 0,
		clockIns = 0,
	}
end

local function tick(bot: Bot)
	local sim = bot.sim
	local root = hud(bot)
	if root == nil then
		return
	end

	-- Policy checkText, naming the screen: each second, every word on it fits, and the
	-- manifest's do too (brought up and put away again) while there's one.
	if bot.policy.checkText and sim.now >= (bot.nextTextCheck or 0) then
		bot.nextTextCheck = sim.now + 1
		local label = `{bot.policy.checkText} at {math.floor(sim.now)}s`
		checkTextFits(sim, bot.player, label)
		local tabs = root.Play.Side.Tabs
		if sim:shown(tabs.MANIFEST) and tabs.MANIFEST.Interactable then
			sim:click(tabs.MANIFEST)
			checkTextFits(sim, bot.player, `{label}, the manifest`)
			if bot.policy.grown then
				checkGrown(sim, readingText(root.Play.Side.Scroller.Manifest), `{label}, the manifest`)
			end
			sim:click(tabs.RULES)
		end
	end

	-- On the pier between shifts: walk to the time clock and clock in.
	if root.Lobby.Visible then
		if bot.policy.clockIn ~= false then
			clockIn(bot)
		end
		return
	end

	-- Count lanterns going out from the top bar (they're relit each night).
	local lit = 0
	for _, lantern in topRow(bot.player).TopBar.Right.Lanterns:GetChildren() do
		if lantern:IsA("Frame") and lantern.Visible and lantern:GetAttribute("Lit") then
			lit += 1
		end
	end
	if lit < bot.lit then
		bot.lanternsLost += bot.lit - lit
	end
	bot.lit = lit

	local alert = topRow(bot.player).Alert
	if sim:shown(alert) then
		local line = `{alert.Caption.Text}: {alert.Paragraph.Text}`
		if bot.alerts[#bot.alerts] ~= line then
			table.insert(bot.alerts, line)
		end
	end

	local ledger = root.Play.Ledger
	if ledger.Visible then
		bot.sawLedger = true
		if bot.policy.checkText then
			checkTextFits(sim, bot.player, `{bot.policy.checkText}, the ledger open`)
		end
		sim:click(ledger.Close)
		return
	end

	local overlay = root.Overlay
	if overlay.Visible then
		local card = overlay.Card
		local kicker = card.Header.Kicker.Text
		local title = card.Header.Title.Text
		local key = kicker .. "|" .. title
		if key ~= bot.lastCard then
			bot.lastCard = key
			bot.cardSince = sim.now
			if title == "The Tide Came In" then
				bot.sawFailed = true
			end
		end
		if bot.checkedCard ~= key and sim.now - bot.cardSince >= 0.5 then
			-- Once it's settled, every word on it fits (on whatever screen this is), and with
			-- policy grown, the words meant for reading are as big as the Text Size asks.
			bot.checkedCard = key
			checkTextFits(sim, bot.player, `the card "{key}"`)
			if bot.policy.grown then
				checkGrown(sim, readingText(card.Body), `the card "{key}"`)
			end
		end
		local night = tonumber(string.match(title, "^Night (%d+)$"))
		if night then
			bot.nights[night] = true
			if bot.sawFailed then
				bot.sawRetry = true
			end
		end
		if string.find(kicker, "THE MORNING AFTER", 1, true) then
			local texts = {}
			for _, label in card.Body:GetDescendants() do
				if label:IsA("TextLabel") then
					table.insert(texts, label.Text)
				end
			end
			bot.endingText = table.concat(texts, "\n")
			if string.find(bot.endingText, "Endings found", 1, true) then
				bot.ending = title
			end
			return
		end
		local continue = card.Footer.Continue
		if bot.policy.pressContinue ~= false and sim:shown(continue) and continue.Interactable then
			if sim.now - bot.cardSince > 1 then
				if bot.policy.useKeys then
					sim:pressKey(roblox.Enum.KeyCode.Return)
				else
					sim:click(continue)
				end
			end
		end
		return
	end

	local desk = root.Play.Desk
	local board, deny = desk.Board, desk.Deny
	if not (sim:shown(desk.TicketHolder) and board.Interactable) then
		return
	end
	local view = readDesk(root)
	local ticketKey = `{view.night}|{view.name}`
	if bot.decided[ticketKey] then
		return
	end
	if bot.seenTicket[ticketKey] == nil then
		bot.seenTicket[ticketKey] = sim.now
	end
	if sim.now - bot.seenTicket[ticketKey] < 2 then
		return -- read it properly first
	end

	local tab = desk.TicketHolder.PageTab
	if bot.policy.stopAtPage and sim:shown(tab) then
		bot.atPage = true
		return
	end
	if bot.policy.takePages and sim:shown(tab) then
		if bot.policy.useKeys then
			sim:pressKey(roblox.Enum.KeyCode.P)
		else
			sim:click(tab)
		end
		bot.pagesTaken += 1
		return
	end
	if bot.policy.idle then
		return
	end

	local tells = lookAtPassenger(sim)
	assert(tells, `no passenger at the window for {view.name}`)
	view.speech = heard(bot, tells.model)
	assert(view.speech ~= "", `{view.name} said nothing`)
	local call = rightCall(bot, view, tells)
	if bot.policy.override then
		call = bot.policy.override(view, tells, call) or call
	end
	bot.decided[ticketKey] = true
	bot.calls += 1
	if bot.policy.useKeys then
		sim:pressKey(if call == "board" then roblox.Enum.KeyCode.B else roblox.Enum.KeyCode.T)
	else
		sim:click(if call == "board" then board else deny)
	end
end

local function boot(options): (any, any)
	local sim = Sim.new(options or { root = ROOT })
	sim:startServer()
	sim:run(1)
	return sim
end

local function clean(sim, label: string)
	for _, err in sim.errors do
		print(err)
	end
	T.equal(#sim.errors, 0, `{label}: script errors`)
	T.equal(#sim.deprecated, 0, `{label}: deprecated API used: {table.concat(sim.deprecated, ", ")}`)
	for _, warning in sim.warnings do
		print("warning:", warning)
	end
	T.equal(#sim.warnings, 0, `{label}: warnings`)
end

-- Puts a hat on a player's avatar, the way the platform loads one: an Accessory of type
-- Hat on the head's HatAttachment.
local HAT = [[
	local player = game:GetService("Players"):GetPlayers()[1]
	local accessory = Instance.new("Accessory")
	accessory.Name = "TopHat"
	accessory.AccessoryType = Enum.AccessoryType.Hat
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1.2, 1)
	handle.Transparency = 0.1
	handle.Parent = accessory
	local attachment = Instance.new("Attachment")
	attachment.Name = "HatAttachment"
	attachment.Position = Vector3.new(0, -0.6, 0)
	attachment.Parent = handle
	-- A hat with a logo and a sparkle on it.
	local logo = Instance.new("Decal")
	logo.Name = "Logo"
	logo.Parent = handle
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "Sparkle"
	sparkle.Parent = handle
	player.Character.Humanoid:AddAccessory(accessory)
	return handle
]]

-- The built-in sounds every Roblox client has on every device: the ones Roblox's own
-- characters make (RbxCharacterSounds). Other files in rbxasset://sounds/ may not ship
-- on phones and consoles.
local SHIPPED_SOUNDS = {
	["rbxasset://sounds/action_footsteps_plastic.mp3"] = true,
	["rbxasset://sounds/action_falling.ogg"] = true,
	["rbxasset://sounds/action_get_up.mp3"] = true,
	["rbxasset://sounds/action_jump.mp3"] = true,
	["rbxasset://sounds/action_jump_land.mp3"] = true,
	["rbxasset://sounds/action_swim.mp3"] = true,
	["rbxasset://sounds/impact_water.mp3"] = true,
	["rbxasset://sounds/uuhhh.mp3"] = true,
}

-- The sounds played so far, by name, and where from ("server" or "client").
local function soundsPlayed(sim)
	local names = {}
	for _, entry in sim.sounds do
		local side = if entry.context == "server" then "server" else "client"
		names[`{side}:{entry.name}`] = true
		assert(
			SHIPPED_SOUNDS[entry.id],
			`{entry.name} plays {entry.id}: every sound must be one Roblox's characters make, so every device has it`
		)
	end
	return names
end

T.test("a clerk playing from the HUD finishes five nights clean", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local hat = sim:execute(HAT)
	local bot = newBot(sim, alice)
	local hatHidden = false
	local finished = sim:runUntil(
		function()
			return bot.ending ~= nil
		end,
		3600,
		1 / 20,
		function()
			tick(bot)
			if alice:GetAttribute("OnShift") and alice.Character:FindFirstChild("ClerkCap") then
				hatHidden = hat.Transparency == 1 and hat.Logo.Transparency == 1 and not hat.Sparkle.Enabled
			end
		end
	)
	T.expect(hatHidden, "her own hat goes under the clerk's cap for the shift, logo, sparkle and all")
	sim:run(3) -- the save finishes just after the ending card appears
	clean(sim, "clean run")
	checkEndingCard(sim, alice, "the ending card")
	T.expect(finished, `the run never ended (stuck at {math.floor(sim.now)}s on "{bot.lastCard}")`)
	T.equal(bot.ending, "The Petrel Sails")
	T.equal(bot.lanternsLost, 0, "no lantern lost")
	for night = 1, 5 do
		T.expect(bot.nights[night], `saw the night {night} intro`)
	end
	T.expect(string.find(bot.endingText, "Endings found: 1 of 4 · The Petrel Sails", 1, true) ~= nil, bot.endingText)
	local saved = sim.stores.LastFerryProgress_v1.u_101
	T.expect(saved and saved.endings.CLEAN_SHIFT and saved.runs == 1, "progress saved to the DataStore")
	T.equal(alice.leaderstats.Endings.Value, 1, "the player list shows one ending found")
	T.equal(alice.leaderstats.Shifts.Value, 1, "and one shift worked")
	local sounds = soundsPlayed(sim)
	T.expect(sounds["client:Footsteps"], "passengers' footsteps while they walk")
	T.expect(sounds["client:LastFerryStamp"], "the stamp thuds onto the ticket")
	T.expect(sounds["client:LastFerryClick"], "buttons click")
	T.expect(sounds["server:Thud"], "the booth door thunks shut")
	T.expect(sounds["server:Splash"], "the drowned splash as they sink")
	print(
		`    (a clean run took {math.floor(sim.now / 60)} min {math.floor(sim.now % 60)} s of game time, {bot.calls} calls)`
	)

	-- Then everyone clocks out onto the pier, ready for another shift.
	local root = hud(bot)
	local back = sim:runUntil(function()
		return root.Lobby.Visible
	end, 90)
	sim:run(1)
	clean(sim, "clock out")
	T.expect(back, "back to the lobby after the ending")
	T.expect(onPier(alice), `Alice is back on the pier (feet at {feet(alice)})`)
	T.equal(alice:GetAttribute("OnShift"), false, "off shift")
	T.equal(alice:GetAttribute("Stand"), nil, "with no stand")
	T.expect(alice.Character:FindFirstChild("ClerkCap") == nil, "the cap comes off")
	T.equal(alice.Character.Humanoid.WalkSpeed, 16, "walking at Roblox's usual pace again")
	T.equal(hat.Transparency, 0.1, "her own hat comes back as it was")
	T.equal(hat.Logo.Transparency, 0, "logo and all")
	T.expect(hat.Sparkle.Enabled, "sparkling again")
	T.expect(clockPrompt(sim).Enabled, "the time clock is ready for the next shift")
	T.equal(sim.workspace.World.Booth.Door.CanCollide, false, "the door is open")
	T.equal(root.Lobby.Found.Text, "Endings found: 1 of 4")
	T.equal(alice.CameraMode, roblox.Enum.CameraMode.Classic, "Roblox's third-person camera on the pier")
	T.equal(alice.DevEnableMouseLock, true, "Shift Lock is back, as the place allows it")
	T.expect(sim:coreGuiEnabled(alice, "PlayerList"), "and so is Roblox's player list")
end)

T.test("players arrive on the pier as their avatars and clock in together", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bob = sim:addPlayer("Bob", 202)
	sim:run(2)
	clean(sim, "arrival")
	for _, player in { alice, bob } do
		local root = player.PlayerGui.LastFerryHud.Root
		T.expect(player.Character ~= nil, `{player.Name} has an avatar`)
		T.expect(onPier(player), `{player.Name} spawned on the pier (feet at {feet(player)})`)
		T.expect(sim:shown(root.Lobby), `{player.Name} sees the lobby banner`)
		T.expect(not sim:shown(root.Overlay), `{player.Name} sees no card on the pier`)
		T.expect(not sim:shown(root.Play), `{player.Name} sees no shift HUD on the pier`)
		T.equal(player.CameraMode, roblox.Enum.CameraMode.Classic, `{player.Name}: third person on the pier`)
		T.expect(not root.Parent.FreeCursor.Visible, "the mouse isn't freed on the pier")
	end
	T.expect(string.find(alice.PlayerGui.LastFerryHud.Root.Lobby.How.Text, "<b>E</b>", 1, true) ~= nil, "says hold E")
	T.expect(clockPrompt(sim).Enabled, "the time clock is ready")
	T.equal(clockPrompt(sim).ActionText, "Clock in")
	T.equal(sim.workspace.World.Booth.Door.CanCollide, false, "the booth door is open")

	-- Too far away, the prompt can't be reached.
	T.expect(not pcall(sim.triggerPrompt, sim, alice, clockPrompt(sim)), "the prompt needs you at the clock")
	local bot = newBot(sim, alice, { idle = true, pressContinue = false })
	T.expect(clockIn(bot), "Alice clocks in")
	sim:run(1.5)
	clean(sim, "clock in")
	local standsUsed = {}
	for _, player in { alice, bob } do
		local root = player.PlayerGui.LastFerryHud.Root
		T.expect(inBooth(player), `{player.Name} is in the booth (feet at {feet(player)})`)
		T.equal(player:GetAttribute("OnShift"), true, `{player.Name} is on shift`)
		T.expect(player.Character:FindFirstChild("ClerkCap") ~= nil, `{player.Name} wears the clerk's cap`)
		T.equal(player.Character.Humanoid.WalkSpeed, 10, "walking at booth pace")
		T.equal(player.CameraMode, roblox.Enum.CameraMode.LockFirstPerson, `{player.Name}: first person on shift`)
		T.equal(
			player.DevEnableMouseLock,
			false,
			`{player.Name}: no Shift Lock on shift (it would undo the eye height)`
		)
		T.expect(root.Parent.FreeCursor.Visible and root.Parent.FreeCursor.Modal, "the HUD frees the mouse")
		T.equal(root.Overlay.Card.Header.Title.Text, "Night 1", `{player.Name} sees the night 1 card`)
		local key = tostring(feet(player))
		T.expect(not standsUsed[key], "each clerk has their own stand")
		standsUsed[key] = true
	end
	T.equal(sim.workspace.World.Booth.Door.CanCollide, true, "the door shuts behind them")
	T.expect(not clockPrompt(sim).Enabled, "no clocking in again mid-shift")
	for _, player in { alice, bob } do
		T.expect(
			not sim:coreGuiEnabled(player, "PlayerList"),
			`{player.Name}: Roblox's player list is put away for the shift, clear of the rules`
		)
	end
	-- A clerk who somehow ends up out on the pier mid-shift is put back at their stand.
	local stand = feet(bob)
	sim:moveCharacter(bob, roblox.Vector3.new(0, 0, 20))
	sim:run(1.5)
	T.expect(inBooth(bob), `Bob is back in the booth (feet at {feet(bob)})`)
	T.expect((feet(bob) - stand).Magnitude < 1e-3, "at his own stand")
	T.expect(sim.workspace.World.Booth.BoothSpawn.Enabled, "respawns land in the booth")
	T.expect(not sim.workspace.World.Pier.PierSpawn.Enabled, "not on the pier")
	-- The booth holds them: walls, glass, roof and the counter are solid.
	for _, name in { "Wall", "Glass", "Roof", "Counter", "CounterFront", "CounterGuard", "Floor" } do
		for _, part in sim.workspace.World.Booth:GetChildren() do
			if part.Name == name then
				T.expect(part.CanCollide, `{name} is solid`)
			end
		end
	end
end)

T.test("in co-op, a clerk in the way of your view of the window turns see-through for you", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bob = sim:addPlayer("Bob", 202)
	sim:run(1)
	T.expect(clockIn(newBot(sim, alice, { idle = true })), "Alice clocks in")
	sim:run(1.5)
	local window = roblox.Vector3.new(0, 0.2, -3.2)
	local function see(player): number
		return player.Character.Head.LocalTransparencyModifier
	end
	-- Alice at the back, Bob right in front of her at the counter.
	sim:moveCharacter(alice, roblox.Vector3.new(-2, 0.2, 5.6), window)
	sim:moveCharacter(bob, roblox.Vector3.new(0, 0.2, 2.7), window)
	sim:run(0.5)
	T.equal(see(bob), 0.75, "Bob, in Alice's way, is see-through")
	T.equal(bob.Character.ClerkCap.Top.LocalTransparencyModifier, 0.75, "cap and all")
	T.equal(see(alice), 0, "Alice, behind Bob, isn't in his way")
	-- Bob steps aside.
	sim:moveCharacter(bob, roblox.Vector3.new(3.5, 0.2, 3), window)
	sim:run(0.5)
	T.equal(see(bob), 0, "out of the way, Bob is solid again")
	clean(sim, "co-op view")
end)

T.test("if the shift hits a bug, everyone is back on the pier and the harbor is reset", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	sim:run(1)
	-- A night that floods the booth and then breaks.
	sim:execute([[
		local Director = require("./Shift/Director")
		local WorldService = require("./Services/WorldService")
		Director.playRun = function()
			WorldService.setFlood(true)
			task.wait(5)
			error("a bug in the shift")
		end
	]])
	T.expect(clockIn(newBot(sim, alice, { idle = true })), "Alice clocks in")
	sim:run(3)
	T.expect(sim.workspace.World.Flood.Slosh.IsPlaying, "the flood is sloshing round the booth")
	sim:run(6)
	T.expect(onPier(alice), `Alice is back on the pier (feet at {feet(alice)})`)
	T.expect(not sim.workspace.World.Flood.Slosh.IsPlaying, "the slosh stops")
	T.equal(sim.workspace.World.Flood.Transparency, 1, "the flood drains")
	T.expect(clockPrompt(sim).Enabled, "and the time clock is ready again")
	-- The error is reported, not hidden.
	T.equal(#sim.warnings, 1, "one warning")
	T.expect(string.find(sim.warnings[1], "a bug in the shift", 1, true) ~= nil, sim.warnings[1])
	table.clear(sim.warnings)
	clean(sim, "error path")
end)

T.test("a clerk who respawns mid-shift looks out of the window again", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	sim:run(1)
	T.expect(clockIn(newBot(sim, alice, { idle = true })), "Alice clocks in")
	sim:run(1.5)
	local camera = sim.workspace.CurrentCamera
	local outward = camera.CFrame.LookVector
	-- She turns round to face the back wall, then resets her character.
	camera.CFrame = roblox.CFrame.new(camera.CFrame.Position) * roblox.CFrame.Angles(0, math.pi, 0)
	sim:execute([[game:GetService("Players"):GetPlayers()[1]:LoadCharacterAsync()]])
	sim:run(1)
	T.expect(camera.CFrame.LookVector:Dot(outward) > 0.99, `looking out of the window ({camera.CFrame.LookVector})`)
	T.expect(inBooth(alice), "back at the counter")
	clean(sim, "respawn")
end)

T.test("from every stand, the booth view starts aimed at the passenger's face", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	sim.cameraFollows = alice
	sim:run(1)
	T.expect(clockIn(newBot(sim, alice, { idle = true })), "Alice clocks in")
	sim:run(1.5)
	local camera = sim.workspace.CurrentCamera
	for _, name in STAND_ORDER do
		standAt(sim, alice, STANDS[name])
		local look = camera.CFrame.LookVector
		local toTarget = WINDOW_TARGET - camera.CFrame.Position
		local miss = (toTarget - look * toTarget:Dot(look)).Magnitude
		T.expect(miss < 0.02, `{name} stand: the view passes {miss} studs from the passenger's face`)
		local eye = camera.CFrame.Position.Y + look.Y * 0.5
		T.expect(math.abs(eye - 5.1) < 0.02, `{name} stand: the eye is at the booth's eye height ({eye})`)
	end
	clean(sim, "aim")
end)

T.test("a respawned clerk's view is aimed from their stand, even while they're still on the spawn pad", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	sim.cameraFollows = alice
	sim:run(1)
	T.expect(clockIn(newBot(sim, alice, { idle = true })), "Alice clocks in")
	sim:run(1.5)
	T.equal(alice:GetAttribute("Stand"), STANDS.front, "the server told her client which stand is hers")
	-- Her stand is the left one; her new character appears on the booth's spawn pad, and
	-- her camera turns to the window before the server moves her to the stand.
	alice:SetAttribute("Stand", STANDS.left)
	sim:moveCharacter(alice, roblox.Vector3.new(3.3, 0.2, 7.1))
	sim:executeClient(alice, [[require("./Controllers/CameraController").faceWindow()]])
	sim:step(1 / 30)
	local camera = sim.workspace.CurrentCamera
	local eye = roblox.Vector3.new(STANDS.left.X, 5.1, STANDS.left.Z)
	local want = (WINDOW_TARGET - eye).Unit
	T.expect(
		camera.CFrame.LookVector:Dot(want) > 0.9999,
		`looking at the passenger from her stand, not from the pad ({camera.CFrame.LookVector}, want {want})`
	)
	clean(sim, "aim from the stand")
end)

T.test("a clerk who respawns while the view is on the flood keeps watching it", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	sim:run(1)
	T.expect(clockIn(newBot(sim, alice, { idle = true })), "Alice clocks in")
	sim:run(1.5)
	local camera = sim.workspace.CurrentCamera
	-- The tide comes in and the view turns to look down into the booth, as it does on a
	-- failed night; then her character resets.
	sim:executeClient(alice, [[require("./Controllers/CameraController").lookTo(0, -26)]])
	sim:run(2)
	local watching = camera.CFrame
	sim:execute([[game:GetService("Players"):GetPlayers()[1]:LoadCharacterAsync()]])
	sim:run(1)
	T.equal(camera.CameraType, roblox.Enum.CameraType.Scriptable, "still the flood's view")
	T.expect(
		camera.CFrame.LookVector:Dot(watching.LookVector) > 0.999,
		`still looking where it was ({camera.CFrame.LookVector})`
	)
	clean(sim, "respawn in a cinematic")
end)

T.test("gamepad A boards at the window and jumps the rest of the time", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	-- Roblox's own jump binding (ControlModule, Medium priority).
	local jumps = { count = 0 }
	sim:runAsClient(alice, function(env)
		env.game:GetService("ContextActionService"):BindActionAtPriority("jumpAction", function(_, state)
			if state == env.Enum.UserInputState.Begin then
				jumps.count += 1
			end
			return env.Enum.ContextActionResult.Sink
		end, false, env.Enum.ContextActionPriority.Medium.Value, env.Enum.KeyCode.ButtonA)
	end)
	sim:run(1)
	sim:pressKey(roblox.Enum.KeyCode.ButtonA, alice)
	T.equal(jumps.count, 1, "on the pier, A jumps")

	local bot = newBot(sim, alice, { idle = true })
	local atWindow = sim:runUntil(
		function()
			local root = hud(bot)
			return root.Play.Desk.Board.Interactable and sim:shown(root.Play.Desk.TicketHolder)
		end,
		300,
		1 / 20,
		function()
			tick(bot)
		end
	)
	T.expect(atWindow, "a passenger reached the window")
	local before = jumps.count
	sim:pressKey(roblox.Enum.KeyCode.ButtonA, alice)
	sim:run(0.5)
	T.equal(jumps.count, before, "at the window, A boards instead of jumping")
	T.expect(not hud(bot).Play.Desk.Board.Interactable, "the call was made")
	clean(sim, "gamepad")
end)

T.test("passengers are classic Robloxians who move like Roblox characters", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, { idle = true })
	local model
	sim:runUntil(
		function()
			for _, candidate in sim.workspace.World.Passengers:GetChildren() do
				local root = candidate:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.Z + 3.2) < 0.5 then
					model = candidate
					return true
				end
			end
			return false
		end,
		300,
		1 / 20,
		function()
			tick(bot)
		end
	)
	clean(sim, "crowd")
	T.expect(model ~= nil, "a passenger reached the window")
	-- Built like Roblox's own R6 dummy, with the built-in smile and no name tag.
	for _, name in { "HumanoidRootPart", "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" } do
		T.expect(model:FindFirstChild(name) ~= nil, `has a {name}`)
	end
	T.equal(model.Head.face.Texture, "rbxasset://textures/face.png", "the classic face")
	T.equal(model.Head.Mesh.MeshType, roblox.Enum.MeshType.Head, "the classic head")
	T.equal(model.Humanoid.DisplayDistanceType, roblox.Enum.HumanoidDisplayDistanceType.None, "no name tag")
	for _, name in { "Neck", "Left Shoulder", "Right Shoulder", "Left Hip", "Right Hip" } do
		T.expect(model.Torso:FindFirstChild(name) ~= nil, `joint {name}`)
	end
	-- The client animates them: standing, they sway and look about.
	local neck = model.Torso.Neck
	local before = neck.Transform
	sim:run(1.5)
	T.expect(neck.Transform ~= before, "the head turns while they wait")
	T.expect(model.Torso["Right Shoulder"].Transform ~= roblox.CFrame.identity, "the arms sway")
end)

T.test("passengers walk smoothly on every screen, and the booth door swings on its hinge", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	sim:run(1)
	local door = sim.workspace.World.Booth.Door
	local hinge = door:GetPivot().Position
	local bot = newBot(sim, alice, { idle = true })
	T.expect(clockIn(bot), "Alice clocks in")
	local offHinge = 0
	local pastShut = 0 -- how far it swings the wrong way, into the booth
	sim:run(0.8, 1 / 30, function()
		offHinge = math.max(offHinge, (door:GetPivot().Position - hinge).Magnitude)
		pastShut = math.max(pastShut, -door:GetPivot().LookVector.X)
	end)
	T.expect(offHinge < 1e-3, `the door turns on its hinge as it shuts (drifted {offHinge})`)
	T.expect(pastShut < 1e-3, `it slams shut without swinging into the booth ({pastShut})`)
	T.expect((door.Position - roblox.Vector3.new(0, 3.45, 8)).Magnitude < 1e-3, `the door is shut ({door.Position})`)

	-- The night starts and the first passengers walk out of the fog to the queue.
	local root
	sim:runUntil(
		function()
			for _, model in sim.workspace.World.Passengers:GetChildren() do
				local candidate = model:FindFirstChild("HumanoidRootPart")
				if candidate and (candidate:GetAttribute("GlideTime") or 0) > 3 then
					root = candidate
					return true
				end
			end
			return false
		end,
		120,
		1 / 30,
		function()
			tick(bot)
		end
	)
	T.expect(root ~= nil, "a passenger set off from the fog")
	local writes = sim:countWrites(root, "CFrame")
	local positions = {}
	sim:run(2, 1 / 30, function()
		table.insert(positions, root.Position)
	end)
	local stride = 7 / 30 -- Config.WalkSpeed studs a second, 30 frames a second
	for i = 2, #positions do
		local step = (positions[i] - positions[i - 1]).Magnitude
		T.expect(math.abs(step - stride) < 0.02, `frame {i}: moved {step} studs, not a steady {stride}`)
	end
	T.equal(writes.server or 0, 0, "the server sent the walk once and left the moving to the client")
	T.expect((writes["client:101"] or 0) >= 59, `Alice's client moved them every frame ({writes["client:101"]})`)
	clean(sim, "smooth walking")
end)

T.test("passengers speak in Roblox-style bubbles for the whole window, and in the chat log", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bob = sim:addPlayer("Bob", 202)
	local bot = newBot(sim, alice, { idle = true, pressContinue = false })
	local friend = newBot(sim, bob, { idle = true, pressContinue = false })
	local function bothSee(): boolean
		for _, player in { alice, bob } do
			local bubble = speechBubble(player)
			if not (bubble and sim:shown(bubble)) then
				return false
			end
		end
		return true
	end
	local seen = sim:runUntil(bothSee, 300, 1 / 20, function()
		-- Both press Continue so the first window opens.
		for _, player in { alice, bob } do
			local continue = player.PlayerGui.LastFerryHud.Root.Overlay.Card.Footer.Continue
			if sim:shown(continue) and continue.Interactable then
				sim:click(continue)
			end
		end
		tick(bot)
		tick(friend)
	end)
	clean(sim, "speech")
	T.expect(seen, "bubbles appeared")
	local tells = lookAtPassenger(sim)
	T.expect(tells ~= nil, "someone is at the window")
	local line = heard(bot, tells.model)
	T.expect(line ~= "", "Alice sees the passenger's line over their head")
	T.equal(heard(friend, tells.model), line, "Bob sees the same line")

	-- Roblox's own bubble look, drawn over everything: the booth's walls and the HUD.
	local bubble = speechBubble(alice)
	local label = bubble.Bubble.Line
	T.equal(label.FontFace.Family, "rbxasset://fonts/families/GothamSSm.json", "Roblox's bubble font")
	T.equal(label.TextSize, 16, "at Roblox's bubble size")
	T.equal(bubble.Bubble.BackgroundColor3, roblox.Color3.fromRGB(250, 250, 250), "white")
	T.equal(bubble.Caret.Image, "rbxasset://textures/ui/InGameChat/Caret.png", "with Roblox's tail")
	T.expect(bubble.Parent.DisplayOrder > alice.PlayerGui.LastFerryHud.DisplayOrder, "over the HUD")

	-- Still up near the end of the window, long after Roblox's own bubbles would have gone.
	sim:run(40, 1 / 20)
	T.equal(heard(bot, tells.model), line, "still readable 40 s later")
	-- Once the window closes (at 45 s) it goes with them, a moment later.
	sim:run(7, 1 / 20)
	T.equal(heard(bot, tells.model), "", "gone once they've left the window")

	local logged = 0
	for _, message in sim.systemMessages do
		-- The chat line is rich text, so its quotes and ampersands are escaped.
		local text = string.gsub(message.text, "&(%a+);", { apos = "'", quot = '"', lt = "<", gt = ">", amp = "&" })
		if message.channel == "RBXSystem" and string.find(text, line, 1, true) then
			logged += 1
		end
	end
	T.equal(logged, 2, "the line is in both players' chat logs")
	clean(sim, "speech after the window")
end)

T.test("on a console, where Roblox's chat never shows, passengers' lines still do, bigger", function()
	-- A 1080p TV, under Roblox's top bar at its TV size (87 px).
	local sim = Sim.new({
		root = ROOT,
		tenFoot = true,
		preferredInput = roblox.Enum.PreferredInput.Gamepad,
		screen = roblox.Vector2.new(1920, 1080),
		safeArea = roblox.Vector2.new(1920, 993),
	})
	sim:startServer()
	sim:run(1)
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, { idle = true })
	local seen = sim:runUntil(
		function()
			local bubble = speechBubble(alice)
			return bubble ~= nil and sim:shown(bubble)
		end,
		300,
		1 / 20,
		function()
			tick(bot)
		end
	)
	clean(sim, "console")
	T.expect(seen, "the passenger's line shows")
	T.equal(speechBubble(alice).Bubble.Line.TextSize, 24, "in bigger type, for a TV across the room")
	sim:run(0.5)
	checkTextFits(sim, alice, "on a TV")
end)

-- On one screen, from every stand: the passenger's line is up, clear of every piece of the
-- HUD, and entirely above their head (never over their face). With `snug`, there's room
-- for it to sit where Roblox's own bubbles do, its tail touching a point just over their
-- head. With `crowded` (text drawn bigger than designed), it may not fit under the top bar
-- row: then it sits on their head, over the row (see Ui/Speech), and covers nothing else.
local function checkSpeechPlacement(sim, player, model, label: string, snug: boolean, crowded: boolean?)
	local camera = sim.workspace.CurrentCamera
	local stack = speechBubble(player)
	local screen = sim.workspace.CurrentCamera.ViewportSize
	local inset = sim.game:GetService("GuiService"):GetGuiInset()
	for _, name in STAND_ORDER do
		standAt(sim, player, STANDS[name])
		local where = `{label}, {name} stand`
		T.expect(sim:shown(stack) and stack.Bubble.Line.Text ~= "", `{where}: the line is up`)
		local bubble = box(stack)
		local boxFrame, size = model:GetBoundingBox()
		local top = roblox.Vector3.new(
			model.HumanoidRootPart.Position.X,
			boxFrame.Position.Y + size.Y / 2,
			model.HumanoidRootPart.Position.Z
		)
		local head = camera:WorldToScreenPoint(top)
		for piece, r in hudPieces(sim, player) do
			local group = string.match(piece, "^(%a+)%.")
			local upTop = group == "Left" or group == "Right" or group == "Row" or piece == "Play.Row"
			T.expect(
				not overlap(bubble, r) or (crowded and upTop and math.abs(bubble.bottom - head.Y) < 1.5),
				`{where}: the bubble {describe(bubble)} overlaps the HUD's {piece} {describe(r)}`
			)
		end
		T.expect(
			bubble.bottom <= head.Y + 0.5,
			`{where}: the bubble ends at {bubble.bottom}, below the top of their head at {head.Y}`
		)
		T.expect(bubble.left >= 0 and bubble.right <= screen.X, `{where}: the bubble {describe(bubble)} is on screen`)
		T.expect(bubble.top >= -inset.Y, `{where}: the bubble {describe(bubble)} is below the top of the screen`)
		-- Roblox draws its own buttons in the top bar row over every game's GUI.
		local free = sim.game:GetService("GuiService").TopbarInset
		T.expect(
			bubble.top >= -0.5 or (bubble.left >= free.Min.X - 0.5 and bubble.right <= free.Max.X + 0.5),
			`{where}: the bubble {describe(bubble)} is under Roblox's own buttons (free from x {free.Min.X} to {free.Max.X})`
		)
		-- The tail points down at them, wherever the bubble has had to move.
		local caret = box(stack.Caret)
		local tip = camera:WorldToScreenPoint(top + roblox.Vector3.new(0, 0.4, 0))
		local x, y = (caret.left + caret.right) / 2, caret.bottom
		T.expect(stack.Caret.Visible, `{where}: the tail is showing`)
		T.expect(math.abs(x - tip.X) < 1.5, `{where}: the tail at x {x} points at their head, at x {tip.X}`)
		if snug then
			T.expect(
				math.abs(y - tip.Y) < 1.5,
				`{where}: the tail's tip at y {y} touches the point over their head, at y {tip.Y}`
			)
		end
	end
end

-- From the front stand, turning the view from 40 degrees left to 40 right and tilting it up
-- and down a little: wherever the passenger is on screen, their line never covers a piece of
-- the HUD. The one exception is the top bar row, which it goes over only when their head is
-- so high on screen that it would otherwise cover their face: it's then sitting on their
-- head. Then back to looking at them.
local function checkSpeechTurning(sim, player, model, label: string)
	standAt(sim, player, STANDS.front)
	local camera = sim.workspace.CurrentCamera
	local ahead = camera.CFrame
	for _, pitch in { -8, 0, 8 } do
		for yaw = -40, 40, 4 do
			camera.CFrame = roblox.CFrame.new(ahead.Position)
				* roblox.CFrame.Angles(0, math.rad(yaw), 0)
				* ahead.Rotation
				* roblox.CFrame.Angles(math.rad(pitch), 0, 0)
			sim:step(1 / 30)
			local stack = speechBubble(player)
			if sim:shown(stack) then
				local where = `{label}, turned {yaw} degrees and tilted {pitch}`
				local bubble = box(stack)
				local boxFrame, size = model:GetBoundingBox()
				local root = model.HumanoidRootPart.Position
				local head =
					camera:WorldToScreenPoint(roblox.Vector3.new(root.X, boxFrame.Position.Y + size.Y / 2, root.Z))
				for piece, r in hudPieces(sim, player) do
					if overlap(bubble, r) then
						local group = string.match(piece, "^(%a+)%.")
						local upTop = group == "Left" or group == "Right" or group == "Row" or piece == "Play.Row"
						local onHead = math.abs(bubble.bottom - head.Y) < 1.5
						T.expect(
							upTop and onHead,
							`{where}: the bubble {describe(bubble)} covers the HUD's {piece} {describe(r)}, with their head at y {head.Y}`
						)
					end
				end
			end
		end
	end
	standAt(sim, player, STANDS.front)
end

-- Makes every passenger say `line`.
local function everyoneSays(sim, line: string)
	sim:execute(string.format(
		[[
		local Content = require("./Shift/Content")
		local line = %q
		for _, regular in Content.Regulars do
			for i in regular.lines do
				regular.lines[i] = line
			end
		end
		for i in Content.LivingLines do
			Content.LivingLines[i] = line
		end
		for _, herring in Content.RedHerrings do
			herring.line = line
		end
		for _, lines in Content.DrownedLines do
			for i in lines do
				lines[i] = line
			end
		end
		for i in Content.Mara.lines do
			Content.Mara.lines[i] = line
		end
		Content.Anna.line = line
	]],
		line
	))
end

-- The longest line any passenger can say (with "{name}" as the longest display name Roblox
-- allows).
local LONGEST_LINE = [[
	local Content = require("./Shift/Content")
	local name = string.rep("W", 20)
	local longest = ""
	local function consider(line)
		line = string.gsub(line, "{name}", name)
		if #line > #longest then
			longest = line
		end
	end
	for _, regular in Content.Regulars do
		for _, line in regular.lines do
			consider(line)
		end
	end
	for _, line in Content.LivingLines do
		consider(line)
	end
	for _, herring in Content.RedHerrings do
		consider(herring.line)
	end
	for _, lines in Content.DrownedLines do
		for _, line in lines do
			consider(line)
		end
	end
	for _, line in Content.Mara.lines do
		consider(line)
	end
	consider(Content.Anna.line)
	return longest
]]

-- Plays until a passenger with a torn page is at the window, then stops playing (the bot's
-- policy must have stopAtPage). Returns the passenger's model.
local function untilAPage(sim, bot)
	local reached = sim:runUntil(
		function()
			return bot.atPage == true
		end,
		1800,
		1 / 20,
		function()
			tick(bot)
		end
	)
	assert(reached, "no page came up")
	local tells = lookAtPassenger(sim)
	assert(tells, "nobody at the window")
	return tells.model
end

T.test("the passenger's line is never under the HUD or over their face, from any stand, on any screen", function()
	for _, screen in
		{
			{
				label = "a 16:9 monitor",
				screen = roblox.Vector2.new(1280, 720),
				safeArea = roblox.Vector2.new(1280, 662),
				snug = true,
			},
			{
				label = "a notched phone",
				screen = roblox.Vector2.new(844, 390),
				safeArea = roblox.Vector2.new(750, 332),
				input = roblox.Enum.PreferredInput.Touch,
			},
			{
				label = "an iPhone SE",
				screen = roblox.Vector2.new(667, 375),
				safeArea = roblox.Vector2.new(667, 317),
				input = roblox.Enum.PreferredInput.Touch,
			},
		}
	do
		local sim = boot({
			root = ROOT,
			screen = screen.screen,
			safeArea = screen.safeArea,
			preferredInput = screen.input,
		})
		-- Everyone says the longest line in the game, so the bubble is as big as it gets.
		local longest = sim:execute(LONGEST_LINE)
		everyoneSays(sim, longest)
		local alice = sim:addPlayer("Alice", 101)
		sim.cameraFollows = alice
		local bot = newBot(sim, alice, { stopAtPage = true })
		local model = untilAPage(sim, bot)
		T.equal(speechBubble(alice).Bubble.Line.Text, longest, `{screen.label}: the longest line`)
		local root = alice.PlayerGui.LastFerryHud.Root
		local tab = root.Play.Desk.TicketHolder.PageTab
		checkSpeechPlacement(sim, alice, model, `{screen.label}, a page to take`, screen.snug == true)
		checkTextFits(sim, alice, `{screen.label}, a page to take`)
		checkHint(sim, alice, `{screen.label}, a page to take`)
		checkSpeechTurning(sim, alice, model, `{screen.label}, a page to take`)
		sim:click(tab)
		sim:run(1)
		T.expect(sim:shown(root.Play.Ledger), `{screen.label}: taking the page opened the ledger`)
		checkSpeechPlacement(sim, alice, model, `{screen.label}, ledger open`, screen.snug == true)
		checkTextFits(sim, alice, `{screen.label}, ledger open`)
		checkHint(sim, alice, `{screen.label}, ledger open`)
		sim:click(root.Play.Ledger.Close)
		checkSpeechPlacement(sim, alice, model, `{screen.label}, rules showing`, screen.snug == true)
		sim:click(root.Play.Side.Tabs.HIDE)
		checkSpeechPlacement(sim, alice, model, `{screen.label}, rules hidden`, screen.snug == true)
		checkTextFits(sim, alice, `{screen.label}, rules hidden`)
		clean(sim, screen.label)
	end
end)

T.test("all five torn pages reach the ledger and the epilogue", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, { takePages = true })
	sim:runUntil(
		function()
			return bot.ending ~= nil
		end,
		3600,
		1 / 20,
		function()
			tick(bot)
		end
	)
	sim:run(3)
	clean(sim, "ledger run")
	T.equal(bot.pagesTaken, 5)
	T.expect(string.find(bot.endingText, "THE LEDGER", 1, true) ~= nil, "the ledger epilogue is on the ending card")
	local saved = sim.stores.LastFerryProgress_v1.u_101
	T.expect(saved.endings.THE_LEDGER and saved.endings.CLEAN_SHIFT, "both endings saved")
end)

T.test("keyboard shortcuts work the window, the page tab and the cards", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, { useKeys = true, takePages = true })
	sim:runUntil(
		function()
			return bot.ending ~= nil
		end,
		3600,
		1 / 20,
		function()
			tick(bot)
		end
	)
	sim:run(3)
	clean(sim, "keyboard run")
	T.equal(bot.ending, "The Petrel Sails")
	T.equal(bot.lanternsLost, 0)
	T.equal(bot.pagesTaken, 5)
	T.expect(bot.sawLedger, "taking a page opened the ledger")
end)

T.test("in co-op the ledger opens only for whoever took the page", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bob = sim:addPlayer("Bob", 202)
	local finder = newBot(sim, alice, { takePages = true })
	local friend = newBot(sim, bob, { idle = true, pressContinue = false })
	sim:runUntil(
		function()
			return finder.pagesTaken >= 2
		end,
		3600,
		1 / 20,
		function()
			tick(finder)
			tick(friend)
		end
	)
	sim:run(2, 1 / 20, function()
		tick(finder)
		tick(friend)
	end)
	clean(sim, "co-op pages")
	T.expect(finder.sawLedger, "the finder's ledger opened")
	T.expect(not friend.sawLedger, "the friend's ledger stayed shut")
	local noticed = false
	for _, line in friend.alerts do
		if string.find(line, "A TORN PAGE", 1, true) then
			noticed = true
		end
	end
	T.expect(noticed, "the friend was told a page was found")
end)

T.test("waving Mara through on the last night brings the Marigold", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, {
		override = function(view)
			if view.name == "Mara Pike" and view.night == 5 then
				return "board"
			end
			return nil
		end,
	})
	sim:runUntil(
		function()
			return bot.ending ~= nil
		end,
		3600,
		1 / 20,
		function()
			tick(bot)
		end
	)
	sim:run(8) -- the Marigold fades in over a few seconds
	clean(sim, "Mara run")
	T.equal(bot.ending, "Mara Goes Home")
	T.equal(bot.lanternsLost, 0, "Mara never costs a lantern")
	T.equal(sim.workspace.World.Marigold.Hull.Transparency, 0.55, "the ghost ship is visible")
	T.equal(sim.workspace.World.Lighthouse.Rotor:GetAttribute("Spinning"), true, "the lighthouse is lit")
end)

T.test("an idle clerk: windows close, lanterns go out, the tide comes in, the night restarts", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, { idle = true, pressContinue = false })
	sim:runUntil(
		function()
			return bot.sawRetry
		end,
		900,
		1 / 20,
		function()
			tick(bot)
		end
	)
	sim:run(2) -- the flood drains over a second as the retry starts
	clean(sim, "idle run")
	T.expect(bot.lanternsLost >= 3, "lanterns went out")
	T.expect(bot.sawFailed, "the tide came in")
	T.expect(bot.sawRetry, "the night started again")
	T.equal(sim.workspace.World.Flood.Transparency, 1, "the flood drained for the retry")
	local sounds = soundsPlayed(sim)
	T.expect(sounds["client:LastFerryGust"], "a gust as each lantern blows out")
	T.expect(sounds["server:Slosh"], "water sloshing round the booth")
	T.expect(not sim.workspace.World.Flood.Slosh.IsPlaying, "and it stops when the flood drains")
end)

T.test("on phones the HUD scales down but the main buttons stay at least 44 px", function()
	-- In landscape, under Roblox's 58 px top bar: a notched phone, and an iPhone SE.
	for _, phone in
		{
			{ screen = roblox.Vector2.new(844, 390), safeArea = roblox.Vector2.new(750, 332) },
			{ screen = roblox.Vector2.new(667, 375), safeArea = roblox.Vector2.new(667, 317) },
		}
	do
		local sim = boot({
			root = ROOT,
			screen = phone.screen,
			safeArea = phone.safeArea,
			preferredInput = roblox.Enum.PreferredInput.Touch,
		})
		local alice = sim:addPlayer("Alice", 101)
		sim:run(3)
		clean(sim, "phone boot")
		checkTextFits(sim, alice, "on the pier, on a phone")
		local root = alice.PlayerGui.LastFerryHud.Root
		local scale = root.UIScale.Scale
		T.expect(scale < 1, `scaled down ({scale})`)
		local main = { root.Play.Desk.Board, root.Play.Desk.Deny, root.Overlay.Card.Footer.Continue }
		for _, button in main do
			local height = button.Size.Y.Offset * scale
			T.expect(height >= 44, `{button.Name} is {height} px tall at scale {scale}`)
		end
		local tab = root.Play.Desk.TicketHolder.PageTab
		T.expect((tab.Size.X.Offset - 28) * scale >= 44, "the page tab shows at least 44 px")
		-- Secondary controls (tabs, ledger) stay usable at 38 px or more.
		for _, button in { root.Play.Side.Tabs.RULES, root.Play.Side.Tabs.MANIFEST, topRow(alice).TopBar.Right.Ledger } do
			T.expect(button.AbsoluteSize.Y >= 38, `{button.Name} is {button.AbsoluteSize.Y} px`)
		end
		T.expect(string.find(root.Play.Hint.Text, "Pinch", 1, true) ~= nil, "touch hint")
		-- The rules panel stops short of Roblox's jump button (bottom right, 90 px up).
		local side = root.Play.Side
		local screenBottom = root.Parent.AbsolutePosition.Y + root.Parent.AbsoluteSize.Y
		local gap = screenBottom - (side.AbsolutePosition.Y + side.AbsoluteSize.Y)
		T.expect(gap >= 112, `the rules panel ends {gap} px above the bottom, clear of the jump button`)
		T.expect(
			string.find(root.Lobby.How.Text, "Touch and hold", 1, true) ~= nil,
			"the pier says to hold the prompt, as it needs"
		)
	end
end)

-- The status pills on this player's screen: those on the left and those on the right don't
-- meet, and all are inside the row. Returns the room between the two.
local function checkPills(player, label: string): number
	local bar = topRow(player).TopBar
	local leftEnd, rightStart = -math.huge, math.huge
	for _, pill in bar.Left:GetChildren() do
		if pill:IsA("GuiObject") and pill.Visible then
			leftEnd = math.max(leftEnd, pill.AbsolutePosition.X + pill.AbsoluteSize.X)
		end
	end
	for _, pill in bar.Right:GetChildren() do
		if pill:IsA("GuiObject") and pill.Visible then
			rightStart = math.min(rightStart, pill.AbsolutePosition.X)
		end
	end
	local row = bar.Parent
	T.expect(
		leftEnd < rightStart,
		`{label}: the pills on the left ({leftEnd}) run into those on the right ({rightStart})`
	)
	T.expect(
		rightStart >= row.AbsolutePosition.X and leftEnd <= row.AbsolutePosition.X + row.AbsoluteSize.X,
		`{label}: the pills stay in the row`
	)
	return rightStart - leftEnd
end

T.test("on the smallest phone, every card's words fit, from the first night to the ending", function()
	-- An iPhone SE in landscape, under Roblox's top bar. The bot checks each card's text
	-- as it comes up (tick); the ending card is checked here, once its scene has played.
	local sim = boot({
		root = ROOT,
		screen = roblox.Vector2.new(667, 375),
		safeArea = roblox.Vector2.new(667, 317),
		preferredInput = roblox.Enum.PreferredInput.Touch,
	})
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, { takePages = true })
	local finished = sim:runUntil(
		function()
			return bot.ending ~= nil
		end,
		3600,
		1 / 20,
		function()
			tick(bot)
		end
	)
	T.expect(finished, `the run never ended (stuck at {math.floor(sim.now)}s on "{bot.lastCard}")`)
	sim:run(3)
	clean(sim, "phone run")
	checkEndingCard(sim, alice, "the ending card, on a phone")
end)

-- The labels held at a size in the player's HUD and status (Ui.holdTextSize; the bubble
-- holds its own).
local function heldLabels(player): { any }
	local found = {}
	for _, name in { "LastFerryHud", "LastFerryTopBar" } do
		for _, object in player.PlayerGui[name]:GetDescendants() do
			if object:IsA("UITextSizeConstraint") then
				table.insert(found, object.Parent)
			end
		end
	end
	return found
end

-- Held labels held at more than their TextSize, by name: the ticket's name grows into the
-- room its box has (Ticket.luau).
local HELD_AT = { Passenger = 26 }

-- Every label in a box that can't grow is held at its size, or at the size the player's
-- Text Size draws it if that's smaller: not bigger, and not smaller either (but for
-- rounding down to a whole screen pixel, if Roblox holds text on screen).
local function checkHeld(sim, player, how: string)
	local held = heldLabels(player)
	T.expect(#held > 20, `{how}: labels in boxes that can't grow are held ({#held})`)
	for _, object in held do
		local wanted = math.min(sim:drawnTextSize(object, true), HELD_AT[object.Name] or object.TextSize)
		local drawn, onePixel = sim:drawnTextSize(object), 1 / sim:scaleOf(object)
		T.expect(
			drawn >= wanted - onePixel - 0.01 and drawn <= wanted + 0.01,
			`{how}: {object:GetFullName()} is drawn at {drawn}, for {wanted}`
		)
	end
end

-- What the game found out about where Roblox holds text (Ui.findWhereTextIsHeld), once it
-- has asked.
local function textHeld(sim, player): string
	local gui = player.PlayerGui.LastFerryHud
	sim:runUntil(function()
		return gui:GetAttribute("TextHeld") ~= nil
	end, 5)
	return gui:GetAttribute("TextHeld")
end

-- Roblox draws all text bigger at the player's Text Size setting (GuiService's
-- PreferredTextSize), except where a UITextSizeConstraint holds it down (Ui.holdTextSize).
-- Roblox doesn't say whether it adds that in a label's own pixels or on screen: on a
-- monitor, where the HUD is scaled up, its own pixels are the more demanding; on a phone,
-- scaled down, the screen's (Sim.new's textSizeOffsetIn).
T.test("at every Text Size a player can choose, the longest line and every word still fit", function()
	for _, screen in
		{
			{
				label = "a 16:9 monitor",
				screen = roblox.Vector2.new(1280, 720),
				safeArea = roblox.Vector2.new(1280, 662),
				roomy = true,
			},
			{
				label = "a notched phone",
				screen = roblox.Vector2.new(844, 390),
				safeArea = roblox.Vector2.new(750, 332),
				input = roblox.Enum.PreferredInput.Touch,
				-- Roblox's buttons as wide as they get with voice chat on: past the desk, with
				-- the status still up in their row.
				wideButtons = 240,
				-- And buttons of Roblox's on the right of the row too, past the rules panel
				-- (Roblox puts none there now, but its layout allows them).
				rightButtons = 250,
			},
			{
				label = "an iPhone SE",
				screen = roblox.Vector2.new(667, 375),
				safeArea = roblox.Vector2.new(667, 317),
				input = roblox.Enum.PreferredInput.Touch,
				-- With a microphone button beside Roblox's own (voice chat on).
				micButtons = 208,
			},
		}
	do
		for _, textSize in { "Large", "Larger", "Largest" } do
			local largest = textSize == "Largest"
			local label = `{screen.label}, at Text Size {textSize}`
			local sim = boot({
				root = ROOT,
				screen = screen.screen,
				safeArea = screen.safeArea,
				preferredInput = screen.input,
				preferredTextSize = (roblox.Enum.PreferredTextSize :: any)[textSize],
				textSizeOffsetIn = if screen.roomy then "label" else "screen",
			})
			everyoneSays(sim, sim:execute(LONGEST_LINE))
			local alice = sim:addPlayer("Alice", 101)
			sim.cameraFollows = alice
			sim:run(3)
			checkTextFits(sim, alice, `{label}, on the pier`)
			checkHeld(sim, alice, `{label}, on the pier`)
			-- The bot checks everything on screen as it plays (the night's card included), up to
			-- a passenger with a page to take.
			local bot = newBot(sim, alice, { stopAtPage = true, checkText = label, grown = true })
			local model = untilAPage(sim, bot)
			local root = alice.PlayerGui.LastFerryHud.Root
			local reading = readingText(root.Play.Side.Scroller.Rules)
			table.insert(reading, root.Play.Hint)
			for _, pill in { "NightPill", "ClockPill", "DatePill" } do
				table.insert(reading, topRow(alice).TopBar.Left[pill]:FindFirstChildOfClass("TextLabel"))
			end
			checkGrown(sim, reading, `{label}, a page to take`)
			checkHeld(sim, alice, `{label}, a page to take`)
			-- On a phone the longest line at a big size may only fit over the top bar row.
			local crowded = not screen.roomy
			checkSpeechPlacement(sim, alice, model, `{label}, a page to take`, false, crowded)
			-- The line is as big as the player asked for wherever there's room for it, and never
			-- smaller than designed (Ui/Speech draws it smaller only to keep it on screen).
			local line = speechBubble(alice).Bubble.Line
			local full = sim:drawnTextSize(line, true)
			local guiInset = sim.game:GetService("GuiService"):GetGuiInset()
			local drawnAt = {}
			for _, name in STAND_ORDER do
				standAt(sim, alice, STANDS[name])
				local drawn = sim:drawnTextSize(line)
				drawnAt[name] = drawn
				T.expect(
					if screen.roomy then drawn == full else drawn >= 16,
					`{label}, {name} stand: the line is drawn at {drawn} px`
				)
				if drawn < full then
					-- Only as much smaller as it had to be: 2 px bigger, it wouldn't have fitted
					-- under the top of the screen (allowing for each line 2 px taller, one line
					-- more, and the 4 px to spare it needs to be drawn bigger again).
					local top = box(speechBubble(alice)).top + guiInset.Y
					local lines = math.round(line.TextBounds.Y / drawn)
					T.expect(
						top <= 4 + 2 * lines + (drawn + 2) + 1,
						`{label}, {name} stand: drawn at {drawn} px, with {top} px over it`
					)
				end
			end
			if largest and screen.micButtons then
				-- Roblox's buttons a microphone wider: the line keeps out from under them, beside
				-- them rather than drawn smaller to fit under them (a step smaller at most, for
				-- the room it loses beside them).
				local before = sim.game:GetService("GuiService").TopbarInset
				sim:setTopbarInset(roblox.Rect.new(screen.micButtons, 0, screen.safeArea.X, 58))
				sim:run(0.5)
				for _, name in STAND_ORDER do
					standAt(sim, alice, STANDS[name])
					local drawn = sim:drawnTextSize(line)
					T.expect(
						drawn >= drawnAt[name] - 2,
						`{label}, Roblox's buttons to x {screen.micButtons}, {name} stand: the line is drawn at {drawn} px, from {drawnAt[name]}`
					)
				end
				checkSpeechPlacement(
					sim,
					alice,
					model,
					`{label}, Roblox's buttons to x {screen.micButtons}`,
					false,
					true
				)
				sim:setTopbarInset(before)
				sim:run(0.5)
			end
			checkTextFits(sim, alice, `{label}, a page to take`)
			checkHint(sim, alice, `{label}, a page to take`)
			sim:click(root.Play.Desk.TicketHolder.PageTab)
			sim:run(1)
			T.expect(sim:shown(root.Play.Ledger), `{label}: taking the page opened the ledger`)
			checkSpeechPlacement(sim, alice, model, `{label}, ledger open`, false, crowded)
			checkTextFits(sim, alice, `{label}, ledger open`)
			checkHint(sim, alice, `{label}, ledger open`)
			sim:click(root.Play.Ledger.Close)
			sim:click(root.Play.Side.Tabs.HIDE)
			checkSpeechPlacement(sim, alice, model, `{label}, rules hidden`, false, crowded)
			checkTextFits(sim, alice, `{label}, rules hidden`)
			if largest and screen.wideButtons then
				-- Voice chat and the like widen Roblox's own buttons (they're drawn over every
				-- game's GUI): a line crowded up into the row still isn't under them.
				sim:setTopbarInset(roblox.Rect.new(screen.wideButtons, 0, screen.safeArea.X, 58))
				sim:run(0.5)
				T.equal(
					topRow(alice).Parent,
					alice.PlayerGui.LastFerryTopBar,
					`{label}: the status is still up in Roblox's row`
				)
				checkSpeechPlacement(sim, alice, model, `{label}, Roblox's buttons wider`, false, true)
				checkTextFits(sim, alice, `{label}, Roblox's buttons wider`)
			end
			if largest and screen.rightButtons then
				-- Roblox's buttons on the right of the row too: nor under those, nor drawn smaller
				-- to fit under them (a step smaller at most, for the room it loses beside them).
				local right = screen.safeArea.X - screen.rightButtons
				sim:setTopbarInset(roblox.Rect.new(164, 0, right, 58))
				sim:run(0.5)
				for _, name in STAND_ORDER do
					standAt(sim, alice, STANDS[name])
					local drawn = sim:drawnTextSize(line)
					T.expect(
						drawn >= drawnAt[name] - 2,
						`{label}, Roblox's buttons from x {right}, {name} stand: the line is drawn at {drawn} px, from {drawnAt[name]}`
					)
				end
				checkSpeechPlacement(sim, alice, model, `{label}, Roblox's buttons on the right`, false, true)
				checkTextFits(sim, alice, `{label}, Roblox's buttons on the right`)
				checkPills(alice, `{label}, Roblox's buttons on the right`)
			end
			clean(sim, label)
		end
	end
end)

T.test("at the largest Text Size, every word fits all shift long", function()
	-- On the smallest screen: five nights, a page taken each night (the ledger opens), and a
	-- wrong call on the second (a lantern goes out, with a banner saying so). With the
	-- setting added on screen, which on a phone makes the most of it.
	local label = "an iPhone SE, at the largest Text Size"
	local sim = boot({
		root = ROOT,
		screen = roblox.Vector2.new(667, 375),
		safeArea = roblox.Vector2.new(667, 317),
		preferredInput = roblox.Enum.PreferredInput.Touch,
		preferredTextSize = roblox.Enum.PreferredTextSize.Largest,
		textSizeOffsetIn = "screen",
	})
	local alice = sim:addPlayer("Alice", 101)
	local wrong = false
	local bot = newBot(sim, alice, {
		checkText = label,
		grown = true,
		takePages = true,
		override = function(view, _, call)
			if view.night == 2 and not wrong then
				wrong = true
				return if call == "board" then "deny" else "board"
			end
			return nil
		end,
	})
	T.expect(
		sim:runUntil(
			function()
				return bot.ending ~= nil
			end,
			3600,
			1 / 20,
			function()
				tick(bot)
			end
		),
		`{label}: the run never ended (stuck at {math.floor(sim.now)}s on "{bot.lastCard}")`
	)
	T.equal(bot.lanternsLost, 1, `{label}: the one wrong call`)
	T.equal(bot.pagesTaken, 5, `{label}: a page each night`)
	local banner = false
	for _, line in bot.alerts do
		banner = banner or string.find(line, "LANTERN", 1, true) ~= nil
	end
	T.expect(banner, `{label}: a banner said the lantern went out ({table.concat(bot.alerts, "; ")})`)
	checkEndingCard(sim, alice, `{label}, the ending card`)
	clean(sim, label)
end)

T.test("the status fits whatever room Roblox's own top bar buttons leave it", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, { idle = true })
	local play = alice.PlayerGui.LastFerryHud.Root.Play
	T.expect(
		sim:runUntil(
			function()
				return sim:shown(play)
			end,
			120,
			1 / 20,
			function()
				tick(bot)
			end
		),
		"the first night started"
	)
	local bar = topRow(alice).TopBar
	local function check(label: string, shown: { [string]: boolean })
		sim:run(0.5)
		checkPills(alice, label)
		for name, want in shown do
			local pill = bar.Left:FindFirstChild(name) or bar.Right:FindFirstChild(name)
			T.equal(pill.Visible, want, `{label}: {name} showing`)
		end
	end
	check("plenty of room", { NightPill = true, ClockPill = true, DatePill = true, QueuePill = true, Lanterns = true })
	sim:setTopbarInset(roblox.Rect.new(700, 0, 1280, 58))
	check("Roblox's buttons take more room", { NightPill = true, ClockPill = true, DatePill = false, Lanterns = true })
	sim:setTopbarInset(roblox.Rect.new(900, 0, 1280, 58))
	check("and more", { NightPill = true, DatePill = false, QueuePill = false, Lanterns = true })
	sim:setTopbarInset(roblox.Rect.new(200, 0, 1280, 58))
	check(
		"and then less again",
		{ NightPill = true, ClockPill = true, DatePill = true, QueuePill = true, Lanterns = true }
	)
	clean(sim, "top bar room")
end)

-- With a page in the ledger, Roblox's buttons take more and more of the top bar row: the
-- status still fits, its extras going in order, and moves to the HUD only when even the
-- pills that always show wouldn't fit. At the player's Text Size `textSize`.
local function squeezeTheStatus(textSize)
	local sim = boot({ root = ROOT, preferredTextSize = textSize })
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice, { stopAtPage = true })
	untilAPage(sim, bot)
	sim:click(alice.PlayerGui.LastFerryHud.Root.Play.Desk.TicketHolder.PageTab)
	sim:run(0.5)
	local gui = alice.PlayerGui.LastFerryTopBar
	T.expect(sim:shown(topRow(alice).TopBar.Right.Ledger), "the ledger's pill is up")
	-- Roblox's buttons take more and more of the row, 16 px at a time. The bot waits at the
	-- window meanwhile (well inside the 45 seconds they wait).
	local order = { "DatePill", "QueuePill", "Word", "ClockPill" } -- the order they go in
	local spare: number? = nil -- the room between the two groups, up in the row
	local inHud = false
	local someFit: number? = nil -- the first row with room for some of the extras, not all
	local roomiest: { [string]: boolean } = {} -- which extras show with the most room
	for left = 164, 1244, 16 do
		sim:setTopbarInset(roblox.Rect.new(left, 0, 1280, 58))
		sim:run(0.3)
		local where = `the row from x {left}`
		local bar = topRow(alice).TopBar
		T.expect(sim:shown(bar), `{where}: the pills are up`)
		local between = checkPills(alice, where)
		local ledger = bar.Right.Ledger
		for _, always in { bar.Left.NightPill, ledger, ledger.Content.Icon, ledger.Content.Count, bar.Right.Lanterns } do
			T.expect(always.Visible, `{where}: the {always.Name} always shows`)
		end
		local extras = {
			DatePill = bar.Left.DatePill,
			QueuePill = bar.Right.QueuePill,
			Word = ledger.Content.Word,
			ClockPill = bar.Left.ClockPill,
		}
		local showing = 0
		for i = 1, #order do
			showing += if extras[order[i]].Visible then 1 else 0
			if left == 164 then
				roomiest[order[i]] = extras[order[i]].Visible
			end
			if i < #order and extras[order[i]].Visible then
				T.expect(extras[order[i + 1]].Visible, `{where}: the {order[i]} shows but the {order[i + 1]} doesn't`)
			end
		end
		if someFit == nil and showing > 0 and showing < #order then
			someFit = left
		end
		if bar.Parent.Parent == gui then
			T.expect(not inHud, `{where}: back up in Roblox's row with less room than before`)
			spare = between
		elseif not inHud then
			inHud = true
			-- Down in the HUD only because the pills that always show no longer fit: up in the
			-- row they had only the gap they keep between the two groups (three of Roblox's
			-- 8 px gaps) and less than 16 px more.
			T.expect(spare ~= nil and spare >= 24 and spare < 40, `{where}: moved to the HUD with {spare} px to spare`)
		end
	end
	T.expect(spare ~= nil and inHud, "the status was up in Roblox's row, then in the HUD")
	assert(someFit, "no row had room for some of the extras but not all")

	-- Back up in the row with room for some of the pills: with nothing changing, nothing is
	-- shown or hidden (the pills aren't switched on and off to see whether they fit).
	sim:setTopbarInset(roblox.Rect.new(someFit, 0, 1280, 58))
	sim:run(0.3)
	local bar = topRow(alice).TopBar
	T.equal(bar.Parent.Parent, gui, "back up in Roblox's row with a little more room")
	checkPills(alice, "a little more room")
	local extras = { bar.Left.DatePill, bar.Right.QueuePill, bar.Right.Ledger.Content.Word, bar.Left.ClockPill }
	local showing = 0
	local writes = {}
	for _, extra in extras do
		showing += if extra.Visible then 1 else 0
		writes[extra.Name] = sim:countWrites(extra, "Visible")
	end
	T.expect(showing > 0 and showing < #extras, `some of the pills fit ({showing} of {#extras})`)
	sim:run(2)
	for name, counts in writes do
		local total = 0
		for _, count in counts do
			total += count
		end
		T.equal(total, 0, `the {name} was shown or hidden {total} times with nothing changing`)
	end

	sim:setTopbarInset(roblox.Rect.new(164, 0, 1280, 58))
	sim:run(0.3)
	checkPills(alice, "room again")
	for _, extra in extras do
		T.equal(extra.Visible, roomiest[extra.Name], `room again: the {extra.Name} showing, as before`)
	end
	clean(sim, "ledger in the top bar")
end

T.test("with a page in the ledger the status still fits, and moves to the HUD only when it must", function()
	squeezeTheStatus(roblox.Enum.PreferredTextSize.Medium)
end)

T.test("at the largest Text Size, the status fits the top bar row the same way", function()
	-- The pills' text is drawn bigger, and measured as big as it's drawn.
	squeezeTheStatus(roblox.Enum.PreferredTextSize.Largest)
end)

-- Plays until a passenger at the window is talking, and returns their model.
local function untilTalking(sim, bot, limit: number)
	local model
	local talking = sim:runUntil(
		function()
			local tells = lookAtPassenger(sim)
			model = tells and tells.model
			return model ~= nil and heard(bot, model) ~= ""
		end,
		limit,
		1 / 20,
		function()
			tick(bot)
		end
	)
	return if talking then model else nil
end

T.test("text measured before its font has loaded is measured again once it has", function()
	-- Roblox loads each font the first time it's needed; until then text measures as a
	-- stand-in font's does (a fifth narrower, in the simulator). ContentProvider:PreloadAsync
	-- is meant to wait for the font, but players report it doesn't always: both ways.
	for _, waits in { true, false } do
		local how = if waits then "preloading waits" else "preloading doesn't wait"
		local sim = boot({ root = ROOT, fontsLoadAt = 25, preloadWaitsForFonts = waits })
		-- A short line, which a bubble left the stand-in font's size would be too narrow for.
		everyoneSays(sim, "Evening, clerk.")
		local alice = sim:addPlayer("Alice", 101)
		sim.cameraFollows = alice
		local bot = newBot(sim, alice, { idle = true })
		T.expect(untilTalking(sim, bot, 24) ~= nil, `{how}: a passenger is talking before the fonts have loaded`)
		-- Their line fits in its bubble, measured with the stand-in font and then with the
		-- real one. (Roblox doesn't draw the lines of wrapped text that don't fit, so a bubble
		-- left the stand-in's size would lose some of what they say.)
		local line = speechBubble(alice).Bubble.Line
		local function fits(label: string)
			local room = line.AbsoluteSize
			T.expect(
				line.TextFits,
				`{how}, {label}: "{line.Text}" doesn't fit in a bubble with room for {room.X} x {room.Y}`
			)
		end
		sim:run(0.5)
		T.expect(not sim.fontsLoaded, `{how}: the fonts are still loading`)
		fits("before the fonts have loaded")
		sim:run(sim.fontsLoadAt - sim.now + 0.5)
		T.expect(sim.fontsLoaded, `{how}: the fonts have loaded`)
		fits("once they have")
		if waits then
			-- And the status, measured with the stand-in font at first, fits the room it has
			-- with the real one, however much that is.
			for left = 164, 1100, 16 do
				sim:setTopbarInset(roblox.Rect.new(left, 0, 1280, 58))
				sim:run(0.3)
				checkPills(alice, `with the fonts loaded, the row from x {left}`)
			end
		end
		clean(sim, `late fonts, {how}`)
	end
end)

T.test("a window moved to a TV mid-line: the bubble's type grows with it, and still fits", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	sim.cameraFollows = alice
	local bot = newBot(sim, alice, { idle = true })
	T.expect(untilTalking(sim, bot, 120) ~= nil, "a passenger is talking")
	local line = speechBubble(alice).Bubble.Line
	T.equal(line.TextSize, 16, "at a computer's size")
	sim:setDisplaySize(roblox.Enum.DisplaySize.Large)
	sim:run(0.5)
	T.equal(line.TextSize, 24, "at a TV's size once the window's on one")
	T.expect(line.TextFits, "and the line fits its bubble")
	clean(sim, "moved to a TV")
end)

-- Has the server send the passenger at the window a line to say, as it does when they answer
-- a call.
local function sayAgain(sim, line: string)
	sim:execute(string.format(
		[[
		local Config = require("../ReplicatedStorage/Shared/Config")
		local Net = require("../ReplicatedStorage/Shared/Net")
		Net.event(Config.Remotes.Fx):FireAllClients({ kind = "say", text = %q })
	]],
		line
	))
end

T.test("at a big Text Size the line steps down a step at a time, as far as it must, without flicker", function()
	-- The longest line on a notched phone at the largest size, from the left stand, where
	-- it's drawn smaller only to stay on screen: tilting the view moves the passenger's head
	-- up or down the screen, and with it the room over their head.
	local sim = boot({
		root = ROOT,
		screen = roblox.Vector2.new(844, 390),
		safeArea = roblox.Vector2.new(750, 332),
		preferredInput = roblox.Enum.PreferredInput.Touch,
		preferredTextSize = roblox.Enum.PreferredTextSize.Largest,
	})
	local longest = sim:execute(LONGEST_LINE)
	everyoneSays(sim, longest)
	local alice = sim:addPlayer("Alice", 101)
	sim.cameraFollows = alice
	local bot = newBot(sim, alice, { idle = true })
	T.expect(untilTalking(sim, bot, 300) ~= nil, "a passenger is talking")
	standAt(sim, alice, STANDS.left)
	local camera = sim.workspace.CurrentCamera
	local ahead = camera.CFrame
	local limit = speechBubble(alice).Bubble.Line:FindFirstChildOfClass("UITextSizeConstraint")
	local function tilt(degrees: number): number
		camera.CFrame = roblox.CFrame.new(ahead.Position)
			* ahead.Rotation
			* roblox.CFrame.Angles(math.rad(degrees), 0, 0)
		sim:step(1 / 30)
		return limit.MaxTextSize
	end
	-- From looking up (their head low on the screen, where it fits as big as the setting
	-- draws it) to looking down: drawn smaller a step at a time, down to its designed size.
	-- (Not only ever smaller: lower down, the bubble can have room to be wider, and fewer
	-- lines.)
	local full = 16 + sim:textSizeOffset()
	local guiInset = sim.game:GetService("GuiService"):GetGuiInset()
	local sizes, edges = { tilt(25) }, {}
	for degrees = 25, -30, -0.1 do
		local size = tilt(degrees)
		if size ~= sizes[#sizes] then
			table.insert(sizes, size)
			table.insert(edges, { bigger = degrees + 0.1, smaller = degrees })
		end
	end
	local seen = table.concat(sizes, " ")
	T.equal(sizes[1], 1000, `looking up, as big as the setting draws it ({seen})`)
	T.equal(sizes[#sizes], 16, `looking down, at its designed size ({seen})`)
	for i = 2, #sizes do
		local a, b = sizes[i - 1], sizes[i]
		local change = math.abs((if a == 1000 then full else a) - (if b == 1000 then full else b))
		T.equal(change, 2, `a step at a time: {seen}`)
	end
	for i, edge in edges do
		local size, step = sizes[i], sizes[i + 1]
		if step > size then
			continue -- drawn bigger, lower down
		end
		local where = `from {size} to {step}`
		-- Where it has to be drawn smaller, found to within a hair's breadth (coming from
		-- looking up each time).
		local bigger, smaller = edge.bigger, edge.smaller
		for _ = 1, 24 do
			local middle = (bigger + smaller) / 2
			tilt(25)
			if tilt(middle) == size then
				bigger = middle
			else
				smaller = middle
			end
		end
		-- Just short of it, it stays the size it is, however long the view is held still,
		-- and all of it is on screen, to the pixel.
		tilt(25)
		tilt(bigger)
		for _ = 1, 5 do
			T.equal(tilt(bigger), size, `{where}: held still just short of the edge`)
		end
		local top = box(speechBubble(alice)).top
		T.expect(top >= -guiInset.Y, `{where}: just short of the edge, the bubble's top {top} is on screen`)
		-- Just past it, a step smaller (2 px) is enough.
		T.equal(tilt(smaller), step, `{where}: just past the edge, drawn a step smaller`)
		-- Rocking across it: once drawn smaller, it's drawn bigger again only with room to
		-- spare.
		local writes = sim:countWrites(limit, "MaxTextSize")
		for _ = 1, 10 do
			tilt(bigger)
			tilt(smaller)
		end
		local total = 0
		for _, count in writes do
			total += count
		end
		T.equal(total, 0, `{where}: the line's size changed while the view rocked`)
		edge.bigger, edge.smaller = bigger, smaller
	end
	-- Drawn smaller just short of the first edge, with no room to spare to be drawn bigger
	-- again, the next line starts afresh: as big as the setting draws it, where that fits.
	local first = edges[1]
	tilt(25)
	tilt(first.smaller)
	T.equal(tilt(first.bigger), sizes[2], "drawn smaller just short of the first edge")
	sayAgain(sim, longest)
	T.equal(tilt(first.bigger), sizes[1], "the next line is drawn as big as it fits")
	clean(sim, "rocking at a big Text Size")
end)

T.test("where Roblox holds text back is asked, not assumed, and text is held right either way", function()
	-- Roblox's docs don't say whether a UITextSizeConstraint holds text on screen, after any
	-- UIScale (a DevForum bug report says so), or in the label's own pixels, so the game asks
	-- Roblox once it starts. In a world where TextBounds don't show what a constraint does,
	-- it can't tell, and goes by the report.
	local monitor = { label = "a monitor", screen = roblox.Vector2.new(1280, 720), offsetIn = "label" }
	local phone = {
		label = "an iPhone SE",
		screen = roblox.Vector2.new(667, 375),
		safeArea = roblox.Vector2.new(667, 317),
		offsetIn = "screen",
	}
	for _, case in
		{
			{ on = monitor, constraintIn = "screen", answer = "screen" },
			{ on = phone, constraintIn = "screen", answer = "screen" },
			{ on = monitor, constraintIn = "label", answer = "label" },
			{ on = phone, constraintIn = "label", answer = "label" },
			{ on = phone, constraintIn = "screen", answer = "unknown", textBoundsIgnoreConstraints = true },
		}
	do
		local how = `{case.on.label}, text held {case.constraintIn == "screen" and "on screen" or "in its own pixels"}`
			.. (if case.textBoundsIgnoreConstraints then " (TextBounds don't show it)" else "")
		local sim = boot({
			root = ROOT,
			screen = case.on.screen,
			safeArea = case.on.safeArea,
			preferredTextSize = roblox.Enum.PreferredTextSize.Largest,
			textSizeOffsetIn = case.on.offsetIn,
			constraintIn = case.constraintIn,
			textBoundsIgnoreConstraints = case.textBoundsIgnoreConstraints,
		})
		local alice = sim:addPlayer("Alice", 101)
		T.equal(textHeld(sim, alice), case.answer, `{how}: what the game found`)
		sim:run(2)
		T.expect(
			alice.PlayerGui:FindFirstChild("LastFerryTextCheck") == nil,
			`{how}: the labels it asked with are gone`
		)
		checkHeld(sim, alice, `{how}, on the pier`)
		clean(sim, how)
	end
end)

T.test("the player changes their Text Size mid-line: the bubble is the right size by the next frame", function()
	-- With Roblox holding text on screen and in each label's own pixels.
	for _, constraintIn in { "screen", "label" } do
		local sim = boot({ root = ROOT, constraintIn = constraintIn })
		everyoneSays(sim, "Evening, clerk. One for the island, please.")
		local alice = sim:addPlayer("Alice", 101)
		sim.cameraFollows = alice
		local bot = newBot(sim, alice, { idle = true })
		T.expect(untilTalking(sim, bot, 120) ~= nil, "a passenger is talking")
		sim:run(0.5)
		T.equal(textHeld(sim, alice), constraintIn, "where the game found Roblox holds text")
		local bubble = speechBubble(alice).Bubble
		local before = bubble.AbsoluteSize
		-- Nothing is held back at the usual size, so the HUD looks as designed whatever
		-- Roblox does with a constraint.
		T.equal(#heldLabels(alice), 0, "at the usual Text Size, no label is held")
		-- Measured again when the setting changes: not left until the line turns out not to
		-- fit (or, going back down, never, as it would still fit a bubble too big for it).
		sim:setPreferredTextSize(roblox.Enum.PreferredTextSize.Largest)
		sim:step(1 / 60)
		T.expect(bubble.AbsoluteSize.Y > before.Y, `bigger at once ({bubble.AbsoluteSize}, from {before})`)
		T.expect(bubble.Line.TextFits, "with the line fitting it")
		-- Labels in boxes that can't grow are held at their own size under the HUD's UIScale
		-- (4/3 on this monitor), however it changes.
		local how = `text held {if constraintIn == "screen" then "on screen" else "in its own pixels"}`
		checkHeld(sim, alice, `{how}, at the largest Text Size`)
		-- Held again while the call stamp pops (its own UIScale, from 1.5 down to 1): only the
		-- scales the HUD is laid out at count, so it's still held at its size once it lands.
		local stamp = alice.PlayerGui.LastFerryHud.Root.Play.Desk.TicketHolder.Ticket.CallStamp
		local pop = stamp:FindFirstChildOfClass("UIScale")
		pop.Scale = 1.4
		sim:executeClient(alice, [[require("./Ui/Ui").refreshHeldText()]])
		pop.Scale = 1
		checkHeld(sim, alice, `{how}, held again while the stamp popped`)
		-- Roblox's top bar row grows half as big again (as on a TV), and the status with it.
		sim:setTopbarInset(roblox.Rect.new(164, 0, 1280, 87))
		sim:step(1 / 60)
		checkHeld(sim, alice, `{how}, in a taller top bar row`)
		sim:setTopbarInset(roblox.Rect.new(164, 0, 1280, 58))
		sim:step(1 / 60)
		-- The window shrinks to a phone's size, and the HUD's scale with it.
		sim:setScreen(roblox.Vector2.new(844, 390), roblox.Vector2.new(750, 332))
		sim:step(1 / 60)
		checkHeld(sim, alice, `{how}, in a smaller window`)
		sim:setScreen(roblox.Vector2.new(1280, 720), roblox.Vector2.new(1280, 662))
		sim:step(1 / 60)
		-- Each size between too.
		for _, size in { "Large", "Larger" } do
			sim:setPreferredTextSize((roblox.Enum.PreferredTextSize :: any)[size])
			sim:step(1 / 60)
			checkHeld(sim, alice, `{how}, at Text Size {size}`)
		end
		sim:setPreferredTextSize(roblox.Enum.PreferredTextSize.Medium)
		sim:step(1 / 60)
		T.equal(bubble.AbsoluteSize, before, "and back as it was at once")
		T.equal(#heldLabels(alice), 0, "and nothing held once it's back to the usual size")
		clean(sim, `Text Size changed mid-line, {how}`)
	end
end)

T.test("with no top bar row to put it in, the status sits at the top of the HUD instead", function()
	-- An old 36 px top bar: too short for the status's pills. On a monitor, and on phones at
	-- the largest Text Size with the setting added on screen, where the pills, scaled down
	-- with the HUD, have their text that much bigger in their own pixels; and once with
	-- Roblox not saying how much bigger the setting draws text (TextService fails).
	local touch = roblox.Enum.PreferredInput.Touch
	local largest = roblox.Enum.PreferredTextSize.Largest
	for _, case in
		{
			{ label = "a monitor", screen = roblox.Vector2.new(1280, 720), safeArea = roblox.Vector2.new(1280, 684) },
			{
				label = "an iPhone SE, at the largest Text Size",
				screen = roblox.Vector2.new(667, 375),
				safeArea = roblox.Vector2.new(667, 339),
				input = touch,
				textSize = largest,
			},
			{
				label = "a notched phone, at the largest Text Size",
				screen = roblox.Vector2.new(844, 390),
				safeArea = roblox.Vector2.new(750, 354),
				input = touch,
				textSize = largest,
			},
			{
				label = "an iPhone SE, at the largest Text Size, TextService failing",
				screen = roblox.Vector2.new(667, 375),
				safeArea = roblox.Vector2.new(667, 339),
				input = touch,
				textSize = largest,
				offsetFails = true,
			},
		}
	do
		local label = `no top bar row, {case.label}`
		local sim = boot({
			root = ROOT,
			screen = case.screen,
			safeArea = case.safeArea,
			preferredInput = case.input,
			preferredTextSize = case.textSize,
			textSizeOffsetIn = "screen",
			textSizeOffsetFails = case.offsetFails,
		})
		local alice = sim:addPlayer("Alice", 101)
		local bot = newBot(sim, alice, { stopAtPage = true })
		local play = alice.PlayerGui.LastFerryHud.Root.Play
		local onShift = sim:runUntil(
			function()
				return sim:shown(play)
			end,
			120,
			1 / 20,
			function()
				tick(bot)
			end
		)
		T.expect(onShift, `{label}: the first night started`)
		local row = play:FindFirstChild("Row")
		T.expect(row ~= nil, `{label}: the status row is in the HUD`)
		T.expect(sim:shown(row.TopBar.Left.NightPill), `{label}: and showing`)
		local rowBottom = row.AbsolutePosition.Y + row.AbsoluteSize.Y
		T.expect(play.Desk.AbsolutePosition.Y >= rowBottom, `{label}: the desk starts under it`)
		T.expect(play.Side.AbsolutePosition.Y >= rowBottom, `{label}: and so does the rules panel`)
		if case.input == nil then
			T.expect(row.TopBar.Right.Lanterns.AbsoluteSize.Y >= 38, `{label}: its pills are big enough to see and tap`)
		end
		-- A page in the ledger, so every pill that can show is up, and the passenger's line
		-- stays clear of it, from every stand.
		sim.cameraFollows = alice
		local model = untilAPage(sim, bot)
		checkPills(alice, label)
		-- On a phone at that size the line may only fit over the status, sitting on their head.
		local phone = case.input ~= nil
		checkSpeechPlacement(sim, alice, model, label, not phone, phone)
		checkTextFits(sim, alice, label)
		clean(sim, label)
	end
end)

T.test("on tablets the rules panel clears Roblox's bigger jump button", function()
	-- An iPad in landscape: the short side is over 500 px, so the jump button is 120 px, 210 px up.
	local safeArea = roblox.Vector2.new(1024, 710)
	local sim = boot({
		root = ROOT,
		screen = roblox.Vector2.new(1024, 768),
		safeArea = safeArea,
		preferredInput = roblox.Enum.PreferredInput.Touch,
	})
	local alice = sim:addPlayer("Alice", 101)
	sim:run(3)
	clean(sim, "tablet boot")
	checkTextFits(sim, alice, "on the pier, on a tablet")
	local root = alice.PlayerGui.LastFerryHud.Root
	local side = root.Play.Side
	local screenBottom = root.Parent.AbsolutePosition.Y + root.Parent.AbsoluteSize.Y
	local gap = screenBottom - (side.AbsolutePosition.Y + side.AbsoluteSize.Y)
	T.expect(gap >= 232, `the rules panel ends {gap} px above the bottom, clear of the jump button`)
	local height = side.AbsoluteSize.Y
	T.expect(height >= 300, `and still has room for the rules ({height} px)`)
end)

T.test("co-op: a friend who joins late sees the same shift, and the Continue waits for both", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice)
	-- Alice plays into night 2.
	sim:runUntil(
		function()
			return bot.nights[2] == true
		end,
		1800,
		1 / 20,
		function()
			tick(bot)
		end
	)
	local bob = sim:addPlayer("Bob", 202)
	sim:run(2, 1 / 20, function()
		tick(bot)
	end)
	T.expect(inBooth(bob), `Bob starts in the booth, not on the pier (feet at {feet(bob)})`)
	T.equal(bob:GetAttribute("OnShift"), true, "Bob is on shift")
	T.expect(bob.Character:FindFirstChild("ClerkCap") ~= nil, "Bob wears the cap")
	T.expect(tostring(feet(bob)) ~= tostring(feet(alice)), "Bob gets his own stand")
	local bobStand = bob:GetAttribute("Stand")
	T.expect(
		typeof(bobStand) == "Vector3" and (bobStand - feet(bob)).Magnitude < 0.05,
		`the server told Bob's client which stand is his ({bobStand}, where his feet are: {feet(bob)})`
	)
	T.expect(not sim:coreGuiEnabled(bob, "PlayerList"), "and his player list is put away for the shift too")
	local aliceNight = topRow(alice).TopBar.Left.NightPill.Night.Text
	local bobNight = topRow(bob).TopBar.Left.NightPill.Night.Text
	T.equal(bobNight, aliceNight, "Bob sees the same night")

	-- Only Alice presses Continue, so the next card shows 1 of 2 ready and runs its timer.
	local sawHalf = false
	sim:runUntil(
		function()
			return bot.nights[3] == true
		end,
		1800,
		1 / 20,
		function()
			tick(bot)
			local status = bob.PlayerGui.LastFerryHud.Root.Overlay.Card.Footer.Status.Text
			if string.find(status, "1 of 2 ready", 1, true) then
				sawHalf = true
			end
		end
	)
	T.expect(sawHalf, "the card shows 1 of 2 ready")

	sim:removePlayer(bob)
	sim:runUntil(
		function()
			return bot.ending ~= nil
		end,
		3600,
		1 / 20,
		function()
			tick(bot)
		end
	)
	clean(sim, "co-op run")
	T.equal(bot.ending, "The Petrel Sails")
end)

return nil
