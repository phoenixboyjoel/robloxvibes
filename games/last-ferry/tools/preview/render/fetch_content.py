#!/usr/bin/env python3
"""Downloads the built-in Roblox client content the previews use into rbxcontent/: the
textures (the classic face, particle sprites, the chat bubble's tail) from the Roblox
Client Tracker, converting .dds files to .png, and the fonts the game's text is drawn in
(Builder Sans, and Montserrat, which Roblox draws Gotham as) from a mirror of Studio's
content folder. These are Roblox's files: they stay local and are not committed. (Builder
Sans is under Roblox's Builder Font License, for making and promoting experiences on
Roblox, which this is.)

Both sources are pinned to a commit, and every file is checked against its SHA-256 before
it's saved: a file that has changed, or been tampered with, stops the download.

    python3 fetch_content.py
"""

import hashlib
import io
import os
import sys
import urllib.request

from PIL import Image

# The Roblox Client Tracker's "roblox" branch (a copy of the client's own content folder).
TRACKER = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/fcd6994996bb655bef047c69f456463d94faa569/"
FILES = {
    "textures/face.png": "a45ca21d310953cb2bb68608f02b6a24a4ad6f6e833a328cbd4e13328475d692",
    "textures/particles/smoke_main.dds": "27ed2e689b5be44d0dc01b125d174511de4f875402cb19ca9b3bbb386c76632e",
    "textures/particles/sparkles_main.dds": "3e52b300742ee9e267c32d5886842e21b4a5f065906c224dd4e22a72b94ee8cc",
    "textures/particles/fire_main.dds": "99fbc2dabf7cd4fe2efa1e46b7ab2537288ee95cef626f0752b8af26ff392eb8",
    "textures/sparkle.png": "24fca26f50f4cb74392981784d635c31bede4129a4b120e62ed7ab348ce7a9c0",
    "textures/ui/InGameChat/Caret.png": "6626304046639dc65946ee94e2e4391f7de76c70b73886091070591125e580bb",
}

# A mirror of Studio's content folder (the client's fonts aren't in the tracker).
STUDIO = "https://raw.githubusercontent.com/suscersal/roblox-studio-web/b7285b9d773a8f952668d5353a5275248816c050/content/"
FONTS = {
    "fonts/BuilderSans-Regular.otf": "40a248a2229bdd7f0c8f924ef8c94356437d903ac58cf69a06217b9382e88af4",
    "fonts/BuilderSans-Medium.otf": "9f2d5253ab8ecefddfdebaef4c578eb3d1a2985589615604982d84fcabf6221d",
    "fonts/BuilderSans-Bold.otf": "30a9f5a26fd341c2b4a8ee1418b3061445c7c6ce8b4b2565b04480c1b1328af4",
    "fonts/BuilderSans-ExtraBold.otf": "0837070a1713fc7647e74ec51b80ab9d4bce6af5448117c5711bc8a139f3adf0",
    "fonts/Montserrat-Regular.ttf": "dcfe8df29e553fbd655212f94300cb1e704c6cd147fa7a98cb4bcd9eb92c6707",
    "fonts/Montserrat-Medium.ttf": "20ebfd658f55a256d60b4f84849e0026e4b599926493738ed3952c7200218d33",
    "fonts/Montserrat-Bold.ttf": "189aeb285be99f0b58e454dd2dc3cbf34a6db844a9ef26ebc5909178ff77c5be",
    "fonts/Montserrat-Black.ttf": "9d0664ef22c8dbedb44861879d1f6d53d53b1d0e37f4e8e4bcfc62fc0285005d",
    "fonts/FredokaOne-Regular.ttf": "08a0193637baffaa1d9926085fe2a2716c1ce06136b74a9627e61663649c0f37",
    "fonts/Oswald-Regular.ttf": "264639732f5adf80fac1e4a9ef3f0eb58e58b5aead07850087662dedeba11b12",
    "fonts/Oswald-Bold.ttf": "adecc04bd3ae99a835a7bae9de0f261fdd5a6da1630daf000602034fb142052b",
    "fonts/SpecialElite-Regular.ttf": "9398ee3a3796482b70bb1731ab9b581ed1b84127a3d7179ae6a6ce3487377ebc",
}


def fetch(url: str, sha256: str) -> bytes:
    data = urllib.request.urlopen(url, timeout=60).read()
    found = hashlib.sha256(data).hexdigest()
    if found != sha256:
        sys.exit(f"{url}: SHA-256 is {found}, expected {sha256}")
    return data


here = os.path.dirname(os.path.abspath(__file__))
for base, files in ((STUDIO, FONTS), (TRACKER, FILES)):
    for path, sha256 in files.items():
        data = fetch(base + path, sha256)
        out = os.path.join(here, "rbxcontent", path)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        if path.endswith(".dds"):
            out = out[: -len(".dds")] + ".png"
            Image.open(io.BytesIO(data)).save(out)
        else:
            with open(out, "wb") as f:
                f.write(data)
        print("fetched", out)
