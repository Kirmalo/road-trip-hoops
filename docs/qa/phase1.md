# Phase 1 QA and balance pass (P1-09)

Build tested: commit `8f4b58e` (P1-01 to P1-08 merged, the P1-04 sound files are in `assets/sfx/`), then the same
build with the three tuning changes below. Godot 4.3-stable (Linux), headless, `--fixed-fps 60`.

Runs: 20 `--autoplay` + 4 `--humantest` before tuning; 19 `--autoplay` after the first tuning step; **80 `--autoplay` +
2 `--humantest` on the final tuning**. Games take about 4 seconds headless, so the bigger sample is there to settle team
balance and the dunk vs layup rates. Screenshots: the default `--shots` frames, plus a temporary local hook (not
committed) that saved frames 3 and 12 after made shots, the "ON FIRE!" moment, an on-fire player holding the ball and an
on-fire shot in flight, and printed the camera offset every 600 frames.

## Summary

| Check | Target | Before tuning (20 games) | After tuning (80 games) | Result |
|---|---|---|---|---|
| Script errors or warnings in headless logs | none | none | none | PASS |
| Shots per game | 45-70 | 55.2 (43-76) | 53.5 (43-71) | PASS |
| Points per team | ~15-30 | BLUE 18.4 (10-28), RED 18.9 (12-24) | BLUE 21.8 (10-32), RED 22.9 (10-34) | PASS |
| Overall FG% | (baseline 22-37%) | 33.7% | 41.7% | PASS |
| Interceptions per game | few | 3.5 (0-8) | 3.4 (0-9) | PASS |
| Shot clock violations | few | 0 in 20 games | 0 in 80 games (1 in a humantest) | PASS |
| Dunk FG% above layup FG% | dunks better | dunk 39.9%, layup 29.3% | dunk 46.0%, layup 38.8% | PASS |
| Contested layup vs contested 15 ft jumper | layup better | layup 29% < jumper ~36% | layup 39% > jumper ~36% | PASS after tuning |
| Dunks not more than half of shots | <= 50% | 42% | 41% | PASS |
| Jump shots (any shot that isn't a dunk or layup) | some per game | 0.9 per game (17 in 20 games) | 1.1 per game (86 in 80 games) | **FAIL** (needs logic, see R1) |
| Share of shots under 5 ft | baseline ~90% | 49% (the rest are mostly 5-9 ft layups) | 48% | info |
| Team balance | no clear bias | BLUE 10 - RED 10 | BLUE 34 - RED 46 (RED +1.1 pts/game) | PASS, keep watching (see below) |
| Turbo frames per CPU player | > 0 and < 40% | 7.6% both teams | 7.5% both teams | PASS (feel: owner) |
| `stamina_empty` in humantest | > 0 | 171-184 per game | 169-175 per game | PASS |
| Fire starts | > 0 in most games | 1.05 per game (16 of 20 games) | 1.7 per game (72 of 80 games) | PASS |
| FG% while on fire, summed over all games | <= ~65% | 41.2% (21/51) | 43.0% (145/337) | PASS |
| `sfx_crowd` = makes, `sfx_swish` = makes - dunk makes, `sfx_rim` = shots - makes - blocks | exact | exact in every game | exact in every game | PASS |
| `sfx_whistle` = shot clock violations + periods + 1 | exact | exact in every game | exact in every game | PASS |
| `popups` = makes + fire starts | exact | exact in every game | exact in every game | PASS |
| `shakes` >= blocks | yes | yes | yes | PASS (bug B1: rim blocks count twice) |
| Camera offset back to zero after shakes | (0, 0) | (0, 0) at every check over 9000 frames | not re-run (no fx change) | PASS |
| Net animation on a make | visible | visible: the net hangs lower and sways in the frames after a make | - | PASS |
| BLUE "+2" popup over the blue paint | readable | readable because of the dark outline, but low contrast | - | PASS, owner to judge |
| Fire ring and ball trail | visible | ring very clear; trail visible in flight but faint, hidden while held | - | PASS, owner to judge |
| Popup pop-in (1.5x) with nearest filtering | not jagged | clean in the frames captured | - | PASS |
| HUD, touch buttons at 1280x720 | readable, nothing covering play | HUD readable; buttons only cover the bottom-right corner | - | PASS |
| Sounds | real files that play | 8 `.ogg` files present; under xvfb they go through Godot's dummy audio driver (no sound card here) with no errors | - | NOT TESTED by ear |

## Tuning changes (all in `scripts/player.gd`, constants only)

| Constant | Old | New | Why |
|---|---|---|---|
| `CONTEST_MAKE_MULT` | 0.9 | 1.0 | 99% of rim attempts have a defender inside `CONTEST_FT`, and `main.shot_probability()` already multiplies by 0.55 for a defender inside 3 ft. The extra 0.9 counted the contest twice. Contests still matter through that 0.55 and the block chances. |
| `LAYUP_OPEN_PCT` | 0.65 | 0.75 | Contested layups went in 29% of the time, less often than a contested 15 ft jumper (about 36%). A layup should beat a mid-range jumper. |
| `DUNK_OPEN_PCT` | 0.85 | 0.92 | After the two changes above, dunks and layups were level (38.7% vs 39.9% over 19 games), because dunks also carry the higher block chance. This keeps the dunk as the reward for attacking at speed. `shot_probability()` caps at 92%, so this is as high as an open dunk can go. |

Effect, step by step:

| Build | Games | Points BLUE / RED | Shots | FG% | Dunk FG% | Layup FG% | Fire FG% |
|---|---|---|---|---|---|---|---|
| Before tuning | 20 | 18.4 / 18.9 | 55.2 | 33.7% | 39.9% | 29.3% | 41.2% |
| `CONTEST_MAKE_MULT` 1.0 + `LAYUP_OPEN_PCT` 0.75 | 19 (+1 cut off in a 3rd OT, see B2) | 20.5 / 21.5 | 53.2 | 39.5% | 38.7% | 39.9% | 40.0% |
| + `DUNK_OPEN_PCT` 0.92 (final) | 80 | 21.8 / 22.9 | 53.5 | 41.7% | 46.0% | 38.8% | 43.0% |

Points per team moved from the low part of the 15-30 target toward the middle. In the final 80 games, 12 of the 160
team scores were under 15 (lowest 10) and 5 were over 30 (highest 34).

Not tuned, on purpose:
- **Jump shots.** No top-of-script constant controls CPU jump-shot selection. The thresholds (`p > 0.40`,
  `open_ft > 4.0`, `open_ft > 6.0`, and the 2.5 ft on-ball gap in `defense_ai`) are literals inside `handler_ai` and
  `defense_ai`. See R1.
- **CPU turbo (7.5% of frames per player).** It shows on fast breaks and recoveries. Whether that's enough is a feel
  question for the owner. If it's too rare, `CPU_BREAK_FT` 20 -> 14 is the first knob to try.

## Team balance
Over all 119 finished autoplay games in this pass (all builds), BLUE won 52 and RED 67. The final build alone: BLUE 34 -
RED 46 over 80 games, but its two halves were 13-27 and then 21-19, so this is within chance (about p = 0.2 for 80
games). RED scored 1.1 points per game more. BLUE gets the opening possession in Q1, Q4 and OT, so if anything BLUE
should have the edge. Not a bug on this evidence; check it again after Phase 2 changes the AI.

13 of the 80 final games (16%) went to overtime, because nearly every basket is worth 2. The first-to-21 format in
Phase 3 removes overtime.

## Bugs

**B1 (minor, stats only): a blocked dunk or layup counts two shakes.**
- Steps: run `--autoplay`, compare `shakes` with `blocks + dunk_makes`.
- Expected: one shake per block or made dunk.
- Actual: `shakes` = `blocks + dunk_makes + rim_blocks`. `release_rim_shot()` calls `game.rim_shot_blocked()`, which
  shakes 6 px in `block_shot()`, then `player.gd` shakes 4 px again. Only the stronger shake shows (`fx.shake` never
  weakens a running one), so players won't notice. Fix: drop the `game.fx.shake(4.0, 0.2)` in `release_rim_shot()`.

**B2 (test harness): `--quit-after 40000` can cut off a game in its 3rd overtime.**
- Steps: run about 20 `--autoplay` games with the CLAUDE.md command.
- Expected: every run prints `FINAL`.
- Actual: 1 of 20 runs stopped at 24-24 after the 2nd overtime with no `FINAL` line (4 quarters plus 3 overtimes is
  about 40,000 frames). Fix: use `--quit-after 60000` in the CLAUDE.md Testing section. All 80 final runs used 60000
  and finished.

No crashes, no stuck players or balls, no script errors. The only errors in the xvfb logs are ALSA errors (the container
has no sound card, so Godot falls back to the dummy audio driver).

## Per-game tables

Columns: "Turbo B/R %" is turbo frames / (frames x 3) per team, the share of time an average player sprints.
"Contested" is rim attempts with a defender inside `CONTEST_FT`. "5-15 ft" includes the 5-9 ft layups. "SCV" is shot
clock violations. "Fire B/R" is fire starts per team.

### Before tuning (commit 8f4b58e), 20 autoplay games

| # | Final (B-R) | Shots | Makes | FG% | <5 ft | 5-15 ft | 15 ft+ | Dunks (made) | Layups (made) | Contested | Blocks | Steals | Int | SCV | Turbo B/R % | Fire B/R |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 18-16 | 58 | 17 | 29 | 32 | 18 | 1 | 30 (11) | 27 (6) | 57 | 7 | 10 | 4 | 0 | 7.8/7.7 | 0/0 |
| 2 | 28-18 | 58 | 23 | 40 | 27 | 29 | 0 | 19 (8) | 40 (15) | 59 | 2 | 9 | 4 | 0 | 7.0/7.1 | 1/1 |
| 3 | 24-20 | 61 | 22 | 36 | 32 | 23 | 1 | 23 (12) | 37 (10) | 60 | 5 | 11 | 4 | 0 | 7.7/8.2 | 1/0 |
| 4 | 18-20 | 43 | 19 | 44 | 19 | 22 | 0 | 16 (9) | 25 (10) | 41 | 2 | 8 | 7 | 0 | 7.1/7.1 | 1/1 |
| 5 | 10-18 | 56 | 14 | 25 | 32 | 18 | 0 | 36 (11) | 21 (3) | 57 | 6 | 7 | 6 | 0 | 6.2/6.9 | 0/0 |
| 6 | 12-20 | 55 | 16 | 29 | 30 | 20 | 2 | 22 (8) | 31 (8) | 51 | 3 | 10 | 3 | 0 | 8.1/7.4 | 1/0 |
| 7 | 22-14 | 58 | 18 | 31 | 33 | 21 | 0 | 30 (12) | 29 (6) | 56 | 4 | 5 | 2 | 0 | 7.3/7.4 | 1/0 |
| 8 | 20-14 | 53 | 17 | 32 | 26 | 19 | 2 | 21 (11) | 30 (5) | 51 | 6 | 7 | 2 | 0 | 6.7/7.0 | 1/0 |
| 9 | 12-24 | 49 | 18 | 37 | 22 | 22 | 0 | 23 (8) | 23 (10) | 46 | 6 | 8 | 8 | 0 | 7.8/7.6 | 0/1 |
| 10 | 22-18 | 47 | 20 | 43 | 30 | 14 | 0 | 23 (12) | 24 (8) | 47 | 3 | 6 | 1 | 0 | 7.0/6.8 | 1/1 |
| 11 | 26-18 | 47 | 22 | 47 | 21 | 21 | 2 | 17 (7) | 28 (14) | 44 | 3 | 11 | 0 | 0 | 6.9/8.0 | 2/0 |
| 12 | 16-20 | 66 | 18 | 27 | 27 | 23 | 1 | 28 (8) | 37 (10) | 64 | 16 | 6 | 1 | 0 | 8.7/8.0 | 1/0 |
| 13 | 20-24 | 55 | 22 | 40 | 22 | 27 | 0 | 20 (11) | 34 (10) | 53 | 6 | 10 | 2 | 0 | 8.1/8.3 | 0/2 |
| 14 | 10-24 | 56 | 17 | 30 | 31 | 19 | 1 | 28 (10) | 27 (7) | 55 | 5 | 6 | 4 | 0 | 6.8/7.0 | 0/1 |
| 15 | 12-18 | 55 | 15 | 27 | 26 | 22 | 2 | 20 (5) | 33 (10) | 52 | 5 | 7 | 4 | 0 | 7.9/7.0 | 0/1 |
| 16 | 21-16 | 53 | 18 | 34 | 27 | 23 | 2 | 22 (10) | 31 (7) | 53 | 1 | 9 | 4 | 0 | 8.4/7.9 | 1/0 |
| 17 | 24-18 | 52 | 21 | 40 | 19 | 25 | 1 | 20 (9) | 31 (12) | 50 | 7 | 9 | 4 | 0 | 7.8/7.4 | 1/0 |
| 18 | 12-24 | 57 | 18 | 32 | 23 | 29 | 2 | 17 (6) | 38 (12) | 55 | 3 | 6 | 0 | 0 | 8.3/8.6 | 0/1 |
| 19 | 18-22 | 76 | 20 | 26 | 38 | 32 | 0 | 37 (12) | 39 (8) | 75 | 6 | 3 | 2 | 0 | 7.7/8.1 | 0/0 |
| 20 | 22-12 | 49 | 17 | 35 | 23 | 22 | 1 | 17 (7) | 33 (10) | 50 | 3 | 6 | 8 | 0 | 8.3/7.8 | 0/0 |

Humantest before tuning. The scripted human shoots every 97 frames from anywhere and pokes for steals, so 15 ft+ shots
and steals are high by design:

| # | Final (B-R) | Shots | Makes | FG% | <5 ft | 5-15 ft | 15 ft+ | Dunks (made) | Layups (made) | Contested | Blocks | Steals | Int | SCV | Turbo B/R % | Fire B/R |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 15-20 | 66 | 17 | 26 | 17 | 15 | 34 | 13 (7) | 14 (4) | 23 | 0 | 34 | 4 | 0 | 26.2/17.5 | 0/1 |
| 2 | 10-26 | 74 | 18 | 24 | 17 | 18 | 36 | 17 (9) | 15 (3) | 28 | 6 | 37 | 3 | 0 | 26.1/18.0 | 0/2 |
| 3 | 15-20 | 74 | 16 | 22 | 19 | 14 | 38 | 21 (7) | 10 (5) | 23 | 10 | 32 | 3 | 0 | 26.3/16.6 | 0/0 |
| 4 | 18-22 | 76 | 19 | 25 | 18 | 21 | 33 | 20 (9) | 17 (5) | 34 | 9 | 28 | 2 | 0 | 26.2/16.8 | 0/0 |

### After tuning (final), 80 autoplay games; the first 40 are shown

| # | Final (B-R) | Shots | Makes | FG% | <5 ft | 5-15 ft | 15 ft+ | Dunks (made) | Layups (made) | Contested | Blocks | Steals | Int | SCV | Turbo B/R % | Fire B/R |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 26-28 | 64 | 27 | 42 | 36 | 23 | 0 | 30 (13) | 36 (14) | 65 | 5 | 18 | 1 | 0 | 7.0/6.7 | 0/1 |
| 2 | 12-34 | 52 | 23 | 44 | 24 | 20 | 3 | 20 (11) | 28 (11) | 48 | 5 | 8 | 8 | 0 | 9.4/9.2 | 1/1 |
| 3 | 26-24 | 46 | 25 | 54 | 16 | 26 | 1 | 13 (6) | 32 (18) | 45 | 3 | 6 | 4 | 0 | 7.2/6.4 | 1/1 |
| 4 | 20-22 | 53 | 21 | 40 | 24 | 22 | 3 | 24 (8) | 25 (12) | 48 | 4 | 5 | 3 | 0 | 6.7/6.4 | 1/2 |
| 5 | 30-14 | 52 | 22 | 42 | 29 | 19 | 1 | 23 (12) | 28 (8) | 51 | 3 | 4 | 3 | 0 | 5.5/5.3 | 2/1 |
| 6 | 12-18 | 55 | 15 | 27 | 28 | 23 | 0 | 17 (7) | 38 (8) | 55 | 4 | 7 | 2 | 0 | 6.3/7.1 | 0/0 |
| 7 | 32-34 | 71 | 33 | 46 | 34 | 30 | 3 | 32 (15) | 36 (17) | 68 | 4 | 8 | 7 | 0 | 7.4/7.2 | 2/1 |
| 8 | 20-26 | 65 | 23 | 35 | 34 | 24 | 1 | 30 (11) | 34 (12) | 64 | 6 | 7 | 0 | 0 | 7.0/6.8 | 0/1 |
| 9 | 16-22 | 50 | 19 | 38 | 20 | 25 | 0 | 19 (8) | 31 (11) | 49 | 5 | 11 | 1 | 0 | 7.7/7.6 | 0/1 |
| 10 | 12-30 | 54 | 21 | 39 | 24 | 25 | 0 | 18 (6) | 36 (15) | 51 | 5 | 6 | 4 | 0 | 7.9/7.8 | 0/2 |
| 11 | 24-18 | 52 | 21 | 40 | 23 | 26 | 0 | 18 (7) | 33 (14) | 50 | 3 | 10 | 6 | 0 | 9.3/8.8 | 1/0 |
| 12 | 16-28 | 53 | 22 | 42 | 30 | 20 | 1 | 26 (13) | 25 (9) | 50 | 3 | 11 | 6 | 0 | 8.6/8.3 | 0/1 |
| 13 | 18-20 | 47 | 19 | 40 | 23 | 20 | 2 | 23 (10) | 22 (9) | 44 | 2 | 11 | 4 | 0 | 7.4/6.7 | 0/1 |
| 14 | 22-24 | 70 | 23 | 33 | 36 | 29 | 1 | 30 (11) | 39 (11) | 69 | 4 | 12 | 3 | 0 | 6.8/6.7 | 1/0 |
| 15 | 30-18 | 53 | 24 | 45 | 22 | 27 | 0 | 18 (9) | 32 (13) | 48 | 4 | 6 | 4 | 0 | 7.9/8.3 | 2/0 |
| 16 | 16-18 | 51 | 17 | 33 | 26 | 23 | 1 | 21 (9) | 30 (8) | 49 | 1 | 8 | 4 | 0 | 7.2/7.6 | 0/0 |
| 17 | 24-18 | 48 | 21 | 44 | 20 | 22 | 0 | 20 (9) | 29 (12) | 49 | 6 | 11 | 4 | 0 | 9.7/9.5 | 2/0 |
| 18 | 16-18 | 56 | 17 | 30 | 26 | 24 | 1 | 26 (8) | 29 (9) | 54 | 5 | 7 | 4 | 0 | 8.9/8.7 | 0/0 |
| 19 | 16-24 | 52 | 20 | 38 | 28 | 20 | 0 | 18 (7) | 35 (13) | 53 | 4 | 5 | 4 | 0 | 5.9/5.8 | 1/1 |
| 20 | 24-26 | 62 | 25 | 40 | 26 | 29 | 2 | 23 (8) | 38 (17) | 60 | 5 | 6 | 4 | 0 | 8.5/8.4 | 0/1 |
| 21 | 30-24 | 59 | 27 | 46 | 23 | 29 | 3 | 25 (14) | 33 (13) | 58 | 4 | 3 | 4 | 0 | 6.6/6.7 | 1/0 |
| 22 | 16-34 | 49 | 25 | 51 | 27 | 20 | 0 | 24 (13) | 26 (12) | 50 | 2 | 8 | 4 | 0 | 7.2/7.1 | 0/1 |
| 23 | 24-26 | 56 | 25 | 45 | 31 | 22 | 1 | 26 (14) | 29 (11) | 55 | 2 | 3 | 4 | 0 | 7.4/6.8 | 0/1 |
| 24 | 14-22 | 55 | 18 | 33 | 27 | 20 | 2 | 28 (8) | 25 (9) | 52 | 6 | 9 | 3 | 0 | 7.5/7.1 | 0/1 |
| 25 | 28-26 | 58 | 27 | 47 | 29 | 23 | 1 | 22 (11) | 36 (15) | 58 | 5 | 11 | 5 | 0 | 7.7/7.8 | 1/0 |
| 26 | 26-18 | 52 | 22 | 42 | 25 | 22 | 2 | 16 (8) | 32 (12) | 48 | 3 | 8 | 3 | 0 | 6.5/6.2 | 1/0 |
| 27 | 20-33 | 50 | 26 | 52 | 28 | 16 | 1 | 21 (14) | 28 (11) | 49 | 5 | 8 | 3 | 0 | 7.9/7.9 | 1/3 |
| 28 | 30-26 | 50 | 28 | 56 | 21 | 27 | 0 | 17 (9) | 32 (19) | 49 | 2 | 10 | 2 | 0 | 6.3/6.7 | 1/3 |
| 29 | 20-22 | 53 | 21 | 40 | 28 | 18 | 2 | 27 (12) | 25 (9) | 51 | 6 | 8 | 4 | 0 | 7.5/8.2 | 0/0 |
| 30 | 24-28 | 51 | 26 | 51 | 22 | 22 | 1 | 23 (16) | 28 (9) | 49 | 6 | 9 | 1 | 0 | 6.6/7.1 | 1/1 |
| 31 | 22-30 | 62 | 26 | 42 | 33 | 21 | 3 | 29 (15) | 30 (11) | 58 | 5 | 5 | 1 | 0 | 7.0/6.7 | 0/1 |
| 32 | 22-26 | 69 | 24 | 35 | 42 | 21 | 0 | 38 (15) | 30 (9) | 68 | 6 | 4 | 3 | 0 | 7.3/7.3 | 1/0 |
| 33 | 24-18 | 48 | 21 | 44 | 17 | 28 | 1 | 15 (8) | 31 (13) | 45 | 2 | 8 | 2 | 0 | 9.0/8.3 | 1/1 |
| 34 | 18-20 | 46 | 19 | 41 | 13 | 25 | 1 | 9 (3) | 36 (15) | 44 | 7 | 5 | 5 | 0 | 7.1/7.4 | 1/1 |
| 35 | 26-30 | 49 | 28 | 57 | 28 | 19 | 0 | 23 (14) | 24 (13) | 45 | 2 | 8 | 3 | 0 | 8.0/7.8 | 1/1 |
| 36 | 24-18 | 54 | 21 | 39 | 24 | 25 | 0 | 24 (9) | 30 (12) | 54 | 5 | 8 | 3 | 0 | 7.2/7.2 | 2/1 |
| 37 | 22-24 | 54 | 23 | 43 | 25 | 24 | 1 | 21 (11) | 31 (11) | 52 | 4 | 9 | 4 | 0 | 6.7/6.4 | 1/1 |
| 38 | 21-28 | 51 | 24 | 47 | 22 | 22 | 2 | 18 (7) | 30 (15) | 48 | 5 | 6 | 4 | 0 | 8.7/8.1 | 1/1 |
| 39 | 24-20 | 46 | 22 | 48 | 23 | 18 | 0 | 18 (10) | 30 (12) | 48 | 5 | 6 | 7 | 0 | 8.3/8.0 | 1/1 |
| 40 | 26-18 | 49 | 22 | 45 | 20 | 25 | 1 | 16 (10) | 31 (12) | 46 | 3 | 10 | 1 | 0 | 8.4/8.0 | 2/0 |

Humantest after tuning (human dunks 10 and 6, human layups 3 and 1):

| # | Final (B-R) | Shots | Makes | FG% | <5 ft | 5-15 ft | 15 ft+ | Dunks (made) | Layups (made) | Contested | Blocks | Steals | Int | SCV | Turbo B/R % | Fire B/R |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 21-20 | 66 | 20 | 30 | 26 | 10 | 28 | 26 (14) | 7 (1) | 28 | 2 | 30 | 0 | 1 | 26.6/15.0 | 0/0 |
| 2 | 18-27 | 73 | 21 | 29 | 18 | 13 | 40 | 20 (10) | 8 (4) | 20 | 4 | 40 | 4 | 0 | 26.9/19.2 | 0/1 |

### Final build totals (80 autoplay games)

| Stat | Mean | Range |
|---|---|---|
| Final score | BLUE 21.8, RED 22.9 | 10-34 |
| Shots / makes | 53.5 / 22.3 | 43-71 / 15-33 |
| Dunks (made) | 21.8 (10.0) | 9-38 (3-17) |
| Layups (made) | 30.7 (11.9) | 21-41 (7-19) |
| Rim attempts blocked | 4.4 | 1-10 |
| Steals | 7.8 | 3-18 |
| Interceptions | 3.4 | 0-9 |
| Passes | 86.7 | 67-110 |
| Fire starts BLUE / RED | 0.8 / 0.9 | 0-3 |
| Fire shots / makes | 4.2 / 1.8 | 0-12 / 0-7 |
| Shot clock violations | 0 | 0 |

## Recommended follow-up tasks

- **R1 (Phase 2, gameplay): CPU jump-shot selection.** The CPU takes about 1 jump shot per game; 98% of shots are
  dunks or layups. Cause: the defender plays 2.5 ft off the handler, so `open_ft` is almost never over 4 ft, and the
  `p > 0.40` check fails for any contested jumper (a 15 ft jumper with a defender 3-6 ft away is about 36%). Move the
  `handler_ai` thresholds into named constants and add a pull-up rule, e.g. a `CPU_PULLUP_CHANCE` from 12-22 ft when
  the defender is 3-6 ft off or sagging, plus a small chance from three when open. Goal: about 8-15 jumpers per game
  and a few made 3s, with scores still 15-30. This matters more in Phase 3, where the arc shot becomes the 2-pointer.
- **R2 (gameplay, with Phase 2 defense): make "contested" mean something.** 99% of rim attempts count as contested
  (`CONTEST_FT` 4 ft and a 2.5 ft on-ball gap). Once skill-based blocks and close guarding land, retune `CONTEST_FT`
  (try 3.0) so beating your man gives a clearly better look.
- **R3 (small): stamina bar size.** It's 44 x 7 px now (about 8 px on screen). On a tablet, 10 px tall and about 52 px
  wide would read better. The sizes are literals in `player._draw()`, so make them constants.
- **R4 (small): fire trail visibility.** The trail shows in flight but is faint, and while the player holds the ball
  it is hidden under the flame ring. If the owner wants it stronger, try `fx.TRAIL_RADIUS` 6 -> 8 and `TRAIL_LENGTH`
  14 -> 18.
- **R5 (small): BLUE popup contrast.** The light blue "+2" over the blue paint relies on its outline. If the owner finds
  it hard to read, use a lighter blue for the popup (e.g. `Color(0.7, 0.88, 1.0)`) or a thicker outline.
- **R6:** fix B1 and B2 (one line each).

## For the owner to judge on the tablet
1. **Turbo:** push the stick to the edge. Is 1.35x speed noticeable, is 2.5 s of sprint about right, and is the refill
   (about 4 s from empty after a 0.5 s pause) too slow? Does the CPU sprint often enough to look like it's trying?
2. **Stamina bar:** can you read it at a glance under your player (44 x 7 px now)? Should stamina refill between
   quarters? Right now it doesn't.
3. **Dunks and layups:** dunks now go in about 46% and layups 39% of the time, nearly always with a defender close. Do
   dunks feel powerful (SLAM! popup, shake, sound)? Is it clear when you'll dunk and when you'll lay it up?
4. **Sounds:** listen to all of them: swish, rim, bounce, crowd, whistle, dunk, block, fire. Swish and bounce are
   stand-ins. The **dribble sound** plays for your handler on every other bounce at -18 dB: keep it, make it quieter,
   or drop it?
5. **On fire:** about 1.7 fire streaks per game, usually a few shots long (4 fire shots per game, 43% made). Long
   enough? Are the flame ring and the trail easy to see?
6. **Popups:** is the blue "+2" readable over the blue paint, and does the pop-in look clean?
7. **Jump shots:** the CPU almost never shoots from outside. Does that make games feel samey? (R1 would fix it.)
