# P11-21 QA: the SPACE THE FLOOR era rules (twist `era_present`)

Build tested: branch `ccr-f5c087b2-3ojk5f` at `b0b362d` (P11-12 and P11-18 merged). Godot 4.3.stable, headless,
`--fixed-fps 60`. Era values under test: `long_shot_mult` 1.08, `spacing_ft` 2.0, `pullup_mult` 1.10 (twists.gd);
CPU pull-up constants in player.gd: `PULLUP_CPU_CHANCE` 0.5, `PULLUP_WINDOW` 1.0, `PULLUP_CPU_DELAY` 0.3,
`PULLUP_CPU_ROOM_FT` 3.5, `PULLUP_CPU_MAX_FT` 26.

Method as in `docs/qa/phase10-era.md`: every game `--autoplay` (Hard vs Hard), first to 21, random first ball, one
process per game with its own fresh `XDG_DATA_HOME`, in two scratch project copies outside the repo (own
`config/name`), at most two Godot processes at a time, run order shuffled so the sets play interleaved.

Measuring aids, in the scratch copies only (no sim change, no random numbers):
- every frame an off-ball CPU attacker runs `offball_ai()` while a teammate holds the ball and both are in the
  frontcourt: his distance to the hoop, to the ball handler, to the nearest defender and his target's distance to
  the hoop (sums in tenths of a foot, `qa_sp_*`);
- a pull-up off a crossover beyond the arc counted apart (`qa_pu3`, `qa_pu3m`; added after the main sets, so it is
  in the style games and the candidate sets only).

Twist `none` draws no pull-up roll, so `pullups_cross` is 0 there by design (the CPU never takes the cross pull-up
without the twist).

## Runs

| Set | Flags | Games |
|---|---|---|
| none | `--twist none` (Kings vs Bridge Runners, RED "inside") | 64 |
| era | `--twist era_present` | 64 |
| era court | `--twist era_present --court era_present` | 40 |
| grand | `--twist era_grand` (Phase 10 check) | 20 |
| fathers | `--twist era_fathers` (Phase 10 check) | 20 |
| style none | `--twist none --quick-teams` 4 pairings below, 12 each | 48 |
| style era | `--twist era_present --quick-teams` the same 4 pairings, 12 each | 48 |
| cand spacing 1.0 | `--twist era_present`, scratch copy with `spacing_ft` 1.0 (the only change) | 32 |
| cand pull-up 0.3 | `--twist era_present`, scratch copy with player.gd `PULLUP_CPU_CHANCE` 0.3 (the only change) | 32 |
| humantest | `--humantest --twist era_present`, and the same plus `--court era_present` | 2 |

All 368 autoplay games ended (first to 21, win by 1) with exit 0. No script errors, crashes, stuck players or balls,
unfinished games, and no shot-clock violations in any set. `--import`: clean. `--twisttest`: TWISTTEST OK (the three
`era_present` keys listed: 1.08, 2, 1.1).

## Stats (mean, range)

