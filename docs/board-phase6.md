> Archived Phase 6 board, moved here unchanged from docs/BOARD.md on 2026-11-17 when Phase 7 was planned.

# Task Board

Current phase: **Phase 6: content (all 8 cities) and the animation upgrade** (planned 2026-11-17 by `lead-producer`).
The Phase 5 board is archived in `docs/board-phase5.md` (Phase 4: `docs/board-phase4.md`, Phase 3:
`docs/board-phase3.md`, Phase 2: `docs/board-phase2.md`, Phase 1: `docs/board-phase1.md`).

**STATUS: BUILT AND QA'D (2026-11-17).** Every Phase 6 task is merged and done except **P6-42** (web publish and the
owner check-in). Both gates passed: G1 (owner answers, below) and G2 (animation sample approved). The phase summary
for the owner is `docs/phase6-summary.md`. The plan below is kept as written; the task list is in "Done".

Scope (from `docs/VISION.md`, rows "Phase 5 check-in", "Phase 6 design: animation", "Phase 6 design: cities", the
starting city list and the Phase 6 roadmap):
1. **Cities.** All 8 on the route, in this order: Hometown, Chicago, Memphis, New Orleans, Denver, Seattle,
   Los Angeles, New York. Each city gets:
   - a crew: 5 players (2 average, 2 good, a boss), rated by trip stage;
   - its own court look (`court_looks.gd` plus a generated floor and backdrop);
   - a twist: noticeable but fair, the same for both teams, shown with a banner and effects;
   - music: CC0 or CC-BY upbeat chiptune;
   - story scenes (arrival and after-win) and portraits in the approved comic style v2.

   **What Phase 5 already has:**
   - Hometown and Chicago have crews, v1 sheets, portraits and music, but placeholder names, borrowed courts
     (blacktop and gym) and no twists. Phase 6 gives them their own courts and twists: Hometown none (tutorial),
     Chicago wind.
   - New York has music, `ny_boss` art, and a stub bracket whose 8 other players wear the old `red_n` sheets. Phase 6
     gives them real crews, art and a court.
   - Memphis to Los Angeles are map pins only (`built: false`).
2. **Balance the ramp across cities** (QA). Owner: leave the in-city ramp as it is (game 1 to game 3), campaign
   difficulty on their level is about right, and the screens keep their style.
3. **Animation upgrade, a highlight of the game, done side by side with the cities:**
   - Bigger, more detailed players: about 25% taller on screen (owner: "about 100 px, today about 80").
   - New sheet format with many more frames.
   - Standing and running dribble: the legs move and the ball stays in time with the hand.
   - Crossovers, several dunk styles, layups, and jump shots with gather, release and follow-through.
   - Chest, bounce and lob passes; defensive slide; steal swipe; block swat; falling on a crossover; celebrations.
   - Motion effects: squash and stretch, dust on hard cuts, a hang at the top of a dunk, a camera punch on big dunks.
   - The old sheets stay as a fallback until every new sheet exists, and the Kenney fallback rules stay.

Not in scope:
- Boss special moves (owner Phase 5 Q3: no special moves).
- Changes to the in-city ramp or the game lengths, unless the owner changes them in Q10.
- Screen restyling.
- A spin move (VISION: crossover only for now).
- Left-handed layout, How to Play and store exports (Phase 7).
- Quick Game gameplay: it stays as today, except the court choice (Q9).

Format: `ID | task | owner role | files | done when | depends on | blocked by owner questions`

## Rules for every task in this phase
- **Godot 4.3.** No `:=` with an untyped right side (`game.x`, `Flow.match.get(...)`, `JSON.parse_string()`,
  `min`/`max`/`clamp`); use an explicit type or `minf`/`maxf`/`clampf`. Tuning constants go at the top of the script
  they belong to, with a comment.
- **Touch first.** Nothing new to press. Twists are things you feel and see, never a new control.
- **No new `.tscn` scenes.** New code is new `.gd` files built in code (`twists.gd`, `twist_fx.gd`, `sheets.gd`,
  `anim_test.gd`).
- **Simulation and drawing stay apart.** The simulation stays 2D top-down. Everything new on screen goes through
  `View` (`to_screen`, `size_at`). **Animation is visual only.** It reads the sim (velocity, facing, timers,
  `rim_kind`, `jump_t`, `ball.z`) and never writes to it. Sprite size, frame choice, squash, the dunk hang and the
  camera punch must not change any timing, reach, steal window or block window. The sim's dribble (bounce period,
  floor-touch timing for steals) is unchanged; the animation follows the ball, not the other way round.
- **Twists change the sim through `twists.gd` only.** Each hook multiplies or replaces an existing constant through
  `Twists.value(key, default)`. With twist `"none"` every hook returns exactly today's value.
- A task touches only the files listed. If it needs another file, stop and tell the coordinator.
- **Quick Game and the test modes stay as today** (P6-40 checks against P6-00). With `Flow.match` empty the twist is
  `"none"` unless Q9 says otherwise, and the sheets are whatever exists. Behaviour is identical, only the drawing
  changes.
- Data the owner may edit on the tablet (cities, crews, twists, story, looks) lives in `const` dictionaries with
  comments.
- **Assets.** Art is generated by scripts in `tools/art/` in the approved styles: players and courts in style sample
  v1, portraits in comic v2, and the animation in sample v1 once G2 approves it. Third-party assets must be CC0 or
  CC-BY (no SA, no NC), and every asset gets a `CREDITS.md` row.
- **Size budgets.** Web `index.pck` is 5.2 MB today; the budget is set by Q8. **No texture larger than
  2048 x 2048** (WebGL and older Android GPUs).
- **Tests.**
  - Every gameplay task runs 3 `--autoplay`, 1 `--humantest` and `--trip-test --target 3`. All must reach `FINAL` /
    `TRIP END` with no script errors.
  - Every twist task also runs `--city <id> --cgame 1 --autoplay` for its city.
  - Every visual task looks at a screenshot (`--shots`, `--city <id> --shots`, or `--anim-test` once P6-24 exists).

## Shared contract (names fixed now so parallel tasks can call each other)

### Twists (`scripts/twists.gd`, P6-01; `extends RefCounted`, static only, `const Twists = preload(...)`)
```
const TWISTS := {
  "none": {},
  "wind":     {"name": "WIND OFF THE LAKE", "banner": "Wind: long shots and lobs drift", ...numbers (Q1)},
  "crowd":    {...}, "humid": {...}, "thin_air": {...}, "wet": {...}, "sand": {...}, "cage": {...},
}
static var current := "none"
static func set_current(id: String) -> void         # unknown id -> "none" (and a printed warning)
static func value(key: String, default: float) -> float   # the current twist's number, or default (= today)
static func flag(key: String) -> bool               # e.g. "sideline_fence"
static func info() -> Dictionary                    # name, banner line, icon id, for twist_fx / map / pause
```
- Set from `Flow.match.twist` by main.gd at game build time (P6-02). Test flag `--twist <id>` overrides it, in a
  Quick Game too.
