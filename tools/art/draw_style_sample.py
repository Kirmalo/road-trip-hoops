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

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_SHEET = os.path.join(ROOT, "docs", "art", "style_sample_v1.png")
OUT_DIR = os.path.join(ROOT, "docs", "art", "style_sample_v1_sprites")

TILT = math.radians(20.0)          # camera looks down this much (3/4 view)
LIGHT = np.array([-0.58, 0.62, 0.53])
LIGHT = LIGHT / np.linalg.norm(LIGHT)  # camera space: x right, y up, z toward viewer
FRAME_W, FRAME_H = 40, 64          # raw sprite frame (character is about 24x40 inside)
GROUND_Y = 59                      # frame row of the floor under the feet
ZOOM = 4                           # sheet enlargement


# ----------------------------------------------------------------------------- math

def vec(*a):
    return np.array(a, dtype=float)


def unit(*a):
    v = np.array(a, dtype=float)
    return v / np.linalg.norm(v)


def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]], dtype=float)


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]], dtype=float)


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]], dtype=float)


# ----------------------------------------------------------------------------- colors

def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def ramp(base, hi=None, sh=None, deep=None):
    """4 tones (highlight, base, shadow, deep) with hue shifting: warm lights, cool shadows."""
    r, g, b = [c / 255.0 for c in hexc(base)]
    h, l, s = colorsys.rgb_to_hls(r, g, b)

    def mk(dl, dh, ds):
        hh = (h + dh) % 1.0
        ll = min(max(l + dl, 0.0), 1.0)
        ss = min(max(s + ds, 0.0), 1.0)
        rr, gg, bb = colorsys.hls_to_rgb(hh, ll, ss)
        return (int(rr * 255 + 0.5), int(gg * 255 + 0.5), int(bb * 255 + 0.5))

    # shift hue toward yellow for lights, toward blue/purple for shadows
    def toward(target, amt):
        d = ((target - h + 0.5) % 1.0) - 0.5
        return max(-amt, min(amt, d))

    out = [
        hexc(hi) if hi else mk(0.15, toward(1 / 6, 0.03), -0.05),
        hexc(base),
        hexc(sh) if sh else mk(-0.14, toward(0.70, 0.035), 0.04),
        hexc(deep) if deep else mk(-0.26, toward(0.72, 0.06), 0.02),
    ]
    return out


def darker(c, f):
    return tuple(int(x * f) for x in c)


OUTLINE_INK = (22, 14, 26)

SKINS = {
    # hand-picked 4-tone skin ramps
    "deep": ["#a86e4c", "#7e4c32", "#573024", "#381c1e"],
    "light": ["#ffd9b6", "#eeb08a", "#c87c64", "#8c4e4c"],
    "brown": ["#d9986a", "#b06f48", "#844c38", "#58302c"],
    "tan": ["#f0c08e", "#cf9564", "#a2684a", "#6c4238"],
}

BLUE = ["#78b8ff", "#2f74e0", "#1f479e", "#172a66"]
NAVY = ["#4a64b0", "#263c84", "#18245a", "#0e1236"]
WHITE = ["#ffffff", "#e4eaf4", "#a9b6d4", "#6c7aa4"]
RED = ["#ff7a6a", "#d8283a", "#951833", "#5a0e2a"]
BLACK = ["#5c5c72", "#34343f", "#1f1e2a", "#121019"]
GREYW = ["#ffffff", "#d8d8e0", "#9a9ab0", "#5e5e78"]

CREW_RING = {"A": (64, 150, 255), "B": (236, 52, 64)}


def pal(lst):
    return [hexc(c) for c in lst]


FLAT = {
    "eye_white": (246, 240, 236),
    "pupil": (24, 16, 22),
    "iris": (70, 42, 30),
    "mouth_in": (66, 16, 26),
    "teeth": (250, 248, 240),
    "tongue": (206, 76, 88),
    "sweat": (170, 220, 255),
    "sweat_hi": (255, 255, 255),
}

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


def player_palette(p):
    d = {
        "skin": pal(SKINS[p["skin"]]),
        "hair": pal(p["hair_pal"]),
        "top": pal(p["top_pal"]),
        "trim": pal(p["trim_pal"]),
        "shorts": pal(p["shorts_pal"]),
        "shorts_trim": pal(p["shorts_trim"]),
        "sock": pal(p["sock_pal"]),
        "shoe": pal(p["shoe_pal"]),
        "shoe_acc": pal(p["shoe_acc"]),
        "sole": pal(p["sole_pal"]),
        "ball": pal(["#ffa860", "#f0761e", "#b84a16", "#702a12"]),
        "seam": pal(["#5a2a14", "#3a1a0e", "#2a120a", "#1a0a06"]),
        "lip": None,
    }
    for k in ("sleeve_pal", "band_pal", "cap_pal", "brim_pal", "tight_pal"):
        if p.get(k):
            d[k[:-4]] = pal(p[k])
    sk = d["skin"]
    d["lip"] = [sk[2], sk[2], sk[3], sk[3]]
    return d


