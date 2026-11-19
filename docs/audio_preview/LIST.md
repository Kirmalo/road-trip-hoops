# Music listening list: Memphis, New Orleans, Denver, Seattle, Los Angeles (P6-A3, owner Q5 (a))

Two candidates per city: upbeat chiptune with a hint of the city's style. Each `.ogg` here is a 30-second sample
(mono, -20 LUFS like the game music, faded in and out), not the game loop. Pick one per city (or "neither"); the
picked tracks then get cut into seamless loops in `assets/music/` with `tools/make_music.sh` and a row in
`CREDITS.md`. Nothing here ships in the game yet.

All from OpenGameArt. Licenses were read on each page: only CC0 or CC-BY (no share-alike, no non-commercial). Where
a page offers several licenses, we would use the one named below. CC-BY tracks need the credit line in the game's
credits.

| City | Sample | Title | Author | Page | License | What it sounds like |
|---|---|---|---|---|---|---|
| Memphis (soul) | `memphis_a_dawn_of_derangements.ogg` | Dawn of Derangements | Mega Pixel Music Lab | https://opengameart.org/content/dawn-of-derangements | CC-BY 4.0 (also offered: CC-BY 3.0, CC-BY-SA) | Funky FM chiptune: chip slap bass, horns and bells, a steady head-bobbing groove (the most soul-like horns we found) |
| Memphis (soul) | `memphis_b_new_blue_shoes.ogg` | New Blue Shoes | congusbongus | https://opengameart.org/content/new-blue-shoes | CC-BY 4.0 (also offered: OGA-BY 4.0) | Funky OPL3 chiptune "theme music for a cool character", bright and bouncy |
| New Orleans (brass, jazz) | `new_orleans_a_swingshot.ogg` | NES chiptune "Swingshot" (Swing Jazz) | Haley Halcyon | https://opengameart.org/content/nes-chiptune-swingshot-swing-jazz | CC0 | Swing jazz on the NES chip, 12-bar blues in B flat; same composer as the New York track |
| New Orleans (brass, jazz) | `new_orleans_b_welcome_to_swindlers_remix.ogg` | Welcome to Swindler's! - 2nd Remix | Spring Spring | https://opengameart.org/content/welcome-to-swindlers-2nd-remix | CC-BY 4.0 (also offered: CC-BY 3.0, OGA-BY, CC-BY-SA) | Swinging 16-bit tracker remix with brass, a chiptune song redone; the closest to a brass band |
| Denver (bluegrass, folk) | `denver_a_backfoot.ogg` | Backfoot (extended version) | Centurion_of_war | https://opengameart.org/content/backfoot | CC0 | Upbeat retro chip tune with a banjo undertone; short and driving |
| Denver (bluegrass, folk) | `denver_b_lasso_lady.ogg` | Lasso Lady (seamless loop) | congusbongus | https://opengameart.org/content/lasso-lady-seamless-loop | CC0 | NES-style western action theme, 140 bpm, cowboy gallop; already a seamless loop |
| Seattle (rock) | `seattle_a_central_brocessing_unit.ogg` | Central Brocessing Unit | Chance de la Soul | https://opengameart.org/content/central-brocessing-unit | CC0 | Chiptune indie rock with guitar energy, in the style of chip-rock bands |
| Seattle (rock) | `seattle_b_my_friends_will_cry.ogg` | My Friends Will Cry. (title theme) | Christovix (asks for the credit "Music by Christovix Games") | https://opengameart.org/content/my-friends-will-cry | CC-BY 3.0 (also offered: CC-BY-SA 3.0) | Driving NES/SNES rock tune, simple and steady |
| Los Angeles (surf) | `los_angeles_a_beach_stage.ogg` | Beach Stage | MintoDog | https://opengameart.org/content/beach-stage | CC0 | 8-bit beach action stage, 128 bpm, sunny and fast; loopable |
| Los Angeles (surf) | `los_angeles_b_ukulele_surfing.ogg` | Happy Ukelele Island Surfing Theme | Tarush Singhal | https://opengameart.org/content/happy-ukelele-island-surfing-theme | CC0 | 8-bit melody with ukulele and drums, happy island surfing mood (more beach than surf rock) |

Notes:
- Real chiptune surf rock and bluegrass are rare on OpenGameArt. The LA picks lean "beach", the Denver picks lean
  "western/banjo". A true surf-rock pack exists there (Blue Wave Theory) but it is CC-BY-SA, so it is not listed.
- Skipped for licensing: a CC0 pop-punk chiptune album whose notes add "don't re-upload these tracks" (unclear next
  to CC0), and several share-alike or OGA-BY-only tracks.
- Samples made with `python3 tools/make_music.py preview SRC OUT` (the busiest 30 s after the first 4 s).

## Legends: Grandfathers (P9-06)

