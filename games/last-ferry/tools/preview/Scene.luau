--!nonstrict
--[[
	Serializes the simulator's world and one player's screen to plain JSON for
	tools/preview/render (a three.js approximation of Roblox's renderer).

	Every readable, non-deprecated property the engine defines for a class is
	written, using the same reflection data the simulator enforces, so anything
	the game builds reaches the renderer without this file knowing about it.

	Value encoding:
		Color3 {r, g, b} · Vector2 {x, y} · Vector3 {x, y, z} · CFrame 12 numbers
		UDim {scale, offset} · UDim2 {xs, xo, ys, yo} · Rect {x0, y0, x1, y1}
		NumberRange {min, max} · NumberSequence {{t, v, e}...} · ColorSequence {{t, {r, g, b}}...}
		EnumItem "Name" · Font {family, weight, style} · Instance → its node id (or nil)
]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Scene = {}

local reflection = nil
local propertyLists = {}

local function loadReflection(root: string)
	if reflection == nil then
		reflection = serde.decode("json", fs.readFile(`{root}/tests/sim/reflection.json`)).classes
	end
end

-- Every readable, non-deprecated property of a class, including inherited ones.
local function propertiesOf(className: string): { string }
	local cached = propertyLists[className]
	if cached then
		return cached
	end
	local names = {}
	local seen = {}
	local name = className
	while name and reflection[name] do
		for key, info in reflection[name].properties do
			if not info.deprecated and not seen[key] and key ~= "Parent" then
				seen[key] = true
				table.insert(names, key)
			end
		end
		name = reflection[name].superclass
	end
	table.sort(names)
	propertyLists[className] = names
	return names
end

local function finite(n: number): number?
	if n ~= n or n == math.huge or n == -math.huge then
		return nil
	end
	return n
end

local function encodeValue(value: any, ids: { [any]: number }): any
	local kind = typeof(value)
	if kind == "number" then
		return finite(value)
	elseif kind == "boolean" or kind == "string" then
		return value
	elseif kind == "Color3" then
		return { value.R, value.G, value.B }
	elseif kind == "Vector2" then
		return { value.X, value.Y }
	elseif kind == "Vector3" then
		return { value.X, value.Y, value.Z }
	elseif kind == "CFrame" then
		return { value:GetComponents() }
	elseif kind == "UDim" then
		return { value.Scale, value.Offset }
	elseif kind == "UDim2" then
		return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
	elseif kind == "Rect" then
		return { value.Min.X, value.Min.Y, value.Max.X, value.Max.Y }
	elseif kind == "NumberRange" then
		return { value.Min, value.Max }
	elseif kind == "NumberSequence" then
		local keys = {}
		for _, key in value.Keypoints do
			table.insert(keys, { key.Time, key.Value, key.Envelope })
		end
		return keys
	elseif kind == "ColorSequence" then
		local keys = {}
		for _, key in value.Keypoints do
			table.insert(keys, { key.Time, { key.Value.R, key.Value.G, key.Value.B } })
		end
		return keys
	elseif kind == "EnumItem" then
		return value.Name
	elseif kind == "Font" then
		return { family = value.Family, weight = value.Weight.Name, style = value.Style.Name }
	elseif kind == "BrickColor" then
		return { value.Color.R, value.Color.G, value.Color.B }
	elseif kind == "table" then
		local mt = getmetatable(value)
		if type(mt) == "table" and rawget(mt, "__type") == "Instance" then
			return ids[value]
		end
	end
	return nil
end

-- A node for `instance` and everything under it.
local function node(sim, instance, ids: { [any]: number }, nextId: { number }, skip: ((any) -> boolean)?): any
	if skip and skip(instance) then
		return nil
	end
	local className = sim:className(instance)
	nextId[1] += 1
	local id = nextId[1]
	ids[instance] = id
	local props = {}
	for _, key in propertiesOf(className) do
		local ok, value = pcall(function()
			return instance[key]
		end)
		if ok and value ~= nil then
			props[key] = encodeValue(value, ids)
		end
	end
	local children = {}
	for _, child in instance:GetChildren() do
		local childNode = node(sim, child, ids, nextId, skip)
		if childNode then
			table.insert(children, childNode)
		end
	end
	return {
		id = id,
		class = className,
		name = instance.Name,
		props = props,
		children = children,
	}
end

-- Instance-valued properties (Adornee, Part0, PrimaryPart...) point at ids, which only
-- exist once everything has been visited, so they are filled in on a second pass.
local function relink(tree, byId: { [number]: any }, ids: { [any]: number })
	local function walk(n)
		local instance = byId[n.id]
		if instance then
			for _, key in propertiesOf(n.class) do
				local ok, value = pcall(function()
					return instance[key]
				end)
				if ok and type(value) == "table" then
					local mt = getmetatable(value)
					if type(mt) == "table" and rawget(mt, "__type") == "Instance" then
						n.props[key] = ids[value]
					end
				end
			end
		end
		for _, child in n.children do
			walk(child)
		end
	end
	walk(tree)
end

export type Options = {
	root: string?,
	player: any?, -- whose screen to capture (nil: the world only)
	notes: { [string]: any }?,
}

function Scene.capture(sim, options: Options): any
	loadReflection(options.root or ".")
	local ids = {}
	local nextId = { 0 }

	local workspaceTree = node(sim, sim.workspace, ids, nextId)
	local lighting = sim.game:GetService("Lighting")
	local lightingTree = node(sim, lighting, ids, nextId)
	local gui = if options.player then options.player:FindFirstChild("PlayerGui") else nil
	local guiTree = if gui then node(sim, gui, ids, nextId) else nil

	local byId = {}
	for instance, id in ids do
		byId[id] = instance
	end
	relink(workspaceTree, byId, ids)
	relink(lightingTree, byId, ids)
	if guiTree then
		relink(guiTree, byId, ids)
	end

	-- Chat bubbles this player can still see (Roblox shows each for about 15 seconds).
	local bubbles = {}
	for _, bubble in sim.bubbles or {} do
		local age = sim.now - bubble.time
		if bubble.player == options.player and age <= 15 and ids[bubble.adornee] then
			table.insert(bubbles, { adornee = ids[bubble.adornee], message = bubble.message, age = age })
		end
	end

	local camera = sim.workspace.CurrentCamera
	local character = if options.player then options.player.Character else nil
	return {
		bubbles = bubbles,
		version = 3,
		-- The player's own character (its ProximityPrompts show when it's close enough).
		localCharacter = if character then ids[character] else nil,
		time = sim.now,
		screen = { sim.screen.X, sim.screen.Y },
		safeArea = { sim.safeArea.X, sim.safeArea.Y },
		preferredInput = sim.preferredInput.Name,
		camera = {
			cframe = { camera.CFrame:GetComponents() },
			fov = camera.FieldOfView,
		},
		terrain = sim.terrainFills,
		workspace = workspaceTree,
		lighting = lightingTree,
		playerGui = guiTree,
		notes = options.notes,
	}
end

function Scene.write(path: string, scene: any)
	local parent = string.match(path, "^(.*)/[^/]+$")
	if parent and not fs.isDir(parent) then
		fs.writeDir(parent)
	end
	fs.writeFile(path, serde.encode("json", scene))
end

return Scene
