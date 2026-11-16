#!/usr/bin/env python3
"""Player sprite sheets for Road Trip Hoops (original art, generated; no downloaded assets).

Reads the players' parts from tools/art/crews.json and renders each one with the style-sample renderer
(tools/art/pixel3d.py) into one sheet per player, in the layout fixed on docs/BOARD.md:

- assets/players/<id>.png, frame 40 x 64 px, feet on row 59, no ball and no ring baked in.
- 5 rows = drawn directions: 0 S (facing the camera), 1 SE, 2 E, 3 NE, 4 N (back to the camera).
  SW, W, NW are rows 1, 2, 3 mirrored. E = +x on screen.
- 37 columns: idle 0 (2), run 2 (6), dribble 8 (4), shoot 12 (4), dunk 16 (5), layup 21 (3), block 24 (3),
  poke 27 (2), stumble 29 (2), pass 31 (2), celebrate 33 (4).  Sheet 1480 x 320.
Part 1 (P4-03) drew idle, run and dribble; part 2 (P4-09) draws the rest, so all 37 columns are real frames.
Airborne frames (shoot, dunk, layup, block) keep the feet on the floor row: the game adds the jump height.
Also writes assets/players/hands.json: the hand points per player, row and column (frame pixels), so the game can
put the ball in the hand (shoot and pass: both hands; dunk and layup: "R", the near hand when facing E; dribble "R").

Usage:  python3 tools/art/make_players.py [--preview-only] [--only ID]
Output: assets/players/<id>.png, assets/players/hands.json, docs/art/players_preview_v1.png (part 1 view) and
        docs/art/players_preview_v2.png (every animation, not exported)
Needs:  Pillow, numpy
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import pixel3d as P

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CREWS = os.path.join(ROOT, "tools", "art", "crews.json")
OUT_DIR = os.path.join(ROOT, "assets", "players")
PREVIEW = os.path.join(ROOT, "docs", "art", "players_preview_v1.png")
PREVIEW2 = os.path.join(ROOT, "docs", "art", "players_preview_v2.png")
HANDS = os.path.join(ROOT, "assets", "players", "hands.json")

FW, FH = P.FRAME_W, P.FRAME_H          # 40 x 64
# row, body yaw (0 = facing the camera). E is turned 15 degrees toward the camera like the approved sample's side
# view (a pure profile is too thin to read at this size); SE and NE are the true diagonals.
DIRS = [("S", 0.0), ("SE", 45.0), ("E", 75.0), ("NE", 135.0), ("N", 180.0)]
ANIMS = [  # name, start column, frames (board contract; do not reorder)
    ("idle", 0, 2), ("run", 2, 6), ("dribble", 8, 4), ("shoot", 12, 4), ("dunk", 16, 5), ("layup", 21, 3),
    ("block", 24, 3), ("poke", 27, 2), ("stumble", 29, 2), ("pass", 31, 2), ("celebrate", 33, 4),
]
COLS = 37
DRAWN = [a for a, _, _ in ANIMS]      # every animation is drawn (part 2)


# ----------------------------------------------------------------------------- parts -> renderer dict

def load_players(path=CREWS):
    with open(path) as f:
        data = json.load(f)
    pals = data["palettes"]
    for k, v in data.get("skins", {}).items():
        P.SKINS[k] = v
    out = []
    for e in data["players"]:
        p = {"crew": e["crew"], "number": int(e["number"]), "id": e["id"],
             "beard": bool(e.get("beard", False)), "goatee": bool(e.get("goatee", False)),
             "headband": bool(e.get("headband", False))}
        p.update(data["bodies"][e["body"]])
        for k, v in e.get("body_tweak", {}).items():
            p[k] = p[k] + v
        for k, v in e.items():
            if k in p or k in ("body", "body_tweak", "_note"):
                continue
            if k.endswith("_pal") or k in ("shorts_trim", "shoe_acc"):
                v = pals[v] if isinstance(v, str) else v
            p[k] = v
        p.setdefault("sleeve", None)
        p.setdefault("tight", None)
        p["label"] = "#%d %s" % (p["number"], e.get("role", ""))
        p["ring"] = tuple(data["crews"][e["crew"]]["ring"])
        out.append(p)
    return out


# ----------------------------------------------------------------------------- poses
# Body space: x = the player's left, y = up, z = facing. Directions are unit-ish vectors (normalized by the renderer).

def d(a_deg, side_x=0.0):
    """A limb direction swung forward by a_deg from straight down (negative = backward)."""
    a = math.radians(a_deg)
    return (side_x, -math.cos(a), math.sin(a))


def idle_pose(k):
    """Two-frame breathing idle: frame 1 sinks a little and lifts the shoulders."""
    p = dict(P_STAND)
    if k == 1:
        p["shrug"] = 0.45
        p["lean"] = 6
        p["thigh_L"] = (0.16, -1, 0.17)
        p["thigh_R"] = (-0.16, -1, 0.17)
        p["shin_L"] = (0.02, -1, -0.19)
        p["shin_R"] = (-0.02, -1, -0.19)
    return p


P_STAND = {
    "lean": 4, "head_up": 6, "thigh_L": (0.16, -1, 0.12), "shin_L": (0.02, -1, -0.12), "thigh_R": (-0.16, -1, 0.12),
    "shin_R": (-0.02, -1, -0.12), "upper_L": (0.32, -1, -0.02), "fore_L": (0.1, -1, 0.32),
    "upper_R": (-0.32, -1, -0.02), "fore_R": (-0.1, -1, 0.32),
    "foot_L": (0.25, 0, 1), "foot_R": (-0.25, 0, 1),
}

RUN_THIGH = 36.0     # thigh swing amplitude (degrees)
RUN_KNEE = 95.0      # extra knee bend at mid-swing
RUN_ARM = 42.0       # upper-arm swing amplitude
RUN_BOB = 1.1        # body lift in the flight phase (1x pixels)


def run_pose(k, n=6):
    """Run cycle, frame k of n. Leg phase: forward at 90 deg, back at 270; the left leg leads frame 0."""
    ph = 2 * math.pi * k / n
    p = {"lean": 14, "head_up": 14}
    for side, sx, off in (("L", 1.0, 0.0), ("R", -1.0, math.pi)):
        f = ph + off
        a = RUN_THIGH * math.sin(f) + 6.0
        flex = 18.0 + RUN_KNEE * max(0.0, math.cos(f)) ** 1.3
        p["thigh_" + side] = d(a, sx * 0.06)
        p["shin_" + side] = d(a - flex, sx * 0.02)
        toe = 0.15 + 0.75 * max(0.0, -math.sin(f + 0.6))       # toe points down when pushing off behind
        p["foot_" + side] = (sx * 0.08, -toe, 1.0)
        # arm on this side swings opposite to this leg
        c = -RUN_ARM * math.sin(f)
        p["upper_" + side] = d(c, sx * 0.16)
        p["fore_" + side] = d(c + 88.0, sx * 0.02)
    p["jump"] = RUN_BOB * math.sin(2 * ph - math.pi / 2) * 0.5 + RUN_BOB * 0.5
    return p


DRIB_HAND_Y = [-1.2, -3.6, -5.6, -3.4]   # dribble hand height (pelvis-relative) per frame: top, push, low, catch
DRIB_SINK = [0.0, 0.35, 0.55, 0.25]      # knees bend with the push


def dribble_pose(k):
    """Low dribble stance, right hand pumping (the ball is drawn by the game under the hand)."""
    s = DRIB_SINK[k]
    p = {
        "lean": 20 + 2 * s, "head_up": 16, "twist": -10,
        "thigh_L": (0.3, -0.75 + 0.12 * s, 0.55 + 0.1 * s), "shin_L": (0.05, -1, -0.15 - 0.1 * s), "foot_L": (0.2, 0, 1),
        "thigh_R": (-0.35, -0.9 + 0.1 * s, -0.15 + 0.15 * s), "shin_R": (-0.05, -1, 0.1 - 0.12 * s),
        "foot_R": (-0.35, 0, 1),
        "upper_L": (0.5, -0.6, 0.5), "fore_L": (0.05, 0.25, 1),
        "hand_R": (-4.8, DRIB_HAND_Y[k], 5.4), "pole_R": (-1, 0.2, -0.6),
    }
    return p


# ----------------------------------------------------------------------------- part 2 poses (P4-09)
# Airborne frames keep the feet on the floor row: the game draws the jump height itself (jump_z, DUNK_VIEW_LIFT), so
# the sprite only shows the body shape (tucked or pointed legs). The ball is drawn by the game, at the hand points
# written to assets/players/hands.json. "reach_X": (body-space direction, fraction of the arm's length).
# L = the player's own left = the far hand when facing E; jump shots use it so the face stays visible (sample v1).

def legs(p, bend=0.0, spread=0.16, toe=0.0, stride=0.0):
    """Both legs: bend 0 = straight, 1 = deep crouch; toe 0 = flat feet, 1 = pointed (in the air); stride moves the
    left leg forward and the right back (degrees)."""
    for side, sx, st in (("L", 1.0, stride), ("R", -1.0, -stride)):
        a = 8.0 + 52.0 * bend + st
        p["thigh_" + side] = d(a, sx * spread)
        p["shin_" + side] = d(a - 8.0 - 92.0 * bend - (20.0 * toe), sx * 0.03)
        p["foot_" + side] = (sx * 0.18, -0.9 * toe, 1.0)
    return p


def shoot_pose(k):
    """Jump shot: 0 gather (ball at the chest), 1 set point over the forehead, 2 release, 3 follow-through.
    Also the free throw; frames 0-1 and back are the pump fake."""
    if k == 0:
        p = legs({"lean": 9, "head_up": 12}, bend=0.45)
        p["reach_L"] = ((-0.42, -0.25, 0.87), 0.56)
        p["reach_R"] = ((0.42, -0.30, 0.86), 0.56)
        p["pole_L"], p["pole_R"] = (1, -0.6, -0.4), (-1, -0.6, -0.4)
    elif k == 1:
        p = legs({"lean": 1, "head_up": 16, "shrug": 0.8}, bend=0.08, toe=0.35)
        p["reach_L"] = ((-0.22, 0.93, 0.30), 0.78)
        p["reach_R"] = ((0.28, 0.90, 0.35), 0.74)
        p["pole_L"], p["pole_R"] = (1, -0.3, 0.2), (-1, -0.3, 0.2)
    elif k == 2:
        p = legs({"lean": -3, "head_up": 18, "shrug": 1.8}, bend=0.05, toe=1.0, spread=0.10)
        p["reach_L"] = ((-0.18, 0.96, 0.22), 0.96)
        p["reach_R"] = ((0.22, 0.85, 0.45), 0.72)
        p["pole_L"], p["pole_R"] = (1, -0.2, 0.3), (-1, -0.3, 0.3)
    else:
        p = legs({"lean": 3, "head_up": 15, "shrug": 1.0}, bend=0.22, toe=0.2)
        p["reach_L"] = ((-0.15, 0.72, 0.68), 0.97)
        p["reach_R"] = ((-0.3, -0.1, 0.95), 0.62)
        p["pole_L"], p["pole_R"] = (1, -0.4, 0.0), (-1, -0.5, 0.0)
    return p


def dunk_pose(k):
    """Dunk (also the alley-oop finish): 0 gather low, 1 take-off with the knee driving, 2 reach over the rim,
    3 slam, 4 hang on the rim. The near (right) hand carries the ball."""
    if k == 0:
        p = legs({"lean": 24, "head_up": 22}, bend=0.75, stride=12)
        p["reach_R"] = ((0.35, -0.55, 0.76), 0.62)
        p["reach_L"] = ((-0.35, -0.55, 0.76), 0.62)
        p["pole_L"], p["pole_R"] = (1, -0.5, -0.5), (-1, -0.5, -0.5)
    elif k == 1:
        p = {"lean": 8, "head_up": 22, "jump": 3.0}   # lifted a little so the trailing foot (toward the camera in
        # the NE and N rows) stays inside the frame
        p["thigh_L"], p["shin_L"], p["foot_L"] = d(85, 0.1), d(-5, 0.02), (0.1, -0.6, 1)
        p["thigh_R"], p["shin_R"], p["foot_R"] = d(-6, -0.1), d(-50, -0.02), (-0.1, -0.95, 0.4)
        p["reach_R"] = ((-0.1, 0.65, 0.76), 0.85)
        p["reach_L"] = ((0.55, -0.2, -0.6), 0.85)
        p["pole_L"], p["pole_R"] = (1, -0.5, 0.3), (-1, -0.6, 0.2)
    elif k == 2:
        p = {"lean": -2, "head_up": 26, "shrug": 1.5}
        p["thigh_L"], p["shin_L"], p["foot_L"] = d(55, 0.12), d(-30, 0.02), (0.1, -0.85, 0.5)
        p["thigh_R"], p["shin_R"], p["foot_R"] = d(25, -0.12), d(-55, -0.02), (-0.1, -0.9, 0.4)
        p["reach_R"] = ((-0.05, 0.97, 0.25), 0.97)
        p["reach_L"] = ((0.75, 0.25, -0.2), 0.85)
        p["pole_L"], p["pole_R"] = (1, -0.6, 0.0), (-1, -0.3, 0.3)
    elif k == 3:
        p = {"lean": 16, "head_up": 12, "shrug": 0.8}
        p["thigh_L"], p["shin_L"], p["foot_L"] = d(35, 0.12), d(-45, 0.02), (0.1, -0.85, 0.5)
        p["thigh_R"], p["shin_R"], p["foot_R"] = d(10, -0.12), d(-60, -0.02), (-0.1, -0.9, 0.4)
        p["reach_R"] = ((-0.05, 0.45, 0.89), 0.97)
        p["reach_L"] = ((0.7, 0.1, -0.3), 0.85)
        p["pole_L"], p["pole_R"] = (1, -0.6, 0.0), (-1, -0.6, 0.0)
    else:
        p = {"lean": 2, "head_up": 16, "shrug": 2.0}
        p["thigh_L"], p["shin_L"], p["foot_L"] = d(18, 0.12), d(-25, 0.02), (0.12, -0.8, 0.6)
        p["thigh_R"], p["shin_R"], p["foot_R"] = d(8, -0.12), d(-30, -0.02), (-0.12, -0.8, 0.6)
        p["reach_R"] = ((-0.12, 0.95, 0.30), 0.97)
        p["reach_L"] = ((0.12, 0.95, 0.30), 0.97)
        p["pole_L"], p["pole_R"] = (1, -0.3, 0.2), (-1, -0.3, 0.2)
    return p


def layup_pose(k):
    """Layup: 0 gather step (ball at the right hip), 1 lift off the left foot with the right knee up, 2 release."""
    if k == 0:
        p = legs({"lean": 14, "head_up": 18, "twist": -8}, bend=0.45, stride=18)
        p["reach_R"] = ((0.15, -0.45, 0.88), 0.62)
        p["reach_L"] = ((-0.55, -0.35, 0.76), 0.62)
        p["pole_L"], p["pole_R"] = (1, -0.6, -0.3), (-1, -0.6, -0.3)
    elif k == 1:
        p = {"lean": 6, "head_up": 22}
        p["thigh_R"], p["shin_R"], p["foot_R"] = d(80, -0.1), d(0, -0.02), (-0.1, -0.6, 1)
        p["thigh_L"], p["shin_L"], p["foot_L"] = d(-8, 0.1), d(-30, 0.02), (0.1, -0.9, 0.5)
        p["reach_R"] = ((-0.05, 0.75, 0.66), 0.80)
        p["reach_L"] = ((-0.35, 0.55, 0.76), 0.62)
        p["pole_L"], p["pole_R"] = (1, -0.5, 0.0), (-1, -0.5, 0.0)
    else:
        p = {"lean": 2, "head_up": 26, "shrug": 1.4}
        p["thigh_R"], p["shin_R"], p["foot_R"] = d(55, -0.1), d(-25, -0.02), (-0.1, -0.8, 0.6)
        p["thigh_L"], p["shin_L"], p["foot_L"] = d(0, 0.1), d(-25, 0.02), (0.1, -0.9, 0.5)
        p["reach_R"] = ((-0.05, 0.95, 0.30), 0.97)
        p["reach_L"] = ((0.6, 0.2, 0.3), 0.75)
        p["pole_L"], p["pole_R"] = (1, -0.5, 0.0), (-1, -0.3, 0.3)
    return p


def block_pose(k):
    """Block jump: 0 load (arms coming up), 1 both arms straight up, 2 the near hand swats forward."""
    if k == 0:
        p = legs({"lean": 10, "head_up": 18}, bend=0.55)
        p["reach_L"] = ((0.35, 0.35, 0.87), 0.75)
        p["reach_R"] = ((-0.35, 0.35, 0.87), 0.75)
        p["pole_L"], p["pole_R"] = (1, -0.6, -0.2), (-1, -0.6, -0.2)
    elif k == 1:
        p = legs({"lean": -2, "head_up": 22, "shrug": 2.0}, bend=0.05, toe=1.0, spread=0.12)
        p["reach_L"] = ((0.22, 0.95, 0.20), 0.97)
        p["reach_R"] = ((-0.22, 0.95, 0.20), 0.97)
        p["pole_L"], p["pole_R"] = (1, -0.2, 0.0), (-1, -0.2, 0.0)
    else:
        p = legs({"lean": 8, "head_up": 16, "shrug": 1.4}, bend=0.30, toe=1.0, spread=0.14)
        p["reach_L"] = ((0.25, 0.95, 0.15), 0.97)
        p["reach_R"] = ((-0.08, 0.40, 0.91), 0.97)
        p["pole_L"], p["pole_R"] = (1, -0.2, 0.0), (-1, -0.6, 0.0)
    return p


def poke_pose(k):
    """Steal poke (the defender stands still): 0 lunge with the near hand reaching low, 1 the swipe across."""
    p = {"lean": 26, "head_up": 22, "twist": -12 if k == 0 else 10}
    p["thigh_R"], p["shin_R"], p["foot_R"] = d(48, -0.22), d(-15, -0.03), (-0.2, 0, 1)
    p["thigh_L"], p["shin_L"], p["foot_L"] = d(-22, 0.2), d(-40, 0.03), (0.2, -0.2, 1)
    if k == 0:
        p["reach_R"] = ((-0.05, -0.30, 0.95), 0.97)
        p["reach_L"] = ((0.75, -0.55, -0.2), 0.85)
    else:
        p["reach_R"] = ((0.55, -0.35, 0.76), 0.95)
        p["reach_L"] = ((0.85, -0.35, -0.3), 0.85)
    p["pole_L"], p["pole_R"] = (1, -0.4, -0.4), (-1, -0.2, -0.6)
    return p


def stumble_pose(k):
    """Off balance after being beaten: 0 rocked back, arms out; 1 catching himself, a foot crossing over."""
    if k == 0:
        p = {"lean": -14, "head_up": 2, "twist": 12}
        p["thigh_L"], p["shin_L"], p["foot_L"] = d(38, 0.18), d(10, 0.03), (0.2, -0.4, 1)
        p["thigh_R"], p["shin_R"], p["foot_R"] = d(-6, -0.2), d(-20, -0.03), (-0.25, 0, 1)
        p["reach_L"] = ((0.62, 0.55, 0.3), 0.88)
        p["reach_R"] = ((-0.62, 0.35, -0.3), 0.88)
        p["pole_L"], p["pole_R"] = (0.2, -1, -0.2), (-0.2, -1, -0.2)
    else:
        p = {"lean": 4, "head_up": 6, "twist": -14}
        p["thigh_L"], p["shin_L"], p["foot_L"] = d(4, -0.10), d(-12, -0.05), (0.1, 0, 1)
        p["thigh_R"], p["shin_R"], p["foot_R"] = d(22, -0.35), d(-15, -0.03), (-0.35, -0.1, 1)
        p["reach_L"] = ((0.85, -0.1, 0.5), 0.9)
        p["reach_R"] = ((-0.8, 0.45, -0.1), 0.9)
        p["pole_L"], p["pole_R"] = (0.3, -1, 0.0), (-0.3, -1, 0.0)
    return p


def pass_pose(k):
    """Chest pass: 0 ball pulled to the chest, step in; 1 arms snapped out, thumbs down."""
    if k == 0:
        p = legs({"lean": 6, "head_up": 12}, bend=0.30, stride=10)
        p["reach_L"] = ((-0.48, -0.15, 0.86), 0.50)
        p["reach_R"] = ((0.48, -0.15, 0.86), 0.50)
        p["pole_L"], p["pole_R"] = (1, -0.4, -0.6), (-1, -0.4, -0.6)
    else:
        p = legs({"lean": 14, "head_up": 14}, bend=0.30, stride=24)
        p["reach_L"] = ((-0.22, 0.02, 0.98), 0.97)
        p["reach_R"] = ((0.22, 0.02, 0.98), 0.97)
        p["pole_L"], p["pole_R"] = (1, -0.2, 0.0), (-1, -0.2, 0.0)
    return p


def celebrate_pose(k):
    """Celebration with the sample's celebrating face: 0 arms up in a V, 1 a little hop, 2 fist pump, 3 shout."""
    if k in (0, 1):
        p = legs({"lean": -4, "head_up": 20, "shrug": 1.6}, bend=0.10 if k == 0 else 0.0, toe=0.0 if k == 0 else 0.6)
        if k == 1:
            p["jump"] = 1.0
        p["reach_L"] = ((0.50, 0.85, 0.15), 0.90 if k == 0 else 0.97)
        p["reach_R"] = ((-0.50, 0.85, 0.15), 0.90 if k == 0 else 0.97)
        p["pole_L"], p["pole_R"] = (1, -0.2, 0.0), (-1, -0.2, 0.0)
    elif k == 2:
        p = legs({"lean": 8, "head_up": 10, "twist": -6}, bend=0.35)
        p["reach_R"] = ((-0.2, -0.35, 0.92), 0.52)
        p["reach_L"] = ((0.45, 0.88, 0.15), 0.95)
        p["pole_L"], p["pole_R"] = (1, -0.2, 0.0), (-0.6, -1, -0.4)
    else:
        p = legs({"lean": -6, "head_up": 26, "shrug": 2.0}, bend=0.15)
        p["reach_L"] = ((0.75, 0.62, 0.2), 0.6)
        p["reach_R"] = ((-0.75, 0.62, 0.2), 0.6)
        p["pole_L"], p["pole_R"] = (1, -0.6, -0.2), (-1, -0.6, -0.2)
    return p


