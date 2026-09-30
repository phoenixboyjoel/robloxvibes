--!strict
--[[
	All story text and tuning for Last Ferry. Pure data: no Roblox APIs, so the
	logic tests can load it outside Roblox. Lives on the server so players can't
	datamine later nights, the ledger, or the endings.
]]

export type RuleId = "date" | "destination" | "stamp" | "dry" | "manifest" | "breath" | "shadow" | "name"

export type NightDef = {
	date: string,
	yesterday: string,
	tomorrow: string,
	validExtras: number,
	errors: number,
	drowned: number,
	anna: boolean,
	radioStart: string,
	radioMid: string,
}

export type Regular = {
	name: string,
	lines: { string },
}

export type Ending = {
	title: string,
	text: string,
}

local Content = {}

Content.FinalNight = 5
Content.LanternsPerNight = 3
Content.OldDate = "14 NOV 1999"
Content.Destination = "GULL ISLAND"

-- Rules in the order they appear on the card. `night` is when each is introduced.
Content.Rules = {
	{ id = "date" :: RuleId, night = 1, text = "Tickets must show tonight's date." },
	{ id = "destination" :: RuleId, night = 1, text = "Destination must read GULL ISLAND." },
	{ id = "stamp" :: RuleId, night = 2, text = "Every ticket needs the harbor stamp: a red gull." },
	{ id = "dry" :: RuleId, night = 2, text = "It hasn't rained tonight. Nobody wet may board." },
	{ id = "manifest" :: RuleId, night = 3, text = "Only names on tonight's manifest may board." },
	{ id = "breath" :: RuleId, night = 3, text = "It's below freezing. The living breathe fog." },
	{ id = "shadow" :: RuleId, night = 4, text = "Everyone under the booth lamp casts a shadow." },
	{ id = "name" :: RuleId, night = 5, text = "Nobody here knows your name. If they say it, they don't board." },
}

-- Shown in the night summary next to a wrong call.
Content.Reasons = {
	date = "Ticket wasn't dated tonight",
	destination = "Ticket wasn't for Gull Island",
	stamp = "No red gull stamp",
	dry = "Soaking wet on a dry night",
	manifest = "Not on tonight's manifest",
	breath = "No breath in the freezing air",
	shadow = "No shadow under the lamp",
	name = "They knew your name",
} :: { [RuleId]: string }

Content.Nights = {
	{
		date = "14 NOV 2026",
		yesterday = "13 NOV 2026",
		tomorrow = "15 NOV 2026",
		validExtras = 1,
		errors = 1,
		drowned = 1,
		anna = false,
		radioStart = "Evening. Pike here, up at the lighthouse. You're the new clerk? Two rules tonight: "
			.. "tickets dated tonight, and for Gull Island. Nothing else gets past you. "
			.. "And if anyone hands you an old ticket, don't argue. Just turn them away.",
		radioMid = "You saw one, didn't you. Don't look at them too long.",
	},
	{
		date = "15 NOV 2026",
		yesterday = "14 NOV 2026",
		tomorrow = "16 NOV 2026",
		validExtras = 1,
		errors = 1,
		drowned = 2,
		anna = false,
		radioStart = "Harbor office sent new rules. Every ticket gets the red gull stamp now. "
			.. "And it hasn't rained all night. So if someone's dripping, they came up from the water, "
			.. "not down from the sky.",
		radioMid = "They've figured out the date. They're quicker than they used to be.",
	},
	{
		date = "16 NOV 2026",
		yesterday = "15 NOV 2026",
		tomorrow = "17 NOV 2026",
		validExtras = 1,
		errors = 2,
		drowned = 2,
		anna = false,
		radioStart = "Manifest's on your desk tonight. If a name isn't on it, they don't board. "
			.. "It's below freezing out there. Watch their breath. The living can't help it.",
		radioMid = "Some of them are dry tonight. They're learning. Watch the air in front of their faces.",
	},
	{
		date = "17 NOV 2026",
		yesterday = "16 NOV 2026",
		tomorrow = "18 NOV 2026",
		validExtras = 1,
		errors = 1,
		drowned = 3,
		anna = false,
		radioStart = "They're learning. Some of them breathe now, or pretend to, and they've been stealing "
			.. "names off the manifest. But the lamp doesn't lie. Look at the planks. No shadow, no ferry.",
		radioMid = "Three of them came up the ladder at the north pier. I watched them wring out their coats.",
	},
	{
		date = "18 NOV 2026",
		yesterday = "17 NOV 2026",
		tomorrow = "19 NOV 2026",
		validExtras = 1,
		errors = 1,
		drowned = 3,
		anna = true,
		radioStart = "Last night. After tonight they sleep another year. If one of them says your name, "
			.. "they've been watching you work. Don't answer. Don't let them on. "
			.. "...And if you see a little girl in a red coat, her name's Mara. My granddaughter. "
			.. "She's been trying to get home for twenty-seven years. Do what the rules say. I'll understand.",
		radioMid = "I'm going to try the lamp tonight. First time since '99. Keep your window shut if it gets bad.",
	},
} :: { NightDef }

