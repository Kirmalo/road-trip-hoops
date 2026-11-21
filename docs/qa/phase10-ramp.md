# P10-26 Phase 10 QA: the trip ramp with a Father, a boss and the best perks

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `1c7ff3b` (Phase 10 Wave 4 merged: the Fathers, their perks hooked
by P10-22, P10-N1). Godot 4.3 stable (Linux), headless, `--fixed-fps 60 --no-countdown`, every game played to its
city's target. Two copies of the project outside the repo (own `config/name`), every game in its own fresh
`XDG_DATA_HOME` (no trip save, no Legends file), at most 2 Godot processes at a time.

**Import:** clean (no errors, no warnings). **Games:** 872: 500 bound games, 80 comparison games, 290 Quick Game perk
games (200 at the F5 a sizes, 90 after the tuning), 2 `--humantest`. Every one reached `FINAL` with exit 0. No `SCRIPT
ERROR` or `ERROR` lines, 0 shot-clock violations, exactly one side switch in every game, the longest game 49,578 frames
(`--quit-after` 200,000). `--legendtest` LEGENDTEST OK before and after the tuning (one NOTE: `legends_fathers.ogg` is
not there yet). **No screenshots:** headless task, and nothing visual changed (only three perk `text` strings in the Hall,
the same lengths as before).

**Values changed (`scripts/legends_data.gd` `PERKS`, the Fathers only):**

| Perk | Key | Before (F5 a) | After | Text after |
|---|---|---|---|---|
| rise_up (Rooftop) | `contested_dunk_bonus` | 0.015 | **0.025** | Contested dunks +2.5% |
| handle (Ankles) | `cross_win_mult` | 1.05 | **1.15** | Crossovers beat the defender 15% more often |
| blind_pass (Eyes Closed) | `pass_safe_mult` | 0.95 | **0.85** | Passes 15% harder to intercept |

pull_up, strong_hold and quick_hands are unchanged. All values stay inside `_check_perks()`'s limits.
`docs/VISION.md` (F5 a) and `docs/BOARD.md` (the P10 perk contract, lines 88-90) still list the old sizes. I did not
edit them because they record the owner's answer. The lead should confirm the change with the owner, or revert these
three lines.

## Headline

- **The upper bound on Hard holds:** with the strongest legal three (a drafted legend + one boss + one more) and the
  two strongest perks, RED wins **46%** of the late boss games and the New York rounds on Hard (93/200, SE 4). The
  lowest 40-game cell is the **New York semifinal at 20%** (8/40, SE 6), right on the line. Every other Hard cell is
  50-55%. P8-25's bound (20%+, no 40-game cell under 10%) passes. New York on Hard can still be lost: the final is 50%.
- **A Father is the best draft in New York:** in `--city` runs every built legend is draftable (P10-N1). The sim
  drafts `lg_eyes_closed` (95/95/93/93/95, avg 94.2) for all three New York rounds. For Seattle 3 and Los Angeles 3 it
  still drafts the Grandfather `lg_quarterback`, so those two games match P9-30's setup.
- **The semifinal is the soft spot**, and the drafted legend is what makes it soft, not the perks. New York SF on
  Hard, 40 games each:

  | BLUE | BLUE avg | RED wins |
  |---|---|---|
  | P8 bound (`--legends-unlock-none`, no perk) | 87.6 | 17/40 = 42% (8) |
  | Eyes Closed + boss, no perk | 91.3 | 10/40 = 25% (7) |
  | Eyes Closed + boss + 2 perks | 91.3 | 8/40 = 20% (6) |

  The legend costs RED about 17 points (SE 10). The perks cost about 5 more, which is noise. The SF crew (avg 83.9)
  is 7.4 under the best BLUE three. The QF crew is 8.8 under and still wins 55%, so crew style matters as much as the
  rating gap here. In the final, with legend, boss and perks, RED wins 50%. P9-30 measured 52% there with the
  Quarterback and the old, larger perks.
- **Levels (all 5 games pooled):** Easy 7% (100), Normal 26% (100), Hard 46% (200), LEGEND 57% (100). The order
  holds. LEGEND is **+11 over Hard (SE 6)**, which meets P8-25's 10+ proposal this time (P9-30 measured +6 with
  SE 7). The two readings are within noise of each other.
