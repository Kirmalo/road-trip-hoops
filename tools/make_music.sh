#!/bin/sh
# Rebuild assets/music/*.ogg from the original OpenGameArt downloads (pages and licenses in CREDITS.md).
# Usage: sh tools/make_music.sh DIR   where DIR holds the original files named as below (as downloaded).
#
# Each track is cut to a seamless loop [start, end) found with `python3 tools/make_music.py find SRC ...`
# (the two points where the music sounds most alike, then aligned to the sample), the loop end is crossfaded
# (60 ms) into the music just before the loop start, downmixed to mono, matched to -20 LUFS (peaks under -1 dBFS)
# and encoded as Ogg Vorbis q3. Godot loops the file (audio.gd sets loop on the stream).
#
# Loop searches that gave these points (lengths are whole bars):
#   find menu     --min 20 --max 50  --from 1  --to 58    -> 11.45-42.67 (31.2 s, 16 bars)
#   find gym      --min 70 --max 150 --from 12 --to 171   -> 58.85-141.12 (82.3 s, 48 bars at 140 bpm)
#   find blacktop --min 25 --max 59  --from 0.5            -> 9.80-53.80 (44.0 s)
#   find hometown --min 80 --max 150 --from 17 --to 193   -> 54.55-160.15 (105.6 s)
#   find chicago  --min 40 --max 150 --from 0.3            -> 13.75-62.50 (48.75 s)
#   find newyork  --min 40 --max 127 --from 0.2            -> 57.80-121.70 (63.9 s, 24 bars)
set -e
D="$1"
M="python3 tools/make_music.py cut"
X="--xfade 0.06 --lufs -20 --q 3"
mkdir -p assets/music
$M "$D/hella bumps_0.mp3"        assets/music/menu.ogg     --start 11.45 --end 42.6695  $X
$M "$D/wednesday_night.ogg"      assets/music/gym.ogg      --start 58.85 --end 141.1235 $X
$M "$D/catchyswing.ogg"          assets/music/blacktop.ogg --start 9.80  --end 53.80    $X
$M "$D/apple_cider.ogg"          assets/music/hometown.ogg --start 54.55 --end 160.15   $X
$M "$D/Of Far Different Nature - Funky House (CC0)_0.mp3" \
                                 assets/music/chicago.ogg  --start 13.75 --end 62.50    $X
$M "$D/LofiLoop_2.ogg"           assets/music/newyork.ogg  --start 57.80 --end 121.7016 $X
