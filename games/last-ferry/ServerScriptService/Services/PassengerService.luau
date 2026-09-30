--!strict
--[[
	PassengerService: dresses each passenger as a classic Robloxian (Robloxian.luau)
	and walks them around.

	What someone wears comes from their Look, chosen from their name. The tells
	players check are added here from the passenger's facts, never from their kind,
	so what you see always matches what the rules judge:
	- breath: fog puffs in front of the face (ParticleEmitter)
	- wet: soaked, darker, glossy clothes; water dripping from the cuffs and the
	  hem; a wide puddle spreading either side of them at the window; wet
	  footprints where they walk
	- shadow: every visible part has CastShadow = passenger.shadow, plus a
	  darkened patch on the planks where the lamp throws the shadow, so the tell
	  survives phones that turn shadows off at low graphics quality
	- pale (the drowned on the first two nights): a grey-green skin, and seaweed
	  if they're wet too

	The HumanoidRootPart is anchored; every other part hangs off it on Roblox's
	standard joints, so moving the root moves the whole figure. The server glides
	the root (Shared/Glide), so every client walks them smoothly, turning into each
	leg as they go, and swings their limbs as they walk (CrowdController).
]]

local TweenService = game:GetService("TweenService")

local Glide = require("../../ReplicatedStorage/Shared/Glide")
local Sounds = require("../../ReplicatedStorage/Shared/Sounds")
local Types = require("../Shift/Types")
local Robloxian = require("./Robloxian")

local PassengerService = {}

local PALE = Color3.fromRGB(168, 190, 184)
local SEAWEED = Color3.fromRGB(46, 96, 52)
local PAGE = Color3.fromRGB(236, 226, 196)

local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local DROP_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

-- How fast passengers turn to face where they're going: one and a half turns a second.
local TURN_RATE = math.rad(540)

type Figure = {
	root: BasePart,
	feet: number, -- the feet are this far below the root's centre
	puddle: BasePart?,
	mark: BasePart?,
	page: BasePart?,
	walk: {}?,
}

local figures: { [Model]: Figure } = {}

local function breathEmitter(head: BasePart, s: number)
	local mouth = Instance.new("Attachment")
	mouth.Name = "Mouth"
	mouth.Position = Vector3.new(0, -0.18 * s, -0.66 * s)
	mouth.Parent = head

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Breath"
	emitter.Texture = SMOKE_TEXTURE
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Rate = 0.8
	emitter.Lifetime = NumberRange.new(1.2, 1.8)
	emitter.Speed = NumberRange.new(1, 1.6)
	emitter.SpreadAngle = Vector2.new(12, 12)
	emitter.Acceleration = Vector3.new(0, 0.5, 0)
	emitter.Drag = 1
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1.3),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(235, 240, 245))
	emitter.LightEmission = 0.1
	emitter.Parent = mouth
end

-- Water dripping from `part` at `position` (in the part's space). Big, bright and
-- slow enough to read from the booth at night.
local function dripEmitter(part: BasePart, position: Vector3)
	local drip = Instance.new("Attachment")
	drip.Name = "Drip"
	drip.Position = position
	drip.Parent = part

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Drips"
	emitter.Texture = DROP_TEXTURE
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Rate = 7
	emitter.Lifetime = NumberRange.new(0.6, 0.9)
	emitter.Speed = NumberRange.new(0.3, 0.7)
	emitter.SpreadAngle = Vector2.new(12, 12)
	emitter.Acceleration = Vector3.new(0, -10, 0)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.26),
		NumberSequenceKeypoint.new(1, 0.18),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 0.45),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 226, 236))
	emitter.LightEmission = 0.3
	emitter.Parent = drip
end

-- A strand of seaweed hanging from `on`, welded so it moves with it.
local function seaweed(rig: Robloxian.Rig, on: BasePart, at: CFrame, length: number)
	local s = rig.scale
	local strand = Instance.new("Part")
	strand.Name = "Seaweed"
	strand.Size = Vector3.new(0.12 * s, length * s, 0.06 * s)
	strand.CFrame = on.CFrame * at
	strand.Color = SEAWEED
	strand.Material = Enum.Material.SmoothPlastic
	strand.Reflectance = 0.2
	strand.Anchored = false
	strand.Massless = true
	strand.CanCollide = false
	strand.CanTouch = false
	strand.CanQuery = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = on
	weld.Part1 = strand
	weld.Parent = strand
	strand.Parent = rig.model
	table.insert(rig.all, strand)
end

