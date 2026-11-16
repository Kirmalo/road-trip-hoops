# P5-00 Gameplay baseline before Phase 5

Build tested: dev at `ad4dff8` ("Record owner answers for the Phase 5 plan"), branch `ccr-f5c087b2-3ojk5f`, in a
separate worktree on branch `qa-p5-00`, before any Phase 5 code. Godot 4.3 stable (Linux), headless. Default view
(ANGLED), Hard vs Hard. Import is clean (no script errors). 100/100 `--autoplay` games and 6/6 `--humantest` runs
reached `FINAL`; no `ERROR` or script error line in any output; no game hit `--quit-after`.

P5-16 repeats this on the final Phase 5 build (Quick Game: rating 50, empty `Flow.match`) and compares with
section 5.

## 1. Commands

```
godot --headless --path . --import
mkdir -p runs
# 100 autoplay games, Hard (the default for --autoplay), ANGLED (default), 8 in parallel on 4 cores (~13 min)
seq 1 100 | xargs -P 8 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay > runs/a{}.txt 2>&1"
# 6 humantests, 6 in parallel
seq 1 6 | xargs -P 6 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --humantest > runs/h{}.txt 2>&1"
tools/build_web.sh
```

Stats are derived exactly as in `docs/qa/phase4-baseline.md` section 1, plus per-team splits from the stats JSON:
possessions `possessions_t0/_t1`; shots `shots_half1_tN + shots_half2_tN`; makes
`points1_tN + points2_tN - ft_makes_tN` (field goals only); dunks/layups `dunks_tN`/`layups_tN`; 2s
`points2_tN`; FT tried from the `FREE THROWS` line; OOB `oob_tN` (the team charged with the ball going out);
steals/blocks `steals_tN`/`blocks_tN`; crossovers `crossovers_tN`. Fouls on BLUE / RED = fouls committed by that
team (the `FOULS BLUE x RED y` line).

## 2. Autoplay, 100 games, Hard vs Hard, ANGLED (first ball random)

SD = standard deviation per game; SE = SD / 10 (standard error of the 100-game mean).

