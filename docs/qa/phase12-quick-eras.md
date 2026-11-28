# P12-36: era team balance in Quick Game (the New Generation)

Builds: the balance games ran on branch `ccr-f5c087b2-3ojk5f` at **`44c7ca3`** (P12-33 merged; FAST BREAK as final:
`speed_mult` 1.08, `break_mult` 1.20, `stamina_refill_mult` 1.15, `dead_ball_mult` 0.6). The branch then moved to
**`96bb720`** (owner tuning: `challenge_avg` 74, `RIM_RUN_SPEED_MULT` 1.06, four perk sizes). None of that touches an era
team: Overclock / Updraft / Halfcourt carry no rim run, and era teams carry no perks. To be sure, 4 seeded era team games
(NG vs Present gym, Fathers vs NG gym, Grandfathers vs NG NEON DOME, NG vs Concrete Crowns gym) were played on both
builds: **the whole logs are the same line for line**. So every number below holds for `96bb720`. The 2 humantests and the
screenshots ran on `96bb720`. One exception: the 20 `--signature` games (rim run, hesitation, swat on a crew) ran on
`44c7ca3`, where `RIM_RUN_SPEED_MULT` was still 1.12; that changes how fast the rim run is, not how often it fires.

Method as in `docs/qa/phase11-quick-eras.md`: Godot 4.3 stable, headless, `--fixed-fps 60`, one process per game, each
with its own fresh `XDG_DATA_HOME`, two scratch project copies (own `config/name`), at most 2 Godot processes, the cells
interleaved game by game. Every game: `--autoplay --no-countdown --difficulty hard --legends-unlock-all --unlock-all
--quick-teams <blue>,<red> --court <look>`. On an era court `--unlock-all` brings its twist (checked in the TWIST line).
Opponent crews as in Phase 11: Cornfield Kings, Bridge Runners, Concrete Crowns, Riverside Soul, each played the same
number of times on both sides. Era vs era: half the games in each order.

Era teams as built (finale three, stats shifted to average 50, signature moves on, no perks):

| Era team | Players (spd/sht/fin/def/sta) | Moves on the floor | Style as RED |
|---|---|---|---|
| THE GRANDFATHERS | Steeple 35/50/70/55/40, Velvet 60/45/65/40/40, Quarterback 55/55/40/50/50 | hook, finger roll, outlet | inside |
| THE FATHERS | Rooftop 60/50/65/40/35, Midrange 50/70/50/40/40, Freight 35/35/75/60/45 | cradle, fadeaway, shoulder | balanced |
| THE PRESENT | Deep End 55/75/40/40/40, Toolbox 55/50/55/50/40, Skylight 50/30/70/55/45 | step-back, coast, lob magnet | outside |
| THE NEW GENERATION | Overclock 75/50/50/40/35, Updraft 55/35/70/55/35, Halfcourt 50/75/40/45/40 | top gear, putback, hot hand | balanced |

## What ran (1,460 games, all ended with `FINAL`, exit 0, no script errors)

| Cell | Court (twist) | Games |
|---|---|---|
| A. New Generation vs the 4 crews | gym (none) | 200 |
| B. New Generation vs the 4 crews | NEON DOME `era_next` (FAST BREAK) | 200 |
| C. New Generation vs Fathers | gym | 200 |
| D. New Generation vs Present | gym | 200 |
| E. Grandfathers vs New Generation | OLD GYM `era_grand` (OLD SCHOOL) | 200 |
| F. Grandfathers vs New Generation | NEON DOME `era_next` (FAST BREAK) | 200 |
| G. Grandfathers, Fathers, Present vs the 4 crews (did they move since Phase 11?) | gym | 80 each |
| S. Kings / Runners with `--signature rim_run,hesitation,swat` vs New Generation | gym 10, NEON DOME 10 | 20 |

Every cell got its full count; none was cut short. Plus 7 seeded A/B games (below), 2 humantests and 1 screenshot run.

## Win shares (SE = sqrt(p(1-p)/n))

