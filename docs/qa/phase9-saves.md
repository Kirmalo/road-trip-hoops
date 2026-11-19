# P9-31: save QA (1.0.0 and Phase 8 saves in the Phase 9 build, a Phase 9 legend trip in the Phase 8 build, legends.json)

- **Build tested:** `1ff5882` (branch `ccr-f5c087b2-3ojk5f`, after P9-25), Godot 4.3 stable, Linux.
- **Phase 8 build:** `git archive 0dc6c22`.
- **Isolation:** every build is a `git archive` copy under my scratch folder, with its own `config/name` ("RTH P931 New",
  "RTH P931 Old") and its own `XDG_DATA_HOME` per kind of run (fixtures, real-name GUI runs, the legends.json probes, the
  "does a test touch the real files" runs). The shared "Road Trip Hoops" user dir was checked by md5 before and after:
  unchanged (`trip_test.json`, `settings.cfg`, `settings_test.cfg`). One Godot process at a time.
- **Scratch-only additions** (never in the repo): a tap autoload `tapdrv.gd` (finds a Button by its text, sends a real
  mouse press and release, saves a screenshot) for the real-name runs, and two `-s` scripts (`mk_legend.gd` builds the
  Phase 9 legend trip, `probe_legends.gd` loads a given legends.json and prints what the game sees). No script of the
  game was changed.
- **Fixtures:** `docs/qa/fixtures/` unchanged (5 x 1.0.0, 2 x P9-01 trips, 3 settings).
- **Import:** both copies exit 0, no script errors. `--legendtest`, `--triptest-data` (+ `--load`), `--startest`,
  `--cosmetictest`, `--twisttest`, `--ratingtest`: all OK.

## 1. Every fixture loads and plays on (`--trip-test --target 3 --trip-resume`, the fixture as `user://trip_test.json`)
`settings_test.cfg`: none for the 1.0.0 fixtures (the migration credits the stars); for `trip_v2_mid` a `[stars]` section
with its 7 paid games at 2 (as the P9-01 README says); for `trip_v2_done` `settings_v2_72.cfg`. No legends file.

| Fixture | Resumes on | Games | End | Exit |
|---|---|---|---|---|
| `trip_v1_chicago.json` | chicago game 2, map | 30 | TRIP END complete, 24-10 (one replay, a draft) | 0 |
| `trip_v1_points.json` | memphis game 3, points | 20 | TRIP END complete, 24-5 | 0 |
| `trip_v1_bosses.json` | new_orleans game 2, map (repaired to 1 boss) | 20 | TRIP END complete, 24-6 | 0 |
| `trip_v1_ny.json` | new_york game 2, bracket | 7 | TRIP END complete, 24-7 | 0 |
| `trip_v1_done.json` | new_york game 3, done: map -> title | 0 | **TRIP ERROR: star slots were open but no one was drafted** (P9-B1; the same in `0dc6c22`) | 1 |
| `trip_v2_mid.json` | memphis game 2, map, `ht_boss` drafted and starting | 32 | TRIP END complete, 24-15, 48 stars, drafts `ht_boss` + `ht_g2` | 0 |
| `trip_v2_done.json` | done, map in replay mode -> title | 0 | TRIP END complete, 72 stars, the 4 drafts kept | 0 |

- `trip_v1_done` loads fine: paid 24/24, 48 stars, crew points 56, CONTINUE -> map. Only the driver's end check fails
  (no lineup is ever shown on a finished trip, so it never drafts). P9-B1.
- `check_fixtures_v2.gd` (P9-01's check) in the Phase 9 build: **CHECK OK** (both trips: same state, version 2, CONTINUE
  -> map, drafts, own points, no repair; both settings: stars, slots, LEGEND, picks, courts). `check_fixtures_v1.gd` says
  "same state false" for every 1.0.0 trip, which is expected: it was written for the 1.0.0 build, and the Phase 8+
  migration adds crew points, `paid` and `via`.
- No `SCRIPT ERROR`, `ERROR` or `WARNING` lines in the 7 logs. No `legends_test.json` was written by any trip test.

## 2. A Phase 9 trip with a drafted legend in the Phase 8 build
Made in the Phase 9 build with the game's own calls (`mk_legend.gd`, real file names in its own user dir):
`trip_v2_mid.json` + `settings_v2_24.cfg` (24 stars, 2 slots), legends.json with STEEPLE and GATE unlocked and GATE
mentoring Deuce, then `Trip.draft("lg_steeple")` and two lineups:
- **human:** starters `lg_steeple` (you), `ht_boss`, `ud_deuce` (one legend + one boss);
- **bench:** starters Deuce, `ht_boss`, `chi_g1`, STEEPLE on the bench.