The first era's chapter track: upbeat chiptune with an old-school feel (swing, big band, march, ragtime), per VISION
"Music style". Five candidates; each `grand_*.ogg` here is a 30-second sample made like the city samples above (mono,
-20 LUFS, faded in and out, the busiest 30 s after the first 4 s). Pick one (or "none of these"); the pick then gets
cut into a loop in `assets/music/` (P9-16), with a row in `CREDITS.md` and `CREDITS_LIST`. Nothing here is in the game.

All from OpenGameArt; each license was read on the track's page (November 2026): CC0 or CC-BY only. "Swingshot" is
left out on purpose: it is already the New Orleans track. Tempos are rough measurements from the files.

| Sample | Title | Author | License | Page | Length | Why it fits | What would change |
|---|---|---|---|---|---|---|---|
| `grand_a_american_patrol.ogg` | American Patrol | tcarisland | CC-BY 4.0 (https://creativecommons.org/licenses/by/4.0/; the page also offers CC-BY 3.0 and OGA-BY 4.0, we would use CC-BY 4.0) | https://opengameart.org/content/american-patrol | 2:08 (MP3, about 144 bpm) | An 8-bit arrangement of F. W. Meacham's 1885 march (public domain), the tune the big bands swung in the 1940s; half march, half swing ("not as much syncopation as the swing version, but not as 4/4 as the original"). The most "grandfathers" of the five: brass-band pep with a swing bounce | MP3 only, no loop points: we pick a loop on a phrase and crossfade it (60 ms, like Memphis); mono, -20 LUFS, Ogg q3; credit row "American Patrol" by tcarisland, CC-BY 4.0 |
| `grand_b_n163_swing_rhythm.ogg` | N163 Swing Rhythm | Spring Spring | CC0 (https://creativecommons.org/publicdomain/zero/1.0/) | https://opengameart.org/content/n163-swing-rhythm | 1:17 (Ogg, mono, about 150 bpm) | Fast swing on the Famicom N163 chip (FamiTracker): the brightest and quickest, a jitterbug dance-hall number | Short: the loop is most of the file, so it repeats often in a game; mono already, -20 LUFS, Ogg q3; credit as a courtesy (CC0) |
| `grand_c_puppydog_swing.ogg` | Puppydog Swing | Spring Spring | CC0 (https://creativecommons.org/publicdomain/zero/1.0/) | https://opengameart.org/content/puppydog-swing | 2:03 (Ogg, mono, about 100 bpm) | A VRC6 (Famicom expansion chip) swing tune: medium bouncy swing, warmer and less hectic than N163; other projects already use it as loop music | Loop on a phrase with a crossfade; mono already, -20 LUFS, Ogg q3; courtesy credit |
| `grand_d_bebop.ogg` | Bebop (Chiptune) | Pro Sensory | CC0 (https://creativecommons.org/publicdomain/zero/1.0/; the author: "all my music is public domain"; a name credit is a voluntary request) | https://opengameart.org/content/bebop-chiptune | 1:44 (MP3, stereo) | Chiptune bebop: walking-bass jazz-club energy, a late-40s/50s small-combo feel rather than a big band | Mastered very loud (about -8 LUFS): brought down to -20 LUFS, check for clipping grit; loop with a crossfade, mono, Ogg q3; we would credit the name anyway. The page also has a non-chiptune "Bebop" file; the sample uses `Bebop (Chiptune)` |
| `grand_e_one_horse_town.ogg` | One Horse Town | tcarisland | CC-BY 4.0 (https://creativecommons.org/licenses/by/4.0/) | https://opengameart.org/content/one-horse-town | 2:25 (MP3 and WAV, 110 bpm) | 8-bit ragtime: saloon-piano bounce, the oldest-sounding style here (turn of the century more than the 50s), cozy more than intense | Loop points given on the page (1:09.81 to 2:19.63), cut from the WAV; a quiet master (about -27 LUFS) raised to -20 LUFS; mono, Ogg q3; credit row by tcarisland, CC-BY 4.0. Leans "western town", close to the Hometown track's mood |

Notes:
- Order of fit (art-audio's view): American Patrol (march plus swing: old school and still driving enough for a game
  to 21), then Puppydog Swing or N163 Swing Rhythm (pure chiptune swing), then Bebop, then One Horse Town.
- Looked at and left out: "International Vegetable Jumping Contest" (CC-BY 4.0, jazzy shuffle; it starts from a
  transcription of a commercial game's theme), "Ragtime Jazz" (Tarush Singhal, CC0; its page is tagged with a
  commercial game's name, so it may imitate that game's music), "Shufflin'" (Eric Matyas, CC-BY 3.0, big band, but
  not chiptune), tracks offered only as OGA-BY or CC-BY-SA, and one swing track with an insulting title.
