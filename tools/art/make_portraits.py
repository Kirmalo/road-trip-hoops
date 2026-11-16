#!/usr/bin/env python3
"""Story portraits for Road Trip Hoops (P5-A2): large pixel busts in the approved style sample v1 look.

Each portrait is the same 3D-part player as the sprite sheets (tools/art/crews.json, renderer
tools/art/pixel3d.py), rendered close up at a high scale with the procedural portrait faces, bold outlines,
4-tone shading with the light from the upper left, plus a crew-colored rim light on the far edge
(the fighting-game portrait look). Original characters; nothing is traced or copied.

SAMPLE ONLY: the 3 underdogs in 2 expressions and Hometown's boss. SUPERSEDED: the owner chose the comic style v2,
so the game's portraits come from tools/art/make_portraits_v2.py; this script now writes to build/portraits_v1/
(ignored) so rerunning it cannot overwrite them.

Usage:  python3 tools/art/make_portraits.py
Output: build/portraits_v1/<id>.png            96 x 112, default expression (neutral / determined), faces right
        build/portraits_v1/<id>_<expr>.png     the other expressions (happy, smug)
        docs/art/portraits_sample_v1.png     story text box mock-ups and all sample portraits
Needs:  Pillow, numpy
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import pixel3d as P
from make_players import P_STAND, load_players

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "build", "portraits_v1")
SHEET = os.path.join(ROOT, "docs", "art", "portraits_sample_v1.png")

PW, PH = 96, 112           # board contract: 96 x 112 source px, drawn 3x, facing right
ZOOM = 3

# id: [(expression, file suffix), ...]; the first one is the default <id>.png
SAMPLE = {
    "ud_deuce": [("focus", ""), ("happy", "_happy")],
    "ud_jojo": [("focus", ""), ("happy", "_happy")],
    "ud_tank": [("focus", ""), ("happy", "_happy")],
    "ht_boss": [("focus", ""), ("smug", "_smug")],
}
NAMES = {"ud_deuce": "DEUCE", "ud_jojo": "JOJO", "ud_tank": "TANK", "ht_boss": "MAYOR"}
EXPR_LABEL = {"focus": "determined", "happy": "happy", "smug": "smug"}
RIM = {"U": (255, 214, 110), "HT": (150, 240, 150)}   # rim light: gold for your crew, the city crew's color

YAW = 24.0                 # body turned toward screen right (+x), like the sprites
SCALE = 7.4                # 1x sprite units -> portrait px


def pose_for(p, expr):
    pose = dict(P_STAND)
    pose["upper_L"] = (0.18, -1, 0.18)   # arms hang close: lower, calmer shoulders in the bust
    pose["upper_R"] = (-0.18, -1, 0.18)
    pose["shrug"] = -0.7
    pose["head_yaw"] = -6.0
    if expr == "focus":
        pose["head_up"] = 12.0     # level gaze at the camera (it looks down 20 degrees)
        pose["lean"] = 9.0         # leaning in a little: determined
    elif expr == "happy":
        pose["head_up"] = 17.0
        pose["lean"] = 3.0
        pose["head_yaw"] = -10.0
    elif expr == "smug":
        pose["head_up"] = 23.0     # chin up, looking down his nose
        pose["lean"] = -3.0
        pose["head_yaw"] = -14.0
        pose["twist"] = -6.0
    return pose


def portrait(p, expr):
    pose = pose_for(p, expr)
    prims, info, _ = P.build(p, pose)
    hc = info["head_c"]
    C = P.rot_x(P.TILT) @ P.rot_y(math.radians(YAW))
    c = C @ hc
    # head centre at about (50%, 36%) of the frame; bigger players get a little more room
    ox = PW * 0.50 - c[0] * SCALE
    oy = PH * 0.36 + c[1] * SCALE
    img, cv, _ = P.render(p, pose, YAW, w=PW, h=PH, ox=ox, oy=oy, scale=SCALE, expr=expr, portrait=True)
    return rim_light(img, RIM.get(p["crew"], (255, 214, 110)))


def rim_light(img, col):
    """A thin back light on the right-hand silhouette edge (the side away from the key light)."""
    a = np.array(img).astype(np.int32)
    op = a[:, :, 3] > 0
    h, w = op.shape
    # outline pixels are the outermost opaque ring; the rim goes 1-2 px inside them on the right side
    inner = op.copy()
    edge = np.zeros_like(op)
    edge[:, :-1] = op[:, :-1] & ~op[:, 1:]
    outline = edge.copy()
    rim1 = np.zeros_like(op)
    rim1[:, :-1] = op[:, :-1] & outline[:, 1:]
    rim2 = np.zeros_like(op)
    rim2[:, :-1] = op[:, :-1] & rim1[:, 1:]
    rows = np.arange(h)[:, None] * np.ones((1, w))
    keep = rows < h - 2       # not on the cut-off bottom
    for m, k in ((rim1 & keep, 0.55), (rim2 & keep, 0.25)):
        for ch in range(3):
            a[:, :, ch] = np.where(m, (a[:, :, ch] * (1 - k) + col[ch] * k).astype(np.int32), a[:, :, ch])
    return Image.fromarray(a.astype(np.uint8), "RGBA")


# ----------------------------------------------------------------------------- the sample sheet

def font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except TypeError:
        return ImageFont.load_default()


def backdrop(w, h, top, bottom):
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    for j in range(h):
        t = j / max(1, h - 1)
        d.line([(0, j), (w, j)], fill=tuple(int(top[k] * (1 - t) + bottom[k] * t) for k in range(3)) + (255,))
    return im


def story_mock(left, right, speaker, name, line, sub):
    """1280 x 720 story screen as story.gd might draw it: portraits left/right, name plate, text box."""
    scr = backdrop(1280, 720, (40, 34, 66), (16, 14, 26))
    d = ImageDraw.Draw(scr)
    # speed lines behind the speaker (fighting-game flavour)
    cx = 300 if speaker == "left" else 980
    for k in range(28):
        ang = k * (math.pi * 2 / 28)
        d.line([(cx + math.cos(ang) * 120, 300 + math.sin(ang) * 120),
                (cx + math.cos(ang) * 700, 300 + math.sin(ang) * 700)], fill=(60, 52, 96, 255), width=6)
    for img, side in ((left, "left"), (right, "right")):
        if img is None:
            continue
        im = img if side == "left" else img.transpose(Image.FLIP_LEFT_RIGHT)
        big = im.resize((PW * ZOOM, PH * ZOOM), Image.NEAREST)
        if side != speaker:
            arr = np.array(big).astype(np.float32)
            arr[:, :, :3] *= 0.72     # the listener is dimmed
            big = Image.fromarray(arr.astype(np.uint8), "RGBA")
        x = 120 if side == "left" else 1280 - 120 - PW * ZOOM
        scr.alpha_composite(big, (x, 720 - 200 - PH * ZOOM + 24))
    # text box
    d.rounded_rectangle([40, 500, 1240, 696], 16, fill=(14, 12, 24, 240), outline=(242, 182, 44, 255), width=4)
    nx = 70 if speaker == "left" else 1210 - 260
    d.rounded_rectangle([nx, 474, nx + 260, 522], 10, fill=(242, 182, 44, 255), outline=(110, 66, 14, 255), width=3)
    d.text((nx + 130, 498), name, font=font(28), fill=(20, 14, 26), anchor="mm")
    d.text((80, 548), line, font=font(30), fill=(240, 240, 250))
    d.text((80, 600), sub, font=font(30), fill=(240, 240, 250))
    d.text((1210, 676), "TAP  >", font=font(20), fill=(255, 230, 138), anchor="rm")
    d.rounded_rectangle([1130, 20, 1260, 64], 10, fill=(52, 52, 63, 255), outline=(154, 154, 176, 255), width=2)
    d.text((1195, 42), "SKIP", font=font(20), fill=(255, 255, 255), anchor="mm")
    return scr


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    players = {p["id"]: p for p in load_players()}
    made = {}
    for pid, exprs in SAMPLE.items():
        for expr, suf in exprs:
            img = portrait(players[pid], expr)
            img.save(os.path.join(OUT_DIR, pid + suf + ".png"), optimize=True)
            made[(pid, expr)] = img
            print("wrote", pid + suf + ".png")

    # sheet: two story mock-ups, then every sample portrait on a card
    mock1 = story_mock(made[("ud_deuce", "focus")], made[("ht_boss", "smug")], "right", "MAYOR",
                       "Well, well. The Cornfield Kings, in MY town?",
                       "Go home, boys. The county line is mine.")
    mock2 = story_mock(made[("ud_jojo", "happy")], made[("ud_tank", "happy")], "left", "JOJO",
                       "We did it! Next stop: Chicago!",
                       "Tank, you're driving. The Biscuit likes you.")
    cell_w, cell_h = 320, PH * 2 + 70
    rows = 2
    sheet_h = 70 + 720 + 24 + 720 + 40 + rows * cell_h + 40
    sheet = Image.new("RGBA", (1280, sheet_h), (24, 22, 34, 255))
    d = ImageDraw.Draw(sheet)
    d.text((24, 20), "Story portraits SAMPLE v1 - original pixel art, 96 x 112 (3x in the mock-ups, 2x below)", font=font(26), fill=(240, 240, 250))
    sheet.alpha_composite(mock1, (0, 70))
    sheet.alpha_composite(mock2, (0, 70 + 720 + 24))
    y0 = 70 + 720 + 24 + 720 + 40
    for c, pid in enumerate(SAMPLE):
        for r, (expr, _) in enumerate(SAMPLE[pid]):
            x = c * cell_w + 16
            y = y0 + r * cell_h
            p = players[pid]
            ring = p["ring"]
            card = backdrop(PW * 2 + 8, PH * 2 + 8, tuple(int(v * 0.35) for v in ring), (20, 18, 30))
            sheet.alpha_composite(card, (x, y + 30))
            d.rectangle([x, y + 30, x + PW * 2 + 7, y + 30 + PH * 2 + 7], outline=(74, 70, 96, 255), width=2)
            sheet.alpha_composite(made[(pid, expr)].resize((PW * 2, PH * 2), Image.NEAREST), (x + 4, y + 34))
            lab = "neutral" if (pid == "ht_boss" and expr == "focus") else EXPR_LABEL[expr]
            d.text((x, y + 4), "%s  %s" % (NAMES[pid], lab), font=font(20), fill=(255, 230, 138))
    d.text((24, sheet_h - 30), "Light from the upper left, 4 tones per color, crew-colored rim light on the far "
                               "edge. Not yet drawn: the rest of the Hometown and Chicago crews, ny_boss.",
           font=font(18), fill=(154, 154, 176))
    sheet.convert("RGB").save(SHEET)
    print("wrote", SHEET)


if __name__ == "__main__":
    main()
