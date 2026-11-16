# P4-12 Phase 4 QA

Build tested: `ec032a9` ("--ballshots skips the launch panel like --shots"), dev branch `ccr-f5c087b2-3ojk5f`, in a
separate worktree on branch `qa-p4-12`. Godot 4.3 stable (Linux). Import is clean (no script errors). Default view is
ANGLED (no flag). Compared with `docs/qa/phase4-baseline.md` (build `a14a5ee`, before any Phase 4 code).

Summary: **gameplay unchanged (PASS)**, balance PASS, visuals PASS with small cosmetic notes, web build PASS
(pck 4.07 MB, fps the same or a bit better than the baseline on this machine). No tuning changes made.

## 1. Commands

```
godot --headless --path . --import
mkdir -p runs
# 2 x 100 autoplay games (ANGLED is the default), 8 in parallel on 4 cores
seq 1 100   | xargs -P 8 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay > runs/a{}.txt 2>&1"
seq 101 200 | xargs -P 8 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay > runs/a{}.txt 2>&1"
# humantests: 9 ANGLED, 3 FLAT on this build, plus 6 on the baseline commit a14a5ee as a control
godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --humantest [--view flat]
# screenshots (xvfb), 1280x720 and 1280x800 (add --resolution 1280x800 and -screen 0 1280x800x24)
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- --shots --court gym
#   variants: --shots --humantest; --shots --humantest --target 3 (side switch); --ballshots DIR;
#   --menushot --target 3; --court blacktop; --view flat
tools/build_web.sh
```
Stats are derived exactly as in the baseline report, section 1.

## 2. Autoplay, Hard vs Hard, ANGLED (default)

200/200 games reached `FINAL`; no `ERROR` or script error line in any output; no game hit `--quit-after`.
Batch 1 = the required 100-game repeat. Two stats in batch 1 were just past the 2 x combined-SE threshold (loser
points +0.84 vs 0.81, makes +0.97 vs 0.92; they move together, since more makes means more loser points). As the
baseline's compare rule says, I ran 100 more: batch 2 has no stat past the threshold, and the pooled 200 are all
within. With ~46 stats, 1-2 marginal flags per 100-game batch are expected by chance. **Verdict: no drift.**

Threshold = 2 x sqrt(SE_base^2 + SE_new^2) (baseline section 5). Baseline SEs are in `phase4-baseline.md`.

