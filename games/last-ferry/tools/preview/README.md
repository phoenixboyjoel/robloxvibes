# Previews without Studio

Renders what a player would see, from the real game running in the headless
simulator (`tests/sim`), using a three.js approximation of Roblox's renderer.

1. **Export a scene.** The game runs until the scenario is on screen, then the
   whole scene is written to JSON: every part, light, decal, particle emitter and
   SurfaceGui, the Lighting settings, the camera, and the player's ScreenGuis.

   ```sh
   lune run tools/preview/export.luau first preview/first.json --screen=1280,720 --safe=1280,662
   ```

   | Scenario | What's on screen |
   | --- | --- |
   | `first` | The first passenger of night 1 at the window |
   | `wet` | The first dripping passenger of night 1 (one of the drowned) |
   | `intro` | The night 1 title card |
   | `queue` | Between passengers, with the queue walking up |

   `--screen` and `--safe` set the screen and its safe area in pixels. A 58 px top
   inset matches Roblox's current top bar on desktop. `--touch` makes the game see
   a phone.

2. **Render it.** This needs Node and Chromium, but no GPU (WebGL runs in
   software).

   ```sh
   cd tools/preview/render
   npm install                   # three.js, fonts, Playwright
   npx playwright install chromium   # skip if Chromium is already installed for Playwright
   python3 fetch_content.py      # Roblox's built-in face and particle textures (needs Pillow)
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
    corners, gradients) and the same fonts. Builder Sans and Gotham aren't public,
    so Inter and Montserrat stand in for them.
- **Approximate:**
  - Materials are procedural stand-ins for Roblox's textures.
  - Light brightness is tuned by eye, and there is no global illumination.
  - Water is a flat reflective plane.
  - Particles are a still frame replayed from the emitter's settings.
  - The top bar in the corner is a sketch of Roblox's, there only to show what the
    safe area keeps clear.
- **Not drawn:** uploaded assets (`rbxassetid://` meshes, images and sounds),
  terrain other than water, and Roblox's own chat bubbles.

Always confirm looks in a Studio playtest before calling them done.
