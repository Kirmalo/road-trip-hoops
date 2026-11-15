# Phase 2 QA and balance pass (P2-13)

Build tested: commit `a83efd1` (P2-01 to P2-12 merged), then the same build with the tuning changes below.
Godot 4.3-stable (Linux), headless, `--fixed-fps 60 --quit-after 60000`. Every run printed `FINAL`, with no script
errors or warnings. The import was clean.

Runs:
- **Before tuning:** 168 `--autoplay` games (3 batches: 42 + 42 + 84) and 4 `--humantest`.
- **Tuning step 1** (`CPU_LOB_CHANCE`, `CPU_FAKE_BITE`, `CPU_SHOT_QUALITY_MIN` 1.0): 60 autoplay and 3 humantest.
- **Final** (step 1 plus `CPU_SHOT_QUALITY` 1.05..1.25): 60 autoplay and 3 humantest.
- **Balance experiments** on throwaway copies of the project, not committed: reversed player update order (84 games),
  sides swapped (168), inbound spot mirrored (120), every absolute-y literal mirrored (120).
- **Gesture tests** on throwaway copies: 3 humantests with 235 scripted lift-and-re-touch thumbs, and 2 humantests with
  SHOOT taps every 0.45 s to exercise the pump-fake cooldown.
- **Screenshots:** xvfb `--shots --humantest`, with a temporary hook that saved a crossover, a pump fake, a lob, a block
  jump, a live CALL and a beaten defender to the scratch directory.
- **Browser:** `tools/build_web.sh`, `build/web` served with `python3 -m http.server`, Playwright Chromium
  800x450 with `hasTouch`/`isMobile`, and CDP `Input.dispatchTouchEvent`. Two scripted sessions.

Games take about 5 s each headless, so the sample is large. The team-balance question needed a big sample.

## Summary

| Check | Target | Before (168 games) | Final (60 games) | Result |
|---|---|---|---|---|
| Script errors (import, autoplay, humantest, xvfb, browser console) | none | none | none | PASS |
| Shots per game | 45-70 | 61.7 (48-81); 12 games over 70 | 60.4 (46-78); 3 over 70 | PASS (mean); upper tail a little long |
| Points per team | 15-30 | 23.6 (10-40); 17 of 336 under 15, 36 over 30 | 22.9 (12-36); 4 of 120 under 15, 12 over 30 | PASS |
| Interceptions | few | 3.1 (0-8) | 2.9 (0-7) | PASS |
| Shot-clock violations | few | 0 | 0 (also 0 in all 10 humantests) | PASS |
| Overtime games | (P1: 16%) | 11 of 168 (6.5%) | 3 of 60 (5%) | info |
| Blocks | 3-8 | 7.0 (2-19) | 6.7 (2-12) | PASS |
| Steals | 6-12 | 8.2 (2-19) | 8.7 (3-18) | PASS |
| Crossovers per team | 4-12 | 9.5 (3-18) | 10.0 | PASS |
| Crossover beats the defender | 25-45% | 37.3% | 35.0% | PASS |
| Pump fakes per team | 2-6 | 4.35 | 4.5 | PASS |
| Fake bites | 30-50% | 46.3% (top of range) | 39.4% | PASS after tuning |
| Alley-oops (lobs thrown) | 1-4 | 4.2 (0-12) | 2.9 (1-6) | FAIL before, PASS after tuning |
| Alley-oop catches / makes | - | 3.5 / 1.8 | 2.5 / 1.3 | info |
| CPU jumpers, share of shots | 15-30% | 23.8% (14.7 per game) | 24.7% (14.9 per game) | PASS |
| CPU jumper FG% | ~35-42% | 33.8% | 35.7% | FAIL before, PASS after tuning |
| Threes | a few | 4.9 attempts, 1.4 made | 4.8 / 1.4 | PASS |
| Rim attempts "contested" (R2) | 60-80% | 76.5% | 78.4% | PASS |
| B1: `shakes` = `blocks` + `dunk_makes` | every game | yes (168/168) | yes (60/60) | PASS |
| `sfx_whistle` = shot clock + periods + 1 | every game | yes | yes | PASS |
| Steals not flat: shielded (exposure 0) pokes | ~never | 59 shielded pokes; chance is exactly 0 by `steal_chance` | same | PASS |
| Steals not flat: badly timed pokes | rare | 33 of 1374 steals (2.4%) came from badly timed pokes | 11 of 521 | PASS |
| Humantest: timed pokes vs random pokes | timed >> random | timed 102/145 steal (70%), random 19/307 (6%), over 10 runs | | PASS |
| Humantest: timed block jumps vs early jumps | timed > early | timed 21/77 block (27%), early 19/100 (19%), over 10 runs | | PASS, gap modest (see F3) |
| Humantest: flicks = snaps | equal | 391 = 391 over 10 runs | | PASS |
| Humantest: smooth turns and turbo pulls give no flicks | 0 | 0 (255 turns + 255 pulls) | | PASS |
| Humantest: taps outside the rim range = pump fakes | equal | 191 taps = 191 fakes | | PASS |
| No dunk started late (no lag on A near the rim) | - | dunks/layups start on the press (the 0.15 s tap window only applies to the meter) | | PASS (code read + human_dunks every run) |
| Pump-fake cooldown (`PUMP_COOLDOWN` 0.8) | works | fakes + cooldown taps = short taps (35+12 = 47, 50+22 = 72) | | PASS |
| Re-touch false flicks (60 fps, Godot) | 0 | 0 in 235 re-touches (90-180 degree new direction, half with a 50-degree landing wobble) | | PASS |
| Re-touch false flicks (browser, 13-25 fps) | 0 | 0 in 16 re-touches (8 with a wobble) | | PASS |
| Deliberate flicks in the browser at 13-25 fps | detected | 2 of 6 | | FAIL at low fps (known, see F2) |
| Team balance | no clear bias | BLUE 24.0 - RED 23.1, wins 86-82 | BLUE 22.5 - RED 23.2, wins 29-31 | small court-side edge, see "Team balance" |
| HUD and buttons at 1280x720 | readable, not covering play | readable; buttons cover the bottom-right corner spot | | PASS, see F4 |
| Web build: load, flick, SHOOT tap, console | no errors | loads; only GL "ReadPixels" perf warnings and the pre-touch AudioContext warning | | PASS |

