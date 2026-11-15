#!/usr/bin/env bash
# Build the web version and (optionally) publish it to the gh-pages branch for GitHub Pages.
#   tools/build_web.sh            build into build/web/
#   tools/build_web.sh --publish  build, then commit build/web/ to gh-pages and push it
# Needs Godot 4.3 on PATH as `godot` and the 4.3 web templates (web_nothreads_release.zip) in
# ~/.local/share/godot/export_templates/4.3.stable/ (see docs/TEAM.md).
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build/web
touch build/.gdignore          # keep the Godot editor from importing the build output
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-release "Web" build/web/index.html >/dev/null 2>&1
test -s build/web/index.wasm && test -s build/web/index.pck
echo "Built build/web ($(du -sh build/web | cut -f1))"

if [ "${1:-}" = "--publish" ]; then
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
