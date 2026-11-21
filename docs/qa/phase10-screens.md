# P10-28 Screens QA (Phase 10, Legends Chapter 2 "the Fathers")

- Build tested: `4b622ee` (branch `ccr-f5c087b2-3ojk5f`, "P10-27: save QA for Phase 10"). Godot 4.3.stable, Linux, xvfb
  + `--rendering-driver opengl3`, `--fixed-fps 60`.
- Isolation: a `git archive` copy with `config/name="Road Trip Hoops P1028"` and a test-only probe autoload (not in the
  repo), every run in its own `XDG_DATA_HOME` / `HOME` (the legends-with-trip run shares the trip run's folder, as the
  process rule allows) and in a private mount namespace with its own `/tmp` (so `--screens` and `--pauseshot` files
  never mix). A second plain copy (no probe) for the headless autoplay / humantest runs. At most 2 Godot processes at
  a time. The probe pauses the test driver while it shoots each step, shoots every game at frames 40-400 and on every
  `sig_*` / `cpu_fadeaways` / `anim_fadeaway` count, scrolls the draft list, taps [you, Father] then a Grandfather on
  the first lineup with two legends (then puts the picks back), and in the Hall picks plaques, opens the mentor
  picker, assigns, opens the SWITCH confirm, then closes and releases.
- Contact sheet of the key shots: `docs/qa/phase10-screens.png` (26 shots, the bug shots captioned in orange).
- Game code: not changed. Chapter 2 goal numbers were being tuned in parallel (P10-23), so the HUD lines were judged
  for fit and readability, not their values.
- Chapter 2 music is still the stand-in (`fallback_music` "newyork", `LEGENDS MATCH ... music newyork`): the owner has
  not picked the track yet (P10-20). Noted, not a bug.

## Runs

| Run | Result |
|---|---|
| `--import` (probe copy and plain copy) | clean, no script errors |
| `--legendtest` (headless) | LEGENDTEST OK |
| `--titletest --stars 24` (xvfb) | TITLE TEST DONE; timeline with Chapter 2 LOCKED |
| ltA: `--legends-test --stars 24 --target 3 --difficulty normal --legends-no-trip --right-handed` (1280) | LEGENDS END, crew kings, 20 games (4 goal tests, 4 retries), both chapters 14/21; Chapter 2 opened by tokens after Chapter 1; 290 shots |
| trA: `--trip-test --target 3 --screens --legends-unlock-all --stars 24` (1280) | TRIP END 24-0 (25 games, 1 replay, 117 screens); drafts `lg_rooftop` (Fathers row) and `lg_steeple`; one legend refused (Grandfather then Father); legend + boss start (Rooftop + Mayor) |
| trB: same, `--left-handed --trip-stop-after memphis` at 1600x720 | TRIP STOP; draft scrolled to both LEGENDS rows; probe lineup flash, picks put back exactly |
| ltB: `--legends-test --legends-chapter fathers --stars 36 --target 3 --difficulty hard --left-handed` at 1600x720 on trB's trip save | LEGENDS END, crew trip (Deuce, Rooftop, Mayor), "ROOFTOP SITS: HONEY PLAYS", tokens 21/21, hall ok, trip save unchanged |
| ltC: `--legends-test --legends-chapter fathers --stars 36 --target 3 --difficulty easy --legends-no-trip` (1280), probe picks all 12 Hall plaques | LEGENDS END, crew kings, 10 games |
| `--autoplay --challenge <id> --difficulty normal --quit-after 1300` for the 6 Fathers and `fin:fathers` (1280) | every `CHALLENGE GOAL` line on screen (below) |
| `--autoplay --challenge <id> --view flat` (Rooftop) | era court flat, goal line fits |
| `--humantest --challenge lg_lockbox` right-handed 1280 and left-handed 1600; `lg_ankles` left-handed 1280; `lg_freight` right-handed 1600 | HUD with the touch controls, both layouts |
| `--humantest --pauseshot --challenge lg_ankles` (1280 right) / `lg_midrange` (1600 left) | PAUSESHOT, twist `era_fathers` |
| full `--autoplay --challenge` games for the signature moves: Midrange (met 15-9), Rooftop (met 15-11, stop 2/2), Ankles (failed 4-10), Lockbox (failed 11-7 "YOU SCORED 3 OF 6"), Eyes Closed (failed 10-16) | every Fathers signature fired and was shot (table below). The separate Freight game was cut by the 30 min background limit and restarted; Freight's `shoulder` was already shot in the Rooftop game |
| 5 `--autoplay`, 2 `--humantest` (headless, Hard, plain copy) | all ended, no script errors (table below) |

