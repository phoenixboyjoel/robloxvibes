--!strict
local Content = require("../ServerScriptService/Shift/Content")
local Rules = require("../ServerScriptService/Shift/Rules")
local Run = require("../ServerScriptService/Shift/Run")
local Types = require("../ServerScriptService/Shift/Types")
local T = require("./TestLib")

T.suite("Run")

type Policy = (Types.Passenger, Types.Night, number) -> Types.Decision

local function correctCall(p: Types.Passenger, night: Types.Night): Types.Decision
	return if Rules.shouldBoard(p, night) then "board" else "deny"
end

-- Plays a whole run. `policy` picks each call; pages are taken when `takePages`.
local function play(seed: number, policy: Policy, takePages: boolean): (Run.Run, Run.EndingResult, number)
	local run = Run.new(seed)
	local failures = 0
	Run.beginNight(run)
	while true do
		local p = Run.nextPassenger(run)
		if p == nil then
			if Run.finishNight(run) == "ending" then
				return run, Run.ending(run), failures
			end
			Run.beginNight(run)
		else
			if takePages and p.hasLedgerPage then
				T.equal(Run.takeLedgerPage(run, p.id), run.night)
			end
			local night = run.current :: Types.Night
			local outcome = Run.decide(run, p.id, policy(p, night, run.night), false)
			assert(outcome, "decision accepted")
			if Run.isNightFailed(run) then
				failures += 1
				assert(failures < 200, "stuck failing")
				Run.restartNight(run)
			end
		end
	end
end

T.test("perfect play never loses a lantern and ends clean", function()
	for seed = 1, 300 do
		local run, ending, failures = play(seed, function(p, night)
			return correctCall(p, night)
		end, false)
		T.equal(failures, 0, `seed {seed}`)
		T.equal(run.lanterns, Content.LanternsPerNight)
		T.equal(ending.id, "CLEAN_SHIFT")
		T.expect(not ending.secret, "no pages taken")
	end
end)

T.test("all five pages unlock the secret epilogue", function()
	for seed = 1, 100 do
		local run, ending = play(seed, function(p, night)
			return correctCall(p, night)
		end, true)
		T.equal(Run.ledgerCount(run), 5)
		T.expect(ending.secret, `seed {seed}`)
	end
end)

T.test("letting Mara board on the last night sends her home", function()
	for seed = 1, 100 do
		local _, ending = play(seed, function(p, night, number)
			if p.kind == "mara" and number == Content.FinalNight then
				return "board"
			end
			return correctCall(p, night)
		end, false)
		T.equal(ending.id, "MARA_HOME", `seed {seed}`)
	end
end)

T.test("letting Mara board early costs nothing and she says not yet", function()
	local run = Run.new(5)
	Run.beginNight(run)
	while true do
		local p = Run.nextPassenger(run)
		if p == nil then
			break
		end
		local night = run.current :: Types.Night
		local call: Types.Decision = if p.kind == "mara" then "board" else correctCall(p, night)
		local outcome = Run.decide(run, p.id, call, false)
		assert(outcome)
		if p.kind == "mara" then
			T.equal(outcome.special, "mara_not_yet")
			T.expect(not outcome.lanternLost, "no lantern for Mara")
		end
	end
	T.equal(run.lanterns, 3)
	T.equal(run.maraKindness, 1)
end)

T.test("boarding one drowned passenger leads to Low in the Water", function()
	for seed = 1, 100 do
		local boardedOne = false
		local _, ending = play(seed, function(p, night)
			if p.kind == "drowned" and not boardedOne then
				boardedOne = true
				return "board"
			end
			return correctCall(p, night)
		end, false)
		T.equal(ending.id, "LOW_IN_THE_WATER", `seed {seed}`)
	end
end)

T.test("three mistakes fail the night and a retry restores the ending state", function()
	local run = Run.new(11)
	Run.beginNight(run)
	local lost = 0
	while not Run.isNightFailed(run) do
		local p = Run.nextPassenger(run)
		assert(p, "ran out of passengers before failing")
		local night = run.current :: Types.Night
		-- Always make the wrong call (Mara aside, who can't cost a lantern).
		local wrong: Types.Decision = if Rules.shouldBoard(p, night) then "deny" else "board"
		local outcome = Run.decide(run, p.id, wrong, false)
		assert(outcome)
		if outcome.lanternLost then
			lost += 1
		end
	end
	T.equal(lost, 3)
	T.expect(run.drownedBoarded >= 0, "tracked")
	Run.restartNight(run)
	T.equal(run.drownedBoarded, 0, "restart restores the night-start snapshot")
	T.equal(run.lanterns, 3)
	T.equal(run.attempt, 1)
end)

T.test("stale or duplicate decisions are rejected", function()
	local run = Run.new(3)
	Run.beginNight(run)
	local p = Run.nextPassenger(run)
	assert(p)
	T.expect(Run.decide(run, p.id + 999, "board", false) == nil, "wrong id rejected")
	T.expect(Run.decide(run, p.id, "board", false) ~= nil, "first decision accepted")
	T.expect(Run.decide(run, p.id, "deny", false) == nil, "second decision rejected")
end)

T.test("the ledger page can only be taken from its carrier, once", function()
	local run = Run.new(8)
	Run.beginNight(run)
	local took = 0
	while true do
		local p = Run.nextPassenger(run)
		if p == nil then
			break
		end
		local result = Run.takeLedgerPage(run, p.id)
		if p.hasLedgerPage then
			T.equal(result, 1)
			T.expect(Run.takeLedgerPage(run, p.id) == nil, "only once")
			took += 1
		else
			T.expect(result == nil, "not from a non-carrier")
		end
		local night = run.current :: Types.Night
		Run.decide(run, p.id, correctCall(p, night), false)
	end
	T.equal(took, 1)
end)

return nil
