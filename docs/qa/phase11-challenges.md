# P11-23 Phase 11 QA: Chapter 3 ("the Present") challenge balance

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `2565d73` (P11-12 SPACE THE FLOOR, P11-17 signature moves, P11-22
perks merged; the `era_present` numbers as P11-12 left them, P11-21 was measuring them in parallel), plus this task's
one change: Chapter 3's `finale_stage_avg` in `scripts/legends_data.gd`. Godot 4.3 stable (Linux), headless,
`--fixed-fps 60`.

**Setup:** two project copies outside the repo (each its own `config/name`), a fresh `XDG_DATA_HOME` for every game,
at most 2 Godot processes at once. Every game: `--autoplay --challenge <id> --difficulty <level> --no-countdown` plus
`--expected-roster` or `--best-roster` (`Trip.end_of_trip_crew()`). LEGEND: `--stars 72`. Kings: no roster flag, no
trip save. Mid-trip crew (48-star stage, the Chapter 3 gate): fixture `trip_v2_father.json` + `settings_v2_48.cfg` as the
test files. BLUE plays Hard in `--autoplay`; the level changes RED only. The step-back A/B used two more copies with
`SIG_STEP_BACK` renamed so no one matches it (scratch only, never committed).

**Games:** 1,210: 1,202 `--autoplay`, 8 `--humantest`. Every one reached `FINAL`, printed its `CHALLENGE` line and exited
0. 0 `SCRIPT ERROR` / `ERROR` lines (only xvfb's ALSA lines in the screenshot run), 0 shot-clock violations, exactly one
side switch in every game. Per game: 38.6 shots (13-80), FG 50.4%, 1.32 interceptions (max 9), 0.94 fouls, 0.74 out of
bounds, 5.6 steals, 5.2 blocks, OREB 22.2% of misses, loser 10.4 points. Game time: to 11, 4.0 min (1.9-7.9); to 15,
5.7 min (2.9-10.2); to 21, 7.8 min (4.4-11.8). No game came near `--quit-after`; no player or ball stuck.
Import clean. `--legendtest`: LEGENDTEST OK with the final values.

## Bands (owner P6 a, a step harder than Chapter 2)

| | Easy | Normal | Hard | Finale |
|---|---|---|---|---|
| Chapter 2 measured (P10-23 T2, expected crew) | 64 | 63 | 44 | N 70, H 35 |
| Chapter 3 target (P6 a) | above Normal | 55-60 | about 35 | a bit harder than Chapter 2's |
| Proposed bands for the lead | 60-75 | 50-62 | 33-45 | N 50-65, H 25-40 |

## Values

| Key (`present` row) | Before | After | Why |
|---|---|---|---|
| `challenge_avg` | 72 | **72** (kept) | Normal 50.0%, Hard 40.0% on 240 games each. A step either way moves both levels together (about 4 points per step in P10-23), so 71 would put Hard near 44 and 73 Normal near 46. 72 is the smallest total miss. |
| `mate_drop` | 14 | **14** (kept) | Same reason; mates at 58 + shape (Chapter 2: 55). |
| `finale_stage_avg` | 57 | **63** | At 57: N 75%, H 55%. At 60: N 63%, H 50%. At 63: **N 53%, H 33%** (30 games each), under Chapter 2's 70 / 35. Finale legends at 83 + shape: Deep End 88/95/73/73/73, Toolbox 88/83/88/83/73, Skylight 83/63/95/88/78 (Deep End's shooting and Skylight's finishing sit at the 95 cap; the shapes still read). |

No goal number changed: Deep End `cool_misses` 2, Toolbox `start_score` [0, 1], Stretch 11 before 10, Switch `min` 5,
Skylight `count` 2, Zigzag `limit` 6, every target as P3 a.

Opponents on Normal / Hard (challenge_avg 72, mates 58): Deep End 77/95/62/62/62 with Stretch 48/73/58/63/48 and Switch
63/53/58/73/43; Toolbox 77/72/77/72/62; Stretch 62/87/72/77/62; Switch 77/67/72/87/57; Skylight 72/52/92/77/67; Zigzag
82/67/82/62/67.

## Results: Chapter 3, BLUE met % (final values)

| Challenge (type) | Easy exp (12) | Normal exp (40) | Hard exp (40) | LEGEND exp (10) | Normal best (10) | Hard best (10) | Kings, Normal (6) | Mid-trip, Normal (6) |
|---|---|---|---|---|---|---|---|---|
| Deep End (fire, to 15) | 83 | 57.5 | 50 | 40 | 70 | 50 | 100 | 83 |
| Toolbox (comeback 0-1, to 15) | 67 | **77.5** | **35** | 50 | 100 | 60 | 83 | 67 |
| Stretch (race 11 before 10) | 75 | 60 | 47.5 | 60 | 60 | 50 | 67 | 50 |
| Switch (score 5, to 11) | 42 | **15** | **15** | 0 | 20 | 20 | 17 | 0 |
| Skylight (stop x2, to 15) | 50 | 37.5 | 37.5 | 40 | 40 | 50 | 33 | 50 |
| Zigzag (hold < 6, to 11) | 83 | 52.5 | 55 | 40 | 80 | 50 | 50 | 83 |
| **Pooled, 6 challenges** | **66.7** (72) | **50.0** (240) | **40.0** (240) | **38.3** (60) | **61.7** (60) | **46.7** (60) | **58.3** (36) | **55.6** (36) |
| The five without Switch | 71.7 | 57.0 | 45.0 | 46.0 | 70.0 | 52.0 | 66.7 | 66.7 |
| **Finale (to 21, at 63)** | 75 (12) | **53.3** (30) | **33.3** (30) | 50 (10) | 90 (10) | 90 (10) | 50 (6) | 50 (6) |

SE: about 7.8 on a 40-game cell, 3.2 on 240, 6 on 60, 8 on 36, 9 on 30.

How the games were failed: Skylight 29 times on stops ("ONLY n OF 2 STOPS ON SKYLIGHT"; on Normal his crew lost 67.5%
of the games but the goal was met only 37.5%), the rest plain losses. Stretch always "STRETCH'S CREW GOT 10". Zigzag
broke his goal 13 times ("ZIGZAG SCORED 6"). Switch "YOU SCORED n OF 5" 64 times. Deep End (fire), Toolbox
(comeback) and the finale fail by losing. Every goal type is met and failed in the logs.

### Checks

| Check | Result |
|---|---|
| Expected crew, Normal about 55-60% | **FAIL, 5 under:** 50.0% (240). The five without Switch: 57%. |
| Expected crew, Hard about 35% | **Near, 5 over:** 40.0% (240). |
| Harder level = lower share | PASS on the expected crew: Easy 66.7 > Normal 50.0 > Hard 40.0 >= LEGEND 38.3 (the last two inside 1 SE). Best crew 61.7 > 46.7. Finale 75 > 53 > 33; LEGEND 50 on 10 games is inside noise. |
| Finale a bit harder than Chapter 2's | PASS at 63: N 53 / H 33 against 70 / 35. |
| Best crew wins more | PASS: Normal 61.7 vs 50, Hard 46.7 vs 40, finale 90 vs 53 / 33. |
| RED >= 20% against the best crew on Hard | Challenges PASS (RED won 43%). Finale **watch**: RED won 1 of 10 (best crew `lg_eyes_closed` 95s, `la_boss` 93s, `ny_q1`). |
| Every goal type met and failed | PASS |
| Every challenge winnable | PASS. Lowest big cell: Switch 15% (by design, see below). |
| Signature moves seen (per game, the legend's own challenge, 80 games) | step-back 2.15 (stepback frames 2.15), coast 1.95, pop 6.1, steal and run 1.18, lob magnet 0.33, Euro-step 0.80 (eurostep frames 0.76) |
| `--humantest` | 8 runs (Switch Normal 6: met 1, the HUD reads "SCORE 5 ON SWITCH: n"; Deep End Normal 2: met 2). All ended. |
| Screenshot | `--shots --challenge lg_switch` (xvfb, 3 frames): the goal line "SCORE 5 ON SWITCH: 0" is readable under the top bar, the HUD, pause and A / B buttons are clear of the play, nothing is off screen at 1280x720. |
| Kings fallback, Normal | 58.3% (36), finale 3/6. Above the expected crew (50), about 1 SE; Chapter 2's Kings read 33%. A watch item, not a bug I can show. |
| Mid-trip crew at the gate (48 stars: Deuce, MIDRANGE, MAYOR) | 55.6% (36), finale 3/6. |

## The levels sit close together

Normal 50 and Hard 40 are 10 points apart (SE of the gap about 4.5). The owner's band wants about 20 (55-60 vs 35),
and Chapter 2 measured 19. `challenge_avg` and `mate_drop` move every level together, so they can place the middle
(the band's middle is about 46; we are at 45) but not open the gap. Per challenge, Toolbox opens it (77.5 vs 35) and
Zigzag does not at all (52.5 vs 55). The lever is code, not a constant here (P10-23 said the same): a per-level rating
offset for Legends opponents in `legends.gd` (e.g. Normal -3, Easy -6), or per-level goal numbers in `challenge.gd`.
That is a design call for the lead and the owner.

## The score goal (Switch, `min` 5)

Judged only at the end, so the games re-judge at any `min` (expected crew, 80 games: 40 Normal, 40 Hard). "You"
scored 3.2 of 10.1 on Normal, 2.9 of 9.3 on Hard.

| min | 3 | 4 | **5** | 6 |
|---|---|---|---|---|
| Normal (40) | 45 | 27.5 | **15** | 10 |
| Hard (40) | 40 | 32.5 | **15** | 5 |

At 5 it matches the owner's rule for the score goal (Phase 10: "the hardest, met about 17% or less"; Lockbox at 6 reads
5-25%). **Proposal (owner level):** keep 5. If the owner wants Chapter 3's Normal inside 55-60, `min` 4 adds about 2
points to the pooled Normal and Hard (to about 52 / 43) and makes Switch a ~30% challenge.

## The step-back (P11-17): not too strong in CPU hands

| Deep End's challenge, expected crew | games | met | Deep End pts | RED FG | RED threes |
|---|---|---|---|---|---|
| step-back on (today) | 80 | 53.75% | 5.5 | 49.5% | 46.7% (7.4 a game) |
| step-back off (scratch copy) | 40 | 65.0% | 5.0 | 48.0% | 43.4% (7.5 a game) |

- 2.15 step-backs a game to 15 (1.44 CPU rolls after his crossover); 172 seen, 123 of them threes. The odds gain on the
  shot: x1.12 (94), x1.24 (39), x1.00 (39, no contest to remove).
- The move is worth about half a point a game to him and ~11 points of met share (about 1.1 SE). That is a small edge,
  as P4 meant. No change.
- **Watch, human hands:** a human Deep End (a drafted legend as YOU) can cross and shoot every time. Not measured (the
  scripted thumb does not do it). If it plays too strong: `STEP_BACK_KEEP` 0.5 -> 0.65 (player.gd), or for the CPU
  `STEP_BACK_CPU_CHANCE` 0.7 -> 0.5.

## Chapters 1-2 re-run (expected crew, 6 games a challenge; no number changed)

| | Normal now | Normal before | Hard now | Hard before |
|---|---|---|---|---|
| Chapter 1 pooled (36) | 47.2 | 55.7 (P10-23, 140) | 47.2 | 47.1 |
| Chapter 2 pooled (36) | 47.2 | 55.8 (P10-23 after the owner, 120) | 41.7 | 40.8 |

SE about 8.3 on 36 games: both Normal cells are about 1 SE under, Hard matches. P11-22 showed seeded Chapter 2 runs
byte for byte the base build's, so I read this as noise. The "ANKLES' CREW" text (P10-23 bug 1) is fixed.

**Phase 10 watch item (Lockbox, Chapter 2 Easy / Normal):** Lockbox met 0/6 on Normal, 1/6 on Hard (owner: about 17%
or less). Chapter 2 Normal without Lockbox: 57% (17/30). Still the same story: Lockbox alone pulls Chapter 2's Normal
under 60. No change (owner's choice).

## Bugs

None found. 0 errors, 0 stuck games.

## Stale story lines for P11-29

None. No goal number changed, so every Chapter 3 line in `scripts/story_text.gd` still matches: "Two misses in a row"
(Deep End), "Down one" (Toolbox), "Eleven before ten" (Stretch), "Five" (Switch), "Two stops" (Skylight), "Under six"
(Zigzag), "to twenty-one" (the finale). If the owner moves Switch to 4, `lg_switch_unlock` ("Five." x2) goes stale.

Doc text naming the first guess `72 / 14 / 57`: `docs/BOARD.md` lines 111, 245, 423 (history; the finale is 63 now).

## Suggestions for the lead

1. Accept 72 / 14 / 63 and the bands above, or ask the owner for the code lever (a per-level rating offset) if Normal
   must reach 55-60 while Hard stays near 35.
2. Switch `min` 5 stays unless the owner wants 4 (numbers above).
3. Step-back: no change; watch it in the owner's own play.
4. Watch the finale against the best crew on Hard (RED 1/10) and the Kings fallback (58%) in a later pass.
