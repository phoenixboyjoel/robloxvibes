--!strict
--[[
	CrowdController: brings the passengers to life on each client.

	Passengers are classic Robloxians whose limbs hang on Roblox's standard R6
	joints. This swings those joints with the classic Roblox walk (arms and legs
	in opposite pairs, faster and wider the faster they go) while a passenger
	moves, and a slow idle sway and look-around while they stand. Animation
	isn't a tell: everyone moves the same way whatever they are.

	It sets Motor6D.Transform in PreSimulation, as Roblox recommends for custom
	animation. Transforms are local to each client, so the server does nothing.
]]

local RunService = game:GetService("RunService")

local CrowdController = {}

local WALK_SWING = 0.7 -- radians at full stride
local STRIDE_SPEED = 7 -- studs per second at which the stride is full
local STRIDE_RATE = 1.25 -- radians of the walk cycle per stud travelled

type Walker = {
	root: BasePart,
	torso: BasePart,
	last: Vector3,
	speed: number,
	phase: number,
	seed: number,
}

local function joint(torso: BasePart, name: string): Motor6D?
	local found = torso:FindFirstChild(name)
	return if found and found:IsA("Motor6D") then found else nil
end

local function pose(torso: BasePart, name: string, transform: CFrame)
	local motor = joint(torso, name)
	if motor then
		motor.Transform = transform
	end
end

function CrowdController.start()
	local folder = workspace:WaitForChild("World"):WaitForChild("Passengers")
	local walkers: { [Instance]: Walker } = {}
	local count = 0

	local function track(model: Instance)
		if not model:IsA("Model") then
			return
		end
		local root = model:WaitForChild("HumanoidRootPart", 10)
		local torso = model:WaitForChild("Torso", 10)
		if not (root and root:IsA("BasePart") and torso and torso:IsA("BasePart")) or model.Parent ~= folder then
			return
		end
		count += 1
		walkers[model] = {
			root = root,
			torso = torso,
			last = root.Position,
			speed = 0,
			phase = 0,
			seed = count * 1.618,
		}
	end

	folder.ChildAdded:Connect(function(child)
		task.spawn(track, child)
	end)
	folder.ChildRemoved:Connect(function(child)
		walkers[child] = nil
	end)
	for _, child in folder:GetChildren() do
		task.spawn(track, child)
	end

	RunService.PreSimulation:Connect(function(dt: number)
		if dt <= 0 then
			return
		end
		local now = os.clock()
		for _, walker in walkers do
			local position = walker.root.Position
			local moved = Vector3.new(position.X - walker.last.X, 0, position.Z - walker.last.Z)
			walker.last = position
			local speed = moved.Magnitude / dt
			walker.speed += (speed - walker.speed) * (1 - math.exp(-dt * 10))
			local torso = walker.torso
			if walker.speed > 0.4 then
				walker.phase += dt * walker.speed * STRIDE_RATE
				local swing = WALK_SWING * math.min(1, walker.speed / STRIDE_SPEED) * math.sin(walker.phase)
				-- Mirrored joints: the same angle swings the arms in opposite directions,
				-- and the legs take the opposite of the arms, as in Roblox's classic walk.
				pose(torso, "Right Shoulder", CFrame.Angles(0, 0, swing))
				pose(torso, "Left Shoulder", CFrame.Angles(0, 0, swing))
				pose(torso, "Right Hip", CFrame.Angles(0, 0, -swing))
				pose(torso, "Left Hip", CFrame.Angles(0, 0, -swing))
				pose(torso, "Neck", CFrame.identity)
			else
				-- Standing: arms sway a little, and now and then they look about.
				local t = now + walker.seed * 10
				local sway = 0.05 * math.sin(t * 1.4)
				pose(torso, "Right Shoulder", CFrame.Angles(0, 0, sway))
				pose(torso, "Left Shoulder", CFrame.Angles(0, 0, -sway))
				pose(torso, "Right Hip", CFrame.identity)
				pose(torso, "Left Hip", CFrame.identity)
				pose(torso, "Neck", CFrame.Angles(0, 0, 0.18 * math.sin(t * 0.33)))
			end
		end
	end)
end

return CrowdController
