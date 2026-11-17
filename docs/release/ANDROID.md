# Android APK: the release key and the build

The Android version is one APK file you upload to the itch.io page next to the web version. It holds both the
64-bit (arm64-v8a) and the 32-bit (armeabi-v7a) ARM engine, so it runs on old and new tablets. It is about 75-80 MB.

| Field | Value |
|---|---|
| Package id | `io.github.kirmalo.roadtriphoops` |
| App name | Road Trip Hoops |
| Version | 1.0.0 (version code 1) |
| Screen | landscape, full screen (immersive) |
| Permissions | none (no internet) |

Every update you ever publish must have the **same package id**, a **higher version code** (2, 3, ...) and be signed
with the **same release key**. Android refuses to update an app signed with a different key: a lost key means a new
app, and players have to uninstall the old one (and lose their trip save).

## 1. Make the release key (once, ever)

You need `keytool`, which comes with Java. On a computer (Windows, Mac or Linux) install a free JDK, for example
Eclipse Temurin 21 from adoptium.net, then open a terminal (Windows: Command Prompt) and run, all on one line:

```
keytool -genkeypair -v -keystore road-trip-hoops-release.keystore -alias YOUR_ALIAS -keyalg RSA -keysize 2048 -validity 10000
```

- `YOUR_ALIAS`: a short name for the key, e.g. your initials plus `hoops`. Write it down: Godot asks for it.
- keytool asks for a password (twice), then your name and organization (any values, they show in the certificate).
  If it also asks for a key password, press Enter so it uses the same one: Godot signs with one password.
- 10000 days is about 27 years, so the key outlives the game.

This makes the file `road-trip-hoops-release.keystore` in the folder the terminal is in.

### Back it up twice, right away
Keep the keystore file and its alias and password in **two** places apart from each other, for example:
1. a password manager entry with the keystore file attached and the alias and password in the entry;
2. a USB stick or a cloud drive folder that isn't the game's folder, with the password written somewhere else.

Check both backups once: copy the file back and see it has the same size.

### Never commit it
- Never put the keystore (`*.keystore`, `*.jks`), the alias or the password in the game folder, the repo, a ZIP you
  share, `export_presets.cfg`, an issue or a chat with the team. The repo's `.gitignore` skips `*.keystore` and
  `*.jks`, but keep the file out of the folder anyway.
- In Godot, put the password in the export dialog only on your own tablet or computer. If you ever send the team
  `export_presets.cfg`, clear the three release keystore fields first.

## 2. Export the release APK on the tablet (Godot Android editor)

1. **Export templates.** In the Godot editor: Editor > Manage Export Templates > Download and Install (needs the
   4.3 templates, about 1 GB, once; they install next to anything you already have).
2. **Copy the keystore** onto the tablet, into a folder outside the game folder (e.g. `Documents/keys/`).
3. **Editor Settings > Export > Android** (Editor > Editor Settings, search "android"):
   - the debug keystore fields can stay as Godot filled them (Godot makes its own debug key);
   - Android SDK / Java SDK paths are not needed on the tablet for a plain (non-Gradle) APK.
4. **Project > Export**, pick the **Android** preset (it is already in the project):
   - Keystore > Release: pick your `road-trip-hoops-release.keystore`;
   - Keystore > Release User: your alias;
   - Keystore > Release Password: your password.
   - Leave Gradle Build off, Architectures arm64-v8a and armeabi-v7a on, the others off, and every permission off.
5. **Export Project**, untick **Export With Debug**, save as `road-trip-hoops-1.0.0.apk`.
6. Afterwards, clear the three Release fields again if anyone else might ever get a copy of the project folder.

If the Android preset says Android export isn't available in this editor, update the Godot Android editor to the
newest 4.x release (same project, no other change) or use step 3 on a computer.

## 3. Export it on a computer with the build script (Linux, or the team's cloud setup)

`tools/build_android.sh` exports without Android Studio (see `docs/TEAM.md`, "Android APK", for the setup: Godot 4.3,
the Android export templates, a JDK, and `apksigner`/`adb` from apt or an Android SDK). The release key reaches it only
through environment variables, which the script never prints:

```
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/home/you/keys/road-trip-hoops-release.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=YOUR_ALIAS
read -rs GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD && export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
tools/build_android.sh --release
```

(`read -rs` types the password without showing it or saving it in the shell history.) The script stops with a clear
message if one of the three is missing, if the keystore can't be read, or if it sits inside the repo folder. It writes
`build/release/road-trip-hoops-<version>.apk` and prints the signer, the package line, the label, landscape and the
size. Without `--release` it makes `build/release/road-trip-hoops-<version>-debug.apk`, signed with a throwaway debug
key (fine for testing, never upload it: an APK signed with the debug key can't be updated by the release one).

Check a release APK by hand (from the Android SDK build tools or apt):
```
apksigner verify --print-certs build/release/road-trip-hoops-1.0.0.apk   # "Signer #1 certificate DN:" shows your name
aapt dump badging build/release/road-trip-hoops-1.0.0.apk | head -5     # package id, versionCode='1', versionName='1.0.0'
```

## 4. Install the APK on the tablet

1. Copy the APK to the tablet (download it from itch.io, a cloud drive, or USB).
2. Open it from the Files app (or the browser's downloads).
3. Android asks to allow installs from that app the first time: Settings > "Install unknown apps" > the Files app (or
   the browser) > Allow. Go back and tap Install.
4. A Play Protect prompt may say the app is unknown: tap "Install anyway" (it is unknown because it isn't on Google
   Play).
5. An update installs over the old version and keeps the save, as long as it was signed with the same key and has a
   higher version code. An APK signed with a different key (e.g. a debug APK over the release one) fails with
   "App not installed": uninstall first (this deletes the save).

The APK keeps its own save. A trip played in the browser (GitHub Pages or itch.io) doesn't carry over to it.

## 5. For the next update
1. Raise the version in `project.godot` (`application/config/version`, e.g. 1.0.1) and the **version code** in the
   Android preset (`version/code`, e.g. 2). The code must always go up.
2. Export with the same keystore, alias and password as above.
