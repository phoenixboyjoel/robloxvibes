--!strict
--[[
	Robloxian: builds a classic Roblox character (R6 proportions) from parts, the
	way Roblox's own default dummy is built:
	- a HumanoidRootPart, a Torso, and a Head with the classic head mesh and the
	  built-in smile (rbxasset://textures/face.png, shipped with every client);
	- four limbs on Roblox's standard Motor6D joints;
	- a Humanoid with its name tag hidden.
	No asset IDs: everything here ships with the engine.

	Clothes, hair, hats, scarves and bags are parts welded to the body part they sit
	on, so they move with that limb when a client animates the joints
	(CrowdController).

	The wardrobe lists here are what a Look's indices point into; their sizes must
	match Content.Wardrobe (a test checks).
]]

local Robloxian = {}

export type Rig = {
	model: Model,
	root: Part,
	torso: Part,
	head: Part,
	leftArm: Part,
	rightArm: Part,
	leftLeg: Part,
	rightLeg: Part,
	humanoid: Humanoid,
	scale: number,
	feet: number, -- the feet are this far below the root's centre
	clothing: { BasePart }, -- darkened and glossy when soaked
	skin: { BasePart },
	hair: { BasePart },
	all: { BasePart }, -- every visible part
	hem: BasePart?, -- the bottom of a long coat, if the outfit has one
}

export type Look = {
	outfit: number,
	skin: number,
	hair: number,
	hairColor: number,
	hat: number,
	scarf: number,
	bag: number,
	face: number,
	height: number,
}

local FACE_TEXTURE = "rbxasset://textures/face.png"

-- Roblox BrickColor tones.
local SKINS = {
	Color3.fromRGB(245, 205, 48), -- Bright yellow: the classic Robloxian
	Color3.fromRGB(255, 204, 153), -- Pastel brown
	Color3.fromRGB(234, 184, 146), -- Light orange
	Color3.fromRGB(204, 142, 105), -- Nougat
	Color3.fromRGB(124, 92, 70), -- Brown
	Color3.fromRGB(105, 64, 40), -- Reddish brown
}

local HAIR_COLORS = {
	Color3.fromRGB(27, 27, 30), -- black
	Color3.fromRGB(72, 46, 32), -- dark brown
	Color3.fromRGB(124, 82, 48), -- brown
	Color3.fromRGB(230, 192, 104), -- blonde
	Color3.fromRGB(196, 98, 40), -- ginger
	Color3.fromRGB(172, 172, 176), -- grey
}

local SCARVES = {
	Color3.fromRGB(196, 40, 28), -- Bright red
	Color3.fromRGB(242, 243, 243), -- white
	Color3.fromRGB(13, 105, 172), -- Bright blue
	Color3.fromRGB(40, 127, 71), -- Dark green
	Color3.fromRGB(245, 205, 48), -- Bright yellow
}

local HAT_COLORS = {
	Color3.fromRGB(196, 40, 28),
	Color3.fromRGB(13, 105, 172),
	Color3.fromRGB(27, 42, 53),
	Color3.fromRGB(40, 127, 71),
	Color3.fromRGB(218, 133, 65),
}

local GOLD = Color3.fromRGB(226, 176, 60)
local WHITE = Color3.fromRGB(242, 243, 243)
local BLACK = Color3.fromRGB(27, 42, 53)
local LEATHER = Color3.fromRGB(105, 64, 40)
local CANVAS = Color3.fromRGB(186, 170, 130)
local OILSKIN = Color3.fromRGB(250, 196, 18)

type OutfitSpec = {
	name: string,
	torso: Color3,
	arms: Color3?, -- nil: bare arms (skin)
	legs: Color3,
	hem: boolean?, -- a long coat
	detail: ((
		rig: Rig,
		add: (name: string, size: Vector3, at: CFrame, color: Color3, on: BasePart, material: Enum.Material?) -> Part
	) -> ())?,
}

local OUTFITS: { OutfitSpec } = {
	{
		name = "peacoat",
		torso = Color3.fromRGB(33, 52, 96),
		arms = Color3.fromRGB(33, 52, 96),
		legs = Color3.fromRGB(58, 60, 66),
		hem = true,
		detail = function(rig, add)
			local s = rig.scale
			for row = 0, 2 do
				for _, side in { -1, 1 } do
					add(
						"Button",
						Vector3.new(0.14, 0.14, 0.06) * s,
						CFrame.new(0.32 * side * s, (0.45 - row * 0.45) * s, -0.52 * s),
						GOLD,
						rig.torso
					)
				end
			end
		end,
	},
	{
		name = "classic",
		torso = Color3.fromRGB(13, 105, 172), -- the noob's Bright blue
		arms = nil,
		legs = Color3.fromRGB(75, 151, 75), -- and Bright green
	},
	{
		name = "oilskin",
		torso = OILSKIN,
		arms = OILSKIN,
		legs = BLACK,
		hem = true,
		detail = function(rig, add)
			local s = rig.scale
			add(
				"Clasp",
				Vector3.new(0.12, 1.6, 0.06) * s,
				CFrame.new(0, 0.05 * s, -0.52 * s),
				Color3.fromRGB(214, 160, 10),
				rig.torso
			)
		end,
	},
	{
		name = "flannel",
		torso = Color3.fromRGB(196, 40, 28),
		arms = Color3.fromRGB(196, 40, 28),
		legs = Color3.fromRGB(39, 70, 145),
		detail = function(rig, add)
			local s = rig.scale
			for _, y in { 0.45, -0.25 } do
				add(
					"Check",
					Vector3.new(2.02, 0.16, 1.02) * s,
					CFrame.new(0, y * s, 0),
					Color3.fromRGB(120, 20, 16),
					rig.torso
				)
			end
			for _, arm in { rig.leftArm, rig.rightArm } do
				add(
					"Check",
					Vector3.new(1.02, 0.16, 1.02) * s,
					CFrame.new(0, 0.2 * s, 0),
					Color3.fromRGB(120, 20, 16),
					arm
				)
			end
		end,
	},
	{
		name = "parka",
		torso = Color3.fromRGB(40, 127, 71),
		arms = Color3.fromRGB(40, 127, 71),
		legs = Color3.fromRGB(105, 74, 56),
		hem = true,
		detail = function(rig, add)
			local s = rig.scale
			add(
				"Fur",
				Vector3.new(2.14, 0.34, 1.14) * s,
				CFrame.new(0, 0.9 * s, 0),
				WHITE,
				rig.torso,
				Enum.Material.Fabric
			)
		end,
	},
	{
		name = "suit",
		torso = Color3.fromRGB(70, 72, 80),
		arms = Color3.fromRGB(70, 72, 80),
		legs = BLACK,
		detail = function(rig, add)
			local s = rig.scale
			add("Shirt", Vector3.new(0.56, 1.1, 0.05) * s, CFrame.new(0, 0.45 * s, -0.51 * s), WHITE, rig.torso)
			add(
				"Tie",
				Vector3.new(0.18, 0.9, 0.06) * s,
				CFrame.new(0, 0.4 * s, -0.54 * s),
				Color3.fromRGB(196, 40, 28),
				rig.torso
			)
		end,
	},
	{
		name = "sweater",
		torso = Color3.fromRGB(107, 50, 124),
		arms = Color3.fromRGB(107, 50, 124),
		legs = Color3.fromRGB(116, 134, 157),
		detail = function(rig, add)
			local s = rig.scale
			add(
				"Collar",
				Vector3.new(2.04, 0.22, 1.04) * s,
				CFrame.new(0, 0.9 * s, 0),
				Color3.fromRGB(78, 34, 92),
				rig.torso
			)
		end,
	},
	{
		name = "tourist",
		torso = Color3.fromRGB(218, 133, 65),
		arms = nil,
		legs = Color3.fromRGB(193, 190, 66),
		detail = function(rig, add)
			local s = rig.scale
			add(
				"Strap",
				Vector3.new(0.12, 1.25, 1.04) * s,
				CFrame.new(0, 0.35 * s, 0) * CFrame.Angles(0, 0, math.rad(35)),
				BLACK,
				rig.torso
			)
			add("Camera", Vector3.new(0.6, 0.4, 0.34) * s, CFrame.new(0.15 * s, -0.05 * s, -0.65 * s), BLACK, rig.torso)
			add(
				"Lens",
				Vector3.new(0.24, 0.24, 0.12) * s,
				CFrame.new(0.15 * s, -0.05 * s, -0.86 * s),
				Color3.fromRGB(99, 95, 98),
				rig.torso,
				Enum.Material.Glass
			)
		end,
	},
	{
		name = "scrubs",
		torso = Color3.fromRGB(0, 143, 156),
		arms = nil,
		legs = Color3.fromRGB(0, 143, 156),
		detail = function(rig, add)
			local s = rig.scale
			add(
				"Pocket",
				Vector3.new(0.5, 0.4, 0.05) * s,
				CFrame.new(-0.45 * s, 0.35 * s, -0.51 * s),
				Color3.fromRGB(0, 116, 128),
				rig.torso
			)
		end,
	},
	{
		name = "hoodie",
		torso = Color3.fromRGB(44, 46, 54),
		arms = Color3.fromRGB(44, 46, 54),
		legs = Color3.fromRGB(99, 95, 98),
		detail = function(rig, add)
			local s = rig.scale
			add(
				"Hood",
				Vector3.new(1.3, 0.55, 0.45) * s,
				CFrame.new(0, 0.78 * s, 0.62 * s),
				Color3.fromRGB(34, 36, 44),
				rig.torso
			)
			for _, side in { -1, 1 } do
				add(
					"String",
					Vector3.new(0.06, 0.6, 0.06) * s,
					CFrame.new(0.22 * side * s, 0.55 * s, -0.53 * s),
					WHITE,
					rig.torso
				)
			end
		end,
	},
}

-- Mara's own (outfit 0): a bright red coat, worn with a yellow scarf.
local MARA_COAT: OutfitSpec = {
	name = "redcoat",
	torso = Color3.fromRGB(214, 30, 36),
	arms = Color3.fromRGB(214, 30, 36),
	legs = BLACK,
	hem = true,
	detail = function(rig, add)
		local s = rig.scale
		for row = 0, 1 do
			add(
				"Button",
				Vector3.new(0.16, 0.16, 0.06) * s,
				CFrame.new(0, (0.35 - row * 0.5) * s, -0.52 * s),
				BLACK,
				rig.torso
			)
		end
	end,
}

Robloxian.Sizes = {
	outfits = #OUTFITS,
	skins = #SKINS,
	hairs = 5,
	hairColors = #HAIR_COLORS,
	hats = 6,
	scarves = #SCARVES,
	bags = 3,
	faces = 2,
}

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.Massless = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function motor(name: string, parent: Instance, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame)
	local joint = Instance.new("Motor6D")
	joint.Name = name
	joint.Part0 = part0
	joint.Part1 = part1
	joint.C0 = c0
	joint.C1 = c1
	joint.Parent = parent
end

-- The R6 body in the standard pose, standing with its feet at `feet`, facing `facing`.
local function body(feet: CFrame, s: number, skin: Color3, outfit: OutfitSpec): Rig
	local model = Instance.new("Model")
	local rootFrame = feet * CFrame.new(0, 3 * s, 0)

	local root = newPart("HumanoidRootPart", Vector3.new(2, 2, 1) * s, rootFrame, Color3.new(1, 1, 1))
	root.Transparency = 1
	root.Anchored = true
	root.CastShadow = false
	root.Parent = model
	model.PrimaryPart = root

	local torso = newPart("Torso", Vector3.new(2, 2, 1) * s, rootFrame, outfit.torso)
	local head = newPart("Head", Vector3.new(2, 1, 1) * s, rootFrame * CFrame.new(0, 1.5 * s, 0), skin)
	local armColor = outfit.arms or skin
	local rightArm = newPart("Right Arm", Vector3.new(1, 2, 1) * s, rootFrame * CFrame.new(1.5 * s, 0, 0), armColor)
	local leftArm = newPart("Left Arm", Vector3.new(1, 2, 1) * s, rootFrame * CFrame.new(-1.5 * s, 0, 0), armColor)
	local rightLeg =
		newPart("Right Leg", Vector3.new(1, 2, 1) * s, rootFrame * CFrame.new(0.5 * s, -2 * s, 0), outfit.legs)
	local leftLeg =
		newPart("Left Leg", Vector3.new(1, 2, 1) * s, rootFrame * CFrame.new(-0.5 * s, -2 * s, 0), outfit.legs)

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "Mesh"
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = FACE_TEXTURE
	face.Parent = head

	for _, p in { torso, head, rightArm, leftArm, rightLeg, leftLeg } do
		p.Parent = model
	end

	-- Roblox's standard R6 joint frames (as in its own dummy and player characters),
	-- with the offsets scaled.
	local function centre(x: number, y: number): CFrame
		return CFrame.new(x * s, y * s, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	end
	local function right(x: number, y: number): CFrame
		return CFrame.new(x * s, y * s, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
	end
	local function left(x: number, y: number): CFrame
		return CFrame.new(x * s, y * s, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
	end
	motor("RootJoint", root, root, torso, centre(0, 0), centre(0, 0))
	motor("Neck", torso, torso, head, centre(0, 1), centre(0, -0.5))
	motor("Right Shoulder", torso, torso, rightArm, right(1, 0.5), right(-0.5, 0.5))
	motor("Left Shoulder", torso, torso, leftArm, left(-1, 0.5), left(0.5, 0.5))
	motor("Right Hip", torso, torso, rightLeg, right(1, -1), right(0.5, 1))
	motor("Left Hip", torso, torso, leftLeg, left(-1, -1), left(-0.5, 1))

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.EvaluateStateMachine = false -- moved by script, anchored at the root
	humanoid.Parent = model

	local clothing: { BasePart } = { torso, rightLeg, leftLeg }
	local skinParts: { BasePart } = { head }
	for _, arm in { rightArm, leftArm } do
		table.insert(if outfit.arms then clothing else skinParts, arm)
	end
	return {
		model = model,
		root = root,
		torso = torso,
		head = head,
		leftArm = leftArm,
		rightArm = rightArm,
		leftLeg = leftLeg,
		rightLeg = rightLeg,
		humanoid = humanoid,
		scale = s,
		feet = 3 * s,
		clothing = clothing,
		skin = skinParts,
		hair = {},
		all = { torso, head, rightArm, leftArm, rightLeg, leftLeg },
		hem = nil,
	}
end

-- Adds a part welded to `on`, placed at `at` in that part's space.
local function adder(rig: Rig, into: { BasePart })
	return function(
		name: string,
		size: Vector3,
		at: CFrame,
		color: Color3,
		on: BasePart,
		material: Enum.Material?
	): Part
		local p = newPart(name, size, on.CFrame * at, color, material)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = on
		weld.Part1 = p
		weld.Parent = p
		p.Parent = rig.model
		table.insert(rig.all, p)
		table.insert(into, p)
		return p
	end
end

-- A copy of the head's shape, a little larger and set back, reads as hair or a hood.
local function shell(
	rig: Rig,
	name: string,
	color: Color3,
	grow: number,
	up: number,
	back: number,
	into: { BasePart }
): BasePart
	local s = rig.scale
	local p = adder(rig, into)(name, rig.head.Size, CFrame.new(0, up * s, back * s), color, rig.head)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25) * grow
	mesh.Parent = p
	return p
end

local function ball(p: BasePart)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
end

local function cylinderUp(): CFrame
	return CFrame.Angles(0, 0, math.rad(90))
end

local function hairOn(rig: Rig, style: number, color: Color3, hatted: boolean)
	if style == 0 then
		return
	end
	local s = rig.scale
	local add = adder(rig, rig.hair)
	if not hatted then
		shell(rig, "Hair", color, 1.1, 0.1, 0.12, rig.hair)
	end
	if style == 2 then -- long, down the back
		add("HairBack", Vector3.new(1.36, 1.1, 0.3) * s, CFrame.new(0, -0.15 * s, 0.55 * s), color, rig.head)
	elseif style == 3 and not hatted then -- bun
		local bun = add("Bun", Vector3.new(0.6, 0.6, 0.6) * s, CFrame.new(0, 0.58 * s, 0.38 * s), color, rig.head)
		ball(bun)
	elseif style == 4 and not hatted then -- spiky
		for i = -1, 1 do
			add(
				"Spike",
				Vector3.new(0.3, 0.3, 0.3) * s,
				CFrame.new(i * 0.32 * s, 0.72 * s, 0.05 * s) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
				color,
				rig.head
			)
		end
	elseif style == 5 then -- pigtails
		for _, side in { -1, 1 } do
			local tail = add(
				"Pigtail",
				Vector3.new(0.42, 0.42, 0.42) * s,
				CFrame.new(0.72 * side * s, -0.12 * s, 0.1 * s),
				color,
				rig.head
			)
			ball(tail)
		end
	end
end

local function hatOn(rig: Rig, style: number, color: Color3, outfit: OutfitSpec)
	if style == 0 then
		return
	end
	local s = rig.scale
	local add = adder(rig, rig.clothing)
	if style == 1 then -- knit beanie with a bobble
		add(
			"Beanie",
			Vector3.new(0.62, 1.34, 1.34) * s,
			CFrame.new(0, 0.5 * s, 0.04 * s) * cylinderUp(),
			color,
			rig.head
		).Shape =
			Enum.PartType.Cylinder
		ball(add("Bobble", Vector3.new(0.34, 0.34, 0.34) * s, CFrame.new(0, 0.9 * s, 0.04 * s), WHITE, rig.head))
	elseif style == 2 then -- baseball cap
		ball(add("Cap", Vector3.new(1.36, 0.7, 1.36) * s, CFrame.new(0, 0.46 * s, 0.02 * s), color, rig.head))
		add("Brim", Vector3.new(0.95, 0.07, 0.6) * s, CFrame.new(0, 0.42 * s, -0.78 * s), color, rig.head)
	elseif style == 3 then -- sou'wester, the fisherman's rain hat
		ball(add("Crown", Vector3.new(1.36, 0.76, 1.36) * s, CFrame.new(0, 0.46 * s, 0.04 * s), OILSKIN, rig.head))
		add(
			"Brim",
			Vector3.new(0.07, 1.95, 1.95) * s,
			CFrame.new(0, 0.26 * s, 0.18 * s) * CFrame.Angles(math.rad(-10), 0, 0) * cylinderUp(),
			OILSKIN,
			rig.head
		).Shape =
			Enum.PartType.Cylinder
	elseif style == 4 then -- top hat
		add("TopHat", Vector3.new(1.0, 0.98, 0.98) * s, CFrame.new(0, 1.0 * s, 0) * cylinderUp(), BLACK, rig.head).Shape =
			Enum.PartType.Cylinder
		add("Brim", Vector3.new(0.07, 1.5, 1.5) * s, CFrame.new(0, 0.54 * s, 0) * cylinderUp(), BLACK, rig.head).Shape =
			Enum.PartType.Cylinder
		add("Band", Vector3.new(0.18, 1.0, 1.0) * s, CFrame.new(0, 0.66 * s, 0) * cylinderUp(), color, rig.head).Shape =
			Enum.PartType.Cylinder
	elseif style == 5 then -- bucket hat
		add("Bucket", Vector3.new(0.5, 1.3, 1.3) * s, CFrame.new(0, 0.6 * s, 0.04 * s) * cylinderUp(), CANVAS, rig.head).Shape =
			Enum.PartType.Cylinder
		add(
			"Brim",
			Vector3.new(0.07, 1.75, 1.75) * s,
			CFrame.new(0, 0.38 * s, 0.04 * s) * cylinderUp(),
			CANVAS,
			rig.head
		).Shape =
			Enum.PartType.Cylinder
	elseif style == 6 then -- hood up
		shell(rig, "Hood", outfit.torso, 1.2, 0.12, 0.2, rig.clothing)
	end
end

local function bagOn(rig: Rig, style: number)
	if style == 0 then
		return
	end
	local s = rig.scale
	local add = adder(rig, rig.clothing)
	if style == 1 then -- suitcase, held
		add("Suitcase", Vector3.new(0.4, 1.0, 1.3) * s, CFrame.new(0, -1.55 * s, -0.1 * s), LEATHER, rig.rightArm)
		add("Handle", Vector3.new(0.12, 0.2, 0.4) * s, CFrame.new(0, -1.0 * s, -0.1 * s), BLACK, rig.rightArm)
	elseif style == 2 then -- backpack
		add(
			"Backpack",
			Vector3.new(1.5, 1.5, 0.7) * s,
			CFrame.new(0, 0.05 * s, 0.85 * s),
			Color3.fromRGB(52, 88, 60),
			rig.torso
		)
		for _, side in { -1, 1 } do
			add("Strap", Vector3.new(0.2, 1.1, 1.04) * s, CFrame.new(0.55 * side * s, 0.35 * s, 0), BLACK, rig.torso)
		end
	elseif style == 3 then -- tote bag on the left shoulder
		add(
			"Tote",
			Vector3.new(0.3, 0.9, 0.85) * s,
			CFrame.new(-0.62 * s, -0.25 * s, 0),
			CANVAS,
			rig.leftArm,
			Enum.Material.Fabric
		)
		add("ToteStrap", Vector3.new(0.14, 0.7, 0.14) * s, CFrame.new(-0.55 * s, 0.55 * s, 0), CANVAS, rig.leftArm)
	end
end

local function faceExtras(rig: Rig, style: number, hairColor: Color3)
	local s = rig.scale
	local add = adder(rig, rig.clothing)
	if style == 1 then -- glasses
		for _, side in { -1, 1 } do
			add(
				"Lens",
				Vector3.new(0.34, 0.28, 0.05) * s,
				CFrame.new(0.24 * side * s, 0.16 * s, -0.63 * s),
				BLACK,
				rig.head
			).Transparency =
				0.15
		end
		add("Bridge", Vector3.new(0.2, 0.05, 0.05) * s, CFrame.new(0, 0.18 * s, -0.64 * s), BLACK, rig.head)
	elseif style == 2 then -- moustache
		add("Moustache", Vector3.new(0.56, 0.12, 0.06) * s, CFrame.new(0, -0.06 * s, -0.63 * s), hairColor, rig.head)
	end
end

local function scarfOn(rig: Rig, color: Color3)
	local s = rig.scale
	local add = adder(rig, rig.clothing)
	add("Scarf", Vector3.new(1.5, 0.36, 1.24) * s, CFrame.new(0, 1.06 * s, 0), color, rig.torso, Enum.Material.Fabric)
	add(
		"ScarfEnd",
		Vector3.new(0.36, 0.9, 0.12) * s,
		CFrame.new(0.42 * s, 0.55 * s, -0.58 * s) * CFrame.Angles(0, 0, math.rad(-6)),
		color,
		rig.torso,
		Enum.Material.Fabric
	)
end

-- A classic Robloxian dressed from a Look (see Types.Look), standing at `feet`
-- facing `facing`. Outfit 0 is Mara's red coat.
function Robloxian.build(look: Look, feet: Vector3, facing: Vector3): Rig
	local s = look.height
	local frame = CFrame.lookAt(feet, feet + facing)
	local outfit = if look.outfit == 0 then MARA_COAT else OUTFITS[math.clamp(look.outfit, 1, #OUTFITS)]
	local skin = SKINS[math.clamp(look.skin, 1, #SKINS)]
	local rig = body(frame, s, skin, outfit)
	local add = adder(rig, rig.clothing)

	if outfit.hem then
		rig.hem = add("Hem", Vector3.new(2.04, 0.55, 1.04) * s, CFrame.new(0, -1.25 * s, 0), outfit.torso, rig.torso)
	end
	if outfit.detail then
		outfit.detail(rig, add)
	end
	local hairColor = HAIR_COLORS[math.clamp(look.hairColor, 1, #HAIR_COLORS)]
	local hatColor = HAT_COLORS[(look.hairColor + look.outfit) % #HAT_COLORS + 1]
	hairOn(rig, look.hair, hairColor, look.hat ~= 0)
	hatOn(rig, look.hat, hatColor, outfit)
	if look.scarf > 0 then
		scarfOn(rig, SCARVES[math.clamp(look.scarf, 1, #SCARVES)])
	end
	bagOn(rig, look.bag)
	faceExtras(rig, look.face, hairColor)
	return rig
end

return Robloxian
