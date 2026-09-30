--!strict
--[[
	Plays the Director end to end with a simulated clock and a fake stage.

	The bot clerk sees only what a player sees: the broadcast screen state, and
	the passenger's visible tells in the world (wet, breath, shadow). If it can
	play a perfect run from those, the screen carries everything a player needs.
]]

local Config = require("../ReplicatedStorage/Shared/Config")
local View = require("../ReplicatedStorage/Shared/Types")
local Content = require("../ServerScriptService/Shift/Content")
local Director = require("../ServerScriptService/Shift/Director")
local Run = require("../ServerScriptService/Shift/Run")
local Types = require("../ServerScriptService/Shift/Types")
local T = require("./TestLib")

T.suite("Director")

type Facts = { wet: boolean, breath: boolean, shadow: boolean }

type Sim = {
	time: number,
	limit: number,
	director: Director.Director,
	actors: { number },
	pressers: { number },
	policy: Policy,
	state: View.State?,
	states: { View.State },
	fx: { { kind: string, text: string?, night: number } },
	log: { string },
	queue: { Types.Passenger },
	night: number,
	atWindow: Facts?,
	arrivedAt: number,
	decided: { [number]: boolean },
	sentOff: { { night: number, passenger: Types.Passenger, exit: Director.Exit } },
	recorded: { { ending: string, secret: boolean } },
	scenes: { string },
	flood: boolean,
	lanterns: number,
	ferryLoad: number,
}

type Policy = {
	-- Returns the call to make, or nil to let the window close.
	decide: ((state: View.State, facts: Facts, sim: Sim) -> Types.Decision?)?,
	takePages: boolean?,
	pressContinue: boolean?,
	-- Called on every tick before the bot acts, for tests that poke at the Director.
	meddle: ((sim: Sim) -> ())?,
}

local STOP = { stop = true }

-- The rules, applied from what's on screen and what's visible in the world.
local function visibleCall(state: View.State, facts: Facts): Types.Decision
	local view = state.passenger :: View.PassengerView
	local ticket = view.ticket
	local ok = ticket.date == state.date and ticket.destination == Content.Destination
	if state.night >= 2 then
		ok = ok and ticket.stamp == "gull" and not facts.wet
	end
	if state.night >= 3 then
		ok = ok and table.find(state.manifest or {}, ticket.name) ~= nil and facts.breath
	end
	if state.night >= 4 then
		ok = ok and facts.shadow
	end
	if state.night >= 5 then
		ok = ok and string.find(view.line, "{name}", 1, true) == nil
	end
	return if ok then "board" else "deny"
end

local function perfect(state: View.State, facts: Facts): Types.Decision?
	return visibleCall(state, facts)
end

local function act(sim: Sim)
	if sim.policy.meddle then
		sim.policy.meddle(sim)
	end
	local state = sim.state
	if state == nil then
		return
	end
	local director = sim.director
	if state.ready and sim.policy.pressContinue ~= false then
		for _, actor in sim.pressers do
			Director.action(director, actor, "continue", nil)
		end
	end
	local view = state.passenger
	local facts = sim.atWindow
	local decide = sim.policy.decide
	if state.phase == "window" and view and facts and decide and not sim.decided[view.id] then
		if sim.time - sim.arrivedAt < 3 then
			return -- read the ticket first
		end
		if sim.policy.takePages and view.hasPage then
			Director.action(director, sim.actors[1], "page", view.id)
		end
		local call = decide(state, facts, sim)
		if call then
			sim.decided[view.id] = true
			Director.action(director, sim.actors[1], call, view.id)
		end
	end
end

