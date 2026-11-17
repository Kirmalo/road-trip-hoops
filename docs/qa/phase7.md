# P7-40 Phase 7 QA: final release check

**Build tested:** `3cf6c7d` (Merge commit 'ff95bf5', P7-S1 store screenshots), branch `ccr-f5c087b2-3ojk5f`, version
1.0.0. Godot 4.3 stable (Linux), 4 cores, shared between the jobs below (headless trips, autoplay and Chromium ran at
the same time). Playwright 1.63 Chromium, `--use-angle=swiftshader --enable-unsafe-swiftshader`. No script was
changed for this pass.

**Verdict:** release-ready. Nothing blocks the release. One low-impact bug is filed: P7-B1, an intermittent ignored
second tap on QUIT?/RESTART? in the web build, which may be a harness effect. The Android install itself still has to
be checked on the owner's tablet (checklist in section 6).

## 1. Pass / fail

| Check | Result |
|---|---|
| `--import` | PASS (clean, no script or parse error) |
| `--twisttest` | PASS (`TWISTTEST OK`) |
| `--anim-test` | PASS (`ANIM OK`, 69 sheets, 0 empty frames, 0 without points; the 3 warnings are its own bad-sheet self tests) |
| `--triptest-data` / `--triptest-data --load` | PASS / PASS (`TRIPDATA OK`; the "save version 99" warning is its own test) |
| `--ratingtest` | PASS (`RATINGTEST OK`) |
| `--titletest` (headless and under xvfb) | PASS (`TITLE TEST DONE`, settings.cfg put back byte for byte: true) |
| `--backtest` | PASS (`BACKTEST OK`, 15 steps) |
| `--trip-test --target 3` | PASS (`TRIP END`, 41 games, record 24-17, 316 s) |
| `--trip-test --target 3 --trip-force-loss 5` | PASS (game 5 lost 0-3, the lineup came back for HOMETOWN game 3, `TRIP END`, 42 games, 286 s) |
| `--trip-stop-after memphis` then `--trip-resume` | PASS (`TRIP STOP` at new_orleans game 1, record 9-17; the resume picked up there, `TRIP END`, 159 s + 142 s) |
| `--trip-test` full length (11/15/21) | PASS (`TRIP END`, 40 games, record 24-16, 1942 s) |
| 10 `--autoplay` to 21 | PASS (all `FINAL`, stats in section 2) |
| `--humantest` (right-handed) | PASS (FINAL 21-18, 8:46; pause test ok) |
| `--humantest --left-handed` | PASS (FINAL 17-21, 10:06; pause test ok) |
| 3 `--quick-teams` pairings | PASS (all `FINAL`, section 2) |
| Web ZIP built (`tools/build_web.sh --zip`) | PASS: `build/release/road-trip-hoops-1.0.0-web.zip`, 8 files, flat, `index.html` at the root |
| Web: loads to the title in the cross-origin itch-style iframe, no console errors | PASS |
| Web: How to Play, swipe through all 9 pages, the arrows, BACK | PASS |
| Web: Settings LEFT-HANDED on, the MUSIC slider, FULL SCREEN in the iframe | PASS (`document.fullscreenElement` = the canvas, and back to null when switched off) |
| Web: Quick Game by touch, left-handed (joystick on the right, A/B on the left), pause, resume, quit | PASS, but see P7-B1 (the second QUIT tap was sometimes ignored) |
| Web: ROAD TRIP, NEW TRIP, level, story, map, GO, story, lineup, PLAY, a trip game | PASS |
| Web: quit a trip game goes to the map; the save survives a reload, CONTINUE lit | PASS |
| Web: version on the title (`v1.0.0` bottom-right) and in CREW & CREDITS; Godot license at the end of the credits | PASS |
| Web: phone landscape (Pixel 7 landscape, 863x360 CSS px, DPR 2.625) | PASS (nothing cut off on title, Settings, How to Play, Quick Game panel, game HUD, pause, map, lineup) |
| Web: full trip through `GODOT_CONFIG.args` (`--trip-test --target 3`) | PASS (`TRIP END`, 53 games, 65 min real time) |
| APK debug build (`tools/build_android.sh`) | PASS (32 s) |
| APK: aapt / apksigner | PASS (section 4) |
| Visual spot checks | PASS (section 5) |
| Sizes | section 7 |

