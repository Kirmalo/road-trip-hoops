# P9-17 QA: the OLD SCHOOL era rules (twist `era_grand`)

Build tested: branch `ccr-f5c087b2-3ojk5f` at `4fd878a` (P9-08 merged). Godot 4.3.stable, headless, `--fixed-fps 60`.
Era values under test: `speed_mult` 0.94, `long_shot_mult` 0.88, `inside_mult` 1.08, `foul_mult` 0.6.
Every game: `--autoplay` (Hard, CORNFIELD KINGS (BLUE) vs BRIDGE RUNNERS (RED, style "inside")), first to 21, random
first ball, each a separate process in a scratch project copy (own `config/name`, own `XDG_DATA_HOME`).

Not tested: the Chapter 1 legends via `--challenge`. That flag does not exist on this build yet (P9-13 not merged,
no `legends_test.gd`), so every era game here is the Quick Game crews.

## Runs

| Set | Flags | Games |
|---|---|---|
| none | `--autoplay --twist none` | 64 |
| era | `--autoplay --twist era_grand` | 64 |
| era court | `--autoplay --twist era_grand --court era_grand` | 40 |
| cand 0.80 | `--twist era_grand`, scratch copy with `long_shot_mult` 0.80 (the only change) | 64 |
| humantest | `--humantest --twist era_grand` and the same plus `--court era_grand` | 2 |

All 234 games ended 21-x. No script errors, crashes or games that never ended, and no shot-clock violations in any
set. `--twisttest`: TWISTTEST OK (also on the 0.80 copy).

## Stats (mean, range)

| | none (64) | era (64) | era court (40) | cand 0.80 (64) |
|---|---|---|---|---|
| GAME LENGTH, min | 9.38 (6.7-11.9) | 9.91 (6.7-13.4) | 9.65 (7.3-12.3) | 10.11 (7.5-12.4) |
| shots | 66.2 (46-94) | 65.6 (46-93) | 64.6 (46-78) | 65.9 (46-83) |
| FG % (per game) | 51.4 (40-63) | 54.0 (41-67) | 53.3 (43-68) | 54.4 (42-70) |
| possessions | 57.8 (43-78) | 58.6 (41-75) | 57.7 (44-76) | 59.6 (45-73) |
| loser's score | 16.8 (11-20) | 16.9 (8-20) | 16.2 (8-20) | 17.3 (10-20) |
| fouls | 2.59 (0-7) | 1.31 (0-4) | 1.57 (0-4) | 1.36 (0-6) |
| free throws attempted | 1.55 (0-6) | 0.81 (0-4) | 1.10 (0-3) | 0.94 (0-4) |
| three attempts | 10.4 (3-17) | 9.5 (4-19) | 9.2 (2-16) | 8.3 (3-13) |
| threes made a game | 3.44 | 2.73 | 2.52 | 2.27 |
| three make %, pooled | 33.0 | 28.7 | 27.4 | 27.2 |
| three share of shots, % | 15.7 | 14.5 | 14.3 | 12.6 |
| mid jumpers (inside the arc) %, pooled | 38.8 | 38.1 | 41.4 | 41.3 |
| layups %, pooled | 55.9 | 63.5 | 59.2 | 60.2 |
| dunks %, pooled | 71.5 | 76.4 | 75.3 | 76.9 |
| rim attempts (layups + dunks) | 39.2 (22-57) | 38.5 (20-51) | 38.3 (26-51) | 40.0 (29-51) |
| rim share of shots, % | 59.2 | 58.6 | 59.3 | 60.7 |
| rim makes a game | 24.9 | 26.8 | 25.6 | 27.3 |
| out of bounds | 0.91 (0-4) | 1.03 (0-6) | 0.90 (0-5) | 1.00 (0-4) |
| interceptions | 3.1 (0-8) | 2.8 (0-8) | 3.1 (0-9) | 3.4 (0-10) |
| shot-clock violations | 0 | 0 | 0 | 0 |
| side switches | 1 every game | 1 | 1 | 1 |
| RED wins | 33/64 (52%) | 38/64 (59%) | 22/40 (55%) | 30/64 (47%) |

The era court only changes the drawing, so "era" and "era court" are the same rules. Their gaps (layups 63.5 vs
59.2 %) are noise; pooled (104 games): 9.81 min, 65.2 shots, 1.41 fouls, three make % 28.2.

Twist none matches the Phase 8 / P9-08 reference (P9-08: 9.5 min, 66 shots, 51.4 %, 2.57 fouls) and the CLAUDE.md
bands. The era stays inside the bands too: 7-11 min (mean 9.9), 55-90 shots at about 50 % (65.6 at 54 %), fouls
1-5 (1.31, at the bottom), 1-2 out of bounds (about 1), loser 12-20.

### By team (none -> era)
| | BLUE (Kings, takes about 6.5 threes a game) | RED (Bridge Runners, "inside" style, 3.5 threes) |
|---|---|---|
| three make % | 32.0 -> 26.3 | 35.1 -> 33.8 |
| rim makes a game | 11.1 -> 11.7 | 12.6 -> 13.9 |
| FG % | 47.6 -> 49.5 | 54.2 -> 57.4 |

