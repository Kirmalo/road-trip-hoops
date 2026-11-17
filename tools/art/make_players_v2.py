#!/usr/bin/env python3
"""v2 player sheets for Road Trip Hoops (P6-A6; original art, generated; no downloaded or source art).

The owner-approved animation sample v1 (tools/art/make_anim_sample.py, docs/art/anim_sample_v1.md) made into the
full sheet format of docs/BOARD.md ("Player sheet format v2", "Animation table"). The v1 generator
(tools/art/make_players.py) stays as it is; this one imports its part loader and Phase 6 parts and the sample's
leg and dribble code, and renders with tools/art/pixel3d.py.

- Frame 64 x 96 art px, art scale 1.25 (model units -> art px), drawn 2x in the game; the floor point under the
  pelvis is row 88, x 32. Airborne frames keep the feet near the floor row: the game adds the jump height.
- 5 drawn directions, rows S, SE, E, NE, N (yaw 0, 45, 75, 135, 180 as v1); SW, W, NW are mirrors.
- Columns: every animation of ANIMS in order (format.json is the truth), stored in pages of 32 columns
  (<sheet>_p0.png ...; 2048 x 480 px at most).
- The ball is not drawn into the sprite. hands.json stores per body, animation, direction and frame the hand points,
  the ball centre with its layer flag (front 1 = over the sprite, by a z-buffer vote) or null when the ball is free,
  the ball's floor point and height (as the sample's _points.json).
- *_l animations (dribble_l, run_dribble_l, cross_l) are the left-hand versions: the same motion mirrored in the
  body (not the image), so a sleeve or a number stays on its side.
- Owner fixes from G2: the dribbling arm reads against the jersey (pixel3d limb_line: an arm in front of the body
  always gets its contour line) and the running-dribble ball is pushed further to the side, off the legs.

Poses: run, run_dribble and dribble are procedural cycles (the sample's), dunk_two is the sample's dunk; everything
else is a list of key poses ("rigs": pelvis height, foot targets, hand targets, ball, lean...) with Catmull-Rom
in-betweens. Legs are two-bone IK to foot targets on the floor, arms IK to hand targets (clamped to the arm's reach).

Usage:  python3 tools/art/make_players_v2.py [--only ID[,ID...]] [--jobs N] [--frames DIR] [--no-preview]
Output: assets/players2/format.json, hands.json, <id>_p<N>.png, cards/<id>.png;
        docs/art/players_preview_v3.png, docs/art/players_v3_moves.gif
Needs:  Pillow, numpy
"""
import json
import math
import multiprocessing
import os
import sys
import time

import numpy as np
from PIL import Image, ImageDraw

import pixel3d as P
import make_players as M            # load_players() and the Phase 6 parts (it patches pixel3d.build on import)
import make_anim_sample as S        # the approved sample: legs, run and dribble cycles, dunk, ball helpers

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "assets", "players2")
CARD_DIR = os.path.join(OUT_DIR, "cards")
PREVIEW = os.path.join(ROOT, "docs", "art", "players_preview_v3.png")
MOVES_GIF = os.path.join(ROOT, "docs", "art", "players_v3_moves.gif")

SHEETS = ["ud_deuce", "ud_jojo", "ud_tank"]      # this slice (P6-A6); P6-A7 adds the rest
SCALE = S.SCALE                                  # 1.25
FW, FH = S.FW, S.FH                              # 64 x 96
FEET_Y = S.FEET_Y                                # 88
CX = FW // 2
PAGE_COLS = 32
HEAD_PX = 50
DIRS = [("S", 0.0), ("SE", 45.0), ("E", 75.0), ("NE", 135.0), ("N", 180.0)]
ANK = S.ANK
BR = S.BR                                        # ball radius, model units (the game's 11 px ball)
LIMB_LINE = 0.35                                 # pixel3d: arm contour on the body (owner fix 1)


# ----------------------------------------------------------------------------- body numbers

def dims_of(p):
    d = S.body_dims(p)
    legk, tk, W = p["leg"], p["torso"], p["width"]
    d["L"] = d["l1"] + d["l2"]
    d["up"] = 6.7 * (0.5 + 0.5 * legk)
    d["fo"] = 6.2 * (0.5 + 0.5 * legk)
    d["reach"] = d["up"] + d["fo"] + 0.7          # shoulder -> hand centre, arm straight
    d["sh_y"] = 10.0 * tk
    d["tk"] = tk
    return d


def PY(D, f):
    """Pelvis height for a leg extension f (1 = legs straight under the hips)."""
    return ANK + 0.9 + f * D["L"]


def spine_R(lean, twist):
    return P.rot_y(math.radians(twist)) @ P.rot_x(math.radians(lean))


def shoulder(D, r, side):
    sx = 1.0 if side == "L" else -1.0
    shrug = r["shrug"]
    loc = np.array([sx * D["sw"] * (1 - 0.06 * shrug), D["sh_y"] - 0.7 + shrug, -0.3])
    return np.array([r["root"][0], r["py"], r["root"][2]]) + spine_R(r["lean"], r["twist"]) @ loc


def chest(D, r, up=7.0, fwd=3.0):
    loc = np.array([0.0, up * D["tk"], fwd])
    return np.array([r["root"][0], r["py"], r["root"][2]]) + spine_R(r["lean"], r["twist"]) @ loc


# ----------------------------------------------------------------------------- rigs (key poses)
# A key is a dict; missing fields are inherited from the key before (the first key from BASE). Units: model units,
# body space with the floor at y = 0 (x = the player's left, z = facing). Field values:
#   h: leg extension (pelvis height = PY(h)) or py: the pelvis height itself; root: (x, z) pelvis over the floor
#   point; lean, twist, head_up, head_yaw, shrug (degrees / units as pixel3d);
#   fL, fR: (x, y, z, pitch, turn) ankle target (y = ANK is flat on the floor), pitch + = toe up, turn = toe out;
#   hL, hR: ("w", x, y, z) world | ("sh", out, up, fwd) from that side's shoulder (out = away from the body) |
#           ("ball", dx, dy, dz) from the ball | ("chest", x, y, z) from the chest point (spine turned);
#   pL, pR: elbow pole directions; kp: knee pole forward component;
#   ball: None | ("w", x, y, z) | ("hR"/"hL", dx, dy, dz) from that hand | ("mid", dx, dy, dz) between the hands |
#         ("chest", x, y, z).

BASE = {"h": 0.93, "root": (0.0, 0.0), "lean": 4.0, "twist": 0.0, "head_up": 6.0, "head_yaw": 0.0, "shrug": 0.0,
        "fL": None, "fR": None, "hL": ("sh", 1.3, -12.2, 1.2), "hR": ("sh", 1.3, -12.2, 1.2),
        "pL": (1.0, -0.2, -0.3), "pR": (-1.0, -0.2, -0.3), "kp": 1.0, "ball": None}

NUM = ["py", "lean", "twist", "head_up", "head_yaw", "shrug", "kp"]
VEC = ["root3", "fL", "fR", "hL", "hR", "pL", "pR"]


def stance_feet(D, wide=1.0, zL=0.6, zR=-0.4, turn=0.25):
    x = D["hw"] + 1.0 * wide
    return {"fL": (x, ANK, zL, 0.0, turn), "fR": (-x, ANK, zR, 0.0, turn)}


def resolve(D, spec):
    """A key spec -> absolute numbers (world body space)."""
    r = {}
    r["py"] = spec["py"] if "py" in spec else PY(D, spec["h"])
    rt = spec["root"]
    r["root"] = np.array([rt[0], 0.0, rt[1]])
    for k in ("lean", "twist", "head_up", "head_yaw", "shrug", "kp"):
        r[k] = float(spec[k])
    for side in ("L", "R"):
        f = spec["f" + side]
        if f is None:
            f = stance_feet(D)["f" + side]
        r["f" + side] = np.array(f, float)
        r["p" + side] = np.array(spec["p" + side], float)
    hands = {}

    def hand_of(side, ball_pt):
        h = spec["h" + side]
        kind = h[0]
        v = np.array(h[1:], float)
        if kind == "w":
            return v
        if kind == "sh":
            sx = 1.0 if side == "L" else -1.0
            return shoulder(D, r, side) + np.array([sx * v[0], v[1], v[2]])
        if kind == "chest":
            return chest(D, r) + v
        if kind == "ball":
            return ball_pt + v
        raise ValueError(h)

    for side in ("L", "R"):
        if spec["h" + side][0] != "ball":
            hands[side] = hand_of(side, None)
    b = spec["ball"]
    ball = None
    if b is not None:
        kind = b[0]
        v = np.array(b[1:], float)
        if kind == "w":
            ball = v
        elif kind == "chest":
            ball = chest(D, r) + v
        elif kind in ("hR", "hL"):
            ball = hands[kind[1]] + v
        elif kind == "mid":
            ball = (hands["L"] + hands["R"]) / 2.0 + v
        else:
            raise ValueError(b)
    for side in ("L", "R"):
        if spec["h" + side][0] == "ball":
            hands[side] = hand_of(side, ball)
    r["hL"], r["hR"] = hands["L"], hands["R"]
    r["ball"] = ball
    r["grip"] = {s for s in ("L", "R") if spec["h" + s][0] == "ball" or (b is not None and b[0] == "h" + s)}
    return r


def expand(D, keys):
    """[(t, partial spec)] -> [(t, resolved)] with inheritance."""
    out = []
    cur = dict(BASE)
    cur.update(stance_feet(D))
    for t, spec in keys:
        cur = dict(cur)
        if callable(spec):
            spec = spec(cur)
        if "h" in spec:
            cur.pop("py", None)
        cur.update(spec)
        out.append((t, resolve(D, cur)))
    return out


def _flat(r):
    return np.concatenate([[r[k] for k in NUM], r["root"], r["fL"], r["fR"], r["hL"], r["hR"], r["pL"], r["pR"]])


def _unflat(v, like):
    r = {}
    i = 0
    for k in NUM:
        r[k] = float(v[i])
        i += 1
    r["root"] = v[i:i + 3]; i += 3
    r["fL"] = v[i:i + 5]; i += 5
    r["fR"] = v[i:i + 5]; i += 5
    r["hL"] = v[i:i + 3]; i += 3
    r["hR"] = v[i:i + 3]; i += 3
    r["pL"] = v[i:i + 3]; i += 3
    r["pR"] = v[i:i + 3]; i += 3
    r["grip"] = like["grip"]
    return r


def sample(rkeys, t, loop=False):
    """Catmull-Rom through the resolved keys at time t (keys' t ascending; loop: t in [0, 1) and wrap)."""
    n = len(rkeys)
    ts = [k[0] for k in rkeys]
    if loop:
        t = t % 1.0
        for i in range(n):
            a, b = ts[i], ts[(i + 1) % n] + (1.0 if i == n - 1 else 0.0)
            q = t if t >= a else t + 1.0
            if a <= q < b:
                break
        u = (q - a) / (b - a)
        i0, i1, i2, i3 = (i - 1) % n, i, (i + 1) % n, (i + 2) % n
    else:
        if t <= ts[0]:
            return dict(rkeys[0][1])
        if t >= ts[-1]:
            return dict(rkeys[-1][1])
        i = max(j for j in range(n - 1) if ts[j] <= t)
        u = (t - ts[i]) / (ts[i + 1] - ts[i])
        i0, i1, i2, i3 = max(0, i - 1), i, i + 1, min(n - 1, i + 2)
    r1, r2 = rkeys[i1][1], rkeys[i2][1]
    v = S.cr(_flat(rkeys[i0][1]), _flat(r1), _flat(r2), _flat(rkeys[i3][1]), u)
    r = _unflat(v, r1 if u < 0.5 else r2)
    # the ball: interpolated with the keys when both have one, else the nearer key's
    b1, b2 = r1["ball"], r2["ball"]
    if b1 is not None and b2 is not None:
        b0 = rkeys[i0][1]["ball"]
        b3 = rkeys[i3][1]["ball"]
        b0 = b1 if b0 is None else b0
        b3 = b2 if b3 is None else b3
        r["ball"] = S.cr(b0, b1, b2, b3, u)
    else:
        r["ball"] = b1 if u < 0.5 else b2
        if r["ball"] is not None:      # stays in the hands it was in
            src = r1 if u < 0.5 else r2
            gs = sorted(src["grip"])
            if gs:
                off = src["ball"] - sum(src["h" + s] for s in gs) / len(gs)
                r["ball"] = sum(r["h" + s] for s in gs) / len(gs) + off
    return r


