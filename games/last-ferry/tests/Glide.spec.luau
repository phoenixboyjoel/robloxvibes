--!nonstrict
--[[
	Glide (ReplicatedStorage/Shared/Glide.luau) and GlideController: the server
	sends each glide once, as attributes, and every client moves the thing itself,
	every frame.

	The simulator has one copy of the world, shared by the server and every client,
	so here a client's moves show up on the server's copy too. The tests below take
	that into account: they count who moved what with sim:countWrites.
]]

local roblox = require("@lune/roblox")

local Sim = require("./sim/Roblox")
local T = require("./TestLib")

T.suite("Glide")

local V = roblox.Vector3
local FRAME = 1 / 30

local function near(a, b, label: string, tolerance: number?)
	T.expect((a - b).Magnitude < (tolerance or 1e-3), `{label}: expected {b}, got {a}`)
end

-- Prefix for snippets run on the server.
local GLIDE = [[
	local Glide = require("../ReplicatedStorage/Shared/Glide")
	local crate = workspace.Crate
]]

-- A place with just a crate to glide. Players added to it run the real client script,
-- so GlideController moves the crate on their client.
local function crateSim()
	local sim = Sim.new({ root = "." })
	sim:execute([[
		local crate = Instance.new("Part")
		crate.Name = "Crate"
		crate.Size = Vector3.new(2, 2, 2)
		crate.Anchored = true
		crate.CFrame = CFrame.new(0, 1, 0)
		crate.Parent = workspace
	]])
	return sim, sim.workspace.Crate
end

