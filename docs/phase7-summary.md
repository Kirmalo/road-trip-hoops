# Phase 7 summary: ready to release (version 1.0.0)

Play it at https://kirmalo.github.io/road-trip-hoops/ (reload the page once to get the new build). This is the
version that goes on itch.io.

## What's new in the game
- **How to Play**: a new button on the title. 9 picture pages taken from the game itself: controls, turbo, shooting,
  dunks and alley-oops, crossover, CALL for the ball, defense, on fire, and the road trip. Swipe, or tap `<` `>`;
  BACK goes to the title. The text under each picture is in `scripts/howto.gd` (`PAGES`), so you can change it on
  the tablet.
- **LEFT-HANDED** (Settings): the joystick moves to the right half and the A/B buttons to the bottom left. The pause
  button stays top-right. It is remembered.
- **MUSIC volume** (Settings): a slider next to MUSIC ON/OFF, separate from SOUND. Remembered. The pause panel is
  unchanged, as you asked.
- **Version label**: `v1.0.0` small in the bottom-right of the title, and at the top of CREW & CREDITS.
- **App icon**: the van under the basketball sunset (your pick). It is also the browser tab icon and the Android icon.
- **Android back gesture**: in a game it pauses (and back again resumes); on Settings, How to Play, the map and the
  other screens it goes BACK; only on the title does it close the app.
- **Credits**: CREW & CREDITS lists every artist and track with its license, and ends with the Godot engine license
  (it has to ship with the game).

## The release kit (for itch.io)
Everything is in the repo, ready for you to upload. Follow `docs/release/UPLOAD.md` step by step (about 30 minutes).
- **The web ZIP**: `road-trip-hoops-1.0.0-web.zip` (about 38 MB, 8 files). Upload it as is, don't unzip it. The team
  sent it to you in the chat with this summary (UPLOAD.md, part 0). It is built by `tools/build_web.sh --zip`
  into `build/release/`.
- **The page text**: `docs/release/itch_page.md` (title, tagline, description, tags, credits). Copy and paste.
- **The cover**: `docs/release/cover.png` (630 x 500).
- **5 screenshots**: `docs/release/screenshots/shot_1.png` to `shot_5.png` (1280 x 720). Together they show a dunk in the Memphis gym,
  the rainy Seattle park, the trip map, a story scene, and the New York cage. All five on one sheet:
  `docs/art/store_screens_preview.png`.
- **Price**: "$0 or donate" (pay what you want, free with an optional tip), as you decided.

## Android
- The **debug APK** builds and checks out: `road-trip-hoops-1.0.0-debug.apk`, 75 MB, package
  `io.github.kirmalo.roadtriphoops`, landscape, no permissions, 32- and 64-bit ARM. You can use it to try the
  app on your tablet. Don't upload it to itch: an APK signed with your real key can't install over it, so before
  installing the release APK later you uninstall the debug one (and lose its trip save).
- The **release APK** waits for your signing key ("later", as you decided). When you are ready,
  `docs/release/ANDROID.md` has the steps: make the key on a computer, back it up twice, then export on the tablet
  or have the team's script build it. Then UPLOAD.md part B adds it to the same itch page.

## What QA found (docs/qa/phase7.md)
- **Release-ready.** No crash or script error in any test: 16 single games, 5 whole trips (one full length, one with
  a lost game, one stopped and resumed), and a whole trip in the browser (53 games, 65 minutes).
- **In the browser**, inside a page built like itch's: the title loads, How to Play, Settings (LEFT-HANDED, the
  MUSIC slider, FULL SCREEN), a Quick Game played by touch with the mirrored controls, a trip game, and the save
  surviving a reload all work. On a phone-sized screen nothing is cut off.
- **Download size**: the game data is 32.0 MB (2 MB smaller than Phase 6).
- **One small bug, P7-B1**: on the pause panel, the second tap on QUIT? (or RESTART?) was sometimes ignored in the
  browser test (7 of 20 tries). Tapping again worked, and nothing is lost. It may only be the test setup (it never
  happened without screenshots being taken in between), so please try it on the tablet: pause, QUIT, QUIT, a few
  times.
- Quick Games run a little longer than in Phase 6 (about 13 minutes, with more dunks). Nothing in the game play
  changed in Phase 7; it comes from your tuning after Phase 6 (the opponent crew plays its trip style). Still in
  the normal range.

## Known limits
- On the result, stat points and recruit screens, the Android back gesture does nothing on purpose (they need a
  choice from you first).
- UPLOAD.md was written without opening itch.io (it can't be reached from here), so some field names may differ a
  little. Pick the one that means the same.
- itch asks whether the project uses generative AI. That answer is yours. UPLOAD.md (step A7) lists the facts.
- When you upload a new web ZIP to itch later, we expect saves to survive, but we couldn't test it. Check that
  CONTINUE is still there after the first update.
- Exporting the APK from the Godot Android editor on the tablet (ANDROID.md part 2) is written from the docs and not
  tried. If it doesn't work, the team's script can build it.
- Installing and playing the APK could not be tested here (no Android device or emulator).

## Try it on the tablet
1. In the browser: open the game, try HOW TO PLAY, switch LEFT-HANDED on and play a Quick Game, move the MUSIC
   slider, then pause and QUIT twice a few times (P7-B1).
2. If you install the debug APK: follow the 10 steps in section 6 of `docs/qa/phase7.md` (installs, opens in
   landscape, sound on the first tap, the back gesture, the save after closing the app). Tell us what failed.
