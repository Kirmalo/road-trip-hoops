# P11-27: save QA (old saves in the Phase 11 build, Phase 11 Present files in the Phase 10 build, legends.json)

- **Build tested:** `67de993` (branch `ccr-f5c087b2-3ojk5f`, after P11-25), Godot 4.3 stable, Linux.
- **Phase 10 build:** `git archive 83520f8` (the P11-01 fixture build).
- **Isolation:** each build is a `git archive` copy in my scratch folder with its own `config/name` ("RTH P1127 New",
  "RTH P1127 Old"); every run had a fresh `XDG_DATA_HOME` of its own (two shared dirs only for the "does a test touch
  the real files" runs, see 5). The default `Road Trip Hoops` user dir was checked by md5 before and after: unchanged
  (`settings.cfg`, `settings_test.cfg`, `trip_test.json`; it has no `legends.json`). At most 2 Godot processes at a
  time.
- **Scratch-only additions** (never in the repo), the P10-27 tools carried over: the tap autoload `tapdrv.gd` (taps a
  Button by its text with real mouse events, saves screenshots); `mk_p11.gd` (makes the Phase 11 files with the game's
  own calls); `probe.gd` (loads the given legends.json / trip.json / settings.cfg under the real names and prints what
  the game sees; `WRITE=1` saves once, `ASSIGN=lg:pid` trains first). No game script was changed.
- **Import:** both copies exit 0, no script errors.

## The Phase 11 files (made in the Phase 11 build, real file names)
`mk_p11.gd` starts from the P11-01 story (`trip_v2_father.json`, `settings_v2_48.cfg`, `legends_v1_ch2_done.json`) and
makes the calls the screens make:
- Legends: 48 stars open Chapter 3; the Present intro seen; DEEP END won on Normal (2), TOOLBOX on Hard (3), STRETCH
  won with the goal broken (0) then won on Normal (2), SWITCH lost (0). 15 unlocked, 49 tokens (21 + 21 + Present 7).
  Mentors: GATE -> Deuce and ANKLES -> MAYOR (from P11-01), **TOOLBOX -> NICO** (`chi_g1`, bench, perk `extra_pass`).
  -> `legends_p11.json`
- Trip: DEEP END (`lg_deep_end`) drafted from the Present LEGENDS row into slot 4 (via "draft", 0 points,
  95/95/88/88/88), 0 open. Three trip files: **bench** (DEEP END on the bench; Deuce, MIDRANGE, MAYOR start), **you**
  (DEEP END is you, with MAYOR and Deuce), **start** (Deuce, DEEP END, MAYOR; New York round 1 then won: on the bracket
  before round 2, 22-3). The trip calls did not touch `legends.json` (byte for byte).
- Built by hand from `legends_p11.json` for the extreme case: `present_done.json` (all 6 Present legends at 3,
  `fin:present` 3, `finales ["grand", "fathers", "present"]`, 18 unlocked).

## 1. Every old fixture loads and plays on in Phase 11 (`--trip-test --target 3 --trip-resume`, fixture as `trip_test.json`)
`settings_test.cfg`: none for the 1.0.0 fixtures; `trip_v2_mid` a `[stars]` section with its 7 paid games at 2;
`trip_v2_done` `settings_v2_72.cfg`; the P10-01 trip `settings_v2_36.cfg`, the P11-01 trip `settings_v2_48.cfg`, each
with its Legends file as `legends_test.json`. No `--stars`.

| Fixture | Resumes on | Games | End | Exit |
|---|---|---|---|---|
| `trip_v1_chicago.json` | chicago game 2, map | 28 | TRIP END complete, 24-8, 26 stars (Easy) | 0 |
| `trip_v1_points.json` | memphis game 3, points | 26 | TRIP END complete, 24-11 | 0 |
| `trip_v1_bosses.json` | new_orleans game 2, map (3 bosses, one starts: "ONLY ONE BOSS CAN START") | 30 | TRIP END complete, 24-16, 72 stars | 0 |
| `trip_v1_ny.json` | new_york game 2, bracket | 3 | TRIP END complete, 24-3 | 0 |
| `trip_v1_done.json` | done: map -> title | 0 | TRIP END complete, 24-22 | 0 |
| `trip_v2_mid.json` | memphis game 2, map, MAYOR starting | 26 | TRIP END complete, 24-9 (a replay) | 0 |
| `trip_v2_done.json` | done, replay mode -> title | 0 | TRIP END complete, 24-1, the 4 drafts kept | 0 |
| `trip_v2_legend.json` + `legends_v1_mid.json` | los_angeles game 1, STEEPLE + MAYOR start | 18 | TRIP END complete, 24-13, GATE drafted from the LEGENDS row; 5 `PERK block_timing` lines | 0 |
| `trip_v2_legend.json` + `legends_v1_ch1_done.json` | same | 10 | TRIP END complete, 24-5 | 0 |
| `trip_v2_father.json` + `legends_v1_ch2_mid.json` | new_york game 1, MIDRANGE + MAYOR start | 6 | TRIP END complete, 24-5, ROOFTOP drafted into slot 4 | 0 |
| `trip_v2_father.json` + `legends_v1_ch2_done.json` | same | 4 | TRIP END complete, 24-3, ROOFTOP drafted | 0 |

- Every run: paid 24/24 and every game at the level's stars at TRIP END.
- `check_fixtures_v2.gd`, `_v3.gd` and `_v4.gd` (P9-01's, P10-01's and P11-01's checks) in the Phase 11 build: **CHECK OK**
  all three (v4: both Legends files load as saved, Deuce `block_timing`, MAYOR `handle`, the trip as saved, the
  Grandfathers and Fathers LEGENDS rows, the Fathers finale "MIDRANGE SITS: TREY PLAYS"; loading writes nothing).
  `check_fixtures_v1.gd` says "same state false" for the 1.0.0 trips, as in P9-31: it was written for the 1.0.0 build,
  and the Phase 8+ migration adds crew points, `paid` and `via`. Expected.
- No `SCRIPT ERROR`, `ERROR` or `WARNING` lines in the 11 logs; each given `legends_test.json` byte for byte the same
  after its run.

## 2. The Phase 11 files in the Phase 10 build (`83520f8`)
Probe (real names, each trip with `legends_p11.json` and `settings_p11.cfg`, 50 stars):

| | Phase 11 build (reference) | Phase 10 build |
|---|---|---|
| tokens shown | 49/63 (grand 21, fathers 21, present 7) | **42/42** (the Present tokens are kept in the file, not counted) |
| unlocked legends | 15 | 12 (the three Present legends ignored) |
| Chapter 3 | open (48 stars), 7/21 | gate met but not built: COMING LATER |
| NICO's perk (Present mentor TOOLBOX) | `extra_pass` | **none** (pair ignored); Deuce keeps `block_timing`, MAYOR `handle` |
| draft's LEGENDS rows | Grandfathers, Fathers, Present | Grandfathers + Fathers rows only |
| **bench** trip | 14 players, Deuce/MIDRANGE/MAYOR, 0 open | DEEP END **dropped**: 13 players, 1 slot open, starters kept |
| **start** trip | Deuce/DEEP END/MAYOR | DEEP END dropped; starters reset to Deuce/Jojo/Tank (MIDRANGE and MAYOR to the bench) |
| **you** trip | DEEP END you | DEEP END dropped; starters reset to Deuce (you)/Jojo/Tank |
| a Present challenge (`match_for_challenge("lg_deep_end")`) | the match ("DEEP END SITS: TREY PLAYS" when he starts) | {} (unknown id, nothing built) |
| files after loading | unchanged | unchanged (loading writes nothing) |

Real names under xvfb in the Phase 10 build (screenshots checked):

| Run | Result |
|---|---|
| ROAD TRIP -> CONTINUE -> GO -> PLAY (**you** trip) | map -> bracket -> lineup "You play DEUCE", NEW YORK QUARTERFINAL, Deuce/Jojo/Tank picked. **No error dialog**, no script error |
| ROAD TRIP -> CONTINUE -> PLAY -> PLAY (**start** trip) | bracket -> lineup -> the game starts (NY round 2 vs Bodega Bandits). trip.json re-saved: version 2, no `lg_deep_end`, starters the 3 underdogs; `legends.json`, `settings.cfg` byte for byte the same |
| ROAD TRIP -> CONTINUE -> GO -> PLAY (**bench** trip) | lineup with Deuce/MIDRANGE/MAYOR (kept), 1 open slot |
| LEGENDS -> HALL | timeline "TOKENS 42/42", Chapter 3 "COMING LATER 48 STARS OR 30 TOKENS"; Hall 12/12, 42/42. With `present_done.json` the same: 42/42, Chapter 3 still COMING LATER |
| HALL -> TRAIN (STEEPLE) | the picker lists the 11 non-legend players; NICO shows **"NO MENTOR"** (P10-B2's fix holds in the old build); Deuce "TRAINED BY GATE", MAYOR "TRAINED BY ANKLES" |
| ROAD TRIP -> NEW TRIP -> START OVER -> NORMAL | the trip-start story; `legends.json` byte for byte the same |

Headless play-on in the Phase 10 build (each Phase 11 trip as `trip_test.json`, `legends_p11.json` as
`legends_test.json`, `settings_p11.cfg`, no `--stars`): **TRIP END complete** for all three: bench 5 games 24-4, start
2 games 24-3, you 6 games 24-5 (the driver drafts ROOFTOP into the freed slot). Only `PERK block_timing` / `handle`
lines, no Present perk. Exit 0, no script errors, `legends_test.json` unchanged.

What the Phase 10 build writes when it does write Legends (`probe.gd WRITE=1`): every Present key survives (tokens
`lg:lg_deep_end` 2 / `lg_toolbox` 3 / `lg_stretch` 2, the 3 ids in `unlocked`, the 4 Present scenes in `seen`, the
TOOLBOX -> NICO pair), version 1. A TRAIN there that takes NICO (`assign("lg_steeple", "chi_g1")`) frees TOOLBOX, as
the switch rule says.

## 3. Reopened in the Phase 11 build (what survived)
| Files | Phase 11 build sees |
|---|---|
| Phase 10's re-saved **start** trip (after PLAY) + `legends_p11.json` | bracket, New York game 2, 13 players, 1 open slot, starters the 3 underdogs (as the old build saved them). **Lost:** DEEP END on the roster and the lineup. **Kept:** he is still unlocked and back in the draft's Present row (with TOOLBOX and STRETCH); all tokens (49/63); all three mentor pairs and their perks (NICO `extra_pass`) |
| Phase 10's `WRITE=1` legends.json | everything as before: nothing lost in Legends |

So the only loss going through a Phase 10 build is the drafted Present legend (and, when he started, the lineup), as
P10-27 found for a Father in Phase 9. Expected; nothing to fix in Phase 11.

## 4. legends.json missing, broken, empty, garbage, not an object, oversized, newer (Phase 11 build, real names)
Each variant as `user://legends.json` with the **bench** trip (DEEP END drafted) and `settings_p11.cfg`. Per variant: the
probe, the probe with one `Legends.save()`, and two GUI runs (title -> LEGENDS -> HALL -> TRAIN; title -> ROAD TRIP ->
CONTINUE -> GO -> PLAY to the lineup).

| Variant | `read()` | State | GUI | File after the GUI runs | After one `save()` |
|---|---|---|---|---|---|
| missing | {} "no save" | fresh: 0/63, none unlocked, no perks | timeline (3 chapters open by stars), Hall 0/18, lineup: OK | none written | blank version 1 |
| broken (first 300 bytes) | {} "not JSON" | fresh | OK | unchanged | blank |
| empty (0 bytes) | {} "bad size 0" | fresh | OK | unchanged | blank |
| garbage (3000 random bytes) | {} "not JSON" | fresh (44 "Unicode parsing error" lines) | OK | unchanged | blank |
| `[1,2,3]` | {} "not an object" | fresh | OK | unchanged | blank |
| oversized (valid JSON + 250 KB spaces) | {} "bad size 251254" | fresh | OK | unchanged | blank |
| newer (version 2, extra fields, `lg_future` and `fin:next` tokens, `lg:lg_zigzag` 9, `xp:` key, `finales` + "present", "next", `lg_future` -> Jojo, `lg_zigzag` -> Deuce next to GATE -> Deuce, a `{"id"}` scene) | loads | known keys kept, zigzag 9 -> 3, `xp:` key and the `{"id"}` scene dropped; ZIGZAG -> Deuce dropped (one mentor a player: GATE kept); `lg_future` kept but ignored | timeline **TOKENS 52/63** (Present 10: unknown keys not counted), Hall 16/18; Chapter 3 "FINALE WON" with 4 of 6 (file data, harmless, as in P9-31 / P10-27); TRAIN picker: Jojo **"NO MENTOR"**, NICO "TRAINED BY TOOLBOX" | unchanged | version 1; unknown fields gone, `lg_future`, `fin:next` and the `lg_future` pair kept |

- No crash and no `SCRIPT ERROR` in the 14 GUI runs or 14 probes. Only `ERROR` lines: the container's ALSA audio and
  "2 resources still in use at exit".
- DEEP END (drafted) stays on the roster and in the saved trip whatever the file says (missing, broken, garbage, ...).
- With no legend unlocked the Hall has no TRAIN button (the tap driver timed out waiting for it, 6 runs; expected).

## 5. NEW TRIP keeps legends.json; no test touches the real files
NEW TRIP (Phase 11, real names, xvfb: ROAD TRIP -> NEW TRIP -> START OVER -> NORMAL): `legends.json` byte for byte the
same; the new trip is at Hometown with the 3 underdogs, 4 open slots; Deuce still has GATE's perk; the draft offers all
three LEGENDS rows (6 Grandfathers; 6 Fathers; DEEP END, TOOLBOX, STRETCH). The MAYOR and NICO pairs stay in the file
(not on this roster). The Phase 10 build's NEW TRIP: the same (`legends.json` unchanged).

Two isolated user dirs (A and B, one process each), each seeded with real-name files (`legends_p11.json`, the **start**
trip, `settings_p11.cfg`); md5 of the three before and after each run:

| Run | Result | Real files |
|---|---|---|
| `--legendtest` | LEGENDTEST OK (era teams grandfathers, fathers, present OK) | same |
| `--startest`, `--cosmetictest`, `--ratingtest`, `--twisttest` | OK | same |
| `--triptest-data`, `--triptest-data --load` | TRIPDATA OK | same |
| `--titletest --stars 48` | TITLE TEST DONE, "settings.cfg put back as it was: true" | same |
| `--backtest` | BACKTEST OK (62 steps) | same |
| `--trip-test --target 3 --trip-stop-after chicago` | TRIP STOP after chicago, 6-2 | same |
| `--legends-test --stars 48 --target 3` after that stop (dir A) | LEGENDS END, crew trip, 30 games, grand / fathers / present 14/21 each | same |
| `--legends-test --stars 48 --target 3` (dir B, no trip) | LEGENDS END, crew kings, 30 games, 14/21 each | same |
| `--challenge deep_end --autoplay` | CHALLENGE lg_deep_end hard failed 5-16 (fire, Deep End 7 pts; crew kings, twist / look `era_present`, music `legends_present`) | same |
| `--autoplay` x5, `--humantest` x2, `--shots` | below | same |

## 6. General pass (Quick Game, Hard, Kings vs Bridge Runners, gym)
| Run | Final | Length | Shots (made) | FG% | Fouls B/R | FT | Out of bounds | Intercepts | Shot clock | Switches | OREB |
|---|---|---|---|---|---|---|---|---|---|---|---|
| autoplay 1 | 21-18 | 10:16 | 67 (35) | 52% | 0/0 | 0/0 | 0 | 2 | 0 | 1 | 38% |
| autoplay 2 | 18-21 | 9:40 | 67 (33) | 49% | 1/1 | 1/1 | 1 | 3 | 0 | 1 | 35% |
| autoplay 3 | 12-21 | 8:05 | 52 (29) | 56% | 0/0 | 0/0 | 2 | 1 | 0 | 1 | 22% |
| autoplay 4 | 21-16 | 10:51 | 62 (32) | 52% | 1/1 | 1/1 | 0 | 5 | 0 | 1 | 17% |
| autoplay 5 | 18-21 | 10:18 | 63 (34) | 54% | 0/5 | 2/4 | 0 | 6 | 0 | 1 | 31% |
| **autoplay mean (range)** | loser 16.4 (12-18), BLUE 2 of 5 | 9:50 (8:05-10:51) | 62 (52-67) | 52% (49-56) | 1.8 (0-5) | | 0.6 (0-2) | 3.4 (1-6) | 0 | 1 | 29% (17-38) |
| humantest 1 | 21-18 | 6:34 | 60 (36) | 60% | 2/1 | 0/1 | 1 | 5 | 0 | 1 | 38% |
| humantest 2 | 21-18 | 6:24 | 53 (34) | 64% | 2/1 | 0/0 | 2 | 7 | 0 | 1 | 42% |

- Inside the CLAUDE.md targets on the means. Intercepts (3.4 a game) are up on P10-27's 1.6 and the two humantests are
  short and hot (6:24-6:34, 60-64%), as P10-27's humantest 2 was. 5 games can't show a trend, and this task changed no
  gameplay; balance is P11-21 / P11-23 / P11-26's. No shot-clock violations, every game ended, no stuck ball or players.
- Screenshot (gym, 1280x720): HUD readable, pause button and both touch buttons clear of the play.
- No tuning suggested.

## Pass / fail
| Check | Result |
|---|---|
| Import, no script errors (both builds) | PASS |
| Every 1.0.0 fixture loads and plays on to TRIP END (Phase 11) | PASS (5/5) |
| Every Phase 8 fixture loads and plays on; `check_fixtures_v2` | PASS (2/2, CHECK OK) |
| The P10-01 fixtures load and play on (both Legends files); `check_fixtures_v3` | PASS (2/2, CHECK OK) |
| The P11-01 fixtures load and play on (both Legends files); `check_fixtures_v4` | PASS (2/2, CHECK OK, plain resume) |
| Phase 11 trips with a drafted Present legend play on in Phase 11 (bench, you, start) | PASS (TRIP END x3; the save's legend YOU plays, P10-B3's fix holds; `SIGNATURE step_back` in play) |
| Phase 11 files in Phase 10: no error dialog | PASS (lineup, game, Legends, Hall, mentor picker, NEW TRIP) |
| ... the unknown legend dropped from the trip | PASS (bench, start, you) |
| ... his tokens not counted | PASS (42/42, also with every Present token and `fin:present`) |
| ... his mentor pair shown as NO MENTOR and ignored | PASS (NICO "NO MENTOR", no perk, no PERK line) |
| ... plays on | PASS (GUI game start; TRIP END x3 headless, no `--stars`) |
| Reopened in Phase 11: what survived | Legends all kept; the drafted Present legend lost (back in the draft); lineup as the old build saved it |
| legends.json missing / broken / empty / garbage / not an object / oversized / newer: no crash | PASS |
| The drafted Present legend stays when legends.json is missing or broken | PASS |
| NEW TRIP keeps legends.json (both builds) | PASS (byte for byte) |
| No test touches legends.json, trip.json, settings.cfg; owner's user dir untouched | PASS (15 kinds of run, 21 runs) |

## Bugs
None found. No P11-Bn filed.

## Notes (not bugs)
- **Going through a Phase 10 build loses the drafted Present legend** (and, if he started, the whole lineup goes back
  to the 3 underdogs with no note), the same as P10-27 found for a Father in Phase 9. His slot opens; he stays
  unlocked and can be drafted again in Phase 11, at his ratings for the stage reached. Own points: he had 0.
- **A broken legends.json is replaced on the next Legends write**, as in Phase 9 and 10. Still true.
- `present_done.json` / the newer file show "FINALE WON" from the file's `finales` even with Present legends missing:
  data from the file, harmless (P9-31, P10-27 noted the same).
- **Name overlap, for the lead:** Zigzag's first name is **Lucien** (owner's pick) and the New Orleans recruit `nol_g1`
  is "LUCIEN" (Lucien Batiste). The short names differ (ZIGZAG vs LUCIEN) and nothing in the saves mixes them, but a
  trip roster can show a LUCIEN next to ZIGZAG's card reading "Lucien "Zigzag" Moreau". Owner's call whether that
  matters.
- Present mentor perks in the trip tests: NICO's `extra_pass` reaches the trip (probe), but NICO sits on the bench in
  these saves, so no `PERK extra_pass` line came up; how often the perks fire is P11-26's job.
- **Not tested:** the Phase 11 files in the Phase 9, Phase 8 or 1.0.0 builds (not asked; they drop unknown ids the same
  way, see P9-31 and P10-27).
