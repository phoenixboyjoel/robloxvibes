# Narrative & Story-Driven Games on Roblox: What Worked, What Failed, and Why

**Prepared for:** Joel Z, Phoenix Feather Studios ("telling interesting stories via interesting gameplay")
**Research date:** 2026-09-29
**Scope:** Roblox horror, story, and narrative-framed games from 2018 to September 2026. Covers case studies, the micro-horror "story game" genre, monetization, failure modes, craft techniques, 2025-2026 hits, and what a story-first studio building with AI coding agents should do.

---

## 0. Method and confidence legend (read this first)

**Research limits.** Outbound web access was restricted. WebFetch was blocked for Roblox.com, DevForum, Wikipedia, Fandom, Reddit, YouTube, X, trackers and most news sites. Only github.com and raw.githubusercontent.com could be fetched. This agent ran about 45 targeted web searches before the session-wide search budget (200) ran out. That means:

- Most game metrics below come from **search-engine summaries** of wikis (Fandom, NamuWiki, official wikis), trackers (RoVitals, Rolimons, RoWatcher, ServicesPV, BloxQuiz) and news sites. I could not open the pages themselves to check them.
- Platform rules (monetization, maturity, ads, DevEx, AI APIs) come **directly from Roblox's official `creator-docs` GitHub repository**, fetched on 2026-09-29. These are the most reliable facts in this report.
- Where I relied on general knowledge, it is labeled.

| Tag | Meaning |
|---|---|
| **[V]** | Found in this session in a search result summarizing the cited source. The source is secondary (wiki, tracker or news) and was not audited. |
| **[DOC]** | Read directly from Roblox's official creator-docs repo on GitHub (primary source, fetched 2026-09-29). |
| **[T]** | A third-party tracker snapshot or revenue *model*. Treat as directional only. RoVitals itself says actual earnings "can differ several-fold." |
| **[B]** | Background knowledge from training data (up to about mid-2026). **Not freshly verified.** |
| **[U]** | Unverified, or sources conflict. Use with caution. |
| **[EST]** | My own illustrative arithmetic based on stated assumptions. **Not data.** |

---

## 1. Executive summary

1. **On Roblox, the narrative games that last deliver story through systems, not cinema.** Durable hits turn story into rules and mechanics:
   - Doors: each entity is one rule you learn.
   - Scary Shawarma Kiosk: a rules card, with anomalies to detect.
   - 99 Nights in the Forest: a rescue mission laid over a survival loop.
   - Dead Rails: a destination 80 km away.
   - Forsaken and Dandy's World: the character roster is the lore.

   Cutscene-heavy linear stories can spike, but they burn out fast.
2. **Linear "story games" were a real genre and still are.** Camping (SamsonXVI, 2018-19) started the trend. Break In, Field Trip Z (16 endings) and Guesty followed. They can explode: Break In 2 reached **100M visits in 12 days [V]**. But players finish them in one session. They survive through sequels, multiple endings with badges, and a studio's portfolio breadth.
3. **Episodic chapters cut both ways.** Piggy's chapters took it to about **510K peak CCU and 13B+ visits [V]**. Book 2 launched on Sep 12, 2020 at 500K+ players. Within about a month a fan tracker reported **fewer than 100K at peak** (Oct 2020) [V/U]. Over time Piggy lost about 97% of its players (video analysis). Ending the main story, making the lore more complicated, and slowing the update pace all hurt it.
4. **The most durable pattern is procedural replay + co-op + a light lore mystery + big "floor" updates.** Doors has **7.79B visits**. It still drew about 28K CCU in late Sep 2026 and spiked to **226,937 CCU when the Archives Update launched on Aug 28, 2026** [T].
5. **The cheapest format with the strongest recent return is "night-shift / anomaly" micro-horror.** *Scary Shawarma Kiosk: the ANOMALY* is by a **solo Russian developer (kharbor_ykt)**, launched Aug 24-25, 2025, and reached **about 1.3B visits in about 13 months** [V]. Copycats followed within months, both on Roblox and as iOS App Store clones [V].
6. **The 2025 mega-hit came from a story-game developer.** *99 Nights in the Forest* is by Grandma's Favourite Games, co-founded by Cracky4, the creator of Break In. It reached **14.2M peak CCU [V]**, about 26B visits by Apr 2026 [V], and a **20th Century Studios film deal on Apr 13, 2026 [V]**. It wraps a survival-crafting loop around a clear story goal: rescue four missing children. The title itself is the logline.
7. **In 2024-2026 the biggest failures came from people, not design:**
   - **Grace** was discontinued on Apr 1, 2026 after a controversy involving its lead developer [V].
   - **Pressure** lost its voice actor and character designer in Apr 2026 after misconduct allegations against its creator. It vanished from Roblox on May 7, 2026 and came back **18+ only** on May 8 [V].
   - **Dandy's World** and **Apeirophobia** had credit and ownership disputes [V].
   - **Piggy's** fandom became toxic [V].
8. **Compliance is now part of design.** Maturity labels decide who can play [DOC]:
   - "Mild fear" still reaches the youngest tier ("Roblox Kids", ages 5-8).
   - "Moderate fear" starts at "Roblox Select" (ages 9-15).
   - "Restricted" is 18+ ID-verified only, and unplayable in Korea, Saudi Arabia and Türkiye.

   *The Mimic* was banned on Roblox VNG (Vietnam) in July 2026 for extreme horror [V].
9. **Monetization that doesn't break the story:**
   - Sell revives at failure moments.
   - Use soft currency with a pre-run shop.
   - Sell roles, classes or characters, plus cosmetics and private servers.
   - **Never paywall endings.**
   - Rewarded video ads **cannot be progress gates** [DOC].

   Newer levers [DOC]:
   - Subscriptions priced in local currency pay the creator **70% in month 1, then 100%**.
   - Paid access in local currency costs $9.99, $29.99 or $49.99, with a 50-70% creator share.
   - Roblox Plus sign-up bonuses exist.
   - A **U.S. 18+ DevEx rate of $0.0054 per Robux** (standard rate $0.0038) took effect June 8, 2026.
10. **AI agents fit anomaly and anthology micro-horror best.** Those formats are mostly logic, variation, UI and text. Art, audio, scare timing and community remain the bottlenecks. Roblox Studio now has a **built-in MCP server**; the standalone repo was archived on Apr 3, 2026 [DOC]. Every competitor gets the same speed-up, so **the moat is IP (characters people love), release cadence, and community.**

---

## 2. Case-study table (landmark narrative, horror and story-framed games)

> Metrics are the latest found. "Peak" is all-time unless noted. See §11 for the source URLs behind each row.

