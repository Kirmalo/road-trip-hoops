#!/usr/bin/env python3
"""How to Play pictures for Road Trip Hoops (P7-H2), composed from the game's own screenshots.

Input: the raw in-game captures (1280 x 720), committed in tools/art/howto_raw/ so this reruns (a .gdignore there
keeps Godot from importing them; tools/ is not exported anyway):
  howto_<id>.png for controls, turbo, shoot, dunks, moves, call, defense, fire, and the insets howto_dunks_b.png and
  howto_defense_b.png, from the capture driver (P7-H1):
      xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- \
          --howto-shots DIR --court gym --difficulty hard --quick-teams cornfield_kings,bridge_runners
  howto_trip.png (the first trip map, /tmp/hoops_screen_04_map.png) and howto_trip_b.png (the lineup with three
  starters picked, /tmp/hoops_screen_21_lineup_picked.png), from
      xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 \
          --quit-after 2000000 -- --trip-test --target 3 --screens

Each picture is cropped and scaled from its capture (1:1, 0.75x smooth, or 2x nearest for the fire close-up) and gets
overlays drawn here in the style sample v1 look: flat colour bands, a bold dark ink outline, the game's own colours
(the button colours of scripts/touch_controls.gd, the title gold of scripts/ui_kit.gd, the ball of
assets/ball/ball.png). The overlays are drawn on a 2 px grid so they read as pixel art: arrows, a thumb, rings and
boxes around buttons, sparkles. No text is added (the page text is written by scripts/howto.gd).

Usage:  python3 tools/art/make_howto.py [raw dir]          (default tools/art/howto_raw)
Output: assets/howto/<id>.png   960 x 540, for the 9 page ids below (8-bit palette PNGs, to stay small)
        docs/art/howto_preview_v1.png   contact sheet of all 9, for the owner
Reruns are byte-identical (no randomness, no time stamps). Needs: Pillow, numpy
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_DEFAULT = os.path.join(ROOT, "tools", "art", "howto_raw")
OUT_DIR = os.path.join(ROOT, "assets", "howto")
PREVIEW = os.path.join(ROOT, "docs", "art", "howto_preview_v1.png")
BALL_PNG = os.path.join(ROOT, "assets", "ball", "ball.png")

PAGES = ["controls", "turbo", "shoot", "dunks", "moves", "call", "defense", "fire", "trip"]
W, H = 960, 540           # picture size (docs/BOARD.md "How to Play pages")
PX = 2                    # overlay pixel size: overlays are drawn at W/PX x H/PX and scaled up with nearest
COLORS = 255              # palette size of the written PNGs (adaptive, no dithering: crisp and small)


def rgb(c):
    """Godot Color floats -> 0..255 tuple."""
    return tuple(int(round(v * 255)) for v in c)


# palette: the game's own colours
INK = (26, 18, 30)                         # outline (make_icon.py INK)
CREAM = (255, 244, 208)
GOLD = rgb((1.0, 0.82, 0.25))              # ui_kit.gd LIT_COLOR
GOLD_LIGHT = (255, 240, 160)
GOLD_DARK = (232, 168, 40)
ORANGE = rgb((0.95, 0.45, 0.1))            # touch_controls.gd SHOOT
ORANGE_LIGHT = (255, 170, 90)
TURBO = rgb((1.0, 0.6, 0.2))               # touch_controls.gd sprint knob / turbo ring
BLUE = rgb((0.2, 0.5, 0.95))               # touch_controls.gd PASS
CALL_LIT = rgb((0.45, 0.8, 1.0))           # touch_controls.gd CALL_LIT_COLOR
CALL_LIGHT = (200, 236, 255)
STEAL = rgb((1.0, 0.85, 0.3))
BLOCK = rgb((0.9, 0.3, 0.12))              # touch_controls.gd BLOCK_COLOR
GREEN = (72, 200, 72)
GREEN_LIGHT = (170, 240, 150)
FLAME = [(255, 244, 160), (255, 196, 64), (245, 120, 30), (200, 60, 20)]    # light .. dark
SKIN = [(250, 214, 178), (226, 170, 124), (190, 128, 86), (140, 88, 58)]   # thumb: light .. dark
FRAME_BG = rgb((0.1, 0.12, 0.18))          # ui_kit.gd PANEL_COLOR


# ----------------------------------------------------------------------------- base pictures

def load(raw, name):
    path = os.path.join(raw, name + ".png")
    if not os.path.exists(path):
        sys.exit("make_howto: missing raw capture %s" % path)
    return Image.open(path).convert("RGB")


def crop_scale(img, box, size, nearest=False):
    """Crop box (x, y, w, h) of img and scale it to size (w, h)."""
    x, y, w, h = box
    part = img.crop((x, y, x + w, y + h))
    if (w, h) == tuple(size):
        return part
    return part.resize(size, Image.NEAREST if nearest else Image.LANCZOS)


class View:
    """Maps capture pixels to picture pixels for one cropped and scaled piece."""

    def __init__(self, box, dest_xy, dest_size):
        self.box = box
        self.dx, self.dy = dest_xy
        self.sx = dest_size[0] / box[2]
        self.sy = dest_size[1] / box[3]

    def __call__(self, p):
        return (self.dx + (p[0] - self.box[0]) * self.sx, self.dy + (p[1] - self.box[1]) * self.sy)

    def r(self, v):
        return v * self.sx


def paste_inset(base, img, box, dest_xy, scale, nearest=False):
    """Paste a framed inset (crop box of img at scale) with its top-left at dest_xy; returns its View."""
    size = (int(round(box[2] * scale)), int(round(box[3] * scale)))
    part = crop_scale(img, box, size, nearest)
    x, y = dest_xy
    d = ImageDraw.Draw(base)
    # frame: ink, gold band with a light top edge, ink (style sample v1 panels)
    d.rectangle((x - 10, y - 10, x + size[0] + 9, y + size[1] + 9), fill=INK)
    d.rectangle((x - 8, y - 8, x + size[0] + 7, y + size[1] + 7), fill=GOLD_DARK)
    d.rectangle((x - 8, y - 8, x + size[0] + 7, y - 7), fill=GOLD_LIGHT)
    d.rectangle((x - 8, y - 6, x + size[0] + 5, y + size[1] + 5), fill=GOLD)
    d.rectangle((x - 2, y - 2, x + size[0] + 1, y + size[1] + 1), fill=INK)
    base.paste(part, (x, y))
    return View(box, dest_xy, size)


# ----------------------------------------------------------------------------- overlay drawing (2 px grid)

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


class Overlay:
    """Elements drawn one by one on a W/PX x H/PX grid; each gets its own ink outline, then is stacked."""

    def __init__(self):
        self.img = Image.new("RGBA", (W // PX, H // PX), (0, 0, 0, 0))

    def element(self):
        layer = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        return layer, ImageDraw.Draw(layer)

    def add(self, layer, ink=1):
        a = np.array(layer)[:, :, 3] > 0
        if ink > 0:
            ring = dilate(a, ink)
            out = np.zeros((a.shape[0], a.shape[1], 4), np.uint8)
            out[ring] = INK + (255,)
            self.img.alpha_composite(Image.fromarray(out, "RGBA"))
        self.img.alpha_composite(layer)

    def apply(self, base):
        up = self.img.resize((W, H), Image.NEAREST)
        out = base.convert("RGBA")
        out.alpha_composite(up)
        return out.convert("RGB")


def q(p):
    """Picture pixels -> overlay grid."""
    return (int(round(p[0] / PX)), int(round(p[1] / PX)))


def lighter(c, t=0.45):
    return tuple(int(round(v + (255 - v) * t)) for v in c)


def darker(c, t=0.3):
    return tuple(int(round(v * (1 - t))) for v in c)


def bezier(p0, p1, p2, n=40):
    """Quadratic curve through control p1, n + 1 points."""
    pts = []
    for i in range(n + 1):
        t = i / n
        a = (1 - t) * (1 - t)
        b = 2 * (1 - t) * t
        c = t * t
        pts.append((a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1]))
    return pts


def resample(pts, step=4.0):
    """The polyline with points at most step picture pixels apart."""
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.ceil(math.dist(a, b) / step)))
        for i in range(1, n + 1):
            out.append((a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n))
    return out


def _thick(d, pts, color, w):
    pts = [q(p) for p in pts]
    d.line(pts, fill=color, width=w, joint="curve")
    r = w / 2.0
    for p in (pts[0], pts[-1]):
        d.ellipse((p[0] - r + 0.5, p[1] - r + 0.5, p[0] + r - 0.5, p[1] + r - 0.5), fill=color)


def arrow(ov, pts, color=GOLD, w=4, head=7, dashed=False, ink=1):
    """A bold arrow along picture-space points, the head at the last point."""
    layer, d = ov.element()
    pts = resample(pts)
    end = pts[-1]
    # back the shaft off the head
    k = len(pts) - 1
    while k > 0 and math.dist(pts[k], end) < head * PX * 0.9:
        k -= 1
    shaft = pts[:k + 1]
    ang = math.atan2(end[1] - pts[k][1], end[0] - pts[k][0])
    if dashed:
        seg, on, acc, cur = [], True, 0.0, [shaft[0]]
        dash = 9.0 * PX
        for a, b in zip(shaft, shaft[1:]):
            acc += math.dist(a, b)
            cur.append(b)
            if acc >= dash:
                if on:
                    seg.append(cur)
                on, acc, cur = not on, 0.0, [b]
        if on and len(cur) > 1:
            seg.append(cur)
        for s in seg:
            _thick(d, s, color, w)
            d.line([q(p) for p in s], fill=lighter(color), width=1)
    else:
        _thick(d, shaft, color, w)
        # light band along the shaft (flat highlight, light from the upper left)
        d.line([(x, y - 1) for x, y in (q(p) for p in shaft[:-1])], fill=lighter(color), width=1)
    tip = q(end)
    hl = head
    pa = (tip[0] - hl * math.cos(ang) + hl * 0.8 * math.sin(ang), tip[1] - hl * math.sin(ang) - hl * 0.8 * math.cos(ang))
    pb = (tip[0] - hl * math.cos(ang) - hl * 0.8 * math.sin(ang), tip[1] - hl * math.sin(ang) + hl * 0.8 * math.cos(ang))
    d.polygon([tip, pa, pb], fill=color)
    ov.add(layer, ink)


def ring(ov, c, r, color=GOLD, w=3, dashed=False, ry=None, ink=1):
    """A bold ring (ellipse when ry is given) around a picture-space point."""
    layer, d = ov.element()
    cx, cy = q(c)
    rx = r / PX
    ryy = (ry if ry is not None else r) / PX
    box = (cx - rx, cy - ryy, cx + rx, cy + ryy)
    if dashed:
        n = 14
        for i in range(n):
            a0 = 360.0 * i / n
            d.arc(box, a0, a0 + 360.0 / n * 0.55, fill=color, width=w)
    else:
        d.ellipse(box, outline=color, width=w)
        inner = (box[0] + w - 1, box[1] + w - 1, box[2] - w + 1, box[3] - w + 1)
        d.arc(inner, 180, 300, fill=lighter(color), width=1)
    ov.add(layer, ink)


def rbox(ov, box, color=GOLD, w=3, radius=6, ink=1):
    """A bold rounded box around a picture-space rectangle (x0, y0, x1, y1)."""
    layer, d = ov.element()
    a, b = q(box[:2]), q(box[2:])
    d.rounded_rectangle((a[0], a[1], b[0], b[1]), radius=radius, outline=color, width=w)
    d.line((a[0] + radius, a[1] + w - 1, b[0] - radius, a[1] + w - 1), fill=lighter(color), width=1)
    ov.add(layer, ink)


def sparkle(ov, c, size=7, color=GOLD_LIGHT, ink=1):
    """A 4-point star."""
    layer, d = ov.element()
    x, y = q(c)
    s, t = size, max(1, size // 3)
    d.polygon([(x, y - s), (x + t, y - t), (x + s, y), (x + t, y + t), (x, y + s), (x - t, y + t), (x - s, y), (x - t, y - t)],
              fill=color)
    d.point((x, y), fill=(255, 255, 255))
    ov.add(layer, ink)


def ticks(ov, c, r0, r1, angles, color=CREAM, w=2, ink=1):
    """Short strokes radiating from c (a tap, a glow)."""
    layer, d = ov.element()
    for a in angles:
        ra = math.radians(a)
        p0 = (c[0] + r0 * math.cos(ra), c[1] + r0 * math.sin(ra))
        p1 = (c[0] + r1 * math.cos(ra), c[1] + r1 * math.sin(ra))
        _thick(d, [p0, p1], color, w)
    ov.add(layer, ink)


def lines(ov, segs, color=CREAM, w=2, ink=1):
    """Speed lines: a list of (p0, p1)."""
    layer, d = ov.element()
    for p0, p1 in segs:
        _thick(d, [p0, p1], color, w)
    ov.add(layer, ink)


def thumb(ov, tip, angle, length=60, ink=1, tap=True):
    """A thumb pressing at tip (picture space); angle (degrees) points from the tip back to the hand."""
    layer, d = ov.element()
    ux, uy = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    vx, vy = -uy, ux                                      # across the thumb

    def P(a, b):                                          # a along the thumb, b across, in overlay pixels
        t = q(tip)
        return (t[0] + ux * a + vx * b, t[1] + uy * a + vy * b)

    r = 10.0                                              # half width of the thumb (overlay pixels)
    L = length / PX

    def tip_capsule(a0, a1, rad, off=0.0, n=12):
        pts = []
        c = a0 + rad
        for i in range(n + 1):
            th = math.pi * i / n                          # half circle on the tip side
            pts.append(P(c - rad * math.sin(th), off + rad * math.cos(th)))
        pts.append(P(a1, off - rad))
        pts.append(P(a1, off + rad))
        return pts

    # the base of the thumb flares into the hand (a rounded end)
    hr = r * 1.5
    flare = [P(L * 0.4, -r), P(L + 2, -hr)]
    for i in range(1, 12):
        th = -math.pi / 2 + math.pi * i / 12
        flare.append(P(L + 2 + hr * 0.8 * math.cos(th), hr * math.sin(th)))
    flare += [P(L + 2, hr), P(L * 0.4, r)]
    d.polygon(flare, fill=SKIN[2])
    d.polygon(tip_capsule(0, L + 4, r), fill=SKIN[2])                   # shadow side
    d.polygon(tip_capsule(0, L + 4, r - 2.5, off=-2.5), fill=SKIN[1])   # base tone, shifted to the light side
    d.polygon([P(L * 0.5, -r + 2.5), P(L + 2, -hr + 2.5), P(L + 2, hr - 6), P(L * 0.5, r - 5)], fill=SKIN[1])
    d.polygon(tip_capsule(3, L - 6, 3, off=-6), fill=SKIN[0])           # light band
    d.polygon(tip_capsule(2, 15, r - 4.5, off=1.5), fill=SKIN[0])       # nail
    d.polygon(tip_capsule(3, 13, r - 7, off=-0.5), fill=(255, 236, 216))
    k1, k2 = P(L * 0.62, -r + 1), P(L * 0.62, r - 3)                    # knuckle crease
    d.line((k1, k2), fill=SKIN[3], width=1)
    d.line((P(L * 0.72, -r + 3), P(L * 0.72, r - 5)), fill=SKIN[3], width=1)
    ov.add(layer, ink)
    if tap:
        ticks(ov, tip, 18, 30, [angle + 180 + a for a in (-70, -35, 0, 35, 70)], CREAM, 2)


def ball_icon(ov, c, scale=2, ink=1):
    """The game's ball (assets/ball/ball.png frame 0) at scale overlay pixels per ball pixel."""
    ball = Image.open(BALL_PNG).convert("RGBA").crop((0, 0, 16, 16))
    ball = ball.resize((16 * scale, 16 * scale), Image.NEAREST)
    layer, _ = ov.element()
    x, y = q(c)
    layer.alpha_composite(ball, (x - 8 * scale, y - 8 * scale))
    ov.add(layer, ink)


