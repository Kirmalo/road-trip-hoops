# Road Trip Hoops

Top-down 3v3 full-court basketball game in Godot 4 (GDScript), played by touch on an Android tablet.
The owner edits and plays it in the Godot Android editor, and gets updates by downloading the repo as a ZIP and
re-importing it. There is no Git on the tablet, so keep the project self-contained and runnable as is.

## Layout
- `project.godot`: 1280x720 landscape, stretch `canvas_items` + `expand`, GL Compatibility renderer, nearest filtering.
  The features version is "4.3" so older Android editors open it without a warning. Keep code compatible with Godot 4.3+.
- `main.tscn`: a single Node2D with `scripts/main.gd`. Everything else is built in code (no other scenes).
- `scripts/main.gd`: game manager. Clocks, possession, HUD, camera, input routing, the test modes. Builds the game
  when `Flow.screen == "game"`, else asks `flow.gd` for the current screen; plays a trip game from `Flow.match`.
- `scripts/rules.gd`: first to 21, scoring, switching sides, dead balls and inbounds, fouls, free throws, out of bounds.
- `scripts/difficulty.gd`: EASY / NORMAL / HARD values for RED, and the saved settings (`user://settings.cfg`).
- `scripts/menu.gd`: the launch and game-over panel (levels, COURT and MUSIC buttons).
- `scripts/human_input.gd`: the human's controls (flicks, pump-fake taps, CALL, the STEAL/BLOCK button).
- `scripts/player.gd`: movement and CPU offense (spots, ball handler drive/shoot/pass); draws its sprite sheet
  through `view.gd`.
- `scripts/defense.gd`: CPU man-to-man defense, pokes, block jumps and block rules.
- `scripts/ball.gd`: ball states HELD, PASS, SHOT, LOOSE, DEAD; `z` is the ball's height (sim pixels).
- `scripts/court.gd`: draws the floor and backdrop (one instance) and the rims (second instance, above the players),
  through `view.gd`, in the look from `court_looks.gd`.
- `scripts/view.gd`: the projection (static functions, preloaded as `View`): `to_screen`, `to_floor`, `size_at`, the
  stick mapping; modes ANGLED (default, 3/4 view from the near sideline) and FLAT (old top-down, test/fallback).
- `scripts/court_looks.gd`: court looks as data (gym, blacktop): colors, textures, music track.
- `scripts/fx.gd`: popups, screen shake, fire trail. `scripts/audio.gd`: sound effects and music (crossfade, ducking).
- `scripts/touch_controls.gd`: floating joystick on the left half, A and B buttons on the right.
- Road Trip (Phase 5): static data and logic, and screens built in code (each a CanvasLayer from its own script):
  - `scripts/flow.gd`: scene flow (static). `Flow.go(screen, args)` reloads `main.tscn` into a screen; `Flow.match`
    is the next trip game, `Flow.last_result` the last one. Screen table in `SCREENS`.
  - `scripts/trip.gd`: the trip's progress and rules (static): games per city, retries, stat points, recruits,
    starters, the New York bracket, where CONTINUE resumes, `match_for()`. `scripts/save.gd`: the save file
    `user://trip.json` (temp file + rename; tests use `user://trip_test.json`).
  - `scripts/cities.gd`: route, cities, crews and players as const data (stage ratings, tiers, game targets).
    `scripts/ratings.gd`: the five stats (speed, shooting, finishing, defense, stamina) and how they map onto play.
  - `scripts/ui_kit.gd`: the shared look for the screens (buttons, panels, sliders).
  - `scripts/title.gd`: screens "title", "settings", "crew" (ROAD TRIP / QUICK GAME / SETTINGS / CREW & CREDITS).
  - `scripts/trip_map.gd`: "map" (USA map, pins, the van, GO). `scripts/story.gd`: "story" (portraits and text box);
    the lines are data in `scripts/story_text.gd`. `scripts/lineup.gd`: "lineup" (pick 3 starters, the first is you).
  - `scripts/after_game.gd`: "result" (score, RETRY / NEXT) and "points" (spend stat points).
    `scripts/recruit.gd`: "recruit" (sign one of 3). `scripts/bracket.gd`: "bracket" (New York, 3 rounds).
  - `scripts/pause.gd`: the pause button (top-right) and panel in every human game.
  - `scripts/trip_test.gd`: the `--trip-test` driver (plays a whole trip headless through each screen's
    `auto_step()`).
- `assets/`: original art made by `tools/art/` (`players/` sprite sheets + `hands.json`, `courts/` floors and
  backdrops, `ball/`, `portraits/` story portraits, `map/` trip map), `sfx/` and `music/` (see `CREDITS.md`).
  The old Kenney Sports Pack sprites (`assets/*.png`, facing +x) are only a fallback when a new file is missing.
- `tools/`: `art/make_players.py` (players from `art/crews.json`, renderer `art/pixel3d.py`), `art/make_courts.py`
  (courts and ball), `art/make_portraits_v2.py` (portraits, drawing kit `art/comic.py`), `art/make_map.py` (trip
  map), `make_sfx.sh` / `make_music.sh` (sound and music processing), `build_web.sh`. Python 3 with
  Pillow and numpy; rerun a generator and commit its output in `assets/`.

## Conventions
- Units: `FT = 12` pixels per foot. Court is 94 x 50 ft. Team 0 (BLUE, human) attacks the right hoop.
- GDScript: don't use `:=` when the right side is untyped (e.g. `game.something`, or `min`/`max`/`clamp`); use an
  explicit type or `minf`/`maxf`. Otherwise the script fails to parse.
