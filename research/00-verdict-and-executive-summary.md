# Verdict: can Phoenix Feather build Roblox games with Opus 5.5 or GPT-6 Astra?

*Research date: 2026-09-29. Prepared for Joel Z, Phoenix Feather Studios.*

## The short answer

**Yes, building is very plausible. Commercial success is not proven for anyone
yet.** As of September 2026 a small studio can realistically build and ship
Roblox games with a coding agent doing most of the scripting, using either
Claude Opus 5.5 (in Claude Code) or GPT-6 Astra (in Codex). Roblox now supports
this officially. What an agent does not provide is a hit. That still depends on
premise, fun, art direction, retention and live operations, all of which remain
human work. And in 2026 those matter more, not less.

## What the evidence says

### 1. Roblox has built the plumbing for this

Checked directly against Roblox's own documentation and repositories:

- **Studio has a built-in MCP server.** It is Roblox's official connection point
  for outside AI agents, and it replaced the standalone server Roblox archived on
  April 3, 2026.
  - It offers one-click connection for **Claude Code, Codex CLI**, Cursor,
    Gemini CLI and VS Code.
  - Through it, an agent can read and edit scripts, search the game tree, run
    Luau, start and stop playtests, read the console, take screenshots, simulate
    keyboard, mouse and movement input, generate meshes and materials, and hand
    work to a playtest subagent.
- **Roblox publishes a "Build with a coding harness" guide and starter project.**
  It is written for Claude Code and Cursor, pairs Script Sync (Studio's built-in
  file sync) with MCP and Git, and includes Roblox's own advice on writing a
  `CLAUDE.md`.
- Roblox's in-Studio **Assistant** accepts your own Anthropic, OpenAI or Google
  API key. It also has Planning Mode and skills.

### 2. People are shipping prototypes in hours to days

Examples in [01](01-bletdemonjh-and-the-ai-roblox-wave.md) and
[04](04-case-studies.md), all from the past few weeks:

- a GPT-6 Astra kart racer built in Studio in 30 minutes;
- the same anime brawler built with both models;
- a veteran developer's Opus 5.5 remake of the classic Crossroads map, made with
  10 parallel subagents in about 3 hours;
- a first-time developer's first finished Roblox game, built in 3–4 days.

### 3. Nobody has proven the business yet

Across 17 case studies, **no AI-credited Roblox game has verified player or
revenue numbers.**

- The viral posts are new builds in the most crowded genres, often built on
  copyrighted IP, and measured in likes rather than players.
- Roblox's own benchmark sets expectations. Before these two models launched,
  the best model (Claude Fable 5) solved **about 50% of realistic Studio tasks on
  the first try, and all five attempts succeeded on only about 40%**. Treat the
  agent as a fast junior developer whose work you verify, not an autonomous studio.

### 4. The market has turned, and that favours studios with a real point of view

Details in [05](05-roblox-market-and-economics.md):

- **Players and spending are down from the 2025 peak.** Daily users fell from
  151.5M (Q3 2025) to 123M (Q2 2026). Roblox guided Q3 2026 bookings down 14–18%
  and withdrew its full-year guidance.
- **Home recommendations now reward long-term retention.** Roblox says games
  that favour short-term monetization get fewer impressions, and near-copies of
  existing games are "no longer prioritized".
- **New games are shown only to age-checked players aged 16+ at first.**
  Reaching under-16s takes 250 unique plays by highly engaged players within 60
  days, plus a safety review.
- **Adult spending pays better.** Robux spent by age-checked US adults in games
  that never allow R6 avatars cash out at $0.0054 per Robux instead of $0.0038.
- **Cheap AI-made games are flooding in**, including a reported 9,000 or so made
  with Roblox's own Build tool. Speed stops being an advantage when everyone has it.
  **Original characters, stories and art direction become the advantage, and
  that is Phoenix Feather's stated identity.**

### 5. Story games that last tell the story through mechanics

Details in [06](06-story-driven-games-on-roblox.md). The durable hits encode
story as rules and goals:

