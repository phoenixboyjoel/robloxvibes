# Roblox vibe case studies for Last Ferry

> **Written before the "look and feel like Roblox" overhaul (2026-09-30).**
> Where it describes Last Ferry, it describes the game as it was then:
> faceless passengers, no player avatars, a premium-dark HUD and no audio.
> What was built from it is in `games/last-ferry` (see its README and
> ARCHITECTURE.md); the ranked recommendations were followed in that order.

**Prepared for:** Phoenix Feather Studios (Last Ferry team)
**Research date:** 2026-09-30
**Question:** How do the Roblox games closest to Last Ferry look and present themselves, what made them succeed or fail, and what should Last Ferry change so it "looks and gives the Roblox vibe"?

---

## 0. Method, access limits and confidence tags (read first)

**Access limits in this session.**

- WebFetch could open only GitHub (github.com, raw.githubusercontent.com, one api.github.com search call). Everything else was blocked by the egress proxy: Roblox.com, Fandom wikis, Rolimons, RoMonitor, ServicesPV, Reddit, YouTube, TikTok, Wikipedia, Sportskeeda, Dexerto, Beebom, TechWiser, GameRant, TheGamer, PC Gamer, Polygon, Pocket Tactics, IGN and every guide site I tried.
- WebSearch worked, so most game facts come from **search-engine summaries** of the pages cited next to them. I could not open those pages to check them.
- About 75 WebSearch queries in, the **session-wide search budget (200, shared with other agents) ran out**. That left some categories thin, as flagged in §8, §10 and §15.
- To make up for it, I pulled **GitHub-hosted datasets** directly:
  - a Roblox top-earning index with daily CCU for January 2026;
  - a January 2026 snapshot of about 410 top-earning games with **official game descriptions**, gamepass counts and like counts;
  - a September 2026 market scan;
  - YouTube-trending snapshots from about 15 countries;
  - Roblox's official **creator-docs** repository.

| Tag | Meaning |
|---|---|
| **[S]** | From a search-result summary of the linked page(s). Secondary and not opened. |
| **[G]** | Read directly from a GitHub-hosted third-party dataset or file. Third-party scrapes are directional, not audited. |
| **[D]** | Read directly from Roblox's official creator-docs on GitHub. Primary source. |
| **[L]** | From the studio's earlier report `research/06-story-driven-games-on-roblox.md`, which was itself mostly search-summary based. Its URLs are repeated here. |
| **[B]** | Background knowledge, **not verified in this session**. |
| **[I]** | My inference from the cited evidence. |
| **[U]** | Sources conflict, or the claim is uncertain. |

---

## 1. Executive summary

