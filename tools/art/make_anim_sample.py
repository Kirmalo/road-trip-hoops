#!/usr/bin/env python3
"""Animation style sample v1 for Road Trip Hoops (P6-A0; original art, generated; no downloaded or source art).

One player (Deuce, ud_deuce in tools/art/crews.json) rendered with the style-sample renderer (tools/art/pixel3d.py)
at a bigger size and with many more frames, for the owner to approve before every player sheet is redrawn.

- Art scale 1.25 (model units -> art pixels), drawn 2x in the game: an average body (about 40 model units) is
  50 art px = 100 screen px tall; Deuce (lanky) is 53 art px = 106 screen px. Same chunky 2x pixel as the courts,
  the ball and today's players, so the new sprites sit in the same world.
- Frame 64 x 96 art px, the floor point under the pelvis on row FEET_Y (88), x centre 32.
- Directions SE (yaw 45) and E (yaw 75, as make_players.py) only; the full sheet would add S, NE, N.
- Animations (frames, assumed timing):
    run 12 (50 ms each, 0.6 s per stride cycle at full speed; the game scales the rate with the speed),
    rundribble 10 (60 ms, 0.6 s: one bounce per stride cycle, legs running),
    dribble 8 (75 ms, 0.6 s per bounce: knees bent, weight shifting onto the ball side),
    dunk 10 (two-hand: gather, load, takeoff, rise, cock, hang, slam, rim, hang, land; per-frame times below).
- Legs are driven by foot targets on the floor (two-bone IK through pixel3d.ik), so planted feet slide back at
  exactly the run speed and never skate; the pelvis height comes from the targets (bob, landing dip, crouch).
- The ball is NOT baked in: each frame stores the ball centre (art px), a front/back layer flag and the hand
  points, as the game would read them from a json. The GIFs draw the game's own ball (assets/ball/ball.png, read
  only) at those points, as the game would. Airborne dunk frames keep the feet on the floor row; the preview adds
  an illustrative jump lift (DUNK_LIFT) and a rim, as the game does.

Usage:  python3 tools/art/make_anim_sample.py [--frames DIR]   (DIR: also dump every frame as PNG to look at)
Output: docs/art/anim_sample_v1_{run,rundribble,dribble,dunk,compare}.gif, docs/art/anim_sample_v1_sheet.png,
        docs/art/anim_sample_v1_points.json (hand and ball points per frame).
Needs:  Pillow, numpy. Does not touch assets/ or any game file.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import pixel3d as P
import make_players as M

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "docs", "art")
BALL_SHEET = os.path.join(ROOT, "assets", "ball", "ball.png")
FLOOR_TILE = os.path.join(ROOT, "assets", "courts", "gym_floor.png")
CUR_SHEET = os.path.join(ROOT, "assets", "players", "ud_deuce.png")
CUR_HANDS = os.path.join(ROOT, "assets", "players", "hands.json")
PLAYER = "ud_deuce"

SCALE = 1.25                 # art px per model unit (today 1.0)
FW, FH = 64, 96              # frame (art px)
FEET_Y = 88                  # floor row under the pelvis
SHOW = 2                     # in-game display scale
DIRS = [("SE", 45.0), ("E", 75.0)]
BALL_R = 5.5                 # the game ball: 11 art px across (ball.png), i.e. 4.4 model units at SCALE
BR = BALL_R / SCALE
ANK = 1.75                   # pixel3d: ankle height of a flat foot (model units)

TIMES = {                    # ms per frame (GIF units are 10 ms)
    "run": [50] * 12,
    "rundribble": [60] * 10,
    "dribble": [80, 70, 80, 70, 80, 70, 80, 70],
    "dunk": [80, 90, 70, 70, 100, 150, 60, 110, 150, 320],
}
# illustrative jump height for the preview only (art px); the game computes its own (jump_z, DUNK_VIEW_LIFT)
DUNK_LIFT = [0, 0, 4, 14, 20, 22, 21, 19, 15, 0]


# ----------------------------------------------------------------------------- helpers

def body_dims(p):
    legk = p["leg"]
    return {"l1": 8.6 * legk, "l2": 8.3 * legk, "hw": 2.3 * p["width"], "tk": p["torso"],
            "sw": 5.4 * p["width"]}


def spine(pose):
    return P.rot_y(math.radians(pose.get("twist", 0.0))) @ P.rot_x(math.radians(pose.get("lean", 4.0)))


def set_legs(pose, dims, pelvis_y, feet, pole_fwd=1.0):
    """feet: {"L": (ankle point in body space, foot dir)}; the pelvis sits at (0, pelvis_y, 0). Sets thigh/shin/foot
    and 'jump' so pixel3d.build puts the pelvis exactly at pelvis_y (it grounds the lowest ankle otherwise)."""
    lowest = 1e9
    for side, sx in (("L", 1.0), ("R", -1.0)):
        ank, fdir = feet[side]
        hip = np.array([sx * dims["hw"], pelvis_y - 0.9, 0.0])
        ank = np.asarray(ank, float)
        pole = P.unit(sx * 0.18, -0.15, pole_fwd)
        knee = P.ik(hip, ank, dims["l1"], dims["l2"], pole)
        td = P.unit(*(knee - hip))
        sd = P.unit(*(ank - knee))
        pose["thigh_" + side] = tuple(td)
        pose["shin_" + side] = tuple(sd)
        pose["foot_" + side] = tuple(fdir)
        rel_ank = np.array([sx * dims["hw"], -0.9, 0.0]) + td * dims["l1"] + sd * dims["l2"]
        lowest = min(lowest, rel_ank[1])
    pose["jump"] = pelvis_y - (ANK - lowest)
    return pose


def set_hand(pose, side, pt, pelvis_y, pole):
    """Hand target given in body space (floor at y = 0); pixel3d wants it spine-local, pelvis-relative."""
    Rs = spine(pose)
    pose["hand_" + side] = tuple(Rs.T @ (np.asarray(pt, float) - np.array([0.0, pelvis_y, 0.0])))
    pose["pole_" + side] = pole


def arm_swing(pose, side, ang, bend, out=0.16):
    sx = 1.0 if side == "L" else -1.0
    pose["upper_" + side] = M.d(ang, sx * out)
    pose["fore_" + side] = M.d(ang + bend, sx * 0.03)


def cr(p0, p1, p2, p3, t):
    """Catmull-Rom between p1 and p2."""
    p0, p1, p2, p3 = [np.asarray(v, float) for v in (p0, p1, p2, p3)]
    t2, t3 = t * t, t * t * t
    return 0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)


def periodic_spline(keys, ph):
    """keys: [(phase, values...)] sorted in [0, 1); closed loop."""
    n = len(keys)
    ph = ph % 1.0
    for i in range(n):
        a = keys[i]
        b = keys[(i + 1) % n]
        pa, pb = a[0], b[0] + (1.0 if i == n - 1 else 0.0)
        q = ph if ph >= pa else ph + 1.0
        if pa <= q < pb:
            t = (q - pa) / (pb - pa)
            k0 = keys[(i - 1) % n][1:]
            k3 = keys[(i + 2) % n][1:]
            return cr(k0, a[1:], b[1:], k3, t)
    return np.asarray(keys[0][1:], float)


# ----------------------------------------------------------------------------- run legs (shared by run and rundribble)

STANCE = 0.36                # share of the cycle a foot is on the floor (the rest: swing; both up = flight)


def run_foot(ph, L, stride=1.0):
    """Ankle (z forward, y up) and foot pitch (+ = toe up) for a leg at cycle phase ph; contact at ph = 0."""
    zc, zt = 0.30 * L * stride, -0.44 * L * stride
    ph = ph % 1.0
    if ph < STANCE:
        u = ph / STANCE
        z = zc + (zt - zc) * u
        heel = max(0.0, (u - 0.62) / 0.38)            # the heel peels up late in the stance
        y = ANK + 1.6 * heel * heel
        pitch = 0.1 - 1.0 * heel if u > 0.62 else 0.1 * (1.0 - u / 0.3) if u < 0.3 else 0.0
        return z, y, pitch
    # swing: kick up behind, knee drives through, reach, down onto the heel
    keys = [(STANCE, zt, ANK + 1.6, -0.9),
            (0.50, -0.46 * L * stride, 0.36 * L, -1.1),    # heel kicks up behind
            (0.64, -0.10 * L * stride, 0.46 * L, -0.7),    # knee drives through, foot tucked under the seat
            (0.78, 0.26 * L * stride, 0.30 * L, 0.0),     # reaching
            (0.90, 0.36 * L * stride, 0.10 * L, 0.35),
            (1.00, zc, ANK, 0.1)]
    for i in range(len(keys) - 1):
        a, b = keys[i], keys[i + 1]
        if a[0] <= ph <= b[0]:
            t = (ph - a[0]) / (b[0] - a[0])
            k0 = keys[i - 1] if i > 0 else (STANCE - 0.1, zt + 0.1 * L, ANK, 0.0)
            k3 = keys[i + 2] if i + 2 < len(keys) else (1.1, zc - 0.07 * L, ANK, 0.0)
            v = cr(k0[1:], a[1:], b[1:], k3[1:], t)
            return float(v[0]), max(ANK, float(v[1])), float(v[2])
    return zc, ANK, 0.1


def run_legs(pose, dims, ph, stride=1.0, sink=0.0):
    L = dims["l1"] + dims["l2"]
    feet = {}
    for side, sx, off in (("L", 1.0, 0.0), ("R", -1.0, 0.5)):
        z, y, pitch = run_foot(ph + off, L, stride)
        feet[side] = ((sx * (dims["hw"] + 0.2), y, z), (sx * 0.08, pitch, 1.0))
    # pelvis: lowest just after each contact (mid-stance), highest in the flight between the steps
    h0 = ANK + 0.9 + 0.90 * L - sink
    pelvis_y = h0 - 0.035 * L * math.cos(4 * math.pi * (ph - 0.17))
    set_legs(pose, dims, pelvis_y, feet)
    return pelvis_y


def run_pose(k, dims, n=12):
    ph = k / n
    p = {"lean": 18.0, "head_up": 17.0}
    run_legs(p, dims, ph)
    # arms swing opposite to the leg on their side; the left leg is fully forward around ph = 0.95
    s = math.cos(2 * math.pi * (ph - 0.45))        # +1: left arm fully forward
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        a = 6.0 + 44.0 * sgn * s
        bend = 72.0 + 30.0 * max(0.0, sgn * s)       # elbow closes on the forward swing
        arm_swing(p, side, a, bend)
    p["twist"] = -9.0 * s                          # shoulders turn with the arms
    p["head_yaw"] = 7.0 * s                        # the head keeps looking ahead
    return p, None


# ----------------------------------------------------------------------------- dribbles

def ball_free(ph, rel, floor_ph, catch_ph, b0, fl, b1, push=0.45):
    """Ball centre between release (phase rel, point b0), floor (floor_ph, fl) and catch (catch_ph, b1)."""
    b0, fl, b1 = [np.asarray(v, float) for v in (b0, fl, b1)]
    if ph <= floor_ph:
        u = (ph - rel) / (floor_ph - rel)
        f = push * u + (1 - push) * u * u           # pushed: already moving down at the release, then accelerating
        return b0 + (fl - b0) * f
    u = (ph - floor_ph) / (catch_ph - floor_ph)
    f = 1 - (1 - u) * (1 - u) * 0.85 - 0.15 * (1 - u)   # fast off the floor, slowing into the hand
    return fl + (b1 - fl) * f


def rundribble_pose(k, dims, n=10):
    """Running dribble, right hand: push at ph 0..0.15, floor at 0.4 (ahead), back into the hand at 0.92."""
    ph = k / n
    p = {"lean": 15.0, "head_up": 16.0}
    pelvis_y = run_legs(p, dims, ph + 0.92, stride=0.92, sink=0.3)
    s = math.cos(2 * math.pi * (ph + 0.92 - 0.45))
    a = 6.0 + 36.0 * s                             # off (left) arm still swings with the stride, a bit out
    arm_swing(p, "L", a, 70.0 + 26.0 * max(0.0, s), out=0.3)
    p["twist"] = -6.0 * s - 6.0                    # a little turned toward the ball side
    p["head_yaw"] = 6.0 * s + 6.0
    hx = -(dims["sw"] + 4.8)
    # hand path (body space): top/catch, push, follow-through low and ahead, back up, waiting, catch
    hand_keys = [(0.00, hx, 20.6, 5.6),
                 (0.10, hx, 18.6, 7.6),
                 (0.20, hx - 0.3, 16.4, 9.0),          # release with the wrist snapped down
                 (0.32, hx - 0.4, 15.4, 8.8),          # follow-through, arm long
                 (0.50, hx - 0.2, 18.0, 6.6),
                 (0.70, hx, 20.6, 5.2),
                 (0.86, hx, 20.4, 5.6),                # meets the ball on its way up
                 ]
    hand = periodic_spline(hand_keys, ph)
    under = np.array([0.0, -(BR + 1.5), 0.6])        # palm on the top-back of the ball
    rel, floor_ph, catch_ph = 0.17, 0.40, 0.90
    fl = np.array([hx - 0.8, BR, 9.5])
    if ph < rel or ph >= catch_ph:   # in the hand: pushed down, or carried up after the catch
        ball = hand + under
    else:
        b0 = periodic_spline(hand_keys, rel) + under
        b1 = periodic_spline(hand_keys, catch_ph) + under
        ball = ball_free(ph, rel, floor_ph, catch_ph, b0, fl, b1)
    set_hand(p, "R", hand, pelvis_y, (-1, -0.3, -0.5))
    return p, ball


def dribble_pose(k, dims, n=8):
    """Standing dribble in a low stance: push at 0..0.2, floor at 0.5, catch at 0.85; the hips sink and shift onto
    the ball side with the push and come back with the catch."""
    ph = k / n
    # weight: 0 at the catch (up, centred), 1 just after the floor touch (low, over the ball-side foot)
    w = periodic_spline([(0.0, 0.15), (0.2, 0.7), (0.45, 1.0), (0.7, 0.6), (0.85, 0.2)], ph)[0]
    root = np.array([-1.4 * w + 0.6, 0.0, 0.3 * w])        # pelvis over the right (ball-side) foot as he pushes
    p = {"lean": 22.0 + 4.0 * w, "head_up": 20.0 + 4.0 * w, "twist": -12.0 - 5.0 * w, "head_yaw": 10.0 + 4.0 * w}
    L = dims["l1"] + dims["l2"]
    pelvis_y = ANK + 0.9 + 0.80 * L - 1.1 * w
    # feet planted in the world (the sprite root moves instead): left foot forward, right foot back and wide
    feet_w = {"L": (dims["hw"] + 3.2, ANK, 4.0), "R": (-(dims["hw"] + 3.4), ANK, -3.4)}
    feet = {}
    for side, sx in (("L", 1.0), ("R", -1.0)):
        f = np.array(feet_w[side]) - root
        feet[side] = (tuple(f), (sx * 0.35, 0.0, 1.0))
    set_legs(p, dims, pelvis_y, feet, pole_fwd=0.8)
    # off arm up in front as a guard (elbow bent), rocking a little against the hips
    p["reach_L"] = ((0.60, -0.30 - 0.10 * w, 0.74), 0.60 + 0.05 * w)
    p["pole_L"] = (1, -0.7, -0.3)
    hx = -(dims["sw"] + 4.4)
    hand_keys = [(0.00, hx, 18.8, 4.8),
                 (0.10, hx, 17.4, 5.4),
                 (0.20, hx - 0.2, 15.6, 5.8),    # release
                 (0.32, hx - 0.3, 14.4, 5.6),    # wrist down, follow-through
                 (0.55, hx, 16.6, 4.8),
                 (0.75, hx, 18.4, 4.6),
                 (0.88, hx, 18.2, 4.8)]          # catch
    hand = periodic_spline(hand_keys, ph) - root
    under = np.array([0.0, -(BR + 1.5), 0.4])
    rel, floor_ph, catch_ph = 0.2, 0.5, 0.86
    fl = np.array([hx - 0.6, BR, 5.6]) - root
    if ph < rel or ph >= catch_ph:
        ball = hand + under
    else:
        b0 = periodic_spline(hand_keys, rel) - root + under
        b1 = periodic_spline(hand_keys, catch_ph) - root + under
        ball = ball_free(ph, rel, floor_ph, catch_ph, b0, fl, b1, push=0.5)
    set_hand(p, "R", hand, pelvis_y, (-1, -0.4, -0.6))
    p["_root"] = root
    return p, ball


# ----------------------------------------------------------------------------- dunk

def two_hands(p, ball, pelvis_y, back=0.6, poles=((1, -0.5, -0.3), (-1, -0.5, -0.3)), spread=None):
    """Both hands on the ball's sides (a little behind its centre)."""
    s = (BR + 0.5) if spread is None else spread
    b = np.asarray(ball, float)
    set_hand(p, "L", b + np.array([s, 0.3, -back]), pelvis_y, poles[0])
    set_hand(p, "R", b + np.array([-s, 0.3, -back]), pelvis_y, poles[1])


