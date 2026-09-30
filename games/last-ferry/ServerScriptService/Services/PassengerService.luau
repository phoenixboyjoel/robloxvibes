--!strict
--[[
	PassengerService: builds passengers out of parts and walks them around.

	The tells players check are built here from the passenger's facts, never
	from their kind, so what you see always matches what the rules judge:
	- breath: fog puffs in front of the face (ParticleEmitter)
	- wet: a darker, glossy coat, dripping water, and a puddle at the window
	- shadow: every visible part has CastShadow = passenger.shadow

	A figure is an anchored, invisible Root with the visible parts welded to it,
	so tweening the Root moves the whole figure.
]]

local TweenService = game:GetService("TweenService")

local Types = require("../Shift/Types")

local PassengerService = {}

local COATS = {
	Color3.fromRGB(44, 48, 56),
	Color3.fromRGB(38, 52, 78),
	Color3.fromRGB(72, 78, 52),
	Color3.fromRGB(150, 122, 54),
	Color3.fromRGB(96, 70, 50),
	Color3.fromRGB(104, 108, 112),
	Color3.fromRGB(40, 86, 90),
	Color3.fromRGB(86, 46, 62),
}
local SKINS = {
	Color3.fromRGB(255, 224, 196),
	Color3.fromRGB(234, 192, 160),
	Color3.fromRGB(198, 146, 110),
	Color3.fromRGB(160, 110, 78),
	Color3.fromRGB(120, 80, 56),
	Color3.fromRGB(86, 58, 42),
}
local SCARVES = {
	Color3.fromRGB(180, 160, 120),
	Color3.fromRGB(70, 90, 120),
	Color3.fromRGB(120, 60, 60),
	Color3.fromRGB(200, 200, 190),
	Color3.fromRGB(60, 110, 80),
}
local LEGS = Color3.fromRGB(34, 36, 40)
local MARA_COAT = Color3.fromRGB(196, 30, 36)
local MARA_SCARF = Color3.fromRGB(236, 196, 60)
local PALE = Color3.fromRGB(168, 184, 188)
local SEAWEED = Color3.fromRGB(46, 74, 44)

local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local DROP_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

type Figure = {
	root: BasePart,
	halfHeight: number,
	puddle: BasePart?,
	page: BasePart?,
	walk: {}?,
	tween: Tween?,
}

local figures: { [Model]: Figure } = {}

local function piece(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	castShadow: boolean
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = root.CFrame * offset
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = false
	p.Massless = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = castShadow
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
	return p
end

local function cylinderUp(): CFrame
	return CFrame.Angles(0, 0, math.rad(90))
end

local function breathEmitter(head: BasePart, h: number)
	local mouth = Instance.new("Attachment")
	mouth.Name = "Mouth"
	mouth.Position = Vector3.new(0, -0.12 * h, -0.62 * h)
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

local function dripEmitter(coat: BasePart, h: number)
	local hem = Instance.new("Attachment")
	hem.Name = "Hem"
	hem.Position = Vector3.new(0, -1.35 * h, 0)
	hem.Parent = coat

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Drips"
	emitter.Texture = DROP_TEXTURE
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Rate = 12
	emitter.Lifetime = NumberRange.new(0.35, 0.55)
	emitter.Speed = NumberRange.new(0.2, 0.8)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Acceleration = Vector3.new(0, -40, 0)
	emitter.Size = NumberSequence.new(0.12)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.6),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(170, 205, 215))
	emitter.Parent = hem
end