-- Builds the passenger standing at `feet`, facing `facing`.
function PassengerService.spawn(passenger: Types.Passenger, feet: Vector3, facing: Vector3, parent: Instance): Model
	local look = passenger.look
	local rig = Robloxian.build(look, feet, facing)
	local model = rig.model
	model.Name = `Passenger{passenger.id}`
	local s = rig.scale

	if look.pale then
		for _, part in rig.skin do
			part.Color = part.Color:Lerp(PALE, 0.75)
		end
	end
	if passenger.wet then
		-- Soaked through: darker and glossy, with the hair plastered dark too.
		for _, part in rig.clothing do
			part.Color = part.Color:Lerp(Color3.new(0, 0, 0), 0.4)
			part.Reflectance = 0.22
		end
		for _, part in rig.hair do
			part.Color = part.Color:Lerp(Color3.new(0, 0, 0), 0.35)
			part.Reflectance = 0.15
		end
		if look.pale then
			seaweed(rig, rig.torso, CFrame.new(-0.55 * s, 0.35 * s, -0.54 * s), 1.2)
			seaweed(rig, rig.rightArm, CFrame.new(0, -0.3 * s, -0.54 * s), 0.9)
			seaweed(rig, rig.head, CFrame.new(0.5 * s, 0.1 * s, -0.5 * s) * CFrame.Angles(0, 0, math.rad(12)), 0.7)
		end
	end

	local page: BasePart? = nil
	if passenger.hasLedgerPage then
		local tucked = Instance.new("Part")
		tucked.Name = "LedgerPage"
		tucked.Size = Vector3.new(0.5, 0.7, 0.05) * s
		tucked.CFrame = rig.torso.CFrame
			* CFrame.new(0.55 * s, -0.25 * s, -0.54 * s)
			* CFrame.Angles(0, 0, math.rad(12))
		tucked.Color = PAGE
		tucked.Material = Enum.Material.SmoothPlastic
		tucked.Anchored = false
		tucked.Massless = true
		tucked.CanCollide = false
		tucked.CanTouch = false
		tucked.CanQuery = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rig.torso
		weld.Part1 = tucked
		weld.Parent = tucked
		tucked.Parent = model
		table.insert(rig.all, tucked)
		page = tucked
	end

	for _, part in rig.all do
		part.CastShadow = passenger.shadow
	end

	if passenger.breath then
		breathEmitter(rig.head, s)
	end
	if passenger.wet then
		-- From the cuffs and the front of the coat: high enough to clear the sill.
		for _, arm in { rig.leftArm, rig.rightArm } do
			dripEmitter(arm, Vector3.new(0, -0.95 * s, -0.3 * s))
		end
		local hem = rig.hem
		for _, side in { -1, 1 } do
			if hem then
				dripEmitter(hem, Vector3.new(0.55 * side * s, -0.2 * s, -0.45 * s))
			else
				dripEmitter(rig.torso, Vector3.new(0.55 * side * s, -0.95 * s, -0.45 * s))
			end
		end
	end

	figures[model] = { root = rig.root, feet = rig.feet, puddle = nil, page = page, walk = nil }
	model.Destroying:Once(function()
		figures[model] = nil
	end)
	model.Parent = parent
	return model
end

-- How long turning from facing as `from` does to facing as `to` does takes, or 0 if
-- that's hardly a turn.
local function turnTime(from: CFrame, to: CFrame): number
	local angle = math.acos(math.clamp(from.LookVector:Dot(to.LookVector), -1, 1))
	return if angle < math.rad(3) then 0 else math.max(angle / TURN_RATE, 0.12)
end

-- Walks through `path` (points at foot level), then turns to `faceAtEnd` if given.
-- A newer walk on the same figure cancels this one; returns false if cancelled.
function PassengerService.walk(model: Model, path: { Vector3 }, speed: number, faceAtEnd: Vector3?): boolean
	local figure = figures[model]
	if figure == nil then
		return false
	end
	local token = {}
	figure.walk = token
	local function current(): boolean
		return figure.walk == token and model.Parent ~= nil
	end

	local root = figure.root
	for _, point in path do
		if not current() then
			return false
		end
		local here = Glide.frame(root)
		local target = point + Vector3.new(0, figure.feet, 0)
		local distance = (target - here.Position).Magnitude
		if distance > 0.05 then
			-- Turning into the leg as they set off, as Roblox characters do.
			local flat = Vector3.new(target.X - here.X, 0, target.Z - here.Z)
			local facing = if flat.Magnitude > 0.05 then CFrame.lookAt(Vector3.zero, flat) else here.Rotation
			local seconds = distance / speed
			Glide.start(root, CFrame.new(target) * facing, seconds, { turn = turnTime(here, facing) })
			task.wait(seconds)
		end
	end
	if not current() then
		return false
	end

	if faceAtEnd then
		local here = Glide.frame(root)
		local facing = CFrame.lookAt(here.Position, here.Position + faceAtEnd)
		local seconds = turnTime(here, facing)
		if seconds > 0 then
			Glide.start(root, facing, seconds, { style = Enum.EasingStyle.Sine })
			task.wait(seconds)
			if not current() then
				return false
			end
		end
	end
	return true
end

local function drain(puddle: BasePart)
	local tween = TweenService:Create(puddle, TweenInfo.new(0.8), { Transparency = 1 })
	tween.Completed:Once(function()
		puddle:Destroy()
	end)
	tween:Play()
end