| | none (64) | era (64) | era court (40) | grand (20) | fathers (20) |
|---|---|---|---|---|---|
| GAME LENGTH, min | 9.97 (7.4-14.1) | 9.13 (6.1-12.1) | 9.08 (6.1-12.7) | 11.09 (7.8-15.5) | 9.43 (7.0-11.7) |
| shots | 62.3 (47-92) | 57.9 (42-77) | 58.0 (42-78) | 63.1 (47-78) | 61.1 (40-80) |
| FG % (per game) | 54.7 (40-77) | 52.1 (40-67) | 52.1 (41-64) | 56.7 (45-69) | 54.8 (44-67) |
| possessions | 65.6 (47-94) | 61.5 (42-80) | 61.3 (38-85) | 68.4 (46-96) | 63.7 (47-84) |
| loser's score | 16.9 (3-20) | 15.6 (6-20) | 15.4 (8-20) | 17.4 (12-20) | 16.5 (9-20) |
| fouls | 2.27 (0-6) | 1.73 (0-7) | 1.62 (0-5) | 1.60 (0-4) | 2.10 (0-4) |
| free throws attempted | 1.58 (0-4) | 1.12 (0-4) | 0.93 (0-3) | 0.90 (0-3) | 1.35 (0-3) |
| offensive rebounds, % of misses | 24.8 | 21.9 | 22.7 | 24.4 | 28.1 |
| out of bounds | 1.12 (0-4) | 1.03 (0-4) | 1.15 (0-3) | 1.05 (0-3) | 0.90 (0-3) |
| interceptions | 3.4 (0-8) | 3.0 (0-8) | 2.9 (0-7) | 4.0 (0-9) | 3.1 (1-7) |
| shot-clock violations | 0 | 0 | 0 | 0 | 0 |
| side switches | 1 every game | 1 | 1 | 1 | 1 |
| three attempts | 11.0 (4-19) | 17.3 (10-29) | 16.6 (9-25) | 8.9 (4-15) | 11.1 (4-18) |
| threes made a game | 4.03 | 7.22 | 6.83 | 2.65 | 4.00 |
| three make %, pooled | 36.5 | 41.8 | 41.1 | 29.8 | 36.2 |
| **three share of shots, %** | **17.7** | **29.8** | **28.7** | 14.1 | 18.1 |
| points from threes, % of all points | 21 | 39 | 37 | 14 | 21 |
| mid jumpers a game / make % | 17.7 / 48.2 | 16.8 / 50.7 | 17.4 / 52.3 | 20.6 / 50.1 | 17.3 / 52.0 |
| layups a game / make % | 17.7 / 62.5 | 13.8 / 62.5 | 13.2 / 64.3 | 18.0 / 66.9 | 16.4 / 61.9 |
| dunks a game / make % | 15.9 / 72.7 | 10.0 / 72.5 | 10.8 / 69.1 | 15.7 / 75.4 | 16.3 / 69.3 |
| rim attempts (layups + dunks) a game | 33.6 | 23.8 | 24.0 | 33.7 | 32.7 |
| crossovers a game | 26.1 | 22.8 | 23.9 | 31.1 | 24.5 |
| **pull-ups off a crossover a game / make %** | 0 | **9.3 / 55.1** | **9.9 / 54.3** | 0 | 0 |
| ... of them the CPU's new cross pull-up roll | 0 | 6.2 | 6.6 | 0 | 0 |
| other CPU pull-ups (the old `pullups` rule) a game | 12.1 | 8.6 | 8.3 | 14.6 | 11.8 |
| CPU catch-and-shoot threes (`cpu_threes`) a game | 11.5 | 15.9 | 15.2 | 9.1 | 11.6 |
| **off-ball attacker: distance to the hoop, ft** | **20.18** | **21.75** | **21.72** | 19.96 | 20.40 |
| off-ball attacker's spot (target) to the hoop, ft | 19.22 | 20.95 | 20.94 | 19.17 | 19.37 |
| off-ball attacker: distance to the ball handler, ft | 17.14 | 17.35 | 17.67 | 17.10 | 17.27 |
| off-ball attacker: distance to the nearest defender, ft | 5.58 | 5.73 | 5.80 | 5.56 | 5.61 |
| RED wins | 37/64 (58 %) | 29/64 (45 %) | 20/40 (50 %) | 16/20 (80 %) | 11/20 (55 %) |

(Points: in 1s and 2s a three is worth 2, everything else 1; "points from threes" = 2 x threes made over both teams'
points.) Standard error of a win share: about 6 points at 64 games, 8 at 40, 11 at 20. The era court only changes the
drawing, so era and era court are the same rules; their gaps are noise. Pooled era (104 games): 9.11 min, 57.9 shots,
RED 49/104 (47 %).

Bands (CLAUDE.md typical game): length 7-11 min (era mean 9.1; 4 of 64 under 7 and 4 over 11, twist none 0 and 12),
shots 55-90 at about 50 % (57.9 at 52 %; under 55 in 25 of 64 era games vs 15 of 64 with twist none: fewer shots are
needed to reach 21 when more of them are worth 2), fouls 1-5 (1.7, one game had 7), OOB 1-2 (1.0), loser 12-20 (15.6;
5 of 64 under 12, none 3),
OREB about 25 % (21.9 %, see below), few interceptions (3.0). All PASS; OREB a little low and explained.

## Each rule: noticeable?

