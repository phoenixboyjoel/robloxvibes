# Roblox look and feel: engine facts for Last Ferry (tech brief)

> **Written before the "look and feel like Roblox" overhaul (2026-09-30).**
> Where it describes Last Ferry, it describes the game as it was then:
> faceless passengers, no player avatars, a premium-dark HUD and no audio.
> What was built from it is in `games/last-ferry` (see its README and
> ARCHITECTURE.md); the ranked recommendations were followed in that order.
> One thing was built differently after an independent review: passengers'
> lines use a bubble of the game's own drawn like Roblox's (`Ui/Speech`), not
> `TextChatService:DisplayBubble` (section 3), because Roblox's chat never shows
> on consoles, its bubbles fade before the 45 s window ends, and what they say
> is a rule. Moving NPCs on the client (2.7) was built as `Shared/Glide`, and
> used for everything that moves. A second review found the HUD covered that
> bubble on phones (every ScreenGui draws over BillboardGuis), so the bubble
> became a full-screen layer over the HUD, and the HUD's status moved up into
> Roblox's own top bar row; section 5.5 has the top bar facts behind that.

Compiled 2026-09-30 for Phoenix Feather Studios. Scope: making Last Ferry (fixed-camera booth horror, Rojo, strict Luau, headless Lune simulator) look and feel like Roblox: passengers as Roblox-avatar NPCs, optional visible player avatars, NPC speech through bubble chat, and a HUD that follows Roblox UI conventions.

## How to read this brief

create.roblox.com and devforum.roblox.com are blocked from the research sandbox, so every documentation fact below was read from the docs' source repository (identical content, rendered at create.roblox.com/docs). Engine defaults come from the machine-readable API dump, and behaviour that the docs don't cover comes from the client's own Lua source and content files.

