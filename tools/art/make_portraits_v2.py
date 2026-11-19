#!/usr/bin/env python3
"""Story portraits v2 for Road Trip Hoops (P5-A2): drawn comic-book busts, the full cast.

Owner feedback on v1: "a higher quality, make it look like drawn comic style". v2 draws each bust as 2D comic art
with tools/art/comic.py: curved shapes placed by hand per character, hard-edged cel tones from the game palette
(tools/art/crews.json), halftone-dot and hatched deep shadows, crisp highlights, variable-weight ink lines
(heavier on the side away from the light), a bold outer contour. The heads are in 3/4 view facing right
(story.gd mirrors for the right side). Original characters; nothing is traced, downloaded or copied.

The owner approved sample v2 (Deuce, Jojo, Tank, Mayor); the rest of the cast (CAST below: Hometown's County
Line, Chicago's Lakeshore Gusts, New York's King) is drawn with the same kit, parts and lighting, each matching
his sprite in tools/art/crews.json (skin, hair, headwear, outfit, colors).

Usage:  python3 tools/art/make_portraits_v2.py              every portrait + the full preview
        python3 tools/art/make_portraits_v2.py --sample     also redraw the approved sample sheet
        python3 tools/art/make_portraits_v2.py --legends    only the Grandfathers (LG below) + their contact sheet
        python3 tools/art/make_portraits_v2.py ht_g1 ...    a quick row of those characters (ROW_OUT), writes nothing
Output: assets/portraits/<id>.png           288 x 336 (the 96 x 112 contract at 3x), base portrait
        assets/portraits/<id>_<mood>.png    the moods story_text.gd uses (happy; bosses also smug)
        docs/art/portraits_full_v2.png      two story mock-ups and every portrait, labeled (Phase 5 cast)
        docs/art/portraits_p6.png           the same for the Phase 6 cast (P6-A4: the five new city crews and the
                                            New York crews, specs in P6 below)
        docs/art/legends_portraits.png      the six Grandfathers of Legends Chapter 1 (P9-10, specs in LG below)
Needs:  Pillow, numpy
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import comic as C  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "assets", "portraits")
SHEET = os.path.join(ROOT, "docs", "art", "portraits_sample_v2.png")      # only with --sample
FULL_SHEET = os.path.join(ROOT, "docs", "art", "portraits_full_v2.png")
PW, PH = 288, 336

SAMPLE = {
    "ud_deuce": [("focus", ""), ("happy", "_happy")],
    "ud_jojo": [("focus", ""), ("happy", "_happy")],
    "ud_tank": [("focus", ""), ("happy", "_happy")],
    "ht_boss": [("neutral", ""), ("smug", "_smug")],
}
NAMES = {"ud_deuce": "DEUCE", "ud_jojo": "JOJO", "ud_tank": "TANK", "ht_boss": "MAYOR"}
EXPR_LABEL = {"focus": "determined", "happy": "happy", "smug": "smug", "neutral": "neutral"}

ZOOM = 1.12    # the bust drawn a little bigger than its layout coordinates (head fills the frame)
FRONT = 7.0    # widens the front of the face (more of a 3/4 view, less profile)
EYE_WHITE = {"hi": (255, 255, 255), "lt": (250, 246, 240), "base": (240, 234, 228), "sh": (196, 186, 196),
             "dp": (150, 140, 160)}
MOUTH = (70, 22, 34)
TONGUE = (200, 82, 92)


def load():
    with open(os.path.join(ROOT, "tools", "art", "crews.json")) as f:
        d = json.load(f)
    pal = d["palettes"]
    players = {p["id"]: p for p in d["players"]}
    return pal, d["skins"], players


# ----------------------------------------------------------------------------- head geometry (head-local px)
# Origin near the middle of the skull at eye level; the face looks to +x (3/4 view), the ear is at x ~ -20.

def head_outline(jaw=0.0, chin=0.0, crown=0.0, nose=0.0):
    j, c, k, n = jaw, chin, crown, nose
    return [
        (-50, -60 - k), (-22, -82 - k), (14, -85 - k), (42, -74 - k), (58, -52), (63, -30),
        (66, -14), (61, -3, 0), (64 + n * 0.2, 5), (71 + n * 0.6, 14), (80 + c * 0.3 + n, 25), (79 + n, 30 + n * 0.3, 0),
        (70 + n * 0.4, 31 + n * 0.3), (67, 33, 0),
        (70, 38), (69, 43), (66, 46, 0), (69, 51), (66 + c, 57), (68 + c, 65), (64 + c, 73 + j * 0.5),
        (50 + c, 80 + j), (30, 78 + j), (8, 68 + j), (-16 - j * 0.4, 52 + j * 0.6), (-30 - j * 0.6, 36), (-44, 26),
        (-58, 4), (-62, -28),
    ]


EAR = [(-14, -10), (-24, -15), (-33, -7), (-35, 7), (-31, 20), (-22, 28), (-15, 25), (-12, 10)]
EAR_IN = [(-17, -6), (-27, -7), (-30, 5), (-25, 17), (-19, 19)]

# eyes: (upper lid, lower lid) in an eye frame: outer corner at -x, inner corner at +x, width ~26
EYES = {
    "neutral": ([(-13, 1), (-6, -6), (5, -7), (13, 1)], [(-11, 3), (0, 6), (11, 3)], -1.0),
    "focus": ([(-13, -1), (-5, -5), (6, -4), (13, 2)], [(-11, 3), (0, 4.5), (11, 3)], 0.0),
    "happy": ([(-13, 1), (-5, -7), (5, -7.5), (13, 0)], [(-12, 1), (0, -1.5), (12, 1)], -2.0),
    "smug": ([(-13, 0), (-4, -2.5), (6, -2.5), (13, 2)], [(-11, 3), (0, 5), (11, 3)], 0.0),
}
# brows: near brow pts (outer -> inner), far brow pts (inner -> outer), head-local
BROWS = {
    "neutral": ([(0, -20), (16, -23), (33, -19)], [(46, -19), (55, -21), (62, -18)]),
    "focus": ([(0, -22), (17, -19), (34, -11)], [(45, -12), (54, -17), (63, -20)]),
    "happy": ([(0, -24), (15, -30), (33, -24)], [(46, -24), (55, -28), (63, -24)]),
    "smug": ([(0, -18), (16, -20), (33, -17)], [(45, -24), (54, -31), (63, -27)]),
}


def draw_eye(cv, T, cx, cy, sx, expr, far, look=3.0, skin=None, iris_col=(60, 36, 30)):
    up, lo, _ = EYES[expr]
    sgn = -1 if far else 1

    def F(pts):
        return T([(cx + sgn * x * sx, cy + y) for x, y in pts])

    upper, lower = F(up), F(lo)
    white = cv.poly(upper + lower[::-1])
    cv.paint(white, EYE_WHITE["base"])
    # lid shadow on the eyeball
    sh = cv.samp(white, 0, -2.2) & white
    cv.rgb[white & ~sh] = EYE_WHITE["sh"]
    # iris looking toward screen right
    ix, iy = cx + look + (2 if not far else 1), cy - 0.5
    r = 5.6 * (0.8 if far else 1.0)
    (ex, ey), = T([(ix, iy)])
    sc = T.scale()
    iris = cv.ellipse(ex, ey, r * sc * (0.72 if far else 0.92), r * sc) & white
    cv.rgb[iris] = iris_col
    pup = cv.ellipse(ex + 0.5, ey, r * sc * 0.45, r * sc * 0.55) & white
    cv.rgb[pup] = (14, 8, 14)
    glint = cv.ellipse(ex - r * sc * 0.35, ey - r * sc * 0.4, 1.5 * sc, 1.5 * sc) & white
    cv.rgb[glint] = (255, 255, 255)
    cv.a |= white
    # lash line: heavy, tapering toward the inner corner, a flick at the outer corner
    lw = 3.4 if not far else 2.8
    cv.ink(cv.line(upper, lw, taper=(0.12, 0.45)))
    flick = F([(-12, 0), (-16, -1.5), (-18.5, -3)])
    cv.ink(cv.line(flick, 2.2, taper=(0.0, 1.0)))
    cv.ink(cv.line(lower[: 2] + [lower[2]], 1.2, taper=(0.4, 0.5)))
    if expr in ("neutral", "happy"):
        crease = F([(-9, -8), (0, -10.5), (9, -8)])
        cv.ink(cv.line(crease, 1.0, taper=(0.5, 0.5)))
    if expr == "happy":
        bag = F([(-8, 7.5), (1, 9), (9, 7)])
        cv.ink(cv.line(bag, 1.0, taper=(0.5, 0.5)))


def draw_brows(cv, T, expr, col, thick=1.0):
    near, far = BROWS[expr]
    for pts, w, tp in ((near, 6.0, (0.15, 0.35)), (far, 4.6, (0.3, 0.3))):
        m = cv.line(T(pts), w * thick * T.scale(), taper=tp)
        cv.paint(m, col)
        cv.ink(cv.band(m, 0.9, 0.7, 1.4, dirs=20))
    if expr == "focus":
        cv.ink(cv.line(T([(39, -15), (40.5, -9), (40, -5)]), 1.4, taper=(0.4, 0.5)))
        cv.ink(cv.line(T([(43, -14), (43.5, -9)]), 1.1, taper=(0.4, 0.5)))


def draw_nose(cv, T, tones, expr, wide=0.0):
    # nostril wing and the near side of the nose; the tip is part of the face silhouette
    w = wide
    cv.ink(cv.line(T([(53 - w * 3, 20 - w), (51 - w * 4, 26), (55 - w * 3, 31 + w), (62, 31.5 + w)]), 2.0,
                   taper=(0.3, 0.2)))
    cv.ink(cv.line(T([(57 - w, 27 + w * 0.5), (60, 28.5 + w * 0.5)]), 1.6, taper=(0.3, 0.3)))
    cv.ink(cv.line(T([(48, 2), (51, 9), (54, 15)]), 1.1, taper=(0.5, 0.6)))
    if expr == "focus":
        cv.ink(cv.line(T([(45, -3), (50, -1)]), 1.0, taper=(0.5, 0.5)))


def draw_lips(cv, T, skin, expr):
    """Fuller lips: a shaded upper lip and a lit lower lip under the mouth line (not on the open grin)."""
    if expr == "happy":
        cv.ink(cv.line(T([(38, 60), (47, 62), (56, 60)]), 1.3, taper=(0.5, 0.5)))
        return
    y = {"smug": -0.5}.get(expr, 0.0)
    up = cv.poly(T([(37, 46 + y), (44, 42.5), (52, 43), (58, 42), (65, 45 + y), (52, 46.5), (44, 46.5)]))
    cv.rgb[up & ~cv.k] = skin["sh"]
    lo = cv.poly(T([(39, 49), (48, 49.5), (60, 48.5), (57, 54), (49, 56), (42, 54)]))
    cv.rgb[lo & ~cv.k] = skin["base"]
    cv.rgb[cv.ellipse(*T([(50, 51.5)])[0], 3.5 * T.scale(), 1.2 * T.scale()) & ~cv.k] = skin["lt"]
    cv.ink(cv.line(T([(42, 55), (49, 57), (57, 55)]), 1.2, taper=(0.5, 0.5)))


def draw_mouth(cv, T, tones, expr, beard=False):
    sc = T.scale()
    if expr == "happy":
        top = [(32, 41), (46, 44.5), (60, 43), (67, 40)]
        bot = [(66, 42), (58, 54), (46, 58), (34, 46)]
        M = cv.poly(T(top + bot))
        cv.paint(M, MOUTH)
        teeth = M & ~cv.samp(cv.poly(T(top + [(66, 47), (46, 50.5), (33, 45)])), 0, 0, fill=False)
        tm = cv.poly(T(top + [(66, 46), (46, 50), (33, 44.5)])) & M
        cv.rgb[tm] = (250, 248, 244)
        cv.rgb[cv.samp(tm, 0, -1.6) & tm & ~cv.samp(tm, 0, -1.6 + 1.6)] = (200, 196, 206)
        tg = cv.ellipse(*T([(49, 56)])[0], 8 * sc, 3.5 * sc) & M
        cv.rgb[tg] = TONGUE
        cv.ink(cv.band(M, 1.5, 0.6, 1.5, dirs=24))
        cv.ink(cv.line(T([(31, 35), (30, 41), (33, 47)]), 1.8, taper=(0.6, 0.2)))   # smile crease
        if not beard:
            cv.ink(cv.line(T([(50, 23), (40, 30), (31, 38)]), 1.5, taper=(0.4, 0.6)))
            cv.ink(cv.line(T([(42, 63), (50, 64), (58, 61)]), 1.2, taper=(0.5, 0.5)))
        return
    if expr == "focus":
        pts = [(36, 49), (44, 47), (55, 47), (65, 46.5)]
        cv.ink(cv.line(T(pts), 2.6, taper=(0.35, 0.15)))
        cv.ink(cv.line(T([(34, 46), (35, 50.5)]), 1.4, taper=(0.5, 0.5)))
        if not beard:
            cv.ink(cv.line(T([(45, 55), (52, 55.5), (58, 54.5)]), 1.2, taper=(0.5, 0.5)))
    elif expr == "neutral":
        cv.ink(cv.line(T([(37, 47), (50, 47.5), (65, 46.5)]), 2.4, taper=(0.35, 0.15)))
        if not beard:
            cv.ink(cv.line(T([(46, 55), (52, 55.5), (58, 54.5)]), 1.2, taper=(0.5, 0.5)))
    elif expr == "smug":
        cv.ink(cv.line(T([(36, 46), (46, 47.5), (57, 46), (66, 41)]), 2.4, taper=(0.3, 0.1)))
        cv.ink(cv.line(T([(64, 37), (67, 41), (66, 45)]), 1.4, taper=(0.4, 0.4)))
        cv.ink(cv.line(T([(35, 44), (34.5, 48)]), 1.2, taper=(0.5, 0.5)))


def face(cv, T, Tn, skin, expr, jaw=0.0, chin=0.0, crown=0.0, beard=False, hair_col=None, brow_col=None, brow_w=1.0,
         neck=True, **kw):
    """Neck, head, ear and features; returns the head mask. kw: nose, wide, lips, iris (see draw_head)."""
    if neck:
        draw_neck(cv, T, Tn, skin, jaw)
    return draw_head(cv, T, skin, expr, jaw, chin, crown, beard, brow_col, brow_w, **kw)


def neck_shape(Tn, jaw):
    """The neck as part of the body: its sides flare smoothly into the trapezius (head-local, no head tilt)."""
    j = jaw
    return Tn([(-44, 10), (-37 - j * 0.5, 54), (-39 - j * 0.6, 70), (-46 - j, 84), (-62 - j, 93), (-84 - j, 99),
               (-92 - j, 170), (100 + j, 170), (92 + j, 101), (76 + j, 95), (62 + j, 86), (56 + j * 0.6, 72),
               (51 + j * 0.5, 58), (46, 40), (10, 40)])


def neck_column(Tn, jaw):
    """Just the neck column (for things that sit behind the neck, like a hood)."""
    return Tn([(-44, 10), (-37 - jaw * 0.5, 54), (-40 - jaw * 0.6, 80), (-42 - jaw, 130), (60 + jaw, 130),
               (56 + jaw * 0.6, 80), (51 + jaw * 0.5, 58), (46, 40), (10, 40)])


def neck_shading(cv, T, Tn, M, skin, jaw):
    """Cast shadow of the jaw on the neck (hatched), in the same skin tones as the face, and the neck muscle."""
    d = max(0.0, jaw) * 2.0          # bearded jaws (jaw > 0) cast a deeper shadow
    cast = cv.poly(T([(-46, 20), (-30, 46), (-10, 62), (12, 74), (34, 82), (58, 84), (62, 96 + d), (40, 102 + d),
                      (14, 98 + d), (-12, 88 + d), (-32, 74 + d * 0.6), (-44, 56)])) & M

    cv.rgb[cast] = skin["sh"]
    f = cv.soft(cast, 2.5) * cast
    cv.rgb[cv.hatch(np.clip((f - 0.3) * 1.6, 0, 1), spacing=2.8, ang=-30.0, wmax=0.6) & cast] = skin["dp"]
    cv.ink(cv.line(Tn([(40, 88), (30, 106), (18, 124)]), 1.3, taper=(0.5, 0.7)))      # neck muscle


def draw_neck(cv, T, Tn, skin, jaw):
    """A neck on its own (under a tee that covers the shoulders)."""
    neck = cv.poly(neck_column(Tn, jaw))     # the tee's collar is its lower edge
    cv.cel(neck, skin, shadow=cv.crescent(neck, 16), hi=cv.sheen(neck, 4, 5), dots=False, ink=2.4)
    neck_shading(cv, T, Tn, neck, skin, jaw)
    return neck


def draw_head(cv, T, skin, expr, jaw, chin, crown, beard, brow_col, brow_w=1.0, nose=0.0, wide=0.0, lips=False,
              iris=(60, 36, 30), mouth=True):
    """nose: longer nose tip (px), wide: broader nostril wing (0..1.5), lips: fuller lips, iris: eye color,
    mouth=False leaves the mouth to the caller (goatees)."""
    sc = T.scale()
    hp = T(head_outline(jaw, chin, crown, nose))
    head = cv.poly(hp)
    sh = cv.crescent(head, 11)
    sh |= cv.poly(T([(-60, 6), (-46, 10), (-36, 30), (-30, 40), (-44, 26)]))                # under the skull
    flat = cv.poly(T([(38, -14), (45, -11), (46, -2), (42, -6)]))                           # far eye socket
    flat |= cv.poly(T([(60, 31), (71, 31), (70, 36), (60, 34)]))                            # under the nose
    flat |= cv.poly(T([(44, 53), (60, 52), (64, 58), (50, 60)]))                            # under the lip
    flat |= cv.poly(T([(-4, 18), (8, 22), (20, 30), (30, 42, 0), (18, 34), (4, 26)]))       # under the cheekbone
    hi = cv.sheen(head, 3.5, 4.5)
    hi |= cv.poly(T([(48, -4), (54, 4), (60, 16), (64, 22), (58, 20), (51, 8)]))           # nose bridge
    hi |= cv.poly(T([(-2, 13), (10, 9), (24, 12), (12, 12.5)]))                            # cheekbone
    hi |= cv.ellipse(*T([(58, 66)])[0], 3.2 * sc, 2.2 * sc)                                 # chin
    cv.cel(head, skin, shadow=sh, flat=flat, hi=hi, ink=2.2)

    # ear
    ear = cv.poly(T(EAR))
    ein = cv.poly(T([(-17, -5), (-27, -6), (-30, 6), (-25, 17), (-19, 18), (-22, 7)]))
    cv.cel(ear, skin, shadow=ein | cv.crescent(ear, 4), hi=cv.sheen(ear, 1.5, 2.5), ink=1.6, dots=False)
    cv.ink(cv.line(T(EAR_IN), 1.6, taper=(0.2, 0.4)))
    cv.ink(cv.line(T([(-22, 3), (-25, 8), (-21, 13)]), 1.2, taper=(0.4, 0.4)))
    # features
    draw_eye(cv, T, 16, -4, 1.1, expr, far=False, iris_col=iris)
    draw_eye(cv, T, 55, -4, 0.56, expr, far=True, iris_col=iris)
    draw_brows(cv, T, expr, brow_col or (30, 20, 24), thick=brow_w)
    draw_nose(cv, T, skin, expr, wide)
    if not beard and mouth:
        draw_mouth(cv, T, skin, expr)
        if lips:
            draw_lips(cv, T, skin, expr)
    # cheek and jaw accents
    if not beard:
        cv.ink(cv.line(T([(26, 40), (30, 44)]), 1.0, taper=(0.5, 0.5)))
    return head


# ----------------------------------------------------------------------------- bodies (canvas px)

def body_shape(broad):
    b = broad

    def X(x):
        return 148 + (x - 148) * b

    return [(X(-14), 350), (X(-10), 300), (X(4), 270), (X(28), 250), (X(62), 236), (X(104), 226), (X(150), 220),
            (X(198), 224), (X(238), 238), (X(264), 258), (X(282), 296), (X(292), 350)], X


def skin_body(cv, skin, broad, T, Tn, jaw):
    """Shoulders, arms and neck as one skin shape: one contour, one set of tones, no seam at the neck."""
    pts, X = body_shape(broad)
    M = cv.poly(pts) | cv.poly(neck_shape(Tn, jaw))
    # morphological closing (soft dilate, then soft erode): the neck-to-shoulder corner becomes one smooth curve
    M = cv.soft(cv.soft(M, 5.0) > 0.12, 5.0) > 0.88
    sh = cv.crescent(M, 22)
    sh |= cv.poly([(X(20), 300), (X(60), 270), (X(66), 350), (X(10), 350)])      # near arm, under the deltoid
    hi = cv.sheen(M, 4, 5)
    cv.cel(M, skin, shadow=sh, hi=hi, ink=2.4)
    neck_shading(cv, T, Tn, M, skin, jaw)
    cv.ink(cv.line([(X(56), 258), (X(62), 290), (X(64), 340)], 2.0, taper=(0.3, 0.1)))   # near deltoid
    cv.ink(cv.line([(X(236), 254), (X(240), 290), (X(244), 340)], 2.0, taper=(0.3, 0.1)))
    cv.ink(cv.line([(X(100), 252), (X(122), 258), (X(138), 258)], 1.4, taper=(0.4, 0.5)))  # collarbones
    cv.ink(cv.line([(X(170), 258), (X(188), 254), (X(204), 248)], 1.3, taper=(0.5, 0.4)))
    return M, X


def tank_top(cv, X, top, trim, scoop=292, strap=22):
    s = strap
    near_arm = [(X(46), 350), (X(64), 300), (X(76), 262), (X(84), 238)]
    far_arm = [(X(214), 236), (X(220), 266), (X(228), 300), (X(236), 350)]
    neck = [(X(84 + s), 230), (X(118), 268), (X(150), scoop), (X(182), 268), (X(214 - s), 230)]
    pts = near_arm + neck + far_arm
    M = cv.poly([(x, y) for x, y in pts], closed=True)
    sh = cv.crescent(M, 16) | cv.poly([(X(100), 230), (X(150), 250), (X(196), 230), (X(200), 250), (X(150), 270),
                                       (X(100), 250)])
    hi = cv.sheen(M, 3, 4)
    cv.cel(M, top, shadow=sh, hi=hi, ink=0)
    t = cv.line(neck, 10, taper=(0, 0)) | cv.line(near_arm, 10, taper=(0, 0)) | cv.line(far_arm, 10, taper=(0, 0))
    t &= M
    cv.rgb[t] = trim["base"]
    cv.rgb[t & cv.crescent(t, 2.5)] = trim["sh"]
    cv.rgb[t & cv.sheen(t, 0.5, 1.2)] = trim["hi"]
    inner = (cv.line(neck, 10, taper=(0, 0)) & M) ^ (cv.line(neck, 4.5, taper=(0, 0)) & M)
    cv.ink(cv.band(M, 2.0))
    # trim inner edge line and a couple of folds
    cv.ink(cv.line([(X(70), 300), (X(80), 262), (X(90), 240)], 1.0, taper=(0.3, 0.3)) & M)
    cv.ink(cv.line([(X(120), 314), (X(132), 330), (X(136), 350)], 1.5, taper=(0.5, 0.3)) & M)
    cv.ink(cv.line([(X(188), 300), (X(196), 330)], 1.5, taper=(0.5, 0.5)) & M)
    return M


def chest_lines(cv, X):
    cv.ink(cv.line([(X(146), 272), (X(150), 284)], 1.2, taper=(0.5, 0.5)))


# ----------------------------------------------------------------------------- characters

def deuce(cv, pal, skins, expr):
    skin = C.ramp(skins["deep"])
    top, trim, navy, white = C.ramp(pal["BLUE"]), C.ramp(pal["GOLD"]), C.ramp(pal["NAVY"]), C.ramp(pal["WHITE"])
    hair = C.ramp(pal["HAIR_BLACK"])
    ang = {"focus": 3.0, "happy": -4.0}[expr]
    T = C.Xf(150, 132, 0.95, 1.04, ang, pivot=(0, 40), front=FRONT)
    Tn = C.Xf(150, 132, 0.95, 1.04, 0)
    _, X = skin_body(cv, skin, 0.96, T, Tn, -2)
    # navy arm sleeve on the near arm
    sl = cv.poly([(X(-20), 352), (X(-12), 302), (X(36), 296), (X(66), 308), (X(68), 352)])
    cv.cel(sl, navy, shadow=cv.crescent(sl, 10), hi=cv.sheen(sl, 3, 4), ink=2.0)
    cv.ink(cv.line([(X(-6), 310), (X(30), 306), (X(62), 316)], 1.0, taper=(0.3, 0.3)) & sl)
    tank_top(cv, X, top, trim)
    face(cv, T, Tn, skin, expr, jaw=-2, chin=1, crown=4, brow_col=(20, 12, 14), neck=False)
    # short hair, then the headband over it
    hp = T([(-54, -36), (-58, -56), (-36, -80), (-4, -92), (30, -86), (52, -70), (62, -50), (63, -40), (20, -46),
            (-20, -40)])
    hm = cv.poly(hp)
    hsh = cv.crescent(hm, 6)
    hhi = cv.poly(T([(-40, -66), (-20, -82), (8, -86), (-6, -78), (-26, -70)]))
    cv.cel(hm, hair, shadow=hsh, hi=None, ink=2.0, dots=False)
    tex = cv.dots(np.full(hm.shape, 0.35, np.float32), 2.6, 0.6, 20) & hm & hhi
    cv.rgb[tex] = hair["lt"]
    cv.rgb[cv.dots(np.full(hm.shape, 0.25, np.float32), 2.6, 0.6, 20) & hm & ~hsh & ~hhi] = hair["lt"]
    band_pts = T([(-60, -40), (-38, -48), (0, -56), (36, -54), (60, -46), (66, -42), (67, -28), (40, -34),
                  (0, -38), (-36, -32), (-61, -24)])
    bm = cv.poly(band_pts)
    cv.cel(bm, white, shadow=cv.crescent(bm, 4) | cv.poly(T([(-62, -40), (-40, -46), (-40, -30), (-62, -24)])),
           hi=cv.sheen(bm, 2, 2.5), ink=2.0, dots=True, dot_sp=2.8)
    cv.ink(cv.line(T([(-30, -42), (10, -47), (50, -44)]), 0.9, taper=(0.4, 0.4)) & bm)


def jojo(cv, pal, skins, expr):
    skin = C.ramp(skins["tan"])
    tee, gold, navy = C.ramp(pal["BLUE"]), C.ramp(pal["GOLD"]), C.ramp(pal["NAVY"])
    hair = C.ramp(pal["HAIR_BLACK"])
    ang = {"focus": 4.0, "happy": -5.0}[expr]
    T = C.Xf(152, 134, 0.93, 0.98, ang, pivot=(0, 40), front=FRONT)
    Tn = C.Xf(152, 134, 0.93, 0.98, 0)

    def X(x):
        return 148 + (x - 148) * 0.9

    face_neck_first = True
    # neck first, then the tee over the neck base
    # (face() draws the neck too; draw the body after a neck-only pass by drawing the tee and then the head)
    pts, X = body_shape(0.9)
    tm = cv.poly(pts) & ~cv.poly([(X(90), 200), (X(98), 232, 0), (X(122), 252), (X(150), 260), (X(180), 252),
                                  (X(202), 230, 0), (X(210), 200)])

    # tee: draw with a crew collar later
    draw_neck(cv, T, Tn, skin, -3)
    cv.cel(tm, tee, shadow=cv.crescent(tm, 22) | cv.poly([(X(90), 240), (X(150), 262), (X(206), 238),
                                                          (X(210), 262), (X(150), 280), (X(90), 262)]),
           hi=cv.sheen(tm, 4, 5), ink=2.4)
    collar_o = [(X(98), 232), (X(122), 252), (X(150), 260), (X(180), 252), (X(202), 230)]
    collar_m = cv.line(collar_o, 9, taper=(0, 0))
    cv.cel(collar_m, gold, shadow=cv.crescent(collar_m, 3), hi=cv.sheen(collar_m, 0.5, 1.5),
           ink=1.6, dots=False)
    cv.ink(cv.line([(X(-8), 320), (X(26), 318), (X(54), 330)], 1.8, taper=(0.2, 0.2)))   # sleeve hems
    cv.ink(cv.line([(X(250), 296), (X(268), 300), (X(286), 314)], 1.8, taper=(0.2, 0.2)))
    cv.ink(cv.line([(X(60), 266), (X(62), 300), (X(60), 330)], 1.4, taper=(0.4, 0.4)))  # folds
    cv.ink(cv.line([(X(232), 262), (X(236), 290)], 1.4, taper=(0.4, 0.4)))
    cv.ink(cv.line([(X(120), 300), (X(140), 320), (X(146), 345)], 1.3, taper=(0.5, 0.3)))
    # cap brim behind (backwards cap: the brim points back, to the left)
    brim = cv.poly(T([(-44, -42), (-64, -50), (-98, -44), (-110, -34), (-104, -26), (-70, -28), (-46, -26)]))
    cv.cel(brim, navy, shadow=cv.poly(T([(-110, -34), (-104, -26), (-70, -28), (-46, -26), (-50, -34),
                                         (-80, -36)])), hi=cv.sheen(brim, 1.5, 2.5), ink=2.0, dots=False)
    # head without the neck pass (already drawn)
    face_no_neck(cv, T, skin, expr, jaw=-3, chin=-1, crown=2, brow_col=(22, 14, 16))
    # hair peeking out under the cap: sideburn and nape
    sb = cv.poly(T([(-9, -34), (-4, -30), (-6, -14), (-10, -18), (-14, -32)]))
    cv.cel(sb, hair, shadow=cv.crescent(sb, 3), ink=1.4, dots=False)
    nape = cv.poly(T([(-52, -36), (-44, -36), (-50, -18), (-58, -8), (-62, -26)]))
    cv.cel(nape, hair, shadow=cv.crescent(nape, 4), ink=1.6, dots=False)
    # cap dome
    dome_pts = T([(-60, -30), (-60, -58), (-38, -84), (-4, -96), (32, -90), (56, -72), (66, -50), (68, -32),
                  (40, -38), (0, -40), (-36, -34)])
    dm = cv.poly(dome_pts)
    dsh = cv.crescent(dm, 9) | cv.poly(T([(-62, -40), (-30, -42), (0, -44), (40, -42), (68, -36), (68, -30),
                                         (40, -36), (0, -38), (-36, -32), (-62, -26)]))
    dhi = cv.poly(T([(-46, -62), (-30, -80), (-6, -90), (-14, -80), (-34, -66)]))
    cv.cel(dm, gold, shadow=dsh, hi=dhi | cv.sheen(dm, 3, 3), ink=2.4)
    # the strap opening (the back of the cap faces front)
    op = cv.poly(T([(30, -38), (34, -52), (44, -58), (54, -52), (58, -40)]))
    cv.cel(op & dm, hair, shadow=cv.crescent(op, 3), ink=1.6, dots=False)
    strap = cv.poly(T([(28, -40), (60, -41), (60, -36), (28, -35)])) & dm
    cv.cel(strap, navy, ink=1.2, dots=False)
    cv.ink(cv.line(T([(-8, -95), (10, -82), (34, -64), (44, -58)]), 1.4, taper=(0.2, 0.3)) & dm)   # seams
    cv.ink(cv.line(T([(-8, -95), (-26, -74), (-40, -50), (-44, -36)]), 1.4, taper=(0.2, 0.3)) & dm)
    btn = cv.ellipse(*T([(-7, -96)])[0], 4.5, 3)
    cv.cel(btn, gold, ink=1.4, dots=False)


def face_no_neck(cv, T, skin, expr, **kw):
    """face() without its neck (for tops that cover the neck base)."""
    return face(cv, T, T, skin, expr, neck=False, **kw)


def tank(cv, pal, skins, expr):
    skin = C.ramp(skins["light"])
    navy, gold = C.ramp(pal["NAVY"]), C.ramp(pal["GOLD"])
    hair = C.ramp(pal["HAIR_AUBURN"])
    ang = {"focus": 3.0, "happy": -4.0}[expr]
    T = C.Xf(148, 130, 1.06, 1.0, ang, pivot=(0, 40), front=FRONT)
    Tn = C.Xf(148, 130, 1.12, 1.0, 0)
    _, X = skin_body(cv, skin, 1.08, T, Tn, 4)
    # sleeveless hoodie: wide straps, the hood bunched behind the neck, gold drawstrings
    hood = cv.poly([(X(70), 250), (X(74), 214), (X(100), 192), (X(150), 184), (X(196), 192), (X(222), 214),
                    (X(228), 250), (X(150), 262)]) & ~cv.poly(neck_column(Tn, 4))
    cv.cel(hood, navy, shadow=cv.crescent(hood, 12) | cv.poly([(X(106), 206), (X(150), 198), (X(194), 206),
                                                              (X(194), 250), (X(106), 250)]),
           hi=cv.sheen(hood, 3, 4), ink=2.2)
    cv.ink(cv.line([(X(82), 236), (X(88), 214), (X(108), 198)], 1.4, taper=(0.3, 0.3)))     # hood folds
    cv.ink(cv.line([(X(212), 236), (X(206), 214)], 1.4, taper=(0.3, 0.3)))
    tank_top(cv, X, navy, gold, scoop=286, strap=14)
    face(cv, T, Tn, skin, expr, jaw=4, chin=2, crown=0, beard=True, brow_col=hair["dp"], brow_w=1.2, neck=False)
    for xs, xe in ((132, 126), (166, 172)):
        cord = cv.line([(X(xs), 266), (X((xs + xe) / 2), 296), (X(xe), 322)], 3.2, taper=(0, 0))
        cv.cel(cord, gold, ink=1.0, dots=False)
        tip = cv.line([(X(xe), 322), (X(xe), 334)], 5, taper=(0, 0))
        cv.cel(tip, C.ramp(pal["WHITE"]), ink=1.2, dots=False)
    beard_and_hair(cv, T, hair, skin, expr, grey=False)


def beard_and_hair(cv, T, hair, skin, expr, grey):
    # beard over the jaw and chin, below the cheek line
    bpts = T([(-12, -14), (-4, 6), (4, 22), (20, 32), (36, 38), (52, 36), (66, 38), (72, 46), (74, 58),
              (72, 72), (69, 81), (64, 88, 0), (58, 89), (52, 96, 0), (45, 93), (37, 98, 0), (29, 93), (19, 93, 0),
              (11, 87), (3, 85, 0), (-5, 77), (-14, 66), (-24, 50), (-17, 34), (-12, 20), (-11, 0), (-14, -14, 0)])
    bm = cv.poly(bpts)
    sh = cv.crescent(bm, 10) | cv.poly(T([(-26, 44), (-10, 56), (14, 72), (40, 84), (64, 80), (48, 96),
                                         (0, 90), (-26, 56)]))
    hi = cv.poly(T([(-4, 8), (6, 22), (20, 30), (10, 32), (-2, 22)]))
    cv.cel(bm, hair, shadow=sh, hi=hi, ink=2.2, dots=True, dot_sp=3.0)
    # hair flicks: dark strands all over, light strands on the lit side
    rng = np.random.default_rng(7)
    for _ in range(34):
        x = rng.uniform(-14, 66)
        y = rng.uniform(34, 86) if x > 10 else rng.uniform(4, 64)
        p = [(x, y), (x + 1.5, y + 4), (x + 1, y + 8)]
        m = cv.line(T(p), 1.1, taper=(0.5, 0.5)) & bm
        cv.rgb[m] = hair["dp"]
    for _ in range(16):
        x = rng.uniform(-8, 40)
        y = rng.uniform(16, 50) if x < 16 else rng.uniform(40, 64)
        p = [(x, y), (x + 1.2, y + 3.5), (x + 0.8, y + 7)]
        m = cv.line(T(p), 1.2, taper=(0.5, 0.5)) & bm & ~sh
        cv.rgb[m] = hair["hi"]
    # mouth inside the beard, then the moustache over its top
    draw_mouth(cv, T, skin, expr, beard=True)
    if expr == "happy":
        mp = [(28, 42, 0), (36, 36), (46, 32), (56, 29.5), (64, 29.5), (72, 32), (75, 37), (73, 41, 0), (66, 38.5),
              (58, 38), (48, 40), (38, 42)]
    else:
        mp = [(30, 47, 0), (36, 40), (46, 34), (56, 31), (64, 31), (72, 34), (76, 40), (73, 46, 0), (68, 42),
              (60, 40.5), (50, 42), (40, 46)]
    mo = cv.poly(T(mp))
    cv.cel(mo, hair, shadow=cv.crescent(mo, 3), hi=cv.sheen(mo, 1, 1.5), ink=1.8, dots=False)
    for x0 in (40, 47, 54, 61, 67):
        m = cv.line(T([(x0, 33), (x0 - 1.5, 38), (x0 - 3, 43)]), 1.0, taper=(0.4, 0.4)) & mo
        cv.rgb[m] = hair["dp"]
    if grey:
        return
    buzz_hair(cv, T, hair)


def buzz_hair(cv, T, hair, sparse=False):
    """A buzz cut: a tight cap of hair, stippled (sparse: shaved sides, lighter stipple)."""
    hp = T([(-58, -6), (-64, -30), (-53, -62), (-23, -85), (14, -88), (44, -77), (60, -56), (61, -46), (48, -49),
            (26, -56), (6, -52), (-6, -40), (-9, -16), (-13, -13), (-24, -18), (-36, -16), (-48, -6)])
    hm = cv.poly(hp)
    hsh = cv.crescent(hm, 8)
    # the hairline is not inked: a stippled fade into the skin reads as a buzz cut, not a helmet
    fringe = cv.band(hm, 3.5, 1.0, 1.0, dirs=24) & cv.a & ~cv.k
    if sparse:
        # shaved: the scalp stays skin, a fine stipple of stubble on it
        st = cv.dots(np.full(hm.shape, 0.55, np.float32), 2.2, 0.6, 15) & hm & ~cv.k
        cv.rgb[st] = hair["base"]
        return hm
    cv.cel(hm, hair, shadow=hsh, hi=None, ink=0, dots=False)
    st = cv.dots(np.full(hm.shape, 0.5, np.float32), 2.4, 0.6, 15)
    cv.rgb[st & hm & ~hsh] = hair["sh"]
    cv.rgb[st & hm & hsh] = hair["dp"]
    fade = cv.dots(np.full(hm.shape, 0.45, np.float32), 2.4, 0.75, 15)
    cv.rgb[fringe & fade] = hair["sh"]
    hhi = cv.poly(T([(-44, -58), (-20, -80), (10, -84), (-6, -74), (-30, -60)]))
    cv.rgb[hhi & hm & ~st] = hair["lt"]
    cv.k &= ~hm
    return hm


def mayor(cv, pal, skins, expr):
    skin = C.ramp(skins["tan"])
    green, white, gold = C.ramp(pal["GREEN"]), C.ramp(pal["WHITE"]), C.ramp(pal["GOLD"])
    grey = C.ramp(pal["HAIR_GREY"])
    ang = {"neutral": 0.0, "happy": -4.0, "smug": -7.0}[expr]
    T = C.Xf(148, 128, 1.08, 1.0, ang, pivot=(0, 40), front=FRONT)
    Tn = C.Xf(148, 128, 1.16, 1.0, 0)
    _, X = skin_body(cv, skin, 1.12, T, Tn, 5)
    tank_top(cv, X, green, white, scoop=296, strap=20)
    face(cv, T, Tn, skin, expr, jaw=5, chin=2, crown=-2, beard=True, brow_col=grey["base"], brow_w=1.4, neck=False)

    # a few short grey hairs above and behind the ear
    for k in range(7):
        x, y = -58 + k * 3.6, -16 + abs(k - 3) * 0.8
        m = cv.line(T([(x, y), (x + 1.5, y + 5)]), 1.3, taper=(0.3, 0.3))
        cv.paint(m, grey["sh"])
    # shine on the bald head
    sc = T.scale()
    shine = cv.line(T([(-38, -60), (-24, -74), (-4, -80)]), 6 * sc, taper=(0.4, 0.4))
    cv.rgb[shine] = (255, 250, 236)
    dot = cv.ellipse(*T([(8, -80)])[0], 2.4, 2.0)
    cv.rgb[dot] = (255, 250, 236)
    cv.ink(cv.line(T([(14, -62), (30, -64), (44, -58)]), 1.0, taper=(0.5, 0.5)))    # brow-furrow lines
    cv.ink(cv.line(T([(18, -54), (32, -56), (42, -52)]), 0.9, taper=(0.5, 0.5)))
    beard_and_hair(cv, T, grey, skin, expr, grey=True)
    # chain of office: links round the neck and a medallion
    path = C.spline([(X(110), 238), (X(120), 270), (X(150), 290), (X(180), 270), (X(190), 238)], closed=False)
    seg = np.sqrt(((path[1:] - path[:-1]) ** 2).sum(1))
    s = np.concatenate([[0], np.cumsum(seg)])
    links = cv.empty()
    k = 0
    for v in np.arange(0, s[-1], 7.0):
        i = int(np.searchsorted(s, v))
        x, y = path[min(i, len(path) - 1)]
        links |= cv.ellipse(x, y, 4.2 if k % 2 == 0 else 3.2, 3.2 if k % 2 == 0 else 4.2)
        k += 1
    cv.cel(links, gold, shadow=cv.crescent(links, 2), hi=cv.sheen(links, 0.5, 1.2), ink=1.4, dots=False)
    med = cv.ellipse(X(150), 302, 15, 15)
    cv.cel(med, gold, shadow=cv.crescent(med, 6), hi=cv.sheen(med, 1.5, 2.5), ink=2.0, dots=True, dot_sp=2.6)
    star = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 8.5 if i % 2 == 0 else 3.6
        star.append((X(150) + r * math.cos(a), 302 + r * math.sin(a), 0))
    sm = cv.poly(star)
    cv.paint(sm, gold["sh"])
    cv.ink(cv.band(sm, 0.8, 0.6, 1.4, dirs=20))


# ----------------------------------------------------------------------------- the full cast: shared parts

def rough(pts, amp, lobes, seed=0):
    """Bumpy outline: push each point in or out a little (curly hair)."""
    rng = np.random.default_rng(seed)
    out = []
    for i, p in enumerate(pts):
        if len(p) > 2:
            out.append(p)
            continue
        r = amp * (math.sin(i * 2 * math.pi / max(1, lobes) * 3.0) * 0.6 + rng.uniform(-0.4, 0.4))
        out.append((p[0] + r, p[1] - abs(r) * 0.6))
    return out


def tee_body(cv, skin, tee, trim, broad, T, Tn, jaw, folds=True):
    """A crew-neck tee over the shoulders (the neck is drawn first, the collar is its lower edge). Returns X, mask."""
    pts, X = body_shape(broad)
    tm = cv.poly(pts) & ~cv.poly([(X(90), 200), (X(98), 232, 0), (X(122), 252), (X(150), 260), (X(180), 252),
                                  (X(202), 230, 0), (X(210), 200)])
    draw_neck(cv, T, Tn, skin, jaw)
    cv.cel(tm, tee, shadow=cv.crescent(tm, 22) | cv.poly([(X(90), 240), (X(150), 262), (X(206), 238),
                                                          (X(210), 262), (X(150), 280), (X(90), 262)]),
           hi=cv.sheen(tm, 4, 5), ink=2.4)
    collar_o = [(X(98), 232), (X(122), 252), (X(150), 260), (X(180), 252), (X(202), 230)]
    collar_m = cv.line(collar_o, 9, taper=(0, 0))
    cv.cel(collar_m, trim, shadow=cv.crescent(collar_m, 3), hi=cv.sheen(collar_m, 0.5, 1.5), ink=1.6, dots=False)
    cv.ink(cv.line([(X(-8), 320), (X(26), 318), (X(54), 330)], 1.8, taper=(0.2, 0.2)))   # sleeve hems
    cv.ink(cv.line([(X(250), 296), (X(268), 300), (X(286), 314)], 1.8, taper=(0.2, 0.2)))
    if folds:
        cv.ink(cv.line([(X(60), 266), (X(62), 300), (X(60), 330)], 1.4, taper=(0.4, 0.4)))
        cv.ink(cv.line([(X(232), 262), (X(236), 290)], 1.4, taper=(0.4, 0.4)))
        cv.ink(cv.line([(X(120), 300), (X(140), 320), (X(146), 345)], 1.3, taper=(0.5, 0.3)))
    return X, tm


def hood_back(cv, X, Tn, pal, jaw):
    """The hood of a sleeveless hoodie, bunched behind the neck."""
    hood = cv.poly([(X(70), 250), (X(74), 214), (X(100), 192), (X(150), 184), (X(196), 192), (X(222), 214),
                    (X(228), 250), (X(150), 262)]) & ~cv.poly(neck_column(Tn, jaw))
    cv.cel(hood, pal, shadow=cv.crescent(hood, 12) | cv.poly([(X(106), 206), (X(150), 198), (X(194), 206),
                                                             (X(194), 250), (X(106), 250)]),
           hi=cv.sheen(hood, 3, 4), ink=2.2)
    cv.ink(cv.line([(X(82), 236), (X(88), 214), (X(108), 198)], 1.4, taper=(0.3, 0.3)))
    cv.ink(cv.line([(X(212), 236), (X(206), 214)], 1.4, taper=(0.3, 0.3)))


def drawstrings(cv, X, pal, tip):
    for xs, xe in ((132, 126), (166, 172)):
        cord = cv.line([(X(xs), 266), (X((xs + xe) / 2), 296), (X(xe), 322)], 3.2, taper=(0, 0))
        cv.cel(cord, pal, ink=1.0, dots=False)
        t = cv.line([(X(xe), 322), (X(xe), 334)], 5, taper=(0, 0))
        cv.cel(t, tip, ink=1.2, dots=False)


def arm_sleeve(cv, X, body, pal, near=True):
    """A compression sleeve on the near (sprite's right) or far arm, clipped to the arm."""
    if near:
        sl = cv.poly([(X(-20), 352), (X(-12), 302), (X(36), 296), (X(66), 308), (X(68), 352)])
        hem = [(X(-6), 310), (X(30), 306), (X(62), 316)]
    else:
        sl = cv.poly([(X(232), 352), (X(238), 306), (X(264), 298), (X(292), 306), (X(300), 352)])
        hem = [(X(240), 314), (X(264), 306), (X(290), 312)]
    sl &= body
    cv.cel(sl, pal, shadow=cv.crescent(sl, 10), hi=cv.sheen(sl, 3, 4), ink=2.0)
    cv.ink(cv.line(hem, 1.0, taper=(0.3, 0.3)) & sl)


def chain(cv, X, pal, pendant=None, links=(4.2, 3.2), sp=7.0, drop=290):
    path = C.spline([(X(110), 238), (X(120), drop - 20), (X(150), drop), (X(180), drop - 20), (X(190), 238)],
                    closed=False)
    seg = np.sqrt(((path[1:] - path[:-1]) ** 2).sum(1))
    s = np.concatenate([[0], np.cumsum(seg)])
    m = cv.empty()
    for k, v in enumerate(np.arange(0, s[-1], sp)):
        i = int(np.searchsorted(s, v))
        x, y = path[min(i, len(path) - 1)]
        a, b = (links[0], links[1]) if k % 2 == 0 else (links[1], links[0])
        m |= cv.ellipse(x, y, a, b)
    cv.cel(m, pal, shadow=cv.crescent(m, 2), hi=cv.sheen(m, 0.5, 1.2), ink=1.4, dots=False)
    cx, cy = X(150), drop + 14
    if pendant == "crown":
        pts = [(cx - 16, cy + 10, 0), (cx - 19, cy - 11, 0), (cx - 9, cy - 1, 0), (cx, cy - 16, 0), (cx + 9, cy - 1, 0),
               (cx + 19, cy - 11, 0), (cx + 16, cy + 10, 0)]
        cm = cv.poly(pts)
        cv.cel(cm, pal, shadow=cv.crescent(cm, 5), hi=cv.sheen(cm, 1.5, 2.0), ink=2.0, dots=True, dot_sp=2.6)
        for gx in (-9, 0, 9):
            g = cv.ellipse(cx + gx, cy + 4, 2.4, 2.4)
            cv.paint(g, (60, 200, 255) if gx == 0 else (240, 70, 90))
            cv.ink(cv.band(g, 0.7, 0.6, 1.3, dirs=16))
    elif pendant == "lock":
        shackle = cv.line([(cx - 7, cy - 4), (cx - 7, cy - 12), (cx, cy - 16), (cx + 7, cy - 12), (cx + 7, cy - 4)],
                          3.4, taper=(0, 0))
        cv.cel(shackle, pal, ink=1.2, dots=False)
        body = cv.poly([(cx - 11, cy - 4, 0), (cx + 11, cy - 4, 0), (cx + 11, cy + 12, 0), (cx - 11, cy + 12, 0)])
        cv.cel(body, pal, shadow=cv.crescent(body, 5), hi=cv.sheen(body, 1.5, 2.0), ink=2.0, dots=True, dot_sp=2.6)
        cv.ink(cv.ellipse(cx, cy + 2, 2.0, 2.4) | cv.line([(cx, cy + 3), (cx, cy + 8)], 1.6, taper=(0, 0)))


def headband(cv, T, pal):
    band_pts = T([(-60, -40), (-38, -48), (0, -56), (36, -54), (60, -46), (66, -42), (67, -28), (40, -34),
                  (0, -38), (-36, -32), (-61, -24)])
    bm = cv.poly(band_pts)
    cv.cel(bm, pal, shadow=cv.crescent(bm, 4) | cv.poly(T([(-62, -40), (-40, -46), (-40, -30), (-62, -24)])),
           hi=cv.sheen(bm, 2, 2.5), ink=2.0, dots=True, dot_sp=2.8)
    cv.ink(cv.line(T([(-30, -42), (10, -47), (50, -44)]), 0.9, taper=(0.4, 0.4)) & bm)
    return bm


def shades(cv, T, rim_col=None):
    """Dark wrap-around shades over both eyes, with glare streaks."""
    near = cv.poly(T([(-3, -13, 0), (16, -15), (36, -13, 0), (35, -3), (30, 5), (16, 8), (2, 4), (-3, -4)]))
    far = cv.poly(T([(43, -13, 0), (55, -14), (65, -12, 0), (64, -4), (60, 3), (50, 4), (44, -2)]))
    lens = near | far
    cv.paint(lens, (22, 20, 34))
    top = lens & ~cv.samp(lens, 0, 6)
    cv.rgb[top] = (52, 50, 74)
    for (x0, y0, x1, y1, w) in ((4, 4, 18, -12, 3.2), (14, 6, 26, -10, 1.6), (48, 2, 56, -11, 2.0)):
        g = cv.line(T([(x0, y0), (x1, y1)]), w * T.scale(), taper=(0, 0)) & lens
        cv.rgb[g] = (150, 160, 200)
    cv.ink(cv.band(lens, 2.0, 0.7, 1.4, dirs=24))
    cv.ink(cv.line(T([(35, -10), (39, -12), (44, -10)]), 2.6, taper=(0, 0)))    # bridge
    cv.ink(cv.line(T([(-3, -9), (-12, -8), (-17, -6)]), 3.0, taper=(0, 0.3)))    # temple arm to the ear
    if rim_col is not None:
        cv.rgb[cv.line(T([(-2, -13), (16, -15.5), (35, -13)]), 1.2, taper=(0.2, 0.2))] = rim_col


def goatee(cv, T, hair, expr, moustache=True, chin=0.0):
    c = chin
    top = 61 if expr == "happy" else 56
    gm = cv.poly(T([(40, top), (50, top - 1), (62, top), (67 + c, top + 3), (70 + c, 66), (68 + c, 76), (61 + c, 85),
                    (51, 88), (43, 84), (38, 73)]))
    sh = cv.crescent(gm, 6)
    cv.cel(gm, hair, shadow=sh, hi=cv.sheen(gm, 1.5, 2.0), ink=1.8, dots=False)
    for x0 in (44, 50, 56, 62):
        m = cv.line(T([(x0, top + 6), (x0 + 1, top + 14), (x0 - 1, top + 22)]), 1.0, taper=(0.5, 0.5)) & gm
        cv.rgb[m] = hair["dp"]
    if not moustache:
        return gm
    dy = {"happy": -3.5}.get(expr, 0.0)
    lift = 3.0 if expr == "smug" else 0.0
    mo = cv.poly(T([(36, 46 + dy, 0), (43, 41 + dy), (53, 38.5 + dy), (62, 38.5 + dy - lift * 0.5),
                    (69, 41 + dy - lift), (69, 44 + dy - lift, 0), (61, 42.5 + dy - lift * 0.5), (50, 43 + dy),
                    (42, 45 + dy)]))
    cv.cel(mo, hair, shadow=cv.crescent(mo, 2), hi=cv.sheen(mo, 0.6, 1.0), ink=1.4, dots=False)
    return gm


def stubble(cv, T, skin, head, expr):
    zone = cv.poly(T([(-12, 22), (2, 40), (22, 52), (36, 44), (66, 40), (70, 60), (66, 74), (52, 82), (28, 78),
                      (6, 66), (-18, 50)])) & head & ~cv.k
    if expr == "happy":   # not on the open grin
        zone &= ~cv.poly(T([(30, 39), (68, 37), (69, 46), (58, 57), (46, 60), (32, 49)]))
    st = cv.dots(np.full(zone.shape, 0.4, np.float32), 2.0, 0.6, 25) & zone
    cv.rgb[st] = skin["sh"]


def freckles(cv, T, skin, seed=3):
    rng = np.random.default_rng(seed)
    sc = T.scale()
    for cx, cy, n, sx in ((18, 14, 11, 12), (55, 15, 6, 6), (47, 8, 4, 3)):
        for _ in range(n):
            x, y = cx + rng.uniform(-sx, sx), cy + rng.uniform(-4, 5)
            m = cv.ellipse(*T([(x, y)])[0], 1.15 * sc, 1.0 * sc) & ~cv.k
            cv.rgb[m] = skin["sh"]


def ear_stud(cv, T, pal):
    m = cv.ellipse(*T([(-22, 23)])[0], 2.6, 2.6)
    cv.cel(m, pal, hi=cv.sheen(m, 0.4, 1.0), ink=1.0, dots=False)


def bald_shine(cv, T):
    sc = T.scale()
    cv.rgb[cv.line(T([(-38, -60), (-24, -74), (-4, -80)]), 6 * sc, taper=(0.4, 0.4))] = (255, 250, 236)
    cv.rgb[cv.ellipse(*T([(8, -80)])[0], 2.4, 2.0)] = (255, 250, 236)


# hair styles -------------------------------------------------------------------

def flattop(cv, T, hair, top=-112, flare=0.0, fade=True, seed=1):
    """A flat-top / high-top: buzzed sides and a tall block with a flat, lit top plane."""
    buzz_hair(cv, T, hair, sparse=fade)
    f = flare
    pts = [(-58, -40), (-62, -72), (-56 - f, top + 10), (-50 - f, top + 1), (10, top - 3), (50 + f, top + 1),
           (57 + f, top + 10), (60, -70), (58, -54, 0), (46, -56), (26, -62), (0, -64), (-30, -56)]
    bm = cv.poly(T(pts))
    sh = cv.crescent(bm, 10) | cv.poly(T([(-56, -90), (-40, -88), (-34, -50), (-56, -46)]))
    plane = cv.poly(T([(-52 - f, top + 1), (10, top - 3), (52 + f, top + 1), (40 + f, top + 9), (8, top + 6),
                       (-44 - f, top + 9)]))
    cv.cel(bm, hair, shadow=sh, hi=None, ink=2.2, dots=True, dot_sp=3.0)
    cv.rgb[plane & bm & ~cv.k] = hair["lt"]
    cv.rgb[cv.sheen(plane & bm, 0.5, 1.5) & ~cv.k] = hair["hi"]
    rng = np.random.default_rng(seed)
    for _ in range(60):
        x = rng.uniform(-46, 54)
        y = rng.uniform(top + 14, -60)
        m = cv.line(T([(x, y), (x + 0.4, y - 7)]), 1.0, taper=(0.5, 0.5)) & bm & ~plane
        cv.rgb[m & ~cv.k] = hair["dp"] if rng.random() < 0.6 else hair["lt"]
    cv.ink(cv.line(T([(-40 - f, top + 9), (8, top + 6), (40 + f, top + 9)]), 1.2, taper=(0.3, 0.3)) & bm)
    return bm


def afro(cv, T, hair, seed=4):
    cx, cy, rx, ry = -4.0, -50.0, 72.0, 63.0
    arc = []
    for k, a in enumerate(np.linspace(math.radians(-12), math.radians(204), 30)):
        bump = 1.0 + 0.045 * math.cos(k * 2.1)
        arc.append((cx + rx * bump * math.cos(a), cy - ry * bump * math.sin(a)))
    line = [(-72, -26), (-62, -2), (-48, -6), (-32, -16), (-16, -14), (-8, -22), (-4, -40), (6, -52), (26, -58),
            (46, -54), (62, -44)]
    hm = cv.poly(T(arc + line))
    sh = cv.crescent(hm, 16) | cv.poly(T([(-80, -40), (-50, -36), (-30, -20), (-60, 0)]))
    hi = cv.poly(T([(-50, -84), (-30, -104), (0, -110), (-12, -98), (-36, -84)]))
    cv.cel(hm, hair, shadow=sh, hi=None, ink=2.4, dots=True, dot_sp=3.2)
    rng = np.random.default_rng(seed)
    for _ in range(170):
        x, y = rng.uniform(-76, 68), rng.uniform(-114, -4)
        r = rng.uniform(2.0, 3.4)
        a0 = rng.uniform(0, 2 * math.pi)
        pts = [(x + r * math.cos(a0 + t), y + r * math.sin(a0 + t)) for t in np.linspace(0, 3.6, 6)]
        m = cv.line(T(pts), 1.1, taper=(0.4, 0.4)) & hm & ~cv.k
        cv.rgb[m] = hair["dp"] if (m & sh).any() or rng.random() < 0.5 else hair["lt"]
    st = cv.dots(np.full(hm.shape, 0.45, np.float32), 2.6, 0.6, 30) & hi & hm & ~cv.k
    cv.rgb[st] = hair["hi"]
    return hm


def twists(cv, T, hair, seed=5):
    base = cv.poly(T([(-58, -6), (-64, -34), (-54, -66), (-24, -90), (14, -92), (46, -80), (60, -58), (61, -46),
                      (48, -50), (26, -56), (6, -52), (-6, -40), (-9, -16), (-13, -13), (-24, -18), (-36, -16),
                      (-48, -6)]))
    cv.cel(base, hair, shadow=cv.crescent(base, 8), ink=2.0, dots=False)
    rng = np.random.default_rng(seed)
    roots = []
    for a in np.linspace(math.radians(196), math.radians(22), 21):
        roots.append((-2 + 52 * math.cos(a), -36 - 46 * math.sin(a), a))
    for x, y, a in roots:
        L = rng.uniform(11, 15)
        da = rng.uniform(-0.2, 0.2)
        tip = (x + L * math.cos(a + da), y - L * math.sin(a + da) + 2.5)    # the twists hang a little
        mid = ((x + tip[0]) / 2 + rng.uniform(-1.5, 1.5), (y + tip[1]) / 2 - 2.5)
        m = cv.line(T([(x, y), mid, tip]), 10.0 * T.scale(), taper=(0.0, 0.4))
        cv.cel(m, hair, shadow=cv.crescent(m, 2.5), hi=cv.sheen(m, 0.6, 1.2), ink=1.4, dots=False)
        for t in (0.3, 0.55, 0.78):
            px, py = x + (tip[0] - x) * t, y + (tip[1] - y) * t
            nx, ny = -math.sin(a), -math.cos(a)
            tk = cv.line(T([(px - nx * 2.5, py - ny * 2.5 - 1), (px + nx * 2.5, py + ny * 2.5 + 1)]), 0.9,
                         taper=(0.3, 0.3)) & m
            cv.rgb[tk] = hair["dp"]


def mohawk(cv, T, hair):
    buzz_hair(cv, T, hair, sparse=True)
    top = [(44, -74, 0), (48, -94), (34, -100, 0), (28, -112), (8, -110, 0), (-2, -120), (-20, -108, 0), (-36, -114),
           (-46, -94, 0), (-62, -92), (-62, -66, 0), (-58, -48)]
    bot = [(-52, -52), (-40, -72), (-16, -84), (14, -86), (36, -76)]
    m = cv.poly(T(top + bot))
    sh = cv.crescent(m, 9)
    cv.cel(m, hair, shadow=sh, hi=cv.sheen(m, 2, 2.5), ink=2.2, dots=False)
    for x0, y0, x1, y1 in ((36, -78, 40, -92), (20, -84, 22, -104), (0, -86, -2, -112), (-20, -82, -24, -102),
                           (-40, -70, -48, -90), (-52, -56, -58, -72)):
        cv.rgb[cv.line(T([(x0, y0), (x1, y1)]), 1.2, taper=(0.3, 0.5)) & m & ~cv.k] = hair["lt"]


def beanie(cv, T, cap, cuff, hair):
    nape = cv.poly(T([(-52, -36), (-44, -36), (-50, -18), (-58, -8), (-62, -26)]))
    cv.cel(nape, hair, shadow=cv.crescent(nape, 4), ink=1.6, dots=False)
    sb = cv.poly(T([(-9, -34), (-4, -30), (-6, -14), (-10, -18), (-14, -32)]))
    cv.cel(sb, hair, shadow=cv.crescent(sb, 3), ink=1.4, dots=False)
    dome = cv.poly(T([(-63, -32), (-66, -64), (-48, -94), (-14, -110), (24, -106), (52, -88), (66, -62), (68, -36),
                      (40, -42), (0, -44), (-36, -38)]))
    sh = cv.crescent(dome, 10)
    cv.cel(dome, cap, shadow=sh, hi=cv.poly(T([(-48, -76), (-30, -96), (-6, -104), (-20, -92), (-38, -78)])),
           ink=2.4)
    for x0 in range(-50, 64, 9):
        rib = cv.line(T([(x0, -44), (x0 * 0.8 - 6, -76), (x0 * 0.5 - 10, -102)]), 1.0, taper=(0.2, 0.6)) & dome
        cv.rgb[rib & ~cv.k] = cap["sh"]
    cm = cv.poly(T([(-66, -48), (-36, -52), (0, -56), (40, -54), (68, -48), (69, -32), (40, -36), (0, -38),
                    (-36, -32), (-64, -24)]))
    cv.cel(cm, cuff, shadow=cv.crescent(cm, 4), hi=cv.sheen(cm, 1.5, 2), ink=2.0, dots=False)
    for x0 in range(-58, 66, 6):
        r = cv.line(T([(x0, -52 + abs(x0) * 0.02), (x0, -34)]), 0.9, taper=(0.2, 0.2)) & cm
        cv.rgb[r & ~cv.k] = cuff["sh"]
    pts = []
    for k, a in enumerate(np.linspace(0, 2 * math.pi, 22, endpoint=False)):
        r = 14 if k % 2 == 0 else 11.5
        pts.append((-12 + r * math.cos(a), -114 + r * math.sin(a) * 0.9))
    pm = cv.poly(T(pts))
    cv.cel(pm, cuff, shadow=cv.crescent(pm, 6), ink=1.8, dots=True, dot_sp=2.4)


def trucker(cv, T, cap, brim, hair, head):
    # rust hair curling out under the cap at the back and over the ear
    nape = cv.poly(T(rough([(-46, -36), (-56, -30), (-64, -16), (-62, -2), (-54, 6), (-46, -4), (-40, -18),
                            (-26, -24), (-12, -26), (-8, -36)], 2.5, 5)))
    cv.cel(nape, hair, shadow=cv.crescent(nape, 4), hi=cv.sheen(nape, 1, 1.6), ink=1.8, dots=False)
    for x0, y0 in ((-58, -14), (-50, -6), (-36, -22), (-20, -26)):
        cv.ink(cv.line(T([(x0, y0 - 8), (x0 - 1, y0 - 2), (x0 + 2, y0 + 2)]), 1.0, taper=(0.4, 0.4)) & nape)
    dome = cv.poly(T([(-62, -30), (-62, -60), (-40, -88), (-4, -100), (32, -94), (56, -76), (64, -54), (66, -38),
                      (40, -42), (0, -44), (-36, -38)]))
    mesh = cv.poly(T([(-70, -24), (-70, -70), (-46, -100), (-14, -106), (-24, -60), (-20, -36)])) & dome
    sh = cv.crescent(dome, 9)
    cv.cel(dome, cap, shadow=sh, hi=cv.poly(T([(4, -88), (26, -88), (44, -74), (28, -78)])) | cv.sheen(dome, 3, 3),
           ink=2.4)
    cv.rgb[mesh & ~cv.k] = brim["base"]
    cv.rgb[mesh & sh & ~cv.k] = brim["sh"]
    holes = cv.dots(np.full(mesh.shape, 0.55, np.float32), 2.6, 0.6, 45) & mesh & ~cv.k
    cv.rgb[holes] = brim["dp"]
    cv.ink(cv.line(T([(-14, -104), (-22, -70), (-20, -40)]), 1.6, taper=(0.2, 0.2)) & dome)
    patch = cv.ellipse(*T([(30, -66)])[0], 11 * T.scale(), 8 * T.scale())
    cv.cel(patch, brim, hi=cv.sheen(patch, 1, 1.5), ink=1.4, dots=False)
    cv.ink(cv.line(T([(25, -64), (30, -70), (35, -64)]), 1.6, taper=(0.3, 0.3)) & patch)   # a little arrow mark
    btn = cv.ellipse(*T([(-6, -101)])[0], 4.5, 3)
    cv.cel(btn, cap, ink=1.4, dots=False)
    # brim forward over the brow, and its shadow on the face
    shade = cv.poly(T([(18, -42), (68, -40), (72, -26), (40, -28), (20, -30)])) & head & ~cv.k
    cv.rgb[shade] = cv.rgb[shade] * 0.72
    bm = cv.poly(T([(30, -38), (52, -46), (84, -48), (104, -42), (110, -34), (98, -29), (70, -31), (40, -32)]))
    cv.cel(bm, brim, shadow=cv.poly(T([(40, -32), (70, -31), (98, -29), (110, -34), (96, -36), (60, -36)])),
           hi=cv.sheen(bm, 1.2, 2.0), ink=2.2, dots=False)
    cv.ink(cv.line(T([(44, -40), (76, -42), (100, -37)]), 1.0, taper=(0.3, 0.3)) & bm)


def overalls(cv, X, denim, button):
    bib = cv.poly([(X(104), 274), (X(150), 270), (X(196), 274), (X(204), 352), (X(96), 352)])
    cv.cel(bib, denim, shadow=cv.crescent(bib, 12), hi=cv.sheen(bib, 2.5, 3), ink=2.2)
    inner = cv.samp(bib, 3.5, 0, fill=False) & cv.samp(bib, -3.5, 0, fill=False) & cv.samp(bib, 0, -3.5, fill=False)
    st = bib & ~inner & cv.samp(bib, 2.5, 0, fill=False) & cv.samp(bib, -2.5, 0, fill=False) & \
        cv.samp(bib, 0, -2.5, fill=False)
    dash = cv.hatch(np.ones(bib.shape, np.float32), spacing=4.0, ang=60.0, wmax=1.0)
    cv.rgb[st & dash] = denim["hi"]
    pk = cv.poly([(X(128), 292, 0), (X(172), 292, 0), (X(170), 322, 0), (X(130), 322, 0)])
    cv.rgb[pk & bib & cv.crescent(pk, 3)] = denim["sh"]
    cv.ink(cv.band(pk, 1.0, 0.8, 1.2, dirs=16) & bib)
    for xs, xe in ((84, 110), (216, 190)):
        s = cv.line([(X(xs), 228), (X((xs + xe) / 2), 252), (X(xe), 280)], 15, taper=(0, 0))
        cv.cel(s, denim, shadow=cv.crescent(s, 4), hi=cv.sheen(s, 1, 1.5), ink=2.0, dots=False)
        b = cv.ellipse(X(xe), 282, 6, 6)
        cv.cel(b, button, shadow=cv.crescent(b, 2.5), hi=cv.sheen(b, 0.6, 1.2), ink=1.4, dots=False)


ERASER = {"hi": (255, 200, 210), "lt": (250, 170, 180), "base": (230, 130, 150), "sh": (180, 90, 110),
          "dp": (120, 60, 80)}
WOOD = {"hi": (250, 230, 200), "lt": (240, 214, 170), "base": (226, 196, 150), "sh": (180, 150, 110),
        "dp": (120, 100, 70)}


def pencil(cv, T, pal):
    """The mechanic's pencil resting on the ear."""
    body = cv.line(T([(-44, -24), (-6, -17)]), 5.0 * T.scale(), taper=(0, 0))
    cv.cel(body, pal, shadow=cv.crescent(body, 2), hi=cv.sheen(body, 0.4, 1.0), ink=1.3, dots=False)
    er = cv.line(T([(-50, -25), (-44, -24)]), 5.0 * T.scale(), taper=(0, 0))
    cv.cel(er, ERASER, ink=1.3, dots=False)
    tip = cv.poly(T([(-6, -19.5, 0), (2, -16.5, 0), (-6, -14.5, 0)]))
    cv.cel(tip, WOOD, ink=1.1, dots=False)


# characters --------------------------------------------------------------------

def tilt(expr, base=3.0):
    return {"focus": base, "neutral": 0.0, "happy": -4.0, "smug": -7.0}[expr]


def skip(cv, pal, skins, expr):
    skin = C.ramp(skins["light"])
    green, white, hair = C.ramp(pal["GREEN"]), C.ramp(pal["WHITE"]), C.ramp(pal["HAIR_BLOND"])
    T = C.Xf(150, 140, 0.9, 1.04, tilt(expr), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(150, 140, 0.9, 1.04, 0)
    _, X = skin_body(cv, skin, 0.92, T, Tn, -3)
    tank_top(cv, X, green, white, scoop=290, strap=18)
    face(cv, T, Tn, skin, expr, jaw=-3, chin=3, crown=0, brow_col=hair["sh"], neck=False, nose=2.0,
         iris=(60, 112, 176))
    flattop(cv, T, hair, top=-106, fade=False)


def buck(cv, pal, skins, expr):
    skin = C.ramp(skins["brown"])
    white, green, hair = C.ramp(pal["WHITE"]), C.ramp(pal["GREEN"]), C.ramp(pal["HAIR_DARK"])
    T = C.Xf(148, 136, 1.06, 1.0, tilt(expr), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(148, 136, 1.14, 1.0, 0)
    X, tm = tee_body(cv, skin, white, green, 1.12, T, Tn, 4)
    arm_sleeve(cv, X, cv.poly(body_shape(1.12)[0]) & ~tm, green, near=False)
    face(cv, T, Tn, skin, expr, jaw=4, chin=0, crown=0, brow_col=hair["base"], brow_w=1.3, neck=False,
         wide=1.3, lips=True)
    afro(cv, T, hair)


def dale(cv, pal, skins, expr):
    skin = C.ramp(skins["light"])
    green, white, hair = C.ramp(pal["GREEN"]), C.ramp(pal["WHITE"]), C.ramp(pal["HAIR_BROWN"])
    T = C.Xf(150, 132, 0.93, 1.07, tilt(expr, 1.0), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(150, 132, 0.96, 1.07, 0)
    tee_body(cv, skin, green, white, 0.98, T, Tn, 0)
    face(cv, T, Tn, skin, expr, jaw=0, chin=3, crown=2, brow_col=hair["sh"], neck=False, nose=1.0,
         iris=(110, 92, 52))
    goatee(cv, T, hair, expr, chin=3)
    buzz_hair(cv, T, hair)
    pencil(cv, T, C.ramp(pal["GOLD"]))


def rusty(cv, pal, skins, expr):
    skin = C.ramp(skins["light"])
    green, white, denim = C.ramp(pal["GREEN"]), C.ramp(pal["WHITE"]), C.ramp(pal["DENIM"])
    hair, gold = C.ramp(pal["HAIR_RUST"]), C.ramp(pal["GOLD"])
    T = C.Xf(150, 136, 0.98, 0.98, tilt(expr, 2.0), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(150, 136, 1.0, 0.98, 0)
    X, _ = tee_body(cv, skin, green, green, 1.0, T, Tn, 1, folds=False)
    overalls(cv, X, denim, gold)
    head = face(cv, T, Tn, skin, expr, jaw=1, chin=-2, crown=0, brow_col=hair["sh"], neck=False, nose=-2.0,
                iris=(72, 128, 62))
    freckles(cv, T, skin)
    trucker(cv, T, white, green, hair, head)


def nico(cv, pal, skins, expr):
    skin = C.ramp(skins["tan"])
    white, purple, hair = C.ramp(pal["WHITE"]), C.ramp(pal["PURPLE"]), C.ramp(pal["HAIR_INK"])
    T = C.Xf(152, 138, 0.9, 1.03, tilt(expr, 4.0), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(152, 138, 0.9, 1.03, 0)
    tee_body(cv, skin, white, purple, 0.9, T, Tn, -3)
    face(cv, T, Tn, skin, expr, jaw=-3, chin=4, crown=0, brow_col=(26, 18, 24), neck=False, nose=1.0,
         iris=(70, 46, 34))
    beanie(cv, T, purple, white, hair)


def rio(cv, pal, skins, expr):
    skin = C.ramp(skins["umber"])
    purple, white, hair = C.ramp(pal["PURPLE"]), C.ramp(pal["WHITE"]), C.ramp(pal["HAIR_BLACK"])
    T = C.Xf(152, 138, 0.9, 0.99, tilt(expr, 4.0), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(152, 138, 0.92, 0.99, 0)
    body, X = skin_body(cv, skin, 0.9, T, Tn, -2)
    arm_sleeve(cv, X, body, white, near=False)
    tank_top(cv, X, purple, white, scoop=288, strap=16)
    face(cv, T, Tn, skin, expr, jaw=-2, chin=0, crown=1, brow_col=(18, 10, 12), neck=False, wide=0.6)
    mohawk(cv, T, hair)
    ear_stud(cv, T, C.ramp(pal["SILVER"]))


def big_lou(cv, pal, skins, expr):
    skin = C.ramp(skins["deep"])
    plum, white, silver, hair = C.ramp(pal["PLUM"]), C.ramp(pal["WHITE"]), C.ramp(pal["SILVER"]), \
        C.ramp(pal["HAIR_INK"])
    T = C.Xf(148, 130, 1.12, 1.0, tilt(expr, 0.0), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(148, 130, 1.2, 1.0, 0)
    _, X = skin_body(cv, skin, 1.18, T, Tn, 6)
    hood_back(cv, X, Tn, plum, 6)
    tank_top(cv, X, plum, white, scoop=286, strap=14)
    drawstrings(cv, X, white, silver)
    face(cv, T, Tn, skin, expr, jaw=6, chin=2, crown=-2, brow_col=(16, 8, 10), brow_w=1.4, neck=False,
         wide=1.4, lips=True)
    bald_shine(cv, T)
    cv.ink(cv.line(T([(16, -60), (32, -62), (46, -56)]), 1.0, taper=(0.5, 0.5)))
    goatee(cv, T, hair, expr, chin=2)
    shades(cv, T)
    chain(cv, X, silver, pendant="lock", links=(5.4, 4.0), sp=8.5, drop=284)


def marco(cv, pal, skins, expr):
    skin = C.ramp(skins["tan"])
    white, purple, hair = C.ramp(pal["WHITE"]), C.ramp(pal["PURPLE"]), C.ramp(pal["HAIR_BLACK"])
    T = C.Xf(148, 140, 1.02, 0.95, tilt(expr, 2.0), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(148, 140, 1.06, 0.95, 0)
    tee_body(cv, skin, white, purple, 1.02, T, Tn, 2)
    head = face(cv, T, Tn, skin, expr, jaw=2, chin=-1, crown=0, brow_col=(20, 12, 14), brow_w=1.25, neck=False,
                nose=1.5, wide=0.8, iris=(52, 34, 24))
    stubble(cv, T, skin, head, expr)
    twists(cv, T, hair)


def terrell(cv, pal, skins, expr):
    skin = C.ramp(skins["deep"])
    plum, white, purple, hair = C.ramp(pal["PLUM"]), C.ramp(pal["WHITE"]), C.ramp(pal["PURPLE"]), \
        C.ramp(pal["HAIR_BLACK"])
    T = C.Xf(150, 130, 0.9, 1.07, tilt(expr, 5.0), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(150, 130, 0.92, 1.07, 0)
    _, X = skin_body(cv, skin, 0.94, T, Tn, -1)
    tank_top(cv, X, plum, white, scoop=292, strap=20)
    face(cv, T, Tn, skin, expr, jaw=-1, chin=1, crown=2, brow_col=(14, 8, 10), brow_w=1.2, neck=False,
         wide=0.9, lips=True)
    if expr == "focus":   # short temper: a deep frown crease
        cv.ink(cv.line(T([(36, -26), (38, -16)]), 1.2, taper=(0.4, 0.4)))
    buzz_hair(cv, T, hair)
    headband(cv, T, purple)


def king(cv, pal, skins, expr):
    """Black and gold (Phase 6: cities.gd look), a gold arm sleeve; headband, shades rim and chain in gold too."""
    skin = C.ramp(skins["umber"])
    black, silver, hair = C.ramp(pal["BLACK"]), C.ramp(pal["GOLD"]), C.ramp(pal["HAIR_BLACK"])
    T = C.Xf(150, 140, 1.0, 1.02, tilt(expr, 0.0), pivot=(0, 40), front=FRONT)
    Tn = C.Xf(150, 140, 1.12, 1.02, 0)
    body, X = skin_body(cv, skin, 1.16, T, Tn, 2)
    cv.ink(cv.line([(X(70), 250), (X(86), 236), (X(102), 232)], 1.4, taper=(0.4, 0.4)))   # trapezius
    arm_sleeve(cv, X, body, silver, near=True)
    tank_top(cv, X, black, silver, scoop=294, strap=16)
    face(cv, T, Tn, skin, expr, jaw=2, chin=2, crown=0, brow_col=(14, 8, 10), brow_w=1.2, neck=False,
         nose=1.0, wide=0.7, lips=True)
    flattop(cv, T, hair, top=-108, flare=2.0, fade=True, seed=9)
    headband(cv, T, silver)
    shades(cv, T, rim_col=silver["hi"])
    chain(cv, X, silver, pendant="crown", links=(4.6, 3.4), sp=7.5, drop=272)


# ----------------------------------------------------------------------------- Phase 6 cast (P6-A4): new parts
# Memphis, New Orleans, Denver, Seattle, Los Angeles and the three New York crews, drawn with the same kit, parts
# and lighting as the cast above; each matches his sprite in tools/art/crews.json (skin, hair, outfit, colors).

class Shift:
    """A head transform moved up or down by dy head-local px (e.g. shades pushed up on the forehead)."""

    def __init__(self, T, dy):
        self.T, self.dy = T, dy

    def __call__(self, pts):
        return self.T([(p[0], p[1] + self.dy) + tuple(p[2:]) for p in pts])

    def scale(self):
        return self.T.scale()


HAIRLINE_CAP = [(-58, -6), (-64, -30), (-53, -62), (-23, -85), (14, -88), (44, -77), (60, -56), (61, -46), (48, -49),
                (26, -56), (6, -52), (-6, -40), (-9, -16), (-13, -13), (-24, -18), (-36, -16), (-48, -6)]


def tone_is(cv, tones, keys=("hi", "lt", "base", "sh", "dp")):
    """Masks of the pixels painted exactly in each tone of a ramp."""
    return {k: np.all(np.abs(cv.rgb - np.array(tones[k], np.float32)) < 0.01, axis=-1) & cv.a & ~cv.k for k in keys}


def cornrows(cv, T, hair, skin, rows=6, seed=11):
    """Cornrows: braided rows running from the forehead over the crown to the nape (concentric in 3/4 view)."""
    cm = cv.poly(T(HAIRLINE_CAP))
    cv.paint(cm, skin["sh"])
    cv.rgb[cv.crescent(cm, 8)] = skin["dp"]
    sc = T.scale()
    rng = np.random.default_rng(seed)
    radii = np.linspace(14, 64, rows)
    w = (radii[1] - radii[0]) * 0.78
    for r in radii:
        pts = [(-4 + r * 1.04 * math.cos(a), -30 - r * 0.9 * math.sin(a)) for a in np.linspace(0.05, 3.5, 24)]
        m = cv.line(T(pts), w * sc, taper=(0.15, 0.15)) & cm
        cv.cel(m, hair, shadow=cv.crescent(m, 2.5), hi=cv.sheen(m, 0.6, 1.4), ink=1.0, dots=False)
        for a in np.arange(0.12 + rng.uniform(0, 0.1), 3.5, 9.0 / max(r, 1.0)):
            x, y = -4 + r * 1.04 * math.cos(a), -30 - r * 0.9 * math.sin(a)
            nx, ny = math.cos(a), -math.sin(a)
            tx, ty = -math.sin(a), -math.cos(a)
            p0 = (x - nx * w * 0.45 - tx * 1.5, y - ny * w * 0.45 - ty * 1.5)
            p1 = (x + nx * w * 0.45 + tx * 1.5, y + ny * w * 0.45 + ty * 1.5)
            tk = cv.line(T([p0, p1]), 1.0, taper=(0.3, 0.3)) & m
            cv.rgb[tk & ~cv.k] = hair["dp"]
    return cm


def braids_back(cv, T, hair, n=4):
    """Braids hanging down behind the neck (drawn before the head)."""
    for k in range(n):
        x0 = -40 - k * 6
        pts = [(x0, -30), (x0 - 10 - k * 2, 10), (x0 - 14 - k * 3, 50 + k * 6)]
        m = cv.line(T(pts), 7.5 * T.scale(), taper=(0.0, 0.5))
        cv.cel(m, hair, shadow=cv.crescent(m, 2.5), hi=cv.sheen(m, 0.6, 1.2), ink=1.4, dots=False)
        for t in np.linspace(0.1, 0.9, 9):
            x = x0 + (-14 - k * 3) * t
            y = -30 + (80 + k * 6) * t
            cv.rgb[cv.line(T([(x - 3, y - 2), (x + 3, y + 2)]), 1.0, taper=(0.3, 0.3)) & m & ~cv.k] = hair["dp"]


def locs_tail(cv, T, hair):
    """Short locs tied back: the tail behind the head (drawn before the head)."""
    for k, (dx, dy) in enumerate(((-30, 26), (-36, 16), (-26, 36), (-40, 4))):
        pts = [(-58, -48), (-58 + dx * 0.6, -48 + dy * 0.4 - 4), (-58 + dx, -48 + dy)]
        m = cv.line(T(pts), 8.5 * T.scale(), taper=(0.1, 0.5))
        cv.cel(m, hair, shadow=cv.crescent(m, 2.5), hi=cv.sheen(m, 0.6, 1.2), ink=1.4, dots=False)
        for t in (0.35, 0.6, 0.82):
            x, y = -58 + dx * t, -48 + dy * t
            cv.rgb[cv.line(T([(x - 2, y - 3), (x + 2, y + 3)]), 0.9, taper=(0.3, 0.3)) & m & ~cv.k] = hair["dp"]


def locs_tied(cv, T, hair, tie):
    """Locs pulled back over the scalp to a tie at the back of the head."""
    base = cv.poly(T([(-58, -6), (-64, -34), (-54, -66), (-24, -90), (14, -92), (46, -80), (60, -58), (61, -46),
                      (48, -50), (26, -56), (6, -52), (-6, -40), (-9, -16), (-13, -13), (-24, -18), (-36, -16),
                      (-48, -6)]))
    cv.cel(base, hair, shadow=cv.crescent(base, 8), ink=2.0, dots=False)
    for k, (x, y) in enumerate(((56, -50), (44, -58), (30, -62), (14, -60), (0, -54), (-8, -40), (-10, -24))):
        mid = ((x - 58) / 2 + 2, (y - 50) / 2 - 18 + abs(k - 3) * 2)
        m = cv.line(T([(x, y), mid, (-58, -48)]), 7.5 * T.scale(), taper=(0.3, 0.1)) & base
        cv.cel(m, hair, shadow=cv.crescent(m, 2), hi=cv.sheen(m, 0.5, 1.0), ink=1.0, dots=False)
    tm = cv.ellipse(*T([(-58, -47)])[0], 6.5 * T.scale(), 8.5 * T.scale())
    cv.cel(tm, tie, shadow=cv.crescent(tm, 3), hi=cv.sheen(tm, 0.6, 1.2), ink=1.6, dots=False)


def shaggy(cv, T, hair, seed=6, swoop=False):
    """Shaggy hair: a rough mass over the crown and ears, locks falling over the forehead (swoop: swept forward)."""
    back = [(-8, -14), (-14, -26), (-28, -12), (-40, -6), (-54, 6), (-68, -4), (-75, -28), (-71, -60), (-50, -88),
            (-14, -102), (24, -100), (54, -84), (70, -62)]
    if swoop:
        front = [(80, -50), (74, -40, 0), (64, -42), (58, -32, 0), (46, -40), (34, -32, 0), (24, -42), (10, -38, 0),
                 (2, -46)]
    else:
        front = [(70, -42), (62, -32, 0), (54, -42), (46, -28, 0), (36, -40), (26, -28, 0), (16, -40), (6, -32, 0),
                 (2, -44)]
    hm = cv.poly(T(rough(back, 2.4, 7, seed) + front))
    sh = cv.crescent(hm, 10) | cv.poly(T([(-76, -40), (-50, -36), (-30, -14), (-56, 6)]))
    cv.cel(hm, hair, shadow=sh, hi=None, ink=2.2, dots=True, dot_sp=3.0)
    hi = cv.poly(T([(-48, -72), (-24, -92), (10, -96), (-4, -86), (-30, -74)]))
    cv.rgb[hi & hm & ~cv.k] = hair["lt"]
    rng = np.random.default_rng(seed)
    for _ in range(46):
        x, y = rng.uniform(-66, 64), rng.uniform(-96, -20)
        dx, dy = x + 8, y + 60
        n = math.hypot(dx, dy) or 1.0
        p = [(x, y), (x + dx / n * 6 + 1, y + dy / n * 6), (x + dx / n * 11 + 1, y + dy / n * 11 + 1)]
        m = cv.line(T(p), 1.1, taper=(0.4, 0.6)) & hm & ~cv.k
        cv.rgb[m] = hair["dp"] if (m & sh).any() or rng.random() < 0.55 else hair["hi"]
    return hm


def bun(cv, T, hair):
    """Long hair pulled back into a bun on the back of the crown."""
    cap = cv.poly(T([(-58, -6), (-66, -34), (-56, -70), (-24, -94), (14, -96), (46, -82), (62, -60), (62, -46),
                     (48, -50), (26, -56), (6, -52), (-6, -40), (-9, -16), (-13, -13), (-24, -18), (-36, -16),
                     (-48, -6)]))
    cv.cel(cap, hair, shadow=cv.crescent(cap, 8), hi=cv.sheen(cap, 3, 3), ink=2.0, dots=False)
    for x, y in ((56, -52), (40, -60), (22, -60), (6, -54), (-6, -40), (-10, -22), (-30, -16), (-50, -10)):
        m = cv.line(T([(x, y), ((x - 34) / 2, (y - 98) / 2 + 6), (-34, -98)]), 1.0, taper=(0.4, 0.4)) & cap
        cv.rgb[m & ~cv.k] = hair["dp"]
    bm = cv.ellipse(*T([(-34, -104)])[0], 21 * T.scale(), 17 * T.scale())
    cv.cel(bm, hair, shadow=cv.crescent(bm, 6), hi=cv.sheen(bm, 2, 2.5), ink=2.0, dots=True, dot_sp=3.0)
    for a0 in (0.4, 1.9, 3.4):
        pts = [(-34 + 15 * math.cos(a0 + t), -104 + 12 * math.sin(a0 + t)) for t in np.linspace(0, 2.0, 8)]
        cv.rgb[cv.line(T(pts), 1.1, taper=(0.4, 0.4)) & bm & ~cv.k] = hair["dp"]
    cv.ink(cv.line(T([(-46, -92), (-34, -88), (-22, -92)]), 2.4, taper=(0.2, 0.2)))     # the hair tie


def slick(cv, T, hair):
    """Slicked-back hair: a smooth, shiny cap with comb lines running to the back."""
    cap = cv.poly(T([(-58, -6), (-66, -34), (-56, -70), (-24, -95), (18, -99), (50, -86), (65, -64), (64, -50),
                     (50, -52), (28, -58), (6, -52), (-6, -40), (-9, -16), (-13, -13), (-24, -18), (-36, -16),
                     (-48, -6)]))
    cv.cel(cap, hair, shadow=cv.crescent(cap, 9), ink=2.0, dots=False)
    shine = cv.line(T([(-40, -70), (-14, -88), (20, -92), (44, -80)]), 4.0 * T.scale(), taper=(0.5, 0.5)) & cap
    cv.rgb[shine & ~cv.k] = hair["hi"]
    for r in (24, 36, 48, 58):
        pts = [(-6 + r * 1.06 * math.cos(a), -36 - r * 0.92 * math.sin(a)) for a in np.linspace(0.25, 3.3, 20)]
        m = cv.line(T(pts), 1.0, taper=(0.3, 0.3)) & cap & ~shine
        cv.rgb[m & ~cv.k] = hair["dp"]


def waves(cv, T, hair):
    """Short waves: a buzz cut with rippled rings round the crown."""
    hm = buzz_hair(cv, T, hair)
    for r in (10, 18, 26, 34, 42):
        pts = [(-12 + (r + 1.6 * math.sin(a * 9)) * math.cos(a), -56 - (r + 1.6 * math.sin(a * 9)) * 0.8 * math.sin(a))
               for a in np.linspace(-0.6, 3.6, 40)]
        cv.rgb[cv.line(T(pts), 1.4, taper=(0.3, 0.3)) & hm & ~cv.k] = hair["dp"]
        pts2 = [(x + 1.2, y - 1.2) for x, y in pts]
        cv.rgb[cv.line(T(pts2), 0.8, taper=(0.3, 0.3)) & hm & ~cv.k] = hair["lt"]
    return hm


def side_part(cv, T, hair, skin):
    """A fade with a shaved part line on the near side."""
    hm = buzz_hair(cv, T, hair)
    cv.rgb[cv.line(T([(42, -68), (16, -80), (-14, -80), (-34, -72)]), 2.0 * T.scale(), taper=(0.4, 0.3)) & hm] = \
        skin["lt"]
    return hm


def curls(cv, T, hair, seed=8, rx=60.0, ry=50.0, cy=-44.0):
    """Short curly hair: a bumpy cap a little bigger than the skull, textured with curl loops."""
    cx = -4.0
    arc = []
    for k, a in enumerate(np.linspace(math.radians(-10), math.radians(206), 34)):
        bump = 1.0 + 0.06 * math.cos(k * 2.3)
        arc.append((cx + rx * bump * math.cos(a), cy - ry * bump * math.sin(a)))
    line = [(-62, -20), (-56, -4), (-46, -6), (-32, -16), (-16, -14), (-8, -22), (-4, -40), (6, -52), (26, -58),
            (46, -54), (56, -46)]
    hm = cv.poly(T(arc + line))
    sh = cv.crescent(hm, 12) | cv.poly(T([(-70, -36), (-46, -32), (-30, -16), (-56, 0)]))
    cv.cel(hm, hair, shadow=sh, hi=None, ink=2.2, dots=True, dot_sp=3.0)
    rng = np.random.default_rng(seed)
    for _ in range(int(rx * ry / 26)):
        x, y = rng.uniform(cx - rx, cx + rx), rng.uniform(cy - ry - 4, -6)
        r = rng.uniform(1.8, 3.0)
        a0 = rng.uniform(0, 2 * math.pi)
        pts = [(x + r * math.cos(a0 + t), y + r * math.sin(a0 + t)) for t in np.linspace(0, 3.8, 6)]
        m = cv.line(T(pts), 1.1, taper=(0.4, 0.4)) & hm & ~cv.k
        cv.rgb[m] = hair["dp"] if (m & sh).any() or rng.random() < 0.5 else hair["lt"]
    hi = cv.poly(T([(-44, cy - ry * 0.55), (-24, cy - ry * 0.85), (4, cy - ry * 0.95), (-8, cy - ry * 0.75),
                    (-30, cy - ry * 0.55)]))
    cv.rgb[cv.dots(np.full(hm.shape, 0.45, np.float32), 2.6, 0.6, 30) & hi & hm & ~cv.k] = hair["hi"]
    return hm


def backcap_brim(cv, T, brim):
    """The brim of a backwards cap, pointing back (drawn before the head)."""
    b = cv.poly(T([(-44, -42), (-64, -50), (-98, -44), (-110, -34), (-104, -26), (-70, -28), (-46, -26)]))
    cv.cel(b, brim, shadow=cv.poly(T([(-110, -34), (-104, -26), (-70, -28), (-46, -26), (-50, -34), (-80, -36)])),
           hi=cv.sheen(b, 1.5, 2.5), ink=2.0, dots=False)


def backcap(cv, T, cap, brim, hair):
    """A backwards cap (Jojo's), the strap opening at the front."""
    sb = cv.poly(T([(-9, -34), (-4, -30), (-6, -14), (-10, -18), (-14, -32)]))
    cv.cel(sb, hair, shadow=cv.crescent(sb, 3), ink=1.4, dots=False)
    nape = cv.poly(T([(-52, -36), (-44, -36), (-50, -18), (-58, -8), (-62, -26)]))
    cv.cel(nape, hair, shadow=cv.crescent(nape, 4), ink=1.6, dots=False)
    dm = cv.poly(T([(-60, -30), (-60, -58), (-38, -84), (-4, -96), (32, -90), (56, -72), (66, -50), (68, -32),
                    (40, -38), (0, -40), (-36, -34)]))
    dsh = cv.crescent(dm, 9) | cv.poly(T([(-62, -40), (-30, -42), (0, -44), (40, -42), (68, -36), (68, -30),
                                         (40, -36), (0, -38), (-36, -32), (-62, -26)]))
    dhi = cv.poly(T([(-46, -62), (-30, -80), (-6, -90), (-14, -80), (-34, -66)]))
    cv.cel(dm, cap, shadow=dsh, hi=dhi | cv.sheen(dm, 3, 3), ink=2.4)
    op = cv.poly(T([(30, -38), (34, -52), (44, -58), (54, -52), (58, -40)]))
    cv.cel(op & dm, hair, shadow=cv.crescent(op, 3), ink=1.6, dots=False)
    cv.cel(cv.poly(T([(28, -40), (60, -41), (60, -36), (28, -35)])) & dm, brim, ink=1.2, dots=False)
    cv.ink(cv.line(T([(-8, -95), (10, -82), (34, -64), (44, -58)]), 1.4, taper=(0.2, 0.3)) & dm)
    cv.ink(cv.line(T([(-8, -95), (-26, -74), (-40, -50), (-44, -36)]), 1.4, taper=(0.2, 0.3)) & dm)
    cv.cel(cv.ellipse(*T([(-7, -96)])[0], 4.5, 3), cap, ink=1.4, dots=False)


def towel(cv, X, cloth, stripe):
    """A towel slung over the near shoulder, two stripes near its end."""
    m = cv.poly([(X(28), 238), (X(60), 222), (X(100), 224), (X(118), 244), (X(122), 300), (X(118), 352),
                 (X(76), 352), (X(72), 300), (X(56), 266), (X(34), 258)])
    cv.cel(m, cloth, shadow=cv.crescent(m, 10) | cv.poly([(X(30), 244), (X(70), 236), (X(74), 262), (X(36), 262)]),
           hi=cv.sheen(m, 2.5, 3), ink=2.2, dots=True, dot_sp=3.0)
    for y0 in (318, 332):
        s = cv.poly([(X(70), y0), (X(126), y0 - 2), (X(126), y0 + 6), (X(70), y0 + 8)]) & m
        cv.rgb[s & ~cv.k] = stripe["base"]
        cv.rgb[s & cv.crescent(s, 3) & ~cv.k] = stripe["sh"]
    for x0 in (88, 100, 110):
        cv.ink(cv.line([(X(x0), 252), (X(x0 + 2), 290)], 1.0, taper=(0.5, 0.5)) & m)


def whistle(cv, X, cord, metal, drop=300):
    """A whistle on a cord round the neck."""
    for xs in (108, 192):
        m = cv.line([(X(xs), 236), (X((xs + 150) / 2), drop - 22), (X(150), drop - 6)], 2.6, taper=(0, 0))
        cv.cel(m, cord, ink=0.9, dots=False)
    body = cv.poly([(X(134), drop - 4, 0), (X(160), drop - 6, 0), (X(166), drop + 4), (X(160), drop + 14),
                    (X(140), drop + 14), (X(132), drop + 6)])
    cv.cel(body, metal, shadow=cv.crescent(body, 5), hi=cv.sheen(body, 1, 2), ink=1.8, dots=False)
    mp = cv.poly([(X(160), drop - 2, 0), (X(178), drop, 0), (X(178), drop + 7, 0), (X(162), drop + 6, 0)])
    cv.cel(mp, metal, shadow=cv.crescent(mp, 2), ink=1.6, dots=False)
    cv.ink(cv.ellipse(X(146), drop + 2, 3.0, 2.2))


def gold_grin(cv, T, gold, expr):
    """Gator's gold-rimmed grin: gold caps on the teeth when he grins, a gold glint at the corner otherwise."""
    sc = T.scale()
    if expr == "happy":
        top = [(32, 41), (46, 44.5), (60, 43), (67, 40)]
        bot = [(66, 42), (58, 54), (46, 58), (34, 46)]
        M = cv.poly(T(top + bot))
        tm = cv.poly(T(top + [(66, 46), (46, 50), (33, 44.5)])) & M & ~cv.k
        cv.rgb[cv.line(T([(34, 44), (46, 47.5), (60, 46), (66, 43)]), 1.6 * sc, taper=(0.2, 0.2)) & tm] = gold["base"]
        for x0 in (40, 46, 52, 58, 63):
            cv.rgb[cv.line(T([(x0, 42.5), (x0 + 0.5, 48)]), 1.3 * sc, taper=(0, 0)) & tm] = gold["sh"]
        for x0, w in ((49, 3.0), (55, 2.8)):
            g = cv.ellipse(*T([(x0, 45.5)])[0], w * sc, 2.4 * sc) & tm
            cv.rgb[g] = gold["base"]
            cv.rgb[g & cv.sheen(g, 0.2, 0.8)] = gold["hi"]
    else:
        lift = 3.0 if expr == "smug" else 0.0
        g = cv.ellipse(*T([(61, 45.5 - lift)])[0], 2.8 * sc, 2.2 * sc)
        cv.paint(g, gold["base"])
        cv.rgb[g & cv.sheen(g, 0.2, 0.8)] = gold["hi"]
        cv.ink(cv.band(g, 0.7, 0.6, 1.3, dirs=16))


def collar_shades(cv, X, frame, y=296):
    """A pair of shades hooked on the collar by one arm."""
    lens = cv.ellipse(X(136), y + 4, 10, 7.5) | cv.ellipse(X(162), y + 3, 10, 7.5)
    cv.paint(lens, (22, 20, 34))
    cv.rgb[lens & ~cv.samp(lens, 0, 4)] = (52, 50, 74)
    cv.rgb[cv.line([(X(130), y + 8), (X(138), y - 1)], 1.8, taper=(0, 0)) & lens] = (150, 160, 200)
    fr = cv.band(lens, 1.8, 0.8, 1.3, dirs=24)
    cv.paint(fr, frame["base"])
    cv.rgb[fr & cv.crescent(fr, 1.2)] = frame["sh"]
    cv.paint(cv.line([(X(146), y + 2), (X(152), y + 1)], 2.2, taper=(0, 0)), frame["base"])
    cv.paint(cv.line([(X(170), y), (X(176), y - 14), (X(180), y - 30)], 2.0, taper=(0, 0.3)), frame["sh"])
    cv.ink(cv.band(lens | fr, 1.0, 0.7, 1.3, dirs=24))


def goggle_tan(cv, T, skin, head):
    """A pale band where ski goggles sit (the rest of the face is sunburnt a shade darker)."""
    band = cv.poly(T([(-8, -20), (30, -28), (68, -20), (70, 6), (30, 12), (-8, 8)])) & head
    t = tone_is(cv, skin, ("lt", "base", "sh"))
    cv.rgb[band & t["base"]] = skin["lt"]
    cv.rgb[band & t["sh"]] = skin["base"]
    cv.rgb[band & t["lt"]] = skin["hi"]
    cv.ink(cv.line(T([(-6, 9), (30, 13), (66, 7)]), 0.9, taper=(0.5, 0.5)) & head)


def chalk_dust(cv, X, chalk, seed=12):
    """Climbing chalk: dusty hand smudges on the tee."""
    rng = np.random.default_rng(seed)
    for x0, y0, rx, ry in ((112, 300, 15, 11), (124, 322, 9, 13), (196, 288, 12, 9)):
        m = cv.ellipse(X(x0), y0, rx, ry) & cv.a & ~cv.k
        f = cv.soft(m, 3.0) * m
        d = cv.dots(np.clip(f * 1.4, 0, 1), 2.4, 0.7, 25 + rng.uniform(0, 30)) & m
        cv.rgb[d] = cv.rgb[d] * 0.35 + np.array(chalk["lt"], np.float32) * 0.65


def cross_patch(cv, X, cloth, x0=114, y0=304):
    """A sewn-on cross patch on the chest."""
    m = cv.poly([(X(x0 - 5), y0 - 16, 0), (X(x0 + 5), y0 - 16, 0), (X(x0 + 5), y0 - 5, 0), (X(x0 + 16), y0 - 5, 0),
                 (X(x0 + 16), y0 + 5, 0), (X(x0 + 5), y0 + 5, 0), (X(x0 + 5), y0 + 16, 0), (X(x0 - 5), y0 + 16, 0),
                 (X(x0 - 5), y0 + 5, 0), (X(x0 - 16), y0 + 5, 0), (X(x0 - 16), y0 - 5, 0), (X(x0 - 5), y0 - 5, 0)])
    cv.cel(m, cloth, shadow=cv.crescent(m, 4), hi=cv.sheen(m, 0.8, 1.4), ink=1.6, dots=False)
    inner = cv.samp(m, 2.5, 0, fill=False) & cv.samp(m, -2.5, 0, fill=False) & cv.samp(m, 0, 2.5, fill=False) & \
        cv.samp(m, 0, -2.5, fill=False)
    dash = cv.hatch(np.ones(m.shape, np.float32), spacing=3.5, ang=50.0, wmax=1.0)
    cv.rgb[m & ~inner & cv.samp(m, 1.2, 0, fill=False) & cv.samp(m, -1.2, 0, fill=False) & dash & ~cv.k] = cloth["sh"]


def flannel(cv, M, top, line):
    """Flannel checks on a top: crossing darker bands, thin lines in the trim color."""
    t = tone_is(cv, top)
    order = ["hi", "lt", "base", "sh", "dp"]
    xx, yy = cv.xx, cv.yy
    n = ((np.floor((xx - 2) / 13) % 2 == 0).astype(int) + (np.floor((yy + 3) / 13) % 2 == 0).astype(int))
    new = cv.rgb.copy()
    for i, k in enumerate(order):
        for add in (1, 2):
            sel = t[k] & M & (n == add)
            new[sel] = top[order[min(4, i + add)]]
    cv.rgb[:] = new
    thin = ((np.abs(((xx - 2) % 26) - 13) < 0.7) | (np.abs(((yy + 3) % 26) - 13) < 0.7)) & M & ~cv.k
    for k in ("hi", "lt", "base", "sh", "dp"):
        cv.rgb[thin & t[k]] = line["sh"] if k in ("sh", "dp") else line["base"]


# era parts (Phase 9, P9-10) ----------------------------------------------------
# The Grandfathers' portrait parts, drawn once for the era (like the sheets' P9-04 era parts): a thick ribbed
# terry headband, mutton chops and a full mustache. Original shapes in head-local px, same lighting as the kit.

def _interp(pts, x):
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return float(np.interp(x, xs, ys))


def terry_band(cv, T, pal, low=0.0):
    """A thick ribbed terry-cloth headband (wider than headband()); low moves it down the forehead (px)."""
    top = [(-63, -44 + low), (-38, -54 + low), (0, -62 + low), (36, -60 + low), (60, -52 + low), (68, -47 + low)]
    bot = [(-63, -18 + low), (-36, -26 + low), (0, -32 + low), (40, -30 + low), (68, -26 + low)]
    bm = cv.poly(T(top + [(69, -36 + low)] + bot[::-1]))
    sh = cv.crescent(bm, 5) | cv.poly(T([(-64, -46 + low), (-40, -52 + low), (-40, -24 + low), (-64, -16 + low)]))
    cv.cel(bm, pal, shadow=sh, hi=cv.sheen(bm, 2, 3), ink=2.2, dots=True, dot_sp=2.8)
    # terry ribs: short vertical strokes across the band, closer together toward the back (wrapping round)
    for x in list(range(-58, -30, 4)) + list(range(-30, 66, 5)):
        y0, y1 = _interp(top, x) + 2.5, _interp(bot, x) - 2.5
        m = cv.line(T([(x, y0), (x + 0.6, (y0 + y1) / 2), (x, y1)]), 1.1, taper=(0.3, 0.3)) & bm & ~cv.k
        cv.rgb[m & ~sh] = pal["sh"]
        cv.rgb[m & sh] = pal["dp"]
    # a fuzzy top edge: little loops of terry poking out
    for x in range(-54, 64, 7):
        y = _interp(top, x)
        loop = cv.ellipse(*T([(x, y + 0.5)])[0], 1.8 * T.scale(), 1.4 * T.scale())
        cv.paint(loop & ~bm & cv.a, pal["base"])
    cv.ink(cv.band(bm, 1.2, 0.6, 1.4, dirs=24) & ~cv.samp(bm, 0, 3, fill=False))
    return bm


def mutton_chops(cv, T, hair, head, expr):
    """Mutton chops: thick sideburns from the temple down the cheek to the jaw, widest low, the chin shaven."""
    lift = -2.0 if expr == "happy" else 0.0
    pts = [(-12, -24, 0), (1, -24), (3, -6), (8, 12), (18, 27 + lift), (30, 37 + lift), (35, 47 + lift),
           (33, 58), (25, 70), (10, 70), (-4, 62), (-15, 52), (-24, 40, 0), (-14, 30), (-11, 14), (-11, -6)]
    cm = cv.poly(T(pts))
    sh = cv.crescent(cm, 8) | cv.poly(T([(-26, 40), (-12, 50), (8, 64), (26, 68), (10, 72), (-18, 56)]))
    hi = cv.poly(T([(-6, -16), (-3, -4), (2, 10), (7, 18), (2, 15), (-4, 2)]))
    cv.cel(cm, hair, shadow=sh, hi=hi, ink=2.0, dots=True, dot_sp=3.0)
    rng = np.random.default_rng(19)
    for _ in range(40):
        x, y = rng.uniform(-16, 32), rng.uniform(-20, 66)
        m = cv.line(T([(x, y), (x + 1.2, y + 4), (x + 0.6, y + 8)]), 1.0, taper=(0.5, 0.5)) & cm & ~cv.k
        cv.rgb[m] = hair["dp"] if rng.random() < 0.65 else hair["lt"]
    # a soft fade where the chop meets the shaven chin
    edge = cv.band(cm, 2.5, 1.0, 1.0, dirs=24) & head & ~cv.k
    cv.rgb[edge & cv.dots(np.full(cm.shape, 0.4, np.float32), 2.2, 0.6, 25)] = hair["sh"]
    return cm


def era_mustache(cv, T, hair, expr):
    """A full, thick mustache over the mouth (wider and heavier than the goatee's)."""
    dy = -3.5 if expr == "happy" else 0.0
    lift = 2.5 if expr == "happy" else 0.0
    mo = cv.poly(T([(30, 51 + dy - lift, 0), (34, 42 + dy), (44, 35.5 + dy), (54, 34 + dy), (63, 34.5 + dy),
                    (72, 38 + dy), (76, 47 + dy - lift, 0), (68, 44.5 + dy), (58, 44 + dy), (48, 45 + dy),
                    (38, 48 + dy)]))
    cv.cel(mo, hair, shadow=cv.crescent(mo, 3) | cv.poly(T([(36, 44 + dy), (56, 40 + dy), (72, 42 + dy),
                                                              (72, 46 + dy), (34, 48 + dy)])),
           hi=cv.sheen(mo, 0.8, 1.4), ink=1.8, dots=False)
    for x0 in (39, 45, 51, 57, 63, 69):
        m = cv.line(T([(x0, 37 + dy), (x0 - 1.2, 40.5 + dy), (x0 - 2.4, 44 + dy)]), 1.0, taper=(0.4, 0.4)) & mo
        cv.rgb[m] = hair["dp"]
    return mo


# characters (Phase 6) ------------------------------------------------------------

def cast_member(s):
    """A draw function from a spec (see P6 below): body and top, head, beard, hair, extras."""

    def draw(cv, pal, skins, expr):
        P = lambda n: C.ramp(pal[n])       # noqa: E731
        skin = C.ramp(skins[s["skin"]])
        top, trim = P(s["top_pal"]), P(s["trim_pal"])
        hair = P(s["hair_pal"]) if s.get("hair_pal") else None
        sx, sy, cx, cy = s.get("sx", 1.0), s.get("sy", 1.0), s.get("cx", 150), s.get("cy", 136)
        jaw = s.get("jaw", 0)
        T = C.Xf(cx, cy, sx, sy, tilt(expr, s.get("tilt", 3.0)), pivot=(0, 40), front=FRONT)
        Tn = C.Xf(cx, cy, s.get("sxn", sx * 1.04), sy, 0)
        broad = s.get("broad", 1.0)
        kind = s["top"]
        if kind == "tee":
            X, tm = tee_body(cv, skin, top, trim, broad, T, Tn, jaw)
            body = cv.poly(body_shape(broad)[0]) & ~tm
            M = tm
        else:
            body, X = skin_body(cv, skin, broad, T, Tn, jaw)
            if kind == "hoodie":
                hood_back(cv, X, Tn, top, jaw)
        if s.get("sleeve"):
            arm_sleeve(cv, X, body, P(s["sleeve"]), near=s.get("sleeve_near", True))
        if kind != "tee":
            M = tank_top(cv, X, top, trim, scoop=s.get("scoop", 286 if kind == "hoodie" else 290),
                         strap=s.get("strap", 14 if kind == "hoodie" else 18))
            if kind == "hoodie":
                drawstrings(cv, X, P(s.get("strings", s["trim_pal"])), P(s.get("tips", "WHITE")))
        ex = s.get("extras", {})
        if "flannel" in ex:
            flannel(cv, M, top, trim)
        if "patch" in ex:
            cross_patch(cv, X, P(ex["patch"]))
        if "chalk" in ex:
            chalk_dust(cv, X, P(ex["chalk"]))
        style = s.get("hair", "bald")
        if style == "braids":
            braids_back(cv, T, hair)
        if style == "locs_tied":
            locs_tail(cv, T, hair)
        if style == "backcap":
            backcap_brim(cv, T, P(s["brim"]))
        beard = s.get("beard")
        head = face(cv, T, Tn, skin, expr, jaw=jaw, chin=s.get("chin", 0), crown=s.get("crown", 0),
                    beard=bool(beard), brow_col=s.get("brow") or (hair["dp"] if hair else (20, 12, 14)),
                    brow_w=s.get("brow_w", 1.0), neck=False, nose=s.get("nose", 0.0), wide=s.get("wide", 0.0),
                    lips=s.get("lips", False), iris=s.get("iris", (60, 36, 30)), mouth=not s.get("goatee"))
        if "stubble" in ex:
            stubble(cv, T, skin, head, expr)
        if "freckles" in ex:
            freckles(cv, T, skin, seed=ex["freckles"])
        if "goggle_tan" in ex:
            goggle_tan(cv, T, skin, head)
        if "gold_grin" in ex:
            gold_grin(cv, T, P(ex["gold_grin"]), expr)
        if beard:
            beard_and_hair(cv, T, P(beard), skin, expr, grey=True)
        if "chops" in ex:
            mutton_chops(cv, T, P(ex["chops"]), head, expr)
        if "mustache" in ex:
            era_mustache(cv, T, P(ex["mustache"]), expr)
        if style == "bald":
            bald_shine(cv, T)
            cv.ink(cv.line(T([(14, -62), (30, -64), (44, -58)]), 1.0, taper=(0.5, 0.5)))
        elif style == "shaved":
            buzz_hair(cv, T, hair, sparse=True)
            bald_shine(cv, T)
        elif style == "buzz":
            buzz_hair(cv, T, hair)
        elif style == "waves":
            waves(cv, T, hair)
        elif style == "part":
            side_part(cv, T, hair, skin)
        elif style in ("cornrows", "braids"):
            cornrows(cv, T, hair, skin)
        elif style == "locs_tied":
            locs_tied(cv, T, hair, P(s.get("tie", "WHITE")))
        elif style == "twists":
            twists(cv, T, hair, seed=s.get("seed", 5))
        elif style == "curls":
            curls(cv, T, hair, seed=s.get("seed", 8), rx=s.get("curl_rx", 60.0), ry=s.get("curl_ry", 50.0))
        elif style == "afro":
            afro(cv, T, hair, seed=s.get("seed", 4))
        elif style == "flattop":
            flattop(cv, T, hair, top=s.get("flat_top", -108), flare=s.get("flare", 0.0), fade=s.get("fade", True),
                    seed=s.get("seed", 1))
        elif style == "shaggy":
            shaggy(cv, T, hair, seed=s.get("seed", 6), swoop=s.get("swoop", False))
        elif style == "bun":
            bun(cv, T, hair)
        elif style == "slick":
            slick(cv, T, hair)
        elif style == "beanie":
            beanie(cv, T, P(s["cap"]), P(s["cuff"]), hair)
        elif style == "backcap":
            backcap(cv, T, P(s["cap"]), P(s["brim"]), hair)
        if s.get("goatee"):
            goatee(cv, T, hair, expr, chin=s.get("chin", 0))
            draw_mouth(cv, T, skin, expr, beard=True)
        if s.get("headband"):
            headband(cv, T, P(s["headband"]))
        if "terry" in ex:
            terry_band(cv, T, P(ex["terry"]), low=ex.get("terry_low", 0.0))
        if "shades_up" in ex:
            shades(cv, Shift(T, -40), rim_col=P(ex["shades_up"])["lt"])
        if "shades" in ex:
            shades(cv, T, rim_col=P(ex["shades"])["hi"] if ex["shades"] else None)
        if "ear_stud" in ex:
            ear_stud(cv, T, P(ex["ear_stud"]))
        if "chain" in ex:
            chain(cv, X, P(ex["chain"]), pendant=ex.get("pendant"), links=(4.4, 3.3), sp=7.2,
                  drop=ex.get("drop", 284))
        if "towel" in ex:
            towel(cv, X, P(ex["towel"][0]), P(ex["towel"][1]))
        if "whistle" in ex:
            whistle(cv, X, P(ex["whistle"][0]), P(ex["whistle"][1]))
        if "collar_shades" in ex:
            collar_shades(cv, X, P(ex["collar_shades"]))

    return draw


# Each spec matches the player's crews.json entry and his cities.gd look text.
P6 = {
    # Memphis: Riverside Soul, orange and black
    "mem_g1": dict(name="HONEY", skin="deep", top="tank", top_pal="ORANGE", trim_pal="BLACK", broad=1.1, sx=1.04,
                   sxn=1.12, jaw=3, chin=1, wide=1.0, lips=True, tilt=2.0, hair="waves", hair_pal="HAIR_BLACK",
                   brow=(16, 8, 10), brow_w=1.2),
    "mem_g2": dict(name="LAMONT", skin="brown", top="tee", top_pal="BLACK", trim_pal="ORANGE", broad=0.92, sx=0.92,
                   sy=1.04, jaw=-2, chin=2, wide=0.6, tilt=4.0, hair="cornrows", hair_pal="HAIR_BLACK",
                   brow=(18, 10, 12)),
    "mem_boss": dict(name="SMOKE", skin="umber", top="hoodie", top_pal="BLACK", trim_pal="ORANGE", broad=1.18,
                     sx=1.1, sxn=1.2, cy=130, jaw=6, chin=2, crown=-2, wide=1.2, lips=True, tilt=0.0, hair="bald",
                     beard="HAIR_FLECK", brow=(150, 146, 146), brow_w=1.4, strings="ORANGE", tips="WHITE",
                     extras={"towel": ("WHITE", "ORANGE")}),
    "mem_a1": dict(name="BOOKER", skin="tan", top="tee", top_pal="ORANGE", trim_pal="BLACK", broad=1.06, sx=1.0,
                   sy=0.97, jaw=2, chin=-1, nose=1.0, tilt=2.0, hair="flattop", hair_pal="HAIR_DARK", fade=False,
                   flat_top=-104, seed=3, brow=(22, 14, 16), brow_w=1.2),
    "mem_a2": dict(name="WENDELL", skin="deep", top="tank", top_pal="BLACK", trim_pal="ORANGE", broad=0.94, sx=0.92,
                   sy=1.07, cy=132, jaw=-1, chin=2, crown=2, wide=0.9, lips=True, tilt=4.0, hair="curls",
                   hair_pal="HAIR_BLACK", curl_rx=66.0, curl_ry=58.0, seed=14, brow=(14, 8, 10)),
    # New Orleans: Bayou Brass, teal and white
    "nol_g1": dict(name="LUCIEN", skin="brown", top="tank", top_pal="TEAL", trim_pal="WHITE", broad=0.88, sx=0.9,
                   sy=1.0, jaw=-3, chin=1, wide=0.5, tilt=4.0, hair="locs_tied", hair_pal="HAIR_DARK", tie="TEAL",
                   headband="WHITE", brow=(20, 12, 12)),
    "nol_g2": dict(name="BEAU", skin="light", top="tee", top_pal="WHITE", trim_pal="TEAL", broad=0.94, sx=0.92,
                   sy=1.04, jaw=-2, chin=3, nose=2.0, tilt=3.0, hair="shaggy", hair_pal="HAIR_BROWN", seed=21,
                   iris=(62, 120, 110)),
    "nol_boss": dict(name="GATOR", skin="deep", top="hoodie", top_pal="TEAL", trim_pal="WHITE", broad=1.16, sx=1.08,
                     sxn=1.18, cy=132, jaw=5, chin=2, crown=-1, wide=1.3, lips=True, tilt=0.0, hair="flattop",
                     hair_pal="HAIR_INK", flat_top=-96, fade=True, seed=6, brow=(14, 8, 10), brow_w=1.3,
                     strings="WHITE", tips="GOLD", extras={"gold_grin": "GOLD", "chain": "GOLD", "drop": 290}),
    "nol_a1": dict(name="PIERRE", skin="tan", top="tee", top_pal="WHITE", trim_pal="TEAL", broad=1.0, sx=1.0, sy=0.96,
                   jaw=1, chin=-1, nose=1.0, wide=0.6, tilt=2.0, hair="curls", hair_pal="HAIR_INK", seed=9,
                   brow=(20, 12, 14), brow_w=1.2, extras={"stubble": True}),
    "nol_a2": dict(name="MOOSE", skin="light", top="tank", top_pal="TEAL", trim_pal="WHITE", broad=1.16, sx=1.1,
                   sxn=1.18, cy=132, jaw=5, chin=2, wide=0.8, tilt=1.0, hair="buzz", hair_pal="HAIR_RUST",
                   beard="HAIR_RUST", brow_w=1.3, iris=(70, 110, 150)),
    # Denver: Switchbacks, forest and silver
    "den_g1": dict(name="WES", skin="light", top="tank", top_pal="FOREST", trim_pal="SILVER", broad=0.92, sx=0.9,
                   sy=1.04, cy=140, jaw=-2, chin=3, nose=1.5, tilt=4.0, hair="beanie", hair_pal="HAIR_SANDY",
                   cap="FOREST", cuff="SILVER", iris=(80, 110, 140)),
    "den_g2": dict(name="THEO", skin="umber", top="tee", top_pal="SILVER", trim_pal="GREEN", broad=0.9, sx=0.9,
                   sy=1.0, jaw=-3, chin=1, wide=0.7, tilt=4.0, hair="twists", hair_pal="HAIR_BLACK", seed=17,
                   brow=(18, 10, 12), extras={"chalk": "CHALK"}),
    "den_boss": dict(name="RIDGE", skin="light", top="hoodie", top_pal="FOREST", trim_pal="SILVER", broad=1.16,
                     sx=1.08, sxn=1.16, cy=132, jaw=6, chin=2, crown=0, nose=1.0, tilt=0.0, hair="shaggy",
                     hair_pal="HAIR_BLOND", beard="HAIR_BLOND", seed=31, brow_w=1.4, iris=(70, 120, 160),
                     strings="SILVER", tips="FOREST", extras={"patch": "SILVER"}),
    "den_a1": dict(name="GUS", skin="tan", top="tee", top_pal="SILVER", trim_pal="FOREST", broad=1.04, sx=1.0,
                   sy=0.97, jaw=2, chin=0, nose=1.0, wide=0.8, tilt=2.0, hair="backcap", hair_pal="HAIR_DARK",
                   cap="FOREST", brim="SILVER", brow=(22, 14, 16), brow_w=1.2),
    "den_a2": dict(name="CODY", skin="light", top="tank", top_pal="GREEN", trim_pal="SILVER", broad=0.94, sx=0.92,
                   sy=1.07, cy=134, jaw=-1, chin=2, nose=0.5, tilt=3.0, hair="shaggy", hair_pal="HAIR_BROWN",
                   seed=44, iris=(96, 120, 70), extras={"goggle_tan": True}),
    # Seattle: Puddle Jumpers, navy and lime
    "sea_g1": dict(name="DEX", skin="deep", top="tank", top_pal="NAVY", trim_pal="LIME", broad=0.88, sx=0.9,
                   sy=0.99, jaw=-2, chin=0, wide=0.8, lips=True, tilt=4.0, hair="buzz", hair_pal="HAIR_BLACK",
                   brow=(14, 8, 10)),
    "sea_g2": dict(name="IGGY", skin="light", top="tank", top_pal="NAVY", trim_pal="LIME", broad=0.94, sx=0.92,
                   sy=1.05, cy=140, jaw=-1, chin=3, nose=1.5, tilt=3.0, hair="bun", hair_pal="HAIR_DARK",
                   iris=(90, 110, 80), extras={"flannel": True, "stubble": True}),
    "sea_boss": dict(name="DOWNPOUR", skin="tan", top="hoodie", top_pal="NAVY", trim_pal="LIME", broad=1.12,
                     sx=1.04, sxn=1.12, cy=132, jaw=3, chin=1, nose=0.5, wide=0.6, tilt=0.0, hair="buzz",
                     hair_pal="HAIR_INK", headband="LIME", brow=(20, 14, 18), brow_w=1.3, strings="LIME",
                     tips="YELLOW", extras={"ear_stud": "SILVER"}),
    "sea_a1": dict(name="MILO", skin="light", top="tee", top_pal="LIME", trim_pal="NAVY", broad=1.02, sx=1.0, sy=0.96,
                   jaw=1, chin=-2, nose=-1.5, tilt=2.0, hair="curls", hair_pal="HAIR_RUST", seed=27,
                   iris=(70, 120, 70), extras={"freckles": 5}),
    "sea_a2": dict(name="RAY", skin="light", top="tee", top_pal="NAVY", trim_pal="LIME", broad=0.98, sx=0.93,
                   sy=1.07, cy=132, jaw=0, chin=3, crown=2, nose=1.0, tilt=1.0, hair="buzz", hair_pal="HAIR_BLOND",
                   iris=(80, 120, 170)),
    # Los Angeles: Boardwalk Bombers, sky and sand
    "la_g1": dict(name="TREY", skin="brown", top="tank", top_pal="SKY", trim_pal="SAND", broad=0.92, sx=0.92,
                  sy=1.02, jaw=-2, chin=1, wide=0.7, tilt=4.0, hair="curls", hair_pal="HAIR_DARK", seed=33,
                  curl_rx=58.0, curl_ry=46.0, brow=(18, 10, 12)),
    "la_g2": dict(name="KAI", skin="tan", top="tee", top_pal="SAND", trim_pal="SKY", broad=1.06, sx=1.0, sy=1.0,
                  jaw=2, chin=1, nose=1.0, wide=0.5, tilt=3.0, hair="shaggy", hair_pal="HAIR_SUN", seed=52,
                  brow=(150, 110, 70), iris=(60, 46, 34)),
    "la_boss": dict(name="SUNSET", skin="deep", top="hoodie", top_pal="SKY", trim_pal="SAND", broad=1.14, sx=1.02,
                    sxn=1.12, cy=138, jaw=2, chin=2, wide=0.8, lips=True, tilt=0.0, hair="twists",
                    hair_pal="HAIR_BLACK", seed=41, brow=(14, 8, 10), brow_w=1.2, strings="SAND", tips="WHITE",
                    extras={"whistle": ("WHITE", "SILVER")}),
    "la_a1": dict(name="BRODY", skin="light", top="tee", top_pal="SKY", trim_pal="SAND", broad=0.9, sx=0.92, sy=1.0,
                  jaw=-2, chin=2, nose=1.0, tilt=3.0, hair="shaggy", hair_pal="HAIR_BLOND", swoop=True, seed=61,
                  iris=(70, 130, 180)),
    "la_a2": dict(name="DUKE", skin="umber", top="tank", top_pal="SAND", trim_pal="SKY", broad=1.18, sx=1.1,
                  sxn=1.2, cy=132, jaw=6, chin=1, wide=1.2, lips=True, tilt=1.0, hair="buzz", hair_pal="HAIR_BLACK",
                  brow=(14, 8, 10), brow_w=1.3,
                  extras={"shades": "SKY", "shades_up": "RED", "collar_shades": "GOLD"}),
    # New York quarterfinal: Bridge Runners, red and black
    "ny_q1": dict(name="ACE", skin="tan", top="tank", top_pal="RED", trim_pal="BLACK", broad=1.08, sx=1.02, sxn=1.1,
                  jaw=3, chin=1, nose=2.0, wide=0.4, tilt=1.0, hair="slick", hair_pal="HAIR_INK", brow=(20, 14, 18),
                  brow_w=1.2, extras={"stubble": True}),
    "ny_q2": dict(name="DASH", skin="deep", top="tee", top_pal="BLACK", trim_pal="RED", broad=0.9, sx=0.9, sy=1.0,
                  jaw=-3, chin=0, wide=0.6, tilt=4.0, hair="part", hair_pal="HAIR_BLACK", brow=(14, 8, 10)),
    "ny_q3": dict(name="KNOX", skin="light", top="tank", top_pal="RED", trim_pal="BLACK", broad=0.94, sx=0.92,
                  sy=1.07, cy=132, jaw=0, chin=2, crown=2, nose=-1.0, tilt=3.0, hair="buzz", hair_pal="HAIR_RUST",
                  iris=(80, 110, 70), extras={"freckles": 9}),
    # New York semifinal: Bodega Bandits, grey and plum
    "ny_s1": dict(name="JAX", skin="umber", top="tank", top_pal="GREYW", trim_pal="PLUM", broad=0.92, sx=0.92,
                  sy=1.02, cy=140, jaw=-2, chin=1, wide=0.6, lips=True, tilt=4.0, hair="flattop",
                  hair_pal="HAIR_BLACK", flat_top=-112, fade=True, seed=13, brow=(14, 8, 10)),
    "ny_s2": dict(name="OMAR", skin="brown", top="tee", top_pal="PLUM", trim_pal="GREYW", broad=0.96, sx=0.94,
                  sy=1.04, jaw=2, chin=1, nose=1.0, tilt=2.0, hair="buzz", hair_pal="HAIR_DARK", beard="HAIR_DARK",
                  sleeve="PLUM", sleeve_near=False, brow_w=1.2),
    "ny_s3": dict(name="BRUNO", skin="light", top="hoodie", top_pal="GREYW", trim_pal="PLUM", broad=1.18, sx=1.1,
                  sxn=1.2, cy=132, jaw=6, chin=2, crown=-2, nose=0.5, wide=1.0, tilt=1.0, hair="buzz",
                  hair_pal="HAIR_DARK", brow_w=1.4, strings="PLUM", tips="GREYW", iris=(90, 80, 60)),
    # New York final: Concrete Crowns, black and gold
    "ny_f1": dict(name="SLIM", skin="tan", top="tank", top_pal="BLACK", trim_pal="GOLD", broad=0.88, sx=0.9,
                  sy=1.02, jaw=-3, chin=2, nose=1.0, wide=0.4, tilt=4.0, hair="braids", hair_pal="HAIR_INK",
                  brow=(20, 14, 18), extras={"ear_stud": "GOLD"}),
    "ny_f2": dict(name="HAMMER", skin="light", top="hoodie", top_pal="BLACK", trim_pal="GOLD", broad=1.2, sx=1.12,
                  sxn=1.22, cy=130, jaw=6, chin=3, crown=-2, nose=0.0, wide=1.0, tilt=0.0, hair="shaved",
                  hair_pal="HAIR_BROWN", brow_w=1.5, strings="GOLD", tips="BLACK", iris=(70, 90, 110)),
}


GOLD_RIM, HT_RIM, CHI_RIM, NY_RIM = (255, 214, 110), (150, 240, 150), (200, 160, 255), (226, 230, 244)
P6_RIM = {"MEM": (255, 172, 96), "NOL": (120, 232, 220), "DEN": (176, 226, 186), "SEA": (214, 250, 120),
          "LA": (176, 224, 255), "NYQ": (255, 136, 130), "NYS": (214, 184, 236), "NYF": (255, 214, 110)}
# anchor y per hair height (see CAST): tall hair is drawn lower
P6_ANCHOR = {"flattop": 110, "beanie": 110, "bun": 110, "curls": 160, "shaggy": 170, "backcap": 200,
             "locs_tied": 220, "twists": 220, "cornrows": 240, "braids": 240}

# the whole cast: id -> (name, draw function, back light, [(mood, file suffix)], drawing anchor y)
# The first mood is the base portrait (<id>.png). A lower anchor y draws the bust lower (room for tall hair).
CAST = {
    "ud_deuce": ("DEUCE", deuce, GOLD_RIM, [("focus", ""), ("happy", "_happy")], 250),
    "ud_jojo": ("JOJO", jojo, GOLD_RIM, [("focus", ""), ("happy", "_happy")], 250),
    "ud_tank": ("TANK", tank, GOLD_RIM, [("focus", ""), ("happy", "_happy")], 250),
    "ht_boss": ("MAYOR", mayor, HT_RIM, [("neutral", ""), ("happy", "_happy"), ("smug", "_smug")], 250),
    "ht_g1": ("SKIP", skip, HT_RIM, [("focus", ""), ("happy", "_happy")], 110),
    "ht_g2": ("BUCK", buck, HT_RIM, [("focus", ""), ("happy", "_happy")], 110),
    "ht_a1": ("DALE", dale, HT_RIM, [("focus", ""), ("happy", "_happy")], 250),
    "ht_a2": ("RUSTY", rusty, HT_RIM, [("focus", ""), ("happy", "_happy")], 200),
    "chi_boss": ("BIG LOU", big_lou, CHI_RIM, [("neutral", ""), ("happy", "_happy"), ("smug", "_smug")], 250),
    "chi_g1": ("NICO", nico, CHI_RIM, [("focus", ""), ("happy", "_happy")], 110),
    "chi_g2": ("RIO", rio, CHI_RIM, [("focus", ""), ("happy", "_happy")], 110),
    "chi_a1": ("MARCO", marco, CHI_RIM, [("focus", ""), ("happy", "_happy")], 200),
    "chi_a2": ("TERRELL", terrell, CHI_RIM, [("focus", ""), ("happy", "_happy")], 250),
    "ny_boss": ("KING", king, P6_RIM["NYF"], [("neutral", ""), ("happy", "_happy"), ("smug", "_smug")], 110),
}
P6_CREWS = [("MEMPHIS: RIVERSIDE SOUL", "MEM", "mem_"), ("NEW ORLEANS: BAYOU BRASS", "NOL", "nol_"),
            ("DENVER: SWITCHBACKS", "DEN", "den_"), ("SEATTLE: PUDDLE JUMPERS", "SEA", "sea_"),
            ("LOS ANGELES: BOARDWALK BOMBERS", "LA", "la_"), ("NEW YORK QUARTERFINAL: BRIDGE RUNNERS", "NYQ", "ny_q"),
            ("NEW YORK SEMIFINAL: BODEGA BANDITS", "NYS", "ny_s"), ("NEW YORK FINAL: CONCRETE CROWNS", "NYF", "ny_f")]
for _title, _crew, _pre in P6_CREWS:
    for _pid, _s in P6.items():
        if _pid.startswith(_pre):
            _moods = [("neutral", ""), ("happy", "_happy"), ("smug", "_smug")] if _pid.endswith("_boss") else \
                [("focus", ""), ("happy", "_happy")]
            CAST[_pid] = (_s["name"], cast_member(_s), P6_RIM[_crew], _moods,
                          P6_ANCHOR.get(_s.get("hair", ""), 250))
CREW_CARD = {"U": (64, 150, 255), "HT": (60, 160, 80), "CHI": (124, 68, 208), "NY": (150, 150, 170),
             "MEM": (240, 122, 30), "NOL": (30, 166, 160), "DEN": (38, 92, 54), "SEA": (120, 170, 40),
             "LA": (108, 188, 240), "NYQ": (216, 40, 58), "NYS": (110, 70, 130), "NYF": (190, 150, 40)}
P6_SHEET = os.path.join(ROOT, "docs", "art", "portraits_p6.png")

# Phase 9 (P9-10): the six Grandfathers (Legends Chapter 1, docs/legends-plan.md part 3; L1 a). Original characters
# made from the kit's parts; their looks follow the plan's look notes and the approved look sample
# (docs/art/legends_sample_v1.png: Steeple's terry headband and mutton chops, the ERA_* colors of crews.json), so
# they match the in-game sheets (P9-09). Base mood neutral, plus happy.
LG = {
    # hook-shot center: very tall and wiry, mutton chops, a terry headband (the approved sample's look)
    "lg_steeple": dict(name="STEEPLE", skin="umber", top="tank", top_pal="ERA_CRIMSON", trim_pal="ERA_CREAM",
                       broad=0.9, sx=0.88, sy=1.1, sxn=0.94, cy=138, jaw=-2, chin=3, crown=2, nose=1.0, wide=0.8,
                       lips=True, tilt=2.0, hair="buzz", hair_pal="HAIR_BLACK", brow=(16, 8, 10), brow_w=1.1,
                       extras={"chops": "HAIR_BLACK", "terry": "ERA_MUSTARD", "terry_low": 4.0}),
    # shot-blocking wall: broad big, a flat-top
    "lg_gate": dict(name="GATE", skin="light", top="tank", top_pal="ERA_OLIVE", trim_pal="ERA_CREAM", broad=1.2,
                    sx=1.1, sxn=1.2, cy=134, jaw=6, chin=2, crown=-2, nose=0.5, wide=0.8, tilt=0.0, hair="flattop",
                    hair_pal="HAIR_BROWN", flat_top=-104, fade=True, seed=7, brow_w=1.5, iris=(80, 100, 120)),
    # deep shooter: lean, a side part
    "lg_set_shot": dict(name="SET SHOT", skin="tan", top="tank", top_pal="ERA_POWDER", trim_pal="ERA_BROWN",
                        broad=0.9, sx=0.9, sy=1.04, cy=136, jaw=-3, chin=2, nose=1.5, wide=0.3, tilt=3.0,
                        hair="part", hair_pal="HAIR_DARK", brow=(22, 14, 16)),
    # bruising power forward: heavy, bald
    "lg_boxcar": dict(name="BOXCAR", skin="deep", top="tank", top_pal="ERA_WHITE", trim_pal="ERA_MUSTARD",
                      broad=1.22, sx=1.12, sxn=1.22, cy=132, jaw=7, chin=2, crown=-3, wide=1.3, lips=True, tilt=0.0,
                      hair="bald", brow=(14, 8, 10), brow_w=1.5),
    # smooth slasher: long, an afro with a terry headband
    "lg_velvet": dict(name="VELVET", skin="brown", top="tank", top_pal="ERA_LEMON", trim_pal="ERA_NAVY",
                      broad=0.92, sx=0.9, sy=1.06, sxn=0.96, cy=140, jaw=-2, chin=2, wide=0.7, lips=True, tilt=3.0,
                      hair="afro", hair_pal="HAIR_BLACK", seed=23, brow=(16, 8, 10),
                      extras={"terry": "ERA_CREAM", "terry_low": 7.0}),
    # no-look floor general: short, a mustache
    "lg_quarterback": dict(name="QUARTERBACK", skin="light", top="tank", top_pal="ERA_CREAM", trim_pal="ERA_RUST",
                           broad=1.0, sx=1.0, sy=0.96, cy=138, jaw=1, chin=-1, nose=-0.5, wide=0.4, tilt=2.0,
                           hair="curls", hair_pal="HAIR_RUST", curl_rx=60.0, curl_ry=48.0, seed=35,
                           iris=(70, 110, 80), extras={"mustache": "HAIR_RUST", "freckles": 13}),
}
LG_RIM = (255, 214, 138)
LG_SHEET = os.path.join(ROOT, "docs", "art", "legends_portraits.png")
LG_ANCHOR = {"afro": 110}
for _pid, _s in LG.items():
    CAST[_pid] = (_s["name"], cast_member(_s), LG_RIM, [("neutral", ""), ("happy", "_happy")],
                  LG_ANCHOR.get(_s["hair"], P6_ANCHOR.get(_s["hair"], 250)))
CREW_CARD["LG"] = (196, 88, 42)


# ----------------------------------------------------------------------------- the sample sheet

def font(sz, bold=False):
    for f in ("/usr/share/fonts/opentype/inter/Inter-Bold.otf" if bold else
              "/usr/share/fonts/opentype/inter/Inter-Medium.otf",):
        if os.path.exists(f):
            return ImageFont.truetype(f, sz)
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
    scr = backdrop(1280, 720, (40, 34, 66), (16, 14, 26))
    d = ImageDraw.Draw(scr)
    cx = 300 if speaker == "left" else 980
    for k in range(28):
        ang = k * (math.pi * 2 / 28)
        d.line([(cx + math.cos(ang) * 120, 300 + math.sin(ang) * 120),
                (cx + math.cos(ang) * 700, 300 + math.sin(ang) * 700)], fill=(60, 52, 96, 255), width=6)
    for img, side in ((left, "left"), (right, "right")):
        im = img if side == "left" else img.transpose(Image.FLIP_LEFT_RIGHT)
        if side != speaker:
            arr = np.array(im).astype(np.float32)
            arr[:, :, :3] *= 0.72
            im = Image.fromarray(arr.astype(np.uint8), "RGBA")
        x = 120 if side == "left" else 1280 - 120 - PW
        scr.alpha_composite(im, (x, 720 - 200 - PH + 24))
    d.rounded_rectangle([40, 500, 1240, 696], 16, fill=(14, 12, 24, 240), outline=(242, 182, 44, 255), width=4)
    nx = 70 if speaker == "left" else 1210 - 260
    d.rounded_rectangle([nx, 474, nx + 260, 522], 10, fill=(242, 182, 44, 255), outline=(110, 66, 14, 255), width=3)
    d.text((nx + 130, 498), name, font=font(28, True), fill=(20, 14, 26), anchor="mm")
    d.text((80, 548), line, font=font(30), fill=(240, 240, 250))
    d.text((80, 600), sub, font=font(30), fill=(240, 240, 250))
    d.text((1210, 676), "TAP  >", font=font(20), fill=(255, 230, 138), anchor="rm")
    d.rounded_rectangle([1130, 20, 1260, 64], 10, fill=(52, 52, 63, 255), outline=(154, 154, 176, 255), width=2)
    d.text((1195, 42), "SKIP", font=font(20), fill=(255, 255, 255), anchor="mm")
    return scr


def portrait(pid, expr, pal, skins):
    _, draw, rim, _, ay = CAST[pid]
    cv = C.Canvas(PW, PH, zoom=ZOOM, anchor=(150, ay))
    draw(cv, pal, skins, expr)
    cv.rim(rim, width=3.0, strength=0.55)
    # bold outer contour round the whole bust
    cv.ink(cv.band(cv.a, 1.6, 0.6, 1.5))
    return cv.image()


def save(img, path):
    q = img.quantize(colors=255, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    q.save(path, optimize=True)


def main():
    pal, skins, players = load()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    sample = "--sample" in sys.argv
    legends_only = "--legends" in sys.argv
    if args:
        # quick look at some characters: a row of their moods, nothing written to assets/
        made = [portrait(pid, e, pal, skins) for pid in args for e, _ in CAST[pid][3]]
        row = Image.new("RGBA", (PW * len(made), PH), (40, 34, 66, 255))
        for i, im in enumerate(made):
            row.alpha_composite(im, (i * PW, 0))
        row.save(os.environ.get("ROW_OUT", "/tmp/portrait_row.png"))
        return
    os.makedirs(OUT_DIR, exist_ok=True)
    made = {}
    total = 0
    for pid, (name, _, _, moods, _) in CAST.items():
        if legends_only and pid not in LG:
            continue
        for expr, suf in moods:
            img = portrait(pid, expr, pal, skins)
            path = os.path.join(OUT_DIR, pid + suf + ".png")
            save(img, path)
            made[(pid, expr)] = img
            total += os.path.getsize(path)
            print("wrote", pid + suf + ".png", os.path.getsize(path))
    print("total bytes", total)
    legends_sheet(made, pal, skins)
    if legends_only:
        return
    if sample:
        sample_sheet(made, players)
    full_sheet(made)
    p6_crews = [(t, c, [p for p in P6 if p.startswith(pre)]) for t, c, pre in P6_CREWS]
    for _, _, ids in p6_crews:          # boss first, like the full sheet
        ids.sort(key=lambda p: (not p.endswith("_boss"), p))
    full_sheet(made, crews=p6_crews, path=P6_SHEET,
               heading="Story portraits, Phase 6 cast (P6-A4) - drawn comic style v2, 288 x 336 (shown 1:1); "
                     "the first of each character is the base portrait",
               mocks=[(("ud_deuce", "focus"), ("nol_boss", "happy"), "right", "GATOR",
                       "Welcome to the bayou, cornfield boys.", "Hope y'all brought your running shoes."),
                      (("ud_tank", "focus"), ("la_a2", "happy"), "right", "DUKE",
                       "Three pairs. One for every quarter.", "...We play to 21, man. There are no quarters.")])


def legends_sheet(made, pal, skins):
    """docs/art/legends_portraits.png (P9-10): the six Grandfathers, two story mock-ups and every mood.
    The mock-ups' crew portraits are drawn here when --legends did not make them (nothing more is written)."""
    for key in (("ud_deuce", "focus"), ("ud_jojo", "happy")):
        if key not in made:
            made[key] = portrait(key[0], key[1], pal, skins)
    full_sheet(made, crews=[("LEGENDS CHAPTER 1: THE GRANDFATHERS", "LG", list(LG))], path=LG_SHEET,
               heading="Story portraits, the Grandfathers (P9-10) - drawn comic style v2, 288 x 336 (shown 1:1); "
                       "the first of each legend is the base portrait",
               mocks=[(("ud_deuce", "focus"), ("lg_steeple", "neutral"), "right", "STEEPLE",
                       "Lean in, young man. Watch the elbow.", "Nobody blocks what they cannot reach."),
                      (("ud_jojo", "happy"), ("lg_quarterback", "happy"), "right", "QUARTERBACK",
                       "Pass first, kid. Then pass again.", "Shooting is for folks who can't find a teammate.")])


def full_sheet(made, crews=None, mocks=None, path=FULL_SHEET,
               heading="Story portraits v2 - the full set, drawn comic style, 288 x 336 (shown 1:1); "
                     "the first of each character is the base portrait"):
    """docs/art/portraits_full_v2.png: two story mock-ups, then every portrait (base + moods) labeled, by crew.
    Phase 6 calls it with its crews, mock-ups and path (docs/art/portraits_p6.png)."""
    crews = crews or [("YOUR CREW: CORNFIELD KINGS", "U", ["ud_deuce", "ud_jojo", "ud_tank"]),
                      ("HOMETOWN: COUNTY LINE", "HT", ["ht_boss", "ht_g1", "ht_g2", "ht_a1", "ht_a2"]),
                      ("CHICAGO: LAKESHORE GUSTS", "CHI", ["chi_boss", "chi_g1", "chi_g2", "chi_a1", "chi_a2"]),
                      ("NEW YORK: CONCRETE CROWNS", "NY", ["ny_boss"])]
    mocks = mocks or [(("ud_jojo", "focus"), ("chi_boss", "smug"), "right", "BIG LOU",
                       "Easy, Nico. Let 'em play. I'm Big Lou.", "Nobody scores on me twice in Chicago."),
                      (("ud_deuce", "focus"), ("ny_boss", "neutral"), "right", "KING",
                       "So you're the Cornfield Kings.", "Heard you came all the way from a cornfield.")]
    cols, cw, ch = 7, 304, PH + 44
    width = cols * cw + 32
    rows = []          # (title or None, [(pid, expr)])
    for title, crew, ids in crews:
        cells = [(pid, e) for pid in ids for e, _ in CAST[pid][3]]
        rows.append((title, crew, None))
        for k in range(0, len(cells), cols):
            rows.append((None, crew, cells[k:k + cols]))
    mock_w = width // 2 - 24
    mock_h = int(mock_w * 720 / 1280)
    height = 80 + mock_h + 30 + sum(46 if t else ch for t, _, _ in rows) + 50
    sheet = Image.new("RGBA", (width, height), (24, 22, 34, 255))
    d = ImageDraw.Draw(sheet)
    d.text((24, 22), heading, font=font(28, True), fill=(240, 240, 250))
    m1, m2 = [story_mock(made[a], made[b], side, nm, l1, l2) for a, b, side, nm, l1, l2 in mocks]
    sheet.alpha_composite(m1.resize((mock_w, mock_h), Image.LANCZOS), (16, 70))
    sheet.alpha_composite(m2.resize((mock_w, mock_h), Image.LANCZOS), (width // 2 + 8, 70))
    y = 70 + mock_h + 30
    for title, crew, cells in rows:
        if title:
            d.text((24, y + 10), title, font=font(26, True), fill=(255, 230, 138))
            y += 46
            continue
        ring = CREW_CARD[crew]
        for c, (pid, expr) in enumerate(cells):
            x = 16 + c * cw + (cw - PW - 8) // 2
            card = backdrop(PW + 8, PH + 8, tuple(int(v * 0.35) for v in ring), (20, 18, 30))
            sheet.alpha_composite(card, (x, y + 30))
            d.rectangle([x, y + 30, x + PW + 7, y + 30 + PH + 7], outline=(74, 70, 96, 255), width=2)
            sheet.alpha_composite(made[(pid, expr)], (x + 4, y + 34))
            d.text((x, y + 4), "%s  %s" % (CAST[pid][0], EXPR_LABEL[expr]), font=font(20, True),
                   fill=(240, 240, 250))
        y += ch
    d.text((24, height - 34), "Variable-weight ink, 2 cel tones + halftone/hatched deep shadow + highlight, "
                              "crew-colored back light, game palette (tools/art/crews.json). Original, drawn by "
                              "tools/art/make_portraits_v2.py.", font=font(18), fill=(154, 154, 176))
    sheet = sheet.convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    sheet.save(path, optimize=True)
    print("wrote", path)


def sample_sheet(made, players):
    """The approved sample sheet (docs/art/portraits_sample_v2.png), only with --sample."""
    mock1 = story_mock(made[("ud_deuce", "focus")], made[("ht_boss", "smug")], "right", "MAYOR",
                       "Well, well. The Cornfield Kings, in MY town?",
                       "Go home, boys. The county line is mine.")
    mock2 = story_mock(made[("ud_jojo", "happy")], made[("ud_tank", "happy")], "left", "JOJO",
                       "We did it! Next stop: Chicago!",
                       "Tank, you're driving. The Biscuit likes you.")
    cw = 320
    cell_h = PH + 50
    sheet_h = 70 + 720 + 24 + 720 + 40 + 2 * cell_h + 40
    sheet = Image.new("RGBA", (1280, sheet_h), (24, 22, 34, 255))
    d = ImageDraw.Draw(sheet)
    d.text((24, 20), "Story portraits SAMPLE v2 - drawn comic style, 288 x 336 (shown 1:1)", font=font(26, True),
           fill=(240, 240, 250))
    sheet.alpha_composite(mock1, (0, 70))
    sheet.alpha_composite(mock2, (0, 70 + 720 + 24))
    y0 = 70 + 720 + 24 + 720 + 40
    for c, pid in enumerate(SAMPLE):
        for r, (expr, _) in enumerate(SAMPLE[pid]):
            x, y = c * cw + (cw - PW - 8) // 2, y0 + r * cell_h
            ring = (64, 150, 255) if players[pid]["crew"] == "U" else (60, 160, 80)
            card = backdrop(PW + 8, PH + 8, tuple(int(v * 0.35) for v in ring), (20, 18, 30))
            sheet.alpha_composite(card, (x, y + 30))
            d.rectangle([x, y + 30, x + PW + 7, y + 30 + PH + 7], outline=(74, 70, 96, 255), width=2)
            sheet.alpha_composite(made[(pid, expr)], (x + 4, y + 34))
            d.text((x, y + 4), "%s  %s" % (NAMES[pid], EXPR_LABEL[expr]), font=font(20, True), fill=(255, 230, 138))
    d.text((24, sheet_h - 30), "Variable-weight ink, 2 cel tones + halftone/hatched deep shadow + highlight, "
                               "crew-colored back light, game palette. Original, drawn by script.",
           font=font(17), fill=(154, 154, 176))
    sheet = sheet.convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    sheet.save(SHEET, optimize=True)
    print("wrote", SHEET)


if __name__ == "__main__":
    main()
