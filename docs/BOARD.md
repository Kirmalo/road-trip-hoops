# Task Board

Current phase: **Phase 1: feel** (planned 2026-11-15 by `lead-producer`)

Scope (from `docs/VISION.md`): turbo with a stamina bar (human and CPU); auto-dunk or layup near the rim with a jump
animation and contest check; "on fire" after 3 makes in a row; feedback (sound effects swish/rim/bounce/crowd/whistle,
screen shake on dunks and blocks, net animation, bigger score popups, ball trail when on fire).
Not in scope: crossover/spin, pump fake, alley-oop, call for ball, skill-based steals/blocks (Phase 2); 1s and 2s,
first to 21, fouls, out of bounds (Phase 3).

Format: `ID | task | owner role | files | done when | depends on`

Rules for every task in this phase:
- Godot 4.3 compatible; no `:=` with an untyped right side (`game.x`, `min`/`max`/`clamp`). Tuning constants go at the
  top of the script they belong to, with a comment. Touch first: joystick + A + B only. No new `.tscn` scenes: new
  scripts are built in code and added as children in `main.gd` (`main.tscn` stays one node).
- A task touches only the files listed. If it needs another file, stop and tell the coordinator.
- Every new feature adds `stat(...)` counters (listed per task) so `--autoplay` output proves it triggers. Use
  `game.stat("name")` from other scripts. Counters for per-team things end in `_t0` / `_t1`.
- `--autoplay` and `--humantest` must still run headless to the final score with no script errors.

## Todo

### Wave 1 (2 programmers in parallel)

**P1-01 | Turbo and stamina | gameplay | `scripts/player.gd` only**
- Human: turbo while the joystick knob is at the edge (`game.controls.joystick().length() >= TURBO_EDGE`), or Shift
  held (desktop testing only). Reads the joystick from `game.controls` so `main.gd` is not touched. Under
  `--humantest` the scripted input counts as edge (always on) so the drain/refill path runs.
- Per-player `stamina` 0..1. Turbo multiplies speed by `TURBO_SPEED_MULT` and drains; easing off refills after a short
  delay. At 0 turbo is off until stamina is back above `TURBO_MIN_RESTART`.
- CPU: uses turbo on fast breaks, when the handler drives with an open lane, when chasing loose balls/rebounds, and on
  defense to recover when beaten by more than a few feet. Never below `TURBO_MIN_RESTART`.
- Stamina bar drawn in `player._draw()` under the human's ring (small, readable on a tablet), turbo trail or dust
  puff optional. No HUD changes.
- Proposed tunable defaults (top of `player.gd`): `TURBO_EDGE = 0.9`, `TURBO_SPEED_MULT = 1.35`,
  `STAMINA_DRAIN = 0.4`/s (2.5 s of full sprint), `STAMINA_REFILL = 0.25`/s, `REFILL_DELAY = 0.5` s,
  `TURBO_MIN_RESTART = 0.25`, ball handler turbo speed x0.95 of that.
- Stats: `turbo_frames_t0`, `turbo_frames_t1`, `stamina_empty`.
- Done when: in 3 `--autoplay` games both teams have turbo_frames > 0 and neither team sprints more than ~40% of game
  frames; `--humantest` shows `stamina_empty` > 0; a `--shots` screenshot shows the bar; scores stay in the
  CLAUDE.md range.
- Depends on: none.

**P1-02 | Audio manager (safe no-op) | gameplay | new `scripts/audio.gd`, `scripts/main.gd` (`_ready` and member vars only)**
- `audio.gd` extends Node; a small pool (about 6) of `AudioStreamPlayer`s. `play(name: String, volume_db := 0.0,
  pitch_jitter := 0.05)` looks for `res://assets/sfx/<name>.ogg` then `.wav` with `ResourceLoader.exists()`, caches
  the stream, and silently does nothing if no file exists (one `print` per missing name at most, never an error).
- Sound names (fixed now so later tasks can call them): `swish`, `rim`, `bounce`, `crowd`, `whistle`. Optional extras
  the art-audio task may fill: `dunk`, `block`, `fire`. Unknown names are also a no-op.
- `main.gd`: `var audio` created and added in `_ready()`; nothing else in `main.gd` changes.
- Stats: every `play()` call does `game.stat("sfx_<name>")` even when the file is missing.
- Done when: `--autoplay` runs with no `assets/sfx/` folder and no errors; a throwaway test with one dummy `.wav`
  (not committed) plays without errors; `assets/sfx/README.txt` is NOT needed (paths are documented in the script header).
