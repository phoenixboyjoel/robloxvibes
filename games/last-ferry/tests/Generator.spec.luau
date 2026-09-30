--!strict
local Content = require("../ServerScriptService/Shift/Content")
local Generator = require("../ServerScriptService/Shift/Generator")
local Rng = require("../ServerScriptService/Shift/Rng")
local Rules = require("../ServerScriptService/Shift/Rules")
local T = require("./TestLib")

T.suite("Generator")

local SEEDS = 400
local PAPERWORK = { date = true, destination = true, stamp = true, manifest = true }

local function eachNight(fn: (number, any, number) -> ())
	for seed = 1, SEEDS do
		local pools = Generator.newPools(Rng.new(seed))
		for number = 1, Content.FinalNight do
			fn(number, Generator.buildNight(Rng.new(seed * 31 + number), number, pools), seed)
		end
	end
end

T.test("queue size matches the night's recipe", function()
	eachNight(function(number, night)
		local def = Content.Nights[number]
		local expected = #Content.Regulars
			+ def.validExtras
			+ def.errors
			+ def.drowned
			+ (if def.anna then 1 else 0)
			+ 1
		T.equal(#night.passengers, expected, `night {number}`)
	end)
end)

T.test("every call is readable from what the player can see", function()
	eachNight(function(number, night, seed)
		for _, p in night.passengers do
			local broken = Rules.broken(p, night)
			local where = `seed {seed} night {number} {p.role} {p.ticket.name}`
			if p.kind == "living" then
				T.expect(p.breath and p.shadow and not p.wet and not p.saysName, `living with a tell: {where}`)
				if p.role == "error" then
					T.equal(#broken, 1, `error passenger should break exactly one rule: {where}`)
					T.expect(PAPERWORK[broken[1]], `error must be paperwork: {where}`)
				else
					T.equal(#broken, 0, `valid passenger breaks a rule: {where}`)
				end
			else
				T.expect(#broken >= 1, `drowned/Mara must break an active rule: {where}`)
			end
		end
	end)
end)

T.test("the drowned hide one more tell each night", function()
	eachNight(function(number, night)
		for _, p in night.passengers do
			if p.role == "drowned" then
				if number >= 3 then
					T.expect(not p.wet, "dry from night 3")
				end
				if number >= 4 then
					T.expect(p.breath, "breathing from night 4")
				end
				if number == 5 then
					T.expect(p.saysName or not p.shadow, "night 5: says your name or slips on the shadow")
				end
			end
		end
	end)
end)

T.test("{name} appears exactly when a passenger says your name", function()
	eachNight(function(_, night)
		for _, p in night.passengers do
			local hasToken = string.find(p.line, "{name}", 1, true) ~= nil
			T.equal(hasToken, p.saysName, `line "{p.line}"`)
		end
	end)
end)

T.test("Mara's placement, the night-1 opener, and Anna", function()
	eachNight(function(number, night)
		local maraAt, annaAt = 0, 0
		for i, p in night.passengers do
			if p.kind == "mara" then
				maraAt = i
			elseif p.role == "anna" then
				annaAt = i
			end
		end
		T.expect(maraAt >= 2, "Mara is never first")
		if number == Content.FinalNight then
			T.equal(maraAt, #night.passengers, "Mara is last on the final night")
			T.expect(annaAt > 0, "Anna appears on the final night")
		else
			T.equal(annaAt, 0, "Anna only on the final night")
		end
		if number == 1 then
			T.equal(night.passengers[1].role, "regular", "night 1 opens with a regular")
		end
	end)
end)

T.test("one ledger page per night, never on Mara", function()
	eachNight(function(_, night)
		local carriers = 0
		for _, p in night.passengers do
			if p.hasLedgerPage then
				carriers += 1
				T.expect(p.kind ~= "mara", "Mara never carries the page")
			end
		end
		T.equal(carriers, 1)
	end)
end)

T.test("manifest appears on night 3, sorted, and names are unique", function()
	eachNight(function(number, night)
		if number < 3 then
			T.expect(night.manifest == nil, "no manifest before night 3")
		else
			local manifest = night.manifest
			assert(manifest, "manifest from night 3")
			for i = 2, #manifest do
				T.expect(manifest[i - 1] <= manifest[i], "manifest sorted")
			end
		end
		local seen: { [string]: boolean } = {}
		for _, p in night.passengers do
			T.expect(not seen[p.ticket.name], `duplicate name {p.ticket.name}`)
			seen[p.ticket.name] = true
		end
	end)
end)

T.test("clock runs from 11 PM into the small hours", function()
	T.equal(Generator.clock(1, 8), "11:00 PM")
	T.equal(Generator.clock(2, 8), "11:45 PM")
	T.equal(Generator.clock(3, 8), "12:30 AM")
	T.equal(Generator.clock(8, 8), "4:15 AM")
end)

return nil
