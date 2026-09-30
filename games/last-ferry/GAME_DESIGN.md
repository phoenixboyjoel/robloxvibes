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
  - You spawn on the pier behind the booth as your own avatar, with your
    friends. A notice board says STAFF WANTED; you hold E at the time clock
    and everyone is clocked in at the counter.
  - A radio voice explains two simple rules, and the first passenger walks out
    of the fog.
  - Within a minute you have checked a ticket, pressed BOARD or TURN AWAY, and
    seen someone with a 1999 ticket dripping seawater.
- **Moment to moment (20–40 s per passenger):**
  - Read the ticket.
  - Look at the person through the window (first person; lean in to check):
    are they wet? Is their breath fogging in the cold? Do they cast a shadow
    under the lamp? What do they say in the chat bubble over their head?
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
  - Up to four players share one booth as their own avatars, each at a stand
    behind the counter in the harbor's captain's cap, and anyone can make the
    call.
  - Friends argue over "is that breath or just the fog?", in bubble chat, while
    emoting and jumping round the booth between passengers.
  - After the ending everyone clocks out onto the pier together.

## Rules the player learns (cumulative)

Each rule is a tell with a counter: read or look, then turn them away.

| Night | New rule | What the player checks |
| --- | --- | --- |
| 1 | Tickets must show tonight's date | Date on the ticket |
| 1 | Destination must read GULL ISLAND | Destination on the ticket |
| 2 | Every ticket needs the red gull stamp | Stamp on the ticket |
| 2 | It hasn't rained tonight; nobody wet may board | Water dripping from their cuffs and coat, a puddle spreading around them, a dark soaked coat |
| 3 | Only names on tonight's manifest may board | Manifest tab |
| 3 | The living breathe fog in the cold | Breath puffs at the face |
| 4 | Everyone under the lamp casts a shadow | The planks behind and to the right of them |
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

- **On the pier** (between shifts) it's Roblox's own third-person camera round
  your avatar, zoomed in close.
- **In the booth** it's Roblox's first-person camera: look with the mouse (the
  right button, since the cursor stays free for the HUD), a finger or the right
  stick, walk round the booth, and lean in (scroll, pinch or R2) to inspect
  breath and shadows. Every avatar's eye is held at the same height (5.1 studs,
  the old fixed camera's), so a small avatar still sees over the counter and
  everyone sees the planks the tells are tuned for.
- **Cinematic views** turn you to the scene for the flood and the endings.
- **Friends never block the view:** a clerk standing between you and the window
  turns see-through on your screen, and nobody can stand on the counter.
- **The lamp hangs front-left of the window,** so each passenger's shadow falls
  back and to the right across the planks, clear of their own body. A lamp
  straight overhead would hide the shadow behind the passenger, and the shadow
  is a rule.
- **HUD, laid out on a 960 × 420 canvas and scaled to the screen:**

  | Where | What |
  | --- | --- |
  | Top | the night, the clock and date · the ledger, the queue, three lanterns; banners for lost lanterns and found pages |
  | Left, the "desk" | ticket, countdown, BOARD / TURN AWAY |
  | Right | rules card and manifest, which you can hide |
  | Top centre | Pike's radio |
  | Over each passenger | what they say, in a bubble drawn like Roblox's chat bubble, up for the whole window and on every device (and in the chat window) |
  | Bottom centre | kept clear, because that's where the shadows fall |

- In Roblox's chunky house style: thick dark outlines, rounded corners, hard
  shadows, a green BOARD with a check and a red TURN AWAY with a cross, Fredoka
  One titles, Builder Sans ExtraBold controls. Typewriter type only on the
  paper ticket and ledger.
- Main buttons stay at least 44 px on the smallest phones, and the rules panel
  stops above Roblox's touch jump button.

## Art, audio, and assets

- **Style:** a Roblox night, readable on phones.
  - Built entirely from parts in bold Roblox colours: a harbor-teal booth with
    white trim, a red roof and a neon-framed sign; white rails, red-and-white
    lifebuoys, blinking channel buoys, blocky gulls; a starry built-in sky and a
    light blue haze.
  - Passengers are classic Robloxians: Roblox's own head mesh and smile, R6
    proportions, a wardrobe of coats, hats, hair, scarves and bags. The drowned
    are the same people made wrong by the tells. Only Mara wears red.
  - Players are their own avatars.
- **Assets:**
  - The first build uses no external assets and no asset IDs, so nothing needs
    licence checks.
  - Swap in owned packs later, following the checks in
    `research/07-assets-licensing-and-pipeline.md`.
- **Audio:**
  - Only Roblox's built-in sounds, which ship with every client: passengers'
    plastic footsteps, splashes, water sloshing in the flooded booth, the
    stamp's thud, button clicks, a gust when a lantern blows out.
  - Every tell stays visual; many players play muted.
  - Planned: harbor ambience, ferry horn and radio static from Roblox's
    licensed library.

## Milestones (each one playable and testable on its own)

All seven are built and covered by the automated tests; each still needs its
Studio playtest (see `PLAYTEST.md`) before it counts as done.

| # | Phase | Done when (observable in a playtest) | Build |
| --- | --- | --- | --- |
| 1 | World and camera | Booth view through the window; fog, lamp, dock, ferry, water visible; drag-to-look works on mouse and touch | Built |
| 2 | One passenger | A passenger walks out of the fog to the window, their ticket shows, BOARD/TURN AWAY sends them to the ferry or away | Built, tested headless |
| 3 | Night 1 loop | Six passengers, rules card, lanterns go out on mistakes, night summary | Built, tested headless |
| 4 | Five nights | Rules accumulate, tells escalate, radio lines, night failure and retry | Built, tested headless |
| 5 | Endings and secrets | Mara choice, ledger pages, four endings, saves and badges (badge IDs still to create) | Built, tested headless |
| 6 | Phone pass | Compact layout at phone size, 44 px touch targets, readable text | Built; sizes tested, looks unchecked |
| 7 | Looks and feels like Roblox | Classic Robloxian passengers; chat bubbles; players' own avatars on a pier lobby, clocking in to a first-person booth; the chunky Roblox HUD; the player list; Roblox's built-in sounds; everything moving smoothly on every screen | Built, tested headless; previews rendered |

## Kill or continue

- **Watch after two weeks live:**
  - share of players who finish night 1
  - share of players leaving in the first minute
  - day-1 return
  - share reaching an ending
- **Iterate if** fewer than half finish night 1: onboarding problem. Rework the
  first two passengers and the radio.
- **Stop if** two updates later, day-1 return is still below about 20%.
