# Road Trip Hoops: Agent Team

The game is built by a small team of Claude Code agents. Agent definitions are in `.claude/agents/`.

| Role | Agent | Does |
|---|---|---|
| Coordinator | the main Claude Code session | Talks to the owner, starts the other agents, merges their work, pushes |
| Lead / producer | `lead-producer` | Splits a phase into tasks on `docs/BOARD.md`, reviews changes, writes the phase summary |
| Gameplay programmer (1-2) | `gameplay-programmer` | Implements gameplay tasks in `scripts/` |
| Art + audio integrator | `art-audio-integrator` | Finds, license-checks and wires in sprites, music and sound; keeps `CREDITS.md` |
| QA / balance tester | `qa-balance-tester` | Runs headless games and screenshots, checks stats, files bugs, tunes constants |

Subagents can't start other subagents, so the main session coordinates and the lead plans and reviews.

## Phase loop
1. **Plan.** The coordinator asks `lead-producer` to plan the next phase from `docs/VISION.md`. Tasks go on
   `docs/BOARD.md`, each with the files it may touch.
2. **Build.** The coordinator starts a `gameplay-programmer` or `art-audio-integrator` per task, each in its own git
   worktree. Tasks that run at the same time never touch the same file.
3. **Test.** `qa-balance-tester` runs the test pass on each finished task and writes `docs/qa/...`.
4. **Review.** `lead-producer` reviews the diff and the QA report: APPROVE or CHANGES.
5. **Merge.** The coordinator merges approved work onto the development branch and re-runs a quick QA pass on the
   combined result.
6. **Check-in.** At the end of the phase the coordinator pushes, publishes the web build
   (`tools/build_web.sh --publish`), and the lead's summary goes to the owner with multiple-choice questions. The
   owner plays at https://kirmalo.github.io/road-trip-hoops/ (or from a ZIP in the Godot editor) and answers. Answers go into
   `docs/VISION.md` before the next phase starts.

## Rules for every agent
- `docs/VISION.md` decides design. Open design questions go to the owner, never guessed.
- Every pushed commit must open and run in the Godot Android editor (Godot 4.3+), because the owner plays straight
  from a ZIP of the repo.
- Only commit to the branch the coordinator names. Only the coordinator pushes.

## Tools in the cloud environment
- **Godot:** not preinstalled. Download the Linux editor from GitHub releases (reachable), for example:
  ```
  mkdir -p ~/godot && cd ~/godot
  curl -sSLO https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
  unzip -o Godot_v4.3-stable_linux.x86_64.zip && ln -sf ~/godot/Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot
  ```
- **Web export templates** (needed for `tools/build_web.sh`): only the web ones are needed, but GitHub serves the
  1 GB template archive without partial downloads, so download it once, extract two files, delete it:
  ```
  mkdir -p ~/.local/share/godot/export_templates/4.3.stable && cd /tmp
  curl -sSLo tpl.tpz https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
  unzip -oj tpl.tpz templates/web_nothreads_release.zip templates/version.txt -d ~/.local/share/godot/export_templates/4.3.stable/
  rm tpl.tpz
  ```
- **Android APK** (needed for `tools/build_android.sh`, proven in P7-07): Godot's non-Gradle export, no Google SDK
  download (`dl.google.com` is blocked) and no emulator (no `/dev/kvm`; the APK is installed on the owner's tablet).
  1. The Android templates, next to the web ones (one more pass over the same 1 GB archive; nothing else there changes):
     ```
     cd /tmp && curl -sSLo tpl.tpz https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
     unzip -oj tpl.tpz templates/android_debug.apk templates/android_release.apk -d ~/.local/share/godot/export_templates/4.3.stable/
     rm tpl.tpz
     ```
  2. The SDK tools from apt: `apt-get install -y apksigner zipalign adb aapt` (they land in `/usr/lib/android-sdk`).
  3. JDK 21 is preinstalled (`/usr/lib/jvm/java-21-openjdk-amd64`, with `keytool`).
  4. `tools/build_android.sh` does the rest: it makes a stand-in SDK folder (`platform-tools` and
     `build-tools/34.0.0` linked to the apt tools), runs Godot with its own config and data folders under
     `~/.cache/road-trip-hoops-android` (the editor settings with the SDK and JDK paths, the debug keystore), exports,
     then checks the APK with `apksigner verify` and `aapt dump badging`. Overrides: `GODOT`, `ANDROID_TEMPLATES`,
     `JAVA_HOME`, `ANDROID_SDK_ROOT` (a real SDK), `ANDROID_BUILD_HOME`.
  - `tools/build_android.sh` writes `build/release/road-trip-hoops-<version>-debug.apk` (about 80 MB, arm64-v8a and
    armeabi-v7a). `--release` needs the owner's key through `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` / `_USER` /
    `_PASSWORD` (see `docs/release/ANDROID.md`); never put a key or password in the repo or a log.
  - Check by hand: `aapt dump badging <apk>` (package, versionCode/versionName, label, `screen.landscape`, no
    `uses-permission` lines) and `apksigner verify --print-certs <apk>`.
- `xvfb-run` and Python 3 with Pillow are installed. Chromium and Playwright are preinstalled for testing the web build.
- **Network:** the `road-trip-hoops` cloud environment allows opengameart.org (works) and kenney.nl (the site refuses
  scripted downloads; don't work around it). itch.io and freesound.org are blocked. For another host, the coordinator
  asks the owner, or the owner downloads the packs and adds them to the repo.