| Cell | New Generation won | SE | as BLUE | as RED | BLUE side won |
|---|---|---|---|---|---|
| A. vs crews, gym | **54.5%** (109/200) | 3.5 | 51% | 58% | 46.5% |
| B. vs crews, NEON DOME | **58.5%** (117/200) | 3.5 | 53% | 64% | 44.5% |
| C. vs Fathers, gym | **60.5%** (121/200) | 3.5 | 63% | 58% | 52.5% |
| D. vs Present, gym | **55.5%** (111/200) | 3.5 | 55% | 56% | 49.5% |
| E. vs Grandfathers, OLD GYM | **59.0%** (118/200), Grandfathers 41.0% | 3.5 | 60% | 58% | 51.0% |
| F. vs Grandfathers, NEON DOME | **54.0%** (108/200), Grandfathers 46.0% | 3.5 | 60% | 48% | 56.0% |
| A + B (all crews) | 56.5% (226/400) | 2.5 | | | |
| C to F (all era teams) | 57.3% (458/800) | 1.7 | | | |

Per crew (50 games each):

| Court | Kings | Runners | Concrete Crowns | Riverside Soul |
|---|---|---|---|---|
| gym | 56% | 58% | 40% | 64% |
| NEON DOME | 62% | 70% | 50% | 52% |

Reading it:
- **The New Generation is a strong team but not the strongest.** 54.5% against the crews on the gym is 1.3 SE over 50.
  The Present measured 61.7% in Phase 11, and the New Generation beats the Present only 55.5% head to head.
- **Their own court helps them a little**: 58.5% on NEON DOME vs 54.5% on the gym (a 4 point gap, 0.8 SE of the
  difference, so it could be chance). FAST BREAK's early shot bonus favors the team that runs, and Overclock (speed 75)
  runs the most.
- **The Grandfathers are again weakest on their own OLD GYM**: 41.0% there vs the New Generation, 46.0% on NEON DOME.
  It is the same pattern Phase 11 saw (37.5% on OLD GYM vs the crews). OLD SCHOOL's `inside_mult` helps the
  Grandfathers' opponents more than it helps them.
- The order of the era teams: New Generation over the Fathers (60.5%), the Grandfathers on OLD GYM (59%), the Present
  (55.5%) and the Grandfathers on NEON DOME (54%). Order: New Generation > Present > Fathers ~ Grandfathers.
- Side lean: in F the New Generation won 60% as BLUE and 48% as RED. Both orders were played the same number of times,
  so it cancels out. Over all 1,200 New Generation games the BLUE side won 50.0%: no side bias.

## The other three era teams: did they move?

| Era team vs crews, gym | Phase 11 (`42bf2b6`, 120 games) | Phase 12 (`44c7ca3`, 80 games) | gap in SE | both together (200) |
|---|---|---|---|---|
| Grandfathers | 56.7% | **40.0%** (32/80, SE 5.5) | 2.4 | 50.0% |
| Fathers | 48.3% | **43.8%** (35/80, SE 5.5) | 0.6 | 46.5% |
| Present | 61.7% | **53.8%** (43/80, SE 5.6) | 1.1 | 58.5% |
| All three | 55.6% (360) | 45.8% (240) | 2.4 | |

