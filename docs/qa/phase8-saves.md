# P8-26: save migration test (1.0.0 saves in the new build, version 2 saves in 1.0.0)

- **Build tested:** `723810a` (branch `ccr-f5c087b2-3ojk5f`, after P8-24), Godot 4.3 stable, Linux.
- **1.0.0 build:** `git archive 4302f4e`, as in `docs/qa/fixtures/README.md`.
- **Isolation:** every run used a scratch copy with its own `config/name` ("RTH P826 New", "RTH P826 New2", "RTH P826
  Old", "RTH P826 Old2"), so each had its own `user://`. No run touched the shared "Road Trip Hoops" user dir or the
  scratch folders `proj`/`proj2`, so the clean-up the coordinator reported doesn't affect these results. At most 2 of
  my Godot processes ran at once.
- **Fixtures:** the P8-01 files in `docs/qa/fixtures/`, unchanged.
- **Import:** both copies imported with exit 0 and no script errors.

## 1. Each 1.0.0 fixture in the new build

### What the migration should give
Crew points = the 1.0.0 pool + 6 per beaten city + 4 per won New York round + 1 per won game of the city being played.
Paid = every game won. Stars = paid x (1 Easy / 2 Normal / 3 Hard).

| Fixture | Level | Pool | Catch-up | Crew points expected / got | Paid | Stars expected / got | Bosses | CONTINUE expected / got |
|---|---|---|---|---|---|---|---|---|
| `trip_v1_chicago.json` | easy | 5 | 6 + 1 (chicago:1) | 12 / **12** | 4 | 4 / **4** | none | map / **map** |
| `trip_v1_points.json` | normal | 8 | 3 x 6 | 26 / **26** | 9 | 18 / **18** | none | points / **points** |
| `trip_v1_bosses.json` | hard | 2 | 3 x 6 + 1 (new_orleans:1) | 21 / **21** | 10 | 30 / **30** | repaired (below) | map / **map** |
| `trip_v1_ny.json` | normal | 1 | 7 x 6 + 4 | 47 / **47** | 22 | 44 / **44** | 1 (mem_boss), kept | bracket / **bracket** |
| `trip_v1_done.json` | normal | 2 | 7 x 6 + 3 x 4 | 56 / **56** | 24 | 48 / **48** | none | map (P8-17) / **map** |

- **Own points:** every player has `pts` 0, as expected.
- **"via":** the underdogs are `start` and everyone else `recruit`. I read this from the saved version 2 file.
- **Write-back:** the file on disk is version 2 straight after CONTINUE, with `crew_points` and `points` the same as
  in memory.
- **Second load:** the version 2 file loaded again gives the same crew points, paid list and stars (no second
  catch-up and no second credit), and no repair note.

### The boss repair (`trip_v1_bosses.json`)
- `["chi_boss", "ht_boss", "mem_boss"]` became `["chi_boss", "ud_jojo", "ud_deuce"]`; the human is still `chi_boss`.
  - The first boss (BIG LOU) stays.
  - `ht_boss` was swapped for Jojo (sum 280), the strongest non-boss.
  - `mem_boss` was swapped for Deuce (278).
  - Tank (266) stays on the bench.
- The lineup note reads "ONLY ONE BOSS CAN START: MAYOR and SMOKE moved to the bench." (screenshot checked). It is gone
  on the next load.

### Stars credited once per settings file (`migrated_v1`)
- **One settings file, every fixture:** after `trip_v1_done` set `migrated_v1`, loading `trip_v1_chicago` into the same
  settings gave **48 -> 48** (+0).
- **The same save again:** +0.
- **Each fixture on a fresh `settings_v1.cfg`:** the credit is given once, with the figures in the table above.

### The trip plays on to TRIP END (`--trip-test --target 3 --trip-resume`, the fixture as `user://trip_test.json`)
| Fixture | First screen | Games played | End | Exit |
|---|---|---|---|---|
| chicago | map -> lineup | 37 | TRIP END complete, 24-18 | 0 |
| points | points (26 spent) -> recruit | 33 | TRIP END complete, 24-19 | 0 |
| bosses | map -> lineup (1 boss starts; the tap-picked lineup is mem_boss + Jojo + Deuce) | 27 | TRIP END complete, 24-14 | 0 |
| ny | bracket -> lineup (semifinal) | 9 | TRIP END complete, 24-9 | 0 |
| done | map -> title | 0 | TRIP END complete | 0 |

No `SCRIPT ERROR`, `ERROR` or `WARNING` lines in any of the 5 logs.

## 2. The owner's real files (no user args)
- **Setup:** in the "RTH P826 New2" copy I put `trip_v1_points.json` in as `user://trip.json` and `settings_v1.cfg`
  as `user://settings.cfg`.
- **Launch:** the new build ran under xvfb with **no user args**, so it used the real paths: `Save.path()` was
  `user://trip.json` and `Stars.path()` was `user://settings.cfg`.
- **Driver:** a scratch autoload (only in the copy) tapped ROAD TRIP, then CONTINUE, with real mouse press and release
  events.

| Check | Result |
|---|---|
| CONTINUE lands on | **points** (trip_v1_points). The same run with trip_v1_bosses lands on **map**, then GO -> **lineup** with the repair note. With trip_v1_done it lands on **map** in replay mode ("Trip complete! ... Tap a city to replay", button TITLE) |
| trip.json | rewritten as version 2: crew_points 26, paid 9, `via` start/recruit, `replay {}` |
| settings.cfg `[settings]` | byte for byte the same keys and values afterwards: difficulty normal, music on, sfx 0.8, music 0.6, fullscreen true, left_handed true, court barn, quick_team cornfield_kings, quick_opponent lakeshore_gusts, unlocked_courts hometown/chicago/memphis, unlocked_teams county_line/lakeshore_gusts/riverside_soul |
| Stars | a new `[stars]` section: `best` = the 9 games at 2 and `migrated_v1=true` (total 18; bosses 30, done 48) |
| Difficulty read-back (data check) | level normal; courts hometown/chicago/memphis; teams include county_line, lakeshore_gusts, riverside_soul; left-handed true; full screen saved true |
| Full screen | window mode 0 at launch, 3 (full screen) after the first tap: the saved ON came back on the first tap (`restore_fullscreen`), as designed |

## 3. Version 2 saves in the 1.0.0 build
I made four version 2 saves in the new build:
- `v2_memphis`: a fresh Normal trip stopped after Memphis.
- `v2_la_hard`: Hard, stopped after Los Angeles, 63 stars.
- `v2_bosses_migrated`: `trip_v1_bosses` after its migration, with 21 crew points.
- `v2_hostile`: `v2_la_hard`, then:
  - drafted `ht_g2` and `ht_a1` (4 slots);
  - own points (Deuce 4, ht_g2 2) and 3 crew points;
  - a drafted player starting and as the human;
  - a replay marker `chicago:2`.
- `v2_hostile_legend`: the same with level `legend`.

| Save | 1.0.0 `--trip-resume` | Games | End |
|---|---|---|---|
| v2_memphis | map -> New Orleans arrival -> lineup | 31 | TRIP END complete, exit 0 |
| v2_bosses_migrated | map -> lineup | 24 | TRIP END complete, exit 0 |
| v2_la_hard | map -> New York | 4 | TRIP END complete, exit 0 |
| v2_hostile | map -> New York (12-man roster kept, drafted starter kept) | 3 | TRIP END complete, exit 0 |

- **Warnings:** the only one in these runs is the planned "save version 2 is newer than 1; loading what fits". No
  script errors.
- **Real-file run in the 1.0.0 build** (the "RTH P826 Old2" copy, under xvfb, no user args, the same tap driver):
  `v2_hostile_legend` as `trip.json` and a version 2 `settings.cfg` (`difficulty="legend"`, the `[stars]` section,
  `migrated_v1`, a `[cosmetics]` section).
  - ROAD TRIP -> CONTINUE -> **map** ("NEXT: NEW YORK, Record 21-17, level NORMAL"). GO -> the New York story.
  - No error dialog, no crash.
  - `settings.cfg` afterwards still had `[stars]` and `[cosmetics]`, and `difficulty="legend"` was left alone.
- **What 1.0.0 drops when it saves (expected, "loading what fits"):**
  - A LEGEND trip becomes Normal.
  - Each player's own points go into the shared pool (`points` 9).
  - `crew_points`, `paid` and `replay` are dropped; `via` is dropped from each roster entry.
- **Back into the new build:** I loaded 1.0.0's re-save of `v2_hostile` (version 1, with `rule:per_starter` in
  `seen`).
  - Crew points 9 = the pool, so **no catch-up** (correct).
  - Paid 21, CONTINUE -> map.
  - Stars +63 on a fresh stars file, +0 on the second load.
  - `ht_a1` came back as `draft`, but **`ht_g2` came back as `recruit`**. This is bug P8-B2 below.

