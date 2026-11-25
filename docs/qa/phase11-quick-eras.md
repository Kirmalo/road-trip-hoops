# P11-36: era team balance in Quick Game

Build tested: branch head `42bf2b6` (ccr-f5c087b2-3ojk5f after P11-35), Godot 4.3 stable, headless, `--fixed-fps 60`.
Every run used its own project copy and a fresh `XDG_DATA_HOME` (no owner file touched), at most 2 Godot processes.
Flags on every game: `--autoplay --no-countdown --difficulty hard --legends-unlock-all --unlock-all`, plus
`--quick-teams <blue>,<red>` and `--court gym` (or the era's own look).

Era teams as built (`EraTeams.ERA_PICK` "finale", stats shifted to average 50, signature moves on, no perks):

| Era team | Players (spd/sht/fin/def/sta) | Crew style (as RED) |
|---|---|---|
| THE GRANDFATHERS | Steeple 35/50/70/55/40, Velvet 60/45/65/40/40, Quarterback 55/55/40/50/50 | inside |
| THE FATHERS | Rooftop 60/50/65/40/35, Midrange 50/70/50/40/40, Freight 35/35/75/60/45 | balanced |
| THE PRESENT | Deep End 55/75/40/40/40, Toolbox 55/50/55/50/40, Skylight 50/30/70/55/45 | outside |

## What ran (760 games, all ended with `FINAL`, exit 0, no script errors)
| Set | Games | Notes |
|---|---|---|
| Baseline Kings vs Bridge Runners, gym | 60 | 30 each side |
| Each era team vs Kings, Runners, Concrete Crowns (balanced), Riverside Soul (inside), gym | 120 x 3 | 30 per crew, half as BLUE, half as RED |
| Each era team on its own era court (twist on) vs Kings and Runners | 80 / 40 / 40 | Grandfathers got 40 extra to confirm a lean |
| Era vs era, gym | 60 x 3 pairs | half each side |

This is fewer than the board's 200+ per era and 100+ per pair: the owner asked for fewer jobs, the machine was shared
(about 1-2 games a minute) and it rebooted once mid-run (the runner picked up where it stopped). 120 games give an SE
of about 4.5 points, which is enough to see which era teams sit near 50% and which don't.

## Win shares (SE = sqrt(p(1-p)/n))
| Era team | Gym vs crews | as BLUE | as RED | Own era court (twist) |
|---|---|---|---|---|
| Grandfathers | **56.7%** (68/120, SE 4.5) | 58.3% | 55.0% | **37.5%** (30/80, SE 5.4), OLD SCHOOL |
| Fathers | **48.3%** (58/120, SE 4.6) | 50.0% | 46.7% | 47.5% (19/40, SE 7.9), ISO BALL |
| Present | **61.7%** (74/120, SE 4.4) | 63.3% | 60.0% | 55.0% (22/40, SE 7.9), SPACE THE FLOOR |
| All three | 55.6% (200/360, SE 2.6) | | | |

Per opponent (gym, 30 games each):

| Era team | Kings | Runners | Concrete Crowns | Riverside Soul |
|---|---|---|---|---|
| Grandfathers | 83.3% | 63.3% | 43.3% | 36.7% |
| Fathers | 63.3% | 40.0% | 43.3% | 46.7% |
| Present | 70.0% | 63.3% | 56.7% | 56.7% |

Era vs era (gym, 60 each): Present over Fathers **63.3%** (SE 6.2); Present over Grandfathers 56.7% (SE 6.4);
Fathers over Grandfathers 56.7% (SE 6.4). Order: Present > Fathers ~ Grandfathers.

Baseline: Kings 48.3% vs Runners (29/60, SE 6.5). The BLUE side won 21/60 (35%, SE 6.2); see the watch items.

## Game stats (mean, range)
| Set | Games | Length (min) | Shots | FG% | Loser pts | Fouls | OOB | Interceptions | Shot clock | OREB | Side switches != 1 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Baseline | 60 | 9.6 (7.1-13.6) | 61.0 (41-84) | 52.0% | 16.1 (7-20) | 2.10 (0-6) | 1.05 (0-4) | **2.98 (0-9), SE 0.24** | 0 | 26.6% | 0 |
| Grandfathers gym | 120 | 9.6 (5.7-14.0) | 62.2 (38-88) | 52.7% | 16.6 (7-20) | 2.00 (0-6) | 1.19 (0-6) | 2.74 (0-8) | 0 | 25.1% | 0 |
| Fathers gym | 120 | 9.7 (6.4-13.2) | 63.5 (43-86) | 51.6% | 16.8 (10-20) | 1.86 (0-6) | 1.05 (0-4) | 2.51 (0-8) | 0 | 23.5% | 0 |
| Present gym | 120 | 9.2 (6.2-13.4) | 60.7 (39-86) | 51.2% | 15.8 (8-20) | 1.87 (0-6) | 1.16 (0-4) | 2.85 (0-13) | 0 | 24.1% | 0 |
| Grandfathers OLD GYM | 80 | 10.5 (7.9-13.6) | 63.1 (47-83) | 55.3% | 17.0 (11-20) | 1.14 (0-4) | 1.07 (0-4) | 3.14 (0-9) | 0 | 23.9% | 0 |
| Fathers NIGHT PARK | 40 | 9.2 (7.4-12.1) | 61.2 (47-79) | 53.3% | 16.5 (10-20) | 1.55 (0-5) | 1.02 (0-2) | 2.55 (0-6) | 0 | 24.5% | 0 |
| Present BIG STAGE | 40 | 8.4 (5.9-13.2) | 57.7 (41-91) | 49.8% | 15.6 (10-20) | 1.45 (0-5) | 0.93 (0-3) | 2.17 (0-9) | 0 | 22.3% | 0 |
| Era vs era | 180 | 9.1 (5.3-13.3) | 61.7 (37-95) | 52.0% | 16.2 (7-20) | 1.66 (0-8) | 1.14 (0-6) | 2.55 (0-7) | 0 | 26.3% | 0 |

All means are inside the CLAUDE.md bands (55-90 shots at about 50%, 7-11 min, loser 12-20, 1-5 fouls, 1-2 OOB, OREB
about 25%, one side switch). OLD GYM has fewer fouls (foul_mult 0.6) and runs longer (speed 0.94), as meant.

**Interceptions** (the P11-27 question): the Kings vs Runners baseline is **2.98 a game (SE 0.24, 60 games)**. That
matches Phase 10's Quick Game numbers (P10-21 era report 2.8-3.3, P10-30 2.8 / 3.5). The 1.6 in P10-27 was a 5-game
sample on the low side, and P11-27's 3.4 is normal. Nothing changed; no bug.

## Signature moves (per game the era team played, 280-320 games each)
| Era | Moves per game |
|---|---|
| Grandfathers | hook 5.07 (escapes 0.43), finger roll 4.64, outlet 3.59 (1.78 caught) |
| Fathers | fadeaway 9.23, cradle 2.30, shoulder 2.26 (holds 1.62, escapes 0.35) |
| Present | step-back 3.49 (2.63 eased), coast-to-coast 2.52, lob magnet 0.71 (0.23 far catches) |

Animations seen: `anim_hook` 1,488, `anim_fadeaway` 2,590, `anim_stepback` 978. Every signature move of the 9 players
fired. (Euro-step, pop and steal break are on legends who are not in the finale three, so they never play here.)

## Team play (gym, era team vs its opponents, per game)
| | Shots | FG% | 3PA | 3P% | Jumpers | Layups | Dunk tries | Steals | Blocks |
|---|---|---|---|---|---|---|---|---|---|
| Grandfathers | 31.2 | 53.3% | 5.7 | 38.1% | 17.1 | 8.4 | 5.7 | 4.6 | 3.8 |
| their opponents | 31.0 | 52.1% | 6.3 | 36.0% | 15.5 | 8.7 | 6.9 | 4.5 | 3.7 |
| Fathers | 32.0 | 51.0% | 6.6 | 37.8% | 21.9 | 5.2 | 4.9 | 4.2 | 3.8 |
| their opponents | 31.5 | 52.2% | 6.2 | 36.0% | 15.3 | 9.1 | 7.2 | 4.2 | 3.8 |
| Present | 31.0 | 50.8% | **8.8** | 38.9% | 18.9 | 6.2 | 5.9 | **4.4** | 4.2 |
| their opponents | 29.7 | 51.6% | 5.7 | 39.1% | 14.4 | 8.5 | 6.9 | 3.5 | 3.5 |

On OLD GYM (80 games): Grandfathers 53.1% FG, 4.6 3PA at 32.1%, 5.4 dunk tries; their opponents **57.5%** FG, 7.5
dunk tries, 4.2 blocks.

## Checks
| Check | Result |
|---|---|
| Import, no script errors | PASS (both copies; 760 games, 2 humantests, 2 shot runs: no SCRIPT ERROR) |
| Every game ends, no stuck ball or players, no shot-clock violations | PASS (760 / 760 FINAL, 0 violations, one switch every game) |
| Stats in the CLAUDE.md bands | PASS (every set, table above) |
| Grandfathers about 50% on the gym | PASS (56.7%, 1.5 SE) |
| Fathers about 50% on the gym | PASS (48.3%, 0.4 SE) |
| Present about 50% on the gym | **LEAN** (61.7%, 2.7 SE over 50) |
| Each era on its own court about 50% | Fathers PASS (47.5%), Present PASS (55.0%), **Grandfathers LEAN** (37.5%, 2.3 SE under 50) |
| Era vs era about even | Present over Fathers 63.3% (2.2 SE): lean; the other two pairs within 1.1 SE |
| Signature moves fire, perks never | PASS (every move of the nine; no PERK line in any era game) |
| Interceptions "few" | PASS (2.2-3.1 a game in every set; baseline 2.98) |
| Humantest | PASS, see below |
| Screenshots 1280x720 | PASS, see below |

Humantests (scripted human, BLUE, Hard): Present vs Kings on BIG STAGE 21-16 (5:54, 49 shots, 0 fouls, 2
interceptions, twist line "long shots 5/11, pull-ups off a cross 2/3"); Grandfathers vs Runners on the gym 20-21
(8:03, 61 shots, 5 fouls, FT 1/2, 4 interceptions). Both ended normally, one side switch each.

Screenshots (`--shots`, xvfb): Present vs Fathers on BIG STAGE and Kings vs Grandfathers on OLD GYM. The HUD names
the era teams in full and fits ("THE PRESENT >> 0 - 0 THE FATHERS"); the OLD SCHOOL banner shows at tip-off under the
top bar; the joystick, PASS / SHOOT and the pause button stay clear of the play; the two era kits read apart from each
other.

## Bugs
None found.

## Why the leans
- **Present +12 on the gym (and over the Fathers).** The outside style and Deep End's 75 shooting give them 8.8 threes
  a game against 5.7-6.6 for everyone else, at the same 39% (about +3.5 points a game from threes alone). Deep End's
  step-back (3.5 a game, odds x1.12) adds to it. They also steal a bit more (4.4 vs 3.5). The lean holds as BLUE
  (63%), where no crew style applies, so it is mostly the shape (one 75 shooter) plus the step-back, not the style.
- **Grandfathers 57% on the gym but 37.5% on OLD GYM.** OLD SCHOOL's `inside_mult` 1.08 helps whoever goes inside
  most: on OLD GYM their opponents shoot 57.5% (52.1% on the gym) with 7.5 dunk tries, while the Grandfathers stay at
  53% (Steeple's hooks and Velvet's finger rolls already beat contests, so the +8% adds less for them). The slower
  floor (`speed_mult` 0.94) also hurts Steeple (speed 35) on defense. Only Kings and Runners were tested there.
- **Kings are the soft opponent** (all three eras 63-83% against them); Riverside Soul and Concrete Crowns are the
  hard ones for the Grandfathers. That is the crews' shapes, not the era teams.

## Suggested changes (for the owner and lead; nothing applied)
1. Present: the board allows only `ERA_PICK` or the average to change, both with the owner's yes. Options:
   a) leave it (61.7% is the strongest Quick Game team, a fair reward for opening the last era);
   b) a per-era Quick Game average below 50 for the Present (e.g. 48; needs a new constant or row key in
   `era_teams.gd`, a code change, so a programmer task);
   c) a different three (e.g. `ERA_PICK` "shape", or the owner names three without Deep End). I'd take a) unless
   the owner wants all three eras even.
2. Grandfathers on OLD GYM: don't touch `Twists` `era_grand` (`inside_mult`, `speed_mult`): Chapter 1's challenges
   were tuned on them (P9-17, P9-26). Leave it, and mention it in the docs as "the old gym doesn't favor them". If
   the owner wants a home edge, it would be a Quick Game-only change (a programmer task), not a twist number.
3. Era vs era: no change on its own; it follows from point 1.

## Watch items
- The baseline BLUE side won 21/60 (35%, SE 6.2). Phase 10 had 16/40 (40%). The era games show no side effect
  (era team 58/55/63% as BLUE vs 55/47/60% as RED), so this may be chance, but in Quick Game only RED gets its crew
  style, so worth a 200-game look in P11-30: Kings vs Runners, both orders.
- One Present gym game had 13 interceptions (the most in 760). A single outlier; the Present's mean is 2.85.
