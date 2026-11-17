# P6-30 / P6-31 Phase 6 QA: cities, ramp, twists and animation

**Builds tested:**
- **Game batches** (all `--city` games, twist on/off, 8 humantests): `6412667` ("Vision: 31 MB download OK"), branch
  `ccr-f5c087b2-3ojk5f`, plus the wet-court tuning below. The Seattle runs were all made after the tuning.
- **Final build** (web size, Chromium fps and texture memory, `--anim-test`, 18 Quick Game humantests, 20 Quick Game
  autoplay): `631be3f` (P6-25: v1 sheets removed, Quick Game in v2 sheets; recruit joining lines) plus the same
  tuning. P6-25 changes no gameplay code, so the batches on `6412667` stay valid. Only the animation counters of
  Quick Game needed the final build: on `6412667` Quick Game still drew v1 sheets, which have no rim hang.
- Godot 4.3 stable (Linux). 4 cores, shared at times with other jobs (load average 6-13 during the batches).

**Import:** clean, no script or parse error (on `6412667` and again on `631be3f` + tuning). **`--twisttest`:** OK.

**Runs:**
- 1,212 game runs in total. Every one reached `FINAL`, with no `SCRIPT ERROR`, parse error or `ERROR` line.
- Two output files were clobbered when my two job queues met (both wrote `nol2_30` and `nol3_30`). I re-ran those two
  games.
- No game came near `--quit-after`. Every game had exactly 1 side switch and **0 shot-clock violations**, including
  Memphis's 18-second clock.

## Headline

- **Ramp (40 games per city game, Normal, `--expected-roster`):** the Kings win about 60-75% through New Orleans
  (pooled per city: 57%, 74%, 62%, 68%). From Denver on it is about 45-55% (48%, 56%, 52%), and New York is 45%
  (QF 57%, SF 40%, final 38%).
  - The shape matches the working target (about 70% falling to about 50%), with three exceptions:
    - Hometown sits low (57%, SE 6). Hometown 1 is 55% here against 70% in P6-00, a difference that is inside the
      noise.
    - Chicago, at 74%, is easier than Hometown by more than the noise.
    - Denver's boss game (30%, SE 7) and the New York final (38%, SE 8) are below the 40% floor.
  - **I applied no STAGE_AVG change** (section 2.4 explains why).
- **Wet court tuned:** about 500 slides a CPU game to 21 went down to **68 a game to 21** (49-97). Slides are split
  evenly between the teams (34.8 / 33.1). The scripted human slid 8-9 times a game.
  - **The tuning:** `cut_angle_deg` 60 -> 150, `cut_min_speed` 0.8 -> 0.9 (`scripts/twists.gd`), and `SLIDE_MIN_WANT`
    0.5 -> 0.9 (`scripts/player.gd`).
- **Twists:** none of them changes the win share or point share beyond the noise (40 vs 40 games). Every per-team
  stat that a twist touches moves the same way for both teams, or the difference is inside the noise.
  - **Clearly felt:** wet (slides), cage (sideline out of bounds 0.50 -> 0 a game, 0.61 fence bounces), sand (shots
    per minute -11%, possessions per minute -7%), thin air (turbo -7 to -8% for both teams, lobs hang).
  - **Weak in CPU games:** crowd (possessions per minute +4%; the 18 s clock never runs out) and humid (no player
    ever runs empty; turbo -4 to -6%).
  - **Sand length:** games are only +6% longer, which is not significant on 40 games. LA's games to 21 run about
    1 minute longer than the other cities' (11.9 vs 10.4-10.7).
- **Animation:**
  - `--anim-test`: **ANIM OK**, 68 v2 sheets, 1,185 frames each, 0 empty, 0 without points.
  - Ankle-breakers: **2.56 per game to 21** (63% of games have 1-3).
  - Dunk styles (games to 21): one-hand 30%, two-hand 20%, windmill 18%, tomahawk 20%, alley 12%.
  - Rim hang on 97% of made dunks, as designed.
  - Bounce passes are 34% of all passes.
  - Humantest timed steals and blocks unchanged (18 runs on the final build: timed steals 81%, timed blocks 55%).
- **Web (final build):**
  - **`index.pck` = 34,181,680 bytes (32.6 MiB)**; it was 43,387,840 before P6-25.
  - Chromium fps is **-2.5% against the Phase 5 build** (15.6 vs 16.0, idle machine, A/B/A/B).
  - Texture memory is **64.4 MB** (video 88.9 MB) in a Quick Game.
  - No console errors, and the L8 indexed sheets draw correctly in WebGL2.

## 1. Commands