1. **The genre on Roblox has a clear lineage, and Last Ferry sits right inside it.**
   - *Scary Shawarma Kiosk: the ANOMALY* (SSK) set the template: a night-shift worker at a service window, a rules sheet, CCTV with night vision, a shutter button, anomaly customers, and a monster (the Inspector) that grows with every mistake. It reached **~1.3B visits** ([Roblox Wiki](https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror)) [S]).
   - In **January 2026** it averaged **80K-161K CCU** in a third-party top-earning index ([RTE100 exports](https://github.com/nickpio/top-earning-parser/tree/master/index_data/exports) [G]).
   - *Animal Hospital (Anomaly)* then scaled the same idea to **1-4 player co-op**: a check-in window with shutters, a photo, CCTV and a sanity meter. It peaked at **1.2M CCU** and won **four 2026 Roblox Innovation Awards**, including Best New Game and Best Innovation in Creative Direction ([Variety](https://variety.com/2026/gaming/news/animal-hospital-roblox-innovation-awards-20th-anniversary-1236860184/), [GosuGamers](https://www.gosugamers.net/entertainment/news/78773-roblox-animal-hospital-hits-1-2-million-ccu-with-major-update-featuring-new-character-and-items) [S]).
   - Road-Side Sushi's own description names its lineage: **SSK, Road-Side Shawarma and Terminal 13** ([official description in Jan 2026 snapshot](https://github.com/nickpio/top-earning-parser/blob/master/runs/2026-01-06/raw/2026-01-06_top-earning_top1500_enriched.json) [G]).
2. **The "Roblox vibe" is not the same as "blocky".** The breakout hits used three different character looks:
   - SSK: semi-realistic, custom humans. The devs wanted real faces, but "Roblox did not allow the insertion of real faces" (official description [G]). Its January 2026 update made them "a little more realistic and a little less mannequin" ([Deltia's](https://deltiasgaming.com/roblox-scary-shawarma-kiosk-the-anomaly-global-update-guide/) [S]).
   - Animal Hospital: cartoon anthropomorphic animals ([BriefLedger](https://briefledger.co.uk/what-is-animal-hospital-on-roblox-my-12-year-old-explains-the-summers-biggest-craze/) [S]).
   - *Thats not my Robloxian*: classic Robloxians at a window, with about 95% likes ([Nov 2024 scrape](https://github.com/jansencruz23/roblox-webscraper-csharp/blob/main/RobloxWebScraper/data/roblox_games_list.csv) [G]).

   What they share:
   - **Characterful faces**, and characters players can name.
   - **Players who are physically present and social.**
   - **High-contrast night lighting** with warm practical lights.
   - **Chunky, diegetic UI**: rules taped to the counter, a big red shutter button.
   - A **lobby**.
   - **Voice and music**.
   - **Clippable moments.**

   Last Ferry currently has none of these: faceless box-and-ball passengers, no player characters (`CharacterAutoLoads = false`), a muted palette, generic panels, and no audio (repo files `games/last-ferry/GAME_DESIGN.md` and `games/last-ferry/AGENTS.md`).
3. **Roblox's own design guide backs showing players' avatars.**
   - "Users spend a lot of time and money on their avatars and typically want them to be seen by their friends... if you're going to change that for your game, make sure you have a good reason."
   - "Single-player games often find it harder to build and retain an audience."
   - Sources: [Design for Roblox](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/design-for-roblox.md) [D]. The docs also note most games use the player's own avatar, sometimes with "limited modifications... such as helmets, wings, or accessories that match the genre" ([Customize appearance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/characters/appearance.md) [D]).
4. **Visual upgrades drive numbers in this genre.**
   - Animal Hospital went from **736,948 CCU to 1.2M+** within days of an update centred on "visuals, characters, and quality-of-life". That update included a full rework of Dr. Harlow's model with "more expressive eyes" ([BlueStacks](https://www.bluestacks.com/blog/updates/roblox/rl-animal-hospital-july-update-en.html), [Fandom: Dr. Harlow](https://animal-hospital.fandom.com/wiki/Dr._Harlow) [S]; [investor memo](https://github.com/hczhu/stock-research/blob/main/memos/2026-07-23-roblox-ai-feed-creator-tools-games-safety.md) [G]).
   - SSK's biggest content update also upgraded its characters ([Sportskeeda](https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-global-update-patch-notes) [S]).
5. **Creators made these games, and faces and questions sold the clicks.** YouTube-trending snapshots show:
   - SSK: ItsFunneh (US, Dec 2025), Jazzghost (BR, **1.14M views**, "Do you serve him?"), Googly, Chuy Mine and others.
   - Animal Hospital: Foltyn (**2.7M views**), ItsFunneh, Tyler & Snowi, Lana's Life (lore).
   - Source: [tube-virality](https://github.com/gpsyrou/tube-virality) [G].
6. **Ranked recommendations (detail in §14):**
   1. Rebuild passengers as **Roblox-rig characters with faces**, made from HumanoidDescription with curated outfits. The drowned become **stylized variants** of the same people.
   2. Put the **players' own avatars in the booth**, with a clerk's cap and raincoat on top.
   3. Add a **harbor lobby** with Story and Endless doors and a 1-4 player gangway.
   4. Make the UI **diegetic and bold**: stamps, a rules card taped up, and bubble-chat speech.
   5. Push the art direction to **high-contrast stylized night** with saturated accents.
   6. Add a **second lens** and an **embodied failure monster**.
   7. Add **voice, music and sound**.
   8. Package for **clips and thumbnails**.
   9. Adopt the genre's **light, social monetization and monthly or seasonal live ops**.

---

## 2. The anomaly-checker lineage on Roblox (timeline)

| When | Game (creator) | Format | Scale (best available) | Presentation in one line |
|---|---|---|---|---|
| Feb 2024 (PC) | *That's Not My Neighbor* (Nacho Sama), not Roblox | Doorman checks residents for doppelgangers | Viral indie ([KYM](https://knowyourmeme.com/memes/subcultures/thats-not-my-neighbor-see-my-name-on-the-list-right) [S]) | 2D desk, ID papers |
| Mar 19, 2024 | *Thats not my Robloxian* (Scary Developers) | TNMN on Roblox: "Clone Analysis Team", 2012 | 97.7M visits ([Rolimons](https://www.rolimons.com/game/16794833014) [S]); ~95% likes (Nov 2024) [G] | **Robloxians** at a window, with ID, entry request and phone |
| May-Sep 2024 | *Midnight Burger / Midnight Station* (Elevated Horror), *Midnight Motel* (the m devs), *Midnight Movies* | Night-shift job horror, 1st wave | 27.5M / 49.6M / 24.4M / 2.8M visits by Nov 2024 ([scrape](https://github.com/jansencruz23/roblox-webscraper-csharp/blob/main/RobloxWebScraper/data/roblox_games_list.csv) [G]) | Title pattern "Midnight ___ [HORROR]" |
| Aug 25, 2025 (created); public ~Oct 28, 2025 | **Scary Shawarma Kiosk: the ANOMALY** (kharbor_ykt) | Kiosk worker serves or rejects anomalies | ~1.3B visits; Jan 2026 avg CCU 80-161K [G] | First-person kiosk, CCTV and night vision, rules taped up, Inspector |
| Oct 1, 2025 | *Road-Side Shawarma [HORROR]* (nv1sh works) | Same job, rules and nights | 184M visits ([Rolimons](https://www.rolimons.com/game/97267505570231) [S]) | Order board, crouch-and-hide events |
| Oct 25, 2025 | **Terminal 13: Not Human** (Dread Forge) | *Papers, Please*-like passport officer | ~36K peak [S/U]; 106.5M visits ([Rolimons](https://www.rolimons.com/game/126293024094985) [S]) | Passport screen, questions, X-ray, monster at shift end |
| Dec 23, 2025 | *Shawarma Truck: ANOMALIES* (Absolute Cinema Games) | Drive-and-serve anomaly variant | 23.2M visits ([Rolimons](https://www.rolimons.com/game/109366027244026) [S]) | Driving at night with a flashlight |
| ~2025-2026 | *Night 67* | Burger kiosk in the woods, 12AM-6AM | [gap] ([Roblox](https://www.roblox.com/games/127995006069066/Night-67) [S]) | Rules plus a stalker ("67") |
| May 4, 2026 | **Home Alone: Anomalies** (3 AM Productions & Freeground) | Doorstep checker at home | 188M visits; ~26-27K CCU (early Aug) [S] | Laptop CCTV, porch light, chores, sanity |
| May 10, 2026 | **Animal Hospital (Anomaly)** (Animal Anomaly / Roytt) | 1-4 player co-op hospital check-in | **1.2M CCU peak**, 1.7B+ plays [S] | Cartoon animals, shutters, photo, CCTV, classes |
| May 28, 2026 | **Keep the Door Locked** (Hotel Room Services) | Hotel room door checker | ~52M visits, 10K+ CCU, 91% approval [S] | Peephole vs camera feeds |

A tracker-blog timeline says each hit raised the ceiling about tenfold:

- Anomaly Watch peaked at about 4K CCU.
- Terminal 13 peaked at about 36K.
- The July 2026 tier ran from 14K to 286K.
- The genre went "from a $4 corridor in a Japanese subway to billion-play Roblox job sims and a movie."

Source: [spottheanomaly.wiki](https://spottheanomaly.wiki/roblox-anomaly-games-list) [S]. Its 286K figure for Animal Hospital is superseded by the 1.2M reported by [GosuGamers](https://www.gosugamers.net/entertainment/news/78773-roblox-animal-hospital-hits-1-2-million-ccu-with-major-update-featuring-new-character-and-items) [S].

ComicBook.com calls anomaly horror "Roblox's next big horror trend", citing Animal Hospital and Home Alone ([ComicBook.com](https://comicbook.com/gaming/news/robloxs-next-big-horror-trend-has-players-searching-for-anomalies-and-some-are-seriously-scary/) [S]).

---

## 3. Case study 1: *Scary Shawarma Kiosk: the ANOMALY* (the closest analog)

### 3.1 Identity, team and origin

- **Creator:** kharbor_ykt, Boris Kharanutov, a Russian developer ([Roblox Wiki: kharbor_ykt](https://roblox.fandom.com/wiki/Player:Kharbor_ykt) [S]). He is from **Yakutsk**. His brother said Roblox invited him to its California headquarters ([EXO-YKT](https://exo-ykt.ru/articles/zhitel-yakutska-sozdal-v-roblox-igru-i-v-nee-sygrali-uzhe-milliard-raz), [SakhaTime](https://sakhatime.ru/society/117174/) [S]). He says he won't move: "I love Yakutsk" ([EXO-YKT interview](https://exo-ykt.ru/articles/boris-haranutov) [S]).
- **Earlier games:** SSK is his fourth game to gain traction and the first to blow up:
  - Two "SCP Rooms" games.
  - *Short CREEPY stories*, a horror anthology. Its visit count is reported as **320M** in total by a regional outlet ([EXO-YKT](https://exo-ykt.ru/articles/zhitel-yakutska-sozdal-v-roblox-igru-i-v-nee-sygrali-uzhe-milliard-raz) [S]) and **250.9M** by Rolimons ([Rolimons](https://www.rolimons.com/game/8404684575) [S]).
  - A 2024 scrape shows he ran the anthology as a **17+** place and also published an **"All Ages [no gore and blood]"** version on Oct 24, 2024 ([scrape](https://github.com/jansencruz23/roblox-webscraper-csharp/blob/main/RobloxWebScraper/data/roblox_games_list.csv) [G]). This is a maturity-rating strategy worth noting.
- **Not a pure solo project.** The official description (Jan 2026) credits:
  - Project manager: TRAPYXCHAT31
  - **Narrator voice:** Bigzell
  - **Icons:** Starzs
  - **Composer:** Shark_Bight
  - **Writer:** nameisname111111
  - Gamedev helper: Gren
  - Plus four moderators and six testers.

  Source: [official description](https://github.com/nickpio/top-earning-parser/blob/master/runs/2026-01-06/raw/2026-01-06_top-earning_top1500_enriched.json) [G].
- **Dates.**
  - The universe was created **Aug 25, 2025**. That is 134 days before the Jan 6, 2026 snapshot [G], and matches [Roblox Wiki](https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror)) [S]. The fan wiki gives Aug 24 ([Fandom](https://scary-shawarma-roblox.fandom.com/wiki/Scary_Shawarma_Kiosk_Wiki) [S]).
  - The developer's hometown press gives the **launch as Oct 28, 2025**, with **a billion sessions within about five months** ([Yakutsk Vecherniy](https://vecherniy.com/news/istorija_uspekha_razrabotchika_iz_jakutska/2026-04-28-2730) [S]).
  - The description warns: "Before accusing us of copying, take a look at the creation date — work on this game began back in August!" [G]. This implies copy accusations after *Road-Side Shawarma* (created Oct 1, 2025) went public first [I].
- **His own explanation of the appeal.** "Foreigners love the sad Russian vibe." He picked copyright-free music from YouTube that sounds "frightening and anxious enough" ([59.ru / Sibdepo syndication](https://59.ru/text/world/2026/04/19/76373185/) [S]).
  - The game was shown at a developer conference in San Francisco.
  - **PlayStation interviewed him about adding console support** (same source [S]).
  - Console controls exist for PS4, PS5 and Xbox ([YouTube](https://www.youtube.com/watch?v=YtgVoHLyb5g) [S]).

### 3.2 Scale and CCU history

| Date | Visits | CCU (index "avg_ccu") | Index rank | Source |
|---|---|---|---|---|
| 2026-01-06 | 405,455,682 | 89,875 | 29 | [RTE100](https://github.com/nickpio/top-earning-parser/tree/master/index_data/exports) [G] |
| 2026-01-08 | 428,172,540 | 145,118 | **6** (top-10 table) | [weekly report](https://github.com/nickpio/top-earning-parser/blob/master/index_data/exports/Weekly%20Reports/rte100_report_2026-01-08.md) [G] |
| 2026-01-09 | 440,379,087 | **161,306** (highest in the series) | 9 | [G] |
| 2026-01-19 | 571,646,154 | 128,886 | 65 | [G] |
| 2026-01-26 | 639,694,169 | 106,964 | 98 | [G] |
| ~Mar 2026 | ~1B sessions ("within five months" of launch) | — | — | [Vecherniy](https://vecherniy.com/news/istorija_uspekha_razrabotchika_iz_jakutska/2026-04-28-2730) [S] |
| ~Sep 2026 | 1,296,043,629 | ~12.6K live at one snapshot | — | [Roblox Wiki](https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror)) [S]; [ServicesPV](https://servicespv.com/en/blox/stats/scary-shawarma-kiosk-the-anomaly-horror-by-kharbor-ykt-roblox) [S] |

- **Peak CCU is disputed [U].** ServicesPV lists a "record" of **35.7K on May 2, 2026** [S]. The index's daily figures of 80-161K in January 2026 show that record is only that tracker's own window. The true all-time peak is **at least ~161K**, and likely higher (January was the holiday and YouTube surge) [I].
- **Growth rate.** Visits grew **about 11.7M per day** from Jan 6 to Jan 26, 2026 (405M to 640M) [G, arithmetic].
- **Engagement (Jan 6, 2026 snapshot) [G]:**
  - 712,102 favorites.
  - 124,643 likes vs 13,742 dislikes, about **90.1% positive**.
  - Only **one gamepass**, average price **299 Robux**. That is the Friend Pass.

### 3.3 Camera, controls and the player's body

- **First person**, with free movement inside the kiosk. "Standard Roblox controls: WASD to move, mouse to look around, and E or F to interact" ([Droid Gamers](https://www.droidgamers.com/guides/how-to-play-scary-shwarma-kiosk-the-anomaly/), [Finding Dulcinea](https://findingdulcinea.com/scary-shawarma-kiosk-wiki/) [S]).
- **A CCTV monitor with two feeds** (back door and front table) and a **night-vision toggle**. Some anomalies are visible only on camera or only in night vision ([Fandom](https://scary-shawarma-roblox.fandom.com/wiki/Scary_Shawarma_Kiosk_Wiki), [FFBooyah CCTV guide](https://ffbooyah.com/2026/01/08/cctv-camera-guide-for-scary-shawarma-kiosk-how-to-spot-anomalies-early-and-survive-every-night-shift/) [S]).
- **Physical interactables around the player:**
  - A **red button** that closes the shutter.
  - A **phone** on the player's left, used to order supplies and upgrades. The shop is reached by calling 555-145.
  - A **radio**, which can be turned off after Jan 2026.
  - The **rules sheet** on the wall or counter.
  - Sources: [Droid Gamers](https://www.droidgamers.com/guides/how-to-play-scary-shwarma-kiosk-the-anomaly/), [Fandom: Phone](https://scary-shawarma-roblox.fandom.com/wiki/Phone), [TechWiser Shop Update](https://techwiser.com/scary-shawarma-kiosk-shop-update-release-countdown/) [S].
- **Hands-on cooking.** Put sauce on the lavash, cut meat, add vegetables, roll and serve (same Droid Gamers guide [S]).
- **Player avatars.** Players most likely appear as their own Roblox avatars to co-op partners [I].
  - Co-op is "one observes, one serves" ([BloxInformer](https://bloxinformer.com/wikis/scary-shawarma-kiosk-the-anomaly/) [S]).
  - The Weather Update warns players "not to confuse these special anomalies with real players, as some of them are designed to blend in" ([TechWiser](https://techwiser.com/scary-shawarma-kiosk-weather-update-release-countdown/) [S]).
  - I could not verify this with a screenshot.
- **A Motion Sickness mode** was added in the Jan 2026 update. This suggests camera sway or bob by default ([Deltia's](https://deltiasgaming.com/roblox-scary-shawarma-kiosk-the-anomaly-global-update-guide/) [S], [I]).

### 3.4 What customers look like, and how anomalies are shown

- **Customers are custom humanoid characters modeled on real people**, not stock blocky avatars:
  - The description invites fans: "WANT TO ADD YOUR CHARACTER? MESSAGE US ON DISCORD! (Yes — you can become part of the game…) Unfortunately, Roblox did not allow the insertion of real faces🥲" [G].
  - The **Global Update (Jan 24, 2026)** made characters "a little more realistic and a little less mannequin" ([Deltia's](https://deltiasgaming.com/roblox-scary-shawarma-kiosk-the-anomaly-global-update-guide/), [Sportskeeda](https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-global-update-patch-notes) [S]).
  - Conclusion: semi-realistic, human-proportioned customers with faces [I].
- **Anomaly taxonomy.** 6 customer anomalies, 8 CCTV-only, 5 entities, 4 environmental, 3 screamers, and 2 special ([fan data repo](https://github.com/cdg-hue/shawarma-kiosk-share) [G]).
- **Handling categories.** A fan wiki groups them as Dangerous (reject), Safe (serve), Special (follow unique rules) and Environmental. "Five errors causes the inspector to 'fix you'" ([fan wiki repo](https://github.com/bingkahu/scary-shawarma-wiki) [G]).
- **Tells span every channel:**
  - **Appearance:**
    - White Eyes Lady: glassy white eyes, decaying skin.
    - Holes on the back, seen via CCTV.
    - Texture errors and black spots.
    - The Skinwalker's pale, cracked skin.
    - Sources: [TechWiser](https://techwiser.com/scary-shawarma-kiosk-anomalies-guide/), [Droid Gamers](https://www.droidgamers.com/guides/scary-shawarma-kiosk-the-anomaly-all-anomalies-and-how-to-spot-them/), [Sportskeeda](https://www.sportskeeda.com/roblox-news/all-scary-shawarma-kiosk-the-anomaly-anomalies) [S].
  - **Movement:**
    - The Mannequin constantly raises and drops its hands.
    - The Twins jerk their heads unnaturally.
    - Sources: [Sportskeeda: Mannequin](https://www.sportskeeda.com/roblox-news/how-identify-mannequin-scary-shawarma-kiosk-the-anomaly), [GataGames](https://gatagames.com/2025/12/19/scary-shawarma-kiosk-the-anomaly-all-anomalies-and-how-to-spot-them/) [S].
  - **Speech:**
    - The Mannequin orders "shawarma one", "coffee yes".
    - The Gibberish Speaker talks nonsense.
    - A Santa greets you with "Merry Evening".
    - The **Opposite-Gender Voice** anomaly speaks with the wrong voice.
    - The **Hacker** "speaks to you directly using your username" and breaks the fourth wall. This is a direct precedent for Last Ferry's "they know your name" rule.
    - Sources: [Gamezebo](https://www.gamezebo.com/walkthroughs/scary-shawarma-kiosk-anomalies/), [Droid Gamers tips](https://www.droidgamers.com/guides/scary-shawarma-kiosk-the-anomaly-hints-and-tips/), [Sportskeeda](https://www.sportskeeda.com/roblox-news/all-scary-shawarma-kiosk-the-anomaly-anomalies) [S].
  - **Camera-only:**
    - CCTV Passenger: a goblin-like rider on a customer's back.
    - CCTV Double.
    - Nightvision Missing: the customer vanishes in night vision.
    - Night-Vision Dancer.
    - Sources: [fan wiki repo](https://github.com/bingkahu/scary-shawarma-wiki) [G], [Roblox Wiki](https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror)) [S].
  - **Quick-time threats:** the Clown charges while you spam the red button, and a warning tells you to close the shutters ([Sportskeeda: Clown](https://www.sportskeeda.com/roblox-news/how-deal-clown-scary-shawarma-kiosk-the-anomaly), [Deltia's](https://deltiasgaming.com/roblox-scary-shawarma-kiosk-the-anomaly-clown-guide/) [S]).
- **Failure is embodied as a monster.** **The Inspector** slowly rises out of the floor as you make mistakes. He has a red-brown, fungus-like head with no eyes or mouth, and a long black coat ([Fandom: The Inspector](https://scary-shawarma-roblox.fandom.com/wiki/The_Inspector), [Droid Gamers](https://www.droidgamers.com/guides/scary-shawarma-kiosk-the-anomaly-inspector-guide/) [S]).
  - At about **2 AM a driverless black car arrives**, the **screen edges turn red**, and you must leave by the back door without looking back.
  - Break that rule and you wake on a conveyor heading for a shredder: the "Erased" ending ([Sportskeeda: Inspector](https://www.sportskeeda.com/roblox-news/how-survive-inspector-scary-shawarma-kiosk-the-anomaly), [Sportskeeda: endings](https://www.sportskeeda.com/roblox-news/all-endings-scary-shawarma-kiosk-the-anomaly) [S]).

### 3.5 Rules, voice and UI

- **The rules are a physical object.** "You'll find them taped to the counter" (official description [G]). The radio tells new players to "read the rules on the wall". Example rules ([Sportskeeda: rules](https://www.sportskeeda.com/roblox-news/all-rules-scary-shawarma-kiosk-the-anomaly), [Deltia's](https://deltiasgaming.com/roblox-all-rules-in-scary-shawarma-kiosk-the-anomaly/) [S]):
  - "If a smiling customer walks in, give them a soda."
  - "If a faceless man comes to order — serve him, but never look directly at his face."
- **Voice.** A **credited narrator voice actor** [G]. A seasonal **Narrator** entity narrates your actions with subtitles (Dec 20, 2025 - Jan 8, 2026) ([Sportskeeda](https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-the-narrator-update-patch-notes) [S]).
- **Verified UI elements:**
  - The red shutter button [S].
  - Warning prompts ("close the shutters") [S].
  - A red screen-edge vignette during the Inspection [S].
  - A Shop icon on the left of the screen, with a Codes tab inside the shop ([TechWiser codes](https://techwiser.com/roblox-scary-shawarma-kiosk-the-anomaly-codes/), [Destructoid](https://www.destructoid.com/scary-shawarma-kiosk-the-anomaly-codes/) [S]).
  - Settings toggles for Motion Sickness and Turn off Radio [S].
- **Gap.** I could not verify fonts or the exact colors of the UI. See §15 for how to capture them.

### 3.6 Lighting, palette and audio

- **Setting.** A roadside kiosk after dark with basic equipment and a service window, in a town that gets **snow and a winter look** in season ([Sportskeeda: Christmas](https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-christmas-night-shift-guide) [S]).
- **Weather.** The Weather Update added weather-dependent anomalies. One example is a **customer in a yellow raincoat who "can only come out when it rains"**, which leads to an **Ocean ending surrounded by sharks** (badge "Accepted by the Deep") ([TechWiser](https://techwiser.com/scary-shawarma-kiosk-weather-update-release-countdown/), [scaryshawarmakiosk.org badges](https://scaryshawarmakiosk.org/badges/) [S]). This is a close thematic cousin of Last Ferry's dripping drowned.
- **Audio.** A credited composer [G], a radio, and "sad Russian vibe" music chosen for anxiety ([59.ru](https://59.ru/text/world/2026/04/19/76373185/) [S]).
- **Gap.** I had no screenshot access, so the exact palette is [B/U]. Community descriptions stress a lonely lit kiosk against a dark street [S].

### 3.7 Structure, endings, modes and co-op

- **Shift.** The night shift runs **11 PM-7 AM**. Story mode needs **16 clients** to reach an ending ([TechWiser: modes](https://techwiser.com/scary-shawarma-kiosk-all-game-modes/) [S]).
- **Endings.** "10 endings" (June 2026) ([Sportskeeda endings](https://www.sportskeeda.com/roblox-news/all-endings-scary-shawarma-kiosk-the-anomaly), [scary-shawarma-kiosk.com](https://scary-shawarma-kiosk.com/blog/all-endings-complete-guide) [S]). They include:
  - Perfect Shift.
  - Erased.
  - Prison: call 911 five times and hang up.
  - Ocean.
  - Badge-signalled routes: Heartless, CATACLYSM, HAPPY VALLEY, **Dry Drowning**, One of US ([timeline](https://scary-shawarma-kiosk.com/blog/february-may-update-timeline) [S]).
- **Lobby.** Walk left for **Story** or right for **Endless** ([TechWiser](https://techwiser.com/scary-shawarma-kiosk-all-game-modes/) [S]).
- **Co-op.**
  - **Up to 4 players** share the kiosk ([BloxInformer](https://bloxinformer.com/wikis/scary-shawarma-kiosk-the-anomaly/) [S]; "4 per server" [fan repo](https://github.com/cdg-hue/shawarma-kiosk-share) [G]).
  - Creators made co-op content: "PLAYING SHAWARMA KIOSK WITH GIRLFRIEND" (PH trending) [G], and "Can 4 YouTubers Survive ROBLOX Scary Shawarma Kiosk?" ([YouTube](https://www.youtube.com/watch?v=KASLOG3RRAk) [S]).

### 3.8 Monetization

- **Friend Pass: 299 Robux**, sold to "get your friends into the game". It was the only gamepass on Jan 6, 2026 ([Beebom](https://beebom.com/scary-shawarma-kiosk-the-anomaly-codes/), [Rolimons pass](https://www.rolimons.com/gamepass/1608103276) [S]; snapshot [G]). Whether co-op *requires* it is [U].
- **VIP Server pass: 699 Robux**, added Jan 24, 2026 ([Sportskeeda](https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-global-update-patch-notes), [Rolimons](https://www.rolimons.com/gamepass/1679499290) [S]).
- **Corruption Shop.** One-time consumable powers: reveal anomalies, clear mistakes, force events. They cost **1,000-5,000 coins or 19-29 Robux**. Coins come from orders and daily rewards ([Sportskeeda](https://www.sportskeeda.com/roblox-news/all-corruptions-scary-shawarma-kiosk-the-anomaly), [TechWiser](https://techwiser.com/scary-shawarma-kiosk-the-anomaly-corruptions/), [FAQ](https://scaryshawarmakiosk.com/scary-shawarma-kiosk-faq) [S]).
- **Kiosk upgrade shop** (Mar 2026), reached through the in-game phone [S].

### 3.9 Update cadence

| Date | Update | Source |
|---|---|---|
| Dec 20, 2025 - Jan 8, 2026 | Winter "Narrator" entity event | [Sportskeeda](https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-the-narrator-update-patch-notes) [S] |
| Jan 24, 2026 | **Global Update**: 10-11 anomalies, 8 new clients, more realistic characters, VIP server, Motion Sickness mode, radio toggle | [Deltia's](https://deltiasgaming.com/roblox-scary-shawarma-kiosk-the-anomaly-global-update-guide/), [Sportskeeda](https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-global-update-patch-notes) [S] |
| Feb 27 - Mar 7, 2026 | **Weather Update**: weather-specific anomalies, Ocean ending | [TechWiser](https://techwiser.com/scary-shawarma-kiosk-weather-update-release-countdown/) [S] |
| Mar 15-22, 2026 | **Shop Update**: new clients and anomalies, kiosk upgrades. Source says "2025", clearly 2026. | [TechWiser](https://techwiser.com/scary-shawarma-kiosk-shop-update-release-countdown/) [S] |
| May 2026 | New badges (e.g., "Dry Drowning", May 1) | [scaryshawarmakiosk.org](https://scaryshawarmakiosk.org/badges/), [Rolimons badge](https://www.rolimons.com/gamebadge/3135139714184023) [S] |
| Jun 5-15, 2026 | **Backrooms event**: a yellow-wallpaper maze reached through a special customer | [Sportskeeda](https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-backrooms-event-guide), [Rosenberry Rooms](https://www.rosenberryrooms.com/all-scary-shawarma-kiosk-special-events/) [S] |

Roughly **one sizeable update or event every 3-6 weeks**. This matches Roblox's guidance of an update "every 2 weeks to a month" ([L], creator-docs content-updates).

### 3.10 Reception

**Praise and virality.**

- Big creators covered it:
  - **KreekCraft** (Dec 18, 2025) ([YouTube](https://www.youtube.com/watch?v=y5ql2jdCXGk) [S]).
  - **Caylus & Foltyn** (Jan 2026) ([YouTube](https://www.youtube.com/watch?v=Yn7UA3M-148) [S]).
- YouTube trending lists [G] ([tube-virality](https://github.com/gpsyrou/tube-virality)):
  - **ItsFunneh**, "I Worked at a CURSED Shawarma Kiosk in Roblox..." (US, Dec 20, 2025, 264K views at snapshot).
  - **Jazzghost**, "ESSE HOMEM ENTRA NA SUA LANCHONETE. VOCÊ ATENDE ELE?" ("This man walks into your diner. Do you serve him?") (BR, **1.14M views**).
  - **Googly**, "I JOINED the ANOMALIES..." (KE, 589K).
  - Chuy Mine (MX), FearOfEL (PH), Werka Aferka (PL).
  - The titles lean on **3 AM**, **cursed** and **"do you serve him?"** hooks.
- TikTok users call it "10/10 horror game!" ([TikTok](https://www.tiktok.com/@doodlefae/video/7580195998107012382) [S]).
- About 90% likes [G].

**Complaints and risks.**

- **Difficulty and opacity.** Rules can feel harsh under pressure, and the game "rarely confirms whether a customer is an anomaly outright". The Inspector penalizes mistakes, including turning away a *safe* customer (search summary of iOS clone listings and guides [S/U]; [fan wiki repo](https://github.com/bingkahu/scary-shawarma-wiki) [G]).
- **Copying accusations** (see the description [G]).
- **Fast cloning:**
  - *Road-Side Shawarma* ([Rolimons](https://www.rolimons.com/game/97267505570231) [S]).
  - *Shawarma Truck: ANOMALIES* ([Rolimons](https://www.rolimons.com/game/109366027244026) [S]).
  - iOS App Store copies ([App Store](https://apps.apple.com/us/app/-/id6759698340), [App Store](https://apps.apple.com/app/id6757749418) [S]).
- **Decay.** Roughly 100K+ CCU in January 2026 fell to about 12.6K live at a later snapshot [G/S]. That is normal for a trend hit [I].

### 3.11 Why it worked (analysis) and what Last Ferry should take

1. **A mundane, culturally specific place with a flavor people can name.** The Russian shawarma kiosk and the "sad Russian vibe" music give it a strong identity. For Last Ferry, a 1999 ferry disaster on a foggy harbor is equally specific; lean into it (§14 R5, R7) [I].
2. **Tells across many channels:** look, movement, speech, voice, camera-only, and your username. They make great "catch it with me" clips. Last Ferry has visual and paperwork tells, but **its passengers have no faces or voices to carry the others** [I].
3. **Failure is an escalating monster** (the Inspector) rather than a counter. Last Ferry's lanterns are only a counter [I].
4. **The rules are a physical prop** taped to the counter, and a radio voice onboards you. Last Ferry already has Pike on the radio. The rules card should become an in-world prop [I].
5. **Co-op with free movement inside a small space**, plus seasonal and weather events and many endings with badges [S].
6. **Credited specialists** (VO, composer, icon artist) on a small team: the polish points that matter [G].

---

## 4. Case study 2: *Animal Hospital (Anomaly)* (the biggest hit, and the closest co-op analog)

### 4.1 Facts

- **Release and team.** Released **May 10, 2026** by the **Animal Anomaly** group, led by verified developer **Roytt** ([Fandom](https://animal-hospital.fandom.com/wiki/Animal_Hospital_(Game)), [Roblox Wiki](https://roblox.fandom.com/wiki/Animal_Anomaly/Animal_Hospital) [S]). *Break In 2*'s official description credits "Lobby Programming: @Roytt" [G], probably the same developer [I]. If so, he learned the story-game lobby formula first-hand.
- **Scale:**
  - **736,948 CCU** around July 5-7, 2026, then **1.2M+** after the July 10-11 "Harlow's Favorite Update". That is about +63% in days ([GosuGamers](https://www.gosugamers.net/entertainment/news/78773-roblox-animal-hospital-hits-1-2-million-ccu-with-major-update-featuring-new-character-and-items) [S]; [investor memo](https://github.com/hczhu/stock-research/blob/main/memos/2026-07-23-roblox-ai-feed-creator-tools-games-safety.md) [G]).
  - 1.15B visits and 1.68M favorites by July ([animalhospital.blog](https://animalhospital.blog/release-date/) [S]). **1.7B+ plays** later ([BriefLedger](https://briefledger.co.uk/what-is-animal-hospital-on-roblox-my-12-year-old-explains-the-summers-biggest-craze/) [S]).
  - About **132,214 CCU on Sep 13, 2026** ([trend-radar report](https://github.com/Fuheshka/game-trend-radar/blob/main/data/reports/market_report_2026-09-13.md) [G]).
- **Awards.** Won 4 of about 20 categories at the **2026 Roblox Innovation Awards**: Best New Game, **Best Innovation in Creative Direction**, People's Choice, and the Builderman Award. There were 319M votes, and the ceremony was held at RDC in San Jose ([Variety](https://variety.com/2026/gaming/news/animal-hospital-roblox-innovation-awards-20th-anniversary-1236860184/), [GosuGamers](https://www.gosugamers.net/entertainment/news/79176-full-list-of-winners-at-the-roblox-innovation-awards-2026), [Roblox newsroom](https://about.roblox.com/newsroom/2026/09/2026-roblox-innovation-awards) [S]).
- **Declared inspirations.** It "combines concepts from... Scary Shawarma Kiosk and 99 Nights in the Forest, as well as Kinetic Games' Phasmophobia" ([GosuGamers](https://www.gosugamers.net/entertainment/news/78741-animal-hospital-becomes-roblox-s-latest-horror-sensation-here-s-everything-you-need-to-know) [S]).

### 4.2 Presentation

- **Characters.**
  - **Cartoon-style anthropomorphic animal** patients and staff ([BriefLedger](https://briefledger.co.uk/what-is-animal-hospital-on-roblox-my-12-year-old-explains-the-summers-biggest-craze/) [S]).
  - A named host, **Dr. Harlow**. Harlow is a light-orange **muntjac deer** in blue scrubs and a white coat with a face mask (hiding the fangs) and a head mirror. Harlow **grades your shift** and stocks supplies between runs ([Fandom: Dr. Harlow](https://animal-hospital.fandom.com/wiki/Dr._Harlow), [AllThings.How characters](https://allthings.how/every-animal-hospital-character-in-roblox-explained/) [S]).
  - Ambient NPCs such as "Lobby Cat", "Lobby Bunny" and "News Bunny" [S].
- **Players are class characters.** There are 10 **Classes**, and **skins** are "redesigns... of the Classes' character models". The classes "are mostly anthropomorphic animals" ([Fandom: Skins](https://animal-hospital.fandom.com/wiki/Skins), [Fandom: Classes](https://animal-hospital.fandom.com/wiki/Classes) [S]). So players appear as animal staff rather than their own avatars [I].
  - Fans then dress their *own* avatars as the characters: "Animal Hospital Avatars/Outfits" games and UGC bundles exist ([Roblox](https://www.roblox.com/games/108064260980984/Animal-Hospital-Avatars) [S]).
  - This is the "good reason" route the Roblox docs allow: character IP instead of avatar identity [I].
- **Camera.** First person by default. A **third-person option** can be switched on only in the **lobby outside the hospital**, and it "enables you to see your selected class" ([esports.gg](https://esports.gg/guides/roblox/third-person-camera-animal-hospital/) [S]).
- **Check-in routine: window, then photo, then CCTV, then shutters.**
  - Inspect eyes, mouth, ears, posture and twitching at the **reception window**.
  - **Take a photo and wait for it to develop.**
  - Check **CCTV**.
  - Open the **shutters** only if all three are clean.
  - Sources: [AllThings.How 3 checks](https://allthings.how/catch-every-anomaly-in-animal-hospital-roblox-with-3-checks/), [The Spike](https://www.thespike.gg/roblox/animal-hospital/all-anomalies) [S].
- **Treatment.**
  - A screen above the bed shows 1-3 required treatments.
  - A wrong treatment kills the patient and costs one of three lives ([Fandom: Treatment](https://animal-hospital.fandom.com/wiki/Treatment) [S]).
  - A **Sanity** meter replaces health; coffee restores it ([GosuGamers](https://www.gosugamers.net/entertainment/news/78741-animal-hospital-becomes-roblox-s-latest-horror-sensation-here-s-everything-you-need-to-know) [S]).
- **Progression by shift** ([AllThings.How](https://allthings.how/every-animal-hospital-character-in-roblox-explained/) [S]):
  - Shift 1: shutters and cameras.
  - Shift 2: Supplies Shop and emergency wing.
  - Shift 3: taser.
  - Shift 4: anomaly warning.

### 4.3 Monetization

- **Currency.** **Animal Coins** buy classes and skins. They can be earned or bought, and gifted ([Fandom: Animal Coins](https://animal-hospital.fandom.com/wiki/Animal_Coins) [S]).
- **Robux-only classes: Head Nurse and Secret Agent.**
  - Reported prices differ: **80 and 320 Robux** ([memo](https://github.com/hczhu/stock-research/blob/main/memos/2026-07-23-roblox-ai-feed-creator-tools-games-safety.md) [G]) vs "190 (also 240 or 80...)" ([Sportskeeda](https://www.sportskeeda.com/roblox-news/animal-hospital-classes-guide-prices-perks), [GosuGamers classes](https://www.gosugamers.net/entertainment/news/78750-all-classes-in-roblox-animal-hospital-explained-with-perks-and-best-class-tier-list) [S]) [U].
  - Secret Agent starts with a **gun** and a scanner ([Beebom](https://beebom.com/roblox-animal-hospital-classes-guide/) [S]).
- **Other purchases** are mostly cosmetic or convenience, "in the 50 to 500 Robux range" ([Fandom: Gamepasses](https://animal-hospital.fandom.com/wiki/Gamepasses) [S]).

### 4.4 Reception

**Praise.**

- A Reddit post: "Animal Hospital is the new #1 Roblox game!!... unique characters, fun lore... a massive win for the front page" ([memo quoting r/roblox](https://github.com/hczhu/stock-research/blob/main/memos/2026-07-04-roblox-news-roundup-age-check-fallout-adult-pivot.md) [G]).
- A compiled growth guide uses it as the example of an idea "a kid can picture before bed: 'a hospital run by animals'" ([roblox-growth-design](https://github.com/TabooHarmony/roblox-brain/blob/main/skills/design/roblox-growth-design/references/full.md) [G]).
- YouTube trending [G] ([tube-virality](https://github.com/gpsyrou/tube-virality)):
  - **Foltyn**, "ROBLOX ANIMAL HOSPITAL.." (2.7M views).
  - **ItsFunneh**.
  - **Tyler & Snowi**: "CAUGHT ON CAMERA", "The SECRET MASTERMIND behind...", and "I Played FAKE Animal Hospital Anomaly Games" (783K, about clones).
  - **Lana's Life**, "I FOUND NEW LORE".
  - Brazilian and Indonesian "secret"/"anomaly" videos.
  - **Lore, secrets and characters** drive the titles.

**Complaints.**

- **Pay-to-win.** The Robux Secret Agent's gun ("I Tested Animal Hospital PAY TO WIN!" [YouTube](https://www.youtube.com/watch?v=miVFlBIqu8g) [S]).
- **Repetition and downfall commentary** ("Is Animal Hospital Really THAT Bad?" [YouTube](https://www.youtube.com/watch?v=kuQ7Yz3gm54); "Animal Hospital Has 30 Days Left..." [YouTube](https://www.youtube.com/watch?v=SU21H8Zq4VM) [S]).
- **Community drama** ([AllThings.How](https://allthings.how/animal-hospital-roblox-drama-explained-the-controversy-around-the-viral-game/) [S]; details not retrieved).
- **Clones** (Tyler & Snowi video [G]).

### 4.5 Lessons for Last Ferry

- **Proof that 1-4 player co-op at a check-in window with shutters plus a "second lens" is the winning shape**, and Last Ferry already has that shape [I].
- **The step that doubled CCU was a visual and character upgrade, not new mechanics**:
  - "This patch focused on visuals, characters, and quality-of-life changes rather than a brand-new map or mode" ([BlueStacks](https://www.bluestacks.com/blog/updates/roblox/rl-animal-hospital-july-update-en.html) [S]).
  - "New lore, items, and class visual upgrades drove blockbuster engagement" ([memo](https://github.com/hczhu/stock-research/blob/main/memos/2026-07-23-roblox-ai-feed-creator-tools-games-safety.md) [G]).
- **A named, charismatic host who judges your shift** gives the fandom a face. Harlow is to Animal Hospital what Pike could be to Last Ferry [I].
- **Avoid its mistakes.** Don't sell a weapon that skips the checking; keep power earnable [S].

---

## 5. Case study 3: *Terminal 13: Not Human* (the Papers, Please-like on Roblox)

- **Creator and scale.**
  - By **Dread Forge**, a group owned by SlempHolder with about 860K members ([Roblox](https://www.roblox.com/communities/33501450/Dread-Forge) [S]).
  - Created **Oct 25, 2025**. It had 69.2M visits by Jan 6, 2026 [G] and **106.5M** later ([Rolimons](https://www.rolimons.com/game/126293024094985) [S]).
  - **Peak CCU is uncertain [U]**: about **36K** (36,389 on Nov 30, 2025) per [spottheanomaly.wiki](https://spottheanomaly.wiki/roblox-anomaly-games-list) [S], vs a "record" of 2.2K on ServicesPV ([ServicesPV](https://servicespv.com/en/roblox/stats/terminal-13-not-human-horror-by-dread-forge-roblox) [S]; a tracker-coverage artifact [I]).
  - It had 6,163 CCU on Jan 6, 2026, **88.7% likes**, and 4 gamepasses averaging 134 Robux [G].
- **Official description [G].** "You've been assigned to the night shift at Terminal 13. Your job is simple: scan passports, question travelers, and decide who gets through. Keep the terminal clean... **Headphones & max graphics recommended**... inspired by *Shift At Midnight*."
- **Presentation and loop:**
  - **Seven travelers per shift.** Each scans a **digital passport that appears on a screen to the right of the desk**.
  - You **ask questions** (origin, job, purpose, length of stay) and compare the answers with the passport. You also check the **photo match** and **physical oddities** (proportions, movement).
  - An **X-ray scanner** is added on shift 2.
  - Chores: mopping.
  - A shop terminal delivers items **through a chute**: a blunderbuss, a land mine, a music box, a scanner.
  - If you let an impostor through, **a monster comes for you at the end of the shift**.
  - Chapter 2 moves to a **road checkpoint**.
  - It can be played **solo or with friends**.
  - Sources: [Pro Game Guides](https://progameguides.com/roblox/complete-terminal-13-not-human-walkthrough/), [PGG ch. 2](https://progameguides.com/roblox/terminal-13-not-human-second-shift-walkthrough-chapter-2/), [Deltia's](https://deltiasgaming.com/roblox-how-to-play-terminal-13-not-human/), [Sportskeeda](https://www.sportskeeda.com/roblox-news/terminal-13-not-human-a-beginner-s-guide) [S].
  - There was a Christmas update ([Sportskeeda](https://www.sportskeeda.com/roblox-news/terminal-13-not-human-christmas-update-patch-notes) [S]).
- **Gap.** I could not verify the look of travelers (Roblox rigs vs custom models) or the UI styling.
- **Lessons:**
  - Document UI (a passport on a screen) plus **a question-and-answer dialogue** is the Roblox-native way to present paperwork checks. Last Ferry's ticket and manifest map onto it directly.
  - **Chapters that change location** keep it fresh.
  - An **end-of-shift monster payoff** is the scare beat [I].

---

## 6. That's-Not-My-Neighbor-style door checkers

### 6.1 *Thats not my Robloxian* (Scary Developers)

- **Scale:** created Mar 19, 2024, with 97.7M visits ([Rolimons](https://www.rolimons.com/game/16794833014) [S]). In Nov 2024: 58.0M+ visits, 85K+ likes vs 4,303 dislikes (**~95%**), genre "Puzzle", server size 50 ([scrape](https://github.com/jansencruz23/roblox-webscraper-csharp/blob/main/RobloxWebScraper/data/roblox_games_list.csv) [G]).
- **Premise.** Players "work out who is a human, and who is a clone from a lineup of **Robloxians** showing up at your window". The description reads: "Welcome to the Clone Analysis Team (C.A.T.)... It's 2012... Decide who gets access" ([Fandom](https://thats-not-my-robloxian.fandom.com/wiki/Thats_not_my_Robloxian) [S]).
- **Documents:** a daily visitors list, a resident ID (name, ID number, expiry date), an entry request letter, and a phone to call the apartment ([Deltia's](https://deltiasgaming.com/thats-not-my-robloxian-a-beginners-guide/), [PGG](https://progameguides.com/roblox/how-to-find-the-clones-in-thats-not-my-robloxian-roblox/) [S]).
- **Presentation lesson.** The Roblox version succeeded by **reskinning neighbors as classic Roblox avatars** and setting it in Roblox's own "2012" era. That is the clearest precedent for "passengers as Roblox avatars" [I]. There is also a sibling, *That's Not My Blocky Neighbor* ([Roblox](https://www.roblox.com/games/16906926480/Thats-Not-My-Blocky-Neighbor) [S]).

### 6.2 *Keep the Door Locked* (Hotel Room Services)

- **Scale:** launched **May 28, 2026**. About 49M visits and **10K+ CCU** within three months, then **51.9M visits and a 91% rating** on Sep 3 ([Robipedia](https://robipedia.com/game/keep-the-door-locked-anomaly-10232686472), [Creator Exchange](https://creatorexchange.io/roblox-game/10232686472/keep-the-door-locked) [S]). It runs events such as "[BLOODMOON]" ([Rolimons](https://www.rolimons.com/game/124338404742585) [S]).
- **Presentation:**
  - A single hotel room after midnight. You **cycle camera feeds** of the hallway, stairwell and elevator lobby, and you check the **peephole**.
  - 20 anomalies, e.g., a **translucent guest** visible only on camera, and **height distortion** (normal in the peephole, wrong on the monitor).
  - Sources: [KtDL wiki guide](https://keepthedoorlockedroblox.wiki/en/guides/keep-the-door-locked-roblox-guide/), [Beebom](https://beebom.com/all-keep-the-door-locked-anomalies/), [TechWiser](https://techwiser.com/keep-the-door-locked-all-anomalies/) [S].
- **Lesson.** Two views that disagree (the peephole vs the camera) is the core fun. Last Ferry could pair the window with the lamp, a camera, or the lighthouse beam [I].

### 6.3 *Home Alone: Anomalies* (3 AM Productions & Freeground)

- **Scale:** created **May 4, 2026**. It had 188M visits, with **~26-27K CCU** at peak in early Aug 2026, after it "exploded on TikTok in late July" ([Rolimons](https://www.rolimons.com/game/87468080405188) [S]).
- **Cadence.** **Weekly** updates, usually Wednesday at 1 PM ET. Update 10 (Sep 23, 2026) added "Girl Scout" and "Hacker" visitors ([AllThings.How](https://allthings.how/home-alone-anomalies-anomaly-update-schedule/) [S]).
- **Presentation:**
  - Midnight to 6 AM.
  - A **chore board** of four chores (earn $160).
  - Check **CCTV on a laptop**.
  - **Listen to visitors' voices** ("if the voice does not fit the face").
  - Open the door or **turn off the porch light**.
  - Letting anomalies in lowers **sanity**: monsters, hallucinations, destroyed furniture, graffiti.
  - 22 anomalies (Jul 2026).
  - Sources: [Pro Game Guides](https://progameguides.com/roblox/home-alone-walkthrough-anomalies-chores-more/), [Sportskeeda](https://www.sportskeeda.com/roblox-news/all-anomalies-home-alone) [S].
- **Lesson.** **Voiced visitors** and **visible sanity decay of the room itself** are cheap, clip-friendly escalation. Last Ferry could let the booth flood, fog up, or grow barnacles as mistakes pile up [I].

---

## 7. Night-shift job horror (the wider family)

- ***Road-Side Shawarma [HORROR]*** (nv1sh works).
  - Created Oct 1, 2025. 184M visits. A "solo project" with contributors credited for the soundtrack, UI design and **artwork & thumbnails** ([Rolimons](https://www.rolimons.com/game/97267505570231), [Roblox](https://www.roblox.com/games/97267505570231/Road-Side-Shawarma) [S]).
  - Mechanics: a serve button, a fridge for drinks, throwing drinks, **crouch to hide and close your eyes** during events, and an order board ([Sportskeeda](https://www.sportskeeda.com/roblox-news/road-side-shawarma-a-beginner-s-guide), [Deltia's](https://deltiasgaming.com/roblox-road-side-shawarma-a-beginners-guide/) [S]).
  - A Mexican creator video, "ABRIMOS UN RESTAURANTE A LAS 3:00AM..." ("We opened a restaurant at 3:00 AM..."), trended in Dec 2025 [G].
- ***Road-Side Sushi [HORROR]*** (Gundami). "Inspired by Road-Side Shawarma, Scary Shawarma Kiosk, Terminal 13"; "Best experienced with friends!"; "Headphones and max graphics are highly recommended". It had 8.3M visits, 85% likes and 10 gamepasses (Jan 2026) [G].
- ***Shawarma Truck: ANOMALIES*** (Absolute Cinema Games). Dec 23, 2025, 23.2M visits. Drive through "Oakridge" taking orders, with multiple endings and "dynamic events that change every night" ([Rolimons](https://www.rolimons.com/game/109366027244026) [S]).
- ***Night 67***. A burger kiosk in the woods, 12AM-6AM. "Breaking a rule or messing up an order means 67 will come for you." Solo or with friends ([Roblox](https://www.roblox.com/games/127995006069066/Night-67) [S]).
- ***Movie Massacre 📼 [HORROR]*** (Cryptid Horror, which also runs the *Short Horror Games* hub).
  - A VHS store night shift. "**This game can be played by 4 people**", a **secret ending**, and "a shop for fun items to **troll your friends**".
  - 7.25M visits in 57 days, 81.9% likes, and 10 gamepasses averaging 143 Robux (Jan 2026) [G].
- ***Scary Sushi*** (Evil Twin Games). Feb 20, 2024. 116.6M+ visits. Job-interview horror with a "[CHAPTER 2]" title tag ([L]: [Roblox Wiki](https://roblox.fandom.com/wiki/Evil_Twin_Games/Scary_Sushi), [Rolimons](https://www.rolimons.com/game/16454399300)).
- ***Short CREEPY stories*** (KHARBOR games). Created Dec 30, 2021, with 250.9M visits. Stories include "**Night Shift on Route 90**", "**Night Cleaner**" and "**Ominous Steamboat**" ([Rolimons](https://www.rolimons.com/game/8404684575), [Roblox](https://www.roblox.com/games/8404684575/Short-CREEPY-stories) [S]).
- **The 2024 first wave:** *Midnight Burger [HORROR]* and *Midnight Station [HORROR]* (Elevated Horror, 27.5M and 49.6M visits), *Midnight Motel [HORROR]* (24.4M) and *Midnight Movies [HORROR]* (2.8M). All had lobby-size servers of 25-44 by Nov 2024 ([scrape](https://github.com/jansencruz23/roblox-webscraper-csharp/blob/main/RobloxWebScraper/data/roblox_games_list.csv) [G]).

**Family traits (analysis):**

- A "[HORROR]" tag in the title.
- A **3 AM or midnight** hook.
- "Headphones & max graphics recommended".
- 4-player co-op.
- Secret endings.
- Troll or helper shops.
- Frequent cloning.

---

## 8. Exit 8 / I'm on Observation Duty-style anomaly games on Roblox (thin coverage)

- The genre overview credits **The Exit 8** as the origin ("a $4 corridor in a Japanese subway") and notes the film adaptation ([spottheanomaly.wiki](https://spottheanomaly.wiki/anomaly-games) [S]).
- On Roblox, ***Anomaly Watch*** drove a "July 2026 video wave" and peaked at about 4K CCU ([spottheanomaly.wiki: Anomaly Watch](https://spottheanomaly.wiki/anomaly-watch), [Anomaly Watch wiki](https://anomaly-watch-roblox.fandom.com/wiki/Anomalies) [S]). ***Anomaly Observation*** also exists ([Roblox](https://www.roblox.com/games/115500497807053/Anomaly-Observation) [S]).
- **Gap.** The search budget ran out before I could profile Platform 8 or Exit 8 clones on Roblox. The evidence I have suggests that on Roblox the pure "spot the difference in a corridor" format stayed **small (about 4K CCU)**, while **job-sim checkers with characters and co-op** reached 36K to 1.2M [S/I]. That supports keeping Last Ferry character-driven.

---

## 9. FNAF-style fixed-camera or office games on Roblox

| Game (creator) | Scale | Notes |
|---|---|---|
| *FNAF: Co-op* (Z0KTAR's Community Group) | 317M visits; 10.5K CCU; **94.3% likes**; **17 gamepasses** averaging 187 Robux (Jan 6, 2026) [G] | "Experience... Five Nights at Freddy's... now with a friend. Survive together through the... nights"; "Player controlled animatronics are coming soon" [G] |
| *FNAF: Eternal Nights* (Cob-Studios) | Avg CCU **16-26K** across Jan 2026; visits 106M to 136M in 14 days [G] | [gap: presentation] |
| *Five Nights: Hunted* (Double Bandit: Hunted) | 114M visits; 90% likes [G] | Objective-based escape with "blast doors" [G] |
| *Five Nights At Freddy's Doom* (@CaioOpaleiroBR) | 145.9M+ visits (Nov 2024) [G] | 13+ |
| *Animatronic Nights* (PlayBox!) | 13.5M visits; 11 gamepasses averaging 772 Robux [G] | Asymmetric: "Roleplay as your favorite Animatronic... while taking down remaining Night Guards!" [G] |
| *Five Nights TD* (Hyper TD) | 738M visits [G] | Tower defense spin-off (the IP transplanted into a Roblox-native genre) |

**Lesson.** On Roblox the successful FNAF-likes **add co-op or asymmetric play** to the fixed-office formula. They rely heavily on gamepasses, some with 11-17 passes [G]. A pure single-player fixed camera is rare among the hits [I].

---

## 10. *Weird Strict Dad* and *Midnight Horrors*

- ***Weird Strict Dad*** (BlueLoop Studios, "[BOOK 2]" edition).
  - Created Sep 16, 2023. 341M+ visits, 115K+ likes vs 21K+ dislikes (~84%), "All Ages", genre Adventure (Nov 2024 scrape) ([scrape](https://github.com/jansencruz23/roblox-webscraper-csharp/blob/main/RobloxWebScraper/data/roblox_games_list.csv) [G]).
  - The premise comes from the developer's real strict dad. It is inspired by *Residence Massacre* and *Jim's Computer* ([L]: [NamuWiki](https://en.namu.wiki/w/weird%20strict%20dad)).
  - Presentation [B]: a night-time bedroom and house, avoiding a patrolling "dad" character, with a comedic-creepy tone and chapter ("Book") releases.
- ***Midnight Horrors***. The only thing I verified is a low-quality listing: "random horror monsters chase you, survive to the end" ([blog listing](https://github.com/kaichen0621/kaiblog/blob/main/docs/roblox/roblox.md) [G, low quality]). It is a round-based monster-survival party game, not a checker [B/U]. **Gap.**

---

## 11. Ferry, boat, dock and harbor horror on Roblox

- **"Ominous Steamboat"** (a story inside KHARBOR's *Short CREEPY stories*, by the SSK developer).
  - A young sailor's first voyage: scrub the deck, make dinner, fetch coal marked "C", then take the wheel for the captain as things turn strange. A ship's log tells of sounds in the hold.
  - In one ending you row out to sea and are accused of eating the captain.
  - Sources: [Fandom](https://short-creepy-stories-roblox.fandom.com/wiki/Ominous_Steamboat), [Droid Gamers](https://www.droidgamers.com/guides/short-creepy-stories-ominous-steamboat-walkthrough/) [S].
- ***A DEADLY BOAT TRIP*** (Badass Experiences). 45M visits, 2.5K CCU, **93.5% likes** (Jan 2026). A sea-survival run: "SAIL INTO THE DEADLY SEA", trinkets, boat dashing, and a boss called "Sheldon" [G]. It is action, not checking.
- **SSK's sea content:**
  - The **yellow-raincoat customer** who "can only come out when it rains".
  - The **Ocean ending** with sharks.
  - The "Dry Drowning" badge.
  - Sources: [scaryshawarmakiosk.org](https://scaryshawarmakiosk.org/badges/), [Rolimons](https://www.rolimons.com/gamebadge/3135139714184023) [S].
- ***Pressure*** (deep-sea facility) is the big-budget aquatic horror reference ([L]).
- **Finding.** I found **no ferry or ticket-booth checker game on Roblox** before the search budget ran out. That is a probable whitespace, not a confirmed one [U].

---

## 12. Baselines: the "Roblox horror look" (brief)

Numbers are verified as tagged. Visual descriptions are mostly **[B]** (no screenshot access). Treat them as reminders to check in-game, not as evidence.

| Game (creator) | Scale (tagged) | Avatars and camera [B unless tagged] | Look, UI and audio [B unless tagged] | What players associate with it |
|---|---|---|---|---|
| **DOORS** (LSPLASH) | 7.13B visits, 13.2K CCU, 92.9% likes, 2 passes (Jan 2026) [G]; 226,937 CCU on the Archives Update, Aug 28, 2026 [L] | The player's own avatar, first-person-leaning camera; party **elevator** pre-show | Dim hotel lit by warm lamps and flashlights; iconic entity silhouettes; minimal UI. Description: "use each death as a lesson... Headphones & max graphics recommended... free Revive" for joining the group [G] | Entities as learnable rules; co-op screams; revives [L] |
| **Pressure** (Urbanshade) | 416.8M visits, 93.3% likes, 4 passes (Jan 2026) [G] | Own avatars, first person; lobby | Deep-sea industrial; cold blue-teal with red alarms; voiced shopkeeper Sebastian [L]. "You are expendable... Headphones & graphics level 8 or above recommended"; inspired by Doors, *Iron Lung*, *ULTRAKILL*, *SCP: CB* [G] | A charismatic NPC; the 2026 conduct scandal and the switch to 18+ [L] |
| **The Mimic** (MUCDICH / CTStudio) | Jan 2021 [L]; banned on Roblox VNG in Jul 2026 [L] | Own avatars, third person | High-fidelity Japanese folklore, cinematic chapters | "Most realistic Roblox horror"; long chapter gaps [L] |
| **Piggy** (MiniToon) | 14.03B visits, 12.9K CCU, 8 passes averaging 131 (Jan 2026) [G]; ~510K peak [L] | Own avatars; the Piggy "bot" is a Roblox-style character | Bright, blocky, cartoony | Chapters, skins, the 2020 craze; lore got too complex [L] |
| **Apeirophobia** (Polaroid Studios) | 436M visits [L] | Own avatars | Backrooms yellow wallpaper, fluorescent liminal spaces | Levels, entities, ownership disputes [L] |
| **3008** (uglyburger0 [B]) | [gap] | Own avatars, third person | Endless furniture store; bright by day; faceless "employees" at night; base building | SCP-3008 folklore, day/night survival [B] |
| **Dead Rails** (RCM Games) | 6.58B visits; 16.82-min sessions; Roblox TikTok boost [L] | Own avatars | Stylized desert western; bright day, dark night | An 80 km journey [L] |
| **99 Nights in the Forest** (Grandma's Favourite Games) | 21.9B visits, 506K CCU, 91.0% likes, **0 gamepasses** (dev products only) on Jan 6, 2026 [G]; 14.2M peak [L] | Own avatars plus class kits | Cozy-stylized forest; warm campfire vs dark fog; the Deer monster. Description: "Build a camp with friends. Something is watching you." [G] | A story premise, film deal, weekly updates [L] |
| **Forsaken** (Forsaken Dev Team) | 3.98B visits, 104K CCU, 85.8% likes, "RIA 2025 Best Survival Experience" (Jan 2026) [G] | **Play as a roster** of Roblox-folklore characters [L] | Stylized; event lobbies and skins [G] | Platform-native folklore as IP [L] |
| **Grace** (The Fartering Few) | Created Sep 3, 2024; **discontinued Apr 1, 2026** [L] | Own avatars | Doors-like speed-run horror | Conduct scandal [L] |
| *(bonus)* **Dandy's World** (BlushCrunch) | 5.59B visits, 105K CCU, 92.1% likes [G] | **Collectible "Toons"** as player characters [G] | "Mascot Horror Survival Multiplayer... team up with fellow Toons" [G] | Characters as the product [L] |

**What the baselines have in common (analysis):**

- **Identity.** Either the player's own avatar is visible, or a *named, stylized character roster* stands in for it (Forsaken, Dandy's World, Animal Hospital).
- **One iconic monster face** per game, fit for the thumbnail.
- **High contrast.** Darkness cut by warm practical lights or flashlights.
- **A pre-show or lobby**, such as an elevator.
- **"Headphones recommended."**
- **Frequent named updates.** Titles carry event tags (`[DAILY RUNS📟]`, `🎄`, `[🎆]`) [G].

---

## 13. Patterns: what successful anomaly and checker games on Roblox share in presentation

1. **You are a worker at a window, in first person, with a second lens.**
   - The window view shows one version; a CCTV, night-vision, photo, peephole or X-ray view shows the truth.
   - Seen in SSK, Animal Hospital, Keep the Door Locked, Home Alone and Terminal 13 [S].
   - Co-op teams **split observing from serving** [S].
2. **The rules are a prop and a voice, not a menu.** Rules are "taped to the counter" (SSK [G]), a chore board (Home Alone [S]) or "protocols" (T13 [G]), plus a radio or narrator voice (SSK [G/S]).
3. **Mistakes grow a visible monster or visibly corrupt the space**: the Inspector (SSK), sanity hauntings (Animal Hospital, Home Alone), a monster at shift end (T13) [S]. That escalation is the clip.
4. **NPCs have faces, voices and quirks, and tells come through several channels**: appearance, movement, speech, **voice mismatch**, and saying **your username** (SSK, Home Alone) [S]. The NPC look ranges from semi-realistic (SSK) to cartoon (Animal Hospital) to Robloxian (*Thats not my Robloxian*). **No hit I found uses faceless abstract figures** [I].
5. **Players are physically present and social.** Up to 4 in a shared space, free first-person movement (SSK, Animal Hospital), and third-person or character options (Animal Hospital). Identity comes from the player's own avatar or a class character [S/D].
6. **A lobby with modes.** Story (finite, 3-10+ endings with badges) and Endless (SSK) [S]; classes, settings and shop in the lobby (Animal Hospital) [S].
7. **Packaging built for creators.** "[HORROR]" tags, "3 AM", "do you serve him?", "Headphones & max graphics recommended", a face in the thumbnail, secrets and lore for theory videos [G/S].
8. **Live ops rhythm.** From weekly (Home Alone) and near-daily fixes (Animal Hospital), to monthly and seasonal events for SSK (Christmas Narrator, weather, Backrooms) [S].
9. **Light, social monetization.** Friend and VIP passes, cheap consumables (19-29 Robux), classes and skins; **backlash when power is sold** (Animal Hospital's gun) [S].
10. **Humor and specificity around the dread.** A shawarma kiosk with Santa saying "Merry Evening", a Hacker who breaks the fourth wall, a hospital run by animals [S]. A **distinct cultural flavor** ("sad Russian vibe") is itself a selling point [S].
11. **Clones arrive within weeks.** Speed, a named cast and continuous updates are the defense [S/G].
12. **Like ratios of about 85-95%** are normal for hits (SSK 90.1%, T13 88.7%, FNAF: Co-op 94.3%, *Thats not my Robloxian* ~95%) [G].

**Roblox's own guidance (primary) points the same way [D]:**

- "The closer your design patterns and user experience are to the most popular games in that genre, the less you have to explain."
- "Younger users are often less sensitive to visual fidelity."
- "Keep everything as visual as you can."
- Brookhaven's "Creator Cam" for streamers.

Sources: [Design for Roblox](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/design-for-roblox.md) [D].

---

## 14. Recommendations for Last Ferry (ranked by impact)

**Current state** (from the repo's `GAME_DESIGN.md` and `AGENTS.md`):

- Faceless passengers in coats and hats; only Mara wears red.
- `Players.CharacterAutoLoads = false`.
- A fixed booth camera that turns and leans.
- A HUD of panels: ticket and buttons on the left, rules and manifest on the right, speech at top centre.
- Realistic lighting and fog.
- No audio.
- Built only from parts.

### R1 (highest impact). Rebuild passengers as Roblox-rig characters with faces, a named cast, and stylized drowned variants

- **Build every passenger from a `HumanoidDescription`.**
  - Use a curated catalog outfit: coats, scarves, fishermen's gear, school uniforms, tourist hats.
  - Spawn with `Players:CreateHumanoidModelFromDescriptionAsync` ([Players API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Players.yaml), [Appearance docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/characters/appearance.md) [D]).
  - This makes them **read as Roblox instantly**, keeps variety data-driven (it fits the agent pipeline and the generator tests), and gives them **faces** for expressions and name-saying.
  - Use R15 rigs. Faces must stay visible at the window: no hats over eyes.
- **Make the drowned the *same people, wrong***, not realistic horror:
  - desaturated blue-green skin tone (a HumanoidDescription colour change);
  - a wet sheen, meaning a material or texture variant (a peer project found texture swaps read better than geometry: [nightdesk PROJECT_MEMORY](https://github.com/rushikeshgoud19/nightdesk/blob/master/PROJECT_MEMORY.md) [G]);
  - seaweed or barnacle accessories;
  - drip particles and puddles (already a rule);
  - later nights can be almost clean.

  Keep it "Mild/Moderate": no gore ([L] maturity notes).
- **Give 6-10 recurring characters names and one-line personalities**, like SSK's regulars (the Smiling Man, the Twins) and Animal Hospital's cast.
  - Mara in the red coat stays the icon.
  - Add, for example, an old fisherman, a nurse going home, twin schoolkids, a tourist with a camera, and the harbormaster R. Vell.
- **Evidence:**
  - SSK's customers are real people and fans, a key community hook: "WANT TO ADD YOUR CHARACTER?" [G].
  - SSK's big update made characters less "mannequin" [S].
  - Animal Hospital's character and visual rework coincided with 736K→1.2M CCU [S/G].
  - *Thats not my Robloxian* used Robloxians and got ~95% likes [G].
- **Optional Roblox-only scare for later nights.** A drowned passenger **wears a booth player's own avatar**, dripping wet (`GetHumanoidDescriptionFromUserIdAsync` [D]). A doppelganger of your friend at the window is peak clip material [I].

### R2. Put the players in the booth as their own avatars, with a uniform on top

- Turn on characters (`CharacterAutoLoads`) and spawn players *inside* the booth.
- Apply a **"limited modification"**: a ferry-clerk cap and oilskin raincoat accessory over each player's own avatar. The docs name "helmets... or accessories that match the genre" as the norm ([Appearance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/characters/appearance.md) [D]).
- **Camera.** Keep first person for yourself (show hands holding the ticket and stamps). Everyone sees teammates' full avatars.
- **Stations.** Make the booth slightly larger with 3-4 stations, so co-op matches SSK's "one observes, one serves" [S]:
  - the window and stamps;
  - the lamp or camera console;
  - a radio and manifest board;
  - the back door or lantern shelf.
- **Movement.** Allow walking between stations, which SSK and Animal Hospital both allow [S], and snap the camera to the window view at the ticket desk.
- **Pointing.** Add a **ping or point** emote so friends can say "look at his shoes!" without typing.
- **Evidence.** "Users... want [avatars] to be seen by their friends"; "single-player games often find it harder to build and retain an audience" ([Design for Roblox](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/design-for-roblox.md) [D]).

### R3. Add a lobby and pre-show: the Gull Harbor waiting room

- **Two doors**, like SSK's "Story left, Endless right" [S]:
  - **Story** (5 nights, 4 endings).
  - **Endless** (survive as many nights as you can; a leaderboard).
- **A gangway or "boarding ramp" party pad** for 1-4 players, in the spirit of the Doors elevator [B].
- **Instant solo start, no "waiting for players" screen.** A compiled growth guide warns those screens "kill joins" ([growth reference](https://github.com/TabooHarmony/roblox-brain/blob/main/skills/design/roblox-growth-design/references/full.md) [G]).
- **Settings in the lobby**, as Animal Hospital does [S]: motion-sickness mode, third-person/booth-cam, radio volume, colour-blind tells.
- **A cosmetic locker** (uniforms, booth decor) and the badge wall of endings.

### R4. Make the UI diegetic, chunky and consistent (mobile first)

- **Make the core UI physical props:**
  - **The ticket is a paper you hold.**
  - **BOARD is a big green stamp.**
  - **TURN AWAY is the red shutter or stamp.** SSK's red button is iconic [S].
  - **The rules card is taped to the window frame**, as SSK's rules are "taped to the counter" [G].
  - **The manifest is a clipboard.**
- **Colour language.** Pick a small set and apply it everywhere, with bright colours for critical elements and buttons in containers ([UI/UX design](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/ui-ux-design.md) [D]):
  - green = board / safe;
  - red = refuse / danger;
  - amber = warning;
  - sea-teal = drowned or supernatural.
- **Keep existing constraints.** Touch targets of 44 px or more; the bottom centre stays clear for shadows; nothing covers the face.
- **Show speech in a bubble above the passenger**, using `TextChatService:DisplayBubble(character, message)` on the client. Style it per NPC with `OnBubbleAdded`: for example, a waterlogged bubble for the drowned ([Bubble chat docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/chat/bubble-chat.md) [D]).
  - Keep the top-centre subtitle for accessibility and for muted phones.
  - Keep lines to about 8-15 words ([L] craft notes).
- **The name tell.** Have the drowned say a *booth player's* **DisplayName** in the bubble ("Is that you, Sam?"). This mirrors SSK's Hacker, who uses your username [S], and in co-op it creates panic about "who did it pick?" [I].
- **Fonts.** One bold display font for headers and buttons, and a typewriter or ticket font for documents. Test legibility at phone scale [D].
- **Onboarding.** Teach the first rule with **in-world highlights and arrows, not text** ([Onboarding techniques](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/onboarding-techniques.md) [D]).

### R5. Push the art direction to a stylized night with strong contrast and saturated accents

- **Keep the fog, but let it frame rather than flatten.**
  - Contrast warm **sodium-orange lamp pools** against deep **teal and navy night**.
  - Use **wet, specular planks**.
  - Use saturated signature colours: **Mara's red coat, the red gull stamp, the green BOARD stamp, lantern orange**.
  - Apply colour correction and bloom sparingly.
- **Make every tell pop against the background.** A peer anomaly project found "blown-out contrast... a 4% skin-tone shift cannot register when everything is either black or blooming", and that "stock materials are the visual signature of an unfinished Roblox game" ([nightdesk playtest findings](https://github.com/rushikeshgoud19/nightdesk/blob/master/docs/playtest-findings.md) [G]).
- **Replace plain parts on hero props** (the booth, lamp, ferry, gangway, signage) with **licensed PBR assets or SurfaceAppearance**. Follow the studio's asset-licensing checklist (`research/07-assets-licensing-and-pipeline.md`) [I].
- **Evidence.** This keeps the "Realistic" shadow requirement (the shadow rule needs crisp local-light shadows, per `AGENTS.md`). Visual fidelity matters less than readability for young players [D].

### R6. Add a second lens, and embody failure in a monster

- **Second lens.** A **lighthouse sweep, a "harbor camera" monitor, or an old Polaroid** that shows the drowned's true form:
  - a skeleton;
  - a waterline on the body;
  - someone missing entirely, like SSK's "Nightvision Missing" [G/S].
  - This mirrors SSK's CCTV and night vision, Animal Hospital's photo and CCTV, and Keep the Door Locked's peephole vs camera [S].
  - It also **gives the 2nd-4th co-op players a job** [I].
- **Embodied failure.** Replace or augment "three lanterns" with a **visible, escalating threat**, as with SSK's Inspector rising from the floor [S]. Examples:
  - **the tide rising inside the booth**, one step per mistake;
  - **R. Vell's silhouette climbing the pier ladder** closer each time;
  - **the drowned *Marigold*'s bell ringing nearer** in the fog.

  Lose, and the booth floods (a clip moment).

### R7. Add voice, music and sound (they are part of the look)

- **Voice Pike.** Hire a voice actor, or use TTS for barks: `AudioTextToSpeech` takes up to 300 characters per request ([L]/[D]).
- **Music.** A melancholy harbor theme is Last Ferry's equivalent of the "sad Russian vibe" (SSK's composer and narrator are credited [G]).
- **Sound effects:** ferry horn, rope creak, drips, the stamp thunk, a **sting when a drowned passenger says your name**.
- Put "🎧 Headphones recommended" in the description (Doors, Pressure, T13, Road-Side Sushi all do [G]).
- **Keep a visual twin for every audio cue**, which the design already requires.

### R8. Package for creators and clips

- **Title.** Use the genre's tags, e.g., "Last Ferry [HORROR]", with seasonal emoji prefixes during events [G].
- **Thumbnail.** A **face at the ticket window**: a dripping passenger holding a 1999 ticket, and Mara's red coat. Pair it with a question hook ("Would you let her board?"), echoing Jazzghost's "Do you serve him?" at 1.14M views [G].
- **Streamer mode.** Add a "Creator Cam" or hide-HUD toggle ([Design for Roblox](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/design-for-roblox.md) [D]).
- **Clip rhythm.** Aim for a reaction beat every 60-90 s.
- **Secrets for theory videos.** The ledger pages are perfect for this; Animal Hospital's lore videos trended [G].
- **Community.** Consider a **moderated "put your character on the ferry" program**. SSK's Discord invite was "Yes — you can become part of the game" [G].

### R9. Monetization and live ops in the genre's style

- **Price co-op fairly.**
  - Keep **co-op free**. SSK sells a 299-Robux Friend Pass [S], but Roblox advises not making it hard for friends to play together [D].
  - Offer a **VIP server pass**: SSK charges 699 Robux [S].
- **Paid content:**
  - Cosmetic **uniforms and booth skins** (Animal Hospital skins [S]).
  - Cheap **consumable helpers** in the 19-29 Robux range, as SSK's "Corruptions" are [S], e.g., "Relight a lantern" (already planned).
  - **Earnable roles** (Clerk, Lamplighter, Radio Operator). **Never sell a power that skips checking**, as Animal Hospital's gun backlash shows [S].
- **Cadence.** Ship something every 3-6 weeks, like SSK [S].
  - A "Storm Night" weather event, echoing SSK's Weather Update [S].
  - An annual **"Marigold anniversary" event on November 14**, the lore date in `GAME_DESIGN.md`.
  - Holiday passengers, like SSK's "Merry Evening" Santa [S].
  - New named passengers each update.
- **Endless mode** is the mid-game retention layer. SSK has one [S], and a peer project calls weak mid-game retention the genre's weakness ([nightdesk README](https://github.com/rushikeshgoud19/nightdesk) [G]).

### What to avoid

- **Faceless or abstract NPCs and grey, low-contrast scenes.** No hit in the genre uses them, and subtle tells vanish ([nightdesk](https://github.com/rushikeshgoud19/nightdesk/blob/master/docs/playtest-findings.md) [G]).
- **Realistic human faces or photos.** Moderation blocked SSK's attempt [G]. Also avoid realistic gore: The Mimic was banned on Roblox VNG for extreme horror [L].
- **Removing avatar identity without a reason** [D]. Animal Hospital's reason was a full character IP with classes and skins [S].
- **Paywalling friends, or selling power that trivializes the checks** (Animal Hospital's "PAY TO WIN" videos [S]).
- **Text-heavy onboarding, long unskippable intros, "waiting for players" screens** [D/G].
- **Audio-only tells** (most players are on mobile, often muted [D]).
- **Copying another game's title or thumbnail format.** Clones get mocked ("I Played FAKE Animal Hospital Anomaly Games") and a compiled growth guide warns of metadata penalties [G].
- **Long gaps between updates.** Home Alone updates weekly and Animal Hospital near-daily [S]. The genre decays fast (SSK went from 100K+ to about 12.6K CCU) [G/S].

---

## 15. Gaps and how to close them (about one hour of hands-on play)

1. **Play SSK, Animal Hospital, Terminal 13 and Keep the Door Locked for 15 minutes each on a phone and a PC.** Screenshot:
   - fonts, button shapes and HUD colours;
   - how NPC speech is shown (bubble or subtitle);
   - whether your own avatar is visible (SSK);
   - the lobby layout;
   - the thumbnail and icon on the game page.

   None of this could be verified here.
2. **Record real CCU peaks** from Rolimons or RoMonitor for SSK, Terminal 13, Home Alone and Keep the Door Locked. They were blocked here, and the trackers conflict (§3.2, §5).
3. **Check the Friend Pass.** Is co-op in SSK gated behind it?
4. **Profile Roblox Exit 8 and Platform 8 clones, *Midnight Horrors*, and any ferry or harbor games.** The search budget ran out.

---

## 16. Sources

**Primary (read directly)**

- Roblox creator-docs: [Design for Roblox](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/design-for-roblox.md) · [UI/UX design](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/ui-ux-design.md) · [Bubble chat (NPC bubbles)](https://github.com/Roblox/creator-docs/blob/main/content/en-us/chat/bubble-chat.md) · [Customize appearance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/characters/appearance.md) · [Players API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Players.yaml) · [Onboarding techniques](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/onboarding-techniques.md) · [Roblox user base](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/roblox-user-base.md)
- Studio repo: `games/last-ferry/GAME_DESIGN.md`, `games/last-ferry/AGENTS.md`, `research/06-story-driven-games-on-roblox.md` (read only)

**GitHub-hosted third-party data (read directly; directional)**

- RTE100 top-earning index, Jan 2026 daily exports: https://github.com/nickpio/top-earning-parser/tree/master/index_data/exports · Weekly report: https://github.com/nickpio/top-earning-parser/blob/master/index_data/exports/Weekly%20Reports/rte100_report_2026-01-08.md · Top-1500 snapshot with official descriptions (Jan 6, 2026): https://github.com/nickpio/top-earning-parser/blob/master/runs/2026-01-06/raw/2026-01-06_top-earning_top1500_enriched.json
- YouTube trending snapshots: https://github.com/gpsyrou/tube-virality (assets/meta/trending: US_20251220, BR_20260111, KE_20260215, MX_20251207, MX_20260102, PH_20260111, PL_20251223, US_20260624, US_20260712, US_20260826, BR_20260628, BR_20260726, PH_20260726, PL_20260818, ZA_20260701, ID_20260825)
- Trend radar (Sep 13, 2026): https://github.com/Fuheshka/game-trend-radar/blob/main/data/reports/market_report_2026-09-13.md
- Roblox news memos: https://github.com/hczhu/stock-research/blob/main/memos/2026-07-23-roblox-ai-feed-creator-tools-games-safety.md · https://github.com/hczhu/stock-research/blob/main/memos/2026-07-04-roblox-news-roundup-age-check-fallout-adult-pivot.md
- Roblox game scrape (Nov 2024): https://github.com/jansencruz23/roblox-webscraper-csharp/blob/main/RobloxWebScraper/data/roblox_games_list.csv
- Growth-design reference: https://github.com/TabooHarmony/roblox-brain/blob/main/skills/design/roblox-growth-design/references/full.md
- SSK fan data: https://github.com/cdg-hue/shawarma-kiosk-share · https://github.com/bingkahu/scary-shawarma-wiki
- Peer anomaly project: https://github.com/rushikeshgoud19/nightdesk (docs/playtest-findings.md, PROJECT_MEMORY.md) · https://github.com/uxabix/TFC-Horror
- Low-quality listing (Midnight Horrors): https://github.com/kaichen0621/kaiblog/blob/main/docs/roblox/roblox.md

**Search-summary sources, by game [S]**

- **SSK:**
  - Wikis and trackers: https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror) · https://roblox.fandom.com/wiki/Player:Kharbor_ykt · https://scary-shawarma-roblox.fandom.com/wiki/Scary_Shawarma_Kiosk_Wiki · https://scary-shawarma-roblox.fandom.com/wiki/The_Inspector · https://scary-shawarma-roblox.fandom.com/wiki/Phone · https://www.rolimons.com/game/137826330724902 · https://servicespv.com/en/blox/stats/scary-shawarma-kiosk-the-anomaly-horror-by-kharbor-ykt-roblox
  - Sportskeeda: https://www.sportskeeda.com/roblox-news/all-scary-shawarma-kiosk-the-anomaly-anomalies · https://www.sportskeeda.com/roblox-news/how-identify-mannequin-scary-shawarma-kiosk-the-anomaly · https://www.sportskeeda.com/roblox-news/all-rules-scary-shawarma-kiosk-the-anomaly · https://www.sportskeeda.com/roblox-news/how-survive-inspector-scary-shawarma-kiosk-the-anomaly · https://www.sportskeeda.com/roblox-news/how-deal-clown-scary-shawarma-kiosk-the-anomaly · https://www.sportskeeda.com/roblox-news/all-endings-scary-shawarma-kiosk-the-anomaly · https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-global-update-patch-notes · https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-the-narrator-update-patch-notes · https://www.sportskeeda.com/roblox-news/when-next-scary-shawarma-kiosk-the-anomaly-update · https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-backrooms-event-guide · https://www.sportskeeda.com/roblox-news/scary-shawarma-kiosk-the-anomaly-christmas-night-shift-guide · https://www.sportskeeda.com/roblox-news/all-corruptions-scary-shawarma-kiosk-the-anomaly
  - Other guide sites: https://deltiasgaming.com/roblox-scary-shawarma-kiosk-the-anomaly-global-update-guide/ · https://deltiasgaming.com/roblox-all-rules-in-scary-shawarma-kiosk-the-anomaly/ · https://deltiasgaming.com/roblox-scary-shawarma-kiosk-the-anomaly-clown-guide/ · https://www.droidgamers.com/guides/how-to-play-scary-shwarma-kiosk-the-anomaly/ · https://www.droidgamers.com/guides/scary-shawarma-kiosk-the-anomaly-all-anomalies-and-how-to-spot-them/ · https://www.droidgamers.com/guides/scary-shawarma-kiosk-the-anomaly-hints-and-tips/ · https://www.droidgamers.com/guides/scary-shawarma-kiosk-the-anomaly-inspector-guide/ · https://techwiser.com/scary-shawarma-kiosk-anomalies-guide/ · https://techwiser.com/scary-shawarma-kiosk-all-game-modes/ · https://techwiser.com/scary-shawarma-kiosk-the-anomaly-corruptions/ · https://techwiser.com/scary-shawarma-kiosk-weather-update-release-countdown/ · https://techwiser.com/scary-shawarma-kiosk-shop-update-release-countdown/ · https://techwiser.com/roblox-scary-shawarma-kiosk-the-anomaly-codes/ · https://www.gamezebo.com/walkthroughs/scary-shawarma-kiosk-anomalies/ · https://gatagames.com/2025/12/19/scary-shawarma-kiosk-the-anomaly-all-anomalies-and-how-to-spot-them/ · https://ffbooyah.com/2026/01/08/cctv-camera-guide-for-scary-shawarma-kiosk-how-to-spot-anomalies-early-and-survive-every-night-shift/ · https://findingdulcinea.com/scary-shawarma-kiosk-wiki/ · https://bloxinformer.com/wikis/scary-shawarma-kiosk-the-anomaly/ · https://beebom.com/scary-shawarma-kiosk-the-anomaly-codes/ · https://www.destructoid.com/scary-shawarma-kiosk-the-anomaly-codes/ · https://scaryshawarmakiosk.com/scary-shawarma-kiosk-faq · https://scary-shawarma-kiosk.com/blog/all-endings-complete-guide · https://scary-shawarma-kiosk.com/blog/february-may-update-timeline · https://scaryshawarmakiosk.org/badges/ · https://www.rosenberryrooms.com/all-scary-shawarma-kiosk-special-events/
  - Rolimons passes and badges: https://www.rolimons.com/gamepass/1608103276 · https://www.rolimons.com/gamepass/1679499290 · https://www.rolimons.com/gamebadge/3135139714184023
  - Developer press: https://exo-ykt.ru/articles/zhitel-yakutska-sozdal-v-roblox-igru-i-v-nee-sygrali-uzhe-milliard-raz · https://sakhatime.ru/society/117174/ · https://exo-ykt.ru/articles/boris-haranutov · https://vecherniy.com/news/istorija_uspekha_razrabotchika_iz_jakutska/2026-04-28-2730 · https://59.ru/text/world/2026/04/19/76373185/
  - YouTube and TikTok: https://www.youtube.com/watch?v=y5ql2jdCXGk · https://www.youtube.com/watch?v=Yn7UA3M-148 · https://www.youtube.com/watch?v=KASLOG3RRAk · https://www.youtube.com/watch?v=YtgVoHLyb5g · https://www.tiktok.com/@doodlefae/video/7580195998107012382
  - Clones: https://www.rolimons.com/game/97267505570231 · https://www.roblox.com/games/97267505570231/Road-Side-Shawarma · https://www.sportskeeda.com/roblox-news/road-side-shawarma-a-beginner-s-guide · https://deltiasgaming.com/roblox-road-side-shawarma-a-beginners-guide/ · https://www.rolimons.com/game/109366027244026 · https://apps.apple.com/us/app/-/id6759698340 · https://apps.apple.com/app/id6757749418
- **Animal Hospital:**
  - Wikis and news: https://animal-hospital.fandom.com/wiki/Animal_Hospital_(Game) · https://roblox.fandom.com/wiki/Animal_Anomaly/Animal_Hospital · https://www.gosugamers.net/entertainment/news/78741-animal-hospital-becomes-roblox-s-latest-horror-sensation-here-s-everything-you-need-to-know · https://www.gosugamers.net/entertainment/news/78773-roblox-animal-hospital-hits-1-2-million-ccu-with-major-update-featuring-new-character-and-items · https://www.gosugamers.net/entertainment/news/79176-full-list-of-winners-at-the-roblox-innovation-awards-2026 · https://www.gosugamers.net/entertainment/news/78750-all-classes-in-roblox-animal-hospital-explained-with-perks-and-best-class-tier-list · https://variety.com/2026/gaming/news/animal-hospital-roblox-innovation-awards-20th-anniversary-1236860184/ · https://about.roblox.com/newsroom/2026/09/2026-roblox-innovation-awards · https://www.bluestacks.com/blog/updates/roblox/rl-animal-hospital-july-update-en.html · https://animalhospital.blog/release-date/ · https://briefledger.co.uk/what-is-animal-hospital-on-roblox-my-12-year-old-explains-the-summers-biggest-craze/
  - Guides: https://animal-hospital.fandom.com/wiki/Dr._Harlow · https://allthings.how/every-animal-hospital-character-in-roblox-explained/ · https://allthings.how/catch-every-anomaly-in-animal-hospital-roblox-with-3-checks/ · https://www.thespike.gg/roblox/animal-hospital/all-anomalies · https://animal-hospital.fandom.com/wiki/Treatment · https://animal-hospital.fandom.com/wiki/Classes · https://animal-hospital.fandom.com/wiki/Skins · https://animal-hospital.fandom.com/wiki/Animal_Coins · https://animal-hospital.fandom.com/wiki/Gamepasses · https://beebom.com/roblox-animal-hospital-classes-guide/ · https://www.sportskeeda.com/roblox-news/animal-hospital-classes-guide-prices-perks · https://esports.gg/guides/roblox/third-person-camera-animal-hospital/
  - Criticism and drama: https://www.youtube.com/watch?v=miVFlBIqu8g · https://www.youtube.com/watch?v=kuQ7Yz3gm54 · https://www.youtube.com/watch?v=SU21H8Zq4VM · https://allthings.how/animal-hospital-roblox-drama-explained-the-controversy-around-the-viral-game/
  - Fan avatar game: https://www.roblox.com/games/108064260980984/Animal-Hospital-Avatars
- **Terminal 13:** https://www.rolimons.com/game/126293024094985 · https://www.roblox.com/communities/33501450/Dread-Forge · https://progameguides.com/roblox/complete-terminal-13-not-human-walkthrough/ · https://progameguides.com/roblox/terminal-13-not-human-second-shift-walkthrough-chapter-2/ · https://deltiasgaming.com/roblox-how-to-play-terminal-13-not-human/ · https://www.sportskeeda.com/roblox-news/terminal-13-not-human-a-beginner-s-guide · https://www.sportskeeda.com/roblox-news/terminal-13-not-human-christmas-update-patch-notes · https://servicespv.com/en/roblox/stats/terminal-13-not-human-horror-by-dread-forge-roblox
- **Door checkers:**
  - Thats not my Robloxian: https://www.rolimons.com/game/16794833014 · https://thats-not-my-robloxian.fandom.com/wiki/Thats_not_my_Robloxian · https://deltiasgaming.com/thats-not-my-robloxian-a-beginners-guide/ · https://progameguides.com/roblox/how-to-find-the-clones-in-thats-not-my-robloxian-roblox/ · https://www.roblox.com/games/16906926480/Thats-Not-My-Blocky-Neighbor · https://knowyourmeme.com/memes/subcultures/thats-not-my-neighbor-see-my-name-on-the-list-right
  - Keep the Door Locked: https://robipedia.com/game/keep-the-door-locked-anomaly-10232686472 · https://creatorexchange.io/roblox-game/10232686472/keep-the-door-locked · https://www.rolimons.com/game/124338404742585 · https://keepthedoorlockedroblox.wiki/en/guides/keep-the-door-locked-roblox-guide/ · https://beebom.com/all-keep-the-door-locked-anomalies/ · https://techwiser.com/keep-the-door-locked-all-anomalies/
  - Home Alone: Anomalies: https://www.rolimons.com/game/87468080405188 · https://allthings.how/home-alone-anomalies-anomaly-update-schedule/ · https://progameguides.com/roblox/home-alone-walkthrough-anomalies-chores-more/ · https://www.sportskeeda.com/roblox-news/all-anomalies-home-alone
- **Genre overviews:** https://comicbook.com/gaming/news/robloxs-next-big-horror-trend-has-players-searching-for-anomalies-and-some-are-seriously-scary/ · https://spottheanomaly.wiki/roblox-anomaly-games-list · https://spottheanomaly.wiki/anomaly-games · https://spottheanomaly.wiki/anomaly-watch · https://anomaly-watch-roblox.fandom.com/wiki/Anomalies · https://www.roblox.com/games/115500497807053/Anomaly-Observation
- **Night-shift family and boats:** https://www.roblox.com/games/127995006069066/Night-67 · https://www.rolimons.com/game/8404684575 · https://www.roblox.com/games/8404684575/Short-CREEPY-stories · https://short-creepy-stories-roblox.fandom.com/wiki/Ominous_Steamboat · https://www.droidgamers.com/guides/short-creepy-stories-ominous-steamboat-walkthrough/
- **Baselines** (via [L]; see that file's §12 for its full list): https://rovitals.com/game/6516141723 · https://pressure.fandom.com/wiki/Pressure · https://mimic.fandom.com/wiki/The_Mimic · https://piggy.fandom.com/wiki/Piggy_(Game) · https://apeirophobia.fandom.com/wiki/Apeirophobia · https://roblox.fandom.com/wiki/RCM_Games/Dead_Rails · https://www.pcgamer.com/games/survival-crafting/with-a-peak-player-count-of-14-2-million-99-nights-in-the-forest-has-an-audience-other-multiplayer-games-would-kill-for-to-find-these-behemoth-playerbases-you-need-to-be-on-a-platform-like-roblox/ · https://forsaken2024.fandom.com/wiki/FORSAKEN · https://roblox.fandom.com/wiki/The_Fartering_Few/Grace · https://en.namu.wiki/w/weird%20strict%20dad
