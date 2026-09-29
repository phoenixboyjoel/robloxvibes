# Architecture map

The source of truth for what exists. Agents read this instead of re-scanning
Studio, and update it in the same change whenever something is added, moved,
or removed.

## Synced code (disk ↔ Studio)

| Path on disk | Studio instance | Purpose |
| --- | --- | --- |
| `ServerScriptService/Server.server.luau` | Script (Server) | Only server entry point; starts services in order |
| `ServerScriptService/Services/StoryService.luau` | ModuleScript | Talkable NPCs: prompts, server-side dialogue state, choice validation |
| `ServerScriptService/Story/Dialogues.luau` | ModuleScript | Dialogue graphs (server-only so players can't datamine them) |
| `ReplicatedStorage/Client.client.luau` | Script (Client) | Only client entry point; starts controllers |
| `ReplicatedStorage/Controllers/DialogueController.luau` | ModuleScript | Draws the dialogue box, sends choices |
| `ReplicatedStorage/Shared/Config.luau` | ModuleScript | Shared constants (tags, remote names, limits) |
| `ReplicatedStorage/Shared/Net.luau` | ModuleScript | Remote creation/lookup and per-player rate limiter |

## Created at runtime

| Instance | Created by | Notes |
| --- | --- | --- |
| `ReplicatedStorage.Remotes.DialogueShow` | StoryService via Net | server → client: node payload, or nil to close |
| `ReplicatedStorage.Remotes.DialogueChoose` | StoryService via Net | client → server: (nodeId, optionIndex), validated |
| `PlayerGui.Dialogue` | DialogueController | ScreenGui, ResetOnSpawn = false |
| `Workspace.Keeper` | StoryService (demo only) | Spawned when no `StoryNPC` exists and `Config.SpawnDemoNpc` is true |

## World (lives in the place file, reached through MCP)

| Instance | Tags / attributes | Notes |
| --- | --- | --- |
| _(none yet)_ | | Tag talkable NPCs `StoryNPC` and give them a `DialogueId` string attribute |