```
godot --headless --path . --import
# ramp, 40 each (one.sh skips a game whose output already has FINAL); 4 + 2 + 2 processes in parallel
godot --headless --path . --fixed-fps 60 --quit-after 200000 -- --autoplay --city <id> --cgame N --expected-roster
#   ids: hometown (1, 3), chicago (1, 3), memphis, new_orleans, denver, seattle, los_angeles (1-3), new_york (1-3)
# twist off, same city game 1 and same expected roster, 40 each
godot --headless --path . --fixed-fps 60 --quit-after 200000 -- --autoplay --city <id> --cgame 1 --expected-roster --twist none
# humantests: 12 Quick Game on 6412667, 18 Quick Game on the final build, 2 Seattle boss game
godot --headless --path . --fixed-fps 60 --quit-after 200000 -- --humantest [--city seattle --cgame 3 --expected-roster]
# wet tuning probes: Seattle 1 played to 21, 2 games per setting, in a copy of the project
godot --headless --path <copy> --fixed-fps 60 --quit-after 200000 -- --autoplay --city seattle --cgame 1 --expected-roster --target 21
godot --headless --path . -- --anim-test
godot --headless --path . -- --twisttest
# screenshots (xvfb): --shots / --shots --humantest / --twistshots DIR / --ballshots DIR / --texmem, with --shots-dir
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- --city <id> --cgame 3 --expected-roster --shots --shots-dir DIR
tools/build_web.sh        # no publish; Phase 5 build: git archive 4675878 into a folder, same script
```

**`--expected-roster`.** Every run printed `EXPECTED ROSTER` and `MATCH ... | level normal | twist <id>`. What it
models:
- Every stat point is spent on **Deuce** (the first roster player who can take one, on his lowest stat). Deuce goes
  52/62/48/48/50 in Hometown, 67/68/66/66/65 in Denver and 76/77/78/78/77 in New York.
- **Jojo and Tank keep their starting ratings all trip.** Tank is 42/38/62/58/48.
- The recruits are signed but sit on the bench, because the starters are always the 3 underdogs. By New York, LA's
  recruit (82/70/82/70/70) and Seattle's (78/66/66/78/66) are on the bench behind Tank.

So this ramp is a **lower bound**: a player who starts recruits or spreads points over the crew is stronger from
Chicago on. The more cities, the bigger the gap.

## 2. P6-30: ramp

### 2.1 Every city game (40 games each, Normal, CPU vs CPU, BLUE = Cornfield Kings with the Hard knobs)

| City game | To | Games | Kings win % (SE) | Length mean (min-max) | Score (Kings - city) | Loser pts (range) | Point share (SE) | Shots | Fouls | OOB | SCV | P6-00 win % (100) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Hometown 1 | 11 | 40/40 | 55% (8) | 5.3 (2.6-9.6) | 9.8 - 9.1 | 7.8 (3-10) | 51.9% (1.7) | 43 | 2.0 | 1.1 | 0 | 70% (5) |
| Hometown 3 (boss) | 21 | 40/40 | 60% (8) | 10.6 (7.8-15.1) | 19.4 - 17.6 | 15.8 (7-20) | 52.4% (1.4) | 85 | 3.1 | 2.1 | 0 | 64% (5) |
| Chicago 1 | 11 | 40/40 | 72% (7) | 5.9 (4.0-8.9) | 10.3 - 8.3 | 7.6 (1-10) | 55.4% (1.9) | 47 | 1.7 | 1.3 | 0 | 66% (5) |
| Chicago 3 (boss) | 21 | 40/40 | 75% (7) | 11.3 (7.6-15.1) | 20.4 - 17.4 | 16.6 (9-20) | 54.0% (1.1) | 90 | 4.6 | 2.6 | 0 | 62% (5) |
| Memphis 1 | 11 | 40/40 | 62% (8) | 5.9 (3.5-8.8) | 9.9 - 9.2 | 8.1 (3-10) | 52.0% (1.7) | 46 | 2.1 | 1.3 | 0 | - |
| Memphis 2 | 15 | 40/40 | 60% (8) | 7.6 (5.4-10.4) | 13.7 - 12.3 | 10.9 (6-14) | 52.6% (1.5) | 61 | 3.3 | 1.4 | 0 | - |
| Memphis 3 (boss) | 21 | 40/40 | 62% (8) | 10.4 (7.0-13.8) | 19.5 - 17.9 | 16.4 (9-20) | 52.1% (1.2) | 85 | 4.4 | 1.6 | 0 | - |
| New Orleans 1 | 11 | 40/40 | 75% (7) | 5.3 (3.5-8.4) | 10.2 - 8.4 | 7.4 (3-10) | 54.9% (1.9) | 41 | 1.6 | 1.4 | 0 | - |
| New Orleans 2 | 15 | 40/40 | 68% (7) | 8.0 (5.7-11.0) | 13.8 - 12.7 | 11.3 (6-14) | 52.2% (1.4) | 64 | 2.8 | 1.8 | 0 | - |
| New Orleans 3 (boss) | 21 | 40/40 | 60% (8) | 10.4 (4.5-13.3) | 18.9 - 17.5 | 15.3 (6-20) | 52.0% (1.6) | 84 | 3.7 | 2.5 | 0 | - |
| Denver 1 | 11 | 40/40 | 62% (8) | 5.4 (3.9-7.6) | 9.9 - 9.2 | 7.9 (3-10) | 52.0% (1.6) | 45 | 1.8 | 1.3 | 0 | - |
| Denver 2 | 15 | 40/40 | 52% (8) | 7.2 (3.4-10.7) | 13.3 - 12.4 | 10.7 (4-14) | 51.7% (1.8) | 59 | 2.2 | 1.7 | 0 | - |
| Denver 3 (boss) | 21 | 40/40 | **30% (7)** | 10.4 (7.5-13.2) | 17.6 - 19.9 | 16.4 (9-20) | 47.0% (1.2) | 84 | 4.1 | 1.9 | 0 | - |
| Seattle 1 | 11 | 40/40 | 57% (8) | 5.4 (3.4-8.3) | 9.8 - 9.3 | 8.0 (3-10) | 51.5% (1.7) | 44 | 1.9 | 1.3 | 0 | - |
| Seattle 2 | 15 | 40/40 | 68% (7) | 7.6 (5.1-11.8) | 14.1 - 12.0 | 11.0 (4-14) | 53.9% (1.6) | 61 | 2.5 | 1.8 | 0 | - |
| Seattle 3 (boss) | 21 | 40/40 | 42% (8) | 10.7 (7.8-13.3) | 18.8 - 19.2 | 16.9 (12-20) | 49.4% (1.1) | 86 | 3.7 | 1.9 | 0 | - |
| Los Angeles 1 | 11 | 40/40 | 55% (8) | 5.8 (3.8-9.4) | 9.4 - 9.0 | 7.3 (3-10) | 51.3% (2.0) | 41 | 1.8 | 1.2 | 0 | - |
| Los Angeles 2 | 15 | 40/40 | 50% (8) | 8.5 (5.7-11.3) | 13.2 - 13.2 | 11.4 (7-14) | 50.0% (1.4) | 62 | 2.5 | 1.4 | 0 | - |
| Los Angeles 3 (boss) | 21 | 40/40 | 50% (8) | 11.9 (9.1-16.0) | 18.6 - 19.2 | 16.6 (9-20) | 49.2% (1.2) | 86 | 4.2 | 2.5 | 0 | - |
| New York QF | 21 | 40/40 | 57% (8) | 10.7 (7.4-13.7) | 19.1 - 18.8 | 16.8 (9-20) | 50.4% (1.2) | 85 | 4.0 | 1.4 | 0 | - |
| New York SF | 21 | 40/40 | 40% (8) | 10.6 (7.2-14.6) | 18.6 - 19.5 | 17.0 (12-20) | 48.9% (1.0) | 88 | 3.5 | 1.7 | 0 | - |
| New York final (boss) | 21 | 40/40 | **38% (8)** | 10.5 (6.9-14.3) | 18.6 - 19.1 | 16.6 (9-20) | 49.4% (1.3) | 84 | 4.0 | 1.3 | 0 | - |

