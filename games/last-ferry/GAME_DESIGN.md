# Game design: Last Ferry (working title)

## One-line pitch

Work the night ticket booth for the last ferry to Gull Island, and check every
ticket, because some of tonight's passengers drowned in 1999.

## The story in two layers

- **Surface story** (anyone can retell it): The old ferry *Marigold* sank on
  14 November 1999 with everyone aboard. Twenty-seven years later you take the
  night shift at Gull Harbor, and on the anniversary week the drowned come back
  to the ticket window, trying to get home. Keep them off the new ferry.
- **Deep lore** (for theorists):
  - The lighthouse keeper, Ambrose Pike, talks you through the shift on the
    radio. His lamp failed the night the *Marigold* sank and he never relit it.
  - His granddaughter **Mara**, nine years old in a red coat, was aboard with
    her mother **Anna**. Mara comes to your window every night with a 1999
    ticket, asking whether this is the ferry home.
  - Five torn pages of the harbormaster's ledger, one hidden behind a ticket each
    night, reveal the truth. Harbormaster **R. Vell** sold 41 tickets for a boat
    licensed for 23, and sent it out into a storm.
- **Endings** (each has a badge slot):

| Ending | How you get it |
| --- | --- |
| **The Petrel Sails** | Finish all five nights without letting a single drowned passenger board |
| **Mara Goes Home** | Same, but on the last night you let Mara board, breaking the rules on purpose. The lamp relights and the *Marigold* comes for her |
| **Low in the Water** | Finish having let any drowned passenger board. The *Petrel* never arrives, and your name is on tomorrow's manifest |
| **The Ledger** (secret) | Collect all five ledger pages. Adds an epilogue to whichever ending you reach |

## Core loop

- **First 60 seconds:**
  - A radio voice explains two simple rules, and the first passenger walks out
    of the fog.
  - Within a minute you have checked a ticket, pressed BOARD or TURN AWAY, and
    seen someone with a 1999 ticket dripping seawater.
- **Moment to moment (20–40 s per passenger):**
  - Read the ticket.
  - Look at the person (drag to look): are they wet? Is their breath fogging in
    the cold? Do they cast a shadow under the lamp? What do they say?
  - Decide.
- **A night (about 3 minutes):** 6–9 passengers, 11 PM to 5 AM. Each night adds
  one or two rules. Three lanterns on the counter go out one per mistake; lose
  all three and the tide comes in and you replay the night.
- **A run (about 15–20 minutes):** five nights, 38 calls, then an ending. A test
  bot that decides in 2 seconds finishes in under 4 minutes of game time. People
  reading carefully take 10–25 seconds per passenger, which puts a run at 15–20
  minutes.
- **Why come back:**
  - four endings, one of them secret
  - five ledger pages
  - the Mara choice
  - randomized queues on every night and retry
- **With friends:**
  - Up to four players share one booth, and anyone can make the call.
  - Friends argue over "is that breath or just the fog?"

## Rules the player learns (cumulative)

Each rule is a tell with a counter: read or look, then turn them away.

| Night | New rule | What the player checks |
| --- | --- | --- |
| 1 | Tickets must show tonight's date | Date on the ticket |
| 1 | Destination must read GULL ISLAND | Destination on the ticket |
| 2 | Every ticket needs the red gull stamp | Stamp on the ticket |
| 2 | It hasn't rained tonight; nobody wet may board | Dripping water, puddle, dark soaked coat |
| 3 | Only names on tonight's manifest may board | Manifest tab |
| 3 | The living breathe fog in the cold | Breath puffs at the face |
| 4 | Everyone under the lamp casts a shadow | The planks under their feet |
| 5 | Nobody here knows your name | What they say |

The drowned get better at hiding every night:

| Night | The drowned have learned to... | ...so this still gives them away |
| --- | --- | --- |
| 1 | nothing yet | 1999 date, soaked |
| 2 | copy the date | old blue anchor stamp, or still wet |
| 3 | dry off | no breath, or not on the manifest |
| 4 | fake their breath and steal names | no shadow |
| 5 | cast shadows | they know your name |

