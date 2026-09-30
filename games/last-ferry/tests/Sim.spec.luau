--!nonstrict
--[[
	The simulator's own engine behaviour that the game relies on: assemblies
	(WeldConstraint), joints (Motor6D, Weld) and model pivots.
]]

local roblox = require("@lune/roblox")

local Sim = require("./sim/Roblox")
local T = require("./TestLib")

T.suite("Simulator")

local function near(a, b, label: string)
	T.expect((a - b).Magnitude < 1e-3, `{label}: expected {b}, got {a}`)
end

-- A classic R6 rig with Roblox's standard joint frames.
local R6 = [[
	local model = Instance.new("Model")
	local function part(name, size)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Parent = model
		return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1))
	root.Anchored = true
	root.CFrame = CFrame.new(0, 3, 0)
	local torso = part("Torso", Vector3.new(2, 2, 1))
	local head = part("Head", Vector3.new(2, 1, 1))
	local rightArm = part("Right Arm", Vector3.new(1, 2, 1))
	local leftLeg = part("Left Leg", Vector3.new(1, 2, 1))
	local function motor(name, parent, part0, part1, c0, c1)
		local m = Instance.new("Motor6D")
		m.Name = name
		m.Part0 = part0
		m.Part1 = part1
		m.C0 = c0
		m.C1 = c1
		m.Parent = parent
		return m
	end
	local rootFrame = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	motor("RootJoint", root, root, torso, rootFrame, rootFrame)
	motor("Neck", torso, torso, head, CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	local shoulder = motor("Right Shoulder", torso, torso, rightArm, CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	motor("Left Hip", torso, torso, leftLeg, CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	model.PrimaryPart = root
	model.Parent = workspace
	return model, root, torso, head, rightArm, leftLeg, shoulder
]]

T.test("an R6 rig poses from its Motor6Ds and follows its root", function()
	local sim = Sim.new({ root = "." })
	local model, root, torso, head, rightArm, leftLeg, shoulder = sim:execute(R6)
	local V = roblox.Vector3
	near(torso.Position, V.new(0, 3, 0), "torso on the root")
	near(head.Position, V.new(0, 4.5, 0), "head on the neck")
	near(rightArm.Position, V.new(1.5, 3, 0), "right arm at the shoulder")
	near(leftLeg.Position, V.new(-0.5, 1, 0), "left leg at the hip")

	-- Moving the root carries the whole rig.
	root.CFrame = roblox.CFrame.new(10, 3, -5)
	near(head.Position, V.new(10, 4.5, -5), "head follows the root")
	near(leftLeg.Position, V.new(9.5, 1, -5), "leg follows the root")

	-- Swinging the arm forward 90 degrees about the shoulder.
	shoulder.Transform = roblox.CFrame.Angles(0, 0, math.rad(90))
	local arm = rightArm.CFrame
	T.expect(math.abs(arm.UpVector.Y) < 1e-3, `the arm is horizontal (up vector {arm.UpVector})`)
	T.expect(math.abs(arm.Position.Y - 3.5) < 1e-3, `the arm swings about the shoulder (y {arm.Position.Y})`)

	-- PivotTo moves every part once, not twice.
	model:PivotTo(roblox.CFrame.new(0, 3, 20))
	near(root.Position, V.new(0, 3, 20), "root pivoted")
	near(leftLeg.Position, V.new(-0.5, 1, 20), "leg pivoted once")
	T.equal(#sim.errors, 0, "no errors")
end)

return nil
