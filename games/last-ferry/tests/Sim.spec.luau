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

-- A place with only a spawn pad, so the tests below don't depend on the game's world.
local function bareSim()
	local sim = Sim.new({ root = "." })
	sim:execute([[
		game:GetService("Players").CharacterAutoLoads = true
		local pad = Instance.new("SpawnLocation")
		pad.Size = Vector3.new(6, 1, 6)
		pad.CFrame = CFrame.new(10, 0.5, 20) * CFrame.Angles(0, math.rad(90), 0)
		pad.Anchored = true
		pad.Parent = workspace
	]])
	return sim
end

T.test("characters spawn on a SpawnLocation as Roblox's R15 rig", function()
	local sim = bareSim()
	local seen = sim:execute([[
		local Players = game:GetService("Players")
		local seen = {}
		Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function(character)
				-- Handlers run after the engine has parented and placed the character.
				table.insert(seen, { character = character, parented = character.Parent == workspace })
			end)
		end)
		return seen
	]])
	local alice = sim:addPlayer("Alice", 101)
	local character = alice.Character
	T.expect(character ~= nil and character.Parent == sim.workspace, "Alice has a character in the workspace")
	T.equal(#seen, 1, "CharacterAdded fired once")
	T.expect(seen[1].parented, "CharacterAdded handlers see the character in the workspace")
	local root = character.HumanoidRootPart
	local V = roblox.Vector3
	-- On top of the pad (top at y = 1): root 2.35 above the feet.
	near(root.Position, V.new(10, 3.35, 20), "standing on the spawn pad")
	-- Facing the way the pad faces (turned 90 degrees: -X).
	near(root.CFrame.LookVector, V.new(-1, 0, 0), "facing the pad's way")
	near(character.Head.Position, V.new(10, 5.5, 20), "the head on the neck")
	near(character.LeftFoot.Position, V.new(10, 1.15, 20.5), "feet on the pad")
	T.equal(character.Humanoid.RigType, roblox.Enum.HumanoidRigType.R15)
	T.equal(character.Humanoid.RootPart, root, "Humanoid.RootPart")
	T.expect(character.Head:FindFirstChild("HatAttachment") ~= nil, "accessory attachments")
	near(character.Head.HatAttachment.WorldPosition, V.new(10, 6.1, 20), "HatAttachment in the world")

	-- LoadCharacterAsync replaces the character (server only).
	local old = character
	sim:execute([[
		local player = game:GetService("Players"):GetPlayers()[1]
		player:LoadCharacterAsync()
	]])
	T.expect(alice.Character ~= old and old.Parent == nil, "a fresh character replaces the old one")
	sim:removePlayer(alice)
	T.expect(sim.workspace:FindFirstChild("Alice") == nil, "leaving removes the character")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("Humanoid:AddAccessory welds a hat to the head's HatAttachment", function()
	local sim = bareSim()
	local alice = sim:addPlayer("Alice", 101)
	local hat = sim:execute([[
		local character = game:GetService("Players"):GetPlayers()[1].Character
		local accessory = Instance.new("Accessory")
		accessory.Name = "Cap"
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 0.4, 1)
		handle.Parent = accessory
		local attachment = Instance.new("Attachment")
		attachment.Name = "HatAttachment"
		attachment.Position = Vector3.new(0, -0.2, 0)
		attachment.Parent = handle
		character.Humanoid:AddAccessory(accessory)
		return accessory
	]])
	local V = roblox.Vector3
	T.equal(hat.Parent, alice.Character, "the accessory is on the character")
	near(hat.Handle.Position, V.new(10, 6.3, 20), "the cap sits on top of the head")
	sim:moveCharacter(alice, V.new(0, 0, 0))
	near(hat.Handle.Position, V.new(0, 5.3, 0), "the cap goes where the character goes")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("a ProximityPrompt only triggers when enabled and within reach", function()
	local sim = bareSim()
	local log = sim:execute([[
		local post = Instance.new("Part")
		post.Name = "Post"
		post.Anchored = true
		post.CFrame = CFrame.new(10, 3, 30)
		post.Parent = workspace
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Clock in"
		prompt.MaxActivationDistance = 8
		prompt.Parent = post
		local log = {}
		prompt.Triggered:Connect(function(player)
			table.insert(log, player.Name)
		end)
		return log
	]])
	local alice = sim:addPlayer("Alice", 101)
	local prompt = sim.workspace.Post.ProximityPrompt
	local far = pcall(sim.triggerPrompt, sim, alice, prompt)
	T.expect(not far, "10 studs away is out of reach")
	sim:moveCharacter(alice, roblox.Vector3.new(10, 0, 26))
	sim:triggerPrompt(alice, prompt)
	T.equal(table.concat(log, ","), "Alice", "the server saw Alice trigger it")
	prompt.Enabled = false
	T.expect(not pcall(sim.triggerPrompt, sim, alice, prompt), "a disabled prompt can't be triggered")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("ContextActionService: higher priority first, Pass falls through, Sink stops", function()
	local sim = bareSim()
	local alice = sim:addPlayer("Alice", 101)
	local log = {}
	-- Bind from Alice's client, as a client script would.
	sim:runAsClient(alice, function(env)
		local ContextActionService = env.game:GetService("ContextActionService")
		local UserInputService = env.game:GetService("UserInputService")
		ContextActionService:BindActionAtPriority("Jump", function(_, state)
			if state == env.Enum.UserInputState.Begin then
				table.insert(log, "jump")
			end
			return env.Enum.ContextActionResult.Sink
		end, false, env.Enum.ContextActionPriority.Medium.Value, env.Enum.KeyCode.ButtonA)
		ContextActionService:BindActionAtPriority("Board", function(_, state)
			if state ~= env.Enum.UserInputState.Begin then
				return env.Enum.ContextActionResult.Pass
			end
			if log.windowOpen then
				table.insert(log, "board")
				return env.Enum.ContextActionResult.Sink
			end
			return env.Enum.ContextActionResult.Pass
		end, false, env.Enum.ContextActionPriority.High.Value, env.Enum.KeyCode.ButtonA)
		UserInputService.InputBegan:Connect(function(input, processed)
			table.insert(log, `input {input.KeyCode.Name} {processed}`)
		end)
	end)
	sim:pressKey(roblox.Enum.KeyCode.ButtonA, alice)
	log.windowOpen = true
	sim:pressKey(roblox.Enum.KeyCode.ButtonA, alice)
	T.equal(table.concat(log, "; "), "jump; input ButtonA true; board; input ButtonA true")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

return nil
