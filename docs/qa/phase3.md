# P3-12 Phase 3 QA and balance pass

Build tested: `trial-p309` at e83f419 (dev + P3-09 CPU retune + main.gd cleanup), on branch `qa-p3-12`.
Godot 4.3 stable, headless, `--fixed-fps 60 --quit-after 120000`. Import is clean, with no script errors in any run.

Runs: 216 `--autoplay` on Hard, plus 40 each on `--difficulty=normal` and `=easy`; 4 `--humantest` (3 Hard, 1 Easy).
After tuning: 100 Hard, 40+48 Normal, 40+48 Easy. Edge cases: 56 games with temporary hooks, in a separate copy
that isn't committed. Web build: 2 Playwright sessions. Every game reached FINAL, and every process exited 0.

## 1. Hard, 216 autoplay games (build as given)

| Stat | Mean (range) | Target | Result |
|---|---|---|---|
| Final score | winner 21.1 (21-22), loser 16.2 (4-20); 200/216 losers 12-20 | 21-x | PASS |
| Side switches | exactly 1 in 216/216, at 11 (186) or 12 (30, a 2 from 10) | one, at 11 | PASS |
| Game length (`GAME LENGTH`) | 11.5 min (6.8-16.8); 20% under 10, 4% over 15 | ~10-15 | PASS |
| Dead-ball seconds | 37 (23-52) | - | info |
| Shots | 90.8 (56-139) | 75-120 | PASS |
| FG% | 35.3% | - | info |
| 2s share of points | 22.6% (0-49%); 4.2 made from 16.1 tries (29%) | 20-30% | PASS |
| Fouls | 3.8 (0-11); 65% of games 3-6, 27% under 3, 8% over 6 | ~3-6 | PASS |
| Fouls by team | BLUE 1.9 / RED 1.9 | even | PASS |
| Fouls by type | shooting 2.3 / reach 1.4; and-ones 1.0 (44% of shooting fouls) | - | info (see owner question) |
| Free throws | 2.3 tries/game, 73.9% (BLUE 76%, RED 72%); 0 FT timeouts | 65-80% | PASS |
| Out of bounds | 2.4 (0-10); 74% baseline; 92% after a rebound, 8% after a block | ~2-3 | PASS |
| Rim long / wide bounces | 3.9 / 2.8 per game | - | info |
| Blocks per 60 shots | 6.8 (P2 final 6.7) | 4-7 | PASS |
| Steals per 60 shots | 6.8 (P2 final 8.7) | 5-10 | PASS (a little lower than P2) |
| Crossover beats | 38.5% (BLUE 38%, RED 38%) | 25-45% | PASS |
| Fake bites (bites / pump fakes) | 40.0% | 30-50% | PASS |
| Lobs (`alleyoops_t0+t1`) | **4.48/game** (2.9 per 60 shots); alley-oop makes 1.9 | 1-4 per game | FAIL (per game), tuned |
| Interceptions | 3.8 (0-9) = 2.5 per 60 shots (P2 2.9) | few | PASS |
| Shot-clock violations | 0 in 216 | 0 | PASS |
| Lead changes | 1.8 (0-8) | - | info |

### Balance (Hard vs Hard; first ball random)
BLUE wins 114/216 = **52.8%** (standard error +-3.4%). The point diff (BLUE - RED) is +0.44 +-0.39. Points
are 18.9 / 18.5, right hoop 18.6 vs left hoop 18.7. BLUE wins per 40-game block: 19, 20, 25, 17, 24. Per team per
game: steals 5.1/5.1, blocks 5.0/5.2, lobs 2.1/2.4, crossovers 13.5/13.8, 2s made 2.1/2.1, FT tries 1.1/1.2. **No
team bias** (within 1 SE). With the tuned build, 100 more games give 50/50.

## 2. Difficulty (RED plays the level, BLUE plays Hard)

| Level | Games | RED win share | Point diff B-R | RED steals / blocks per game | BLUE's crossovers beat RED | RED bites on fakes | Minutes |
|---|---|---|---|---|---|---|---|
| Hard | 216 | 47.2% | +0.4 | 5.1 / 5.2 | 38% | 42% | 11.5 |
| Normal (as given) | 40 | 37.5% | +2.3 | 3.4 / 3.7 | 53% | 41% | 10.9 |
| Easy (as given) | 40 | 20.0% | +4.5 | 2.0 / 3.0 | 80% | 39% | 10.5 |
| Normal (tuned, bite x1.4) | 48 | 27.1% | +3.4 | 3.1 / 3.8 | 56% | 54% | 10.9 |
| Easy (tuned, bite x1.8) | 48 | 22.9% | +3.7 | 2.3 / 3.1 | 72% | 59% | 11.0 |