This gap is bigger than you'd expect by chance, so I checked whether the code had changed. **It hasn't.** Seeded A/B
games (a seed flag added only in the scratch copies, at the same spot as the How to Play seed) were played on the Phase
11 final build `c8e33ef` and on `44c7ca3`: Present vs Runners on the gym (both orders), Grandfathers vs Concrete Crowns
on the gym, Riverside Soul vs Fathers on the gym, Present vs Fathers on BIG STAGE, and Grandfathers vs Kings on OLD GYM.
All 6 are the same game: same score, same length, same team lines. The full logs are the same line for line, apart from
`anim_cradle` replacing `anim_dunk_windmill` in the 2 Fathers games, which is drawing only (P12-10b's cradle frames).
So the Phase 11 numbers and these come from the same simulation. The gap is sampling noise, and Phase 11's
Grandfathers sample was probably on the high side. The best estimate is both samples together (last column).

Their moves fire as in Phase 11 (per game the team played, gym vs crews, 80 games; Phase 11 in brackets): hook 5.35
(5.07), finger roll 4.66 (4.64), outlet 4.49 (3.59); fadeaway 8.94 (9.23), cradle 2.44 (2.30), shoulder 2.11 (2.26);
step-back 3.58 (3.49), coast-to-coast 2.75 (2.52), lob magnet 0.95 (0.71).

## The New Generation's signature moves

Only three of the six are in the era team (the finale three). **Hesitation (Glitch), swat (Firewall) and rim run (Long
Shadow) can never fire in an era team game**, and neither can Glitch's `combo` frames (only his sheet carries them):
`anim_combo` was 0 in all 1,460 games. Phase 11 noted the same for euro-step, pop and steal break. So that the three
were not left untested, cell S gave a crew those moves with `--signature` against the New Generation.

Per game, the New Generation side (1,200 games, cells A to F):

| Move | Per game | Range over cells | Notes |
|---|---|---|---|
| top gear (Overclock) | **119** sprint starts | 96 (NEON DOME) - 135 | about 3,100-3,900 frames of top gear a game; fewer on NEON DOME because the games are shorter (8.0 vs 9.5 min) |
| putback (Updraft) | **0.80** | 0.73 - 0.91 | 0.45 dunks + 0.34 tips; 0.78 taken above everyone's reach; 45% of games had none, 1 game had 5 |
| hot hand (Halfcourt) | **0.97** fires | 0.91 - 1.02 | the New Generation got 2.22 fires a game against 1.68 for their opponents |

**Putbacks**: P12-17's challenge games gave about 0.25 a game. In era team games it is **0.80 a game**, about three
times as many. The difference is that here Updraft plays every possession at average 50 next to Overclock, and his CPU
crashes the rim on every miss (68 crash frames a game). Still, it is about one a game, and nearly half the games have
none. It is a small move, not a broken one. The team's putbacks overall (any player, `putbacks_t`) are 1.91 a game against
about 1.5-1.7 for their opponents.

Cell S (20 games, `44c7ca3`, the moves on the Kings / Runners side, per game): **rim run 35.9** windows (6,137 frames),
**hesitation 4.2** freezes (61 frames frozen), **swat 1.8** tries, all 36 of 36 blocked, 15 of them blocked only
because of the swat. All three fire. In these games the New Generation side played as usual (top gear 184, putback 0.65,
hot hand 1.00).

Swat note: every try printed `chance 1.00, was 0.67` or `was 0.72`. `SWAT_BLOCK_MULT` 1.5 times today's 0.67-0.72
jumper block chance always reaches the 1.0 cap, so on Hard **every swat try is a sure block**. It fires only about 2 times
a game, so the edge is small, but no roll is left. This is not filed as a bug: P12-17 meant "x1.5, at most 1".
A proposal is below.

## Game stats (mean, range)

| Cell | Games | Length (min) | Shots | FG% | Loser pts | Fouls | OOB | Interceptions (SE) | Shot clock | OREB | Side switches != 1 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| A. NG vs crews, gym | 200 | 9.5 (6.0-12.7) | 61.0 (40-86) | 52.9% | 16.5 (8-20) | 1.93 (0-5) | 1.19 (0-4) | 2.90 (0.12) | 0 | 25.7% | 0 |
| B. NG vs crews, NEON DOME | 200 | 8.0 (5.0-10.9) | 56.3 (35-74) | 56.7% | 16.1 (7-20) | 1.78 (0-5) | 0.95 (0-6) | 2.61 (0.11) | 0 | 26.9% | 0 |
| C. NG vs Fathers, gym | 200 | 9.0 (5.5-13.2) | 61.8 (41-85) | 52.3% | 16.6 (6-20) | 1.52 (0-6) | 1.16 (0-5) | 2.42 (0.12) | 0 | 25.7% | 0 |
| D. NG vs Present, gym | 200 | 9.0 (4.8-12.7) | 60.9 (38-90) | 52.2% | 16.7 (8-20) | 1.68 (0-6) | 1.06 (0-5) | 2.44 (0.11) | 0 | 26.4% | 0 |
| E. GF vs NG, OLD GYM | 200 | 10.1 (6.9-14.7) | 62.7 (41-89) | 54.4% | 16.4 (7-20) | 1.10 (0-5) | 1.12 (0-4) | 3.10 (0.12) | 0 | 24.6% | 0 |
| F. GF vs NG, NEON DOME | 200 | 8.0 (5.4-12.2) | 57.1 (40-84) | 57.0% | 16.4 (8-20) | 1.59 (0-6) | 0.99 (0-5) | 2.37 (0.12) | 0 | 25.2% | 0 |
| G. Grandfathers vs crews | 80 | 9.7 (7.2-12.4) | 62.7 (47-84) | 52.7% | 16.6 (8-20) | 2.17 (0-7) | 1.11 (0-4) | 2.88 (0.19) | 0 | 24.5% | 0 |
| G. Fathers vs crews | 80 | 9.3 (6.0-12.6) | 61.3 (39-81) | 53.0% | 16.4 (10-20) | 1.75 (0-6) | 1.10 (0-5) | 2.69 (0.17) | 0 | 25.6% | 0 |
| G. Present vs crews | 80 | 9.3 (6.2-12.9) | 61.9 (47-85) | 51.9% | 16.8 (6-20) | 1.91 (0-6) | 1.18 (0-4) | 2.70 (0.19) | 0 | 23.8% | 0 |
| S. signature crews vs NG | 20 | 8.6 (6.5-11.3) | 62.5 (47-82) | 51.8% | 16.4 (9-20) | 2.20 (0-4) | 1.35 (0-4) | 2.65 (0.37) | 0 | 25.9% | 0 |

All means are inside the CLAUDE.md bands (55-90 shots at about 50%, 7-11 min, loser 12-20, 1-5 fouls, 1-2 OOB, OREB
about 25%, one side switch every game). NEON DOME games are about 1.5 min shorter with fewer shots at a higher FG%, as
FAST BREAK means (P12-21 measured 8.98 vs 9.73 min for the Kings vs Runners). OLD GYM has the fewest fouls (`foul_mult`
0.6) and is the slowest (10.1 min). Interceptions are 2.4-3.1 a game everywhere, in line with Phase 11's 2.98 baseline.

## Team play (per game, the era team | its opponents)

| Cell | Shots | FG% | 3PA | 3P% | Jumpers | Layups | Dunk tries | Steals | Blocks |
|---|---|---|---|---|---|---|---|---|---|
| A. New Generation, gym | 30.9 | 52.2% | 7.0 | 39.4% | 16.1 | 8.1 | 6.6 | 4.6 | 3.4 |
| crews | 30.1 | 53.7% | 5.7 | 37.5% | 14.2 | 9.0 | 6.9 | 4.4 | 3.8 |
| B. New Generation, NEON DOME | 28.7 | 57.1% | 6.2 | 46.3% | 15.4 | 7.8 | 5.5 | 4.1 | 3.1 |
| crews | 27.7 | 56.2% | 5.2 | 40.3% | 13.2 | 8.8 | 5.8 | 3.7 | 3.2 |
| C. New Generation | 30.9 | 54.0% | 6.5 | 40.4% | 15.8 | 8.4 | 6.7 | 3.8 | 3.8 |
| Fathers | 30.9 | 50.7% | 6.5 | 40.1% | 21.0 | 5.1 | 4.9 | 3.7 | 3.7 |
| D. New Generation | 30.5 | 53.6% | 6.8 | 40.2% | 16.1 | 8.0 | 6.4 | 3.8 | 3.5 |
| Present | 30.5 | 50.9% | 8.1 | 38.5% | 18.2 | 6.3 | 6.0 | 4.2 | 3.5 |
| E. New Generation, OLD GYM | 31.7 | 54.8% | 5.8 | 31.0% | 16.1 | 8.7 | 6.9 | 4.7 | 3.4 |
| Grandfathers | 30.9 | 53.9% | 4.1 | 31.6% | 16.9 | 8.5 | 5.6 | 4.6 | 3.6 |
| F. New Generation, NEON DOME | 28.7 | 56.9% | 5.9 | 45.0% | 15.2 | 7.9 | 5.6 | 3.8 | 3.0 |
| Grandfathers | 28.4 | 57.0% | 4.7 | 44.2% | 15.9 | 7.9 | 4.6 | 3.6 | 3.1 |

Where the edge comes from: a bit more of everything rather than one big weapon. Halfcourt's 75 shooting gives the
most threes after the Present (6-7 a game) and the hot hand; Overclock's 75 speed and top gear give the most dunk tries
and steals (4.6 vs the crews); Updraft's putbacks give more second-chance points.

## Checks

| Check | Result |
|---|---|
| Import, no script errors | PASS (all copies; 1,460 games + 7 A/B + 2 humantests + shots: no SCRIPT ERROR; the only ERROR line is ALSA under xvfb, no sound card) |
| Every game ends, no stuck ball or players, no shot-clock violations | PASS (1,460 / 1,460 FINAL, exit 0, 0 violations, one switch every game) |
| Stats in the CLAUDE.md bands | PASS (every cell) |
| New Generation vs crews about 50%, gym | PASS (54.5%, 1.3 SE) |
| New Generation vs crews, NEON DOME | **LEAN** (58.5%, 2.4 SE over 50), a home edge |
| New Generation vs each era team about even | Present 55.5% (1.6 SE) and Grandfathers on NEON DOME 54.0% (1.1 SE): PASS; **Fathers 60.5% (3.0 SE) and Grandfathers on OLD GYM 59.0% (2.6 SE): LEAN** |
| Signature moves fire | PASS for top gear, putback, hot hand in era games; hesitation, swat, rim run only through `--signature` (not in the era team); `anim_combo` never (not in the era team) |
| Perks never in Quick Game | PASS (no PERK line in any era game) |
| Other three era teams unchanged since Phase 11 | PASS (6 seeded games the same as on `c8e33ef`; the 80-game shares are within 0.6-2.4 SE, see above) |
| Humantest | PASS, see below |
| Screenshots 1280x720 | PASS, see below |

Humantests (`96bb720`, scripted human BLUE, Hard): New Generation vs Kings on NEON DOME 21-16 (5:31, 46 shots, 4
fouls, FT 1/1, 6 interceptions, the FAST BREAK twist line "early shots 20/29, later 14/15", top gear 154, hot hand 1);
Grandfathers vs New Generation on OLD GYM 21-15 (6:55, 59 shots, 2 fouls, 8 interceptions, hook 2, outlet 3, the CPU
New Generation's top gear 133, hot hand 1). Both ended normally with one side switch. The scripted human's passes get
picked off more than the CPU's (Phase 11's humantests had 2 and 4); that is the script, not the era teams.

Screenshots (`--shots`, xvfb, `96bb720`, New Generation vs Grandfathers on NEON DOME, frames 240 / 900 / 1800): the HUD
names both era teams in full and fits ("THE NEW GENERATION >> 0 - 0 THE GRANDFATHERS"). The FAST BREAK banner (icon,
name, line) sits under the top bar. The lime-and-black New Generation kit reads apart from the Grandfathers' maroon and
cream. The joystick, PASS / SHOOT and the pause button stay clear of the play.

## Bugs

None filed. The swat note above is a tuning question, not a bug.

## Suggested changes (proposals for the owner and lead; nothing applied)

1. **New Generation strength: leave it** (my pick). 54.5% against the crews on the gym is milder than the Present's
   Phase 11 61.7%, which the owner kept, and the New Generation is the last era team to open. If the owner wants it
   even, the options are the same as Phase 11's: a per-era Quick Game average below 50 (a new row key in
   `era_teams.gd`, a programmer task) or another `ERA_PICK`.
