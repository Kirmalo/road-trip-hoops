# Task Board

Current phase: **Phase 7: release** (planned 2026-11-17 by `lead-producer`). The Phase 6 board is archived in
`docs/board-phase6.md` (Phase 5: `docs/board-phase5.md`, Phase 4: `docs/board-phase4.md`, Phase 3:
`docs/board-phase3.md`, Phase 2: `docs/board-phase2.md`, Phase 1: `docs/board-phase1.md`).

**STATUS: BUILT AND QA'D (2026-11-17).** Every Phase 7 task is merged and done except **P7-42** (the release
files to the owner and the check-in) and the open bug **P7-B1**. Q1-Q5 are answered (below); the Android signing key
is "later" (VISION "Phase 7 signing key"). Final QA: `docs/qa/phase7.md` (release-ready). The phase summary for the
owner is `docs/phase7-summary.md`. The plan below is kept as written; the task status is in Todo / Doing / Done.

Scope (from `docs/VISION.md`: roadmap Phase 7, the rows "Phase 6 check-in", "Phase 6 tuning check-in" and
"Phase 7 design"):
1. **Settings.** Music volume and sound volume as separate sliders, the difficulty, and a left-handed layout
   (joystick on the right, buttons on the left).
   - **What exists today:**
     - Settings (`title.gd`) has MUSIC ON/OFF, FULL SCREEN, a SOUND slider and LEVEL (EASY / NORMAL / HARD). The
       difficulty is done, so it is only checked.
     - The pause panel (`pause.gd`) has MUSIC ON/OFF, FULL SCREEN and a SOUND slider.
     - There is no music volume.
     - `touch_controls.gd` puts the joystick on the left half and A/B at the bottom right.
2. **How to Play.** Picture pages reached from the title:
   - pages: controls, flicks (crossover), pump fake, CALL, steals, blocks, dunks and alley-oops, turbo and stamina,
     on fire, the trip basics;
   - touch: swipe or arrow buttons, and BACK;
   - **the pictures come from the game itself**: screenshots captured by a test mode, finished by a `tools/art`
     script in the approved style (arrows, a thumb, button callouts). Nothing hand-drawn or downloaded;
   - no playable tutorial (VISION "Phase 7 design").
3. **itch.io HTML5 release.** A ZIP with `index.html` at its root for itch's web embed (1280x720, fullscreen button,
   mobile friendly; threads are already off), built by `tools/build_web.sh --zip`.
4. **Android APK** on the same itch page (no Google Play). The work:
   - an Android export preset: landscape, icon, app name, package id (Q1), version, minimal permissions;
   - a script that builds a debug APK here and a release APK when the owner's keystore comes in through environment
     variables (never committed);
   - exact steps for the owner to create the key and export from the Godot Android editor (Q5).
5. **Store page** (owner uploads; VISION "Phase 7 design"):
   - itch page text;
   - a 630x500 cover;
   - 3-5 screenshots at 1280x720 captured from the game;
   - `UPLOAD.md` with the owner's step-by-step instructions;
   - price: pay what you want (free, optional tip).
6. **Release QA and docs.**
   - Final release QA: a full trip on the web build in Chromium, the touch walk, the APK checks (see P7-40) and
     the version number visible in the game.
   - README, CLAUDE.md and CREDITS.md complete for a public release. Every CC-BY attribution is shown in the
     game's CREW & CREDITS screen, along with the Godot license notice.

Not in scope (owner decisions; anything new goes to the owner first):
- Google Play.
- A playable tutorial.
- New gameplay or balance changes.
- New cities, crews or music.
- Restyling the screens.
- Localization.
- Controller support.
- Achievements and online features.
- A first-launch prompt (unless Q3 picks it).

Format: `ID | task | owner role | files | done when | depends on | blocked by owner questions`

## Rules for every task in this phase
- **Godot 4.3.** Don't use `:=` when the right side is untyped (`game.x`, `cfg.get_value()`,
  `ProjectSettings.get_setting()`, `JSON.parse_string()`, `min`/`max`/`clamp`); use an explicit type or
  `minf`/`maxf`/`clampf` instead. Tuning constants and layout numbers go at the top of the script they belong to,
  each with a comment.
- **Touch first.**
  - Every new screen works with taps and swipes alone: big buttons, BACK top-left like Settings and Crew.
  - Keyboard is for desktop testing only: Escape = BACK, Left/Right = page.
- **No new `.tscn` scenes.**
  - New screens are `.gd` CanvasLayers built in code with `ui_kit.gd` and registered in `flow.gd` `SCREENS`.
  - New test drivers are `.gd` files loaded by a flag, like `trip_test.gd` / `anim_test.gd`.
- **Defaults are today's game.** A fresh install, and every test mode without the new flags, must look, sound and
  play exactly as today:
  - right-handed layout;
  - music volume 1.0 = today's `MUSIC_DB`;
  - no change to the sim.

  Every gameplay task runs 3 `--autoplay`, 1 `--humantest`, `--trip-test --target 3` and `--titletest`. All must
  reach `FINAL` / `TRIP END` / the title test's end with no script errors.
- **Settings live in `user://settings.cfg`, section `"settings"`**, next to `sfx_volume`, `fullscreen` and the
  level. Test runs never write the owner's file: follow the existing pattern (`_test_fs` in title.gd,
  `user://settings_test.cfg` for unlocks).