- Depends on: none.

**P1-03 | FX layer and net animation | gameplay | new `scripts/fx.gd`, `scripts/court.gd`, `scripts/main.gd` (`_ready` and member vars only)**
- Same programmer as P1-02, done right after it (both touch `main.gd._ready`, so not in parallel with each other).
- `fx.gd` (Node2D, high `z_index`) API, all safe to call any time:
  - `shake(strength: float, time: float)`: offsets `game.camera.offset`, decays, ends at exactly zero.
  - `popup(text: String, world_pos: Vector2, color: Color, size: int)`: floating label that rises and fades
    (big, outlined, about 1 s). Used for "+2", "+3", "SLAM!", "ON FIRE!".
  - `set_trail(on: bool, color: Color)`: when on, draws a fading trail behind `game.ball` (fire colors), reading
    the ball's position and `z` each frame.
- `court.gd`: the rims instance gets a simple net (short lines hanging from the rim) and `swish(hoop_index: int)`
  that animates it (stretch and sway for about 0.4 s). Needs `queue_redraw()` only while animating.
- `main.gd`: `var fx` created and added in `_ready()`, `var rims` kept as a member so others can call
  `game.rims.swish(i)`.
- Stats: `shakes`, `popups`.
- Done when: a temporary debug call (removed before review) shows shake, popup, trail and net in a `--shots`
  screenshot; `--autoplay` unchanged and error-free; camera offset is zero after a shake.
- Depends on: P1-02 (same file region of `main.gd`).

**P1-04 | Source CC0 sound effects | art-audio | new `assets/sfx/*`, `CREDITS.md`**
- Find CC0 (or clearly commercial-redistribution) files for `swish`, `rim`, `bounce`, `crowd`, `whistle` (optional:
  `dunk`, `block`, `fire`). Short, trimmed, `.ogg` preferred (mono, under ~100 KB each), names exactly as above.
  Record each in `CREDITS.md` (name, author, source URL, license).
- **Blocked by network.** Needs the owner to allow at least `kenney.nl` (Kenney Impact Sounds / UI Audio, CC0) and
  `opengameart.org` (CC0 filter). Optional: `freesound.org` and `cdn.freesound.org` (CC0 filter only; downloads need a
  login, so less useful), `itch.io` and `img.itch.zone`/download hosts. Fallback: the owner downloads the packs and
  drops the files into `assets/sfx/`.
- Done when: the files import in Godot 4.3 with no errors and P1-02's manager plays each one; CREDITS.md updated.
- Depends on: P1-02 (names and folder); network access. Can run in any wave once unblocked (touches no script).

### Wave 2 (2 programmers in parallel)

**P1-05 | Auto-dunk and layup | gameplay | `scripts/player.gd`, `scripts/ball.gd`**
- Shoot near the rim (`DUNK_RANGE`, `LAYUP_RANGE`, in feet from the hoop being attacked) starts a dunk or layup
  instead of the shot meter. Human: press A near the rim. CPU: the existing `dist_ft < 4.5` drive finish becomes a
  dunk/layup. Which one (dunk or layup) follows the owner's answer to Q1; until then the default is: dunk if within
  `DUNK_RANGE` and moving at more than ~70% speed or on turbo, otherwise layup.
- Jump animation in `player.gd`: `jump_z` rises and falls over `DUNK_TIME` (layup: `LAYUP_TIME`), sprite drawn with
  that upward offset and a slight scale-up; player keeps a little momentum toward the rim. `ball.gd`: while held by a
  jumping player the ball sits at the player's `jump_z` + hand height; the dunk release is a very short, low shot
  (new `shoot()` parameter or a `quick` flag), the layup a short soft arc.
- Contest check at take-off: the nearest defender within `CONTEST_FT` gives a block chance
  (`DUNK_BLOCK_CHANCE`, layup `LAYUP_BLOCK_CHANCE`, scaled by distance) using the existing `game.block_shot()`, and
  lowers make odds through `game.release_shot(self, quality)` (pass a quality that gives about 85% open dunk,
  65% open layup, much lower when contested; `shot_probability()` already applies the openness penalty).
  No `main.gd` change: everything goes through `release_shot`, `block_shot`, `show_message`, `stat`, `fx`, `audio`.
