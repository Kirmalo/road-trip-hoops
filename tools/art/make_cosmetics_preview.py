#!/usr/bin/env python3
"""docs/art/cosmetics_preview.png (P8-09): every star reward cosmetic on one sheet, for the owner.

- Jerseys: the underdogs and a few recruits / draftees in your colors (their default look) and in the 3 alternate
  jerseys (palettes/<id>_j<N>.png, made by make_players_v2.py --jerseys), idle S and running SE, decoded from the
  index pages through each palette exactly as the game draws them, at the in-game 2x.
- Balls: assets/ball/ball.png and ball_1..3 (4 spin frames each) at 4x.
- Vans: assets/map/van.png and van_1..3 at 3x.
- Court looks: the reward looks' backdrop and floor tile (assets/courts/<look>_*.png) at 2x.
Names come from crews.json "jerseys" and scripts/cosmetics.gd ITEMS. Reads only; writes the one preview image.

Usage: python3 tools/art/make_cosmetics_preview.py
Needs: Pillow, numpy
"""
import json
import os
import re
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_players_v2 as V        # noqa: E402  decoded_pages(), cut(), jersey_defs()
import make_anim_sample as S       # noqa: E402  label(), floor_bg()

ROOT = V.ROOT
OUT = os.path.join(ROOT, "docs", "art", "cosmetics_preview.png")
PLAYERS = ["ud_deuce", "ud_jojo", "ud_tank", "ht_g1_crew", "mem_boss_crew", "ny_f1_crew"]
CELLS = [("idle", "S", 0), ("run_dribble", "SE", 2)]
COURTS = [("court_1", "midnight"), ("court_2", "gold_hall")]
BG = (24, 22, 34)
W = 1320


def item_names():
    src = open(os.path.join(ROOT, "scripts", "cosmetics.gd")).read()
    return {m.group(1): m.group(2) for m in re.finditer(r'"(\w+)": \{"kind": "\w+", "name": "([^"]+)"', src)}


def zoom(img, z):
    return img.resize((img.width * z, img.height * z), Image.NEAREST)


def main():
    names = item_names()
    jerseys = V.jersey_defs()
    pal_map = json.load(open(os.path.join(V.OUT_DIR, "palettes.json")))["palettes"]
    who = {e["id"]: e.get("name", "") for e in json.load(open(V.M.CREWS))["players"]}

    cw, ch = V.FW * 2, V.FH * 2
    colw = len(CELLS) * cw + 24
    left = 190
    head = 56
    rowh = ch + 8
    jer_h = head + 30 + len(PLAYERS) * rowh
    ball_h = 40 + 4 * 76
    van_h = 40 + 64 * 3 + 40
    court_h = 40 + len(COURTS) * 236
    H = jer_h + ball_h + van_h + court_h + 20
    img = Image.new("RGBA", (W, H), BG + (255,))
    dr = ImageDraw.Draw(img)

    # ---- jerseys
    S.label(dr, (12, 10), "COSMETICS PREVIEW (P8-09). Jerseys: your colors (default) and the 3 alternate jerseys, "
                          "idle S and running SE at the in-game 2x (palette only, same pages).", 15)
    looks = [("", "DEFAULT (blue and gold)")] + [("_j%d" % n, "%s (jersey_%d)" % (nm, n)) for n, nm, _ in jerseys]
    for c, (_, title) in enumerate(looks):
        S.label(dr, (left + c * colw, head - 20), title, 14, (255, 220, 120))
    floor = S.floor_bg(W - left + 8, len(PLAYERS) * rowh + 8)
    img.alpha_composite(floor, (left - 8, head))
    for r, sid in enumerate(PLAYERS):
        y = head + 4 + r * rowh
        base = pal_map[sid]["pages"]
        nm = who.get(base, "")
        S.label(dr, (12, y + ch // 2 - 16), sid, 14)
        S.label(dr, (12, y + ch // 2 + 2), nm, 13, (200, 200, 215))
        for c, (suf, _) in enumerate(looks):
            pages = V.decoded_pages(base, sid + suf)
            for k, (anim, dn, f) in enumerate(CELLS):
                img.alpha_composite(zoom(V.cut(pages, anim, dn, f).convert("RGBA"), 2),
                                    (left + c * colw + k * cw, y))

    # ---- balls
    y0 = jer_h + 10
    S.label(dr, (12, y0), "BALLS: the 4 spin frames at 4x", 15)
    balls = [("ball.png", "ORANGE (default)")] + [("ball_%d.png" % n, "%s (ball_%d)" % (names.get("ball_%d" % n, ""), n))
                                                  for n in (1, 2, 3)]
    for i, (f, title) in enumerate(balls):
        x = 12 + (i % 2) * 640
        y = y0 + 30 + (i // 2) * 150
        b = Image.open(os.path.join(ROOT, "assets", "ball", f)).convert("RGBA")
        dr.rectangle([x, y, x + 4 * 72 + 8, y + 72], fill=(44, 42, 60))
        for k in range(b.width // 16):
            img.alpha_composite(zoom(b.crop((k * 16, 0, k * 16 + 16, 16)), 4), (x + 8 + k * 72, y + 4))
        S.label(dr, (x + 310, y + 28), title, 15)

    # ---- vans
    y0 = jer_h + ball_h + 10
    S.label(dr, (12, y0), "VAN PAINTS (trip map) at 3x", 15)
    vans = [("van.png", "STOCK (default)")] + [("van_%d.png" % n, "%s (van_%d)" % (names.get("van_%d" % n, ""), n))
                                               for n in (1, 2, 3)]
    for i, (f, title) in enumerate(vans):
        v = Image.open(os.path.join(ROOT, "assets", "map", f)).convert("RGBA")
        x = 12 + i * 326
        dr.rectangle([x, y0 + 28, x + v.width * 3 + 8, y0 + 36 + v.height * 3], fill=(60, 92, 70))
        img.alpha_composite(zoom(v, 3), (x + 4, y0 + 32))
        S.label(dr, (x, y0 + 40 + v.height * 3), title, 14)

    # ---- court looks
    y0 = jer_h + ball_h + van_h + 10
    S.label(dr, (12, y0), "QUICK GAME COURT LOOKS: backdrop and floor tile at 2x (screenshots: docs/art/rewards_preview.png)",
            15)
    for i, (rid, look) in enumerate(COURTS):
        y = y0 + 30 + i * 236
        bd = Image.open(os.path.join(ROOT, "assets", "courts", look + "_backdrop.png")).convert("RGBA")
        fl = Image.open(os.path.join(ROOT, "assets", "courts", look + "_floor.png")).convert("RGBA")
        img.alpha_composite(zoom(bd, 2), (12, y))
        area = Image.new("RGBA", (W - 812, 200))
        t = zoom(fl, 2)
        for ty in range(0, area.height, t.height):
            for tx in range(0, area.width, t.width):
                area.alpha_composite(t, (tx, ty))
        img.alpha_composite(area, (800, y))
        S.label(dr, (12, y + 204), "%s (%s, look %s)" % (names.get(rid, ""), rid, look), 15)

    img.convert("RGB").save(OUT, optimize=True)
    print("wrote %s (%d x %d, %d bytes)" % (os.path.relpath(OUT, ROOT), W, H, os.path.getsize(OUT)))


if __name__ == "__main__":
    main()