## 2. Headless games

### 10 Quick Game `--autoplay` to 21 (Kings vs Bridge Runners, Hard; RED plays its trip style "inside")

| Stat | Mean | Range | CLAUDE.md typical | Phase 6 final (20 games) |
|---|---|---|---|---|
| GAME LENGTH (min) | 12.96 | 10.8-17.2 | 10-15 | 10.90 |
| Shots | 97.4 | 77-121 | 75-120 | 87.0 |
| Loser points | 17.8 | 14-20 | 12-20 | 16.10 |
| Fouls | 5.0 | 3-8 | 2-6 | 2.90 |
| Free throws | 3.1 | 0-5 | - | - |
| Out of bounds | 2.5 | 1-5 | 2-3 | 2.05 |
| Side switches | 1.0 | 1-1 | 1 | 1 |
| Interceptions | 4.6 | 2-8 | few | 3.75 |
| Shot-clock violations | 0 | 0 | few | 0 |
| Dunks | 31.5 | 26-39 | - | 25.5 |
| BLUE wins | 6/10 | - | - | 12/20 |

Finals: 20-21, 16-21, 21-20, 21-19, 21-14, 21-20, 21-18, 16-21, 19-21, 21-16. No game hung, no stuck ball or player, no
script error.

All means are inside CLAUDE.md's typical ranges. Two single games ran over 15 minutes (16:11 and 17:13), one had 121
shots and one had 8 fouls. Against the Phase 6 final numbers, length (+2.1 min), shots (+10), dunks (+6) and fouls
(+2.1) are up by more than the noise of 10 games. **This is not a Phase 7 change.** No simulation script changed in
Phase 7 (`git diff 073c3a5 HEAD` touches only audio, difficulty flags, flow, howto, main, menu, pause, title and
touch_controls). The cause is the owner's tuning change after Phase 6 QA (`073c3a5`: in Quick Game the opponent crew
plays its road-trip style, so the Bridge Runners now play "inside"). Phase 6 QA measured the build before that change.
**Proposal for the lead:** take these as the new Quick Game reference, or run a 40+ game batch on `073c3a5` or later
first, and update CLAUDE.md's "typical game" line if the longer games stay. No tuning is suggested here, because
Phase 7 does no balance work.

### Human and team pairings

| Run | Final | Length | Shots | Fouls | OOB | Switch | Int. | Dunks |
|---|---|---|---|---|---|---|---|---|
| `--humantest` | 21-18 | 8:46 | 84 | 5 | 1 | 1 | 5 | 28 |
| `--humantest --left-handed` | 17-21 | 10:06 | 93 | 6 | 4 | 1 | 4 | 41 |
| `--quick-teams concrete_crowns,county_line` (RED balanced) | 21-17 | 12:58 | 103 | 3 | 3 | 1 | 1 | 21 |
| `--quick-teams county_line,cornfield_kings` (RED no style) | 21-12 | 8:09 | 57 | 5 | 2 | 1 | 5 | 10 |
| `--quick-teams bridge_runners,concrete_crowns --difficulty normal` | 20-21 | 13:02 | 114 | 5 | 4 | 1 | 4 | 42 |

Both humantests ran the pause test (`pause_test_ok` 1; one open and one resume) with no leak of the stray A tap or
joystick touch. The left-handed run was as clean as the right-handed one. HUMANTEST lines: right steals timed 16/18,
blocks timed 5/6; left steals timed 15/18, blocks timed 3/5. The County Line vs Kings game was short (57 shots), but
that is one game.

### Trips (headless)

