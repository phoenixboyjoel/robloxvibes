# Action plan: Phoenix Feather's first 90 days building Roblox games with AI agents

This plan pulls together files 01–07 into what to do next. It assumes Joel plus
coding agents (Claude Code with Opus 5.5, and/or Codex with GPT-6 Astra), a
small budget, and the starter in [`starter/`](../starter/README.md).

## Operating principles

1. **Treat each game as a cheap experiment, not a bet.** Roblox earnings follow a
   power law: the top 1,000 creators take about 85% of payouts, and most games
   earn nothing ([05](05-roblox-market-and-economics.md)). The winning move is
   fast, cheap releases with clear kill-or-continue numbers.
2. **Build for retention, not short-term monetization.** In 2026 the Home
   recommender ranks on the following, and cuts impressions for games that
   monetize at the expense of retention:
   - how often people who see the game on Home click through
   - how many leave in the first 60 seconds
   - how many days players come back (day 1, days 2–7, days 8–28)
   - how often friends come back to play together
3. **Be original.** Roblox now says near-copies of existing games are "no longer
   prioritized", and AI is flooding the platform with cheap games. Your story, your
   characters and your art direction are the moat, not your build speed.
4. **Split the work by what each side is actually good at:**
   - **Agents:** systems code, content variation, working UI, tests, asset
     conversion, security audits, bookkeeping.
   - **Humans:** fun, difficulty, pacing, scare timing, art direction, icons and
     thumbnails, character design, gameplay animation, community.
5. **Compliance and security are part of the build.** That means:
   - server-authoritative code
   - session-locked saves
   - an accurate maturity questionnaire
   - audited third-party assets
   - no IP you don't own

## Two tracks

| | Track A: "cash" games | Track B: the story flagship |
| --- | --- | --- |
| What | A trending mechanic with a real twist, designed for retention (timers, daily goals, co-op) | Original characters and a world that can grow (anthology hub, anomaly-shift series, procedural co-op run) |
| Size | 2–6 weeks each, 2–4 a quarter | Months, released in episodes |
| Kill rule | Fast, on retention numbers | Iterate on retention before adding content |
| Money | Passes, developer products, rewarded ads | Chapter-pass subscription (priced in local currency: 70% to you in month 1, 100% after), cosmetics, revives; later merch and licensing |

## Recommended first game: an "anomaly shift" micro-horror

This is an example to measure your own ideas against, not an instruction to drop
them.

**Update:** this one has been built as
[Last Ferry](../games/last-ferry/README.md) (night ticket window, five nights,
four endings, one to four players). It passes every automated check. It is
waiting for its first Studio playtest
([PLAYTEST.md](../games/last-ferry/PLAYTEST.md)).

**Why this format.** *Scary Shawarma Kiosk*, made by one developer, reached about
1.3B visits in roughly 13 months ([06](06-story-driven-games-on-roblox.md)).
The format suits this studio and these tools:

- It is mostly logic, data and UI, which is where agents are strong.
- The story lives in the rules, which fits "interesting stories via interesting
  gameplay".
- It's cheap to extend: a new anomaly is mostly data.
- It sequels naturally ("[CHAPTER 2]", a new location).
- It can stay within Mild or Moderate fear, so it can reach players under 16.

**Sketch.**
- **Setting:** a mundane night job with one uncanny rule.
- **Structure:** 5–7 nights, 10–15 minutes per run, each night adding anomalies
  and a slice of the mystery (radio logs, notes, a regular who changes).
- **Character:** one named character designed as future IP: the manager, the
  regular, or the thing in the freezer.
- **Endings:** 3–6 plus a secret one, each with a badge.
- **Players:** solo or 2–4 co-op, with one checking and one serving.
- **Monetization:**
  - capped revives
  - cosmetics that fit the world
  - private servers
  - from 2,000 monthly visitors, an optional rewarded ad between nights for a
    free revive token. Roblox forbids using ads as a progress gate.

**The starter already covers part of it.** Server-side dialogue state and
validated choices ([`starter/`](../starter/README.md)) are the backbone of rules
cards, NPC conversations and ending tracking.

## Checking your own ideas

Score each idea 0–2 on each line. Prototype anything that scores **14 or more**.

| # | Question |
| --- | --- |
| 1 | Can a ten-year-old repeat the premise in one sentence? Does the title work as that sentence ("99 Nights in the Forest")? |
| 2 | Is there a replay engine: procedural rooms, runs, roles, several endings? |
| 3 | Is it more fun with friends, and does it give them a reason to come back together? |
| 4 | Is the story told through rules and mechanics rather than cutscenes? |
| 5 | Does it work on a phone, muted, in 10–20 minute sessions? |
| 6 | Does the content fit Mild or Moderate maturity (or is 18+ a deliberate choice)? |
| 7 | Is all the IP yours: no anime, brainrot or licensed characters? |
| 8 | Can it make money without charging for story or endings? |
| 9 | Is most of the work logic, data and UI (cheap for agents), not bespoke art and animation? |
| 10 | Can you say what ships every 2–4 weeks after launch? |

## Week by week

### Days 1–2: set up (see [`starter/README.md`](../starter/README.md))

- Create the **Phoenix Feather Studios** Roblox group. The group owns every
  game and asset.
- Verify Joel's account (government ID if 18+) and turn on 2-step verification
  everywhere.
- Turn on **Asset Privacy** for the group before importing anything.
- Decide **AI data sharing** per game. It's on by default; turn it off for games
  that contain third-party packs.