| Stat | Baseline | Batch 1 (100) mean [range] | Batch 2 (100) mean | 200 games mean [range] | 200 vs baseline: diff / threshold | Verdict |
|---|---|---|---|---|---|---|
| BLUE points | 18.46 | 18.96 [12 to 22] | 18.29 | 18.62 [9 to 22] | +0.16 / 0.83 | PASS |
| RED points | 18.50 | 18.86 [7 to 22] | 19.00 | 18.93 [7 to 22] | +0.43 / 0.80 | PASS |
| Winner points | 21.09 | 21.11 [21 to 22] | 21.13 | 21.12 [21 to 22] | +0.03 / 0.08 | PASS |
| Loser points | 15.87 | 16.71 [7 to 20] | 16.16 | 16.43 [7 to 20] | +0.56 / 0.73 | PASS (batch 1 just over, batch 2 and 200 within) |
| Point diff | -0.04 | 0.10 [-9 to 14] | -0.71 | -0.30 [-12 to 14] | -0.27 / 1.45 | PASS |
| Game length min | 11.31 | 11.55 [7.37 to 15.43] | 11.69 | 11.62 [7.37 to 16.60] | +0.31 / 0.43 | PASS |
| Dead-ball s | 36.40 | 37.38 [27 to 46] | 37.40 | 37.39 [27 to 49] | +0.99 / 1.08 | PASS |
| Possessions | 69.10 | 70.96 [46 to 92] | 71.30 | 71.13 [46 to 97] | +2.03 / 2.73 | PASS |
| Passes | 106.40 | 109.37 [61 to 161] | 109.87 | 109.62 [61 to 163] | +3.22 / 5.19 | PASS |
| Shots | 90.36 | 90.30 [55 to 133] | 92.79 | 91.55 [55 to 134] | +1.19 / 3.82 | PASS |
| Makes | 30.85 | 31.82 [24 to 39] | 31.26 | 31.54 [22 to 39] | +0.69 / 0.82 | PASS (batch 1 just over, batch 2 and 200 within) |
| FG% per game | 34.90 | 35.82 [25.56 to 50.91] | 34.34 | 35.08 [23.88 to 55.74] | +0.18 / 1.38 | PASS |
| Dunks | 27.20 | 26.26 [13 to 45] | 27.95 | 27.11 [13 to 45] | -0.09 / 1.68 | PASS |
| Layups | 26.00 | 26.29 [10 to 44] | 27.04 | 26.66 [10 to 44] | +0.66 / 1.57 | PASS |
| 2s made | 4.45 | 4.43 [0 to 10] | 4.22 | 4.33 [0 to 10] | -0.12 / 0.44 | PASS |
| 2s share % | 24.10 | 23.43 [0 to 47.62] | 22.68 | 23.06 [0 to 47.62] | -1.04 / 2.32 | PASS |
| Fouls | 3.79 | 3.47 [0 to 10] | 3.98 | 3.73 [0 to 12] | -0.06 / 0.51 | PASS |
| Fouls on BLUE | 1.83 | 1.87 [0 to 7] | 2.07 | 1.97 [0 to 7] | +0.14 / 0.37 | PASS |
| Fouls on RED | 1.96 | 1.60 [0 to 6] | 1.91 | 1.75 [0 to 6] | -0.21 / 0.34 | PASS |
| Fouls shooting | 2.32 | 2.10 [0 to 9] | 2.45 | 2.27 [0 to 9] | -0.04 / 0.39 | PASS |
| Fouls reach | 1.47 | 1.37 [0 to 5] | 1.53 | 1.45 [0 to 5] | -0.02 / 0.34 | PASS |
| And-ones | 0.95 | 0.97 [0 to 5] | 1.01 | 0.99 [0 to 5] | +0.04 / 0.24 | PASS |
| FT tried | 2.30 | 2.08 [0 to 9] | 2.38 | 2.23 [0 to 9] | -0.07 / 0.39 | PASS |
| FT made | 1.66 | 1.57 [0 to 7] | 1.81 | 1.69 [0 to 7] | +0.03 / 0.34 | PASS |
| FT timeouts | 0.00 | 0.00 [0 to 0] | 0.00 | 0.00 [0 to 0] | +0.00 / 0.00 | PASS |
| OOB | 2.10 | 2.27 [0 to 6] | 2.43 | 2.35 [0 to 8] | +0.25 / 0.38 | PASS |
| OOB baseline | 1.59 | 1.63 [0 to 5] | 1.78 | 1.71 [0 to 5] | +0.11 / 0.32 | PASS |
| OOB sideline | 0.51 | 0.64 [0 to 2] | 0.65 | 0.65 [0 to 3] | +0.14 / 0.18 | PASS |
| Steals | 10.10 | 10.48 [3 to 20] | 10.94 | 10.71 [3 to 22] | +0.61 / 0.96 | PASS |
| Steals BLUE | 4.92 | 5.49 [1 to 13] | 5.45 | 5.47 [0 to 13] | +0.55 / 0.63 | PASS |
| Steals RED | 5.18 | 4.99 [1 to 11] | 5.49 | 5.24 [1 to 12] | +0.06 / 0.59 | PASS |
| Steals/60 shots | 6.71 | 6.96 [2.12 to 12] | 7.17 | 7.06 [2.12 to 15.41] | +0.35 / 0.59 | PASS |
| Blocks | 10.27 | 10.01 [3 to 19] | 10.60 | 10.30 [3 to 20] | +0.04 / 0.87 | PASS |
| Blocks BLUE | 4.84 | 4.76 [0 to 12] | 5.17 | 4.96 [0 to 13] | +0.12 / 0.63 | PASS |
| Blocks RED | 5.43 | 5.25 [1 to 12] | 5.43 | 5.34 [1 to 14] | -0.09 / 0.62 | PASS |
| Blocks/60 shots | 6.75 | 6.57 [2.24 to 12.13] | 6.81 | 6.69 [2.24 to 12.13] | -0.06 / 0.44 | PASS |
| Crossovers | 26.50 | 27.12 [14 to 41] | 27.53 | 27.32 [13 to 51] | +0.82 / 1.60 | PASS |
| Crossover beats | 10.79 | 10.83 [3 to 19] | 10.37 | 10.60 [2 to 22] | -0.19 / 0.81 | PASS |
| Pump fakes | 11.67 | 11.79 [3 to 25] | 11.99 | 11.89 [2 to 25] | +0.22 / 0.99 | PASS |
| Fake bites | 4.71 | 4.87 [0 to 11] | 4.95 | 4.91 [0 to 11] | +0.20 / 0.58 | PASS |
| Lobs | 3.71 | 3.68 [0 to 8] | 3.36 | 3.52 [0 to 9] | -0.19 / 0.43 | PASS |
| Alley-oop makes | 1.39 | 1.55 [0 to 5] | 1.38 | 1.47 [0 to 6] | +0.08 / 0.28 | PASS |
| Interceptions | 3.95 | 3.92 [0 to 11] | 3.99 | 3.96 [0 to 11] | +0.00 / 0.52 | PASS |
| Shot-clock violations | 0.00 | 0.00 [0 to 0] | 0.00 | 0.00 [0 to 0] | +0.00 / 0.00 | PASS |
| Side switches | 1.00 | 1.00 [1 to 1] | 1.00 | 1.00 [1 to 1] | +0.00 / 0.00 | PASS |
| Lead changes | 2.19 | 2.20 [0 to 7] | 2.18 | 2.19 [0 to 8] | +0.00 / 0.47 | PASS |

