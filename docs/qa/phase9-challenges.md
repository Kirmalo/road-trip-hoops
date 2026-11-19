# P9-26 Phase 9 QA: challenge balance

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `99411b9` (challenges, signature moves, legends in the trip, OLD
SCHOOL `long_shot_mult` 0.80), Godot 4.3 stable (Linux), headless, `--fixed-fps 60`. Every number below changes only
`scripts/legends_data.gd`.

**Setup:** three copies of the project outside the checkout (`p926/a`, `b`, `c`), each with its own `config/name` and
`XDG_DATA_HOME`. At most 2 of my Godot processes ran at once. Other agents' jobs shared the 4 cores, so the games ran
slowly. Every game was `--autoplay --challenge <id> --difficulty <level>` with `--expected-roster` or `--best-roster`
(the end-of-trip crews, `Trip.end_of_trip_crew()`). With neither flag and no test trip save, the Kings play. LEGEND
used `--stars 72`. The mid-trip check used a test trip save. BLUE plays Hard in `--autoplay`, and the level changes
RED only.

**How `--challenge` combines with the roster flags:** it works without `--city`. `Legends.test_match()` builds the
challenge, then puts `end_of_trip_crew(best)` on BLUE. The crew avoids the opponents (a legend you drafted sits out
when he is on the other side). Expected crew: `ud_deuce 70/71/72/72/71, ud_jojo 71/71/73/71/72, ud_tank
69/68/68/70/69` (about 70.5). Best crew: `la_boss 93s`, a drafted legend at 78 + 20 (capped), `ny_q1`. When the
opponents hold Set Shot, the drafted legend is Velvet or Quarterback instead. The `--city new_york --cgame 3` flags
from the brief aren't needed and change nothing here.

**Games:** 1,522 challenge games. That is 252 baseline (6 per cell), 211 T1 and 265 T2 (both stopped early once the
direction was clear), 966 T3 (the final values: 20 per E/N/H cell, 6 per LEGEND and Kings cell), and 28 mid-trip. Every
game reached `FINAL` and printed its `CHALLENGE` line. There were 0 `SCRIPT ERROR` / `ERROR` lines, 0 shot-clock
violations, 0 interceptions and about 0.8 out of bounds and 1.1 fouls per game. Every T3 game had exactly one side
switch. FG% was 53%. Games ran 2:08 to 13:10 of game time (challenges to 11 take about 4-5 min, to 15 about 6-7 min,
the finale about 9 min). None came near `--quit-after`. Import was clean, and `--legendtest` passes with the new values
(`LEGENDTEST OK`).

## Bands (lead's proposal; BLUE = you)

From `docs/qa/phase8-ramp.md`, the New York final with the expected roster: RED won 33% on Easy, 25% on Normal and 58%
on Hard (12 games each). Pooled over the late boss games, Normal was about 46%. I read that as these BLUE (met) bands:

| | Easy | Normal | Hard |
|---|---|---|---|
| expected crew (target ~ NY final) | 65-80% | 55-75% | 35-50% |
| best crew | > expected | > expected | > expected, and RED >= 20% (BLUE <= 80%) |

## Values changed

| Constant (legends_data.gd) | Before | After | Why |
|---|---|---|---|
| `CHALLENGE_AVG` | 80 | **66** | At 80 the expected crew met 33% of the challenges on Normal and 19% on Hard. A rating point is worth little here (see below), so this lever only moved about +10 points from 80 to 66. The rest came from the goal numbers. |
| `MATE_DROP` | 8 | **14** | The teammates (52 + shape) now play clearly below the legend, so the legend's own game is still the story. The legend himself keeps 66 + his shape (Steeple finishing 86, Gate defense 91, Set Shot shooting 91). |
| `FINALE_STAGE_AVG` | 78 | **52** | 78 + 20 put the finale legends at the 95 cap on almost every stat (on LEGEND, all 15 stats were 95). At 52 + 20 = 72 they keep their shapes: Steeple 57/72/92/77/62, Velvet 82/67/87/62/62, Quarterback 77/77/62/72/72. On LEGEND (+12) only Steeple's and Velvet's finishing hit the cap. The finale's win share barely moved between 78 and 52 (below). |
| Steeple `limit` | 6 | **7** | "HOLD STEEPLE UNDER 7 POINTS AND WIN (TO 15)" |
| Gate `their_target` | 7 | **10** | 11 before 7 was met 5 times in 36 baseline games on E/N/H (both crews), and once in 24 on Normal and Hard. 9 was still 10% on Hard (T1). The line is now "REACH 11 BEFORE GATE'S CREW GETS 10", and 10 is the most the rule allows (`target - 1`). |
| Boxcar `count` | 3 | **2** | With 3, many won games failed on stops ("ONLY 1 OF 3"), and Hard was 0-17%. The line is now "BLOCK OR STEAL ON BOXCAR 2 TIMES AND WIN (TO 15)". |
| Velvet `limit` | 5 | **6** | "HOLD VELVET UNDER 6 POINTS AND WIN (TO 11)" |
| Quarterback `start_score` | [0, 6] | **[0, 2]** | 0-6 was met 0 times in 18 games on E/N/H with the expected crew (4/18 with the best), and 0-4 and 0-3 were still 20-25% on Normal. The Grandfathers win the plain game about half the time even when rated well under the crew (see below), so any deficit counts double. The line is now "START DOWN 0-2: COME BACK AND WIN (TO 15)". |