def dunk_pose(k, dims):
    L = dims["l1"] + dims["l2"]
    hw = dims["hw"]
    flat = lambda sx: (sx * 0.12, 0.0, 1.0)
    point = lambda sx, t=0.9: (sx * 0.1, -t, 0.6)
    if k == 0:      # gather: long last step, ball brought to the right hip with both hands
        p = {"lean": 18.0, "head_up": 18.0, "twist": -10.0}
        py = ANK + 0.9 + 0.80 * L
        set_legs(p, dims, py, {"L": ((hw + 0.3, ANK, 0.30 * L), flat(1)),
                               "R": ((-hw - 0.3, ANK + 1.2, -0.30 * L), (-0.1, -0.7, 1.0))})
        ball = np.array([-3.4, py + 1.0, 4.6])
        two_hands(p, ball, py, back=0.2)
    elif k == 1:    # load: both feet down, deep knee bend, ball low between the knees, chest over the toes
        p = {"lean": 30.0, "head_up": 28.0}
        py = ANK + 0.9 + 0.64 * L
        set_legs(p, dims, py, {"L": ((hw + 0.9, ANK, 2.6), flat(1)), "R": ((-hw - 0.9, ANK, -1.4), flat(-1))})
        ball = np.array([-0.6, py - 1.2, 7.0])
        two_hands(p, ball, py, back=0.4, poles=((1, 0.2, -0.6), (-1, 0.2, -0.6)))
    elif k == 2:    # takeoff: left leg drives off (toe last), right knee punches up, ball swinging up past the chin
        p = {"lean": 6.0, "head_up": 22.0}
        py = ANK + 0.9 + 0.93 * L
        set_legs(p, dims, py, {"L": ((hw * 0.8, ANK + 1.4, -0.22 * L), point(1, 1.0)),
                               "R": ((-hw, py - 0.9 - 0.30 * L, 0.36 * L), (-0.1, -0.5, 1.0))})
        ball = np.array([-1.0, py + 9.0, 7.6])
        two_hands(p, ball, py, back=0.6, poles=((1, -0.7, -0.2), (-1, -0.7, -0.2)))
    elif k == 3:    # rise: ball overhead at full reach, body long, knees coming up
        p = {"lean": -2.0, "head_up": 22.0, "shrug": 1.4}
        py = ANK + 0.9 + 0.84 * L
        set_legs(p, dims, py, {"L": ((hw * 0.9, ANK + 1.0, -0.08 * L), point(1)),
                               "R": ((-hw * 0.9, ANK + 3.6, 0.12 * L), point(-1, 0.6))})
        ball = np.array([0.0, py + 29.0, 1.6])
        two_hands(p, ball, py, back=0.3, poles=((1, -0.5, 0.2), (-1, -0.5, 0.2)))
    elif k in (4, 5):   # cock behind the head (top of the jump), back arched, heels kicked up behind; 5 = hang
        h = 0.0 if k == 4 else 1.0
        p = {"lean": -10.0 - 2.0 * h, "head_up": 24.0, "shrug": 1.8}
        py = ANK + 0.9 + 0.80 * L
        set_legs(p, dims, py, {"L": ((hw * 0.9, ANK + 3.4 + h, -0.20 * L - h), point(1)),
                               "R": ((-hw * 0.9, ANK + 5.0 + h, -0.12 * L), point(-1))})
        ball = np.array([0.0, py + 22.5 + 0.4 * h, -6.6 - 0.6 * h])
        two_hands(p, ball, py, back=-0.2, poles=((1, 0.6, 0.6), (-1, 0.6, 0.6)))
    elif k == 6:    # slam: arms whip over and down through the rim, body jack-knifes, knees forward
        p = {"lean": 16.0, "head_up": 10.0, "shrug": 1.0}
        py = ANK + 0.9 + 0.78 * L
        set_legs(p, dims, py, {"L": ((hw * 0.9, ANK + 3.2, 0.18 * L), point(1, 0.7)),
                               "R": ((-hw * 0.9, ANK + 1.6, 0.04 * L), point(-1, 0.8))})
        ball = np.array([0.0, py + 20.5, 11.0])
        two_hands(p, ball, py, back=1.0, poles=((1, -0.4, -0.3), (-1, -0.4, -0.3)))
    elif k in (7, 8):   # 7: hands on the rim right after the slam, knees still up; 8: hanging long, toes down
        h = 0.0 if k == 7 else 1.0
        p = {"lean": 12.0 - 15.0 * h, "head_up": 16.0 + 8.0 * h, "shrug": 1.5 + 0.5 * h}
        py = ANK + 0.9 + 0.86 * L
        if k == 7:
            feet = {"L": ((hw * 0.9, ANK + 4.2, 0.22 * L), point(1, 0.6)),
                    "R": ((-hw * 0.9, ANK + 2.4, 0.12 * L), point(-1, 0.7))}
        else:
            feet = {"L": ((hw * 0.8, ANK + 0.9, -0.06 * L), point(1, 1.0)),
                    "R": ((-hw * 0.8, ANK + 0.3, 0.02 * L), point(-1, 1.0))}
        set_legs(p, dims, py, feet)
        rim = np.array([0.0, py + 24.5 + 1.0 * h, 8.0])
        set_hand(p, "L", rim + np.array([3.4, 0.0, 0.0]), py, (1, -0.4, -0.2))
        set_hand(p, "R", rim + np.array([-3.4, 0.0, 0.0]), py, (-1, -0.4, -0.2))
        ball = None
    else:           # land: deep squash, arms out for balance
        p = {"lean": 20.0, "head_up": 20.0}
        py = ANK + 0.9 + 0.66 * L
        set_legs(p, dims, py, {"L": ((hw + 1.4, ANK, 2.0), flat(1)), "R": ((-hw - 1.4, ANK, -0.6), flat(-1))})
        p["reach_L"] = ((0.75, -0.45, 0.45), 0.72)
        p["reach_R"] = ((-0.75, -0.45, 0.45), 0.72)
        p["pole_L"], p["pole_R"] = (1, 0.3, -0.6), (-1, 0.3, -0.6)
        ball = None
    return p, ball


