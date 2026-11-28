# P12-27: save QA (Phase 11 saves in the Phase 12 build, Phase 12 files in the Phase 11 build, legends.json)

- **Build tested:** `47b1456` (branch `ccr-f5c087b2-3ojk5f`, after P12-21; P12-18 and P12-19 merged), Godot 4.3 stable,
  Linux.
- **Phase 11 build:** `git archive d298d22` ("Phase 11 summary", the published Phase 11 build that P12-01 wrote its
  fixtures with).
- **Isolation:** each build is a `git archive` copy in my scratch folder with its own `config/name` ("RTH P1227 New",
  "RTH P1227 Old"). Every run had a new `XDG_DATA_HOME` folder of its own. One Godot process at a time. The default
  `Road Trip Hoops` user dir was checked by md5 before and after: unchanged. The scratch copies are deleted.
- **Scratch tools** (no game script changed): a tap autoload (presses a visible Button by its text, saves shots; added
  to the scratch copies' `project.godot` only for the GUI runs), `probe_p12.gd` (loads the given files under the real
  names and prints what the build sees; `WRITE=1` saves once; runs in both builds), `make_fixtures_v6_p12.gd` (makes
  the Phase 12 files with the game's own calls), `check_fixtures_v6_p12.gd` (the Phase 12 checks). All three are
  committed as `.gd.txt` in `docs/qa/fixtures/` (rename to `.gd`, put in a copy's root, run with `-s`).
- **Import:** both copies exit 0, no script errors.

## The Phase 12 files (made in the Phase 12 build, real file names)
`make_fixtures_v6_p12.gd`, story G, goes on from P12-01's story F (`settings_v2_72_present.cfg`,
`legends_v1_ch3_done.json`, `trip_v2_present.json` as the owner's files):
- **G1, Legends:** Chapter 4 open (72 stars, "72 STARS OR 48 TOKENS"); the intro seen; OVERCLOCK won on Hard (3), LONG
  SHADOW on Normal (2), GLITCH won with the goal broken (0) then on Normal (2), UPDRAFT lost (0). 21 unlocked, 70 tokens
  (63 + New Generation 7). Mentors: GATE -> Deuce, ANKLES -> MAYOR, TOOLBOX -> NICO (from P12-01) and **OVERCLOCK ->
  JOJO** (`ud_jojo`, perk `fresh_legs`). -> `legends_v1_ch4_mid_p12.json`
- **G2, trip:** the New York final won (trip done), **NEW TRIP** on Normal (`legends.json` byte for byte the same), the
  draft's 4th LEGENDS row offers OVERCLOCK, LONG SHADOW, GLITCH; OVERCLOCK and LONG SHADOW drafted (via "draft", 0
  points), OVERCLOCK starts next to Deuce (you) and JOJO, Hometown won 3-0, SKIP recruited: on the Chicago map.
  -> `trip_v2_next_p12.json`; the same with **OVERCLOCK as YOU** -> `trip_v2_next_you_p12.json`. The trip calls did not
  touch `legends.json`.
- **G3, the end:** UPDRAFT, HALFCOURT, FIREWALL, LONG SHADOW on LEGEND, GLITCH on Hard, OVERCLOCK on Easy (3 kept); the
  finale's before scene; `fin:next` on LEGEND: "LEGENDS COMPLETE | every finale won: legends_complete plays once",
  after_result goes `legends_next_finale_after` -> `legends_complete` -> the chapter view. 84/84 tokens, 24 unlocked,
  finales grand / fathers / present / next. -> `legends_v1_ch4_done_p12.json`. The tour did not touch `trip.json`.
- **G4, settings:** LEGEND, court `era_next`, Quick Game teams `new_generation` vs `present`, the 3 picks.
  -> `settings_v2_72_next_p12.cfg`

All five are committed in `docs/qa/fixtures/` (the `_p12` names) for later phases.

## 1. P12-01's fixtures in the Phase 12 build
`check_fixtures_v5.gd` (P12-01's own check, the owner's file names): **CHECK OK**. Read back as saved (`to_dict()` ==
the file minus version / serial) and loading writes nothing (all three files byte for byte):

| Fixture | Phase 12 build sees |
|---|---|
| `settings_v2_72_present.cfg` | 72 stars, 4 slots, LEGEND open and the level, picks jersey_3 / ball_3 / van_3, 8 courts, MIDNIGHT and GOLD HALL, left-handed, full screen, Chapters 1-3 open |
| `legends_v1_ch3_mid.json` | 49 tokens (21 / 21 / 7), 15 unlocked, 22 seen, finales grand + fathers, the Present finale locked; mentors GATE -> Deuce `block_timing`, ANKLES -> MAYOR `handle`, TOOLBOX -> NICO `extra_pass`; era teams grandfathers + fathers |
| `legends_v1_ch3_done.json` | 63 tokens, 18 unlocked, 27 seen, three finales; the same three mentors and perks; era teams + present; BIG STAGE saved court with SPACE THE FLOOR; saved teams present vs grandfathers |
| `trip_v2_present.json` | CONTINUE -> bracket (New York final), 14 players, drafts MAYOR / STEEPLE / MIDRANGE / DEEP END, starters Deuce (you) + DEEP END + MAYOR (one legend, one boss, no repair), 4 points each, 0 open slots; DEEP END no perk, `step_back`; three LEGENDS rows (no New Generation row: none unlocked), "DEEP END SITS" in Skylight's challenge and the Present finale |

**Chapter 4's gate** (`check_fixtures_v6_p12.gd`, every pair of fixtures):

| Settings | Legends | Stars | Tokens | Chapter 4 | Right? |
|---|---|---|---|---|---|
| `settings_v2_72_present.cfg` | `legends_v1_ch3_mid.json` | 72 | 49 | open | yes (both) |
| `settings_v2_72_present.cfg` | `legends_v1_ch2_done.json` | 72 | 42 | open | yes (stars) |
| `settings_v2_48.cfg` | `legends_v1_ch3_mid.json` | 48 | 49 | open | yes (tokens) |
| `settings_v2_48.cfg` | `legends_v1_ch3_done.json` | 48 | 63 | open | yes (tokens) |
| `settings_v2_48.cfg` | `legends_v1_ch2_done.json` | 48 | 42 | **shut** | yes |
| `settings_v2_36.cfg` | `legends_v1_ch2_done.json` | 36 | 42 | **shut** | yes |

Gate text "72 STARS OR 48 TOKENS" in every case. Nothing lost: tokens, unlocks, seen, finales, mentors, the drafted
Present legend and the 72 stars all come back as saved.

**Play-on:** `--trip-test --target 3 --trip-resume` in the Phase 12 build with the Phase 12 **you** trip
(`trip_v2_next_you_p12.json`, `legends_v1_ch4_mid_p12.json` as `legends_test.json`, the Phase 12 settings):
"TRIP resume: the save's YOU is the drafted legend lg_overclock (the save's pick: allowed)", **TRIP END complete**, 44
games, 24-22, the driver drafted GLITCH, DEEP END and the Chicago boss; `SIGNATURE top_gear` and `PERK fresh_legs JOJO`
lines in play. Exit 0, no script errors, `legends_test.json` unchanged (md5).

## 2. The Phase 12 files in the Phase 11 build (`d298d22`)
Probe (real names), and the same files back in the Phase 12 build for reference:

| | Phase 12 build | Phase 11 build |
|---|---|---|
| tokens shown (mid / done) | 70/84 / 84/84 | **63/63 / 63/63** (the New Generation keys kept in the file, not counted) |
| unlocked (mid / done) | 21 / 24 | 18 / 18 (the New Generation ids ignored) |
| Chapter 4 | open, 7/21 (mid), FINALE WON 21/21 (done) | not built: COMING LATER "72 STARS OR 48 TOKENS" (also with the done file and its `fin:next`) |
| LEGENDS COMPLETE (done) | yes | the build doesn't have it; nothing shown |
| JOJO's perk (mentor OVERCLOCK) | `fresh_legs` | **none**; the pair stays in the file; Deuce `block_timing`, MAYOR `handle`, NICO `extra_pass` kept |
| a New Generation challenge (`match_for_challenge("lg_overclock")`) | the match (twist / look `era_next`, music `legends_next`) | {} (unknown id, nothing built) |
| draft's LEGENDS rows | four (the New Generation row last) | three |
| **trip** (`trip_v2_next_p12.json`) | 6 players, OVERCLOCK starts, LONG SHADOW bench, 2 open | OVERCLOCK and LONG SHADOW **dropped**: 4 players, 4 open slots, starters reset to Deuce (you) / JOJO / TANK, no repair note |
| **you** trip (`trip_v2_next_you_p12.json`) | OVERCLOCK you | both dropped; Deuce (you) / JOJO / TANK |
| files after loading | unchanged | unchanged (loading writes nothing) |

Real names under xvfb in the Phase 11 build (screenshots checked; no error dialog, no script error in any run):

| Run | Result |
|---|---|
| LEGENDS -> HALL -> BACK (done file) | timeline "TOKENS 63/63", Chapters 1-3 FINALE WON, Chapter 4 COMING LATER; Hall 18/18, 63/63 |
| LEGENDS -> HALL -> TRAIN (mid file) | the picker lists DEUCE "TRAINED BY GATE", **JOJO "NO MENTOR"**, TANK, SKIP (no legends) |
| ROAD TRIP -> CONTINUE -> GO -> PLAY (**you** trip) | map -> Chicago story -> lineup "You play DEUCE", Deuce / Jojo / Tank, 2 OPEN SLOT cards -> the game starts (Chicago 1 vs Lakeshore Gusts). trip.json re-saved: version 2, no `lg_` id, starters the 3 underdogs; `legends.json` and `settings.cfg` byte for byte the same |
| ROAD TRIP -> NEW TRIP -> START OVER -> NORMAL | the trip-start story; `legends.json` byte for byte the same |

Headless play-on in the Phase 11 build (**you** trip as `trip_test.json`, `legends_v1_ch4_mid_p12.json` as
`legends_test.json`, no `--stars`): resumes on the Chicago map with the 3 underdogs, **TRIP END complete**, 32 games,
24-10 (the driver drafted DEEP END, ROOFTOP, STEEPLE). Only `PERK block_timing` and `SIGNATURE step_back` lines, no New
Generation perk or move. Exit 0, no script errors, `legends_test.json` unchanged.

What the Phase 11 build writes when it writes Legends (`probe WRITE=1`): every key survives, mid and done (tokens
`lg:lg_overclock` ... and `fin:next`, the 6 ids in `unlocked`, the Chapter 4 scenes and `legends_complete` in `seen`,
`finales` with "next", OVERCLOCK -> JOJO); only `serial` moves.

## 3. Reopened in the Phase 12 build (what survived)
| Files | Phase 12 build sees |
|---|---|
| The Phase 11 build's `WRITE=1` legends.json (done) | everything: 84/84, 24 unlocked, four finales, **LEGENDS COMPLETE**, JOJO `fresh_legs` |
| The Phase 11 build's re-saved trip (after PLAY) + the done file | Chicago map, 4 players, 4 open slots, the 3 underdogs start. **Lost:** OVERCLOCK and LONG SHADOW on the roster (and the lineup). **Kept:** both still unlocked and back in the draft's New Generation row (all six there); JOJO's perk back |

The only loss through a Phase 11 build is the drafted New Generation legend (and, if he started, the lineup), the same
as P11-27 found for a Present legend in Phase 10. Expected; nothing to fix.

## 4. LEGENDS COMPLETE through a save and a load
`check_fixtures_v6_p12.gd` (Phase 12 build, real names): the done file loads as saved, `legends_complete()` true; then
two rounds of `Legends.save()` + a forced `load_state(true)`: complete both times, the same state (84/84, four
finales, `legends_complete` seen). `mark_seen("legends_complete")` again: false (the ending doesn't play twice). The
timeline shows "LEGENDS COMPLETE - TOKENS 84/84" with four FINALE WON panels; the Hall shows 24/24 and the "THE HALL
IS FULL" banner (shots checked). In the Phase 11 build the same file: no crash (above).

## 5. NEW TRIP never touches legends.json
| Build | How | Legends file | Result |
|---|---|---|---|
| Phase 12 | `Trip.new_trip()` (the title's call) + a draft + a lineup, API | `legends_v1_ch3_mid`, `_ch3_done`, `_ch4_mid_p12`, `_ch4_done_p12` | byte for byte, 4/4 |
| Phase 12 | in story G (G2) | `legends_v1_ch4_mid_p12` | byte for byte |
| Phase 12 | GUI: ROAD TRIP -> NEW TRIP -> START OVER -> NORMAL | `legends_v1_ch4_done_p12` | md5 the same |
| Phase 11 | GUI, the same taps | `legends_v1_ch4_done_p12` | md5 the same |

## 6. Standard tests (Phase 12 build, unchanged copy)
| Run | Result |
|---|---|
| `--legendtest` | LEGENDTEST OK (legends 24, chapters 4 built of 4, max tokens 84; save, progress; era teams grandfathers, fathers, present, new_generation) |
| `--triptest-data` | TRIPDATA OK |
| `--triptest-data --load` | TRIPDATA OK, "round trip across a restart: same state" |

## 7. General pass (Quick Game, Hard, Kings vs Bridge Runners, gym)
| Run | Final | Length | Shots (made) | FG% | Fouls B/R | FT | Out of bounds | Intercepts | Shot clock | Switches | OREB |
|---|---|---|---|---|---|---|---|---|---|---|---|
| autoplay 1 | 18-21 | 8:28 | 51 (35) | 69% | 2/2 | 1/3 | 2 | 5 | 0 | 1 | 31% |
| autoplay 2 | 11-21 | 8:18 | 53 (27) | 51% | 2/1 | 3/3 | 0 | 1 | 0 | 1 | 17% |
| autoplay 3 | 21-15 | 11:52 | 76 (33) | 43% | 2/0 | 2/2 | 1 | 6 | 0 | 1 | 31% |
| autoplay 4 | 21-18 | 9:34 | 60 (33) | 55% | 0/2 | 2/2 | 1 | 3 | 0 | 1 | 31% |
| autoplay 5 | 21-18 | 10:33 | 70 (35) | 50% | 1/1 | 1/1 | 2 | 6 | 0 | 1 | 35% |
| **autoplay mean (range)** | loser 16.0 (11-18), BLUE 3 of 5 | 9:45 (8:18-11:52) | 62 (51-76) | 53% (43-69) | 2.6 (1-4) a game | | 1.2 (0-2) | 4.2 (1-6) | 0 | 1 | 29% (17-35) |
| humantest 1 | 21-14 | 8:02 | 68 (33) | 49% | 2/1 | 1/1 | 4 | 5 | 0 | 1 | 20% |
| humantest 2 | 21-15 | 7:09 | 57 (34) | 60% | 3/1 | 0/0 | 0 | 3 | 0 | 1 | 39% |

- Inside the CLAUDE.md targets on the means, and in line with P12-21's 200-game twist-none set (60.7 shots, 54%).
  Autoplay 1 was short and hot (51 shots, 69%), one game; 5 games can't show a trend, and this task changed no
  gameplay. No shot-clock violations, every game ended, no stuck ball or players, no script errors.
- `--shots` (gym, 1280x720): HUD readable, pause button and the touch buttons clear of the play.
- No tuning suggested.

## Pass / fail
| Check | Result |
|---|---|
| Import, no script errors (both builds) | PASS |
| P12-01's fixtures load in Phase 12 as saved (`check_fixtures_v5`) | PASS (CHECK OK; loading writes nothing) |
| Chapter 4 opens as its gate says (72 stars or 48 tokens) | PASS (6/6 pairs) |
| Phase 12 files load in Phase 12 as saved (both legends files, both trips) | PASS |
| A Phase 12 trip with a New Generation legend YOU plays on in Phase 12 | PASS (TRIP END, 44 games) |
| Phase 12 files in Phase 11: no crash, no error dialog | PASS (Legends, Hall, mentor picker, lineup, game start, NEW TRIP) |
| ... the unknown legends dropped from the trip | PASS (both trips; legal three starts) |
| ... their tokens not counted, their mentor pair ignored (NO MENTOR) | PASS (63/63; JOJO NO MENTOR, no perk) |
| ... plays on | PASS (TRIP END, 32 games, exit 0) |
| ... a Legends write keeps every Chapter 4 key | PASS (mid and done) |
| Reopened in Phase 12: what survived | Legends all kept (LEGENDS COMPLETE too); the drafted legends lost from the trip (back in the draft) |
| LEGENDS COMPLETE survives save / load; the ending plays once | PASS |
| NEW TRIP keeps legends.json (both builds) | PASS (byte for byte, 7 runs) |
| `--legendtest`, `--triptest-data`, `--triptest-data --load` | PASS |
| Owner's user dir untouched | PASS (md5 before and after) |

## Bugs
None found. No P12-Bn filed.

## Notes (not bugs)
- **Going through a Phase 11 build loses a drafted New Generation legend** (and, if he started, the lineup goes back to
  the 3 underdogs with no note), as P10-27 and P11-27 found for the earlier eras. He stays unlocked and can be drafted
  again in Phase 12 at his ratings for the stage reached (he had 0 points).
- The Phase 11 build's `chapter_tokens("next")` counts the file's `fin:next` (3 of max 0, probe only); no screen shows
  it there (the unbuilt row shows its gate text). Harmless.
- `legends_v1_ch3_mid.json` (49 tokens) opens Chapter 4 by tokens even at 48 stars: as the gate says (48 tokens).
- The Phase 12 trip-test run from the **you** trip lost 22 of 44 games (target 3, CPU vs CPU; the Phase 11 build's run
  from the same file lost 10 of 32 with the underdogs). One run each, short games, not a balance measure; the ramp is
  P12-26's.
- **Not tested:** the Phase 12 files in the Phase 10 or older builds (not asked; those drop unknown ids the same way,
  P10-27 / P11-27).
