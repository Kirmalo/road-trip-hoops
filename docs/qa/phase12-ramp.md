# P12-26 Phase 12 QA: the ramp with a New Generation legend and the new perks

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `16c3c40`. This build has the owner's tuning: FAST BREAK `speed_mult`
1.08 and `break_mult` 1.20, Chapter 4 `challenge_avg` 74, `RIM_RUN_SPEED_MULT` 1.06, and the six New Generation perks at
the Q5 a sizes. Godot 4.3 stable (Linux), headless, `--fixed-fps 60 --no-countdown`, and every game played to its
target.

Setup:
- Two copies of the project outside the repo, each with its own `config/name`.
- Every game ran in its own fresh `XDG_DATA_HOME`, with no trip save and no Legends file.
- At most 2 Godot processes ran at a time. Another QA task shared the machine, at load about 4.

**Report only.** No file in `scripts/` changed. The perk sizes below are proposals for the owner. These scratch-only
changes were made in copy B, never in the repo:

- `trip.gd` `legend_available()`: env vars limit the `--best-roster` sim to one chapter's legends
  (`HOOPS_SIM_CHAPTER=next`) or to one legend (`HOOPS_SIM_LEGEND=lg_long_shadow`). The sim never drafts a New
  Generation legend by itself (see below).
- `player.gd`: an env var (`HOOPS_PERK_VALUE`) sets the perk's value, to measure `closeout` and `pump_fake` at 1.20.
  When the env vars are unset, copy B plays exactly as the repo does.
- At the end, the proposed sizes went into copy B's `legends_data.gd`. `--legendtest` printed LEGENDTEST OK, so every
  proposal is inside `_check_perks()`'s limits.

**Import:** clean, with no errors.

**Games:** 754 in all:
- 522 bound games;
- 190 Quick Game perk games at today's sizes;
- 40 scratch perk games at 1.20;
- 2 `--humantest`.

Every game reached `FINAL` with exit 0. There were no `SCRIPT ERROR` or `ERROR` lines and 0 shot-clock violations.
Every game had exactly one side switch. The longest game ran 52,950 frames (`--quit-after` 200,000).

**No screenshots:** this is a headless balance task and nothing visual changed.

## Headline

- **The Hard bound holds.** The bound is the strongest legal three with a New Generation legend plus the two strongest
  new perks: Glitch + la_boss + one more, with `--perk fresh_legs,-,head_start`. Against it, RED wins **41% on Hard**
  (65/160, SE 4) across Seattle 3, Los Angeles 3 and the three New York rounds. Phase 11 measured 44%.
  - The New York semifinal on Hard: **42%** (25/60, SE 6).
  - The final: 40% (16/40, SE 8).
  - Every Hard cell is at 30% or more.
