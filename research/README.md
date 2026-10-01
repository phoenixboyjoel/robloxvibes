# Research: building Roblox games with AI agents (September 2026)

Start with **[00: the verdict](00-verdict-and-executive-summary.md)**, then
**[08: the 90-day plan](08-action-plan.md)**.

| # | File | Covers |
| --- | --- | --- |
| 00 | [Verdict and executive summary](00-verdict-and-executive-summary.md) | Is it plausible, which model, what to build, what couldn't be checked |
| 01 | [@bletdemonjh and the AI Roblox wave](01-bletdemonjh-and-the-ai-roblox-wave.md) | What could and couldn't be found about the account; the "AI built my Roblox game" posts around it |
| 02 | [Opus 5.5 vs GPT-6 Astra](02-models-opus-5-5-vs-gpt-6-astra.md) | Prices, vendor benchmarks, Roblox's own Luau benchmark, failure modes, a bake-off protocol |
| 03 | [AI tooling and workflow](03-ai-tooling-and-workflow.md) | Studio's built-in MCP server, Assistant, Script Sync vs Rojo, toolchain versions, third-party tools, policy |
| 04 | [Case studies](04-case-studies.md) | 17 AI-built Roblox projects: successes, failures, hype and backlash |
| 05 | [Market and economics](05-roblox-market-and-economics.md) | Platform numbers, cash-out rates, the discovery algorithm, the 2026 publishing gate, costs |
| 06 | [Story-driven games on Roblox](06-story-driven-games-on-roblox.md) | What worked and failed for narrative and horror games, and the best openings for a story-first studio |
| 07 | [Assets, licensing and pipeline](07-assets-licensing-and-pipeline.md) | Using owned packs legally, Creator Store, import limits, AI asset tools, commissioning, security audits |
| 08 | [Action plan](08-action-plan.md) | Two tracks, the first game, an idea scorecard, week-by-week steps, budget, decision gates |
| 09 | [The Roblox vibe](09-the-roblox-vibe.md) | What makes a game read as "a Roblox game" in 2025–2026: avatars, build style, UI, social signals, store pages, and ranked changes for Last Ferry |
| 10 | [Roblox-vibe case studies](10-roblox-vibe-case-studies.md) | How the closest games (Scary Shawarma Kiosk, Animal Hospital and others) look and present themselves, and what made them work |
| 11 | [Roblox-look engine facts](11-roblox-look-engine-facts.md) | Verified engine details: the stock R6/R15 rigs, animating NPCs, bubble chat, player characters in a booth, fonts and UI kit, built-in content, lighting |

## How this was researched, and its limits

- **09–11** came later, when the first build didn't look like Roblox: three
  research agents covered the platform's identity, the closest games, and the
  engine facts, reading Roblox's docs source, API dump and client scripts
  directly where they could.
- **Parallel research.** Five research agents each covered one area (03–07).
  I wrote 00, 01, 02 and 08, checked the key facts in the others, and fixed
  what was wrong or out of date. For example, the story report had cited MCP
  tools from the archived server.
- **Most of the web was blocked.** This environment's network policy blocked
  x.com, roblox.com, the DevForum, Reddit, YouTube, Wikipedia and most news
  sites. GitHub, raw.githubusercontent.com and anthropic.com were reachable, so:
  - **Roblox's official documentation** was read from its source repository
    (`Roblox/creator-docs`, at its 2026-09-29 state), along with its benchmark
    repo, its starter project, and toolchain source and changelogs.
  - **Anthropic's model announcements** were read directly.
  - **Everything else** comes from search-engine result summaries. The web-search
    budget shared by all agents (200 calls) ran out partway through.
- **Every claim in 03–07 carries a confidence tag.** The letters vary slightly by
  file, and each file explains its own. The general meaning:

  | Tag | Meaning |
  | --- | --- |
  | V / A / DOC / VERIFIED | Read in a primary source this session |
  | S / SNIPPET / SECONDARY | Seen only in a search summary or a secondary source |
  | B / D / MEMORY | Background knowledge; check before relying on it |
  | C / EST | The author's own arithmetic |

- **X post dates** were computed from the post IDs, which encode a millisecond
  timestamp, so they are exact.
- **Not legal advice.** Licensing sections are a careful reading of public
  terms. Read the listed licence pages yourself before shipping.

## Open follow-ups

1. **@bletdemonjh's posts.** Paste them, or allow `x.com` in the environment's
   network settings, and they'll be folded into 01.
2. **Live numbers.** Current top games and player counts (RoMonitor, Rolimons),
   Roblox Plus pricing, and ad costs, once those sites are reachable.
3. **Luau benchmark scores for Opus 5.5 and GPT-6 Astra.** Run OpenGameEval
   yourself (commands in 02) or watch the leaderboard.
