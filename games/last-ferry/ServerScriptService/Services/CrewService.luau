--!strict
--[[
	CrewService: the players themselves, as their own avatars.

	Between shifts everyone is on the pier behind the booth (the lobby): they spawn
	there, walk, jump, emote and read the notice board. Anyone can clock in at the time
	clock by the booth's back door (a ProximityPrompt), and then the whole server works
	the shift together: everyone is brought into the booth, each to a stand behind the
	counter, wearing the harbor's cap, and the door shuts behind them. After the ending
	they clock out onto the pier again.

	Anyone who joins or respawns mid-shift starts in the booth at a free stand, and
	anyone found outside the booth mid-shift is put back at theirs.

	A player's "OnShift" attribute tells their client which camera to use (see
	CameraController): Roblox's own third-person camera on the pier, first person in
	the booth. Shift Lock is off on shift: in first person it would only get in the
	way, and Roblox's camera drops Humanoid.CameraOffset while the mouse is locked,
	which would undo the booth's one eye height for every avatar.
]]

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local WorldService = require("./WorldService")

local CrewService = {}

local CAP = "ClerkCap"
local SHIFT_WALK_SPEED = 10 -- the booth is ten studs wide
local CHECK_EVERY = 1 -- seconds between checks that every clerk is in the booth
local NAVY = Color3.fromRGB(33, 52, 96)
local WHITE = Color3.fromRGB(242, 243, 243)
local BRASS = Color3.fromRGB(226, 176, 72)

local markers: WorldService.Markers
local onShift = false
local stands: { [Player]: number } = {}
-- What's been hidden under each player's cap, as the ways to put it all back.
local hiddenHats: { [Player]: { () -> () } } = {}

-- How far above its feet a standing character's root is.
local function rootHeight(character: Model, humanoid: Humanoid, root: BasePart): number
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		return humanoid.HipHeight + root.Size.Y / 2
	end
	local leg = character:FindFirstChild("Left Leg")
	local legLength = if leg and leg:IsA("BasePart") then leg.Size.Y else 2
	return legLength + root.Size.Y / 2 + humanoid.HipHeight
end

