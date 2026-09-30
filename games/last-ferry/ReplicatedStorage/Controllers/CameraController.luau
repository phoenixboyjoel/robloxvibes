--!strict
--[[
	CameraController: Roblox's own cameras, picked by where you are.

	On the pier between shifts it's Roblox's Classic third-person camera round your
	avatar. On shift in the booth (your "OnShift" attribute, set by the server's
	CrewService) it's Roblox's first-person camera (Player.CameraMode =
	LockFirstPerson): walk with WASD or the thumbstick, and look with the mouse (hold
	the right button while the HUD frees the cursor), a finger, the arrow keys or the
	right stick.

	On top of Roblox's camera, in the booth:
	- leaning in: scroll, pinch or hold R2 narrows the field of view, to check a
	  passenger's breath or shadow;
	- one eye height for every avatar (Humanoid.CameraOffset), so a small avatar sees
	  over the counter and a tall one sees under the top of the window, and everyone
	  sees the planks the tells are tuned for;
	- a shake when a lantern goes out;
	- cinematic views for the flood and the endings: a Scriptable camera that turns,
	  from where you stand, toward the scene.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraController = {}

local WIDE, NARROW = 70, 42 -- field of view range
local EYE_HEIGHT = 5.1 -- the booth camera's height (studs above the dock planks)
local PIER_ZOOM = 12 -- how far out the camera starts on the pier after a shift
local TURN_TIME = 1.4 -- seconds for a cinematic view to turn toward its scene

-- Roblox's first-person camera sits on this point above the root (its BaseCamera's
-- HEAD_OFFSET / R15_HEAD_OFFSET, plus half of any extra root height on scaled R15s).
local HEAD_OFFSET = 1.5

type Cinematic = { from: CFrame, yaw: number, pitch: number, started: number }

local player = Players.LocalPlayer
local fov, targetFov, pinchFov = WIDE, WIDE, WIDE
local triggerLean = 0
local shakeStrength, shakeUntil = 0, 0
local eyeOffset: number? = nil
local cinematic: Cinematic? = nil
local base = CFrame.identity -- the booth's view out of the window
local inBooth = false

local function humanoid(): Humanoid?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

local function clampFov()
	targetFov = math.clamp(targetFov, NARROW, WIDE)
end

-- Where Roblox's camera would put the eye with no CameraOffset.
local function naturalEyeY(h: Humanoid): number?
	local root = h.RootPart
	if root == nil then
		return nil
	end
	local lift = HEAD_OFFSET
	if h.RigType == Enum.HumanoidRigType.R15 then
		lift = if h.AutomaticScalingEnabled then HEAD_OFFSET + (root.Size.Y - 2) / 2 else 2
	end
	return root.Position.Y + lift
end

local function windowRotation(): CFrame
	return base.Rotation
end

-- Turns the view to look straight out of the window, from wherever the camera is, and
-- gives the camera back to Roblox. (Roblox's camera keeps whatever direction the
-- camera faces when it takes over.)
function CameraController.faceWindow()
	cinematic = nil
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.CFrame = CFrame.new(camera.CFrame.Position) * windowRotation()
	targetFov = WIDE
end

-- Turns the view, from where you stand, toward a scene: yaw and pitch in degrees from
-- straight out of the window (positive yaw is to the left).
function CameraController.lookTo(yawDegrees: number, pitchDegrees: number)
	local camera = workspace.CurrentCamera
	cinematic = {
		from = camera.CFrame,
		yaw = math.rad(yawDegrees),
		pitch = math.rad(pitchDegrees),
		started = os.clock(),
	}
	camera.CameraType = Enum.CameraType.Scriptable
end

function CameraController.shake(strength: number, seconds: number)
	shakeStrength = strength
	shakeUntil = os.clock() + seconds
end

local function applyMode()
	local camera = workspace.CurrentCamera
	local onShift = player:GetAttribute("OnShift") == true
	local h = humanoid()
	if h then
		camera.CameraSubject = h
	end
	if onShift then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		if not inBooth then
			inBooth = true
			eyeOffset = nil
			CameraController.faceWindow()
		elseif cinematic == nil then
			camera.CameraType = Enum.CameraType.Custom
		end
	else
		cinematic = nil
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.Classic
		if inBooth then
			inBooth = false
			targetFov = WIDE
			if h then
				h.CameraOffset = Vector3.zero
			end
			-- Back out of first person: a raised minimum zoom pushes the camera out, then
			-- the player can zoom as they like.
			player.CameraMinZoomDistance = PIER_ZOOM
			task.delay(0.2, function()
				player.CameraMinZoomDistance = 0.5
			end)
		end
	end
end

local function connectInput()
	-- Scroll and the right trigger lean in. They pass the input on: Roblox's camera
	-- ignores zoom in first person anyway.
	ContextActionService:BindActionAtPriority(
		"LastFerryLean",
		function(_action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
			if inBooth and cinematic == nil then
				if input.UserInputType == Enum.UserInputType.MouseWheel then
					targetFov -= input.Position.Z * 4
					clampFov()
				elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
					triggerLean = if state == Enum.UserInputState.End then 0 else math.clamp(input.Position.Z, 0, 1)
				end
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.UserInputType.MouseWheel,
		Enum.KeyCode.ButtonR2
	)

	UserInputService.TouchPinch:Connect(
		function(_positions: { any }, scale: number, _velocity: number, state: Enum.UserInputState, processed: boolean)
			if processed or not inBooth then
				return
			end
			if state == Enum.UserInputState.Begin then
				pinchFov = targetFov
			elseif scale > 0 then
				targetFov = pinchFov / scale
				clampFov()
			end
		end
	)
end

function CameraController.start()
	local anchor = workspace:WaitForChild("World"):WaitForChild("Booth"):WaitForChild("CameraAnchor") :: BasePart
	base = anchor.CFrame

	connectInput()
	player:GetAttributeChangedSignal("OnShift"):Connect(applyMode)
	player.CharacterAdded:Connect(function()
		eyeOffset = nil
		task.defer(applyMode)
	end)
	applyMode()

	RunService:BindToRenderStep("LastFerryCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local camera = workspace.CurrentCamera
		local ease = 1 - math.exp(-dt * 10)
		local now = os.clock()
		local shake = Vector3.zero
		if now < shakeUntil then
			local fade = (shakeUntil - now) * shakeStrength
			shake = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * fade * 0.25
		end

		local wantFov = if inBooth then math.min(targetFov, WIDE - (WIDE - NARROW) * triggerLean) else WIDE
		fov += (wantFov - fov) * ease
		camera.FieldOfView = fov

		local view = cinematic
		if view then
			-- Turn from where the view started toward the scene, then hold there.
			local t = math.clamp((now - view.started) / TURN_TIME, 0, 1)
			local turned = 1 - (1 - t) ^ 3
			local target = CFrame.new(view.from.Position)
				* windowRotation()
				* CFrame.Angles(0, view.yaw, 0)
				* CFrame.Angles(view.pitch, 0, 0)
			local frame = view.from:Lerp(target, turned)
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = frame * CFrame.Angles(shake.Y * 0.1, shake.X * 0.1, 0)
			camera.Focus = frame * CFrame.new(0, 0, -8)
			return
		end

		local h = humanoid()
		if h == nil or not inBooth then
			return
		end
		-- One eye height for everyone, measured while standing (not mid-jump).
		local natural = naturalEyeY(h)
		if natural and h.FloorMaterial ~= Enum.Material.Air then
			local want = EYE_HEIGHT - natural
			eyeOffset = if eyeOffset == nil then want else eyeOffset + (want - eyeOffset) * ease
		end
		local offset = Vector3.new(shake.X, (eyeOffset or 0) + shake.Y, 0)
		if h.CameraOffset ~= offset then
			h.CameraOffset = offset
		end
	end)
end

return CameraController