# ----------------------------------------------------------------------------- primitives

class Sphere:
    def __init__(self, c, r, mat, part, t=0.0, clip=None):
        self.c, self.r, self.mat, self.part, self.t, self.clip = np.asarray(c, float), r, mat, part, t, clip


class Ellipsoid:
    def __init__(self, c, axes, mat, part, clip=None):
        # axes: 3x3, columns are the semi-axis vectors in body space
        self.c, self.A, self.mat, self.part, self.t, self.clip = np.asarray(c, float), np.asarray(axes, float), mat, part, 0.0, clip


def ell(c, R, rx, ry, rz, mat, part, clip=None):
    return Ellipsoid(c, R @ np.diag([rx, ry, rz]), mat, part, clip)


class Canvas:
    """Orthographic z-buffer renderer. Body space: x = player's left, y = up, z = facing."""

    def __init__(self, w, h, ox, oy, yaw, scale=1.0):
        self.w, self.h, self.scale = w, h, scale
        self.ox, self.oy = ox, oy
        self.C = rot_x(TILT) @ rot_y(yaw)
        ii, jj = np.meshgrid(np.arange(w), np.arange(h))
        self.X = (ii + 0.5 - ox) / scale
        self.Y = (oy - (jj + 0.5)) / scale
        self.z = np.full((h, w), -1e9)
        self.n = np.zeros((h, w, 3))
        self.pid = np.full((h, w), -1, dtype=int)
        self.prims = []

    def _clip_ok(self, prim, depth):
        if prim.clip is None:
            return np.ones(depth.shape, bool)
        p0, nrm = prim.clip
        cam = np.stack([self.X, self.Y, depth], -1)
        body = cam @ self.C  # row vectors: body = C^T cam
        return ((body - p0) @ nrm) >= 0.0

    def add(self, prim):
        k = len(self.prims)
        self.prims.append(prim)
        c = self.C @ prim.c
        if isinstance(prim, Sphere):
            r = prim.r
            dx, dy = self.X - c[0], self.Y - c[1]
            d2 = dx * dx + dy * dy
            m = d2 < r * r
            dz = np.sqrt(np.maximum(r * r - d2, 0.0))
            depth = c[2] + dz
            n = np.stack([dx / r, dy / r, dz / r], -1)
        else:
            M = self.C @ prim.A
            Mi = np.linalg.inv(M)
            P0 = np.stack([self.X - c[0], self.Y - c[1], np.full(self.X.shape, -c[2])], -1)
            a = P0 @ Mi.T
            b = Mi[:, 2]
            bb = b @ b
            ab = a @ b
            aa = (a * a).sum(-1)
            disc = ab * ab - bb * (aa - 1.0)
            m = disc > 0
            t = (-ab + np.sqrt(np.maximum(disc, 0.0))) / bb
            depth = t
            u = a + t[..., None] * b
            n = u @ Mi
            n = n / np.maximum(np.linalg.norm(n, axis=-1, keepdims=True), 1e-9)
        upd = m & (depth > self.z) & self._clip_ok(prim, depth)
        self.z[upd] = depth[upd]
        self.n[upd] = n[upd]
        self.pid[upd] = k

    def project(self, body_pt):
        c = self.C @ np.asarray(body_pt, float)
        px = self.ox + c[0] * self.scale
        py = self.oy - c[1] * self.scale
        return int(math.floor(px)), int(math.floor(py)), c[2]

    def body_hit(self, j, i):
        cam = np.array([self.X[j, i], self.Y[j, i], self.z[j, i]])
        return self.C.T @ cam


# ----------------------------------------------------------------------------- figure

def ik(a, target, l1, l2, pole):
    """Two-bone IK: returns the elbow/knee position bending toward the pole direction."""
    d_vec = target - a
    d = min(np.linalg.norm(d_vec), l1 + l2 - 0.05)
    u = d_vec / np.linalg.norm(d_vec)
    cos_a = max(-1.0, min(1.0, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)))
    w = pole - (pole @ u) * u
    w = w / max(np.linalg.norm(w), 1e-6)
    return a + l1 * (cos_a * u + math.sqrt(1 - cos_a * cos_a) * w)


