--!strict
--[[
	Sfx: sounds only this player hears (button clicks, the stamp, a lantern's gust),
	made on first use in SoundService on the client, where they don't replicate. A
	sound in SoundService has no position, so it plays at the same volume anywhere.
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sounds = require("../Shared/Sounds")

local Sfx = {}

local made: { [Sounds.Spec]: Sound } = {}

local function sound(spec: Sounds.Spec, name: string): Sound
	local existing = made[spec]
	if existing then
		return existing
	end
	local created = Sounds.make(spec, SoundService, `LastFerry{name}`)
	made[spec] = created
	return created
end

function Sfx.click()
	sound(Sounds.Click, "Click"):Play()
end

-- The rubber stamp hitting the ticket.
function Sfx.stamp()
	sound(Sounds.Thud, "Stamp"):Play()
end

-- A lantern blowing out: a short rush of wind that dies away.
function Sfx.gust()
	local gust = sound(Sounds.Gust, "Gust")
	gust.Volume = Sounds.Gust.volume
	gust.TimePosition = 0
	gust:Play()
	TweenService:Create(gust, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Volume = 0 }):Play()
	task.delay(1.2, function()
		gust:Stop()
	end)
end

return Sfx