def clamp_hands(D, r):
    """Pull hand targets in to the arm's reach (pixel3d would stretch the forearm); a gripped ball moves along."""
    shift = []
    for side in ("L", "R"):
        sh = shoulder(D, r, side)
        v = r["h" + side] - sh
        d = np.linalg.norm(v)
        m = D["reach"] - 0.25
        if d > m:
            nh = sh + v * (m / d)
            if side in r["grip"]:
                shift.append(nh - r["h" + side])
            r["h" + side] = nh
    if shift and r["ball"] is not None:
        r["ball"] = r["ball"] + sum(shift) / len(shift)


def rig_pose(D, r):
    """Resolved rig -> (pixel3d pose, ball) in root-relative coordinates (as make_anim_sample.render wants)."""
    clamp_hands(D, r)
    p = {k: r[k] for k in ("lean", "twist", "head_up", "head_yaw", "shrug")}
    root = np.array([r["root"][0], 0.0, r["root"][2]])
    feet = {}
    for side, sx in (("L", 1.0), ("R", -1.0)):
        f = r["f" + side]
        feet[side] = ((f[0] - root[0], f[1], f[2] - root[2]), (sx * f[4], f[3], 1.0))
    S.set_legs(p, D, r["py"], feet, pole_fwd=r["kp"])
    for side in ("L", "R"):
        S.set_hand(p, side, r["h" + side] - root, r["py"], tuple(P.unit(*r["p" + side])))
    p["_root"] = root
    ball = None if r["ball"] is None else np.asarray(r["ball"], float) - root
    return p, ball


# ----------------------------------------------------------------------------- mirroring (the *_l animations)

def mirror_pose(p, ball):
    q = {}
    for k, v in p.items():
        if k in ("twist", "head_yaw"):
            q[k] = -v
        elif k == "_root":
            q[k] = np.array([-v[0], v[1], v[2]])
        elif k[-2:] in ("_L", "_R"):
            base, side = k[:-2], k[-1]
            k2 = base + "_" + ("R" if side == "L" else "L")
            if base == "reach":
                dv, fr = v
                q[k2] = ((-dv[0], dv[1], dv[2]), fr)
            else:
                q[k2] = (-v[0], v[1], v[2])
        else:
            q[k] = v
    b = None if ball is None else np.array([-ball[0], ball[1], ball[2]])
    return q, b


# ----------------------------------------------------------------------------- procedural cycles (sample v1)

def run_fn(k, D, n):
    return S.run_pose(k, D, n)


def dribble_fn(k, D, n):
    """The sample's standing dribble with the hand a little further out from the hip (fix 1: the arm reads)."""
    p, ball = S.dribble_pose(k, D, n)
    return p, ball


def run_dribble_fn(k, D, n=10):
    """The sample's running dribble (right hand), with the ball pushed out to the side (owner fix 2): the hand works
    further out from the hip and the ball lands beside the right foot's line instead of in front of the legs."""
    ph = k / n
    p = {"lean": 15.0, "head_up": 16.0}
    pelvis_y = S.run_legs(p, D, ph + 0.92, stride=0.92, sink=0.3)
    s = math.cos(2 * math.pi * (ph + 0.92 - 0.45))
    a = 6.0 + 36.0 * s
    S.arm_swing(p, "L", a, 70.0 + 26.0 * max(0.0, s), out=0.3)
    p["twist"] = -6.0 * s - 8.0
    p["head_yaw"] = 6.0 * s + 8.0
    hx = -(D["sw"] + 6.3)
    hand_keys = [(0.00, hx, 20.6, 4.6),
                 (0.10, hx - 0.2, 18.6, 6.2),
                 (0.20, hx - 0.6, 16.6, 7.4),
                 (0.32, hx - 0.8, 15.6, 7.2),
                 (0.50, hx - 0.4, 18.0, 5.6),
                 (0.70, hx, 20.6, 4.4),
                 (0.86, hx, 20.4, 4.6)]
    hand = S.periodic_spline(hand_keys, ph)
    under = np.array([0.0, -(BR + 1.5), 0.6])
    rel, floor_ph, catch_ph = 0.17, 0.40, 0.90
    fl = np.array([hx - 2.6, BR, 7.0])
    if ph < rel or ph >= catch_ph:
        ball = hand + under
    else:
        b0 = S.periodic_spline(hand_keys, rel) + under
        b1 = S.periodic_spline(hand_keys, catch_ph) + under
        ball = S.ball_free(ph, rel, floor_ph, catch_ph, b0, fl, b1)
    S.set_hand(p, "R", hand, pelvis_y, (-1, -0.3, -0.7))
    return p, ball


def dunk_two_fn(k, D, n=10):
    return S.dunk_pose(k, D)


def slide_fn(k, D, n=8):
    """Defensive slide toward the player's left (+x), one step per cycle: the left foot reaches out, the right foot
    slides in after it; planted feet move back at the slide speed so they don't skate. Played backwards = to his
    right."""
    ph = k / n
    hw = D["hw"]
    step = 0.50 * D["L"]
    A = hw + 9.0               # the lead (left) foot touches down here (x, the pelvis at 0) at ph 0.35
    B = -(hw + 2.4)            # the trail (right) foot touches down here at ph 0.85

    def planted_or_swing(ph, down, up_len, x_down, lift):
        # foot touches down at `down`, is planted for 1 - up_len of the cycle, then swings for up_len
        u = (ph - down) % 1.0
        if u < 1.0 - up_len:
            return x_down - step * u, ANK
        s = (u - (1.0 - up_len)) / up_len
        s2 = s * s * (3 - 2 * s)
        x0 = x_down - step * (1.0 - up_len)
        return x0 + (x_down - x0) * s2, ANK + lift * math.sin(math.pi * s)

    xl, yl = planted_or_swing(ph, 0.35, 0.35, A, 1.6)
    xr, yr = planted_or_swing(ph, 0.85, 0.35, B, 0.7)
    p = {"lean": 24.0, "head_up": 24.0, "twist": 0.0, "head_yaw": 0.0}
    feet = {"L": ((xl, yl, 0.8), (0.35, 0.0, 1.0)), "R": ((xr, yr, -0.8), (-0.35, 0.0, 1.0))}
    py = PY(D, 0.64) - 0.45 * math.cos(4 * math.pi * (ph - 0.1))
    S.set_legs(p, D, py, feet, pole_fwd=0.7)
    # arms wide and active: the lead (left) hand up and out, the trail hand low and wide
    p["reach_L"] = ((0.80, 0.25 + 0.06 * math.sin(2 * math.pi * ph), 0.55), 0.92)
    p["reach_R"] = ((-0.85, -0.35, 0.40), 0.90)
    p["pole_L"], p["pole_R"] = (0.6, -1, -0.2), (-0.6, -1, -0.2)
    return p, None


# ----------------------------------------------------------------------------- key-pose animations

def K(*parts, **kw):
    """A key: the dicts merged, then the keywords."""
    out = {}
    for d in parts:
        out.update(d)
    out.update(kw)
    return out


def two(ball_back=0.5, spread=None, up=0.3):
    s = (BR + 0.5) if spread is None else spread
    return {"hL": ("ball", s, up, -ball_back), "hR": ("ball", -s, up, -ball_back)}


def F(x, z, y=ANK, pitch=0.0, turn=0.2):
    return (x, y, z, pitch, turn)


def k_idle(D):
    hw = D["hw"]
    fe = {"fL": F(hw + 1.2, 0.8, turn=0.3), "fR": F(-hw - 1.2, -0.6, turn=0.3)}
    return [(0.0, K(fe, h=0.93, lean=4, twist=-4, head_up=6, head_yaw=-2, shrug=0.0, root=(0.0, 0.0),
                       hL=("sh", 1.2, -12.3, 1.0), hR=("sh", 1.4, -12.2, 1.4))),
            (0.5, K(h=0.905, lean=6, twist=-2, head_up=8, head_yaw=3, shrug=0.5, root=(0.35, 0.1),
                       hL=("sh", 1.5, -12.0, 1.6), hR=("sh", 1.6, -12.0, 1.8)))]


def k_hold(D):
    hw = D["hw"]
    fe = {"fL": F(hw + 2.4, 3.0, turn=0.25), "fR": F(-hw - 2.4, -2.4, turn=0.35)}
    b = ("chest", -3.2, -6.5, 4.0)
    return [(0.0, K(fe, two(0.3), h=0.82, lean=16, twist=-14, head_up=16, head_yaw=12, ball=b,
                       pL=(1, -0.6, -0.4), pR=(-1, -0.6, -0.6))),
            (0.5, K(h=0.80, lean=18, twist=-16, head_yaw=14, ball=("chest", -3.6, -6.8, 4.2), shrug=0.3))]


def k_catch(D):
    hw = D["hw"]
    fe = {"fL": F(hw + 1.8, 2.6, turn=0.25), "fR": F(-hw - 1.8, -1.6, turn=0.3)}
    return [(0.0, K(fe, two(0.6, BR + 0.7), h=0.86, lean=10, head_up=12, ball=("chest", 0.0, 0.5, 11.5),
                       pL=(1, -0.5, -0.2), pR=(-1, -0.5, -0.2))),
            (1.0, K(two(0.5), h=0.80, lean=14, ball=("chest", 0.0, -0.5, 8.0))),
            (2.0, K(two(0.4), h=0.79, lean=15, twist=-6, ball=("chest", -1.5, -2.5, 5.0),
                       pL=(1, -0.7, -0.5), pR=(-1, -0.7, -0.5))),
            (3.0, K(two(0.3), h=0.81, lean=16, twist=-10, head_yaw=6, ball=("chest", -2.6, -5.5, 4.2)))]


def k_cross(D, n=8):
    """Crossover, right hand to left: low push across the front, the ball hits the floor in the middle, the left
    hand takes it; the hips swing from the right foot onto a hard plant of the left."""
    hw, sw = D["hw"], D["sw"]
    xr = -(sw + 4.2)
    xl = sw + 4.2
    top = ("hR", 0.0, -(BR + 1.5), 0.6)
    topl = ("hL", 0.0, -(BR + 1.5), 0.6)
    fe = {"fL": F(hw + 3.0, 4.0, turn=0.35), "fR": F(-hw - 3.4, -3.4, turn=0.35)}
    guardL = ("chest", 5.5, -1.0, 7.0)
    return [
        (0.0, K(fe, h=0.80, lean=24, twist=-14, head_up=22, head_yaw=10, root=(-1.2, 0.2),
                   hR=("w", xr, 18.6, 5.0), hL=guardL, ball=top, pR=(-1, -0.4, -0.6), pL=(1, -0.7, -0.3))),
        (1.0, K(h=0.78, twist=-10, root=(-1.6, 0.3), hR=("w", xr + 2.0, 15.8, 7.2), ball=top)),
        (2.0, K(h=0.75, twist=-2, root=(-0.4, 0.5), hR=("w", xr + 6.0, 13.6, 8.6),
                   hL=("w", xl - 1.0, 15.0, 7.4), ball=top, head_yaw=4)),
        (3.0, K(h=0.73, twist=6, root=(0.4, 0.6), hR=("w", -4.0, 14.0, 8.0),
                   hL=("w", xl, 14.6, 6.8), ball=("w", 0.0, BR + 0.4, 9.4), head_yaw=-2,
                   fL=F(hw + 4.2, 4.6, turn=0.5))),
        (4.0, K(h=0.72, twist=12, root=(1.6, 0.6), hR=("chest", -6.0, -1.0, 6.0),
                   hL=("w", xl, 15.4, 6.2), ball=topl, lean=26, pL=(1, -0.4, -0.6))),
        (5.0, K(h=0.74, twist=15, root=(1.9, 0.5), hL=("w", xl, 18.0, 5.4), ball=topl, head_yaw=-8)),
        (6.0, K(h=0.77, twist=14, root=(1.6, 0.4), hL=("w", xl, 16.2, 6.6), ball=topl)),
        (7.0, K(h=0.80, twist=12, root=(1.1, 0.3), hL=("w", xl + 0.3, 14.8, 7.0), ball=topl, lean=24,
                   hR=("chest", -5.5, -1.0, 7.0), head_yaw=-10)),
    ]


