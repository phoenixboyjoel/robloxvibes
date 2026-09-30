--!strict
-- Tunables shared by server and client. Nothing secret: players can read this.

local Config = {
	Remotes = {
		State = "ShiftState", -- server -> client: the whole screen state
		Fx = "ShiftFx", -- server -> client: one-off effects (lantern out, page found)
		Progress = "ShiftProgress", -- server -> client: endings this player has found
		Action = "ShiftAction", -- client -> server: board / deny / page / continue
	},

	-- Seconds.
	DecisionTime = 45, -- then the window closes on them (counts as turning them away)
	IntroTime = 30, -- night title card; any player can open the window sooner
	SummaryTime = 25,
	FailedTime = 9,
	EndingTime = 60,
	BetweenPassengers = 1.5, -- after a call, before the next passenger steps up
	RadioTime = 9, -- Pike's mid-night message plays with nobody at the window
	LastPassengerTime = 6, -- watch the night's last passenger leave before the summary

	WalkSpeed = 7, -- studs per second

	ActionsPerSecond = 4,
	ActionBurst = 6,

	-- Booth camera look limits, in degrees.
	LookYaw = 38,
	LookPitchDown = 32,
	LookPitchUp = 12,
}

return Config
