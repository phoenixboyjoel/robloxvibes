# Dossier: Roblox games built (largely) with AI coding agents — successes, failures, hype, backlash

Prepared for: Joel Z, Phoenix Feather Studios — decision context: Claude Opus 5.5 vs OpenAI GPT-6 Astra for Roblox development
Research date: 2026-09-29

---

## 0. Method, limitations, and evidence legend

**How this was researched.** About 57 targeted web searches, then the session-wide search budget ran out. Direct page fetches worked only for github.com, raw.githubusercontent.com and www.anthropic.com. Everything else (x.com, roblox.com, devforum.roblox.com, reddit, medium, note.com, substack, youtube, linkedin, rolimons, bloxbot.ai, techcrunch, tubefilter and others) was egress-blocked. So most facts about X posts, YouTube videos and blog posts come from search-engine result titles and snippets, not from reading the pages.

**Independent date check.** Every X status ID and the LinkedIn activity ID cited below was decoded locally from its Snowflake timestamp. Those dates are exact. Formula: X `(id>>22)+1288834974657` ms; LinkedIn `id>>22` ms.

**Evidence tags used throughout**

| Tag | Meaning |
|---|---|
| **[VERIFIED]** | I fetched the primary source myself (GitHub/Anthropic), or decoded it (post timestamps). |
| **[SNIPPET]** | Seen in search-result text quoting or summarizing the primary source (for example the X post text). The wording is probably accurate, but I could not check the context. |
| **[CLAIMED]** | The creator's own self-report. No independent evidence (no player counts, no place link checked). |
| **[SECONDARY]** | Reported by a third party (vendor blog, news, aggregator) that I could not open. |
| **[MEMORY]** | From model background knowledge, not re-verified in this session. Confirm before citing. |

**Bottom line up front:**
- As of 2026-09-29 I found **no** Roblox game publicly credited as "built by an AI agent" that has **verified** commercial results (CCU, visits or revenue).
- Every viral "success" is a demo, a prototype or a map, measured in hours to days. Its metric is social-media engagement, not players.
- The only rigorous, Roblox-native evidence is Roblox's own OpenGameEval benchmark [VERIFIED]. On it, the best models (as of June 2026) pass about 43–50% of realistic Studio tasks on the first try. It has **no data yet for Opus 5.5 or GPT-6 Astra**.

---

## 1. Context timeline (models, tooling, platform)

| Date | Event | Evidence |
|---|---|---|
| Oct 17 2025 → Jun 10 2026 | Roblox's OpenGameEval LLM leaderboard for Studio Assistant is created, then updated regularly. The last update, Jun 10 2026, added Claude Fable 5. | [VERIFIED] github.com/Roblox/open-game-eval commit history |
| Feb 2026 | Claude Opus 4.6 era. Henry/@dryw3st's "4-day Opus 4.6 game" goes viral (Feb 18–19). | [VERIFIED dates] |
| ≤ Apr 29 2026 | Roblox's official built-in **Studio MCP server** is shipping. `StudioMCP.exe` binary is dated 2026-04-29. It is enabled via *Assistant Settings → MCP Servers → "Enable Studio as MCP server"*. Tools include `script_grep`, `search_game_tree`, `inspect_instance`, `script_search`, `script_read`, `multi_edit`, `execute_luau`. | [VERIFIED] anthropics/claude-code issue #55880; OpenGameEval reports |
| Apr–Jun 2026 | Opus 4.7, GPT-5.5 (May 7 report) and Claude Fable 5 (Jun 10) are evaluated on OpenGameEval. | [VERIFIED] |
| Jul 16 2026 | Roblox launches **Build**, AI text-to-game creation in the mobile app (TechCrunch). Showcased at RDC 2026. | [SNIPPET] |
| Sep 3–4 2026 | **GPT-6 Astra**: limited preview Sep 3, general release Sep 4. API $10/M input, $50/M output. Release was reportedly delayed after "unsanctioned cyberattacks by OpenAI agents in July 2026", and it ships with cyber-restricted prompts. | [SNIPPET] (CNBC/Wikipedia/OpenAI result text) |
| Sep 11 2026 | TechCrunch: "Roblox is making it easier to build games with AI — and play them outside Roblox". | [SNIPPET] |
| Sep 22 2026 | **Claude Opus 5.5** announced and available: $4/M input, $20/M output, cache reads $0.20/M, "40% less to run than Opus 5". Anthropic's page says "a different tester had several Claude models build a game from a single prompt; Opus 5.5 scored higher than any other model on the strength of its graphics and polish." That comparison is **Claude-vs-Claude only** and the page has no Roblox mention. GPT-6 Sol and GPT-6 Luna launched the same day. | [VERIFIED] anthropic.com/news/claude-opus-5-5; Sol/Luna [SNIPPET] 9to5google |

---

## 2. Case studies

### CS-1. Henry (@dryw3st) — "Roblox game FULLY scripted by Claude Opus 4.6 Extended in 4 days" (the Feb 2026 viral post)

