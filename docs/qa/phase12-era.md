# P12-21 QA: the FAST BREAK era rules (twist `era_next`)

Build tested: branch `ccr-f5c087b2-3ojk5f` at `a289122` (P12-12 merged; P12-17's signature moves not merged, which
does not matter here: `--autoplay` plays crews, not legends). Godot 4.3.stable, headless, `--fixed-fps 60`. Era values
under test (twists.gd): `speed_mult` 1.05, `stamina_refill_mult` 1.15, `dead_ball_mult` 0.6, `break_mult` 1.10 (main.gd
`BREAK_WINDOW` 5.0 s).

Method as in `docs/qa/phase11-era.md`: every game `--autoplay` (Hard vs Hard, the default Cornfield Kings vs Bridge
Runners, RED style "inside"), first to 21, random first ball, one process per game with its own fresh
`XDG_DATA_HOME`, in two scratch project copies outside the repo (own `config/name`), at most two Godot processes at a
time, the sets interleaved game by game.

Measuring aid, in the scratch copies only (stat counters, no sim change, no random number): the same early / later
split as P12-12's TWIST line (`in_break_window()` at the release), but counted **in every set**, twist none too (the
game counts it only under the twist), plus each shot's make odds at the release, its distance, rim move or not, and
how the team got the ball (offensive rebound, defensive rebound, other = inbound, steal, loose ball).

Candidates: extra twist rows in the scratch copies' twists.gd (copies of `era_next` with other numbers, same name,
banner and icon). **twists.gd in the repo is not changed.**

## Runs

| Set | Twist values (speed / refill / dead ball / break) | Games |
|---|---|---|
| none | `--twist none` | 200 |
| era | `--twist era_next` as built: 1.05 / 1.15 / 0.6 / 1.10 | 200 |
| c1 | 1.05 / 1.15 / 0.6 / **1.20** | 60 |
| c2 | 1.05 / 1.15 / 0.6 / **1.30** | 60 |
| c3 | **1.08** / 1.15 / 0.6 / **1.20** | 60 |
| c4 | **1.08** / 1.15 / 0.6 / **1.30** | 40 |
| c5 | **1.08** / 1.15 / 0.6 / **1.45** | 40 |
| humantest | `--humantest --twist era_next`, and the same plus `--court era_next` | 2 |

All 660 autoplay games ended (first to 21, win by 1), exit 0. No script errors, crashes, stuck players or balls,
unfinished games, and no shot-clock violations in any set. `--import`: clean (no errors, no warnings).
`--twisttest`: TWISTTEST OK (`era_next` speed_mult 1.05, stamina_refill_mult 1.15, dead_ball_mult 0.6, break_mult 1.1).

## Stats (mean, range)

