#!/usr/bin/env python3
"""Player sprite sheets for Road Trip Hoops (original art, generated; no downloaded assets).

RETIRED (P6-25): these are the v1 sheets (40 x 64 frames). Every player now has a v2 sheet from
tools/art/make_players_v2.py (assets/players2/), and the v1 outputs below (assets/players/*.png and
assets/players/hands.json) were removed from the project. The game no longer ships or expects them: scripts/sheets.gd
still reads a v1 sheet if one is put back, and player.gd falls back to the Kenney sprites (assets/blue_n.png,
red_n.png) when a player has no sheet at all. This script stays as a tool (its parts and renderer are shared with
make_players_v2.py and make_anim_sample.py); running it writes the v1 files again, which are not needed and should
not be committed.

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

Usage:  python3 tools/art/make_players.py [--preview-only] [--only ID[,ID...] [--preview]] [--jobs N]
Output: assets/players/<id>.png, assets/players/hands.json, docs/art/players_preview_v1.png (part 1 view) and
        docs/art/players_preview_v2.png (every animation, not exported)
        (both for the Phase 4 six), docs/art/players_preview_p5.png (Phase 5 players: S, E, N and an action frame).
Phase 5: entries with "recruit": true also write <id>_crew.png in your crew's colors (crews.json crew_recolor);
sheets are saved as indexed-palette PNGs when that is smaller (same pixels, about 40 KB instead of 95 KB).
Phase 6 (P6-A1): the five new city crews and the New York crews ("phase": 6 in crews.json), new parts in the
"Phase 6 parts" section below, preview docs/art/players_preview_p6.png. Sheets render in parallel (--jobs).
Phase 9 (P9-04): the Grandfathers era parts ("Phase 9 era parts" section below; make_players_v2.py uses them through
this loader). python3 tools/art/make_players.py --legends-sample writes only the owner's look sample
docs/art/legends_sample_v1.png and .gif (one era look in the v2 style; nothing in assets/).
Phase 10 (P10-04): the Fathers era parts ("Phase 10 era parts": baggy shorts, crew socks, the durag; the
older sleeve, leg sleeve, wristbands, cornrows, goatee and headband reused). --legends-sample fathers writes only the
owner's look sample docs/art/legends_fathers_sample_v1.png and .gif (two era looks; nothing in assets/).
Phase 11 (P11-05): the Present era parts ("Phase 11 era parts": mid-thigh shorts, compression tights on both legs
or one, a knee sleeve, low socks, hair crop / waves / hightop_fade / manbun, a boxed beard and a thin mustache).
--legends-sample present writes only the owner's look sample docs/art/legends_present_sample_v1.png and .gif (two
era looks, Deep End and Toolbox as the Phase 11 board proposes them; nothing in assets/).
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
PREVIEW_P5 = os.path.join(ROOT, "docs", "art", "players_preview_p5.png")
PREVIEW_P6 = os.path.join(ROOT, "docs", "art", "players_preview_p6.png")
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
    entries = []
    for e in data["players"]:
        entries.append(e)
        if e.get("recruit"):
            # recruits switch to your colors (Q11 a): the same parts, palette names swapped
            swap = data["crew_recolor"][e["crew"]]
            c = {k: (swap.get(v, v) if isinstance(v, str) and (k.endswith("_pal") or k in ("shorts_trim", "shoe_acc"))
                     else v) for k, v in e.items()}
            c.update(swap.get("_fields", {}))
            c["id"] = e["id"] + "_crew"
            c["crew"] = "U"
            c["recolor_of"] = e["id"]
            entries.append(c)
    out = []
    for e in entries:
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
        p["title"] = e.get("name", "")
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



# ----------------------------------------------------------------------------- Phase 6 parts (P6-A1)
# New hair styles and accessories, added here around pixel3d.build so the renderer and every older sheet stay
# pixel-identical: a player without these keys goes straight through to the original build.
#   hair cornrows | locs_tied | shaggy | sides (shaved sides, short top) | bun | slick (combed back) | part (fade
#   with a shaved part); braids: true adds short braids at the nape (with cornrows).
#   two-digit numbers (10-99); no_number: true (flannel shirts).
#   flannel: true (checks on the top), patch: true (a cross patch on the left chest, patch_pal),
#   towel: "L"/"R" (towel over that shoulder, towel_pal, stripes in trim), waist_jacket: true (a jacket tied at the
#   waist, jacket_pal), whistle: true (on the chain, whistle_pal), glasses_up: true (spare shades on the forehead) and
#   glasses_collar: true (a pair hooked on the collar, collar_pal), glasses_pal; goggle_tan: true (pale band at the eyes);
#   hand_pal (chalk or tape on the hands); kneepads: "L" | "R" | "both" (pad_pal).

_ORIG_BUILD = P.build
_ORIG_NUMBER_PX = P.number_px
_CUR = {}          # the player being rendered (materials are evaluated lazily inside P.render)
EXT_HAIR = {"cornrows": "bald", "locs_tied": "twists", "shaggy": "buzz", "sides": "bald", "bun": "buzz",
            "slick": "buzz", "part": "buzz"}
EXT_KEYS = ("flannel", "patch", "towel", "waist_jacket", "whistle", "glasses_up", "glasses_collar", "goggle_tan",
            "hand_pal", "kneepads", "braids", "no_number")
HK = 1.14          # pixel3d head scale


def number_px_ext(num, x, y, cx, cy, cell):
    if _CUR.get("no_number"):
        return False
    if num < 10:
        return _ORIG_NUMBER_PX(num, x, y, cx, cy, cell)
    # two digits side by side (x grows to the viewer's right on both faces, see pixel3d.number_px)
    c = cell * 0.9
    return (_ORIG_NUMBER_PX(num // 10, x, y, cx - 2.0 * c, cy, c)
            or _ORIG_NUMBER_PX(num % 10, x, y, cx + 2.0 * c, cy, c))


def is_ext(p):
    return p["hair"] in EXT_HAIR or p["number"] >= 10 or any(p.get(k) for k in EXT_KEYS)


def build_ext(p, pose, expr="focus", portrait=False):
    _CUR.clear()
    _CUR.update(p)
    if not is_ext(p):
        return _ORIG_BUILD(p, pose, expr, portrait)
    style = p["hair"]
    q = dict(p)
    q["hair"] = EXT_HAIR.get(style, style)
    prims, info, pp = _ORIG_BUILD(q, pose, expr, portrait)
    for k in ("towel", "jacket", "whistle", "glasses", "collar", "hand", "pad", "patch"):
        if p.get(k + "_pal"):
            pp[k] = P.pal(p[k + "_pal"])
    W, mass, tk = p["width"], p["mass"], p["torso"]
    head_c, Rh, pelvis = info["head_c"], info["Rh"], info["pelvis"]
    Rs = P.rot_y(math.radians(pose.get("twist", 0.0))) @ P.rot_x(math.radians(pose.get("lean", 4.0)))
    sh_y = 10.0 * tk

    def S(x, y, z):
        return pelvis + Rs @ P.vec(x, y, z)

    def H(x, y, z):
        return head_c + Rh @ P.vec(x, y, z)

    def head_local(h):
        return Rh.T @ (h - head_c) / (HK * HK)

    def hairline(l):
        return 1.55 * max(-1.0, min(1.0, l[2] / 3.6)) + 0.25

    # --- head: new hair styles and face extras (wrap the head materials)
    def head_extra(l, m):
        x, y, z = l
        if m == "band":
            return m
        top = y > hairline(l) + 0.15
        if style == "cornrows" and top and m == "skin":
            return "skin+1" if (x * 0.62 + 10.0) % 1.0 < 0.34 else "hair"
        if style == "sides" and y > hairline(l) + 0.3 and m == "skin":
            return "hair" if abs(x) < 2.0 else "skin+1"
        if style == "part" and m == "hair" and 0.85 < x < 1.35 and y > 1.0 and z > -1.5:
            return "skin+1"
        if p.get("goggle_tan") and m == "skin" and z > 1.3 and -0.2 < y < 1.15 and abs(x) < 3.0:
            return "skin-1"
        return m

    new = []
    for pr in prims:
        if pr.part == "head" and callable(pr.mat):
            def wrapped(h, prim, orig=pr.mat):
                m = orig(h, prim)
                return head_extra(head_local(h), m)
            pr.mat = wrapped
        new.append(pr)
    prims = new
    if style == "locs_tied":
        prims.append(P.ell(H(0, 0.6, -3.9), Rh, 1.2, 1.3, 1.1, "hair_tw", "hair"))
        prims.append(P.ell(H(0, -0.9, -4.5), Rh, 0.9, 1.6, 0.8, "hair_tw", "hair"))
    if style == "shaggy":
        pl = (H(0, -0.6, 0), Rh @ P.unit(0, 1.0, -0.75))
        prims.append(P.ell(H(0, 1.0, -0.45), Rh, 3.45 + 0.55, 3.95 + 0.25, 3.6 + 0.5, "hair", "hair", clip=pl))
        for sx in (-1.4, 0.2, 1.6):   # fringe locks over the forehead
            prims.append(P.ell(H(sx, 2.0, 3.0), Rh, 1.0, 0.8, 0.8, "hair", "hair"))
    if style == "sides":
        prims.append(P.ell(H(0, 3.3, -0.2), Rh, 1.9, 1.3, 3.0, "hair_tw", "hair"))
    if style == "bun":
        prims.append(P.ell(H(0, 1.2, -0.5), Rh, 3.45 + 0.25, 3.95 + 0.1, 3.6 + 0.3, "hair", "hair",
                           clip=(H(0, 0.9, 0), Rh @ P.unit(0, 1.0, -0.45))))
        prims.append(P.Sphere(H(0, 3.2, -3.4), 1.45, "hair_tw", "hair"))
    if style == "slick":
        prims.append(P.ell(H(0, 0.6, -0.6), Rh, 3.45 + 0.3, 3.95 + 0.15, 3.6 + 0.5, "hair", "hair",
                           clip=(H(0, 0.85, 0), Rh @ P.unit(0, 1.0, -0.38))))
    if p.get("braids"):
        for bx in (-1.6, 0.0, 1.6):
            P.limb(prims, H(bx, -0.8, -3.4), H(bx * 1.1, -3.6, -3.9), 0.65, 0.5, "hair_tw", "hair")

    # --- torso: flannel checks, a chest patch
    def torso_extra(h, m):
        qv = Rs.T @ (h - pelvis)
        x, y, z = qv
        if p.get("patch") and z > 0.8 and m.startswith("top"):
            dx, dy = x - 2.0 * W, y - 7.3 * tk
            if (abs(dx) < 0.5 and abs(dy) < 1.4) or (abs(dy) < 0.5 and abs(dx) < 1.4):
                return "patch"
        if p.get("flannel") and m == "top":
            bx = math.floor(x / 1.7 + 10) % 2
            by = math.floor(y / 1.7 + 10) % 2
            return "top+1" if bx and by else ("top" if bx or by else "top-1")
        return m

    if p.get("patch") or p.get("flannel"):
        for pr in prims:
            if pr.part == "torso" and callable(pr.mat):
                def wrapped_t(h, prim, orig=pr.mat):
                    return torso_extra(h, orig(h, prim))
                pr.mat = wrapped_t

    # --- hands (chalk, tape)
    if p.get("hand_pal"):
        for pr in prims:
            if pr.part == "hand":
                pr.mat = "hand"

    # --- knee pads / brace: leg spheres come L thigh, L calf, L shoe, then R (pixel3d.build order)
    if p.get("kneepads"):
        side, seen_shoe = "L", False
        for pr in prims:
            if pr.part == "shoe":
                seen_shoe = True
                continue
            if pr.part == "thigh" and seen_shoe:
                side, seen_shoe = "R", False
            if pr.part in ("thigh", "calf") and p["kneepads"] in (side, "both"):
                def wrapped_k(h, prim, orig=pr.mat):
                    m = orig(h, prim)
                    near = (prim.part == "thigh" and prim.t > 0.86) or (prim.part == "calf" and prim.t < 0.2)
                    return "pad" if near and m in ("skin", "tight") else m
                pr.mat = wrapped_k

    # --- extra pieces
    if p.get("towel"):
        sx = 1.0 if p["towel"] == "L" else -1.0
        fz = 3.0 + mass * 0.5
        a, b, c = S(sx * 2.9 * W, sh_y - 4.6, fz + 0.3), S(sx * 3.0 * W, sh_y + 1.3, -0.3), S(sx * 2.9 * W, sh_y - 5.0, -fz)

        def towel_mat(h, prim):
            return "trim" if 0.72 < prim.t < 0.86 and prim.part == "towel_f" else "towel"

        P.limb(prims, a, b, 1.45, 1.4, towel_mat, "towel_f")
        P.limb(prims, b, c, 1.4, 1.45, "towel", "towel_b")
    if p.get("waist_jacket"):
        I = np.eye(3)
        prims.append(P.ell(pelvis + P.vec(0, 1.3, 0), I, 3.8 * W + mass * 0.5 + 0.45, 0.8,
                           2.45 + mass * 0.3 + 0.45, "jacket", "jacket"))
        prims.append(P.ell(pelvis + P.vec(0, -1.0, -2.7 - mass * 0.3), I, 3.3 * W, 2.4, 0.65, "jacket", "jacket"))
        knot = pelvis + P.vec(0, 1.1, 2.9 + mass * 0.3 + 0.2)
        prims.append(P.Sphere(knot, 0.95, "jacket+1", "jacket"))
        for kx in (0.7, -0.7):
            P.limb(prims, knot, knot + P.vec(kx, -2.6, 0.25), 0.7, 0.55, "jacket", "jacket")
    if p.get("whistle"):
        prims.append(P.ell(S(0.0, 7.7 * tk, 3.3 + mass * 0.5), Rs, 0.75, 0.95, 0.7, "whistle", "whistle"))
    if p.get("glasses_up"):     # a spare pair pushed up on the forehead
        prims.append(P.ell(H(0, 2.4, 2.7), Rh, 2.7, 0.6, 1.0, "glasses", "glasses"))
    if p.get("glasses_collar"):  # and one hooked on the collar (collar_pal)
        prims.append(P.ell(S(0.0, 7.6 * tk, 3.6 + mass * 0.5), Rs, 1.9, 0.7, 0.6, "collar", "glasses"))
    return prims, info, pp


P.number_px = number_px_ext
P.build = build_ext


# ----------------------------------------------------------------------------- Phase 9 era parts (P9-04)
# The Grandfathers era (Legends Chapter 1): outfit and face parts drawn once for the whole era, added around the
# Phase 6 build in the same way, so a player without these keys goes straight through (every older sheet stays
# pixel-identical). Original parts only: no real player's look, number or accessory is copied.
#   era_shorts: true      short, snug shorts (shorts_len ERA_SHORTS_LEN, the thighs a little slimmer under them)
#   socks: "striped"      tall tube socks (sock_len ERA_SOCK_LEN unless given) with two bands at the top (stripe_pal,
#                         stripe2_pal for the second band, default the first)
#   terry: true           a thick terry headband (band_pal) over any hair, ribbed, sitting on the hair's outside
#                         (an afro too)
#   chops: true           mutton chops (sideburns grown down to the jaw line, chin shaved)
#   mustache: true        a full mustache, the ends turned down a little
#   hair "flattop"        a flat-top: short sides, a squared top
#   knee pads in era colors: the Phase 6 kneepads with an era pad_pal (ERA_PAD, ERA_RUST ...)
# Era palettes are the ERA_* rows of crews.json. tools/art/make_players.py --legends-sample draws the owner's look
# sample from these parts (docs/art/legends_sample_v1.png and .gif); nothing in assets/ is written by it.

ERA_SHORTS_LEN = 0.46       # thigh fraction under the shorts (today's shortest is 0.62)
ERA_SHORTS_SNUG = 0.38      # thigh radius taken off under the shorts (they hug the leg)
ERA_SOCK_LEN = 0.9          # calf fraction under the socks (up to just below the knee)
ERA_STRIPES = ((0.05, 0.11), (0.15, 0.21))     # the two bands, from the sock top down (calf fraction)
TERRY_Y = 1.25              # head-local height of the terry band centre
TERRY_R = 0.85              # its thickness (head-local radius of the ring's beads)
TERRY_BEADS = 26
ERA_KEYS = ("era_shorts", "terry", "chops", "mustache")

_P6_BUILD = P.build


def is_era(p):
    return p.get("hair") == "flattop" or p.get("socks") == "striped" or any(p.get(k) for k in ERA_KEYS)


def _inside(prim, pt):
    if isinstance(prim, P.Sphere):
        ok = float(np.linalg.norm(pt - prim.c)) <= prim.r
    else:
        ok = float(np.linalg.norm(np.linalg.solve(prim.A, pt - prim.c))) <= 1.0
    if ok and prim.clip is not None:
        p0, nrm = prim.clip
        ok = float((pt - p0) @ nrm) >= 0.0
    return ok


def build_era(p, pose, expr="focus", portrait=False):
    if not is_era(p):
        return _P6_BUILD(p, pose, expr, portrait)
    q = dict(p)
    if p.get("hair") == "flattop":
        q["hair"] = "buzz"
    if p.get("era_shorts"):
        q["shorts_len"] = ERA_SHORTS_LEN
    if p.get("socks") == "striped" and not p.get("sock_len_set"):
        q["sock_len"] = max(p.get("sock_len", 0.0), ERA_SOCK_LEN)
    prims, info, pp = _P6_BUILD(q, pose, expr, portrait)
    if p.get("stripe_pal"):
        pp["stripe"] = P.pal(p["stripe_pal"])
        pp["stripe2"] = P.pal(p.get("stripe2_pal") or p["stripe_pal"])
    head_c, Rh = info["head_c"], info["Rh"]

    def H(x, y, z):
        return head_c + Rh @ P.vec(x, y, z)

    def head_local(h):
        return Rh.T @ (h - head_c) / (HK * HK)

    # --- legs: snug short shorts, striped tube socks
    slen, sock = q["shorts_len"], q["sock_len"]
    for pr in prims:
        if p.get("era_shorts") and pr.part == "thigh" and pr.t < slen:
            pr.r = max(0.6, pr.r - ERA_SHORTS_SNUG)
        if p.get("socks") == "striped" and pr.part == "calf" and callable(pr.mat) and p.get("stripe_pal"):
            def sock_mat(h, prim, orig=pr.mat, top=1.0 - sock):
                m = orig(h, prim)
                if m != "sock":
                    return m
                (a0, a1), (b0, b1) = ERA_STRIPES
                if top + a0 <= prim.t < top + a1:
                    return "stripe"
                if top + b0 <= prim.t < top + b1:
                    return "stripe2"
                return m
            pr.mat = sock_mat

    # --- face: mutton chops, mustache (wrap the head materials)
    def face_era(l, m):
        x, y, z = l
        if m != "skin":
            return m
        ax = abs(x)
        if p.get("chops") and z > -0.4 and -2.5 < y < 1.0 and ax > 2.35 - 0.25 * min(1.0, max(0.0, -y)) \
                and not (y < -1.7 and ax < 2.3):
            return "hair"
        if p.get("mustache") and z > 2.0 and ((-1.55 < y < -0.85 and ax < 1.5) or (1.05 < ax < 1.6 and -2.05 < y < -0.85)):
            return "hair"
        return m

    if p.get("chops") or p.get("mustache"):
        for pr in prims:
            if pr.part == "head" and callable(pr.mat):
                def wrapped_f(h, prim, orig=pr.mat):
                    return face_era(head_local(h), orig(h, prim))
                pr.mat = wrapped_f

    # --- flat-top: stacked flat layers, the top one a level lid
    if p.get("hair") == "flattop":
        HX, HY, HZ = info["HX"], info["HY"], info["HZ"]
        for k, (y, s) in enumerate(((2.0, 0.96), (2.9, 0.97), (3.8, 0.97), (4.6, 0.95))):
            prims.append(P.ell(H(0, y, -0.25), Rh, HX * s, 0.75 if k < 3 else 0.55, HZ * s * 0.97, "hair", "hair"))

    # --- terry headband: a ring of ribbed beads on the outermost head or hair surface at the band height
    if p.get("terry"):
        shells = [pr for pr in prims if pr.part in ("head", "hair")]
        for b in range(TERRY_BEADS):
            th = 2.0 * math.pi * b / TERRY_BEADS
            sx, sz = math.sin(th), math.cos(th)
            rs = 0.0
            for i in range(80, 0, -1):
                r = i * 0.1
                if any(_inside(pr, H(r * sx, TERRY_Y, r * sz)) for pr in shells):
                    rs = r
                    break
            c = H((rs - 0.3) * sx, TERRY_Y, (rs - 0.3) * sz)
            prims.append(P.Sphere(c, TERRY_R * HK, "band" if b % 2 else "band-1", "band"))
    return prims, info, pp


P.build = build_era


# ----------------------------------------------------------------------------- Phase 10 era parts (P10-04)
# The Fathers era (Legends Chapter 2, the 2000s): parts drawn once for the whole era, wrapped around the Phase 9
# build in the same way, so a player without these keys goes straight through (every older sheet stays
# pixel-identical). Original parts only: no real player's look, number or accessory is copied, and the parts are
# spread over the six legends (the hard rule's combination check: never cornrows + a single arm sleeve + a headband on
# a small quick guard).
#   baggy: true           knee-length baggy shorts (shorts_len ERA2_BAGGY_LEN unless given): wider legs
#                         (ERA2_BAGGY_ADD) and a side panel down the outside of each leg in shorts_trim
#   socks: "crew"         short crew socks (sock_len ERA2_CREW_LEN unless given) with one band at the top (stripe_pal)
#   hair "durag"          a cloth cap (rag_pal) over the whole head to just above the brows, a seam down the middle,
#                         the tie band at the forehead and two tails hanging at the nape; no hair shows
# Reused as they are (the era wears them; drawn in older sections): sleeve "L" | "R" (an arm shooting sleeve,
# sleeve_pal), tight "L" | "R" (the leg shooting sleeve, tight_pal: under baggy shorts it shows from the knee to the
# sock), wrist (wristbands, wrist_pal), hair cornrows (+ braids), goatee, headband (band_pal).
# Era palettes are the ERA2_* rows of crews.json. tools/art/make_players.py --legends-sample fathers draws the owner's
# look sample (docs/art/legends_fathers_sample_v1.png and .gif); nothing in assets/ is written by it.

ERA2_BAGGY_LEN = 1.1        # thigh fraction under the shorts (> 1: past the knee onto the shin)
ERA2_BAGGY_ADD = 0.5        # leg radius added under the shorts (today's shorts add 0.45 to the thigh)
ERA2_PANEL = 0.7            # side panel: the outer part of the leg, as a fraction of the sphere radius
ERA2_CREW_LEN = 0.26        # calf fraction under crew socks (a short sock above the shoe)
ERA2_CREW_BAND = 0.07       # the band at the sock top (calf fraction)
DURAG_CUT = (0.2, 0.3)      # head-local: the cap's lower edge plane, y >= a + b * z (low at the back, high in front)
DURAG_TAILS = ((0.7, 1.0), (-0.7, -1.0))       # (x at the knot, x at the tip) of the two tails

_P9_BUILD = P.build


def is_era2(p):
    return bool(p.get("baggy")) or p.get("socks") == "crew" or p.get("hair") == "durag"


def build_era2(p, pose, expr="focus", portrait=False):
    if not is_era2(p):
        return _P9_BUILD(p, pose, expr, portrait)
    q = dict(p)
    if p.get("hair") == "durag":
        q["hair"] = "bald"
    if p.get("baggy") and not p.get("shorts_len_set"):
        q["shorts_len"] = max(p.get("shorts_len", 0.0), ERA2_BAGGY_LEN)
    if p.get("socks") == "crew" and not p.get("sock_len_set"):
        q["sock_len"] = ERA2_CREW_LEN
    prims, info, pp = _P9_BUILD(q, pose, expr, portrait)
    if p.get("rag_pal"):
        pp["rag"] = P.pal(p["rag_pal"])
    if p.get("stripe_pal"):
        pp["stripe"] = P.pal(p["stripe_pal"])
    head_c, Rh = info["head_c"], info["Rh"]

    def H(x, y, z):
        return head_c + Rh @ P.vec(x, y, z)

    def head_local(h):
        return Rh.T @ (h - head_c) / (HK * HK)

    # --- legs: baggy shorts (wider, side panel), crew socks with a band. Leg spheres come L thigh, L calf, L shoe,
    # then R (pixel3d.build order), like the knee pads.
    slen, sock = q["shorts_len"], q["sock_len"]
    side, seen_shoe = 1.0, False
    for pr in prims:
        if pr.part == "shoe":
            seen_shoe = True
            continue
        if pr.part == "thigh" and seen_shoe:
            side, seen_shoe = -1.0, False
        if pr.part not in ("thigh", "calf"):
            continue
        under = pr.t < slen if pr.part == "thigh" else pr.t < slen - 1.0
        if p.get("baggy") and under:
            pr.r += ERA2_BAGGY_ADD
            if callable(pr.mat):
                def baggy_mat(h, prim, orig=pr.mat, sx=side):
                    m = orig(h, prim)
                    if m == "shorts" and (h - prim.c)[0] * sx > prim.r * ERA2_PANEL:
                        return "shorts_trim"
                    return m
                pr.mat = baggy_mat
        if p.get("socks") == "crew" and pr.part == "calf" and callable(pr.mat) and p.get("stripe_pal"):
            def crew_mat(h, prim, orig=pr.mat, top=1.0 - sock):
                m = orig(h, prim)
                if m == "sock" and prim.t < top + ERA2_CREW_BAND:
                    return "stripe"
                return m
            pr.mat = crew_mat

    # --- durag: a cap shell over the head, cut low at the back, with a seam, the tie band and two tails
    if p.get("hair") == "durag":
        HX, HY, HZ = info["HX"], info["HY"], info["HZ"]
        a, b = DURAG_CUT
        nrm = P.unit(0, 1.0, -b)

        def rag_mat(h, prim):
            x, y, z = head_local(h)
            edge = y - (a + b * z)
            if z > 0.8 and edge < 0.75:
                return "rag+1"            # the tie band across the forehead
            if abs(x) < 0.33 and y > 0.6:
                return "rag+1"            # the seam down the middle
            return "rag"

        prims.append(P.ell(H(0, 0.5, -0.15), Rh, HX + 0.3, HY + 0.15, HZ + 0.3, rag_mat, "hair",
                           clip=(H(0, a, 0), Rh @ nrm)))
        for x0, x1 in DURAG_TAILS:
            P.limb(prims, H(x0, -0.6, -3.8), H(x1 * 1.2, -5.2, -4.6), 0.85, 0.65, "rag", "hair")
    return prims, info, pp


P.build = build_era2


# ----------------------------------------------------------------------------- Phase 11 era parts (P11-05)
# The Present era (Legends Chapter 3, today's game): parts drawn once for the whole era, wrapped around the Phase 10
# build in the same way, so a player without these keys goes straight through (every older sheet stays
# pixel-identical). Original parts only: no real player's look, number or accessory is copied, and the parts are
# spread over the six legends (the hard rule's combination check, docs/BOARD.md Phase 11: never the step-back shooter
# with a full beard, the slim deep-range guard with a mouthguard, the seven-foot shooting big with shaggy hair, the
# big point-forward in a headband, or the long-armed two-way wing with twists).
#   modern_shorts: true   mid-thigh shorts (shorts_len ERA3_SHORTS_LEN unless given), a slim cut (ERA3_SHORTS_SLIM
#                         off the thigh) with a thin side stripe in shorts_trim
#   tights: "both" | "L" | "R"   compression tights (tight_pal) from under the shorts to the ankle, on both legs or
#                         one, with a darker seam down the outside; the low socks sit over their ends
#   knee_sleeve: "L" | "R"   a knee sleeve (knee_pal) from the lower thigh to the upper calf, a darker band at each end
#   socks: "low"          modern low socks (sock_len ERA3_LOW_LEN unless given), just over the shoe, no band
#   hair "crop"           close-cropped hair with a sharp line-up (a straight front hairline, squared temples)
#   hair "waves"          short hair brushed into waves: lighter ridges in rings around the crown, the same line-up
#   hair "hightop_fade"   a squared, flat-topped high-top over faded sides and back (shorter than the 1990s hightop)
#   hair "manbun"         hair pulled back into a low bun at the back of the head (never a high top-knot), a faded
#                         undercut; the hair tie in band_pal when given (no headband: that needs headband: true)
#   boxed_beard: true     a short, trimmed beard: a straight cheek line, the jaw strap, chin and mustache
#   thin_mustache: true   a thin line over the lip (no beard)
#   hair "curls"          (P11-14) short tight curls: a low rounded mound over the top, bumpy at the edge, with the
#                         twists' knot texture (never a headband: Zigzag's look, the hard rule's spread)
#   arm_len: 1.08         (P11-14, pixel3d.build) upper and fore arm this much longer (default 1: everyone else)
# Era palettes are the ERA3_* rows of crews.json. tools/art/make_players.py --legends-sample present draws the owner's
# look sample (docs/art/legends_present_sample_v1.png and .gif); nothing in assets/ is written by it.

ERA3_SHORTS_LEN = 0.7       # thigh fraction under the shorts (mid-thigh; era 1 0.46, today's shortest 0.62)
ERA3_SHORTS_SLIM = 0.3      # thigh radius taken off under the shorts (today's shorts add 0.45: a slimmer cut)
ERA3_STRIPE = 0.8           # the side stripe: the outer part of the leg, as a fraction of the sphere radius
ERA3_SEAM = 0.82            # the tights' seam, the same way
ERA3_LOW_LEN = 0.1          # calf fraction under low socks
ERA3_KNEE = (0.76, 0.34)    # knee sleeve: from thigh fraction a to calf fraction b
ERA3_KNEE_BAND = 0.05       # the darker band at each end of the sleeve
ERA3_LINEUP_Y = 1.45        # head-local height of the straight front hairline (crop, waves, hightop fade)
ERA3_WAVE_CROWN = (0.0, 4.3, -0.8)   # head-local centre of the wave rings
ERA3_WAVE_STEP = 1.7        # ring spacing (head-local units; about 2 px in the frame)
ERA3_HAIR = ("crop", "waves", "hightop_fade", "manbun", "curls")
ERA3_CURL_BUMPS = ((1.9, 4.35, 0.9), (-1.9, 4.35, 0.9), (0.0, 4.75, 0.2), (2.9, 3.4, -0.9), (-2.9, 3.4, -0.9),
                   (1.3, 4.4, -2.0), (-1.3, 4.4, -2.0), (0.0, 3.3, -3.4))   # P11-14 curls: head-local bump centres
ERA3_CURL_R = 1.05
ERA3_KEYS = ("modern_shorts", "tights", "knee_sleeve", "boxed_beard", "thin_mustache")

_P10_BUILD = P.build


def is_era3(p):
    return p.get("hair") in ERA3_HAIR or p.get("socks") == "low" or any(p.get(k) for k in ERA3_KEYS)


def build_era3(p, pose, expr="focus", portrait=False):
    if not is_era3(p):
        return _P10_BUILD(p, pose, expr, portrait)
    style = p.get("hair")
    q = dict(p)
    if style in ERA3_HAIR:
        q["hair"] = "bald"
    if p.get("modern_shorts") and not p.get("shorts_len_set"):
        q["shorts_len"] = ERA3_SHORTS_LEN
    if p.get("socks") == "low" and not p.get("sock_len_set"):
        q["sock_len"] = ERA3_LOW_LEN
    if p.get("tights"):
        q["tight"] = None          # drawn below on the legs it names
    prims, info, pp = _P10_BUILD(q, pose, expr, portrait)
    if p.get("knee_pal"):
        pp["knee"] = P.pal(p["knee_pal"])
    if p.get("tights") and "tight" not in pp:
        pp["tight"] = P.pal(p["tight_pal"])
    head_c, Rh = info["head_c"], info["Rh"]
    HX, HY, HZ = info["HX"], info["HY"], info["HZ"]

    def H(x, y, z):
        return head_c + Rh @ P.vec(x, y, z)

    def head_local(h):
        return Rh.T @ (h - head_c) / (HK * HK)

    def hairline(l):
        return 1.55 * max(-1.0, min(1.0, l[2] / 3.6)) + 0.25

    # --- legs: modern shorts (slim, side stripe), tights, knee sleeve. Leg spheres come L thigh, L calf, L shoe, then
    # R (pixel3d.build order), like the knee pads.
    slen = q["shorts_len"]
    tights = p.get("tights")
    knee = p.get("knee_sleeve")
    side, sname, seen_shoe = 1.0, "L", False
    for pr in prims:
        if pr.part == "shoe":
            seen_shoe = True
            continue
        if pr.part == "thigh" and seen_shoe:
            side, sname, seen_shoe = -1.0, "R", False
        if pr.part not in ("thigh", "calf"):
            continue
        under = pr.t < slen if pr.part == "thigh" else pr.t < slen - 1.0
        if p.get("modern_shorts") and under and pr.part == "thigh":
            pr.r = max(0.6, pr.r - ERA3_SHORTS_SLIM)
        if not callable(pr.mat):
            continue
        tight_here = tights in ("both", sname)
        knee_here = knee == sname and ((pr.part == "thigh" and pr.t >= ERA3_KNEE[0])
                                      or (pr.part == "calf" and pr.t <= ERA3_KNEE[1]))

        def leg3_mat(h, prim, orig=pr.mat, sx=side, th=tight_here, kn=knee_here):
            m = orig(h, prim)
            out = (h - prim.c)[0] * sx
            if p.get("modern_shorts") and m == "shorts" and out > prim.r * ERA3_STRIPE:
                return "shorts_trim"
            if kn and m in ("skin", "tight"):
                a, b = ERA3_KNEE
                edge = (prim.part == "thigh" and prim.t < a + ERA3_KNEE_BAND) or \
                       (prim.part == "calf" and prim.t > b - ERA3_KNEE_BAND)
                return "knee+1" if edge else "knee"
            if th and m == "skin":
                return "tight+1" if out > prim.r * ERA3_SEAM else "tight"
            return m
        pr.mat = leg3_mat

    # --- head: the era's hair (on the bald head's skin) and the face parts
    def face3(l, m):
        x, y, z = l
        if m != "skin":
            return m
        ax = abs(x)
        hl = hairline(l)
        if style in ("crop", "waves", "hightop_fade"):
            # line-up: a straight front hairline, squared temples, the back and sides following the head
            line = min(hl + 0.2, ERA3_LINEUP_Y) if z > 0.6 else hl + 0.2
            if ax > 2.5 and z > 0.0:
                line = min(line, 0.7)       # the squared temple corners
            if y > line:
                if style == "hightop_fade":
                    return "hair" if (y > 2.2 and ax < 2.7 and z > -2.4) or (z > 2.2 and y > ERA3_LINEUP_Y) \
                        else "skin+1"       # faded sides and back
                if style == "waves":
                    cx, cy, cz = ERA3_WAVE_CROWN
                    dd = math.sqrt((x - cx) ** 2 + (y - cy) ** 2 + (z - cz) ** 2)
                    return "hair-1" if (dd / ERA3_WAVE_STEP) % 1.0 < 0.42 else "hair"
                return "hair"
        if style == "curls" and y > hl + 0.1:
            return "hair"
        if style == "manbun" and y > hl + 0.15:
            return "skin+1" if ax > 2.55 and y < 2.0 else "hair"     # the faded undercut
        if p.get("boxed_beard") and z > -0.4:
            if (ax > 2.5 and y < 0.1) or (ax > 1.5 and y < -1.7) or y < -2.45:
                if not (ax < 1.0 and -2.35 < y < -1.55 and z > 2.0):
                    return "hair"
            if -1.5 < y < -1.05 and ax < 1.4 and z > 2.2:
                return "hair"
        if p.get("thin_mustache") and z > 2.1 and -1.45 < y < -0.95 and ax < 1.35:
            return "hair"
        return m

    for pr in prims:
        if pr.part == "head" and callable(pr.mat):
            def wrapped3(h, prim, orig=pr.mat):
                return face3(head_local(h), orig(h, prim))
            pr.mat = wrapped3
    if style == "hightop_fade":    # a squared block on top, cut flat
        prims.append(P.ell(H(0, 3.2, -0.15), Rh, HX - 0.3, 3.0, HZ - 0.25, "hair", "hair",
                           clip=(H(0, 5.6, 0), Rh @ P.unit(0, -1.0, 0))))
    if style == "curls":           # a low mound of tight curls, a few bumps round its edge for the outline
        prims.append(P.ell(H(0, 1.25, -0.4), Rh, HX + 0.55, HY + 0.4, HZ + 0.5, "hair_tw", "hair",
                           clip=(H(0, 0.55, 0), Rh @ P.unit(0, 1.0, -0.6))))
        for bx, by, bz in ERA3_CURL_BUMPS:
            prims.append(P.Sphere(H(bx, by, bz), ERA3_CURL_R, "hair_tw", "hair"))
    if style == "manbun":          # the hair pulled back over the top, and a low bun at the back of the head
        prims.append(P.ell(H(0, 0.9, -0.4), Rh, HX + 0.2, HY + 0.12, HZ + 0.25, "hair", "hair",
                           clip=(H(0, 1.5, 0), Rh @ P.unit(0, 1.0, -0.35))))
        prims.append(P.ell(H(0, 0.9, -4.4), Rh, 1.05, 1.0, 0.55,
                           "band" if p.get("band_pal") else "hair+2", "hair"))    # the tie (band_pal: a colored one)
        prims.append(P.Sphere(H(0, 0.8, -5.4), 1.4, "hair_tw", "hair"))
    return prims, info, pp


P.build = build_era3


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
    """Indexed-palette PNG (exact colors, index 0 transparent) when the sheet has at most 255 colors and that file
    is smaller than the RGBA one (Phase 5 measure); otherwise RGBA. Pixels are identical either way."""
    img.save(path, optimize=True)
    rgba_size = os.path.getsize(path)
    a = np.array(img)
    opaque = a[:, :, 3] > 0
    if not opaque.any() or (a[:, :, 3][opaque] != 255).any():
        return "rgba"
    cols, inv = np.unique(a[:, :, :3][opaque].reshape(-1, 3), axis=0, return_inverse=True)
    if len(cols) > 255:
        return "rgba"
    idx = np.zeros(a.shape[:2], np.uint8)
    idx[opaque] = inv.reshape(-1) + 1
    q = Image.fromarray(idx, "P")
    flat = [0, 0, 0] + [int(v) for v in cols.reshape(-1)]
    q.putpalette(flat + [0] * (768 - len(flat)))
    tmp = path + ".tmp.png"
    q.save(tmp, optimize=True, transparency=0)
    if os.path.getsize(tmp) < rgba_size:
        os.replace(tmp, path)
        return "indexed"
    os.remove(tmp)
    return "rgba"


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


P5_GROUPS = [("Your crew: the underdogs (blue ring)", lambda p: p["crew"] == "U" and "recolor_of" not in p),
             ("Hometown: County Line (green and white, red ring)", lambda p: p["crew"] == "HT"),
             ("Chicago: Lakeshore Gusts (purple and white, red ring)", lambda p: p["crew"] == "CHI"),
             ("New York champions: Concrete Crowns", lambda p: p["crew"] == "NY"),
             ("Recruits in your colors (<id>_crew)", lambda p: "recolor_of" in p)]
P6_GROUPS = [("Memphis: Riverside Soul (orange and black)", lambda p: p["crew"] == "MEM"),
             ("New Orleans: Bayou Brass (teal and white)", lambda p: p["crew"] == "NOL"),
             ("Denver: Switchbacks (forest and silver)", lambda p: p["crew"] == "DEN"),
             ("Seattle: Puddle Jumpers (navy and lime)", lambda p: p["crew"] == "SEA"),
             ("Los Angeles: Boardwalk Bombers (sky and sand)", lambda p: p["crew"] == "LA"),
             ("New York quarterfinal: Bridge Runners (red and black)", lambda p: p["crew"] == "NYQ"),
             ("New York semifinal: Bodega Bandits (grey and plum)", lambda p: p["crew"] == "NYS"),
             ("New York final: Concrete Crowns (black and gold)", lambda p: p["crew"] == "NYF"),
             ("Phase 6 recruits in your colors (<id>_crew)", lambda p: "recolor_of" in p)]


def preview_p5(players, all_frames, path=PREVIEW_P5, zoom=3, per_line=5, groups=None):
    """Phase 5 check: every new player standing S, E, N plus one action frame (crews.json 'action'), by crew.
    Phase 6 uses it too (groups=P6_GROUPS)."""
    cell = 42
    block = 4 * cell + 14
    head = 16
    lines = []
    for title, keep in (groups or P5_GROUPS):
        grp = [p for p in players if keep(p)]
        for i in range(0, len(grp), per_line):
            lines.append((title if i == 0 else None, grp[i:i + per_line]))
    w = per_line * block + 8
    h = sum((head if t else 0) + FH + 16 for t, _ in lines) + 6
    base = Image.new("RGBA", (w, h), P.hexc("#c99a62") + (255,))
    dr = ImageDraw.Draw(base)
    labels = []
    y = 4
    for title, grp in lines:
        if title:
            dr.rectangle([0, y, w, y + head - 4], fill=P.hexc("#1c1a26"))
            labels.append((title, 4, y + 1, True))
            y += head
        for b, p in enumerate(grp):
            fr = all_frames[p["id"]]
            act = tuple(p.get("action", ["shoot", 2]))
            seq = [fr[("S", "idle", 0)], fr[("E", "idle", 0)], fr[("N", "idle", 0)], fr[("E", act[0], act[1])]]
            x_b = 4 + b * block
            for c, img in enumerate(seq):
                x0 = x_b + c * cell + (cell - FW) // 2
                ring = ring_image(p["ring"])
                base.alpha_composite(ring, (x0, y + 10 + P.GROUND_Y - ring.size[1] // 2 - 1))
                base.alpha_composite(img, (x0, y + 10))
            labels.append(("%s  %s #%d  (S E N, %s)" % (p["id"], p["title"], p["number"], act[0]), x_b + 2, y, False))
        y += FH + 16
    big = base.resize((w * zoom, h * zoom), Image.NEAREST)
    dr = ImageDraw.Draw(big)
    for txt, x, yy, is_head in labels:
        dr.text((x * zoom + 4, yy * zoom + 4), txt, font=font(22 if is_head else 17),
                fill=(250, 244, 230) if is_head else (28, 20, 30))
    big.convert("RGB").save(path, optimize=True)


def _job(p):
    sheet, frames, probs, hp = make_sheet(p)
    return p["id"], sheet, frames, probs, hp


# ----------------------------------------------------------------------------- Phase 9 legend look sample (P9-04)
# --legends-sample: one Grandfathers look (Steeple, the hook-shot center of docs/legends-plan.md; L1 a) in the
# v2 sheet style (tools/art/make_players_v2.py's renderer, poses and preview helpers, imported read only), for the
# owner's look check before P9-09 makes the legend sheets. Writes only docs/art/legends_sample_v1.png and .gif.
# The look is data here, not in crews.json (no sheet is made from it); the number is a placeholder (the legends'
# numbers come from a list the owner approves). The parts row puts the other era parts on plain bodies: a parts
# check, not the other legends' final looks.

LEGEND_SAMPLE_PNG = os.path.join(ROOT, "docs", "art", "legends_sample_v1.png")
LEGEND_SAMPLE_GIF = os.path.join(ROOT, "docs", "art", "legends_sample_v1.gif")
_ERA_KIT = {"top": "tank", "sleeve": None, "tight": None, "era_shorts": True, "socks": "striped"}
LEGEND_SAMPLE = dict(_ERA_KIT, **{
    "id": "lg_sample_steeple", "crew": "B", "number": 18, "role": "hook-shot center", "name": "Steeple",
    "body": "wiry_center", "body_tweak": {"leg": 0.05, "torso": 0.02, "width": -0.05, "mass": -0.1},
    "skin": "umber", "hair": "buzz", "hair_pal": "HAIR_BLACK", "chops": True, "terry": True, "band_pal": "ERA_MUSTARD",
    "top_pal": "ERA_RUST", "trim_pal": "ERA_CREAM", "shorts_pal": "ERA_RUST", "shorts_trim": "ERA_CREAM",
    "shorts_len": ERA_SHORTS_LEN, "sock_pal": "ERA_CREAM", "sock_len": ERA_SOCK_LEN, "stripe_pal": "ERA_RUST",
    "stripe2_pal": "ERA_MUSTARD", "shoe_pal": "ERA_CREAM", "shoe_acc": "ERA_RUST", "sole_pal": "ERA_GUM"})
# your colors (a drafted legend wears them, like a _crew recolor): era palette names swapped
LEGEND_SAMPLE_CREW = {"ERA_CREAM": "WHITE", "ERA_RUST": "BLUE", "ERA_MUSTARD": "GOLD"}
PARTS_CHECK = [  # (label, entry): the other era parts on plain bodies (not final looks)
    ("flat-top, knee pads", dict(_ERA_KIT, id="era_part_1", crew="B", number=4, body="heavy_big", skin="light",
                                hair="flattop", hair_pal="HAIR_BROWN", kneepads="both", pad_pal="ERA_PAD",
                                top_pal="ERA_OLIVE", trim_pal="ERA_CREAM", shorts_pal="ERA_OLIVE",
                                shorts_trim="ERA_CREAM", sock_pal="ERA_CREAM", stripe_pal="ERA_OLIVE",
                                shoe_pal="ERA_CREAM", shoe_acc="ERA_OLIVE", sole_pal="ERA_GUM")),
    ("mustache, tall socks", dict(_ERA_KIT, id="era_part_2", crew="B", number=2, body="stocky_guard", skin="tan",
                                  hair="buzz", hair_pal="HAIR_DARK", mustache=True, top_pal="ERA_POWDER",
                                  trim_pal="ERA_BROWN", shorts_pal="ERA_BROWN", shorts_trim="ERA_POWDER",
                                  sock_pal="ERA_CREAM", stripe_pal="ERA_POWDER", stripe2_pal="ERA_BROWN",
                                  shoe_pal="ERA_CREAM", shoe_acc="ERA_BROWN", sole_pal="ERA_GUM")),
    ("afro + terry band", dict(_ERA_KIT, id="era_part_3", crew="B", number=9, body="lanky_wing", skin="brown",
                               hair="afro", hair_pal="HAIR_BLACK", terry=True, band_pal="ERA_CREAM",
                               top_pal="ERA_MUSTARD", trim_pal="ERA_BROWN", shorts_pal="ERA_MUSTARD",
                               shorts_trim="ERA_BROWN", sock_pal="ERA_CREAM", stripe_pal="ERA_BROWN",
                               stripe2_pal="ERA_MUSTARD", shoe_pal="ERA_CREAM", shoe_acc="ERA_BROWN",
                               sole_pal="ERA_GUM")),
    ("chops + mustache, pad", dict(_ERA_KIT, id="era_part_4", crew="B", number=5, body="power_forward",
                                   skin="deep", hair="bald", hair_pal="HAIR_BLACK", chops=True, mustache=True,
                                   wrist=True, wrist_pal="ERA_CREAM", kneepads="R", pad_pal="ERA_RUST",
                                   top_pal="ERA_BROWN", trim_pal="ERA_MUSTARD", shorts_pal="ERA_BROWN",
                                   shorts_trim="ERA_MUSTARD", sock_pal="ERA_CREAM", stripe_pal="ERA_BROWN",
                                   shoe_pal="ERA_CREAM", shoe_acc="ERA_BROWN", sole_pal="ERA_GUM")),
]
SAMPLE_REF = "ud_deuce"     # today's player next to the sample, for size and style
SAMPLE_ANIMS = ["idle", "run", "run_dribble", "dunk_two", "dunk_one"]


def _sample_players():
    """The sample entries through load_players (palettes, bodies) from a scratch copy of crews.json."""
    import tempfile
    raw = json.load(open(CREWS))
    crew = dict(LEGEND_SAMPLE)
    crew.update({k: LEGEND_SAMPLE_CREW.get(v, v) for k, v in LEGEND_SAMPLE.items() if isinstance(v, str)})
    crew.update({"id": LEGEND_SAMPLE["id"] + "_crew", "crew": "U"})
    entries = [dict(LEGEND_SAMPLE), crew] + [dict(e) for _, e in PARTS_CHECK]
    for e in entries:
        e.setdefault("sock_len", ERA_SOCK_LEN)
        e.setdefault("shorts_len", ERA_SHORTS_LEN)
    raw["players"] = entries
    fd, tmp = tempfile.mkstemp(suffix=".json")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(raw, f)
        return {p["id"]: p for p in load_players(tmp)}
    finally:
        os.remove(tmp)


def _render_anims(V, p, anims, dirs):
    D = V.dims_of(p)
    out, probs = {}, []
    for name in anims:
        poses = V.anim_poses(name, D)
        for dname, yaw in V.DIRS:
            if dname not in dirs:
                continue
            seq = []
            for k, (pose, ball) in enumerate(poses):
                img, rec = V.render_frame(p, pose, ball, yaw, V.EXPR.get(name, "focus"))
                probs += V.check(img, rec, "%s %s %s %d" % (p["id"], name, dname, k))
                seq.append((img, rec))
            out[(name, dname)] = seq
    return out, probs


def legends_sample(argv):
    if __name__ == "__main__":
        sys.modules["make_players"] = sys.modules["__main__"]    # make_players_v2 imports this module: no re-patch
    import make_players_v2 as V
    import make_anim_sample as AS
    ps = _sample_players()
    sid, cid = LEGEND_SAMPLE["id"], LEGEND_SAMPLE["id"] + "_crew"
    ref = [q for q in V.players_v2() if q["id"] == SAMPLE_REF][0]
    alld = ("S", "SE", "E", "NE", "N")
    fr, probs = {}, []
    for pid, p in ((sid, ps[sid]), (cid, ps[cid]), (SAMPLE_REF, ref)):
        fr[pid], pr = _render_anims(V, p, SAMPLE_ANIMS, alld)
        probs += pr
    parts = []
    for lab, e in PARTS_CHECK:
        f, pr = _render_anims(V, ps[e["id"]], ["idle", "run"], ("S", "SE", "E"))
        parts.append((lab, f))
        probs += pr

    # --- the PNG
    Z, pad, lab_h = 2, 6, 18
    cw, chh = V.FW * Z, V.FH * Z
    cells_per_row = 10
    W = 150 + cells_per_row * (cw + pad)

    def C(f, name, dn, k=0, flip=False):
        img, rec = f[(name, dn)][k]
        if flip:
            return V.compose(img.transpose(Image.FLIP_LEFT_RIGHT), dict(rec, ball=None))
        return V.compose(img, rec)

    def strip(f):
        r = [C(f, "idle", dn) for dn in alld] + [C(f, "idle", "E", flip=True)]
        r += [C(f, "run", "E", 3), C(f, "run_dribble", "SE", 2), C(f, "dunk_two", "SE", 5), C(f, "dunk_one", "E", 7)]
        return r

    heads = ("idle S SE E NE N W (mirrored) | run E | running dribble SE | two-hand dunk SE (hang) | one-hand dunk E "
             "(at the rim; the game adds the jump height)")
    rows = [("STEEPLE, era colors", strip(fr[sid])), ("in your colors", strip(fr[cid])),
            ("today: " + SAMPLE_REF, strip(fr[SAMPLE_REF]))]
    prow = []
    for lab, f in parts:
        prow += [C(f, "idle", "S"), C(f, "run", "SE", 2)]
    H = 64 + len(rows) * (chh + lab_h + pad) + 2 * 30 + (chh + lab_h + pad) + 4 * V.FH + 2 * pad
    base = AS.floor_bg(W, H)
    dr = ImageDraw.Draw(base)
    dr.rectangle([0, 0, W, 56], fill=(28, 26, 38, 255))
    AS.label(dr, (8, 6), "Legends look sample v1 (P9-04): the Grandfathers era parts on Steeple, the hook-shot "
                         "center (an original character; number 18 is a placeholder). Shown 2x as in the game.", 14)
    AS.label(dr, (8, 30), heads, 12, (210, 204, 224))
    y = 64
    for name, r in rows:
        AS.label(dr, (8, y + lab_h + chh // 2 - 8), name, 13)
        for c, cell in enumerate(r):
            base.alpha_composite(cell.resize((cw, chh), Image.NEAREST), (150 + c * (cw + pad), y + lab_h))
        y += chh + lab_h + pad
    dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
    AS.label(dr, (8, y + 4), "Parts check: the other era parts on plain bodies (idle S, run SE). Not the other "
                             "legends' final looks (P9-09 makes those).", 13)
    y += 30
    for i, (lab, f) in enumerate(parts):
        AS.label(dr, (150 + 2 * i * (cw + pad) + 2, y + 2), lab, 12)
    for c, cell in enumerate(prow):
        base.alpha_composite(cell.resize((cw, chh), Image.NEAREST), (150 + c * (cw + pad), y + lab_h))
    y += chh + lab_h + pad
    dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
    AS.label(dr, (8, y + 4), "Close-up 4x: terry headband, mutton chops, short shorts, striped tube socks (S, SE, E, "
                             "NE, N)", 13)
    y += 30
    x = 150
    for dn in alld:
        img, rec = fr[sid][("idle", dn)][0]
        base.alpha_composite(img.resize((V.FW * 4, V.FH * 4), Image.NEAREST), (x, y))
        x += V.FW * 4 + pad
    base.convert("RGB").save(LEGEND_SAMPLE_PNG, optimize=True)
    print("wrote %s %s %d bytes" % (LEGEND_SAMPLE_PNG, base.size, os.path.getsize(LEGEND_SAMPLE_PNG)))

    # --- the GIF: era colors, your colors and today's player side by side
    moves = [("idle", "S", 1), ("run", "SE", 2), ("run", "E", 2), ("run_dribble", "SE", 2), ("run_dribble", "E", 2),
             ("dunk_two", "SE", 1), ("dunk_one", "E", 1), ("idle", "SE", 1)]
    top, head = 30, 22
    panels = [(sid, "STEEPLE"), (cid, "YOUR COLORS"), (SAMPLE_REF, "TODAY")]
    gw = pad + len(panels) * (cw + pad)
    gh = head + (V.FH + top) * Z + pad + 14
    frames, durs = [], []
    for name, dn, loops in moves:
        ms = V.ANIM[name][3]
        lift = V.PREVIEW_LIFT.get(name)
        for _ in range(loops):
            for k, dur in enumerate(ms):
                bg = AS.floor_bg(gw, gh)
                d2 = ImageDraw.Draw(bg)
                d2.rectangle([0, 0, gw, head - 4], fill=(28, 26, 38, 255))
                AS.label(d2, (6, 3), "%s (%s) %d/%d" % (name, dn, k + 1, len(ms)), 13)
                for c, (pid, title) in enumerate(panels):
                    img, rec = fr[pid][(name, dn)][k]
                    cell = AS.compose_frame(img, rec, lift=lift[k] if lift else 0, ball_spin=k, top=top)
                    bg.alpha_composite(cell.resize((cw, (V.FH + top) * Z), Image.NEAREST),
                                       (pad + c * (cw + pad), head))
                    AS.label(d2, (pad + c * (cw + pad) + 4, gh - 18), title, 11)
                frames.append(bg)
                durs.append(max(20, dur))
    AS.gif_save(frames, durs, LEGEND_SAMPLE_GIF)
    print("wrote %s %d frames %d bytes" % (LEGEND_SAMPLE_GIF, len(frames), os.path.getsize(LEGEND_SAMPLE_GIF)))
    for s in probs:
        print("CHECK", s)
    print("checks: %d problem(s)" % len(probs))
    return len(probs)


# ----------------------------------------------------------------------------- Phase 10 legend look sample (P10-04)
# --legends-sample fathers: two Fathers looks (Rooftop, the high-flying shooting guard, and Eyes Closed, the no-look
# passer; F1 a) in the v2 sheet style, for the owner's look check before P10-14 makes the six sheets. Writes only
# docs/art/legends_fathers_sample_v1.png and .gif. The looks are data here, not in crews.json (no sheet is made from
# them); numbers are placeholders (the owner approves the list) and the surnames are not picked yet. The parts row
# puts the other era parts on plain bodies, in the way the hard rule spreads them (a parts check, not final looks).
# The combination check (docs/BOARD.md Phase 10): the small quick crossover guard gets no cornrows and no arm sleeve;
# the cornrows go to a tall wing (Rooftop) with a LEFT arm sleeve and no headband; the other sleeves are a right arm
# sleeve on a buzz-cut defender and leg sleeves.

FATHERS_SAMPLE_PNG = os.path.join(ROOT, "docs", "art", "legends_fathers_sample_v1.png")
FATHERS_SAMPLE_GIF = os.path.join(ROOT, "docs", "art", "legends_fathers_sample_v1.gif")
FATHERS_FLOOR = os.path.join(ROOT, "assets", "courts", "blacktop_floor.png")   # read only: the era plays outdoors
_ERA2_KIT = {"top": "tank", "sleeve": None, "tight": None, "baggy": True, "socks": "crew",
             "sock_pal": "ERA2_ICE", "shoe_pal": "ERA2_ICE"}
FATHERS_SAMPLE = [
    ("ROOFTOP", "high-flying shooting guard: tall and lanky, cornrows, left arm sleeve, baggy shorts, crew socks",
     dict(_ERA2_KIT, id="lg_sample_rooftop", crew="B", number=27, role="high-flying shooting guard", name="Rooftop",
          body="lanky_wing", body_tweak={"leg": 0.04, "torso": 0.01}, skin="brown", hair="cornrows",
          hair_pal="HAIR_BLACK", sleeve="L", sleeve_pal="ERA2_CHARCOAL", top_pal="ERA2_SEAFOAM",
          trim_pal="ERA2_ICE", shorts_pal="ERA2_SEAFOAM", shorts_trim="ERA2_CHARCOAL", stripe_pal="ERA2_SEAFOAM",
          shoe_acc="ERA2_SEAFOAM", sole_pal="ERA2_CHARCOAL")),
    ("EYES CLOSED", "no-look passer: slim, durag, wristbands, right leg sleeve, baggy shorts, crew socks",
     dict(_ERA2_KIT, id="lg_sample_eyes_closed", crew="B", number=14, role="no-look passer", name="Eyes Closed",
          body="slim_guard", skin="deep", hair="durag", hair_pal="HAIR_BLACK", rag_pal="ERA2_TANGERINE", wrist=True,
          wrist_pal="ERA2_ICE", tight="R", tight_pal="ERA2_STEEL", top_pal="ERA2_BRICK", trim_pal="ERA2_TANGERINE",
          shorts_pal="ERA2_BRICK", shorts_trim="ERA2_TANGERINE", stripe_pal="ERA2_BRICK", shoe_acc="ERA2_BRICK",
          sole_pal="ERA2_TANGERINE")),
]
# your colors (a drafted legend wears them, like a _crew recolor): era palette names swapped
FATHERS_SAMPLE_CREW = {"ERA2_SEAFOAM": "BLUE", "ERA2_BRICK": "BLUE", "ERA2_GRAPE": "BLUE", "ERA2_CHARCOAL": "NAVY",
                       "ERA2_STEEL": "NAVY", "ERA2_TANGERINE": "GOLD", "ERA2_CITRUS": "GOLD", "ERA2_ICE": "WHITE"}
FATHERS_PARTS_CHECK = [  # (label, entry): the other era parts on plain bodies, spread as the hard rule asks
    ("small guard: twists, headband", dict(_ERA2_KIT, id="era2_part_1", crew="B", number=5, body="stocky_guard",
                                           skin="tan", hair="twists", hair_pal="HAIR_DARK", headband=True,
                                           band_pal="ERA2_ICE", top_pal="ERA2_CITRUS", trim_pal="ERA2_CHARCOAL",
                                           shorts_pal="ERA2_CITRUS", shorts_trim="ERA2_CHARCOAL",
                                           stripe_pal="ERA2_CHARCOAL", shoe_acc="ERA2_CHARCOAL",
                                           sole_pal="ERA2_CHARCOAL")),
    ("big: goatee, headband", dict(_ERA2_KIT, id="era2_part_2", crew="B", number=8, body="heavy_big", skin="umber",
                                   hair="bald", hair_pal="HAIR_BLACK", goatee=True, headband=True,
                                   band_pal="ERA2_CITRUS", top_pal="ERA2_GRAPE", trim_pal="ERA2_CITRUS",
                                   shorts_pal="ERA2_GRAPE", shorts_trim="ERA2_CITRUS", stripe_pal="ERA2_GRAPE",
                                   shoe_acc="ERA2_GRAPE", sole_pal="ERA2_CITRUS")),
    ("wing: buzz, right sleeve", dict(_ERA2_KIT, id="era2_part_3", crew="B", number=2, body="lanky_guard",
                                      skin="light", hair="buzz", hair_pal="HAIR_BROWN", sleeve="R",
                                      sleeve_pal="ERA2_CHARCOAL", top_pal="ERA2_STEEL", trim_pal="ERA2_CITRUS",
                                      shorts_pal="ERA2_STEEL", shorts_trim="ERA2_CITRUS", stripe_pal="ERA2_STEEL",
                                      shoe_acc="ERA2_STEEL", sole_pal="ERA2_STEEL")),
    ("fade, left leg sleeve", dict(_ERA2_KIT, id="era2_part_4", crew="B", number=6, body="wiry_center",
                                   skin="umber", hair="part", hair_pal="HAIR_BLACK", tight="L",
                                   tight_pal="ERA2_CHARCOAL", top_pal="ERA2_TANGERINE", trim_pal="ERA2_STEEL",
                                   shorts_pal="ERA2_TANGERINE", shorts_trim="ERA2_STEEL", stripe_pal="ERA2_TANGERINE",
                                   shoe_acc="ERA2_TANGERINE", sole_pal="ERA2_STEEL")),
]
FATHERS_ANIMS = ["idle", "run", "run_dribble", "dunk_tomahawk", "dunk_one"]


def _load_entries(entries):
    """Sample entries through load_players (palettes, bodies) from a scratch copy of crews.json."""
    import tempfile
    raw = json.load(open(CREWS))
    raw["players"] = entries
    fd, tmp = tempfile.mkstemp(suffix=".json")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(raw, f)
        return {p["id"]: p for p in load_players(tmp)}
    finally:
        os.remove(tmp)


def _fathers_players():
    entries = []
    for _, _, e in FATHERS_SAMPLE:
        entries.append(dict(e))
        c = {k: (FATHERS_SAMPLE_CREW.get(v, v) if isinstance(v, str) else v) for k, v in e.items()}
        c.update({"id": e["id"] + "_crew", "crew": "U"})
        entries.append(c)
    entries += [dict(e) for _, e in FATHERS_PARTS_CHECK]
    for e in entries:
        e.setdefault("shorts_len", ERA2_BAGGY_LEN)
        e.setdefault("sock_len", ERA2_CREW_LEN)
    return _load_entries(entries)


def _blacktop_bg(w, h, show=2):
    if not os.path.exists(FATHERS_FLOOR):
        return Image.new("RGBA", (w, h), (52, 54, 62, 255))
    t = Image.open(FATHERS_FLOOR).convert("RGBA")
    t = t.resize((t.width * show, t.height * show), Image.NEAREST)
    bg = Image.new("RGBA", (w, h))
    for y in range(0, h, t.height):
        for x in range(0, w, t.width):
            bg.paste(t, (x, y))
    return bg


def legends_sample_fathers(argv):
    if __name__ == "__main__":
        sys.modules["make_players"] = sys.modules["__main__"]    # make_players_v2 imports this module: no re-patch
    import make_players_v2 as V
    import make_anim_sample as AS
    ps = _fathers_players()
    ref = [q for q in V.players_v2() if q["id"] == SAMPLE_REF][0]
    alld = ("S", "SE", "E", "NE", "N")
    fr, probs = {}, []
    looks = []
    for title, desc, e in FATHERS_SAMPLE:
        looks.append((title, desc, e["id"], e["id"] + "_crew"))
    for _, _, sid, cid in looks:
        for pid in (sid, cid):
            fr[pid], pr = _render_anims(V, ps[pid], FATHERS_ANIMS, alld)
            probs += pr
    fr[SAMPLE_REF], pr = _render_anims(V, ref, FATHERS_ANIMS, alld)
    probs += pr
    parts = []
    for lab, e in FATHERS_PARTS_CHECK:
        f, pr = _render_anims(V, ps[e["id"]], ["idle", "run"], ("S", "SE", "E", "N"))
        parts.append((lab, f))
        probs += pr

    # --- the PNG
    Z, pad, lab_h = 2, 6, 18
    cw, chh = V.FW * Z, V.FH * Z
    cells_per_row = 10
    lx = 170
    W = lx + cells_per_row * (cw + pad)

    def C(f, name, dn, k=0, flip=False):
        img, rec = f[(name, dn)][k]
        if flip:
            return V.compose(img.transpose(Image.FLIP_LEFT_RIGHT), dict(rec, ball=None))
        return V.compose(img, rec)

    def strip(f):
        r = [C(f, "idle", dn) for dn in alld] + [C(f, "idle", "E", flip=True)]
        r += [C(f, "run", "E", 3), C(f, "run_dribble", "SE", 2), C(f, "dunk_tomahawk", "SE", 5),
              C(f, "dunk_one", "E", 7)]
        return r

    heads = ("idle S SE E NE N W (mirrored) | run E | running dribble SE | tomahawk dunk SE (hang) | one-hand dunk E "
             "(at the rim; the game adds the jump height)")
    rows = []
    for title, desc, sid, cid in looks:
        rows += [(title + ", era colors", desc, strip(fr[sid])), ("  in your colors", "", strip(fr[cid]))]
    rows.append(("today: " + SAMPLE_REF, "", strip(fr[SAMPLE_REF])))
    prow = []
    for lab, f in parts:
        prow += [C(f, "idle", "S"), C(f, "run", "SE", 2)]
    bar = 30
    card_z = 3
    H = (64 + len(rows) * (chh + lab_h + pad) + 3 * bar + (chh + lab_h + pad) + V.FH * card_z + lab_h + pad
         + 4 * V.FH + 3 * pad)
    base = _blacktop_bg(W, H)
    dr = ImageDraw.Draw(base)
    dr.rectangle([0, 0, W, 56], fill=(28, 26, 38, 255))
    AS.label(dr, (8, 6), "Legends look sample v1 (P10-04): the Fathers era parts (2000s) on two looks, Rooftop and "
                         "Eyes Closed (original characters; numbers are placeholders). Shown 2x as in the game, on "
                         "the blacktop.", 14)
    AS.label(dr, (8, 30), heads, 12, (210, 204, 224))
    y = 64
    for name, desc, r in rows:
        dr.rectangle([0, y, W, y + lab_h - 2], fill=(28, 26, 38, 200))
        AS.label(dr, (8, y + 1), name + (": " + desc if desc else ""), 12)
        for c, cell in enumerate(r):
            base.alpha_composite(cell.resize((cw, chh), Image.NEAREST), (lx + c * (cw + pad), y + lab_h))
        y += chh + lab_h + pad
    dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
    AS.label(dr, (8, y + 4), "Parts check: the other era parts on plain bodies, spread over different builds "
                             "(idle S, run SE). Not the other legends' final looks (P10-14 makes those).", 13)
    y += bar
    for i, (lab, f) in enumerate(parts):
        AS.label(dr, (lx + 2 * i * (cw + pad) + 2, y + 2), lab, 12)
    for c, cell in enumerate(prow):
        base.alpha_composite(cell.resize((cw, chh), Image.NEAREST), (lx + c * (cw + pad), y + lab_h))
    y += chh + lab_h + pad
    dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
    AS.label(dr, (8, y + 4), "Cards 3x (idle S, frame 0: the Hall / draft card): era colors and your colors", 13)
    y += bar
    x = lx
    for title, _, sid, cid in looks:
        for pid, sub in ((sid, title), (cid, "your colors")):
            img, _ = fr[pid][("idle", "S")][0]
            box = Image.new("RGBA", (V.FW * card_z, V.FH * card_z), (36, 34, 48, 255))
            box.alpha_composite(img.resize((V.FW * card_z, V.FH * card_z), Image.NEAREST))
            base.alpha_composite(box, (x, y))
            AS.label(dr, (x + 4, y + V.FH * card_z + 2), sub, 12)
            x += V.FW * card_z + 3 * pad
    y += V.FH * card_z + lab_h + pad
    dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
    AS.label(dr, (8, y + 4), "Close-up 4x: cornrows, arm sleeve, baggy shorts with the side panel, crew socks "
                             "(Rooftop S, NE, N) | durag with its tails, wristbands, leg sleeve (Eyes Closed S, N)", 13)
    y += bar
    x = lx
    sid1, sid2 = looks[0][2], looks[1][2]
    for pid, dn in ((sid1, "S"), (sid1, "NE"), (sid1, "N"), (sid2, "S"), (sid2, "N")):
        img, rec = fr[pid][("idle", dn)][0]
        base.alpha_composite(img.resize((V.FW * 4, V.FH * 4), Image.NEAREST), (x, y))
        x += V.FW * 4 + pad
    base.convert("RGB").save(FATHERS_SAMPLE_PNG, optimize=True)
    print("wrote %s %s %d bytes" % (FATHERS_SAMPLE_PNG, base.size, os.path.getsize(FATHERS_SAMPLE_PNG)))

    # --- the GIF: both looks in era colors and your colors, and today's player, side by side
    moves = [("idle", "S", 1), ("run", "SE", 2), ("run", "E", 2), ("run_dribble", "SE", 2), ("run_dribble", "E", 2),
             ("dunk_tomahawk", "SE", 1), ("dunk_one", "E", 1), ("idle", "N", 1)]
    top, head = 30, 22
    panels = [(looks[0][2], looks[0][0]), (looks[0][3], "YOUR COLORS"), (looks[1][2], looks[1][0]),
              (looks[1][3], "YOUR COLORS"), (SAMPLE_REF, "TODAY")]
    gw = pad + len(panels) * (cw + pad)
    gh = head + (V.FH + top) * Z + pad + 14
    frames, durs = [], []
    for name, dn, loops in moves:
        ms = V.ANIM[name][3]
        lift = V.PREVIEW_LIFT.get(name)
        for _ in range(loops):
            for k, dur in enumerate(ms):
                bg = _blacktop_bg(gw, gh)
                d2 = ImageDraw.Draw(bg)
                d2.rectangle([0, 0, gw, head - 4], fill=(28, 26, 38, 255))
                AS.label(d2, (6, 3), "%s (%s) %d/%d" % (name, dn, k + 1, len(ms)), 13)
                d2.rectangle([0, gh - 20, gw, gh], fill=(28, 26, 38, 255))
                for c, (pid, title) in enumerate(panels):
                    img, rec = fr[pid][(name, dn)][k]
                    cell = AS.compose_frame(img, rec, lift=lift[k] if lift else 0, ball_spin=k, top=top)
                    bg.alpha_composite(cell.resize((cw, (V.FH + top) * Z), Image.NEAREST),
                                       (pad + c * (cw + pad), head))
                    AS.label(d2, (pad + c * (cw + pad) + 4, gh - 18), title, 11)
                frames.append(bg)
                durs.append(max(20, dur))
    AS.gif_save(frames, durs, FATHERS_SAMPLE_GIF)
    print("wrote %s %d frames %d bytes" % (FATHERS_SAMPLE_GIF, len(frames), os.path.getsize(FATHERS_SAMPLE_GIF)))
    for s in probs:
        print("CHECK", s)
    print("checks: %d problem(s)" % len(probs))
    return len(probs)


# ----------------------------------------------------------------------------- Phase 11 legend look sample (P11-05)
# --legends-sample present: two Present looks in the board's proposed form (docs/BOARD.md Phase 11, the flagged
# table's right column, owner answer P1 a; not the plan's flagged drafts): Deep End (Calloway Whitlock, the step-back
# shooter: no beard, a thin mustache, waves, no mouthguard) and Toolbox (Theo Lindqvist, the point-forward: man bun,
# no headband), in the v2 sheet style, for the owner's look check before P11-14 makes the six sheets. Writes only
# docs/art/legends_present_sample_v1.png and .gif. The looks are data here, not in crews.json (no sheet is made from
# them); the numbers are placeholders (the owner approves the list). The parts row puts the other era parts on plain
# bodies, spread the way the hard rule asks (a parts check, not the other legends' final looks: P11-14 makes those).

PRESENT_SAMPLE_PNG = os.path.join(ROOT, "docs", "art", "legends_present_sample_v1.png")
PRESENT_SAMPLE_GIF = os.path.join(ROOT, "docs", "art", "legends_present_sample_v1.gif")
PRESENT_FLOOR = os.path.join(ROOT, "assets", "courts", "gym_floor.png")    # read only: the era plays indoors
_ERA3_KIT = {"top": "tank", "sleeve": None, "tight": None, "modern_shorts": True, "socks": "low",
             "sock_pal": "ERA3_LIGHT", "shoe_pal": "ERA3_LIGHT"}
PRESENT_SAMPLE = [
    ("DEEP END", "step-back shooter: lean guard, waves, thin mustache (no beard, no mouthguard), right-leg tights, "
                 "mid-thigh shorts, low socks",
     dict(_ERA3_KIT, id="lg_sample_deep_end", crew="B", number=26, role="step-back shooter", name="Deep End",
          body="lanky_guard", skin="brown", hair="waves", hair_pal="HAIR_BLACK", thin_mustache=True, tights="R",
          tight_pal="ERA3_INK", top_pal="ERA3_GRAPHITE", trim_pal="ERA3_TEAL", shorts_pal="ERA3_GRAPHITE",
          shorts_trim="ERA3_TEAL", shoe_acc="ERA3_TEAL", sole_pal="ERA3_GRAPHITE")),
    ("TOOLBOX", "point-forward: big and strong, low man bun (no headband), clean-shaven, mid-thigh shorts, low socks",
     dict(_ERA3_KIT, id="lg_sample_toolbox", crew="B", number=38, role="point-forward", name="Toolbox",
          body="champion", body_tweak={"mass": -0.08}, skin="light", hair="manbun", hair_pal="HAIR_BROWN",
          band_pal="ERA3_GRAPHITE",
          top_pal="ERA3_CORAL", trim_pal="ERA3_GRAPHITE", shorts_pal="ERA3_CORAL", shorts_trim="ERA3_GRAPHITE",
          shoe_acc="ERA3_CORAL", sole_pal="ERA3_GRAPHITE")),
]
# your colors (a drafted legend wears them, like a _crew recolor): era palette names swapped
PRESENT_SAMPLE_CREW = {"ERA3_GRAPHITE": "BLUE", "ERA3_CORAL": "BLUE", "ERA3_DEEP_TEAL": "BLUE",
                       "ERA3_INK": "NAVY", "ERA3_TEAL": "GOLD", "ERA3_LIGHT": "WHITE"}
PRESENT_PARTS_CHECK = [  # (label, entry): the other era parts on plain bodies, spread as the hard rule asks
    ("stretch: dark crop, boxed beard, tights", dict(_ERA3_KIT, id="era3_part_1", crew="B", number=4,
                                                     body="wiry_center",
                                            skin="tan", hair="crop", hair_pal="HAIR_DARK", boxed_beard=True,
                                            tights="both", tight_pal="ERA3_INK", top_pal="ERA3_LIGHT",
                                            trim_pal="ERA3_INK", shorts_pal="ERA3_LIGHT", shorts_trim="ERA3_INK",
                                            shoe_acc="ERA3_INK", sole_pal="ERA3_INK")),
    ("wing: bald, boxed beard", dict(_ERA3_KIT, id="era3_part_2", crew="B", number=7, body="lanky_wing",
                                     skin="deep", hair="bald", hair_pal="HAIR_BLACK", boxed_beard=True,
                                     top_pal="ERA3_CORAL", trim_pal="ERA3_LIGHT", shorts_pal="ERA3_CORAL",
                                     shorts_trim="ERA3_LIGHT", shoe_acc="ERA3_CORAL", sole_pal="ERA3_CORAL")),
    ("big: high-top fade, left tights", dict(_ERA3_KIT, id="era3_part_3", crew="B", number=9, body="power_forward",
                                             skin="umber", hair="hightop_fade", hair_pal="HAIR_BLACK", tights="L",
                                             tight_pal="ERA3_LIGHT", top_pal="ERA3_DEEP_TEAL", trim_pal="ERA3_INK",
                                             shorts_pal="ERA3_DEEP_TEAL", shorts_trim="ERA3_INK", shoe_acc="ERA3_DEEP_TEAL",
                                             sole_pal="ERA3_INK")),
    ("guard: crop, knee sleeve", dict(_ERA3_KIT, id="era3_part_4", crew="B", number=2, body="slim_guard",
                                      skin="light", hair="crop", hair_pal="HAIR_BROWN", knee_sleeve="L",
                                      knee_pal="ERA3_LIGHT", top_pal="ERA3_GRAPHITE", trim_pal="ERA3_DEEP_TEAL",
                                      shorts_pal="ERA3_GRAPHITE", shorts_trim="ERA3_DEEP_TEAL", shoe_acc="ERA3_DEEP_TEAL",
                                      sole_pal="ERA3_GRAPHITE")),
]
PRESENT_ANIMS = ["idle", "run", "run_dribble", "shoot"]


def _present_players():
    entries = []
    for _, _, e in PRESENT_SAMPLE:
        entries.append(dict(e))
        c = {k: (PRESENT_SAMPLE_CREW.get(v, v) if isinstance(v, str) else v) for k, v in e.items()}
        c.update({"id": e["id"] + "_crew", "crew": "U"})
        entries.append(c)
    entries += [dict(e) for _, e in PRESENT_PARTS_CHECK]
    for e in entries:
        e.setdefault("shorts_len", ERA3_SHORTS_LEN)
        e.setdefault("sock_len", ERA3_LOW_LEN)
    return _load_entries(entries)


def _floor_bg(path, w, h, show=2):
    if not os.path.exists(path):
        return Image.new("RGBA", (w, h), (120, 92, 60, 255))
    t = Image.open(path).convert("RGBA")
    t = t.resize((t.width * show, t.height * show), Image.NEAREST)
    bg = Image.new("RGBA", (w, h))
    for y in range(0, h, t.height):
        for x in range(0, w, t.width):
            bg.paste(t, (x, y))
    return bg


def legends_sample_present(argv):
    if __name__ == "__main__":
        sys.modules["make_players"] = sys.modules["__main__"]    # make_players_v2 imports this module: no re-patch
    import make_players_v2 as V
    import make_anim_sample as AS
    ps = _present_players()
    ref = [q for q in V.players_v2() if q["id"] == SAMPLE_REF][0]
    alld = ("S", "SE", "E", "NE", "N")
    fr, probs = {}, []
    looks = [(title, desc, e["id"], e["id"] + "_crew") for title, desc, e in PRESENT_SAMPLE]
    for _, _, sid, cid in looks:
        for pid in (sid, cid):
            fr[pid], pr = _render_anims(V, ps[pid], PRESENT_ANIMS, alld)
            probs += pr
    fr[SAMPLE_REF], pr = _render_anims(V, ref, PRESENT_ANIMS, alld)
    probs += pr
    parts = []
    for lab, e in PRESENT_PARTS_CHECK:
        f, pr = _render_anims(V, ps[e["id"]], ["idle", "run"], ("S", "SE", "E", "N"))
        parts.append((lab, f))
        probs += pr

    def bg_of(w, h):
        return _floor_bg(PRESENT_FLOOR, w, h)

    # --- the PNG
    Z, pad, lab_h = 2, 6, 18
    cw, chh = V.FW * Z, V.FH * Z
    cells_per_row = 10
    lx = 170
    W = lx + cells_per_row * (cw + pad)

    def C(f, name, dn, k=0, flip=False):
        img, rec = f[(name, dn)][k]
        if flip:
            return V.compose(img.transpose(Image.FLIP_LEFT_RIGHT), dict(rec, ball=None))
        return V.compose(img, rec)

    def strip(f):
        r = [C(f, "idle", dn) for dn in alld] + [C(f, "idle", "E", flip=True)]
        r += [C(f, "run", "E", 3), C(f, "run_dribble", "SE", 2), C(f, "shoot", "E", 2), C(f, "shoot", "SE", 6)]
        return r

    heads = ("idle S SE E NE N W (mirrored) | run E | running dribble SE | jumper E (gather) | jumper SE (release; "
             "the game adds the jump height)")
    rows = []
    for title, desc, sid, cid in looks:
        rows += [(title + ", era colors", desc, strip(fr[sid])), ("  in your colors", "", strip(fr[cid]))]
    rows.append(("today: " + SAMPLE_REF, "", strip(fr[SAMPLE_REF])))
    prow = []
    for lab, f in parts:
        prow += [C(f, "idle", "S"), C(f, "run", "SE", 2)]
    bar = 30
    card_z = 3
    H = (64 + len(rows) * (chh + lab_h + pad) + 3 * bar + (chh + lab_h + pad) + V.FH * card_z + lab_h + pad
         + 4 * V.FH + 3 * pad)
    base = bg_of(W, H)
    dr = ImageDraw.Draw(base)
    dr.rectangle([0, 0, W, 56], fill=(28, 26, 38, 255))
    AS.label(dr, (8, 6), "Legends look sample v1 (P11-05): the Present era parts on two looks, Deep End and Toolbox, "
                         "as the board proposes them (original characters; numbers are placeholders). Shown 2x as in "
                         "the game.", 14)
    AS.label(dr, (8, 30), heads, 12, (210, 204, 224))
    y = 64
    for name, desc, r in rows:
        dr.rectangle([0, y, W, y + lab_h - 2], fill=(28, 26, 38, 200))
        AS.label(dr, (8, y + 1), name + (": " + desc if desc else ""), 12)
        for c, cell in enumerate(r):
            base.alpha_composite(cell.resize((cw, chh), Image.NEAREST), (lx + c * (cw + pad), y + lab_h))
        y += chh + lab_h + pad
    dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
    AS.label(dr, (8, y + 4), "Parts check: the other era parts on plain bodies, spread over different builds "
                             "(idle S, run SE). Not the other legends' final looks (P11-14 makes those).", 13)
    y += bar
    for i, (lab, f) in enumerate(parts):
        dr.rectangle([lx + 2 * i * (cw + pad), y, lx + 2 * i * (cw + pad) + 2 * cw + pad, y + lab_h - 2],
                     fill=(28, 26, 38, 200))
        AS.label(dr, (lx + 2 * i * (cw + pad) + 2, y + 2), lab, 12)
    for c, cell in enumerate(prow):
        base.alpha_composite(cell.resize((cw, chh), Image.NEAREST), (lx + c * (cw + pad), y + lab_h))
    y += chh + lab_h + pad
    dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
    AS.label(dr, (8, y + 4), "Cards 3x (idle S, frame 0: the Hall / draft card): era colors and your colors", 13)
    y += bar
    x = lx
    for title, _, sid, cid in looks:
        for pid, sub in ((sid, title), (cid, "your colors")):
            img, _ = fr[pid][("idle", "S")][0]
            box = Image.new("RGBA", (V.FW * card_z, V.FH * card_z), (36, 34, 48, 255))
            box.alpha_composite(img.resize((V.FW * card_z, V.FH * card_z), Image.NEAREST))
            base.alpha_composite(box, (x, y))
            dr.rectangle([x, y + V.FH * card_z, x + V.FW * card_z, y + V.FH * card_z + lab_h], fill=(28, 26, 38, 255))
            AS.label(dr, (x + 4, y + V.FH * card_z + 2), sub, 12)
            x += V.FW * card_z + 3 * pad
    y += V.FH * card_z + lab_h + pad
    dr.rectangle([0, y, W, y + 24], fill=(28, 26, 38, 255))
    AS.label(dr, (8, y + 4), "Close-up 4x: waves, thin mustache, mid-thigh shorts with the side stripe, one-leg "
                             "tights, "
                             "low socks (Deep End S, NE) | low man bun with the faded undercut (Toolbox S, E, N)", 13)
    y += bar
    x = lx
    sid1, sid2 = looks[0][2], looks[1][2]
    for pid, dn in ((sid1, "S"), (sid1, "NE"), (sid2, "S"), (sid2, "E"), (sid2, "N")):
        img, rec = fr[pid][("idle", dn)][0]
        base.alpha_composite(img.resize((V.FW * 4, V.FH * 4), Image.NEAREST), (x, y))
        x += V.FW * 4 + pad
    base.convert("RGB").save(PRESENT_SAMPLE_PNG, optimize=True)
    print("wrote %s %s %d bytes" % (PRESENT_SAMPLE_PNG, base.size, os.path.getsize(PRESENT_SAMPLE_PNG)))

    # --- the GIF: both looks in era colors and your colors, and today's player, side by side
    moves = [("idle", "S", 1), ("run", "SE", 2), ("run", "E", 2), ("run_dribble", "SE", 2), ("run_dribble", "E", 2),
             ("shoot", "E", 1), ("shoot", "SE", 1), ("idle", "N", 1)]
    top, head = 30, 22
    panels = [(looks[0][2], looks[0][0]), (looks[0][3], "YOUR COLORS"), (looks[1][2], looks[1][0]),
              (looks[1][3], "YOUR COLORS"), (SAMPLE_REF, "TODAY")]
    gw = pad + len(panels) * (cw + pad)
    gh = head + (V.FH + top) * Z + pad + 14
    frames, durs = [], []
    for name, dn, loops in moves:
        ms = V.ANIM[name][3]
        lift = V.PREVIEW_LIFT.get(name)
        for _ in range(loops):
            for k, dur in enumerate(ms):
                bg = bg_of(gw, gh)
                d2 = ImageDraw.Draw(bg)
                d2.rectangle([0, 0, gw, head - 4], fill=(28, 26, 38, 255))
                AS.label(d2, (6, 3), "%s (%s) %d/%d" % ("jumper" if name == "shoot" else name, dn, k + 1, len(ms)), 13)
                d2.rectangle([0, gh - 20, gw, gh], fill=(28, 26, 38, 255))
                for c, (pid, title) in enumerate(panels):
                    img, rec = fr[pid][(name, dn)][k]
                    cell = AS.compose_frame(img, rec, lift=lift[k] if lift else 0, ball_spin=k, top=top)
                    bg.alpha_composite(cell.resize((cw, (V.FH + top) * Z), Image.NEAREST),
                                       (pad + c * (cw + pad), head))
                    AS.label(d2, (pad + c * (cw + pad) + 4, gh - 18), title, 11)
                frames.append(bg)
                durs.append(max(20, dur))
    AS.gif_save(frames, durs, PRESENT_SAMPLE_GIF)
    print("wrote %s %d frames %d bytes" % (PRESENT_SAMPLE_GIF, len(frames), os.path.getsize(PRESENT_SAMPLE_GIF)))
    for s in probs:
        print("CHECK", s)
    print("checks: %d problem(s)" % len(probs))
    return len(probs)


def main(argv):
    if "--legends-sample" in argv:    # P9-04: the owner's look sample only, nothing in assets/
        i = argv.index("--legends-sample")
        if i + 1 < len(argv) and argv[i + 1] == "fathers":    # P10-04: the Fathers look sample
            return legends_sample_fathers(argv)
        if i + 1 < len(argv) and argv[i + 1] == "present":    # P11-05: the Present look sample
            return legends_sample_present(argv)
        return legends_sample(argv)
    only = set(argv[argv.index("--only") + 1].split(",")) if "--only" in argv else None
    jobs = int(argv[argv.index("--jobs") + 1]) if "--jobs" in argv else (os.cpu_count() or 1)
    players = load_players()
    os.makedirs(OUT_DIR, exist_ok=True)
    all_frames = {}
    all_hands = {}
    problems = []
    todo = [p for p in players if not only or p["id"] in only]
    if jobs > 1:
        import multiprocessing
        with multiprocessing.get_context("fork").Pool(jobs) as pool:
            results = pool.map(_job, todo, chunksize=1)
    else:
        results = [_job(p) for p in todo]
    for pid, sheet, frames, probs, hp in results:   # in crews.json order, so hands.json keeps its order
        all_frames[pid] = frames
        all_hands[pid] = hp
        problems += probs
        out = os.path.join(OUT_DIR, pid + ".png")
        if "--preview-only" not in argv:
            kind = save_png(sheet, out)
            print("wrote %s %s %s %d bytes" % (out, sheet.size, kind, os.path.getsize(out)))
    if not only:
        p4 = [p for p in players if p["crew"] in ("A", "B")]   # the Phase 4 previews keep their six players
        preview(p4, all_frames)
        print("wrote", PREVIEW)
        preview2(p4, all_frames)
        print("wrote", PREVIEW2)
        preview_p5([p for p in players if p["crew"] not in ("A", "B") and p.get("phase", 5) == 5], all_frames)
        print("wrote", PREVIEW_P5)
        preview_p5([p for p in players if p.get("phase") == 6], all_frames, path=PREVIEW_P6, groups=P6_GROUPS)
        print("wrote", PREVIEW_P6)
        if "--preview-only" not in argv:
            write_hands(all_hands)
    elif "--preview" in argv:
        preview_p5([p for p in players if p["id"] in all_frames], all_frames, path=PREVIEW_P6, groups=P6_GROUPS)
        print("wrote", PREVIEW_P6)
    for s in problems:
        print("CHECK", s)
    print("checks: %d problem(s)" % len(problems))


if __name__ == "__main__":
    main(sys.argv[1:])