| Rule (owner P2 a) | none | era | Change | Verdict |
|---|---|---|---|---|
| Shots beyond the arc +8 % | 36.5 % | 41.8 % | x 1.15 | PASS, strongly noticeable |
| Three attempts | 11.0 a game | 17.3 | +57 % | the share of shots from beyond the arc 17.7 -> 29.8 % |
| Threes made | 4.0 a game | 7.2 | +3.2 | about 3 more "2 points" threes a game; 39 % of all points |
| Off-ball players 2 ft wider | 20.2 ft from the hoop | 21.8 | +1.6 ft (their spots +1.7) | PASS for the distance; little extra room (see below) |
| Jumper right after a crossover or spin +10 % | not rolled | 9.3 a game at 55 % | new | PASS, about 9 pull-ups a game |

Threes: the make % grows more than 8 % (x 1.15) because a pull-up three gets both multipliers (1.08 x 1.10 = 1.19)
and because the spacing leaves the catch-and-shoot threes a little more open. Attempts grow mostly through the CPU's
catch-and-shoot rule (`cpu_threes` 11.5 -> 15.9 a game; its chance is x `long_shot_mult`, the rest from more open
catches) and the pull-up threes (about 3.8 a game, below).

Spacing: an off-ball attacker stands 1.6 ft further from the hoop on average (his spot 1.7 ft; the edge clamp and the
"stay out of the handler's way" rule eat the rest). It does **not** buy him much room: the distance to the ball
handler grows 0.2-0.5 ft and to the nearest defender only 0.15-0.2 ft, because man-to-man defenders follow their man
out. On screen the players stand visibly a step deeper; the floor does not look much more open.

### Is the pull-up too strong? (the lead's question)

P11-12's 8 games saw 10.4 pull-ups a game at 63 %. On 104 era games: **9.3-9.9 a game at 55 %**. The style games
(48, with the split aid) give the shape: of 496 pull-ups, 180 were threes made at 44.4 % and 316 were twos made at
57.9 %.

| Shot (era) | make % | points per shot (1s and 2s) |
|---|---|---|
| pull-up two off a crossover | 57.9 | 0.58 |
| pull-up three off a crossover | 44.4 | 0.89 |
| any three | 41.8 | 0.84 |
| mid jumper (all, inside the arc) | 50.7 | 0.51 |
| layup / dunk | 62.5 / 72.5 | 0.63 / 0.73 |

Verdict: **not too strong; no change to `PULLUP_CPU_CHANCE` 0.5 or `PULLUP_WINDOW` 1.0.**
- A pull-up two is worth less than a layup or a dunk and only a little more than any mid jumper, and the team FG %
  goes **down** in the era (54.7 -> 52.1 %). Scoring does not run away: the loser's score is 15.6, the length 9.1 min.
- The pull-up three (0.89 a shot) is the best shot in the era, but it is the three rule doing that (any three is
  0.84), and it is about 3.8 shots a game.
- The candidate with `PULLUP_CPU_CHANCE` 0.3 (32 games) cut the CPU's cross pull-up tries by a third (6.2 -> 4.2 a
  game), but the handler then took the old pull-up instead (8.6 -> 10.3 a game) and the rim attempts did not come
  back (23.8 -> 23.8). Lowering it removes some of the era's identity and buys nothing.
- The 63 % of the first 8 games was a small sample.

### Where did the rim attempts go?

The era trades rim attempts for threes: layups + dunks 33.6 -> 23.8 a game (-29 %), dunks 15.9 -> 10.0 (-37 %). It is
**not** the pull-up roll (the 0.3 candidate kept 23.8). It is mostly the spacing: with `spacing_ft` 1.0 (32 games)
the rim attempts were 25.6 and OREB 25.4 % (back in its band), threes 15.6 a game (still +41 %), share 26.5 %.
The block spots (5, +-8 ft) move out to about 11 ft, so fewer attackers stand near the rim for cuts, lobs and
putbacks (OREB 24.8 -> 21.9 %), and fewer rim attacks also mean fewer shooting fouls (2.27 -> 1.73).

## Share by crew style

`--quick-teams` pairings both ways round (the style plays only on RED): Riverside Soul (inside) vs Switchbacks
(outside), Boardwalk Bombers (inside) vs Bodega Bandits (outside), 12 games each.

