# Task Board

Current phase: **Phase 12: Legends, Chapter 4 (the New Generation)** (planned 2026-11-27 by `lead-producer`; VISION
"Phase 11 check-in": "Next: Chapter 4, the New Generation"). The Phase 11 board is archived in `docs/board-phase11.md`
(Phase 10: `docs/board-phase10.md`, Phase 9: `docs/board-phase9.md`, Phase 8: `docs/board-phase8.md`, Phase 7:
`docs/board-phase7.md`, Phase 6: `docs/board-phase6.md`, Phase 5: `docs/board-phase5.md`, Phase 4: `docs/board-phase4.md`,
Phase 3: `docs/board-phase3.md`, Phase 2: `docs/board-phase2.md`, Phase 1: `docs/board-phase1.md`).

**STATUS: DRAFT, PENDING THE OWNER'S ANSWERS to Q1-Q8 (`docs/legends-plan.md` "Phase 12 open questions").** Wave 1
needs no answer and can start. Every later task names the questions it waits for. Once the answers are in, the lead
updates this board: the contract below, the task rows, and any task an answer adds or drops (Q4, Q8).

Scope (the proposal in `docs/legends-plan.md` "Phase 12 plan"; each point waits for its question):
1. **Six original New Generation legends** (Q1): data, the name check extended to the 2024-2026 draft classes and
   today's young stars, sheets in the approved style with new era parts, portraits, unlock stories, joining lines,
   and jersey numbers the owner approves.
2. **Their six challenges and the finale** (Q3) on the six goal types we have (no new goal type): one of each type,
   with `score` the hardest; the finale to 21.
3. **The era rules** (Q2): one twist, `era_next` (proposed "FAST BREAK": two existing keys plus `dead_ball_mult` and
   `break_mult`). **The era court** `era_next`, a made-up arena of the future. **The era music**: a listening list,
   and the owner picks.
4. **The gate** (Q6): 72 stars or 48 tokens today (data). The timeline, chapter view, Hall and draft show four
   playable chapters. Nothing is "COMING LATER" any more (checked: no 5th panel is needed, plan 12.7).
5. **Mentors** (Q5): six new perks, about 2 stat points each. **Draft**: unlocked New Generation legends join the
   Road Trip draft; the one-legend rule stays (one legend of any era + one boss).
6. **Signature moves** (Q4): a small play edge each, plus the new animation(s) the owner picks, with previews first.
7. **The 4th era team** (Q7): NEW GENERATION in Quick Game (data only, `era_teams.gd`), and its court on COURT.
8. **The end of the mode** (Q8): proposed, a closing scene and LEGENDS COMPLETE.
9. **Carry-overs from the Phase 11 check-in** (the owner asked): Midrange's skin brown on his sheet and card (P12-09);
   Rooftop's cradle dunk with its own look, preview first (P12-10a, P12-10b). The Techno drive loop point only if
   the owner asks.
10. **Not in Phase 12** unless Q8 adds them: single legends in Quick Game, one-on-one, Legends cosmetics and the token
    ladder, an ALL-TIME game.

## Rules for every task in this phase
- **The hard rule (`docs/legends-plan.md` part 1): every legend is our own character.** No real player's name or
  nickname, face or likeness, number in a team's colors, signature accessory, trademark, shoe line, slogan or
  celebration, team, arena or league. **The New Generation is the riskiest era yet**: its archetypes map onto today's
  youngest stars, whom every player knows by look right now. So **no legend may carry a combination of look, build,
  number and move that points at one real player**. Examples: the very thin seven-footer who shoots step-backs; the
  tall flashy point guard with neck tattoos and a low number; the explosive leaper guard in a headband wearing 12; the
  big, quick bulldozer forward; the athletic twin wings. Spread the era parts (neon hair, mohawk, two-tone hair, locs,
  buzz cut, neon sleeves) one per legend. Move names are plain basketball words ("top gear", "putback", "hesitation",
  "hot hand", "swat"); never "logo three", never "heat check" as a celebration, and no slogan in any text (the list in
  `docs/legends-namecheck.md`). Kits never copy a current NBA or WNBA team's color pair. The owner's reference picture
  is never an asset or an input to a script. Review rejects any change that breaks this rule, the same way it rejects
  an asset without a license.
- **Chapters 1-3 and the rest of the game play exactly as in Phase 11.** No sim change outside P12-12 (the era rules),
  P12-17 (signature moves) and P12-22 (perks). Every new hook is a default that is exactly today's game: with twist
  `none` or an older era twist, no New Generation legend on the court and no new perk, seeded `--autoplay` and the
  Chapter 1-3 `--challenge` runs match `docs/qa/phase11.md` / `phase11-challenges.md` byte for byte.