`DRAFT_TIER` (20, a drafted legend on the trip) and `RATING_CAP` (95) are unchanged.

**The story text needs a follow-up (not my file).** `scripts/story_text.gd` still has the old numbers in some
unlock lines:
- line 276: "Under six." (Steeple)
- line 288: "Eleven before seven." (Gate)
- line 314: "Three times you took it off me." (Boxcar)
- line 328: "Under five." (Velvet)
- lines 342 and 344: "Down six before the tip", "Down six felt like home." (Quarterback)

`docs/legends-plan.md` (L2 a and the part 2 table) and the `docs/BOARD.md` HUD example ("HOLD STEEPLE UNDER 6") show
the old goals too. L2 a was the owner's pick, so the lead should show the owner the new numbers.

## Results: BLUE met % (SE), before and after

"Before" is the merged values (6 games per cell). "After" is T3 (20 games per E/N/H cell, 6 for LEGEND).

### Pooled

| Level | Expected, before | Expected, after | Best, before | Best, after | Finale expected, before → after | Finale best, before → after |
|---|---|---|---|---|---|---|
| Easy | 47% (36) | **77%** (120) | 64% (36) | **83%** (120) | 67% (6) → **90%** (20) | 100% (6) → **100%** (20) |
| Normal | 33% (36) | **70%** (120) | 53% (36) | **68%** (120) | 67% (6) → **55%** (20) | 83% (6) → **80%** (20) |
| Hard | 19% (36) | **47%** (120) | 19% (36) | **71%** (120) | 17% (6) → **45%** (20) | 50% (6) → **80%** (20) |
| LEGEND | - | **36%** (36) | - | **61%** (36) | - → 50% (6) | - → 67% (6) |

### Per challenge, after (T3), BLUE met %

| Challenge (type) | Easy exp | Easy best | Normal exp | Normal best | Hard exp | Hard best | LEGEND exp / best (6 each) | Kings, Normal (6) |
|---|---|---|---|---|---|---|---|---|
| Steeple (hold < 7, to 15) | 95 | 95 | 70 | 95 | 70 | 75 | 83 / 67 | 50 |
| Gate (race 11 before 10) | 70 | 80 | 65 | 35 | 40 | 60 | 50 / 50 | 33 |
| Set Shot (fire, to 15) | 75 | 90 | 80 | 75 | 65 | 80 | 17 / 67 | 33 |
| Boxcar (stop x2, to 15) | 65 | 85 | 55 | 45 | 40 | 80 | 17 / 67 | 50 |
| Velvet (hold < 6, to 11) | 85 | 90 | 90 | 95 | 40 | 70 | 17 / 67 | 33 |
| Quarterback (comeback 0-2, to 15) | 70 | 60 | 60 | 65 | 25 | 60 | 33 / 50 | 50 |
| Finale (to 21) | 90 | 100 | 55 | 80 | 45 | 80 | 50 / 67 | 17 |

The SE is about 10-11 points on a 20-game cell and 19-20 on a 6-game cell.

### Per challenge, before (merged values, 6 games per cell), BLUE met %

| Challenge | Easy exp / best | Normal exp / best | Hard exp / best |
|---|---|---|---|
| Steeple (hold < 6) | 67 / 83 | 50 / 50 | 33 / 50 |
| Gate (11 before 7) | 50 / 17 | 17 / 0 | 0 / 0 |
| Set Shot (fire) | 83 / 100 | 67 / 100 | 17 / 50 |
| Boxcar (stop x3) | 17 / 50 | 33 / 33 | 0 / 17 |
| Velvet (hold < 5) | 67 / 100 | 33 / 100 | 67 / 0 |
| Quarterback (0-6) | 0 / 33 | 0 / 33 | 0 / 0 |
| Finale | 67 / 100 | 67 / 83 | 17 / 50 |

### Steps between

| Step | Values | Normal exp | Hard exp | Notes |
|---|---|---|---|---|
| base | 80 / 8 / 78, Gate 7, Boxcar 3, QB 0-6 | 33% (36) | 19% (36) | |
| T1 | 72 / 10 / 66, Gate 9, Boxcar 2, QB 0-4 | 50% (60) | 25% (60) | QB normal 20%, Gate hard 10% |
| T2 | 68 / 10 / 60, Gate 10, QB 0-3 | 49% (72) | 31% (72) | -4 rating points moved nothing measurable |
| **T3** | **66 / 14 / 52**, Steeple 7, Velvet 6, QB 0-2 | **70%** (120) | **47%** (120) | the final values |

