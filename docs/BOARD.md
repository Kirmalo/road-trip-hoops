# Task Board

Current phase: **Phase 11: Legends, Chapter 3 (the Present)** (planned 2026-11-25 by `lead-producer`; VISION "Phase 11
start": "Go on to the next"). The Phase 10 board is archived in `docs/board-phase10.md` (Phase 9: `docs/board-phase9.md`,
Phase 8: `docs/board-phase8.md`, Phase 7: `docs/board-phase7.md`, Phase 6: `docs/board-phase6.md`, Phase 5:
`docs/board-phase5.md`, Phase 4: `docs/board-phase4.md`, Phase 3: `docs/board-phase3.md`, Phase 2: `docs/board-phase2.md`,
Phase 1: `docs/board-phase1.md`).

**STATUS: WAVE 1 NEARLY DONE, WAVE 2 STARTING. The owner answered P1-P8 (VISION "Phase 11 answers P1-P8": all a,
except P4 c, both new animations, and P8 b, era teams in Quick Game, with the follow-up that each era court with its
era rules joins the Quick Game COURT list once that era's team is open), then the names after P11-02 (VISION "Phase 11
names (after P11-02)": **Sigurd** "Stretch" Halvorsen) and the music (VISION "Phase 11 era music": "Techno DRIVE!!!"
v2.5, CC-BY 4.0). Merged: P11-01, P11-02, P11-03, P11-04, P11-07 (era color magenta on graphite, a first guess until
the look check), P11-08. P11-05b is in review for the look check; P11-05 and P11-06 are still to come. Can start now:
P11-09, P11-11, P11-12, P11-20, P11-32, P11-37. P11-14 and P11-15 wait for the look check (P11-05, P11-05b, P11-06),
P11-16 for P11-11.**

Scope: a shippable Chapter 3 end to end, on the Phase 9-10 machinery (a chapter is data in `legends_data.gd` `CHAPTERS`
/ `LEGENDS` / `PERKS`, with per-chapter rating keys, extra animation pages, the `score` goal type, era rows in the draft
and the Hall; so Chapter 3 is mostly data, art, story and one era twist):
1. **Six original Present legends** (`docs/legends-plan.md` part 3: the modern look; spacing, step-backs, long shots):
   data, the name check (extended to today's players, nicknames and celebrations), sheets in the approved style with
   new era parts, portraits, unlock stories, joining lines, jersey numbers the owner approves.
2. **Their six challenges** on the six goal types we have (P3 a: no new goal type): Deep End fire (to 15), Toolbox
   comeback from 0-1 (to 15), Stretch race to 11 before 10, Switch score 5 yourself and win (to 11), Skylight 2 stops
   (to 15), Zigzag hold under 6 (to 11); and **the Present finale** to 21 (Deep End, Toolbox, Skylight).
3. **The era rules**: one twist, `era_present` "SPACE THE FLOOR" (P2 a: shots beyond the arc +8%, off-ball players 2 ft
   wider, a jumper right after a crossover or spin +10%, everyone). **The era court**: `era_present`, a made-up
   modern arena. **The era music**: a listening list, the owner picks (CC0 / CC-BY).
4. **The gate**: 48 stars or 30 tokens, no Chapter 2 finale needed (P7 a; already data). The timeline, chapter view, Hall and
   draft show three playable chapters.
5. **Mentors**: six new perks, one per Present legend, about 2 stat points each (P5 a; the owner's size after P10-26). **Draft**:
   unlocked Present legends join the Road Trip draft; the one-legend rule stays (one legend from any chapter + one boss).
6. **Signature moves**: a small play edge each (P4), plus **two** new animations (P4 c): Deep End's step-back
   (`stepback`, on his sheet only) and Zigzag's Euro-step (`eurostep`, on his sheet only); previews to the owner first.
7. **Carry-overs**: the Phase 10 watch items (the New York semifinal on Hard at the 20% edge, P11-26; Chapter 2 on Easy
   and Normal reading a little hard because of Lockbox, re-reported in P11-23), Rooftop's cradle look only if the owner
   asked for its own look at the Phase 10 check-in (P11-10).
8. **Era teams in Quick Game** (P8 b, P11-32..P11-36): GRANDFATHERS, FATHERS and PRESENT on YOUR TEAM / OPPONENT once 3
   legends of that era are unlocked in the Legends file (their 3 best, each player's stats shifted to average 50 like
   `Trip.quick_team()`, the era's colors and crew style), and (owner follow-up) each era court with its era twist on
   COURT once that era's team is open. This changes today's rule that the era looks are never in the COURT list.
9. **Not in Phase 11**: single legends in Quick Game, one-on-one, Legends cosmetics and the token ladder, Chapter 4 (it
   stays a `built: false` pin).

## Rules for every task in this phase
- **The hard rule (`docs/legends-plan.md` part 1): every legend is our own character.** No real player's name or
  nickname, face or likeness, number in a team's colors, signature accessory, trademark, slogan or celebration, team,
  arena or league. **The Present is the riskiest era**: its archetypes map straight onto famous players active today,
  whom every player knows by look. So **no legend may carry a combination of look, build, number and move that points
  at one real player** (e.g. the step-back shooter with a full beard; the slim deep-range guard with a mouthguard; the
  seven-foot European pick-and-pop big with shaggy hair; the big, strong point-forward going coast to coast in a
  headband; the quiet long-armed two-way wing who steals and runs). Spread the era parts (beards, buns, sleeves,
  headbands, tights) over several legends; never a whole famous set on one. Move names are plain basketball words
  ("step-back", "Euro-step", "pick-and-pop", "alley-oop"); no celebration or slogan of a real player in any story line,
  bio or HUD text (e.g. no "night night", "ice in my veins", "too small"). Kits never copy a current team's color pair,
  above all with a number that team made famous. The owner's reference picture is never an asset or an input to a
  script. Review rejects any change that breaks it, the same way it rejects an asset without a license.
- **Flagged in the plan's draft. P1 a: the owner took every proposal; after P11-02's check he changed Ozren to Sigurd
  (VISION "Phase 11 names (after P11-02)"). The names are fixed:**
  | Draft | Problem | Chosen (P1 a and the names row) |
  |---|---|---|
  | Calloway "Deep End" **Briggs**, step-back shooter, **beard** | Briggs is 1 letter from a real surname (Braggs, flagged in Phase 9); step-back + beard is one famous current guard's set | surname **Whitlock**; no beard (thin mustache, kept after P11-02), waves, no mouthguard |
  | Theo "**Swiss Knife**" Lindqvist, point-forward | "Swiss Army" is a knife maker's trademark and "Swiss Knife" sits next to it; the big strong coast-to-coast point-forward is two famous forwards' type | nickname **"Toolbox"**; man bun kept, no headband, a number neither of them wore |
  | Ozren "Stretch" Halvorsen, stretch big, **shaggy hair** | seven-foot European shooting big with shaggy hair is one famous big's look (and another's type) | first name **Sigurd** (owner after P11-02); close-cropped dark hair (never blond), a short boxed beard, medium build; no one-leg fadeaway |
  | **Idris** "Switch" Achterberg, two-way wing, long arms, short twists | "Idris" points at a famous actor; the quiet long-armed wing who steals and runs is one famous current forward's type | first name **Ellery**; bald with a short beard, bare arms (twists stay Ankles') |
  | Bodie "Skylight" **Ferreira**, rim-running big | Ferreira is a real player's surname (Rolando Ferreira, flagged in Phase 9) | surname **Castellano**; high-top fade kept |
  | **Santi** "Zigzag" Moreau, slasher, **headband** | "Santi" is how a current player is known (first name only, allowed, but very current); the headband is already Ankles' and Freight's | first name **Lucien**; curly hair, a knee sleeve, no headband |
- **Chapters 1-2 and the rest of the game play exactly as in Phase 10.** No game-sim change outside P11-12 (SPACE THE
  FLOOR), P11-17 (signature moves) and P11-22 (mentor perks); the era teams (P11-32..34) only add Quick Game choices, a
  Quick Game with the Phase 10 crews and courts plays as before. Every new hook is a
  default that is exactly today's game: with twist `none` / `era_grand` / `era_fathers`, no Present legend on the court
  and no new perk, `--autoplay` and the Chapter 1-2 `--challenge` runs match `docs/qa/phase10.md` /
  `phase10-challenges.md`.
- **Every chapter is data.** No `"present"` (or `"fathers"`, `"grand"`) string in game logic outside `legends_data.gd`,
  the art lookups keyed by chapter id (frames, pins) and the tests; Chapter 4 must later be data, art and story only.
- Tuning constants at the top of the script they belong to (the SPACE THE FLOOR values in `twists.gd`, the signature
  numbers in `player.gd` / `defense.gd`, the challenge numbers, per-chapter rating keys and perk sizes in
  `legends_data.gd`).
- Godot 4.3, no `:=` with untyped right sides, no new `.tscn`, touch first (joystick + A + B in every game: **no new
  button or gesture** for any move; a step-back or Euro-step comes out of today's inputs; the menus are big tap targets,
  Escape = BACK on desktop, the Android back goes BACK), 1280x720 and wider screens. Version stays 1.0.0.
- Saves stay compatible: **`legends.json` version 1** (new legends are just new keys: `"lg:<id>"`, `"fin:present"`, ids
  in `unlocked` / `seen` / `mentors`), **`trip.json` version 2** (a drafted Present legend is a `via: "draft"` entry
  with an `lg_` id). A Phase 10 build opening Phase 11 files must not crash (unknown ids ignored or dropped, P11-27).
- Test runs never touch the owner's files: `user://legends_test.json`, `user://trip_test.json`, `user://settings_test.cfg`.
- Art: generated by the `tools/art` scripts in the approved style (style sample v1, the approved animation sample, comic
  portraits v2, the approved legend look samples for build and finish), never drawn by hand, downloaded or traced; rerun
  the generator and commit its output. Music: CC0 or CC-BY only, a row in `CREDITS.md` and `CREDITS_LIST`.

## Process rule (worked in Phases 9-10, keep it)
- **At most 2 Godot processes per agent** at a time (the 4 cores are shared with the other agents; two `--anim-test`
  runs side by side ran out of memory in P10-30: run anim tests one at a time).
- **Every test run in its own `XDG_DATA_HOME`** (and, for a scratch project copy, its own `config/name`), so no run sees
  another's `user://` files. Runs that must share files (`--triptest-data` then `--load`; `--trip-stop-after` then
  `--trip-resume`; `--trip-test` then `--challenge` with its trip save) share one name and one data folder, nothing else.
