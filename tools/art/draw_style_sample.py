#!/usr/bin/env python3
"""Player style sample sheet v1 for Road Trip Hoops (original art, no downloaded assets).

Draws four original streetball players (two crews) as pixel art in the angled 3/4 view.
Each figure is built from simple 3D shapes (spheres and ellipsoids for head, muscles and
limbs), rendered at 1x with an orthographic camera tilted down, shaded in 4 tones with the
light from the upper left, then given bold dark outlines and a cleanup pass. Faces on the
small sprites are placed pixel by pixel; the close-up portraits use procedural features.

Usage:  python3 tools/art/draw_style_sample.py
Output: docs/art/style_sample_v1.png (sheet, 4x) and docs/art/style_sample_v1_sprites/*.png (1x)
Needs:  Pillow, numpy
"""
import colorsys
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from pixel3d import *  # noqa: F401,F403  (renderer, palettes, constants)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_SHEET = os.path.join(ROOT, "docs", "art", "style_sample_v1.png")
OUT_DIR = os.path.join(ROOT, "docs", "art", "style_sample_v1_sprites")

ZOOM = 4                           # sheet enlargement


# ----------------------------------------------------------------------------- players

PLAYERS = [
    {
        "id": "a1_lanky_wing", "desc": "tank, arm sleeve, long shorts", "crew": "A", "label": "Crew A  #7  lanky wing",
        "skin": "deep", "number": 7,
        "leg": 1.10, "torso": 1.05, "width": 0.94, "mass": -0.10,
        "hair": "twists", "hair_pal": ["#4a3a3c", "#2a2024", "#19121a", "#0c080e"],
        "top": "tank", "top_pal": WHITE, "trim_pal": BLUE,
        "shorts_pal": BLUE, "shorts_trim": WHITE, "shorts_len": 1.12,
        "sleeve": "R", "sleeve_pal": NAVY, "tight": None,
        "sock_pal": WHITE, "sock_len": 0.45, "shoe_pal": WHITE, "shoe_acc": BLUE, "sole_pal": NAVY,
        "beard": False,
    },
    {
        "id": "a2_stocky_guard", "desc": "tee, headband, short shorts", "crew": "A", "label": "Crew A  #2  stocky guard",
        "skin": "light", "number": 2,
        "leg": 0.93, "torso": 0.97, "width": 1.10, "mass": 0.32,
        "hair": "band", "hair_pal": ["#a8724a", "#7a4c30", "#55321f", "#331c14"],
        "band_pal": WHITE,
        "top": "tee", "top_pal": BLUE, "trim_pal": WHITE,
        "shorts_pal": WHITE, "shorts_trim": BLUE, "shorts_len": 0.62,
        "sleeve": None, "sleeve_pal": None, "tight": None,
        "sock_pal": BLUE, "sock_len": 0.16, "shoe_pal": BLUE, "shoe_acc": WHITE, "sole_pal": WHITE,
        "beard": False,
    },
    {
        "id": "b1_stocky_big", "desc": "sleeveless hoodie, beard", "crew": "B", "label": "Crew B  #5  stocky big",
        "skin": "brown", "number": 5,
        "leg": 0.97, "torso": 1.02, "width": 1.14, "mass": 0.38,
        "hair": "bald", "hair_pal": ["#3a2a26", "#221814", "#140e0e", "#0a0608"],
        "top": "hoodie", "top_pal": BLACK, "trim_pal": RED,
        "shorts_pal": RED, "shorts_trim": BLACK, "shorts_len": 0.78,
        "sleeve": None, "sleeve_pal": None, "tight": None,
        "sock_pal": GREYW, "sock_len": 0.30, "shoe_pal": BLACK, "shoe_acc": RED, "sole_pal": RED,
        "beard": True,
    },
    {
        "id": "b2_lanky_guard", "desc": "long tee, back cap, leg sleeve", "crew": "B", "label": "Crew B  #9  lanky guard",
        "skin": "tan", "number": 9,
        "leg": 1.08, "torso": 1.04, "width": 0.92, "mass": -0.12,
        "hair": "cap", "hair_pal": ["#3c3238", "#1e181e", "#120e12", "#08060a"],
        "cap_pal": BLACK, "brim_pal": RED,
        "top": "longtee", "top_pal": RED, "trim_pal": BLACK,
        "shorts_pal": BLACK, "shorts_trim": RED, "shorts_len": 1.08,
        "sleeve": None, "sleeve_pal": None, "tight": "L", "tight_pal": BLACK,
        "sock_pal": BLACK, "sock_len": 0.25, "shoe_pal": RED, "shoe_acc": WHITE, "sole_pal": WHITE,
        "beard": False,
    },
]



