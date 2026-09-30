#!/usr/bin/env python3
"""Blockout preview of the booth camera's view, from a scene exported by
tools/preview/export.luau.

A small numpy ray tracer: boxes, cylinders and balls with Roblox's conventions
(cylinders run along their X axis), the booth lamp as a spotlight with shadows,
dim moonlight, the booth's own warm light, neon glow, distance fog, and the
passengers' breath and drips drawn as puffs.

It is a layout and readability check, not Roblox's renderer: no textures, no
materials, no reflections, no Future lighting. Use it to see what's in frame,
where shadows fall, and what the HUD might cover; judge looks in Studio.

    python3 tools/preview/render.py preview/first.json preview/first.png [--hud] [--shadows]

--hud draws the HUD regions (at a 960-wide screen) over the view.
--shadows tints everything in the booth lamp's shadow red, to check the shadow tell.
"""

import json
import math
import sys

import numpy as np
from PIL import Image, ImageDraw

WIDTH, HEIGHT = 960, 540
VERTICAL_FOV = 70.0
FOG = np.array([150, 165, 182]) / 255.0 * 0.32
FOG_PER_STUD = 0.013
AMBIENT = np.array([0.16, 0.18, 0.24])
MOON_DIR = np.array([0.35, 1.0, 0.25]) / np.linalg.norm([0.35, 1.0, 0.25])
MOON = np.array([0.20, 0.24, 0.34])
INTERIOR = {"pos": np.array([0.0, 2.9, 1.2]), "range": 9.0, "color": np.array([1.0, 0.78, 0.52]) * 0.55}
WATER = np.array([22, 40, 44]) / 255.0
EPS = 1e-4


def frame(components):
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = components
    rotation = np.array([[r00, r01, r02], [r10, r11, r12], [r20, r21, r22]])
    return np.array([x, y, z]), rotation


def to_local(origins, dirs, center, rotation):
    return (origins - center) @ rotation, dirs @ rotation


def hit_box(origins, dirs, center, rotation, size):
    lo, ld = to_local(origins, dirs, center, rotation)
    half = np.asarray(size) / 2
    with np.errstate(divide="ignore", invalid="ignore"):
        inv = 1.0 / ld
        t1 = (-half - lo) * inv
        t2 = (half - lo) * inv
    near = np.minimum(t1, t2)
    far = np.maximum(t1, t2)
    tmin = np.nanmax(near, axis=1)
    tmax = np.nanmin(far, axis=1)
    t = np.where(tmin > EPS, tmin, tmax)
    ok = (tmax >= np.maximum(tmin, EPS)) & (t > EPS)
    axis = np.nanargmax(near, axis=1)
    rows = np.arange(len(t))
    normal = np.zeros_like(lo)
    normal[rows, axis] = -np.sign(ld[rows, axis])
    return np.where(ok, t, np.inf), normal @ rotation.T


def hit_cylinder(origins, dirs, center, rotation, size):
    lo, ld = to_local(origins, dirs, center, rotation)
    radius = min(size[1], size[2]) / 2
    half = size[0] / 2
    best = np.full(len(lo), np.inf)
    normal = np.zeros_like(lo)
    a = ld[:, 1] ** 2 + ld[:, 2] ** 2
    b = 2 * (lo[:, 1] * ld[:, 1] + lo[:, 2] * ld[:, 2])
    c = lo[:, 1] ** 2 + lo[:, 2] ** 2 - radius**2
    disc = b * b - 4 * a * c
    with np.errstate(divide="ignore", invalid="ignore"):
        root = np.sqrt(np.maximum(disc, 0))
        for sign in (-1, 1):
            t = (-b + sign * root) / (2 * a)
            x = lo[:, 0] + t * ld[:, 0]
            ok = (disc >= 0) & (a > 1e-12) & (t > EPS) & (np.abs(x) <= half) & (t < best)
            best = np.where(ok, t, best)
            side = np.stack([np.zeros_like(t), lo[:, 1] + t * ld[:, 1], lo[:, 2] + t * ld[:, 2]], axis=1) / radius
            normal = np.where(ok[:, None], side, normal)
        for cap in (-half, half):
            t = (cap - lo[:, 0]) / ld[:, 0]
            y = lo[:, 1] + t * ld[:, 1]
            z = lo[:, 2] + t * ld[:, 2]
            ok = (t > EPS) & (y * y + z * z <= radius**2) & (t < best)
            best = np.where(ok, t, best)
            cap_normal = np.zeros_like(lo)
            cap_normal[:, 0] = np.sign(cap)
            normal = np.where(ok[:, None], cap_normal, normal)
    return best, normal @ rotation.T


