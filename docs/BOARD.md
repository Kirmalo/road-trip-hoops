# Task Board

Current phase: **Phase 5: campaign framework (plus a pause screen)** (planned 2026-11-16 by `lead-producer`). The
Phase 4 board is archived in `docs/board-phase4.md` (Phase 3: `docs/board-phase3.md`, Phase 2:
`docs/board-phase2.md`, Phase 1: `docs/board-phase1.md`).

**STATUS: WAITING FOR THE OWNER.** The owner answers the questions below before anything is built. No task starts
until the coordinator relays the answers; then the answers go into `docs/VISION.md` and the "Owner answers" section
here, and the plan is adjusted where an answer is not the recommended option.

Scope (from `docs/VISION.md`, rows "Campaign: city rule" to "Finale", Game length, Difficulty, Phase 5 roadmap):
- Title screen: Road Trip (start / continue), Quick Game (today's single game with level and court), Settings
  (music, sound volume, default level), Crew & Credits (your crew and stats; art and music credits).
- Pause screen: a pause button in a top corner; Resume / Restart / Quit (to the title or the trip map), music on/off,
  sound volume, current score and a few stats for both teams.
- Trip map: pixel USA map, 8 city pins, the van drives along the road, trophies on beaten cities.
- City data: court look, music, game length by trip stage (11 / 15 / 21), the city crew (2 good + 1 boss + average
  fillers), ratings per trip stage, play style. The 3-game city rule (game 1: 1 good + 2 average; game 2: 2 good +
  1 average; game 3: 2 good + boss), retry on a loss with no penalty.
- After a city: stat points (from wins) spent on Speed, Shooting, Finishing, Defense, Stamina for any player;
  recruit one of the crew's good players or the boss onto the bench.
- Roster: the 3 underdogs + recruits; a lineup screen picks 3 starters before each game.
- Auto-save after every game (one trip, `user://`, survives web reloads; "New trip" asks to confirm).
- Story scenes: big pixel portraits + text box, tap to advance, data-driven; before/after each city and key moments.
- New York finale: a knockout bracket (quarterfinal, semifinal, final), the final against the champions with a
  special boss, then an ending scene.
- **Proven end to end with Hometown and Chicago** and a **stub tournament**. The other 5 cities are pins on the map
  marked "coming soon" (skipped by the route in this build). Placeholder story text. Phase 6 builds the real content
  (courts, twists, story, the other crews).

Not in scope: new courts (Hometown and Chicago use the existing looks as placeholders: Hometown = blacktop,
Chicago = gym; the music already exists: `hometown.ogg`, `chicago.ogg`, `newyork.ogg`), city twists, boss special
moves (Phase 6 if the owner wants them, Q3), left-handed layout and How to Play (Phase 7), new gameplay or tuning of
Quick Game.

Format: `ID | task | owner role | files | done when | depends on | blocked by owner questions`

## Rules for every task in this phase
- Godot 4.3 compatible; no `:=` with an untyped right side (`game.x`, `Flow.match.get(...)`, `JSON.parse_string()`,
  `min`/`max`/`clamp`); use an explicit type or `minf`/`maxf`/`clampf`. Tuning constants at the top of the script they
  belong to, with a comment.
- **Touch first.** Every screen is used by tapping big buttons (at least 200 x 110 px at the 1280x720 base, like
  menu.gd). During play the only new control is the pause button. Keyboard is for desktop tests only.
- **No new `.tscn` scenes.** `main.tscn` stays the only scene; screens are built in code (see Scene flow).
- A task touches only the files listed. If it needs another file, stop and tell the coordinator.
- **Quick Game and the tests stay exactly as today.** With no trip match (`Flow.match` empty) the game builds today's
  BLUE vs RED with today's sheets and ratings; every new rating is 50 there, and rating 50 gives multiplier 1.0
  exactly. `--autoplay`, `--humantest`, `--shots`, `--menushot` skip the title and play as now. P5-16 checks it
  against the P5-00 baseline.
- Data the owner may edit on the tablet (cities, crews, story text) lives in plain GDScript `const` dictionaries with
  comments, never in code paths.
- Each design choice the owner hasn't made is a **constant** with the recommended option as its default.
- Assets: CC0 or CC-BY only; generated art is "Original, made for this project" in `CREDITS.md` with its generator
  script. Web budget: `index.pck` under 12 MB (4.07 MB now). Player sheets are written as indexed-palette PNGs if
  that is smaller (P5-A1 measures).
- Tests: every gameplay task runs 3 `--autoplay` + 1 `--humantest` (all reach `FINAL`, no script errors); every
  screen task also runs `--trip-test` once it exists (P5-15) and the screenshot mode for its screen.

## Shared contract (names fixed now so parallel tasks can call each other)

### Scene flow
`main.tscn` is still one Node2D with `main.gd`. Moving between screens = `Flow.go(screen)`, which sets
`Flow.screen` and calls `get_tree().reload_current_scene()` (deferred), the same trick menu.gd uses today. In
`_ready()`, main.gd checks `Flow.screen` first: `"game"` builds the game as today (with `Flow.match`, see below);
anything else hands over to `Flow.build_screen(self)`, which adds that screen's node (a CanvasLayer built in code)
plus its own `audio.gd` instance for the menu music, and returns without building the court.

```
title --Road Trip--> (new trip: story "trip_start") --> map
map --GO--> story "<city>_arrive" (first visit) --> lineup --> game --> result
result: lost -> lineup (retry the same game)  |  won, games left -> lineup (next game)
        won game 3 -> story "<city>_won" -> points -> recruit -> map (van drives to the next city)
map at New York -> story "final_before" -> bracket -> lineup -> game -> result -> bracket ... final won -> story "ending" -> title
title --Quick Game--> game (today's start panel: level, court, music) ; game-over panel gets a TITLE button
any game --pause--> Quit -> title (Quick Game) or map (trip)
```

`scripts/flow.gd` (P5-01; `extends RefCounted`, static only, used through
`const Flow = preload("res://scripts/flow.gd")`):
- `static var screen := "title"`; names: `"title"`, `"settings"`, `"crew"`, `"map"`, `"story"`, `"lineup"`,
  `"game"`, `"result"`, `"points"`, `"recruit"`, `"bracket"`.
- `const SCREENS := {name: "res://scripts/<file>.gd"}`: title.gd (title, settings, crew), trip_map.gd, story.gd,
  lineup.gd, after_game.gd (result, points), recruit.gd, bracket.gd. A missing script shows a plain "screen not
  built yet: BACK" panel, so the flow runs before every screen exists.
- `static func go(to: String, args := {}) -> void`; `static var args := {}` (e.g. story: `{"scene": "hometown_arrive",
  "then": "lineup"}`).
- `static var match := {}`: the next game (format below); `{}` = Quick Game / tests.
- `static var last_result := {}`: `{"won": bool, "score": [a, b], "stats": {...}}`, set by main.gd at game over in
  a trip game.
- `static func game_finished(winner: int, score: Array, stats: Dictionary) -> void`: main.gd calls it
  `RESULT_DELAY` s (2.5) after a trip game ends; it fills `last_result`, asks Trip to record it and save, then
  `go("result")`.
- `static var test := ""`: `"trip"` under `--trip-test`; flow then loads `trip_test.gd` (P5-15) if present.
- Every screen script implements `func auto_step() -> bool`: take the default choice (first city, first option,
  keep the lineup, spend points on the lowest stat of the first player, recruit the first candidate, advance the
  story one line); returns false when there is nothing to do. The trip test calls it; nothing else does.

### Match config (`Flow.match`, built by `trip.gd`, read by main.gd and player.gd)
```
{
  "mode": "trip",                       # absent or {} = Quick Game
  "label": "HOMETOWN - GAME 2 OF 3",    # shown at tip-off instead of "FIRST TO 21"
  "target": 11,                         # rules.target (side switch at (target + 1) / 2, as --target does)
  "look": "blacktop", "music": "hometown",
  "level": "normal",                    # Difficulty for team 1 in this game (Q4); "" = the saved level
  "teams": [
    {"name": "BARN BURNERS", "style": "", "players": [P, P, P]},   # team 0: your 3 starters, starter 0 = human
    {"name": "COUNTY LINE", "style": "inside", "players": [P, P, P]}
  ]
}
P = {"id": "ud_deuce", "name": "DEUCE", "sheet": "ud_deuce",
     "ratings": {"speed": 55, "shooting": 62, "finishing": 50, "defense": 48, "stamina": 50,
                 "steal": 60, "block": 40}}
```
`steal` and `block` are derived by trip.gd: `clampi(defense + steal_bias, 0, 100)` (same for block), where the
biases are per player in `cities.gd` (Quick Game keeps today's `RATINGS_BY_INDEX` values).

### Ratings and how each stat maps onto the gameplay (`scripts/ratings.gd`, P5-01; static only)
All ratings 0-100, 50 = average = today's players. `f = (rating - 50) / 50` (-1..+1). Constants at the top of
ratings.gd (starting values; P5-16 checks the spread, Phase 6 tunes):

| Stat | Where it acts (existing constants) | Formula | Range at 0 / 100 |
|---|---|---|---|
| Speed | player `speed` (170 px/s), so turbo, defense and rim moves scale with it | `speed * (1 + SPEED_SPAN * f)`, SPEED_SPAN 0.08 | 156 / 184 px/s |
| Shooting | jump shots: `main.shot_probability()` result; free throws: `FT_BASE` | `x (1 + SHOOT_SPAN * f)`, SHOOT_SPAN 0.15 | x0.85 / x1.15 |
| Finishing | `DUNK_OPEN_PCT`, `LAYUP_OPEN_PCT`; and `DUNK_SPEED_FRAC` (good finishers dunk at a lower speed) | `pct x (1 + FINISH_SPAN * f)`, FINISH_SPAN 0.12; `frac - DUNK_EASE * f`, DUNK_EASE 0.05 | x0.88 / x1.12; 0.75 / 0.65 |
| Defense | the existing `steal` and `block` ratings (steal chance, block chance, CPU poke/jump spans), via the biases | `steal = defense + steal_bias`, `block = defense + block_bias` | as today's rating code |
| Stamina | `STAMINA_DRAIN`, `STAMINA_REFILL` | `drain x (1 - STAM_SPAN * f)`, `refill x (1 + STAM_SPAN * f)`, STAM_SPAN 0.25 | drain x1.25 / x0.75 |

Functions: `static func mult(stat: String, rating: int) -> float` and the named helpers
`speed_px(base, r)`, `shot_mult(r)`, `finish_mult(r)`, `dunk_speed_frac(base, r)`, `stamina_drain(base, r)`,
`stamina_refill(base, r)`. The human's shot meter and timing windows are untouched (skill over dice): ratings only
move the odds. Ratings act on both teams and **do not depend on the difficulty level**; the level stays what it is
today (CPU sharpness for team 1 only, `difficulty.gd`).

Play style (team 1 only): `ratings.gd` `const STYLES := {"inside": {...}, "outside": {...}, "balanced": {}}`, each a
small table of multipliers on CPU tendency keys (`three_chance`, `pullup_chance`, `lob_chance`, `cut_chance`,
`kick_chance`, `poke_chance`, `help_side`). `Difficulty.value(team, key, hard)` multiplies by
`Ratings.style_mult(team_style, key)` after the level rule, so every existing call site gets it; P5-03 routes the
five offense constants (`CPU_THREE_CHANCE`, `CPU_PULLUP_CHANCE`, `CPU_LOB_CHANCE`, `CPU_CUT_CHANCE`,
`CPU_KICK_CHANCE`) through `Difficulty.value` too (same value with no style, so Quick Game is unchanged).

### City and crew data (`scripts/cities.gd`, P5-04; `const` data only, plus tiny getters)
```
const ROUTE := ["hometown", "chicago", "memphis", "new_orleans", "denver", "seattle", "los_angeles", "new_york"]
const STAGE_AVG := {1: 40, 2: 45, 3: 50, 4: 54, 5: 58, 6: 62, 7: 66, 8: 70}   # average player per stage (Q3)
const TIER := {"avg": {"all": 0}, "good": {"all": 4, "spec": 12}, "boss": {"all": 20, "spec": 25}}   # Q3
const CITIES := {
  "hometown": {"name": "HOMETOWN", "state": "Indiana", "stage": 1, "target": 11, "look": "blacktop",
               "music": "hometown", "twist": "none", "built": true,
               "crew": {"name": "COUNTY LINE", "style": "balanced", "colors": "GREEN",
                        "good": ["ht_g1", "ht_g2"], "boss": "ht_boss", "avg": ["ht_a1", "ht_a2"]},
               "story": {"arrive": "hometown_arrive", "won": "hometown_won"}},
  "memphis": {"name": "MEMPHIS", "stage": 3, "built": false, ...},   # pin only in Phase 5
  "new_york": {... "tournament": true, "rounds": [...]} }
const PLAYERS := {
  "ud_deuce": {"name": "DEUCE", "sheet": "ud_deuce", "portrait": "ud_deuce", "role": "shooter",
               "tier": "start", "ratings": {...}, "steal_bias": 10, "block_bias": -10, "bio": "..."},
  "ht_g1": {"name": "...", "sheet": "ht_g1", "portrait": "ht_g1", "tier": "good", "spec": ["shooting", "speed"],
            "steal_bias": 0, "block_bias": 0, "recruitable": true}, ... }
const START_CREW := ["ud_deuce", "ud_jojo", "ud_tank"]
const CREW_NAME := "BARN BURNERS"; const VAN_NAME := "OLD BLUE"   # Q2
```
City-crew ratings are computed by trip.gd: `STAGE_AVG[stage] + TIER[tier].all` on every stat, plus `spec` on the
player's specialty stats. A recruit keeps the ratings he had when he joined (stat points raise them later).
Game lengths are data (`target` per city, Q8). The tournament entry lists its rounds: crew, target, and the final's
boss (`ny_boss`).

### Save format (`user://trip.json`, `scripts/save.gd`, P5-05)
```
{"version": 1, "level": "normal", "city": "chicago", "game": 1, "beaten": ["hometown"],
 "points": 4, "roster": [{"id": "ud_deuce", "ratings": {...}}, ...], "starters": ["ud_deuce", "ud_jojo", "ud_tank"],
 "human": "ud_deuce", "bracket": {"round": 0}, "seen": ["trip_start", "hometown_arrive"],
 "record": {"wins": 5, "losses": 1}, "phase": "map"}   # phase = where Continue resumes: map/points/recruit/bracket
```
Written with `FileAccess` + `JSON.stringify` to a temp file, then renamed (no half-written save). Saved after every
game and after every choice (points spent, recruit, lineup). A game in progress is never saved: Continue after a
quit or reload starts that game again at 0-0. A missing or broken file = no trip (Continue hidden). Test runs use
`user://trip_test.json` so they never touch the owner's save. Settings stay in `user://settings.cfg`.

### Story script format (`scripts/story_text.gd`, P5-10; `const` data only)
```
const SCENES := {
  "trip_start": [
    {"who": "ud_jojo", "side": "left", "text": "Placeholder: Jojo shows the tournament flyer."},
    {"who": "ud_deuce", "side": "right", "text": "Placeholder: Deuce says yes.", "mood": ""},
  ],
  "hometown_arrive": [...], "hometown_won": [...], "chicago_arrive": [...], "chicago_won": [...],
  "first_loss": [...], "final_before": [...], "ending": [...],
}
```
`who` is a `PLAYERS` id (portrait and name from cities.gd) or `"narrator"` (no portrait). `{crew}`, `{van}`,
`{city}` in the text are replaced. Tap anywhere = next line (the first tap finishes the typing). A SKIP button skips
the scene. Seen scenes are remembered in the save (shown once; the "first_loss" scene only the first time).

### Art (art-audio, generated by scripts in `tools/art/`)
- Player sheets: same layout as Phase 4 (`assets/players/<id>.png`, 1480 x 320, 40 x 64 frames). player.gd loads
  `assets/players/<P.sheet>.png`, falling back to today's `blue_n`/`red_n` when the file is missing. Ids: `ud_deuce`,
  `ud_jojo`, `ud_tank`; city crews `<city>_g1`, `<city>_g2`, `<city>_boss`, `<city>_a1`, `<city>_a2` (`ht_`, `chi_`);
  `ny_boss`. Recruits in your colors (Q11 a): `<id>_crew.png`, used when he plays for you.
- Portraits: `assets/portraits/<id>.png`, 96 x 112 source px, drawn at 3x, facing right (story.gd mirrors for the
  right side), large bust in the approved fighting-game style, made from the same crews.json parts. Missing file =
  a colored silhouette.
- Map: `assets/map/usa.png` 640 x 360 (drawn 2x), `assets/map/map.json`:
  `{"cities": {"hometown": [x, y], ...}, "roads": {"hometown>chicago": [[x, y], ...], ...}}` (source px);
  `van.png` (2 frames x facing left/right, 48 x 32 each), `pin.png`, `pin_done.png` (trophy), `pin_locked.png`.
  Missing files = drawn shapes (outline rectangle, circles, a box van).

## Risks and how this plan handles them
- **Quick Game drifts.** Rating 50 = multiplier 1.0, `Flow.match` empty = today's setup; P5-00 baseline (100 games)
  vs P5-16 (100 games), each stat within 2 standard errors.
- **Static state across reloads.** Flow/Trip keep state in `static var`s (survive `reload_current_scene`, like
  `menu.start_done`); the save file is the truth on launch. The trip test runs a whole trip in one process and then
  again across a restart.
- **Web saves.** `user://` on the web is IndexedDB; P5-16 checks a save survives a page reload in Chromium, and the
  owner checks it on the tablet.
- **Pause with touch.** `get_tree().paused`, pause.gd and audio.gd `PROCESS_MODE_ALWAYS`; the joystick and A/B
  release on pause, so a held finger doesn't keep running after Resume. The pause button sits outside the joystick
  half's drag start (Q10) and is ignored during the first 0.5 s after Resume.
- **Balance of the ramp.** Ratings change shot odds by at most about 15%. `--autoplay --city <id> --cgame N` measures
  each city game's win share (40 games each); target for Phase 5 only: game 1 easier than game 3, no city game
  below about 30% for a CPU-controlled BLUE at starting ratings on Normal. Phase 6 balances properly.
- **Build size.** About 8 sheets per city (5 crew + 3 recruit recolors) at ~100 KB: ~0.9 MB per city, ~7 MB for
  the whole trip by Phase 6. P5-A1 tries indexed PNGs; P5-16 reports `index.pck`.
- **Tablet editing.** Data files are `const` dictionaries with comments; a typo shows as a parse error in the
  Godot editor right away (better than a silent JSON error).

## Owner questions (to answer now, before anything is built)
Answer with the letter; (a) is the recommendation each time. Answers go here and into `docs/VISION.md`.

### Round 1: your crew and the opponents
- **Q1 The 3 starting underdogs** (all from Hometown, Indiana; team colors blue and gold, VISION art style:
  muscular arcade builds, bold outlines; your team's ring stays blue):
  - **Deuce Carter**, #2, shooting wing and leader. Long and lean, deep brown skin, white headband over short
    hair, blue tank top with gold trim, a navy arm sleeve, knee-length shorts. Calm and proud. *Hometown's old
    high-school star; a knee injury cost him his college offer, and this trip is his second shot.*
  - **Jojo Reyes**, #5, quick point guard. Slim, tan skin, backwards gold cap, long blue tee, long shorts, a leg
    sleeve. Loud, funny, never stops talking. *Works nights at his uncle's gas station, where he found the
    tournament flyer and talked the others into going.*
  - **Tobias "Tank" Lind**, #9, big man (finishing and defense). Wide and heavy, light skin, red-brown buzz cut
    and a short beard, sleeveless navy hoodie, gold shorts. Quiet gentle giant. *A farm kid who learned to play on
    the barn driveway hoop and fixed up the van in his family's barn.*

  (a) These three as written. (b) These three, but I'll change some names or looks (tell us which).
  (c) Make it a mixed crew: Jojo becomes a woman guard, "Jo Reyes" (the art tool needs a new body type first).
  (d) Propose a completely different set.
- **Q2 Crew name and van name.** (a) The crew is the "Barn Burners", the van is "Old Blue". (b) The crew is the
  "Cornfield Kings", the van is "The Biscuit". (c) I'll name them myself.
- **Q3 How good players, average players and bosses differ.** Ratings are 0-100 (today's players are all 50).
  (a) Average players match the trip stage (about 40 in Hometown, rising to 70 in New York); good players are a
  little better overall and much better (+12) in two specialties; the boss is much better at everything (+20).
  No special moves, they are simply better. (b) Like (a), and each boss also gets one special move (for example
  an unstoppable dunk), built in Phase 6. (c) Bigger gaps: good players +20 in their specialties, bosses +30.
- **Q4 Easy / Normal / Hard on the trip.** (a) Pick the level when you start a trip; you can change it any time in
  Settings; it makes the opponents sharper or sloppier on top of the cities getting harder. (b) No level on the
  trip: the cities alone set the difficulty (the level is for Quick Game only). (c) Pick it when you start a trip,
  and it can't be changed for that trip.

### Round 2: progress and the trip
- **Q5 Stat points.** (a) 2 points per win (6 per city; a loss costs nothing); each point adds +3 to one stat of
  one player; no stat goes above 90. (b) 1 point per win; each point adds +5; cap 90. (c) Like (a), plus 3 bonus
  points for beating each city's boss.
- **Q6 How much story per city.** (a) One short scene when you arrive (4-6 lines) and one after you beat the city
  (3-5 lines), plus the trip start, your first loss, before the final, and the ending. (b) Only the arrival scene,
  plus the trip start and the ending. (c) Like (a), plus one line from the opponent before every game.
- **Q7 Moving on the trip map.** (a) The route is fixed; tap GO and the van drives to the next city; beaten cities
  get a trophy and can't be replayed. (b) Fixed route, but you can also replay a beaten city just for fun (no stat
  points). (c) You choose the order of the middle cities (Memphis to Los Angeles); the start and New York stay fixed.
- **Q8 Game lengths and the New York tournament.** (a) Hometown, Chicago and Memphis play to 11; New Orleans and
  Denver to 15; Seattle, Los Angeles and the tournament to 21. The tournament is 3 games (quarterfinal, semifinal,
  final); a loss lets you replay that round. (b) Only Hometown and Chicago to 11; Memphis, New Orleans and Denver to
  15; the rest to 21; same tournament as (a). (c) Lengths as (a), but a tournament loss sends you back to the
  quarterfinal.

### Round 3: menus and screens
- **Q9 Quick Game.** (a) Stays as today: BLUE vs RED, pick the level and the court. (b) It also lets you play
  with your trip crew against any crew you have beaten.
- **Q10 The pause screen.** (a) A small pause button in the top-right corner (away from the joystick side). The
  pause screen has a big RESUME, then RESTART and QUIT (to the title, or to the trip map in a trip game; a quit trip
  game starts again at 0-0), MUSIC ON/OFF and a sound volume slider, and the score with points, shots made/taken,
  dunks, steals and blocks for both teams. (b) The same, with the button in the top-left corner. (c) The same,
  but no stats, just the score.
- **Q11 How opponents look, and names on screen.** (a) Your crew always wears blue and gold; each city crew wears
  its own colors, but the ring under them is always red so you can tell who's who; a recruit changes into your
  colors; the top bar shows the crew names instead of BLUE and RED. (b) Opponents always wear red, recruits keep
  their old colors, and the top bar keeps BLUE and RED.

## Owner answers (2026-11-16, also in docs/VISION.md)
- Q1 underdogs: as written: Deuce Carter (shooting wing, leader), Jojo Reyes (quick point guard), Tobias "Tank" Lind
  (big man), with the looks and backstories proposed on this board.
- Q2 names: crew "Cornfield Kings", van "The Biscuit".
- Q3 tiers: moderate: average players match the trip stage (~40 rising to ~70), good players +12 in two specialties,
  boss +20 at everything, no special moves.
- Q4 difficulty on the trip: pick EASY/NORMAL/HARD at trip start, changeable in Settings, stacks on the cities.
- Q5 stat points: 2 per win, +3 per point, cap 90.
- Q6 story: arrival scene (4-6 lines) and a scene after beating each city, plus trip start, first loss, before the
  final and the ending.
- Q7 trip map: fixed route, tap GO, no replays of beaten cities.
- Q8 game lengths (owner's own answer): in EVERY city game 1 is to 11, game 2 to 15, game 3 (the boss game) to 21.
- Q8b tournament: quarterfinal, semifinal and final ALL to 21; a loss replays that round.
- Q9 Quick Game: stays as today.
- Q10 pause: button top-right; big RESUME, then RESTART and QUIT (to title or trip map; a quit game restarts at 0-0);
  MUSIC on/off, sound volume slider, score and per-team stats.
- Q11 looks: your crew in blue and gold; each city crew in its own colors but with a red ring; recruits change into
  your colors; the top bar shows crew names.

## Todo

### Wave 1: after the owner's answers
- **P5-00** | Baseline: 100 `--autoplay` games + 6 `--humantest` on the current dev build (stats table as in
  `docs/qa/phase4.md` section 2), and `index.pck` size | qa | `docs/qa/phase5-baseline.md` | the table is written
  and the commit is recorded | - | none
- **P5-01** | Core contract code: `flow.gd` (screens, `go`, `match`, `last_result`, `game_finished`, `build_screen`
  with the "not built yet" fallback panel, `--trip-test` loading `trip_test.gd` if present, `auto_step` rule),
  `ratings.gd` (stat formulas and STYLES as in the contract, `self_test()` printing the table, run with
  `-- --ratingtest`), `ui_kit.gd` (shared big button, panel, title label, text box and slider styles, taken from
  menu.gd's look, so all screens match) | gameplay A | `scripts/flow.gd`, `scripts/ratings.gd`, `scripts/ui_kit.gd`
  (new) | the three files parse in 4.3; `--ratingtest` shows 1.0 at rating 50 for every stat; nothing calls them yet,
  so autoplay is unchanged | - | none
- **P5-02** | main.gd hooks (small, early): screen hand-off at the top of `_ready()` (tests skip it); read
  `Flow.match` (target, look, music, level, team names, per-player sheet and ratings passed to `player.setup()`,
  the human starts on starter 0, tip-off label); shooting rating in `shot_probability()` and the free-throw chance;
  per-team counters the pause screen needs (`shots_t`, `makes_t`, `steals_t`); trip game over -> FINAL message, then
  `Flow.game_finished()` after `RESULT_DELAY`; add `pause.gd` to the HUD if the file exists; `--city <id>
  --cgame N` test flags (autoplay a trip matchup built by `Trip.match_for()` if trip.gd exists) | gameplay A |
  `scripts/main.gd` | with `Flow.match` empty: 3 autoplay + 1 humantest look like today; a hand-built test match
  (constant in the flag code) plays to 11 with the given names and sheets; no title in the test modes | P5-01 | Q11
  (names in the top bar; (b) = keep BLUE/RED)
- **P5-03** | player.gd + difficulty.gd: `setup()` takes an optional player dict (sheet path with fallback, ratings
  incl. speed/finishing/stamina, steal/block); speed, stamina drain/refill, dunk/layup make and dunk speed through
  `Ratings`; route the 5 CPU offense constants through `Difficulty.value`; `Difficulty.value` applies the team's
  style; the trip level from `Flow.match.level` | gameplay B | `scripts/player.gd`, `scripts/difficulty.gd` | Quick
  Game identical (rating 50, no style; 3 autoplay + humantest in range); a test match with all ratings 80 vs 20
  wins clearly (5 games); no `:=` on untyped values | P5-01 | Q4
- **P5-04** | City data: the 8-city ROUTE, STAGE_AVG, TIER, Hometown and Chicago complete (crews with names, roles,
  specialties, style, colors, targets, looks, music, story ids), the other 5 as `built: false` pins, the New York
  tournament stub (3 rounds: two stub crews reusing existing sheets and the champions with `ny_boss`), START_CREW
  and the 3 underdogs, CREW_NAME, VAN_NAME; placeholder names marked `# placeholder (Phase 6)` | gameplay B |
  `scripts/cities.gd` (new) | parses in 4.3; every id it names exists in PLAYERS; the full lineup print comes with
  P5-05's `--triptest-data` | P5-01 | Q1, Q2, Q3, Q8, Q11
- **P5-A1** | Player sheets from the generator: 3 underdogs, Hometown crew (5), Chicago crew (5), `ny_boss`, and the
  `_crew` recolors of the 6 recruitable Hometown/Chicago players (Q11 a); new palettes (GOLD, city colors) in
  crews.json; indexed PNG output if smaller; previews in `docs/art/`; CREDITS rows | art-audio |
  `tools/art/crews.json`, `tools/art/make_players.py`, `assets/players/*`, `docs/art/*`, `CREDITS.md` | sheets load in
  game (test match through `--city hometown --cgame 3 --shots`), look right in a screenshot, size per sheet reported
  | - | Q1, Q2, Q11

### Wave 2: after P5-01 and P5-02 are merged
- **P5-05** | Trip logic and save: `trip.gd` (static state; `new_trip(level)`, `continue_trip()`, `crew_for_game(city,
  n)` with the 1 good + 2 avg / 2 good + 1 avg / 2 good + boss rule, `match_for()` building `Flow.match`,
  `record_result()` with retry on a loss, `award_points()`, `spend(player, stat)` with the cap, `recruit(id)`,
  `next_city()` skipping `built: false` cities, bracket progress, `roster()`, `set_starters()`); `save.gd` (format
  above, temp-file write, version, broken file = none); `-- --triptest-data` prints every city game's lineup and a
  save/load round trip | gameplay A | `scripts/trip.gd`, `scripts/save.gd` (new) | the data print is right; a save
  written, the game restarted, and the same state loaded | P5-01, P5-04 | Q3, Q4, Q5, Q7, Q8
- **P5-06** | Title screen: ROAD TRIP (NEW TRIP / CONTINUE, "New trip" asks to confirm, level pick if Q4 a/c),
  QUICK GAME (today's start panel), SETTINGS (music on/off, sound volume, default level), CREW & CREDITS (roster with
  ratings and record; the CREDITS.md entries as a scrolling list in the game, kept in a const list); menu music;
  menu.gd: a TITLE button on the Quick Game panels | gameplay B | `scripts/title.gd` (new), `scripts/menu.gd` | every
  button works by touch in Chromium; settings remembered after a reload; Quick Game plays as today | P5-01, P5-02,
  P5-07 (volume) | Q4, Q9
- **P5-07** | Sound volume: `audio.set_sfx_volume(0..1)` and `sfx_volume` saved in `user://settings.cfg`, read once
  per run | gameplay B | `scripts/audio.gd` | volume 0 silences the effects, music unaffected; remembered | P5-01 | none
- **P5-08** | Pause screen as in the contract and Q10: button, `get_tree().paused`, RESUME / RESTART / QUIT,
  MUSIC, volume slider, score and the stats table; releases the joystick and buttons | gameplay B | `scripts/pause.gd`
  (new) | works in a Quick Game and a trip game; RESTART replays the same matchup; QUIT goes to the right screen; no
  input leaks into the game while paused | P5-02, P5-07 | Q10
- **P5-A2** | Portraits: `tools/art/make_portraits.py` (busts from the crews.json parts, approved style); first a
  sample sheet of the 3 underdogs for the owner (the coordinator shows it; the build doesn't wait), then all
  Hometown/Chicago crew portraits and `ny_boss` | art-audio | `tools/art/make_portraits.py` (new),
  `assets/portraits/*`, `docs/art/*`, `CREDITS.md` | portraits load in story.gd (or a screenshot of the sample) | P5-A1
  | Q1
- **P5-A3** | Map art: `tools/art/make_map.py`: pixel USA map with roads between the 8 cities, `map.json`, van (with
  the van name painted on if Q2 gives one), pins, trophy | art-audio | `tools/art/make_map.py` (new),
  `assets/map/*`, `CREDITS.md` | the map reads at 1280x720 and 1280x800; city points match the pins | - | Q2, Q7

### Wave 3: after P5-05 is merged (screens; each its own file, so they run in parallel)
- **P5-09** | Trip map: map, pins (beaten = trophy, locked = grey "coming soon"), GO button, the van drives the road
  to the next city (about 3 s, tap to skip), current city info (name, game n of 3, record, crew name), MENU button
  back to the title | gameplay A | `scripts/trip_map.gd` (new) | works with and without P5-A3 art; `auto_step` picks GO
  | P5-05 | Q7
- **P5-10** | Story scenes: `story.gd` (portraits left/right, name plate, text box with typing, tap to advance, SKIP,
  `{crew}`/`{van}`/`{city}` replace, `then` screen) and `story_text.gd` (placeholder scenes for the trip start,
  Hometown, Chicago, first loss, before the final, the ending) | gameplay B | `scripts/story.gd`,
  `scripts/story_text.gd` (new) | all scenes play by touch; missing portraits show silhouettes | P5-05 | Q1, Q2, Q6
- **P5-11** | Lineup: roster cards (sprite idle frame, name, role, 5 stat bars), tap to choose 3 starters, the first
  chosen is the one you control, the opponent's 3 shown on the right, PLAY | gameplay A | `scripts/lineup.gd` (new) |
  works with 3 to 10 players (scrolls); remembers the last lineup | P5-05 | none
- **P5-12** | Result and stat points: result screen (score, WIN/LOSS, game n of 3, RETRY or NEXT); points screen
  (points left, a player picker, 5 stats with + buttons, caps shown, DONE; undo before DONE) | gameplay B |
  `scripts/after_game.gd` (new) | loss -> retry the same game; points saved; cap enforced | P5-05 | Q5
- **P5-13** | Recruit screen: the 3 candidates (2 good + boss) with sprite, portrait, ratings, specialty; tap one,
  confirm; he joins the roster (in your colors if Q11 a) | gameplay A | `scripts/recruit.gd` (new) | the recruit is on
  the roster and in the save; can't be skipped by accident | P5-05 | Q11
- **P5-14** | Tournament bracket: the 3 rounds drawn as a bracket, current round lit, PLAY, a loss handled per Q8,
  the final against the champions and `ny_boss`, then story "ending" -> title with the trip marked complete |
  gameplay B | `scripts/bracket.gd` (new) | the stub bracket plays through to the ending | P5-05 | Q8
- **P5-15** | Trip test driver: `--trip-test` (headless; uses `user://trip_test.json`) runs title -> new trip ->
  Hometown 3 games (each `--autoplay`-style, short: `--target` wins if given) -> points -> recruit -> Chicago ->
  tournament stub -> ending, calling `auto_step()`; `--trip-force-loss N` makes game N count as a loss (tests the
  retry); `--trip-stop-after <city>` quits after that city; `--trip-resume` loads the save and goes on; prints
  `TRIP ...` lines (screen, city, game, result, points, recruit, saved) and `TRIP END` or a clear error;
  `--screens` (xvfb) screenshots every screen to `/tmp/hoops_screen_*.png` | gameplay A | `scripts/trip_test.gd`
  (new) | the full test reaches `TRIP END` with no script errors; stop + resume continues at the right game | P5-05 (and
  runs better as screens land) | none
- **P5-A4** (optional) | UI sounds, synthesized like the swish: tap, van horn, stat up, recruit fanfare, story blip |
  art-audio | `tools/` sound script, `assets/sfx/*`, `CREDITS.md` | files exist and are credited; screens play them by
  name if present (audio.play does nothing for a missing name) | - | none

### Wave 4: everything above merged
- **P5-16** | QA: `--trip-test` 3 times (one with `--trip-force-loss 2`), stop after Hometown + resume across a
  restart; 100 Quick Game autoplay vs P5-00 (within 2 SE); 40 games each for `--city hometown --cgame 1..3` and
  `--city chicago --cgame 1..3` on Normal (win share, length: a game to 11 should take about 5-8 min); humantest;
  `--screens` and a look at every screen at 1280x720 and 1280x800; web build in Chromium with touch: whole flow by
  taps, pause in game, save survives a page reload; `index.pck` size | qa | `docs/qa/phase5.md` | report written;
  bugs filed on this board | all | none
- **P5-17** | Docs: README.txt (title screen, the Road Trip, pause, stat points, lineup, saving, what's placeholder),
  the CLAUDE.md Testing section (new flags), CREDITS.md check | gameplay A | `README.txt`, `CLAUDE.md` (Testing
  section only, coordinator approves), `CREDITS.md` (check only) | the owner can follow the README on the tablet |
  P5-16 | none
- **P5-18** | Web publish (`tools/build_web.sh --publish`) and the lead's phase summary | coordinator, lead | - |
  published, summary sent | P5-17 | none

## Parallel plan

| Wave | Programmer A | Programmer B | Art-audio | QA |
|---|---|---|---|---|
| 1 | P5-01 core, then P5-02 main.gd | P5-04 cities data, then P5-03 player/difficulty (after P5-01) | P5-A1 sheets | P5-00 baseline |
| 2 | P5-05 trip + save | P5-07 volume, P5-08 pause, P5-06 title | P5-A2 portraits, P5-A3 map | quick check per merge |
| 3 | P5-15 trip test, P5-09 map, P5-11 lineup, P5-13 recruit | P5-10 story, P5-12 results/points, P5-14 bracket | P5-A4 (optional) | quick check per merge |
| 4 | P5-17 docs | | | P5-16, then P5-18 publish |

Why this split: `main.gd` is touched only by P5-02 (wave 1), `player.gd`/`difficulty.gd` only by P5-03, `menu.gd`
only by P5-06, `audio.gd` only by P5-07. Every screen is its own new file, so wave 3 tasks never share a file.
`tools/`, `assets/` and `CREDITS.md` belong to the art-audio agent until P5-17. Screens work without the art (drawn
fallbacks) and the flow works without screens ("not built yet" panel), so no wave waits on art.
P5-15 starts as soon as P5-05 merges so each later screen is tested in the full flow when it lands.

## Doing

## Review

## Done
