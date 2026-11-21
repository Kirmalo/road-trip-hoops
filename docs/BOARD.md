# Task Board

Current phase: **Phase 10: Legends, Chapter 2 (the Fathers)** (planned 2026-11-21 by `lead-producer`; VISION "Phase 10
start": "Go on to the next"). The Phase 9 board is archived in `docs/board-phase9.md` (Phase 8: `docs/board-phase8.md`,
Phase 7: `docs/board-phase7.md`, Phase 6: `docs/board-phase6.md`, Phase 5: `docs/board-phase5.md`, Phase 4:
`docs/board-phase4.md`, Phase 3: `docs/board-phase3.md`, Phase 2: `docs/board-phase2.md`, Phase 1: `docs/board-phase1.md`).

**STATUS: PLANNED, not started. Wave 1 needs no owner answer (except P10-04b, only built if F4 says so). Waves 2+ wait
for the owner's answers to F1-F8 (`docs/legends-plan.md` "Phase 10 open questions") and the era look check (P10-04).**

Scope: a shippable Chapter 2 end to end, on the Phase 9 machinery (everything is data in `legends_data.gd` `CHAPTERS` /
`LEGENDS` / `PERKS`, so Chapter 2 is mostly data, art, story and one era twist):
1. **Six original Fathers legends** (`docs/legends-plan.md` part 3: the 2000s look, baggy shorts, arm sleeves, cornrows;
   isolation scorers and high flyers): data, the name check (extended to the 2000s era), sheets in the approved style
   with new era parts, portraits, unlock stories, joining lines, jersey numbers the owner approves.
2. **Their six challenges** on the Phase 9 goal types (hold / fire / stop / race / comeback), plus at most one cheap new
   type if the owner wants it (F3), and **the Fathers finale** to 21.
3. **The era rules**: one twist, `era_fathers` "ISO BALL" (F2). **The era court**: `era_fathers`, a blacktop under
   lights. **The era music**: a listening list, the owner picks (CC0 / CC-BY).
4. **The gate**: 36 stars or 12 tokens (already data; F7 asks whether Chapter 1's finale is also needed). The timeline,
   chapter view and Hall show two playable chapters.
5. **Mentors**: one perk per Fathers legend, about 2 stat points each (F5). **Draft**: unlocked Fathers join the Road
   Trip draft; the one-legend rule stays (one legend from any chapter + one boss may start).
6. **Signature moves**: a small play edge each on existing animations; a new animation only if the owner picks one
   (F4).
7. **Carry-overs**: the Velvet challenge watch item (re-measure, tune if still off, P10-08), P9-B7 (wide-screen art bars
   on the tour, P10-03), the P9-33 leftovers (credits rows, the How to Play line, P10-10), the story lines and docs that
   still show Chapter 1's pre-P9-26 goal numbers (P10-29).
8. **Not in Phase 10** unless F8 adds it: era teams and single legends in Quick Game, one-on-one, Legends cosmetics and
   the token ladder, Chapters 3-4 (they stay `built: false` pins).

## Rules for every task in this phase
- **The hard rule (`docs/legends-plan.md` part 1): every legend is our own character.** No real player's name or
  nickname, face or likeness, number in a team's colors, signature accessory, trademark, slogan, team, arena or league.
  The 2000s are the era most players remember, so the risk is higher than in Chapter 1: **no legend may carry a
  combination of look, build, number and move that points at one real player** (e.g. the small quick crossover guard
  with cornrows, a single arm sleeve and a headband is one famous real player's look: sleeves and braids are era parts
  spread over several legends, never that whole set on one). Move names are plain basketball words ("crossover",
  "fadeaway", "chase-down block"). The owner's reference picture is never an asset or an input to a script. Review
  rejects any change that breaks it, the same way it rejects an asset without a license.
- **Chapter 1 and the rest of the game play exactly as in Phase 9.** No game-sim change outside P10-12 (ISO BALL),
  P10-13 (the new goal type, only if F3 a), P10-17 (signature moves) and P10-22 (mentor perks). Every new hook is a
  default that is exactly today's game: with twist `none` / `era_grand`, no Fathers legend on the court and no new perk,
  `--autoplay` and the Chapter 1 `--challenge` runs match `docs/qa/phase9.md` / `phase9-challenges.md`.
- **Every chapter is data.** No `"fathers"` (or `"grand"`) string in game logic outside `legends_data.gd`, the art
  lookups keyed by chapter id (frames, pins) and the tests; a third chapter must later be data, art and story only.
- Tuning constants at the top of the script they belong to (the ISO BALL values in `twists.gd`, the signature numbers in
  `player.gd` / `defense.gd`, the challenge numbers, per-chapter rating keys and perk sizes in `legends_data.gd`).
- Godot 4.3, no `:=` with untyped right sides, no new `.tscn`, touch first (joystick + A + B in every game; the menus are
  big tap targets, Escape = BACK on desktop, the Android back goes BACK), 1280x720 and wider screens.
- Saves stay compatible: **`legends.json` version 1** (new legends are just new keys: `"lg:<id>"`, `"fin:fathers"`, ids
  in `unlocked` / `seen` / `mentors`), **`trip.json` version 2** (a drafted Father is a `via: "draft"` entry with an `lg_`
  id). A Phase 9 build opening Phase 10 files must not crash (unknown ids ignored or dropped, P10-27).
- Test runs never touch the owner's files: `user://legends_test.json`, `user://trip_test.json`, `user://settings_test.cfg`.
- Art: generated by the `tools/art` scripts in the approved style (style sample v1, the approved animation sample,
  comic portraits v2, the approved legend look sample v1 for build and finish), never drawn by hand, downloaded or traced;
  rerun the generator and commit its output. Music: CC0 or CC-BY only, a row in `CREDITS.md` and `CREDITS_LIST`.

## Process rule (worked in Phase 9, keep it)
- **At most 2 Godot processes per agent** at a time (the 4 cores are shared with the other agents).
- **Every test run in its own `XDG_DATA_HOME`** (and, for a scratch project copy, its own `config/name`), so no run sees
  another's `user://` files. Runs that must share files (`--triptest-data` then `--load`; `--trip-stop-after` then
  `--trip-resume`; `--trip-test` then `--challenge` with its trip save) share one name and one data folder, nothing else.