- Feedback this task owns: "SLAM DUNK!" via `game.fx.popup`, `game.fx.shake(...)` on a made dunk, `game.audio.play("dunk")`.
- Proposed tunable defaults (top of `player.gd`): `DUNK_RANGE = 6.0`, `LAYUP_RANGE = 9.0`, `DUNK_TIME = 0.55`,
  `LAYUP_TIME = 0.45`, `CONTEST_FT = 4.0`, `DUNK_BLOCK_CHANCE = 0.18`, `LAYUP_BLOCK_CHANCE = 0.12`.
- Stats: `dunks`, `dunk_makes`, `layups`, `layup_makes`, `rim_blocks`.
- Done when: in 3 `--autoplay` games dunks and layups both happen for both teams, dunks are not more than about half
  of all shots, scores stay roughly 15-30 per team (the baseline shows ~90% of shots at the rim already, so watch it),
  `--humantest` exercises a human dunk; a screenshot or log line shows the jump.
- Depends on: P1-01 (`player.gd`), P1-03 (`fx`). Soft: P1-02 (`audio`).

**P1-06 | Game-event feedback in main | gameplay | `scripts/main.gd`**
- `on_shot_made`: bigger score popup at the hoop (`fx.popup("+2"/"+3", ...)`, team color, large), `audio.play("crowd")`,
  short top message kept but shorter. `block_shot`: `fx.shake(...)` + `audio.play("block")` (no-op if missing).
  `audio.play("whistle")` on shot clock violation, end of period and game over.
- Make the center message bigger/punchier (size, a quick scale-in) if it fits in `show_message`/`_update_message`.
- Do not touch `release_shot`'s odds or anything in `player.gd`/`ball.gd`.
- Stats: comes from `sfx_*`, `shakes`, `popups` counters in P1-02/P1-03.
- Done when: `--autoplay` stats show `sfx_crowd` about equal to makes, `sfx_whistle` = shot clock violations +
  periods + 1, `shakes` >= `blocks`; screenshot shows a popup; no errors.
- Depends on: P1-02, P1-03.

### Wave 3 (2 programmers in parallel)

