#!/bin/sh
# Rebuild assets/sfx/*.ogg from the original OpenGameArt downloads (see CREDITS.md for the pages).
# swish.ogg and bounce.ogg are synthesized instead: tools/make_swish.py, tools/make_bounce.py
# Usage: sh tools/make_sfx.sh DIR   where DIR holds the original files (zips extracted) named as below.
set -e
D="$1"
M="python3 tools/make_sfx.py"
mkdir -p assets/sfx
$M "$D/bing1.wav"          assets/sfx/rim.ogg    --start 0.0  --end 0.70 --fade-out 0.25
$M "$D/Gregor Quendel - Crowd Cheering Sounds - 03 - Strong cheering - I.mp3" \
                           assets/sfx/crowd.ogg  --start 5.5  --end 10.5 --loop 0.5
$M "$D/metal_slam_01.ogg"  assets/sfx/dunk.ogg   --start 0.0  --end 0.57 --fade-out 0.12
$M "$D/impact.7.ogg"       assets/sfx/block.ogg  --start 0.26 --end 0.60 --fade-out 0.08
$M "$D/flame_0.ogg"        assets/sfx/fire.ogg   --start 0.0  --end 0.45 --fade-out 0.08
