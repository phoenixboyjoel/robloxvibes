--!nonstrict
--[[
	The simulator's own engine behaviour that the game relies on: assemblies
	(WeldConstraint), joints (Motor6D, Weld), pivots, characters, accessories,
	prompts, input, tags, easing and attributes.
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

T.test("CollectionService: tags, and signals for tagged instances in the game", function()
	local sim = Sim.new({ root = "." })
	local log = sim:execute([[
		local CollectionService = game:GetService("CollectionService")
		local log = {}
		CollectionService:GetInstanceAddedSignal("Glide"):Connect(function(instance)
			table.insert(log, "+" .. instance.Name)
		end)
		CollectionService:GetInstanceRemovedSignal("Glide"):Connect(function(instance)
			table.insert(log, "-" .. instance.Name)
		end)
		return log
	]])
	local model = sim:execute([[
		local model = Instance.new("Model")
		local hull = Instance.new("Part")
		hull.Name = "Hull"
		hull:AddTag("Glide")
		hull.Parent = model
		return model
	]])
	local CollectionService = sim.game:GetService("CollectionService")
	local hull = model.Hull
	T.equal(#log, 0, "nothing fires for an instance outside the game")
	T.equal(#CollectionService:GetTagged("Glide"), 0, "and GetTagged doesn't find it")
	T.expect(hull:HasTag("Glide") and CollectionService:HasTag(hull, "Glide"), "but it has the tag")
	T.equal(table.concat(hull:GetTags(), ","), "Glide")

	model.Parent = sim.workspace
	sim:drain()
	T.equal(table.concat(log, " "), "+Hull", "added fires when a tagged instance enters the game")
	T.equal(CollectionService:GetTagged("Glide")[1], hull, "GetTagged finds it")
	hull:RemoveTag("Glide")
	hull:AddTag("Glide")
	model.Parent = nil
	model.Parent = sim.workspace
	model:Destroy()
	sim:drain()
	T.equal(table.concat(log, " "), "+Hull -Hull +Hull -Hull +Hull -Hull", "every change in the game fires")
	T.equal(#CollectionService:GetTagged("Glide"), 0, "a destroyed instance isn't tagged any more")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("TweenService:GetValue follows Roblox's easing curves", function()
	local sim = Sim.new({ root = "." })
	local v = sim:execute([[
		local TweenService = game:GetService("TweenService")
		local S, D = Enum.EasingStyle, Enum.EasingDirection
		local peak = 0
		for t = 0, 1, 0.01 do
			peak = math.max(peak, TweenService:GetValue(t, S.Back, D.Out))
		end
		return {
			linear = TweenService:GetValue(0.5, S.Linear, D.In),
			quadIn = TweenService:GetValue(0.5, S.Quad, D.In),
			quadOut = TweenService:GetValue(0.5, S.Quad, D.Out),
			quadInOut = TweenService:GetValue(0.25, S.Quad, D.InOut),
			sineOut = TweenService:GetValue(0.5, S.Sine, D.Out),
			backPeak = peak,
			backEnd = TweenService:GetValue(1, S.Back, D.Out),
			bounceHit = TweenService:GetValue(1 / 2.75, S.Bounce, D.Out),
			bouncePeak = (function()
				local most = 0
				for t = 0, 1, 0.01 do
					most = math.max(most, TweenService:GetValue(t, S.Bounce, D.Out))
				end
				return most
			end)(),
			bounceBack = TweenService:GetValue(0.55, S.Bounce, D.Out),
			below = TweenService:GetValue(-1, S.Linear, D.In),
			above = TweenService:GetValue(2, S.Quad, D.Out),
		}
	]])
	local function close(actual, expected, label)
		T.expect(math.abs(actual - expected) < 1e-3, `{label}: expected {expected}, got {actual}`)
	end
	close(v.linear, 0.5, "Linear")
	close(v.quadIn, 0.25, "Quad In")
	close(v.quadOut, 0.75, "Quad Out")
	close(v.quadInOut, 0.125, "Quad InOut")
	close(v.sineOut, math.sin(math.pi / 4), "Sine Out")
	close(v.backPeak, 1.1, "Back Out overshoots by a tenth")
	close(v.backEnd, 1, "and ends at 1")
	close(v.bounceHit, 1, "Bounce Out first reaches the end at 1/2.75")
	close(v.bouncePeak, 1, "and never passes it")
	T.expect(v.bounceBack < 1, `it bounces back off it ({v.bounceBack})`)
	close(v.below, 0, "alpha is clamped below")
	close(v.above, 1, "and above")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("a part pivots about its PivotOffset; a model about its PrimaryPart's pivot", function()
	local sim = Sim.new({ root = "." })
	local door, model = sim:execute([[
		local door = Instance.new("Part")
		door.Size = Vector3.new(2.6, 6.9, 0.25)
		door.CFrame = CFrame.new(0, 3.45, 8)
		door.PivotOffset = CFrame.new(-1.3, 0, 0)
		door.Anchored = true
		door.Parent = workspace
		local model = Instance.new("Model")
		local hull = Instance.new("Part")
		hull.CFrame = CFrame.new(5, 0, 0)
		hull.PivotOffset = CFrame.new(0, -2, 0)
		hull.Parent = model
		model.PrimaryPart = hull
		model.Parent = workspace
		return door, model
	]])
	local V = roblox.Vector3
	near(door:GetPivot().Position, V.new(-1.3, 3.45, 8), "the door's pivot is its hinged edge")
	door:PivotTo(door:GetPivot() * roblox.CFrame.Angles(0, math.rad(-90), 0))
	near(door:GetPivot().Position, V.new(-1.3, 3.45, 8), "turning it leaves the hinge where it was")
	T.expect(math.abs(door.CFrame.LookVector.Z) < 1e-3, `and turns the door a quarter turn ({door.CFrame.LookVector})`)
	near(model:GetPivot().Position, V.new(5, -2, 0), "the model's pivot is its PrimaryPart's")
	model:PivotTo(roblox.CFrame.new(0, 0, 0))
	near(model.PrimaryPart.Position, V.new(0, 2, 0), "and it moves by it")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("attributes hold only the types Roblox allows, under valid names", function()
	local sim = Sim.new({ root = "." })
	local r = sim:execute([[
		local part = Instance.new("Part")
		local function try(name, value)
			return (pcall(part.SetAttribute, part, name, value))
		end
		return {
			cframe = try("GlideFrom", CFrame.new(1, 2, 3)),
			number = try("GlideTime", 1.5),
			string = try("GlideStyle", "Quad"),
			boolean = try("Lit", true),
			vector = try("Where", Vector3.one),
			tableValue = try("List", {}),
			instance = try("Other", part),
			space = try("Two words", 1),
			reserved = try("RBXThing", 1),
			long = try(string.rep("a", 101), 1),
			path = try("Glide.Id-2/x_y", 1),
			cleared = try("GlideTime", nil) and part:GetAttribute("GlideTime") == nil,
		}
	]])
	for _, ok in { "cframe", "number", "string", "boolean", "vector", "path", "cleared" } do
		T.expect(r[ok], `{ok} is allowed`)
	end
	for _, bad in { "tableValue", "instance", "space", "reserved", "long" } do
		T.expect(not r[bad], `{bad} is refused`)
	end
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

T.test("GUI layout: where things are on screen, as Roblox lays them out", function()
	local sim = Sim.new({
		root = ".",
		screen = roblox.Vector2.new(844, 390),
		safeArea = roblox.Vector2.new(750, 332),
		topbarInset = roblox.Rect.new(253, 0, 750, 58),
	})
	local gui = sim:execute([[
		local gui = Instance.new("ScreenGui")
		gui.Name = "Hud"
		gui.Parent = game:GetService("StarterGui")
		-- A canvas scaled down to half, like the HUD's.
		local root = Instance.new("Frame")
		root.Name = "Root"
		root.Size = UDim2.fromScale(2, 2)
		root.Parent = gui
		local scale = Instance.new("UIScale")
		scale.Scale = 0.5
		scale.Parent = root
		local panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.AnchorPoint = Vector2.new(1, 0)
		panel.Position = UDim2.new(1, -16, 0, 70)
		panel.Size = UDim2.new(0, 250, 1, -86)
		panel.Parent = root
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingTop = UDim.new(0, 20)
		padding.Parent = panel
		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 4)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.Parent = panel
		for i, name in { "Second", "First", "Hidden" } do
			local row = Instance.new("Frame")
			row.Name = name
			row.Size = UDim2.fromOffset(100, 30)
			row.LayoutOrder = if name == "First" then 1 else 2
			row.Visible = name ~= "Hidden"
			row.Parent = panel
		end
		-- A label that wraps and grows to fit its text.
		local label = Instance.new("TextLabel")
		label.Name = "Note"
		label.Size = UDim2.fromOffset(100, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextWrapped = true
		label.TextSize = 10
		label.Text = "one two three four five six"
		label.LayoutOrder = 3
		label.Parent = panel
		-- The top bar row, and the whole screen.
		local top = Instance.new("ScreenGui")
		top.Name = "Top"
		top.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
		top.Parent = gui.Parent
		local full = Instance.new("ScreenGui")
		full.Name = "Full"
		full.ScreenInsets = Enum.ScreenInsets.None
		full.Parent = gui.Parent
		return gui
	]])
	local V2 = roblox.Vector2.new
	near(
		gui.AbsolutePosition,
		V2(0, 0),
		"GUI coordinates start where a safe-area ScreenGui does: below the top bar, clear of the notch"
	)
	near(gui.AbsoluteSize, V2(750, 332), "and covers the safe area")
	local root = gui.Root
	near(root.AbsoluteSize, V2(750, 332), "a canvas twice the size, scaled by half, fits the screen")
	local panel = root.Panel
	-- The canvas is 1500 x 664 before scaling: the panel is 250 wide, 16 in from the right.
	near(panel.AbsoluteSize, V2(125, (664 - 86) / 2), "a panel's size is scaled with everything in it")
	near(panel.AbsolutePosition, V2((1500 - 16 - 250) / 2, 35), "and so is where it is")
	local inside = panel.AbsolutePosition + V2(5, 10) -- inside the padding, at half scale
	near(
		panel.First.AbsolutePosition,
		V2(inside.X + (125 - 5 - 50) / 2, inside.Y),
		"the list goes in LayoutOrder, centred"
	)
	near(
		panel.Second.AbsolutePosition,
		V2(inside.X + (125 - 5 - 50) / 2, inside.Y + 15 + 2),
		"each after the last and the gap"
	)
	near(panel.Note.AbsolutePosition, V2(inside.X + (125 - 5 - 50) / 2, inside.Y + 34), "a hidden row takes no room")
	T.expect(panel.Note.AbsoluteSize.Y > 5, `a wrapped label grows to fit its lines ({panel.Note.AbsoluteSize})`)
	T.equal(panel.Note.AbsoluteSize.Y, panel.Note.TextBounds.Y / 2, "its text's height, scaled")
	local top = gui.Parent.Top
	near(
		top.AbsolutePosition,
		V2(253, -58),
		"a TopbarSafeInsets ScreenGui is in Roblox's top bar row, beside its buttons"
	)
	near(top.AbsoluteSize, V2(497, 58), "as wide as the room Roblox leaves there")
	T.equal(sim.game:GetService("GuiService").TopbarInset, roblox.Rect.new(253, 0, 750, 58))
	near(
		gui.Parent.Full.AbsolutePosition,
		V2(-47, -58),
		"a full-screen ScreenGui starts at the screen's corner, under the notch"
	)
	near(gui.Parent.Full.AbsoluteSize, V2(844, 390), "and covers all of it")
	-- The camera draws the whole screen, but its viewport coordinates start at the device
	-- safe area's top-left, and its screen coordinates are GUI coordinates.
	local camera = sim.workspace.CurrentCamera
	near(camera.ViewportSize, V2(750, 390), "the viewport is the device safe area")
	camera.CFrame = roblox.CFrame.new(0, 10, 0)
	local ahead = roblox.Vector3.new(0, 10, -20)
	local viewportPoint = camera:WorldToViewportPoint(ahead)
	local screenPoint = camera:WorldToScreenPoint(ahead)
	near(
		V2(viewportPoint.X, viewportPoint.Y),
		V2(844 / 2 - 47, 390 / 2),
		"straight ahead is the screen's middle, in viewport terms"
	)
	near(V2(screenPoint.X, screenPoint.Y), V2(844 / 2 - 47, 390 / 2 - 58), "and in GUI terms")
	-- IgnoreGuiInset moves a ScreenGui between the two safe areas, as Roblox's docs say.
	local ignoring = sim:execute([[
		local gui = Instance.new("ScreenGui")
		gui.IgnoreGuiInset = true
		gui.Parent = game:GetService("StarterGui")
		return gui
	]])
	T.equal(ignoring.ScreenInsets, roblox.Enum.ScreenInsets.DeviceSafeInsets, "IgnoreGuiInset: over the top bar")
	near(ignoring.AbsolutePosition, V2(0, -58), "from the top of the screen")
	ignoring.IgnoreGuiInset = false
	T.equal(ignoring.ScreenInsets, roblox.Enum.ScreenInsets.CoreUISafeInsets, "and back below it")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

-- A label's TextBounds for `text` in `font` (Luau that makes the Font) at `size`, wrapped at
-- `width` if given.
local function textBounds(sim, font: string, size: number, text: string, width: number?, rich: boolean?)
	return sim:execute(string.format(
		[[
		local gui = Instance.new("ScreenGui")
		local label = Instance.new("TextLabel")
		label.FontFace = %s
		label.TextSize = %d
		label.Text = %q
		label.RichText = %s
		label.TextWrapped = %s
		label.Size = UDim2.fromOffset(%d, 1000)
		label.Parent = gui
		gui.Parent = game:GetService("StarterGui")
		return label.TextBounds
	]],
		font,
		size,
		text,
		tostring(rich == true),
		tostring(width ~= nil),
		width or 1000
	))
end

local GOTHAM = 'Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)'
local BUILDER_BOLD = "Font.fromEnum(Enum.Font.BuilderSansBold)"

T.test("text is as wide as it is in Roblox's own fonts, and wraps as Roblox wraps it", function()
	local sim = Sim.new({ root = "." })
	local V2 = roblox.Vector2.new
	T.equal(textBounds(sim, GOTHAM, 16, "Evening, clerk."), V2(119, 16), "Gotham, which Roblox draws as Montserrat")
	T.equal(textBounds(sim, BUILDER_BOLD, 18, "NIGHT 1 / 5"), V2(93, 18), "Builder Sans Bold")
	T.equal(textBounds(sim, BUILDER_BOLD, 16, "TAKE\nPAGE").Y, 32, "a line break starts a new line")
	local name = textBounds(sim, GOTHAM, 16, string.rep("W", 20), 300)
	T.equal(name.Y, 32, "a word wider than the line is broken across two")
	T.expect(name.X <= 300, `and neither line is wider than the label ({name.X})`)
	T.equal(
		textBounds(sim, BUILDER_BOLD, 18, "<b>NIGHT</b> 1 / 5", nil, true),
		V2(93, 18),
		"rich text's tags take no room"
	)
	local line = textBounds(sim, GOTHAM, 16, "Petrel's a good boat. Better than the old one.", 300)
	T.equal(line.Y, 32, "a line longer than the label wraps between words")
	-- Wrapped text too tall for its label: the lines that don't fit aren't drawn.
	local fits, bounds = sim:execute([[
		local gui = Instance.new("ScreenGui")
		local label = Instance.new("TextLabel")
		label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		label.TextSize = 16
		label.TextWrapped = true
		label.Text = "Petrel's a good boat. Better than the old one."
		label.Size = UDim2.fromOffset(300, 20)
		label.Parent = gui
		gui.Parent = game:GetService("StarterGui")
		return label.TextFits, label.TextBounds
	]])
	T.equal(fits, false, "text too tall for its label doesn't fit")
	T.equal(bounds.Y, 16, "and only the line that fits is measured")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("fonts load late: text measures as a stand-in font's until then, and PreloadAsync waits", function()
	local sim = Sim.new({ root = ".", fontsLoadAt = 5 })
	local label = sim:execute([[
		local gui = Instance.new("ScreenGui")
		local label = Instance.new("TextLabel")
		label.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		label.TextSize = 18
		label.Text = "NIGHT 1 / 5"
		label.Parent = gui
		gui.Parent = game:GetService("StarterGui")
		task.spawn(function()
			game:GetService("ContentProvider"):PreloadAsync({ label })
			label:SetAttribute("Loaded", true)
		end)
		return label
	]])
	sim:run(4)
	T.equal(label:GetAttribute("Loaded"), nil, "PreloadAsync is still waiting for the font")
	local early = label.TextBounds.X
	T.expect(early < 93, `measured as a stand-in font's meanwhile ({early})`)
	sim:run(1.5)
	T.equal(label:GetAttribute("Loaded"), true, "then it returns")
	T.equal(label.TextBounds.X, 93, "and the text measures as its own font's")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

T.test("GuiService.ViewportDisplaySize: small on a phone, medium on a computer, large on a TV", function()
	local sizes = roblox.Enum.DisplaySize
	local phone = Sim.new({ root = ".", preferredInput = roblox.Enum.PreferredInput.Touch })
	T.equal(phone.game:GetService("GuiService").ViewportDisplaySize, sizes.Small)
	T.equal(Sim.new({ root = "." }).game:GetService("GuiService").ViewportDisplaySize, sizes.Medium)
	T.equal(Sim.new({ root = ".", tenFoot = true }).game:GetService("GuiService").ViewportDisplaySize, sizes.Large)
end)

return nil