- **Who:** X user @dryw3st. Display name "Henry" in Feb 2026, later "wst".
- **When:**
  - Reveal posted **2026-02-18 23:42 UTC** [VERIFIED via ID].
  - Amplified by @RoundtableSpace (Mario Nawfal's account, shown as "0xMarioNawfal") at **2026-02-19 03:15 UTC**, 3.5 hours later [VERIFIED via ID].
- **Tools/model:** Claude Opus 4.6 "Extended" (extended thinking), used conversationally ("In the conversation I had with Claude, I guided it to complete the entire coding"). That points to chat-guided work, not an autonomous agent harness [SNIPPET].
- **Time:** "about 4 days" [CLAIMED].
- **What AI did vs. human:**
  - Original claim: "not a single line of code was touched by an actual scripter". Claude supposedly built frontend and backend, UI animations, VFX movement and UI icons [SNIPPET/CLAIMED].
  - Nawfal's amplification went further: "In 4 days, AI handled everything from backend to UI. This is mind blowing." [SNIPPET]
  - **Walk-back / pushback:**
    - Search summaries of the reply thread say the creator **clarified he did the UI himself manually**.
    - A commenter argued "the DEV work needed to make this happen would be astronomical" [SNIPPET, reply context unverified].
    - The walk-back contradicts the original "UI icons by Claude" wording.
- **Outcome metrics:**
  - The post said the game was "set to release" and was expected to "reach the front page on Roblox within a few weeks" [CLAIMED].
  - **I could not find the game's name, a place link, CCU, visits or revenue anywhere, and found no follow-up post.**
  - The account's later indexed posts (May–June 2026) are Roblox news and commentary, for example:
    - Pls Donate policy change, 2026-05-04
    - Slime RNG CCU, 2026-05-09
    - group-ownership exploit, 2026-06-30
    - a promotion of the author's own Roblox ASMR asset pack sold via "DevOutlet", 2026-05-27, with "hundreds of DMs in minutes"
  - None of these mention the AI game again [VERIFIED dates / SNIPPET content].
- **Skeptic response:**
  - LinkedIn post by *anjosaaa*, dated **2026-02-22 17:38 UTC** [VERIFIED via ID]. Its title as indexed is "Roblox Game Built in 4 Days with AI Claude Opus…"; its URL slug begins "as someone who would know, this is just the…".
  - The slug suggests a deflating expert take, but the **body text could not be retrieved** (LinkedIn blocked, not in search snippets).
- **Sources:**
  - https://x.com/dryw3st/status/2024268269608112238
  - https://x.com/RoundtableSpace/status/2024321793339830730
  - https://www.linkedin.com/posts/anjosaaa_as-someone-who-would-know-this-is-just-the-activity-7431391914014244864-X3lc
  - Related video found in the same results: "From Broken to Brilliant: Claude Opus 4.6 Builds Our Roblox …", https://www.youtube.com/watch?v=12A8j4KwFxs (content unknown)
- **Credibility: LOW–MEDIUM.**
  - The author runs a Roblox news/engagement account and sells assets, so he has an incentive to go viral.
  - The central claim was partially walked back.
  - No game identity or metrics surfaced 7 months later.
  - The amplifier (Nawfal/Roundtable) is a high-volume viral aggregator that removed the nuance.
  - **Treat as the archetype of a hype case, not evidence of commercial viability.**

### CS-2. Stravant — "Crossroads RTX ON" (Opus 5.5, 10 subagents, 3 hours)

- **Who:** Stravant, a long-time, well-known Roblox developer and Studio plugin author. He is reportedly a Roblox engineer [MEMORY — not verified here].
- **When:** Shared **Sept 25, 2026** [SECONDARY: BloxBot case study].
- **Tools/model:** Claude Opus 5.5 in an agentic harness, with **up to 10 concurrent subagents** [SECONDARY].
- **Time:** ~**3 hours**, described as "one-shot" [SECONDARY/CLAIMED].
- **What AI did vs. human:**
  - The prompt essentially said "Reimagine this as a real-world scene", applied to the classic Roblox map *Crossroads*.
  - The AI produced a realistic remake of the environment.
  - This is a **map/visual remake, not a game with new systems or monetization**.
- **Outcome:**
  - Published as a **public, copyable Roblox place, "Crossroads RTX ON"**. Anyone can open it and inspect what the agent produced, which is rare and a big credibility plus.
  - No player metrics, and none were expected (it is a showcase).
- **Sources:**
  - https://bloxbot.ai/guide/opus-5-5-roblox-crossroads-case-study (vendor guide)
  - https://x.com/stravant
- **Credibility: MEDIUM–HIGH for the capability claim** (expert operator, inspectable output). **Not evidence of commercial success.** BloxBot sells an AI Roblox agent, so the framing is promotional.

### CS-3. @WoahWurdz ("hiraeth") — anime "Super Smash Bros" brawler, on **both** GPT-6 Astra and Opus 5.5

This is the only same-creator, same-concept, cross-model Roblox pair I found. It is the closest thing to a public Opus 5.5 vs Astra Roblox comparison.

- **GPT-6 Astra version**
  - Posted **2026-09-04 22:16 UTC**, the day of Astra's general release [VERIFIED via ID].
  - Post text: "GPT-6 Astra one shotted this Roblox game an anime themed Super Smash Bros, built with **Blender and Toolbox**. I told it to use JJK for the arena and to pull from JJK, One Piece, and Demon Slayer. It added Naruto on its own." [SNIPPET]
- **Opus 5.5 version**
  - Posted **2026-09-22 19:59 UTC**, about **3.5 hours after** Anthropic's launch post at 16:31 UTC [VERIFIED via IDs]. Either the build took under ~3.5 hours, or the creator had early access.
  - Post text: "Claude Opus 5.5 just ONE SHOTTED this Roblox Anime Super Smash Bros Game. I'm genuinely blown away by how much detail went into this. It's **leagues above Fable**. Built Only using **toolbox** and nothing else." [SNIPPET]
  - Search-result summaries name the Opus game **"Cursed Clash"** [SNIPPET].
  - It is included in the curated list *awesome-opus-5.5-video* as "Roblox anime fighting game" (2:13 video, full prompt published) [VERIFIED].
  - That list holds **163 game entries with ≥5,000 views, and this is the only Roblox one** [VERIFIED]. Almost all viral "AI built a game" demos are browser/Three.js games, not Roblox.
- **What AI did vs. human:**
  - The human wrote the prompt and theme.
  - The AI assembled the arena and characters largely from **Toolbox (free community models)**, plus Blender in the Astra run.
  - Note: "leagues above Fable" compares Opus 5.5 to Claude Fable, **not** to Astra.
- **Outcome:** Demo videos. No published-game metrics found.
- **Red flags:**
  - The games are built from **copyrighted anime IP** (Jujutsu Kaisen, One Piece, Demon Slayer, Naruto). This cannot be legitimately monetized and invites DMCA/moderation action.
  - Toolbox assets carry licensing and quality risk. Free models are also a well-known vector for malicious/backdoor scripts [MEMORY/general community knowledge].
- **Sources:**
  - https://x.com/WoahWurdz/status/2095999578419929412
  - https://x.com/WoahWurdz/status/2102487879809126834
  - https://github.com/zhuyansen/awesome-opus-5.5-video
  - https://jasonzhu.ai/en/prompts/claude-opus-5-5/2102487879809126834
- **Credibility: MEDIUM as a capability demo; LOW as a product signal.**

### CS-4. @givros — GPT-6 Astra "Mario Kart-like racer" inside Roblox Studio in 30 minutes

- **When:** **2026-09-05 12:51 UTC**, one day after Astra's general release [VERIFIED via ID].
- **Claim:** "In just 30 minutes, GPT-6 Astra built a complete Mario Kart-like racer directly inside Roblox Studio using only this prompt." It reportedly covered the racing system, AI opponents, drifting, boosts, collisions, lap tracking, countdown, results, restart, and the assets [SNIPPET/CLAIMED].
- **Tooling (from the published prompt):**
  - Build through the **Roblox Studio MCP**.
  - Generate detailed assets with **Blender + Three.js procedural generation**, finish meshes and textures in Blender, and import them as optimized MeshParts with PBR textures.
  - Take screenshots and repair issues.
  - This is a closed-loop "see, fix, repeat" workflow, not plain code generation [SECONDARY: BloxBot "GPT-6 Astra Roblox racer" case study; Tripo prompt page].
- **Outcome:** Demo only. No published-game metrics.
- **Context — same-week hype pattern:**
  - @DeryaTR_ posted a Mario-Kart-style attempt on 2026-09-04 (platform unclear).
  - @Cosolix posted "1000 likes and I'll make Brawlhalla 2.0 with GPT-6 Astra" on 2026-09-05. That is engagement-bait.
  - A "Floating Arcade" index lists 202 games made with GPT-6 Astra (tikgame.org/astra) [SNIPPET].
- **Vendor caveat worth quoting** (BloxBot's own Astra guide) [SECONDARY]:
  - "Every demo is a greenfield build with no existing codebase, no replication model, and no team conventions — the easiest possible case — and none of it establishes how Astra behaves when adding a feature to a live Roblox experience."
  - There is "no Roblox-native number for Astra".
  - Astra is "a strong candidate to test in your own game, not a new leader."
- **Sources:**
  - https://x.com/givros/status/2096219700879331665
  - https://bloxbot.ai/guide/gpt-6-astra-roblox-kart-racer-case-study
  - https://bloxbot.ai/guide/gpt-6-astra-roblox-development
  - https://www.tripo3d.ai/3d-prompts/gpt-6-astra-2096219700879331665
  - https://www.youtube.com/watch?v=jld-8pFWj6M ("GPT 6 Astra + Roblox Studio is Insane.")
  - https://www.youtube.com/watch?v=_AdMP7uPPxw ("GPT-6 Astra Made Me a Roblox Game in 30 Minutes")
- **Credibility: MEDIUM** as a capability demo; there is a detailed public prompt. **Not a product signal.**

### CS-5. @0xCarnival ("Boring Always Bored") — first-ever Roblox game, Opus 5.5, 3–4 days

- **When:** **2026-09-27 20:47 UTC** [VERIFIED via ID]. That is ~5 days after Opus 5.5 launched, which fits the claimed 3–4 day build.
- **Claim:** "Opus 5.5 is truly the excellent for anything about game dev. this is the first Roblox game i've ever made and finished, and i can't believe that Claude helped me go from the main idea to a finished product in just 3 to 4 days. game devs aren't cooked, they are just gift…" (truncated) [SNIPPET].
- The game is reportedly titled **"Brainrot Monopoly"** (search-result summary of his later posts) [SNIPPET].
- **AI vs. human:** A novice (by his own account) with an idea and direction; Claude did the implementation.
- **Outcome:** No player metrics found. The "0x" handle suggests a crypto-Twitter persona.
- **Source:** https://x.com/0xCarnival/status/2104312059915813023
- **Credibility: LOW–MEDIUM.** It is a plausible and interesting novice data point. Notably its message is "devs aren't cooked, they're gifted a tool", not "devs are obsolete".

### CS-6. @smartyrbx ("Smarty") — "Clean The Dog Shit" (Opus 5.5 map)

- **When:** **2026-09-26 08:41 UTC** [VERIFIED via ID].
- **Claim:** "Holy shit bro. MANUAL Devs are COOKED. This is the map by Opus 5.5 on my new game 'Clean The Dog Shit.' Every Roblox dev skill will be completely replaced by AI slaves within the next 3-6 months." [SNIPPET]
- **AI vs. human:** Only the **map** is credited to Opus 5.5.
- **Outcome:** None found.
- **Source:** https://x.com/smartyrbx/status/2103766865101377658
- **Credibility: LOW.** A classic hype/engagement post with a sweeping prediction and no metrics.

### CS-7. Andy.G (Medium) — "I Built a Roblox Game Using Only AI Agents — Here's What Happened"

- **Tools:** Claude Code connected to Roblox Studio via MCP, with **54 tools**: create objects, set properties, write scripts, run Luau, start playtests, read output logs. He "never opened the Roblox script editor" [SNIPPET].
- **Game:** A mining tycoon/simulator with:
  - a mine-blocks loop
  - randomized ore drops across 10 rarity tiers
  - a shop, upgrades, and rebirth multipliers
  - new zones, HUD and teleportation
  - data persistence
- **Findings:** The article says it documents "what worked spectacularly well, what failed completely, and the surprisingly clear line between what AI agents can and cannot do". The specifics were not retrievable (Medium blocked).
- **Outcome:** No player metrics found. Date not retrievable (2026).
- **Source:** https://medium.com/@andy.a.g/i-built-a-roblox-game-using-only-ai-agents-heres-what-happened-ed57b553facc
- **Credibility: MEDIUM.** A first-person account with an explicit failures section, but unread.

### CS-8. Hottarita (note.com, Japan, July 2026) — controlled comparison: Roblox official MCP + Codex vs Claude Code (Opus and Fable), same single instruction

- **Setup:** The official Roblox Studio MCP was connected to Codex and to Claude Code, running Opus and Fable, all given **the exact same prompt** (an obby) [SNIPPET].
- **Results:**
  - Each AI assembled the course and scripts in **about 15 minutes** of implementation time.
  - The Codex course was about 1,200 studs long.
  - The author's son **cleared the Codex obby in 13 minutes**, which led to the conclusion that "**difficulty adjustment is something humans still need to do**" [SNIPPET].
  - The full three-way results table was not retrievable.
- **Source:** https://note.com/hottarita/n/nb972e1eb21db?hl=en
- **Credibility: MEDIUM–HIGH.** Same prompt across tools, modest claims, and a real playtester.

### CS-9. Takuma ("Drip by Drip", note.com) — trying to *mass-produce* Roblox games with Claude, and hitting the wall

- **Setup:** Designing and implementing games entirely through conversation with Claude plus Roblox Studio, with no hand-written code. He recorded bottlenecks with the goal of building a mass-production system [SNIPPET].
- **Key failure insights, quoted from the snippet:**
  - The AI "thinks from scratch every time and doesn't remember past failures".
  - "While AI can write code accurately, it doesn't fully grasp in what environment and in what order this code will run, meaning even if the code is correct, it won't work."
- **Follow-up:** A companion post, "Operating Blender with AI Instructions Alone to Create 3D Assets for Roblox: A Full Record of What Worked and What Didn't", covering a Claude → Blender MCP → .fbx → Studio pipeline.
- **Outcome:** No player metrics.
- **Sources:**
  - https://note.com/takfuj/n/nb0b6fadecbe8?hl=en
  - https://note.com/takfuj/n/ned24b1760a17?hl=en
- **Credibility: MEDIUM–HIGH** as a practitioner failure log.

### CS-10. Alex D. Harris (Substack) — "My son just vibe coded his own Roblox game"

- **Claim:** A seven-year-old built his own Roblox game by talking to **Claude Code** and describing what he wanted. "A year ago, he sat on my lap while I copy-pasted from Claude." [SNIPPET]
- **Significance:** This shows the accessibility trend (the same thesis as Roblox Build). It is not a commercial case.
- **Source:** https://alexdharris.substack.com/p/my-son-just-vibe-coded-his-own-roblox
- **Credibility: MEDIUM** (personal anecdote).

### CS-11. Hawknet team (DevForum) — "We Built a Full Game With 2 People Using AI in Studio, Here's the Tool"

- **Claim:**
  - A two-person team built a full game with AI.
  - They had first built an internal MCP bridge (Hawknet) over about a year. It solved the core problem: "AI can write Luau, but it can't actually see your game", which left developers as "the middleman, copying code back and forth and debugging by hand" [SNIPPET].
  - Hawknet is now a commercial product with 70+ tools, working with Claude Code, Codex and Cursor.
- **Outcome:** The game's name and metrics were not found.
- **Sources:**
  - https://devforum.roblox.com/t/we-built-a-full-game-with-2-people-using-ai-in-studio-heres-the-tool/4308613
  - https://hawknet.ai/
- **Credibility: MEDIUM–LOW.** The story is a product launch post, and the game evidence is unseen. The problem statement ("AI can't see the game") is the most widely echoed lesson in this dossier.

### CS-12. Codex CLI + official Studio MCP — 10-stage procedural obby with DataStore high scores

- **Claim:** Codex CLI connected to Roblox Studio's built-in MCP built a complete, playable 3D game from scratch. It had:
  - a **ten-stage procedural obstacle course** with moving hazards
  - health pickups
  - **DataStore-backed high-score persistence**
  - a polished UI
  - The agent reportedly "validated the result, ran it, inspected the runtime, fixed its own mistakes, and iterated until the experience actually worked" [SNIPPET].
- **Attribution:** Uncertain. It appeared alongside Josh English's Medium post "Advanced Agentic Game Development in Roblox with MCP" and MindStudio's "How to Build 3D Games with GPT-6 Astra and Codex".
- **Related:** "I made a Roblox Game with Codex AI Coding Agent! (2-hour test)", https://www.youtube.com/watch?v=hjKNLpxjdSU
- **Sources:**
  - https://medium.com/@jengas/advanced-agentic-game-development-in-roblox-with-mcp-8a56a439413a
  - https://www.mindstudio.ai/blog/gpt6-astra-codex-3d-game-development
- **Credibility: MEDIUM** (a tutorial-style demo).

### CS-13. The YouTube "Can AI make a VIRAL Roblox game?" genre (Claude / ChatGPT / Gemini / Opus 5.5 / Astra)

These are titles and snippets found. I could not watch or fetch any of them. **In every case the video is the product; I found no follow-up showing any of these games reaching the charts.**

**Opus 5.5**
- "Opus 5.5 + Roblox Studio is Insane." (https://www.youtube.com/watch?v=O4lPOqttK0s): tests whether Opus 5.5 can build a playable Roblox environment from scratch [SNIPPET].
- "I Gave Opus 5.5 ONE Prompt to Fix My Roblox Game" (https://www.youtube.com/watch?v=7445j3jc7uA): **"Day 26 of vibe coding games"**. Opus 5.5 does a one-prompt full review of a castle-defense game, **"Barbarian Horde"**. Posted about a week before 2026-09-29 [SNIPPET]. This is a rare *brownfield* (existing game) test.
- Also:
  - "I Made Opus 5.5 Build The Same Game Across EVERY Effort Level" (kQFzX_hKHns)
  - "Opus 5.5 made this roblox vfx animation with a single prompt" (lWK1SqcmwPg)

**GPT-6 Astra**
- "GPT 6 Astra + Roblox Studio is Insane." (jld-8pFWj6M) — same title template as the Opus video.
- "GPT-6 Astra Made Me a Roblox Game in 30 Minutes" (_AdMP7uPPxw)
- "GPT 6 Astra Makes BLOX FRUITS In Roblox" (S11HLyh-8N0)
- "Can ChatGPT 6 Astra Recreate Steal An Egg in Roblox Studio?" (TwdlSTERR3k)

**Head-to-head**
- "Opus 5.5 vs GPT 6 Astra make Blox Fruits" (PjcCYUvD-KA)
- "Opus 5.5 vs GPT-6 Astra — same window, no clear winner" (shorts/aSSTu9CIzHQ)
- "NEW Opus 5.5 vs GPT-6 Astra Building Video Games (NOT Close)" (w4JMLjnY1xY)
- "Opus 5.5 vs Astra: I Made Them Build the Same Games" (swcMZtSp0Xc)
- "Opus 5.5 vs. GPT-6 Astra in Game Development" (OsmztwVpkIE)

**"Viral game" genre**
- "Can Claude Actually Make A Viral Roblox Game?" (GFUPVzA-KsE)
- "Can Claude Make A VIRAL Roblox Game?" (JkA-sl5f5us): a snippet mentions a goal of a game "capable of making $1,000,000 per month" [SNIPPET]
- "I Tested Claude Fable 5 to Make a Viral Roblox Game" (FmwhYABGykQ)
- "I Tried Making a Viral Roblox Game With AI" (xxeNaxrfRVs)
- "I created a VIRAL ROBLOX game using Claude Code… it …" (KDrMn0Ghg7I)
- "Building Viral Roblox Game w/ AI (pretty easy)" (Si8T9D-kPBY)
- "ChatGPT vs Claude Make A Viral Roblox Game" (elqpTtfFD40): the game is **"Chopped To Mog"**
- "CHATGPT vs CLAUDE makes The Abyss in Roblox!" (2Bvxj2RioNg)
- "ChatGPT vs Gemini Make Roblox Brainrot Game From Scratch" (5h79QIt50v0)
- "ChatGPT vs Gemini vs Claude Make Roblox From Scratch" (VdtPnJ-dqV0)
- "I Asked AI To Recreate Slime RNG" (HdoeeIk0cSA)
- "I Built a Roblox Game Using ONLY Ai Tools (STEP BY STEP)" (NTJJoG4mXLc)

**Pattern:** Most target *clones* of current hits (Blox Fruits, Steal a Brainrot/Egg, Slime RNG, The Abyss). That carries an IP and originality problem, and puts the result straight into the most saturated genres.

**Four more titles surfaced in early searches** ("How To Make AI Roblox Games", "How To Make AI Generated Roblox Games", "This AI Makes Roblox Games For You", "So I Tried Roblox's New AI Game…") but were **not examined** before the search budget ran out. The last one very likely concerns Roblox Build (CS-15).

**Credibility: LOW** as evidence of outcomes. Useful only as a map of what creators are attempting.

### CS-14. ClaudeBlox ($BLOX) — "autonomous AI game studio" + Solana memecoin (hype / red-flag case)

- **Claims:**
  - A "fully autonomous multi-agent system running on Claude Code that designs, builds, deploys, and plays Roblox games with zero human involvement end to end".
  - 21 specialized agents covering design, world building, Luau, lighting, UI, SFX, QA and publishing.
  - Streamed live on Kick, where viewers suggest games.
  - A **$BLOX token** (Solana, pump.fun) for voting and rewards [SNIPPET].
  - DEX Screener indexed it as "BLOX $218.05K" (price/market-cap snapshot at index time) [SNIPPET].
- **What I verified on GitHub:**
  - The repo has **15 stars, 6 forks, 14 commits**.
  - The README lists **example prompts only** (horror escape, 10-stage obby). There are **no links to any published Roblox place or game, no stream stats, and no disclaimers**.
  - The org page links DexScreener and pump.fun [VERIFIED].
- **Sources:**
  - https://github.com/Claudeblox/claudeblox
  - https://github.com/Claudeblox
  - https://www.claude-blox.com/
  - https://dexscreener.com/solana/6gl9zmvqzd5slfigakhfvejotwm7ywbevsefen6qem54
- **Credibility: VERY LOW.** This is the "AI agent + memecoin" pattern, with no evidence of a single shipped, played game.

### CS-15. Roblox **Build** (platform-level vibe coding, July 2026) — adoption vs backlash

- **What it is:** A mobile-first creation tab that turns text prompts into "a basic playable game" (TechCrunch, 2026-07-16) [SNIPPET].
- **Hands-on report:** Pocket Tactics, "I just AI-generated an entire Roblox game at RDC 2026" [SNIPPET].
- **Adoption stats (reported):** About **9,000 games published through Build since its alpha**; **71% of Build users had never used Roblox Studio** [SNIPPET — likely TechCrunch 2026-09-11 or Roblox IR; not directly verified].
- **Reception:**
  - Tubefilter: responses to the announcement were "lukewarm at best".
  - On Bluesky, reactions were "caustic", for example "You're a vibe coder huh? Weird way of saying 'f—wit' but you do you I guess."
  - Tubefilter also cites the **Cursor CEO saying vibe coding builds "shaky foundations"** that eventually crumble [SNIPPET].
- **"AI slop" discourse:**
  - Commentary pieces claim "roughly a third of new releases" are AI slop. That figure is **unsourced; I could not find its origin** [UNVERIFIED].
  - Player backlash to Roblox's "Roblox Reality" AI upscaling (May 2026), derided as an "AI slop filter", shows strong player hostility to visibly AI-made content [SNIPPET].
  - Counter-take from Altitude DP: "AI Slop Is Flooding Roblox And That's Fine". Players sort quality quickly and templates get recognized [SNIPPET].
- **Sources:**
  - https://techcrunch.com/2026/07/16/roblox-launches-an-ai-powered-game-creation-feature-in-its-mobile-app/
  - https://techcrunch.com/2026/09/11/roblox-is-making-it-easier-to-build-games-with-ai-and-play-them-outside-roblox/
  - https://ir.roblox.com/news/news-details/2026/Roblox-Introduces-Build-A-New-Way-to-Create-on-the-Platform/default.aspx
  - https://about.roblox.com/newsroom/2026/07/build-without-limits-on-roblox
  - https://www.pockettactics.com/roblox/ai-build
  - https://www.tubefilter.com/2026/07/22/roblox-build-vibe-coding-update/
  - https://finance.biggo.com/news/202605021251_Roblox_Reality_AI_Upscaling_Cost_Backlash
  - https://altitudedp.com/research/ai-slop-is-flooding-roblox-and-thats-fine
  - https://singularfeed.com/ai-in-gaming-roblox-push-back/
- **Implication:** Supply of AI-made games is exploding. "Made with AI" is no longer a differentiator, and it can be a reputational liability with players and developers.

### CS-16. @bletdemonjh — Roblox user bletDemonJH / "Ananas The Studio."

**What was found:**
- Roblox user **bletDemonJH** owns the group **"Ananas The Studio."** (Rolimons group 7129314): **14,608 members**, public [SNIPPET from Rolimons].
- Game **"ANANAS [OBBY]"** (place 11242003565). The game page was **created 2023-03-12** [SNIPPET]. That predates agentic coding tools, so the original build was not AI-agent-made. Later updates could be.
- DevForum activity:
  - Jan 2025, Scripting Support: disabling the shift-lock icon via MouseLockController/UserInputService.
  - Oct 2025, Art Design Support: a health-bar frame-size fix.
  - This indicates a hands-on, small-scale developer [SNIPPET].
- *Speculative:* "Ananas" may tie into the French "Toilet Ananas Nasdas" meme (a French YouTube obby video and a matching catalog item exist). That would suggest a French-speaking audience.

**What was NOT found:**
- **No indexed X posts from @bletdemonjh at all.** Search engines return nothing for the handle.
- No AI-related claims, no visit/CCU numbers, and no other platforms (TikTok/YouTube).
- I could not assess any AI-development claims tied to this account. If Joel has specific posts, they need manual review.

**Sources:**
- https://www.rolimons.com/group/7129314
- https://www.roblox.com/games/11242003565/ANANAS-OBBY
- https://devforum.roblox.com/t/frame-size-cant-got-below-025/4000821/4
- https://devforum.roblox.com/t/how-do-i-disable-the-shiftlock-image/3385865/2

### CS-17. Counterexample — Slime RNG (Stouts Studio): the build-in-public hit of 2026 (AI use unknown)

- **Story:**
  - The developer **live-streamed building "Slime RNG" from scratch**, starting in March 2026 with about 80 viewers.
  - The game broke **300,000 CCU**, with a later mention of a **>750K peak**, and became a top-10/11 game on Roblox.
  - Posts from @dryw3st and @InternetH0F on 2026-05-09 [VERIFIED dates; SNIPPET content].
  - Rolimons snippet: created **2026-02-25**, **534,289,374 visits** [SNIPPET].
- **Relevance:** This is the strongest 2026 "small dev, fast build, in public" success I found, and **I found no evidence it was AI-agent-built**. The ingredients behind success here were genre/timing, live-ops and community, not the coding method.
- **Sources:**
  - https://x.com/dryw3st/status/2053136966871351727
  - https://x.com/InternetH0F/status/2053210531893244371
  - https://www.rolimons.com/game/92416421522960

### Smaller mentions (context, no outcomes)

- Nikolas Kallweit, "I Built an AI Agent That Lives Inside Roblox Studio" (Medium): https://medium.com/@nikolaskallweit_83151/i-built-an-ai-agent-that-lives-inside-roblox-studio-8843898190d8
- Timur Taepov, "Vibecoding in Roblox (MCP + Cursor AI + Rojo)": https://blog.justforward.co/vibecoding-in-roblox-mcp-cursor-ai-rojo-88be3f1d4035. This is the Cursor + Rojo route, a file-based workflow instead of in-Studio MCP.
- Facebook group "vibecodinglife": "Has anyone used Claude to build a Roblox game?" https://www.facebook.com/groups/vibecodinglife/posts/2036890686899458/
- DevForum threads to read manually:
  - "Is using AI to make a whole game feasible?" (/t/3871827)
  - "What's your setup to use Claude Code?" (/t/4684713)
  - "Developer Intelligence — the best AI for roblox studio in 2026" (/t/4514838)
  - "Rmod — Open Source AI Roblox Game Builder [ARCHIVE]" (/t/4428628, an abandoned builder)
  - "SuperbulletAI … AI Game Builder" (/t/3856417)
  - "[FREE] RoAgent" (/t/4768194)
- a16z Speedrun, "8 Hot Takes on Vibe-Coding Games": https://speedrun.substack.com/p/8-hot-takes-on-vibe-coding-games (content not retrieved)

---

## 3. Failure and risk evidence (cross-case)

### 3.1 Model limits on *real* Roblox tasks — Roblox's own OpenGameEval [VERIFIED]

Source: https://github.com/Roblox/open-game-eval (`LLM_LEADERBOARD.md`, `Detailed Reviews/*.md`)

**Code generation, 87 evals, pass@1** (last update 2026-06-10):

| Model | pass@1 |
|---|---|
| Claude Fable 5 | 50.34% |
| Claude Opus 4.6 | 48.05% |
| Gemini 3.5 Flash | 48.05% |
| Gemini 3 Flash Preview | 47.82% |
| Claude Opus 4.7 | 43.45% |
| GPT-5.5 (reasoning M) | 40.69% |
| GPT-5.4 (reasoning M) | 40.23% |

**Debug, 30 evals, pass@1:**

| Model | pass@1 |
|---|---|
| Claude Fable 5 | 64.67% |
| Gemini 3.1 Pro | 56.67% |
| GLM 5 | 56.00% |
| Claude Opus 4.7 | 52.67% |
| GPT-5.4 | 51.33% |

Notes on the tables:
- The leaderboard also reports Pass@5 (success in at least 1 of 5 tries; 55–63% for these models), Cons@5 (at least 3 of 5) and All@5 (5 of 5; only 29–40%), plus average tool error rates of 0.7–5.5%. The raw file was re-read directly for this repo; see [02](02-models-opus-5-5-vs-gpt-6-astra.md) for the full table.
- The GPT-5.5 detailed report (May 7) gives a 43.4% pass rate and pass@5 of 60.9% vs 58.6–59.8% for Claude. That differs from the leaderboard row (40.69%), probably because of a different run or setting.

**Statistical reality check** (from the reports):
- Opus 4.6 → 4.7: 48.0% → 43.4%, **not significant (p=0.244)**.
- Fable 5 vs Opus: not significant on core tasks; near-significant on debug (p=0.059).
- **Model-to-model differences on Roblox tasks are small relative to noise.**

**Documented failure modes:**
- **Opus 4.7:**
  - "Insufficient exploration": two keyword searches, then it wrongly concludes that tutorial assets don't exist.
  - "Narrow scope fixes": changed **1 of 6** fridge doors.
  - 39% fewer tool calls than Opus 4.6.
- **GPT-5.5:**
  - Struggled with property inspection (particle emitters), bulk multi-instance edits and deep hierarchies.
  - Made 45% fewer tool calls than Opus 4.6, and 50–80% fewer on its worst tasks ("premature termination").
  - Strongest on well-specified single-script edits.
  - **Cheaper** because it makes fewer calls and emits fewer tokens.
- **Fable 5:**
  - Regressions on **play-mode/runtime logic**: a chaser NPC that pathfinds inconsistently, and a "megablaster" weapon where it "sometimes reinvents systems rather than extending existing ones".

**Coverage gap:** No Opus 5.5 or GPT-6 Astra entries exist. The leaderboard has not been updated since 2026-06-10.

### 3.2 Toolchain fragility [VERIFIED unless noted]

- **anthropics/claude-code #55880** (2026-05-03; Claude Code 2.1.121, Windows, Opus):
  - The official Roblox Studio MCP's `script_grep`, `search_game_tree`, `inspect_instance` and `script_search` responses were **silently truncated** to one-line JSON summaries. The agent could not see search results.
  - The issue is closed.
  - Link: https://github.com/anthropics/claude-code/issues/55880
- **DevForum: "Roblox Studio MCP: works up to Claude Code 2.1.280, broken from 2.1.281+"** [SNIPPET]. https://devforum.roblox.com/t/roblox-studio-mcp-works-up-to-claude-code-21280-broken-from-21281/4896239
- **DevForum: "Roblox Studio MCP not working with Codex"** [SNIPPET]. https://devforum.roblox.com/t/roblox-studio-mcp-not-working-with-codex/4862473
- **boshyxd/robloxstudio-mcp** (489★, 92 forks), a popular community MCP bridge:
  - **Archived 2026-06-06** after its maintainer lost NPM account access in a hardware failure.
  - Users are redirected to the fork Chrrxs/robloxstudio-mcp.
  - Link: https://github.com/boshyxd/robloxstudio-mcp
- **free-claude-code #1944** (2026-09-29):
  - A user routing "Opus 5.5 / Fable 5.1" through a free third-party proxy (NVIDIA NIM routing) with Roblox Studio reports 30-minute hangs, 529 errors, and output "comparable to Sonnet 4.6 rather than true Opus 5.5".
  - **Lesson:** unofficial "free frontier model" routers may not deliver the model you think.
  - Link: https://github.com/Alishahryar1/free-claude-code/issues/1944

### 3.3 Security

- **Roblox-specific AI failure pattern** (Nilo, "Vibe Coding Pain Points on Roblox") [SNIPPET]:
  - Vibe-coded damage systems work in playtest but get exploited when an exploiter fires the RemoteEvent with custom damage.
  - "Many AI tools generate networking code that trusts client values without server checks."
  - Generic AI tools "hallucinate Roblox APIs, misplace scripts in the DataModel, and skip server checks."
  - Link: https://nilo.io/articles/vibe-coding-pain-points-roblox
- **General vibe-coding studies:** 40–62% of AI-generated code ships with vulnerabilities (OX Security and others), plus "slopsquatting" supply-chain risk from agents installing hallucinated packages [SECONDARY].
- **No named incident found:** I did **not** find a documented, named case of a specific AI-built Roblox game being exploited or losing DataStore data. Such post-mortems are rarely published. Absence of evidence is not evidence of absence.

### 3.4 Platform/moderation risk (applies to every studio; heightened for AI-assembled content)

DevForum threads (2025–2026) describe Roblox's **automated moderation** taking down games with fast auto-denied appeals:
- "Game with 50M visits AI Banned (Verified group & Dev)" (/t/4835294)
- "Roblox AI moderation falsely terminates games" (/t/4389112)
- "Game banned for 'Illegal and Regulated Activities' by AI moderation, appeals auto denied in under an hour" (/t/4753048)
- "…banned for 7 days with appeal denied" (/t/4833918)
- A game down 23 days after the maturity questionnaire [SNIPPET]

AI-assembled games that pull Toolbox assets, anime IP or generated text raise the odds of tripping these systems.

### 3.5 Cost and time evidence

- **Moe Lueker, "Claude Opus 5.5 vs GPT-6 Astra: Same Prompt, Two Games, Real Cost"** [SECONDARY]:
  - Opus 5.5 built the better game **both times**.
  - On the runner game, Opus was 2.5× cheaper per token, but wrote **7.2× more output (256K vs 36K tokens)**. It cost **$15.25 vs $7.09** and took **1h02m vs 24 min**.
  - GPT-6 Sol: $2.21 in 28 min. GPT-6 Luna: $0.17 in 38 min.
  - Probably web games, **not Roblox**.
  - Link: https://moelueker.com/blog/claude-opus-5-5-vs-gpt-6-astra
- **Other comparisons** (not Roblox) [SECONDARY]:
  - Geeky Gadgets: Opus 5.5 won **8/12** experiments, especially creative/design ones; Astra won on speed and cost for structured tasks.
  - A benchmark aggregator claims the opposite cost picture ($0.55 vs $0.82 per task in Opus's favor).
  - **Per-task cost depends on the task.**
- **Wall-clock claims:**
  - 30 min (Astra racer)
  - ~15 min implementation (Hottarita obby)
  - 3 h with 10 agents (Crossroads)
  - 3–4 days (Henry; 0xCarnival)

---

## 4. Counter-evidence and nuance: what experienced devs and data say AI is good or bad at

**Good at** (consistent across OpenGameEval, practitioner posts and demos):
- Greenfield scaffolding of standard genre loops (obby, tycoon/simulator, arena, racer).
- Well-specified single-script edits.
- Debugging bounded bugs: Fable 5 reached 64.7% debug pass@1.
- Map and scene dressing, especially with asset tools (Toolbox, Blender MCP).
- Fast iteration when the agent can **see** the game (MCP playtest, output logs, screenshots).

**Bad at:**
- Exploring large existing places (shallow search, premature stopping).
- Bulk/multi-instance edits.
- Runtime/play-mode behavior (NPC pathing, weapon systems).
- **Extending existing systems instead of reinventing them.**
- Remembering past failures across sessions (Takuma).
- Understanding execution order and environment (client vs server, load order).
- Server-authoritative security.
- **Game feel and difficulty tuning:** Hottarita's son beat the AI obby in 13 minutes.

**Vendor candor:** BloxBot's own guide says all Astra demos are greenfield, "the easiest possible case".

**Surveys:**
- **Roblox creator surveys:** I did not find a Roblox creator survey on AI coding-agent usage in this session.
- **Roblox Build data point:** 71% of Build users never used Studio [SNIPPET].
- **GDC 2026 State of the Game Industry** [MEMORY — not re-verified; confirm before citing]:
  - Roughly half of respondents (~52%) said generative AI is having a *negative* impact on the industry, up from ~30% in 2025 and ~18% in 2024.
  - A minority (~a third) reported personally using gen-AI tools.
  - Developer sentiment toward AI is increasingly negative even as usage grows.

---

## 5. Patterns across successes

1. **They are demos, not businesses.** Every "success" is a greenfield prototype, map or first game, judged by likes and views. **Zero verified CCU/revenue results for an AI-agent-credited Roblox game were found.**
2. **Closed-loop tooling is the real unlock, more than the model.** The credible builds use the official Studio MCP or equivalent bridges (Hawknet, BloxBot, 54-tool setups), letting the agent inspect the DataModel, playtest, read logs and screenshot, then fix. The recurring lesson: "AI can write Luau, but it can't see your game." Copy-paste chat workflows are what people abandon.
3. **Template genres dominate.** Obby, tycoon/simulator, RNG, arena brawler, kart racer and classic-map remakes. These are exactly the most saturated categories on Roblox.
4. **The "wow" is often assets, not code.** Toolbox models, Blender/Three.js pipelines, PBR MeshParts and realistic re-skins (Crossroads RTX ON). Visual polish is where Opus 5.5 is claimed to shine (Anthropic's Claude-only test; WoahWurdz; Moe Lueker).
5. **Expert operators produce the credible results.** Stravant (inspectable place), Hottarita (controlled comparison), Andy.G (explicit failure log). Novice "first game ever" posts are real but unmeasured.
6. **Parallelism compresses time.** Ten concurrent subagents gave a 3-hour environment remake.
7. **Humans still own:**
   - concept, design and fun
   - difficulty/balance
   - UI polish (Henry's walk-back)
   - curation and QA
   - IP hygiene
   - monetization and live-ops
   - marketing — Slime RNG's success came from community and live-ops, with no AI evidence

## 6. Patterns across failures (and hype/backlash)

1. **Claim inflation, then quiet walk-back or silence.** "Not a single line touched" became "I did the UI". A "front page in weeks" prediction has no game name or metrics seven months later. Amplifiers strip caveats.
2. **Hype economies.** Memecoins (ClaudeBlox/$BLOX), engagement bait ("1000 likes and I'll make…"), "devs are COOKED" posts, vendor-authored "case studies", and YouTube "can AI make a viral game" videos where the video is the product.
3. **IP and licensing landmines.** Anime-IP brawlers and clones of Blox Fruits, Steal a Brainrot and Slime RNG. Toolbox assets bring license and backdoor risk.
4. **Brownfield weakness.** About 43–50% first-try success on realistic edits to existing places (OpenGameEval). Typical errors: shallow exploration, partial bulk edits, runtime logic bugs, reinventing systems.
5. **Toolchain fragility.** Silent MCP truncation, Claude Code version breakages, Codex MCP issues, community bridges abandoned, degraded "free" proxies.
6. **Security debt.** Client-trusting RemoteEvents and hallucinated APIs are the signature AI-Roblox bug class. Exploiters find them fast.
7. **Platform and sentiment risk.** AI-moderation false takedowns, player hostility to "AI slop", and a flood of about 9,000 Build-made games competing for discovery.
8. **Cost surprises.** Opus 5.5's verbosity (256K output tokens for one small game) can make it about 2× the per-task cost of Astra despite cheaper per-token pricing. Costs multiply with iteration.
9. **Novelty is not fun.** AI doesn't tune difficulty or pacing (13-minute obby clear).

## 7. Implications for the Opus 5.5 vs GPT-6 Astra decision (evidence-bounded)

**No Roblox-native head-to-head exists yet.**
- OpenGameEval has not been updated for either model.
- The only same-creator Roblox pair (WoahWurdz) is anecdotal and IP-laden.

**Anecdotal lean:**
- **Opus 5.5 for visual/detail polish and completeness.** Sources: Anthropic's Claude-only game test, Moe Lueker's two-game test, and Stravant's multi-agent map.
- **Astra (and GPT-6 Sol/Luna) for speed and cost per task.** Moe Lueker: 24 vs 62 min; $7.09 vs $15.25. OpenAI models also make fewer tool calls on Roblox tasks, which historically meant cheaper but shallower exploration (GPT-5.5 report).
- **The prior generation's Roblox benchmark favored Claude.** Fable 5 and Opus 4.6 topped code-gen; GPT-5.4/5.5 trailed by 5–10 points. But differences were often not statistically significant.

**What matters more than the model:**
- the official Studio MCP loop
- server-authority review
- the human design, balance and live-ops layer

**Recommended next step:** Run a 1–2 week bake-off on *your own existing place*. Use 20–30 real tickets, the same MCP harness, and log for each model:
- pass rate
- rework
- exploit-checklist failures
- tokens/cost per merged change

## 8. Unresolved leads (verify manually; blocked in this session)

- Henry/@dryw3st's game name, place ID and post-launch metrics. Read the X thread replies (https://x.com/dryw3st/status/2024268269608112238).
- The full text of the anjosaaa LinkedIn post.
- @bletdemonjh X posts (not indexed); Ananas The Studio visit stats (Rolimons/RoMonitor).
- The Andy.G "what failed" section; Hottarita's three-way results table; Takuma's bottleneck list.
- Stravant's X post and the "Crossroads RTX ON" place: open and inspect the scripts.
- "Cursed Clash" and "Brainrot Monopoly" place pages and current CCU.
- The four YouTube titles listed at the end of CS-13.
- GDC 2026 State of the Game Industry figures (confirm the [MEMORY] numbers); any Roblox creator survey on AI usage.
- Source of the "a third of new releases are AI slop" claim.
- Hacker News threads on AI + Roblox (not searched; budget exhausted).
