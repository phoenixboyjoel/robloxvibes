--!strict
--[[
	Builds one night's queue. Guarantees (checked by tests/Generator.spec.luau):

	- Living passengers never show a supernatural tell (always dry, breathing,
	  casting a shadow, never saying your name). "Errors" break exactly one
	  paperwork rule that is active tonight; everyone else breaks none.
	- Every drowned passenger (and Mara) breaks at least one active rule, so the
	  right call is always readable from the ticket, the manifest and what you see.
	- The drowned hide one more tell each night, per GAME_DESIGN.md.
]]

local Content = require("./Content")
local Rng = require("./Rng")
local Rules = require("./Rules")
local Types = require("./Types")

export type Pools = {
	living: { string },
	drowned: { string },
	herrings: { number },
}

local Generator = {}

local MARA_NIGHT_LINES = #Content.Mara.lines

-- Fresh name pools for a run; names are drawn without replacement until a pool empties.
function Generator.newPools(rng: Rng.Rng): Pools
	local herrings = {}
	for i = 1, #Content.RedHerrings do
		table.insert(herrings, i)
	end
	return {
		living = rng:shuffle(table.clone(Content.LivingNames)),
		drowned = rng:shuffle(table.clone(Content.DrownedNames)),
		herrings = rng:shuffle(herrings),
	}
end

local function draw(rng: Rng.Rng, pool: { string }, source: { string }, taken: { [string]: boolean }): string
	for _ = 1, #source * 2 do
		if #pool == 0 then
			for _, name in rng:shuffle(table.clone(source)) do
				table.insert(pool, name)
			end
		end
		local name = table.remove(pool) :: string
		if not taken[name] then
			taken[name] = true
			return name
		end
	end
	error("Generator: ran out of unique names")
end

local function look(rng: Rng.Rng, pale: boolean): Types.Look
	return {
		coat = rng:int(1, 8),
		hat = rng:int(0, 3),
		scarf = rng:int(0, 5),
		bag = rng:int(0, 3),
		skin = rng:int(1, 6),
		height = 0.92 + rng:next() * 0.16,
		pale = pale,
	}
end

local function validTicket(name: string, date: string): Types.Ticket
	return { name = name, destination = Content.Destination, date = date, stamp = "gull" }
end

local function living(rng: Rng.Rng, role: string, name: string, date: string, line: string): Types.Passenger
	return {
		id = 0,
		kind = "living",
		role = role,
		ticket = validTicket(name, date),
		wet = false,
		breath = true,
		shadow = true,
		saysName = false,
		line = line,
		hasLedgerPage = false,
		look = look(rng, false),
	}
end