| | none (200) | era (200) | c1 (60) | c2 (60) | c3 (60) | c4 (40) | c5 (40) |
|---|---|---|---|---|---|---|---|
| **GAME LENGTH, min** | **9.73** (5.8-13.8) | **8.98** (5.6-14.4) | 8.94 (6.9-11.5) | 8.52 (6.0-11.2) | 8.48 (5.7-11.4) | **8.62** (5.4-11.4) | 8.17 (5.2-11.4) |
| seconds per possession | 9.16 | 8.68 | 8.64 | 8.56 | 8.55 | 8.46 | 8.45 |
| possessions | 63.7 (44-91) | 62.1 (37-100) | 62.1 | 59.8 | 59.5 | 61.2 | 58.0 |
| shots | 60.7 (39-89) | 58.9 (35-94) | 59.8 (46-82) | 56.3 (40-77) | 57.0 (38-72) | 58.3 (41-77) | 55.0 (37-76) |
| FG % (pooled) | 54.1 | 55.8 | 55.5 | 58.3 | 57.7 | 56.2 | 59.3 |
| **early shots, % of shots** | 30.0 | 31.5 | 32.9 | 32.6 | 33.6 | 34.2 | 33.5 |
| early shots a game | 17.5 | 17.9 | 18.9 | 17.6 | 18.5 | 19.2 | 17.8 |
| **early make %** | **52.5** | **57.4** | 58.2 | 64.4 | 61.3 | **63.8** | 67.2 |
| **later make %** | **57.8** | **58.1** | 57.5 | 58.8 | 59.0 | **55.4** | 58.4 |
| **early minus later** | **-5.3** | **-0.7** | +0.7 | +5.6 | +2.3 | **+8.4** | +8.8 |
| early / later make odds at the release, % | 55.7 / 63.0 | 60.5 / 63.2 | 63.8 / 62.6 | 68.4 / 63.6 | 66.0 / 63.5 | 68.0 / 62.8 | 72.2 / 64.4 |
| early / later shot distance, ft | 15.7 / 11.0 | 15.6 / 10.8 | 15.8 / 10.9 | 15.8 / 10.6 | 15.3 / 10.6 | 15.6 / 10.6 | 16.1 / 10.2 |
| early / later at the rim (layup, dunk), % | 36.7 / 59.3 | 36.8 / 59.9 | 34.8 / 58.1 | 34.1 / 60.8 | 37.4 / 60.1 | 36.7 / 60.2 | 33.3 / 61.9 |
| loser's score | 16.6 (6-20) | 16.7 (9-20) | 16.8 (8-20) | 16.3 (9-20) | 16.3 (9-20) | 16.6 (8-20) | 16.6 (7-20) |
| fouls | 2.06 (0-7) | 2.16 (0-8) | 1.93 (0-7) | 1.45 (0-4) | 1.82 (0-5) | 2.27 (0-5) | 1.93 (0-4) |
| free throws attempted | 1.49 (0-5) | 1.41 (0-7) | 1.23 | 0.90 | 1.30 | 1.38 | 1.25 |
| offensive rebounds, % of misses | 25.4 | 24.8 | 25.1 | 25.4 | 25.4 | 27.5 | 26.6 |
| putbacks a game | 4.80 | 4.73 | 5.13 | 4.32 | 4.72 | 5.25 | 4.22 |
| out of bounds | 0.98 (0-4) | 1.18 (0-4) | 0.95 | 0.93 | 1.07 | 0.90 | 0.90 |
| interceptions | 2.92 (0-8) | 3.06 (0-11) | 2.85 | 2.88 | 2.85 | 2.95 | 2.83 |
| steals | 9.26 | 8.74 | 8.05 | 7.98 | 7.35 | 8.85 | 7.97 |
| shot-clock violations | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| side switches | 1 every game | 1 | 1 | 1 | 1 | 1 | 1 |
| **dead-ball seconds** | **35.3** (23-43) | **22.0** (16-27) | 22.0 | 21.7 | 21.8 | 21.9 | 21.7 |
| three attempts | 11.0 | 10.6 | 10.7 | 9.8 | 9.6 | 10.2 | 9.4 |
| dunks / layups a game | 14.9 / 18.2 | 13.8 / 18.3 | 13.8 / 17.6 | 13.5 / 16.9 | 12.8 / 18.1 | 12.8 / 18.7 | 12.8 / 16.9 |
| FG % BLUE (Kings) / RED (Runners) | 51.3 / 57.0 | 53.3 / 58.4 | 52.4 / 58.6 | 55.2 / 61.4 | 55.6 / 59.8 | 53.8 / 58.8 | 58.0 / 60.7 |
| **RED wins** | **114/200 (57.0 %)** | **94/200 (47.0 %)** | 34/60 (56.7 %) | 38/60 (63.3 %) | 29/60 (48.3 %) | 21/40 (52.5 %) | 16/40 (40.0 %) |

"Early" = released within `BREAK_WINDOW` 5 s of the shooter's team getting the ball (the shot clock restarting).
Standard errors: a game length mean about 0.10 min at 200 games, 0.2 at 40-60; a win share about 3.5 points at 200,
6.5 at 60, 8 at 40; an early make % about 1.2 points at 200 games, 1.8-2.2 at 40-60.

