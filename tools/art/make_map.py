#!/usr/bin/env python3
"""Trip map art for Road Trip Hoops (P5-A3): original pixel art, no downloaded or traced map images.

The USA outline is a hand-written, simplified list of rough longitude/latitude points (a few dozen per coast),
projected with a simple conic projection and rasterized at 1x, then given pixel-art terrain (dithered 4-tone
regions, farm fields, mountains, trees), a bold outline, a drop shadow and a coastline. Roads between the 8 route
cities follow hand-picked waypoints, smoothed and drawn as a little highway with a dashed gold centre line.

Usage:  python3 tools/art/make_map.py
Output: assets/map/usa.png       640 x 360 map (drawn 2x = 1280 x 720), no labels or pins baked in
        assets/map/map.json      city points and road polylines (source px), see "_help" inside
        assets/map/van.png       "The Biscuit": 2 frames x facing right (row 0) / left (row 1), 48 x 32 each
        assets/map/van_1..3.png  the star-reward paint jobs (VAN_PAINTS), same layout, size and anchor as van.png
        assets/map/pin.png       16 x 20 pin: a city not reached yet (blue)
        assets/map/pin_current.png   the city you are at / going to next (gold, basketball)
        assets/map/pin_locked.png    "coming soon" (grey, padlock)
        assets/map/pin_done.png      beaten city: the trophy marker
        docs/art/map_preview_v1.png      1280 x 720 mock-up (header, labels, van, trophies, GO button)
        docs/art/map_preview_v1_800.png  the same at 1280 x 800
        docs/art/van_paints.png          the stock van and the 3 paint jobs at 4x (review strip)
Needs:  Pillow, numpy
"""
import json
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "map")
DOCS = os.path.join(ROOT, "docs", "art")

W, H = 640, 360
HEADER_H = 36          # source px kept for the screen header (72 px on screen)
BOX = (34, 46, 606, 326)   # where the US landmass is fitted (source px)

ROUTE = ["hometown", "chicago", "memphis", "new_orleans", "denver", "seattle", "los_angeles", "new_york"]
NAMES = {"hometown": "HOMETOWN", "chicago": "CHICAGO", "memphis": "MEMPHIS", "new_orleans": "NEW ORLEANS",
         "denver": "DENVER", "seattle": "SEATTLE", "los_angeles": "LOS ANGELES", "new_york": "NEW YORK"}
# rough (lon, lat). Hometown is a made-up small town in north-central Indiana.
CITY_LL = {
    "hometown": (-85.7, 40.3), "chicago": (-87.65, 41.85), "memphis": (-90.05, 35.15),
    "new_orleans": (-90.07, 29.95), "denver": (-104.99, 39.74), "seattle": (-122.33, 47.61),
    "los_angeles": (-118.24, 34.05), "new_york": (-74.0, 40.71),
}
# label side hint for the game: where the name reads best next to the pin
LABEL = {"hometown": "right", "chicago": "left", "memphis": "right", "new_orleans": "below", "denver": "right",
         "seattle": "right", "los_angeles": "left", "new_york": "left"}

# road waypoints between consecutive route cities (lon, lat), roughly along big highways
LEGS = {
    "hometown>chicago": [(-86.4, 41.0)],
    "chicago>memphis": [(-88.2, 40.6), (-88.9, 38.9), (-89.2, 37.1)],
    "memphis>new_orleans": [(-90.2, 33.6), (-90.3, 31.6)],
    "new_orleans>denver": [(-91.4, 30.6), (-93.8, 32.4), (-96.8, 32.9), (-100.0, 33.6), (-103.0, 34.9),
                           (-104.5, 36.9), (-104.7, 38.4)],
    "denver>seattle": [(-104.9, 41.2), (-106.5, 43.0), (-108.6, 45.6), (-112.5, 46.3), (-115.5, 47.4),
                       (-118.4, 47.3), (-120.8, 47.4)],
    "seattle>los_angeles": [(-122.7, 45.5), (-123.1, 43.6), (-122.4, 40.8), (-121.6, 38.6), (-120.1, 36.6),
                            (-118.9, 35.0)],
    "los_angeles>new_york": [(-116.4, 34.6), (-114.4, 35.0), (-111.6, 35.3), (-106.6, 35.1), (-101.8, 35.5),
                             (-97.5, 35.5), (-94.4, 35.3), (-92.3, 34.7), (-89.6, 34.0), (-86.8, 33.5),
                             (-84.4, 33.8), (-80.9, 35.3), (-77.6, 37.4), (-76.4, 39.3), (-75.0, 40.2)],
}

# ----------------------------------------------------------------------------- outlines (rough lon, lat)
USA = [
    (-124.7, 48.4), (-124.1, 46.9), (-123.9, 45.6), (-124.1, 44.0), (-124.5, 42.8), (-124.2, 41.8),
    (-124.4, 40.4), (-123.8, 39.5), (-123.0, 38.1), (-122.5, 37.6), (-121.9, 36.6), (-121.0, 35.5),
    (-120.6, 34.6), (-119.4, 34.4), (-118.5, 34.0), (-117.9, 33.6), (-117.2, 32.6),
    (-114.7, 32.7), (-111.0, 31.4), (-108.2, 31.4), (-108.2, 31.8), (-106.5, 31.8), (-104.6, 29.8),
    (-103.2, 29.0), (-102.4, 29.8), (-101.3, 29.7), (-99.6, 27.6), (-97.4, 25.9),
    (-97.3, 27.4), (-96.4, 28.3), (-94.8, 29.3), (-93.7, 29.7), (-92.2, 29.6), (-90.9, 29.2), (-89.5, 28.9),
    (-89.4, 29.6), (-89.6, 30.3), (-88.1, 30.4), (-86.6, 30.4), (-85.4, 29.8), (-84.3, 30.0), (-83.3, 29.3),
    (-82.7, 28.0), (-82.0, 26.6), (-81.2, 25.4), (-80.4, 25.2), (-80.1, 26.6), (-80.6, 28.4), (-81.3, 30.4),
    (-81.1, 31.7), (-80.0, 32.7), (-78.9, 33.7), (-77.8, 34.1), (-76.5, 34.8), (-75.5, 35.4), (-75.9, 36.6),
    (-75.6, 37.8), (-75.1, 38.7), (-74.9, 39.1), (-74.1, 39.9), (-74.0, 40.5), (-72.6, 40.9), (-71.9, 41.2),
    (-70.6, 41.5), (-69.95, 41.75), (-70.6, 42.6), (-70.7, 43.1), (-70.0, 43.8), (-68.8, 44.3), (-67.0, 44.8),
    (-67.8, 45.7), (-67.8, 47.1), (-69.2, 47.4), (-70.1, 46.6), (-71.4, 45.1), (-74.8, 45.0), (-76.4, 44.2),
    (-76.6, 43.6), (-79.1, 43.3), (-78.9, 42.9), (-80.4, 42.2), (-82.7, 41.7), (-83.1, 42.3), (-82.4, 43.0),
    (-82.3, 44.6), (-83.0, 45.6), (-84.4, 46.5), (-86.8, 47.3), (-89.6, 48.0), (-91.5, 48.1), (-93.0, 48.6),
    (-95.2, 48.9), (-95.2, 49.0), (-104.0, 49.0), (-114.0, 49.0), (-123.0, 49.0), (-122.8, 48.1),
    (-123.5, 48.2),
]
CANADA = [
    (-132.0, 49.0), (-125.8, 49.0), (-124.6, 48.5), (-123.2, 48.3), (-123.0, 49.0), (-114.0, 49.0),
    (-104.0, 49.0), (-95.2, 49.0), (-95.2, 48.9), (-93.0, 48.6), (-91.5, 48.1), (-89.6, 48.0), (-86.8, 47.3),
    (-84.4, 46.5), (-83.0, 45.6), (-82.3, 44.6), (-82.4, 43.0), (-83.1, 42.3), (-82.7, 41.7), (-80.4, 42.2),
    (-78.9, 42.9), (-79.1, 43.3), (-76.6, 43.6), (-76.4, 44.2), (-74.8, 45.0), (-71.4, 45.1), (-70.1, 46.6),
    (-69.2, 47.4), (-67.8, 47.1), (-67.8, 45.7), (-67.0, 44.8), (-66.0, 45.2), (-64.6, 45.9), (-65.9, 44.6),
    (-65.6, 43.6), (-63.6, 44.5), (-61.0, 45.3), (-60.1, 46.0), (-61.4, 46.2), (-64.0, 46.3), (-64.6, 47.6),
    (-65.5, 48.1), (-64.3, 48.9), (-62.0, 49.4), (-58.0, 50.0), (-50.0, 52.0), (-50.0, 62.0), (-140.0, 62.0),
]
MEXICO = [
    (-117.2, 32.6), (-114.7, 32.7), (-111.0, 31.4), (-108.2, 31.4), (-108.2, 31.8), (-106.5, 31.8),
    (-104.6, 29.8), (-103.2, 29.0), (-102.4, 29.8), (-101.3, 29.7), (-99.6, 27.6), (-97.4, 25.9),
    (-97.6, 24.2), (-97.7, 22.2), (-97.0, 19.5), (-104.0, 18.0), (-106.0, 22.0), (-108.5, 25.2),
    (-110.5, 27.5), (-112.2, 29.2), (-113.0, 31.0), (-114.6, 31.7), (-114.8, 30.8), (-114.0, 29.0),
    (-112.2, 27.0), (-110.3, 24.0), (-109.8, 22.9), (-111.0, 24.2), (-112.2, 25.6), (-114.0, 27.6),
    (-115.0, 29.6), (-116.4, 31.0), (-117.0, 32.0),
]
CUBA = [(-84.9, 21.9), (-83.0, 22.9), (-81.0, 23.2), (-78.0, 22.4), (-75.5, 21.0), (-74.2, 20.2), (-77.5, 19.9),
        (-80.0, 21.8), (-82.5, 22.2)]
