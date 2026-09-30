#!/usr/bin/env python3
"""Builds tests/sim/fonts.json: how wide each character is in the fonts the game uses.

The simulator (tests/sim/Roblox.luau) measures text with it, so TextBounds and
automatically sized GUI come out close to Roblox's: each character's advance width, as
a share of the text size, from Roblox's own font files (no kerning).

Usage:
    python3 tests/sim/gen_fonts.py path/to/content/fonts

`content/fonts` is the folder of fonts that ships with the Roblox client and Studio;
every face the game uses is in it. A mirror of Studio's:
https://github.com/suscersal/roblox-studio-web/tree/main/content/fonts
Only the widths are kept, not the fonts. (Builder Sans is Roblox's, under its Builder
Font License: for making experiences on Roblox, which this is.)
"""

import json
import os
import struct
import sys

# The families the game draws text in, by the name in their Font's family path
# ("rbxasset://fonts/families/BuilderSans.json"), and the faces of each that ship with
# the client, by weight. Gotham is gone: Roblox draws it as Montserrat.
FACES = {
    "BuilderSans": {
        400: "BuilderSans-Regular.otf",
        500: "BuilderSans-Medium.otf",
        700: "BuilderSans-Bold.otf",
        800: "BuilderSans-ExtraBold.otf",
    },
    "Montserrat": {
        400: "Montserrat-Regular.ttf",
        500: "Montserrat-Medium.ttf",
        700: "Montserrat-Bold.ttf",
        900: "Montserrat-Black.ttf",
    },
    "FredokaOne": {400: "FredokaOne-Regular.ttf"},
    "Oswald": {400: "Oswald-Regular.ttf", 700: "Oswald-Bold.ttf"},
    "SpecialElite": {400: "SpecialElite-Regular.ttf"},
}

# Printable ASCII, and the other characters the game shows.
CHARACTERS = "".join(chr(code) for code in range(32, 127)) + "·–—‘’“”…é°×→"


def tables(data: bytes) -> dict:
    """The font's tables, by tag."""
    count = struct.unpack(">H", data[4:6])[0]
    found = {}
    for i in range(count):
        tag, _, offset, length = struct.unpack(">4sIII", data[12 + 16 * i : 28 + 16 * i])
        found[tag.decode("latin-1")] = data[offset : offset + length]
    return found


def glyph_finder(cmap: bytes):
    """Which glyph draws a character, from the font's Unicode character map (format 4)."""
    count = struct.unpack(">H", cmap[2:4])[0]
    start = None
    for i in range(count):
        platform, encoding, offset = struct.unpack(">HHI", cmap[4 + 8 * i : 12 + 8 * i])
        if struct.unpack(">H", cmap[offset : offset + 2])[0] != 4:
            continue
        if (platform, encoding) == (3, 1) or (platform == 0 and start is None):
            start = offset
    if start is None:
        sys.exit("no Unicode character map (format 4) in the font")

    def u16(at: int) -> int:
        return struct.unpack(">H", cmap[at : at + 2])[0]

    def s16(at: int) -> int:
        return struct.unpack(">h", cmap[at : at + 2])[0]

    double = u16(start + 6)
    ends = start + 14
    starts = ends + double + 2
    deltas = starts + double
    ranges = deltas + double

    def glyph(code: int) -> int:
        for segment in range(double // 2):
            if code > u16(ends + 2 * segment):
                continue
            first = u16(starts + 2 * segment)
            if code < first:
                return 0
            delta = s16(deltas + 2 * segment)
            range_offset = u16(ranges + 2 * segment)
            if range_offset == 0:
                return (code + delta) & 0xFFFF
            found = u16(ranges + 2 * segment + range_offset + 2 * (code - first))
            return (found + delta) & 0xFFFF if found else 0
        return 0

    return glyph


def widths(path: str) -> dict:
    """Each character's advance width, as a share of the text size."""
    data = open(path, "rb").read()
    found = tables(data)
    units = struct.unpack(">H", found["head"][18:20])[0]
    metrics = struct.unpack(">H", found["hhea"][34:36])[0]
    hmtx = found["hmtx"]
    advances = [struct.unpack(">H", hmtx[4 * i : 4 * i + 2])[0] for i in range(metrics)]
    glyph = glyph_finder(found["cmap"])
    result = {}
    for character in CHARACTERS:
        index = glyph(ord(character))
        if index == 0:
            continue  # not in this font
        advance = advances[index] if index < metrics else advances[-1]
        result[character] = round(advance / units, 4)
    return result


def main(folder: str) -> None:
    families = {}
    for family, faces in FACES.items():
        families[family] = {str(weight): widths(os.path.join(folder, name)) for weight, name in faces.items()}
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fonts.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(families, f, indent=1, sort_keys=True, ensure_ascii=False)
    print(f"wrote {out}: {sum(len(faces) for faces in families.values())} faces")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
