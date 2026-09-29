--!strict
--[[
	Dialogue graphs. This lives on the server so players can't datamine story
	they haven't reached; the client only ever sees the node it is shown.

	Each dialogue names a start node. Each node has a speaker, a line, and
	options. An option with `to` jumps to that node; one without ends the talk.
]]

export type Option = {
	text: string,
	to: string?,
}

export type Node = {
	speaker: string,
	text: string,
	options: { Option },
}

export type Dialogue = {
	start: string,
	nodes: { [string]: Node },
}

local Dialogues: { [string]: Dialogue } = {
	Lighthouse = {
		start = "greet",
		nodes = {
			greet = {
				speaker = "Keeper",
				text = "The lamp went dark the night the ferry vanished. Nobody asks me why.",
				options = {
					{ text = "Why did it go dark?", to = "why" },
					{ text = "I should go." },
				},
			},
			why = {
				speaker = "Keeper",
				text = "Someone climbed the stairs before me. The oil was already gone.",
				options = {
					{ text = "Who else has a key?", to = "key" },
					{ text = "Goodbye." },
				},
			},
			key = {
				speaker = "Keeper",
				text = "Only the harbormaster. Ask her about the ledger.",
				options = {
					{ text = "I will." },
				},
			},
		},
	},
}

return Dialogues