2. **NEON DOME home edge** (58.5%): leave it. It comes from FAST BREAK, whose numbers the owner just set, and Chapter 4's
   challenges are tuned on them.
3. **Grandfathers on OLD GYM** (41% vs the New Generation, 37.5% vs the crews in Phase 11): the same as Phase 11's
   point 2. Don't touch `era_grand`; if the owner wants a home edge, make it a Quick Game-only change.
4. **Swat**: `player.gd` `SWAT_BLOCK_MULT` 1.5 -> **1.3** would turn today's 0.67 / 0.72 into 0.87 / 0.94, so a swat try
   is a near-sure block but not a sure one. It only matters in Chapter 4 challenges and drafted-Firewall trip games
   (not in Quick Game). Re-run the Firewall `--challenge` rows (P12-23) if it changes. A lead / owner call; it can also
   stay as built.
5. **Putbacks** (0.8 a game here, 0.25 in the challenges): no change. It fires about once a game and is visible.

## Watch items

- The Phase 11 vs Phase 12 gap for the Grandfathers vs crews (56.7% vs 40.0%) is noise, since the simulation is the same
  game for game. The pooled 50% is the number to quote. If anyone quotes "the Grandfathers about 57% on the gym", it
  should be about 50%.
- Hesitation, swat and rim run never play in Quick Game, so the owner sees them only in Chapter 4 challenges or with a
  drafted Glitch / Firewall / Long Shadow on a trip.