## Tuning changes (constants only)

| Constant | File | Old | New | Why |
|---|---|---|---|---|
| `CPU_LOB_CHANCE` | `player.gd` | 0.25 | 0.18 | Lobs were 4.2 per game (0-12), above the 1-4 target. Now 2.9-3.4 (1-6 in the final batch). |
| `CPU_FAKE_BITE` | `defense.gd` | 0.4 | 0.35 | CPU defenders bit on 46% of fakes, at the top of the 30-50% range. Now 39-42%. |
| `CPU_SHOT_QUALITY_MIN` / `_MAX` | `player.gd` | 0.95 / 1.2 | 1.05 / 1.25 | CPU jumpers went in 33.8% of the time over 168 games, below the 35-42% target (P2-11's 38.9% was measured on 24 games). Step 1 (1.0 / 1.2) gave 33.6%, inside the noise. The final 1.05 / 1.25 gives 35.7% over 896 jumpers. |

Step by step:

| Build | Games | Points B / R | Shots | FG% | Jumper FG% | Jumper share | Lobs | Alley makes | Fake bites | Blocks | Steals |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Before (`a83efd1`) | 168 | 24.0 / 23.1 | 61.7 | 37.4% | 33.8% | 23.8% | 4.2 | 1.8 | 46.3% | 7.0 | 8.2 |
| Step 1: lob 0.18, bite 0.35, quality 1.0..1.2 | 60 | 24.4 / 23.4 | 61.9 | 37.8% | 33.6% | 23.6% | 3.4 | 1.6 | 41.6% | 6.7 | 8.2 |
| Final: quality 1.05..1.25 | 60 | 22.5 / 23.2 | 60.4 | 37.0% | 35.7% | 24.7% | 2.9 | 1.3 | 39.4% | 6.7 | 8.7 |

Compared with Phase 1's final build (80 games): shots 53.5 → 60.4, points 21.8 / 22.9 → 22.5 / 23.2, FG 41.7% →
37.0%, blocks 4.4 → 6.7, steals 7.8 → 8.7, interceptions 3.4 → 2.9, jump shots 1.1 → 14.9 per game, overtime 16% → 5%.

## Team balance

**Finding: the team that attacks the right-hand hoop has a small edge, about +0.7 points per game and 53% of wins.
It is tied to the side of the court, not to BLUE, the roster or the update order. I couldn't find the exact line.**

| Run | Games | Who attacks the right hoop | Right-hoop team minus left-hoop team, points/game (z) | Right-hoop team wins |
|---|---|---|---|---|
| Before tuning, as shipped | 168 | BLUE | +0.91 (z 1.4) | 86 of 168 |
| Player update order reversed (RED updates first) | 84 | BLUE | +0.90 (z 1.2) | 43 of 84 |
| **Sides swapped** (`attack_hoop`, `in_frontcourt`, start facing) | 168 | **RED** | **+1.11 (z 2.0)** | **102 of 168** |
| Inbound spot mirrored (`own.y - 5 ft`) | 120 | BLUE | +0.57 (z 0.8) | 67 of 120 |
| All absolute-y literals mirrored (inbound, period start rows, start spots) | 120 | BLUE | +0.19 (z 0.3) | 57 of 120 |
| Tuning step 1 / final | 60 + 60 | BLUE | +1.03 / -0.67 | 31 / 29 of 60 |
| **All 780 games** | | | **+0.68 (z ≈ 2.4)** | **415 of 780 (53.2%)** |

What this rules out:
- **Update order** (team 0 runs before team 1 every frame): reversing it didn't change the edge. It did move steals a
  little toward the team that updates second (RED steals 4.49 vs BLUE 4.10 with RED first, the other way round as
  shipped). It doesn't move points.
- **BLUE itself, roster slot or ratings, any `is_human` / `HUMAN_TEAM` path in autoplay**: when the sides swap, the edge
  goes with the right hoop to RED. In autoplay `is_human()` is always false. The only `HUMAN_TEAM` code that runs is
  `on_ball_held` and `do_pass` bookkeeping of `human_player`, which changes no movement.
- **Possession order**: quarter openings are team-based (BLUE in Q1, Q4 and OT), not side-based, and per-team shot
  counts are level (31.2 vs 30.7).

Most likely cause (not proven): the court is mirrored left to right (`spot_pos`, `inward`), but anything that uses
"left/right of facing" is rotated (`dribble_side`, `Vector2.from_angle(facing + PI / 2)`, `d.orthogonal()` in the CPU
sidestep and crossover, `side := 1.0 if d.cross(r) > 0.0 else -1.0`). Mixed with literals that use absolute y (inbound at
`own.y + 5 * FT`, period-start rows `[0, -12, 12]`, start spots `[0, 1, 4]`), the two halves of the court play
slightly differently. Mirroring the absolute-y literals cut the edge from about +0.9 to +0.19, but that is within the
noise (±0.7), so it is a lead, not proof.

Impact: small (about 3% of a team's points). It favours the human's team, since BLUE attacks right, so it is not
unfair to the player. VISION's "switching sides at the midpoint" (Phase 3) cancels it over a game. Logged as bug B1
below. Not tuned, because no constant controls it.

Per-team numbers before tuning (168 games, BLUE attacks right): points 24.02 / 23.11, shots 31.2 / 30.7, makes
11.6 / 11.2, jumper makes 2.64 / 2.33 (35.2% / 32.4%), threes made 0.72 / 0.64, dunks 11.85 / 11.85, layups 11.8 / 11.7,
blocks 3.32 / 3.70, steals 4.23 / 3.95, lobs 2.06 / 2.12, rim cuts 4.2 / 4.2, crossovers 9.43 / 9.54, cross beats
3.64 / 3.43, pump fakes 4.30 / 4.40, fakes bitten on 1.96 / 1.84, fire starts 0.82 / 0.77, turbo and guard-slow frames
level. Most of the gap is jump-shot makes. With sides swapped, the right-hoop team (RED) made slightly more jumpers
and threes. The right-hoop team was also blocked a little more often in both setups (622 vs 558, 604 vs 560).

Final build (60 games): BLUE / RED points 22.5 / 23.2, shots 30.5 / 30.2, makes 10.8 / 11.3, jumpers 7.3 / 7.7
(made 2.7 / 2.6), threes made 0.83 / 0.62, blocks 3.0 / 3.7, steals 4.4 / 4.3, lobs 1.5 / 1.4, crossovers 9.6 / 10.3
(beats 3.5 / 3.5), pump fakes 4.8 / 4.2, wins 29 / 31.

## Gesture and input checks

- **Flicks (humantest, 60 fps):** `human_flicks` = `humantest_snaps` in all 10 runs (391 total). Smooth 180-degree turns
  and radial turbo pulls gave 0 flicks.
- **Re-touch false flicks:** a throwaway humantest copy lifted the scripted thumb every 1.7 s of ball time. It touched
  down up to 30 px away and pushed a new direction 90, 130, 180 or -130 degrees off; every second re-touch first landed
  50 degrees off and then corrected. Result: 0 flicks in 235 re-touches, and flicks still equal snaps. The browser
  session (13-25 fps) gave 0 false flicks in 16 re-touches. The board's proposed change (don't record samples while
  `_touch_age < FLICK_TOUCH_IGNORE`) isn't needed on this evidence. It is still a cheap safety net (see R3).
- **Pump fake:** taps = fakes in every humantest (191). With taps every 0.45 s, `pump_cooldown_taps` fired 12 and 22
  times, and fakes plus cooldown taps equal the short taps. A tapped-out fake keeps the ball and does nothing, as the
  constant's comment says.
- **Steal timing:** timed pokes (button lit) steal 70%, random pokes 6%. The CPU only steals on a well-timed poke (97.6% of
  CPU steals).
- **Block timing:** timed jumps block 27%, early ones 19% (10 runs). Well-timed is better, but "early" in the humantest
  means "pressed as the CPU shot starts", which often still meets a slow windup or a layup. See F3.
- **CALL:** 31-38 calls per humantest, 6-10 answered at once; the rest time out or are cancelled (the script parks the
  thumb with its own man in the lane, as P2-10 noted). Human alley-oop catches 0-5 per run.

## Screenshots (xvfb `--shots --humantest`, plus the temporary hook)

Viewed: default frames 240/900/1800/3600, `hoops_steal_cue`, `hoops_block_label`, and hook frames for a crossover (x3),
a pump fake (x3), a lob, a block jump (x3) and a live CALL (x3).
- HUD (quarter clock, score, shot clock) readable on every frame; nothing off screen at 1280x720.
- Crossover: motion streaks behind the handler and the ball on the new hand, clear.
- Pump fake: the ball goes up over the head; the hop is small. Clearer in the browser frame than in xvfb.
- STEAL cue: solid yellow button with a thick ring, very visible. BLOCK label: deeper orange with an up arrow, clearly
  different from STEAL.
- CALL: "BALL!" popup, a pass-lane cue line from the passer, and a lit light-blue CALL button with a ring. Clear.
- Lob: the ball is caught early in flight, so the arc height isn't obvious in a still frame.
- See F4 for button overlap.

## Browser check (web build, as the owner plays)

`tools/build_web.sh` → `build/web` (35 MB, not committed). Chromium 800x450, touch emulation, software WebGL at 13-25 fps.
- Loads to the court; the console shows only the engine banner, `human_input: debug log on` (the `?debug_input` URL),
  GL "GPU stall due to ReadPixels" performance warnings (caused by the screenshots), and the AudioContext autoplay
  warning before the first touch. No errors, no `pageerror`.
- Joystick: steering works, turbo pull shows "turbo pull" when the finger goes past 1.5 rings.
- A short SHOOT tap (60 ms) was read as `short tap 0.150 s` and made a pump fake (ball over the head in the frame). A
  0.7 s hold showed the meter and shot. B on defense = SWITCH.
- Deliberate flicks: 2 of 6 detected at 13-25 fps (F2). 0 false flicks from 1 smooth 90-degree turn, 2 s of circular
  steering and 16 re-touches.

## Bugs and findings

**B1 (balance, small): the team attacking the right hoop scores about 0.7 points per game more (53% of wins).**
- Steps: run 100+ `--autoplay` games; then swap the hoops (`attack_hoop`, `in_frontcourt`, the start `facing`) and run
  100+ more.
- Expected: no side or team bias.
- Actual: the right-hoop team is ahead in both setups (BLUE +0.91 as shipped; RED +1.11 with sides swapped). Pooled
  over 780 games: +0.68 points per game, z ≈ 2.4. Not the update order (reversing it changed nothing). Likely a mix of
  left/right-of-facing logic (hand side, sidestep sign, crossover direction) with absolute-y literals (inbound
  `own.y + 5 * FT`, period-start rows, start spots). Mirroring those literals for one experiment reduced it to +0.19
  (within the noise).
- Suggested fix (code, not a constant): make the absolute-y literals relative to the attacking direction (e.g.
  multiply by `inward(attack_hoop(team))`) and break the `d.cross(r) == 0` sidestep tie randomly. Then re-measure over
  200+ games with sides swapped. Low priority: switching sides at halftime in Phase 3 cancels it.

**F2 (known, browser only): flicks are missed at low frame rates.** At 13-25 fps (software rendering) 2 of 6 clean
flicks fired. The two-step snap spans 2-3 frames, and the old-direction sample is more than `FLICK_WINDOW` (0.12 s)
old by the time the new direction arrives. Tablets at 30-60 fps are fine (391/391 at 60 fps). Fix from P2-06: compare
with the last strong sample even if it is one frame older than the window.

**F3 (feel): early block jumps still work 19% of the time** (timed jumps 27%). The jump lasts `BLOCK_JUMP_TIME`
0.5 s and a block needs `BLOCK_HEIGHT_MIN` 0.6 of the height, so an "early" press 0.1-0.2 s before the release often
still lands in the window. Not a bug; if the owner finds blocking too easy, raise `BLOCK_HEIGHT_MIN` 0.6 → 0.7.

**F4 (layout): the touch buttons sit over the bottom-right corner spot.** When BLUE attacks right and the camera is on
the right half, a BLUE player in the right corner (`SPOTS` index 4) is often drawn under PASS or SHOOT (seen in several
hook frames and in the browser). The floating joystick also covers the bottom-left paint when play is on the left
hoop, but that is where the thumb is anyway. Suggest moving the buttons lower or a little smaller, or nudging the
camera so the ball sits above the buttons. Owner to judge.

**F5 (test harness): humantest scores run high** (17-46 points per team, about 80 shots), because the script shoots
every 97 frames from anywhere and keeps calling. That is expected, not a game bug.

No crashes, no stuck players or balls, no games that failed to end (max 3 overtimes, all finished within 60000
frames), and no shot-clock violations in 780 autoplay games.

## Recommended follow-ups
- **R1:** fix B1 (absolute-y literals relative to the attacking direction, random sidestep tie-break), or leave it to
  Phase 3's side switch. Re-measure with sides swapped.
- **R2:** F2 flick window at low fps (one-line change in `human_input.gd`).
- **R3 (optional):** don't record flick samples while `_touch_age < FLICK_TOUCH_IGNORE`. 0 false flicks were seen, so
  this is a safety net only.
- **R4:** F4 button and corner overlap (layout change in `touch_controls.gd`, or a small camera offset).
- **R5 (Phase 3 targets, for the lead to confirm):** at first to 21 with 1s and 2s, today's pace (about 60 shots and
  23 points per team per 8 minutes, 37% FG) is about 22 makes per game. Proposed targets: a game to 21 lasts about
  45-60 shots and 6-9 minutes; winner exactly 21-22 (a 2 from 20); loser 10-19; 2-pointers (today's threes) 8-15% of
  shots at 28-35%; blocks 4-7, steals 5-10, alley-oops 1-3 per game; side switch at 11. Re-check B1 after the switch.

## For the owner to judge on the tablet
1. **Crossover:** does a quick flick feel reliable, with no accidental crossovers when you lift and re-place your thumb?
   About 1 in 3 crossovers shakes a CPU defender.
2. **Pump fake:** a short tap of SHOOT. Is the hop easy enough to see? CPU defenders now bite about 40% of the time. Is
   the 0.8 s before the next fake noticeable?
3. **Blocks:** jumping a little early still blocks fairly often. Too easy, or about right?
4. **Steals:** is the yellow STEAL cue easy to time? Well-timed pokes steal about 70% of the time.
5. **Alley-oops:** the CPU now throws about 3 lobs per game (was 4). Enough to feel special?
6. **CPU jump shots:** about 15 per game at about 36%, 1-2 threes made. Does the CPU feel like a threat from outside?
7. **Buttons:** do PASS and SHOOT hide your teammate in the bottom-right corner?
8. **CALL:** does the lit CALL button and the "BALL!" popup make it clear your teammate heard you?

## Per-game tables

Columns: "Blocks/Steals B/R" are by BLUE / by RED. "Cross B/R (beats)" are crossovers by each team and how many beat a
defender. "Fakes B/R (bites)" are pump fakes by each team and how many a defender bit on. "Lobs B/R (alley makes)" are
alley-oop lobs thrown by each team and alley-oop dunks made. "SCV" is shot-clock violations.

### Final build, 60 autoplay games

| # | Final (B-R) | OT | Shots | FG% | Jumpers (made) | 3s (made) | Dunks (made) | Layups (made) | Blocks B/R | Steals B/R | Int | Cross B/R (beats) | Fakes B/R (bites) | Lobs B/R (alley makes) | SCV |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 23-36 | 0 | 66 | 42 | 21 (14) | 6 (3) | 17 (8) | 28 (8) | 3/7 | 2/4 | 4 | 16/12 (11) | 2/3 (2) | 1/2 (2) | 0 |
| 2 | 25-22 | 0 | 57 | 40 | 17 (5) | 6 (1) | 12 (6) | 28 (12) | 2/4 | 3/4 | 1 | 8/13 (6) | 1/7 (1) | 0/2 (2) | 0 |
| 3 | 12-28 | 0 | 60 | 33 | 15 (6) | 3 (0) | 21 (7) | 24 (8) | 4/4 | 3/1 | 6 | 9/6 (5) | 3/2 (2) | 2/1 (1) | 0 |
| 4 | 27-24 | 2 | 78 | 32 | 16 (5) | 3 (1) | 26 (9) | 36 (11) | 4/1 | 3/5 | 1 | 11/15 (11) | 4/5 (2) | 1/0 (0) | 0 |
| 5 | 31-21 | 0 | 59 | 42 | 12 (5) | 5 (3) | 20 (7) | 28 (14) | 3/1 | 9/7 | 2 | 11/8 (5) | 4/5 (3) | 1/2 (0) | 0 |
| 6 | 17-24 | 0 | 66 | 30 | 18 (4) | 6 (1) | 23 (8) | 25 (8) | 1/7 | 3/1 | 6 | 9/6 (5) | 3/4 (4) | 3/3 (1) | 0 |
| 7 | 24-12 | 0 | 52 | 33 | 13 (3) | 7 (2) | 20 (8) | 19 (6) | 2/3 | 10/6 | 2 | 7/8 (6) | 6/4 (3) | 1/4 (1) | 0 |
| 8 | 21-19 | 0 | 53 | 36 | 14 (5) | 4 (2) | 18 (7) | 21 (7) | 3/5 | 12/6 | 2 | 12/11 (14) | 7/2 (2) | 1/0 (1) | 0 |
| 9 | 24-26 | 0 | 66 | 38 | 14 (3) | 4 (0) | 28 (10) | 24 (12) | 5/6 | 0/3 | 2 | 8/18 (14) | 7/6 (7) | 0/1 (1) | 0 |
| 10 | 26-19 | 0 | 51 | 43 | 14 (4) | 5 (2) | 19 (8) | 20 (11) | 0/6 | 7/2 | 3 | 11/10 (6) | 7/2 (2) | 3/0 (2) | 0 |
| 11 | 26-21 | 0 | 62 | 37 | 14 (6) | 4 (1) | 24 (12) | 24 (6) | 2/7 | 7/3 | 2 | 12/13 (13) | 4/8 (3) | 2/1 (2) | 0 |
| 12 | 26-19 | 0 | 66 | 33 | 20 (5) | 5 (2) | 15 (4) | 31 (15) | 2/7 | 3/3 | 3 | 11/18 (8) | 7/4 (6) | 1/1 (0) | 0 |
| 13 | 16-21 | 0 | 55 | 33 | 18 (4) | 10 (1) | 18 (11) | 20 (3) | 3/3 | 1/4 | 5 | 9/11 (8) | 2/2 (0) | 1/1 (2) | 0 |
| 14 | 24-21 | 0 | 64 | 34 | 15 (4) | 4 (1) | 27 (11) | 22 (7) | 7/2 | 4/6 | 1 | 4/16 (6) | 3/4 (3) | 2/2 (1) | 0 |
| 15 | 30-17 | 0 | 71 | 30 | 19 (8) | 10 (5) | 24 (8) | 28 (6) | 4/4 | 5/2 | 1 | 6/14 (6) | 6/11 (8) | 2/1 (2) | 0 |
| 16 | 22-18 | 0 | 46 | 43 | 12 (3) | 2 (0) | 13 (8) | 21 (10) | 1/3 | 2/6 | 0 | 17/8 (7) | 3/7 (6) | 0/1 (1) | 0 |
| 17 | 22-28 | 0 | 59 | 42 | 16 (5) | 3 (0) | 20 (8) | 24 (12) | 1/1 | 6/6 | 1 | 9/12 (7) | 2/2 (4) | 1/2 (1) | 0 |
| 18 | 22-20 | 1 | 77 | 27 | 19 (7) | 6 (1) | 29 (9) | 29 (6) | 4/6 | 5/4 | 1 | 13/10 (4) | 6/3 (3) | 2/0 (0) | 0 |
| 19 | 16-22 | 0 | 52 | 37 | 13 (4) | 2 (0) | 20 (9) | 20 (6) | 5/1 | 5/4 | 1 | 11/11 (11) | 6/6 (5) | 1/0 (0) | 0 |
| 20 | 31-32 | 0 | 61 | 51 | 19 (9) | 3 (1) | 21 (10) | 21 (12) | 3/3 | 2/3 | 3 | 10/7 (5) | 2/2 (2) | 3/2 (2) | 0 |
| 21 | 17-14 | 0 | 54 | 28 | 14 (4) | 6 (1) | 21 (6) | 20 (5) | 1/3 | 4/3 | 7 | 14/5 (6) | 6/6 (5) | 2/0 (0) | 0 |
| 22 | 22-18 | 1 | 64 | 31 | 18 (5) | 4 (0) | 24 (9) | 23 (7) | 2/2 | 6/6 | 4 | 10/14 (8) | 12/5 (7) | 1/2 (3) | 0 |
| 23 | 31-20 | 0 | 64 | 38 | 17 (7) | 4 (3) | 23 (13) | 24 (4) | 5/2 | 4/4 | 7 | 4/12 (7) | 6/2 (5) | 1/3 (4) | 0 |
| 24 | 29-17 | 0 | 68 | 32 | 17 (4) | 4 (2) | 32 (16) | 19 (2) | 5/1 | 7/4 | 6 | 3/9 (3) | 4/8 (3) | 5/1 (3) | 0 |
| 25 | 23-20 | 0 | 63 | 33 | 12 (4) | 3 (1) | 22 (7) | 29 (10) | 2/3 | 1/2 | 2 | 17/8 (5) | 3/6 (3) | 3/0 (1) | 0 |
| 26 | 26-25 | 0 | 62 | 40 | 11 (4) | 1 (1) | 23 (9) | 28 (12) | 2/4 | 4/1 | 3 | 11/8 (10) | 2/8 (6) | 1/2 (3) | 0 |
| 27 | 18-20 | 0 | 63 | 29 | 12 (3) | 4 (2) | 23 (7) | 28 (9) | 2/5 | 3/5 | 4 | 12/6 (10) | 4/4 (3) | 2/1 (0) | 0 |
| 28 | 24-28 | 0 | 59 | 44 | 14 (7) | 2 (0) | 21 (9) | 24 (10) | 3/5 | 4/2 | 1 | 12/10 (10) | 2/4 (2) | 2/2 (2) | 0 |
| 29 | 22-29 | 0 | 64 | 38 | 15 (6) | 4 (3) | 27 (12) | 23 (6) | 1/3 | 1/4 | 3 | 6/10 (7) | 4/5 (5) | 5/1 (3) | 0 |
| 30 | 26-27 | 0 | 66 | 36 | 19 (8) | 7 (5) | 24 (7) | 23 (9) | 2/3 | 5/4 | 3 | 11/13 (9) | 7/2 (5) | 3/2 (1) | 0 |
| 31 | 17-20 | 0 | 64 | 28 | 16 (2) | 4 (1) | 22 (9) | 27 (7) | 2/7 | 7/2 | 3 | 7/16 (7) | 2/6 (4) | 1/0 (0) | 0 |
| 32 | 25-26 | 0 | 56 | 45 | 16 (5) | 3 (1) | 23 (12) | 17 (8) | 4/2 | 6/7 | 3 | 7/10 (7) | 6/4 (5) | 1/1 (1) | 0 |
| 33 | 27-18 | 0 | 60 | 37 | 8 (3) | 3 (1) | 24 (9) | 28 (10) | 5/2 | 4/2 | 3 | 8/8 (4) | 4/4 (2) | 2/3 (1) | 0 |
| 34 | 18-19 | 0 | 60 | 30 | 13 (4) | 6 (1) | 21 (12) | 26 (4) | 4/4 | 0/3 | 6 | 4/10 (4) | 6/4 (3) | 1/2 (2) | 0 |
| 35 | 31-21 | 0 | 61 | 41 | 11 (5) | 5 (2) | 21 (9) | 29 (11) | 4/3 | 8/5 | 3 | 10/10 (8) | 7/5 (3) | 1/2 (3) | 0 |
| 36 | 26-23 | 0 | 57 | 39 | 17 (9) | 8 (5) | 22 (9) | 18 (4) | 2/3 | 4/3 | 2 | 12/9 (4) | 5/2 (2) | 1/3 (0) | 0 |
| 37 | 19-22 | 0 | 62 | 32 | 14 (6) | 4 (1) | 24 (7) | 24 (8) | 6/1 | 4/1 | 2 | 13/9 (9) | 3/7 (7) | 1/1 (1) | 0 |
| 38 | 20-29 | 0 | 63 | 37 | 16 (8) | 8 (3) | 21 (5) | 26 (11) | 0/6 | 0/6 | 4 | 7/7 (3) | 3/1 (1) | 2/3 (1) | 0 |
| 39 | 17-19 | 0 | 57 | 30 | 12 (3) | 5 (2) | 18 (6) | 28 (8) | 6/3 | 6/8 | 3 | 9/5 (6) | 3/4 (1) | 1/3 (3) | 0 |
| 40 | 23-28 | 0 | 50 | 48 | 13 (5) | 5 (3) | 19 (13) | 18 (7) | 3/1 | 8/9 | 6 | 6/6 (3) | 2/4 (4) | 2/2 (2) | 0 |
| 41 | 14-24 | 0 | 57 | 33 | 13 (3) | 5 (0) | 20 (9) | 24 (7) | 1/4 | 1/6 | 1 | 10/14 (8) | 7/5 (4) | 0/2 (1) | 0 |
| 42 | 16-33 | 0 | 57 | 42 | 16 (7) | 2 (1) | 20 (7) | 22 (10) | 2/5 | 3/8 | 2 | 14/8 (8) | 7/5 (5) | 1/2 (1) | 0 |
| 43 | 16-26 | 0 | 54 | 39 | 13 (4) | 1 (0) | 20 (12) | 21 (6) | 4/2 | 7/4 | 3 | 12/8 (8) | 6/1 (1) | 1/0 (1) | 0 |
| 44 | 19-26 | 0 | 57 | 39 | 9 (6) | 2 (1) | 21 (8) | 27 (8) | 4/1 | 2/8 | 0 | 7/10 (5) | 8/4 (8) | 1/3 (2) | 0 |
| 45 | 34-33 | 0 | 62 | 52 | 24 (15) | 7 (3) | 19 (12) | 19 (6) | 1/6 | 8/2 | 3 | 8/7 (3) | 5/3 (6) | 2/1 (3) | 0 |
| 46 | 18-34 | 0 | 56 | 46 | 9 (5) | 2 (0) | 22 (11) | 25 (10) | 2/5 | 1/2 | 2 | 10/10 (5) | 3/2 (2) | 1/2 (2) | 0 |
| 47 | 22-18 | 0 | 63 | 32 | 14 (3) | 6 (0) | 27 (9) | 23 (8) | 4/1 | 6/7 | 3 | 10/8 (5) | 2/4 (3) | 2/3 (2) | 0 |
| 48 | 23-22 | 0 | 65 | 32 | 16 (4) | 10 (3) | 21 (11) | 28 (7) | 3/4 | 6/4 | 5 | 6/7 (1) | 6/1 (2) | 1/2 (2) | 0 |
| 49 | 19-35 | 0 | 57 | 46 | 15 (3) | 6 (2) | 18 (11) | 24 (12) | 2/1 | 0/9 | 3 | 8/16 (6) | 5/3 (1) | 4/0 (2) | 0 |
| 50 | 15-18 | 0 | 61 | 26 | 10 (3) | 6 (1) | 23 (8) | 28 (5) | 3/4 | 3/0 | 1 | 7/7 (3) | 9/5 (6) | 1/1 (0) | 0 |
| 51 | 18-24 | 0 | 64 | 33 | 20 (7) | 5 (0) | 19 (6) | 25 (8) | 2/5 | 2/5 | 5 | 11/6 (6) | 4/1 (2) | 1/0 (0) | 0 |
| 52 | 23-28 | 0 | 66 | 38 | 13 (4) | 5 (1) | 23 (10) | 31 (11) | 4/3 | 7/4 | 3 | 11/7 (6) | 6/3 (2) | 1/0 (0) | 0 |
| 53 | 24-25 | 0 | 55 | 44 | 14 (8) | 3 (1) | 20 (9) | 21 (7) | 4/1 | 3/2 | 3 | 6/12 (5) | 5/8 (4) | 2/1 (1) | 0 |
| 54 | 24-23 | 0 | 58 | 40 | 13 (3) | 4 (1) | 16 (6) | 29 (14) | 3/4 | 5/4 | 1 | 11/11 (12) | 6/3 (1) | 0/1 (1) | 0 |
| 55 | 30-20 | 0 | 52 | 48 | 14 (6) | 5 (0) | 23 (10) | 15 (9) | 4/3 | 11/5 | 2 | 15/12 (7) | 3/2 (1) | 3/3 (3) | 0 |
| 56 | 18-26 | 0 | 53 | 42 | 11 (6) | 2 (0) | 18 (8) | 24 (10) | 4/7 | 3/6 | 4 | 9/14 (13) | 9/5 (7) | 0/1 (0) | 0 |
| 57 | 27-20 | 0 | 61 | 38 | 15 (5) | 7 (1) | 20 (9) | 26 (10) | 1/6 | 6/5 | 3 | 8/13 (6) | 5/3 (4) | 1/0 (0) | 0 |
| 58 | 32-17 | 0 | 60 | 37 | 21 (9) | 9 (5) | 17 (6) | 22 (7) | 3/6 | 5/3 | 3 | 9/14 (10) | 2/2 (2) | 0/1 (1) | 0 |
| 59 | 16-30 | 0 | 63 | 37 | 15 (5) | 5 (1) | 20 (10) | 28 (9) | 7/5 | 3/6 | 1 | 8/11 (6) | 6/8 (6) | 2/1 (1) | 0 |
| 60 | 17-16 | 0 | 65 | 25 | 17 (3) | 9 (1) | 20 (8) | 28 (5) | 3/6 | 6/4 | 5 | 9/12 (7) | 9/4 (2) | 0/1 (0) | 0 |

### Before tuning (a83efd1), first 42 of 168 autoplay games

| # | Final (B-R) | OT | Shots | FG% | Jumpers (made) | 3s (made) | Dunks (made) | Layups (made) | Blocks B/R | Steals B/R | Int | Cross B/R (beats) | Fakes B/R (bites) | Lobs B/R (alley makes) | SCV |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 26-32 | 0 | 56 | 50 | 11 (4) | 6 (3) | 20 (10) | 25 (15) | 2/4 | 2/5 | 2 | 6/7 (5) | 3/9 (2) | 3/0 (1) | 0 |
| 2 | 28-22 | 0 | 61 | 41 | 13 (3) | 5 (0) | 24 (12) | 24 (10) | 4/2 | 3/6 | 1 | 8/7 (3) | 5/8 (6) | 3/3 (4) | 0 |
| 3 | 22-30 | 0 | 61 | 41 | 16 (11) | 5 (2) | 23 (10) | 22 (4) | 1/4 | 6/4 | 3 | 17/12 (16) | 7/5 (5) | 1/1 (0) | 0 |
| 4 | 27-34 | 0 | 66 | 44 | 12 (5) | 3 (3) | 28 (11) | 26 (13) | 2/7 | 2/4 | 3 | 12/8 (9) | 4/3 (3) | 3/1 (1) | 0 |
| 5 | 22-24 | 2 | 71 | 32 | 12 (2) | 3 (0) | 30 (11) | 29 (10) | 3/5 | 7/4 | 7 | 12/15 (7) | 7/3 (4) | 2/3 (2) | 0 |
| 6 | 26-28 | 0 | 57 | 47 | 12 (4) | 2 (0) | 20 (10) | 25 (14) | 5/3 | 9/6 | 3 | 13/9 (8) | 3/2 (4) | 0/1 (0) | 0 |
| 7 | 28-23 | 0 | 65 | 38 | 22 (9) | 7 (2) | 19 (9) | 24 (9) | 4/3 | 3/4 | 3 | 9/8 (6) | 3/5 (5) | 3/1 (2) | 0 |
| 8 | 22-26 | 0 | 67 | 36 | 15 (5) | 5 (0) | 26 (8) | 26 (11) | 4/5 | 4/3 | 6 | 6/13 (5) | 5/5 (2) | 5/1 (2) | 0 |
| 9 | 31-19 | 0 | 67 | 36 | 23 (7) | 8 (2) | 15 (8) | 29 (10) | 1/1 | 7/2 | 5 | 7/9 (7) | 3/6 (3) | 3/2 (1) | 0 |
| 10 | 27-26 | 0 | 60 | 43 | 16 (8) | 6 (1) | 18 (11) | 27 (9) | 3/3 | 2/5 | 3 | 5/10 (6) | 4/3 (2) | 2/2 (3) | 0 |
| 11 | 28-10 | 0 | 61 | 31 | 14 (3) | 3 (0) | 22 (11) | 25 (6) | 5/3 | 5/3 | 5 | 13/12 (9) | 7/3 (7) | 1/1 (0) | 0 |
| 12 | 26-16 | 0 | 62 | 34 | 12 (3) | 4 (0) | 29 (16) | 21 (2) | 6/2 | 5/5 | 4 | 10/4 (4) | 4/2 (1) | 0/2 (2) | 0 |
| 13 | 17-22 | 0 | 65 | 28 | 15 (5) | 4 (3) | 23 (8) | 30 (6) | 4/4 | 7/7 | 1 | 8/11 (7) | 2/4 (1) | 2/0 (0) | 0 |
| 14 | 21-29 | 0 | 61 | 39 | 16 (8) | 6 (2) | 18 (6) | 28 (10) | 2/5 | 3/4 | 2 | 3/4 (2) | 7/7 (5) | 0/3 (1) | 0 |
| 15 | 25-32 | 0 | 63 | 44 | 12 (2) | 5 (2) | 29 (19) | 23 (8) | 6/0 | 1/5 | 1 | 9/9 (6) | 1/3 (1) | 2/6 (4) | 0 |
| 16 | 21-30 | 0 | 73 | 34 | 13 (4) | 4 (1) | 37 (15) | 23 (7) | 2/7 | 3/4 | 2 | 11/6 (3) | 5/3 (6) | 5/4 (5) | 0 |
| 17 | 27-22 | 0 | 60 | 40 | 18 (2) | 4 (1) | 24 (14) | 18 (8) | 2/1 | 4/4 | 6 | 5/9 (6) | 4/5 (7) | 3/3 (3) | 0 |
| 18 | 32-12 | 0 | 49 | 43 | 11 (6) | 2 (2) | 18 (7) | 20 (8) | 4/3 | 10/4 | 6 | 9/9 (7) | 3/5 (3) | 3/1 (1) | 0 |
| 19 | 22-28 | 0 | 55 | 44 | 16 (5) | 4 (2) | 20 (11) | 19 (8) | 1/3 | 2/0 | 7 | 12/10 (6) | 5/3 (3) | 2/2 (3) | 0 |
| 20 | 27-15 | 0 | 60 | 33 | 17 (5) | 6 (2) | 28 (10) | 16 (5) | 3/4 | 9/5 | 0 | 8/5 (2) | 2/5 (1) | 3/4 (2) | 0 |
| 21 | 31-30 | 1 | 64 | 45 | 19 (10) | 6 (3) | 26 (14) | 19 (6) | 4/4 | 2/2 | 2 | 6/10 (8) | 2/4 (2) | 1/2 (3) | 0 |
| 22 | 27-32 | 0 | 64 | 42 | 15 (8) | 7 (5) | 23 (10) | 26 (10) | 1/7 | 2/2 | 4 | 9/6 (2) | 2/2 (3) | 3/2 (3) | 0 |
| 23 | 23-24 | 0 | 58 | 40 | 13 (6) | 6 (1) | 24 (10) | 23 (7) | 5/5 | 3/6 | 0 | 12/12 (10) | 3/5 (3) | 1/3 (1) | 0 |
| 24 | 28-23 | 0 | 51 | 49 | 10 (4) | 3 (1) | 15 (10) | 26 (11) | 1/4 | 4/2 | 1 | 15/8 (12) | 4/5 (4) | 2/0 (1) | 0 |
| 25 | 26-20 | 0 | 63 | 37 | 13 (2) | 3 (0) | 29 (12) | 21 (9) | 3/5 | 6/5 | 1 | 16/7 (2) | 8/3 (6) | 1/1 (1) | 0 |
| 26 | 18-20 | 0 | 66 | 27 | 12 (4) | 4 (2) | 23 (7) | 32 (7) | 2/3 | 5/4 | 3 | 11/7 (8) | 7/1 (4) | 1/0 (0) | 0 |
| 27 | 20-22 | 0 | 50 | 42 | 18 (9) | 5 (0) | 21 (12) | 11 (1) | 1/2 | 5/6 | 5 | 15/8 (5) | 1/5 (3) | 0/1 (0) | 0 |
| 28 | 22-20 | 0 | 67 | 31 | 16 (7) | 4 (1) | 24 (10) | 27 (7) | 4/4 | 4/6 | 2 | 4/15 (7) | 1/7 (3) | 1/1 (1) | 0 |
| 29 | 20-26 | 0 | 66 | 35 | 16 (6) | 4 (0) | 26 (7) | 24 (10) | 1/4 | 2/2 | 2 | 10/6 (9) | 4/7 (6) | 3/0 (1) | 0 |
| 30 | 24-23 | 0 | 56 | 39 | 7 (5) | 4 (3) | 28 (12) | 21 (6) | 4/5 | 5/4 | 3 | 9/18 (5) | 1/3 (3) | 1/4 (2) | 0 |
| 31 | 30-16 | 0 | 69 | 33 | 18 (3) | 5 (0) | 23 (11) | 28 (9) | 3/3 | 5/3 | 0 | 13/8 (10) | 6/8 (8) | 1/2 (0) | 0 |
| 32 | 28-30 | 3 | 81 | 36 | 17 (5) | 6 (0) | 34 (16) | 30 (9) | 4/5 | 8/8 | 5 | 10/10 (9) | 6/7 (3) | 0/4 (2) | 0 |
| 33 | 24-15 | 0 | 58 | 33 | 13 (5) | 2 (1) | 15 (9) | 30 (5) | 1/1 | 4/4 | 1 | 6/11 (6) | 5/4 (2) | 5/1 (4) | 0 |
| 34 | 22-31 | 0 | 67 | 39 | 14 (3) | 9 (1) | 31 (15) | 22 (8) | 2/6 | 3/0 | 3 | 7/12 (10) | 1/5 (2) | 6/1 (3) | 0 |
| 35 | 25-24 | 0 | 60 | 40 | 11 (3) | 3 (1) | 29 (16) | 20 (5) | 4/2 | 3/4 | 3 | 6/10 (3) | 3/4 (3) | 3/4 (5) | 0 |
| 36 | 20-16 | 0 | 59 | 31 | 12 (2) | 4 (0) | 23 (6) | 25 (10) | 2/2 | 7/4 | 5 | 11/11 (8) | 5/4 (4) | 1/3 (3) | 0 |
| 37 | 26-20 | 0 | 54 | 41 | 14 (5) | 3 (2) | 20 (9) | 20 (8) | 5/4 | 3/6 | 6 | 11/15 (11) | 4/3 (4) | 6/3 (3) | 0 |
| 38 | 21-19 | 0 | 56 | 34 | 11 (4) | 6 (2) | 19 (8) | 26 (8) | 1/4 | 6/3 | 3 | 8/7 (5) | 3/4 (1) | 2/1 (2) | 0 |
| 39 | 20-24 | 0 | 63 | 33 | 19 (6) | 4 (2) | 28 (12) | 17 (3) | 2/6 | 3/2 | 1 | 13/5 (7) | 4/4 (4) | 3/3 (5) | 0 |
| 40 | 20-23 | 0 | 71 | 30 | 15 (6) | 6 (1) | 29 (6) | 27 (10) | 7/6 | 3/2 | 1 | 14/10 (11) | 2/6 (5) | 1/5 (1) | 0 |
| 41 | 24-33 | 0 | 59 | 47 | 13 (6) | 3 (1) | 21 (12) | 25 (10) | 4/3 | 4/6 | 5 | 8/4 (7) | 6/2 (5) | 4/2 (2) | 0 |
| 42 | 30-23 | 0 | 53 | 49 | 17 (12) | 3 (1) | 14 (7) | 22 (10) | 3/6 | 9/5 | 8 | 9/11 (4) | 3/4 (5) | 1/0 (1) | 0 |