(The three numbers are `CHALLENGE_AVG` / `MATE_DROP` / `FINALE_STAGE_AVG`.)

## Checks

| Check | Result |
|---|---|
| Import, `--legendtest` | PASS (clean; `LEGENDTEST OK` with the new values) |
| Expected crew about the NY final on each level | PASS: Easy 77%, Normal 70%, Hard 47% (NY final: 67 / 75 / 42%, 12-game cells; pooled Normal late boss games about 54%) |
| Best crew wins more | PASS pooled (E/N/H: 74% vs 64%, 360 games each; Hard 71 vs 47, Easy 83 vs 77). On **Normal alone, best 68% = expected 70%**, inside the noise. The odd cells are Gate Normal best 35% and Boxcar Normal best 45%. |
| On Hard the CPU still wins 20%+ against the best crew | PASS: challenges RED 29%. The finale is **on the line**: RED 20% (4/20, SE 9). |
| Easy < Normal < Hard (harder level = lower share) | PASS on the expected crew: 77 > 70 > 47 > 36 (LEGEND). Best crew: 83 > 68 ≈ 71 > 61. Normal and Hard can't be told apart on the best crew. |
| Every challenge type winnable (none near 0%) | PASS: the lowest 20-game cell is Quarterback Hard expected at 25%. Before: Gate 0% and Quarterback 0% on Normal and Hard. |
| Every goal type met and failed in the logs | PASS. Hold: "STEEPLE SCORED 7", "VELVET SCORED 6". Race: "GATE'S CREW GOT 10". Stop: "ONLY 1 OF 2 STOPS ON BOXCAR". Fire and comeback fail on "LOST". All are met in many games. |
| Finale legends keep their shapes (not all 95) | PASS on E/N/H (no 95s except Steeple's finishing 92 → 95 on LEGEND, and Velvet's). Before: 13 of 15 stats at 95 on Normal and all 15 on LEGEND. |
| Mid-trip: challenges reachable with a Denver-stage crew | PASS. Steps: `--trip-test --target 3 --trip-stop-after denver --difficulty normal`, then `--challenge <id>` without a roster flag. TRIP STOP after denver, exit 0. The trip crew (starters `ht_g1 59/59/59/59/56, ud_jojo 65s, ud_deuce 64s`) played all 7. Normal: 42% met (10/24, SE 10), the finale 4/4. That is below the end-of-trip 70%, so the challenges get easier as the crew grows. |
| Kings fallback (no target) | Normal, 6 games each: challenges 42% (15/36), finale 17% (1/6). Kings `ud_jojo 60/48/44/48/52, ud_tank 42/38/62/58/48, ud_deuce 50/60/46/46/48`. |
| Screenshots | NOT RUN. The brief limited me to headless processes. The changed HUD lines were checked by text in a `--humantest`: "REACH 11 BEFORE GATE'S CREW GETS 10" is 1 character longer than before, and "COME BACK FROM 0-2: WIN TO 15". Both games ran (met 11-7 and 15-11). The line is 720 px wide at font 22, so the HUD should be checked once under xvfb. |

## Why the ratings move so little here

From 80 / 8 to 68 / 10, the legends dropped 12 points and their mates 14. The expected crew's Normal share went from
33% to 49%, and most of that was the Gate and Boxcar goal changes. Steeple's and Set Shot's plain-game shares barely
moved. The finale showed no measurable change from 78 to 52: on Normal, pooled, it was 4/6, 5/10, 6/12 and 11/20 at
78 / 66 / 60 / 52. Under the OLD SCHOOL era rules the Grandfathers' inside style (dunks, close shots, long shots ×0.80)
wins about half the games against a crew that is rated 10-15 points higher. On the Quarterback challenge at T2, RED
averaged about 61 against 70.5 and still won 9 of 12 (in one of them it made 9 dunks to BLUE's 2).

The best crew (about 90) does gain, especially on Hard. So the lower ratings mostly protect the mid-trip and Kings
cases, and the goal numbers set the share for the end-of-trip crews.

## Suggestions for the lead

1. **Show the owner the new goal numbers** (they change L2 a) and **update the story lines listed above**
   (`story_text.gd`, P9-14's file), plus `docs/legends-plan.md` and the BOARD HUD example.
2. Finale vs the best crew on Hard is at exactly 20% RED. For more margin, try `FINALE_STAGE_AVG` 55: the shapes
   still hold on Normal, since Steeple's finishing reaches the cap at 95. Measure it on 40+ games, because a 20-game
   cell can't see a 3-point change.
3. Velvet on Normal is the easiest cell (90%) but Hard is 40%. If the owner wants Velvet harder, `limit` 5 is the
   lever. I kept 6 so the level gap isn't widened.
4. The rating levers are weak because of the era rules. Any later change to `twists.gd` `era_grand` (P9-30) should
   rerun this table, at least on Normal and Hard with the expected crew.
