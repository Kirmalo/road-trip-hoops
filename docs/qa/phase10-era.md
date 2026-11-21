# P10-21 QA: the ISO BALL era rules (twist `era_fathers`)

Build tested: branch `ccr-f5c087b2-3ojk5f` at `e18ba56`. Godot 4.3.stable, headless, `--fixed-fps 60`.
Era values under test (unchanged by this task): `cross_beat_mult` 1.2, `dunk_range_mult` 1.1, `arc_mult` 1.05.
F2 a only, so there is no `help_mult` or `mid_mult` to check.

Method as in `docs/qa/phase9-era.md`: every game is `--autoplay` (Hard vs Hard), first to 21, random first ball, one
process per game with its own fresh `XDG_DATA_HOME`, in two scratch project copies outside the repo (own
`config/name`), at most two Godot processes at a time. The run order was shuffled so the sets were played interleaved.

Measuring aids, in the scratch copies only (no sim change, no extra random numbers): a counter
`qa_cross_faced_t<team>` where `cross_beat_check()` finds a defender in front (the denominator of the beat rate;
the game itself only counts that for a human defender), and a print of every `start_rim_move()` (kind and distance
in ft). Alley-oops do not pass through `start_rim_move()`, so "take-offs" below are driving dunks and layups only.

## Runs

| Set | Flags | Games |
|---|---|---|
| none | `--twist none` (Kings vs Bridge Runners, RED "inside") | 64 |
| iso | `--twist era_fathers` | 64 |
| iso court | `--twist era_fathers --court era_fathers` | 40 |
| grand | `--twist era_grand` (Phase 9 check) | 32 |
| style none | `--twist none --quick-teams` 4 pairings below, 20 each | 80 |
| style iso | `--twist era_fathers --quick-teams` the same 4 pairings, 20 each | 80 |
| humantest | `--humantest --twist era_fathers`, and the same plus `--court era_fathers` | 2 |

All 362 games ended 21-x with exit 0. No script errors, crashes, stuck players or balls, or unfinished games, and
no shot-clock violations in any set. `--import`: clean. `--twisttest`: TWISTTEST OK.

## Stats (mean, range)

| | none (64) | iso (64) | iso court (40) | grand (32) |
|---|---|---|---|---|
| GAME LENGTH, min | 9.63 (7.2-12.3) | 9.56 (7.2-12.8) | 9.31 (6.6-12.4) | 10.65 (7.3-13.5) |
| shots | 61.1 (45-76) | 59.5 (40-75) | 58.7 (41-77) | 63.6 (46-87) |
| FG % (per game) | 53.8 (43-69) | 56.5 (43-70) | 56.3 (41-73) | 55.0 (42-65) |
| possessions | 63.7 (46-81) | 63.1 (47-87) | 60.8 (44-88) | 66.4 (48-92) |
| loser's score | 16.2 (8-20) | 16.7 (9-20) | 16.1 (9-20) | 16.5 (11-20) |
| fouls | 2.30 (0-5) | 2.08 (0-6) | 1.75 (0-4) | 1.38 (0-5) |
| free throws attempted | 1.47 (0-5) | 1.38 (0-5) | 0.95 (0-3) | 0.97 (0-4) |
| offensive rebounds, % of misses | 25.9 | 25.4 | 26.5 | 25.6 |
| out of bounds | 1.08 (0-4) | 1.23 (0-4) | 0.97 (0-3) | 1.19 (0-4) |
| interceptions | 3.0 (1-7) | 3.3 (0-10) | 2.8 (0-9) | 3.2 (0-5) |
| shot-clock violations | 0 | 0 | 0 | 0 |
| side switches | 1 every game | 1 | 1 | 1 |
| three attempts | 11.3 (5-20) | 10.4 (3-18) | 10.4 (5-19) | 9.2 (4-18) |
| three make %, pooled | 37.4 | 36.7 | 44.0 | 28.0 |
| mid jumpers %, pooled | 49.8 | 50.1 | 46.7 | 44.4 |
| layups a game / make % | 17.9 / 60.3 | 16.8 / 62.4 | 16.9 / 63.9 | 18.9 / 63.7 |
| dunks a game / make % | 15.6 / 71.7 | 16.1 / 75.7 | 15.0 / 72.8 | 17.0 / 76.7 |
| crossovers a game | 24.5 | 25.1 | 24.3 | 27.4 |
| crossovers with a defender in front | 23.2 | 24.1 | 23.2 | 26.4 |
| crossover beats a game | 9.6 | 12.0 | 12.3 | 11.3 |
| **beat rate (beats / in front)** | **41.4 %** | **49.9 %** | **52.9 %** | 43.0 % |
| beats the twist added (`iso_cross_beats`) | 0 | 1.84 | 1.85 | 0 |
| driving take-offs (dunk + layup) | 29.0 | 29.0 | 28.4 | 31.1 |
| dunk share of take-offs | 38.5 % | 42.2 % | 40.6 % | 39.0 % |
| **dunk take-off distance, mean / 90th pct / max, ft** | **5.52 / 5.98 / 6.00** | **6.03 / 6.58 / 6.60** | 5.95 / 6.57 / 6.60 | 5.52 / 5.98 / 6.00 |
| dunks from past 6 ft (`iso_far_dunks`) | 0 | 9.1 | 8.2 | 0 |
| RED wins | 40/64 (62 %) | 31/64 (48 %) | 25/40 (62 %) | 17/32 (53 %) |

