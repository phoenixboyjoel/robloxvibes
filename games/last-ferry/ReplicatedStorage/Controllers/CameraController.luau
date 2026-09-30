--!strict
--[[
	CameraController: you sit in the booth. The camera stays at the booth's
	CameraAnchor and only turns: drag with the mouse or a finger, arrow keys or
	WASD, or the right stick. Scroll, pinch or the triggers lean in (narrower
	field of view) to inspect a passenger's breath or shadow.
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require("../Shared/Config")

local CameraController = {}

local MOUSE_SENSITIVITY = 0.2 -- degrees per pixel
local TOUCH_SENSITIVITY = 0.28
local KEY_SPEED = 70 -- degrees per second
local STICK_SPEED = 110
local WIDE, NARROW = 70, 42 -- field of view range

local yaw, pitch = 0, 0 -- current offsets from the anchor's direction, in degrees
local targetYaw, targetPitch = 0, 0
local fov, targetFov = WIDE, WIDE
local shakeStrength, shakeUntil = 0, 0
local stick = Vector2.zero
local zoomStick = 0
local dragInput: InputObject? = nil
local mouseDragging = false
local pinchFov = WIDE

local function clampTargets()
	targetYaw = math.clamp(targetYaw, -Config.LookYaw, Config.LookYaw)
	targetPitch = math.clamp(targetPitch, -Config.LookPitchDown, Config.LookPitchUp)
	targetFov = math.clamp(targetFov, NARROW, WIDE)
end

local function turn(dx: number, dy: number, sensitivity: number)
	targetYaw -= dx * sensitivity
	targetPitch -= dy * sensitivity
	clampTargets()
end

-- Eases the view toward an angle (degrees from straight out of the window).
function CameraController.lookTo(yawDegrees: number, pitchDegrees: number)
	targetYaw = yawDegrees
	targetPitch = pitchDegrees
	targetFov = WIDE
	clampTargets()
end

function CameraController.shake(strength: number, seconds: number)
	shakeStrength = strength
	shakeUntil = os.clock() + seconds
end

local function connectInput()
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch then
			if dragInput == nil then
				dragInput = input
			end
		elseif kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.MouseButton2 then
			mouseDragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject, processed: boolean)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseMovement and mouseDragging then
			turn(input.Delta.X, input.Delta.Y, MOUSE_SENSITIVITY)
		elseif kind == Enum.UserInputType.Touch and input == dragInput then
			turn(input.Delta.X, input.Delta.Y, TOUCH_SENSITIVITY)
		elseif kind == Enum.UserInputType.MouseWheel and not processed then
			targetFov -= input.Position.Z * 4
			clampTargets()
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
			stick = Vector2.new(input.Position.X, input.Position.Y)
			if stick.Magnitude < 0.15 then
				stick = Vector2.zero
			end
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			zoomStick = input.Position.Z
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch then
			if input == dragInput then
				dragInput = nil
			end
		elseif kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.MouseButton2 then
			mouseDragging = false
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
			stick = Vector2.zero
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			zoomStick = 0
		end
	end)

	UserInputService.TouchPinch:Connect(
		function(_positions: { any }, scale: number, _velocity: number, state: Enum.UserInputState, processed: boolean)
			if processed then
				return
			end
			if state == Enum.UserInputState.Begin then
				dragInput = nil -- two fingers: a pinch, not a drag
				pinchFov = targetFov
			elseif scale > 0 then
				targetFov = pinchFov / scale
				clampTargets()
			end
		end
	)
end

local function keyAxis(positive: { Enum.KeyCode }, negative: { Enum.KeyCode }): number
	if UserInputService:GetFocusedTextBox() then
		return 0
	end
	local value = 0
	for _, key in positive do
		if UserInputService:IsKeyDown(key) then
			value += 1
			break
		end
	end
	for _, key in negative do
		if UserInputService:IsKeyDown(key) then
			value -= 1
			break
		end
	end
	return value
end

function CameraController.start()
	local camera = workspace.CurrentCamera
	local anchor = workspace:WaitForChild("World"):WaitForChild("Booth"):WaitForChild("CameraAnchor") :: BasePart
	local base = anchor.CFrame
	local look = base.LookVector
	local baseYaw = math.atan2(-look.X, -look.Z)
	local basePitch = math.asin(look.Y)

	connectInput()

	RunService:BindToRenderStep("LastFerryCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local horizontal = keyAxis({ Enum.KeyCode.Left, Enum.KeyCode.A }, { Enum.KeyCode.Right, Enum.KeyCode.D })
		local vertical = keyAxis({ Enum.KeyCode.Up, Enum.KeyCode.W }, { Enum.KeyCode.Down, Enum.KeyCode.S })
		if horizontal ~= 0 or vertical ~= 0 or stick ~= Vector2.zero or zoomStick ~= 0 then
			targetYaw += (horizontal * KEY_SPEED - stick.X * STICK_SPEED) * dt
			targetPitch += (vertical * KEY_SPEED + stick.Y * STICK_SPEED * 0.7) * dt
			targetFov = WIDE - (WIDE - NARROW) * zoomStick
			clampTargets()
		end

		local ease = 1 - math.exp(-dt * 12)
		yaw += (targetYaw - yaw) * ease
		pitch += (targetPitch - pitch) * ease
		fov += (targetFov - fov) * ease

		-- A slow sway, as if you're breathing, plus a shake when a lantern goes out.
		local t = os.clock()
		local swayYaw = math.sin(t * 0.37) * 0.35
		local swayPitch = math.sin(t * 0.53) * 0.25
		if t < shakeUntil then
			local fade = (shakeUntil - t) * shakeStrength
			swayYaw += (math.random() - 0.5) * fade * 2
			swayPitch += (math.random() - 0.5) * fade * 2
		end

		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = fov
		camera.CFrame = CFrame.new(base.Position)
			* CFrame.Angles(0, baseYaw + math.rad(yaw + swayYaw), 0)
			* CFrame.Angles(basePitch + math.rad(pitch + swayPitch), 0, 0)
	end)
end

return CameraController