def k_shoot(D):
    """Jump shot off the left hand (the far hand facing E, so the face stays visible, as v1): 0-3 gather (dip, ball
    to the set point), 4-5 rise, 6 release, 7-9 follow-through and land. Feet leave the floor 4-8 (the game adds the
    jump)."""
    hw = D["hw"]
    fe = {"fL": F(hw + 1.6, 1.6, turn=0.2), "fR": F(-hw - 1.6, -0.4, turn=0.25)}
    air = lambda u, t=0.8: {"fL": F(hw + 1.2, 0.8, ANK + u, -t, 0.15), "fR": F(-hw - 1.2, -0.6, ANK + u * 0.8, -t, 0.2)}
    shot = lambda bx, by, bz: {"ball": ("chest", bx, by, bz), "hL": ("ball", 0.3, -(BR + 0.2), -1.6),
                               "hR": ("ball", -(BR + 0.4), 0.0, 0.2)}
    return [
        (0.0, K(fe, shot(0.4, -4.5, 6.0), h=0.86, lean=10, head_up=12, pL=(1, -0.8, -0.3), pR=(-1, -0.8, -0.3))),
        (1.0, K(shot(0.4, -5.5, 6.4), h=0.76, lean=16, head_up=16)),
        (2.0, K(shot(0.8, 2.0, 5.0), h=0.80, lean=10, head_up=16, pL=(1, -1, 0.0))),
        (3.0, K(shot(1.4, 11.5, 2.6), h=0.90, lean=4, head_up=18, shrug=0.6, pL=(0.6, -1, 0.0),
                   pR=(-1, -0.6, 0.2))),
        (4.0, K(air(1.0, 0.6), shot(1.4, 13.5, 2.4), h=0.97, lean=0, head_up=20, shrug=1.0)),
        (5.0, K(air(2.0, 0.9), shot(1.2, 15.0, 3.0), lean=-2, head_up=20, shrug=1.4)),
        (6.0, K(air(2.4, 1.0), h=0.97, lean=-2, head_up=20, shrug=1.8, ball=("chest", 1.0, 19.2, 7.2),
                   hL=("ball", 0.2, -(BR + 0.6), -2.0), hR=("sh", 3.0, 7.0, 7.0), pL=(0.4, -1, 0.2))),
        (7.0, K(air(2.0, 0.9), ball=None, hL=("sh", 0.0, 12.6, 6.0), hR=("sh", 2.5, 5.0, 6.0), shrug=1.6)),
        (8.0, K(air(0.8, 0.5), h=0.92, lean=2, hL=("sh", 0.3, 11.5, 7.0), hR=("sh", 3.0, -2.0, 6.0), shrug=1.0)),
        (9.0, K(fe, h=0.84, lean=8, head_up=14, shrug=0.4, hL=("sh", 1.5, -6.0, 7.0), hR=("sh", 2.0, -9.0, 4.0),
                   pL=(1, -0.6, -0.3), pR=(-1, -0.4, -0.4))),
    ]


def jump_feet(D, kneeL, kneeR, toe=0.8, zl=0.0, zr=0.0, ul=0.0, ur=0.0):
    """Feet tucked under in the air (kneeX: how high the ankle is lifted, model units)."""
    hw = D["hw"]
    return {"fL": F(hw * 0.9, zl, ANK + kneeL + ul, -toe, 0.1), "fR": F(-hw * 0.9, zr, ANK + kneeR + ur, -toe, 0.1)}


def approach(D, carry):
    """Shared start of layups and dunks: 0 long gather step, 1 plant and load (ball in both hands)."""
    hw, L = D["hw"], D["L"]
    return [
        (0.0, K(carry(0), fL=F(hw + 0.3, 0.30 * L), fR=F(-hw - 0.3, -0.30 * L, ANK + 1.2, -0.7, 0.1),
                   h=0.80, lean=18, head_up=18, twist=-10, pL=(1, -0.5, -0.3), pR=(-1, -0.5, -0.3))),
        (1.0, K(carry(1), fL=F(hw + 0.9, 2.6), fR=F(-hw - 0.9, -1.4), h=0.64, lean=30, head_up=28, twist=-4,
                   pL=(1, 0.2, -0.6), pR=(-1, 0.2, -0.6))),
    ]


def carry_hip(i):
    return K(two(0.2), ball=("chest", -3.4, -6.0, 4.6) if i == 0 else ("chest", -0.6, -8.0, 6.0))


def k_layup(D):
    """Right-hand layup: gather, plant on the left foot, the right knee drives up, the ball rises on the right
    hand to full reach, finger roll at 5 (release), hands up, land and settle."""
    hw, L = D["hw"], D["L"]
    keys = approach(D, carry_hip)
    keys += [
        (2.0, K(fL=F(hw * 0.8, -0.18 * L, ANK + 1.2, -1.0, 0.1), fR=F(-hw, 0.34 * L, PY(D, 0.92) - 0.9 - 0.32 * L,
                   -0.5, 0.1), h=0.93, lean=8, head_up=24, twist=-6, ball=("chest", -2.8, 2.0, 6.0),
                   hL=("ball", BR + 0.4, 0.4, -0.4), hR=("ball", -0.6, -(BR + 0.6), -0.8), pL=(1, -0.6, -0.2))),
        (3.0, K(fL=F(hw * 0.9, -0.12 * L, ANK + 2.6, -1.0, 0.1), fR=F(-hw, 0.30 * L, PY(D, 0.92) - 0.9 - 0.36 * L,
                   -0.6, 0.1), lean=2, head_up=28, shrug=1.0, ball=("chest", -3.4, 12.0, 6.6),
                   hR=("ball", -0.4, -(BR + 0.6), -1.4), hL=("ball", BR + 0.6, 0.0, -0.6), pR=(-1, -0.6, 0.2))),
        (4.0, K(fL=F(hw * 0.9, -0.08 * L, ANK + 3.2, -1.0, 0.1), fR=F(-hw, 0.24 * L, ANK + 6.0, -0.7, 0.1),
                   lean=-2, head_up=28, shrug=1.6, ball=("w", -3.6, PY(D, 0.92) + 26.0, 7.0),
                   hR=("ball", -0.2, -(BR + 0.8), -1.2), hL=("sh", 4.0, 2.0, 5.0), pL=(1, -1, 0.0))),
        (5.0, K(lean=-3, shrug=1.8, ball=("w", -3.2, PY(D, 0.92) + 28.4, 9.6),
                   hR=("ball", -0.2, -(BR + 0.4), -2.2), hL=("sh", 4.4, 0.0, 4.0))),
        (6.0, K(ball=None, hR=("sh", 1.0, 12.8, 3.0), hL=("sh", 4.0, -1.0, 4.0), fR=F(-hw, 0.18 * L, ANK + 4.4,
                   -0.8, 0.1), head_up=26)),
        (7.0, K(fL=F(hw * 0.9, 0.0, ANK + 1.2, -0.7, 0.1), fR=F(-hw, 0.10 * L, ANK + 2.0, -0.6, 0.1), lean=4,
                   shrug=1.0, hR=("sh", 1.5, 7.0, 6.0), hL=("sh", 3.5, -4.0, 4.0), head_up=20)),
        (8.0, K(fL=F(hw + 1.4, 1.6), fR=F(-hw - 1.4, -0.4), h=0.70, lean=18, head_up=18, shrug=0.0,
                   hR=("sh", 3.0, -6.0, 6.0), hL=("sh", 3.0, -7.0, 5.0), pL=(1, 0.3, -0.6), pR=(-1, 0.3, -0.6))),
        (9.0, K(h=0.86, lean=8, head_up=10, hR=("sh", 1.5, -11.0, 2.5), hL=("sh", 1.5, -11.0, 2.5),
                   pL=(1, -0.2, -0.3), pR=(-1, -0.2, -0.3))),
    ]
    return keys


def rim_pt(D, up=24.5, fwd=8.0):
    return np.array([0.0, PY(D, 0.86) + up, fwd])


def k_dunk_one(D):
    """One-hand dunk (right hand): gather, load, takeoff with the ball going to the right hand, rise palming it, the
    arm reaching over the rim (top, a short hang), the slam with the wrist snapped, the right hand on the rim,
    land."""
    hw, L = D["hw"], D["L"]
    keys = approach(D, carry_hip)
    top = PY(D, 0.92)
    keys += [
        (2.0, K(fL=F(hw * 0.8, -0.22 * L, ANK + 1.4, -1.0, 0.1), fR=F(-hw, 0.36 * L, top - 0.9 - 0.30 * L, -0.5, 0.1),
                   h=0.93, lean=6, head_up=22, twist=-8, ball=("chest", -2.4, 6.0, 7.0),
                   hR=("ball", -0.8, -(BR + 0.4), -1.2), hL=("ball", BR + 0.5, 0.3, -0.6), pR=(-1, -0.7, -0.2))),
        (3.0, K(fL=F(hw * 0.9, -0.10 * L, ANK + 2.6, -0.9, 0.1), fR=F(-hw * 0.9, 0.14 * L, ANK + 5.0, -0.7, 0.1),
                   h=0.86, lean=-2, head_up=24, shrug=1.4, twist=-6, ball=("w", -3.2, top + 27.0, 4.0),
                   hR=("ball", 0.0, -(BR + 0.6), -1.4), hL=("sh", 4.5, 3.0, 4.0), pL=(1, -1, 0.0), pR=(-1, -0.5, 0.2))),
        (4.0, K(fL=F(hw * 0.9, -0.16 * L, ANK + 3.6, -0.9, 0.1), fR=F(-hw * 0.9, 0.04 * L, ANK + 5.4, -0.8, 0.1),
                   lean=-6, head_up=24, shrug=1.8, ball=("w", -3.0, top + 28.0, 2.0),
                   hR=("ball", 0.0, -(BR + 0.6), -1.8), hL=("sh", 5.0, 4.0, 2.0))),
        (5.0, K(lean=-8, head_up=24, ball=("w", -3.0, top + 28.4, 4.0), fL=F(hw * 0.9, -0.18 * L, ANK + 4.2, -1.0, 0.1))),
        (6.0, K(lean=14, head_up=12, shrug=1.0, ball=("w", -2.6, top + 20.5, 11.0),
                   hR=("ball", 0.0, BR + 0.4, -1.6), hL=("sh", 5.0, -2.0, 3.0),
                   fL=F(hw * 0.9, 0.18 * L, ANK + 3.2, -0.7, 0.1), fR=F(-hw * 0.9, 0.06 * L, ANK + 1.8, -0.8, 0.1))),
        (7.0, K(lean=6, head_up=18, shrug=1.6, ball=None, hR=("w", -2.6, PY(D, 0.86) + 24.5, 8.0),
                   hL=("sh", 5.0, -4.0, 2.0), fL=F(hw * 0.9, 0.10 * L, ANK + 2.4, -0.8, 0.1),
                   fR=F(-hw * 0.9, 0.0, ANK + 1.2, -0.9, 0.1))),
        (8.0, K(fL=F(hw + 1.4, 2.0), fR=F(-hw - 1.4, -0.6), h=0.66, lean=20, head_up=20, shrug=0.0,
                   hR=("sh", 3.5, -6.0, 6.0), hL=("sh", 3.5, -6.0, 6.0), pL=(1, 0.3, -0.6), pR=(-1, 0.3, -0.6))),
    ]
    return keys