- **Scratch folders outside the repo** (the agent's scratchpad or `/tmp/<task>/`): project copies for candidate numbers,
  logs, screenshots. Only the task's own files are committed.
- QA reports give the build commit, the flags, the game count per cell and the standard error; a 20-game cell cannot
  see a 3-point change (`docs/qa/phase9-challenges.md`).

## Shared contract (names fixed now so parallel tasks can call each other)

### Chapter 2 data (`scripts/legends_data.gd`)
- The `fathers` row becomes `"built": true` (P10-11) with: `"rules": "ISO BALL"`, `"twist": "era_fathers"`, `"look":
  "era_fathers"`, `"music": "legends_fathers"`, `"fallback_music"` (an existing city track until the pick, P10-20),
  `"gate": {"stars": 36, "tokens": 12}` (F7 may add a finale rule), `"crew"` (`"THE FATHERS"`, a `ratings.gd` style,
  the era palettes from P10-04, `ui_color`), `"legends"` (6 ids), `"finale"` (target 21, 3 ids, `"FATHERS FINALE"`),
  `"intro_scene": "legends_fathers_intro"`, `"finale_scenes": {"before": "legends_fathers_finale_before", "after":
  "legends_fathers_finale_after"}`.
- **Optional per-chapter rating keys (P10-02)** in a `CHAPTERS` row: `"challenge_avg"`, `"mate_drop"`,
  `"finale_stage_avg"`; a row without them uses today's constants (`CHALLENGE_AVG` 66, `MATE_DROP` 14,
  `FINALE_STAGE_AVG` 52, 55 after P10-23), so Chapter 1 is unchanged. The Fathers row sets them only if F6 asks for a
  step (it does: 69 / 14 / 56).
- Legend ids `lg_<nickname>` in lower case with `_` (the F1 answer fixes them; the plan's draft: `lg_rooftop`,
  `lg_ankles`, `lg_midrange`, `lg_freight`, `lg_eyes_closed`, `lg_lockbox`). Each row has every Chapter 1 key (`name`,
  `full`, `first`, `last`, `chapter: "fathers"`, `archetype`, `role`, `tier: "legend"`, `sheet`, `portrait`, `number`,
  `shape` (sum 0), `spec`, `steal_bias`, `block_bias`, `signature`, `challenge` (its `mates`: 2 other Fathers), `perk`,
  `colors`, `look`, `bio`, `unlock_scene: "lg_<id>_unlock"`).
- New goal type (only if F3 a): `"score"` in `CHALLENGE_TYPES`, row key `"min"`: **you** (the human, `Trip.human`)
  score at least `min` points yourself and your team wins; HUD "SCORE 6 ON LOCKBOX: 2"; checked at the end like `stop`.
- New perks (F5 a; ids and keys distinct from Chapter 1's and from the twist keys): `"rise_up"` (`contested_dunk_bonus`
  +0.015, 0.025 after P10-26), `"handle"` (`cross_win_mult` 1.05, 1.15 after P10-26), `"pull_up"` (`mid_shot_bonus` +0.015), `"strong_hold"`
  (`strip_guard_mult` 0.95: steal chance on him), `"blind_pass"` (`pass_safe_mult` 0.95, 0.85 after P10-26: interception
  chance on his passes), `"quick_hands"` (`steal_window_mult` 1.05). Defaults: 1.0 for `_mult`, 0.0 for `_bonus`.
- Signature ids (F4 a): `cradle`, `double_cross`, `fadeaway`, `shoulder`, `no_look`, `chase_down` (one per legend; the
  `text` in plain words for the Hall).

### ISO BALL (`scripts/twists.gd`, F2)
- Twist `era_fathers`: `"name": "ISO BALL"`, a banner line, `"icon": "era_fathers"`. Keys (F2 a; values are starting
  points, P10-21 tunes): `cross_beat_mult` (a crossover beats the defender this much more often, CPU and human
  defenders alike), `dunk_range_mult` (dunk range x this), `arc_mult` 1.05 (existing, drawing only). F2 b adds
  `help_mult` (the off-ball help lean x this); F2 c `mid_mult` (jumpers inside the arc). Each in `DEFAULTS` at today's
  value (1.0), read once through `Twists.value(key, default)`, no team read.