def hit_ball(origins, dirs, center, size):
    radius = min(size) / 2
    oc = origins - center
    b = np.einsum("ij,ij->i", oc, dirs)
    c = np.einsum("ij,ij->i", oc, oc) - radius**2
    disc = b * b - c
    root = np.sqrt(np.maximum(disc, 0))
    t = -b - root
    t = np.where(t > EPS, t, -b + root)
    ok = (disc >= 0) & (t > EPS)
    t = np.where(ok, t, np.inf)
    point = origins + dirs * np.where(np.isfinite(t), t, 0)[:, None]
    return t, (point - center) / radius


def intersect(part, origins, dirs):
    center, rotation = part["_frame"]
    if part["shape"] == "Cylinder":
        return hit_cylinder(origins, dirs, center, rotation, part["size"])
    if part["shape"] == "Ball":
        return hit_ball(origins, dirs, center, part["size"])
    return hit_box(origins, dirs, center, rotation, part["size"])


def blocked(parts, origins, dirs, limits):
    """True where something that casts a shadow lies between origin and origin + dir * limit."""
    shade = np.zeros(len(origins), dtype=bool)
    for part in parts:
        if not part["castShadow"] or part["transparency"] > 0.5 or part["material"] == "Neon":
            continue
        t, _ = intersect(part, origins, dirs)
        shade |= t < limits - 0.05
    return shade


def render(scene, hud=False, debug_shadows=False):
    parts = scene["parts"]
    for part in parts:
        part["_frame"] = frame(part["cframe"])
    solid = [p for p in parts if p["transparency"] < 0.8]

    eye, rotation = frame(scene["camera"])
    right, up, back = rotation[:, 0], rotation[:, 1], rotation[:, 2]
    forward = -back
    tan_v = math.tan(math.radians(VERTICAL_FOV / 2))
    tan_h = tan_v * WIDTH / HEIGHT
    xs = (np.arange(WIDTH) + 0.5) / WIDTH * 2 - 1
    ys = 1 - (np.arange(HEIGHT) + 0.5) / HEIGHT * 2
    grid_x, grid_y = np.meshgrid(xs, ys)
    dirs = forward + grid_x[..., None] * tan_h * right + grid_y[..., None] * tan_v * up
    dirs = (dirs / np.linalg.norm(dirs, axis=2, keepdims=True)).reshape(-1, 3)
    origins = np.broadcast_to(eye, dirs.shape).copy()
    count = len(dirs)

    depth = np.full(count, np.inf)
    normal = np.zeros((count, 3))
    color = np.tile(FOG, (count, 1))
    neon = np.zeros(count, dtype=bool)
    for part in solid:
        t, n = intersect(part, origins, dirs)
        closer = t < depth
        depth = np.where(closer, t, depth)
        normal = np.where(closer[:, None], n, normal)
        color = np.where(closer[:, None], np.asarray(part["color"]), color)
        neon = np.where(closer, part["material"] == "Neon", neon)

    # Harbor water below the planks.
    with np.errstate(divide="ignore", invalid="ignore"):
        t_water = (scene["waterLevel"] - origins[:, 1]) / dirs[:, 1]
    water = (dirs[:, 1] < 0) & (t_water > 0) & (t_water < depth)
    depth = np.where(water, t_water, depth)
    normal = np.where(water[:, None], np.array([0.0, 1.0, 0.0]), normal)
    color = np.where(water[:, None], WATER, color)

    hit = np.isfinite(depth)
    points = origins + dirs * np.where(hit, depth, 0)[:, None]
    facing = np.einsum("ij,ij->i", normal, dirs) > 0
    normal = np.where(facing[:, None], -normal, normal)

    light = np.tile(AMBIENT, (count, 1))
    light += np.clip(normal @ MOON_DIR, 0, 1)[:, None] * MOON

    # The booth lamp: a spotlight with shadows.
    lamp = scene["lamp"]
    lamp_pos, lamp_rot = frame(lamp["cframe"])
    lamp_dir = -lamp_rot[:, 2]
    to_lamp = lamp_pos - points
    dist = np.linalg.norm(to_lamp, axis=1)
    to_lamp_unit = to_lamp / np.maximum(dist, 1e-6)[:, None]
    cone = (-to_lamp_unit @ lamp_dir) >= math.cos(math.radians(lamp["angle"] / 2))
    lit = hit & cone & (dist < lamp["range"])
    n_dot = np.clip(np.einsum("ij,ij->i", normal, to_lamp_unit), 0, 1)
    candidates = np.nonzero(lit & (n_dot > 0))[0]
    shadowed = np.zeros(count, dtype=bool)
    if len(candidates):
        starts = points[candidates] + normal[candidates] * 0.02
        shadowed[candidates] = blocked(solid, starts, to_lamp_unit[candidates], dist[candidates])
    falloff = np.clip(1 - dist / lamp["range"], 0, 1) ** 1.5
    lamp_color = np.asarray(lamp["color"])
    strength = np.where(lit & ~shadowed, n_dot * falloff * lamp["brightness"] * 0.55, 0)
    light += strength[:, None] * lamp_color

    # The booth's own warm light on the counter.
    to_inside = INTERIOR["pos"] - points
    inside_dist = np.linalg.norm(to_inside, axis=1)
    inside = np.clip(1 - inside_dist / INTERIOR["range"], 0, 1) * np.clip(
        np.einsum("ij,ij->i", normal, to_inside / np.maximum(inside_dist, 1e-6)[:, None]), 0, 1
    )
    light += inside[:, None] * INTERIOR["color"]

    shaded = color * light
    shaded = np.where(neon[:, None], np.clip(color * 1.25, 0, 1), shaded)
    if debug_shadows:
        in_shadow = lit & shadowed & (n_dot > 0)
        shaded = np.where(in_shadow[:, None], shaded * 0.4 + np.array([0.6, 0.0, 0.0]), shaded)

    fog = 1 - np.exp(-FOG_PER_STUD * np.where(hit, depth, 1e4))
    fog = np.where(neon, fog * 0.6, fog)
    shaded = shaded * (1 - fog[:, None]) + FOG * fog[:, None]

    # Breath puffs and drips, drawn over whatever is behind them.
    for emitter in scene["emitters"]:
        position = np.asarray(emitter["position"])
        if emitter["name"] == "Breath":
            ahead = np.asarray(emitter["facing"])
            puffs = [(position + ahead * s + np.array([0, 0.08 * s, 0]), r) for s, r in ((0.35, 0.16), (0.8, 0.3), (1.35, 0.45))]
            tint, alpha = np.array([0.85, 0.88, 0.92]), 0.28
        else:
            puffs = [(position + np.array([0, -dy, 0]), 0.12) for dy in (0.15, 0.55, 0.95)]
            tint, alpha = np.array([0.78, 0.88, 0.92]), 0.75
        for center, radius in puffs:
            t, _ = hit_ball(origins, dirs, center, [radius * 2] * 3)
            front = t < depth
            shaded = np.where(front[:, None], shaded * (1 - alpha) + tint * alpha, shaded)

    image = np.clip(shaded, 0, 1) ** (1 / 2.2)
    img = Image.fromarray((image.reshape(HEIGHT, WIDTH, 3) * 255).astype(np.uint8))
    if hud:
        draw_hud(img)
    return img