- **Every chapter is data.** No `"next"` (or older chapter id) string in game logic outside `legends_data.gd`, the art
  lookups keyed by chapter id (frames, pins) and the tests. The chapter id stays `next` (plan 12.6).
- Tuning constants go at the top of the script they belong to: the era values in `twists.gd`, `BREAK_WINDOW` in
  `main.gd`, the signature numbers in `player.gd` / `defense.gd`, and the challenge numbers, per-chapter rating keys
  and perk sizes in `legends_data.gd`.
- Godot 4.3, no `:=` with untyped right sides, no new `.tscn`. Touch first: joystick + A + B in every game, **no new
  button or gesture** for any move (each comes out of today's inputs). Menus use big tap targets, Escape = BACK on
  desktop, and the Android back goes BACK. Support 1280x720 and wider screens. Version stays 1.0.0.
- Saves stay compatible: **`legends.json` version 1** (new keys only: `"lg:<id>"`, `"fin:next"`, ids in `unlocked` /
  `seen` / `mentors`) and **`trip.json` version 2** (a drafted New Generation legend is a `via: "draft"` entry with an
  `lg_` id). A Phase 11 build opening Phase 12 files must not crash (P12-27).
- Test runs never touch the owner's files: `user://legends_test.json`, `user://trip_test.json`,
  `user://settings_test.cfg`.
- Art is generated by the `tools/art` scripts in the approved style (style sample v1, the approved animation sample,
  comic portraits v2, the approved legend look samples). Never drawn by hand, downloaded or traced. Rerun the
  generator and commit its output. Music: CC0 or CC-BY only, with a row in `CREDITS.md` and `CREDITS_LIST`.

## Process rule (from Phases 9-11, keep it)
- **At most 3 agent tasks at a time** (the team rule now). Each wave below has 3 or fewer. The lead and the
  coordinator are not counted.
- **At most 2 Godot processes per agent** at a time. Run `--anim-test` runs one at a time (memory).
- **Every test run gets its own `XDG_DATA_HOME`** (and, for a scratch project copy, its own `config/name`). Runs that
  must share files share one name and one data folder, nothing else. Scratch folders go outside the repo; only the
  task's own files are committed.
- QA reports give the build commit, the flags, the game count per cell and the standard error.
- Owner previews (look sample, animation previews, court, numbers, names, music) go to the coordinator as soon as they
  are in review, so the owner can answer while the next wave runs.

## Shared contract (proposed; fixed once the answers are in)

### Chapter 4 data (`scripts/legends_data.gd`)
- The `next` row becomes `"built": true` (P12-11) with these keys:
  - `"rules"` (Q2, proposed `"FAST BREAK"`), `"twist": "era_next"`, `"look": "era_next"`, `"music": "legends_next"`,
    `"fallback_music": "newyork"`, `"gate"` (Q6; today `{"stars": 72, "tokens": 48}`)
  - `"crew"`: `"THE NEW GENERATION"`, a `ratings.gd` style (`inside`, `outside` or `balanced`; proposed `balanced`, since no "fast" style exists and a new
    style would be a sim change), the
    era palettes `ERA4_*` from P12-05, and `ui_color`
  - `"legends"` (6 ids), `"finale"` (target 21, 3 ids, `"NEW GENERATION FINALE"`)
  - `"intro_scene": "legends_next_intro"`, `"finale_scenes": {"before": "legends_next_finale_before", "after":
    "legends_next_finale_after"}`
  - the per-chapter rating keys (Q3; first guess `challenge_avg` 75, `mate_drop` 14, `finale_stage_avg` 66; P12-23
    tunes them)
- Legend ids (proposed, Q1 a): `lg_hyperdrive`, `lg_long_shadow`, `lg_glitch`, `lg_pogo`, `lg_halfcourt`,
  `lg_firewall`. The ids come from the nicknames, so a surname swap does not change them. If Q1 renames a nickname,
  the id follows the new nickname before any art is made. Each row has every Chapter 1-3 key; `archetype` is short
  enough for the draft card.
- Challenges (Q3 a): `lg_hyperdrive` `race` 11 before 10, `lg_long_shadow` `comeback` from 0-2 (to 15), `lg_glitch`
  `stop` 2 (to 15), `lg_pogo` `hold` under 6 (to 11), `lg_halfcourt` `fire` (to 15), `lg_firewall` `score` `min` 5
  (to 11). Finale: `lg_hyperdrive`, `lg_pogo`, `lg_halfcourt`.
- Perks (Q5 a; keys distinct from all earlier perks and twist keys; defaults 1.0 for `_mult`, 0.0 for `_bonus`):
  - `"fresh_legs"` (`sprint_drain_mult` 0.90)
  - `"head_start"` (`break_speed_mult` 1.04)
  - `"pump_fake"` (`fake_bite_mult` 1.15)
  - `"second_chance"` (`putback_bonus` 0.025)
  - `"early_shot"` (`early_shot_bonus` 0.010)
  - `"closeout"` (`jumper_block_mult` 1.10)
- Signature ids (Q4): `top_gear`, `rim_run`, `hesitation`, `putback`, `hot_hand`, `swat`. One per legend. The `text`
  is plain words, at most 2 lines in the Hall.
- New extras (Q4 a): `combo` (between the legs into behind the back, on `lg_glitch` only, alias `cross`). Q4 b: a
  `tipdunk` on `lg_pogo` only (alias `dunk_one`). Carry-over: `cradle` on `lg_rooftop` only (alias
  `dunk_windmill`). Every extra is listed in `format.json`'s `"extra"` with its `"sheets"`, as since P9-04c.

### The era rules (`scripts/twists.gd`, Q2)
- Twist `era_next`: `"name"` (proposed `"FAST BREAK"`), a banner line, `"icon": "era_next"`. Keys (Q2 a, starting
  points; P12-21 tunes them): `speed_mult` 1.05, `stamina_refill_mult` 1.15, `dead_ball_mult` 0.6 (new: x
  `rules.gd` `MADE_WAIT`, `OOB_WAIT`, `FOUL_WAIT`), `break_mult` 1.10 (new: x the make chance of a shot within
  `main.gd` `BREAK_WINDOW` 5.0 s of the shooter's team getting the ball, everyone). The new keys go in `DEFAULTS` at
  1.0, are read through `Twists.value(key, default)`, and never read a team. No shot clock change.

### Art and audio files
- Sheets `assets/players2/lg_<id>_p<N>.png`, palettes `lg_<id>`, `_crew`, `_crew_j1..3`, cards; strip
  `docs/art/legends_next.png` (`make_players_v2.py --legends-strip next`). Era palettes `ERA4_*` in
  `tools/art/crews.json` (P12-05). Era parts in `make_players.py` "Phase 12 era parts". Look sample
  `docs/art/legends_next_sample_v1.*` (`--legends-sample next`).
- Portraits `assets/portraits/lg_<id>.png` and `_happy`; contact sheet `docs/art/legends_next_portraits.png`
  (`make_portraits_v2.py --legends next`).
- Court `assets/courts/era_next_floor.png`, `era_next_backdrop.png` (`make_courts.py --era next`), and a
  `court_looks.gd` row `"era_next"` (no twist key, no reward; it joins the Quick Game COURT list through
  `era_teams.gd` only).
- Legends UI `assets/legends/frame_next.png`, `pin_next.png`, `pin_next_done.png` (`pin_next_locked.png` exists),
  listed in `ui.json`, and the timeline's 4th panel lit (`timeline.png`).
- Music `assets/music/legends_next.ogg` (P12-20): the owner's pick from P12-08's list.

### Story (`scripts/story_text.gd`)
- Scenes `legends_next_intro`, `lg_<id>_unlock` x 6, `legends_next_finale_before`, `legends_next_finale_after`, and
  (Q8 a) `legends_complete`, the closing scene with a legend of each era. Plus `RECRUIT_LINES` for the six.

### Era team (Q7; `scripts/era_teams.gd`, no logic change expected)
- `new_generation` (from the crew name): the finale three at average 50, the era kit, signatures kept, no perks; open
  once those three are unlocked. Its court goes after BIG STAGE in the COURT list.

## Owner answers already in (VISION)
These apply to Chapter 4 unchanged:
- "Legends plan answers": 6 per era, gates rising along the timeline, a mix of goals, one legend + one boss may start,
  small perks.
- "Phase 9 answers L1-L8": challenges are played with your Road Trip crew, or the Kings without a trip; drafted
  legends are boss level; mentors for regular players only, in Road Trip games only.
- "Phase 10 answers F1-F8", the perk size (about 2 stat points), and the score goal meant as the hardest.
- "Phase 11 answers P1-P8" and the rows after them: era teams are the finale three, and a team's court with its rules
  is on COURT once the team is open.
- The technical choices of Phases 9-11: the level is picked on the chapter view; a drafted legend sits when he is an
  opponent; one LEGENDS row per chapter in the draft (timeline order); extras only on the sheets that list them.
- From the "Phase 11 check-in": Chapter 4 next; Midrange's skin brown; Rooftop's cradle gets its own look.

## Todo
Everything below (Tasks by wave). Nothing past wave 1 starts before its questions are answered.

## Doing

## Review

## Done

## Tasks by wave (DRAFT)
Format: **id** | title | owner | files it may touch | done when | waits for.

### Wave 1 (no owner answer needed)
- **P12-02** | Name list for the new generation and a first check of the six
  | gameplay-programmer A | `docs/legends-namecheck.md` only
  | The lists gain the 2024-2026 draft classes, today's young stars and their nicknames, dunk contest names, current
  Japanese and European players, and shoe and product lines whose names could be a nickname ("Hyper...", "Zoom",
  ...). Then a "Chapter 4 (P12-02): first check" section covering the draft names and Q1 a's proposals (Ostrander,
  Marchetti, Ballantyne, Hyperdrive / Overdrive, Delacroix, Adeyemi, Starling): each one's result, 1-letter near
  misses, the look combinations in words (plan 12.1), the numbers 17 / 56 / 25 / 57 / 39 / 51, and a short summary
  for the owner. A name that fails comes with two passing alternatives | none
- **P12-03** | Four built chapters in the Legends logic and tests
  | gameplay-programmer B | `scripts/legends_data.gd` (test helpers only), `scripts/legends.gd` (`self_test()` only),
  `scripts/legends_test.gd`
  | `stand_in_test_data("next")` works (ids `lg_zz_next_1..6`), and a new `--legends-test-four` flag builds the 4th row
  as a stand-in. `Legends.self_test()` holds four built chapters with the stand-in (gates 72 stars / 48 tokens, max
  tokens 84, finales, unlocks, the swap and mentors over four eras, round trip). The `--legends-test` driver ends
  cleanly after the **last** chapter (no next-gate check when there is none). Shipped output is byte for byte the same
  as before: `--legendtest` OK, `--legends-test --stars 24 --target 3` LEGENDS END, and the three-chapter run
  unchanged | none
- **P12-10a** | Rooftop's cradle dunk: its own look, a preview (carry-over, the owner asked)
  | art-audio-integrator A | `tools/art/make_players_v2.py` (a `cradle` EXTRA row, carried by no sheet yet),
  `docs/art/cradle_v1.gif`
  | A dunk where he swings the ball from his hip in one arm and lays it in high, next to today's windmill, in 5
  directions; 0 hand/ball check problems; `format.json` and every sheet unchanged. For the owner's look check | none

### Wave 2 (Q1 for P12-05; the others need no answer)
- **P12-05** | New Generation era parts and a look sample
  | art-audio-integrator A | `tools/art/make_players.py` ("Phase 12 era parts"), `tools/art/crews.json` (`ERA4_*`
  palettes only), `docs/art/legends_next_sample_v1.png` / `.gif`
  | Parts: neon dyed hair, two-tone hair, mohawk (or the existing one), locs tied up, neon sleeves, modern low-cut
  shoes. Palettes: first guess lime + violet on near-black. The sample shows two legends in their kit and in your
  colors next to today's ud_deuce, plus a parts row for the other four. Renderer checks 0 problems, `--anim-test`
  ANIM OK, nothing in `assets/` changed. For the owner's look check | Q1, P12-02, P12-10a merged
- **P12-08** | Era music listening list
  | art-audio-integrator B | `docs/audio_preview/LIST.md` ("Legends: New Generation"), `docs/audio_preview/next_*.ogg`
  | 3-5 fast chiptune or electro tracks (160-175 bpm, neon synth leads; not New York's track, Bebop, Headspin or
  Techno drive), CC0 or CC-BY only, each license link checked on its page, 30 s samples at -20 LUFS. The owner picks
  one | none
- **P12-01** | Phase 11 save fixtures
  | qa-balance-tester | `docs/qa/fixtures/` (new files only) and its README
  | `legends_v1_ch3_mid.json` (Chapters 1-2 closed, 3 Present beaten, a Present mentor), `legends_v1_ch3_done.json`
  (three chapters closed, 63 tokens), `trip_v2_present.json` (a drafted Present legend starting next to a boss),
  `settings_v2_72.cfg`. A check script like the Phase 11 one. P12-27 loads them into the Phase 12 build | none

### Wave 3 (Q4 for P12-05b)
- **P12-05b** | The new animation(s) and their previews
  | art-audio-integrator B | `tools/art/make_players_v2.py` (EXTRA rows, carried by no sheet yet), `docs/art/combo_v1.gif`
  (Q4 a) and/or `docs/art/tipdunk_v1.gif` (Q4 b)
  | Each extra next to the move it replaces, 5 directions, events in the row (Q4 a `combo`: the crossover's timing so
  the sim is unchanged; Q4 b `tipdunk`: takeoff, catch and release frames); stand-in bodies until the legends' sheets
  exist; 0 hand/ball check problems. For the owner's look check | Q4, P12-05 merged (Q4 d: dropped)
- **P12-09** | Midrange's skin goes brown on his sheet and card (carry-over)
  | art-audio-integrator A | `tools/art/crews.json` (the `lg_midrange` entry only), `assets/players2/lg_midrange*`,
  `assets/players2/cards/lg_midrange*`
  | Regenerated with `--only lg_midrange` (his fadeaway extra kept). His skin matches his portrait's; no other sheet
  changes byte for byte; `--anim-test --anim-sheet lg_midrange` ANIM OK; a shot of him in a `--challenge
  lg_midrange` game | P12-05 merged (crews.json)
- **P12-06** | The New Generation court: a made-up arena of the future
  | art-audio-integrator C | `tools/art/make_courts.py` (`--era next`), `assets/courts/era_next_*`,
  `scripts/court_looks.gd` (the `era_next` row)
  | Dark glass floor, glowing lines, an edge light, hanging light rings, a dark crowd with phone lights. No word, digit
  or logo; it does not read as MIDNIGHT or BIG STAGE. Era colors from P12-05's palettes. Checked in angled and flat
  shots; `--era` rewrites the older era files byte for byte; not in the COURT list. A name proposal for the look
  check | P12-05 merged

**Owner look check after wave 3**: names (P12-02), the look sample and colors (P12-05), the animation preview(s)
(P12-05b), the cradle (P12-10a), the court and its name (P12-06), the numbers, and the music pick (P12-08). The lead
writes the answers into the contract.

### Wave 4 (Q1, Q3, Q5, Q6 answered; the look check done)
- **P12-11** | Chapter 4 data and the name check in the data
  | gameplay-programmer A | `scripts/legends_data.gd`, `docs/legends-namecheck.md`
  | The `next` row built as in the contract (music `legends_next`, fallback `newyork` until P12-20), the six legends
  (ids, names, numbers, shapes, challenges, signatures, looks, bios), the six perks as data, and the new names, probes
  and numbers in the lists. The namecheck doc's Chapter 4 table is final. `--legendtest` LEGENDTEST OK (notes for art
  not there yet). 24 legends, max tokens 84 | Q1, Q3, Q5, Q6, P12-02, P12-03 merged