The only engine messages in the logs are the xvfb ones (ALSA / dummy audio driver).

## Autoplay / humantest stats (sanity only; this task changes no sim)

| Stat | Mean | Range (5 autoplay) | Target (CLAUDE.md) |
|---|---|---|---|
| Final | RED won 4 of 5 | 16-21, 18-21, 18-21, 21-9, 18-21 | 21-x, loser 12-20 |
| Game length | 9:01 | 6:38 - 10:18 | 7-11 min |
| Shots | 56.8 | 45 - 65 | 55-90 |
| Make rate | 54% | 51% - 67% | about 50% |
| Fouls | 2.6 | 1 - 4 | 1-5 |
| Out of bounds | 1.4 | 0 - 3 | 1-2 |
| Interceptions | 3.0 | 2 - 5 | few |
| Side switches | 1 | 1 - 1 | 1 |
| Shot-clock violations | 0 | 0 | few |
| Offensive rebounds | 30% | 23% - 40% | about 25% |

Humantest: 21-13 (6:27, 54 shots, 4 fouls, 3 interceptions) and 21-18 (8:08, 67 shots, 5 fouls, 5 interceptions),
`pause_test_ok` 1 in both. 5 games say nothing about balance (one 9 below the loser band, one 45-shot game).

## Checks (1280x720 unless marked)

