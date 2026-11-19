#!/usr/bin/env python3
"""Legends UI art for Road Trip Hoops (P9-11): the era tour timeline, the chapter pins and the Hall plaque frames.

Original pixel art made here, nothing downloaded or traced. The Grandfathers art uses the P9-05 OLD GYM palette
(make_courts.py: aged maple, dark wainscot wood, felt banners, late-day window light) and its court textures; the
locked chapters (2-4) show only a dimmed, colourless hint of a court, a padlock and their gate (drawn by the game).
No names, letters, years of real seasons, teams, leagues, arenas or marks.

Usage:  python3 tools/art/make_legends_ui.py
Output (assets/legends/; texel = one pixel of these images, drawn at 2 canvas px per texel like the map):
  timeline.png            640 x 360 era tour backdrop (2x = 1280 x 720): rows 0..HEADER_H-1 kept for the screen
                          header, four era panels left to right (1 Grandfathers in colour, 2-4 dimmed), a timeline
                          rail across them; no labels or pins baked in. On 1280 x 800 centre it (y + 40) and fill
                          the bars with "bar_bg".
  pin_grand.png           32 x 40 chapter pin, Chapter 1 open (brass medallion, an old laced ball)
  pin_grand_done.png      Chapter 1 finished (gold, the laced ball and a star)
  pin_grand_locked.png    Chapter 1 before its gate (grey, padlock)
  pin_fathers_locked.png  Chapters 2-4: locked pins only (grey medallions with their era sign and a padlock):
  pin_present_locked.png    fathers = a chain-net hoop, present = a modern ball, next = a lightning bolt
  pin_next_locked.png
  frame_grand.png         56 x 88 era card frame (Grandfathers): carved wainscot wood, a brass bevel, a felt
                          pennant and star on top, an opaque backing in the window (old gym wall, window light, a
                          strip of maple floor) and an empty brass name plate. Draw the frame, then the legend's
                          card crop in the window.
  frame_locked.png        56 x 88 locked plaque frame: grey iron and dark wood, a dim spotlit backing, a padlock on
                          top, an empty dark name plate. Draw the silhouette (below, or the card darkened) in the
                          window, and "?" / the challenge line where the game likes.
  silhouette.png          40 x 60 a generic player silhouette that fits the window (from a player card's shape)
  ui.json                 the numbers above for the screens (see "_help" inside)
  docs/art/legends_ui.png preview for the owner: the tour mock-up at 1280 x 720 (header, labels, pins drawn as the
                          game would) and the Hall pieces at 2x and 4x
Needs:  Pillow, numpy
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True               # importing make_courts leaves no __pycache__ in tools/art
import make_courts as C  # noqa: E402  (the P9-05 era palette; only its constants are used)

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "assets", "legends")
COURTS = os.path.join(ROOT, "assets", "courts")
CARDS = os.path.join(ROOT, "assets", "players2", "cards")
PREVIEW = os.path.join(ROOT, "docs", "art", "legends_ui.png")

W, H = 640, 360
HEADER_H = 36
BAR_BG = (18, 16, 30)
INK = (22, 14, 26)

# the four chapters, left to right; "court" = the textures shown in the panel (a hint for the locked ones)
CHAPTERS = [
    {"id": "grand", "court": "era_grand", "open": True},
    {"id": "fathers", "court": "blacktop", "open": False},
    {"id": "present", "court": "gold_hall", "open": False},
    {"id": "next", "court": "midnight", "open": False},
]
MARGIN, POST = 7, 6
PANEL_W = (W - 2 * MARGIN - 3 * POST) // 4      # 152
PANEL_Y0, PANEL_Y1 = HEADER_H + 8, H - 8          # 44 .. 352
BD_Y = PANEL_Y0 + 14                              # backdrop top row inside a panel
RAIL_Y = 226                                      # timeline rail centre row

PIN_W, PIN_H = 32, 40
PIN_ANCHOR = (16, 37)

FRAME_W, FRAME_H = 56, 88
WINDOW = (8, 8, 40, 60)                           # x, y, w, h inside the frame
CARD_CROP = (12, 34, 40, 60)                      # x, y, w, h of a 64 x 96 v2 card that fills the window
PLATE = (6, 72, 44, 11)                           # name plate inside the frame

H_ = C.H
BRASS = [H_("#ffe9a8"), H_("#e8c060"), H_("#b88a34"), H_("#7a5620")]
GOLD = [H_("#fff0a0"), H_("#f4c030"), H_("#c08418"), H_("#74460e")]
STEEL = [H_("#d0d0d8"), H_("#9898a4"), H_("#6c6c78"), H_("#4a4a54")]
DARKSTEEL = [H_("#8a8a96"), H_("#62626e"), H_("#44444e"), H_("#2c2c34")]
LEATHER = [H_("#c8783a"), H_("#a05a2a"), H_("#74401e"), H_("#4a2812")]
BALL = [H_("#ffb070"), H_("#e8782a"), H_("#b0501a"), H_("#7a3410")]
CREAM = H_("#fff4d0")


def mix(a, b, t):
    return tuple(int(round(a[k] * (1 - t) + b[k] * t)) for k in range(3))


class Canvas:
    """An RGBA texel canvas with the few drawing calls these pieces need."""

    def __init__(self, w, h, fill=(0, 0, 0, 0)):
        self.w, self.h = w, h
        self.a = np.zeros((h, w, 4), np.uint8)
        self.a[:, :] = fill if len(fill) == 4 else tuple(fill) + (255,)

    def put(self, x, y, c, alpha=255):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.a[y, x] = tuple(c[:3]) + (alpha,)

    def get(self, x, y):
        return tuple(int(v) for v in self.a[int(y), int(x), :3])

    def blend(self, x, y, c, t):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            o = self.a[y, x]
            self.a[y, x, :3] = mix(tuple(int(v) for v in o[:3]), c, t)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.put(x, y, c)

    def disk(self, cx, cy, r, c):
        for y in range(int(cy - r - 1), int(cy + r + 2)):
            for x in range(int(cx - r - 1), int(cx + r + 2)):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.put(x, y, c)

    def image(self):
        return Image.fromarray(self.a.copy(), "RGBA")


def outline(im, ink=INK + (255,)):
    a = np.array(im)
    m = a[:, :, 3] > 0
    g = np.zeros_like(m)
    g[1:, :] |= m[:-1, :]
    g[:-1, :] |= m[1:, :]
    g[:, 1:] |= m[:, :-1]
    g[:, :-1] |= m[:, 1:]
    a[g & ~m] = ink
    return Image.fromarray(a, "RGBA")


def grey(c, t=1.0):
    y = int(round(0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]))
    return mix(c, (y, y, y), t)


# ----------------------------------------------------------------------------- the timeline backdrop

def panel_x(i):
    return MARGIN + i * (PANEL_W + POST)


def panel_cx(i):
    return panel_x(i) + PANEL_W // 2


def court_scene(look, w, h):
    """A slice of a court: its backdrop (sky / wall continued above), then its floor tile; RGB array h x w."""
    bd = np.asarray(Image.open(os.path.join(COURTS, look + "_backdrop.png")).convert("RGB"))
    fl = np.asarray(Image.open(os.path.join(COURTS, look + "_floor.png")).convert("RGB"))
    out = np.zeros((h, w, 3), np.uint8)
    top = BD_Y - PANEL_Y0
    bh = bd.shape[0]
    x0 = {"era_grand": 150, "blacktop": 40, "gold_hall": 200, "midnight": 60}.get(look, 0)  # a busy part of each
    cols = [(x0 + x) % bd.shape[1] for x in range(w)]
    out[:top, :] = bd[0, cols][None, :, :]
    out[top:top + bh, :] = bd[:, cols][: max(0, min(bh, h - top))]
    fy = top + bh
    for y in range(fy, h):
        out[y, :] = fl[(y - fy) % fl.shape[0], [x % fl.shape[1] for x in range(w)]]
    # the far sideline and the apron's shadow under the backdrop
    out[fy:fy + 2, :] = (out[fy:fy + 2, :].astype(float) * 0.62).astype(np.uint8)
    line = (240, 236, 220) if look != "midnight" else (120, 220, 255)
    out[fy + 9, :] = (out[fy + 9, :].astype(float) * 0.3 + np.array(line) * 0.7).astype(np.uint8)
    return out


def draw_timeline():
    cv = Canvas(W, H, BAR_BG)
    ph = PANEL_Y1 - PANEL_Y0 + 1
    # the wall between the panels: dark wainscot wood with a lit top edge
    cv.rect(0, HEADER_H, W - 1, H - 1, C.WAINSCOT[3])
    cv.rect(0, HEADER_H, W - 1, HEADER_H, BRASS[2])
    cv.rect(0, HEADER_H + 1, W - 1, HEADER_H + 1, BRASS[3])
    for x in range(0, W, 12):                                 # panelling grooves
        for y in range(HEADER_H + 3, H):
            if (y // 3) % 2 == 0 and x % 24 == 0:
                cv.put(x, y, C.WAINSCOT[2])
    for i, ch in enumerate(CHAPTERS):
        x0 = panel_x(i)
        sc = court_scene(ch["court"], PANEL_W, ph).astype(float)
        if not ch["open"]:                                    # a colourless, dim hint of a later era
            y = (sc * np.array([0.3, 0.59, 0.11])).sum(axis=2, keepdims=True)
            sc = sc * 0.15 + y * 0.85
            sc = sc * 0.48 + np.array([40, 38, 62]) * 0.30
        else:                                                 # late-day warmth on the open era
            sc = sc * 0.92 + np.array([255, 200, 120]) * 0.08
        # darken toward the bottom (the game writes the chapter name and gate there) and at the sides
        yy = np.arange(ph)[:, None, None]
        xx = np.arange(PANEL_W)[None, :, None]
        dark = np.clip((yy - (RAIL_Y - PANEL_Y0 + 6)) / 70.0, 0, 1) * 0.55
        side = np.clip(1 - np.minimum(xx, PANEL_W - 1 - xx) / 14.0, 0, 1) * 0.25
        sc = sc * (1 - np.maximum(dark, side)) + np.array([14, 10, 20]) * np.maximum(dark, side)
        # fine dither on the dark gradient so it stays pixel-art (two tones, checkered)
        chk = ((np.arange(ph)[:, None] + np.arange(PANEL_W)[None, :]) % 2 == 0)[:, :, None]
        sc = np.where(chk & (dark > 0.05) & (dark < 0.5), sc * 0.94, sc)
        cv.a[PANEL_Y0:PANEL_Y1 + 1, x0:x0 + PANEL_W, :3] = np.clip(sc + 0.5, 0, 255).astype(np.uint8)
        # the panel's frame: brass for the open era, steel for the locked ones
        rp = BRASS if ch["open"] else DARKSTEEL
        for x in range(x0 - 2, x0 + PANEL_W + 2):
            cv.put(x, PANEL_Y0 - 2, rp[1])
            cv.put(x, PANEL_Y0 - 1, rp[3])
            cv.put(x, PANEL_Y1 + 1, rp[2])
            cv.put(x, PANEL_Y1 + 2, rp[3])
        for y in range(PANEL_Y0 - 2, PANEL_Y1 + 3):
            cv.put(x0 - 2, y, rp[0] if y < PANEL_Y1 else rp[2])
            cv.put(x0 - 1, y, rp[3])
            cv.put(x0 + PANEL_W, y, rp[3])
            cv.put(x0 + PANEL_W + 1, y, rp[2])
        for (cx, cy) in ((x0 - 2, PANEL_Y0 - 2), (x0 + PANEL_W + 1, PANEL_Y0 - 2), (x0 - 2, PANEL_Y1 + 2),
                         (x0 + PANEL_W + 1, PANEL_Y1 + 2)):        # corner rivets
            cv.rect(cx - 1, cy - 1, cx + 1, cy + 1, rp[2])
            cv.put(cx - 1, cy - 1, rp[0])
        if not ch["open"]:                                    # diagonal "not yet" veil lines on the locked eras
            for y in range(PANEL_Y0, RAIL_Y - 10):
                for x in range(x0, x0 + PANEL_W):
                    if (x + y) % 9 == 0:
                        cv.blend(x, y, (20, 18, 34), 0.35)
    # the timeline rail: gold up to Chapter 1, then a dark iron rail with dashes toward the later eras
    c1 = panel_cx(0)
    for x in range(0, W):
        done = x <= c1
        rp = GOLD if done else DARKSTEEL
        cv.put(x, RAIL_Y - 3, INK)
        cv.put(x, RAIL_Y - 2, rp[0])
        cv.put(x, RAIL_Y - 1, rp[1])
        cv.put(x, RAIL_Y, rp[1])
        cv.put(x, RAIL_Y + 1, rp[2])
        cv.put(x, RAIL_Y + 2, rp[3])
        cv.put(x, RAIL_Y + 3, INK)
        cv.blend(x, RAIL_Y + 4, (0, 0, 0), 0.45)
        cv.blend(x, RAIL_Y + 5, (0, 0, 0), 0.2)
        if not done and (x // 4) % 3 == 0:
            cv.put(x, RAIL_Y, STEEL[1])
            cv.put(x, RAIL_Y - 1, STEEL[0])
    for i in range(4):                                        # a sleeper under each pin and ticks between
        cx = panel_cx(i)
        rp = GOLD if i == 0 else DARKSTEEL
        cv.rect(cx - 10, RAIL_Y - 5, cx + 10, RAIL_Y + 5, INK)
        cv.rect(cx - 9, RAIL_Y - 4, cx + 9, RAIL_Y + 4, rp[2])
        cv.rect(cx - 9, RAIL_Y - 4, cx + 9, RAIL_Y - 4, rp[1])
        cv.rect(cx - 9, RAIL_Y + 4, cx + 9, RAIL_Y + 4, rp[3])
        for tx in (cx - 40, cx - 26, cx + 26, cx + 40):
            cv.rect(tx, RAIL_Y - 5, tx, RAIL_Y - 4, rp[1])
            cv.rect(tx, RAIL_Y + 4, tx, RAIL_Y + 5, rp[3])
    # arrow head at the right end: the timeline goes on
    for k in range(6):
        for y in range(RAIL_Y - 6 + k, RAIL_Y + 7 - k):
            cv.put(W - 8 + k, y, DARKSTEEL[1] if y < RAIL_Y else DARKSTEEL[2])
    img = Image.fromarray(cv.a[:, :, :3].copy(), "RGB")
    return img


# ----------------------------------------------------------------------------- the chapter pins

def emblem(cv, kind, cx, cy, locked):
    g = (lambda c: grey(c, 0.85)) if locked else (lambda c: c)
    if kind == "grand":                                       # an old leather ball: round, curved seams, a laced slot
        cv.disk(cx, cy, 7, g(LEATHER[1]))
        cv.disk(cx - 2, cy - 2, 3, g(LEATHER[0]))
        for y in range(cy - 7, cy + 8):                       # lower right in shade
            for x in range(cx - 7, cx + 8):
                if (x - cx) ** 2 + (y - cy) ** 2 <= 49 and (x - cx) + (y - cy) > 6:
                    cv.put(x, y, g(LEATHER[2]))
        sm = g(LEATHER[3])
        for x in range(cx - 7, cx + 8):                       # the belt seam
            cv.put(x, cy + 1, sm)
        for y in range(cy - 6, cy + 7):                       # two curved side seams
            dx = int(round(((y - cy) ** 2) / 12.0))
            cv.put(cx - 5 + dx, y, sm)
            cv.put(cx + 5 - dx, y, sm)
        cv.rect(cx - 2, cy - 5, cx + 2, cy - 1, sm)           # the lace slot on top, cream laces across it
        for y in (cy - 4, cy - 2):
            cv.rect(cx - 2, y, cx + 2, y, g(CREAM))
        cv.put(cx - 4, cy - 5, g((255, 230, 190)))
    elif kind == "fathers":                                   # a rim with a chain net
        rim = g(H_("#e8782a"))
        for x in range(cx - 6, cx + 7):
            cv.put(x, cy - 3, rim)
            cv.put(x, cy - 2, g(H_("#a0461a")))
        cv.rect(cx - 7, cy - 3, cx - 7, cy - 2, rim)
        cv.rect(cx + 7, cy - 3, cx + 7, cy - 2, rim)
        chain = g(H_("#c8ccd6"))
        for k, x in enumerate(range(cx - 6, cx + 7, 3)):
            for d in range(7):
                xx = x + (d // 2) * (1 if x < cx else -1 if x > cx else 0)
                if d % 2 == 0:
                    cv.put(xx, cy - 1 + d, chain)
        cv.rect(cx - 3, cy + 5, cx + 3, cy + 5, chain)
    elif kind == "present":                                   # a modern ball
        cv.disk(cx, cy, 7, g(BALL[1]))
        cv.disk(cx - 2, cy - 2, 3, g(BALL[0]))
        sm = g(BALL[3])
        for y in range(cy - 7, cy + 8):
            cv.put(cx, y, sm)
        for x in range(cx - 7, cx + 8):
            cv.put(x, cy, sm)
        for y in range(cy - 6, cy + 7):
            dx = int(round(((y - cy) ** 2) / 12.0))
            cv.put(cx - 5 + dx, y, sm)
            cv.put(cx + 5 - dx, y, sm)
    else:                                                     # next: a lightning bolt
        bolt = ["....###", "...###.", "..###..", ".######", "....##.", "...##..", "..##...", ".#....."]
        for j, row in enumerate(bolt):
            for i, ch in enumerate(row):
                if ch == "#":
                    cv.put(cx - 4 + i, cy - 4 + j, g(H_("#ffe040") if i + j < 8 else H_("#f0a020")))


def padlock(cv, x, y, body, dark):
    """A small padlock, top-left at (x, y): 7 wide, 8 tall."""
    for (dx, dy) in ((1, 0), (2, -1), (3, -1), (4, -1), (5, 0), (1, 1), (5, 1), (1, 2), (5, 2)):
        cv.put(x + dx, y + dy, dark)
    cv.rect(x, y + 3, x + 6, y + 8, dark)
    cv.rect(x + 1, y + 4, x + 5, y + 7, body)
    cv.put(x + 1, y + 4, mix(body, (255, 255, 255), 0.5))
    cv.rect(x + 3, y + 5, x + 3, y + 6, dark)


def pin_image(kind, state):
    """state: open, done or locked."""
    rp = {"open": BRASS, "done": GOLD, "locked": STEEL}[state]
    cv = Canvas(PIN_W, PIN_H)
    cx, cy, r = 16, 15, 13
    tip = PIN_ANCHOR
    for y in range(cy, tip[1] + 1):                           # the point
        hw = (tip[1] - y) * 7.0 / (tip[1] - cy)
        for x in range(int(cx - hw), int(cx + hw) + 1):
            cv.put(x, y, rp[2] if x > cx else rp[1])
    cv.disk(cx, cy, r, rp[1])
    for y in range(cy - r, cy + r + 1):                       # shading: light upper left, dark lower right
        for x in range(cx - r, cx + r + 1):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 <= r * r:
                s = (x - cx) + (y - cy)
                if s > 9:
                    cv.put(x, y, rp[2])
                if d2 > (r - 1.4) ** 2 and s > 4:
                    cv.put(x, y, rp[3])
                elif d2 > (r - 1.4) ** 2 and s < -4:
                    cv.put(x, y, rp[0])
    # bead ring (a medallion's rim)
    for k in range(16):
        a = k * math.pi / 8
        cv.put(cx + round(math.cos(a) * (r - 2.5)), cy + round(math.sin(a) * (r - 2.5)), rp[3 if state != "locked" else 2])
    face = H_("#3a2a24") if state != "locked" else H_("#3a3a44")
    cv.disk(cx, cy, 9, face)
    cv.disk(cx, cy, 8, mix(face, (0, 0, 0), 0.25))
    emblem(cv, kind, cx, cy, state == "locked")
    cv.put(cx - 9, cy - 7, (255, 255, 255))
    cv.put(cx - 8, cy - 9, (255, 255, 255))
    if state == "done":                                       # a gold star badge at the upper right
        star = ["..#..", ".###.", "#####", ".###.", "##.##"]
        for j, row in enumerate(star):
            for i, ch in enumerate(row):
                if ch == "#":
                    cv.put(cx + 6 + i, cy - 13 + j, GOLD[0] if j < 2 else GOLD[1])
    if state == "locked":
        padlock(cv, cx + 4, cy + 3, STEEL[0], H_("#26262e"))
    im = outline(cv.image())
    a = np.array(im)
    for x in range(10, 23):                                   # a soft shadow on the ground under the tip
        for y, al in ((tip[1] + 1, 110), (tip[1] + 2, 60)):
            if 0 <= y < PIN_H and a[y, x, 3] == 0 and abs(x - tip[0]) <= (6 if y == tip[1] + 1 else 4):
                a[y, x] = (20, 16, 30, al)
    return Image.fromarray(a, "RGBA")


# ----------------------------------------------------------------------------- the plaque frames

def frame_border(cv, wood, metal, glow):
    """Carved frame: an outer ink line, a wood band with a lit top-left and dark bottom-right, a metal bevel round
    the window and the name plate."""
    wx, wy, ww, wh = WINDOW
    cv.rect(0, 4, FRAME_W - 1, FRAME_H - 1, INK)
    cv.rect(1, 5, FRAME_W - 2, FRAME_H - 2, wood[1])
    for y in range(5, FRAME_H - 1):
        for x in range(1, FRAME_W - 1):
            if x <= 2 or y <= 6:
                cv.put(x, y, wood[0])
            elif x >= FRAME_W - 4 or y >= FRAME_H - 4:
                cv.put(x, y, wood[2])
            elif (x * 3 + y * 7) % 23 == 0:
                cv.put(x, y, wood[2])                         # wood grain flecks
    for y in range(8, FRAME_H - 6, 6):                        # carved grooves down the sides
        cv.put(3, y, wood[3])
        cv.put(FRAME_W - 5, y, wood[3])
    # metal bevel round the window
    cv.rect(wx - 2, wy - 2, wx + ww + 1, wy + wh + 1, metal[3])
    cv.rect(wx - 2, wy - 2, wx + ww, wy - 2, metal[0])
    cv.rect(wx - 2, wy - 2, wx - 2, wy + wh, metal[0])
    cv.rect(wx - 1, wy - 1, wx + ww, wy - 1, metal[1])
    cv.rect(wx - 1, wy - 1, wx - 1, wy + wh, metal[1])
    cv.rect(wx + ww, wy, wx + ww, wy + wh, metal[2])
    cv.rect(wx, wy + wh, wx + ww, wy + wh, metal[2])
    # name plate
    px, py, pw, ph = PLATE
    cv.rect(px - 1, py - 1, px + pw, py + ph, INK)
    cv.rect(px, py, px + pw - 1, py + ph - 1, metal[1] if glow else metal[2])
    cv.rect(px, py, px + pw - 1, py, metal[0])
    cv.rect(px, py + ph - 1, px + pw - 1, py + ph - 1, metal[3])
    cv.rect(px + pw - 1, py, px + pw - 1, py + ph - 1, metal[2])
    for sx in (px + 2, px + pw - 3):                          # screws
        cv.put(sx, py + ph // 2, metal[3])
        cv.put(sx, py + ph // 2 - 1, metal[0])


def window_backing_grand(cv):
    """Old gym wall in late-day light, the window glow from the left, a strip of aged maple at the feet."""
    wx, wy, ww, wh = WINDOW
    floor_y = wy + 51                                          # card feet (row 90) land at window row 56
    for y in range(wy, wy + wh):
        for x in range(wx, wx + ww):
            if y < floor_y - 4:
                k = 1 if y > wy + 12 else 2
                c = C.PLASTER[k]
                g = max(0.0, 1.0 - ((x - wx) * 0.6 + (y - wy) * 0.25) / 24.0)   # light from the upper left
                c = mix(c, C.WINDOW[1], 0.55 * g)
                if (x * 5 + y * 3) % 17 == 0:
                    c = mix(c, C.PLASTER[3], 0.4)
            elif y < floor_y:
                c = C.WAINSCOT[1] if y > floor_y - 4 else C.WAINSCOT[0]       # kick board
                if y == floor_y - 1:
                    c = C.WAINSCOT[3]
            else:
                k = ((x - wx) // 9 + (y - floor_y) // 3) % 4
                c = C.AGEWOOD[k]
                if (y - floor_y) % 3 == 2:
                    c = C.AGEWOOD_SEAM
            cv.put(x, y, c)
    # a felt banner on the wall (a star and stripes only)
    fx = wx + ww - 11
    for y in range(wy + 2, wy + 16):
        for x in range(fx, fx + 8):
            cv.put(x, y, C.FELT[0][1] if x < fx + 7 else C.FELT[0][2])
    for d in range(2):
        for x in range(fx, fx + 8):
            if abs(x - (fx + 3.5)) > d * 2 + 1:
                cv.put(x, wy + 16 + d, C.FELT[0][2])
    cv.rect(fx - 1, wy + 1, fx + 8, wy + 1, C.RAFTER[1])
    for (dx, dy) in ((3, 4), (4, 4), (2, 5), (3, 5), (4, 5), (5, 5), (3, 6), (4, 6)):
        cv.put(fx + dx, wy + dy, C.FELT[4][0])
    cv.rect(fx + 1, wy + 11, fx + 6, wy + 11, C.FELT[4][0])
    cv.rect(fx + 1, wy + 13, fx + 6, wy + 13, C.FELT[4][0])
    # a soft spot of light on the floor where he stands
    for y in range(floor_y, wy + wh):
        for x in range(wx, wx + ww):
            d = ((x - (wx + ww / 2)) / 15.0) ** 2 + ((y - (wy + 56)) / 4.0) ** 2
            if d < 1:
                cv.blend(x, y, (255, 230, 170), 0.22)
            elif d < 1.6:
                cv.blend(x, y, (90, 50, 20), 0.18)              # his shadow ring


def window_backing_locked(cv):
    """A dim, cold room with a spotlight cone: a black silhouette reads against it."""
    wx, wy, ww, wh = WINDOW
    floor_y = wy + 51
    base = H_("#4a4658")
    for y in range(wy, wy + wh):
        for x in range(wx, wx + ww):
            t = abs(x - (wx + ww / 2 - 0.5)) / (ww / 2)
            cone = max(0.0, 1.0 - t * (1.6 - (y - wy) / wh * 0.8))
            c = mix(H_("#24222e"), base, 0.35 + 0.65 * cone)
            if y >= floor_y:
                c = mix(c, H_("#1a1822"), 0.45)
                if (y - floor_y) % 3 == 2:
                    c = mix(c, (0, 0, 0), 0.2)
            if (x + y) % 2 == 0 and 0.2 < cone < 0.45:
                c = mix(c, H_("#24222e"), 0.3)                 # dither the cone's edge
            cv.put(x, y, c)
    for y in range(floor_y, wy + wh):                          # the lit spot on the floor
        for x in range(wx, wx + ww):
            d = ((x - (wx + ww / 2)) / 14.0) ** 2 + ((y - (wy + 56)) / 3.5) ** 2
            if d < 1:
                cv.blend(x, y, H_("#9a96b0"), 0.35)


def crest(cv, kind):
    """The top of the frame: a felt pennant with a star (era frame) or an iron padlock (locked)."""
    mid = FRAME_W // 2
    if kind == "grand":
        cv.rect(mid - 9, 0, mid + 9, 5, INK)
        cv.rect(mid - 8, 1, mid + 8, 4, C.FELT[0][1])
        cv.rect(mid - 8, 1, mid + 8, 1, C.FELT[0][0])
        cv.rect(mid - 8, 4, mid + 8, 4, C.FELT[0][2])
        star = ["..#..", "#####", ".###.", ".#.#."]
        for j, row in enumerate(star):
            for i, ch in enumerate(row):
                if ch == "#":
                    cv.put(mid - 2 + i, 1 + j, BRASS[0] if j < 2 else BRASS[1])
        for sx in (mid - 6, mid + 5):
            cv.rect(sx, 2, sx + 1, 3, BRASS[1])
            cv.put(sx, 2, BRASS[0])
    else:
        cv.rect(mid - 6, 0, mid + 6, 6, INK)
        cv.rect(mid - 5, 1, mid + 5, 5, DARKSTEEL[1])
        cv.rect(mid - 5, 1, mid + 5, 1, DARKSTEEL[0])
        padlock(cv, mid - 3, 0, STEEL[1], H_("#1c1c24"))


def frame_image(kind):
    cv = Canvas(FRAME_W, FRAME_H)
    if kind == "grand":
        wood = [C.WAINSCOT[0], C.WAINSCOT[1], C.WAINSCOT[2], C.WAINSCOT[3]]
        frame_border(cv, wood, BRASS, True)
        window_backing_grand(cv)
    else:
        wood = [H_("#5a5260"), H_("#433c48"), H_("#2f2a34"), H_("#1e1a22")]
        frame_border(cv, wood, DARKSTEEL, False)
        window_backing_locked(cv)
    crest(cv, kind)
    # corner rosettes on the era frame / bolts on the locked one
    for (x, y) in ((2, 6), (FRAME_W - 5, 6), (2, FRAME_H - 5), (FRAME_W - 5, FRAME_H - 5)):
        m = BRASS if kind == "grand" else DARKSTEEL
        cv.rect(x, y, x + 2, y + 2, m[2])
        cv.put(x, y, m[0])
        cv.put(x + 1, y + 1, m[1])
    return cv.image()


def card_crop(card):
    x, y, w, h = CARD_CROP
    return card.crop((x, y, x + w, y + h))


def silhouette_image():
    """A plain player's shape (a hometown card's alpha), filled with near-black ink and a faint cold rim light."""
    card = Image.open(os.path.join(CARDS, "ht_a1.png")).convert("RGBA")
    a = np.array(card_crop(card))
    m = a[:, :, 3] > 0
    out = np.zeros_like(a)
    out[m] = (16, 14, 22, 255)
    edge = m & ~np.roll(m, 1, axis=1)                          # left edges catch the spotlight
    edge |= m & ~np.roll(m, 1, axis=0)
    out[edge] = (58, 54, 74, 255)
    return Image.fromarray(out, "RGBA")


# ----------------------------------------------------------------------------- preview

def font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except TypeError:
        return ImageFont.load_default()


def label(d, xy, s, sz, fill, anchor="mm"):
    d.text(xy, s, font=font(sz), fill=fill, anchor=anchor, stroke_width=3, stroke_fill=(0, 0, 0))


def preview(tl, pins, frames, sil):
    S = 2
    names = ["GRANDFATHERS", "FATHERS", "PRESENT", "NEXT GEN"]
    sub = ["6 LEGENDS  -  TOKENS 0/21", "36 STARS OR 12 TOKENS", "48 STARS OR 30 TOKENS", "72 STARS OR 48 TOKENS"]
    tour = tl.resize((W * S, H * S), Image.NEAREST).convert("RGBA")
    d = ImageDraw.Draw(tour)
    d.rectangle([0, 0, 1279, HEADER_H * S - 1], fill=BAR_BG)
    d.text((24, 36), "LEGENDS", font=font(36), fill=(255, 228, 140), anchor="lm")
    d.text((640, 36), "THE ERA TOUR  -  TOKENS 0/21", font=font(24), fill=(235, 235, 245), anchor="mm")
    d.rounded_rectangle([1150, 16, 1260, 56], 8, fill=(50, 52, 62), outline=(210, 210, 220), width=2)
    d.text((1205, 36), "BACK", font=font(22), fill=(255, 255, 255), anchor="mm")
    for i in range(4):
        cx = panel_cx(i) * S
        p = pins["grand_open" if i == 0 else CHAPTERS[i]["id"] + "_locked"].resize((PIN_W * S, PIN_H * S),
                                                                                   Image.NEAREST)
        tour.alpha_composite(p, (cx - PIN_ANCHOR[0] * S, RAIL_Y * S - PIN_ANCHOR[1] * S))
        col = (255, 228, 140) if i == 0 else (200, 200, 212)
        label(d, (cx, (RAIL_Y + 22) * S), "CHAPTER %d" % (i + 1), 22, col)
        label(d, (cx, (RAIL_Y + 36) * S), names[i], 30, col)
        label(d, (cx, (RAIL_Y + 52) * S), "PLAY" if i == 0 else "COMING LATER", 22,
              (120, 230, 120) if i == 0 else (170, 170, 186))
        label(d, (cx, (RAIL_Y + 64) * S), sub[i], 17, (230, 230, 238))
    d.text((12, 708), "mock-up: header, labels and buttons drawn by the game (P9-18); pins and backdrop from "
                      "assets/legends/", font=font(14), fill=(190, 190, 200), anchor="lm")
    # hall pieces
    hall_h = 670
    pv = Image.new("RGBA", (1280, 720 + hall_h), (24, 22, 34, 255))
    pv.alpha_composite(tour, (0, 0))
    d2 = ImageDraw.Draw(pv)
    d2.rectangle([0, 720, 1279, 756], fill=(16, 14, 26))
    d2.text((12, 738), "Hall of Legends pieces at 2x (as in the game) and 4x: era frame with a stand-in card (the "
                       "legend cards come in P9-09), the locked plaque with the silhouette, the 6 pins",
             font=font(16), fill=(235, 235, 245), anchor="lm")
    stand_in = card_crop(Image.open(os.path.join(CARDS, "ht_a1.png")).convert("RGBA"))
    fr_card = frames["grand"].copy()
    fr_card.alpha_composite(stand_in, WINDOW[:2])
    fr_lock = frames["locked"].copy()
    fr_lock.alpha_composite(sil, WINDOW[:2])
    x, y = 24, 780
    for im, tag in ((frames["grand"], "frame_grand"), (fr_card, "+ card"), (frames["locked"], "frame_locked"),
                    (fr_lock, "+ silhouette")):
        big = im.resize((FRAME_W * 2, FRAME_H * 2), Image.NEAREST)
        pv.alpha_composite(big, (x, y))
        d2.text((x + FRAME_W, y + FRAME_H * 2 + 14), tag, font=font(15), fill=(220, 220, 230), anchor="mm")
        x += FRAME_W * 2 + 24
    nm = ImageDraw.Draw(pv)
    x += 10
    for im in (fr_card, fr_lock):
        big = im.resize((FRAME_W * 4, FRAME_H * 4), Image.NEAREST)
        pv.alpha_composite(big, (x, y))
        x += FRAME_W * 4 + 24
    # sample name plate text the game would draw (2x and 4x)
    for (px0, sc, s) in ((24 + FRAME_W * 2 + 24, 2, "STEEPLE"), (24 + 3 * (FRAME_W * 2 + 24), 2, "?"),
                         (x - 2 * (FRAME_W * 4 + 24), 4, "STEEPLE"), (x - (FRAME_W * 4 + 24), 4, "?")):
        cxp = px0 + (PLATE[0] + PLATE[2] / 2) * sc
        cyp = y + (PLATE[1] + PLATE[3] / 2) * sc
        nm.text((cxp, cyp), s, font=font(8 * sc), fill=(255, 250, 230), anchor="mm", stroke_width=2,
                stroke_fill=(0, 0, 0))
    # pins at 4x
    x, y = 24, 1180
    for key in ("grand_open", "grand_done", "grand_locked", "fathers_locked", "present_locked", "next_locked"):
        big = pins[key].resize((PIN_W * 4, PIN_H * 4), Image.NEAREST)
        pv.alpha_composite(big, (x, y))
        d2.text((x + PIN_W * 2, y + PIN_H * 4 + 12), "pin_" + key.replace("_open", ""), font=font(15),
                fill=(220, 220, 230), anchor="mm")
        x += PIN_W * 4 + 40
    pv.convert("RGB").save(PREVIEW, optimize=True)
    print("wrote", os.path.relpath(PREVIEW, ROOT))


def main():
    os.makedirs(OUT, exist_ok=True)
    tl = draw_timeline()
    pins = {
        "grand_open": pin_image("grand", "open"),
        "grand_done": pin_image("grand", "done"),
        "grand_locked": pin_image("grand", "locked"),
        "fathers_locked": pin_image("fathers", "locked"),
        "present_locked": pin_image("present", "locked"),
        "next_locked": pin_image("next", "locked"),
    }
    frames = {"grand": frame_image("grand"), "locked": frame_image("locked")}
    sil = silhouette_image()
    files = {"timeline.png": tl, "frame_grand.png": frames["grand"], "frame_locked.png": frames["locked"],
             "silhouette.png": sil}
    for k, im in pins.items():
        files["pin_" + k.replace("_open", "") + ".png"] = im
    for fn, im in files.items():
        p = os.path.join(OUT, fn)
        im.save(p, optimize=True)
        print("wrote %s %s %d bytes" % (os.path.relpath(p, ROOT), im.size, os.path.getsize(p)))
    data = {
        "_help": ["Texel numbers (draw everything at 2 canvas px per texel, like the trip map). timeline.png is",
                  "640 x 360 with rows 0..header_h-1 kept for the header; pin_points are where each chapter's pin",
                  "tip goes (pin_anchor inside the 32 x 40 pin), left to right in chapter order; label_y is a good",
                  "first row for the chapter name under the rail. On 1280 x 800 centre the backdrop (y + 40) and",
                  "fill the bars with bar_bg. Frames are 56 x 88: draw the frame, then the card's card_crop (a",
                  "64 x 96 v2 card) or silhouette.png at window's x, y; the name plate rect is free for text."],
        "size": [W, H], "header_h": HEADER_H, "bar_bg": "#%02x%02x%02x" % BAR_BG,
        "chapters": [c["id"] for c in CHAPTERS],
        "panels": [[panel_x(i), PANEL_Y0, PANEL_W, PANEL_Y1 - PANEL_Y0 + 1] for i in range(4)],
        "rail_y": RAIL_Y, "label_y": RAIL_Y + 14,
        "pin_points": [[panel_cx(i), RAIL_Y] for i in range(4)],
        "pin_size": [PIN_W, PIN_H], "pin_anchor": list(PIN_ANCHOR),
        "pins": {"grand": {"open": "pin_grand.png", "done": "pin_grand_done.png", "locked": "pin_grand_locked.png"},
                 "fathers": {"locked": "pin_fathers_locked.png"}, "present": {"locked": "pin_present_locked.png"},
                 "next": {"locked": "pin_next_locked.png"}},
        "frame_size": [FRAME_W, FRAME_H], "frames": {"grand": "frame_grand.png", "locked": "frame_locked.png"},
        "window": list(WINDOW), "card_crop": list(CARD_CROP), "name_plate": list(PLATE),
        "silhouette": "silhouette.png",
    }
    with open(os.path.join(OUT, "ui.json"), "w") as fh:
        json.dump(data, fh, indent=1)
        fh.write("\n")
    print("wrote assets/legends/ui.json")
    preview(tl, pins, frames, sil)


if __name__ == "__main__":
    main()
