# Roblox Platform Economy and Discovery Landscape, 2025–2026: Market Brief

**Prepared for:** Joel Z, Phoenix Feather Studios (small indie studio; story-driven games plus occasional "money games"; planning Roblox launches built with AI coding agents)
**Date:** 2026-09-29
**Scope:** Platform scale, creator economics, discovery and algorithm, genre hits, policy risk, and costs, ending with implications for a small AI-assisted studio.

---

## 0. Method, confidence legend, limitations

**How this was researched**
- About 22 targeted web searches ran before the **session-wide search budget ran out**. The budget was shared with other agents, so the goal of 50+ queries could not be met.
- Direct page fetches were **blocked for almost every domain** (roblox.com, devforum, sec.gov, ir.roblox.com, pocketgamer.biz, and others). The one reachable source of primary material was Roblox's **official creator documentation mirror on GitHub** (`github.com/Roblox/creator-docs`). It is the source repository for `create.roblox.com/docs`, and about 35 pages were read from it directly.
- Earnings figures come from search-result summaries of SEC filings, shareholder letters and earnings-call coverage. The underlying documents are linked, but I could not open them myself.

**Confidence tags used throughout**

| Tag | Meaning |
|---|---|
| **[A]** | Primary Roblox source read directly this session (official creator-docs on GitHub). |
| **[B]** | Secondary: search summaries of SEC filings, Roblox newsroom posts, or press coverage. The URL is given but the page itself could not be opened. |
| **[C]** | My own calculation from [A]/[B] figures. The arithmetic is shown. |
| **[D]** | From my training knowledge (through about mid-2026) and **not re-checked this session**. Treat as low-to-medium confidence and check before relying on it. |

Section 8 lists the gaps I could not fill.

---

## Executive summary

1. **The 2025 boom has turned into a 2026 comedown.** DAU peaked at **151.5M in Q3 2025** (+70% YoY, 39.6B hours) on the back of Grow a Garden, Steal a Brainrot and 99 Nights in the Forest. It then fell each quarter: 144M (Q4 2025), 132M (Q1 2026), **123M (Q2 2026, +10% YoY)**. Q2 2026 bookings rose only **8%** to $1.6B. **Q3 2026 bookings are guided down 14–18% YoY**, and full-year guidance was **withdrawn** on July 30, 2026. [B]
2. **Creator payouts are still large.** DevEx fees were about **$1.50B in FY2025** (Q1 $281.6M, Q2 $316.4M, Q3 $427.9M, Q4 $477M) and **$363M in Q2 2026** (+15% YoY). That is roughly **22–23% of bookings** paid out to creators. [B][C]
3. **The discovery algorithm now optimizes for measured long-term retention.** Roblox openly traded short-term monetization for this. Games that "emphasize short-term monetization rather than long-term retention" get fewer impressions, and this contributed directly to the Q2 2026 bookings miss. [B]
4. **Roblox has published how Home ranking works.** The main signals are play-through rate from Home, first-play bounce (<60s and 61–180s), play-days per user (D1, D2–7, D8–28) and playtime (capped at 60 min per user per game per day). Secondary signals are co-play days, qualified sessions, spend-days and Robux per user. **Only users who arrived organically from "Recommended for You" count in ranking.** Traffic from ads, friends, search and social media does not. [A]
5. **Clones are penalized.** "Games with metadata and place files that closely resemble existing games on Roblox are no longer prioritized for recommendations." Hand-picked "**Standout Games**" rewards *novel* games. [A]
6. **Adults are the growth and monetization story.** In the US, 18+ DAU and hours grew 40% YoY in Q1 2026, and the 18–34 group grew over 50%. US 18+ users monetize **over 50% higher** than under-18s. Since **June 8, 2026**, spend from age-checked US 18+ players in R15-only games cashes out at **$0.0054/Robux**, which is 42% above the standard **$0.0038** and raises the creator's effective share of consumer spend from **26.6% to 37.8%**. [A][B][C]
7. **Launching a new game is now gated.** New public games reach **age-checked users 16+ only** at first. Reaching under-16s (Roblox Kids ages 5–8 and Roblox Select ages 9–15, live since June 2026) requires all of the following:
   - an age-checked developer account with 2FA;
   - either 2 months of Plus/Premium, a refundable **1,000 Robux** fee, or **50,000 Robux** for expedited review;
   - about **250 unique plays by highly engaged age-checked users within 60 days**;
   - a safety review.

   DevForum threads report the eligibility pipeline as buggy. [A][B]
8. **Safety changes are depressing engagement, especially among young users.** Communications have required an age check since January 2026, and chat is limited by age. By the end of Q2 2026, 57% of global DAUs were age-checked (over 70% in the US and Australia). Roblox says this slowed new-user acquisition and reduced communication. [B]
9. **The monetization toolkit is broader than before.** It now includes Creator Rewards (replaced Premium Payouts on July 24, 2025), Roblox Plus sign-up bounties (up to 750 Robux per new subscriber), a 10% cut of in-game Robux transfers, managed/regional pricing, local-currency subscriptions (**100% creator share from month 2**), local-currency paid access ($9.99/$29.99/$49.99 at 50/60/70%), rewarded video and immersive ads (≥2,000 monthly visitors), and Shopify commerce. [A]
10. **AI tooling lowers barriers for everyone.** Studio has a **built-in MCP server**; the standalone repo was archived April 3, 2026 in its favor. Roblox is also pushing "Build" (conversational game creation). Competition from cheap content will grow, so **differentiation (story, art direction, novelty) and retention design matter more than raw output speed**. [A][B]

---

## 1. Platform scale

### 1.1 Quarterly KPIs (Q1 2025 – Q2 2026)

| Quarter | DAU | DAU YoY | Hours engaged | Bookings | Bookings YoY | Revenue | DevEx fees | Tag |
|---|---|---|---|---|---|---|---|---|
| Q1 2025 | ~97.8M | — | ~21.7B | ~$1.2B | — | ~$1.0B | **$281.6M** (+39%) | [B] DevEx; others [C] back-calculated from Q1'26 growth rates |
| Q2 2025 | ~111.8M | +41% | ~27.4B | ~$1.44B | +51% | ~$1.08B | **$316.4M** (+52%) | [B]/[C]/[D] |
| Q3 2025 | **151.5M** | +70% | **39.6B** (+91%) | **$1.92B** | +70% | $1.36B (+48%) | **$427.9M** (+85%) | [B] |
| Q4 2025 | **144M** | +69% | n/a (gap) | **$2.2B** | +63% | ~$1.4B (+43%) | **$477M** (+70%) | [B] |
| Q1 2026 | **132M** | +35% | **31B** (+43%) | **$1.7B** | +43% | $1.4B (+39%) | n/a (gap) | [B] |
| Q2 2026 | **123M** | +10% | **29B** (+5%) | **$1.6B** | +8% | $1.5B (+36%) | **$363M** (+15%) | [B] |