### 2.2 The curve, per city (all games of the city pooled)

| City (stage, twist) | Games | Kings win % (SE) | Point share |
|---|---|---|---|
| Hometown (1, none), games 1 + 3 | 80 | 57% (6) | 52.2% |
| Chicago (2, wind), games 1 + 3 | 80 | 74% (5) | 54.5% |
| Memphis (3, crowd) | 120 | 62% (4) | 52.2% |
| New Orleans (4, humid) | 120 | 68% (4) | 52.7% |
| Denver (5, thin air) | 120 | 48% (5) | 49.6% |
| Seattle (6, wet) | 120 | 56% (5) | 51.3% |
| Los Angeles (7, sand) | 120 | 52% (5) | 49.9% |
| New York (8, cage) | 120 | 45% (5) | 49.5% |

```
win %  75 |    C        N
       70 |
       65 |       M
       60 | H
       55 |                   S
       50 |                         L
       45 |              D               NY
          +--------------------------------
            H  C  M  N  D  S  L  NY
```

Point share tells the same story with less noise: about 52-55% through New Orleans, then 49.5-51.3% from Denver on.

### 2.3 Against the targets (working target, not an owner decision)

| Check | Result | |
|---|---|---|
| About 70% in Hometown | 57% (6) pooled. Hometown 1 is 55% (8) here against 70% (5) in P6-00 with the same three Kings and no twist (P6-10 rebuilt the crews from STAGE_AVG + TIER). The diff of 15 is inside the noise (limit 19). Pooled with P6-00, Hometown 1 is 66% | about right |
| Falling to about 50% in the New York final | 38% (8) | a bit low (1.5 SE) |
| No city game above 80% | highest 75% (New Orleans 1, Chicago 3) | pass |
| No city game below 40% | **Denver 3: 30% (7)**, New York final 38% (8), New York SF 40% (8) | Denver 3 fails (1.4 SE under) |
| No city easier than the one before by more than the noise | Chicago over Hometown: +17, limit 15.6. New Orleans over Memphis: +6, limit 11.7. Seattle over Denver: +8, limit 14. LA over Seattle: -4. New York over LA: -7 | **Chicago over Hometown fails**. The others pass |
| Game lengths | to 11: 5.3-5.9 min, to 15: 7.2-8.5, to 21: 10.4-11.9 (the P5-16 / P6-00 targets: 4-8, 7.6-7.7, 10.6-11.2) | pass |
| Shot-clock violations, side switches, stuck games | 0; 1 every game; none | pass |