| # | Game | Developer / team | Launch | Format / narrative method | Key metrics | Monetization (known) | Outcome / why | Conf. |
|---|---|---|---|---|---|---|---|---|
| 1 | **DOORS** | LSPLASH: Lightning_Splash + co-dev RediblesQW. About 5 core devs and about 50 QA testers. Studio founded 2017 (earlier games: Ragdoll Universe, VOCAB HAVOC). | Dev began late 2020; released Aug 10, 2022. Hotel+ Jan 28, 2023. Floor 2 "The Mines" [B: 2024]. Archives Update Aug 28, 2026. | Co-op procedural 100-door floors. Entities work as rules (Rush, Seek, Figure…). Sub-floors (The Rooms, Backdoor). Inspired by Spooky's Jump Scare Mansion and nicorocks5555's *Rooms*. | **7,785,867,491 visits.** 145.3M visits in the last 30 days. Highest peak RoVitals recorded: **226,937 (Aug 28, 2026)**. About 28K CCU at check (#32 of 24,173 tracked). The earlier all-time peak (2022-23) is unknown. | Knobs (earned per run, or bought with Robux). **Revives (Robux only).** Pre-run shop. RoVitals model: $1.3K-$11.9K per day, about $119K per 30 days (central) [T]. | Still alive four years on because procedural replay, big floor updates and events (April Fools modes [B]) keep it fresh. The official wiki is self-hosted (doorsgame.wiki). | V / T |
| 2 | **Pressure** | Urbanshade: Hadal Division. Lead YourFriendZeal (Denmark). Voiced shopkeeper Sebastian Solace (Gianni Matragrano). | Beta Feb 7, 2024. Release Jul 7, 2024. | Doors-like deep-sea procedural horror. Documents and terminals. A charismatic voiced NPC. | 453M-489M visits (sources differ). 1.6M favorites. Peak CCU unknown. | Unknown in detail [gap] | Dec 2024: Zeal reportedly turned down an **eight-figure Robux buyout offer**. **Apr 2026:** a former contributor made serious misconduct allegations against the lead developer (reported, not adjudicated). The voice actor and the character designer quit. **May 7, 2026: the game vanished. May 8: it returned restricted to 18+**, apparently over an outdated maturity questionnaire. Under-18 players who had spent money were locked out. | V |
| 3 | **The Mimic** | CTStudio / MUCDICH. Solo until about Jun 2021, then about 5 devs (CactusHasDied, JustYourKarma, Ampient, ciovz, Sythivo). | Jan 15, 2021 | Cinematic chapter horror built on Japanese urban legends. "Books" with a "Beast" antagonist per book. | Visits not found [gap]. Structure conflicts: one source says 9 chapters across 3 books in 5 years; another says 4 books of 4 chapters [U]. | Unknown [gap] | Long delays between chapters: the dev apologized on TikTok in Jan 2024 before Book 2 Ch 3. Jealousy's final chapter came May 30, 2025. **Banned on Roblox VNG (Vietnam) in Jul 2026** for extreme horror. | V |
| 4 | **Piggy** | MiniToon (later MiniToon Inc) | Jan 2020 [B] | Episodic escape horror. Book 1 (12 chapters [B]) and Book 2, plus character-focused chapters. Piggy played by a bot or a player. Build Mode [B]. | **13B+ visits (Mar 2025).** 1B visits in 83 days (3rd-fastest ever). **~510K peak CCU** after Book 1 Ch 12. Book 2 (Sep 12, 2020) topped Adopt Me! at 500K+. **"<100K at peak" by about Oct 10, 2020** (fan news account) [U]. | Skins and cosmetics [B]. A fan-forum claim of about 64-65M Robux banked by Jul 2024 [U]. Franchise includes novels, merch, and games outside Roblox [V]. | Story ended in Nov 2021. No major updates after Nov 2022. About −97% players: lore too convoluted for young players, a toxic fandom (death threats aimed at the developers), a repetitive loop, and slower releases. | V / U |
| 5 | **Rainbow Friends** | Roy & Charcle | Ch 1 2022 [B]. **Ch 2 Jun 2, 2023** [V]. | Co-op mascot horror in chapters | 1B, then **5B+ visits** | [gap] | A gap of about 10 months between chapters [B]. Fan-made "Chapter 2" clones filled the wait [V: clone listing exists]. | V / B |
| 6 | **Dandy's World** | BlushCrunch Studio (Qwelver). Co-lead Rox fired Oct 7, 2024. | Public alpha Jun 14, 2024 | Co-op mascot horror. Elevator descends through floors. Collectible playable "Toons" with personalities, hunted by "Twisted" versions of themselves. | **1B visits by Dec 2024; 2B by Feb 2025; 5B by Nov 2025; 6B+ by Feb 27, 2026.** Typically 96K+ CCU. | Toons (earned or bought) [B] | A character-driven fandom (fan art and animation). Artists alleged uncredited designs. **Still in alpha as of Mar 2026.** | V |
| 7 | **FORSAKEN** | Forsaken Dev Team | Created Jul 27, 2024. Launched Dec 25, 2024. | Asymmetric Dead by Daylight-style horror. The roster comes from **Roblox myths and legends** (1x1x1x1, John Doe, Guest 666, Shedletsky). Inspired by *The Robloxia: Until Dawn*. | **4.0-4.6B visits.** About 80K average CCU. Peak **577,191** (one source) vs a "1.2M" claim [U]. | Characters and skins [B] | Won **Best Survival Experience, Roblox Innovation Awards 2025**. Turns Roblox's own folklore into IP. | V / U |
| 8 | **Regretevator** | The Axolotl Sun (lead yeuc_c) | 2020 | Random-floor elevator horror-comedy with social play | 200M+ visits by early 2025 [U: low-grade source] | [gap] | Character comedy and a big fandom. It descends from the old "Normal Elevator" format [B]. | V / U |
| 9 | **Apeirophobia** | Monochrome Studios, then Polaroid Studios | Jul 19, 2022 | Backrooms-style levels (0-24, plus 666), puzzles and entities | **436M visits** | [gap] | Ownership disputes. In **mid-Dec 2025 a new owner took over and the original devs stopped work**. Their successor project is *Elsewhere* (Black Corridor). | V |
| 10 | **Break In / Break In 2 (Story)** | Cracky4 (Alec Kieft, NZ) | BI about 2020 [B]. BI2 in 2023 [B]. | Linear co-op story with roles, items, fights, and **4 endings (good, secret, evil, origin)** | **BI2: 100M visits in 12 days** | Roles and items [B] | A blueprint for the modern story game. Its creator went on to co-found 99 Nights. | V |
| 11 | **99 Nights in the Forest** | Grandma's Favourite Games (NZ): Alec Kieft (Cracky4), Matthew Hufton, Cameron Angland. Group founded Apr 2020. | Created Mar 4, 2025. Launched about May 2025. | Survival-crafting plus a narrative mission: **rescue four missing kids** from a deer monster and cultists. Inspired by the real 2023 Caquetá plane-crash survival. | Passed **1,023,439 CCU on about Jul 18, 2025**. **Peak 14.2M CCU.** About 26B visits by Apr 2026; 29.77B on Rolimons later. About 339K CCU in Jul 2026 [T]. 7th most-played Roblox game ever. | Classes and premium currency [B]. A RoMonitor monetization page exists [gap: not read]. | **20th Century Studios film (Apr 13, 2026)**, written by Josh Cooley, with the devs as executive producers. Kieft spoke at **GDC 2026** ("Catching Culture Currents"). | V / T |
| 12 | **Camping series** | SamsonXVI | 2018-2019 | Linear story (Camping 1-3, prequels Hotel and Mansion) | **950M+ total place visits (2026)** | [gap] | Credited with **starting the "story game" trend of 2018-19** | V |
| 13 | **Field Trip Z** | Splitting Point Studios | 2020 [B] | Zombie outbreak at a school, **16 endings** (the most of any story game) | Once passed Break In to reach #1. About 1.4K CCU now [T]. | [gap] | Endings drive replays and YouTube "all endings" videos | V / T |
| 14 | **Guesty** | NK Studio | 2020 | A Piggy-like, MM2-like chapter game (9 chapters) | About 100M visits | [gap] | A Piggy-wave derivative that did well but never broke out | V |
| 15 | **Weird Strict Dad** | (creator unverified) | 2023 [B] | Night survival in your bedroom with a possessed dad. Relatable premise taken from the dev's real dad. Inspired by *Residence Massacre* and *Jim's Computer*. | About 1.4K CCU now [T] | [gap] | The premise is the hook. Unofficial RP spin-offs, marked "officially dead" | V / T |
| 16 | **Scary Shawarma Kiosk: the ANOMALY [horror]** | **kharbor_ykt** (Boris Kharanutov, Russia), solo | Aug 24-25, 2025 | Night-shift job (11 PM-7 AM). Serve customers, follow the rules, spot disguised **anomalies**. Multiple endings. | **1,296,043,629 visits (about 13 months).** Peak **35.7K (May 2, 2026)** per one tracker; a YouTube title claims "100K players??" [U]. About 12.6K live at one snapshot [T]. | [gap] | The breakout "anomaly" micro-horror. Clones followed: *Road-Side Shawarma [HORROR]* and **iOS App Store clones**. It even has an IMDb entry. | V / U |
| 17 | **Scary Sushi** | Evil Twin Games. About 5 credited: h0wlin_wolf (code, design, build), dinobytz, CocoMendos, xJennyBeanx, mastermime. | Feb 20, 2024 | Job-interview horror: gather ingredients while monsters roam the back rooms. **[CHAPTER 2]** in the title. | **116.6M+ visits** | [gap] | Small team, chapter sequel. Copycat *Road-Side Sushi [HORROR]*. | V |
| 18 | **Dead Rails** | RCM Games (RiccoMiller) | Early 2025 | Journey survival: 80 km by train across a zombie-filled Wild West. Inspired by *A Dusty Trip*. | **6.58B visits.** Average session **16.82 min**. More than half of its first 232M visits came in one week. | [gap] | **Roblox's official TikTok** featured it in Feb 2025 (499K likes), then it hit the front page. The destination gives the story its shape. | V |
| 19 | **Grace** | The Fartering Few (lead dev "Simon") | Created Sep 3, 2024 | Doors-like speed-run horror (time-limited rooms) | [gap] | [gap] | **Discontinued Apr 1, 2026** after a controversy centred on the lead developer, followed by doxxing and harassment (as reported). | V |
| 20 | **Short Horror Games / Short CREEPY stories** | Anthology hubs | 2022 / 2024 | **10-20 minute stories** added regularly (for example "Night Shift on Route 90", "Don't Knock Twice", "Homecoming") | [gap] | [gap] | The anthology model: one discovery page, many episodes | V |

**Games you named that I could only cover from background knowledge [B], with no fresh metrics:**
- **Evade** and **Nico's Nextbots** (2022): meme-driven nextbot chase games with little or no story. They show that a meme plus a chase loop can beat story at scale for a short time.
- **A Dusty Trip** (2024): the road-trip survival game that inspired Dead Rails [V: the inspiration link].
- **Cheese Escape** (2022): a kid-friendly maze horror.
- **Bakon** (2021): a Piggy-wave chapter clone.
- **Isle**: survival mystery with lore and multiple endings, known for long dev cycles.
- **Deepwoken**: a lore-heavy hardcore RPG whose lore comes through item text and NPCs, and lives in community wikis.
- **Blox Fruits**: only a thin quest story; its draw is anime fantasy fulfillment.
- **Pillar Chase 2**: an asymmetric-horror forerunner of Forsaken.
- **Specter**: Phasmophobia-style co-op ghost investigation where the stories emerge from play.
- **Innovation Inc** facilities: older sci-fi facility games with "meltdown" events and lore.
- **The Normal Elevator**: the ancestor of Regretevator.
- **Residence Massacre**: home-invasion night survival.
- **Dead Silence**, **"Need More Heat/Cold"**, **"Eeveelution"**: not verified. I could not confirm they are narrative games.

---

## 3. Game-by-game notes: why each worked or failed

### 3.1 DOORS (LSPLASH): the gold standard for story delivered through systems
- **Origins [V]:** Development began in late 2020 and the game released Aug 10, 2022. Inspirations were *Spooky's Jump Scare Mansion* and nicorocks5555's Roblox game *Rooms*. The core team is about 5 people with about 50 QA testers, and Lightning_Splash "doesn't plan on extending the development team." LSPLASH previously made ragdoll games and VOCAB HAVOC. **Lesson: a small, stable, veteran team with a large volunteer QA group.**
- **Update model [V]:**
  - Hotel+ (Jan 28, 2023) added entities, items, and the first sub-floor, *The Rooms*.
  - Floor 2, *The Mines*, followed [B: 2024].
  - *The Archives Update* (Aug 28, 2026) produced the highest peak RoVitals has recorded: **226,937 CCU**.
  - Big "floor-scale" updates re-ignite a procedural game the same way a new chapter does, but nothing gets "used up."
- **Why it works (analysis):**
  1. **Each entity is a readable rule with a telegraph.** Examples: lights flicker and you hide; an eye appears and you look away; "turn around" means reverse. Each is a tiny story with its own counterplay. Kids learn them from friends and YouTube, and they are fun to explain, which is word-of-mouth fuel.
  2. **Procedural rooms mean infinite replays.** Hand-authored set pieces (the library puzzle, the Seek chase, the final door) give the run a story arc.
  3. **Death messages that teach** (the "Guiding Light" [B]) turn failure into lore and a tutorial.
  4. **Co-op** turns horror into a shared social story ("you left me!").
  5. **Monetization sits at failure points:** revives are Robux-only [V], and knobs are earned per run or bought [V].
  6. **Ownership of lore:** a self-hosted official wiki (doorsgame.wiki) [V].
- **Economics [T]:** RoVitals models about $119K per 30 days at the current (post-spike) level, with a range of $1.3K-$11.9K per day. Implied yield: about 31M earned Robux on 145M visits, or **about 0.22 earned Robux per visit** [EST]. This is a useful but weak anchor. See §5.4.

### 3.2 Pressure (Urbanshade): great craft, catastrophic people risk
- **Craft [V/B]:** Released Jul 7, 2024 after a Feb 2024 beta. It follows the Doors formula in a deep-sea setting with documents, terminals, and a **professionally voiced, charismatic shopkeeper (Sebastian Solace)** who became a fandom icon [B].
- **Commercial value [V]:** 453M-489M visits and 1.6M favorites. In the Dec 2024 drama, Zeal reportedly received an **eight-figure Robux offer** to sell the game.
- **Collapse [V]:**
  - Apr 2026 (about Apr 8-9): a former contributor publicly made serious misconduct allegations against the lead developer. These are reported allegations, not findings.
  - Voice actor **Gianni Matragrano quit publicly**. Character designer **Zerum** (creator of Sebastian) left, along with other contributors.
  - **May 7, 2026: the game disappeared. May 8: it was reinstated as 18+ only.** The likely cause was an outdated or inaccurate maturity questionnaire. Under-18 players who had paid were locked out.
- **Lessons:**
  - Key-person risk and conduct risk are existential. Contributors own "pieces" of the IP, like a voice and character designs.
  - Your maturity questionnaire is a live compliance document. A wrong rating can shut you out of your core audience overnight.

### 3.3 The Mimic (MUCDICH / CTStudio): cinematic chapters, slow cadence
- **[V]:** Started Jan 15, 2021 by a solo dev, who built a team around Jun 2021. Japanese urban-legend horror in "books," each with a "Beast" antagonist. Known for high visual fidelity and set-piece horror [B].
- **Cadence problems [V]:** Before Book 2 Ch 3 the dev posted "Sorry for the long delay" (Jan 2024). The final chapter of *Jealousy* shipped May 30, 2025. Sources don't agree on the chapter and book structure [U]. That confusion is itself a sign of drawn-out, irregular releases.
- **Regional risk [V]:** Banned on **Roblox VNG (Vietnam)** in Jul 2026 for extreme horror themes.
- **Lesson:** Cinematic chapter horror builds a devoted fandom. But each chapter is expensive and slow, and the audience drifts away between releases. It also carries regional and maturity exposure.

### 3.4 Piggy (MiniToon): the episodic-chapter supernova
- **Rise [V]:** Originally "created as a joke and a way to test AI pathfinding." It reached 1B visits in 83 days, the 3rd-fastest ever. Peak **about 510K CCU** came after Book 1 Ch 12, when it passed Adopt Me!. Book 2 launched on schedule on Sep 12, 2020, with 500K+ players.
- **Decline [V]:**
  - "After Book 2 came out, the number of users suddenly dropped by more than half."
  - A fan news account reported "less than 100,000 concurrent players… at the peak" around Oct 10, 2020 [U].
  - The main story ended in Nov 2021. In **Nov 2022 it was confirmed there would be no more major updates.**
  - The analysis video *How Piggy Lost 97% of its Players* (Sep 25, 2025) lists: the end of episodic content; convoluted lore that alienated young players; a repetitive loop once puzzles were solved; less frequent seasonal updates replacing chapters; and a toxic fandom, including death threats aimed at the creators.
- **Franchise value [V]:** Novels, merchandise, and games outside Roblox. The DevForum profiled "MiniToon Inc" as a Level Up Spotlight. **Lesson: episodic Roblox horror can become an off-platform IP.**
- **Lessons:**
  1. Chapters create enormous spikes, but each chapter is consumed in days.
  2. A procedural or user-generated layer (Build Mode [B]) extends life.
  3. Lore must stay readable for 8-12-year-olds.
  4. Plan the story's ending like a product transition, not a finale.

### 3.5 Rainbow Friends (Roy & Charcle): mascot horror and the chapter-gap problem
- **[V]:** 5B+ visits. Chapter 2 arrived Jun 2, 2023 at "Odd World" amusement park.
- **[B]:** Chapter 1 launched around Aug-Sep 2022 and spread through YouTube. The roughly 10-month gap let fan-made "Chapter 2" games fill search results. A listing called *Rainbow Friends CHAPTER 2 TWO v2! fanmade* exists [V].
- **Lesson:** Between chapters, the vacuum gets filled by clones. Ship smaller chapters more often, or keep a replayable mode alive in the meantime.

### 3.6 Dandy's World (BlushCrunch): characters are the product
- **[V]:** Public alpha Jun 14, 2024. Visits went 1B (Dec 2024), 2B (Feb 2025), 5B (Nov 2025), 6B+ (Feb 27, 2026), with typically 96K+ CCU. Co-op players take an elevator down through floors, extract "Ichor" through quick-time events, and are hunted by "Twisted" versions of the playable "Toons."
- **Why it works (analysis):** Each Toon is a **collectible character with a personality** that is also a gameplay kit. Characters drive fan art and animation, and they drive purchases. Floors are procedural or random, so it replays well.
- **Risks [V]:** Co-lead Rox was fired Oct 7, 2024, and his revenue share ended. Artists alleged their designs were used without credit or payment. The studio's responses were seen as defensive. There was spill-over conflict with the Databrawl fandom. **Still in alpha after about 2 years** [V].
- **Lesson:** Character-driven IP can be monetized very well, but **credit and contract hygiene for designers** is essential.

### 3.7 FORSAKEN: Roblox's own folklore as IP
- **[V]:** Created Jul 27, 2024 and launched Dec 25, 2024. 4.0-4.6B visits and about 80K average CCU. Won the Innovation Award for Best Survival Experience in 2025. Asymmetric, Dead by Daylight-style. **Killers and survivors come from Roblox myths** (1x1x1x1, John Doe, Guest 666, Shedletsky). Peak is disputed: 577,191 vs "1.2M" [U].
- **Why it works (analysis):**
  - Instant recognition and nostalgia.
  - Built-in lore mysteries, since the community already tells these legends.
  - A roster model where each character is lore plus a kit plus a skin.
  - Round-based replay.
  - Fan-animation virality [B].
- **Lesson:** "Platform-native folklore" works as a free, pre-loved IP. For a new studio, the equivalent is inventing folklore designed to spread.

### 3.8 Regretevator and Apeirophobia
- **Regretevator [V/U]:** The Axolotl Sun, led by yeuc_c, since 2020, with 200M+ visits. Random floors, each a short vignette (task, hazard or joke). Horror-comedy with a social hangout. **Format lesson:** an "elevator of vignettes" is really a native anthology engine. New floors are cheap, bite-sized content and fit AI-assisted production well.
- **Apeirophobia [V]:** 436M visits since Jul 2022, riding the Backrooms trend. Ownership passed from Monochrome to Polaroid after "controversy." In Dec 2025 a new owner seized the game and the original developers left to build *Elsewhere*. **Lesson:** Who owns the Roblox group and place is an existential business question.

### 3.9 Break In to 99 Nights: the story-game developer who went supernova
- **Break In 2 [V]:** 100M visits in 12 days. Four endings (good, secret, evil, origin). "All endings / all badges" YouTube videos appear on cue.
- **99 Nights in the Forest [V]:**
  - Made by the same core developer (Cracky4), now a three-person New Zealand team.
  - Its story is simple and emotionally legible: **four missing kids, a monstrous deer, cultists, survive 99 nights.** It was inspired by the 2023 Caquetá crash.
  - Reached 1.02M CCU by about Jul 18, 2025 and **14.2M at peak**. About 26B visits by Apr 2026 (29.77B later on Rolimons). About 339K CCU in Jul 2026 [T]; even the biggest hit decays about 97% from its peak.
  - **Film deal with 20th Century Studios (Apr 13, 2026).**
  - GDC 2026 talk on "riding resonant trends": TikTok, fandoms, memes.
- **Lesson for Phoenix Feather:** The best "story-first" move on Roblox in 2025 was not a longer story. It was a **story premise fused with a replayable systemic loop**, with the stakes in the title ("99 Nights"). Story sets the goal, the emotional stakes, and the brand. Systems deliver the hours.

### 3.10 The classic story-game genre (Camping → Field Trip Z → Weird Strict Dad)
- **Camping [V]:** SamsonXVI started the trend in 2018-19 and built a series (3 mainline games plus 2 prequels) with 950M+ visits. He makes cameos in other story games, a sign of how much the genre is built on references.
- **Field Trip Z [V]:** 16 endings, the most of any story game. It once beat Break In for #1.
- **Guesty [V]:** A Piggy-inspired chapter game with about 100M visits.
- **Weird Strict Dad [V]:** Its premise comes from the dev's real strict dad. It draws on *Residence Massacre* and *Jim's Computer*.
- **Naming signals [V]:** Titles carry tags such as "(Story)", "[STORY]", "[CHAPTER 2]" and "[HORROR]". Examples: *Break In 2 (Story)*, *The Guest (STORY)*, *Scary Sushi [CHAPTER 2]*, *Road-Side Sushi [HORROR]*.
- **Saturation signal [V]:** A 2025 DevForum thread is titled *"What do games like Break In, Scary Sushi, Field Trip Z, Faithless, and The Kidnapper have that my game doesn't?"*. Many indie story games fail, and developers can't tell why. I could not retrieve the replies.

### 3.11 Scary Shawarma Kiosk: the "anomaly shift" breakout
- **[V]:** Solo developer kharbor_ykt (Boris Kharanutov, Russia). Launched Aug 24-25, 2025 and reached about 1.3B visits in about 13 months (about 3.3M visits per day on average [EST]). The player works the night shift at "Shawarma 24," keeps the grill hot, serves every order, and follows the rules. Some customers are disguised anomalies, and serving them causes errors, failed inspections, or death.
- **Why it works (analysis):**
  1. A mundane, funny, specific setting plus one clear horror rule.
  2. A **readable skill test**: spot what's wrong, which YouTube audiences love.
  3. A cooking and serving routine (a "Papa's"-style loop [B]) that is satisfying even without the scares.
  4. Night-by-night pacing with escalating anomalies.
  5. Multiple endings.
  6. Very cheap to extend: new anomalies are mostly data.
  7. It borrows the "rules horror" and "doppelganger check" trends from indie PC games such as *The Exit 8*, *I'm on Observation Duty* and *That's Not My Neighbor* [B].
- **Clones [V]:** *Road-Side Shawarma [HORROR]* on Roblox, plus at least two iOS apps imitating it.

### 3.12 Grace: a discontinued hit
- **[V]:** A Doors-like speed-run horror created Sep 3, 2024. **Discontinued Apr 1, 2026** after a lead-developer scandal and the doxxing and harassment that followed. There is no metric data [gap].

### 3.13 Dead Rails and A Dusty Trip: "journey" narrative
- **[V]:** Dead Rails asks you to cover 80 km by train through the zombie West. It was inspired by *A Dusty Trip*. Average session is 16.82 min and it has 6.58B visits. Its launch was boosted by **Roblox's official TikTok (Feb 2025)**.
- **Analysis:** A destination is the simplest story structure there is. You get a beginning (depart), a middle (procedural events), an end (arrival and boss [B]), and endless replays. It works well as a framework for story set pieces along the route.

---

## 4. Why the hits hit: cross-cutting factors

| Factor | Evidence | Weight (analysis) |
|---|---|---|
| **Replay engine** (procedural rooms or floors, runs, rounds, endings) | Doors, Pressure, Dandy's World, Regretevator, Dead Rails, Forsaken. Linear games spike and fade (Break In 2, Piggy after Book 2). | ★★★★★. The single biggest predictor of lasting CCU |
| **Co-op or social horror** (friends as the audience) | Nearly every hit. Roblox docs: users "treat Roblox as a place to hang out with their friends" [DOC]. | ★★★★★ |
| **Premise legible in title and thumbnail** (a logline title) | *99 Nights in the Forest*, *Scary Shawarma Kiosk*, *Weird Strict Dad*, *Break In*, *Dead Rails* | ★★★★ (CTR) |
| **Rules you can learn** (entities or anomalies as mechanics) | Doors entities, anomaly rules, Weird Strict Dad's "don't get caught" | ★★★★ (teachability and word of mouth) |
| **Characters as fandom anchors** | Sebastian Solace (Pressure), Toons (Dandy's), Forsaken roster, Piggy skins, the Rainbow Friends | ★★★★ (fan art, merch, monetization) |
| **Lore mystery** (drip-fed and theory-friendly) | Doors floors, The Mimic, Piggy (until it became too convoluted) | ★★★ (retention among older fans; risky for young ones) |
| **YouTube and TikTok amplification** | Dead Rails via Roblox's TikTok. "All endings" videos. Doors, Piggy and Rainbow Friends on YouTube [B]. GDC 2026 talk on culture currents. | ★★★★★ for the launch spike |
| **Multiple endings plus badges** | Field Trip Z (16), Break In 2 (4), Scary Shawarma endings | ★★★ (replays, completionists, video content) |
| **Big update "events"** (floors, chapters, April Fools modes) | Doors Archives (Aug 2026: the largest peak RoVitals recorded), Hotel+, Piggy chapters | ★★★★ |
| **Riding a trend** (Backrooms, nextbots, anomaly/rules horror, mascot horror) | Apeirophobia (Backrooms), Evade/Nico's (nextbots) [B], Scary Shawarma (anomaly), Dandy's/Rainbow Friends (mascot horror) | ★★★★ for launch, ★ for longevity |

**Pattern:** Launch virality comes from the **premise, trend and YouTube-friendly moments**. Longevity comes from **replay engines, a social loop, and a cadence of big updates**. The story games that died had the first and not the second.

---

## 5. The "scary story" / micro-horror genre: formula, makers, economics, AI fit

### 5.1 Two eras of the formula
**Era 1: "Story games" (2018-2023).** Camping, Break In, Field Trip Z, Guesty, the Airplane/Daycare-type series [B].
- Lobby → party queue (bus, van or elevator) → teleport to a story server → a **linear 10-30 minute** sequence.
- Scripted NPC text dialogue, fetch and hide tasks, a **boss fight or chase**, and roles such as medic, fighter or hacker (Break In [B]).
- **2-16 endings**, each with a badge. Sequels and prequels expand the series.

**Era 2: "Micro-horror / anomaly / job-shift" games (2024-2026).** Scary Sushi, Scary Shawarma Kiosk, Weird Strict Dad, anthology hubs.
- A **mundane job or place plus one horror rule**: serve customers but reject anomalies; stay in bed so dad doesn't catch you; interview at a sushi bar while monsters roam.
- A **5-20 minute session**, split into nights or shifts with escalating difficulty.
- A **rules card or checklist** mechanic, simple verbs (serve, check, hide, run), and **2-6 endings plus a secret one**.
- Chapter sequels marked in the title ("[CHAPTER 2]").
- Built by **1-5 people** [V: solo for Scary Shawarma; about 5 credited for Scary Sushi].

### 5.2 Who makes them [V]
- **Solo developers.** kharbor_ykt (Scary Shawarma). Cracky4 early on (Break In). SamsonXVI (Camping). MUCDICH at the start of The Mimic.
- **Micro-teams of 3-5.** Evil Twin Games (Scary Sushi). LSPLASH (about 5, though Doors is not micro-horror). Grandma's Favourite Games (3 founders).
- **Roblox anthology hubs** that keep adding short stories.
- *[Gap]* I found **no verified data on how long these take to build**. [B]: DevForum and YouTube devlogs generally describe small story or horror games being built in weeks to a few months with Creator Store assets. Treat that as unverified.

### 5.3 The formula card (synthesis)

| Element | Proven pattern | Examples |
|---|---|---|
| Hook | "[Mundane place or person] + [one wrong thing]"; a title that works as a logline | Scary Shawarma Kiosk, Weird Strict Dad, Break In |
| Session | 5-20 minutes, finishable on a phone, fits one video | Anthology hubs: 10-20 min [V] |
| Structure | Nights, shifts or chapters with escalation, then a climax chase, then an ending | Scary Shawarma nights; Break In |
| Core verb | Serve, check, hide or flee, with **visual tells** | Anomaly detection |
| Social | 1-8 player co-op; friends die in funny ways | All the major hits |
| Replay | Multiple endings and badges, randomized anomalies, secret routes | Field Trip Z (16 endings) |
| Sequel | "[CHAPTER 2]" relaunch, or a new location in the same universe | Scary Sushi Ch 2, Rainbow Friends Ch 2 |
| Monetization | Revive, skip, roles and tools, cosmetics, private servers | §6 |
| Marketing | Monster-face thumbnail; TikTok jump-scare clips; "all endings" YouTube guides | Break In 2 all-endings videos [V] |

### 5.4 Economics: what do they earn? (illustrative only)
There is **no verified revenue data** for any micro-horror game [gap]. As an anchor, RoVitals' model for Doors implies **about 0.22 earned Robux per visit** [T/EST]. DevEx pays **$0.0038 per Robux** [DOC] (it was $0.0035 before Sep 5, 2025).

| Visits | At 0.05 R$/visit | At 0.22 R$/visit (Doors-model anchor) | At 0.5 R$/visit |
|---|---|---|---|
| 10M | $1.9K | $8.4K | $19K |
| 100M (Break In 2's first 12 days; Scary Sushi lifetime) | $19K | $84K | $190K |
| 1.3B (Scary Shawarma lifetime) | $247K | $1.09M | $2.47M |

[EST] These are illustrations, not estimates of any specific game. Real yields vary widely with monetization design, audience age (under-13s spend less and see no ads [B]), and region. Creator Rewards payouts (the Jul 24, 2025 replacement for Premium Payouts [DOC]) add to this, but I could not retrieve their formula.

**Takeaway:** A single micro-horror hit can plausibly earn from the low six figures to the low seven figures (USD). The median game earns close to nothing (the DevForum saturation thread). **This is a portfolio business.**

### 5.5 Why this genre suits AI-assisted development (and where it doesn't)

| Component | AI-agent leverage | Notes |
|---|---|---|
| Game-state logic (nights, shifts, rules checks, endings, badge awards, DataStores) | **High** | Well-bounded Luau state machines |
| Content variation (anomaly catalogs, rule sets, customer orders, room generators) | **High** | Data-driven. Agents can generate and balance hundreds of variants |
| UI (dialogue boxes, rules card, shop, ending screens, mobile controls) | High for function, medium for polish | Roblox docs: keep UI "as visual as you can" [DOC] |
| Cutscenes (camera tweens, letterboxing, skip, subtitles) | Medium-high | Timing and "feel" need human review |
| Writing (dialogue, notes, lore docs) plus **localization** | High for drafts | A human editor owns tone and voice. Keep lines short. |
| Voice | Medium | `AudioTextToSpeech`: 300 characters per request, speed 0.5-2×, pitch ±12 semitones, rate limit 1 + 6×CCU per minute [DOC]. Good for radio, PA and NPC barks. |
| Live NPC conversation | Experimental | `TextGenerator`: system prompt, context tokens, JSON-schema output, starts at 100 requests/min and scales with CCU [DOC] |
| 3D monsters and environments | Low-medium | Creator Store assets (the built-in Studio MCP has `search_asset` and `insert_asset` [DOC]); human art direction for the "thumbnail monster" |
| Animation and audio scares | Low-medium | Scare timing, stingers and silence are craft |
| QA automation | Medium | Built-in Studio MCP: `start_stop_play`, `execute_luau`, `get_console_output`, `screen_capture`, input simulation, and a `playtest` subagent [DOC]. Fear and fun still need playtests with the target age group. |
| Community, wiki, Discord, lore drops | Medium | Agents can draft; a human presence is required |

**Tooling fact [DOC]:** Roblox's standalone `studio-rust-mcp-server` (supporting Claude Desktop and Cursor) was **archived Apr 3, 2026 in favor of a built-in MCP server inside Roblox Studio.** That is the intended path for Claude Opus 5.5 or GPT-6 agents to drive Studio.

**Strategic caveat:** If AI makes micro-horror cheap for you, it does for everyone. Clones of Scary Shawarma appeared on and off Roblox within months [V]. Speed alone will not be a moat. **IP (characters and a world), a story people talk about, and a reliable cadence** can be.

---

## 6. Monetization patterns in narrative games (what works without killing the story)

### 6.1 Observed in the hits
| Mechanism | Where | Story-safe? | Notes |
|---|---|---|---|
| **Revives** (Robux only) | Doors [V]; common in story games [B] | ✔ when capped | Sells at the moment of highest investment (just died, near the end). Cap per run. Offer an earned alternative. |
| **Soft currency plus a pre-run shop** | Doors Knobs, earned per run or bought [V] | ✔ | Converts time into power and lets payers skip the grind |
| **Roles, classes, playable characters** | Break In roles [B]; 99 Nights classes [B]; Dandy's Toons [B]; Forsaken roster [B] | ✔✔ | Characters are lore plus a kit plus a purchase. The strongest fit for a story-first studio. |
| **Cosmetics and skins** | Piggy [B], Forsaken [B] | ✔✔ | Make them diegetic (uniforms, kiosk decor, flashlights) |
| **Private servers** | Common [B] | ✔ | For friend groups and YouTubers. Roblox Plus pays creators up to 100 Robux per month when Plus subscribers spend 60+ min in paid private servers they created [DOC]. |
| **Skip chapter / skip night** | Obby and story staples [B] | ~ | Fine for players replaying to hunt badges. Don't let first-timers skip the climax. |
| **Merch, books, film** | Piggy novels and merch [V]; 99 Nights film [V] | ✔✔ | Story IP pays off beyond Robux. The biggest argument for a story-first studio. |

### 6.2 Platform levers and rules (primary source, Roblox creator-docs, fetched 2026-09-29) [DOC]
- **DevEx:** $0.0038 per Robux since Sep 5, 2025 (was $0.0035). Minimum cash-out is 30,000 Robux ($114).
- **U.S. 18+ DevEx rate:** **$0.0054** for qualifying Robux earned from U.S. players aged 18+ (developer products, passes, subscriptions, private servers). **Effective June 8, 2026.** The game must use R15 or custom human or non-human rigs "100% of active playtime," with **no R6**. This rewards adult-skewing horror, but the audience is small.
- **Paid access in Robux:** 25-1,000 Robux. No refunds. Not available on Xbox. **Cannot be combined with private servers.** Roblox warns it "can limit the number of users who join."
- **Paid access in local currency:**

  | Price | Creator share |
  |---|---|
  | $9.99 | 50% |
  | $29.99 | 60% |
  | $49.99 | 70% |

  Purchase is on **desktop or web only**. 48-hour refund window. 60-day escrow. Not purchasable in Argentina, China, Colombia, India, Indonesia, Russia, Taiwan, Turkey, UAE, Ukraine or Vietnam. This makes a premium narrative release possible for an older audience, at the cost of discovery.
- **Subscriptions:**
  - Robux subscriptions: minimum 49 Robux; the creator gets 70%.
  - **Local currency** ($2.99-$14.99): the creator gets **70% in month 1, then 100%** afterwards.
  - Benefits must be the same on every platform, can't be revoked, and can't be gated behind extra requirements.

  A good fit for a "Story Club," such as early access to new episodes or monthly cosmetics.
- **Roblox Plus** (a new subscription):
  - Plus members get 10%, then 20%, discounts, **subsidized by Roblox** so the creator's revenue per sale is unchanged.
  - A **sign-up bonus of 250 Robux per month for 3 months** (750 total) for subscriptions prompted in-game.
  - 10% commission on in-game Robux transfers.
- **Rewarded video ads:**
  - Game requirements: public and **unrestricted**, **≥2,000 unique monthly visitors**, approved maturity questionnaire.
  - Publisher requirements: 13+, 2FA, ID-verified.
  - The reward must be a developer product, **suggested value 3-10 Robux**, **not randomized**.
  - Ads **must not be a progress gate** and belong at natural breaks, such as between nights.
  - Paid per impression (EPM).
- **Engagement-based payouts** ended **Jul 24, 2025**, replaced by **Creator Rewards** (formula not in the doc I fetched [gap]).

### 6.3 Guidelines that follow from this (analysis)
1. **Never sell the ending, and never interrupt a story beat with a purchase prompt.** Prompt at failure (revive), at preparation (pre-run shop), or at identity (character or cosmetic).
2. **Sell characters and roles that change how the story plays** (Break In's roles, Dandy's Toons). This monetizes the fiction.
3. **Put optional rewarded ads between nights or shifts** for a free revive token. That is compliant and reaches the ad-eligible 13+ audience [DOC].
4. **Use a subscription for cadence**: a monthly cosmetic plus early access to the next episode. Local-currency subscriptions pay 100% after month 1.
5. **Plan for IP licensing.** Piggy (books, merch) and 99 Nights (film) show that story games can build brands. Keep contracts clean so you own the IP (§7).

---

## 7. Failure patterns (with evidence)

| # | Failure mode | Evidence | Mitigation |
|---|---|---|---|
| F1 | **Content consumed too fast** (linear, one session) | Break In 2: 100M visits in 12 days [V], then a decline [B]. Piggy after Book 2 fell by more than half [V]. Even 99 Nights went from 14.2M to about 339K [T]. | Add a replay layer (procedural, endings, roles, UGC). Plan the next release before launch. |
| F2 | **Long chapter gaps and cliffhanger fatigue** | The Mimic's delay apologies [V]. Rainbow Friends' roughly 10-month gap [B]. Dandy's World still in alpha after about 2 years [V]. | Smaller, more frequent drops. Roblox recommends updates **every 2 weeks to a month, each taking under 3 weeks of effort** [DOC]. |
| F3 | **Clone flooding** | Rainbow Friends fan-made Ch 2 [V]. Road-Side Shawarma and Road-Side Sushi [V]. iOS App Store clones [V]. Piggy-likes such as Guesty (inspired by Piggy [V]) and Bakon [B]. | Speed to sequel. A distinctive character IP. Official channels (wiki, Discord). |
| F4 | **Lore too convoluted for the audience** | Piggy's "increasingly complex and convoluted storyline alienated… the younger audience" [V] | Two-layer lore: a simple surface story plus optional deep lore for theory fans |
| F5 | **Team, ownership and credit disputes** | Apeirophobia ownership seizures [V]. Dandy's World: Rox fired, artist credit allegations [V]. | Written contributor agreements, IP assignment, credits, revenue-share terms, and group ownership held by a company account |
| F6 | **Creator conduct scandals** | Grace discontinued Apr 1, 2026 [V]. Pressure contributors quit and the game was pulled or restricted, May 2026 [V]. | Code of conduct, safeguarding for minors on the team and in the community, professional distance from young fans, and contingency plans for key people |
| F7 | **Maturity and regional compliance** | Pressure relisted as 18+ only [V]. The Mimic banned on Roblox VNG [V]. Restricted-rated games unplayable in Korea, Saudi Arabia and Türkiye; a missing questionnaire restricts play for everyone [DOC]. | Answer the questionnaire accurately and re-review it after every update. Design for **Mild or Moderate** fear to maximize reach. |
| F8 | **Toxic fandom and harassment** | Piggy death threats [V]. Grace doxxing [V]. | Moderated community spaces. Don't reward drama. Set clear rules. |
| F9 | **Genre saturation** | DevForum: "What do games like Break In, Scary Sushi, Field Trip Z… have that my game doesn't?" [V] | Differentiate on premise, character and quality. Test thumbnails and titles with ads before investing. |
| F10 | **Loop too shallow once puzzles are solved** | Piggy [V] | Randomize puzzle solutions and item spawns. Add modes (hard mode, modifiers). |

---

## 8. Craft: delivering story to a young, mobile-heavy, often muted, short-attention audience

**Audience facts [DOC]:**
- "The majority of Roblox users play on a mobile device."
- "Many younger users struggle to read text-heavy interfaces"; keep "everything as visual as you can."
- Players are "Tourists" (hop between games, prefer variety) or "Locals" (engaged; they "form almost all a game's engaged user base").
- First-time experiences must "get users into the fun quickly."
- Roblox now has more users aged 13+ than under 13.
- A typical session means playing "a handful of different games."

**Techniques (✔ = seen in the cited hits; [B] = general practice):**

1. **Story as rules (the core technique).**
   - Every threat has a **visual tell plus a single counter-rule**: Doors entities, anomaly checklists.
   - Rules are easy to learn, easy to translate, and easy to retell ("if the lights flicker, HIDE"). The retelling is the story.
   - ✔ Doors, Scary Shawarma.
2. **Design for no audio.**
   - Every audio cue gets a visual twin: flicker, screen shake, UI pulse, subtitles.
   - Audio then becomes a bonus layer of fear, not a requirement [B].
3. **Death as narration.**
   - After a death, a short hint or lore line ("It hunts by sound…"). This teaches, adds lore, and softens frustration.
   - ✔ Doors' death-hint system [B: "Guiding Light"].
4. **Micro-dialogue.**
   - About 8-15 words per bubble. Portraits and emotes over paragraphs. Tap to advance, hold to skip.
   - Auto-translate-friendly phrasing [B]. Supported by [DOC] ("visual UI is easier to translate").
5. **Environmental storytelling.**
   - Notes, documents, terminals, posters, radio chatter, graffiti, and the arrangement of corpses and props.
   - Optional to read, so tourists skip them and locals and theorists hunt them.
   - ✔ Pressure documents [B]. Apeirophobia levels [V].
6. **The pre-show vehicle.**
   - An elevator, bus, van or train handles matchmaking, the loading screen, and story framing in one.
   - ✔ Doors elevator [B], Regretevator, Dandy's World, Dead Rails, A Dusty Trip, Camping-era buses [B].
7. **Short, skippable cutscenes.**
   - Scripted camera (tweens) with letterboxing, **3-10 s beats**, a skip option for replays, and subtitles always on [B].
   - Save longer cinematics for chapter climaxes. The Mimic proves they can land [B], but they cost cadence.
8. **A charismatic host or shopkeeper NPC.**
   - A recurring character who talks to players between runs and gives the fandom a face.
   - ✔ Sebastian Solace (Pressure), the Dandy's World cast, Doors' shop [B].
   - Voice it with pro VA or TTS barks [DOC TTS].
9. **Multiple endings plus badges plus hint boards.**
   - Endings are the replay engine of linear stories and drive "ALL ENDINGS" videos.
   - ✔ Field Trip Z (16), Break In 2 (4).
   - Show locked-ending silhouettes to invite completionists [B].
10. **Designed-in YouTuber moments.**
    - A reaction beat every 60-90 s: jump scare, betrayal, funny death, ragdoll.
    - A secret or easter egg per episode for "theory" videos.
    - Private servers for creators [B].
    - Roblox's own TikTok can amplify you (Dead Rails [V]).
11. **Co-op storytelling.**
    - Roles with distinct verbs so friends make different stories (Break In roles [B]).
    - Asymmetric play, where one friend is the monster (Piggy, Forsaken).
    - Revive-a-friend moments.
12. **Lore communities and ARGs.**
    - Official wikis: Doors (doorsgame.wiki) and Pressure (urbanshade.org) run their own [V].
    - Discord lore drops, hidden badges, update-log riddles [B].
    - Keep the surface story simple (Piggy's lesson, F4).
13. **Platform-native folklore.**
    - Build on memes the audience already knows (Forsaken's Roblox myths, nextbots, the Backrooms), or invent spreadable folklore of your own [V/B].
14. **Maturity-aware horror.**
    - Stay within Mild or Moderate fear (no realistic blood) so the game is playable by 5-15-year-olds [DOC].
    - Build tension from rules, uncertainty and chases rather than gore.

---

## 9. Recent (2025-2026) narrative hits and emerging formats

| When | Event | Significance | Conf. |
|---|---|---|---|
| Dec 25, 2024 → 2025 | **Forsaken** launches and reaches about 80K average CCU and 4B+ visits. Innovation Award 2025. | Asymmetric horror built on Roblox folklore | V |
| Feb 2025 | **Dead Rails** goes viral through Roblox's own TikTok | Journey narrative; platform-driven amplification | V |
| Mar-May 2025 → Jul 18, 2025 | **99 Nights in the Forest** created and launched, passing 1.02M CCU | A story premise fused with survival crafting | V |
| 2025 | 99 Nights peaks at 14.2M CCU (date unverified) and passes Grow a Garden in the Sep 2025 charts | Story-framed games can top the platform | V/U |
| Aug 24-25, 2025 | **Scary Shawarma Kiosk** launches and reaches about 1.3B visits by Sep 2026 | The anomaly/job-shift micro-horror boom (solo dev) | V |
| Nov 2025 → Feb 2026 | **Dandy's World** passes 5B, then 6B visits | Character-driven co-op horror at scale | V |
| Dec 2025 | Apeirophobia ownership seizure; original devs leave to make *Elsewhere* | Ownership risk | V |
| Mar 13, 2026 | GDC talk by Alec Kieft (with the Bee Swarm Simulator dev) on riding culture trends | Hit-making is trend-reading | V |
| Apr 1, 2026 | **Grace** discontinued | Conduct risk | V |
| Apr 3, 2026 | Standalone Roblox Studio MCP repo archived; **Studio has a built-in MCP server** | AI-agent development is officially supported | DOC |
| Apr 13, 2026 | **99 Nights film** at 20th Century Studios | Roblox narrative IP goes to Hollywood | V |
| Apr-May 2026 | **Pressure** allegations; game pulled, then 18+ only | Conduct plus compliance risk | V |
| Jun 8, 2026 | **U.S. 18+ DevEx rate ($0.0054)** takes effect | New incentive for adult-skewing games | DOC |
| Jul 2026 | **The Mimic banned on Roblox VNG** | Regional horror restrictions | V |
| Aug 28, 2026 | **Doors: The Archives Update**, 226,937 CCU (highest peak RoVitals has recorded) | Veteran procedural horror can still spike | T |

**Emerging formats (analysis):**
1. **Anomaly and rules horror** in mundane jobs (kiosks, sushi bars, night shifts, airports; the DevForum has "realistic airport for a horror game" threads [V]).
2. **Anthology hubs** of 10-20 minute stories [V].
3. **Survival crafting with a narrative goal** (99 Nights).
4. **Journey and destination** runs (Dead Rails, A Dusty Trip).
5. **Asymmetric horror with roster lore** (Forsaken).
6. **Character-collector co-op horror** (Dandy's World).
7. **LLM-driven NPCs** are now possible natively through `TextGenerator` [DOC], but I found no verified hit using them [gap].

---

## 10. Opportunities for a story-first studio using AI agents

The motto "interesting stories via interesting gameplay" is exactly what Roblox rewards. The winners tell story **through rules, roles, characters and goals**. The recommendations below go from lowest risk and fastest learning to the biggest bets.

### Rec 1: Build a portfolio of "anomaly shift" micro-horror games, each a short series (start now)
- **Format:** A mundane job with one uncanny rule, played over 5-7 in-game nights (10-15 minutes per run).
  - Each night adds anomalies and a slice of a mystery (radio logs, notes, a regular customer who changes).
  - 3-6 endings plus a secret ending. Solo play or 2-4 player co-op, where one person checks and another serves.
- **Why:** Scary Shawarma Kiosk shows a solo developer can reach about 1.3B visits in 13 months [V]. The format is mostly **logic plus data plus UI**, which is where agents excel (§5.5). It also expresses your motto directly: the story lives in what you notice while doing the job.
- **Story-first twist:** Give each game a named, lovable or uncanny **character** (the manager, the regular, the thing in the freezer). Design them as future IP rather than a generic monster.
- **Scope with agents [EST]:** 2-4 weeks per title for a vertical slice with 2-3 people plus agents. Launch, measure, and make a "[CHAPTER 2]" or new location within 2-4 weeks if the numbers justify it.
- **Monetization:** Revive (capped), skip night for completionists, diegetic cosmetics (uniforms, kiosk skins), private servers, and an optional rewarded ad between nights for a free revive token [DOC rules].
- **Guardrails:** Rate for Mild or Moderate fear. Keep text minimal. Give every audio cue a visual twin. Make an original monster the thumbnail face.

### Rec 2: An episodic anthology hub (one universe, many 10-15 minute stories) (the studio's flagship)
- **Format:** One experience, like a "haunted bus line" or a "late-night radio show." The host vehicle or character is the pre-show and selects an episode.
  - **Ship a new episode every 2-4 weeks**, matching Roblox's cadence guidance [DOC].
  - Shared meta-progression: episode badges, collectibles, host cosmetics.
  - A season-long **meta-mystery** tying the episodes together.
- **Why:** It fixes the genre's biggest failure (F1, F2): one discovery page gathers retention, and each episode is a cheap, testable story. It suits AI agents: an episode template, a data-driven script, and reusable systems. The Short Horror Games hubs prove the format exists [V]; a better-branded, character-hosted version is the opportunity.
- **Monetization:** A subscription "Night Pass" with early access to next week's episode plus a monthly cosmetic. Local currency gives 70%, then 100% [DOC]. Plus revives and cosmetics.
- **Data loop:** The top-performing episodes get spun out into standalone games or sequels. That turns the anthology into an R&D engine for IP.

### Rec 3: A procedural co-op "run" story with a host character (the Doors/Pressure/Dandy's lesson)
- **Format:** A run of 30-100 rooms or floors from a procedural room library.
  - Entities as rules. A charismatic shopkeeper or host who comments between runs.
  - Lore delivered through death hints and collectible documents.
  - Big "floor" updates every few months, with smaller cadence drops in between.
- **Why:** This is the most durable pattern (Doors: 7.79B visits, still spiking four years later [V/T]). Agents can generate room variants, entity behaviors and balance data. Humans own entity design, audio and scare timing.
- **When:** After one or two micro-horror launches have built your pipeline and taught you your audience (a 2-4 month build [EST]).

### Rec 4: A narrative goal fused with a systemic loop (the 99 Nights lesson) (a bigger bet, once you have traction)
- **Format:** Pick a loop that works on its own (survival, journey, management, extraction) and give it an **emotionally legible story goal in the title**. Examples: rescue someone, reach somewhere, survive N nights, find out what happened.
- **Why:** This beat every pure story game in 2025. The story does the marketing (logline title), provides motivation, and has franchise potential (a film deal [V]). Systems deliver the hours.

### Rec 5: An AI-native narrative experiment (small, controlled)
- **Format:** A "who's lying?" or "is this person an anomaly?" interrogation game where NPC answers come from `TextGenerator` [DOC].
  - Use JSON-schema outputs to keep answers inside designed truth tables.
  - Keep authored fallback lines. Add TTS barks (300-character chunks) [DOC].
- **Why:** You can do this and most competitors can't. It's also on-brand.
- **Risks:** Rate limits (starting at 100 requests/min, scaling with CCU), latency, moderation, and cost at scale. There is no proven hit yet [gap]. Keep it a feature inside Rec 1 or 2, not a standalone bet.

### Rec 6: (Optional, later) A premium older-audience narrative
- **Format:** Paid access in local currency ($9.99 at a 50% share) or in Robux (25-1,000 R$). Target a 16+ or 18+ audience. Could use the **U.S. 18+ DevEx rate of $0.0054** if you use R15-only rigs [DOC].
- **Caveat:** Discovery falls sharply with paid access, which is desktop/web purchase only in local currency. Restricted-rated games lose several countries [DOC]. Treat this as a brand or "director's cut" play, not a growth engine.

### Pipeline and operating recommendations
1. **Title is the logline; thumbnail is the monster.** A/B test titles and thumbnails with small Roblox ad spends before investing more ([B]; Ads Manager docs exist [DOC listing]).
2. **Build a reusable narrative toolkit once, with agents:**
   - Dialogue system (short bubbles, portraits, auto-translate-safe), cutscene sequencer (camera tweens, letterbox, skip)
   - Rules card, anomaly/entity framework, endings and badge manager
   - Night/shift director, revive/shop/private-server modules, analytics events

   Every new title then becomes mostly content.
3. **Agent workflow:** Drive Studio through the **built-in Studio MCP** [DOC]. Keep code in files and sync to Studio (for example with Rojo [B]). Use automated play-mode checks through the MCP playtest tools (and Jest Roblox unit tests) for regression checks. Hold human playtests with kids for fear and fun.
4. **Kill or continue on data within about 14 days of launch [B heuristic]:** Track thumbnail CTR, % of players reaching the first ending, average session, D1 and D7 retention, and the share of traffic from social or YouTube. Compare against your own portfolio baseline.
5. **IP and people hygiene from day 1** (F5, F6):
   - Written IP assignment and credit terms for every artist, composer and voice actor.
   - Company-owned Roblox groups.
   - A code of conduct and safeguarding policy for interacting with a young audience.

   Pressure, Grace, Dandy's World and Apeirophobia show this is not optional.
6. **Compliance as a checklist item every update:** Re-answer the maturity questionnaire when content changes [DOC]. Aim for Mild or Moderate fear.
7. **Community stack:** Discord, an official wiki you control (as Doors and Pressure do [V]), TikTok clips, and a creator-friendly private-server policy.
8. **Two-layer lore:** A surface story an 8-year-old can retell in one sentence, plus deep lore for theorists (avoid F4).

---

## 11. Gaps and unverified items (could not be filled under the access limits)

- **Revenue:** No verified revenue for any title. Only RoVitals' Doors model [T] and a dubious fan claim of about 64-65M Robux for Piggy [U].
- **Peaks:** Doors' true all-time peak before 2026. Pressure's and Grace's peaks. Scary Shawarma's true peak (35.7K vs "100K?"). Forsaken's peak (577K vs 1.2M). The date of 99 Nights' 14.2M peak.
- **The Mimic:** Visits, CCU, and a consistent book and chapter structure.
- **Build times and budgets** for micro-horror games. No postmortems retrieved: DevForum, Medium and YouTube were not accessible, and the DevForum saturation thread's replies were unreadable.
- **Monetization specifics:** Doors revive pricing and caps; Pressure, Dandy's World, Forsaken and 99 Nights product mixes (a RoMonitor page exists but was not read).
- **Creator Rewards (post-Jul 24, 2025) formula:** Not in the fetched doc.
- **Unconfirmed as narrative games:** "Need More Heat/Cold," "Eeveelution," "Dead Silence," "Airport Scary." The specific maker behind the "Kimmy/Fat Lizard"-style cheap scary chapters (not found).
- **2026 new narrative hits beyond those listed:** Search budget ran out before a dedicated 2026 sweep.
- **Dates:** Floor 2 (The Mines) release date; Rainbow Friends Ch 1 date; Break In 1 and 2 release dates. All marked [B].

---

## 12. Sources

**Doors / LSPLASH**
- RoVitals DOORS stats: https://rovitals.com/game/6516141723
- DOORS Wiki (Fandom): https://doors-game.fandom.com/wiki/DOORS · Update Logs 2026: https://doors-game.fandom.com/wiki/Update_Logs/2026 · The Archives Update: https://doors-game.fandom.com/wiki/The_Archives_Update · Knobs: https://doors-game.fandom.com/wiki/Knobs
- Official DOORS Wiki: https://doorsgame.wiki/wiki/DOORS · https://doorsgame.wiki/wiki/LSPLASH
- Roblox Wiki: https://roblox.fandom.com/wiki/LSPLASH/DOORS · https://roblox.fandom.com/wiki/LSPLASH
- PCGamesN Doors codes (currency context): https://www.pcgamesn.com/doors/codes

**Pressure**
- https://pressure.fandom.com/wiki/Pressure · https://urbanshade.org/wiki/Pressure · https://www.rolimons.com/game/12411473842 · https://roblox.fandom.com/wiki/Player:YourFriendZeal · https://en.namu.wiki/w/Pressure(Roblox)
- Primetimer (Apr 2026 allegations): https://www.primetimer.com/features/what-is-the-pressure-roblox-controversy-involving-zeal-and-ren-2026-allegations-explored-as-gianni-matragrano-quits-in-wake-of-concerning-google-doc
- PiunikaWeb (May 7, 2026 disappearance): https://piunikaweb.com/2026/05/07/horror-game-pressure-disappears-roblox-details-unclear/
- FFBooyah (deleted, returned, 18+): https://ffbooyah.com/2026/05/08/roblox-pressure-drama-full-story-explained-deleted-returned-and-now-18/
- HelloItsVG on X: https://x.com/HelloItsVG/status/2042234618712035543 · https://x.com/HelloItsVG/status/2052422432447754514

**The Mimic**
- https://mimic.fandom.com/wiki/The_Mimic · https://roblox.fandom.com/wiki/CTStudio/The_Mimic · https://www.rolimons.com/game/6243699076 · https://endsights.com/the-mimic-lore · https://progameguides.com/roblox/when-does-the-mimic-book-ii-come-out/
- MUCDICH TikToks: https://www.tiktok.com/@mucdich/video/7323411631004749087 · https://www.tiktok.com/@mucdich/video/7507254995151015214

**Piggy**
- https://piggy.fandom.com/wiki/Piggy_(Game) · https://piggy.fandom.com/wiki/PIGGY_(Franchise) · https://piggy.fandom.com/wiki/Piggy_(Game)/Book_2 · https://roblox.fandom.com/wiki/Player:MiniToon/Piggy · https://en.namu.wiki/w/Piggy/Book%202
- "How Piggy Lost 97% of its Players": https://www.youtube.com/watch?v=JCVji-FrUt0
- Piggy News (<100K peak, Oct 2020): https://x.com/Piggy_News/status/1315255894687481856
- DevForum Level Up Spotlight, MiniToon Inc: https://devforum.roblox.com/t/level-up-spotlight-minitoon-inc/1439441
- Robux claim (fan forum, unreliable): https://piggy.fandom.com/f/p/4400000000000152876

**Rainbow Friends**
- https://wikirainbowfriends.fandom.com/wiki/Chapter_2 · https://rblx-horror.fandom.com/wiki/Rainbow_Friends · https://www.rolimons.com/game/7991339063 · Fan-made clone: https://www.roblox.com/games/10836902530/Rainbow-Friends-CHAPTER-2-TWO-v2-fanmade

**Dandy's World**
- RoWatcher: https://rowatcher.com/news/when-does-dandy-s-world-leave-alpha-full-release-new-characters-roadmap · https://dandys-world-robloxhorror.fandom.com/wiki/Dandy's_World_(Game) · https://shapes.inc/fandom/dandy-s-world/highlight-rox-controversy · https://dandys-world-robloxhorror.fandom.com/f/p/4400000000000039776

**Forsaken**
- https://forsaken2024.fandom.com/wiki/FORSAKEN · https://roblox.fandom.com/wiki/Forsaken_Dev_Team/Forsaken · https://rowatcher.com/games/6331902150/forsaken · https://www.forsakenhub.com/blog/what-is-forsaken-roblox-complete-overview-2026 · https://www.forsakenhub.com/blog/forsaken-faq-50-questions-answered-2026

**Regretevator / Apeirophobia**
- https://roblox.fandom.com/wiki/The_Axolotl_Sun/Regretevator · https://regretevator.fandom.com/wiki/Regretevator_(game) · https://shapes.inc/fandom/regretevator
- https://apeirophobia.fandom.com/wiki/Apeirophobia · https://roblox.fandom.com/wiki/Polaroid_Studios/Apeirophobia · https://www.rolimons.com/game/10277607801

**Break In / 99 Nights / Grandma's Favourite Games**
- https://roblox.fandom.com/wiki/Player:Cracky4/Break_In · https://roblox-break-in.fandom.com/wiki/Break_In_2_(Game) · https://en.namu.wiki/w/Break%20In%202 · https://www.rolimons.com/game/13864661000 · All endings video: https://www.youtube.com/watch?v=up9amaDhauo
- PC Gamer (14.2M): https://www.pcgamer.com/games/survival-crafting/with-a-peak-player-count-of-14-2-million-99-nights-in-the-forest-has-an-audience-other-multiplayer-games-would-kill-for-to-find-these-behemoth-playerbases-you-need-to-be-on-a-platform-like-roblox/ · https://games.gg/news/99-nights-forest-14-million-roblox/
- 1M CCU milestone: https://x.com/ChannelSuzumiya/status/1946276491328716934
- Film: https://deadline.com/2026/04/99-nights-in-the-forest-movie-1236859433/ · https://variety.com/2026/film/news/99-nights-in-the-forest-movie-20th-century-studios-1236720515/ · https://www.hollywoodreporter.com/movies/movie-news/99-nights-in-the-forest-josh-cooley-20th-century-studios-film-1236704624/
- Interview: https://www.pcgamesn.com/roblox/99-nights-in-the-forest-interview · DevForum Creator Spotlight: https://devforum.roblox.com/t/creator-spotlight-the-story-behind-99-nights-in-the-forest/4036940
- GDC 2026: https://schedule.gdconf.com/session/catching-culture-currents-riding-resonant-trends-in-roblox-and-beyond/915731 · https://schedule.gdconf.com/speaker/kieft-alec/80898 · https://about.roblox.com/newsroom/2026/03/roblox-gdc-2026
- https://roblox.fandom.com/wiki/Grandma's_Favourite_Games/99_Nights_in_the_Forest · https://99-nights-in-the-forest.fandom.com/wiki/Grandma's_Favourite_Games · https://www.rolimons.com/game/79546208627805 · https://romonitorstats.com/experience/79546208627805/monetization/ · https://www.bloxquiz.gg/stats/99-nights-in-the-forest · https://www.maxpowergaming.co/post/99-nights-in-the-forest-surpasses-grow-a-garden-roblox-s-september-breakout

**Story-game genre**
- Camping: https://roblox-camping.fandom.com/wiki/SamsonXVI · https://roblox.fandom.com/wiki/Player:SamsonXVI/Camping
- Guesty: https://roblox.fandom.com/wiki/NK_Studio/GUESTY
- Field Trip Z: https://en.namu.wiki/w/Field%20Trip%20Z · https://www.roblox.com/games/4954096313/Field-Trip-Z
- Weird Strict Dad: https://en.namu.wiki/w/weird%20strict%20dad · https://www.roblox.com/games/14787369036/weird-strict-dad · https://www.roblox.com/games/14985941742/Weird-Strict-Dad
- Trending story games list: https://bloxodes.com/lists/top-trending-roblox-story-games
- DevForum saturation thread: https://devforum.roblox.com/t/what-do-games-like-break-in-scary-sushi-field-trip-z-faithless-and-the-kidnapper-have-that-my-game-doesnt/3667052
- Anthologies: https://www.roblox.com/games/18432975025/Short-Horror-Games · https://www.roblox.com/games/8404684575/Short-CREEPY-stories
- Horror roundups: https://noping.com/blog/best-roblox-horror-games · https://esports.gg/news/roblox/10-best-roblox-horror-games-in-2025-ranked/ · https://www.rpgstash.com/blog/roblox-horror-games-2026-top-trending-scary-experiences

**Micro-horror**
- Scary Shawarma Kiosk: https://roblox.fandom.com/wiki/Player:Kharbor_ykt/Scary_Shawarma_Kiosk:_the_ANOMALY_(horror) · https://roblox.fandom.com/wiki/Player:Kharbor_ykt · https://www.rolimons.com/game/137826330724902 · https://servicespv.com/en/blox/stats/scary-shawarma-kiosk-the-anomaly-horror-by-kharbor-ykt-roblox · https://www.youtube.com/watch?v=5T5es1MTyyE · Clone: https://www.rolimons.com/game/97267505570231 · iOS clones: https://apps.apple.com/us/app/-/id6759698340 · https://apps.apple.com/app/id6757749418 · IMDb: https://www.imdb.com/title/tt39195692/
- Scary Sushi: https://roblox.fandom.com/wiki/Evil_Twin_Games/Scary_Sushi · https://www.rolimons.com/game/16454399300 · Clone: https://www.roblox.com/games/114533377706788/Road-Side-Sushi

**Dead Rails / Grace**
- https://roblox.fandom.com/wiki/RCM_Games/Dead_Rails · https://www.gameanalytics.com/blog/dead-rails-and-the-hit-makers-formula · https://gamerant.com/roblox-zombie-game-dead-rails-popularity/ · https://games.gg/news/dead-rails-roblox-zombie-game/
- https://roblox.fandom.com/wiki/The_Fartering_Few/Grace · https://grace-rbx.fandom.com/f/p/4400000000000052062 · https://ffbooyah.com/2026/04/02/the-grace-roblox-drama-explained-what-happened-to-simon-the-controversy-and-the-future-of-the-game/

**Platform context**
- Grow a Garden (22.3M peak, Aug 23, 2025): https://en.wikipedia.org/wiki/Grow_a_Garden · Steal a Brainrot (>25M CCU): https://en.wikipedia.org/wiki/Steal_a_Brainrot · https://profitable.app/roblox/developers · https://gamedevreports.substack.com/p/roblox-top-100-roblox-developers

**Roblox official creator-docs (GitHub, primary) [DOC]**
- DevEx: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md
- U.S. 18+ DevEx rate: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/18-plus-devex-rate.md
- Paid access (Robux): https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-access-robux.md
- Paid access (local currency): https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-access-local-currency.md
- Subscriptions: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/subscriptions.md
- Private servers: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/private-servers.md
- Roblox Plus: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/roblox-plus.md
- Engagement-based payouts (deprecated Jul 24, 2025): https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/engagement-based-payouts.md
- Monetization index: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/index.md
- Rewarded video ads: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/rewarded-video-ads.md
- Content maturity: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md
- Regional availability: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/regional-content-availability.md
- Content update cadence: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/content-updates.md
- Design for Roblox: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/design-for-roblox.md
- Roblox user base: https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/roblox-user-base.md
- TextGenerator (LLM NPCs): https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/TextGenerator.yaml
- AudioTextToSpeech: https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/AudioTextToSpeech.yaml
- Studio MCP server (archived Apr 3, 2026; now built into Studio): https://github.com/Roblox/studio-rust-mcp-server