| Run | Games | Record | Wall time | End |
|---|---|---|---|---|
| `--trip-test --target 3` | 41 | 24-17 | 316 s | `TRIP END` |
| `... --trip-force-loss 5` | 42 | 24-18 | 286 s | `TRIP END`; game 5 "LOST 0 - 3, forced", retried as game 6 |
| `... --trip-stop-after memphis` | 26 | 9-17 | 159 s | `TRIP STOP after memphis` (new_orleans game 1, saved) |
| `... --trip-resume` | 21 | 24-23 at the end | 142 s | `TRIP END` |
| `--trip-test` full length | 40 | 24-16 | 1942 s | `TRIP END`; 8 games to 11, 11 to 15, 21 to 21; lengths 3:53-13:26 |

## 3. Web release ZIP (Chromium, Playwright, touch)

Setup: `tools/build_web.sh --zip`, unzipped into a scratch folder and served by `python3 -m http.server` on
`127.0.0.1:8601`. The host page was served from `localhost:8602`, so the game ran cross-origin like on itch. It holds
`<iframe width=1280 height=720 allow="autoplay; fullscreen *; ..." allowfullscreen>`. The browser context was
1280x720 with `hasTouch`. Taps, drags and two-finger joystick-plus-button presses were sent with CDP
`Input.dispatchTouchEvent`, so they reached the cross-origin frame as real touches. A second context used
`devices['Pixel 7 landscape']` with a full-window iframe.

- **Load:** the title showed in about 10-14 s (SwiftShader), with `v1.0.0` bottom-right. Console: no errors. The only
  warnings came from the host page's `allow` list ("Unrecognized feature: 'monetization' / 'xr' / 'web-share'",
  "Allow attribute will take precedence over 'allowfullscreen'"), which is itch's iframe and not the game.
- **How to Play:** left swipes went through all 9 pages: CONTROLS, TURBO, SHOOTING, DUNKS AND ALLEY-OOPS, CROSSOVER,
  CALL FOR THE BALL, DEFENSE, ON FIRE, THE ROAD TRIP. The page dots follow, the `>` arrow dims on the last page, `<`
  and `>` work, and BACK goes to the title.
- **Settings:** LEFT-HANDED: ON, the MUSIC slider dragged to about half (the knob follows the finger), FULL SCREEN
  works inside the iframe (canvas fullscreen) and switches back off. LEFT-HANDED was still ON after a page reload.