- **Perks ("about 2 stat points' worth", owner):** 2 stat points (+6 on one stat of one player) are worth about
  **0.05 points a game** in these games, as in P9-30.
  - At the F5 a sizes, **pull_up (0.9x), strong_hold (about 1.1x) and quick_hands (1-3x)** were about right.
  - **rise_up (0.55x), handle (0.2-0.5x) and blind_pass (0.35x)** were well under. handle fired in 6 of 30 games,
    strong_hold in 3 of 30 and blind_pass in only **1 of 30**, so a pupil would almost never see it.
  - After the tuning: rise_up about 1.0x, handle about 0.5-1.5x (fires in 14 of 30 games), blind_pass about 1.2x
    (7 of 30).
  - No perk is over 2 stat points by more than the method's error (quick_hands is an upper estimate). None of them
    moves a win share by a measurable amount.
- **The best perk of either chapter:** I used `--perk -,quick_pass,quick_hands`. Player 0 is the drafted legend, who
  can't be a pupil. The boss gets Quarterback's quick_pass (P9-30's strongest; about 2x at 1.05). The third starter
  gets Lockbox's quick_hands (the strongest Fathers perk by these counts). They come from two different mentors, so
  the crew is legal. A drafted legend may still mentor (owner: only legends can't be pupils). The tuned perks are each
  about 1x, so this pair is still the strongest, and the bound needs no rerun after the tuning.

## Setup

- Bound: `--autoplay --city <id> --cgame N --best-roster --perk -,quick_pass,quick_hands --difficulty <level>`
  (LEGEND: `--difficulty legend --stars 72`) for Seattle 3, Los Angeles 3 and the New York QF, SF and final.
  - Hard: 40 games per game.
  - Easy, Normal and LEGEND: 20 per game, pooled into 40-game late-boss cells and 60-game New York cells (100 a
    level).
- Comparison: New York SF on Hard, 40 games each, with the P8 bound (`--best-roster --legends-unlock-none`, no perk)
  and with the best three without a perk.
- Perks: Quick Game on Hard (Kings vs Bridge Runners), `--perk <id>` on all 3 BLUE players.
  - At the F5 a sizes: 20 games each for rise_up and pull_up, 30 each for handle, strong_hold, blind_pass and
    quick_hands (the rare ones got 10 more), and 40 games without a perk.
  - After the tuning: 30 games each for rise_up, handle and blind_pass.

## The starting crews (RAMP lines)

| Game | BLUE best (legend + boss + 1) | BLUE avg | Legend (spd/sht/fin/def/sta) | RED avg Hard (Easy, Normal the same) | RED avg LEGEND |
|---|---|---|---|---|---|
| Seattle 3 | lg_quarterback, den_boss, den_g1 | 81.3 | 93/93/78/88/88 | 80.5 | 90.6 |
| Los Angeles 3 | lg_quarterback, sea_boss, sea_g1 | 85.8 | 95/95/83/93/93 | 85.5 | 92.6 |
| New York QF | lg_eyes_closed, la_boss, la_g1 | 89.7 | 95/95/93/93/95 | 80.9 | 91.5 |
| New York SF | lg_eyes_closed, la_boss, ny_q1 | 91.3 | 95/95/93/93/95 | 83.9 | 92.9 |
| New York final | lg_eyes_closed, la_boss, ny_q1 | 91.3 | 95/95/93/93/95 | 89.5 | 94.6 |

At Seattle and Los Angeles these match P9-30 exactly. In New York the Father adds +0.2 to the final's BLUE average
over P9-30's Quarterback (91.1). He is capped at 95 on three stats, so `DRAFT_TIER` does nothing here.

## RED win share, best crew with legend, boss and 2 perks (SE, games)

| Game | Easy | Normal | Hard | LEGEND |
|---|---|---|---|---|
| Seattle 3 | 1/20 = 5% (5) | 8/20 = 40% (11) | **21/40 = 52% (8)** | 10/20 = 50% (11) |
| Los Angeles 3 | 0/20 = 0% | 2/20 = 10% (7) | **22/40 = 55% (8)** | 11/20 = 55% (11) |
| New York QF | 2/20 = 10% (7) | 3/20 = 15% (8) | **22/40 = 55% (8)** | 13/20 = 65% (11) |
| New York SF | 1/20 = 5% (5) | 6/20 = 30% (10) | **8/40 = 20% (6)** | 8/20 = 40% (11) |
| New York final | 3/20 = 15% (8) | 7/20 = 35% (11) | **20/40 = 50% (8)** | 15/20 = 75% (10) |
| Late 2 pooled | **1/40 = 2% (2)** | **10/40 = 25% (7)** | **43/80 = 54% (6)** | **21/40 = 52% (8)** |
| New York 3 pooled | **6/60 = 10% (4)** | **16/60 = 27% (6)** | **50/120 = 42% (5)** | **36/60 = 60% (6)** |
| All 5 pooled | **7/100 = 7% (3)** | **26/100 = 26% (4)** | **93/200 = 46% (4)** | **57/100 = 57% (5)** |

The 20-game cells (SE 5-11) can't be read on their own. P9-30, the same setup with the Quarterback and the old
perks: Easy 20%, Normal 25%, Hard 51%, LEGEND 57% (76 / 76 / 160 / 76 games). Easy reads lower now (7% vs 20%, about
2.5 SE). There is no band for Easy on the best crew, and an Easy trip with the best possible three should be easy.
Average final margin (BLUE - RED): Easy +5.8, Normal +2.9, Hard +0.4, LEGEND -1.0.

## Perks: measured effect and "2 stat points"

The perk is on all 3 BLUE players, Quick Game, Hard. "Events" are the perk's own counter (`perk_<id>_t0`):

- rise_up: contested dunks it raised;
- pull_up: inside-arc jumpers it raised;
- handle: crossovers that beat the man only because of it (`perk_cross_beats_t0`);
- strong_hold: pokes that would have stripped anyone else;
- blind_pass: pick-offs it stopped;
- quick_hands: pokes that were well timed only in the wider window.

A game point is 1 inside the arc and 2 beyond. A turnover avoided or forced is worth 0.6-0.9 points (BLUE scores 0.60
a possession here, plus the transition chance).

**"2 stat points"** = +6 on one stat of one player. Per player per game in the no-perk games, from the `ratings.gd`
spans:

| Stat +6 | Change per chance | Chances per player per game | Points per player per game |
|---|---|---|---|
| finishing | x1.0144 | 4.75 rim shots | +0.048 |
| shooting | x1.018 | 2.7 mid jumpers, 2.4 threes | +0.059 |
| defense (steal +6) | +0.024 on a 0.7 poke | 1.4 steals | +0.036, plus blocks |

So the yardstick is about **0.05 points per game per player**, the same as P9-30.

| Perk (value) | Games | Fired in | Events / game, team (SE) | Points / game, team | Per player | x "2 stat points" |
|---|---|---|---|---|---|---|
| rise_up (+0.015) | 20 | 20 | 5.50 (0.44) | 5.50 x 0.015 = 0.083 | 0.028 | **0.55x** |
| **rise_up (+0.025, new)** | 30 | 30 | 5.87 (0.50) | 5.87 x 0.025 = 0.147 | 0.049 | **1.0x** |
| pull_up (+0.015) | 20 | 20 | 8.85 (0.63) | 8.85 x 0.015 = 0.133 | 0.044 | **0.9x** |
| handle (x1.05) | 30 | 6 | 0.27 (0.11) | 0.27 x 0.1-0.3 (rough, a beat's worth) = 0.03-0.08 | 0.01-0.03 | **0.2-0.5x** |
| **handle (x1.15, new)** | 30 | 14 | 0.77 (0.18) | 0.77 x 0.1-0.3 = 0.08-0.23 | 0.03-0.08 | **0.5-1.5x** |
| strong_hold (x0.95) | 30 | 3 | 0.13 (0.08); expected 4.2 RED steals x 5.3% = 0.22 | 0.22 x 0.75 = 0.17 | 0.055 | **about 1.1x** |
| blind_pass (x0.95) | 30 | **1** | 0.03 (0.03); expected 1.3 BLUE pick-offs x 5% = 0.07 | 0.07 x 0.75 = 0.05 | 0.017 | **0.35x** |
| **blind_pass (x0.85, new)** | 30 | 7 | 0.23 (0.08) | 0.23 x 0.75 = 0.17 | 0.058 | **about 1.2x** |
| quick_hands (x1.05) | 30 | 17 | 0.77 (0.15) | 0.77 x 0.72 (steals per good poke) x 0.75 = 0.42 (upper) | 0.05-0.14 | **1-3x** (rough) |

Notes:

- **rise_up:** almost every dunk counts as contested (11.6 of 11.8 dunks a game), so the perk is in effect "dunks
  +x". The odds sit near 0.85, under `SHOT_CAP` 0.92, so little of the bonus is lost to the cap.
- **handle:** the second roll is `(x - 1) x 0.42 / 0.58` per crossover that did not beat the man (about 7 a game for
  the team). That is +0.036 a crossover at 1.05 and +0.11 at 1.15. The measured 0.27 and 0.77 beats a game match it.
  What a beat is worth is the rough part:
  - nearly every shot in these games counts as contested (layups 16.8 contested vs 0.2 "mid" a game), so a beat buys
    a cleaner drive more than an open shot;
  - I put it at 0.1-0.3 points;
  - P10-21's ISO BALL (+2.5 beats a game) moved FG % by +2.7 points, but its longer dunks are mixed in.
- **strong_hold and blind_pass:** the counts are too rare to measure well. The expected values (the base rate x the
  5% or 15% cut) agree with the counts.
  - At 0.95, strong_hold is about right by worth, but it fires in 3 of 30 games (RED strips BLUE about 4 times a
    game). I left it, because it is at size. If the owner wants it seen more often, 0.90 doubles it (about 2.2x).
- **quick_hands:** the counter overstates the gain. The CPU defender also times his pokes on the wider window
  (`defense.gd`), so without the perk many of these pokes would just land a moment later, in the normal window.
  BLUE's steals measured 4.50 against 4.17 a game without a perk (+0.33, SE about 0.5). The geometric estimate (5%
  more good pokes) gives about 1x.
- **Win shares:** BLUE's win share and margin move by -1.5 to +2.2 points against no perk (SE 1.0-1.4 a cell), which
  is noise for every perk. A perk of this size can't be resolved by win share. The none set's BLUE won 45% (18/40).
- **In the bound games** (one player each), quick_pass fired 12.9 passes a game and quick_hands 0.24 pokes a game.
  P9-30 measured quick_pass at 11.7-12.8 in trip games.

## Checks

| Check | Result | |
|---|---|---|
| Hard: RED wins 20%+ (late boss games and New York, legend + boss + best perks) | 46% pooled (200 games); cells 52 / 55 / 55 / 20 / 50% | **pass** |
| No 40-game cell under 10% (P8-25 proposal) | lowest NY SF 20% (8/40) | pass (**watch**: on the line) |
| New York on Hard can still be lost (owner L7 a) | QF 55%, SF 20%, final 50% | pass |
| Easy < Normal < Hard < LEGEND | 7 < 26 < 46 < 57% (100 / 100 / 200 / 100) | pass |
| LEGEND 10+ points over Hard (P8-25 proposal) | +11 (SE 6); P9-30 +6 (SE 7) | pass (just; keep watching) |
| Each Fathers perk about 2 stat points (F5 a, L8 a) | before: pull_up, strong_hold, quick_hands about 1x; rise_up, handle, blind_pass 0.2-0.55x. After the tuning: every one about 1x (0.5-3x within the method's error) | **pass after tuning** |
| Every Fathers perk fires (`--perk <id>`, counters) | all 6; before the tuning blind_pass in 1/30, strong_hold 3/30, handle 6/30 games; after: blind_pass 7/30, handle 14/30 | pass (strong_hold rare, see notes) |
| `--legendtest` before and after the tuning | LEGENDTEST OK (NOTE: `legends_fathers.ogg` missing, known) | pass |
| Script errors, unfinished games, shot-clock violations | 0, 0, 0 | pass |
| `--humantest` x2 | both FINAL, exit 0 (below) | pass |
| Screenshots | not taken (headless task, no visual change) | n/a |

## Game stats (mean, range)

| | Bound games (500) | Comparison (80) | Quick Game perk games (290) | Target (CLAUDE.md) | |
|---|---|---|---|---|---|
| Game length | 8.7 min (4.9-12.7) | 8.8 (6.0-13.8) | 9.7 (5.6-13.4) | 7-11 | pass |
| Shots per game | 58.3 (32-83) | 60.8 (38-93) | 60.6 (36-83) | 55-90 | pass |
| Field goal % | 53.8% | 51.7% | 53.8% | about 50% | pass |
| Loser's points | 15.8 (5-20) | 16.4 (8-20) | 16.3 (8-20) | usually 12-20 | pass |
| Fouls per game | 1.9 (0-7) | 1.7 (0-5) | 2.2 (0-7) | 1-5 | pass |
| Out of bounds per game | 0.8 (0-4) | 0.8 (0-4) | 1.1 (0-5) | 1-2 | pass (a little low, as in Phase 9-10) |
| Interceptions per game | 2.3 (0-10) | 2.4 (0-6) | 3.1 (0-10) | few | pass |
| Offensive rebounds, % of misses | 25.8% | 25.2% | 25.6% | about 25% | pass |
| Shot-clock violations | 0 | 0 | 0 | few | pass |
| Side switches | 1 in every game | 1 | 1 | 1 | pass |

Humantest:

- `--humantest --city new_york --cgame 3 --best-roster --perk -,quick_pass,quick_hands` (it played Normal): FINAL
  21-14, 7:37. Steals timed 13/13, blocks timed 3/4, countdown presses ignored 3/3, the quick_pass PERK line printed.
- `--humantest --difficulty normal --perk handle` (old size): FINAL 21-18, 10:01. Steals timed 17/20, blocks timed
  3/6, crossovers beat him 3/5.
- No errors in either.

## Bugs

None new.

## Suggested tuning and watch items (for the lead)

- **Applied:** rise_up 0.025, handle 1.15, blind_pass 0.85 (table at the top). Please confirm with the owner, because
  F5 a named 1.5% / 5% / 5%; or revert those three lines. If the owner wants to keep his F5 a wording, rise_up at
  0.02 ("+2%") is the smallest change that gets it to about 0.75x. handle and blind_pass need about 3x their F5 a size
  to be worth 2 stat points at all.
- **strong_hold (`strip_guard_mult`), optional:** 0.95 is about 1.1x by worth, but it shows up in 1 game in 10. 0.90
  ("10% harder to strip") would be about 2x and show up twice as often.
- **New York SF on Hard (watch):** 20% with Eyes Closed + boss + perks, 25% without the perks, 42% for the P8 bound.
  It passes, but with no margin. If the lead wants margin, the lever is the SF crew in `cities.gd`. `DRAFT_TIER`
  won't do it: the legend is capped at 95 in New York. That is a ramp number, outside this task, so I did not touch
  it. One more 40-game cell would show whether 20% is noise: the QF crew, 3 points weaker on the cards, wins 55%.
- **`Difficulty.LEGEND_BONUS` (watch):** LEGEND is +11 over Hard with the best crew here, +6 in P9-30 (each about
  SE 6-7). BOSS_CAP 95 holds New York's LEGEND crews at 91.5-94.6. No change needed.

## How to rerun

```
# a bound cell; levels easy|normal|hard, legend needs --stars 72
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --no-countdown --city new_york \
    --cgame 2 --best-roster --perk -,quick_pass,quick_hands --difficulty hard
# the P8 bound for comparison
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --no-countdown --city new_york \
    --cgame 2 --best-roster --legends-unlock-none --difficulty hard
# a perk's effect (Quick Game, all 3 BLUE players); the stats dict has perk_<id>_t0
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --no-countdown --difficulty hard \
    --perk blind_pass
```
Win share is RED's share of the `FINAL` lines. The `RAMP` line has both crews. Run each game in a fresh
`XDG_DATA_HOME`, and give each process its own output file names: two runners that pick the next free number at the
same moment overwrite each other's log. That happened to 4 of my no-perk games, which I threw away and replayed.
