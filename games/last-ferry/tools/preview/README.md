# Previews without Studio

Renders what a player would see, from the real game running in the headless
simulator (`tests/sim`), using a three.js approximation of Roblox's renderer.

1. **Export a scene.** The game runs until the scenario is on screen, then the
   whole scene is written to JSON: every part, light, decal, particle emitter and
   SurfaceGui, the Lighting settings, the camera, the player's ScreenGuis (the
   HUD, the status in Roblox's top bar row, the passenger's speech bubble) and
   BillboardGuis, Roblox chat bubbles they can see, and their character (for
   prompts in reach).
   The simulator stands in for Roblox's default camera (`sim.cameraFollows`):
   third person behind the avatar on the pier, first person at the head in the
   booth (with Humanoid.CameraOffset, and the avatar hidden from its own
   camera the way Roblox does it).

   ```sh
   lune run tools/preview/export.luau first preview/first.json --screen=1280,720 --safe=1280,662
   ```

   | Scenario | What's on screen |
   | --- | --- |
   | `lobby` | Three avatars on the pier, one at the time clock with its "Clock in" prompt up |
   | `first` | The first passenger of night 1 at the window, in first person |
   | `wet` | The first dripping passenger of night 1 (one of the drowned) |
   | `intro` | The night 1 title card, just after clocking in |
   | `queue` | Between passengers, with the queue walking up |
   | `summary` | The end-of-night card after boarding everyone (right and wrong calls) |
   | `crew` | Three clerks in their caps behind the counter, seen from the dock (no HUD) |
   | `lineup` | The whole passenger wardrobe in daylight (no HUD) |
   | `pier` | The empty pier behind the booth (no HUD) |

   `--screen` and `--safe` set the screen and its safe area in pixels. The
   default safe area leaves a 58 px top inset, below Roblox's current top bar,
   which is where `CoreUISafeInsets` puts a ScreenGui. `--touch` makes the game
   see a phone: for a phone in landscape try
   `--screen=844,390 --safe=750,332 --touch`.

2. **Render it.** This needs Node and Chromium, but no GPU (WebGL runs in
   software).

   ```sh
   cd tools/preview/render
   npm install                   # three.js, fonts, Playwright
   npx playwright install chromium   # skip if Chromium is already installed for Playwright
   python3 fetch_content.py      # Roblox's face, particle and chat-tail textures and its fonts (needs Pillow)
   node shot.mjs ../../../preview/first.json ../../../preview/first.png
   ```

## What it gets right, and what it doesn't

The renderer is close enough to judge layout, framing, readability, colour, and
whether a tell can be seen from the booth. It is not Roblox's renderer.

- **Close to Roblox:**
  - Part shapes (blocks, balls, cylinders, wedges, and the classic head mesh);
  - Roblox's own face decal and particle sprites (fetched locally, never
    committed);
  - point and spot lights with shadows, Atmosphere fog, a night sky, Neon glow,
    ColorCorrection and Blur;
  - the HUD, drawn from the real GUI tree with Roblox's layout rules (UDim2,
    anchors, list layouts, padding, automatic size, UIScale, rich text, strokes,
    corners, gradients, UIShadow, rotation) and Roblox's own font files for the
    fonts the game uses (Builder Sans; Montserrat, which Roblox draws Gotham as;
    Fredoka One, Oswald, Special Elite), fetched by `fetch_content.py`, with
    look-alikes from @fontsource for any it hasn't fetched;
  - Roblox's own chat bubbles (anchored over a model's bounding box, as the
    client's ExperienceChat does) and its default ProximityPrompt, both drawn
    from the client's own layout numbers;
  - BillboardGuis in the PlayerGui, drawn where their Adornee is on screen
    (StudsOffset, StudsOffsetWorldSpace, SizeOffset), with the HUD over them
    as in Roblox.
- **Approximate:**
  - Materials are procedural stand-ins for Roblox's textures.
  - Light brightness is tuned by eye, and there is no global illumination.
  - Water is a flat reflective plane.
  - Particles are a still frame replayed from the emitter's settings.
  - Text measured by the game (`TextBounds`) comes from the simulator, which
    adds up each character's width in the font (no kerning), so a line can
    come out a pixel or two different from Roblox's.
  - Roblox's buttons in the top-left corner are a sketch of Roblox's. ScreenGuis
    with `TopbarSafeInsets` are drawn beside them, in the part of the row the
    simulator's `GuiService.TopbarInset` leaves, which is an estimate.
- **Not drawn:** uploaded assets (`rbxassetid://` meshes, images and sounds),
  terrain other than water, the touch thumbstick and jump button, the chat
  window and the player list. Player avatars are the simulator's blocky R15 in
  plain colours, not real avatars with clothing and accessories.

Always confirm looks in a Studio playtest before calling them done.
