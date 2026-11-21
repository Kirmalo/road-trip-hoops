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
#
# Phase 6 listening list (P6-A3): docs/audio_preview/*.ogg are 30 s samples, not loops, made with
#   python3 tools/make_music.py preview SRC docs/audio_preview/<city>_<a|b>_<title>.ogg
# (sources and licenses in docs/audio_preview/LIST.md). The owner's picks (Phase 6) are cut at the end of this file:
#   memphis      New Blue Shoes (new_blue_shoes_0.mp3)           find --min 30 --max 90 --from 1 -> 41.90-76.46
#                (34.56 s, waveform corr 0.987)
#   new_orleans  Swingshot (swing.ogg, the author's looping OGG)  the page's loop offset 11.36 s to the file end;
#                checked: the end matches the music before 11.3605 s best at exactly that offset (40.43 s)
#   denver       Lasso Lady (lassolady_4.ogg), the author's seamless loop: whole file (73.72 s)
#   seattle      My Friends Will Cry (title theme, ..._0.ogg)     find --min 30 --max 90 --from 1 -> 11.20-93.2513
#                (82.05 s, corr 0.937)
#   los_angeles  Happy Ukelele Island Surfing Theme (ukele.mp3)   find --min 30 --max 90 --from 1 -> 6.40-93.6728
#                (87.27 s, corr 0.862); its peaks cap it at -21.8 LUFS
# Seam check (no listening): the 20 ms RMS envelope around each loop start and end in the source matches (the same
# hits in the same places), and the largest sample step at the wrap is within the track's normal range.
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
$M "$D/new_blue_shoes_0.mp3"            assets/music/memphis.ogg     --start 41.90 --end 76.46 --xfade 0.06 --lufs -20 --q 3
$M "$D/swing.ogg"                       assets/music/new_orleans.ogg --start 11.3605 --end full --xfade 0.01 --lufs -20 --q 3
$M "$D/lassolady_4.ogg"                 assets/music/denver.ogg      $W
$M "$D/my_friends_will_cry_title_0.ogg" assets/music/seattle.ogg     --start 11.20 --end 93.2513 --xfade 0.06 --lufs -20 --q 3
$M "$D/ukele.mp3"                       assets/music/los_angeles.ogg --start 6.40 --end 93.6728 --xfade 0.06 --lufs -20 --q 3
# Phase 9 (P9-16), the Legends Chapter 1 (Grandfathers era) track, the owner's pick D from docs/audio_preview/LIST.md:
#   legends_grand  Bebop (Chiptune) ("Bebop (Chiptune)_0.mp3", the stereo 320k MP3, not the page's other "Bebop.mp3")
#   The master is very loud (-5.4 LUFS integrated, true peak +1.4 dBFS) and hard-clipped: flat tops at full scale on
#   about 6% of the left channel's samples. Turning it down keeps the clipping, so first: the MP3's ripple on the
#   flat tops is flattened (hard clip at 0.95, scaled to 0.5 for headroom) and ffmpeg's adeclip rebuilds the clipped
#   peaks (afterwards 0.007% of samples above the old clip level, a smooth tail instead of a pile-up; it only rewrites
#   the clipped runs). Then 192 bpm (the file's tag; 1 bar = 1.25 s):
#   find --min 30 --max 95 --from 1 --to 101 -> 28.25-78.2516 (50.00 s, 40 bars, similarity 0.987, corr 0.839);
#   loops of 58 s or more matched far worse (<= 0.89). Seam: the source's 20 ms envelope at 28.25 and 78.25 s is the
#   same within 1 dB for 0.2 s before and 0.3 s after; wrap step 0.002 (the track's steps: p99 0.075).
#   Mono sum is safe (L/R correlation 0.31, mono loses 1-2.6 dB per band, no cancellation). -20 LUFS, peak -5.4 dBFS.
T=$(mktemp --suffix=.wav)
ffmpeg -v error -y -i "$D/Bebop (Chiptune)_0.mp3" \
    -af "aeval=exprs='0.5*clip(val(0)/0.95\,-1\,1)|0.5*clip(val(1)/0.95\,-1\,1)',adeclip=t=10:m=s" -c:a pcm_f32le "$T"
$M "$T"                                 assets/music/legends_grand.ogg --start 28.25 --end 78.2516 --xfade 0.06 --lufs -20 --q 3
rm -f "$T"
# Phase 10 (P10-20), the Legends Chapter 2 (Fathers era) track, the owner's pick A from docs/audio_preview/LIST.md:
#   legends_fathers  Headspin (headspin_0.mp3, the page's 128k joint-stereo MP3, 205.0 s; not the .xm module)
#   Loud master (-10.9 LUFS integrated, true peak +1.7 dBFS) but not clipped: no flat tops (0 samples within 2% of
#   the max), the 0.03% above 1.0 are MP3 overshoot, kept in float and turned down, so no de-clip step.
#   L/R correlation 0.98: the mono sum is safe. About 78.85 bpm (1 bar = 3.044 s):
#   find --min 40 --max 110 --from 12 --to 200 -> 76.55-173.9566 (97.41 s, 32 bars, similarity 0.996); the 16-bar
#   loop 51.20-99.90 matched worse (envelope off by up to 5 dB). Both points sit 0.18 s after a near-silent gap
#   (-40 dB) before a downbeat, so the loop is moved 0.21 s earlier into it (same length): 76.34-173.7466, 40 ms
#   crossfade inside the gap. Seam: the source's 20 ms envelope at 76.34 and 173.75 s is the same within 0.3 dB for
#   0.2 s before and 0.3 s after (100 ms blocks the same for 2 s); the encoded wrap is at -50 dB, step 0.0007 (the
#   track's steps: p99 0.125). -20.1 LUFS, true peak -4.3 dBFS, 913 KB.
$M "$D/headspin_0.mp3"                  assets/music/legends_fathers.ogg --start 76.34 --end 173.7466 --xfade 0.04 --lufs -20 --q 3