Pooled rates (200 games; baseline in brackets): FG% 6308/18309 = 34.5% (34.1%); FT% 338/446 = 75.8% (72.2%,
SE 3.0); crossover beat % 2120/5465 = 38.8% (40.7%, SE 1.3; batch 1 39.9%, batch 2 37.7%); fake bite %
982/2378 = 41.3% (40.4%). Winner scored 21 in 176/200 (88%; baseline 91%) and the loser had 12-20 in 187/200 (93.5%;
baseline 90%). Every game had exactly one side switch, no shot-clock violations, no FT timeouts.

**Team balance:** BLUE won 49/100 in batch 1, 42/100 in batch 2, **91/200 = 45.5%** overall. At 200 games the SE is
3.5 pts, so 43-57% is the 2-SE band around 50% (and the baseline's 53/100 differs by 7.5 pts with a combined SE of
6.1: noise). PASS. The recent small batches with RED ahead fit this: 42/100 is within the 39-67% noise band of the
baseline's rule. If the lead wants more certainty, 200 more games would narrow the band to about 46.5-53.5%.

**Why no drift was expected (code check):** all Phase 4 script changes (`git diff a14a5ee ec032a9 -- scripts/`) are
in view.gd, court.gd, court_looks.gd, fx.gd, menu.gd, audio.gd, plus view parts of main.gd, player.gd and ball.gd.
The view code in player.gd and ball.gd reads sim state and writes only `_v_*` vars and its own view nodes (added
to `game.world`); the sim nodes stay children of main in the same order; defense.gd, human_input.gd and rules are
untouched. The only sim-facing change is `View.stick_to_world` on the joystick (identity in FLAT) and the inverse
on the humantest thumb.

**Headless CPU cost (performance note, not a gameplay change):** the 100-game batch took 11 min of wall time (44 min
CPU) vs about 4 min in the baseline. Same 4 games, 4 in parallel: FLAT 28.2 s CPU for 173,931 frames
(0.16 ms/frame), ANGLED 97.6 s for 160,285 frames (0.61 ms/frame), so the ANGLED view code costs about 0.45 ms of
script time per frame on this desktop CPU even with no rendering. On a tablet this could be a few ms per frame; see
follow-ups.

## 3. Humantest

The humantest is not deterministic. Because the baseline's 3 runs looked different from the new ones (timed blocks
70% then, 44-48% now; "in front" 61-62% then, 47-66% now), I re-ran 6 humantests on the baseline commit `a14a5ee`
itself as a control. The control matches the new build, so the baseline's 3 runs were a lucky sample, not a change.

| Totals | Baseline report (3 runs) | Control `a14a5ee` (6 runs) | ANGLED (9 runs) | FLAT (3 runs) |
|---|---|---|---|---|
| Finals (BLUE-RED) | 21-18, 21-18, 9-21 | 20-21, 11-21, 15-22, 14-21, 15-21, 14-22 | 20-21, 15-21, 10-21, 12-21, 20-22, 20-21, 16-22, 17-21, 21-19 | 14-21, 22-15, 21-18 |
| Timed steals | 41/50 (82%) | 76/95 (80%) | 108/139 (78%) | 46/54 (85%) |
| Random steals | 26/103 (25%) | 31/200 (16%) | 54/296 (18%) | 15/114 (13%) |
| Timed blocks | 14/20 (70%) | 12/29 (41%) | 26/58 (45%) | 12/25 (48%) |
| Early-jump blocks | 3/28 (11%) | 8/37 (22%) | 18/69 (26%) | 5/26 (19%) |
| Guarding in front | 61-62% | 43-72% | 47-64% | 47-66% |
| Beaten / spells | 33/214 | 48/367 | 91/616 | 35/245 |
| Assist frames (mean per run) | 3736 | 3370 | 3370 | 3909 |
| CPU crossovers beat him | 6/12 | 5/11 | 6/14 | 4/8 |
| Shot-clock violations | 0 | 0 | 0 | 0 |