The boss game is the hardest game of its city only in Denver, Seattle and New York. In Hometown, Chicago and
Memphis, game 1, game 2 and the boss are all within noise of each other (as in P6-00). The owner asked to leave the
in-city ramp as it is.

### 2.4 Tuning decision: no STAGE_AVG change

- The broad shape is the target's: about 65% in the first four cities and about 50% in the last four.
- The two failures sit at the ends, and both have a better explanation than STAGE_AVG:
  - **Chicago over Hometown** comes from Hometown landing on the low side. 40-game batches swing by 15 points, and
    Hometown 1 was 70% in P6-00. Chicago's wind doesn't help the Kings beyond the noise (section 3).
  - **Denver 3 and the New York final** are where the `--expected-roster` crew is weakest against the boss. Two of
    its three starters are still at their Hometown ratings while the boss is at STAGE_AVG + 20 (78 in Denver, 90 in
    New York). A real player who starts the better recruits does better than this.
- The owner says the campaign difficulty is about right. A STAGE_AVG step of 2 moves a city by roughly 3-5 win
  points, too little to verify on 40 games.
- If the lead wants Denver's boss game over 40% anyway, the smallest step in the owner's range is `STAGE_AVG[5]`
  58 -> 56. Then confirm on 100 games of Denver 3 and Seattle 1, as the board's P6-30 line asks.
- A better measuring stick for later: an `--expected-roster` variant that starts the best 3 by average rating.
  That's a tool change, so I left it out of this pass.

### 2.5 Proposed campaign targets (for the lead to confirm)

- Kings (CPU, Normal, `--expected-roster`):
  - 55-75% per city through New Orleans, 45-60% from Denver on;
  - no city game under 35% or over 80% on 40 games (SE 7-8);
  - the New York final 40-55%.
