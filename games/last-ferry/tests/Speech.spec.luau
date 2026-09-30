--!nonstrict
--[[
	Ui/Speech's placement of a passenger's speech bubble (Speech.place): over their
	head as Roblox places its own, then kept inside the room the HUD leaves, moving
	along or up as far as it takes but down only until the tail touches their head;
	and beside or over anything in the way lower down (Speech.placeInRoom).
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
	T.equal(at.Y, 215, "a HUD below: it moves up, clear of it, tail and all")

	at = place(sim, V2(400, 330), { 250, 0, 400, 600 })
	T.equal(at.X, 225, "wider than the room: centred on it")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

-- Places a bubble for a head whose top is at `head` (the tail's tip 30 px above it) in an
-- `area` with `obstacles` in it (each left, top, right, bottom). The bubble is 200 x 60,
-- or as narrow as the room it's given (never under 152, the narrowest a bubble gets) and
-- taller for it. Returns its box and where along it the tail is.
local function placeInRoom(sim, head, area, obstacles)
	local list = {}
	for _, o in obstacles do
		table.insert(list, string.format("{ left = %s, top = %s, right = %s, bottom = %s }", o[1], o[2], o[3], o[4]))
	end
	local size, at, along = sim:execute(string.format(
		[[
		local Speech = require("../ReplicatedStorage/Ui/Speech")
		local head = Vector2.new(%s, %s)
		local room = {
			area = { left = %s, top = %s, right = %s, bottom = %s },
			obstacles = { %s },
		}
		local function sizeFor(area)
			local width = math.max(math.min(200, area.right - area.left), 152)
			return Vector2.new(width, 60 * 200 / width)
		end
		return Speech.placeInRoom(head - Vector2.new(0, 30), head, 5, room, sizeFor)
	]],
		head.X,
		head.Y,
		area[1],
		area[2],
		area[3],
		area[4],
		table.concat(list, ", ")
	))
	-- The bubble with its tail.
	local box = { left = at.X, top = at.Y, right = at.X + size.X, bottom = at.Y + size.Y + 5 }
	return box, along
end

local function clear(box, o): boolean
	return box.right <= o[1] or box.left >= o[3] or box.bottom <= o[2] or box.top >= o[4]
end

T.test("a bubble goes beside anything in the way lower down, or over it", function()
	local sim = Sim.new({ root = "." })
	-- The page tab: out of the ticket's right edge, which is just left of the room.
	local tab = { 230, 280, 346, 400 }
	local area = { 274, 0, 800, 600 }

	local box, along = placeInRoom(sim, V2(500, 330), area, { tab })
	T.equal(box.left, 400, "not in the way: over the head as ever")
	T.equal(along, 100, "the tail in the middle")

	box = placeInRoom(sim, V2(320, 330), area, { tab })
	T.expect(clear(box, tab), "in the way, with the tip right of its middle: beside it")
	T.equal(box.left, 346, "on the right, where the tip is")

	box = placeInRoom(sim, V2(280, 330), area, { tab })
	T.expect(clear(box, tab), "with the tip left of its middle and no room on the left: still beside it")
	T.equal(box.left, 346, "on the right, where there's room")
	T.expect(box.left >= area[1], "and inside the room")

	local wide = { 0, 0, 800, 600 }
	local post = { 400, 280, 460, 400 }
	box, along = placeInRoom(sim, V2(380, 330), wide, { post })
	T.expect(clear(box, post), "with room on the tip's side: beside it")
	T.equal(box.right, 400, "on the left, where the tip is")
	T.equal(along, 180, "its tail still pointing at them")

	box = placeInRoom(sim, V2(280, 330), { 274, 0, 480, 600 }, { tab })
	T.expect(clear(box, tab), "no room on either side: over it")
	T.equal(box.bottom, 280, "just over it, tail and all")
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end)

return nil
