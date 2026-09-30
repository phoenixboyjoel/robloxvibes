# First Studio playtest

Everything here was built and tested without Roblox Studio. The logic and the
wiring are covered by tests, and `tools/preview` renders an approximation of
each screen, but nobody has played it in Roblox yet. This is the checklist for
that first look. It should take about an hour. Note what's wrong with a
screenshot, and the agent can fix it from the notes.

Build the place fresh (`rojo build -o LastFerry.rbxl`; an older copy predates
the Roblox-look overhaul), open it in Studio, open the **Output** window, then
**Play**. If you sync into a place of your own with `rojo serve` instead, first
set two properties on **Workspace** that the Rojo plugin can't sync:
**SignalBehavior → Deferred** and **PlayerScriptsUseInputActionSystem →
Disabled**.

## 1. The pier (the lobby)

- [ ] No red errors in Output, on the server or the client (Output shows both
      in Play mode).
- [ ] You spawn on the pier behind the booth as your own avatar, facing the
      booth, in Roblox's normal third-person camera. The player list shows
      **Endings** and **Shifts**.
- [ ] Walk, jump and emote. Rails and invisible walls keep you on the pier:
      try to jump the rails into the water or onto the passengers' dock.
- [ ] The **LAST FERRY** banner says how to start. The notice board beside the
      path says the same.
- [ ] Walk up to the time clock right of the booth's back door: Roblox's
      "Clock in" prompt appears. Hold **E** (tap on a phone, **X** on a
      gamepad).
- [ ] A moment of black, then you're inside the booth at the counter in first
      person, the door thunks shut behind you, and the "Night 1" card shows two
      rules and Pike's radio message. **OPEN THE WINDOW** starts the night.
- [ ] **The status up top:** the night, the clock and the date, then IN LINE
      and the three lanterns, sit as dark pills in Roblox's own top bar row,
      beside Roblox's buttons, level with them and the same height. Open
      Roblox's menu and its chat: nothing of ours sits under Roblox's buttons,
      and if they take more room (join voice, say) the date drops out first,
      then IN LINE. Once you've taken a page, a LEDGER pill joins them (its
      word goes before the clock when room is short; its icon and page count
      stay). On a computer, Roblox's player list (top right) is put away for
      the shift, so it doesn't cover the rules, and it's back on the pier.
      With a gamepad, Roblox hides its buttons until you press Menu: the pills
      move over and back with them, in one jump rather than a slide. Judge
      whether that looks out of place beside Roblox's own buttons.

## 2. In the booth (first person)

