# Claude Opus 5.5 vs GPT-6 Astra for Roblox work

## Bottom line

- **Both can build Roblox games through Roblox Studio's built-in MCP server.**
  Studio has one-click connections for Claude Code (Opus 5.5) and for Codex CLI
  (GPT-6 Astra).
- **Neither model has a Roblox-specific score yet.** Roblox's own benchmark was
  last updated before either launched.
- **Lean Opus 5.5 as the primary agent, and keep Astra as reviewer and fallback.**
  Then settle it with a one-week bake-off on your own game (below). The reasons
  for the lean are in the next section.
- **Your agent rules and your test loop will matter more than the model.**
  Roblox's benchmark reviews all say the same thing: the biggest failure modes
  go away with better instructions, not a better model.

## Why the lean is Opus 5.5

1. **Claude models lead the only Roblox benchmark.** On Roblox's OpenGameEval
   (June 2026), Claude Fable 5 was first and Opus 4.6 second on authoring. GPT-5.5
   and GPT-5.4 trailed by 5–10 points. Most gaps were not statistically
   significant, and on an older version of the benchmark a Gemini model led.
2. **Opus 5.5 is roughly Fable-class and cheaper.** Anthropic says it "performs
   at the level of Claude Fable 5.1 on most work" at $4/$20 per million tokens,
   against Fable 5.1's $10/$50.
3. **Roblox's own AI starter is written for Claude Code.** It ships guidance on
   writing a CLAUDE.md and an ARCHITECTURE.md.
4. **Polish.** In same-prompt tests, Opus 5.5 is reported to produce more
   polished, more detailed games.

## Why Astra is still worth running

1. **Speed and cost per task.** In the one detailed cost comparison found, Astra
   finished in 24 minutes for $7.09 against Opus 5.5's 62 minutes and $15.25.
   Opus wrote about 7× more output.
2. **Strong computer use** and a solid Codex harness.
3. **A cheaper tier.** Codex now defaults to GPT-6.1 Sol, which OpenAI describes
   as near-Astra at lower cost.

## The numbers

### What each costs and where it runs

| | Claude Opus 5.5 | GPT-6 Astra |
| --- | --- | --- |
| Released | 2026-09-22 (verified, Anthropic) | Preview 2026-09-03, general availability 2026-09-04 (news summaries) |
| API price per million tokens | **$4 input / $20 output**; cache reads $0.20; fast mode $8 / $40 (verified) | $10 / $50 (search snippet, **unverified**) |
| Context | Not stated on the launch page | 272K default in Codex, 872K max (Codex model catalog); OpenAI marketing says up to about 1.05M total (search snippet) |
| Effort levels | low, medium (default), high, xhigh, max | low → max, plus "ultra"; Codex defaults to low (Codex catalog) |
| Where you use it | Claude apps, **Claude Code**, API, AWS, Google Cloud, Azure | ChatGPT paid plans, **Codex**, API, AWS, Azure, GitHub Copilot (news summaries) |
| One-click Studio connection | Claude Code, Claude Desktop | Codex CLI |

Other Claude options:

- **Sonnet 5.5** (2026-09-28, $2/$10): cheap and fast for routine scripting.
  Anthropic reports it scoring close to Opus 5.5 on several benchmarks, while
  calling Opus clearly stronger on open-ended work.
- **Fable 5.1** ($10/$50): Anthropic's top general model.

### Anthropic's published comparison

These are vendor numbers. Anthropic itself notes that "benchmark margins have
become a less reliable guide to real-world differences."

| Benchmark | Opus 5.5 | GPT-6 Astra | Fable 5.1 |
| --- | --- | --- | --- |
| Terminal-Bench 4.0 (agentic coding in a terminal) | **66.4%** | 57.9% | 55.8% |
| FrontierCode v1.1 (would the change be merged?) | **54.4%** | 53.3% | 50.3% |
| GDPval-AA v2.1 (professional work, Elo) | **1846** | 1542 | 1735 |
| AutomationBench (business workflows) | 40.0% | **41.4%** | 31.4% |
| Humanity's Last Exam (with tools) | **67.7%** | 57.2% | 65.6% |
| Terminal-Bench-Science 0.1 | 58.7% | **64.6%** | 52.6% |

Anthropic also says that on FrontierCode, Opus 5.5 at default effort beats
Astra's top score "for about a fifth of the cost per task". It also reports an
internal single-prompt game test in which Opus 5.5 "scored higher than any other
model on the strength of its graphics and polish". That test compared Claude
models only.