# ----------------------------------------------------------------------------- poses

STAND = {
    "lean": 4, "head_up": 6, "thigh_L": (0.16, -1, 0.12), "shin_L": (0.02, -1, -0.12), "thigh_R": (-0.16, -1, 0.12),
    "shin_R": (-0.02, -1, -0.12), "upper_L": (0.32, -1, -0.02), "fore_L": (0.1, -1, 0.32),
    "upper_R": (-0.32, -1, -0.02), "fore_R": (-0.1, -1, 0.32),
    "foot_L": (0.25, 0, 1), "foot_R": (-0.25, 0, 1),
}
RUN = {
    "lean": 16, "head_up": 16, "jump": 1.0,
    "thigh_L": (0.05, -0.15, 1), "shin_L": (0.0, -0.85, -0.5), "foot_L": (0, -0.45, 1),
    "thigh_R": (-0.05, -1, -0.42), "shin_R": (0.0, -0.5, -1), "foot_R": (0, -0.9, 0.45),
    "upper_L": (0.12, -0.7, -0.75), "fore_L": (0.0, -1, 0.3),
    "upper_R": (-0.12, -0.75, 0.55), "fore_R": (0.0, 0.55, 0.85),
}
DRIBBLE = {
    "lean": 20, "head_up": 16, "twist": -10,
    "thigh_L": (0.3, -0.75, 0.55), "shin_L": (0.05, -1, -0.15), "foot_L": (0.2, 0, 1),
    "thigh_R": (-0.35, -0.9, -0.15), "shin_R": (-0.05, -1, 0.1), "foot_R": (-0.35, 0, 1),
    "upper_L": (0.5, -0.6, 0.5), "fore_L": (0.05, 0.25, 1),
    "ball_at": (-5.0, -8.5, 6.0), "hand_R": ("ball", (0.2, 3.5, -0.3)), "pole_R": (-1, 0.2, -0.6),
}
SHOT = {
    # shooting hand is the far one (the sprite gets mirrored for the other direction anyway),
    # so the face stays visible under the ball; the near guide arm keeps its elbow out
    "lean": -4, "head_up": 14, "jump": 6, "shrug": 2.4,
    "thigh_L": (0.1, -1, 0.18), "shin_L": (0.0, -1, -0.3), "foot_L": (0.1, -0.85, 0.5),
    "thigh_R": (-0.1, -1, 0.05), "shin_R": (0.0, -1, -0.35), "foot_R": (-0.1, -0.85, 0.5),
    "ball_at": (0.9, 26.4, 1.0),
    "hand_L": ("ball", (1.7, -3.0, 0.0)), "pole_L": (1, -0.3, 0.5),
    "hand_R": ("ball", (-3.0, -1.6, 0.2)), "pole_R": (-1, -0.3, 0.5),
}

VIEWS = [
    ("front", STAND, 0),
    ("side", STAND, 70),
    ("back", STAND, 180),
    ("run", RUN, 75),
    ("dribble", DRIBBLE, 60),
    ("jump shot", SHOT, 30),
]


# ----------------------------------------------------------------------------- ring, floor

def ring_image(crew, w=FRAME_W, h=9):
    """Soft team-coloured ellipse ring to sit under the feet (1x)."""
    c = CREW_RING[crew]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx, cy, rx, ry = w / 2.0, h / 2.0, 10.5, 3.6
    for j in range(h):
        for i in range(w):
            dx, dy = (i + 0.5 - cx) / rx, (j + 0.5 - cy) / ry
            d = math.sqrt(dx * dx + dy * dy)
            if 0.80 <= d <= 1.0:
                px[i, j] = c + (215,)
            elif 0.62 <= d < 0.80:
                px[i, j] = c + (110,)
            elif d < 0.62:
                px[i, j] = (10, 10, 30, 70)  # soft contact shadow
            elif d <= 1.12:
                px[i, j] = c + (60,)
    return img


WOOD = [hexc("#d9a066"), hexc("#d29a5e"), hexc("#cc935a"), hexc("#d6a062")]


