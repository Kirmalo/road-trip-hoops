# P11-28 Screens QA (Phase 11, Legends Chapter 3 "the Present")

- Build tested: `b3c7adc` (branch `ccr-f5c087b2-3ojk5f`, "Docs: Zigzag is Bastien"), everything for Chapter 3 merged.
  Godot 4.3.stable, Linux, xvfb + `--rendering-driver opengl3`, `--fixed-fps 60`.
- Isolation: a `git archive` copy with `config/name="Road Trip Hoops P1128"` and a test-only screenshot probe autoload
  (scratch copy only, not in the repo). Every run had its own `XDG_DATA_HOME` / `HOME` (the 1600 trip run and the
  legends run after it shared one folder on purpose, so the legends run used that trip save) and ran in a private mount
  namespace with its own `/tmp`. At most 2 Godot processes at a time. The probe pauses the test driver while it takes
  each screen's shot, shoots games at fixed frames and on every `sig_*` / `anim_stepback` / `anim_eurostep` count,
  scrolls the draft to each LEGENDS row, and in the Hall picks plaques and opens and closes the mentor picker.
- Contact sheet: `docs/qa/phase11-screens.png` (36 shots; bug and note shots have orange captions).
- Game code: not changed.

## Runs

| Run | Result |
|---|---|
| `--import` (probe copy) | clean, no script errors |
| `--legendtest` (headless) | LEGENDTEST OK |
| t0: `--titletest --stars 24` | TITLE TEST DONE; timeline with Chapter 3 LOCKED |
| ltA: `--legends-test --stars 24 --target 3 --difficulty hard --legends-no-trip --right-handed` (1280) | LEGENDS END, crew kings, 30 games (6 goal tests, 6 retries), grand / fathers / present 21/21 each; Chapter 2 opened by 21 tokens, Chapter 3 by 42 tokens; 175 shots |
| trA: `--trip-test --target 3 --screens --legends-unlock-all --stars 24 --right-handed` (1280) | TRIP END 24-0 (25 games, 1 replay, 117 screens); drafts `lg_deep_end` (Present row) then `lg_rooftop` (Fathers row); a second legend refused; legend + boss start (Deep End + Mayor) |
| trB: `--trip-test --target 3 --legends-unlock-all --stars 24 --left-handed --trip-stop-after memphis` at 1600x720 | TRIP STOP (record 9-8, games played out); the same drafts, the refusal and legend + boss checked |
| ltB: `--legends-test --legends-chapter present --stars 48 --target 3 --difficulty normal --left-handed` at 1600x720, on trB's trip save | LEGENDS END, crew trip (Deuce, Deep End, Mayor), "DEEP END SITS: HONEY PLAYS", Hall and the trip roster's mentor picker |
| `--autoplay --challenge <id> --difficulty normal` (1500 frames) for the 6 Present legends and `fin:present` (1280) | every `CHALLENGE GOAL` line on screen (below) |
| `--autoplay --challenge lg_zigzag --view flat` | BIG STAGE flat, goal line and banner fit |
| `--humantest --challenge` lg_switch (1600 left), lg_deep_end (1280 right), lg_zigzag (1280 left), lg_skylight (1600 right) | HUD with the touch controls in both layouts |
| `--humantest --pauseshot --challenge lg_toolbox` (1280 right) | PAUSESHOT, twist `era_present`. The 1600 left one (lg_stretch) printed PAUSESHOT, then the process was stopped from outside ("Terminated") before its image was copied out: no 1600 pause shot this pass |
| `--titletest --legends-unlock-all --stars 48` at 1280 and at 1600 left-handed | TITLE TEST DONE both; settings.cfg put back; `hoops_quick_era_*` shots (P11-35) |
| `--menushot --target 3 --legends-unlock-all`: `--quick-teams grandfathers,present --court era_present` (1280), `present,cornfield_kings --court era_present` (1600) | menu shots OK |
| `--autoplay --legends-unlock-all --quick-teams fathers,present --court era_present` (8000 frames) | era team vs era team on BIG STAGE |
| Full `--autoplay --challenge` games for the moves: lg_deep_end (failed 12-15), lg_zigzag (failed 6-11), lg_switch at 1600 left (failed 11-4, "YOU SCORED 1 OF 5"), lg_zigzag `--difficulty easy --target 21` twice (met 22-16; the second stopped by me once it had its Euro-step) | step-back 1, Euro-step 2 (one in Switch's game, one in the second 21-point Zigzag game), pop many, coast 2 |
| 5 `--autoplay`, 2 `--humantest` (headless, Hard, Kings vs Runners) | all ended, no script errors (table below) |

The only engine errors in the logs come from xvfb (ALSA / the dummy audio driver).

## Autoplay / humantest stats (sanity only; this task changes no sim)

| Stat | Mean | Range (5 autoplay) | Target (CLAUDE.md) |
|---|---|---|---|
| Final | RED won 3 of 5 | 12-21, 21-18, 17-21, 21-17, 17-21 | 21-x, loser 12-20 |
| Game length | 9:25 | 8:02 - 11:46 | 7-11 min |
| Shots | 61 | 55 - 83 | 55-90 |
| Make rate | 53% | 43% - 61% | about 50% |
| Fouls | 2.6 | 0 - 7 | 1-5 |
| Out of bounds | 1.8 | 1 - 4 | 1-2 |
| Interceptions | 2.4 | 1 - 4 | few |
| Side switches | 1 | 1 - 1 | 1 |
| Shot-clock violations | 0 | 0 | few |
| Offensive rebounds | 26% | 17% - 33% | about 25% |

Humantest: 21-13 (7:22, 63 shots, 1 foul, 1 interception) and 21-13 (6:32, 53 shots, 1 foul, 5 interceptions),
`pause_test_ok` 1 in both. One autoplay game ran long (11:46, 83 shots, 7 fouls). Five games say nothing about balance.

## Checks (1280x720 unless marked)

| Screen / feature | Shot (sheet #) | Result |
|---|---|---|
| Timeline, Chapter 3 locked: grey pin, "LOCKED", "OPENS AT 48 STARS OR 30 TOKENS", "YOU HAVE 24 STARS" | 1 | PASS |
| Timeline, Chapter 3 open (42 tokens): teal pin, PLAY, "6 LEGENDS - TOKENS 0/21"; then all three "FINALE WON 21/21", TOKENS 63/63, Chapter 4 COMING LATER | 2, 3 | PASS |
| Chapter 3 view with the Kings: 6 silhouettes, "CHAPTER 3 - SPACE THE FLOOR RULES", the detail names DEEP END, finale card locked, NO TRIP note | 4 | PASS |
| Chapter 3 view with the trip crew, a drafted Present legend sitting: "DEEP END SITS: HONEY PLAYS. A legend never plays against himself." (Honey in orange) | 5 (1600) | PASS |
| Intro, 6 unlock scenes, finale before / after: portraits, name plates, SKIP, text box | 6-8 | PASS, every Present scene seen; portraits **P11-B1** |
| Each Present challenge HUD line | 9-15 | "DEEP END IS ON FIRE: WIN TO 15" (fire ring), "COME BACK FROM 0-1: WIN TO 15" (starts 0-1), "REACH 11 BEFORE STRETCH'S CREW GETS 10", "SCORE 5 ON SWITCH: n" (counts up), "BLOCK OR STEAL ON SKYLIGHT: 0/2", "HOLD ZIGZAG UNDER 6: n"; finale: no line. All centred, clear of the clock and the pause button, at 1280 and 1600 |
| SPACE THE FLOOR banner in play (coordinator note 2) | 9, 15, 16 | PASS: "Space: threes fall, wider spacing, pull-ups off a crossover" ends at about x 914 in a box that ends at 970 (1280), under the goal line; it fits in flat view and at 1600 too |
| SPACE line on the Quick Game panel and in the pause panel | 29-31, 36 | PASS: one line on the panel at 1280 and 1600 ("SPACE: threes fall, ..."); two lines in the pause panel, inside it. Note 2 |
| Era court BIG STAGE in play, angled and flat | 9-16, 32 | PASS: pale wood, teal keys, LED ribbon with coral blocks, crowd; flat: the flat floor with teal keys |
| Step-back (Deep End) | 17 | PASS: a crossover ("SHOOK!"), the hop back, the rise and release with the stepback frames (`anim_stepback` 1); the defender covers part of the pose, as in Phases 9-10. Note 3 |
| Euro-step (Zigzag) | 18 | PASS: the step out to one side of Jojo, back across and the layup over him (`anim_eurostep` 1, `sig_euro_step` 1); also seen at 1600 left in Switch's game, mostly hidden behind two defenders. Note 3 |
| Other Present signatures | sig logs | pop (Stretch drifts to the arc, many per game), coast (Toolbox, 2 in Switch's game) seen; steal-and-run and lob magnet not seen in these few games (P11-23 counted them) |
| Hall: three era rows (CHAPTER 1, 2, 3 with status and tokens), the Chapter 4 locked row below, header 18/18 LEGENDS - 63/63 TOKENS; Present plaques in the arena frame, coral plates | 19-21 | PASS |
| Hall opened from each chapter view picks that chapter's first legend and scrolls to its row (Steeple; Rooftop; Deep End) | 19, 20 | PASS |
| Hall detail for the six Present legends (probe picks each) | 21, sheet | PASS: names, archetypes, signature and perk texts fit; Stretch's long text shrinks (P10-B6 fix holds) |
| Mentor picker: no trip (the underdogs, NO TRIP note) and the trip roster at 1600 (YOU / STARTER / BENCH, drafted legends left out) | 22 | PASS |
| Draft: three LEGENDS rows (GRANDFATHERS orange, FATHERS mint, PRESENT teal; "6 TO DRAFT" each), the arena frames on the Present cards | 23, 24 | PASS, with **P11-B2** |
| Draft joining line: Deep End's portrait and line, "CALLOWAY "DEEP END" WHITLOCK JOINS THE CORNFIELD KINGS!" wraps in the panel | trA `hoops_screen_11_draft` | PASS |
| Lineup: LEGEND tags in each era's color, DRAFTED, BOSS; legend + boss start | 25 | PASS, with **P11-B2** |
| Lineup one-legend rule line | trA / trB logs | PASS by the log: "ONLY ONE LEGEND CAN START. Bench ROOFTOP first." The driver puts the picks back before the probe's next shot, so this pass has no picture of the flash (Phase 10 has one) |
| Quick Game panel: an era team on each side, BIG STAGE with its twist line; YOUR TEAM / OPPONENT in era colors | 29-31 | PASS at 1280 and 1600 |
| Quick Game era team vs era team on BIG STAGE (Fathers vs Present) | 32 | PASS; the kits stay apart on court (the team rings decide anyway) |
| 1600x720: chapter view, Hall, picker, draft, lineup, game HUD, menus | 5, 21, 22, 31, 33 | PASS |
| Left-handed: game HUD (joystick right, buttons bottom left, pause top-right, goal line clear) at 1280 and 1600 | 33, 35 | PASS. Menu screens don't mirror (by design) |
| Hard rule by eye (every screen above, `docs/art/legends_present.png`, `docs/art/legends_present_portraits.png`, the Hall bios and texts, the scene lines seen) | all | PASS against the board's look table: Deep End no beard (thin mustache), waves; Toolbox man bun, no headband, #38; Stretch close-cropped dark hair, short boxed beard; Switch bald, short beard, bare arms; Skylight high-top fade; Zigzag curly hair, knee sleeve, no headband. No real name, nickname, slogan or brand seen. Note 4 |

### Coordinator note 1: Fathers mint vs Present teal; the coral name plate
- Measured on the screenshots: Fathers band / tag `#5cc7a1` (hue 159), Present `#17a8a1` (hue 177). Contrast between
  them 1.42:1. On the draft the rows carry their chapter name, so it is readable; on the **lineup** two LEGEND tags sit
  next to each other with nothing else telling the eras apart (sheet 25, 26), and the yellow LEGEND text on the teal
  fill is only 2.1:1. Filed as P11-B2 with a fix.
- Name plates (sheet 27): the default dark ink `#3d2414` on the Present coral plate `#d8483a` is 3.4:1 (the Fathers'
  orange plate is 3.1:1 with the same ink, accepted in Phase 10). Readable at every size seen (draft 1x, Hall 2x and 3x).
  White would be 4.3:1. **No change needed**; if the owner wants it lighter: `colors.present.plate_text` `"#fff3e8"`
  (about 4.1:1), written by `tools/art/make_legends_ui.py` into `assets/legends/ui.json` (today the file has no
  `"colors"` block; hall.gd and draft.gd already read it).

### Notes (not filed)
1. See note 1 above (P11-B2).
2. The twist line reads "SPACE: threes fall, ..." while every other twist line starts with its full name ("ISO BALL:
   ..."). "Space the floor: ..." would run about 90 px past the in-game banner box at 1280, so the short "Space:" is the
   right call; leave it.
3. The moves are rare in play: in five full Present games the step-back fired once (Deep End's own 15-point game) and
   the Euro-step twice (none in a 15-point and a 21-point Zigzag game). P11-23 measured 2.15 step-backs and 0.80
   Euro-steps per game, so this is chance plus short games, but an owner who wants to see the Euro-step may wait a
   while. A tuning question for P11-36 / the owner, not a screen bug.
4. Hard rule cautions for the owner's eye (no change needed by my reading): the era palette (teal and coral on
   graphite / ink) is near the idea of one current team's black alternate with pink and blue trim, but no single kit
   copies it (Toolbox coral and graphite, Switch ink and teal, Zigzag white and coral, ...), and no number points at a
   player of that team. Stretch is a light-skinned, Nordic-named stretch big; his dark close-cropped hair, boxed beard,
   #49 and no fadeaway keep him apart, as the name check asked.
5. Stale text for P11-29: `legends_data.gd`'s `"look"` lines (not shown in game) say Stretch "white tank with coral
   trim" (the sheet has teal trim), Zigzag "aqua tank with ink trim" (white and coral) and Deep End "mint trim" (teal);
   the board's name table still says "first name Lucien" for Zigzag (now Bastien).
6. The Hall's `pick()` (the test and keyboard path) does not scroll a picked plaque into view (Steeple picked while
   the list showed the Present row: only his plate strip visible). A tap always hits a visible plaque, so touch is not
   affected.

## Bugs (filed on `docs/BOARD.md`)

### P11-B1 (Low-medium, art): Switch's and Skylight's story portraits wear the wrong kits
- Steps: any scene with Switch or Skylight (their unlock scenes, the draft joining line), or
  `docs/art/legends_present_portraits.png`.
- Expected: the kit of his sheet and card (crews.json): Switch ink tank with teal trim, Skylight deep teal tank with
  white trim.
- Actual: Switch's portrait has a teal tank with white trim, Skylight's an ink tank with coral trim (sheet 28): the two
  look swapped next to their Hall cards. Also Stretch's portrait skin is "tan", his sheet "light".
- Cause: `tools/art/make_portraits_v2.py` line 2089 (`lg_switch`: `top_pal="ERA3_TEAL", trim_pal="ERA3_LIGHT"`) and
  line 2093 (`lg_skylight`: `top_pal="ERA3_INK", trim_pal="ERA3_CORAL"`) differ from `tools/art/crews.json` lines 888 and
  896; Stretch `skin="tan"` vs crews.json line 878 `"light"`.
- Fix: Switch `ERA3_INK` / `ERA3_TEAL`, Skylight `ERA3_DEEP_TEAL` / `ERA3_LIGHT`, Stretch `skin="light"`; rerun
  `make_portraits_v2.py --legends present` (assets/portraits/lg_switch*, lg_skylight*, lg_stretch* and the preview).

### P11-B2 (Low, readability): the Present's teal is too close to the Fathers' mint on LEGEND tags and draft bands
- Steps: a lineup with a drafted Father and a drafted Present legend (`--trip-test --legends-unlock-all --stars 24`), or
  the draft's LEGENDS rows.
- Expected: the two eras' tags tell apart at a glance.
- Actual: `#5cc7a1` vs `#17a8a1`, 1.42:1 (sheet 25, 26); yellow LEGEND text on the Present tag 2.1:1.
- Cause: `scripts/legends_data.gd` line 158, the Present crew's `"ui_color": Color(0.09, 0.66, 0.63)` (the court's key
  teal), next to the Fathers' `Color(0.36, 0.78, 0.63)` (line 139).
- Fix (stays teal, the owner's era color): `"ui_color": Color(0.04, 0.45, 0.52)` (`#0a7385`): 2.7:1 against the mint,
  the LEGEND text 3.9:1, still 3.1:1 against the dark card. It also darkens the Present's Quick Game team button and the
  drawn fallback frame (both stay readable). A color the owner sees: the coordinator's or the owner's yes first.

## Best screenshots for the owner (scratch, not committed)
Listed in the hand-off report.

## Suggested tuning
None from this task (screens only); see note 3 for the move rates.
