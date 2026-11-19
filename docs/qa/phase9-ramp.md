# P9-30 Phase 9 QA: the trip ramp with a drafted legend, a boss and the best perks

**Build tested:** branch `ccr-f5c087b2-3ojk5f` at `ff0380f` (P9-24, mentor perks in play). Godot 4.3 stable (Linux),
headless, `--fixed-fps 60`, every game played to its city's target. Two copies of the project outside the checkout,
each with its own `config/name` and `XDG_DATA_HOME`; at most 2 Godot processes of mine at a time (other agents' jobs ran
on the same machine).

**Import:** clean. **Games:** 588 `--autoplay` / `--humantest` games: 426 trip city games, 160 Quick Game perk games,
2 humantest runs. Every one reached `FINAL`. No `SCRIPT ERROR` or `ERROR` lines, 0 shot-clock violations, exactly one
side switch in every game, none near `--quit-after`. `--legendtest` LEGENDTEST OK, `--triptest-data` TRIPDATA OK,
`--ratingtest` RATINGTEST OK. **No screenshots:** this task was limited to headless runs (no xvfb), and nothing visual
changed.

**Values changed: none.** `DRAFT_TIER` stays 20 and `PERKS` stay as they are (reasons below).

## Headline

- **Upper bound on Hard holds easily:** with a drafted legend, a boss and the two strongest perks, RED wins **51%** of
  the late boss games and the New York final on Hard (82/160, SE 4). The lowest 40-game cell is Los Angeles at 38%.
  The P8-25 bound (20%+, no 40-game cell under 10%) passes by a wide margin, so New York on Hard can still be lost. The
  owner's L7 a rule (tone the legend down if New York on Hard can't be lost) doesn't trigger.
- **What the legend adds:** +2.2 (New York) to +5.4 (Denver) on BLUE's starting average over the Phase 8 best crew.
  At stage 8 his stats are mostly capped at 95. In the New York final on Hard RED wins 52% against legend + boss +
  perks and 62% against the P8 best crew (`--legends-unlock-none`, no perks). That is -10 points, SE 11, not
  significant. The P8-25 fit (+0.034 logit per rating point) predicts about -2 points from the ratings alone.