- Lengths:
  - to 11: 4.5-6.5 min;
  - to 15: 7-9 min;
  - to 21: 10-12.5 min (LA's sand at the top of that).

## 3. P6-30: twists, on vs off (city game 1, 40 vs 40, same expected roster)

"REAL" means |diff| > 2 x sqrt(SE_on^2 + SE_off^2). With about 25 stats per twist, expect about 1 crossing by chance.
FG% rows are pooled per team (t0 = Kings, t1 = city crew).

| Twist (city) | Kings win on / off | Point share on / off | Length on / off (min) | What it should do | Measured (on vs off) | Both teams the same? |
|---|---|---|---|---|---|---|
| wind (Chicago) | 72% / 62% | 56.2 / 52.3 | 5.87 / 5.77 | long shots -8% at full gust; lobs drift | Long-shot FG% 24.1% vs 27.1% (320 / 325 tries), -3 points. The set amount predicts about -1.6 points (-8% of 27% x a mean gust of about 0.75), and the gap is inside the noise. 1.47 lobs a game drift; 0.11 a game blown out of reach | Kings 26.3 vs 25.9, city 22.0 vs 28.5. Neither difference is real, and each team's long shots get the same hook. Overall FG% Kings +2.9, city -3.7, both inside the noise |
| crowd (Memphis) | 62% / 62% | 52.5 / 53.4 | 5.86 / 5.93 | 18 s clock, +4% speed, a faster game | Possessions per minute 6.27 vs 6.03 (+4%, REAL). Shots per minute +2% (noise). **0 shot-clock violations**. Length unchanged | turbo, FG%, points: all inside the noise for both |
| humid (New Orleans) | 75% / 68% | 55.3 / 55.3 | 5.26 / 5.38 | stamina refills 30% slower | **No player ran empty in any game, on or off.** Turbo 14.9 / 14.6 vs 15.5 / 15.5 s per minute (Kings / city; city -0.88 REAL). Shots per minute -6.5% (REAL) | Turbo is down for both (-0.60 and -0.88). OOB went up (+0.62, REAL), almost surely chance: humid doesn't touch the ball |
| thin air (Denver) | 62% / 55% | 52.2 / 53.1 | 5.38 / 5.34 | long shots +8%, lobs hang, stamina drains 20% faster | Turbo -1.04 (Kings) and -1.27 (city) s per minute, both REAL: you tire faster. 1.47 lobs a game take the longer flight. Long-shot FG% 32.1% vs 31.1% (346 / 312 tries): +8% is too small to see on 40 games | yes: turbo drops by the same amount on both sides |
| wet (Seattle, after tuning) | 58% / 54% | 51.5 / 51.5 | 5.39 / 5.60 | hard cuts slide | 38.3 slides a game to 11 (7.2 per minute), split 18.6 / 19.7. Seattle 2: 50, Seattle 3 (to 21): **67.9** (49-97). Turbo +0.9 / +0.7 s per minute | yes: slides split evenly; points, FG% and steals inside the noise |
| sand (Los Angeles) | 54% / 62% | 51.0 / 52.1 | 5.83 / 5.51 (+6%, not REAL) | everyone slower, turbo matters more; longer games | Shots per minute 7.08 vs 7.99 (-11%, REAL). Possessions per minute 5.79 vs 6.21 (-7%, REAL). Turbo use 15.1 / 15.2 vs 15.7 / 15.3 (no rise). LA's games to 21 average 11.9 min against 10.4-10.7 in the other late cities | yes: FG%, points and turbo inside the noise for both |
| cage (New York QF) | 61% / 61% | 50.2 / 52.8 | 10.40 / 11.10 | no sideline out of bounds; ball off the fence | Sideline OOB 0.00 vs 0.50 a game (REAL). 0.61 fence bounces a game (REAL). Total OOB 1.28 vs 2.22 | OOB is down for both teams (Kings -0.39, city -0.56) |

**Fairness:**
- No twist moves the win share (every gap is under its noise limit of 20-33 points) or the point share (every gap is
  under 4 points, limit 5).
- Each hook ignores the team, and the per-team numbers agree with that.

**Strength against "noticeable but fair":**
- **Wet:** was far too strong (about 500 slides a game). Tuned, see section 4.
- **Sand:** the pace drops clearly (shots -11%) and the games run longer, but only +6% on game 1 and about +1 min
  on the boss game. That isn't "far off", so I left it. To make it more visible, the next step would be `speed_mult`
  0.9 -> 0.88 in `twists.gd`. CPU turbo use doesn't go up (the CPU's turbo choice doesn't read the twist); a human
  feels the bigger boost.
- **Crowd and humid are mild in CPU games.**
  - The CPU shoots well inside 18 s, so the shorter clock never runs out.
  - The CPU never empties stamina, so a slower refill barely shows.
  - Both are felt by a human: the shot clock on screen, and stamina when he sprints a lot.
  - I'd leave them. If the lead wants more: `stamina_refill_mult` 0.7 -> 0.6, or `shot_clock` 18 -> 16.
- **Thin air and wind** do about what their numbers say.
- **Cage** removes sideline turnovers (about half of all OOB).

## 4. P6-30: wet court tuning (applied)

Probes: Seattle 1 played to 21 (`--target 21`), 2 games per setting, 0.42 grip throughout.

| cut_min_speed | cut_angle_deg | SLIDE_MIN_WANT | Slides per game (2 games) | per minute |
|---|---|---|---|---|
| 0.8 | 60 | 0.5 (as built) | 453, 554 | 52-54 |
| 0.9 | 100 | 0.8 | 267, 342 | 26-27 |
| 0.85 | 90 | 0.7 | 245, 321 | 32-35 |
| 1.0 | 120 | 0.9 | 151, 209 | 13-15 |
| 0.95 | 135 | 0.9 | 232, 244 | 17.5 |
| 1.1 | 120 | 0.8 | 20, 25 | 2.2-2.4 |
| 1.0 | 135 | 0.9 | 173, 140 | 12-14 |
| 1.03 | 120 | 0.9 | 24, 14 | 2 |
| 0.97 | 150 | 0.95 | 57, 71 | 5.1-5.4 |
| **0.9** | **150** | **0.9** | **78, 69** | **6.3-6.5** |
| 0.9 | 165 | 0.9 | 56, 40 | 4.1-4.8 |

**Applied:**

| Constant | File | Was | Now |
|---|---|---|---|
| `"cut_min_speed"` (wet) | `scripts/twists.gd` | 0.8 | 0.9 |
| `"cut_angle_deg"` (wet) | `scripts/twists.gd` | 60.0 | 150.0 |
| `SLIDE_MIN_WANT` | `scripts/player.gd` | 0.5 | 0.9 |

`cut_grip` stays 0.42. `DEFAULTS` in twists.gd and the hook defaults are unchanged, so with any other twist nothing
slides.

**Why these values:**
- A slide now needs a near reversal (150 degrees or more) at 90% of top speed or more, while still pushing the new
  way at 90% or more.
- A ball handler's full stick is 0.94 x top speed. The `SLIDE_MIN_WANT` and `cut_min_speed` values stay under 0.94,
  so a human handler still slides on a hard reversal without sprinting.
  - At 0.95 or 1.0, he could only slide while on turbo.
  - Above 1.0, only turbo players slid (2 a minute).
- Slide counts with these values:

  | Runs | Slides a game | Split (Kings / city) |
  |---|---|---|
  | 40 Seattle 3 games to 21 | **67.9** (49-97) | 34.8 / 33.1 |
  | 40 Seattle 2 games to 15 | 50.4 | 24.7 / 25.7 |
  | 40 Seattle 1 games to 11 | 38.3 | - |
  | 2 Seattle boss humantests | 94 and 87 | the scripted human slid **8 and 9 times**; slide time about 12 s a game |

- That is inside the asked 60-150, toward the low end. If the owner finds it too subtle: `cut_angle_deg` 135 with
  `cut_min_speed` 0.95 gave about 240 a game, so try 140-145 first.
- With the tuning, wet changes no team stat beyond the noise (section 3).

## 5. P6-31: animation

### 5.1 `--anim-test`

- `631be3f` + tuning: **ANIM OK**.
  - `0 v1 sheets, 68 v2 sheets (v2: 237 columns, 8 pages)`, 29 animations.
  - Every sheet and `_crew` recolor: 1,185 frames, 0 empty, 0 without points.
  - `SHEETS OK`.
  - The three `WARNING: Sheets:` lines come from the self-test's deliberately bad test sheets (`bad_v2`, `test_rgba`,
    `test_gray`).
