# P10-08 Phase 10 QA: the Velvet watch item

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `9378f0d`, Godot 4.3 stable (Linux), headless, `--fixed-fps 60`.
Import was clean in both copies (0 errors).

**Setup:** two copies of the project outside the checkout: `a` (the build as it is, Velvet `limit` 6) and `b` (the same,
except Velvet's challenge `limit` 7 and its line "HOLD VELVET UNDER 7 POINTS AND WIN (TO 11)" in
`scripts/legends_data.gd`). Each copy had its own `config/name`, and each game had its own fresh `XDG_DATA_HOME`, so
there was no test trip save and no Legends file. At most 2 of my Godot processes ran at once. Every game was
`--autoplay --challenge <id> --difficulty <level> --expected-roster --no-countdown` (or `--best-roster` where the
table says so). BLUE plays Hard in `--autoplay`; the level changes RED only. Copy `b` also ran the Boxcar and finale
cells, which `limit` doesn't touch.

Expected crew (`Trip.end_of_trip_crew(false)`): `ud_deuce 70/71/72/72/71, ud_jojo 71/71/73/71/72, ud_tank
69/68/68/70/69`. Velvet's side: `lg_velvet 76/61/81/56/56, lg_steeple 37/52/72/57/42, lg_set_shot 47/77/42/47/47`
(Normal).

**Games:** 780. All of them reached `FINAL` and printed their `CHALLENGE` line. There were 0 `SCRIPT ERROR` / `ERROR`
lines and 0 shot-clock violations. Every game had exactly one side switch. Per game: 36.3 shots, FG 56.0%, 1.7
interceptions, 0.6 out of bounds, 0.8 fouls, 6.0 steals and 4.6 blocks. OREB was 24.0% of misses. Game time ran 2:11 to
12:36: about 4:30-5:10 to 11, 6:10-7:10 to 15, and 9:20-9:35 for the finale.

## Velvet: `limit` 6 (now) vs 7, BLUE met %

| Crew, level | limit 6 | limit 7 | P9-34 (limit 6) | P9-26 (limit 6) |
|---|---|---|---|---|
| expected, Easy | **82.5%** (33/40), SE 6.0 | 92.5% (37/40), SE 4.2 | - | 85 (20) |
| expected, Normal | **75.0%** (30/40), SE 6.8 | 72.5% (29/40), SE 7.1 | 45 (20) | 90 (20) |
| expected, Hard | **57.5%** (23/40), SE 7.8 | 45.0% (18/40), SE 7.9 | 60 (20) | 40 (20) |
| best, Normal | **75.0%** (30/40), SE 6.8 | 70.0% (14/20), SE 10.2 | - | 95 (20) |
| best, Hard | **67.5%** (27/40), SE 7.4 | 50.0% (10/20), SE 11.2 | - | 70 (20) |

How the games were failed (goal = "VELVET SCORED n", lost = a plain loss at 11):

| Cell | limit 6: goal / lost | limit 7: goal / lost |
|---|---|---|
| expected, Easy | 4 / 3 | 1 / 2 |
| expected, Normal | 4 / 6 | 1 / 10 |
| expected, Hard | 3 / 14 | 3 / 19 |
| best, Normal | 3 / 7 | 1 / 5 |
| best, Hard | 5 / 8 | 3 / 7 |

- **P9-34's Normal 45% did not come back.** On 40 games Normal is 75% at `limit` 6, inside the 55-75 band (at its top).
  The cell has now read 90 / 45 / 75 over three batches, which is what a short game to 11 does on 20-game cells.
- **Normal is above Hard again** at `limit` 6, on both crews: expected 75 > 57.5, best 75 > 67.5. Easy > Normal > Hard
  holds.
- **The limit is a weak lever.** At `limit` 6 the goal breaks only 3-5 games in 40. Most failures are plain losses, so
  7 can only win back a few games per cell. At 7, Easy rose to 92.5% and Normal and Hard did not rise: they fell by 1
  to 1.5 SE, which is noise.
- Expected Hard at 57.5% is about 1 SE above the 35-50 Hard band. The best crew still loses 32.5% on Hard (needs >=
  20%): PASS.

## All of Chapter 1, expected crew, `limit` 6, BLUE met %