| Stat | Mean | SD | SE | Min | Max |
|---|---|---|---|---|---|
| BLUE points | 18.21 | 3.40 | 0.34 | 9 | 22 |
| RED points | 18.94 | 3.44 | 0.34 | 9 | 22 |
| Winner points | 21.13 | 0.34 | 0.03 | 21 | 22 |
| Loser points | 16.02 | 3.22 | 0.32 | 9 | 20 |
| Point diff (BLUE - RED) | -0.73 | 6.01 | 0.60 | -13 | 12 |
| Game length, minutes | 11.46 | 2.02 | 0.20 | 6.85 | 16.67 |
| Dead-ball seconds | 36.78 | 4.70 | 0.47 | 26 | 47 |
| Possessions | 70.43 | 12.55 | 1.25 | 39 | 103 |
| Possessions BLUE | 35.18 | 6.28 | 0.63 | 20 | 51 |
| Possessions RED | 35.25 | 6.29 | 0.63 | 19 | 52 |
| Passes | 107.87 | 23.57 | 2.36 | 62 | 168 |
| Shots | 91.05 | 16.46 | 1.65 | 52 | 134 |
| Shots BLUE | 44.09 | 8.72 | 0.87 | 26 | 62 |
| Shots RED | 43.54 | 9.12 | 0.91 | 22 | 80 |
| Makes | 31.14 | 3.52 | 0.35 | 23 | 39 |
| Makes BLUE | 15.36 | 2.78 | 0.28 | 8 | 20 |
| Makes RED | 15.78 | 2.89 | 0.29 | 8 | 20 |
| FG% (per game) | 34.95 | 5.24 | 0.52 | 23.36 | 49.30 |
| FG% BLUE | 35.76 | 7.95 | 0.79 | 18.64 | 58.62 |
| FG% RED | 37.12 | 7.67 | 0.77 | 21.15 | 57.14 |
| Dunks (tries) | 27.23 | 6.54 | 0.65 | 12 | 44 |
| Dunks (tries) BLUE | 13.65 | 4.18 | 0.42 | 3 | 24 |
| Dunks (tries) RED | 13.58 | 4.29 | 0.43 | 4 | 26 |
| Layups (tries) | 26.16 | 6.88 | 0.69 | 13 | 43 |
| Layups (tries) BLUE | 13.17 | 4.34 | 0.43 | 3 | 23 |
| Layups (tries) RED | 12.99 | 4.04 | 0.40 | 4 | 25 |
| 2s made | 4.41 | 1.56 | 0.16 | 1 | 8 |
| 2s made BLUE | 2.15 | 1.45 | 0.14 | 0 | 6 |
| 2s made RED | 2.26 | 1.35 | 0.14 | 0 | 6 |
| 2s share of points, % | 23.96 | 8.76 | 0.88 | 5.13 | 43.75 |
| Fouls | 3.86 | 1.95 | 0.20 | 0 | 10 |
| Fouls on BLUE | 1.97 | 1.42 | 0.14 | 0 | 6 |
| Fouls on RED | 1.89 | 1.27 | 0.13 | 0 | 7 |
| Fouls: shooting | 2.27 | 1.50 | 0.15 | 0 | 7 |
| Fouls: reach | 1.59 | 1.40 | 0.14 | 0 | 7 |
| And-ones | 1.01 | 1.05 | 0.10 | 0 | 4 |
| Free throws tried | 2.25 | 1.51 | 0.15 | 0 | 7 |
| FT tried BLUE | 1.07 | 1.04 | 0.10 | 0 | 4 |
| FT tried RED | 1.18 | 1.04 | 0.10 | 0 | 4 |
| Free throws made | 1.60 | 1.26 | 0.13 | 0 | 5 |
| FT timeouts | 0.00 | 0.00 | 0.00 | 0 | 0 |
| Out of bounds | 2.16 | 1.47 | 0.15 | 0 | 8 |
| OOB BLUE | 1.06 | 0.97 | 0.10 | 0 | 4 |
| OOB RED | 1.10 | 1.06 | 0.11 | 0 | 4 |
| OOB baseline | 1.45 | 1.30 | 0.13 | 0 | 7 |
| OOB sideline | 0.71 | 0.86 | 0.09 | 0 | 4 |
| Steals | 10.61 | 3.90 | 0.39 | 2 | 20 |
| Steals BLUE | 5.17 | 2.34 | 0.23 | 0 | 11 |
| Steals RED | 5.44 | 2.46 | 0.25 | 0 | 12 |
| Steals per 60 shots | 6.97 | 2.28 | 0.23 | 1.97 | 13.24 |
| Blocks | 10.67 | 3.94 | 0.39 | 2 | 19 |
| Blocks BLUE | 5.27 | 2.44 | 0.24 | 1 | 11 |
| Blocks RED | 5.40 | 2.73 | 0.27 | 1 | 13 |
| Blocks per 60 shots | 6.96 | 2.04 | 0.20 | 1.69 | 11.29 |
| Crossovers | 26.83 | 6.74 | 0.67 | 11 | 49 |
| Crossovers BLUE | 13.48 | 4.15 | 0.42 | 5 | 24 |
| Crossovers RED | 13.35 | 4.53 | 0.45 | 2 | 25 |
| Crossover beats | 10.23 | 3.62 | 0.36 | 4 | 21 |
| Pump fakes | 11.84 | 3.83 | 0.38 | 3 | 20 |
| Fake bites | 5.14 | 2.61 | 0.26 | 0 | 12 |
| Lobs | 3.92 | 1.81 | 0.18 | 1 | 9 |
| Alley-oop makes | 1.73 | 1.46 | 0.15 | 0 | 7 |
| Interceptions | 3.72 | 2.00 | 0.20 | 0 | 9 |
| Shot-clock violations | 0.00 | 0.00 | 0.00 | 0 | 0 |
| Side switches | 1.00 | 0.00 | 0.00 | 1 | 1 |
| Lead changes | 2.22 | 1.90 | 0.19 | 0 | 8 |

Pooled rates over the 100 games (phase4.md 200-game pool in brackets):