Standard error of a win share: about 6 points at 64 games, 8 at 40, 9 at 32. The era court only changes the drawing,
so iso and iso court are the same rules (their three % gap, 36.7 vs 44.0, is noise). Pooled iso (104 games): 9.47
min, 59.2 shots, RED 56/104 (54 %).

Bands (CLAUDE.md typical game): length 7-11 min (iso: 8 of 64 over 11, none: 9 of 64, the same), shots 55-90 at about
50 % (iso 59.5 at 56.5 %; 15 of 64 games under 55 in both none and iso, the fast high-FG % games as in Phase 9),
fouls 1-5 (one iso game had 6), OOB 1-2, loser 12-20 (3 of 64 under 12), OREB 25 %. All PASS, the same as twist none.

## Each rule: noticeable? (the owner's words)

Pooled over every game of each twist (none: 64 + 80 style games = 144; iso: 104 + 80 = 184):

| Rule | none | iso | Change | Owner target | Verdict |
|---|---|---|---|---|---|
| Crossover beats the defender in front | 41.0 % (SE 0.9) | 49.7 % (SE 0.8) | x 1.21 | "about 20 % more often" | PASS: on target |
| Crossover beats a game | 9.4 | 11.9 | +2.5 (+27 %) | | about 2-3 more "SHOOK!" popups a game |
| Ankle-breaker falls a game | 2.06 | 2.65 | +29 % | | follows the beats |
| Dunk take-off distance, mean | 5.51 ft | 6.00 ft | +8.9 % | "about 10 % further out" | PASS |
| Dunk take-off distance, max | 6.00 ft | 6.60 ft | +10 % | | exactly the rule |
| Dunks from past 6 ft | 0 | 9.1 a game (iso set) | | | most driving dunks now take off from 6-6.6 ft |
| Dunk share of driving take-offs | 37.5 % | 41.5 % | +4 pts | | slightly more dunks, fewer layups |
| Arc (drawing only) | 1.0 | 1.05 | +5 % | "slightly higher arc" | PASS (slight, as asked; see below) |

The crossover rule lands where the owner asked: today's beat rate measures 41 % (P10-12's `CROSS_ISO_BASE_RATE`
0.42 is right), the era's 49.7 %. Every driving dunk moves out by the full extra range: a driver takes off as soon
as he is in range, so the distribution shifts from "up to 6 ft" to "up to 6.6 ft" (mean +0.5 ft). On screen this is
small (half a foot), but the owner asked for "about 10 %" and that is what it is; dunks also get a little more common
(+4 points of the take-offs) and go in a little more (71.7 -> 75.7 %, they start from a cleaner spot).