| Challenge (type) | Easy | Normal | Hard | P9-34 N / H | P9-26 E / N / H |
|---|---|---|---|---|---|
| Steeple (hold < 7, to 15) | 70 (14/20) | 85 (17/20) | 35 (7/20) | 90 / 60 | 95 / 70 / 70 |
| Gate (race 11 before 10) | 75 (15/20) | 50 (10/20) | 45 (9/20) | 60 / 35 | 70 / 65 / 40 |
| Set Shot (fire, to 15) | 70 (14/20) | 70 (14/20) | 40 (8/20) | 80 / 50 | 75 / 80 / 65 |
| Boxcar (2 stops, to 15) | 52.5 (21/40) | 55 (22/40) | 37.5 (15/40) | 60 / 20 | 65 / 55 / 40 |
| Velvet (hold < 6, to 11) | 82.5 (33/40) | 75 (30/40) | 57.5 (23/40) | 45 / 60 | 85 / 90 / 40 |
| Quarterback (from 0-2, to 15) | 60 (12/20) | **30** (6/20) | **15** (3/20) | 50 / 40 | 70 / 60 / 25 |
| **Pooled, 6 challenges** | **68.1%** (109/160) | **61.9%** (99/160) | **40.6%** (65/160) | 65 / 44 | 77 / 70 / 47 |
| Finale (to 21) | 90 (18/20) | 80 (16/20) | 30 (6/20) | 50 / 60 | 90 / 55 / 45 |

SE: about 10-11 points on a 20-game cell and 7-8 on a 40-game cell. The pooled rows count each game once.

Failure reasons: Boxcar lost 47 games outright and failed 15 more on stops ("ONLY 1 OF 2" 13, "ONLY 0 OF 2" 2), 5 of
those on Easy and 8 on Normal. Steeple broke his goal 7 times in 60. Gate's failures are all "GATE'S CREW GOT 10".
Set Shot, Quarterback and the finale are failed by losing.

## Checks

| Check | Result |
|---|---|
| Import | PASS (clean, both copies) |
| Every game ends, no errors, no shot-clock violations | PASS (780/780 `FINAL`; 0 errors; 0 violations; interceptions 1.7 per game) |
| Velvet Normal back in the 55-75 band | PASS: 75% (40 games) |
| Velvet Normal >= Hard | PASS: 75 vs 57.5 (expected), 75 vs 67.5 (best) |
| Velvet Hard in 35-50 (expected) | Slightly high: 57.5% (about 1 SE over) |
| Boxcar Hard real at 20%? | No: 37.5% on 40 games (P9-34's 4/20 was noise). In the band. |
| Pooled bands, expected crew (E 65-80, N 55-75, H 35-50) | PASS: 68.1 / 61.9 / 40.6 |
| Easy > Normal > Hard, pooled | PASS |
| Every type winnable (no cell near 0) | PASS, but Quarterback Hard is 15% (3/20), the lowest cell measured in Phase 9-10 |
| Finale | Easy 90, Normal 80, Hard 30 (a bit under the Hard band, 1.5 SE) |

## Recommendation for P10-11

**Keep Velvet's `limit` at 6** (`scripts/legends_data.gd`, `lg_velvet.challenge.limit`; no change). On 40 games per
cell it is back where P9-26 tuned it on Normal (75%) and it is ordered by level on both crews. `limit` 7 doesn't raise
Normal or Hard, because few games break the goal. It only pushes Easy to 92.5%. The Velvet watch item can be closed.
(`story_text.gd` already says "Under six.")

The cells to watch now (not part of this task; measure 40 games before touching them):
1. **Quarterback on Normal 30% and Hard 15%** (20 games each; P9-26 60 / 25, P9-34 50 / 40). Normal is about 2.5 SE
   under its band. Every failure was a plain loss: BLUE averaged 12.8-13.6 on Normal and 10.2-14.7 on Hard. If 40
   games confirm it, the lever is `lg_quarterback.challenge.start_score` [0, 2] -> **[0, 1]**. A deficit counts
   double against the Grandfathers.
2. **Boxcar on Easy 52.5%** (40 games, about Normal's 55%). It sits under the 65-80 Easy band because 5 Easy wins failed on
   stops. Hard (37.5%) is fine. No change is suggested yet. If the lead wants Easy higher, a level-dependent `count`
   is a code change (`challenge.gd`), not a constant.
3. **Finale on Hard 30%** (20 games) is just under 35. A 40-game check is needed before touching
   `FINALE_STAGE_AVG` 52.

Logs and the tally script are in my scratch folder (`p1008/logs`, `p1008/tally.py`, `p1008/final_tally.txt`).
