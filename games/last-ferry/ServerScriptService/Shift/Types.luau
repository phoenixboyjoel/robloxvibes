--!strict
-- Shared shapes for the pure shift logic (Rules, Generator, Run).

local Content = require("./Content")

export type RuleId = Content.RuleId
export type Stamp = "gull" | "anchor" | "none"
export type Kind = "living" | "drowned" | "mara"
export type Decision = "board" | "deny"

export type Ticket = {
	name: string,
	destination: string,
	date: string,
	stamp: Stamp,
}

-- Indices into palettes chosen on the Roblox side, plus flags that change the build.
export type Look = {
	coat: number,
	hat: number,
	scarf: number,
	bag: number,
	skin: number,
	height: number,
	pale: boolean,
}

export type Passenger = {
	id: number,
	kind: Kind,
	role: string, -- "regular" | "extra" | "herring" | "error" | "drowned" | "anna" | "mara"
	ticket: Ticket,
	-- What the player can see besides the ticket:
	wet: boolean,
	breath: boolean,
	shadow: boolean,
	saysName: boolean,
	line: string, -- may contain {name}
	hasLedgerPage: boolean,
	look: Look,
}

export type Night = {
	number: number,
	date: string,
	rules: { RuleId },
	manifest: { string }?, -- nil until the manifest rule is active
	passengers: { Passenger },
}

export type Outcome = {
	passengerId: number,
	name: string,
	kind: Kind,
	role: string,
	decision: Decision,
	timedOut: boolean,
	correct: boolean,
	lanternLost: boolean,
	special: string?, -- "mara_not_yet" | "mara_home" | "mara_wait"
	broken: { RuleId },
}

return {}