Arc: a 20 ft jumper's drawn peak is `shot_peak` 92.8 sim px over the straight line; x 1.05 is about 4.6 sim px (about
10 screen px at 1280 x 720). Thin air (1.15) is three times that. The capture `hoops_ball_thin_air_arc.png` (the
tag `ball.gd` uses for any `arc_mult` twist) shows a long jumper from the far side at its peak at about y 40, just
under the top bar's text (y 28): visible, not hidden. This is "slightly higher", as the owner worded it. No change.

Side effects: FG % +2.7 points (more beats and dunks), shots -1.6, length the same (9.6 vs 9.6 min), fouls and
rebounds the same. Nothing else moved outside noise.

## Share by crew style

`--quick-teams` pairings, both ways round (the style plays only on RED, so "both ways" = the inside crew as RED with
its style, then the outside crew as RED with its style; the BLUE crew keeps its stat shape at average 50):
Riverside Soul (inside) vs Switchbacks (outside), Boardwalk Bombers (inside) vs Bodega Bandits (outside). 20 games
each.

| Pairing (BLUE, RED) | none: inside crew wins | iso: inside crew wins |
|---|---|---|
| Switchbacks, Riverside Soul (inside RED) | 6/20 | 9/20 |
| Riverside Soul, Switchbacks (outside RED) | 8/20 | 9/20 |
| Bodega Bandits, Boardwalk Bombers (inside RED) | 12/20 | 10/20 |
| Boardwalk Bombers, Bodega Bandits (outside RED) | 10/20 | 12/20 |
| **all four** | **36/80 (45.0 %)** | **40/80 (50.0 %)** |
| plus Kings vs Bridge Runners (inside RED; none / iso + iso court) | 40/64 | 56/104 |
| **inside crews, every game** | **76/144 (52.8 %)** | **96/184 (52.2 %)** |

SE: 5.6 points at 80 games (a difference of two 80-game shares: 7.9). The era moves the inside crews' share by
+5 points in the style pairs (under one SE of the difference) and by -0.6 points over every game. **No style is
favoured.** This is the opposite of the Phase 9 lesson (OLD SCHOOL's `inside_mult` gave an inside crew 68 %): ISO
BALL's crossover rule works for every handler, and both styles cross about as often.

Per style, iso games (style pairs): crossover beat rate inside 48.9 %, outside 47.4 %; far dunks a game, inside
crew 3.5-5.6, outside crew 3.5-4.6. An inside crew gets about 0.5 more far dunks a game (P10-12 saw the same), which
does not show in the wins.

The Kings vs Bridge Runners matchup: RED 62 % with twist none (Phase 9 measured 60 % on 40), 48 % iso, 62 % iso
court; within chance of each other and of the long-run share.

## Twist none and era_grand match Phase 9

| | Phase 9 (`docs/qa/phase9.md`, 40 each) | here |
|---|---|---|
| none: shots, FG %, length, fouls, OREB, RED | 61.5, 53.9 %, 9:49, 2.2, 26.6 %, 60 % | 61.1, 53.8 %, 9:38, 2.30, 25.9 %, 62.5 % (64) |
| era_grand: shots, FG %, length, fouls, OREB, RED | 61.8, 56.5 %, 10:29, 1.6, 24.8 %, 67 % | 63.6, 55.0 %, 10:39, 1.38, 25.6 %, 53 % (32) |

PASS: twist none and OLD SCHOOL play as in Phase 9 (era_grand's RED 53 % on 32 games vs 67 % on 40 is within
chance; 12 of its 32 games went over 11 min, as OLD SCHOOL is the slow era, mean 10.7). The crossover and dunk hooks
draw no random number and change nothing at 1.0: twist none's crossover beat rate (41 %) and dunk distances (max
6.00 ft) are today's.