Per-run means (control / ANGLED x6 / FLAT): shots 75 / 84 / 90, human steals 17.8 / 17.3 / 20.3 of 49 / 49 / 56
pokes, human blocks 3.8 / 6.8 / 7.7 of 15 / 21 / 22 jumps, human crossovers 34 / 35 / 44, human dunks 16 / 20 / 17.
No counter dropped to 0; no rate moved by more than a third against the control. FLAT vs ANGLED human stats match
within noise (the humantest thumb goes through `View.world_to_stick`, so this checks the stick mapping both ways).
PASS. No `ERROR` line in any humantest.

## 4. Visual checks (xvfb, 1280x720 and 1280x800)

Screenshots reviewed (all looked at):
- 1280x720 gym `--shots` (frames 240, 900, 1800) and `--shots --humantest` (240, 900, 1800, steal cue, BLOCK label)
- 1280x720 gym `--shots --humantest --target 3` side switch; `--ballshots` (dribble, lob, rim make, rim miss, dunk,
  net drop, loose, popup, fire)
- 1280x720 blacktop `--shots --humantest` (240, 900, 1800, steal cue)
- 1280x800 gym `--shots --humantest` (240, 900, 1800, steal cue, BLOCK label); 1280x800 blacktop side switch
- `--menushot --target 3`: gym at 1280x720, blacktop at 1280x800 (launch and game-over panels)
- 1280x720 `--view flat --shots --humantest` (FLAT still looks like the old top-down build)
- Web (Chromium 1280x800): launch panel, COURT toggled, after reload, MUSIC OFF/ON, game start, stick up / right /
  down-right, sprint pull, mid play, after play

| Check | Result |
|---|---|
| HUD readable over the gym crowd and the blacktop street (dark top bar) | PASS |
| Nothing off screen at 1280x720 / 1280x800; both sidelines in view; about 2/3 of the court length (zoom 1.68: 762 of 1128 px) | PASS |
| Far-sideline heads below the HUD bar (far sideline at y ~195 at 720, ~235 at 800; HUD bar 54 px) | PASS |
| Players depth-sorted (pile-ups in the key, a blue and a red overlapping, nearer one in front) | PASS |
| Ball vs rim/backboard: in front of the board on makes and the dunk from the court side, drops through the net under the rim (`net_drop`), rim-out at the right hoop correct | PASS |
| Hoops drawn above their floor spot (rim over the dark spot at the basket in the key, both hoops) | PASS |
| Popups ("+2", "RED FOR TWO!", "PERFECT RELEASE", "SWITCH SIDES") readable, below the HUD | PASS (see cosmetic 2) |
| Gym scenery (bleachers + crowd, banners at 16:10) and blacktop (fence, street, cars, buildings) | PASS |
| Launch and game-over panels with COURT and MUSIC buttons, readable, finger-sized | PASS |
| Side switch: camera stays; HUD shows `<< BLUE` after the switch (BLUE attacks left) | PASS |
| Touch buttons don't cover the action: they sit over the near-right corner as before (owner OK'd in Phase 2) | PASS |
| No debug drawings left (`VIEW_PROBE` removed; no stray lines/markers) | PASS |
| Steal cue ring on the floor under the ball | PASS, but often hidden by the players' legs (it is on the decal layer, under everyone) |
| Slow pan for shimmer | NOT CHECKED: only still images here; owner to judge on the tablet |

Cosmetic notes (not blockers):
1. At 1280x800 the gym backdrop's top row (scoreboard, banners) is cut by the screen top behind the HUD bar.
2. The "+2" popup over a make at the hoop overlaps the backboard and the crowd strip (still readable).
3. The camera follows the ball, so the human can be off screen during long passes or rebounds (web `11_mid_play`,
   ballshot `lob`: only the edge of his ring shows). This is the chosen Q1 framing, but an edge arrow for an
   off-screen human may help.