def k_tomahawk(D):
    """Tomahawk (right hand): the ball cocked far back behind the head with the back arched and the heels kicked up,
    then hammered down over the rim."""
    hw, L = D["hw"], D["L"]
    keys = approach(D, carry_hip)
    top = PY(D, 0.86)
    keys += [
        (2.0, K(fL=F(hw * 0.8, -0.22 * L, ANK + 1.4, -1.0, 0.1), fR=F(-hw, 0.36 * L, PY(D, 0.93) - 0.9 - 0.30 * L,
                   -0.5, 0.1), h=0.93, lean=6, head_up=22, twist=-6, ball=("chest", -1.0, 9.0, 6.0),
                   **two(0.5), pL=(1, -0.7, -0.2), pR=(-1, -0.7, -0.2))),
        (3.0, K(fL=F(hw * 0.9, -0.08 * L, ANK + 1.0, -0.9, 0.1), fR=F(-hw * 0.9, 0.12 * L, ANK + 3.6, -0.6, 0.1),
                   h=0.84, lean=-2, head_up=22, shrug=1.4, twist=-4, ball=("w", -1.5, top + 29.0, 1.0), **two(0.3))),
        (4.0, K(fL=F(hw * 0.9, -0.26 * L, ANK + 4.6, -0.9, 0.1), fR=F(-hw * 0.9, -0.18 * L, ANK + 6.4, -0.8, 0.1),
                   h=0.80, lean=-14, head_up=26, shrug=1.8, twist=-10, ball=("w", -3.2, top + 23.0, -7.6),
                   hR=("ball", 0.0, -0.4, BR + 0.6), hL=("sh", 3.5, 6.0, 6.0), pR=(-1, 0.6, 0.6), pL=(1, -1, 0.2))),
        (5.0, K(lean=-16, head_up=26, ball=("w", -3.4, top + 22.0, -8.6),
                   fL=F(hw * 0.9, -0.28 * L, ANK + 5.4, -1.0, 0.1), fR=F(-hw * 0.9, -0.20 * L, ANK + 7.0, -0.9, 0.1))),
        (6.0, K(lean=-2, head_up=20, twist=-4, ball=("w", -2.8, top + 29.0, 3.0),
                   hR=("ball", 0.0, -0.4, -(BR + 0.6)), hL=("sh", 4.0, 2.0, 5.0), pR=(-1, -0.4, 0.4),
                   fL=F(hw * 0.9, -0.06 * L, ANK + 4.0, -0.9, 0.1), fR=F(-hw * 0.9, 0.04 * L, ANK + 5.4, -0.8, 0.1))),
        (7.0, K(lean=18, head_up=10, shrug=1.0, ball=("w", -2.0, top + 19.0, 11.4),
                   hR=("ball", 0.0, BR + 0.4, -1.4), hL=("sh", 5.0, -3.0, 2.0), pR=(-1, -0.5, -0.2),
                   fL=F(hw * 0.9, 0.20 * L, ANK + 3.4, -0.7, 0.1), fR=F(-hw * 0.9, 0.08 * L, ANK + 2.0, -0.8, 0.1))),
        (8.0, K(lean=8, head_up=18, shrug=1.6, ball=None, hR=("w", -2.6, top + 24.5, 8.0),
                   hL=("sh", 5.0, -4.0, 2.0), fL=F(hw * 0.9, 0.06 * L, ANK + 1.8, -0.8, 0.1),
                   fR=F(-hw * 0.9, -0.02 * L, ANK + 0.8, -0.9, 0.1))),
        (9.0, K(fL=F(hw + 1.4, 2.0), fR=F(-hw - 1.4, -0.6), h=0.66, lean=20, head_up=20, shrug=0.0,
                   hR=("sh", 3.5, -6.0, 6.0), hL=("sh", 3.5, -6.0, 6.0), pL=(1, 0.3, -0.6), pR=(-1, 0.3, -0.6))),
    ]
    return keys


def k_windmill(D):
    """Windmill (right hand): after the takeoff the ball swings down past the hip, back, up behind and over the top
    in one big circle with a straight arm, then the slam."""
    hw, L = D["hw"], D["L"]
    keys = approach(D, carry_hip)
    top = PY(D, 0.86)
    r = D["reach"] - 0.4

    def arm_at(deg, py_f=0.86, lean=0.0):
        # straight right arm at angle deg in the side plane: 0 = down, 90 = straight back, 180 = up, 270 = forward
        a = math.radians(deg)
        rr = {"py": PY(D, py_f), "root": (0, 0, 0), "lean": lean, "twist": -6.0, "shrug": 1.0}
        rr["root"] = np.zeros(3)
        sh = shoulder(D, rr, "R")
        return sh + r * np.array([-0.18, -math.cos(a), -math.sin(a)])

    def mill(deg, **kw):
        h = arm_at(deg, lean=kw.get("lean", 0.0))
        hand = ("w", float(h[0]), float(h[1]), float(h[2]))
        a = math.radians(deg)
        out = -np.array([-0.0, -math.cos(a), -math.sin(a)])   # the ball sits on the outside of the circle
        d = K(hR=hand, ball=("hR", -0.3, -(BR + 0.8) * math.cos(a), -(BR + 0.8) * math.sin(a)),
                 h=0.86, twist=-6, shrug=1.0)
        d.update(kw)
        return d
    tuck = lambda a, b, za=0.0, zb=0.0: {"fL": F(hw * 0.9, za, ANK + a, -0.9, 0.1), "fR": F(-hw * 0.9, zb, ANK + b, -0.8, 0.1)}
    keys += [
        (2.0, K(fL=F(hw * 0.8, -0.22 * L, ANK + 1.4, -1.0, 0.1), fR=F(-hw, 0.36 * L, PY(D, 0.93) - 0.9 - 0.30 * L,
                   -0.5, 0.1), h=0.93, lean=6, head_up=22, twist=-6, ball=("chest", -1.5, 4.0, 7.0),
                   **two(0.5), pL=(1, -0.7, -0.2), pR=(-1, -0.7, -0.2))),
        (3.0, K(mill(330, lean=2), **tuck(1.6, 4.0, -0.1 * L, 0.14 * L), hL=("sh", 4.0, 2.0, 6.0), head_up=22,
                   pR=(-1, -0.2, 0.6), pL=(1, -1, 0.0))),
        (4.0, K(mill(15, lean=4), **tuck(2.6, 5.0, -0.12 * L, 0.10 * L), hL=("sh", 4.5, 4.0, 5.0))),
        (5.0, K(mill(70, lean=2), **tuck(3.4, 5.6, -0.16 * L, 0.04 * L), pR=(-1, -0.2, 0.2))),
        (6.0, K(mill(125, lean=-4), **tuck(4.0, 6.0, -0.2 * L, -0.06 * L), shrug=1.6, pR=(-1, 0.2, 0.0))),
        (7.0, K(mill(175, lean=-8), **tuck(4.6, 6.2, -0.24 * L, -0.10 * L), shrug=1.8, head_up=26,
                   hL=("sh", 5.0, 5.0, 3.0))),
        (8.0, K(mill(212, lean=-6), **tuck(4.6, 6.2, -0.24 * L, -0.10 * L), shrug=1.8, head_up=24)),
        (9.0, K(mill(250, lean=4), **tuck(3.6, 4.4, -0.02 * L, 0.04 * L), shrug=1.4, head_up=18, pR=(-1, -0.6, 0.0))),
        (10.0, K(lean=16, head_up=12, shrug=1.0, ball=("w", -2.4, top + 19.0, 11.4),
                    hR=("ball", 0.0, BR + 0.4, -1.4), hL=("sh", 5.0, -3.0, 2.0), pR=(-1, -0.5, -0.2),
                    **tuck(3.4, 2.0, 0.20 * L, 0.08 * L))),
        (11.0, K(lean=8, head_up=18, shrug=1.6, ball=None, hR=("w", -2.6, top + 24.5, 8.0),
                    hL=("sh", 5.0, -4.0, 2.0), **tuck(1.8, 0.8, 0.06 * L, -0.02 * L))),
        (12.0, K(fL=F(hw + 1.4, 2.0), fR=F(-hw - 1.4, -0.6), h=0.66, lean=20, head_up=20, shrug=0.0,
                    hR=("sh", 3.5, -6.0, 6.0), hL=("sh", 3.5, -6.0, 6.0), pL=(1, 0.3, -0.6), pR=(-1, 0.3, -0.6))),
    ]
    return keys


def k_alley(D):
    """Alley-oop: no ball at the takeoff, both arms reach up for the lob, the two-hand catch (4), cocked behind the
    head, the slam, hands on the rim, land."""
    hw, L = D["hw"], D["L"]
    top = PY(D, 0.86)
    nob = lambda i: K(hL=("sh", 2.0, -10.0, 4.0), hR=("sh", 2.0, -10.0, 4.0), ball=None)
    keys = approach(D, nob)
    keys[1][1].update(hL=("sh", 3.0, -9.0, -3.0), hR=("sh", 3.0, -9.0, -3.0), head_up=34)
    tuck = lambda a, b, za=0.0, zb=0.0: {"fL": F(hw * 0.9, za, ANK + a, -0.9, 0.1), "fR": F(-hw * 0.9, zb, ANK + b, -0.8, 0.1)}
    keys += [
        (2.0, K(fL=F(hw * 0.8, -0.22 * L, ANK + 1.4, -1.0, 0.1), fR=F(-hw, 0.36 * L, PY(D, 0.93) - 0.9 - 0.30 * L,
                   -0.5, 0.1), h=0.93, lean=4, head_up=30, hL=("sh", 2.5, 8.0, 7.0), hR=("sh", 2.5, 8.0, 7.0),
                   pL=(1, -0.6, -0.2), pR=(-1, -0.6, -0.2))),
        (3.0, K(**tuck(1.2, 3.8, -0.08 * L, 0.12 * L), h=0.86, lean=-2, head_up=32, shrug=1.6,
                   hL=("sh", 1.5, 12.0, 4.0), hR=("sh", 1.5, 12.0, 4.0), pL=(1, -0.4, 0.2), pR=(-1, -0.4, 0.2))),
        (4.0, K(**tuck(2.6, 4.8, -0.12 * L, 0.06 * L), lean=-4, head_up=30, shrug=1.8,
                   ball=("w", 0.0, top + 29.5, 3.6), **two(0.4))),
        (5.0, K(**tuck(3.6, 5.2, -0.20 * L, -0.12 * L), lean=-10, head_up=24, shrug=1.8,
                   ball=("w", 0.0, top + 22.5, -6.4), **two(-0.2), pL=(1, 0.6, 0.6), pR=(-1, 0.6, 0.6))),
        (6.0, K(lean=-12, ball=("w", 0.0, top + 22.9, -7.0), **tuck(4.6, 6.2, -0.24 * L, -0.14 * L))),
        (7.0, K(lean=16, head_up=10, shrug=1.0, ball=("w", 0.0, top + 20.5, 11.0), **two(1.0),
                   pL=(1, -0.4, -0.3), pR=(-1, -0.4, -0.3), **tuck(3.2, 1.6, 0.18 * L, 0.04 * L))),
        (8.0, K(lean=12, head_up=16, shrug=1.5, ball=None, hL=("w", 3.4, top + 24.5, 8.0),
                   hR=("w", -3.4, top + 24.5, 8.0), **tuck(4.2, 2.4, 0.22 * L, 0.12 * L))),
        (9.0, K(fL=F(hw + 1.4, 2.0), fR=F(-hw - 1.4, -0.6), h=0.66, lean=20, head_up=20, shrug=0.0,
                   hR=("sh", 3.5, -6.0, 6.0), hL=("sh", 3.5, -6.0, 6.0), pL=(1, 0.3, -0.6), pR=(-1, 0.3, -0.6))),
    ]
    return keys


