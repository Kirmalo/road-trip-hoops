#!/usr/bin/env python3
"""App icons and the itch.io cover for Road Trip Hoops (P7-05), built from the game's own art.

Pieces reused from assets (read only, nothing downloaded or hand drawn):
  assets/map/van.png              "The Biscuit", frame 0 facing right (48 x 32, anchor between the wheels 24, 29)
  assets/players2/cards/ud_*.png  the three underdogs' cards (64 x 96)
  assets/courts/blacktop_floor.png  the blacktop tile (64 x 64)
Drawn here in the style sample v1 look (flat colour bands, 4 tones, light from the upper left, dark ink outline):
  the title's banded sunset (colours from scripts/title.gd), a big basketball "setting sun" in the ball.png palette,
  the cornfield and the road with gold dashes, and "ROAD TRIP HOOPS" in a 5 x 7 pixel font in the title's gold.

Usage:  python3 tools/art/make_icon.py
Output: assets/icon/icon.png         256 x 256  project icon and web favicon (64-cell art at 4x, rounded corners)
        assets/icon/icon_192.png     192 x 192  Android main icon (3x)
        assets/icon/icon_512.png     512 x 512  spare, for itch (8x)
        assets/icon/icon_fg_432.png  432 x 432  Android adaptive foreground (108-cell art at 4x, transparent; the
                                                motif stays inside the 264 px safe circle)
        assets/icon/icon_bg_432.png  432 x 432  Android adaptive background (opaque, full bleed)
        docs/release/cover.png       630 x 500  itch.io cover (315 x 250 art at 2x)
        docs/art/icon_cover_preview_v1.png  the icon at 48 / 96 / 192 / 512, the adaptive icon under round and
                                            squircle masks, and the cover (for the owner)
Reruns are byte-identical (no randomness, no time stamps). Needs: Pillow, numpy
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ICON_DIR = os.path.join(ROOT, "assets", "icon")
COVER = os.path.join(ROOT, "docs", "release", "cover.png")
PREVIEW = os.path.join(ROOT, "docs", "art", "icon_cover_preview_v1.png")
VAN = os.path.join(ROOT, "assets", "map", "van.png")
CARDS = os.path.join(ROOT, "assets", "players2", "cards")
FLOOR = os.path.join(ROOT, "assets", "courts", "blacktop_floor.png")


def rgb(c):
    """Godot Color floats -> 0..255 tuple."""
    return tuple(int(round(v * 255)) for v in c)


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


# the title screen's colours (scripts/title.gd, scripts/ui_kit.gd)
SKY_TOP = rgb((0.10, 0.12, 0.30))
SKY_LOW = rgb((0.95, 0.52, 0.30))
CORN = rgb((0.55, 0.50, 0.12))
CORN_TOP = rgb((0.90, 0.78, 0.25))
ROAD = rgb((0.16, 0.16, 0.18))
ROAD_EDGE = rgb((0.40, 0.40, 0.42))
VERGE = rgb((0.30, 0.42, 0.16))
GOLD = rgb((1.0, 0.82, 0.25))
GOLD_TONES = [(255, 240, 160), GOLD, (232, 168, 40), (176, 104, 24)]   # light .. dark (the title gold, 4 tones)
CREAM = (255, 244, 208)
INK = (26, 18, 30)
# ball.png's palette (tools/art/make_courts.py)
BALL_OUT = (42, 18, 12)
BALL_TONES = [(255, 224, 184), (255, 176, 112), (240, 118, 30), (184, 74, 22), (112, 42, 18)]
BALL_SEAM = (106, 44, 16)
BALL_SEAM_DARK = (62, 26, 10)

# ----------------------------------------------------------------------------- 5 x 7 pixel font

FONT = {
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
    "J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
    "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
    "(": [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
    ")": ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
    ".": [".", ".", ".", ".", ".", ".", "#"],
    ",": ["..", "..", "..", "..", "..", ".#", "#."],
    " ": ["...", "...", "...", "...", "...", "...", "..."],
}


def text_mask(s, scale=1, gap=1):
    """Boolean mask (h, w) of the text at `scale` art pixels per font pixel."""
    w = sum(len(FONT[c][0]) + gap for c in s) - gap
    m = np.zeros((7, w), bool)
    x = 0
    for c in s:
        g = FONT[c]
        for j, row in enumerate(g):
            for i, ch in enumerate(row):
                if ch == "#":
                    m[j, x + i] = True
        x += len(g[0]) + gap
    return np.kron(m, np.ones((scale, scale), bool))


def dilate(m, r):
    out = m.copy()
    h, w = m.shape
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy > r * r + r:
                continue
            sh = np.zeros_like(m)
            sh[max(0, dy):h + min(0, dy), max(0, dx):w + min(0, dx)] = \
                m[max(0, -dy):h - max(0, dy), max(0, -dx):w - max(0, dx)]
            out |= sh
    return out


def title_text(s, scale, outline=2, shadow=3, tones=GOLD_TONES):
    """Gold title lettering: 4-tone fill (lit top, dark bottom), ink outline and a drop shadow. Returns RGBA."""
    m = text_mask(s, scale)
    pad = outline + shadow
    h, w = m.shape
    M = np.zeros((h + 2 * pad, w + 2 * pad), bool)
    M[pad:pad + h, pad:pad + w] = m
    ring = dilate(M, outline)
    a = np.zeros(M.shape + (4,), np.uint8)
    sh = np.zeros_like(ring)
    sh[shadow:, shadow:] = ring[:-shadow, :-shadow]
    a[sh] = INK + (150,)
    a[ring] = INK + (255,)
    ys = np.arange(M.shape[0])[:, None].repeat(M.shape[1], 1) - pad
    band = np.clip((ys * 4) // max(1, h), 0, 3)       # 4 horizontal tone bands per line of text
    for k in range(4):
        sel = M & (band == k)
        a[sel] = tones[[0, 1, 1, 2][k]] + (255,)
    # a dark lip on the bottom pixel row of each stroke (light from the upper left)
    below = np.zeros_like(M)
    below[:-1] = M[1:]
    lip = M & ~below
    a[lip] = tones[3] + (255,)
    return Image.fromarray(a, "RGBA")


def small_text(s, col=CREAM, shadow=INK):
    """1x font, 1 px drop shadow. Returns RGBA."""
    m = text_mask(s, 1)
    h, w = m.shape
    a = np.zeros((h + 1, w + 1, 4), np.uint8)
    a[1:, 1:][m] = shadow + (255,)
    a[:h, :w][m] = col + (255,)
    return Image.fromarray(a, "RGBA")


# ----------------------------------------------------------------------------- the pieces

def ball(r, rot=-0.35):
    """A basketball of radius r cells in ball.png's palette, lit from the upper left, seams rotated by rot."""
    n = 2 * r + 2
    a = np.zeros((n, n, 4), np.uint8)
    c = n / 2.0
    L = np.array([-0.55, -0.62, 0.56])
    L = L / np.linalg.norm(L)
    w = 0.55 / r + 0.035                                 # seam half-width (about one cell)
    cr, sr = math.cos(rot), math.sin(rot)
    for y in range(n):
        for x in range(n):
            u, v = (x + 0.5 - c) / r, (y + 0.5 - c) / r
            d = math.hypot(u, v)
            if d > 1.0:
                continue
            if d > 1.0 - 1.0 / r:
                a[y, x] = BALL_OUT + (255,)
                continue
            nz = math.sqrt(max(0.0, 1.0 - d * d))
            lum = u * L[0] + v * L[1] + nz * L[2]
            tone = 0 if lum > 0.975 else 1 if lum > 0.82 else 2 if lum > 0.38 else 3 if lum > 0.0 else 4
            # seams in the ball's own frame (rotated)
            ru, rv = u * cr - v * sr, u * sr + v * cr
            seam = (abs(ru) < w or abs(rv) < w or abs(math.hypot(ru - 1.5, rv) - 0.95) < w
                    or abs(math.hypot(ru + 1.5, rv) - 0.95) < w)
            if seam:
                a[y, x] = (BALL_SEAM_DARK if tone >= 3 else BALL_SEAM) + (255,)
            else:
                a[y, x] = BALL_TONES[tone] + (255,)
    return Image.fromarray(a, "RGBA")