def limb(prims, p0, p1, r0, r1, mat, part, bulge=0.0, bulge_at=0.4, step=0.3):
    p0, p1 = np.asarray(p0, float), np.asarray(p1, float)
    n = max(3, int(np.linalg.norm(p1 - p0) / step))
    for k in range(n + 1):
        t = k / n
        r = r0 + (r1 - r0) * t + bulge * max(0.0, 1.0 - abs(t - bulge_at) / 0.45)
        prims.append(Sphere(p0 + (p1 - p0) * t, r, mat, part, t))


DIGITS = {
    0: ["111", "101", "101", "101", "111"], 1: ["010", "110", "010", "010", "111"],
    2: ["111", "001", "111", "100", "111"], 3: ["111", "001", "011", "001", "111"],
    4: ["101", "101", "111", "001", "001"], 5: ["111", "100", "111", "001", "111"],
    6: ["111", "100", "111", "101", "111"], 7: ["111", "001", "010", "010", "010"],
    8: ["111", "101", "111", "101", "111"], 9: ["111", "101", "111", "001", "111"],
}


def number_px(digit, x, y, cx, cy, cell):
    """True if body-space (x, y) falls on a lit cell of the 3x5 digit centred at (cx, cy)."""
    gx = math.floor((x - cx) / cell + 1.5)
    gy = math.floor((cy - y) / cell + 2.5)
    if 0 <= gx < 3 and 0 <= gy < 5:
        # front view is seen from the front, x = player's left = screen right
        return DIGITS[digit][gy][gx] == "1"
    return False


