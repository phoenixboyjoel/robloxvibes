--!strict
--[[
	EffectsController: client-only screen effects and the lighthouse.

	- Blur behind the intro and summary cards.
	- A cold green tint while the tide is in (a failed night).
	- A red pulse when a lantern goes out.
	- The lighthouse beam, turned smoothly on each client while the server has
	  set the rotor's "Spinning" attribute.
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local EffectsController = {}

-- A cool, slightly saturated night: colours read on phones, where the engine drops
-- shadows and much of the lighting.
local NORMAL_TINT = Color3.fromRGB(242, 247, 255)
local NORMAL_SATURATION = 0.14
local FLOOD_TINT = Color3.fromRGB(170, 222, 214)
local ALARM_TINT = Color3.fromRGB(255, 150, 140)

local grade: ColorCorrectionEffect
local blur: BlurEffect
local flooded = false
local blurred = false

local function tweenGrade(tint: Color3, saturation: number, seconds: number)
	TweenService:Create(grade, TweenInfo.new(seconds, Enum.EasingStyle.Sine), {
		TintColor = tint,
		Saturation = saturation,
	}):Play()
end

function EffectsController.setBlur(on: boolean)
	if on == blurred then
		return
	end
	blurred = on
	TweenService:Create(blur, TweenInfo.new(0.4, Enum.EasingStyle.Sine), { Size = if on then 14 else 0 }):Play()
end

function EffectsController.setFlooded(on: boolean)
	if on == flooded then
		return
	end
	flooded = on
	if on then
		tweenGrade(FLOOD_TINT, -0.45, 2)
	else
		tweenGrade(NORMAL_TINT, NORMAL_SATURATION, 1)
	end
end

function EffectsController.lanternOut()
	grade.TintColor = ALARM_TINT
	tweenGrade(if flooded then FLOOD_TINT else NORMAL_TINT, if flooded then -0.45 else NORMAL_SATURATION, 0.9)
end

local function spinLighthouse()
	local world = workspace:WaitForChild("World")
	local lighthouse = world:WaitForChild("Lighthouse")
	local rotor = lighthouse:WaitForChild("Rotor") :: BasePart
	local beam = lighthouse:WaitForChild("Beam") :: BasePart
	local pivot = rotor.Position
	local angle = 0
	RunService.RenderStepped:Connect(function(dt: number)
		if rotor:GetAttribute("Spinning") ~= true then
			return
		end
		angle = (angle + dt * 0.9) % (math.pi * 2)
		local cframe = CFrame.new(pivot) * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-4), 0, 0)
		rotor.CFrame = cframe
		beam.CFrame = cframe * CFrame.new(0, 0, -(beam.Size.Z / 2 + 1))
	end)
end

function EffectsController.start()
	grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "LastFerryGrade"
	grade.Saturation = NORMAL_SATURATION
	grade.Contrast = 0.1
	grade.TintColor = NORMAL_TINT
	grade.Parent = Lighting

	blur = Instance.new("BlurEffect")
	blur.Name = "LastFerryBlur"
	blur.Size = 0
	blur.Parent = Lighting

	task.spawn(spinLighthouse)
end

return EffectsController