local function newSim(seed: number, policy: Policy, actors: { number }?, pressers: { number }?, limit: number?): Sim
	local sim = {} :: Sim
	sim.time = 0
	sim.limit = limit or 20000
	sim.actors = actors or { 1 }
	sim.pressers = pressers or sim.actors
	sim.policy = policy
	sim.state = nil
	sim.states = {}
	sim.fx = {}
	sim.log = {}
	sim.queue = {}
	sim.night = 0
	sim.atWindow = nil
	sim.arrivedAt = 0
	sim.decided = {}
	sim.sentOff = {}
	sim.recorded = {}
	sim.scenes = {}
	sim.flood = false
	sim.lanterns = 0
	sim.ferryLoad = 0

	local clock: Director.Clock = {
		now = function()
			return sim.time
		end,
		sleep = function(seconds: number)
			sim.time += seconds
			if sim.time > sim.limit then
				error(STOP)
			end
			act(sim)
		end,
	}

	local stage: Director.Stage = {
		actors = function()
			return sim.actors
		end,
		newSeed = function()
			return seed
		end,
		broadcast = function(state: View.State)
			sim.state = state
			sim.night = state.night
			table.insert(sim.states, state)
		end,
		fx = function(fx: View.Fx)
			table.insert(sim.fx, { kind = fx.kind, text = fx.text, night = sim.night })
		end,
		recordEnding = function(ending: string, secret: boolean)
			table.insert(sim.recorded, { ending = ending, secret = secret })
		end,
		resetWorld = function()
			table.insert(sim.log, "resetWorld")
		end,
		setLanterns = function(lit: number)
			sim.lanterns = lit
		end,
		setFerryLoad = function(drownedAboard: number)
			sim.ferryLoad = drownedAboard
		end,
		setFlood = function(on: boolean)
			sim.flood = on
			table.insert(sim.log, `flood {on}`)
		end,
		endingScene = function(ending: string)
			table.insert(sim.scenes, ending)
		end,
		beginQueue = function(passengers: { Types.Passenger })
			sim.queue = passengers
			sim.atWindow = nil
			table.insert(sim.log, "beginQueue")
		end,
		callToWindow = function(index: number)
			table.insert(sim.log, `call {index}`)
			local passenger = sim.queue[index]
			assert(passenger, `callToWindow({index}) with no such passenger`)
			sim.atWindow = { wet = passenger.wet, breath = passenger.breath, shadow = passenger.shadow }
			sim.arrivedAt = sim.time
			-- Walking up to the window takes a moment.
			sim.time += 1.5
		end,
		sendOff = function(index: number, exit: Director.Exit)
			table.insert(sim.log, `sendOff {index} {exit}`)
			table.insert(sim.sentOff, { night = sim.night, passenger = sim.queue[index], exit = exit })
			sim.atWindow = nil
		end,
		removePage = function(index: number)
			table.insert(sim.log, `removePage {index}`)
		end,
		clearQueue = function()
			table.insert(sim.log, "clearQueue")
			sim.atWindow = nil
		end,
	}

	sim.director = Director.new(clock, stage)
	return sim
end

-- Plays until the ending (returns it) or until the simulated time limit (returns nil).
local function play(sim: Sim): Run.EndingResult?
	local ok, result = pcall(Director.playRun, sim.director)
	if ok then
		return result
	end
	if result ~= STOP then
		error(result, 0)
	end
	return nil
end

local function fxOf(sim: Sim, kind: string): { { kind: string, text: string?, night: number } }
	local list = {}
	for _, fx in sim.fx do
		if fx.kind == kind then
			table.insert(list, fx)
		end
	end
	return list
end

local function sawPhase(sim: Sim, phase: string): boolean
	for _, state in sim.states do
		if state.phase == phase then
			return true
		end
	end
	return false
end

local function indexOf(list: { string }, value: string): number?
	return table.find(list, value)
end