def build(p, pose, expr="focus", portrait=False):
    """Returns (prims, info) for a player in a pose. Units are 1x sprite pixels."""
    W = p["width"]
    mass = p["mass"]
    legk, tk = p["leg"], p["torso"]
    thigh_len, shin_len = 8.6 * legk, 8.3 * legk
    upper_len, fore_len = 6.7 * (0.5 + 0.5 * legk), 6.2 * (0.5 + 0.5 * legk)
    sw = 5.4 * W           # half shoulder width
    hw = 2.3 * W           # half hip width
    ANK = 1.75

    lean = math.radians(pose.get("lean", 4.0))
    twist = math.radians(pose.get("twist", 0.0))
    Rs = rot_y(twist) @ rot_x(lean)

    def S(x, y, z):  # spine-local -> body (relative to pelvis, pelvis added later)
        return Rs @ vec(x, y, z)

    # legs first, relative to pelvis at origin
    legs = {}
    for side, sx in (("L", 1.0), ("R", -1.0)):
        hip = vec(sx * hw, -0.9, 0.0)
        td = unit(*pose["thigh_" + side])
        sd = unit(*pose["shin_" + side])
        knee = hip + td * thigh_len
        ank = knee + sd * shin_len
        legs[side] = (hip, knee, ank)
    lowest = min(legs["L"][2][1], legs["R"][2][1])
    pelvis = vec(0.0, ANK - lowest + pose.get("jump", 0.0), 0.0)

    prims = []
    pp = player_palette(p)

    def skin(*_):
        return "skin"

    # --- torso garment rules (spine-local coordinates q relative to pelvis)
    top = p["top"]
    neck_y = 10.6 * tk
    sh_y = 10.0 * tk

    def torso_mat(h, prim):
        q = Rs.T @ (h - pelvis)
        x, y, z = q
        ax = abs(x)
        num = p["number"]
        if top in ("tank", "hoodie"):
            arm_x = (3.25 if top == "tank" else 3.5) * W
            arm_y = 5.6 * tk
            scoop = (7.9 if top == "tank" else 9.4) * tk + 0.42 * x * x if z > 0 else 9.6 * tk + 0.3 * x * x
            if ax > arm_x and y > arm_y:
                return "skin"
            if y > scoop:
                return "skin"
            if ax > arm_x - 0.55 and y > arm_y - 0.5:
                return "trim"
            if y > scoop - 0.6:
                return "trim"
            if top == "hoodie" and z > 0:
                if 0.4 < ax < 1.3 and 6.4 * tk < y < scoop and int(y * 2) % 2 == 0:
                    return "trim"
                if ax < 2.7 * W and 1.6 < y < 4.0 * tk and (abs(ax - 2.7 * W) < 0.6 or abs(y - 4.0 * tk) < 0.5):
                    return "top+1"
        else:  # tee / longtee
            neck = 9.4 * tk + 0.4 * x * x if z > 0 else 9.9 * tk + 0.3 * x * x
            if y > neck:
                return "skin"
            if y > neck - 0.75:
                return "trim"
            if top == "longtee" and y < -1.2:
                return "trim"
        if top == "hoodie":
            return "top"
        if z > 0.8 and number_px(num, x, y, 0.0, 6.2 * tk, 0.95):
            return "trim" if top != "tee" else "trim"
        if z < -0.8 and number_px(num, -x, y, 0.0, 6.6 * tk, 1.0):
            return "trim"
        return "top"

    def shorts_mat(h, prim):
        q = h - pelvis
        if q[1] > 1.4:
            return "shorts_trim"
        if abs(q[0]) > 3.5 * W and abs(q[2]) < 0.8:
            return "shorts_trim"
        return "shorts"

    loose = 0.35 if top == "longtee" else 0.0
    # pelvis / shorts
    prims.append(ell(pelvis + vec(0, -0.2, 0), np.eye(3), 3.8 * W + mass * 0.5, 2.4, 2.45 + mass * 0.3, shorts_mat, "pelvis"))
    # torso (spine frame)
    tm = torso_mat
    prims.append(ell(pelvis + S(0, 3.4 * tk, 0.15), Rs, 3.5 * W + mass * 0.6 + loose, 3.4 * tk, 2.75 + mass * 0.3 + loose, tm, "torso"))
    prims.append(ell(pelvis + S(0, 7.0 * tk, 0.0), Rs, 4.9 * W + mass * 0.8 + loose, 3.5 * tk, 3.0 + mass * 0.4 + loose, tm, "torso"))
    for sx in (1, -1):  # pecs
        prims.append(ell(pelvis + S(sx * 2.1 * W, 7.4 * tk, 1.7 + mass * 0.3), Rs, 2.4 * W + mass * 0.3, 1.8, 1.5, tm, "torso"))
    # traps
    prims.append(ell(pelvis + S(0, sh_y - 0.35, -0.6), Rs, 4.1 * W + mass * 0.4, 1.65, 1.9, tm, "torso"))
    if top == "hoodie":
        prims.append(ell(pelvis + S(0, neck_y - 0.2, -2.2), Rs @ rot_x(-0.5), 3.3 * W, 1.6, 1.9, "top", "torso"))
    # neck
    limb(prims, pelvis + S(0, sh_y - 0.5, -0.2), pelvis + S(0, neck_y + 2.6, 0.35), 1.6 + mass * 0.3, 1.45 + mass * 0.2, skin, "neck")

    # --- head
    head_c = pelvis + S(0, neck_y + 5.3, 0.55)
    Rh = Rs @ rot_y(math.radians(pose.get("head_yaw", 0.0))) @ rot_x(math.radians(-pose.get("head_up", 0.0)))
    HX, HY, HZ = 3.45, 3.95, 3.6
    HK = 1.14  # head scale: arcade proportions, head about 1/4 of the height
    Rh = Rh * HK
    hair = p["hair"]

    def head_local(h):
        return Rh.T @ (h - head_c) / (HK * HK)

    def hairline(l):
        f = max(-1.0, min(1.0, l[2] / HZ))
        return 1.55 * f + 0.25

    def head_mat(h, prim):
        l = head_local(h)
        x, y, z = l
        if hair == "bald":
            pass
        elif hair == "band":
            if 0.9 < y < 2.0 and y > hairline(l) - 1.2:
                return "band"
            if y > hairline(l) + (0.4 if z > 0 else 0):
                return "hair"
        elif hair in ("twists", "cap"):
            if y > hairline(l):
                return "hair"
        if portrait:
            f = face_features(l, expr, p)
            if f:
                return f
        if p["beard"] and y < -1.25 + 0.15 * abs(x) and z > -0.6:
            if not (abs(x) < 1.0 and -2.35 < y < -1.55 and z > 2.0):
                return "hair"
        if p["beard"] and -1.45 < y < -0.95 and abs(x) < 1.3 and z > 2.2:
            return "hair"
        return "skin"

    prims.append(ell(head_c, Rh, HX, HY, HZ, head_mat, "head"))
    prims.append(ell(head_c + Rh @ vec(0, -1.75, 0.75), Rh, 2.75 + mass * 0.4, 2.2, 2.75, head_mat, "head"))
    prims.append(ell(head_c + Rh @ vec(0, -0.35, 3.45), Rh, 0.55, 0.95, 0.75, head_mat, "head"))  # nose
    for sx in (1, -1):
        prims.append(ell(head_c + Rh @ vec(sx * 3.25, -0.4, -0.2), Rh, 0.55, 1.0, 0.75, skin, "head"))
        # brow ridge / cheekbones give the face some planes
        prims.append(ell(head_c + Rh @ vec(sx * 1.4, 0.75, 2.95), Rh, 1.2, 0.55, 0.75, head_mat, "head"))
    if hair == "twists":
        pl = (head_c + Rh @ vec(0, 0.35, 0), Rh @ unit(0, 1.0, -0.55))
        tw = ell(head_c + Rh @ vec(0, 1.1, -0.35), Rh, HX + 0.35, HY + 0.2, HZ + 0.35, "hair_tw", "hair", clip=pl)
        prims.append(tw)
    if hair == "cap":
        pl = (head_c + Rh @ vec(0, 0.75, 0), Rh @ unit(0, 1.0, -0.3))
        prims.append(ell(head_c + Rh @ vec(0, 0.55, -0.1), Rh, HX + 0.35, HY + 0.15, HZ + 0.35, "cap", "hair", clip=pl))
        prims.append(ell(head_c + Rh @ vec(0, 2.2, -3.5), Rh @ rot_x(-0.45), 2.5, 0.45, 1.9, "brim", "hair"))
        prims.append(Sphere(head_c + Rh @ vec(0, HY + 0.5, -0.1), 0.6, "brim", "hair"))

    # --- arms
    hands = {}
    BR = 3.1  # ball radius
    ball_c = pelvis + S(*pose["ball_at"]) if "ball_at" in pose else None
    for side, sx in (("L", 1.0), ("R", -1.0)):
        sh = pelvis + S(sx * sw * (1 - 0.06 * pose.get("shrug", 0.0)), sh_y - 0.7 + pose.get("shrug", 0.0), -0.3)
        if ("hand_" + side) in pose:
            tgt = pose["hand_" + side]
            T = ball_c + vec(*tgt[1]) if tgt[0] == "ball" else pelvis + S(*tgt)
            wr = T - unit(*(T - sh)) * 0.7
            el = ik(sh, wr, upper_len, fore_len, unit(*pose.get("pole_" + side, (sx, -0.2, -0.3))))
            fd = unit(*(wr - el))
            hands[side] = T
        else:
            ud = unit(*pose["upper_" + side])
            fd = unit(*pose["fore_" + side])
            el = sh + ud * upper_len
            wr = el + fd * fore_len
            hands[side] = wr + fd * 0.7
        sleeve_side = p["sleeve"] == side

        def arm_mat(h, prim, sleeve_side=sleeve_side, part=None):
            t = prim.t
            if top == "tee" and prim.part == "upper" and t < 0.55:
                return "trim" if t > 0.42 else "top"
            if top == "longtee" and prim.part == "upper" and t < 0.95:
                return "trim" if t > 0.8 else "top"
            if top == "longtee" and prim.part == "delt":
                return "top"
            if top == "tee" and prim.part == "delt":
                return "top"
            if sleeve_side and prim.part in ("upper", "fore"):
                if prim.part == "upper" and t < 0.25:
                    return "skin"
                if prim.part == "fore" and t > 0.88:
                    return "skin"
                return "sleeve"
            return "skin"

        r_m = mass * 0.45
        prims.append(Sphere(sh + vec(sx * 0.2, 0.25, 0), 1.95 + r_m, arm_mat, "delt"))
        limb(prims, sh, el, 1.55 + r_m, 1.15 + r_m * 0.6, arm_mat, "upper", bulge=0.32 + r_m * 0.4, bulge_at=0.45)
        limb(prims, el, wr, 1.25 + r_m * 0.6, 0.9 + r_m * 0.3, arm_mat, "fore", bulge=0.25, bulge_at=0.25)
        prims.append(Sphere(hands[side], 1.15 + r_m * 0.3, skin, "hand"))

    # --- legs
    for side, sx in (("L", 1.0), ("R", -1.0)):
        hip, knee, ank = [pelvis + v for v in legs[side]]
        tight = p["tight"] == side
        slen = p["shorts_len"]
        sock = p["sock_len"]

        def leg_mat(h, prim, tight=tight, slen=slen, sock=sock):
            t = prim.t
            if prim.part == "thigh":
                if t < slen:
                    return "shorts_trim" if t > slen - 0.12 else "shorts"
                return "tight" if tight else "skin"
            # calf
            if t < slen - 1.0:
                return "shorts_trim" if t > slen - 1.12 else "shorts"
            if t > 1.0 - sock:
                return "sock"
            return "tight" if tight else "skin"

        r_m = mass * 0.5
        sl = p["shorts_len"]
        # thigh: baggy where the shorts are
        n = max(3, int(np.linalg.norm(knee - hip) / 0.3))
        for k in range(n + 1):
            t = k / n
            r = 2.0 + r_m + (1.45 - 2.0) * t + 0.3 * max(0.0, 1 - abs(t - 0.35) / 0.45)
            if t < sl:
                r += 0.45
            prims.append(Sphere(hip + (knee - hip) * t, r, leg_mat, "thigh", t))
        n = max(3, int(np.linalg.norm(ank - knee) / 0.3))
        for k in range(n + 1):
            t = k / n
            r = 1.35 + r_m * 0.6 + (0.85 - 1.35) * t + 0.4 * max(0.0, 1 - abs(t - 0.28) / 0.4)
            if t < sl - 1.0:
                r = max(r, 1.85 + r_m)
            prims.append(Sphere(knee + (ank - knee) * t, r, leg_mat, "calf", t))
        # sneaker
        fdir = unit(*pose.get("foot_" + side, (sx * 0.12, 0.0, 1.0)))
        up = vec(0, 1, 0)
        lat = np.cross(up, fdir)
        if np.linalg.norm(lat) < 1e-6:
            lat = vec(1, 0, 0)
        lat = lat / np.linalg.norm(lat)
        upv = np.cross(fdir, lat)
        Rf = np.stack([lat, upv, fdir], 1)
        sc = ank + fdir * 1.0 - upv * 0.45

        def shoe_mat(h, prim, sc=sc, Rf=Rf):
            l = Rf.T @ (h - sc)
            if l[1] < -0.55:
                return "sole"
            if l[2] < -1.1 or (l[1] > 0.55 and l[2] > 0.6):
                return "shoe_acc"
            return "shoe"

        prims.append(Ellipsoid(sc, Rf @ np.diag([1.35 + r_m * 0.2, 1.25, 2.35]), shoe_mat, "shoe"))
        prims.append(Sphere(ank + upv * 0.3, 1.15, shoe_mat, "shoe"))

    # --- ball
    if ball_c is not None:
        bc = ball_c
        Rb = rot_z(0.5) @ rot_x(0.6)

        def ball_mat(h, prim, bc=bc, Rb=Rb):
            l = Rb.T @ (h - bc) / BR
            w = 0.13
            if abs(l[0]) < w or abs(l[1]) < w:
                return "seam"
            return "ball"

        prims.append(Sphere(bc, BR, ball_mat, "ball"))

    info = {"head_c": head_c, "Rh": Rh, "HX": HX, "HY": HY, "HZ": HZ, "pelvis": pelvis}
    return prims, info, pp


