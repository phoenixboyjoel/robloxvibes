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

-- How a passenger looks: indices into the wardrobe the Roblox side draws from
-- (Content.Wardrobe gives the size of each list; 0 means "none"), plus flags that
-- change the build. Chosen from the passenger's name, never their kind, so the same
-- person looks the same every night and looks never give the drowned away.
export type Look = {
	outfit: number,
	skin: number,
	hair: number,
	hairColor: number,
	hat: number,
	scarf: number,
	bag: number,
	face: number, -- 0 nothing, 1 glasses, 2 a moustache
	height: number, -- scale of the whole figure
	pale: boolean, -- the drowned on the early nights, before they learn to hide it
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
