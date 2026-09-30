--!nonstrict
--[[
	Runs the real game in the headless simulator until a scenario is on screen,
	then writes the whole scene (world, lighting, camera and the player's GUI)
	to JSON for tools/preview/render.

	Run from the game folder:
		lune run tools/preview/export.luau <scenario> <out.json> [--screen=W,H] [--safe=W,H] [--touch]

	Scenarios:
		first  - the first passenger of night 1 at the window (a regular: dry, breathing, casting a shadow)
		wet    - the first dripping passenger of night 1 (one of the drowned)
		intro  - the night 1 title card, before the window opens
		queue  - between passengers, with the queue walking up

	--screen and --safe set the screen and its safe area in pixels (default 1280x720,
	safe 1280x684). --touch makes the game see a phone.
]]

local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Scene = require("./Scene")
local Sim = require("../../tests/sim/Roblox")

local args = {}
local flags = {}
for _, arg in process.args do
	local key, value = string.match(arg, "^%-%-([%w-]+)=?(.*)$")
	if key then
		flags[key] = if value == "" then true else value
	else
		table.insert(args, arg)
	end
end
local scenario = args[1] or "first"
local outPath = args[2] or `preview/{scenario}.json`

local function pair(text: string?): Vector2?
	if type(text) ~= "string" then
		return nil
	end
	local x, y = string.match(text, "^(%d+)[,x](%d+)$")
	return if x then roblox.Vector2.new(tonumber(x), tonumber(y)) else nil
end

local screen = pair(flags.screen)
local sim = Sim.new({
	root = ".",
	screen = screen,
	safeArea = pair(flags.safe) or (screen and roblox.Vector2.new(screen.X, screen.Y - 36)),
	preferredInput = if flags.touch then roblox.Enum.PreferredInput.Touch else nil,
})
sim:startServer()
sim:run(1)
local player = sim:addPlayer("Preview", 1)

local function hud()
	return player.PlayerGui.LastFerryHud.Root
end

local function atWindow()
	for _, model in sim.workspace.World.Passengers:GetChildren() do
		local rootPart = model:FindFirstChild("Root") or model:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local position = rootPart.Position
			if math.abs(position.X) < 0.5 and math.abs(position.Z + 3.2) < 0.5 then
				return model
			end
		end
	end
	return nil
end

-- Presses Continue on every card (once it's been up a moment) until `reached` says stop.
local lastCard = ""
local function playUntil(reached: () -> boolean, limit: number): boolean
	return sim:runUntil(function()
		local root = hud()
		local overlay = root.Overlay
		if overlay.Visible then
			if reached() then
				return true
			end
			local continue = overlay.Card.Footer.Continue
			local key = overlay.Card.Header.Title.Text
			if key ~= lastCard then
				lastCard = key
			elseif sim:shown(continue) and continue.Interactable then
				sim:click(continue)
			end
			return false
		end
		return reached()
	end, limit, 1 / 20)
end

local done
if scenario == "intro" then
	done = playUntil(function()
		local overlay = hud().Overlay
		return overlay.Visible and overlay.Card.Header.Title.Text == "Night 1"
	end, 120)
	sim:run(1.5)
elseif scenario == "queue" then
	done = playUntil(function()
		local root = hud()
		return not root.Overlay.Visible and root.Play.Desk.Idle.Visible
	end, 300)
	sim:run(2)
else
	done = playUntil(function()
		local root = hud()
		if root.Overlay.Visible then
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
	end, 1200)
	sim:run(6.5) -- let the puddle spread to full size
	-- Don't catch the booth lamp mid-flicker.
	sim:runUntil(function()
		local bulb = sim.workspace.World.Booth:FindFirstChild("LampBulb")
		return bulb ~= nil and bulb.Transparency == 0
	end, 3, 1 / 20)
end
assert(done, `never reached the "{scenario}" scenario`)
assert(#sim.errors == 0, table.concat(sim.errors, "\n"))

local scene = Scene.capture(sim, { root = ".", player = player, notes = { scenario = scenario } })
Scene.write(outPath, scene)
print(`wrote {outPath} ({scenario}, at {math.floor(sim.now)} s)`)
