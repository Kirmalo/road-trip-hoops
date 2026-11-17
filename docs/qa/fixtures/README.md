# 1.0.0 save fixtures (P8-01)

Saves written by the 1.0.0 build (commit `4302f4e`; its `scripts/` are identical to `c8162ab`), so Phase 8 can test
that every 1.0.0 save loads (`trip.json` version 1, the owner's `settings.cfg`). They are the exact bytes `save.gd`
and `ConfigFile` wrote; don't edit them by hand. To test one, copy it to `user://trip_test.json` (or `trip.json`) /
`user://settings.cfg` of the build under test.

| File | State | How it was made |
|---|---|---|
| `trip_v1_chicago.json` | Easy. Hometown beaten (one loss), 3 of its 6 points left unspent, `ht_g1` recruited and starting, Chicago game 1 won: on the map before Chicago game 2, pool 5. CONTINUE -> map | scripted trip A |
| `trip_v1_points.json` | Normal. Hometown, Chicago, Memphis beaten, on the points screen after Memphis (2 points left from Chicago + 6 new = 8). CONTINUE -> points | scripted trip B |
| `trip_v1_bosses.json` | Hard. The Hometown, Chicago and Memphis bosses recruited; all 3 start (`chi_boss` is you); New Orleans game 1 won, pool 2. CONTINUE -> map | scripted trip C |
| `trip_v1_ny.json` | Normal. 7 cities beaten, New York round 1 won, 1 of 2 points spent: between New York rounds, pool 1. CONTINUE -> bracket | scripted trip B, later |
| `trip_v1_done.json` | Normal. The whole trip played: 46 real CPU vs CPU games to 3 (`--target 3`), record 24-22 (one forced loss), phase `done`, pool 2. CONTINUE -> title | real `--trip-test` run |
| `settings_v1.cfg` | The owner's `settings.cfg` at the moment of `trip_v1_points.json`: level normal, music on, sfx 0.8, music 0.6, full screen, left-handed, Quick Game court `barn` and teams Kings vs `lakeshore_gusts`, unlocked courts hometown/chicago/memphis and teams `county_line`, `lakeshore_gusts`, `riverside_soul` | scripted trip B |

How they were made (2026-11-17, Godot 4.3 stable):
- A copy of the 1.0.0 build: `git archive 4302f4e`, with only `config/name` in `project.godot` changed so it gets its own
  `user://` folder (nothing of the owner's or other test runs is touched).
- Scripted trips: `make_fixtures_v1.gd.txt` (rename to `.gd`, put it in that copy's root), run
  `FIXTURE_OUT=<dir> godot --headless --path <copy> -s res://make_fixtures_v1.gd`. It drives `trip.gd` with the calls
  the screens make (`match_for`, `record_result` + `after_result` after each game, `spend` / `finish_points`,
  `recruit`, `set_starters`, `mark_seen` for the arrival stories) and copies the save at each stop. It runs without user
  arguments, so the 1.0.0 code writes `user://trip.json` and the unlocks into `user://settings.cfg`, as on the tablet.
- `trip_v1_done.json`: in the same copy, `godot --headless --path . --fixed-fps 60 --quit-after 2000000 -- --trip-test
  --target 3 --trip-force-loss 5` (TRIP END, complete), then `user://trip_test.json` copied.

Checked in the 1.0.0 build:
- `check_fixtures_v1.gd.txt` (same way, `FIXTURE_DIR=<dir>`): each trip fixture loads (`Trip.continue_trip()`), the
  loaded state equals the file (minus `version` / `serial`), CONTINUE goes to the screen above; `trip_v1_bosses.json`
  keeps all 3 bosses starting; `settings_v1.cfg` gives the 3 courts, the 3 teams, left-handed and full screen. CHECK OK.
- Each fixture as `user://trip_test.json`, then `-- --trip-test --target 3 --trip-resume`: resumes on the screen above
  and plays on to TRIP END (exit 0, no errors): chicago 32 games, points 31, bosses 27 (the first game resumed with the
  3 bosses starting), ny 2, done 0 (straight to the CHAMPIONS title).
