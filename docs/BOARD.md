# Task Board

Current phase: **Phase 4: 3/4 view, pixel art and audio** (planned 2026-11-16 by `lead-producer`). The Phase 3 board
is archived in `docs/board-phase3.md`, Phase 2 in `docs/board-phase2.md`, Phase 1 in `docs/board-phase1.md`.

Scope (from `docs/VISION.md`): (a) switch the camera to the angled 3/4 view (decided by the owner) while the
simulation stays 2D top-down underneath: one projection function, a foreshortened court, depth-sorted upright
sprites, hoops with backboards and poles, ball height and shadow, popups and effects placed through the projection,
the joystick mapped to the view, HUD unchanged. (b) The full player sprite set in the approved style (sample v1),
made by a generator script so new players (Road Trip recruits, Phase 5) are cheap. (c) Ball and hoop art, two court
looks set by data (wood gym and an outdoor blacktop; the rest come in Phase 6), effects. (d) Audio: a music player
with a menu track and 2-3 city tracks (CC0/CC-BY only), synthesized swish and bounce, everything in `CREDITS.md`.
Not in scope: title screen, trip map, city data beyond the two looks, saving (Phase 5); settings screen and the
in-game credits line (Phase 7); new gameplay or tuning. **Gameplay must not change in this phase.**

Format: `ID | task | owner role | files | done when | depends on`

Rules for every task in this phase:
- Godot 4.3 compatible; no `:=` with an untyped right side (`game.x`, `min`/`max`/`clamp`); use an explicit type or
  `minf`/`maxf`/`clampf`. Tuning constants go at the top of the script they belong to, with a comment. Touch first:
  joystick + A (orange) + B (blue) during play, no new in-game buttons. No new `.tscn` scenes: new scripts are built
  in code (`view.gd`, `court_looks.gd`). Nearest filtering stays on (pixel art).
- A task touches only the files listed. If it needs another file, stop and tell the coordinator.
- **Drawing only.** No task may change how the simulation moves, decides or scores: `position`, `velocity`, `z`,
  `jump_z`, `facing` and every timer keep their meaning and values. Visual-only values (heights, sort keys, frame
  numbers) are computed from them, never written back.
