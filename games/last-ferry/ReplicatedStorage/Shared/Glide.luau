--!strict
--[[
	Glide: smooth movement on every screen.

	When the server moves a part with TweenService, players only see it move when a
	change replicates, unevenly, a few times a second, so it stutters, and the
	server sends every frame of it to every player. Roblox's docs say to tween
	on the client instead. With Glide the server says where something is going and
	when, as attributes on it, and each client moves it there itself every frame
	(GlideController). The server moves it too, at the start and at the end, so
	its own copy is right for its logic.

	The server (passengers walking, turning and sinking; the Petrel; the Marigold;
	the booth door; the flood):

		Glide.start(target, to, seconds, options?)  from where it is now to `to`
		Glide.frame(target)                         where it is now, mid-glide or not
		Glide.stop(target)                          stops it where it is now
		Glide.set(target, frame)                    puts it there at once

	`target` is a Model or a part, moved by its pivot. A part moves its whole
	assembly, so a passenger glides by their HumanoidRootPart.

	Once something has glided, move it only with Glide: clients place it by its
	latest glide, whatever its CFrame says.
]]

local TweenService = game:GetService("TweenService")

local Glide = {}

-- The tag clients find gliding things by.
Glide.Tag = "Glide"

local FROM = "GlideFrom"
local TO = "GlideTo"
local START = "GlideStart"
local TIME = "GlideTime"
local STYLE = "GlideStyle"
local DIRECTION = "GlideDirection"
local TURN = "GlideTurn"
-- Written last, so a client that sees a new id has the rest of that glide too
-- (attribute changes arrive in the order they were made).
local ID = "GlideId"
Glide.IdAttribute = ID

export type Spec = {
	id: number,
	from: CFrame,
	to: CFrame,
	start: number, -- server time, workspace:GetServerTimeNow()
	time: number,
	style: Enum.EasingStyle,
	direction: Enum.EasingDirection,
	-- Above 0: it turns to its new facing within this many seconds, as someone
	-- walking turns first and then goes. Otherwise it turns as it moves.
	turn: number,
}

export type Options = {
	style: Enum.EasingStyle?, -- Linear by default
	direction: Enum.EasingDirection?, -- Out by default, as with TweenInfo
	turn: number?,
}

local STYLES: { [string]: Enum.EasingStyle } = {}
for _, item in Enum.EasingStyle:GetEnumItems() do
	STYLES[item.Name] = item
end
local DIRECTIONS: { [string]: Enum.EasingDirection } = {}
for _, item in Enum.EasingDirection:GetEnumItems() do
	DIRECTIONS[item.Name] = item
end

-- Where a glide has got to, `elapsed` seconds after it started.
function Glide.sample(spec: Spec, elapsed: number): CFrame
	if elapsed >= spec.time then
		return spec.to
	end
	local eased = TweenService:GetValue(math.max(elapsed / spec.time, 0), spec.style, spec.direction)
	local spin = eased
	if spec.turn > 0 then
		local t = math.clamp(elapsed / spec.turn, 0, 1)
		spin = TweenService:GetValue(t, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
	return CFrame.new(spec.from.Position:Lerp(spec.to.Position, eased))
		* spec.from.Rotation:Lerp(spec.to.Rotation, spin)
end

-- A glide reaches each client a moment after it started: the network's delay. A client
-- plays it from when it arrives, that much behind the server, so it's seen whole and
-- never skipped into; the server's own moves reach the client just as late, so they
-- line up. One more than LATE seconds late (for a player who has just joined, say) is
-- joined where it has got to. Returns how far behind to play a glide that arrived `late`.
Glide.LATE = 0.5
function Glide.lag(late: number): number
	return if late > 0 and late < Glide.LATE then late else 0
end

-- The glide `target` is on, from its attributes, or nil if it has none (or a broken one).
function Glide.read(target: Instance): Spec?
	local id = target:GetAttribute(ID)
	local from = target:GetAttribute(FROM)
	local to = target:GetAttribute(TO)
	local start = target:GetAttribute(START)
	local time = target:GetAttribute(TIME)
	local style = target:GetAttribute(STYLE)
	local direction = target:GetAttribute(DIRECTION)
	local turn = target:GetAttribute(TURN)
	if
		typeof(id) ~= "number"
		or typeof(from) ~= "CFrame"
		or typeof(to) ~= "CFrame"
		or typeof(start) ~= "number"
		or typeof(time) ~= "number"
		or typeof(style) ~= "string"
		or typeof(direction) ~= "string"
		or typeof(turn) ~= "number"
	then
		return nil
	end
	local easingStyle = STYLES[style]
	local easingDirection = DIRECTIONS[direction]
	if easingStyle == nil or easingDirection == nil then
		return nil
	end
	return {
		id = id,
		from = from,
		to = to,
		start = start,
		time = time,
		style = easingStyle,
		direction = easingDirection,
		turn = turn,
	}
end

--------------------------------------------------------------------------------
-- Server

-- Glides still under way, by target.
local active: { [PVInstance]: Spec } = {}
local lastId = 0

local function write(target: PVInstance, spec: Spec)
	target:SetAttribute(FROM, spec.from)
	target:SetAttribute(TO, spec.to)
	target:SetAttribute(START, spec.start)
	target:SetAttribute(TIME, spec.time)
	target:SetAttribute(STYLE, spec.style.Name)
	target:SetAttribute(DIRECTION, spec.direction.Name)
	target:SetAttribute(TURN, spec.turn)
	target:SetAttribute(ID, spec.id)
end

-- Where `target` is now: part way along its glide, or where it stands.
function Glide.frame(target: PVInstance): CFrame
	local spec = active[target]
	if spec then
		return Glide.sample(spec, workspace:GetServerTimeNow() - spec.start)
	end
	return target:GetPivot()
end

-- Glides `target` from where it is now to `to` over `seconds`. A new glide takes over
-- from one under way, from wherever that had got to.
function Glide.start(target: PVInstance, to: CFrame, seconds: number, options: Options?)
	local from = Glide.frame(target)
	local time = math.max(seconds, 0)
	lastId += 1
	local spec: Spec = {
		id = lastId,
		from = from,
		to = to,
		start = workspace:GetServerTimeNow(),
		time = time,
		style = if options and options.style then options.style else Enum.EasingStyle.Linear,
		direction = if options and options.direction then options.direction else Enum.EasingDirection.Out,
		turn = math.clamp(if options and options.turn then options.turn else 0, 0, time),
	}
	target:AddTag(Glide.Tag)
	write(target, spec)
	if time <= 0 then
		active[target] = nil
		target:PivotTo(to)
		return
	end
	-- The server's copy stays put while clients move theirs, and catches up at the end.
	target:PivotTo(from)
	active[target] = spec
	task.delay(time, function()
		if active[target] == spec then
			active[target] = nil
			if target.Parent then
				target:PivotTo(spec.to)
			end
		end
	end)
end

-- Puts `target` at `frame` at once, ending any glide.
function Glide.set(target: PVInstance, frame: CFrame)
	Glide.start(target, frame, 0)
end

-- Stops `target` where it has got to, if it's gliding.
function Glide.stop(target: PVInstance)
	if active[target] then
		Glide.set(target, Glide.frame(target))
	end
end

return Glide
