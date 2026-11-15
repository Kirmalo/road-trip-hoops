# Task Board

Current phase: **Phase 2: moves** (planned 2026-11-15 by `lead-producer`). The Phase 1 board is archived in
`docs/board-phase1.md`.

Scope (from `docs/VISION.md`): crossover or spin (quick flick of the stick while dribbling), pump fake (very short tap
of Shoot), alley-oop (Pass to a teammate cutting to the rim), call for the ball, skill-based steals and blocks (timing
and the handler's exposure instead of flat dice rolls; blocks on jump timing; close guarding slows the driver), and a
CPU retune so it uses and defends these moves. Carried from Phase 1: R1 CPU pull-up jumpers (owner approved at the
check-in), R2 lower `CONTEST_FT` once the new defense lands, B1 double-counted `shakes` on a blocked rim attempt, and a
BLUE vs RED balance recheck.
Not in scope (Phase 3): first to 21, 1s and 2s, switching sides, fouls and free throws, out of bounds, Easy / Normal /
Hard. Don't add fouls for reaching or for jumping into a shooter.

Format: `ID | task | owner role | files | done when | depends on`

Rules for every task in this phase:
- Godot 4.3 compatible; no `:=` with an untyped right side (`game.x`, `min`/`max`/`clamp`); use an explicit type or
  `minf`/`maxf`/`clampf`. Tuning constants go at the top of the script they belong to, with a comment. Touch first:
  joystick + A (orange) + B (blue) only, no new buttons. No new `.tscn` scenes: new scripts are built in code.
- A task touches only the files listed. If it needs another file, stop and tell the coordinator.
- Every new feature adds `stat(...)` counters (listed per task) so `--autoplay` proves the CPU uses it and
  `--humantest` proves the human input path runs. Per-team counters end in `_t0` / `_t1`; human-only ones start with
  `human_`. Scripted `--humantest` inputs live in `main.gd` only.
- `--autoplay` (3 games) and `--humantest` (1 game) must still run headless to `FINAL` with no script errors, and
  scores stay in the CLAUDE.md range (45-70 shots, about 15-30 points per team). Report the numbers in the hand-off.
- No input may add delay to a dunk, layup or the start of the shot meter (see the gesture rules below).
- Call into another task's code by the names in "Shared contract". If that code isn't merged yet, guard the call
  (`if p.has_method("start_crossover"):`) so each task merges on its own.

## Shared contract (names fixed now so parallel tasks can call each other)

`player.gd` (state added by P2-01, filled in by later tasks; all start at "off"):
- `var stumble_t := 0.0` seconds left off balance (slow, can't steal or jump). `func stumble(time: float)`.
- `var block_jump_t := -1.0` time since a defender's block jump started (< 0 = not jumping).
  `func start_block_jump() -> bool` (false if already airborne or stumbling), `func is_airborne() -> bool` (rim move
  or block jump), `func block_height_frac() -> float` (0 on the floor, 1 at the top of the jump).
- `var cross_t := 0.0` seconds left in a crossover/spin (P2-05), `var move_kind := ""` ("cross" or "spin"),
  `var dribble_side := 1.0` (+1 right hand, -1 left hand; P2-05), `func start_crossover(dir: Vector2, kind: String)`.
- `var fake_t := 0.0` seconds left in a pump fake (P2-06).
- `var alley_cut := false` this player is cutting to the rim for a lob (P2-09).
- `var def` the player's defense brain (`defense.gd` instance, P2-01).

`defense.gd` (new, P2-01; `extends RefCounted`, one instance per player, holds the CPU defender's state):
- `func cpu_update(delta: float)`: today's `defense_ai` body, moved.
- `static func rim_blocker(game, shooter, kind: String)` returns the blocking defender or `null`, asked at the moment
  a dunk/layup leaves the hand. `static func check_jump_shot_block(game)` runs every frame from `main.gd` (P2-07).

`main.gd` / `human_input.gd`:
- `game.input` (new `human_input.gd`, P2-03): `a_pressed()`, `a_released()`, `b_pressed()`, `update(delta, stick)`.
- `game.steal_exposure(defender, handler) -> float` 0..1 and `game.attempt_steal(defender, _legacy := -1.0)` (P2-04;
  the unused second argument keeps old callers working).
- Unchanged and used by everyone: `game.do_pass`, `game.block_shot`, `game.rim_shot_blocked`, `game.release_shot`,
  `game.show_message`, `game.stat`, `game.fx`, `game.audio`.

## Touch gestures (design notes, against the current code)

Today: the left-half touch makes a floating joystick; the knob stops at the ring (`JOY_RADIUS` 80 px) and
`controls.joystick()` returns the knob vector (dead zone 0.15). Turbo is the finger's distance from the center
(`turbo_pull()`, past `TURBO_PULL` 1.5 x the ring). A with the ball: inside `LAYUP_RANGE` (9 ft) it takes off for a
dunk/layup on press; outside it starts the shot meter on press and shoots on release (a release under 0.6 of the
meter is already a bad 0.6-quality shot). B with the ball = pass; on defense = switch; **on offense without the ball A
and B do nothing** (the HUD shows "-").

- **Crossover / spin flick (P2-03 detects, P2-05 acts).** Only while the human holds the ball, on the floor, not in the
  shot meter. Sample the knob vector every physics frame. A flick is: the stick direction turns by at least
  `FLICK_ANGLE` (100 degrees) within `FLICK_WINDOW` (0.12 s), and the stick is pushed at least `FLICK_MIN_LEN` (0.6
  of the ring) both before and after. A quick reversal that passes through the dead zone still counts (compare with
  the last sample outside the dead zone, if it is inside the window). After a flick, no new flick for `FLICK_COOLDOWN`
  (0.5 s); the first 0.15 s after the thumb touches down is ignored (a new floating center isn't a flick).
  Turbo is told apart because it is measured on the finger's **distance** from the center and the flick on the
  **direction** of the knob: pulling out past the ring changes length, not angle, so it can't trigger a flick, and a
  flick doesn't start or stop turbo. Normal steering is told apart by speed: a 90-degree turn spread over more than
  0.12 s (7 frames) is steering. Classification if the owner wants both moves (Q1): turn of 100-150 degrees =
  crossover, more than 150 degrees (a flick back) = spin. Testable in `--humantest`: a smooth 180-degree turn over
  0.4 s gives 0 flicks, a radial pull from 0.8 to 1.6 ring radii gives 0 flicks and turbo on, a 120-degree snap over
  3 frames gives exactly 1 flick.
- **Pump fake (P2-06).** No added lag: the shot meter still starts on press. If A is released before
  `PUMP_TAP_MAX` (0.15 s, about 0.17 of the meter), it's a pump fake instead of a shot (today that release is a
  near-useless 0.6 shot, so nothing is lost). Holding longer shoots as now. Near the rim the press starts a dunk/layup
  at once, so a tap can't be a fake there without either waiting (lag) or a different rule: owner question Q2.
- **Call for the ball (P2-10).** B on offense without the ball is free today: it becomes CALL (label "CALL"). Details Q4.
- **Alley-oop (P2-09).** Proposed rule: a pass becomes a lob when the receiver is cutting (`alley_cut`, or moving
  toward the rim at > 60% speed), is within `ALLEY_FT` (12 ft) of the rim he attacks, and no defender is between him
  and the rim within 4 ft. The lob flies higher and slower (only the first 40% of its flight can be picked off), and
  the receiver catches it in the air and dunks (no button) unless the owner picks otherwise (Q5).
- **Defense button (P2-07).** A on defense today pokes for a steal and, in the first 0.3 s of a jump shot, can block
  at 30%. With jump-timing blocks, A needs to mean "poke" or "jump": Q3.

## Owner answers (2026-11-15, also in docs/VISION.md)
- **Q1 dribble moves:** crossover only. Any quick flick while dribbling is a crossover (fast side-step, ball switches
  hands, a defender too close can stumble). No spin for now.
- **Q2 pump fake:** only away from the rim, where the meter shows. Near the rim SHOOT dunks or lays up right away.
- **Q3 defense button:** automatic. Orange says BLOCK and jumps when your man starts a shot or is near the rim and
  you're close; otherwise STEAL. Jumping at a fake leaves you in the air.
- **Q4 call for the ball:** blue becomes CALL on offense without the ball; the teammate passes as soon as the lane is
  clear (about 1.5 s); if you're cutting to the rim it's a lob.
- **Q5 alley-oops:** automatic. PASS to a teammate cutting to the rim throws a lob and he dunks it in the air; same
  when a teammate lobs to you.
- **Q6 luck:** owner's own answer: "timing based but also depend on the traits of the specific player since players
  will have attributes". Implemented as: timing/exposure decides a good vs bad try; a good try succeeds with a chance
  set by the player's rating (`ratings` {"steal", "block"} 0-100 on each player, `rating(key)` in player.gd; about
  70% at 50, about +/-20% across 0-100); bad timing almost never works. Updated in VISION (6486a45): no stumble
  after a missed steal; instead the defender stands still while attempting a steal (hit or miss), so poking has a cost. Ratings are varied per player with equal team totals. They are the start of the
  player attributes the campaign (Phase 5) will grow.
- **P2-10 control (owner approved, 2026-11-15):** `CONTROL_FOLLOWS_CATCH := false`. When the human passes, he takes
  over the receiver as before. When a teammate gets the ball any other way (rebound, steal, inbound, CPU pass), that
  teammate plays it and the human keeps his player and presses CALL to get the ball.

## Phase 2 check-in (owner, 2026-11-15) and tuning round P2.5
Answers: crossover about right; steals AND blocks too hard; CPU too hard mainly because it's hard to stay in front
of the ball handler, so add a defensive assist; leave the PASS/SHOOT buttons where they are.

**P2.5-01 | Easier steals and blocks | gameplay | `scripts/main.gd` (steal constants), `scripts/defense.gd`,
`scripts/player.gd` (block constants only)**
- Steals: widen the human's timing window (STEAL_GRACE), raise the good-timing success, make the yellow cue last
  longer and easier to read; keep random pokes rare-ish (the poke freeze stays). Blocks: widen the human's good-timing
  window (e.g. BLOCK_HEIGHT_MIN lower, not higher) and raise good-timing success. Human only unless the CPU must
  change to keep balance; CPU steals/blocks stay in their target ranges.
- Done when: humantest timed steals succeed clearly more often (aim ~80% timed, ~10-15% random), timed human blocks
  ~45-55%, early jumps ~10-15%; autoplay unchanged (CPU vs CPU).

**P2.5-02 | Defensive assist | gameplay | `scripts/player.gd` (human movement), `scripts/human_input.gd`**
- While the human guards the ball handler (within ~8 ft) and steers roughly toward him or toward the basket line,
  blend the movement toward the spot between the handler and the basket (a few feet in front of him), matching his
  lateral moves. The human still steers: pulling clearly away, sprinting off or pressing STEAL/BLOCK overrides it.
  Tuning constants (assist strength, range, angle) at the top. Crossovers still beat it sometimes (stumble rules stay).
- Stats: `human_assist_frames`, and a humantest metric for how often the handler gets past the human defender
  (before/after). Done when: in humantest the human defender stays in front clearly more often; CPU vs CPU unchanged.

## Todo

### Wave 1: can start now (no owner answers needed)

**P2-01 | Defense brain split and shared primitives | gameplay (A) | `scripts/player.gd`, new `scripts/defense.gd`**
- New `defense.gd` (`extends RefCounted`, `var p`, `var game`); each player creates one in `setup()` as `def`.
  Move the body of `defense_ai()` into `def.cpu_update(delta)` unchanged; `player.defense_ai` becomes one call.
  Move the rim-block dice from `start_rim_move()` into `Defense.rim_blocker(game, shooter, kind)`, asked in
  `release_rim_shot()` (same odds, same contest distance; make-odds contest `rim_quality` stays at take-off).
- Add the shared state and functions from "Shared contract" (`stumble`, `start_block_jump`, `is_airborne`,
  `block_height_frac`, and the declared-but-unused vars). Block jump: `BLOCK_JUMP_TIME` 0.5 s, `BLOCK_JUMP_PX` 26,
  drawn through the existing `jump_z` sprite offset; no steering while airborne (keep a little momentum).
  Stumbling: speed x`STUMBLE_SPEED_MULT` 0.35, no turbo. Nothing calls these yet except a temporary debug call.
- Close guarding slows the driver (decided in VISION): a handler (human or CPU) with a defender within `GUARD_FT` 4.0
  in front of him (inside `GUARD_CONE` 50 degrees of his movement direction), not stumbling and not airborne, moves at
  x`GUARD_SLOW` 0.82 (turbo still applies on top).
- B1: remove the extra `game.fx.shake(4.0, 0.2)` in `release_rim_shot()`.
- Stats: `guard_slow_frames_t0/_t1` (frames a handler of that team is slowed), `stumbles`, `block_jumps_t0/_t1`.
- Done when: 3 `--autoplay` games stay in range and `rim_blocks` per game is close to Phase 1 (4.4); `shakes` =
  `blocks + dunk_makes`; `guard_slow_frames` > 0 for both teams; a temporary debug run shows a block jump and a
  stumble (removed before review); humantest runs.
- Depends on: none.

**P2-02 | CPU pull-up jumpers (R1) | gameplay (A, after P2-01) | `scripts/player.gd`**
- Move the literals in `handler_ai` (`p > 0.40`, `open_ft > 4.0`, `open_ft > 6.0`, `dist_ft < 26.0`, the 0.5 / 0.3 /
  0.15 rolls, shot-clock 4.0 / 32.0) into named constants at the top. Add a pull-up rule: in the frontcourt, 12-22 ft
  from the rim with the defender 3-6 ft off (or sagging/behind), `CPU_PULLUP_CHANCE` per decision; a small
  `CPU_THREE_CHANCE` when open beyond the arc. Pull-ups use the normal jumper path (`start_shot`, then CPU release).
- Stats: `pullups_t0/_t1`, `cpu_threes`.
- Done when: over 5 `--autoplay` games about 8-15 jump shots (non-dunk, non-layup) per game, a few 3s made, scores
  still 15-30 per team, shot count still 45-70.
- Depends on: P2-01 (same file).

**P2-03 | Human input module and flick / tap detection | gameplay (B) | new `scripts/human_input.gd`, `scripts/main.gd`**
- Move the bodies of `_on_a_pressed`, `_on_a_released`, `_on_b_pressed`, `_switch_player` and the pass-target choice
  into `human_input.gd` (`extends Node`, `var game`), created in `main._ready()` as `game.input`. `main.gd` keeps the
  signal connections, the keyboard handler, `_input_vector()` and the humantest script, and forwards to `game.input`.
  Behavior unchanged.
- Flick detector in `input.update(delta, stick)` (called every physics frame with the same vector the human player
  gets), exactly as in "Touch gestures" (constants `FLICK_ANGLE`, `FLICK_WINDOW`, `FLICK_MIN_LEN`, `FLICK_COOLDOWN`,
  `FLICK_TOUCH_IGNORE`, `SPIN_ANGLE` 150 at the top of `human_input.gd`). Reads `game.controls.joy_index` to notice a
  new touch. On a flick: `human_player.start_crossover(flick_dir, kind)` if the method exists. `kind` is "cross" or
  "spin" by angle; until Q1 is answered both are reported, P2-05 applies the owner's choice.
- Humantest (in `main.gd`): while the human has the ball, every ~3 s inject a 3-frame 120-degree snap of the stick;
  every ~5 s inject a smooth 180-degree turn over 0.4 s and a radial pull; every ~4 s a 5-frame A tap (pump fake
  input) outside the rim range. Counters for each scripted input.
- Stats: `human_flicks`, `human_flick_cross`, `human_flick_spin`, `humantest_snaps`, `humantest_smooth_turns`,
  `humantest_taps`.
- Done when: humantest shows `human_flicks` = `humantest_snaps` (smooth turns and pulls give none); autoplay
  unchanged (the detector is off without a human); a keyboard/touch smoke test under xvfb opens with no errors.
- Depends on: none.

**P2-04 | Skill-based steals (exposure) | gameplay (B, after P2-03) | `scripts/main.gd`**
- Replace the flat roll in `attempt_steal` with `steal_exposure(defender, handler)`: the ball sits at
  `handler.position + facing * 15 px` (plus `dribble_side` once P2-05 lands). Reach: the defender's distance to the
  **ball**, not the body, must be under `STEAL_REACH_FT` 2.5. Shielding: the angle between handler->ball and
  handler->defender; under 60 degrees fully exposed, over 120 degrees shielded (0), linear between. Multipliers:
  handler in a crossover (`cross_t > 0`) x`STEAL_CROSS_MULT` 1.6, in a spin x0.3, sprinting x1.3, pump faking x1.3.
  Chance = `STEAL_BASE` x exposure; `STEAL_LUCK` sets how much luck is left (Q6; default option 1 = success about 70%
  when fully exposed, near 0 when shielded). A missed poke: `defender.stumble(STEAL_MISS_STUMBLE)` 0.35 s if the
  method exists (Q6 option 3 sets it to 0). Same rule for human and CPU; the second argument is ignored.
- Keep the jump-shot block path in `attempt_steal` for now (P2-07 replaces it).
- Stats: `steal_pokes_t0/_t1`, `steals_t0/_t1`, `steal_shielded` (pokes at exposure 0), `steal_miss_stumbles`.
- Done when: autoplay steals stay about 5-10 per game (the CPU pokes on a timer until P2-08, so expect fewer: report
  it), humantest steals drop from ~35 to a believable number, both teams have steals, scores in range.
- Depends on: P2-03 (same file). Q6 only changes constants.
- Review notes (lead, trial merge `trial-p2b`): the miss stumble now resolves to the real `stumble()` (~95/game) and
  contradicts the updated VISION; replace it with a stand-still poke freeze (needs a `poke_t` in player.gd movement;
  file owner to be set by the coordinator). Timing window is too narrow for a human, see "Steal timing" below.
- **Steal timing (later task, P2-07/P2-08 or P2-13):** the dribble is `4 + |sin(9t)| * 16` px, so z under 8 px is
  ~55 ms per bounce (~16% of the time) and z under 5 is ~14 ms (under one frame). Minimal readable cue: flash or
  enlarge the STEAL button (or a small ring under the ball) while `steal_timing(handler) > 0`, and/or measure timing
  as time to the nearest floor touch with a ~0.1 s grace. The dribble sound only plays every 2nd floor touch.

### Wave 2: needs Q1, Q2, Q3 (Q6 for constants)

**P2-05 | Crossover / spin and the dribble hand | gameplay (A) | `scripts/player.gd`, `scripts/ball.gd`**
- `start_crossover(dir, kind)`, only for the owner's moves from Q1. Crossover: `CROSS_TIME` 0.3 s burst toward
  `dir` at x`CROSS_SPEED_MULT` 1.25, `dribble_side` flips, the ball crosses in front of the body. Spin (if chosen):
  `SPIN_TIME` 0.45 s, sprite turns 360 degrees, ball shielded, x1.05 speed. `CROSS_COOLDOWN` 0.6 s.
- Beating the man: the defender within `CROSS_BEAT_FT` 5 who is in front of the handler stumbles for
  `CROSS_STUN` 0.45 s if he is moving the wrong way or is a CPU still inside its reaction time (`def` decides the CPU
  reaction in P2-08; until then a flat `CROSS_BEAT_CHANCE` 0.5 for CPU defenders). Popup on a beat (short word,
  e.g. "SHOOK!" via `game.fx.popup`). A stumbling defender doesn't slow the driver (P2-01).
- `ball.gd`: held ball drawn at `facing * 15 + side offset * dribble_side`; handlers slowly switch hands away from the
  nearest defender when not in a move. CPU handler: crossover when a defender is close in front and the lane is shut
  (`CPU_CROSS_CHANCE` per decision), spin if chosen.
- Stats: `crossovers_t0/_t1`, `spins_t0/_t1`, `human_crossovers`, `cross_beats_t0/_t1`.
- Done when: autoplay shows about 4-12 crossovers per team per game and some beats; humantest `human_crossovers` =
  `human_flicks` (minus ones during cooldown); scores in range; screenshot of the ball on the left hand.
- Depends on: P2-01, P2-02 (`player.gd`), P2-03 (detector), P2-04 (exposure uses `cross_t`), Q1.
- Note (lead): Q1 = crossover only. P2-03 still reports `kind` "spin" for turns over 150 degrees; `start_crossover`
  must treat "spin" exactly like "cross" (no spin move, no `spins_*` stats, `move_kind` always "cross"), so
  `STEAL_SPIN_MULT` in main.gd never applies.
- Review (lead, 765643e): APPROVE. Godot 4.3 parses clean; every kind plays as "cross"; exposure reads the drawn
  `ball.position`, so the hand counts in `steal_exposure`. 3 autoplay: crossovers 5-15/team, beats ~55% of them
  (P2-08 brings that to 25-45% via `def.beaten_by_cross`). Humantest flicks 57 = crossovers 57.

**P2-06 | Pump fake | gameplay (A, after P2-05) | `scripts/player.gd`**
- Human: release of A within `PUMP_TAP_MAX` 0.15 s of starting the meter = pump fake (no shot, keeps the ball,
  `fake_t` = `PUMP_TIME` 0.3 s: ball raised, small hop drawn, can move slowly, can press A again right away to shoot).
  Near the rim: as Q2 decides (option 1: unchanged).
- CPU handler: outside the rim range with a defender within 5 ft in front, `CPU_PUMP_CHANCE` per decision; while
  faking it sets `shooting` like a real shot for the fake's time, so defenders that react to the shot start bite.
  If the defender bit (`block_jump_t >= 0`), the CPU drives past (turbo) or steps in for a shot.
- Stats: `pump_fakes_t0/_t1`, `human_pump_fakes`, `pump_bites_t0/_t1` (a defender of the other team started a block
  jump within 0.4 s of the fake), `pump_and_score`.
- Done when: humantest `human_pump_fakes` about equal to `humantest_taps` outside the rim range; autoplay 2-6 pump fakes
  per team per game and some bites once P2-07 lands; scores in range.
- Depends on: P2-05 (same file), P2-03, Q2. Bites need P2-07 merged (CPU block jumps).
- Review (lead, daa86b3): APPROVE. A full-length release and dunks/layups are unchanged (no lag). Pressing A again
  during a fake starts a new meter (it doesn't shoot instantly), and fakes can be chained with no cooldown. 3 autoplay:
  fakes 3-8/team, bites 0 (as expected until P2-07); humantest taps 22 = fakes 22. For P2-07: a human fake keeps
  `shooting` true for only about 0.15 s, so CPU jumps at human fakes must come from `def.on_pump_fake(faker)`.
- Follow-up (not blocking): human_input.gd's flick detector uses real time, but drops samples older than 0.12 s. Below
  about 10 fps (seen in Chromium software rendering) a whole flick lands between two input events and is missed.
  Tablets at 30-60 fps are fine. Option: compare with the last strong sample even if it is one frame older than the window.

**P2-07 | Jump-timing blocks and the defense button | gameplay (B) | `scripts/defense.gd`, `scripts/human_input.gd`, `scripts/main.gd`**
- `Defense.rim_blocker`: a block happens when a defender of the other team is airborne at the dunk/layup release,
  within `RIM_BLOCK_REACH_FT` 4.0 of the shooter and at least `BLOCK_HEIGHT_MIN` 0.6 of his jump height; luck per Q6.
  Dunks are harder to block than layups (`DUNK_BLOCK_MULT`). No airborne defender = no block (the dice are gone).
- Jump shots: `Defense.check_jump_shot_block(game)`, called every frame from `main._physics_process`: while
  `ball.state == SHOT` and `shot_t < JUMPER_BLOCK_WINDOW` 0.25, an airborne defender within `JUMPER_BLOCK_REACH_FT`
  3.5 of the ball at height >= `BLOCK_HEIGHT_MIN` blocks (once per shot) via `game.block_shot()`. Remove the jump-shot
  block path from `attempt_steal` and the 12% roll from `cpu_update`.
- CPU defenders jump: when their man starts a shot (`shooting` goes true, includes pump fakes) or takes off at the
  rim, within `CPU_JUMP_FT` 6, with a reaction delay `CPU_JUMP_REACT` 0.12-0.3 s and `CPU_JUMP_CHANCE` 0.6.
- Human: A on defense per Q3 (option 1: `human_input.gd` picks BLOCK when the guarded man is shooting/in a rim move or
  within 9 ft of his rim and the human is within 6 ft, else STEAL; `main._update_hud` shows the label). Humantest:
  on defense press A about 0.15 s after a CPU shot starts (good timing) on half the shots and right away on the rest.
- Stats: `block_jumps_t0/_t1` (from P2-01), `blocks_t0/_t1`, `rim_blocks`, `jumper_blocks`, `jumps_early` (airborne
  and landing before the release), `human_block_jumps`, `human_blocks`.
- Done when: autoplay blocks about 3-8 per game for both teams, `rim_blocks` lower than Phase 1's 4.4 is fine;
  humantest has human blocks > 0 and well-timed jumps block more often than early ones; scores in range.
- Depends on: P2-01, P2-03, P2-04 (`main.gd`), Q3. Q6 for constants.
- Review (lead, f5399ce on trial-w2): APPROVE. 34 autoplay games: blocks 8.0/game (top of range; layup-on-the-way-up
  departure adds ~2.3/game, accepted), blocks_t0/t1 144/127: the coordinator's 9/1-style splits were variance, the code
  paths are symmetric. Follow-up: `rim_blocker` sets `rolled_shot = shot_serial + 1` before rolling, but a successful
  rim block never increments `shot_serial`, so that blocker gets no try on the next released shot (set it only on a
  miss, or bump the serial in `rim_shot_blocked`). Humantest: timed jumps blocked 1/6, early 0/10 (thin but right way).

**P2-08 | CPU defense reads the moves | gameplay (B, after P2-07) | `scripts/defense.gd`**
- Pokes: the CPU pokes only when `game.steal_exposure()` is above `CPU_POKE_EXPOSURE` 0.5, at most every
  `CPU_POKE_GAP` 1.2 s, and more often against a crossing handler. Crossovers: a reaction time
  `CPU_CROSS_REACT` 0.2-0.4 s (during it a crossover can beat him, see P2-05); after a beat he sprints to recover.
  Close guarding: on the ball he stays in front within `GUARD_FT` when he can (that's what slows the driver).
- Stats: `cpu_pokes`, `cpu_poke_skipped_shielded`, `cpu_cross_reads` (crossover inside his reaction window that
  didn't beat him), `recover_sprints`.
- Done when: autoplay steals about 5-10 per game, `cross_beats` a minority of crossovers (about 25-45%),
  `guard_slow_frames` up from P2-01, scores in range.
- Depends on: P2-07 (same file), P2-05 for `cross_t`.
- Review (lead, 9c62941 on trial-w2): APPROVE. Cross beats 87/267 = 33%; fake bites ~5/game (`cpu_fake_bites`,
  `pump_bites_t*`), ~45% of fakes; steals avg ~9 (0-17). `CPU_POKE_GAP` is 2.0 (board said 1.2), fine with steals in range.

### Wave 3: needs Q4, Q5

**P2-09 | Alley-oop | gameplay (A) | `scripts/ball.gd`, `scripts/player.gd`**
- `ball.pass_to` decides a lob by the rule in "Touch gestures" (`ALLEY_FT` 12, cutting, no defender in front within 4
  ft). Lob: `LOB_SPEED` 480 px/s, high arc (`LOB_PEAK`), interceptable only in the first 40% of the flight. Receiver:
  catches in the air and dunks (new `start_alley_dunk()` reusing the rim move; a defender jumping in reach can block it
  through `Defense.rim_blocker`). If Q5 picks option 2, the human must press A in the air (window `ALLEY_TAP_WINDOW`);
  option 3 moves the lob choice to `human_input.gd` (P2-10).
- CPU off-ball: sometimes cut to the rim (`CPU_CUT_CHANCE` per spot change, sets `alley_cut`) when the handler is in
  the frontcourt and the cutter's man is behind him. CPU handler: lob to a cutter that qualifies (`CPU_LOB_CHANCE`).
- Stats: `alley_lobs_t0/_t1`, `alley_dunks`, `alley_makes`, `alley_picks` (lob intercepted), `rim_cuts_t0/_t1`.
- Done when: autoplay about 1-4 alley-oops per game for both teams and most of them dunks; scores in range.
- Depends on: P2-06 (`player.gd`), P2-05 (`ball.gd`), P2-07 (`rim_blocker`), Q5.

**P2-10 | Call for the ball | gameplay (B) | `scripts/human_input.gd`, `scripts/main.gd`**
- B on offense without the ball = CALL (HUD label "CALL", per Q4). Option 1: `human_input.update` keeps the call
  alive for `CALL_WINDOW` 1.5 s and has the CPU handler `game.do_pass(handler, human)` once the lane is clear (no
  defender within `CALL_LANE_FT` 3 of the line) and the handler isn't shooting or airborne; a small "BALL!" popup over
  the human (`game.fx.popup`). Calling while cutting near the rim sets `alley_cut` so the pass becomes a lob (P2-09).
  Option 3 adds A = "LOB" call.
- Humantest: on offense without the ball press B every ~3 s; when a teammate is near the rim press B with the ball.
- Stats: `human_calls`, `human_call_passes`, `human_call_timeouts`, `human_alley_lobs`.
- Done when: humantest shows calls and passes from calls, at least one human alley-oop over 2 games once P2-09 lands;
  autoplay unchanged.
- Depends on: P2-07 (`human_input.gd`, `main.gd`), Q4, Q5.

### Wave 4

**P2-11 | CPU retune, contest distance and balance | gameplay (A) | `scripts/player.gd`, `scripts/defense.gd` (constants and small logic)**
- R2: lower `CONTEST_FT` (try 3.0) now that blocks need a jump and close guarding slows drivers; beating your man
  should give a clearly better look. Balance the CPU's use of every move (targets per game: 8-15 jumpers, 4-12
  crossovers per team, 2-6 pump fakes per team, 1-4 alley-oops, 5-10 steals, 3-8 blocks, few interceptions and shot
  clock violations). Recheck BLUE vs RED over 20 games.
- Stats: none new; `rim_contested` share of rim attempts should drop from 99% to roughly 60-80%.
- Done when: 10 `--autoplay` games hit the targets with scores 15-30 per team; changes listed with before/after numbers.
- Depends on: P2-01 to P2-10 merged.

**P2-12 | README how to play | gameplay (B) | `README.txt`**
- Add crossover/spin, pump fake, alley-oop, CALL, steals (protect the ball with your body; crossovers expose it),
  blocks (jump on time; don't bite on fakes), close guarding, and the new constants in "EASY THINGS TO CHANGE"
  (`human_input.gd` flick settings, `defense.gd` block and steal settings).
- Done when: the text matches the merged behavior and the owner's answers.
- Depends on: P2-10, P2-09. Runs in parallel with P2-11.

**P2-13 | Phase 2 QA and balance pass | qa | `docs/qa/phase2.md` (report); tuning constants at the top of `player.gd`, `defense.gd`, `human_input.gd`, `main.gd` only if needed, listed in the report**
- 20+ `--autoplay` games, 4 `--humantest` games, `--shots` screenshots (a crossover, a pump fake hop, a block jump,
  an alley-oop lob). Compare with `docs/qa/phase1.md`.
- Check every move's counters per team against the P2-11 targets; the humantest gesture checks (flicks = snaps,
  smooth turns and pulls give no flicks, taps outside the rim range = pump fakes, no dunk started late); steals and
  blocks are not flat (well-timed vs early jumps, exposure 0 pokes almost never work); scores, shots, FG%, OT rate;
  BLUE vs RED; no script errors; B1 fixed (`shakes` = `blocks + dunk_makes`).
- Test the web build in Chromium with Playwright touch emulation: a flick while holding the stick, a short tap of
  SHOOT, CALL, BLOCK. Report whether a flick can be triggered by accident during normal steering, and by lifting
  and re-touching the thumb (P2-03 saw 1 re-touch false flick in 3 browser runs at 15 fps). If it recurs at 60 fps,
  don't record stick samples while `_touch_age < FLICK_TOUCH_IGNORE` (today they are recorded, only firing waits).
- Done when: report with a table per game and a pass/fail line per feature; tuning changes listed with before/after.
- Depends on: P2-11 (P2-12 optional).

**P2-14 | Publish the web build | coordinator | `gh-pages` branch (build output only)**
- After P2-13 passes and the phase is merged: `tools/build_web.sh --publish`, then the lead writes the phase summary.
- Depends on: P2-13.

## Parallel plan

| Wave | Programmer A | Programmer B | Other |
|---|---|---|---|
| 1 (start now) | P2-01 defense split + primitives, then P2-02 pull-ups (`player.gd`, `defense.gd`) | P2-03 human input + flick detector, then P2-04 steals (`human_input.gd`, `main.gd`) | coordinator asks Q1-Q6 |
| 2 (Q1, Q2, Q3) | P2-05 crossover, then P2-06 pump fake (`player.gd`, `ball.gd`) | P2-07 blocks + defense button, then P2-08 CPU defense (`defense.gd`, `human_input.gd`, `main.gd`) | |
| 3 (Q4, Q5) | P2-09 alley-oop (`ball.gd`, `player.gd`) | P2-10 call for the ball (`human_input.gd`, `main.gd`) | |
| 4 | P2-11 CPU retune (`player.gd`, `defense.gd`) | P2-12 README (`README.txt`) | P2-13 QA, then P2-14 publish (coordinator) |

Why this split: `player.gd` and `main.gd` are the hot spots, so wave 1 moves CPU defense into `defense.gd` (owned by A
in wave 1, B from wave 2) and human input routing into `human_input.gd` (B). Within a wave A and B never share a file;
`defense.gd` changes hands only between waves. Each wave merges and gets a quick QA run (3 autoplay + 1 humantest)
before the next starts. If the owner answers late, wave 1 still finishes; nothing in wave 2 starts before Q1-Q3.

## Doing

## Review

- P2-11 CPU retune (`worktree-agent-a0ab513e1e0ae8ed8`, 617c4b6): CHANGES. Parses on 4.3, 0 shot-clock violations.
  Lead's 6 autoplay: 36-24, 20-30, 20-34, 30-26, 36-26, 33-31 OT (5 of 12 team scores over 30; mean 28.8);
  jumpers 14/game; `late_closeouts` 75 of 84 jumpers (89%); alley-oop catches 2-6 (mean 4); rim contested ~77%;
  blocks 5.8, steals 10.7, intercepts 3.8. Humantest 22-35. Fixes: (1) the late-closeout test needs
  `shot_contest_t >= CLOSEOUT_GRACE` (0.35 s) but a CPU windup is 0.3-0.45 s, so even a defender glued from the start
  is often "late", and a human closeout on a CPU jumper almost never counts in full. Count the defender as close
  from the start (seed `shot_contest_t` at `start_shot`) or cap the grace by the windup, e.g. `minf(CLOSEOUT_GRACE,
  0.5 * cpu_shot_time)`. (2) Get scores back to 15-30 per team (P2-11's done-when) after (1), with 10 games; alley-oops
  can move to P2-13 if they stay near 4. The call hold is fine: the handler keeps driving and sidestepping, only shots
  and passes wait, at most CALL_WINDOW 1.5 s, and the shot-clock exit works. More timeouts are expected: calls whose
  lane never clears now run the full window instead of ending with the handler's own shot or pass.

- P2-09 alley-oop (`worktree-agent-a6f6286e12d331c4a`) + P2-10 call for the ball (`worktree-agent-a88cb4ada7618ca1b`),
  trial merge `trial-w3`: CHANGES (one small fix). Lob API matches what P2-10 calls; parses; autoplay in range.
  Fix before merge (P2-10 owns `human_input.gd`): `defense_action()` returns BLOCK while `game.ball.is_lob()` and the
  human is within BLOCK_CLOSE_FT of the receiver (owner Q3: "near the rim and you're close"); today it says STEAL
  until ~0.09 s before the dunk. Call answer rate (instrumented copy, 3 humantests): answered calls go at once
  (< 0.25 s); timeouts are almost all "lane blocked by the caller's own man" with the scripted thumb parked within
  5 ft of the rim, so it is mostly the test. Follow-up for P2-11 (`player.gd`): while a call is live the CPU handler
  should not start a new shot or pass elsewhere (except late shot clock); about a third of calls end that way.

- P2-03 + P2-04 (`worktree-agent-a7352f0fb16833d4f`, trial merge `trial-p2b`): CHANGES (miss stumble vs VISION,
  humantest score out of range, steal timing window). See the P2-04 review notes.

## Done
- P2-01 defense split, ratings, block jump, stumble, close-guard slow, B1 fix (approved after one fix; merged 8b7d552).
  Ratings by roster slot, both teams: steal/block 75/40, 40/75, 35/35.
- P2-02 CPU pull-up jumpers (merged). ~10.6 jumpers/game (18%), jumper FG ~22%, threes 2/9: retune in P2-11.
- P2-03 human_input.gd, flick/tap detection (approved; merged 4e15617). 0 false flicks from turns/turbo pulls.
- P2-04 skill-based steals (approved after changes; merged). Owner: no stumble on a miss; every steal attempt freezes
  the defender for STEAL_POKE_FREEZE 0.3 s (`poke_t`). Timing = a window around each dribble floor touch:
  STEAL_GRACE 0.05 s (human), STEAL_CPU_GRACE 0.02 s until P2-08 times CPU pokes (then make it equal).
  STEAL button turns solid yellow with a pulsing ring while a poke would be well timed.
  Merged check: 26-12, 12-22, 18-17, 20-16; 49-57 shots; 9-15 steals; 2-3 intercepts.
- P2-05 crossover + dribble hand, P2-06 pump fake (approved; merged 7cf16fe). Spin flicks play as crossovers.
- P2-07 jump-timing blocks + automatic BLOCK/STEAL button, P2-08 CPU defense reads the moves (approved; merged
  7cf16fe, plus coordinator fix 76d3dfb: a blocked rim attempt advances `shot_serial`). Layups blockable on the way up
  for 0.12 s (accepted departure). Combined: blocks ~8/game (top of target), fake bites ~45% of fakes, crossovers beat
  the defender 33%, steals ~9/game (0-17). BLUE/RED block split was variance (144/127 over 34 games).
- Follow-ups for P2-11/P2-13: fakes can be chained with no cooldown; flicks below ~10 fps can be missed (tablets fine).
- P2-09 alley-oop, P2-10 call for the ball (approved; merged 4ba2441, plus coordinator fix 49d8a51: A shows BLOCK
  while a lob is coming to a player within BLOCK_CLOSE_FT). Owner approved CONTROL_FOLLOWS_CATCH := false.
  Combined: 16-28 points per team, alley-oops 1-10/game. Low call-answer rate in humantest is mostly the script
  (its own man in the lane); open callers get the ball at once.
- For P2-11: while a call is live the CPU handler shouldn't start a new shot or pass elsewhere (except late in the
  shot clock); about a third of calls end that way. Fakes have no cooldown (consider a small one).
- P2-11 CPU retune (approved after changes; merged). Late-closeout rule (contests_me) with the "already close =
  never late" fix; CONTEST_FT 3.0; CPU jumper quality up; threes; CPU_JUMPER_JUMP_CHANCE 0.2; CPU_FAKE_BITE 0.4;
  call hold (CPU passer waits on a live human CALL unless shot clock < 5 s); PUMP_COOLDOWN 0.8 s; open dunk 0.82,
  open layup 0.65. 24 games: 23.8 ppg, jumper FG 38.9%, jumpers 24%, blocks 6.5, steals 8.7.
  BLUE/RED 604/540 over 24 games: P2-13 must check balance over 40+ games.
- P2-12 README (merged e9911e0).
- P2-13 QA (merged a4a6676; report docs/qa/phase2.md). 780 autoplay games, all targets pass. Tuned CPU_LOB_CHANCE
  0.18, CPU_FAKE_BITE 0.35, CPU_SHOT_QUALITY 1.05-1.25. Balance: the team attacking the RIGHT hoop gets about +0.7
  points per game (53% wins), whichever team it is; likely left/right facing logic mixed with fixed-y spots (bug B1
  in the report). Phase 3's side switch at 11 cancels it.
- Coordinator fix for QA's one fail (low-fps flicks in the browser): the flick window grows by up to two drawn
  frames (FLICK_FRAME_GRACE_MAX 0.15 s; drawn-frame time measured in human_input._process, since input arrives once
  per drawn frame but detection runs per physics tick). Browser at ~15 fps: 9/10 snaps (was 0/10). Headless 60 fps:
  flicks = snaps, 0 false flicks from smooth turns.
- Watch in P2-13: RED scored lower than BLUE in several runs since P2-01/P2-02; recheck team balance over 20+ games.
