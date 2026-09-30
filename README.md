# robloxvibes

Phoenix Feather Studios' workspace for building Roblox games with AI coding
agents: Claude Code with Claude Opus 5.5, or Codex with GPT-6 Astra.

- **[research/](research/README.md): is this plausible, and how?** Start with
  [the verdict](research/00-verdict-and-executive-summary.md) and
  [the 90-day plan](research/08-action-plan.md).
- **[starter/](starter/README.md): a checked starting point for each game.** It
  wires an agent to Roblox Studio (Script Sync or Rojo, plus Studio's built-in
  MCP server). It includes agent rules drawn from Roblox's own benchmark findings
  and a working, exploit-resistant NPC dialogue slice.
- **[games/last-ferry/](games/last-ferry/README.md): the first game, built.** An
  anomaly-shift horror game. You work the night ticket window for the last ferry
  to Gull Island and keep the drowned off the boat.
  - Five nights and four endings, for one to four players.
  - Built entirely from code: the world, the HUD, and a test suite that runs the
    real server and client headlessly while a bot plays.
  - Next step: the first Studio playtest
    ([PLAYTEST.md](games/last-ferry/PLAYTEST.md)).

## The answer in one paragraph

Yes. As of September 2026, Roblox officially supports AI agents driving Studio,
and people are building playable Roblox prototypes in hours to days with both
models. No AI-built Roblox game has verified commercial results yet. Even the
best models solve only about half of realistic Studio tasks on the first try, so
every change needs verifying. The market now rewards retention and originality
over speed. Use the agent for systems and content variation, and put human effort
into premise, fun, art direction and live operations. A story-first studio is
well placed for that. Details and sources are in [research/](research/README.md).