BAHAMA = [(-78.4, 26.7), (-77.0, 26.6), (-77.6, 26.9)]
LAKES = {
    "superior": [(-92.1, 46.75), (-90.6, 46.6), (-88.4, 47.3), (-87.6, 46.5), (-86.0, 46.6), (-84.6, 46.5),
                 (-84.8, 47.2), (-85.2, 47.9), (-86.6, 48.7), (-88.4, 48.6), (-89.6, 48.2), (-91.2, 47.4)],
    "michigan": [(-87.25, 41.6), (-87.8, 42.4), (-87.9, 43.5), (-87.5, 44.6), (-87.0, 45.5), (-86.0, 45.95),
                 (-85.0, 45.8), (-85.5, 44.8), (-86.3, 44.0), (-86.45, 43.0), (-86.3, 42.2), (-86.8, 41.7)],
    "huron": [(-82.45, 43.1), (-82.5, 44.0), (-83.4, 45.0), (-84.0, 45.8), (-84.8, 45.85), (-83.6, 46.1),
              (-81.6, 46.0), (-80.8, 45.3), (-81.6, 44.6), (-81.7, 43.4)],
    "erie": [(-83.4, 41.75), (-82.0, 41.45), (-81.0, 41.85), (-79.8, 42.3), (-78.95, 42.85), (-80.1, 42.7),
             (-81.6, 42.6), (-83.0, 42.05)],
    "ontario": [(-79.8, 43.3), (-78.8, 43.35), (-77.0, 43.3), (-76.2, 43.6), (-76.35, 44.15), (-77.6, 43.95),
                (-79.4, 43.75)],
    "salt": [(-112.9, 41.6), (-112.3, 41.5), (-112.1, 40.8), (-112.6, 40.9)],
}
MISSISSIPPI = [(-95.2, 47.3), (-94.2, 46.2), (-93.2, 45.0), (-91.9, 44.3), (-91.2, 43.4), (-90.9, 42.2),
               (-91.1, 40.9), (-90.6, 39.6), (-90.2, 38.6), (-89.5, 37.4), (-89.2, 37.0), (-89.6, 36.2),
               (-90.05, 35.15), (-90.8, 34.0), (-91.1, 33.0), (-91.2, 31.8), (-91.5, 31.0), (-91.1, 30.5),
               (-90.3, 30.0), (-89.7, 29.6), (-89.4, 29.2)]
MISSOURI = [(-111.5, 47.4), (-108.0, 47.7), (-104.5, 48.0), (-101.5, 47.4), (-100.5, 46.6), (-100.4, 45.0),
            (-98.5, 43.0), (-96.5, 42.5), (-95.9, 41.3), (-95.3, 39.6), (-94.0, 39.1), (-92.2, 38.6),
            (-90.2, 38.8)]
# mountain ridges (lon, lat): peaks are scattered along them
RIDGES = [
    [(-113.5, 48.6), (-112.0, 46.5), (-110.6, 44.6), (-109.2, 43.2), (-107.0, 41.0), (-105.6, 39.0),
     (-106.0, 37.3), (-105.6, 35.8)],
    [(-121.6, 48.6), (-121.7, 46.6), (-121.8, 44.4), (-122.2, 42.2)],
    [(-121.5, 40.8), (-120.2, 39.0), (-118.8, 37.2), (-118.2, 36.0)],
    [(-115.8, 45.8), (-114.6, 44.2), (-111.6, 40.6), (-110.0, 38.6)],
]
HILLS = [[(-84.6, 34.8), (-82.8, 36.0), (-80.6, 37.4), (-78.9, 39.0), (-77.4, 40.6), (-75.6, 41.8),
          (-74.3, 43.6), (-72.6, 44.2)]]

# terrain regions: seed points (lon, lat, region); nearest seed (with a jittered position) wins
SEEDS = [
    (-122.5, 46.5, "forest"), (-121.0, 44.0, "forest"), (-117.0, 48.0, "forest"), (-114.5, 47.5, "forest"),
    (-123.5, 41.5, "forest"),
    (-121.0, 38.2, "valley"), (-119.8, 36.6, "valley"),
    (-117.0, 35.0, "desert"), (-114.5, 33.4, "desert"), (-111.5, 33.2, "desert"), (-110.5, 36.2, "desert"),
    (-116.5, 38.8, "desert"), (-106.5, 33.0, "desert"), (-103.5, 31.0, "desert"), (-113.5, 38.0, "desert"),
    (-112.5, 43.2, "steppe"), (-108.0, 43.0, "steppe"), (-108.5, 40.5, "steppe"), (-118.0, 43.5, "steppe"),
    (-119.8, 40.6, "steppe"), (-109.5, 46.5, "steppe"),
    (-106.2, 38.8, "high"), (-110.4, 44.6, "high"), (-106.2, 36.4, "high"),
    (-100.5, 47.2, "plains"), (-100.0, 43.6, "plains"), (-99.5, 39.6, "plains"), (-99.5, 35.6, "plains"),
    (-101.0, 32.0, "plains"), (-98.0, 29.5, "plains"), (-103.0, 40.5, "plains"), (-104.0, 45.5, "plains"),
    (-93.5, 45.6, "farm"), (-93.2, 41.6, "farm"), (-89.5, 40.8, "farm"), (-85.6, 40.8, "farm"),
    (-83.0, 40.2, "farm"), (-95.8, 38.4, "farm"), (-89.6, 43.6, "farm"), (-84.8, 43.0, "farm"),
    (-87.0, 33.0, "south"), (-82.5, 33.0, "south"), (-92.4, 32.5, "south"), (-90.6, 30.8, "south"),
    (-84.6, 36.0, "south"), (-81.5, 28.4, "south"), (-95.0, 31.2, "south"), (-78.6, 36.0, "south"),
    (-74.2, 43.2, "east"), (-70.0, 45.3, "east"), (-77.2, 41.0, "east"), (-79.6, 38.4, "east"),
    (-72.5, 42.0, "east"), (-89.6, 46.2, "east"), (-85.0, 45.8, "east"),
]
RAMPS = {   # highlight, base, shadow, deep (light from the upper left)
    "forest": ["#79b45f", "#4a9049", "#2f6c3b", "#1d4a2b"],
    "valley": ["#d2dc80", "#a9bd55", "#7c9840", "#526c2e"],
    "desert": ["#f4d79e", "#e0b471", "#b9884e", "#805834"],
    "steppe": ["#dcd18c", "#bbae65", "#8f8548", "#605a34"],
    "high": ["#cdb982", "#a68f5b", "#7d6943", "#54442e"],
    "plains": ["#ece088", "#cdc05c", "#a19742", "#6d6631"],
    "farm": ["#afdc74", "#82c054", "#5b9a40", "#3c6c2f"],
    "south": ["#92d36c", "#60b14e", "#418c3f", "#2a622f"],
    "east": ["#86c463", "#529e4a", "#36793c", "#23562d"],
}
NEIGHBOR = ["#c3c6aa", "#a7ab90", "#868b74", "#62675a"]
SEA = {"foam": "#cdeefe", "shallow": "#5aa6e0", "mid": "#3f88cf", "deep": "#2d6cb6", "abyss": "#25599c",
       "wave": "#6cb8ee", "shadow": "#1e4a86"}
