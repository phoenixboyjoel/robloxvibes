--!strict
-- What the server sends the client. The client never learns who is drowned:
-- it gets the ticket, the words, and whatever it can see in the world.

export type Phase = "waiting" | "intro" | "queue" | "window" | "summary" | "failed" | "ending"

export type TicketView = {
	name: string,
	destination: string,
	date: string,
	stamp: string, -- "gull" | "anchor" | "none"
}

export type PassengerView = {
	id: number,
	ticket: TicketView,
	line: string, -- may contain {name}: each client fills in its own player's display name
	hasPage: boolean, -- a torn page is still tucked behind the ticket
	deadline: number, -- workspace:GetServerTimeNow() when the window closes
}

export type RuleLine = {
	text: string,
	isNew: boolean,
}

export type SummaryRow = {
	name: string,
	call: string, -- "BOARDED" | "TURNED AWAY" | "WINDOW CLOSED"
	correct: boolean,
	note: string,
}

export type LedgerPage = {
	night: number,
	text: string,
}

export type EndingView = {
	id: string,
	title: string,
	text: string,
	secretTitle: string?,
	secretText: string?,
}

export type Ready = {
	count: number,
	total: number,
}

export type State = {
	phase: Phase,
	night: number, -- 0 before the first run starts
	finalNight: number,
	date: string,
	clock: string,
	lanterns: number,
	maxLanterns: number,
	rules: { RuleLine },
	manifest: { string }?,
	passenger: PassengerView?,
	waiting: number, -- passengers still in the queue after the one at the window
	ledger: { LedgerPage }, -- pages found this run
	title: string?, -- title card for intro / summary / failed
	text: string?, -- body text for intro (the radio) / failed
	summary: { SummaryRow }?,
	ending: EndingView?,
	ready: Ready?, -- who has pressed Continue, while the phase waits on it
	phaseEnds: number?, -- server time the phase moves on by itself
}

export type Fx = {
	kind: string, -- "call" | "lanternOut" | "say" | "page" | "radio"
	text: string?,
}

export type Progress = {
	found: { string }, -- titles of the endings this player has found, in order
	total: number,
}

return {}
