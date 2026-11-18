# P8-27 Screens QA (Phase 8, Wave 7)

- Build tested: `6a47562` (branch `ccr-f5c087b2-3ojk5f`, "P8-23: trip test checks stars, paid games, the draft, a replay
  and the locker" merged). Godot 4.3.stable, Linux, xvfb + `--rendering-driver opengl3`.
- Isolation: a `git archive` copy with `config/name="Road Trip Hoops P827"` (own `user://`), every run in a private
  mount namespace with its own `/tmp` (the screenshots of the other QA batches could not mix with these). One Godot
  process at a time. A second copy ("P827 Probe") added three test-only autoloads that are not in the repo: a frame
  snapshot (countdown, CREW screen), a lineup tap (the boss rule) and the P7-B1 tap probe.
- Contact sheet of the key shots: `docs/qa/phase8-screens.png` (36 shots, the bug shots captioned in orange).
- Game code: not changed.

## Runs

| Run | Result |
|---|---|
| `--import` | clean, no script errors |
| `--trip-test --target 3 --screens --stars 24` (1280x720) | TRIP END, 24-0, 115 screens, paid 24/24, locker ok, draft `ht_boss`, 1 replay; 66 shots |
| `--trip-test --target 3 --screens --stars 72 --difficulty legend` | TRIP END, 24-0, every game >= 3 stars, 4 slots, locker ok; 66 shots |
| `--trip-test --trip-resume --mapshot` on the finished LEGEND trip | map `done`, picker, cancel (marker gone), replay of `new_york:1` played (lost, stars 72 -> 72), marker gone, TRIP END |
| fixture `trip_v1_chicago.json`, `--trip-resume --screens --stars 24 --mapshot --trip-stop-after chicago` | map stars, picker, replay of `chicago:1` (won, no points), draft, points (crew points), recruit; TRIP STOP |
| fixture `trip_v1_bosses.json`, `--trip-resume --screens --stars 12 --trip-stop-after new_orleans` | `TRIP lineup repaired on load (only one boss can start): [chi_boss, ht_boss, mem_boss] -> [chi_boss, ud_jojo, ud_deuce]`, the note on the first lineup, replay `memphis:1`, draft 12-player pool, TRIP STOP |
| same fixture + lineup tap probe (`tap_player("ht_boss")` while Big Lou starts) | `LINEUP ht_boss refused: ONLY ONE BOSS CAN START (chi_boss already starts)`, flash shown |
| `--trip-test --screens --stars 24 --trip-stop-after chicago --left-handed --resolution 1600x720` | TRIP STOP, 27 shots |
| fixture chicago again at `--resolution 1600x720` with `--mapshot` | TRIP STOP, 18 shots |
| `--menushot --target 3` with `--stars 72`, `--stars 72 --left-handed --resolution 1600x720`, `--stars 0` | start and game-over panels; LEGEND only with 72 |
| `--titletest --stars 72` (xvfb) | TITLE TEST DONE, settings.cfg put back; 11 shots |
| CREW screen with a version 2 save (drafted player), probe copy | shot |
| `--shots --stars 72 --wear jersey_N,ball_N` (N = 1..3; courts gym, `midnight`, `gold_hall`) + countdown snaps | 3 runs, 3 shots each + 5 countdown frames |
| `--humantest --pauseshot --stars 72`, 1280x720 and 1600x720, `--right-handed` and `--left-handed` | 4 pause shots + 4 HUD frames; `pause_test_ok` |
| P7-B1 probe (below) | 30/30 second taps quit |
| 5 `--autoplay`, 2 `--humantest` (headless, Hard) | all ended, no script errors (table below) |

The only engine messages in every log are the xvfb ones (ALSA / dummy audio driver, V-Sync not supported).

## Autoplay / humantest stats (sanity only; this task changes no sim)

| Stat | Mean | Range (5 autoplay) | Target |
|---|---|---|---|
| Final | 4 games to 21; RED won 2 of 5 | 21-10, 19-21, 13-21, 21-18, 21-20 | 21-x, loser 12-20 |
| Game length | 9:24 | 6:28 - 12:09 | 10-15 min |
| Shots | 67 | 50 - 84 | 75-120 |
| Fouls | 1.8 | 0 - 4 | 2-6 |
| Out of bounds | 1.2 | 0 - 2 | 2-3 |
| Interceptions | 2.6 | 1 - 4 | few |
| Side switches | 1 | 1 - 1 | 1 |
| Shot-clock violations | 0 | 0 | few |

Humantest: 21-20 (6:58, 63 shots, 5 fouls) and 21-15 (6:20, 57 shots, 0 fouls), `pause_test_ok` 1 in both. The short
games and low shot counts match the P7-T1 higher make rates (P8-25 / P8-29 judge the new reference, not this task).
Every game starts with `COUNTDOWN 1 (2.25 s frozen before tip-off)`.

## Checks (1280x720 unless marked)

| Screen / feature | Shots | Result |
|---|---|---|
| Result, per-win points line ("+1 STAT POINT EACH: DEUCE, JOJO, TANK (3 to spend)") | s24 `10`, `14` | PASS |
| Result, "+2 NEW STARS!" (Normal), "NEW BEST: 3 STARS!" (LEGEND), "BEST: 3 STARS" (no gain), replay "REPLAY: STARS ONLY" | s24 `10`, s72 `10`, chi `04`, `09` | PASS. With `--stars N` the "STARS n/72" count stays at N (as the flag says) |
| Result, UNLOCKED line | - | NOT SEEN: with `--stars` forced the total never crosses a ladder step in a run, and a real run starts from the bests already saved. Not covered here (P8-29 can catch it on a fresh `settings_test.cfg` without `--stars`) |
| STAT POINTS after a win (three starter tabs, +3 200x110, UNDO, SKIP/DONE) | s24 `11`, `12` | PASS |
| STAT POINTS with crew points (1.0.0 catch-up) | chi `10`, boss `10` | FAIL: SKIP pushed off the right edge = P8-B1 (already filed by P8-26, not filed again) |
| Lineup: OPEN SLOT (before / after a beaten crew), SLOT LOCKED "OPENS AT 36 STARS", scroll bar | s24 `09`, `13`, `22` | PASS |
| Lineup: STAT POINTS card (crew points, TAP TO SPEND) | chi `03`, boss `03` | PASS (the whole 400x184 card is the tap target) |
| Lineup: BOSS and DRAFTED tags | s24 `31`, `63` | PASS |
| Lineup: boss repair note on the first lineup after loading `trip_v1_bosses.json` | boss `03` | PASS: "ONLY ONE BOSS CAN START: MAYOR and SMOKE moved to the bench." |
| Lineup: a second boss tapped | boss `probe_lineup_boss_rule` | PASS: "ONLY ONE BOSS CAN START. Bench BIG LOU first." |
| Lineup header in a replay | chi `03`, boss `03` | FAIL = P8-B3 |
| Draft: crews in bands, BOSS / GOOD tags, slot rings and locks, SIGN, the joining line with the portrait, 12-player pool scrolls | s24 `24`, `25`, boss `07`, `08` | PASS |
| Locker: ladder (got / next / locked), tiles with ON, lock and star count, 24 and 72 stars | s24 `02`, s72 `02`, title `hoops_locker` | PASS |
| Map: stars under every pin ("6/9", "0/9"), the replay picker (rows, stars, PLAY or "not won yet", CLOSE), cancel and replay, finished trip (trophies, "Tap a city to replay", TITLE instead of GO) | s24 `06`, `19`, chi/mapdone `hoops_map_*` | PASS. The parked van covers part of the NEW YORK and HOMETOWN labels, but the labels draw on top and stay readable |
| Title: STARS n/72 tab, LOCKER button | s24 `01`, title `hoops_title` | PASS |
| LEGEND in the level pickers: title trip picker, Settings, Quick Game start and game-over panels; absent at `--stars 0` | title `hoops_title_level`, `hoops_settings`, menu `*` | PASS (colour difference = P8-B6) |
| Quick Game reward courts: `QUICK COURTS gym, blacktop, midnight, gold_hall` at 72; `gym, blacktop` at 0 | menu logs | PASS |
| CREW: player rows, DRAFTED tag | `snap_crew_90` | PASS, with P8-B4 and P8-B5 |
| Countdown 3-2-1-GO: centred under "FIRST TO 21", readable on the dark MIDNIGHT court, play frozen (SHOT 24) | `snap_w2_20..160` | PASS |
| Cosmetics in a game: HOME WHITES + SKY (gym), AFTER HOURS + NIGHT GLOW (MIDNIGHT), THROWBACK + GOLD (GOLD HALL); the ball reads on all three floors | game `w1/w2/w3_hoops_*` | PASS, with P8-B7 |
| HUD and pause, right- and left-handed, 1280x720 and 1600x720: joystick / SHOOT / PASS mirrored, pause button top-right, panel inside the frame | pause `*` | PASS |
| 1600x720: title, locker, map, lineup, draft, recruit, result, replay picker centred; the replay header fits there | wide, widechi | PASS, except the STAT POINTS screen = P8-B8 |
| Buttons under 110 px tall | all | none found: +3 200x110, SKIP/UNDO 200x110, PLAY 360x130, picker PLAY ~220x110, CLOSE 200x110, SIGN 560x110, locker tiles 200x152, draft cards 192x314, lineup cards 400x184. The small pills (TAP TO SPEND, BOSS, DRAFTED, the 2/3 pick numbers) are labels on a bigger tap target |
| Dimmed NEXT / +3 / GO in some shots | s24 `10`, `11`, `19` | not a bug: the shot is taken 40 frames after the screen opens, inside the screens' 0.8 s arm time (the map's GO while the van drives) |