INK = "#1b2418"
BAR_BG = "#12101e"   # screen bars above / below the map on taller screens (1280 x 800), same as the header
ROAD = {"edge": "#26242c", "tar": "#5b5a66", "tar_hi": "#77768a", "line": "#f2c440"}


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# ----------------------------------------------------------------------------- projection

LAT0, LON0 = 38.5, -96.5
N_CONE = 0.42                      # flatter than a true conic: a friendlier, stylized curve
G = LAT0 + 75.0                    # cone apex distance (deg); larger = flatter curve
STRETCH = 1.32                     # stylized: a bit wider than true shape so the east coast cities breathe


def raw(lon, lat):
    rho = G - lat
    th = math.radians(N_CONE * (lon - LON0))
    return rho * math.sin(th) * STRETCH, -(G - LAT0 - rho * math.cos(th))


def _fit():
    pts = [raw(*p) for p in USA]
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    sx = (BOX[2] - BOX[0]) / (max(xs) - min(xs))
    sy = (BOX[3] - BOX[1]) / (max(ys) - min(ys))
    s = min(sx, sy)
    ox = (BOX[0] + BOX[2]) / 2 - s * (max(xs) + min(xs)) / 2
    oy = (BOX[1] + BOX[3]) / 2 - s * (max(ys) + min(ys)) / 2
    return s, ox, oy


SCALE, OX, OY = _fit()


def P(lon, lat):
    x, y = raw(lon, lat)
    return (OX + SCALE * x, OY + SCALE * y)


def poly_mask(ll, w=W, h=H):
    im = Image.new("L", (w, h), 0)
    ImageDraw.Draw(im).polygon([P(*p) for p in ll], fill=255)
    return np.array(im) > 0


# ----------------------------------------------------------------------------- helpers

def shift(m, dx, dy):
    out = np.zeros_like(m)
    hh, ww = m.shape
    xs0, xs1 = max(0, dx), min(ww, ww + dx)
    ys0, ys1 = max(0, dy), min(hh, hh + dy)
    out[ys0:ys1, xs0:xs1] = m[ys0 - dy:ys1 - dy, xs0 - dx:xs1 - dx]
    return out


def dilate(m, r=1, square=False):
    out = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if (dx or dy) and (square or dx * dx + dy * dy <= r * r + r * 0.5):
                out |= shift(m, dx, dy)
    return out


def dist_field(m, maxd=12):
    """Distance (in steps) from the True area, up to maxd."""
    d = np.full(m.shape, maxd, dtype=np.int32)
    cur = m.copy()
    d[cur] = 0
    for k in range(1, maxd):
        nxt = dilate(cur, 1)
        d[nxt & ~cur] = k
        cur = nxt
    return d


def value_noise(w, h, cell, seed):
    rng = np.random.RandomState(seed)
    gw, gh = w // cell + 3, h // cell + 3
    g = rng.rand(gh, gw)
    ys, xs = np.mgrid[0:h, 0:w]
    fx, fy = xs / cell, ys / cell
    x0, y0 = fx.astype(int), fy.astype(int)
    tx, ty = fx - x0, fy - y0
    tx = tx * tx * (3 - 2 * tx)
    ty = ty * ty * (3 - 2 * ty)
    a = g[y0, x0] * (1 - tx) + g[y0, x0 + 1] * tx
    b = g[y0 + 1, x0] * (1 - tx) + g[y0 + 1, x0 + 1] * tx
    return a * (1 - ty) + b * ty


BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


def catmull(pts, step=0.25):
    """Catmull-Rom through pts; returns dense points."""
    if len(pts) < 2:
        return pts
    ext = [pts[0]] + pts + [pts[-1]]
    out = []
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = (np.array(ext[j], dtype=float) for j in (i - 1, i, i + 1, i + 2))
        seg = np.linalg.norm(p2 - p1)
        n = max(2, int(seg / step))
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            q = 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
            out.append((q[0], q[1]))
    out.append(tuple(pts[-1]))
    return out


def resample(dense, spacing):
    out = [dense[0]]
    acc = 0.0
    for a, b in zip(dense, dense[1:]):
        d = math.hypot(b[0] - a[0], b[1] - a[1])
        acc += d
        if acc >= spacing:
            out.append(b)
            acc = 0.0
    if out[-1] != dense[-1]:
        if math.hypot(out[-1][0] - dense[-1][0], out[-1][1] - dense[-1][1]) < spacing * 0.5 and len(out) > 1:
            out[-1] = dense[-1]
        else:
            out.append(dense[-1])
    return out


# ----------------------------------------------------------------------------- the map

def city_px():
    return {c: P(*CITY_LL[c]) for c in ROUTE}


def road_paths():
    cp = city_px()
    paths = {}
    for i in range(len(ROUTE) - 1):
        a, b = ROUTE[i], ROUTE[i + 1]
        key = "%s>%s" % (a, b)
        pts = [cp[a]] + [P(*q) for q in LEGS[key]] + [cp[b]]
        paths[key] = catmull(pts)
    return paths


