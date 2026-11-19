# P9-32 Screens QA (Phase 9, Legends)

- Build tested: `2a69c9b` (branch `ccr-f5c087b2-3ojk5f`, "P9-28: --backtest covers the Legends screens"). Godot
  4.3.stable, Linux, xvfb + `--rendering-driver opengl3`, `--fixed-fps 60`.
- Isolation (as in `phase8-screens.md`): a `git archive` copy with `config/name="Road Trip Hoops P932"` (own
  `user://`, own `XDG_DATA_HOME` and `HOME`), every run in a private mount namespace with a tmpfs `/tmp`. One Godot
  process at a time. A second copy ("P932 Probe") adds one test-only autoload that is not in the repo: it pauses the
  test driver while it takes screenshots of every screen and game, drives the Hall's mentor picker and SWITCH confirm
  (`open_picker`, `tile_tapped`, then `release` to put things back), shoots Steeple's hook shots (`hook_shot` and
  `shooting` true), and on the first lineup with two legends taps [you, legend 1] then legend 2 (the one-legend
  flash) and restores the picks.
- Contact sheet of the key shots: `docs/qa/phase9-screens.png` (32 shots, the bug shots captioned in orange).
- Game code: not changed.

## Runs

| Run | Result |
|---|---|
| `--import` (both copies) | clean, no script errors |
| `--titletest --stars 0` (xvfb) | TITLE TEST DONE; LEGENDS locked, tap line "LEGENDS OPEN AT 24 STARS. YOU HAVE 0: WIN TRIP GAMES!", no HALL on CREW |
| `--titletest --stars 24 --legends-unlock-all` (xvfb) | TITLE TEST DONE; LEGENDS open, legends screen and back, CREW's HALL OF LEGENDS and back |
| probe, `--legends-test --stars 24 --target 3 --difficulty normal --legends-no-trip` (1280x720) | LEGENDS END, crew kings, 10 games (2 goal tests, 2 retries), 26 screens, hall ok, trip save unchanged; 81 shots |
| `--trip-test --target 3 --screens --legends-unlock-all --stars 24` (probe watching) | TRIP END 24-0 (25 games, 1 replay, 117 screens), legend drafts `lg_steeple`, `lg_gate`, one-legend refusal ok, final starters `ud_deuce, lg_steeple, ht_boss` (legend + boss) |
| probe, `--legends-test --stars 24 --target 3 --difficulty hard --left-handed --resolution 1600x720` on that finished trip | LEGENDS END, crew trip, "STEEPLE SITS: TREY PLAYS" in Steeple's games, tokens 21/21; 81 shots |
| probe, `--trip-test ... --legends-unlock-all --stars 24 --trip-stop-after hometown` (1280x720) | TRIP STOP; lineup flash "ONLY ONE LEGEND CAN START. Bench STEEPLE first." shot, picks restored, driver's own check still ok |
| probe, `--legends-test --stars 24 --target 3 --difficulty easy` on that mid-trip save | LEGENDS END, crew trip (Deuce, Jojo, Tank), tokens 9/21 |
| same trip stop at `--resolution 1600x720 --left-handed` | TRIP STOP; draft, banner, lineup flash, recruit shots |
| probe, `--autoplay --challenge <id> --difficulty normal --quit-after 2000` for the 6 legends and `finale` | every `CHALLENGE GOAL` line printed and on screen (below) |
| probe, `--autoplay --challenge lg_steeple` played out | 7-15 (lost on the score, Steeple 4 pts), `cpu_hooks_t1` 3, `anim_hook` 3, 3 hooks shot |
| `--humantest --pauseshot --challenge lg_gate --right-handed` (1280) / `--challenge lg_boxcar --left-handed --resolution 1600x720` | PAUSESHOT, twist `era_grand`; HUD frames |
| 5 `--autoplay`, 2 `--humantest` (headless, Hard, plain copy) | all ended, no script errors (table below) |

The only engine messages in the logs are the xvfb ones (ALSA / dummy audio driver, V-Sync not supported).

## Autoplay / humantest stats (sanity only; this task changes no sim)

| Stat | Mean | Range (5 autoplay) | Target (CLAUDE.md) |
|---|---|---|---|
| Final | BLUE won 4 of 5 | 9-21, 21-19, 21-15, 21-20, 21-9 | 21-x, loser 12-20 |
| Game length | 8:33 | 5:57 - 10:19 | 7-11 min |
| Shots | 65.6 | 45 - 83 | 55-90 |
| Make rate | 48% | 38% - 60% | about 50% |
| Fouls | 3.0 | 0 - 6 | 1-5 |
| Out of bounds | 1.2 | 1 - 2 | 1-2 |
| Interceptions | 1.4 | 0 - 3 | few |
| Side switches | 1 | 1 - 1 | 1 |
| Shot-clock violations | 0 | 0 | few |

Humantest: 21-14 (8:32, 70 shots, 5 fouls, 6 interceptions) and 14-21 (8:36, 82 shots, 0 fouls, 10 interceptions),
`pause_test_ok` 1 in both. Two loser scores (9) are below the 12-20 band; 5 games say nothing about balance.