# ----------------------------------------------------------------------------- portrait face features

def face_features(l, expr, p):
    """Procedural face for close-ups. l = head-local point (x = player's left, y up, z forward)."""
    x, y, z = l
    if z < 1.2:
        return None
    ax = abs(x)
    sx = 1.0 if x > 0 else -1.0
    # brows
    if expr == "focus":
        by = 0.80 + 0.34 * (ax - 0.55)          # low, heavy and angled down toward the nose
        bth = 0.50
    else:
        by = 1.60 + 0.10 * (ax - 0.5) - 0.20 * (ax - 1.5) ** 2   # raised and arched
        bth = 0.40
    if 0.45 < ax < 2.55 and abs(y - by) < bth / 2:
        return "brow"
    ex, ey = 1.42, 0.12
    if expr != "focus":
        # eyes squeezed shut in a shout: two arcs
        u = (ax - ex) / 0.85
        if abs(u) < 1.0 and abs(y - (ey + 0.05 + 0.30 * (1 - u * u))) < 0.17:
            return "lid"
        if abs(u) < 0.8 and ey - 0.32 < y < ey - 0.05 + 0.30 * (1 - u * u) - 0.17:
            return "skin-1"   # cheeks pushed up by the grin
    else:
        ew, eh = 0.82, 0.40
        dx, dy = (ax - ex) / ew, (y - ey) / eh
        if dx * dx + dy * dy < 1.0:
            if dy > 0.30:
                return "lid"           # heavy upper lid: a narrowed, focused look
            ix, iy = (x - sx * (ex - 0.12)), (y - ey + 0.02)
            if ix * ix + iy * iy < 0.09:
                return "pupil"
            if ix * ix + iy * iy < 0.17:
                return "iris"
            return "eye_white"
    # nostrils
    if 0.25 < ax < 0.6 and -1.05 < y < -0.8 and z > 3.0:
        return "skin+2"
    # mouth
    if expr == "focus":
        my = -2.05 + 0.12 * ax * ax
        if ax < 1.05 and abs(y - my) < 0.16:
            return "mouth_line"
        if ax < 0.7 and my - 0.42 < y < my - 0.16:
            return "skin-1"
    else:
        mx, my, mw, mh = 0.0, -2.25, 1.3, 1.0
        dx, dy = ax / mw, (y - my) / mh
        d = dx * dx + dy * dy
        if d < 1.0:
            if dy > 0.42:
                return "teeth"
            if dy < -0.45 and ax < 0.7:
                return "tongue"
            return "mouth_in"
        if d < 1.35 and dy < -0.3:
            return "lip"
    return None