def k_rim_hang(D):
    """Hanging on the rim after a dunk: both hands on the rim, the body swinging under it (loop)."""
    hw, L = D["hw"], D["L"]
    top = PY(D, 0.86)
    rim = lambda: {"hL": ("w", 3.4, top + 25.5, 8.0), "hR": ("w", -3.4, top + 25.5, 8.0), "ball": None}
    return [(0.0, K(rim(), h=0.86, lean=-6, head_up=22, shrug=2.0, fL=F(hw * 0.8, -0.10 * L, ANK + 1.0, -1.0, 0.1),
                       fR=F(-hw * 0.8, -0.02 * L, ANK + 0.4, -1.0, 0.1), pL=(1, -0.4, -0.2), pR=(-1, -0.4, -0.2))),
            (0.5, K(lean=4, root=(0.0, 1.6), fL=F(hw * 0.8, 0.12 * L, ANK + 2.0, -0.8, 0.1),
                       fR=F(-hw * 0.8, 0.18 * L, ANK + 1.4, -0.8, 0.1), head_up=18))]


def k_pass(D, kind):
    hw, L = D["hw"], D["L"]
    fe = {"fL": F(hw + 1.4, 1.2), "fR": F(-hw - 1.4, -1.0)}
    step = {"fL": F(hw + 1.2, 0.32 * L, turn=0.15), "fR": F(-hw - 1.4, -1.6, turn=0.3)}
    if kind == "chest":
        return [
            (0.0, K(fe, two(0.4), h=0.86, lean=8, head_up=12, ball=("chest", 0.0, -1.5, 6.0),
                       pL=(1, -0.6, -0.5), pR=(-1, -0.6, -0.5))),
            (1.0, K(two(0.4), h=0.82, lean=6, ball=("chest", 0.0, -1.0, 4.6), pL=(1, -0.3, -0.8), pR=(-1, -0.3, -0.8))),
            (2.0, K(step, two(0.5), h=0.80, lean=14, ball=("chest", 0.0, -0.5, 9.5))),
            (3.0, K(h=0.80, lean=18, ball=("chest", 0.0, 0.0, 15.5), hL=("ball", BR + 0.2, -0.4, -1.4),
                       hR=("ball", -(BR + 0.2), -0.4, -1.4), pL=(1, -0.2, 0.0), pR=(-1, -0.2, 0.0))),
            (4.0, K(ball=None, hL=("chest", 3.4, -1.5, 13.0), hR=("chest", -3.4, -1.5, 13.0), lean=17)),
            (5.0, K(fe, h=0.86, lean=8, hL=("sh", 2.0, -8.0, 6.0), hR=("sh", 2.0, -8.0, 6.0),
                       pL=(1, -0.4, -0.4), pR=(-1, -0.4, -0.4))),
        ]
    if kind == "bounce":
        return [
            (0.0, K(fe, two(0.4), h=0.84, lean=10, head_up=12, ball=("chest", 0.0, -2.5, 6.0),
                       pL=(1, -0.6, -0.5), pR=(-1, -0.6, -0.5))),
            (1.0, K(two(0.4), h=0.78, lean=14, ball=("chest", 0.0, -3.0, 4.6), pL=(1, -0.3, -0.8), pR=(-1, -0.3, -0.8))),
            (2.0, K(step, two(0.6), h=0.72, lean=26, head_up=22, ball=("chest", 0.0, -6.0, 9.5))),
            (3.0, K(h=0.70, lean=30, head_up=26, ball=("chest", 0.0, -9.5, 14.0), hL=("ball", BR + 0.2, 1.4, -1.0),
                       hR=("ball", -(BR + 0.2), 1.4, -1.0), pL=(1, -0.2, 0.0), pR=(-1, -0.2, 0.0))),
            (4.0, K(ball=None, hL=("chest", 3.4, -10.0, 12.0), hR=("chest", -3.4, -10.0, 12.0), lean=28)),
            (5.0, K(fe, h=0.84, lean=10, head_up=14, hL=("sh", 2.0, -9.0, 6.0), hR=("sh", 2.0, -9.0, 6.0),
                       pL=(1, -0.4, -0.4), pR=(-1, -0.4, -0.4))),
        ]
    # lob: overhead, both hands
    return [
        (0.0, K(fe, two(0.4), h=0.86, lean=8, head_up=14, ball=("chest", 0.0, -1.0, 6.0),
                   pL=(1, -0.6, -0.5), pR=(-1, -0.6, -0.5))),
        (1.0, K(two(0.3), h=0.84, lean=0, head_up=20, ball=("chest", 0.0, 10.0, 3.4), pL=(1, -0.8, 0.0),
                   pR=(-1, -0.8, 0.0), shrug=0.8)),
        (2.0, K(step, two(-0.2), h=0.86, lean=-6, head_up=24, shrug=1.4, ball=("chest", 0.0, 14.0, -2.0),
                   pL=(1, 0.2, 0.6), pR=(-1, 0.2, 0.6))),
        (3.0, K(h=0.90, lean=6, head_up=26, shrug=1.6, ball=("chest", 0.0, 17.5, 9.0),
                   hL=("ball", BR + 0.2, -0.8, -1.6), hR=("ball", -(BR + 0.2), -0.8, -1.6), pL=(1, -0.6, 0.0),
                   pR=(-1, -0.6, 0.0))),
        (4.0, K(ball=None, hL=("sh", 1.8, 9.0, 9.0), hR=("sh", 1.8, 9.0, 9.0), lean=8, head_up=24)),
        (5.0, K(fe, h=0.86, lean=6, head_up=14, shrug=0.0, hL=("sh", 2.0, -8.0, 6.0), hR=("sh", 2.0, -8.0, 6.0),
                   pL=(1, -0.4, -0.4), pR=(-1, -0.4, -0.4))),
    ]


def k_steal(D):
    """Steal swipe with the right hand: load, lunge on the right foot, the hand sweeps low across from the right side
    to the left, recover."""
    hw, L = D["hw"], D["L"]
    fe = {"fL": F(hw + 2.6, 1.0, turn=0.35), "fR": F(-hw - 2.6, -0.6, turn=0.35)}
    lunge = {"fR": F(-hw - 1.8, 0.36 * L, turn=0.15), "fL": F(hw + 2.4, -0.30 * L, ANK + 0.6, -0.4, 0.3)}
    return [
        (0.0, K(fe, h=0.76, lean=22, head_up=22, twist=-10, hR=("sh", 4.0, -6.0, 5.0), hL=("sh", 4.0, -2.0, 6.0),
                   pL=(0.6, -1, -0.2), pR=(-0.6, -1, -0.2))),
        (1.0, K(lunge, h=0.70, lean=32, head_up=30, twist=-22, root=(-0.6, 2.0), hR=("chest", -9.0, -6.0, 9.0),
                   hL=("sh", 5.0, 0.0, 1.0))),
        (2.0, K(h=0.66, lean=36, twist=-4, root=(-0.4, 3.0), hR=("chest", -3.0, -9.0, 14.5), head_up=32)),
        (3.0, K(h=0.66, twist=14, root=(0.0, 3.0), hR=("chest", 5.0, -8.5, 12.0), hL=("sh", 5.0, 1.0, -2.0))),
        (4.0, K(h=0.72, lean=28, twist=10, root=(0.0, 1.8), hR=("chest", 4.0, -4.0, 7.0), head_up=26)),
        (5.0, K(fe, h=0.76, lean=22, head_up=22, twist=-4, root=(0.0, 0.0), hR=("sh", 4.0, -6.0, 5.0),
                   hL=("sh", 4.0, -2.0, 6.0))),
    ]


def k_block(D):
    """Block: load with the arms low, jump with both arms up, the right hand swats forward at the top (4-5), come
    down."""
    hw, L = D["hw"], D["L"]
    fe = {"fL": F(hw + 1.6, 0.8), "fR": F(-hw - 1.6, -0.4)}
    tuck = lambda a, b: {"fL": F(hw * 0.9, -0.04 * L, ANK + a, -0.9, 0.1), "fR": F(-hw * 0.9, 0.0, ANK + b, -0.9, 0.1)}
    return [
        (0.0, K(fe, h=0.74, lean=16, head_up=22, hL=("sh", 2.5, -9.0, 5.0), hR=("sh", 2.5, -9.0, 5.0),
                   pL=(1, -0.4, -0.4), pR=(-1, -0.4, -0.4))),
        (1.0, K(h=0.64, lean=22, head_up=30, hL=("sh", 3.0, -6.0, 8.0), hR=("sh", 3.0, -6.0, 8.0))),
        (2.0, K(fL=F(hw + 1.0, 0.4, ANK + 0.6, -1.0, 0.1), fR=F(-hw - 1.0, -0.2, ANK + 0.4, -1.0, 0.1), h=0.97,
                   lean=2, head_up=28, shrug=1.2, hL=("sh", 1.5, 9.0, 7.0), hR=("sh", 1.5, 9.0, 7.0),
                   pL=(1, -0.5, 0.0), pR=(-1, -0.5, 0.0))),
        (3.0, K(tuck(2.0, 2.6), h=0.94, lean=-2, head_up=26, shrug=2.0, hL=("sh", 1.4, 13.0, 2.0),
                   hR=("sh", 1.4, 13.0, 2.0))),
        (4.0, K(tuck(3.2, 3.4), lean=-4, hR=("sh", 0.6, 11.0, 7.0), hL=("sh", 2.0, 12.6, 2.0))),
        (5.0, K(tuck(3.0, 3.0), lean=12, head_up=18, shrug=1.4, hR=("sh", 0.8, 3.0, 12.4), hL=("sh", 2.6, 11.0, 4.0),
                   pR=(-1, -0.6, -0.2))),
        (6.0, K(tuck(1.4, 1.2), lean=8, head_up=16, shrug=0.8, hR=("sh", 3.0, -4.0, 9.0), hL=("sh", 4.0, 4.0, 6.0))),
        (7.0, K(fe, h=0.72, lean=18, head_up=18, shrug=0.0, hL=("sh", 3.5, -7.0, 5.0), hR=("sh", 3.5, -7.0, 5.0),
                   pL=(1, 0.3, -0.6), pR=(-1, 0.3, -0.6))),
    ]


def k_stumble(D):
    """Off balance (beaten on a move): rocked back, arms out, a foot stepping back to catch himself, steady again."""
    hw, L = D["hw"], D["L"]
    fe = {"fL": F(hw + 2.0, 0.8, turn=0.3), "fR": F(-hw - 2.0, -0.4, turn=0.3)}
    return [
        (0.0, K(fe, h=0.80, lean=16, head_up=18, hL=("sh", 3.0, -6.0, 6.0), hR=("sh", 3.0, -6.0, 6.0))),
        (1.0, K(h=0.84, lean=-8, twist=12, root=(0.0, -1.0), head_up=0, head_yaw=-10, hL=("sh", 9.0, 5.0, 3.0),
                   hR=("sh", 9.0, 2.0, -2.0), pL=(0.2, -1, -0.2), pR=(-0.2, -1, -0.2))),
        (2.0, K(h=0.86, lean=-14, twist=16, root=(0.6, -2.2), fR=F(-hw - 1.6, -0.24 * L, ANK + 2.6, -0.4, 0.3),
                   hL=("sh", 10.0, 8.0, 0.0), hR=("sh", 9.0, 6.0, -4.0), head_up=-2)),
        (3.0, K(h=0.80, lean=-10, twist=10, root=(0.4, -3.4), fR=F(-hw - 2.0, -0.38 * L, turn=0.4),
                   hL=("sh", 9.0, 4.0, 4.0), hR=("sh", 10.0, 1.0, -2.0))),
        (4.0, K(h=0.74, lean=2, twist=4, root=(0.2, -3.8), fL=F(hw + 2.4, -0.10 * L, ANK + 1.4, -0.3, 0.3),
                   hL=("sh", 7.0, 0.0, 6.0), hR=("sh", 8.0, -2.0, 2.0), head_up=10, head_yaw=4)),
        (5.0, K(h=0.72, lean=10, twist=-4, root=(0.0, -3.0), fL=F(hw + 2.2, -0.04 * L, turn=0.3),
                   hL=("sh", 4.0, -4.0, 6.0), hR=("sh", 5.0, -5.0, 4.0), head_up=16)),
        (6.0, K(h=0.76, lean=14, twist=-2, root=(0.0, -1.6), hL=("sh", 3.0, -6.0, 6.0), hR=("sh", 3.0, -6.0, 6.0))),
        (7.0, K(fe, h=0.80, lean=14, twist=0, root=(0.0, 0.0), head_up=18, head_yaw=0)),
    ]