- **P12-12** | The era rules
  | gameplay-programmer B | `scripts/twists.gd`, `scripts/rules.gd` (the `dead_ball_mult` hook), `scripts/main.gd`
  (the `break_mult` hook, `BREAK_WINDOW`), `scripts/twist_fx.gd` (the banner icon)
  | `era_next` as in the contract; `--twisttest` TWISTTEST OK; twist `none` and every older twist give byte-identical
  seeded `--autoplay` logs; 8+ `--autoplay --twist era_next` games all end; the banner and icon shown in a
  `--twistshots` shot | Q2 (Q2 d: dropped; Q2 b: twists.gd only), P12-03 merged
- **P12-07** | Legends UI art for Chapter 4
  | art-audio-integrator C | `tools/art/make_legends_ui.py`, `assets/legends/frame_next.png`, `pin_next.png`,
  `pin_next_done.png`, `ui.json`, `timeline.png`, `docs/art/legends_ui.png`
  | In the chosen era colors. The 4th timeline panel shows the court lit. Chapters 1-3 files byte for byte unchanged;
  `--legendtest` OK | the look check, P12-06 merged

### Wave 5
- **P12-14** | The six New Generation sheets (+ the extras)
  | art-audio-integrator A | `tools/art/make_players_v2.py`, `tools/art/crews.json`, `assets/players2/lg_<six>*`,
  `assets/players2/format.json`, `assets/players2/hands.json` (only if needed), `scripts/sheets.gd` (`ALIASES`)
  | Six sheets with palettes, `_crew`, `_crew_j1..3`, cards; the strip `docs/art/legends_next.png`; Q4's extra on its
  legend's sheet only (listed in `"extra"`, own lane); no older sheet changes byte for byte; `--anim-test` ANIM OK
  | Q1, Q4, the look check, P12-11 merged
