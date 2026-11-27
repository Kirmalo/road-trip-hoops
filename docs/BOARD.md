# Task Board

Current phase: **Phase 12: Legends, Chapter 4 (the New Generation)** (planned 2026-11-27 by `lead-producer`; VISION
"Phase 11 check-in": "Next: Chapter 4, the New Generation"). The Phase 11 board is archived in `docs/board-phase11.md`
(Phase 10: `docs/board-phase10.md`, Phase 9: `docs/board-phase9.md`, Phase 8: `docs/board-phase8.md`, Phase 7:
`docs/board-phase7.md`, Phase 6: `docs/board-phase6.md`, Phase 5: `docs/board-phase5.md`, Phase 4: `docs/board-phase4.md`,
Phase 3: `docs/board-phase3.md`, Phase 2: `docs/board-phase2.md`, Phase 1: `docs/board-phase1.md`).

**STATUS: PLANNED.** The owner answered Q1-Q8 (VISION "Phase 12 answers Q1-Q8"): Q2 a FAST BREAK, Q3 a a step harder,
Q4 a Glitch's combo dribble (preview first), Q5 a six new perks, Q6 a 72 stars or 48 tokens, Q7 a the 4th era team
and court, Q8 a an ending. **Q1: a futuristic chapter**: 3 of the 6 legends have visible cybernetic parts, each tied to
his signature move (a small play edge like every legend's, never a bigger one), 3 are all natural. The roster built on
that is `docs/legends-plan.md` 12.9 (a draft until the owner's first check, after wave 1: the names and the look
sample).

Scope (`docs/legends-plan.md` "Phase 12 plan", 12.9 for the roster):
1. **Six original New Generation legends** (12.9): Overclock, Long Shadow, Glitch, Updraft, Halfcourt, Firewall;
   **cyber**: Overclock (leg braces), Glitch (chrome forearm), Firewall (visor); **natural**: Long Shadow, Updraft,
   Halfcourt. Data, the name check extended to the 2024-2026 draft classes, today's young stars and famous fictional
   cyborgs, sheets with the new era and cyber parts, portraits, unlock stories, joining lines, numbers 17 / 56 / 25 /
   57 / 39 / 51 (the owner sees them at the first check).
2. **Their six challenges and the finale** (Q3 a, a step harder than Chapter 3) on the six goal types we have: one of
   each type, with `score` the hardest; the finale to 21.
3. **The era rules** (Q2 a): twist `era_next` "FAST BREAK" (two existing keys plus `dead_ball_mult` and `break_mult`).
   **The era court** `era_next`, a made-up arena of the future (first name idea NEON DOME). **The era music**: a
   listening list, and the owner picks.
4. **The gate** (Q6 a): 72 stars or 48 tokens, no Chapter 3 finale needed. The timeline, chapter view, Hall and draft
   show four playable chapters; nothing is "COMING LATER" any more (no 5th panel, plan 12.7).
5. **Mentors** (Q5 a): six new perks, about 2 stat points each. **Draft**: unlocked New Generation legends join the
   Road Trip draft; the one-legend rule stays (one legend of any era + one boss).
6. **Signature moves**: a small play edge each; one new animation (Q4 a): Glitch's combo dribble, preview first.
7. **The 4th era team** (Q7 a): NEW GENERATION in Quick Game (data only, `era_teams.gd`), and its court on COURT.
8. **The end of the mode** (Q8 a): a closing scene with a legend of each era, LEGENDS COMPLETE on the timeline, a full
   Hall banner. Nothing new to play.
9. **Carry-overs from the Phase 11 check-in**: DONE before the phase (P12-09 Midrange brown, P12-10a/b the cradle).
   The Techno drive loop point only if the owner asks.
10. **Not in Phase 12**: single legends in Quick Game, one-on-one, Legends cosmetics and the token ladder, an ALL-TIME
    game (Q8 b/c not picked), a pulsing glow (12.9: static glow only).

## Rules for every task in this phase
- **The hard rule (`docs/legends-plan.md` part 1): every legend is our own character.** No real player's name or
  nickname, face or likeness, number in a team's colors, signature accessory, trademark, shoe line, slogan or
  celebration, team, arena or league. **The New Generation is the riskiest era yet**: its archetypes map onto today's
  youngest stars, whom every player knows by look right now. So **no legend may carry a combination of look, build,
  number and move that points at one real player**. Examples: the very thin seven-footer who shoots step-backs; the
  tall flashy point guard with neck tattoos and a low number; the explosive leaper guard in a headband wearing 12; the
  big, quick bulldozer forward; the athletic twin wings. Spread the hair parts (lime crop, mohawk, two-tone hair, locs,
  buzz cut, sandy curls with a headband) one per legend. Move names are plain basketball words ("top gear", "putback",
  "hesitation", "hot hand", "swat"); never "logo three", never "heat check" as a celebration, and no slogan in any text (the list in
  `docs/legends-namecheck.md`). Kits never copy a current NBA or WNBA team's color pair. The owner's reference picture
  is never an asset or an input to a script. Review rejects any change that breaks this rule, the same way it rejects
  an asset without a license.
- **The cyber rule (Q1, `docs/legends-plan.md` 12.9).** Three legends (Overclock, Glitch, Firewall) wear visible
  cybernetic parts, three (Long Shadow, Updraft, Halfcourt) are all natural. A part is look only, tied to its legend's
  move; the move is the same small edge as any legend's (no stat, speed or rating bonus for a part). No part copies a
  famous fictional cyborg's look (a metal arm with a star or emblem, a red visor, a gold visor band, a chrome band round
  a bald head, two metal arms) and no name or text uses "cyborg", "bionic", "robo", "terminator", "android" or "iron".
  The natural three carry no chrome, glow or dyed hair.
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


## Shared contract (from the answers; the roster names and looks are final after the owner's first check)

