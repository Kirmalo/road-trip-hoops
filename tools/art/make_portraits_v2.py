#!/usr/bin/env python3
"""Story portraits SAMPLE v2 for Road Trip Hoops (P5-A2): drawn comic-book busts.

Owner feedback on v1: "a higher quality, make it look like drawn comic style". v2 draws each bust as 2D comic art
with tools/art/comic.py: curved shapes placed by hand per character, hard-edged cel tones from the game palette
(tools/art/crews.json), halftone-dot and hatched deep shadows, crisp highlights, variable-weight ink lines
(heavier on the side away from the light), a bold outer contour. The heads are in 3/4 view facing right
(story.gd mirrors for the right side). Original characters; nothing is traced, downloaded or copied.

Usage:  python3 tools/art/make_portraits_v2.py
Output: assets/portraits/v2/<id>.png           288 x 336 (the 96 x 112 contract at 3x), default expression
        assets/portraits/v2/<id>_<expr>.png    other expressions (happy, smug)
        docs/art/portraits_sample_v2.png       story text box mock-ups and all sample portraits
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
OUT_DIR = os.path.join(ROOT, "assets", "portraits", "v2")
SHEET = os.path.join(ROOT, "docs", "art", "portraits_sample_v2.png")
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

def head_outline(jaw=0.0, chin=0.0, crown=0.0):
    j, c, k = jaw, chin, crown
    return [
        (-50, -60 - k), (-22, -82 - k), (14, -85 - k), (42, -74 - k), (58, -52), (63, -30),
        (66, -14), (61, -3, 0), (64, 5), (71, 14), (80 + c * 0.3, 25), (79, 30, 0), (70, 31), (67, 33, 0),
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


def draw_eye(cv, T, cx, cy, sx, expr, far, look=3.0, skin=None):
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
    cv.rgb[iris] = (60, 36, 30)
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


def draw_nose(cv, T, tones, expr):
    # nostril wing and the near side of the nose; the tip is part of the face silhouette
    cv.ink(cv.line(T([(53, 20), (51, 26), (55, 31), (62, 31.5)]), 2.0, taper=(0.3, 0.2)))
    cv.ink(cv.line(T([(57, 27), (60, 28.5)]), 1.6, taper=(0.3, 0.3)))
    cv.ink(cv.line(T([(48, 2), (51, 9), (54, 15)]), 1.1, taper=(0.5, 0.6)))
    if expr == "focus":
        cv.ink(cv.line(T([(45, -3), (50, -1)]), 1.0, taper=(0.5, 0.5)))


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
         neck=True):
    """Neck, head, ear and features; returns the head mask."""
    sc = T.scale()
    if neck:
        draw_neck(cv, T, Tn, skin, jaw)
    return draw_head(cv, T, skin, expr, jaw, chin, crown, beard, brow_col, brow_w)


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


def draw_head(cv, T, skin, expr, jaw, chin, crown, beard, brow_col, brow_w=1.0):
    sc = T.scale()
    hp = T(head_outline(jaw, chin, crown))
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
    draw_eye(cv, T, 16, -4, 1.1, expr, far=False)
    draw_eye(cv, T, 55, -4, 0.56, expr, far=True)
    draw_brows(cv, T, expr, brow_col or (30, 20, 24), thick=brow_w)
    draw_nose(cv, T, skin, expr)
    if not beard:
        draw_mouth(cv, T, skin, expr)
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
    # buzz cut: a tight cap of hair, stippled
    hp = T([(-58, -6), (-64, -30), (-53, -62), (-23, -85), (14, -88), (44, -77), (60, -56), (61, -46), (48, -49),
            (26, -56), (6, -52), (-6, -40), (-9, -16), (-13, -13), (-24, -18), (-36, -16), (-48, -6)])
    hm = cv.poly(hp)
    hsh = cv.crescent(hm, 8)
    # the hairline is not inked: a stippled fade into the skin reads as a buzz cut, not a helmet
    fringe = cv.band(hm, 3.5, 1.0, 1.0, dirs=24) & cv.a & ~cv.k
    cv.cel(hm, hair, shadow=hsh, hi=None, ink=0, dots=False)
    st = cv.dots(np.full(hm.shape, 0.5, np.float32), 2.4, 0.6, 15)
    cv.rgb[st & hm & ~hsh] = hair["sh"]
    cv.rgb[st & hm & hsh] = hair["dp"]
    fade = cv.dots(np.full(hm.shape, 0.45, np.float32), 2.4, 0.75, 15)
    cv.rgb[fringe & fade] = hair["sh"]
    hhi = cv.poly(T([(-44, -58), (-20, -80), (10, -84), (-6, -74), (-30, -60)]))
    cv.rgb[hhi & hm & ~st] = hair["lt"]
    cv.k &= ~hm


def mayor(cv, pal, skins, expr):
    skin = C.ramp(skins["tan"])
    green, white, gold = C.ramp(pal["GREEN"]), C.ramp(pal["WHITE"]), C.ramp(pal["GOLD"])
    grey = C.ramp(pal["HAIR_GREY"])
    ang = {"neutral": 0.0, "smug": -7.0}[expr]
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


RIM = {"ud_deuce": (255, 214, 110), "ud_jojo": (255, 214, 110), "ud_tank": (255, 214, 110),
       "ht_boss": (150, 240, 150)}   # back light: gold for your crew, the city crew's color
DRAW = {"ud_deuce": deuce, "ud_jojo": jojo, "ud_tank": tank, "ht_boss": mayor}


def portrait(pid, expr, pal, skins):
    cv = C.Canvas(PW, PH, zoom=ZOOM, anchor=(150, 250))
    DRAW[pid](cv, pal, skins, expr)
    cv.rim(RIM[pid], width=3.0, strength=0.55)
    # bold outer contour round the whole bust
    cv.ink(cv.band(cv.a, 1.6, 0.6, 1.5))
    return cv.image()


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


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    pal, skins, players = load()
    only = sys.argv[1:]
    made = {}
    for pid, exprs in SAMPLE.items():
        for expr, suf in exprs:
            if only and pid not in only:
                continue
            img = portrait(pid, expr, pal, skins)
            q = img.quantize(colors=255, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
            q.save(os.path.join(OUT_DIR, pid + suf + ".png"), optimize=True)
            made[(pid, expr)] = img
            print("wrote", pid + suf + ".png", os.path.getsize(os.path.join(OUT_DIR, pid + suf + ".png")))
    if only:
        row = Image.new("RGBA", (PW * len(made), PH), (40, 34, 66, 255))
        for i, im in enumerate(made.values()):
            row.alpha_composite(im, (i * PW, 0))
        row.save(os.environ.get("ROW_OUT", "/tmp/portrait_row.png"))
        return
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