- **Scratch folders outside the repo** (the agent's scratchpad or `/tmp/<task>/`): project copies for candidate numbers,
  logs, screenshots. Only the task's own files are committed.
- QA reports give the build commit, the flags, the game count per cell and the standard error; a 20-game cell cannot
  see a 3-point change (`docs/qa/phase9-challenges.md`).

## Shared contract (names fixed now so parallel tasks can call each other)

### Chapter 3 data (`scripts/legends_data.gd`)
- The `present` row becomes `"built": true` (P11-11) with: `"rules": "SPACE THE FLOOR"`, `"twist": "era_present"`,
  `"look": "era_present"`, `"music": "legends_present"`, `"fallback_music"` (an existing track, only a missing-file
  guard), `"gate"` (P7; today `{"stars": 48, "tokens": 30}`), `"crew"` (`"THE PRESENT"`, a `ratings.gd` style, the era
  palettes from P11-05, `ui_color`), `"legends"` (6 ids), `"finale"` (target 21, 3 ids, `"PRESENT FINALE"`),
  `"intro_scene": "legends_present_intro"`, `"finale_scenes": {"before": "legends_present_finale_before", "after":
  "legends_present_finale_after"}`, and the per-chapter rating keys `"challenge_avg"`, `"mate_drop"`,
  `"finale_stage_avg"` (P6 a, a step harder than Chapter 2; first guess 72 / 14 / 57, P11-23 tunes them).
- Legend ids (fixed by P1 a and VISION "Phase 11 names (after P11-02)"): `lg_deep_end` (Calloway "Deep End" Whitlock), `lg_toolbox` (Theo "Toolbox" Lindqvist),
  `lg_stretch` (Sigurd "Stretch" Halvorsen), `lg_switch` (Ellery "Switch" Achterberg), `lg_skylight` (Bodie "Skylight"
  Castellano), `lg_zigzag` (Lucien "Zigzag" Moreau). Each row has every Chapter 1-2 key (`name`,
  `full`, `first`, `last`, `chapter: "present"`, `archetype` (short enough for the draft card, P10-B5), `role`, `tier:
  "legend"`, `sheet`, `portrait`, `number`, `shape` (sum 0), `spec`, `steal_bias`, `block_bias`, `signature`,
  `challenge` (its `mates`: 2 other Present legends), `perk`, `colors`, `look`, `bio`, `unlock_scene: "lg_<id>_unlock"`).
- Stand-in chapter data (P11-03): `LegendsData.stand_in_test_data(chapter_id)` replaces `two_chapter_test_data()` (that
  name stays as a wrapper for `"fathers"`): any not-yet-built row becomes a built copy of Chapter 1 (ids `lg_zz_*`), so
  the self tests and `--legends-test-three` run three built chapters before P11-11 lands.
- Challenges (P3 a, the six existing types, no `deep` type): `lg_deep_end` `fire` (to 15), `lg_toolbox` `comeback`
  from 0-1 (to 15), `lg_stretch` `race` 11 before 10, `lg_switch` `score` `min` 5 (to 11), `lg_skylight` `stop` 2 (to
  15), `lg_zigzag` `hold` under 6 (to 11); finale `lg_deep_end`, `lg_toolbox`, `lg_skylight` to 21.
- New perks (P5 a; ids and keys distinct from Chapters 1-2 and from the twist keys; each about 2 stat points, P11-26
  measures): `"off_dribble"` (`pullup_bonus` +0.015: jumpers within `PULLUP_WINDOW` s after his crossover), `"extra_pass"`
  (`assist_shot_bonus` +0.015: a teammate's shot within 1.5 s of his pass), `"catch_shoot"` (`catch_shot_bonus` +0.015:
  his jumper within 1.0 s of a catch), `"contest"` (`guard_contest_bonus` 0.015: the man he guards shoots 1.5% worse),
  `"board_work"` (`rebound_reach_mult` 1.05), `"side_step"` (`layup_block_mult` 0.95: block chance on his layups).
  Defaults: 1.0 for `_mult`, 0.0 for `_bonus`.
- Signature ids (P4): `step_back` (Deep End), `coast` (Toolbox), `pop` (Stretch), `steal_break` (Switch), `lob_magnet`
  (Skylight), `euro_step` (Zigzag); one per legend; the `text` in plain words for the Hall (at most 2 lines, P10-B6).
  P4 c: two new extras (P11-05b's rows), `stepback` (12 frames, `"fade"` / `"fade_ft"` 2.0 the slide back, `"sheets"`
  `["lg_deep_end"]`, alias `shoot`) and `eurostep` (13 frames, a step one way then the other into the layup,
  `"steps"` / `"euro_path"` in feet to his left, the game moves him; `"sheets"` `["lg_zigzag"]`, alias `layup`); `step_back` plays `stepback` and `euro_step` plays `eurostep` when
  `Sheets.has_anim()` says so (counts `anim_stepback` / `anim_eurostep`).

### SPACE THE FLOOR (`scripts/twists.gd`, P2)
- Twist `era_present`: `"name": "SPACE THE FLOOR"`, a banner line, `"icon": "era_present"`. Keys (P2 a, chosen; starting
  points, P11-21 tunes): `long_shot_mult` 1.08 (existing: shots beyond the arc), `spacing_ft` 2.0 (new: off-ball spots in
  `player.gd` `SPOTS` move this far away from the ball side and the key, sideways, never further from the hoop than
  today's spot plus 1 ft, so a kick-out stays a fair shot), `pullup_mult` 1.10 (new: a jumper within `PULLUP_WINDOW` s
  after a crossover or spin, everyone). No shot clock change (P2 a). Each new key in `DEFAULTS` at today's
  value (0.0 / 1.0), read once through `Twists.value(key, default)`, no team read.

### Art and audio files
- Sheets `assets/players2/lg_<id>_p<N>.png`, palettes `lg_<id>`, `_crew`, `_crew_j1..3`, cards; strip
  `docs/art/legends_present.png` (`make_players_v2.py --legends-strip present`). Era palettes `ERA3_*` in
  `tools/art/crews.json` (P11-05). The `hook` and `fadeaway` extras stay on their sheets; P4 c's extras go only on their
  legend's sheet, listed in `format.json`'s `"extra"`: `stepback` on `lg_deep_end_x0.png`, `eurostep` on
  `lg_zigzag_x0.png`; `scripts/sheets.gd` `ALIASES` gains `stepback` -> `shoot`, `eurostep` -> `layup`.
- Portraits `assets/portraits/lg_<id>.png` and `_happy`; contact sheet `docs/art/legends_present_portraits.png`.
- Court `assets/courts/era_present_floor.png`, `era_present_backdrop.png`; `court_looks.gd` row `"era_present"` (no
  twist key, no reward; P8 b: the era looks join the Quick Game COURT list only through P11-34, once their era team is
  open, the twist coming from the chapter row); a made-up modern arena that does
  not read as GOLD HALL, the gym or Memphis' soul gym; no real team, arena, league, logo, sponsor or readable word.
- Legends UI `assets/legends/frame_present.png`, `pin_present.png`, `pin_present_done.png` (the locked pin exists),
  listed in `assets/legends/ui.json` under `frames.present` and `pins`.
- Music `assets/music/legends_present.ogg` (P11-20): the owner's pick, "Techno DRIVE!!!" v2.5 by Centurion_of_war,
  CC-BY 4.0, credited as "Techno drive" (VISION "Phase 11 era music").

### Story (`scripts/story_text.gd`)
- Scenes `legends_present_intro`, `lg_<id>_unlock` x 6, `legends_present_finale_before`, `legends_present_finale_after`;
  `RECRUIT_LINES` for the six. Lines that name a goal number use the numbers in `legends_data.gd` at the time; P11-23
  lists any line its tuning makes stale, P11-29 fixes it.

### Era teams in Quick Game (P8 b; `scripts/era_teams.gd`, new, static `EraTeams`)
- **Data, not chapter ids.** An era team exists for every `built` `CHAPTERS` row with a `crew` and 3+ legends. Its id is
  the crew name in lower case with `_`, a leading `the_` dropped: `grandfathers`, `fathers`, `present` (the Present's
  once P11-11 builds its row). Name: the crew name ("THE GRANDFATHERS"); color: the crew's `ui_color`; style: the crew's
  `style`; player colors: the crew's era `colors` (their `_crew` palettes, as in a Legends game).
- **Open** (`EraTeams.is_open(id)`): at least `ERA_TEAM_MIN` 3 of that chapter's legends unlocked in the Legends file
  (`Legends.is_unlocked()`, legends.gd loaded at run time; missing = no era teams). Never the trip save, never stars.
  `--legends-unlock-all` / `--legends-unlock-none` act through `Legends.is_unlocked()`; `--unlock-all` (every Quick
  Game team and court) opens every era team too, `--unlock-none` (a fresh install) closes them. Nothing is ever saved
  by the gate; test runs never save the picks (as today).
- **Lineup** (`EraTeams.lineup(id)`): the era's 3 best of its unlocked legends by the shape (owner P8 b; the build's
  first rule, `ERA_PICK` at the top of the script: the highest single stat of each shape, ties in data order, the
  first one is YOU; question Q11-E1 asks the owner to confirm). A test run that names a locked era team
  (`--quick-teams`) picks from all its legends.
- **Team dict** (`EraTeams.team(id)`): the same keys as `Trip.quick_team()` (`id`, `name`, `style`, `color`, `players`,
  `colors`); each player is `Trip.player_dict()` of his `lg_` id with his ratings shifted to average `Trip.QUICK_AVG` 50
  (the `Trip.quick_ratings()` shift on his shape, each stat clamped), `own_colors` true, no `"perk"` (perks are Road
  Trip only). His `signature` stays in his row, so signature moves play (question Q11-E2 asks the owner to confirm).
- **Era courts** (`EraTeams.look_of(id)`, `EraTeams.twist_of_look(look)`): the chapter's `look` joins the Quick Game
  COURT list once its era team is open (after the city courts, before the star reward courts) and brings the chapter's
  `twist` (OLD SCHOOL, ISO BALL, SPACE THE FLOOR) and the look's music, like a city court brings its city's twist.
  `--court era_<x>` still shows any look; a locked era court from `--court` plays without its twist unless
  `--unlock-all` (as city courts do).