POSES = {"run": (run_pose, 12), "rundribble": (rundribble_pose, 10), "dribble": (dribble_pose, 8),
         "dunk": (dunk_pose, 10)}
ORDER = ["run", "rundribble", "dribble", "dunk"]


# ----------------------------------------------------------------------------- render

def cam_matrix(yaw):
    return P.rot_x(P.TILT) @ P.rot_y(math.radians(yaw))


def ball_in_front(cv, bx, by, bz):
    """The ball's layer for the frame: over the sprite if most body pixels it covers are behind its surface
    (a z-buffer vote against the renderer's depth; hands on the ball count too). No overlap: in front."""
    front = behind = 0
    for j in range(int(by - BALL_R) - 1, int(by + BALL_R) + 2):
        for i in range(int(bx - BALL_R) - 1, int(bx + BALL_R) + 2):
            if not (0 <= i < cv.w and 0 <= j < cv.h) or cv.pid[j, i] < 0:
                continue
            d2 = ((i + 0.5 - bx) ** 2 + (j + 0.5 - by) ** 2) / (SCALE * SCALE)
            if d2 >= BR * BR:
                continue
            if bz + math.sqrt(BR * BR - d2) > cv.z[j, i]:
                front += 1
            else:
                behind += 1
    return front >= behind