# ----------------------------------------------------------------------------- shading

def shade_level(i):
    if i > 0.66:
        return 0
    if i > 0.26:
        return 1
    if i > -0.16:
        return 2
    return 3


def render(p, pose, yaw, w=FRAME_W, h=FRAME_H, ox=None, oy=GROUND_Y, scale=1.0,
           expr="focus", portrait=False, face_stamp=True, ox_body=0.0):
    prims, info, pp = build(p, pose, expr, portrait)
    if ox is None:
        ox = w / 2.0
    cv = Canvas(w, h, ox, oy, math.radians(yaw), scale)
    for pr in prims:
        cv.add(pr)

    H, Wd = h, w
    mat = np.full((H, Wd), None, dtype=object)
    lvl = np.zeros((H, Wd), dtype=int)
    part = np.full((H, Wd), "", dtype=object)
    opaque = cv.pid >= 0

    # material + light
    for j in range(H):
        for i in range(Wd):
            if not opaque[j, i]:
                continue
            pr = cv.prims[cv.pid[j, i]]
            hb = cv.body_hit(j, i)
            m = pr.mat(hb, pr) if callable(pr.mat) else pr.mat
            off = 0
            if "+" in m:
                m, o = m.split("+")
                off = int(o)
            elif "-" in m:
                m, o = m.split("-")
                off = -int(o)
            if m == "hair_tw":
                m = "hair"
                # twisted texture: small lighter knots
                cell = (math.floor(hb[0] * 1.4 / max(scale, 1) * scale / 1.0) + math.floor(hb[1] * 1.3) * 2 + math.floor(hb[2] * 1.4)) % 3
                off = -1 if cell == 0 else (1 if cell == 1 else 0)
            n = cv.n[j, i]
            inten = float(n @ LIGHT)
            # screen-space cast shadow toward the light
            shadowed = False
            for s in (1.2, 2.2, 3.4, 4.6):
                ss = s / scale * scale  # in pixels
                ii = int(math.floor(i + 0.5 - LIGHT[0] * ss * 1.6))
                jj = int(math.floor(j + 0.5 - LIGHT[1] * ss * 1.6))
                if 0 <= ii < Wd and 0 <= jj < H and cv.pid[jj, ii] >= 0:
                    d_ray = cv.z[j, i] + LIGHT[2] * s * 1.6 / scale
                    if cv.z[jj, ii] > d_ray + 0.9 and cv.prims[cv.pid[jj, ii]].part != pr.part:
                        shadowed = True
                        break
            L = shade_level(inten)
            if shadowed:
                L = max(L, 2) if L < 2 else 3
            # contact creases: a nearby closer part (delt over biceps, pec over abs) darkens a step
            crease = False
            for a, b in ((j - 1, i), (j, i - 1), (j, i + 1), (j - 1, i - 1), (j - 1, i + 1)):
                if 0 <= a < H and 0 <= b < Wd and cv.pid[a, b] >= 0:
                    dz = cv.z[a, b] - cv.z[j, i]
                    if 0.45 * scale < dz < 5.0 * scale and cv.prims[cv.pid[a, b]].part != pr.part:
                        crease = True
            if crease and L < 3:
                L += 1
            mat[j, i] = m
            lvl[j, i] = max(0, min(3, L + off))
            part[j, i] = pr.part

    # cleanup: lone shade pixels take the level of their neighbours
    for _ in range(2):
        for j in range(1, H - 1):
            for i in range(1, Wd - 1):
                if not opaque[j, i] or mat[j, i] in FLAT:
                    continue
                nb = [(j - 1, i), (j + 1, i), (j, i - 1), (j, i + 1)]
                same = [lvl[a, b] for a, b in nb if opaque[a, b] and mat[a, b] == mat[j, i]]
                if len(same) >= 3 and all(s != lvl[j, i] for s in same):
                    vals = sorted(same)
                    lvl[j, i] = vals[len(vals) // 2]

    # colors
    pp = dict(pp)
    pp["mouth_line"] = [darker(pp["skin"][3], 0.75)] * 4
    pp["lid"] = [darker(pp["hair"][3], 1.0)] * 4
    pp["brow"] = [pp["hair"][2], pp["hair"][2], pp["hair"][3], pp["hair"][3]]
    img = Image.new("RGBA", (Wd, H), (0, 0, 0, 0))
    px = img.load()
    col = {}
    for j in range(H):
        for i in range(Wd):
            if not opaque[j, i]:
                continue
            m = mat[j, i]
            if m in FLAT:
                c = FLAT[m]
            else:
                c = pp[m][lvl[j, i]]
            col[(i, j)] = c
            px[i, j] = c + (255,)

    # internal contour lines: where a closer part overlaps a farther one, darken the far pixel
    th = 1.6 / 1.0
    line = np.zeros((H, Wd), bool)
    for j in range(H):
        for i in range(Wd):
            if not opaque[j, i]:
                continue
            for a, b in ((j - 1, i), (j + 1, i), (j, i - 1), (j, i + 1)):
                if 0 <= a < H and 0 <= b < Wd and opaque[a, b]:
                    if cv.z[a, b] > cv.z[j, i] + th * (scale if portrait else 1.0) and part[a, b] != part[j, i]:
                        line[j, i] = True
    for j in range(H):
        for i in range(Wd):
            if line[j, i]:
                m = mat[j, i]
                base = pp[m][3] if m not in FLAT else FLAT[m]
                px[i, j] = darker(base, 0.62) + (255,)

    # sprite faces: placed pixel by pixel
    if face_stamp and not portrait:
        stamp_face(px, cv, info, p, pp, yaw)

    # remove one-pixel spurs so the outline doesn't grow spikes
    for _ in range(2):
        rm = []
        for j in range(H):
            for i in range(Wd):
                if opaque[j, i]:
                    cnt = sum(1 for a, b in ((j - 1, i), (j + 1, i), (j, i - 1), (j, i + 1))
                              if 0 <= a < H and 0 <= b < Wd and opaque[a, b])
                    if cnt <= 1:
                        rm.append((j, i))
        for j, i in rm:
            opaque[j, i] = False
            px[i, j] = (0, 0, 0, 0)

    # exterior outline (4-neighbour), tinted by the material it wraps
    out = img.copy()
    op = out.load()
    for j in range(H):
        for i in range(Wd):
            if opaque[j, i]:
                continue
            nbs = [(i, j - 1), (i, j + 1), (i - 1, j), (i + 1, j)]
            touch = [(a, b) for a, b in nbs if 0 <= a < Wd and 0 <= b < H and opaque[b, a]]
            if touch:
                a, b = touch[0]
                m = mat[b, a]
                deep = FLAT.get(m) if m in FLAT else pp[m][3]
                c = tuple(int(0.45 * d + 0.55 * o) for d, o in zip(deep, OUTLINE_INK))
                op[i, j] = c + (255,)
    return out, cv, info


def stamp_face(px, cv, info, p, pp, yaw):
    hc, Rh = info["head_c"], info["Rh"]
    skin = pp["skin"]
    hair = pp["hair"]
    brow = hair[3] if p["hair"] not in ("bald",) else darker(skin[3], 0.7)
    eye_dark = (26, 16, 24)
    eye_w = (236, 228, 222)

    def vis(local):
        pt = hc + Rh @ np.asarray(local, float)
        i, j, d = cv.project(pt)
        if 0 <= i < cv.w and 0 <= j < cv.h and cv.pid[j, i] >= 0 and cv.prims[cv.pid[j, i]].part == "head":
            if d >= cv.z[j, i] - 1.2:
                return i, j
        return None

    def put(i, j, c):
        if 0 <= i < cv.w and 0 <= j < cv.h and cv.pid[j, i] >= 0 and cv.prims[cv.pid[j, i]].part == "head":
            px[i, j] = c + (255,)

    yaw_n = ((yaw + 180) % 360) - 180
    if abs(yaw_n) > 120:
        return  # back view: no face
    if abs(yaw_n) < 30:
        # front: two eyes with a brow over each, mouth
        for sx in (1, -1):
            e = vis((sx * 1.45, 0.05, 3.2))
            if e:
                i, j = e
                put(i, j, eye_dark)
                put(i, j - 1, brow)
                put(i + sx, j - 1, brow)  # brow extends outward
                put(i + sx, j, eye_w)
        m = vis((0, -2.0, 3.0))
        if m:
            i, j = m
            put(i - 1, j, darker(skin[3], 0.8))
            put(i, j, darker(skin[3], 0.8))
    else:
        # side / 3/4: near eye, brow, mouth at the front of the face
        sx = -1.0 if yaw_n > 0 else 1.0
        e = vis((sx * 1.35, 0.05, 3.0))
        if e:
            i, j = e
            fwd = 1 if yaw_n > 0 else -1
            put(i, j, eye_dark)
            put(i, j - 1, brow)
            put(i - fwd, j - 1, brow)
            put(i - fwd, j, eye_w)
        m = vis((sx * 0.6, -2.0, 3.0))
        if m:
            i, j = m
            put(i, j, darker(skin[3], 0.8))


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
