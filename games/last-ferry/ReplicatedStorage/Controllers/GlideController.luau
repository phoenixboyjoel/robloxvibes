--!strict
--[[
	GlideController: moves everything the server glides (Shared/Glide) on this
	client, every frame and before the camera, so passengers, the Petrel, the
	Marigold, the booth door and the flood move smoothly on every screen, whatever
	the connection. The server sends each glide once.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Glide = require("../Shared/Glide")

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

-- The same place and facing, near enough.
local function near(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 0.01
		and a.LookVector:Dot(b.LookVector) > 0.9999
		and a.UpVector:Dot(b.UpVector) > 0.9999
end

function GlideController.start()
	local tracks: { [Instance]: Track } = {}

	local function add(instance: Instance)
		if instance:IsA("PVInstance") and tracks[instance] == nil then
			tracks[instance] = { target = instance, id = nil, spec = nil, lag = 0, holdUntil = nil }
		end
	end
	CollectionService:GetInstanceAddedSignal(Glide.Tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(Glide.Tag):Connect(function(instance: Instance)
		tracks[instance] = nil
	end)
	for _, instance in CollectionService:GetTagged(Glide.Tag) do
		add(instance)
	end

	RunService:BindToRenderStep("LastFerryGlide", Enum.RenderPriority.First.Value, function()
		local now = workspace:GetServerTimeNow()
		for _, track in tracks do
			local target = track.target
			local id = target:GetAttribute(Glide.IdAttribute)
			if id ~= track.id then
				track.id = id
				track.holdUntil = nil
				local spec = Glide.read(target)
				track.spec = spec
				if spec then
					track.lag = Glide.lag(now - spec.start)
				end
			end
			local spec = track.spec
			if spec == nil then
				continue
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
	end)
end

return GlideController
