--!strict
--[[
	The rules card. `broken` looks only at what the player can see: the ticket,
	the manifest, and the passenger's visible tells. The generator guarantees that
	each passenger's intended fate agrees with it, and the tests check that.
]]

local Content = require("./Content")
local Types = require("./Types")

local Rules = {}

function Rules.activeRules(night: number): { Types.RuleId }
	local list: { Types.RuleId } = {}
	for _, rule in Content.Rules do
		if rule.night <= night then
			table.insert(list, rule.id)
		end
	end
	return list
end

function Rules.isActive(night: number, id: Types.RuleId): boolean
	return table.find(Rules.activeRules(night), id) ~= nil
end

-- Text for the rules card, newest rules marked so players notice them.
function Rules.card(night: number, date: string): { { text: string, isNew: boolean } }
	local lines = {}
	for _, rule in Content.Rules do
		if rule.night <= night then
			local text = rule.text
			if rule.id == "date" then
				text = `Tickets must show tonight's date: {date}.`
			end
			table.insert(lines, { text = text, isNew = rule.night == night })
		end
	end
	return lines
end

function Rules.broken(passenger: Types.Passenger, night: Types.Night): { Types.RuleId }
	local onManifest: { [string]: boolean } = {}
	if night.manifest then
		for _, name in night.manifest do
			onManifest[name] = true
		end
	end

	local broken: { Types.RuleId } = {}
	for _, id in night.rules do
		local ok = true
		if id == "date" then
			ok = passenger.ticket.date == night.date
		elseif id == "destination" then
			ok = passenger.ticket.destination == Content.Destination
		elseif id == "stamp" then
			ok = passenger.ticket.stamp == "gull"
		elseif id == "dry" then
			ok = not passenger.wet
		elseif id == "manifest" then
			ok = onManifest[passenger.ticket.name] == true
		elseif id == "breath" then
			ok = passenger.breath
		elseif id == "shadow" then
			ok = passenger.shadow
		elseif id == "name" then
			ok = not passenger.saysName
		end
		if not ok then
			table.insert(broken, id)
		end
	end
	return broken
end

function Rules.shouldBoard(passenger: Types.Passenger, night: Types.Night): boolean
	return #Rules.broken(passenger, night) == 0
end

return Rules
