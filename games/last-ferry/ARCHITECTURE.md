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
| `ServerScriptService/Server.server.luau` | Server entry: turns off avatars, builds the world, starts progress and the shift |
| `ServerScriptService/Shift/Content.luau` | All story text and tuning: rules, nights, names, lines, Mara, the ledger, endings, notes |
| `ServerScriptService/Shift/Types.luau` | Shapes of passengers, tickets, nights, outcomes |
| `ServerScriptService/Shift/Rng.luau` | Seeded Park–Miller RNG, so runs and retries are reproducible in tests |
| `ServerScriptService/Shift/Rules.luau` | Which rules are active, the rules card, and `broken(passenger, night)` from visible facts only |
| `ServerScriptService/Shift/Generator.luau` | Builds each night's queue under the fairness guarantees (see its header) |
| `ServerScriptService/Shift/Run.luau` | Five-night run state: lanterns, decisions, retries, ledger pages, ending |
| `ServerScriptService/Shift/Director.luau` | The shift itself: phases, timers, Continue, player actions. Talks to the world only through a `Stage` and waits only through a `Clock` |
| `ServerScriptService/Services/WorldService.luau` | Builds Gull Harbor: dock, booth, lamp, lanterns, ferry, lighthouse, the *Marigold*, flood; exposes path markers and scene effects |
| `ServerScriptService/Services/PassengerService.luau` | Builds passenger figures from parts, with visible tells (breath emitter, drips and puddle, CastShadow); walks and vanishes them |
| `ServerScriptService/Services/ShiftService.luau` | The Roblox `Stage` for the Director (queue on the dock, remotes, world calls) and the action handler |
| `ServerScriptService/Services/ProgressService.luau` | Endings found per player (DataStore) and badges |
| `ReplicatedStorage/Shared/Config.luau` | Remote names and tunables both sides read (timers, walk speed, look limits) |
| `ReplicatedStorage/Shared/Net.luau` | Creates and finds RemoteEvents; per-player rate limiter |
| `ReplicatedStorage/Shared/Types.luau` | The screen state, effects and progress payloads the server sends |
| `ReplicatedStorage/Client.client.luau` | Client entry: starts the effects, camera and HUD controllers |
| `ReplicatedStorage/Controllers/CameraController.luau` | Fixed booth camera: drag, keys and stick to look; scroll, pinch and R2 to lean in; shake |
| `ReplicatedStorage/Controllers/EffectsController.luau` | Blur behind cards, flood tint, lantern-out pulse, client-side lighthouse spin |
| `ReplicatedStorage/Controllers/HudController.luau` | The whole HUD and its wiring to the remotes |
| `ReplicatedStorage/Ui/Theme.luau` | Colours, fonts, design canvas and scale limits |
| `ReplicatedStorage/Ui/Ui.luau` | Typed UI builders (frames, labels, buttons, layout) |
| `ReplicatedStorage/Ui/Widgets.luau` | Shared pieces: captions, paragraphs, rule rows, text outlines |
| `ReplicatedStorage/Ui/Ticket.luau` | The ticket card, its drawn stamps, the torn-page tab, the BOARDED / TURNED AWAY stamp |
| `ReplicatedStorage/Ui/Overlay.luau` | Waiting, intro, summary, tide-came-in and ending cards, with the co-op Continue |
| `tests/` | Lune test suite (`lune run tests/run.luau`) and the headless simulator in `tests/sim/` |

## How a run flows

```
Server.server.luau
  WorldService.build()         harbor, lighting, water, booth; returns path markers
  ProgressService.start()      DataStore, badges, Progress remote
  ShiftService.start(markers)  Stage + Clock for the Director; Action remote handler
    loop forever:
      Director.waitForPlayers
      Director.playRun
        Run.new(seed); Run.beginNight -> Generator.buildNight
        per night:
          intro      hold up to IntroTime, or until everyone presses Continue
          per passenger:
            queue    Stage.callToWindow: walk them up; the queue steps forward
            window   wait up to DecisionTime for board / deny (timeout = deny)
            call     Run.decide -> lanterns, exit path, effects, ferry load
          if lanterns = 0: failed (flood, FailedTime), Run.restartNight, intro again
          summary    hold up to SummaryTime / Continue
        ending       endingScene, recordEnding, hold up to EndingTime / Continue
```

If `playRun` throws, ShiftService logs the traceback, clears the queue and
starts a fresh run, so a bug can't leave players stuck in a frozen booth.

## Remotes

All live in `ReplicatedStorage.Remotes`, created by the server through `Net`.

| Remote | Direction | Payload |
| --- | --- | --- |
| `ShiftState` | server → clients | `Types.State`: the whole screen, sent on every change |
| `ShiftFx` | server → clients | `Types.Fx`: `call`, `lanternOut`, `say`, `page`, `radio` |
| `ShiftProgress` | server → one client | `Types.Progress`: titles of endings found |
| `ShiftAction` | client → server | `("board" \| "deny" \| "page", passengerId)`, `("continue")`, `("sync")` |

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
| Camera | (0, 5.1, 3.4), fixed; looks out through the window. The planks closer than z ≈ −3.3 are hidden by the wall |
| Passenger at the window | (0, 0, −3.2), facing the booth |
| Booth lamp | (−3.4, 8.1, −1.05), aimed at (1.2, 0, −4.6). Shadows fall back and to the right, in view |
| Queue slots | (−2, 0, −11), (0.5, 0, −17), (−1.5, 0, −23); spawn in the fog at (−4, 0, −50) |
| Exits | board: gate → gangway → the *Petrel*'s deck; away: left of the rope line into the fog; water: the dock's left edge, then sink |
| *Petrel* | Moored along the dock's right edge, bow into the fog; sits lower for each drowned passenger aboard |
| Lighthouse | (−60, 0, −130); the beam turns on each client while the rotor's `Spinning` attribute is true |

## Tests and the simulator

- `tests/Rng|Rules|Generator|Run.spec.luau`: pure logic. The generator fuzz
  covers 400 seeds × 5 nights.
- `tests/Director.spec.luau`: the shift on a fake Stage and Clock.
- `tests/Game.spec.luau`: the real server and client scripts in
  `tests/sim/Roblox.luau`, a mock engine checked against
  `tests/sim/reflection.json`. A bot plays from the HUD.

When the game starts using a Roblox class or method the simulator doesn't know:

1. Add the class to `CLASSES` in `tests/sim/gen_reflection.py`.
2. Rerun the script with a fresh API dump.
3. Add the method to `tests/sim/Roblox.luau`.

The simulator doesn't render, has no physics, and snaps tweens to their end
values. It proves logic and wiring, not looks.
