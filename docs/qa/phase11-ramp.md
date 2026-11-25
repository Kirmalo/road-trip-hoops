# P11-26 Phase 11 QA: the ramp with a Present legend and the new perks

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `5ea5a00` (Phase 11 wave 4 merged: the Present, its perks hooked by
P11-22, P11-23's `finale_stage_avg` 63). Godot 4.3 stable (Linux), headless, `--fixed-fps 60 --no-countdown`, every
game played to its target. Two copies of the project outside the repo (own `config/name`), every game in its own fresh
`XDG_DATA_HOME` (no trip save, no Legends file), at most 2 Godot processes at a time.

**Report only.** No file in `scripts/` changed. The perk sizes below are proposals for the owner. Two scratch-only
changes were made in the copies, never in the repo:

- `trip.gd` `legend_available()`: an env var limits the `--best-roster` sim to one era's legends. It is used for the
  "Present legend" cells (`bp_*`), because the sim never picks a Present legend by itself (see below).
- `legends_data.gd`: `side_step` at 0.5 and `board_work` at 1.2 and 2.0, to measure what those two hooks can be
  worth. The copies were put back to the repo file before the two `--humantest` runs.

**Import:** clean. **Games:** 527: 280 bound games, 60 Legends finale games, 185 Quick Game perk games and 2
`--humantest`. Every one reached `FINAL` with exit 0. There were no `SCRIPT ERROR` or `ERROR` lines and 0 shot-clock
violations. Every game had exactly one side switch. The longest game ran 50,228 frames (`--quit-after` 200,000).
**No screenshots:** this is a headless balance task and nothing visual changed.

## Headline

- **The Hard bound holds, with margin.** The strongest legal three plus the two strongest perks is a drafted legend
  plus one boss plus one more, with `--perk -,quick_pass,contest`. Against it, RED wins **44%** on Hard across the
  late boss games and New York (80/180, SE 4). Every Hard cell is at 39% or more.
- **The New York semifinal on Hard, the Phase 10 watch item, is no longer at the edge.** On 80 games RED wins
  **31/80 = 39% (SE 5)**. P10-26 measured 20% (8/40). With a Present legend (Toolbox) in the crew, RED wins 6/20 =
  30%. That is the lowest cell, and it sits 1 SE above 20%. I read the old 20% as mostly noise from a 40-game cell.
- **The Chapter 3 finale against the best crew on Hard, P11-23's 1-of-10 note:** on 40 games RED wins **16/40 = 40%
  (SE 8)** with no perk, and 10/20 = 50% with the two perks. P11-23's 1/10 was a small sample. The finale passes the
  20% floor easily.
- **The sim never drafts a Present legend.** At the New York cap, `lg_eyes_closed` (95/95/93/93/95, sum 471) beats
  the best Present legend, `lg_toolbox` (95/95/95/95/88, sum 468). In Seattle and Los Angeles it still picks
  `lg_quarterback`. With Toolbox forced, the crew average drops from 91.3 to 91.1. The forced runs (SF 30%, final 45%)
  match the sim's own pick within noise.
- **Perks.** "2 stat points" is worth about **0.05 points per game per player** (the yardstick is the same as P9-30 and
  P10-26; this build gives 0.047-0.064). At the P5 a sizes:

  | Perk | Worth vs 2 stat points |
  |---|---|
  | `contest` | **3x** (the strongest perk of any chapter by this method) |
  | `extra_pass` | 1.6x |
  | `catch_shoot` | 1.4x |
  | `off_dribble` | 0.65x |
  | `board_work` | about 0.4x (rough) |
  | `side_step` | **0.2x**; it fires about once in 14 games for one pupil |

  Proposed: `contest` 0.005, `extra_pass` 0.010, `catch_shoot` 0.010, `off_dribble` 0.025, `board_work` 1.15,
  `side_step` 0.80. Each is about 1x (table below). `side_step` 0.80 is already at the `PERK_MULT_MAX` 0.2 limit.

## Setup

- **Bound:** `--autoplay --city <id> --cgame N --best-roster --perk -,quick_pass,contest --difficulty <level>` (LEGEND:
  `--difficulty legend --stars 72`) for Seattle 3, Los Angeles 3 and the New York QF, SF and final.
  - Player 0 is the drafted legend, who can't be a pupil.
  - The boss gets Quarterback's `quick_pass`, P9-30's strongest perk (about 2x).
  - The third starter gets Switch's `contest`, the strongest Present perk (3x, below). It replaces P10-26's
    `quick_hands` (1-3x, an upper estimate).
  - The two perks come from two different mentors, so the crew is legal.
  - Hard: SF 80 games, final 40, Seattle 3, Los Angeles 3 and the QF 20 each. Those three pool into a 40-game late-boss
    cell and the New York rounds pool into 140.
  - Easy, Normal and LEGEND: 4 games per game, 20 per level. Fewer than P10-26: the owner asked for fewer runs, and the
    shared machine ran at load 4-13 for the first hours.
  - Present legend forced (`bp_*`): New York SF and final on Hard, 20 each.
- **Finale:** `--autoplay --challenge fin:present --best-roster --difficulty hard`: 40 games with no perk (as P11-23)
  and 20 with `--perk -,quick_pass,contest`.
- **Perks:** Quick Game on Hard (Kings vs the Bridge Runners), `--perk <id>` on all 3 BLUE players.
  - 30 games with no perk.
  - At the P5 a sizes: `contest` 25 games; `off_dribble`, `extra_pass`, `catch_shoot`, `board_work` and `side_step` 15
    each.
  - Scratch sizes: `side_step` 0.5 (15 games), `board_work` 1.2 and 2.0 (20 each).

## The starting crews (RAMP lines)

| Game | BLUE best (legend + boss + 1) | BLUE avg | RED avg Hard |
|---|---|---|---|
| Seattle 3 | lg_quarterback 93/93/78/88/88, den_boss, den_g1 | 81.3 | 80.5 |
| Los Angeles 3 | lg_quarterback 95/95/83/93/93, sea_boss, sea_g1 | 85.8 | 85.5 |
| New York QF | lg_eyes_closed 95/95/93/93/95, la_boss, la_g1 | 89.7 | 80.9 |
| New York SF | lg_eyes_closed, la_boss, ny_q1 | 91.3 | 83.9 |
| New York final | lg_eyes_closed, la_boss, ny_q1 | 91.3 | 89.5 |
| SF / final, Present forced | **lg_toolbox 95/95/95/95/88**, la_boss, ny_q1 | 91.1 | 83.9 / 89.5 |
| Chapter 3 finale (Hard) | lg_eyes_closed, la_boss, ny_q1 | 91.3 | Deep End 88/95/73/73/73, Toolbox 88/83/88/83/73, Skylight 83/63/95/88/78 (83.4) |

These are the same crews as P10-26. Phase 11 added no stronger draft.

## RED win share, best crew with legend, boss and 2 perks (games, SE)

| Game | Easy | Normal | Hard | LEGEND |
|---|---|---|---|---|
| Seattle 3 | 1/4 | 2/4 | 12/20 = 60% (11) | 4/4 |
| Los Angeles 3 | 2/4 | 2/4 | 9/20 = 45% (11) | 3/4 |
| New York QF | 1/4 | 0/4 | 10/20 = 50% (11) | 2/4 |
| **New York SF** | 2/4 | 1/4 | **31/80 = 39% (5)** | 1/4 |
| New York final | 1/4 | 1/4 | 18/40 = 45% (8) | 2/4 |
| SF, Toolbox forced | | | 6/20 = 30% (10) | |
| Final, Toolbox forced | | | 9/20 = 45% (11) | |
| Late 2 pooled | 3/8 | 4/8 | **21/40 = 52% (8)** | 7/8 |
| New York 3 pooled | 4/12 | 2/12 | **59/140 = 42% (4)** | 5/12 |
| **All 5 pooled** | **7/20 = 35% (11)** | **6/20 = 30% (10)** | **80/180 = 44% (4)** | **12/20 = 60% (11)** |
| Chapter 3 finale, no perk | | | **16/40 = 40% (8)** | |
| Chapter 3 finale, 2 perks | | | 10/20 = 50% (11) | |

P10-26, the same setup with `quick_hands` in place of `contest`: Easy 7%, Normal 26%, Hard 46%, LEGEND 57% (100 /
100 / 200 / 100 games).

- Hard (44 vs 46) and LEGEND (60 vs 57) match.
- Normal (30 vs 26) matches.
- Easy reads 35% on 20 games against 7% on 100. Seven Easy games ended 21-20 or 20-21. The RAMP and MATCH lines show
  level easy and the right crews. At SE 11, 20 games can't place Easy against Normal. I don't count it as a finding.
  There is no band for Easy against the best crew. If the lead wants it settled, 40 more Easy games would do it.
- Average final margin (BLUE - RED), Hard: SF +2.2, final +1.0, late two -0.1.

## Perks: measured effect and "2 stat points"

The perk is on all 3 BLUE players (Quick Game, Hard). "Events" are the perk's own counter, `perk_<id>_t0`:

- `off_dribble`: jumpers within `PULLUP_WINDOW` of his crossover;
- `extra_pass`: shots by a teammate within 1.5 s of his pass;
- `catch_shoot`: his jumpers within 1.0 s of a catch;
- `contest`: RED shots with the holder within 8 ft;
- `board_work`: rebounds he reached only with the longer reach;
- `side_step`: blocks at his layups that the perk turned away.

Points per made shot, measured: BLUE 1.14 (any shot), BLUE jumpers about 1.35 (41% of BLUE jumpers are threes), RED
1.08. A game point is 1 inside the arc and 2 beyond.

**Yardstick:** 2 stat points is +6 on one stat of one player.

| Stat +6 | Change per chance | Points per player per game |
|---|---|---|
| shooting | x1.018 on 5.3 jumpers at about 50% | +0.064 |
| finishing | x1.0144 on about 4 rim shots at about 80% | +0.047 |

So the yardstick is **about 0.05 points per game per player**, the same as P9-30 and P10-26.

| Perk (value) | Games | Fired in | Events / game, team (SE) | Points / game, team | Per player | x "2 stat points" |
|---|---|---|---|---|---|---|
| off_dribble (+0.015) | 15 | 15 | 5.07 (0.70) | 5.07 x 0.015 x 1.3 = 0.099 | 0.033 | **0.65x** |
| extra_pass (+0.015) | 15 | 15 | 13.8 (0.9) | 13.8 x 0.015 x 1.14 = 0.236 | 0.079 | **1.6x** |
| catch_shoot (+0.015) | 15 | 15 | 10.6 (1.1) | 10.6 x 0.015 x 1.35 = 0.215 | 0.072 | **1.4x** |
| contest (0.015) | 25 | 25 | 29.1 (1.3) | 29.1 x 0.015 x 1.08 = 0.471 | 0.157 | **3.1x** |
| contest, one holder (bound games) | 120 | 120 | 8.4-9.4 (0.4) | 9 x 0.015 x 1.08 = 0.146 | 0.146 | **2.9x** |
| board_work (x1.05) | 15 | 15 | 4.6 (0.6), mostly balls he had anyway | see notes: about 0.06 | about 0.02 | **about 0.4x** (rough) |
| side_step (x0.95) | 15 | **1** | 0.067 (0.067); expected 1.07 blocks x 5% = 0.053 | 0.053 x 0.6 = 0.032 | 0.011 | **0.2x** |

Notes:

- **contest** fires on almost every shot the holder's man takes. With three holders, 29 of RED's 31 shots a game are
  hit, and with one holder 8-9 a game. It is the strongest perk of any chapter by this method: `quick_pass` is about
  2x, `quick_hands` 1-3x. At 0.005, one holder takes about 0.05 points a game, which is 1.0x.
- **extra_pass and catch_shoot** sit at 1.4-1.6x. P10-26 counted 0.5-1.5x as inside the method's error, and the owner
  kept `quick_pass` at about 2x. 0.010 ("+1%") brings both to about 1.0x. That part is optional.
- **off_dribble:** 0.025 ("+2.5%") is about 1.1x. The CPU pull-up an off_dribble player rolls after his crossovers
  did not raise BLUE's pull-ups: 5.8 a game against 6.6 with no perk, within noise. The perk's worth is the bonus
  alone.
- **board_work:** the counter overstates the effect.
  - At x1.05 the reach grows from 20 px to 21 px (1/12 ft). A ball in that band is nearly always one he would pick
    up a frame or two later anyway.
  - Rebound rates are the honest measure (BLUE's offensive and defensive rebound shares, against 130 Quick Game games
    with perks that don't touch rebounds: OREB 26.1%, DREB 78.8%, SE 1.0 each):

    | board_work | OREB | DREB | Rebounds / game, team | SE |
    |---|---|---|---|---|
    | x1.05, 15 games | 21.8% | 88.3% | +0.56 | about 0.5 |
    | x1.2, scratch, 20 games | 30.3% | 77.0% | +0.45 | about 0.5 |
    | **x2.0, scratch, 20 games** | 29.2% | **90.3%** | **+1.84** | about 0.5 |

  - Scaling the x2.0 gain down by (m - 1), or by the band's area (m^2 - 1), gives:
    - x1.05: +0.06-0.09 rebounds, about 0.3-0.4x;
    - x1.15: +0.2-0.28 rebounds, **0.9-1.3x**;
    - x1.2: 1.25-1.7x.
  - Here a rebound won is worth about 0.7 points (0.56-0.59 points a possession, plus the stop).
- **side_step:** the scratch run at x0.5 measured 0.53 blocks turned away a game, so about 1.07 blocks a game land on
  three holders' layups (0.36 for one player).
  - x0.95 turns away 5% of those: 0.053 a game. The measured rate was 1 in 15 games.
  - x0.80, the largest `PERK_MULT_MAX` allows, turns away 0.21 a game, worth about 0.13 points: **about 0.85x**.
  - A single pupil would still see it about once every 14 games at x0.95, and about once in 4-5 games at x0.80.
  - If the owner wants it worth more, or seen more often, the limit or the hook has to change. One option: count
    dunks and close shots too, like `shoulder`. That is a code change for the lead, not a size.
  - A layup that is not blocked scores about 0.75 x 1 point, minus the 20% of blocks BLUE gets back: about 0.6
    points.
- **Win shares** in the perk games move within noise. BLUE's margin runs from -2.1 (no perk) to +2.7 (`side_step` x0.5),
  with SE 1.1-1.6 a cell. The no-perk set's BLUE won only 30% (9/30, SE 8), against 45% in P10-26. That is the Kings
  against the Bridge Runners, not a perk effect. Every perk set lands between 40% and 73% for BLUE.

## Proposed perk sizes (owner decides; `scripts/legends_data.gd` `PERKS`, the Present only)

| Perk (mentor) | Key | Now (P5 a) | Proposed | Worth now -> proposed | Text if changed |
|---|---|---|---|---|---|
| off_dribble (Deep End) | `pullup_bonus` | 0.015 | **0.025** | 0.65x -> 1.1x | Jumpers right after his crossover +2.5% |
| extra_pass (Toolbox) | `assist_shot_bonus` | 0.015 | **0.010** (optional) | 1.6x -> 1.05x | A teammate's shot right after his pass +1% |
| catch_shoot (Stretch) | `catch_shot_bonus` | 0.015 | **0.010** (optional) | 1.4x -> 0.95x | Jumpers right after a catch +1% |
| contest (Switch) | `guard_contest_bonus` | 0.015 | **0.005** | 3.1x -> 1.0x | The man he guards shoots 0.5% worse |
| board_work (Skylight) | `rebound_reach_mult` | 1.05 | **1.15** | 0.4x -> 0.9-1.3x | Reaches rebounds 15% further |
| side_step (Zigzag) | `layup_block_mult` | 0.95 | **0.80** (the limit) | 0.2x -> 0.85x | Layups 20% harder to block |

All the proposed values are inside `_check_perks()`'s limits (`_bonus` in (0, 0.06], `_mult` within 0.2 of 1.0). If
the owner takes them, `docs/VISION.md` (P5 a) and the BOARD contract line for the six perks need the new sizes. The
`text` strings are about the same length as today's. The bound needs no rerun after the change:

- the measured bound used `contest` at 0.015, three times its proposed worth;
- `quick_pass` (2x) stays the strongest perk after it;
- the bound only goes up from here.

## Checks

| Check | Result | |
|---|---|---|
| Hard: RED wins 20%+ against legend + boss + best perks (late boss games and New York) | 44% pooled (180); cells 60 / 45 / 50 / 39 / 45% | **pass** |
| New York SF on Hard, 80+ games (Phase 10 watch item) | 31/80 = 39% (SE 5); with Toolbox forced 6/20 = 30% | **pass** (no longer at the edge) |
| A Present legend in the bound | the sim prefers Eyes Closed or Quarterback; forced Toolbox SF 30%, final 45% | pass |
| Chapter 3 finale, best crew, Hard (P11-23 note, RED 1/10) | 16/40 = 40% (no perk), 10/20 = 50% (2 perks) | **pass** (the 1/10 was noise) |
| New York on Hard can still be lost (owner L7 a) | QF 50%, SF 39%, final 45% | pass |
| Easy < Normal < Hard < LEGEND | 35 / 30 / 44 / 60% (20 / 20 / 180 / 20 games) | Hard < LEGEND shown; Easy vs Normal not resolved at 20 games |
| LEGEND 10+ over Hard (P8-25 proposal) | +16 (SE 12) | not resolved (20 games); P10-26 +11 |
| Each Present perk about 2 stat points | contest 3x; extra_pass 1.6x; catch_shoot 1.4x; off_dribble 0.65x; board_work about 0.4x; side_step 0.2x | **fail as sized**; the proposals bring each to about 1x |
| Every Present perk fires | all 6; side_step in 1 of 15 games (three holders) | pass (side_step rare) |
| Script errors, unfinished games, shot-clock violations | 0, 0, 0 | pass |
| `--humantest` x2 | both FINAL, exit 0 | pass |
| Screenshots | not taken (headless, no visual change) | n/a |

## Game stats (mean, range)

| | Bound (280) | Chapter 3 finale (60) | Quick Game perk games (185) | Target (CLAUDE.md) | |
|---|---|---|---|---|---|
| Game length | 8.7 min (5.2-12.9) | 7.6 (5.4-11.0) | 9.8 (6.4-13.9) | 7-11 | pass |
| Shots per game | 58.8 (36-92) | 55.9 (38-89) | 61.6 (41-86) | 55-90 | pass |
| Field goal % | 53.7% | 50.3% | 53.1% | about 50% | pass |
| Loser's points | 16.1 (7-20) | 15.8 (8-20) | 16.2 (7-20) | usually 12-20 | pass |
| Fouls per game | 1.9 (0-6) | 1.5 (0-6) | 2.5 (0-7) | 1-5 | pass |
| Out of bounds per game | 0.7 (0-4) | 1.0 (0-4) | 1.3 (0-4) | 1-2 | pass (a little low in the bound games, as in Phase 9-10) |
| Interceptions per game | 2.3 (0-7) | 1.5 (0-4) | 2.8 (0-8) | few | pass |
| Offensive rebounds, % of misses | 27.3% | 22.1% | 24.9% | about 25% | pass |
| Shot-clock violations | 0 | 0 | 0 | few | pass |
| Side switches | 1 in every game | 1 | 1 | 1 | pass |

Humantest (both played Normal, the repo's perk sizes):

- `--humantest --city new_york --cgame 2 --best-roster --perk -,quick_pass,contest`, Toolbox forced: FINAL 21-13,
  6:13.
  - Steals timed 11/11, blocks timed 5/4, countdown presses ignored 3/3.
  - The `quick_pass` and `contest` PERK lines printed ("BRUNO's jumper from 15.1 ft, odds 0.60 (-0.015) missed").
- `--humantest --difficulty normal --perk side_step`: FINAL 21-16, 8:09.
  - Steals timed 12/14, blocks timed 2/5.
  - `side_step` never fired, as expected at x0.95.
- No errors in either.

## Bugs

None new in gameplay.

- **Minor, a test counter:** the first humantest printed `blocks timed 5/4` (more timed blocks than timed jumps). It
  comes from `main.gd`'s HUMANTEST line (`humantest_timed_blocks` / `humantest_timed_jumps`). One jump probably gets
  counted for two blocks, for example a `keep_block` swat. It is cosmetic and only in `--humantest`; worth a look in
  P11-29 or later.

## Suggested tuning and watch items (for the lead)

- **Perk sizes:** the table above. All six are proposals; nothing was applied.
  - `contest` 0.005 and `side_step` 0.80 matter most.
  - `off_dribble` 0.025 and `board_work` 1.15 lift two weak ones.
  - `extra_pass` and `catch_shoot` at 0.010 are optional.
- **`side_step`:** even at the 0.80 limit it is about 0.85x and rare for one pupil. A bigger reach needs a design
  answer, not a size: a wider `PERK_MULT_MAX`, or the hook also covering dunks and close shots.
- **New York SF on Hard:** closed as a watch item (39% on 80 games). No `cities.gd` change is needed.
- **Chapter 3 finale against the best crew:** closed (40% on 40 games).
- **Easy against the best crew:** 35% on 20 games. P10-26 measured 7% on 100. That is probably noise. Rerun 40 games if
  the lead wants it settled.

## How to rerun

```
# a bound cell; levels easy|normal|hard, legend needs --stars 72
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --no-countdown --city new_york \
    --cgame 2 --best-roster --perk -,quick_pass,contest --difficulty hard
# the Chapter 3 finale against the best crew
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --no-countdown \
    --challenge fin:present --best-roster --difficulty hard
# a perk's effect (Quick Game, all 3 BLUE players); the stats dict has perk_<id>_t0
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --no-countdown --difficulty hard \
    --perk side_step
```

Win share is RED's share of the `FINAL` lines; the `RAMP` / `LEGENDS MATCH` lines show both crews. Run each game in a
fresh `XDG_DATA_HOME`, with one output file per process. The workers here pulled single games from a shared queue under
`flock`.