| Run | Result |
|---|---|
| Phase 8 `--trip-resume`, human | resumes on the map, STEEPLE gone from the roster, starters reset to Deuce, Jojo, Tank; 30 games to **TRIP END complete** (24-13), exit 0, no errors or warnings |
| Phase 8 `--trip-resume`, bench | STEEPLE gone, starters kept (Deuce, `ht_boss`, `chi_g1`); 24 games to **TRIP END complete** (24-7), exit 0 |
| Phase 8, real names, xvfb (tap ROAD TRIP, CONTINUE, GO) | title -> map ("NEXT: MEMPHIS, Record 7-1") -> lineup: "You play DEUCE", slots 2, open 1, drafted `ht_boss`. **No error dialog**, no crash (screenshots checked) |
| Phase 8, same, then PLAY | the game starts; trip.json re-saved without `lg_steeple` (version 2, starters the 3 underdogs). `legends.json` and `settings.cfg` byte for byte the same |
| Phase 9, the Phase 8 re-save, real names | CONTINUE -> map -> lineup, no errors; STEEPLE is not on the roster and is back in the draft's LEGENDS row (with GATE); `legends.json` unchanged |
| Phase 9, the original legend trip, real names | lineup "You play STEEPLE", roster 7, drafted `ht_boss` + `lg_steeple`; nothing written |