- **Wiring**: `Difficulty.quick_teams()` lists the open era teams after the crews; `Difficulty.team_info()` knows the
  era ids (so `--quick-teams grandfathers,fathers` works), but `all_teams()` as the trip reads it (`team_of()`,
  `unlock_team()`) never returns an era id; `Trip.quick_team(id)` hands an era id to `EraTeams.team(id)`; `menu.gd`
  `quick_courts()` / `quick_twist()` add the era looks and their twists. A saved pick whose era team is closed again
  falls back to the Kings / the Bridge Runners (today's rule).

## Owner answers already in (VISION)
"Legends plan answers" (6 per era, gates 36 / 48 / 72 stars or tokens, a mix of goals, one legend + one boss may start,
small perks), "Phase 9 answers L1-L8" (challenges with your Road Trip crew, the Kings without a trip; boss-level drafted
legends; mentors for regular players only, Road Trip games only), "Phase 10 answers F1-F8" and the Phase 10 rows after
them (perks about 2 stat points each, the score goal meant as the hardest), "Phase 11 start", **"Phase 11 answers
P1-P8"** (P1 a, P2 a, P3 a, P4 c, P5 a, P6 a, P7 a, P8 b plus the era-court follow-up). The technical choices of
Phases 9-10 (the level picked on the chapter view, a drafted legend sits when he is an opponent, one LEGENDS row per
chapter in the draft, extras only on the sheets that list them) apply to Chapter 3 unchanged.

## Todo
Everything below (Tasks by wave).

## Doing

## Review
- **P11-17** (gameplay A, on the branch): the six Present moves in `player.gd` (constants at the top, block "P11-17"),
  each only for its signature: `step_back` (a jumper 16 ft+ within 1.0 s of his crossover hops back the stepback
  row's `fade_ft` 2.0 over its `fade` frames during the windup, keeps 0.5 of the contest; CPU sets it up with more
  crossovers and rises at 0.7 through P11-12's `try_cpu_cross_pullup`, twist or not), `coast` (a defensive rebound:
  6 s of sprinting with the ball with no drain, no lock, no CPU reserve; the CPU runs it to the rim), `pop` (CPU off
  the ball drifts out to 24.5 ft while his man is 10 ft+ off him; any catch-and-shoot jumper within 1.0 s keeps 0.5 of
  the contest; `since_catch` for everyone, set in `ball.hold`), `steal_break` (his poke recovered by his team, or his
  pick-off: x1.15 speed for 2 s; the CPU runs the lane), `lob_magnet` (ball.gd's lob range and his take-off range +3 ft;
  the CPU cuts at 0.16), `euro_step` (a layup from 5 ft+ with a man within 6 ft in front: the steps on the floor along
  the eurostep row's `euro_path` and its ms (0.36 s, 2.5 ft in), then the layup with block chance x0.5 and 0.5 of the
  rim contest; defense.gd reads the take-off, not the steps). `stepback` / `eurostep` frames when `Sheets.has_anim()`,
  counts `anim_stepback` / `anim_eurostep`; `sig_<id>_t<team>` plus detail counts. No new input. Test flag
  `--signature <id>[,..]` (BLUE only, like `--perk`) for `--humantest`. Seeded A/B (a scratch copy with a fixed seed):
  `--autoplay`, `--autoplay --twist era_present`, `--humantest`, `--challenge lg_steeple`, `--challenge lg_midrange`
  byte for byte the same logs as before. Each move seen in the 7 Present `--challenge` runs (11 games: step-back 19,
  anim_stepback 19, Euro-step 8, anim_eurostep 8, pop 44, coast 5, steal_break 5, lob_magnet 2) and as the human.
  For P11-29: CLAUDE.md's player.gd line and the test flags need the six moves and `--signature`.
- **P11-20** (art E): `assets/music/legends_present.ogg` (383 KB) from "Techno DRIVE!!!" v2.5 (`racing tecno_v2.5.ogg`),
  Centurion_of_war, CC-BY 4.0, credited "Techno drive": loop 47.86-87.86 s (the last 20 whole bars, 120 bpm; the
  track builds, so no whole-file loop), 30 ms crossfade before the downbeat, mono, -20.1 LUFS (from -13.2), true peak
  -4.2 dBFS, wrap step 0.019 (p99 0.091). `make_music.sh` step, `CREDITS.md` row, `CREDITS_LIST` entry (and the
  "need the credit" line names the Present era music). `--titletest` credits: 6 CC-BY rows, 6 shown. Not wired to a
  look or chapter here: `court_looks.gd` `era_present` and `legends_data.gd` still say `newyork` until their owners
  (P11-06 / P11-11) set `legends_present`; the `--challenge` check waits for P11-11.
- **P11-32** (gameplay F, P8 b; on the branch): `scripts/era_teams.gd` (static, nothing preloaded but `legends_data.gd`
  and `ratings.gd`; `legends.gd`, `trip.gd`, `difficulty.gd` loaded at run time). `ERA_PICK` "finale" (owner, VISION
  "Phase 11 era teams": the finale three from `CHAPTERS`' `finale`; "shape", Q11-E1 a, kept as the other value),
  `ERA_TEAM_MIN` 3. API `ids()`, `open_ids()`, `is_era_id()`, `info()` (an `all_teams()`-style entry for P11-33),
  `is_open()`, `unlocked_count()`, `lineup()`, `ratings_of()`, `team()`, `look_of()`, `twist_of_look()`, `era_of_look()`,
  `self_test()`. Today: `grandfathers` (Steeple 35/50/70/55/40, Velvet, Quarterback; OLD GYM, OLD SCHOOL) and `fathers`
  (Rooftop, Midrange, Freight; NIGHT PARK, ISO BALL), each player averaging 50, signature kept, no perk, own era kit.
  `self_test()` "" with no flag and under each of the four unlock flags (and both pairs); stand-in Present: 3 teams; a
  real test Legends file with 2 / 3 of an era unlocked: closed / open; a missing legends.gd: none open; nothing written.
- **P11-11** (gameplay-programmer A): `legends_data.gd` `present` row built (SPACE THE FLOOR, `era_present` twist and
  look, music `legends_present`, fallback `newyork`, gate 48 / 30, crew THE PRESENT `outside`, `ERA3_TEAL` /
  `ERA3_CORAL`, teal `ui_color`, finale Deep End, Toolbox, Skylight to 21, keys 72 / 14 / 57), the six legends (ids,
  names, numbers 26 / 38 / 49 / 29 / 52 / 58, the plan's shapes, challenges as the contract, signatures `step_back`,
  `coast`, `pop`, `steal_break`, `lob_magnet`, `euro_step`, looks per the board's spread), the six perks (data only),
  P11-02's lists in `REAL_NICKNAMES` / `REAL_NAMES`, `NUMBER_AVOID` + 4, 7, 77, five new probes; namecheck doc's Chapter
  3 table final. `--legendtest` LEGENDTEST OK (notes: twist, music, story, sheets, portraits not there yet). Two small
  test-only fixes outside the row, needed for a third built chapter: `legends.gd` `_check_chapter_walk()` checks a
  shipped chapter's scenes strictly once story_text.gd has its intro (LegendsData's rule), `trip.gd` self test expects
  a LEGENDS row per built chapter (was exactly two). 18 legends, max tokens 63.
- **P11-05b** (art B, P4 c: both; on the branch, waits for the owner's look check): `make_players_v2.py` EXTRA rows `stepback` (12 frames: drive step, plant with the
  last dribble, push back, hop, land square, then today's jumper; events `fade` [1, 4], `fade_ft` `STEP_FT` 2.0,
  release 8, air [6, 10]) and `eurostep` (13 frames: gather, long step right, plant, long step back left, plant on
  the takeoff foot, then today's layup; `steps` [1, 3], `euro_path` [[0, 0], [2, -1.5], [4, 0.9]] feet to his left
  (the game moves him), takeoff 5, release 8, air [5, 10]); carried by no sheet yet (`EXTRA_CREWS` empty), so
  `format.json`, `hands.json` and every sheet stay as they are. Previews `docs/art/stepback_v1.gif` (1.47 MB, vs the
  jump shot) and `docs/art/eurostep_v1.gif` (1.50 MB, vs the layup), 5 directions, drift drawn, 0 hand/ball check
  problems; stand-in bodies `sea_g1` (slim guard, short fade, no beard) and `den_g2` (slim guard, short twists, no
  headband) until the legends' sheets exist. For the owner's look check with P11-05.
- **P11-06** (art C): `era_present` court done: `make_courts.py --era present` (wide cool ash planks, teal key, dark
  centre circle and apron, charcoal bowl, black seats, teal / coral ribbon boards with stripes and chevrons only, phone
  lights; no word, digit or logo), `era_present_floor.png` 969 B, `era_present_backdrop.png` 15.8 KB, a
  `court_looks.gd` row (name proposed "NEW ARENA", music `newyork` until P11-20). Checked angled and flat shots;
  not in the COURT list (`--menushot --unlock-all --stars 72`); `--era` rewrites the older era files byte for byte.
  Teal is a first guess until P11-05's palettes.
- **P11-15** (art B): `make_portraits_v2.py --legends present` writes the six Present portraits, neutral and happy
  (`assets/portraits/lg_deep_end|toolbox|stretch|switch|skylight|zigzag[_happy].png`, 12 files, 167 KB) and
  `docs/art/legends_present_portraits.png` (283 KB). New kit parts: `crop` (line-up), `manbun` (low bun, faded
  undercut), `boxed_beard` (short, straight cheek line), `thin_mustache`; high-top fade = `flattop(fade=True)`. Looks:
  Deep End waves + thin mustache; Toolbox low man bun, clean-shaven; Stretch dark crop + boxed beard; Switch bald +
  boxed beard; Skylight high-top fade; Zigzag curls, no headband. Kits teal + coral on graphite / ink / white
  (`PRESENT_PALETTES` in the script, only where crews.json lacks that name); `present_kit()` takes P11-14's crews.json
  colors on a rerun. Older portraits unchanged (the new parts are opt-in).
- **P11-05** | Present era parts and a look sample | art-audio-integrator A | `make_players.py` "Phase 11 era parts"
  (modern_shorts, tights both/L/R, knee_sleeve, socks low, hair crop / waves / hightop_fade / manbun (a low bun),
  boxed_beard, thin_mustache; no older sheet changes: 0 of 121 sheets use them), `ERA3_*` palettes in `crews.json`
  (P11-07's MAGENTA, GRAPHITE, LIGHT, FLOOR plus INK, MINT, EMBER, AQUA), `--legends-sample present` writes
  `docs/art/legends_present_sample_v1.png` / `.gif`: Deep End (Whitlock: waves, thin mustache, no beard, right-leg
  tights, #26 placeholder, graphite / mint) and Toolbox (Lindqvist: low man bun, no headband, clean-shaven, #38
  placeholder, magenta / graphite), each in your colors, next to today's ud_deuce; parts row (Stretch dark crop +
  boxed beard + tights, bald + boxed beard wing, high-top fade + one-leg tights, crop + knee sleeve). Renderer
  checks 0 problems; `--anim-test` ANIM OK; nothing in `assets/` changed. Waiting for the owner's look check.
- **P11-37** (gameplay C): `legends_tour.gd` `_on_hall()` only: from a chapter view HALL passes `"pick"` = the
  chapter's first unlocked legend in data order (none unlocked: its first plaque, the locked detail; hall.gd's existing
  `_scroll_to_pick()` brings the row into view) and `"back_args"` the chapter; the timeline's HALL as before. From the
  data (`LegendsData.legend_ids(chapter)`), no chapter id. `--backtest` BACKTEST OK (Fathers view -> Hall picks
  lg_rooftop, BACK to the Fathers view), `--legends-test` LEGENDS END (20 games, 28/42 tokens); xvfb shots: Grandfathers
  view -> Steeple picked, Fathers view -> Rooftop picked.
- **P11-18** (gameplay B): `legends.gd`: the game flow already read every chapter from the data (gate, intro, finale,
  back to the chapter view, the swap), so no logic change was needed; `self_test()` now holds the three shipped chapters
  (`SHIPPED_CHAPTERS` 3, `SHIPPED_GATES` 24 / 36 or 12 / 48 or 30 as test expectations, `_check_shipped_gates()`), and
  the chapter walk adds: each chapter shut at the gate of the one before it, open at its own with no finale; the
  tour's `_intro_scene()` / `_finale_before()` pick the Present's scenes once; `Flow.legends_args()` (pause QUIT, game
  end) on the game's chapter; `parse_challenge()` per chapter and legend; the swap for all 18 legends (each drafted
  Present legend sits in exactly his own games). Breaking the Present gate or its swap fails the test. `--legendtest`
  OK; `--legends-test --difficulty hard` LEGENDS END (30 games, 63/63, Present opens by 42 tokens, its intro played);
  `--legends-chapter present` END (14/21); 3 `--autoplay`, 1 `--humantest`, `--challenge lg_deep_end` (met 15-14).