T.test("a perfect clerk finishes clean using only the screen and the world", function()
	for seed = 1, 60 do
		local sim = newSim(seed, { decide = perfect })
		local ending = play(sim)
		assert(ending, `seed {seed}: run did not finish`)
		T.equal(ending.id, "CLEAN_SHIFT", `seed {seed}`)
		T.expect(not ending.secret, "no pages taken")
		T.equal(#fxOf(sim, "lanternOut"), 0, `seed {seed}: no lantern lost`)
		T.expect(not sawPhase(sim, "failed"), `seed {seed}: never failed`)
		T.equal(#sim.recorded, 1)
		T.equal(sim.recorded[1].ending, "CLEAN_SHIFT")
		T.equal(sim.scenes[1], "CLEAN_SHIFT")
		T.equal(sim.lanterns, Content.LanternsPerNight)
		T.equal(sim.ferryLoad, 0)
	end
end)

T.test("every passenger is called in order and sent the right way", function()
	for seed = 1, 30 do
		local sim = newSim(seed, { decide = perfect })
		play(sim)
		local calls = 0
		local expected = 1
		for _, line in sim.log do
			if line == "beginQueue" then
				expected = 1
			elseif string.sub(line, 1, 5) == "call " then
				T.equal(line, `call {expected}`, `seed {seed}`)
				expected += 1
				calls += 1
			end
		end
		T.equal(#sim.sentOff, calls, "each called passenger is sent off once")
		for _, sent in sim.sentOff do
			local p = sent.passenger
			local want: Director.Exit = if p.kind == "drowned"
				then "water"
				elseif p.kind == "mara" then "away"
				else "board"
			if p.role == "error" then
				want = "away"
			end
			T.equal(sent.exit, want, `{p.role} {p.ticket.name}`)
		end
	end
end)

T.test("the screen never says who is drowned", function()
	local allowed: { [string]: boolean } = {}
	for _, key in
		{
			-- State
			"phase",
			"night",
			"finalNight",
			"date",
			"clock",
			"lanterns",
			"maxLanterns",
			"rules",
			"manifest",
			"passenger",
			"waiting",
			"ledger",
			"title",
			"text",
			"summary",
			"ending",
			"ready",
			"phaseEnds",
			-- PassengerView / TicketView
			"id",
			"ticket",
			"line",
			"hasPage",
			"deadline",
			"name",
			"destination",
			"stamp",
			-- RuleLine / SummaryRow / LedgerPage / EndingView / Ready
			"isNew",
			"call",
			"correct",
			"note",
			"secretTitle",
			"secretText",
			"count",
			"total",
		}
	do
		allowed[key] = true
	end

	local function walk(value: any, path: string)
		if type(value) ~= "table" then
			return
		end
		for key, child in value do
			if type(key) == "string" then
				T.expect(allowed[key] == true, `unexpected key {path}.{key}`)
			end
			walk(child, `{path}.{key}`)
		end
	end

	for seed = 1, 10 do
		local sim = newSim(seed, { decide = perfect })
		play(sim)
		for _, state in sim.states do
			walk(state, "state")
			T.expect(state.passenger == nil or state.phase == "window", "passenger only at the window")
			T.expect(state.summary == nil or state.phase == "summary", "summary only in the summary")
			T.expect(state.ending == nil or state.phase == "ending", "ending only at the end")
			T.equal(#state.ledger, 0, "no pages were taken, so none are shown")
		end
	end
end)

T.test("the rules card grows each night and shows tonight's date", function()
	local sim = newSim(4, { decide = perfect })
	play(sim)
	local counts = { 2, 4, 6, 7, 8 }
	for _, state in sim.states do
		if state.phase == "window" then
			T.equal(#state.rules, counts[state.night], `night {state.night}`)
			T.expect(string.find(state.rules[1].text, state.date, 1, true) ~= nil, "date rule shows the date")
			T.equal(state.manifest ~= nil, state.night >= 3, "manifest from night 3")
		end
	end
end)

T.test("an idle clerk: every window closes, lanterns go out, the tide comes in", function()
	local sim = newSim(2, { pressContinue = false }, nil, nil, 900)
	T.equal(play(sim), nil, "an idle clerk never reaches an ending")

	-- Nobody pressed Continue, so the first intro ran its full length.
	local firstCall = indexOf(sim.log, "call 1")
	T.expect(firstCall ~= nil, "a passenger came to the window")
	local firstWindow: View.State? = nil
	for _, state in sim.states do
		if state.phase == "window" then
			firstWindow = state
			break
		end
	end
	assert(firstWindow and firstWindow.passenger, "saw a window state")
	T.expect(firstWindow.passenger.deadline >= Config.IntroTime + Config.DecisionTime, "intro waited out its timer")

	local calls = fxOf(sim, "call")
	T.expect(#calls >= 3, "several windows closed")
	for _, fx in calls do
		T.equal(fx.text, "WINDOW CLOSED")
	end
	T.expect(#fxOf(sim, "lanternOut") >= 3, "turning the living away costs lanterns")
	T.expect(sawPhase(sim, "failed"), "the night failed")
	T.expect(indexOf(sim.log, "flood true") ~= nil and indexOf(sim.log, "flood false") ~= nil, "flood rose and fell")

	local retried = false
	local sawFailed = false
	for _, state in sim.states do
		if state.phase == "failed" then
			sawFailed = true
			T.equal(state.title, Content.NightFailed.title)
		elseif sawFailed and state.phase == "intro" then
			retried = true
			T.equal(state.text, Content.RetryRadio, "Pike's retry line")
			T.equal(state.night, 1, "same night again")
			T.equal(state.lanterns, Content.LanternsPerNight, "lanterns relit")
			break
		end
	end
	T.expect(retried, "the night was taken again")
end)

T.test("letting Mara board on the last night sends her home", function()
	for seed = 1, 20 do
		local sim = newSim(seed, {
			decide = function(state, facts)
				local view = state.passenger :: View.PassengerView
				if view.ticket.name == Content.Mara.name and state.night == Content.FinalNight then
					return "board"
				end
				return visibleCall(state, facts)
			end,
		})
		local ending = play(sim)
		assert(ending, "finished")
		T.equal(ending.id, "MARA_HOME", `seed {seed}`)
		T.equal(sim.scenes[1], "MARA_HOME")
		T.equal(#fxOf(sim, "lanternOut"), 0, "Mara never costs a lantern")
		local said = fxOf(sim, "say")
		T.equal(said[#said].text, Content.Mara.home)
		local last = sim.sentOff[#sim.sentOff]
		T.equal(last.passenger.kind, "mara", "Mara is last on the final night")
		T.equal(last.exit, "board", "she walks up the gangway")
	end
end)

T.test("saying yes to Mara early costs nothing; she says not yet", function()
	local sim = newSim(9, {
		decide = function(state, facts)
			local view = state.passenger :: View.PassengerView
			if view.ticket.name == Content.Mara.name then
				return if state.night < Content.FinalNight then "board" else "deny"
			end
			return visibleCall(state, facts)
		end,
	})
	local ending = play(sim)
	assert(ending, "finished")
	T.equal(ending.id, "CLEAN_SHIFT")
	local said = fxOf(sim, "say")
	T.equal(#said, Content.FinalNight)
	for i = 1, Content.FinalNight - 1 do
		T.equal(said[i].text, Content.Mara.notYet)
	end
	T.equal(said[Content.FinalNight].text, Content.Mara.wait)
	T.equal(#fxOf(sim, "lanternOut"), 0)
	for _, sent in sim.sentOff do
		if sent.passenger.kind == "mara" then
			T.equal(sent.exit, "away", "she goes back into the fog")
		end
	end
end)

T.test("a Mara whose window closes on the last night waits another year", function()
	local sim = newSim(12, {
		decide = function(state, facts)
			local view = state.passenger :: View.PassengerView
			if view.ticket.name == Content.Mara.name and state.night == Content.FinalNight then
				return nil
			end
			return visibleCall(state, facts)
		end,
	})
	local ending = play(sim)
	assert(ending, "finished")
	T.equal(ending.id, "CLEAN_SHIFT")
	local said = fxOf(sim, "say")
	T.equal(said[#said].text, Content.Mara.wait)
	local calls = fxOf(sim, "call")
	T.equal(calls[#calls].text, "WINDOW CLOSED")
end)

T.test("letting one of the drowned aboard sinks the Petrel lower", function()
	for seed = 1, 20 do
		local boarded = false
		local sim = newSim(seed, {
			decide = function(state, facts)
				-- Night 1: the drowned drip seawater. Wave the first one through.
				if not boarded and state.night == 1 and facts.wet then
					boarded = true
					return "board"
				end
				return visibleCall(state, facts)
			end,
		})
		local ending = play(sim)
		assert(ending, "finished")
		T.expect(boarded, "found a drowned passenger on night 1")
		T.equal(ending.id, "LOW_IN_THE_WATER", `seed {seed}`)
		T.equal(sim.ferryLoad, 1)
		local lost = fxOf(sim, "lanternOut")
		T.equal(#lost, 1)
		local text = lost[1].text :: string
		T.expect(string.find(text, Content.Notes.drownedBoarded, 1, true) ~= nil, text)
	end
end)

T.test("all five ledger pages unlock the epilogue", function()
	for seed = 1, 20 do
		local sim = newSim(seed, { decide = perfect, takePages = true })
		local ending = play(sim)
		assert(ending, "finished")
		T.expect(ending.secret, `seed {seed}`)
		T.equal(sim.recorded[1].secret, true)
		local pages = fxOf(sim, "page")
		T.equal(#pages, Content.FinalNight)
		for i, fx in pages do
			T.equal(fx.text, Content.Ledger[i], "page text in night order")
			T.equal(fx.night, i)
		end
		local removed = 0
		for _, line in sim.log do
			if string.sub(line, 1, 10) == "removePage" then
				removed += 1
			end
		end
		T.equal(removed, Content.FinalNight)

		local final: View.State? = nil
		for _, state in sim.states do
			if state.phase == "ending" then
				final = state
			end
		end
		assert(final and final.ending, "ending state")
		T.equal(final.ending.secretTitle, Content.Endings.THE_LEDGER.title)
		T.equal(#final.ledger, Content.FinalNight)
	end
end)

T.test("a taken page leaves the ticket at once", function()
	local sim = newSim(21, { decide = perfect, takePages = true })
	play(sim)
	local sawPage = false
	for i, state in sim.states do
		local view = state.passenger
		if view and view.hasPage then
			sawPage = true
			local after = sim.states[i + 1]
			T.expect(after.passenger ~= nil and not after.passenger.hasPage, "next broadcast drops the page")
			T.equal(#after.ledger, #state.ledger + 1)
		end
	end
	T.expect(sawPage, "some ticket carried a page")
end)

T.test("out-of-place actions change nothing", function()
	for seed = 1, 15 do
		local function meddle(s: Sim)
			local director = s.director
			local state = s.state
			if state == nil then
				return
			end
			-- Junk that must be ignored in every phase.
			Director.action(director, 1, "explode", 1)
			Director.action(director, 1, "board", "1")
			Director.action(director, 1, "deny", nil)
			Director.action(director, 1, "page", {})
			if state.phase ~= "window" then
				Director.action(director, 1, "board", 1)
				Director.action(director, 1, "page", 1)
				T.expect(director.pending == nil, "no call outside the window")
			elseif state.passenger then
				Director.action(director, 1, "board", state.passenger.id + 1000)
				Director.action(director, 1, "page", state.passenger.id + 1000)
				T.expect(director.pending == nil, "no call for another passenger")
			end
		end
		local sim = newSim(seed, {
			decide = function(state, facts, s)
				local call = visibleCall(state, facts)
				local view = state.passenger :: View.PassengerView
				Director.action(s.director, 1, call, view.id)
				-- A second, opposite call from a friend is too late.
				Director.action(s.director, 2, if call == "board" then "deny" else "board", view.id)
				return nil
			end,
			meddle = meddle,
		})
		local ending = play(sim)
		assert(ending, "finished")
		T.equal(ending.id, "CLEAN_SHIFT", `seed {seed}`)
		T.equal(#fxOf(sim, "lanternOut"), 0)
		T.equal(#fxOf(sim, "page"), 0, "no page from junk")
	end
end)

T.test("co-op: Continue waits for every player, or the timer", function()
	local both = newSim(3, { decide = perfect }, { 1, 2 }, { 1, 2 })
	play(both)
	local soloPress = newSim(3, { decide = perfect }, { 1, 2 }, { 1 })
	play(soloPress)

	local function firstWindowDeadline(sim: Sim): number
		for _, state in sim.states do
			if state.phase == "window" and state.passenger then
				return state.passenger.deadline
			end
		end
		error("no window")
	end
	T.expect(firstWindowDeadline(both) < 5 + Config.DecisionTime, "everyone pressed: intro skipped")
	T.expect(firstWindowDeadline(soloPress) >= Config.IntroTime + Config.DecisionTime, "one of two pressed: timer ran")

	local sawHalf = false
	for _, state in soloPress.states do
		local ready = state.ready
		if ready and ready.count == 1 and ready.total == 2 then
			sawHalf = true
		end
	end
	T.expect(sawHalf, "the screen shows 1 of 2 ready")
end)

T.test("the radio checks in once, halfway through each night", function()
	local sim = newSim(6, { decide = perfect })
	play(sim)
	local radio = fxOf(sim, "radio")
	T.equal(#radio, Content.FinalNight)
	for i, fx in radio do
		T.equal(fx.text, Content.Nights[i].radioMid)
		T.equal(fx.night, i)
	end
end)

T.test("every call in the summary is explained", function()
	local sim = newSim(14, { decide = perfect })
	play(sim)
	local rows = 0
	for _, state in sim.states do
		if state.phase == "summary" and state.summary then
			for _, row in state.summary do
				rows += 1
				T.expect(row.correct, `{row.name} {row.call}`)
				T.expect(#row.note > 0, `note for {row.name}`)
			end
		end
	end
	T.expect(rows > 0, "summaries shown")
end)

T.test("phases run in order", function()
	local sim = newSim(8, { decide = perfect })
	play(sim)
	local phases: { string } = {}
	for _, state in sim.states do
		if phases[#phases] ~= state.phase then
			table.insert(phases, state.phase)
		end
	end
	T.equal(phases[1], "intro")
	T.equal(phases[#phases], "ending")
	for i = 2, #phases do
		local before, now = phases[i - 1], phases[i]
		local ok = (before == "intro" and now == "queue")
			or (before == "queue" and (now == "window" or now == "summary"))
			or (before == "window" and now == "queue")
			or (before == "summary" and (now == "intro" or now == "ending"))
		T.expect(ok, `{before} -> {now}`)
	end
end)

return nil