| Screen / feature | Shots (run folder) | Result |
|---|---|---|
| Timeline, Chapter 2 locked: grey pin, "LOCKED", "OPENS AT 36 STARS OR 12 TOKENS", "YOU HAVE 24 STARS" | t0 `hoops_legends` | PASS (note 1) |
| Timeline, Chapter 2 open (by 14 tokens): green pin, PLAY; then both "FINALE WON 14/21" | ltA `0151`, `0287` | PASS |
| Chapter 2 view with the Kings: 6 silhouettes, the detail names the legend ("ROOFTOP"), finale card locked, "THE KINGS AT EVEN RATINGS", NO TRIP note, YOU on Jojo | ltA `0162` | PASS (note 2) |
| Chapter 2 view with the trip crew: "YOUR ROAD TRIP STARTERS", "ROOFTOP SITS: HONEY PLAYS. A legend never plays against himself." (Honey in orange) | ltB `0015` (1600) | PASS |
| Intro, 6 unlock scenes, finale before / after: portraits, name plates, SKIP, text box | ltA `0153`..`0273`, ltB | PASS, every Fathers scene seen |
| Each Fathers challenge HUD line | hud_* `0008_game_f300_ch` | "BLOCK OR STEAL ON ROOFTOP: 0/2", "REACH 11 BEFORE ANKLES'S CREW GETS 10" (**P10-B4**), "MIDRANGE IS ON FIRE: WIN TO 15" (fire ring at tip-off, "MIDRANGE IS COOLED: WIN TO 15" after), "HOLD FREIGHT UNDER 7: 0", "COME BACK FROM 0-2: WIN TO 15" (score starts 0-2), "SCORE 6 ON LOCKBOX: 0" (counts up: 1 after the human's dunk). Finale: no line. All centred 280..1000, clear of the clock and the pause button, at 1280 and 1600 |
| End reasons | sig_* logs | "YOU SCORED 3 OF 6" (score goal), "ANKLES'S CREW GOT 10" (P10-B4), "LOST 10-16", stop "2/2 on lg_rooftop (blocks 1, steals 1)" |
| ISO BALL banner and pause line | ltA `0165`, pause_r / pause_l16 `hoops_pause` | PASS: banner "ISO BALL / Iso ball: crossovers shake defenders, dunks from further out" sits under the goal line (P9-B4 stays fixed); the pause panel's last line says the same |
| Era court `era_fathers` in play, angled | ltA `0164`..`0280`, hud_* | PASS: blacktop, light poles with pools of light, chain fence, crowd on bleachers, painted green keys; reads as its own court (not MIDNIGHT) |
| Era court, `--view flat` | flat_rooftop `0006` | PASS (flat floor and the fallback tokens, as in every flat game) |
| Signature moves in play | sig_* | PASS for all six: Midrange's fadeaway (post up, turn, rise, release, the slide back; `anim_fadeaway` counted, frames shot every 5), Rooftop's cradle dunk (reads as a dunk; no own frames, by design F4), Ankles' double crossover ("SHOOK!", a defender falls), Freight's shoulder-in layup "through DEUCE's block try", Eyes Closed's no-look pass (a normal pass on screen, the edge is in the numbers), Lockbox's chase-down block from behind on a dunk ("BLOCKED!"). As in Phase 9, the defender often covers part of the pose |
| Fadeaway sheet frames | `docs/art/legends_fathers.png` | PASS: only on `lg_midrange` (era colors and `_crew`), others "no extra animation" |
| Hall: two era rows (CHAPTER 1 THE GRANDFATHERS, CHAPTER 2 THE FATHERS, each with its status and tokens), Chapter 3-4 locked rows, header "12/12 LEGENDS - 28/42 TOKENS"; the Fathers plaques in the night-park frame | ltA `0283`, ltB `0136` | PASS, with **P10-B5**, **P10-B6** in the detail |
| Hall detail for all 12 legends (probe picks each) | ltC `0135`..`0146` | 10 of 12 fit; Rooftop and Freight: **P10-B5**; Rooftop: **P10-B6**; locked plaques: note 3 |
| Mentor picker (trip roster, 6 tiles: YOU / STARTER / BENCH, NO MENTOR; drafted legends left out), assign flash, SWITCH confirm | ltB `0138`..`0140` (1600) | PASS |
| Draft: two LEGENDS rows ("UNLOCKED IN LEGENDS - THE GRANDFATHERS" orange bar, "... - THE FATHERS" seafoam bar, "6 TO DRAFT" each), night-park frames on the Fathers cards | trA `hoops_screen_10_draft`, trB `0001_draft_scroll_fathers`, `0002_draft_scroll_end` | PASS, with **P10-B5** (role line cut) |
| Draft joining line: Rooftop's portrait and his line, "DORIAN "ROOFTOP" ASHCOMBE JOINS THE CORNFIELD KINGS!" wraps inside the panel | trA `0001_draft_hint` (1280) | PASS (P9-B3 stays fixed) |
| Lineup: LEGEND tags in each era's color (Steeple orange, Rooftop seafoam), DRAFTED, BOSS; legend + boss start | trA `hoops_screen_31_lineup` | PASS |
| Lineup one-legend rule line | trB `0007_lineup_one_legend_flash` (1600) | PASS: "ONLY ONE LEGEND CAN START. Bench ROOFTOP first." in orange; Steeple not picked; picks put back |
| 1600x720: timeline, chapter view, Hall, picker, confirm, stories, draft, lineup, game HUD, pause | ltB, trB, hum_*_l16 / r16, pause_l16 | PASS. **P9-B7 is gone**: the timeline backdrop now fills the screen (its edge columns stretched, the rail runs to both edges); the chapter view's dimmed backdrop does too |
| Left-handed: game HUD (joystick right, STEAL / SWITCH bottom left, pause top-right, goal line clear) at 1280 and 1600 | hum_ankles_l12, hum_lockbox_l16 | PASS. The menu screens don't mirror (by design, no joystick) |
| Buttons under 110 px tall | all | none found (same sizes as Phase 9) |
| Hard rule by eye (every screen above, the six sheets in `docs/art/legends_fathers.png`, the portraits in `docs/art/legends_fathers_portraits.png`, every Fathers line in `story_text.gd`, the bios, signature and perk texts) | all | PASS, with two cautions for the owner (note 4) |

### Notes (not filed)
1. The locked timeline panel says "YOU HAVE 24 STARS" but not the tokens, although the gate is stars **or** tokens (the
   header shows the token total). Could read "YOU HAVE 24 STARS, 7 TOKENS".
2. The chapter view's header "CHAPTER 2 - ISO BALL RULES - TOKENS 14/42" shows the all-chapters total, while the
   timeline panel and the Hall row show the chapter's own (0/21). Not wrong, a little confusing next to each other.
3. The Hall's locked plaque detail still says "?" while its challenge line names him ("SCORE 6 POINTS YOURSELF ON
   LOCKBOX AND WIN") and the chapter view shows his name since the P9-B6 fix. Same question as P9-B6, now only in the
   Hall (`scripts/hall.gd` `_detail_locked()`): show the name there too, for consistency.
4. Hard rule cautions (no change needed by my reading; for the owner's eye): **Midrange** is an isolation scorer with a
   turnaround fadeaway in a purple ("grape") kit; the kit is grape and ice / white, not purple and gold, his number is
   28 and his hair a low fade, so no one real player's combination; if the owner wants more distance, a non-purple
   kit is the cheap change. **Freight** (huge low-post center, shaved head, short goatee) shares two looks with the
   best-known 2000s center; his headband, steel and citrus kit and number 48 keep him apart. The look spread the name
   check asked for holds on the sheets and portraits: Ankles has twists and a headband but no cornrows or sleeve;
   Rooftop the cornrows and a left arm sleeve, no headband; Lockbox a right arm sleeve and a buzz cut. No real name,
   nickname, slogan, brand or tour name anywhere.
5. The Hall's no-trip mentor picker (P9-B5) was not re-shot in this pass (the no-trip Hall visit picked locked
   plaques); the trip roster picker was.

## Bugs (filed on `docs/BOARD.md`)

### P10-B4 (Low, cosmetic): "ANKLES'S CREW" in the race goal's HUD line and its failure reason
- Steps: `--autoplay --challenge lg_ankles` (or the tour's Ankles challenge).
- Expected: "REACH 11 BEFORE ANKLES' CREW GETS 10", as the data line and the chapter view say.
- Actual: HUD "REACH 11 BEFORE ANKLES'S CREW GETS 10" and, on a loss, "ANKLES'S CREW GOT 10" (hud_lg_ankles `0008`,
  sig_lg_ankles log). `scripts/challenge.gd` lines 158 and 239 build `"%s'S CREW"`.
- Fix: a small possessive helper in `challenge.gd` (`name + "'"` when the name ends in S, else `name + "'S"`) used on
  both lines.

### P10-B5 (Medium-low, cosmetic): long archetypes are cut on the draft cards and in the Hall detail
- Steps: a draft with the Fathers row (trip test above), or the Hall on Rooftop / Freight.
- Expected: the whole role line.
- Actual: draft cards "HIGH-FLYING SHOOTING GUA" and "LOW-POST BULLDOZER CENT" (trB `0001`); Hall "HIGH-FLYING
  SHOOTING GUAF" and "LOW-POST BULLDOZER CENTE" (ltC `0141`, `0144`; 1280 and 1600). The lineup shows it in full
  (smaller font). Chapter 1's longest ("BRUISING POWER FORWARD", "NO-LOOK FLOOR GENERAL") fit on the draft cards.
- Fix: shrink the archetype label to fit its width (`hall.gd` already has `_fit_font()`; the same on the draft card
  role label in `scripts/draft.gd`), or shorter archetypes in `legends_data.gd` ("HIGH-FLYING GUARD", "BULLDOZER
  CENTER").

### P10-B6 (Medium-low): Rooftop's signature text runs into the MENTOR PERK heading in the Hall
- Steps: HALL, tap ROOFTOP (once unlocked).
- Expected: the signature text above the MENTOR PERK heading.
- Actual: the text takes 3 lines ("Cradle dunk: he rocks the ball in his arm in / the air, and his dunks slip past
  part of a / contest") and the third line is drawn over "MENTOR PERK" (ltB `0136` at 1600, ltC `0141` at 1280). The
  other 11 texts take 2 lines.
- Fix: shorten the text in `legends_data.gd` (e.g. "Cradle dunk: his dunks slip past part of a contest"), and/or let
  `hall.gd` `_detail_open()` place the perk block under the measured text height (or shrink the text to 2 lines).

## Best screenshots for the owner (scratch, not committed)
Listed in the hand-off report.

## Suggested tuning
None from this task (screens only).
