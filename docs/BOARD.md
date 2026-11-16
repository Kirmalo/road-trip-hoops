# Task Board

Current phase: **Phase 3: rules and format** (planned 2026-11-16 by `lead-producer`). The Phase 2 board (with the
P2.5 tuning round) is archived in `docs/board-phase2.md`, Phase 1 in `docs/board-phase1.md`.

Scope (from `docs/VISION.md`): first to 21 with streetball scoring (1 point inside the arc, 2 beyond); switch sides
when the first team reaches 11; fouls and free throws (reusing the shot meter); out of bounds; Easy / Normal / Hard.
Owner (Phase 2 check-in): today's CPU is too hard, so **today's CPU becomes Hard** and Normal and Easy are built below
it. Check game length: if a full-court game to 21 runs past about 8 minutes, the owner picks a fix (Q2).
Carried from Phase 2: B1 (the team attacking the right hoop scores ~0.7 points per game more; the side switch should
cancel it, and P3-02 also mirrors the absolute-y literals), and the crossover vs. assisted-defender question (for the
Phase 3 check-in, see the end of "Questions for owner").
Not in scope: title screen, trip map, cities, saving campaign progress (Phase 5); settings screen (Phase 7). The only
new screen is the minimal difficulty panel (Q7).

Format: `ID | task | owner role | files | done when | depends on`

Rules for every task in this phase:
- Godot 4.3 compatible; no `:=` with an untyped right side (`game.x`, `min`/`max`/`clamp`); use an explicit type or
  `minf`/`maxf`/`clampf`. Tuning constants go at the top of the script they belong to, with a comment. Touch first:
  joystick + A (orange) + B (blue) during play, no new in-game buttons. No new `.tscn` scenes: new scripts are built
  in code (`rules.gd`, `difficulty.gd`, `menu.gd`). Static vars are fine (Godot 4.1+).
- A task touches only the files listed. If it needs another file, stop and tell the coordinator.
- Every rule adds `stat(...)` counters (listed per task) so `--autoplay` proves the rule fires in CPU games and
  `--humantest` proves the human path runs. Per-team counters end in `_t0` / `_t1`; human-only ones start with
  `human_`. Scripted `--humantest` inputs live in `main.gd` only.
- **Games are longer now.** Run tests with `--quit-after 120000` (33 min at 60 fps) until P3-11 updates CLAUDE.md.
  `--autoplay` (3 games) and `--humantest` (1 game) must still reach `FINAL` with no script errors. Until P3-04
  measures the new normal, report per game: final score, shots, `GAME LENGTH`, and the task's own counters.
- Each design choice the owner hasn't made yet is a **constant** with the recommended option as its default, so an
  answer only changes constants (or adds a small follow-up the task lists).
- Call into another task's code by the names in "Shared contract". If that code isn't merged yet, guard the call
  (`if game.rules != null and game.rules.has_method("call_foul"):`) so each task merges on its own.

## Shared contract (names fixed now so parallel tasks can call each other)

`rules.gd` (new, P3-01; `extends Node`, `var game`, created in `main._ready()` as `game.rules`). Owns the score, the
format, possession changes after dead balls, fouls and free throws. `main.gd` keeps the loop, HUD, input routing,
steals and the humantest script.
- Constants (P3-01): `TARGET_SCORE := 21`, `WIN_BY := 1` (Q1), `GAME_TIME_CAP := 0.0` (seconds; 0 = no time limit,
  Q1), `SWITCH_AT := 11` (P3-02). Test-only command-line override `--target N` (switch at `(N + 1) / 2`).
- `func points_for(shooter, hoop: Vector2) -> int`: 2 beyond the arc (`game.is_three()` keeps its name and means
  "beyond the arc"), else 1. Free throws are 1.
- `func add_score(team: int, pts: int, kind: String)`: the only place `game.score` changes; checks the side switch
  (P3-02) and the win; `kind` is "shot", "dunk", "layup", "ft".
- `func is_game_point(team: int) -> bool` (HUD).
- `var sides_swapped := false` (P3-02); `game.attack_hoop(team)` and `game.in_frontcourt(pos, team)` read it.
  Nothing else may hard-code "team 0 attacks right".