- `6412667` gave the same result (plus its v1 sheets).

### 5.2 Animation counters per game (stats JSON, all city games of section 2 plus 20 Quick Game autoplay)

| Games | n | min | dunk tries | made | one | two | windmill | tomahawk | alley | rim hangs | ankle-breakers | chest | bounce | lob | passes | camera punches |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| City, to 21 | 400 | 10.7 | 24.7 | 11.3 | 7.5 | 5.0 | 4.4 | 5.0 | 2.9 | 11.0 | **2.56** | 61.9 | 33.3 | 3.3 | 98.5 | 6.8 |
| City, to 15 | 200 | 7.8 | 18.5 | 8.5 | 6.0 | 4.2 | 2.1 | 4.0 | 2.3 | 8.2 | 1.95 | 44.3 | 24.2 | 2.7 | 71.2 | 4.8 |
| City, to 11 | 280 | 5.6 | 12.8 | 5.9 | 4.3 | 3.0 | 1.2 | 2.8 | 1.5 | 5.6 | 1.49 | 31.8 | 17.0 | 1.8 | 50.6 | 3.0 |
| Quick Game (final build) | 20 | 10.9 | 25.5 | 10.6 | 9.1 | 4.9 | 1.9 | 6.3 | 3.5 | 10.4 | 2.25 | 60.9 | 36.2 | 4.1 | 101.2 | 6.3 |

- **Dunk style mix**, games to 21: one-hand 30%, two-hand 20%, windmill 18%, tomahawk 20%, alley 12%. Every dunk
  try gets a style (9,891 styles for 9,891 tries over all city games). Windmills grow with the finishing ratings:
  9% in games to 11, 18% in games to 21, 7% in Quick Game.
- **Rim hangs:** 97% of made dunks (4,386 / 4,509). This is the designed 0.3 s hang after every made dunk; a dunk
  blocked at the rim doesn't hang.
- **Ankle-breakers** (target 1-3 a game):
  - Games to 21: mean 2.56, range 0-8. Distribution: 0: 37, 1: 88, 2: 83, 3: 82, 4: 58, 5: 30, 6: 15, 7: 6, 8: 1.
  - Of 400 games, 63% are in 1-3, 9% have none and 28% have 4 or more. Quick Game: 2.25.
  - In range on the mean. `ANKLE_BREAK_PCT` 30 -> 25 would bring it to about 2.1 if the owner sees too many.
- **Bounce passes:** 34% of passes (62% chest, 3-4% lob). A third of all passes is a lot of bounce passes for "a
  defender in the lane or a short pass". It's a visual pick only, so the owner can judge it in play. Fewer: tighten
  the pick in `ball.gd`'s `pass_look()`, a code change, not filed as a bug.
- **Wet court visuals:** `twist_fx_slide_sprays` = the slide count, one spray per slide.

### 5.3 Animation must not move a stat

**Humantest (Quick Game, Hard).** On the final build, Quick Game draws v2 sheets. On `6412667` it still drew v1.

| Totals | Final build (18 runs) | 6412667, v1 in Quick Game (12 runs) | P6-00 (6 runs) | P5-16 pool (12) |
|---|---|---|---|---|
| Timed steals | 225/279 (81%) | 149/184 (81%) | 81/95 (85%) | 151/176 (86%) |
| Random steals | 94/588 (16%) | 58/381 (15%) | 39/198 (20%) | 71/361 (20%) |
| Timed blocks | 53/96 (55%) | 41/73 (56%) | 26/43 (60%) | 39/61 (64%) |
| Early-jump blocks | 24/123 (20%) | 21/93 (23%) | 11/49 (22%) | 18/81 (22%) |
| Guarding in front | 35-76% | 28-68% | 52-67% | 46-68% |
| Beaten / spells | 187/1178 | 103/817 | 60/415 | 116/749 |
| Assist frames (mean per run) | 3344 | 3301 | 3397 | 3060 |
| CPU crossovers beat him | 20/35 | 20/32 | 7/15 | 17/29 |
| Shot-clock violations / side switches | 0 / 1 every run | 0 / 1 every run | 0 / 1 | 0 / 1 |

- The first 6 final-build runs gave timed steals 71/96 (74%). I ran 12 more on the final build and 6 more on
  `6412667` to check. Both builds came to exactly 81%, so the first 6 were noise.
