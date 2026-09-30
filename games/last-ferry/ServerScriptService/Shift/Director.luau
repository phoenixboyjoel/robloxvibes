--!strict
--[[
	Director: runs the shift. Intro, passengers one at a time at the window,
	the night summary, a retry when the tide comes in, and the ending.

	It decides what happens and when, but never touches Roblox itself. Everything
	it does to the world or the players goes through a Stage, and all waiting goes
	through a Clock. ShiftService passes the real ones (parts, tweens, remotes,
	server time). tests/Director.spec.luau passes fakes with a simulated clock and
	plays whole runs, timeouts and retries in milliseconds.

	Players act through Director.action, which checks everything: the phase, the
	passenger id, and whether the thing can still be done.
]]

local Config = require("../../ReplicatedStorage/Shared/Config")
local View = require("../../ReplicatedStorage/Shared/Types")
local Content = require("./Content")
local Generator = require("./Generator")
local Rules = require("./Rules")
local Run = require("./Run")
local Types = require("./Types")

export type Exit = "board" | "away" | "water"

export type Clock = {
	now: () -> number,
	sleep: (seconds: number) -> (),
}

export type Stage = {
	-- Ids of the players in the server. Any of them can make the call.
	actors: () -> { number },
	newSeed: () -> number,
	broadcast: (state: View.State) -> (),
	fx: (fx: View.Fx) -> (),
	recordEnding: (ending: string, secret: boolean) -> (),

	resetWorld: () -> (),
	setLanterns: (lit: number) -> (),
	setFerryLoad: (drownedAboard: number) -> (),
	setFlood: (on: boolean) -> (),
	endingScene: (ending: string) -> (),

	-- Passengers are addressed by their place in tonight's queue.
	beginQueue: (passengers: { Types.Passenger }) -> (),
	callToWindow: (index: number) -> (), -- yields until they are standing at the window
	sendOff: (index: number, exit: Exit) -> (),
	removePage: (index: number) -> (),
	clearQueue: () -> (),
}

export type Director = {
	clock: Clock,
	stage: Stage,
	run: Run.Run?,
	phase: View.Phase,
	phaseEnds: number?,
	title: string?,
	text: string?,
	summary: { View.SummaryRow }?,
	ending: View.EndingView?,
	skippable: boolean,
	ready: { [number]: boolean },
	pending: Types.Decision?,
	deadline: number,
}

local POLL = 0.1

local MARA_REPLIES: { [string]: string } = {
	mara_not_yet = Content.Mara.notYet,
	mara_wait = Content.Mara.wait,
	mara_home = Content.Mara.home,
}

local Director = {}

function Director.new(clock: Clock, stage: Stage): Director
	return {
		clock = clock,
		stage = stage,
		run = nil,
		phase = "waiting",
		phaseEnds = nil,
		title = nil,
		text = nil,
		summary = nil,
		ending = nil,
		skippable = false,
		ready = {},
		pending = nil,
		deadline = 0,
	}
end

-- What went wrong or right with a call, for the summary and the lost-lantern message.
function Director.note(outcome: Types.Outcome): string
	local notes = Content.Notes
	local reason = if #outcome.broken > 0 then Content.Reasons[outcome.broken[1]] .. "." else ""

	if outcome.kind == "mara" then
		if outcome.special == "mara_not_yet" then
			return notes.maraNotYet
		elseif outcome.special == "mara_home" then
			return notes.maraHome
		elseif outcome.special == "mara_wait" then
			return notes.maraWait
		end
		return notes.maraTurnedAway
	elseif outcome.kind == "drowned" then
		local who = if outcome.role == "anna" then notes.anna .. " " else ""
		local fate = if outcome.decision == "board" then notes.drownedBoarded else notes.drownedTurnedAway
		return `{who}{fate} {reason}`
	elseif outcome.decision == "board" then
		return if outcome.correct then notes.aliveBoarded else `{notes.errorBoarded} {reason}`
	end
	return if outcome.correct then reason else notes.aliveTurnedAway
end

function Director.callLabel(outcome: Types.Outcome): string
	if outcome.timedOut then
		return "WINDOW CLOSED"
	end
	return if outcome.decision == "board" then "BOARDED" else "TURNED AWAY"
end

local function exitFor(passenger: Types.Passenger, outcome: Types.Outcome): Exit
	if outcome.decision == "board" and outcome.special ~= "mara_not_yet" then
		return "board"
	elseif passenger.kind == "drowned" then
		return "water"
	end
	return "away"
end

