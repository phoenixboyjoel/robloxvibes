--!strict
--[[
	WorldService: builds Gull Harbor from parts when the server starts, so the
	place needs no assets and the whole world lives in git.

	Layout (studs; dock surface at y = 0, the booth window faces -Z):
		camera              (0, 5.1, 3.4)   inside the booth, looking out
		passenger at window (0, 0, -3.2)    the planks closer than z ≈ -3.3 are hidden by the wall
		booth lamp          (-3.4, 8.3, -1) front-left, so each shadow falls back and to the
		                                    right, where the camera can see it
		queue               (-2, 0, -11) → (0.5, 0, -17) → (-1.5, 0, -23), fog beyond
		gate → gangway → Petrel, moored along the right edge of the dock
		lighthouse far front-left; the Marigold's ghost out in the fog

	The lighthouse beam is spun by each client (EffectsController) while the
	rotor's "Spinning" attribute is true, so it turns smoothly.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

export type Markers = {
	camera: CFrame,
	window: Vector3,
	queue: { Vector3 },
	spawn: Vector3,
	board: { Vector3 },
	away: { Vector3 },
	water: { Vector3 },
}

type PartProps = {
	name: string?,
	size: Vector3,
	cframe: CFrame,
	color: Color3?,
	material: Enum.Material?,
	transparency: number?,
	reflectance: number?,
	shape: Enum.PartType?,
	castShadow: boolean?,
	collide: boolean?,
	parent: Instance,
}

local WOOD = Color3.fromRGB(74, 60, 48)
local BOOTH_PAINT = Color3.fromRGB(52, 86, 84)
local TRIM = Color3.fromRGB(214, 205, 180)
local METAL = Color3.fromRGB(58, 60, 64)
local LAMP_WARM = Color3.fromRGB(255, 198, 132)
local LANTERN_LIT = Color3.fromRGB(255, 170, 70)
local LANTERN_OUT = Color3.fromRGB(40, 36, 32)
local BEACON = Color3.fromRGB(255, 236, 190)

local FERRY_HOME = CFrame.new(32.5, -1.5, -36) * CFrame.Angles(0, math.rad(90), 0)
local MARIGOLD_HOME = CFrame.new(-12, -1, -92) * CFrame.Angles(0, math.rad(20), 0)

local WorldService = {}

local markers: Markers
local ferry: Model
local ferryMover: CFrameValue
local ferryTween: Tween? = nil
local ferryLoad = 0
local lampLight: SpotLight
local lampBulb: BasePart
local lanterns: { BasePart } = {}
local lighthouseGlass: BasePart
local lighthouseGlow: PointLight
local lighthouseLight: SpotLight
local lighthouseBeam: BasePart
local lighthouseRotor: BasePart
local marigold: Model
local marigoldParts: { BasePart } = {}
local marigoldMover: CFrameValue
local marigoldTween: Tween? = nil
local sceneToken = 0 -- bumped on reset, so a late ending effect can't leak into the next run
local flood: BasePart
local passengers: Folder

local function part(props: PartProps): Part
	local p = Instance.new("Part")
	p.Name = props.name or "Part"
	p.Anchored = true
	p.CanCollide = props.collide == true
	p.CanTouch = false
	p.CanQuery = false
	if props.shape then
		p.Shape = props.shape
	end
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = props.color or METAL
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Transparency = props.transparency or 0
	p.Reflectance = props.reflectance or 0
	p.CastShadow = if props.castShadow == nil then true else props.castShadow
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = props.parent
	return p
end

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- A cylinder standing upright: Roblox cylinders run along X, so size.X is the height.
local function upright(position: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
end

local function sign(parent: BasePart, face: Enum.NormalId, text: string, textColor: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.6
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = textColor
	label.TextScaled = true
	label.FontFace = Font.fromEnum(Enum.Font.Oswald)
	label.Text = text
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = label
end

-- Moves a model by tweening a CFrameValue and pivoting the model to it.
local function mover(model: Model): CFrameValue
	local value = Instance.new("CFrameValue")
	value.Name = "Mover"
	value.Value = model:GetPivot()
	value.Changed:Connect(function(cframe: CFrame)
		model:PivotTo(cframe)
	end)
	value.Parent = model
	return value
end

local function setUpLighting()
	Lighting.ClockTime = 2
	Lighting.Brightness = 1.2
	Lighting.Ambient = Color3.fromRGB(26, 30, 38)
	Lighting.OutdoorAmbient = Color3.fromRGB(46, 54, 70)
	Lighting.EnvironmentDiffuseScale = 0.25
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ExposureCompensation = 0.25
	Lighting.GlobalShadows = true

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere == nil then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	local fog = atmosphere :: Atmosphere
	fog.Density = 0.36
	fog.Offset = 0.12
	fog.Color = Color3.fromRGB(150, 165, 182)
	fog.Decay = Color3.fromRGB(74, 84, 100)
	fog.Glare = 0
	fog.Haze = 2.4
end

local function setUpWater()
	local terrain = workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(22, 40, 44)
	terrain.WaterTransparency = 0.4
	terrain.WaterReflectance = 0.6
	terrain.WaterWaveSize = 0.15
	terrain.WaterWaveSpeed = 6
	-- Surface at y = -2, a stud below the planks.
	terrain:FillBlock(CFrame.new(0, -9, -120), Vector3.new(760, 14, 760), Enum.Material.Water)
end

local function buildDock(parent: Folder)
	local dock = folder("Dock", parent)
	-- Deck: planks running along Z so the lamp shadow reads clearly across them.
	-- Planks cover x -19.95..24.95 and z -62..8.
	for x = -20, 24, 2 do
		part({
			name = "Plank",
			size = Vector3.new(1.9, 1, 70),
			cframe = CFrame.new(x + 1, -0.5, -27),
			color = WOOD:Lerp(Color3.new(0, 0, 0), ((x // 2) % 3) * 0.06),
			material = Enum.Material.WoodPlanks,
			collide = true,
			parent = dock,
		})
	end
	-- Pilings into the water, poking a stud above the planks at the edges.
	for _, x in { -20, 25 } do
		for z = 6, -60, -8 do
			part({
				name = "Piling",
				size = Vector3.new(12, 1.4, 1.4),
				cframe = upright(Vector3.new(x, -5, z)),
				color = WOOD:Lerp(Color3.new(0, 0, 0), 0.35),
				material = Enum.Material.Wood,
				shape = Enum.PartType.Cylinder,
				parent = dock,
			})
		end
	end
	-- Queue rope: posts either side of the line with a dull rope between them.
	for _, x in { -4.5, 3.5 } do
		local previous: Vector3? = nil
		for z = -7, -27, -5 do
			local top = Vector3.new(x, 3, z)
			part({
				name = "Post",
				size = Vector3.new(3, 0.35, 0.35),
				cframe = upright(Vector3.new(x, 1.5, z)),
				color = METAL,
				material = Enum.Material.Metal,
				shape = Enum.PartType.Cylinder,
				parent = dock,
			})
			if previous then
				local mid = (previous + top) / 2
				part({
					name = "Rope",
					size = Vector3.new(0.12, 0.12, (top - previous).Magnitude),
					cframe = CFrame.lookAt(mid - Vector3.new(0, 0.15, 0), top),
					color = Color3.fromRGB(150, 124, 54),
					material = Enum.Material.Fabric,
					castShadow = false,
					parent = dock,
				})
			end
			previous = top
		end
	end
	-- Gate to the gangway.
	for _, x in { 6.5, 10 } do
		part({
			name = "GatePost",
			size = Vector3.new(0.4, 4, 0.4),
			cframe = CFrame.new(x, 2, -9),
			color = TRIM,
			parent = dock,
		})
	end
	local gateSign = part({
		name = "GateSign",
		size = Vector3.new(3.4, 0.9, 0.2),
		cframe = CFrame.new(8.25, 3.6, -9) * CFrame.Angles(0, math.rad(180), 0),
		color = Color3.fromRGB(28, 34, 44),
		parent = dock,
	})
	sign(gateSign, Enum.NormalId.Front, "GANGWAY · PETREL →", TRIM)
	-- Gangway from the dock up onto the Petrel's deck.
	local from, to = Vector3.new(17, 0.2, -20), Vector3.new(27, 2.05, -24.5)
	part({
		name = "Gangway",
		size = Vector3.new(2.4, 0.3, (to - from).Magnitude),
		cframe = CFrame.lookAt((from + to) / 2, to),
		color = METAL,
		material = Enum.Material.DiamondPlate,
		parent = dock,
	})
end

local function buildBooth(parent: Folder): CFrame
	local booth = folder("Booth", parent)
	part({
		name = "Floor",
		size = Vector3.new(10, 0.2, 8),
		cframe = CFrame.new(0, 0.1, 4),
		color = Color3.fromRGB(60, 52, 46),
		material = Enum.Material.Wood,
		collide = true,
		parent = booth,
	})
	local walls = {
		{ Vector3.new(10, 2.5, 0.4), Vector3.new(0, 1.25, 0) }, -- below the window (sill at 2.5)
		{ Vector3.new(10, 1.3, 0.4), Vector3.new(0, 7.55, 0) }, -- above the window (top at 6.9)
		{ Vector3.new(1.8, 4.4, 0.4), Vector3.new(-4.1, 4.7, 0) },
		{ Vector3.new(1.8, 4.4, 0.4), Vector3.new(4.1, 4.7, 0) },
		{ Vector3.new(0.4, 8.2, 8), Vector3.new(-5, 4.1, 4) },
		{ Vector3.new(0.4, 8.2, 8), Vector3.new(5, 4.1, 4) },
		{ Vector3.new(10, 8.2, 0.4), Vector3.new(0, 4.1, 8) },
	}
	for _, wall in walls do
		part({
			name = "Wall",
			size = wall[1],
			cframe = CFrame.new(wall[2]),
			color = BOOTH_PAINT,
			material = Enum.Material.WoodPlanks,
			parent = booth,
		})
	end
	part({
		name = "Roof",
		size = Vector3.new(11.5, 0.6, 9.6),
		cframe = CFrame.new(0, 8.5, 3.8),
		color = Color3.fromRGB(38, 42, 48),
		material = Enum.Material.Slate,
		parent = booth,
	})
	-- Window frame and glass.
	for _, trim in
		{
			{ Vector3.new(6.8, 0.25, 0.5), Vector3.new(0, 2.45, -0.05) },
			{ Vector3.new(6.8, 0.25, 0.5), Vector3.new(0, 6.95, -0.05) },
			{ Vector3.new(0.25, 4.4, 0.5), Vector3.new(-3.3, 4.7, -0.05) },
			{ Vector3.new(0.25, 4.4, 0.5), Vector3.new(3.3, 4.7, -0.05) },
		}
	do
		part({ name = "Trim", size = trim[1], cframe = CFrame.new(trim[2]), color = TRIM, parent = booth })
	end
	part({
		name = "Glass",
		size = Vector3.new(6.4, 4.4, 0.08),
		cframe = CFrame.new(0, 4.7, -0.1),
		color = Color3.fromRGB(170, 200, 210),
		transparency = 0.93,
		reflectance = 0.04,
		castShadow = false,
		parent = booth,
	})
	-- Counter, with the booth's own warm light.
	local counter = part({
		name = "Counter",
		size = Vector3.new(9.2, 0.3, 1.6),
		cframe = CFrame.new(0, 2.5, 0.95),
		color = Color3.fromRGB(96, 74, 58),
		material = Enum.Material.Wood,
		parent = booth,
	})
	local interior = Instance.new("PointLight")
	interior.Color = LAMP_WARM
	interior.Brightness = 0.5
	interior.Range = 9
	interior.Shadows = false
	interior.Parent = counter
	-- Three lanterns on the counter: one goes out for each mistake.
	table.clear(lanterns)
	for i = 1, 3 do
		local x = -3.9 + (i - 1) * 0.7
		part({
			name = "LanternBase",
			size = Vector3.new(0.45, 0.12, 0.45),
			cframe = CFrame.new(x, 2.71, 1.1),
			color = METAL,
			parent = booth,
		})
		local glass = part({
			name = `Lantern{i}`,
			size = Vector3.new(0.35, 0.5, 0.35),
			cframe = CFrame.new(x, 3.02, 1.1),
			color = LANTERN_LIT,
			material = Enum.Material.Neon,
			castShadow = false,
			parent = booth,
		})
		table.insert(lanterns, glass)
	end
	-- A radio, for Pike.
	part({
		name = "Radio",
		size = Vector3.new(1.1, 0.6, 0.6),
		cframe = CFrame.new(3.3, 2.95, 1.2),
		color = Color3.fromRGB(64, 58, 50),
		parent = booth,
	})
	part({
		name = "Antenna",
		size = Vector3.new(0.06, 1.2, 0.06),
		cframe = CFrame.new(3.6, 3.8, 1.3) * CFrame.Angles(0, 0, math.rad(-18)),
		color = METAL,
		parent = booth,
	})
	-- Outside: the sign above the window and the lamp that lights the passenger.
	local boothSign = part({
		name = "Sign",
		size = Vector3.new(8, 1.1, 0.2),
		cframe = CFrame.new(0, 8.9, -0.35),
		color = Color3.fromRGB(28, 34, 44),
		parent = booth,
	})
	sign(boothSign, Enum.NormalId.Front, "GULL HARBOR · NIGHT FERRY TICKETS", TRIM)
	part({
		name = "LampArm",
		size = Vector3.new(0.2, 0.2, 0.8),
		cframe = CFrame.new(-3.4, 8.15, -0.6),
		color = METAL,
		parent = booth,
	})
	-- Front-left of the passenger and above their head: the shadow falls back and to the
	-- right across the planks, clear of their own body as seen from the booth. The wall
	-- above the window hides the bulb itself from the camera.
	lampBulb = part({
		name = "LampBulb",
		size = Vector3.new(0.6, 0.3, 0.6),
		cframe = CFrame.lookAt(Vector3.new(-3.4, 8.1, -1.05), Vector3.new(1.2, 0, -4.6)),
		color = LAMP_WARM,
		material = Enum.Material.Neon,
		castShadow = false,
		parent = booth,
	})
	lampLight = Instance.new("SpotLight")
	lampLight.Face = Enum.NormalId.Front
	lampLight.Angle = 80
	lampLight.Range = 26
	lampLight.Brightness = 4
	lampLight.Color = LAMP_WARM
	lampLight.Shadows = true
	lampLight.Parent = lampBulb

	local cameraCFrame = CFrame.lookAt(Vector3.new(0, 5.1, 3.4), Vector3.new(0, 4.4, -4))
	part({
		name = "CameraAnchor",
		size = Vector3.new(0.2, 0.2, 0.2),
		cframe = cameraCFrame,
		transparency = 1,
		castShadow = false,
		parent = booth,
	})
	return cameraCFrame
end

local function buildFerry(parent: Folder)
	-- Moored along the dock's right edge, bow out into the fog (the hull's +X is world -Z).
	ferry = Instance.new("Model")
	ferry.Name = "Petrel"
	local hull = part({
		name = "Hull",
		size = Vector3.new(44, 6, 12),
		cframe = FERRY_HOME,
		color = Color3.fromRGB(214, 218, 220),
		parent = ferry,
	})
	part({
		name = "Stripe",
		size = Vector3.new(44.2, 0.8, 12.2),
		cframe = FERRY_HOME * CFrame.new(0, 1.4, 0),
		color = Color3.fromRGB(30, 48, 82),
		parent = ferry,
	})
	part({
		name = "Deck",
		size = Vector3.new(42, 0.4, 11),
		cframe = FERRY_HOME * CFrame.new(0, 3.2, 0),
		color = Color3.fromRGB(70, 74, 80),
		parent = ferry,
	})
	local cabin = part({
		name = "Cabin",
		size = Vector3.new(22, 5, 8),
		cframe = FERRY_HOME * CFrame.new(2, 5.9, 0),
		color = Color3.fromRGB(226, 228, 230),
		parent = ferry,
	})
	for i = -4, 4 do
		for _, side in { -1, 1 } do
			part({
				name = "Window",
				size = Vector3.new(1.4, 1.1, 0.1),
				cframe = cabin.CFrame * CFrame.new(i * 2.3, 0.6, side * 4.02),
				color = Color3.fromRGB(255, 214, 150),
				material = Enum.Material.Neon,
				castShadow = false,
				parent = ferry,
			})
		end
	end
	part({
		name = "Funnel",
		size = Vector3.new(3, 4, 3),
		cframe = FERRY_HOME * CFrame.new(-6, 10.4, 0),
		color = Color3.fromRGB(30, 48, 82),
		parent = ferry,
	})
	-- Name on the side facing the dock (the hull's -Z face points at world -X).
	local namePlate = part({
		name = "NamePlate",
		size = Vector3.new(10, 1.6, 0.1),
		cframe = FERRY_HOME * CFrame.new(-6, 0, -6.06),
		transparency = 1,
		castShadow = false,
		parent = ferry,
	})
	sign(namePlate, Enum.NormalId.Front, "PETREL", Color3.fromRGB(30, 48, 82))
	ferry.PrimaryPart = hull
	ferry.Parent = parent
	ferryMover = mover(ferry)
end

local function buildLighthouse(parent: Folder)
	local lighthouse = folder("Lighthouse", parent)
	local base = Vector3.new(-60, 0, -130)
	part({
		name = "Rock",
		size = Vector3.new(30, 14, 26),
		cframe = CFrame.new(base + Vector3.new(0, -6, 0)),
		color = Color3.fromRGB(52, 54, 56),
		material = Enum.Material.Rock,
		parent = lighthouse,
	})
	for band = 0, 5 do
		part({
			name = "Tower",
			size = Vector3.new(8, 7.6 - band * 0.35, 7.6 - band * 0.35),
			cframe = upright(base + Vector3.new(0, 1 + band * 8 + 4, 0)),
			color = if band % 2 == 0 then Color3.fromRGB(220, 218, 210) else Color3.fromRGB(150, 44, 40),
			shape = Enum.PartType.Cylinder,
			parent = lighthouse,
		})
	end
	lighthouseGlass = part({
		name = "LampRoom",
		size = Vector3.new(4, 5, 5),
		cframe = upright(base + Vector3.new(0, 51, 0)),
		color = Color3.fromRGB(40, 44, 48),
		material = Enum.Material.Glass,
		transparency = 0.2,
		shape = Enum.PartType.Cylinder,
		parent = lighthouse,
	})
	lighthouseGlow = Instance.new("PointLight")
	lighthouseGlow.Color = BEACON
	lighthouseGlow.Brightness = 3
	lighthouseGlow.Range = 40
	lighthouseGlow.Enabled = false
	lighthouseGlow.Parent = lighthouseGlass

	lighthouseRotor = part({
		name = "Rotor",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.new(base + Vector3.new(0, 51, 0)),
		transparency = 1,
		castShadow = false,
		parent = lighthouse,
	})
	lighthouseRotor:SetAttribute("Spinning", false)
	lighthouseLight = Instance.new("SpotLight")
	lighthouseLight.Face = Enum.NormalId.Front
	lighthouseLight.Angle = 20
	lighthouseLight.Range = 60
	lighthouseLight.Brightness = 8
	lighthouseLight.Color = BEACON
	lighthouseLight.Enabled = false
	lighthouseLight.Parent = lighthouseRotor

	-- The beam you see sweeping through the fog. Clients turn it with the rotor, keeping
	-- its near end a stud in front of the rotor.
	lighthouseBeam = part({
		name = "Beam",
		size = Vector3.new(3, 3, 110),
		cframe = lighthouseRotor.CFrame * CFrame.new(0, 0, -56),
		color = BEACON,
		material = Enum.Material.Neon,
		transparency = 1,
		castShadow = false,
		parent = lighthouse,
	})
end

local function buildMarigold(parent: Folder)
	marigold = Instance.new("Model")
	marigold.Name = "Marigold"
	local ghost = Color3.fromRGB(190, 225, 215)
	local hull = part({
		name = "Hull",
		size = Vector3.new(30, 5, 9),
		cframe = MARIGOLD_HOME,
		color = ghost,
		material = Enum.Material.Neon,
		transparency = 1,
		castShadow = false,
		parent = marigold,
	})
	local cabin = part({
		name = "Cabin",
		size = Vector3.new(14, 4, 6),
		cframe = MARIGOLD_HOME * CFrame.new(-2, 4.5, 0),
		color = ghost,
		material = Enum.Material.Neon,
		transparency = 1,
		castShadow = false,
		parent = marigold,
	})
	local mast = part({
		name = "Mast",
		size = Vector3.new(0.5, 9, 0.5),
		cframe = MARIGOLD_HOME * CFrame.new(6, 7, 0),
		color = ghost,
		material = Enum.Material.Neon,
		transparency = 1,
		castShadow = false,
		parent = marigold,
	})
	marigoldParts = { hull, cabin, mast }
	marigold.PrimaryPart = hull
	marigold.Parent = parent
	marigoldMover = mover(marigold)
end

local function buildFlood(parent: Folder)
	-- Rises inside the booth when a night is lost.
	flood = part({
		name = "Flood",
		size = Vector3.new(9.6, 0.2, 7.6),
		cframe = CFrame.new(0, 0.1, 4),
		color = Color3.fromRGB(20, 44, 50),
		material = Enum.Material.Glass,
		transparency = 1,
		reflectance = 0.2,
		castShadow = false,
		parent = parent,
	})
end

local function moveFerry(target: CFrame, seconds: number, style: Enum.EasingStyle, direction: Enum.EasingDirection)
	if ferryTween then
		ferryTween:Cancel()
	end
	local tween = TweenService:Create(ferryMover, TweenInfo.new(seconds, style, direction), { Value = target })
	ferryTween = tween
	tween:Play()
end

-- Where the Petrel sits at the dock with this many of the drowned aboard.
local function mooredAt(load: number): CFrame
	local n = math.min(load, 8)
	return FERRY_HOME * CFrame.new(0, -0.45 * n, 0) * CFrame.Angles(math.rad(0.6 * n), 0, 0)
end

function WorldService.build(): Markers
	for _, name in { "Baseplate", "SpawnLocation" } do
		local leftover = workspace:FindFirstChild(name)
		if leftover then
			leftover:Destroy()
		end
	end

	local world = folder("World", workspace)
	setUpLighting()
	setUpWater()
	buildDock(world)
	local cameraCFrame = buildBooth(world)
	buildFerry(world)
	buildLighthouse(world)
	buildMarigold(world)
	buildFlood(world)
	passengers = folder("Passengers", world)

	-- Paths are at foot level. Exits leave the queue lane in front of the first rope
	-- posts (z = -7), so nobody walks through the ropes.
	markers = {
		camera = cameraCFrame,
		window = Vector3.new(0, 0, -3.2),
		queue = { Vector3.new(-2, 0, -11), Vector3.new(0.5, 0, -17), Vector3.new(-1.5, 0, -23) },
		spawn = Vector3.new(-4, 0, -50),
		board = {
			Vector3.new(4.5, 0, -5.6),
			Vector3.new(8.25, 0, -8.2),
			Vector3.new(8.25, 0, -10.5), -- through the gate
			Vector3.new(17, 0.35, -20),
			Vector3.new(27, 2.2, -24.5), -- top of the gangway
			Vector3.new(30, 1.9, -25.5),
		},
		away = { Vector3.new(-6, 0, -5), Vector3.new(-8.5, 0, -30), Vector3.new(-7, 0, -56) },
		water = { Vector3.new(-6, 0, -5), Vector3.new(-18.6, 0, -21), Vector3.new(-21.4, -1.2, -21.4) },
	}

	-- The lamp over the window flickers now and then. It means nothing, and players will
	-- wonder whether it does.
	task.spawn(function()
		while true do
			task.wait(10 + math.random() * 18)
			for _ = 1, math.random(2, 4) do
				lampLight.Brightness = 1
				lampBulb.Transparency = 0.6
				task.wait(0.05 + math.random() * 0.1)
				lampLight.Brightness = 4
				lampBulb.Transparency = 0
				task.wait(0.05 + math.random() * 0.2)
			end
		end
	end)

	return markers
end

function WorldService.markers(): Markers
	return markers
end

function WorldService.passengerFolder(): Folder
	return passengers
end

function WorldService.setLanterns(lit: number)
	for i, glass in lanterns do
		local on = i <= lit
		glass.Color = if on then LANTERN_LIT else LANTERN_OUT
		glass.Material = if on then Enum.Material.Neon else Enum.Material.Glass
	end
end

-- Each drowned passenger aboard makes the Petrel sit a little lower in the water.
function WorldService.setFerryLoad(drownedAboard: number)
	if drownedAboard == ferryLoad then
		return
	end
	ferryLoad = drownedAboard
	moveFerry(mooredAt(drownedAboard), 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
end

function WorldService.setLighthouse(on: boolean)
	lighthouseRotor:SetAttribute("Spinning", on)
	lighthouseLight.Enabled = on
	lighthouseGlow.Enabled = on
	lighthouseBeam.Transparency = if on then 0.85 else 1
	lighthouseGlass.Material = if on then Enum.Material.Neon else Enum.Material.Glass
	lighthouseGlass.Color = if on then BEACON else Color3.fromRGB(40, 44, 48)
end

-- The old ferry fades up out of the fog, then sails away.
local function showMarigold(token: number)
	for _, p in marigoldParts do
		TweenService:Create(p, TweenInfo.new(4, Enum.EasingStyle.Sine), { Transparency = 0.55 }):Play()
	end
	task.delay(6, function()
		if sceneToken ~= token then
			return
		end
		local tween = TweenService:Create(
			marigoldMover,
			TweenInfo.new(40, Enum.EasingStyle.Linear),
			{ Value = MARIGOLD_HOME * CFrame.new(-120, 0, 0) }
		)
		marigoldTween = tween
		tween:Play()
	end)
end

-- Five in the morning: the Petrel leaves, and the ending decides what else happens.
function WorldService.endingScene(ending: string)
	sceneToken += 1
	local token = sceneToken
	if ending == "CLEAN_SHIFT" or ending == "MARA_HOME" then
		WorldService.setLighthouse(true)
	end
	if ending == "MARA_HOME" then
		showMarigold(token)
	end
	task.delay(4, function()
		if sceneToken == token then
			-- Out along the hull's length, bow first into the fog.
			moveFerry(mooredAt(ferryLoad) * CFrame.new(110, 0, 0), 50, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end)
end

function WorldService.setFlood(on: boolean)
	local cframe = if on then CFrame.new(0, 1.8, 4) else CFrame.new(0, 0.1, 4)
	TweenService:Create(flood, TweenInfo.new(if on then 4 else 1, Enum.EasingStyle.Sine), {
		CFrame = cframe,
		Transparency = if on then 0.25 else 1,
	}):Play()
end

-- Back to the start of a run: lanterns lit, the Petrel moored and empty, the lighthouse
-- dark, and no ghost ship.
function WorldService.reset()
	WorldService.setLanterns(3)
	WorldService.setLighthouse(false)
	WorldService.setFlood(false)
	ferryLoad = 0
	if ferryTween then
		ferryTween:Cancel()
		ferryTween = nil
	end
	ferryMover.Value = FERRY_HOME
	sceneToken += 1
	if marigoldTween then
		marigoldTween:Cancel()
		marigoldTween = nil
	end
	marigoldMover.Value = MARIGOLD_HOME
	for _, p in marigoldParts do
		p.Transparency = 1
	end
end

return WorldService
