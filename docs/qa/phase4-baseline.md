# P4-00 Gameplay baseline before the view change

Build tested: dev at `a14a5ee` ("Plan Phase 4 tasks; archive the Phase 3 board"), branch `qa-p4-00`, before any
Phase 4 code. Godot 4.3 stable (Linux), headless. Import is clean. 100/100 `--autoplay` games and 3/3 `--humantest`
runs reached `FINAL`; no `ERROR` or script error line in any output.

P4-12 repeats this on the final build (FLAT and ANGLED) and compares with section 5.

## 1. Commands

```
godot --headless --path . --import
# 100 autoplay games, Hard (the default for --autoplay), 8 in parallel; about 4 minutes on 4 cores
mkdir -p runs
seq 1 100 | xargs -P 8 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay > runs/a{}.txt 2>&1"
# 3 humantests
for i in 1 2 3; do godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --humantest > runs/h$i.txt 2>&1; done
```

Per game, the numbers come from the `FINAL`, `GAME LENGTH`, `FOULS ... | FREE THROWS ...` lines and the stats JSON.
Derived stats:
- FG% = `makes / shots`. 2s made = `points2_t0 + points2_t1`; 2s share = 2 x 2s made / total points.
- Steals and blocks per 60 shots = 60 x `steals` (or `blocks`) / `shots`.
- Crossovers = `crossovers_t0 + _t1`; beats = `cross_beats_t0 + _t1`. Pump fakes = `pump_fakes_t0 + _t1`; bites =
  `cpu_fake_bites`. Lobs = `alleyoops_t0 + _t1`; alley-oop makes = `alleyoop_makes`.
- Interceptions = `intercepts`; shot-clock violations = `shotclock` (the key is absent when 0); OOB = `out_of_bounds`.
- Pooled rates (FG%, FT%, beat %, bite %) = sum of numerators / sum of denominators over all 100 games.

## 2. Autoplay, 100 games, Hard vs Hard (first ball random)

SD = standard deviation per game; SE = SD / 10 (standard error of the 100-game mean).

| Stat | Mean | SD | SE | Min | Max |
|---|---|---|---|---|---|
| BLUE points | 18.46 | 3.47 | 0.35 | 9 | 22 |
| RED points | 18.50 | 3.30 | 0.33 | 9 | 22 |
| Winner points | 21.09 | 0.29 | 0.03 | 21 | 22 |
| Loser points | 15.87 | 3.01 | 0.30 | 9 | 20 |
| Point diff (BLUE - RED) | -0.04 | 6.06 | 0.61 | -12 | +12 |
| Game length, minutes (`GAME LENGTH`) | 11.31 | 1.81 | 0.18 | 7.0 | 16.0 |
| Dead-ball seconds | 36.4 | 4.5 | 0.45 | 26 | 47 |
| Possessions (both teams) | 69.1 | 11.6 | 1.16 | 44 | 97 |
| Passes | 106.4 | 21.4 | 2.14 | 64 | 174 |
| Shots | 90.36 | 16.17 | 1.62 | 54 | 136 |
| Makes | 30.85 | 3.43 | 0.34 | 22 | 38 |
| FG% (per game) | 34.9 | 5.8 | 0.58 | 24.8 | 53.4 |
| Dunks (tries) | 27.2 | 7.2 | 0.72 | 13 | 52 |
| Layups (tries) | 26.0 | 6.5 | 0.65 | 10 | 43 |
| 2s made | 4.45 | 1.81 | 0.18 | 0 | 10 |
| 2s share of points, % | 24.1 | 9.6 | 0.96 | 0 | 48.8 |
| Fouls | 3.79 | 2.13 | 0.21 | 0 | 9 |
| Fouls on BLUE / RED | 1.83 / 1.96 | 1.47 / 1.38 | 0.15 / 0.14 | 0 / 0 | 6 / 7 |
| Fouls: shooting | 2.32 | 1.63 | 0.16 | 0 | 8 |
| Fouls: reach | 1.47 | 1.35 | 0.14 | 0 | 7 |
| And-ones | 0.95 | 1.02 | 0.10 | 0 | 4 |
| Free throws tried | 2.30 | 1.62 | 0.16 | 0 | 8 |
| Free throws made | 1.66 | 1.37 | 0.14 | 0 | 6 |
| FT timeouts | 0 | 0 | 0 | 0 | 0 |
| Out of bounds | 2.10 | 1.51 | 0.15 | 0 | 7 |
| OOB baseline / sideline | 1.59 / 0.51 | 1.30 / 0.73 | 0.13 / 0.07 | 0 / 0 | 7 / 3 |
| Steals | 10.10 | 4.04 | 0.40 | 2 | 21 |
| Steals BLUE / RED | 4.92 / 5.18 | 2.64 / 2.42 | 0.26 / 0.24 | 0 / 0 | 17 / 13 |
| Steals per 60 shots | 6.71 | 2.45 | 0.24 | 1.4 | 14.5 |
| Blocks | 10.27 | 3.54 | 0.35 | 4 | 19 |
| Blocks BLUE / RED | 4.84 / 5.43 | 2.61 / 2.45 | 0.26 / 0.25 | 0 / 0 | 11 / 12 |
| Blocks per 60 shots | 6.75 | 1.73 | 0.17 | 3.1 | 10.4 |
| Crossovers | 26.5 | 6.7 | 0.67 | 11 | 46 |
| Crossover beats | 10.79 | 3.43 | 0.34 | 4 | 22 |
| Pump fakes | 11.67 | 4.13 | 0.41 | 3 | 21 |
| Fake bites | 4.71 | 2.42 | 0.24 | 0 | 11 |
| Lobs | 3.71 | 1.84 | 0.18 | 0 | 9 |
| Alley-oop makes | 1.39 | 1.14 | 0.11 | 0 | 5 |
| Interceptions | 3.95 | 2.14 | 0.21 | 0 | 12 |
| Shot-clock violations | 0 | 0 | 0 | 0 | 0 |
| Side switches | 1.00 | 0 | 0 | 1 | 1 |
| Lead changes | 2.19 | 1.92 | 0.19 | 0 | 9 |