| Rate | Value |
|---|---|
| FG% (3114 / 9105) | 34.2% (34.5%) |
| FT% (160 / 225) | 71.1% (75.8%; SE about 3 pts) |
| Crossover beat % (1023 / 2683) | 38.1% (38.8%) |
| Fake bite % (514 / 1184) | 43.4% (41.3%) |
| Steals / blocks / lobs / interceptions per 60 shots | 6.99 / 7.03 / 2.58 / 2.45 |
| **BLUE wins** | **43 / 100 = 43%** (SE 5 pts) |

Other checks against the CLAUDE.md targets: winner scored 21 in 87 games (22, a 2 from 20, in 13); the loser had
12-20 in 85/100; game length 6.9-16.7 min (23 games under 10 min, 4 over 15); fouls 3.9 and OOB 2.2 per game; every
game had exactly one side switch, no shot-clock violations, no FT timeouts. Shots 91 per game sits in the 75-120
target. All stats are within 2 x combined SE of phase4.md's 200-game numbers (closest: alley-oop makes +0.26 vs threshold 0.33; blocks +0.37 vs
0.87, passes -1.75 vs 5.2), so nothing moved since Phase 4 QA.

**Team balance:** BLUE 43/100. With a 5-pt SE this is within the 40-60% noise band (just inside 2 SE); Phase 4 QA had
45.5% over 200 games. Not flagged, but RED has now been a little ahead in three batches (42, 49, 43); see section 5.

## 3. Humantest, 6 runs (Hard, ANGLED)

| Run | Final | Length | `HUMANTEST` line |
|---|---|---|---|
| 1 | BLUE 18 - RED 21 | 7:59 | steals timed 14/16 random 2/34, blocks timed 2/5 early 0/8, in front 58% beaten 10 in 57, assist 3456 (2 pulling away), crossovers beat him 2/3, FTs good 0/0 early 1/1 |
| 2 | BLUE 21 - RED 13 | 7:03 | steals timed 9/12 random 7/22, blocks timed 0/2 early 0/4, in front 66% beaten 8 in 46, assist 2517 (1), crossovers 1/2, FTs 0/0 early 0/1 |
| 3 | BLUE 15 - RED 21 | 12:11 | steals timed 20/23 random 11/41, blocks timed 4/9 early 1/9, in front 55% beaten 10 in 86, assist 3966 (0), crossovers 0/1, FTs 0/0 early 0/0 |
| 4 | BLUE 14 - RED 22 | 6:10 | steals timed 11/12 random 1/19, blocks timed 1/8 early 0/9, in front 67% beaten 10 in 48, assist 2308 (0), crossovers 0/1, FTs 0/0 early 0/0 |
| 5 | BLUE 16 - RED 21 | 9:04 | steals timed 10/14 random 4/25, blocks timed 5/8 early 1/10, in front 39% beaten 13 in 68, assist 3287 (0), crossovers 0/0, FTs 1/1 early 1/1 |
| 6 | BLUE 16 - RED 21 | 7:02 | steals timed 8/13 random 5/24, blocks timed 1/4 early 1/6, in front 47% beaten 5 in 48, assist 2543 (14), crossovers 0/0, FTs 0/0 early 0/1 |

| Totals (6 runs) | This baseline | phase4.md ANGLED (9 runs) |
|---|---|---|
| Timed steals | 72/90 (80%) | 108/139 (78%) |
| Random steals | 30/165 (18%) | 54/296 (18%) |
| Timed blocks | 13/36 (36%) | 26/58 (45%) |
| Early-jump blocks | 3/46 (7%) | 18/69 (26%) |
| Guarding in front | 39-67% | 47-64% |
| Beaten / spells | 56/353 | 91/616 |
| Assist frames (mean per run) | 3013 | 3370 |
| CPU crossovers beat him | 3/7 | 6/14 |
| Shot-clock violations | 0 | 0 |

