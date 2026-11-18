# Road Trip Hoops

Top-down 3v3 full-court basketball game in Godot 4 (GDScript), played by touch on an Android tablet.
The owner edits and plays it in the Godot Android editor, and gets updates by downloading the repo as a ZIP and
re-importing it. There is no Git on the tablet, so keep the project self-contained and runnable as is.

## Layout
- `project.godot`: 1280x720 landscape, stretch `canvas_items` + `expand`, GL Compatibility renderer, nearest filtering.
  The features version is "4.3" so older Android editors open it without a warning. Keep code compatible with Godot 4.3+.
  `application/config/version` ("1.0.0") is the one version source: the title (bottom-right), the CREW & CREDITS
  list, the web ZIP name and the APK read it. `config/icon` is `assets/icon/icon.png`; `quit_on_go_back=false` (the
  Android back gesture pauses or goes BACK, it only quits on the title).
- `main.tscn`: a single Node2D with `scripts/main.gd`. Everything else is built in code (no other scenes).
- `scripts/main.gd`: game manager. Clocks, possession, HUD, camera, input routing, the test modes. Builds the game
  when `Flow.screen == "game"`, else asks `flow.gd` for the current screen; plays a trip game from `Flow.match`
  (crews, court, music, twist). `_fix_jersey_clash()` (P8-B7): your star jersey switches to your normal look for a
  game against a crew in close colors (`Cosmetics.jersey_clashes()`; that game only, never saved).