def render(p, anim, k, yaw, dims):
    fn, n = POSES[anim]
    pose, ball = fn(k, dims)
    root = pose.pop("_root", np.zeros(3))
    C = cam_matrix(yaw)
    rc = C @ root
    ox = FW / 2.0 + rc[0] * SCALE
    oy = FEET_Y - rc[1] * SCALE
    img, cv, info = P.render(p, pose, yaw, w=FW, h=FH, ox=ox, oy=oy, scale=SCALE)
    rec = {"hands": {}, "ball": None}
    for side in ("L", "R"):
        i, j, _ = cv.project(info["hands"][side])
        rec["hands"][side] = [i, j]
    if ball is not None:
        bc = C @ np.asarray(ball, float)
        bx = ox + bc[0] * SCALE
        by = oy - bc[1] * SCALE
        front = ball_in_front(cv, bx, by, bc[2])
        fc = C @ np.array([ball[0], 0.0, ball[2]])
        rec["ball"] = [round(bx, 1), round(by, 1), 1 if front else 0]
        rec["ball_floor"] = [round(ox + fc[0] * SCALE, 1), round(oy - fc[1] * SCALE, 1)]
        rec["ball_h"] = round(float(ball[1] - BR), 2)
    return img, rec


def pieces(img):
    a = np.array(img)[:, :, 3] > 0
    seen = np.zeros_like(a)
    n = 0
    H, W = a.shape
    for j, i in zip(*np.nonzero(a)):
        if seen[j, i]:
            continue
        n += 1
        st = [(j, i)]
        seen[j, i] = True
        while st:
            y, x = st.pop()
            for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= yy < H and 0 <= xx < W and a[yy, xx] and not seen[yy, xx]:
                    seen[yy, xx] = True
                    st.append((yy, xx))
    return n