## Done
- **P11-01** (qa, merged) Phase 10 save fixtures: `docs/qa/fixtures/` legends_v1_ch2_mid / _ch2_done, trip_v2_father, settings_v2_48, make_ / check_fixtures_v4 (README "Phase 10 save fixtures"); scripted like P10-01, not a test-driver stop (README says why)
- **P11-02** (gameplay-programmer A, merged): today's-era lists and the first check of the six in
  `docs/legends-namecheck.md`. Owner after it (VISION "Phase 11 names (after P11-02)"): **Sigurd** "Stretch"
  Halvorsen (was Ozren; dark hair, never blond, medium build), Skylight keeps Castellano, Deep End keeps his thin
  mustache, Whitlock and "Stretch" kept; numbers at the look check.
- **P11-03** (gameplay-programmer B, merged) | `LegendsData.stand_in_test_data(chapter_id)` (`two_chapter_test_data()` its
  `"fathers"` wrapper, the same rows byte for byte; other rows get ids `lg_zz_<chapter>_1..6`); `Legends.self_test()`:
  the shipped walk is now `_check_chapter_walk()` over any number of built chapters, plus `_check_three_chapters()`
  (stand-in Present: gates 48 stars / 30 real tokens, max tokens 63, finales, unlocks, the swap and mentors over three
  eras, round trip); no "present" / two-chapter count left in the tests' expectations. Shipped matches (56 JSON dumps)
  and `--legends-test` / `--legends-test-two` output identical to 7dae4fa; `--legendtest` LEGENDTEST OK
- **P11-04** (gameplay-programmer C, merged): checked, no code change needed. `legends_tour.gd` and `hall.gd` already read
  every chapter from the data. In a scratch copy with a built stand-in `present` row (Chapter 1 copies `lg_zz_1..6`,
  18 legends, 63 tokens) at 1280x720 and 1600x720: the timeline shows Chapter 3 LOCKED with its gate ("OPENS AT 48
  STARS OR 30 TOKENS"), then open (PLAY), then FINALE WON on all three; the Chapter 3 view works; the Hall has three
  built rows and scrolls to the bottom (934 px list, scroll 354 = the end, the Chapter 4 locked row under it); the
  mentor picker with a full trip roster scrolls. With the shipped data every screen is the same as in Phase 10.
  `--backtest` BACKTEST OK (clean copy, and again with the stand-in on: the same 63 steps).
- **P11-07** (art D, merged): `frame_present.png` (56 x 88, 3541 B), `pin_present.png` (854 B), `pin_present_done.png`
  (876 B), listed in `ui.json` (`frames.present`, `pins.present.open/done`); preview `docs/art/legends_ui.png` (Chapter 3
  row). Made-up modern arena: graphite glass band, magenta LED strip, centre-hung screen crest (bars only), magenta
  plate, dark stands with a magenta light ribbon, glossy floor, spotlight. **Era color magenta on graphite is a first
  guess**: `ERA3_MAGENTA` / `_GRAPHITE` / `_LIGHT` / `_FLOOR` in the script; it reads crews.json's `ERA3_*` of those
  names when P11-05 adds them (else change `PRESENT_PAL`), rerun after the look check if they change. Chapters 1-2
  files and `timeline.png` byte for byte unchanged; the Chapter 3 timeline panel is still the dimmed hint (recolor once
  P11-06's court lands). `--legendtest` OK.
  Review (look-check follow-up): recolored teal + coral from the court's own ramps (the script's own values, crews.json
  no longer read), the Chapter 3 timeline panel now shows BIG STAGE in colour, `era_present` named BIG STAGE; frame
  3494 B, pins 884 / 869 B, Chapters 1-2 files and `ui.json` byte for byte unchanged; `--legendtest` OK.
- **P11-08** (art E, merged) | Era music listening list
  | art-audio-integrator E | `docs/audio_preview/LIST.md` ("Legends: Present"), `docs/audio_preview/present_*.ogg`
  | 3-5 upbeat chiptune tracks with a modern arena feel (electro, trap-style drums, big synth hooks; not New York's,
  Headspin or Bebop), CC0 or CC-BY only (no share-alike, no non-commercial), each license link checked on its page; the
  owner picks one during the build | none
  | Result: 5 samples `docs/audio_preview/present_a..e_*.ogg` (30 s, -20 LUFS, 232-288 KB each, 1.26 MB total): The Bass of the
  Future (CC0), Royal run (CC0), 8-Bit Hero Quest (CC-BY 4.0), Techno DRIVE!!! v2.5 (CC-BY 4.0), TECHNOCADE (CC-BY 3.0);
  list in `LIST.md` "Legends: Present"; the owner picks one. **Owner's pick (VISION "Phase 11 era music"): D, "Techno DRIVE!!!" v2.5 by
  Centurion_of_war, CC-BY 4.0, credit title "Techno drive"** (P11-20).

## Tasks by wave

### Wave 1 (no owner answer needed; P11-05b builds P4 c's two animations)
- **P11-01** | Phase 10 save fixtures
  | qa-balance-tester | `docs/qa/fixtures/` (new files only): `legends_v1_ch2_mid.json` (Chapter 1 closed, 3 Fathers
  beaten, a Fathers mentor), `legends_v1_ch2_done.json` (both chapters closed, 42 tokens), `trip_v2_father.json` (a
  drafted Father starting next to a boss, a Grandfather on the bench, a mentored player), `settings_v2_48.cfg` (48
  stars); README lines on how each was made
  | each made by the Phase 10 build (`83520f8`) through `--legends-test` / `--trip-test` stops, loads and plays in that
  build, committed | none
- **P11-02** | DONE | Name list for today's era and a first check of the six (draft names and the proposals)
  | gameplay-programmer A | `docs/legends-namecheck.md` (only; the data copy is P11-11's)
  | the lists extended with today's players (NBA and WNBA stars of about 2015-2026), their nicknames, and their famous
  celebrations and slogans (as words that must never appear); `NUMBER_AVOID` reviewed for the era (numbers a shipped
  legend wears stay legal: they passed their own check); the six chosen names (P1 a: Calloway "Deep End" Whitlock, Theo
  "Toolbox" Lindqvist, Ozren (now Sigurd) "Stretch" Halvorsen, Ellery "Switch" Achterberg, Bodie "Skylight" Castellano, Lucien
  "Zigzag" Moreau; first, last and nickname each) run through step 1 (every NBA and WNBA player) and the lists, the
  flagged draft names (Briggs, Swiss Knife, Idris, Ferreira, Santi) kept as probes that must fail; a table like Chapter
  2's with each verdict; the look combinations checked in words (the board's six risky sets, on the chosen looks); a
  hit on a chosen name goes back to the owner before P11-11 | none
- **P11-03** | DONE | Three built chapters in the Legends logic
  | gameplay-programmer B | `scripts/legends.gd`, `scripts/legends_data.gd` (test helpers only, no rows)
  | the contract's `stand_in_test_data(chapter_id)` (`two_chapter_test_data()` a wrapper, Phase 10 output unchanged);
  `Legends.self_test()` adds a three-chapter case (gates by stars and by tokens, tokens per chapter, finales, mentors and
  unlocks across three eras, `max_tokens()` 63); no "two chapters" assumption left in game logic; with the shipped data
  every match is byte for byte the same `Flow.match`; `--legendtest` LEGENDTEST OK | none
- **P11-04** | DONE (no code change) | Tour and Hall with three chapters
  | gameplay-programmer C | `scripts/legends_tour.gd`, `scripts/hall.gd`
  | checked in a scratch copy with the `present` row built from stand-in data: the timeline with 3 open chapters (PLAY,
  LOCKED with its gate, FINALE WON each), the chapter view, three Hall rows (the scroll reaches the last row, Chapter 4
  locked under it), the mentor picker with 18 legends (fits or scrolls); 1280 and 1600x720; with the shipped data every
  screen as in Phase 10 (screenshots before / after in the report); `--backtest` unchanged | none
- **P11-05** | Present era parts and a look sample
  | art-audio-integrator A | `tools/art/make_players.py` (era parts in "Phase 11 era parts", `--legends-sample present`),
  `tools/art/crews.json` (`ERA3_*` palettes and part docs only), `docs/art/legends_present_sample_v1.png` / `.gif` (new)
  | parts drawn once for the era: modern mid-thigh shorts, compression tights (full and one-leg), a knee sleeve, a man
  bun, a high-top fade, waves, close-cropped hair, a boxed beard and a thin mustache, modern low socks; a sample of two
  era looks (run, running dribble, a jumper, idle card) in the approved style for the **owner's look check**, using the
  chosen looks (P1 a: Deep End no beard, a thin mustache and waves; Stretch close-cropped hair and a short boxed beard;
  never the flagged ones); the report writes out the hard rule's combination check for both; nothing in
  `assets/` changes; `--anim-test` ANIM OK | none
- **P11-05b** (P4 c: both) | REVIEW, the owner's look check | The two new animations and their previews
  | art-audio-integrator B | `tools/art/make_players_v2.py` (two new `EXTRA` rows, `stepback` and `eurostep`, each
  carried only by the sheets that list it: `stepback` on `lg_deep_end`, `eurostep` on `lg_zigzag`; `--extra-preview
  stepback|eurostep`), `docs/art/stepback_v1.gif` and `docs/art/eurostep_v1.gif` (new: 5 directions each next to the
  move it replaces, the jumper / the layup)
  | ball and hand points for every frame of both; the step-back slides back about 2 ft before the jumper (the fadeaway
  pipeline, `"fade_ft"`), the Euro-step steps one way then the other into the layup (its sideways shift in the row, like
  `"fade_ft"`); drawn on a stand-in body until P11-14's sheets exist; both previews go to the owner's look check with
  P11-05; the hook and fadeaway rows and their output unchanged; nothing in `assets/` committed | P4 (answered c).
  Result: `stepback` (12 frames, `fade_ft` 2.0) and `eurostep` (13 frames, `euro_path`), no sheet carries them yet
  (`EXTRA_CREWS` empty), previews on stand-in bodies
- **P11-06** | The Present court: a made-up modern arena
  | art-audio-integrator C | `tools/art/make_courts.py` (`--era present`), `assets/courts/era_present_floor.png`,
  `era_present_backdrop.png`, `scripts/court_looks.gd` (one row; a display name proposed in the report, the owner
  confirms at the look check)
  | glossy floor, painted key in the era color, dark stands, light ribbons with abstract stripes only (no word, logo,
  sponsor, team or league), no real arena's shape; clearly not GOLD HALL, the gym or `soul_gym`; players and the ball
  readable on it (screenshots with `--court era_present`, both views); not in the COURT list yet (P11-34 adds the era
  looks once their era team is open) | none
- **P11-07** | DONE | Legends UI art for Chapter 3
  | art-audio-integrator D | `tools/art/make_legends_ui.py`, `assets/legends/` (`frame_present.png`, `pin_present.png`,
  `pin_present_done.png`, `ui.json`), `docs/art/legends_ui.png`
  | the Present card frame and pins in the approved style, era colors from P11-05's palettes (a first guess until the
  look check; rerun after it if they change); Chapters 1-2 files byte for byte unchanged | none
