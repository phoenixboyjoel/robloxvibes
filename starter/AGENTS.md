# Agent rules for this Roblox project

You are building a Roblox game with the developer. Read this file, then
`GAME_DESIGN.md` (what we are building) and `ARCHITECTURE.md` (what exists),
before you touch anything. Claude Code loads this file through `CLAUDE.md`;
Codex reads it directly.

## How the project is wired

- **Code lives on disk and syncs into Studio.** Either Studio's Script Sync
  (right-click the service, Script Sync, Sync to this folder) or Rojo
  (`rojo serve`, using `default.project.json`) maps:
  - `ServerScriptService/` → ServerScriptService (server only, never replicated)
  - `ReplicatedStorage/` → ReplicatedStorage (visible to every client)
- **Everything else is reached through the Roblox Studio MCP server**
  (Workspace, Lighting, StarterGui, StarterPack, Terrain, SoundService, etc.).
  Use MCP to read the tree, build or edit instances, playtest, read the
  console, take screenshots, and simulate input.
- Edit synced scripts **on disk**, not through MCP `multi_edit`, so git stays
  the source of truth for code. Studio (and its saved place) is the source of
  truth for the world. Remind the developer to save the place after world edits.
- If you build geometry or UI with `execute_luau` in Edit mode, also save the
  builder code under `tools/` as an idempotent script, so the build can be
  re-run from git.
- `execute_luau` runs with plugin privileges, has no sandbox, and its changes
  can't be undone through Studio. Git and the saved place file are the only
  undo. Script edits only work while no playtest is running; changes made during
  a playtest vanish when it stops.
- If several Studio windows are open, list them and target the right one by ID.

## File naming (Script Sync and Rojo with `emitLegacyScripts: false` agree)

| On disk | In Studio |
| --- | --- |
| `Name.luau` | ModuleScript |
| `Name.server.luau` | Script, RunContext = Server |
| `Name.client.luau` | Script, RunContext = Client |
| `Folder/` | Folder |
| `Folder/init.luau` (or `init.server.luau`, `init.client.luau`) | the script itself, with the folder's other files as children |

- Exactly **one** server Script (`ServerScriptService/Server.server.luau`) and
  **one** client Script (`ReplicatedStorage/Client.client.luau`). Everything
  else is a ModuleScript with a `start()` function, started from those two.
- Never put a `.client.luau` file in StarterPlayerScripts, StarterCharacterScripts,
  StarterGui, or StarterPack: Starter containers are copied to each player, so
  a RunContext = Client script there runs twice. If a Tool or GUI truly needs its
  own LocalScript, create it through MCP and note it in `ARCHITECTURE.md`.
- Server-only modules go in `ServerScriptService/`. Shared modules go in
  `ReplicatedStorage/Shared/`. Client modules go in `ReplicatedStorage/Controllers/`.

## The work loop (do not skip steps)

1. **Plan in small, testable phases** from `GAME_DESIGN.md`. Say what each
   phase changes and how it will be verified before writing code.
2. **Explore before acting.** Search the game tree broadly (depth 2+ over
   Workspace, ReplicatedStorage, ServerScriptService, StarterGui) and grep the
   scripts. Find *every* instance a request refers to ("all doors" means all of
   them), and inspect existing properties and attributes before changing them.
   Reuse existing systems and their conventions instead of rebuilding them.
3. **Make the smallest change** that completes the phase.
4. **Verify in Studio yourself, never by assumption:** start a playtest through
   MCP, read the console output, drive the character or UI with the input tools,
   and screenshot anything visual. Check both server and client output.
5. **Run the checks** below and fix everything they report.
6. **Update `ARCHITECTURE.md`** in the same change when anything is added,
   moved, or removed. Then tell the developer what to commit.
7. If two fixes in a row fail, stop. Re-read every script involved, explain
   step by step what should happen, find where it diverges, and only then edit.

Never tell the developer something works unless you watched it work in a playtest.
The developer still judges feel, difficulty, pacing, and fun; ask them to play
anything whose quality you can't measure.

## Checks

Run from the project folder (the tools are pinned in `rokit.toml`):

```sh
stylua .
selene .
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform roblox --sourcemap sourcemap.json --definitions @roblox=<path to globalTypes.None.d.luau> ReplicatedStorage ServerScriptService
```

