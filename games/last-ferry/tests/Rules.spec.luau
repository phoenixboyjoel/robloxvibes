--!strict
local Content = require("../ServerScriptService/Shift/Content")
local Rules = require("../ServerScriptService/Shift/Rules")
local Types = require("../ServerScriptService/Shift/Types")
local T = require("./TestLib")

T.suite("Rules")

local function passenger(overrides: { [string]: any }?): Types.Passenger
	local p: Types.Passenger = {
		id = 1,
		kind = "living",
		role = "extra",
		ticket = { name = "Ada Quinn", destination = Content.Destination, date = "16 NOV 2026", stamp = "gull" },
		wet = false,
		breath = true,
		shadow = true,
		saysName = false,
		line = "Evening.",
		hasLedgerPage = false,
		look = {
			outfit = 1,
			skin = 1,
			hair = 0,
			hairColor = 1,
			hat = 0,
			scarf = 0,
			bag = 0,
			face = 0,
			height = 1,
			pale = false,
		},
	}
	if overrides then
		for key, value in overrides do
			(p :: any)[key] = value
		end
	end
	return p
end

local function night(number: number, manifest: { string }?): Types.Night
	return {
		number = number,
		date = "16 NOV 2026",
		rules = Rules.activeRules(number),
		manifest = manifest,
		passengers = {},
	}
end

T.test("rules accumulate night by night", function()
	T.equal(#Rules.activeRules(1), 2)
	T.equal(#Rules.activeRules(2), 4)
	T.equal(#Rules.activeRules(3), 6)
	T.equal(#Rules.activeRules(4), 7)
	T.equal(#Rules.activeRules(5), 8)
end)

T.test("a clean ticket boards on every night", function()
	for n = 1, 5 do
		T.expect(Rules.shouldBoard(passenger(), night(n, { "Ada Quinn" })), `night {n}`)
	end
end)

T.test("tells only count once their rule is active", function()
	local ghost = passenger({ breath = false, shadow = false })
	T.expect(Rules.shouldBoard(ghost, night(2, nil)), "breath/shadow rules not active on night 2")
	T.expect(not Rules.shouldBoard(ghost, night(3, { "Ada Quinn" })), "breath rule active on night 3")
end)

T.test("each rule catches its own violation", function()
	type Case = { rule: string, overrides: { [string]: any }, night: number }
	local ticket = function(date: string, destination: string, stamp: string)
		return { name = "Ada Quinn", destination = destination, date = date, stamp = stamp }
	end
	local cases: { Case } = {
		{ rule = "date", overrides = { ticket = ticket(Content.OldDate, Content.Destination, "gull") }, night = 1 },
		{ rule = "destination", overrides = { ticket = ticket("16 NOV 2026", "SALT POINT", "gull") }, night = 1 },
		{ rule = "stamp", overrides = { ticket = ticket("16 NOV 2026", Content.Destination, "none") }, night = 2 },
		{ rule = "dry", overrides = { wet = true }, night = 2 },
		{ rule = "breath", overrides = { breath = false }, night = 3 },
		{ rule = "shadow", overrides = { shadow = false }, night = 4 },
		{ rule = "name", overrides = { saysName = true }, night = 5 },
	}
	for _, case in cases do
		local broken = Rules.broken(passenger(case.overrides), night(case.night, { "Ada Quinn" }))
		T.equal(#broken, 1, `rule {case.rule}`)
		T.equal(broken[1], case.rule)
	end
	local offList = Rules.broken(passenger(), night(3, { "Somebody Else" }))
	T.equal(offList[1], "manifest")
end)

T.test("the rules card shows tonight's date and marks new rules", function()
	local card = Rules.card(3, "16 NOV 2026")
	T.equal(#card, 6)
	T.expect(string.find(card[1].text, "16 NOV 2026", 1, true) ~= nil, "date in rule text")
	T.expect(not card[1].isNew and card[5].isNew and card[6].isNew, "new-rule flags")
end)

return nil
