# P8-25 Phase 8 QA: the trip ramp retune

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `2eeb47c` (P8-14b, the one-boss limit) for the batches. After a
worker restart the branch moved to `2099944` (P8-B1..B8 UI fixes). I diffed it: the only script changes outside the UI
are a 1.0.0 save-load rule in `trip.gd` and the `--backtest` steps in `main.gd`. Neither touches the simulation, the
ratings or the roster sims, so the batches stay valid. `--triptest-data` and `--trip-test` ran on `2099944` plus this
change. Godot 4.3 stable (Linux), headless, `--fixed-fps 60`, every game played to the city's own target.

**Setup:** isolated copies of the project, each with its own `config/name` (so each has its own `user://`). One copy
per tuning: `base` (as merged), `c1` (the new STAGE_AVG) and `c1L12` (c1 plus LEGEND_BONUS 12). At most 3 Godot
processes ran at once, and at most 2 after the restart. The machine was shared with other agents' jobs for the first
hours.

**Import:** clean. **Games:** 1,420 `--autoplay` city games: 640 before, 708 after (Normal, Hard, Easy and LEGEND +6)
and 72 with LEGEND +12. Every one reached `FINAL`. There were no `SCRIPT ERROR` or `ERROR` lines, 0 shot-clock
violations, and exactly one side switch in every game. No game came near `--quit-after`.

## Headline