- **No secrets in git.** No keystore, password or alias in any committed file, script default or log line. The
  release key reaches the build only through environment variables. `.gitignore` covers `*.keystore`, `*.jks`
  and `build/`.
- **Assets.**
  - Pictures, the icon and the cover are generated by `tools/art/` scripts from the game's own captures or its
    approved art (style sample v1, the players in `docs/art/players_v3_moves.gif`, comic portraits v2).
  - Every new asset gets a `CREDITS.md` row.
  - No texture larger than 2048 x 2048.
  - How to Play pictures: at most about 2.5 MB together (web `index.pck` is 34.2 MB today).
- **One task per file per wave** (parallel plan below). A task touches only the files it lists. If it needs another
  file, it stops and tells the coordinator.
- **The project must still open from a ZIP in the Godot 4.3 Android editor.** New `project.godot` keys must exist
  in 4.3. Export presets must not break opening the project when the Android templates are missing (Godot only
  warns).

## Shared contract (names fixed now so parallel tasks can call each other)

### Settings (P7-01 `difficulty.gd`, P7-02 `audio.gd`)
| Key in `settings.cfg` [settings] | Type, default | Owner script | API |
|---|---|---|---|
| `left_handed` | bool, `false` | `difficulty.gd` | `static func is_left_handed() -> bool`, `static func set_left_handed(on: bool) -> void` (saves) |
| `music_volume` | float 0..1, `1.0` | `audio.gd` | `static var music_volume := 1.0`, `func set_music_volume(v: float, save := true) -> void`, `static func save_music_volume() -> void`; read once per run like `sfx_volume` |

- **Test flags** (`difficulty.gd` reads them; for this run only, never saved):
  - `--left-handed` / `--right-handed`;
  - `--music-volume X` (0..1).
- **Music volume is applied in `_update_music_volume()`** as one more gain on top of today's math (ducking and the
  crossfade unchanged): `MUSIC_DB + linear_to_db(g * pow(music_volume, SFX_VOLUME_CURVE))`, floored at
  `MUSIC_SILENT_DB`.
  - `music_volume` 0 = silent, but it does not flip `MenuScript.music_on`. MUSIC ON/OFF stays as it is.
  - The twist ambience follows the SOUND volume, as today.

### Touch layout (P7-03 `touch_controls.gd`)
- `var left_handed := false`, set in `_ready()` from `Difficulty.is_left_handed()`.
- `func mirror_x(p: Vector2) -> Vector2`: `Vector2(size.x - p.x, p.y)` when left-handed, else `p`.
- `func on_joy_side(pos: Vector2) -> bool`: the left half when right-handed, the right half when left-handed.
- `a_center()` and `b_center()` return the mirrored points. Their callers (`main.gd`, `pause.gd`) keep calling
  them and never place a control in raw coordinates.
- `JOY_RADIUS`, `TURBO_PULL`, the hit radii and the drawing are unchanged; only the positions are mirrored.
- The pause button stays top-right in both layouts (Q3 may change this), and so does the HUD top bar.

### Screens
- `flow.gd` `SCREENS` gains `"howto": "res://scripts/howto.gd"` (P7-04).
  - Args: `{"back": "<screen>"}`, default `"title"`.
  - `howto.gd` (P7-H3) implements `auto_step()`: next page, `false` after the last page.
- **Title** (P7-04):
  - a HOW TO PLAY button: a third button in the SETTINGS / CREW & CREDITS row, or a row of its own if three don't
    fit at `SIDE_BTN`;
  - the version, small, in the bottom-right corner: `"v" + version`;
  - CREW & CREDITS shows the version at the top of its list and, at the end, the Godot notice
    (`Engine.get_license_text()`).
- **Version, single source**: `project.godot` `application/config/version` (P7-08, `"1.0.0"` unless Q1 says
  otherwise). Read it with `var v: String = str(ProjectSettings.get_setting("application/config/version", ""))`.
  An empty string means no label (true until P7-08 lands).

### How to Play pages (P7-H1 capture, P7-H2 pictures, P7-H3 screen)
Page ids, in order. Each page is one picture plus a title and 2-4 short lines. The lines are written in `howto.gd`
`PAGES`, so the owner can edit them on the tablet; they are not baked into the image.

| # | id | Picture shows (captured from the game) | Points the lines make |
|---|---|---|---|
| 1 | `controls` | a game with the joystick out, SHOOT (A) and PASS (B) visible; callouts on the three | joystick moves, A shoots, B passes; left-handed layout in Settings |
| 2 | `turbo` | a player sprinting with the thumb past the ring, stamina bar draining | pull past the ring to sprint; stamina refills when you ease off |
| 3 | `shoot` | the shot meter during a jump shot, the arc marked | hold and release in the green; 1 inside the arc, 2 beyond; a short tap is a pump fake |
| 4 | `dunks` | a dunk at the rim (turbo dunk if possible), plus an alley-oop lob | SHOOT near the rim dunks or lays up; pass to a cutter = alley-oop |
| 5 | `moves` | a crossover: the flick and the beaten defender | flick the stick while dribbling to cross over |
| 6 | `call` | the CALL bubble, B lit as CALL | press CALL for the ball; you take over whoever you pass to |
| 7 | `defense` | the STEAL button glowing next to a handler, then BLOCK at a shooter | STEAL when it glows; BLOCK when your man shoots near you; bad timing fouls |
| 8 | `fire` | a player on fire, the flaming ball trail | 3 makes in a row = on fire: bigger green zone, no stamina drain |
| 9 | `trip` | the trip map (and lineup or points screen as an inset) | 3 games per city, win to move on, stat points, recruit one player, pick 3 starters |