### Wave 2 (the answers are in; each task still waits for its wave 1 input. P11-13 dropped: P3 a needs no new goal type)
- **P11-09** | REVIEW | Legends test driver: three chapters
  | gameplay-programmer E | `scripts/legends_test.gd`
  | `--legends-test` plays every built chapter in data order and checks the next gate from the data (P7 a, 48 stars or
  30 tokens, no Chapter 2 finale needed: Chapter 3 opens after a Hard run of Chapters 1-2, 42 tokens; still locked
  after a Normal run, 28 tokens, unless `--stars 48`; the check reads the data, not these numbers); `--legends-test-three` (P11-03's stand-in)
  plays three chapters; `--legends-chapter present` works once the row is built; on today's data the output is the
  Phase 10 run; LEGENDS END on every level | P11-03 merged.
  Result: `--legends-test-three` (the timeline's third row as `stand_in_test_data()`); LEGENDS END on Easy (1 chapter,
  Chapter 2 locked at 9 tokens), Normal (2 chapters, Present locked at 28; 3 with `--stars 48`), Hard (3, opens at 42
  tokens), Legend (3), trip crew + force loss, `--legends-chapter present`; default and `--legends-test-two` runs
  byte for byte as before
- **P11-11** | Chapter 3 data and the name check in the data
  | gameplay-programmer A | `scripts/legends_data.gd`, `docs/legends-namecheck.md`
  | P11-02's lists copied into `REAL_NAMES` / `REAL_NICKNAMES` (plus probes that must fail: the flagged draft names, a
  present-day nickname, a celebration), `NUMBER_AVOID` from P11-02; the contract's `present` row and the six `LEGENDS`
  rows with the chosen names and ids (P1 a), their challenges and the finale as the contract lists them (P3 a), the
  per-chapter rating keys a step harder than Chapter 2 (P6 a, first guess 72 / 14 / 57), the gate 48 stars or 30
  tokens (P7 a, unchanged), the six `PERKS` rows of the contract (P5 a, data only), the six signatures with `step_back`
  and `euro_step` (P4 c); the doc's Chapter 3 table final; `--legendtest` LEGENDTEST OK (name check included) | P11-02,
  P11-03 merged
- **P11-12** | REVIEW (recovered by the coordinator from the agent's scratch copy after its worktree was removed; twisttest/legendtest OK, twist none byte-identical in seeded autoplay, 8 era games: 17 threes at 37%, 10.4 pull-ups off a cross at 63% (P11-21 to judge), banner shortened to fit) | The SPACE THE FLOOR era rules
  | gameplay-programmer B | `scripts/twists.gd`, `scripts/player.gd` (the spacing hook on the off-ball spots, the
  pull-up mark), `scripts/main.gd` (`pullup_mult` in `shot_probability()`), `scripts/twist_fx.gd` (banner icon)
  | P2 a: `long_shot_mult` 1.08, `spacing_ft` 2.0, `pullup_mult` 1.10 (no shot clock change); each key one
  `Twists.value(key, default)`, default = today; `--twisttest` TWISTTEST OK; `--twist era_present --autoplay` a sane
  game; banner and pause line read; twists `none`, `era_grand`, `era_fathers` unchanged | none (P2 answered a): **can
  start now**
- **P11-13** | ~~The `deep` goal type~~: **dropped** (P3 a: the six challenges use the existing goal types)
- **P11-14** | REVIEW | The six Present sheets
  | art-audio-integrator A | `tools/art/make_players_v2.py`, `tools/art/crews.json`, `assets/players2/` (pages,
  palettes, `palettes.json`, cards, `format.json`'s `"extra"`), `scripts/sheets.gd` (`ALIASES` rows `stepback` ->
  `shoot`, `eurostep` -> `layup` only)
  | 6 `lg_` sheets in the approved style with the approved era parts and their own era kits (no current team's color
  pair), `_crew` and `_crew_j1..3`; the hook and fadeaway pages stay where they are (their files unchanged); P4 c:
  `stepback` on `lg_deep_end_x0.png` and `eurostep` on `lg_zigzag_x0.png` (P11-05b's rows, `EXTRA_CREWS` / crews.json
  `"extra"` filled), both listed in `format.json`'s `"extra"`
  (`has_anim()` true only there; on any other sheet they draw the jumper / the layup); `--anim-test` ANIM OK on every
  sheet, the extra pages included; strip `docs/art/legends_present.png`; download growth reported | P11-05 and P11-05b
  approved at the look check, P11-11's name check (ids)
  Result: six sheets (crew "PR", numbers 26/38/49/29/52/58), kits teal / coral on graphite, ink, white (ERA3_TEAL,
  ERA3_DEEP_TEAL, ERA3_CORAL; magenta, mint, ember, aqua dropped; no kit wears teal and coral together); new parts
  hair `curls` (Zigzag) and `arm_len` (Switch, 1.08; pixel3d, default 1). The new extras get their own lane at extra
  column 0 (`EXTRA_LANE`), so they sit on x0; anim_test's overlap check now only flags extras one sheet carries
  together. Hook / fadeaway files unchanged; ANIM OK (also `--anim-fake-v2`); about 3.1 MB added
- **P11-15** | The Present portraits
  | art-audio-integrator B | `tools/art/make_portraits_v2.py` (`--legends present`), `assets/portraits/lg_*.png`,
  `docs/art/legends_present_portraits.png`
  | neutral and happy for each, comic style v2, original faces from the kit's parts, kits matching P11-14's; no likeness
  (the report says how each face differs from the famous player of his type) | P11-11's name check, P11-05 approved
- **P11-16** | REVIEW | Chapter 3 story
  | gameplay-programmer D | `scripts/story_text.gd`, `scripts/story.gd` (only if a lookup needs it)
  | the intro, 6 unlock scenes, the finale's before and after, 6 joining lines; light comedy with heart, the Present as
  the Fathers' "kids" grown up and the Grandfathers' grandkids (theme only, no real families), no real people, quotes,
  slogans, celebrations or trademarked move names; goal numbers as in the data; every scene the data names exists
  (`--legendtest`) | P11-11.
  Result: the 9 scenes (BIG STAGE, the giant screen, Toolbox's screwdriver, Switch's few words, Tank's grandpa and
  the shorts) and 6 joining lines in `story_text.gd`, no story.gd change; `--legendtest` OK with no scene NOTE;
  `--legends-test --legends-chapter present` plays all 9 scenes, LEGENDS END (Hard, 3 chapters, too)
- **P11-32** (P8 b) | REVIEW | Era teams: the logic
  | gameplay-programmer F | `scripts/era_teams.gd` (new, static `EraTeams`, loaded at run time by its callers; tuning
  `ERA_TEAM_MIN` 3 and `ERA_PICK` at the top)
  | the contract's "Era teams in Quick Game": `ids()`, `is_open(id)`, `lineup(id)`, `team(id)`, `look_of(id)`,
  `twist_of_look(look)`, all from `LegendsData.CHAPTERS` / `LEGENDS` (no chapter id string in the logic), the gate from
  `Legends.is_unlocked()` only (never the trip save or stars; a missing legends.gd = no era teams), each player's stats
  shifted to average 50 like `Trip.quick_ratings()`, no perk; `self_test()` returns "" or the reasons (per era: 2
  unlocked = closed, 3 = open with those 3, 6 = the 3 best by `ERA_PICK`; averages 50 within rounding, each stat in
  range; `--unlock-all` / `--unlock-none` / `--legends-unlock-all` / `--legends-unlock-none`; a chapter without a built
  row or crew gives no team; with `stand_in_test_data("present")` three teams), run from a scratch copy (P11-33 wires
  it into `--legendtest`); works today with `grandfathers` and `fathers`, `present` appears by itself once P11-11 builds
  its row; nothing saved | none (P8 answered b): **can start now**
- **P11-20** (moved up from wave 3) | Era music in the game
  | art-audio-integrator E | `assets/music/legends_present.ogg`, `tools/make_music.sh`, `CREDITS.md` (one row),
  `scripts/title.gd` (`CREDITS_LIST`, one entry)
  | the owner's pick: D, "Techno DRIVE!!!" v2.5 by Centurion_of_war (CC-BY 4.0, OpenGameArt), credit title "Techno
  drive" as the author asks (VISION "Phase 11 era music"; telling the author is the coordinator's, a request, not a
  license term); looped, processed to the game loudness (about -20 LUFS like Headspin), credited (CC-BY rows: title,
  author, license link, source, changes), `--titletest`'s CC-BY check passes; once P11-11 names the track,
  `--challenge <a Present legend>` plays `legends_present` | none: **can start now** (the `--challenge` check after
  P11-11 is merged)
