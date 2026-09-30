#!/usr/bin/env python3
"""Downloads the built-in Roblox client content the previews use into rbxcontent/: the
textures (the classic face, particle sprites, the chat bubble's tail) from the Roblox
Client Tracker, converting .dds files to .png, and the fonts the game's text is drawn in
(Builder Sans, and Montserrat, which Roblox draws Gotham as) from a mirror of Studio's
content folder. These are Roblox's files: they stay local and are not committed. (Builder
Sans is under Roblox's Builder Font License, for making and promoting experiences on
Roblox, which this is.)

    python3 fetch_content.py
"""

import io
import os
import urllib.request

from PIL import Image

BASE = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/"
FILES = [
    "textures/face.png",
    "textures/particles/smoke_main.dds",
    "textures/particles/sparkles_main.dds",
    "textures/particles/fire_main.dds",
    "textures/sparkle.png",
    "textures/ui/InGameChat/Caret.png",
]

FONTS_BASE = "https://raw.githubusercontent.com/suscersal/roblox-studio-web/main/content/"
FONTS = [
    f"fonts/{name}"
    for name in [
        "BuilderSans-Regular.otf",
        "BuilderSans-Medium.otf",
        "BuilderSans-Bold.otf",
        "BuilderSans-ExtraBold.otf",
        "Montserrat-Regular.ttf",
        "Montserrat-Medium.ttf",
        "Montserrat-Bold.ttf",
        "Montserrat-Black.ttf",
        "FredokaOne-Regular.ttf",
        "Oswald-Regular.ttf",
        "Oswald-Bold.ttf",
        "SpecialElite-Regular.ttf",
    ]
]

here = os.path.dirname(os.path.abspath(__file__))
for path in FONTS:
    out = os.path.join(here, "rbxcontent", path)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "wb") as f:
        f.write(urllib.request.urlopen(FONTS_BASE + path, timeout=60).read())
    print("fetched", out)
for path in FILES:
    data = urllib.request.urlopen(BASE + path, timeout=60).read()
    out = os.path.join(here, "rbxcontent", path)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    if path.endswith(".dds"):
        out = out[: -len(".dds")] + ".png"
        Image.open(io.BytesIO(data)).save(out)
    else:
        with open(out, "wb") as f:
            f.write(data)
    print("fetched", out)
