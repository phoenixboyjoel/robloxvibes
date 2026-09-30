#!/usr/bin/env python3
"""Builds tests/sim/reflection.json from a Roblox API dump.

The simulator (tests/sim/Roblox.luau) uses it to hold mock instances to the real
engine's rules: which members exist, their value types, what scripts may read or
write, and what is deprecated.

Usage:
    python3 tests/sim/gen_reflection.py path/to/API-Dump.json

Get the dump from the Roblox client tracker:
https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
"""

import json
import os
import sys

# Every class the game creates or touches. Superclasses are added automatically.
CLASSES = [
    # Created with Instance.new
    "Part", "Folder", "Model", "SurfaceGui", "TextLabel", "TextButton", "Frame",
    "ScrollingFrame", "ScreenGui", "UIPadding", "UIListLayout", "UICorner", "UIStroke",
    "UIScale", "CFrameValue", "Atmosphere", "PointLight", "SpotLight", "Attachment",
    "ParticleEmitter", "WeldConstraint", "RemoteEvent", "ColorCorrectionEffect", "BlurEffect",
    "WedgePart", "Seat", "SpawnLocation", "Motor6D", "Weld", "Humanoid", "SpecialMesh", "Decal",
    "Accessory", "BodyColors", "BillboardGui", "ImageLabel", "UIGradient", "UIAspectRatioConstraint",
    "UISizeConstraint", "UITextSizeConstraint", "Sound", "Highlight", "Sky", "BloomEffect",
    "SunRaysEffect", "TextChannel", "ProximityPrompt", "CanvasGroup", "ImageButton", "UIShadow",
    "IntValue", "NumberValue", "StringValue",
    # Services and objects the engine provides
    "DataModel", "Workspace", "Players", "Player", "PlayerGui", "ReplicatedStorage",
    "ServerScriptService", "RunService", "TweenService", "Tween", "Lighting", "Terrain",
    "Camera", "DataStoreService", "DataStore", "BadgeService", "StarterGui", "GuiService",
    "UserInputService", "InputObject", "TextChatService", "ChatWindowConfiguration",
    "BubbleChatConfiguration", "SoundService", "StarterPlayer", "ContextActionService",
    "ProximityPromptService",
]

SCRIPT_OK = {"None"}


def main(dump_path: str) -> None:
    dump = json.load(open(dump_path))
    by_name = {c["Name"]: c for c in dump["Classes"]}

    wanted = []
    for name in CLASSES:
        while name and name != "<<<ROOT>>>":
            if name not in wanted:
                wanted.append(name)
            name = by_name[name].get("Superclass")

    classes = {}
    for name in sorted(wanted):
        c = by_name[name]
        props, events, functions = {}, {}, {}
        for m in c["Members"]:
            tags = m.get("Tags", [])
            security = m.get("Security", "None")
            deprecated = "Deprecated" in tags
            if m["MemberType"] == "Property":
                if "NotScriptable" in tags:
                    continue
                read = security.get("Read", "None") if isinstance(security, dict) else security
                write = security.get("Write", "None") if isinstance(security, dict) else security
                if read not in SCRIPT_OK:
                    continue
                vt = m["ValueType"]
                props[m["Name"]] = {
                    "category": vt["Category"],
                    "type": vt["Name"],
                    "readOnly": "ReadOnly" in tags or write not in SCRIPT_OK,
                    "deprecated": deprecated,
                }
            elif m["MemberType"] == "Event":
                if security in SCRIPT_OK:
                    events[m["Name"]] = {"deprecated": deprecated}
            elif m["MemberType"] in ("Function", "Callback"):
                if security in SCRIPT_OK:
                    functions[m["Name"]] = {"deprecated": deprecated, "yields": "Yields" in tags}
        classes[name] = {
            "superclass": c.get("Superclass"),
            "creatable": "NotCreatable" not in c.get("Tags", []) and "Service" not in c.get("Tags", []),
            "service": "Service" in c.get("Tags", []),
            "properties": props,
            "events": events,
            "functions": functions,
        }

    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "reflection.json")
    with open(out, "w") as f:
        json.dump({"classes": classes}, f, indent=1, sort_keys=True)
    print(f"wrote {out}: {len(classes)} classes")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
