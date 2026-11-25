# Task Board

Current phase: **Phase 11: Legends, Chapter 3 (the Present)** (planned 2026-11-25 by `lead-producer`; VISION "Phase 11
start": "Go on to the next"). The Phase 10 board is archived in `docs/board-phase10.md` (Phase 9: `docs/board-phase9.md`,
Phase 8: `docs/board-phase8.md`, Phase 7: `docs/board-phase7.md`, Phase 6: `docs/board-phase6.md`, Phase 5:
`docs/board-phase5.md`, Phase 4: `docs/board-phase4.md`, Phase 3: `docs/board-phase3.md`, Phase 2: `docs/board-phase2.md`,
Phase 1: `docs/board-phase1.md`).

**STATUS: PLANNED, not started. Wave 1 needs no owner answer (except P11-05b, only built if P4 picks an animation).
Waves 2+ wait for the owner's answers to P1-P8 (`docs/legends-plan.md` "Phase 11 open questions") and the era look
check (P11-05, with P11-05b and P11-06).**

Scope: a shippable Chapter 3 end to end, on the Phase 9-10 machinery (a chapter is data in `legends_data.gd` `CHAPTERS`
/ `LEGENDS` / `PERKS`, with per-chapter rating keys, extra animation pages, the `score` goal type, era rows in the draft
and the Hall; so Chapter 3 is mostly data, art, story and one era twist):
1. **Six original Present legends** (`docs/legends-plan.md` part 3: the modern look; spacing, step-backs, long shots):
   data, the name check (extended to today's players, nicknames and celebrations), sheets in the approved style with
   new era parts, portraits, unlock stories, joining lines, jersey numbers the owner approves.
2. **Their six challenges** on the six goal types we have (hold / fire / stop / race / comeback / score; one more cheap
   type only if P3 asks for it), and **the Present finale** to 21.
3. **The era rules**: one twist, `era_present` "SPACE THE FLOOR" (P2). **The era court**: `era_present`, a made-up
   modern arena. **The era music**: a listening list, the owner picks (CC0 / CC-BY).
4. **The gate**: 48 stars or 30 tokens (already data; P7 asks whether to keep it). The timeline, chapter view, Hall and
   draft show three playable chapters.
5. **Mentors**: one perk per Present legend, about 2 stat points each (the owner's size after P10-26; P5). **Draft**:
   unlocked Present legends join the Road Trip draft; the one-legend rule stays (one legend from any chapter + one boss).
6. **Signature moves**: a small play edge each on existing animations, plus one new animation only if the owner picks
   one (P4; the step-back is the era's headline move).
7. **Carry-overs**: the Phase 10 watch items (the New York semifinal on Hard at the 20% edge, P11-26; Chapter 2 on Easy
   and Normal reading a little hard because of Lockbox, re-reported in P11-23), Rooftop's cradle look only if the owner
   asked for its own look at the Phase 10 check-in (P11-10).
8. **Not in Phase 11** unless P8 adds it: era teams and single legends in Quick Game, one-on-one, Legends cosmetics and
   the token ladder, Chapter 4 (it stays a `built: false` pin).

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
- **Flagged in the plan's draft (P1 asks the owner; P11-02 checks every proposal before any art uses it):**
  | Draft | Problem | Proposal (subject to P11-02) |
  |---|---|---|
  | Calloway "Deep End" **Briggs**, step-back shooter, **beard** | Briggs is 1 letter from a real surname (Braggs, flagged in Phase 9); step-back + beard is one famous current guard's set | surname **Whitlock**; no beard (thin mustache), waves, no mouthguard |
  | Theo "**Swiss Knife**" Lindqvist, point-forward | "Swiss Army" is a knife maker's trademark and "Swiss Knife" sits next to it; the big strong coast-to-coast point-forward is two famous forwards' type | nickname **"Toolbox"**; man bun kept, no headband, a number neither of them wore |
  | Ozren "Stretch" Halvorsen, stretch big, **shaggy hair** | seven-foot European shooting big with shaggy hair is one famous big's look (and another's type) | keep the name; close-cropped hair and a short boxed beard; no one-leg fadeaway |
  | **Idris** "Switch" Achterberg, two-way wing, long arms, short twists | "Idris" points at a famous actor; the quiet long-armed wing who steals and runs is one famous current forward's type | first name **Ellery**; bald with a short beard, bare arms (twists stay Ankles') |
  | Bodie "Skylight" **Ferreira**, rim-running big | Ferreira is a real player's surname (Rolando Ferreira, flagged in Phase 9) | surname **Castellano**; high-top fade kept |
  | **Santi** "Zigzag" Moreau, slasher, **headband** | "Santi" is how a current player is known (first name only, allowed, but very current); the headband is already Ankles' and Freight's | first name **Lucien**; curly hair, a knee sleeve, no headband |
- **Chapters 1-2 and the rest of the game play exactly as in Phase 10.** No game-sim change outside P11-12 (SPACE THE
  FLOOR), P11-13 (a new goal type, only if P3 c), P11-17 (signature moves) and P11-22 (mentor perks). Every new hook is a
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
  `"finale_stage_avg"` as P6 says (a first guess for P6 a: 72 / 14 / 57; P11-23 tunes them).
- Legend ids `lg_<nickname>` in lower case with `_` (the P1 answer fixes them; with the proposals: `lg_deep_end`,
  `lg_toolbox`, `lg_stretch`, `lg_switch`, `lg_skylight`, `lg_zigzag`). Each row has every Chapter 1-2 key (`name`,
  `full`, `first`, `last`, `chapter: "present"`, `archetype` (short enough for the draft card, P10-B5), `role`, `tier:
  "legend"`, `sheet`, `portrait`, `number`, `shape` (sum 0), `spec`, `steal_bias`, `block_bias`, `signature`,
  `challenge` (its `mates`: 2 other Present legends), `perk`, `colors`, `look`, `bio`, `unlock_scene: "lg_<id>_unlock"`).
- Stand-in chapter data (P11-03): `LegendsData.stand_in_test_data(chapter_id)` replaces `two_chapter_test_data()` (that
  name stays as a wrapper for `"fathers"`): any not-yet-built row becomes a built copy of Chapter 1 (ids `lg_zz_*`), so
  the self tests and `--legends-test-three` run three built chapters before P11-11 lands.
- New goal type (only if P3 c): `"deep"` in `CHALLENGE_TYPES`, row key `"min"`: your team scores at least `min` points
  from beyond the arc and wins; HUD "SCORE 6 FROM DEEP: 2"; judged at the end like `score`.
- New perks (P5 a; ids and keys distinct from Chapters 1-2 and from the twist keys; each about 2 stat points, P11-26
  measures): `"off_dribble"` (`pullup_bonus` +0.015: jumpers within `PULLUP_WINDOW` s after his crossover), `"extra_pass"`
  (`assist_shot_bonus` +0.015: a teammate's shot within 1.5 s of his pass), `"catch_shoot"` (`catch_shot_bonus` +0.015:
  his jumper within 1.0 s of a catch), `"contest"` (`guard_contest_bonus` 0.015: the man he guards shoots 1.5% worse),
  `"board_work"` (`rebound_reach_mult` 1.05), `"side_step"` (`layup_block_mult` 0.95: block chance on his layups).
  Defaults: 1.0 for `_mult`, 0.0 for `_bonus`.
- Signature ids (P4): `step_back` (Deep End), `coast` (Toolbox), `pop` (Stretch), `steal_break` (Switch), `lob_magnet`
  (Skylight), `euro_step` (Zigzag); one per legend; the `text` in plain words for the Hall (at most 2 lines, P10-B6).

### SPACE THE FLOOR (`scripts/twists.gd`, P2)
- Twist `era_present`: `"name": "SPACE THE FLOOR"`, a banner line, `"icon": "era_present"`. Keys (P2 a; starting
  points, P11-21 tunes): `long_shot_mult` 1.08 (existing: shots beyond the arc), `spacing_ft` 2.0 (new: off-ball spots in
  `player.gd` `SPOTS` move this far away from the ball side and the key, sideways, never further from the hoop than
  today's spot plus 1 ft, so a kick-out stays a fair shot), `pullup_mult` 1.10 (new: a jumper within `PULLUP_WINDOW` s
  after a crossover or spin, everyone). P2 c adds `shot_clock` 20 (existing key). Each new key in `DEFAULTS` at today's
  value (0.0 / 1.0), read once through `Twists.value(key, default)`, no team read.

### Art and audio files
- Sheets `assets/players2/lg_<id>_p<N>.png`, palettes `lg_<id>`, `_crew`, `_crew_j1..3`, cards; strip
  `docs/art/legends_present.png` (`make_players_v2.py --legends-strip present`). Era palettes `ERA3_*` in
  `tools/art/crews.json` (P11-05). The `hook` and `fadeaway` extras stay on their sheets; the P4 extra (`stepback` and/or
  `eurostep`) goes only on its legend's sheet, listed in `format.json`'s `"extra"`, on `lg_<id>_x0.png`.
- Portraits `assets/portraits/lg_<id>.png` and `_happy`; contact sheet `docs/art/legends_present_portraits.png`.
- Court `assets/courts/era_present_floor.png`, `era_present_backdrop.png`; `court_looks.gd` row `"era_present"` (no
  twist key, no reward, never in the Quick Game COURT list, like the other era looks); a made-up modern arena that does
  not read as GOLD HALL, the gym or Memphis' soul gym; no real team, arena, league, logo, sponsor or readable word.
- Legends UI `assets/legends/frame_present.png`, `pin_present.png`, `pin_present_done.png` (the locked pin exists),
  listed in `assets/legends/ui.json` under `frames.present` and `pins`.
- Music `assets/music/legends_present.ogg` (P11-20, the owner's pick from P11-08).

### Story (`scripts/story_text.gd`)
- Scenes `legends_present_intro`, `lg_<id>_unlock` x 6, `legends_present_finale_before`, `legends_present_finale_after`;
  `RECRUIT_LINES` for the six. Lines that name a goal number use the numbers in `legends_data.gd` at the time; P11-23
  lists any line its tuning makes stale, P11-29 fixes it.

## Owner answers already in (VISION)
"Legends plan answers" (6 per era, gates 36 / 48 / 72 stars or tokens, a mix of goals, one legend + one boss may start,
small perks), "Phase 9 answers L1-L8" (challenges with your Road Trip crew, the Kings without a trip; boss-level drafted
legends; mentors for regular players only, Road Trip games only), "Phase 10 answers F1-F8" and the Phase 10 rows after
them (perks about 2 stat points each, the score goal meant as the hardest), "Phase 11 start". The technical choices of
Phases 9-10 (the level picked on the chapter view, a drafted legend sits when he is an opponent, one LEGENDS row per
chapter in the draft, extras only on the sheets that list them) apply to Chapter 3 unchanged.

## Todo
Everything below (Tasks by wave).

## Doing

## Review
- **P11-07** (art D): `frame_present.png` (56 x 88, 3541 B), `pin_present.png` (854 B), `pin_present_done.png` (876 B),
  listed in `ui.json` (`frames.present`, `pins.present.open/done`); preview `docs/art/legends_ui.png` (Chapter 3 row).
  Made-up modern arena: graphite glass band, magenta LED strip, centre-hung screen crest (bars only), magenta plate,
  dark stands with a magenta light ribbon, glossy floor, spotlight. First-guess era colors `ERA3_MAGENTA` /
  `_GRAPHITE` / `_LIGHT` / `_FLOOR` in the script; it reads crews.json's `ERA3_*` of those names when P11-05 adds them
  (else change `PRESENT_PAL`), rerun after the look check. Chapters 1-2 files and `timeline.png` byte for byte
  unchanged; the Chapter 3 timeline panel is still the dimmed hint (recolor once P11-06's court lands). `--legendtest` OK.

## Done

## Tasks by wave

### Wave 1 (no owner answer needed; P11-05b only if P4 picks an animation)
- **P11-01** | Phase 10 save fixtures
  | qa-balance-tester | `docs/qa/fixtures/` (new files only): `legends_v1_ch2_mid.json` (Chapter 1 closed, 3 Fathers
  beaten, a Fathers mentor), `legends_v1_ch2_done.json` (both chapters closed, 42 tokens), `trip_v2_father.json` (a
  drafted Father starting next to a boss, a Grandfather on the bench, a mentored player), `settings_v2_48.cfg` (48
  stars); README lines on how each was made
  | each made by the Phase 10 build (`83520f8`) through `--legends-test` / `--trip-test` stops, loads and plays in that
  build, committed | none
- **P11-02** | Name list for today's era and a first check of the six (draft names and the proposals)
  | gameplay-programmer A | `docs/legends-namecheck.md` (only; the data copy is P11-11's)
  | the lists extended with today's players (NBA and WNBA stars of about 2015-2026), their nicknames, and their famous
  celebrations and slogans (as words that must never appear); `NUMBER_AVOID` reviewed for the era (numbers a shipped
  legend wears stay legal: they passed their own check); the plan's six **and** the board's proposals (Whitlock,
  Toolbox, Ellery, Castellano, Lucien) run through step 1 (every NBA player) and the lists; a table like Chapter 2's
  with each verdict; the look combinations checked in words (the board's six risky sets); results go to the owner with
  P1 | none
- **P11-03** | Three built chapters in the Legends logic
  | gameplay-programmer B | `scripts/legends.gd`, `scripts/legends_data.gd` (test helpers only, no rows)
  | the contract's `stand_in_test_data(chapter_id)` (`two_chapter_test_data()` a wrapper, Phase 10 output unchanged);
  `Legends.self_test()` adds a three-chapter case (gates by stars and by tokens, tokens per chapter, finales, mentors and
  unlocks across three eras, `max_tokens()` 63); no "two chapters" assumption left in game logic; with the shipped data
  every match is byte for byte the same `Flow.match`; `--legendtest` LEGENDTEST OK | none
- **P11-04** | Tour and Hall with three chapters
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
  proposed looks (not the flagged ones); the report writes out the hard rule's combination check for both; nothing in
  `assets/` changes; `--anim-test` ANIM OK | none
- **P11-05b** (only if P4 a, b or c) | The new animation and its preview
  | art-audio-integrator B | `tools/art/make_players_v2.py` (the new `EXTRA` row: `stepback`, `eurostep` or both,
  carried only by the sheets that list it), `docs/art/<move>_v1.gif` (new: 5 directions next to the move it replaces)
  | ball and hand points for every frame; a step-back slides back about 2 ft before the jumper (the fadeaway pipeline,
  `"fade_ft"`), a Euro-step steps one way then the other into the layup; goes to the owner's look check with P11-05;
  nothing in `assets/` committed | P4
- **P11-06** | The Present court: a made-up modern arena
  | art-audio-integrator C | `tools/art/make_courts.py` (`--era present`), `assets/courts/era_present_floor.png`,
  `era_present_backdrop.png`, `scripts/court_looks.gd` (one row; a display name proposed in the report, the owner
  confirms at the look check)
  | glossy floor, painted key in the era color, dark stands, light ribbons with abstract stripes only (no word, logo,
  sponsor, team or league), no real arena's shape; clearly not GOLD HALL, the gym or `soul_gym`; players and the ball
  readable on it (screenshots with `--court era_present`, both views); not in the COURT list | none
- **P11-07** | Legends UI art for Chapter 3
  | art-audio-integrator D | `tools/art/make_legends_ui.py`, `assets/legends/` (`frame_present.png`, `pin_present.png`,
  `pin_present_done.png`, `ui.json`), `docs/art/legends_ui.png`
  | the Present card frame and pins in the approved style, era colors from P11-05's palettes (a first guess until the
  look check; rerun after it if they change); Chapters 1-2 files byte for byte unchanged | none
- **P11-08** | Era music listening list
  | art-audio-integrator E | `docs/audio_preview/LIST.md` ("Legends: Present"), `docs/audio_preview/present_*.ogg`
  | 3-5 upbeat chiptune tracks with a modern arena feel (electro, trap-style drums, big synth hooks; not New York's,
  Headspin or Bebop), CC0 or CC-BY only (no share-alike, no non-commercial), each license link checked on its page; the
  owner picks one during the build | none

### Wave 2 (P11-09 needs no answer; the rest need P1-P7 and the look check)
- **P11-09** | Legends test driver: three chapters
  | gameplay-programmer E | `scripts/legends_test.gd`
  | `--legends-test` plays every built chapter in data order and checks the next gate from the data (Chapter 3: open
  after a Hard run of Chapters 1-2, 42 tokens; still locked after a Normal run, 28 tokens, unless `--stars 48`; the P7
  answer may change this, and the check reads the data, not these numbers); `--legends-test-three` (P11-03's stand-in)
  plays three chapters; `--legends-chapter present` works once the row is built; on today's data the output is the
  Phase 10 run; LEGENDS END on every level | P11-03 merged
- **P11-11** | Chapter 3 data and the name check in the data
  | gameplay-programmer A | `scripts/legends_data.gd`, `docs/legends-namecheck.md`
  | P11-02's lists copied into `REAL_NAMES` / `REAL_NICKNAMES` (plus probes that must fail: the flagged draft names, a
  present-day nickname, a celebration), `NUMBER_AVOID` from P11-02; the contract's `present` row and six `LEGENDS` rows
  (P1), their challenges and the finale (P3), the per-chapter rating keys (P6), the gate (P7), the six `PERKS` rows (P5,
  data only); the doc's Chapter 3 table final; `--legendtest` LEGENDTEST OK (name check included) | P11-02, P11-03, P1,
  P3, P5, P6, P7
- **P11-12** | The SPACE THE FLOOR era rules
  | gameplay-programmer B | `scripts/twists.gd`, `scripts/player.gd` (the spacing hook on the off-ball spots, the
  pull-up mark), `scripts/main.gd` (`pullup_mult` in `shot_probability()`), `scripts/twist_fx.gd` (banner icon)
  | per P2: each key one `Twists.value(key, default)`, default = today; `--twisttest` TWISTTEST OK; `--twist era_present
  --autoplay` a sane game; banner and pause line read; twists `none`, `era_grand`, `era_fathers` unchanged | P2
- **P11-13** (only if P3 c) | The `deep` goal type
  | gameplay-programmer C | `scripts/challenge.gd`
  | the contract's `deep` type: HUD line and count, met / failed at the end with a reason ("4 OF 6 FROM DEEP"), the six
  existing types unchanged; `--challenge` on a fake row in a scratch copy shows met and failed | P3
- **P11-14** | The six Present sheets
  | art-audio-integrator A | `tools/art/make_players_v2.py`, `tools/art/crews.json`, `assets/players2/` (pages,
  palettes, `palettes.json`, cards, `format.json` only if P4 adds an extra)
  | 6 `lg_` sheets in the approved style with the approved era parts and their own era kits (no current team's color
  pair), `_crew` and `_crew_j1..3`; the hook and fadeaway pages stay where they are (their files unchanged); the P4 extra
  on its sheet if picked; `--anim-test` ANIM OK on every sheet; strip `docs/art/legends_present.png`; download growth
  reported | P11-05 approved (and P11-05b if P4 a-c), P11-11's name check (ids)
- **P11-15** | The Present portraits
  | art-audio-integrator B | `tools/art/make_portraits_v2.py` (`--legends present`), `assets/portraits/lg_*.png`,
  `docs/art/legends_present_portraits.png`
  | neutral and happy for each, comic style v2, original faces from the kit's parts, kits matching P11-14's; no likeness
  (the report says how each face differs from the famous player of his type) | P1, P11-11's name check, P11-05 approved
- **P11-16** | Chapter 3 story
  | gameplay-programmer D | `scripts/story_text.gd`, `scripts/story.gd` (only if a lookup needs it)
  | the intro, 6 unlock scenes, the finale's before and after, 6 joining lines; light comedy with heart, the Present as
  the Fathers' "kids" grown up and the Grandfathers' grandkids (theme only, no real families), no real people, quotes,
  slogans, celebrations or trademarked move names; goal numbers as in the data; every scene the data names exists
  (`--legendtest`) | P1, P3, P11-11

### Wave 3
- **P11-17** | Signature moves
  | gameplay-programmer A | `scripts/player.gd`, `scripts/defense.gd`, `scripts/ball.gd` (only what the moves need)
  | per P4: each edge works only for the legend whose `signature` it is (constants at the top, `sig_log()` lines and
  `sig_<id>_t<team>` counts); the P4 extra played when `Sheets.has_anim()` says so (`anim_stepback` / `anim_eurostep`
  counts); no new input: a human Deep End's jumper after his crossover flick is the step-back by itself; without a
  Present legend on the court nothing changes (`--autoplay` stats, a Chapter 1 and a Chapter 2 `--challenge` pass);
  each move seen in a `--challenge` run | P11-12 merged (player.gd), P11-11, P11-14 (P4 extra)
- **P11-18** | Chapter flow and the gate
  | gameplay-programmer B | `scripts/legends.gd`
  | the P7 gate rule; Chapter 3's intro on its first open; its finale closes it; the tour returns to the right chapter
  view after a Chapter 3 game, unlock or finale; drafted Present legends sit when they are opponents; `Legends.self_test()`
  covers the three shipped chapters (gates, tokens per chapter, unlocks, mentors from three eras, the test trip save
  unchanged) | P11-11, P7
- **P11-19** | Draft and lineup with three eras
  | gameplay-programmer C | `scripts/trip.gd`, `scripts/draft.gd`, `scripts/lineup.gd`
  | three LEGENDS rows in the draft in timeline order (Grandfathers, Fathers, then "UNLOCKED IN LEGENDS - THE
  PRESENT"), each in its frame and tag color, the draft scrolls to the last; `LEGEND_LIMIT` 1 across
  all chapters; legend + boss still allowed; `end_of_trip_crew()` `_sim_chapters` counts Chapter 3 only for Chapter 3 runs
  and `--city` runs; save version 2; every fixture loads; `--triptest-data` (+ `--load`) TRIPDATA OK | P11-11, P11-07
- **P11-20** | Era music in the game
  | art-audio-integrator E | `assets/music/legends_present.ogg`, `tools/make_music.sh`, `CREDITS.md` (one row),
  `scripts/title.gd` (`CREDITS_LIST`, one entry)
  | the owner's pick, looped, processed to the game loudness (about -20 LUFS like Headspin), credited (CC-BY rows: title,
  author, license link, source, changes); `--challenge <a Present legend>` plays `legends_present` | P11-08 and the
  owner's pick, P11-11 (the row names the track)
- **P11-21** | QA: the SPACE THE FLOOR era rules
  | qa-balance-tester | `docs/qa/phase11-era.md`; may tune the `era_present` numbers in `scripts/twists.gd`
  | 64+ `--autoplay --twist era_present` games against 64 twist `none` (and 40 with `--court era_present`): each rule
  noticeable (long-shot makes, the off-ball spacing in feet, pull-ups if P2 a), length, shots, FG%, the share of shots
  from beyond the arc, fouls, rebounds inside the CLAUDE.md bands or explained; the share by crew style (outside vs
  inside crews: an era that favours long shots can favour one style, the Phase 9 lesson); twists `none`, `era_grand`,
  `era_fathers` match Phase 10 | P11-12

### Wave 4
- **P11-22** | Mentor perks for the Present
  | gameplay-programmer B | `scripts/player.gd`, `scripts/main.gd`, `scripts/defense.gd` (one hook per new perk key)
  | each key one `p.perk(key, default)`, default = today; your side only, Road Trip games only; `--perk <id>` shows each
  working (PERK line, `perk_<id>_t0`); `--autoplay` unchanged with no perk; the Hall's perk text from the data | P11-17
  merged, P11-11, P5
- **P11-23** | QA: Chapter 3 challenge balance
  | qa-balance-tester | `docs/qa/phase11-challenges.md`; may tune the Chapter 3 goal numbers and its per-chapter rating
  keys in `scripts/legends_data.gd`
  | `--challenge <id> --autoplay` with `--expected-roster` / `--best-roster` on every Present legend and the finale, Easy
  / Normal / Hard (40+ games a cell where near a band) and LEGEND; bands per P6 (P6 a: Normal about 55-60%, Hard about
  35% with the expected crew); harder level = lower share; each goal type met and failed in the logs; the Kings fallback
  and a mid-trip crew (48-star stage) reported; Chapters 1-2 re-run on Normal and Hard (expected crew) to show no change,
  and the Phase 10 watch item (Chapter 2 on Easy / Normal, Lockbox) reported; any story line made stale is listed for
  P11-29 | P11-17, P11-18, P11-21 tuned, P11-13 (P3 c)
- **P11-24** | Trip test: a drafted Present legend
  | gameplay-programmer C | `scripts/trip_test.gd`
  | with `--legends-unlock-all --stars 24`: `LEGEND_DRAFT_CHAPTERS` gains `present` (the first legend draft signs a
  Present legend from his chapter's row, the second one of another era), the lineup refuses two legends and accepts one
  + a boss; "TRIP legend eras" lists three rows; TRIP END on every level; `--trip-resume` works | P11-19

### Wave 5
- **P11-25** | Back test and title test for Chapter 3
  | gameplay-programmer C | `scripts/main.gd` (the `--backtest` table only)
  | `BACKTEST_CHAPTER3` "present" like P10-25's steps: the Chapter 3 view goes to the timeline, the Hall on a Present
  plaque goes back to the chapter view and to CREW, the mentor picker closes, a Present challenge pauses, resumes and
  QUITs to its chapter view; the run opens Chapter 3's gate itself unless `--stars 48` / `--tokens 30` do; BACKTEST OK;
  `--titletest` passes (also `--stars 48 --legends-unlock-all`) | P11-22 merged (main.gd), P11-18, P11-04
- **P11-26** | QA: the ramp with a Present legend and the new perks
  | qa-balance-tester | `docs/qa/phase11-ramp.md`; may tune the Present perk sizes in `scripts/legends_data.gd`
  | `--best-roster` with the strongest legal three (a legend of any era + a boss) plus the best perk of any chapter
  (`--perk`), late boss games and New York on every level, 40+ games a cell: on Hard RED still wins 20%+ (the P8-25
  bound), with the New York semifinal re-measured on 80+ games (the Phase 10 watch item at the edge); each new perk worth
  about 2 stat points (measured like P9-30 / P10-26; sizes changed only with the owner's yes) | P11-22, P11-19
- **P11-27** | QA: saves
  | qa-balance-tester | `docs/qa/phase11-saves.md`
  | every 1.0.0, Phase 8, P10-01 and P11-01 fixture loads and plays on in Phase 11; a Phase 11 `legends.json` (Present
  legends unlocked, their tokens, a Present mentor) and a trip with a drafted Present legend, opened by the Phase 10
  build (`83520f8`): no error dialog, the unknown legend dropped from the trip, his tokens not counted, his mentor pair
  shown as NO MENTOR (P10-B2) and ignored, plays on; missing, broken, newer `legends.json`: no crash; NEW TRIP keeps it;
  no test touches the owner's files | P11-01, P11-18, P11-19, P11-22
- **P11-28** | QA: screens
  | qa-balance-tester | `docs/qa/phase11-screens.md`, `docs/qa/phase11-screens.png`
  | xvfb screenshots: the timeline (Chapter 3 locked with its gate, open, all three finales won), the Chapter 3 view (crew
  and Kings, a drafted Present legend sitting), each Present challenge HUD line, the SPACE THE FLOOR banner, the era court
  in play (both views), each signature move (and the P4 animation), an unlock scene, the finale, the Hall's three rows
  and the mentor picker, the draft's three LEGENDS rows, the lineup rule line; 1280x720 and 1600x720, both hand layouts;
  the hard rule by eye on every screen, sheet and portrait (names, the look combinations of the board's table, kit
  colors against current teams); bugs filed as P11-Bn | P11-04, P11-14, P11-15, P11-16, P11-18, P11-19, P11-20
- **P11-10** (only if the owner asked for it at the Phase 10 check-in) | Rooftop's cradle dunk with its own look
  | art-audio-integrator A | `tools/art/make_players_v2.py`, `assets/players2/lg_rooftop*` and `format.json` (a
  `cradle` extra on his sheet only), `scripts/player.gd` (the `CRADLE_STYLE` line only)
  | a preview gif first for the owner; `--anim-test` ANIM OK; `--challenge rooftop` shows `anim_cradle`; nothing else
  changes | the owner's answer, P11-14 and P11-22 merged

### Wave 6
- **P11-29** | Docs
  | gameplay-programmer C | `CLAUDE.md`, `README.txt`, `CREDITS.md` (the Present art rows), `scripts/title.gd`
  (`CREDITS_LIST`), `docs/legends-plan.md` (part 3's Present table and part 4's row as shipped), `docs/release/itch_page.md`,
  `scripts/story_text.gd` (goal numbers in lines only, from P11-23's list)
  | every new key, flag, file and screen state documented; credits in step; no story line names a stale number |
  P11-23..P11-28
- **P11-30** | Final Phase 11 QA
  | qa-balance-tester | `docs/qa/phase11.md`, `docs/qa/phase11-final.png`
  | `--legends-test` on every level (three chapters), `--legends-chapter present`, `--trip-test` on every level (three-era
  legends), resume, backtest, titletest, legendtest, startest, cosmetictest, twisttest, ratingtest, anim-test (alone),
  triptest-data, 20 `--autoplay` games against the Phase 10 reference, the P11-21/24/28/29 results; a web build in
  Playwright (touch, real frame timing, not only `--fixed-fps`) through a Chapter 3 unlock, the Hall, a Present draft and
  a mentor; release-ready or bugs | P11-29
- **P11-31** | Phase summary and check-in
  | lead-producer, then the coordinator | `docs/phase11-summary.md`; publish the web build, rebuild the web ZIP and the
  debug APK | the summary with 2-4 questions; the owner plays | P11-30

## Parallel plan (never two tasks on the same file in one wave)
| Wave | Tasks (agent) | Files | Notes |
|---|---|---|---|
| 1 | P11-01 (qa), P11-02 (gameplay A), P11-03 (gameplay B), P11-04 (gameplay C), P11-05 (art A), P11-05b (art B, if P4), P11-06 (art C), P11-07 (art D), P11-08 (art E) | fixtures / namecheck doc / legends.gd, legends_data.gd test helpers / legends_tour.gd, hall.gd / make_players.py, crews.json, sample / make_players_v2.py, gif / make_courts.py, courts, court_looks.gd / make_legends_ui.py, assets/legends / audio_preview | P11-02's results and P11-05 (+ P11-05b, P11-06) go to the owner with P1-P8 |
| 2 | P11-09 (E), P11-11 (A), P11-12 (B), P11-13 (C, if P3 c), P11-14 (art A), P11-15 (art B), P11-16 (D) | legends_test.gd / legends_data.gd, namecheck doc / twists.gd, player.gd, main.gd, twist_fx.gd / challenge.gd / make_players_v2.py, crews.json, players2 / make_portraits_v2.py, portraits / story_text.gd, story.gd | P11-09 right after P11-03 is merged (no answer needed); P11-11's name check lands before P11-14 / P11-15 use the names |
| 3 | P11-17 (A), P11-18 (B), P11-19 (C), P11-20 (art E), P11-21 (qa) | player.gd, defense.gd, ball.gd / legends.gd / trip.gd, draft.gd, lineup.gd / music, make_music.sh, CREDITS.md, title.gd / docs + twists.gd numbers | P11-17 after P11-12 is merged |
| 4 | P11-22 (B), P11-23 (qa), P11-24 (C) | player.gd, main.gd, defense.gd / docs + legends_data.gd numbers / trip_test.gd | P11-22 after P11-17 is merged |
| 5 | P11-25 (C), P11-26 (qa), P11-27 (qa), P11-28 (qa), P11-10 (art A, if asked) | main.gd / docs + legends_data.gd perk numbers / docs / docs / make_players_v2.py, lg_rooftop pages, format.json, player.gd one line | P11-25 after P11-22 is merged; at most two qa tasks at once; P11-10 lands before P11-28 shoots the moves |
| 6 | P11-29 (C), then P11-30 (qa), then P11-31 (lead, coordinator) | docs, title.gd, story_text.gd numbers / docs / docs | |

Chains to watch: `legends_data.gd` by P11-03 (test helpers, wave 1), P11-11 (rows, 2), then numbers only by P11-23 (4)
and P11-26 (5); `legends.gd` by P11-03 then P11-18; `player.gd` by P11-12, P11-17, P11-22, P11-10 (each merged before the
next); `defense.gd` by P11-17 then P11-22; `main.gd` by P11-12, P11-22, P11-25; `make_players_v2.py` by P11-05b, P11-14,
P11-10; `crews.json` by P11-05 then P11-14; `CREDITS.md` and `title.gd` by P11-20 then P11-29; `story_text.gd` by P11-16
then numbers only in P11-29; `docs/legends-namecheck.md` by P11-02 then P11-11.

## Open questions for the owner
P1-P8 in `docs/legends-plan.md` "Phase 11 open questions" (each says which tasks it blocks). The era music pick comes
from P11-08's list during the build; jersey numbers, the court's name and the look sample go to the owner's look check
(P11-02, P11-05, P11-06). Still open from the Phase 10 check-in: Rooftop's cradle dunk (keep the windmill, or its own
look: P11-10).