# ----------------------------------------------------------------------------- composing

def font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except TypeError:
        return ImageFont.load_default()


def floor_bg(w, h):
    """The gym floor tile at the in-game 2x (read only), as the background."""
    if os.path.exists(FLOOR_TILE):
        t = Image.open(FLOOR_TILE).convert("RGBA")
        t = t.resize((t.width * SHOW, t.height * SHOW), Image.NEAREST)
        bg = Image.new("RGBA", (w, h))
        for y in range(0, h, t.height):
            for x in range(0, w, t.width):
                bg.paste(t, (x, y))
        return bg
    return Image.new("RGBA", (w, h), P.hexc("#c99a62") + (255,))


def ring_img(scale_k=SCALE):
    c = (64, 150, 255)
    w, h = int(40 * scale_k) + 2, 11
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx, cy, rx, ry = w / 2.0, h / 2.0, 10.5 * scale_k, 3.6 * scale_k
    for j in range(h):
        for i in range(w):
            dx, dy = (i + 0.5 - cx) / rx, (j + 0.5 - cy) / ry
            dd = math.sqrt(dx * dx + dy * dy)
            if 0.80 <= dd <= 1.0:
                px[i, j] = c + (215,)
            elif 0.62 <= dd < 0.80:
                px[i, j] = c + (110,)
            elif dd < 0.62:
                px[i, j] = (10, 10, 30, 70)
            elif dd <= 1.12:
                px[i, j] = c + (60,)
    return img


BALL_FRAMES = None


def ball_frame(i):
    global BALL_FRAMES
    if BALL_FRAMES is None:
        sh = Image.open(BALL_SHEET).convert("RGBA")
        BALL_FRAMES = [sh.crop((16 * k, 0, 16 * k + 16, 16)) for k in range(sh.width // 16)]
    return BALL_FRAMES[i % len(BALL_FRAMES)]


def shadow_img(w, h, alpha=70):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, w - 1, h - 1], fill=(20, 10, 30, alpha))
    return img


def draw_rim(cell, cx, cy, layer):
    """A simple rim + net (preview only). layer 'back' = far half of the ring, 'front' = near half and the net."""
    d = ImageDraw.Draw(cell)
    rx, ry = 8, 3
    box = [cx - rx, cy - ry, cx + rx, cy + ry]
    if layer == "back":
        d.arc(box, 180, 360, fill=(214, 84, 30, 255))
        # backboard edge behind
        d.rectangle([cx - 13, cy - 22, cx + 13, cy - 21], fill=(236, 236, 244, 255))
        d.rectangle([cx - 1, cy - 21, cx + 1, cy - ry - 1], fill=(120, 120, 140, 255))
    else:
        for t in range(-3, 4):
            x0 = cx + t * 2.4
            d.line([(x0, cy + 1), (cx + t * 1.4, cy + 10)], fill=(240, 240, 248, 200))
        d.line([(cx - 4, cy + 10), (cx + 4, cy + 10)], fill=(240, 240, 248, 200))
        d.arc(box, 0, 180, fill=(240, 110, 40, 255))