local function body(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if character == nil or character.Parent == nil then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = if humanoid then humanoid.RootPart else nil
	return character, humanoid, root
end

-- Stands the player's character with its feet at `feet`, facing the same way.
local function place(player: Player, feet: CFrame)
	local character, humanoid, root = body(player)
	if character and humanoid and root then
		character:PivotTo(feet * CFrame.new(0, rootHeight(character, humanoid, root), 0))
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local function freeStand(player: Player): number
	local current = stands[player]
	if current then
		return current
	end
	local taken: { [number]: boolean } = {}
	local count = 0
	for other, index in stands do
		if other.Parent == Players then
			taken[index] = true
			count += 1
		end
	end
	for index = 1, #markers.stands do
		if not taken[index] then
			return index
		end
	end
	return count % #markers.stands + 1 -- a full booth: share
end

-- The harbor's clerk cap: a captain's cap, the look every ferry hand knows. A white top
-- wider than its navy band, a black peak and a brass badge, built from parts so it needs
-- no assets. The Handle is an invisible block on the head's HatAttachment (the top of
-- the head); the cap's pieces are welded to it.
local function makeCap(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = CAP
	accessory.AccessoryType = Enum.AccessoryType.Hat

	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		if shape then
			p.Shape = shape
		end
		p.Size = size
		p.CFrame = offset
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CastShadow = false
		p.Parent = accessory
		return p
	end

	-- Cylinders run along X, so the round ones are turned upright.
	local upright = CFrame.Angles(0, 0, math.rad(90))
	local handle = piece("Handle", Vector3.new(0.4, 0.4, 0.4), CFrame.identity, NAVY)
	handle.Transparency = 1
	local pieces = {
		piece("Band", Vector3.new(0.28, 1.3, 1.3), CFrame.new(0, -0.02, 0) * upright, NAVY, Enum.PartType.Cylinder),
		piece("Top", Vector3.new(0.16, 1.52, 1.52), CFrame.new(0, 0.2, 0.02) * upright, WHITE, Enum.PartType.Cylinder),
		piece(
			"Peak",
			Vector3.new(1, 0.07, 0.45),
			CFrame.new(0, -0.12, -0.72) * CFrame.Angles(math.rad(-10), 0, 0),
			Color3.fromRGB(20, 24, 32)
		),
		piece("Badge", Vector3.new(0.26, 0.18, 0.05), CFrame.new(0, 0, -0.66), BRASS),
	}
	for _, p in pieces do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = p
		weld.Parent = p
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "HatAttachment" -- meets the head's HatAttachment
	attachment.Parent = handle
	return accessory
end

-- Hides one piece of a hat (its parts, decals and textures, and any sparkle, flame,
-- trail or light on it), noting how to put it back.
local function hide(item: Instance, putBack: { () -> () })
	if item:IsA("BasePart") then
		local was = item.Transparency
		item.Transparency = 1
		table.insert(putBack, function()
			item.Transparency = was
		end)
		return
	end
	if item:IsA("Decal") then -- Textures too
		local was = item.Transparency
		item.Transparency = 1
		table.insert(putBack, function()
			item.Transparency = was
		end)
		return
	end
	if
		item:IsA("ParticleEmitter")
		or item:IsA("Trail")
		or item:IsA("Beam")
		or item:IsA("Light")
		or item:IsA("Fire")
		or item:IsA("Smoke")
		or item:IsA("Sparkles")
	then
		-- All of these have Enabled, but strict Luau can't set it through their union.
		local effect = item :: any
		local was: boolean = effect.Enabled
		effect.Enabled = false
		table.insert(putBack, function()
			effect.Enabled = was
		end)
	end
end

-- Hats go under the cap for the shift (hair stays), and come back after.
local function wearCap(player: Player)
	local character, humanoid = body(player)
	if character == nil or humanoid == nil or character:FindFirstChild(CAP) then
		return
	end
	local putBack: { () -> () } = {}
	for _, accessory in humanoid:GetAccessories() do
		if accessory:IsA("Accessory") and accessory.AccessoryType == Enum.AccessoryType.Hat then
			for _, descendant in accessory:GetDescendants() do
				hide(descendant, putBack)
			end
		end
	end
	hiddenHats[player] = putBack
	humanoid:AddAccessory(makeCap())
end

local function takeOffCap(player: Player)
	local character = player.Character
	local cap = if character then character:FindFirstChild(CAP) else nil
	if cap then
		cap:Destroy()
	end
	local putBack = hiddenHats[player]
	if putBack then
		for _, restore in putBack do
			restore()
		end
	end
	hiddenHats[player] = nil
end

-- Brings one player into the shift: to a free stand, capped, walking at booth pace.
local function joinShift(player: Player)
	local _, humanoid = body(player)
	player:SetAttribute("OnShift", true)
	player.DevEnableMouseLock = false
	if humanoid == nil then
		return -- they'll be placed when their character spawns
	end
	local index = freeStand(player)
	stands[player] = index
	place(player, markers.stands[index])
	humanoid.WalkSpeed = SHIFT_WALK_SPEED
	wearCap(player)
end

-- Sends one player back to the pier, in a loose crowd round the spawn, facing the booth.
local function leaveShift(player: Player, slot: number)
	player:SetAttribute("OnShift", false)
	player.DevEnableMouseLock = StarterPlayer.EnableMouseLockOption
	takeOffCap(player)
	local _, humanoid = body(player)
	if humanoid then
		humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
		local column = (slot - 1) % 4
		local row = (slot - 1) // 4
		local feet = markers.pier + Vector3.new(-4.5 + column * 3, 0, -2 + row * 3)
		place(player, CFrame.lookAt(feet, Vector3.new(feet.X, feet.Y, 0)))
	end
end

local function onCharacter(player: Player, character: Model)
	if not character:IsDescendantOf(workspace) then
		character.AncestryChanged:Wait()
	end
	-- Let the engine finish loading the character (scaling it, putting it on a spawn)
	-- before moving it, whether events here run deferred (as this place is set) or not.
	task.wait()
	if onShift and player.Character == character then
		joinShift(player)
	end
end

-- Whether a character is inside the booth: within its walls and under its roof.
local function inBooth(root: BasePart): boolean
	local at = root.Position
	return math.abs(at.X) < 4.9 and at.Z > 0.2 and at.Z < 7.9 and at.Y < 8
end

-- Mid-shift, puts any clerk who has ended up outside the booth back at their stand: a
-- character that loaded on the pier just as the shift started, say.
local function keepInBooth()
	while true do
		task.wait(CHECK_EVERY)
		if onShift then
			for _, player in Players:GetPlayers() do
				local _, humanoid, root = body(player)
				if humanoid and root and player:GetAttribute("OnShift") == true and not inBooth(root) then
					joinShift(player)
				end
			end
		end
	end
end

function CrewService.start(worldMarkers: WorldService.Markers)
	markers = worldMarkers
	WorldService.setShift(false)

	local function watch(player: Player)
		player:SetAttribute("OnShift", onShift)
		player.CharacterAdded:Connect(function(character: Model)
			onCharacter(player, character)
		end)
		local character = player.Character
		if character then
			task.spawn(onCharacter, player, character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		stands[player] = nil
		hiddenHats[player] = nil
	end)
	task.spawn(keepInBooth)
end

-- Yields until someone who `canClockIn` presses the time clock's prompt, and returns them.
-- The prompt only shows between shifts.
function CrewService.waitForClockIn(canClockIn: (player: Player) -> boolean): Player
	local prompt = WorldService.clockPrompt()
	local clock = (prompt.Parent :: Attachment).WorldPosition
	local clocked: Player? = nil
	local connection = prompt.Triggered:Connect(function(player: Player)
		-- The engine checks the distance; check it again, generously, for anyone who
		-- fires the prompt from across the harbor.
		local _, _, root = body(player)
		local near = root ~= nil and (root.Position - clock).Magnitude <= prompt.MaxActivationDistance + 6
		if clocked == nil and near and canClockIn(player) then
			clocked = player
			prompt.Enabled = false
		end
	end)
	prompt.Enabled = true
	while clocked == nil do
		task.wait(0.1)
	end
	connection:Disconnect()
	prompt.Enabled = false
	return clocked :: Player
end

-- Everyone into the booth, and the door shuts.
function CrewService.startShift()
	onShift = true
	table.clear(stands)
	WorldService.setShift(true)
	for _, player in Players:GetPlayers() do
		joinShift(player)
	end
end

-- Everyone back out onto the pier, and the door opens.
function CrewService.endShift()
	onShift = false
	table.clear(stands)
	WorldService.setShift(false)
	for slot, player in Players:GetPlayers() do
		leaveShift(player, slot)
	end
end

return CrewService
