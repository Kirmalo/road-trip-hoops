# P10-23 Phase 10 QA: Chapter 2 ("the Fathers") challenge balance

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `890ef5e` (P10-21 ISO BALL QA and P10-22 Fathers perks merged), plus this
task's changes: the Chapter 2 numbers in `scripts/legends_data.gd` and P10-N1 in `scripts/trip.gd`. Godot 4.3 stable
(Linux), headless, `--fixed-fps 60`.

**Setup:** I used two copies of the project outside the repo (`a` and `b`, each with its own `config/name`). Every game
got its own fresh `XDG_DATA_HOME`, so there was no test trip save and no Legends file unless I put one there. At most
2 of my Godot processes ran at once. Every game was `--autoplay --challenge <id> --difficulty <level> --no-countdown`
plus `--expected-roster` or `--best-roster` (the end-of-trip crews, `Trip.end_of_trip_crew()`). LEGEND used
`--stars 72`. The Kings games had no roster flag and no trip save. For the mid-trip crew, the P10-01 fixture
`trip_v2_legend.json` (with `settings_v2_36.cfg`, 36 stars) was copied in as `trip_test.json` / `settings_test.cfg`.
BLUE plays Hard in `--autoplay`, and the level changes RED only. The import was clean. `--legendtest` passes with the
final values (`LEGENDTEST OK`; one NOTE: `legends_fathers.ogg` isn't there yet, so the chapter plays `newyork`).

**Games:** 1,961 games: 1,924 `--autoplay` and 37 `--humantest`. Every one reached `FINAL`, printed its `CHALLENGE`
line and exited 0. There were 0 `SCRIPT ERROR` / `ERROR` lines and 0 shot-clock violations. Every game had exactly one
side switch. Per game: 40.6 shots (14-83), FG 54.2%, 1.59 interceptions (max 8), 1.20 fouls, 0.71 out of bounds,
6.2 steals and 5.6 blocks. OREB was 24.5% of misses. Game time: to 11, 4.4 min (2.0-8.4); to 15, 6.2 min (3.3-10.2);
to 21, 9.0 min (5.7-12.5). No game came near `--quit-after`, and no player or ball got stuck (every game ended).

The run harness lost two worker threads to a log-name race and to a lost child process. I re-ran exactly the missing
jobs, so every cell below has the games it says.

## P10-N1: the best crew's legend (done)

Rule (coordinator): in a `--challenge` run, `Trip.end_of_trip_crew(true)` / `--best-roster` drafts a legend only from
the chapters up to and including the challenge's own, never one of the opponents. `trip.gd`: `end_of_trip_crew()`
sets `_sim_chapters` from `Flow.match.chapter` (in `LegendsData.chapter_ids()` order) when `Flow.match` is a legends
game. `legend_available()` checks it only on the sim path (`_sim_legends`). The real draft and the
`--city --best-roster` ramp sims are unchanged. The `TRIP END CREW` line now ends with `| chapters [...]` (or `all`).

| Run | Best crew's legend (every game) |
|---|---|
| Chapter 1 (Steeple, Set Shot, Velvet, finale) | `lg_quarterback` 95/95/88/95/95, chapters `["grand"]` |
| Chapter 1 (Gate, Boxcar, Quarterback) | `lg_set_shot` 93/95/88/93/93 or `lg_velvet` 95/93/95/88/88, `["grand"]` |
| Chapter 2 (Ankles, Freight, Lockbox, finale) | `lg_eyes_closed` 95/95/93/93/95, chapters `["grand", "fathers"]` |
| Chapter 2 (Rooftop, Midrange, Eyes Closed) | `lg_quarterback` (Eyes Closed is an opponent or a mate) |

The other two are always `la_boss` 93s and `ny_q1` 82/82/94/94/82. Chapter 1's best crew is again Phase 9's kind (a
Grandfather). Re-measured below: Normal 65%, Hard 72%, against P9-26's 68 / 71.

## Bands for Chapter 2 (proposal, for the lead to confirm)

F6 a says "a step harder than Chapter 1". The coordinator's targets are Normal about 60-65% and Hard about 40% with the
expected crew. P9-26's bands were Easy 65-80, Normal 55-75 and Hard 35-50. I shifted them:

| | Easy | Normal | Hard |
|---|---|---|---|
| expected crew | 60-75% | 55-70% (aim 60-65) | 33-47% (aim 40) |
| best crew | > expected | > expected | > expected, and RED >= 20% (BLUE <= 80%) |

## Values changed (`scripts/legends_data.gd`, Chapter 2 only)

| Key | Before | After | Why |
|---|---|---|---|
| fathers `challenge_avg` | 69 | **69** (unchanged; T1 tried 67) | At 67 / 15, Hard was 53% (on target with Lockbox at 4, Normal 57.5%). Back at 69 / 14, Hard is 39-44%. The legend is 3 over Chapter 1's 66 (the "step"). |
| fathers `mate_drop` | 13 | **14** | Mates at 55 + shape (Chapter 1: 52). With 13, Normal was 49%. |
| fathers `finale_stage_avg` | 52 | **56** | At 52 the finale on Hard was 54% (14/26), above the band. At 56 it is 35% (7/20) and Normal 70%. Shapes hold: Rooftop 86/76/91/66/61, Midrange 76/95/76/66/66, Freight 61/61/95/86/71 (two stats at the 95 cap). |
| Eyes Closed `start_score` | [0, 2] | **[0, 1]** | At 0-2, 42% on both Normal and Hard (12 games each), and every failure was a plain loss. At 0-1: Normal 75%, Hard 60%. Line: "START DOWN 0-1: COME BACK AND WIN (TO 15)". |
| Lockbox `min` | 6 | **3** | See "The score goal" below. Line: "SCORE 3 POINTS YOURSELF ON LOCKBOX AND WIN (TO 11)". |

Not changed: Rooftop `count` 2, Ankles `their_target` 10, Midrange `cool_misses` 2, Freight `limit` 7, and every
target (Lockbox stays to 11, the finale to 21, as F3 a says). The legends_data.gd row comment says what changed.

**F3 a said "6+" for Lockbox.** The lead should show the owner the new number (and Eyes Closed's 0-1), the way P9-26
did for L2 a.

## The score goal (Lockbox)

The goal is only judged at the end, so it never changes play: no early end, and the "you" side plays the same way. So
any game can be re-judged at another `min` from its `CHALLENGE ... you (<id>) N of M pts` line. The table re-judges
the final-rating games (T2) and the humantests.

| Cell (games) | won the game | min 2 | **min 3** | min 4 | min 5 | min 6 |
|---|---|---|---|---|---|---|
| expected, Easy (12) | 75% | 67 | **50** | 50 | 17 | 17 |
| expected, Normal (20) | 70% | 60 | **50** | 35 | 15 | 0 |
| expected, Hard (20) | 55% | 50 | **45** | 15 | 15 | 5 |
| expected, LEGEND (12) | 67% | 67 | **67** | 33 | 17 | 8 |
| best, Normal (12) | 83% | 67 | **33** | 17 | 0 | 0 |
| best, Hard (12) | 58% | 42 | **33** | 25 | 17 | 0 |
| humantest, expected, Normal (12) | 83% | 75 | **50** | 42 | 8 | 8 |
| humantest, expected, Hard (6) | 50% | 33 | **17** | 17 | 17 | 0 |
| all humantests, every rating step (35) | 80% | 63 | **51** | 40 | 20 | 11 |

- **The plain game against Lockbox's crew is easy, and "you" scoring is the goal.** "You" is BLUE player 0. In
  `--autoplay` and in the scripted `--humantest` thumb (it presses CALL every 3 s and shoots inside 24 ft), "you"
  scores about a third of the team's points: 3.4 of 10.3 on Normal, 2.6 of 9.4 on Hard (Lockbox's defense is 89 on
  Normal). The humantest thumb scored 3.3 of 10.7, the same as the CPU.
- At the owner's 6 the goal was met 0-17% everywhere (baseline: 0 of 12 on Hard). At 4 it was 35% on Normal and 15%
  on Hard, while every other Chapter 2 cell is 30-75%. At **3** it is 50% on Normal and 45% on Hard, in line with the
  other five. On Normal, 50% of the humantests met it.
- A real player who goes for the goal will shoot more than the CPU's "you", so 3 may play easier in human hands than
  these numbers say. If the owner wants it stricter, 4 is the step: from the table, about 35-40% on Normal and 15-20%
  on Hard by the CPU measure.
- **The best crew's low score is a measuring effect.** Its "you" is the drafted legend (`lg_eyes_closed`, a pass-first
  95), who scores 2.4 of 10.7. In a real lineup the player picks YOU.