- `trip.match_for()` adds `"twist": city.twist` (P6-10).

Hook points. Each is one `Twists.value(...)` call around today's constant; the default is today's value:

| Key | Default (today) | File | Used by |
|---|---|---|---|
| `long_shot_mult` | 1.0 | main.gd `shot_probability()` (shots beyond the arc) | wind, thin_air |
| `shot_clock` | 24.0 (`SHOT_CLOCK_LENGTH`) | main.gd | crowd |
| `speed_mult` | 1.0 | player.gd top speed (after `Ratings.speed_px`) | crowd, sand |
| `turbo_mult` | 1.35 (`TURBO_SPEED_MULT`) | player.gd | sand |
| `stamina_drain_mult`, `stamina_refill_mult` | 1.0 | player.gd (after `Ratings.stamina_*`) | thin_air, humid |
| `cut_grip`, `cut_min_speed`, `cut_angle_deg` | 1.0, -, - | player.gd accel on a sharp turn at speed (crossover bursts keep full grip) | wet |
| `lob_drift_ft`, `wind_dir` (runtime: `Twists.wind` Vector2, set once per game, flips at the side switch only if Q1 says so) | 0 | ball.gd lob target (sim) | wind |
| `shot_curve_ft` | 0 | ball.gd drawn shot path only (visual) | wind |
| `lob_time_mult`, `arc_mult` | 1.0 | ball.gd lob flight time (sim), drawn shot arc (visual) | thin_air |
| `sideline_fence` (flag), `fence_bounce` | false, - | ball.gd `_went_out()`: a loose ball crossing a sideline bounces back in | cage (Q2) |
| `crowd_db` | 0 | audio / twist_fx crowd loop | crowd |

Every hook acts on **all players and both teams the same way**; no hook reads `team`.

### City data (`scripts/cities.gd`, P6-10; done)
- All 8 cities have `built: true`, a `look` (new look ids `barn`, `rooftop`, `soul_gym`, `bayou`, `mountain`,
  `rain_park`, `beach`, `cage`), `music` (track ids `hometown`, `chicago`, `memphis`, `new_orleans`, `denver`,
  `seattle`, `los_angeles`, `newyork`) and `twist` (`none`, `wind`, `crowd`, `humid`, `thin_air`, `wet`, `sand`,
  `cage` (Q2)). The known ids are `Cities.LOOK_IDS`, `MUSIC_IDS`, `TWIST_IDS`; `Cities.twist(id)` reads one.
- Each city also has `"fallback": {"look", "music"}`: `trip.gd` `look_for()` / `music_for()` put the city's own look
  in the match once `court_looks.gd` has it (P6-12) and its own track once `assets/music/<id>.ogg` exists (P6-A3);
  until then the fallback (gym / blacktop, an existing track). No code change is needed when the art lands.
- Crew data is as in Phase 5: name, style, colors, ui_color, good, boss, avg, and `look` text per player for the art
  agent (body and skin words from `tools/art/crews.json`). New palette names for P6-A1: `ORANGE`, `TEAL`, `LIME`,
  `SKY`, `SAND` (the others exist).
- Id prefixes: `mem_`, `nol_`, `den_`, `sea_`, `la_` (`<p>_g1`, `_g2`, `_boss`, `_a1`, `_a2`). Every player's
  `sheet` and `portrait` is his own id; until P6-A1 / P6-A4 draw them they fall back (sheet -> `red_n`, portrait ->
  a silhouette in the crew's ui_color).
- New York keeps `ny_q*`, `ny_s*`, `ny_f*` and `ny_boss`, now with their own sheet / portrait ids. The semifinal
  crew "Subway Sparks" is renamed **BODEGA BANDITS** (grey and plum).
- STAGE_AVG and TIER stay (owner Q3). QA may nudge STAGE_AVG within "about 40 rising to about 70" (P6-30).
- `trip.gd` (P6-10):
  - `match_for()` adds `"twist"` (the city's; `"none"` in Hometown).
  - Test flag `--expected-roster` (with `--city <id> --cgame N`): the match uses the crew a trip would have there
    (`Trip.expected_roster()`): every earlier game won at once, the points spent as after_game.gd's `auto_step()`
    does (one at a time on the lowest stat of the first roster player who can take one), the first recruit
    candidate signed, and the lineup's default starters (the 3 underdogs; the trip test's one-off pick check is not
    replayed). Prints an `EXPECTED ROSTER` line. QA measures the ramp with it.
  - After a city's boss game (game 3, or the New York final) is won, `Difficulty.unlock_court(city)` is called if
    difficulty.gd has it (P6-17), never in the in-memory test trips.
  - `--triptest-data` checks every city's ids, story scenes, crew shape, recruitable flags, the expected roster at
    each city, and the full route to New York.

### Court looks (`scripts/court_looks.gd`, P6-12; art from `tools/art/make_courts.py`, P6-A2)
- New look entries use the same keys as `gym` and `blacktop`, plus these optional keys (`court.gd` ignores a missing
  key):
  - `"ambience"`: an sfx loop name such as `rain` or `wind`;
  - `"backboard"`: `"glass"`, `"metal"` or `"wood"`;
  - `"pole"` colors;
  - `"front_fence"`: true for the cage, low posts and mesh along the near sideline, drawn under the players;
  - `"floor_overlay"`: `"puddles"` or `"sand_drift"`.
- `gym` and `blacktop` stay for Quick Game.
- `names()` returns the order the COURT button cycles (Q9).

### Player sheet format v2 (numbers from the owner-approved animation sample v1; the JSON file is the truth)
The sample (`docs/art/anim_sample_v1.md`, `_points.json`) replaced the guessed 56 x 80 numbers:
```
assets/players2/format.json         {"version": 2, "frame": [64, 96], "feet_row": 88, "center_x": 32, "head_px": 50,
                                     "draw_scale": 2.0, "dirs": ["S", "SE", "E", "NE", "N"],
                                     "cols": <logical columns per direction>, "page_cols": 32,
                                     "anims": {"idle": {"start": 0, "frames": 6, "fps": 6, "loop": true}, ...}}
assets/players2/<sheet>.png         one page (when cols <= 64); <sheet>_p0.png is accepted too
assets/players2/<sheet>_p0.png ...  pages when cols > 64: page p holds logical columns p*64 .. p*64+63
assets/players2/hands.json          {"frame": [64, 96], "feet_row": 88,
                                     "bodies": {"<body>": {"<anim>": {"<DIR>": [{"hands": {"L": [x, y], "R": [x, y]},
                                        "ball": [x, y, front] or null, "ball_floor": [x, y], "ball_h": h}, ...]}}},
                                     "sheets": {"<sheet>": "<body>"}}       # recolors share their body's points
assets/players2/cards/<sheet>.png   one 64 x 96 frame: the idle frame facing the camera (lineup, recruit, bracket)
```
- Numbers: frame 64 x 96 art px, art scale 1.25, drawn 2x in the game (an average body is 50 art px = 100 px on the
  720 px screen; today 40 art px). The floor point under the pelvis is row 88, x 32. Ids are today's (`ud_deuce`,
  `ht_g1`, `ht_g1_crew`, ...).