### Chapter 4 data (`scripts/legends_data.gd`)
- The `next` row becomes `"built": true` (P12-11) with these keys:
  - `"rules": "FAST BREAK"`, `"twist": "era_next"`, `"look": "era_next"`, `"music": "legends_next"`,
    `"fallback_music": "newyork"`, `"gate": {"stars": 72, "tokens": 48}` (Q6 a)
  - `"crew"`: `"THE NEW GENERATION"`, style `balanced` (no "fast" style exists; a new style would be a sim change),
    the era palettes `ERA4_*` from P12-05, and `ui_color`
  - `"legends"` (6 ids), `"finale"` (target 21, 3 ids, `"NEW GENERATION FINALE"`)
  - `"intro_scene": "legends_next_intro"`, `"finale_scenes": {"before": "legends_next_finale_before", "after":
    "legends_next_finale_after"}`
  - the per-chapter rating keys (Q3 a; first guess `challenge_avg` 75, `mate_drop` 14, `finale_stage_avg` 66; P12-23
    tunes them to Normal about 45%, Hard about 30-35%, the finale a bit harder than Chapter 3's)
- Legend ids (12.9; the ids follow the nicknames): `lg_overclock`, `lg_long_shadow`, `lg_glitch`, `lg_updraft`,
  `lg_halfcourt`, `lg_firewall`. A nickname the owner changes at the first check changes its id before any art is
  made. Each row has every Chapter 1-3 key; `archetype` is short enough for the draft card. The cyber part is in the
  `look` text only; no game logic reads it (no new data key unless the owner picks a CYBER / NATURAL tag, 12.9 R3).
- **The cyber rule**: a cyber part is look only. The play edge is the signature move, the same size as any legend's;
  no stat, speed or rating bonus for a part. Shapes sum to 0 as always.
- Challenges (Q3 a): `lg_overclock` `race` 11 before 10, `lg_long_shadow` `comeback` from 0-2 (to 15), `lg_glitch`
  `stop` 2 (to 15), `lg_updraft` `hold` under 6 (to 11), `lg_halfcourt` `fire` (to 15), `lg_firewall` `score` `min` 5
  (to 11). Finale (suggested, 12.9 R2): `lg_overclock`, `lg_updraft`, `lg_halfcourt`.
- Perks (Q5 a; keys distinct from all earlier perks and twist keys; defaults 1.0 for `_mult`, 0.0 for `_bonus`):
  - Overclock `"fresh_legs"` (`sprint_drain_mult` 0.90)
  - Long Shadow `"head_start"` (`break_speed_mult` 1.04)
  - Glitch `"pump_fake"` (`fake_bite_mult` 1.15)
  - Updraft `"second_chance"` (`putback_bonus` 0.025)
  - Halfcourt `"early_shot"` (`early_shot_bonus` 0.010)
  - Firewall `"closeout"` (`jumper_block_mult` 1.10)
- Signature ids: `top_gear` (Overclock), `rim_run` (Long Shadow), `hesitation` (Glitch), `putback` (Updraft),
  `hot_hand` (Halfcourt), `swat` (Firewall). The `text` is plain words, at most 2 lines in the Hall.
- New extra (Q4 a): `combo` (between the legs into behind the back) on `lg_glitch` only, alias `cross`, listed in
  `format.json`'s `"extra"` with its `"sheets"`, its own lane. The cradle extra is already in (P12-10b).

### The era rules (`scripts/twists.gd`, Q2 a)
- Twist `era_next`: `"name": "FAST BREAK"`, a banner line ("Fast break: a quicker game, early shots fall"), `"icon":
  "era_next"`. Keys (starting points; P12-21 tunes them): `speed_mult` 1.05, `stamina_refill_mult` 1.15,
  `dead_ball_mult` 0.6 (new: x `rules.gd` `MADE_WAIT`, `OOB_WAIT`, `FOUL_WAIT`), `break_mult` 1.10 (new: x the make
  chance of a shot within `main.gd` `BREAK_WINDOW` 5.0 s of the shooter's team getting the ball, everyone). The new
  keys go in `DEFAULTS` at 1.0, are read through `Twists.value(key, default)`, and never read a team. No shot clock
  change.

### Art and audio files
- **Cyber parts in the sheets (12.9)**: two FLAT glow tones in `tools/art/pixel3d.py` (`FLAT`: unshaded, no contour),
  **lime** and **violet**, own RGB values (never a kit tone, so the jersey map never touches them), and a shaded
  **chrome** ramp. Opt-in parts in `make_players.py` "Phase 12 era parts": leg braces (both shins: a 2 px chrome strut,
  a 1 px lime line), a chrome forearm and hand (violet seams at the wrist and knuckles, one arm, swaps in the mirrored
  directions like Deep End's tights), a visor (a 1-2 px lime band across the eyes, chrome at the temples, front only).
  **Static glow only** (palettes are fixed; no pulse, no halo past the outline). Every recolor (`_crew`, `_crew_j1..3`)
  keeps the parts. Older sheets byte for byte the same.
- The natural three: no chrome, no glow, no dyed hair (skin, cloth, tape; warm hair colors).
- Sheets `assets/players2/lg_<id>_p<N>.png`, palettes `lg_<id>`, `_crew`, `_crew_j1..3`, cards; strip
  `docs/art/legends_next.png` (`make_players_v2.py --legends-strip next`). Era palettes `ERA4_*` (first guess lime +
  violet on near-black, chrome on the parts only) in `tools/art/crews.json`. Look sample
  `docs/art/legends_next_sample_v1.*` (`make_players.py --legends-sample next`).
- Portraits `assets/portraits/lg_<id>.png` and `_happy`; contact sheet `docs/art/legends_next_portraits.png`
  (`make_portraits_v2.py --legends next`). The cyber parts show in the cyber portraits (Overclock's braces need a lower
  framing or their glow; P12-15 proposes).
- Court `assets/courts/era_next_floor.png`, `era_next_backdrop.png` (`make_courts.py --era next`), and a
  `court_looks.gd` row `"era_next"` (no twist key, no reward; it joins the Quick Game COURT list through
  `era_teams.gd` only).
- Legends UI `assets/legends/frame_next.png`, `pin_next.png`, `pin_next_done.png` (`pin_next_locked.png` exists),
  listed in `ui.json`, and the timeline's 4th panel lit (`timeline.png`).
- Music `assets/music/legends_next.ogg` (P12-20): the owner's pick from P12-08's list.

### Story (`scripts/story_text.gd`)
- Scenes `legends_next_intro`, `lg_<id>_unlock` x 6, `legends_next_finale_before`, `legends_next_finale_after`, and
  (Q8 a) `legends_complete`: a legend of each era (suggested Steeple, Rooftop, Deep End, and Glitch + Halfcourt, one
  cyber and one natural), the old laced ball handed down the eras; the grandfathers, fathers and sons theme. Plus
  `RECRUIT_LINES` for the six. A cyber part is a tool the legend earned or built (12.9's hooks), never a cheat.

### Era team (Q7 a; `scripts/era_teams.gd`, no logic change expected)
- `new_generation` (from the crew name): the finale three at average 50, the era kit, signatures kept, no perks; open
  once those three are unlocked. Its court goes after BIG STAGE in the COURT list, with FAST BREAK and its music.

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
- "Phase 11 check-in": Chapter 4 next; Midrange's skin brown (done, P12-09); Rooftop's cradle its own look (done,
  P12-10a/b).
- "Phase 12 answers Q1-Q8" (above).

## Todo
Everything in "Tasks by wave" not marked DONE.

## Doing

## Review
- **P12-21** QA of FAST BREAK (qa): `docs/qa/phase12-era.md`. 200 `--autoplay --twist era_next` vs 200 twist none
  (Kings vs Runners), all ended, no errors, 0 shot-clock violations: game 8.98 vs 9.73 min, shots 58.9 vs 60.7, FG
  55.8 vs 54.1 %, dead balls 22.0 vs 35.3 s, fouls 2.16 vs 2.06, OREB 24.8 vs 25.4 %, RED 47 vs 57 % (a 2 SE lean).
  Early shots (within 5 s) 31 % of shots, made 57.4 % vs later 58.1 % (no twist: 52.5 vs 57.8: early shots are longer,
  fewer at the rim), so 1.10 only cancels their handicap. Candidates (scratch only): break 1.20 +0.7, 1.30 +5.6, speed
  1.08 + break 1.30 **+8.4** (8.62 min, FG 56.2 %, RED 52.5 %, 40 games), break 1.45 +8.8 but FG 59 %, RED 40 %.
  Suggested for the owner: `break_mult` 1.30, `speed_mult` 1.08 (twists.gd not changed)
- **P12-33** The 4th era team in Quick Game (gameplay B): no logic change needed, the data opens it. `era_teams.gd` self test only: `SHIPPED_IDS` (the four teams), timeline order, `STAND_IN_CHECKS` (stand-in Present and stand-in New Generation rows), team and info color = the crew's `ui_color`. `menu.gd` untouched. LEGENDTEST era teams [grandfathers, fathers, present, new_generation] OK; `--titletest` DONE plain / `--legends-unlock-all --stars 72` (COURT gym > blacktop > era_grand > era_fathers > era_present > era_next > midnight > gold_hall, NEON DOME twist era_next music legends_next) / `--legends-unlock-none` (none open); 4 autoplays NEW GENERATION vs Kings on NEON DOME 21-18, 19-21, 16-21, 18-21 (8:17-9:46, music_legends_next).
- **P12-18** Chapter flow, the gate and the ending (gameplay B): `legends.gd`, `legends_tour.gd`, `hall.gd`, and the
  `--legends-test` driver's checks (`legends_test.gd`, as the coordinator asked). `SHIPPED_CHAPTERS` 4 (gate 72 stars
  or 48 tokens checked; the chapter walk runs on four eras). `Legends.legends_complete()` (every timeline row built,
  each finale won; from the data, no chapter id), `last_chapter()`, `complete_scene()`, `COMPLETE_SCENE`
  "legends_complete": the finale win that completes the mode plays its "after" scene, then the ending (marked seen,
  once), then the chapter view; replays and later games never again. Timeline: the sub line becomes a gold banner
  "LEGENDS COMPLETE - TOKENS 84/84" and the hint "Every era beaten, every finale won. The Hall is full." Hall: the title
  and hint sit on a gold banner ("THE HALL IS FULL: LEGENDS COMPLETE. TAP HERE FOR THE ENDING."), the count box gets a
  gold border; a tap on the banner (776 x 114) replays the ending, back to the Hall (the plaque's REPLAY STORY stays
  his unlock scene). No CYBER / NATURAL tag (owner R3). `--legendtest` OK; `--legends-test --stars 24 --target 3
  --difficulty hard` LEGENDS END 84/84 (ending 1x after the last finale, 1x from the Hall); `--difficulty normal
  --stars 48` LEGENDS END, Chapter 4 locked at 42 tokens, no ending, no banner; `--backtest` OK; `--titletest` DONE
- **P12-16** Chapter 4 story and the end of the mode (gameplay C): `story_text.gd` only (story.gd unchanged).
  `legends_next_intro` (NEON DOME, FAST BREAK, Overclock and Emrys Tregarth introduce the six), the six
  `lg_<id>_unlock` scenes (goal numbers from the data: 11 before 10, down 0-2 to 15, 2 stops to 15, under 6 to 11, hot
  start cooled by 2 misses to 15, 5 points on him to 11; each teaches his perk), `legends_next_finale_before` /
  `_after` (CHAPTER 4: DONE, a hint to the wood gym), `RECRUIT_LINES` for the six, and `legends_complete` (12 lines,
  the old wood gym: Steeple's laced ball to Rooftop, Deep End, then Glitch (left) and Halfcourt (right) together;
  ends "LEGENDS COMPLETE"). Cyber origins: Overclock's knee brace after an injury at twelve, Glitch's hand built in the
  school workshop, Firewall's training visor. Naturals: Long Shadow's dirt trailhead court, Updraft's sand court by the
  pier, Halfcourt's old film of the Grandfathers. Every new line through the name check lists (all nicknames, 1-word
  too, names, `CYBER_WORDS`): 0 hits. `--legendtest` OK (the Chapter 4 story note is gone); `--legends-test --stars 24
  --target 3 --difficulty hard` LEGENDS END 84/84, every Chapter 4 scene played. P12-18: play `legends_complete` once
  after `legends_next_finale_after` (in `Legends.after_result()`), before the chapter view / LEGENDS COMPLETE
- **P12-15** New Generation portraits (art B): `make_portraits_v2.py --legends next` (LG4, `next_kit()` follows the
  crews.json sheets once P12-14 adds them; until then the sample's parts), twelve `assets/portraits/lg_<six>[_happy].png`
  (about 196 KB), `docs/art/legends_next_portraits.png`. Firewall's thin flat lime visor with chrome temple ends; Glitch's
  chrome right forearm and hand raised, the ball on his index finger, violet wrist and knuckle seams, no star;
  Overclock's all-lime crop, no mask, his braces shown by their lime light from below (a halftone on the tank and a
  lime line under the jaw: proposal, owner may ask for a lower framing instead); Long Shadow's locs and wooden bead tie,
  Updraft's mohawk and raised hand with taped fingers, Halfcourt's freckles, sandy curls, white cotton headband.
  New parts opt-in (comic.py `glow()` / `reglow()` / `tint()`; hair `mohawk` / `two_tone` / `locs_up` and the extras
  `visor`, `raised_hand`, `brace_glow` in `cast_member`): a full rerun gives all 143 older portraits and sheets byte
  for byte the same (md5). `--legendtest` OK, no portraits note for Chapter 4
- **P12-05** New Generation era parts, cyber parts and the look sample: `make_players.py` "Phase 12 era parts"
  (opt-in: `leg_braces`, `chrome_arm`, `visor`, hair `two_tone` / `locs_up`, `cotton_band`, `low_cut`, `tape_fingers`,
  `wristband`, `freckles`), `pixel3d.py` `FLAT` `glow_lime` / `glow_violet` and `CHROME`, `crews.json` `ERA4_*`;
  sample `docs/art/legends_next_sample_v1.png` / `.gif` (`make_players.py --legends-sample next`). Renderer checks 0
  problems, ANIM OK, `assets/` untouched, all 71 older sheets' test frames byte for byte the same. For owner check 1
- **P12-02** (gameplay A, on the branch): `docs/legends-namecheck.md` "Chapter 4 (P12-02): first check" and the
  P12-02 list additions (2024-2026 drafts, young stars and nicknames, dunk contest, Japan, Europe, shoe lines, famous
  fictional cyborgs and robots and their looks). Step 1: `nba_api` 1.12.0 (Oct 21 2026, 6,426 entries, holds the 2026
  class). All six pass the hard rule and the data test's rules (Python dry run of `name_hit()`: six pass, the 18
  shipped still pass, 7 new probes fail); numbers pass. **One fail of our own rule, not applied**: Emrys is 2 letters
  from Earl (Earl "Mayor" Pruitt, `cities.gd`); owner: keep Emrys, or Leander (12.9) or Emrys. `--legendtest` OK
  (doc only, nothing else changed)
- **P12-03** Four built chapters in the Legends logic and tests (gameplay-programmer B): `stand_in_test_data("next")`
  (ids `lg_zz_next_1..6`), `--legends-test-four` (wins over `-three` / `-two`), `Legends.self_test()`
  `_check_four_chapters()` (gate 72 / 48, max tokens 84, the walk over four eras; `SHIPPED_GATES` holds `next`, and a
  build with Chapter 4 built passes too, so P12-11 needs no test change). `--legendtest` OK; `--legends-test --stars 24
  --target 3` and `--legends-test-three` byte for byte as before; `--legends-test-four` Hard 84/84 and Normal `--stars
  72` 56/84 end "next is the last chapter", LEGENDS END; `--backtest` OK, `--trip-test` (unlock-all, 48 stars) TRIP END,
  `--titletest` DONE

- **P12-08** Era music listening list (art-audio A): `docs/audio_preview/LIST.md` "Legends: New Generation", five
  30 s samples `docs/audio_preview/next_a..e_*.ogg` (-20.0/-20.1 LUFS, 241-267 KB each, 1.26 MB together), all
  OpenGameArt, each license read on its page: Escalate (congusbongus, CC-BY 3.0, ~167 bpm), Hammer (yubatake, CC-BY
  4.0, 170), Fever Stadium (MintoDog, CC0, 165), Ramming Speed (congusbongus, CC-BY 4.0, ~167), Neon Hyperdrive
  (adiutorium, CC0, ~140). Art-audio's pick: Ramming Speed; Hammer if the owner wants no 4th congusbongus track.
  For the owner to pick (P12-20)
- **P12-11** Chapter 4 data and the name check in the data (gameplay-programmer A): the `next` row built (FAST BREAK,
  `era_next` twist / look, music `legends_next`, fallback `newyork`, gate 72 / 48, crew THE NEW GENERATION `balanced`
  `ERA4_NIGHT` / `ERA4_LIME`, finale Overclock, Updraft, Halfcourt, 75 / 14 / 66); the six legends (Emrys Halfcourt),
  the six perks as data, P12-02's list additions in `REAL_NICKNAMES` / `REAL_NAMES`, "not in my house", the one-word
  `CYBER_WORDS` check in `name_hit()`, 8 new probes; the namecheck doc's Chapter 4 table final. **Needs two test-only
  fixes outside the row** (in the report, verified in a scratch copy): `legends.gd` `_check_stand_in_chapters()` and
  `era_teams.gd` `self_test()` still assumed Chapter 4 unbuilt; with them `--legendtest` OK (24 legends, 84 tokens),
  without them 2 fails. `--legends-test --stars 24 --target 3 --difficulty hard` LEGENDS END 84/84; `--titletest` DONE;
  `--backtest` OK (`--titletest --legends-unlock-all --stars 72` fails until P12-06's `era_next` court row lands)
- **P12-12** The era rules (gameplay-programmer B): twist `era_next` "FAST BREAK" in `twists.gd` (`speed_mult` 1.05,
  `stamina_refill_mult` 1.15, new `dead_ball_mult` 0.6 and `break_mult` 1.10, both 1.0 in `DEFAULTS`), `rules.gd`
  `dead_wait()` on `MADE_WAIT` / `OOB_WAIT` / `FOUL_WAIT` (made field goals in main.gd, made last free throws, out of
  bounds, reaching fouls), `main.gd` `BREAK_WINDOW` 5.0 and `in_break_window()` (the shooter's team got the ball, i.e.
  the shot clock restarted, at most 5 s ago) in `shot_probability()` (the CPU's shoot odds read it too), the TWIST line's
  early / later shots and dead-ball seconds (counted only under the twist), and the banner icon (a ball with lime speed
  lines and violet chevrons). TWISTTEST OK, LEGENDTEST OK; seeded A/B against the base build byte for byte: `--autoplay`
  with no twist and each of the 10 older twists, `--humantest`, `--force-fouls`, `--challenge steeple` / `rooftop` /
  `deep_end`. 24 seeded `--autoplay --twist era_next` games vs 24 without (same seeds): game 8.9 vs 9.0 min, dead balls
  22 vs 34 s, shots 56.8 vs 56.0, FG 57.9% vs 56.0%, all ended, no errors; early shots 30% of shots. `--humantest
  --twist era_next` 21-19, the `--twistshots` banner checked
- **P12-20** Era music in the game (art-audio C): `assets/music/legends_next.ogg` = Escalate (congusbongus, CC-BY
  3.0, license re-read on its page), the page's loop file whole (130.55 s, 17 phrases of 7.68 s), de-clipped like
  Bebop (the master's 0.13% clipped samples rebuilt with adeclip), 5 ms wrap blend (wrap step 0.002), mono, -20.8 LUFS
  (peak-limited, true peak -1.1 dBFS, no limiter), q3, 1.20 MB; recipe in `tools/make_music.sh`; CREDITS.md row and
  `CREDITS_LIST` entry; music keys were already `legends_next` (court_looks.gd comment updated). `--titletest` DONE
  (7 CC-BY rows, 7 shown), `--legendtest` OK (no music note), `--challenge lg_overclock --autoplay` music `legends_next`

## Done
- **P12-09** Midrange's skin brown on his sheet and card (before the phase; ANIM OK, LEGENDTEST OK)
- **P12-10a** Rooftop's cradle dunk preview `docs/art/cradle_v1.gif` (before the phase)
- **P12-10b** The cradle on Rooftop's sheet (before the phase: a `cradle` extra, 12 frames, on `lg_rooftop_x0.png`
  only, `EXTRA_LANE` 0; player.gd `CRADLE_ANIM` when `Sheets.has_anim()`, else the windmill; counted `anim_cradle`;
  sheets.gd alias `cradle` -> windmill; no sim change; ANIM OK, `--anim-fake-v2` OK, LEGENDTEST OK, `--challenge
  rooftop` 3 SIGNATURE cradle lines, `anim_cradle` 2). The owner sees the gif at the second look check.

## Tasks by wave
Format: **id** | title | owner | files it may touch | done when | waits for.

### Wave 1 (can start now)
- **P12-02** | REVIEW | Name list for the new generation and the check of the six (12.9)
  | gameplay-programmer A | `docs/legends-namecheck.md` only
  | The lists gain the 2024-2026 draft classes, today's young stars and their nicknames, dunk contest names, current
  Japanese and European players, shoe and product lines whose names could be a nickname ("Hyper...", "Zoom", ...),
  and **famous fictional cyborgs and robots** (film, games, comics: names and their signature looks, e.g. a metal arm
  with a star, a red visor, a gold visor band). Then a "Chapter 4 (P12-02): first check" section for 12.9's six
  (Tavian "Overclock" Brightwell, Calder "Long Shadow" Ostrander, Cosimo "Glitch" Draycott, Silvan "Updraft" Ingleby,
  Emrys "Halfcourt" Tregarth, Kasimir "Firewall" Oyelaran): the `nba_api` step, 1-letter near misses, first names
  within 2 letters of a game name, the nicknames against brands and fictional characters, the look combinations in
  words (the five real-player sets **and** the cyborg looks), the numbers 17 / 56 / 25 / 57 / 39 / 51, and a short
  summary for the owner. A name that fails comes with two passing alternatives (12.9 lists backups) | none
- **P12-03** | Four built chapters in the Legends logic and tests
  | gameplay-programmer B | `scripts/legends_data.gd` (test helpers only), `scripts/legends.gd` (`self_test()` only),
  `scripts/legends_test.gd`
  | `stand_in_test_data("next")` works (ids `lg_zz_next_1..6`), and a new `--legends-test-four` flag builds the 4th row
  as a stand-in. `Legends.self_test()` holds four built chapters with the stand-in (gates 72 stars / 48 tokens, max
  tokens 84, finales, unlocks, the swap and mentors over four eras, round trip). The `--legends-test` driver ends
  cleanly after the **last** chapter (no next-gate check when there is none). Shipped output is byte for byte the same
  as before: `--legendtest` OK, `--legends-test --stars 24 --target 3` LEGENDS END, and the three-chapter run
  unchanged | none
- **P12-05** | New Generation era parts, the cyber parts and a look sample
  | art-audio-integrator A | `tools/art/make_players.py` ("Phase 12 era parts"), `tools/art/pixel3d.py` (new `FLAT`
  glow tones and the chrome ramp only, opt-in), `tools/art/crews.json` (`ERA4_*` palettes only),
  `docs/art/legends_next_sample_v1.png` / `.gif`
  | Era parts: lime-dyed crop, two-tone hair, mohawk (or the existing one), locs tied up with a bead tie, sandy curls +
  cotton headband, buzz cut, modern low-cut shoes, taped fingers. Cyber parts as in the contract (leg braces, chrome
  forearm and hand, visor; lime and violet static glow, chrome ramp), opt-in. Palettes: lime + violet on near-black.
  The sample shows **Glitch** (cyber) and **Halfcourt** (natural) in their kit and in your colors next to today's
  ud_deuce, plus a parts row with the other four (Overclock's braces and Firewall's visor at game size and 2x, so the
  owner judges how they read), idle and run. Each part's tie to its move in one caption line. Renderer checks 0
  problems, `--anim-test` ANIM OK, nothing in `assets/` changed, every older sheet byte for byte the same if
  regenerated. For the owner's first check | none

**Owner check 1 after wave 1**: the six names and nicknames (P12-02), which three are cyber and how the parts look,
the era colors (P12-05's sample), the numbers, and 12.9's picks R1-R4 (the finale three, a CYBER / NATURAL tag or
none, static glow). The lead writes the answers into the contract and VISION.

### Wave 2 (after owner check 1)
- **P12-05b** | REVIEW | Glitch's combo dribble: the preview
  | art-audio-integrator B | `tools/art/make_players_v2.py` (a `combo` EXTRA row, carried by no sheet yet),
  `docs/art/combo_v1.gif`
  | Between the legs into behind the back next to today's crossover, 5 directions, on a stand-in body **with the chrome
  forearm** (P12-05's part), the violet seams visible through the move; the crossover's timing so the sim is
  unchanged; 0 hand/ball check problems; `format.json` and every sheet unchanged. For owner check 2 | P12-05 merged,
  owner check 1
  | Result: `combo` EXTRA row (12 frames, 320 ms like `cross`, lane 0, no sheet carries it), gif on the look
  sample's Glitch (5 directions + W mirrored, crossover row under it, a 4x band SE / E / W); 0 check problems;
  format.json unchanged. Note for P12-14 / P12-17: two hand switches, so it ends in the hand it started in
  (`hand_end` "R"), unlike `cross` ("L"): the game must keep the ball hand on his combo, or say otherwise. Lead: (a) the game keeps the ball in his starting hand after a combo (P12-17; the hand side only, the crossover's beat and timing unchanged)
- **P12-06** | The New Generation court: a made-up arena of the future
- **P12-06** | REVIEW | The New Generation court: a made-up arena of the future
  | art-audio-integrator C | `tools/art/make_courts.py` (`--era next`), `assets/courts/era_next_*`,
  `scripts/court_looks.gd` (the `era_next` row)
  | Dark glass floor, lime glowing lines, an edge light, chrome rails, hanging violet light rings, a dark crowd with
  phone lights. No word, digit or logo; it does not read as MIDNIGHT or BIG STAGE. Era colors from owner check 1.
  Checked in angled and flat shots; `--era` rewrites the older era files byte for byte; not in the COURT list. A name
  proposal (first idea NEON DOME) for owner check 2 | P12-05 merged, owner check 1
  | Result: `era_next` "NEON DOME" (name for owner check 2), music `legends_next` (fallback `newyork` until P12-20);
  floor 1995 B, backdrop 13500 B; owner sheet `docs/art/era_next_preview.png` (`--era next --era-sheet DIR`: angled,
  flat, tiles, MIDNIGHT and BIG STAGE beside it); `--era` keeps the older era files byte for byte; `--legendtest` OK,
  `--titletest` OK; with `--legends-unlock-all --stars 72` the court is listed after BIG STAGE and only the twist
  checks fail until P12-12's `era_next` twist lands (a scratch stub twist: TITLE TEST DONE)
- **P12-08** | REVIEW | Era music listening list
  | art-audio-integrator A | `docs/audio_preview/LIST.md` ("Legends: New Generation"),
  `docs/audio_preview/next_*.ogg`
  | 3-5 fast chiptune or electro tracks (160-175 bpm, bright synth leads, a futuristic "machine" feel; not New York's
  track, Bebop, Headspin or Techno drive), CC0 or CC-BY only, each license link checked on its page, 30 s samples at
  -20 LUFS. The owner picks one | none

### Wave 3
- **P12-11** | REVIEW | Chapter 4 data and the name check in the data
  | gameplay-programmer A | `scripts/legends_data.gd`, `docs/legends-namecheck.md`
  | The `next` row built as in the contract (music `legends_next`, fallback `newyork` until P12-20), the six legends as
  owner check 1 left them (ids, names, numbers, shapes, challenges, signatures, looks with the cyber parts, bios), the
  six perks as data, and the new names, probes (a cyborg name or two among them) and numbers in the lists. The
  namecheck doc's Chapter 4 table is final. `--legendtest` LEGENDTEST OK (notes for art not there yet). 24 legends,
  max tokens 84 | owner check 1, P12-02, P12-03 merged
- **P12-12** | REVIEW | The era rules
  | gameplay-programmer B | `scripts/twists.gd`, `scripts/rules.gd` (the `dead_ball_mult` hook), `scripts/main.gd`
  (the `break_mult` hook, `BREAK_WINDOW`), `scripts/twist_fx.gd` (the banner icon)
  | `era_next` as in the contract; `--twisttest` TWISTTEST OK; twist `none` and every older twist give byte-identical
  seeded `--autoplay` logs; 8+ `--autoplay --twist era_next` games all end; the banner and icon shown in a
  `--twistshots` shot | P12-03 merged
- **P12-01** | REVIEW | Phase 11 save fixtures
  | qa-balance-tester | `docs/qa/fixtures/` (new files only) and its README
  | `legends_v1_ch3_mid.json` (Chapters 1-2 closed, 3 Present beaten, a Present mentor), `legends_v1_ch3_done.json`
  (three chapters closed, 63 tokens), `trip_v2_present.json` (a drafted Present legend starting next to a boss),
  `settings_v2_72_present.cfg` (named so, `settings_v2_72.cfg` is P9-01's). A check script like the Phase 11 one. P12-27 loads them into the Phase 12 build | none
  | Result: written by d298d22 (`make_fixtures_v5.gd.txt`, story F); the settings file is `settings_v2_72_present.cfg`
  (`settings_v2_72.cfg` is P9-01's). `check_fixtures_v5.gd.txt` CHECK OK in d298d22 and in the head (39a20bc);
  `--trip-test --trip-resume` on the trip: TRIP END complete in both, no errors

**Owner check 2 after wave 3**: the combo dribble preview (P12-05b), the cradle gif (P12-10a, done), the court and its
name (P12-06), the music pick (P12-08).

### Wave 4 (after owner check 2)
- **P12-07** | REVIEW | Legends UI art for Chapter 4
  | art-audio-integrator C | `tools/art/make_legends_ui.py`, `assets/legends/frame_next.png`, `pin_next.png`,
  `pin_next_done.png`, `ui.json`, `timeline.png`, `docs/art/legends_ui.png`
  | In the chosen era colors (a chrome edge on the frame is fine). The 4th timeline panel shows the court lit. Chapters
  1-3 files byte for byte unchanged; `--legendtest` OK | owner check 2, P12-06 merged
  | Result: `frame_next` (black glass band with a violet lattice, chrome bevel, lime LED strip, a violet light ring
  on top, NEON DOME in the window, lime plate), `pin_next` (violet medallion, lime bolt in a lime LED ring) and
  `pin_next_done` (gold); `pin_next_locked` kept byte for byte (same bolt). The 4th timeline panel shows NEON DOME lit
  (only x 478-635 of `timeline.png` changed). `ui.json`: `next` pins and frame, new `"colors": {"next": {"title":
  "#b8ff3a", "plate_text": "#16151d"}}` (plate text 10.1:1 on the lime plate). Every Chapter 1-3 file md5-identical.
  `--legendtest` OK; xvfb shots of the timeline (72 and 48 stars), the Chapter 4 view and the Hall checked. For the
  lead: the lineup LEGEND tag (gold text, no outline, on `ui_color` #6da321) is 2.1:1, below the Present's 3.8:1; a
  darker lime `ui_color` like #466e14 gives 4.1:1 (legends_data.gd, not this row). No LEGENDS COMPLETE / full Hall
  banner art (not in this row)
- **P12-14** | REVIEW | The six New Generation sheets (+ the combo extra)
  | art-audio-integrator A | `tools/art/make_players_v2.py`, `tools/art/crews.json`, `assets/players2/lg_<six>*`,
  `assets/players2/format.json`, `assets/players2/hands.json` (only if needed), `scripts/sheets.gd` (`ALIASES`)
  | Six sheets with palettes, `_crew`, `_crew_j1..3`, cards; the cyber parts on Overclock, Glitch and Firewall only,
  their glow the same in every recolor; the natural three with no chrome or glow pixel; the strip
  `docs/art/legends_next.png`; the `combo` extra on `lg_glitch` only (listed in `"extra"`, own lane); no older sheet
  changes byte for byte; `--anim-test` ANIM OK | owner check 2, P12-11 merged
- **P12-15** | REVIEW | The New Generation portraits
  | Result: crews.json crew `NG` (six `draft` entries from the sample's `NEXT_LOOKS`, `crew_recolor` `NG` = the
  sample's map; hair lime / platinum, wood, cotton, tape out of it), `--legends-strip next`, sheets.gd `combo` -> `cross`.
  The idle S and run dribble SE frames match the approved sample pixel for pixel (era and your colors). Chrome and
  glow: 7 palette entries on each cyber sheet, the same in all 5 palettes; 0 on the natural three. `combo` on
  `lg_glitch_x0` col 0, `hand_end` "R". Only additions in format.json / hands.json / palettes.json, no older file
  touched. 0 render check problems; ANIM OK (352 sheets), `--anim-fake-v2` OK, `--legendtest` OK (no sheet note).
  2.04 MB of sheet files (+ 29 KB jerseys)
- **P12-15** | The New Generation portraits
  | art-audio-integrator B | `tools/art/make_portraits_v2.py`, `tools/art/comic.py` (new opt-in kit parts only),
  `assets/portraits/lg_<six>*`, `docs/art/legends_next_portraits.png`
  | Twelve portraits (neutral, happy) in the era kits; the visor on Firewall, the chrome hand on Glitch (raised, the
  ball on his fingers), Overclock's braces shown by a lower framing or their glow; the natural three clearly natural.
  New kit parts are opt-in, so older portraits stay byte for byte the same | P12-11 merged, owner check 1

### Wave 5
- **P12-16** | REVIEW | Chapter 4 story and the end of the mode
  | gameplay-programmer C | `scripts/story_text.gd`, `scripts/story.gd` (only if a scene needs it)
  | The intro, six unlock scenes, the finale before/after, `RECRUIT_LINES` for the six, and `legends_complete` with a
  legend of each era (the contract's Story row). Each cyber part gets its origin in a line, as a tool he earned or
  built; the naturals' lines tie them to the old courts. No slogan or banned word (`--legendtest` checks the text).
  Lines that name a goal number use the data's numbers | P12-11 merged
- **P12-17** | Signature moves
  | gameplay-programmer A | `scripts/player.gd`, `scripts/defense.gd`, `scripts/ball.gd`
  | The six moves, constants at the top (block "P12-17"), each only for its signature and at the size in the contract
  (no extra edge for a cyber part); the `combo` frames on Glitch's crossovers when `Sheets.has_anim()` (counts
  `anim_combo`); `--signature` takes the new ids; no new input. Seeded A/B: `--autoplay`, every older era twist,
  `--humantest` and one `--challenge` per older chapter give byte-identical logs. Each move is seen in the Chapter 4
  `--challenge` runs and as the human | P12-12, P12-14 merged
- **P12-20** | REVIEW | Era music in the game
  | art-audio-integrator C | `assets/music/legends_next.ogg`, `tools/make_music.sh`, `CREDITS.md`, `scripts/title.gd`
  (`CREDITS_LIST` only), `scripts/court_looks.gd` and `scripts/legends_data.gd` (the music key only)
  | The owner's pick, looped, about -20 LUFS, mono; a credits row (title, author, license link, source, changes);
  `--titletest` credits count right; `--challenge lg_overclock` plays it | the music pick, P12-11 merged

### Wave 6
- **P12-18** | REVIEW | Chapter flow, the gate and the ending
  | gameplay-programmer B | `scripts/legends.gd`, `scripts/legends_tour.gd`, `scripts/hall.gd`
  | `self_test()` holds the four shipped chapters (`SHIPPED_CHAPTERS` 4, gate 72 stars / 48 tokens). The chapter walk
  covers Chapter 4 (shut at the Present's gate, open at its own). After the Chapter 4 finale's after scene comes
  `legends_complete` once, then LEGENDS COMPLETE on the timeline (the header or a banner, no new panel) and a full-Hall
  banner; replays never play it again. A CYBER / NATURAL tag only if owner check 1 asked for one. No "next" string in
  the logic. `--legendtest` OK; `--legends-test --difficulty hard` LEGENDS END (84/84) | P12-11, P12-16 merged
- **P12-19** | REVIEW | Draft and lineup with four eras
  | Result: no logic change needed (rows, colors, frames and the limit all read the data); the 4th row "UNLOCKED IN
  LEGENDS - THE NEW GENERATION" shows last in `frame_next` and #466e14, the gold LEGEND tag reads on it (about 4.2:1)
  on the draft and the lineup. trip.gd `_check_each_era()`: per built era a fresh trip, its row (order, color, ids), its
  first legend drafted (sheet, signature), refused next to one legend of each other era, starts with a boss as YOU,
  kept by a save while locked; a save with an `lg_` id this build doesn't know loads without him (a legal three
  starts), the way a Phase 11 build reads a New Generation draft. Headers in draft.gd / lineup.gd. `--triptest-data`
  (and `--load`) OK, `--trip-test --target 3 --legends-unlock-all --stars 48` TRIP END (4 rows offered, drafts present
  -> fathers -> grand as P12-24's driver still wants), plain `--trip-test --target 3` TRIP END, `--legendtest` OK,
  `--backtest` OK. `LEGEND_DRAFT_CHAPTERS` left to P12-24
  | gameplay-programmer C | `scripts/trip.gd`, `scripts/draft.gd`, `scripts/lineup.gd`
  | A 4th LEGENDS row ("UNLOCKED IN LEGENDS - THE NEW GENERATION", timeline order, era frame and color); the one-legend
  rule over four eras; the trip self test expects a row per built chapter; a Phase 11 build drops a New Generation
  legend safely (P12-27 checks) | P12-11, P12-14 merged
- **P12-21** | REVIEW | QA: the era rules
  | qa-balance-tester | `docs/qa/phase12-era.md`, `scripts/twists.gd` (`era_next` numbers only)
  | 200+ `--autoplay --twist era_next` games against Phase 11's bands: game length, shots, early-possession shots,
  make rate, fouls, rebounds; the numbers tuned if the era doesn't feel faster or the stats leave the bands (with the
  owner's yes) | P12-12, P12-17 merged

### Wave 7
- **P12-22** | Mentor perks for the New Generation
  | gameplay-programmer A | `scripts/player.gd`, `scripts/main.gd`, `scripts/defense.gd`, `scripts/ball.gd` (only if a
  hook lives there)
  | The six hooks, each a default that is today's game; `--perk` takes the new ids, with a `PERK` line the first time
  each changes a play; seeded A/B without a new perk byte-identical | P12-17 merged
- **P12-23** | QA: Chapter 4 challenges and finale
  | qa-balance-tester | `docs/qa/phase12-challenges.md`, `scripts/legends_data.gd` (challenge numbers and rating
  keys only)
  | Per challenge and the finale, Easy / Normal / Hard with the end-of-trip crew (`--expected-roster`,
  `--best-roster`), cells big enough to see Q3 a's bands (Normal about 45%, Hard about 30-35%, the finale a bit harder
  than Chapter 3's 53% / 33%); Firewall the hardest; the cyber legends no harder than the natural ones beyond their
  goal; any story line made stale listed for P12-29 | P12-17, P12-18 merged
- **P12-24** | Trip test: a drafted New Generation legend
  | gameplay-programmer C | `scripts/trip_test.gd`
  | `LEGEND_DRAFT_CHAPTERS` next -> present -> fathers -> grand (the first legend draft signs a New Generation legend
  from his row); refusals across eras; legend + boss starts; TRIP END checks every built chapter's row | P12-19 merged

### Wave 8
- **P12-25** | Back test and title test for Chapter 4
  | gameplay-programmer C | `scripts/main.gd` (the backtest steps only), `scripts/title.gd` (the titletest driver only)
  | `BACKTEST_CHAPTER4` "next" (its view, the Hall and back, the mentor picker, a challenge's pause, resume and QUIT;
  its gate forced for the run unless `--stars 72` or `--tokens 48`); `--titletest` era checks with four era teams and
  courts; BACKTEST OK, TITLE TEST DONE | P12-18, P12-22 merged
- **P12-26** | QA: the ramp with New Generation legends and perks
  | qa-balance-tester | `docs/qa/phase12-ramp.md`, `scripts/legends_data.gd` (perk numbers only)
  | `--best-roster` with a New Generation legend and the strongest new perks: Hard RED share against Phase 11's 44%;
  each perk measured at about 2 stat points, resized with the owner's yes | P12-22, P12-23 merged
- **P12-33** | REVIEW | The 4th era team and its court in Quick Game
  | gameplay-programmer B | `scripts/era_teams.gd` (self test expectations; logic only if the data needs it),
  `scripts/menu.gd` (only if the COURT order needs it)
  | `new_generation` opens with its finale three; `--quick-teams new_generation,grandfathers` works; the court follows
  BIG STAGE on COURT with FAST BREAK and its music; `--legendtest` "era teams" OK | P12-11, P12-20 merged

### Wave 9
- **P12-27** | QA: saves | qa-balance-tester | `docs/qa/phase12-saves.md` | P12-01's fixtures load in the Phase 12 build;
  Phase 12 files open in a Phase 11 build without a crash (unknown ids dropped); a NEW TRIP never touches
  `legends.json` | P12-19, P12-18 merged
- **P12-28** | QA: screens | qa-balance-tester | `docs/qa/phase12-screens.md` and shots | Every Legends screen at
  1280x720 and wider with four chapters (timeline, Chapter 4 view, Hall with four rows, draft rows, LEGENDS COMPLETE),
  the six moves and the combo dribble, the cyber parts readable at game size in angled and flat view (and in your
  colors), the court and banner; bugs filed as P12-B<n> | P12-25 merged
- **P12-36** | QA: era team balance | qa-balance-tester | `docs/qa/phase12-quick-eras.md` | NEW GENERATION vs the crews on
  Hard and vs each era team (Grandfathers vs New Generation on both era courts), 200+ games a cell; a report for the
  owner, no change without his yes | P12-33 merged

### Wave 10
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

## Parallel plan (never two tasks on the same file in one wave; at most 3 agent tasks a wave)
| Wave | Tasks (agent) | Files | Notes |
|---|---|---|---|
| 1 | P12-02 (gameplay A), P12-03 (gameplay B), P12-05 (art A) | namecheck doc / legends_data.gd helpers, legends.gd self_test, legends_test.gd / make_players.py, pixel3d.py, crews.json ERA4, sample | then **owner check 1**: names + look sample |
| 2 | P12-05b (art B), P12-06 (art C), P12-08 (art A) | make_players_v2.py, combo gif / make_courts.py, courts, court_looks.gd / audio_preview | P12-05b and P12-06 after check 1 |
| 3 | P12-11 (gameplay A), P12-12 (gameplay B), P12-01 (qa) | legends_data.gd, namecheck doc / twists.gd, rules.gd, main.gd, twist_fx.gd / fixtures | then **owner check 2**: combo, court, music |
| 4 | P12-07 (art C), P12-14 (art A), P12-15 (art B) | make_legends_ui.py, assets/legends / make_players_v2.py, crews.json, players2, format.json, sheets.gd / make_portraits_v2.py, comic.py, portraits | |
| 5 | P12-16 (C), P12-17 (A), P12-20 (art C) | story_text.gd, story.gd / player.gd, defense.gd, ball.gd / music, make_music.sh, CREDITS.md, title.gd CREDITS_LIST, court_looks.gd + legends_data.gd music key | |
| 6 | P12-18 (B), P12-19 (C), P12-21 (qa) | legends.gd, legends_tour.gd, hall.gd / trip.gd, draft.gd, lineup.gd / docs + twists.gd numbers | |
| 7 | P12-22 (A), P12-23 (qa), P12-24 (C) | player.gd, main.gd, defense.gd, ball.gd / docs + legends_data.gd numbers / trip_test.gd | |
| 8 | P12-25 (C), P12-26 (qa), P12-33 (B) | main.gd backtest, title.gd titletest / docs + legends_data.gd perk numbers / era_teams.gd, menu.gd | P12-26 after P12-23 merged |
| 9 | P12-27, P12-28, P12-36 (qa x3) | docs only | |
| 10 | P12-29 (C), then P12-30 (qa), then P12-31 (lead), P12-32 (coordinator) | docs / docs / docs / build output | |

Chains to watch:
- `legends_data.gd`: P12-03 (helpers), P12-11 (rows), P12-20 (music key), then numbers only in P12-23 and P12-26.
- `make_players.py` / `pixel3d.py`: P12-05 (parts), then read by P12-05b and P12-14.
- `make_players_v2.py`: P12-05b, then P12-14. `crews.json`: P12-05 (ERA4 palettes), then P12-14.
- `player.gd`: P12-17, then P12-22. `main.gd`: P12-12, P12-22, P12-25.
- `court_looks.gd`: P12-06, then the music key in P12-20.
- `title.gd`: P12-20 (`CREDITS_LIST`), P12-25 (titletest), P12-29.
- `legends.gd`: P12-03 (self_test), P12-18.
- Each task is merged before the next one on its chain starts.

## Open questions for the owner
- At owner check 1 (`docs/legends-plan.md` 12.9): R1 the six names and which three are cyber; R2 the finale and era
  team three (Overclock, Updraft, Halfcourt, or Glitch in for Overclock); R3 a CYBER / NATURAL tag on the Hall and
  draft cards or none; R4 static glow or a pulse later. Also the era colors and the numbers.
- At owner check 2: the combo dribble, the court and its name, the music.
- Still open from Phase 11: the Techno drive loop point (the owner listens).