POSES = {"idle": idle_pose, "run": run_pose, "dribble": dribble_pose, "shoot": shoot_pose, "dunk": dunk_pose,
         "layup": layup_pose, "block": block_pose, "poke": poke_pose, "stumble": stumble_pose, "pass": pass_pose,
         "celebrate": celebrate_pose}
EXPR = {"celebrate": "celebrate"}   # face per animation (pixel3d.stamp_face)



# ----------------------------------------------------------------------------- render + checks

def render_frame(p, anim, k, yaw, hands=None):
    img, cv, info = P.render(p, POSES[anim](k), yaw, expr=EXPR.get(anim, "focus"))
    if hands is not None:
        for side in ("L", "R"):
            i, j, depth = cv.project(info["hands"][side])
            hands[side] = [int(i), int(j)]
    return img


def frame_problems(img, tag):
    """Stray pixels, clipping at the frame edge, feet not on the floor row."""
    a = np.array(img)[:, :, 3] > 0
    probs = []
    if a[0].any() or a[-1].any() or a[:, 0].any() or a[:, -1].any():
        probs.append("touches the frame edge")
    ys = np.nonzero(a.any(axis=1))[0]
    bottom = ys.max() if len(ys) else -1
    # the floor point under the body is row 59; a foot stepping toward the camera sits a little lower in 3/4
    if not (55 <= bottom <= 62):
        probs.append("lowest row %d (expected 55-62)" % bottom)
    # connected components (4-neighbour): a sprite must be one piece
    seen = np.zeros_like(a)
    comps = []
    for j, i in zip(*np.nonzero(a)):
        if seen[j, i]:
            continue
        stack, n = [(j, i)], 0
        seen[j, i] = True
        while stack:
            y, x = stack.pop()
            n += 1
            for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= yy < FH and 0 <= xx < FW and a[yy, xx] and not seen[yy, xx]:
                    seen[yy, xx] = True
                    stack.append((yy, xx))
        comps.append(n)
    if len(comps) != 1:
        probs.append("%d pieces %s" % (len(comps), sorted(comps)))
    return ["%s: %s" % (tag, s) for s in probs]