## Humantest (ISO BALL)

| Run | Final | Length | Fouls | Notes |
|---|---|---|---|---|
| `--twist era_fathers` | BLUE 21 - RED 19 | 7:14 | 6 (shooting 6, and-ones 5) | steals timed 7/11, blocks timed 3/4; human crossovers 30, beat 6 (2 from the twist); a CPU crossover at the human 0/1 |
| `+ --court era_fathers` | BLUE 21 - RED 10 | 5:17 | 3 | steals timed 9/11, blocks timed 2/2; human crossovers 20, beat 2; a CPU crossover at the human 0/1 |

Both ran to the end, exit 0, no errors. The second run is short (5:17, 21-10): one humantest, scripted, not a band
check. The CPU crossed at the scripted human defender once per game, so the human-defender side of the rule
(the `cross_beat_human` easing) is not measured here; it is the same code path as the CPU defender's second roll.

## Screenshots (xvfb, 1280 x 720, `--court era_fathers --twist era_fathers`)

| Check | Result |
|---|---|
| HUD readable (`--shots`) | PASS: top bar, shot clock, pause button clear on the era floor |
| Touch buttons not covering the action | PASS: joystick bottom-left, PASS / SHOOT bottom-right, as on other courts |
| Banner (`--twistshots`) | PASS: "ISO BALL" with its icon (a ball with a zigzag), the line "Iso ball: crossovers shake defenders, dunks from further out" ends at about x 950 of the 970 px banner |
| Arc and dunk (`--ballshots`) | PASS: mid-flight jumper and a dunk at the rim drawn; the arc peak stays below the top bar text |

## Checks

| Check | Result |
|---|---|
| Import, script errors | PASS (none in 362 games) |
| `--twisttest` | PASS (TWISTTEST OK, the three era_fathers keys listed) |
| Crossover beats about 20 % more often | PASS: 41.0 -> 49.7 % (x 1.21) |
| Dunks about 10 % further out | PASS: mean 5.51 -> 6.00 ft (+8.9 %), max 6.0 -> 6.6 ft |
| Slightly higher arc | PASS (drawing only, x 1.05, slight as asked) |
| Length, shots, FG %, fouls, OOB, OREB, loser in the bands | PASS, same as twist none |
| Shot-clock violations, interceptions | PASS (0; about 3 a game, as none) |
| Share by crew style | PASS: inside crews 52.8 % (none) vs 52.2 % (iso) |
| Twist none and era_grand match Phase 9 | PASS |
| Humantest x 2 | PASS |

## Tuning

**None applied.** Each rule is at the owner's number and noticeable by its own measure, and no style is favoured, so
the task's condition for tuning (a rule not noticeable, or a style clearly favoured) is not met. `scripts/twists.gd`
`era_fathers` stays `cross_beat_mult` 1.2, `dunk_range_mult` 1.1, `arc_mult` 1.05.

Options for the lead, only if the owner later says it does not feel different enough (not measured):
- The dunk rule is the least visible on screen (half a foot further). `dunk_range_mult` 1.2 (7.2 ft) would show more,
  at the cost of more dunks (and an inside crew gets a few more of them; re-check the style share).
- `arc_mult` 1.10 would read clearly as "higher" while staying under thin air's 1.15.

## Notes
- Not tested: the Fathers legends (`--challenge` on a Chapter 2 legend); P10-17's signature moves are being added in
  parallel, and these games have no Fathers on the court.
- `--ballshots` with twist none never collected all its tags in 400 s (no lob was caught), and timed out (exit 124);
  the era_fathers run also timed out after saving 11 images. A capture driver detail, not a game bug.
- The game itself counts a crossover "in front" only for a human defender (`human_cross_faced`). A QA counter like
  `cross_faced_t<team>` for every defender would let later passes measure the beat rate without a scratch patch.
