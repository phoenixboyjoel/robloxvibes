# Architecture: Last Ferry

Update this file in the same change as any code that adds, moves or removes
something.

## Shape

- **The server decides everything.** The client draws the screen state it is
  sent and sends back button presses. It never learns which passengers are
  drowned.
- **One server Script** (`ServerScriptService/Server.server.luau`) and **one
  client Script** (`ReplicatedStorage/Client.client.luau`, RunContext Client).
  Everything else is a ModuleScript.
- **Pure logic has no Roblox APIs.** `ServerScriptService/Shift/` holds the
  rules, the queue generator, the run state machine and the shift director.
  Lune tests them directly. They live on the server, so players can't datamine
  later nights, the ledger or the endings.
- **The world is code.** `WorldService` builds the harbor from parts when the
  server starts, so git holds everything and the place file is a build output
  (`rojo build`).
- **The server says where things go; each client moves them.** A part the
  server moves with TweenService stutters on players' screens and costs a
  replication every frame, so nothing moving is tweened on the server.
  Passengers, the *Petrel*, the *Marigold*, the booth door and the flood are
  glided (`Shared/Glide`): the server writes each move once, as attributes, and
  every client moves the thing smoothly itself (`GlideController`). The
  lighthouse beam and the passengers' limbs are animated on each client too.

## Files