## Results: Chapter 2, BLUE met %

Steps (the three numbers are `challenge_avg` / `mate_drop` / `finale_stage_avg`):

| Step | Values | Expected Easy | Expected Normal | Expected Hard | Notes |
|---|---|---|---|---|---|
| B1 base | 69 / 13 / 52, Eyes 0-2, Lockbox 6 | 52.8% (36) | 48.6% (72) | 36.1% (72) | Lockbox 0-17% |
| T1 | 67 / 15 / 52, Eyes 0-1, Lockbox 4 | 62.5% (48) | 57.5% (120) | 45.0% (120) | without Lockbox, Hard 61% > Normal 59% |
| **T2 (final)** | **69 / 14 / 56, Eyes 0-1, Lockbox 3** | **63.9% (72)** | **63.3% (120)** | **44.2% (120)** | Lockbox as played at 4: N 60.8, H 39.2 |

Final values (T2, Lockbox re-judged at 3), per challenge:

| Challenge (type) | Easy exp | Normal exp | Hard exp | LEGEND exp | Normal best | Hard best | LEGEND best | Kings, Normal | Mid-trip, Normal |
|---|---|---|---|---|---|---|---|---|---|
| Rooftop (stop x2, to 15) | 42 (5/12) | 55 (11/20) | 40 (8/20) | 33 (4/12) | 75 (9/12) | 58 (7/12) | 33 (2/6) | 33 (2/6) | 75 (3/4) |
| Ankles (race 11 before 10) | 50 (6/12) | 60 (12/20) | 35 (7/20) | 50 (6/12) | 67 (8/12) | 58 (7/12) | 0 (0/6) | 33 (2/6) | 50 (2/4) |
| Midrange (fire, to 15) | 83 (10/12) | 75 (15/20) | 55 (11/20) | 50 (6/12) | 100 (12/12) | 75 (9/12) | 67 (4/6) | 33 (2/6) | 25 (1/4) |
| Freight (hold < 7, to 15) | 75 (9/12) | 65 (13/20) | 30 (6/20) | 58 (7/12) | 75 (9/12) | 75 (9/12) | 50 (3/6) | 33 (2/6) | 50 (2/4) |
| Eyes Closed (comeback 0-1, to 15) | 83 (10/12) | 75 (15/20) | 60 (12/20) | 25 (3/12) | 83 (10/12) | 75 (9/12) | 67 (4/6) | 50 (3/6) | 100 (4/4) |
| Lockbox (score 3, to 11) | 50 (6/12) | 50 (10/20) | 45 (9/20) | 67 (8/12) | 33 (4/12) | 33 (4/12) | 17 (1/6) | 17 (1/6) | 50 (2/4) |
| **Pooled, 6 challenges** | **63.9** (72) | **63.3** (120) | **44.2** (120) | **47.2** (72) | **72.2** (72) | **62.5** (72) | **38.9** (36) | **33.3** (36) | **58.3** (24) |
| Finale (to 21) | 83 (10/12) | 70 (14/20) | 35 (7/20) | 17 (2/12) | 65 (13/20) | 60 (12/20) | 50 (3/6) | 50 (3/6) | 75 (3/4) |