def check(ov, c, s=8, color=GREEN, ink=1):
    layer, d = ov.element()
    x, y = q(c)
    d.line([(x - s, y), (x - s // 3, y + s * 2 // 3), (x + s, y - s)], fill=color, width=4, joint="curve")
    d.line([(x - s, y - 1), (x - s // 3, y + s * 2 // 3 - 1), (x + s, y - s - 1)], fill=lighter(color), width=1)
    ov.add(layer, ink)


def flame(ov, base, h=26, w=10, lean=0.0, ink=1):
    """A flame tongue standing on base (picture space), in 4 flat bands."""
    layer, d = ov.element()
    x, y = q(base)
    for i, col in enumerate(reversed(FLAME)):             # dark (big) .. light (small)
        k = 1.0 - 0.22 * i
        hh, ww = h * k / PX, w * k / PX
        tipx = x + lean * hh
        d.polygon([(x - ww / 2, y), (x - ww * 0.55, y - hh * 0.35), (tipx, y - hh), (x + ww * 0.55, y - hh * 0.35),
                   (x + ww / 2, y)], fill=col)
        d.ellipse((x - ww / 2, y - ww / 2, x + ww / 2, y + ww / 2 - 1), fill=col)
    ov.add(layer, ink)


def panel(ov, box, ink=1):
    """A small dark panel with a gold edge (the ui_kit look) behind icons."""
    layer, d = ov.element()
    a, b = q(box[:2]), q(box[2:])
    d.rounded_rectangle((a[0], a[1], b[0], b[1]), radius=5, fill=FRAME_BG + (235,), outline=GOLD, width=2)
    ov.add(layer, ink)


# ----------------------------------------------------------------------------- helpers on captures

def trace_arc(img, y0, y1, x0, x1, step=4):
    """The three-point arc in a capture: the leftmost court-line white in [x0, x1] on each row (gaps skipped)."""
    a = np.asarray(img).astype(int)
    white = (a[:, :, 0] > 225) & (a[:, :, 1] > 225) & (a[:, :, 2] > 225)
    pts = []
    for y in range(y0, y1 + 1, step):
        xs = np.nonzero(white[y, x0:x1])[0]
        if len(xs):
            pts.append((x0 + int(xs[0]), y))
    return pts


def runs(pts, max_gap=12):
    """Split a traced polyline at gaps."""
    out, cur = [], [pts[0]]
    for a, b in zip(pts, pts[1:]):
        if math.dist(a, b) > max_gap:
            out.append(cur)
            cur = []
        cur.append(b)
    out.append(cur)
    return [r for r in out if len(r) > 1]


# ----------------------------------------------------------------------------- the pages

def page_controls(raw):
    img = load(raw, "howto_controls")
    v = View((0, 0, 1280, 720), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H))
    ov = Overlay()
    joy, knob = (260, 460), (340, 450)
    # the joystick: ring callout and the four ways it moves
    ring(ov, v(joy), v.r(98), GOLD, 3)
    for ang in (0, 90, 180, 270):
        a = math.radians(ang)
        p0 = v((joy[0] + 108 * math.cos(a), joy[1] + 108 * math.sin(a)))
        p1 = v((joy[0] + 150 * math.cos(a), joy[1] + 150 * math.sin(a)))
        arrow(ov, [p0, p1], CREAM, w=3, head=6)
    # SHOOT (A) and PASS (B) callouts
    ring(ov, v((1160, 590)), v.r(90), ORANGE_LIGHT, 3)
    ring(ov, v((1000, 630)), v.r(72), CALL_LIT, 3)
    # the human: the yellow ring at his feet is you
    ring(ov, v((1128, 455)), v.r(62), GOLD, 3, dashed=True, ry=v.r(30))
    thumb(ov, v(knob), 125, 70)
    thumb(ov, v((1200, 648)), 40, 64)
    return ov.apply(base)


def page_turbo(raw):
    img = load(raw, "howto_turbo")
    v = View((0, 160, 960, 540), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H))
    ov = Overlay()
    joy = (260, 460)
    ring(ov, v(joy), v.r(120), TURBO, 3, dashed=True)               # the turbo ring
    d = (-0.95, -0.31)                                                # the way the thumb pulls (the knob's way)
    n = (-0.31, 0.95)                                                 # beside it, so the arrow shows
    thumb(ov, v((joy[0] + d[0] * 150, joy[1] + d[1] * 150)), 125, 64)
    arrow(ov, [v((joy[0] - n[0] * 40 + d[0] * 10, joy[1] - n[1] * 40 + d[1] * 10)),
               v((joy[0] - n[0] * 40 + d[0] * 165, joy[1] - n[1] * 40 + d[1] * 165))], TURBO, w=4, head=7)
    # the stamina bar draining
    rbox(ov, (v((604, 370))[0], v((604, 370))[1], v((710, 406))[0], v((710, 406))[1]), GOLD, 3, 4)
    arrow(ov, [v((725, 360)), v((725, 400))], GOLD, w=3, head=6)
    return ov.apply(base)


def page_shoot(raw):
    img = load(raw, "howto_shoot")
    v = View((320, 175, 960, 540), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H))
    ov = Overlay()
    # the arc: 1 point inside, 2 beyond
    arc = trace_arc(img, 252, 668, 600, 960)
    for run in runs([v(p) for p in arc], 24):
        arrow_free = len(run) > 2
        if arrow_free:
            layer, d = ov.element()
            dash, on, acc, cur = 10.0, True, 0.0, [run[0]]
            for a, b in zip(run, run[1:]):
                acc += math.dist(a, b)
                cur.append(b)
                if acc >= dash * PX:
                    if on:
                        _thick(d, cur, GOLD, 3)
                    on, acc, cur = not on, 0.0, [b]
            ov.add(layer, 1)
    # the shot meter: release in the green
    rbox(ov, (v((734, 180))[0], v((734, 180))[1], v((848, 218))[0], v((848, 218))[1]), GOLD, 3, 4)
    arrow(ov, bezier(v((930, 150 + 25)), v((880, 175)), v((852, 198))), GREEN, w=3, head=6)
    # hold SHOOT
    ring(ov, v((1160, 590)), v.r(90), GOLD, 3)
    thumb(ov, v((1196, 646)), 45, 64)
    return ov.apply(base)


def page_dunks(raw):
    img = load(raw, "howto_dunks")
    v = View((0, 160, 960, 540), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H))
    ov = Overlay()
    # the dunk: up from the floor to the rim
    arrow(ov, bezier(v((330, 470)), v((360, 250)), v((190, 222))), GOLD, w=4, head=8)
    sparkle(ov, v((112, 228)), 8)
    sparkle(ov, v((180, 190)), 6)
    sparkle(ov, v((118, 300)), 5)
    # the alley-oop inset: a lob to the cutter
    lob = load(raw, "howto_dunks_b")
    iv = paste_inset(base, lob, (500, 170, 780, 420), (566, 316), 0.48)
    arrow(ov, bezier(iv((650, 290)), iv((800, 120)), iv((1110, 330))), CREAM, w=3, head=7, dashed=True)
    ring(ov, iv((1140, 520)), iv.r(70), GOLD, 3, dashed=True, ry=iv.r(32))
    return ov.apply(base)


def page_moves(raw):
    img = load(raw, "howto_moves")
    v = View((110, 150, 960, 540), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H))
    ov = Overlay()
    joy, knob = (260, 460), (210, 415)
    # the flick: a quick side-to-side on the stick
    arrow(ov, bezier(v((300, 360)), v((260, 330)), v((185, 360))), CREAM, w=3, head=6)
    arrow(ov, bezier(v((220, 560)), v((260, 590)), v((335, 560))), CREAM, w=3, head=6)
    thumb(ov, v(knob), 120, 64)
    # the crossover: the ball goes across, the defender is beaten
    arrow(ov, bezier(v((588, 478)), v((650, 530)), v((728, 470))), GOLD, w=4, head=7)
    sparkle(ov, v((548, 288)), 7)
    sparkle(ov, v((520, 330)), 5, CREAM)
    sparkle(ov, v((566, 250)), 4, CREAM)
    return ov.apply(base)


def page_call(raw):
    img = load(raw, "howto_call")
    v = View((0, 0, 1280, 720), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H))
    ov = Overlay()
    # CALL (B) lit, you shout for the ball, the ball comes to you
    ring(ov, v((1000, 630)), v.r(92), GOLD, 3)
    ticks(ov, v((1000, 630)), v.r(100), v.r(122), [200, 235, 270, 305], GOLD_LIGHT, 2)
    arrow(ov, bezier(v((1060, 255)), v((1265, 320)), v((1150, 430))), CREAM, w=4, head=8, dashed=True)
    thumb(ov, v((1036, 676)), 50, 64, tap=False)
    return ov.apply(base)