- Layout: each direction is one row of `cols` logical columns (animation `start` + frame); rows 0-4 = S, SE, E, NE,
  N (SW, W, NW mirrored: `x' = 63 - x`, L and R swap). The columns are stored in pages of up to `page_cols` = 32
  columns, so a page is at most 2048 x 480 px (the 2048 texture limit; about 180 columns = 6 pages). An animation may cross a page edge; `Sheets.frame_region()` finds the page.
- hands.json is keyed by animation and direction, like the sample's `_points.json` (so it doesn't depend on the column
  layout). `ball` is the ball centre for the game's 11 px ball, `front` 1 = drawn over the sprite; null = the ball is
  free (after a dunk's slam). Directions without points (the sample has SE and E only) return `{}`.
- **Fallback chain** (sheets.gd): each id the caller lists, v2 (`assets/players2/`, needs `format.json`) then v1
  (`assets/players/<sheet>.png`, 37 x 5 frames of 40 x 64, today's `hands.json`); nothing at all = the caller draws
  the Kenney sprite (player.gd) or a silhouette (screens). v1 and v2 players can share a court. A page or sheet of
  the wrong size is refused (a warning), so a half-made sheet falls back instead of drawing garbage.
- Animation names: an animation a sheet doesn't have maps to the nearest one it has (`Sheets.ALIASES`): on a v1
  sheet run_dribble / cross / catch -> dribble, hold / land -> idle, slide -> run, dunk_* / rim_hang -> dunk, pass_* ->
  pass, steal -> poke, fall -> stumble, celebrate_a/b -> celebrate; on a v2 sheet today's names map the other way
  (dunk -> dunk_two, pass -> pass_chest, poke -> steal, celebrate -> celebrate_a). The sample's `rundribble` =
  `run_dribble`.
- `scripts/sheets.gd` (P6-05, static, no game state; `const Sheets = preload("res://scripts/sheets.gd")`):
  - `load_sheet(sheet_id) -> {id, version, fmt, texture (page 0), pages}` (v2 then v1, {} if neither);
    `load_first(ids)`; `with_base(sheet_id)` = `[id]` plus the plain id after a `_crew` one;
  - `frame_index(fmt, dir_row, anim, k) -> int` (`dir_row * cols + start + k`; k wraps if the anim loops, else
    clamps); `progress_index(fmt, dir_row, anim, f)` for f in 0..1; `frame_region(sheet, index) -> {texture, region}`;
  - `resolve(fmt, anim)`, `has_anim()`, `anim_frames(fmt, anim) -> int`, `anim_fps(fmt, anim) -> float` (0 = driven by a
    progress), `anim_loops()`;
  - `hand(fmt, sheet_id, frame, flip = false) -> {L, R: Vector2, ball: Vector2, ball_front: bool, ball_h}` or {};
  - `feet_y(fmt)`, `center_x(fmt)`, `frame_size(fmt)`, `head_px(fmt)`, `draw_scale(fmt)`, `cols()`, `page_cols()`;
  - `card(sheet_id) -> Texture2D`: `cards/<sheet>.png`, else the idle S frame cut from its v2 or v1 sheet;
    `card_info(sheet_id)` / `card_first(ids)` add the floor point and height, and `card_rect(info, v1_pos, v1_scale)`
    places any card where today's 40 x 64 card stood (same floor point and character height).
  - `self_test()` (prints `SHEETS ... OK`): v1 numbers against player.gd and hands.json, then a 2-page v2 sheet built
    in `user://sheets_test/` with the sample's points. Run it with a one-line `SceneTree` script, or from
    `--anim-test` (P6-24).
  - lineup.gd, recruit.gd and bracket.gd go through it (P6-06); player.gd (P6-21) and ball.gd (P6-22) next, so
    nothing else hardcodes 40 x 64 or 37 columns.

- **v2.1: indexed pages + palettes (coordinator decision after P6-A6 measured 29 MB of video memory per RGBA sheet,
  about 175 MB with 6 players on court).**
  - Pages are 8-bit grayscale PNGs (`<sheet>_p<n>.png`, imported as L8, lossless, nearest): the gray value is a
    palette index, 0 = transparent. About 7.3 MB of video memory per sheet instead of 29.
  - `palettes/<id>.png`: a 256 x 1 RGBA palette per sheet AND per recolor (`ud_deuce.png`, `ht_g1_crew.png` ...).
    A `_crew` recolor is only a palette that points at its base sheet's pages (`hands.json` `sheets` maps it to the
    body; `format.json` or a `palettes.json` maps recolor -> base pages). No separate recolor pages: this also keeps
    the download inside Q8.
  - `format.json` gets `"indexed": true`. The game draws an indexed sheet through one shared canvas_item shader
    (`scripts/shaders/palette.gdshader`, made by the programmer: `COLOR = texture(palette, vec2((idx * 255.0 + 0.5) /
    256.0, 0.5)); alpha 0 for index 0`), with the palette as a per-sprite uniform. Mirroring, modulate (fade) and
    the existing outline/flash effects must keep working.
  - Cards stay RGBA (64 x 96, small). v1 sheets and non-indexed v2 sheets keep working (reader checks `indexed`).

### Animation table (names fixed; frame counts are read from `format.json`)
The counts below were the plan's guess. The approved sample has run 12, run_dribble 10, dribble 8, dunk_two 10 (and
proposes idle 6, cross 8, shoot 10, layup 10, the passes 6, catch 4, slide 8, steal 6, block 8, fall 8, land 4,
celebrate 12, stumble 8); the code reads whatever `format.json` says.
Today = what the v1 sheet does. "Phase" = what picks the frame.