def draw_hud(img):
    """Outlines of the HUD regions at 1280 x 720 (scale 4/3 of the 960 x 420 canvas's width)."""
    draw = ImageDraw.Draw(img, "RGBA")
    s = WIDTH / 960  # this image is 960 wide: the design canvas maps 1:1 horizontally
    top = 70 * s
    boxes = [
        ("ticket", (16, top, 16 + 250, top + 190)),
        ("page tab", (16 + 250 - 28, top + 40, 16 + 250 - 28 + 100, top + 116)),
        ("BOARD", (16, top + 236, 16 + 119, top + 300)),
        ("TURN AWAY", (16 + 131, top + 236, 16 + 250, top + 300)),
        ("rules / manifest", (WIDTH - 16 - 250, top, WIDTH - 16, HEIGHT - 16)),
        ("speech", (WIDTH / 2 + 30 - 150, 56, WIDTH / 2 + 30 + 150, 120)),
        ("top bar", (16, 6, WIDTH - 16, 62)),
    ]
    for label, (x0, y0, x1, y1) in boxes:
        draw.rectangle((x0, y0, x1, y1), outline=(255, 220, 160, 220), width=2, fill=(20, 25, 32, 90))
        draw.text((x0 + 6, y0 + 4), label, fill=(255, 230, 190, 255))


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    scene = json.load(open(sys.argv[1]))
    image = render(scene, hud="--hud" in sys.argv, debug_shadows="--shadows" in sys.argv)
    image.save(sys.argv[2])
    print(f"wrote {sys.argv[2]}")


if __name__ == "__main__":
    main()