- **New values:** `STAGE_AVG` = 40 / 46 / 52 / 58 / 63 / 68 / 73 / 78 (the progression plan's starting point).
  `LEGEND_BONUS` 6 -> **12**. `BOSS_CAP` stays **95**.
- **Lower bound** (`--expected-roster`, Normal): RED wins **41%** pooled over 160 games (40% before). Phase 6 had
  about 42%. Boss games: **35% in stages 1-4 and 46% in stages 5-8**, against 36% and 60% in Phase 6. With the old
  values the late boss games had fallen to 33% (17% in Seattle), so the new values bring back the late rise, though
  not all of it.
- **Upper bound** (`--best-roster`, Hard): RED wins **56%** (boss games 61%). The 20%+ target passes by a wide margin.
- **Levels** (Memphis, Denver and New York boss games, both rosters, 72 games per level): Easy 25%, Normal 40%,
  Hard 56%, LEGEND +6 **58%**, LEGEND +12 **71%**. LEGEND +6 played like Hard, so I raised the bonus to 12.
- **Why the stage averages move win shares so little:** a rating point is worth very little in a CPU-vs-CPU game. A
  logistic fit over all 1,420 games gives **+0.034 per point of average rating gap (SE 0.010)**. That is about
  0.8 win points per rating point near 50%. The level is worth far more: Easy -1.45, Normal -0.63, Hard 0 (SE
  0.12-0.30). So a whole step of the ramp (+2 to +8) moves a city by roughly 2-6 win points. That is less than the
  noise of a 12-game cell (SE 14).
- **Scope cut:** after the restart and the 2-process limit, the cells are smaller than the board asked for:
  - 12 games per boss cell instead of 40;
  - 8 per game 1 cell instead of 16;
  - 12 per Easy and LEGEND cell, on 3 cities.

  Each pooled line has 64-160 games (SE 4-6). Single-city cells can't be read on their own (SE 11-18).

## Chosen values and why

| Constant | Before | After | Why |
|---|---|---|---|
| `Cities.STAGE_AVG` | 40/45/50/54/58/62/66/70 | **40/46/52/58/63/68/73/78** | Each starter now earns his own points after every win, so the expected crew gains about 2.4 average per city. With the old values that crew is level with the city crew at game 1 from Denver to the New York QF (0 to 5 points behind), and the late boss games got easier than in Phase 6 (33% pooled for stages 5-8). The new values keep the city crews ahead on the cards: at game 1 your crew goes from 8 points ahead in Hometown to 13 behind at the New York QF; in the boss games from level to 19 behind. The late boss games go back up to 46%. The pooled lower bound (41%) stays at Phase 6's level. |
| `Difficulty.LEGEND_BONUS` | 6 | **12** | +6 is only about +4 win points by the fit. Measured: 58% vs Hard's 56% (72 games each), so LEGEND was not harder than Hard. +12 measured 71%, 15 points over Hard (about 2 SE). |
| `Trip.BOSS_CAP` | 95 | **95** (kept) | It caps the New York boss on every level (78 + 20 = 98 -> 95). On LEGEND it caps every boss from Denver on (83 + 12 = 95) and New York's good players. I saw no reason to lift it: a higher cap would only make New York harder, and New York is already near the top of the lower bound on Hard. |

Per-city targets (`CITY_TARGETS` 11 / 15 / 21) are unchanged.

## Pooled RED win share (SE, games)

"Before" is `base`, "after" is `c1`. Hometown is stage 1 = 40 in both, so it has the same matchups and is pooled
from the same 12 + 8 games per cell.

| Roster, level | Games | Before: all 8 | After: all 8 | After: stages 1-4 | After: stages 5-8 |
|---|---|---|---|---|---|
| expected, normal | boss | 35% (5, 96) | 41% (5, 96) | 35% (7, 48) | 46% (7, 48) |
| expected, normal | game 1 | 47% (6, 64) | 42% (6, 64) | 28% (8, 32) | 56% (9, 32) |
| expected, normal | both | 40% (4, 160) | 41% (4, 160) | | |
| expected, hard | boss | 53% (5, 96) | 58% (5, 96) | 56% (7, 48) | 60% (7, 48) |
| expected, hard | game 1 | 48% (6, 64) | 48% (6, 64) | 41% (9, 32) | 56% (9, 32) |
| expected, hard | both | 51% (4, 160) | 54% (4, 160) | | |
| best, normal | boss | 41% (5, 96) | 38% (5, 96) | 33% (7, 48) | 42% (7, 48) |
| best, normal | game 1 | 39% (6, 64) | 27% (6, 64) | 28% (8, 32) | 25% (8, 32) |
| best, normal | both | 40% (4, 160) | 33% (4, 160) | | |
| best, hard | boss | 55% (5, 96) | 61% (5, 96) | 62% (7, 48) | 60% (7, 48) |
| best, hard | game 1 | 48% (6, 64) | 48% (6, 64) | 53% (9, 32) | 44% (9, 32) |
| best, hard | both | 52% (4, 160) | 56% (4, 160) | | |

Phase 6 reference (`docs/qa/phase6.md`, Normal, expected roster, 40 games per city game): RED won 40 / 25 / 38 / 40 /
70 / 58 / 50 / 62% of the boss games (Hometown .. New York final), 36% in stages 1-4 and 60% in stages 5-8. Of the
first games it won 45 / 28 / 38 / 25 / 38 / 43 / 45 / 43%, 34% and 42%.

## Levels (Memphis, Denver and New York boss games, `c1`)

| Level | Expected RED win | Best RED win | Expected per city (Mem/Den/NY) | Best per city |
|---|---|---|---|---|
| Easy | 33% (SE 8, 36) | 17% (SE 6, 36) | 4/12 4/12 4/12 | 3/12 2/12 1/12 |
| Normal | 36% (SE 8, 36) | 44% (SE 8, 36) | 4/12 6/12 3/12 | 5/12 6/12 5/12 |
| Hard | 53% (SE 8, 36) | 58% (SE 8, 36) | 8/12 4/12 7/12 | 7/12 5/12 9/12 |
| LEGEND +6 | 47% (SE 8, 36) | 69% (SE 8, 36) | 5/12 3/12 9/12 | 9/12 8/12 8/12 |
| **LEGEND +12** | **75% (SE 7, 36)** | **67% (SE 8, 36)** | 8/12 9/12 10/12 | 11/12 8/12 5/12 |

Both rosters together: Easy 25%, Normal 40%, Hard 56%, LEGEND +6 58%, LEGEND +12 71% (72 games each). Easy < Normal
< Hard holds. The fit's level terms give the same order over all games: Easy -1.45 (SE 0.30), Normal -0.63 (0.12),
Hard 0 (reference). On the expected roster alone, Easy (33%) and Normal (36%) are close on this small subset.

## Per city: RED win % (SE, games)

"avg" is the five-stat average of the three starters, BLUE v RED, after the change. Before, RED's average was 0 / 1 /
2 / 4 / 5 / 6 / 7 / 7 points lower per city in the boss games (Hometown .. New York; the New York boss is now capped, 95 instead of 98). Before,
BLUE's best-roster average was also a little lower (its recruits came from older stages).

**Game 3 (boss; New York: the final), NORMAL**

| City | Expected before | Expected after | avg BLUE v RED after | Best before | Best after | avg BLUE v RED after |
|---|---|---|---|---|---|---|
| Hometown | 25% (12, 12) | 25% (12, 12) | 52.5 v 52.5 | 33% (14, 12) | 33% (14, 12) | 52.5 v 52.5 |
| Chicago | 42% (14, 12) | 42% (14, 12) | 54.9 v 58.5 | 25% (12, 12) | 33% (14, 12) | 57.6 v 58.5 |
| Memphis | 50% (14, 12) | 33% (14, 12) | 57.3 v 64.5 | 25% (12, 12) | 42% (14, 12) | 61.2 v 64.5 |
| New Orleans | 42% (14, 12) | 42% (14, 12) | 59.7 v 70.5 | 58% (14, 12) | 25% (12, 12) | 64.9 v 70.5 |
| Denver | 33% (14, 12) | 50% (14, 12) | 62.1 v 75.5 | 33% (14, 12) | 50% (14, 12) | 70.9 v 75.5 |
| Seattle | 17% (11, 12) | 42% (14, 12) | 64.5 v 80.5 | 33% (14, 12) | 33% (14, 12) | 75.9 v 80.5 |
| Los Angeles | 50% (14, 12) | 67% (14, 12) | 66.9 v 85.5 | 33% (14, 12) | 42% (14, 12) | 80.8 v 85.5 |
| New York | 25% (12, 12) | 25% (12, 12) | 70.5 v 89.5 | 83% (11, 12) | 42% (14, 12) | 88.9 v 89.5 |

**Game 3 (boss; New York: the final), HARD**

| City | Expected before | Expected after | avg BLUE v RED after | Best before | Best after | avg BLUE v RED after |
|---|---|---|---|---|---|---|
| Hometown | 33% (14, 12) | 33% (14, 12) | 52.5 v 52.5 | 67% (14, 12) | 67% (14, 12) | 52.5 v 52.5 |
| Chicago | 58% (14, 12) | 50% (14, 12) | 54.9 v 58.5 | 67% (14, 12) | 67% (14, 12) | 57.6 v 58.5 |
| Memphis | 42% (14, 12) | 67% (14, 12) | 57.3 v 64.5 | 58% (14, 12) | 58% (14, 12) | 61.2 v 64.5 |
| New Orleans | 75% (12, 12) | 75% (12, 12) | 59.7 v 70.5 | 50% (14, 12) | 58% (14, 12) | 64.9 v 70.5 |
| Denver | 42% (14, 12) | 33% (14, 12) | 62.1 v 75.5 | 58% (14, 12) | 42% (14, 12) | 70.9 v 75.5 |
| Seattle | 50% (14, 12) | 75% (12, 12) | 64.5 v 80.5 | 33% (14, 12) | 67% (14, 12) | 75.9 v 80.5 |
| Los Angeles | 75% (12, 12) | 75% (12, 12) | 66.9 v 85.5 | 50% (14, 12) | 58% (14, 12) | 80.8 v 85.5 |
| New York | 50% (14, 12) | 58% (14, 12) | 70.5 v 89.5 | 58% (14, 12) | 75% (12, 12) | 88.9 v 89.5 |

**Game 1 (New York: the quarterfinal, to 21), NORMAL**

| City | Expected before | Expected after | avg BLUE v RED after | Best before | Best after | avg BLUE v RED after |
|---|---|---|---|---|---|---|
| Hometown | 38% (17, 8) | 38% (17, 8) | 51.3 v 42.9 | 25% (15, 8) | 25% (15, 8) | 51.3 v 42.9 |
| Chicago | 50% (18, 8) | 25% (15, 8) | 53.7 v 48.9 | 25% (15, 8) | 25% (15, 8) | 56.4 v 48.9 |
| Memphis | 38% (17, 8) | 38% (17, 8) | 56.1 v 54.9 | 25% (15, 8) | 38% (17, 8) | 60.0 v 54.9 |
| New Orleans | 62% (17, 8) | 12% (12, 8) | 58.5 v 60.9 | 50% (18, 8) | 25% (15, 8) | 64.5 v 60.9 |
| Denver | 50% (18, 8) | 38% (17, 8) | 60.9 v 65.9 | 50% (18, 8) | 62% (17, 8) | 70.5 v 65.9 |
| Seattle | 38% (17, 8) | 50% (18, 8) | 63.3 v 70.9 | 62% (17, 8) | 12% (12, 8) | 75.5 v 70.9 |
| Los Angeles | 62% (17, 8) | 75% (15, 8) | 65.7 v 75.9 | 25% (15, 8) | 12% (12, 8) | 80.5 v 75.9 |
| New York | 38% (17, 8) | 62% (17, 8) | 68.1 v 80.9 | 50% (18, 8) | 12% (12, 8) | 85.5 v 80.9 |

**Game 1 (New York: the quarterfinal, to 21), HARD**

| City | Expected before | Expected after | avg BLUE v RED after | Best before | Best after | avg BLUE v RED after |
|---|---|---|---|---|---|---|
| Hometown | 38% (17, 8) | 38% (17, 8) | 51.3 v 42.9 | 62% (17, 8) | 62% (17, 8) | 51.3 v 42.9 |
| Chicago | 38% (17, 8) | 38% (17, 8) | 53.7 v 48.9 | 38% (17, 8) | 12% (12, 8) | 56.4 v 48.9 |
| Memphis | 75% (15, 8) | 38% (17, 8) | 56.1 v 54.9 | 50% (18, 8) | 88% (12, 8) | 60.0 v 54.9 |
| New Orleans | 38% (17, 8) | 50% (18, 8) | 58.5 v 60.9 | 25% (15, 8) | 50% (18, 8) | 64.5 v 60.9 |
| Denver | 38% (17, 8) | 50% (18, 8) | 60.9 v 65.9 | 75% (15, 8) | 38% (17, 8) | 70.5 v 65.9 |
| Seattle | 50% (18, 8) | 25% (15, 8) | 63.3 v 70.9 | 38% (17, 8) | 50% (18, 8) | 75.5 v 70.9 |
| Los Angeles | 50% (18, 8) | 62% (17, 8) | 65.7 v 75.9 | 50% (18, 8) | 12% (12, 8) | 80.5 v 75.9 |
| New York | 62% (17, 8) | 88% (12, 8) | 68.1 v 80.9 | 50% (18, 8) | 75% (15, 8) | 85.5 v 80.9 |

**Easy and LEGEND (after; LEGEND here is +6, the +12 batch is in the level table above)**

| City | Easy expected | Easy best | LEGEND +6 expected | LEGEND +6 best | LEGEND +12 expected | LEGEND +12 best |
|---|---|---|---|---|---|---|
| Memphis 3 | 33% (14, 12) | 25% (12, 12) | 42% (14, 12) | 75% (12, 12) | 67% (14, 12) | 92% (8, 12) |
| Denver 3 | 33% (14, 12) | 17% (11, 12) | 25% (12, 12) | 67% (14, 12) | 75% (12, 12) | 67% (14, 12) |
| New York final | 33% (14, 12) | 8% (8, 12) | 75% (12, 12) | 67% (14, 12) | 83% (11, 12) | 42% (14, 12) |

On LEGEND +12 RED averages 76.5 in Memphis, 87.5 in Denver (boss at the cap) and 94.6 in the New York final (BOSS_CAP 95
holds most of New York's bonus back).

## Game stats (all batches)

| | Before (640) | After (708) | Target (CLAUDE.md, P7-T1) | |
|---|---|---|---|---|
| Length to 21 | 8.8 min (5.2-12.9) | 8.6 min (5.7-12.4) | 7-11 | pass |
| Length to 11 | 4.4 min (1.8-6.7) | 4.4 min (2.4-7.2) | (Phase 6: 4.5-6.5) | a little short, as in P7-T1 |
| Loser's points to 21 | 16.4 (7-20) | 16.6 (6-20) | usually 12-20 | pass |
| Fouls per game to 21 | 2.5 | 2.5 | 1-5 | pass |
| Shot-clock violations | 0 | 0 | few | pass |
| Side switches | 1 in every game | 1 in every game | 1 | pass |
| Unfinished, script errors | 0, 0 | 0, 0 | 0 | pass |

## Checks

| Check | Result | |
|---|---|---|
| Lower bound near the Phase 6 win shares (Normal) | 41% pooled (Phase 6 about 42%). Boss games 35% in stages 1-4 (Phase 6 36%) and 46% in 5-8 (Phase 6 60%) | pass (late boss games a bit easier than in Phase 6, 2 SE) |
| Upper bound on Hard: RED wins 20%+ | 56% pooled, 61% in the boss games; lowest single cell 12% (8 games: Chicago 1, LA 1) | pass |
| LEGEND harder than Hard | +6: 58% vs 56% (not harder). **+12: 71% vs 56%** | pass with the new LEGEND_BONUS |
| Easy < Normal < Hard | 25% < 40% < 56% (subset); fit -1.45 < -0.63 < 0 | pass |
| `--triptest-data` and `--triptest-data --load` | `TRIPDATA OK` (136 checks ok, incl. "LEGEND: +12 on the opponents, capped at 95 (ny_boss 95)"); round trip across a restart: same state | pass |
| `--trip-test --target 3` | `TRIP END ... record 24-16 ... games 41 ... results checked 41 ... replays 1 ... complete`, exit 0 | pass |
| Quick Game Easy / Normal / Hard unchanged | `Trip.quick_ratings()` shifts each player to average 50. At the new stage averages, no stat of a non-boss player reaches the cap (New York good: 78 + 4 + 12 = 94), and a capped boss is flat anyway. So every Quick Game crew gets the same ratings as before. Quick Game LEGEND does change (+12 instead of +6, `LEGEND_CAP` 95) | by reasoning, no autoplay rerun |

## Findings

1. **The ramp barely moves win shares** (fit above). STAGE_AVG mostly sets the numbers on the cards: whether the city
   crews look stronger than yours as your points grow. That is why I took the plan's values. With them the late cities
   still read as tougher than your crew, the lower bound matches Phase 6, and Hard stays beatable. Phase 6 guessed
   "a step of 2 moves a city by 3-5 win points"; the measured value is about 1.7.
2. **The best roster is not much better than the expected one** for the CPU BLUE. On Normal it wins more (RED 33% vs
   41%), but on Hard it doesn't (56% vs 54%): the boss on BLUE gains less than the level costs. A real player
   gains more from a strong roster than the Hard CPU does. So "upper bound" here means "the ratings' best case", not
   "the easiest a human will find it".
3. **Hard is hard for any roster:** RED wins 54-61% against both rosters. In Phase 6, Hard wasn't measured on the trip.
   If the owner finds Hard trips too hard, the fix is in the Hard CPU values (out of this task's scope), not the ramp.
4. **LEGEND +6 was not measurably harder than Hard.** At +12 it is. In New York, BOSS_CAP 95 leaves LEGEND +12 only about
   +5 on RED's average (89.5 -> 94.6; the boss is capped on every level).
5. **The best roster in the New York final** drafts the QF and SF crews' players (P8-21). BLUE averages 88.9 against
   89.5, nearly even. RED won 42% on Normal and 75% on Hard there.
6. **Small cells:** single-city numbers at 8-12 games swing by ±15-18 points. Two cells look odd but are inside the
   noise: New Orleans 1 Normal expected (1/8 RED) and LA / New York game 1 Normal best (1/8). Judge the ramp on the
   pooled lines.

## Proposed targets (for the lead to confirm)

- Lower bound (`--expected-roster`, Normal): RED 35-50% pooled over all cities; boss games 30-45% in stages 1-4 and
  40-60% in 5-8.
- Upper bound (`--best-roster`, Hard): RED at least 20% pooled, and no 40-game cell under 10%.
- LEGEND at least 10 points over Hard on the same cells (72+ games), and Easy < Normal < Hard.
- Measure on pooled lines (64+ games); single-city cells need 40+ games to be read on their own.

## How to rerun

```
# one cell game (12 per cell here); kinds --expected-roster / --best-roster, levels easy|normal|hard|legend
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --city <id> --cgame <1|3> \
    --expected-roster --difficulty normal
# LEGEND needs the stars, else it silently plays Hard
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --city denver --cgame 3 \
    --best-roster --difficulty legend --stars 72
godot --headless --path . -- --triptest-data
godot --headless --path . -- --triptest-data --load
godot --headless --path . --fixed-fps 60 --quit-after 2000000 -- --trip-test --target 3
```
Each run prints the `RAMP` line (both teams' starters and averages), `MATCH`, `FINAL` and `GAME LENGTH`. Win share
is RED's share of `FINAL` lines.
