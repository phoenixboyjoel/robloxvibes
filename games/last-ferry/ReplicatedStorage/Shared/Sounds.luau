--!strict
--[[
	Sounds: the game's audio, all of it from the built-in sounds Roblox's own
	characters make (rbxasset://sounds/..., used by RbxCharacterSounds, so every
	client on every device has them), so there's nothing to upload and every one of
	them sounds like Roblox:

		Footsteps  a passenger walking: the plastic footsteps every Roblox character makes
		Splash     one of the drowned sinking back into the harbor; the tide coming in
		Paddle     the water sloshing round the booth while it floods
		Thud       the rubber stamp hitting the ticket; the booth door shutting
		Click      pressing a button: a landing's tap, sped up to a short tock
		Gust       a lantern blowing out: the rush of wind Roblox plays when you fall

	Sound is only ever feedback. Every tell stays visual, and every passenger makes
	the same sounds whatever they are.
]]

export type Spec = {
	id: string,
	volume: number,
	speed: number,
	looped: boolean?,
	near: number?, -- RollOffMinDistance: full volume within this many studs
	far: number?, -- RollOffMaxDistance: silent beyond this
}

local Sounds = {
	Footsteps = {
		id = "rbxasset://sounds/action_footsteps_plastic.mp3",
		volume = 0.45,
		speed = 1.25, -- passengers stroll; Roblox plays it at 1.85 for a running character
		looped = true,
		near = 6,
		far = 70,
	} :: Spec,
	Splash = { id = "rbxasset://sounds/impact_water.mp3", volume = 0.8, speed = 1, near = 10, far = 160 } :: Spec,
	Paddle = { id = "rbxasset://sounds/action_swim.mp3", volume = 0.35, speed = 0.8, looped = true, near = 8 } :: Spec,
	Thud = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.7, speed = 0.75, near = 8, far = 80 } :: Spec,
	Click = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.3, speed = 2.4 } :: Spec,
	Gust = { id = "rbxasset://sounds/action_falling.ogg", volume = 0.6, speed = 1.4 } :: Spec,
}

-- A Sound for `spec`, parented to `parent`: in a part it's heard from there, anywhere
-- else it's heard everywhere at the same volume.
function Sounds.make(spec: Spec, parent: Instance, name: string?): Sound
	local sound = Instance.new("Sound")
	sound.Name = name or "Sound"
	sound.SoundId = spec.id
	sound.Volume = spec.volume
	sound.PlaybackSpeed = spec.speed
	sound.Looped = spec.looped == true
	sound.RollOffMinDistance = spec.near or 10
	sound.RollOffMaxDistance = spec.far or 120
	sound.Parent = parent
	return sound
end

return Sounds