- The steal check reads `ball.position`, which comes from the sim (`facing`, `hand_x`), never from the drawn hand.
  Nothing in the drawing code writes `facing`, `velocity`, `position` or `hand_x`.
- Every rate is within a third of P6-00 and P5-16, and no counter dropped to 0.
- Per-run counters on the final build:
  - shots 60-99;
  - human steals 11-24;
  - human blocks 1-13;
  - human dunks 9-25;
  - alley-oop lobs 2-9;
  - rim hangs 7-16.

**Quick Game autoplay, final build, 20 games (vs P6-00's 200-game pool, limit = 2 x sqrt(SE^2 + SE^2)):**

| Stat | Final build, mean (SE) | P6-00 mean (SE) | Result |
|---|---|---|---|
| Length | 10.90 (0.46) | 11.22 (0.13) | ok |
| Loser points | 16.10 (0.76) | 15.78 (0.23) | ok |
| Shots | 87.0 (3.3) | 87.8 (1.1) | ok |
| FG% | 35.2 (1.1) | 35.7 (0.35) | ok |
| Dunks | 25.5 (0.9) | 25.6 (0.5) | ok |
| Layups | 25.2 (1.3) | 25.5 (0.4) | ok |
| Steals per 60 shots | 6.28 (0.61) | 6.94 (0.19) | ok |
| Blocks per 60 shots | 7.07 (0.37) | 6.76 (0.14) | ok |
| Fouls | 2.90 (0.42) | 3.77 (0.13) | ok, just (diff 0.87, limit 0.88) |
| OOB | 2.05 (0.29) | 2.42 (0.12) | ok |
| Interceptions | 3.75 (0.51) | 3.87 (0.14) | ok |
| Crossovers | 26.9 (2.2) | 26.1 (0.5) | ok |
| Lobs | 3.35 (0.41) | 3.58 (0.12) | ok |
| Shot-clock violations / side switches | 0 / 1 | 0 / 1 | ok |
| BLUE wins | 12/20 | 100/200 | ok |

No stat crosses the line. Fouls come closest (2.90, just inside the limit on 20 games), so P6-40's 200-game run
should watch them. Fouls are sim-only (rules.gd), and no Phase 6 animation code touches them.

### 5.4 Screenshots (xvfb, 1280x720)

What I took:
- `--shots` and `--twistshots` for Seattle, Los Angeles, New York, Memphis and Denver (boss games);
- `--twistshots` for New Orleans and Chicago;
- `--ballshots` for Seattle and Quick Game;
- `--shots --humantest` for Quick Game and Memphis;
- in Chromium, a Quick Game on the final build.

What I checked:
- **HUD:** readable on every court: FIRST TO 21, crew names with the possession arrow, SHOT clock, pause.
- **Nothing off screen.** The twist banner sits under the top bar, clear of the HUD. The "SEATTLE - GAME 3 OF 3"
  label draws below it.
- **Touch buttons:** the joystick, PASS / SHOOT and STEAL / SWITCH stay in the corners, clear of the play.
- **Running dribble:** the ball is low and to the side, and doesn't cover the legs (Seattle, LA, New York).
- **At the rim:** the Seattle `--ballshots` rim shot has the ball at the rim above the player's raised hands. None
  of my frames caught a dunk at the moment of the slam; the rim-hang and dunk-style counters (5.2) show they run.
- **Held ball:** in the dribble and handler shots the ball is at the dribbling hand. I didn't look at a catch frame
  closely.
- **Far heads under the HUD:** players at the far sideline keep their heads below the top bar on every court. The
  highest head was about y = 185 on the Memphis crowd court, with the bar ending about y = 55.
- **Twist effects:** all visible: rain and puddle splashes in Seattle, sand drifts in LA, breath puffs in Denver,
  wavy heat lines in New Orleans, the fence in New York, the crowd in Memphis.
- **BALL! popup:** readable over the caller's head, above the CALL bubble (Quick Game humantest). In one shot it is
  clipped at the screen edge (bug 1).
- **Chromium, final build:** v2 indexed (L8 + palette) sheets draw in the right colors in WebGL2: blue/gold Kings
  and red/black Bridge Runners.

## 6. P6-31: web build, fps, texture memory

| | Phase 5 (`4675878`) | 6412667 | **Final (`631be3f` + tuning)** |
|---|---|---|---|
| `index.pck` | 5,454,544 | 43,387,840 | **34,181,680 (32.6 MiB)** |
| `index.wasm` | 35,376,909 | 35,376,909 | 35,376,909 |

**What is in the final pck** (by source folder):
- `assets/players2` textures: 20.2 MB (376 files);
- `players2/hands.json`: 1.7 MB;
- music: 6.2 MB;
- portraits: 4.7 MB;
- the rest is under 0.7 MB.

P6-25 took out the 8.8 MB of v1 textures and the 0.37 MB v1 `hands.json`.

**Against the owner's budget:** the owner OK'd "about 31 MB for the web download". The pck is 34.2 MB (32.6 MiB),
about 3 MB over if that figure was the pck. gzip doesn't help (the pck is PNG data: the `6412667` pck gzips
from 43.4 to 40.4 MB). The wasm is 35.4 MB raw and about 8 MB gzipped, as before. If the 3 MB matters, `hands.json` (1.7 MB of
text) is the easiest cut.

