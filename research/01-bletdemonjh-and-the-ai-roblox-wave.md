# @bletdemonjh and the September 2026 "AI built my Roblox game" wave

## What I could not do

The brief was to read all of @bletdemonjh's X posts, starting from
<https://x.com/bletdemonjh/status/2104871105752391780>. **I couldn't read any of them.**

- This session's network policy blocks `x.com`, `twitter.com`, the embed and
  syndication hosts, and the usual X mirrors. It also blocks most other sites,
  including roblox.com, the DevForum, Reddit, YouTube and news sites.
- Search engines have indexed **none** of the account's posts, under any spelling
  of the handle. The account appears too small or too new to be indexed.

To close this gap, do one of these and ask for a follow-up pass:

1. Paste the posts (text or screenshots) into the chat, or export them to a file
   in this repo.
2. Add `x.com` (and optionally `api.fxtwitter.com`, which returns single posts as
   JSON) to the environment's allowed domains. X's logged-out web view shows very
   little, so a full timeline may still need a logged-in export.

Nothing below claims to describe what the account says.

## What I could verify about the account holder

| Fact | Source | Confidence |
| --- | --- | --- |
| The linked post was published **2026-09-29 09:49 UTC**, about 14 hours before this research | Decoded from the post ID (X IDs embed a millisecond timestamp) | Certain |
| Roblox user **bletDemonJH** owns the group **"Ananas The Studio."** (group 7129314), which has **14,608 members** and was created about four years ago | Rolimons group page (search result) | High |
| The game **ANANAS [OBBY]** (place 11242003565) exists; its page shows a creation date of 2023-03-12 | Search result for the Roblox game page | Medium. Its link to the group isn't confirmed |
| bletDemonJH answers DevForum questions on UI and scripting (shift-lock icon, Jan 2025; health-bar frame sizing, Oct 2025) | DevForum post titles (search results) | High |
| A GitHub account named **bletDemonJH** exists with no public repositories | github.com, fetched directly | Certain |

The name match across Roblox, GitHub and X is strong evidence it is one person: a
hands-on Roblox developer who runs a mid-sized community group. Nothing found
shows player counts, revenue, or claims about AI.

## The context the post landed in

The post went up a week after Claude Opus 5.5 launched (Sept 22) and three weeks
after GPT-6 Astra (Sept 3–4). That week had a wave of public "an AI built my
Roblox game" posts. Every timestamp below is decoded from its post ID.

| When (UTC) | Who | Claim | What it actually shows |
| --- | --- | --- | --- |
| 2026-02-18 23:42 | @dryw3st ("Henry") | Roblox game "fully scripted" by Claude Opus 4.6 in about 4 days, "not a single line" by a human scripter | Went viral through @RoundtableSpace 3.5 hours later. Replies say he later clarified he made the UI himself. No game name, link or metrics found seven months on |
| 2026-09-04 22:16 | @WoahWurdz ("hiraeth") | GPT-6 Astra "one shotted" an anime Super Smash Bros-style game, built with Blender and Toolbox | Demo built on copyrighted anime characters, so it can't be sold |
| 2026-09-05 12:51 | @givros | GPT-6 Astra built a Mario Kart-like racer inside Roblox Studio in 30 minutes | Demo with a published prompt: Studio MCP plus Blender plus screenshot-and-fix loops |
| 2026-09-22 19:59 | @WoahWurdz | The same anime brawler, rebuilt with Opus 5.5 ("leagues above Fable, built only using toolbox") | The only same-person, same-idea comparison across the two models. Still a demo |
| 2026-09-25 | Stravant (veteran Roblox tools developer) | "Crossroads RTX ON": the classic map remade as a realistic scene by Opus 5.5 with up to 10 subagents in about 3 hours | A public, copyable place, so the output can be inspected. A map, not a game (source: a vendor case study) |
| 2026-09-26 08:41 | @smartyrbx | The map for "Clean The Dog Shit" was made by Opus 5.5; "manual devs are cooked" | Engagement bait with no metrics |
| 2026-09-27 20:47 | @0xCarnival | First Roblox game he ever finished, idea to done in 3–4 days with Opus 5.5 ("game devs aren't cooked, they are just gift[ed a tool]") | A plausible first-timer result. No metrics |
| **2026-09-29 09:49** | **@bletdemonjh** | **The post you linked** | **Not readable here** |

**Inference, not verified:** given its timing and how you framed the request, the
post is probably part of this wave. Treat it as one more data point once it can
be read, not as proof either way.

## What the wave does and doesn't prove

It proves that building is now fast. With Roblox's built-in Studio MCP server
(see [03](03-ai-tooling-and-workflow.md)), current models can produce a playable
Roblox prototype in hours to days, even for someone who has never shipped a
Roblox game.

It does not prove anyone is making money. Across 17 case studies
([04](04-case-studies.md)), **none of the AI-credited Roblox games has a verified
player count or revenue figure.** The posts share a pattern:

- They are new projects in template genres (brawler, racer, obby, tycoon,
  brainrot), the most crowded categories on the platform.
- The impressive part is often the assets (Toolbox models, Blender), not the systems.
- Several rely on IP the creator can't monetize.
- The measure of success is likes, not players.

The one credible 2026 small-team hit in the same period, Slime RNG, has no
evidence of being built with AI. It won through live-ops and community.

Roblox's own benchmark ([02](02-models-opus-5-5-vs-gpt-6-astra.md)) sets
expectations: before these two models launched, the best models solved about half
of realistic Studio tasks on the first try.

## Similar names that were checked and dropped

Searches for the handle also returned unrelated accounts with similar names (for
example BlueDemonJr, BleachDemonz, BlenderDemon) and unrelated catalog items.
None connect to bletDemonJH, and they were excluded.
