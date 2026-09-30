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
| `ServerScriptService/Services/PassengerService.luau` | Dresses a Robloxian for each passenger and adds the visible tells from their facts: breath emitter; drips from cuffs and hem, a wide puddle, footprints; pale skin and seaweed; CastShadow plus a shadow mark on the planks. Walks and vanishes them |
| `ServerScriptService/Services/CrewService.luau` | The players' own avatars: the pier between shifts, the time clock's "Clock in" prompt, a stand each in the booth, the clerk's cap (their own hats hidden under it), late joiners, clocking out |
| `ServerScriptService/Services/ShiftService.luau` | The Roblox `Stage` for the Director (queue on the dock, remotes, world calls) and the action handler |
| `ServerScriptService/Services/ProgressService.luau` | Endings found per player (DataStore), badges, and the player list's `leaderstats` (Endings, Shifts) |
| `ReplicatedStorage/Shared/Config.luau` | Remote names and tunables both sides read (timers, walk speed, rate limits) |
| `ReplicatedStorage/Shared/Net.luau` | Creates and finds RemoteEvents; per-player rate limiter |
| `ReplicatedStorage/Shared/Types.luau` | The screen state, effects and progress payloads the server sends |
| `ReplicatedStorage/Client.client.luau` | Client entry: starts the effects, camera, crowd and HUD controllers |
| `ReplicatedStorage/Controllers/CameraController.luau` | Roblox's own cameras: Classic on the pier, LockFirstPerson on shift (one eye height for every avatar, lean in by field of view, shake, both through `Humanoid.CameraOffset`), Scriptable views of the flood and the endings |
| `ReplicatedStorage/Controllers/CrowdController.luau` | Animates passengers on each client: the classic Roblox walk, idle sway and look-about, via `Motor6D.Transform` in `PreSimulation` |
| `ReplicatedStorage/Controllers/EffectsController.luau` | Blur behind cards, flood tint, lantern-out pulse, client-side lighthouse spin |
| `ReplicatedStorage/Controllers/HudController.luau` | The whole HUD and its wiring to the remotes: the lobby banner on the pier, the shift HUD, passengers' lines as chat bubbles and chat-log lines, `ContextActionService` shortcuts that give way to Roblox's controls, the Modal button that frees the mouse in first person |
| `ReplicatedStorage/Ui/Theme.luau` | Colours and fonts in Roblox's chunky house style (Fredoka One titles, Builder Sans ExtraBold controls, Special Elite and Oswald only on paper), design canvas and scale limits |
| `ReplicatedStorage/Ui/Ui.luau` | Typed UI builders: frames, labels, layout, text strokes, hard shadows (`UIShadow`), gloss, drawn icons (check, cross, play, bang, page) and chunky buttons that squash and spring back |
| `ReplicatedStorage/Ui/Widgets.luau` | Shared pieces: captions, paragraphs, tags, rule rows with number badges, lantern icons, text outlines |
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

If `playRun` throws, ShiftService logs the traceback, clears the queue and
sends everyone back to the pier, so a bug can't leave players stuck in a frozen
booth.

Players who join (or respawn) mid-shift appear in the booth (`BoothSpawn`) and
CrewService puts them at a free stand. A player's `OnShift` attribute tells
their client which camera to use.

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

Passengers' lines are shown by each client with `TextChatService:DisplayBubble`
on the passenger's model (Roblox's own chat bubble) and logged to the chat
window as a system message.

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
| Booth view | First person from each clerk's stand, the eye held at y = 5.1 for every avatar. The front stand's view matches the old fixed camera `CameraAnchor` at (0, 5.1, 3.4), which cinematic views and previews still use: the sill hides the planks closer than z ≈ −4.1, and a passenger's body hides the planks straight behind them |
| Stands | Feet at (0, 0.2, 2.7) (front), (±2.8, 0.2, 3), (0, 0.2, 5.4), (±2.8, 0.2, 5.8), all facing the window |
| Pier | Behind the booth, z 8 to 46; railings and invisible walls keep players on it. `PierSpawn` at (0, 0, 30) faces the booth; the notice board at (−7.5, 3.9, 12) faces the spawn |
| Booth door and time clock | The back wall's door (hinge at (−1.3, 3.45, 8)) opens onto the pier between shifts and shuts for one. The time clock is right of it on the pier side, (2.7, 3.9, 8.4); its `ClockIn` prompt (hold E, 9 studs) is up only between shifts. Walls, glass, counter and roof are solid |
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
  characters and spawns, accessories, ProximityPrompts, ContextActionService.
- `tests/Passenger.spec.luau`: passengers look the same whatever their kind;
  the tells come from their facts.
- `tests/Game.spec.luau`: the real server and client scripts in
  `tests/sim/Roblox.luau`, a mock engine checked against
  `tests/sim/reflection.json`. A bot spawns on the pier, clocks in at the
  time clock and plays from the HUD.

When the game starts using a Roblox class or method the simulator doesn't know:

1. Add the class to `CLASSES` in `tests/sim/gen_reflection.py`.
2. Rerun the script with a fresh API dump.
3. Add the method to `tests/sim/Roblox.luau`.

The simulator doesn't render, has no physics, and snaps tweens to their end
values. It proves logic and wiring, not looks.
