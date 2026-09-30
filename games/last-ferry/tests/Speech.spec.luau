--!nonstrict
--[[
	Ui/Speech's placement of a passenger's speech bubble (Speech.place): over their
	head as Roblox places its own, then kept inside the room the HUD leaves, moving
	along or up as far as it takes but down only until the tail touches their head.
]]

local roblox = require("@lune/roblox")

local Sim = require("./sim/Roblox")
local T = require("./TestLib")

T.suite("Speech")

local V2 = roblox.Vector2.new

-- Places a 200 x 60 bubble with a 5 px tail for a head whose top is at `head`, the tail's
-- tip 30 px above it, in `room` (left, top, right, bottom). Returns its top-left corner and
-- where along it the tail is.
local function place(sim, head, room)
	return sim:execute(string.format(
		[[
		local Speech = require("../ReplicatedStorage/Ui/Speech")
		local head = Vector2.new(%s, %s)
		local room = { left = %s, top = %s, right = %s, bottom = %s }
		return Speech.place(head - Vector2.new(0, 30), head, Vector2.new(200, 60), 5, room)
	]],
		head.X,
		head.Y,
		room[1],
		room[2],
		room[3],
		room[4]
	))
end

T.test("a bubble sits over the head, and moves to stay in the room the HUD leaves", function()
	local sim = Sim.new({ root = "." })
	local wide = { 0, 0, 800, 600 }
	local at, along = place(sim, V2(400, 330), wide)
	T.equal(at, V2(300, 235), "with room to spare: centred over the head, the tail's tip 30 px up")
	T.equal(along, 100, "the tail in the middle")

	at, along = place(sim, V2(50, 330), wide)
	T.equal(at.X, 0, "near the room's left edge, it stops at the edge")
	T.equal(along, 50, "and its tail still points at them")
	at, along = place(sim, V2(3, 330), wide)
	T.equal(along, 17, "though never into a rounded corner")
	at, along = place(sim, V2(-100, 330), wide)
	T.equal(at.X, 0, "with them off to one side, it waits at the edge")
	T.equal(along, nil, "with no tail")

	at = place(sim, V2(400, 330), { 0, 250, 800, 600 })
	T.equal(at.Y, 250, "a HUD above: it moves down, clear of it")
	at = place(sim, V2(400, 330), { 0, 280, 800, 600 })
	T.equal(at.Y, 265, "but no further than the top of their head: it never covers their face")
	at = place(sim, V2(400, 330), { 0, 0, 800, 280 })
	T.equal(at.Y, 220, "a HUD below: it moves up, clear of it")

	at = place(sim, V2(400, 330), { 250, 0, 400, 600 })
	T.equal(at.X, 225, "wider than the room: centred on it")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

return nil