Sources:
- Q2 2026: [8-K ex99.1](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm), [shareholder letter PDF](https://s27.q4cdn.com/984876518/files/doc_financials/2026/q2/Roblox-Q2-2026-Earnings-Shareholder-Letter.pdf), [PocketGamer.biz](https://www.pocketgamer.biz/roblox-revenue-rises-36-yy-but-young-north-americans-see-falling-per-hour-monetisation/), [Investing.com slides](https://www.investing.com/news/company-news/roblox-q2-2026-slides-revenue-rises-36-as-bookings-growth-stalls-93CH-4826381), [Music Ally](https://musically.com/2026/07/31/roblox-ended-q2-2026-with-123-million-daily-active-users/)
- Q1 2026: [8-K](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028882/ex991-q12026earningsshar.htm), [letter PDF](https://ir.roblox.com/files/doc_financials/2026/q1/Q1-2026-Earnings-Shareholder-Letter.pdf), [Yahoo Finance](https://finance.yahoo.com/markets/stocks/articles/roblox-rblx-beats-expectations-1-113142093.html)
- Q4 2025: [8-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000009/ex991-q42025shareholder.htm), [Investing.com slides](https://www.investing.com/news/company-news/roblox-q4-2025-slides-69-user-growth-and-63-bookings-surge-despite-continued-losses-93CH-4489163)
- Q3 2025: [8-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000326/ex991-q32025shareholderl.htm), [call transcript](https://s27.q4cdn.com/984876518/files/doc_financials/2025/q3/Q3-2025-Earnings-Conference-Call_Transcript.pdf), [PYMNTS](https://www.pymnts.com/earnings/2025/robloxs-150-million-daily-users-still-havent-translated-into-profitability/)
- Q2 2025: [8-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000261/q225shletterex992.htm), [press release](https://ir.roblox.com/news/news-details/2025/Roblox-Reports-Second-Quarter-2025-Financial-Results/default.aspx)
- Q1 2025: [8-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000117/ex992-q12025shareholderl.htm)

**Other Q2 2026 datapoints [B]**
- Monthly unique payers: **27M** (+15%).
- ABPDAU: **$12.66** (−2% YoY), down from a $15.97 peak in Q4 2024.
- Operating cash flow **$318M** (+60%); free cash flow **$294M** (+66%).
- US & Canada is still **more than 50% of global spend**, including **$846M** of Q2 revenue ([PocketGamer.biz](https://www.pocketgamer.biz/roblox-revenue-rises-36-yy-but-young-north-americans-see-falling-per-hour-monetisation/)).

**Q1 2026 cash flow [B]:** operating cash flow $629M (+42%), free cash flow $596M (+40%).

### 1.2 Full-year 2025

| Metric | FY2025 | Tag / source |
|---|---|---|
| Revenue | **$4,890.6M** (+36%) | [B] [FY2025 annual report](https://www.sec.gov/Archives/edgar/data/1315098/000110465926044380/rblx-20251231xars.pdf) |
| Bookings | **≈ $6.8B** (≈ $1.21B + $1.44B + $1.92B + $2.2B) | [C]. The "$7.3B" in [Runchey Research](https://www.runcheyresearch.com/blog/rblx-deferred-revenue-creator-moat-deep-dive) matches the **trailing 12 months to Q1 2026** ($1.44B + $1.92B + $2.2B + $1.7B ≈ $7.26B), not calendar 2025. |
| DevEx fees (creator cash-outs) | **≈ $1.503B** ($281.6M + $316.4M + $427.9M + $477M) | [C], matching the "$1.503B" in [SQ Magazine](https://sqmagazine.co.uk/roblox-game-creation-and-monetization-statistics/) [B] |
| Average DAU | ≈ 126M (mean of quarterly DAU) | [C] |

### 1.3 Trajectory and why it matters
- **2025 was an anomaly driven by viral hits.**
  - The Q3 2025 letter credits Grow a Garden plus "two new viral experiences: Steal a Brainrot and 99 Nights in the Forest." Each hit a concurrent-user peak "which would have exceeded those of the entire platform last year." [B] ([Q3 2025 8-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000326/ex991-q32025shareholderl.htm))
  - Hours peaked near **40B in Q3 2025** and were **29B in Q2 2026**. [B] ([Outlook Respawn](https://respawn.outlookindia.com/gaming/gaming-news/roblox-q2-2026-revenue-soars-36-to-15b-despite-bookings-miss))
- **Why 2026 decelerated (Roblox's own explanations) [B]:**
  - The **Russia ban** took effect in December 2025. One outlet also mentions a later reinstatement in Russia; I could not verify that.
  - The **age-check rollout** limited communication for users who had not age-checked, "diluted communication for age-checked users," and "slowed new user acquisition" (Q1 2026).
  - **Engagement moved from 2025's viral games** to "new and evergreen games with lower hourly monetization."
  - **Discovery algorithm changes** favored long-term retention (Q2 2026). Sources: [Q1 2026 8-K](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028882/ex991-q12026earningsshar.htm), [GuruFocus call highlights](https://www.gurufocus.com/news/8993610/roblox-corp-rblx-q2-2026-earnings-call-highlights-revenue-surges-36-to-15b-but-q3-bookings-forecast-signals-sharp-decline).
- **Guidance path for 2026 [B]:**
  - February 2026: FY2026 bookings growth guided at **+22% to +26%**.
  - Before Q2, a later guide of **+8% to +12%** was reported (single secondary source; probably set at the Q1 print).
  - **July 30, 2026: full-year guidance withdrawn.** Q3 2026 guide is bookings **$1.58–1.65B (−14% to −18% YoY)** and revenue **$1.41–1.49B (+4% to +10%)**.
  - Stock reaction: about −20% after Q1 ([tech-insider](https://tech-insider.org/roblox-q1-2026-earnings/)) and −13.8% after hours to $41.94 after Q2 ([Investing.com transcript](https://www.investing.com/news/transcripts/earnings-call-transcript-roblox-q2-2026-beats-eps-but-shares-sink-on-bookings-93CH-4826338)).

### 1.4 Demographics
- **Q3 2025:** 13+ DAU grew **89% YoY**, and **two-thirds of all DAUs are 13+**. [B] ([Q3 2025 8-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000326/ex991-q32025shareholderl.htm))
- **Q1 2026:** US 18+ DAU and hours both **+40% YoY**, and the **18–34 group grew over 50%**, faster than any other. **18+ users are 26% of age-checked DAUs.** US 18+ users **monetize over 50% higher** than under-18s. [B] ([Q1 2026 8-K](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028882/ex991-q12026earningsshar.htm), [Roblox newsroom, 18+ DevEx](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42))
- **Q2 2026:** monetization per hour fell **most among under-13 users in the US and Canada**. [B] ([PocketGamer.biz](https://www.pocketgamer.biz/roblox-revenue-rises-36-yy-but-young-north-americans-see-falling-per-hour-monetisation/), [MediaPost](https://www.mediapost.com/publications/article/416947/roblox-hits-123m-q2-users-struggles-to-engage-you.html))
- **Strategy:** Roblox named the 18+ market "a major opportunity." It is "removing previous limits on supported content types, including expanding into 2D gaming alongside high-fidelity 3D." [B] ([Yahoo: AI push and monetization reset](https://finance.yahoo.com/technology/ai/articles/roblox-q2-earnings-call-highlights-140000882.html))
- Roblox's own user-base doc now says only that more users are 13+ than under 13. Its regional charts are stale (from 2022). [A] ([roblox-user-base.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/roblox-user-base.md))

### 1.5 Regional mix (Q2 2026) [B]

| Region | DAU | YoY | Note |
|---|---|---|---|
| US & Canada | 22M | +6% | More than 50% of global spend ($846M Q2 revenue) |
| Europe | 26M | +1% | Nearly flat, partly due to Russia |
| APAC | 41M | +15% | Growth engine, but low monetization |
| Rest of world | 34M | +15% | Growth engine, but low monetization |
| **Total** | **123M** | **+10%** | |

Sources: [Investing.com](https://www.investing.com/news/company-news/roblox-q2-2026-slides-revenue-rises-36-as-bookings-growth-stalls-93CH-4826381), [PocketGamer.biz](https://www.pocketgamer.biz/roblox-revenue-rises-36-yy-but-young-north-americans-see-falling-per-hour-monetisation/).

**Implication:** **US & Canada has about 18% of DAU but more than half of spend.** Regional pricing (Section 2.6) is how Roblox is trying to monetize APAC and rest of world.

### 1.6 Platform unit economics (derived, useful for forecasting) [C]

| Metric | Value | Arithmetic |
|---|---|---|
| DevEx paid per engagement-hour (Q2 2026) | **≈ $0.0125/hour** | $363M ÷ 29B hours |
| DevEx per DAU per day (Q2 2026) | **≈ $0.032** | $363M ÷ (123M × 91 days) |
| DevEx per DAU per day (FY2025) | **≈ $0.033** | $1.503B ÷ (126M × 365) |
| Bookings per hour (Q2 2026 / Q3 2025) | ≈ $0.055 / $0.048 | $1.6B ÷ 29B; $1.92B ÷ 39.6B |
| Bookings per DAU per day (Q2 2026) | ≈ $0.14 | ABPDAU $12.66 ÷ 91 |
| Hours per DAU per day (Q2 2026) | ≈ 2.6 h | 29B ÷ (123M × 91) |
| DevEx as a share of bookings | ≈ 22–23% | Q2 2026 $363M ÷ $1.6B; FY2025 $1.503B ÷ ~$6.8B |

**Rule of thumb [C]:** at the *platform-average* DevEx per hour (~$0.0125):
- **~$100k per year of creator cash-out needs ~667k engagement-hours per month**, which is about **925 average concurrent users around the clock**.
- This is an optimistic proxy. Platform DevEx includes UGC avatar-item commissions and is skewed upward by the top games. Many indie games monetize far below average.

---

## 2. Creator economics

### 2.1 Developer Exchange (DevEx)
- **Standard rate: $0.0038 per earned Robux**, which is **$114 per 30,000 Robux**. It was raised from **$0.0035** ($105 per 30k), an **8.5%** increase, effective **September 5, 2025**. Older balances cash out at the old rate first. [A] ([developer-exchange.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md); [DevForum announcement](https://devforum.roblox.com/t/increasing-devex-%E2%80%94-creators-will-now-earn-85-more/3920159))
- **US 18+ rate: $0.0054 per Robux** (+42%), **effective June 8, 2026**. [A] ([18-plus-devex-rate.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/18-plus-devex-rate.md); [DevForum](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091); [newsroom](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42); [Tubefilter](https://www.tubefilter.com/2026/05/01/roblox-hikes-developer-earnings-by-42-but-only-if-they-make-games-aimed-at-adults/))
  - **Which purchases qualify:** developer products, passes, subscriptions and private servers bought by **US players who are 18+ and verified by facial age estimation or ID**.
  - **Which games qualify:**
    - Player characters must be R15, a custom humanoid (about 12 limb parts/joints) or a custom non-humanoid for **"100% of active playtime."**
    - **R6 must never be available** at any point in the game.
    - Roblox runs **background compliance checks**.
  - **Stated intent:** reward "high-quality character articulation and strong creative direction," with "unique and in-depth gameplay mechanics or distinctive visual styles."
- **Eligibility to cash out [A]:**
  - At least 30,000 earned Robux.
  - Age 13+ with a verified email.
  - A DevEx portal account and a W-9 or W-8 tax form.
  - Account in good standing.
- **Limits and timing [A]:** one completed cash-out per calendar month. Payout takes about 10 business days the first time and about 5 after that.
- **Robux that count as earned [A]:** sales of developer products, passes, subscriptions, private servers and marketplace items; Creator Rewards; and Creator Store sales.
- **Robux that do not count [A]:** purchased Robux, subscription grants, trading, *transfers received as a user*, gift cards, and Robux from violating content.
- **Registered creators [B]:**
  - Over 42,000 registered in DevEx as of June 30, 2026 ([Q2 2026 10-Q](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051082/rblx-20260630.htm)).
  - At December 31, 2025: 35,500 registered, and over 23,500 received cash payouts ([SQ Magazine citing the 10-K](https://sqmagazine.co.uk/roblox-game-creation-and-monetization-statistics/)).
  - The DevEx minimum dropped from 50k to 30k Robux on January 31, 2023.

### 2.2 Robux-to-USD math: what a creator keeps of each consumer dollar [C]

Roblox stated on the Q2 2026 call that creators' effective earnings on in-game spend by age-checked US 18+ users rose "**to 37.8% from 26.6%**." [B] ([Yahoo](https://finance.yahoo.com/technology/ai/articles/roblox-q2-earnings-call-highlights-140000882.html)) Both numbers can be reproduced exactly:

| Scenario | Creator keeps (Robux) of 100 spent | × DevEx rate | = USD | Share of consumer spend (at ≈ $0.01 per Robux paid by the player) |
|---|---|---|---|---|
| Before Sept 5, 2025 | 70 | $0.0035 | $0.245 | **24.5%** |
| Standard since Sept 5, 2025 | 70 | $0.0038 | $0.266 | **26.6%** |
| US 18+ rate since June 8, 2026 | 70 | $0.0054 | $0.378 | **37.8%** |
| Local-currency subscription, month 2 onward | 100% of value | n/a | n/a | Materially higher (see 2.7) |

- The exact match means Roblox's average consumer price is about **$0.01 per Robux** (roughly 1,000 Robux per $10), and passes and developer products pay creators **70%**.
- Budgeting rule: **each $1 a player spends on a standard developer product becomes about $0.27 of creator cash, or about $0.38 for age-checked US adults in R15-only games.**

### 2.3 Revenue shares by product

| Product | Creator share | Holds / notes | Tag / source |
|---|---|---|---|
| Passes, developer products | 70% of Robux (Roblox 30%) | About 5-day hold | [C] from the 26.6% math; [D] long-standing |
| Robux-priced subscriptions | **70% every month**; minimum price 49 Robux; open to all creators | About 5-day hold; regional pricing always on | [A] [subscriptions.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/subscriptions.md) |
| Local-currency subscriptions ($2.99 / $4.99 / $7.99 / $9.99 / $14.99) | **70% in month 1, 100% from month 2 on**; requires ID- or phone-verified account | 30-day hold; paid after the term is delivered | [A] same |
| Paid access, local currency ($9.99 / $29.99 / $49.99) | **50% / 60% / 70%** | 60-day escrow; monthly payout via Tipalti; buyable only on desktop/web; 48-hour refund window; **not sold** in Argentina, China, Colombia, India, Indonesia, Russia, Taiwan, Turkey, UAE, Ukraine or Vietnam | [A] [paid-access-local-currency.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-access-local-currency.md) |
| UGC avatar items bought on the Marketplace | Creator 30%, Roblox 70% (progressive share possible above price floors) | Upload fee 80 Robux (500 for emissive); publishing advance of 10 Robux (classic clothing), 600–1,500 (accessories), 1,500 (emotes), 2,500 (bodies) | [A] [marketplace-fees-and-commissions.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md) |
| UGC items sold **inside your game** | Item creator 30%, **game owner 40%**, Roblox 30% | Selling others' items in-game earns 40% | [A] same |
| Limited resale | Reseller 50%, original creator 10%, seller/affiliate 10%, Roblox 30% | | [A] same |
| Creator Store plugins and models | Only taxes and processing deducted; minimum price $4.99 (plugins) or $2.99 (models) | 30-day escrow | [A] [monetization index](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/index.md) |
| Licensed IP (License Manager) | Rightsholder takes a negotiated cut (docs example: 10%) | "Full game" or "in-game sales" licenses; example IPs: Blair Witch, The Strangers, Fall | [A] [ip-licensing/creators.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ip-licensing/creators.md) |

### 2.4 Creator Rewards (replaced Premium Payouts and Creator Affiliates on July 24, 2025) [A]

Source: [creator-rewards.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/creator-rewards.md), [engagement-based-payouts.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/engagement-based-payouts.md), [affiliates.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/affiliates.md)

- **Old model (retired):**
  - Engagement-based "Premium Payouts" paid by the share of Premium members' playtime.
  - Creator Affiliates paid up to 50% of a new user's purchases for 6 months, capped at $100.
  - **Both were deprecated on July 24, 2025.**
- **Daily Engagement Rewards:** **5 Robux per day** if your game is **one of the first three games an "Active Spender" plays for 10+ minutes** that day. An Active Spender has made qualifying purchases of **$9.99 or more anywhere on Roblox in the past 60 days**. No enrollment needed.
  - [C] 5 Robux × $0.0038 = **about $0.019 per qualifying spender per day**. So 1,000 such spenders a day is about $19/day, or roughly $570/month.
  - Design lever: be a game that spenders open **early in their session** (daily habit, daily rewards, timers).
- **Audience Expansion Rewards:** **35% revenue share on a new or returning user's first $100 of qualifying purchases** over 60 days. The user must arrive via your **share link or direct access** and play 10+ minutes on their first day.
  - **Requires:** an ID-verified account, a DevEx account, and the game averaging **100+ DAU for 60 days**.
- **Timing:** all rewards are paid as earned Robux with a **60-day hold**.

### 2.5 Roblox Plus and Robux transfers (new in 2025–26) [A]

Source: [roblox-plus.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/roblox-plus.md), [robux-transfers.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/robux-transfers.md)

- **Discounts:** Plus subscribers get **10% off in-game purchases for 2 months, then 20% off**. **Roblox pays for the discount**, so creators earn the same as on a full-price sale.
- **Sign-up bounty:** creators earn **up to 750 Robux per newly acquired Plus subscriber** (250 per month for 3 months), with a 60-day hold.
- **Private servers:** creators earn **up to 100 Robux per subscriber** who spends 60+ minutes a month in a paid private server.
- **Robux transfers:** Plus subscribers can send **10–500 Robux per transfer**. When a transfer happens through your game's prompt, **your game earns 10%** (Roblox takes no fee), and those Robux are DevEx-eligible.
- **Gap:** I could not confirm Plus's launch date or consumer price.

### 2.6 Pricing tools [A]
- **Price optimization** ([price-optimization.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/price-optimization.md)):
  - Runs automatic A/B price tests of about 3 weeks, rerun at least every 90 days.
  - Requires **at least 60,000 transactions in the previous 30 days**, so small games are not eligible.
  - Covers passes and developer products only, and prices are locked during a test.
  - The doc gives no uplift figures.
- **Regional pricing** ([regional-pricing.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/regional-pricing.md)):
  - Prices are set to **30–100% of your default price**, based on purchasing power, exchange rates and local spending.
  - Location is judged using VPN, billing and account history.
  - `GetUsersPriceLevelsAsync` returns a price level from 1 to 1000.
  - On by default for passes; manual for developer products; always on for Robux subscriptions.
- **Managed pricing** ([managed-pricing.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/managed-pricing.md)):
  - Combines both tools in one Creator Hub view.
  - **New games and items are enrolled automatically (opt-out).**
  - Subscriptions, private servers and developer servers are regionalized automatically.

### 2.7 Subscriptions, paid access, private servers [A]
- Local-currency subscriptions paying **100% from month 2** are the best-paying recurring product on the platform. They suit episodic or story content, such as a monthly "chapter pass."
- Paid access in local currency ($49.99 at 70%) is viable for **premium PC/desktop story games**, but only desktop/web purchases count and a 60-day escrow applies.
- **Gap:** I did not open private-servers.md. The only private-server detail confirmed is the Plus bounty in 2.5.

### 2.8 Commerce (physical goods) [A]

Source: [commerce-products.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/commerce-products.md)
- **Shopify is the only merchant partner.**
- **Creator must be:** 18+, ID- and email-verified, with 2FA and business information on file.
- **Game must be:** public, with a maturity label.
- **Buyers:** US only, age 13+ (18+ in Texas).
- **Limits:** 500 products per game, 100 on sale at once.
- **Bundling digital items** requires at least 100k average DAU over 90 days, or at least 1M Robux average monthly earnings, or a $50k/year ad-spend agreement.
- **Not relevant for a new indie until it has scale or merchandise.**

### 2.9 Ads as publisher revenue [A]
- **Rewarded video** ([rewarded-video-ads.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/rewarded-video-ads.md)):
  - Earnings = EPM (earnings per 1,000 impressions) × impressions. **No rates are published.**
  - The game must be public and unrestricted, average **at least 2,000 unique visitors per month**, and pass the Maturity & Compliance Questionnaire.
  - The publisher must be 13+ with ID verification and 2FA, and the player must take an explicit action before a video plays.
  - Showcase placements from top games ([ad-placements index](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/ad-placements/index.md)):
    - in menu: Adopt Me;
    - on the HUD: Barry's Prison Run, Brookhaven, **Grow a Garden** (HUD reward of items that speed growth), Sols RNG;
    - in the shop: **Blue Lock Rivals**;
    - as a pop-up: Evade, +1 Speed Keyboard Escape;
    - in the world: RIVALS.
- **Immersive ads** ([immersive-ads.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/immersive-ads.md)):
  - Formats: image, video and portal ads.
  - What earns: an image impression needs 1+ second in view; a click-to-play video pays after 15 seconds watched; a portal ad pays per teleport.
  - Paid on the 25th of the following month, with the same eligibility rules as rewarded video.
- **Gap:** no public EPM benchmarks.
  - [D] Launch context: rewarded video arrived around 2025 with Google as an ad-inventory partner; not verified this session.

### 2.10 The real distribution of earnings
- **FY2025:** about $1.503B in DevEx; about 23,500+ creators received cash; 35,500 registered. [B]/[C]
- **Top of the distribution [B], from [SQ Magazine](https://sqmagazine.co.uk/roblox-game-creation-and-monetization-statistics/) (secondary, citing Roblox disclosures):**
  - Top 10 creators averaged **about $33.9M** (headline) or **about $38.5M** (body text) each. The two figures conflict and probably cover different periods.
  - The **top 1,000 averaged about $1.3M** each.
- **Concentration [C]:** if the top 1,000 averaged $1.3M in the same year, they received **about $1.3B, roughly 86% of all DevEx**. The remaining ~22,500 paid creators would share about $0.2B, an average of **about $9k per year**. The median is almost certainly far lower, likely in the low thousands, because the DevEx minimum is only $114.
- **Base rate [D]:** Roblox has millions of creators and experiences. **Well under 1% of experiences reach meaningful DevEx.** Expect a power law: most launches earn nothing, a few percent earn pocket money, and a tiny fraction earn a living.

---

## 3. Discovery and algorithm (2025–2026)

### 3.1 Official Home "Recommended for You" mechanics [A]

Source: [discovery.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/discovery.md) (canonical: create.roblox.com/docs/discovery)

- **Two stages.**
  1. **Retrieval** picks a subset of games "each user might enjoy playing based on key signals like engagement, retention, and monetization."
  2. **Ranking** orders that subset personally for each user.
- **Ranking signals:**

| Weight | Signal | Definition (Roblox wording) |
|---|---|---|
| **Most important** | Play-through rate | "The rate at which users play your game after seeing it in the Recommended for You sort" |
| Most important | First-play bounce rate | Users who leave after a short first session, measured at **<60s** and **61–180s** |
| Most important | Play days per user | Unique days played, tracked at **Day 1, Days 2–7, Days 8–28** |
| Most important | Playtime per user | Capped at **60 minutes per user, per game, per day** |
| Important | Intentional co-play days | Unique days users come back **to play with friends** |
| Important | Qualified play sessions | Qualified sessions per user who arrived via recommendations |
| Important | Spend days per user | Unique days the user spends Robux |
| Important | Robux spent per user | Average spend |

- **Critical rule:** "Roblox doesn't count the engagement, monetization, or retention of users first acquired from **ads, curation, friends, search, social media, or any other source** in the ranking stage." **Only organic Recommended-for-You users count.**
- **Explore and expand:** after a content update you may see a spike in recommended traffic (explore). If that cohort performs well, Roblox expands to similar cohorts.
  - **Updates are how you earn new tests.** Roblox "continually reclassifies content quality with every update."
  - A daily-updated banner tells you when a game's visibility is reduced.
- **What moves your impressions:** your updates; Roblox algorithm changes; total Home traffic; and competition from other games.
  - Home traffic follows seasonality: **Saturday weekly peaks**, summer, back-to-school and holidays.
- **Benchmarks:** the similar-game benchmarks in Creator Hub are diagnostic only. "Benchmarks and benchmark games **do not impact** the Recommended for You algorithm."
- **Expect noise:** play-through rate drops temporarily when impressions ramp up. This is normal.

### 3.2 The 2026 pivot to long-term retention [B]
- **What changed (Q2 2026 call, July 30, 2026):**
  - Roblox chose to aim discovery "directly on measured long-term retention."
  - Discovery went from static to a system "constantly self-improving and self-estimating the best user-game pairs for long-term retention."
  - Games that **"emphasize short-term monetization rather than long-term retention"** now get a **"lower frequency of impressions."**
- **Cost and outlook:**
  - The hit fell mainly on the **US under-13** cohort and was bigger than expected.
  - Management says tests show the long-term retention gain will outweigh the short-term monetization loss, but gave **no timeline**.
- Sources: [GuruFocus](https://www.gurufocus.com/news/8993610/roblox-corp-rblx-q2-2026-earnings-call-highlights-revenue-surges-36-to-15b-but-q3-bookings-forecast-signals-sharp-decline), [Yahoo](https://finance.yahoo.com/technology/ai/articles/roblox-q2-earnings-call-highlights-140000882.html), [call transcript PDF](https://s27.q4cdn.com/984876518/files/doc_financials/2026/q2/32789865_2009724400_3775763_Transcript_EditedCopy_20260730233208.pdf).
- **Takeaway:** the **"2025 money-game playbook"** of aggressive short-loop monetization plus viral spikes is **being actively deprioritized** by the recommender. The Day 8–28 play-days signal and co-play days now count for more.

### 3.3 Other discovery surfaces
- **Acquisition sources reported in analytics [A]** ([acquisition.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/acquisition.md)):
  - Home Recommended; **Continue Play**; **Today's Picks**; Home other (Favorites and similar); **Friend Activity**; Search; **Charts (all sorts)**; Sponsored ads (sponsored experiences and **takeovers**); Search ads; **Portal ads**; Teleport; Other.
  - Per-source metrics: impression→play conversion, D7 retention, 7-day playtime, 30-day payer conversion and 30-day revenue per user.
  - Guidance: get **session time, D1 retention, payer conversion and ARPPU** to at least your similar-game benchmarks "to improve discovery visibility."
- **Today's Picks** is a named Home surface [A]. **Gap:** its selection rules are unpublished.
- **Charts / Discover page:** "top charts and trending sorts," which Roblox says it is updating to be "more impactful and dynamic" [A].
  - [D] Historic sorts include Top Trending, Up-and-Coming, Top Earning and Top Rated. Their current names and rules were not verified.
- **Search [A]:**
  - **Semantic search** in all officially supported languages (for example "food games").
  - **Search ads:** up to 10 keywords per ad set, a **second-price auction adjusted by relevance (eCPM)**, charged at the second price plus one cent, shown to ages 13+, with clickbait and spam suppressed ([search-ads.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/search-ads.md)).
- **Standout Games [A]:** hand-curated by Roblox for **"novel games"** with unique mechanics, distinctive visual styles, or an underrepresented genre. This is the best curated route for a story-driven indie.
- **Experience Events [A]:** up to 5 thumbnails; players can opt in to be notified when the event starts.
- **Notifications and Live Events [A]:**
  - Personalized notifications cover milestones, high scores and friend activity.
  - Live Events are limited-time, cross-game quests.
- **Game details page [A]:** a "similar games" rail. You can improve how your game shows here with Events, Groups, passes and subscriptions.
- **Short-form video feed ("Moments") [D]:** reportedly announced around RDC 2025. **Rollout status in 2026 not verified.**

### 3.4 What throttles exposure [A]
- **Giveaway or money bait:** "Metadata that implies any type of monetary reward is not prioritized," for example "Robux! Play now!"
- **Mismatched metadata:** a thumbnail promising dinosaurs on a generic obby is not recommended.
- **Clones:** "Games with metadata and place files that closely resemble existing games on Roblox are **no longer prioritized**."
  - Roblox says trend-following is fine if you "add unique elements."

### 3.5 Paid acquisition (Ads Manager) [A]

Source: [ads-manager.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/ads-manager.md)
- **Bidding:** **automated.** You set a budget and duration, and Roblox computes the bid.
- **Goals:** Plays, Engagement, and Earnings (limited availability).
- **Targeting:** location, age, gender, genre and device, plus segments for all, new, recent or lapsed players.
- **Payment:**
  - By card (**18+ only**; a $1 verification hold is placed) or by **ad credits converted from Robux** (13+; minimum 1 credit; conversion is permanent).
  - **No published minimum budget.**
- **Placements:** Home (sponsored placements and takeovers), search results and portals.
- **How ads relate to ranking:** because ranking uses only organic Recommended-for-You users, **paid users don't directly improve your ranking**. They matter indirectly:
  - they seed co-play and Friend Activity;
  - they build Charts momentum;
  - they help meet the **250 highly-engaged-plays** requirement for under-16 eligibility (Section 5.2);
  - they generate data to fix your first-time user experience before organic tests.
- **Gap:** CPM/CPC or cost-per-play benchmarks are not documented. See Section 6 for anecdotal ranges [D].

### 3.6 Metrics that matter and benchmarks
- **Official levers, in Roblox's order of importance [A]:**
  1. Home play-through rate (icon, thumbnail, title)
  2. First-play bounce under 60s and 61–180s (onboarding)
  3. Play days D1, D2–7, D8–28 (progression, habit, live ops)
  4. Playtime (session design; no benefit beyond 60 min/day)
  5. Co-play days (social design)
  6. Spend days and Robux per user (monetization)
- **Official retention definitions [A]:** D1, D7 and D30 are return rates for a first-play cohort. Insights and benchmarks need **100+ DAU**, and **no numeric thresholds are published** ([retention.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/retention.md), [insights.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/insights.md)).
- **Community rules of thumb [D, unverified; replace with your Creator Hub similar-game benchmarks]:**
  - D1: ~20% is weak, ~30% decent, 40%+ strong.
  - D7: ~5% weak, ~10% decent, 15%+ strong.
  - Average session: 15–30+ minutes.
  - Payer conversion: ~1–5%.
  - Indie ARPDAU: often well under platform DevEx/DAU-day (~$0.03, per 1.6 [C]).
- **In-game experimentation [A]:** `experiments.md` and `configs.md` exist in Creator Hub docs for A/B testing and remote config. The in-game Recommendation Service can rank items inside your game, and the `MaximizePlays` config "indexes on user satisfaction" ([recommendation.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/recommendation.md)).

### 3.7 How small developers get noticed

**Official and structural levers [A]**
- Ship frequent updates, because each can trigger an explore phase.
- Optimize icon and thumbnail for play-through rate, and the first 3 minutes for bounce rate.
- Build co-play loops.
- Use Experience Events, notifications and share links. Share links also pay 35% Audience Expansion rewards.
- Pitch for Standout Games with a genuinely novel game.
- Use search ads on genre keywords.

**Off-platform tactics [D]**
- The 2025 hits were amplified by **TikTok and YouTube Shorts clips** and by Roblox YouTubers and streamers.
- **Admin-abuse / live events** on fixed weekly schedules (for example Grow a Garden's Saturday updates) created appointment viewing.
- **Discord communities, Twitter/X dev accounts and codes** drive returning players.
- Micro-influencer seeding (small creators with 10k–200k followers) is the common indie tactic.
- **Verify** these against current creator-economy coverage; they could not be checked this session.

---

## 4. Genre trends and hits, 2025–2026

**Confidence note:** apart from the Roblox-sourced statements marked [A]/[B], the game-specific facts below come from **[D] training knowledge** and should be checked, especially the CCU peaks.

### 4.1 The 2025 wave

| Game | Launch (approx.) | Core loop | Reported peak | Team / dev | Why it hit | Tag |
|---|---|---|---|---|---|---|
| **Grow a Garden** | Mar 2025 | Plant → wait (real-time growth, **continues offline**) → harvest → sell. Rotating seed shop with restock timers, weather mutations, pets, trading. | **About 21.6M CCU (June 2025)**, reported as the largest concurrency ever for a single game at the time | Reportedly built in days by a **teen solo developer**, then scaled with Splitting Point Studios | Low-skill idle loop, strong "come back later" pull (D2–7/D8–28), weekly Saturday updates and "admin abuse" events, mobile-friendly | Peak and team [D]; "continued success" and rewarded-video HUD placement [A]/[B] |
| **Steal a Brainrot** | ~May 2025 | Buy meme characters from a conveyor; they earn cash per second; **steal from other players' bases**; lock your base; rebirth | Reported to **pass Grow a Garden's record in fall 2025 (~25M CCU)**; low-to-medium confidence | Small team | Italian-brainrot memes (Tralalero Tralala, Tung Tung Tung Sahur…) tuned for kids' TikTok; social conflict creates clippable drama; FOMO rarities | Named viral hit [B]; details [D] |
| **99 Nights in the Forest** | ~mid-2025 | Co-op survival horror: keep the campfire lit, rescue children, survive "the Deer," class progression | Multi-million CCU; Roblox says its peak beat the **whole platform's prior-year peak** | Grandma's Favourite Games [D] | Friend co-op (co-play days), tension, streamability, clear goal ("99 nights") | [B] + [D] |
| **Dead Rails** | ~Feb 2025 | Co-op train journey through a zombie Wild West; scavenge, fight, reach the end | Million-plus range (unverified) | Small studio | Novel premise, co-op, run-based replay | [D] |
| **Forsaken** | 2025 | Asymmetric horror (1 killer vs. survivors) with Roblox-lore characters | Hundreds of thousands (unverified) | Community team | Dead by Daylight-style format plus Roblox meme lore; YouTube-friendly | [D] |
| **Dandy's World** | 2024–25 | Co-op horror; collect and upgrade "Toon" characters; floor-by-floor runs | Hundreds of thousands (unverified) | Small studio | Character collection, fan art and lore, cute-creepy style | [D] |
| **Fisch** | Late 2024 | Fishing RPG: rods, locations, rarity collection, events | Around or above 1M (unverified) | Small team | Relaxing progression, collection, frequent events | [D] |
| **Blue Lock: Rivals** | Late 2024 | Anime-soccer PvP with character abilities | High hundreds of thousands (unverified) | Small team | Anime fandom crossover, competitive skill, shop rewarded-video placement | Shop RV placement [A]; rest [D] |
| **Ink Game** | 2025 | Squid Game-style elimination rounds | Spiked with Squid Game S3 (June 2025); unverified | Small team | Riding a TV event; party elimination format | [D] |

### 4.2 Patterns that made them work [C/D synthesis]
1. **One-sentence premise plus instant readability.** Kids understand the loop from a thumbnail or a 10-second clip (plant/steal/survive), which drives Home play-through and TikTok virality.
2. **Real-time timers and offline progress** (Grow a Garden) create **play days**, the strongest ranking signal after play-through rate.
3. **Social conflict or co-op.** Stealing (Brainrot) and co-op survival (99 Nights, Dead Rails) raise **co-play days**, now an explicit ranking signal [A].
4. **Scheduled live ops.** Weekly updates plus "admin abuse" events create appointment play. Each update also re-triggers the recommender's **explore phase** [A].
5. **FOMO rarity and trading economies.** These drove 2025 spend. **They are also exactly what the 2026 algorithm now marks down** when they come at the expense of retention [B].
6. **Meme IP** (brainrot) or **pop-culture adjacency** (anime, Squid Game) is free virality but carries IP risk (Section 5.6).

### 4.3 Copycat dynamics
- **2025 [D]:** every hit spawned dozens of "Grow a ___" and "Steal a ___" clones within weeks. A few fast followers did well by combining two trends (for example "Plants vs Brainrots," fall 2025).
- **2026 [A]:** Roblox now says near-duplicate place files or metadata are "no longer prioritized." **Pure clones are a worse bet than in 2025.** "Trend plus a unique twist" remains endorsed.

### 4.4 Small teams [D]
- Grow a Garden is the canonical case: a **very small or solo developer, a minimal first version in days**, then scaling up with a studio partner.
- Most 2024–25 breakouts came from **teams of about 1–10 people** who iterated weekly after launch rather than polishing before it.

### 4.5 2026 landscape [B + gap]
- Roblox says 2026 engagement moved **away from 2025's viral games toward "new and evergreen games"** with lower hourly monetization [B].
- **Gap:** I could not verify **which games topped the charts in 2026 or their CCU peaks**, because search was unavailable. **Action:** check RoMonitor Stats or Rolimons, and Roblox's Charts, before choosing a genre.

---

## 5. Risks and platform policy

### 5.1 Age checks and chat [B]
- **January 2026:** global rollout of **proactive age checks (facial age estimation or ID) required to use communications**.
  - End of Q2 2026: **57% of global DAUs age-checked**; the US and Australia are **above 70%**; the long-term goal is 90%.
  - Effects Roblox reported: less communication, and **slower new-user acquisition**.
  - Sources: [Q2 2026 letter](https://s27.q4cdn.com/984876518/files/doc_financials/2026/q2/Roblox-Q2-2026-Earnings-Shareholder-Letter.pdf), [Q1 2026 8-K](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028882/ex991-q12026earningsshar.htm).
- **[D] How chat works:** age-checked users are placed in **age bands** and can chat only within or near their band, with Trusted Connections for known contacts.
- **Design implication:** don't depend on free-text chat for social play. Build **non-chat social mechanics** (emotes, pings, co-op actions, parties).

### 5.2 Roblox Kids / Select and the 2026 publishing gate [A][B]

**Account types (live early June 2026; announced April 13–14, 2026)**
- **Roblox Kids (ages 5–8):** Minimal or Mild content only; chat off by default.
- **Roblox Select (ages 9–15):** up to Moderate content; chat on but limited to Trusted Friends and similar ages.
- Sources: [Roblox newsroom](https://about.roblox.com/newsroom/2026/04/introducing-roblox-kids-and-select-accounts), [TechCrunch](https://techcrunch.com/2026/04/13/roblox-introduces-kids-and-select-accounts-for-age-appropriate-access-to-games-and-chat/), [Variety](https://variety.com/2026/digital/news/roblox-kids-accounts-game-rating-system-1236719701/).

**Publishing requirements** ([publish-games-and-places.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md), [kids-and-select.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/kids-and-select.md))

| Step | Requirement |
|---|---|
| Any public game (audience **16+**) | Account in good standing and **at least 2 days old**; **age-checked** (facial estimation if under 18, **government ID if 18+**); **Maturity & Compliance Questionnaire** completed; **at most 5 never-public games made public per day** |
| All ages (reach Kids/Select) | Everything above **plus 2FA**, **plus one of**: an active **Roblox Plus or Premium subscription for 2 consecutive months**; **or a 1,000 Robux refundable fee per game** (added May 19, 2026, refunded 3 months after eligibility if compliant) ([DevForum](https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944)); **or 50,000 Robux per game for expedited review** |
| Evaluation | Starts **available only to age-checked users 16+**. Must reach **"250 unique plays by highly engaged age-checked users within a 60-day window"** (players are weighted by account age, play history and spend). Then a safety review of real-time moderation reports and gameplay. One doc summary instead mentioned "25 highly engaged players" in the refund context, so **confirm on Creator Hub**. |
| Content caps | Kids: Minimal or Mild only. Select: up to Moderate. |
| Subscription timing | The subscription is only needed at the moment you publish or update for all ages. The game stays all-ages if the subscription later lapses. |

- **Known friction [B]:** DevForum threads report broken eligibility and games stuck at 16+ ([1](https://devforum.roblox.com/t/%E2%9D%97-roblox-kidsselect-eligibility-broken-%E2%9D%97/4687072), [2](https://devforum.roblox.com/t/unable-to-make-game-public-to-16-even-when-meeting-eligibility-criteria/4608545), [3](https://devforum.roblox.com/t/game-locked-16-but-says-all-ages-under-reach/4713792), [4](https://devforum.roblox.com/t/new-select-eligibility-ambiguity/4603403)).
- **What this means:** a brand-new game **cannot tap the under-16 audience on day one.** Plan an older-player seeding phase. The 16+ phase lines up with the 18+ monetization tailwind.

### 5.3 Content maturity labels and ratings [A][B]

Source: [content-maturity.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md)
- **Minimal:** occasional mild violence, light unrealistic blood.
- **Mild:** repeated mild violence, heavy unrealistic blood, mild fear, mild crude humor.
- **Moderate:** moderate violence, light realistic blood, moderate fear, moderate crude humor, unplayable gambling content.
- **Restricted:** strong violence, heavy realistic blood, romantic themes, alcohol, strong language. **Age-verified 18+ only.**
- **Unlabeled experiences:** Roblox "restricts the playability of the experience on the platform for all players."
- **Questionnaire topics:** violence, blood, fear, crude humor, gambling, language, romance, alcohol, social hangouts, **user creation features**, sensitive issues, paid items, media sharing, and **AI interactions** (relevant if you ship LLM NPCs).
- **Later in 2026 [B]:** a move to the **IARC framework**, so regional ratings appear (ESRB in the US, PEGI in Europe, USK in Germany, GRAC in Korea) ([Variety](https://variety.com/2026/digital/news/roblox-kids-accounts-game-rating-system-1236719701/), [Kinzoo](https://www.kinzoo.com/blog/robloxs-new-kid-accounts-explained-what-parents-need-to-know-before-june)).
- **Trade-off for story games:** mature themes mean a Restricted label, which means **18+ age-verified only** (18+ is about 26% of age-checked DAU). In exchange you get the 18+ DevEx uplift. Moderate keeps access to 9–15 and 16+.

### 5.4 Monetization compliance [A]
- **Paid random items (loot boxes)** ([paid-random-items.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-random-items.md)):
  - Show **all outcomes with numeric odds summing to 100%** *before* purchase.
  - Update the odds if an outcome can only be obtained once.
  - Honor `PolicyService` flags `ArePaidRandomItemsRestricted` and `IsPaidItemTradingAllowed` per player, which vary by region and age.
- **Commerce:** 18+ creators only; US buyers only; 18+ buyers in Texas. This hints that state-law exposure is shaping product rules.
- **Discovery:** never use Robux-giveaway metadata [A].

### 5.5 Legal and regulatory backdrop [D, not verified this session]
- **US state attorney-general actions reported in 2025:** Louisiana lawsuit (August 2025), Kentucky lawsuit (October 2025), Florida criminal subpoenas (October 2025), Texas lawsuit (around November 2025). Many private child-safety suits, reportedly consolidated in federal court.
- **Country-level blocks:** Turkey (2024), several Middle Eastern countries, and **Russia (December 2025)**. The Russia ban is [B], confirmed in Roblox's Q1 2026 letter.
- **Cost impact [B]:** Roblox cited higher trust-and-safety costs, including safety marketing, in Q2 2026.
- **What this means for small developers:** policy tightening keeps coming, and new rules land quickly (the Kids/Select gate took about 2 months from announcement to go-live). Hangout or social games with private spaces, UGC features, or open chat carry the highest moderation and eligibility risk. [D]: 2025 rules restricted some private-space social hangouts to ID-verified 17+/18+.

### 5.6 IP and copyright
- **Tools [A]:** Roblox runs a DMCA process and a **Rights Manager** for rightsholders (docs `publishing/dmca-guidelines.md`, `rights-manager.md`, `dsa-ip-reporting.md`; not opened). The **License Manager** offers legal IP deals (2.3).
- **Brainrot memes [D]:** these characters are AI-generated with murky authorship. Individual meme creators have claimed rights, and hit games have filed takedowns against copycats. **Using third-party meme or anime IP is a real takedown risk.** Original characters (story IP) are both safer and an asset you own.

### 5.7 Moderation risks for new or AI-built games [C]
- Several things can trigger moderation or restrict a game:
  - Asset moderation of AI-generated meshes, textures and audio.
  - Metadata mismatch between thumbnail and gameplay (also a discovery penalty [A]).
  - Unlabeled content.
  - Inaccurate questionnaire answers.
  - Undisclosed paid random items.
- Consequence: a permanent takedown also **forfeits the refundable 1,000 or 50,000 Robux Kids/Select fee** [A].

### 5.8 Timeline of rule changes that matter

| Date | Change | Tag |
|---|---|---|
| Jul 24, 2025 | **Creator Rewards** launch; Premium engagement payouts and Creator Affiliates retired | [A] |
| Sep 5, 2025 | **DevEx $0.0035 → $0.0038** (+8.5%) | [A] |
| Dec 2025 | Roblox **banned in Russia** | [B] |
| Jan 2026 | **Global age checks to use communications** | [B] |
| Apr 3, 2026 | Standalone Studio MCP repo archived in favor of the **built-in Studio MCP server** | [A] ([repo](https://github.com/Roblox/studio-rust-mcp-server)) |
| Apr 13–14, 2026 | **Kids/Select** announced, with new game-screening process | [B] |
| Late Apr 2026 | **US 18+ DevEx rate** announced | [B] |
| May 19, 2026 | **1,000 Robux refundable fee** added as a Kids/Select publishing route | [B] |
| Early Jun 2026 | **Kids/Select live**; new games default to 16+ until evaluated | [B]/[A] |
| Jun 8, 2026 | **$0.0054 US 18+ DevEx rate** live | [A] |
| Jul 30, 2026 | Q2 call: discovery optimized for long-term retention; FY guidance withdrawn; 2D and new content types coming; "Build" AI creation | [B] |
| Later 2026 | IARC / ESRB / PEGI ratings | [B] |

---

## 6. Costs

### 6.1 Platform-imposed costs [A]

| Item | Cost |
|---|---|
| Publishing for 16+ | Free (needs age check and questionnaire) |
| Reaching under-16 (Kids/Select), option 1 | Plus or Premium for 2 months. Premium's price is about $5–$10/month [D]; Plus pricing is a gap. |
| Reaching under-16, option 2 | **1,000 Robux per game (~$10 at retail), refundable** |
| Expedited review | **50,000 Robux per game** (~$500 at retail, or ~$190 of DevEx value) |
| UGC upload | 80 Robux per item (500 emissive), plus a publishing advance of 10–2,500 Robux |
| Ads Manager | No published minimum; ad credits are bought from Robux (1 minimum) or you pay by card (18+) |
| Commerce digital-benefit threshold | A $50k/year ad-spend agreement is one route to qualify |

### 6.2 Advertising (sponsored, search, portal) [A + D]
- **Model [A]:** automated bidding on a budget. Search ads use a relevance-adjusted second-price auction.
- **Budgets [D, anecdotal]:**
  - Indie launch tests commonly run **$50–$500 per day for a few days**.
  - Cost per play is reported in the **low cents to tens of cents**, highest for US or 18+ targeting.
  - Treat ads as a way to **gather retention data and seed 16+ plays**, not as a reliable way to make back the spend.

### 6.3 Influencers [D, unverified]
- **Micro creators (10k–100k followers):** about $50–$500 per short or mention, or free game access and codes.
- **Mid-tier Roblox YouTubers:** about $1k–$10k per video.
- **Top-tier:** $10k–$50k+ per video.
- Many small developers use **revenue-share or affiliate deals** instead. Audience Expansion rewards (35% of a new user's first $100 via your share link) can be passed through to creators.

### 6.4 Contractor rates [D, unverified; ranges vary by region and skill]
Common marketplaces: Talent Hub, HiddenDevs and similar Discord communities, DevForum Collaboration.

| Role | Typical range |
|---|---|
| Luau scripter | Junior ~$10–25/h; experienced ~$30–75/h; senior or lead $75–150+/h. Per-system commissions ~$50–$2,000+. |
| Builder / map | ~$15–50/h; a full map ~$100–$3,000+ |
| 3D modeler | ~$10–$150+ per asset depending on complexity |
| Animator | ~$10–$75 per animation |
| UI designer | ~$10–$150 per screen; a full UI kit ~$200–$1,500 |
| **Icon and thumbnail artist** (your key play-through lever) | ~$20–$200 per piece |

Payment is often in Robux (cheaper for the payer), and percentage revenue-share deals are common.

### 6.5 Timelines [D]
- **Trend or money-game MVP:** days to 6 weeks. Grow a Garden's first version reportedly took days.
- **Polished mid-scope game:** 2–6 months.
- **Story-driven game with custom characters:** 4–12 months.
- **After launch:** hits typically update **weekly**. Plan the live-ops budget, not just the launch budget.
- **Add to the calendar now:** at least 2 days of account age, age check and 2FA; a 60-day window to earn the 250 highly engaged plays; and 3 months until the 1,000-Robux fee is refunded.

---

## 7. Implications for a small AI-assisted indie studio

1. **Enter a market that is still huge but past its peak.**
   - Roblox still has 123M DAU and pays creators about $1.4–1.5B a year.
   - But 2026 bookings are shrinking (Q3 guide −14% to −18%) and the 2025 viral tailwind is gone.
   - Plan for **slower organic uptake, competition for fewer marginal dollars, and more policy change.**
2. **Build for the algorithm Roblox now runs: long-term retention.**
   - Priorities, in Roblox's order: Home play-through rate → first-3-minute bounce → play days (D1, D2–7, **D8–28**) → playtime (useless beyond 60 min/day) → **co-play days** → spend days.
   - For money games, **swap aggressive paywalls and FOMO for daily-return loops**: timers, offline progress, daily goals, weekly events. These still sell skips and cosmetics, and they no longer cost you impressions.
3. **Don't clone; twist.** Near-duplicates are "no longer prioritized," and cheap AI-built clones will flood the market. Your advantage is **story, characters and art direction**, which also target **Standout Games** curation of "novel games."
4. **Lean into the 18+ opening. It fits a story studio.**
   - US 18+ is the fastest-growing group and monetizes more than 50% higher than under-18s.
   - Games that are **R15-only (no R6 ever)** earn **$0.0054/Robux on US 18+ spend**, which is **37.8%** of consumer spend versus 26.6%.
   - Roblox is opening **new content types (2D, high-fidelity)** for this market.
   - **Label choice:** a **Restricted** label (romance, strong language) limits you to age-verified 18+ players. **Moderate** keeps teens (9–15 via Select, plus 16+) and still earns the 18+ uplift on adult spend.
5. **Plan launches around the 16+ gate.**
   - Every new game starts **16+ only**.
   - **Seed older players first:** Discord, TikTok and YouTube aimed at teens and adults, plus small **Ads Manager** tests targeted 16+/18+. That is how you hit the **250 highly engaged plays in 60 days** before under-16 access opens.
   - Pay the refundable **1,000 Robux** per game, or keep Premium/Plus active for 2 months.
   - Use the **50,000-Robux expedite** only for a time-sensitive hit.
   - DevForum reports eligibility bugs, so **budget weeks of slack**.
6. **Stack monetization in the order that pays best.**
   - **Local-currency subscriptions** pay 100% from month 2; ideal for episodic story "chapter passes" or VIP.
   - Passes and developer products (70% of Robux).
   - **Rewarded video** once the game has at least 2,000 monthly visitors.
   - **Creator Rewards:** be an early-in-day game for spenders (5 Robux per spender per day) and push share links (35% of a new user's first $100).
   - **Plus bounties** (750 Robux per sign-up) and a 10% cut of transfers.
   - Leave **managed or regional pricing** on to monetize APAC and rest of world, the only regions growing about 15%.
   - For premium PC story titles, consider **paid access at $29.99–$49.99** (60–70% share; desktop only; 60-day escrow).
7. **Set realistic revenue expectations** ([C] platform averages; indie results are usually lower).
   - About **$0.0125 of DevEx per engagement-hour**, so roughly **925 average concurrent users around the clock ≈ $100k/year**.
   - Most launches earn nothing. The top 1,000 creators take about 85%+ of payouts.
   - **Treat each game as a cheap experiment with kill criteria**, for example "D1 below ~25% or D7 below ~7% after ~5k organic plays, then iterate or kill." Calibrate to your Creator Hub benchmarks.
8. **Use AI agents for speed and live ops, not for sameness.**
   - Studio's **built-in MCP server** lets Claude or Cursor run code, insert models, playtest and read output. Use it to ship **weekly updates**, each of which re-triggers the recommender's explore phase.
   - Also use it for A/B tests (Experiments/Configs) and quick onboarding fixes aimed at the <60s and 61–180s bounce windows.
   - **Spend human money where AI is weakest:** icon, thumbnail and character art (play-through rate) and narrative polish.
9. **Treat compliance as part of engineering.**
   - Fill in the maturity questionnaire accurately, including **AI-interaction and user-creation items** if you use LLM NPCs or building features.
   - Show loot-box odds and honor PolicyService flags.
   - Avoid money-bait metadata.
   - Avoid unlicensed meme or anime IP; use original IP or the License Manager.
   - Design social play that works **without open chat**.
10. **Suggested portfolio for Phoenix Feather:**
    - **Track A (cash):** 2–4 fast "trend + twist" retention-first money games per quarter, 2–6 weeks each. Small ad or influencer seeding ($200–$1,000 per game). Kill quickly on the retention gates.
    - **Track B (brand):** one R15-only, story-driven flagship aimed at teens and adults (Moderate or Restricted), monetized with local-currency chapter subscriptions and cosmetics. Pitch it for Standout Games.
    - **Minimum cash to start:** a few hundred dollars per launch (fees, test ads, art) plus contractor art budget. The bigger costs are **live-ops time and marketing content**.

---

## 8. Gaps and verification to-do
- **2026 chart-toppers and CCU peaks** (the biggest games of 2026) could not be verified. Check RoMonitor Stats, Rolimons and Roblox Charts.
- **Exact CCU peaks, launch dates and team sizes** for Grow a Garden, Steal a Brainrot, 99 Nights, Dead Rails, Forsaken, Dandy's World, Fisch, Blue Lock Rivals and Ink Game are **[D] only**.
- **Missing earnings detail:** Q4 2025 hours, Q1 2026 DevEx fees, and full regional history before Q2 2026.
- **Sponsored and search ad costs** (CPM/CPC/CPP) are not public in the docs. Influencer rates and contractor rates are **[D]**; check current Talent Hub and HiddenDevs listings.
- **Roblox Plus:** launch date and price. **Moments** short-video feed: status. **Today's Picks** and **Up-and-Coming**: selection rules.
- **State AG lawsuits and country bans** are [D] except the Russia ban.
- **Kids/Select threshold wording:** "250 unique plays" vs. "25 highly engaged players." Confirm on Creator Hub.
- **Earnings distribution:** conflicting top-10 averages ($33.9M vs $38.5M) and the exact median payout are unverified.
- **Rewarded video / immersive ads:** no EPM data found.

---

## Appendix: primary Roblox docs read this session (GitHub mirror of create.roblox.com/docs)

Base: `https://github.com/Roblox/creator-docs/blob/main/content/en-us/`
- [discovery.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/discovery.md) · [creator-rewards.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/creator-rewards.md) · [affiliates.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/affiliates.md)
- Monetization:
  - [developer-exchange](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md) · [18-plus-devex-rate](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/18-plus-devex-rate.md) · [engagement-based-payouts](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/engagement-based-payouts.md) · [roblox-plus](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/roblox-plus.md) · [robux-transfers](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/robux-transfers.md)
  - [price-optimization](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/price-optimization.md) · [regional-pricing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/regional-pricing.md) · [managed-pricing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/managed-pricing.md)
  - [subscriptions](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/subscriptions.md) · [commerce-products](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/commerce-products.md) · [paid-random-items](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-random-items.md) · [paid-access-local-currency](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-access-local-currency.md) · [immersive-ads](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/immersive-ads.md) · [index](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/index.md)
- Promotion: [rewarded-video-ads](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/rewarded-video-ads.md) · [ads-manager](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/ads-manager.md) · [search-ads](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/search-ads.md) · [content-maturity](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md)
- Publishing: [publish-games-and-places](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md) · [kids-and-select](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/kids-and-select.md) · [account-verification](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/account-verification.md)
- Analytics: [acquisition](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/acquisition.md) · [retention](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/retention.md) · [insights](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/insights.md)
- Other production docs: [recommendation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/recommendation.md) · [roblox-user-base](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/roblox-user-base.md) · [ad-placements](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/ad-placements/index.md)
- Marketplace and IP: [marketplace fees](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md) · [IP licensing for creators](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ip-licensing/creators.md)
- Tooling: [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server) (archived April 3, 2026 in favor of the built-in Studio MCP)