-- Regulars ride every night, never break a rule, and carry the town's side of the story.
Content.Regulars = {
	{
		name = "Tomas Brennan",
		lines = {
			"Petrel's a good boat. Better than the old one.",
			"Heard knocking on the hull last night. Ice, probably. Probably.",
			"You look tired. Don't let them get to you.",
			"My dad was on the Marigold. Did you know that?",
			"Last night of it. Then they sleep another year.",
		},
	},
	{
		name = "Priya Nair",
		lines = {
			"Night shift at the island clinic. You too, I see.",
			"Someone on the ferry last night asked me what year it was.",
			"Keep your window shut between customers. Trust me.",
			"Three hypothermia cases this week. None of them were cold when they came in.",
			"If you ever want a day job, the clinic's hiring.",
		},
	},
} :: { Regular }

Content.LivingNames = {
	"Agnes Rudd",
	"Hollis Webb",
	"June Okafor",
	"Declan Marsh",
	"Sam Kowalski",
	"Rosa Lindqvist",
	"Felix Adeyemi",
	"Nell Hart",
	"Otto Brandt",
	"Wren Castell",
	"Iris Moreau",
	"Callum Reid",
	"Maeve Doyle",
	"Arjun Mehta",
	"Bea Holloway",
	"Linus Varga",
	"Tess Galloway",
	"Kit Ramsey",
	"Hana Sato",
	"Omar Haddad",
	"Greta Lund",
	"Milo Ferris",
	"Ada Quinn",
	"Ravi Bose",
}

Content.LivingLines = {
	"Cold enough to freeze the gulls, isn't it?",
	"My brother's getting married on the island. Don't ask why at night.",
	"Is the café on the island still open this late?",
	"Evening.",
	"Do you hear that knocking under the dock? No? Just me, then.",
	"My phone says there's no signal on the island. Perfect.",
	"They say the old ferry comes back this week every year.",
	"Just the one ticket, yes. Just me.",
	"Is it always this foggy?",
	"I've got a dog in this bag. Kidding. Mostly.",
	"Long night?",
	"Sorry, my hands are shaking. It's the cold.",
	"The lamp over your window keeps flickering. Somebody should fix that.",
	"First time on the night crossing. Anything I should know?",
}

-- Living passengers who say unsettling things but break no rule.
Content.RedHerrings = {
	{ name = "Edith Crane", line = "I haven't set foot on a ferry since 1999. I swore I wouldn't." },
	{ name = "Albie Shaw", line = "There's someone standing out on the water. Right there. Don't you see them?" },
	{ name = "Noor Rahman", line = "My grandfather drowned out there. I bring him flowers every year." },
}

-- Names from the Marigold's passenger list. The drowned use them.
Content.DrownedNames = {
	"Walter Finch",
	"Clara Finch",
	"Ernest Gale",
	"Dorothy Leigh",
	"Harold Mott",
	"Irene Salt",
	"Percy Dunn",
	"Mabel Orr",
	"George Tully",
	"Winifred Hale",
	"Albert Crewe",
	"Lottie Price",
	"Ruth Ansel",
	"Victor Kell",
	"Edna Voss",
	"Silas Marr",
	"Fern Oakes",
	"Cecil Thorne",
}

-- What the drowned say, by night. {name} is replaced with a player's display name.
Content.DrownedLines = {
	{
		"The water was so cold.",
		"Is this the Marigold?",
		"I've been waiting a long time.",
		"One for Gull Island. I'm late. I'm very late.",
	},
	{
		"Lovely dry night, isn't it?",
		"Here's my ticket. It's fine. It's all fine.",
		"I just need to get home.",
		"Is the captain aboard? Captain Ansel?",
	},
	{
		"One for Gull Island, please.",
		"I remember this booth. It was blue then.",
		"Evening. Cold one.",
		"Quickly, please. They're waiting for me.",
	},
	{
		"See? I'm breathing. See?",
		"We're getting better at this.",
		"My name's on your list. Look.",
		"Ticket, stamp, name. All in order.",
	},
	{
		"Evening, {name}.",
		"Long shift, {name}?",
		"{name}. We've been watching you work.",
		"You've been kind to us, {name}. Mostly.",
	},
} :: { { string } }