| Counter (stats JSON) | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 | Run 6 | Mean |
|---|---|---|---|---|---|---|---|
| shots / makes | 77 / 34 | 63 / 29 | 107 / 33 | 56 / 31 | 82 / 31 | 67 / 29 | 75.3 / 31.2 |
| human_steals / human_steal_pokes | 16 / 50 | 16 / 34 | 31 / 64 | 12 / 31 | 14 / 39 | 13 / 37 | 17.0 / 42.5 |
| human_blocks / human_block_jumps | 4 / 18 | 0 / 11 | 6 / 24 | 4 / 18 | 6 / 26 | 6 / 15 | 4.3 / 18.7 |
| human_crossovers / human_cross_beats | 32 / 3 | 33 / 4 | 53 / 8 | 19 / 2 | 43 / 8 | 22 / 2 | 33.7 / 4.5 |
| human_pump_fakes / human_pump_bites | 16 / 4 | 14 / 1 | 26 / 4 | 9 / 1 | 24 / 8 | 11 / 2 | 16.7 / 3.3 |
| human_dunks / human_layups | 15 / 4 | 20 / 3 | 22 / 7 | 10 / 2 | 17 / 4 | 17 / 3 | 16.8 / 3.8 |
| human_alleyoop_lobs / catches | 6 / 5 | 4 / 3 | 6 / 4 | 5 / 5 | 8 / 3 | 2 / 3 | 5.2 / 3.8 |
| human_fouled / human_ft_attempts | 2 / 1 | 1 / 1 | 1 / 0 | 0 / 0 | 2 / 2 | 2 / 1 | 1.3 / 0.8 |
| intercepts / shotclock / out_of_bounds | 7 / 0 / 3 | 1 / 0 / 1 | 10 / 0 / 1 | 2 / 0 / 1 | 3 / 0 / 1 | 1 / 0 / 2 | 4.0 / 0 / 1.5 |
| steals / blocks (all) | 17 / 9 | 21 / 1 | 38 / 7 | 13 / 6 | 18 / 8 | 16 / 7 | 20.5 / 6.3 |

BLUE (the scripted human) won 1 of 6. The humantest is not deterministic; timed blocks (36%) and early-jump blocks
(3/46) are lower than Phase 4's 9 runs, but on 36 and 46 tries this is inside the noise seen between the Phase 4
baseline (70%) and its control (41%). No counter dropped to 0 over the 6 runs.

## 4. Web build

`tools/build_web.sh` (no `--publish`): `build/web` 38 MB. **`index.pck` = 3,710,256 bytes (3.54 MiB)**, down from
4,070,544 at Phase 4 QA (the music was replaced by chiptune tracks in `a7c2472`); `index.wasm` 35,376,909
(unchanged). Under the 12 MB budget. (BOARD.md still says "4.07 MB now".) No fps run in this task.

## 5. How to compare (P5-16)

- **Board rule:** P5-16 runs 100 `--autoplay` games on the Quick Game path (rating 50, empty `Flow.match`), same
  flags as section 1. Each stat in section 2 must be within 2 SE. Use the combined SE: a difference of two 100-game
  means is real if it is more than **2 x sqrt(SE_base^2 + SE_new^2)**, about **2.8 x the SE column** (e.g. shots
  +-4.7, game length +-0.57 min, loser points +-0.91, FG% +-1.5 pts, steals per 60 shots +-0.65, blocks per 60 shots
  +-0.58, fouls +-0.55, OOB +-0.42, interceptions +-0.57, crossover beats +-1.0).
- With ~70 stats in the table, 3-4 will cross that line by chance in a 100-game batch. If one or two stats fail,
  run 100 more and judge the pooled 200 (as phase4.md did) before calling it drift. Per-team rows move together
  with their totals; judge the totals first.
- **Counts that are 0 here** (shot-clock violations, FT timeouts) and side switches (always 1): any change is a bug.
- **BLUE win share:** 43% at 100 games, SE 5 pts; anything from about 29% to 57% at 100 new games is noise. Judge
  balance on 200+ games (CLAUDE.md). Pooled with phase4.md's 200 this build line is at 134/300 = 44.7% (SE 2.9),
  just inside 2 SE of 50%. If P5-16 also lands under 45%, run 200 more and look at the first-ball side.
- **Humantest:** compare 6-run totals; flag a rate (timed steals, timed blocks, assist frames, crossovers beaten) only
  if it moves by more than about a third, or a counter drops to 0.
- **index.pck:** report bytes against 3,710,256 and the 12 MB budget.
