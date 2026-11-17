# P5-16 Phase 5 QA

Build tested: dev at `0e8e1e7` ("Title: CONTINUE detects the saved trip and resumes at the right screen; finished trips
show CHAMPIONS"), branch `ccr-f5c087b2-3ojk5f`, in a separate worktree on branch `qa-p5-16`. Godot 4.3 stable (Linux).
Import is clean: no script error or parse error. No game, trip test or screen run printed a script error; the only
`ERROR` lines are the ALSA audio-device lines under xvfb (no sound card here) and one "4 resources still in use at
exit" line at the end of a `--shots` run.

**Summary:** the whole Road Trip runs end to end (3 trip tests + stop/resume, all `TRIP END`); Quick Game is
unchanged from the P5-00 baseline (100 games: 1 stat of 40 over the line, the pooled 200: none); every Normal city game
is between 60% and 70% for a CPU-controlled crew; the web build plays the flow by touch, pause works and the save
survives a reload. Findings: the city ramp is flat (game 1 is not clearly easier than the boss game), the
`--difficulty` flag does nothing in `--city` games (test-only bug), two small text clips, and a dead CONTINUE button
on a finished trip. No tuning applied (section 6).

## 1. Commands

```
godot --headless --path . --import
# trip tests (one after another: they share user://trip_test.json)
godot --headless --path . --fixed-fps 60 --quit-after 3000000 -- --trip-test                       # full length
godot --headless --path . --fixed-fps 60 --quit-after 3000000 -- --trip-test --target 5 --trip-force-loss 2
godot --headless --path . --fixed-fps 60 --quit-after 3000000 -- --trip-test --target 5 --trip-stop-after hometown
godot --headless --path . --fixed-fps 60 --quit-after 3000000 -- --trip-test --target 5 --trip-resume   # new process
# Quick Game: 2 x 100 autoplay, 6 + 6 humantests (Hard, ANGLED)
seq 1 100 | xargs -P 6 -I{} sh -c "godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay > runs/a{}.txt 2>&1"
godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --humantest
# campaign: 40 games each, Normal (the --city default)
godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --autoplay --city hometown --cgame 1   # ... 1..3, chicago 1..3
godot --headless --path . --fixed-fps 60 --quit-after 120000 -- --humantest --city hometown --cgame 1  # 6 each: ht 1, ht 3, chi 3
# screens (also with -screen 0 1280x800x24 and --resolution 1280x800)
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- --trip-test --target 3 --screens
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- --shots --city chicago --cgame 3
tools/build_web.sh
```

Note: a full-length `--trip-test` needs more than 400000 frames (one run at `--quit-after 400000` stopped in the New
York semifinal, exit 0 and no `TRIP END` line); the full trip below took 16 games and about 2.4 hours of game time.
`trip_test.gd`'s own example (`--quit-after 2000000`) is right.

## 2. Trip tests

| Run | Flags | Games | Record | Result | Script errors |
|---|---|---|---|---|---|
| 1 | full length (11 / 15 / 21, tournament 21) | 16 | 9-7 | `TRIP END ... complete`, 58 screens | none |
| 2 | `--target 5 --trip-force-loss 2` | 16 | 9-7 (game 2 forced) | `TRIP END ... complete` | none |
| 3a | `--target 5 --trip-stop-after hometown` | 3 | 3-0 | `TRIP STOP after hometown`, saved: city chicago game 1 phase map | none |
| 3b | `--target 5 --trip-resume` (new process) | 20 | 9-14 total | `TRIP resume` at chicago game 1 / map / 3-0 / recruit ht_g1 kept; `TRIP END` | none |
| extra | `--target 3 --screens` x 4 (720 and 800, xvfb) | 9 each | 9-0 | `TRIP END` | none |

Run 1, game by game (CPU vs CPU: the trip test sets `main.autoplay`, so your crew plays with the Hard knobs, the city
crew with Normal):

| # | Game | Result | Length |
|---|---|---|---|
| 1-2 | Hometown 1 (to 11) | L 10-11, W 11-10 | 4:54, 3:42 |
| 3-4 | Hometown 2 (to 15) | L 8-15, W 15-12 | 5:56, 7:58 |
| 5 | Hometown 3 (to 21) | W 21-15 | 9:57 |
| 6-7 | Chicago 1, 2 | W 11-10, W 15-11 | 6:46, 8:21 |
| 8-9 | Chicago 3 | L 19-22, W 21-20 | 11:31, 11:28 |
| 10 | New York quarterfinal | W 21-12 | 9:22 |
| 11-13 | Semifinal | L 15-21, L 17-21, W 21-19 | 10:44, 10:03, 9:53 |
| 14-16 | Final | L 19-21, L 20-21, W 22-18 | 11:15, 10:30, 11:34 |

Checked: every loss went back to the lineup for the same game (the `first_loss` story played once, at the first
retry); a won game 3 went story `<city>_won` -> points -> recruit -> map; New York: `final_before` -> bracket ->
lineup -> game -> result -> points between rounds -> bracket; the final won -> `ending` -> title with the trip done.
All 8 story scenes were shown once each (`seen` in the save). The pick test (recruit + 2 underdogs) produced that team
in the next game. Each screen line printed `saved ok`.

Save file sanity (`user://trip_test.json`): after the stop, `city chicago, game 1, phase map, points 0, record 3-0,
beaten [hometown]`, 4 players, Deuce +6 points spent as 1/2/2/1 steps of +3 (52->55, 48->54, 48->54, 50->53),
`version 1`, `serial 18`. After the trip: `phase done, bracket round 3, beaten [hometown, chicago, new_york]`, 5 players,
all ratings at or under 90, `serial 78`. 2 stat points from the final win are left unspent (nothing to spend them on
after the ending; harmless).

## 3. Quick Game vs the P5-00 baseline

100 `--autoplay` games (Hard vs Hard, ANGLED, `Flow.match` empty): 100/100 reached `FINAL`, none hit `--quit-after`.
Compare rule from `docs/qa/phase5-baseline.md` section 5 (limit = 2 x sqrt(SE_base^2 + SE_new^2)). In the first 100
one stat crossed the line (fake bites, -0.81 vs 0.68), so I ran 100 more as the rule says; in the pooled 200 every stat
is inside its limit (fake bites -0.56 vs 0.62). Shot-clock violations 0, FT timeouts 0, side switches always 1.

| Stat | P5-00 (100) | P5-16 first 100: mean (SE) | min-max | diff | limit | | P5-16 pooled 200: mean (SE) | diff | limit | |
|---|---|---|---|---|---|---|---|---|---|---|
| BLUE points | 18.21 | 18.85 (0.31) | 10-22 | +0.64 | 0.92 | ok | 18.88 (0.21) | +0.66 | 0.80 | ok |
| RED points | 18.94 | 18.66 (0.27) | 10-22 | -0.28 | 0.87 | ok | 18.43 (0.23) | -0.51 | 0.82 | ok |
| Winner points | 21.13 | 21.07 (0.03) | 21-22 | -0.06 | 0.08 | ok | 21.09 (0.02) | -0.04 | 0.07 | ok |
| Loser points | 16.02 | 16.44 (0.26) | 10-20 | +0.42 | 0.82 | ok | 16.21 (0.19) | +0.19 | 0.75 | ok |
| Point diff (BLUE - RED) | -0.73 | 0.19 (0.53) | -11-11 | +0.92 | 1.60 | ok | 0.45 (0.40) | +1.18 | 1.44 | ok |
| Game length, minutes | 11.46 | 11.36 (0.18) | 7.77-17.08 | -0.10 | 0.54 | ok | 11.46 (0.13) | +0.00 | 0.48 | ok |
| Dead-ball seconds | 36.78 | 36.70 (0.44) | 27-50 | -0.08 | 1.29 | ok | 36.84 (0.31) | +0.05 | 1.13 | ok |
| Possessions | 70.43 | 69.27 (1.08) | 49-99 | -1.16 | 3.30 | ok | 69.86 (0.80) | -0.57 | 2.97 | ok |
| Passes | 107.87 | 105.75 (2.18) | 61-188 | -2.12 | 6.42 | ok | 108.25 (1.69) | +0.38 | 5.81 | ok |
| Shots | 91.05 | 89.45 (1.60) | 54-129 | -1.60 | 4.59 | ok | 90.08 (1.15) | -0.97 | 4.02 | ok |
| Shots BLUE | 44.09 | 42.88 (0.84) | 25-67 | -1.21 | 2.42 | ok | 43.66 (0.61) | -0.43 | 2.12 | ok |
| Shots RED | 43.54 | 42.85 (0.81) | 26-63 | -0.69 | 2.44 | ok | 42.91 (0.59) | -0.63 | 2.17 | ok |
| Makes | 31.14 | 31.32 (0.30) | 24-38 | +0.18 | 0.93 | ok | 31.25 (0.23) | +0.11 | 0.83 | ok |
| FG% (per game) | 34.95 | 35.83 (0.54) | 20-51.67 | +0.88 | 1.50 | ok | 35.48 (0.38) | +0.53 | 1.29 | ok |
| Dunks (tries) | 27.23 | 26.79 (0.64) | 11-44 | -0.44 | 1.82 | ok | 26.55 (0.46) | -0.68 | 1.59 | ok |
| Layups (tries) | 26.16 | 26.08 (0.63) | 10-44 | -0.08 | 1.87 | ok | 26.58 (0.43) | +0.42 | 1.62 | ok |
| 2s made | 4.41 | 4.37 (0.17) | 0-8 | -0.04 | 0.46 | ok | 4.38 (0.12) | -0.03 | 0.40 | ok |
| 2s share of points, % | 23.96 | 23.40 (0.91) | 0-48.48 | -0.56 | 2.53 | ok | 23.64 (0.66) | -0.32 | 2.19 | ok |
| Fouls | 3.86 | 3.74 (0.21) | 0-9 | -0.12 | 0.57 | ok | 3.70 (0.15) | -0.16 | 0.49 | ok |
| Fouls: shooting | 2.27 | 2.48 (0.15) | 0-6 | +0.21 | 0.42 | ok | 2.31 (0.11) | +0.04 | 0.37 | ok |
| Fouls: reach | 1.59 | 1.26 (0.15) | 0-7 | -0.33 | 0.40 | ok | 1.39 (0.10) | -0.21 | 0.34 | ok |
| And-ones | 1.01 | 1.29 (0.12) | 0-5 | +0.28 | 0.31 | ok | 1.07 (0.08) | +0.06 | 0.25 | ok |
| Free throws tried | 2.25 | 2.45 (0.15) | 0-6 | +0.20 | 0.42 | ok | 2.29 (0.11) | +0.04 | 0.37 | ok |
| Free throws made | 1.60 | 1.82 (0.12) | 0-5 | +0.22 | 0.36 | ok | 1.68 (0.09) | +0.08 | 0.31 | ok |
| FT timeouts | 0.00 | 0.00 (0.00) | 0-0 | +0.00 | 0.00 | ok | 0.00 (0.00) | +0.00 | 0.00 | ok |
| Out of bounds | 2.16 | 2.29 (0.16) | 0-9 | +0.13 | 0.44 | ok | 2.28 (0.11) | +0.12 | 0.37 | ok |
| Steals | 10.61 | 9.75 (0.34) | 1-17 | -0.86 | 1.04 | ok | 10.37 (0.26) | -0.24 | 0.94 | ok |
| Steals per 60 shots | 6.97 | 6.60 (0.22) | 0.79-11.61 | -0.37 | 0.64 | ok | 7.00 (0.18) | +0.03 | 0.58 | ok |
| Blocks | 10.67 | 11.20 (0.39) | 3-22 | +0.53 | 1.10 | ok | 11.12 (0.27) | +0.45 | 0.95 | ok |
| Blocks per 60 shots | 6.96 | 7.44 (0.20) | 2.57-12.13 | +0.48 | 0.56 | ok | 7.36 (0.14) | +0.40 | 0.48 | ok |
| Crossovers | 26.83 | 27.13 (0.69) | 13-43 | +0.30 | 1.93 | ok | 27.24 (0.48) | +0.41 | 1.65 | ok |
| Crossover beats | 10.23 | 10.22 (0.37) | 2-20 | -0.01 | 1.03 | ok | 10.66 (0.26) | +0.43 | 0.89 | ok |
| Pump fakes | 11.84 | 11.52 (0.36) | 2-22 | -0.32 | 1.05 | ok | 11.59 (0.27) | -0.25 | 0.94 | ok |
| Fake bites | 5.14 | 4.33 (0.22) | 0-12 | -0.81 | 0.68 | FAIL | 4.58 (0.17) | -0.56 | 0.62 | ok |
| Lobs | 3.92 | 3.79 (0.17) | 1-9 | -0.13 | 0.50 | ok | 3.84 (0.13) | -0.08 | 0.45 | ok |
| Alley-oop makes | 1.73 | 1.75 (0.12) | 0-5 | +0.02 | 0.38 | ok | 1.71 (0.09) | -0.02 | 0.35 | ok |
| Interceptions | 3.72 | 3.88 (0.20) | 0-11 | +0.16 | 0.57 | ok | 3.85 (0.15) | +0.13 | 0.50 | ok |
| Shot-clock violations | 0.00 | 0.00 (0.00) | 0-0 | +0.00 | 0.00 | ok | 0.00 (0.00) | +0.00 | 0.00 | ok |
| Side switches | 1.00 | 1.00 (0.00) | 1-1 | +0.00 | 0.00 | ok | 1.00 (0.00) | +0.00 | 0.00 | ok |
| Lead changes | 2.22 | 1.95 (0.17) | 0-7 | -0.27 | 0.52 | ok | 1.96 (0.12) | -0.26 | 0.45 | ok |

Pooled rates (200 games): FG% 34.7% (6249/18015; baseline 34.2%), FT% 73.4% (336/458; 71.1%), crossover beat 39.2%
(38.1%), fake bite 39.5% (43.4%). Winner scored 21 in 181/200 (22 in the rest), loser 12-20 in 193/200, 45 games
under 10 min, 5 over 15. **BLUE wins: 57/100 in the first batch, 54/100 in the second, 111/200 = 55.5% (SE 3.5)**:
inside the noise band (P5-00 had 43/100; all builds pooled 245/500 = 49%). `--ratingtest`: every helper returns
exactly 1.0 at rating 50.

### Humantest (Quick Game, Hard)

12 runs (two batches of 6; the rule says flag a rate that moves by more than a third): all reached `FINAL`, 0
shot-clock violations. BLUE (scripted human) won 5/12.

| Totals | Batch 1 (6) | Batch 2 (6) | Pooled 12 | P5-00 (6) |
|---|---|---|---|---|
| Timed steals | 77/95 (81%) | 74/81 (91%) | 151/176 (86%) | 72/90 (80%) |
| Random steals | 38/203 (19%) | 33/158 (21%) | 71/361 (20%) | 30/165 (18%) |
| Timed blocks | 29/34 (85%) | 10/27 (37%) | 39/61 (64%) | 13/36 (36%) |
| Early-jump blocks | 12/45 (27%) | 6/36 (17%) | 18/81 (22%) | 3/46 (7%) |
| Guarding in front | 50-68% | 46-65% | 46-68% | 39-67% |
| Beaten / spells | 66/423 | 50/326 | 116/749 | 56/353 |
| Assist frames (mean per run) | 3306 | 2813 | 3060 | 3013 |
| CPU crossovers beat him | 10/17 | 7/12 | 17/29 | 3/7 |

Batch 1's timed blocks (85%) moved by more than a third, batch 2 (37%) is back on the baseline. Phase 4 already saw
70% and 41% between batches, so this is noise on 30-odd tries, not a change. Per run (mean of 12): shots 74.6 / makes
31.8, human steals 18.5 of 44.8 pokes, human blocks 5.8 of 16.9 jumps, crossovers 35.2 / beats 5.8, pump fakes 17.8 /
bites 4.9, dunks 16.6 / layups 4.9, lobs 4.4 / catches 3.3, fouled 1.0 / FT 0.8, interceptions 5.4, OOB 1.6. No counter
dropped to 0.

## 4. Campaign balance (Normal)

How `--autoplay --city <id> --cgame N` sets the sides (read in `difficulty.gd`, `trip.gd`, `main.gd`, and checked in
the stats JSON and the `MATCH` line):
- **BLUE = your crew** (Cornfield Kings, the 3 underdogs at their starting ratings: Deuce, Jojo, Tank; no stat points,
  no recruits), **played by the CPU with the Hard knobs**. `Difficulty.value()` returns the Hard value for team 0 on
  every level, so the level never touches your side.
- **RED = the city crew** at `STAGE_AVG[stage] + TIER` ratings, with the crew's style and the **Normal** knobs
  (`trip.DEFAULT_LEVEL`, since `--city` has no trip loaded).
- So the win share below is "Hard-knob CPU crew vs Normal city crew", i.e. ratings + level, not a human. It is an
  upper bound for a weak player; the humantest rows show the other end.

| City game | To | Games | Kings win % (SE) | Length mean (min-max) | Score (Kings - city) | Loser pts (range) | Point share | Shots | Fouls | OOB | SCV |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Hometown 1 (1 good + 2 avg, 40) | 11 | 40 | 68% (7) | 5.5 (3.2-9.3) | 10.0 - 8.2 | 7.2 (3-10) | 54.9% | 43 | 1.4 | 1.3 | 0 |
| Hometown 2 (2 good + 1 avg) | 15 | 40 | 65% (8) | 8.0 (5.1-11.1) | 13.3 - 12.6 | 10.8 (6-14) | 51.5% | 63 | 2.1 | 1.4 | 0 |
| Hometown 3 (2 good + boss 60) | 21 | 40 | 68% (7) | 11.0 (7.4-14.4) | 19.6 - 16.9 | 15.4 (5-20) | 53.7% | 89 | 3.8 | 2.4 | 0 |
| Chicago 1 (stage 45) | 11 | 40 | 70% (7) | 5.5 (3.7-8.7) | 9.9 - 8.4 | 7.3 (1-10) | 54.0% | 46 | 1.9 | 1.3 | 0 |
| Chicago 2 | 15 | 40 | 62% (8) | 7.8 (5.5-11.0) | 13.9 - 12.5 | 11.2 (5-14) | 52.6% | 63 | 2.6 | 1.9 | 0 |
| Chicago 3 (boss 65) | 21 | 40 | 60% (8) | 10.7 (6.7-17.0) | 19.4 - 18.1 | 16.5 (9-20) | 52.0% | 86 | 3.8 | 2.6 | 0 |

(Chicago 3 with the 20 extra games from section 4.1, which also played Normal: 38/60 = 63%.) All 240 games reached `FINAL`; no
shot-clock violations; one side switch each; no game near `--quit-after`.

**Length.** Games to 11: mean 5.5 min, 31/80 under 5 min, 46 in 5-8, 3 over 8. To 15: 7.9 min (5.1-11.1). To 21: 10.8
min (6.7-17.0), like Quick Game. The board's "about 5-8 min" for a game to 11 holds for the mean but 4 in 10 games
are a bit shorter. **Proposed campaign targets for the lead to confirm:** to 11: 4-8 min (mean ~5.5), 35-50 shots,
0-3 fouls, about 1 OOB; to 15: 6-10 min, 55-70 shots, 1-4 fouls; to 21: as Quick Game (9-13 min, 75-120 shots, 2-6
fouls, 2-3 OOB).

**Ramp.** Board target for Phase 5: game 1 easier than game 3, no city game below about 30% for a CPU-controlled BLUE.
- No game is below 30% (lowest 60%): **pass**.
- Hometown: 68% / 65% / 68%: **no ramp** (fail). Chicago: 70% / 62% / 60%: the right direction but inside the noise
  (SE 7-8 pts). Point share drops a little from game 1 to game 3 in both cities (54.9 -> 53.7, 54.0 -> 52.0), so the
  stronger crews do cost something, but the longer boss game (to 21) gives the better side more chances to win, which
  cancels it. The level gap (Hard knobs for your side, Normal for theirs) is worth more than the +20 boss.
- With the scripted human (`--humantest --city`, 6 each, your human controls Deuce): Hometown 1 1/6 (6.5 - 10.2 avg),
  Hometown 3 1/6 (16.3 - 21.0), Chicago 3 0/6 (16.2 - 21.2). The scripted human also wins only 5/12 against Quick
  Game Hard RED, so this mostly says the bot is weak, but it means none of the city games is a walkover for a player
  who plays like it.

### 4.1 Easy and Hard spot checks

**Bug found first:** `--difficulty easy|hard` is ignored in a `--city` game. `Difficulty.effective_level()` returns
`Flow.match.level` whenever a match is set, and `Trip.match_for()` always sets `"normal"` without a loaded trip, so the
flag only changes the saved level. The 20 games I first ran with `--difficulty easy/hard` printed `MATCH ... level
normal` and `"difficulty_normal": 1` (they are counted as Normal above). For the spot checks I used a throwaway copy
of the project (not committed) with `trip.gd` `DEFAULT_LEVEL` set to `"easy"` or `"hard"` (the `MATCH` line and the
stats key confirm the level):

| Boss game | Level | Games | Kings win % (SE) | Length | Score | Loser pts (range) |
|---|---|---|---|---|---|---|
| Hometown 3 | Easy | 10 | 80% (13) | 10.4 (8.2-13.4) | 20.4 - 15.7 | 15.1 (8-20) |
| Hometown 3 | Normal | 40 | 68% (7) | 11.0 | 19.6 - 16.9 | 15.4 (5-20) |
| Hometown 3 | Hard | 10 | 70% (14) | 10.9 (8.4-15.4) | 20.3 - 17.0 | 16.3 (11-20) |
| Chicago 3 | Easy | 10 | 80% (13) | 10.5 (7.1-12.7) | 20.2 - 16.2 | 15.4 (7-20) |
| Chicago 3 | Normal | 40 | 60% (8) | 10.7 | 19.4 - 18.1 | 16.5 (9-20) |
| Chicago 3 | Hard | 10 | 60% (15) | 10.4 (8.5-13.9) | 19.1 - 18.5 | 16.5 (9-20) |

Easy is easier; Normal and Hard can't be told apart on 10 games (SE 14-15). On Hard both sides use the same knobs, so
the Kings' 60-70% there is the rating edge of the three underdogs (avg ~51) over Hometown (good 44/56, boss 60) and
Chicago: the ratings move the result less than the level knobs do.

## 5. Screens

Reviewed at 1280x720 and 1280x800 (xvfb `--screens` with a copy of `trip_test.gd` taking up to 60 shots per screen
name, 89 shots per size; the stock driver takes 2 per name and so never shoots the later story scenes, the ending,
the 5-player lineup or the CHAMPIONS title), plus `--shots --city chicago --cgame 3`, plus the web build at 1280x800
(title, settings, crew & credits, road trip panel, level pick, game, pause, result, CHAMPIONS panel).

| Screen | 720 | 800 | Notes |
|---|---|---|---|
| Title | ok | ok | road and sky fill the extra 80 px |
| Road Trip panel (CONTINUE / NEW TRIP / level pick) | ok | ok | status line readable; see bug 4 for a finished trip |
| Settings | - | ok (web) | MUSIC, SOUND slider, LEVEL; "LEVEL is for Quick Game and new trips" |
| Crew & credits | - | ok (web) | scroll list, big scroll bar; list stays 145-705 at 800 |
| Map | ok | ok | pins, labels, info box, GO dim while the van drives |
| Story (all 8 scenes) | ok | ok | comic portraits of Jojo, Deuce, Tank, Mayor, Nico, Big Lou, King, narrator lines; name tags, TAP >, SKIP |
| Lineup, 3 / 4 / 5 players | ok | ok | 5 cards fit without scrolling (bottom at 705 of 720); see bug 3 |
| Game (trip) | ok | ok | crew names in the top bar, pause button clear of SHOT, joystick and A/B clear of the play |
| Pause | - | ok (web) | score, stats table, RESUME, RESTART, QUIT, MUSIC, SOUND |
| Result (win, loss, CHAMPIONS!) | ok | ok | stats table, NEXT / RETRY, "+2 STAT POINTS" |
| Points | ok | ok | at 800 the screen stays in the top 720 (80 px empty below); fine |
| Recruit | ok | ok | 3 cards, NOW -> WITH YOU recolors, "X JOINS" banner |
| Bracket (3 rounds) | ok | ok | see bug 2 |
| Ending | ok | ok | 5 lines, then the title |
| CHAMPIONS on the title | ok (web) | ok (web) | "TRIP COMPLETE - CHAMPIONS! 9-14 - NORMAL - start a NEW TRIP to go again" in the Road Trip panel |

## 6. Web build (Chromium, touch)

`tools/build_web.sh` (no publish). **`index.pck` = 5,453,328 bytes (5.20 MiB)**, +1,743,072 (+47%) on P5-00's
3,710,256: the new player sheets, portraits and map (about 1.4 MB of new PNGs) and the screen scripts. Under the 12 MB
budget. `index.wasm` 35,376,909 (unchanged).

Playwright's Chromium 1243, headless, SwiftShader WebGL, 1280x800, `hasTouch` + `isMobile`, every tap a CDP
`Input.dispatchTouchEvent` (joystick drags too), a persistent browser profile, served with `python3 -m http.server`.
For a short game a copy of `index.html` passed `"args": ["--", "--target", "3"]` (same build files).

| Check | Result |
|---|---|
| Load to title | 2.1-5.5 s |
| Title -> ROAD TRIP -> NEW TRIP -> NORMAL -> story `trip_start` (TAP advances, SKIP) -> map -> GO -> story `hometown_arrive` -> lineup -> PLAY | pass |
| Game by touch (joystick drive + SHOOT taps): scored 2, lost 2-3; idle games lost 0-3 | pass |
| Pause: button top-right; RESUME; RESTART (two taps) restarts at 0-0; QUIT (two taps) -> map, the record unchanged | pass |
| Result (loss) -> RETRY -> story `first_loss` -> lineup | pass |
| Reload the page: title -> ROAD TRIP shows "HOMETOWN, GAME 1 - 0-1 - NORMAL"; CONTINUE -> map at game 1 (record kept) | pass |
| Finished trip (save written into IndexedDB `/userfs`): ROAD TRIP panel shows CHAMPIONS | pass (bug 4) |
| Console | no errors; only Chromium's "GPU stall due to ReadPixels" warning, caused by the screenshots |

One note: a QUIT confirm can time out if the second tap comes later than `pause.CONFIRM_TIME` (2.5 s); with a slow
screenshot between the taps my first try stayed on the pause screen. Expected behaviour.

## 7. Bugs

1. **`--difficulty` is ignored in `--city` games** (test flags; medium for QA). Steps: `godot --headless --path .
   --fixed-fps 60 -- --autoplay --city chicago --cgame 3 --difficulty easy`. Expected: RED plays Easy (`main.gd`
   `_apply_match_settings`: "a --difficulty flag wins, for tests"). Actual: `MATCH ... level normal`, stats
   `"difficulty_normal": 1`, because `difficulty.gd` `effective_level()` returns `Flow.match.level` before looking at
   the flag. Fix idea: in `effective_level()`, return `level` when `from_cmdline()` set it, or let `Trip.match_for()`
   use the flag's level when no trip is active. (In a real trip there is no flag, so players are not affected.)
2. **Bracket text clipped** (low). Steps: reach New York (`--trip-test --target 3 --screens`), first bracket.
   Expected: "WINNER OF THE QUARTERFINAL" in the semifinal box. Actual: "WINNER OF THE QUARTERF" (cut at the box edge),
   720 and 800. "WINNER OF THE SEMIFINAL" fits.
3. **Lineup header touches the right edge** (low). Steps: New York lineup. Actual: "NEW YORK - QUARTERFINAL" in the
   top-right runs to x = 1280 (the last letter is at the screen edge), 720 and 800. Longer Phase 6 labels will be cut.
4. **Dead CONTINUE on a finished trip** (low, touch). Steps: finish a trip, title -> ROAD TRIP. Expected: the gold
   default button does something (or NEW TRIP is the gold one). Actual: CONTINUE is gold, a tap does nothing
   (`title.gd` `_on_continue`: "a finished trip stays on the title"); only NEW TRIP works.
5. **`--screens` misses screens** (test tool, low). `SHOTS_PER_SCREEN := 2` per screen name: story scenes after the
   second, the ending, the CHAMPIONS title, the 5-player lineup; and settings, crew, pause and the game are not in the
   trip at all. Suggest a shot per story scene and a title shot before `TRIP END`.

Not bugs, for the record: after a loss, CONTINUE resumes on the map (GO -> lineup), not on the lineup; the van drives
from Chicago to New York along the roads through the "soon" cities (fine once Phase 6 builds them).

## 8. Tuning

**None applied.** The only balance item is the flat ramp, and constants in reach don't fix it:
- Owner-fixed: `TIER` (+12 / +20), `STAGE_AVG` (~40 rising), `CITY_TARGETS` (11 / 15 / 21).
- Experiment in a throwaway copy: `ratings.SHOOT_SPAN` 0.15 -> 0.25 and `FINISH_SPAN` 0.12 -> 0.20 (Normal, 30 games
  each): Hometown 1 60% (SE 9), Hometown 3 60%, Chicago 3 63%. Still flat (point share 52.2% / 51.2% / 53.6%), so wider
  spans alone don't make a ramp, and they would make New York (avg 70, boss 90) much harder. Not applied.

Suggestions for Phase 6 (owner / lead to decide):
- Measure each city game on 100+ games (40 has an SE of 7-8 pts, the same size as the ramp we look for).
- To make game 3 a real step: a bigger boss (Q3 option (c): good +20, boss +30), or a per-game level step for team 1
  (e.g. game 1 at the trip level minus one notch), or more weight on ratings in the CPU's choices (which shots it takes),
  since the CPU uses the knobs much more than the ratings.
- Fix bug 1 first so Easy / Normal / Hard can be measured per city game with the stock build.

## 9. What the owner should judge on the tablet

- Does Hometown game 1 feel easy and the boss game (to 21 vs the Mayor) a real challenge? The numbers say the three
  games feel about the same for a strong player.
- Game length: to 11 is about 5.5 min (often under 5), to 15 about 8, to 21 about 11.
- The comic story scenes (8 scenes), the map with the van, the recruit cards, the bracket.
- The pause button (top right), RESTART / QUIT needing two taps, music and sound on the pause screen.
- That a trip save survives closing the browser tab on the tablet (it survives a reload in Chromium).