| Pairing (BLUE, RED) | none: inside crew wins | era: inside crew wins |
|---|---|---|
| Switchbacks, Riverside Soul (inside RED) | 10/12 | 5/12 |
| Riverside Soul, Switchbacks (outside RED) | 6/12 | 6/12 |
| Bodega Bandits, Boardwalk Bombers (inside RED) | 5/12 | 5/12 |
| Boardwalk Bombers, Bodega Bandits (outside RED) | 5/12 | 5/12 |
| **all four** | **26/48 (54.2 %)** | **21/48 (43.8 %)** |
| plus Kings vs Bridge Runners (inside RED; none / era + era court) | 37/64 | 49/104 |
| **inside crews, every game** | **63/112 (56.3 %)** | **70/152 (46.1 %)** |

The era moves the inside crews' share down by about 10 points over every game. The standard error of that
difference is about 6.2 points, so this is 1.6 SE: a lean, not proven, and it points the expected way (an era that
pays long shots pays the shooting crews). In the style pairs, the change is all in one pairing (10/12 -> 5/12); the
other three did not move. Much smaller than the Phase 9 lesson (OLD SCHOOL gave an inside crew 68 %).

Per style (style games): inside crews 3PA 5.3 -> 8.5 a game at 36.7 -> 41.9 %, rim attempts 16.9 -> 11.6; outside
crews 3PA 7.2 -> 10.0 at 41.0 -> 46.5 %, rim 13.4 -> 9.0. Both styles take about 5 pull-ups a game at 53 %.

Style games, all four pairings together: none 9.53 min, 60.8 shots, FG 53.0 %, 3PA 12.5, fouls 2.21, OREB 25.3 %;
era 8.83 min, 57.5 shots, FG 50.9 %, 3PA 18.5 at 44.4 %, rim 20.6, fouls 1.27, OREB 22.2 %. The same picture as the
Kings vs Bridge Runners sets.

## Twists none, era_grand and era_fathers match Phase 10

| | Phase 10 (`docs/qa/phase10-era.md`) | here |
|---|---|---|
| none: length, shots, FG %, fouls, OREB, 3PA / 3P %, RED | 9.63, 61.1, 53.8, 2.30, 25.9, 11.3 / 37.4, 62 % (64) | 9.97, 62.3, 54.7, 2.27, 24.8, 11.0 / 36.5, 58 % (64) |
| era_grand | 10.65, 63.6, 55.0, 1.38, 25.6, 9.2 / 28.0, 53 % (32) | 11.09, 63.1, 56.7, 1.60, 24.4, 8.9 / 29.8, 80 % (20) |
| era_fathers | 9.56, 59.5, 56.5, 2.08, 25.4, 10.4 / 36.7, 48 % (64) | 9.43, 61.1, 54.8, 2.10, 28.1, 11.1 / 36.2, 55 % (20) |

PASS: every number within noise. OLD SCHOOL's RED 16/20 on 20 games is over the 53-67 % Phase 9-10 measured, within
about 1.5 SE (OLD SCHOOL favours the inside crew, known since Phase 9). The new hooks draw no random number and change nothing at
their defaults: twist none plays no cross pull-up and the off-ball distances are today's (20.2 ft none vs 20.0 / 20.4
in the other eras).

## Humantest (SPACE THE FLOOR)

| Run | Final | Length | Fouls | Notes |
|---|---|---|---|---|
| `--twist era_present` | BLUE 21 - RED 13 | 5:14 | 1 (shooting, and-one) | steals timed 9/10, blocks timed 2/3; long shots 2/6; pull-ups off a cross 3/3 (all BLUE, the CPU went up 0) |
| `+ --court era_present` | BLUE 21 - RED 18 | 7:06 | 2 (reach) | steals timed 11/12, blocks timed 0/1; long shots 3/5; pull-ups off a cross 0/0 |

Both ran to the end, exit 0, no errors. In both, RED never took a cross pull-up: RED crosses mostly when a CPU defender
slides with the sidestep, and against the scripted human defender it crossed once in two games. So in a real human
game the pull-up rule will show mostly on the human side's own jumpers. Two scripted games are too few to say more.

## Screenshots (xvfb, 1280 x 720, `--twist era_present --court era_present`)

