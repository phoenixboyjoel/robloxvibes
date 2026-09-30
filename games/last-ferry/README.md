# Last Ferry

A Roblox rules-horror game from Phoenix Feather Studios. You work the night
ticket window for the last ferry to Gull Island. Twenty-seven years ago the
*Marigold* sank with everyone aboard, and this week the drowned are back in the
queue, trying to get home.

- **Five nights.** Each one adds a rule, and the drowned learn to hide one more
  tell.
- **Every passenger is a call:**
  1. Read the ticket.
  2. Look at the person: breath in the cold, dripping seawater, a shadow under
     the lamp, whether they know your name.
  3. Check the rules card and the manifest.
  4. Press **BOARD** or **TURN AWAY**.
- **Three lanterns a night.** Each wrong call puts one out. Lose all three and
  the tide comes in.
- **Four endings, one of them secret.** Plus a little girl in a red coat who
  asks every night whether this is the ferry home.
- **It's a Roblox game first.** You arrive on the pier behind the booth as your
  own avatar, with your friends; hold **E** at the time clock and the whole
  server clocks in. You work the window in first person, side by side at the
  counter in the harbor's captain's caps. Passengers are classic Robloxians who
  talk in chat bubbles, the HUD is Roblox's chunky house style, and the player
  list keeps your Endings and Shifts.
- **One to four players** share the booth, and anyone can make the call.
- **Controls:**
  - On the pier: Roblox's usual controls, camera, chat and emotes.
  - In the booth: walk with WASD or the thumbstick; look with the right mouse
    button, a finger or the right stick; scroll, pinch or R2 to lean in.
  - **B** / **T** (gamepad **A** / **B**) to board or turn away, **P** (**X**)
    to take a torn page, and **Enter** or **Space** to continue. Gamepad A and
    Space still jump when there's nothing to press.

Everything is built from parts and code, and the sounds are Roblox's built-in
ones: no asset IDs, no licences to check. The story design is in
[GAME_DESIGN.md](GAME_DESIGN.md) and the code map is in
[ARCHITECTURE.md](ARCHITECTURE.md).

## What it looks like

These are renders of the real game, running in the test simulator, drawn by
[tools/preview](tools/preview/README.md): a three.js approximation of Roblox's
renderer, close enough to judge framing, colour, layout and whether a tell can
be seen. Roblox itself will differ in materials, light and fog, and players will
be wearing their own avatars rather than the simulator's plain blocky ones.