-- A puddle spreads under wet passengers while they stand at the window, and drains
-- away when they leave so the next passenger isn't standing in it.
function PassengerService.setPuddle(model: Model, on: boolean)
	local figure = figures[model]
	if figure == nil then
		return
	end
	if figure.puddle then
		drain(figure.puddle)
		figure.puddle = nil
	end
	if not on then
		return
	end
	-- The sill hides their feet, and from the booth their body hides the planks right
	-- behind them, so the puddle spreads wide: its sides show either side of them.
	local root = Glide.frame(figure.root)
	local centre = root.Position - Vector3.new(0, figure.feet - 0.03, 0) - root.LookVector * 0.9
	local puddle = Instance.new("Part")
	puddle.Name = "Puddle"
	puddle.Shape = Enum.PartType.Cylinder
	puddle.CFrame = CFrame.new(centre) * CFrame.Angles(0, 0, math.rad(90))
	puddle.Color = Color3.fromRGB(18, 30, 36)
	puddle.Material = Enum.Material.Glass
	puddle.Reflectance = 0.35
	puddle.Transparency = 0.15
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.CanTouch = false
	puddle.CanQuery = false
	puddle.CastShadow = false
	-- It spreads on each client, so it grows smoothly there.
	Glide.spread(puddle, Vector3.new(0.04, 0.6, 0.6), Vector3.new(0.04, 5.6, 5.6), 6)
	puddle.Parent = model.Parent
	figure.puddle = puddle
end

local function flatPart(name: string, size: Vector3, cframe: CFrame, color: Color3, transparency: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = transparency
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

-- Wet footprints along the walk from where they stand now to `to` (foot level), laid
-- as they reach each step. They dry out after half a minute.
function PassengerService.footprints(model: Model, to: Vector3, speed: number)
	local figure = figures[model]
	if figure == nil then
		return
	end
	local from = Glide.frame(figure.root).Position - Vector3.new(0, figure.feet, 0)
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local length = flat.Magnitude
	if length < 1 then
		return
	end
	local direction = flat.Unit
	local side = direction:Cross(Vector3.yAxis)
	local folder = model.Parent
	local step = 0
	for distance = 0.6, length - 0.8, 1.15 do
		step += 1
		local foot = from + direction * distance + side * (if step % 2 == 0 then 0.28 else -0.28)
		local at = Vector3.new(foot.X, 0.02, foot.Z)
		task.delay(distance / speed, function()
			if folder == nil or folder.Parent == nil then
				return
			end
			local footprint = flatPart(
				"Footprint",
				Vector3.new(0.34, 0.02, 0.62),
				CFrame.lookAt(at, at + direction),
				Color3.fromRGB(16, 26, 30),
				0.2
			)
			footprint.Material = Enum.Material.Glass
			footprint.Reflectance = 0.3
			footprint.Parent = folder
			task.delay(18, function()
				local dry = TweenService:Create(footprint, TweenInfo.new(6), { Transparency = 1 })
				dry.Completed:Once(function()
					footprint:Destroy()
				end)
				dry:Play()
			end)
		end)
	end
end

-- A darkened patch on the planks where the lamp at `lamp` throws this passenger's
-- shadow, or nothing when `lamp` is nil. Only for passengers who cast a shadow.
function PassengerService.setShadowMark(model: Model, lamp: Vector3?)
	local figure = figures[model]
	if figure == nil then
		return
	end
	if figure.mark then
		figure.mark:Destroy()
		figure.mark = nil
	end
	if lamp == nil then
		return
	end
	local feet = Glide.frame(figure.root).Position - Vector3.new(0, figure.feet, 0)
	local away = Vector3.new(feet.X - lamp.X, 0, feet.Z - lamp.Z)
	if away.Magnitude < 0.1 then
		return
	end
	local direction = away.Unit
	local scale = figure.feet / 3
	local length = 4.6 * scale
	local centre = feet + direction * (length / 2 - 0.2) + Vector3.new(0, 0.025, 0)
	local mark = flatPart(
		"ShadowMark",
		Vector3.new(1.9 * scale, 0.02, length),
		CFrame.lookAt(centre, centre + direction),
		Color3.new(0, 0, 0),
		0.55
	)
	mark.Parent = model
	figure.mark = mark
end

function PassengerService.removePage(model: Model)
	local figure = figures[model]
	if figure and figure.page then
		figure.page:Destroy()
		figure.page = nil
	end
end

-- Fades the figure out and destroys it. `sink` drops it into the water as it fades.
function PassengerService.vanish(model: Model, seconds: number, sink: boolean?)
	local figure = figures[model]
	if figure then
		figure.walk = nil
		if figure.puddle then
			drain(figure.puddle)
			figure.puddle = nil
		end
		local root = figure.root
		if sink then
			Glide.start(root, Glide.frame(root) * CFrame.new(0, -8, 0), seconds, {
				style = Enum.EasingStyle.Quad,
				direction = Enum.EasingDirection.In,
			})
			Sounds.make(Sounds.Splash, root, "Splash"):Play()
		else
			Glide.stop(root)
		end
	end
	for _, descendant in model:GetDescendants() do
		local fades = descendant:IsA("Decal") or (descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart")
		if fades then
			TweenService:Create(descendant, TweenInfo.new(seconds), { Transparency = 1 }):Play()
		elseif descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end
	task.delay(seconds + 0.1, function()
		model:Destroy()
	end)
end

return PassengerService