local function readyCount(self: Director): View.Ready?
	if not self.skippable then
		return nil
	end
	local actors = self.stage.actors()
	local count = 0
	for _, id in actors do
		if self.ready[id] then
			count += 1
		end
	end
	return { count = count, total = #actors }
end

-- The screen state every player sees. Built only from what a clerk could know:
-- the ticket, the words, the rules card and the manifest. Never the passenger's kind.
function Director.state(self: Director): View.State
	local state: View.State = {
		phase = self.phase,
		night = 0,
		finalNight = Content.FinalNight,
		date = "",
		clock = "",
		lanterns = Content.LanternsPerNight,
		maxLanterns = Content.LanternsPerNight,
		rules = {},
		manifest = nil,
		passenger = nil,
		waiting = 0,
		ledger = {},
		title = self.title,
		text = self.text,
		summary = self.summary,
		ending = self.ending,
		ready = readyCount(self),
		phaseEnds = self.phaseEnds,
	}

	local run = self.run
	local night = if run then run.current else nil
	if run == nil or night == nil then
		return state
	end

	state.night = run.night
	state.date = night.date
	state.clock = if self.phase == "summary" or self.phase == "ending"
		then "5:00 AM"
		else Generator.clock(math.max(run.index, 1), #night.passengers)
	state.lanterns = run.lanterns
	state.rules = Rules.card(run.night, night.date)
	state.manifest = if night.manifest then table.clone(night.manifest) else nil
	state.waiting = Run.remaining(run)
	for number, found in run.ledger do
		if found then
			table.insert(state.ledger, { night = number, text = Content.Ledger[number] })
		end
	end

	local passenger = Run.currentPassenger(run)
	if self.phase == "window" and passenger then
		state.passenger = {
			id = passenger.id,
			ticket = {
				name = passenger.ticket.name,
				destination = passenger.ticket.destination,
				date = passenger.ticket.date,
				stamp = passenger.ticket.stamp,
			},
			line = passenger.line,
			hasPage = passenger.hasLedgerPage and not run.pageTaken,
			deadline = self.deadline,
		}
	end
	return state
end

local function broadcast(self: Director)
	self.stage.broadcast(Director.state(self))
end

-- Polls until `done` returns true (true) or the deadline passes (false).
local function waitUntil(self: Director, deadline: number, done: () -> boolean): boolean
	while not done() do
		if self.clock.now() >= deadline then
			return false
		end
		self.clock.sleep(POLL)
	end
	return true
end

local function everyoneReady(self: Director): boolean
	local actors = self.stage.actors()
	if #actors == 0 then
		return false
	end
	for _, id in actors do
		if not self.ready[id] then
			return false
		end
	end
	return true
end

-- Shows the current phase for `seconds`, or until every player presses Continue.
local function hold(self: Director, seconds: number, skippable: boolean)
	local deadline = self.clock.now() + seconds
	table.clear(self.ready)
	self.skippable = skippable
	self.phaseEnds = deadline
	broadcast(self)
	waitUntil(self, deadline, function()
		return skippable and everyoneReady(self)
	end)
	self.skippable = false
	self.phaseEnds = nil
end

-- A player pressed something. Anything out of place is ignored.
function Director.action(self: Director, actor: number, kind: string, value: unknown)
	local run = self.run
	if run == nil then
		return
	end
	if kind == "board" or kind == "deny" then
		if self.phase ~= "window" or self.pending ~= nil then
			return
		end
		local passenger = Run.currentPassenger(run)
		if passenger and value == passenger.id then
			self.pending = if kind == "board" then "board" else "deny"
		end
	elseif kind == "page" then
		if self.phase ~= "window" or self.pending ~= nil or typeof(value) ~= "number" then
			return
		end
		local night = Run.takeLedgerPage(run, value :: number)
		if night then
			self.stage.removePage(run.index)
			self.stage.fx({ kind = "page", text = Content.Ledger[night] })
			broadcast(self)
		end
	elseif kind == "continue" then
		if self.skippable and not self.ready[actor] then
			self.ready[actor] = true
			broadcast(self)
		end
	end
end

-- Everything that follows a call: the lanterns, where the passenger goes, and what they say.
local function react(self: Director, passenger: Types.Passenger, outcome: Types.Outcome)
	local run = self.run :: Run.Run
	local stage = self.stage

	stage.setLanterns(run.lanterns)
	stage.sendOff(run.index, exitFor(passenger, outcome))
	if outcome.decision == "board" and passenger.kind == "drowned" then
		stage.setFerryLoad(run.drownedBoarded)
	end

	stage.fx({ kind = "call", text = Director.callLabel(outcome) })
	local reply = if outcome.special then MARA_REPLIES[outcome.special] else nil
	if reply then
		stage.fx({ kind = "say", text = reply })
	end
	if outcome.lanternLost then
		stage.fx({ kind = "lanternOut", text = Director.note(outcome) })
	end
end

local function playNight(self: Director, retry: boolean): "done" | "failed"
	local run = self.run :: Run.Run
	local night = run.current :: Types.Night
	local def = Content.Nights[run.night]
	local stage = self.stage

	stage.setLanterns(run.lanterns)
	stage.setFerryLoad(run.drownedBoarded)
	stage.beginQueue(night.passengers)

	self.phase = "intro"
	self.title = `Night {run.night}`
	self.text = if retry then Content.RetryRadio else def.radioStart
	hold(self, Config.IntroTime, true)
	self.title = nil
	self.text = nil

	local midway = math.ceil(#night.passengers / 2)
	while true do
		local passenger = Run.nextPassenger(run)
		if passenger == nil then
			return "done"
		end

		self.phase = "queue"
		broadcast(self)
		stage.callToWindow(run.index)

		self.phase = "window"
		self.pending = nil
		self.deadline = self.clock.now() + Config.DecisionTime
		self.phaseEnds = self.deadline
		broadcast(self)
		local decided = waitUntil(self, self.deadline, function()
			return self.pending ~= nil
		end)
		local decision: Types.Decision = self.pending or "deny"
		self.pending = nil
		self.phaseEnds = nil

		local outcome = Run.decide(run, passenger.id, decision, not decided)
		assert(outcome, "Director: the call was rejected")
		self.phase = "queue"
		react(self, passenger, outcome)
		broadcast(self)

		if Run.isNightFailed(run) then
			return "failed"
		end
		if run.index == midway then
			stage.fx({ kind = "radio", text = def.radioMid })
		end
		self.clock.sleep(Config.BetweenPassengers)
	end
end

local function nightFailed(self: Director)
	self.phase = "failed"
	self.title = Content.NightFailed.title
	self.text = Content.NightFailed.text
	self.stage.setFlood(true)
	self.stage.clearQueue()
	hold(self, Config.FailedTime, false)
	self.stage.setFlood(false)
	self.title = nil
	self.text = nil
end

local function nightSummary(self: Director)
	local run = self.run :: Run.Run
	local rows: { View.SummaryRow } = {}
	for _, outcome in run.outcomes do
		table.insert(rows, {
			name = outcome.name,
			call = Director.callLabel(outcome),
			correct = outcome.correct,
			note = Director.note(outcome),
		})
	end
	self.phase = "summary"
	self.title = if run.night >= Content.FinalNight then "The last night is over" else `Night {run.night} survived`
	self.summary = rows
	hold(self, Config.SummaryTime, true)
	self.title = nil
	self.summary = nil
	self.stage.clearQueue()
end

local function showEnding(self: Director, result: Run.EndingResult)
	local ending = Content.Endings[result.id]
	local secret = Content.Endings.THE_LEDGER
	self.phase = "ending"
	self.ending = {
		id = result.id,
		title = ending.title,
		text = ending.text,
		secretTitle = if result.secret then secret.title else nil,
		secretText = if result.secret then secret.text else nil,
	}
	self.stage.clearQueue()
	self.stage.endingScene(result.id)
	self.stage.recordEnding(result.id, result.secret)
	hold(self, Config.EndingTime, true)
	self.ending = nil
end

-- Waits until at least one player is in the server.
function Director.waitForPlayers(self: Director)
	if #self.stage.actors() > 0 then
		return
	end
	self.run = nil
	self.phase = "waiting"
	broadcast(self)
	while #self.stage.actors() == 0 do
		self.clock.sleep(1)
	end
end

-- Plays one run, five nights and an ending. Yields throughout.
function Director.playRun(self: Director): Run.EndingResult
	local run = Run.new(self.stage.newSeed())
	self.run = run
	self.stage.resetWorld()
	Run.beginNight(run)

	local retry = false
	while true do
		if playNight(self, retry) == "failed" then
			nightFailed(self)
			Run.restartNight(run)
			retry = true
		else
			nightSummary(self)
			retry = false
			if Run.finishNight(run) == "ending" then
				break
			end
			Run.beginNight(run)
		end
	end

	local result = Run.ending(run)
	showEnding(self, result)
	return result
end

return Director