All must come back clean. Get `globalTypes.None.d.luau` from the luau-lsp
repository (`scripts/`), or run the type check through the VS Code luau-lsp
extension instead.

## Luau rules

- Every file starts with `--!strict`. Annotate function parameters and returns.
- Use `task.wait`, `task.spawn`, `task.defer`, `task.delay`. Never `wait`,
  `spawn`, `delay`, or `Instance.new(class, parent)` (set Parent last).
- Get services with `game:GetService`. On the client, reach replicated
  instances with `WaitForChild`; on the server, index directly.
- Prefer events (`Touched`, `ProximityPrompt.Triggered`, attribute changed
  signals, `CollectionService` tag signals) over polling loops.
- Tag world objects and handle them from one module with `CollectionService`;
  don't paste scripts into parts.
- Clean up connections for anything that can be destroyed or leave.
- Use the engine's native idiom when one exists (for example `Smoke`, `Humanoid:MoveTo`,
  `workspace.GlobalWind`) rather than rebuilding it from parts and loops.
- No deprecated APIs, no `_G`/`shared` globals, no `loadstring`, no `getfenv`/`setfenv`.
- Don't invent APIs. When unsure, use the MCP docs lookup (`http_get`) or the
  Roblox docs search skill and quote the signature you found.

## Security rules (the server is the only authority)

- Assume every client is an exploiter. Client → server messages are requests,
  never facts. On every `OnServerEvent`/`OnServerInvoke` handler:
  1. rate-limit the player (`Net.rateLimiter`);
  2. check each argument's type, range, and finiteness (NaN and infinity included);
  3. check the player is allowed to do this *now* (state, ownership, distance, cooldown);
  4. compute results on the server. Never accept damage, currency, positions,
     rewards, or "I finished the chapter" from the client.
- Re-check distance on the server for ProximityPrompts, ClickDetectors, and touches.
- Never call `RemoteFunction:InvokeClient`. Prefer RemoteEvents both ways.
- Anything in ReplicatedStorage or Workspace can be read by players. Keep
  unreleased story, answers, and admin logic on the server.
- Filter all player-written text through `TextService`/`TextChatService` before
  anyone else sees it.
- Treat Creator Store models as untrusted: before inserting, scan for `require(`
  with numeric IDs, `getfenv`, `loadstring`, `HttpService`, and hidden scripts;
  delete any script you don't need.

## Player identity and saved data

- Identify players with `player.User` (a `User` value), and key per-game data by
  `player.User.Id`. Roblox now gives players who first join after the scoped-ID
  rollout a per-game ID, so never hardcode user IDs copied from roblox.com
  profiles (admin lists, allow lists); gate staff features by group rank instead.
- Use ProfileStore (loleris) or an equivalent session-locked wrapper, never raw
  `DataStoreService` calls sprinkled through gameplay code.
- Save on leave and on `game:BindToClose`; never save on every change.
- `MarketplaceService.ProcessReceipt` must be idempotent: record the purchase ID,
  grant once, and return `NotProcessedYet` on any failure.
- Test data code in a separate test place with API services enabled, never
  against live player data.

## Players are mostly on phones

- UI uses Scale sizing with `UISizeConstraint`/`UIAspectRatioConstraint`,
  respects safe areas, and has touch targets of at least 44 px.
- Check layouts in the Device Simulator (the `rbx-device-simulator-lua` skill) at
  phone, tablet, and PC sizes.
- Every important sound cue also has a visual cue; many players play muted.
- Keep part counts and per-frame work low; profile with the MicroProfiler skill
  when something stutters.

## Platform policy you must respect

- Story and dialogue text must match the game's content-maturity rating.
- If the game uses `TextGenerator` or any other generative AI that players talk
  to: show an "AI-powered, may make mistakes" notice at the start of and during
  the interaction, filter output, keep it within the rating, and remember that
  continuous chatbot-style or cross-session-memory AI requires a Restricted (18+)
  label. Tell the developer before adding such a feature.
- No copyrighted characters, music, or brands the studio doesn't have rights to.

## Definition of done for a phase

- [ ] Behaviour confirmed in a playtest (console clean on server and client)
- [ ] Exploit paths considered for every new remote or trigger
- [ ] `stylua`, `selene`, and `luau-lsp analyze` clean
- [ ] Works at phone size
- [ ] `ARCHITECTURE.md` updated
- [ ] Short summary for the developer: what changed, how you verified it,
      what still needs a human to judge