def make_sheet(p):
    """Returns (sheet, frames, problems, hands). hands[row][column] = {"L": [x, y], "R": [x, y]} in frame pixels."""
    sheet = Image.new("RGBA", (FW * COLS, FH * len(DIRS)), (0, 0, 0, 0))
    frames = {}
    problems = []
    hands = [[None] * COLS for _ in DIRS]
    for r, (dname, yaw) in enumerate(DIRS):
        for anim in DRAWN:
            start, n = [(s, c) for a, s, c in ANIMS if a == anim][0]
            for k in range(n):
                hp = {}
                img = render_frame(p, anim, k, yaw, hp)
                frames[(dname, anim, k)] = img
                hands[r][start + k] = hp
                problems += frame_problems(img, "%s %s %s%d" % (p["id"], dname, anim, k))
                sheet.paste(img, ((start + k) * FW, r * FH))
    return sheet, frames, problems, hands


def save_png(img, path):
    """RGBA PNG (about 35-40 KB per sheet; the repeated filler frames compress to almost nothing)."""
    img.save(path, optimize=True)


# ----------------------------------------------------------------------------- preview

def font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except TypeError:
        return ImageFont.load_default()


def preview(players, all_frames, path=PREVIEW, zoom=3):
    """Per player: idle in all 8 directions (W side mirrored), the run cycle (E) and the dribble (SE)."""
    cell = 42
    label_w = 70
    top = 22
    cols = 8 + 1 + 6 + 1 + 4
    w = label_w + cols * cell
    h = top + len(players) * (FH + 4) + 6
    base = Image.new("RGBA", (w, h), P.hexc("#c99a62") + (255,))
    dr = ImageDraw.Draw(base)
    dr.rectangle([0, 0, label_w - 4, h], fill=P.hexc("#1c1a26"))
    dr.rectangle([0, 0, w, top - 4], fill=P.hexc("#1c1a26"))
    for r, p in enumerate(players):
        fr = all_frames[p["id"]]
        y0 = top + r * (FH + 4)
        seq = []
        for dname in ("S", "SE", "E", "NE", "N"):
            seq.append(fr[(dname, "idle", 0)])
        for dname in ("NE", "E", "SE"):  # NW, W, SW: mirrored
            seq.append(fr[(dname, "idle", 0)].transpose(Image.FLIP_LEFT_RIGHT))
        seq.append(None)
        seq += [fr[("E", "run", k)] for k in range(6)]
        seq.append(None)
        seq += [fr[("SE", "dribble", k)] for k in range(4)]
        for c, img in enumerate(seq):
            if img is None:
                continue
            x0 = label_w + c * cell + (cell - FW) // 2
            ring = ring_image(p["ring"])
            base.alpha_composite(ring, (x0, y0 + P.GROUND_Y - ring.size[1] // 2 - 1))
            base.alpha_composite(img, (x0, y0))
    big = base.resize((w * zoom, h * zoom), Image.NEAREST)
    dr = ImageDraw.Draw(big)
    ft = font(16)
    heads = [("idle: S  SE  E  NE  N  NW  W  SW (last 3 mirrored)", 0), ("run (E), 6 frames", 9),
             ("dribble (SE), 4 frames", 16)]
    for txt, c in heads:
        dr.text(((label_w + c * cell) * zoom + 6, 8), txt, font=ft, fill=(250, 244, 230))
    for r, p in enumerate(players):
        y = (top + r * (FH + 4) + FH // 2) * zoom
        dr.rectangle([8, y - 30, 14, y + 30], fill=p["ring"])
        dr.text((20, y - 30), p["id"], font=ft, fill=p["ring"])
        dr.text((20, y - 8), p["label"].split(" ", 1)[0], font=ft, fill=(250, 244, 230))
        dr.text((20, y + 12), p["label"].split(" ", 1)[1], font=font(13), fill=(200, 196, 214))
    big.convert("RGB").save(path, optimize=True)


def ring_image(c, w=FW, h=9):
    """The soft team ring of the style sample (preview only; the game draws its own)."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx, cy, rx, ry = w / 2.0, h / 2.0, 10.5, 3.6
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


def write_hands(all_hands, path=HANDS):
    data = {"_help": "Hand points in frame pixels (40 x 64 frame, feet on row 59): players.<id>[row][column] = "
                     "{L: [x, y], R: [x, y]}. Rows 0-4 = S, SE, E, NE, N; for a mirrored row use x' = 39 - x and "
                     "swap L and R. L/R are the player's own hands. Load with load(path).data in Godot.",
            "frame": [FW, FH], "feet_row": P.GROUND_Y, "players": all_hands}
    with open(path, "w") as f:
        json.dump(data, f, separators=(",", ":"))
    print("wrote %s %d bytes" % (path, os.path.getsize(path)))


def preview2(players, all_frames, path=PREVIEW2, zoom=2):
    """Part 2 check: every player's animations facing E (idle + the part 2 set), then two players in all 5 drawn
    directions, on the gym floor colour with the team ring."""
    seq_anims = ["idle", "shoot", "dunk", "layup", "block", "poke", "stumble", "pass", "celebrate"]
    cell = 42
    label_w = 74
    top = 24
    gap = 10
    ncols = sum(n for a, _, n in ANIMS if a in seq_anims)
    groups = len(seq_anims)
    w = label_w + ncols * cell + (groups - 1) * gap + 6
    rows = [(p, "E") for p in players] + [(players[0], dn) for dn, _ in DIRS] + [(players[3], dn) for dn, _ in DIRS]
    sec2 = len(players)
    h = top + len(rows) * (FH + 4) + 18 + 6
    base = Image.new("RGBA", (w, h), P.hexc("#c99a62") + (255,))
    dr = ImageDraw.Draw(base)
    dr.rectangle([0, 0, label_w - 4, h], fill=P.hexc("#1c1a26"))
    dr.rectangle([0, 0, w, top - 4], fill=P.hexc("#1c1a26"))
    ys = []
    for r, (p, dn) in enumerate(rows):
        y0 = top + r * (FH + 4) + (18 if r >= sec2 else 0)
        ys.append(y0)
        if r == sec2:
            dr.rectangle([label_w - 4, y0 - 18, w, y0 - 4], fill=P.hexc("#1c1a26"))
        fr = all_frames[p["id"]]
        c = 0
        heads = []
        for g, anim in enumerate(seq_anims):
            n = [n for a, _, n in ANIMS if a == anim][0]
            x_start = label_w + c * cell + g * gap
            heads.append((anim, n, x_start))
            for k in range(n):
                x0 = x_start + k * cell + (cell - FW) // 2
                ring = ring_image(p["ring"])
                base.alpha_composite(ring, (x0, y0 + P.GROUND_Y - ring.size[1] // 2 - 1))
                base.alpha_composite(fr[(dn, anim, k)], (x0, y0))
            c += n
    big = base.resize((w * zoom, h * zoom), Image.NEAREST)
    dr = ImageDraw.Draw(big)
    ft = font(15)
    for anim, n, x in heads:
        dr.text((x * zoom + 6, 10), "%s (%d)" % (anim, n), font=ft, fill=(250, 244, 230))
    dr.text((label_w * zoom + 6, (ys[sec2] - 16) * zoom), "all 5 drawn directions (S, SE, E, NE, N); W side = mirrored",
            font=ft, fill=(250, 244, 230))
    for r, (p, dn) in enumerate(rows):
        y = (ys[r] + FH // 2) * zoom
        dr.rectangle([8, y - 26, 13, y + 26], fill=p["ring"])
        dr.text((18, y - 26), p["id"], font=ft, fill=p["ring"])
        dr.text((18, y - 6), dn, font=ft, fill=(250, 244, 230))
    big.convert("RGB").save(path, optimize=True)


def main(argv):
    only = argv[argv.index("--only") + 1] if "--only" in argv else None
    players = load_players()
    os.makedirs(OUT_DIR, exist_ok=True)
    all_frames = {}
    all_hands = {}
    problems = []
    for p in players:
        if only and p["id"] != only:
            continue
        sheet, frames, probs, hp = make_sheet(p)
        all_frames[p["id"]] = frames
        all_hands[p["id"]] = hp
        problems += probs
        out = os.path.join(OUT_DIR, p["id"] + ".png")
        if "--preview-only" not in argv:
            save_png(sheet, out)
            print("wrote %s %s %d bytes" % (out, sheet.size, os.path.getsize(out)))
    if not only:
        preview(players, all_frames)
        print("wrote", PREVIEW)
        preview2(players, all_frames)
        print("wrote", PREVIEW2)
        if "--preview-only" not in argv:
            write_hands(all_hands)
    for s in problems:
        print("CHECK", s)
    print("checks: %d problem(s)" % len(problems))


if __name__ == "__main__":
    main(sys.argv[1:])
