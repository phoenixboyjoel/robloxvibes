--!strict
--[[
	WorldService: builds Gull Harbor from parts when the server starts, so the
	place needs no assets and the whole world lives in git.

	Layout (studs; dock surface at y = 0, the booth window faces -Z):
		camera              (0, 5.1, 3.4)       inside the booth, looking out
		passenger at window (0, 0, -3.2)        the sill hides the planks closer than z ≈ -4.1,
		                                        so their feet, but not what's behind them
		booth lamp          (-3.4, 8.1, -1.05)  front-left, so each shadow falls back and to the
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
	pier: Vector3, -- where players arrive, on the pier behind the booth
	stands: { CFrame }, -- where players stand in the booth for a shift, facing the window
	window: Vector3,
	queue: { Vector3 },
	spawn: Vector3,
	board: { Vector3 },
	away: { Vector3 },
	water: { Vector3 },
	lamp: Vector3,
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

-- A Roblox night: bold, saturated colours that still read on phones, where the
-- engine drops shadows and most of the lighting at low graphics quality.
local WOOD = Color3.fromRGB(110, 82, 58)
local BOOTH_PAINT = Color3.fromRGB(24, 128, 120) -- harbor teal ("It was blue then.")
local TRIM = Color3.fromRGB(242, 243, 243)
local ROOF = Color3.fromRGB(196, 40, 28)
local METAL = Color3.fromRGB(58, 60, 64)
local BUOY_RED = Color3.fromRGB(214, 36, 30)
local BUOY_GREEN = Color3.fromRGB(40, 160, 70)
local SIGN_NEON = Color3.fromRGB(255, 176, 72)
local LAMP_WARM = Color3.fromRGB(255, 198, 132)
local LANTERN_LIT = Color3.fromRGB(255, 170, 70)
local LANTERN_OUT = Color3.fromRGB(40, 36, 32)
local BEACON = Color3.fromRGB(255, 236, 190)

local FERRY_HOME = CFrame.new(32.5, -1.5, -36) * CFrame.Angles(0, math.rad(90), 0)
local MARIGOLD_HOME = CFrame.new(-12, -1, -92) * CFrame.Angles(0, math.rad(20), 0)

local WorldService = {}

local markers: Markers
local clockPrompt: ProximityPrompt
local pierSpawn: SpawnLocation
local boothSpawn: SpawnLocation
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
local marigoldFades: { Tween } = {}
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

-- An invisible wall that keeps players where they belong (taller than a jump).
local function barrier(parent: Instance, size: Vector3, cframe: CFrame)
	local wall = part({
		name = "Barrier",
		size = size,
		cframe = cframe,
		transparency = 1,
		castShadow = false,
		collide = true,
		parent = parent,
	})
	wall.CanQuery = false
end

-- A white rail fence from `a` to `b` (on the planks), with posts every few studs.
local function railing(parent: Instance, a: Vector3, b: Vector3, color: Color3?)
	local span = b - a
	local length = span.Magnitude
	local steps = math.max(1, math.floor(length / 3))
	for i = 0, steps do
		local at = a + span * (i / steps)
		part({
			name = "RailPost",
			size = Vector3.new(0.3, 1.8, 0.3),
			cframe = CFrame.new(at + Vector3.new(0, 0.9, 0)),
			color = color or TRIM,
			parent = parent,
		})
	end
	for _, y in { 0.9, 1.7 } do
		part({
			name = "Rail",
			size = Vector3.new(0.18, 0.18, length),
			cframe = CFrame.lookAt((a + b) / 2 + Vector3.new(0, y, 0), b + Vector3.new(0, y, 0)),
			color = color or TRIM,
			parent = parent,
		})
	end
end

-- A red-and-white lifebuoy ring, standing on its edge, facing `facing`.
local function lifebuoy(parent: Instance, centre: Vector3, facing: Vector3)
	local frame = CFrame.lookAt(centre, centre + facing)
	for i = 0, 7 do
		local angle = i * math.pi / 4
		part({
			name = "Lifebuoy",
			size = Vector3.new(0.55, 0.62, 0.34),
			cframe = frame * CFrame.Angles(0, 0, angle) * CFrame.new(0, 0.62, 0),
			color = if i % 2 == 0 then BUOY_RED else TRIM,
			parent = parent,
		})
	end
end

local function bollard(parent: Instance, at: Vector3)
	part({
		name = "Bollard",
		size = Vector3.new(1.1, 0.9, 0.9),
		cframe = upright(at + Vector3.new(0, 0.55, 0)),
		color = Color3.fromRGB(34, 36, 40),
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
	part({
		name = "BollardCap",
		size = Vector3.new(0.25, 1.2, 1.2),
		cframe = upright(at + Vector3.new(0, 1.15, 0)),
		color = Color3.fromRGB(34, 36, 40),
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
end

-- A channel buoy bobbing out on the water, with a blinking top.
local function channelBuoy(parent: Instance, at: Vector3, color: Color3)
	part({
		name = "Buoy",
		size = Vector3.new(2.6, 1.6, 1.6),
		cframe = upright(at + Vector3.new(0, 0.6, 0)),
		color = color,
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
	part({
		name = "BuoyCone",
		size = Vector3.new(1.4, 0.9, 0.9),
		cframe = upright(at + Vector3.new(0, 2.5, 0)),
		color = color,
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
	local light = part({
		name = "BuoyLight",
		size = Vector3.new(0.5, 0.5, 0.5),
		cframe = CFrame.new(at + Vector3.new(0, 3.4, 0)),
		color = color,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		castShadow = false,
		parent = parent,
	})
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Brightness = 1.5
	glow.Range = 10
	glow.Parent = light
	light:SetAttribute("Blink", true)
end

type GullPiece = { name: string, size: Vector3, at: CFrame, color: Color3 }

local GULL_GREY = Color3.fromRGB(163, 162, 165)
local GULL_LEGS = Color3.fromRGB(218, 133, 65)
local GULL: { GullPiece } = {
	{ name = "GullBody", size = Vector3.new(0.7, 0.6, 1.2), at = CFrame.new(0, 0.55, 0), color = TRIM },
	{ name = "GullHead", size = Vector3.new(0.45, 0.45, 0.45), at = CFrame.new(0, 1.0, -0.5), color = TRIM },
	{
		name = "GullBeak",
		size = Vector3.new(0.14, 0.14, 0.34),
		at = CFrame.new(0, 0.95, -0.85),
		color = Color3.fromRGB(245, 205, 48),
	},
	{ name = "GullWing", size = Vector3.new(0.12, 0.42, 0.95), at = CFrame.new(-0.4, 0.6, 0.05), color = GULL_GREY },
	{ name = "GullWing", size = Vector3.new(0.12, 0.42, 0.95), at = CFrame.new(0.4, 0.6, 0.05), color = GULL_GREY },
	{
		name = "GullTail",
		size = Vector3.new(0.5, 0.12, 0.45),
		at = CFrame.new(0, 0.7, 0.75),
		color = Color3.fromRGB(27, 42, 53),
	},
	{ name = "GullLeg", size = Vector3.new(0.08, 0.3, 0.08), at = CFrame.new(-0.15, 0.15, 0), color = GULL_LEGS },
	{ name = "GullLeg", size = Vector3.new(0.08, 0.3, 0.08), at = CFrame.new(0.15, 0.15, 0), color = GULL_LEGS },
}

-- A blocky gull perched at `at`, looking along `facing`. Pure decoration: no shadow.
local function seagull(parent: Instance, at: Vector3, facing: Vector3)
	local frame = CFrame.lookAt(at, at + facing)
	for _, piece in GULL do
		part({
			name = piece.name,
			size = piece.size,
			cframe = frame * piece.at,
			color = piece.color,
			castShadow = false,
			parent = parent,
		})
	end
end

local function lampPost(parent: Instance, at: Vector3)
	part({
		name = "LampPost",
		size = Vector3.new(7, 0.35, 0.35),
		cframe = upright(at + Vector3.new(0, 3.5, 0)),
		color = Color3.fromRGB(34, 36, 40),
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
	local lamp = part({
		name = "LampGlobe",
		size = Vector3.new(0.9, 0.9, 0.9),
		cframe = CFrame.new(at + Vector3.new(0, 7.3, 0)),
		color = Color3.fromRGB(255, 214, 150),
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		castShadow = false,
		parent = parent,
	})
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 198, 132)
	light.Brightness = 1.4
	light.Range = 18
	light.Parent = lamp
end

local function bench(parent: Instance, at: Vector3, facing: Vector3)
	local frame = CFrame.lookAt(at, at + facing)
	part({
		name = "BenchSeat",
		size = Vector3.new(4, 0.3, 1.3),
		cframe = frame * CFrame.new(0, 1.3, 0),
		color = WOOD,
		material = Enum.Material.WoodPlanks,
		collide = true,
		parent = parent,
	})
	part({
		name = "BenchBack",
		size = Vector3.new(4, 1.2, 0.25),
		cframe = frame * CFrame.new(0, 2.1, 0.55),
		color = WOOD,
		material = Enum.Material.WoodPlanks,
		collide = true,
		parent = parent,
	})
	for _, x in { -1.7, 1.7 } do
		part({
			name = "BenchLeg",
			size = Vector3.new(0.25, 1.2, 1.2),
			cframe = frame * CFrame.new(x, 0.6, 0),
			color = Color3.fromRGB(34, 36, 40),
			parent = parent,
		})
	end
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
	-- Three in the morning under a big moon: dark, but bright enough that faces,
	-- coats and colours read at every graphics quality.
	Lighting.ClockTime = 3
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(62, 68, 92)
	Lighting.OutdoorAmbient = Color3.fromRGB(92, 106, 142)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ExposureCompensation = 0.35
	Lighting.GlobalShadows = true
	-- The shadow rule needs crisp local-light shadows, and needs them kept when a
	-- device lowers its quality level. (The project file sets these too.)
	Lighting.LightingStyle = Enum.LightingStyle.Realistic
	Lighting.PrioritizeLightingQuality = true
	Lighting.ShadowSoftness = 0.15

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere == nil then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	local fog = atmosphere :: Atmosphere
	fog.Density = 0.3
	fog.Offset = 0.2
	fog.Color = Color3.fromRGB(118, 146, 186)
	fog.Decay = Color3.fromRGB(56, 76, 118)
	fog.Glare = 0.15
	fog.Haze = 1.2

	-- Stars and a big moon; the sky textures are Roblox's built-in ones.
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky == nil then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	local night = sky :: Sky
	night.StarCount = 3000
	night.MoonAngularSize = 16
	night.CelestialBodiesShown = true

	-- Neon signs, lanterns and lit windows glow.
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom == nil then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	local glow = bloom :: BloomEffect
	glow.Intensity = 0.7
	glow.Size = 28
	glow.Threshold = 1.4
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
	-- Queue rope: posts either side of the line with a dull rope between them. None of it
	-- casts a shadow, so the only shadows on the planks by the window are passengers'.
	local sag = Vector3.new(0, 0.15, 0)
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
				castShadow = false,
				parent = dock,
			})
			if previous then
				local mid = (previous + top) / 2
				part({
					name = "Rope",
					size = Vector3.new(0.12, 0.12, (top - previous).Magnitude),
					cframe = CFrame.lookAt(mid - sag, top - sag),
					color = Color3.fromRGB(150, 124, 54),
					material = Enum.Material.Fabric,
					castShadow = false,
					parent = dock,
				})
			end
			previous = top
		end
	end
	-- Gate to the gangway: taller and wider than any passenger, so nobody clips it.
	for _, x in { 5.9, 10.6 } do
		part({
			name = "GatePost",
			size = Vector3.new(0.4, 7, 0.4),
			cframe = CFrame.new(x, 3.5, -9),
			color = TRIM,
			castShadow = false,
			parent = dock,
		})
	end
	local gateSign = part({
		name = "GateSign",
		size = Vector3.new(4.9, 0.9, 0.2),
		cframe = CFrame.new(8.25, 6.6, -9) * CFrame.Angles(0, math.rad(180), 0),
		color = Color3.fromRGB(28, 34, 44),
		castShadow = false,
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

	-- Harbor furniture, in bold colours that read from the booth even on phones.
	-- None of it stands in the queue lane or on a passenger's way to the ferry,
	-- the fog or the water.
	lifebuoy(dock, Vector3.new(5.9, 3.4, -8.72), Vector3.zAxis)
	lifebuoy(dock, Vector3.new(-12, 2.2, -5.2), Vector3.new(1, 0, 0.6))
	part({
		name = "BuoyStand",
		size = Vector3.new(0.3, 3, 0.3),
		cframe = CFrame.new(-12.3, 1.5, -5.4),
		color = TRIM,
		parent = dock,
	})
	for z = -6, -54, -8 do
		if z > -14 or z < -28 then
			bollard(dock, Vector3.new(23.8, 0, z))
		end
	end
	seagull(dock, Vector3.new(-20, 1, -10), Vector3.new(1, 0, 0.3))
	seagull(dock, Vector3.new(25, 1, -42), Vector3.new(-1, 0, 0.5))
	channelBuoy(dock, Vector3.new(-34, -2.3, -46), BUOY_RED)
	channelBuoy(dock, Vector3.new(-40, -2.3, -84), BUOY_GREEN)
	channelBuoy(dock, Vector3.new(44, -2.3, -70), BUOY_GREEN)
end

-- An invisible spawn pad whose top is at the given frame's top face: characters appear
-- standing on it. No force field (Duration 0), and nobody bumps into it.
local function spawnPad(name: string, size: Vector3, cframe: CFrame, parent: Instance): SpawnLocation
	local pad = Instance.new("SpawnLocation")
	pad.Name = name
	pad.Size = size
	pad.CFrame = cframe
	pad.Anchored = true
	pad.CanCollide = false
	pad.CanTouch = false
	pad.CanQuery = false
	pad.Transparency = 1
	pad.CastShadow = false
	pad.Neutral = true
	pad.Duration = 0
	pad.Parent = parent
	return pad
end

-- The pier behind the booth, where players arrive as their avatars before a shift
-- (the "lobby"). Railings and invisible walls keep them off the passengers' dock and
-- out of the water; the booth's back door is the way in.
local function buildPier(parent: Folder): Vector3
	local pier = folder("Pier", parent)
	for x = -14, 12, 2 do
		part({
			name = "Plank",
			size = Vector3.new(1.9, 1, 38),
			cframe = CFrame.new(x + 1, -0.5, 27),
			color = WOOD:Lerp(Color3.new(0, 0, 0), ((x // 2) % 3) * 0.06),
			material = Enum.Material.WoodPlanks,
			collide = true,
			parent = pier,
		})
	end
	for _, x in { -14.5, 14.5 } do
		for z = 14, 46, 8 do
			part({
				name = "Piling",
				size = Vector3.new(12, 1.4, 1.4),
				cframe = upright(Vector3.new(x, -5, z)),
				color = WOOD:Lerp(Color3.new(0, 0, 0), 0.35),
				material = Enum.Material.Wood,
				shape = Enum.PartType.Cylinder,
				parent = pier,
			})
		end
	end
	-- Rails round the edges, and along the line that separates the pier from the dock.
	railing(pier, Vector3.new(-13.8, 0, 5), Vector3.new(-13.8, 0, 45.8))
	railing(pier, Vector3.new(13.8, 0, 5), Vector3.new(13.8, 0, 45.8))
	railing(pier, Vector3.new(-13.8, 0, 45.8), Vector3.new(13.8, 0, 45.8))
	railing(pier, Vector3.new(-19.5, 0, 4.6), Vector3.new(-5.3, 0, 4.6))
	railing(pier, Vector3.new(5.3, 0, 4.6), Vector3.new(24.5, 0, 4.6))
	barrier(pier, Vector3.new(1, 16, 42), CFrame.new(-14.4, 8, 25.3))
	barrier(pier, Vector3.new(1, 16, 42), CFrame.new(14.4, 8, 25.3))
	barrier(pier, Vector3.new(30, 16, 1), CFrame.new(0, 8, 46.4))
	barrier(pier, Vector3.new(15.2, 16, 1), CFrame.new(-12.6, 8, 4.4))
	barrier(pier, Vector3.new(20.2, 16, 1), CFrame.new(15.1, 8, 4.4))

	for _, z in { 16, 30, 43 } do
		lampPost(pier, Vector3.new(-12, 0, z))
		lampPost(pier, Vector3.new(12, 0, z))
	end
	bench(pier, Vector3.new(-10.5, 0, 23), Vector3.new(1, 0, 0))
	bench(pier, Vector3.new(10.5, 0, 23), Vector3.new(-1, 0, 0))
	lifebuoy(pier, Vector3.new(-13.6, 1.8, 36), Vector3.new(1, 0, 0))
	seagull(pier, Vector3.new(14.5, 1, 38), Vector3.new(-1, 0, 0.2))

	-- A notice board beside the path to the booth, facing the spawn, so the first thing
	-- a new player reads is what to do. (A part's Front face is its -Z side; turned
	-- round, it faces down the pier.)
	local board = part({
		name = "NoticeBoard",
		size = Vector3.new(6, 3.4, 0.3),
		cframe = CFrame.new(-7.5, 3.9, 12) * CFrame.Angles(0, math.rad(180), 0),
		color = Color3.fromRGB(33, 52, 96),
		parent = pier,
	})
	for _, x in { -10.3, -4.7 } do
		part({
			name = "BoardPost",
			size = Vector3.new(0.4, 5.6, 0.4),
			cframe = CFrame.new(x, 2.8, 11.7),
			color = TRIM,
			parent = pier,
		})
	end
	sign(board, Enum.NormalId.Front, "NIGHT FERRY · STAFF WANTED\nClock in at the ticket office door", TRIM)

	-- Players appear here between shifts, facing the booth (-Z, as a SpawnLocation faces
	-- by default).
	pierSpawn = spawnPad("PierSpawn", Vector3.new(8, 0.2, 8), CFrame.new(0, -0.1, 30), pier)
	return Vector3.new(0, 0, 30)
end

local DOOR_HINGE = CFrame.new(-1.3, 3.45, 8)
local DOOR_SHUT = DOOR_HINGE * CFrame.new(1.3, 0, 0)
local DOOR_OPEN = DOOR_HINGE * CFrame.Angles(0, math.rad(-100), 0) * CFrame.new(1.3, 0, 0)
local door: BasePart

local function buildBooth(parent: Folder): CFrame
	local booth = folder("Booth", parent)
	part({
		name = "Floor",
		size = Vector3.new(10, 0.2, 8),
		cframe = CFrame.new(0, 0.1, 4),
		color = Color3.fromRGB(96, 70, 52),
		material = Enum.Material.WoodPlanks,
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
		-- The back wall, either side of and above the staff door.
		{ Vector3.new(3.6, 8.2, 0.4), Vector3.new(-3.2, 4.1, 8) },
		{ Vector3.new(3.6, 8.2, 0.4), Vector3.new(3.2, 4.1, 8) },
		{ Vector3.new(2.8, 1.3, 0.4), Vector3.new(0, 7.55, 8) },
	}
	for _, wall in walls do
		part({
			name = "Wall",
			size = wall[1],
			cframe = CFrame.new(wall[2]),
			color = BOOTH_PAINT,
			material = Enum.Material.WoodPlanks,
			collide = true,
			parent = booth,
		})
	end
	-- White corner trim, the classic harbor-kiosk look.
	for _, x in { -5.05, 5.05 } do
		for _, z in { -0.05, 8.05 } do
			part({
				name = "CornerTrim",
				size = Vector3.new(0.5, 8.2, 0.5),
				cframe = CFrame.new(x, 4.1, z),
				color = TRIM,
				parent = booth,
			})
		end
	end
	part({
		name = "Roof",
		size = Vector3.new(11.5, 0.6, 9.6),
		cframe = CFrame.new(0, 8.5, 3.8),
		color = ROOF,
		material = Enum.Material.SmoothPlastic,
		collide = true, -- a clerk jumping in the booth bumps their head
		parent = booth,
	})
	part({
		name = "RoofTrim",
		size = Vector3.new(11.7, 0.25, 9.8),
		cframe = CFrame.new(0, 8.12, 3.8),
		color = TRIM,
		parent = booth,
	})

	-- The staff door at the back, from the pier. Open between shifts, shut during one.
	door = part({
		name = "Door",
		size = Vector3.new(2.6, 6.9, 0.25),
		cframe = DOOR_OPEN,
		color = TRIM,
		collide = false,
		parent = booth,
	})
	local doorSign = part({
		name = "DoorSign",
		size = Vector3.new(1.8, 0.5, 0.05),
		cframe = DOOR_OPEN * CFrame.new(0, 1.6, 0.16),
		color = Color3.fromRGB(33, 52, 96),
		castShadow = false,
		parent = booth,
	})
	sign(doorSign, Enum.NormalId.Back, "STAFF ONLY", TRIM)
	local doorWeld = Instance.new("WeldConstraint")
	doorWeld.Part0 = door
	doorWeld.Part1 = doorSign
	doorWeld.Parent = doorSign
	doorSign.Anchored = false

	-- The time clock on the pier side of the back wall, right of the door: where a shift
	-- starts. Roblox's own "E" prompt, held for a moment so nobody clocks in by accident.
	local timeClock = part({
		name = "TimeClock",
		size = Vector3.new(1.3, 1.7, 0.45),
		cframe = CFrame.new(2.7, 3.9, 8.43),
		color = Color3.fromRGB(46, 58, 76),
		collide = true,
		parent = booth,
	})
	part({
		name = "ClockFace",
		size = Vector3.new(0.1, 0.8, 0.8),
		cframe = CFrame.new(2.7, 4.2, 8.67) * CFrame.Angles(0, math.rad(90), 0),
		color = TRIM,
		shape = Enum.PartType.Cylinder,
		castShadow = false,
		parent = booth,
	})
	part({
		name = "CardSlot",
		size = Vector3.new(0.7, 0.08, 0.1),
		cframe = CFrame.new(2.7, 3.45, 8.67),
		color = Color3.fromRGB(20, 22, 26),
		castShadow = false,
		parent = booth,
	})
	local clockSign = part({
		name = "ClockSign",
		size = Vector3.new(1.8, 0.5, 0.06),
		cframe = CFrame.new(2.7, 5.1, 8.24),
		color = SIGN_NEON,
		material = Enum.Material.Neon,
		castShadow = false,
		parent = booth,
	})
	sign(clockSign, Enum.NormalId.Back, "CLOCK IN", Color3.fromRGB(28, 34, 44))
	local promptPoint = Instance.new("Attachment")
	promptPoint.Name = "PromptPoint"
	promptPoint.Position = Vector3.new(0, 0, 0.4)
	promptPoint.Parent = timeClock
	clockPrompt = Instance.new("ProximityPrompt")
	clockPrompt.Name = "ClockIn"
	clockPrompt.ActionText = "Clock in"
	clockPrompt.ObjectText = "Night shift"
	clockPrompt.HoldDuration = 0.6
	clockPrompt.MaxActivationDistance = 9
	clockPrompt.RequiresLineOfSight = false
	clockPrompt.Enabled = false
	clockPrompt.Parent = promptPoint

	-- Clerks who join (or respawn) mid-shift appear inside, facing the window.
	boothSpawn = spawnPad("BoothSpawn", Vector3.new(4, 0.2, 2), CFrame.new(0, 0.1, 5.6), booth)
	boothSpawn.Enabled = false

	-- Inside, for anyone who turns round: a clock and the rules in poster form.
	part({
		name = "Clock",
		size = Vector3.new(0.2, 1.4, 1.4),
		cframe = CFrame.new(3.2, 6.2, 7.75) * CFrame.Angles(0, math.rad(90), 0), -- a disc on the wall
		color = TRIM,
		shape = Enum.PartType.Cylinder,
		parent = booth,
	})
	for _, hand in { { 0.55, 0 }, { 0.38, 90 } } do
		part({
			name = "ClockHand",
			size = Vector3.new(0.08, hand[1], 0.05),
			cframe = CFrame.new(3.2, 6.2, 7.62)
				* CFrame.Angles(0, 0, math.rad(hand[2]))
				* CFrame.new(0, hand[1] / 2, 0),
			color = Color3.fromRGB(27, 42, 53),
			castShadow = false,
			parent = booth,
		})
	end
	local poster = part({
		name = "Poster",
		size = Vector3.new(2.4, 3, 0.05),
		cframe = CFrame.new(-3.2, 4.8, 7.77),
		color = Color3.fromRGB(245, 233, 196),
		castShadow = false,
		parent = booth,
	})
	sign(poster, Enum.NormalId.Front, "CHECK\nEVERY\nTICKET", Color3.fromRGB(196, 40, 28))
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
		collide = true, -- nobody climbs out of the window
		parent = booth,
	})
	-- Counter, with the booth's own warm light.
	local counter = part({
		name = "Counter",
		size = Vector3.new(9.2, 0.3, 1.6),
		cframe = CFrame.new(0, 2.5, 0.95),
		color = Color3.fromRGB(128, 90, 60),
		material = Enum.Material.Wood,
		collide = true,
		parent = booth,
	})
	part({
		name = "CounterFront",
		size = Vector3.new(9.2, 2.35, 0.3),
		cframe = CFrame.new(0, 1.2, 1.6),
		color = BOOTH_PAINT:Lerp(Color3.new(0, 0, 0), 0.2),
		material = Enum.Material.WoodPlanks,
		collide = true,
		parent = booth,
	})
	local interior = Instance.new("PointLight")
	interior.Color = LAMP_WARM
	interior.Brightness = 0.5
	interior.Range = 9
	interior.Shadows = false
	interior.Parent = counter
	-- A warm ceiling lamp at the back, so clerks can see each other. Its light stops short
	-- of the window: it never lights a passenger or the planks where the tells are.
	local ceilingLamp = part({
		name = "CeilingLamp",
		size = Vector3.new(0.18, 1.1, 1.1),
		cframe = CFrame.new(0, 8.1, 5) * CFrame.Angles(0, 0, math.rad(90)),
		color = LAMP_WARM,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		castShadow = false,
		parent = booth,
	})
	local ceilingLight = Instance.new("PointLight")
	ceilingLight.Color = LAMP_WARM
	ceilingLight.Brightness = 0.9
	ceilingLight.Range = 8
	ceilingLight.Shadows = false
	ceilingLight.Parent = ceilingLamp
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
	-- A neon frame round the sign, the brightest thing on the harbor.
	for _, bar in
		{
			{ Vector3.new(8.3, 0.14, 0.14), Vector3.new(0, 9.52, -0.5) },
			{ Vector3.new(8.3, 0.14, 0.14), Vector3.new(0, 8.28, -0.5) },
			{ Vector3.new(0.14, 1.38, 0.14), Vector3.new(-4.08, 8.9, -0.5) },
			{ Vector3.new(0.14, 1.38, 0.14), Vector3.new(4.08, 8.9, -0.5) },
		}
	do
		part({
			name = "SignNeon",
			size = bar[1],
			cframe = CFrame.new(bar[2]),
			color = SIGN_NEON,
			material = Enum.Material.Neon,
			castShadow = false,
			parent = booth,
		})
	end
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
	local pier = buildPier(world)
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
		pier = pier,
		-- Where each clerk's feet go on the booth floor, facing the window: the front spot
		-- first. Four fit along the counter and behind it; more than six share.
		stands = {
			CFrame.lookAt(Vector3.new(0, 0.2, 2.7), Vector3.new(0, 0.2, -1)),
			CFrame.lookAt(Vector3.new(-2.8, 0.2, 3), Vector3.new(-2.8, 0.2, -1)),
			CFrame.lookAt(Vector3.new(2.8, 0.2, 3), Vector3.new(2.8, 0.2, -1)),
			CFrame.lookAt(Vector3.new(0, 0.2, 5.4), Vector3.new(0, 0.2, -1)),
			CFrame.lookAt(Vector3.new(-2.8, 0.2, 5.8), Vector3.new(-2.8, 0.2, -1)),
			CFrame.lookAt(Vector3.new(2.8, 0.2, 5.8), Vector3.new(2.8, 0.2, -1)),
		},
		window = Vector3.new(0, 0, -3.2),
		queue = { Vector3.new(-2, 0, -11), Vector3.new(0.5, 0, -17), Vector3.new(-1.5, 0, -23) },
		spawn = Vector3.new(-0.5, 0, -50), -- the middle of the rope lane
		board = {
			Vector3.new(4.5, 0, -5.6),
			Vector3.new(8.25, 0, -8.2),
			Vector3.new(8.25, 0, -10.5), -- through the gate
			Vector3.new(17, 0.35, -20),
			Vector3.new(27, 2.2, -24.5), -- top of the gangway
			Vector3.new(30, 1.9, -25.5),
		},
		away = { Vector3.new(-6, 0, -4.2), Vector3.new(-8.5, 0, -30), Vector3.new(-7, 0, -56) },
		-- Off the dock's left edge about 32° left of straight out, inside the window's view.
		water = { Vector3.new(-6, 0, -4.2), Vector3.new(-18.6, 0, -30), Vector3.new(-21.4, -1.2, -31) },
		lamp = lampBulb.Position,
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

-- The prompt on the time clock by the booth's back door.
function WorldService.clockPrompt(): ProximityPrompt
	return clockPrompt
end

-- The staff door swings open onto the pier between shifts, and shuts for one.
function WorldService.setDoor(open: boolean)
	door.CanCollide = not open
	TweenService:Create(door, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = if open then DOOR_OPEN else DOOR_SHUT,
	}):Play()
end

-- During a shift the door is shut and anyone who (re)spawns appears in the booth;
-- between shifts the door is open and everyone appears on the pier.
function WorldService.setShift(on: boolean)
	WorldService.setDoor(not on)
	boothSpawn.Enabled = on
	pierSpawn.Enabled = not on
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
		local fade = TweenService:Create(p, TweenInfo.new(4, Enum.EasingStyle.Sine), { Transparency = 0.55 })
		table.insert(marigoldFades, fade)
		fade:Play()
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

-- The tide rises in the booth, over the counter, where the camera can see it.
function WorldService.setFlood(on: boolean)
	local cframe = if on then CFrame.new(0, 3.1, 4) else CFrame.new(0, 0.1, 4)
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
	-- Setting Transparency doesn't stop a running fade, so cancel them first.
	for _, fade in marigoldFades do
		fade:Cancel()
	end
	table.clear(marigoldFades)
	for _, p in marigoldParts do
		p.Transparency = 1
	end
end

return WorldService