- **Quick Game:** YOUR TEAM and OPPONENT cycle (on a fresh install only the Kings and the Bridge Runners exist, so a
  tap swaps them; a second tap within the panel's tap guard after the scene reload is ignored, which is by design).
  I played NORMAL for about 30 s of joystick drags on the right half and A/B taps on the left. The floating joystick
  shows where the right thumb lands and the player runs the way it is pushed. SHOOT/PASS and STEAL/SWITCH sit
  bottom-left. Pause (top-right) opens the panel and the game stops. RESUME continues (the shot clock ran on).
  QUIT? then QUIT goes to the title, but see **P7-B1**.
- **Trip by touch:** ROAD TRIP showed "No trip saved yet" with CONTINUE dimmed. NEW TRIP, NORMAL, then the story taps
  through to the map (HOMETOWN, Game 1 of 3, to 11, vs COUNTY LINE). GO, the story again, then LINEUP (Deuce YOU, Jojo,
  Tank vs Skip/Dale/Rusty) and PLAY. The game at the barn court started with the left-handed controls. Pause, QUIT, QUIT
  went back to the map.
- **Save after a reload:** after a page reload, ROAD TRIP shows "HOMETOWN, GAME 1 - 0-0 - NORMAL" with **CONTINUE
  lit**. CONTINUE opens the map.
- **Credits:** CREW & CREDITS starts with "ROAD TRIP HOOPS v1.0.0". Dragging the list to the end shows "GODOT ENGINE
  LICENSE" and the full MIT text, ending at "SOFTWARE.".
- **Phone landscape (Pixel 7, 863x360 CSS):** title, Settings, How to Play, the Quick Game panel, the game (HUD, pause
  button, joystick ring, PASS/SHOOT all inside the view), the pause panel, the map (pillarboxed, info box and GO
  inside) and the lineup. Nothing is cut off. Pause, then QUIT twice (0.7 s apart), worked here.
- **Full trip on the web runtime:** a copy of `index.html` had `GODOT_CONFIG.args` set to
  `["--", "--trip-test", "--target", "3"]`, served from its own port and opened in headless Chromium (no iframe). The
  `--` is needed: with `["--trip-test", ...]` the game started on the title, because without the separator Godot sees
  them as engine args and not user args. **Result: `TRIP END` after 3,913 s (65 min) in real time**: 53 games (all 7 cities,
  then the New York bracket), record 24-29 (the CPU-vs-CPU trip retried more often than headless), roster of 10, every
  screen stepped through. No script error or page error during the run. At the quit, after `TRIP END`, the engine
  printed its usual exit-time messages: "ObjectDB instances leaked at exit", "18 resources still in use at exit", and
  on the web only "Pages in use exist at exit in PagedAllocator: WorkerThreadPool". The native runs print the same
  leak lines when they quit. They are not game errors, because they come at the forced quit of the test.

## 4. Android APK

`tools/build_android.sh` (debug) built `build/release/road-trip-hoops-1.0.0-debug.apk` in 32 s, using the stand-in
SDK from the apt tools.

| Check | Result |
|---|---|
| package | `io.github.kirmalo.roadtriphoops` |
| versionCode / versionName | 1 / 1.0.0 |
| label | "Road Trip Hoops" (every locale) |
| icon | `res/mipmap-anydpi-v26/icon.xml` (adaptive) plus the PNG icons, 48-192 px; the 192 px icon is the van under the ball sunset |
| orientation | `screenOrientation` = landscape; `uses-feature android.hardware.screen.landscape` |
| permissions | none: `aapt dump permissions` lists no `uses-permission` (the only `android:permission` is Godot's own `DUMP` guard on a component, from the template) |
| ABIs | `arm64-v8a`, `armeabi-v7a` |
| sdk | min 21, target 34; GLES 3.0 |
| debuggable | yes (debug build, expected; the `--release` build is the owner's) |
| `apksigner verify` | verified, v1 + v2 + v3 schemes, 1 signer (Godot debug cert `CN=Godot, OU=Godot Engine`) |
| no secrets / no stray files | no keystore, `build/`, `docs/` or `tools/` in the APK |
| size | 78,625,450 bytes (75 MiB). Most of it is the two engine libraries (`libgodot_android.so` 71.5 MB armeabi-v7a + 65.5 MB arm64, uncompressed sizes) |

Not tested: install, launch and play. There is no device or emulator here (no KVM, no system images), and
`--release` was not run because there is no owner key.

## 5. Visual spot checks

I looked at each image:
- Title (web and xvfb): name, crew, van line, 5 buttons, road sign, `v1.0.0` bottom-right, all readable.
- Settings (web; xvfb `/tmp/hoops_settings_left_handed.png`): MUSIC ON/OFF plus slider, SOUND slider, LEVEL, FULL
  SCREEN and LEFT-HANDED all inside 1280x720; LEFT-HANDED: ON shows.
- How to Play: all 9 pages on the web (pictures, text and dots fit). Pages 1 (CONTROLS) and 9 (THE ROAD TRIP) were
  checked closely.
- Left-handed game (xvfb `--shots --left-handed` at frames 240/900/1800, and on the web): joystick ring bottom-right,
  SHOOT/PASS (STEAL/SWITCH on defense) bottom-left, HUD and pause button clear. As in the right-handed layout, the
  two buttons can cover a player near the left baseline for a moment. This is the mirror of today's layout, not new.
- Credits end (xvfb `/tmp/hoops_crew_end.png`, and on the web): the Godot MIT notice is complete and readable.
- Android icon: clear at 192 px.

## 6. Owner's tablet checklist (APK)

1. Copy `road-trip-hoops-1.0.0.apk` (your signed release build; or the debug APK for a trial) to the tablet. Open it,
   allow "install unknown apps" for the file manager or browser if asked, and install. Expect: it installs without
   asking for any permission.
2. Find "Road Trip Hoops" with the van-and-sunset icon in the app drawer and open it. Expect: it opens in
   landscape, does not rotate to portrait, and shows the title with v1.0.0 bottom-right.
3. Tap anything. Expect: sound and music start from the first tap.
4. HOW TO PLAY: swipe through all 9 pages, then BACK.
5. SETTINGS: turn LEFT-HANDED on, move MUSIC and SOUND, go back. Start a QUICK GAME on NORMAL. Expect: the joystick
   appears under your right thumb, the A/B buttons are bottom-left, and two fingers at once (move and shoot) work.
6. In the game, tap the pause button, then RESUME. Pause again, tap QUIT, then QUIT again. Expect: the title (try it a
   few times, this is P7-B1).
7. Android back gesture or button: in a game it should pause; on Settings, How to Play or the map it should go back;
   only on the title should it close the app.
8. Start a ROAD TRIP (NEW TRIP), play or quit the first game so you are back on the map. Then close the app fully
   (recent apps, swipe it away) and open it again. Expect: ROAD TRIP shows CONTINUE lit with your city and record,
   and LEFT-HANDED is still on.
9. Lock the screen during a game, then unlock it. Expect: no crash, the game is still there, and no music plays
   while the screen is locked. (Not checked here; report what it does.)
10. Later updates: install the new APK over the old one (same key, higher version code). Expect: the trip save and
   settings are kept.

## 7. Sizes

| File | Bytes | Size | Budget |
|---|---|---|---|
| `index.pck` | 32,034,864 | 30.55 MiB (32.0 MB) | owner "about 31 MB" (VISION); board 34.2 MB (Phase 6's 34,181,680) |
| `index.wasm` | 35,376,909 | 33.7 MiB | engine, unchanged |
| web ZIP `road-trip-hoops-1.0.0-web.zip` | 37,628,606 | 35.9 MiB | itch: 8 files (limit 1000), largest 35.4 MB (limit 200 MB) |
| `build/web` total (8 files) | 67,790,682 | 64.7 MiB | |
| debug APK | 78,625,450 | 75.0 MiB | (no budget set) |
| `assets/howto/` | 524,241 | 0.5 MiB | pictures cap about 2.5 MB |

`index.pck` is 2,146,816 bytes smaller than Phase 6's 34,181,680. It is under 31 MiB, and 32.0 in decimal MB, so it
sits at the owner's "about 31 MB".

## 8. Bugs

- **P7-B1 (low, intermittent, web)**: the second tap on the pause panel's QUIT? / RESTART? is sometimes ignored.
  - Steps (release ZIP, Chromium 1280x720, CDP touch or `page.mouse.click`): Quick Game NORMAL; after ~4 s tap the
    pause button; ~1 s later tap QUIT (it turns gold, "QUIT?"); 0.4-1.5 s later tap QUIT again.
  - Expected: the title.
  - Actual: in 7 of 20 tries nothing happened; "QUIT?" stayed until the 2.5 s confirm window ran out and went back to
    "QUIT". RESTART did the same once.
  - It always worked on a third tap, and when another panel button (MUSIC) was tapped in between. 8/8 passed in a loop
    without screenshots between the taps, 3/4 passed with a screenshot between them, 1/1 passed on the phone context,
    and 2/2 passed natively under xvfb (touch and mouse through `Input.parse_input_event`).
  - Each failure had a SwiftShader screenshot or a page reload close to the taps, so it may be the harness. The cause
    is not found. Filed in `docs/BOARD.md` for an on-device check (tablet checklist step 6).

No other bugs. No script errors anywhere: import, the 9 test modes, 16 headless games, 5 headless trips, or the
Chromium console.

## 9. Not tested

- Install, launch, touch, back gesture and save on a real Android device (no emulator here); the checklist above
  covers them.
- The `--release` APK (needs the owner's key).
- The real itch.io page (the owner uploads). The iframe harness stood in for it.
- Real audio output: headless and SwiftShader have no sound device. Only the MUSIC slider's movement was checked.
- Real GPU frame rate on the web: SwiftShader is a CPU renderer, so its frame rate says nothing about a tablet.
