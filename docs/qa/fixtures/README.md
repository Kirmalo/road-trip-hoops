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

# Phase 8 save fixtures (P9-01)

Saves written by the Phase 8 build (commit `0dc6c22`), so Phase 9 can test that every Phase 8 save loads (`trip.json`
version 2 with drafts, each player's own points and the replay marker; `settings.cfg` with stars and LOCKER picks).
Same rules as above: the exact bytes `save.gd` and `ConfigFile` wrote, don't edit them by hand.

| File | State | How it was made |
|---|---|---|
| `trip_v2_mid.json` | Normal. Hometown (one loss) and Chicago beaten, `ht_g1` and `chi_g1` recruited, MAYOR (`ht_boss`) drafted into star slot 1 (12 stars) and starting with Deuce (you) and `chi_g1`; Memphis game 1 won: on the map before Memphis game 2, every roster player with 1 point of his own unspent (6), crew points 0, record 7-1, paid 7. CONTINUE -> map | scripted trip A |
| `trip_v2_done.json` | Hard. The whole trip (record 24-1, paid 24, phase `done`), 4 star slots filled by drafts (`ht_boss`, `chi_a1`, `mem_boss`, `sea_a1`: two bosses on the roster, one starting: Jojo (you), `mem_boss`, `nol_g1`, each with the 6 New York points unspent, 19 in all), 7 recruits; then a replay of Chicago game 2 started from the picker and won, so the marker is cleared (`replay {}`) and the trip did not move. CONTINUE -> map (replay mode) | scripted trip C |
| `settings_v2_24.cfg` | The owner's `settings.cfg` after a whole Easy trip: 24 stars (every game 1), 2 slots, LOCKER picks `jersey_1` / `ball_1` / `van_1`; level normal, music on, sfx 0.8, music 0.6, full screen, left-handed, court `rooftop`, Kings vs `lakeshore_gusts`, all 8 courts and the 9 crews unlocked | scripted trip B |
| `settings_v2_72.cfg` | The owner's `settings.cfg` after a whole Hard trip (the one in `trip_v2_done.json`): 72 stars (every game 3), 4 slots, LEGEND open and picked as the level, LOCKER picks `jersey_3` / `ball_3` / `van_3`, court `gold_hall`, `bayou_brass` vs `concrete_crowns`, music off, sfx 0.7, music 0.5, windowed, right-handed, all 8 courts and the 9 crews unlocked | scripted trip C |

How they were made (2026-11-19, Godot 4.3 stable):
- A copy of the Phase 8 build: `git archive 0dc6c22` (its `scripts/` are the current branch's minus the new
  `legends_save.gd`), with only `config/name` in `project.godot` changed ("RTH P901 Fixtures") and its own
  `XDG_DATA_HOME`, so it has its own `user://` folder.
- `make_fixtures_v2.gd.txt` (rename to `.gd`, put it in that copy's root), run
  `FIXTURE_OUT=<dir> godot --headless --path <copy> -s res://make_fixtures_v2.gd`. It drives `trip.gd` with the calls
  the screens make (`match_for`, `record_result` + `after_result` after each game, the points screen's `spend` /
  `finish_points` after every win, `recruit`, `draft` (OPEN SLOT -> DRAFT), `set_starters`, `mark_seen`,
  `start_replay` then `record_result` for the replay) and the LOCKER's `Cosmetics.pick`, and copies the files at each
  stop. No user arguments, so the build writes `user://trip.json` and the stars, unlocks and picks into
  `user://settings.cfg`, as on the tablet. Each trip starts on a fresh `settings.cfg`, so its stars are its own (trip A
  ends at 14 stars; its settings are not a fixture).

Checked in the Phase 8 build:
- `check_fixtures_v2.gd.txt` (same way, `FIXTURE_DIR=<dir>`): each trip fixture loads (`Trip.continue_trip()`), the
  loaded state equals the file (minus `version` / `serial`), version 2, CONTINUE -> map, the drafts, the starters' own
  points, the phase, no replay marker and no boss repair; each settings fixture gives its stars, slots, LEGEND, the 3
  picks, the level and the 8 courts (72: MIDNIGHT and GOLD HALL open). CHECK OK.
- Each trip fixture as `user://trip_test.json`, then `-- --trip-test --target 3 --trip-resume` (exit 0, no `ERROR` or
  `WARNING` lines). The trip test checks every won game's stars at TRIP END, so `user://settings_test.cfg` must hold
  the stars the fixture's trip already won: for `trip_v2_mid.json` a `[stars]` section with the 7 paid games at 2
  (Hometown 1-3, Chicago 1-3, Memphis 1; without it the run ends "TRIP ERROR: ... did not pay all 24 games or record
  their stars", only those 7 missing), for `trip_v2_done.json` `settings_v2_72.cfg` itself.
  - mid: resumes on the map before Memphis game 2 with `ht_boss` (drafted) starting, plays 39 games (a Memphis 1
    replay, a second draft `ht_g2` once the stars reach 24) to TRIP END, record 24-22, 48 stars, paid 24/24.
  - done: map in replay mode -> title, 0 games; TRIP END with 72 stars, slots 4, the 4 drafts kept, paid 24/24.

# Phase 9 save fixtures (P10-01)

Saves written by the Phase 9 build (commit `a1dc3c7`; its `scripts/` are identical to `9fa3283`), so Phase 10 can test
that every Phase 9 save loads (`legends.json` version 1, a `trip.json` version 2 with a drafted legend, `settings.cfg`
with 36 stars). Same rules as above: the exact bytes `save.gd`, `legends_save.gd` and `ConfigFile` wrote, don't edit
them by hand. To test one, copy it to `user://legends.json` (any test run: `legends_test.json`), `trip.json`
(`trip_test.json`) / `settings.cfg` (`settings_test.cfg`) of the build under test. All four are one owner's story:
`trip_v2_legend.json`, `settings_v2_36.cfg` and `legends_v1_mid.json` are the same moment; `legends_v1_ch1_done.json`
is the same Legends file later (the trip did not move in between, checked byte for byte).

| File | State | How it was made |
|---|---|---|
| `trip_v2_legend.json` | Normal. Hometown to Seattle beaten (record 18-2: one loss in Chicago and in Denver), paid 18; MAYOR (`ht_boss`, drafted at 12 stars) and STEEPLE (`lg_steeple`, drafted from the draft's LEGENDS row at 24 stars, via "draft", ratings 83/83/95/88/82 + steal 80 / block 98) both start with Deuce (you): one legend + one boss, no repair. 7 recruits, 11 players, 3 slots, 1 open, every point spent (0 own, 0 crew). Deuce is trained by GATE (the mentor pair is in the Legends file, so his `block_timing` perk works only with `legends_v1_mid.json` / `_ch1_done.json`). On the map before Los Angeles game 1. CONTINUE -> map | scripted story D |
| `settings_v2_36.cfg` | The owner's `settings.cfg` at that moment: 36 stars (18 games at 2), 3 slots, LEGEND closed, Legends open (gate 24); LOCKER picks `jersey_2` / `ball_1` / `van_1`; level normal, music on, sfx 0.9, music 0.7, full screen, right-handed, Quick Game court `midnight` (the 30-star reward), Kings vs `riverside_soul`; 6 courts and 6 crews unlocked (Hometown to Seattle) | scripted story D |
| `legends_v1_mid.json` | The owner's `legends.json` at that moment: intro seen; STEEPLE won on Normal (2), GATE on Hard (3), SET SHOT failed once (score won, goal broken: nothing) then won on Normal (2): 3 unlocked, 7 tokens on two levels, their 3 unlock scenes seen; GATE trains Deuce (`mentors {"lg_gate": "ud_deuce"}`); no finale | scripted story D |
| `legends_v1_ch1_done.json` | Later: BOXCAR won with 1 stop first (goal broken: nothing) then on Hard, VELVET lost once then won on Hard, QUARTERBACK on Hard, STEEPLE and SET SHOT replayed on Hard (best 2 -> 3), GATE replayed on Normal (best 3 kept), the finale's before scene, the finale won on Hard: 6 unlocked, 21/21 tokens, `finales ["grand"]` (Chapter 1 closed), 9 scenes seen, the same mentor. Your crew in the games with STEEPLE as an opponent: "STEEPLE SITS: DEX PLAYS" | scripted story D, later |

How they were made (2026-11-21, Godot 4.3 stable):
- A copy of the Phase 9 build: `git archive a1dc3c7`, with only `config/name` in `project.godot` changed ("RTH P1001
  Fixtures") and its own fresh `XDG_DATA_HOME`, so it has its own `user://` folder.
- `make_fixtures_v3.gd.txt` (rename to `.gd`, put it in that copy's root), run
  `FIXTURE_OUT=<dir> godot --headless --path <copy> -s res://make_fixtures_v3.gd`. It starts on a fresh `settings.cfg`,
  `trip.json` and `legends.json` and drives `trip.gd` as `make_fixtures_v2` does (plus the LEGENDS row draft) and
  `legends.gd` with the calls the tour and the Hall make: the chapter intro's `mark_seen`, `match_for_challenge` /
  `match_for_finale` on PLAY (the finale's before scene), `record_result` + `after_result` after each game (a broken
  goal is `{"won": true, "challenge": {"met": false}}`), `assign` for TRAIN. No user arguments, so the build writes
  `user://trip.json`, `user://legends.json` and `user://settings.cfg`, as on the tablet.

Checked in the Phase 9 build (`a1dc3c7`) and in the current build (`9fa3283`), each in its own copy (own `config/name`,
own fresh `XDG_DATA_HOME`):
- `check_fixtures_v3.gd.txt` (same way, `FIXTURE_DIR=<dir>`, no user args: the owner's file names): the settings give
  36 stars, 3 slots, LEGEND closed, the 3 picks, normal, 6 courts, MIDNIGHT open, Legends open; each Legends file
  loads as saved (`to_dict()` == the file minus version / serial): mid 7 tokens, 3 unlocked, no finale; done 21/21,
  6 unlocked, finale won, chapter done; both give Deuce GATE's `block_timing`; the trip loads as saved, version 2,
  CONTINUE -> map (Los Angeles game 1), drafts `ht_boss` + `lg_steeple`, starters Deuce + STEEPLE + MAYOR legal, no
  repair, 1 open slot, Deuce's perk on the trip, none on STEEPLE, the draft's last row LEGENDS (`lg_gate`,
  `lg_set_shot`), STEEPLE's challenge "STEEPLE SITS: DEX PLAYS"; loading writes nothing (the files byte for byte).
  CHECK OK in both builds.
- The three as `trip_test.json` / `legends_test.json` (mid) / `settings_test.cfg`, then `-- --trip-test --target 3
  --trip-resume`: **TRIP ERROR in both builds** ("the legend draft did not sign lg_gate to the bench (or it changed the
  starters or who you play)"), a `trip_test.gd` driver bug, not the fixture: on a resumed trip the lineup's tap pick
  test and the first (legend) draft happen on the same lineup visit, and `_draft_test()` keeps `Trip.starters` from
  before the taps (the lineup saves its picks on the way to DRAFT), so it sees the starters change. The draft itself
  worked (GATE signed, the hint gave the one-legend rule). With `--stars 24` (2 slots, none open, so no draft test) the
  same resume plays to TRIP END (exit 0, no ERROR or WARNING lines), STEEPLE and MAYOR starting all the way, Deuce's
  `PERK block_timing` line in a game: a1dc3c7 12 games, record 24-7; 9fa3283 10 games, record 24-5.
- With the trip and `legends_v1_ch1_done.json`: `-- --autoplay --challenge velvet` (a real CPU game to 11, Normal,
  crew trip, "STEEPLE SITS: DEX PLAYS", `sea_g1` in for him): a1dc3c7 11-10 met (Velvet 2 pts), 9fa3283 10-11 failed;
  exit 0, the test trip and Legends files unchanged byte for byte. `-- --legends-test --target 3` on the trip fixture
  (9fa3283; it erases the Legends test file first): LEGENDS END, crew trip, the swap line, 10 games, trip unchanged.