- **P11-37** | HALL from a chapter view opens on its own era (P11-04's suggestion)
  | gameplay-programmer C | `scripts/legends_tour.gd` (`_on_hall()` only)
  | from a chapter view, HALL passes `"pick"` = that chapter's first unlocked plaque (data order) and `"back_args"` the
  chapter, so the Hall opens with that era's row in view and his detail up; a chapter with no unlocked legend opens the
  Hall as today but scrolled to its row if `hall.gd` already allows it, else as today (no hall.gd change in this task);
  HALL from the timeline unchanged; BACK still lands on the chapter view; works for every built chapter from the data
  (no chapter id string); `--backtest` BACKTEST OK, `--legends-test` LEGENDS END | none: **can start now**

### Wave 3
- **P11-17** | Signature moves
  | gameplay-programmer A | `scripts/player.gd`, `scripts/defense.gd`, `scripts/ball.gd` (only what the moves need)
  | per P4 (the six edges of `docs/legends-plan.md` P4): each edge works only for the legend whose `signature` it is
  (constants at the top, `sig_log()` lines and `sig_<id>_t<team>` counts); P4 c: Deep End's step-back jumper plays
  `stepback` (slides back the row's `"fade_ft"`, like the fadeaway) and Zigzag's Euro-step layup plays `eurostep` (the
  sim moves him along the row's `"euro_path"`, drawing never writes back), each
  when `Sheets.has_anim()` says so (`anim_stepback` and `anim_eurostep` counts, both seen); no new input: a human Deep
  End's jumper after his crossover flick is the step-back by itself, a human Zigzag's drive to the rim the Euro-step; without a
  Present legend on the court nothing changes (`--autoplay` stats, a Chapter 1 and a Chapter 2 `--challenge` pass);
  each move seen in a `--challenge` run | P11-12 merged (player.gd), P11-11, P11-14 (both extras)
- **P11-18** | REVIEW | Chapter flow and the gate
  | gameplay-programmer B | `scripts/legends.gd`
  | the P7 a gate (48 stars or 30 tokens, no Chapter 2 finale needed); Chapter 3's intro on its first open; its finale closes it; the tour returns to the right chapter
  view after a Chapter 3 game, unlock or finale; drafted Present legends sit when they are opponents; `Legends.self_test()`
  covers the three shipped chapters (gates, tokens per chapter, unlocks, mentors from three eras, the test trip save
  unchanged) | P11-11
- **P11-19** | REVIEW | Draft and lineup with three eras
  | gameplay-programmer C | `scripts/trip.gd`, `scripts/draft.gd`, `scripts/lineup.gd`
  | three LEGENDS rows in the draft in timeline order (Grandfathers, Fathers, then "UNLOCKED IN LEGENDS - THE
  PRESENT"), each in its frame and tag color, the draft scrolls to the last; `LEGEND_LIMIT` 1 across
  all chapters; legend + boss still allowed; `end_of_trip_crew()` `_sim_chapters` counts Chapter 3 only for Chapter 3 runs
  and `--city` runs; save version 2; every fixture loads; `--triptest-data` (+ `--load`) TRIPDATA OK | P11-11, P11-07.
  Result: the logic was already data-driven (no chapter id), so no rule changed: three rows, frames and tag colours from
  the data (screenshot at 1280 and 1600). trip.gd: `sim_chapters_for(match)` (the P10-N1 rule as one function; Chapter
  1 run grand, 2 + fathers, 3 all three, any other match every built chapter); self test drafts a third-era legend into
  slot 4 (any two legends refused, it + a boss start, kept by the version 2 save) and checks the best crew per chapter
  game. draft.gd: `DRAFT legends rows` print, `scroll_to_row(i)` / `scroll_to_last()` for drivers and shots. lineup.gd:
  comment only. TRIPDATA OK (+ `--load`); check_fixtures v2-v4 CHECK OK (v1 differs as on the base, its catch-up);
  `--trip-test --legends-unlock-all --stars 24` TRIP END; `--legendtest` OK
- **P11-21** | QA: the SPACE THE FLOOR era rules
  | qa-balance-tester | `docs/qa/phase11-era.md`; may tune the `era_present` numbers in `scripts/twists.gd`
  | 64+ `--autoplay --twist era_present` games against 64 twist `none` (and 40 with `--court era_present`): each rule
  noticeable (long-shot makes, the off-ball spacing in feet, pull-ups after a crossover or spin), length, shots, FG%, the share of shots
  from beyond the arc, fouls, rebounds inside the CLAUDE.md bands or explained; the share by crew style (outside vs
  inside crews: an era that favours long shots can favour one style, the Phase 9 lesson); twists `none`, `era_grand`,
  `era_fathers` match Phase 10 | P11-12

### Wave 4
- **P11-22** | REVIEW | Mentor perks for the Present
  | gameplay-programmer B | `scripts/player.gd`, `scripts/main.gd`, `scripts/defense.gd` (one hook per new perk key)
  | P5 a, the contract's six perks (`off_dribble`, `extra_pass`, `catch_shoot`, `contest`, `board_work`, `side_step`):
  each key one `p.perk(key, default)`, default = today; your side only, Road Trip games only (never an era team in
  Quick Game); `--perk <id>` shows each working (PERK line, `perk_<id>_t0`); `--autoplay` unchanged with no perk; the
  Hall's perk text from the data | P11-17 merged, P11-11
  Result: main.gd `_perk_shot_bonus()` (pullup_bonus on a jumper with `pullup_mark`, catch_shot_bonus on one with the
  new `player.catch_mark`, `PERK_CATCH_WINDOW` 1.0 s at the shot start), `_perk_mate_bonus()` (assist_shot_bonus: the
  passer of the caught pass, shot released within `PERK_ASSIST_WINDOW` 1.5 s of `do_pass()`; guard_contest_bonus: the
  shooter's slot man within `PERK_GUARD_FT` 8 ft), `_perk_rebound_reach()` (rebound_reach_mult on ball.gd's 20 px floor
  pick-up reach, missed field goals only); defense.gd `_side_step_mult()` on both layup block rolls. CPU: an off_dribble
  player rolls the SPACE THE FLOOR pull-up after his crossovers with any twist. Seeded runs with no perk / old perks /
  a Chapter 2 challenge / `--humantest` / `era_present` are byte for byte the base build's. Fires per game to 21 (3
  holders): contest 24, extra_pass 15, catch_shoot 13, board_work 2, off_dribble 4, side_step 0 in 5 games (rare: a
  block try at a BLUE layup inside the 5% band; for P11-26)
- **P11-23** | QA: Chapter 3 challenge balance
  | qa-balance-tester | `docs/qa/phase11-challenges.md`; may tune the Chapter 3 goal numbers and its per-chapter rating
  keys in `scripts/legends_data.gd`
  | `--challenge <id> --autoplay` with `--expected-roster` / `--best-roster` on every Present legend and the finale, Easy
  / Normal / Hard (40+ games a cell where near a band) and LEGEND; bands per P6 a (Normal about 55-60%, Hard about 35%
  with the expected crew, the finale a bit harder than Chapter 2's); harder level = lower share; each goal type met and failed in the logs; the Kings fallback
  and a mid-trip crew (48-star stage) reported; Chapters 1-2 re-run on Normal and Hard (expected crew) to show no change,
  and the Phase 10 watch item (Chapter 2 on Easy / Normal, Lockbox) reported; any story line made stale is listed for
  P11-29 | P11-17, P11-18, P11-21 tuned
- **P11-24** | REVIEW | Trip test: a drafted Present legend
  | gameplay-programmer C | `scripts/trip_test.gd`
  | with `--legends-unlock-all --stars 24`: `LEGEND_DRAFT_CHAPTERS` gains `present` (the first legend draft signs a
  Present legend from his chapter's row, the second one of another era), the lineup refuses two legends and accepts one
  + a boss; "TRIP legend eras" lists three rows; TRIP END on every level; `--trip-resume` works | P11-19
  | Result: `LEGEND_DRAFT_CHAPTERS` ["present", "fathers", "grand"], `LEGEND_DRAFTS` 3 (a 3rd only with a 3rd slot);
  the driver scrolls the draft to the legend's row (`scroll_to_row()`) before the tap; the refusal tries the oldest
  era on the roster then another, legend + boss starts the first draft's era; TRIP END checks every built chapter
  with an open legend had a row and the drafts followed the order. `--legends-unlock-all --stars 24` TRIP END on Easy
  (38 games), Normal (43), Hard (69): drafted present + fathers, refusal fathers/present, legend + boss present;
  `--difficulty legend --stars 72` (50 games) drafted all three eras, refusal grand/present; Normal stop after Chicago
  then `--trip-resume`: TRIP END, refusal and legend + boss checked again on the loaded save.
- **P11-33** (P8 b) | REVIEW | Era teams on the Quick Game team lists
  | gameplay-programmer F | `scripts/difficulty.gd` (`quick_teams()`, `team_info()`, `team_unlocked()` know the era
  ids; `all_teams()` for the trip unchanged), `scripts/trip.gd` (`quick_team()` hands an era id to `EraTeams.team()`,
  nothing else), `scripts/legends.gd` (`legendtest()` also runs `EraTeams.self_test()`, one call)
  | open era teams listed after the crews in `Difficulty.quick_teams()`; `team_of()` / `unlock_team()` never see an era
  id; `--quick-teams grandfathers,fathers` (any era id, locked or not, like the crews) plays them in `--autoplay` and
  `--humantest` (the BLUE / RED lines show the three legends at average 50, era colors, no `PERK` line, `SIGNATURE`
  lines as they happen); `--unlock-all` opens every era team, `--unlock-none` closes them, `--legends-unlock-all` /
  `-none` act through the Legends file's rule; a saved era pick whose team is closed falls back to the Kings / the
  Bridge Runners; nothing written to `settings.cfg`, `legends.json` or `trip.json` in a test run; `--legendtest`
  LEGENDTEST OK (era teams included), `--triptest-data` (+ `--load`) TRIPDATA OK, a Kings vs Bridge Runners
  `--autoplay` as in Phase 10 | P11-32 merged, P11-18 merged (legends.gd), P11-19 merged (trip.gd)
  Result: `Difficulty.team_info()` falls back to `EraTeams.info()`, `team_unlocked()` asks `EraTeams.is_open()`,
  `quick_teams()` adds `open_ids()` after the crews, `unlock_team()` refuses an era id (`is_era_team()`), `all_teams()` /
  `team_of()` unchanged; `Trip.quick_team()` hands an `"era"` entry to `EraTeams.team()`; `legendtest()` prints
  "LEGENDTEST era teams [grandfathers, fathers, present]: OK". Lists: no flag / `--unlock-none` / `--legends-unlock-none`
  Kings + Runners; `--legends-unlock-all` + the 3 era teams; `--unlock-all` all 11 crews + 3. Closed era picks fall back
  to Kings / Runners. `--autoplay` grandfathers,present 21-16 (7:51, SIGNATURE hook / finger_roll / outlet, no PERK),
  present,fathers 21-17, kings,grandfathers (normal) 21-13, kings,runners 15-21 (7:21); `--humantest` fathers,grandfathers
  22-18; `--triptest-data` (+ `--load`) TRIPDATA OK; nothing written in the test runs.
- **P11-34** (P8 b and the owner's follow-up) | REVIEW | Era teams and era courts on the Quick Game panel
  | gameplay-programmer D | `scripts/menu.gd` (`quick_courts()`, `quick_twist()`, the team and court button lines),
  `scripts/court_looks.gd` (the "never in quick_courts()" comments on the era rows only; the rows' data unchanged)
  | the COURT list adds each era look (OLD GYM, NIGHT PARK, the Present arena) once its era team is open
  (`EraTeams.look_of()`), after the city courts and before the star reward courts; it brings its chapter's twist
  (`EraTeams.twist_of_look()`: OLD SCHOOL, ISO BALL, SPACE THE FLOOR) in the twist line, the banner and the pause line,
  and the look's music; a closed era's look is not offered; YOUR TEAM / OPPONENT show the era team's name in its color;
  `--court era_grand` (any era look) shows it with its twist only when open or `--unlock-all` (like city courts); the
  CLAUDE.md "never in the Quick Game COURT list" rule is replaced (P11-29 writes it); Phase 10 COURT and team lists
  unchanged with no legend unlocked; checked with P11-33 merged | P11-32 merged, P11-06 merged (the `era_present` row),
  P11-12 merged (the `era_present` twist)
  Result: `quick_courts()` adds `open_era_looks()` (each open era team's `EraTeams.look_of()`, timeline order) after the
  city courts, before MIDNIGHT / GOLD HALL; `quick_twist()` asks `era_twist()` first (the chapter's twist only while
  that era team is open, so `--court era_grand` alone plays twist none, with `--unlock-all` or the era open OLD
  SCHOOL); `twist_line()` puts the twist name in front of a banner without one (SPACE THE FLOOR's); team buttons
  already read `EraTeams.info()` (name, era color). court_looks.gd: era comments rewritten, NIGHT PARK's `"music"`
  `blacktop` -> `legends_fathers` (the one data change, the coordinator's call), `music()` plays the chapter's
  `fallback_music` while an era track file is missing (checked: `newyork`). Lists with no legend unlocked: gym,
  blacktop / Kings, Runners (Phase 10). `--autoplay` grandfathers-present on BIG STAGE 19-22 (10:06), fathers-
  grandfathers on NIGHT PARK 19-22 (8:54), Kings-Runners 19-21 (10:47); `--humantest` on OLD GYM 21-14; LEGENDTEST OK.

### Wave 5
- **P11-25** | REVIEW | Back test and title test for Chapter 3
  | gameplay-programmer C | `scripts/main.gd` (the `--backtest` table only)
  | `BACKTEST_CHAPTER3` "present" like P10-25's steps: the Chapter 3 view goes to the timeline, the Hall on a Present
  plaque goes back to the chapter view and to CREW, the mentor picker closes, a Present challenge pauses, resumes and
  QUITs to its chapter view; the run opens Chapter 3's gate itself unless `--stars 48` / `--tokens 30` do; BACKTEST OK;
  `--titletest` passes (also `--stars 48 --legends-unlock-all`) | P11-22 merged (main.gd), P11-18, P11-04
  | Result: `BACKTEST_CHAPTER3` "present" and a copy of the P10-25 Chapter 2 steps (16 steps, 62 in all): the Chapter 3
  view (at the request 'present') BACK to the timeline and the title; the Hall picked on lg_deep_end BACK to the chapter
  view, to CREW, the mentor picker closes; the lg_deep_end challenge pauses, resumes, QUITs to the Present view, BACK
  twice. BACKTEST OK plain (the run forces 48 stars), with `--tokens 30` (stars 24, tokens 30) and `--stars 48`;
  TITLETEST DONE plain and with `--stars 48 --legends-unlock-all` (three chapters open, 18 unlocked, settings.cfg put
  back); 3 `--autoplay` 11-21, 21-20, 14-21 (9:03-10:35), `--humantest` 21-17.
- **P11-26** | QA: the ramp with a Present legend and the new perks
  | qa-balance-tester | `docs/qa/phase11-ramp.md`; may tune the Present perk sizes in `scripts/legends_data.gd`
  | `--best-roster` with the strongest legal three (a legend of any era + a boss) plus the best perk of any chapter
  (`--perk`), late boss games and New York on every level, 40+ games a cell: on Hard RED still wins 20%+ (the P8-25
  bound), with the New York semifinal re-measured on 80+ games (the Phase 10 watch item at the edge); each new perk worth
  about 2 stat points (measured like P9-30 / P10-26; sizes changed only with the owner's yes) | P11-22, P11-19
- **P11-27** | REVIEW | QA: saves
  | qa-balance-tester | `docs/qa/phase11-saves.md`
  | every 1.0.0, Phase 8, P10-01 and P11-01 fixture loads and plays on in Phase 11; a Phase 11 `legends.json` (Present
  legends unlocked, their tokens, a Present mentor) and a trip with a drafted Present legend, opened by the Phase 10
  build (`83520f8`): no error dialog, the unknown legend dropped from the trip, his tokens not counted, his mentor pair
  shown as NO MENTOR (P10-B2) and ignored, plays on; missing, broken, newer `legends.json`: no crash; NEW TRIP keeps it;
  no test touches the owner's files | P11-01, P11-18, P11-19, P11-22
  | Result (`docs/qa/phase11-saves.md`, build 67de993): all 11 old fixture resumes TRIP END (1.0.0 x5, Phase 8 x2,
  P10-01 x2, P11-01 x2), check_fixtures v2/v3/v4 CHECK OK; Phase 11 files (15 unlocked, 49 tokens, TOOLBOX -> NICO,
  DEEP END drafted on the bench / starting / YOU) in 83520f8: no error dialog, DEEP END dropped (a lineup he started in
  resets to the underdogs), 42/42 tokens, NICO "NO MENTOR" with no perk, game starts, TRIP END x3; its writes keep
  every Present key. 7 broken/newer legends.json variants: no crash; NEW TRIP keeps legends.json in both builds;
  owner's files untouched by 21 test runs. 5 `--autoplay` (9:50 mean, 52%), 2 `--humantest` 21-18. No bugs filed.
- **P11-28** | QA: screens
  | qa-balance-tester | `docs/qa/phase11-screens.md`, `docs/qa/phase11-screens.png`
  | xvfb screenshots: the timeline (Chapter 3 locked with its gate, open, all three finales won), the Chapter 3 view (crew
  and Kings, a drafted Present legend sitting), each Present challenge HUD line, the SPACE THE FLOOR banner, the era court
  in play (both views), each signature move (the step-back and Euro-step animations too), an unlock scene, the finale, the Hall's three rows
  and the mentor picker, the draft's three LEGENDS rows, the lineup rule line; 1280x720 and 1600x720, both hand layouts;
  the hard rule by eye on every screen, sheet and portrait (names, the look combinations of the board's table, kit
  colors against current teams); the Quick Game panel with an era team on each side and an era court (P11-35's
  shots); bugs filed as P11-Bn | P11-04, P11-14, P11-15, P11-16, P11-18, P11-19, P11-20, P11-34
- **P11-10** (only if the owner asked for it at the Phase 10 check-in) | Rooftop's cradle dunk with its own look
  | art-audio-integrator A | `tools/art/make_players_v2.py`, `assets/players2/lg_rooftop*` and `format.json` (a
  `cradle` extra on his sheet only), `scripts/player.gd` (the `CRADLE_STYLE` line only)
  | a preview gif first for the owner; `--anim-test` ANIM OK; `--challenge rooftop` shows `anim_cradle`; nothing else
  changes | the owner's answer, P11-14 and P11-22 merged
- **P11-35** (P8 b) | REVIEW | Title test and menu shots for the era teams
  | gameplay-programmer F | `scripts/title.gd` (the `--titletest` driver only)
  | `--titletest` on QUICK GAME: with no legend unlocked (`--legends-unlock-none`) no era team or era court is offered;
  with `--legends-unlock-all` YOUR TEAM and OPPONENT cycle through the three era teams and COURT through the three era
  looks (each with its twist line), then everything back as before (`settings.cfg` restored byte for byte, as today);
  `--menushot` shots with `--quick-teams grandfathers,present --court era_present` and `--quick-teams fathers,kings
  --court era_fathers` (no `main.gd` change; if one is needed, after P11-25 is merged); TITLETEST passes both ways, the
  shots in the report | P11-33, P11-34 merged
  | Result: `_test_quick_eras()` after the QUICK GAME checks: the lists hold exactly `EraTeams.open_ids()` (after the
  crews) and their looks (after the city courts, before MIDNIGHT / GOLD HALL, each with its twist and line), then YOUR
  TEAM, OPPONENT and COURT are tapped round their whole lists (button line, era color, twist line per stop; shots
  `hoops_quick_era_team_<side>_<id>` / `_court_<look>` under xvfb), picks and court put back. TITLETEST DONE plain and
  `--legends-unlock-none` (Kings, Runners; gym, blacktop), `--legends-unlock-all --stars 48` (+3 teams, OLD GYM / NIGHT
  PARK / BIG STAGE with OLD SCHOOL / ISO BALL / SPACE THE FLOOR), `--unlock-all --stars 72` (14 teams, 15 courts), and
  xvfb over a seeded settings.cfg (era picks, BIG STAGE): put back byte for byte. `--menushot` (with
  `--legends-unlock-all`, needed for the twist line) both pairs OK, no main.gd change. 3 `--autoplay` 21-20, 12-21,
  22-17 (8:40-12:26), `--humantest` 21-14.
- **P11-36** (P8 b) | REVIEW | QA: era team balance in Quick Game
  | qa-balance-tester | `docs/qa/phase11-quick-eras.md` (reports only; `ERA_PICK` or the average changed only with the
  owner's yes)
  | 200+ `--autoplay` games per era team against the Quick Game crews on Hard (half as BLUE, half as RED, against the
  Kings, the Bridge Runners and two unlocked crews, `--unlock-all`), gym court, plus 40+ per era on its own era court
  with its twist; the era team's win share about 50/50 (within about two standard errors of 50%, SE given); era vs era
  (100+ games per pair); game length, shots, FG%, fouls, rebounds in the CLAUDE.md bands; signature move counts per era;
  any lean explained (signature moves, the twist, the crew style); no test touches the owner's files | P11-33, P11-34
  merged, P11-17 merged (signature moves), P11-21 tuned
  | Result (`docs/qa/phase11-quick-eras.md`, 760 games, all ended, 0 errors, 0 shot-clock violations): gym vs 4 crews
  (120 each, SE ~4.5) Grandfathers 56.7%, Fathers 48.3%, Present **61.7%** (lean: 8.8 threes a game, step-back);
  own court Grandfathers **37.5%** on OLD GYM (80, SE 5.4; OLD SCHOOL's inside_mult helps the crews more), Fathers
  47.5%, Present 55.0% (40 each); era vs era (60 each) Present over Fathers 63.3%, over Grandfathers 56.7%, Fathers
  over Grandfathers 56.7%. Stats in the bands; Kings vs Runners interceptions 2.98 a game (60 games, SE 0.24), as
  Phase 10 Quick Game. Nothing changed; owner choices in the report (leave the Present lean, or a lower Present average)

### Wave 6
- **P11-29** | Docs
  | gameplay-programmer C | `CLAUDE.md`, `README.txt`, `CREDITS.md` (the Present art rows), `scripts/title.gd`
  (`CREDITS_LIST`), `docs/legends-plan.md` (part 3's Present table and part 4's row as shipped), `docs/release/itch_page.md`,
  `scripts/story_text.gd` (goal numbers in lines only, from P11-23's list)
  | every new key, flag, file and screen state documented, the era teams too (`era_teams.gd`, the Quick Game team and
  COURT lists, the changed "never in the COURT list" rule for the era looks, `--quick-teams` era ids, what
  `--unlock-all` / `--legends-unlock-all` open); credits in step; no story line names a stale number | P11-23..P11-28,
  P11-33..P11-36
- **P11-30** | Final Phase 11 QA
  | qa-balance-tester | `docs/qa/phase11.md`, `docs/qa/phase11-final.png`
  | `--legends-test` on every level (three chapters), `--legends-chapter present`, `--trip-test` on every level (three-era
  legends), resume, backtest, titletest, legendtest, startest, cosmetictest, twisttest, ratingtest, anim-test (alone),
  triptest-data, 20 `--autoplay` games against the Phase 10 reference, a Quick Game with each era team on its era court,
  the P11-21/24/28/29/36 results; a web build in
  Playwright (touch, real frame timing, not only `--fixed-fps`) through a Chapter 3 unlock, the Hall, a Present draft, a
  mentor and a Quick Game with an era team; release-ready or bugs | P11-29
- **P11-31** | Phase summary and check-in
  | lead-producer, then the coordinator | `docs/phase11-summary.md`; publish the web build, rebuild the web ZIP and the
  debug APK | the summary with 2-4 questions; the owner plays | P11-30

## Parallel plan (never two tasks on the same file in one wave)
| Wave | Tasks (agent) | Files | Notes |
|---|---|---|---|
| 1 | P11-01 (qa, done), P11-02 (gameplay A, done), P11-03 (gameplay B, done), P11-04 (gameplay C, done), P11-05 (art A), P11-05b (art B, both extras; review), P11-06 (art C), P11-07 (art D, done), P11-08 (art E, done) | fixtures / namecheck doc / legends.gd, legends_data.gd test helpers / legends_tour.gd, hall.gd / make_players.py, crews.json, sample / make_players_v2.py, gif / make_courts.py, courts, court_looks.gd / make_legends_ui.py, assets/legends / audio_preview | P11-02's results and P11-05 (+ P11-05b's two previews, P11-06) go to the owner's look check |
| 2 | P11-09 (E), P11-11 (A), P11-12 (B), P11-14 (art A), P11-15 (art B), P11-16 (D), P11-32 (F), P11-20 (art E), P11-37 (C) | legends_test.gd / legends_data.gd, namecheck doc / twists.gd, player.gd, main.gd, twist_fx.gd / make_players_v2.py, crews.json, players2, format.json, sheets.gd ALIASES / make_portraits_v2.py, portraits / story_text.gd, story.gd / era_teams.gd (new) / music, make_music.sh, CREDITS.md, title.gd CREDITS_LIST / legends_tour.gd | P11-09, P11-11, P11-12, P11-20, P11-32, P11-37 can start now (P11-02, P11-03 merged); P11-11's name check lands before P11-14 / P11-15 use the names; P11-14 after the look check (P11-05, P11-05b); P11-13 dropped |
| 3 | P11-17 (A), P11-18 (B), P11-19 (C), P11-21 (qa) | player.gd, defense.gd, ball.gd / legends.gd / trip.gd, draft.gd, lineup.gd / docs + twists.gd numbers | P11-17 after P11-12 is merged |
| 4 | P11-22 (B), P11-23 (qa), P11-24 (C), P11-33 (F), P11-34 (D) | player.gd, main.gd, defense.gd / docs + legends_data.gd numbers / trip_test.gd / difficulty.gd, trip.gd quick_team(), legends.gd legendtest() / menu.gd, court_looks.gd comments | P11-22 after P11-17 is merged; P11-33 after P11-18 and P11-19 are merged; P11-34 merged after P11-33 |
| 5 | P11-25 (C), P11-26 (qa), P11-27 (qa), P11-28 (qa), P11-36 (qa), P11-10 (art A, if asked), P11-35 (F) | main.gd / docs + legends_data.gd perk numbers / docs / docs / docs / make_players_v2.py, lg_rooftop pages, format.json, player.gd one line / title.gd titletest driver | P11-25 after P11-22 is merged; at most two qa tasks at once; P11-10 lands before P11-28 shoots the moves; P11-35 before P11-28 (its shots) |
| 6 | P11-29 (C), then P11-30 (qa), then P11-31 (lead, coordinator) | docs, title.gd, story_text.gd numbers / docs / docs | |

Chains to watch: `legends_data.gd` by P11-03 (test helpers, wave 1), P11-11 (rows, 2), then numbers only by P11-23 (4)
and P11-26 (5); `legends.gd` by P11-03 then P11-18; `player.gd` by P11-12, P11-17, P11-22, P11-10 (each merged before the
next); `defense.gd` by P11-17 then P11-22; `main.gd` by P11-12, P11-22, P11-25; `make_players_v2.py` by P11-05b, P11-14,
P11-10; `crews.json` by P11-05 then P11-14; `CREDITS.md` by P11-20 then P11-29; `title.gd` by P11-20, P11-35 (titletest
driver), then P11-29; `story_text.gd` by P11-16 then numbers only in P11-29; `docs/legends-namecheck.md` by P11-02 then
P11-11; `legends.gd` by P11-03, P11-18, then one line in P11-33; `trip.gd` by P11-19 then `quick_team()` in P11-33;
`court_looks.gd` by P11-06 then comments in P11-34; `format.json` by P11-14 then P11-10; `legends_tour.gd` only by
P11-37.

## Open questions for the owner
P1-P8 are answered (VISION "Phase 11 answers P1-P8"; `docs/legends-plan.md` "Phase 11 open questions"). Still open:
- Answered since: the names after P11-02 (VISION "Phase 11 names (after P11-02)") and the era music (VISION "Phase 11
  era music"). Still for the owner's look check: jersey numbers, kits, the court's name, the look sample and the two
  animation previews (P11-05, P11-05b, P11-06).
- From the Phase 10 check-in: Rooftop's cradle dunk (keep the windmill, or its own look: P11-10).
- **Q11-E1. Which "3 best" make an era team?** Shapes sum to 0 and the stats are averaged to 50, so "best" needs a rule.
  a) the three with the highest single stat in their shape, ties in data order (the build's first rule, `ERA_PICK`);
  b) the era's finale three once they are unlocked, else the unlocked ones in data order; c) the owner names three per
  era. (P11-32 builds a) as a stand-in; blocks only P11-36's final numbers.)
- **Q11-E2. Do the legends' signature moves play in Quick Game?** a) yes, they are the players (the build's default;
  perks never, they are Road Trip only); b) no, an era team plays plain. (P11-32 builds a); P11-36 measures it.)
