# The Roblox Vibe: what makes a game read as "a Roblox game" in 2025–2026, and how to get it into Last Ferry

> **Written before the "look and feel like Roblox" overhaul (2026-09-30).**
> Where it describes Last Ferry, it describes the game as it was then:
> faceless passengers, no player avatars, a premium-dark HUD and no audio.
> What was built from it is in `games/last-ferry` (see its README and
> ARCHITECTURE.md); the ranked recommendations were followed in that order.

**Prepared for:** Phoenix Feather Studios (studio head's note: *"the game doesn't look like Roblox right now. it doesn't look or give the roblox vibe."*)
**Date:** 2026-09-30
**Scope:** Characters, world and build style, UI, social and feel signals, store-page art, the top games of 2025–2026, and a ranked list of changes for **Last Ferry** (a fixed-camera, 1–4 player night-shift horror game at a harbor ticket booth).

---

## 0. Method, limits and evidence tags (read first)

**What was possible in this environment**
- **102 web searches** ran before the session-wide search cap (200, shared with other agents) was reached. After that, no more searches were possible.
- **Direct page fetching was blocked** for every non-GitHub domain tested, about 120 of them. Blocked domains included fandom.com, reddit.com (www and old), youtube.com, x.com, wikipedia.org, sportskeeda, dexerto, pcgamer, beebom, pockettactics, rolimons, rowatcher and every *.roblox.com host.
  - Most third-party facts below therefore come from **search-engine summaries** of the cited pages. I could not open those pages.
  - **Reddit could not be read at all.**
- Three kinds of source *were* read directly from GitHub:
  1. **Roblox's official `creator-docs` repository**, the source of create.roblox.com/docs (commit `14665218`, 2026-09-29). Live URLs are given alongside.
  2. **Open datasets:**
     - YouTube "Trending" snapshots from `gpsyrou/tube-virality`: a sample of 1,324 daily lists across 7 countries, Feb 2025–Sep 2026.
     - A Jan 6, 2026 top-earning Roblox games snapshot from `nickpio/top-earning-parser`.
  3. **Code** from Roblox's CoreScripts mirror and from Quenty's Nevermore.
- I read the Last Ferry source in `games/last-ferry` **read-only** so the recommendations point at real code. Nothing there was modified.

**Evidence tags**

| Tag | Meaning |
|---|---|
| **[DOC]** | Read directly in Roblox's official creator-docs (primary source). |
| **[GH]** | Read directly from a GitHub file or dataset (primary for that data). |
| **[S]** | Search-engine summary of the cited page. The page itself could not be opened, so treat the wording as a paraphrase. |
| **[B]** | Background knowledge. **Not verified this session.** |
| **[U]** | Sources conflict, or authority is low. |
| **[REC]** | My recommendation or inference, not a sourced fact. |

---

## 1. Executive summary

1. **The "Roblox vibe" is, first of all, *Roblox people on screen*.** That means your avatar, your friends' avatars, and NPCs who look like Roblox players. Roblox's own design guide says:
   - "Users spend a lot of time and money on their avatars and typically want them to be seen by their friends and other users. A common identity across the platform is part of what makes Roblox special, so if you're going to change that for your game, make sure you have a good reason." [DOC] ([design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox); [GitHub](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/design-for-roblox.md))
   - Roblox users made **274 million avatar updates a day** in 2025 [S] ([Roblox IR](https://ir.roblox.com/news/news-details/2025/Roblox-Releases-New-Data-Decoding-Search-and-Style-Trends-in-Digital-Experiences/default.aspx)).
   - **Last Ferry today has no player avatars (`CharacterAutoLoads = false`) and no Roblox-looking NPCs (faceless box-and-ball figures).** That combination is the single biggest reason it doesn't read as Roblox. [REC]
2. **Last Ferry is squarely in the hottest Roblox genre of 2025–26: anomaly night-shift horror.**
   - *Scary Shawarma Kiosk: the ANOMALY* launched Aug 25, 2025, is 4 players per server, and passed 1.2B visits [S] ([Roblox Wiki](https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror)); [GH guide](https://github.com/cdg-hue/shawarma-kiosk-share)).
   - *Animal Hospital (Anomaly)* launched May 10, 2026 and swept the **2026 Roblox Innovation Awards**: Best New Game, Innovation in Creative Direction, People's Choice and the Builderman Award [S] ([Variety](https://variety.com/2026/gaming/news/animal-hospital-roblox-innovation-awards-20th-anniversary-1236860184/)).
   - In these games **the "normal" customer is a Roblox-looking character, and the scare is wrongness on top of that.** A missing face is itself a monster trope: Shawarma has a "Faceless Man" entity and a "No Face" anomaly [GH] [S] ([guide repo](https://github.com/cdg-hue/shawarma-kiosk-share); [moyens.net](https://uk.moyens.net/gaming/codes/scary-shawarma-kiosk-anomalies-revealed/)).
   - Last Ferry's all-faceless queue removes the baseline that makes the genre work. [REC]
3. **World style.** Roblox-native means:
   - chunky, readable, "built in Studio" geometry with bright accents and simple materials;
   - Roblox's own docs call `LightingStyle.Soft` "a flat, retro‑Roblox look" [DOC] ([lighting](https://create.roblox.com/docs/environment/lighting)).

   Realism exists (*Pressure*, *The Mimic*), but it always sits around Roblox avatars and Roblox conventions. Cartoon games dominate the front page [S] ([DevForum](https://devforum.roblox.com/t/does-the-design-style-of-a-game-determine-its-success/236721)).
4. **Most players are on phones, where moody realistic lighting mostly disappears.**
   - About 80–83% of users play on mobile [S] ([Statista](https://www.statista.com/statistics/1190919/roblox-games-users-global-distribution-platform/)).
   - About 65% of a typical game's players are on Android, ~60% of them with 2–4 GB RAM [DOC] ([test-on-hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)).
   - The engine disables shadows entirely below graphics quality 4 [DOC] ([improve performance](https://create.roblox.com/docs/performance-optimization/improve)).
5. **UI.** The Roblox "house style" is chunky:
   - rounded containers and big buttons;
   - thick dark outlines or strokes on text;
   - bold rounded type (Fredoka One, Gotham/Montserrat Bold/Black, Builder Sans Bold/ExtraBold, Luckiest Guy);
   - saturated state colors and bouncy feedback [S] ([VizzBees](https://vizzbees.com/blog/roblox-ui-design-ideas); [DevForum](https://devforum.roblox.com/t/whats-a-good-font-face-to-use-as-a-general-theme-for-a-game/2538479)).

   Horror games darken the palette but keep type large and legible. *DOORS* uses Oswald [S] ([YouTube short](https://www.youtube.com/shorts/9X9VTeZJwv0)), so Oswald is not the problem. The problem is the typewriter/serif/mono mix on thin dark panels. Roblox's own docs say to avoid "excessively decorative or thin fonts" on phones [DOC] ([adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design)).
6. **Social signals.** Players expect:
   - bubble chat above heads, emotes, jumping;
   - a lobby with an elevator or party queue;
   - visible core UI (top bar, chat, player list), usernames on screen, and meme-able moments.

   Last Ferry currently **hides the emote menu and player list** and shows passenger speech as HUD text rather than chat bubbles (read from `HudController.luau`).
7. **Store page.** Roblox thumbnails lead with **characters and one big emotion**, 2–4 huge words, and high contrast [S] ([generalistprogrammer](https://generalistprogrammer.com/tutorials/how-to-make-a-roblox-game-icon); [CreatorXP](https://creatorxp.gg/guides/roblox-game-icon-mistakes)). Titles carry emoji and bracket tags:
   - 62% of 410 top-earning games (Jan 2026) have an emoji in the name, and 58% a bracket or paren tag;
   - in the top 50 by players, 37 have emoji [GH] ([top-earning snapshot](https://github.com/nickpio/top-earning-parser/blob/master/runs/2026-01-06/pruned/2026-01-06_top-earning_top1500_enriched_pruned.json)).
8. **Roblox's own nostalgia and lore are hot in 2025–26.**
   - Roblox ran a 20th-anniversary "THE HUNT: ROBLOX 20" event that walked through classic games from 2006 onward [GH] (YouTube Trending data, KreekCraft, Sept 2026).
   - *Forsaken* built its cast from Roblox myths and figures [S] ([TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ForsakenRobloxKillers)).
   - *Steal a Brainrot* added "Guest" and "1x1x1x1" characters [GH] (YouTube Trending data, Nov 2025).
   - The most-viewed Roblox horror clip in the trending sample (25.2M views) is a *Dead Rails* animation starring **the noob** [GH].
9. **The top 5 fixes, ranked (§10):**
   1. Rebuild passengers as Roblox avatars, and make the drowned "wrong" on top of that base.
   2. Give players bodies, visible to each other in the booth, with bubble chat and emotes.
   3. Reskin the HUD in chunky Roblox style.
   4. Relight and recolor for "Roblox night" on phones.
   5. Add a pier lobby with a party gangway queue.

   After those come: a Roblox-format icon, thumbnails and title; Roblox humor and lore cameos; Roblox-style feedback audio; and small physical interactions.

---

## 2. The eight signals players read as "Roblox" (scorecard)

| # | Signal | What Roblox players expect | Key evidence | Last Ferry today |
|---|---|---|---|---|
| 1 | **Avatars on screen** | You, your friends and NPCs as Roblox avatars | [DOC design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox); "Most games let players use their own Roblox avatar" [DOC] ([appearance](https://create.roblox.com/docs/characters/appearance)) | ❌ No player bodies; faceless mannequins |
| 2 | **Roblox iconography** | Classic smile, noob colors, bacon hair, Guest, Builderman, myths | §3.4 | ❌ None |
| 3 | **"Built in Studio" world** | Chunky parts, readable silhouettes, bright accents, Plastic/SmoothPlastic/Neon | §4 | ⚠️ Part-built, but tuned toward realism (`LightingStyle.Realistic`, dense haze) |
| 4 | **Chunky, legible UI** | Big rounded buttons, stroked bold rounded type, saturated state colors, bouncy tweens | §5 | ❌ Dark minimal "indie" panels; Oswald, Special Elite, Merriweather, Roboto Mono |
| 5 | **Social layer** | Bubble chat, emotes, jump, names, player list | §6 | ❌ Emotes menu and player list disabled; speech drawn as a HUD label |
| 6 | **Lobby and queue** | Hub where avatars mingle, then an elevator, bus or pad queue | §6.3 | ❌ No lobby |
| 7 | **Roblox humor and memes** | Horror that is funny with friends; lore jokes; "3AM" and "night shift" framing | §6.5 | ⚠️ Serious tone only |
| 8 | **Roblox-format store page** | Avatar faces, one emotion, 2–4 bold words, emoji and [TAG] titles | §7 | ⏳ Not made yet |

---

## 3. Characters

### 3.1 Avatars are the platform's identity

- Roblox tells developers:
  - "A common identity across the platform is part of what makes Roblox special" [DOC] ([design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)).
  - "single-player games often find it harder to build and retain an audience on Roblox" [DOC] (same page).
  - "Most games let players use their own Roblox avatar, although some implement an in-game customization system… Other games make limited modifications to player avatars such as helmets, wings, or accessories that match the genre" [DOC] ([appearance](https://create.roblox.com/docs/characters/appearance)).
- Scale of avatar culture:
  - **274 million daily avatar updates** in 2025. 87% of surveyed users said experimenting with avatar style made them more comfortable expressing themselves [S] ([Roblox IR](https://ir.roblox.com/news/news-details/2025/Roblox-Releases-New-Data-Decoding-Search-and-Style-Trends-in-Digital-Experiences/default.aspx); [Roblox Replay 2025](https://about.roblox.com/newsroom/2025/12/roblox-replay-decoded-search-style); [YPulse](https://www.ypulse.com/newsfeed/2025/12/22/roblox-yearly-stats-show-its-gen-zs-proving-ground-for-style-trends-and-identity/)).
  - An earlier Roblox report found 56% of Gen Z users say styling their avatar matters more to them than styling themselves physically [S] ([Roblox newsroom 2023](https://about.roblox.com/newsroom/2023/11/insights-latest-digital-expression-fashion-beauty-trends-report)).
- Even Roblox's own realistic horror showcase, *The Mystery of Duvall Drive*, was built around avatars:
  - "we always built with an avatar both in our 3D application and inside Studio";
  - "We wanted both realistic and block characters to feel natural in scale" [DOC] ([construct-the-house](https://create.roblox.com/docs/resources/the-mystery-of-duvall-drive/construct-the-house)).
- Roblox's Recommended-for-You ranking lists **"Intentional co-play days per user"** (days users come back to play *with friends*) as an "Important" signal [DOC] ([discovery](https://create.roblox.com/docs/discovery)).
  - Its "Most important" signals are play-through rate, play days, playtime and **first-play bounce rate** (sessions under 60 s and 61–180 s), which counts against a game [DOC] (same page).
  - A game where friends can't see each other throws away the social glue that co-play measures. A first minute that looks unfamiliar risks early bounces. [REC]

### 3.2 R6 vs R15 in 2026

- **The perception:**
  - R6 (6 parts) reads as "old-school, blocky, nostalgic, simple animations";
  - R15 reads as "smoother, more customization" [S, weak] ([fb-answers](https://www.facebook.com/fb-answers/roblox-r6-avatar-comparison/)).
  - On the DevForum, combat and RPG games (*Deepwoken*, *Type: Soul*, the battlegrounds genre) are cited as choosing R6 [S] ([DevForum](https://devforum.roblox.com/t/why-do-combat-game-developers-lean-more-towards-r6-rather-than-r15/3136549); [DevForum](https://devforum.roblox.com/t/is-it-better-to-use-r6-or-r15-in-games/1834142)).
- **Roblox's direction is R15.**
  - The **R6→R15 Adapter** lets R15 avatars join R6 games while keeping "R6-like scale and movement," so R6 games can use layered clothing and dynamic heads [DOC] ([r6-to-r15-adapter](https://create.roblox.com/docs/characters/r6-to-r15-adapter)).
  - The **U.S. 18+ DevEx rate** ($0.0054/Robux, effective June 8, 2026) requires *player characters* to spend "100% of active playtime" as R15 or custom rigs. R6 player avatars make a game ineligible [DOC] ([18+ DevEx](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate)).
  - **But:** "the eligibility criteria only applies to player characters. Roblox does not evaluate non-player characters (NPCs)" [DOC] (same page).
- **Implication for Last Ferry [REC]:**
  - Players should be R15, the default avatar, to keep that rate open.
  - Passengers (NPCs) can use either rig, *including classic R6-looking figures*, without affecting eligibility.

### 3.3 Classic faces vs Dynamic Heads (the 2026 migration)

- **Timeline:**
  - Roblox announced "Completing the Dynamic Head Migration" in late January 2026.
  - Classic faces went off-sale on **March 23–24, 2026**, and classic head/face combinations were converted to Dynamic Heads [S] ([Roblox Wiki via search](https://roblox.fandom.com/wiki/Normal_face); [1AM Gamer](https://1amgamer.com/posts/roblox-classic-faces-removed-dynamic-heads-community-reaction-2026); [Dexerto](https://www.dexerto.com/gaming/roblox-finally-removes-classic-faces-as-major-avatar-update-rolls-out-3340618/)).
- **Backlash:**
  - Coverage called the reaction "swift and brutal" across Reddit, X, TikTok and YouTube, with players mourning the "end of an era" [S] ([1AM Gamer](https://1amgamer.com/posts/roblox-classic-faces-removed-dynamic-heads-community-reaction-2026); [Gamezebo](https://www.gamezebo.com/features/roblox-classic-faces/); [Game Rant](https://gamerant.com/roblox-classic-faces-removed-gone-offsale-update/)).
  - KreekCraft mocked the "self-expression is foundational" wording in the announcement [S] ([X, 2026-01-28](https://x.com/KreekCraft/status/2016314032920101213); date decoded from the post ID).
  - Roblox partly walked it back:
    - an animation-off toggle;
    - later, the option to pick a classic head and choose a classic face.

    PC Gamer called this "not enough to make everyone happy" [S] ([PC Gamer](https://www.pcgamer.com/games/roblox-walks-back-some-of-its-dramatic-changes-to-avatar-faces-but-not-enough-to-make-everyone-happy/); [piunikaweb](https://piunikaweb.com/2026/03/25/roblox-replacing-classic-heads-nifty-trick-brings-it-back/)).
- **For developers:**
  - Roblox publishes a classic-vs-dynamic comparison table for each face [DOC] ([head-comparison](https://create.roblox.com/docs/art/characters/head-comparison)).
  - A community module, **"Reface,"** swaps migrated dynamic heads back to "the correct classic mesh + face decal" in-experience [S] ([DevForum](https://devforum.roblox.com/t/reface-restore-classic-decal-faces-following-the-dynamic-head-migration-v110/4560579)).
  - Roblox's own CoreScripts still build a default dummy with a head `Decal` set to **`rbxasset://textures/face.png`**, the built-in classic face shipped with the client, and Quenty's `RigBuilderUtils` does the same [GH] ([Client-Tracker GenerateDummy.lua](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/scripts/CoreScripts/Modules/FTUX/Utility/GenerateDummy.lua); [Nevermore RigBuilderUtils](https://github.com/Quenty/NevermoreEngine/blob/main/src/rigbuilderutils/src/Shared/RigBuilderUtils.lua)).
  - The engine also has a built-in `SpecialMesh` **`MeshType.Head`**, the classic rounded head [GH] (Roblox API dump, `Enum.MeshType`).
  - **You can build a classic Roblox-looking person entirely from code with zero uploaded asset IDs**, which fits Last Ferry's "no asset IDs" rule. [REC]
- **Why this matters for a horror game [REC]:**
  - In 2026 the classic static face is simultaneously beloved, nostalgic and *gone from the catalog*.
  - A frozen classic face on an otherwise normal-looking passenger reads as "from the old days," while living players' faces animate.
  - That is a native-to-Roblox uncanny tell (see §10, R1).

### 3.4 Roblox iconography players recognize instantly

- **The classic smile:**
  - The original face (two dot eyes, a V-like smile) was drawn by David Baszucki on Oct 4, 2005.
  - An April 2015 change to a different smile caused such backlash that Roblox reverted it on May 7, 2015 [S] ([Roblox Wiki, Normal face](https://roblox.fandom.com/wiki/Normal_face); [ExitLag](https://www.exitlag.com/blog/roblox-smile/)).
- **The Noob:**
  - Yellow head and arms, blue torso, green legs. These were the default avatars assigned from 2006 to 2007.
  - It is "widely viewed as one of the most iconic 'characters' within Roblox" and is now worn ironically as fashion [S] ([Roblox Wiki, Noob](https://roblox.fandom.com/wiki/Noob); [Outfit Styles wiki](https://roblox-outfit-styles.fandom.com/wiki/Classic_Noob)).
  - In the YouTube Trending sample, the single most-viewed Roblox horror video was **"When they forget noob in town ☠️ PT8 – Roblox Dead Rails #robloxanimation"** (Ninja Roblox, **25.2M views**, PH trending 2025-06-28). Its sequels PT7 (14.7M) and PT9 (8.3M) also trended [GH] ([tube-virality](https://github.com/gpsyrou/tube-virality), `trending_videos_PH_20250628.json`).
- **Bacon hair:**
  - The default "Pal Hair," free since 2014. It means a newbie, like "noob," and is also used ironically (pretend-noob pranks) [S] ([Beebom](https://beebom.com/roblox-bacon/); [Pocket Tactics](https://www.pockettactics.com/roblox-bacon); [ExitLag](https://www.exitlag.com/blog/bacon-hair-roblox/)).
  - Creators still title videos with it, for example "BACON Snucks Into ONLY STRONGEST Server!" (2.5M views, Steal a Brainrot) [GH] (tube-virality, PH 2026-07-13).
- **Guest, John Doe, 1x1x1x1, c00lkidd and Roblox myths:**
  - Roblox "myths" are horror stories built around odd accounts [S] ([Roblox Wiki, Roblox myth](https://roblox.fandom.com/wiki/Roblox_myth)).
  - *Forsaken's* killers and survivors are built from them: c00lkidd, John Doe, 1x1x1x1, Noob, Guest 1337, Shedletsky, Builderman [S] ([TV Tropes killers](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ForsakenRobloxKillers); [TV Tropes survivors](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ForsakenRobloxSurvivors); [Heroes Wiki](https://hero.fandom.com/wiki/Survivors_(Forsaken))).
  - "GUEST 666 IS FINALLY HERE!" (Forsaken Halloween 2025 update) and "GUEST, 1X1X1X1… ATUALIZAÇÃO DO ROUBE UM BRAINROT" (Steal a Brainrot, Nov 2025) both trended [GH] (tube-virality US 2025-11-01, BR 2025-11-02).
  - *The Last Guest: Reimagined*, a fan-made Roblox action film, drew 1.2M views [GH] (tube-virality PH 2026-05-11).
- **Builderman** is David Baszucki's username [DOC] ([Roblox user base glossary](https://create.roblox.com/docs/production/roblox-user-base)).
  - Roblox's 20th-anniversary "THE HUNT: ROBLOX 20" event (Sept 2026) had a Builderman live event.
  - It walked players through Crossroads (2006), Sword Fight on the Heights IV (2007), Chaos Canyon (2009), Work at a Pizza Place (2010), Natural Disaster Survival (2011), Piggy (2021) and more [GH] (tube-virality: KreekCraft "BUILDERMAN LIVE EVENT", CA 2026-09-20; "THE HUNT: ROBLOX 20", GB 2026-09-18).
  - **Nostalgia is at a 20-year peak right now.** [REC]
- Roblox's docs note that the culture "has its own vocabulary, memes, celebrities, and even myths" [DOC] ([Roblox user base](https://create.roblox.com/docs/production/roblox-user-base)).

### 3.5 How popular games present NPCs

| Game | NPC / character approach | What it signals | Source |
|---|---|---|---|
| **Scary Shawarma Kiosk** (2025) | "Normal" customers look like regular people and players. Anomalies are wrong versions: a white-eyed lady, a skinwalker with "pale, cracked, white skin with no hair or clothes", holes visible only on CCTV, a man whose face falls off. Entities include the **Faceless Man**. "The Hacker" addresses **you by your username**. | Baseline normal Roblox person, then distortion. Using the player's username is a Roblox-native scare. | [S] [TechWiser](https://techwiser.com/scary-shawarma-kiosk-anomalies-guide/), [Deltia's](https://deltiasgaming.com/scary-shawarma-kiosk-all-anomalies-guide-roblox/), [Droid Gamers](https://www.droidgamers.com/guides/scary-shawarma-kiosk-the-anomaly-all-anomalies-and-how-to-spot-them/), [Beebom](https://beebom.com/all-anomalies-in-scary-shawarma-kiosk/); [GH guide](https://github.com/cdg-hue/shawarma-kiosk-share) |
| **Animal Hospital (Anomaly)** (2026) | Anthropomorphic animal patients; the anomaly is added wrongness ("Three Eyes, Hollow Eyes, Sharp Teeth, extra limbs, wrong proportions, and animation tells"). Checked at the **window**, against a **photo**, and on **CCTV**. | Cute-then-wrong. Stylized characters with legible tells. | [S] [allthings.how](https://allthings.how/catch-every-anomaly-in-animal-hospital-roblox-with-3-checks/), [Fandom](https://animal-hospital.fandom.com/wiki/Animal_Hospital_(Game)) |
| **Terminal 13: Not Human** (2025) | Travelers at a passport checkpoint. Impostors show "unusual proportions, movement patterns, inhuman appearance", or a photo that doesn't match. | Papers-Please grammar on Roblox figures. | [S] [Deltia's](https://deltiasgaming.com/roblox-how-to-play-terminal-13-not-human/), [Pro Game Guides](https://progameguides.com/roblox/complete-terminal-13-not-human-walkthrough/) |
| **Home Alone (Anomaly)** | Visitors at the door. Tells include a voice that doesn't fit the face ("an ultra-high voice on a huge gym visitor") and the wrong vehicle outside. | Comedy-horror mismatch tells. | [S] [allthings.how](https://allthings.how/home-alone-anomaly-roblox-how-to-identify-every-visitor/) |
| **That's Not My Robloxian** | "Robloxian" residents and their clones, set in 2012. | Uses the platform's own name and look as the subject. | [S] [Fandom](https://thats-not-my-robloxian.fandom.com/wiki/Clones), [Sportskeeda](https://www.sportskeeda.com/roblox-news/thats-not-my-robloxian-definitive-guide-faqs) |
| **Weird Strict Dad** | The dad is a Roblox-avatar NPC. When possessed, his face becomes Renderman's (a Blockland creepypasta face) and his shirt turns red. | A familiar Roblox person made uncanny with one swap. | [S] [Villains Wiki](https://villains.fandom.com/wiki/Mysterious_Man_(Weird_Strict_Dad)), [Fandom](https://weird-strict-dad.fandom.com/wiki/Weird_Strict_Dad_(Game)) |
| **Forsaken** (2024–) | Every character is Roblox lore or a Roblox figure. The game even added a YouTuber: "They added ME to ROBLOX FORSAKEN" (Flamingo, 1.8M views). | Roblox iconography is the IP. | [S] [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ForsakenRoblox); [GH] tube-virality GB 2025-07-11 |
| **Piggy** | Blocky Roblox proportions with animal heads and accessories. | Roblox bodies plus a simple costume. | [S] [ExitLag](https://www.exitlag.com/blog/roblox-piggy/), [BrightChamps](https://brightchamps.com/blog/roblox-piggy/) |
| **Dead Rails** (2025) | Zombies are "green humanoid beings that wear worn out western attire", on Roblox-proportioned bodies. | Classic Roblox body plus a color and outfit swap. | [S] [Villains Wiki](https://villains.fandom.com/wiki/Zombies_(Dead_Rails)), [Roblox Wiki](https://roblox.fandom.com/wiki/RCM_Games/Dead_Rails) |
| **DOORS / Pressure / 99 Nights** | Custom monsters (entities, "the Deer," cultists) in a world full of player avatars. | The monsters are custom; the people are Roblox. | [S] [99 Nights Wiki](https://99-nights-in-the-forest.fandom.com/wiki/99_Nights_in_the_Forest:_Game), [Pressure Wiki](https://pressure.fandom.com/wiki/Pressure); DOORS [B] |
| **Roblox NPC Kit** (official) | Rthro zombie, soldiers and robots as ready-made NPCs. | Roblox's own default "NPC look" is avatar-rigged. | [DOC] [npc-kit](https://create.roblox.com/docs/resources/npc-kit) |

### 3.6 The rule of the genre Last Ferry belongs to

- The anomaly games that define 2025–26 all use the same grammar. A **normal-looking Roblox person** is the baseline. **Wrongness** is the tell: eyes, face, proportions, voice, camera-only details, and names. [S] (table above)
- **Facelessness is on the monster side of that line:**
  - "Faceless Man" (looking at it triggers danger) and "No Face" in Shawarma [GH] [S];
  - a blank face is the classic noppera-bō folklore trick that Shawarma borrows [S] ([moyens.net](https://uk.moyens.net/gaming/codes/scary-shawarma-kiosk-anomalies-revealed/)).
- **So a Roblox player reads Last Ferry's all-faceless queue as "everyone is already a monster" or "this isn't Roblox."** Neither helps the tells. [REC]

---

## 4. World and build style

### 4.1 What "built on Roblox" looks like

- Commonly described traits:
  - "blocky geometry, bright colors, minimal textures, and customizable avatars, prioritizing creativity, accessibility, and performance over realism" [S] ([Vasundhara](https://www.vasundhara.io/blogs/roblox-art-style-explained-what-makes-roblox-so-unique));
  - "blocky low-poly design, third-person perspective, fast and snappy gameplay, bright saturated colors, and flat materials" [S] ([Nilo blog](https://blog.nilo.io/vibe-code-roblox-style/));
  - "a blocky character, springy physics, a counter that climbs, and a leaderboard" [S] ([Summer Engine](https://www.summerengine.com/blog/how-to-make-a-roblox-style-game-with-ai)).
- Many developers "consciously choose to maintain stylistic consistency, often incorporating blocky elements or vibrant colors… even with advanced graphical capabilities" [S] ([ChicMic](https://www.chicmicstudios.in/blogs/the-evolution-of-roblox-graphics-and-whether-players-really-care/)).
- The default material for new parts is **Plastic** [DOC] ([materials](https://create.roblox.com/docs/parts/materials)). Plastic, SmoothPlastic and Neon, in bold colors, are the house look [B].
- **Lighting style is an explicit choice** [DOC] ([lighting](https://create.roblox.com/docs/environment/lighting)):
  - `Realistic` gives "the most advanced and realistic lighting and shadows";
  - `Soft` gives "a flat, retro‑Roblox look with softer lights and shadows."
  - Last Ferry uses `Realistic` (`WorldService.luau`, `setUpLighting`).

### 4.2 Studs, BrickColor and the classic revival

- Studs were the classic surface. The surface tool is gone and new parts have no studs, but some developers recreate the old circular studs for nostalgia [S] ([Roblox Wiki, Studs](https://roblox.fandom.com/wiki/Studs_(surface)); [Preservationist Wiki](https://roblox-preservationist.fandom.com/wiki/Studs)).
- WoodReviewer's post on the 2025 "retro-looking games" trend lists other parts of the classic look [S] ([WoodReviewerRBX](https://woodreviewerrbx.com/2025/05/23/on-retro-looking-games/); [X, 2025-05-23](https://x.com/WoodReviewerRBX/status/1926038238575071691)):
  - only 32 BrickColors;
  - joint-built, destructible objects;
  - extra-thick walls to stop clipping.
- **Roblox Classicism / NeoClassicism** is a named community aesthetic. Roblox ran **The Classic** event (May 23–28, 2024) [S] ([Roblox Lore Database](https://robloxloredatabase.miraheze.org/wiki/Roblox_Classicism); [Roblox Wiki](https://roblox.fandom.com/wiki/The_Classic)).
- *DOORS*' 2024 April Fools **Retro Mode** restyled the game like "classic 2009 Roblox games," with speed and jump pads, hats and dancing NPCs [S] ([DOORS Wiki](https://doors-game.fandom.com/wiki/2024_April_Fools_Event)).
- Roblox's own 20th-anniversary event (Sept 2026) revisited 2006–2023 classics [GH] (tube-virality, §3.4).

### 4.3 The realism debate

- **The long-running DevForum consensus:**
  - "a pretty consistent trend of 'cartoon like' games dominating the front page… Higher detailed games that go for a more 'realistic' feel usually take second place" [S] ([DevForum](https://devforum.roblox.com/t/does-the-design-style-of-a-game-determine-its-success/236721));
  - style follows the target audience, and a cartoon style attracts younger players [S] (same thread; [DevForum "Cartoony or realistic?"](https://devforum.roblox.com/t/cartoony-or-realistic/2485711)).
  - Roleplay developers note that *Brookhaven*/*Berry Avenue*-type hits are low-poly, and that realism costs performance [S] ([DevForum](https://devforum.roblox.com/t/low-poly-vs-realistic-for-a-role-playing-game/3143597)).
- **Roblox's own guidance:**
  - "Younger users are often less sensitive to visual fidelity and more likely to stick around if they're having a good time, regardless of how your game looks" [DOC] ([design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)).
  - It also lists *DOORS* among games that appeal to **older** users, whose audience "is growing older every day" [DOC] (same page).
  - There are now more users 13+ than under 13 [DOC] ([user base](https://create.roblox.com/docs/production/roblox-user-base)).
- **Realistic horror exists, but it keeps Roblox's people and conventions:**
  - *Pressure* explicitly moved "away from the platform's traditional blocky aesthetic toward a more realistic and immersive art style," but kept *DOORS*'s room-by-room loop [S] ([Shapes](https://shapes.inc/fandom/pressure); [Pressure Wiki](https://pressure.fandom.com/wiki/Pressure)).
  - *The Mimic* "uses Roblox's avatar system" with "4K-adjacent graphics" [S] ([Screenwise](https://screenwiseapp.com/guides/the-mimic-roblox)).
  - *DOORS* won Best Visual Design and Best Audio Design at the 2023 Roblox Innovation Awards [S] ([Shapes](https://shapes.inc/fandom/doors-roblox-game); [DOORS Wiki](https://doors-game.fandom.com/wiki/DOORS)).
- **Market check (Jan 6, 2026 top-earning snapshot, players at capture)** [GH] ([snapshot](https://github.com/nickpio/top-earning-parser/blob/master/runs/2026-01-06/pruned/2026-01-06_top-earning_top1500_enriched_pruned.json)):
  - *Pressure*: 3,125 players.
  - *DOORS*: 13,204.
  - *Scary Shawarma Kiosk*: 89,875 (134 days old).
  - *Forsaken*: 104,187.
  - *Dandy's World*: 105,143.
  - *99 Nights*: 506,355.

  The new-wave horror hits are stylized, avatar-centric and social; the realism flagships trail them. This is a single snapshot, so read it as directional only.
- **The avatar-realism push is a separate fight.**
  - TechCrunch covered Roblox's push toward avatar realism in 2021 [S] ([TechCrunch](https://techcrunch.com/2021/10/14/roblox-avatar-updates-rdc-2021/)).
  - A widely shared 2026 post: "8 years of trying to push realistic avatars and hardly anybody outside of employees… use them" [S] ([X, Lord CowCow, 2026-06-18](https://x.com/greenlegocats/status/2067748060680364362)).
  - Combined with the classic-faces backlash (§3.3), **the community is actively protective of the blocky, classic identity right now.** [REC]
- **Style mismatch:** mixing blocky avatars with photoreal environments creates "visual tension that breaks the cohesive art direction" [S, low authority] ([Alife Virtual](https://www.alifevirtual.com/blog/photorealistic-vs-blocky-roblox.php)).

### 4.4 Horror palettes that still read as Roblox

- Roblox's icon guidance endorses three moods [DOC] ([experience-icons](https://create.roblox.com/docs/production/publishing/experience-icons)):
  - "bright, high-saturation colors for a fantasy or dreamy setting";
  - "muted low-saturation colors for a somber, moody setting";
  - "heavy color balance and contrast for a horror game."
- The thumbnail docs show a "dark and stormy theme for a horror game" as correct [DOC] ([thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)).
- **Muted is allowed; low contrast is the enemy.** [REC] Roblox's accessibility guidance warns against dark-on-dark and light-on-light text [DOC] ([accessibility](https://create.roblox.com/docs/production/publishing/accessibility)).

### 4.5 The phone constraint (why "moody realistic" backfires)

- **Share of mobile:** 83% of Roblox game users signed in on mobile as of Dec 2025 [S] ([Statista](https://www.statista.com/statistics/1190919/roblox-games-users-global-distribution-platform/)); ~80% of sessions [S] ([RoWatcher](https://rowatcher.com/news/mobile-vs-desktop-on-roblox-who-s-playing-what-in-2026)).
- **Device reality:**
  - "The majority of Roblox players are on lower-spec mobile devices";
  - Android is ~65% of a typical game's players, ~60% of them with 2–4 GB RAM;
  - over 50% of players are on devices scoring 10,000–20,000 on Passmark [DOC] ([test-on-hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)).
- **Shadows:** "The Roblox engine automatically degrades shadow quality as client graphics quality level decreases, eventually disabling shadows altogether at quality levels below 4" [DOC] ([improve](https://create.roblox.com/docs/performance-optimization/improve)).
- **Future lighting** falls back to voxel lighting at quality levels 3 and below [S] ([Roblox Wiki, Future Is Bright](https://roblox.fandom.com/wiki/Future_Is_Bright); [DevForum Android rollout](https://devforum.roblox.com/t/future-is-bright-on-android-is-fully-rolled-out-client-beta/3235808)).
  - A DevForum thread notes Future lighting "looks fine on PC, but way too bright on mobile" [S] ([DevForum](https://devforum.roblox.com/t/future-lighting-looks-fine-on-pc-but-way-too-bright-on-mobile/1087420)).
- **Consequence for Last Ferry [REC]:** many players will not see the fog-and-lamp mood the team is tuning on PC. The **characters, palette and UI must carry the look.** Last Ferry already adds a fallback shadow patch for low-quality devices (per its README), which is the right instinct.

---

## 5. UI style

### 5.1 The Roblox "house style"

- A 2026 taxonomy of Roblox UI styles (cartoon, neon, minimal, fantasy, glass, retro, Y2K, anime, pastel, industrial, sketch, premium dark) describes the dominant **cartoon** style as "chunky cartoon UI with thick dark outlines, 16 px rounded corners, saturated primary colours, hard drop shadows, and playful oversized buttons." It fits "obbies, simulators, tycoons, and games aimed at younger audiences" [S] ([VizzBees](https://vizzbees.com/blog/roblox-ui-design-ideas)).
  - Its **minimal/premium-dark** style ("charcoal panels… hairline dividers, tight modern sans type") is essentially what Last Ferry has now. That style reads "premium PC indie," not "Roblox." [REC]
- The building blocks are native: `UICorner` for rounded edges, `UIGradient` for fills, `UIStroke` for outlines [S] ([VizzBees](https://vizzbees.com/blog/roblox-ui-design-ideas)) [DOC] ([appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)).
  - UIStroke gained scaling and offsets in 2025 [S] ([DevForum](https://devforum.roblox.com/t/full-release-uistroke-improvements-scaling-offsets-and-more/3958036)).
  - UIGradient gained radial and conical types in 2026 [S] ([DevForum](https://devforum.roblox.com/t/studio-beta-upgraded-ui-gradients/4846594)).
  - "UIStroke x UIGradient is a great combo" is a standing community tutorial [S] ([DevForum](https://devforum.roblox.com/t/uistroke-x-uigradient-is-a-great-combo-heres-why/1463030)).
- Roblox's UI/UX doc on buttons [DOC] ([ui-ux-design](https://create.roblox.com/docs/production/game-design/ui-ux-design)):
  - "Housing buttons in a container… distinguishes them from the background… Adding highlights or shadows can enhance their tactile appeal by suggesting 3D depth."
  - Headers "larger and bolder than body text."
  - Conventions include the X close button (shown in *DOORS* and others), grey for unusable buttons, lock icons, the "E" proximity prompt, and "walking into circles on the ground in order to queue up for a match."

### 5.2 Fonts

- **Platform font:** Builder Sans (from March 2024). It replaced Gotham SSm, which was then deprecated in Studio and mapped to **Montserrat** (Arial became Arimo) [S] ([DevForum announcement](https://devforum.roblox.com/t/introducing-builder-font-deprecating-gotham-and-arial/2868222); [UltraTextGen](https://ultratextgen.com/answers/what-font-does-roblox-use/)).
  - Bubble chat's default font is `BuilderSansMedium` [DOC] ([bubble-chat](https://create.roblox.com/docs/chat/bubble-chat)).
- **The developer favorite:** "many games are using Fredoka One for literally all of their UI," and it is a popular replacement for Gotham [S] ([DevForum](https://devforum.roblox.com/t/whats-a-good-font-face-to-use-as-a-general-theme-for-a-game/2538479)). Fredoka One and Luckiest Guy, with text strokes, give "that distinctive bold, cartoonish Roblox simulator look" [S] ([DevForum](https://devforum.roblox.com/t/where-can-i-find-this-simulator-font/650336)).
- **Built-in enum fonts** include FredokaOne, LuckiestGuy, Bangers, Creepster, GothamBold/Black, Oswald, SpecialElite, Merriweather, RobotoMono and BuilderSans (Medium/Bold/ExtraBold) [GH] ([Font.yaml](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/enums/Font.yaml)).
- **Usage proxy:** approximate GitHub code-search hits for `Enum.Font.<name>`, 2026-09-30. The public code is skewed toward older and exploit-GUI scripts, and Builder fonts are usually referenced via `Font.new`, so they are undercounted [GH]:

  | Font | Hits |
  |---|---|
  | GothamBold | ~23.2k |
  | SourceSansBold | ~15.3k |
  | GothamBlack | ~4.4k |
  | FredokaOne | ~3.4k |
  | Cartoon | ~1.1k |
  | LuckiestGuy | ~0.7k |
  | Oswald | ~0.5k |
  | Bangers | ~0.4k |
  | SpecialElite | ~0.3k |
  | Merriweather | ~0.3k |
  | Creepster | ~0.2k |

  The "Roblox voice" in type has been **heavy geometric sans (Gotham Bold/Black, now Montserrat/Builder Bold) plus a rounded display font (Fredoka One)**. Typewriter and serif fonts are rare.
- **Roblox's own legibility rules** [DOC] ([adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design); [choose-an-art-style](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/choose-an-art-style)):
  - "Avoid excessively decorative or thin fonts."
  - "Display text on top of a contrasting color or with a stroke."
  - "Use stylized text sparingly, such as for titles or alert text."

### 5.3 How horror games adapt the house style

- **DOORS:**
  - condensed Oswald type [S] ([YouTube short "FONTS used in Roblox DOORS – Oswald"](https://www.youtube.com/shorts/9X9VTeZJwv0));
  - a commissioned UI with "various gradients and image-text/button overlays" [S] ([ArtStation, "Doors UI"](https://www.artstation.com/artwork/qJAd3N));
  - platform conventions such as the X close button [DOC] ([ui-ux-design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).
- **Horror UI threads** on the DevForum favor "dark, minimalist" menus but stress that "a cool-looking font that cannot be deciphered is useless" [S] ([DevForum](https://devforum.roblox.com/t/horror-ui-inspired-by-dark-themes-%E2%80%93-what-can-i-improve-on/3604663); [DevForum](https://devforum.roblox.com/t/feedback-on-horror-game-ui/2495299)).
- **Anomaly games reduce the interface to one or two big, color-coded verbs:**
  - Shawarma: the **shutter**;
  - Animal Hospital: a **Shutters button** plus a scanner that shows "green means safe, red means anomaly, yellow means no patient detected";
  - Home Alone: a **porch-light switch** [S] ([allthings.how](https://allthings.how/catch-every-anomaly-in-animal-hospital-roblox-with-3-checks/); [u7buy](https://www.u7buy.com/blog/animal-hospital-roblox-scanner-guide/); [allthings.how](https://allthings.how/home-alone-anomaly-roblox-how-to-identify-every-visitor/)).
  - Last Ferry's BOARD / TURN AWAY is the right shape. It just needs the Roblox skin. [REC]
- **What to take from horror peers [REC]:** keep the dark palette, but render every control as a chunky, high-contrast, iconified, stroked Roblox button. Reserve decorative or typewriter fonts for *diegetic paper* (the ticket), never for controls or status.

### 5.4 Kits and trends

- Custom UI is commonly built from UICorner, UIStroke and UIGradient rather than flat frames. Generator tools that output "flat rectangles, no gradients, and default fonts" are considered crude [S] ([VizzBees](https://vizzbees.com/blog/best-roblox-ui-generator)).
- **TopbarPlus** is the standard community library for adding icons to Roblox's top bar in native style [S] ([DevForum](https://devforum.roblox.com/t/topbarplus-v340-construct-topbar-icons-with-ease-customise-them-with-themes-dropdowns-captions-labels-and-more/1017485)).
- The *Grow a Garden* UI is a common reference for the current cartoon-simulator look [S] ([DevForum "Grow a garden ui example"](https://devforum.roblox.com/t/grow-a-garden-ui-example/3764006)).

---

## 6. Social and feel signals

### 6.1 Chat, emotes, jumping, names

- **Bubble chat** shows "customizable speech chat bubbles above user avatars **and NPCs**" [DOC] ([bubble-chat](https://create.roblox.com/docs/chat/bubble-chat)).
  - `TextChatService:DisplayBubble` exists for NPC bubbles [GH] (API dump).
  - Bubble chat has been on Roblox since Nov 26, 2009 and was upgraded in 2020 with rounded corners and animations [S] ([Roblox Wiki](https://roblox.fandom.com/wiki/Bubble_chat)).
- **Emotes:** every user has default emotes (dance, point, cheer) via "/e cheer" or the emotes menu [DOC] ([emotes](https://create.roblox.com/docs/characters/emotes)).
- **Leaderboard:** the built-in **PlayerList** leaderboard with `leaderstats` is a core Roblox fixture [DOC] ([leaderboards](https://create.roblox.com/docs/players/leaderboards)). Nilo and Summer Engine both list a leaderboard and "springy" movement as parts of the Roblox feel [S] (§4.1 links).
- **Core UI:** "All Roblox games share a few core UI elements, such as the chat and player list… Replicating these patterns will ensure experienced Roblox users will intuitively understand how to use your interface" [DOC] ([design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)). Roblox launched its redesigned in-game top bar for all users on 2024-10-15 [S] ([X, RTC](https://x.com/Roblox_RTC/status/1846295476418892100); [Roblox Wiki](https://roblox.fandom.com/wiki/Game_Controls)).
- **Last Ferry today:** `HudController.luau` disables Backpack, Health, **EmotesMenu** and **PlayerList**, and draws passenger speech in a HUD label. That removes several Roblox-native signals at once. [REC]

### 6.2 Sounds

- The iconic **"oof"** death sound was removed in July 2022 over licensing and replaced. The community backlash showed how identity-defining default sounds are [S] ([Kotaku](https://kotaku.com/roblox-oof-sound-death-removed-licensing-tallarico-1849335787); [Wikipedia](https://en.wikipedia.org/wiki/Roblox_oof)). The word lives on in game names such as "Zoo or Oof" and "Draw or Oof" [GH] (tube-virality titles).
- Roblox's UX doc cites a "cha-ching!" register sound as model feedback [DOC] ([ui-ux-design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

### 6.3 Lobbies and queues

- **DOORS:** the lobby "serves as a community hub for players to communicate and strategize." It has twelve elevators offering 1–4 player lobbies, with the maximum reportedly raised to 6 in 2025 [S] ([DOORS Wiki, Lobby](https://doors-game.fandom.com/wiki/Lobby); [DOORS Wiki, Lobby Menu](https://doors-game.fandom.com/wiki/Lobby_Menu)).
- "How do I make a lobby teleport system like DOORS has?" is a recurring DevForum question [S] ([DevForum](https://devforum.roblox.com/t/how-do-i-make-lobby-teleport-system-like-doors-has/2428201)).
- Roblox's docs list "walking into circles on the ground in order to queue up for a match" as a convention [DOC] ([ui-ux-design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).
- The studio's earlier research found the same pattern (lobby → party queue by bus, van or elevator → story server) across *Dandy's World*, *Regretevator*, *Dead Rails* and others (repo `research/06-story-driven-games-on-roblox.md`, lines 250 and 416).

### 6.4 Friends and streamers

- Horror with friends "turns into something else entirely": "one person freezes, another sprints the wrong way" [S] ([ExitLag](https://www.exitlag.com/blog/top-10-scary-roblox-games-to-play-with-friends-multiplayer-horror/); [Game Rant](https://gamerant.com/best-roblox-horror-games-play-with-friends/)).
- Roblox tells developers to design for streamers: "could a streamer make great, fun content with it?" *Brookhaven's* "Creator Cam" hides the UI for recording [DOC] ([design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)).
- **YouTube evidence** [GH] ([tube-virality](https://github.com/gpsyrou/tube-virality); my sample of 1,324 daily Trending lists, US/GB/CA/PH/BR/MX/ID, every 3rd day, Feb 2025–Sep 2026):
  - 7,177 unique Roblox-related trending videos.
  - Anomaly and shawarma/animal-hospital videos rose from 14 in Dec 2025 to 35 in Jan 2026 and **peaked at 73 in July 2026**.
  - Big-creator framing is "first night shift… something feels off," with friends:
    - ItsFunneh, "I Worked at a CURSED Shawarma Kiosk in Roblox…" (US, 2025-12-20);
    - Foltyn, "ROBLOX ANIMAL HOSPITAL.." (2.7M views, 2026-07-01);
    - Tyler & Snowi, "CAUGHT ON CAMERA in Animal Hospital Anomaly!… so many FUNNY MOMENTS" (US, 2026-07-12);
    - Googly, "I JOINED the ANOMALIES in Scary Shawarma Kiosk.." (589K);
    - "PLAYING SHAWARMA KIOSK WITH GIRLFRIEND";
    - "NUNCA VENDAS COMIDA A LAS 3AM".
  - Across 1,170 horror-ish Roblox trending titles, **89% contain an ALL-CAPS word**, 16% promise "secret/lore," 14% name a friend or duo, and 17% use emoji.

### 6.5 Roblox humor

- Roblox's docs: "Weirdness and creativity are a core part of Roblox culture" [DOC] ([design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)).
- Shawarma is praised as "a fantastic blend of humor and genuine scares" [S, U] ([earnaldo](https://earnaldo.com/blog/scary-shawarma-kiosk)). It also sorts anomalies into **dangerous, harmless, special and event** types, so some oddballs are safe to serve [S] ([Beebom](https://beebom.com/all-anomalies-in-scary-shawarma-kiosk/); [Sportskeeda](https://www.sportskeeda.com/roblox-news/all-scary-shawarma-kiosk-the-anomaly-anomalies)).
- The biggest hits of 2025 run on memes:
  - *Steal a Brainrot's* Italian-brainrot characters, AI-generated animal hybrids such as Tralalero Tralala and Tung Tung Tung Sahur [S] ([Forbes](https://www.forbes.com/sites/danidiplacido/2025/09/19/robloxs-italian-brainrot-trend-explained/); [Gabb](https://gabb.com/blog/steal-a-brainrot/));
  - "admin abuse" live events. Flamingo's "I hosted an ADMIN ABUSE on GROW A GARDEN" reached 5.77M views, and 4.4% of all Roblox trending titles in the sample mention admin or admin abuse [GH].

---

## 7. Thumbnails, icons and the store page

### 7.1 Official rules

| Asset | Rules [DOC] |
|---|---|
| **Thumbnails** ([thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)) | 16:9 at 1920×1080. Up to 10 images or videos. "avoid placing any essential text or elements at the bottom," because the player count covers it. Horror example: "dark and stormy theme." Videos must be authentic, and text overlays kept sparse. |
| **Thumbnail personalization** (same page) | Rotates 2–5 home-page thumbnails per user segment. Average **+8.5% qualified play-through rate**, up to +50%. Keep several active. |
| **Icons** ([experience-icons](https://create.roblox.com/docs/production/publishing/experience-icons)) | 512×512, and must still read at ~150×150. "Heavy color balance and contrast for a horror game." |
| **Discovery** ([discovery](https://create.roblox.com/docs/discovery)) | "Add your own spin to existing trends in the title, images, description, and in-game content". Mismatched metadata and near-duplicate games are down-ranked. "Most important" signals: play-through rate (the thumbnail's job), first-play bounce rate (a negative signal), play days and playtime. "Important": intentional co-play days, qualified sessions and spend. |
| **Descriptions** ([descriptions](https://create.roblox.com/docs/production/publishing/descriptions)) | "Feel free to use emojis as desired for extra flair." (Experimental guidance.) |

### 7.2 What top thumbnails do (community best practice)

- "Faces and expressive poses convert: shock, excitement, fear, triumph create an instant hook that a static logo never will."
- "If you use words, use two to four of them, huge and bold."
- Use a posed avatar or key model on a bold, high-contrast backdrop [S] ([generalistprogrammer](https://generalistprogrammer.com/tutorials/how-to-make-a-roblox-game-icon); [VizzBees](https://vizzbees.com/blog/how-to-make-a-roblox-thumbnail); [Simplified](https://simplified.com/blog/ai-design/roblox-thumbnail-trends)).
- "The strongest thumbnails have a single focal point — a character mid-action, one dramatic object, one emotion… add a rim light or an outline around your character" [S] ([CreatorXP](https://creatorxp.gg/guides/roblox-game-icon-mistakes)).
- For horror, "pick one focal point — usually the monster or the player's terrified face" [S, low authority] ([Roblox GFX horror guide](https://roblox-gfx-pack-horror.pages.dev/)).
- The **Roblox GFX** pipeline is standard: export avatars from Studio, pose and light them in Blender, render [S] ([DevForum GFX tutorial](https://devforum.roblox.com/t/create-roblox-gfx-tutorial-blender-2881828329/890782); [Renderbux](https://www.renderbux.com/guides/roblox-gfx-without-blender)).
- "Screaming" and surprised avatar faces are a popular comedic look [S] ([MaxPower Gaming](https://www.maxpowergaming.co/post/7-popular-roblox-ugc-trends-players-obsessed-with)).
- The studio's earlier research lists "Monster-face thumbnail" and "Title is the logline; thumbnail is the monster" as patterns of the micro-horror hits (repo `research/06-story-driven-games-on-roblox.md`, lines 279 and 528).

### 7.3 Titles: emoji and [TAGS] are a Roblox signal

- In the Jan 6, 2026 top-earning snapshot (410 games), **62% of names contain an emoji and 58% a bracket or paren tag**. In the top 50 by players, 37 have emoji and 26 have tags [GH] ([snapshot](https://github.com/nickpio/top-earning-parser/blob/master/runs/2026-01-06/pruned/2026-01-06_top-earning_top1500_enriched_pruned.json)).
- Horror examples from that list:
  - "99 Nights in the Forest 🔦";
  - "[🎆] Forsaken";
  - "Scary Shawarma Kiosk: the ANOMALY [horror]";
  - "Terminal 13: Not Human [HORROR]";
  - "DOORS [DAILY RUNS📟]";
  - "Piggy [NEW CHAPTER]";
  - "Movie Massacre 📼 [HORROR]";
  - "Road-Side Sushi [HORROR]".
- Also "Animal Hospital (Anomaly) 🧪" [S] ([Rolimons](https://www.rolimons.com/game/78515283254292)).

### 7.4 Five-minute thumbnail audit (do this on the live site, which I could not open)

Open the Roblox **Charts → Top Trending / Horror** sort on a phone and check the first 20 horror tiles:
1. How many show a **Roblox avatar face**?
2. How many show **one monster face**?
3. How many have **≤4 words**?
4. How many use a **dark backdrop with a single saturated accent** (red, cyan or yellow)?

Last Ferry's tile must survive side-by-side at ~150 px. [REC]

---

## 8. Top games of 2025–2026 and what their looks share

| Game (launch) | Scale (source) | Look and presentation | Source |
|---|---|---|---|
| **Grow a Garden** (Mar 2025) | 1B visits in 33 days; ~21.3M CCU (June 2025) | Cute, bright, calm. Cartoon crops and pets, chunky UI, weekly "admin abuse" events. | [S] [Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden), [PocketGamer.biz](https://www.pocketgamer.biz/robloxs-peak-concurrent-user-count-hits-record-474m-as-steal-a-brainrot-and-grow-a-garden-compete/), [Malay Mail](https://www.malaymail.com/news/tech-gadgets/2025/06/22/grow-a-garden-is-robloxs-calming-new-hit-surpassing-nine-billion-visits/179854) |
| **Steal a Brainrot** (2025) | First game past 25M CCU; 6.0M players at the Jan 6, 2026 snapshot | Meme characters (AI-born Italian brainrot) on conveyors, bright bases, avatars stealing. Later added "Guest" and "1x1x1x1" lore characters. | [S] [PocketGamer.biz](https://www.pocketgamer.biz/robloxs-peak-concurrent-user-count-hits-record-474m-as-steal-a-brainrot-and-grow-a-garden-compete/); [GH] snapshot and tube-virality |
| **99 Nights in the Forest** (2025) | 14.2M peak CCU; 26B visits (Apr 2026); Best Adventure and Best Horror at the 2025 RIAs | Stylized night forest. A campfire as the light anchor, the Deer, cultists, kids to rescue. Avatars in third person [B]. | [S] [99 Nights Wiki](https://99-nights-in-the-forest.fandom.com/wiki/99_Nights_in_the_Forest:_Game) |
| **Plants vs Brainrots** (fall 2025) | ~8.65M CCU record (Oct 2025) | Grow a Garden × Steal a Brainrot × PvZ. Bright, meme humor. | [S] [MaxPower](https://www.maxpowergaming.co/post/roblox-s-latest-breakout-game-is-plants-vs-brainrots) |
| **Dead Rails** (2025) | Top-grossing breakout | Western and zombies on Roblox bodies. Green zombies in western clothes. Fan animations star the noob (25.2M-view clip). | [S] [Villains Wiki](https://villains.fandom.com/wiki/Zombies_(Dead_Rails)); [GH] tube-virality |
| **Forsaken** (launched Dec 25, 2024) | ~4B visits; ~80K average CCU; Best Survival Experience at the 2025 RIAs | Roblox-lore cast (noob, guests, c00lkidd, 1x1x1x1), blocky bodies. | [S] [Forsaken Wiki](https://forsaken2024.fandom.com/wiki/FORSAKEN); [RoWatcher](https://rowatcher.com/games/6331902150/forsaken) |
| **DOORS** (2022) | 5B+ visits; Best Visual Design at the 2023 RIAs; Best Use of Audio at the 2026 RIAs | Moody lighting, custom entities, avatar players, elevator lobby. | [S] [Shapes](https://shapes.inc/fandom/doors-roblox-game); [Pocket Tactics](https://www.pockettactics.com/roblox/innovation-awards-2026) |
| **Pressure** (Jul 2024) | 3.1K players at the Jan 2026 snapshot | The realism flagship. | [S] [Pressure Wiki](https://pressure.fandom.com/wiki/Pressure); [GH] snapshot |
| **Scary Shawarma Kiosk** (Aug 2025) | 1.2–1.3B visits; ~90K players at the Jan 2026 snapshot | First-person kiosk, CCTV, shutter, 4 players, Roblox people plus anomalies. | [S] [Roblox Wiki](https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror)); [GH] snapshot |
| **Animal Hospital (Anomaly)** (May 2026) | ~1.2–1.3M peak CCU; 1.15B visits (Jul 2026); swept the 2026 RIAs | Cute animal patients with wrongness tells, 1–4 players, classes, sanity. "Creative identity captures players' attention almost immediately". | [S] [Animal Hospital Wiki](https://animal-hospital.fandom.com/wiki/Animal_Hospital_(Game)); [RoWatcher](https://rowatcher.com/games/10148749921/animal-hospital-anomaly); [Yahoo](https://tech.yahoo.com/gaming/articles/winners-roblox-innovation-awards-2026-172522234.html) |
| **Steal An Egg** (Jul 2026) | 14.27M peak CCU (Sep 19, 2026) [U]; briefly pulled in Aug 2026 | Egg and pet stealing, the "steal" formula. | [S/U] [RoVitals](https://rovitals.com/game/107778070777162); [1vX](https://1vx.gg/news/steal-an-egg-was-pulled-from-roblox-after-hitting-no-1-with-500-000-concurrent-players) |
| **Dandy's World** (2024) | 105K players (Jan 2026 snapshot) | Cartoon "Toons," mascot horror, elevator descent. | [GH] snapshot; studio research/06 |
| **Fish It!** (2025–26) | 889K players (Jan 2026 snapshot) | Fishing. | [GH] snapshot |
| **Dress to Impress / Fisch / Blue Lock Rivals / Ink Game** | 75K / 59K / n.a. / 17K players (Jan 2026 snapshot) | Fashion runway; bright fishing islands; anime soccer; Squid Game. Details not verified this session. | [GH] snapshot; looks [B] |

- **Platform context:** Roblox hit a record **47.4M concurrent users** in Q3 2025, driven by Steal a Brainrot and Grow a Garden [S] ([PocketGamer.biz](https://www.pocketgamer.biz/robloxs-peak-concurrent-user-count-hits-record-474m-as-steal-a-brainrot-and-grow-a-garden-compete/)).
- **YouTube Trending share** (unique Roblox videos in my sample) [GH]:

  | Game | Unique videos |
  |---|---|
  | Steal a Brainrot | 1,545 |
  | Brookhaven | 884 |
  | 99 Nights | 635 |
  | Grow a Garden | 316 |
  | Blox Fruits | 249 |
  | Dead Rails | 178 |
  | Animal Hospital | 153 |
  | Shawarma/kiosk | 62 |
  | DOORS | 49 |
  | Forsaken | 26 |
  | Pressure | 0 |
  | Grace | 0 |

  These are keyword matches, so directional only.

**What the hits share** [REC, synthesized from the rows above]:
1. **Avatars everywhere.** The player is always a visible Roblox person. NPCs are either Roblox people or clearly *custom* monsters, never neutral mannequins.
2. **Premise legible in one frame and one line** (garden, steal, 99 nights, kiosk, hospital).
3. **High-contrast, saturated focal colors**, even in horror: a campfire, neon, a red shutter.
4. **Chunky, iconified UI.**
5. **Social mechanics that produce clips:** stealing, trolling, co-op panic, admin abuse.
6. **Meme or lore IP:** brainrot, noob, Guest, myths.
7. **Frequent events** tagged in the title.

---

## 9. Last Ferry audit (read-only review of the repo)

| Area | Current implementation | Reads as | Evidence |
|---|---|---|---|
| Player characters | `Players.CharacterAutoLoads = false` | "Not Roblox": no avatars and no co-presence | `ServerScriptService/Server.server.luau:12` |
| Passengers | Part-built figures, `SmoothPlastic`, **no faces**, muted coats | Mannequins. In genre grammar, faceless means monster | `ServerScriptService/Services/PassengerService.luau` |
| Lighting | `LightingStyle.Realistic`, ClockTime 2, Ambient (26,30,38), Atmosphere density 0.36, haze 2.4, shadow-based tell | Moody PC-indie. On phones, shadows vanish below QL4 | `ServerScriptService/Services/WorldService.luau` `setUpLighting()` |
| HUD fonts | Oswald (titles), Builder Sans (body), Special Elite (ticket), Merriweather (speech), Roboto Mono | "Premium dark minimal" (VizzBees' minimal style), not Roblox chunky | `ReplicatedStorage/Ui/Theme.luau` |
| HUD colors | Dark blue-grey panels (20,25,32), muted green and red buttons | Low-saturation indie | `Theme.luau` |
| Core UI | Emotes menu off, player list off, chat moved bottom-left | Removes Roblox-native signals | `ReplicatedStorage/Controllers/HudController.luau:76-83` |
| Speech | HUD label, top centre | A visual-novel feel rather than Roblox bubbles | `HudController.luau` header comment |
| Lobby | None (straight into the booth) | Misses the first Roblox moment | README flow |
| Strengths to keep | 1–4 co-op, anomaly night-shift premise, visible tells, 5 nights, Mild fear target | **On-trend genre** (Shawarma, Animal Hospital) | README; §3.5 |

---

## 10. Recommendations for Last Ferry (ranked by impact)

The ranking weighs impact on "reads as Roblox at a glance" (a screenshot, a 5-second clip, the thumbnail), the strength of the evidence, and cost. All items are [REC] and built on the evidence cited.

### R1 (highest). Make passengers look like Roblox people; make the drowned wrong *on top of* that

**Why**
- The genre's grammar is a normal Roblox person plus wrongness (§3.5–3.6).
- Faceless figures read as monsters or "not Roblox."
- Roblox's own docs stress shared avatar identity (§3.1).

**How: two options**
- **(A) Keep the "no asset IDs" rule.** Build classic-proportion rigs in code:
  - `Head` part with a `SpecialMesh` `MeshType.Head` and a face `Decal` = `rbxasset://textures/face.png` (the built-in classic smile Roblox's own dummy generator uses);
  - Torso 2×2×1, limbs 1×2×1, a `Humanoid` and `BodyColors`.
  - Dress them with part-built coats, hats and bags in *Roblox* colors, including a few instantly readable archetypes (noob yellow/blue/green; a "bacon-hair"-style part hairdo; a 2000s tourist).
  - This alone flips the read from "indie mannequin" to "Robloxian." ([Client-Tracker GenerateDummy](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/scripts/CoreScripts/Modules/FTUX/Utility/GenerateDummy.lua); [Nevermore](https://github.com/Quenty/NevermoreEngine/blob/main/src/rigbuilderutils/src/Shared/RigBuilderUtils.lua))
- **(B) Best look.** Spawn real avatar outfits with `Players:CreateHumanoidModelFromDescriptionAsync`, using curated `HumanoidDescription`s or outfits (`GetHumanoidDescriptionFromOutfitIdAsync`; `GetHumanoidDescriptionFromUserIdAsync` also exists) [DOC] ([appearance](https://create.roblox.com/docs/characters/appearance)) [GH] (API dump).
  - Hair, layered clothing and accessories make the queue look like a real Roblox server.
  - Curate the list rather than pulling random users, to avoid unmoderated or inappropriate outfits.

**Tells to layer on top** (keep breath, drips, shadow, name):
- **Era tell (optional mechanic):** living passengers are modern R15 avatars with animated faces. The 1999 drowned are **classic blocky figures with frozen classic faces**. On later nights the drowned "learn" to wear modern outfits, which fits the design's "the drowned hide one more tell each night."
  - This turns 2026's classic-face nostalgia (§3.3) into a scare.
  - NPC rigs don't affect 18+ DevEx eligibility [DOC].
- **Genre tells from peers:**
  - white or hollow eyes, too-wide smile, slightly wrong proportions, a face that's missing only on second look (Shawarma, Animal Hospital, Terminal 13; §3.5);
  - a passenger wearing **a party member's own avatar** as a late-game doppelgänger. [REC; private servers or opt-in if you prefer]
- **Mara** (the girl in the red coat) should read as a classic child avatar in a bright red coat. She could be a thumbnail star.

### R2. Give players bodies and let them see each other in the booth

**Why**
- Avatars are the platform; "Intentional co-play days" is a discovery ranking signal (§3.1, §7.1).
- Streamers need to show friends reacting (§6.4).

**How**
- Turn character loading back on, or spawn characters on server start. Seat 1–4 avatars on booth stools or standing positions (R15, the default).
- Keep the fixed window camera, but add:
  - a **"turn around" glance** (a hold or button) that looks back into the booth at your teammates;
  - teammates' reflections in the window glass, or a small booth mirror;
  - nameplates or "@name BOARDED" call-outs;
  - an avatar highlight on whoever pressed the button.
- Let players use **emotes** (re-enable `EmotesMenu`) and **jump** in the lobby, and ideally in the booth ("stand up" mode).
- Re-enable the **PlayerList** with `leaderstats` (for example *Nights* and *Correct Calls*), even if it starts collapsed [DOC] ([leaderboards](https://create.roblox.com/docs/players/leaderboards)).

### R3. Reskin the HUD in chunky Roblox style (keep it dark, drop the "indie")

**Why:** the house style is chunky and stroked, and Roblox's docs discourage thin or decorative fonts on phones (§5).

**Buttons**
- **BOARD:** saturated green, ✓ icon.
- **TURN AWAY:** saturated red, ✕ icon.
- Both about 20–30% larger, `UICorner` 12–16 px, `UIStroke` 3 px near-black, subtle top-to-bottom `UIGradient`, and a hard drop shadow.
- Press tween: scale 0.92, then Back-out to 1.0. Hover: 1.05. Pair each press with a stamp thunk.

**Type**
- Controls and status: **Fredoka One** or **Builder Sans ExtraBold** in white with a dark stroke.
- Keep **Oswald** only for big titles if you like it (DOORS does).
- **Special Elite only on the paper ticket** (diegetic).
- Drop Merriweather and Roboto Mono from gameplay text.

**Status**
- Chunky icon pips for the three lanterns.
- A "NIGHT 2/5" pill and big clock numerals.
- Short, bold warning banners, color-coded, with icons.

**Placement**
- Respect Roblox's top bar (top-left) and chat.
- Keep the bottom centre clear, as the design already does.

### R4. Relight and recolor for "Roblox night," phones first

**Why:** most players are on low-spec phones. Shadows vanish below quality level 4, and Future lighting falls back to voxel lighting (§4.5).

**How**
- Raise `Ambient`/`OutdoorAmbient` and lower Atmosphere density and haze until silhouettes and faces read at graphics levels 1–3.
- Add **saturated practical accents**:
  - neon "TICKETS" and "GULL ISLAND" signs;
  - the ferry's cabin and running lights (red, green, white);
  - red-and-white lifebuoys and yellow safety rails;
  - a warm orange booth lamp.
- Build chunkier props (bollards, rope coils, crates, gangway rails) in Plastic, SmoothPlastic and WoodPlanks. Avoid photoreal textures.
- **Try `LightingStyle.Soft`**, Roblox's "flat, retro‑Roblox look," for the environment [DOC]. The shadow tell already has a fallback patch, and it can become an explicit, stylized shadow decal that reads at every quality level.
- **Test on a low-end Android** as Roblox recommends [DOC] ([test-on-hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)).

### R5. Add a pier lobby with a party gangway (the DOORS-elevator pattern)

**Why:** the first minute is where players see avatars, jump, chat and form a party (§6.3). It's also a streamer moment.

**How**
- Spawn in third person on a lit, lively pier.
- A **gangway / ticket-gate queue pad** (walk-in circle) holds 1–4 players and counts down, then starts the shift.
- Add a board of last night's survivors (leaderboard) and a lost-and-found shop later. Any monetization is out of scope here.

### R6. Store page in Roblox format

**Icon** (512×512, readable at 150 px)
- One pale, dripping Roblox-avatar passenger's face at the ticket window.
- Warm lamp rim light against a cold blue-black background.
- A single red accent (Mara's coat or the stamp).

**Thumbnails** (1920×1080, 3–5 active for personalization [DOC])
- (a) 2–4 terrified player avatars in the booth vs. a drowned passenger at the glass, with "DON'T LET THEM BOARD";
- (b) a close-up with no breath in the cold, with "NO BREATH?";
- (c) Mara, with "IS THIS THE FERRY HOME?"

Keep text off the bottom band [DOC].

**Title** in platform style, for example **"Last Ferry ⛴️ [HORROR]"** or **"Last Ferry: Don't Let Them Board (Anomaly) ⛴️"** (§7.3). "Anomaly" is an accurate genre keyword that search understands [DOC] ([discovery](https://create.roblox.com/docs/discovery): semantic search).

**Framing for creators:** "night shift" and "3AM" pitch lines ("Never take the ferry at 3AM") match how creators title these games (§6.4). Setting `ClockTime` near 3 costs nothing.

### R7. Roblox humor and lore cameos (virality)

- Add a **harmless-oddball category**, as Shawarma does: a noob with a fishing rod, a bacon-hair tourist with too many suitcases, a man in a fish costume, a speed-walking guest. Board them and nothing bad happens (§6.5).
- Add **Roblox lore nods**:
  - one drowned passenger in classic "Guest" style (the Guest and 1x1x1x1 icons are alive in Forsaken and Steal a Brainrot, §3.4);
  - a ticket dated 2006 as an easter egg.
- **"Knows your name" should use the player's Roblox DisplayName or @username**, which is exactly what Shawarma's "Hacker" anomaly does (§3.5).
- Add a funny or dramatic **fail state** (the tide washes the booth, ragdolls, a comedic splash) within Mild fear [DOC] (maturity target in the README). It gives streamers a clip.

### R8. Roblox-native feedback audio

- Crisp UI clicks and a **"cha-ching"** or stamp for correct boards (Roblox's docs use the cha-ching as the model of feedback, §6.2).
- A comedic splash for mistakes, alongside the horror stingers.
- Passenger speech as **bubble chat** (`TextChatService:DisplayBubble`) with an optional subtitle. Players chat in bubbles too [DOC] ([bubble-chat](https://create.roblox.com/docs/chat/bubble-chat)).

### R9. Small physical interactions in the booth (genre grammar)

Peers use a **window + photo + CCTV** triad and physical tasks (§3.5, §5.3). Add 1–2 in-booth stations that someone must lean to or walk to:
- a CCTV monitor showing the passenger's back (tells visible only there);
- a manifest board with an "E" proximity prompt [DOC] (the convention in [ui-ux-design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

This lets 4 players split roles as Shawarma players do [S] ([MuMu guide](https://www.mumuplayer.com/blog/roblox-scary-shawarma-kiosk-guide.html)).

**Acceptance test for all of the above [REC]:**
- Show a 5-second phone screen recording and the thumbnail to five Roblox players aged 10–17, without the title, and ask: "What platform is this? Would you play it with friends?"
- Ship when four of five say "Roblox" without hesitation.

---

## 11. What to avoid

1. **Faceless mannequins as the normal baseline.** They read as monsters or "not Roblox" (§3.6).
2. **No visible players.** No bodies, no emotes, no player list, no bubbles: the platform's social identity is switched off (§3.1, §6.1).
3. **Premium-dark minimal UI with thin, typewriter or serif fonts for controls.** Roblox's docs warn against "excessively decorative or thin fonts" (§5.2).
4. **Mood that only exists at high graphics settings.** Below quality 4 there are no shadows; tune for level 1–3 first (§4.5).
5. **Photoreal PBR textures next to blocky avatars.** A style clash (§4.3).
6. **Long text intros.** Roblox favors fast, visual onboarding: "Lengthy, detailed tutorials are liable to bore users" [DOC] ([design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)).
7. **Misleading thumbnails** or a copied title or visuals from Shawarma or Animal Hospital. Both are down-ranked [DOC] ([discovery](https://create.roblox.com/docs/discovery)).
8. **R6-only player characters**, if the U.S. 18+ DevEx rate matters. NPCs are exempt [DOC] ([18+ DevEx](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate)).
9. **Gore or realistic blood.** Keep Mild or Moderate fear to keep the audience wide (studio research/06; README maturity target).

---

## 12. Open questions and things to verify on live pages

- **Thumbnail audit:** I could not view any Roblox store page, thumbnail or icon image. Do the §7.4 audit on a phone.
- **Shawarma NPC build:** I could not confirm whether Shawarma's customers are R15 player-outfit rigs or custom meshes. Play it for 10 minutes and note the customers' rig, faces and clothing.
- **Animal Hospital:** I could not confirm Animal Hospital's camera (first or third person) or its UI fonts.
- **Reddit:** no Reddit threads could be read. If the studio head wants direct quotes from r/roblox or r/robloxgamedev on "too realistic," pull them manually.
- **Hit peaks:** peak CCUs for 2026 hits (Steal An Egg 14.27M, Animal Hospital 1.3M) come from trackers via search [S/U]. Confirm them on RoMonitor or Rolimons before quoting publicly.

---

## Appendix A: YouTube Trending sample (method)

- **Source:** [`gpsyrou/tube-virality`](https://github.com/gpsyrou/tube-virality), `assets/meta/trending/trending_videos_{CC}_{YYYYMMDD}.json` (YouTube Data API "most popular" per region).
- **Sample:** US, GB, CA, PH, BR, MX and ID; every 3rd available day from 2025-02-23 to 2026-09-29; **1,324 snapshots, 8,225 Roblox video-days, 7,177 unique Roblox videos.** A video counts as Roblox-related when "roblox" appears in the title, description or tags.
- **Game counts** are keyword matches on title, description and tags, so expect some false positives and negatives.
- **"Horror-ish"** means 1,170 videos matching horror, anomaly or night-shift terms or known horror titles.
- **Examples cited in the text:** Ninja Roblox "When they forget noob in town ☠️ PT8 – Roblox Dead Rails" (25.2M, PH 2025-06-28); ItsFunneh "I Worked at a CURSED Shawarma Kiosk in Roblox…" (US 2025-12-20); Foltyn "ROBLOX ANIMAL HOSPITAL.." (2.7M, 2026-07-01); Tyler & Snowi "CAUGHT ON CAMERA in Animal Hospital Anomaly!" (US 2026-07-12); Googly "I JOINED the ANOMALIES in Scary Shawarma Kiosk.." (KE 2026-02-15); KreekCraft "BUILDERMAN LIVE EVENT" and "THE HUNT: ROBLOX 20" (Sept 2026); CORSO "GUEST 666 IS FINALLY HERE!" (Forsaken, US 2025-11-01); xMarcelo "GUEST, 1X1X1X1… ROUBE UM BRAINROT" (BR 2025-11-02); Flamingo "They added ME to ROBLOX FORSAKEN" (GB 2025-07-11) and "I hosted an ADMIN ABUSE on GROW A GARDEN" (5.77M).

## Appendix B: Main sources

**Roblox official docs** (read via [github.com/Roblox/creator-docs](https://github.com/Roblox/creator-docs); live under create.roblox.com/docs):
- [design-for-roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)
- [roblox-user-base](https://create.roblox.com/docs/production/roblox-user-base)
- [ui-ux-design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- [choose-an-art-style](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/choose-an-art-style)
- [adaptive-design](https://create.roblox.com/docs/production/publishing/adaptive-design)
- [accessibility](https://create.roblox.com/docs/production/publishing/accessibility)
- [thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)
- [experience-icons](https://create.roblox.com/docs/production/publishing/experience-icons)
- [descriptions](https://create.roblox.com/docs/production/publishing/descriptions)
- [discovery](https://create.roblox.com/docs/discovery)
- [bubble-chat](https://create.roblox.com/docs/chat/bubble-chat)
- [emotes](https://create.roblox.com/docs/characters/emotes)
- [leaderboards](https://create.roblox.com/docs/players/leaderboards)
- [appearance](https://create.roblox.com/docs/characters/appearance)
- [characters](https://create.roblox.com/docs/characters)
- [r6-to-r15-adapter](https://create.roblox.com/docs/characters/r6-to-r15-adapter)
- [head-comparison](https://create.roblox.com/docs/art/characters/head-comparison)
- [18-plus-devex-rate](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate)
- [lighting](https://create.roblox.com/docs/environment/lighting)
- [materials](https://create.roblox.com/docs/parts/materials)
- [test-on-hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)
- [improve](https://create.roblox.com/docs/performance-optimization/improve)
- [npc-kit](https://create.roblox.com/docs/resources/npc-kit)
- [Duvall Drive: construct-the-house](https://create.roblox.com/docs/resources/the-mystery-of-duvall-drive/construct-the-house)
- [Font enum](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/enums/Font.yaml)

**GitHub code and data:**
- [Client-Tracker GenerateDummy.lua](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/scripts/CoreScripts/Modules/FTUX/Utility/GenerateDummy.lua)
- [Nevermore RigBuilderUtils](https://github.com/Quenty/NevermoreEngine/blob/main/src/rigbuilderutils/src/Shared/RigBuilderUtils.lua)
- [Super-Nostalgia-Zone](https://github.com/MaximumADHD/Super-Nostalgia-Zone)
- [shawarma-kiosk-share](https://github.com/cdg-hue/shawarma-kiosk-share)
- [tube-virality](https://github.com/gpsyrou/tube-virality)
- [top-earning-parser (2026-01-06)](https://github.com/nickpio/top-earning-parser/blob/master/runs/2026-01-06/pruned/2026-01-06_top-earning_top1500_enriched_pruned.json)

**Characters and faces** [S]:
- [Gamezebo](https://www.gamezebo.com/features/roblox-classic-faces/)
- [PC Gamer](https://www.pcgamer.com/games/roblox-walks-back-some-of-its-dramatic-changes-to-avatar-faces-but-not-enough-to-make-everyone-happy/)
- [Dexerto](https://www.dexerto.com/gaming/roblox-finally-removes-classic-faces-as-major-avatar-update-rolls-out-3340618/)
- [piunikaweb](https://piunikaweb.com/2026/03/25/roblox-replacing-classic-heads-nifty-trick-brings-it-back/)
- [1AM Gamer](https://1amgamer.com/posts/roblox-classic-faces-removed-dynamic-heads-community-reaction-2026)
- [Game Rant](https://gamerant.com/roblox-classic-faces-removed-gone-offsale-update/)
- [KreekCraft on X](https://x.com/KreekCraft/status/2016314032920101213)
- [Reface (DevForum)](https://devforum.roblox.com/t/reface-restore-classic-decal-faces-following-the-dynamic-head-migration-v110/4560579)
- [Normal face](https://roblox.fandom.com/wiki/Normal_face)
- [Noob](https://roblox.fandom.com/wiki/Noob)
- [Beebom bacon](https://beebom.com/roblox-bacon/)
- [Pocket Tactics bacon](https://www.pockettactics.com/roblox-bacon)
- [Roblox myth](https://roblox.fandom.com/wiki/Roblox_myth)
- [TV Tropes: Forsaken](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ForsakenRoblox)
- [Roblox Replay 2025](https://about.roblox.com/newsroom/2025/12/roblox-replay-decoded-search-style)
- [Roblox IR](https://ir.roblox.com/news/news-details/2025/Roblox-Releases-New-Data-Decoding-Search-and-Style-Trends-in-Digital-Experiences/default.aspx)
- [R6/R15 DevForum](https://devforum.roblox.com/t/why-do-combat-game-developers-lean-more-towards-r6-rather-than-r15/3136549)

**Anomaly genre** [S]:
- [Shawarma (Roblox Wiki)](https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror))
- [TechWiser](https://techwiser.com/scary-shawarma-kiosk-anomalies-guide/)
- [Deltia's](https://deltiasgaming.com/scary-shawarma-kiosk-all-anomalies-guide-roblox/)
- [Beebom](https://beebom.com/all-anomalies-in-scary-shawarma-kiosk/)
- [spottheanomaly.wiki](https://spottheanomaly.wiki/roblox-anomaly-games-list)
- [Animal Hospital Wiki](https://animal-hospital.fandom.com/wiki/Animal_Hospital_(Game))
- [allthings.how](https://allthings.how/catch-every-anomaly-in-animal-hospital-roblox-with-3-checks/)
- [Variety](https://variety.com/2026/gaming/news/animal-hospital-roblox-innovation-awards-20th-anniversary-1236860184/)
- [Pocket Tactics RIA 2026](https://www.pockettactics.com/roblox/innovation-awards-2026)
- [Terminal 13 (Deltia's)](https://deltiasgaming.com/roblox-how-to-play-terminal-13-not-human/)
- [Home Alone (allthings.how)](https://allthings.how/home-alone-anomaly-roblox-how-to-identify-every-visitor/)
- [Weird Strict Dad](https://villains.fandom.com/wiki/Mysterious_Man_(Weird_Strict_Dad))
- [That's Not My Robloxian](https://thats-not-my-robloxian.fandom.com/wiki/Clones)
- [Night 67 (TechBaked)](https://techbaked.com/best-roblox-horror-games-scariest/)

**World, UI and thumbnails** [S]:
- [DevForum design-style thread](https://devforum.roblox.com/t/does-the-design-style-of-a-game-determine-its-success/236721)
- [Low Poly vs Realistic](https://devforum.roblox.com/t/low-poly-vs-realistic-for-a-role-playing-game/3143597)
- [Pressure (Shapes)](https://shapes.inc/fandom/pressure)
- [The Mimic (Screenwise)](https://screenwiseapp.com/guides/the-mimic-roblox)
- [Lord CowCow on X](https://x.com/greenlegocats/status/2067748060680364362)
- [WoodReviewerRBX](https://woodreviewerrbx.com/2025/05/23/on-retro-looking-games/)
- [Roblox Classicism](https://robloxloredatabase.miraheze.org/wiki/Roblox_Classicism)
- [DOORS Retro Mode](https://doors-game.fandom.com/wiki/2024_April_Fools_Event)
- [Future Is Bright](https://roblox.fandom.com/wiki/Future_Is_Bright)
- [Statista mobile](https://www.statista.com/statistics/1190919/roblox-games-users-global-distribution-platform/)
- [VizzBees UI](https://vizzbees.com/blog/roblox-ui-design-ideas)
- [Fredoka thread](https://devforum.roblox.com/t/whats-a-good-font-face-to-use-as-a-general-theme-for-a-game/2538479)
- [Builder font announcement](https://devforum.roblox.com/t/introducing-builder-font-deprecating-gotham-and-arial/2868222)
- [DOORS fonts short](https://www.youtube.com/shorts/9X9VTeZJwv0)
- [DOORS lobby](https://doors-game.fandom.com/wiki/Lobby)
- [Oof (Kotaku)](https://kotaku.com/roblox-oof-sound-death-removed-licensing-tallarico-1849335787)
- [Bubble chat history](https://roblox.fandom.com/wiki/Bubble_chat)
- [Top bar (RTC)](https://x.com/Roblox_RTC/status/1846295476418892100)
- [generalistprogrammer](https://generalistprogrammer.com/tutorials/how-to-make-a-roblox-game-icon)
- [CreatorXP](https://creatorxp.gg/guides/roblox-game-icon-mistakes)
- [VizzBees thumbnails](https://vizzbees.com/blog/how-to-make-a-roblox-thumbnail)
- [PocketGamer.biz 47.4M CCU](https://www.pocketgamer.biz/robloxs-peak-concurrent-user-count-hits-record-474m-as-steal-a-brainrot-and-grow-a-garden-compete/)
- [Forbes brainrot](https://www.forbes.com/sites/danidiplacido/2025/09/19/robloxs-italian-brainrot-trend-explained/)
- [99 Nights Wiki](https://99-nights-in-the-forest.fandom.com/wiki/99_Nights_in_the_Forest:_Game)
- [Forsaken Wiki](https://forsaken2024.fandom.com/wiki/FORSAKEN)