- **Two view modes until P4-11.** `View.mode` is `FLAT` (today's top-down look, the identity projection) by default
  and `ANGLED` with the test flag `--view angled`. Every task must look right in both modes and merge in FLAT, so the
  dev branch always plays like today. P4-11 makes ANGLED the default.
- Each design choice the owner hasn't made yet is a **constant** with the recommended option as its default.
- Assets: CC0 or CC-BY only (no CC-BY-SA, no OGA-BY, no GPL). Every new file in `assets/` gets a `CREDITS.md` row in
  the same task (generated art: "Original, made for this project", with the generator script). Web build budget:
  `index.pck` under 12 MB (it is 0.27 MB now; the engine `.wasm` is the other ~35 MB and doesn't change).
- Tests: `--quit-after 120000` as in CLAUDE.md. Every gameplay task runs 3 `--autoplay` + 1 `--humantest` in FLAT
  and the same in `--view angled`, all reaching `FINAL` with no script errors, plus screenshots (`--shots`) in both
  modes. Report final score, shots and `GAME LENGTH` per game.

## Shared contract (names fixed now so parallel tasks can call each other)

`scripts/view.gd` (new, P4-01; `extends RefCounted`, used through `const View = preload("res://scripts/view.gd")`,
static functions only, no instance):
- `const FLAT := 0`, `const ANGLED := 1`, `static var mode := FLAT` (set from `--view flat|angled` by main.gd;
  P4-11 changes the default). `static func angled() -> bool`.
- Constants (tuning, top of the file): `TILT_Y` (court depth on screen as a fraction of its true depth, start 0.55),
  `PERSPECTIVE` (0 = parallel, a small value narrows the far side; start 0.0, P4-11 tries 0.1-0.2),
  `HEIGHT_SCALE` (screen pixels per sim pixel of height, start 1.0), `RIM_Z := 10.0 * 12` (rim height in sim pixels,
  10 ft), `SIDE_FLIP := false` (Q2 b: view from the other sideline after the switch).
- `static func to_screen(p: Vector2, h := 0.0) -> Vector2`: sim floor point `p` (pixels) at height `h` (sim pixels,
  like `ball.z` and `jump_z`) to canvas pixels. FLAT: `p - Vector2(0, h)` (today's drawing).
- `static func to_floor(s: Vector2) -> Vector2`: the inverse at `h = 0`.
- `static func size_at(p: Vector2) -> float`: sprite scale at `p` (1.0 without perspective).
- `static func stick_to_world(v: Vector2) -> Vector2`: a stick vector in screen terms (up = toward the far sideline
  as seen on screen) to the sim direction that looks like that on screen, **same length** (so speed and turbo don't
  change). FLAT: identity. `static func world_to_stick(v: Vector2) -> Vector2`: the inverse (humantest's thumb).
- `static func screen_angle(p: Vector2, world_angle: float) -> float`: a sim facing angle as seen on screen at `p`
  (sprite direction choice).

Layers (created in `main._ready()` by P4-01; all are Node2D children of main):
- `game.floor_layer` z -10: the court floor instance (court.gd, `draw_rims = false`).
- `game.decals` z -5: things lying on the floor under everyone: shadows, team rings, fire rings, dust, the steal cue.
- `game.world` z 0, `y_sort_enabled = true`: every upright thing. Each child's `position` is its **projected floor
  point** (`View.to_screen(sim_pos, 0)`) and it draws its height offset itself, so Godot's y-sort is the depth sort.
- `game.overlay` z 30: the CALL cue, the human's arrow, stamina bar and shot meter (always on top, never sorted).
- `game.fx` z 50 (as today): popups. `fx.popup(text, world_pos, ...)` keeps its signature; fx projects `world_pos`.
- HUD (CanvasLayer), touch controls and the menu: unchanged.
- Sim nodes (players, ball) stay where they are and keep `position` as the sim position, but stop drawing in their
  own transform: each one creates its view node(s) in `game.world` / `game.decals` / `game.overlay` and updates them
  after its own update each frame.

Hoops (P4-07, `court.gd`): per hoop `i` three nodes in `game.world`: the pole and backboard (sort y = hoop screen y minus 3), the back half of the rim (minus 1), the front half of the
rim and the net (plus 1). `swish(i, k)` keeps its signature. `func hoop_sort_y(i: int) -> float` returns the hoop's screen y. The ball (P4-10) sets its sort y to
exactly `hoop_sort_y(i)` while it is within `BALL_RIM_SORT_FT` of the rim in the air, so it draws behind the front of
the rim and the net and in front of the backboard.

Heights (visual only): the sim treats the rim as height 0 at the end of a shot and uses small jump heights
(`DUNK_JUMP_PX` 30). The views map them: `ball.gd` draws a shot rising to `View.RIM_Z` at the hoop and a rim
rebound falling from there, a made shot dropping through the net; `player.gd` scales a dunk or alley-oop jump so the
hands reach the rim (constant `DUNK_VIEW_LIFT`). Held ball: drawn at the holder's hand height in screen space.

Player sprite sheets (P4-03 makes them, P4-06 plays them; layout fixed here):
- One PNG per player: `assets/players/<id>.png`, ids `blue_1`, `blue_2`, `blue_3`, `red_1`, `red_2`, `red_3`
  (index 0-2 in the team = `_1`-`_3`). Frame 40 x 64 px, feet on row 59, character about 24 x 40, no ball and no
  ring baked in (the ball and the team ring are drawn in code). Drawn at 2x (`PLAYER_SCALE := 2.0` in player.gd).
- 5 rows = drawn directions: 0 S (facing the camera), 1 SE, 2 E, 3 NE, 4 N (back to the camera). SW, W, NW are
  rows 1, 2, 3 mirrored (`flip_h`). E = +x on screen.
- 37 columns, animations in this order (start column, frames): idle 0 (2), run 2 (6), dribble 8 (4), shoot 12 (4),
  dunk 16 (5), layup 21 (3), block 24 (3), poke 27 (2), stumble 29 (2), pass 31 (2), celebrate 33 (4).
  Sheet size 1480 x 320. Free throw = shoot; pump fake = shoot frames 0-1 and back; crossover = dribble, faster
  and leaning; alley-oop = dunk. The 6 VISION animations plus layup, poke, stumble and pass, which the game shows now.
- A missing sheet must not break the game: player.gd falls back to today's Kenney texture.

## Risks and how this plan handles them
- **Gameplay drift.** All work is drawing; FLAT mode keeps the old look on the dev branch; P4-00 measures a
  100-game baseline now and P4-12 repeats it on the final build (each stat within 2 standard errors). Autoplay doesn't
  touch the stick, so a drift there means a drawing task wrote to sim state.
- **Joystick in a foreshortened view.** One mapping function (`View.stick_to_world`, same length), applied in
  main.gd before the stick reaches `human_input` and the players; the humantest thumb goes through the inverse.
  P4-12 compares human steals, blocks, crossovers and defensive-assist use between FLAT and ANGLED humantests and
  plays it by hand in Chromium with touch emulation.
- **Depth sorting** of ball vs players vs rims vs backboard: y-sorted `game.world` plus the rim sort rule above.
  P4-12 screenshots a made shot, a rim-out and a dunk at each hoop.
- **The far sideline.** Players on the far sideline are small and high on screen, the near sideline is under the
  thumbs. Camera framing constants (P4-01) plus Q1 and Q3; P4-12 checks 1280x720 and 1280x800 (stretch `expand`
  shows more court on 16:10) with a player on each sideline and in each corner.
- **Heights** (rim at 10 ft but the sim's shot ends at height 0): visual-only mapping (see Heights); QA checks
  shots, rebounds and dunks look like they go through the rim.
- **Sheet and build size:** 6 sheets of 1480 x 320 (well under the 2048 px WebGL limit), budget 1 MB for all player
  art; music as mono Ogg Vorbis about q3, 1-2 MB per track; `index.pck` under 12 MB.
- **Tablet performance:** about 15 sorted nodes; the court floor is drawn once (not every frame), nets redraw only
  while animating. `--fps` (P4-01) prints the frame rate; P4-12 measures it in Chromium (target 55+ fps at
  1280x800 with 4x CPU throttle) and reports draw calls from the Godot monitor.
- **Shimmering pixels** with a non-integer camera zoom (today 1.15) and nearest filtering: P4-11 picks a zoom that
  keeps 2x sprites crisp, or snaps sprite positions to whole pixels; P4-12 looks at a slow pan.
- **Web audio:** browsers start sound only after the first touch; music must start (or resume) on the first tap, and
  never play in headless tests (like audio.gd today).

## Owner questions (to ask now; answers go here and in `docs/VISION.md`)
- **Q1 Camera framing.** (a) Follow the ball left and right, zoomed in so about two thirds of the court length shows
  and both sidelines are always on screen (recommended: bigger players, classic arcade feel); (b) the whole court
  always on screen, no camera movement (smaller players); (c) closer still, following the ball both ways (biggest
  players, the far sideline sometimes off screen). How steep the angle looks is judged at the check-in.
- **Q2 Side switch at 11.** (a) The camera stays on the same sideline; after the switch BLUE attacks to the left, as
  today (recommended); (b) the view swings to the other sideline so BLUE always attacks to the right.
- **Q3 Behind the far sideline.** (a) A strip of scenery that fits the court: bleachers with a crowd in the gym, a
  fence and street in the blacktop (recommended); (b) a plain dark border, like today.
- **Q4 Trying the two courts before the trip map exists.** (a) A COURT button on the start and game-over panels
  switches Gym / Blacktop, and the music follows the court (recommended); (b) the court changes every game by itself;
  (c) only the gym for now (the blacktop stays in the files for Phase 5).
- **Q5 Music during games.** (a) Menu music on the panels, the court's track softly during play, and a MUSIC ON/OFF
  button on the start and game-over panels (recommended); (b) music on the panels only, crowd and effects during play;
  (c) music everywhere, no on/off button until the Phase 7 settings.

## Owner answers (2026-11-16, also in docs/VISION.md): every question got the recommended option
- Q1 camera: follow the ball, ~2/3 of the court length, both sidelines always visible.
- Q2 side switch: the camera stays (BLUE attacks left after the switch).
- Q3 behind the far sideline: court scenery (gym bleachers + crowd; blacktop fence + street).
- Q4 trying courts: COURT button on the start/game-over panels (Gym / Blacktop); music follows the court.
- Q5 music: menu music on the panels, the court's track softly in game, MUSIC ON/OFF on the panels (remembered).

## Todo

### Wave 1: can start now (no owner answers needed)

**P4-00 | Gameplay baseline before the view change | qa | `docs/qa/phase4-baseline.md` (report only)**
- On the current dev branch: 100 `--autoplay` games (Hard) and 3 `--humantest`. Table of means and standard errors:
  final scores, shots, FG%, 2s, `GAME LENGTH`, steals/blocks per 60 shots, fouls, free throws, OOB, lobs,
  interceptions, crossover beats, fake bites, shot-clock violations, BLUE win share; human counters from humantest.
  Also the web build `index.pck` size and an fps reading in Chromium (Playwright, 1280x800, touch emulation).
- Done when: the report has the table and the exact commands, so P4-12 can repeat them.
- Depends on: none.

**P4-01 | Projection core, layers, camera, stick mapping | gameplay (A) | new `scripts/view.gd`, `scripts/main.gd`**
- `view.gd` per the contract (FLAT and ANGLED; ANGLED is a parallel tilt with `PERSPECTIVE` support).
  `--view flat|angled` and `--fps` (prints `FPS n` every 5 s) parsed in main.gd.
- main.gd: create `floor_layer`, `decals`, `world` (y-sorted), `overlay`; the floor court instance goes in
  `floor_layer`, the rims instance stays as today until P4-07 replaces it. Camera follows
  `View.to_screen(ball.position, 0)` with limits from the projected court corners plus margins; framing constants at
  the top (`CAM_ZOOM`, `CAM_FOLLOW_X`, `CAM_FOLLOW_Y`, `CAM_MARGIN_FT`) set for Q1 (a). Stick: `_input_vector()`
  result goes through `View.stick_to_world` before `input.update` and `p.update`; the humantest thumb (world
  directions) goes through `View.world_to_stick`. The CALL cue and steal cue draw through `View.to_screen` (cue in
  `overlay`, steal ring in `decals`).
- A `--viewtest` flag prints `VIEWTEST OK` after checking `to_floor(to_screen(p)) == p` (under 0.5 px) on a grid
  and `stick_to_world` keeps length, then quits.
- Done when: FLAT looks like today (screenshots side by side) and 20 autoplay games match P4-00 within noise;
  `--viewtest` passes; with `--view angled` the game runs to FINAL (players and ball still flat-drawn, that's expected),
  the camera keeps the ball framed, and humantest's human stats are close to FLAT's.
- Depends on: none. Merge early: wave 2 needs `view.gd`.

**P4-02 | Music player | gameplay (B) | `scripts/audio.gd`**
- `func play_music(track: String, fade := 1.0)`, `func stop_music(fade := 1.0)`, `func set_music_on(on: bool)`,
  `var music_on := true` (saved later by the panel task). Tracks are `res://assets/music/<track>.ogg`, looping; a
  missing file is skipped with one print (like effects). Crossfade with two players. `MUSIC_DB` (start -14 dB),
  `MUSIC_DUCK_DB` (lower during play, Q5 a). Never plays in headless runs. Stats `music_<track>`.
- Done when: with a test ogg the track loops and crossfades (desktop run), headless runs show no errors and no
  leftover audio at exit; nothing calls it yet (P4-11 wires it).
- Depends on: none.

**P4-03 | Player sprite generator, part 1 | art-audio | new `tools/art/pixel3d.py`, new `tools/art/make_players.py`, new `tools/art/crews.json`, new `assets/players/*.png`, `CREDITS.md`**
- Move the renderer of `draw_style_sample.py` (3D primitives, 4-tone shading, outlines, face stamps) into
  `pixel3d.py` without changing its output (rerun the sample: pixel-identical), or import it from the sample
  unchanged; `draw_style_sample.py` may only change its imports.
- `crews.json`: one entry per player: id, crew, body type, skin, hair, face extras, outfit pieces, colors, number.
  The 4 approved sample players plus one new player per crew built from the same parts (the owner judges them at the
  check-in). Adding a recruit = one more entry.
- `make_players.py` writes the 6 sheets in the contract layout: idle, run and dribble in all 5 directions now, the
  other columns filled with idle frames (layout final, so P4-06 can integrate). A preview sheet goes to
  `docs/art/players_preview.png` (not exported).
- Done when: 6 sheets at 1480 x 320, transparent background, feet on row 59, run cycle reads at 2x, all under 1 MB
  together; CREDITS row added; preview image attached to the report.
- Depends on: none.

**P4-04 | Synthesized swish and bounce | art-audio | new `tools/make_swish.py`, new `tools/make_bounce.py`, `assets/sfx/swish.ogg`, `assets/sfx/bounce.ogg`, `CREDITS.md`**
- Like `tools/make_whistle.py`: a net swish (filtered noise burst with a soft rattle) and a basketball bounce (a
  pitched rubber thump with a short ring), mono Ogg Vorbis, peak-normalized. Same file names, so no code changes.
  Replace the two CREDITS rows (the Vinrax and AntumDeluge stand-ins leave).
- Done when: both files play in the game (desktop or web run), the dribble stays soft at the -8 dB the owner set,
  CREDITS updated, the old source files are gone.
- Depends on: none.

**P4-05 | Music tracks | art-audio | new `assets/music/*.ogg`, new `tools/make_music.sh`, `CREDITS.md`**
- From `docs/phase4-asset-scout.md`, CC0 first: menu "Hella Bumps" (cynicmusic, CC0); gym court "Wednesday Night
  [Funk Fusion]" (Zane Little, CC0; Memphis, the old-school gym); blacktop "Catchy Swing" (Doge, CC0; New Orleans, the
  bayou blacktop); Hometown "Apple Cider" (Zane Little, CC0) for later. Re-read each license on its page. Mono Ogg
  Vorbis about q3, trimmed to a clean loop, loudness matched; file names `menu`, `gym`, `blacktop`, `hometown`.
- Done when: 3-4 tracks, together under 7 MB, loop without a click, CREDITS rows with the exact page and license.
- Depends on: none (Q5 decides only when they play).

### Wave 2: after P4-01 is merged

**P4-06 | Player rendering in 3/4 | gameplay (A) | `scripts/player.gd`**
- A view node per player in `game.world` (sprite from the player's sheet; fallback Kenney texture), positioned at
  `View.to_screen(position, 0)` and scaled by `View.size_at`; the jump drawn as a height offset (dunk lift per
  Heights). Direction: `View.screen_angle(position, facing)` to 8 directions (rows and `flip_h` per contract).
  Animation per state: idle, run (speed-scaled fps), dribble (has the ball; crossover faster with lean), shoot (also
  free throw, pump fake frames 0-1), dunk (also alley-oop), layup, block jump, poke (steal attempt), stumble (beaten,
  off balance), pass, celebrate (scorer after a make, the winners at game over). Constants for fps per animation.
- Shadow, team ring (soft, team colored, like the sample), fire ring and dust go to a node in `game.decals`; the
  human's arrow, stamina bar and shot meter to a node in `game.overlay`, all through `View.to_screen`.
- Done when: FLAT and ANGLED screenshots of all six players running, dribbling, shooting, dunking, blocking;
  the sprite direction matches movement in all 8 directions; autoplay stats within noise; nothing in the sim reads the
  new nodes.
- Depends on: P4-01; P4-03 for real sheets (the fallback lets it start and merge before).

**P4-07 | Court and hoops in 3/4, court looks by data | gameplay (B) | `scripts/court.gd`, new `scripts/court_looks.gd`**
- `court_looks.gd`: `const LOOKS := {"gym": {...}, "blacktop": {...}}` with floor texture or colors, line color,
  paint color, center logo color, apron, backdrop kind (Q3), backboard style (glass / metal), net color. `static var
  current := "gym"`; a test flag `--court gym|blacktop` (parsed here). Plain dictionaries, easy to edit on the tablet.
- Floor: the court drawn through `View.to_screen`: floor (texture tiled on a subdivided grid so it foreshortens),
  lines, keys, arcs, center circle as projected polylines; the apron; the far-side backdrop strip (Q3 a, flat border
  with Q3 b). Drawn once per look, not every frame.
- Hoops per the contract: pole, backboard (with the square), rim back half, rim front half and the net, as three
  y-sorted nodes per hoop in `game.world`; the net animation (`swish`) projected. FLAT keeps today's look.
- Done when: ANGLED screenshots of both looks show both hoops, the full far sideline and the backdrop; FLAT matches
  today; the floor isn't redrawn every frame (check with the profiler or a counter).
- Depends on: P4-01; P4-08 for textures (flat colors until then). The backdrop waits for Q3; the rest can start.

**P4-08 | Court textures, backdrops and ball art | art-audio | new `tools/art/make_courts.py`, new `assets/courts/*.png`, new `assets/ball/*.png`, `CREDITS.md`**
- Our own pixel art in the sample's style (generated, so no attribution): a seamless wood plank tile and a blacktop
  asphalt tile (32 x 32 or 64 x 64), backdrop strips for Q3 a (gym bleachers with a crowd, blacktop fence and street),
  a 16 x 16 ball with 4 spin frames and a highlight. CC0 fallbacks from the scout (MonoTone or Leozlk ball; Pixel
  Courts tiles are CC-BY 4.0) only if ours doesn't read well; record any used in CREDITS.
- Done when: files in place, tiles seamless (a 4 x 4 tiled test image in the report), all under 0.5 MB.
- Depends on: none for the tiles and ball; the backdrops wait for Q3.

**P4-09 | Player sprite generator, part 2 | art-audio | `tools/art/make_players.py`, `tools/art/pixel3d.py`, `assets/players/*.png`**
- The remaining animations in all 5 directions: shoot 4, dunk 5, layup 3, block 3, poke 2, stumble 2, pass 2,
  celebrate 4, plus 2 idle frames (breathing). Celebrate uses the sample's celebrating face.
- Done when: all 37 columns are real frames for all 6 players; preview sheet updated; still under 1 MB.
- Depends on: P4-03.

### Wave 3: needs Q1, Q2, Q4, Q5; wave 2 merged

**P4-10 | Ball and effects in 3/4 | gameplay (A) | `scripts/ball.gd`, `scripts/fx.gd`**
- Ball view in `game.world` at its projected floor point with the visual height per Heights, the rim sort rule
  (`BALL_RIM_SORT_FT`), shadow in `game.decals` (shrinks with height), spin frames from P4-08 (Kenney ball if
  missing). fx: popups at `View.to_screen(world_pos)`, the fire trail through `View.to_screen(pos, z)`, shake
  unchanged. Pixel puffs for landing dust and block sparks only if they come from P4-08 or are drawn in code.
- Done when: ANGLED screenshots: a jump shot in flight, a swish (ball behind the front rim, in front of the board),
  a rim-out, a dunk at each hoop, a bouncing loose ball with its shadow, a popup and the fire trail; FLAT matches
  today; autoplay stats within noise.
- Depends on: P4-01, P4-07 (`hoop_sort_y`). Can start before the owner answers.

**P4-11 | Turn the 3/4 view on; framing, panels, music | gameplay (B) | `scripts/main.gd`, `scripts/view.gd`, `scripts/menu.gd`**
- `View.mode` default ANGLED (`--view flat` stays as a test flag). Framing constants for Q1, the side switch per Q2
  (`SIDE_FLIP`), try `PERSPECTIVE` 0.0 vs a small value and the zoom vs pixel shimmer, and recommend one. Panels:
  the COURT button per Q4 (sets `court_looks.current`, restarts like the level buttons, remembered in
  `user://settings.cfg`) and MUSIC ON/OFF per Q5 (remembered); main calls `audio.play_music` for the menu and the
  court's track (track name in the look's data or a small table in main) and starts it on the first touch on the web.
- Done when: the default run is ANGLED with no flag; screenshots at 1280x720 and 1280x800 with players on both
  sidelines and in the corners; panel screenshots (`--menushot`); music starts after the first tap in Chromium and the
  choice survives a restart.
- Depends on: P4-01, P4-02, P4-06, P4-07 (P4-10 merges in the same wave); Q1, Q2, Q4, Q5.

### Wave 4: everything above merged

**P4-12 | Phase 4 QA | qa | `docs/qa/phase4.md` (report only; small tuning of view constants with the coordinator's OK)**
- Gameplay unchanged: repeat P4-00 exactly (100 autoplay, 3 humantest) on the final build; every stat within 2 SE.
  Humantest FLAT vs ANGLED human stats.
- Visual: screenshots of both looks, both hoops, the side switch, the far and near sidelines, all four corners, a
  dunk, a swish, a rim-out, a block, a steal, free throws, game over, at 1280x720 and 1280x800; a slow pan for
  shimmer; ball vs rim vs backboard sorting.
- Touch: Playwright with touch emulation: pushing "up" moves toward the far sideline on screen, diagonals look right,
  turbo pull, flick crossover, defensive assist.
- Web: `index.pck` size vs budget, fps at 1280x800 (also with 4x CPU throttle), load time, music after the first tap.
- Done when: the report has the before/after table, the screenshots, size and fps, and a PASS/FAIL list.
- Depends on: P4-04 to P4-11.

**P4-13 | README, CLAUDE.md, CREDITS check | gameplay (B) | `README.txt`, `CLAUDE.md`, `CREDITS.md`**
- README: the new view, how to switch court and music (Q4, Q5). CLAUDE.md layout: `view.gd`, `court_looks.gd`,
  `assets/players`, `assets/music`, the generator scripts and how to rerun them; test flags `--view`, `--court`,
  `--viewtest`, `--fps`. CREDITS: every file in `assets/` has a row and a CC0/CC-BY license; Kenney rows removed if
  their files are gone.
- Done when: a fresh clone opens with no missing files; every asset path is in CREDITS.
- Depends on: P4-12.

**P4-14 | Publish the web build | coordinator | `gh-pages` branch (build output only)**
- After P4-12 passes and the phase is merged: `tools/build_web.sh --publish`, then the lead writes the phase summary.
- Depends on: P4-12, P4-13.

## Parallel plan

| Wave | Programmer A | Programmer B | Art-audio | QA |
|---|---|---|---|---|
| 1 (start now) | P4-01 view core (`view.gd`, `main.gd`) | P4-02 music player (`audio.gd`) | P4-03 sprites part 1, then P4-04 swish/bounce, then P4-05 music | P4-00 baseline |
| 2 (after P4-01) | P4-06 players (`player.gd`) | P4-07 court and hoops (`court.gd`, `court_looks.gd`) | P4-08 courts and ball art, then P4-09 sprites part 2 | quick check per merge |
| 3 (Q1, Q2, Q4, Q5) | P4-10 ball and fx (`ball.gd`, `fx.gd`) | P4-11 view on, framing, panels, music (`main.gd`, `view.gd`, `menu.gd`) | P4-09 if not done | |
| 4 | | P4-13 docs | | P4-12, then P4-14 publish (coordinator) |

Why this split: `main.gd` and `view.gd` belong to A in wave 1 and to B in wave 3, never both in one wave. The art
files (`tools/`, `assets/`, `CREDITS.md`) belong only to the art-audio agent until P4-13. P4-10 can start in wave 2
if B finishes P4-07 first and `hoop_sort_y` is merged. Each wave merges and gets a quick QA run (3 autoplay + 1
humantest in FLAT and ANGLED) before the next starts. If the owner answers late, waves 1-2 and P4-10 still finish;
only P4-11 and the backdrop parts of P4-07/P4-08 wait.

## Doing

## Review
- **P4-01** (branch `worktree-agent-acabab04d075939f2`, ffb773e): lead review APPROVE. Merges cleanly into dev.
  View API matches the contract. Extras: `DEFAULT_MODE`, `ANCHOR`, static vars `perspective`/`flipped`, `self_test()`.
  `SIDE_FLIP` is false, so `flipped` stays false and the camera does not flip at the switch (owner Q2 a).
  Checked on the trial merge: `--viewtest` OK, 2 FLAT autoplay runs (16-21, 12-21), FLAT humantest (16-21, snaps 36 =
  flicks 36), ANGLED humantest (21-16, snaps 29 = flicks 29). No script errors.
  For P4-11: the zoom shows about 3/4 of the court length, but the owner chose about 2/3. Remove `VIEW_PROBE`.
  Fix the stale comments on `SIDE_FLIP` and the camera ("until the owner answers").
- **P4-06** (branch `worktree-agent-a13be5c2a01f60557`, c3ea452, `player.gd` only): lead review APPROVE.
  FLAT is drawing-only: the only FLAT-reachable changes are `if View.angled()` guards in `setup()` / `_draw()` and a
  new `_process()` that does nothing while `_v_body` is null. The view code reads sim state and writes only `_v_*`
  vars and view nodes, so the FLAT stats 2 SE off the baseline are noise. FLAT `_draw()` (ring, arrow, stamina bar,
  shot meter, fire ring) is unchanged; CALL bubble and steal cue live in main.gd. Sheets are loaded once, sort is by
  the projected floor point in `game.world`. Checked: FLAT humantest 10-21, ANGLED humantest 21-17, `--shots --view
  angled` (sheet sprites, rings, arrow and stamina bar look right), no script errors.
  Notes for later: about 50 small `PackedVector2Array`s per frame from `_floor_ring` (fine; P4-12 measures fps).
  In ANGLED the shadow and rings are drawn every frame for every player.

## Done