- **The legend changes nothing measurable.**
  - Glitch with no perk: 38% over the five games (61/160, SE 4), and 41% over SF + final (100 games).
  - The sim's own pick, Eyes Closed, with no perk: 40% over SF + final (24/60, SE 6).
  - Long Shadow forced (the rim run, P12-23's strongest move): 42% over SF + final (26/62, SE 6). His SF alone is 33%
    (14/42, SE 7).
- **The perks change nothing measurable either.** Glitch's crew is 38% with no perk and 41% with the two perks: the same
  within noise (SE 4 each). No cell falls below 20%.
- **Perks at the Q5 a sizes** (yardstick: "2 stat points" = +6 on one stat, about **0.05 points per game per player** in
  this build, the same as P9-30 to P11-26):

  | Perk | Worth vs 2 stat points | Changes a play, one pupil |
  |---|---|---|
  | `fresh_legs` | **1.3-1.8x** | every sprint (7.5% of his frames) |
  | `head_start` | about 1.2x | every gain of the ball (28% of his frames) |
  | `early_shot` | 0.8x | 3.3 shots a game get +1%, about 1 make in 30 games |
  | `closeout` | **0.65x** | one block about every 15 games |
  | `pump_fake` | **0.35x** (CPU pupil) | one bite about every 15-25 games (CPU); a human who fakes a lot gets about 0.5 a game |
  | `second_chance` | **0.2x** | 0.44 putbacks a game get +2.5%, about 1 make in 90 games |

  Earlier QA said `closeout` and `pump_fake` barely fire. That is confirmed, and so is `second_chance`. Proposed:
  `fresh_legs` 0.93, `closeout` 1.15, `pump_fake` 1.20 (the limit), `second_chance` 0.06 (the limit), and keep
  `head_start` and `early_shot`. `pump_fake` and `second_chance` stay under 1x even at the limits. They need a design
  answer (a bigger scope), not a bigger size.

## Setup

- **Bound:** `--autoplay --city <id> --cgame N --best-roster --difficulty <level> [--perk ...]` (LEGEND:
  `--difficulty legend --stars 72`), on the cities Phase 11 measured: Seattle 3, Los Angeles 3 and the New York QF, SF
  and final.
  - **New Generation legend** (`bN_*`, copy B, `HOOPS_SIM_CHAPTER=next`): the sim drafts the best New Generation legend
    for the crew. That is Glitch in every game.
  - The perks: `fresh_legs` (Overclock's) and `head_start` (Long Shadow's) are the two strongest new perks (below).
    They come from two different mentors, and Glitch (the legend) gets none.
    - In New York la_boss is player 0 and Glitch player 1, so the string is `fresh_legs,-,head_start`.
    - In Seattle and Los Angeles Glitch is player 0, so it is `-,fresh_legs,head_start`.
    - The PERK lines confirmed each pupil.
  - The same crew **with no perk**, to tell the legend apart from the perks.
  - **Eyes Closed** (`bE_*`, the repo copy, the sim's own pick) with no perk: SF and final.
  - **Long Shadow forced** (`bL_*`): SF and final with no perk, and SF with the two perks.
  - **The all-time strongest pair** (`bN_qp`): Glitch's crew with `quick_pass,-,fresh_legs`, SF only.
    `quick_pass` is P9-30's 2x perk.
  - Cell sizes: Hard SF 60, final 40, and the other three 20 each. Normal and LEGEND: 4 per game, 20 per level, with
    the perks.
- **Perks:** Quick Game on Hard (Kings vs the Bridge Runners), `--perk <id>` on all 3 BLUE players.
  - 40 games with no perk and 25 per perk.
  - Scratch: `closeout` and `pump_fake` at 1.20, 20 games each.
- **Humantest:**
  - `--humantest --city new_york --cgame 2 --best-roster --perk fresh_legs,-,head_start`, Glitch forced.
  - `--humantest --difficulty normal --perk pump_fake`.

## The starting crews (RAMP lines)

| Game | BLUE best (legend + boss + 1) | BLUE avg | RED avg Hard |
|---|---|---|---|
| Seattle 3 | **lg_glitch 95/93/83/83/78**, den_boss, den_g1 | 80.8 | 80.5 |
| Los Angeles 3 | **lg_glitch 95/95/88/88/83**, sea_boss, sea_g1 | 85.1 | 85.5 |
| New York QF | la_boss, **lg_glitch 95/95/93/93/88**, la_g1 | 89.2 | 80.9 |
| New York SF / final | la_boss, **lg_glitch**, ny_q1 | 90.9 | 83.9 / 89.5 |
| SF / final, sim's own pick | lg_eyes_closed 95/95/93/93/95, la_boss, ny_q1 | 91.3 | 83.9 / 89.5 |
| SF / final, Long Shadow forced | la_boss, **lg_long_shadow 95/88/95/95/78**, ny_q1 | 90.0 | 83.9 / 89.5 |

- **The sim never drafts a New Generation legend by itself.** At the New York cap the best of them is Glitch
  (95/95/93/93/88, sum 464). Eyes Closed (sum 471) still wins, as in Phase 11.
- The New Generation shapes carry -10 to -20 on stamina, and each loses 5-10 rating points to the 95 cap. So in a
  real trip a New Generation legend is a little weaker on paper than the best Father. Swapping one in costs the crew
  0.4 of average (Glitch) or 1.3 (Long Shadow).

## RED win share against the best crew with a legend (games, SE)

| Game | Glitch + 2 new perks, Hard | Glitch, no perk, Hard | Normal (perks) | LEGEND (perks) |
|---|---|---|---|---|
| Seattle 3 | 9/20 = 45% (11) | 5/20 = 25% (10) | 1/4 | 3/4 |
| Los Angeles 3 | 6/20 = 30% (10) | 9/20 = 45% (11) | 2/4 | 1/4 |
| New York QF | 9/20 = 45% (11) | 6/20 = 30% (10) | 1/4 | 1/4 |
| **New York SF** | **25/60 = 42% (6)** | 21/60 = 35% (6) | 1/4 | 2/4 |
| New York final | 16/40 = 40% (8) | 20/40 = 50% (8) | 2/4 | 2/4 |
| Late 2 pooled | 15/40 = 38% (8) | 14/40 = 35% (8) | 3/8 | 4/8 |
| New York 3 pooled | 50/120 = 42% (5) | 47/120 = 39% (4) | 4/12 | 5/12 |
| **All 5 pooled** | **65/160 = 41% (4)** | **61/160 = 38% (4)** | **7/20 = 35% (11)** | **9/20 = 45% (11)** |

The other legends and pairs, all on Hard:

| Crew | SF | Final | SF + final |
|---|---|---|---|
| Eyes Closed (sim's pick), no perk | 17/40 = 42% (8) | 7/20 = 35% (11) | 24/60 = 40% (6) |
| Glitch, no perk | 21/60 = 35% (6) | 20/40 = 50% (8) | 41/100 = 41% (5) |
| Glitch + fresh_legs + head_start | 25/60 = 42% (6) | 16/40 = 40% (8) | 41/100 = 41% (5) |
| Glitch + quick_pass + fresh_legs | 9/20 = 45% (11) | | |
| Long Shadow, no perk | 14/42 = 33% (7) | 12/20 = 60% (11) | 26/62 = 42% (6) |
| Long Shadow + fresh_legs + head_start | 8/20 = 40% (11) | | |

Phase 11 (P11-26), the same setup with a Present-era bound (Eyes Closed + `quick_pass` + `contest` at 0.015): Easy 35%,
Normal 30%, Hard 44%, LEGEND 60% (20 / 20 / 180 / 20 games).

- **Hard: 41% against Phase 11's 44%,** a difference of 0.6 SE. Phase 12 adds no stronger draft, and no perk strong
  enough to move the bound.
- The New York SF is again the low cell of New York: 42% with perks and 35% without (pooled 38%, 120 games). The
  first 18 Long Shadow SF games read 22%; with 42 games it is 33%. No Hard cell with 40+ games is under 33%.
- Normal 35% and LEGEND 45% match Phase 11 (30%, 60%) within their SE of 11. As in Phase 11, 20 games can't separate
  Hard from LEGEND. Easy was not run: it has no band against the best crew, and the time went to the Hard cells.
- **Legend effect** (no perk, SF + final): Eyes Closed 40%, Glitch 41%, Long Shadow 42%. On 60-100 games a New
  Generation legend is worth the same as the best Father. Long Shadow's rim run fired about 34 times a game
  (`sig_rim_run_t0`), but his lower stamina and shooting offset it.
- **Perk effect** (Glitch): with no perk 38%, with the two perks 41%. On 160 games each, that is no measurable gain
  (it even reads the wrong way, at 0.5 SE). This matches the worths below: two perks at about 1.2-1.8x of "2 stat
  points" each are about 0.1 points a game, far under what 160 games can show.
- Average final margin (BLUE - RED), Hard: Glitch with perks +1.2, Glitch with no perk +1.4, Eyes Closed +1.2, Long
  Shadow +1.5.

## Perks: measured effect and "2 stat points"

The perk is on all 3 BLUE players (Quick Game, Hard; 25 games per perk, 40 with no perk). "Events" are the perk's own
counter, `perk_<id>_t0`, plus P12-22's extra counters:

- `fresh_legs`: each new sprint; `_frames_` counts the sprint frames it sized.
- `head_start`: each ball gain; `_frames_` counts the frames he ran at x1.04.
- `pump_fake`: bites only the perk caused (the roll landed between the old and the new chance); `_tries_` counts every
  bite roll it sized.
- `second_chance`: his putback shots that got the bonus.
- `early_shot`: his shots within `BREAK_WINDOW` 5 s of a gain that got the bonus.
- `closeout`: jumper blocks only the perk made; `_tries_` counts every jumper block try it sized.

**Yardstick** (the no-perk games, per BLUE player per game):

| Stat +6 | Change per chance | Points per player per game |
|---|---|---|
| shooting | x1.018 on 5.6 jumpers at 39-43%, 1.15-1.3 points a make | +0.045-0.055 |
| finishing | x1.0144 on 5.2 rim shots at about 62% | +0.046 |
| speed | x1.0096 on every frame | (the speed perk's measure, below) |
| stamina | drain x0.97 and refill x1.03 | sprint share 38.5% -> 39.9% at full use (+3.7%) |

So the yardstick is **about 0.05 points per game per player**, as in P9-30, P10-26 and P11-26. Points per make: BLUE
1.16-1.24 (any shot), RED 1.11-1.16. A point is 1 inside the arc and 2 beyond.

`fresh_legs` and `head_start` are slices of a stat (stamina drain, speed). They are measured against +6 on that stat,
because a win share can't show 0.05 points a game.

| Perk (value) | Games | Fired in | Events / game, team (SE) | Measure | Per player | x "2 stat points" |
|---|---|---|---|---|---|---|
| fresh_legs (x0.90) | 25 | 25 | 351 sprints; 7.5% of his frames | BLUE sprint share +4.8% (0.2709 vs 0.2581 of frames, SE 0.0035 each); the model: +6.5% | +6 stamina = +3.7% | **1.3x** (measured), 1.76x (model) |
| head_start (x1.04) | 25 | 25 | 100 gains; 27.9% of his frames | 4% x 0.279 = +1.12% average speed | +6 speed = +0.96% | **1.17x** |
| early_shot (+0.010) | 25 | 25 | 9.88 (0.77) | 9.88 x 0.010 x 1.2 = 0.119 | 0.040 | **0.8x** |
| second_chance (+0.025) | 25 | 18 | 1.32 (0.24) | 1.32 x 0.025 x 1.0 = 0.033 | 0.011 | **0.22x** |
| closeout (x1.10) | 25 | 4 | 0.20 (0.10); tries 2.4; expected 2.4 x 0.075 = 0.18 | 0.18 x 0.55 = 0.10 | 0.033 | **0.65x** |
| closeout (x1.20, scratch) | 20 | 5 | 0.30 (0.13); tries 2.1 | 0.34 x 0.55 = 0.19 | 0.062 | 1.25x |
| pump_fake (x1.15) | 25 | 3 | 0.12 (0.07); tries 6.6 | pooled 0.21 x 0.25 = 0.053 | 0.018 | **0.35x** |
| pump_fake (x1.20, scratch) | 20 | 7 | 0.40 (0.13); tries 5.7 | 0.28 x 0.25 = 0.07 | 0.024 | 0.47x |

Notes:

- **fresh_legs:**
  - The CPU never runs his tank dry (`stamina_empty` 0 in every game): it keeps a reserve and stops at
    `TURBO_MIN_RESTART`. So the perk shows up as more sprint time.
  - BLUE sprinted +4.8% more of the game, about 2.6 SE. A rate model of sprint and refill says +6.5% at full use.
    +6 stamina says +3.7% by the same model, so the perk is 1.3-1.8x.
  - It fires on every sprint. At 0.93 the model gives +4.6% (1.2x) and the measured scale about 0.95x, so about 1x.
- **head_start:**
  - The window (5 s after every gain: rebounds, steals and inbounds) covers 28% of a player's frames.
  - +4% there is +1.12% on average, the same as +7 speed, so 1.17x. That is inside the method's error, so keep it.
  - Speed in transition may be worth a little more than half-court speed. The bound shows no sign of it (above).
- **early_shot** at 0.8x is inside the 0.5-1.5x band. 0.012 would make it about 0.95x, but that is optional.
- **second_chance:**
  - Only 1.32 shots a game (three holders) are his own putbacks inside 14 ft within 3 s of an offensive rebound. A
    single pupil gets 0.44, and a 2.5% bonus turns about one make in 90 games.
  - At the `_bonus` limit 0.06 it is about 0.5x. To reach 1x the hook needs a wider scope, which is a lead and owner
    question. Two options: any BLUE shot within `PUTBACK_SECS` after **his** offensive rebound (a kick-out to a
    teammate too), or the bonus on his tip-ins plus his rebound reach.
- **closeout:**
  - It sizes only good-timed and bad-timed block tries at jumpers, about 0.8 a game for one pupil, at about +0.075
    chance each. That gives one block every 15 games.
  - The value of a block on a jumper is about 0.55 points: a contested jumper scores about 48% x 1.2 points, minus the
    third of blocks the offense keeps, against the 25% of misses it rebounds.
  - 1.15 gives about 1.0x. 1.20 (the limit) gives 1.25x.
- **pump_fake:**
  - The CPU fakes about 1.7 times a game per player (`CPU_PUMP_CHANCE` 0.04 per decision, only with a man close in
    front, inside 24 ft).
  - The perk sizes about 2.2 bite rolls a game for one CPU pupil. At x1.15, 3 perk bites in 25 games; at x1.20, 8 in
    20 games. Pooled, that is 1.42 bites a game per unit of (mult - 1) for three holders.
  - A bite is worth about 0.25 points: an open look or a drive past a man in the air, plus the foul chance.
    `pump_and_score` is 67% of `pump_then_shots`, against 53% overall.
  - For a CPU pupil it is 0.35x now and 0.47x at the 1.20 limit.
  - **For the human it is far more.** The two humantests faked 13 and 19 times, and the pump_fake one sized 10 bite
    rolls. That is about 0.5 extra bites a game expected, or about 2.5x. The perk mostly matters when YOU hold it.
    0 perk bites came in that one game, which is within chance.
- **Win shares** in the perk games move within noise.
  - The no-perk set's BLUE won only 25% (10/40, SE 7), with a margin of -2.4. That is the Kings against the Bridge
    Runners on Hard; Phase 11's set had 30%.
  - Every perk set had a margin from -0.8 to +1.5 (SE 1.1-1.6). The perks that hardly fire (`closeout` -0.1,
    `pump_fake` +0.1) moved as much as the others, so this is the baseline's luck, not a perk effect.

## Proposed perk sizes (owner decides; `scripts/legends_data.gd` `PERKS`, the New Generation only)

| Perk (mentor) | Key | Now (Q5 a) | Proposed | Worth now -> proposed | Text if changed |
|---|---|---|---|---|---|
| fresh_legs (Overclock) | `sprint_drain_mult` | 0.90 | **0.93** | 1.3-1.8x -> 0.95-1.2x | Sprinting tires him 7% less |
| head_start (Long Shadow) | `break_speed_mult` | 1.04 | keep | 1.17x | |
| pump_fake (Glitch) | `fake_bite_mult` | 1.15 | **1.20** (the limit) | 0.35x -> 0.47x (CPU pupil); about 2.5x -> 3.3x for YOU | His pump fakes get the defender up 20% more often |
| second_chance (Updraft) | `putback_bonus` | 0.025 | **0.06** (the limit) | 0.22x -> 0.5x | Putbacks after an offensive rebound +6% |
| early_shot (Halfcourt) | `early_shot_bonus` | 0.010 | keep (0.012 optional) | 0.8x (-> 0.95x) | Shots soon after getting the ball +1.2% |
| closeout (Firewall) | `jumper_block_mult` | 1.10 | **1.15** | 0.65x -> 1.0x | His blocks on jump shots work 15% more often |

- All the proposed values are inside `_check_perks()`'s limits (`_bonus` in (0, 0.06], `_mult` within 0.2 of 1.0, the
  limits included). A scratch copy with them passed `--legendtest` (LEGENDTEST OK).
- If the owner takes them, `docs/VISION.md` (Q5 a) and the BOARD contract line for the six perks need the new sizes.
  The texts are about as long as today's (P12-B1's Hall fit, `_fit_font()`, min 14, handles them).
- **pump_fake and second_chance stay under 1x at the limits.** Making them worth 2 stat points needs a design answer
  for the lead and the owner, not a size:
  - `pump_fake`: the CPU's own fake rate (`CPU_PUMP_CHANCE`) caps it, a sim change outside the perk. Or accept a perk
    that is weak on a CPU pupil and about 2-3x on YOU.
  - `second_chance`: a wider hook (above).
  - The same happened with `side_step` in Phase 11.
- **The bound needs no rerun after the change.** It was measured with `fresh_legs` at 0.90, which is stronger than
  proposed. The stronger proposals (`closeout` 1.15, `pump_fake` 1.20, `second_chance` 0.06) all stay at or under
  about 1x, under `fresh_legs` and `quick_pass`. The Glitch + `quick_pass` + `fresh_legs` SF cell read 45% (20 games).

## Checks

| Check | Result | |
|---|---|---|
| Hard: RED wins 20%+ against legend + boss + best perks (late boss games and New York) | 41% pooled (160); cells 45 / 30 / 45 / 42 / 40% | **pass** |
| Hard bound against Phase 11's 44% | 41% (SE 4): the same | pass |
| New York SF on Hard, 60+ games | 42% with perks (60), 35% without (60) | pass |
| A New Generation legend in the bound | the sim prefers Eyes Closed; forced Glitch 41%, Long Shadow 42% (SF + final) | pass |
| Legend effect and perk effect told apart | legend: Glitch 41 = Eyes Closed 40 (no perk); perks: 41 vs 38 (no gain measurable) | pass |
| New York on Hard can still be lost (owner L7 a) | QF 45%, SF 42%, final 40% | pass |
| Normal < Hard < LEGEND | 35 / 41 / 45% (20 / 160 / 20 games) | not resolved at 20 games (as in Phase 11) |
| Each New Generation perk about 2 stat points | fresh_legs 1.3-1.8x; head_start 1.2x; early_shot 0.8x; closeout 0.65x; pump_fake 0.35x; second_chance 0.22x | **fail as sized** for 4; the proposals bring fresh_legs and closeout to about 1x; pump_fake and second_chance stay under 1x at the limits |
| Every New Generation perk fires | all 6; closeout in 4 of 25 games, pump_fake in 3 of 25 (three holders) | pass (closeout and pump_fake rare, as P12-22 said) |
| Script errors, unfinished games, shot-clock violations | 0, 0, 0 | pass |
| `--humantest` x2 | both FINAL, exit 0 | pass |
| Screenshots | not taken (headless, no visual change) | n/a |

## Game stats (mean, range)

| | Bound (522) | Quick Game perk games (230) | Target (CLAUDE.md) | |
|---|---|---|---|---|
| Game length | 8.6 min (5.1-12.8) | 9.7 (6.0-14.7) | 7-11 | pass |
| Shots per game | 59.3 (34-88) | 60.6 (37-91) | 55-90 | pass |
| Field goal % | 53.2% | 53.7% | about 50% | pass |
| Loser's points | 16.2 (6-20) | 16.2 (5-20) | usually 12-20 | pass |
| Fouls per game | 1.9 (0-8) | 2.1 (0-6) | 1-5 | pass |
| Out of bounds per game | 0.8 (0-5) | 1.1 (0-6) | 1-2 | pass (a little low in the bound games, as in Phases 9-11) |
| Interceptions per game | 2.2 (0-7) | 3.2 (0-12) | few | pass (the 12 was a no-perk Quick Game, an outlier) |
| Offensive rebounds, % of misses | 26.1% | 25.7% | about 25% | pass |
| Shot-clock violations | 0 | 0 | few | pass |
| Side switches | 1 in every game | 1 | 1 | pass |

Humantest (both played Normal; `--humantest` reads its level that way):

- `--humantest --city new_york --cgame 2 --best-roster --perk fresh_legs,-,head_start`, Glitch forced: FINAL 21-10,
  5:44.
  - Steals timed 10/10, blocks timed 1/1, countdown presses ignored 3/3.
  - Both PERK lines printed (the fresh_legs drain x0.90, head_start x1.04 off the ball).
  - fresh_legs fired on 50 sprints and head_start on 30 gains.
- `--humantest --difficulty normal --perk pump_fake`: FINAL 21-12, 8:03.
  - 19 human pump fakes and 10 bite rolls sized; the perk caused no bite this game.
  - Steals timed 12/13, blocks timed 2/6.
- No errors in either.

## Bugs

None. No P12-Bn added.

- The `pump_fake` tries counter at x1.15 predicted about 0.36 perk bites a game (6.6 tries x about +0.055). 0.12 came
  (3 in 25 games, which is unlikely but possible). At x1.20 the prediction (0.43) and the count (0.40) agree. I read
  this as chance, not a counting fault.

## Suggested tuning and watch items (for the lead)

- **Perk sizes:** the table above. Nothing was applied.
  - `fresh_legs` 0.93 and `closeout` 1.15 bring two perks to about 1x.
  - `pump_fake` 1.20 and `second_chance` 0.06 are the limits and still under 1x. They need a scope answer (above).
  - `early_shot` 0.012 is optional.
- **The Hard ramp:** no `cities.gd` or `LEGEND_BONUS` change needed. 41% against the New Generation bound, 40-42% with
  any legend in New York.
- **Long Shadow** as a drafted legend: SF 33% (42 games), the lowest cell with 40+ games. Worth watching if
  `RIM_RUN_SPEED_MULT` ever goes back up.

## How to rerun

```
# a bound cell; a New Generation legend needs the scratch env in trip.gd legend_available() (the sim prefers Eyes Closed)
HOOPS_SIM_CHAPTER=next godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --no-countdown \
    --city new_york --cgame 2 --best-roster --perk fresh_legs,-,head_start --difficulty hard
# a perk's effect (Quick Game, all 3 BLUE players); the stats dict has perk_<id>_t0 and _tries_ / _frames_
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --no-countdown --difficulty hard \
    --perk closeout
```

Win share is RED's share of the `FINAL` lines; the `RAMP` lines show both crews. Each game ran in a fresh
`XDG_DATA_HOME`, with one output file per game. Two workers pulled single games from a shared queue under `flock`.