- Touch first: every feature must be usable with the joystick plus the two buttons. Keyboard (WASD, J, K) is for
  desktop testing only.
- The simulation stays 2D top-down (positions, velocities, heights, facing). All drawing goes through `view.gd`'s
  projection (`View.to_screen(p, h)` etc.); nothing on screen is placed in raw sim coordinates, and drawing never
  writes back into the simulation.
- Art is generated by the scripts in `tools/art` in the owner-approved style (style sample v1), not drawn by hand
  or downloaded. Any third-party asset must be CC0 or CC-BY (no share-alike, no non-commercial) and get a row in
  `CREDITS.md`.

## Testing (no tablet needed)
Download a Godot 4 Linux editor binary from the GitHub releases, then:

```
godot --headless --path . --import
# full CPU vs CPU game to 21, prints the final score, GAME LENGTH, fouls/free throws and the stats
godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay
# scripted human inputs, exercises shoot/pass/steal/switch/free-throw code paths
godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --humantest
# screenshots to /tmp/hoops_*.png (needs xvfb)
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- --shots
```
Test flags (after `--`, combine with the modes above):
- `--difficulty easy|normal|hard` (or `--difficulty=normal`): the level; it changes RED only. `--autoplay` and
  `--humantest` play Hard without it. With `--autoplay`, RED's win share measures the level (BLUE plays Hard).
- `--target N`: play to N instead of 21 (sides switch at (N + 1) / 2), e.g. `--target 3` for a short game.
- `--force-fouls`: fouls some released field goals, to exercise the free-throw path.
- `--menushot` (xvfb, like `--shots`; add `--target 3`): screenshots of the launch and game-over difficulty panels.
- `--view flat|angled` (or `--view=angled`): the drawing mode (default angled). The simulation is the same in both.
- `--court gym|blacktop` (or `--court=blacktop`): the court look for this run (overrides the saved choice).
- `--perspective k`: try a far-side narrowing of k (e.g. 0.15; the game uses 0).
- `--ballshots [DIR]` (xvfb, angled): screenshots of the ball (dribble, lob, rim, dunk, loose) to DIR, default `/tmp`.
- `--viewtest`: checks the projection round trip and stick mapping, prints the result and quits.
- `--fps`: prints the frame rate every few seconds.

Road Trip tests (Phase 5). Every test mode above skips the title screen and plays a Quick Game as before; the trip
tests use `user://trip_test.json`, never the owner's save:
```
# a whole trip headless through every screen: title, Hometown (3 games), points, recruit, Chicago, New York, ending.
# Prints TRIP lines and ends with "TRIP END" (exit 0) or "TRIP ERROR: <why>" (exit 1)
godot --headless --path . --fixed-fps 60 --quit-after 2000000 -- --trip-test --target 3
# trip data and save round trip: every city game's lineups and save checks, then a second process loads and compares
godot --headless --path . -- --triptest-data
godot --headless --path . -- --triptest-data --load
# prints the ratings table (what each stat does on today's values; checks that 50 = exactly today) and quits
godot --headless --path . -- --ratingtest
# taps through the title, settings and crew screens, ends on QUICK GAME (screenshots /tmp/hoops_title*.png,
# /tmp/hoops_settings.png, /tmp/hoops_crew*.png when run under xvfb without --headless)
godot --headless --path . --fixed-fps 60 --quit-after 20000 -- --titletest
```
- `--trip-force-loss N` (with `--trip-test`): the Nth trip game of this run is lost, to test the retry.
- `--trip-stop-after <city>` (with `--trip-test`): quits on the map once that city is done ("TRIP STOP", saved).
- `--trip-resume` (with `--trip-test`, a new process): loads the test save and plays on from there.
- `--screens` (with `--trip-test`, xvfb): screenshots of every screen to `/tmp/hoops_screen_NN_<screen>.png`; each trip
  game is then decided at once.
- `--city <id> --cgame N` (N = 1..3, default 1): play that city game's matchup (crews, ratings, target, court, music)
  CPU vs CPU, or with `--humantest` / a screenshot mode. Ids are the `cities.gd` keys (`hometown`, `chicago`, ...).

After gameplay changes, run several `--autoplay` games and check the stats look sane. A typical game to 21 is about
75-120 shots and 10-15 minutes of game time (`GAME LENGTH`), ends 21-x (the loser usually 12-20), has about 2-6
fouls and 2-3 out of bounds, one side switch, and few interceptions or shot-clock violations.
Look at a screenshot after visual changes.
Judge team balance on 200+ `--autoplay` games: 40-game batches swing up to about 65/35 by chance
(docs/qa/phase3-length.md). `--autoplay` picks the first ball at random.

## Web build (how the owner plays)
The owner plays the web version at https://kirmalo.github.io/road-trip-hoops/ (GitHub Pages, served from the
`gh-pages` branch, which holds only build output). `tools/build_web.sh` builds `build/web/` (ignored by git);
`tools/build_web.sh --publish` also commits it to `gh-pages` and pushes. The `Web` preset is in `export_presets.cfg`
(threads off, so no special server headers are needed). Publish after each merged phase, or when the coordinator asks.
Test a web build in Chromium with Playwright (touch emulation) before publishing.

## Vision and team
- `docs/VISION.md`: the design decisions and roadmap (Road Trip campaign, first to 21, pixel art, phases 1-7).
  Read it before any gameplay or content work. Don't decide design it leaves open; ask the owner.
- `docs/TEAM.md`: how the agent team (`.claude/agents/`) works through a phase. `docs/BOARD.md` is the task board.
- `CREDITS.md`: every asset with its source and license. Only CC0 or other licenses that allow commercial redistribution.