## P7-B1 (second QUIT? tap ignored), under xvfb

A probe autoload in the probe copy plays `--humantest`; after the scripted pause it taps the real pause button, then
QUIT, then QUIT again 0.4 / 0.6 / 0.8 / 1.0 / 1.2 / 1.5 s later, as `InputEventScreenTouch` (press, then release
on the next frame) or as mouse clicks through `Input.parse_input_event`. Success = the scene reloads (with the test
flags QUIT lands on a new Quick Game).

| Mode | Second taps that quit |
|---|---|
| touch, `--fixed-fps 60` | 12/12 |
| mouse, `--fixed-fps 60` | 6/6 |
| touch, real time (no `--fixed-fps`), a full-viewport screenshot saved right after the first tap (the web report's "screenshot between taps" case) | 12/12 |

The first tap armed QUIT? every time. **Not reproduced** natively (30/30). This matches P7-40 (native xvfb 2/2) and
points again at the web harness (SwiftShader stalls) or the browser input path, which xvfb cannot test. P7-B1 stays
open for the tablet / real Chromium check in P8-29.

## Bugs

### P8-B3 | Lineup header cut off on a replay (1280x720) | low-medium
- Steps: any replay from the map (e.g. `trip_v1_chicago.json`, `--trip-resume --mapshot`, or the trip test's Memphis
  replay), look at the lineup's top-right header.
- Expected: "REPLAY - CHICAGO - GAME 1 OF 3" / "FIRST TO 11  STARS ONLY" inside the opponent panel's column
  (x 904..1264).
- Actual: the first line runs off the right edge of the screen ("... GAME 1 OF 3", the "3" is cut) and the block is
  pushed right of the column. `_fit_font()` in `lineup.gd` `_build_head()` shrinks the font but the line still
  overflows. Seen on `chicago:1` and `memphis:1`. At 1600x720 it lands in the margin and looks fine.
- Suggested fix (`lineup.gd`): put "REPLAY" on the second line with STARS ONLY ("FIRST TO 11 - REPLAY, STARS ONLY"),
  or check `_fit_font()` against the label's real width (the line is about 330 px at its final size and the label is
  drawn about 40 px right of `SIDE_POS.x`).