**fps.** Same method as P4-12 / P6-00:
- Playwright Chromium 1243, headless, SwiftShader (`--use-angle=swiftshader --enable-unsafe-swiftshader
  --ignore-gpu-blocklist`);
- 1280x800, `hasTouch` + `isMobile`, `python3 -m http.server`;
- `auto.html` = `index.html` with `"args": ["--", "--autoplay", "--fps"]` (plus `--texmem` on the Phase 6 build);
- a 12 s wait, then 3 x 5 s requestAnimationFrame counts;
- a new browser per run, order A/B/A/B.

| Session | Load average | Phase 5: rAF fps (in-game FPS lines) | Phase 6 final: rAF fps (FPS lines) |
|---|---|---|---|
| 1 (machine busy with my batches) | 10-12 | 6.9 / 8.2 / 7.9; 7.9 / 9.2 / 10.6 (7-12) | 7.8 / 5.5 / 7.6; 6.5 / 8.9 / 9.7 (6-10) |
| **2 (idle)** | 0.9-3.6 | **15.6 / 15.6 / 15.8; 16.7 / 16.2 / 16.1** (14-17) | **15.3 / 14.9 / 16.5; 16.0 / 15.4 / 15.5** (14-16) |

- On the idle session: **Phase 5 16.0 fps, Phase 6 15.6 fps (-2.5%)**, inside the run-to-run spread.
- The busy session gives 8.5 vs 7.7 (-9%) under heavy, uneven load.
- Time to the first in-game `FPS` line: 6.7-6.9 s for Phase 5, 7.4-7.6 s for Phase 6 (the bigger pck).

**Texture memory** (`--texmem`, 2 s into the game, 6 v2 indexed sheets on court):
- Chromium Quick Game: **texture 64.4 MB, video 88.9 MB**. The busy session read 64.3-68.0 / 88.7-92.5.
- Godot xvfb, Seattle boss game: texture 64.5 MB, video 76.8 MB.
- The board's estimate was about 90 MB of textures with RGBA sheets. The indexed v2.1 pages land at about 64 MB in
  total, court and HUD included.
- The JS heap is 51 MB for Phase 6 against 17-21 MB for Phase 5.

**Console:**
- **No console errors** and no page errors in any run.
- The only WebGL messages are SwiftShader's `GPU stall due to ReadPixels` performance notes, which appear in both
  builds.
- **No WebGL issue with the L8 textures:** the indexed sheets load (TEXMEM lists every player as `v2,indexed`) and
  draw in the right palette.

## 7. Bugs

1. **BALL! popup can be clipped at the screen edge** (minor, visual; filed on the board).
   - Steps: `xvfb-run ... -- --shots --humantest --city memphis --cgame 3 --expected-roster --shots-dir DIR`, then
     look at `hoops_call_cue.png`.
   - Expected: the popup moves inside the screen, like the other popups.
   - Actual: it is drawn at the caller's head while he stands at the right edge of the view, and shows as "BA" cut
     off at x = 1280. `human_input.gd:227` places it with `fx.popup_head` at the head position with no clamp.
2. Not a bug, a test-tool note for the lead: **`--expected-roster` never starts a recruit and gives every point to
   Deuce** (it does what the board says). The ramp it measures is a lower bound from Chicago on (section 1). A
   variant that starts the best 3 would measure what a sensible player meets.

No crashes, stuck players, stuck balls, never-ending games or shot-clock violations in 1,212 runs.

## 8. Tuning summary and suggestions

**Applied** (committed with this report):

| Constant | File | Was | Now | Why |
|---|---|---|---|---|
| wet `"cut_angle_deg"` | `scripts/twists.gd` | 60.0 | 150.0 | slides only on a near reversal |
| wet `"cut_min_speed"` | `scripts/twists.gd` | 0.8 | 0.9 | at speed only |
| `SLIDE_MIN_WANT` | `scripts/player.gd` | 0.5 | 0.9 | a real push the new way; a handler's full stick (0.94) still qualifies |

Result: about 68 slides a game to 21 (was about 500), even between the teams, 8-9 for the human.

**Suggested, not applied** (lead or owner to decide; each needs a 100-game check):
- `STAGE_AVG[5]` 58 -> 56 (`cities.gd`), only if Denver's boss game must be over 40% for the `--expected-roster`
  crew (section 2.4).
- Sand `speed_mult` 0.9 -> 0.88, if LA should be measurably longer even on game 1 (now +6%, +1 min on the boss).
- Humid `stamina_refill_mult` 0.7 -> 0.6, or crowd `shot_clock` 18 -> 16, only if they should show in CPU play too.
  For a human they already show.
- `ANKLE_BREAK_PCT` 30 -> 25 (`player.gd`), if the owner sees too many falls (28% of games have 4 or more).