**Living passengers never show a supernatural tell.** Their mistakes are
paperwork only: wrong date, wrong destination, missing stamp, not on the
manifest. Some harmless oddities are there to unsettle you, such as an old
woman who mentions 1999, or a lamp that flickers.

## Content maturity target

Mild to Moderate fear:

- no blood, gore or death on screen
- dread comes from rules, uncertainty, fog, water and faces in the queue
- aimed to stay playable by players aged 9–15 once the game is eligible

Answer the questionnaire accordingly. No generative AI is exposed to players.

## Monetization (never paywall the story or an ending)

Not in the first build. Planned:

- **Revives:** "Relight a lantern", capped at one per night.
- **Cosmetics that fit the world:** booth decorations, a clerk's lamp colour.
- **Private servers** for friend groups and YouTubers.
- **Optional rewarded ad** between nights for a free lantern, once the game has
  2,000 monthly visitors.

## Screen and camera

- You sit in the booth. The camera is fixed at the window and only turns (drag,
  keys or stick), and you can lean in (scroll, pinch or R2) to inspect breath
  and shadows.
- **The lamp hangs front-left of the window,** so each passenger's shadow falls
  back and to the right across the planks, clear of their own body. A lamp
  straight overhead would hide the shadow behind the passenger, and the shadow
  is a rule.
- **HUD, laid out on a 960 × 420 canvas and scaled to the screen:**

  | Where | What |
  | --- | --- |
  | Left, the "desk" | ticket, countdown, BOARD / TURN AWAY |
  | Right | rules card and manifest, which you can hide |
  | Top centre | what the passenger says, Pike's radio, lost-lantern notes |
  | Bottom centre | kept clear, because that's where the shadows fall |

- Main buttons stay at least 44 px on the smallest phones.

## Art, audio, and assets

- **Style:**
  - Built entirely from parts: foggy blue night, warm sodium lamp, wet planks,
    black water.
  - Passengers are faceless figures in coats and hats. Only Mara wears red.
- **Assets:**
  - The first build uses no external assets and no asset IDs, so nothing needs
    licence checks.
  - Swap in owned packs later, following the checks in
    `research/07-assets-licensing-and-pipeline.md`.
- **Audio:**
  - None in the first build. Every cue is visual first; many players play muted.
  - Planned: harbor ambience, ferry horn, radio static, water drips from Roblox's
    licensed library.

## Milestones (each one playable and testable on its own)

All six are built and covered by the automated tests; each still needs its
Studio playtest (see `PLAYTEST.md`) before it counts as done.

| # | Phase | Done when (observable in a playtest) | Build |
| --- | --- | --- | --- |
| 1 | World and camera | Booth view through the window; fog, lamp, dock, ferry, water visible; drag-to-look works on mouse and touch | Built |
| 2 | One passenger | A passenger walks out of the fog to the window, their ticket shows, BOARD/TURN AWAY sends them to the ferry or away | Built, tested headless |
| 3 | Night 1 loop | Six passengers, rules card, lanterns go out on mistakes, night summary | Built, tested headless |
| 4 | Five nights | Rules accumulate, tells escalate, radio lines, night failure and retry | Built, tested headless |
| 5 | Endings and secrets | Mara choice, ledger pages, four endings, saves and badges (badge IDs still to create) | Built, tested headless |
| 6 | Phone pass | Compact layout at phone size, 44 px touch targets, readable text | Built; sizes tested, looks unchecked |

## Kill or continue

- **Watch after two weeks live:**
  - share of players who finish night 1
  - share of players leaving in the first minute
  - day-1 return
  - share reaching an ending
- **Iterate if** fewer than half finish night 1: onboarding problem. Rework the
  first two passengers and the radio.
- **Stop if** two updates later, day-1 return is still below about 20%.