4. The orange button reads "-" on offense without the ball (unchanged behavior from before Phase 4).

## 5. Web build

`tools/build_web.sh` (no `--publish`): `build/web` 38 MB. **`index.pck` = 4,070,544 bytes (3.9 MiB)**, up from
273,216 (baseline); `index.wasm` 35,376,909 (unchanged). Under the 12 MB pck budget. Most of the growth is music
(`assets/music` 3.2 MB on disk, 6 tracks) and the player sheets (628 KB).

Chromium (Playwright's bundled Chromium 1243, headless, SwiftShader software WebGL, 1280x800, `hasTouch` +
`isMobile`, CDP `Input.dispatchTouchEvent`, served with `python3 -m http.server`), same sampler as the baseline:

| Measure | Baseline | Phase 4 |
|---|---|---|
| Load to game ready (loader overlay removed, local server) | not measured | 1.24-1.35 s |
| Launch panel fps | 15.9-19.8 | 19.7 |
| fps over 60 s of play (stick, sprint, flicks, A/B taps) | - | 22.7 |
| In game, 3 x 5 s | 19.3 / 21.0 / 19.8 | 24.1 / 23.7 / 23.4 |
| In game, 4x CPU throttle (CDP), 2 x 5 s | - | 20.0 / 20.7 |
| Console errors | - | none |

These are CPU-rendered numbers for comparing builds on this machine only; no fps regression. The board's 55+ fps
with 4x throttle can't be judged with software WebGL; it needs a real GPU or the tablet.

Touch checks (screenshots in the scratchpad web run): start panel shows; **COURT** toggled GYM -> BLACKTOP and,
after waiting 3 s and reloading, the panel came back as BLACKTOP (remembered); **MUSIC** toggled ON -> OFF (greyed)
-> ON; tapped NORMAL and the game started on the blacktop. Pushing the stick **up** moved the human toward the far
sideline on screen; right and down-right looked right; pulling past the ring turned the knob orange (sprint); flicks
ran; PASS / SHOOT / STEAL taps worked; a full 60 s of play with no console error. Audio: the page's AudioContext was
`running` and its clock advancing; headless Chromium doesn't enforce the first-gesture rule, so "music starts on
the first tap" must be checked on the tablet.

## 6. Bugs

None that block. Minor, all pre-existing:
- **Quit-time leak message** on desktop runs that use audio (`--shots`, `--menushot`):
  `ERROR: 2 resources still in use at exit` (`crowd.ogg`, and with the menu panel also `menu.ogg`). Steps: run
  `--menushot --target 3` under xvfb. Expected: clean exit. Actual: the leak line at exit. The baseline commit
  `a14a5ee` prints the same line (crowd.ogg), so it is not new; harmless (dummy audio driver, at quit).

## 7. Tuning

None. Camera zoom (1.68, min 1.2) and tilt (`TILT_Y` 0.48) look right: both sidelines always visible, about 2/3 of
the court length on screen as the owner chose, far heads clear of the HUD at 16:9 and 16:10.

## 8. Follow-ups

1. ANGLED view script cost: about 0.45 ms more CPU per frame than FLAT on desktop with no rendering (section 2).
   Worth a profile before Phase 5 (the P4-06 note: ~50 small `PackedVector2Array`s per frame from `_floor_ring`,
   shadows and rings redrawn every frame for every player). Measure on the tablet first.
2. Edge arrow or marker when the human is off screen (cosmetic 3).
3. Gym backdrop: shift it down or crop so the banners aren't cut at 16:10 (cosmetic 1).
4. FT% 75.8% vs 72.2% is within noise (1.2 SE) but worth watching in the next QA.

## 9. What the owner should judge on the tablet

- How steep the angle looks (`TILT_Y` 0.48) and the zoom (players' size, 2/3 of the court length).
- Readability of the players and the ball in pile-ups in the key, and of the ball against the backboard.
- The two new players #4 and #8 (look, outfits, how they read at game size next to the others).
- The two courts (gym bleachers and crowd; blacktop fence, street and cars) and the COURT button on both panels.
- Music: menu track on the panels, the court's track softly in game, MUSIC ON/OFF remembered, and that music starts
  on the first tap.
- Sounds: the new swish and ball bounce.
- Any shimmer while the camera pans slowly (non-integer zoom with nearest filtering).
- Frame rate in a full game on the tablet.