- **Levels, both sets pooled (76 games for each level, 160 on Hard):** Easy 20%, Normal 25%, Hard 51%, LEGEND 57%. The
  order Easy < Normal < Hard < LEGEND holds. But **LEGEND is only 6 points over Hard here** (SE 7). P8-25's target is
  10+ points. The cause: BOSS_CAP 95 keeps New York's LEGEND bonus to +5.1 on RED's average (89.5 to 94.6). This is a
  watch item for `Difficulty.LEGEND_BONUS` (not in this task's scope), not a fail.
- **`--expected-roster` unchanged:** no legend and no perk enter it by code (`_sim_legends` is only set for the best
  sim, `_perks_off` for both). Its RAMP lines match P8-25 exactly: Denver 3 62.1 v 75.5, New York final 70.5 v 89.5.
  New York final on Normal: RED 8/20 = 40% (P8-25: 3/12; Phase 6: 62%), within the noise.
- **Perks (owner L8 a: "about 2 stat points' worth"):** by the shots and plays each perk changed, every perk is worth
  about **2 to 5 times** what 2 stat points (+6 on one stat) give one player. In absolute terms they are still small:
  0.1 to 0.25 points a game per player, which no win-share test can resolve. The sizes are the owner's own L8 a numbers
  (close shots +4%, block window 10%, ...), so I did not change them. Smaller values are proposed below for the lead and
  owner to decide.
- **Finding:** `--best-roster` does **not** add a perk. `Trip._sim_roster()` sets `_perks_off = true` for both sims;
  the comments at `trip.gd` lines 68 and 793 say "P9-30 adds the best perk there", but no code does. I used P9-24's
  flag on BLUE: `--perk -,quick_pass,close_touch`. The legend is always BLUE player 0 and can't be a pupil, so this
  gives the boss and the third starter the two strongest perks, each from a different mentor, which is legal. To make
  `--best-roster` alone carry the perk, the lead must change `trip.gd`; that's a gameplay-code change outside my scope.

## Setup

- `--autoplay --city <id> --cgame 3 --best-roster --perk -,quick_pass,close_touch --difficulty <level>` (LEGEND with
  `--stars 72`). In the sim the best crew may draft any legend (`_sim_legends`). It picks Quarterback each time: his
  shape is the flattest, so he loses the least to the 95 cap and has the best rating sum.
- Hard: 40 games each for Denver 3, Seattle 3, Los Angeles 3 and the New York final. Easy, Normal and LEGEND: 40 games
  of the New York final and 12 games each for the three late boss games, pooled (36), as the task allowed.
- Comparison runs: the New York final on Hard with the P8 bound (`--best-roster --legends-unlock-none`, no perk), 40
  games. The New York final on Normal with `--expected-roster`, 20 games.
- Perks: Quick Game on Hard (Kings vs Bridge Runners, every player at an average of 50), `--perk <id>` on all 3 BLUE
  players, 20 games per perk, plus 40 games without a perk.

## The starting crews (RAMP lines)

| Game | BLUE best (legend + boss + 1) | BLUE avg | P8 best avg (no legend) | Legend's stats (spd/sht/fin/def/sta) | RED avg (Hard) | RED avg LEGEND |
|---|---|---|---|---|---|---|
| Denver 3 | lg_quarterback, nol_boss, nol_g1 | 76.3 | 70.9 | 88/88/73/83/83 | 75.5 | 87.5 |
| Seattle 3 | lg_quarterback, den_boss, den_g1 | 81.3 | 75.9 | 93/93/78/88/88 | 80.5 | 90.6 |
| Los Angeles 3 | lg_quarterback, sea_boss, sea_g1 | 85.8 | 80.8 | 95/95/83/93/93 | 85.5 | 92.6 |
| New York final | lg_quarterback, la_boss, ny_q1 | 91.1 | 88.9 | 95/95/88/95/95 | 89.5 | 94.6 |

At New York the L7 a rule gives 78 + 20 = 98 before his shape and the cap, so 4 of his 5 stats are capped. Lowering
DRAFT_TIER down to about 17 would change nothing there (he'd still be 95 on 4 stats). It would only weaken him in
the earlier cities, where RED still wins half the games on Hard.

## RED win share, best crew with legend, boss and 2 perks (SE, games)

| Game | Easy | Normal | Hard | LEGEND |
|---|---|---|---|---|
| Denver 3 | 2/12 (17%) | 1/12 (8%) | **23/40 = 57% (8)** | 7/12 (58%) |
| Seattle 3 | 3/12 (25%) | 3/12 (25%) | **23/40 = 57% (8)** | 5/12 (42%) |
| Los Angeles 3 | 2/12 (17%) | 4/12 (33%) | **15/40 = 38% (8)** | 8/12 (67%) |
| New York final | **8/40 = 20% (6)** | **11/40 = 28% (7)** | **21/40 = 52% (8)** | **23/40 = 57% (8)** |
| Late 3 pooled | 7/36 = 19% (7) | 8/36 = 22% (7) | 61/120 = 51% (5) | 20/36 = 56% (8) |
| All 4 pooled | 15/76 = 20% (5) | 19/76 = 25% (5) | **82/160 = 51% (4)** | 43/76 = 57% (6) |

The 12-game cells (SE 11-14) can't be read on their own. P8-25's best crew without legends (12-game cells): Hard late
boss games 42 / 67 / 58 / 75%, Normal 50 / 33 / 42 / 42% (Denver / Seattle / LA / New York). Normal now reads lower (25%
pooled vs about 42%); the legend shows most where the level gap is smallest. There is no band for Easy or Normal on
the best crew.

**Comparison, the New York final on Hard:** legend + boss + 2 perks 21/40 = 52% (SE 8); P8 bound
(`--legends-unlock-none`, no perk) 25/40 = 62% (SE 8). Difference -10, SE 11.

## Perks: measured effect and "2 stat points"

Quick Game on Hard, the perk on all 3 BLUE players, 20 games each (none: 40). "Events" = the perk's own counter
(`perk_<id>_t0`: shots it raised, passes it sped up, block tries good only because of it, dunks from beyond 6 ft). A
point is a game point (1 inside the arc, 2 beyond).

| Perk (value) | Events per game (team) | Measured change vs none (SE) | Expected points per game, team | Per player | x "2 stat points" |
|---|---|---|---|---|---|
| close_touch (+0.04) | 12.3 (0.9) | jumper makes 5.10 to 6.30; layup make 0.577 to 0.586 | 12.3 x 0.04 x 1 = **0.49** | 0.16 | about 3x |
| soft_layup (+0.03) | 10.0 (0.7), nearly every layup counts as contested | layup make 0.577 to 0.592 | 10.0 x 0.03 x 1 = **0.30** | 0.10 | about 2x |
| deep_range (+0.03) | 6.9 (0.3) | three make 0.270 to 0.399 (138 threes; mostly noise, expected +0.03) | 6.9 x 0.03 x 2 = **0.41** | 0.14 | about 2.5-3x |
| block_timing (x1.10) | 5.1 (0.6) good tries | blocks 4.03 to 4.75 (+0.7, SE 0.7) | about 0.7 blocks x 0.6 = **~0.45** (rough) | ~0.15 | about 3x (rough) |
| long_dunk (x1.10, 6.0 to 6.6 ft) | 5.3 (0.5) dunks from beyond 6 ft | dunks 8.6 to 9.4 (SE 0.9); rim points +0.2 (SE 0.7) | 5.3 x (0.70 dunk - 0.58 layup) = **~0.6** (upper estimate) | ~0.2 | about 2-4x |
| quick_pass (x1.10) | 41 (2.4) passes | interceptions (both teams) 3.58 to 2.50 (-1.1, SE 0.5) | about 1.1 x 0.6-0.9 = **~0.7-1.0** | ~0.25-0.3 | about 4-5x |

**"2 stat points":** one point = +3 (`Trip.POINT_GAIN`), so 2 points = +6 on one stat of one player. From the ratings
table (`--ratingtest`) and these games' shot counts (per player per game: 3.2 layups, 2.9 dunks, 5.3 jumpers):

- finishing +6: x1.0144 on his layups and dunks, about +0.009 per rim shot, so **+0.056 points per game**;
- shooting +6: x1.018 on his jumpers, about +0.006 per jumper, so **+0.045 points per game**.

So 2 stat points are worth about 0.05 points per game for one player. The shot perks' numbers are solid: they are
counted events times a fixed bonus. Block, dunk and pass go through a play, so those are estimates (marked rough).
Win shares and point margins move by +1 to +2 points for every perk vs none (SE 1.2-1.4). That is not resolvable, and
the 40-game "none" set probably came out a little low (BLUE 35% vs about 50% expected).

In the trip (the `bh_` runs) the perks fire just as often per player: close_touch 3.5-4.2 shots and quick_pass
11.7-12.8 passes per game for the one player who has each.

## Checks

| Check | Result | |
|---|---|---|
| Hard: RED wins 20%+ (late boss games and New York, best crew with legend + boss + perk) | 51% pooled (160 games); cells 38 / 52 / 57 / 57% | pass |
| No 40-game cell under 10% (P8-25 proposal) | lowest 38% (LA, Hard) | pass |
| New York on Hard can still be lost (owner L7 a) | RED 52% (21/40) | pass, DRAFT_TIER kept at 20 |
| `--expected-roster` unchanged | no legend or perk by code; RAMP lines = P8-25; NY final Normal 40% (20) | pass |
| Easy < Normal < Hard < LEGEND | 20 < 25 < 51 < 57% (76 / 76 / 160 / 76 games) | pass |
| LEGEND 10+ points over Hard (P8-25 proposal) | +6 (SE 7) | **watch** (BOSS_CAP limits New York; not in scope) |
| Perks about 2 stat points' worth (L8 a) | about 2-5x (0.1-0.3 points a game per player) | **over, proposal below** (owner's L8 a values kept) |
| Each perk fires (`--perk <id>`, PERK log lines and counters) | all 6, every game | pass |
| `--best-roster` adds the best perk (board P9-21 / P9-30 note) | it does not (`_perks_off`); used `--perk` | **finding** |
| `--legendtest`, `--triptest-data`, `--ratingtest` | OK, OK, OK | pass |
| Script errors, unfinished games, shot-clock violations | 0, 0, 0 | pass |
| Screenshots | not taken (headless-only task) | n/a |

## Game stats

| | Trip games (426) | Quick Game, Hard (160 + 2 humantest) | Target (CLAUDE.md) | |
|---|---|---|---|---|
| Game length to 21 | 8.4 min (5.2-11.9) | 9.4 min (6.7-13.3) | 7-11 | pass |
| Shots per game | 63.5 (38-87) | 66.2 (44-91) | 55-90 | pass |
| Field goal % | 50.7% | 51.0% | about 50% | pass |
| Loser's points | 16.2 (7-20) | 16.6 (8-20) | usually 12-20 | pass |
| Fouls per game | 2.4 (0-8) | 2.5 (0-7) | 1-5 | pass |
| Out of bounds per game | 1.0 (0-6) | 1.3 (0-5) | 1-2 | pass |
| Interceptions per game | 2.4 (0-10) | 3.2 (0-12) | few | pass |
| Shot-clock violations | 0 | 0 | few | pass |
| Side switches | 1 in every game | 1 in every game | 1 | pass |

Humantest: `--humantest` (Hard) FINAL 15-21, 7:41, steals timed 14/15, blocks timed 4/3, countdown presses ignored
3/3. `--humantest --difficulty normal` FINAL 21-14, 6:58, steals timed 9/13, free throws early 0/1. No errors.

## Bugs

1. **`--best-roster` has no perk although the comments say it does** (`trip.gd` lines 68 and 793).
   Steps: `--autoplay --city new_york --cgame 3 --best-roster`. Expected (per the comments and board line 152): the
   best crew plays with the best perk. Actual: no `PERK` lines, no `perk_*` counters; `_sim_roster()` sets
   `_perks_off = true` for both sims. Fix options for the lead: keep `--perk` as the way the bound is measured and fix
   the comments, or have `_sim_roster(best)` hand perks to the non-legend starters. Low priority: the bound holds
   either way (perks are worth about 0.1-0.3 points a game per player).

## Suggested tuning (for the lead and the owner; not applied)

- `LegendsData.DRAFT_TIER`: **keep 20.** Hard is at 51% pooled with the legend in the crew; the bound has about 30
  points of margin.
- `LegendsData.PERKS`, only if the owner wants "about 2 stat points" literally (the L8 a values are his own; each
  perk is now 2-5x that, though still small in points):

| Perk | Now | Proposed | About x "2 stat points" after |
|---|---|---|---|
| close_touch `close_shot_bonus` | 0.04 ("+4%") | **0.015** ("+1.5%") | 1.2x |
| soft_layup `contested_layup_bonus` | 0.03 ("+3%") | **0.015** ("+1.5%") | 1x |
| deep_range `three_bonus` | 0.03 ("+3%") | **0.015** ("+1.5%") | 1.3x |
| block_timing `block_window_mult` | 1.10 ("10% wider") | **1.05** ("5% wider") | ~1.5x (rough) |
| long_dunk `dunk_reach_mult` | 1.10 | **1.05** | ~1-2x (rough) |
| quick_pass `pass_speed_mult` | 1.10 ("10% faster") | **1.05** ("5% faster") | ~2x (rough) |

  All of these stay inside `_check_perks()`'s limits (_bonus in (0, 0.06], _mult in (1.0, 1.2]). Each change needs
  its `text` changed with it, and `docs/legends-plan.md` (perk table, L8 a) updated. The ramp bound needs no rerun for
  smaller perks: it passed with the current, stronger ones.
- `Difficulty.LEGEND_BONUS` (watch, outside this task): with a drafted legend on BLUE, LEGEND is only 6 points over
  Hard. If the owner wants LEGEND clearly harder in New York, `Trip.BOSS_CAP` (95) is what holds it back there.

## How to rerun

```
# a bound cell (12-40 games); levels easy|normal|hard, legend needs --stars 72
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --city new_york --cgame 3 \
    --best-roster --perk -,quick_pass,close_touch --difficulty hard
# the P8 bound for comparison
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --city new_york --cgame 3 \
    --best-roster --legends-unlock-none --difficulty hard
# a perk's effect (Quick Game, all 3 BLUE players)
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --difficulty hard --perk close_touch
```
Win share is RED's share of `FINAL` lines; the `RAMP` line has both crews; the stats dict has `perk_<id>_t0`.