-- Returns the passenger and whether their name belongs on the manifest.
local function drowned(rng: Rng.Rng, night: number, def: Content.NightDef, name: string): (Types.Passenger, boolean)
	local ticket = validTicket(name, def.date)
	local wet, breath, shadow, saysName = false, false, false, false
	local onManifest = false
	local pale = night <= 2

	if night == 1 then
		ticket.date = Content.OldDate
		ticket.stamp = "anchor"
		wet = true
	elseif night == 2 then
		if rng:chance(0.5) then
			ticket.stamp = "anchor"
			wet = rng:chance(0.35)
		else
			wet = true
		end
	elseif night == 3 then
		onManifest = rng:chance(0.5)
	elseif night == 4 then
		breath = true
		onManifest = not rng:chance(0.25)
	else
		breath = true
		onManifest = true
		if rng:chance(0.3) then
			shadow = false -- slipped: forgot their shadow instead
		else
			shadow = true
			saysName = true
		end
	end

	local lines = Content.DrownedLines[math.clamp(night, 1, #Content.DrownedLines)]
	local line = rng:pick(lines)
	if saysName and not string.find(line, "{name}", 1, true) then
		line = "Evening, {name}."
	elseif not saysName and string.find(line, "{name}", 1, true) then
		line = "One for Gull Island."
	end

	return {
		id = 0,
		kind = "drowned",
		role = "drowned",
		ticket = ticket,
		wet = wet,
		breath = breath,
		shadow = shadow,
		saysName = saysName,
		line = line,
		hasLedgerPage = false,
		look = look(rng, pale),
	},
		onManifest
end

local function anna(rng: Rng.Rng): Types.Passenger
	return {
		id = 0,
		kind = "drowned",
		role = "anna",
		ticket = {
			name = Content.Anna.name,
			destination = Content.Destination,
			date = Content.OldDate,
			stamp = "anchor",
		},
		wet = true,
		breath = false,
		shadow = false,
		saysName = false,
		line = Content.Anna.line,
		hasLedgerPage = false,
		look = look(rng, true),
	}
end

local function mara(rng: Rng.Rng, night: number): Types.Passenger
	local passengerLook = look(rng, false)
	passengerLook.height = 0.72
	return {
		id = 0,
		kind = "mara",
		role = "mara",
		ticket = {
			name = Content.Mara.name,
			destination = Content.Destination,
			date = Content.OldDate,
			stamp = "anchor",
		},
		wet = false,
		breath = false,
		shadow = false,
		saysName = false,
		line = Content.Mara.lines[math.clamp(night, 1, MARA_NIGHT_LINES)],
		hasLedgerPage = false,
		look = passengerLook,
	}
end

-- Paperwork mistakes a living passenger can make, limited to tonight's rules.
local function applyError(rng: Rng.Rng, passenger: Types.Passenger, night: number, def: Content.NightDef): boolean
	local kinds: { Types.RuleId } = { "date", "destination" }
	if Rules.isActive(night, "stamp") then
		table.insert(kinds, "stamp")
	end
	if Rules.isActive(night, "manifest") then
		table.insert(kinds, "manifest")
	end

	local kind = rng:pick(kinds)
	if kind == "date" then
		passenger.ticket.date = if rng:chance(0.5) then def.yesterday else def.tomorrow
	elseif kind == "destination" then
		passenger.ticket.destination = rng:pick(Content.WrongDestinations)
	elseif kind == "stamp" then
		passenger.ticket.stamp = "none"
	end
	return kind ~= "manifest" -- false: leave them off the manifest
end

function Generator.buildNight(rng: Rng.Rng, number: number, pools: Pools): Types.Night
	local def = Content.Nights[number]
	assert(def, `No night {number}`)

	local taken: { [string]: boolean } = {}
	for _, regular in Content.Regulars do
		taken[regular.name] = true
	end
	taken[Content.Mara.name] = true
	taken[Content.Anna.name] = true
	for _, herring in Content.RedHerrings do
		taken[herring.name] = true
	end

	local queue: { Types.Passenger } = {}
	local manifestNames: { string } = {}
	local function add(passenger: Types.Passenger, listed: boolean)
		table.insert(queue, passenger)
		if listed then
			table.insert(manifestNames, passenger.ticket.name)
		end
	end

	-- Regulars ride every night with a line that moves their story on.
	local regulars = {}
	for _, regular in Content.Regulars do
		local line = regular.lines[math.clamp(number, 1, #regular.lines)]
		table.insert(regulars, living(rng, "regular", regular.name, def.date, line))
	end

	-- Valid extras; on nights 2–4 one of them may be a red herring.
	local extras = {}
	for i = 1, def.validExtras do
		if i == 1 and number >= 2 and number <= 4 and #pools.herrings > 0 and rng:chance(0.6) then
			local herring = Content.RedHerrings[table.remove(pools.herrings) :: number]
			table.insert(extras, living(rng, "herring", herring.name, def.date, herring.line))
		else
			local name = draw(rng, pools.living, Content.LivingNames, taken)
			table.insert(extras, living(rng, "extra", name, def.date, rng:pick(Content.LivingLines)))
		end
	end

	for _, passenger in regulars do
		add(passenger, true)
	end
	for _, passenger in extras do
		add(passenger, true)
	end

	for _ = 1, def.errors do
		local name = draw(rng, pools.living, Content.LivingNames, taken)
		local passenger = living(rng, "error", name, def.date, rng:pick(Content.LivingLines))
		local listed = applyError(rng, passenger, number, def)
		add(passenger, listed)
	end

	for _ = 1, def.drowned do
		local name = draw(rng, pools.drowned, Content.DrownedNames, taken)
		local passenger, listed = drowned(rng, number, def, name)
		add(passenger, listed)
	end

	-- A few no-shows so the manifest isn't simply "everyone in the queue".
	for _ = 1, 2 do
		table.insert(manifestNames, draw(rng, pools.living, Content.LivingNames, taken))
	end

	rng:shuffle(queue)

	-- Night 1 opens with a friendly regular so the first call is an easy BOARD.
	if number == 1 then
		for i, passenger in queue do
			if passenger.role == "regular" then
				table.remove(queue, i)
				table.insert(queue, 1, passenger)
				break
			end
		end
	end

	if def.anna then
		table.insert(queue, rng:int(2, #queue + 1), anna(rng))
	end

	-- Mara: somewhere after the first passenger, and last on the final night.
	local maraPassenger = mara(rng, number)
	if number >= Content.FinalNight then
		table.insert(queue, maraPassenger)
	else
		table.insert(queue, rng:int(2, #queue + 1), maraPassenger)
	end

	-- One ledger page per night, behind a random ticket (living or drowned) but never Mara's.
	local carriers = {}
	for i, passenger in queue do
		if passenger.kind ~= "mara" then
			table.insert(carriers, i)
		end
	end
	queue[rng:pick(carriers)].hasLedgerPage = true

	table.sort(manifestNames)

	return {
		number = number,
		date = def.date,
		rules = Rules.activeRules(number),
		manifest = if Rules.isActive(number, "manifest") then manifestNames else nil,
		passengers = queue,
	}
end

-- "11:00 PM" for the first passenger through "4:xx AM" for the last.
function Generator.clock(index: number, total: number): string
	local minutes = 23 * 60 + math.floor((index - 1) * 360 / math.max(total, 1))
	minutes = minutes % (24 * 60)
	local hour = math.floor(minutes / 60)
	local minute = minutes % 60
	local suffix = if hour >= 12 then "PM" else "AM"
	local display = hour % 12
	if display == 0 then
		display = 12
	end
	return string.format("%d:%02d %s", display, minute, suffix)
end

return Generator
