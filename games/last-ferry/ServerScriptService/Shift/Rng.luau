--!strict
--[[
	Seeded random numbers (Park–Miller minimal standard generator). Pure Luau, so
	night generation is reproducible from a seed in tests and in Roblox alike.
	Every intermediate product stays below 2^53, so it is exact in doubles.
]]

local MODULUS = 2147483647
local MULTIPLIER = 48271

local Rng = {}
Rng.__index = Rng

export type Rng = typeof(setmetatable({} :: { state: number }, Rng))

function Rng.new(seed: number): Rng
	local state = math.floor(math.abs(seed)) % MODULUS
	if state == 0 then
		state = 1
	end
	return setmetatable({ state = state }, Rng)
end

-- Uniform number in [0, 1).
function Rng.next(self: Rng): number
	self.state = (self.state * MULTIPLIER) % MODULUS
	return (self.state - 1) / (MODULUS - 1)
end

-- Uniform integer in [low, high].
function Rng.int(self: Rng, low: number, high: number): number
	return low + math.floor(self:next() * (high - low + 1))
end

function Rng.chance(self: Rng, probability: number): boolean
	return self:next() < probability
end

function Rng.pick<T>(self: Rng, list: { T }): T
	assert(#list > 0, "Rng.pick on an empty list")
	return list[self:int(1, #list)]
end

-- Shuffles in place (Fisher–Yates) and returns the same list.
function Rng.shuffle<T>(self: Rng, list: { T }): { T }
	for i = #list, 2, -1 do
		local j = self:int(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

return Rng