Band counts (CLAUDE.md typical game: 7-11 min, 55-90 shots, loser 12-20, fouls 1-5, OOB 1-2):

| | none | era | c1 | c2 | c3 | c4 | c5 |
|---|---|---|---|---|---|---|---|
| games under 7 min / over 11 | 4 / 45 | 18 / 12 | 1 / 3 | 5 / 2 | 9 / 1 | 4 / 3 | 6 / 1 |
| games under 55 shots | 52 | 62 | 17 | 25 | 23 | 14 | 20 |
| loser under 12 | 10 | 11 | 3 | 5 | 4 | 6 | 4 |
| fouls over 5 | 3 | 7 | 2 | 0 | 0 | 0 | 0 |

## Checks (era as built)

| Check | Result |
|---|---|
| Every game ends, no stuck player or ball, no errors | PASS (200/200, 660/660 with the candidates) |
| Length 7-11 min | PASS: 8.98 mean (none 9.73) |
| Shots 55-90 at about 50 % | PASS: 58.9 at 55.8 % (31 % of games under 55, none 26 %) |
| Fouls 1-5, OOB 1-2, loser 12-20 | PASS: 2.16, 1.18, 16.7 |
| OREB about 25 % | PASS: 24.8 % |
| Few interceptions, no shot-clock violations | PASS: 3.1, 0 |
| Dead balls 40 % shorter | PASS: 35.3 -> 22.0 s a game (x 0.62) |
| **The fastest pace (owner Q2)** | **WEAK**: 45 s shorter than twist none (-7.7 %, real: 5 SE), 0.5 s less per possession; SPACE THE FLOOR was 0.84 min shorter than none in Phase 11, so FAST BREAK is only about as fast as Chapter 3's era |
| **Early shots fall (owner Q2)** | **FAIL as a feel**: early 57.4 % vs later 58.1 %, no visible gap; the rule only cancels the early shots' own handicap (below) |
| Stamina back +15 % | not visible in CPU games: the CPU never ran empty in any set (`stamina_empty` 0 in all 660 games); it shows only on a human who sprints a lot (humantest: 57 and 92 empties a game) |
| Team balance | LEAN: RED 57 % with no twist vs 47 % in the era (10 points, about 2 SE), see below |
| HUD, banner, touch buttons (`--shots` on NEON DOME) | PASS |

### Why early shots do not fall more (P12-12's finding, explained)

Without any twist, early shots go in **5.3 points less** than later ones (52.5 vs 57.8 %): they are harder shots.
They come from 15.7 ft on average against 11.0 ft, and only 37 % of them are at the rim against 59 % (a defensive
rebound or a steal is followed by a pull-up jumper in transition more often than by a layup; the walk-up offence
works the ball in close). Only the offensive-rebound early shots (putbacks, about 30 % of them) are better than
average (62.5 % with no twist).

`break_mult` 1.10 adds about 4.9 points to the early shots (52.5 -> 57.4 %), which only cancels that handicap, so in
the era an early shot falls about as often as any other. Each +0.10 on `break_mult` adds about 3-4 points to the early
odds (60.5 % at 1.10, 63.8 at 1.20, 68 at 1.30, 72 at 1.45). The CPU's shoot decision reads the same odds, but that
barely grows the early share (31.5 % -> 32.6-34.2 %), so the gain is not eaten by worse shot picks.