## Checks (1280x720 unless marked)

| Screen / feature | Shots (in the run's folder) | Result |
|---|---|---|
| Title, LEGENDS locked (dim purple-grey, "24 STARS" tab, tap line) and open (purple) | title0 `hoops_title_legends_locked`, title24 `hoops_title` | PASS. 4 top buttons 270x130 |
| Timeline: 4 panels, pins, CHAPTER n, status, gates "36 STARS OR 12 TOKENS" etc., PLAY 240x110, HALL / BACK | title24 `hoops_legends`, lt `002`, `080` | PASS; FINALE WON and the token count after the chapter |
| Chapter view: 6 plaques (locked silhouettes, then cards with pips), finale card locked / OPEN / FINALE WON, detail, level buttons 235x110, PLAY / PLAY FINALE | lt_kings `005`, `057`, `066` | PASS, see P9-B6 (locked name) |
| Chapter view with the Kings: "THE KINGS AT EVEN RATINGS", NO TRIP note, YOU on Jojo | lt_kings `005` | PASS (see P9-B5) |
| Chapter view with a trip crew: "YOUR ROAD TRIP STARTERS"; a drafted legend facing himself: "STEEPLE SITS: TREY PLAYS. A legend never plays against himself." (Trey in orange) | lt_trip `005`, lt_trip_wl `005`, `066` | PASS |
| Intro scene, unlock scenes (6), finale before / after: portraits, name plates (STEEPLE, QUARTERBACK ...), SKIP, text box | lt_kings `003`/`004`, `015`..`055`, `058`..`065` | PASS, every scene seen once (scenes 9) |
| Each challenge's HUD line | ch_* `002_game_f330` | PASS: "HOLD STEEPLE UNDER 6: 0", "REACH 11 BEFORE GATE'S CREW GETS 7", "SET SHOT IS ON FIRE: WIN TO 15" (fire ring at tip-off), "BLOCK OR STEAL ON BOXCAR: 0/3" (1/3 after a steal), "HOLD VELVET UNDER 5: 0", "COME BACK FROM 0-6: WIN TO 15" (score starts 0-6). Finale: no line (by design). Centered 280..1000, clear of the clock and the pause button. FAIL for the first seconds = P9-B4 |
| End message | lt_kings `008`, `013`, `062` | PASS: "FINAL 3 - 0 / CHALLENGE MET!" (blue), "FINAL 0 - 6 / CHALLENGE FAILED" with the line "CHALLENGE FAILED: STEEPLE SCORED 6" (red); finale "CORNFIELD KINGS WINS!" |
| OLD SCHOOL banner and pause line | lt_kings `006`, pause_r `hoops_pause`, pause_lw | PASS: banner "OLD SCHOOL / Old school: slower, more inside, fewer threes and fouls"; the pause panel's last line says the same |
| Steeple's hook shot in a game | hook `005`..`010`, zoom in the contact sheet | PASS: the one-arm hook over the shoulder reads (3 of 3 hooks drew the hook frames). Note: the CPU only hooks with a defender within 6 ft, so in 2 of the 3 the defender covers most of the pose |
| Hall: plaques, detail (rating bars, signature, perk, TRAINS line), REPLAY STORY / TRAIN 210x110, locked chapter rows (COMING LATER, gate), the header count | title24 `hoops_hall`, lt_kings `072`..`078` | PASS |
| Hall mentor picker: no trip (underdogs) and trip roster (10 tiles, legends left out), tags YOU / STARTER / BENCH, NO MENTOR / TRAINED BY; assign flash "STEEPLE now trains DEUCE."; SWITCH confirm with both lines, NOT YET / YES, SWITCH; SWITCH and back to TRAIN after release | lt_kings `075`..`078`, lt_trip / lt_trip_wl `075`, `077` | PASS, with P9-B5 |
| Draft LEGENDS row: "UNLOCKED IN LEGENDS - THE GRANDFATHERS", 6 TO DRAFT, LEGEND tags, era frames, hint "STEEPLE joins at these stats. ONLY ONE LEGEND CAN START." | trip_lg `hoops_screen_10_draft`, `001_draft_hint1` | PASS; the join banner FAILS at 1280 = P9-B3 |
| Lineup with a legend + a boss starting (LEGEND / DRAFTED / BOSS tags) | trip_lg `hoops_screen_31_lineup` | PASS |
| Lineup one-legend flash | trip_hz `003_lineup_one_legend_flash` | PASS: "ONLY ONE LEGEND CAN START. Bench STEEPLE first." in orange, Gate not picked |
| CREW: HALL OF LEGENDS button once a legend is unlocked, none at 0 | title24 `hoops_crew` | PASS |
| 1600x720: timeline, chapter view, Hall, picker, confirm, story, draft, lineup, recruit, game HUD | lt_trip_wl, trip_wl, pause_lw | PASS (layout box centred, nothing off screen; the join banner fits here), with P9-B7 |
| Left-handed: game HUD (joystick right, SHOOT / PASS bottom left, pause top-right, the goal line clear of all) | pause_lw `002_game_f330` | PASS. The menu screens don't mirror (by design, no joystick) |
| Buttons under 110 px tall | all | none found: level buttons 235x110, PLAY 484x112, timeline PLAY 240x110, HALL / BACK 200x110, REPLAY STORY / TRAIN ~210x110, picker tiles ~268x118, CLOSE 240x110, confirm 300x118, draft SIGN 560x110 |
| Name check by eye (every screen, every legends story line in `story_text.gd`) | all | PASS: only the made-up names (Ezekiel "Steeple" Oakhurst, Augustus "Gate" Fenwick, Harlan "Set Shot" Vickery, Cornelius "Boxcar" Dunmore, Desmond "Velvet" Ashby, Otis "Quarterback" Brannigan); no real player's name anywhere |

## Bugs

### P9-B3 (Medium): a drafted legend's join banner runs off the screen at 1280x720
- Steps: `--trip-test --target 3 --screens --legends-unlock-all --stars 24` (or a real trip with a legend unlocked):
  the draft signs a legend.
- Expected: the "joins" message fits the screen.
- Actual: "EZEKIEL "STEEPLE" OAKHURST JOINS THE CORNFIELD KIN" is cut at the right edge, the panel too (trip_lg
  `001_draft_hint1`, `hoops_screen_11_draft`). Legends have no `RECRUIT_LINES` entry, so `draft.gd` `_banner()` shows
  the full name at `UI.BUTTON_FONT` with no wrap or shrink. It just fits at 1600x720; Boxcar's longer name likely not.
  1280x720 is the owner's tablet layout.
- Suggested fix (`scripts/draft.gd` `_banner()`, or `scripts/story_text.gd`): give each legend a joining line in
  `RECRUIT_LINES` (then the portrait + line path, like the other drafts); or cap the panel at the frame width with
  `AUTOWRAP_WORD_SMART` / shrink the font to fit; or use the short name ("STEEPLE JOINS THE CORNFIELD KINGS!").

### P9-B4 (Low-Medium): the OLD SCHOOL banner covers the challenge goal line at the start of every challenge
- Steps: any challenge game (`--challenge lg_set_shot`, or the tour): look at the first seconds after GO.
- Expected: the goal line ("SET SHOT IS ON FIRE: WIN TO 15") readable from tip-off.
- Actual: the twist banner (`twist_fx.gd` `BANNER_Y` 62, `BANNER_H` 76, 4.5 s from the scene start) sits over the
  goal line (`challenge.gd` `LINE_TOP` 56, `LINE_H` 30) and hides it until about 2.25 s after GO (lt_kings `006`,
  ch_lg_set_shot `001`; at frame 330 the line shows).
- Suggested fix: in a challenge game move the banner under the line (`BANNER_Y` = `LINE_TOP` + `LINE_H` + 6 = 92,
  `scripts/twist_fx.gd`, when `game.challenge != null`), or draw the goal line on a layer above the banner.

### P9-B5 (Low): without a trip, "YOU" is Jojo on the chapter view but Deuce in the Hall's mentor picker
- Steps: no trip save (`--legends-test --legends-no-trip`, or a fresh install with 24 stars): chapter view, then
  HALL > a legend > TRAIN.
- Expected: the same player marked YOU, or the picker not claiming one.
- Actual: the chapter view's crew (the Kings, `Trip.QUICK_KINGS`) puts YOU on JOJO; the picker
  (`hall.gd` `_load_players()`, `Cities.START_CREW[0]`) tags DEUCE as YOU (lt_kings `005` vs `075`). With a trip
  both say the trip's human (consistent).
- Suggested fix (`scripts/hall.gd` `_load_players()`): in the no-trip case tag the underdogs "UNDERDOG" (or no tag),
  since they are the future trip's players, not the Kings who play these games.

### P9-B6 (Low, design question for the lead): a locked plaque hides the legend's name, the detail names him
- Chapter view: the locked plaque and the detail title say "? ? ?", but the challenge line right under it says "HOLD
  STEEPLE UNDER 6 POINTS AND WIN" (and the HUD names him). Either show his name on the detail title, or word the
  goal without it ("HOLD HIM UNDER 6 ..."). `scripts/legends_tour.gd` / `legends_data.gd` challenge text.

### P9-B7 (Low, cosmetic): 1600x720, the timeline and chapter-view art stops at the 1280 box
- At 1600x720 the timeline's 4 panels and the dimmed backdrop end at x 160 / 1440 with flat dark bars outside (lt_trip_wl
  `002`, `005`). Nothing is cut or off screen. Suggested fix (`scripts/legends_tour.gd`): stretch or extend the
  backdrop's edge columns to the viewport width (the buttons stay in the box).

### Notes (not filed)
- The Hall's header hint "Beat a legend on the LEGENDS tour to hang him here." stays at 6/6.
- With the test flag `--target 3`, Gate's race line reads "REACH 3 BEFORE GATE'S CREW GETS 7" (their target is not
  scaled); test flag only.
- The finale's opponents on NORMAL are rated 83-95 against the Kings at 50 (`LEGENDS MATCH` line); balance is P9-30 /
  P9-31's, not judged here.

## Suggested tuning
None from this task (screens only).
