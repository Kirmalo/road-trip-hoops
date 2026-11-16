#!/bin/sh
# Rebuild assets/music/*.ogg from the original OpenGameArt downloads (pages and licenses in CREDITS.md).
# Usage: sh tools/make_music.sh DIR   where DIR holds the original files named as below (as downloaded;
# the Juhani Junkala tracks come out of the two pack ZIPs).
#
# All tracks are upbeat chiptune (Phase 4 check-in). Each is downmixed to mono, matched to -20 LUFS (peaks under
# -1 dBFS) and encoded as Ogg Vorbis q3. Godot loops the file (audio.gd sets loop on the stream).
#
# Most sources are made to loop as whole files (the author's seamless loops; --start 0 --end full). Their wrap
# point gets a 5 ms equal-power blend of the last samples into the first (shortens the loop by 5 ms, too little to
# hear in the rhythm) so a tiny step at the seam can't click.
# Slam-Funk's own loop point did not match its file end, so its loop was found with
#   python3 tools/make_music.py find funk_0.ogg --min 30 --max 60 --from 0.5  -> 6.10-45.4542 (39.35 s, 20 bars)
# and the loop end is crossfaded (60 ms) into the music just before the loop start.
#
# Tempos (checked by onset autocorrelation and file length = whole bars):
#   menu 140 bpm (24 bars), gym 154 (36 bars), blacktop 181 (56 bars), hometown ~171 (6/8 feel),
#   chicago ~125 shuffle, newyork 122 (20 bars).
set -e
D="$1"
M="python3 tools/make_music.py cut"
W="--start 0 --end full --xfade 0.005 --lufs -20 --q 3"
mkdir -p assets/music
$M "$D/Juhani Junkala [Chiptune Adventures] 1. Stage 1.ogg"   assets/music/menu.ogg     $W
$M "$D/Juhani Junkala [Chiptune Adventures] 2. Stage 2.ogg"   assets/music/gym.ogg      $W
$M "$D/Juhani Junkala [Retro Game Music Pack] Level 1.wav"    assets/music/blacktop.ogg $W
$M "$D/CHIPTUNE_Loop_Minstrel_Dance_0.wav"                    assets/music/hometown.ogg $W
$M "$D/8-bit_bluesy_battle_2.ogg"                             assets/music/chicago.ogg  $W
$M "$D/funk_0.ogg" assets/music/newyork.ogg --start 6.10 --end 45.4542 --xfade 0.06 --lufs -20 --q 3