- `scripts/rules.gd`: first to 21, scoring, switching sides, dead balls and inbounds, fouls, free throws, out of bounds.
- `scripts/difficulty.gd`: EASY / NORMAL / HARD values for RED, and the saved settings (`user://settings.cfg`),
  including the Quick Game court unlocks (`unlock_court(city)` after a city's boss game is won; kept for good) and
  team unlocks (`unlock_team(crew_id)`, same moment; a New York crew when its round is won; `quick_teams()`). Trip
  test runs keep both kinds of unlock in `user://settings_test.cfg`, never in the owner's `settings.cfg`.
  LEFT-HANDED: `is_left_handed()` / `set_left_handed()` (saved as `left_handed`); a test run (any user argument after
  `--`) never saves it. Also parses `--music-volume` into `music_volume_flag` for `audio.gd`.
  LEGEND (P8-19, open at 72 stars, `Stars.legend_open()`; `offered_levels()`): the Hard values plus `LEGEND_BONUS`
  (12) on every opponent stat, capped at `LEGEND_CAP` 95 (trip games: `Trip.BOSS_CAP` 95). A saved or asked-for
  LEGEND that isn't open plays Hard.
- `scripts/menu.gd`: the Quick Game panel (levels, YOUR TEAM / OPPONENT, COURT and MUSIC buttons). A 4th level button,
  LEGEND, once it is open. COURT cycles the gym, the blacktop, every unlocked city court and the open star reward
  looks (MIDNIGHT, GOLD HALL: `Cosmetics.open_court_looks()`); a city court brings its city's twist
  (`quick_twist()`). The team buttons cycle the Kings, the Bridge Runners and every beaten crew (`Trip.quick_team()`:
  the boss game's lineup, own colors, each player's stats shifted to average 50; RED plays its crew's style).
- `scripts/human_input.gd`: the human's controls (flicks, pump-fake taps, CALL, the STEAL/BLOCK button).
- `scripts/player.gd`: movement and CPU offense (spots, ball handler drive/shoot/pass); picks the animation (running
  dribble, 4 dunk styles, rim hang, ankle-breaker falls, ...) and draws its sheet through `view.gd`, with the motion
  effects (squash and stretch, foot dust, camera punch on big dunks). Quick Game wears the underdogs (BLUE) and the
  Bridge Runners (RED).
- `scripts/defense.gd`: CPU man-to-man defense, pokes, block jumps and block rules.
- `scripts/ball.gd`: ball states HELD, PASS, SHOT, LOOSE, DEAD; `z` is the ball's height (sim pixels). Draws the
  picked ball (`Cosmetics.ball_sheet()`) in every game.
- `scripts/court.gd`: draws the floor and backdrop (one instance) and the rims (second instance, above the players),
  through `view.gd`, in the look from `court_looks.gd` (plus props: wood backboard, near fence, puddles, sand).
- `scripts/view.gd`: the projection (static functions, preloaded as `View`): `to_screen`, `to_floor`, `size_at`, the
  stick mapping; modes ANGLED (default, 3/4 view from the near sideline) and FLAT (old top-down, test/fallback).
- `scripts/court_looks.gd`: court looks as data (gym, blacktop, the 8 city courts and the 2 star reward looks
  `midnight` and `gold_hall`, "reward" `court_1` / `court_2`): colors, textures, music track, ambience.
  `ALWAYS_OPEN` (gym, blacktop) need no unlock.
- `scripts/fx.gd`: popups (kept inside the view), screen shake, fire trail, foot dust, camera punch.
  `scripts/audio.gd`: sound effects, music (crossfade, ducking) and twist ambience loops; `sfx_volume` and
  `music_volume` (0..1, 1.0 = the old levels), both saved in `settings.cfg`.
- `scripts/twists.gd`: the city twists as data (static, preloaded as `Twists`): wind, crowd, humid, thin_air, wet,
  sand, cage (and none). Every sim hook is `Twists.value(key, default)`, so twist none is exactly the old game; no
  hook reads a team. `scripts/twist_fx.gd`: the twist's banner, effects and ambience (drawing only).
- `scripts/sheets.gd`: the player sheet reader (static, `Sheets`): v2 from `assets/players2/format.json`, hands and
  ball points, cards, palettes, and the fallback chain. Indexed pages draw through `scripts/shaders/palette.gdshader`.
  Star jerseys are palettes `<sheet>_j<N>` / `<sheet>_crew_j<N>` (a missing one draws the look without it;
  `strip_jersey()`).
- `scripts/anim_test.gd`: the `--anim-test` driver (checks every sheet, writes contact sheets).
- `scripts/touch_controls.gd`: floating joystick on the left half, A and B buttons on the right. Left-handed
  (`Difficulty.is_left_handed()`, read in `_ready()`) mirrors it: joystick on the right half, A and B bottom left.
  Place anything new through `mirror_x(p)` and test the joystick zone with `on_joy_side(pos)`.
- Road Trip (Phase 5; progression in Phase 8): static data and logic, and screens built in code (each a CanvasLayer
  from its own script):
  - `scripts/flow.gd`: scene flow (static). `Flow.go(screen, args)` reloads `main.tscn` into a screen; `Flow.match`
    is the next trip game, `Flow.last_result` the last one. Screen table in `SCREENS`.
  - `scripts/trip.gd`: the trip's progress and rules (static): games per city, retries, stat points, recruits,
    starters, the New York bracket, where CONTINUE resumes, `match_for()`. `scripts/save.gd`: the save file
    `user://trip.json` (temp file + rename; tests use `user://trip_test.json`).
  - Phase 8 in `trip.gd`: every win pays each of the 3 starters his own stat points (`POINTS_CITY_GAME` 1 for city
    games 1-2, `POINTS_BOSS_GAME` 2 for the boss game and each New York round; every level; each game once per trip,
    `paid`; the bench gets none). Star roster slots (`Stars.slots()`, `open_slots()`): `draft(id)` signs any player
    of a crew beaten on this trip, bosses too, at his city's stage ratings (final for the trip, via "draft"). One
    boss at most among the 3 starters (`BOSS_LIMIT`, `starters_ok()`; however he joined; a save with more is repaired
    on load, `boss_repair`). Replays (`start_replay()`, `stage_reached()`): any game won on this trip, from the map
    between games or after the trip, opponents at the stage reached, stars only (no points, story, recruit, unlocks
    or record); the trip never moves. Opponents get `Difficulty.rating_bonus()` (LEGEND), each stat <= `BOSS_CAP` 95.
  - Save version 2 (`save.gd` `VERSION` 2): each roster entry has `pts` (his unspent points) and `via` (start /
    recruit / draft); the trip has `crew_points` (anyone may spend them), `paid` (game keys) and `replay` ({} or
    {city, game}); `points` is still written (the total), so 1.0.0 still reads it. A version 1 save catches up on
    load: its pool plus `CATCHUP_*` become crew points, every won game is paid, its stars are credited once.
  - `scripts/cities.gd`: the 8-city route, cities (court look, music, twist), crews and players as const data
    (stage ratings, tiers, game targets). `scripts/ratings.gd`: the five stats (speed, shooting, finishing,
    defense, stamina) and how they map onto play.
  - `scripts/stars.gd` (static, `Stars`): 1 / 2 / 3 stars for a win on Easy / Normal / Hard (LEGEND 3) per city game
    and New York round, best kept (`MAX` 72), in section "stars" of the settings file (tests: `settings_test.cfg`);
    a NEW TRIP keeps them. `REWARDS` is the ladder: jersey 6, slot 12, ball 18, slot + van 24, court 30, slot +
    jersey 36, ball 42, slot + van 48, jersey 54, court + ball 60, van 66, LEGEND 72.
  - `scripts/cosmetics.gd` (static): the star rewards you wear (3 jerseys, 3 balls, 3 van paints; `ITEMS`, picks in
    section "cosmetics") and the 2 Quick Game court looks; `ball_sheet()`, `van_path()`, `jersey_suffix()`,
    `jersey_clashes()`. A missing file or a locked pick falls back to the default.
  - `scripts/ui_kit.gd`: the shared look for the screens (buttons, panels, sliders).
  - `scripts/title.gd`: screens "title", "settings", "crew" (ROAD TRIP with its "STARS n/72" tab / QUICK GAME /
    LOCKER / SETTINGS / HOW TO PLAY / CREW & CREDITS, the version bottom-right). Settings: MUSIC on/off and volume,
    SOUND, LEVEL (LEGEND once open), FULL SCREEN, LEFT-HANDED. CREW shows each player's points, DRAFTED tags and the
    crew points. The credits list is `CREDITS_LIST` (keep it in step with `CREDITS.md`), then the Godot license.
  - `scripts/locker.gd`: "locker" (from the title, BACK to `args.back`): the star ladder (scrolls) and the JERSEY,
    BALL and VAN picks (CLASSIC + 3 tiles each; a tap wears an open one, saved at once).
  - `scripts/howto.gd`: "howto", the How to Play pages (`PAGES` data: picture `assets/howto/<id>.png`, title, lines;
    < > buttons or a swipe; BACK to `args.back`).
  - `scripts/trip_map.gd`: "map" (USA map, pins with their best stars, the van in its picked paint, GO, the city's
    twist line; a pin with won games opens the replay picker; a finished trip opens in replay mode).
    `scripts/story.gd`: "story" (portraits and text box); the lines are data in `scripts/story_text.gd` (also
    `RECRUIT_LINES`, one per recruit). `scripts/lineup.gd`: "lineup" (pick 3 starters, the first is you; points
    badges and the STAT POINTS card, OPEN SLOT cards to the draft, BOSS tags and the one-boss rule).
  - `scripts/draft.gd`: "draft" (`args.back` "lineup"): the beaten crews' players by crew; pick one, SIGN, confirm.
  - `scripts/after_game.gd`: "result" (score, the points each starter won, the stars (NEW STAR / NEW BEST, n/72),
    any reward just unlocked, RETRY / NEXT) and "points" (spend stat points: after every win the 3 starters with
    SKIP; after a city or from elsewhere the whole roster; crew points go to anyone).
    `scripts/recruit.gd`: "recruit" (sign one of 3; he says his joining line). `scripts/bracket.gd`: "bracket"
    (New York, 3 rounds).
  - `scripts/pause.gd`: the pause button (top-right) and panel in every human game (with the twist line).
  - `scripts/trip_test.gd`: the `--trip-test` driver (plays a whole trip headless through each screen's
    `auto_step()`).
- `scripts/countdown.gd`: the 3-2-1-GO! countdown at the start of every match (main.gd freezes play and input until GO!;
  timing, sizes and sounds are constants at its top).
- `scripts/howto_shots.gd`: the `--howto-shots DIR` capture driver (test only; main.gd adds it to a seeded
  `--humantest` game; it only watches and saves `DIR/howto_<id>.png`, prints `HOWTO SHOTS <n>/9`).
- `assets/`: original art made by `tools/art/`: `players2/` (v2.1 player sheets: 64 x 96 frames drawn 2x, indexed
  8-bit gray pages `<id>_p<N>.png`, `palettes/<id>.png` per sheet, per `_crew` recolor and per star jersey `_j<N>`,
  `palettes.json`, `format.json` (the truth for frames and animations), body-keyed `hands.json` (hand and ball
  points), `cards/`), `courts/` floors and backdrops (with `midnight_*`, `gold_hall_*`), `ball/` (`ball_1..3` the
  star balls), `portraits/` story portraits, `map/` trip map (`van_1..3` the van paints), `icon/` app icons,
  `howto/` the How to Play pictures; `sfx/` (with the twist sounds and the reward and countdown sounds) and `music/`
  (see `CREDITS.md`). The v1 sheets (`assets/players/`) were removed in P6-25. The old Kenney Sports Pack sprites
  (`assets/*.png`, facing +x) are only a fallback when a player has no sheet at all.
- `project.godot` imports lossless textures as PNG (`force_png`), so the indexed pages stay 8-bit. Keep it.
- `tools/`: `art/make_players_v2.py` (the player sheets from `art/crews.json`; uses `art/make_anim_sample.py`, the
  approved animation sample, and the parts loader of the retired v1 generator `art/make_players.py`, whose own
  output is no longer committed; renderer `art/pixel3d.py`; `--jerseys` the star jerseys), `art/make_courts.py`
  (courts and balls), `art/make_cosmetics_preview.py` (`docs/art/cosmetics_preview.png`, every star cosmetic on
  one sheet for the owner; reads only), `art/make_portraits_v2.py` (portraits, drawing kit `art/comic.py`),
  `art/make_map.py` (trip map and van paints), `art/make_icon.py` (`assets/icon/` and `docs/release/cover.png`),
  `art/make_howto.py` (composes `assets/howto/` from the raw captures in `tools/art/howto_raw/`), `make_sfx.sh` /
  `make_music.sh` (sound and music processing), `make_twist_sfx.py` (twist sounds), `make_ui_sfx.py` (star,
  stat_up, unlock, countdown, go; `all` writes them into `assets/sfx/`; needs ffmpeg), `build_web.sh`,
  `build_android.sh`. Python 3 with Pillow and numpy; rerun a generator and commit its output in `assets/`.
- `docs/release/`: the itch.io release kit: `cover.png`, `screenshots/`, `itch_page.md` (the page text), `UPLOAD.md`
  (the owner's upload steps), `ANDROID.md` (the release key and the APK). Release builds go to `build/release/`
  (ignored by git).

## Conventions
- Units: `FT = 12` pixels per foot. Court is 94 x 50 ft. Team 0 (BLUE, human) attacks the right hoop.
- GDScript: don't use `:=` when the right side is untyped (e.g. `game.something`, or `min`/`max`/`clamp`); use an
  explicit type or `minf`/`maxf`. Otherwise the script fails to parse.
- Touch first: every feature must be usable with the joystick plus the two buttons. Keyboard (WASD, J, K) is for
  desktop testing only.
- The simulation stays 2D top-down (positions, velocities, heights, facing). All drawing goes through `view.gd`'s
  projection (`View.to_screen(p, h)` etc.); nothing on screen is placed in raw sim coordinates, and drawing never
  writes back into the simulation.
- Art is generated by the scripts in `tools/art` in the owner-approved style (style sample v1; players in the
  approved animation style, `docs/art/players_v3_moves.gif`), not drawn by hand or downloaded. Any third-party asset
  must be CC0 or CC-BY (no share-alike, no non-commercial) and get a row in `CREDITS.md`.

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
- `--difficulty easy|normal|hard|legend` (or `--difficulty=normal`): the level; it changes RED only. `--autoplay`
  and `--humantest` play Hard without it. With `--autoplay`, RED's win share measures the level (BLUE plays Hard).
  `legend` needs the stars open (`--stars 72`), else it plays Hard.
- `--stars N` (or `--stars=N`, 0..72): this run acts as if the star total were N (slots, cosmetics, LEGEND); never
  saved, the per-game bests stay the real ones.
- `--wear id[,id...]` (or `--wear=...`): wear these jersey / ball / van items this run (`cosmetics.gd` ids, e.g.
  `--stars 72 --wear jersey_2,ball_1`); only unlocked ones show, never saved.
- `--target N`: play to N instead of 21 (sides switch at (N + 1) / 2), e.g. `--target 3` for a short game.
- `--force-fouls`: fouls some released field goals, to exercise the free-throw path.
- `--menushot` (xvfb, like `--shots`; add `--target 3`): screenshots of the launch and game-over difficulty panels.
- `--view flat|angled` (or `--view=angled`): the drawing mode (default angled). The simulation is the same in both.
- `--court <look>` (or `--court=blacktop`): the court look for this run (overrides the saved choice): `gym`,
  `blacktop`, a city look (`barn`, `rooftop`, `soul_gym`, `bayou`, `mountain`, `rain_park`, `beach`, `cage`) or a
  star reward look (`midnight`, `gold_hall`); any look, locked or not.
- `--twist <id>`: play with this twist (`none`, `wind`, `crowd`, `humid`, `thin_air`, `wet`, `sand`, `cage`); wins over
  the city's or court's twist.
- `--unlock-all` / `--unlock-none`: Quick Game courts and teams as if every city's boss was beaten / as on a fresh
  install.
- `--quick-teams <blue>,<red>` (or `--quick-teams=a,b`): the Quick Game crews (ids: the crew name in lower case with
  `_`, e.g. `cornfield_kings`, `county_line`, `concrete_crowns`; any crew, locked or not). Test runs otherwise play
  the Kings vs the Bridge Runners, never the saved picks.
- `--perspective k`: try a far-side narrowing of k (e.g. 0.15; the game uses 0).
- `--shots-dir DIR`: where `--shots` and `--menushot` save their images (default `/tmp`).
- `--ballshots [DIR]` (xvfb, angled): screenshots of the ball (dribble, lob, rim, dunk, loose) to DIR, default `/tmp`.
- `--twistshots DIR` (xvfb): screenshots of the game's twist effects to `DIR/hoops_twist_<id>_<frame>.png`.
- `--pauseshot` (with `--humantest`, xvfb): saves the open pause panel to `/tmp/hoops_pause.png`.
- `--texmem` (xvfb or web, not headless): prints the texture and video memory once a game runs (`TEXMEM` line).
- `--players2-dir DIR`: read the v2 player sheets from DIR (`res://`, `user://` or absolute) instead of
  `assets/players2/`.
- `--viewtest`: checks the projection round trip and stick mapping, prints the result and quits.
- `--left-handed` / `--right-handed`: the mirrored or the normal touch layout for this run (wins over the saved
  setting; never saved). Without either, test runs play the right-handed layout.
- `--music-volume X` (or `--music-volume=X`, X in 0..1): the music volume for this run, never saved.
- `--fps`: prints the frame rate every few seconds.
- `--no-countdown`: skip the 3-2-1 countdown at the start (also skipped in `--howto-shots` and `--twistshots`).

Phase 6 checks:
```
# the twist table: every hook key has its default, twist none changes nothing; prints TWISTTEST OK and quits
godot --headless --path . -- --twisttest
# every player sheet (format, sizes, empty frames, hand and ball points), Sheets.self_test(); ANIM OK (exit 0) or
# ANIM FAILED (exit 1). Under xvfb (no --headless) it also writes contact sheets and strips to /tmp
godot --headless --path . -- --anim-test
```
- `--anim-test` sub-flags: `--anim-sheet id[,id...]` (only these sheets), `--anim-out DIR` (images there),
  `--anim-shots` (write the images headless too), `--anim-fake-v2` (also test the v2 path on a built-in fake sheet).

Phase 8 checks (both in scratch files, never the owner's or the trip test's settings; exit 0 on OK, 1 on FAILED):
```
# the star store and the reward ladder (Stars.self_test()); prints STARTEST OK or STARTEST FAILED: <why> and quits
godot --headless --path . -- --startest
# the cosmetics store: picks, locks, fallbacks (Cosmetics.self_test()); prints COSMETICTEST OK or FAILED and quits
godot --headless --path . -- --cosmetictest
```

Road Trip tests (Phase 5). Every test mode above skips the title screen and plays a Quick Game as before; the trip
tests use `user://trip_test.json`, never the owner's save:
```
# a whole trip headless through every screen: title, the 7 cities (3 games, points, recruit each), the New York
# bracket, ending.
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
- `--backtest`: sends the Android back request on every screen and checks where it lands (title quits, a game
  pauses and resumes, other screens go BACK, draft and locker too, the map's replay picker closes; result, points and
  recruit ignore it); plays with 12 stars (one slot open for the draft); prints `BACKTEST OK` or fails.
- `--titletest` also visits the LOCKER and back; it puts every setting back and restores `user://settings.cfg` byte
  for byte at the end.
- `--trip-force-loss N` (with `--trip-test`): the Nth trip game of this run is lost, to test the retry.
- `--trip-stop-after <city>` (with `--trip-test`): quits on the map once that city is done ("TRIP STOP", saved).
- `--trip-resume` (with `--trip-test`, a new process): loads the test save and plays on from there.
- `--screens` (with `--trip-test`, xvfb): screenshots of every screen to `/tmp/hoops_screen_NN_<screen>.png`; each trip
  game is then decided at once.
- Phase 8 checks in `--trip-test` (P8-23; any broken one is a TRIP ERROR): after every game its stars (best kept, the
  level's 1/2/3 on a win) and its points (each game paid once; losses and replays pay nothing), at TRIP END all 24
  games paid and every game at the level's stars, and the level is `--difficulty`'s. The first title of a run visits
  the LOCKER (back to the title); the first lineup with an open star slot drafts one player through the OPEN SLOT card
  and the DRAFT screen (`--stars 12` or more; also when the test settings file's own stars open a slot); the first map
  after Memphis plays one replay from its picker and checks the trip did not move (city, game, phase, record, points,
  paid, starters; the driver keeps the starters in replays). Run it on every level, e.g. `--difficulty easy`,
  `normal`, `hard` and `--difficulty legend --stars 72`. Stars a run wins stay in `user://settings_test.cfg`.
- `--mapshot DIR [--map-pick <city>]` (with `--trip-test --trip-resume`, xvfb): on the first map saves
  `DIR/hoops_map_*.png` (the map with its stars, the open replay picker of that city, default the last one won),
  starts a replay and backs out (the marker must be gone), then PLAYs it for real and shoots the map after it;
  prints `MAPSHOT` lines. DIR defaults to `/tmp`.
- `--city <id> --cgame N` (N = 1..3, default 1): play that city game's matchup (crews, ratings, target, court, music,
  twist) CPU vs CPU, or with `--humantest` / a screenshot mode. Ids are the `cities.gd` keys (`hometown`, `chicago`,
  `memphis`, `new_orleans`, `denver`, `seattle`, `los_angeles`, `new_york`).
- `--expected-roster` (with `--city`): BLUE is the crew a trip would really have there (the 3 underdogs start and
  earn every point, each on his lowest stat; recruits on the bench, no drafts): a lower bound for the ramp.
- `--best-roster` (with `--city`): BLUE is the strongest legal three a trip could field there (4 star slots open,
  the best recruit and drafts, at most one boss among the starters): the upper bound. The ramp (P8-25,
  `docs/qa/phase8-ramp.md`): `Cities.STAGE_AVG` 40 / 46 / 52 / 58 / 63 / 68 / 73 / 78, `LEGEND_BONUS` 12.

After gameplay changes, run several `--autoplay` games and check the stats look sane. A typical game to 21 is about
55-90 shots at about 50% (P7-T1: was 75-120 at about 35%) and 7-11 minutes of game time (`GAME LENGTH`), ends 21-x
(the loser usually 12-20), has about 1-5 fouls and 1-2 out of bounds, one side switch, and few interceptions or
shot-clock violations.
Look at a screenshot after visual changes.
Judge team balance on 200+ `--autoplay` games: 40-game batches swing up to about 65/35 by chance
(docs/qa/phase3-length.md). `--autoplay` picks the first ball at random.

How to Play pictures (two steps; the raw captures are committed, so step 2 alone reruns the pictures):
```
# 1. the game captures (8 pages and the insets) to DIR, from a seeded game; prints HOWTO SHOTS <n>/9
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- \
    --howto-shots DIR --court gym --difficulty hard --quick-teams cornfield_kings,bridge_runners
# the trip page: the first map and the lineup_picked screen (/tmp/hoops_screen_04_map.png, ..._21_lineup_picked.png)
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 \
    --quit-after 2000000 -- --trip-test --target 3 --screens
# 2. copy them into tools/art/howto_raw/ as howto_<id>.png (howto_trip.png, howto_trip_b.png), then compose
python3 tools/art/make_howto.py
```
- `--howto-dir DIR` (How to Play screen): read the pictures from DIR instead of `assets/howto/`.

## Release builds (Phase 7)
- `tools/build_web.sh --zip`: a fresh web build plus the itch.io ZIP `build/release/road-trip-hoops-<version>-web.zip`
  (flat, `index.html` at the root); `--zip --publish` does both.
- `tools/build_android.sh`: the debug APK `build/release/road-trip-hoops-<version>-debug.apk`. `--release` signs
  `build/release/road-trip-hoops-<version>.apk` with the owner's key, given only through
  `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD` (never in a file, never in the repo; keystores
  `*.keystore` / `*.jks` are git-ignored). Needs the 4.3 Android templates, a JDK and the apt tools
  (`apksigner zipalign adb aapt`); without `ANDROID_SDK_ROOT` it builds a stand-in SDK from them under
  `~/.cache/road-trip-hoops-android`. Setup in `docs/TEAM.md` ("Android APK"), the owner's side in
  `docs/release/ANDROID.md`.

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
- `CREDITS.md`: every asset with its source and license. Only CC0 or other licenses that allow commercial
  redistribution (CC-BY rows: title, author, license link, source, changes). The in-game CREW & CREDITS list
  (`CREDITS_LIST` in `title.gd`) shows the same; keep them in step.
