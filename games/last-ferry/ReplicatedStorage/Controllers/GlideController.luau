--!strict
--[[
	GlideController: moves everything the server glides (Shared/Glide) on this
	client, every frame and before the camera, so passengers, the Petrel, the
	Marigold, the booth door and the flood move smoothly on every screen, whatever
	the connection. The server sends each glide once. Parts the server spreads (a
	wet passenger's puddle) grow here too.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Glide = require("../Shared/Glide")
local Net = require("../Shared/Net")

local GlideController = {}

-- For this long after a glide ends it's held at the end, so a move of the server's
-- that arrives late can't leave it somewhere else.
local HOLD = 1

type Track = {
	target: PVInstance,
	id: unknown,
	spec: Glide.Spec?,
	lag: number,
	holdUntil: number?, -- set once it's reached the end
}

type Spread = {
	part: BasePart,
	lag: number?, -- set once its attributes have all arrived
}

-- The same place and facing, near enough.
local function near(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 0.01
		and a.LookVector:Dot(b.LookVector) > 0.9999
		and a.UpVector:Dot(b.UpVector) > 0.9999
end

-- Watches the instances with `tag`, calling `add` for each and `remove` when it goes.
local function watchTag(tag: string, add: (Instance) -> (), remove: (Instance) -> ())
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
	for _, instance in CollectionService:GetTagged(tag) do
		add(instance)
	end
end

function GlideController.start()
	local tracks: { [Instance]: Track } = {}
	local spreads: { [Instance]: Spread } = {}

	watchTag(Glide.Tag, function(instance: Instance)
		if instance:IsA("PVInstance") and tracks[instance] == nil then
			tracks[instance] = { target = instance, id = nil, spec = nil, lag = 0, holdUntil = nil }
		end
	end, function(instance: Instance)
		tracks[instance] = nil
	end)
	watchTag(Glide.SpreadTag, function(instance: Instance)
		if instance:IsA("BasePart") and spreads[instance] == nil then
			spreads[instance] = { part = instance, lag = nil }
		end
	end, function(instance: Instance)
		spreads[instance] = nil
	end)

	local function glide(track: Track, now: number)
		local target = track.target
		local id = target:GetAttribute(Glide.IdAttribute)
		if id ~= track.id then
			local previous = track.spec
			local spec = Glide.read(target)
			track.id = id
			track.holdUntil = nil
			track.spec = spec
			if spec then
				track.lag = Glide.lagFor(previous, track.lag, spec, now - spec.start)
			end
		end
		local spec = track.spec
		if spec == nil then
			return
		end
		local elapsed = now - spec.start - track.lag
		if elapsed < spec.time then
			target:PivotTo(Glide.sample(spec, elapsed))
		elseif track.holdUntil == nil then
			target:PivotTo(spec.to)
			track.holdUntil = now + HOLD
		elseif now < (track.holdUntil :: number) and not near(target:GetPivot(), spec.to) then
			target:PivotTo(spec.to)
		end
	end

	local names = Glide.SpreadAttributes
	local function spread(entry: Spread, now: number)
		local part = entry.part
		local from, to = part:GetAttribute(names.from), part:GetAttribute(names.to)
		local start, time = part:GetAttribute(names.start), part:GetAttribute(names.time)
		if
			typeof(from) ~= "Vector3"
			or typeof(to) ~= "Vector3"
			or typeof(start) ~= "number"
			or typeof(time) ~= "number"
		then
			return -- not all here yet
		end
		local lag: number = entry.lag or Glide.lag(now - start)
		entry.lag = lag
		local elapsed = now - start - lag
		part.Size = Glide.spreadSize(from, to, time, elapsed)
		if elapsed >= time then
			spreads[part] = nil
		end
	end

	RunService:BindToRenderStep("LastFerryGlide", Enum.RenderPriority.First.Value, function()
		local now = Net.serverTime()
		if now == nil then
			return -- disconnected
		end
		for _, track in tracks do
			glide(track, now)
		end
		for _, entry in spreads do
			spread(entry, now)
		end
	end)
end

return GlideController
