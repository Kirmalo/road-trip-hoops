# P12-28 Screens QA (Phase 12, Legends Chapter 4 "the New Generation")

- Build tested: `44c7ca3` (branch `ccr-f5c087b2-3ojk5f`, the P12-25 / P12-33 / P12-21 merges in), four chapters
  built. Godot 4.3.stable, Linux, xvfb + `--rendering-driver opengl3`, `--fixed-fps 60`, deviceScaleFactor 1.
- Isolation: a `git archive` copy with `config/name="Road Trip Hoops P1228"` and a test-only screenshot probe autoload
  (scratch copy only, never in the repo). Every run had its own `XDG_DATA_HOME` / `HOME` and its own private `/tmp`
  (runs that had to share a save shared one data folder on purpose: the 2400 trip run and the Chapter 4 legends run
  after it). One Godot process at a time. The probe holds the test driver while it shoots each screen, shoots games at
  fixed frames and on every `sig_*` / `anim_combo` count, scrolls the draft to each LEGENDS row, picks Hall plaques and
  opens / closes the mentor picker; for the ending it opens the Hall on a copy of a finished Legends test file
  (`legends_test.json` after the Hard run, every finale won there; the owner's files never touched) and steps the
  `legends_complete` scene line by line.
- Contact sheet: `docs/qa/phase12-screens.png` (46 shots, numbered below; bug and note shots have orange captions).
  Bug shot: `docs/qa/shots/phase12/p12-b1_perk_clip.png`.
- Game code: not changed.

## Runs

| Run | Result |
|---|---|
| `--import` (probe copy) | clean, no script errors |
| `--legendtest` (headless) | LEGENDTEST OK, era teams [grandfathers, fathers, present, new_generation] OK |
| ltA: `--legends-test --stars 24 --target 3 --difficulty hard --legends-no-trip --right-handed` (1280) | LEGENDS END, crew kings, 40 games (8 goal tests, 8 retries), all four chapters 21/21, 84/84; Chapter 4 opened by 63 tokens; "LEGENDS complete true, ending after the last finale 1, from the Hall 1, timeline true" |
| trA: `--trip-test --target 3 --screens --legends-unlock-all --stars 72 --right-handed` (1280) | TRIP END 24-0 (25 games, 1 replay, 121 screens); drafts Overclock (row next) -> Deep End -> Rooftop -> Steeple; one-legend refusal tried [grand, next]; legend + boss start Overclock + Mayor |
| trB: `--trip-test --target 3 --legends-unlock-all --stars 72 --left-handed --trip-stop-after chicago` at 2400x1080, games played out | TRIP STOP (record 6-2); Overclock starts from Chicago in your colors |
| ltB: `--legends-test --legends-chapter next --stars 72 --target 3 --difficulty normal --left-handed` at 2400x1080 on trB's save | LEGENDS END, crew trip, "OVERCLOCK SITS: JOJO PLAYS", Hall + the trip roster's mentor picker |
| `--autoplay --challenge <id> --difficulty normal` (1500 frames) for the 6 New Generation legends and `fin:next` | every `CHALLENGE GOAL` line on screen (below), twist era_next on all 7 |
| `--autoplay --challenge lg_glitch / lg_firewall / fin:next --view flat` | NEON DOME flat, goal line and banner fit |
| Full `--autoplay --challenge` games for the moves (1280): lg_firewall (failed 11-5, "YOU SCORED 2 OF 5"), fin:next (failed 18-21), lg_glitch twice (failed 11-15 flat; failed 15-10 angled, "ONLY 0 OF 2 STOPS"), lg_updraft easy (failed 7-11) | see the moves table |
| `--humantest --signature hesitation,putback,swat` (1280 right), `--humantest --challenge` lg_glitch (1280 left), lg_firewall (2400 left), lg_overclock (1600 right) | HUD with the touch controls in both layouts |
| `--humantest --pauseshot --challenge lg_halfcourt` (1280) | PAUSESHOT, twist `era_next` |
| `--titletest --legends-unlock-all --stars 72` at 1280 and at 2400x1080 left-handed | TITLE TEST DONE both; era order courts [era_grand, era_fathers, era_present, era_next]; NEON DOME twist era_next, music legends_next, line "FAST BREAK: a quicker game, early shots fall" |
| `--menushot --target 3 --legends-unlock-all`: `new_generation,present --court era_next` (1280), `cornfield_kings,new_generation --court era_next` (2400) | menu shots OK |
| `--autoplay --legends-unlock-all --quick-teams new_generation,grandfathers --court era_next` (angled) and `new_generation,present` (flat), 8000 frames | OK |
| `--autoplay --twist era_next --court era_next --twistshots DIR` | 3 twist shots |
| `--anim-test --anim-sheet` the six `lg_` New Generation sheets (xvfb, `--anim-out` into the scratch folder) | ANIM OK, 358 images. (A first try failed with 358 "could not write" lines only: my `--anim-out` folder did not exist. Not a game fault.) |
| `--backtest --stars 72` headless and at 2400x1080 under xvfb | BACKTEST OK both (Chapter 4 block and the LEGENDS COMPLETE Hall banner included) |
| 5 `--autoplay`, 2 `--humantest` (headless, Hard, Kings vs Runners) | all ended, no script errors (table below) |

The only engine errors in the game logs come from xvfb (ALSA / dummy audio). Two `SCRIPT ERROR` lines in one ending
run came from my probe (it poked a story field on the Hall screen), not from the game.

## Autoplay / humantest stats (sanity only; this task changes no sim)

| Stat | Mean | Range (5 autoplay) | Target (CLAUDE.md) |
|---|---|---|---|
| Final | RED won 4 of 5 | 16-21, 18-21, 21-13, 16-21, 17-21 | 21-x, loser 12-20 |
| Game length | 9:57 | 8:29 - 12:08 | 7-11 min |
| Shots | 62.8 | 56 - 74 | 55-90 |
| Make rate | 52% | 45% - 57% | about 50% |
| Fouls | 2.2 | 0 - 4 | 1-5 |
| Out of bounds | 1.6 | 0 - 3 | 1-2 |
| Interceptions | 2.2 | 0 - 5 | few |
| Side switches | 1 | 1 - 1 | 1 |
| Shot-clock violations | 0 | 0 | few |
| Offensive rebounds | 25.8% | 16.7% - 33.3% | about 25% |

Humantest: 21-17 (7:06, 61 shots, 6 fouls) and 21-15 (7:19, 70 shots, 2 fouls). One autoplay ran 12:08 (74 shots).
Five games say nothing about balance (RED 4 of 5 is chance at this count).

## Checks (1280x720 unless marked)

| Screen / feature | Sheet # | Result |
|---|---|---|
| Timeline, Chapter 4 locked: grey pin, "LOCKED", "OPENS AT 72 STARS OR 48 TOKENS", "YOU HAVE 24 STARS"; "NEW GENERATION" fits its panel | 1 | PASS |
| Timeline, Chapter 4 open (63 tokens): violet pin with the bolt, PLAY, "6 LEGENDS - TOKENS 0/21", the others FINALE WON | 2 | PASS |
| Timeline, LEGENDS COMPLETE: gold sub line "LEGENDS COMPLETE - TOKENS 84/84", hint "Every era beaten, every finale won. The Hall is full.", four FINALE WON panels, gold pins; at 1280 and 2400x1080 | 3, 4 | PASS. Note 5 |
| Chapter 4 view with the Kings: 6 silhouettes, "CHAPTER 4 - FAST BREAK RULES", detail OVERCLOCK, finale card locked, NO TRIP note | 5 | PASS. Note 4 |
| Chapter 4 view, all won: six cards in the neon frame, lime plates, PLAY FINALE, "TO 21 AGAINST OVERCLOCK, UPDRAFT, HALFCOURT" | 6 | PASS |
| Chapter 4 view with the trip crew at 2400x1080: "OVERCLOCK SITS: JOJO PLAYS. A legend never plays against himself.", LEGEND level button | 7 | PASS |
| Hall: four era rows (CHAPTER 4 THE NEW GENERATION in lime, FINALE WON 21/21), 24/24 LEGENDS - 84/84 TOKENS, the full banner "THE HALL IS FULL: LEGENDS COMPLETE. TAP HERE FOR THE ENDING." at 1280 and 2400 | 8, 9 | PASS |
| Hall detail for the six New Generation legends (names, full names, archetypes, numbers, shapes, signature texts) | 8, 10, 11 | PASS for everything but the perk line: **P12-B1** (Glitch and Firewall, at 1280 and 2400) |
| Mentor picker: no trip (the underdogs, NO TRIP note) and the trip roster at 2400 (YOU / STARTER / BENCH, drafted legends left out); the long Glitch perk fits here | 13, 14 | PASS |
| Draft: four LEGENDS rows in timeline order (GRANDFATHERS orange, FATHERS mint, PRESENT teal, NEW GENERATION #466e14 measured (70, 110, 20) on band and head), "6 TO DRAFT", neon frames, cards in your colors | 15, 16 | PASS |
| Draft joining line: Overclock's portrait and line wrap in the panel | 17 | PASS |
| Lineup: LEGEND tags in each era's color (olive / teal / mint side by side tell apart), DRAFTED, legend + boss; 2400 left-handed | 18, 19 | PASS |
| `legends_complete` ending: every line, name plates, portraits (Jojo, Steeple, Tank, Rooftop, Deep End, Deuce, Glitch with the old ball on his chrome hand, Halfcourt); every text fits the box; then back to the Hall | 20, 21 | PASS |
| Chapter 4 intro, six unlock scenes, finale before / after (one shot each, first line) | 22 | PASS |
| Challenge HUD lines: "REACH 11 BEFORE OVERCLOCK'S CREW GETS 10", "COME BACK FROM 0-2: WIN TO 15", "BLOCK OR STEAL ON GLITCH: 0/2", "HOLD UPDRAFT UNDER 6: n", "HALFCOURT IS ON FIRE: WIN TO 15", "SCORE 5 ON FIREWALL: n"; finale: no line. Centred, clear of the clock and pause button at 1280, 1600 and 2400 | 23-28, 39, 40 | PASS |
| FAST BREAK banner: icon (ball with speed lines), "Fast break: a quicker game, early shots fall" inside its box, under the goal line | 23, 24, 26 | PASS |
| NEON DOME in play: dark grid floor, violet keys and circles, lime lines, rings and rail over the crowd; flat view: flat floor with the violet keys | 23-29, 46 | PASS |
| Pause panel: FAST BREAK line in two lines inside the panel; "THE NEW GENERATION" header wraps in 3 lines and fits | 41 | PASS |
| Quick Game: YOUR TEAM / OPPONENT "THE NEW GENERATION" in its olive; COURT NEON DOME with its FAST BREAK line; game-over panel at 2400 | 42-44 | PASS |
| Touch controls: joystick and A / B never over the goal line; left-handed mirrored at 1280 and 2400 | 39, 40 | PASS |
| Hard rule and cyber rule by eye (every screen above, portraits, cards, sheets) | all | PASS by my reading. Glitch's forearm is plain chrome with violet seams, no emblem, a normal hand; Firewall's visor is a thin lime band, chrome only at the temples (not red, not gold, nothing round the head); Overclock's braces are shin struts. The natural three show no chrome or glow. No real name, nickname, slogan or brand seen |

### The moves (in game, angled 1280 unless marked)

| Move | Seen | Sheet # |
|---|---|---|
| hesitation + combo (Glitch) | yes: the man in front stands still, "SHOOK!", the combo frames (`anim_combo` 12, `anim_combo_l` 8 in one game; also in Firewall's game); often half hidden behind his defender, as with Phase 11's moves | 30, 31, 45 (contact strip) |
| swat (Firewall) | yes: 2 blocks on jumpers, "BLOCKED!", the ball flies off | 32 |
| hot hand (Halfcourt) | yes: on fire after 2 makes in a row, the fire ring. Note 3 | 33 |
| top gear (Overclock) | yes (many per game), also in your colors in the 2400 trip game | 34, 37 |
| rim run (Long Shadow) | yes (many per game, by the log and the shots) | - |
| putback (Updraft) | only by the log: 4 putbacks (tips, one "high") in the flat-view Glitch game; none in the angled finale to 21 or Updraft's own easy game to 11. No angled picture this pass. Note 2 | - |

### Cyber parts at game size

| Part | Own kit | Your colors | Flat view |
|---|---|---|---|
| Glitch's chrome forearm | readable (grey-white arm, violet at the wrist) | readable on the draft card | not drawn: flat view uses the old top-down sprites for everyone (test / fallback mode) |
| Firewall's lime visor | readable: a lime band across the eyes, clear at 1x | - (not drafted in these runs) | not drawn (same) |
| Overclock's leg braces | weak: the lime light line sits next to lime trim, lime stripes and lime shoes, so at 1x the struts read as a grey shin patch | clearer: grey strut and lime line on brown shins against the blue kit (2400 trip game) | not drawn (same) |

Sheet 35, 36, 38 are 2x / 3x zooms of 1x game frames.

## Notes (not filed)
1. See P12-B1 below.
2. Putback is rare in short games: 0 in two angled games where Updraft played (one to 21), 4 in one flat game. If the
   owner wants to see it, it may take a while; a P12-36 / owner question, not a screen bug.
3. Hot hand: the "ON FIRE!" popup lands on the centre "THE NEW GENERATION SCORES" message and the "+1" (sheet 33).
   The same happens for any fire start (main.gd shows both on the make); the long team name makes it more likely.
   Readable after the 0.8 s message fades. Not new in Phase 12.
4. The Chapter 4 view's detail wraps "REACH 11 BEFORE OVERCLOCK'S CREW GETS" with "10" alone on the second line
   (sheet 5, 7). It fits; a shorter line would look tidier.
5. Wide timeline: the stretched edge columns are wood on both sides, so a wood strip sits beside the NEON DOME panel at
   2400 (sheet 4). The gold rail stops at Chapter 1 even when all four are won (it is in `timeline.png`). Cosmetic.
6. Overclock's braces are weak in his own kit (table above). If the owner wants them to read: a brighter chrome strut
   or the light line in white / violet instead of lime (art, `make_players.py` "Phase 12 era parts").
7. The `--backtest`'s forced LEGENDS COMPLETE shows the Hall banner with 0/84 tokens (sheet 9): a test-only state, the
   real ending needs every finale won.

## Bugs (filed on `docs/BOARD.md`)

### P12-B1 (Low, text fit): two New Generation mentor perk texts are cut off in the Hall detail
- Steps: `--legends-test --stars 24 --target 3 --difficulty hard` (or `--legends-unlock-all`), open the Hall, tap
  GLITCH or FIREWALL. 1280x720 and 2400x1080 alike.
- Expected: the whole perk line, like every other legend's.
- Actual: "His pump fakes get the defender up 15% more" (the word "often" is lost) and "His blocks on jump shots work
  10% more ofte" (the "n" cut at the panel edge). Shot `docs/qa/shots/phase12/p12-b1_perk_clip.png`, sheet 10-12.
- Cause: `scripts/hall.gd` line 563 draws the perk text as one clipped line (`_text(..., Rect2(DETAIL_PAD, perk_y +
  22.0, full_w, 30), DETAIL_TEXT_FONT, ...)`, `clip_text`), with no shrink. `legends_data.gd` `PERKS` `pump_fake`
  (49 letters) and `closeout` (44, wider letters) are the longest texts yet; Long Shadow's 44-letter line just fits.
- Fix (either): shrink it like the name and archetype, `_fit_font(label, full_w)` down to `DETAIL_ARCH_MIN` 12 on the
  label `_text()` returns; or shorten the two texts in `PERKS`: `"Pump fakes get his man up 15% more often"` and
  `"Blocks on jump shots work 10% more often"` (the mentor picker shows them too, it already fits the long ones).

## Suggested tuning
None from this task (screens only); see note 2 for the putback rate.