def k_fall(D):
    """Ankle-breaker: the feet cross up, he tips back onto the floor (hands back), sits there a beat, then rolls to
    one knee and gets up into a stance."""
    hw, L, l1, l2 = D["hw"], D["L"], D["l1"], D["l2"]
    fe = {"fL": F(hw + 2.0, 0.8, turn=0.3), "fR": F(-hw - 2.0, -0.4, turn=0.3)}
    sit_py = ANK + 2.2
    sit_feet = {"fL": F(hw + 1.6, 0.86 * L - 4.0, ANK, 0.9, 0.3), "fR": F(-hw - 1.0, 0.80 * L - 4.0, ANK, 0.9, 0.3)}
    kneel_py = ANK + l1 * 0.95
    return [
        (0.0, K(fe, h=0.80, lean=16, head_up=18, hL=("sh", 3.0, -6.0, 6.0), hR=("sh", 3.0, -6.0, 6.0))),
        (1.0, K(h=0.84, lean=4, twist=18, root=(-0.6, -0.4), fL=F(-hw * 0.4, 0.4, ANK + 1.2, -0.3, -0.2),
                   head_yaw=-16, hL=("sh", 7.0, 0.0, 6.0), hR=("sh", 8.0, 2.0, -1.0))),
        (2.0, K(h=0.80, lean=-12, twist=24, root=(-0.4, -2.0), fL=F(-hw * 0.6, 2.4, turn=-0.2),
                   fR=F(-hw - 1.4, 1.6, ANK + 2.0, 0.3, 0.3), hL=("sh", 9.0, 6.0, 2.0), hR=("sh", 9.0, 8.0, -2.0),
                   head_up=-4, pL=(0.2, -1, -0.2), pR=(-0.2, -1, -0.2))),
        (3.0, K(py=PY(D, 0.55), lean=-24, twist=14, root=(0.0, -4.4), fL=F(hw * 0.2, 0.30 * L, ANK + 1.4, 0.6, 0.1),
                   fR=F(-hw - 1.2, 0.36 * L, ANK + 3.6, 0.6, 0.3), hL=("w", hw + 6.0, 6.0, -10.0),
                   hR=("w", -hw - 6.0, 7.0, -11.0), head_up=0)),
        (4.0, K(sit_feet, py=sit_py, lean=-30, twist=4, root=(0.0, -5.0), hL=("w", D["sw"] + 2.0, 1.4, -11.0),
                   hR=("w", -D["sw"] - 2.0, 1.4, -11.0), head_up=4, pL=(1, -0.2, 0.5), pR=(-1, -0.2, 0.5))),
        (5.0, K(py=sit_py + 0.4, lean=-22, head_up=16, head_yaw=10)),
        (6.0, K(lean=-18, head_up=12, head_yaw=-10, hL=("w", D["sw"] + 2.0, 1.4, -10.0))),
        (7.0, K(py=sit_py + 1.4, lean=10, twist=-10, root=(0.0, -3.4), fL=F(hw + 1.4, 0.40 * L, turn=0.2),
                   fR=F(-hw - 1.0, 0.08 * L, ANK, 0.0, 0.2), hL=("w", D["sw"] + 1.0, 1.4, 4.0),
                   hR=("w", -D["sw"] - 3.0, 1.4, -4.0), head_up=18, head_yaw=0, pL=(1, -0.4, -0.4),
                   pR=(-1, -0.4, -0.4))),
        (8.0, K(py=kneel_py, lean=12, twist=-4, root=(0.0, -1.6), fL=F(hw + 1.4, 0.36 * L, turn=0.2),
                   fR=F(-hw - 0.8, -l2 + 1.0, ANK + 0.4, -0.9, 0.2), kp=1.0, hL=("w", hw + 2.6, PY(D, 0.5), 7.0),
                   hR=("w", -D["sw"] - 2.0, 4.0, 3.0), head_up=16)),
        (9.0, K(py=kneel_py + 3.2, lean=18, twist=0, root=(0.0, -0.4), hL=("sh", 2.0, -9.0, 6.0),
                   hR=("sh", 3.0, -8.0, 5.0), fR=F(-hw - 1.0, -0.40 * L, ANK + 1.6, -0.6, 0.2))),
        (10.0, K(h=0.76, lean=18, root=(0.0, 0.0), fL=F(hw + 2.0, 1.6, turn=0.3), fR=F(-hw - 2.0, -1.0, turn=0.3),
                    hL=("sh", 3.0, -6.0, 6.0), hR=("sh", 3.0, -6.0, 6.0), head_up=18)),
        (11.0, K(fe, h=0.80, lean=14, head_up=18)),
    ]


def k_land(D):
    hw = D["hw"]
    fe = {"fL": F(hw + 1.6, 1.4), "fR": F(-hw - 1.6, -0.4)}
    return [
        (0.0, K(fe, h=0.74, lean=16, head_up=16, hL=("sh", 5.0, -6.0, 5.0), hR=("sh", 5.0, -6.0, 5.0),
                   pL=(1, 0.3, -0.6), pR=(-1, 0.3, -0.6))),
        (1.0, K(h=0.64, lean=24, head_up=22, hL=("sh", 6.0, -5.0, 6.0), hR=("sh", 6.0, -5.0, 6.0))),
        (2.0, K(h=0.78, lean=14, head_up=16, hL=("sh", 3.0, -9.0, 4.0), hR=("sh", 3.0, -9.0, 4.0))),
        (3.0, K(h=0.88, lean=6, head_up=10, hL=("sh", 1.6, -11.5, 2.0), hR=("sh", 1.6, -11.5, 2.0),
                   pL=(1, -0.2, -0.3), pR=(-1, -0.2, -0.3))),
    ]


def k_celebrate_a(D):
    """Fist pumps: right, left, with a bounce in the knees and the shout face (loop)."""
    hw = D["hw"]
    fe = {"fL": F(hw + 1.6, 1.0, turn=0.3), "fR": F(-hw - 1.6, -0.4, turn=0.3)}
    return [
        (0.0, K(fe, h=0.84, lean=6, head_up=18, twist=-8, hR=("sh", 2.0, 10.0, 3.0), hL=("chest", 3.0, -2.0, 6.0),
                   pR=(-1, -0.4, 0.3), pL=(0.6, -1, -0.3), shrug=1.0)),
        (0.2, K(h=0.80, lean=10, hR=("sh", 3.0, 2.0, 6.0), head_up=14, shrug=0.4)),
        (0.4, K(h=0.86, twist=0, hR=("chest", -3.0, -2.0, 6.0), hL=("chest", 3.0, -1.0, 7.0), head_up=12)),
        (0.5, K(h=0.84, lean=6, head_up=18, twist=8, hL=("sh", 2.0, 10.0, 3.0), hR=("chest", -3.0, -2.0, 6.0),
                   pL=(1, -0.4, 0.3), pR=(-0.6, -1, -0.3), shrug=1.0)),
        (0.7, K(h=0.80, lean=10, hL=("sh", 3.0, 2.0, 6.0), head_up=14, shrug=0.4)),
        (0.9, K(h=0.86, twist=0, hL=("chest", 3.0, -2.0, 6.0), hR=("chest", -3.0, -1.0, 7.0), head_up=12,
                   pR=(-1, -0.4, 0.3))),
    ]


def k_celebrate_b(D):
    """The big one: crouch, then a hop with both arms up in a V and the shout, land, flex (loop)."""
    hw = D["hw"]
    fe = {"fL": F(hw + 1.8, 0.8, turn=0.3), "fR": F(-hw - 1.8, -0.4, turn=0.3)}
    hop = {"fL": F(hw + 1.4, 0.4, ANK + 3.0, -0.8, 0.2), "fR": F(-hw - 1.4, -0.2, ANK + 3.0, -0.8, 0.2)}
    vee = {"hL": ("sh", 5.5, 11.0, 1.5), "hR": ("sh", 5.5, 11.0, 1.5), "pL": (1, -0.3, 0.0), "pR": (-1, -0.3, 0.0)}
    return [
        (0.0, K(fe, h=0.72, lean=20, head_up=12, hL=("sh", 5.0, -5.0, 3.0), hR=("sh", 5.0, -5.0, 3.0),
                   pL=(1, -0.4, -0.2), pR=(-1, -0.4, -0.2))),
        (0.2, K(hop, vee, py=PY(D, 0.95) + 3.0, lean=-6, head_up=26, shrug=1.6)),
        (0.35, K(hop, vee, py=PY(D, 0.95) + 3.6, lean=-8, head_up=28, shrug=1.8)),
        (0.5, K(fe, h=0.76, lean=10, head_up=20, shrug=0.8, hL=("sh", 6.0, 6.0, 2.0), hR=("sh", 6.0, 6.0, 2.0))),
        (0.7, K(h=0.80, lean=4, head_up=24, shrug=1.2, hL=("sh", 6.0, 1.0, 1.0), hR=("sh", 6.0, 1.0, 1.0),
                   pL=(1, 0.8, 0.0), pR=(-1, 0.8, 0.0))),      # flex: fists by the ears, elbows out
        (0.85, K(h=0.78, lean=6, head_up=26, hL=("sh", 6.4, 2.0, 1.4), hR=("sh", 6.4, 2.0, 1.4))),
    ]


# ----------------------------------------------------------------------------- the animation table

def keyed(fn, n, loop=False, times=None, bounce=None):
    return {"kind": "keys", "fn": fn, "n": n, "loop": loop, "times": times, "bounce": bounce}


def proc(fn, n, loop=True):
    return {"kind": "proc", "fn": fn, "n": n, "loop": loop}


def mirrored(name):
    return {"kind": "mirror", "of": name}


def T(n, last=None):
    """Frame times for a one-shot through keys 0..last (last = n - 1 by default)."""
    last = (n - 1) if last is None else last
    return [last * k / (n - 1) for k in range(n)]