| Anim | Frames | Plays when (player.gd reads) | Frame phase |
|---|---|---|---|
| idle | 4 | standing without the ball | clock, 3 fps |
| run | 8 | moving faster than `RUN_MIN_SPEED` without the ball, not guarding | clock, fps scaled by speed (today's rule) |
| dribble | 6 | standing with the ball | **locked to the ball**: 1 dribble per cycle (`ball.dribble_phase()`, P6-22) |
| run_dribble | 8 | moving with the ball | **locked to the ball**: 2 dribbles = 2 steps per cycle; under ~40% speed it blends to `dribble` |
| cross | 6 | crossover burst (`cross_t`) | progress of the burst; the ball's hand switch follows the frame's hands |
| hold, catch | 2, 2 | ball held (free throw line, inbound) / first 0.15 s after a catch | one-shot |
| shoot | 8 | jump shot and free throw: gather 0-2, rise 3-4, release 5, follow-through 6-7 | the human's `shot_charge` or the CPU's windup, then the follow timer |
| layup | 6 | `rim_kind == "layup"` | jump progress |
| dunk_one, dunk_two, dunk_tomahawk, dunk_windmill (Q6) | 7, 7, 7, 8 | `rim_kind == "dunk"`; the style is a visual pick (Q6) from speed, turbo, finishing rating and a hash of the player and possession (no random calls in the sim) | jump progress through the hang curve |
| rim_hang | 2 | right after a dunk, if Q7 keeps it | visual timer |
| pass_chest, pass_bounce, pass_lob | 4 each | a pass leaves the hands: lob = `ball.lob`; bounce = a visual pick for a defender in the lane or a short pass; else chest | one-shot |
| slide | 6 | guarding (defense), moving sideways or backwards relative to facing | fps by speed |
| steal | 4 | `poke_t` (swipe) | one-shot |
| block | 6 | `block_jump_t`: crouch, rise, swat at the top, fall | jump progress |
| stumble, fall | 4, 8 | `stumble_t`; `fall` if Q7 (a crossover beat a close defender, an "ankle-breaker") | stumble time |
| celebrate_a, celebrate_b | 6, 6 | after a make or a win (b for dunks and game winners) | clock |
| land | 2 | the first ~0.12 s after any jump lands | visual timer |

That's about 140 of 160 slots, with room for Q6 (c). The hands for each frame come from `hands.json`. **The ball is
drawn in the hand of every held-ball frame**, including run_dribble, cross, catch, the passes and the dunk styles.

### Motion effects (visual only; P6-23)
- **Squash and stretch**: sprite scale on take-off (stretch), landing (squash) and the `land` frames. At most about
  12%, with the feet kept on the floor point.
- **Dunk hang**: a remap of the *drawn* lift curve so the drawn dunk spends longer near the top. The sim's
  `jump_t`, `jump_z`, `DUNK_RELEASE` and block windows are unchanged (Q7).
- **Dust**: `fx.dust()` puffs at the feet on hard cuts (sharp turn at speed, the crossover burst start) and on
  landings. On the sand court they are sand-colored, on the wet court splashes (P6-14 lends twist_fx's colors).
- **Camera punch**: `fx.punch(strength)`. Main.gd multiplies the camera zoom by `fx.zoom_punch()` (+3-5% for about
  0.25 s, eased). It fires on big dunks only (Q7: turbo dunks, alley-oops, windmill/tomahawk) and stacks with today's
  dunk shake.

### Art lists (art-audio)
- **v1 sheets now** (P6-A1, today's generator and format, so every city plays before the redraw):
  - Memphis, New Orleans, Denver, Seattle and Los Angeles crews, 5 each: 25.
  - 8 New York players (`ny_q1-3`, `ny_s1-3`, `ny_f1-2`).
  - `_crew` recolors of the 15 new recruitable players.
- **v2 sheets after G2** (P6-A6, P6-A7): all of the above plus the 3 underdogs, Hometown, Chicago, `ny_boss` and the
  6 Hometown/Chicago recolors. About 48 base sheets and 21 recolors. Q8 decides if recolors are separate files.
- **Portraits** (P6-A4, comic v2): base plus `_happy` for the 33 new characters, bosses also `_smug`.
- **Courts** (P6-A2): 8 looks, floor tile and backdrop each.
- **Music** (P6-A3): 5 new tracks. Hometown, Chicago and New York keep theirs.
- **Twist sounds** (P6-A5): rain loop, wind loop, loud crowd loop, fence rattle, splash, sand step.

## Risks and how this plan handles them
- **Animation breaks gameplay feel.**
  - The rules make animation visual only, so no timing or reach changes.
  - P6-40 compares 100 Quick Game games with the P6-00 baseline (each stat within 2 SE).
  - The owner judges the feel on the tablet.
- **Dribble out of time with the steps.** run_dribble is phase-locked to the sim's fixed dribble: about 0.35 s per
  bounce, about 0.7 s per 2-step cycle. At full speed that is a stride of about 6 ft, which looks right. The sim's
  dribble period isn't touched because steal timing depends on it.
- **Download size and memory.**
  - 160 frames x 5 directions at 56 x 80 is about 7.5x today's pixels per sheet: about 300 KB per sheet and about
    14 MB of video memory each.
  - About 69 sheets come to about 15-20 MB of download.
  - Six players on court plus the ball is about 90 MB of textures. Screens use the small card images, never whole
    sheets.
  - Q8 sets the budget. P6-A6 measures the real size on the first 3 v2 sheets before the rest are drawn. P6-31
    measures fps in Chromium against P6-00.
- **Texture size limits.** At most 2048 x 2048 per texture (the GLES3 / WebGL2 minimum). v2 sheets are split into
  pages of 32 columns (32 x 64 = 2048 px wide, 5 x 96 = 480 px high); `format.json` `page_cols` is 32.
- **Twists unfair or invisible.** Every hook ignores `team`. P6-30 compares each city with and without its twist
  (100 games each) for the score split and pace, and checks the twist is felt:
  - wind: long-shot FG% drops by about the set amount;
  - sand: game length and turbo use go up;
  - wet: slide count;
  - crowd: shot clock pace.

  A banner at tip-off, a twist line on the map and the pause screen, and ambient effects make every twist readable.
- **Ramp across cities.**
  - P6-30 uses `--expected-roster` (the crew a trip would really have) and 100 games per city game.
  - Working target, to be confirmed by the owner's play: a CPU-controlled crew on Normal wins about 70% in Hometown,
    falling city by city to about 50% in the New York final. No city game is above 80% or below 40%, and no city is
    easier than the one before by more than the noise.
  - Levers: STAGE_AVG (within "about 40 rising to about 70") and twist numbers inside the strength the owner picks
    in Q1.
- **Trip length.** 7 cities x (11 + 15 + 21) plus 3 tournament games to 21 is about 3.5 hours of play, over VISION's
  "2-3 hours" (Q10).
- **Sharing files.** player.gd, ball.gd and main.gd get twist hooks (wave 1) and animation work (wave 2/3), so each
  file has one task per wave (parallel plan below).

## Owner answers
- Q1 twists: (a) as proposed. Q2 New York: (a) fenced cage. Q3 crews: (a) all as written (Subway Sparks renamed).
  Q4 story: (a) light comedy with heart. Q5 music: (a) listening list first. Q6 dunks: (a) 4 styles. Q7 motion:
  (a) medium. Q8 size: (a) 15-20 MB is fine. Q10 trip length: (a) keep 11/15/21 (about 3.5 hours).
- **Q9 (owner's own answer):** Quick Game offers every city court WITH its twist, but a city's court unlocks only
  after you beat that city's boss on the Road Trip (gym and blacktop always open, twist none). Coordinator default:
  an unlock is kept for good (a new trip doesn't lock it again), stored with the settings, not in the trip save.
  New task P6-17.
- **G2 passed: the owner approved animation sample v1** (`docs/art/anim_sample_v1*`: 64x96 frames at 2x, art scale
  1.25), with two fixes for the full redraw: make the dribbling arm read against the jersey (side view: navy sleeve
  on a blue jersey), and push the running-dribble ball a bit more to the side so it doesn't cover the legs.

## Todo
(Phase 6 tuning round, from the owner's Phase 6 check-in; see VISION "Phase 6 check-in". Then publish and Phase 7.)

## Doing

## Review

## Done
- **Tuning round (owner's Phase 6 check-in), merged:** P6-T1 camera 1.60 -> 1.72 with a small depth slide at 16:9
  (2583a9e); P6-T2 FULL SCREEN in Settings and pause, first tap restores it on the web (7ba7a00); P6-T3 Quick Game
  team pick on both sides, unlocks with the boss/bracket wins, stats shifted to a 50 average, test unlocks go to
  `user://settings_test.cfg` (bcff4b0). P6-42 republished after them.
All merged on `ccr-f5c087b2-3ojk5f` by `c6a8491` (P6-41 in the docs commit after it). The task text is as planned;
what changed is in the **Done notes** below.

**Done notes:**
- P6-A6b (v2.1 indexed pages + palettes, `bdd2e60`) and the recruit joining lines (`631be3f`, `story_text.gd`
  `RECRUIT_LINES`, `recruit.gd`) were added during the phase.
- P6-30 and P6-31 wrote one report, `docs/qa/phase6.md` (not `phase6-cities.md` / `phase6-anim.md`), with 40 games
  per city game (not 100). Applied tuning: wet court (`twists.gd` `cut_angle_deg` 150, `cut_min_speed` 0.9;
  `player.gd` `SLIDE_MIN_WANT` 0.9). No STAGE_AVG change.
- P6-40 is folded into `docs/qa/phase6.md` plus the coordinator's checks on `c6a8491`: import clean,
  `--trip-test --target 3` plays all 8 cities to `TRIP END`, Seattle game 3 `--autoplay` FINAL 21-17 in 9:44.
  Quick Game against P6-00 was 20 autoplay games (all stats inside the limit; fouls 2.90 vs 3.77, just inside) and
  18 humantests. Not run separately in this phase: the forced loss and stop/resume across all 8 cities, the
  per-city touch walk in Chromium, the save-survives-reload check. `index.pck` is 34.2 MB against the owner's
  "about 31 MB" (owner question in the summary).
- P6-B1 fixed in `c6a8491`: popups are clamped to the visible view in `fx.gd` `_draw`.
- P6-41: `README.txt` and `CLAUDE.md` updated; `CREDITS.md` checked (every Phase 6 track, twist sound, court,
  portrait and `assets/players2/` has a row; the removed v1 sheets are noted), no change needed.

### Wave 0
- **P6-00** | Baseline on the current dev build:
  - 100 Quick Game `--autoplay` and 6 `--humantest` (stats table as in `docs/qa/phase5.md` section 3);
  - `--city hometown|chicago --cgame 1..3`, 100 games each on Normal;
  - `index.pck` size;
  - fps in headless Chromium on a Quick Game (same method as P4-12) and in the Godot `--fps` run.

  | qa | `docs/qa/phase6-baseline.md` | table written, commit recorded | - | none

### Wave 1
- **P6-01** | Twist table and getters as in the contract, with the Q1/Q2 numbers as commented constants; `info()`
  for banners | gameplay A | `scripts/twists.gd` (new) | parses in 4.3; every key in the hook table has its
  default; `value()` returns the default for `"none"` | - | Q1, Q2
- **P6-02** | main.gd hooks:
  - read `Flow.match.twist` and set `Twists.current`; `--twist <id>` test flag;
  - `long_shot_mult` in `shot_probability()`; `shot_clock` from `Twists.value`;
  - twist banner at tip-off: the line under the match label, plus twist_fx's banner if the file exists;
  - add a `twist_fx.gd` node to the game if the file exists;
  - camera zoom x `fx.zoom_punch()` if fx has it;
  - `--anim-test` loads `scripts/anim_test.gd` if present (like `--trip-test`).

  | gameplay A | `scripts/main.gd` | twist `none`: 3 autoplay + humantest as P6-00; `--city chicago --cgame 1
  --twist wind` and `--twist crowd` play and print the twist in the `MATCH` line | P6-01 | Q1, Q9
- **P6-03** | player.gd twist hooks: `speed_mult`, `turbo_mult`, stamina drain/refill, wet-court grip on sharp turns
  at speed (crossover bursts keep full grip), and a read-only `sliding` flag for the effects. Must merge before P6-21
  starts | gameplay A | `scripts/player.gd` | twist none identical; `--twist sand` games are measurably longer;
  `--twist wet` prints a slide count stat | P6-01 | Q1
- **P6-04** | ball.gd and rules.gd twist hooks:
  - wind: the lob target drifts downwind (sim) and the drawn shot path curves (visual);
  - thin air: lob time and drawn arc;
  - cage: a loose ball crossing a sideline bounces off the fence (rattle sfx if present); baselines unchanged;
  - `stat()` counters for each.

  Must merge before P6-22 starts | gameplay A | `scripts/ball.gd`, `scripts/rules.gd` | twist none identical; each
  twist seen in `--ballshots` and in its stat | P6-01 | Q1, Q2
- **P6-10** | City and crew data:
  - the 5 new cities complete, plus the real New York crews;
  - Hometown, Chicago and New York names per Q3 (the `# placeholder` marks removed);
  - looks, music and twist ids for all 8; `built: true` everywhere;
  - per-player `look` text for the art agent;
  - trip.gd: `match_for()` adds `twist`; `--expected-roster`; `self_test()` checks every id and that each city's
    lineup prints.

  | gameplay B | `scripts/cities.gd`, `scripts/trip.gd` | `--triptest-data` (+ `--load`) passes for all 8 cities;
  `--trip-test --target 3` plays all 8 cities to `TRIP END` (sheets fall back to `red_n` until P6-A1) | - | Q2, Q3, Q10
- **P6-05** | Sheet format reader as in the contract: v1 built in, v2 from `format.json` and `hands.json`
  (body-keyed), the fallback chain, `card()`, and `"pages"` support if P6-A0 needs it. Static, no game state |
  gameplay B | `scripts/sheets.gd` (new) | parses in 4.3; with only v1 files every function gives today's numbers;
  with the P6-A0 sample files it returns the v2 frame for each anim | P6-A0 (format proposal) | none
- **P6-06** | Cards use `Sheets.card()` instead of cutting frame 0 out of a 40 x 64 sheet | gameplay B |
  `scripts/lineup.gd`, `scripts/recruit.gd`, `scripts/bracket.gd` | screens look as today with v1 sheets, and show the
  sample player's v2 card when it exists (`--trip-test --screens`) | P6-05 | none
- **P6-11** | Story scenes:
  - arrival and after-win for Memphis, New Orleans, Denver, Seattle and Los Angeles;
  - Hometown, Chicago, New York and the ending rewritten from placeholder to final names (Q3) and tone (Q4);
  - `final_before`, `first_loss` and `ending` reviewed;
  - each scene mentions or hints at the city's twist (it is part of the "shown" rule).

  | gameplay B | `scripts/story_text.gd` | every scene id that cities.gd names exists; `--trip-test --target 3
  --screens` shows them; lead reviews tone | P6-10 | Q3, Q4
- **P6-A1** | crews.json parts and v1 sheets for the 33 new players and 15 recolors, with new palettes; preview
  `docs/art/players_preview_p6.png`; CREDITS rows | art-audio | `tools/art/crews.json`, `tools/art/make_players.py`,
  `assets/players/*`, `docs/art/*`, `CREDITS.md` | `--city <each> --cgame 3 --shots` shows the crews; size reported |
  P6-10 (look text) | Q3
- **P6-A2** | 8 court looks in `make_courts.py`, floor tile and backdrop each:
  - barn driveway with a cornfield;
  - lakefront rooftop with a skyline (wind flags);
  - old-school gym with a packed crowd;
  - bayou blacktop with cypress and lights;
  - mountain park with peaks;
  - rainy park (wet sheen, puddles);
  - beach (sand floor, boardwalk);
  - fenced cage with city blocks.

  No real buildings, logos or brands. Preview `docs/art/courts_preview_v2.png` for the coordinator to show the owner
  | art-audio | `tools/art/make_courts.py`, `assets/courts/*`, `docs/art/*`, `CREDITS.md` | preview reads at 1280x720;
  files load through a test look | - | none
- **P6-A3** | Music: 5 tracks (Memphis, New Orleans, Denver, Seattle, Los Angeles), upbeat chiptune with a city
  flavor, CC0 or CC-BY from OpenGameArt. Loops cut with `tools/make_music.sh`, -20 LUFS like the others. Listening
  list for the owner if Q5 (a) | art-audio | `tools/make_music.sh`, `assets/music/*`, `CREDITS.md` | 5 files play
  through `audio.play_music(<id>)`; licenses checked | - | Q5
- **P6-A0** (Done: approved, see Owner answers).

### Wave 2
- **P6-12** | Court looks data: the 8 new looks with their textures, colors, music, ambience and the optional keys
  from the contract; `names()` order per Q9 | art-audio | `scripts/court_looks.gd` | `--court <each>` and `--city
  <each> --shots` look right; Quick Game COURT button per Q9 | P6-A2 | Q9
- **P6-13** | court.gd supports the new optional look keys (wood backboard and barn pole, `front_fence` posts and
  mesh under the players, `floor_overlay` puddles and sand drift), all through View | gameplay A | `scripts/court.gd`
  | gym and blacktop unchanged in a screenshot; cage, rain_park and beach show their props | P6-12 (or a test look)
  | none
- **P6-14** | Twist effects (new script):
  - the banner at tip-off and after the side switch, with the name, one line and an icon;
  - wind streaks plus a windsock or arrow showing the wind;
  - rain and splashes; heat shimmer and sweat when tired; thin-air breath puffs and a higher drawn arc trail;
  - sand puffs at the feet; crowd camera flashes;
  - the ambience loop through audio (P6-15) if present.

  Visual only, through View | gameplay A | `scripts/twist_fx.gd` (new) | every twist readable in a `--city <id>
  --shots` screenshot; twist none draws nothing; fps cost measured (`--fps`) | P6-01, P6-02 | Q1, Q2
- **P6-15** | Ambience: `play_ambience(name, db)` and `stop_ambience()`, ducked like the music; the crowd loop's
  volume from `Twists.value("crowd_db")` | gameplay A | `scripts/audio.gd` | missing file = silence; pause stops it
  | P6-01 | none
- **P6-16** | Twist line on the trip map's city box ("WIND: long shots and lobs drift") and on the pause screen |
  gameplay A | `scripts/trip_map.gd`, `scripts/pause.gd` | shows for each city in `--trip-test --screens`; nothing
  for Hometown | P6-01, P6-10 | none
- **P6-21** | Animation selection for v2 sheets:
  - the full animation table (run_dribble, cross, the 4 dunk styles, pass types, slide, steal, block swat, fall,
    celebrations, land, catch);
  - fps per animation from `format.json`, run and slide fps by speed;
  - dribble and run_dribble locked to `ball.dribble_phase()`;
  - v1 sheets keep today's mapping exactly;
  - `HEAD_PX` and `DUNK_VIEW_LIFT` from the format (`head_px`), so the hands still reach the rim.

  Built against the P6-A0 sheet | gameplay B | `scripts/player.gd` | v1-only game: frames identical to today
  (P6-24 contact sheet diff); with the sample sheet each animation in the table shows when its condition holds; 3
  autoplay + humantest as P6-00 | P6-03, P6-05, P6-A0 | Q6, Q7
- **P6-22** | Ball for v2:
  - hand points from `Sheets.hand()` (frame size and feet row from the format);
  - `dribble_phase() -> float` (0 = in the hand at the top, 0.5 = on the floor; read-only, from the sim's dribble);
  - the ball in the right hand for cross, catch and each pass type;
  - the bounce pass drawn bouncing once on the floor (visual);
  - `REACH_VIEW_Z` and `CATCH_VIEW_Z` scaled by `head_px`.

  | gameplay B | `scripts/ball.gd` | the ball sits in the hand in every held-ball frame of the sample (`--ballshots`,
  `--anim-test`); v1 unchanged | P6-04, P6-05 | none
- **P6-24** | `--anim-test` driver:
  - poses one or all sheets through every animation in 8 directions on a plain court, with the ball drawn in hand;
  - writes contact sheets `/tmp/hoops_anim_<sheet>_<anim>.png` and a frame strip for a moving preview (xvfb);
  - headless: checks every sheet's format, hands and frame counts and prints `ANIM OK` or the problems.

  | gameplay A | `scripts/anim_test.gd` (new) | runs on v1 sheets and the sample; QA and art can use it to check hands
  | P6-02, P6-05 | none
- **P6-A4** | Portraits for the 33 new characters (comic v2, moods), from crews.json | art-audio |
  `tools/art/make_portraits_v2.py`, `tools/art/crews.json`, `assets/portraits/*`, `docs/art/*`, `CREDITS.md` | story
  scenes show them (`--trip-test --screens`) | P6-A1 | Q3
- **P6-A5** | Twist sounds: rain loop, wind loop, loud crowd loop, fence rattle, splash, sand step (synthesized like
  the swish, or CC0) | art-audio | `tools/` sound scripts, `tools/make_sfx.sh`, `assets/sfx/*`, `CREDITS.md` | files
  credited; `audio.play(name)` plays them | - | none
- **P6-A6** (after G2) | v2 generator, first slice:
  - `tools/art/make_players_v2.py` (new; the v1 generator stays) writes `format.json`, body-keyed `hands.json`, cards
    and the 3 underdogs' v2 sheets with the whole animation table;
  - measures size on disk, in `index.pck` and in video memory; reports whether the Q8 budget holds before the rest is
    drawn;
  - preview `docs/art/players_preview_v3.png`.

  | art-audio | `tools/art/make_players_v2.py` (new), `tools/art/pixel3d.py`, `assets/players2/*`, `docs/art/*`,
  `CREDITS.md` | `--anim-test` shows `ANIM OK` for the 3; hands checked | G2, P6-A1 | Q6, Q8

- **P6-17** | Quick Game court unlocks (Q9): a court unlocks when its city's boss game is won on any trip (kept for
  good, saved with the settings, not in the trip save); the COURT button cycles the gym, the blacktop and the
  unlocked city courts, and a city court brings its twist; a locked city shows nothing. `--unlock-all` test flag |
  gameplay A | `scripts/menu.gd`, `scripts/difficulty.gd` (settings file), one call from `trip.gd` (coordinate with
  P6-10: `Trip` calls `Difficulty.unlock_court(city)` after a boss win) | a fresh install shows gym + blacktop only;
  after `--trip-test` the beaten cities' courts appear; Quick Game on Chicago's court plays with wind | P6-02, P6-10 |
  Q9

### Wave 3
- **P6-23** | Motion effects as in the contract:
  - squash and stretch, the land frames, the dunk hang curve (drawn lift only), dust and splash on hard cuts and
    landings;
  - `fx.punch()` / `fx.zoom_punch()` on big dunks;
  - `POPUP_HEAD_LIFT` for taller players.

  | gameplay B | `scripts/player.gd`, `scripts/fx.gd` | visible in `--anim-test` strips and `--shots`; sim stats as P6-00
  (no timing change); fps cost measured | P6-21 | Q7
- **P6-26** | main.gd size pass for taller players: `CAM_TOP_FT` (far heads visible), CALL bubble and steal cue
  heights from `Sheets.head_px` | gameplay A | `scripts/main.gd` | heads and bubbles not cut at 1280x720 and 1280x800
  with v2 sheets | P6-21, P6-A6 | none
- **P6-A7** | v2 sheets for every other player and recolor (or runtime recolor, Q8); preview; CREDITS | art-audio |
  `tools/art/make_players_v2.py`, `tools/art/crews.json`, `assets/players2/*`, `docs/art/*`, `CREDITS.md` |
  `--anim-test` `ANIM OK` for all sheets | P6-A6 | Q8
- **P6-30** | QA cities and ramp:
  - for each city game: 100 `--autoplay --city <id> --cgame N --expected-roster` on Normal, and 100 with
    `--twist none` for the twist's size and fairness;
  - humantest 6 per twist city; Easy/Hard spot checks on the boss games;
  - tune the twist constants within the Q1 strength, and STAGE_AVG within the owner's range, toward the ramp target;
  - a twist screenshot per city.

  | qa | `docs/qa/phase6-cities.md`, constants in `scripts/twists.gd` and `scripts/cities.gd` (tuning only) | report
  written; ramp table; tuning listed | P6-02..P6-04, P6-10, P6-14 | none
- **P6-31** | QA animation:
  - `--anim-test` on all sheets: hands, frame counts;
  - Quick Game 100 autoplay vs P6-00 (animation must not move a stat);
  - screenshots at 720 and 800;
  - Chromium touch fps vs P6-00; `index.pck`; video memory estimate;
  - a moving-preview strip of each new animation for the owner.

  | qa | `docs/qa/phase6-anim.md` | report written; bugs filed here | P6-21..P6-24, P6-A6 | none

### Wave 4
- **P6-25** | Remove the v1 player sheets and `assets/players/hands.json` once every v2 sheet exists. Keep the Kenney
  fallback and sheets.gd's v1 path (it then falls to Kenney). Update CREDITS | art-audio | `assets/players/*`,
  `CREDITS.md` | full trip and Quick Game run with only v2; pck shrinks | P6-A7, P6-31, G2 | none
- **P6-40** | Final QA:
  - `--trip-test` full length plus a forced loss plus stop/resume across all 8 cities;
  - 100 Quick Game games vs P6-00;
  - the whole flow by touch in Chromium (each city's banner, ambience, pause twist line);
  - save survives a reload;
  - `index.pck` within Q8.

  | qa | `docs/qa/phase6.md` | report written; bugs filed | all | none
- **P6-41** | Docs:
  - README.txt (cities, twists, new animations);
  - CLAUDE.md Layout (`twists.gd`, `twist_fx.gd`, `sheets.gd`, `anim_test.gd`, `assets/players2/`,
    `make_players_v2.py`) and Testing (`--twist`, `--expected-roster`, `--anim-test`), coordinator approves;
  - CREDITS check.

  | gameplay A | `README.txt`, `CLAUDE.md`, `CREDITS.md` (check only) | the owner can follow it | P6-40 | none

### Bugs from QA (P6-30 / P6-31, `docs/qa/phase6.md` section 7)
- **P6-B1** | BALL! popup clipped at the screen edge: the caller stands at the edge of the view, and the popup at
  his head (`human_input.gd` `fx.popup_head`) is cut off ("BA"). Keep it inside the screen like the other popups |
  gameplay A | `scripts/human_input.gd` or `scripts/fx.gd` | the popup fully on screen in `--shots --humantest --city
  memphis --cgame 3` | - | none


## Open questions for the owner
**All answered** (see "Owner answers" above and `docs/VISION.md`); kept for the record. The Phase 6 check-in
questions are in `docs/phase6-summary.md`.

Answer with the letter; (a) is the recommendation each time. Answers go into `docs/VISION.md` and "Owner answers"
above.

- **Q1 How strong are the city twists?** They are the same for both teams. Our proposal:

  | City | Twist | What changes | How you see it |
  |---|---|---|---|
  | Hometown | none (tutorial) | nothing | no banner |
  | Chicago | wind | A steady crosswind, gusting between half and full strength. At full gust, shots beyond the arc go in 8% less often and curve about 1.5 ft in the air. Lobs land up to 2 ft downwind (usually still caught) | banner "WIND OFF THE LAKE", wind streaks, flags, a wind arrow |
  | Memphis | full crowd | 18-second shot clock (24 today), everyone 4% faster, crowd much louder | banner "FULL HOUSE", camera flashes |
  | New Orleans | humid | stamina refills 30% slower | heat shimmer, sweat when tired |
  | Denver | thin air | shots beyond the arc go in 8% more often, shots and lobs float about 15% higher and longer, stamina drains 20% faster | breath puffs, high arcs |
  | Seattle | wet court | a sharp turn at full speed slides about 1.5 ft before you change direction (crossovers keep their grip) | rain, splashes |
  | Los Angeles | sand | everyone 10% slower; turbo boost 35% -> 45%, so turbo matters more | sand puffs at the feet |

  (a) As proposed. (b) About twice as strong. (c) About half as strong. (d) As proposed, but I'll change some (tell
  us which).
- **Q2 New York's twist ("tight sidelines").** (a) A fenced cage: a loose ball bounces off the fence back into play
  (no out of bounds on the sidelines; baselines as now) with a fence rattle. (b) A narrower court, about 6 ft less
  room to drive around (riskier: every CPU spot and the camera depend on the court size). (c) No twist: the finale is
  just the best crews and a loud crowd.
- **Q3 Crew names and themes.** Our proposal (original characters; no real teams; each crew has 2 average players,
  2 good ones and a boss):
  - Memphis **RIVERSIDE SOUL** (orange and black, inside game), boss Darnell "Smoke" Whitfield, a barbecue
    pitmaster.
  - New Orleans **BAYOU BRASS** (teal and white, fast break), boss Andre "Gator" Fontenot, a trombone player.
  - Denver **SWITCHBACKS** (forest green and silver, long range), boss Hank "Ridge" Larsen, ski patrol.
  - Seattle **PUDDLE JUMPERS** (navy and lime, balanced), boss Kenji "Downpour" Sato, a fishing-boat deckhand.
  - Los Angeles **BOARDWALK BOMBERS** (sky blue and sand, slashers), boss Malik "Sunset" Rivers, a lifeguard.

  Today's placeholders (Hometown County Line and the Mayor; Chicago Lakeshore Gusts and Big Lou; New York Bridge
  Runners, Subway Sparks, Concrete Crowns, King, "Big City Showdown") become final, except **Subway Sparks**, which
  we rename because "Sparks" is a real pro team.

  (a) All of this as written. (b) As written, but I'll change some names (tell us which). (c) Propose a different
  set.
- **Q4 Story tone for the new cities.** (a) Keep Phase 5's tone: light comedy with heart. Each city crew is a rival
  who respects you after you win, and the recruit joins with a funny line. Running jokes pay off in New York (Deuce's
  knee, the van breaking down once on the way, Jojo's napkin math). Arrival scenes are 4-6 lines, after-win scenes
  3-5. (b) More drama: stakes and setbacks, a rival crew that follows you across the country. (c) Shorter and mostly
  jokes.
- **Q5 Music for the 5 new cities.** (a) We look for CC0 or CC-BY upbeat chiptune with a hint of each city's style
  (soul, brass, bluegrass, rock, surf). You get a short listening list before it's final. (b) The same search, but we
  pick and you swap later if you don't like one. (c) Reuse the 6 tracks we already have for the new cities.
- **Q6 Dunk styles.** (a) 4 styles: one-hand, two-hand, tomahawk and windmill. The windmill only comes on turbo or
  from great finishers (and bosses). Alley-oops are a two-hand catch and slam. Styles are picked by speed, turbo and
  the finishing rating; it's only the look, the chance to score doesn't change. (b) 3 styles: one-hand, two-hand,
  tomahawk. (c) 6 styles: (a) plus a reverse dunk and a 360 (more art, so the full redraw takes longer).
- **Q7 How big should the motion feel?** (a) A hang at the top of every dunk and a short rim hang after it; the
  camera punch only on big dunks (turbo, alley-oop, windmill or tomahawk); a defender beaten by a crossover up close
  falls down and gets back up (an "ankle-breaker", about 1-3 a game). All of it is only the look: block and steal
  timing don't change. (b) Bigger: a camera punch on every dunk, a longer hang. (c) Subtle: a small hang, no rim
  hang, beaten defenders only stumble as today.
- **Q8 Download size.** The new animations make each player sheet much bigger. The web download grows from about
  5.5 MB to about 15-20 MB. (a) That's fine. (b) Keep it under about 12 MB: the game recolors recruits itself
  (fewer files) and average players get fewer frames for rare moves. (c) Keep it under 12 MB even if every player
  gets fewer frames.
- **Q9 Courts in Quick Game.** (a) The COURT button cycles through all 8 city courts plus the gym and the blacktop.
  Twists are off in Quick Game. (b) The same, but each city court brings its twist. (c) Gym and blacktop only, as
  today.
- **Q10 Trip length.** With all 8 cities, every city to 11, 15 and 21 and the tournament to 21, the full trip is about
  3.5 hours of play, more than the 2-3 hours in the vision. (a) Keep it; a long trip is fine. (b) Game 1 and 2 to 11,
  the boss game to 21 (about 3 hours). (c) Hometown, the tutorial city, plays 7, 11 and 15; the rest stay as they are.
