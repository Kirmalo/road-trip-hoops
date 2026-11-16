# P3-04 Game length check + BLUE/RED balance investigation

Builds tested: `trial-p3w1` at 4b222e6 (first to 21, side switch, difficulty plumbing) and current dev
`ccr-f5c087b2-3ojk5f` at f860504 (adds fouls/FTs, out of bounds, difficulty panel, P3-06 `spot_pos` mirror).
Godot 4.3 stable, headless, `--fixed-fps 60 --quit-after 120000 -- --autoplay` (Hard). 15 and 11 use `--target N`
(same as setting `TARGET_SCORE`/`SWITCH_AT` 15/8 and 11/6). 2,180 autoplay games and 4 humantest runs in total.
Import clean; no script errors in any run; every game reached FINAL; every game had exactly one side switch.

## 1. Game length (minutes = frames / 60, equal to `GAME LENGTH`)

| Build | Target | Games | Minutes mean (range) | Shots mean (range) | Winner - loser | Spread mean (range) | 2-pt share of points | Fouls |
|---|---|---|---|---|---|---|---|---|
| trial | 21 | 360 | 13.0 (8.4-19.6) | 96 (54-159) | 21.0 - 16.8 (loser 8-20) | 4.2 (1-13) | 10% | - |
| trial | 15 | 30 | 9.2 (4.9-14.5) | 68 (27-104) | 15.0 - 11.3 (6-14) | 3.7 (1-9) | 11% | - |
| trial | 11 | 30 | 6.3 (3.9-9.4) | 47 (30-63) | 11.1 - 7.2 (3-10) | 3.8 (1-8) | 14% | - |
| dev | 21 | 300 | 12.9 (8.7-17.3) | 90 (57-132) | 21.0 - 16.3 (8-20) | 4.7 (1-13) | 11% | 3.6 |
| dev | 15 | 20 | 8.9 (5.9-13.1) | 64 (43-95) | 15.1 - 10.7 (8-14) | 4.3 (1-8) | 11% | 2.6 |
| dev | 11 | 20 | 6.7 (4.5-9.3) | 47 (32-69) | 11.0 - 7.8 (2-10) | 3.2 (1-9) | 9% | 1.4 |

Shot-clock violations: 0 in every game. Interceptions: 4.7 / 4.8 per game to 21 (2.6 to 11). Winner never past
target + 1. Humantest: trial 21-20 (9:21), 16-21 (9:51); dev 21-17 (7:03), 13-21 (8:33), no errors.

**A game to 21 takes about 13 minutes** (range 8.5-19.5), well past the 8-minute line (Q2). To 15: about 9 minutes.
To 11: about 6.5 minutes. Matches the board estimate (12 min, ~90 shots).

Suggested CLAUDE.md ranges (P3-11 already wrote "75-120 shots, 10-15 min" for 21; data supports it):
- to 21: 65-125 shots, 9-17 min, loser 12-20
- to 15: 45-90 shots, 6-12 min, loser 8-14
- to 11: 35-60 shots, 4-9 min, loser 4-10

## 2. BLUE/RED bias

Standard error of a win share: 5% at 100 games, 3.5% at 200, 2.6% at 360. Point diff is BLUE minus RED per game.

| Build | Test (one change) | Games | BLUE wins | Point diff |
|---|---|---|---|---|
| trial | as is (BLUE first ball, BLUE right first, team 0 updates first) | 360 | 50.6% | +0.15 +-0.26 |
| trial | `FIRST_BALL_TEAM = 1` | 300 | 46.0% | -0.37 +-0.31 |
| trial | spawn/update order RED first (`for t in [1, 0]` in main `_ready`) | 300 | 49.7% | -0.18 +-0.29 |
| trial | start `sides_swapped = true` (RED right first) | 300 | 49.0% | -0.29 +-0.30 |
| trial | `spot_pos` y mirrored (`-inward(hoop) * s.y`) | 100 | 58.0% | +0.88 +-0.58 |
| dev | as is | 300 | 48.7% | -0.23 +-0.31 |
| dev | `FIRST_BALL_TEAM = 1` | 200 | 47.0% | -0.28 +-0.38 |
| dev | start `sides_swapped = true` | 200 | 57.0% | +0.39 +-0.36 |

BLUE wins per consecutive 40-game block of the unchanged builds: trial 22, 21, 26, 19, 18, 18, 20, 21, 17;
dev 23, 16, 22, 20, 20, 19, 17. Short batches swing a lot: 20-game batches at 15/11 on dev gave BLUE 70% and 25%.

Other per-team numbers (trial, 360 games): possessions 38.6 / 38.1 (the first-ball team gets ~0.5 more), shots per
half and per team level, right-hoop vs left-hoop points 19.0 / 18.9 (dev 18.8 / 18.6), steals, blocks, dunks,
crossovers, beats, turbo frames all level within noise.

Findings:
- **The 30/40 BLUE (75%) result does not reproduce.** 360 games on the same build give 50.6%; no 40-game block
  went above 26. The dev "RED 62%" (25/40) is also inside the normal spread (one block here was 16 BLUE / 24 RED);
  300 dev games give RED 51.3%. Neither build has a measurable team, hoop or update-order bias.
- **First ball**: worth about +0.5 possessions; its measured effect is +0.25 pts/game pooled (2-3% win share),
  under 2 standard errors. It is the only effect with a mechanism, and it always favours BLUE as configured.
- B1 (right hoop): gone. Right vs left hoop points are within 0.2 on both builds; the side switch plus the mirrored
  rows, inbound spot and (dev) `spot_pos` make the halves 180-degree-rotation symmetric. Starting-side tests moved
  the diff by 0.4-0.6 in opposite directions on the two builds: noise.
- HUMAN_TEAM code: everything human-only goes through `is_human()` (false in autoplay) or `not autoplay`;
  `Difficulty.value()` returns the Hard constant for both teams on Hard. Nothing team-0-specific runs in autoplay
  except `FIRST_BALL_TEAM`, the players' update order, and the `frames` counter.

## Bugs
None found in this pass. (Known: GAME POINT shows when a team is a 2 away, e.g. from 19, or at 0-1 with `--target 3`.)

## Suggested changes (not applied)
- No gameplay fix needed for balance.
- Test-only: in `rules.gd` `start_game()`, when `game.autoplay`, pick the first-ball team at random
  (`var t: int = game.rng.randi() % 2 if game.autoplay else FIRST_BALL_TEAM`) so balance runs don't carry the
  first-ball edge. Optional: alternate the player update order each frame in `main._physics_process`.
- Process: judge balance on 200+ games (+-3.5%); treat 40-game swings up to about 65/35 as noise.
- Q2 for the owner: 21 takes ~13 min; 15 ~9 min; 11 ~6.5 min.