- **Doors:** each monster is a rule you learn. 7.8B visits, and tracker data
  shows it still spiking to about 227K concurrent players in August 2026.
- ***99 Nights in the Forest*:** rescue four missing kids, survive the nights.
  It peaked at 14.2M concurrent players and now has a film deal.
- ***Scary Shawarma Kiosk*:** a solo developer's rules-based night-shift horror
  game, with about 1.3B visits in 13 months.

Purely linear, cutscene-heavy story games spike and then get used up.

The cheapest high-return format that fits AI agents is **"anomaly shift"
micro-horror**: a mundane job with one uncanny rule, played over several nights
with multiple endings. It is mostly logic, data and UI, which is exactly what
agents are good at.

### 6. Your existing assets are usable, with care

Details in [07](07-assets-licensing-and-pipeline.md). Uploading to Roblox grants
Roblox a broad, sublicensable license, and meshes and images can default to open
use, so asset-store licenses need a closer look.

| Source | Status |
| --- | --- |
| Public-domain (CC0) packs; Synty packs bought directly from Synty; Roblox's licensed audio library | Clear to use |
| Unity Asset Store, Fab, TurboSquid and similar | Gray area. Upload as private, never redistribute, turn off AI data sharing, and ideally get the publisher's OK in writing |
| Unreal-only content, Unity "Restricted" assets, non-commercial or editorial licenses, commercial music | Out |

### 7. Which model to use

Details in [02](02-models-opus-5-5-vs-gpt-6-astra.md).

- **Lean: Opus 5.5 as the main agent.**
  - Claude models lead Roblox's Luau benchmark, although most gaps were not
    statistically significant.
  - Roblox's own starter is written for Claude Code.
  - Opus 5.5 costs $4/$20 per million tokens, and Anthropic pitches it at roughly
    Fable 5.1 level.
- **Keep GPT-6 Astra as reviewer and fallback.** Reports say it is faster and
  sometimes cheaper per task.
- **Settle it with a one-week bake-off on your own tasks.** Neither model has a
  Roblox-specific score yet.
- **The rules you give the agent matter as much as the model.** Every failure
  pattern Roblox measured has a matching rule in
  [`starter/AGENTS.md`](../starter/AGENTS.md).

## What this repository gives you

| Path | What it is |
| --- | --- |
| [`starter/`](../starter/README.md) | A checked starter project. It works with Script Sync or Rojo, and includes agent rules (`AGENTS.md` / `CLAUDE.md`), a game design template, an architecture map, and a working NPC-dialogue slice with server-side validation and rate limiting. It passes `rojo build`, `selene`, `stylua --check` and `luau-lsp analyze` in strict mode. It hasn't been run in Studio yet, because that needs a Windows or macOS machine. |
| [`research/08-action-plan.md`](08-action-plan.md) | The 90-day plan: setup, bake-off, licence triage, first game, launch, and when to keep going or stop |
| [`research/01`–`07`](README.md) | The full research, with sources and a confidence tag on each claim |

## What I couldn't do (read before relying on this)

- **I couldn't read @bletdemonjh's posts.** x.com is blocked in this environment,
  and search engines haven't indexed the account. I verified who the account
  holder is: the Roblox developer bletDemonJH, who owns the 14.6K-member group
  "Ananas The Studio." I also verified that the linked post went up on 2026-09-29
  at 09:49 UTC, in the middle of a wave of "AI built my Roblox game" posts. **Paste
  the posts, or allow x.com, and I'll fold them in.** See
  [01](01-bletdemonjh-and-the-ai-roblox-wave.md).
- **Most sites were blocked, and the shared web-search budget ran out** partway
  through. What that means for trust:
  - **Most reliable:** Roblox rules, APIs, fees and policies, read directly from
    Roblox's official documentation source on GitHub, and Anthropic's model facts,
    read from anthropic.com.
  - **Less reliable:** game metrics, OpenAI details, news and third-party licence
    wording. These mostly come from search-result summaries and carry a tag in
    each file.
- **Needs a professional:** licensing conclusions are a careful reading of public
  terms, not legal advice. Money figures for games are estimates unless tagged
  verified.
