# Phoenix Feather Roblox starter

A small, checked starting point for building a Roblox game with a coding agent
(Claude Code with Opus 5.5, or Codex with GPT-6 Astra) driving Roblox Studio.
Copy this folder once per game.

What's inside:

- **Agent rules**: `AGENTS.md` (Codex reads it; `CLAUDE.md` imports it for
  Claude Code), `ARCHITECTURE.md` (map of what exists), and `GAME_DESIGN.md`
  (the spec you fill in before building).
- **A working vertical slice** of the thing story games need most: talk to an
  NPC, read a line, pick a reply. Dialogue state lives on the server, every
  choice is validated and rate-limited, and the story data can't be datamined
  from the client. On a blank Baseplate it spawns a yellow "Keeper" to talk to.
- **Tooling** pinned in `rokit.toml`: Rojo 7.7.0, selene 0.31.0,
  StyLua 2.5.2, luau-lsp 1.70.1.

The code passes `stylua --check`, `selene` (Roblox std), `rojo build`, and
`luau-lsp analyze` in strict mode with no findings. It has not been playtested
in Studio (that needs a Windows or macOS machine); step 6 below is that check.

## 1. Install

- Roblox Studio (latest), Git, and one agent:
  - **Claude Code** (terminal, or the VS Code extension), or
  - **Codex CLI**.
- Optional but recommended: [Rokit](https://github.com/rojo-rbx/rokit), then run
  `rokit install` in this folder to get the pinned tools.
- VS Code users: the "Luau Language Server" extension and its Studio companion
  plugin, plus the selene and StyLua extensions.

## 2. Make the place

1. Copy this folder to a new folder named after your game and `git init` it.
2. In Studio: **New Experience** → Baseplate, then **File → Save to File** into
   that folder (`.rbxl`/`.rbxlx` files are ignored by git on purpose).

## 3. Sync the code (pick one)

**Script Sync (Roblox's built-in, simplest).**
1. **File → Beta Features** → enable **Script Sync** if it's listed → restart Studio.
2. In the Explorer, right-click **ServerScriptService** → **Script Sync → Sync to…** →
   choose the game folder itself (not the subfolder). Repeat for **ReplicatedStorage**.
3. Resolve the first-sync dialog in favour of **disk**.

**Rojo (more control, supports packages).**
1. `rojo plugin install`, then `rojo serve` in the game folder.
2. In Studio, open the Rojo plugin and **Connect**.
3. `default.project.json` sets `emitLegacyScripts: false` so file names mean the
   same thing as under Script Sync, and `$ignoreUnknownInstances` so Rojo never
   deletes things you placed in those services by hand.

Don't run both at once on the same services.

## 4. Connect the agent to Studio (MCP)

In Studio: **Assistant** → **…** → **Manage MCP Servers** → turn on
**Enable Studio as MCP server**, then under **Quick connect** switch on Claude
Code or Codex CLI. Restart the agent afterwards.

If quick connect doesn't list your client, add it by hand:

| | macOS | Windows |
| --- | --- | --- |
| Claude Code | `claude mcp add Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP` | `claude mcp add Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` |
| Codex CLI | `codex mcp add Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP` | `codex mcp add Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` |

## 5. Check the wiring

Ask the agent, in order:

1. "Read AGENTS.md, GAME_DESIGN.md and ARCHITECTURE.md, then tell me how this
   project is wired without touching Studio."
2. "Use the Roblox MCP to list what's in Workspace, ReplicatedStorage and
   ServerScriptService."
3. "Start a playtest, check the server and client console for errors, walk the
   character to the Keeper, trigger its prompt, pick option 1, screenshot the
   dialogue box, then stop the playtest and report."

## 6. Playtest it yourself

Press **Play**, walk to the yellow Keeper, press **E**, and click through the
conversation. Then set `SpawnDemoNpc = false` in `ReplicatedStorage/Shared/Config.luau`
and tag your own NPC: give any Part, or a Model with a PrimaryPart, the tag
`StoryNPC` and a string attribute `DialogueId` naming an entry in
`ServerScriptService/Story/Dialogues.luau`.

## 7. Build your game

1. Fill in `GAME_DESIGN.md`. Be specific; the agent builds what you write.
2. Ask for a plan broken into small phases, each testable on its own. Change the
   plan before any code exists.
3. One phase at a time: the agent implements it, verifies it in a playtest through
   MCP, runs the checks in `AGENTS.md`, and updates `ARCHITECTURE.md`. You play it.
   Commit when it's right.
4. Whenever the agent does something you had to correct twice, add a rule to
   `AGENTS.md`.
