--!strict
--[[
	A five-night run as a plain state machine: no Roblox APIs, no timers.
	ShiftService drives it (walking passengers, waiting for decisions) and the
	tests drive it directly.

	Lifecycle:
		local run = Run.new(seed)
		Run.beginNight(run)
		while Run.nextPassenger(run) do
			Run.decide(run, id, "board" | "deny", timedOut)  -- exactly once per passenger
			if Run.isNightFailed(run) then Run.restartNight(run) ... end
		end
		Run.finishNight(run) --> "next" | "ending"
]]

local Content = require("./Content")
local Generator = require("./Generator")
local Rng = require("./Rng")
local Rules = require("./Rules")
local Types = require("./Types")

export type EndingResult = {
	id: string,
	secret: boolean,
}

export type Run = {
	seed: number,
	night: number,
	lanterns: number,
	attempt: number,
	drownedBoarded: number,
	maraKindness: number,
	maraBoardedFinal: boolean,
	ledger: { boolean },
	pools: Generator.Pools,
	current: Types.Night?,
	index: number,
	decided: boolean,
	pageTaken: boolean,
	outcomes: { Types.Outcome },
	snapshot: { drownedBoarded: number, maraKindness: number },
	nextId: number,
}

local Run = {}

function Run.new(seed: number): Run
	local ledger = {}
	for i = 1, Content.FinalNight do
		ledger[i] = false
	end
	return {
		seed = seed,
		night = 1,
		lanterns = Content.LanternsPerNight,
		attempt = 0,
		drownedBoarded = 0,
		maraKindness = 0,
		maraBoardedFinal = false,
		ledger = ledger,
		pools = Generator.newPools(Rng.new(seed)),
		current = nil,
		index = 0,
		decided = true,
		pageTaken = false,
		outcomes = {},
		snapshot = { drownedBoarded = 0, maraKindness = 0 },
		nextId = 1,
	}
end

-- Generates the current night's queue and resets the per-night state.
function Run.beginNight(run: Run): Types.Night
	local rng = Rng.new(run.seed + run.night * 7919 + run.attempt * 104729)
	local night = Generator.buildNight(rng, run.night, run.pools)
	for _, passenger in night.passengers do
		passenger.id = run.nextId
		run.nextId += 1
	end
	run.current = night
	run.lanterns = Content.LanternsPerNight
	run.index = 0
	run.decided = true
	run.pageTaken = false
	run.outcomes = {}
	run.snapshot = { drownedBoarded = run.drownedBoarded, maraKindness = run.maraKindness }
	return night
end

function Run.currentPassenger(run: Run): Types.Passenger?
	local night = run.current
	if night == nil then
		return nil
	end
	return night.passengers[run.index]
end

-- Moves to the next passenger in the queue, or returns nil when the night is over.
function Run.nextPassenger(run: Run): Types.Passenger?
	local night = run.current
	assert(night, "Run.nextPassenger before beginNight")
	assert(run.decided, "Run.nextPassenger before the current passenger was decided")
	run.index += 1
	local passenger = night.passengers[run.index]
	run.decided = passenger == nil
	return passenger
end

function Run.remaining(run: Run): number
	local night = run.current
	if night == nil then
		return 0
	end
	return math.max(#night.passengers - run.index, 0)
end

-- Applies a decision for the passenger at the window. Returns nil if the
-- decision is stale (wrong passenger, or already decided).
function Run.decide(run: Run, passengerId: number, decision: Types.Decision, timedOut: boolean): Types.Outcome?
	local night = run.current
	local passenger = Run.currentPassenger(run)
	if night == nil or passenger == nil or run.decided or passenger.id ~= passengerId then
		return nil
	end
	run.decided = true

	local broken = Rules.broken(passenger, night)
	local outcome: Types.Outcome = {
		passengerId = passenger.id,
		name = passenger.ticket.name,
		kind = passenger.kind,
		role = passenger.role,
		decision = decision,
		timedOut = timedOut,
		correct = true,
		lanternLost = false,
		special = nil,
		broken = broken,
	}

	if passenger.kind == "mara" then
		-- Mara never costs a lantern. Letting her board is a story choice.
		if decision == "board" then
			if run.night >= Content.FinalNight then
				outcome.special = "mara_home"
				run.maraBoardedFinal = true
			else
				outcome.special = "mara_not_yet"
				run.maraKindness += 1
			end
		elseif run.night >= Content.FinalNight then
			outcome.special = "mara_wait"
		end
	else
		local shouldBoard = #broken == 0
		outcome.correct = (decision == "board") == shouldBoard
		if not outcome.correct then
			outcome.lanternLost = true
			run.lanterns = math.max(run.lanterns - 1, 0)
		end
		if decision == "board" and passenger.kind == "drowned" then
			run.drownedBoarded += 1
		end
	end

	table.insert(run.outcomes, outcome)
	return outcome
end

-- The page is taken from whoever carries it while they stand at the window.
function Run.takeLedgerPage(run: Run, passengerId: number): number?
	local passenger = Run.currentPassenger(run)
	if passenger == nil or passenger.id ~= passengerId or not passenger.hasLedgerPage or run.pageTaken then
		return nil
	end
	run.pageTaken = true
	run.ledger[run.night] = true
	return run.night
end

function Run.ledgerCount(run: Run): number
	local count = 0
	for _, found in run.ledger do
		if found then
			count += 1
		end
	end
	return count
end

function Run.isNightFailed(run: Run): boolean
	return run.lanterns <= 0
end

-- Retry the same night with a fresh queue. Ledger pages already found are kept.
function Run.restartNight(run: Run): Types.Night
	run.drownedBoarded = run.snapshot.drownedBoarded
	run.maraKindness = run.snapshot.maraKindness
	run.attempt += 1
	return Run.beginNight(run)
end

function Run.finishNight(run: Run): "next" | "ending"
	assert(not Run.isNightFailed(run), "Run.finishNight on a failed night")
	if run.night >= Content.FinalNight then
		return "ending"
	end
	run.night += 1
	run.attempt = 0
	return "next"
end

function Run.ending(run: Run): EndingResult
	local id
	if run.drownedBoarded > 0 then
		id = "LOW_IN_THE_WATER"
	elseif run.maraBoardedFinal then
		id = "MARA_HOME"
	else
		id = "CLEAN_SHIFT"
	end
	return { id = id, secret = Run.ledgerCount(run) == Content.FinalNight }
end

return Run
