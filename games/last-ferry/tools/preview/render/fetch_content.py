#!/usr/bin/env python3
"""Downloads the built-in Roblox client textures the previews use (the classic face,
particle sprites, the chat bubble's tail) from the Roblox Client Tracker into rbxcontent/, converting .dds
files to .png. These are Roblox's files: they stay local and are not committed.

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

here = os.path.dirname(os.path.abspath(__file__))
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