| Check | Result |
|---|---|
| HUD readable (`--shots`) | PASS: top bar, shot clock, pause button clear on the BIG STAGE floor |
| Touch buttons not covering the action | PASS: joystick bottom-left, PASS / SHOOT (STEAL / SWITCH) bottom-right, as on other courts |
| Banner (`--autoplay --twistshots`) | PASS: "SPACE THE FLOOR" with its icon, the line "Threes fall, wider spacing, pull-ups off a crossover" ends at about x 855 of the banner's about x 970 |
| Pause line (`--humantest --pauseshot`) | PASS: the line wraps to two lines inside the stats panel |

Note: `--twistshots` alone (no `--autoplay`) never started a game and ran into my 600 s timeout with no images; with
`--autoplay` it works. Phase 10 used it the same way; not a bug in the game, maybe worth a line in CLAUDE.md.

## Checks

| Check | Result |
|---|---|
| Import, script errors | PASS (none in 368 games + 2 humantests + 3 screenshot runs) |
| `--twisttest` | PASS (TWISTTEST OK) |
| Threes fall more often (+8 %) | PASS: 36.5 -> 41.8 % (x 1.15 with the pull-up and spacing on top) |
| Share of shots beyond the arc | PASS, noticeable: 17.7 -> 29.8 % |
| Off-ball players 2 ft wider | PASS for the distance (+1.6 ft); weak for real room (+0.2 ft from the defender) |
| Pull-ups after a crossover or spin | PASS: 9.3 a game at 55 %; not too strong (see above) |
| Length, shots, FG %, fouls, OOB, loser in the bands | PASS |
| OREB about 25 % | explained: 21.9 % (fewer attackers near the rim) |
| Shot-clock violations, interceptions | PASS (0; about 3 a game, as none) |
| Share by crew style | lean, not proven: inside crews 56.3 % (none) -> 46.1 % (era), 1.6 SE |
| Twists none, era_grand, era_fathers match Phase 10 | PASS |
| Humantest x 2 | PASS |
| Banner, pause line, HUD, buttons | PASS |

## Bugs

1. **The spacing hook does not follow the board's contract (P11-12, player.gd `spaced_spot()`).**
   Steps: `--autoplay --twist era_present`, measure an off-ball attacker's spot. Expected (BOARD "SPACE THE FLOOR"):
   spots move `spacing_ft` away from the ball side and the key, **sideways**, "never further from the hoop than
   today's spot plus 1 ft, so a kick-out stays a fair shot". Actual: the spot moves straight out from the hoop by the
   full 2 ft (`hoop + off.normalized() * (len + sp)`): measured +1.7 ft further from the hoop (the edge clamp takes
   the rest), +0.2-0.5 ft from the ball handler. The owner's words ("off-ball players 2 ft wider") are met either way;
   the contract's cap is not. Low severity: every band passes. It is the main cause of the lost rim attempts (above).
   For the lead to decide (player.gd is P11-17's now; I did not touch it).

No other bugs found.

## Tuning

**None applied.** `scripts/twists.gd` `era_present` stays `long_shot_mult` 1.08, `spacing_ft` 2.0, `pullup_mult`
1.10; player.gd `PULLUP_CPU_CHANCE` 0.5 and `PULLUP_WINDOW` 1.0 stay (my proposal: keep them). Each rule is at the
owner's number and noticeable, every band passes, and the style lean is under 2 SE.

Options for the lead, if wanted:
- If the spacing should match the contract (or the owner wants the dunks of the other eras back): either fix
  `spaced_spot()` as the contract says (sideways, at most +1 ft from the hoop), or set `spacing_ft` 1.0. Measured at
  1.0 (32 games): rim attempts 25.6 a game (2.0: 23.8, none: 33.6), OREB 25.4 %, threes 15.6 a game (still +41 %),
  share 26.5 %, 9.3 min, loser 17.6. The spots would then be exactly the contract's +1 ft from the hoop. Not applied:
  2.0 is the owner's number and the contract fix belongs in player.gd.
- `pullup_mult` stacking with `long_shot_mult` on a pull-up three (x 1.19) is by the rules as written ("everyone",
  "a jumper"); if the owner wants the +10 % on twos only, that is a player.gd / main.gd change, not a number.
- Watch for P11-23 (Chapter 3 challenges): the era leans a little to shooting crews, so a Present legend who is a
  shooter (Deep End, Stretch) plays a touch stronger on his own court; check his challenge's met share there.