# name -> definition, fps (0 = progress-driven), per-frame ms (previews, and a hint for the game), events
ANIMS = [
    ("idle", keyed(k_idle, 6, loop=True), 6.0, [170] * 6, {}),
    ("run", proc(run_fn, 12), 20.0, [50] * 12, {"contact": [0, 6]}),
    ("dribble", proc(dribble_fn, 8), 13.3, [80, 70] * 4, {"floor": 4, "catch": 7}),
    ("dribble_l", mirrored("dribble"), 13.3, [80, 70] * 4, {"floor": 4, "catch": 7, "hand": "L"}),
    ("run_dribble", proc(run_dribble_fn, 10), 16.7, [60] * 10, {"floor": 4, "catch": 9, "contact": [1, 6]}),
    ("run_dribble_l", mirrored("run_dribble"), 16.7, [60] * 10, {"floor": 4, "catch": 9, "contact": [1, 6], "hand": "L"}),
    ("cross", keyed(k_cross, 8), 0.0, [40] * 8, {"floor": 3, "switch": 4, "hand_end": "L"}),
    ("cross_l", mirrored("cross"), 0.0, [40] * 8, {"floor": 3, "switch": 4, "hand_end": "R"}),
    ("hold", keyed(k_hold, 4, loop=True), 4.0, [250] * 4, {}),
    ("catch", keyed(k_catch, 4), 0.0, [40, 40, 50, 60], {"contact": 0}),
    ("shoot", keyed(k_shoot, 10), 0.0, [70, 70, 60, 60, 50, 50, 60, 120, 100, 120],
     {"gather": [0, 3], "rise": [4, 5], "release": 6, "follow": [7, 9], "air": [4, 8]}),
    ("layup", keyed(k_layup, 10), 0.0, [70, 70, 50, 50, 50, 60, 60, 60, 80, 100],
     {"takeoff": 2, "release": 5, "air": [2, 7], "land": 8}),
    ("dunk_one", keyed(k_dunk_one, 9), 0.0, [80, 90, 70, 70, 90, 120, 60, 200, 300],
     {"takeoff": 2, "hang": 5, "release": 6, "rim": 7, "air": [2, 7], "land": 8}),
    ("dunk_two", proc(dunk_two_fn, 10, loop=False), 0.0, [80, 90, 70, 70, 100, 150, 60, 110, 150, 320],
     {"takeoff": 2, "hang": 5, "release": 6, "rim": 7, "air": [2, 8], "land": 9}),
    ("dunk_tomahawk", keyed(k_tomahawk, 10), 0.0, [80, 90, 70, 70, 100, 150, 60, 60, 200, 300],
     {"takeoff": 2, "hang": 5, "release": 7, "rim": 8, "air": [2, 8], "land": 9}),
    ("dunk_windmill", keyed(k_windmill, 12, times=[0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12]), 0.0,
     [80, 90, 60, 60, 60, 60, 140, 60, 60, 60, 200, 300],
     {"takeoff": 2, "hang": 6, "release": 9, "rim": 10, "air": [2, 10], "land": 11}),
    ("dunk_alley", keyed(k_alley, 10), 0.0, [80, 90, 70, 70, 80, 90, 150, 60, 200, 300],
     {"takeoff": 2, "catch": 4, "hang": 6, "release": 7, "rim": 8, "air": [2, 8], "land": 9}),
    ("rim_hang", keyed(k_rim_hang, 4, loop=True), 5.0, [200] * 4, {}),
    ("pass_chest", keyed(lambda D: k_pass(D, "chest"), 6), 0.0, [50, 50, 40, 40, 60, 90], {"release": 3}),
    ("pass_bounce", keyed(lambda D: k_pass(D, "bounce"), 6), 0.0, [50, 50, 40, 40, 60, 90], {"release": 3}),
    ("pass_lob", keyed(lambda D: k_pass(D, "lob"), 6), 0.0, [60, 60, 50, 50, 70, 90], {"release": 3}),
    ("slide", proc(slide_fn, 8), 12.0, [80] * 8, {"direction": "player's left; play backwards for his right"}),
    ("steal", keyed(k_steal, 6), 12.0, [50, 60, 50, 60, 80, 90], {"reach": 2}),
    ("block", keyed(k_block, 8), 0.0, [60, 70, 50, 60, 70, 70, 80, 120], {"takeoff": 2, "swat": 5, "air": [2, 6]}),
    ("stumble", keyed(k_stumble, 8), 0.0, [60] * 8, {}),
    ("fall", keyed(k_fall, 12), 0.0, [60, 70, 70, 80, 120, 200, 200, 120, 120, 100, 100, 120],
     {"down": [4, 6], "getup": [7, 11]}),
    ("land", keyed(k_land, 4), 0.0, [40, 50, 50, 60], {}),
    ("celebrate_a", keyed(k_celebrate_a, 10, loop=True), 9.0, [110] * 10, {}),
    ("celebrate_b", keyed(k_celebrate_b, 10, loop=True), 9.0, [110] * 10, {"air": [2, 4]}),
]
EXPR = {"celebrate_a": "celebrate", "celebrate_b": "celebrate"}
ANIM = {a[0]: a for a in ANIMS}

# illustrative jump lift for the previews only (art px per frame); the game computes its own from the sim
PREVIEW_LIFT = {
    "shoot": [0, 0, 0, 0, 6, 12, 14, 12, 5, 0],
    "layup": [0, 0, 4, 12, 18, 20, 18, 10, 0, 0],
    "dunk_one": [0, 0, 4, 14, 20, 22, 21, 19, 0],
    "dunk_two": [0, 0, 4, 14, 20, 22, 21, 19, 15, 0],
    "dunk_tomahawk": [0, 0, 4, 14, 20, 22, 22, 21, 19, 0],
    "dunk_windmill": [0, 0, 4, 12, 17, 20, 22, 23, 22, 21, 19, 0],
    "dunk_alley": [0, 0, 4, 14, 22, 24, 25, 23, 21, 0],
    "rim_hang": [19, 19, 19, 19],
    "block": [0, 0, 4, 14, 20, 20, 10, 0],
}


for _a in ANIMS:
    _n = _a[1]["n"] if _a[1]["kind"] != "mirror" else ANIM[_a[1]["of"]][1]["n"]
    assert len(_a[3]) == _n, _a[0]
    if _a[1]["kind"] == "keys" and _a[1].get("times"):
        assert len(_a[1]["times"]) == _n, _a[0]


def columns():
    out = {}
    c = 0
    for name, d, fps, ms, ev in ANIMS:
        n = d["n"] if d["kind"] != "mirror" else ANIM[d["of"]][1]["n"]
        out[name] = (c, n)
        c += n
    return out, c


# ----------------------------------------------------------------------------- frames

def frame_times(d):
    n = d["n"]
    if d["times"]:
        return d["times"]
    if d["loop"]:
        return [k / n for k in range(n)]
    return [float(k) for k in range(n)]           # keys at 0, 1, 2 ... one per frame


def anim_poses(name, D):
    """[(pixel3d pose, ball)] for every frame of an animation."""
    _, d, _, _, _ = ANIM[name]
    if d["kind"] == "mirror":
        return [mirror_pose(p, b) for p, b in anim_poses(d["of"], D)]
    if d["kind"] == "proc":
        return [d["fn"](k, D, d["n"]) for k in range(d["n"])]
    rk = expand(D, d["fn"](D))
    out = []
    for t in frame_times(d):
        r = sample(rk, t, d["loop"])
        out.append(rig_pose(D, r))
    return out


def render_frame(p, pose, ball, yaw, expr):
    pose = dict(pose)
    root = pose.pop("_root", np.zeros(3))
    C = S.cam_matrix(yaw)
    rc = C @ root
    ox = FW / 2.0 + rc[0] * SCALE
    oy = FEET_Y - rc[1] * SCALE
    img, cv, info = P.render(p, pose, yaw, w=FW, h=FH, ox=ox, oy=oy, scale=SCALE, expr=expr, limb_line=LIMB_LINE)
    rec = {"hands": {}, "ball": None}
    for side in ("L", "R"):
        i, j, _ = cv.project(info["hands"][side])
        rec["hands"][side] = [i, j]
    if ball is not None:
        bc = C @ np.asarray(ball, float)
        bx = ox + bc[0] * SCALE
        by = oy - bc[1] * SCALE
        front = S.ball_in_front(cv, bx, by, bc[2])
        fc = C @ np.array([ball[0], 0.0, ball[2]])
        rec["ball"] = [round(bx, 1), round(by, 1), 1 if front else 0]
        rec["ball_floor"] = [round(ox + fc[0] * SCALE, 1), round(oy - fc[1] * SCALE, 1)]
        rec["ball_h"] = round(float(ball[1] - BR), 2)
    return img, rec


def check(img, rec, tag):
    a = np.array(img)[:, :, 3] > 0
    probs = []
    if a[0].any() or a[-1].any() or a[:, 0].any() or a[:, -1].any():
        probs.append("touches the frame edge")
    n = S.pieces(img)
    if n != 1:
        probs.append("%d pieces" % n)
    b = rec.get("ball")
    if b is not None and not (5 <= b[0] <= FW - 6 and 5 <= b[1] <= FH - 6):
        probs.append("ball centre near/out of the frame %s" % b)
    return ["%s: %s" % (tag, s) for s in probs]


def render_sheet(sheet_id, dump=None, only_anims=None):
    """Renders one player's whole sheet. Returns (frames {(anim, dir): [(img, rec)]}, problems)."""
    p = [q for q in M.load_players() if q["id"] == sheet_id][0]
    D = dims_of(p)
    frames, probs = {}, []
    for name, d, fps, ms, ev in ANIMS:
        if only_anims and name not in only_anims:
            continue
        poses = anim_poses(name, D)
        for dname, yaw in DIRS:
            seq = []
            for k, (pose, ball) in enumerate(poses):
                img, rec = render_frame(p, pose, ball, yaw, EXPR.get(name, "focus"))
                probs += check(img, rec, "%s %s %s %d" % (sheet_id, name, dname, k))
                seq.append((img, rec))
                if dump:
                    os.makedirs(dump, exist_ok=True)
                    img.save(os.path.join(dump, "%s_%s_%s_%02d.png" % (sheet_id, name, dname, k)))
            frames[(name, dname)] = seq
    return frames, probs


def _render_job(args):
    sid, dump, only = args
    t = time.time()
    fr, pr = render_sheet(sid, dump, only)
    # PIL images pickle fine; keep them as raw bytes to be lighter
    out = {k: [(np.array(img), rec) for img, rec in v] for k, v in fr.items()}
    return sid, out, pr, time.time() - t


# ----------------------------------------------------------------------------- files