| Tag | Source | Version / location |
|---|---|---|
| **API** | Full API dump (defaults, tags, security, serialization) | client `0.741.19.7411056`, https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Full-API-Dump.json |
| **CD** `path` | Roblox/creator-docs, `content/en-us/<path>` | commit `1466521` (2026-09-29). Page URL = `https://create.roblox.com/docs/<path without .md/.yaml>` (for example `CD reference/engine/classes/Humanoid.yaml` = https://create.roblox.com/docs/reference/engine/classes/Humanoid) |
| **RCT** `path` | MaximumADHD/Roblox-Client-Tracker, branch `roblox` | commit `fcd6994` = client 0.741.19.7411056, `https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/<path>` |
| **RSW** `path` | suscersal/roblox-studio-web: a mirror of the Studio install's `content/` folder, files MD5-checked against RCT `rbxManifest.txt` | commit `04762bb` (2026-09-29), `https://github.com/suscersal/roblox-studio-web/blob/main/<path>` |
| **EC** `path` | diamond3500/ExtraContent: mirror of the client's ExtraContent (CoreScript packages, UI textures) | commit `c63ce13` (2026-09-23), `https://github.com/diamond3500/ExtraContent/blob/main/<path>` |
| **ExpChat** `file` | The in-experience chat package, `EC LuaPackages/Packages/_Index/ExperienceChat-567b090e-58d00f83/ExperienceChat/<file>` | as EC |
| **REPO** `path` | This repository (read, not modified) | paths from the repository root |

The rigs were decoded with Lune (`roblox.deserializeModel`), using small Lune helper scripts (not kept). Anything marked **[unverified]** comes from inference or community knowledge and should be checked in Studio before we rely on it.

---

## 0. Decisions at a glance

1. **We can have authentic Roblox-avatar NPCs with zero asset IDs.** Build the classic R6 "Robloxian" from `Part`s. Use the built-in `SpecialMesh` head (`MeshType.Head`, scale 1.25) and the classic smile decal `rbxasset://textures/face.png`, which ships with every client. Join the parts with Roblox's exact Motor6D frames and attachment names, taken from the stock rig in Studio's own content folder (see 1.2 and 1.3). A blocky R15 built from 15 Parts plus the root is also possible, and it adds short sleeves and shoes through per-limb colours (1.4). Clothing, faces other than the smile, Dynamic Heads and the R15 body meshes all need network assets.
2. **Animate on the client by writing `Motor6D.Transform` in `RunService.PreSimulation`.** The docs recommend this for custom animation, it needs no assets, it costs the server nothing, and it doesn't replicate. The official R6 Animate script's own numbers give an authentic classic walk and sit (2.4). Roblox's default animation IDs also work in any experience through an `Animator`, but they are network assets and they don't run in Lune. Move NPCs on the client too, because the docs call server-side `TweenService` on moving parts jittery and bandwidth-heavy (2.7).
3. **Bubble chat works for NPC lines, from the client only.** Call `TextChatService:DisplayBubble(npcModel, text)` from a LocalScript or a client-context Script, and style it with `BubbleChatConfiguration` or `TextChatService.OnBubbleAdded`. The bubbles are Roblox's own UI, so they look authentic. According to the ExpChat source they show even when the viewer's chat is restricted and even when `BubbleChatConfiguration.Enabled` is false. There are four caveats. ExpChat does not mount on 10-foot (console) interfaces. Bubbles are occluded by geometry, are hidden beyond `MaxDistance` (default 100) from the camera and collapse to "…" beyond `MinimizeDistance` (default 40). At most 3 bubbles stack per speaker. The default `BubbleDuration` is 15 s in the engine (the docs say 30). `ChatVersion` must be `TextChatService`. Lines we write ourselves need no text filtering (section 3).
4. **Fonts and UI:** 43 built-in font families, including Creepster, Special Elite, Grenze Gotisch, Fredoka One, Luckiest Guy, Bangers, Permanent Marker, Press Start 2P, Builder Sans (Roblox's own UI font) and Montserrat (which now stands in for Gotham). Each family has some faces shipped locally and others downloaded from the cloud (5.1). The modern UI toolkit is all available: `UIStroke` (Contextual/Border modes, Inner/Center/Outer position, ScaledSize), `UICorner` with per-corner radii, `UIGradient` (Linear/Radial/Conical/Elliptical), the new `UIShadow`, `CanvasGroup`, flex layouts (`UIFlexItem`), `UIDragDetector`, 9-slice, and runtime **StyleSheets** (`StyleSheet`/`StyleRule`/`StyleLink`/`StyleDerive`/`StyleQuery`). Screen-safe areas come from `ScreenGui.ScreenInsets` (5.2 to 5.7).
5. **Lighting for "Roblox look":** `Lighting.LightingStyle = Soft` gives the "flat, retro-Roblox look". `ColorGradingEffect.TonemapperPreset = Retro` imitates pre-2019 Roblox; pair it with light brightness at most 1. `Lighting.Technology` is deprecated and can't be scripted (section 7).

---

## 1. Avatar NPCs without network assets

### 1.1 Options compared

| Option | Assets needed | Look | Runs in Lune sim | Notes |
|---|---|---|---|---|
| **A. R6 from Parts** (recommended) | none | Classic 2006–2016 Robloxian: blocky, SpecialMesh head, smile | yes: only `Instance.new` + properties | 7 parts + Humanoid. Exact values in 1.2. Already the approach in `REPO games/last-ferry/ServerScriptService/Services/Robloxian.luau` |
| **B. Blocky R15 from Parts** | none | Modern "Blocky" R15 silhouette (15 parts): short sleeves, gloves, shoes, knees and elbows | yes | 16 parts + 15 Motor6Ds. Stock R15 limbs are MeshParts with **network** mesh IDs, so use Block parts at the same sizes (1.4) |
| **C. `Players:CreateHumanoidModelFromDescriptionAsync`** | none for an all-default description with R6. R15 default body meshes are network assets. Clothing/accessories by ID are network assets, though `AccessoryDescription.Instance` can carry local accessories | Engine-built rig, automatically correct | no | Yields and can fail (wrap in `pcall`). Default description colours are **black** (1.9). Which head R15 gets is **[unverified]** |
| **D. Pre-built model saved in the place / Rojo `.rbxm`** | none if built from A or B | same as A/B | depends on sim loading `.rbxm` | Rojo can sync `.rbxm`/`.rbxmx` model files. Cloning a template is cheaper than rebuilding |

### 1.2 The stock R6 rig, exact values

Studio ships the default R6 character as `content/avatar/character.rbxm` (Model `erik.cassel`, `PrimaryPart = Head`) [RSW content/avatar/character.rbxm, decoded with Lune]. It contains **no Motor6Ds**; the engine creates them when it builds a player character **[inference]**. The joint values below come from the stock morph rig `content/avatar/morpherEditorR6.rbxmx` [RSW content/avatar/morpherEditorR6.rbxmx]. Its Right Shoulder value also matches 308 independent GitHub code hits.

**Parts** (all `Part`, `Material = Plastic`, `Color = 163,162,165` "Medium stone grey", Shape Block):

| Part | Size | Offset from HumanoidRootPart (character space) | CanCollide | Notes |
|---|---|---|---|---|
| HumanoidRootPart | 2, 2, 1 | 0, 0, 0 | false | Transparency 1. Child `RootAttachment` at 0,0,0 |
| Torso | 2, 2, 1 | 0, 0, 0 | true | Child `Decal 'roblox'` (empty Texture, Face Front). TopSurface Studs, BottomSurface Inlet, Left/RightSurface Weld |
| Head | 2, 1, 1 | 0, 1.5, 0 | true | `SpecialMesh 'Mesh'` (MeshType Head, Scale 1.25,1.25,1.25, Offset 0), `Decal 'face'` (Face Front, Texture `rbxasset://textures/face.png`) |
| Left Arm | 1, 2, 1 | -1.5, 0, 0 | false | TopSurface Studs, BottomSurface Inlet |
| Right Arm | 1, 2, 1 | 1.5, 0, 0 | false | same |
| Left Leg | 1, 2, 1 | -0.5, -2, 0 | false | TopSurface Studs |
| Right Leg | 1, 2, 1 | 0.5, -2, 0 | false | TopSurface Studs |

The Humanoid has `RigType = R6` and `HipHeight = 0`. Ground to HumanoidRootPart centre is 3 studs: leg length 2 + half root 1 + HipHeight 0. That matches the R6 formula "LeftLeg.Size.Y + 0.5·RootPart.Size.Y + HipHeight" [CD reference/engine/classes/Humanoid.yaml, HipHeight].

**Attachments** (part-local position, all identity rotation) [RSW content/avatar/character.rbxm]:

| Part | Attachments |
|---|---|
| Head | `HairAttachment` (0, 0.6, 0), `HatAttachment` (0, 0.6, 0), `FaceFrontAttachment` (0, 0, -0.6), `FaceCenterAttachment` (0, 0, 0) |
| Torso | `NeckAttachment` (0, 1, 0), `BodyFrontAttachment` (0, 0, -0.5), `BodyBackAttachment` (0, 0, 0.5), `LeftCollarAttachment` (-1, 1, 0), `RightCollarAttachment` (1, 1, 0), `WaistFrontAttachment` (0, -1, -0.5), `WaistCenterAttachment` (0, -1, 0), `WaistBackAttachment` (0, -1, 0.5) |
| Left Arm / Right Arm | `LeftShoulderAttachment` / `RightShoulderAttachment` (0, 1, 0); `LeftGripAttachment` / `RightGripAttachment` (0, -1, 0) |
| Left Leg / Right Leg | `LeftFootAttachment` / `RightFootAttachment` (0, -1, 0) |
| HumanoidRootPart | `RootAttachment` (0, 0, 0) |

**Motor6Ds** (all `MaxVelocity = 0.1`) [RSW content/avatar/morpherEditorR6.rbxmx]:

| Motor6D (parent) | Part0 → Part1 | C0 | C1 |
|---|---|---|---|
| `RootJoint` (HumanoidRootPart) | HumanoidRootPart → Torso | `CFrame.new(0,0,0, -1,0,0, 0,0,1, 0,1,0)` | same as C0 |
| `Neck` (Torso) | Torso → Head | `CFrame.new(0,1,0, -1,0,0, 0,0,1, 0,1,0)` | `CFrame.new(0,-0.5,0, -1,0,0, 0,0,1, 0,1,0)` |
| `Right Shoulder` (Torso) | Torso → Right Arm | `CFrame.new(1,0.5,0, 0,0,1, 0,1,0, -1,0,0)` | `CFrame.new(-0.5,0.5,0, 0,0,1, 0,1,0, -1,0,0)` |
| `Left Shoulder` (Torso) | Torso → Left Arm | `CFrame.new(-1,0.5,0, 0,0,-1, 0,1,0, 1,0,0)` | `CFrame.new(0.5,0.5,0, 0,0,-1, 0,1,0, 1,0,0)` |
| `Right Hip` (Torso) | Torso → Right Leg | `CFrame.new(1,-1,0, 0,0,1, 0,1,0, -1,0,0)` | `CFrame.new(0.5,1,0, 0,0,1, 0,1,0, -1,0,0)` |
| `Left Hip` (Torso) | Torso → Left Leg | `CFrame.new(-1,-1,0, 0,0,-1, 0,1,0, 1,0,0)` | `CFrame.new(-0.5,1,0, 0,0,-1, 0,1,0, 1,0,0)` |

Joint solve: `Part1.CFrame * C1 == Part0.CFrame * C0` for welds [CD reference/engine/classes/Weld.yaml]. A Motor6D inserts its `Transform` as `Part0.CFrame * C0 * Transform == Part1.CFrame * C1`. That form is the standard one and is also what the repo simulator implements [REPO games/last-ferry/tests/sim/Roblox.luau ~l.591]. The joint names above are the ones Roblox's own R6 Animate script looks up: `Torso:WaitForChild("Right Shoulder")` etc. [RCT avatar/unification/humanoidAnimateR6WithFace/init.client.lua l.3–9].

Humanoid rules that matter for Part-built rigs:
- R6: "The Head part must be attached to a part named Torso, or the Humanoid will die immediately". For R15 the part must be `UpperTorso`. R15 rigs can be rescaled with NumberValues (`BodyDepthScale`, `BodyHeightScale`, `BodyWidthScale`, `HeadScale`) under the Humanoid, which "will automatically create Vector3Value objects named OriginalSize inside of each limb" [CD reference/engine/classes/Humanoid.yaml; API `Humanoid.RequiresNeck` default true].
- Name and health display needs the Humanoid inside a Model that has a BasePart named `Head` at the same level [CD characters/name-health-display.md].
- `Humanoid:BuildRigFromAttachments()` builds Motor6Ds only from attachments whose names end in `RigAttachment` (R15 convention). R6 has none, so create the six Motor6Ds yourself [CD reference/engine/classes/Humanoid.yaml, BuildRigFromAttachments].

### 1.3 R6 builder (strict Luau, zero assets)

```lua
--!strict
-- Classic R6 Robloxian built from Parts: no asset IDs. Numbers are Roblox's own
-- (content/avatar/character.rbxm + morpherEditorR6.rbxmx). `s` scales the whole rig.
local R6 = {}

local FACE = "rbxasset://textures/face.png" -- built-in classic smile, 128x128, tintable via Decal.Color3

local function newPart(name: string, size: Vector3, cf: CFrame, color: Color3, collide: boolean): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic -- stock rigs are Plastic (SmoothPlastic loses the subtle 2022 plastic grain)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = collide
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true -- the root is anchored; nothing here needs mass
	return p
end

local function attachment(parent: BasePart, name: string, x: number, y: number, z: number, s: number)
	local a = Instance.new("Attachment")
	a.Name = name
	a.Position = Vector3.new(x, y, z) * s
	a.Parent = parent
end

-- Rotation parts of Roblox's R6 joint frames.
local CENTRE = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
local RIGHT = CFrame.new(0, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local LEFT = CFrame.new(0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)

local function motor(name: string, parent: Instance, p0: BasePart, p1: BasePart, c0: CFrame, c1: CFrame)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1
	m.MaxVelocity = 0.1 -- stock value
	m.Parent = parent
end

export type Colors = { head: Color3, torso: Color3, arms: Color3, legs: Color3 }

function R6.build(rootCFrame: CFrame, colors: Colors, s: number): Model
	local model = Instance.new("Model")
	local root = newPart("HumanoidRootPart", Vector3.new(2, 2, 1) * s, rootCFrame, colors.torso, false)
	root.Transparency = 1
	root.Anchored = true -- static/scripted NPC: CD performance-optimization/improve.md
	root.CastShadow = false
	local torso = newPart("Torso", Vector3.new(2, 2, 1) * s, rootCFrame, colors.torso, false)
	local head = newPart("Head", Vector3.new(2, 1, 1) * s, rootCFrame * CFrame.new(0, 1.5 * s, 0), colors.head, false)
	local la = newPart("Left Arm", Vector3.new(1, 2, 1) * s, rootCFrame * CFrame.new(-1.5 * s, 0, 0), colors.arms, false)
	local ra = newPart("Right Arm", Vector3.new(1, 2, 1) * s, rootCFrame * CFrame.new(1.5 * s, 0, 0), colors.arms, false)
	local ll = newPart("Left Leg", Vector3.new(1, 2, 1) * s, rootCFrame * CFrame.new(-0.5 * s, -2 * s, 0), colors.legs, false)
	local rl = newPart("Right Leg", Vector3.new(1, 2, 1) * s, rootCFrame * CFrame.new(0.5 * s, -2 * s, 0), colors.legs, false)

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "Mesh"
	mesh.MeshType = Enum.MeshType.Head -- built-in engine mesh, no asset
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25) -- stock value; see the scaling caveat below the code
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = FACE
	face.Parent = head

	attachment(head, "HairAttachment", 0, 0.6, 0, s)
	attachment(head, "HatAttachment", 0, 0.6, 0, s)
	attachment(head, "FaceFrontAttachment", 0, 0, -0.6, s)
	attachment(head, "FaceCenterAttachment", 0, 0, 0, s)
	attachment(torso, "NeckAttachment", 0, 1, 0, s)
	attachment(torso, "BodyFrontAttachment", 0, 0, -0.5, s)
	attachment(torso, "BodyBackAttachment", 0, 0, 0.5, s)
	attachment(torso, "LeftCollarAttachment", -1, 1, 0, s)
	attachment(torso, "RightCollarAttachment", 1, 1, 0, s)
	attachment(torso, "WaistFrontAttachment", 0, -1, -0.5, s)
	attachment(torso, "WaistCenterAttachment", 0, -1, 0, s)
	attachment(torso, "WaistBackAttachment", 0, -1, 0.5, s)
	attachment(la, "LeftShoulderAttachment", 0, 1, 0, s)
	attachment(la, "LeftGripAttachment", 0, -1, 0, s)
	attachment(ra, "RightShoulderAttachment", 0, 1, 0, s)
	attachment(ra, "RightGripAttachment", 0, -1, 0, s)
	attachment(ll, "LeftFootAttachment", 0, -1, 0, s)
	attachment(rl, "RightFootAttachment", 0, -1, 0, s)
	attachment(root, "RootAttachment", 0, 0, 0, s)

	local function at(x: number, y: number, rot: CFrame): CFrame
		return CFrame.new(x * s, y * s, 0) * rot
	end
	motor("RootJoint", root, root, torso, at(0, 0, CENTRE), at(0, 0, CENTRE))
	motor("Neck", torso, torso, head, at(0, 1, CENTRE), at(0, -0.5, CENTRE))
	motor("Right Shoulder", torso, torso, ra, at(1, 0.5, RIGHT), at(-0.5, 0.5, RIGHT))
	motor("Left Shoulder", torso, torso, la, at(-1, 0.5, LEFT), at(0.5, 0.5, LEFT))
	motor("Right Hip", torso, torso, rl, at(1, -1, RIGHT), at(0.5, 1, RIGHT))
	motor("Left Hip", torso, torso, ll, at(-1, -1, LEFT), at(-0.5, 1, LEFT))

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- no name tag
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.EvaluateStateMachine = false -- no physics/sensors; we move it ourselves
	humanoid.Parent = model

	for _, p in { root, torso, head, la, ra, ll, rl } do
		p.Parent = model
	end
	model.PrimaryPart = root -- stock file uses Head; the root is the practical pivot
	return model
end

return R6
```

The code sets `Decal.Texture`. `Decal.TextureContent` is the newer `Content`-typed twin [API `Decal`]. Leave `Humanoid.RigType = R6` set so that tools and CoreScripts treat the model as R6.

**Scaling caveat.** Brick, Wedge and Sphere SpecialMeshes scale linearly with the part's Size. `SpecialMesh` type **Head** "currently scale[s] in a non standard manner. Developers should not rely on this as there are plans to change this behavior" [CD reference/engine/classes/DataModelMesh.yaml, Scale]. When a rig is scaled by `s` (the repo scales the Head part by `s` and keeps `Scale = 1.25`), check the head in Studio at the smallest and largest `s`. If it looks off, multiply `mesh.Scale` by `s` as well.

### 1.4 The stock R15 rig, and a blocky R15 from Parts

`content/avatar/characterR15.rbxm` (Model `Player`, `PrimaryPart = HumanoidRootPart`, `Humanoid.RigType = R15`, `HipHeight = 1.35`) [RSW content/avatar/characterR15.rbxm]. The limbs are `MeshPart`s whose `MeshId`s are `http://www.roblox.com/asset/?id=1699715537…1699715652` (network assets). The Head is a plain `Part` 2×1×1 with the same `SpecialMesh` Head 1.25 and `face.png` decal as R6. Every joint has identity rotation, and every Motor6D is parented to its Part1 with `MaxVelocity = 0`. Each part also carries `OriginalSize`/`OriginalPosition` Vector3Values, which are used by scaling.

**Parts** (Plastic, grey 163,162,165. Offsets are relative to the HumanoidRootPart centre; ground is at y = -2.35 = -(1.35 + 1)):

| Part | Size | Offset | CanCollide |
|---|---|---|---|
| HumanoidRootPart | 2, 2, 1 | 0, 0, 0 | true (Transparency 1) |
| LowerTorso | 2, 0.4, 1 | 0, -0.15, 0 | true |
| UpperTorso | 2, 1.6, 1 | 0, 0.85, 0 | true |
| Head (Part + SpecialMesh Head 1.25 + `face` decal) | 2, 1, 1 | 0, 2.15, 0 | true |
| LeftUpperArm / RightUpperArm | 1, 1.1687, 1 | ∓1.5, 1.0187, 0 | false |
| LeftLowerArm / RightLowerArm | 1, 1.0519, 1 | ∓1.5, 0.4259, 0 | false |
| LeftHand / RightHand | 1, 0.3, 1 | ∓1.5, -0.2, 0 | false |
| LeftUpperLeg / RightUpperLeg | 1, 1.2166, 1 | ∓0.5, -0.7708, 0 | false |
| LeftLowerLeg / RightLowerLeg | 1, 1.1931, 1 | ∓0.5, -1.5509, 0 | false |
| LeftFoot / RightFoot | 1, 0.3, 1 | ∓0.5, -2.2, 0 | false |

**Motor6Ds** (name, parent = Part1, Part0, C0 position, C1 position; all rotations identity):

| Joint | Part0 → Part1 | C0 | C1 |
|---|---|---|---|
| `Root` | HumanoidRootPart → LowerTorso | 0, -0.35, 0 | 0, -0.2, 0 |
| `Waist` | LowerTorso → UpperTorso | 0, 0.2, 0 | 0, -0.8, 0 |
| `Neck` | UpperTorso → Head | 0, 0.8, 0 | 0, -0.5, 0 |
| `LeftShoulder` / `RightShoulder` | UpperTorso → L/R UpperArm | ∓1, 0.563, 0 | ±0.5, 0.3943, 0 |
| `LeftElbow` / `RightElbow` | UpperArm → LowerArm | 0, -0.3341, 0 | 0, 0.2587, 0 |
| `LeftWrist` / `RightWrist` | LowerArm → Hand | 0, -0.5009, 0 | 0, 0.125, 0 |
| `LeftHip` / `RightHip` | LowerTorso → L/R UpperLeg | ∓0.5, -0.2, 0 | 0, 0.4208, 0 |
| `LeftKnee` / `RightKnee` | UpperLeg → LowerLeg | 0, -0.4011, 0 | 0, 0.379, 0 |
| `LeftAnkle` / `RightAnkle` | LowerLeg → Foot | 0, -0.5472, 0 | 0, 0.1019, 0 |

**Attachments.** Rig attachments, named `<Joint>RigAttachment`, sit at the C0 position on Part0 and the C1 position on Part1; for example `RootRigAttachment` is at (0,-0.35,0) on the root and (0,-0.2,0) on LowerTorso. The accessory attachments are:
- Head: `HairAttachment` and `HatAttachment` (0, 0.6, 0), `FaceFrontAttachment` (0, 0, -0.6), `FaceCenterAttachment` (0, 0, 0).
- UpperTorso: `NeckAttachment` (0, 0.8, 0), `BodyFrontAttachment` (0, -0.2, -0.5), `BodyBackAttachment` (0, -0.2, 0.5), `LeftCollarAttachment` (-1, 0.8, 0), `RightCollarAttachment` (1, 0.8, 0).
- LowerTorso: `WaistCenterAttachment` (0, -0.2, 0), `WaistFrontAttachment` (0, -0.2, -0.5), `WaistBackAttachment` (0, -0.2, 0.5).
- Upper arms: `LeftShoulderAttachment` / `RightShoulderAttachment` (0, 0.5843, 0).
- Hands: `LeftGripAttachment` / `RightGripAttachment` (0, -0.15, 0), rotated `CFrame.Angles(math.rad(-90), 0, 0)`.
- Feet: `LeftFootAttachment` / `RightFootAttachment` (0, -0.15, 0).
- Root: `RootAttachment` (0, 0, 0).

[all from RSW content/avatar/characterR15.rbxm]

A blocky R15 built from Parts uses the table above with `Part` (Block) instead of the MeshParts. Because the stock body meshes are near-cuboids with those exact bounding sizes, the silhouette matches Roblox's default R15 closely. Only the slight bevel differs **[visual check in Studio]**. Per-limb colour gives short sleeves (UpperArm = shirt colour, LowerArm and Hand = skin), trousers (Upper and Lower Leg) and shoes (Foot), which R6 can't show without clothing textures.

Other stock heads, for reference only (all network assets):
- `characterR15DynamicHeadV2.rbxm`: MeshPart Head with mesh 123480233606534, texture 111092388570647 and `FaceControls`; body meshes 7430070991…; `HipHeight` 2.
- `defaultDynamicHead.rbxm` uses rbxassetid 11445807850.

[RSW content/avatar/]

### 1.5 Accessories (hats, hair, bags) without assets

- An `Accessory` must contain a part named **`Handle`**; a plain `Part` or MeshPart is fine. The Handle holds an `Attachment` named exactly like one on the character. `Humanoid:AddAccessory(accessory)` then welds the Handle to that body part (a `Weld` under the Handle) so the two attachments coincide. If no match is found, the accessory stays parented but unattached [CD reference/engine/classes/Humanoid.yaml, AddAccessory].
- Accessory welds are normally made on the server. Client-side `AddAccessory` "may not always produce the desired behavior"; call `Humanoid:BuildRigFromAttachments()` to force the welds [same].
- Attachment names by accessory type: Hat → `HatAttachment`. Hair → `HairAttachment`. Face → `FaceFrontAttachment` or `FaceCenterAttachment`. Neck → `NeckAttachment`. Front → `BodyFrontAttachment`. Back → `BodyBackAttachment`. Waist → `WaistFrontAttachment`, `WaistCenterAttachment` or `WaistBackAttachment`. Shoulder → `LeftShoulderAttachment`/`RightShoulderAttachment`, which move with the arm, or `LeftCollarAttachment`/`RightCollarAttachment`, which do not [CD avatar/rigid-accessories/specifications.md].
- Zero-asset shapes:
  - `Part.Shape` offers Ball, Block, Cylinder, Wedge and CornerWedge [API `Enum.PartType`].
  - `SpecialMesh.MeshType` offers built-in `Head`, `Torso` ("the default Humanoid torso mesh"), `Wedge`, `Sphere`, `Cylinder` and `Brick`. `Prism`, `Pyramid`, `ParallelRamp`, `RightAngleRamp` and `CornerWedge` are deprecated. `FileMesh` needs an asset [API `Enum.MeshType`; CD reference/engine/enums/MeshType.yaml].
  - A `SpecialMesh` of type Head scaled larger reads as hair or a hood. The repo already does this [REPO Robloxian.luau `shell`].
- Simplest pattern for scripted NPCs: weld decorative parts directly to the limb with `WeldConstraint`, as the repo does. They follow the limb when a client animates the joint.
- The Accessory route is only needed for `ApplyDescriptionAsync`: `AccessoryDescription.Instance` "can be used instead of AssetId to apply accessories without uploading them to the platform" [CD reference/engine/classes/AccessoryDescription.yaml]. The same holds for `BodyPartDescription.Instance` [CD reference/engine/classes/BodyPartDescription.yaml].

### 1.6 Clothing (`Shirt`, `Pants`, `ShirtGraphic`)

- `Shirt` and `Pants` are visible only when they are **siblings of a Humanoid** with `ShirtTemplate` / `PantsTemplate` set to an image such as `rbxassetid://86896487`. They tint with `Clothing.Color3`. A Shirt covers the torso and arms and "will take priority over a Pants on the torso" [CD reference/engine/classes/Shirt.yaml, Pants.yaml].
- `ShirtTemplateContent`/`PantsTemplateContent` are `Content`-typed, but they **do not accept `EditableImage`** [CD reference/engine/classes/Shirt.yaml, ShirtTemplateContent]. There is therefore no zero-asset clothing texture. Clothing always needs an uploaded image.
- `ShirtGraphic` applies a texture to the torso front (a t-shirt). It has `Graphic`/`TextureContent` and `Color3` (default 1,1,1) [API; CD reference/engine/classes/ShirtGraphic.yaml].
- Roblox's own "default clothing" for unclothed avatars is `content/avatar/defaultShirt.rbxm` (`ShirtTemplate` id 855777285) and `defaultPants.rbxm` (`PantsTemplate` id 867826313). Both are network assets [RSW content/avatar/].
- `CharacterMesh` changes the appearance of R6 body parts only and needs mesh assets [CD reference/engine/classes/CharacterMesh.yaml].
- **Zero-asset alternative:** colour the parts. On R6 that means torso = shirt, arms = sleeve or skin, legs = trousers. Welded Part details work too: collars, coat hems, buttons, straps. The repo already does both.

### 1.7 Body colours

- `BodyColors` defaults: `HeadColor3`, `LeftArmColor3` and `RightArmColor3` 253,234,141; `TorsoColor3` 40,127,71; `LeftLegColor3` and `RightLegColor3` 13,105,172. Each also has a `BrickColor` twin [API `BodyColors`]. It applies colours only "when parented inside of a character with a Humanoid" [CD reference/engine/classes/BodyColors.yaml]. On Part-built rigs, setting `Part.Color` directly is simpler; a BodyColors object would override it.
- Classic BrickColor skin tones in the repo match Roblox's palette names: Bright yellow 245,205,48 (the classic Robloxian); Pastel brown; Light orange; Nougat; Brown; Reddish brown [REPO Robloxian.luau `SKINS`].
- The stock rig's colour is 163,162,165 (Medium stone grey) [RSW character.rbxm].

### 1.8 Faces and heads

- **Classic face:** `rbxasset://textures/face.png`. It is a 128×128 greyscale-with-alpha "Smile", shipped in every client's content folder. Studio's default rigs use it [RSW content/textures/face.png; CD projects/assets/index.md lists `rbxasset://textures/face.png` as an example]. It renders through a `Decal` named `face` on the Head. `Decal.Color3` tints it (default 1,1,1) and `Decal.Transparency` fades it [API `Decal`]. It is the **only** face shipped as a local file. Every other catalog face ("Face" asset type → `HumanoidDescription.Face`) is a network asset.
- **Dynamic Heads:** MeshPart heads with `FaceControls`, about 50 FACS float properties such as `JawDrop`, `EyesLookLeft` and `LeftLipCornerPuller` [API `FaceControls`]. The default dynamic head is rbxassetid 11445807850 [RSW content/avatar/defaultDynamicHead.rbxm]. That is a network asset, so avoid it for a zero-asset build.
  - `StarterPlayer.EnableDynamicHeads` (`LoadDynamicHeads`: Default/Disabled/Enabled) is not scriptable [API].
  - `AvatarEditorService:ConformToAvatarRulesAsync` "remaps classic face and classic head assets to their corresponding Dynamic Head asset IDs" [CD reference/engine/classes/AvatarEditorService.yaml].
  - A flag `FFlagSunsetEnableDynamicHeads` exists in the client [RCT FVariables.txt]. This suggests Roblox is changing how dynamic heads are toggled, so the classic Part head is the future-proof choice for our own NPCs **[inference]**.
- **Expression changes without assets:** you can't use extra textures, but you can:
  - tint or fade the face decal (for example a grey-green tint for a drowned passenger);
  - swap to a blank face (`face.Transparency = 1`) and draw features with small welded Parts, as the repo does with glasses and moustache;
  - put a `SurfaceGui` on a thin transparent face-plate Part just in front of the head (z ≈ -0.62·s) and draw eyes and mouth with `Frame` + `UICorner`. A SurfaceGui on the Head part itself would render on the flat box face at z = -0.5, *inside* the 1.25-scaled mesh, so it would be hidden **[inference from geometry; check in Studio]**.

### 1.9 HumanoidDescription reference (engine defaults)

[API `HumanoidDescription`; CD reference/engine/classes/HumanoidDescription.yaml]
- Scales: `BodyTypeScale` 0.3, `DepthScale` 1, `HeadScale` 1, `HeightScale` 1, `ProportionScale` 1, `WidthScale` 1.
- Body parts (asset IDs, int64): `Head`, `Torso`, `LeftArm`, `RightArm`, `LeftLeg`, `RightLeg`, `Face`. All default to 0, meaning the default block part.
- Body colours: `HeadColor`, `TorsoColor`, `LeftArmColor`, `RightArmColor`, `LeftLegColor`, `RightLegColor`. **All default to Color3(0,0,0), i.e. black**, so always set them. They are NotReplicated/CanSave false; the data lives in child `BodyPartDescription` instances (`AssetId`, `BodyPart`, `Color` default 0,0,0, `HeadShape`, `Instance`).
- Clothing: `Shirt`, `Pants`, `GraphicTShirt` (asset IDs, default 0).
- Accessories (comma-separated ID strings, NotReplicated): `BackAccessory`, `FaceAccessory`, `FrontAccessory`, `HairAccessory`, `HatAccessory`, `NeckAccessory`, `ShouldersAccessory`, `WaistAccessory`. `AccessoryBlob` "[]" is NotScriptable. Newer structured form: child `AccessoryDescription` (`AccessoryType`, `AssetId`, `Instance`, `IsLayered`, `Order`, `Position`, `Rotation`, `Scale`; `Puffiness` deprecated) and `GetAccessories(includeRigid)` / `SetAccessories(list, includeRigid)`. There is also a `MakeupDescription` child class.
- Animations (IDs, default 0): `ClimbAnimation`, `FallAnimation`, `IdleAnimation`, `JumpAnimation`, `MoodAnimation`, `RunAnimation`, `SwimAnimation`, `WalkAnimation`. `StaticFacialAnimation` defaults to false. Emotes: `AddEmote`, `GetEmotes`, `SetEmotes`, `GetEquippedEmotes`, `SetEquippedEmotes`, `RemoveEmote`.
- `UseAvatarSettings` (default false): when true, the experience's Avatar Settings are applied to models built from the description [CD reference/engine/classes/Players.yaml, CreateHumanoidModelFromDescriptionAsync].

### 1.10 `Players:CreateHumanoidModelFromDescriptionAsync`

- Signature: `CreateHumanoidModelFromDescriptionAsync(description: HumanoidDescription, rigType: Enum.HumanoidRigType, assetTypeVerification: Enum.AssetTypeVerification = Default) -> Model`. Tagged **Yields**, security None, capabilities AvatarAppearance and Players [CD reference/engine/classes/Players.yaml; API].
- It supersedes the now-deprecated `CreateHumanoidModelFromDescription`. The whole avatar API moved to `…Async` names: `ApplyDescriptionAsync`, `ApplyDescriptionResetAsync`, `GetHumanoidDescriptionFromUserIdAsync`/`…OutfitIdAsync`, `CreateHumanoidModelFromUserIdAsync`, `Player:LoadCharacterAsync`, `LoadCharacterWithHumanoidDescriptionAsync`, `PlayEmoteAsync`. Each deprecated name carries a `PreferredDescriptorName` in the dump [API].
- `Enum.AssetTypeVerification`: `Default` = 1, `ClientOnly` = 2, `Always` = 3. The docs say to use `Always` "unless you want to load non-catalog assets" [CD reference/engine/enums/AssetTypeVerification.yaml].
- **It works on the client.** Roblox's own client CoreScripts call it there:
  - `CharacterModelPool` does `Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)` (and R15), then sets `DisplayDistanceType = None` and anchors the HumanoidRootPart [RCT scripts/CoreScripts/Modules/InspectAndBuy/CharacterModelPool.lua l.26–28].
  - The avatar-editor prompt wraps the call in `pcall` [RCT scripts/CoreScripts/Modules/AvatarEditorPrompts/Components/HumanoidViewport.lua].
- No throttle is documented. It can fail on network or asset errors, so always use `pcall`. It isn't available in Lune.
- With an all-default description and `R6`, the result is the classic block R6 (block parts, SpecialMesh head, smile decal, as in `character.rbxm`), with **black** body colours unless you set them **[output details: verify in Studio]**. With `R15` the limbs are the stock MeshParts (network meshes). Whether the head is the classic Part head or a dynamic head depends on the dynamic-head rollout **[unverified]**.

---

## 2. Animating NPCs

### 2.1 Options compared

| Option | Assets | Where it runs | Replication | Lune | Verdict |
|---|---|---|---|---|---|
| **Procedural `Motor6D.Transform`** in `RunService.PreSimulation` | none | each client | none (`Transform` is Hidden + NotReplicated) | math is testable; timing isn't simulated | **Recommended.** Docs call it the way to do custom animation |
| `Animator` + Roblox default animation IDs, Animator created **on the client** | network (Roblox-owned animation assets) | each client | none (a locally created Animator never replicates) | no | Good for authentic idle/walk if we accept network assets |
| `Animator` + animations started **on the server** | network | server, replicated | yes | no | Costs server CPU and bandwidth. Docs advise against it for many NPCs |
| `KeyframeSequenceProvider:RegisterKeyframeSequence` / `AnimationClipProvider:RegisterAnimationClip` (local keyframes → temporary ID) | none | – | – | no | **Studio only**: "temporary and cannot be used outside of Studio" [CD reference/engine/classes/KeyframeSequenceProvider.yaml; AnimationClipProvider.yaml] |
| Legacy `Motor:SetDesiredAngle` / `MaxVelocity` | none | server or client | `DesiredAngle` replicates, `CurrentAngle` doesn't [API `Motor`] | math only | What the R6 Animate script still uses for sit/fall poses (2.4). Coarse |
| Writing `C0`/`C1` every frame | none | – | replicates if done on the server | – | Avoid: "don't update C0 and C1. Instead, update the Motor6D.Transform property" [CD performance-optimization/improve.md] |

### 2.2 `Motor6D.Transform` facts

- "It is recommended to use this property for custom animations rather than `C0` and `C1`" [CD reference/engine/classes/Motor6D.yaml, Transform]. Tags: Hidden, NotReplicated [API].
- **Timing:** Transforms are "not applied immediately … but rather as a batch in a parallel job after `RunService.PreSimulation`, immediately before physics steps". If the model has an `Animator`, Transform "will usually be overwritten every frame by the Animator after `RunService.PreAnimation` and before `RunService.PreSimulation`" [same]. So:
  - With no Animator (our procedural case), set Transform in `PreSimulation`.
  - With an Animator, *multiply into* the animated value in `PreSimulation` and skip when `animator.EvaluationThrottled` is true. This is Roblox's own sample:

```lua
RunService.PreSimulation:Connect(function()
	if not animator.EvaluationThrottled then
		neck.Transform = computeNeckRotation() * neck.Transform
	end
end)
```
[CD reference/engine/classes/AnimationConstraint.yaml; Animator.yaml, EvaluationThrottled]

- Anchoring the HumanoidRootPart doesn't stop joint animation, because Motor6D/Transform posing is kinematic. Roblox's own preview rigs are anchored and animated: the stock `morpherEditorR6.rbxmx` has `HumanoidRootPart.Anchored = true`, and `CharacterModelPool` anchors the root of models it animates [RSW content/avatar/morpherEditorR6.rbxmx; RCT CharacterModelPool.lua]. Docs: "Anchor all parts that don't need to be driven by physics, such as for static NPCs" [CD performance-optimization/improve.md].

A reusable client animator (strict Luau). It is a pure function of time and speed, so it can be unit-tested in Lune by checking the CFrames it returns:

```lua
--!strict
local RunService = game:GetService("RunService")

type Joints = { rs: Motor6D, ls: Motor6D, rh: Motor6D, lh: Motor6D, neck: Motor6D, root: Motor6D }

local function r6Pose(t: number, speed: number, talking: boolean): (CFrame, CFrame, CFrame, CFrame, CFrame, CFrame)
	-- Classic R6: same angle on both shoulders swings the arms in opposite directions (mirrored joint
	-- frames); hips take the negative (2.4). Z-axis rotation = swing; Neck Z = turn, Neck X = nod.
	local swing = math.min(1, speed / 16) * 1.0 * math.sin(t * 9) -- ~classic stride at WalkSpeed 16 [unverified numbers]
	local idle = 0.03 * math.sin(t * 1.6)
	local a = if speed > 0.2 then swing else idle
	local nod = if talking then 0.06 * math.sin(t * 11) else 0
	return CFrame.Angles(0, 0, a), CFrame.Angles(0, 0, a), CFrame.Angles(0, 0, -a), CFrame.Angles(0, 0, -a),
		CFrame.Angles(nod, 0, 0), CFrame.new(0, 0, 0.02 * math.sin(t * 1.6)) -- root: tiny breathing bob (joint Z = up)
end

local function drive(j: Joints, t: number, speed: number, talking: boolean)
	j.rs.Transform, j.ls.Transform, j.rh.Transform, j.lh.Transform, j.neck.Transform, j.root.Transform =
		r6Pose(t, speed, talking)
end

RunService.PreSimulation:Connect(function(_dt: number)
	-- for each tracked NPC within ~80 studs of the camera: drive(joints, os.clock() + seed, speed, talking)
end)
```

### 2.3 Joint axis cheat sheet

Each axis is derived from the stock joint frames. Rotation applies in the C0 frame, so the effect is `Part0 * C0 * Transform * C1⁻¹`. Confirm each sign visually once.

**R6** (frames from 1.2):
- `Right Shoulder` / `Right Hip`: joint Z = torso **+X**. `CFrame.Angles(0,0,θ)` with θ > 0 swings the limb **forward** (toward LookVector −Z).
- `Left Shoulder` / `Left Hip`: joint Z = torso **−X**. θ > 0 swings the limb **backward**. So the same θ on both shoulders gives opposite arm swings, which is why the classic scripts use `+a, +a` on the shoulders and `−a, −a` on the hips.
- `Neck`: joint Z = torso **+Y**, so `Angles(0,0,θ)` turns the head (yaw). Joint X = torso −X, so `Angles(θ,0,0)` with θ > 0 nods the head **forward/down**.
- `RootJoint`: same rotation as the Neck, pivot at the torso centre. `Angles(0,0,θ)` turns the whole body; `Angles(θ,0,0)` bows forward; `CFrame.new(0,0,h)` raises the body by h (joint Z = up); `Angles(0,θ,0)` leans sideways.

**R15** (all frames identity):
- `Angles(θ,0,0)` about +X swings a limb **forward** for θ > 0 on *both* sides, so walking uses opposite signs left and right.
- Knees bend with θ < 0 (the foot goes back). Elbows bend with θ > 0.
- `Neck`: `Angles(0,θ,0)` turns the head; `Angles(θ,0,0)` with θ > 0 tips the head back.
- `Waist`: `Angles(0,θ,0)` twists the upper body.

### 2.4 Classic R6 motion numbers (from Roblox's own R6 Animate script)

From `RCT avatar/unification/humanoidAnimateR6WithFace/init.client.lua` (the R6 Animate script shipped with the client):
- **Sit pose (legacy fallback):** `RightShoulder.MaxVelocity = 0.15`, `LeftShoulder.MaxVelocity = 0.15`, then `RightShoulder:SetDesiredAngle(3.14/2)`, `LeftShoulder:SetDesiredAngle(-3.14/2)`, `RightHip:SetDesiredAngle(3.14/2)`, `LeftHip:SetDesiredAngle(-3.14/2)` (l.445–451). The Transform equivalent for a seated passenger: `Right Shoulder = Angles(0,0,π/2)`, `Left Shoulder = Angles(0,0,-π/2)`, `Right Hip = Angles(0,0,π/2)`, `Left Hip = Angles(0,0,-π/2)`. Place the root so the torso's bottom rests on the bench (root centre = seat top + 1 stud at scale 1), or use a real `Seat` (4.3).
- **Limp poses** (Dead, GettingUp, FallingDown, PlatformStanding): `amplitude = 0.1`, `frequency = 1`, `desiredAngle = amplitude * math.sin(time * frequency)`, with `RightShoulder(+a)`, `LeftShoulder(+a)`, `RightHip(−a)`, `LeftHip(−a)` (l.456–491). The loop runs at 10 Hz (`wait(0.1)`), and `MaxVelocity` smooths between updates.
- **Walking** in the current script plays the walk animation asset `180426354`. The pre-2015 script walked procedurally with the same sign pattern at `amplitude = 1`, `frequency = 9` while running **[unverified: from memory of the old script, not in current sources]**. The repo's `CrowdController` uses a distance-driven phase (0.7 rad max swing), which reads the same.

### 2.5 `Animator` and Roblox's default animation IDs

**Replication rules** [CD reference/engine/classes/Animator.yaml, LoadAnimation]:
- An `Animator` must be in `Workspace` before `LoadAnimation`, or it throws (it can't reach `AnimationClipProvider`).
- An Animator under a **player's character** replicates animations the client starts.
- For anything else (NPCs), "animations must be loaded and started on the server to replicate".
- "The Animator object must be initially created on the server … If an Animator is created locally, then AnimationTracks loaded with that Animator will not replicate."
- `LoadAnimation` always creates a new track, so cache the tracks or use `GetTrackByAnimationId`.

**Performance guidance:** "Play NPC animations on the client … consider creating the Animator on the client and running the animations locally … only playing animations for NPCs who are near". Use `AnimationController` (+ Animator) for static NPCs, disable unused Humanoid states, and pool NPC models [CD performance-optimization/improve.md].

**API details** [API; CD reference/engine/classes/Animator.yaml]:
- `Animator.PreferLodEnabled` (default true) lets the engine throttle evaluation "based on distance, screen coverage, and frame budget". Set it to false for hero NPCs. `Animator.EvaluationThrottled` is read-only.
- `Workspace.ClientAnimatorThrottling`: `Enum.ClientAnimatorThrottlingMode` Default/Disabled/Enabled.
- `AnimationTrack:Play(fadeTime=0.1, weight=1, speed=1)`, `Stop(fadeTime=0.1)`, `AdjustSpeed(1)`, `AdjustWeight(1, 0.1)`.
- `Enum.AnimationPriority`: Idle 0, Movement 1, Action 2, Action2 3, Action3 4, Action4 5, Core 1000.
- `Humanoid:LoadAnimation` is deprecated in favour of `Animator:LoadAnimation`.

**R6 default Animate children** [RSW content/avatar/animations/humanoidR6AnimateChildren.rbxm, decoded; same IDs in RCT humanoidAnimateR6WithFace]:

| State | Animation (ID) |
|---|---|
| idle | `Animation1` 180435571 (Weight 9), `Animation2` 180435792 (Weight 1) |
| walk / run | 180426354 |
| jump | 125750702 (the script's own table has 14464997074) |
| fall | 180436148 (script: 14464364913) |
| climb | 180436334 (script: 14464300575) |
| sit | 178130996 |
| toolnone | 182393478 |
| toolslash / toollunge | 129967390 / 129967478 |
| wave | script: 14465059355 |

**R15 default Animate children** [RSW content/avatar/animations/ R15 children rbxm; script fallbacks in RCT avatar/scripts/humanoidAnimateR15.lua]:

| State | ID(s) |
|---|---|
| idle | 507766388 (Weight 9), 507766666 (Weight 1) |
| walk | 913402848 (attribute LinearVelocity 0,6.4) |
| run | 913376220 (LinearVelocity 0,12.8) |
| jump | 507765000 |
| fall | 507767968 |
| climb | 507765644 |
| sit | 2506281703 |
| swim / swimidle | 2510199791 / 2510201162 |
| toolnone / toolslash / toollunge | 507768375 / 522635514 / 522638767 |
| wave / point / laugh / cheer | 507770239 / 507770453 / 507770818 / 507770677 |
| dance, dance2, dance3 | 507771019, 507771955, 507772104; 507776043, 507776720, 507776879; 507777268, 507777451, 507777623 |

The script's fallback table uses different IDs: idle 507766666/507766951/507766388, walk 507777826, run 507767714.

**"R6-style animations on R15" set** (unification): idle 12521158637 / 12521162526, walk and run 12518152696, jump 12520880485, fall 12520972571, climb 12520982150, sit 12520993168 [RCT avatar/unification/humanoidClassicAnimate.lua].

**Animate script structure** (for replacing defaults): `animateScript.run.RunAnim`, `walk.WalkAnim`, `jump.JumpAnim`, `idle.Animation1`/`Animation2` (with a `Weight` NumberValue), `fall.FallAnim`, `swim.Swim`, `swimidle.SwimIdle`, `climb.ClimbAnim`. The docs tell developers to use catalog (Roblox-owned) animation IDs such as Ninja Run `656118852` in their experiences [CD animation/using.md]. These all remain network assets that load at runtime.

### 2.6 Avatar Joint Upgrade (`AnimationConstraint`)

- `StarterPlayer.AvatarJointUpgrade` (RolloutState) is "the default for new experiences". It is a Studio setting: the property is RobloxScriptSecurity and is saved through a hidden `AvatarJointUpgrade_SerializedRollout` [API]. With it, **R15 player characters** spawn with `AnimationConstraint` joints instead of Motor6D. `character:FindFirstChildOfClass("Motor6D")` and `IsA("Motor6D")` then fail. `C0`/`C1`/`Part0`/`Part1` exist only as **read-only** aliases [CD reference/engine/classes/AnimationConstraint.yaml, Motor6D.yaml; API].
- `AnimationConstraint.Transform` works exactly like `Motor6D.Transform`. `IsKinematic` (default true) behaves like Motor6D. "Instead of setting C0 on the server, use client-side animation evaluation" [same].
- This only affects **player characters**. Our Part-built NPCs keep the Motor6Ds we create. Any code that touches *player* avatar joints (for example a seated pose for the player in the booth) must accept both classes. `StarterPlayer.CharacterBreakJointsOnDeath` needs the upgrade [API; CD StarterPlayer.yaml].

### 2.7 Moving NPCs

- **Anchored root + scripted CFrame** (our case): the server always owns anchored parts [CD physics/network-ownership.md]. However, "If TweenService is used to tween an object server side, the tweened property is replicated to each client every frame. Not only does this result in the tween being jittery as clients' latency fluctuates, but it causes a lot of unnecessary network traffic". The mitigation is "Tween objects on the client rather than the server" [CD performance-optimization/improve.md]. Recommended pattern: the server sets attributes (`FromPos`, `ToPos`, `StartTime` from `workspace:GetServerTimeNow()`, `Speed`), and each client interpolates the root CFrame locally and derives walk speed for the limb swing. The server's copy stays authoritative for logic only.
- **`Humanoid:MoveTo(pos, part?)`** needs an unanchored root and `EvaluateStateMachine = true`. It times out after **8 s** unless re-issued. It completes within "~1 stud" and ends when WalkToPoint/WalkToPart change, `Move()` is called, or the root's CFrame is set by a script [CD reference/engine/classes/Humanoid.yaml, MoveTo]. It costs physics per NPC, and the NPC is automatically network-owned by nearby clients unless you call `SetNetworkOwner(nil)` on the server. That call "may result in jittery physics interactions" [CD physics/network-ownership.md].
- `SetNetworkOwner` can't be used on anchored parts [same].

### 2.8 Humanoid settings for NPCs

- Defaults [API `Humanoid`]: `AutoJumpEnabled` true, `AutoRotate` true, `AutomaticScalingEnabled` true, `BreakJointsOnDeath` true, `DisplayDistanceType` **Viewer**, `DisplayName` "" (shows the Model name), `EvaluateStateMachine` true, `Health`/`MaxHealth` 100, `HealthDisplayDistance` 100, `HealthDisplayType` DisplayWhenDamaged, `HipHeight` 0, `JumpHeight` 7.2, `JumpPower` 50, `MaxSlopeAngle` 89, `NameDisplayDistance` 100, `NameOcclusion` OccludeAll, `RequiresNeck` true, `RigType` R6, `UseJumpPower` true, `WalkSpeed` 16.
- **An NPC with a Humanoid and a Head shows its Model name above its head by default**. Hide it with `DisplayDistanceType = None` ("do not appear under any circumstances"). Use `HealthDisplayType = AlwaysOff` for the bar [CD characters/name-health-display.md]. For an authentic player-style name tag instead, use `DisplayDistanceType = Subject` + `NameDisplayDistance`. Use clearly fictional names, never real usernames. Names are occluded by visible geometry unless `NameOcclusion = NoOcclusion`; occluders with Transparency > 0.99 don't count [same].
- `EvaluateStateMachine = false`: "No forces … No sensors … No collision changes … No state transitions or replication". State events still fire if you set states manually [CD reference/engine/classes/Humanoid.yaml]. Ideal for anchored scripted NPCs.
- Otherwise disable unused states with `Humanoid:SetStateEnabled(state, false)`. It doesn't replicate, so call it where the humanoid is simulated [CD Humanoid.yaml; performance-optimization/improve.md]. `Enum.HumanoidStateType`: `Ragdoll` and `RunningNoPhysics` are deprecated, and `StrafingNoPhysics` is unused [CD reference/engine/enums/HumanoidStateType.yaml].
- Player characters get a default health-regeneration script [RCT avatar/scripts/humanoidHealthRegenScript.server.lua]. The usual way to remove it is an empty Script named `Health` in `StarterCharacterScripts` **[community knowledge]**. Part-built NPCs never get it.

---

## 3. Bubble chat for NPC lines

### 3.1 API

- **`TextChatService:DisplayBubble(partOrCharacter: Instance, message: string)`** "Displays a chat bubble above the provided part or player character, and fires the `BubbleDisplayed` event … Can display bubbles for non-player characters (NPCs) if you specify a part within the character, such as its head. **Note that this method is only available for use in LocalScript, or in a Script with RunContext of Client.**" [CD reference/engine/classes/TextChatService.yaml, DisplayBubble; API: no security tag, not Yields].
- `TextChatService.BubbleDisplayed(partOrCharacter, textChatMessage)` fires for each bubble [API].
- **`TextChatService.OnBubbleAdded = function(message: TextChatMessage, adornee: Instance): BubbleChatMessageProperties?`** is a client-only callback. "If the chat message is sent via DisplayBubble, adornee will be the partOrCharacter provided, and message.TextSource will be nil." Returned properties override `BubbleChatConfiguration`. `UICorner`, `UIGradient` or `ImageLabel` children of the returned object override their counterparts too [CD TextChatService.yaml, OnBubbleAdded].
- `BubbleChatMessageProperties` [API]: `BackgroundColor3` (250,250,250), `BackgroundTransparency` 0.1, `FontFace`, `TailVisible` true, `TextColor3` (57,59,61), `TextSize` 16.
- Docs example (NPC + ProximityPrompt) [CD chat/bubble-chat.md, "NPC bubbles"]:

```lua
local TextChatService = game:GetService("TextChatService")
local prompt = workspace.SomeNPC.ProximityPrompt
local head = prompt.Parent:WaitForChild("Head")
prompt.Triggered:Connect(function()
	TextChatService:DisplayBubble(head, "Hello world!")
end)
```

### 3.2 `BubbleChatConfiguration` (child of TextChatService) properties and defaults

Defaults are from [API]. Where the docs disagree [CD chat/bubble-chat.md, reference/engine/classes/BubbleChatConfiguration.yaml], that is noted, and **you should set the value explicitly**.

| Property | Engine default | Notes |
|---|---|---|
| `AdorneeName` | "HumanoidRootPart" | part or Attachment name looked up (recursively) when the adornee is a Model |
| `BackgroundColor3` | 250,250,250 | |
| `BackgroundTransparency` | 0.1 | ExpChat multiplies it by the user's PreferredTransparency setting and lerps the colour from its "Flint" grey toward `BackgroundColor3` by the same factor [ExpChat ClientSettings/ClientSettingsUtility.lua l.22–30] |
| `BubbleDuration` | **15** (s) | the guide says **30**. The ExpChat legacy defaults also say 15 |
| `BubblesSpacing` | 6 (px) | vertical gap between stacked bubbles |
| `Enabled` | **true** | the guide says true. The class reference page says false. Set it explicitly |
| `Font` | GothamMedium (Hidden, legacy) | use `FontFace` |
| `FontFace` | (guide: BuilderSansMedium) | |
| `LocalPlayerStudsOffset` | 0,0,0 | local player only |
| `MaxBubbles` | 3 | older bubbles disappear |
| `MaxDistance` | 100 | from the **camera** |
| `MinimizeDistance` | 40 | beyond this: a single "…" bubble |
| `TailVisible` | true | |
| `TextColor3` | 57,59,61 | |
| `TextSize` | 16 | |
| `VerticalStudsOffset` | 0 | extra studs above adornee |

**Advanced children** of `BubbleChatConfiguration` (or of a returned `BubbleChatMessageProperties`) [CD chat/bubble-chat.md]:
- `ImageLabel`: `Image`, `ImageColor3` (255,255,255), `ImageRectOffset`, `ImageRectSize`, `ScaleType` (Stretch), `SliceCenter`, `SliceScale` (1), `TileSize`. This gives 9-slice bubble art. The docs' example uses an uploaded image, but a local `rbxasset://textures/ui/...` 9-slice would also work **[unverified]**; see 6.1.
- `UIGradient`: `Enabled` false, `Color`, `Offset`, `Rotation`, `Transparency`.
- `UICorner`: `CornerRadius` (0,12).
- `UIPadding`: 8 px on each side.

### 3.3 How bubbles actually behave (Roblox's ExpChat source)

All points from the client's ExperienceChat package (`ExpChat` = `EC LuaPackages/Packages/_Index/ExperienceChat-567b090e-58d00f83/ExperienceChat/`):

1. **Chat permissions don't gate NPC bubbles.** `DisplayBubble` goes through `runOnBubbleDisplayed` → `IncomingBubbleChatMessageReceived`. The reducer builds those messages with `shouldOverrideBubbleChatSettings = true` and `isVisibleInBubbleChat = true`, "always visible in BubbleChat" [ExpChat installReducer/Messages.lua l.288–308; mountClientApp/init.lua l.515–552]. Player messages, by contrast, need `canLocalUserChat` and `isBubbleChatEnabled` [Messages.lua l.310–362]. Toggling `BubbleChatConfiguration.Enabled` skips messages that have `shouldOverrideBubbleChatSettings` [Messages.lua l.400–420]. So NPC bubbles appear for users with chat disabled and even with bubble chat disabled. **This is current behaviour from source, not a documented guarantee.**
2. **No console support:** the whole ExpChat app, bubbles included, renders only when `canShowDefaultChat()`, which is `not GuiService:IsTenFootInterface()` [ExpChat mountClientApp/init.lua l.220–226, App.lua l.25–27]. On Xbox and PlayStation, NPC bubbles won't show, so you need a custom BillboardGui fallback (3.6).
3. **Rendering:** a `BillboardGui` per speaker, placed in a CoreGui ScreenGui (`ExperienceChat`, `ResetOnSpawn = false`, `DisplayOrder -1`) [RCT scripts/CoreScripts/CoreScripts/ExperienceChatMain.lua l.78–84]. Size `UDim2.fromOffset(500, 200)`, `SizeOffset (0, 0.5)`, `StudsOffset = (0, 1, 0.1) + (0, VerticalStudsOffset, 0)` for non-local speakers, `ResetOnSpawn = false`. **`AlwaysOnTop` is not set, so bubbles are hidden by geometry in front of them** [ExpChat BubbleChat/BillboardGui/BillboardGui.lua l.416–428]. Behaviour behind transparent glass (the booth window) is **[untested]**.
4. **Adornee resolution:**
   - **Pass the NPC Model:** the bubble attaches to `model:FindFirstChild(AdorneeName, true)` or else `PrimaryPart`, and a spring-animated vertical offset lifts it to the **top of the model's bounding box**, so it clears hats [BillboardGui.lua l.224–261].
   - **Pass the Head:** the offset is `Head.Size.Y/2`, so tall hats can overlap the bubble.
   - Attachments are also accepted as adornees.
5. **Distance:** rendered only while the camera is within `MaxDistance`. Beyond `MinimizeDistance`, bubbles collapse to an ellipsis bubble [BillboardGui.lua l.494–510].
6. **Look:** text `RichText = true`, `TextWrapped`, max width **300 px**, padding 8 px. The tail image is `rbxasset://textures/ui/InGameChat/Caret.png` at 9×6 px, tinted with the background colour. Size and transparency use spring animations [ExpChat BubbleChat/ChatBubble/ChatBubble.lua l.150–180; installReducer/BubbleChat/LegacySettings.lua]. Whether `DisplayBubble` escapes rich-text markup is **[untested]**; test `<i>…</i>` before relying on it.
7. Stacking is per speaker, with `MaxBubbles` 3. Bubbles fade after `BubbleDuration`. Whitespace-only text is dropped. For a non-player adornee, ExpChat mints a "mock userId" per `partOrModel` instance [ExpChat installReducer/Messages.lua l.84–122]. **Always pass the same instance for the same NPC** (for example, always the Model); a Model and its Head would make two separate bubble stacks.
8. **Legacy `Chat:Chat(part, message, color)`** still produces bubbles: ExpChat listens to `Chat.Chatted` "for compatibility" [mountClientApp/init.lua l.544–547]. The `Chat` service is legacy; prefer DisplayBubble.
9. `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)` hides the chat window and input bar but not bubbles. Only the `isChatWindowEnabled` and `isChatInputBarEnabled` reducers consume the CoreGui flag, and `AppContainer` renders `bubbleChat` as a separate child [ExpChat installReducer/ChatVisibility/isChatWindowEnabled.lua l.42–52; isChatInputBarEnabled.lua l.66–102; AppContainer/AppContainer.lua l.105–150]. To hide the window only, use `TextChatService.ChatWindowConfiguration.Enabled = false` (default true; bg 25,27,29 at 0.3 transparency; TextSize 14) and `ChatInputBarConfiguration.Enabled = false` (bg 25,27,29 at 0.2; `KeyboardKeyCode` Slash) [API].

### 3.4 Setup requirements

- `TextChatService.ChatVersion` must be `TextChatService`. It is **write-protected (RobloxScriptSecurity)** for scripts, and the API dump's class default is `LegacyChatService` [API]. The property "has been deprecated in newly created Studio experiences. TextChatService is the only allowed chat system and is automatically enabled" [CD reference/engine/classes/TextChatService.yaml, ChatVersion]. "All games that offer in-game text chat for users must integrate TextChatService" [CD chat/guidelines.md]. Set it in the place file. Rojo can serialize it in `default.project.json` → `"TextChatService": {"$properties": {"ChatVersion": "TextChatService"}}` for `rojo build`. Live `rojo serve` sync may be refused because of the security level, so set it once in Studio **[unverified for serve]**.
- `CreateDefaultTextChannels` and `CreateDefaultCommands` default to true (PluginSecurity write) [API].
- **Filtering:** "you are responsible for filtering any displayed text that you don't have explicit control over" [CD ui/text-filtering.md]. Developer-written NPC lines are under our control and need no `TextService:FilterStringAsync` pass. The chat policy lists "Text on menus created by developers" and "Status updates from the game" as **not** chat, and requires filtering for "incoming text that originates from another user" [CD chat/guidelines.md]. Anything built from player input (names typed by players, etc.) must be filtered on the server first (`TextService:FilterStringAsync` → `GetNonChatStringForBroadcastAsync`) [CD ui/text-filtering.md].

### 3.5 Recommended client code

```lua
--!strict
-- StarterPlayerScripts (client). The server fires Net "Say"(npcModel, text, styleName).
local TextChatService = game:GetService("TextChatService")
local GuiService = game:GetService("GuiService")

local config = TextChatService:WaitForChild("BubbleChatConfiguration") :: BubbleChatConfiguration
config.Enabled = true -- don't trust the default (docs disagree)
config.BubbleDuration = 8
config.MaxBubbles = 2
config.MaxDistance = 120
config.MinimizeDistance = 80 -- passengers are 10-40 studs from the booth camera
config.VerticalStudsOffset = 0.5
config.FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium)
config.TextSize = 18

local STYLES: { [string]: { bg: Color3, text: Color3, font: Font } } = {
	normal = { bg = Color3.fromRGB(250, 250, 250), text = Color3.fromRGB(57, 59, 61), font = Font.fromEnum(Enum.Font.BuilderSansMedium) },
	wrong = { bg = Color3.fromRGB(20, 24, 22), text = Color3.fromRGB(170, 214, 190), font = Font.fromEnum(Enum.Font.SpecialElite) },
}

TextChatService.OnBubbleAdded = function(message: TextChatMessage, adornee: Instance): BubbleChatMessageProperties?
	if message.TextSource ~= nil or adornee == nil then
		return nil -- a real player's bubble: leave it alone
	end
	local style = STYLES[(adornee:GetAttribute("BubbleStyle") :: string?) or "normal"] or STYLES.normal
	local props = Instance.new("BubbleChatMessageProperties")
	props.BackgroundColor3 = style.bg
	props.TextColor3 = style.text
	props.FontFace = style.font
	return props
end

local function say(npc: Model, text: string)
	if GuiService:IsTenFootInterface() then
		-- consoles: ExpChat is not mounted; show our own BillboardGui bubble instead (3.6)
		return
	end
	TextChatService:DisplayBubble(npc, text) -- pass the Model: bubble sits above hats
end
```

### 3.6 Fallback and alternatives

- **Custom BillboardGui bubble** (consoles, or when we need `AlwaysOnTop`, a longer maximum width, or typewriter effects): mirror the look from 3.3. White `Frame` 250,250,250 at `BackgroundTransparency` 0.1, `UICorner` 12, `UIPadding` 8, text 57,59,61 at size 16 in BuilderSansMedium, max width 300 via `UISizeConstraint` and `AutomaticSize = XY`. Add a 9×6 tail `ImageLabel` using `rbxasset://textures/ui/InGameChat/Caret.png`. Use `BillboardGui.Size = UDim2.fromOffset(300, 150)`, `StudsOffset = Vector3.new(0, 1, 0)` and `LightInfluence = 0` (the default). Set `MaxDistance` as you like; its default is INF [API `BillboardGui`].
- **`Dialog` / `DialogChoice`**: Roblox's built-in click-to-talk NPC dialog. Not deprecated. Defaults: `ConversationDistance` 25, `Purpose` Help, `Tone` Neutral, `BehaviorType` SinglePlayer, `InitialPrompt` "", `TriggerDistance` 0, `GoodbyeChoiceActive` true [API; CD reference/engine/classes/Dialog.yaml]. Player-initiated and CoreScript-rendered, so it suits Q&A rather than timed lines. It isn't recommended for the booth flow, and it is untested with TextChatService.

---

## 4. Player characters in a fixed-camera booth

### 4.1 Two setups

| | **A. No avatar** (current: `Players.CharacterAutoLoads = false` in `REPO games/last-ferry/default.project.json` and `Server.server.luau`) | **B. Visible avatar in the booth** |
|---|---|---|
| Spawning | Never call `LoadCharacterAsync` | `CharacterAutoLoads` true, or `player:LoadCharacterAsync()` then place the character |
| Controls | Nothing to move | Freeze (4.3) |
| Camera | `Scriptable` | `Scriptable` (4.4) |
| StarterGui | **Not cloned** until `LoadCharacterAsync` is called, so build UI into `PlayerGui` from script (the repo does) [CD ui/on-screen-containers.md; PlayerGui.yaml] | cloned on spawn. Set `ScreenGui.ResetOnSpawn = false` for persistent HUD |
| ProximityPrompt / ClickDetector | `MaxActivationDistance` is measured from the player's **character** [CD reference/engine/classes/ProximityPrompt.yaml, ClickDetector.yaml]. Without one, prompts never show **[inference]**. Use GUI buttons or camera raycasts | work (place the character within 10 studs, the default) |
| Chat bubbles | NPC bubbles still work: distance is measured from the camera (3.3) | same. The player's own chat also bubbles above their avatar |
| Roblox vibe | Low: you're a disembodied camera | High: your own avatar is visible in the booth. It is loaded with the user's appearance (network assets supplied by the platform) |

### 4.2 Relevant properties and defaults

**`Players`** [API; CD reference/engine/classes/Players.yaml]:
- `CharacterAutoLoads` true (NotReplicated): "If this property is disabled (false), player characters will not spawn until the `Player:LoadCharacterAsync()` function is called for each Player, including when players join".
- `RespawnTime` "defaults to 5.0 seconds". `UseStrafingAnimations` is NotScriptable. Players is a service, so the API dump lists no defaults for it.

**`Player:LoadCharacterAsync()`** (supersedes deprecated `LoadCharacter`) [API; CD reference/engine/classes/Player.yaml]:
- Event order: `Character` set → `CharacterAdded` → `Changed` → appearance initialised → `CharacterAppearanceLoaded` → parented to the DataModel → rig built and scaled → moved to spawn.
- It "also clears the player's Backpack and PlayerGui". Give HUD ScreenGuis `ResetOnSpawn = false` or rebuild them after spawning. Don't call it again before `CharacterAppearanceLoaded` fires.
- Variant `LoadCharacterWithHumanoidDescriptionAsync(desc)`.
- With no `SpawnLocation`, Studio play inserts the avatar at "around (0, 100, 0)" [CD includes/studio/playtest-modes.md].
- `SpawnLocation.Duration` 10 s ForceField. 0 disables it and creates no ForceField instance [CD reference/engine/classes/SpawnLocation.yaml].

**`StarterPlayer`** [API; CD reference/engine/classes/StarterPlayer.yaml]:
- Movement and jumping: `AutoJumpEnabled` true, `CharacterWalkSpeed` 16, `CharacterJumpHeight` 7.2, `CharacterJumpPower` 50, `CharacterUseJumpPower` true, `CharacterMaxSlopeAngle` 89.
- Camera: `CameraMaxZoomDistance` 400, `CameraMinZoomDistance` 0.5, `CameraMode` Classic, `DevCameraOcclusionMode` Zoom, `DevComputerCameraMovementMode` / `DevTouchCameraMovementMode` UserChoice.
- Controls: `DevComputerMovementMode` / `DevTouchMovementMode` UserChoice, `EnableMouseLockOption` true.
- Name and health: `HealthDisplayDistance` 100, `NameDisplayDistance` 100 (set 0 to hide others' tags).
- Avatar and death: `LoadCharacterAppearance` true (false = default-looking characters), `ClassicDeath` true, `CharacterBreakJointsOnDeath` true, `UserEmotesEnabled` true, `AllowCustomAnimations` true (Hidden, write RobloxScriptSecurity).
- Rollout switches: `CreateDefaultPlayerModule` true, `EnableDynamicHeads` (`Enum.LoadDynamicHeads` Default/Disabled/Enabled, NotScriptable), `LuaCharacterController` Default (`Enum.CharacterControlMode` Default/Legacy/NoCharacterController/LuaCharacterController), `AvatarJointUpgrade` (2.6).
- Template models: `StarterCharacter` / `StarterHumanoid` children override the spawned model. A **Part-built R6 named `StarterCharacter` makes every player a classic Robloxian with no assets**, as an alternative to their own avatar.

**Avatar Settings** (Studio: File/Avatar → Avatar Settings) [CD studio/avatar-settings.md]:
- "modifies underlying game defaults that are **not visible outside of the settings interface or accessible with scripts**".
- Avatar type: R6, R15, or R15 & R6.
- General presets: Player Choice, or Consistent Gameplay ("same height with the same box collider").
- Body: Scale (Player Choice / Custom Scale; "classic style avatars are around 5 studs tall … humanoid style proportions are around 6 to 6.5"), Appearance (Custom Parts by ID), Build.
- Clothing and accessory overrides.
- Collision: Default = OuterBox, Single Collider, Legacy = InnerBox.
- Animation Packs: Player Choice / Standard R15 / **Standard R6**, plus Custom Clips.
- Abilities: Legacy Humanoid (default) / Character Controller Library.
- The backing classes (`AvatarSettings`, `AvatarRules`, `AvatarBodyRules`, `AvatarCollisionRules`, `AvatarAnimationRules`, …) are RobloxScriptSecurity and not scriptable [API].
- `HumanoidDescription.UseAvatarSettings` makes description-built models follow these settings.
- R6 avatars in an R15-mode game go through the R6-to-R15 adapter (`Workspace.AvatarUnificationMode`, NotScriptable) [CD characters/r6-to-r15-adapter.md; API].

### 4.3 Freezing the player in the booth

1. **Built-in controls off for everyone:** set `StarterPlayer.DevComputerMovementMode = Scriptable` and `DevTouchMovementMode = Scriptable`. Per-player equivalents are `Player.DevComputerMovementMode` / `Player.DevTouchMovementMode`.
   - Scriptable "Disables all default controls" [CD reference/engine/enums/DevComputerMovementMode.yaml] and "The player's character will not respond to default controls" [DevTouchMovementMode.yaml].
   - In the classic ControlModule, `Scriptable` returns no computer module **including gamepad**, and no touch module, so the thumbstick and jump button aren't created [RCT scripts/PlayerScripts/StarterPlayerScripts/PlayerModule.module/ControlModule.lua l.335–396].
2. `require(player.PlayerScripts.PlayerModule):GetControls():Disable()` works with the **classic** PlayerModule only [RCT PlayerModule.module.lua; ControlModule `Enable(enable?)`/`Disable()` l.315–333]. The new InputAction-based PlayerModule is used when `Workspace.PlayerScriptsUseInputActionSystem` is enabled; the scripts then live under StarterPlayer and the server processes input [CD reference/engine/classes/Workspace.yaml]. It says: "PlayerModule currently has no public API" [RCT scripts/PlayerScripts/StarterPlayer/PlayerModule/init.lua l.131–135]. So **don't rely on `GetControls()`**. Use option 1 plus 3.
3. **Belt and braces (server):**
   - Anchor the character's HumanoidRootPart, or set `Humanoid.WalkSpeed = 0`, `JumpHeight = 0` (and `JumpPower = 0`) and `AutoRotate = false`.
   - Or seat them: `Seat:Sit(humanoid)` creates a `Weld` named `SeatWeld`, parented to the seat, with "the character … welded 2 studs above the seat". Jumping exits the seat, so on the owning client call `humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)`; `SetStateEnabled` doesn't replicate. There is a 3 s re-sit cooldown per character per seat [CD reference/engine/classes/Seat.yaml].
4. `GuiService.TouchControlsEnabled = false` hides the touch thumbstick and jump button on the client [API; RCT ControlModule l.146, l.302–306].

### 4.4 Camera

- `workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable`, then set `Camera.CFrame`. With Scriptable "you should update [`Camera.Focus`] every frame because certain visuals are more detailed depending on how close they are to the focus point". `FieldOfView` default 70, range 1–120 [CD workspace/camera/index.md]. The repo does this [REPO games/last-ferry/ReplicatedStorage/Controllers/CameraController.luau l.177].
- If the camera sits inside or behind the player's own head: set `BasePart.LocalTransparencyModifier` on the local character's parts (client only). Effective transparency = `1 - (1 - Transparency) * (1 - LocalTransparencyModifier)` [CD reference/engine/classes/BasePart.yaml, LocalTransparencyModifier]. The default camera scripts overwrite it in first person, which doesn't matter with Scriptable **[inference]**.
- `Humanoid.CameraOffset` is "an offset applied to the Camera's subject position when its CameraSubject is set to this Humanoid", in object space relative to the HumanoidRootPart [CD reference/engine/classes/Humanoid.yaml]. It is irrelevant with a Scriptable camera.

---

## 5. UI

### 5.1 Fonts

**Constructors** [CD reference/engine/datatypes/Font.yaml]:
- `Font.new(family: Content, weight = Enum.FontWeight.Regular, style = Enum.FontStyle.Normal)`; the family is `rbxasset://fonts/families/<Name>.json` or `rbxassetid://<id>`.
- `Font.fromEnum(Enum.Font)` throws on `Unknown`.
- `Font.fromName("FredokaOne", weight?, style?)` → `rbxasset://fonts/families/FredokaOne.json`; letters, digits, `_`, `-` only.
- `Font.fromId(id, weight?, style?)` for uploaded font families.
- Properties: `Family`, `Weight`, `Style`, `Bold`.

**`Enum.Font`** [API]: Legacy 0, Arial 1, ArialBold 2, SourceSans 3, SourceSansBold 4, SourceSansLight 5, SourceSansItalic 6, Bodoni 7, Garamond 8, Cartoon 9, Code 10, Highway 11, SciFi 12, Arcade 13, Fantasy 14, Antique 15, SourceSansSemibold 16, Gotham 17, GothamMedium 18, GothamBold 19, GothamBlack 20, AmaticSC 21, Bangers 22, Creepster 23, DenkOne 24, Fondamento 25, FredokaOne 26, GrenzeGotisch 27, IndieFlower 28, JosefinSans 29, Jura 30, Kalam 31, LuckiestGuy 32, Merriweather 33, Michroma 34, Nunito 35, Oswald 36, PatrickHand 37, PermanentMarker 38, Roboto 39, RobotoCondensed 40, RobotoMono 41, Sarpanch 42, SpecialElite 43, TitilliumWeb 44, Ubuntu 45, BuilderSans 46, BuilderSansMedium 47, BuilderSansBold 48, BuilderSansExtraBold 49, Arimo 50, ArimoBold 51, Unknown 100.
- "`Gotham` has been removed. Using it will map to the `Montserrat` font" (likewise GothamMedium, GothamBold, GothamBlack) [CD reference/engine/enums/Font.yaml].
- `Font.fromEnum` maps the old names to families: Antique → RomanAntique, Arcade → PressStart2P, Bodoni → AccanthisADFStd, Cartoon → ComicNeueAngular, Code → Inconsolata, Fantasy → Balthazar, Garamond → Guru, Highway → HighwayGothic, SciFi → Zekton, Legacy → LegacyArial, SourceSans* → SourceSansPro [CD reference/engine/datatypes/Font.yaml, fromEnum table].

**Built-in families: faces shipped locally vs downloaded on first use.** Local faces are `rbxasset://fonts/*.ttf|otf` files, which are in the Studio manifest. Cloud faces are `rbxassetid://` [RSW content/fonts/families/*.json; RCT rbxManifest.txt]. Cloud faces download the first time they are used, and text can briefly render in a fallback **[inference]**, so prefer local faces for the HUD.

| Family | Local faces | Cloud-only faces |
|---|---|---|
| **BuilderSans** (Roblox's UI font) | Regular 400, Medium 500, Bold 700, ExtraBold 800 | Thin, Light, SemiBold |
| BuilderExtended | Regular, SemiBold, Bold | Light, ExtraBold |
| BuilderMono | Light, Regular, Bold | – |
| **Montserrat** (Gotham stand-in: the 2017–2023 Roblox UI look) | Regular, Medium, Bold, Black | the other weights and italics |
| **SourceSansPro** (2014–2017 Roblox UI) | Light, Regular, Italic, SemiBold, Bold | ExtraLight, Black, other italics |
| **LegacyArial** / LegacyArimo (2006–2013 `Enum.Font.Legacy`/`Arial`) | Regular, Bold | – |
| Arimo | Regular, Bold | Medium, SemiBold, italics |
| **Creepster** (horror) | Regular | – |
| **SpecialElite** (typewriter) | Regular | – |
| **GrenzeGotisch** (blackletter) | Regular, Bold | Thin…Black |
| **HighwayGothic** (road-sign; ferry signage) | Regular | – |
| Merriweather (serif) | Regular, Italic | Light, Bold, Black (+ italics) |
| Oswald (condensed) | Regular, Bold | ExtraLight, Light, Medium, SemiBold |
| FredokaOne, LuckiestGuy, Bangers, DenkOne (bubbly "simulator" titles) | Regular | – |
| PermanentMarker, IndieFlower, PatrickHand, Kalam (handwriting) | Regular (Kalam: Regular) | Kalam Light, Bold |
| PressStart2P (Arcade), Zekton (SciFi), Michroma, Jura | Regular | Jura Light…Bold |
| RobotoMono, Roboto, RobotoCondensed, Inconsolata, Ubuntu, Nunito, TitilliumWeb, Sarpanch, JosefinSans | Regular (Roboto also Italic, Bold; Ubuntu Italic; TitilliumWeb Bold; Sarpanch Bold) | the other weights |
| AccanthisADFStd (Bodoni), RomanAntique (Antique), Guru (Garamond), Balthazar (Fantasy), Fondamento (Regular, Italic), AmaticSC (Regular, Bold), ComicNeueAngular (Bold only) | as listed | – |
| NotoSansCJKFallback | – | Regular |

- No Nosifer and no "GothamSSm" family ships. ExpChat's own config references GothamSSm Medium internally.
- The **Builder font licence** allows use "solely for … UGC … on the Roblox platform and for digital promotions incorporating such UGC off of the Roblox platform". In-experience UI and marketing images of the game are fine; using the font outside Roblox is not [CD resources/builder-font-license.md].
- **Instance.new gotchas:** a new `TextLabel` has `Font = Legacy`, `TextSize = 8`, `TextColor3 = 27,42,53`, `TextStrokeTransparency = 1`, `RichText = false` [API]. Always set `FontFace` and `TextSize`.
- Other text properties: `LineHeight` 1, `MaxVisibleGraphemes` -1 (typewriter reveal), `OpenTypeFeatures`, `TextDirection` [API].
- `UITextSizeConstraint` defaults Min 1 / Max 100 [API]. "Do not use MinTextSize property values lower than 9 or the text will be difficult to read for many viewers" [CD ui/size-modifiers.md]. On mobile legibility: "Avoid excessively decorative or thin fonts", so keep Creepster and Grenze Gotisch for short titles only [CD production/publishing/adaptive-design.md].

### 5.2 Appearance modifiers (defaults from API; behaviour from CD ui/appearance-modifiers.md)

- **`UIStroke`**:
  - `ApplyStrokeMode` Contextual (outlines the text on text objects, the border otherwise); `Border` strokes the bounds. Two UIStrokes on one text object (one Contextual, one Border) outline text and box independently [CD ui/appearance-modifiers.md].
  - `BorderStrokePosition` Outer (Outer/Center/Inner). `BorderOffset` UDim 0,0.
  - `Color` black, `Enabled` true, `Thickness` 1, `Transparency` 0, `ZIndex` 1.
  - `LineJoinMode` Round (Round/Bevel/Miter).
  - `StrokeSizingMode` FixedSize (ScaledSize = relative to size).
  - A `UIGradient` under a UIStroke colours the stroke. "Both the parent object and UIStroke can have child UIGradient instances", so stroke and fill gradients are independent [CD ui/appearance-modifiers.md].
- **`UICorner`**: `CornerRadius` (0,8), plus per-corner `TopLeftRadius`, `TopRightRadius`, `BottomRightRadius`, `BottomLeftRadius` (each (0,8), each saved). `CornerRadius` is NotReplicated/CanSave false, so it acts as a convenience alias over the four [API].
- **`UIGradient`**: `Color` white→white, `Transparency` 0→0, `Offset` 0,0, `Rotation` 0, `Scale` 1, `TileMode` Clamp (Clamp/Repeat/Mirror), `Type` Linear (Linear/Radial/Conical/Elliptical), `Enabled` true.
- **`UIShadow`** (new):
  - `BlurRadius` UDim 0,0 (scale relative to the shorter side), `Color` black, `Enabled` true, `Inset` false, `Mode` Shape (`Enum.ApplyShadowMode` Shape/Text), `Offset` UDim2, `ShowBehindParent` true, `Spread` UDim2, `Transparency` 0, `ZIndex` -1 [API].
  - The docs' limitations list says UIShadow "does not support text" (it shadows a TextLabel's rectangle), "does not support inset shadows", Path2D, textures or gradients, while the API already has `Mode = Text` and `Inset`. Those are probably still rolling out, so test before relying on them [CD reference/engine/classes/UIShadow.yaml].
  - It follows the parent's `UICorner` and `Rotation`, and multiple shadows order by ZIndex.
- **`UIPadding`**: all four sides 0. **`UIScale`**: `Scale` 1 (the repo scales a design canvas).
- **`CanvasGroup`**: `GroupTransparency` 0 and `GroupColor3` white fade or tint a whole subtree as one layer (render-target cost).

### 5.3 Layout

- `UIListLayout` flex: `Wraps` false, `HorizontalFlex` / `VerticalFlex` (`Enum.UIFlexAlignment` None/Fill/SpaceAround/SpaceBetween/SpaceEvenly), `ItemLineAlignment` Automatic, `Padding` [API; CD ui/list-flex-layouts.md].
- `UIFlexItem`: `FlexMode` None (None/Grow/Shrink/Fill/Custom), `GrowRatio` 0, `ShrinkRatio` 0, `ItemLineAlignment` Automatic [API].
- `UIAspectRatioConstraint`: `AspectRatio` 1, `AspectType` FitWithinMaxSize, `DominantAxis` Width. `UISizeConstraint`: Min 0,0, Max INF [API].
- `GuiObject.AutomaticSize` for text bubbles and toasts [CD ui/size-modifiers.md].
- **9-slice:** `ImageLabel.ScaleType = Slice`, `SliceCenter` (Rect, pixels), `SliceScale` (default 1) [CD ui/9-slice.md].
- **`UIDragDetector`**: `DragStyle` TranslatePlane, `ResponseStyle` Offset, `BoundingBehavior` Automatic, `DragAxis` (1,0), `DragRelativity` Absolute, `DragSpace` Parent, `MinDragTranslation`/`MaxDragTranslation`, `SelectionModeDragSpeed` (0,300,0,300) [API; CD ui/ui-drag-detectors.md]. Good for sliding a ticket across the counter.

### 5.4 Styling (StyleSheets): runtime-buildable

- `StyleLink` (in a ScreenGui) → `StyleSheet` (`StyleRule` children). A `StyleSheet` derives from others via `StyleDerive` (`Priority`) and holds **tokens** as attributes; values reference tokens with `"$Name"`. "Only one StyleSheet can apply to a given tree" [CD ui/styling/index.md].
- `StyleRule.Selector` syntax [CD reference/engine/classes/StyleRule.yaml]:
  - Selectors: class (`"Frame"`, `"UICorner"`), tag (`".ButtonPrimary"`, CollectionService tags), name (`"#CloseButton"`), state (`":Hover"`; `Enum.GuiState` Idle/Hover/Press/NonInteractable), query (`"@Name"`; built-ins `@ReducedMotionEnabledTrue`, `@PreferredInputTouch`, `@PreferredInputGamepad`, `@PreferredInputKeyboardAndMouse`, `@PreferredTextSizeLarge`…, `@ViewportDisplaySizeSmall/Medium/Large`).
  - Combinators: `>` (child), `>>` (descendant), `,` (list), `::` (phantom UIComponent, e.g. `"Frame::UICorner"`, `"::UIStroke #Outer"`).
- API [API]: `StyleRule:SetProperty(name, value)`, `SetProperties(dict)`, `SetPropertyTransition(prop, params)`, `SetPropertyTransitions`, `SetDefaultPropertyTransition`, `GetProperties`; `Priority` (int). `StyleBase:InsertStyleRule(rule, priority?)`, `GetStyleRules`, `SetStyleRules`. `StyleSheet:GetDerives()/SetDerives()`. `StyleQuery:SetCondition(name, value)` / `SetConditions`, `IsActive`.
- Rule properties serialize to a hidden `PropertiesSerialize` BinaryString, so **build rules in code** (works with Rojo). Styled properties show a ⚠ in the Properties window.

```lua
--!strict
-- Roblox-flavoured buttons for every ScreenGui that links this sheet.
local sheet = Instance.new("StyleSheet")
sheet:SetAttribute("Ink", Color3.fromRGB(25, 27, 29))       -- Roblox chat/topbar panel colour
sheet:SetAttribute("Paper", Color3.fromRGB(255, 255, 255))
local button = Instance.new("StyleRule")
button.Selector = "TextButton.RbxButton"
button:SetProperties({
	BackgroundColor3 = "$Ink",
	BackgroundTransparency = 0.3,
	TextColor3 = "$Paper",
	FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
	TextSize = 20,
})
button.Parent = sheet
local corner = Instance.new("StyleRule")
corner.Selector = "TextButton.RbxButton::UICorner"
corner:SetProperty("CornerRadius", UDim.new(0, 8))
corner.Parent = sheet
local hover = Instance.new("StyleRule")
hover.Selector = "TextButton.RbxButton:Hover"
hover:SetProperty("BackgroundTransparency", 0.15)
hover.Parent = sheet
-- local link = Instance.new("StyleLink"); link.StyleSheet = sheet; link.Parent = hudScreenGui
```

### 5.5 Screen space, CoreGui, accessibility

- **`ScreenGui` defaults** [API; CD includes/ui/screen-insets.md]: `ScreenInsets` **CoreUISafeInsets** (None/DeviceSafeInsets/CoreUISafeInsets/TopbarSafeInsets), `ClipToDeviceSafeArea` true, `SafeAreaCompatibility` FullscreenExtension, `IgnoreGuiInset` false, `DisplayOrder` 0, `ResetOnSpawn` true.
- **GuiService** [API; CD reference/engine/classes/GuiService.yaml]:
  - `TopbarInset` (Rect, read-only); `GetInsetArea(screenInsets)`; `GetGuiInset()`.
  - `PreferredTransparency` (multiply your panel transparencies by it); `PreferredTextSize` (Medium/Large/Larger/Largest; not applied to `TextScaled`); `ReducedMotionEnabled`.
  - `ViewportDisplaySize`, `TouchControlsEnabled`, `IsTenFootInterface()`.
  - **`SendNotification{Title, Text, Icon, Buttons = {{Text, ButtonType = Enum.NotificationButtonType.Primary/Secondary, OnActivated}}, OnDisplay, OnDismiss}`** shows Roblox's **native** notification UI and returns an id for `DismissNotification`. Security None: authentic Roblox toasts at no art cost [CD GuiService.yaml, SendNotification]. `StarterGui:SetCore("SendNotification", …)` is the older route [CD reference/engine/classes/StarterGui.yaml].
- **`StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.X, false)`**: PlayerList, Health, Backpack, Chat, All, EmotesMenu, SelfView, Captures, AvatarSwitcher, ExperienceShop [API].
- **Top bar metrics** (to align our HUD with Roblox's) [RCT scripts/CoreScripts/Modules/TopBar/Constants.lua]: `TopBarHeight` 58 with the current "Chrome" top bar (36 legacy); button height 44 (Chrome); `ScreenSideOffset` 16; `TopBarPadding` 12. Health bar colours: red 255,28,0; yellow 250,235,0; green 27,252,107.
- **Roblox's own chat UI palette** (a safe "looks like Roblox" panel style): window background 25,27,29 at 0.3 transparency, input bar 25,27,29 at 0.2, white text size 14 with a black stroke at 0.5 [API `ChatWindowConfiguration`, `ChatInputBarConfiguration`].

#### The top bar row, in detail

Researched from Roblox's client scripts (RCT, client 0.741, including files from its history), the design tokens in the client's packages (EC), the creator docs (CD), TopbarPlus v3.4 and search snippets of DevForum threads (the forum itself is blocked).

- **Size and placement:** the row is 58 px (87 on a TV: 1.5×); buttons and pills are 44 px, at y 12 to 56. The Roblox button is at x 16 to 60, then the unibar from x 68: 4 + 44 per icon + 4 [RCT scripts/CoreScripts/Modules/TopBar/Constants.lua; Chrome/ChromeShared/Unibar/Constants.lua; UnibarMenu.lua]. Checked against measurements of the docs' own screenshots.
- **`GuiService.TopbarInset`** is the widest gap between Roblox's "keep-out areas" in the row [RCT Chrome/ChromeShared/Service/KeepOutAreasHandler.lua]. With the menu and chat in the unibar it's about `Rect(164, 0, width, 58)` on a PC; 208 with a mic, 120 with chat off, 52 more with the global shop button. It's measured from the device safe area's left edge, so on a notched phone add the notch. Nothing sits at the right end by default, except the health bar while a character is hurt, which isn't counted (so disable `CoreGuiType.Health` if you use that end) [RCT TopBar/Components/Presentation/HealthBar.lua].
- **It changes:** when icons come and go (voice, a party, the shop) over about 150 ms; with a gamepad Roblox hides its buttons and the whole row is free until the menu opens [RCT TopBar/Components/GamepadConnector.lua]; it can be zero for the first frames of a game, and one regression made it 16 × 58. Consoles got the new top bar through an A/B test; VR moves Roblox's buttons to a 3D panel. So a game using the row needs a fallback, and should listen for `AbsoluteSize` changes rather than read it once.
- **Roblox's pill style (dark theme):** near-black 18, 18, 21 (Foundation `OverMedia_0`) at 8% transparency, multiplied by `GuiService.PreferredTransparency`; fully rounded; icons and emphasis text 247, 247, 248, muted text 188, 190, 200; a highlight of 208, 217, 251 at 0.92 on hover and 0.88 when pressed; 8 px between items; Builder Sans, Bold 18 for titles and Medium 15 for labels [EC RbxDesignFoundations Default/Dark.lua; UIBlox App/Style/Tokens/mappers.lua; RCT UnibarMenu.lua, TopBar/Components/Presentation/IconButton.lua]. TopbarPlus draws its icons the same way, in a `TopbarSafeInsets` ScreenGui, with fallbacks for short, empty, console and VR rows [GitHub 1ForeverHD/TopbarPlus, src/Elements/Container.lua].
- **Coordinates:** `AbsolutePosition` is measured from the bottom-left corner of the top bar, at the device safe area's left edge (the `CoreUISafeInsets` system), as `InputObject.Position` is [CD reference/engine/classes/GuiBase2d.yaml]; `Camera:WorldToScreenPoint` "takes in account the current GUI inset … the 2D position returned is in the same term as GUI positions" [CD reference/engine/classes/Camera.yaml]. `WorldToViewportPoint` is "taken from the top left corner of the viewport", and the viewport (`ViewportSize`) is the device safe area, top bar included but not the notch [CD Camera.yaml]. So neither gives positions on a ScreenGui with `ScreenInsets = None` (which covers the whole screen, notch too) directly: that layer starts at (−notch, −top bar) in GUI coordinates. To put something over a point in the world on it, take the layer's `AbsolutePosition` off `WorldToScreenPoint`. `WorldToViewportPoint` would put it off by the notch on a phone: 47 px on an 844 × 390 one.
- **Measuring text without showing it:** Roblox's own bubble chat measures each message with a `TextLabel` in a disabled ScreenGui and reads its `TextBounds` straight away [EC BubbleChat/Helpers/getTextBounds.lua]. A hidden object's own `AbsoluteSize` isn't a safe measure: DevForum reports say `AbsoluteSize` and `AutomaticSize` aren't kept up to date while an object is hidden (a 2021 fix, flag `UpdateAutomaticSizeWhenSetVisible`, updates them when it's shown again) [search snippets of DevForum threads "AutomaticSize not updating when object is set to be visible" and "AbsoluteSize property not updating upon window resizing"]. `TextService:GetTextSize` (`Enum.Font` only) and `GetTextBoundsAsync` (yields) honour the player's Text Size setting, `GuiService.PreferredTextSize`, and so do automatically sized labels [CD GuiService.yaml]. So the status pills are measured from their text, the way the bubbles are.
- **Fonts load late:** DevForum bug reports (search snippets) say some fonts take 10–15 s to load after joining, Gotham and Montserrat among them. Until then `TextBounds` is a stand-in font's, and nothing fires when the real font arrives ["Fonts now have a 10-15s loading time, breaking early TextBounds references"; "It is difficult to get the size of text when font assets need to load"]. `TextService:GetTextBoundsAsync` yields "because some fonts may need to be loaded in order to measure them. … If the font is already loaded, it will not yield; `ContentProvider:PreloadAsync()` can be used to make sure a font is loaded" [CD TextService.yaml]. Roblox's newer UI library (Foundation) measures with `GetTextBoundsAsync` and measures again when the Text Size setting changes [RCT Foundation `useTextSize.lua`, `getTextBoundsAsync.lua`]. So: preload the font, and measure again once it's in and whenever `GuiService.PreferredTextSize` changes.
- **Wrapping:** with `TextWrapped`, lines break at spaces, and a word wider than the label is broken across lines [search snippets of the TextLabel docs and DevForum]. A 20-character display name of W's is 360 px in Montserrat Medium 16: wider than a 300 px chat bubble.
- **Real widths:** every face the game draws text in ships with the client in `content/fonts`: Builder Sans Regular, Medium, Bold and ExtraBold (`.otf`); Montserrat Regular, Medium, Bold and Black; Fredoka One; Oswald Regular and Bold; Special Elite [Studio content mirror, `content/fonts/families/*.json` and the files they name]. `tests/sim/fonts.json` holds each character's width from them (`tests/sim/gen_fonts.py`). Adding them up agrees with Chromium's measurements of the same fonts to within a few percent, not exactly: kerning makes some strings narrower (up to about 3.6%, "AVA WATTERSON"), and rounding makes others wider (about 2.9%, "MANIFEST") [fifth review's experiment with Roblox's font files in Chromium]. So the tests want 4% to spare beside text that doesn't wrap. Builder Sans is under Roblox's Builder Font License: free "solely for the purpose of creating, developing, modifying, uploading, and publishing UGC … on the Roblox platform and for digital promotions incorporating such UGC" [CD resources/builder-font-license.md].
- **The player's Text Size setting** (`GuiService.PreferredTextSize`: Medium, Large, Larger, Largest; a four-step slider from Default to Largest in Roblox's settings menu [RCT CoreScripts/Modules/Settings/Pages/GameSettings.lua]) makes Roblox draw text bigger "through the engine's font rendering pipeline" [CD accessibility.md]. It adds a fixed number of pixels: "The scale is currently applied as a fixed offset, so text that is larger by default will scale less relative to smaller text" [search snippet of the DevForum announcement "Introducing Text Scaling Setting [Studio Beta]", August 2025]. `TextService:GetTextSizeOffsetAsync` returns it, "an additive value", and its font and size parameters "currently … do not affect the outcome" [CD TextService.yaml]; the values themselves aren't published anywhere I could reach. The docs' rules [CD accessibility.md]:
  - text a `UITextSizeConstraint` constrains "will **not** shrink below or expand above the set MinTextSize/MaxTextSize, regardless of the player's text size setting";
  - `TextScaled` text isn't scaled by it;
  - elements with `AutomaticSize` grow to fit the bigger text;
  - wrapped text "will wrap to additional lines … within limits of the element's absolute size";
  - `GetTextSize` and `GetTextBoundsAsync` honour it.

  A UITextSizeConstraint overrides rich text's `<font size>` markup, so text with sized runs can't be held without distorting them [search snippet of the DevForum thread "New preferred text size setting makes it impossible to have text objects using RichText without TextScaled enabled that aren't affected by the setting"]. The setting reached players abruptly, and developers asked for it to be reverted [DevForum "Preferred Text Scaling needs to be Reverted", via the fifth review]. For this game: text meant for reading wraps or grows its box; text in a box that can't grow is held at its size (`Ui.holdTextSize`); and the simulator guesses 0, 2, 4 and 8 px for Medium to Largest.
- **TVs:** `GuiService:IsTenFootInterface()` "is hardcoded to return `true` whenever the client runs on a console … making it an unreliable proxy for rendering context"; read `GuiService.ViewportDisplaySize` instead: `Small` (most phones and tablets), `Medium` (most laptops and monitors), `Large` (most TVs or larger) [CD GuiService.yaml, enums/DisplaySize.yaml].
- **The player list** is open by default on a computer, anchored to the top right just under the row, at `(1, -4, 0, 62)`, about 288 px wide with one stat: over the top right of the safe area [RCT PlayerList/PlayerListController.lua, PlayerListInitialVisibleState.lua]. On phones it's hidden until opened, as a centred panel. It's toggled from the unibar's menu or Tab.
- **`SetCore("SendNotification")` toasts** stack in a 200 px column at the bottom right, which on a phone is where the jump button is [RCT CoreScripts/NotificationScript2.lua]; `GuiService:SendNotification` is documented but reported as not yet enabled.

### 5.6 Official UI and UX guidance

[CD production/game-design/ui-ux-design.md; production/game-design/design-for-roblox.md; production/publishing/accessibility.md]
- Prioritise a clear hierarchy. Direct attention through colour, size, space, proximity and movement. Keep a consistent visual language.
- Follow platform conventions: X to close, grey = disabled, a lock icon for locked, "E" for ProximityPrompt interactions.
- Design mobile-first and avoid colliding with core UI (chat, player list, top bar).
- Prefer visuals over text.
- Accessibility: sufficient contrast; don't rely on colour or sound alone; respect `PreferredTransparency`, `PreferredTextSize` and `ReducedMotionEnabled` (code samples in accessibility.md). Minimum touch target: the repo's 44 px note matches common practice.

---

## 6. Built-in content (`rbxasset://`, no network)

`rbxasset://` URLs load from the client's local content folders. The lists below come from the **Studio (Windows) manifest** [RCT rbxManifest.txt; RSW mirror]. Mobile and console clients ship `content/` too, but not necessarily every Studio-only file (cursors, plugin art). Prefer files the runtime itself uses (face, particles, sky, fonts, character sounds, CoreScript UI) and **check anything else on a phone** **[platform coverage unverified]**. The docs: "`rbxasset` points to Roblox's content folder on the user's device", with `rbxasset://textures/face.png` as the example [CD projects/assets/index.md].

### 6.1 Textures

- **Faces and characters:** `rbxasset://textures/face.png` (classic smile).
- **Effects:**
  - `textures/sparkle.png` (32²), `textures/glow.png` (256² starburst), `textures/explosion.png`, `textures/gradient.png`, `textures/whiteCircle.png`, `textures/smallWhiteCircle.png`, `textures/triangle.png`, `textures/shadowblurmask.png`, `textures/noise.dds`, `textures/Blank.png`, `textures/SurfacesDefault.png`.
  - Particles (`rbxasset://textures/particles/…`): `sparkles_main.dds` (the ParticleEmitter default), `sparkles_color.dds`, `smoke_main.dds`, `smoke_color.dds`, `fire_main.dds`, `fire_color.dds`, `fire_alpha.dds`, `fire_sparks_main.dds`, `fire_sparks_color.dds`, `legacy_fire_alpha_color.dds`, `explosion01_*`, `forcefield_*`, `common_alpha.dds`, `SquareParticle.png`.
  - [RCT rbxManifest.txt]
- **Legacy Roblox UI kit** (`rbxasset://textures/ui/…`), useful for a period-authentic "old Roblox" HUD and a console fallback bubble:
  - Chat bubbles: `dialog_white.png` (+`@2x`), `dialog_tail.png` (+`@2x`), `dialog_blue/green/red.png`, `chatBubble_white_notify_bkg.png` (+blue/green/red), `textures/chatBubble_bot_notifyGray_dotDotDot.png` (typing dots).
  - Buttons and panels: `btn_newWhite.png`, `btn_newGrey.png`, `btn_newBlue.png` (+Glow and @2x), `btn_white.png`, `btn_grey.png`, `btn_red.png`, `RoundedRect8px.png`, `TopRoundedRect8px.png`, `BottomRoundedRect8px.png` (9-slice rounded rects), `Modal.png`.
  - Health, slider, scrollbar and icons: `Health-BKG-*.png`, `Slider-*.png`, `scroll-top/middle/bottom.png`, `CloseButton.png`, `ErrorIcon.png`, `WarningIcon.png`, `Gear.png`, `GuiImagePlaceholder.png`, `TouchControlsSheet.png`, `DPadSheet.png`.
  - Loading: `textures/loading/loadingvignette.png` (256×144) and `darkLoadingTexture.png`.
  - Avoid Roblox brand marks (`robloxlogo.png`, `robloxTilt*.png`, `RobuxIcon.png`, `icon_ROBUX.png`, `TixIcon.png`); using them in our own UI could read as official Roblox UI.
  - [RCT rbxManifest.txt]
- **Modern CoreScript art** in ExtraContent (`rbxasset://textures/ui/…`): the 9-slice chat bubbles `ui/LuaChat/9-slice/chat-bubble.png`, `chat-bubble2.png`, `chat-bubble-tip.png` (+@2x/@3x), `modal.png`, `input-default.png`; the bubble-chat tail `ui/InGameChat/Caret.png`; `ui/LuaApp/graphic/gr-bloom-circle.png`; `ui/LuaApp/graphic/Auth/Vignette.png` [EC textures/ui/…].
- **Sky:** Sky defaults are `SkyboxBk/Dn/Ft/Lf/Rt/Up = rbxasset://textures/sky/sky512_{bk,dn,ft,lf,rt,up}.tex`, `SunTextureId = rbxasset://sky/sun.jpg`, `MoonTextureId = rbxasset://sky/moon.jpg` [API `Sky`]. An alternative set, `textures/sky/indoor512_*.tex`, is in `PlatformContent/pc/…`, and cloud textures are in `content/sky/` [RCT rbxManifest.txt].
- **Materials:** every base `Enum.Material` look ships with the client. Custom `MaterialVariant`s need uploaded textures **[general knowledge]**.

### 6.2 Sounds

- `content/sounds`: `action_falling.ogg`, `action_footsteps_plastic.mp3`, `action_get_up.mp3`, `action_jump.mp3`, `action_jump_land.mp3`, `action_swim.mp3`, `impact_explosion_03.mp3`, `impact_water.mp3`, `oof.ogg`, `ouch.ogg`, `volume_slider.ogg`, all as `rbxasset://sounds/<file>` [RCT rbxManifest.txt]. Listen to `oof.ogg` before using it: the classic "oof" was replaced in 2022 for licensing reasons **[general knowledge]**, so don't assume which one this file is.
- **Roblox character sounds** (`RbxCharacterSounds`, which runs for *player* characters only) [RCT scripts/PlayerScripts/StarterPlayerScriptsCommon/RbxCharacterSounds.lua]:
  - Every sound is created with `Volume 0.65`, `RollOffMinDistance 5`, `RollOffMaxDistance 150`, and parented to the root part.
  - Climbing: `action_footsteps_plastic.mp3`, looped.
  - Died: `rbxasset://sounds/uuhhh.mp3`. This file is not in the Studio manifest.
  - FreeFalling: `action_falling.ogg`, looped. Volume ramps up above 75 studs/s.
  - GettingUp: `action_get_up.mp3`. Jumping: `action_jump.mp3`. Landing: `action_jump_land.mp3` (volume scales with impact).
  - Running: `action_footsteps_plastic.mp3`, looped, `Pitch` (PlaybackSpeed) **1.85**. It plays while velocity > 0.5 and `MoveDirection.Magnitude` > 0.5.
  - Splash: `impact_water.mp3`. Swimming: `action_swim.mp3`, looped, Pitch 1.6.
  - With `SoundService.CharacterSoundsUseNewApi` enabled, the same data drives `AudioPlayer`s.
  - For **NPC footsteps**, copy this recipe: a looped `Sound` under the NPC root, playing only while it moves. Note `Sound` defaults are `Volume` 0.5, `RollOffMinDistance` 10, `RollOffMaxDistance` 10000, `RollOffMode` Inverse [API `Sound`].

### 6.3 Fonts and avatar files

- Fonts: `rbxasset://fonts/families/<Name>.json` (5.1).
- Avatar reference files (not directly loadable as assets by scripts, but useful as numeric references): `content/avatar/character.rbxm`, `characterR15.rbxm`, `characterR15DynamicHeadV2.rbxm`, `morpherEditorR6.rbxmx`, `morpherEditorR15.rbxmx`, `defaultShirt.rbxm`, `defaultPants.rbxm`, `animations/*`, `scripts/*` [RSW content/avatar/].

---

## 7. Lighting and post-processing

### 7.1 `Lighting` properties (engine defaults from API; doc conflicts noted)

| Property | Default | Notes |
|---|---|---|
| `LightingStyle` | Realistic | `Soft` "produces a flat, retro-Roblox look with softer lights and shadows" [CD environment/lighting.md] |
| `PrioritizeLightingQuality` | true | true = keep shadows and shading quality as quality drops, false = keep view distance |
| `Technology` | Compatibility | **Deprecated**, read/write RobloxScriptSecurity, "only modifiable in Studio". Superseded by LightingStyle + PrioritizeLightingQuality [CD reference/engine/classes/Lighting.yaml]. Values: Voxel, Compatibility, ShadowMap, Future (Legacy and Unified are themselves deprecated) [API] |
| `Ambient` | 0.5,0.5,0.5 (API) | docs say black 0,0,0. Set it explicitly |
| `OutdoorAmbient` | 0.5,0.5,0.5 | |
| `Brightness` | 1 | |
| `ClockTime` / `TimeOfDay` | 14 / "14:00:00" | |
| `GeographicLatitude` | 41.7333 | |
| `GlobalShadows` | false (class default) | Studio's place templates usually turn it on **[unverified]**. Set it explicitly |
| `ShadowSoftness` | 0.5 (API) | docs say 0.2. It "is only valid when LightingStyle is set to Realistic" [CD environment/lighting.md] |
| `EnvironmentDiffuseScale` / `EnvironmentSpecularScale` | 0 / 0 | |
| `ExposureCompensation` | 0 | range −5…5 |
| `ColorShift_Top` / `ColorShift_Bottom` | black | |
| `FogColor` / `FogStart` / `FogEnd` | 0.75 grey / 0 / 100000 | "Fog properties are hidden when Lighting contains an Atmosphere object" [CD reference/engine/classes/Atmosphere.yaml] |
| `Outlines` | true | deprecated |

### 7.2 Effects (defaults from API)

Effects under **Lighting** apply to everyone. Under **Camera** they are per-player (client) [CD environment/post-processing-effects.md].

- **`ColorGradingEffect`**: `TonemapperPreset` Default / **Retro**. Retro "imitate[s] the pre‑2019 Roblox appearance. Colors look less saturated and there's less contrast". Advice: "to recreate a full pre‑2019 Roblox look … experiment with Retro and set the brightness of all lights to a maximum of 1.0". It must be parented to Lighting, and only the most recently parented one applies [CD environment/post-processing-effects.md; reference/engine/classes/ColorGradingEffect.yaml].
- `ColorCorrectionEffect`: `Brightness` 0, `Contrast` 0, `Saturation` 0, `TintColor` white.
- `BloomEffect`: `Intensity` 0.4, `Size` 24, `Threshold` 0.95.
- `SunRaysEffect`: `Intensity` 0.25, `Spread` 1.
- `DepthOfFieldEffect`: `FarIntensity` 0.75, `FocusDistance` 0.05, `InFocusRadius` 10, `NearIntensity` 0.75.
- `BlurEffect`: `Size` 24.
- **`Atmosphere`**: `Color` 200,170,108, `Decay` 92,60,14, `Density` 0.395, `Glare` 0, `Haze` 0, `Offset` 0. Glare needs Haze > 0; Decay needs Haze and Glare > 0 [API; CD environment/atmosphere.md].
- **`Sky`**: `CelestialBodiesShown` true, `MoonAngularSize` 11, `SunAngularSize` 21, `StarCount` 3000, `SkyboxOrientation` 0,0,0, plus the default textures in 6.1 [API].
- **`Clouds`** (parent to `Terrain`): `Color` white, `Cover` 0.5, `Density` 0.7, `Enabled` true [API; CD environment/clouds.md].
- **Terrain water**: `WaterColor` 0.05,0.33,0.36, `WaterReflectance` 1, `WaterTransparency` 0.3, `WaterWaveSize` 0.15, `WaterWaveSpeed` 10 [API `Terrain`].

### 7.3 "Roblox look" starting points (taste, not engine facts)

- **Retro Roblox (2008–2018 feel):** `LightingStyle = Soft`, `ColorGradingEffect.TonemapperPreset = Retro`, every light's `Brightness` ≤ 1, `Brightness` 1–2, `OutdoorAmbient` mid-grey, `EnvironmentDiffuseScale` and `EnvironmentSpecularScale` near 0, no Bloom or SunRays. Materials Plastic and SmoothPlastic, default Sky.
- **Modern Roblox horror:** `LightingStyle = Realistic` (the repo's current setting), `ShadowSoftness` 0.2–0.5, `Atmosphere` with `Haze` 1–3 for sea fog, a slight `ColorCorrection` desaturation, `Bloom` Intensity ~0.3. Keep `PrioritizeLightingQuality = true` so the lamp-lit booth keeps its shadows on low-end phones.
- The repo's `"Technology": "Future"` in `default.project.json` is a deprecated property (still serialized). Prefer `LightingStyle` + `PrioritizeLightingQuality` [CD Lighting.yaml].

---

## 8. Everything else

### 8.1 `ProximityPrompt` (the Roblox-native interaction UI)

- Defaults [API]: `ActionText` "Interact", `ObjectText` "", `KeyboardKeyCode` E, `GamepadKeyCode` ButtonX, `HoldDuration` 0, `MaxActivationDistance` 10 (from the player's **character**), `MaxIndicatorDistance` 0, `RequiresLineOfSight` true, `ClickablePrompt` true, `Exclusivity` OnePerButton, `Style` Default (Custom = draw your own UI in `PromptShown`/`PromptHidden`), `UIOffset` 0,0, `Enabled` true, `AutoLocalize` true.
- Events: `Triggered`, `TriggerEnded`, `PromptButtonHoldBegan`/`Ended`, `PromptShown(inputType)`, `PromptHidden`, `IndicatorShown`/`Hidden`.
- The "E" prompt is a recognised platform convention [CD production/game-design/ui-ux-design.md]. It needs a local character (4.1).

### 8.2 `BillboardGui` / `SurfaceGui`

- `BillboardGui` defaults [API]: `AlwaysOnTop` false, `LightInfluence` 0, `Brightness` 1, `MaxDistance` INF, `Size` 0 (set it!), `SizeOffset`, `StudsOffset`, `StudsOffsetWorldSpace`, `ExtentsOffset(WorldSpace)`, `PlayerToHideFrom`, `ClipsDescendants` false, `Active` false. `DistanceLowerLimit`/`UpperLimit` are deprecated.
- `SurfaceGui` defaults: `AlwaysOnTop` false, `LightInfluence` 0, `Brightness` 1, `PixelsPerStud` 50, `SizingMode` FixedSize. `MaxDistance` is **0 in the API dump** (0 = "no limit"), while the docs say "the default value of 1000 works fine for most cases" [API; CD reference/engine/classes/SurfaceGui.yaml]. Set it explicitly.
- Buttons inside a BillboardGui or SurfaceGui "will only receive user input if they are parented to the player's PlayerGui". Put the gui in StarterGui/PlayerGui with `Adornee` set. For a SurfaceGui, "the part's CanQuery property must be true" [CD ui/in-experience-containers.md].

### 8.3 `Highlight`

- Defaults [API]: `DepthMode` AlwaysOnTop (Occluded), `FillColor` red, `FillTransparency` 0.5, `OutlineColor` white, `OutlineTransparency` 0, `Enabled` true, `Adornee`.
- Limits and costs [CD effects/highlighting.md]:
  - At most **255** simultaneous highlights. A disabled one still takes a slot.
  - The **first highlight on screen costs up to ~1 ms of GPU on mobile**; later ones are cheap.
  - On mobile, cost grows with screen coverage.
  - Invisible highlights cost nothing.

### 8.4 Performance for ~10 NPCs on phones

- Anchor static or scripted NPCs [CD performance-optimization/improve.md]. Keep `Humanoid.EvaluateStateMachine = false`, or disable unused states [same; CD Humanoid.yaml].
- Animate on the client with `Motor6D.Transform` (not C0/C1). Only animate NPCs near the camera. Pool NPC models instead of destroying and rebuilding them [CD performance-optimization/improve.md].
- **Don't tween NPC CFrames on the server**: that replicates every frame and jitters. Tween or interpolate on the client [same].
- Turn `CastShadow` off on small decorative parts (buttons, glasses, straps), especially far from the camera [same]. Keep `CanTouch`/`CanQuery`/`CanCollide` off on cosmetic parts (the repo already does).
- An R6 body is 7 parts. With 10–25 decorative parts per passenger, 10 passengers are about 170–320 parts: trivial. The costly items are Highlights (the first one), full-screen CanvasGroups, and many shadow-casting lights.
- `Workspace.EnableSLIMAvatars` (streaming) gives distant *platform avatars* lightweight representations. It is irrelevant for Part NPCs [CD performance-optimization/improve.md].

### 8.5 Headless tests (Lune) considerations

- Everything in the Part-built path uses `Instance.new` + properties and is testable in Lune. That covers rigs, attachments, Motor6Ds, pose maths, bubble config and styling rules.
- The following don't exist in Lune: engine behaviours (Humanoid state machine, Animator, `CreateHumanoidModelFromDescriptionAsync`, rendering of `DisplayBubble`, StyleSheet resolution). Keep them behind thin adapters.
- The repo simulator already enforces "DisplayBubble can only be called from the client" [REPO games/last-ferry/tests/sim/Roblox.luau l.1159–1166].
- Lune's `CFrame.lookAt` faces the opposite way to Roblox's. The repo simulator patches it [same, l.30–40].

---

## 9. Observations on the current Last Ferry code (read-only review)

- `Robloxian.luau` builds R6 exactly to Roblox's stock numbers: part sizes, the head mesh with Scale 1.25, the `face` decal, and all six Motor6D C0/C1 values match 1.2.
  - Differences from stock: `Material = SmoothPlastic` (stock rigs are **Plastic**), no attachments (fine unless we adopt Accessories), and `Head` Scale kept at 1.25 while part sizes scale by `s` (check the head at extreme heights, 1.3).
  - [REPO games/last-ferry/ServerScriptService/Services/Robloxian.luau l.331–433]
- `CrowdController.luau` animates with `Motor6D.Transform` in `PreSimulation` on the client, which is the documented best practice. Its sign conventions match 2.3 [REPO games/last-ferry/ReplicatedStorage/Controllers/CrowdController.luau].
- `PassengerService.luau` moves passengers with **server-side `TweenService` on the root CFrame**. The docs flag this as jittery and bandwidth-heavy [CD performance-optimization/improve.md]. Consider replicating a path + start time and tweening on each client (2.7) [REPO games/last-ferry/ServerScriptService/Services/PassengerService.luau l.243–246].
- `default.project.json` sets `Lighting.Technology = "Future"` (deprecated) and `LightingStyle = "Realistic"`. For a "Roblox look" pass, try `Soft` + `ColorGradingEffect` Retro (7.3). Also add `TextChatService.ChatVersion = "TextChatService"` so NPC bubbles can't be broken by an old place file (3.4).
- Theme fonts (Oswald, BuilderSans(+Bold), SpecialElite, Merriweather, RobotoMono) all have locally shipped Regular faces, and Bold where used. Nothing waits on a cloud download [REPO games/last-ferry/ReplicatedStorage/Ui/Theme.luau; 5.1].

---

## Appendix A. Source index

- **API dump:** https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Full-API-Dump.json (0.741.19.7411056). Queried with a small Python helper (not kept).
- **Creator docs source:** https://github.com/Roblox/creator-docs (commit 1466521). Main pages used:
  - Reference classes: HumanoidDescription, Players, Player, Humanoid, Motor6D, AnimationConstraint, Animator, KeyframeSequenceProvider, AnimationClipProvider, StarterPlayer, Seat, SpawnLocation, TextChatService, BubbleChatConfiguration, Chat, Dialog, Lighting, ColorGradingEffect, Atmosphere, BasePart, Accessory, AccessoryDescription, BodyPartDescription, AvatarEditorService, Shirt, Pants, ShirtGraphic, BodyColors, CharacterMesh, SpecialMesh, DataModelMesh, Weld, GuiService, StarterGui, StyleRule, UIShadow, UIStroke, EditableImage, Workspace, ProximityPrompt, ClickDetector.
  - Reference enums: AssetTypeVerification, Font, MeshType, HumanoidStateType, DevComputerMovementMode, DevTouchMovementMode.
  - Datatypes: Font.
  - Guides: `characters/name-health-display.md`, `characters/r6-to-r15-adapter.md`, `animation/using.md`, `chat/bubble-chat.md`, `chat/guidelines.md`, `chat/in-experience-text-chat.md`, `ui/text-filtering.md`, `ui/appearance-modifiers.md`, `ui/size-modifiers.md`, `ui/list-flex-layouts.md`, `ui/9-slice.md`, `ui/on-screen-containers.md`, `ui/in-experience-containers.md`, `ui/ui-drag-detectors.md`, `ui/styling/index.md`, `includes/ui/screen-insets.md`, `includes/studio/playtest-modes.md`, `workspace/camera/index.md`, `environment/lighting.md`, `environment/post-processing-effects.md`, `environment/atmosphere.md`, `environment/clouds.md`, `effects/highlighting.md`, `performance-optimization/improve.md`, `physics/network-ownership.md`, `production/game-design/ui-ux-design.md`, `production/game-design/design-for-roblox.md`, `production/publishing/accessibility.md`, `production/publishing/adaptive-design.md`, `projects/assets/index.md`, `studio/avatar-settings.md`, `avatar/rigid-accessories/specifications.md`, `avatar/in-experience-creation.md`, `resources/builder-font-license.md`.
- **Client tracker** (https://github.com/MaximumADHD/Roblox-Client-Tracker/tree/roblox):
  - Avatar scripts: `avatar/scripts/humanoidAnimateR15.lua`, `avatar/unification/humanoidAnimateR6WithFace/init.client.lua`, `avatar/unification/humanoidClassicAnimate.lua`, `avatar/scripts/humanoidHealthRegenScript.server.lua`.
  - Player scripts: `scripts/PlayerScripts/StarterPlayerScriptsCommon/RbxCharacterSounds.lua`, `scripts/PlayerScripts/StarterPlayerScripts/PlayerModule.module.lua` (+`/ControlModule.lua`), `scripts/PlayerScripts/StarterPlayer/PlayerModule/init.lua`.
  - CoreScripts: `scripts/CoreScripts/CoreScripts/ExperienceChatMain.lua`, `scripts/CoreScripts/Modules/InspectAndBuy/CharacterModelPool.lua`, `scripts/CoreScripts/Modules/AvatarEditorPrompts/Components/HumanoidViewport.lua`, `scripts/CoreScripts/Modules/TopBar/Constants.lua`.
  - Build metadata: `rbxManifest.txt`, `FVariables.txt`.
- **Studio content mirror** (https://github.com/suscersal/roblox-studio-web): `content/avatar/character.rbxm`, `characterR15.rbxm`, `characterR15DynamicHeadV2.rbxm`, `defaultDynamicHead.rbxm`, `morpherEditorR6.rbxmx`, `defaultShirt.rbxm`, `defaultPants.rbxm`, `animations/humanoidR6AnimateChildren.rbxm` (+ R15 children), `content/fonts/families/*.json`.
- **ExtraContent** (https://github.com/diamond3500/ExtraContent), ExperienceChat package `LuaPackages/Packages/_Index/ExperienceChat-567b090e-58d00f83/ExperienceChat/`:
  - `mountClientApp/init.lua`, `App.lua`, `AppContainer/AppContainer.lua`.
  - `installReducer/Messages.lua`, `installReducer/BubbleChat/LegacySettings.lua`.
  - `BubbleChat/BillboardGui/BillboardGui.lua`, `BubbleChat/ChatBubble/ChatBubble.lua`, `BubbleChat/BubbleChatApp/BubbleChatApp.lua`.
  - Also the `textures/ui/…` files.