- `func dead_ball(next_team: int, wait: float, spot := Vector2.INF)` and `func inbound(team: int, spot := Vector2.INF)`
  (moved from main's `_dead_ball` / `_inbound`; `Vector2.INF` = the baseline under the hoop the team defends, as today).
- Fouls (P3-05): `func call_foul(defender, fouled, kind: String) -> void`, kind "shooting" or "reach" (and "drive" if
  Q3 = c). A shooting foul during a shot waits for the shot's result (`pending_foul`), then free throws or an and-one.
- Free throws (P3-05): `var ft_active := false`, `var ft_shooter = null`, `var ft_left := 0`,
  `func ft_spot(p) -> Vector2` (where each player stands during free throws), `func ft_released()` (the shooter let
  go). `main.release_shot()` asks `rules.ft_active` and scores a free throw with `FT_*` odds (no contest, no blocks).
- Out of bounds (P3-07): `func ball_out(pos: Vector2, last_team: int)`.
- `main.gd` (P3-01): `func on_game_over(winner: int)` (P3-08 shows the panel from here) and `func start_game()`.

`difficulty.gd` (new, P3-03; `extends RefCounted`, used through `preload`, no instance needed):
- `const EASY := 0`, `NORMAL := 1`, `HARD := 2`; `static var level := HARD` (survives `reload_current_scene()`).
- `static func value(team: int, key: String, hard_value: float) -> float`: returns `hard_value` for the human's team
  (team 0) and on Hard; on Normal/Easy scales or replaces it from the `LEVELS` table. Only the other team changes.
- `static func level_name() -> String`, `static func load_saved()`, `static func save()` (`user://settings.cfg`,
  `ConfigFile`, key `difficulty`), `static func from_cmdline()` (`--difficulty easy|normal|hard`; autoplay and
  humantest default to `hard` so numbers compare with Phase 2).

`player.gd` (P3-06): `func at_free_throw() -> bool` (this player is `rules.ft_shooter`), CPU and human free-throw
behavior; `ball.gd` (P3-07): `var last_touch_team := -1`.

## Game length estimate (to check in P3-04)
Today (P2-13 final build): 60 shots, 37% FG, ~22 makes and 1.4 threes made per 8 minutes of game clock.
With 1s and 2s that is ~24 points per 8 minutes for both teams together. A game to 21 ends around 21-15 (P2 losers
score ~74% of the winner), so ~36 points: **about 12 minutes of play and ~90 shots**, plus dead-ball pauses (the game
clock stops during them today). To 15 (switch at 8): ~26 points, ~9 minutes. To 11 (switch at 6): ~6-7 minutes.
Free throws add a few points and a few stoppages. So games to 21 will very likely run past 8 minutes: Q2.

## Owner answers (2026-11-16, also in docs/VISION.md): every question got the recommended option
- Q1 game end: first to 21, 21-20 counts, no game clock or quarters, 24 s shot clock stays.
- Q2 length: test build to 21; Road Trip early cities 11, middle 15, late + tournament 21.
- Q3 fouls: bad timing only (badly timed block jump reaching the shooter, or poking a shielded ball), 3-6 per game.
- Q4 after a foul: 1 FT inside the arc, 2 beyond, and-one 1; reaching = sideline ball; missed last FT = live rebound.
- Q5 out of bounds: simple (only a loose ball crossing a line).
- Q6 Easy/Normal: the CPU is less sharp, not slower (shooting, reactions, timing, more fake bites, less help).
- Q7 picking the level: start + game-over panel with big EASY/NORMAL/HARD buttons, remembered.

## Owner answers
(none yet; the coordinator records them here and in `docs/VISION.md`)

## Todo

### Wave 1: can start now (no owner answers needed)

**P3-01 | Rules module, first to 21, 1s and 2s, game end | gameplay (A) | `scripts/main.gd`, new `scripts/rules.gd`**
- New `rules.gd` per "Shared contract". Move the score, `_dead_ball`, `_inbound`, `start_period`/`_end_period`
  logic into it. Scoring: `points_for` (2 beyond the arc, 1 inside); messages "BLUE SCORES" / "BLUE FOR TWO!",
  popups "+1" / "+2". Game end per Q1 option a (constants `TARGET_SCORE`, `WIN_BY`, `GAME_TIME_CAP` cover b and c):
  remove quarters, overtime and the game clock; the shot clock stays. BLUE has the first ball. "Tap to play again"
  still restarts (A reloads the scene) until P3-08.
- HUD: top-left shows "FIRST TO 21" (and "GAME POINT" in the team color when a team is one basket away), the score
  and the shot clock as now. `on_game_over(winner)` in main.gd prints the autoplay lines (`FINAL BLUE x - RED y`,
  the stats dict, a new `GAME LENGTH m:ss` line with all play time including dead-ball pauses).
- `--target N` test override in rules.gd.
- Stats: `points1_t0/_t1`, `points2_t0/_t1` (made baskets by value), `game_seconds`, `dead_seconds`,
  `possessions_t0/_t1`, `game_points` (times a team reached game point), `lead_changes`.
- Done when: 5 `--autoplay` games end at the target (winner 21 or 22, never past it), no quarter/OT text, shot-clock
  violations still rare; `--target 11` ends at 11-12; humantest reaches FINAL; screenshot of the new top bar; the
  report lists game length, shots and scores per game.
- Depends on: none. Q1 only changes constants.

**P3-02 | Switch sides at 11 (and B1) | gameplay (A, after P3-01) | `scripts/main.gd`, `scripts/rules.gd`**
- When a basket first brings a team to `SWITCH_AT` (11; `(TARGET_SCORE + 1) / 2` when `--target` is used): pause
  `SWITCH_PAUSE` 2.0 s, whistle, message "SWITCH SIDES", set `sides_swapped`, reset positions on the new halves, the
  team that was scored on inbounds as usual. Only once per game. `attack_hoop` and `in_frontcourt` follow the flag;
  check every caller in `player.gd`, `defense.gd`, `ball.gd` and `human_input.gd` reads hoops only through them
  (report any that don't; don't edit those files, list them for the coordinator).
- A small arrow next to BLUE in the top bar shows which way BLUE attacks; flips at the switch.
- B1 (QA R1): make the absolute-y literals in `reset_positions` and the inbound spot relative to the attack
  direction (mirror with `inward()`), so both halves play the same.
- Stats: `side_switches` (exactly 1 per finished game), `points_right_hoop`, `points_left_hoop`,
  `points_half1_t0/_t1`, `points_half2_t0/_t1`.
- Done when: every autoplay game has exactly one switch, at 11; after it both teams attack the other hoop (CPU offense
  spots, defense, fast breaks, lobs, rebounds all work: shots per team stay level in each half); humantest's human
  attacks the correct hoop after the switch; screenshot after the switch; 20 autoplay games list right-hoop vs
  left-hoop points.
- Depends on: P3-01 (same files).

**P3-03 | Difficulty plumbing (today's CPU = Hard) | gameplay (B) | new `scripts/difficulty.gd`, `scripts/player.gd`, `scripts/defense.gd`**
- New `difficulty.gd` per "Shared contract", with save/load in `user://settings.cfg`. Wrap every CPU skill constant
  Q6 might touch in `Difficulty.value(team, "key", CONST)` at the point of use: jump-shot quality
  (`CPU_SHOT_QUALITY_MIN/MAX`), crossover reaction (`CPU_CROSS_REACT_*`, `CPU_CROSS_BEAT_REACT`), jump reaction and
  chances (`CPU_JUMP_REACT_*`, `CPU_JUMP_CHANCE`, `CPU_JUMPER_JUMP_CHANCE`, `CPU_LOB_JUMP_CHANCE`), pokes
  (`CPU_POKE_CHANCE`, `CPU_POKE_ON_TIME`), `CPU_FAKE_BITE`, help defense (`HELP_SIDE`), and for Q6 b a `speed_mult`
  and `stamina_drain` key (1.0 on every level until answered). Hard returns today's values exactly.
- Placeholder table for Normal/Easy (multipliers on Hard, so a later Hard retune carries over), marked "until Q6":
  for example Normal shot quality x0.92, reactions +0.05 s, on-time pokes x0.7, fake bite x1.3; Easy about twice that.
- Stats: `difficulty_<name>` once per game.
- Done when: `--difficulty hard` (and no flag) gives the same numbers as today over 10 autoplay games (scores,
  steals, blocks, crossover beats within noise); `--difficulty easy` and `normal` make RED clearly weaker against the
  Hard BLUE CPU (report BLUE win share at each level over 10 games each); a saved level is read back after a restart.
- Depends on: none (values finalized in P3-10 after Q6).

**P3-04 | Game length check | qa | `docs/qa/phase3-length.md` (report only)**
- After P3-02 merges: 20 `--autoplay` games each at `--target 21`, `--target 15`, `--target 11`: real play time
  (`GAME LENGTH`), shots, final scores, 2-pointer share, B1 right vs left hoop points. Recommend the shot and score
  ranges for CLAUDE.md (P3-11) and give the coordinator the numbers for Q2.
- Done when: the report has a table per target and a one-line answer "a game to 21 takes about N minutes".
- Depends on: P3-02. Can run before any owner answer.

### Wave 2: needs Q3 and Q4

**P3-05 | Foul calls and the free-throw sequence | gameplay (A) | `scripts/rules.gd`, `scripts/main.gd`**
- `rules.call_foul` per "Shared contract": whistle, "FOUL!" popup on the fouler, dead ball. Shooting foul during a
  shot: `pending_foul`, resolved when the shot lands: made = and-one (1 FT), missed = free throws per Q4 (constants
  `FT_INSIDE` 1, `FT_BEYOND` 2, `FT_VALUE_MODE` "one_each" or "shot_value" for Q4 b, `BONUS_FOULS` 0 = off for Q4 c).
  Reach foul: the fouled team inbounds from the sideline at the ball's x (`rules.inbound(team, spot)`); the shot
  clock keeps running for the same team unless under `FOUL_MIN_CLOCK` 10 s (then reset to it).
- Free-throw sequence: players walk to `ft_spot(p)` (shooter at the line, 13.75 ft from the hoop center; two per side
  of the key, alternating teams; the rest behind the arc), `FT_SETUP_TIME` 1.0 s, then the shooter shoots; HUD
  "FREE THROW 1 OF 2". `main.release_shot` during `ft_active`: odds `FT_BASE` 0.72 x quality (perfect release 1.3,
  normal 1.0, bad 0.6; cap 0.95), 1 point, no contest, no blocks, no interceptions. Not the last FT: the shooter
  gets the ball back at the line. Last FT: made = other team's ball from the baseline, missed = live rebound (everyone
  is released when the ball leaves the hand). A human at the line who doesn't shoot within `FT_HUMAN_WAIT` 10 s
  shoots automatically at quality 1.0.
- The reach-foul trigger in `attempt_steal` (main.gd): a poke that reaches the handler while the ball is shielded
  (`steal_exposure` 0, Q3 a/c) fouls with `FOUL_REACH_CHANCE` 0.3 (constant `REACH_FOULS` false for Q3 b).
- Humantest (main.gd): at the line press A and release in the green zone on every 2nd free throw and early (charge
  0.5) on the others; count `humantest_ft_good` / `humantest_ft_early`.
- Stats: `fouls_t0/_t1` (committed), `fouls_shooting`, `fouls_reach`, `and_ones`, `ft_attempts_t0/_t1`,
  `ft_makes_t0/_t1`, `ft_last_misses`, `human_fouls`, `human_fouled`, `human_ft_attempts`, `human_ft_makes`,
  `human_ft_perfect`, `ft_timeouts`.
- Done when: autoplay fouls and free throws happen in every few games (shooting fouls arrive with P3-06), the score
  includes FT points, the game still ends at the target (a FT can win it); humantest has human FT attempts with good
  releases making clearly more than early ones; screenshot of the FT line-up.
- Depends on: P3-02 (same files), Q3, Q4.

**P3-06 | Player side of fouls and free throws | gameplay (B) | `scripts/defense.gd`, `scripts/player.gd`, `scripts/human_input.gd`**
- Shooting fouls (defense.gd): in `rim_blocker` and `check_jump_shot_block`, an airborne defender within reach whose
  timing is "bad" (Q3: too early, too late, or still up from biting on a fake) fouls with `FOUL_BAD_JUMP_CHANCE` 0.35
  instead of just missing; call `game.rules.call_foul(d, shooter, "shooting")` (guarded). Good timing never fouls.
  CPU defenders don't change their jumping to avoid fouls (difficulty may later). If Q3 = c, also the late step into a
  driver (`player.gd` close-guard check: a defender moving into the handler at > `FOUL_DRIVE_SPEED` inside 2 ft).
- Free throws (player.gd): while `rules.ft_active`, every player seeks `rules.ft_spot(self)` and stands still; no
  turbo, crossovers, pokes or block jumps; the CPU shooter shoots after `CPU_FT_WAIT` 0.8-1.4 s with quality
  `Difficulty.value(team, "ft_quality", ...)` random in `CPU_FT_QUALITY_MIN/MAX` (about 70-78% made). Human at the line:
  the normal meter; a short tap is ignored (no pump fake at the line).
- human_input.gd: during free throws A only shoots (shooter) or does nothing; B does nothing; `defense_action()`
  returns "-" while `ft_active`.
- Stats: `foul_bad_jumps` (bad-timed jumps that fouled), `cpu_ft_shots`, `human_ft_taps_ignored`.
- Done when: autoplay about 3-6 fouls per game for both teams together, split roughly evenly; CPU free throws ~70-78%;
  no player moves during a free throw until the last one is released; humantest human fouls > 0 and human free
  throws work; scores still end at the target.
- Depends on: P3-03 (`player.gd`, `defense.gd`), P3-05 for the free-throw state (guarded until merged), Q3, Q4.

### Wave 3: needs Q5 and Q7

**P3-07 | Out of bounds | gameplay (B) | `scripts/ball.gd`, `scripts/rules.gd`**
- ball.gd: track `last_touch_team` (holder's team on a catch; the defender's team when a steal or block knocks it
  loose, judged from the state before `make_loose`; the shooter's team on a rim-out). A LOOSE ball that crosses a
  sideline or baseline (instead of bouncing back) calls `game.rules.ball_out(pos, last_touch_team)`.
- rules.gd `ball_out`: whistle, "OUT OF BOUNDS" message, the other team inbounds from the nearest sideline spot (from
  the baseline if it went out there), shot clock reset on a change of possession, kept otherwise.
- Q5 b (full rule) would add the handler stepping out (`player.gd` movement and `main.clamp_to_court`): a separate
  follow-up task if chosen.
- Stats: `oob_t0/_t1` (team that lost it), `oob_after_steal`, `oob_after_block`, `oob_after_rebound`.
- Done when: autoplay about 1-4 out-of-bounds per game, no ball stuck on a line, no inbound from off the court;
  humantest runs; screenshot of a sideline inbound.
- Depends on: P3-05 (`rules.gd`), Q5.

**P3-08 | Difficulty panel | gameplay (A) | new `scripts/menu.gd`, `scripts/main.gd`**
- Per Q7 (option a): a CanvasLayer panel built in code with three large buttons (at least 200x110 px, finger-sized at
  1280x720) EASY / NORMAL / HARD, the remembered level lit; shown at launch (game waits) and after each game under the
  final score. Tap = `Difficulty.level = x`, `Difficulty.save()`, `reload_current_scene()`. First launch: Normal.
  Option b: skip the launch panel. Option c: a small top-bar button instead (no panel).
- `--autoplay` and `--humantest` skip the panel and use `Difficulty.from_cmdline()`.
- Stats: `menu_shown`, `menu_picks_<name>`.
- Done when: the panel works by touch in the web build (Playwright touch emulation: tap each level, the choice
  survives a reload); keyboard J/K or mouse also work on desktop; autoplay and humantest unchanged; screenshots of
  the launch and game-over panels.
- Depends on: P3-05 (`main.gd`), P3-03 (`difficulty.gd`), Q7.

### Wave 4: needs Q6; everything above merged

**P3-09 | CPU retune for 1s and 2s, fouls and Hard | gameplay (A) | `scripts/player.gd`, `scripts/defense.gd` (constants and small logic)**
- With 2 points beyond the arc the CPU's shot choice changes value: retune `CPU_THREE_*`, pull-ups and passes so
  2-pointers are 8-15% of shots at 28-35%. Tune `FOUL_BAD_JUMP_CHANCE` / `FOUL_REACH_CHANCE` (if needed via the
  coordinator for main.gd) to 3-6 fouls a game. Hard stays the Phase 2 CPU in feel: per 60 shots, blocks 4-7,
  steals 5-10, alley-oops 1-3, crossover beats 25-45%, few interceptions and shot-clock violations.
- Done when: 20 autoplay games at `--difficulty hard` hit the targets; changes listed before/after.
- Depends on: P3-01 to P3-08 merged.

**P3-10 | Normal and Easy values | gameplay (B) | `scripts/difficulty.gd`**
- Set the `LEVELS` table per Q6 (multipliers on Hard). Proxy targets with BLUE as the Hard CPU, 20 games per level:
  RED wins about 50% on Hard, about 25-35% on Normal, about 10-20% on Easy; RED still uses every move on Easy (no
  move counter drops to 0). Humantest at each level: the human scores more on Easy than on Hard.
- Done when: the table and a per-level stats table are in the hand-off.
- Depends on: P3-03, Q6. Runs in parallel with P3-09 (multipliers carry over a Hard retune).

**P3-11 | README and CLAUDE.md testing targets | gameplay (B, after P3-10) | `README.txt`, `CLAUDE.md` (Testing section only)**
- README: first to 21 with 1s and 2s, game end and clocks (Q1), switch at 11, fouls and free throws (how to shoot
  them: hold and release SHOOT at the line), out of bounds, difficulty and how to pick it; "EASY THINGS TO CHANGE"
  for `rules.gd` (`TARGET_SCORE`, `SWITCH_AT`, `WIN_BY`, foul and free-throw constants) and `difficulty.gd`; remove
  quarters and "Shots beyond the arc count 3". FILES list adds `rules.gd`, `difficulty.gd`, `menu.gd`.
- CLAUDE.md "Testing": `--quit-after` large enough for a game to 21, the new typical numbers from P3-04/P3-12
  (shots, points, game length, fouls, free throws), and `--difficulty` / `--target`.
- Done when: the text matches the merged behavior and the owner's answers.
- Depends on: P3-10 (and P3-04 numbers).

**P3-12 | Phase 3 QA and balance pass | qa | `docs/qa/phase3.md` (report); tuning constants at the top of `rules.gd`, `player.gd`, `defense.gd`, `difficulty.gd` only if needed, listed in the report**
- 20+ `--autoplay` games per difficulty, 4 `--humantest` (two on Easy, two on Hard), `--shots` screenshots (top bar,
  game point, switch sides, free-throw line-up, sideline inbound, both panels). Compare with `docs/qa/phase2.md`.
- Per rule pass/fail: games end at the target per Q1; exactly one switch at 11; B1 gone (right vs left hoop points
  and win share within noise over 40+ games); fouls 3-6 per game and FT 65-80% (CPU); and-ones happen; out of bounds
  1-4 per game; difficulty proxy targets from P3-10; game length per Q2's answer; no stuck states (ball dead with no
  inbound, players frozen after a free throw); no script errors.
- Web build in Chromium with Playwright touch emulation: pick a level on the panel, shoot a free throw with the
  meter, see the switch, and check the choice is remembered after a reload.
- Done when: report with per-game tables and a pass/fail line per rule; tuning changes listed before/after.
- Depends on: P3-09, P3-10 (P3-11 optional).

**P3-13 | Publish the web build | coordinator | `gh-pages` branch (build output only)**
- After P3-12 passes and the phase is merged: `tools/build_web.sh --publish`, then the lead writes the phase summary
  (with the check-in questions above).
- Depends on: P3-12.

## Parallel plan

| Wave | Programmer A | Programmer B | Other |
|---|---|---|---|
| 1 (start now) | P3-01 rules module + first to 21, then P3-02 switch sides (`main.gd`, `rules.gd`) | P3-03 difficulty plumbing (`difficulty.gd`, `player.gd`, `defense.gd`) | coordinator asks Q1-Q7; P3-04 length check after P3-02 |
| 2 (Q3, Q4) | P3-05 fouls + free-throw sequence (`rules.gd`, `main.gd`) | P3-06 player side of fouls and FTs (`defense.gd`, `player.gd`, `human_input.gd`) | |
| 3 (Q5, Q7) | P3-08 difficulty panel (`menu.gd`, `main.gd`) | P3-07 out of bounds (`ball.gd`, `rules.gd`) | |
| 4 (Q6) | P3-09 CPU retune (`player.gd`, `defense.gd`) | P3-10 Normal/Easy values (`difficulty.gd`), then P3-11 README + CLAUDE.md | P3-12 QA, then P3-13 publish (coordinator) |

Why this split: `main.gd` is the hot spot, so P3-01 moves the rules (score, format, dead balls, inbounds, later
fouls and free throws) into `rules.gd` first. A owns `main.gd` + `rules.gd` in waves 1-2; in wave 3 `rules.gd` passes
to B (out of bounds) while A works in `main.gd` + `menu.gd`. B owns `player.gd` + `defense.gd` in waves 1-2, and the
CPU retune goes back to A in wave 4 while B only touches `difficulty.gd`. Within a wave A and B never share a file.
Each wave merges and gets a quick QA run (3 autoplay + 1 humantest, `--quit-after 120000`) before the next starts.
If the owner answers late, wave 1 and P3-04 still finish (and P3-04's numbers help answer Q2); nothing in wave 2
starts before Q3 and Q4.

## Doing

## Review
- P3-01, P3-02, P3-03 (trial merge trial-p3w1): lead review APPROVE, with these notes.
  - Follow-up for the coordinator (player.gd, not in P3-02's files): B1 mirrors the `reset_positions` rows and the
    inbound spot by attack direction, but `player.spot_pos()` still uses the absolute `SPOTS` y. The team inbounding
    at the right hoop now lines up on the opposite side from its offense spots (player 1 at +12 ft, his spot at -16 ft).
    Mirror `s.y` by `inward(hoop)` too, or the halves still play differently.
  - Note for P3-08: `Difficulty.level` defaults to HARD (per the contract). The board says first launch = Normal, so
    the panel must pick Normal when `user://settings.cfg` has no saved level.
  - BLUE bias check: `FIRST_BALL_TEAM` 0 means BLUE always gets the first ball (quarters used to alternate it), and
    `players` update team 0 first every frame (older code). For balance tests, alternate or randomize the first ball
    in `--autoplay` only.
  - `is_game_point` counts a 2 as "one basket away", so GAME POINT shows from 19 even though 2s are rare.
- P3-05 + P3-06 (trial merge trial-p3w2): lead review APPROVE, with these follow-ups.
  - Parses and runs on Godot 4.3; no double or missing reach roll (defense.gd defers to main's FOUL_REACH_CHANCE);
    jumpers_t* no longer counts free throws; free-throw flow recovers from a lost ball, a lost result and a win.
  - `defense.commit_foul` shows the reason popup and counts `foul_bad_jumps` even when `rules.call_foul` ignores
    the call (pending foul, dead ball): have `call_foul` return bool and popup/count only when accepted.
  - A side switch triggered by an and-one or a free throw waits for the next dead ball; if the last FT misses (live
    rebound), the switch happens a possession or more later. Rare; fix with P3-07 or note it.
  - Dead code in the combined build: rules.gd fallback (`FB_CPU_FT_*`, `ft_walk`, `_fallback_reset`) and
    defense.gd's `FOUL_SHIELD_POKE_CHANCE` path with `_reach_foul_elsewhere`. Remove in P3-09 (one owner each).
  - P3-09: reach fouls run high with a poking human (humantest 7 reach + 1 shooting = 8 fouls); most shooting
    fouls are late jumps at rim shots, hence ~60% and-ones (owner question added to VISION).
  - `--force-fouls` (test only) stays; list it in CLAUDE.md Testing in P3-11.
  - GAME POINT at 20 vs 19: owner question in VISION; one constant (`GAME_POINT_BASKET`).

## Done
