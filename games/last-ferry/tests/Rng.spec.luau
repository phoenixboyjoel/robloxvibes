--!strict
local Rng = require("../ServerScriptService/Shift/Rng")
local T = require("./TestLib")

T.suite("Rng")

T.test("same seed gives the same sequence", function()
	local a, b = Rng.new(42), Rng.new(42)
	for _ = 1, 1000 do
		T.equal(a:next(), b:next())
	end
end)

T.test("different seeds diverge", function()
	local a, b = Rng.new(1), Rng.new(2)
	local same = 0
	for _ = 1, 100 do
		if a:next() == b:next() then
			same += 1
		end
	end
	T.expect(same < 5, "sequences should differ")
end)

T.test("next stays in [0, 1) and int stays in range", function()
	local rng = Rng.new(7)
	local seen: { [number]: boolean } = {}
	for _ = 1, 20000 do
		local x = rng:next()
		T.expect(x >= 0 and x < 1, `next out of range: {x}`)
		local n = rng:int(3, 9)
		T.expect(n >= 3 and n <= 9 and n % 1 == 0, `int out of range: {n}`)
		seen[n] = true
	end
	for n = 3, 9 do
		T.expect(seen[n], `int never produced {n}`)
	end
end)

T.test("zero and negative seeds still work", function()
	for _, seed in { 0, -5, 2147483647, 1e12 } do
		local x = Rng.new(seed):next()
		T.expect(x >= 0 and x < 1, `bad value for seed {seed}`)
	end
end)

T.test("shuffle is a permutation", function()
	local rng = Rng.new(99)
	local list = {}
	for i = 1, 50 do
		list[i] = i
	end
	rng:shuffle(list)
	table.sort(list)
	for i = 1, 50 do
		T.equal(list[i], i)
	end
end)

return nil