def draw_map():
    rng = random.Random(7)
    img = np.zeros((H, W, 3), dtype=np.uint8)

    us = poly_mask(USA)
    canada = poly_mask(CANADA) & ~us
    mexico = poly_mask(MEXICO) & ~us
    islands = poly_mask(CUBA) | poly_mask(BAHAMA)
    lakes = np.zeros_like(us)
    for ll in LAKES.values():
        lakes |= poly_mask(ll)
    land = (us | canada | mexico | islands) & ~lakes
    us_land = us & ~lakes

    # --- sea: depth by distance from any land, waves, drop shadow of the land
    d = dist_field(land, 14)
    sea_col = np.where(d <= 2, 0, np.where(d <= 6, 1, np.where(d <= 11, 2, 3)))
    names = ["shallow", "mid", "deep", "abyss"]
    # dither the band edges a little
    ys, xs = np.mgrid[0:H, 0:W]
    bay = BAYER[ys % 4, xs % 4]
    noise = value_noise(W, H, 18, 3)
    sea_col = np.clip(sea_col + ((noise - 0.5) * 1.2 + bay - 0.5 > 0.55).astype(int)
                      - ((noise - 0.5) * 1.2 + bay - 0.5 < -0.6).astype(int), 0, 3)
    for k, nme in enumerate(names):
        img[sea_col == k] = hexc(SEA[nme])
    shadow = shift(land, 2, 3) & ~land
    img[shadow] = hexc(SEA["shadow"])
    # waves: little "~" marks on open water
    wave = hexc(SEA["wave"])
    for gy in range(HEADER_H + 4, H - 4, 13):
        for gx in range(4, W - 6, 17):
            x = gx + rng.randint(-5, 5)
            y = gy + rng.randint(-4, 4)
            if 0 <= y < H - 1 and 0 <= x < W - 4 and d[y, x] >= 5 and d[y - 1:y + 2, x:x + 4].min() >= 4:
                for i, dy in enumerate((0, -1, -1, 0)):
                    img[y + dy, x + i] = wave
    foam = dilate(land, 1) & ~land
    img[foam & ~shadow] = hexc(SEA["foam"])
    img[foam & shadow] = hexc(SEA["mid"])

    # --- neighbour land: muted, flat, simple bevel
    nb = canada | mexico | islands
    nb_idx = np.ones((H, W), dtype=int)
    lit = nb & ~shift(nb, 1, 1)
    dark = nb & ~shift(nb, -1, -1)
    nb_idx[lit] = 0
    nb_idx[dark] = 2
    tex = value_noise(W, H, 9, 11)
    nb_idx[nb & (tex + bay * 0.5 > 1.05)] = 2
    for k in range(4):
        img[nb & (nb_idx == k)] = hexc(NEIGHBOR[k])
    nb = nb & ~lakes

    # --- US terrain regions (jittered Voronoi on the seeds)
    jx = (value_noise(W, H, 14, 21) - 0.5) * 16
    jy = (value_noise(W, H, 14, 22) - 0.5) * 16
    best = np.full((H, W), 1e9)
    reg = np.zeros((H, W), dtype=int)
    rnames = list(RAMPS.keys())
    for lon, lat, r in SEEDS:
        sx, sy = P(lon, lat)
        dd = (xs + jx - sx) ** 2 + (ys + jy - sy) ** 2
        better = dd < best
        best[better] = dd[better]
        reg[better] = rnames.index(r)
    idx = np.ones((H, W), dtype=int)
    tex = value_noise(W, H, 7, 31) * 0.7 + value_noise(W, H, 3, 32) * 0.3
    idx[(tex + (bay - 0.5) * 0.35) > 0.66] = 0
    idx[(tex + (bay - 0.5) * 0.35) < 0.30] = 2
    # farm fields: a patchwork of squares in the farm belt
    farm = reg == rnames.index("farm")
    cell = ((xs // 7) + (ys // 5) * 3 + ((xs // 7) * (ys // 5)) % 5) % 4
    fidx = np.choose(cell, [0, 1, 1, 2])
    gap = (xs % 7 == 6) | (ys % 5 == 4)
    idx[farm] = np.where(gap[farm], 2, fidx[farm])
    # plains: wheat rows
    plains = reg == rnames.index("plains")
    rows = (ys % 3 == 0) & (value_noise(W, H, 5, 41) > 0.45)
    idx[plains & rows] = 0
    # region borders: a dark seam so regions read as shapes
    seam = np.zeros((H, W), dtype=bool)
    for dx, dy in ((1, 0), (0, 1)):
        seam |= (reg != shift(reg, dx, dy)) & shift(us_land, dx, dy)
    idx[seam & ((xs + ys) % 4 == 0)] = 2
    # bevel: lit coast on the upper left, shade on the lower right
    lit = us_land & ~shift(us_land, 1, 1)
    lit2 = us_land & ~shift(us_land, 2, 2)
    sh1 = us_land & ~shift(us_land, -1, -1)
    sh2 = us_land & ~shift(us_land, -2, -2)
    idx[lit2] = np.minimum(idx[lit2], 1)
    idx[lit] = 0
    idx[sh2] = np.maximum(idx[sh2], 2)
    idx[sh1] = 3
    for r, nme in enumerate(rnames):
        ramp = [hexc(c) for c in RAMPS[nme]]
        for k in range(4):
            img[us_land & (reg == r) & (idx == k)] = ramp[k]

    # --- rivers
    river = hexc(SEA["mid"])
    river_hi = hexc(SEA["shallow"])
    for ll in (MISSOURI, MISSISSIPPI):
        dense = catmull([P(*q) for q in ll], 0.3)
        for (x, y) in dense:
            xi, yi = int(round(x)), int(round(y))
            if 0 <= xi < W and 0 <= yi < H and us_land[yi, xi]:
                img[yi, xi] = river
        for (x, y) in dense[::7]:
            xi, yi = int(round(x)), int(round(y))
            if 0 <= xi < W and 0 <= yi < H and us_land[yi, xi]:
                img[yi, xi] = river_hi

    # --- lakes
    ld = dist_field(~lakes, 4)   # distance from the shore, inside the lakes
    img[lakes] = hexc(SEA["mid"])
    img[lakes & (ld >= 3)] = hexc(SEA["deep"])
    img[lakes & (ld == 1)] = hexc(SEA["shallow"])

    # --- the outline: bold ink around the US, softer around the neighbours
    us_edge = dilate(us_land, 1) & ~us_land & ~lakes
    nb_edge = dilate(nb, 1) & ~nb & ~us_land & ~lakes
    img[nb_edge & ~us_edge & ~shift(land, 0, 0)] = hexc("#2c4a6a")
    img[us_edge] = hexc(INK)
    lake_edge = lakes & dilate(us_land | nb, 1)
    img[lake_edge] = hexc("#284a70")
    # US-Canada / US-Mexico border: a light dashed line over the ink
    border = us_edge & (canada | mexico)
    img[border & ((xs + ys) % 4 < 2)] = hexc("#d8d0a0")

    # --- roads (so decorations can avoid them)
    paths = road_paths()
    center = np.zeros((H, W), dtype=bool)
    dash = np.zeros((H, W), dtype=bool)
    for key, dense in paths.items():
        s = 0.0
        prev = dense[0]
        for (x, y) in dense:
            s += math.hypot(x - prev[0], y - prev[1])
            prev = (x, y)
            xi, yi = int(round(x)), int(round(y))
            if 0 <= xi < W and 0 <= yi < H:
                center[yi, xi] = True
                if (s % 6.0) < 3.0:
                    dash[yi, xi] = True
    fill = dilate(center, 1, square=True)
    edge = dilate(fill, 1) & ~fill
    keep_clear = dilate(fill, 4)
    for c, (x, y) in city_px().items():
        keep_clear[max(0, int(y) - 24):int(y) + 6, max(0, int(x) - 12):int(x) + 13] = True

    # --- decorations: mountains, hills, trees, cacti
    def put(sprite, x, y):
        """sprite: list of strings, chars map to colors; '.' clear. (x, y) = bottom centre."""
        hgt, wid = len(sprite), len(sprite[0])
        x0, y0 = int(x) - wid // 2, int(y) - hgt + 1
        if x0 < 0 or y0 < 0 or x0 + wid >= W or y0 + hgt >= H:
            return False
        area = keep_clear[y0:y0 + hgt, x0:x0 + wid]
        if area.any() or not us_land[y0:y0 + hgt, x0:x0 + wid].all() or occupied[y0:y0 + hgt, x0:x0 + wid].any():
            return False
        for j, row in enumerate(sprite):
            for i, ch in enumerate(row):
                if ch != ".":
                    img[y0 + j, x0 + i] = PAL[ch]
        occupied[y0:y0 + hgt, x0:x0 + wid] = True
        return True

    PAL = {"k": hexc("#2a2230"), "w": hexc("#ffffff"), "s": hexc("#cfd8ec"), "l": hexc("#b59a7c"),
           "m": hexc("#8a6e58"), "d": hexc("#5e4a40"), "g": hexc("#5aa24e"), "G": hexc("#2f7a3c"),
           "t": hexc("#1f5a30"), "T": hexc("#6a4a2e"), "c": hexc("#4f9a4a"), "C": hexc("#2e6a36"),
           "h": hexc("#74b45a"), "H": hexc("#3f8442")}
    occupied = np.zeros((H, W), dtype=bool)
    PEAK = ["....k....", "...kwk...", "..kwssk..", ".klwmmdk.", "klllmmddk", "kkkkkkkkk"]
    PEAK_S = ["...k...", "..kwk..", ".klsdk.", "kllmmdk", "kkkkkkk"]
    HILL = [".kkk..", "khhHk.", "khhhHk", "kkkkkk"]
    PINE = [".k.", "kgk", "kgk", "gGt", ".T."]
    TREE = [".kk.", "khhk", "khHk", ".kk.", ".T.."]
    CACT = [".k.", "kck", "ckC", ".C."]
    for ridge in RIDGES:
        dense = catmull([P(*q) for q in ridge], 0.5)
        for (x, y) in dense[::9]:
            for _ in range(2):
                spr = PEAK if rng.random() < 0.6 else PEAK_S
                put(spr, x + rng.randint(-5, 5), y + rng.randint(-3, 4))
    for ridge in HILLS:
        dense = catmull([P(*q) for q in ridge], 0.5)
        for (x, y) in dense[::8]:
            put(HILL, x + rng.randint(-3, 3), y + rng.randint(-2, 2))
    for _ in range(2200):
        x, y = rng.randint(2, W - 3), rng.randint(HEADER_H, H - 3)
        if not us_land[y, x]:
            continue
        r = rnames[reg[y, x]]
        roll = rng.random()
        if r == "forest" and roll < 0.30:
            put(PINE, x, y)
        elif r == "east" and roll < 0.16:
            put(PINE if rng.random() < 0.5 else TREE, x, y)
        elif r == "south" and roll < 0.09:
            put(TREE, x, y)
        elif r == "desert" and roll < 0.05:
            put(CACT, x, y)

    # --- draw the roads on top
    img[edge] = hexc(ROAD["edge"])
    img[fill] = hexc(ROAD["tar"])
    img[fill & ~shift(fill, 1, 1)] = hexc(ROAD["tar_hi"])
    img[dash] = hexc(ROAD["line"])

    # --- compass rose in the Atlantic
    draw_compass(img, 606, 232)
    return Image.fromarray(img, "RGB").convert("RGBA"), paths


def draw_compass(img, cx, cy):
    ink, gold, goldd, cream = hexc("#1b2418"), hexc("#f2c440"), hexc("#b87818"), hexc("#fff4d0")
    for r in range(0, 9):
        for (dx, dy) in ((0, -r), (0, r), (-r, 0), (r, 0)):
            pass
    pts = []
    for dy in range(-10, 11):
        for dx in range(-10, 11):
            ad, bd = abs(dx), abs(dy)
            on_n = dx == 0 and bd <= 10 or dy == 0 and ad <= 10
            star = (ad <= 2 and bd <= 10 - 3 * ad // 1 * 1 and ad * 4 + bd <= 10) or (bd <= 2 and bd * 4 + ad <= 10)
            if star:
                pts.append((dx, dy))
    S = set(pts)
    for (dx, dy) in pts:
        x, y = cx + dx, cy + dy
        col = gold if (dx <= 0 and dy <= 0) or (dx < 0 and dy > 0 and abs(dy) < abs(dx)) else goldd
        if dy < 0 and dx == 0:
            col = cream
        img[y, x] = col
    for (dx, dy) in pts:
        for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (dx + ex, dy + ey) not in S:
                img[cy + dy + ey, cx + dx + ex] = ink
    # "N"
    for j in range(5):
        img[cy - 17 + j, cx - 2] = cream
        img[cy - 17 + j, cx + 2] = cream
        img[cy - 17 + j, cx - 2 + min(4, j)] = cream


# ----------------------------------------------------------------------------- tiny pixel font (3x5)

FONT3 = {
    "A": ["###", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": ["###", "#..", "#..", "#..", "###"], "E": ["###", "#..", "##.", "#..", "###"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"], "I": ["#", "#", "#", "#", "#"],
    "S": ["###", "#..", "###", "..#", "###"], "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"], " ": ["..", "..", "..", "..", ".."],
}


def text3(px, s, x, y, col, shadow=None):
    for ch in s:
        g = FONT3[ch]
        for j, row in enumerate(g):
            for i, c in enumerate(row):
                if c == "#":
                    if shadow is not None:
                        px[x + i + 1, y + j + 1] = shadow
                    px[x + i, y + j] = col
        x += len(g[0]) + 1


def text3_w(s):
    return sum(len(FONT3[c][0]) + 1 for c in s) - 1


# ----------------------------------------------------------------------------- outline helper for sprites

def outline(im, ink=(26, 18, 30, 255)):
    a = np.array(im)
    m = a[:, :, 3] > 0
    ring = dilate(m, 1) & ~m
    a[ring] = ink
    return Image.fromarray(a, "RGBA")


# ----------------------------------------------------------------------------- the van "The Biscuit"

VAN_W, VAN_H = 48, 32
BISCUIT = ["#fbecc4", "#e9c98a", "#c29a5c", "#7c5a36"]
VBLUE = ["#78b8ff", "#2f74e0", "#1f479e", "#172a66"]
VGOLD = ["#ffe68a", "#f2b62c", "#b87818", "#6e420e"]
PRIMER = ["#c9c9c4", "#a3a39e", "#7d7d7a", "#555553"]
RUST = ["#c0642e", "#8a3e1e", "#5e2614"]
GLASS = ["#a8d0ff", "#5a7ab8", "#2a3a66", "#18203c"]
# The stock paint (assets/map/van.png): biscuit body, primer-grey replacement door, blue stripe, gold pinstripes,
# rust, a dent and one odd hubcap. The paint jobs (VAN_PAINTS, below) are dicts with the same keys.
STOCK = {"body": BISCUIT, "door": PRIMER, "stripe": VBLUE, "trim": VGOLD, "worn": True,
         "hubs": (["#f0d898", "#c8a060", "#8a6a3a"], ["#e6e8f0", "#a8acb8", "#6a6e7a"]),
         "label": "#fff4d0", "deco": None}


def van_frame(frame, paint=None):
    """One frame facing right (+x), no lettering, in the given paint (default: the stock Biscuit).
    Returns (image, body_y_offset)."""
    p = paint or STOCK
    BISCUIT, PRIMER, VBLUE, VGOLD = p["body"], p["door"], p["stripe"], p["trim"]
    im = Image.new("RGBA", (VAN_W, VAN_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    bob = -1 if frame == 1 else 0
    C = lambda h: hexc(h) + (255,)
    # body silhouette (facing right): boxy van, sloped nose
    body = [(3, 11), (5, 9), (35, 9), (38, 10), (42, 15), (44, 17), (44, 24), (3, 24)]
    body = [(x, y + bob) for x, y in body]
    d.polygon(body, fill=C(BISCUIT[1]))
    # shading bands: lit roof edge, shadowed lower panel and skirt
    d.line([(5, 9 + bob), (35, 9 + bob)], fill=C(BISCUIT[0]))
    d.line([(4, 10 + bob), (37, 10 + bob)], fill=C(BISCUIT[0]))
    d.rectangle([3, 21 + bob, 44, 22 + bob], fill=C(BISCUIT[2]))
    d.rectangle([3, 23 + bob, 44, 24 + bob], fill=C(BISCUIT[3]))
    d.line([(3, 11 + bob), (3, 20 + bob)], fill=C(BISCUIT[0]))
    # primer-grey replacement door (front door, mismatched)
    d.polygon([(31, 10 + bob), (36, 10 + bob), (39, 13 + bob), (39, 22 + bob), (31, 22 + bob)], fill=C(PRIMER[1]))
    d.line([(31, 10 + bob), (36, 10 + bob)], fill=C(PRIMER[0]))
    d.rectangle([31, 21 + bob, 39, 22 + bob], fill=C(PRIMER[2]))
    # blue stripe with gold pinstripes along the side (stops at the grey door)
    d.rectangle([3, 15 + bob, 30, 19 + bob], fill=C(VBLUE[1]))
    d.line([(3, 15 + bob), (30, 15 + bob)], fill=C(VBLUE[0]))
    d.line([(3, 19 + bob), (30, 19 + bob)], fill=C(VBLUE[2]))
    d.line([(3, 14 + bob), (30, 14 + bob)], fill=C(VGOLD[1]))
    d.line([(3, 20 + bob), (30, 20 + bob)], fill=C(VGOLD[2]))
    # the stripe continues on the nose in gold only
    d.line([(40, 17 + bob), (44, 17 + bob)], fill=C(VGOLD[1]))
    d.line([(40, 18 + bob), (44, 18 + bob)], fill=C(VBLUE[1]))
    # windows
    for x0, x1 in ((6, 12), (14, 21), (23, 29)):
        d.rectangle([x0, 11 + bob, x1, 13 + bob], fill=C(GLASS[2]))
        d.line([(x0, 11 + bob), (x1, 11 + bob)], fill=C(GLASS[1]))
        d.point((x0 + 1, 12 + bob), fill=C(GLASS[0]))
    d.polygon([(32, 11 + bob), (35, 11 + bob), (37, 13 + bob), (32, 13 + bob)], fill=C(GLASS[2]))
    d.point((33, 11 + bob), fill=C(GLASS[1]))
    # windshield on the sloped nose
    d.polygon([(37, 10 + bob), (38, 10 + bob), (42, 15 + bob), (40, 15 + bob)], fill=C(GLASS[1]))
    d.point((38, 11 + bob), fill=C(GLASS[0]))
    # cracked windshield line
    d.point((40, 13 + bob), fill=C(GLASS[3]))
    # sliding door seam and handle, dent, rust
    d.line([(13, 11 + bob), (13, 22 + bob)], fill=C(BISCUIT[2]))
    d.line([(22, 11 + bob), (22, 22 + bob)], fill=C(BISCUIT[2]))
    d.point((20, 16 + bob), fill=C(VGOLD[3]))
    d.point((36, 16 + bob), fill=C(PRIMER[3]))
    for (x, y, k) in ((5, 21, 1), (6, 22, 0), (7, 21, 2), (16, 22, 1), (17, 21, 0), (26, 22, 1),
                      (41, 21, 1), (42, 22, 0), (4, 13, 1), (28, 12, 2)) if p["worn"] else ():
        d.point((x, y + bob), fill=C(RUST[k]))
    if p["worn"]:
        d.line([(24, 17 + bob), (26, 18 + bob)], fill=C(VBLUE[3]))   # a dent across the stripe
    if p["deco"]:
        p["deco"](d, bob, C)
    # lights and bumpers
    d.rectangle([43, 19 + bob, 44, 20 + bob], fill=C("#fff2a0"))
    d.point((44, 19 + bob), fill=C("#ffffff"))
    d.rectangle([3, 12 + bob, 3, 13 + bob], fill=C("#e83a3a"))
    d.rectangle([40, 23 + bob, 45, 24 + bob], fill=C("#b8bcc8"))
    d.line([(40, 23 + bob), (45, 23 + bob)], fill=C("#e6e8f0"))
    d.rectangle([2, 23 + bob, 6, 24 + bob], fill=C("#8a8e9a"))   # rear bumper, dull and bent
    d.point((2, 22 + bob), fill=C("#8a8e9a"))
    # roof rack: rails, a suitcase, a duffel bag and a basketball
    d.line([(7, 8 + bob), (33, 8 + bob)], fill=C("#3a3640"))
    for x in (8, 20, 32):
        d.point((x, 9 + bob), fill=C("#3a3640"))
    d.rectangle([9, 3 + bob, 17, 7 + bob], fill=C("#9a6a3e"))
    d.line([(9, 3 + bob), (17, 3 + bob)], fill=C("#c08a52"))
    d.line([(9, 7 + bob), (17, 7 + bob)], fill=C("#6a4426"))
    d.line([(13, 3 + bob), (13, 7 + bob)], fill=C("#f2b62c"))
    d.rectangle([19, 4 + bob, 26, 7 + bob], fill=C(STOCK["stripe"][2]))     # the crew's blue duffel, every paint
    d.line([(20, 4 + bob), (25, 4 + bob)], fill=C(STOCK["stripe"][1]))
    d.point((22, 5 + bob), fill=C(STOCK["trim"][1]))
    d.ellipse([28, 3 + bob, 32, 7 + bob], fill=C("#e8782a"))
    d.point((29, 4 + bob), fill=C("#ffb070"))
    d.line([(30, 3 + bob), (30, 7 + bob)], fill=C("#7a3410"))
    d.line([(28, 5 + bob), (32, 5 + bob)], fill=C("#7a3410"))
    d.line([(40, 8 + bob), (42, 4 + bob)], fill=C("#3a3640"))   # bent antenna
    # wheel arches
    for wx in (11, 36):
        d.ellipse([wx - 5, 19 + bob, wx + 5, 29 + bob], fill=C("#1a1420"))
    im = outline(im)
    # wheels (on the ground, no bob), drawn after the outline so they sit in the arches
    d = ImageDraw.Draw(im)
    for n, wx in enumerate((11, 36)):
        d.ellipse([wx - 4, 22, wx + 4, 30], fill=C("#1a1420"))
        d.ellipse([wx - 3, 23, wx + 3, 29], fill=C("#2e2a36"))
        d.point((wx - 2, 24), fill=C("#4a4656"))
        hub = p["hubs"][n]   # stock: one odd hubcap
        d.ellipse([wx - 2, 24, wx + 2, 28], fill=C(hub[1]))
        d.point((wx - 1, 25), fill=C(hub[0]))
        d.point((wx + 1, 27), fill=C(hub[2]))
        d.point((wx, 26), fill=C("#2e2a36"))
        # a bolt that turns between the frames
        bolt = [(wx, 24), (wx + 2, 26)][frame]
        d.point(bolt, fill=C(hub[2]))
    # exhaust puff from the rear
    puffs = [(1, 22)] if frame == 0 else [(0, 20), (1, 23)]
    for (x, y) in puffs:
        for (ex, ey, al) in ((0, 0, 170), (1, 0, 120), (0, 1, 120), (-1, 0, 90), (0, -1, 90)):
            if 0 <= x + ex < VAN_W:
                d.point((x + ex, y + ey), fill=(210, 210, 220, al))
    # ground shadow
    a = np.array(im)
    for x in range(5, 43):
        for y in (30, 31):
            if a[y, x, 3] == 0:
                a[y, x] = (20, 16, 30, 90 if y == 30 else 50)
    return Image.fromarray(a, "RGBA"), bob


def make_van(paint=None):
    p = paint or STOCK
    sheet = Image.new("RGBA", (VAN_W * 2, VAN_H * 2), (0, 0, 0, 0))
    label = "BISCUIT"
    tw = text3_w(label)
    for f in range(2):
        im, bob = van_frame(f, p)
        right = im.copy()
        px = right.load()
        sh = hexc(p["shadow"]) + (255,) if p.get("shadow") else None
        text3(px, label, 4 + (27 - tw) // 2, 15 + bob, hexc(p["label"]) + (255,), sh)
        left = im.transpose(Image.FLIP_LEFT_RIGHT)
        px = left.load()
        x0 = VAN_W - 31 + (27 - tw) // 2
        text3(px, label, x0, 15 + bob, hexc(p["label"]) + (255,), sh)
        sheet.paste(right, (f * VAN_W, 0))
        sheet.paste(left, (f * VAN_W, VAN_H))
    return sheet


# ----------------------------------------------------------------------------- van paint jobs (P8-07)
# Star rewards: assets/map/van_<N>.png, the same sheet layout, size and anchor as van.png (only the paint changes;
# same body, rack, wheels and BISCUIT lettering). A fresh paint job has no rust, dent or odd hubcap.

def _deco_flames(d, bob, C):
    """Hot-rod flames: they start on the nose and lick back along the side, over the door and under the stripe."""
    Y, O, R = C("#ffe68a"), C("#f2a02c"), C("#e8602a")
    # (row, back end x): long tongues low and near the stripe ends, short ones between
    tongues = [(11, 38), (12, 34), (13, 37), (14, 32), (15, 35), (16, 31), (17, 33), (18, 30), (19, 34),
               (20, 26), (21, 19), (22, 29)]
    for y, x0 in tongues:
        if y in (14, 15, 16, 17, 18, 19) and x0 < 31:
            x0 = 31                          # the black stripe stays clear for the lettering
        x1 = 41 if y < 15 else 43
        d.line([(x0, y + bob), (x1, y + bob)], fill=O)
        d.line([(x0 + 3, y + bob), (x1, y + bob)], fill=Y)
        d.point((x0, y + bob), fill=R)
    d.point((36, 16 + bob), fill=C("#5c1418"))   # door handle over the flames


def _deco_woodie(d, bob, C):
    """A surf woodie: a varnished wood side panel with cream frame rails, the door panel to match."""
    W = ["#e8b070", "#c07c44", "#8e5630", "#5a341c"]
    F = C("#f6ecd0")
    for x0, x1 in ((3, 30), (31, 38)):
        d.rectangle([x0, 14 + bob, x1, 21 + bob], fill=C(W[2]))   # dark varnish, so the cream lettering reads
        d.line([(x0, 20 + bob), (x1, 20 + bob)], fill=C(W[3]))
        for x in range(x0 + 2, x1, 4):                       # grain flecks
            d.point((x, 15 + bob + (x % 4)), fill=C(W[1]))
            d.point((x + 1, 15 + bob + (x % 4)), fill=C(W[1]))
        d.line([(x0, 14 + bob), (x1, 14 + bob)], fill=F)      # frame rails
        d.line([(x0, 21 + bob), (x1, 21 + bob)], fill=F)
        d.line([(x0, 14 + bob), (x0, 21 + bob)], fill=F)
        d.line([(x1, 14 + bob), (x1, 21 + bob)], fill=F)
    d.line([(13, 14 + bob), (13, 21 + bob)], fill=F)          # the sliding door seams are frame posts too
    d.line([(22, 14 + bob), (22, 21 + bob)], fill=F)
    d.line([(40, 17 + bob), (44, 17 + bob)], fill=F)          # a cream line on the nose
    d.line([(40, 18 + bob), (44, 18 + bob)], fill=C(W[1]))
    d.point((36, 17 + bob), fill=C(W[3]))                     # door handle


def _deco_gold(d, bob, C):
    """Champion gold: a white star on the door and a black-and-white checker band on the nose."""
    K, Wt = C("#16121a"), C("#ffffff")
    for (x, y) in ((35, 15), (34, 16), (35, 16), (36, 16), (33, 17), (34, 17), (35, 17), (36, 17), (37, 17),
                   (34, 18), (36, 18), (33, 19), (37, 19)):
        d.point((x, y + bob), fill=Wt)
    for x in range(40, 45):
        d.point((x, 17 + bob), fill=K if x % 2 == 0 else Wt)
        d.point((x, 18 + bob), fill=Wt if x % 2 == 0 else K)
    d.line([(4, 22 + bob), (30, 22 + bob)], fill=C("#7a5212"))


CHROME = ["#ffffff", "#c8ccd8", "#7a7e8a"]
VAN_PAINTS = {
    # van_1: candy red with a black stripe and hot-rod flames from the nose
    1: {"name": "HOT SAUCE", "body": ["#ff8a6a", "#d8382c", "#9a2020", "#5c1418"],
        "door": ["#ff8a6a", "#d8382c", "#9a2020", "#5c1418"],
        "stripe": ["#4a4048", "#2a2228", "#1a1418", "#100c10"], "trim": ["#ffe68a", "#f2b62c", "#f2a02c", "#6e420e"],
        "worn": False, "hubs": (CHROME, CHROME), "label": "#ffe68a", "deco": _deco_flames},
    # van_2: a surf woodie: sea-green paint over a varnished wood side panel, cream trim, white-wall hubs
    2: {"name": "SURF WOODIE", "body": ["#b4f4e4", "#4cc4b0", "#2a8c84", "#16585a"],
        "door": ["#b4f4e4", "#4cc4b0", "#2a8c84", "#16585a"],
        "stripe": ["#e8b070", "#c07c44", "#8e5630", "#5a341c"], "trim": ["#f6ecd0", "#f6ecd0", "#f6ecd0", "#c8bc98"],
        "worn": False, "hubs": (["#ffffff", "#f6ecd0", "#b8ae90"], ["#ffffff", "#f6ecd0", "#b8ae90"]),
        "label": "#fff4d0", "deco": _deco_woodie},
    # van_3: champion gold with a black racing stripe, white pinstripes, a door star and chrome hubs
    3: {"name": "GOLD RUSH", "body": ["#fff4b0", "#f2c23c", "#c08a1c", "#7a5212"],
        "door": ["#fff4b0", "#f2c23c", "#c08a1c", "#7a5212"],
        "stripe": ["#4a4450", "#24202a", "#16121a", "#0c0a10"], "trim": ["#ffffff", "#ffffff", "#e8e8f0", "#7a7e8a"],
        "worn": False, "hubs": (CHROME, CHROME), "label": "#ffe68a", "deco": _deco_gold},
}


def van_paints_preview(stock, paints, out):
    """docs/art/van_paints.png: the stock van and each paint job, both frames facing right, then facing left,
    at 4x on the map's plains colour, with the paint name under each."""
    Z, PAD, LAB = 4, 8, 22
    vans = [("STOCK", stock)] + [(VAN_PAINTS[n]["name"] + "  (van_%d)" % n, paints[n]) for n in sorted(paints)]
    cw = VAN_W * 2 * Z + PAD
    img = Image.new("RGB", (PAD + cw * len(vans), PAD + VAN_H * 2 * Z + LAB), hexc("#cdc05c"))
    d = ImageDraw.Draw(img)
    for i, (name, sheet) in enumerate(vans):
        big = sheet.resize((VAN_W * 2 * Z, VAN_H * 2 * Z), Image.NEAREST)
        img.paste(big, (PAD + i * cw, PAD), big)
        d.text((PAD + i * cw + 4, PAD + VAN_H * 2 * Z + 2), name, font=font(16), fill="#1b2418")
    img.save(out, optimize=True)


# ----------------------------------------------------------------------------- pins and the trophy

PIN_W, PIN_H = 16, 20
PIN_ANCHOR = (8, 18)


def pin_image(kind):
    ramps = {"open": VBLUE, "current": VGOLD, "locked": ["#d0d0d8", "#9898a4", "#6c6c78", "#4a4a54"]}
    rp = [hexc(c) + (255,) for c in ramps[kind]]
    im = Image.new("RGBA", (PIN_W, PIN_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # teardrop: a circle and a point at (8, 17)
    d.ellipse([2, 1, 13, 12], fill=rp[1])
    d.polygon([(4, 9), (11, 9), (8, 16), (7, 16)], fill=rp[1])
    d.ellipse([3, 2, 8, 6], fill=rp[0])
    d.point((4, 3), fill=(255, 255, 255, 255))
    d.polygon([(11, 6), (13, 6), (12, 10), (9, 15), (8, 15)], fill=rp[2])
    d.point((8, 16), fill=rp[3])
    # face of the pin
    if kind == "open":
        d.ellipse([5, 4, 10, 9], fill=hexc("#fff4d0") + (255,))
        d.rectangle([7, 6, 8, 7], fill=rp[2])
    elif kind == "current":
        d.ellipse([4, 3, 11, 10], fill=hexc("#fff4d0") + (255,))
        d.ellipse([5, 4, 10, 9], fill=hexc("#e8782a") + (255,))
        d.point((6, 5), fill=hexc("#ffb070") + (255,))
        d.line([(7, 4), (7, 9)], fill=hexc("#7a3410") + (255,))
        d.line([(5, 6), (10, 6)], fill=hexc("#7a3410") + (255,))
    else:
        dk = hexc("#3a3a44") + (255,)
        d.rectangle([5, 6, 10, 9], fill=dk)          # padlock body
        d.line([(6, 4), (6, 5)], fill=dk)
        d.line([(9, 4), (9, 5)], fill=dk)
        d.line([(7, 3), (8, 3)], fill=dk)
        d.point((7, 7), fill=rp[0])
        d.point((8, 7), fill=rp[0])
    im = outline(im)
    a = np.array(im)
    for x in range(4, 12):
        if a[18, x, 3] == 0:
            a[18, x] = (20, 16, 30, 110)
        if 5 <= x <= 10 and a[19, x, 3] == 0:
            a[19, x] = (20, 16, 30, 60)
    return Image.fromarray(a, "RGBA")


def trophy_image():
    G = [hexc(c) + (255,) for c in VGOLD]
    im = Image.new("RGBA", (PIN_W, PIN_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # handles
    d.ellipse([1, 3, 6, 8], outline=G[2])
    d.ellipse([9, 3, 14, 8], outline=G[2])
    # cup
    d.polygon([(3, 1), (12, 1), (12, 5), (10, 9), (5, 9), (3, 5)], fill=G[1])
    d.line([(3, 1), (12, 1)], fill=G[0])
    d.line([(4, 2), (4, 5)], fill=G[0])
    d.point((5, 2), fill=(255, 255, 255, 255))
    d.polygon([(10, 2), (11, 2), (11, 5), (9, 8)], fill=G[2])
    # stem and base
    d.rectangle([7, 10, 8, 11], fill=G[2])
    d.point((7, 10), fill=G[1])
    d.rectangle([5, 12, 10, 13], fill=G[1])
    d.line([(5, 12), (10, 12)], fill=G[0])
    d.rectangle([4, 14, 11, 17], fill=hexc("#6a4426") + (255,))
    d.line([(4, 14), (11, 14)], fill=hexc("#9a6a3e") + (255,))
    d.rectangle([6, 15, 9, 16], fill=G[1])      # name plate
    d.point((6, 15), fill=G[0])
    # star on the cup
    d.point((7, 4), fill=(255, 255, 255, 255))
    d.point((8, 4), fill=G[0])
    d.line([(6, 5), (9, 5)], fill=G[0])
    d.point((7, 6), fill=G[0])
    im = outline(im)
    a = np.array(im)
    for x in range(3, 13):
        if a[19, x, 3] == 0:
            a[19, x] = (20, 16, 30, 110)
    return Image.fromarray(a, "RGBA")


# ----------------------------------------------------------------------------- preview

def font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except TypeError:
        return ImageFont.load_default()


def point_along(path, t):
    tot = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(path, path[1:]))
    goal = tot * t
    s = 0.0
    for a, b in zip(path, path[1:]):
        dd = math.hypot(b[0] - a[0], b[1] - a[1])
        if s + dd >= goal:
            k = (goal - s) / dd if dd else 0
            return (a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k), (b[0] - a[0])
        s += dd
    return path[-1], 1.0


def preview(usa, cities, roads, van, pins, screen_h, out):
    Z = 2
    scr = Image.new("RGBA", (1280, screen_h), hexc(BAR_BG) + (255,))
    oy = (screen_h - 720) // 2
    scr.alpha_composite(usa.resize((W * Z, H * Z), Image.NEAREST), (0, oy))
    d = ImageDraw.Draw(scr)
    if oy > 0:
        d.line([(0, screen_h - oy), (1280, screen_h - oy)], fill=hexc("#f2b62c"), width=3)
    # header (as trip_map.gd might draw it)
    hh = HEADER_H * Z + oy
    d.rectangle([0, 0, 1280, hh], fill=(18, 16, 30, 230))
    d.line([(0, hh), (1280, hh)], fill=hexc("#f2b62c"), width=3)
    d.text((24, hh // 2), "ROAD TRIP", font=font(34), fill=hexc("#ffe68a"), anchor="lm")
    d.text((640, hh // 2), "CORNFIELD KINGS  -  NEXT: MEMPHIS  -  RECORD 6-1", font=font(22), fill="#e8eaf4",
           anchor="mm")
    d.rounded_rectangle([1150, hh // 2 - 20, 1260, hh // 2 + 20], 8, fill=hexc("#34343f"), outline="#9a9ab0",
                        width=2)
    d.text((1205, hh // 2), "MENU", font=font(20), fill="#ffffff", anchor="mm")
    state = {"hometown": "done", "chicago": "done", "memphis": "current", "new_orleans": "locked",
             "denver": "locked", "seattle": "locked", "los_angeles": "locked", "new_york": "open"}
    f = font(18)
    for c in ROUTE:
        x, y = cities[c]
        spr = pins[state[c]].resize((PIN_W * Z, PIN_H * Z), Image.NEAREST)
        scr.alpha_composite(spr, (int(round(x * Z - PIN_ANCHOR[0] * Z)), int(round(y * Z - PIN_ANCHOR[1] * Z)) + oy))
        name = NAMES[c] + ("  (soon)" if state[c] == "locked" else "")
        side = LABEL[c]
        if side == "right":
            pos, anc = (x * Z + 20, y * Z - 18 + oy), "lm"
        elif side == "left":
            pos, anc = (x * Z - 20, y * Z - 18 + oy), "rm"
        else:
            pos, anc = (x * Z, y * Z + 14 + oy), "mt"
        col = "#9a9ab0" if state[c] == "locked" else "#ffffff"
        d.text(pos, name, font=f, fill=col, anchor=anc, stroke_width=3, stroke_fill=(20, 16, 30))
    # the van between Chicago and Memphis, on the road
    (vx, vy), dx = point_along(roads["chicago>memphis"], 0.45)
    row = 0 if dx >= 0 else 1
    fr = van.crop((0, row * VAN_H, VAN_W, (row + 1) * VAN_H)).resize((VAN_W * Z, VAN_H * Z), Image.NEAREST)
    scr.alpha_composite(fr, (int(vx * Z - 24 * Z), int(vy * Z - 29 * Z) + oy))
    # GO button and city card
    by = screen_h - 96
    d.rounded_rectangle([1060, by, 1250, by + 72], 14, fill=hexc("#2fa046"), outline=hexc("#103c26"), width=4)
    d.text((1155, by + 36), "GO", font=font(44), fill="#ffffff", anchor="mm", stroke_width=3,
           stroke_fill=hexc("#103c26"))
    d.rounded_rectangle([24, by - 30, 404, by + 72], 12, fill=(18, 16, 30, 220), outline=hexc("#f2b62c"), width=2)
    d.text((44, by - 14), "MEMPHIS, Tennessee", font=font(24), fill="#ffe68a")
    d.text((44, by + 20), "Game 1 of 3  -  crew: coming in Phase 6", font=font(18), fill="#e8eaf4")
    d.text((44, by + 44), "mock-up: header, card and GO drawn by the game", font=font(14), fill="#9a9ab0")
    scr.convert("RGB").save(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DOCS, exist_ok=True)
    usa, paths = draw_map()
    usa.convert("RGB").save(os.path.join(OUT, "usa.png"), optimize=True)
    cities = {c: (round(x, 1), round(y, 1)) for c, (x, y) in city_px().items()}
    roads = {}
    for k, dense in paths.items():
        pts = resample(dense, 4.0)
        roads[k] = [[round(x, 1), round(y, 1)] for x, y in pts]
    data = {
        "_help": ["Made by tools/art/make_map.py (edit LEGS / CITY_LL there and re-run). All numbers are source px",
                  "of usa.png (640 x 360, drawn 2x). cities: pin tip point. roads: 'a>b' polyline from city a to b",
                  "in route order, points about 4 px apart (the van follows it). label: side where the name reads",
                  "best. pins are 16 x 20 with the tip at pin_anchor. van.png: 48 x 32 frames, columns = 2 drive",
                  "frames, row 0 faces right, row 1 faces left; van_anchor = the point between the wheels on the road.",
                  "header_h: rows at the top kept clear for the header. On 1280 x 800 centre the map (y + 40) and fill",
                  "the bars with bar_bg (the top bar joins the header, the bottom bar holds GO)."],
        "size": [W, H], "scale": 2, "header_h": HEADER_H, "bar_bg": BAR_BG, "sea": SEA["deep"],
        "route": ROUTE,
        "cities": {c: [cities[c][0], cities[c][1]] for c in ROUTE},
        "label": LABEL,
        "roads": roads,
        "pin_size": [PIN_W, PIN_H], "pin_anchor": list(PIN_ANCHOR),
        "pins": {"open": "pin.png", "current": "pin_current.png", "locked": "pin_locked.png", "done": "pin_done.png"},
        "van_frame": [VAN_W, VAN_H], "van_frames": 2, "van_rows": ["right", "left"], "van_anchor": [24, 29],
    }
    with open(os.path.join(OUT, "map.json"), "w") as fh:
        json.dump(data, fh, indent=1)
    van = make_van()
    van.save(os.path.join(OUT, "van.png"), optimize=True)
    paints = {n: make_van(p) for n, p in VAN_PAINTS.items()}
    for n, sheet in paints.items():
        sheet.save(os.path.join(OUT, "van_%d.png" % n), optimize=True)
    van_paints_preview(van, paints, os.path.join(DOCS, "van_paints.png"))
    pins = {"open": pin_image("open"), "current": pin_image("current"), "locked": pin_image("locked"),
            "done": trophy_image()}
    for k, fn in data["pins"].items():
        pins[k].save(os.path.join(OUT, fn), optimize=True)
    preview(usa, cities, roads, van, pins, 720, os.path.join(DOCS, "map_preview_v1.png"))
    preview(usa, cities, roads, van, pins, 800, os.path.join(DOCS, "map_preview_v1_800.png"))
    # close-up of the sprites for review (not part of the game)
    sh = Image.new("RGBA", (VAN_W * 2 + PIN_W * 4 + 24, VAN_H * 2), hexc("#cdc05c") + (255,))
    sh.alpha_composite(van, (0, 0))
    for i, k in enumerate(("open", "current", "locked", "done")):
        sh.alpha_composite(pins[k], (VAN_W * 2 + 6 + i * (PIN_W + 4), 6))
    sh.resize((sh.size[0] * 6, sh.size[1] * 6), Image.NEAREST).convert("RGB").save(
        os.path.join(DOCS, "map_sprites_v1.png"))
    print("cities:", cities)
    print("scale %.2f px/deg-ish" % SCALE)


if __name__ == "__main__":
    main()