The SE is about 11 points on a 20-game cell, 14 on 12 games and 20 on 6. Pooled: about 4.5 on 120 games and 5.7 on 72.

How the games were failed (final values, every cell): Rooftop on stops 16 times ("ONLY n OF 2 STOPS ON ROOFTOP"),
the rest plain losses. Ankles always "ANKLES'S CREW GOT 10" (see the bugs). Freight broke his goal 11 times ("FREIGHT
SCORED 7"). Lockbox "YOU SCORED n OF 4" 39 times as played (re-judged at 3 in the table). Midrange (fire), Eyes Closed (comeback) and the finale fail by losing.
The baseline logs show every type both met and failed too.

Crews in these runs. Expected: `ud_deuce 70/71/72/72/71, ud_jojo 71/71/73/71/72, ud_tank 69/68/68/70/69`. Kings:
`ud_jojo 60/48/44/48/52, ud_tank 42/38/62/58/48, ud_deuce 50/60/46/46/48`. Mid-trip (36 stars, after Seattle):
`ud_deuce 67/68/66/66/65, lg_steeple 83/83/95/88/82, ht_boss 72/69/69/69/69`. Chapter 2 opponents on Normal (final):
Rooftop 79/69/84/59/54 with Eyes Closed 60/55/50/50/60 and Freight 40/40/80/65/50. Ankles 84/74/64/64/59. Midrange
69/89/69/59/59. Freight 54/54/94/79/64. Eyes Closed 74/69/64/64/74. Lockbox 74/59/64/89/59.

## Checks

| Check | Result |
|---|---|
| Import, `--legendtest` | PASS (clean; LEGENDTEST OK with the final values) |
| Every game ends, no errors, no shot-clock violations | PASS (1,961 / 1,961; 0 errors; 0 violations; 1.6 interceptions a game) |
| Expected crew, Normal about 60-65% | PASS: 63.3% (120) |
| Expected crew, Hard about 40% | PASS, at the top: 44.2% (120), about 1 SE over 40. With Lockbox at 4 it would be 39.2%. |
| Expected crew, Easy (60-75) | PASS: 63.9% (72) |
| Harder level = lower share (expected) | **Partly.** Normal > Hard clearly (63 vs 44). Easy (63.9) and Normal (63.3) can't be told apart. LEGEND (47.2, 72 games) is not under Hard (44.2). Both are inside 1 SE. On the best crew: 72 > 62.5 > 39 (PASS). Finale: 83 > 70 > 35 > 17 (PASS). |
| Best crew wins more | PASS: Normal 72 vs 63, Hard 62.5 vs 44. Finale Hard 60 vs 35. Finale Normal 65 vs 70 is inside the noise. |
| RED >= 20% against the best crew on Hard | PASS: challenges RED 37.5%, finale RED 40% |
| Every goal type met and failed in the logs | PASS: stop, race, fire, hold, comeback and score are all met and all failed |
| Every challenge winnable (no cell near 0) | PASS on E/N/H. The lowest 20-game cell is Freight Hard at 30%. Ankles on LEGEND with the best crew was 0/6 (a 6-game cell; Hard best was 58%). |
| Finale shapes hold | PASS: 2 stats at the 95 cap on E/N/H (Midrange shooting, Freight finishing) |
| Kings fallback (no trip), Normal | 33% (12/36), finale 3/6. Lower than Chapter 1's Kings (P9-26: 42%, finale 1/6). |
| Mid-trip crew, 36-star stage (fixture `trip_v2_legend.json`), Normal | 58% (14/24), finale 3/4. Chapter 2 opens at 36 stars, so this is the crew that first meets it. |
| `--humantest` | 37 runs (Lockbox Normal 26 and Hard 9 over the three rating steps; Rooftop 1, Eyes Closed 1). All ended. The Lockbox HUD reads "SCORE 3 ON LOCKBOX: n". |
| Screenshot | One `--shots --challenge lg_lockbox --expected-roster` run under xvfb (3 frames). The goal line "SCORE 3 ON LOCKBOX: 0" is readable under the top bar. The HUD, the buttons and the 1280x720 frame are fine, and nothing is off screen. The only error was the ALSA audio device (no sound card in xvfb). |

## Chapter 1 (P10-N2)

Expected crew, against P10-08 (the last Chapter 1 measure). No Chapter 1 number was changed.

| Challenge | Normal now | Normal P10-08 | Hard now | Hard P10-08 |
|---|---|---|---|---|
| Steeple (hold < 7) | 65 (13/20) | 85 | 65 (13/20) | 35 |
| Gate (race 11 before 10) | 40 (8/20) | 50 | 40 (8/20) | 45 |
| Set Shot (fire) | 60 (12/20) | 70 | 40 (8/20) | 40 |
| Boxcar (stop x2) | 65 (13/20) | 55 | 45 (9/20) | 37.5 |
| Velvet (hold < 6, to 11) | 55 (11/20) | 75 | 70 (14/20) | 57.5 |
| Quarterback (comeback 0-2) | **52.5 (21/40)** | 30 | **35 (14/40)** | 15 |
| **Pooled** | **55.7% (140)** | 61.9% (160) | **47.1% (140)** | 40.6% (160) |
| Finale | 60 (12/20) | 80 | **62.5 (25/40)** | 30 |

- **No measurable change.** The pooled shares moved -6.2 on Normal and +6.5 on Hard. Each is about 1.1 SE, in opposite
  directions. Single cells swing the way 20-game cells do (Steeple Hard 35 -> 65 is the largest, at 2 SE). The
  expected crew holds no legend, so P10-N1 doesn't touch these games.
- **Quarterback did not confirm.** It was 52.5% on Normal and 35% on Hard on 40 games each (P10-08: 30 / 15 on 20).
  So `start_score` stays **[0, 2]**: I did not apply the [0, 1] change. Across P9-26, P9-34, P10-08 and now, Normal
  reads 60 / 50 / 30 / 52.5 and Hard 25 / 40 / 15 / 35.
- **Boxcar on Easy: 70% (28/40),** inside 65-80 (P10-08: 52.5%). Of the 12 failures, 6 were lost on stops ("ONLY n
  OF 2"). No change.
- **The Chapter 1 finale on Hard was 62.5% (25/40),** above the 35-50 band. It has read 45 (P9-26, 20 games), 30
  (P10-08, 20) and now 62.5 (40). That pools to 50% (40/80), at the top of the band. I made no change, because the
  brief allows no other Chapter 1 change without asking. Watch item: if the lead wants it lower, raise
  `FINALE_STAGE_AVG` 52 -> 55. In Chapter 2, +4 on the finale base took Hard from 54% to 35%, although part of that
  drop may be noise.
- **The best crew under the P10-N1 rule (Grandfathers only),** 10 games a cell: Normal 65% (39/60), Hard 71.7%
  (43/60), finale 60 / 80. P9-26 measured 68 / 71 and finale 80 / 80, so it matches Phase 9 again.
  - Normal: Steeple 90, Gate 60, Set Shot 50, Boxcar 60, Velvet 50, Quarterback 80.
  - Hard: Steeple 90, Gate 50, Set Shot 90, Boxcar 70, Velvet 80, Quarterback 50.

## Bugs

1. **Low (text), `scripts/challenge.gd` lines 158 and 239: "ANKLES'S CREW".** Steps: `--autoplay --challenge
   lg_ankles`. Expected: "REACH 11 BEFORE ANKLES' CREW GETS 10" (the data line in `legends_data.gd` writes it that
   way). Actual: the HUD line and the failure reason add "'S" to any name: "REACH 11 BEFORE ANKLES'S CREW GETS 10",
   "ANKLES'S CREW GOT 10". Fix: write only an apostrophe when the name ends in S. Gate's "GATE'S" is right.
2. **Note (measurement): the score goal in `--best-roster` runs.** `end_of_trip_crew(true)` puts the drafted legend
   first (YOU). In Lockbox's challenge that is Eyes Closed, a pass-first player, so the best crew meets the score goal
   less often than the expected crew (33 vs 50% on Normal). No game bug. A real lineup lets the player pick YOU.

## Stale text for P10-29 (`scripts/story_text.gd`; I did not edit it)

Made stale by this task:
- line 463 (comment): "start down 0-2" -> 0-1
- line 466: "Down two before the tip, and you came back." (Eyes Closed, now down one)
- line 468: "Down two is how we start every morning, Mr. Pemberton." (now down one)
- line 477 (comment): "score 6 points yourself" -> 3
- line 480: "Six points. You, yourself, on me. ... and you still got six." (Lockbox, now 3)

Still right: line 414 "Twice" (Rooftop's 2 stops), line 426 "Eleven before ten" (Ankles), line 454 "Under seven"
(Freight), line 496 "to twenty-one" (the finale).

Older comment-only lines, stale since P9-26 (the spoken lines are right): line 278 "hold him under 6" (now 7), 290
"his crew gets 7" (10), 316 "3 blocks or steals" (2), 330 "hold him under 5" (6), 344 "start down 0-6" (0-2).

Elsewhere:
- `docs/legends-plan.md` lines 383-384 (Eyes Closed 0-2, Lockbox "at least 6").
- `docs/BOARD.md` line 87 (the HUD example "SCORE 6 ON LOCKBOX: 2").
- `CLAUDE.md`'s `--best-roster` paragraph ("every built legend counts as draftable"): since P10-N1 that is true only
  for `--city` runs; a `--challenge` run drafts from the chapters up to its own. I did not edit `CLAUDE.md`.

## Suggestions for the lead

1. Show the owner Lockbox's 3 (F3 a said 6+) and Eyes Closed's 0-1, and send the story lines above to P10-29.
2. The levels separate less in Chapter 2 than in Chapter 1. Easy and Normal read the same (64 / 63), and on Hard
   Ankles, Eyes Closed and Freight sit near their Normal cells in some batches. The data keys move every level
   together, so they can place the average but not widen the gap. If the owner wants Easy clearly easier, the lever
   is code: per-level goal numbers in `challenge.gd`, or a level rating offset in `legends.gd`, not a constant here.
3. The Chapter 1 finale on Hard is a watch item. It pools to 50% over 80 games. `FINALE_STAGE_AVG` 52 -> 55 would
   need asking first, and 40 games on each level to measure.
4. Fix the "ANKLES'S" text (bug 1) with the P10-29 text pass.

The logs, the job lists and the tally scripts (`run.py`, `tally.py`, `final.py`) are in my scratch folder
`p1023/w`, which is not in the repo.