Pooled rates over the 100 games:

| Rate | Value | Approx. SE |
|---|---|---|
| FG% (3085 / 9036) | 34.1% | 0.6 pts (game-to-game) |
| FT% (166 / 230) | 72.2% | 3.0 pts |
| Crossover beat % (1079 / 2651) | 40.7% | 1.3 pts |
| Fake bite % (471 / 1167) | 40.4% | 1.8 pts |
| Steals / blocks / lobs / interceptions per 60 shots | 6.71 / 6.82 / 2.46 / 2.62 | - |
| **BLUE wins** | **53 / 100 = 53%** | 5.0 pts |

Other checks: winner scored 21 in 91 games and 22 (a 2 from 20) in 9; the loser had 12-20 in 90/100. Every game had
exactly one side switch, no shot-clock violations, no FT timeouts. All within the Phase 3 targets and close to the
Phase 3 final numbers (docs/qa/phase3.md).

## 3. Humantest, 3 runs (Hard)

The humantest is not deterministic (the CPU's rolls differ), so runs vary a lot; compare totals, not single runs.

| Run | Final | Length | Fouls (B/R) | FTs | `HUMANTEST` line |
|---|---|---|---|---|---|
| 1 | BLUE 21 - RED 18 | 10:11 | 1 / 3 | 1/2 | steals timed 17/20 random 11/33, blocks timed 4/6 early 1/10, in front 61% beaten 10 in 77 spells, assist 3812 frames (0 pulling away), crossovers beat him 3/4, FTs good 1/1 early 0/1 |
| 2 | BLUE 21 - RED 18 | 9:42 | 5 / 0 | 2/2 | steals timed 14/16 random 11/40, blocks timed 6/8 early 2/10, in front 62% beaten 17 in 82 spells, assist 4121 frames (1 pulling away), crossovers beat him 3/6, FTs good 0/0 early 0/0 |
| 3 | BLUE 9 - RED 21 | 7:03 | 1 / 2 | 1/3 | steals timed 10/14 random 4/30, blocks timed 4/6 early 0/8, in front 62% beaten 6 in 55 spells, assist 3274 frames (0 pulling away), crossovers beat him 0/2, FTs good 1/1 early 0/1 |

Totals over 3 runs: timed steals 41/50 (82%), random steals 26/103 (25%); timed blocks 14/20 (70%), early-jump
blocks 3/28 (11%); guarding in front 61-62%, beaten 33 in 214 spells; crossovers beat the human 6/12.

| Counter (stats JSON) | Run 1 | Run 2 | Run 3 | Mean |
|---|---|---|---|---|
| shots / makes | 100 / 36 | 91 / 35 | 66 / 24 | 85.7 / 31.7 |
| human_steals / human_steal_pokes | 28 / 53 | 25 / 56 | 14 / 44 | 22.3 / 51.0 |
| human_blocks / human_block_jumps | 8 / 24 | 10 / 25 | 4 / 22 | 7.3 / 23.7 |
| human_crossovers / human_cross_beats | 49 / 11 | 37 / 6 | 27 / 5 | 37.7 / 7.3 |
| human_cross_faced / human_cross_beaten (assisted) | 4 / 3 (3) | 6 / 3 (3) | 2 / 0 (0) | 4.0 / 2.0 |
| human_assist_frames | 3812 | 4121 | 3274 | 3736 |
| human_pump_fakes / human_pump_bites | 24 / 6 | 18 / 2 | 14 / 4 | 18.7 / 4.0 |
| human_dunks / human_layups | 24 / 6 | 23 / 0 | 15 / 1 | 20.7 / 2.3 |
| human_alleyoop_lobs / catches | 7 / 5 | 8 / 6 | 3 / 4 | 6.0 / 5.0 |
| human_calls / answered | 34 / 6 | 40 / 6 | 21 / 4 | 31.7 / 5.3 |
| human_shield_pokes | 13 | 11 | 10 | 11.3 |
| human_fouled / human_ft_attempts / makes | 3 / 2 / 1 | 0 / 0 / 0 | 2 / 2 / 1 | 1.7 / 1.3 / 0.7 |
| intercepts / shotclock / out_of_bounds | 6 / 0 / 4 | 9 / 0 / 1 | 6 / 0 / 1 | 7.0 / 0 / 2.0 |
| steals / blocks (all) | 32 / 13 | 25 / 13 | 19 / 9 | 25.3 / 11.7 |

## 4. Web build

`tools/build_web.sh` (no `--publish`): `build/web` 35 MB; **`index.pck` = 273,216 bytes**, `index.wasm` 35,376,909.

FPS in Chromium (Playwright's bundled Chromium 1243, headless, software WebGL via SwiftShader, viewport 1280x800,
`hasTouch` + `isMobile`, served with `python3 -m http.server`): count `requestAnimationFrame` callbacks over 5 s.
Launch panel 15.9-19.8 fps; in game (tap NORMAL at 640,490, then three 5 s samples) **19.3 / 21.0 / 19.8 fps** (an
earlier run that stayed on the panel: 15.8-18.0). This is a CPU-rendered number for comparing builds on this machine
only, not a tablet frame rate. Sampler used:

```js
const fps = await page.evaluate(ms => new Promise(r => { let n = 0; const t0 = performance.now();
  const f = () => { n++; if (performance.now() - t0 < ms) requestAnimationFrame(f);
                    else r(n * 1000 / (performance.now() - t0)); }; requestAnimationFrame(f); }), 5000);
```
Launch args: `--use-angle=swiftshader --enable-unsafe-swiftshader --ignore-gpu-blocklist`; wait 12 s after `goto`.
Once P4-01 adds `--fps`, also read the in-game `FPS n` line.

## 5. How to compare (P4-12, P4-01)

- **Means of per-game stats:** with 100 new games, the difference of two means has SE = sqrt(SE_a^2 + SE_b^2), about
  1.41 x the SE above. A difference is **real if it is more than 2 x that**, about **2.8 x the SE column**.
  Examples of the threshold at 100 vs 100 games: shots +-4.6, game length +-0.51 min, loser points +-0.85,
  FG% +-1.6 pts, steals per 60 shots +-0.68, blocks per 60 shots +-0.49, fouls +-0.60, OOB +-0.43, lobs +-0.51,
  interceptions +-0.60, crossover beats +-0.96, fake bites +-0.68 per game.
  The board's shorter rule "each stat within 2 SE" uses the baseline SE alone and so is stricter (about 1 in 20 stats
  will fail it by chance with ~40 stats); if one stat fails it, re-run 100 more games before calling it drift.
- **With 20 games** (P4-01 check): SE_new = SD / sqrt(20) (e.g. shots 3.6, minutes 0.40, steals per 60 shots 0.55);
  threshold = 2 x sqrt(SE_new^2 + SE_base^2).
  Shots must stay within about +-8, game length within +-0.9 min.
- **BLUE win share:** SE is 5 pts at 100 games, so anything from about 39% to 67% (within 2 x 7 pts of 53%)
  is noise. Judge balance on 200+ games (CLAUDE.md).
- **Counts that are 0 here** (shot-clock violations, FT timeouts) and side switches (always 1): any change at all is a
  bug to look at, not noise.
- **Humantest:** 3 runs are too few for fine comparisons; only flag a change if the 3-run total of a rate (timed steals,
  timed blocks, assist frames, crossovers beaten) moves by more than about a third, or a counter drops to 0.
- Autoplay doesn't touch the stick or the camera, so a real drift in autoplay means a drawing task wrote to sim state.
