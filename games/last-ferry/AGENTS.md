# Agent rules: Last Ferry

You are working on a finished first build of a Roblox game with the developer.
Read this file, then `GAME_DESIGN.md` (what the game is), `ARCHITECTURE.md`
(what exists and how it flows) and `PLAYTEST.md` (what hasn't been seen yet)
before you change anything. Claude Code loads this file through `CLAUDE.md`;
Codex reads it directly.

## How this project differs from the starter template

- **Git holds everything, including the world.** The harbor, the booth and the
  ferry are built by `WorldService` when the server starts. Don't build world
  geometry by hand in Studio or with MCP `execute_luau`; change `WorldService`
  and rebuild. The `.rbxl` is a build output (`rojo build -o LastFerry.rbxl`)
  and is ignored by git.
- **There is a headless test suite, and it's the first line of verification.**
  `lune run tests/run.luau` runs:
  - the logic tests;
  - a simulated shift;
  - the real server and client scripts together, with a bot playing through the
    HUD.

  It must pass before you tell anyone a change works. Then verify in Studio
  (below) for anything visual or about feel.

## How the project is wired

- `ServerScriptService/` and `ReplicatedStorage/` sync into Studio with Rojo
  (`rojo serve`, `default.project.json`) or Script Sync. The project also sets
  properties that belong in the place:
  - `Workspace.StreamingEnabled = false`: the client needs the whole harbor in
    view from the booth;
  - `Lighting.LightingStyle = Realistic` with `PrioritizeLightingQuality`:
    crisp local-light shadows, which the shadow rule depends on.
    `setUpLighting` sets both again at runtime;
  - `Players.CharacterAutoLoads = true`: players are their own avatars;
  - `StarterPlayer.CameraMaxZoomDistance = 25`: a close third-person camera on
    the pier;
  - `TextChatService.ChatVersion = TextChatService`, which the passengers' chat
    bubbles need (scripts can't set it).
- One server Script, one client Script (in ReplicatedStorage, RunContext
  Client). Everything else is a ModuleScript. Never put a `.client.luau` file in
  a Starter container: it would run twice.
- Requires use Roblox's require-by-string: `./` from the script's parent, `../`
  from its grandparent. The disk layout mirrors the DataModel, so the same paths
  work in Studio, in luau-lsp and in the Lune tests.

## Rules that keep the game fair (tests enforce them)

- The living never show a supernatural tell: they are always dry, breathing and
  casting a shadow, and never say your name. Their mistakes are paperwork only.
- Every drowned passenger, and Mara, breaks at least one rule that is active
  that night and visible to the player.
- `Rules.broken` looks only at what the player can see. Visible tells are built
  from the passenger's facts (`wet`, `breath`, `shadow`, `saysName`), never from
  their `kind`.
- The screen state (`Director.state`) never carries a passenger's kind, role or
  tells. Only what a clerk can read or see.
- If you add a rule or a new kind of passenger, extend the generator's guarantee
  tests in `tests/Generator.spec.luau` first.

## The work loop

1. Plan in small phases from `GAME_DESIGN.md` and `PLAYTEST.md` notes. Say
   what each phase changes and how it will be verified.
2. Read the modules involved. Reuse `Content`, `Rules`, `Director`, `Ui`
   builders and `Widgets` instead of adding parallel versions.
3. Make the smallest change that completes the phase. Story text goes in
   `Content.luau`; tunables in `Content.Nights` or `Shared/Config.luau`.
4. Run the checks (below) until they're clean.
5. For anything visual or about feel (lighting, fog, shadows, particles, UI
   layout, pacing), verify in Studio through the MCP server:
   - start a playtest;
   - read the server and client output;
   - screenshot the booth view at the window;
   - use the device emulator for phone sizes.

   Never claim something looks right without a screenshot.
6. Update `ARCHITECTURE.md` in the same change.
7. If two fixes in a row fail, stop. Re-read everything involved, explain
   step by step what should happen and where it diverges, then edit.

The developer judges feel, difficulty, pacing and scares. Ask them to play
anything you can't measure.

## Checks

From this folder (every tool, Lune included, is pinned in `rokit.toml`):

```sh
stylua ServerScriptService ReplicatedStorage tests tools
selene .
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform roblox --sourcemap sourcemap.json \
  --definitions @roblox=<path to globalTypes.None.d.luau> ReplicatedStorage ServerScriptService
lune run tests/run.luau
rojo build -o LastFerry.rbxl
```

All clean, every time. If a test fails, the code is wrong until proven
otherwise. Don't weaken or skip a test to get green.

## Luau rules

- `--!strict` on every game file, with parameters and returns annotated.
- UI properties are set through typed assignments (see `Ui.luau`) so luau-lsp
  checks every property name and value type. Don't build instances from
  untyped property tables.
- `task.*` only: never `wait`, `spawn`, `delay`, or `Instance.new(class,
  parent)`. Set Parent last.
- No deprecated APIs. The simulator records any deprecated member used, and the
  tests fail on it.
- Never move things by tweening their CFrame on the server: it stutters on
  players' screens and replicates every frame. Glide them
  (`ReplicatedStorage/Shared/Glide`), and once something has glided move it only
  with Glide. Tweening other properties on the server (a fade, a colour) is
  fine.
- Identify players with `player.User`; key saved data by `player.User.Id`.
- New Roblox API in game code? The simulator will say "isn't simulated". Add
  the class to `tests/sim/gen_reflection.py` and the behaviour to
  `tests/sim/Roblox.luau`, rather than working around the test.

## Security

- Every `ShiftAction` goes through three checks:
  1. the rate limiter;
  2. the kind whitelist in `ShiftService`;
  3. the phase and passenger-id checks in `Director.action`.

  Keep all three for any new action.
- Story content, later nights, the ledger and the endings stay in
  `ServerScriptService`. Players can read anything in ReplicatedStorage.
- No player-written text is shown to others. If that changes, filter it with
  TextService.

## Phones first

- The HUD is laid out on a 960 × 420 design canvas and scaled with `UIScale`
  (`Theme`). At the smallest phone scale (about 0.7), main buttons must stay at
  least 44 px: keep them 64 design px or more. `Game.spec` checks this.
- Keep the bottom centre of the screen clear: the passenger's shadow falls
  there, and it's a rule from night 4.
- Nothing may cover a passenger's face while they're at the window: breath is
  a rule from night 3. That's why the radio waits for an empty window and
  warnings show as a banner over the top bar.
- Roblox's touch controls are on (players walk the pier and the booth): the
  thumbstick takes the lower left and the jump button the lower right. The
  rules panel stops short of the jump button on touch screens; `Game.spec`
  checks it.
- Every tell must be visible from the front stand's first-person view (the eye
  is held at y = 5.1 for every avatar). The sill hides the planks closer than
  z ≈ −4.1, and a passenger's body hides everything straight behind them.
  Check new cues with `tools/preview` (export, then render) before a Studio
  playtest.
- Every tell is visual. Sound is feedback only (footsteps, the stamp, clicks, a
  lantern's gust, splashes), and only Roblox's built-in sounds
  (`rbxasset://sounds/...`, see `Shared/Sounds.luau`), so there's nothing to
  upload. Every passenger sounds the same whatever they are; `Game.spec` checks
  that every sound played is a built-in one.

## Definition of done

- [ ] `lune run tests/run.luau` passes, and new behaviour has a test
- [ ] stylua, selene and luau-lsp clean; `rojo build` succeeds
- [ ] Visual or feel changes checked in a Studio playtest with screenshots,
      including a phone emulator
- [ ] `ARCHITECTURE.md` updated
- [ ] A short summary for the developer: what changed, how it was verified,
      and what still needs a human to judge