- **P12-15** | The New Generation portraits
  | art-audio-integrator B | `tools/art/make_portraits_v2.py`, `assets/portraits/lg_<six>*`,
  `docs/art/legends_next_portraits.png`
  | Twelve portraits (neutral, happy) in the era kits; new kit parts are opt-in, so older portraits stay byte for
  byte the same | the look check, P12-11 merged
- **P12-16** | Chapter 4 story and the end of the mode
  | gameplay-programmer C | `scripts/story_text.gd`, `scripts/story.gd` (only if a scene needs it)
  | The intro, six unlock scenes, the finale before/after, `RECRUIT_LINES` for the six, and (Q8 a/b/c)
  `legends_complete` with a legend of each era (the grandfathers, fathers and sons theme; "kid" allowed). No slogan
  or banned word (`--legendtest` checks the text). Lines that name a goal number use the data's numbers | Q1, Q3, Q8,
  P12-11 merged

### Wave 6
- **P12-17** | Signature moves
  | gameplay-programmer A | `scripts/player.gd`, `scripts/defense.gd`, `scripts/ball.gd`
  | The six moves, constants at the top (block "P12-17"), each only for its signature; the extra frames when
  `Sheets.has_anim()` (counts `anim_<extra>`); `--signature` takes the new ids; no new input. Seeded A/B: `--autoplay`,
  every older era twist, `--humantest` and one `--challenge` per older chapter give byte-identical logs. Each move is
  seen in the Chapter 4 `--challenge` runs and as the human | Q4, P12-12, P12-14 merged