| Path | What it does |
| --- | --- |
| `ServerScriptService/Server.server.luau` | Server entry: builds the world, starts progress, the crew (players' avatars) and the shift |
| `ServerScriptService/Shift/Content.luau` | All story text and tuning: rules, nights, names, lines, Mara, the ledger, endings, notes |
| `ServerScriptService/Shift/Types.luau` | Shapes of passengers, tickets, nights, outcomes |
| `ServerScriptService/Shift/Rng.luau` | Seeded Park–Miller RNG, so runs and retries are reproducible in tests |
| `ServerScriptService/Shift/Rules.luau` | Which rules are active, the rules card, and `broken(passenger, night)` from visible facts only |
| `ServerScriptService/Shift/Generator.luau` | Builds each night's queue under the fairness guarantees (see its header) |
| `ServerScriptService/Shift/Run.luau` | Five-night run state: lanterns, decisions, retries, ledger pages, ending |
| `ServerScriptService/Shift/Director.luau` | The shift itself: phases, timers, Continue, player actions. Talks to the world only through a `Stage` and waits only through a `Clock` |
| `ServerScriptService/Services/WorldService.luau` | Builds Gull Harbor: dock, booth (door, time clock and its prompt, spawns), the pier behind it, lamp, lanterns, ferry, lighthouse, the *Marigold*, flood; exposes path markers and scene effects |
| `ServerScriptService/Services/Robloxian.luau` | Builds a classic R6 Robloxian from parts to Roblox's own rig numbers (GenerateDummy, the stock R6 morph), dressed from a `Look`: outfits, skins, hair, hats, scarves, bags, faces. No assets |
| `ServerScriptService/Services/PassengerService.luau` | Dresses a Robloxian for each passenger and adds the visible tells from their facts: breath emitter; drips from cuffs and hem, a wide puddle, footprints; pale skin and seaweed; CastShadow plus a shadow mark on the planks. Walks them leg by leg (a glide each, turning into the leg as they set off), sinks and fades them |
| `ServerScriptService/Services/CrewService.luau` | The players' own avatars: the pier between shifts, the time clock's "Clock in" prompt, a stand each in the booth (the `Stand` attribute says which, so the camera can aim from it), the clerk's cap (their own hats hidden under it, sparkles and all), Shift Lock off on shift, late joiners and respawns (placed a frame after they load), a once-a-second check that puts any clerk found outside the booth back at their stand, clocking out |
| `ServerScriptService/Services/ShiftService.luau` | The Roblox `Stage` for the Director (queue on the dock, remotes, world calls) and the action handler |
| `ServerScriptService/Services/ProgressService.luau` | Endings found per player (DataStore), badges, and the player list's `leaderstats` (Endings, Shifts) |
| `ReplicatedStorage/Shared/Config.luau` | Remote names and tunables both sides read (timers, walk speed, rate limits) |
| `ReplicatedStorage/Shared/Net.luau` | Creates and finds RemoteEvents; per-player rate limiter; `serverTime()`, the server's clock, or nil while the client has lost its connection (when Roblox's `GetServerTimeNow` throws) |
| `ReplicatedStorage/Shared/Types.luau` | The screen state, effects and progress payloads the server sends |
| `ReplicatedStorage/Shared/Sounds.luau` | Every sound in the game, all Roblox built-ins (`rbxasset://sounds/`): footsteps, splash, slosh, thud, click, gust |
| `ReplicatedStorage/Shared/Glide.luau` | Smooth movement. The server's side: `start` (from where it is now to a target, eased, optionally turning first), `frame` (where it has got to), `stop`, `set`, and `spread` (a part growing, like a wet passenger's puddle; full size on the server at once). It writes the glide as attributes (`GlideFrom`, `GlideTo`, `GlideStart` in server time, `GlideTime`, `GlideStyle`, `GlideDirection`, `GlideTurn`, then `GlideId`) and the `Glide` tag, and moves the server's copy only at the start and the end. The shared maths: `sample`, `read`, `lag`, `lagFor` (a glide that carries straight on from the last, like the next leg of a walk, keeps its lag so the legs join up), `spreadSize` |
| `ReplicatedStorage/Client.client.luau` | Client entry: starts the glide, effects, camera, crowd and HUD controllers |
| `ReplicatedStorage/Controllers/CameraController.luau` | Roblox's own cameras: Classic on the pier, LockFirstPerson on shift (one eye height for every avatar, lean in by field of view, shake, both through `Humanoid.CameraOffset`), Scriptable views of the flood and the endings. At the start of every night each clerk's view turns to the face of the passenger at the window (0, 4.4, −4), aimed from their own stand (their `Stand` attribute) at the booth's eye height, so it's right even before CrewService has moved them there. Other clerks between you and the window turn see-through on your screen (`LocalTransparencyModifier`); a respawn mid-shift faces the window again, unless the view is on the flood or an ending; a pinch with a finger on the thumbstick isn't a lean |
| `ReplicatedStorage/Controllers/CrowdController.luau` | Animates passengers on each client: the classic Roblox walk, idle sway and look-about, via `Motor6D.Transform` in `PreSimulation`, with Roblox's plastic footsteps while they walk |
| `ReplicatedStorage/Controllers/GlideController.luau` | Moves everything tagged `Glide` on this client every frame, before the camera (render priority First). A glide is played from when it arrives, as far behind the server as the network is, so it's seen whole and lines up with the server's own moves; one more than half a second late (a player who has just joined) is joined where it has got to. A glide that carries straight on from the last keeps that one's lag, so a walk's legs join with no skip or pause. For a second after a glide ends it holds the thing at the end, so a late move from the server can't leave it elsewhere. It also grows everything tagged `Spread` |
| `ReplicatedStorage/Controllers/EffectsController.luau` | Blur behind cards, flood tint, lantern-out pulse, client-side lighthouse spin |
| `ReplicatedStorage/Controllers/HudController.luau` | The whole HUD and its wiring to the remotes: the lobby banner on the pier, the shift HUD (the status up in Roblox's top bar row, `Ui/TopBar`; the desk and the rules panel under it), passengers' lines as speech bubbles (`Ui/Speech`) kept to the room the HUD leaves them, and chat-log lines, `ContextActionService` shortcuts that give way to Roblox's controls, the Modal button that frees the mouse in first person, and Roblox's player list put away on shift (on a computer it's open over the top right, where the rules panel is) and back on the pier |
| `ReplicatedStorage/Ui/Theme.luau` | Colours and fonts in Roblox's chunky house style (Fredoka One titles, Builder Sans ExtraBold controls, Special Elite and Oswald only on paper), design canvas and scale limits |
| `ReplicatedStorage/Ui/Ui.luau` | Typed UI builders: frames, labels, layout, text strokes, hard shadows (`UIShadow`), gloss, drawn icons (check, cross, play, bang, page) and chunky buttons that squash and spring back |
| `ReplicatedStorage/Ui/Widgets.luau` | Shared pieces: captions, paragraphs, tags, rule rows with number badges, lantern icons, text outlines |
| `ReplicatedStorage/Ui/Sfx.luau` | Sounds only this player hears (clicks, the stamp, a lantern's gust), made in SoundService on the client |
| `ReplicatedStorage/Ui/Speech.luau` | What the passenger at the window says, drawn exactly like Roblox's chat bubble (Gotham SSm Medium 16, white, rounded, Roblox's tail) and sized from its measured text as Roblox sizes its own, on its own ScreenGui (`LastFerrySpeech`, DisplayOrder 7) over the HUD. Every frame, once the camera has moved, it goes over their head and then moves to stay in the room the HUD leaves it: along or up as far as it takes, down only until its tail touches the top of their head (`Speech.place`). Where the camera draws their head comes from `WorldToScreenPoint`, which is in the same coordinates as `AbsolutePosition` (so it's right on a notched phone too, where viewport coordinates aren't); the bubble's layer covers the whole screen, so it takes off where the layer starts. The room can have obstacles lower down (the page tab): it keeps to one side of one only if it would otherwise cover it. It stays up for the whole window and works where Roblox's chat doesn't (consoles, with bigger text) |
| `ReplicatedStorage/Ui/TopBar.luau` | The shift's status in Roblox's own top bar row (`ScreenInsets.TopbarSafeInsets`, beside Roblox's buttons), as pills like Roblox's: night, clock and date; ledger, queue and lanterns; a lost lantern or a found page as a banner across the row. It scales with the row (up on a TV) and fits whatever room Roblox's buttons leave, dropping the date, then the queue, the word LEDGER and the clock. With no row tall enough, or none wide enough for the pills that always show (the night, the ledger's icon and page count, the lanterns), it sits at the top of the HUD instead. The pills are measured from their text, the way Roblox measures its chat bubbles (a label in a ScreenGui that's never shown), not from their own sizes: Roblox doesn't keep what's hidden laid out |
| `ReplicatedStorage/Ui/Ticket.luau` | The ticket card, its drawn stamps, the torn-page tab, the BOARDED / TURNED AWAY stamp |
| `ReplicatedStorage/Ui/Overlay.luau` | Intro, summary, tide-came-in and ending cards, with the co-op Continue |
| `tests/` | Lune test suite (`lune run tests/run.luau`) and the headless simulator in `tests/sim/` |
| `tools/preview/` | Exports a scenario from the simulator and renders it like Roblox with three.js (see its README) |

## How a run flows

```
Server.server.luau
  WorldService.build()         harbor, lighting, water, booth, pier; returns path markers
  ProgressService.start()      DataStore, badges, Progress remote
  CrewService.start(markers)   players' avatars spawn on the pier
  ShiftService.start(markers)  Stage + Clock for the Director; Action remote handler
    loop forever:
      Director.toLobby            phase "waiting": everyone on the pier as their avatar
      CrewService.waitForClockIn  someone holds the time clock's prompt
      CrewService.startShift      everyone to a stand in the booth, door shut, caps on
      Director.playRun
        Run.new(seed); Run.beginNight -> Generator.buildNight
        per night:
          intro      hold up to IntroTime, or until everyone presses Continue
          per passenger:
            queue    Stage.callToWindow: walk them up; the queue steps forward
            window   wait up to DecisionTime for board / deny (timeout = deny)
            call     Run.decide -> lanterns, exit path, effects, ferry load
            pause    BetweenPassengers; RadioTime after the midway passenger (Pike's
                     message plays with nobody at the window); LastPassengerTime
                     after the last one (so their exit is seen before the summary)
          if lanterns = 0: failed (flood, FailedTime), Run.restartNight, intro again
          summary    hold up to SummaryTime / Continue
        ending       endingScene, recordEnding, hold up to EndingTime / Continue
      CrewService.endShift        everyone back on the pier, door open, caps off
```

If `playRun` throws, ShiftService logs the traceback, clears the queue, resets
the harbor (no flood left sloshing) and sends everyone back to the pier, so a bug
can't leave players stuck in a frozen booth.

Players who join (or respawn) mid-shift appear in the booth (`BoothSpawn`, in
the back corner) and CrewService puts them at a free stand once the engine has
finished loading them. A player's `OnShift` attribute tells their client which
camera to use.

## Place settings

The project file sets these on the place, because scripts can't (or shouldn't):

| Setting | Why |
| --- | --- |
| `Workspace.StreamingEnabled = false` | The booth sees the whole harbor |
| `Workspace.SignalBehavior = Deferred` | Event handlers run after what fired them has finished (a character is fully loaded and placed before CrewService moves it). A place left on Default runs them immediately for now. The simulator only runs them deferred and refuses a project without it |
| `Workspace.PlayerScriptsUseInputActionSystem = Disabled` | Keeps Roblox's controls on ContextActionService, where the HUD's High-priority bindings take gamepad A and Space before jump. The simulator refuses a project without it |
| `Lighting.LightingStyle = Realistic`, `PrioritizeLightingQuality` | Crisp local-light shadows, which the shadow rule needs |
| `Players.CharacterAutoLoads = true` | Players are their own avatars |
| `StarterPlayer.CameraMaxZoomDistance = 25` | A close third-person camera on the pier |
| `TextChatService.ChatVersion = TextChatService` | The chat log for passengers' lines, and friends' bubbles |

`SignalBehavior` and `PlayerScriptsUseInputActionSystem` can't be synced by the
Rojo plugin: a place built with `rojo build` has them, but with `rojo serve` set
them once in Studio's Properties on Workspace.

## Remotes

All live in `ReplicatedStorage.Remotes`, created by the server through `Net`.

| Remote | Direction | Payload |
| --- | --- | --- |
| `ShiftState` | server → clients | `Types.State`: the whole screen, sent on every change |
| `ShiftFx` | server → clients | `Types.Fx`: `call`, `lanternOut`, `say`, `page` (with `by`, the finder's UserId), `radio` |
| `ShiftProgress` | server → one client | `Types.Progress`: titles of endings found |
| `ShiftAction` | client → server | `("board" \| "deny" \| "page", passengerId)`, `("continue")`, `("sync")` |

A player counts as present (for Continue and for clocking in) only after
their client has loaded and sent `sync`, so a slow phone doesn't lose the first
intro's timer.

Passengers' lines are shown by each client in a bubble over the passenger's head
(`Ui/Speech`, drawn like Roblox's own) for the whole window, and logged to the
chat window as a system message. Roblox's `TextChatService:DisplayBubble` isn't
used for them: what they say is a rule on night 5, and Roblox's bubbles fade
after `BubbleDuration`, sit under every ScreenGui (they're BillboardGuis, so the
HUD would cover them), and don't show at all on consoles. The bubble is on its
own layer over the HUD, and the HUD tells it the room it may use: right of the
desk, left of the rules panel (or the ledger, or the RULES button), below
anything at the top, above the hint, and to one side of the ticket's page tab if
it would otherwise cover it. The status is up in
Roblox's top bar row so that on a phone there's room above a passenger's head
for the longest line in the game.

Moving things are glided, not tweened on the server: the server writes each
move once as attributes (see `Shared/Glide`) and every client moves the thing
itself. Once something has glided, move it only with Glide: clients place it by
its latest glide, whatever its CFrame says.

Every action is checked in this order:
1. **Rate limit** (4 a second, bursts of 6).
2. **Whitelist:** the action kind must be one of the known ones.
3. **Director check:** the action has to fit the current phase, and board, deny
   and page must name the passenger at the window.

Anything else is ignored. The screen state holds only what a clerk can see:
- the ticket;
- the passenger's words;
- the rules;
- the manifest;
- ledger pages already taken;
- summaries after the fact.

`tests/Director.spec.luau` fails if any other key appears.

`{name}` in a line is filled in by each client with its own player's display
name, so in co-op each friend sees their own name.

## Saved data

- DataStore `LastFerryProgress_v1`, key `u_<player.User.Id>`, value
  `{ endings = { [endingId] = true }, runs = number }`.
- Saved once per ending with `UpdateAsync`, merging with what's stored: a union
  of endings, and runs + 1. The data only ever grows and nothing is left
  unsaved, so there's no session locking, save-on-leave or BindToClose. Switch
  to ProfileStore (see the starter's AGENTS.md) the moment purchases or anything
  that can decrease are added.
- Studio without API access: saving turns itself off for the session, with one
  warning.

## World layout

Studs; dock surface at y = 0; the booth window faces −Z.

| Thing | Where |
| --- | --- |
| Booth view | First person from each clerk's stand, the eye held at y = 5.1 for every avatar and aimed at the passenger's face, (0, 4.4, −4), at the start of every night. The front stand's view matches the old fixed camera `CameraAnchor` at (0, 5.1, 3.4), which cinematic views and previews still use: the sill hides the planks closer than z ≈ −4.1, and a passenger's body hides the planks straight behind them |
| Stands | Feet at (0, 0.2, 2.7) (front), (±2.8, 0.2, 3), then (±2, 0.2, 5.6), whose line to the window passes between the front clerks' heads, and (0, 0.2, 6.6); all facing the window. `BoothSpawn` is in the back right corner, (3.3, 0.1, 7.1), clear of them all |
| Pier | Behind the booth, z 8 to 46; railings and invisible walls keep players on it. `PierSpawn` at (0, 0, 30) faces the booth; the notice board at (−7.5, 3.9, 12) faces the spawn |
| Booth door and time clock | The back wall's door (hinge at (−1.3, 3.45, 8); the door's `PivotOffset` puts its pivot there, so gliding it swings it on the hinge) opens onto the pier between shifts and slams shut for one, bouncing off the frame. The time clock is right of it on the pier side, (2.7, 3.9, 8.4); its `ClockIn` prompt (hold E, 9 studs) is up only between shifts. Walls, glass, counter and roof are solid, and an invisible `CounterGuard` over the counter, up to the top of the window, stops anyone standing on it in front of the passenger |
| Passenger at the window | (0, 0, −3.2), facing the booth |
| Booth lamp | (−3.4, 8.1, −1.05), aimed at (1.2, 0, −4.6). Shadows fall back and to the right, in view. Lighting is pinned to `LightingStyle = Realistic` and `PrioritizeLightingQuality = true` (project file and `setUpLighting`). Passengers who cast a shadow also get a dark `ShadowMark` part there, for devices that drop local-light shadows |
| Queue slots | (−2, 0, −11), (0.5, 0, −17), (−1.5, 0, −23); spawn in the fog at (−0.5, 0, −50), mid-lane |
| Exits | board: gate (posts at x 5.9 and 10.6, 7 tall) → gangway → the *Petrel*'s deck; away: round the first rope post, left of the rope line into the fog; water: off the dock's left edge at z −31 (about 32° left, in view), then sink |
| *Petrel* | Moored along the dock's right edge, bow into the fog; sits lower for each drowned passenger aboard |
| Lighthouse | (−60, 0, −130); the beam turns on each client while the rotor's `Spinning` attribute is true |

## Tests and the simulator

- `tests/Rng|Rules|Generator|Run.spec.luau`: pure logic. The generator fuzz
  covers 400 seeds × 5 nights.
- `tests/Director.spec.luau`: the shift on a fake Stage and Clock.
- `tests/Sim.spec.luau`: the simulator's own engine behaviour: rigs and joints,
  characters and spawns, accessories, ProximityPrompts, ContextActionService,
  CollectionService tags, easing curves (Bounce too), pivots, attribute types,
  GUI layout (where things are on screen), Roblox's top bar row, and where the
  camera draws a point in each of Roblox's coordinate systems.
- `tests/Glide.spec.luau`: glides are eased, sent once and moved by every
  client every frame; late joiners, changes of course, stops and late server
  moves; a walk's legs joining up; the server's end move with nobody watching;
  spreading parts; models and hinged parts.
- `tests/Speech.spec.luau`: where a speech bubble goes in the room it has.
- `tests/Passenger.spec.luau`: passengers look the same whatever their kind;
  the tells come from their facts.
- `tests/Game.spec.luau`: the real server and client scripts in
  `tests/sim/Roblox.luau`, a mock engine checked against
  `tests/sim/reflection.json`. A bot spawns on the pier, clocks in at the
  time clock and plays from the HUD. It also checks, from every stand and on a
  monitor, a notched phone and an iPhone SE, that the longest line in the game
  sits clear of every piece of the HUD and never over the passenger's face;
  that every stand's view is aimed at the passenger, even straight after a
  respawn; and that the status fits however much of the top bar row Roblox's
  buttons leave, with a page in the ledger too, moving to the HUD only when
  even the pills that always show wouldn't fit.

When the game starts using a Roblox class or method the simulator doesn't know:

1. Add the class to `CLASSES` in `tests/sim/gen_reflection.py`.
2. Rerun the script with a fresh API dump.
3. Add the method to `tests/sim/Roblox.luau`.

The simulator doesn't render, has no physics, and snaps tweens to their end
values. It has one copy of the world, shared by the server and every client,
so a client's glide shows on the server's copy too; `sim:countWrites` tells
who moved what. It lays GUI out as Roblox does (sizes, anchors, padding,
UIScale, list layouts, automatic sizes) for `AbsolutePosition` and
`AbsoluteSize`, but text has no font engine: `TextBounds` is an estimate.
Screens are `Sim.new({ screen, safeArea, topbarInset })`, where the top bar row's
free part defaults to all but Roblox's buttons (`sim:setTopbarInset` changes it,
as when Roblox's chat pill opens); consoles are `Sim.new({ tenFoot = true })`.
Coordinates start where Roblox's do: GUI coordinates (`AbsolutePosition`,
`WorldToScreenPoint`) at the bottom-left of the top bar, at the safe area's left
edge; viewport coordinates (`WorldToViewportPoint`, `ViewportSize`) at the top
bar's top-left. Attribute signals fire only when a value changes, as Roblox's
do. It proves logic, wiring and layout, not looks.