## 4. General pass (new build, Quick Game, not part of this task's checks)
| Run | Final | Length | Shots | Fouls B/R | FT | Out of bounds | Interceptions | Side switches | Errors |
|---|---|---|---|---|---|---|---|---|---|
| autoplay 1 | 15-21 | 9:19 | 69 | 4/2 | 3/4 | 1 | 2 | 1 | 0 |
| autoplay 2 | 21-18 | 9:43 | 70 | 1/1 | 2/2 | 0 | 2 | 1 | 0 |
| autoplay 3 | 18-21 | 12:12 | 84 | 1/2 | 1/1 | 3 | 5 | 1 | 0 |
| autoplay 4 | 21-15 | 8:42 | 57 | 1/0 | 1/1 | 2 | 1 | 1 | 0 |
| autoplay 5 | 17-21 | 10:28 | 68 | 1/1 | 0/1 | 2 | 6 | 1 | 0 |
| **autoplay mean (range)** | loser 16.6 (15-18) | 10:05 (8:42-12:12) | 69.6 (57-84) | 2.8 (1-6) per game | | 1.6 (0-3) | 3.2 (1-6) | 1 | 0 |
| humantest 1 | 21-17 | 6:54 | 59 | 0/1 | 0/0 | 1 | 0 | 1 | 0 |
| humantest 2 | 21-18 | 7:23 | 68 | 2/5 | 1/3 | 0 | 4 | 1 | 0 |