def van_right():
    return Image.open(VAN).convert("RGBA").crop((0, 0, 48, 32))   # frame 0, facing right


VAN_ANCHOR = (24, 29)


def card(name):
    return Image.open(os.path.join(CARDS, name + ".png")).convert("RGBA")


def sky_bands(img, y0, y1, bands):
    """The title's flat sunset bands between rows y0 and y1."""
    d = ImageDraw.Draw(img)
    for k in range(bands):
        a = y0 + (y1 - y0) * k // bands
        b = y0 + (y1 - y0) * (k + 1) // bands
        d.rectangle([0, a, img.width - 1, b - 1], fill=mix(SKY_TOP, SKY_LOW, k / (bands - 1)) + (255,))


def corn(img, y, h):
    """Cornfield strip ending at row y (stalks in a fixed rhythm, gold tips)."""
    d = ImageDraw.Draw(img)
    d.rectangle([0, y - h + 2, img.width - 1, y - 1], fill=CORN + (255,))
    for x in range(0, img.width, 2):
        k = (x * 7 + (x // 2) * 3) % 5
        top = y - h + (k % 3)
        d.line([(x, top), (x, y - 1)], fill=(mix(CORN, INK, 0.25) if k == 4 else CORN) + (255,))
        d.point((x, top), fill=CORN_TOP + (255,))
        if k in (1, 3):
            d.point((x, top + 1), fill=CORN_TOP + (255,))


def road(img, y, h, dash=8, gap=6, offset=0):
    """Road from row y, h rows deep: edge line, asphalt, gold centre dashes."""
    d = ImageDraw.Draw(img)
    d.rectangle([0, y, img.width - 1, y + h - 1], fill=ROAD + (255,))
    d.line([(0, y), (img.width - 1, y)], fill=ROAD_EDGE + (255,))
    cy = y + h // 2 + 1
    x = -offset
    while x < img.width:
        d.rectangle([x, cy, x + dash - 1, cy], fill=GOLD + (255,))
        x += dash + gap


def ink_outline(im, r=1, col=INK):
    a = np.array(im)
    m = a[:, :, 3] > 0
    ring = dilate(m, r) & ~m
    a[ring] = col + (255,)
    return Image.fromarray(a, "RGBA")


def round_mask(img, rad, border=1):
    """Rounded-corner app tile: transparent outside, an ink border inside the edge."""
    n = img.width
    a = np.array(img)
    inside = np.zeros((n, n), bool)
    for y in range(n):
        for x in range(n):
            cx = min(max(x + 0.5, rad), n - rad)
            cy = min(max(y + 0.5, rad), n - rad)
            inside[y, x] = (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= rad * rad
    edge = inside & dilate(~inside, border)
    a[~inside] = 0
    a[edge] = INK + (255,)
    return Image.fromarray(a, "RGBA")


# ----------------------------------------------------------------------------- the icon motif

BALL_R = 17
BALL_C = (0, -11)         # cells from the tile centre
VAN_AT = (0, 20)          # where the van's anchor (between the wheels, on the road) goes
ROAD_TOP = 14             # road surface starts this far below the centre
ROAD_H = 14


def motif(n, c):
    """Ball setting behind the van, centred at cell c of an n-cell transparent tile."""
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    b = ball(BALL_R)
    img.alpha_composite(b, (c + BALL_C[0] - b.width // 2, c + BALL_C[1] - b.height // 2))
    v = van_right()
    img.alpha_composite(v, (c + VAN_AT[0] - VAN_ANCHOR[0], c + VAN_AT[1] - VAN_ANCHOR[1]))
    return img


def backdrop(n, c):
    """Sunset bands, a corn line and the road, so the van's wheels sit on the road at cell c + VAN_AT."""
    img = Image.new("RGBA", (n, n), (0, 0, 0, 255))
    ry = c + ROAD_TOP
    sky_bands(img, 0, ry - 3, 7)
    corn(img, ry, 5)
    road(img, ry, n - ry, dash=6, gap=5, offset=2)
    d = ImageDraw.Draw(img)
    d.rectangle([0, ry + ROAD_H, n - 1, n - 1], fill=VERGE + (255,))
    d.line([(0, ry + ROAD_H), (n - 1, ry + ROAD_H)], fill=ROAD_EDGE + (255,))
    return img


def make_icon64():
    n, c = 64, 32
    img = backdrop(n, c)
    img.alpha_composite(motif(n, c))
    return round_mask(img, 11)


def make_adaptive():
    n, c = 108, 54
    bg = backdrop(n, c)
    fg = motif(n, c)
    return fg, bg


# ----------------------------------------------------------------------------- the cover

def make_cover():
    W, H = 315, 250                     # art pixels, saved at 2x
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    horizon = 160
    sky_bands(img, 0, horizon - 4, 12)
    # the ball sets over the cornfield, left of centre
    b = ball(44)
    img.alpha_composite(b, (96 - b.width // 2, horizon - 8 - b.height // 2))
    corn(img, horizon, 9)
    road(img, horizon, 26, dash=14, gap=10, offset=4)
    # the blacktop in front: floor tile (1x), a painted line and the edge
    floor = Image.open(FLOOR).convert("RGBA")
    ct = horizon + 26
    for x in range(0, W, floor.width):
        img.alpha_composite(floor.crop((0, 0, floor.width, H - ct)), (x, ct))
    d = ImageDraw.Draw(img)
    d.line([(0, ct), (W - 1, ct)], fill=ROAD_EDGE + (255,))
    d.line([(0, ct + 10), (W - 1, ct + 10)], fill=(232, 232, 226, 255))
    # the van on the road, 2x, driving right
    v = van_right().resize((96, 64), Image.NEAREST)
    img.alpha_composite(v, (22, horizon + 20 - VAN_ANCHOR[1] * 2))
    # the underdogs on the blacktop (cards 1x): Jojo, Tank behind, Deuce in front
    # the underdogs on the blacktop, cards at 2x (the van's pixel size): Jojo and Tank behind, Deuce in front
    feet = 226
    for name, cx, y in (("ud_jojo", 172, feet - 6), ("ud_tank", 284, feet - 6), ("ud_deuce", 228, feet)):
        cd = card(name)
        l, t, r, bt = cd.getbbox()
        cd = cd.crop((l, t, r, bt))
        cd = cd.resize((cd.width * 2, cd.height * 2), Image.NEAREST)
        sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(sh).ellipse([cx - 26, y - 5, cx + 26, y + 2], fill=INK + (120,))
        img.alpha_composite(sh)
        img.alpha_composite(cd, (cx - cd.width // 2, y - cd.height))
    # the name, in the title's gold
    t1 = title_text("ROAD TRIP", 4, outline=2, shadow=3)
    t2 = title_text("HOOPS", 8, outline=3, shadow=4)
    img.alpha_composite(t1, ((W - t1.width) // 2 + 1, 8))
    img.alpha_composite(t2, ((W - t2.width) // 2 + 2, 8 + t1.height - 4))
    # the tagline on a dark strip at the bottom
    d.rectangle([0, H - 22, W - 1, H - 1], fill=(14, 12, 24, 230))
    d.line([(0, H - 23), (W - 1, H - 23)], fill=GOLD_TONES[2] + (255,))
    for k, line in enumerate(("DRIVE YOUR UNDERDOG CREW ACROSS AMERICA",
                              "AND WIN THE 3V3 STREETBALL TOURNAMENT IN NEW YORK.")):
        tl = small_text(line)
        img.alpha_composite(tl, ((W - tl.width) // 2, H - 20 + k * 10))
    return img.resize((W * 2, H * 2), Image.NEAREST).convert("RGB")


# ----------------------------------------------------------------------------- the owner's preview sheet

def mask_preview(fg, bg, size, kind):
    """The adaptive icon as a launcher shows it: the middle 72 of 108 dp, under a round or squircle mask."""
    full = bg.copy()
    full.alpha_composite(fg)
    s = full.width
    crop = full.crop((s // 6, s // 6, s - s // 6, s - s // 6)).resize((size, size), Image.LANCZOS)
    m = Image.new("L", (size * 4, size * 4), 0)
    md = ImageDraw.Draw(m)
    if kind == "circle":
        md.ellipse([0, 0, size * 4 - 1, size * 4 - 1], fill=255)
    else:
        md.rounded_rectangle([0, 0, size * 4 - 1, size * 4 - 1], radius=size * 4 * 0.3, fill=255)
    m = m.resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(crop, (0, 0), m)
    return out


def label(sheet, s, x, y):
    t = small_text(s)
    sheet.alpha_composite(t.resize((t.width * 2, t.height * 2), Image.NEAREST), (x, y))


def make_preview(icons, fg, bg, cover):
    """Top row: the icon at 48 / 96 / 192 / 512. Bottom: the cover, the adaptive icon under two masks, the safe circle."""
    W = 40 + 630 + 30 + 192 + 16 + 48 + 30 + 216 + 40
    H = 40 + 512 + 40 + 500 + 40
    sheet = Image.new("RGBA", (W, H), (40, 42, 54, 255))
    d = ImageDraw.Draw(sheet)
    x = 40
    for sz in (48, 96, 192, 512):
        sheet.alpha_composite(icons[sz], (x, 40 + 512 - sz))
        label(sheet, f"{sz} PX", x, 40 + 512 + 8)
        x += sz + 40
    y0 = 40 + 512 + 40
    sheet.alpha_composite(cover.convert("RGBA"), (40, y0))
    label(sheet, "COVER 630 X 500", 40, y0 + 500 + 8)
    cx = 40 + 630 + 30
    y = y0
    for kind in ("circle", "squircle"):
        sheet.alpha_composite(mask_preview(fg, bg, 192, kind), (cx, y))
        sheet.alpha_composite(mask_preview(fg, bg, 48, kind), (cx + 192 + 16, y + 144))
        label(sheet, "ADAPTIVE, " + kind.upper(), cx, y + 200)
        y += 250
    # the 432 foreground over the background, with the 264 px safe circle, at half size
    sx = cx + 192 + 16 + 48 + 30
    full = bg.copy()
    full.alpha_composite(fg)
    sheet.alpha_composite(full.resize((216, 216), Image.LANCZOS), (sx, y0))
    r = 264 / 4
    d.ellipse([sx + 108 - r, y0 + 108 - r, sx + 108 + r, y0 + 108 + r], outline=(255, 255, 255, 255))
    label(sheet, "FG+BG 432", sx, y0 + 224)
    label(sheet, "SAFE CIRCLE 264", sx, y0 + 248)
    return sheet.convert("RGB")


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)


def main():
    i64 = make_icon64()
    icons = {s: i64.resize((s, s), Image.NEAREST) for s in (192, 256, 512)}
    icons[48] = icons[192].resize((48, 48), Image.LANCZOS)     # what a launcher does with the 192 (preview only)
    icons[96] = icons[192].resize((96, 96), Image.LANCZOS)
    save(icons[256], os.path.join(ICON_DIR, "icon.png"))
    save(icons[192], os.path.join(ICON_DIR, "icon_192.png"))
    save(icons[512], os.path.join(ICON_DIR, "icon_512.png"))
    fg, bg = make_adaptive()
    fg4 = fg.resize((432, 432), Image.NEAREST)
    bg4 = bg.resize((432, 432), Image.NEAREST)
    save(fg4, os.path.join(ICON_DIR, "icon_fg_432.png"))
    save(bg4.convert("RGB"), os.path.join(ICON_DIR, "icon_bg_432.png"))
    # the safe circle check: every opaque foreground pixel within 132 px of the centre
    a = np.array(fg4)[:, :, 3] > 0
    ys, xs = np.nonzero(a)
    far = float(np.max(np.hypot(xs + 0.5 - 216, ys + 0.5 - 216)))
    print(f"adaptive foreground: furthest opaque pixel {far:.1f} px from the centre (safe circle 132)")
    cover = make_cover()
    save(cover, COVER)
    save(make_preview(icons, fg4, bg4, cover), PREVIEW)
    for p in ("icon.png", "icon_192.png", "icon_512.png", "icon_fg_432.png", "icon_bg_432.png"):
        print(os.path.join("assets/icon", p), Image.open(os.path.join(ICON_DIR, p)).size)
    print("docs/release/cover.png", Image.open(COVER).size)


if __name__ == "__main__":
    main()