To see early shots clearly fall (early at least 5 points over later, and about 10 over a normal game's early shot)
`break_mult` has to be about **1.30**.

### Pace

- The dead-ball cut works (-13 s a game), but dead balls are only about 6 % of the game.
- `speed_mult` 1.08 instead of 1.05 shortens a possession only about 0.1-0.2 s (c1 8.64 -> c3 8.55 s, c2 8.56 -> c4
  8.46 s). Most of the shorter games come from more makes (fewer possessions to reach 21): c2 (1.30, speed 1.05) is as
  short as c3 (1.20, speed 1.08).
- c4 (speed 1.08, break 1.30): 8.62 min, 8.46 s a possession, the shortest per possession of every set; c5 is
  shorter still (8.17 min) but only by making more shots.

### Balance between the crews

The era moves RED's (Bridge Runners, inside style) share from 57 % to 47 % over 200 games each (2 SE: a lean, not
proven). The Kings take more early shots (9.9 a game against RED's 8.0 under the era) and more of their shots are
jumpers, so a bonus on early jumpers pays them more; their FG % rises 2.0 points, RED's 1.4. The candidates do not
grow this in a clear way (c1 57 %, c2 63 %, c3 48 %, c4 52.5 %, c5 40 %, all within 1-2 SE of 50 %); c5 is the one to
watch (40 %, BLUE's FG 58 %). P12-23's challenge QA should look at it with the New Generation legends.

## Humantest (FAST BREAK)

| Run | Final | Length | Fouls | Notes |
|---|---|---|---|---|
| `--humantest --twist era_next` | BLUE 21 - RED 20 | 6:12 | 3 (shooting, 3 and-ones) | early shots 17/26, later 20/25; dead balls 23 s; stamina ran empty 57; steals timed 9/11, blocks timed 3/4 |
| `+ --court era_next` | BLUE 21 - RED 20 | 7:04 | 3 (1 shooting, 2 reach) | early shots 26/45, later 11/16; dead balls 25 s; stamina ran empty 92; steals timed 13/15 |

Both ran to the end, exit 0, no errors. The scripted human shoots early a lot (half to three quarters of the shots).

## Screenshots (xvfb, 1280 x 720, `--shots --twist era_next --court era_next`)

| Check | Result |
|---|---|
| HUD readable | PASS: top bar, score, shot clock and the pause button clear over the NEON DOME stands |
| Banner | PASS: "FAST BREAK" with its icon (ball, lime speed lines, violet chevrons), the line "Fast break: a quicker game, early shots fall" inside the banner |
| Touch buttons not covering the action | PASS: joystick bottom-left, PASS / SHOOT (SWITCH / STEAL) bottom-right, as on other courts; the lime lines and violet key read well |

## Suggested tuning (for the owner; twists.gd not changed)

Recommended: **c4**, in `scripts/twists.gd` `era_next`:
- `break_mult` 1.10 -> **1.30**
- `speed_mult` 1.05 -> **1.08**
- `stamina_refill_mult` 1.15 and `dead_ball_mult` 0.6 unchanged.

What c4 gives (40 games): games 8.62 min (1.1 min shorter than a normal game, the shortest era so far per
possession), early shots in 63.8 % against 55.4 % later (and 52.5 % for an early shot in a normal game), FG 56.2 %,
58.3 shots, fouls 2.3, OREB 27.5 %, loser 16.6, RED 52.5 %. Every number inside CLAUDE.md's bands. 40 games is a small
sample: the pooled 1.30 sets (c2 + c4, 100 games) give early 64.1 % against later 57.4 % (+6.7).

Not recommended:
- c5 (`break_mult` 1.45): early shots fall even more (+8.8) and games are shortest (8.17 min), but FG goes to 59 %,
  half the games end under 55 shots and RED dropped to 40 %.
- c1 / c3 (`break_mult` 1.20): early shots still only +0.7 / +2.3 over later; not "clearly".
- Keeping 1.10: an early shot falls exactly like any other; the owner will not see it.

If the owner wants an even faster feel without more makes, numbers in twists.gd cannot do much more: `speed_mult`
moves the possession length little. A shorter shot clock (not wanted, Q2) or a faster CPU push after a rebound would
be a code change for the lead to decide.

Proposed targets for the era (for the lead to confirm): game 8-9.5 min (about 1 min under twist none), early make %
at least 5 points over later shots, FG 54-58 %, shots 55-65, the other bands as CLAUDE.md.