### Art and audio files
- Sheets `assets/players2/lg_<id>_p<N>.png`, palettes `lg_<id>`, `_crew`, `_crew_j1..3`, cards; strip
  `docs/art/legends_fathers.png`. Era palettes `ERA2_*` in `tools/art/crews.json` (P10-04). The `hook` extra stays on
  the Chapter 1 sheets only (technical choice: the Fathers don't use it; saves a few pages each) unless F4 adds an extra.
- Portraits `assets/portraits/lg_<id>.png` and `_happy`; contact sheet `docs/art/legends_fathers_portraits.png`.
- Court `assets/courts/era_fathers_floor.png`, `era_fathers_backdrop.png`; `court_looks.gd` row `"era_fathers"` (no
  twist key, no reward, never in the Quick Game COURT list, like `era_grand`); it must not read as the MIDNIGHT reward
  look (a different palette and props: light poles and their pools of light, a chain fence, painted lines).
- Legends UI `assets/legends/frame_fathers.png`, `pin_fathers.png`, `pin_fathers_done.png` (the locked pin exists),
  listed in `assets/legends/ui.json` under `frames.fathers` and `pins` (P10-06; P10-03 reads them, a missing one falls
  back to the `grand` art).
- Music `assets/music/legends_fathers.ogg` (P10-20, the owner's pick from P10-07).

### Story (`scripts/story_text.gd`)
- Scenes `legends_fathers_intro`, `lg_<id>_unlock` x 6, `legends_fathers_finale_before`, `legends_fathers_finale_after`;
  `RECRUIT_LINES` for the six (the draft's joining line). Lines that name a goal number use the numbers in
  `legends_data.gd` at the time; P10-23 lists any line its tuning makes stale, P10-29 fixes it.

## Owner answers already in (VISION)
"Legends plan answers" (6 per era, gates 36 / 48 / 72 stars or tokens, a mix of goals, one legend + one boss may start,
small perks), "Phase 9 answers L1-L8" (challenges with your Road Trip crew, the Kings without a trip; boss-level
drafted legends; mentors for regular players only, Road Trip games only), "Mentor perk size" (shot perks +1.5%, others
5%), "Phase 10 start". Phase 9's technical choices (the level picked on the chapter view, a drafted legend sits when he
is an opponent) apply to Chapter 2 unchanged.

## Todo
Everything below (Tasks by wave).

## Doing

## Review

## Done

## Tasks by wave

### Wave 1 (no owner answer needed; P10-04b only if F4 picks an animation)
- **P10-01** | Phase 9 save fixtures
  | qa-balance-tester | `docs/qa/fixtures/` (new files only): `legends_v1_mid.json` (3 Grandfathers beaten, tokens on
  two levels, one mentor), `legends_v1_ch1_done.json` (Chapter 1 closed, 21 tokens), `trip_v2_legend.json` (a trip with
  a drafted Grandfather starting next to a boss, a mentored player), `settings_v2_36.cfg` (36 stars); README lines on
  how each was made
  | each made by the Phase 9 build (`a1dc3c7`) through `--legends-test` / `--trip-test` stops, loads and plays in that
  build, committed | none
- **P10-02** | Multi-chapter readiness in the Legends logic
  | gameplay-programmer A | `scripts/legends.gd`, `scripts/legends_data.gd` (helpers only, no rows)
  | the per-chapter rating keys of the contract (defaults = today's constants: every Chapter 1 match is byte for byte the
  same `Flow.match`); no `"grand"` or "first built chapter" assumption left in game logic (`test_match()` takes
  `fathers` / `fin:fathers`; `max_tokens()`, `chapter_tokens()`, `after_result()` and the finale's "chapter done" work
  for any built chapter); `self_test()` adds a case with two built chapters (a test-only data hook, never the shipped
  rows); `--legendtest` LEGENDTEST OK | none
- **P10-03** | Tour and Hall for several chapters, P9-B7
  | gameplay-programmer B | `scripts/legends_tour.gd`, `scripts/hall.gd`
  | frames, pins and colors per chapter from `assets/legends/ui.json` and the chapter row (missing art = the `grand`
  art); the timeline with 2 open chapters (each PLAY, LOCKED with its gate or FINALE WON), the chapter view and the
  Hall row for any built chapter; the mentor picker lists the legends of every built chapter; P9-B7 fixed (at 1600x720
  the backdrop reaches the screen edges, the buttons stay in the 1280 box); with today's data every screen looks as in
  Phase 9 (screenshots before / after in the report); `--legends-test`, `--backtest` unchanged | none
- **P10-04** | Fathers era parts and a look sample
  | art-audio-integrator A | `tools/art/make_players.py` (era parts in "Phase 10 era parts", `--legends-sample fathers`),
  `tools/art/crews.json` (`ERA2_*` palettes and part docs only), `docs/art/legends_fathers_sample_v1.png` / `.gif` (new)
  | parts drawn once for the era: baggy knee-length shorts, an arm sleeve (left or right), a shooting sleeve on the leg,
  wristbands, a durag, braids / cornrows if the existing ones don't read, a goatee, crew socks; a sample of two era
  looks (run, running dribble, a dunk, idle card) in the approved style for the **owner's look check**; no sample look
  matches one real player (the hard rule's combination check, written in the report); nothing in `assets/` changes;
  `--anim-test` ANIM OK | none
- **P10-04b** (only if F4 b, c or d) | The new animation and its preview
  | art-audio-integrator B | `tools/art/make_players_v2.py` (the new `EXTRA` row, carried only by the sheets that use
  it), `docs/art/<move>_v1.gif` (new: 5 directions next to the move it replaces)
  | ball and hand points for every frame; goes to the owner's look check with P10-04; nothing in `assets/` committed |
  F4
- **P10-05** | The Fathers court: a blacktop under lights
  | art-audio-integrator C | `tools/art/make_courts.py` (`--era fathers`), `assets/courts/era_fathers_floor.png`,
  `era_fathers_backdrop.png`, `scripts/court_looks.gd` (one row)
  | a made-up night playground (no real team, arena, league or brand), light poles, a fence, a city skyline that is no
  real city's; clearly not the MIDNIGHT look; players and the ball readable under it (screenshot with `--court
  era_fathers`, both views); not in the COURT list | none
- **P10-06** | Legends UI art for Chapter 2
  | art-audio-integrator D | `tools/art/make_legends_ui.py`, `assets/legends/` (`frame_fathers.png`, `pin_fathers.png`,
  `pin_fathers_done.png`, `ui.json`), `docs/art/legends_ui.png`
  | the Fathers card frame and pins in the approved style, era colors of P10-04's palettes (a first guess until the look
  check; rerun after it if they change); Chapter 1's files byte for byte unchanged | none
- **P10-07** | Era music listening list
  | art-audio-integrator E | `docs/audio_preview/LIST.md` ("Legends: Fathers"), `docs/audio_preview/fathers_*.ogg`
  | 3-5 upbeat chiptune tracks with a 2000s streetball feel (boom-bap, funk, R&B grooves, not New York's track), CC0 or
  CC-BY only, each license link checked; the owner picks one during the build | none
- **P10-08** | QA: the Velvet watch item
  | qa-balance-tester | `docs/qa/phase10-velvet.md` (new); candidate numbers only in a scratch copy
  | Velvet's challenge on Normal and Hard, expected and best end-of-trip crews, 40+ games per cell (P9-34 saw Normal 45%
  under Hard 60%); if Normal is still below Hard or outside the P9-26 band, a candidate `limit` (or `target`) measured
  the same way; the number goes into P10-11 (this task commits no code) | none
- **P10-09** | Legends test driver: every built chapter
  | gameplay-programmer C | `scripts/legends_test.gd`
  | `--legends-test` plays each built chapter in data order (its intro, 6 challenges, finale, the next chapter's gate
  checked: open by stars or tokens as the data says); `--legends-chapter <id>` plays only that one (gate forced open for
  the run, nothing saved); the forced loss / broken goal retries apply per chapter; on today's data the output is the
  Phase 9 run plus one line; LEGENDS END on every level | none
- **P10-10** | DONE (coordinator, 86b4882: CREDITS rows, CREDITS_LIST, How to Play line) | Credits catch-up (P9-33 leftovers)
  | gameplay-programmer D | `CREDITS.md`, `scripts/title.gd` (`CREDITS_LIST`), `scripts/howto.gd` (one trip-page line)
  | the Phase 9 art rows (legend sheets, portraits, OLD GYM, Legends UI: generated, our own) and the How to Play line on
  legends in the draft; `CREDITS.md` and `CREDITS_LIST` in step; `--titletest` passes | none

### Wave 2 (needs F1-F7 and the look check)
- **P10-11** | Chapter 2 data and the name check
  | gameplay-programmer A | `scripts/legends_data.gd`, `docs/legends-namecheck.md`
  | **first** the name check: the lists extended with the 2000s-era players and nicknames (the doc says the source),
  `NUMBER_AVOID` reviewed for the era, the six F1 names checked (the Phase 9 doc already flags Vance and Ridley), any
  flag shown to the owner before the art uses the name; then the contract's `fathers` row and six `LEGENDS` rows (F1),
  their challenges and the finale (F3), the per-chapter rating keys (F6), the six `PERKS` rows (F5, data only), the
  Velvet number from P10-08 if it changed; `--legendtest` LEGENDTEST OK (name check included) | P10-02, F1, F3, F5, F6
- **P10-12** | The ISO BALL era rules
  | gameplay-programmer B | `scripts/twists.gd`, `scripts/player.gd` (the crossover and dunk-range hooks),
  `scripts/defense.gd` (the help hook, F2 b only), `scripts/twist_fx.gd` (banner icon), `scripts/main.gd` (F2 c only:
  `mid_mult` in `shot_probability()`)
  | per F2: each key one `Twists.value(key, default)`, default = today; `--twisttest` TWISTTEST OK; `--twist
  era_fathers --autoplay` a sane game; banner and pause line read; twist `none` and `era_grand` unchanged | F2
- **P10-13** (only if F3 a) | The `score` goal type
  | gameplay-programmer C | `scripts/challenge.gd`
  | the contract's `score` type: HUD line and count, met / failed at the end with a reason ("YOU SCORED 4 OF 6"), the
  existing five types unchanged; `--challenge` on a fake row in a scratch copy shows met and failed | F3
- **P10-14** | The six Fathers sheets
  | art-audio-integrator A | `tools/art/make_players_v2.py`, `tools/art/crews.json`, `assets/players2/` (pages,
  palettes, `palettes.json`, cards, `format.json` only if F4 adds an extra)
  | 6 `lg_` sheets in the approved style with the approved era parts and their own era kits, `_crew` and `_crew_j1..3`;
  the hook pages stay on the Chapter 1 sheets only (their files unchanged); the F4 extra on its sheets if picked;
  `--anim-test` ANIM OK on every sheet; strip `docs/art/legends_fathers.png`; download growth reported | P10-04 approved
  (and P10-04b if F4 b-d), P10-11's name check (ids)
- **P10-15** | The Fathers portraits
  | art-audio-integrator B | `tools/art/make_portraits_v2.py` (`--legends fathers`), `assets/portraits/lg_*.png`,
  `docs/art/legends_fathers_portraits.png`
  | neutral and happy for each, comic style v2, original faces from the kit's parts, kits matching P10-14's; no likeness |
  F1, P10-11's name check, P10-04 approved
- **P10-16** | Chapter 2 story
  | gameplay-programmer D | `scripts/story_text.gd`, `scripts/story.gd` (only if a lookup needs it)
  | the intro, 6 unlock scenes, the finale's before and after, 6 joining lines; light comedy with heart, the Fathers as
  the Grandfathers' "kids" grown up (theme only, no real families), no real people, quotes, slogans or trademarked move
  names; goal numbers as in the data; every scene the data names exists (`--legendtest`) | F1, F3, P10-11

### Wave 3
- **P10-17** | Signature moves
  | gameplay-programmer A | `scripts/player.gd`, `scripts/defense.gd`, `scripts/ball.gd` (only what the moves need)
  | per F4: each edge works only for the legend whose `signature` it is (constants at the top, `sig_log()` lines and
  `sig_<id>_t<team>` counts); the F4 extra played when `Sheets.has_anim()` says so; without a Fathers legend on the court
  nothing changes (`--autoplay` stats, a Chapter 1 `--challenge` pass); each move seen in a `--challenge` run | P10-12
  merged (player.gd, defense.gd), P10-11, P10-14 (F4 extra)
- **P10-18** | Chapter flow and the gate
  | gameplay-programmer B | `scripts/legends.gd`
  | the F7 gate rule; Chapter 2's intro on its first open; its finale closes it; the tour returns to the right chapter
  view after a Chapter 2 game, unlock or finale; drafted Fathers sit when they are opponents, like Chapter 1;
  `Legends.self_test()` covers both shipped chapters (gates, tokens per chapter, unlocks, mentors from both eras, the
  test trip save unchanged) | P10-11, F7
- **P10-19** | Draft and lineup with two eras
  | gameplay-programmer C | `scripts/trip.gd`, `scripts/draft.gd`, `scripts/lineup.gd`
  | one LEGENDS row per chapter in the draft ("UNLOCKED IN LEGENDS - THE FATHERS", that chapter's frame and tag color;
  technical choice, shown at the check-in); `LEGEND_LIMIT` 1 across all chapters; legend + boss still allowed; the
  stale P9-30 comments in `trip.gd` fixed; save version 2; every fixture loads; `--triptest-data` (+ `--load`) TRIPDATA
  OK | P10-11, P10-06
- **P10-20** | DONE (art-audio-integrator E: `assets/music/legends_fathers.ogg`, "Headspin" by congusbongus, CC0,
  license re-read on the page; loop 76.34-173.75 s (97.41 s, 32 bars), 40 ms crossfade in a near-silent gap, mono,
  -20.1 LUFS, true peak -4.3 dBFS, 913 KB; seam within 0.3 dB on the 20 ms envelope; CREDITS.md row and
  `CREDITS_LIST` entry; `fallback_music` `newyork` kept as the missing-file guard; `--legendtest` OK without the
  NOTE, `--titletest` DONE, `--challenge rooftop` plays music `legends_fathers`; the previews stay, as Phase 9's did)
  | Era music in the game
  | art-audio-integrator E | `assets/music/legends_fathers.ogg`, `tools/make_music.sh`, `CREDITS.md` (one row)
  | the owner's pick, processed to the game loudness, credited (CC-BY rows: title, author, license link, source,
  changes) | P10-07 and the owner's pick, P10-10 merged (CREDITS.md)
- **P10-21** | QA: the ISO BALL era rules
  | qa-balance-tester | `docs/qa/phase10-era.md`; may tune the `era_fathers` numbers in `scripts/twists.gd`
  | 64+ `--autoplay --twist era_fathers` games against 64 twist `none` (and 40 with `--court era_fathers`): each rule
  noticeable (crossover beats, dunk range, help if F2 b, mid makes if F2 c), length, shots, FG%, fouls, rebounds inside
  the CLAUDE.md bands or explained; the share by crew style (inside vs outside crews; the Phase 9 lesson: an era can
  favour one style); twist `none` and `era_grand` match Phase 9 | P10-12

### Wave 4
- **P10-22** | Mentor perks for the Fathers
  | gameplay-programmer B | `scripts/player.gd`, `scripts/main.gd`, `scripts/defense.gd` (one hook per new perk key)
  | each key one `p.perk(key, default)`, default = today; your side only, Road Trip games only; `--perk <id>` shows each
  working (PERK line, `perk_<id>_t0`); `--autoplay` unchanged with no perk; the Hall's perk text from the data | P10-17
  merged, P10-11, F5
- **P10-23** | DONE (`docs/qa/phase10-challenges.md`: fathers 69 / 14 / 56, Eyes Closed 0-1, Lockbox min 3 (owner: 6 kept, Chapter 1 `FINALE_STAGE_AVG` 52 -> 55; VISION "Phase 10 tuning"); expected crew Easy 64%, Normal 63%, Hard 44%; stale story lines listed for P10-29) | QA: Chapter 2 challenge balance
  | qa-balance-tester | `docs/qa/phase10-challenges.md`; may tune the Chapter 2 goal numbers and its per-chapter rating
  keys in `scripts/legends_data.gd`
  | `--challenge <id> --autoplay` with `--expected-roster` / `--best-roster` on every Father and the finale, Easy / Normal
  / Hard (40+ games a cell where near a band) and LEGEND; bands: P9-26's, shifted as F6 says; harder level = lower
  share; each goal type met and failed in the logs; the Kings fallback and a mid-trip crew (36-star stage) reported;
  Chapter 1 re-run on Normal and Hard (expected crew) to show no change; any story line made stale is listed for P10-29 |
  P10-17, P10-18, P10-21 tuned, P10-13 (F3 a)
- **P10-N2** | DONE (P10-23: Quarterback did not confirm on 40 games, Normal 52.5% / Hard 35%, `start_score` stays [0, 2]; Boxcar Easy 70% on 40; Chapter 1 finale Hard 62.5% on 40, pooled with P9-26 and P10-08 50% of 80: watch item, no change; Chapter 1 expected crew no measurable change) | (for P10-23, from P10-08 `docs/qa/phase10-velvet.md`) | Velvet stays at limit 6 (Normal 75%, Hard 57.5% on 40 games): watch item closed. New Chapter 1 low spot: Quarterback comeback Normal 30% / Hard 15% (20 games each); if 40 games confirm, `start_score` [0, 2] -> [0, 1]. Also re-check Boxcar Easy (52.5%) and the Chapter 1 finale on Hard (30%) on 40 games |
- **P10-N1** | DONE (P10-23, coordinator's rule: in a `--challenge` run the best crew's legend comes only from the chapters up to the challenge's own, never an opponent; `end_of_trip_crew()` `_sim_chapters`, test path only; Chapter 1 best re-measured: Normal 65%, Hard 72%, as P9-26) | (for P10-19 / P10-23, `scripts/trip.gd`) | With the fathers row built, `Trip.end_of_trip_crew(true)` / `--best-roster` count every built legend as draftable, so Chapter 1 `--challenge --best-roster` runs now pick a Father (e.g. `lg_eyes_closed`) and no longer match docs/qa/phase9-*.md. Decide the rule (a chapter-1 run uses only legends that can be unlocked by then, or any) and re-measure (P11-found by P10-11) |
- **P10-B2** | FIXED (hall.gd `known_mentor()` / `tile_status()`: a mentor id `LegendsData.is_legend_id()` doesn't know reads as "NO MENTOR" on the tile and in the confirm; the pair stays in the file; the picker prints `HALL picker tiles | <id>: <label>, ...`; checked with `--backtest` on a legends_test.json with `lg_future -> ud_jojo`: "ud_jojo: NO MENTOR", file byte for byte) | (from P10-27, `scripts/hall.gd`, low, cosmetic) | The mentor picker labels a player whose mentor this build doesn't know (a newer build's legends.json, e.g. `"mentors": {"lg_future": "ud_jojo"}`) "TRAINED BY LG_FUTURE": `legend_name(id)` falls back to the raw id (the pair already gives no perk; the Phase 9 build does the same with Phase 10 files: "TRAINED BY LG_ANKLES"). Fix: when `LegendsData.is_legend_id(mentor)` is false show the tile as "NO MENTOR" (or "TRAINED BY A LEGEND"), keep the pair in the file. `docs/qa/phase10-saves.md` |
- **P10-B3** | FIXED (trip_test.gd `_save_you`: a `--trip-resume` save whose `human` is a drafted legend plays him ("TRIP game N: you play the legend ..., the resumed save's pick") until the driver picks a lineup itself; the check still fails on a driver's own pick; a resumed legend-YOU save with a replay marker: TRIP END, the old driver: TRIP ERROR) | (from P10-27, `scripts/trip_test.gd`, low, test only) | `--trip-test --trip-resume` of a legal save whose `human` is a drafted legend (the lineup allows it; it plays in a real-name run) ends at the first game with "TRIP ERROR: the driver made a legend YOU": the check on `mine[0]` is meant for the driver's own picks but the lineup came from the save. Fix: fail only when the driver picked that lineup itself, or on resume repick YOU to the first non-legend starter. `docs/qa/phase10-saves.md` |
- **P10-B4** | FIXED (challenge.gd `possessive()`: "GATE'S", "ANKLES'"; the race HUD line "REACH 11 BEFORE ANKLES' CREW GETS 10" and the loss reason "ANKLES' CREW GOT 10", seen in `--autoplay --challenge ankles` and on screen at 1280 and 1600) | (from P10-28, `scripts/challenge.gd`, low, cosmetic) | The race goal's HUD line and its failure reason say "REACH 11 BEFORE ANKLES'S CREW GETS 10" / "ANKLES'S CREW GOT 10" (lines 158 and 239 build `"%s'S CREW"`); the data line says "ANKLES' CREW". Fix: a possessive helper (`name + "'"` when the name ends in S, else `name + "'S"`) on both lines. `docs/qa/phase10-screens.md` |
- **P10-B5** | FIXED (draft.gd: the role line uses the card width inside the border (`ROLE_PAD` 5) and shrinks down to `ROLE_MIN_FONT` 10; hall.gd: the archetype goes through `_fit_font()` down to `DETAIL_ARCH_MIN` 12; data unchanged; Rooftop and Freight whole on the draft cards and in the Hall at 1280 and 1600) | (from P10-28, `scripts/draft.gd`, `scripts/hall.gd` or `scripts/legends_data.gd`, medium-low, cosmetic) | Long archetypes are cut: draft cards "HIGH-FLYING SHOOTING GUA", "LOW-POST BULLDOZER CENT"; Hall detail "HIGH-FLYING SHOOTING GUAF", "LOW-POST BULLDOZER CENTE" (1280 and 1600). Fix: shrink the role / archetype label to its width (`hall.gd` has `_fit_font()`; the same for the draft card's role label), or shorter archetypes for Rooftop and Freight ("HIGH-FLYING GUARD", "BULLDOZER CENTER"). `docs/qa/phase10-screens.md` |
- **P10-B6** | FIXED (hall.gd `_detail_open()`: MENTOR PERK goes under the signature text's measured height (`_wrapped_height()`, at least `PERK_Y`); a text that would push the perk block into the TRAINS strip shrinks down to `SIG_TEXT_MIN` 14: Rooftop's is now 2 lines, the other 11 as before; legends_data.gd unchanged) | (from P10-28, `scripts/legends_data.gd` / `scripts/hall.gd`, medium-low) | In the Hall, Rooftop's signature text takes 3 lines and the third ("contest") is drawn over the MENTOR PERK heading (1280 and 1600; the other 11 take 2). Fix: shorten the text (e.g. "Cradle dunk: his dunks slip past part of a contest") and/or place the perk block under the measured text height in `_detail_open()`. `docs/qa/phase10-screens.md` |
- **P10-B7** | FIXED (coordinator: one `_hud_node.queue_redraw()` when the banner hides) | (from P10-30, `scripts/twist_fx.gd`, medium-low, cosmetic; since P6) | After the twist banner slides out, its right end (up to ~90 px at 60 fps, more at lower frame rates) stays stuck at the left edge under the top bar / goal line ("...her out") until the next banner at the side switch, and again after it. Seen in every web game with a twist (every Legends game) and natively without `--fixed-fps` (frames 900 and 1800); `--fixed-fps 60` hides it. Cause: `_process()` sets `_banner_t = -1.0` past `BANNER_TIME` and then queues no redraw (`if _banner_t >= 0.0 or kind == "wind"`), so the HUD node keeps its last, almost-gone drawing. Fix: one more `_hud_node.queue_redraw()` on the frame the banner hides (e.g. inside `if _banner_t > BANNER_TIME:`). `docs/qa/phase10.md` |
- **P10-B1** | FIXED (P10-24, 79d69a3) | (for P10-24, `scripts/trip_test.gd`, low, test only) | A resumed trip with an open slot and a legend in the pool runs the tap pick test and the first draft on the same lineup visit: `_draft_test()` snapshots `Trip.starters` before the lineup saves its tapped picks, so `_check_draft()` reports changed starters (TRIP ERROR) though the draft worked. Fix: snapshot after the picks are saved, or skip the pick test on the drafting visit. Until then resume the P10-01 fixtures with `--stars 24` (docs/qa/fixtures/README.md) |
- **P10-24** | Trip test: a drafted Father
  | gameplay-programmer C | `scripts/trip_test.gd`
  | with `--legends-unlock-all --stars 24`: the first slot drafts a Grandfather, the second a Father (from his chapter's
  row), the lineup refuses the two legends together and accepts one + a boss; TRIP END on every level; `--trip-resume`
  works | P10-19

### Wave 5
- **P10-25** | DONE (gameplay-programmer, `--backtest` steps 32-45: Chapter 2 view, Hall on a Fathers plaque (back to the chapter view and to CREW, the mentor picker), a Fathers challenge pause, resume and QUIT; BACKTEST OK as before, with `--stars 36` and `--tokens 12`; `--titletest` OK, also `--stars 36 --legends-unlock-all`) | Back test and title test for Chapter 2
  | gameplay-programmer C | `scripts/main.gd` (the `--backtest` table only)
  | the Chapter 2 view goes to the timeline, a Chapter 2 challenge pauses, resumes and QUITs to its chapter view, the
  Hall from a Chapter 2 plaque goes back; BACKTEST OK; `--titletest` passes | P10-22 merged (main.gd), P10-18, P10-03
- **P10-26** | DONE (qa-balance-tester, `docs/qa/phase10-ramp.md` at 1c7ff3b: 872 games, `--best-roster --perk -,quick_pass,quick_hands` (Eyes Closed + boss in New York, Quarterback + boss in Seattle / LA): Hard RED 46% pooled (200; cells 52 / 55 / 55 / 20 / 50%, NY SF on the line, a watch item), Easy 7 / Normal 26 / LEGEND 57%; perks vs "2 stat points" (about 0.05 points a game a player): pull_up, strong_hold, quick_hands about 1x as they were, rise_up 0.015 -> 0.025, handle 1.05 -> 1.15, blind_pass 0.95 -> 0.85 (each was 0.2-0.55x; now about 1x; owner to confirm against F5 a); LEGENDTEST OK; 0 errors) | QA: the ramp with Fathers and their perks
  | qa-balance-tester | `docs/qa/phase10-ramp.md`; may tune the Fathers perk sizes in `scripts/legends_data.gd`
  | `--best-roster` with the strongest legal three (a Father or a Grandfather + a boss) plus the best perk of either
  chapter (`--perk`), late boss games and New York on every level, 40+ games a cell: on Hard RED still wins 20%+ (the
  P8-25 bound); each new perk worth about 2 stat points (measured, like P9-30) | P10-22, P10-19
- **P10-27** | DONE (qa-balance-tester, `docs/qa/phase10-saves.md` at 7e38b7a: all 9 old fixtures (1.0.0, Phase 8, P10-01) to TRIP END in Phase 10, `check_fixtures_v2` / `_v3` OK; the Phase 10 files in `a1dc3c7`: no error dialog, the drafted Father dropped, his tokens and mentor pairs ignored, TRIP END with `--stars 24`; reopened in Phase 10 every Legends key survived, only the drafted Father is lost; 7 broken / newer legends.json variants no crash; NEW TRIP keeps legends.json; no test touched the real files; bugs P10-B2, P10-B3, both low) | QA: saves
  | qa-balance-tester | `docs/qa/phase10-saves.md`
  | every 1.0.0, Phase 8 and P10-01 fixture loads and plays on in Phase 10; a Phase 10 `legends.json` (Fathers unlocked,
  their tokens, a Fathers mentor) and a trip with a drafted Father, opened by the Phase 9 build (`a1dc3c7`): no error
  dialog, the unknown legend dropped from the trip, his tokens not counted, his mentor pair ignored, plays on; missing,
  broken, newer `legends.json`: no crash; NEW TRIP keeps it; no test touches the owner's files | P10-01, P10-18, P10-19,
  P10-22
- **P10-28** | DONE (qa-balance-tester, `docs/qa/phase10-screens.md` at 4b622ee, contact sheet `docs/qa/phase10-screens.png`: timeline locked / open / both finales won, Chapter 2 view with the Kings and with a trip crew (a drafted Rooftop sits), every Fathers HUD line, ISO BALL banner under the goal line, the era court angled and flat, all six signature moves and the fadeaway seen in play, unlock scenes, finale, Hall two rows and the mentor picker, the draft's two LEGENDS rows, the lineup rule line; 1280 and 1600x720 (P9-B7 gone), both hand layouts; hard rule by eye passes, two cautions for the owner (Midrange's purple kit, Freight's shaved head and goatee); music still the stand-in; bugs P10-B4, P10-B5, P10-B6) | QA: screens
  | qa-balance-tester | `docs/qa/phase10-screens.md`
  | xvfb screenshots: the timeline (Chapter 2 locked with its gate, open, finale won), the Chapter 2 view (crew and Kings),
  each Fathers challenge HUD line, the ISO BALL banner, the era court in play (both views), each signature move (and the
  F4 animation), an unlock scene, the finale, the Hall's two rows and the mentor picker, the draft's two LEGENDS rows,
  the lineup rule line; 1280x720 and 1600x720 (P9-B7 gone), both hand layouts; the hard rule by eye on every screen and
  sheet (names and the look combination); bugs filed as P10-Bn | P10-03, P10-14, P10-15, P10-16, P10-18, P10-19, P10-20

### Wave 6
- **P10-29** | DONE (gameplay-programmer: CLAUDE.md Chapter 2, README.txt, CREDITS.md Fathers art rows and CREDITS_LIST, legends-plan.md part 3 as shipped and the shipped goal numbers, itch_page.md, story_text.gd goal numbers (Eyes Closed down one, the P9-26 comments), stale board numbers; import clean, `--legendtest` OK, `--titletest` OK, `--legends-test --stars 24 --target 3` LEGENDS END with both chapters) | Docs
  | gameplay-programmer C | `CLAUDE.md`, `README.txt`, `CREDITS.md` (check), `scripts/title.gd` (`CREDITS_LIST`),
  `docs/legends-plan.md` (part 3's Fathers table and the Chapter 1 goal numbers as shipped), `docs/release/itch_page.md`,
  `scripts/story_text.gd` (goal numbers in lines only, from P10-23's list)
  | every new key, flag, file and screen state documented; credits in step; no story line names a stale number | P10-23..
  P10-28
- **P10-30** | DONE (qa-balance-tester, `docs/qa/phase10.md` at 498ad3e, contact sheet `docs/qa/phase10-final.png`: release-ready; 11 `--trip-test` runs (every level, two-era legends, stop + resume) TRIP END; 8 `--legends-test` runs (every level, both chapters, `--legends-chapter fathers`, forced losses, a trip crew) LEGENDS END; every self test OK (the legends_fathers.ogg NOTE is gone); every Father and the finale played, music `legends_fathers`; 20 `--autoplay` match Phase 9 (60 shots, 56% FG, 9:54, OREB 25.8%); web build by touch through LEGENDS, a Chapter 2 view, a Fathers challenge, the Hall, a mentor and a Fathers draft, no console errors; bug P10-B7, medium-low, cosmetic: the stuck banner strip) | Final Phase 10 QA
  | qa-balance-tester | `docs/qa/phase10.md`
  | `--legends-test` on every level (both chapters), `--trip-test` on every level, resume, backtest, titletest,
  legendtest, startest, cosmetictest, twisttest, ratingtest, anim-test, triptest-data, 10+ `--autoplay` games against the
  Phase 9 reference, the P10-21/24/28/29 results; a web build in Playwright (touch) through a Chapter 2 unlock, the Hall,
  a Fathers draft; release-ready or bugs | P10-29
- **P10-31** | Phase summary and check-in
  | lead-producer, then the coordinator | `docs/phase10-summary.md`; publish the web build | the summary with 2-4
  questions; the owner plays | P10-30

## Parallel plan (never two tasks on the same file in one wave)
| Wave | Tasks (agent) | Files | Notes |
|---|---|---|---|
| 1 | P10-01 (qa), P10-02 (gameplay A), P10-03 (gameplay B), P10-04 (art A), P10-04b (art B, if F4), P10-05 (art C), P10-06 (art D), P10-07 (art E), P10-08 (qa), P10-09 (gameplay C), P10-10 (gameplay D) | fixtures / legends.gd, legends_data.gd helpers / legends_tour.gd, hall.gd / make_players.py, crews.json, sample / make_players_v2.py, gif / make_courts.py, courts, court_looks.gd / make_legends_ui.py, assets/legends / audio_preview / scratch only / legends_test.gd / CREDITS.md, title.gd, howto.gd | P10-04 (+ P10-04b) go to the owner's look check together; at most two qa tasks run at once (2 Godot processes each) |
| 2 | P10-11 (A), P10-12 (B), P10-13 (C, if F3 a), P10-14 (art A), P10-15 (art B), P10-16 (D) | legends_data.gd, namecheck doc / twists.gd, player.gd, defense.gd, twist_fx.gd, main.gd (F2 c) / challenge.gd / make_players_v2.py, crews.json, players2 / make_portraits_v2.py, portraits / story_text.gd, story.gd | P10-11's name check lands before P10-14 / P10-15 use the names |
| 3 | P10-17 (A), P10-18 (B), P10-19 (C), P10-20 (art E), P10-21 (qa) | player.gd, defense.gd, ball.gd / legends.gd / trip.gd, draft.gd, lineup.gd / music, make_music.sh, CREDITS.md / docs + twists.gd numbers | P10-17 after P10-12 is merged |
| 4 | P10-22 (B), P10-23 (qa), P10-24 (C) | player.gd, main.gd, defense.gd / docs + legends_data.gd numbers / trip_test.gd | P10-22 after P10-17 is merged |
| 5 | P10-25 (C), P10-26 (qa), P10-27 (qa), P10-28 (qa) | main.gd / docs + legends_data.gd perk numbers / docs / docs | P10-25 after P10-22 is merged; the three qa tasks: at most two at once |
| 6 | P10-29 (C), then P10-30 (qa), then P10-31 (lead, coordinator) | docs, title.gd, story_text.gd numbers / docs / docs | |

Chains to watch: `legends_data.gd` by P10-02 (helpers, wave 1), P10-11 (rows, 2), then numbers only by P10-23 (4) and
P10-26 (5); `legends.gd` by P10-02 then P10-18; `player.gd` / `defense.gd` by P10-12, P10-17, P10-22 (each merged before
the next); `main.gd` by P10-12 (F2 c only), P10-22, P10-25; `make_players_v2.py` by P10-04b then P10-14; `crews.json` by
P10-04 then P10-14; `CREDITS.md` by P10-10, P10-20, P10-29; `title.gd` by P10-10 then P10-29; `story_text.gd` by P10-16
then numbers only in P10-29.

## Open questions for the owner
F1-F8 in `docs/legends-plan.md` "Phase 10 open questions" (each says which tasks it blocks). The era music pick comes
from P10-07's list during the build. Technical choices shown at the check-in: the hook pages stay on Chapter 1's sheets;
the draft shows one LEGENDS row per chapter.