- **Raw captures** (P7-H1): `--howto-shots DIR` (xvfb) writes `DIR/howto_<id>.png` at 1280x720, plus an optional
  `howto_<id>_b.png` inset (dunks, defense, trip). The capture for `trip` may come from `--trip-test --screens`
  instead; P7-H1 says which.
- **Pictures** (P7-H2): `python3 tools/art/make_howto.py <raw dir>` writes `assets/howto/<id>.png`.
  - Each is 960 x 540, cropped and scaled from the raw capture, with the overlays drawn by the script: arrows, a
    thumb, button callouts and the ring for turbo.
  - Overlays are in the style sample v1 look: bold dark outline, flat bands, the game's palette.
  - No text in the image beyond what the game itself shows.
  - The raw captures are committed in `tools/art/howto_raw/`, so the generator reruns.
- **Missing picture**: `howto.gd` draws a framed placeholder with the page title, so P7-H3 can merge before P7-H2.

### Release files and build scripts
- Web (P7-06): `tools/build_web.sh --zip` builds as today, then writes
  `build/release/road-trip-hoops-<version>-web.zip`.
  - `index.html`, `index.pck`, `index.wasm`, `index.js` and the icons sit at the ZIP's root, with no folder.
  - `--publish` is unchanged; `--zip --publish` does both.
  - `<version>` is read from `project.godot`.
- Android (P7-07):
  - `tools/build_android.sh` writes `build/release/road-trip-hoops-<version>-debug.apk`.
  - `tools/build_android.sh --release` writes `build/release/road-trip-hoops-<version>.apk`. It needs Godot's own
    environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` (the alias)
    and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`, and fails with a clear message if any is missing.
  - Preset name `"Android"` (`platform="Android"`), `export_path="build/release/road-trip-hoops.apk"`.
- Preset fields (P7-07, icons and version in P7-08):
  - `package/unique_name` = Q1 (placeholder `io.github.kirmalo.roadtriphoops`), `package/name` = Q1
    (`"Road Trip Hoops"`);
  - `version/code=1`; `version/name` empty (= `application/config/version`);
  - `screen/immersive_mode=true`;
  - `gradle_build/use_gradle_build=false`;
  - architectures `arm64-v8a` and `armeabi-v7a` on, `x86`/`x86_64` off;
  - every permission off (no INTERNET);
  - orientation from `project.godot` (landscape, as today).
- Icons (P7-05):
  - `assets/icon/icon.png` (256, the project icon and web favicon);
  - `assets/icon/icon_192.png`, `icon_fg_432.png`, `icon_bg_432.png` (Android main and adaptive icon);
  - `icon_512.png` (spare, for itch).
- Store and owner docs (excluded from the export by the `docs/*` filter):
  - `docs/release/cover.png` (630 x 500, P7-05);
  - `docs/release/screenshots/shot_1..5.png` (1280 x 720, P7-S1);
  - `docs/release/itch_page.md`, `docs/release/UPLOAD.md` (P7-S2);
  - `docs/release/ANDROID.md` (P7-07: keystore and APK steps).

## What we found about building APKs here (checked 2026-11-17)
- **Missing:**
  - The Android SDK. `dl.google.com` is blocked by the proxy (403), so Google's cmdline-tools, platforms and system
    images can't be downloaded.
  - `/dev/kvm`, so **no Android emulator can run here**. Installing and launching the APK is checked on the owner's
    tablet (a checklist in `UPLOAD.md`).
- **Present or reachable:**
  - OpenJDK 21 with `keytool` (`JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`);
  - Godot 4.3 on PATH, with only the web templates installed;
  - GitHub releases: the 4.3 export templates `.tpz` holds `android_debug.apk` / `android_release.apk`;
  - Ubuntu 24.04 apt: `apksigner` (31.0.2), `zipalign`, `adb`, `aapt`;
  - `maven.google.com` (200), not needed without Gradle.
- **Likely route (not yet proven, P7-07 proves it first):** Godot's non-Gradle export only needs:
  - an SDK folder with `platform-tools/adb` and `build-tools/<ver>/apksigner`, which a shim folder can provide
    with links to the apt tools;
  - a JDK path;
  - the two Android templates;
  - `rendering/textures/vram_compression/import_etc2_astc=true` (export validation asks for it; our textures are
    lossless PNG, so nothing reimports differently).

  Godot makes the debug keystore with `keytool`. The APK is checked here with `aapt dump badging` (package, version,
  permissions, SDK levels, label, icon) and `apksigner verify --print-certs`.
- **If the route fails:** P7-07 documents exactly what's missing. The fallback is the owner's own Godot Android editor
  (4.3 can export a non-Gradle APK on the device), with step-by-step instructions in `docs/release/ANDROID.md`.

## Risks and how this plan handles them
- **The release key.**
  - The owner must keep the same key for every future update. A lost key means a new app that can't update the
    old one.
  - The key must never pass through git.
  - Q5 decides where the key is made. `ANDROID.md` covers making it, backing it up, and exporting with it (on the
    tablet, or here through environment variables).
- **APK size.** About 34 MB of game data plus the Godot engine for two ARM ABIs: an estimated 60-80 MB. That's fine
  for itch (1 GB per file). P7-07 reports the real size. Dropping `armeabi-v7a` saves about 15-20 MB but loses old
  32-bit tablets; we keep both unless the owner says otherwise.
