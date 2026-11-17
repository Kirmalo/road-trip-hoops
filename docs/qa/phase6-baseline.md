# P6-00 Phase 6 baseline

Build tested: dev at `4675878` ("Phase 6: owner answers (G1) and animation sample approved (G2); P6-17 court
unlocks"), branch `ccr-f5c087b2-3ojk5f`, in a separate worktree, before any Phase 6 gameplay code. Godot 4.3 stable
(Linux). Import is clean: no script or parse error. All 200 Quick Game `--autoplay` games, 6/6 `--humantest` runs
and all 600 `--city` games reached `FINAL`. None of them printed a `SCRIPT ERROR`, parse error or `ERROR` line, and
none came near `--quit-after` (the longest Quick Game took 56,385 of 120,000 frames). The only `ERROR` lines anywhere
are the usual ALSA and "resources still in use at exit" lines from the xvfb `--shots` run.

The gameplay code hasn't changed since P5-16 (`0e8e1e7`). The only script changes since then are the `--difficulty`
flag in `--city` games (`main.gd`) and the title, lineup, bracket and `trip_test.gd` fixes. So the Quick Game
comparison below also measures the noise between two batches of the same game.

**Headline:**
- **Quick Game:** BLUE won 100/200 = 50.0% (SE 3.5). Per game: 11.2 min, 87.8 shots, 3.8 fouls, 2.4 OOB, 0 shot-clock
  violations, 1 side switch every game.
- **Against the P5-16 pool:** 3 of 40 stats are over the line (blocks, blocks per 60 shots, fake bites). All three are
  inside the line against P5-00, so there is no drift.
- **City games on Normal:** the Kings win 62-71% of every game. The ramp is still flat.
- **Web:** `index.pck` is 5,454,528 bytes.
- **fps:** the numbers are low because the machine was shared (load average 9-16 on 4 cores). See section 6.

## 1. Commands

```
godot --headless --path . --import
# Quick Game: 2 x 100 autoplay (Hard vs Hard, ANGLED, Flow.match empty), 3-5 in parallel
seq 1 100   | xargs -P 5 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay > runs/a{}.txt 2>&1"
seq 101 200 | xargs -P 3 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay > runs/a{}.txt 2>&1"
# 6 humantests (Quick Game, Hard)
seq 1 6 | xargs -P 2 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --humantest > runs/h{}.txt 2>&1"
# campaign, 100 games each, Normal (the --city default; the MATCH line says "level normal")
godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay --city hometown --cgame 1   # 1..3, chicago 1..3
# screenshots
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- --shots
# fps: Godot (xvfb, llvmpipe, no --fixed-fps), 60 s of a CPU vs CPU Quick Game
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --quit-after 3600 -- --autoplay --fps
tools/build_web.sh
```

The stats are worked out as in `docs/qa/phase4-baseline.md` section 1 and `docs/qa/phase5-baseline.md`, from the
`FINAL`, `GAME LENGTH` and `FOULS` / `FREE THROWS` lines and the stats JSON. The runs were slow because other jobs
shared the machine: a 100-game batch took 40-60 min instead of 13 min in P5-00. `--fixed-fps 60` keeps the games
independent of that. The city batch was stopped once at its 2 h limit; I re-ran only the games with no `FINAL`, so
every game counted is a complete run.

## 2. Quick Game, 200 games (Hard vs Hard, ANGLED, first ball random)

The first 100 games are the batch the task asked for. In that batch 2 stats crossed the line against P5-16 (blocks,
blocks per 60 shots), so I ran 100 more, as the compare rule says. **The 200-game pool is the baseline for P6-40.**
The compare rule is from phase5-baseline.md section 5: a difference is real if it is more than
2 x sqrt(SE_base^2 + SE_new^2).

| Stat | P6-00 200: mean | SD | SE | min-max | first 100: mean (SE) | P5-16 pooled 200: mean (SE) | diff (200) | limit | |
|---|---|---|---|---|---|---|---|---|---|
| BLUE points | 18.43 | 3.59 | 0.25 | 6-22 | 18.20 (0.38) | 18.88 (0.21) | -0.45 | 0.66 | ok |
| RED points | 18.43 | 3.44 | 0.24 | 9-22 | 18.59 (0.33) | 18.43 (0.23) | +0.00 | 0.67 | ok |
| Winner points | 21.09 | 0.28 | 0.02 | 21-22 | 21.06 (0.02) | 21.09 (0.02) | -0.00 | 0.06 | ok |
| Loser points | 15.78 | 3.24 | 0.23 | 6-20 | 15.73 (0.33) | 16.21 (0.19) | -0.44 | 0.60 | ok |
| Point diff (BLUE - RED) | 0.00 | 6.26 | 0.44 | -15 to +12 | -0.39 (0.63) | 0.45 (0.40) | -0.45 | 1.19 | ok |
| Game length, minutes | 11.22 | 1.77 | 0.13 | 7.58-15.65 | 11.25 (0.17) | 11.46 (0.13) | -0.24 | 0.36 | ok |
| Dead-ball seconds | 36.66 | 4.72 | 0.33 | 27-51 | 36.36 (0.46) | 36.84 (0.31) | -0.18 | 0.91 | ok |
| Possessions | 68.85 | 10.68 | 0.76 | 47-98 | 68.87 (1.11) | 69.86 (0.80) | -1.01 | 2.20 | ok |
| Passes | 104.61 | 19.57 | 1.38 | 64-167 | 103.98 (1.88) | 108.25 (1.69) | -3.64 | 4.37 | ok |
| Shots | 87.83 | 14.97 | 1.06 | 56-123 | 87.97 (1.45) | 90.08 (1.15) | -2.25 | 3.13 | ok |
| Shots BLUE | 42.13 | 8.22 | 0.58 | 22-64 | 41.98 (0.82) | 43.66 (0.61) | -1.53 | 1.69 | ok |
| Shots RED | 42.40 | 8.01 | 0.57 | 25-61 | 42.73 (0.77) | 42.91 (0.59) | -0.51 | 1.64 | ok |
| Makes | 30.82 | 3.39 | 0.24 | 22-39 | 30.68 (0.32) | 31.25 (0.23) | -0.43 | 0.66 | ok |
| FG% (per game) | 35.74 | 4.93 | 0.35 | 25-50.85 | 35.45 (0.45) | 35.48 (0.38) | +0.26 | 1.03 | ok |
| Dunks (tries) | 25.64 | 6.66 | 0.47 | 13-44 | 25.64 (0.62) | 26.55 (0.46) | -0.91 | 1.32 | ok |
| Layups (tries) | 25.45 | 6.25 | 0.44 | 12-45 | 25.87 (0.60) | 26.58 (0.43) | -1.13 | 1.23 | ok |
| 2s made | 4.31 | 1.65 | 0.12 | 0-9 | 4.38 (0.17) | 4.38 (0.12) | -0.07 | 0.33 | ok |
| 2s share of points, % | 23.50 | 9.09 | 0.64 | 0-47.06 | 23.82 (0.91) | 23.64 (0.66) | -0.14 | 1.84 | ok |
| Fouls | 3.77 | 1.85 | 0.13 | 0-10 | 3.71 (0.18) | 3.70 (0.15) | +0.07 | 0.40 | ok |
| Fouls: shooting | 2.38 | 1.45 | 0.10 | 0-8 | 2.36 (0.14) | 2.31 (0.11) | +0.07 | 0.30 | ok |
| Fouls: reach | 1.39 | 1.14 | 0.08 | 0-6 | 1.35 (0.12) | 1.39 (0.10) | +0.00 | 0.26 | ok |
| And-ones | 1.03 | 0.92 | 0.06 | 0-4 | 0.96 (0.10) | 1.07 (0.08) | -0.04 | 0.21 | ok |
| Free throws tried | 2.36 | 1.45 | 0.10 | 0-8 | 2.34 (0.14) | 2.29 (0.11) | +0.07 | 0.30 | ok |
| Free throws made | 1.73 | 1.20 | 0.09 | 0-6 | 1.73 (0.13) | 1.68 (0.09) | +0.05 | 0.25 | ok |
| FT timeouts | 0.00 | 0.00 | 0.00 | 0-0 | 0.00 (0.00) | 0.00 (0.00) | +0.00 | 0.00 | ok |
| Out of bounds | 2.42 | 1.71 | 0.12 | 0-9 | 2.29 (0.16) | 2.28 (0.11) | +0.14 | 0.33 | ok |
| Steals | 10.09 | 3.98 | 0.28 | 2-21 | 10.07 (0.40) | 10.37 (0.26) | -0.28 | 0.77 | ok |
| Steals per 60 shots | 6.94 | 2.65 | 0.19 | 1.52-15 | 6.90 (0.27) | 7.00 (0.18) | -0.06 | 0.52 | ok |
| Blocks | 10.00 | 3.75 | 0.27 | 1-23 | 9.69 (0.31) | 11.12 (0.27) | -1.12 | 0.76 | over |
| Blocks per 60 shots | 6.76 | 2.04 | 0.14 | 0.77-13.15 | 6.59 (0.18) | 7.36 (0.14) | -0.60 | 0.40 | over |
| Crossovers | 26.11 | 6.74 | 0.48 | 10-47 | 26.34 (0.70) | 27.24 (0.48) | -1.13 | 1.35 | ok |
| Crossover beats | 10.00 | 3.48 | 0.25 | 4-21 | 9.99 (0.33) | 10.66 (0.26) | -0.66 | 0.72 | ok |
| Pump fakes | 11.95 | 3.82 | 0.27 | 4-21 | 11.99 (0.36) | 11.59 (0.27) | +0.36 | 0.76 | ok |
| Fake bites | 5.08 | 2.44 | 0.17 | 0-15 | 5.08 (0.26) | 4.58 (0.17) | +0.50 | 0.48 | over |
| Lobs | 3.58 | 1.72 | 0.12 | 0-8 | 3.49 (0.17) | 3.84 (0.13) | -0.25 | 0.36 | ok |
| Alley-oop makes | 1.61 | 1.24 | 0.09 | 0-6 | 1.52 (0.12) | 1.71 (0.09) | -0.10 | 0.25 | ok |
| Interceptions | 3.87 | 1.96 | 0.14 | 0-10 | 3.97 (0.20) | 3.85 (0.15) | +0.02 | 0.41 | ok |
| Shot-clock violations | 0.00 | 0.00 | 0.00 | 0-0 | 0.00 (0.00) | 0.00 (0.00) | +0.00 | 0.00 | ok |
| Side switches | 1.00 | 0.00 | 0.00 | 1-1 | 1.00 (0.00) | 1.00 (0.00) | +0.00 | 0.00 | ok |
| Lead changes | 1.90 | 1.84 | 0.13 | 0-7 | 2.00 (0.19) | 1.96 (0.12) | -0.06 | 0.35 | ok |

**The three stats over the line against the P5-16 pool, checked against P5-00** (`docs/qa/phase5-baseline.md`, 100
games):

| Stat | P6-00 200 | P5-16 200 | P5-00 100 | P6-00 - P5-00 | limit | |
|---|---|---|---|---|---|---|
| Blocks | 10.00 (0.27) | 11.12 (0.27) | 10.67 (0.39) | -0.67 | 0.95 | ok |
| Blocks per 60 shots | 6.76 (0.14) | 7.36 (0.14) | 6.96 (0.20) | -0.20 | 0.49 | ok |
| Fake bites | 5.08 (0.17) | 4.58 (0.17) | 5.14 (0.26) | -0.06 | 0.62 | ok |

P5-16's pool was on the high side for blocks and on the low side for fake bites. P6-00 is close to P5-00 on all
three. All three builds run the same gameplay code, so this is batch noise: with about 40 stats, 2-3 crossings per
comparison are expected. The two halves agree with each other (blocks 9.69 / 10.31, fake bites 5.08 / 5.07). Layups
crossed the line in the second 100 alone (25.02), but not in the pool.

Pooled rates (200 games, P5-16 in brackets):
- FG% 35.1% (6165/17565; 34.7%)
- FT% 73.1% (345/472; 73.4%)
- Crossover beats 38.3% (2000/5222; 39.2%)
- Fake bites 42.5% (1015/2390; 39.5%)
- Per 60 shots: steals 6.89, blocks 6.83, lobs 2.45, interceptions 2.64.

| Check (CLAUDE.md targets) | Result | |
|---|---|---|
| Game length 10-15 min (typical) | mean 11.22, range 7.6-15.7; 50/200 under 10 min, 3 over 15 | pass (as in P5) |
| Shots 75-120 | mean 87.8, range 56-123 | pass |
| Ends 21-x, loser usually 12-20 | winner scored 21 in 183/200 (22 in 17); loser 12-20 in 176/200 | pass |
| Fouls 2-6, OOB 2-3 | 3.77, 2.42 | pass |
| One side switch | 200/200 | pass |
| Few interceptions, no shot-clock violations | 3.87 per game, 0 shot-clock violations, 0 FT timeouts | pass |
| Team balance | **BLUE 47/100 + 53/100 = 100/200 = 50.0% (SE 3.5)** | pass |
| Games that never end, stuck ball | none (longest game 56,385 frames) | pass |

## 3. Humantest, 6 runs (Quick Game, Hard, ANGLED)

| Run | Final | Length | `HUMANTEST` line |
|---|---|---|---|
| 1 | BLUE 10 - RED 21 | 8:19 | steals timed 13/17 random 8/36, blocks timed 6/9 early 3/10, in front 67% beaten 6 in 76, assist 3576 (3 pulling away), crossovers beat him 2/4, FTs good 0/0 early 0/0 |
| 2 | BLUE 20 - RED 21 | 10:24 | steals timed 18/22 random 10/41, blocks timed 8/10 early 1/10, in front 67% beaten 15 in 82, assist 4100 (0), crossovers 3/5, FTs 0/0 early 1/1 |
| 3 | BLUE 12 - RED 21 | 6:56 | steals timed 12/14 random 5/24, blocks timed 2/3 early 0/4, in front 61% beaten 9 in 48, assist 2690 (0), crossovers 1/1, FTs 0/0 early 0/0 |
| 4 | BLUE 16 - RED 21 | 10:10 | steals timed 15/17 random 8/38, blocks timed 4/10 early 3/11, in front 59% beaten 14 in 89, assist 3851 (2), crossovers 1/3, FTs 0/0 early 0/0 |
| 5 | BLUE 13 - RED 21 | 8:01 | steals timed 10/10 random 3/28, blocks timed 2/5 early 3/7, in front 52% beaten 11 in 61, assist 3088 (5), crossovers 0/1, FTs 0/0 early 0/0 |
| 6 | BLUE 21 - RED 17 | 8:28 | steals timed 13/15 random 5/31, blocks timed 4/6 early 1/7, in front 66% beaten 5 in 59, assist 3079 (0), crossovers 0/1, FTs 1/1 early 1/1 |

| Totals | P6-00 (6 runs) | P5-16 pooled (12 runs) | P5-00 (6 runs) |
|---|---|---|---|
| Timed steals | 81/95 (85%) | 151/176 (86%) | 72/90 (80%) |
| Random steals | 39/198 (20%) | 71/361 (20%) | 30/165 (18%) |
| Timed blocks | 26/43 (60%) | 39/61 (64%) | 13/36 (36%) |
| Early-jump blocks | 11/49 (22%) | 18/81 (22%) | 3/46 (7%) |
| Guarding in front | 52-67% | 46-68% | 39-67% |
| Beaten / spells | 60/415 | 116/749 | 56/353 |
| Assist frames (mean per run) | 3397 | 3060 | 3013 |
| CPU crossovers beat him | 7/15 | 17/29 | 3/7 |
| Shot-clock violations | 0 | 0 | 0 |

| Counter (stats JSON) | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 | Run 6 | Mean |
|---|---|---|---|---|---|---|---|
| shots / makes | 79 / 27 | 93 / 38 | 59 / 29 | 98 / 35 | 77 / 29 | 75 / 34 | 80.2 / 32.0 |
| human_steals / human_steal_pokes | 21 / 53 | 28 / 63 | 17 / 38 | 23 / 55 | 13 / 38 | 18 / 46 | 20.0 / 48.8 |
| human_blocks / human_block_jumps | 10 / 22 | 12 / 30 | 3 / 10 | 11 / 27 | 5 / 18 | 5 / 17 | 7.7 / 20.7 |
| human_crossovers / human_cross_beats | 36 / 6 | 38 / 7 | 22 / 4 | 43 / 7 | 27 / 6 | 40 / 6 | 34.3 / 6.0 |
| human_pump_fakes / human_pump_bites | 19 / 8 | 22 / 5 | 13 / 2 | 19 / 3 | 14 / 3 | 17 / 4 | 17.3 / 4.2 |
| human_dunks / human_layups | 14 / 5 | 17 / 7 | 10 / 4 | 18 / 6 | 11 / 5 | 20 / 3 | 15.0 / 5.0 |
| human_alleyoop_lobs / catches | 4 / 2 | 3 / 4 | 3 / 2 | 5 / 3 | 1 / 1 | 7 / 3 | 3.8 / 2.5 |
| human_fouled / human_ft_attempts | 0 / 0 | 1 / 1 | 0 / 0 | 0 / 0 | 0 / 0 | 3 / 2 | 0.7 / 0.5 |
| intercepts / out_of_bounds | 5 / 2 | 7 / 1 | 1 / 0 | 5 / 4 | 5 / 3 | 5 / 3 | 4.7 / 2.2 |
| steals / blocks (all) | 25 / 12 | 31 / 16 | 19 / 3 | 24 / 12 | 14 / 7 | 19 / 8 | 22.0 / 9.7 |

BLUE (the scripted human) won 1 of 6 (P5-16: 5/12). Every rate is within a third of P5-16's 12-run pool, and no
counter dropped to 0 over the 6 runs (human free-throw attempts are rare: 3 in 6 runs). All 6 runs had one side
switch and no shot-clock violation.

## 4. Campaign balance, 100 games each, Normal

The setup is the same as in phase5.md section 4:
- **BLUE** is the Cornfield Kings: Deuce, Jojo and Tank at their starting ratings, played by the CPU with the Hard
  knobs.
- **RED** is the city crew at its stage ratings, with the Normal knobs.

Every run printed `MATCH ... | level normal` and had the stats key `difficulty_normal`.

| City game | To | Games | Kings win % (SE) | Length mean (min-max) | Score (Kings - city) | Loser pts (range) | Point share | Shots | Fouls | OOB | SCV | P5-16 win % (40 games) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Hometown 1 | 11 | 100/100 | 70% (5) | 5.6 (3.0-10.1) | 10.4 - 8.4 | 7.6 (0-10) | 55.1% | 44 | 1.8 | 1.3 | 0 | 68% |
| Hometown 2 | 15 | 100/100 | 62% (5) | 7.7 (4.6-12.2) | 13.8 - 12.5 | 11.2 (3-14) | 52.4% | 61 | 2.7 | 1.7 | 0 | 65% |
| Hometown 3 (boss) | 21 | 100/100 | 64% (5) | 11.2 (6.8-16.6) | 19.4 - 17.5 | 15.7 (9-20) | 52.6% | 90 | 4.0 | 2.5 | 0 | 68% |
| Chicago 1 | 11 | 100/100 | 66% (5) | 5.7 (3.5-9.5) | 10.1 - 8.6 | 7.5 (0-10) | 54.1% | 46 | 1.9 | 1.1 | 0 | 70% |
| Chicago 2 | 15 | 100/100 | 71% (5) | 7.6 (3.3-10.9) | 14.2 - 11.8 | 10.9 (3-14) | 54.7% | 62 | 2.6 | 1.5 | 0 | 62% |
| Chicago 3 (boss) | 21 | 100/100 | 62% (5) | 10.6 (7.4-14.0) | 19.1 - 17.9 | 15.9 (8-20) | 51.6% | 85 | 3.6 | 2.2 | 0 | 60% (63% of 60) |

All 600 games reached `FINAL`, with one side switch each, no shot-clock violations and no script errors. Every city
game is within 2 combined SE of P5-16's 40-game number. Some Hometown 1 and Chicago 1 games ended with the loser on 0
(loser range 0-10).

**The ramp is still flat, as P5-16 found:**
- **Game 1 vs the boss game:** Hometown 70% -> 64% (a 6-point drop, SE 7) and Chicago 66% -> 62% (4 points, SE 7).
  Both cities go the right way, but neither drop is significant on 100 games.
- **Game 2** doesn't sit between them: Chicago 2 is the highest of the three at 71%.
- **Point share** does fall from game 1 to the boss game (55.1 -> 52.6, 54.1 -> 51.6), so the stronger crews cost
  points. But the boss game is longer (to 21), and that gives the better side more chances to win, which cancels it.
- **Floor:** the lowest game is 62%, far above the 30% floor: pass.
- **Length:** matches the campaign targets P5-16 proposed (to 11: 4-8 min, here a mean of 5.6-5.7; to 15: 7.6-7.7;
  to 21: 10.6-11.2).

Use these as the per-city reference for P6-30 (twist on vs off). With 100 games the win-share SE is 5 points, so a
twist that moves the split by less than about 14 points (2 x sqrt(5^2 + 5^2)) can't be told from noise. Point share
and length are more sensitive measures.

## 5. Screenshots (`--shots`, 1280x720)

Checked `/tmp/hoops_240.png`, `_900.png` and `_1800.png` (gym, ANGLED):
- The HUD is readable: FIRST TO 21, the score with the possession arrow, the SHOT clock, the pause button top-right.
- The joystick (bottom-left) and PASS / SHOOT (STEAL / SWITCH on defense, bottom-right) stay clear of the play.
- Nothing is off screen.

Pass. This build has no new effects to check.

## 6. Web build and fps

`tools/build_web.sh` (no publish) built `build/web` (40 MB).
- **`index.pck` = 5,454,528 bytes (5.20 MiB)**, 1,200 bytes more than P5-16's 5,453,328. The P6-A0 sample isn't in the
  pck; the extra bytes are script changes.
- `index.wasm` = 35,376,909 bytes (unchanged).
- The Q8 budget (15-20 MB, owner answer (a)) holds with about 10 MB to spare.

**fps.** Other agents' jobs shared the machine the whole time: the load average was 9-16 on 4 cores during these runs,
and above 15 during the Chromium runs. So these numbers are much lower than P4-12's on an idle machine and are **not**
a fair baseline on their own.

| Measure | P6-00 (load 9-16) | P4-12 (idle) |
|---|---|---|
| Godot `--fps`, xvfb llvmpipe 1280x720, `--autoplay`, 60 s | FPS 35-64, median 56 (13 lines: 53 55 61 61 44 53 62 35 64 63 56 56 48) | - |
| Chromium, load to game ready | 2.8-3.5 s | 1.24-1.35 s |
| Chromium in game, 3 x 5 s rAF count (2 runs) | 11.2 / 10.2 / 11.2; 11.1 / 11.8 / 12.4 | 24.1 / 23.7 / 23.4 |
| Chromium, 4x CPU throttle, 2 x 5 s | 9.8 / 9.4; 9.1 / 10.2 | 20.0 / 20.7 |
| In-game `FPS n` lines (Chromium console) | 7-14 | - |
| Console errors | none | none |

The Chromium method is the same as in P4-12:
- Playwright Chromium 1243, headless, SwiftShader WebGL (`--use-angle=swiftshader --enable-unsafe-swiftshader
  --ignore-gpu-blocklist`).
- 1280x800 viewport, `hasTouch` + `isMobile`, served with `python3 -m http.server`.
- A 12 s wait, then the rAF sampler from phase4-baseline.md.

One difference: the game here is a CPU vs CPU Quick Game, not one played by touch. A copy of `index.html` with
`"args": ["--", "--autoplay", "--fps"]` starts it (same build files), which keeps the load steady and repeatable.
Without the `--`, the args are ignored and the title stays up.

**For P6-31:** don't compare against these absolute numbers. Build `4675878` and the Phase 6 build side by side,
measure them back to back in the same session with the same script (alternating A/B/A/B), and note the load average.

## 7. Bugs

None found in this pass.

## 8. Tuning

None applied, and the baseline needs none. The flat city ramp is the same finding as P5-16 section 8; the owner or
lead decides what to do about it (a bigger boss tier, or a per-game level step). The ratings move the results less
than the level knobs do.

## 9. How to compare (P6-40, P6-30)

- **P6-40:**
  - Run 200 Quick Game `--autoplay` games with the flags from section 1, and compare each stat with the 200-game
    column in section 2.
  - A difference is real if |diff| > 2 x sqrt(SE_P6-00^2 + SE_new^2), which is about 2.8 x the SE column at 200 vs
    200. Examples: shots +-3.0, game length +-0.37 min, loser points +-0.65, FG% +-0.99 points, blocks per 60 shots
    +-0.40, steals per 60 shots +-0.53, fouls +-0.37, OOB +-0.34, interceptions +-0.39.
  - With only 100 new games, use SD / 10 as SE_new.
  - Expect 2-3 of the 40 stats over the line by chance (this task had 3). Re-run before calling it drift.
- **Counts that are 0 here** (shot-clock violations, FT timeouts) and **side switches** (always 1): any change is a
  bug.
- **BLUE win share:** 50.0% (SE 3.5). The animation work must not change it; 40-60% at 200 games is noise.
- **Humantest:** compare 6-run totals with section 3. Flag a rate that moves by more than a third, or a counter that
  drops to 0.
- **`index.pck`:** compare against 5,454,528 bytes and the Q8 budget.
- **P6-30:** compare each city with section 4 (100 games per city game).