### Roblox's own benchmark: OpenGameEval

Roblox publishes an open benchmark of realistic Studio tasks
(<https://github.com/Roblox/open-game-eval>, leaderboard read directly for this
report). Tasks run inside Roblox's Assistant harness with its MCP tools, five
tries each, with a 300-second limit per try.

**Authoring (87 tasks)**

| Model | Pass@1 | Pass@5 | All@5 | Tool error rate |
| --- | --- | --- | --- | --- |
| Claude Fable 5 | **50.3%** | 62.1% | **39.5%** | 1.40% |
| Claude Opus 4.6 | 48.1% | 59.8% | 38.3% | **0.71%** |
| Gemini 3.5 Flash | 48.1% | **63.2%** | 33.9% | 3.30% |
| Gemini 3 Flash Preview | 47.8% | 60.9% | 35.1% | 5.51% |
| Claude Opus 4.7 | 43.5% | 58.6% | 32.2% | 1.33% |
| GPT-5.5 (medium reasoning) | 40.7% | 56.3% | 30.6% | 0.91% |
| GPT-5.4 (medium reasoning) | 40.2% | 55.2% | 29.0% | 1.81% |

**Debugging (30 tasks, Pass@1):**

| Model | Pass@1 |
| --- | --- |
| Claude Fable 5 | **64.7%** |
| Gemini 3.1 Pro | 56.7% |
| GLM 5 | 56.0% |
| Opus 4.7 | 52.7% |
| GPT-5.4 | 51.3% |
| Gemini 3 Flash Preview | 51.3% |
| Opus 4.6 | 50.7% |
| GPT-5.5 | 50.0% |
| Gemini 3.5 Flash | 49.3% |
| GPT Codex 5.3 | 47.3% |
| Sonnet 4.6 | 46.0% |

How to read these numbers:

- Pass@1 is the chance of succeeding on the first try. Pass@5 counts a task as
  solved if any of five tries worked. All@5 needs all five tries to work.
- **Even the best model solved only about half of realistic Studio tasks on the
  first try.** It solved all five tries on only about 40% of them. That is the
  most honest single number for "can AI make Roblox games": yes, but expect to
  verify and fix constantly.
- GPT models ran at medium reasoning because higher settings hit the time limit.
  An unconstrained harness like Codex may do better.
- Roblox's detailed reviews found most model-to-model gaps were not
  statistically significant. **The behaviour differences were large, though, and
  they map directly to rules you can write down:**

| Failure seen in Roblox's reviews | Model(s) | Rule in [`starter/AGENTS.md`](../starter/AGENTS.md) that counters it |
| --- | --- | --- |
| Gives up after 2–3 searches, or asks instead of looking | Opus 4.7, GPT-5.5 ("confident wrong action") | Search the game tree broadly (depth 2+) before acting |
| Edits one of six matching objects | Opus 4.7 | Find every instance the request refers to |
| Builds a new system instead of extending the existing one | Fable 5 | Reuse existing systems and their attributes |
| Code looks right but runtime behaviour is wrong (NPC chase, damage) | Fable 5 | Verify in a playtest yourself; never by assumption |
| Changes made at runtime vanish; edit time confused with play time | Opus 4.6; Roblox says its own Assistant does this too | Edit scripts on disk; runtime changes don't persist |
| Rebuilds an effect instead of using the native feature (particles vs `Smoke`) | Opus 4.7 | Use the engine's native idiom |
| Can't see state outside scripts (properties, deep hierarchies) | GPT-5.5 | Inspect properties and attributes before changing them |

## Same-prompt anecdotes

| Test | Result | Weight |
| --- | --- | --- |
| @WoahWurdz built the same anime brawler with Astra (Sept 4) and Opus 5.5 (Sept 22) | Both "one-shotted". The Opus post calls it "leagues above Fable"; it doesn't compare against Astra | Demo only; uses anime IP |
| Moe Lueker, "Opus 5.5 vs GPT-6 Astra: same prompt, two games, real cost" (probably web games) | Opus made the better game both times. Astra was 2.5× faster and about half the cost; Opus wrote 256K output tokens against 36K | Secondary; not Roblox |
| Geeky Gadgets, 12 experiments | Opus won 8 of 12, mostly creative and design tasks. Astra won on speed and cost for structured tasks | Secondary; not Roblox |
| Hottarita (July 2026, before either launch): Codex vs Claude Code (Opus and Fable), same obby prompt, official Studio MCP | Each built a working obby in about 15 minutes. His son cleared the Codex one in 13 minutes: "difficulty adjustment is something humans still need to do" | Practitioner; Roblox-specific |

