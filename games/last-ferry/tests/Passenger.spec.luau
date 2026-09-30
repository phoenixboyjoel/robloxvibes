--!nonstrict
--[[
	How passengers are built (ServerScriptService/Services/PassengerService.luau),
	in the simulator: what you see comes from a passenger's facts, never from
	their kind, and the wardrobe matches the Look ranges the logic picks from.
]]

local Sim = require("./sim/Roblox")
local T = require("./TestLib")

T.suite("Passengers")

local SPAWN = [[
	local PassengerService = require("./Services/PassengerService")
	local spec = ...
	local folder = Instance.new("Folder")
	folder.Parent = workspace
	local look = {
		outfit = spec.outfit or 1, skin = 1, hair = 1, hairColor = 1, hat = spec.hat or 1, scarf = 1,
		bag = spec.bag or 1, face = 1, height = spec.height or 1, pale = spec.pale or false,
	}
	return PassengerService.spawn({
		id = spec.id or 1,
		kind = spec.kind or "living",
		role = "extra",
		ticket = { name = "Test", destination = "GULL ISLAND", date = "", stamp = "gull" },
		wet = spec.wet or false,
		breath = spec.breath ~= false,
		shadow = spec.shadow ~= false,
		saysName = false,
		line = "",
		hasLedgerPage = false,
		look = look,
	}, Vector3.new(spec.x or 0, 0, 0), Vector3.new(0, 0, 1), folder)
]]

local function spawn(sim, spec)
	local source = string.gsub(SPAWN, "local spec = %.%.%.", function()
		local fields = {}
		for key, value in spec do
			table.insert(fields, `{key} = {if type(value) == "string" then `"{value}"` else tostring(value)}`)
		end
		return `local spec = \{ {table.concat(fields, ", ")} \}`
	end)
	return sim:execute(source)
end

-- Rounds to hundredths (and turns -0 into 0), so float noise doesn't count.
local function r(value: number): number
	return math.floor(value * 100 + 0.5) / 100
end

-- Everything visible about a figure, relative to its root, sorted.
local function appearance(model): { string }
	local root = model.HumanoidRootPart.CFrame
	local rows = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local offset = root:ToObjectSpace(part.CFrame).Position
			table.insert(
				rows,
				string.format(
					"%s %.2f,%.2f,%.2f %.2f,%.2f,%.2f %.3f,%.3f,%.3f %s %.2f %.2f %s",
					part.Name,
					r(offset.X),
					r(offset.Y),
					r(offset.Z),
					r(part.Size.X),
					r(part.Size.Y),
					r(part.Size.Z),
					part.Color.R,
					part.Color.G,
					part.Color.B,
					part.Material.Name,
					part.Transparency,
					part.Reflectance,
					tostring(part.CastShadow)
				)
			)
		end
	end
	table.sort(rows)
	return rows
end

T.test("kind never changes how a passenger looks; only the facts do", function()
	local sim = Sim.new({ root = "." })
	for outfit = 0, 10 do
		local living = spawn(sim, { id = 1, kind = "living", outfit = outfit, hat = outfit % 7, bag = outfit % 4 })
		local drowned =
			spawn(sim, { id = 2, kind = "drowned", outfit = outfit, hat = outfit % 7, bag = outfit % 4, x = 20 })
		local a, b = appearance(living), appearance(drowned)
		T.equal(#a, #b, `outfit {outfit}: same number of parts`)
		for i = 1, #a do
			T.equal(b[i], a[i], `outfit {outfit}: part {i}`)
		end
	end
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("the tells come from the facts", function()
	local sim = Sim.new({ root = "." })
	local dry = spawn(sim, { id = 1 })
	local wet = spawn(sim, { id = 2, wet = true, x = 10 })
	local cold = spawn(sim, { id = 3, breath = false, shadow = false, x = 20 })
	local pale = spawn(sim, { id = 4, wet = true, pale = true, x = 30 })

	T.expect(dry:FindFirstChild("Drips", true) == nil, "dry passengers don't drip")
	T.expect(wet:FindFirstChild("Drips", true) ~= nil, "wet passengers drip")
	T.expect(wet.Torso.Color ~= dry.Torso.Color and wet.Torso.Reflectance > 0, "a soaked coat is darker and glossy")
	T.expect(dry:FindFirstChild("Breath", true) ~= nil, "the living breathe")
	T.expect(cold:FindFirstChild("Breath", true) == nil, "no breath without the fact")
	for _, part in cold:GetDescendants() do
		if part:IsA("BasePart") then
			T.equal(part.CastShadow, false, `{part.Name} casts no shadow`)
		end
	end
	T.expect(pale:FindFirstChild("Seaweed") ~= nil, "the pale, wet drowned wear seaweed")
	T.expect(wet:FindFirstChild("Seaweed") == nil, "only when pale")
	T.expect(pale.Head.Color ~= dry.Head.Color, "pale skin")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("the wardrobe covers every Look the logic can pick", function()
	local Content = require("../ServerScriptService/Shift/Content")
	local sim = Sim.new({ root = "." })
	local sizes = sim:execute([[return require("./Services/Robloxian").Sizes]])
	for key, count in Content.Wardrobe do
		T.equal(sizes[key], count, `wardrobe {key}`)
	end
	-- Every hat, bag and outfit builds without error, and Mara (outfit 0) is small.
	for hat = 0, Content.Wardrobe.hats do
		spawn(sim, { id = 10 + hat, hat = hat, bag = hat % 4, outfit = hat % 11, x = hat * 6 })
	end
	local mara = spawn(sim, { id = 99, outfit = 0, height = 0.72, x = -20 })
	T.expect(mara.Torso.Size.Y < 1.5, "Mara is small")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

return nil