local function clean(sim)
	T.equal(#sim.errors, 0, table.concat(sim.errors, "\n"))
end

T.test("a glide eases along, turns ahead of the move if asked, and ends exactly", function()
	local sim = Sim.new({ root = "." })
	local r = sim:execute([[
		local Glide = require("../ReplicatedStorage/Shared/Glide")
		local spec = {
			id = 1,
			from = CFrame.new(0, 0, 0),
			to = CFrame.new(10, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
			start = 0,
			time = 2,
			style = Enum.EasingStyle.Linear,
			direction = Enum.EasingDirection.Out,
			turn = 0,
		}
		local r = { to = spec.to }
		r.half = Glide.sample(spec, 1)
		r.before = Glide.sample(spec, -1)
		r.after = Glide.sample(spec, 5)
		spec.turn = 0.5
		r.turned = Glide.sample(spec, 0.5)
		spec.turn = 0
		spec.style = Enum.EasingStyle.Quad
		spec.direction = Enum.EasingDirection.In
		r.quad = Glide.sample(spec, 1)
		spec.style = Enum.EasingStyle.Back
		spec.direction = Enum.EasingDirection.Out
		r.peak = 0
		for t = 0, 2, 0.02 do
			r.peak = math.max(r.peak, Glide.sample(spec, t).X)
		end
		r.lags = { Glide.lag(0.2), Glide.lag(0.7), Glide.lag(-0.1) }
		return r
	]])
	near(r.half.Position, V.new(5, 0, 0), "Linear: halfway at half time")
	near(r.before.Position, V.zero, "held at the start until it begins")
	T.expect(r.after == r.to, "exactly at the end once it's over")
	near(r.turned.LookVector, r.to.LookVector, "with a turn time, it faces the new way within it")
	near(r.turned.Position, V.new(2.5, 0, 0), "while only a quarter of the way along")
	near(r.quad.Position, V.new(2.5, 0, 0), "Quad In: a quarter of the way at half time")
	T.expect(math.abs(r.peak - 11) < 0.05, `Back Out overshoots by a tenth and settles (peak {r.peak})`)
	T.equal(r.lags[1], 0.2, "a glide that arrives 0.2 s late plays whole, 0.2 s behind")
	T.equal(r.lags[2], 0, "one that arrives 0.7 s late is joined where it has got to")
	T.equal(r.lags[3], 0, "a clock a little behind the server's doesn't hold it back")
	clean(sim)
end)

T.test("a glide that carries straight on from the last keeps its lag, so a walk's corners join up", function()
	local sim = Sim.new({ root = "." })
	local r = sim:execute([[
		local Glide = require("../ReplicatedStorage/Shared/Glide")
		local function leg(from, to, start, time)
			return {
				id = 1,
				from = CFrame.new(from),
				to = CFrame.new(to),
				start = start,
				time = time,
				style = Enum.EasingStyle.Linear,
				direction = Enum.EasingDirection.Out,
				turn = 0,
			}
		end
		local first = leg(Vector3.zero, Vector3.new(10, 0, 0), 0, 2)
		local next = leg(Vector3.new(10, 0, 0), Vector3.new(10, 0, 10), 2, 2)
		local elsewhere = leg(Vector3.new(0, 0, 5), Vector3.new(10, 0, 10), 2, 2)
		local later = leg(Vector3.new(10, 0, 0), Vector3.new(10, 0, 10), 3, 2)
		return {
			Glide.lagFor(first, 0.2, next, 0.2),
			Glide.lagFor(first, 0.2, next, 0.05),
			Glide.lagFor(first, 0.2, next, 0.45),
			Glide.lagFor(first, 0.2, next, 1.5),
			Glide.lagFor(first, 0.2, elsewhere, 0.3),
			Glide.lagFor(first, 0.2, elsewhere, 0.7),
			Glide.lagFor(first, 0.2, later, 0.05),
			Glide.lagFor(nil, 0, next, 0.3),
		}
	]])
	T.equal(r[1], 0.2, "the next leg, arriving as late as the last, plays just as far behind")
	T.equal(r[2], 0.2, "arriving sooner, it still waits for the last to finish here: no skip at the corner")
	T.equal(r[3], 0.45, "arriving later, it plays from when it arrives: a pause at the corner, not a skip")
	T.equal(r[4], 0.7, "very late, it's joined no more than LATE behind the last")
	T.equal(r[5], 0.3, "a glide from somewhere else is timed on its own")
	T.equal(r[6], 0, "and joined where it has got to if it's very late")
	T.equal(r[7], 0.05, "as is one that starts a second after the last ended")
	T.equal(r[8], 0.3, "the first glide is timed on its own")
	clean(sim)
end)

T.test("the server sends a glide once; each client moves it every frame", function()
	local sim, crate = crateSim()
	sim:addPlayer("Alice", 101)
	sim:run(0.2)
	local writes = sim:countWrites(crate, "CFrame")
	sim:execute(GLIDE .. "Glide.start(crate, CFrame.new(10, 1, 0), 2)")
	T.equal(crate:GetAttribute("GlideTime"), 2, "the glide is written on the crate")
	T.expect(crate:HasTag("Glide"), "and tagged, for clients to find")

	local xs = {}
	sim:run(1, FRAME, function()
		table.insert(xs, crate.Position.X)
	end)
	for i = 2, #xs do
		local step = xs[i] - xs[i - 1]
		T.expect(step > 0.15 and step < 0.19, `frame {i}: moved {step} studs (5 studs a second is 0.167 a frame)`)
	end
	local serverFrame = sim:execute(GLIDE .. "return Glide.frame(crate)")
	T.expect(math.abs(serverFrame.X - 5) < 0.2, `the server knows where it has got to (x {serverFrame.X})`)

	sim:run(1.2)
	near(crate.Position, V.new(10, 1, 0), "at the end")
	T.expect((writes.server or 0) <= 1, `the server moved it no more than once, at the end ({writes.server})`)
	T.expect((writes["client:101"] or 0) >= 55, `Alice's client moved it every frame ({writes["client:101"]})`)
	clean(sim)
end)

T.test("the server's copy waits at the start, and a player who joins mid-glide sees it where it has got to", function()
	local sim, crate = crateSim()
	sim:execute(GLIDE .. "Glide.start(crate, CFrame.new(10, 1, 0), 4)")
	sim:run(2)
	near(crate.Position, V.new(0, 1, 0), "with no client to move it, the server's copy is still at the start")
	sim:addPlayer("Bob", 202)
	sim:run(FRAME)
	T.expect(
		math.abs(crate.Position.X - 5) < 0.2,
		`Bob joined 2 s in and sees it halfway, not at the start (x {crate.Position.X})`
	)
	sim:run(2.2)
	near(crate.Position, V.new(10, 1, 0), "and at the end with everyone else")
	clean(sim)
end)

T.test("with no players, the server's copy still ends up where the glide ends, moved just once", function()
	local sim, crate = crateSim()
	sim:execute(GLIDE .. "Glide.start(crate, CFrame.new(10, 1, 0), 2)")
	local writes = sim:countWrites(crate, "CFrame")
	sim:run(1)
	near(crate.Position, V.new(0, 1, 0), "at the start while it glides")
	sim:run(1.2)
	near(crate.Position, V.new(10, 1, 0), "at the end once it's over")
	T.equal(writes.server, 1, "the server moved it once, at the end")
	clean(sim)
end)

T.test("a spreading part is full size on the server and grows on each client", function()
	local sim = Sim.new({ root = "." })
	sim:addPlayer("Alice", 101)
	sim:run(0.2)
	local full = sim:execute([[
		local Glide = require("../ReplicatedStorage/Shared/Glide")
		local puddle = Instance.new("Part")
		puddle.Name = "Puddle"
		puddle.Anchored = true
		Glide.spread(puddle, Vector3.new(0.04, 0.6, 0.6), Vector3.new(0.04, 5.6, 5.6), 2)
		local size = puddle.Size
		puddle.Parent = workspace
		return size
	]])
	near(full, V.new(0.04, 5.6, 5.6), "the server's copy is its full size at once")
	local puddle = sim.workspace.Puddle
	local writes = sim:countWrites(puddle, "Size")
	local sizes = {}
	sim:run(2.2, FRAME, function()
		table.insert(sizes, puddle.Size.Y)
	end)
	T.expect(sizes[1] < 1, `on Alice's screen it starts small ({sizes[1]})`)
	for i = 2, #sizes do
		T.expect(sizes[i] >= sizes[i - 1], `frame {i}: it only grows ({sizes[i - 1]} to {sizes[i]})`)
	end
	T.expect(sizes[30] > 3 and sizes[30] < 5.6, `part way at 1 s ({sizes[30]})`)
	near(puddle.Size, V.new(0.04, 5.6, 5.6), "and full size at the end")
	local grown = writes["client:101"] or 0
	T.expect(grown >= 55, `Alice's client grew it every frame ({grown})`)
	sim:run(1)
	T.equal(writes["client:101"], grown, "and it stays that size")
	T.equal(writes.server or 0, 0, "the server never touched it again")
	clean(sim)
end)

T.test("a new glide takes over from wherever the last had got to", function()
	local sim, crate = crateSim()
	sim:addPlayer("Alice", 101)
	sim:run(0.2)
	sim:execute(GLIDE .. "Glide.start(crate, CFrame.new(10, 1, 0), 2)")
	sim:run(1)
	local before = crate.Position
	sim:execute(GLIDE .. "Glide.start(crate, CFrame.new(5, 1, 10), 2)")
	sim:run(FRAME)
	T.expect((crate.Position - before).Magnitude < 0.3, `no jump when it changes course ({before} to {crate.Position})`)
	sim:run(2.2)
	near(crate.Position, V.new(5, 1, 10), "at the new end")

	-- Stopped part way, it stays there; set, it's there at once.
	sim:execute(GLIDE .. "Glide.start(crate, CFrame.new(5, 1, -10), 2)")
	sim:run(1)
	sim:execute(GLIDE .. "Glide.stop(crate)")
	sim:run(FRAME)
	local stopped = crate.Position
	T.expect(math.abs(stopped.Z) < 0.4, `stopped halfway (z {stopped.Z})`)
	sim:run(2)
	near(crate.Position, stopped, "and stays stopped")
	sim:execute(GLIDE .. "Glide.set(crate, CFrame.new(0, 1, -3))")
	sim:run(FRAME)
	near(crate.Position, V.new(0, 1, -3), "set: there at once")
	clean(sim)
end)

T.test("once a glide ends, a late move from the server can't leave it somewhere else", function()
	local sim, crate = crateSim()
	sim:addPlayer("Alice", 101)
	sim:run(0.2)
	sim:execute(GLIDE .. "Glide.start(crate, CFrame.new(10, 1, 0), 1)")
	sim:run(1.3)
	near(crate.Position, V.new(10, 1, 0), "at the end")
	-- A stale position arriving from the server just after the end.
	crate.CFrame = roblox.CFrame.new(0, 1, 0)
	sim:run(FRAME)
	near(crate.Position, V.new(10, 1, 0), "put back at the end")
	clean(sim)
end)

T.test("a model glides whole, and a part turns about its pivot", function()
	local sim = Sim.new({ root = "." })
	local boat, door = sim:execute([[
		local boat = Instance.new("Model")
		boat.Name = "Boat"
		local hull = Instance.new("Part")
		hull.Name = "Hull"
		hull.Anchored = true
		hull.CFrame = CFrame.new(0, 0, 0)
		hull.Parent = boat
		local cabin = Instance.new("Part")
		cabin.Name = "Cabin"
		cabin.Anchored = true
		cabin.CFrame = CFrame.new(0, 3, 2)
		cabin.Parent = boat
		boat.PrimaryPart = hull
		boat.Parent = workspace
		-- A door hung on its left edge: its pivot is the hinge.
		local door = Instance.new("Part")
		door.Name = "Door"
		door.Size = Vector3.new(2.6, 6.9, 0.25)
		door.Anchored = true
		door.CFrame = CFrame.new(0, 3.45, 8)
		door.PivotOffset = CFrame.new(-1.3, 0, 0)
		door.Parent = workspace
		return boat, door
	]])
	sim:addPlayer("Alice", 101)
	sim:run(0.2)
	sim:execute([[
		local Glide = require("../ReplicatedStorage/Shared/Glide")
		Glide.start(workspace.Boat, CFrame.new(0, 0, -20), 2)
		local door = workspace.Door
		Glide.start(door, door:GetPivot() * CFrame.Angles(0, math.rad(-100), 0), 0.6, {
			style = Enum.EasingStyle.Back,
			direction = Enum.EasingDirection.Out,
		})
	]])
	local hinge = V.new(-1.3, 3.45, 8)
	local turned = false
	sim:run(0.7, FRAME, function()
		near(door:GetPivot().Position, hinge, "the door turns on its hinge")
		near((door.Position - hinge), (door.Position - hinge).Unit * 1.3, "its middle stays 1.3 from the hinge")
		turned = turned or door.CFrame.LookVector.Z > -0.99
	end)
	T.expect(turned, "the door swung")
	sim:run(1.4)
	near(boat.Hull.Position, V.new(0, 0, -20), "the hull sailed")
	near(boat.Cabin.Position, V.new(0, 3, -18), "and the cabin with it")
	clean(sim)
end)

return nil