-- Builds the figure standing at `feet`, facing `facing`.
function PassengerService.spawn(passenger: Types.Passenger, feet: Vector3, facing: Vector3, parent: Instance): Model
	local look = passenger.look
	local h = look.height
	local halfHeight = 2.5 * h
	local shadow = passenger.shadow
	local isMara = passenger.kind == "mara"

	local model = Instance.new("Model")
	model.Name = `Passenger{passenger.id}`

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2 * h, 5 * h, 1 * h)
	root.CFrame = CFrame.lookAt(feet + Vector3.new(0, halfHeight, 0), feet + Vector3.new(0, halfHeight, 0) + facing)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CastShadow = false
	root.Parent = model
	model.PrimaryPart = root

	-- Offsets are from the Root's centre; the feet are at -halfHeight.
	local function at(x: number, y: number, z: number): CFrame
		return CFrame.new(x * h, y * h - halfHeight, z * h)
	end

	local skin = SKINS[math.clamp(look.skin, 1, #SKINS)]
	if look.pale then
		skin = skin:Lerp(PALE, 0.75)
	end
	local coatColor = if isMara then MARA_COAT else COATS[math.clamp(look.coat, 1, #COATS)]
	if passenger.wet then
		coatColor = coatColor:Lerp(Color3.new(0, 0, 0), 0.35)
	end

	for _, side in { -1, 1 } do
		piece(model, root, "Leg", Vector3.new(0.7, 2.2, 0.8) * h, at(0.42 * side, 1.1, 0), LEGS, shadow)
		piece(model, root, "Arm", Vector3.new(0.55, 2.2, 0.6) * h, at(1.3 * side, 3.0, 0), coatColor, shadow)
	end
	local coat = piece(model, root, "Coat", Vector3.new(2.1, 2.8, 1.25) * h, at(0, 2.8, 0), coatColor, shadow)
	if passenger.wet then
		coat.Reflectance = 0.15
	end

	local head = piece(model, root, "Head", Vector3.new(1.25, 1.25, 1.25) * h, at(0, 4.85, 0), skin, shadow)
	head.Shape = Enum.PartType.Ball
	for _, side in { -1, 1 } do
		piece(
			model,
			root,
			"Eye",
			Vector3.new(0.14, 0.14, 0.05) * h,
			at(0.22 * side, 4.93, -0.6),
			Color3.fromRGB(20, 20, 24),
			false
		)
	end

	local scarf = if isMara
		then MARA_SCARF
		elseif look.scarf > 0 then SCARVES[math.clamp(look.scarf, 1, #SCARVES)]
		else nil
	if scarf then
		piece(model, root, "Scarf", Vector3.new(1.4, 0.35, 1.35) * h, at(0, 4.3, 0), scarf, shadow)
	end

	if not isMara then
		if look.hat == 1 then
			local beanie = piece(
				model,
				root,
				"Hat",
				Vector3.new(0.5, 1.28, 1.28) * h,
				at(0, 5.35, 0) * cylinderUp(),
				coatColor:Lerp(Color3.new(1, 1, 1), 0.15),
				shadow
			)
			beanie.Shape = Enum.PartType.Cylinder
		elseif look.hat == 2 then
			local cap = piece(
				model,
				root,
				"Hat",
				Vector3.new(0.28, 1.36, 1.36) * h,
				at(0, 5.42, 0) * cylinderUp(),
				LEGS,
				shadow
			)
			cap.Shape = Enum.PartType.Cylinder
			piece(model, root, "Brim", Vector3.new(1.0, 0.08, 0.5) * h, at(0, 5.32, -0.72), LEGS, shadow)
		elseif look.hat == 3 then
			piece(model, root, "Hood", Vector3.new(1.5, 1.45, 1.1) * h, at(0, 4.95, 0.28), coatColor, shadow)
		end
	end

	if look.bag == 1 then
		piece(
			model,
			root,
			"Suitcase",
			Vector3.new(1.4, 1.0, 0.45) * h,
			at(1.55, 0.9, 0),
			Color3.fromRGB(92, 64, 44),
			shadow
		)
	elseif look.bag == 2 then
		piece(
			model,
			root,
			"Backpack",
			Vector3.new(1.5, 1.7, 0.7) * h,
			at(0, 3.2, 0.95),
			Color3.fromRGB(52, 60, 50),
			shadow
		)
	elseif look.bag == 3 then
		piece(
			model,
			root,
			"Tote",
			Vector3.new(0.9, 1.0, 0.3) * h,
			at(-1.45, 2.0, 0),
			Color3.fromRGB(170, 160, 140),
			shadow
		)
	end

	if passenger.wet and look.pale then
		piece(model, root, "Seaweed", Vector3.new(0.12, 1.3, 0.12) * h, at(-0.7, 3.9, -0.64), SEAWEED, shadow)
		piece(model, root, "Seaweed", Vector3.new(0.1, 0.9, 0.1) * h, at(0.9, 2.2, -0.64), SEAWEED, shadow)
	end

	local page: BasePart? = nil
	if passenger.hasLedgerPage then
		page = piece(
			model,
			root,
			"LedgerPage",
			Vector3.new(0.5, 0.7, 0.05) * h,
			at(0.6, 2.7, -0.66) * CFrame.Angles(0, 0, math.rad(12)),
			Color3.fromRGB(226, 218, 196),
			shadow
		)
	end

	if passenger.breath then
		breathEmitter(head, h)
	end
	if passenger.wet then
		dripEmitter(coat, h)
	end

	figures[model] = { root = root, halfHeight = halfHeight, puddle = nil, page = page, walk = nil, tween = nil }
	model.Destroying:Once(function()
		figures[model] = nil
	end)
	model.Parent = parent
	return model
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
	if figure.tween then
		figure.tween:Cancel()
	end

	local root = figure.root
	for _, point in path do
		if figure.walk ~= token or model.Parent == nil then
			return false
		end
		local target = point + Vector3.new(0, figure.halfHeight, 0)
		local from = root.Position
		local distance = (target - from).Magnitude
		if distance > 0.05 then
			local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
			local rotation = if flat.Magnitude > 0.05
				then CFrame.lookAt(Vector3.zero, flat).Rotation
				else root.CFrame.Rotation
			root.CFrame = CFrame.new(from) * rotation
			local tween = TweenService:Create(
				root,
				TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
				{ CFrame = CFrame.new(target) * rotation }
			)
			figure.tween = tween
			tween:Play()
			tween.Completed:Wait()
		end
	end

	if figure.walk ~= token or model.Parent == nil then
		return false
	end
	figure.tween = nil
	if faceAtEnd then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + faceAtEnd)
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
	local feet = figure.root.Position - Vector3.new(0, figure.halfHeight, 0)
	local puddle = Instance.new("Part")
	puddle.Name = "Puddle"
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Size = Vector3.new(0.04, 0.6, 0.6)
	puddle.CFrame = CFrame.new(feet + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, 0, math.rad(90))
	puddle.Color = Color3.fromRGB(18, 30, 36)
	puddle.Material = Enum.Material.Glass
	puddle.Reflectance = 0.35
	puddle.Transparency = 0.15
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.CanTouch = false
	puddle.CanQuery = false
	puddle.CastShadow = false
	puddle.Parent = model.Parent
	TweenService:Create(puddle, TweenInfo.new(6, Enum.EasingStyle.Sine), { Size = Vector3.new(0.04, 3.4, 3.4) }):Play()
	figure.puddle = puddle
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
		if figure.tween then
			figure.tween:Cancel()
		end
		if figure.puddle then
			drain(figure.puddle)
			figure.puddle = nil
		end
		if sink then
			TweenService:Create(figure.root, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = figure.root.CFrame * CFrame.new(0, -8, 0),
			}):Play()
		end
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name ~= "Root" then
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