def page_defense(raw):
    img = load(raw, "howto_defense")
    v = View((320, 170, 960, 540), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H))
    ov = Overlay()
    # STEAL glows: tap it next to the ball handler
    ring(ov, v((548, 425)), v.r(46), GOLD, 3, dashed=True)
    for p, s in (((1060, 500), 8), ((1262, 520), 6), ((1250, 680), 7), ((1075, 690), 5)):
        sparkle(ov, v(p), s)
    thumb(ov, v((1200, 650)), 45, 64)
    # inset: BLOCK at a shooter
    blk = load(raw, "howto_defense_b")
    iv = paste_inset(base, blk, (0, 140, 1280, 580), (586, 18), 0.28)
    arrow(ov, [iv((330, 420)), iv((330, 360)), iv((205, 270))], GOLD, w=3, head=6)
    ring(ov, iv((1160, 590)), iv.r(96), GOLD, 2)
    return ov.apply(base)


def page_fire(raw):
    img = load(raw, "howto_fire")
    v = View((490, 140, 480, 270), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H), nearest=True)
    ov = Overlay()
    hot, ball = (735, 322), (728, 248)
    # flames around the hot hand's feet and a blazing ball
    for ang, h in ((175, 46), (140, 62), (40, 60), (5, 44)):         # on the front of his feet ring
        a = math.radians(ang)
        lean = 0.35 * math.cos(a)
        flame(ov, v((hot[0] + 44 * math.cos(a), hot[1] + 4 + 16 * math.sin(a))), h, 22, lean)
    ticks(ov, v(ball), v.r(22), v.r(32), [-160, -125, -90, -55, -20, 160, 20], FLAME[1], 2)
    # 3 makes in a row
    panel(ov, (20, 20, 296, 112))
    for i in range(3):
        c = (62 + i * 88, 70)
        if i == 2:
            flame(ov, (c[0], c[1] + 16), 86, 48, 0.0)            # the third make sets him on fire
        ball_icon(ov, c, 2)
        check(ov, (c[0] + 22, c[1] + 18), 8)
    return ov.apply(base)