What the Phase 8 build loses (expected, it can't know a legend; nothing to fix in Phase 9):
- the legend himself (his slot opens again; he can be drafted again in Phase 9 since he stays unlocked in legends.json);
- when he started: the whole lineup goes back to the 3 underdogs (the Phase 8 `set_starters` refuses the saved three),
  with no lineup note;
- any own points he had (STEEPLE had 0 here).

## 3. legends.json missing, broken, empty, newer (Phase 9 build, real file names)
Each variant as `user://legends.json`, with the legend trip (STEEPLE starting) as `trip.json` and `settings_p9.cfg`
(24 stars). Two checks per variant: the `probe_legends.gd` script (load, gates, the trip, perks, the draft pool, a
challenge match, then one `Legends.save()`), and two GUI runs under xvfb (title -> LEGENDS -> HALL; title -> ROAD TRIP ->
CONTINUE -> GO -> lineup).

| Variant | `read()` | State | GUI runs | File after the GUI runs | After one `save()` |
|---|---|---|---|---|---|
| missing | {} "no save" | fresh: 0 tokens, none unlocked; LEGENDS open (24 stars) | timeline, hall 0/6, lineup with STEEPLE kept: OK | none written | blank version 1 |
| broken (cut JSON) | {} "not JSON" | fresh | OK | unchanged | blank (the broken file is replaced) |
| empty (0 bytes) | {} "bad size 0" | fresh | OK | unchanged | blank |
| garbage (3000 random bytes) | {} "not JSON" | fresh | OK | unchanged | blank |
| `[1,2,3]` | {} "not an object" | fresh | (probe only) | | blank |
| newer (version 7, extra fields, an unknown legend `lg_future`, an unknown chapter, two mentors on Deuce) | loads | tokens of the known keys kept and clamped (`lg:lg_gate` 9 -> 3), the bad `xp:` key and the `{"id"}` scene dropped, unlocked STEEPLE, GATE (+ `lg_future`, ignored), mentors: GATE -> Deuce kept, STEEPLE's second pair on Deuce dropped (load repair) | timeline "TOKENS 12/21", Hall 2/6, lineup OK | unchanged | version 1; unknown fields gone, `lg_future` and `fin:fathers` kept |

- No crash, no `SCRIPT ERROR` in any of the 10 GUI runs or 6 probes.
- A drafted legend stays on the roster whatever the file says (missing, broken: STEEPLE still starts), as the contract says.
- Visiting the title, the timeline, the Hall and the lineup never writes legends.json.
- The garbage file prints 436 "Unicode parsing error" lines (from `get_as_text()`; plain log lines, no error dialog).
  `save.gd` reads the same way. Harmless.
- The newer file shows "TOKENS 12/21" in the timeline header and the Hall while the chapter says 9/21 (P9-B2).

## 4. NEW TRIP keeps legends.json
Real names, xvfb: legends.json (STEEPLE + GATE unlocked, GATE mentors Deuce) and the legend trip; ROAD TRIP -> NEW TRIP ->
START OVER -> NORMAL -> the trip-start story.
- legends.json: **byte for byte the same** (md5 `ce91234f...` before and after). settings.cfg the same.
- trip.json: a new trip at Hometown, roster and starters the 3 underdogs (STEEPLE gone with the old trip, as designed).
- On the new trip (probe): Deuce still has GATE's perk (block timing +10%), the draft pool's LEGENDS row offers STEEPLE and
  GATE before any crew is beaten, 2 open slots.

## 5. No test touches legends.json, trip.json or settings.cfg
One isolated user dir with real-name files seeded (legends.json, the legend trip.json, settings.cfg); the md5 of the
three taken before and after each run.

| Run | Result | Real files |
|---|---|---|
| `--legendtest` | LEGENDTEST OK | same |
| `--startest`, `--cosmetictest`, `--ratingtest` | OK | same |
| `--triptest-data`, `--triptest-data --load` | TRIPDATA OK | same |
| `--trip-test --target 3 --trip-stop-after chicago` | TRIP STOP after chicago | same |
| `--legends-test --stars 24 --target 3` (with the test trip) | LEGENDS END, crew trip, 10 games | same |
| `--legends-test --stars 24 --target 3 --legends-no-trip` | LEGENDS END, crew kings, 10 games | same |
| `--titletest` | TITLE TEST DONE ("settings.cfg put back as it was: true") | same |
| `--backtest` | BACKTEST OK | same |
| `--autoplay` x5, `--humantest` x2 | below | same |
| `--challenge lg_steeple --autoplay --target 3` | CHALLENGE lg_steeple hard met 3-0 | same |
| `--shots` (xvfb) | 3 screenshots | same |

The test runs wrote only `trip_test.json`, `settings_test.cfg` and `legends_test.json`. Note: `--titletest` still
writes `settings.cfg` while it runs and puts it back byte for byte at the end (by design since Phase 5); a run killed
halfway would leave it changed. Not new.

## 6. General pass (Quick Game, Hard, Kings vs Bridge Runners)
The seeded settings.cfg has the court `rooftop`, so every game played the rooftop look with the wind twist.

| Run | Final | Length | Shots (made) | Fouls B/R | FT | Out of bounds | Intercepts | Switches |
|---|---|---|---|---|---|---|---|---|
| autoplay 1 | 16-21 | 8:20 | 54 (32) | 2/0 | 2/2 | 3 | 4 | 1 |
| autoplay 2 | 12-21 | 9:06 | 61 (27) | 5/1 | 4/5 | 2 | 2 | 1 |
| autoplay 3 | 21-20 | 9:16 | 59 (37) | 1/0 | 1/1 | 1 | 4 | 1 |
| autoplay 4 | 14-21 | 10:06 | 73 (31) | 1/0 | 1/1 | 2 | 3 | 1 |
| autoplay 5 | 21-19 | 9:14 | 68 (38) | 0/1 | 1/1 | 2 | 1 | 1 |
| **autoplay mean (range)** | loser 16.2 (12-20), BLUE 2 of 5 | 9:12 (8:20-10:06) | 63 (54-73), 52% | 2.2 (1-6) | | 2.0 (1-3) | 2.8 (1-4) | 1 |
| humantest 1 | 21-12 | 6:40 | 57 (31) | 4/0 | 2/3 | 2 | 1 | 1 |
| humantest 2 | 18-21 | 8:48 | 86 (37) | 0/1 | 0/0 | 5 | 5 | 1 |

- All within the CLAUDE.md targets (55-90 shots at about 50%, 7-11 minutes, loser 12-20, 1-5 fouls). humantest 2 had
  5 out of bounds (target 1-2), one game only. No shot-clock violations, every game ended, no stuck ball or players.
- Screenshot (rooftop, 1280x720): HUD readable, wind meter and pause button on screen, touch buttons clear of the play.
- No tuning suggested.

## Pass / fail
| Check | Result |
|---|---|
| Import, no script errors (both builds) | PASS |
| Every 1.0.0 fixture loads and plays on to TRIP END | PASS for 4 of 5; `trip_v1_done` loads fine but the driver ends in TRIP ERROR (P9-B1, the driver, also in `0dc6c22`) |
| Every P9-01 fixture loads and plays on to TRIP END; `check_fixtures_v2` | PASS (2/2, CHECK OK) |
| Phase 9 legend trip in the Phase 8 build: no error dialog, legend dropped, plays on | PASS (headless both lineups to TRIP END; real names under xvfb) |
| legends.json untouched by the Phase 8 build | PASS |
| legends.json missing / broken / empty / garbage / not an object / newer: no crash | PASS |
| A drafted legend stays when legends.json is missing or broken | PASS |
| NEW TRIP keeps legends.json (byte for byte; mentor perk and draft row still there) | PASS |
| No test touches legends.json, trip.json, settings.cfg | PASS (15 kinds of run) |
| Owner's real user dir untouched | PASS |
| Token totals shown with a newer file | **FAIL** (minor): P9-B2 |

## Bugs
### P9-B1: `--trip-resume` on a finished migrated trip fails the draft check (test driver)
- **Steps:** `trip_v1_done.json` as `user://trip_test.json`, no `settings_test.cfg`, then
  `godot --headless --path . --fixed-fps 60 --quit-after 2000000 -- --trip-test --target 3 --trip-resume`.
- **Expected:** TRIP END complete, exit 0 (as in P8-26 at `723810a`, before P8-23 added the draft check).
- **Actual:** the migration gives 48 stars (4 slots); the finished trip goes map -> title with no lineup, so the driver
  never gets a chance to draft. `_end_checks()` then prints "TRIP draft at the end | slots 4 | drafted [] | NO DRAFT" and
  ends "TRIP ERROR: star slots were open but no one was drafted", exit 1. The same in `0dc6c22`. The save itself is
  fine (paid 24/24, 48 stars, CONTINUE -> map).
- **Severity:** low (test only; anyone rerunning the P8-01 checks gets a false failure).
- **Suggested fix (`trip_test.gd`):** set a flag when a lineup with `Trip.open_slots() > 0` was shown outside a replay
  (the place that drafts, line 187), and fail at the end only when that flag is set and nobody was drafted. The
  comment above `_end_checks()` already says "checked when they had their chance".

### P9-B2: the token total counts tokens this build doesn't know
- **Steps:** a legends.json with tokens for an unknown legend or chapter (a newer build's file, or a hand edit), e.g.
  `{"version": 7, "tokens": {"lg:lg_steeple": 3, "lg:lg_gate": 3, "fin:grand": 3, "lg:lg_future": 2, "fin:fathers": 1}, ...}`.
  Open LEGENDS, then HALL.
- **Expected:** the header total agrees with the chapters this build shows: 9 of 21.
- **Actual:** the timeline header says "TOKENS 12/21" and the Hall "12/21 TOKENS", while Chapter 1 says 9/21.
  `Legends.tokens_total()` sums every key `LegendsSave.clean()` kept (any `lg:` / `fin:` key). With more such keys the
  total goes past 21. The same total feeds `gate_met()`, so 12 such tokens already meet the Fathers gate ("12 TOKENS").
  This has no effect today because Chapter 2 isn't built. Similarly, a newer file's `finales: ["grand"]` shows Chapter
  1 "FINALE WON" with 2 of 6 legends unlocked (data from the file; harmless).
- **Severity:** low (needs a newer or hand-edited file; display only today).
- **Suggested fix (`legends.gd`):** for the shown total, sum only `chapter_tokens(ch)` over `LegendsData.built_chapters()`
  (and/or cap at `max_tokens()`). Keep the unknown keys in the file (forward compatible, as now). Decide whether gates
  should count them; for a file from a newer build, counting them is arguably right.

## Notes (not bugs)
- **A broken legends.json is replaced, not kept:** it reads as a fresh start, and the next Legends write (a challenge
  result, a seen scene, a mentor pick) writes a blank file over it, so the broken one is lost. Visiting screens doesn't
  write. This matches `save.gd` and the temp-file writes make a half file unlikely. If wanted: rename an unreadable file
  to `legends.json.bad` before the first write.
- **A newer legends.json loses its unknown fields** on this build's first write (version goes back to 1; unknown legends
  and their tokens are kept). As designed ("loads what fits"). A later build must accept a version 1 rewrite of its
  own file.
- **For P9-32 (screens):** when the human is a drafted legend, his card is last in roster order. The lineup's first
  screen shows "You play STEEPLE" but not his card, so you have to scroll to see him.
- **Not tested:** a Phase 9 legend trip in the 1.0.0 build. It wasn't asked for, and the 1.0.0 loader drops unknown ids
  the same way.