The era helps an inside crew more than a jump-shooting crew. The twist reads no team, so this comes from the crews'
styles and is expected. RED's 59 % (38/64; 57.7 % pooled over 104) is within chance against 52 % with twist none
(the gap is about 1 standard error). If the Chapter 1 legends are an inside crew, expect their challenges to play a
little harder in this era. Check that again with `--challenge` once P9-13 is in.

### Humantest (era)
| Run | Final | Length | Fouls | Notes |
|---|---|---|---|---|
| `--twist era_grand` | BLUE 21 - RED 18 | 7:51 | 1 (reach) | steals timed 13/14, blocks timed 4/5, countdown presses ignored 3/3 |
| `+ --court era_grand` | BLUE 17 - RED 21 | 8:56 | 1 (reach) | steals timed 13/16, blocks timed 3/5, crossovers beat him 3/4 |

Both ran to the end without errors. There were no free throws in either game; 2 humantest runs are too few to say
anything about free throws.

## Checks
| Check | Result |
|---|---|
| Import, script errors | PASS (none) |
| Twist none = Phase 8 reference | PASS (9.4 min, 66 shots, 51.4 %, 2.6 fouls) |
| Fewer fouls | PASS: 2.59 -> 1.31 a game (-49 %), free throws 1.55 -> 0.81 |
| More close makes | PASS: layups +7.6 pts, dunks +4.9 pts (SHOT_CAP 0.92 caps the open dunks), +1.9 rim makes a game |
| More inside *play* (attempts) | FAIL (weak): the rim share of shots does not move (59.2 -> 58.6 %). The CPU picks its shots by where it stands, so only the makes change |
| Fewer threes falling | PASS but small: 33.0 -> 28.7 %, 3.44 -> 2.73 made a game (-0.7, about one fewer three every game and a half) |
| Fewer three attempts | weak: 10.4 -> 9.5 (-9 %) |
| Slower | PASS (small): +0.53 min a game (+6 %; about 2.5 standard errors), same shots and possessions |
| Bands (length, shots, FG, fouls, OOB) | PASS |
| Balance | PASS within chance (see by team) |
| Banner fits 1280x720 | PASS (the line ends at about x 900 of the 960 px banner); the icon is a plain white dot |
| HUD, touch buttons (`--shots`, era court) | PASS: HUD readable; the joystick and buttons stay in the corners |

## Does it feel different enough?
Partly. The fewer fouls show clearly. The other three changes are small enough that a player could miss them:
- Slower: +0.5 min, and players are 6 % slower, so a player sees it less than the sand twist (0.9).
- Fewer threes: about 0.7 fewer threes made a game at 0.88. In a game of about 33 makes the player barely notices.
- More inside: layups and dunks go in more, but the CPU does not drive more, so the shot mix looks the same as today.

## Proposed tuning (constants only, `scripts/twists.gd`, `TWISTS.era_grand`)
1. **`long_shot_mult` 0.88 -> 0.80** (measured, 64 games, the "cand 0.80" column). Threes made drop to 2.27 a game
   (-34 % from today, was -21 %). The CPU now takes fewer threes as well, 10.4 -> 8.3 (its three decision reads the
   odds), so "fewer threes" becomes true for attempts, not only for makes. The rim share goes up to 60.7 % and the
   mid jumpers to 41 %. The game gets a little longer (10.1 min) and stays inside every band. Balance 30/64 RED.
   This is the one change that moves both the mix and the feel. I recommend it.
2. Keep `inside_mult` 1.08. Open dunks already hit SHOT_CAP 0.92, and layups are +5..8 points. Raising it makes
   games shorter, which works against "slower".
3. Keep `foul_mult` 0.6. Fouls are 1.3 a game, already at the bottom of the 1-5 band. Lower and free throws almost
   never happen.
4. Optional: `speed_mult` 0.94 -> 0.92 if the owner wants the slower pace to show on screen. Not measured; the sand
   twist at 0.9 is the reference for what feels slow.
5. Not a constant: to get really "more inside play" (more drives), the CPU's shot choice would need a twist key (for
   example a weight on its three/drive pick). That is a code change for the lead to decide, not something QA can tune.

## Banner text
Current: "Old school: slower, more inside, fewer threes and fouls". It fits, but "fewer threes" reads as fewer three
attempts, and those barely drop at 0.88. Proposed (checked in a `--twistshots` capture, fits the banner with a few
px to spare; longer lines get cut off at the banner's 560 px text width):

    "Old school: slower, threes miss more, inside scores, few fouls"

If option 1 (0.80) goes in, "fewer threes" is true for attempts too, and the current line is fine.

## Notes and minor findings
- `twist_fx.gd` `_draw_icon()` has no `era_grand` case. The banner shows the fallback plain white dot in its circle
  (screenshot below). An era icon is still to do.
- The era court backdrop has a painted wall scoreboard reading "14 - 12" just under the HUD, while the real score is
  0 - 0. It is art, but a player could read it as the score. Minor, for the art owner.
- `--twistshots` needs a game mode (`--autoplay`). On its own it stays on the title screen and never quits.

Captures (scratch, not committed): banner `hoops_twist_era_grand_100.png`, play `hoops_900.png` / `hoops_1800.png`.