- **Android back gesture quits the app.**
  - Godot's `application/config/quit_on_go_back` is true by default. Today `pause.gd` opens the pause panel on it,
    but the app still quits.
  - P7-08 sets it false. P7-10 makes back act like BACK on the screens and like the pause button in a game. On
    the title, back still leaves the app (the platform's normal behaviour).
- **itch.io can't be reached from here** (403), so the embed is tested in a local harness: an `<iframe>` page
  (1280x720 with `allowfullscreen`, plus a phone-landscape viewport) served from the unzipped release ZIP (P7-40).
  The owner does the real upload.
- **Web saves.**
  - Saves live in the browser per site. A trip played on GitHub Pages doesn't carry over to itch.io, and the APK
    has its own save. `UPLOAD.md` and the itch page say so.
  - Godot keys `user://` by the project name, so the save survives re-uploads on itch. Keep `config/name`.
- **Left-handed layout breaks something mirrored by hand.** The scripted thumb (`main.gd` `HT_FINGER_POS`) and the
  pause test's stray touch (`pause.gd`) use raw left-half points. P7-03 routes both through `mirror_x()`, and
  `--humantest --left-handed` must pass like the default.
- **How to Play pictures go stale** if the HUD changes. They are regenerated by two commands (capture, compose), and
  CLAUDE.md lists them.
- **Size.** Pictures are capped at about 2.5 MB. The icon and cover are small. P7-40 reports `index.pck` against
  34.2 MB.
- **Godot license notice.** The MIT notice must ship. It is shown in CREW & CREDITS with `Engine.get_license_text()`
  (the list scrolls), and `CREDITS.md` already has the engine row.

## Owner answers
From `docs/VISION.md` "Phase 7 design":
- Release on itch.io: the web version plus a downloadable Android APK on the same page; no Google Play for now.
- Price: pay what you want (free, with an optional tip).
- How to Play: picture pages from the title (controls, flicks, steals, blocks, dunks); no playable tutorial.
- The owner uploads. The team builds the release files (the web ZIP, and the APK signed with a key the owner
  creates), writes the step-by-step upload instructions, the store page text and the screenshots.

Q1-Q5 answered (VISION "Phase 7 plan answers"): all the recommended (a) answers. Package id
io.github.kirmalo.roadtriphoops, app name "Road Trip Hoops", 1.0.0 / code 1, the proposed tagline; LEFT-HANDED and
MUSIC in Settings only; no source link on itch, GitHub Pages stays the test build; the owner makes the release key.
Coordinator: Android back = pause/BACK, quits only on the title; APK keeps 32- and 64-bit ARM.

## Todo
- **P7-B1** | Web: the second tap on QUIT? / RESTART? sometimes ignored (details under "Bugs from P7-40" below).
  Check on the owner's tablet first (`docs/qa/phase7.md` section 6, step 6).

## Doing
- **P7-42** | Coordinator: release files to the owner (web ZIP, debug APK, `UPLOAD.md`, page text, cover,
  screenshots), the web publish, and the owner check-in. The summary `docs/phase7-summary.md` is written.

## Review

## Done
All merged on `ccr-f5c087b2-3ojk5f` by `a201ef1`. The task text below is as planned; what changed is in the notes.
- P7-01 left-handed setting and test flags (`4a2cf42`); P7-02 music volume (`3d4459d`).
- P7-03 left-handed touch layout (`bb83784`); P7-04 Settings LEFT-HANDED and MUSIC, HOW TO PLAY button, version,
  credits (`fbde3a8`).
- P7-05 icons and cover (`c7557f9`), then the ball as a sunset, the owner's pick (`0ffcc9a`, preview
  `docs/art/icon_cover_preview_v2.png`).
- P7-06 `build_web.sh --zip` (`4d66cde`); P7-07 Android preset, `build_android.sh`, `ANDROID.md` (`6783553`).
- P7-08 release metadata: version 1.0.0, icon, `quit_on_go_back=false`, Android icons (`b944698`).
- P7-10 Android back gesture (`d8faa67`; fix `1b326d1`: Escape on the menus works again, `--backtest` documented).
- P7-H1 capture driver (`2ddecaf`); P7-H2 pictures (`b412f97`); P7-H3 How to Play screen (`73e42ba`; fix `7834d98`:
  BACK came back after the tap guard).
- P7-S1 store screenshots (`ff95bf5`, contact sheet `docs/art/store_screens_preview.png`); P7-S2 itch page text and
  `UPLOAD.md` (`08eefde`).
- P7-40 final release QA (`a201ef1`, `docs/qa/phase7.md`): release-ready, bug P7-B1 filed.
- P7-41 README, CLAUDE.md and CREDITS.md (`b72349b`; `6ef4a44` adds the How to Play pictures to the credits row).