**P1-07 | On fire | gameplay | `scripts/main.gd`, `scripts/player.gd`**
- Track consecutive makes (per player or per team: owner's answer to Q3; default per player). At 3 in a row the player
  is "on fire": "ON FIRE!" popup, `audio.play("fire")`, flame/glow drawn around the player in `player._draw()`, and
  `game.fx.set_trail(true, ...)` while that player holds or shoots the ball.
- Effect while on fire (owner's answer to Q4; default proposal: shot quality x`FIRE_SHOT_BONUS` = 1.15 and stamina
  drains at half speed). Ends on the owner's chosen rule (default: a miss, or the other team scores twice in a row);
  also ends at the end of the game, not at quarter breaks.
- Both teams can go on fire (CPU too), unless the owner says otherwise.
- Stats: `fire_starts_t0`, `fire_starts_t1`, `fire_shots`, `fire_makes`.
- Done when: over 5 `--autoplay` games `fire_starts` > 0 for at least one team in most games and FG% while on fire is
  not above ~65%; trail visible in a screenshot (temporary forced state allowed for the shot, removed before review).
- Depends on: P1-05 (`player.gd`), P1-06 (`main.gd`), P1-03 (`set_trail`).

**P1-08 | Ball and rim feedback | gameplay | `scripts/ball.gd`**
- `audio.play("bounce")` when a loose ball hits the floor with real speed (not every tiny bounce) and a soft bounce
  for the dribble (rate-limited, quiet, maybe every other dribble). `swish` + `game.rims.swish(i)` when a made shot
  reaches the hoop; `rim` (+ a small net wiggle) on a miss rim-out.
- Do not change shot timing or the make/miss logic.
- Stats: `sfx_*` counters from P1-02 cover it.
- Done when: `--autoplay` stats show `sfx_swish` = makes, `sfx_rim` about equal to misses, `sfx_bounce` reasonable
  (not thousands per game unless the dribble sound is intended and quiet); net animation visible in a screenshot.
- Depends on: P1-05 (`ball.gd`), P1-02, P1-03.

### Wave 4

**P1-09 | Phase 1 QA and balance pass | qa | `docs/qa/phase1.md` (report); tuning constants at the top of `player.gd`/`main.gd` only if needed, listed in the report**
- 10 `--autoplay` games, 2 `--humantest` games, `--shots` screenshots. Compare to `docs/qa/baseline-pre-phase1.md`.
- Check: 45-70 shots, 15-30 points per team, few intercepts and shot clock violations; dunks + layups per game and
  their FG%; share of shots under 5 ft (baseline ~90%); turbo frames per team and `stamina_empty`; `fire_starts` per
  team and fire FG%; `sfx_*` counts match events; `shakes`, `popups`; any BLUE vs RED bias over 10 games; no script
  errors or warnings in the log; camera offset not stuck after shakes.
- Done when: report written with a table per game and a pass/fail line per feature; tuning changes (if any) listed with
  before/after numbers.
- Depends on: P1-01 to P1-08 merged (P1-04 optional: report says if sounds are real files or still missing).

**P1-10 | README how-to-play update | gameplay | `README.txt`**
- Add turbo (push the stick to the edge), dunks/layups (Shoot near the rim), on fire, and the new tunable constants
  to "EASY THINGS TO CHANGE".
- Done when: text matches the merged behavior and the owner's answers.
- Depends on: P1-07, P1-08. Can run in parallel with P1-09.

## Parallel plan

| Wave | Programmer A | Programmer B | Other |
|---|---|---|---|
| 1 | P1-01 turbo (`player.gd`) | P1-02 audio, then P1-03 fx + net (`audio.gd`, `fx.gd`, `court.gd`, `main.gd` `_ready`) | P1-04 art-audio, as soon as hosts are allowed |
| 2 | P1-05 dunk/layup (`player.gd`, `ball.gd`) | P1-06 main feedback (`main.gd`) | |
| 3 | P1-07 on fire (`main.gd`, `player.gd`) | P1-08 ball/rim feedback (`ball.gd`) | |
| 4 | P1-10 README | | P1-09 QA |

Why this order: `player.gd` is serial P1-01 -> P1-05 -> P1-07; `main.gd` is serial P1-02/03 -> P1-06 -> P1-07;
`ball.gd` is serial P1-05 -> P1-08. New `audio.gd`/`fx.gd` with fixed APIs let feature tasks call feedback without
editing each other's files. Each wave merges and gets a quick QA run before the next starts.

## Owner answers (2026-11-15, also in docs/VISION.md)
1. **Dunk or layup:** automatic by distance and speed (very close + fast or turbo = dunk, otherwise layup). No shot
   meter for either. Player ratings may add to this in the campaign.
2. **Turbo with the ball:** handler sprints slightly slower (0.95x); jump shots right after sprinting are less
   accurate; dunks and layups are not penalized. (Added to P1-01 as a follow-up.)
3. **On fire, who:** one player, 3 makes in a row, dunks and layups count.
4. **On fire, what and until when:** bigger green zone on the meter, stamina doesn't drain, flaming trail. Ends on that
   player's miss or when the other team scores. CPU players can catch fire.
5. **Sound:** pending; the coordinator is asking the owner to allow the hosts.

## Doing
- P1-04 sound effects (art-audio, OpenGameArt only: kenney.nl refuses scripted downloads)
- P1-05 auto-dunk and layup
- P1-06 game-event feedback in main

## Review

## Done
- P1-01 turbo and stamina (approved; merged 2be15df). Includes owner answer 2: handler 0.95x, jumpers within 0.6 s
  of sprinting x0.8 quality, no penalty inside 6 ft. Also changed: on a fast break the backcourt handler heads for
  the rim.
- P1-02 audio manager (approved; merged). Headless runs skip playback but still count `sfx_<name>`.
- P1-03 FX layer and nets (approved; merged).
- Combined wave 1 check: 3 autoplay games 14-18, 14-16, 20-16; humantest 14-22; no script errors.

### Follow-ups for P1-09 QA (from reviews)
- `turbo_frames_t*` counts player-frames; per-player usage = turbo_frames / (frames x 3). Currently about 6%.
- CPU turbo (about 6%) may be too rare to see: consider lower `CPU_BREAK_FT` or a wider `lane_open` rule.
- Stamina bar is 44x7 px: consider 9-10 px tall for the tablet.
- Stamina doesn't reset between quarters (open question for the owner at check-in).
- Play a real sound once under xvfb after P1-04 lands (headless never plays audio).
- Check the popup pop-in (1.5x scale) doesn't look jagged with nearest filtering.