def page_trip(raw):
    img = load(raw, "howto_trip")
    v = View((0, 0, 1280, 720), (0, 0), (W, H))
    base = crop_scale(img, v.box, (W, H))
    ov = Overlay()
    # next stop: the van rolls from Hometown to Chicago
    arrow(ov, bezier(v((772, 334)), v((732, 322)), v((774, 286))), GOLD, w=3, head=6)
    sparkle(ov, v((806, 244)), 7)
    sparkle(ov, v((760, 238)), 5, CREAM)
    # GO
    rbox(ov, (v((966, 560))[0], v((966, 560))[1], v((1266, 710))[0], v((1266, 710))[1]), GOLD_LIGHT, 3, 10)
    thumb(ov, v((1196, 684)), 40, 60)
    # inset: the lineup, three starters picked
    lu = load(raw, "howto_trip_b")
    paste_inset(base, lu, (12, 120, 832, 392), (22, 336), 0.5)
    return ov.apply(base)


BUILDERS = {
    "controls": page_controls, "turbo": page_turbo, "shoot": page_shoot, "dunks": page_dunks,
    "moves": page_moves, "call": page_call, "defense": page_defense, "fire": page_fire, "trip": page_trip,
}


def save_png(img, path):
    pal = img.quantize(colors=COLORS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    pal.save(path, optimize=True)


def contact_sheet(pics):
    cw, ch, gap = 480, 270, 12
    sheet = Image.new("RGB", (3 * cw + 4 * gap, 3 * ch + 4 * gap), INK)
    for i, img in enumerate(pics):
        x = gap + (i % 3) * (cw + gap)
        y = gap + (i // 3) * (ch + gap)
        sheet.paste(img.resize((cw, ch), Image.LANCZOS), (x, y))
    return sheet


def main():
    raw = sys.argv[1] if len(sys.argv) > 1 else RAW_DEFAULT
    os.makedirs(OUT_DIR, exist_ok=True)
    pics, total = [], 0
    for pid in PAGES:
        img = BUILDERS[pid](raw)
        assert img.size == (W, H)
        path = os.path.join(OUT_DIR, pid + ".png")
        save_png(img, path)
        total += os.path.getsize(path)
        pics.append(Image.open(path).convert("RGB"))
        print("%-9s %7d bytes" % (pid, os.path.getsize(path)))
    print("total     %7d bytes" % total)
    save_png(contact_sheet(pics), PREVIEW)
    print("preview  ", PREVIEW)


if __name__ == "__main__":
    main()