- RED win share goes Hard > Normal > Easy on both builds: PASS. The 40-48 game batches have a +-7% standard
  error, so Normal and Easy overlap a little. Pooled over every Easy game (88): 18%.
- RED uses every move on Easy: crossovers, fakes, lobs, alley-oops, steals, blocks, 2s, pull-ups, kick-outs, fouls,
  dunks and layups are all above 0 per game. Steals are the thinnest: 0 in 7-9 of 40-48 Easy games. PASS.
- **Found:** on the build as given, Easy and Normal did not bite on fakes more than Hard (39% / 41% vs 42%), which
  goes against owner Q6 ("more bites on fakes"). Cause: a pump fake lasts `PUMP_TIME` 0.3 s, and the CPU only rolls
  the bite once its jump reaction (`jump_react`, Hard 0.12-0.30 s) has run out. Easy adds 0.06 s, so about a third of
  its reactions finish after the fake is over and never roll. That cancels the x1.5. Fixed by constants (below).

## 3. Humantest (scripted touch inputs)

| Run | Final | Length | Fouls (human) | FTs | OOB | Steals timed / random | Blocks timed / early |
|---|---|---|---|---|---|---|---|
| Hard 1 | 15-21 | 9:34 | 4 reach (1 by, 1 on) | 0 | 4 | 13/17, 6/35 | 3/9, 1/9 |
| Hard 2 | 21-17 | 8:33 | 0 | 0 | 3 | 12/13, 8/27 | 4/5, 3/8 |
| Hard 3 | 19-21 | 9:28 | 3 (1 by, 2 on) | human 0/2 (1 perfect, 1 early) | 2 | 15/18, 7/34 | 5/7, 2/7 |
| Easy (tuned build) | 15-21 | 9:15 | 2 reach | 0 | - | 9/14, 13/35 | 6/9, 1/8 |

One switch every run, 0 shot-clock violations, no errors. The human free-throw path ran (meter, perfect and early
releases); only 2 human FTs in 4 runs, so the made-vs-early gap couldn't be judged here (P3-05 covered it).

## 4. Edge cases (temporary hooks in a scratch copy: log lines, forced out-of-bounds, forced FT misses)

| Case | How | Result |
|---|---|---|
| Side switch triggered by an and-one | `--target 5 --force-fouls`: an and-one dunk brought BLUE/RED to 3 (switch at 3) | PASS. The switch waits for the FT. Make: dead ball, then SWITCH SIDES, then the other team inbounds. Miss: live rebound, and the switch comes at the next dead ball (documented behavior, owner question open). |
| Side switch triggered by a free throw | same, 10 games: the first of 2 FTs reached the switch score | PASS. The second FT is shot at the old hoop; the switch follows at the next dead ball |
| Game point / win on a free throw | 5 of 30 short games ended on a FT; also in the web build (RED 3-0 to 3 with a FT lineup on screen) | PASS. FINAL at exactly the target, game-over panel shows |
| Foul during the free-throw lineup | hook called `call_foul` (shooting and reach) in every FT phase (walk, setup, shoot, air) | PASS. All ignored (`call_foul` returns false), the FT went on normally |
| Out of bounds right after the switch | hook pushed the ball over a sideline 0.4 s after the first post-switch inbound (4 games) | PASS. Whistle, sideline inbound at the spot, shot clock kept (23.6) |
| Shot clock after out of bounds | 51 logged OOBs | PASS. Change of possession (or after a rim hit): 24. Same team keeps it (block/steal knocked out): kept, at least 5 s |
| OOB while the switch is pending (missed last FT, then out) | hook: forced FT miss plus a forced out | **BUG B1**, below |

## 5. Web build (`tools/build_web.sh`, Chromium 1280x720, hasTouch + isMobile, CDP `Input.dispatchTouchEvent`)

- Fresh profile: the start panel shows with **NORMAL lit**. A tap on EASY starts the game. PASS.
- About 60 s of touch play (floating stick in 6 directions, A held 0.12 / 0.45 s, B taps). The top bar shows
  "FIRST TO 21", "BLUE >> 0 - 0 RED" with the attack arrow, and the shot clock. Buttons switch SHOOT/PASS,
  STEAL/SWITCH and CALL as expected. PASS.
- Reload: **EASY stays lit** (remembered). PASS.
- A second copy with `GODOT_CONFIG.args` set to `--target 3 --force-fouls` showed the switch (arrow flips to
  "<< BLUE"), GAME POINT in red at 0-2, a FREE THROW lineup at the right hoop (lane spots clear of the buttons), and
  the game-over panel "FINAL 0 - 3 RED WINS!" with "Tap a level to play again" and EASY lit. PASS.
- Console: no errors, and no page errors. There were only the GL "GPU stall due to ReadPixels" performance warnings
  and one WebGL context-lost warning at load (software GL). Software GL ran at 9-16 fps here, so the game ran slower
  than real time. Feel can't be judged from this environment.