- [ ] **Looking:** hold the right mouse button to look around (the cursor stays
      free for the HUD; it jumps to the middle while you hold the button, as
      Roblox's first-person camera does), drag on a phone, or use the right
      stick. Scroll, pinch or hold R2 to lean in. On a phone, walk with the
      thumbstick while dragging to look: that mustn't lean in.
- [ ] **Shift Lock:** pressing Shift does nothing on shift (it would drop you to
      your avatar's own eye height). Back on the pier it works again, if the
      place allows it.
- [ ] **Walking:** WASD or the thumbstick moves you round the booth; you can't
      leave it (door, walls, window glass and roof are solid). Jumping bumps
      the roof.
- [ ] **Eye height:** try a small avatar and a tall one (Avatar Settings, or a
      friend's). Both should see over the counter and the passenger's face
      through the window, at about the same height.
- [ ] **Friends:** in a 2-player test (Test → Clients and Servers), each clerk
      has a stand. Turn round: the other wears the harbor's white captain's
      cap. Hats they came in with are hidden under it, and come back after the
      shift. Check the cap sits well on a few avatar heads (classic head,
      dynamic head, big hair).
- [ ] You don't see your own body or cap in first person.
- [ ] **In each other's way:** stand behind a friend. While they're between you
      and the window they turn see-through on your screen (not on theirs), and
      solid again when they step aside. Try to jump onto the counter: an
      invisible guard stops you.
- [ ] **Respawn mid-shift** (Esc → Reset Character): you're back at a stand,
      looking out of the window, capped.
- [ ] **Every stand looks at the passenger:** with three or more players, at the
      start of a night each clerk's view is turned from their own stand to the
      passenger's face, not straight ahead.

## 3. The harbor at night (tune these first)

- [ ] **Colour and light:** bold Roblox colours read at night: the teal booth,
      red roof, neon sign frame, white rails, red-and-white lifebuoys, the
      passengers' clothes and faces.
- [ ] **Fog:** the queue (about 11, 17 and 23 studs out) is visible, and
      passengers walk out of the fog at around 50 studs. If it's too thick or
      thin, change `fog.Density` in `WorldService.setUpLighting`, which is 0.3
      now.
- [ ] **The lamp** over the window (front-left) lights the passenger's face.
- [ ] **Shadows:** a passenger at the window casts a shadow back and to the
      right across the planks. You should see it from the front stand without
      turning. This is a rule from night 4, so it must read clearly.
      - The lamp is `LampBulb` in `WorldService.buildBooth`.
      - Lighting is pinned to `LightingStyle = Realistic` with
        `PrioritizeLightingQuality` on.
      - Passengers who cast a shadow also get a dark `ShadowMark` patch in the
        same place. Check that it lines up with the real shadow, and doesn't
        look like a second shadow.
      - **Repeat this check with Studio's rendering quality set low**
        (Settings → Rendering → Editor Quality Level 1–3) and on a real phone.
        The shadow mark must still make the tell readable there.
      - The booth's ceiling lamp must not light the planks by the window.
- [ ] **Breath:** puffs from the passenger's face are visible against the fog,
      about one a second. They are the `Breath` emitters in
      `PassengerService`: try a higher Rate or a less transparent puff if
      they're hard to see.
- [ ] **Wet passengers:**
      - you can see a darker glossy coat and paler skin;
      - water drips from the sleeve cuffs and the front of the coat;
      - a wide puddle spreads out on both sides of them at the window;
      - wet footprints trail off when they leave.
- [ ] **Passengers look like Roblox people:** classic heads with the smile,
      varied outfits, hats and hair, walking with the classic arm and leg
      swing, swaying and looking about while they wait.
- [ ] **Everything moves smoothly:** passengers walk without stutter and turn
      into each leg of their walk (no snapping round); the booth door swings on
      its hinge; the *Petrel* sails off smoothly at the end. Then add lag
      (Studio Settings → Network → Incoming Replication Lag, 0.2 s) and check
      again, in a 2-player test: nothing should jump or stutter, only start a
      moment later.
- [ ] The lighthouse is far out front-left, dark until an ending. The *Petrel*
      is moored along the right edge of the dock, its cabin windows lit.

## 4. One passenger, start to finish

- [ ] The first passenger is a regular, Tomas or Priya, who walks up to the
      window with Roblox's plastic footsteps.
- [ ] The ticket slides in on the left:
      - their name;
      - GULL ISLAND;
      - tonight's date (14 NOV 2026);
      - a red gull stamp.
- [ ] What they say appears in a white bubble over their head that looks like
      Roblox's own chat bubble, and as a line in the chat window (so it can be
      read again). The bubble stays up for the whole window (45 s), and shows
      over the wall above the window from every stand, even for a tall
      passenger in a hat. It goes a moment after they leave.
- [ ] The bubble follows their head smoothly as you look around (no lag or
      jitter behind the view), is never under or over the ticket, the rules
      panel or the ledger, and never covers their face: look down at the
      planks and it stays above their head (off the top of the screen if it
      has to). With a TAKE PAGE tab showing, turn about 30 degrees right, so
      the passenger is near the ticket: the bubble moves beside the tab (or
      just over it) and never onto the ticket.
- [ ] On the first night, the hint along the bottom is two short lines on a
      computer or with a gamepad (how to look, then the keys), and doesn't run
      under the rules panel.
- [ ] **BOARD** (green, with a check): the button squashes and clicks, the
      ticket gets a BOARDED stamp with a thud and slides away. They walk
      through the gate and up the gangway, then fade.
- [ ] A dripping passenger with a 1999 ticket and a blue anchor stamp:
      **TURN AWAY** (red, with a cross) makes them walk to the dock's left edge
      and sink with a splash.
- [ ] A wrong call:
      - a lantern goes out, with a gust of wind: in the top bar, and on the
        counter;
      - the screen flashes red and shakes;
      - a red banner across the top bar row says why, for six seconds, then
        the status comes back.
- [ ] The countdown bar under the ticket turns red in the last 10 seconds. At 0
      the window closes, which counts as TURN AWAY.

## 5. A whole run (15 to 20 minutes)

- [ ] The rules card grows each night, and new rules say NEW.
- [ ] From night 3 the **MANIFEST** tab has names.
- [ ] Halfway through each night the queue pauses, and Pike's radio message
      types itself out while nobody is at the window.
- [ ] Mara, a small figure in a red coat, comes every night. Saying BOARD
      before night 5 costs nothing: she says "Not yet."
- [ ] The end-of-night summary lists every call with a green check or a red
      cross, and a reason.
- [ ] On one ticket a night, a **TAKE PAGE** tab pokes out of its right edge,
      low down (clear of the passenger's bubble on a phone). Taking it opens
      the harbormaster's ledger over the rules panel, without blocking the
      buttons. With two players, only the finder's ledger opens; the other
      player gets a notice.
- [ ] Endings:
      - For about 7 seconds only the title shows, while the view turns to the
        scene.
      - The lighthouse relights for a clean run.
      - The ghost ship appears for Mara's ending.
      - The *Petrel* sails off into the fog in all of them.
      - Then the text card rises. **CLOCK OUT** (or its timer) takes everyone
        back to the pier, where the player list's Endings and Shifts have gone
        up.
- [ ] Lose a night on purpose: the view tips down, water pours in and sloshes
      over the counter, and the night starts again with Pike's retry line.
- [ ] Keyboard: **B** boards, **T** turns away, **P** takes a page, and
      **Enter** or **Space** continues. On a gamepad: A, B, X, and A. Gamepad A
      and Space still jump whenever they have nothing else to do.

## 6. Phones and friends

- [ ] **Test → Device** emulators (iPhone SE, a modern iPhone, an iPad, a
      1080p PC, and an Xbox for the TV layout):
      - nothing sits under the notch or Roblox's buttons;
      - the text is readable;
      - BOARD / TURN AWAY are easy to tap, and the key caps are gone;
      - the thumbstick (lower left) and the jump button (lower right) work,
        and the rules panel stops above the jump button;
      - the passenger's shadow area (bottom centre) isn't covered.
        On 720p and small phones the far end of the shadow runs under the
        rules panel; the part by their feet, and the shadow mark, should
        stay clear.
      - Roblox's chat window opens bottom left, not over the ticket.
      - On phones the passenger's bubble sits over their head, between the
        ticket and the rules panel, with the longest lines (three lines of
        text) still clear of the top of the screen. The top bar row shows the
        night, the clock and the lanterns, and IN LINE if there's room
        (probably not on an iPhone SE). The date is the first to go.
      - On an iPad the rules panel stops above the bigger jump button.
      - On the Xbox (a TV screen) there's no Roblox chat at all, but the
        passenger's bubble still shows, in bigger type.
      - No text anywhere is cut off or spills out of its box: the pills, the
        ticket, the rules, the buttons and every card, the ending's too. (The
        tests check this with Roblox's own font widths, but without kerning,
        which can make text a few percent wider or narrower; and on a TV they
        see only the first night's card.)
      - In Roblox's Settings (Esc, then Settings), set Text Size to the
        largest, on a phone and on a PC:
        - the rules, the passenger's bubble, the radio, the manifest, the
          ledger, the hint, the status pills and the cards' words are all
          bigger, and still fit. The bubble wraps into more lines; on small
          phones the longest lines may sit over the top bar row, or be drawn
          a little smaller so they stay on screen. The pills drop the date
          first.
        - The ticket, the buttons, the tabs, the card headings and the
          countdown stay their usual size, by design (their boxes can't
          grow). Say whether they're readable enough at that setting.
        - Roblox doesn't publish how much bigger each setting draws text; the
          tests guess 8 px at the largest. If it's more, look hardest at the
          bubble on an iPhone SE and at "The next passenger is coming up the
          dock..." on the desk.
      - Mara (the smallest passenger) has a normal-looking classic head.
- [ ] **Test → Clients and Servers**, 2 players:
      - both see the same passenger;
      - either can make the call;
      - the Continue card shows "1 of 2 ready" until both press it, or the
        timer runs out;
      - a player who joins mid-shift appears in the booth, capped, looking at
        the passenger from their stand, with the whole line in the bubble
        (Roblox can take a few seconds to load the bubble's font for a new
        player; the bubble resizes once it has).
- [ ] With API services enabled, finish a run, stop, and play again: the pier
      banner and the player list show the endings you've found.

## Tuning knobs

| What | Where | Now |
| --- | --- | --- |
| Time per passenger | `Config.DecisionTime` | 45 s |
| Intro / summary / ending timers | `Config.IntroTime`, `SummaryTime`, `EndingTime` | 30 / 25 / 60 s |
| Passenger walking speed | `Config.WalkSpeed` | 7 studs/s |
| Clerks' walking speed on shift | `SHIFT_WALK_SPEED` in `CrewService` | 10 studs/s |
| Eye height in the booth | `EYE_HEIGHT` in `CameraController` | 5.1 studs |
| How far out the pier camera can zoom | `StarterPlayer.CameraMaxZoomDistance` (project file) | 25 studs |
| The passenger's speech bubble (text size, width, height above the head) | `ReplicatedStorage/Ui/Speech.luau` | 16 px (24 on a TV), text up to 300 px wide (or the room between the ticket and the rules), 0.4 studs up |
| The gap between the bubble and the HUD | `SPEECH_GAP` in `HudController` | 8 design px |
| How much smaller the bubble's line may be drawn, at a big Text Size, to stay on screen | `limits` in `Speech.luau` (`applyDisplay`) | 2 px at a time, down to 16 px (24 on a TV) |
| Which text grows with the player's Text Size | `hold` in `Ui.label` (`Ui.luau`) | all but text whose box can't grow, button labels and tags |
| The status pills in Roblox's top bar row | `ReplicatedStorage/Ui/TopBar.luau` | 44 px pills, 12 px down, near-black at 8% see-through (Roblox's own numbers) |
| Sound volumes and pitches | `ReplicatedStorage/Shared/Sounds.luau` | |
| Queue sizes and difficulty per night | `Content.Nights` | 6 to 9 passengers |
| All story text | `ServerScriptService/Shift/Content.luau` | |
| HUD scale on small screens | `Theme.DesignWidth/Height`, `MinScale` | 960 × 420, 0.66 |