TOP = 26   # preview cells get this many art rows of headroom above the frame (the dunk's lift and the rim)


def compose_frame(img, rec, lift=0, ball_spin=0, ring=True, rim=None, ball_override=None, top=TOP):
    """One preview cell (FW x FH + top) with the ring, shadows, the sprite lifted by `lift` and the ball on its
    layer (front flag), as the game would draw them. Frame coordinates are shifted down by `top`."""
    cell = Image.new("RGBA", (FW, FH + top), (0, 0, 0, 0))
    if ring:
        r = ring_img()
        cell.alpha_composite(r, (FW // 2 - r.width // 2, top + FEET_Y - r.height // 2))
    if lift:
        cell.alpha_composite(shadow_img(18, 5, 60), (FW // 2 - 9, top + FEET_Y - 2))
    ball = ball_override if ball_override is not None else rec["ball"]
    bpos = None
    if ball is not None:
        bx, by, front = ball
        if ball_override is None:
            by -= lift
            fx, fy = rec["ball_floor"]
        else:
            fx, fy = bx, FEET_Y + 1
        hgt = max(0.0, fy - by)
        sw = max(5, int(10 - hgt / 6))
        cell.alpha_composite(shadow_img(sw, 3, 80), (int(round(fx - sw / 2)), top + int(round(fy - 1))))
        bpos = (int(round(bx)) - 8, top + int(round(by)) - 8)
    if rim is not None:
        draw_rim(cell, rim[0], top + rim[1], "back")
    if bpos is not None and not ball[2]:
        cell.alpha_composite(ball_frame(ball_spin), bpos)
    cell.alpha_composite(img, (0, top - lift))
    if bpos is not None and ball[2]:
        cell.alpha_composite(ball_frame(ball_spin), bpos)
    if rim is not None:
        draw_rim(cell, rim[0], top + rim[1], "front")
    return cell


def dunk_extras(frames_dir):
    """Rim position (from the hands on the rim in frame 7) and the free ball after the slam, per direction."""
    out = {}
    for dname, _ in DIRS:
        recs = frames_dir[dname]
        h7 = recs[7][1]["hands"]
        rx = (h7["L"][0] + h7["R"][0]) / 2.0
        ry = (h7["L"][1] + h7["R"][1]) / 2.0 - DUNK_LIFT[7] + 1
        h8 = recs[8][1]["hands"]
        ex_lift8 = DUNK_LIFT[7] + ((h8["L"][1] + h8["R"][1]) - (h7["L"][1] + h7["R"][1])) / 2.0
        balls = {7: [rx + 1, ry + 4, 1], 8: [rx + 1, ry + 14, 1], 9: [rx + 2, FEET_Y - 20, 1]}
        out[dname] = {"rim": (int(round(rx)), int(round(ry))), "balls": balls, "lift8": int(round(ex_lift8))}
    return out


# ----------------------------------------------------------------------------- outputs

def gif_save(frames, durs, path):
    """Quantize every frame to one shared palette (no dithering: pixel art) and write a looping GIF."""
    w, h = frames[0].size
    strip = Image.new("RGB", (w, h * len(frames)))
    for i, f in enumerate(frames):
        strip.paste(f.convert("RGB"), (0, h * i))
    pal = strip.quantize(colors=255, method=Image.MEDIANCUT, dither=Image.Dither.NONE)
    q = [f.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE) for f in frames]
    q[0].save(path, save_all=True, append_images=q[1:], duration=durs, loop=0, optimize=False, disposal=1)


def label(dr, xy, txt, sz=14, fill=(250, 244, 230)):
    x, y = xy
    dr.text((x + 1, y + 1), txt, font=font(sz), fill=(20, 14, 26))
    dr.text((x, y), txt, font=font(sz), fill=fill)


def anim_cells(anim, data, extras, t_ms, top=TOP):
    """The cell images (one per direction) of `anim` at time t (ms, looping)."""
    durs = TIMES[anim]
    total = sum(durs)
    t = t_ms % total
    k = 0
    acc = 0
    while acc + durs[k] <= t:
        acc += durs[k]
        k += 1
    cells = []
    for dname, _ in DIRS:
        img, rec = data[dname][k]
        spin = int(t_ms / 60)
        if anim == "dunk":
            ex = extras[dname]
            bo = ex["balls"].get(k)
            if k == 9:   # the ball bounces away during the landing hold
                u = (t - acc) / durs[k]
                bo = [ex["rim"][0] + 9 + 8 * u, FEET_Y - 6 - 16 * abs(math.sin(math.pi * (0.2 + 1.3 * u))) * (1 - 0.4 * u), 1]
            lift = ex["lift8"] if k == 8 else DUNK_LIFT[k]   # 8 hangs from the same rim
            cells.append(compose_frame(img, rec, lift=lift, ball_spin=spin, rim=ex["rim"], ball_override=bo))
        else:
            cells.append(compose_frame(img, rec, ball_spin=spin, top=top))
    return cells, k


def event_times(loops):
    """All frame-change times (ms) within the LCM loop of the given [durations] lists."""
    total = 1
    for d in loops:
        s = sum(d)
        total = total * s // math.gcd(total, s)
    ts = set()
    for d in loops:
        s = sum(d)
        for rep in range(total // s):
            acc = rep * s
            for x in d:
                ts.add(acc)
                acc += x
    ts = sorted(ts)
    return ts, total


def anim_gif(anim, data, extras, path):
    pad = 8
    head = 22
    w = (FW * SHOW) * len(DIRS) + pad * (len(DIRS) + 1)
    top = TOP if anim == "dunk" else 0      # headroom only for the jump
    h = (FH + top) * SHOW + head + pad
    frames, durs = [], []
    acc = 0
    for k, dur in enumerate(TIMES[anim]):
        cells, _ = anim_cells(anim, data, extras, acc, top)
        if anim == "dunk" and k == 9:   # split the landing hold so the bouncing ball moves
            sub = 4
            for s_ in range(sub):
                cells, _ = anim_cells(anim, data, extras, acc + dur * s_ / sub, top)
                frames.append(_panel(cells, w, h, pad, head, anim))
                durs.append(dur // sub)
        else:
            frames.append(_panel(cells, w, h, pad, head, anim))
            durs.append(dur)
        acc += dur
    gif_save(frames, durs, path)


def _panel(cells, w, h, pad, head, anim):
    bg = floor_bg(w, h)
    dr = ImageDraw.Draw(bg)
    dr.rectangle([0, 0, w, head - 4], fill=(28, 26, 38, 255))
    n = POSES[anim][1]
    label(dr, (6, 3), "%s, %d frames: SE | E" % (anim, n), 13)
    for c, cell in enumerate(cells):
        big = cell.resize((cell.width * SHOW, cell.height * SHOW), Image.NEAREST)
        bg.alpha_composite(big, (pad + c * (FW * SHOW + pad), head))
    return bg


def current_frames():
    """Today's sheet: E run (6) and SE dribble (4), with the ball placed like ball.gd does (approximate)."""
    sh = Image.open(CUR_SHEET).convert("RGBA")
    hands = json.load(open(CUR_HANDS))["players"][PLAYER]
    run = [sh.crop(((2 + k) * 40, 2 * 64, (3 + k) * 40, 3 * 64)) for k in range(6)]
    drib = [(sh.crop(((8 + k) * 40, 64, (9 + k) * 40, 128)), hands[1][8 + k]["R"]) for k in range(4)]
    return run, drib


def current_cell(kind, frames, t_ms):
    """A 2x cell for today's animation at time t: run 6 x 100 ms, dribble 4 x 150 ms (game: 11 and 7 fps)."""
    cw, chh = 40, 64
    cell = Image.new("RGBA", (cw + 8, chh), (0, 0, 0, 0))
    r = ring_img(1.0)
    cell.alpha_composite(r, ((cw + 8) // 2 - r.width // 2, 59 - r.height // 2 - 1))
    if kind == "run":
        k = int(t_ms // 100) % 6
        cell.alpha_composite(frames[k], (4, 0))
    else:
        k = int(t_ms // 150) % 4
        img, hand = frames[k]
        cell.alpha_composite(img, (4, 0))
        frac = abs(math.cos(math.pi * (t_ms % 600) / 600.0))     # ball.gd: lerp(bottom, top, frac) on its own clock
        top = hand[1] + 5.5 * 0.7
        bottom = 59 + 2 - 5.5
        by = bottom + (top - bottom) * frac
        bx = hand[0] + 4
        cell.alpha_composite(shadow_img(8, 3, 80), (int(bx) - 4, 61))
        cell.alpha_composite(ball_frame(int(t_ms / 60)), (int(round(bx)) - 8, int(round(by)) - 8))
    return cell.resize((cell.width * SHOW, cell.height * SHOW), Image.NEAREST)


def compare_gif(all_data, extras, path):
    cur_run, cur_drib = current_frames()
    loops = [TIMES[a] for a in ORDER] + [[100] * 6, [150] * 4]
    _, total = event_times(loops)
    # a fixed 20 ms tick (browsers slow down GIF delays under 20 ms); every change lands within 10 ms of its time
    ts = list(range(0, total, 20))
    pad = 10
    head = 40
    cw_new = FW * SHOW
    cw_cur = (40 + 8) * SHOW
    w = pad + 4 * (cw_new + pad) + 14 + 2 * (cw_cur + pad)
    h = head + (FH + TOP) * SHOW + pad
    frames, durs = [], []
    for i, t in enumerate(ts):
        nxt = ts[i + 1] if i + 1 < len(ts) else total
        bg = floor_bg(w, h)
        dr = ImageDraw.Draw(bg)
        dr.rectangle([0, 0, w, head - 6], fill=(28, 26, 38, 255))
        x = pad
        for a in ORDER:
            cells, _ = anim_cells(a, all_data[a], extras, t)
            big = cells[0].resize((cw_new, (FH + TOP) * SHOW), Image.NEAREST)
            bg.alpha_composite(big, (x, head))
            label(dr, (x + 4, 4), "NEW " + a, 13)
            label(dr, (x + 4, 19), "%d frames, SE" % POSES[a][1], 11, (190, 196, 220))
            x += cw_new + pad
        dr.rectangle([x, head - 6, x + 3, h], fill=(28, 26, 38, 255))
        x += 14
        y_cur = head + (TOP + FEET_Y - 59) * SHOW     # today's frames on the same floor line
        for kind, fr, lab in (("run", cur_run, "NOW run"), ("dribble", cur_drib, "NOW dribble")):
            bg.alpha_composite(current_cell(kind, fr, t), (x, y_cur))
            label(dr, (x + 4, 4), lab, 13, (255, 210, 120))
            label(dr, (x + 4, 19), "%s" % ("6 frames, E" if kind == "run" else "4 frames, SE"), 11, (190, 196, 220))
            x += cw_cur + pad
        if frames and np.array_equal(np.asarray(frames[-1]), np.asarray(bg)):
            durs[-1] += nxt - t        # nothing moved this tick
        else:
            frames.append(bg)
            durs.append(nxt - t)
    gif_save(frames, durs, path)
    return total, len(frames)


def contact_sheet(all_data, extras, path, zoom=3):
    rows = [(a, d) for a in ORDER for d, _ in DIRS]
    maxn = max(POSES[a][1] for a in ORDER)
    lw = 120
    head = 30
    cw = FW + 2
    w = lw + maxn * cw + 4
    h = head // zoom + len(rows) * (FH + 12) + 4
    # draw at 1x then zoom, labels at the zoomed size
    base = floor_bg(w * SHOW, h * SHOW).resize((w, h), Image.NEAREST)
    dr = ImageDraw.Draw(base)
    dr.rectangle([0, 0, lw - 6, h], fill=(28, 26, 38, 255))
    ys = []
    for r, (a, dname) in enumerate(rows):
        y0 = head // zoom + r * (FH + 12) + 10
        ys.append(y0)
        for k, (img, rec) in enumerate(all_data[a][dname]):
            x0 = lw + k * cw
            cell = compose_frame(img, rec, ball_spin=k, top=0)
            dr.rectangle([x0, y0, x0 + FW - 1, y0 + FH - 1], outline=(150, 110, 70, 255))
            base.alpha_composite(cell, (x0, y0))
            # hand points (1 px marks): R red, L cyan; ball centre yellow
            for side, col in (("R", (255, 40, 60, 255)), ("L", (40, 230, 255, 255))):
                hx, hy = rec["hands"][side]
                if 0 <= hx < FW and 0 <= hy < FH:
                    base.putpixel((x0 + hx, y0 + hy), col)
    big = base.resize((w * zoom, h * zoom), Image.NEAREST)
    dr = ImageDraw.Draw(big)
    label(dr, (10, 8), "Animation style sample v1: Deuce, frame %dx%d art px (feet row %d), shown 3x; the game draws "
                       "2x. Ball = the game's ball at the stored point; dots: R hand red, L hand cyan. Dunk frames "
                       "keep the feet on the floor (the game adds the jump)." % (FW, FH, FEET_Y), 18)
    for r, (a, dname) in enumerate(rows):
        y = ys[r] * zoom
        label(dr, (12, y + 40), a, 20)
        label(dr, (12, y + 66), dname, 18, (190, 196, 220))
        label(dr, (12, y + 90), "%d frames" % POSES[a][1], 15, (190, 196, 220))
        label(dr, (12, y + 110), "ms: " + "/".join(str(x) for x in TIMES[a]) if len(set(TIMES[a])) > 1 else "%d ms each" % TIMES[a][0], 13, (190, 196, 220))
        for k in range(POSES[a][1]):
            label(dr, ((lw + k * (FW + 2)) * zoom + 4, y + 2), str(k), 14)
    big.convert("RGB").save(path, optimize=True)


def main(argv):
    dump = argv[argv.index("--frames") + 1] if "--frames" in argv else None
    pl = [p for p in M.load_players() if p["id"] == PLAYER][0]
    dims = body_dims(pl)
    all_data = {}
    points = {"_help": "Per animation and direction, per frame: hands {L, R: [x, y]} and ball [x, y, front] in art "
                       "px of a %dx%d frame (feet row %d); front 1 = draw the ball over the sprite. ball_h = the "
                       "ball's bottom above the floor (model units)." % (FW, FH, FEET_Y),
              "frame": [FW, FH], "feet_row": FEET_Y, "scale": SCALE, "times_ms": TIMES, "anims": {}}
    probs = []
    for a in ORDER:
        all_data[a] = {}
        points["anims"][a] = {}
        for dname, yaw in DIRS:
            seq = []
            for k in range(POSES[a][1]):
                img, rec = render(pl, a, k, yaw, dims)
                al = np.array(img)[:, :, 3] > 0
                if al[0].any() or al[-1].any() or al[:, 0].any() or al[:, -1].any():
                    probs.append("%s %s %d: touches the frame edge" % (a, dname, k))
                n = pieces(img)
                if n != 1:
                    probs.append("%s %s %d: %d pieces" % (a, dname, k, n))
                ys = np.nonzero(al.any(axis=1))[0]
                rec["bbox_y"] = [int(ys.min()), int(ys.max())]
                seq.append((img, rec))
                if dump:
                    os.makedirs(dump, exist_ok=True)
                    compose_frame(img, rec, ring=False, top=0).save(os.path.join(dump, "%s_%s_%02d.png" % (a, dname, k)))
                    img.save(os.path.join(dump, "raw_%s_%s_%02d.png" % (a, dname, k)))
            all_data[a][dname] = seq
            points["anims"][a][dname] = [{k2: v for k2, v in r.items()} for _, r in seq]
    extras = dunk_extras(all_data["dunk"])
    for a in ORDER:
        anim_gif(a, all_data[a], extras, os.path.join(OUT, "anim_sample_v1_%s.gif" % a))
    total, nf = compare_gif(all_data, extras, os.path.join(OUT, "anim_sample_v1_compare.gif"))
    contact_sheet(all_data, extras, os.path.join(OUT, "anim_sample_v1_sheet.png"))
    with open(os.path.join(OUT, "anim_sample_v1_points.json"), "w") as f:
        json.dump(points, f, separators=(",", ":"))
    for fn in sorted(os.listdir(OUT)):
        if fn.startswith("anim_sample_v1"):
            print("wrote docs/art/%s %d bytes" % (fn, os.path.getsize(os.path.join(OUT, fn))))
    print("compare loop %d ms, %d frames" % (total, nf))
    tops = {a: min(r["bbox_y"][0] for d in all_data[a].values() for _, r in d) for a in ORDER}
    print("highest row per anim:", tops)
    for s in probs:
        print("CHECK", s)
    print("checks: %d problem(s)" % len(probs))


if __name__ == "__main__":
    main(sys.argv[1:])
