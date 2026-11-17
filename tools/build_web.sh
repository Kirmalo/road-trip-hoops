#!/usr/bin/env bash
# Build the web version and (optionally) publish it to the gh-pages branch for GitHub Pages.
#   tools/build_web.sh            build into build/web/
#   tools/build_web.sh --publish  build, then commit build/web/ to gh-pages and push it
#   tools/build_web.sh --zip      build fresh, then write the itch.io web ZIP
#                                 build/release/road-trip-hoops-<version>-web.zip (index.html at its root)
#   tools/build_web.sh --zip --publish   both (any order)
# <version> is project.godot's application/config/version ("dev" while that key is missing or empty).
# Needs Godot 4.3 on PATH as `godot` and the 4.3 web templates (web_nothreads_release.zip) in
# ~/.local/share/godot/export_templates/4.3.stable/ (see docs/TEAM.md). --zip also needs `zip`.
set -euo pipefail
cd "$(dirname "$0")/.."

do_zip=0
do_publish=0
for arg in "$@"; do
  case "$arg" in
    --zip) do_zip=1 ;;
    --publish) do_publish=1 ;;
    *) echo "Unknown option: $arg (use --zip and/or --publish)" >&2; exit 2 ;;
  esac
done

# itch.io limits for an HTML5 upload: at most 1000 files, no file over 200 MB.
ITCH_MAX_FILES=1000
ITCH_MAX_FILE_BYTES=$((200 * 1024 * 1024))

if [ "$do_zip" = 1 ]; then
  command -v zip >/dev/null || { echo "--zip needs the zip command" >&2; exit 1; }
  rm -rf build/web             # fresh export, so no stale file from an older build lands in the ZIP
fi

mkdir -p build/web
touch build/.gdignore          # keep the Godot editor from importing the build output
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-release "Web" build/web/index.html >/dev/null 2>&1
test -s build/web/index.wasm && test -s build/web/index.pck
echo "Built build/web ($(du -sh build/web | cut -f1))"

if [ "$do_zip" = 1 ]; then
  # The version, single source: config/version in project.godot's [application] section.
  version="$(awk '
    /^\[/ { in_app = ($0 == "[application]") }
    in_app && /^config\/version[ \t]*=/ {
      sub(/^[^=]*=[ \t]*/, ""); gsub(/^"|"[ \t\r]*$/, ""); print; exit
    }' project.godot)"
  if [ -z "$version" ]; then
    version="dev"
    echo "Warning: project.godot has no application/config/version; naming the ZIP with \"$version\"" >&2
  fi
  # itch.io embed checks: index.html at the root, relative paths only, within the file limits.
  test -s build/web/index.html && test -s build/web/index.js
  if grep -Eq '(src|href)="/' build/web/index.html; then
    echo "index.html uses an absolute path; itch.io needs relative paths" >&2; exit 1
  fi
  n_files="$(find build/web -type f | wc -l | tr -d ' ')"
  if [ "$n_files" -gt "$ITCH_MAX_FILES" ]; then
    echo "build/web has $n_files files; itch.io allows $ITCH_MAX_FILES" >&2; exit 1
  fi
  big="$(find build/web -type f -size +"${ITCH_MAX_FILE_BYTES}"c)"
  if [ -n "$big" ]; then
    echo "Over itch.io's 200 MB per file: $big" >&2; exit 1
  fi
  mkdir -p build/release
  zip_path="build/release/road-trip-hoops-${version}-web.zip"
  rm -f "$zip_path"
  # Flat: the files sit at the ZIP's root, no folder (-D: no directory entries, -X: no extra file attributes).
  (cd build/web && zip -q -9 -D -X -r "../../$zip_path" .)
  zip_bytes="$(wc -c < "$zip_path" | tr -d ' ')"
  echo "Wrote $zip_path ($n_files files, $(du -h "$zip_path" | cut -f1), $zip_bytes bytes)"
fi

if [ "$do_publish" = 1 ]; then
  src_commit="$(git rev-parse --short HEAD)"
  src_branch="$(git rev-parse --abbrev-ref HEAD)"
  tmp="$(mktemp -d)"
  if git ls-remote --exit-code --heads origin gh-pages >/dev/null 2>&1; then
    git fetch -q origin gh-pages
    git worktree add -q "$tmp" origin/gh-pages
    git -C "$tmp" checkout -q -B gh-pages
  else
    git worktree add -q --detach "$tmp"
    git -C "$tmp" checkout -q --orphan gh-pages
    git -C "$tmp" rm -rq --cached . >/dev/null 2>&1 || true
  fi
  find "$tmp" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp build/web/* "$tmp/"
  touch "$tmp/.nojekyll"
  printf 'Road Trip Hoops web build from %s (%s). Built by tools/build_web.sh; do not edit by hand.\n' \
    "$src_branch" "$src_commit" > "$tmp/README.txt"
  git -C "$tmp" add -A
  git -C "$tmp" commit -q -m "Web build from $src_branch $src_commit" || echo "No changes to publish"
  for i in 1 2 3 4; do git -C "$tmp" push -q -u origin gh-pages && break || sleep $((2 ** i)); done
  git worktree remove --force "$tmp"
  echo "Published to gh-pages"
fi