## Settle it in a week: the bake-off

1. **Run Roblox's benchmark on both models** with your own API keys:
   ```sh
   uv run invoke_eval.py --files "Evals/*.lua" --api-key $ROBLOX_OPEN_CLOUD_KEY \
     --llm-name claude --llm-api-key $ANTHROPIC_API_KEY --llm-model-version claude-opus-5-5
   uv run invoke_eval.py --files "Evals/*.lua" --api-key $ROBLOX_OPEN_CLOUD_KEY \
     --llm-name openai --llm-api-key $OPENAI_API_KEY --llm-model-version gpt-6-astra
   ```
   Budget time for this: each run takes 3–4 minutes, and one Open Cloud key allows
   50 submissions an hour. Start with one try per task on the 30 debug tasks plus
   a 20-task authoring subset.
2. **Give both agents the same ten real tasks** in a copy of the
   [`starter/`](../starter/README.md) place. Suggested tasks:
   - Add a second NPC whose dialogue branches on a choice made with the first.
   - Save which endings a player has seen, using ProfileStore.
   - Build night 1 of an anomaly-shift game (see [08](08-action-plan.md)).
   - Add a mobile-friendly rules-card UI.
   - Write an exploit test for every remote, then fix what fails.
   - Find and fix a bug you plant yourself.
3. **Score each task:**
   - worked on the first try
   - how many times you had to steer it
   - security problems found on review
   - minutes taken and dollars spent
   - how much of the work you'd keep
4. **Pick a primary and keep the other as reviewer.** Have the second model review
   each diff from the first; different models catch different mistakes.

## Keeping costs sane

- Default to **medium effort** for Opus 5.5. It's Anthropic's default and, by their
  numbers, beats Opus 5 at max effort on several benchmarks. Raise effort only for
  architecture or hard debugging.
- Push routine edits (UI tweaks, config, simple bugs) to **Sonnet 5.5** or
  **GPT-6.1 Sol**.
- Tell the agent what "done" looks like and when to stop. Every's week-long Opus
  5.5 test warns it "won't stop on its own, and it'll eat your weekly limit".
- Budget review time as well as tokens. An Endor Labs analysis is headlined
  "only 33.5% of code is secure" for Opus 5.5; only the headline was readable.
  Whichever model you use, a human (or the second model) reviews every remote,
  purchase and save path.
- Use prompt caching (API) or a subscription plan (Claude Code, ChatGPT/Codex).
  Agent work is mostly re-reading context, and cache reads are cheap ($0.20 per
  million tokens on Opus 5.5).

## Sources

- Anthropic, "Introducing Claude Opus 5.5" (Sept 22, 2026), read directly: <https://www.anthropic.com/claude-opus-5-5>
- Anthropic, "Introducing Claude Sonnet 5.5" (Sept 28, 2026) and "Introducing Claude Fable 5.1 and Claude Mythos 5.1" (Sept 1, 2026): <https://www.anthropic.com/news>
- Roblox OpenGameEval leaderboard and detailed reviews, read directly: <https://github.com/Roblox/open-game-eval>
- OpenAI Codex CLI model catalog (read from the open-source repo): <https://github.com/openai/codex>
- GPT-6 Astra launch coverage, as search summaries only (OpenAI's site was blocked): <https://openai.com/index/gpt-6-astra/>, <https://www.cnbc.com/2026/09/03/open-ai-astra-gpt-6-cyber.html>, <https://github.blog/changelog/2026-09-04-gpt-6-astra-is-generally-available-in-github-copilot/>
- Same-prompt comparisons: <https://moelueker.com/blog/claude-opus-5-5-vs-gpt-6-astra>; <https://note.com/hottarita/n/nb972e1eb21db>; <https://x.com/WoahWurdz/status/2095999578419929412>; <https://x.com/WoahWurdz/status/2102487879809126834>
- Every, "Vibe Check: Opus 5.5" and their tips post: <https://every.to/vibe-check/vibe-check-opus-5-5-is-pulling-our-codex-converts-back-to-claude>, <https://x.com/every/status/2102495448825262388>
- Endor Labs, Opus 5.5 secure-code analysis (headline only; the page was blocked): <https://www.endorlabs.com/learn/opus-5-5-6x-cheaper-and-2x-faster-than-fable-5-1-but-memorization-keeps-it-off-the-top-spot>
