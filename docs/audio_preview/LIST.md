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