-- Night 5 always brings Mara's mother.
Content.Anna = {
	name = "Anna Pike",
	line = "Have you seen my girl? Red coat. She was right beside me.",
}

Content.Mara = {
	name = "Mara Pike",
	lines = {
		"Is this the ferry home? My mum's on Gull Island.",
		"You're the one who was here yesterday. Is it tonight?",
		"I'm not wet. See? I never went in the water.",
		"Grandpa says the lamp is broken. Can you see it from here?",
		"Please. It's the last night. Is it the ferry home?",
	},
	-- Letting her board on nights 1–4.
	notYet = "Not yet. The lamp's still dark.",
	-- Turning her away on the final night.
	wait = "That's okay. I'll wait. I'm good at waiting.",
	-- Letting her board on the final night.
	home = "Thank you. I can see the light.",
}

-- One page per night, tucked behind one ticket.
Content.Ledger = {
	"14 Nov 1999. Marigold licensed for 23 souls. Sold 23. Crossing weather fair. — R. Vell, Harbormaster",
	"Storm warning at 21:00. Captain Ansel wants to cancel. I told him the island needs the supplies.",
	"Sold 18 more tickets at the pier, cash. Nobody counts heads on a cold night.",
	"41 aboard. Pike radioed: the lamp is out, the mechanism froze. I told Ansel to sail anyway.",
	"I wrote 23 in the official log. I'll say the rest were never aboard. God forgive me. — R. Vell",
}

Content.Endings = {
	CLEAN_SHIFT = {
		title = "The Petrel Sails",
		text = "Five nights. Not one of them got aboard. At five in the morning the Petrel pulls away "
			.. "full of the living, and for the first time in twenty-seven years the lamp on Gull Point "
			.. 'flickers on. The radio crackles: "Go home, clerk. Get some sleep."',
	},
	MARA_HOME = {
		title = "Mara Goes Home",
		text = "You wave through a ticket that is twenty-seven years old. Mara walks up the gangway, "
			.. "and out in the fog something answers the Petrel's horn: an old, low note. The Marigold's "
			.. "lights. The lamp on Gull Point blazes. On the radio, an old man is crying.",
	},
	LOW_IN_THE_WATER = {
		title = "Low in the Water",
		text = "The Petrel leaves at five, riding low. Lower than it should. At six, Gull Island radios: "
			.. "the ferry never arrived. Tomorrow night's manifest is already on your desk. "
			.. "Your name is on it.",
	},
	THE_LEDGER = {
		title = "The Ledger",
		text = "You mail Vell's five pages to the Gull Island Gazette. The next night, the queue is empty. "
			.. "Somewhere in the fog a ferry horn sounds once, and then never again.",
	},
} :: { [string]: Ending }

Content.EndingOrder = { "CLEAN_SHIFT", "MARA_HOME", "LOW_IN_THE_WATER", "THE_LEDGER" }

Content.NightFailed = {
	title = "The Tide Came In",
	text = "The last lantern goes out. Cold water rises through the floorboards of the booth, "
		.. "and something taps on the glass. Take the night again.",
}

-- Pike, when a night is taken again.
Content.RetryRadio = "Clerk? You still there? Good. The tide's gone back out. Same rules as before. "
	.. "Take your time with each one. They're counting on you rushing."

-- Notes beside each call in the night summary, and on a lost lantern.
Content.Notes = {
	aliveBoarded = "Alive. A safe crossing.",
	aliveTurnedAway = "Alive, and nothing was wrong with their ticket.",
	errorBoarded = "Alive, but they shouldn't have boarded.",
	drownedTurnedAway = "Drowned in 1999.",
	drownedBoarded = "Drowned in 1999, and now they're aboard the Petrel.",
	anna = "Mara's mother.",
	maraNotYet = "Mara. You said yes. She said: not yet.",
	maraTurnedAway = "Mara. She'll be back tomorrow night.",
	maraHome = "Mara went home.",
	maraWait = "Mara will wait another year.",
}

Content.WrongDestinations = { "SALT POINT", "GULL ROCK", "HARBOUR TOWN", "GREY ISLAND" }

return Content