## Bugs

**B1 (minor): a dead-ball spot set before a pending side switch is used after it.** When the switch is waiting
on a live ball (an and-one or FT brought a team to 11, then the last FT missed), the next dead ball can be an out of
bounds or a reaching foul. `_switch_sides()` then resets both teams onto their new halves, but `inbound()` still uses
the old `pending_spot` and `_clock_after_inbound`.
- Steps: a hook forced the last FT to miss with the switch pending, then pushed the ball out over the sideline.
- Expected: the sideline inbound is on the team's side of the court as it is after the switch (spot rotated 180
  degrees with the court), or a normal baseline inbound.
- Actual: the inbounder is teleported to the old spot. In one game RED inbounded from (78, 0) ft, which was its
  backcourt before the switch and is its frontcourt after it (free advance), with the shot clock kept at 23.6. In
  another, RED inbounded deep in its new backcourt. Rare: it needs an and-one/FT to reach 11, then a missed last FT,
  then an OOB or reach foul before any made basket.
- Fix (rules.gd, not a constant): in `_switch_sides()`, rotate a set `pending_spot` with the court
  (`Vector2(COURT_W - x, COURT_H - y)`), or clear it so the inbound uses the baseline. This goes away if the owner
  picks `SWITCH_SKIPS_FT_REBOUND = true`.

No other bugs: no stuck balls, no frozen players after free throws, no inbound from off the court, no games that
didn't end.

## Tuning changes (constants only; committed)

| Constant | File | Old | New | Why | After (re-run) |
|---|---|---|---|---|---|
| `CPU_LOB_CHANCE` | `player.gd` | 0.18 | 0.15 | 4.48 lobs per game, above 1-4 (per 60 shots it is the same as Phase 2; games are just longer) | 100 Hard games: lobs 3.53/game (2.4 per 60 shots), alley-oop makes 1.5; everything else level: shots 89.7, 11.4 min, 2s 22.4% of points, fouls 3.8, FT 70%, OOB 2.3, blocks/steals per 60 shots 7.0/6.9, crossover beat 39.6%, bites 40%, interceptions 3.5, SCV 0, BLUE 50% |
| `LEVELS[NORMAL].fake_bite` | `difficulty.gd` | x1.25 | x1.4 | Q6: Normal must bite more than Hard. It measured 41% vs 42% | 48 games: RED bites 54% of fakes; RED wins 27% |
| `LEVELS[EASY].fake_bite` | `difficulty.gd` | x1.5 | x1.8 | same, Easy measured 39% | 48 games: RED bites 59%; RED wins 23% |

A first try with x1.6 / x2.2 (40 games each) gave 56% / 79% bites. 79% made Easy's defenders jump at almost every
fake, so I backed both off.

## Proposed CLAUDE.md targets (first to 21, 1s and 2s), for the lead to confirm
Games to 21: 75-120 shots, 10-15 min (single games 7-17), loser 12-20, one switch at 11 or 12. 2s are 20-30% of
points. Fouls 2-6 (mean 3-4, split evenly), FTs 65-80%, OOB 2-3. Per 60 shots: blocks 4-8, steals 5-9, lobs 1.5-3,
interceptions under 3. Shot-clock violations 0. Lobs per game: about 2-4.

## Follow-ups
- B1 above (rules.gd).
- The difficulty multipliers on reaction time also cut the chance to *act* on short windows, not just its timing.
  Any future "x more" on a reaction-gated action (fake bites, lob jumps) needs measuring, not just setting.
- Easy RED steals are thin (2.3/game, 0 in about 1 game in 6). Fine for Easy; flag it if the owner wants more
  visible CPU defense on Easy.
- BLUE's crossovers beat Easy RED 72-80% of the time. That is expected for Easy, but the owner should feel it.

## For the owner to judge on the tablet
1. **Game length:** to 21 is about 11.5 min (7-17). Too long for one sitting? (Road Trip plan: 11/15/21.)
2. **Fouls:** about 4 a game, 60% on shots. 44% of shooting fouls are and-ones (open question in VISION). Too
   many, too few, and do the "FOUL ON ... REACHING" calls feel fair when you poke?
3. **Free-throw feel:** the meter at the line, CPU about 72%. Is the lineup pause (about 3-4 s) too slow?
4. **Long rebounds and out of bounds:** about 2.4 OOB per game, almost all hard bounces off the rim going over the
   baseline. Keep, make rarer, or remove (`ball.RIM_LONG_CHANCE`, `RIM_WIDE_CHANCE`)?
5. **Difficulty levels:** is Easy easy enough (CPU wins about 20% against a Hard CPU; it bites on fakes about 60%
   and is beaten by crossovers about 75%)? Is Normal a clear step between them?
6. GAME POINT from 20 (current) or 19, and the side switch after a missed FT (open questions in VISION).