### P8-B4 | CREW: a long role runs into the stats | low
- Steps: CREW & CREDITS with a trip that has New Orleans' Lucien on the roster (`trip_v1_bosses.json` played on).
- Expected: a gap between the role column and "SPD".
- Actual: "fast-break guardSPD 70": the role column is too narrow for "fast-break guard" (and "all-around boss" only
  just fits). It may be older than Phase 8, but P8-13 reworked this screen.
- Suggested fix (`title.gd`, the crew rows): a smaller font for the role or a role column about 20 px wider.

### P8-B5 | CREW: the record shows twice on the van line | low
- Actual: "Van: The Biscuit.   Record 12-1.   DENVER, GAME 1 - 12-1 - HARD.   Crew points: 0." The record comes once
  from the crew line and once from `_trip_summary()`.
- Suggested fix (`title.gd`): drop one of the two (e.g. "Van: The Biscuit.  DENVER, GAME 1 - 12-1 - HARD.  Crew
  points: 0.").

### P8-B6 | LEGEND looks different in the title pickers | cosmetic
- The Quick Game panel paints LEGEND purple (its own colour); the title's trip level picker and Settings show it as a
  plain blue button like EASY/HARD. Not wrong, just not the same. Owner's call; one look in all three would be clearer.

### P8-B7 | AFTER HOURS jersey vs the default Quick Game opponent | low (design / art)
- Steps: `--stars 72 --wear jersey_2` (any court; worst on MIDNIGHT), Kings vs Bridge Runners.
- Actual: BLUE in black and pink and RED in black and red: both teams look dark with red accents; only the floor
  rings and the hair tell them apart at a glance.
- Suggested: give AFTER HOURS a lighter main colour (e.g. charcoal-grey body with pink trim) in `tools/art`, or have
  Quick Game fall back to the classic jersey when the opponent's main colour is close. Art / owner decision.

### P8-B8 | STAT POINTS screen not centred on wide screens | low
- Steps: `--resolution 1600x720`, any win -> STAT POINTS.
- Actual: the tabs, bars and +3 column stay left-aligned (to about x 1430) while UNDO / SKIP sit at the right edge,
  so a 170 px gap opens between the +3 buttons and the screen edge. Lineup, draft, locker and map all centre their
  1280 frame. With crew points, SKIP just fits at 1600 but not at 1280 (P8-B1).
- Suggested fix (`after_game.gd`, points mode): build the points page in a centred 1280x720 frame like `lineup.gd`'s
  `FRAME_SIZE`; that fixes it together with P8-B1.

## Notes (not bugs)
- With `--stars N` the replay picker shows the real per-game bests saved in the test settings file (earlier runs gave
  every game 3), so "not won yet" rows can show 3 stars. That is the stars-are-kept-for-good rule, not a display bug.
- The title's van is still the drawn box van; the van paint only shows on the map and the locker (by design, P8-20).
- At 1600x720 the game camera shows the court off-centre in the start/game-over panels (old behaviour, Phase 6).

## Tuning
No tuning changes from this pass: it is a screens task, and the sim numbers above belong to P8-25 / P8-29.