![Three avatars on the pier behind the booth, one at the time clock with Roblox's "Clock in" prompt](docs/preview-lobby.png)

**The pier.** You spawn behind the booth as your own avatar. The notice board and
the banner say what to do; the time clock by the back door has Roblox's own
"Clock in" prompt.

| A living regular at the window | One of the drowned (1999 ticket) |
| --- | --- |
| ![First-person booth view with a living passenger](docs/preview-living.png) | ![First-person booth view with a drowned passenger](docs/preview-drowned.png) |

**The window, in first person.** Passengers are classic Robloxians and talk in
chat bubbles. The living breathe fog and cast a shadow back and to the right of
them under the lamp. The drowned carry old tickets with the blue anchor stamp;
this one drips seawater and wears seaweed. The HUD is Roblox's chunky style:
green BOARD, red TURN AWAY, lanterns top right, rules on the right.

| The clerks, seen from the dock | On a phone |
| --- | --- |
| ![Three avatars in captain's caps behind the counter, a passenger in front](docs/preview-crew.png) | ![The booth view on a phone in landscape](docs/preview-phone.png) |

**Friends share the booth** in the harbor's captain's cap, each at a stand behind
the counter. **On a phone** the HUD scales down, stays below Roblox's top bar,
and keeps the rules panel clear of the jump button.

## Status

| Area | State |
| --- | --- |
| Game logic (rules, queue generation, runs, endings) | Built, fuzz-tested over thousands of generated nights |
| Shift flow (intro, window, summary, retry, ending, co-op Continue) | Built, simulated end to end |
| Server (world, passengers, crew, remotes, saves) and client (cameras, HUD, crowd, sounds) | Built, run together in a headless Roblox simulator with players' characters |
| Roblox look and feel (avatars and pier lobby, classic Robloxian passengers, chat bubbles, chunky HUD, player list, built-in sounds) | Built, tested headless, previewed with an approximate renderer |
| Looks, lighting, feel, pacing in real Roblox | **Not yet seen.** It needs a playtest in Roblox Studio on your machine ([PLAYTEST.md](PLAYTEST.md)) |
| Store page, badges, icon, questionnaire | To do before publishing (checklist below) |

## Play it in Studio

1. Get `LastFerry.rbxl`:
   - use the copy delivered with this build, or
   - build it with `rojo build -o LastFerry.rbxl`.
2. Open it in Roblox Studio and press **Play**. Everything (the harbor, the
   booth, the pier, the ferry, the fog) is built by the server script when it
   starts, so the place looks empty in Edit mode. That's expected. You spawn on
   the pier: walk to the time clock by the booth's back door and hold **E**.
3. Work through [PLAYTEST.md](PLAYTEST.md) and note anything that looks or feels
   wrong.

To work on the code with live sync, run `rojo serve` in this folder and connect
the Rojo plugin, or use Studio's Script Sync on `ServerScriptService` and
`ReplicatedStorage`. [AGENTS.md](AGENTS.md) explains the rules for doing that
with Claude Code or Codex.

## Checks

Run from this folder. Every tool, Lune included, is pinned in `rokit.toml`:
install Rokit, then run `rokit install`.

```sh
stylua --check ServerScriptService ReplicatedStorage tests tools
selene .
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform roblox --sourcemap sourcemap.json \
  --definitions @roblox=<path to globalTypes.None.d.luau> ReplicatedStorage ServerScriptService
lune run tests/run.luau
rojo build -o LastFerry.rbxl
```

GitHub Actions runs all of these on every pull request
([.github/workflows/checks.yml](../../.github/workflows/checks.yml)), with the
same pinned versions. It keeps the built place file as a download on each run.

At the time of this build every check comes back clean:
- 51 tests pass.
- There are 0 selene findings.
- There are 0 strict type errors.

An independent review then checked what the tests can't: geometry against
Roblox's real conventions, replication, rendering and layering, and
readability. Its fixes are in:
- **Wet passengers:** drips and the puddle moved to where the booth can see
  them.
- **Lighting:** pinned for reliable shadows, with a fallback shadow mark for
  low-quality devices.
- **Radio and warnings:** Pike's radio pauses the queue, and lantern warnings
  moved to a top banner, so neither covers a passenger's face.
- **Plus:** taller cards, a delayed ending reveal, keyboard and gamepad
  shortcuts, and a gate the passengers fit through.

The tests have three layers:

1. **Logic** (`Rng`, `Rules`, `Generator`, `Run`):
   - Every generated night is fair: the living never show a supernatural tell,
     and every drowned passenger breaks a rule you can see.
   - Perfect play never loses a lantern.
   - Each ending is reachable.
2. **Shift flow** (`Director.spec`): whole runs on a simulated clock, including
   timeouts, retries, co-op Continue and ignored junk input. A bot that sees only
   the screen state plays perfectly, and nothing on screen reveals who is
   drowned.
3. **The real game, headless** (`Game.spec`, `Passenger.spec`, `Sim.spec`):
   - The actual server and client scripts run together in `tests/sim`, a mock
     Roblox checked against the engine's API dump, on a virtual clock, with
     players' characters, spawns, accessories, ProximityPrompts,
     ContextActionService and sounds.
   - A bot spawns on the pier, walks to the time clock and clocks in, reads the
     HUD, the chat bubbles and the passengers' visible tells, then presses the
     real buttons.
   - It finishes clean runs, the Mara ending, the ledger epilogue, and a
     late-joining co-op session, then clocks out onto the pier.
   - It checks the lobby, the booth (door, walls, stands, the cap, hats hidden
     and restored), gamepad A boarding instead of jumping, what players hear,
     and button sizes and the jump-button gap on phone-sized screens.
   - Passengers who differ only in kind are built identically, part for part.

Mutation checks confirmed each layer fails when a real bug is planted (for
example, swapped buttons, a wrong date on the ticket, a missing manifest, or
breath never shown).

## Before publishing

- [ ] Playtest in Studio ([PLAYTEST.md](PLAYTEST.md)), including the phone
      device emulators and a 2-player local server.
- [ ] Game Settings → Places → Max Players: **4**.
- [ ] Avatar Settings: R15 (keep player choice of body and clothing). The
      booth normalises eye height, so any avatar size works. Check the clerk's
      cap on a few heads.
- [ ] Game Settings → Security → turn on **Enable Studio Access to API
      Services** to test saving in Studio. The game runs without it and says so
      in the output.
- [ ] Create four badges on the Creator Dashboard:
      - The Petrel Sails
      - Mara Goes Home
      - Low in the Water
      - The Ledger (secret)

      Put their IDs in `BADGES` in
      `ServerScriptService/Services/ProgressService.luau`.
- [ ] Maturity & Compliance questionnaire: the target is **Mild fear** (see
      [GAME_DESIGN.md](GAME_DESIGN.md)): no blood, gore, or on-screen death.
- [ ] Icon, thumbnails, a 30-second trailer of the first two passengers, and a
      description that leads with the hook. In Roblox's format: a title like
      **Last Ferry ⛴️ [HORROR]**, thumbnails with 2–4 avatars in the booth
      facing a drowned passenger ("DON'T LET THEM BOARD"), and "anomaly" and
      "night shift" in the description (see
      `research/` and the Roblox-look research notes).
- [ ] Genre: Horror. Set the start place's server fill to "maximum" so friends
      land together.

Market context, the discovery rules for new games, and the kill and continue
thresholds are in `research/` at the repository root.
