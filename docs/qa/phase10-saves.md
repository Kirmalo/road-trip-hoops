# P10-27: save QA (old saves in the Phase 10 build, Phase 10 Fathers files in the Phase 9 build, legends.json)

- **Build tested:** `7e38b7a` (branch `ccr-f5c087b2-3ojk5f`, after P10-25), Godot 4.3 stable, Linux.
- **Phase 9 build:** `git archive a1dc3c7`.
- **Isolation:** each build is a `git archive` copy in my scratch folder with its own `config/name` ("RTH P1027 New",
  "RTH P1027 Old"); every run had a fresh `XDG_DATA_HOME` of its own (one shared dir only for the "does a test
  touch the real files" runs, see 5). The default `Road Trip Hoops` user dir was checked by md5 before and after:
  unchanged (`settings.cfg`, `settings_test.cfg`, `trip_test.json`; it has no `legends.json`). At most 2 Godot
  processes at a time.
- **Scratch-only additions** (never in the repo): the P9-31 tap autoload `tapdrv.gd` (taps a Button by its text with
  real mouse events, saves screenshots) for the real-name runs; `mk_p10.gd` (makes the Phase 10 files with the
  game's own calls); `probe.gd` (loads the given legends.json / trip.json / settings.cfg under the real names and
  prints what the game sees; `WRITE=1` saves once, `ASSIGN=lg:pid` trains first). No game script was changed.
- **Import:** both copies exit 0, no script errors.

## The Phase 10 files (made in the Phase 10 build, real file names)
`mk_p10.gd` starts from the P10-01 story (`trip_v2_legend.json`, `settings_v2_36.cfg`, `legends_v1_ch1_done.json`)
and makes the calls the screens make:
- Legends: Fathers intro seen; ROOFTOP won on Normal (2), ANKLES on Hard (3), MIDRANGE failed once (score won, goal
  broken: 0) then won on Normal (2), FREIGHT lost (0). 9 unlocked, 28 tokens (Grandfathers 21 + Fathers 7).
  Mentors: GATE -> Deuce (P10-01), ANKLES -> MAYOR (`ht_boss`, starter, perk `handle`), ROOFTOP -> NICO (`chi_g1`,
  bench, perk `rise_up`). -> `legends_p10.json`
- Trip: MIDRANGE (`lg_midrange`) drafted into the third star slot (via "draft", 0 points, 95/93/93/83/83), 0 open.
  Three trip files: **bench** (MIDRANGE on the bench, Deuce + STEEPLE + MAYOR start), **you** (MIDRANGE is you, with
  MAYOR and Deuce), **start** (Deuce, MIDRANGE, MAYOR; Los Angeles game 1 then won with him: on the map before LA
  game 2, record 19-2). The trip calls did not touch `legends.json`.
- Built by hand from `legends_p10.json` for the extreme case: `fathers_done.json` (all 6 Fathers at 3, `fin:fathers` 3,
  `finales ["grand", "fathers"]`).

## 1. Every old fixture loads and plays on in Phase 10 (`--trip-test --target 3 --trip-resume`, fixture as `trip_test.json`)
`settings_test.cfg`: none for the 1.0.0 fixtures; `trip_v2_mid` a `[stars]` section with its 7 paid games at 2;
`trip_v2_done` `settings_v2_72.cfg`; the P10-01 trip `settings_v2_36.cfg` plus its Legends file as `legends_test.json`.
No `--stars` (P10-B1 is fixed).

| Fixture | Resumes on | Games | End | Exit |
|---|---|---|---|---|
| `trip_v1_chicago.json` | chicago game 2, map | 33 | TRIP END complete, 24-13 (a replay, a draft) | 0 |
| `trip_v1_points.json` | memphis game 3, points | 33 | TRIP END complete, 24-18 | 0 |
| `trip_v1_bosses.json` | new_orleans game 2, map (3 bosses repaired to 1) | 31 | TRIP END complete, 24-17 | 0 |
| `trip_v1_ny.json` | new_york game 2, bracket | 3 | TRIP END complete, 24-3 | 0 |
| `trip_v1_done.json` | done: map -> title | 0 | TRIP END complete, 24-22 (P9-B1 gone) | 0 |
| `trip_v2_mid.json` | memphis game 2, map, MAYOR starting | 38 | TRIP END complete, 24-21 | 0 |
| `trip_v2_done.json` | done, replay mode -> title | 0 | TRIP END complete, 24-1, the 4 drafts kept | 0 |
| `trip_v2_legend.json` + `legends_v1_mid.json` | los_angeles game 1, STEEPLE + MAYOR start | 8 | TRIP END complete, 24-3, GATE drafted from the LEGENDS row; Deuce's `PERK block_timing` in play | 0 |
| `trip_v2_legend.json` + `legends_v1_ch1_done.json` | same | 16 | TRIP END complete, 24-11 | 0 |

- `check_fixtures_v2.gd` and `check_fixtures_v3.gd` (P9-01's and P10-01's checks) in the Phase 10 build: **CHECK OK**
  both.
- No `SCRIPT ERROR`, `ERROR` or `WARNING` lines in the 9 logs; the `legends_test.json` given was byte for byte the same
  after each run.

## 2. The Phase 10 files in the Phase 9 build (`a1dc3c7`)
Probe (real names, each trip with `legends_p10.json` and `settings_p10.cfg`, 38 stars):

| | Phase 10 build (reference) | Phase 9 build |
|---|---|---|
| tokens shown | 28/42 (grand 21, fathers 7) | **21/21** (the Fathers tokens are kept in the file, not counted) |
| unlocked legends | 9 | 6 (the three Fathers ignored) |
| MAYOR's / NICO's perk (Fathers mentors) | `handle` / `rise_up` | **none** (pair ignored); Deuce keeps GATE's `block_timing` |
| draft's LEGENDS rows | Grandfathers row + Fathers row | the Grandfathers row only |
| **bench** trip | 12 players, starters Deuce/STEEPLE/MAYOR, 0 open | MIDRANGE **dropped**: 11 players, 1 slot open, starters kept |
| **start** trip | Deuce/MIDRANGE/MAYOR | MIDRANGE dropped; starters reset to Deuce/Jojo/Tank (STEEPLE and MAYOR go to the bench) |
| **you** trip | MIDRANGE you | MIDRANGE dropped; starters reset to Deuce (you)/Jojo/Tank |
| a Fathers challenge (`match_for_challenge("lg_rooftop")`) | the match | {} (unknown id, nothing built) |
| files after loading | unchanged | unchanged (loading writes nothing) |

Real names under xvfb in the Phase 9 build (screenshots checked):

| Run | Result |
|---|---|
| ROAD TRIP -> CONTINUE -> GO (start trip) | map -> lineup "You play DEUCE", LOS ANGELES GAME 2, open slot, MAYOR drafted. **No error dialog**, no script error |
| same, then PLAY | the game starts (beach court, LA game 2). trip.json re-saved: version 2, no `lg_midrange`, starters the 3 underdogs; `legends.json`, `settings.cfg` byte for byte the same |
| LEGENDS -> HALL | timeline "TOKENS 21/21", Chapter 2 "COMING LATER"; Hall 6/6, 21/21. With `fathers_done.json` (all Fathers, `fin:fathers`, `finales` with "fathers") the same: 21/21, Chapter 2 still COMING LATER |
| HALL -> TRAIN (STEEPLE) | the picker lists the roster; MAYOR shows **"TRAINED BY LG_ANKLES"**, NICO **"TRAINED BY LG_ROOFTOP"** (raw ids; cosmetic, the old build can't be fixed; the same code in Phase 10 is P10-B2) |
| ROAD TRIP -> NEW TRIP -> START OVER -> NORMAL | the trip-start story; `legends.json` byte for byte the same |

Headless play-on in the Phase 9 build (each Phase 10 trip as `trip_test.json`, `legends_p10.json` as `legends_test.json`):
- Without `--stars`: **TRIP ERROR** "the legend draft did not sign lg_gate ..." on the first lineup: that is P10-B1,
  which `a1dc3c7` still has (MIDRANGE dropped leaves a slot open, so the old driver's draft test runs). Not the save.
- With `--stars 24` (the P10-01 workaround): **TRIP END complete** for all three: bench 12 games 24-7 (STEEPLE and
  MAYOR start throughout), start 10 games 24-6, you 10 games 24-5. Only `PERK block_timing` (GATE) lines, no Fathers
  perk. `legends_test.json` unchanged.

What the Phase 9 build writes when it does write Legends (`probe.gd WRITE=1`): every Fathers key survives (tokens,
`unlocked`, `seen`, the two mentor pairs), version 1. A TRAIN there that takes a Fathers pupil (`assign("lg_steeple",
"ht_boss")`) frees ANKLES, as the switch rule says.

## 3. Reopened in the Phase 10 build (what survived)
| Files | Phase 10 build sees |
|---|---|
| Phase 9's re-saved trip (after PLAY) + `legends_p10.json` | CONTINUE -> map -> lineup with no errors: Los Angeles game 2, 11 players, 1 open slot, starters the 3 underdogs (as the old build saved them). **Lost:** MIDRANGE on the roster and the lineup. **Kept:** he is still unlocked and is back in the draft's Fathers row (with ROOFTOP and ANKLES); all tokens (28/42); all three mentor pairs and their perks |
| Phase 9's `WRITE=1` legends.json + trip | 28/42 tokens, 9 unlocked, mentors and perks as before: nothing lost in Legends |
| Phase 9's legends.json after the STEEPLE -> MAYOR switch | MAYOR has STEEPLE's `close_touch`, ANKLES is free, NICO keeps ROOFTOP |

So the only loss going through a Phase 9 build is the drafted Father (and, when he started, the lineup). Expected: the
old build can't know him; nothing to fix in Phase 10.

## 4. legends.json missing, broken, empty, garbage, not an object, oversized, newer (Phase 10 build, real names)
Each variant as `user://legends.json` with the **bench** trip (MIDRANGE drafted) and `settings_p10.cfg`. Per variant: the
probe, the probe with one `Legends.save()`, and two GUI runs (title -> LEGENDS -> HALL -> TRAIN; title -> ROAD TRIP ->
CONTINUE -> GO).

| Variant | `read()` | State | GUI | File after the GUI runs | After one `save()` |
|---|---|---|---|---|---|
| missing | {} "no save" | fresh: 0/42, none unlocked, no perks | timeline, Hall, lineup: OK | none written | blank version 1 |
| broken (first 300 bytes) | {} "not JSON" | fresh | OK | unchanged | blank |
| empty (0 bytes) | {} "bad size 0" | fresh | OK | unchanged | blank |
| garbage (3000 random bytes) | {} "not JSON" | fresh (272 "Unicode parsing error" log lines, as in P9-31) | OK | unchanged | blank |
| `[1,2,3]` | {} "not an object" | fresh | OK | unchanged | blank |
| oversized (valid JSON + 250 KB spaces) | {} "bad size 250790" | fresh | OK | unchanged | blank |
| newer (version 2, extra fields, `lg_future` and `fin:present` tokens, `lg:lg_lockbox` 9, `xp:` key, `finales` + "fathers", "present", `lg_future` -> Jojo, `lg_lockbox` -> Deuce next to GATE -> Deuce, a `{"id"}` scene) | loads | known keys kept, `lockbox` 9 -> 3, `xp:` key and the `{"id"}` scene dropped; LOCKBOX -> Deuce dropped (one mentor a player: GATE kept); `lg_future` kept but ignored | timeline **TOKENS 34/42** (grand 21 + fathers 13: unknown keys not counted, P9-B2 fix holds), Hall 10/12; Chapter 2 "FINALE WON" with 4 of 6 (file data, harmless, as P9-31 noted for Chapter 1); TRAIN picker shows Jojo **"TRAINED BY LG_FUTURE"** (P10-B2) | unchanged | version 1; unknown fields gone, `lg_future`, `fin:present` and the `lg_future` pair kept |

- No crash and no `SCRIPT ERROR` in the 14 GUI runs or 14 probes. Only `ERROR` lines: the container's ALSA audio and
  "2 resources still in use at exit".
- MIDRANGE (drafted) stays on the roster whatever the file says (missing, broken, ...), as the contract says.
- With no legend unlocked the Hall has no TRAIN button (the tap driver timed out waiting for it; expected).

## 5. NEW TRIP keeps legends.json; no test touches the real files
NEW TRIP (Phase 10, real names, xvfb: ROAD TRIP -> NEW TRIP -> START OVER -> NORMAL): `legends.json` byte for byte the
same; the new trip is at Hometown with the 3 underdogs, 3 open slots; Deuce still has GATE's perk; the draft offers both
LEGENDS rows (6 Grandfathers; ROOFTOP, ANKLES, MIDRANGE). The MAYOR and NICO pairs stay in the file (not on this roster).

One isolated user dir seeded with real-name files (`legends_p10.json`, the **start** trip, `settings_p10.cfg`); md5 of the
three before and after each run:

| Run | Result | Real files |
|---|---|---|
| `--legendtest` | LEGENDTEST OK | same |
| `--startest`, `--cosmetictest`, `--ratingtest`, `--twisttest` | OK | same |
| `--triptest-data`, `--triptest-data --load` | TRIPDATA OK | same |
| `--trip-test --target 3 --trip-stop-after chicago` | TRIP STOP after chicago | same |
| `--titletest --stars 36` | TITLE TEST DONE, "settings.cfg put back as it was: true" | same |
| `--backtest --stars 36 --tokens 12` | BACKTEST OK | same |
| `--legends-test --stars 36 --target 3` | LEGENDS END, crew kings, 20 games, grand 14/21, fathers 14/21 | same |
| `--legends-test --stars 36 --target 3` after a `--trip-stop-after chicago` (own dir) | LEGENDS END, crew trip, 20 games | same |
| `--challenge rooftop --autoplay` | CHALLENGE lg_rooftop hard met 15-14 (stop 3/2), crew kings, twist and look `era_fathers` | same |
| `--autoplay` x5, `--humantest` x2, `--shots` | below | same |

My first `--legends-test` ran **at the same time as** `--backtest` in that same user dir and ended "LEGENDS ERROR: ... the
trip save changed": the backtest wrote `trip_test.json` while the legends test checked it. My mistake, not a bug; alone it
passes (above).

## 6. General pass (Quick Game, Hard, Kings vs Bridge Runners, gym)
| Run | Final | Length | Shots (made) | FG% | Fouls B/R | FT | Out of bounds | Intercepts | Shot clock | Switches | OREB |
|---|---|---|---|---|---|---|---|---|---|---|---|
| autoplay 1 | 17-21 | 10:12 | 66 (36) | 55% | 1/0 | 1/1 | 1 | 1 | 0 | 1 | 28% |
| autoplay 2 | 18-21 | 9:26 | 58 (33) | 57% | 0/1 | 1/1 | 1 | 3 | 0 | 1 | 48% |
| autoplay 3 | 16-21 | 7:25 | 43 (29) | 67% | 1/0 | 1/1 | 0 | 1 | 0 | 1 | 14% |
| autoplay 4 | 21-14 | 8:25 | 52 (27) | 52% | 1/2 | 2/2 | 1 | 1 | 0 | 1 | 20% |
| autoplay 5 | 21-17 | 8:18 | 55 (32) | 58% | 2/2 | 2/2 | 1 | 2 | 0 | 1 | 44% |
| **autoplay mean (range)** | loser 16.4 (14-18), BLUE 2 of 5 | 8:45 (7:25-10:12) | 55 (43-66) | 57% (52-67) | 2.0 (1-4) | | 0.8 (0-1) | 1.6 (1-3) | 0 | 1 | 31% (14-48) |
| humantest 1 | 21-17 | 8:04 | 70 (37) | 53% | 0/0 | 0/0 | 3 | 5 | 0 | 1 | 30% |
| humantest 2 | 21-10 | 5:23 | 42 (30) | 71% | 1/2 | 1/2 | 1 | 3 | 0 | 1 | 17% |

- Inside the CLAUDE.md targets on the means. Autoplay 3 (43 shots at 67%) and humantest 2 (42 shots, 5:23, loser 10) are
  short hot games, one each; 5 games can't show a trend and this task changed no gameplay. No shot-clock violations,
  every game ended, no stuck ball or players.
- Screenshot (gym, 1280x720): HUD readable, pause button and both touch buttons clear of the play.
- No tuning suggested.

## Pass / fail
| Check | Result |
|---|---|
| Import, no script errors (both builds) | PASS |
| Every 1.0.0 fixture loads and plays on to TRIP END (Phase 10) | PASS (5/5, `trip_v1_done` too now) |
| Every Phase 8 fixture loads and plays on; `check_fixtures_v2` | PASS (2/2, CHECK OK) |
| The P10-01 fixtures load and play on (both Legends files); `check_fixtures_v3` | PASS (2/2, CHECK OK, plain resume) |
| Phase 10 files in Phase 9: no error dialog | PASS (lineup, game, Legends, Hall, mentor picker, NEW TRIP) |
| ... the unknown legend dropped from the trip | PASS (bench, start, you) |
| ... his tokens not counted | PASS (21/21 also with every Fathers token and `fin:fathers`) |
| ... his mentor pairs ignored | PASS (no perk, no PERK line); the picker shows the raw id (cosmetic, old build) |
| ... plays on | PASS (TRIP END x3 with `--stars 24`; plain resume hits P10-B1 of `a1dc3c7`) |
| Reopened in Phase 10: what survived | Legends all kept; the drafted Father lost (back in the draft); lineup as the old build saved it |
| legends.json missing / broken / empty / garbage / not an object / oversized / newer: no crash | PASS |
| The drafted Father stays when legends.json is missing or broken | PASS |
| NEW TRIP keeps legends.json (both builds) | PASS (byte for byte) |
| No test touches legends.json, trip.json, settings.cfg; owner's user dir untouched | PASS (16 kinds of run) |
| `--trip-resume` of a save where a legend is YOU (Phase 10 driver) | **FAIL** (test driver only): P10-B3 |
| Mentor label for an unknown legend id (Phase 10 Hall) | **FAIL** (minor, cosmetic): P10-B2 |

## Bugs
### P10-B2: the mentor picker shows a raw id for a mentor this build doesn't know
- **Steps:** a legends.json with a mentor pair whose legend this build has no row for (a newer build's file, or Phase 10
  files opened in Phase 9), e.g. `"mentors": {"lg_future": "ud_jojo"}`, Jojo on the trip. LEGENDS -> HALL -> a beaten
  legend -> TRAIN.
- **Expected:** a plain label (Jojo free to train, or "TRAINED BY A LEGEND").
- **Actual:** Jojo's tile says "TRAINED BY LG_FUTURE". `hall.gd` `legend_name(id)` falls back to the id. In the Phase 9
  build with Phase 10 files: "TRAINED BY LG_ANKLES", "TRAINED BY LG_ROOFTOP". The pair gives no perk (right), and picking
  him for a known legend frees it (the switch rule).
- **Severity:** low (cosmetic; needs a newer build's file). Phase 9 can't be fixed; this keeps the next chapter's files
  from showing raw ids in Phase 10.
- **Suggested fix (`scripts/hall.gd`):** in the picker, when `LegendsData.is_legend_id(mentor)` is false, show the tile as
  "NO MENTOR" (or "TRAINED BY A LEGEND"); keep the pair in the file (it is the newer build's).

### P10-B3: `--trip-resume` fails on a save where a drafted legend is YOU (test driver)
- **Steps:** a trip whose `human` is a drafted legend (made with the game's own `Trip.set_starters(["lg_midrange",
  "ht_boss", "ud_deuce"], "lg_midrange")`, which the lineup allows) as `user://trip_test.json`, then
  `--trip-test --target 3 --trip-resume`.
- **Expected:** TRIP END (the save is legal and plays: a real-name GUI run starts LA game 1 with MIDRANGE as you).
- **Actual:** the first game ends "TRIP ERROR: the driver made a legend YOU (lg_midrange): a legend run keeps you on a
  player you picked", exit 1. The check (`trip_test.gd`, the `Trip.is_legend(str(mine[0]))` line in the game check) is
  meant for the driver's own picks, but the lineup came from the save.
- **Severity:** low (test only; anyone resuming such a save gets a false failure).
- **Suggested fix (`scripts/trip_test.gd`):** fail only when the driver itself picked that lineup (e.g. a flag set where
  the driver taps the starters), or on resume, let the lineup visit repick YOU to the first non-legend starter.

## Notes (not bugs)
- **Going through a Phase 9 build loses the drafted Father** (and, if he started, the whole lineup goes back to the 3
  underdogs with no note, like Phase 8 did with STEEPLE). His slot opens; he stays unlocked and can be drafted again in
  Phase 10, at his ratings for the stage reached. Own points: he had 0.
- **A broken legends.json is replaced on the next Legends write**, as in Phase 9 (P9-31 note). Still true.
- `fathers_done.json` / the newer file show "FINALE WON" from the file's `finales` even with Fathers missing: data from
  the file, harmless (P9-31 noted the same for Chapter 1).
- Fathers mentor perks in the trip tests: the perks reach the trip's players (probe: MAYOR `handle`, NICO `rise_up`), but
  no `PERK handle` / `rise_up` line came up in 29 short (to 3) trip games; `block_timing` did 6 times. How much they come
  up is P10-26's job, not a save problem.
- **Not tested:** the Phase 10 files in the 1.0.0 or Phase 8 builds (not asked; they drop unknown ids the same way, see
  P9-31 for Phase 8).