def floor_image(w, h, seed=7):
    """Foreshortened maple floor: boards run left-right, 3 px tall, with a 1 px front edge."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    px = img.load()
    y = 0
    row = 0
    while y < h:
        bh = 3
        x = -rnd.randint(0, 40)
        while x < w:
            L = rnd.randint(26, 60)
            base = WOOD[rnd.randrange(len(WOOD))]
            for xx in range(max(0, x), min(w, x + L)):
                for yy in range(y, min(h, y + bh)):
                    c = base
                    if yy == y:
                        c = tuple(min(255, int(v * 1.06)) for v in base)
                    if xx == x + L - 1:
                        c = darker(base, 0.84)  # board end joint
                    px[xx, yy] = c + (255,)
            # grain streaks
            for _ in range(L // 9):
                gx = rnd.randint(max(0, x), max(0, min(w - 1, x + L - 4)))
                gy = y + rnd.randint(0, bh - 1)
                for k in range(rnd.randint(2, 6)):
                    if 0 <= gx + k < w and gy < h and gx + k < x + L - 1:
                        px[gx + k, gy] = darker(base, 0.92) + (255,)
            x += L
        if y + bh < h:
            for xx in range(w):
                px[xx, y + bh] = hexc("#b57c48") + (255,)  # seam between boards
        y += bh + 1
        row += 1
    return img


def paint_lines(img, crew_split_x):
    """Painted court lines: a sideline and a foreshortened three-point arc, plus two key colours."""
    w, h = img.size
    px = img.load()
    paint = (246, 240, 228)

    def blend(i, j, c, a):
        if 0 <= i < w and 0 <= j < h:
            o = px[i, j]
            px[i, j] = tuple(int(o[k] * (1 - a) + c[k] * a) for k in range(3)) + (255,)

    # foreshortened arc (ellipse) around the left and right ends
    for (cx, col) in ((-30, (64, 128, 232)), (w + 30, (220, 56, 68))):
        rx, ry = 120, 70
        cy = h * 0.52
        for j in range(h):
            for i in range(w):
                dx, dy = (i + 0.5 - cx) / rx, (j + 0.5 - cy) / ry
                d = math.sqrt(dx * dx + dy * dy)
                if d < 0.55:
                    blend(i, j, col, 0.30)
                if abs(d - 1.0) < 0.013 or abs(d - 0.55) < 0.02:
                    blend(i, j, paint, 0.92)
    # half-court style line
    for j in range(h):
        pass


# ----------------------------------------------------------------------------- sheet

def font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except TypeError:
        return ImageFont.load_default()


def make_portrait(p, expr):
    pose = dict(STAND)
    pose["head_up"] = 22 if expr == "celebrate" else 12
    pose["head_yaw"] = 0
    S = 4.0
    w = h = 56
    # aim the head centre into the frame
    prims, info, _ = build(p, pose)
    hc = info["head_c"]
    yaw = -28 if p["crew"] == "A" else 28
    C = rot_x(TILT) @ rot_y(math.radians(yaw))
    c = C @ hc
    ox = w / 2 - c[0] * S
    oy = h * 0.44 + c[1] * S
    img, cv, _ = render(p, pose, yaw, w=w, h=h, ox=ox, oy=oy, scale=S, expr=expr, portrait=True)
    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    sprites = {}
    for p in PLAYERS:
        for name, pose, yaw in VIEWS:
            img, _, _ = render(p, pose, yaw)
            sprites[(p["id"], name)] = img
            img.save(os.path.join(OUT_DIR, "%s_%s.png" % (p["id"], name.replace(" ", "_"))))
    for crew in ("A", "B"):
        ring_image(crew).save(os.path.join(OUT_DIR, "ring_crew_%s.png" % crew.lower()))
    portraits = {}
    for p in (PLAYERS[0], PLAYERS[2]):
        for expr in ("focus", "celebrate"):
            img = make_portrait(p, expr)
            portraits[(p["id"], expr)] = img
            img.save(os.path.join(OUT_DIR, "%s_face_%s.png" % (p["id"], expr)))

    # layout (1x units, then everything is scaled by ZOOM)
    label_w = 52
    cell_w = 44
    top_h = 26
    row_h = 61
    cols = len(VIEWS)
    sheet_w = label_w + cols * cell_w + 6
    floor_h = row_h * len(PLAYERS) + 4
    face_h = 74
    sheet_h = top_h + floor_h + 6 + face_h
    base = Image.new("RGBA", (sheet_w, sheet_h), hexc("#1c1a26") + (255,))
    fl = floor_image(sheet_w - label_w + 2, floor_h)
    paint_lines(fl, (sheet_w - label_w) // 2 + 1)
    base.paste(fl, (label_w - 2, top_h))
    # front edge of the floor slab (3/4 depth cue)
    d = ImageDraw.Draw(base)
    d.rectangle([label_w - 2, top_h + floor_h, sheet_w - 1, top_h + floor_h + 3], fill=hexc("#7a4626"))
    d.line([label_w - 2, top_h + floor_h, sheet_w - 1, top_h + floor_h], fill=hexc("#f0c086"))

    for r, p in enumerate(PLAYERS):
        for c, (name, pose, yaw) in enumerate(VIEWS):
            spr = sprites[(p["id"], name)]
            x0 = label_w + c * cell_w + (cell_w - FRAME_W) // 2
            y0 = top_h + r * row_h + row_h - FRAME_H + 1
            ring = ring_image(p["crew"])
            base.alpha_composite(ring, (x0, y0 + GROUND_Y - ring.size[1] // 2 - 1))
            base.alpha_composite(spr, (x0, y0))
    # face row
    fx = label_w + 4
    fy = top_h + floor_h + 10
    for (pid, expr), img in portraits.items():
        frame = Image.new("RGBA", (img.size[0] + 2, img.size[1] + 2), hexc("#4a4660") + (255,))
        inner = Image.new("RGBA", img.size, hexc("#2c2a3a") + (255,))
        frame.paste(inner, (1, 1))
        crew = "A" if pid.startswith("a") else "B"
        grad = Image.new("RGBA", img.size, (0, 0, 0, 0))
        gd = ImageDraw.Draw(grad)
        cc = CREW_RING[crew]
        for k in range(img.size[1]):
            a = int(90 * k / img.size[1])
            gd.line([0, k, img.size[0], k], fill=cc + (a,))
        frame.alpha_composite(grad, (1, 1))
        frame.alpha_composite(img, (1, 1))
        base.alpha_composite(frame, (fx, fy))
        fx += img.size[0] + 10

    big = base.resize((sheet_w * ZOOM, sheet_h * ZOOM), Image.NEAREST)
    d = ImageDraw.Draw(big)
    ft = font(30)
    fs = font(17)
    fl_ = font(15)
    d.text((14, 12), "Road Trip Hoops  -  player style sample v1  (original pixel art, 1x sprites shown 4x)",
           font=ft, fill=(250, 244, 230))
    for c, (name, _, _) in enumerate(VIEWS):
        x = (label_w + c * cell_w) * ZOOM + cell_w * ZOOM // 2
        y = (top_h - 6) * ZOOM - 4
        tw = d.textlength(name, font=fs)
        d.rounded_rectangle([x - tw / 2 - 8, y - 4, x + tw / 2 + 8, y + 22], 6, fill=(20, 18, 30, 210))
        d.text((x - tw / 2, y - 1), name, font=fs, fill=(250, 244, 230))
    for r, p in enumerate(PLAYERS):
        y = (top_h + r * row_h + row_h // 2) * ZOOM
        name = p["label"].split("  ")
        cc = CREW_RING[p["crew"]]
        d.rectangle([10, y - 44, 18, y + 44], fill=cc)
        d.text((26, y - 44), name[0], font=fs, fill=cc)
        d.text((26, y - 22), name[1] + "  " + name[2], font=fs, fill=(250, 244, 230))
        for k, part in enumerate(p["desc"].split(", ")):
            d.text((26, y + 2 + k * 18), part, font=fl_, fill=(200, 196, 214))
    y = (top_h + floor_h + 6) * ZOOM + 8
    d.text((14, y + 6), "Close-ups", font=fs, fill=(250, 244, 230))
    d.text((14, y + 30), "focused /", font=fl_, fill=(200, 196, 214))
    d.text((14, y + 50), "celebrating", font=fl_, fill=(200, 196, 214))
    fx = label_w + 4
    for (pid, expr) in portraits:
        p = [q for q in PLAYERS if q["id"] == pid][0]
        txt = "%s %s" % (p["label"].split("  ")[1], "focused" if expr == "focus" else "celebrating")
        d.text((fx * ZOOM + 4, y - 4), txt, font=fl_, fill=(220, 216, 232))
        fx += 56 + 10
    d.text((sheet_w * ZOOM - 560, sheet_h * ZOOM - 30),
           "Light from upper left; 4 tones per colour; rings show the crew.", font=fl_, fill=(150, 146, 170))
    os.makedirs(os.path.dirname(OUT_SHEET), exist_ok=True)
    big.convert("RGB").save(OUT_SHEET, optimize=True)
    print("wrote", OUT_SHEET, big.size)


if __name__ == "__main__":
    main()