- Make a **quarantine place** for vetting Creator Store and contractor assets.
- Install Roblox Studio, Git, Claude Code and/or Codex CLI, and Rokit.
- Copy `starter/`, connect Script Sync or Rojo, and connect the Studio MCP
  server. Run the three check prompts, then play the Keeper demo yourself.

### Week 1: choose the model, sort the assets, write the design

1. **Model bake-off** (protocol in [02](02-models-opus-5-5-vs-gpt-6-astra.md)).
   Run the same ten tasks through both agents and score them. Pick a primary
   and keep the other as reviewer.
2. **Asset licence triage** ([07](07-assets-licensing-and-pipeline.md)).
   - List every pack you own in `assets/manifest.csv` and rate it green, yellow
     or red.
   - Email the publishers of the yellow ones; the template is in 07 §1.6.
   - Upload nothing red.
3. **Design the game.** Write `GAME_DESIGN.md` for game #1, and one-page versions
   of your other ideas, scored with the table above.

### Weeks 2–4: build a playable slice of game #1

- Ask the agent for a phase plan, then run each phase through the loop in
  `AGENTS.md`:
  1. plan the phase
  2. explore the game tree
  3. make the change
  4. verify it in a playtest
  5. run the checks
  6. update `ARCHITECTURE.md`
  7. you play it
  8. commit
- Build the **reusable narrative kit** once, then reuse it in every later game:
  - dialogue (started in the starter)
  - rules card
  - night/shift director
  - endings and badges manager
  - revive and shop
  - analytics events
- Commission the **icon and thumbnail** (roughly $20–200 per piece). Click-through
  from Home is the first ranking signal, and art is where AI is weakest.
- End of week 4 gate: **five people outside the studio play it cold.** If they
  don't finish a night and ask to play again, fix the first three minutes before
  building anything more.

### Weeks 5–6: launch (every new game starts 16+ only)

- **Before publishing:**
  - Answer the maturity questionnaire accurately.
  - Make sure all assets passed moderation at least a day earlier.
  - Re-run the security audit on the whole place.
  - Test on a cheap Android phone.
- **Publish.** New games are visible only to age-checked players aged 16+ at
  first.
- **Get the first players:**
  - Seed a Discord and short TikTok or YouTube clips.
  - Run small Ads Manager tests aimed at 16+ players; anecdotally $50–500 a day
    for a few days.
- **Open it to under-16s:**
  - Pay the refundable 1,000 Robux fee (or hold Premium/Plus for 2 months).
  - Reach **250 unique plays by highly engaged players within 60 days**.
  - Pass Roblox's safety review.
- **Track:**
  - Home click-through
  - share of players leaving before 60 seconds and before 3 minutes
  - day-1 and day-7 return rates
  - session length
  - share of players reaching the first ending

### Weeks 7–12: iterate or stop; start the next game

- **Ship an update every 2–4 weeks.** Roblox recommends small updates every 2
  weeks to a month, each taking under 3 weeks of work. Every update gives the
  recommender a fresh reason to test the game.
- **Kill-or-continue heuristic** (replace with your Creator Hub benchmarks once
  you have 100+ daily users):
  - After about 5,000 organic plays, if **day-1 return is under ~20–25%** or
    **day-7 return is under ~5–7%**, rework the first three minutes.
  - If two updates don't move those numbers, stop and put the kit into game #2.
- **Start game #2** or an anthology hub that reuses the kit. An anthology hub is
  one game with new 10–15 minute episodes every 2–4 weeks and a character who
  hosts them.

## First-game budget (estimates, tagged in 05 and 07)

| Item | Estimate |
| --- | --- |
| Agent usage | A Claude Code and/or ChatGPT/Codex plan, or API pay-as-you-go. Opus 5.5 costs $4/$20 per million tokens. One published head-to-head spent $7–15 per full small-game build; real iteration costs many times that |
| Asset packs | $200–800 |
| Commissions (icon/thumbnail, character set, 10–20 animations, map polish) | $800–3,000 |
| AI asset tools (one 3D generator, one audio tool) | $25–60 a month, cancelled between bursts |
| Roblox fees | 1,000 Robux refundable fee to reach under-16s (about $10 of Robux) |
| Launch ads and seeding | A few hundred dollars |
| **Total** | **About $1,500–5,000 plus Joel's time** |

## Things not to do

- Clone a trending game one-for-one. It gets deprioritized, and 2026 punishes it.
- Ship anything built on anime, meme or brainrot IP you don't own.
- Insert free models without the audit, or let an agent insert assets outside the
  quarantine place.
- Let an agent publish, change live DataStores, or run Open Cloud writes without
  your approval.
- Believe "one-shot" claims, including your own agent's. It isn't done until
  you've watched it work in a playtest.
- Let an agent run with no budget or stopping point.
- Treat the maturity questionnaire as a formality. A wrong rating can lock out
  your audience overnight; Pressure did in May 2026.
- Build without written IP assignment from every contractor, or let anyone but
  the studio group own the games and assets.

## Decision gates

| When | Question | If no |
| --- | --- | --- |
| End of week 1 | Did one model clearly win the bake-off? | Use Opus 5.5 as primary and Astra as reviewer; revisit next month |
| End of week 4 | Do people outside the studio finish a night and want another? | Rework the first three minutes; cut scope |
| Launch + 2 weeks | Are day-1 and day-7 returns above your thresholds? | Two updates aimed at retention, then stop |
| Day 90 | Does anything show traction? | Keep the kit, pick the best-scoring idea, repeat with what you learned |
