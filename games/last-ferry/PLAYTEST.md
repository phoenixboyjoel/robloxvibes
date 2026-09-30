# First Studio playtest

Everything here was built and tested without Roblox Studio. The logic and the
wiring are covered by tests, but nobody has *looked* at the game yet. This is
the checklist for that first look. It should take about an hour. Note what's
wrong with a screenshot, and the agent can fix it from the notes.

Open `LastFerry.rbxl` in Studio, open the **Output** window, then **Play**.

## 1. It starts cleanly

- [ ] No red errors in Output, on the server or the client (Output shows both
      in Play mode).
- [ ] You're inside the booth looking out through the window. There's no
      avatar, and no jump or thumbstick controls on touch.
- [ ] Drag to look around; the view stops at about 38° either side. Scroll to
      lean in.
- [ ] The "Night 1" card shows two rules and Pike's radio message.
      **OPEN THE WINDOW** starts the night.

## 2. The harbor at night (tune these first)

- [ ] **Fog:** the queue (about 11, 17 and 23 studs out) is visible, and
      passengers walk out of the fog at around 50 studs. If it's too thick or
      thin, change `fog.Density` in `WorldService.setUpLighting`, which is 0.36
      now.
- [ ] **The lamp** over the window (front-left) lights the passenger's face.
- [ ] **Shadows:** a passenger at the window casts a shadow back and to the
      right across the planks. You should see it without moving the camera.
      This is a rule from night 4, so it must read clearly.
      - The lamp is `LampBulb` in `WorldService.buildBooth`.
      - Lighting is pinned to `LightingStyle = Realistic` with
        `PrioritizeLightingQuality` on.
      - Passengers who cast a shadow also get a dark `ShadowMark` patch in the
        same place. Check that it lines up with the real shadow, and doesn't
        look like a second shadow.
      - **Repeat this check with Studio's rendering quality set low**
        (Settings → Rendering → Editor Quality Level 1–3) and on a real phone.
        The shadow mark must still make the tell readable there.
- [ ] **Breath:** puffs from the passenger's face are visible against the fog,
      about one a second. They are the `Breath` emitters in
      `PassengerService.breathEmitter`: try a higher Rate or a less transparent
      puff if they're hard to see.
- [ ] **Wet passengers:**
      - you can see a darker glossy coat;
      - water drips from the sleeve cuffs and the front of the coat;
      - a wide puddle spreads out on both sides of them at the window;
      - wet footprints trail off when they leave.
- [ ] The lighthouse is far out front-left, dark until an ending. The *Petrel*
      is moored along the right edge of the dock, its cabin windows lit.

## 3. One passenger, start to finish

- [ ] The first passenger is a regular, Tomas or Priya, who walks up to the
      window.
- [ ] The ticket slides in on the left:
      - their name;
      - GULL ISLAND;
      - tonight's date (14 NOV 2026);
      - a red gull stamp.
- [ ] Their line of dialogue shows at the top centre.
- [ ] **BOARD**: the ticket gets a green BOARDED stamp and slides away. They
      walk through the gate and up the gangway, then fade.
- [ ] A dripping passenger with a 1999 ticket and a blue anchor stamp:
      **TURN AWAY** makes them walk to the dock's left edge and sink.
- [ ] A wrong call:
      - a lantern goes out: in the top bar, and on the counter, which is off
        to the lower left, so look down-left to see it;
      - the screen flashes red and shakes;
      - a red banner across the top says why.
- [ ] The countdown bar under the ticket turns red in the last 10 seconds. At 0
      the window closes, which counts as TURN AWAY.

## 4. A whole run (15 to 20 minutes)

- [ ] The rules card grows each night, and new rules say NEW.
- [ ] From night 3 the **MANIFEST** tab has names.
- [ ] Halfway through each night the queue pauses, and Pike's radio message
      types itself out while nobody is at the window.
- [ ] Mara, a small figure in a red coat, comes every night. Saying BOARD
      before night 5 costs nothing: she says "Not yet."
- [ ] The end-of-night summary lists every call, green or red, with a reason.
- [ ] On one ticket a night, a **TAKE PAGE** tab pokes out. Taking it opens the
      harbormaster's ledger over the rules panel, without blocking the
      buttons. With two players, only the finder's ledger opens; the other
      player gets a notice.
- [ ] Endings:
      - For about 7 seconds only the title shows, while the camera turns to the
        scene.
      - The lighthouse relights for a clean run.
      - The ghost ship appears for Mara's ending.
      - The *Petrel* sails off into the fog in all of them.
      - Then the text card rises.
- [ ] Lose a night on purpose: the camera tips down, water rises over the
      counter, and the night starts again with Pike's retry line.
- [ ] Keyboard: **B** boards, **T** turns away, **P** takes a page, and
      **Enter** or **Space** continues. On a gamepad: A, B, X, and A.

## 5. Phones and friends

- [ ] **Test → Device** emulators (iPhone SE, a modern iPhone, an iPad, a
      1080p PC):
      - nothing sits under the notch or Roblox's buttons;
      - the text is readable;
      - BOARD / TURN AWAY are easy to tap;
      - the passenger's shadow area (bottom centre) isn't covered.
        On 720p and small phones the far end of the shadow runs under the
        rules panel; the part by their feet, and the shadow mark, should
        stay clear.
      - Roblox's chat window opens bottom left, not over the ticket.
- [ ] **Test → Clients and Servers**, 2 players:
      - both see the same passenger;
      - either can make the call;
      - the Continue card shows "1 of 2 ready" until both press it, or the
        timer runs out.
- [ ] With API services enabled, finish a run, stop, and play again: the ending
      card lists the endings you've found.

## Tuning knobs

| What | Where | Now |
| --- | --- | --- |
| Time per passenger | `Config.DecisionTime` | 45 s |
| Intro / summary / ending timers | `Config.IntroTime`, `SummaryTime`, `EndingTime` | 30 / 25 / 60 s |
| Walking speed | `Config.WalkSpeed` | 7 studs/s |
| Look range | `Config.LookYaw`, `LookPitchDown`, `LookPitchUp` | 38° / 32° / 12° |
| Queue sizes and difficulty per night | `Content.Nights` | 6 to 9 passengers |
| All story text | `ServerScriptService/Shift/Content.luau` | |
| HUD scale on small screens | `Theme.DesignWidth/Height`, `MinScale` | 960 × 420, 0.66 |