- **P12-18** | Chapter flow, the gate and the ending
  | gameplay-programmer B | `scripts/legends.gd`, `scripts/legends_tour.gd`, `scripts/hall.gd`
  | `self_test()` holds the four shipped chapters (`SHIPPED_CHAPTERS` 4, gates from Q6). The chapter walk covers
  Chapter 4 (shut at the Present's gate, open at its own). Q8 a: after the Chapter 4 finale's after scene comes
  `legends_complete` once, then LEGENDS COMPLETE on the timeline (the header or a banner, no new panel) and a full-Hall
  banner; replays never play it again. No "next" string in the logic. `--legendtest` OK; `--legends-test --difficulty
  hard` LEGENDS END (84/84) | Q6, Q8, P12-11, P12-16 merged
- **P12-20** | Era music in the game
  | art-audio-integrator C | `assets/music/legends_next.ogg`, `tools/make_music.sh`, `CREDITS.md`, `scripts/title.gd`
  (`CREDITS_LIST` only), `scripts/court_looks.gd` and `scripts/legends_data.gd` (the music key only)
  | The owner's pick, looped, about -20 LUFS, mono; a credits row (title, author, license link, source, changes);
  `--titletest` credits count right; `--challenge lg_hyperdrive` plays it | the music pick, P12-11 merged

### Wave 7
- **P12-19** | Draft and lineup with four eras
  | gameplay-programmer C | `scripts/trip.gd`, `scripts/draft.gd`, `scripts/lineup.gd`
  | A 4th LEGENDS row ("UNLOCKED IN LEGENDS - THE NEW GENERATION", timeline order, era frame and color); the one-legend
  rule over four eras; the trip self test expects a row per built chapter; a Phase 11 build drops a New Generation
  legend safely (P12-27 checks) | P12-11, P12-14 merged
- **P12-21** | QA: the era rules
  | qa-balance-tester | `docs/qa/phase12-era.md`, `scripts/twists.gd` (`era_next` numbers only)
  | 200+ `--autoplay --twist era_next` games against Phase 11's bands: game length, shots, early-possession shots,
  make rate, fouls, rebounds; the numbers tuned if the era doesn't feel faster or the stats leave the bands (with the
  owner's yes) | P12-12, P12-17 merged
- **P12-10b** | The cradle on Rooftop's sheet
  | art-audio-integrator A | `tools/art/make_players_v2.py`, `assets/players2/lg_rooftop*`, `assets/players2/format.json`,
  `scripts/player.gd` (the `CRADLE_STYLE` line only)
  | `cradle` extra on `lg_rooftop` only, as approved; `--anim-test` ANIM OK; `--challenge lg_rooftop` shows
  `anim_cradle`; nothing else changes | the look check, P12-14 and P12-17 merged

### Wave 8
- **P12-22** | Mentor perks for the New Generation
  | gameplay-programmer A | `scripts/player.gd`, `scripts/main.gd`, `scripts/defense.gd`, `scripts/ball.gd` (only if a
  hook lives there)
  | The six hooks, each a default that is today's game; `--perk` takes the new ids, with a `PERK` line the first time
  each changes a play; seeded A/B without a new perk byte-identical | Q5, P12-17 and P12-10b merged
- **P12-23** | QA: Chapter 4 challenges and finale
  | qa-balance-tester | `docs/qa/phase12-challenges.md`, `scripts/legends_data.gd` (challenge numbers and rating
  keys only)
  | Per challenge and the finale, Easy / Normal / Hard with the end-of-trip crew (`--expected-roster`,
  `--best-roster`), cells big enough to see Q3's bands; Firewall the hardest; any story line made stale listed for
  P12-29 | Q3, P12-17, P12-18 merged
- **P12-24** | Trip test: a drafted New Generation legend
  | gameplay-programmer C | `scripts/trip_test.gd`
  | `LEGEND_DRAFT_CHAPTERS` next -> present -> fathers -> grand (the first legend draft signs a New Generation legend
  from his row); refusals across eras; legend + boss starts; TRIP END checks every built chapter's row | P12-19 merged

### Wave 9
- **P12-25** | Back test and title test for Chapter 4
  | gameplay-programmer C | `scripts/main.gd` (the backtest steps only), `scripts/title.gd` (the titletest driver only)
  | `BACKTEST_CHAPTER4` "next" (its view, the Hall and back, the mentor picker, a challenge's pause, resume and QUIT;
  its gate forced for the run unless `--stars 72` or `--tokens 48`); `--titletest` era checks with four era teams and
  courts; BACKTEST OK, TITLE TEST DONE | P12-18, P12-22 merged
- **P12-26** | QA: the ramp with New Generation legends and perks
  | qa-balance-tester | `docs/qa/phase12-ramp.md`, `scripts/legends_data.gd` (perk numbers only)
  | `--best-roster` with a New Generation legend and the strongest new perks: Hard RED share against Phase 11's 44%;
  each perk measured at about 2 stat points, resized with the owner's yes | P12-22, P12-23 merged
- **P12-33** | The 4th era team and its court in Quick Game
  | gameplay-programmer B | `scripts/era_teams.gd` (self test expectations; logic only if the data needs it),
  `scripts/menu.gd` (only if the COURT order needs it)
  | `new_generation` opens with its finale three; `--quick-teams new_generation,grandfathers` works; the court follows
  BIG STAGE on COURT with its twist and music; `--legendtest` "era teams" OK | Q7, P12-11, P12-20 merged

### Wave 10
- **P12-27** | QA: saves | qa-balance-tester | `docs/qa/phase12-saves.md` | P12-01's fixtures load in the Phase 12 build;
  Phase 12 files open in a Phase 11 build without a crash (unknown ids dropped); a NEW TRIP never touches
  `legends.json` | P12-19, P12-18 merged
- **P12-28** | QA: screens | qa-balance-tester | `docs/qa/phase12-screens.md` and shots | Every Legends screen at
  1280x720 and wider with four chapters (timeline, Chapter 4 view, Hall with four rows, draft rows, LEGENDS COMPLETE),
  the six moves and the extras, the court and banner; bugs filed as P12-B<n> | P12-25 merged
- **P12-36** | QA: era team balance | qa-balance-tester | `docs/qa/phase12-quick-eras.md` | NEW GENERATION vs the crews on
  Hard and vs each era team (Grandfathers vs New Generation on both era courts), 200+ games a cell; a report for the
  owner, no change without his yes | P12-33 merged

### Wave 11
- **P12-29** | Docs | gameplay-programmer C | `CLAUDE.md`, `README.txt`, `CREDITS.md`, `docs/legends-plan.md` (as
  shipped), `docs/release/itch_page.md`, `scripts/title.gd` (`CREDITS_LIST` only), `scripts/story_text.gd` (stale
  numbers only) | Every fact read from the merged code; `--legendtest`, `--titletest` OK | all build tasks merged
- **P12-30** | Final Phase 12 QA | qa-balance-tester | `docs/qa/phase12.md` | Every test mode passes; 200 `--autoplay`
  games in Phase 11's bands; Kings vs Runners both orders; `--trip-test` on every level; `--legends-test` on every
  level; release-ready or a bug list | P12-29 merged
- **P12-31** | Phase summary and check-in | lead-producer | `docs/phase12-summary.md`, this board | What's new, how to try
  it on the tablet, known issues, 2-4 multiple-choice questions | P12-30 passes
- **P12-32** | Publish | coordinator | `gh-pages` (build output only), `build/release/` (not in git) |
  `tools/build_web.sh --zip --publish` after a Playwright touch check of the web build, `tools/build_android.sh` (the
  debug APK; the signed one needs the owner's key) | P12-31, the merge onto the named branch

### Added only if the owner picks them
- Q8 b: **P12-37** ALL-TIME game (`legends_data.gd` a row, `legends.gd` the match, `legends_tour.gd` a button, a QA
  cell). Q8 c: **P12-38** the token ladder and Legends cosmetics (`legends.gd`, `cosmetics.gd`, `locker.gd`, art;
  several tasks, planned when chosen).

## Parallel plan (never two tasks on the same file in one wave; at most 3 agent tasks a wave)
| Wave | Tasks (agent) | Files | Notes |
|---|---|---|---|
| 1 | P12-02 (gameplay A), P12-03 (gameplay B), P12-10a (art A) | namecheck doc / legends_data.gd helpers, legends.gd self_test, legends_test.gd / make_players_v2.py, cradle gif | can start now |
| 2 | P12-05 (art A), P12-08 (art B), P12-01 (qa) | make_players.py, crews.json, sample / audio_preview / fixtures | P12-05 after Q1 |
| 3 | P12-05b (art B), P12-09 (art A), P12-06 (art C) | make_players_v2.py, gifs / crews.json lg_midrange, lg_midrange files / make_courts.py, courts, court_looks.gd | then the owner's look check |
| 4 | P12-11 (A), P12-12 (B), P12-07 (art C) | legends_data.gd, namecheck doc / twists.gd, rules.gd, main.gd, twist_fx.gd / make_legends_ui.py, assets/legends | |
| 5 | P12-14 (art A), P12-15 (art B), P12-16 (C) | make_players_v2.py, crews.json, players2, format.json, sheets.gd / make_portraits_v2.py, portraits / story_text.gd, story.gd | |
| 6 | P12-17 (A), P12-18 (B), P12-20 (art C) | player.gd, defense.gd, ball.gd / legends.gd, legends_tour.gd, hall.gd / music, make_music.sh, CREDITS.md, title.gd CREDITS_LIST, court_looks.gd + legends_data.gd music key | |
| 7 | P12-19 (C), P12-21 (qa), P12-10b (art A) | trip.gd, draft.gd, lineup.gd / docs + twists.gd numbers / make_players_v2.py, lg_rooftop, format.json, player.gd one line | |
| 8 | P12-22 (A), P12-23 (qa), P12-24 (C) | player.gd, main.gd, defense.gd, ball.gd / docs + legends_data.gd numbers / trip_test.gd | |
| 9 | P12-25 (C), P12-26 (qa), P12-33 (B) | main.gd backtest, title.gd titletest / docs + legends_data.gd perk numbers / era_teams.gd, menu.gd | P12-26 after P12-23 merged (legends_data.gd numbers) |
| 10 | P12-27, P12-28, P12-36 (qa x3) | docs only | |
| 11 | P12-29 (C), then P12-30 (qa), then P12-31 (lead), P12-32 (coordinator) | docs / docs / docs / build output | |

Chains to watch:
- `legends_data.gd`: P12-03 (helpers), P12-11 (rows), P12-20 (music key), then numbers only in P12-23 and P12-26.
- `make_players_v2.py`: P12-10a, P12-05b, P12-14, P12-10b. `crews.json`: P12-05, P12-09, P12-14.
- `format.json`: P12-14, then P12-10b.
- `player.gd`: P12-17, P12-10b (one line), P12-22.
- `main.gd`: P12-12, P12-22, P12-25.
- `court_looks.gd`: P12-06, then the music key in P12-20.
- `title.gd`: P12-20 (`CREDITS_LIST`), P12-25 (titletest), P12-29.
- `legends.gd`: P12-03 (self_test), P12-18.
- Each task is merged before the next one on its chain starts.

## Open questions for the owner
Q1-Q8 in `docs/legends-plan.md` "Phase 12 open questions" (each one with its options; (a) is the recommendation).
Also still open from Phase 11: the Techno drive loop point (the owner listens).
