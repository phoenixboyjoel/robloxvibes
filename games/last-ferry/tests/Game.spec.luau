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
	lit: number,
	alerts: { string },
	pagesTaken: number,
	nights: { [number]: boolean },
	sawFailed: boolean,
	sawRetry: boolean,
	sawLedger: boolean?,
	calls: number,
	clockIns: number,
}

local function hud(bot: Bot)
	local gui = bot.player.PlayerGui:FindFirstChild("LastFerryHud")
	return gui and gui:FindFirstChild("Root")
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
		night = tonumber(string.match(root.Play.TopBar.Left.Night.Text, "NIGHT (%d+)")),
	}
end

-- The latest chat bubble this player saw over `model` (bubbles go on the whole model).
local function heard(bot: Bot, model): string
	local latest = ""
	for _, bubble in bot.sim.bubbles do
		if bubble.player == bot.player and bubble.adornee == model then
			latest = bubble.message
		end
	end
	return latest
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

	-- On the pier between shifts: walk to the time clock and clock in.
	if root.Lobby.Visible then
		if bot.policy.clockIn ~= false then
			clockIn(bot)
		end
		return
	end

	-- Count lanterns going out from the top bar (they're relit each night).
	local lit = 0
	for _, lantern in root.Play.TopBar.Right.Lanterns:GetChildren() do
		if lantern:IsA("Frame") and lantern.Visible and lantern:GetAttribute("Lit") then
			lit += 1
		end
	end
	if lit < bot.lit then
		bot.lanternsLost += bot.lit - lit
	end
	bot.lit = lit

	local alert = root.Play.Alert
	if sim:shown(alert) then
		local line = `{alert.Caption.Text}: {alert.Paragraph.Text}`
		if bot.alerts[#bot.alerts] ~= line then
			table.insert(bot.alerts, line)
		end
	end

	local ledger = root.Play.Ledger
	if ledger.Visible then
		bot.sawLedger = true
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
	player.Character.Humanoid:AddAccessory(accessory)
	return handle
]]

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
				hatHidden = hat.Transparency == 1
			end
		end
	)
	T.expect(hatHidden, "her own hat goes under the clerk's cap for the shift")
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
	T.equal(alice.leaderstats.Endings.Value, 1, "the player list shows one ending found")
	T.equal(alice.leaderstats.Shifts.Value, 1, "and one shift worked")
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
	T.expect(alice.Character:FindFirstChild("ClerkCap") == nil, "the cap comes off")
	T.equal(alice.Character.Humanoid.WalkSpeed, 16, "walking at Roblox's usual pace again")
	T.equal(hat.Transparency, 0.1, "her own hat comes back as it was")
	T.expect(clockPrompt(sim).Enabled, "the time clock is ready for the next shift")
	T.equal(sim.workspace.World.Booth.Door.CanCollide, false, "the door is open")
	T.equal(root.Lobby.Found.Text, "Endings found: 1 of 4")
	T.equal(alice.CameraMode, roblox.Enum.CameraMode.Classic, "Roblox's third-person camera on the pier")
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
		T.expect(root.Parent.FreeCursor.Visible and root.Parent.FreeCursor.Modal, "the HUD frees the mouse")
		T.equal(root.Overlay.Card.Header.Title.Text, "Night 1", `{player.Name} sees the night 1 card`)
		local key = tostring(feet(player))
		T.expect(not standsUsed[key], "each clerk has their own stand")
		standsUsed[key] = true
	end
	T.equal(sim.workspace.World.Booth.Door.CanCollide, true, "the door shuts behind them")
	T.expect(not clockPrompt(sim).Enabled, "no clocking in again mid-shift")
	T.expect(sim.workspace.World.Booth.BoothSpawn.Enabled, "respawns land in the booth")
	T.expect(not sim.workspace.World.Pier.PierSpawn.Enabled, "not on the pier")
	-- The booth holds them: walls, glass, roof and the counter are solid.
	for _, name in { "Wall", "Glass", "Roof", "Counter", "CounterFront", "Floor" } do
		for _, part in sim.workspace.World.Booth:GetChildren() do
			if part.Name == name then
				T.expect(part.CanCollide, `{name} is solid`)
			end
		end
	end
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

T.test("passengers speak in chat bubbles over their heads, and in the chat log", function()
	local sim = boot()
	local alice = sim:addPlayer("Alice", 101)
	local bob = sim:addPlayer("Bob", 202)
	local bot = newBot(sim, alice, { idle = true, pressContinue = false })
	local friend = newBot(sim, bob, { idle = true, pressContinue = false })
	local seen = sim:runUntil(
		function()
			return #sim.bubbles >= 2
		end,
		300,
		1 / 20,
		function()
			-- Both press Continue so the first window opens.
			for _, player in { alice, bob } do
				local continue = player.PlayerGui.LastFerryHud.Root.Overlay.Card.Footer.Continue
				if sim:shown(continue) and continue.Interactable then
					sim:click(continue)
				end
			end
			tick(bot)
			tick(friend)
		end
	)
	clean(sim, "speech")
	T.expect(seen, "bubbles appeared")
	local tells = lookAtPassenger(sim)
	T.expect(tells ~= nil, "someone is at the window")
	local line = heard(bot, tells.model)
	T.expect(line ~= "", "Alice sees the passenger's line over their head")
	T.equal(heard(friend, tells.model), line, "Bob sees the same line")
	local logged = 0
	for _, message in sim.systemMessages do
		-- The chat line is rich text, so its quotes and ampersands are escaped.
		local text = string.gsub(message.text, "&(%a+);", { apos = "'", quot = '"', lt = "<", gt = ">", amp = "&" })
		if message.channel == "RBXSystem" and string.find(text, line, 1, true) then
			logged += 1
		end
	end
	T.equal(logged, 2, "the line is in both players' chat logs")
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
		-- The rules panel stops short of Roblox's jump button (bottom right, about 90 px up).
		local side = root.Play.Side
		local gap = (-side.Size.Y.Offset - 70) * scale
		T.expect(gap >= 112, `the rules panel ends {gap} px above the bottom, clear of the jump button`)
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
	T.expect(inBooth(bob), `Bob starts in the booth, not on the pier (feet at {feet(bob)})`)
	T.equal(bob:GetAttribute("OnShift"), true, "Bob is on shift")
	T.expect(bob.Character:FindFirstChild("ClerkCap") ~= nil, "Bob wears the cap")
	T.expect(tostring(feet(bob)) ~= tostring(feet(alice)), "Bob gets his own stand")
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
