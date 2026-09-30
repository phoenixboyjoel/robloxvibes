--!nonstrict
--[[
	Runs the real game in the headless simulator until a passenger is standing at
	the window, then writes every visible part, the booth lamp, the camera and the
	passengers' particle emitters to JSON for tools/preview/render.py.

	Run from the game folder:
		lune run tools/preview/export.luau first  preview/first.json
		lune run tools/preview/export.luau wet    preview/wet.json

	Scenarios:
		first - the first passenger of night 1 (a regular: dry, breathing, casting a shadow)
		wet   - the first dripping passenger of night 1 (one of the drowned)
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Sim = require("../../tests/sim/Roblox")

local scenario = process.args[1] or "first"
local outPath = process.args[2] or "preview/scene.json"

local sim = Sim.new({ root = "." })
sim:startServer()
sim:run(1)
local player = sim:addPlayer("Preview", 1)

local function hud()
	return player.PlayerGui.LastFerryHud.Root
end

local function atWindow()
	for _, model in sim.workspace.World.Passengers:GetChildren() do
		local rootPart = model:FindFirstChild("Root")
		if rootPart then
			local position = rootPart.Position
			if math.abs(position.X) < 0.5 and math.abs(position.Z + 3.2) < 0.5 then
				return model
			end
		end
	end
	return nil
end

local lastCard = ""
local done = sim:runUntil(function()
	local root = hud()
	local overlay = root.Overlay
	if overlay.Visible then
		local continue = overlay.Card.Footer.Continue
		local key = overlay.Card.Header.Title.Text
		if key ~= lastCard then
			lastCard = key
		elseif sim:shown(continue) and continue.Interactable then
			sim:click(continue)
		end
		return false
	end
	local board = root.Play.Desk.Board
	local model = atWindow()
	if model == nil or not board.Interactable then
		return false
	end
	local wet = model:FindFirstChild("Drips", true) ~= nil
	if scenario == "first" or (scenario == "wet" and wet) then
		return true
	end
	sim:click(board)
	return false
end, 1200, 1 / 20)
assert(done, "never reached the scenario")
sim:run(6.5) -- let the puddle spread to full size
-- Don't catch the booth lamp mid-flicker.
sim:runUntil(function()
	local bulb = sim.workspace.World.Booth:FindFirstChild("LampBulb")
	return bulb ~= nil and bulb.Transparency == 0
end, 3, 1 / 20)

local parts = {}
local emitters = {}
local camera = nil
local lamp = nil

local function components(cframe)
	return { cframe:GetComponents() }
end

for _, instance in sim.workspace:GetDescendants() do
	if instance:IsA("BasePart") then
		if instance.Name == "CameraAnchor" then
			camera = components(instance.CFrame)
		end
		local light = instance:FindFirstChildOfClass("SpotLight")
		if instance.Name == "LampBulb" and light then
			lamp = {
				cframe = components(instance.CFrame),
				angle = light.Angle,
				range = light.Range,
				brightness = light.Brightness,
				color = { light.Color.R, light.Color.G, light.Color.B },
			}
		end
		if instance.Transparency < 0.98 then
			table.insert(parts, {
				name = instance.Name,
				shape = if instance:IsA("Part") then instance.Shape.Name else "Block",
				size = { instance.Size.X, instance.Size.Y, instance.Size.Z },
				cframe = components(instance.CFrame),
				color = { instance.Color.R, instance.Color.G, instance.Color.B },
				transparency = instance.Transparency,
				castShadow = instance.CastShadow,
				material = instance.Material.Name,
			})
		end
	elseif instance:IsA("ParticleEmitter") and instance.Enabled then
		local attachment = instance.Parent
		local part = attachment and attachment.Parent
		if attachment and attachment:IsA("Attachment") and part and part:IsA("BasePart") then
			local position = part.CFrame * attachment.Position
			local facing = part.CFrame.LookVector
			table.insert(emitters, {
				name = instance.Name,
				position = { position.X, position.Y, position.Z },
				facing = { facing.X, facing.Y, facing.Z },
			})
		end
	end
end

assert(#sim.errors == 0, table.concat(sim.errors, "\n"))
local parent = string.match(outPath, "^(.*)/[^/]+$")
if parent and not fs.isDir(parent) then
	fs.writeDir(parent)
end
fs.writeFile(
	outPath,
	serde.encode("json", {
		scenario = scenario,
		camera = camera,
		lamp = lamp,
		parts = parts,
		emitters = emitters,
		waterLevel = -2,
	})
)
print(`wrote {outPath}: {#parts} parts, {#emitters} emitters, at {math.floor(sim.now)} s`)