- **Every game ended**, with no stuck ball or players reported.
- **Shots are below the old 75-120 target** (mean 70). That fits a build with higher make rates (P7-T1); P8-29 should
  confirm the new reference rather than this 5-game sample.
- **Proposed target for the lead to confirm:** about 55-90 shots for a game to 21, if P7-T1 is what lowered them.
- **No balance tuning is suggested from this task.**

## Pass / fail
| Check | Result |
|---|---|
| Import, no script errors | PASS |
| Every fixture loads; CONTINUE lands on map / points / map / bracket / map (done) | PASS |
| Crew points = pool + catch-up (incl. +1 per won game of the current city) | PASS (12 / 26 / 21 / 47 / 56) |
| Paid = every won game | PASS (4 / 9 / 10 / 22 / 24) |
| Stars credited at the save's level, once per settings file (`migrated_v1`) | PASS |
| Boss repair: first boss stays, the others swapped for the strongest non-bosses, lineup note | PASS |
| Saved as version 2 at once; reloading gives no second catch-up | PASS |
| Every fixture plays on to TRIP END (`--trip-resume`) | PASS (5/5, exit 0) |
| Real files (no user args): settings unlocks, left-handed, full screen, court, teams kept; stars written into settings.cfg | PASS |
| Version 2 saves in 1.0.0: load, no error dialog or crash, play on to TRIP END | PASS (4 saves headless, 1 real-file run with screenshots) |
| 1.0.0 re-save loaded again in the new build: no double catch-up or stars | PASS |
| Points screen layout with crew points | **FAIL**: P8-B1 |
| `via draft` survives a 1.0.0 round trip | **FAIL** (minor): P8-B2 |

## Bugs
These are numbered P8-B1 and P8-B2 here. P8-27 is filing bugs at the same time, so the lead may need to renumber.

### P8-B1: points screen: DONE button pushed off screen when crew points are shown
- **Steps:**
  1. Open `trip_v1_points.json` (or any migrated save with crew points) in the new build.
  2. CONTINUE goes to the STAT POINTS screen.
- **Expected:** the UNDO and DONE (SKIP) buttons sit fully on screen at the top right, at 1280x720.
- **Actual:** the header line "DEUCE: NO POINTS   CREW POINTS: 26 (anyone)   (+3 each, max 90)" is one unwrapped label
  in the header HBox (`after_game.gd`, `_left_label` in the `tcol` box). It is wider than the space left, so the HBox
  pushes DONE past the right edge. Only "DO" shows (screenshot: the points screen after CONTINUE, 1280x720).
- **Impact:**
  - DONE is the screen's way out, and every 1.0.0 save with points left lands here or on the per-win points screen
    with crew points.
  - Enter still works on desktop, and the part of the button still on screen may still take a tap. On the tablet it
    looks broken.
- **Fix idea (gameplay programmer):**
  - Let the label shrink and wrap: `_left_label.autowrap_mode` plus `clip_text`, or `custom_minimum_size.x = 0` with
    `SIZE_EXPAND_FILL`.
  - Or put the crew points on a second line.
  - Check with a 3-digit crew total and the longest player name.

### P8-B2: a drafted recruitable player becomes "recruit" after a 1.0.0 round trip (one free roster slot)
- **Steps:**
  1. In the new build, draft a city's good player who wasn't the city's recruit (e.g. `ht_g2` after recruiting
     `ht_g1`).
  2. Open the trip in 1.0.0, which saves it as version 1 without `via`.
  3. Load it in the new build again.
- **Expected:** `ht_g2` stays `via: "draft"` and fills one star slot.
- **Actual:** `_via_of()` gives `recruit` to any recruitable player, so `ht_g2` is `recruit`. `drafted_ids()` loses
  him, `open_slots()` goes up by 1, and the roster can grow one past its star limit. Non-recruitable draftees (e.g.
  `ht_a1`) are fine.
- **Severity:** low. It only happens when someone opens a newer save in the old build.
- **Fix idea:** in a version 1 load, count one recruit per beaten city: the first recruitable player of each city in
  roster order is `recruit`, and any further one from the same city is `draft`.

## Notes (not bugs)
- **Unspent crew points on a finished trip:** a migrated finished trip (`trip_v1_done`) arrives with 56 crew points.
  The map doesn't mention them. They can be spent from the lineup's STAT POINTS card before a replay (`done` is a
  spend phase).
  - Worth a line in P8-27's look at the map, or a hint on the map card.
- **Downgrades when 1.0.0 saves:** LEGEND becomes Normal, own points join the shared pool, and the replay marker is
  dropped. All three are expected.
