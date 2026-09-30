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
	ending: string?,
	endingText: string,
	lanternsLost: number,
	lastMessage: string,
	pagesTaken: number,
	nights: { [number]: boolean },
	sawFailed: boolean,
	sawRetry: boolean,
	calls: number,
}

local function hud(bot: Bot)
	local gui = bot.player.PlayerGui:FindFirstChild("LastFerryHud")
	return gui and gui:FindFirstChild("Root")
end

local function textOf(label): string
	return if label then label.Text else ""
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
		speech = textOf(root.Play.Center.Speech:FindFirstChild("Paragraph")),
		night = tonumber(string.match(root.Play.TopBar.Left.Night.Text, "NIGHT (%d+)")),
	}
end

-- What you can see of the passenger standing at the window.
local function lookAtPassenger(sim)
	local folder = sim.workspace.World.Passengers
	for _, model in folder:GetChildren() do
		local rootPart = model:FindFirstChild("Root")
		if rootPart then
			local position = rootPart.Position
			if math.abs(position.X) < 0.5 and math.abs(position.Z + 3.2) < 0.5 then
				local breath = model:FindFirstChild("Breath", true)
				local drips = model:FindFirstChild("Drips", true)
				return {
					breath = breath ~= nil and breath.Enabled,
					wet = drips ~= nil and drips.Enabled,
					shadow = model.Coat.CastShadow,
				}
			end
		end
	end
	return nil
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
		lastMessage = "",
		pagesTaken = 0,
		nights = {},
		sawFailed = false,
		sawRetry = false,
		calls = 0,
	}
end

local function tick(bot: Bot)
	local sim = bot.sim
	local root = hud(bot)
	if root == nil then
		return
	end

	-- A lantern going out shows a message; count each new one.
	local message = root.Play.Center.Message
	if sim:shown(message) then
		local text = message.Paragraph.Text
		if text ~= bot.lastMessage then
			bot.lastMessage = text
			bot.lanternsLost += 1
		end
	else
		bot.lastMessage = ""
	end

	local ledger = root.LedgerModal
	if ledger.Visible then
		sim:click(ledger.Sheet.Close)
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
				sim:click(continue)
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
	if bot.policy.takePages and sim:shown(tab) then
		sim:click(tab)
		bot.pagesTaken += 1
		return
	end
	if bot.policy.idle then
		return
	end

	local tells = lookAtPassenger(sim)
	assert(tells, `no passenger at the window for {view.name}`)
	local call = rightCall(bot, view, tells)
	if bot.policy.override then
		call = bot.policy.override(view, tells, call) or call
	end
	bot.decided[ticketKey] = true
	bot.calls += 1
	sim:click(if call == "board" then board else deny)
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

T.test("a clerk playing from the HUD finishes five nights clean", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bot = newBot(sim, alice)
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
	sim:run(3) -- the save finishes just after the ending card appears
	clean(sim, "clean run")
	T.expect(finished, `the run never ended (stuck at {math.floor(sim.now)}s on "{bot.lastCard}")`)
	T.equal(bot.ending, "The Petrel Sails")
	T.equal(bot.lanternsLost, 0, "no lantern lost")
	for night = 1, 5 do
		T.expect(bot.nights[night], `saw the night {night} intro`)
	end
	T.expect(string.find(bot.endingText, "Endings found: 1 of 4 · The Petrel Sails", 1, true) ~= nil, bot.endingText)
	local saved = sim.stores.LastFerryProgress_v1.u_101
	T.expect(saved and saved.endings.CLEAN_SHIFT and saved.runs == 1, "progress saved to the DataStore")
	print(
		`    (a clean run took {math.floor(sim.now / 60)} min {math.floor(sim.now % 60)} s of game time, {bot.calls} calls)`
	)
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
end)

T.test("on phones the HUD scales down but the main buttons stay at least 44 px", function()
	-- Safe areas in landscape: a notched phone, and an iPhone SE.
	for _, safeArea in { roblox.Vector2.new(750, 330), roblox.Vector2.new(667, 335) } do
		local sim = boot({
			root = ROOT,
			screen = safeArea + roblox.Vector2.new(0, 40),
			safeArea = safeArea,
			preferredInput = roblox.Enum.PreferredInput.Touch,
		})
		local alice = sim:addPlayer("Alice", 101)
		sim:run(3)
		clean(sim, "phone boot")
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
		for _, button in { root.Play.Side.Tabs.RULES, root.Play.Side.Tabs.MANIFEST, root.Play.TopBar.Right.Ledger } do
			T.expect(button.Size.Y.Offset * scale >= 38, `{button.Name} is {button.Size.Y.Offset * scale} px`)
		end
		T.expect(string.find(root.Play.Hint.Text, "Pinch", 1, true) ~= nil, "touch hint")
	end
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
	local aliceNight = alice.PlayerGui.LastFerryHud.Root.Play.TopBar.Left.Night.Text
	local bobNight = bob.PlayerGui.LastFerryHud.Root.Play.TopBar.Left.Night.Text
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
