#!/usr/bin/env bash
# Build the Android APK (Godot's non-Gradle export, preset "Android" in export_presets.cfg).
#   tools/build_android.sh            debug APK:   build/release/road-trip-hoops-<version>-debug.apk
#   tools/build_android.sh --release  release APK: build/release/road-trip-hoops-<version>.apk
#
# --release signs with the owner's key, given only through Godot's own environment variables (never in a file):
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH      the .keystore / .jks file (keep it outside the repo)
#   GODOT_ANDROID_KEYSTORE_RELEASE_USER      the key alias
#   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD  the password
# This script never prints them. See docs/release/ANDROID.md.
#
# Needs (see docs/TEAM.md, "Android APK"):
#   - Godot 4.3 on PATH as `godot` (or GODOT=/path/to/godot);
#   - android_debug.apk and android_release.apk from the 4.3 export templates, in ANDROID_TEMPLATES
#     (default ~/.local/share/godot/export_templates/4.3.stable, next to the web templates);
#   - a JDK 17+ (JAVA_HOME, default /usr/lib/jvm/java-21-openjdk-amd64);
#   - an Android SDK folder with platform-tools/adb and build-tools/<version>/apksigner (ANDROID_SDK_ROOT). Without
#     ANDROID_SDK_ROOT the script makes a stand-in SDK from the apt packages (apksigner zipalign adb aapt).
#
# Godot runs with its own config and data folders under ANDROID_BUILD_HOME (default ~/.cache/road-trip-hoops-android),
# so the editor settings of other builds (web) are untouched and the debug keystore Godot makes there stays outside
# the repo.
set -euo pipefail
cd "$(dirname "$0")/.."

MODE=debug
case "${1:-}" in
  "") ;;
  --release) MODE=release ;;
  *) echo "usage: tools/build_android.sh [--release]" >&2; exit 2 ;;
esac

GODOT="${GODOT:-godot}"
GODOT_VER="4.3.stable"
ANDROID_TEMPLATES="${ANDROID_TEMPLATES:-$HOME/.local/share/godot/export_templates/$GODOT_VER}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"
BUILD_HOME="${ANDROID_BUILD_HOME:-$HOME/.cache/road-trip-hoops-android}"
APT_SDK="/usr/lib/android-sdk"     # where the apt packages put adb and apksigner
SHIM_BUILD_TOOLS="34.0.0"          # the version folder name Godot looks under (any version number works)

fail() { echo "build_android: $*" >&2; exit 1; }

# ---- the release key: only from the environment, never echoed ----
if [ "$MODE" = release ]; then
  missing=""
  for v in GODOT_ANDROID_KEYSTORE_RELEASE_PATH GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD; do
    if [ -z "${!v:-}" ]; then missing="$missing $v"; fi
  done
  [ -z "$missing" ] || fail "--release needs these environment variables:$missing (see docs/release/ANDROID.md)"
  [ -r "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" ] || fail "can't read the keystore named in GODOT_ANDROID_KEYSTORE_RELEASE_PATH"
  case "$(realpath "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH")" in
    "$(pwd)"/*) fail "the release keystore is inside the repo folder; move it out (it must never be committed)" ;;
  esac
fi

# ---- toolchain checks ----
command -v "$GODOT" >/dev/null || fail "Godot not found (set GODOT or put godot on PATH)"
for f in android_debug.apk android_release.apk; do
  [ -s "$ANDROID_TEMPLATES/$f" ] || fail "missing $ANDROID_TEMPLATES/$f (the 4.3 export templates, see docs/TEAM.md)"
done
[ -x "$JAVA_HOME/bin/keytool" ] || fail "no JDK at JAVA_HOME=$JAVA_HOME (needs bin/keytool)"

mkdir -p "$BUILD_HOME"
if [ -z "${ANDROID_SDK_ROOT:-}" ]; then
  [ -x "$APT_SDK/platform-tools/adb" ] && [ -x "$APT_SDK/build-tools/debian/apksigner" ] ||
    fail "no ANDROID_SDK_ROOT and no apt tools (apt-get install apksigner zipalign adb aapt)"
  ANDROID_SDK_ROOT="$BUILD_HOME/sdk"
  mkdir -p "$ANDROID_SDK_ROOT/build-tools"
  ln -sfn "$APT_SDK/platform-tools" "$ANDROID_SDK_ROOT/platform-tools"
  ln -sfn "$APT_SDK/build-tools/debian" "$ANDROID_SDK_ROOT/build-tools/$SHIM_BUILD_TOOLS"
fi

# ---- Godot's own config and data folders for this build ----
CFG="$BUILD_HOME/config/godot"
DATA="$BUILD_HOME/data/godot"
mkdir -p "$CFG" "$DATA/export_templates/$GODOT_VER" "$DATA/keystores" "$BUILD_HOME/cache"
for f in android_debug.apk android_release.apk version.txt; do
  if [ -e "$ANDROID_TEMPLATES/$f" ]; then ln -sfn "$ANDROID_TEMPLATES/$f" "$DATA/export_templates/$GODOT_VER/$f"; fi
done
[ -e "$DATA/export_templates/$GODOT_VER/version.txt" ] || echo "$GODOT_VER" > "$DATA/export_templates/$GODOT_VER/version.txt"
# Only the SDK and JDK paths: Godot makes its own debug keystore (keytool) in $DATA/keystores the first time and
# fills in the debug key fields itself.
cat > "$CFG/editor_settings-4.3.tres" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$JAVA_HOME"
export/android/android_sdk_path = "$ANDROID_SDK_ROOT"
EOF

# ---- export ----
VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot | head -n 1)"
VERSION="${VERSION:-1.0.0}"        # no config/version yet: Godot's Android export also writes 1.0.0
if [ "$MODE" = release ]; then
  OUT="build/release/road-trip-hoops-$VERSION.apk"
else
  OUT="build/release/road-trip-hoops-$VERSION-debug.apk"
fi
mkdir -p build/release
touch build/.gdignore              # keep the Godot editor from importing the build output
rm -f "$OUT" "$OUT.idsig"

export XDG_CONFIG_HOME="$BUILD_HOME/config" XDG_DATA_HOME="$BUILD_HOME/data" XDG_CACHE_HOME="$BUILD_HOME/cache"
export JAVA_HOME
LOG="$BUILD_HOME/export.log"       # Godot masks the keystore fields in its own log (<REDACTED>)
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
if ! "$GODOT" --headless --path . "--export-$MODE" "Android" "$OUT" >"$LOG" 2>&1 || [ ! -s "$OUT" ]; then
  grep -E "ERROR|error|warning" "$LOG" | grep -v -i "password" | tail -n 20 >&2 || true
  fail "export failed (full log: $LOG)"
fi
rm -f "$OUT.idsig"                 # the v4 signature file is only for incremental adb installs

# ---- checks ----
APKSIGNER="$(ls -d "$ANDROID_SDK_ROOT"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -n 1)"
if [ -n "$APKSIGNER" ]; then
  "$APKSIGNER" verify "$OUT" >/dev/null 2>&1 || fail "apksigner verify failed on $OUT"
  echo "apksigner: signature verified"
  "$APKSIGNER" verify --print-certs "$OUT" 2>/dev/null | grep "certificate DN" || true
fi
if command -v aapt >/dev/null; then
  aapt dump badging "$OUT" | grep -E "^package:|^sdkVersion|^targetSdkVersion|^application-label:|^uses-permission|^native-code|landscape'$" || true
fi
echo "Built $OUT ($(du -h "$OUT" | cut -f1), $(stat -c %s "$OUT") bytes)"