**Done notes:**
- Added during the phase: the title's road sign moved below the three-button row (`430ce34`).
- P7-40: the 10 Quick Game autoplay games are longer than Phase 6's (12.96 min, 97 shots, 5.0 fouls on average),
  all means inside CLAUDE.md's ranges. No sim script changed in Phase 7; QA traces it to the owner's tuning
  `073c3a5` (RED plays its crew's style). Open for the lead: take them as the new reference, or rerun 40+ games.
- P7-42: no release APK yet (the owner's key is "later"); the debug APK is for testing only.

### Wave 1 (start now; six tasks, no shared files)
- **P7-01** | Left-handed setting:
  - `is_left_handed()` / `set_left_handed()` as in the contract, saved as `left_handed` in `settings.cfg`;
  - test runs don't save;
  - flags `--left-handed` / `--right-handed` (this run only) and `--music-volume X` (stored for P7-02 to read:
    `static var music_volume_flag := -1.0`).

  | gameplay A | `scripts/difficulty.gd` | parses in 4.3; a fresh `settings.cfg` reads false; set, reload, reads true;
  the flag wins for the run without writing the file | - | none
- **P7-02** | Music volume:
  - `music_volume` with load, save and set, as in the contract;
  - applied in `_update_music_volume()`;
  - `Difficulty.music_volume_flag` wins when >= 0.

  | gameplay B | `scripts/audio.gd` | 1.0 = today's levels exactly (print the dB in a one-off check); 0 = silent;
  ducking and the crossfade unchanged; 3 autoplay + humantest clean | - | none
- **P7-05** | Icon and cover generator `tools/art/make_icon.py`, outputs:
  - `assets/icon/*` as in the contract;
  - `docs/release/cover.png` (630 x 500).

  The pictures are built from the game's own art: the underdogs' cards (`assets/players2/cards/`), the ball, a court
  floor, the van from `assets/map/van.png`, and the name "ROAD TRIP HOOPS" in the title's gold. All in the style
  sample v1 look. The adaptive foreground keeps the motif inside the 264 px safe circle. A `CREDITS.md` row (original,
  generated).

  | art-audio | `tools/art/make_icon.py` (new), `assets/icon/*` (new), `docs/release/cover.png` (new), `CREDITS.md` |
  reruns byte-identical; readable at 48 px; sizes exact; contact image for the owner in the PR | - | none (the
  owner judges the look at the check-in)
- **P7-06** | `tools/build_web.sh --zip`: the release ZIP as in the contract (flat root, version from
  `project.godot`). Also check the itch.io embed needs: `index.html` at the root, relative paths only, nothing over
  itch's limits (1000 files, 200 MB per file). Print the ZIP size.

  | gameplay C | `tools/build_web.sh` | the ZIP unzips to a flat folder that runs from a local server in Chromium;
  `--publish` alone behaves as today | - | none
- **P7-07** | Android build:
  - **Step 1, the spike.** Set up the toolchain here: the apt `apksigner zipalign adb aapt`, an SDK shim folder,
    `android_debug.apk` and `android_release.apk` from the 4.3 templates `.tpz` (extracted like the web templates
    in `docs/TEAM.md`), and the editor settings for the SDK and JDK paths. Export a debug APK of the current build.
    If it can't be done, stop after step 1, write down what is missing, and do step 3 only.
  - **Step 2, the preset and script.**
    - Add the `"Android"` preset with the contract's fields; the icons come in P7-08.
    - `tools/build_android.sh`, as in the contract. It sets up nothing secret, never echoes passwords, and keeps
      the debug keystore outside the repo.
    - `import_etc2_astc=true` in `project.godot` if the export asks for it.
    - Add `*.keystore` and `*.jks` to `.gitignore`.
  - **Step 3, `docs/release/ANDROID.md`.**
    - The exact steps to create the release keystore (the `keytool` command with placeholders; alias, validity
      10000 days) and to back it up twice.
    - Exporting the release APK in the Godot Android editor on the tablet: Editor Settings > Export > Android,
      Project > Export > Android > Release keystore fields.
    - Exporting it here with the environment variables.
    - What never to commit.
    - Installing the APK on the tablet ("install unknown apps").
  - Add the toolchain setup to "Tools in the cloud environment" in `docs/TEAM.md`.

  | gameplay B (after P7-02) | `export_presets.cfg`, `tools/build_android.sh` (new), `project.godot` (only
  `import_etc2_astc`), `.gitignore`, `docs/release/ANDROID.md` (new), `docs/TEAM.md` | `aapt dump badging` shows the
  package, version 1 / name, label, landscape, no permissions; `apksigner verify` passes on the debug APK; the APK
  size is reported; or the spike's findings are written down and ANDROID.md covers the tablet route | - | Q1 (the
  package id; placeholder until answered), Q5 (which route `ANDROID.md` leads with)
- **P7-H1** | How to Play capture driver `scripts/howto_shots.gd` (new), loaded by `main.gd` under
  `--howto-shots DIR` (like `--anim-test`):
  - It plays scripted `--humantest`-style situations, or watches a game, and saves `howto_<id>.png` at the moments
    in the page table. It polls the game state (the joystick shown, `turbo_pull()`, `rim_kind`, `a_glow`,
    `a_block`, the call bubble, on fire); it never changes the sim's rules.
  - Uses fixed seeds, so a rerun gives the same pictures.
  - Quits when every page has a capture or after a time limit, and prints `HOWTO SHOTS <n>/9` plus the missing ids.
  - If `trip` comes from `--trip-test --screens`, say so.

  | gameplay A (after P7-01) | `scripts/howto_shots.gd` (new), `scripts/main.gd` (the flag hook only) | under xvfb
  all 9 captures (or 8 + the trip screen) exist and show the moment named; default runs unchanged | - | none

### Wave 2 (after the wave-1 task each one names)
- **P7-03** | Left-handed layout, as in the touch contract:
  - `touch_controls.gd`: the joystick zone on the right half and A/B mirrored to the bottom left.
  - `main.gd`: the humantest thumb (`HT_FINGER_POS`) through `controls.mirror_x()`.
  - `pause.gd`: the stray-touch test spot through `mirror_x()`.

  Check that nothing else on screen collides with the mirrored buttons: popups, the twist banner, the message line
  (all centred today) and the pause button (top-right).

  | gameplay A | `scripts/touch_controls.gd`, `scripts/main.gd`, `scripts/pause.gd` | `--humantest` and
  `--humantest --left-handed` both pass; `--shots --humantest --left-handed` screenshot shows the mirrored layout;
  the default is byte-for-byte today's layout | P7-01, P7-H1 (main.gd) | Q3 (if the pause button moves)
- **P7-04** | Title and Settings:
  - Settings gets a LEFT-HANDED ON/OFF row (`Difficulty.set_left_handed`) and a MUSIC volume slider (`UI.slider_row`,
    saved after `SFX_SAVE_DELAY` like SOUND, previews on the menu music). MUSIC ON/OFF, FULL SCREEN, SOUND and LEVEL
    stay. It must fit 1280x720 and the narrowest 16:9 or 4:3 view; scroll or two columns if needed.
  - The title gets the HOW TO PLAY button (`Flow.go("howto", {"back": "title"})`) and the version label.
  - CREW & CREDITS:
    - the version at the top of the list;
    - `CREDITS_LIST` checked against `CREDITS.md`, so that every CC-BY item shows title, author, license and
      source exactly as the license asks (`crowd`, `crowd_loud`, `newyork`, `memphis`, `seattle` with "Music by
      Christovix Games");
    - the Godot license text at the end.
  - `flow.gd`: the `"howto"` entry.
  - `--titletest`: taps LEFT-HANDED (and back), moves the MUSIC slider (and back), opens HOW TO PLAY, pages once
    and taps BACK. Every setting is put back, and the test never writes the owner's file.

  | gameplay C | `scripts/title.gd`, `scripts/flow.gd` | `--titletest` passes; screenshots of settings, title
  and credits; the left-handed choice reaches the next game | P7-01, P7-02 | Q3 (placement)
- **P7-H2** | `tools/art/make_howto.py`: the 9 pictures from the raw captures, as in the contract. The raw
  captures go in `tools/art/howto_raw/`, plus a `CREDITS.md` row.

  | art-audio | `tools/art/make_howto.py` (new), `tools/art/howto_raw/*` (new), `assets/howto/*` (new),
  `CREDITS.md` | reruns byte-identical; 9 pictures at 960 x 540, at most about 2.5 MB together; a contact sheet for
  the owner | P7-H1 (P7-05 for `CREDITS.md`) | none
- **P7-H3** | How to Play screen `scripts/howto.gd` (new), screen `"howto"`:
  - `PAGES` const data (the table above; the lines written plainly, at most 4 per page, big font);
  - the picture centred, title above, lines below, page dots;
  - big < > arrow buttons and a horizontal swipe (a drag of at least about 80 px; a tap on the picture does
    nothing);
  - BACK top-left goes to `args.back`; Escape = BACK and Left/Right = page on desktop;
  - the `PANEL_ARM` tap guard like title.gd;
  - a missing picture draws a placeholder;
  - `auto_step()`.

  | gameplay B | `scripts/howto.gd` (new) | under `--titletest` (after P7-04) every page shows; screenshots of
  pages 1, 4, 9; swipe works in Chromium with touch emulation | - (merges with P7-04) | none
- **P7-08** | Release metadata:
  - `project.godot`: `application/config/version` (Q1, `"1.0.0"`), `application/config/icon` =
    `res://assets/icon/icon.png`, `application/config/quit_on_go_back=false`.
  - Android preset: the three launcher icon fields.
  - Web preset: the PWA icon fields stay empty (the favicon comes from the project icon).

  | gameplay C (after P7-04) | `project.godot`, `export_presets.cfg` | the project opens in 4.3 headless without
  warnings about the icon; the web build's favicon is the new icon; the debug APK shows the icon and version name
  in `aapt dump badging` | P7-05, P7-07 | Q1

### Wave 3
- **P7-10** | Android back gesture with `quit_on_go_back` false (P7-08):
  - in a game, back opens or closes the pause panel (`pause.gd` already opens it on the request);
  - on any other screen it does what that screen's BACK / Escape does;
  - on the title it quits the app.

  One handler in `main.gd` that sends the screen an Escape key press. No per-screen edits unless a screen lacks an
  Escape BACK; if one does, stop and tell the coordinator.

  | gameplay A | `scripts/main.gd` | a desktop test sends `NOTIFICATION_WM_GO_BACK_REQUEST` on the title, settings,
  howto, map and in a game, and logs the result; humantest clean | P7-03, P7-08 | none
- **P7-S1** | Store screenshots, 5 images at 1280 x 720, captured from the game (xvfb):
  - a dunk on a city court;
  - a big moment with a twist (rain or wind);
  - the trip map;
  - a story scene (portraits);
  - the New York cage or the lineup screen.

  Use the existing modes (`--shots --city <id> --cgame N`, `--trip-test --screens`, `--ballshots`) or P7-H1's
  driver. No HUD debug text, the right-handed layout, and a sharp frame (not mid-fade). A contact sheet for the
  owner.

  | qa | `docs/release/screenshots/*` (new) | 5 PNGs, exact size, each a different part of the game | P7-03, P7-04,
  P7-H3 | none
- **P7-S2** | Store page text and the owner's upload steps.
  - `docs/release/itch_page.md`:
    - the title and tagline (Q2);
    - a short description (under 140 characters for itch's "short description");
    - a long description: the pitch, the trip, the cities and twists, the controls, the features;
    - "Controls: touch (joystick + 2 buttons); keyboard WASD / J / K on desktop";
    - saves stay in your browser or on your device;
    - a credits pointer ("Music and sound by ..., full credits in the game's CREW & CREDITS screen") listing every
      CC-BY author;
    - the genre (Sports) and tags (up to 10 proposed);
    - the source link only if Q4 says so.
  - `docs/release/UPLOAD.md`, one numbered list the owner can follow on the tablet. It can also be done on a computer.
    1. Create the itch project: title, URL, the kind "HTML".
    2. Pricing: "No payments" vs "Donate"; pick pay what you want with a minimum of $0 and a suggested tip.
    3. Upload the web ZIP with "This file will be played in the browser".
    4. Embed options: viewport 1280 x 720, "Mobile friendly" with landscape orientation, the "Fullscreen button"
       on, "Automatically start on page load" off, SharedArrayBuffer off.
    5. Upload the APK as a download, marked Android.
    6. The cover and screenshots; the genre, tags, release status and community settings.
    7. Save as a draft, test on the tablet (web and APK install checklist), then make it public.
    8. How to upload an update later: the same file slot, the version code bumped, the same key.

  | art-audio | `docs/release/itch_page.md` (new), `docs/release/UPLOAD.md` (new) | the coordinator can follow
  UPLOAD.md without guessing; every field on itch's edit page is covered | P7-06, P7-07 | Q2, Q4

### Wave 4
- **P7-40** | Final release QA, report `docs/qa/phase7.md`.
  - **Headless.**
    - The full `--trip-test` (full length and `--target 3`), a forced loss, and stop/resume.
    - 3 Quick Game `--autoplay` against the Phase 6 numbers; `--humantest` with and without `--left-handed`;
      `--titletest`; `--twisttest`; `--anim-test`.
  - **Web, from the release ZIP**, served locally, in Chromium with Playwright touch emulation, in the itch-style
    iframe harness (1280x720 and a phone-landscape viewport).
    - A full trip. The web runtime runs the trip test: `GODOT_CONFIG.args` patched to
      `--trip-test --target 3` in a copy of `index.html`.
    - A touch walk: title, How to Play (swipe and arrows), Settings (LEFT-HANDED on, then a game played by touch
      with the mirrored controls; the MUSIC slider), a new trip's first game by touch, pause, quit, CONTINUE.
    - The save survives a reload.
    - FULL SCREEN works inside the iframe.
    - The version is visible on the title and in the credits.
    - `index.pck` and ZIP sizes.
  - **APK.**
    - `aapt dump badging`, `apksigner verify`, the size.
    - Install and launch can't be tested here (no emulator: no KVM, no Android system images), so give the owner
      a tablet checklist in the report: installs, opens landscape, sound on the first tap, back gesture, the save
      survives closing the app.

  | qa | `docs/qa/phase7.md` (new) | report written; bugs filed here as P7-Bn | all above | none
- **P7-41** | Docs for a public release.
  - `README.txt`:
    - the player part first (what the game is, how to play, the controls, Settings and LEFT-HANDED, How to Play,
      where saves live);
    - the build part after (web ZIP, APK, `ANDROID.md`).
  - `CLAUDE.md`: Layout (`howto.gd`, `howto_shots.gd`, `assets/icon/`, `assets/howto/`, `docs/release/`,
    `make_icon.py`, `make_howto.py`, `build_android.sh`) and Testing (`--left-handed`, `--music-volume`,
    `--howto-shots`, `build_web.sh --zip`, `build_android.sh`). The coordinator approves.
  - `CREDITS.md`: every file under `assets/` covered, every license CC0, CC-BY or MIT (the engine), and the CC-BY
    attribution text matching the in-game list.

  | gameplay C | `README.txt`, `CLAUDE.md`, `CREDITS.md`, `docs/TEAM.md` (check only) | the owner can follow it;
  the coordinator approves the CLAUDE.md change | P7-40 | none
- **P7-42** | Coordinator.
  - Build the release files from the merged commit (`build_web.sh --zip --publish`, `build_android.sh`, and the
    release APK if the owner's key route allows it here).
  - Hand them to the owner the way Q4 allows (a GitHub release on the repo is the default proposal).
  - Then `lead-producer` writes `docs/phase7-summary.md`.

  | coordinator | (no repo files besides the summary) | the owner has the ZIP, the APK (or the steps to export
  it), `UPLOAD.md`, the page text and the images | P7-40, P7-41 | Q4, Q5

### Bugs from P7-40 (details in `docs/qa/phase7.md`)
- **P7-B1** | Web: the confirming second tap on the pause panel's QUIT? / RESTART? is sometimes ignored (intermittent).
  - Build: release ZIP of `3cf6c7d`, served locally, Playwright Chromium 1280x720 (SwiftShader), touch through CDP
    `Input.dispatchTouchEvent`, also seen with `page.mouse.click`.
  - Steps: Quick Game, NORMAL; after ~4 s tap the pause button (top-right); ~1 s later tap QUIT (it turns gold,
    "QUIT?"); 0.4-1.5 s later tap QUIT again.
  - Expected: back to the title (Quick Game) or the map (trip).
  - Actual: in 7 of 20 tries the second tap did nothing; "QUIT?" stayed until CONFIRM_TIME (2.5 s) ran out and it went
    back to "QUIT". RESTART behaved the same once. A third tap after that worked; tapping another button (MUSIC) in
    between also worked. A loop of 8 tries without a screenshot between the taps passed 8/8; 3/4 passed with a
    screenshot between them; the phone viewport (Pixel 7 landscape) passed 1/1; native xvfb (touch and mouse through
    `Input.parse_input_event`) passed 2/2. So it may be a harness effect (SwiftShader stalls during screenshots), but
    it was not proven either way.
  - Impact: low (tap again and it works; nothing is lost). Check on the tablet (checklist in `docs/qa/phase7.md`).
  | gameplay | `scripts/pause.gd` (investigate only first) | the owner's tablet and a real Chromium both quit on the
  second tap every time, or the cause is found and fixed | - | none

## Parallel plan (never two tasks on the same file in one wave)
| Wave | Tasks (owner role) | Files touched | Notes |
|---|---|---|---|
| 1 | P7-01 (gameplay A), P7-02 (gameplay B), P7-05 (art-audio), P7-06 (gameplay C), P7-07 (gameplay B after P7-02), P7-H1 (gameplay A after P7-01) | difficulty.gd / audio.gd / make_icon.py, assets/icon, cover, CREDITS.md / build_web.sh / export_presets.cfg, build_android.sh, project.godot, .gitignore, ANDROID.md, TEAM.md / howto_shots.gd, main.gd | P7-07 starts with its spike so the APK answer comes early |
| 2 | P7-03 (gameplay A), P7-04 (gameplay C), P7-H2 (art-audio), P7-H3 (gameplay B), P7-08 (gameplay C after P7-04) | touch_controls.gd, main.gd, pause.gd / title.gd, flow.gd / make_howto.py, howto_raw, assets/howto, CREDITS.md / howto.gd / project.godot, export_presets.cfg | P7-H3 and P7-04 merge together (the button and the screen) |
| 3 | P7-10 (gameplay A), P7-S1 (qa), P7-S2 (art-audio) | main.gd / docs/release/screenshots / itch_page.md, UPLOAD.md | |
| 4 | P7-40 (qa), then P7-41 (gameplay C), then P7-42 (coordinator) | docs/qa/phase7.md / README.txt, CLAUDE.md, CREDITS.md / - | |

The file most at risk is `main.gd`: P7-H1 (wave 1), P7-03 (wave 2) and P7-10 (wave 3) each change a few lines, in
order. The same goes for `project.godot` and `export_presets.cfg`: P7-07 (wave 1), then P7-08 (wave 2). `CREDITS.md`
gets one row in P7-05 (wave 1) and one in P7-H2 (wave 2), and P7-41 checks it (wave 4).

## Open questions for the owner (Q1-Q5 answered, see "Owner answers")
Answer with the letter. (a) is the recommendation each time. Answers go into `docs/VISION.md` and "Owner answers"
above.

- **Q1 App identity (Android and the version label).**
  - The package id can never change once people install the APK.
  - (a) Package id `io.github.kirmalo.roadtriphoops`, app name "Road Trip Hoops", version 1.0.0 (version code 1),
    the version shown small on the title (bottom right) and in CREW & CREDITS.
  - (b) The same, but a package id of your own (e.g. `com.<yourname>.roadtriphoops`) or another version (e.g.
    0.9.0).
- **Q2 Store page title and tagline.**
  - (a) Title "Road Trip Hoops", tagline "Drive your underdog crew across America and win the 3v3 streetball
    tournament in New York.", genre Sports. Proposed tags: basketball, sports, arcade, pixel-art, streetball,
    touch-friendly, android, retro, singleplayer, 2d.
  - (b) The same title with a tagline you write.
  - (c) A different title for the store.
- **Q3 Where the new settings go.**
  - (a) Settings gets LEFT-HANDED ON/OFF and a MUSIC volume slider; MUSIC ON/OFF stays; the pause panel stays as
    it is (it already has MUSIC ON/OFF, FULL SCREEN and SOUND); the pause button stays top-right in both layouts.
  - (b) As (a), and the pause panel also gets LEFT-HANDED and the MUSIC slider.
  - (c) As (a), and the very first launch asks "Which hand for the joystick?" once.
- **Q4 Source code and the GitHub page.**
  - (a) The itch page doesn't link the GitHub source. The GitHub Pages build stays as your test build. We hand you
    the release files as a GitHub release on the repo.
  - (b) The itch page links the source. You also pick a license for the code; today there is none, so it is "all
    rights reserved".
  - (c) As (a), but take GitHub Pages down at release so itch.io is the only place to play.
- **Q5 The release signing key** (it signs the APK; keep it forever, or updates won't install over the old app).
  - (a) You make it on a computer with Java's `keytool` (we give the exact command). You keep two backups, and
    export the release APK yourself in the Godot Android editor on the tablet (we give the steps). Our script can
    also build it here if you pass the key path and passwords as environment variables.
  - (b) You have no computer: the team makes the key here once, and you download it once from a private place and
    keep the backups. Less safe: the key passed through the cloud.
  - (c) For 1.0, ship an APK signed with a debug key, and make a real key later. Not recommended: switching keys
    means uninstalling the old version (and losing its save).