def write_sheet(sheet_id, frames):
    cols, total = columns()
    pages = []
    npages = int(math.ceil(total / PAGE_COLS))
    for pg in range(npages):
        c0 = pg * PAGE_COLS
        w = min(PAGE_COLS, total - c0)
        pages.append(Image.new("RGBA", (w * FW, FH * len(DIRS)), (0, 0, 0, 0)))
    for name, (start, n) in cols.items():
        for r, (dname, _) in enumerate(DIRS):
            for k, (img, rec) in enumerate(frames[(name, dname)]):
                c = start + k
                pages[c // PAGE_COLS].paste(img, ((c % PAGE_COLS) * FW, r * FH))
    sizes = []
    for pg, img in enumerate(pages):
        path = os.path.join(OUT_DIR, "%s_p%d.png" % (sheet_id, pg))
        kind = M.save_png(img, path)
        sizes.append((path, img.size, kind, os.path.getsize(path)))
    os.makedirs(CARD_DIR, exist_ok=True)
    card = frames[("idle", "S")][0][0]
    cpath = os.path.join(CARD_DIR, sheet_id + ".png")
    M.save_png(card, cpath)
    sizes.append((cpath, card.size, "card", os.path.getsize(cpath)))
    return sizes


def write_format():
    cols, total = columns()
    anims = {}
    for name, d, fps, ms, ev in ANIMS:
        start, n = cols[name]
        loop = d["loop"] if d["kind"] != "mirror" else ANIM[d["of"]][1]["loop"]
        e = {"start": start, "frames": n, "fps": fps, "loop": bool(loop), "ms": ms}
        e.update({k: v for k, v in ev.items() if k != "times"})
        anims[name] = e
    fmt = {"_help": "v2 player sheets (P6-A6, tools/art/make_players_v2.py). Frame 64 x 96 art px, art scale 1.25, "
                    "drawn 2x; floor point row 88, x 32. Rows S, SE, E, NE, N (SW, W, NW mirrored). Logical columns "
                    "in pages of page_cols: <sheet>_p<N>.png. fps 0 = the game drives the frame from a progress. "
                    "ms = the drawn timing per frame (previews; a hint). Events are frame indexes: release (the ball "
                    "leaves the hands), floor (dribble bounce), catch, takeoff, hang, rim (hands on the rim), land, "
                    "swat, air [first, last] (feet off the floor). *_l = left-hand versions; cross ends in the left "
                    "hand, cross_l in the right.",
           "version": 2, "frame": [FW, FH], "feet_row": FEET_Y, "center_x": CX, "head_px": HEAD_PX,
           "art_scale": SCALE, "draw_scale": 2.0, "dirs": [d for d, _ in DIRS], "cols": total,
           "page_cols": PAGE_COLS, "anims": anims}
    with open(os.path.join(OUT_DIR, "format.json"), "w") as f:
        json.dump(fmt, f, indent=1)
    return fmt


def body_key(p):
    return p["body"] if not p.get("body_tweak") else p["id"]


def write_hands(all_frames):
    """Body-keyed hands.json. Sheets on the same body (and no body_tweak) share the points; if a sheet's points
    differ (a hair style can flip a ball layer vote), it gets its own body entry."""
    players = {q["id"]: q for q in M.load_players()}
    raw = json.load(open(M.CREWS))
    body_of = {e["id"]: e for e in raw["players"]}
    path = os.path.join(OUT_DIR, "hands.json")
    data = {"bodies": {}, "sheets": {}}
    if os.path.exists(path):
        try:
            old = json.load(open(path))
            data["bodies"].update(old.get("bodies", {}))
            data["sheets"].update(old.get("sheets", {}))
        except ValueError:
            pass
    for sid, frames in all_frames.items():
        e = body_of.get(sid, body_of.get(players[sid].get("recolor_of", ""), {}))
        key = e.get("body", sid) if not e.get("body_tweak") else sid
        pts = {}
        for name, d, fps, ms, ev in ANIMS:
            pts[name] = {dn: [_rec_out(rec) for _, rec in frames[(name, dn)]] for dn, _ in DIRS}
        if key in data["bodies"] and data["bodies"][key] != pts and data["sheets"].get(sid) != key:
            key = sid
        data["bodies"][key] = pts
        data["sheets"][sid] = key
    out = {"_help": "v2 hand and ball points (P6-A6): bodies.<body>.<anim>.<DIR>[frame] = {hands: {L, R: [x, y]}, "
                    "ball: [x, y, front] or null, ball_floor: [x, y], ball_h}. Art px of a 64 x 96 frame (floor row "
                    "88). front 1 = draw the ball over the sprite. null = the ball is free (thrown, slammed) or not "
                    "in this animation. Mirrored rows: x' = 63 - x, swap L and R. sheets.<sheet> = its body.",
           "frame": [FW, FH], "feet_row": FEET_Y, "bodies": data["bodies"], "sheets": data["sheets"]}
    with open(path, "w") as f:
        json.dump(out, f, separators=(",", ":"))
    return path


def _rec_out(rec):
    o = {"hands": rec["hands"], "ball": rec["ball"]}
    if rec["ball"] is not None:
        o["ball_floor"] = rec["ball_floor"]
        o["ball_h"] = rec["ball_h"]
    return o


# ----------------------------------------------------------------------------- previews

def compose(img, rec, lift=0, spin=0, ring=True, top=0, ball=True):
    return S.compose_frame(img, rec if ball else dict(rec, ball=None), lift=lift, ball_spin=spin, ring=ring, top=top)


def preview_png(all_frames, path=PREVIEW):
    """1. The 3 players: idle in 8 directions (the W side mirrored), plus a run, dribble and dunk frame.
    2. Every animation of each player facing SE (2x), wrapped in rows, frames numbered."""
    players = list(all_frames.keys())
    Z = 2
    pad = 4
    lab = 18
    cols_per_row = 16
    # section 1
    sec1 = []
    for sid in players:
        fr = all_frames[sid]
        row = []
        for dn in ("S", "SE", "E", "NE", "N"):
            row.append(compose(*fr[("idle", dn)][0]))
        for dn in ("NE", "E", "SE"):
            img, rec = fr[("idle", dn)][0]
            row.append(compose(img.transpose(Image.FLIP_LEFT_RIGHT), dict(rec, ball=None)))
        row.append(None)
        row.append(compose(*fr[("run", "E")][3]))
        row.append(compose(*fr[("run_dribble", "SE")][2]))
        row.append(compose(*fr[("cross", "S")][3]))
        row.append(compose(*fr[("shoot", "E")][6], lift=0))
        row.append(compose(*fr[("dunk_windmill", "SE")][7], lift=0))
        row.append(compose(*fr[("fall", "SE")][5], lift=0))
        sec1.append((sid, row))
    # section 2: each player, all animations, SE
    blocks = []
    for sid in players:
        fr = all_frames[sid]
        cells = []
        for name, d, fps, ms, ev in ANIMS:
            seq = fr[(name, "SE")]
            for k, (img, rec) in enumerate(seq):
                cells.append((name if k == 0 else None, k, compose(img, rec)))
        blocks.append((sid, cells))
    cw, chh = FW * Z, FH * Z
    W = pad + cols_per_row * (cw + pad) + 150
    H = 40 + len(sec1) * (chh + lab + pad)
    for sid, cells in blocks:
        H += 30 + int(math.ceil(len(cells) / cols_per_row)) * (chh + lab + pad)
    base = S.floor_bg(W, H)
    dr = ImageDraw.Draw(base)
    dr.rectangle([0, 0, W, 34], fill=(28, 26, 38, 255))
    S.label(dr, (8, 8), "Player sheets v2 (P6-A6): frame 64x96 art px, shown 2x as in the game. Row 1 per player: idle "
                        "S SE E NE N NW W SW (last 3 mirrored) | run E, run dribble SE, crossover S, jump shot release "
                        "E, windmill top SE, fall SE. Below: every animation facing SE.", 13)
    y = 40
    for sid, row in sec1:
        S.label(dr, (8, y), sid, 14)
        for c, cell in enumerate(row):
            if cell is None:
                continue
            base.alpha_composite(cell.resize((cw, chh), Image.NEAREST), (110 + c * (cw + pad), y + lab))
        y += chh + lab + pad
    for sid, cells in blocks:
        dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
        S.label(dr, (8, y + 4), "%s: all %d columns, SE" % (sid, len(cells)), 14)
        y += 30
        for i, (name, k, cell) in enumerate(cells):
            r, c = divmod(i, cols_per_row)
            x0 = pad + c * (cw + pad)
            y0 = y + r * (chh + lab + pad)
            base.alpha_composite(cell.resize((cw, chh), Image.NEAREST), (x0, y0 + lab))
            S.label(dr, (x0 + 2, y0 + 2), ("%s %d" % (name, k)) if name else str(k), 11,
                    (250, 244, 230) if name else (200, 196, 214))
        y += int(math.ceil(len(cells) / cols_per_row)) * (chh + lab + pad)
    base.convert("RGB").save(path, optimize=True)
    return path


MOVES = [  # (animation, direction, loops); the GIF plays the 3 players side by side
    ("run", "SE", 2), ("run_dribble", "SE", 2), ("run_dribble", "E", 2), ("dribble", "SE", 2), ("cross", "S", 1),
    ("dribble_l", "S", 1), ("cross_l", "S", 1), ("shoot", "E", 1), ("layup", "SE", 1), ("dunk_one", "E", 1),
    ("dunk_two", "SE", 1), ("dunk_tomahawk", "E", 1), ("dunk_windmill", "SE", 1), ("dunk_alley", "E", 1),
    ("rim_hang", "SE", 2), ("pass_chest", "E", 1), ("pass_bounce", "SE", 1), ("pass_lob", "E", 1),
    ("catch", "SE", 1), ("hold", "S", 1), ("slide", "S", 2), ("steal", "SE", 1), ("block", "S", 1),
    ("stumble", "SE", 1), ("fall", "SE", 1), ("land", "SE", 1), ("celebrate_a", "S", 1), ("celebrate_b", "S", 1),
    ("idle", "S", 1),
]


def moves_gif(all_frames, path=MOVES_GIF):
    players = list(all_frames.keys())
    Z = 2
    top = 30
    pad = 6
    head = 22
    cw = FW * Z
    W = pad + len(players) * (cw + pad)
    H = head + (FH + top) * Z + pad
    frames, durs = [], []
    for name, dn, loops in MOVES:
        ms = ANIM[name][3]
        lift = PREVIEW_LIFT.get(name)
        for _ in range(loops):
            for k, dur in enumerate(ms):
                bg = S.floor_bg(W, H)
                dr = ImageDraw.Draw(bg)
                dr.rectangle([0, 0, W, head - 4], fill=(28, 26, 38, 255))
                S.label(dr, (6, 3), "%s (%s) %d/%d" % (name, dn, k + 1, len(ms)), 13)
                for c, sid in enumerate(players):
                    img, rec = all_frames[sid][(name, dn)][k]
                    lf = lift[k] if lift else 0
                    cell = S.compose_frame(img, rec, lift=lf, ball_spin=k, top=top)
                    bg.alpha_composite(cell.resize((cw, (FH + top) * Z), Image.NEAREST), (pad + c * (cw + pad), head))
                frames.append(bg)
                durs.append(max(20, dur))
    S.gif_save(frames, durs, path)
    return path, len(frames), sum(durs)


# ----------------------------------------------------------------------------- main

def main(argv):
    only = argv[argv.index("--only") + 1].split(",") if "--only" in argv else SHEETS
    jobs = int(argv[argv.index("--jobs") + 1]) if "--jobs" in argv else min(len(only), os.cpu_count() or 1)
    dump = argv[argv.index("--frames") + 1] if "--frames" in argv else None
    anims = argv[argv.index("--anims") + 1].split(",") if "--anims" in argv else None
    os.makedirs(OUT_DIR, exist_ok=True)
    t0 = time.time()
    tasks = [(sid, dump, anims) for sid in only]
    if jobs > 1:
        with multiprocessing.get_context("fork").Pool(jobs) as pool:
            res = pool.map(_render_job, tasks)
    else:
        res = [_render_job(t) for t in tasks]
    all_frames, problems = {}, []
    for sid, fr, pr, dt in res:
        all_frames[sid] = {k: [(Image.fromarray(a), rec) for a, rec in v] for k, v in fr.items()}
        problems += pr
        print("rendered %s in %.0f s" % (sid, dt))
    if anims:          # a quick look only: contact strips to the dump folder, no files written
        out = dump or "/tmp"
        for sid, fr in all_frames.items():
            for (name, dn), seq in fr.items():
                strip = Image.new("RGBA", (FW * len(seq), FH + S.TOP), (0, 0, 0, 0))
                lift = PREVIEW_LIFT.get(name)
                for k, (img, rec) in enumerate(seq):
                    strip.alpha_composite(S.compose_frame(img, rec, lift=lift[k] if lift else 0, ball_spin=k), (FW * k, 0))
                bg = S.floor_bg(strip.width * 3, strip.height * 3)
                bg.alpha_composite(strip.resize((strip.width * 3, strip.height * 3), Image.NEAREST))
                bg.convert("RGB").save(os.path.join(out, "strip_%s_%s_%s.png" % (sid, name, dn)))
        for s in problems:
            print("CHECK", s)
        print("checks: %d problem(s)" % len(problems))
        return
    fmt = write_format()
    print("wrote assets/players2/format.json: %d columns, %d pages of %d" % (fmt["cols"],
          int(math.ceil(fmt["cols"] / PAGE_COLS)), PAGE_COLS))
    total = 0
    for sid in only:
        sizes = write_sheet(sid, all_frames[sid])
        s = sum(x[3] for x in sizes)
        total += s
        for pth, sz, kind, b in sizes:
            print("wrote %s %s %s %d bytes" % (os.path.relpath(pth, ROOT), sz, kind, b))
        print("sheet %s: %d bytes on disk (pages + card)" % (sid, s))
    hp = write_hands(all_frames)
    print("wrote %s %d bytes" % (os.path.relpath(hp, ROOT), os.path.getsize(hp)))
    if "--no-preview" not in argv:
        print("wrote", preview_png(all_frames))
        pth, nf, ms = moves_gif(all_frames)
        print("wrote %s: %d frames, %.1f s, %d bytes" % (pth, nf, ms / 1000.0, os.path.getsize(pth)))
    for s in problems:
        print("CHECK", s)
    print("checks: %d problem(s); %.0f s" % (len(problems), time.time() - t0))


if __name__ == "__main__":
    main(sys.argv[1:])
