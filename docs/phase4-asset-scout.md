# Phase 4 asset scout (OpenGameArt only)

Research only: nothing here is in `assets/` or `CREDITS.md` yet. Every license below was read on the asset's own
OpenGameArt page (the "License(s)" field) on 2026-11-16. Where a page lists several licenses (dual licensing) we may
pick the CC0 or CC-BY one. "Checked" means a file was downloaded to a temp dir and looked at; other rows are judged from
the page text and preview only.

Network: only opengameart.org was used. kenney.nl, itch.io and freesound.org were not tried (refused or blocked);
several Kenney packs are mirrored on OpenGameArt by Kenney himself, so those are reachable.

Today's game: straight top-down, Kenney Sports Pack players (21x31 px, drawn at 1.75x, facing +x), ball 18x18,
floor, lines, rims and nets drawn in code (`scripts/court.gd`). VISION proposes 32x32 player sprites at 2x.

Fit: **good** = usable with small edits, **ok** = usable with real work or a style compromise, **poor** = not
recommended.

## 1a. Players, straight top-down (current camera)

| Page | Title | Author | License | Contents | Fit |
|---|---|---|---|---|---|
| https://opengameart.org/content/sports-pack-350 | Sports pack (350+) | Kenney | CC0 | The pack we use now (checked): 5 shirt colors x 5 skin tones x 2 hair styles, single pose, ~21x31; top-down basketball hoops (4 orientations, 2 styles), balls, nets, colored field tiles | ok: legal and consistent, but flat vector style, not pixel art, no walk frames |
| https://opengameart.org/content/hockey-players | hockey players | wutang33 | CC0 | Checked: idle + 2 skate frames per team, 100x100 canvas, ~30 px body, holds a stick | poor: hockey gear and stick baked in, crude |
| https://opengameart.org/content/top-down-runner | Top Down Runner | tokka | CC-BY 3.0 (or GPL 3.0) | Checked: 265x558 sheet, GTA1/2-style man, idle + run frames, ~60 px | ok: real overhead run cycle, but painted (not crisp pixel art), street clothes, one character |
| https://opengameart.org/content/human-topview | Human topview | E-norm | CC0 | Checked: 469x344 sheet of overhead men, single poses | poor: no walk frames, holds guns |
| https://opengameart.org/content/top-down-man-with-gun-animated | Top Down Man With Gun - Animated | Technopeasant | CC0 | Overhead walk with legs (from the zombie pack below) | poor: gun in hand; legs could be borrowed |
| https://opengameart.org/content/animated-top-down-zombie | Animated Top Down Zombie | rileygombart | CC0 | Overhead zombie walk with animated legs | poor: zombie, but the CC0 leg frames could be reused under a self-drawn torso |
| https://opengameart.org/content/animated-top-down-survivor-player | Animated Top Down Survivor Player | rileygombart | CC-BY 3.0 | 20-frame overhead move/idle, high-res (~250 px), always holding a weapon | poor: weapons in every frame, not pixel art |
| https://opengameart.org/content/low-pixel-fighters-top-view | low-pixel fighters (top-view) | qubodup (from BOFH) | CC-BY 3.0 / GPL | Tiny overhead walk/shoot/die | poor: soldiers with guns |
| https://opengameart.org/content/pixelart-humans-characters | Pixelart humans characters | madmedicsoft | CC0 | Checked: overhead (`*_top.png`) and 3/4 soldier sheets, 8 dirs, ~24 px | poor: military, weapon poses |
| https://opengameart.org/content/2d-top-down-office-characters | 2D Top Down Office Characters | BunnyHop43 | CC0 | One SVG of overhead office workers | poor: vector, office clothes, no frames |

No top-down basketball player sprite exists on OpenGameArt. The closest usable base is the Kenney figure we already
have. Best route for top-down: **code-drawn or self-made 32x32 pixel sprites** (head, shoulders, arms, two-frame legs),
recolored per team by a palette shader. A top-down figure is mostly a head and shoulders, so a script in `tools/` can
draw it; the only animation needed is a 2-4 frame leg/arm swing.

## 1b. Players, 3/4 or side view (if the camera changes)

| Page | Title | Author | License | Contents | Fit |
|---|---|---|---|---|---|
| https://opengameart.org/content/pixel-baller-basketball-player-sprite-pack | Pixel Baller - Basketball Player Sprite Pack | ericlambdev (Eric Lamb) | CC-BY 4.0 (also in its README) | Checked: 80x140 frames, 7 animations / 34 frames (dribble 6, jumpshot 9, run 6, run_dribble 6, defense 2, pass 3, idle 2), 6 uniforms x 3 skin tones, blank jersey, 1x and 4x sheets, ~39 colors | ok-good: the only real basketball player pack, clean pixel art, team colors already made. But all frames face the camera (front view, no side, back or turned poses), and 80x140 is ~4x the size VISION plans; shrinking pixel art looks bad. Uploaded 2026-11-12, very new |
| https://opengameart.org/content/puny-characters | Puny Characters | Shade | CC0 | Checked: 32x32 canvas (fits 16x16), 8 directions, idle/walk/attack rows; plain base + colored variants | ok: proper 8-direction 3/4 walk, recolorable, CC0; but chibi RPG people, would need shirts/shorts drawn on and a ball-holding pose |
| https://opengameart.org/content/24x32-bases-0 | 24x32 Bases | diamonddmgirl | CC0 | Checked: 24x32 RPG bases, 4 directions x 3 walk frames, 5 skin tones x 3 builds | ok: good recolorable base, 4 directions, but RPG proportions and no sports poses |
| https://opengameart.org/content/rpg-urban-pack | RPG Urban Pack | Kenney | CC0 | Checked: 16x16 tiles + 6 modern characters, 4 directions with walk frames | ok: modern people, 4-dir walk, tiny (16 px); good for crowd/bench, small for players |
| https://opengameart.org/content/urban-character-pack | Urban Character Pack | Doodle | CC0 | Checked: 31 modern street characters, idle/walk/attack/jump/hold, small front 3/4 view | ok: streetwear, jump and hold poses; best as crowd or bench filler |
| https://opengameart.org/content/cozy-town-lite-%E2%80%94-16x16-top-down-street-tiles-caf%C3%A9-and-walking-character | Cozy Town Lite | roberto mellado (credit "Spaceyyy") | CC-BY 4.0 | Checked: one 16x24 player, idle + walk in 4 directions, plus street tiles | poor-ok: one character, small |
| https://opengameart.org/content/24x32-characters-with-faces-big-pack | 24x32 characters with faces | Cabbit (Svetlana Kushnariova) | CC-BY 3.0 / OGA-BY 3.0 | 50+ RPG characters, 4-dir walk | poor: fantasy costumes |

## 1c. Comparison: top-down vs 3/4 camera

| | Straight top-down (today) | Angled 3/4 (arcade style) |
|---|---|---|
| Ready-made player sprites | None that are basketball. Overhead people on OGA are almost all shooters holding guns. Kenney figures (CC0, vector, no frames) are what we have | Pixel Baller (CC-BY 4.0): a real basketball player with dribble, jump shot, run, pass and defense, 6 uniforms. Front-facing only, 80x140 px |
| What we'd draw or recolor | Whole player sprite by script (overhead body is simple: head, shoulders, arms, 2-4 leg frames) plus palette shader for teams. Hoop, lines, nets stay code-drawn as now | With Pixel Baller: side-facing and back-facing run frames are missing, so either mirror/accept front-facing players running sideways, or draw turn frames by hand (a lot of work at 80x140). Shrinking 80x140 to the planned ~32 px size would lose the detail. With Puny/24x32 Bases (CC0, 4-8 directions): paint jerseys and shorts on by script, draw ball-holding and shooting poses |
| Hoop and court | Code-drawn already; Kenney top-down hoop (CC0) is an option | Side-view hoops exist (Pixel Courts, Leozlk 32x32 sheet); the court floor must be drawn foreshortened in code (lines in perspective) with floor tiles |
| Gameplay code impact | None | Large: depth sorting by y, z-height drawing, hit areas and the camera all change |

Short version: top-down keeps the code and needs a self-drawn player sprite; 3/4 gets one good basketball pack but
it lacks direction frames and is far bigger than planned, and the camera change touches most drawing code.

## 2. Ball and hoop

| Page | Title | Author | License | Contents | Fit |
|---|---|---|---|---|---|
| https://opengameart.org/content/basketballs-32x32 | Basketballs [32x32] | Leozlk | CC0 | Checked: 96x64 sheet, 32x32 and 16x16 balls in 6 styles, plus a side-view hoop with backboard, net and pole | good: plain orange 16x16/32x32 pixel ball. Skip the balls with lettering ("W", "CLUTCH", stripes), they could read as brands. The hoop is side view (3/4 option) |
| https://opengameart.org/content/basketball-1 | Basketball | MonoTone | CC0 | Checked: 17x17 pixel ball | good: matches today's ball size |
| https://opengameart.org/content/basketball-0 | Basketball | loltsilol | CC0 | Checked: 32x32 simple ball | ok |
| https://opengameart.org/content/pixel-courts-basketball-court-backgrounds-tiles | Pixel Courts (props) | ericlambdev | CC-BY 4.0 | Checked: side-view hoops (indoor and street, left/right, 120x300), 16x16 ball, bench 96x40, scoreboard 120x56 | good for 3/4 or side camera; no use top-down |
| https://opengameart.org/content/sports-pack-350 | Sports pack (350+) | Kenney | CC0 | Checked: top-down hoops (rim + backboard + pole, 4 directions, 2 styles), basketballs | ok: the only top-down hoop, but vector style. Today's code-drawn rim and net are already fine |
| https://opengameart.org/content/basketball-pack | Basketball Pack | looneybits | CC0 | Cartoon vector catch-game assets (not downloaded) | poor: not pixel art |

## 3. Court and ground tiles, decoration

Courts are about 1128x600 px. Lines, keys and arcs must stay code-drawn (they come from the rules geometry); what we
need is a seamless floor texture per city tiled under them, plus props around the court.

| Page | Title | Author | License | Contents | Fit |
|---|---|---|---|---|---|
| https://opengameart.org/content/pixel-courts-basketball-court-backgrounds-tiles | Pixel Courts (tiles) | ericlambdev | CC-BY 4.0 | Checked: seamless 32x32 wood, asphalt and concrete floor tiles; side-view scenes (gym with crowd, night street with chain-link fence, desert) in parallax layers | good: wood gym (Memphis), asphalt (New Orleans, NYC), concrete (Chicago rooftop, Denver). Scenes only fit a side/3-4 camera |
| https://opengameart.org/content/sports-pack-350 | Sports pack (field tiles) | Kenney | CC0 | 208 field tiles in 10 color schemes incl. orange, grey and sand court colors | ok: flat colors, not pixel art |
| https://opengameart.org/content/pixel-art-wood-tiles | Pixel Art Wood Tiles | SpinachChicken | CC0 | Wood plank tiles | ok: gym floor or barn boards |
| https://opengameart.org/content/wood-floor | Wood Floor | DavidRStudios | CC0 | Wood floor tile | ok |
| https://opengameart.org/content/lpc-modern-streets | LPC Modern Streets | Faufilage | CC0 | Sidewalks, cracked road, drains, manholes, sign poles | ok: asphalt and sidewalk surrounds (NYC, New Orleans) |
| https://opengameart.org/content/roguelike-modern-city-pack | Roguelike Modern City pack | Kenney | CC0 | 1000+ 16x16 city tiles: roads, parking, buildings | ok: city surrounds, fences |
| https://opengameart.org/content/rpg-urban-pack | RPG Urban Pack | Kenney | CC0 | Checked: 480 16x16 tiles: courts/plazas, fences, benches, trees, cars, people | good: benches, chain fence, trees, street props for any city |
| https://opengameart.org/content/tiny-city | Tiny City | Kenney | CC0 | 130 16x16 city tiles | ok |
| https://opengameart.org/content/tiny-town | Tiny Town | Kenney | CC0 | 130 16x16 town tiles (grass, fences, trees, houses) | ok: Hometown barn driveway surrounds, Denver park |
| https://opengameart.org/content/tiny-ski | Tiny Ski | Kenney | CC0 | 130 16x16 snow tiles | ok: snow edges if a court is wintry |
| https://opengameart.org/content/very-basic-32x32-topdown-snow-tileset | Very Basic 32x32 Topdown Snow Tileset | Spring Spring | CC0 | 32x32 snow tiles | ok |
| https://opengameart.org/content/cozy-farm-lite-16x16-top-down-farm-tiles-crops-farmer-hen | Cozy Farm Lite | roberto mellado (Spaceyyy) | CC-BY 4.0 | 16x16 grass, dirt path, crops, farmer, hen | ok: Hometown barn surrounds |
| https://opengameart.org/content/park-mini-sprite-pack | Park - Mini Sprite Pack | Gerald Burke | CC0 | Small park props (4 KB) | ok |
| https://opengameart.org/content/top-down-foliage-collection | Top down foliage collection | Liosan | CC-BY 3.0 | Overhead palm trees, trees, bushes (painted) | ok: LA palms, Seattle/Denver trees; painted style |
| https://opengameart.org/content/slates-32x32px-orthogonal-tileset-by-ivan-voirol | Slates 32x32 | Ivan Voirol | CC-BY 4.0 | Large 32x32 RPG tileset (grass, sand, water, stone) | ok: beach sand and water edge for LA |
| https://opengameart.org/content/ground-tileset-grass-sand | Ground Tileset // Grass & Sand // | chabull | CC-BY 3.0 | Grass/sand tiles | ok |
| https://opengameart.org/content/tiny-16-basic | Tiny 16: Basic | Sharm | CC-BY 4.0 / CC-BY 3.0 / OGA-BY | 16x16 basic overworld | ok |

City-by-city coverage: barn driveway (wood/dirt + Tiny Town/Cozy Farm), Chicago rooftop (concrete tile + code-drawn
ledge), Memphis gym (wood), New Orleans blacktop (asphalt), Denver park (concrete/asphalt + trees), Seattle rain
(asphalt + code-drawn puddles/rain), LA beach (sand + palms), NYC cage (asphalt + RPG Urban chain fence). A top-down
**crowd** was not found anywhere.

## 4. Effects

| Page | Title | Author | License | Contents | Fit |
|---|---|---|---|---|---|
| https://opengameart.org/content/free-pixel-effects-pack | Free Pixel Effects Pack | CodeManu | CC0 | 20 pixel effects, 100x100 frames (fire, smoke, hits) | good: dust puff, fire, impact |
| https://opengameart.org/content/pixel-fx-pack | Pixel FX Pack | CodeManu | CC0 | More pixel effects | good |
| https://opengameart.org/content/party-confetti-sprite-sheet-effect | party confetti sprite sheet effect | sketcherskt | CC0 | Checked: 10 frames of 64x64 | good: game-over/win confetti |
| https://opengameart.org/content/confetti-effect-spritesheet | Confetti Effect Spritesheet | jellyfizh | CC0 | One 601 KB sheet | ok: large |
| https://opengameart.org/content/4-generic-animated-sparks | 4 generic animated sparks | Puffolotti | CC0 | Checked: 1026x563 sheet, 4 spark animations | good: block/dunk impact |
| https://opengameart.org/content/spark-effect | Spark effect | kurohina | CC0 | Two 9-frame spark strips | good |
| https://opengameart.org/content/smoke-fire-animated-particle-16x16 | Smoke & Fire Animated Particle [16x16] | KnoblePersona | CC-BY 3.0 | Checked: 64x64 sheet of 16x16 frames | good: on-fire trail particle, dust |
| https://opengameart.org/content/fx-smoke-trail-pixel | FX Smoke Trail Pixel | DkuCook | CC0 | Small animated smoke trail GIF | ok |
| https://opengameart.org/content/fire-fx-burning-fire-animation | Fire FX - Burning Fire Animation | Mikodrak | CC0 | 40-frame fire loop (zip) | ok: not pixel art |
| https://opengameart.org/content/particle-pack-80-sprites | Particle Pack (80+ sprites) | Kenney | CC0 | 80 soft particle textures | ok: for GPUParticles, not pixel art |

## 5. Music

Sizes are the files as posted. Re-encoded to mono or low-bitrate Ogg Vorbis (~q3), 1.5-2.5 min tracks come to about
1-2 MB each, so nine tracks fit well under 30 MB. MP3-only tracks need converting to .ogg; loop points need checking by
ear.

| City / style | Page | Title | Author | License | File | Fit |
|---|---|---|---|---|---|---|
| Hometown: acoustic/Americana | https://opengameart.org/content/apple-cider | Apple Cider | Zane Little Music | CC0 | ogg 3.1 MB | good: cozy acoustic |
| | https://opengameart.org/content/gone-fishin | Gone Fishin' | You're Perfect Studio (memoraphile) | CC0 (also CC-BY 4.0 / OGA-BY) | mp3 3.4 MB + menu track 2.3 MB | good: country/bluegrass feel |
| | https://opengameart.org/content/miniature-saloon | Miniature Saloon | Zane Little Music | CC0 | wav 11 MB | ok: honky-tonk |
| | https://opengameart.org/content/country | Country | Pro Sensory | CC0 | mp3 2.5 MB | ok (not heard) |
| Chicago: blues/house | https://opengameart.org/content/bgm-blues-guitar-loop | Bgm Blues Guitar Loop | Ncone | CC-BY 3.0 | mp3 1.2 MB, a loop | good: blues guitar loop |
| | https://opengameart.org/content/funky-house | Funky House | Of Far Different Nature | CC0 | mp3 2.7 MB (seamless loop version in LOOP BOX #4) | good: the house half of the brief |
| | https://opengameart.org/content/blues-0 | Blues | Spring Spring | CC0 | ogg 1.4 MB | ok ("loud bass") |
| | https://opengameart.org/content/jazzy-blues | Jazzy blues | LushoGames | CC0 | mp3 2.1 MB | ok |
| | https://opengameart.org/content/a-conversation-with-saul-jazzblues-shuffle | A Conversation with Saul | Matthew Pablo | CC-BY 3.0 | mp3 3.8 MB, live band | good: live blues shuffle |
| Memphis: soul/blues | https://opengameart.org/content/wednesday-night-funk-fusion | Wednesday Night [Funk Fusion] | Zane Little Music | CC0 | ogg 2.8 MB | ok-good: funk/soul |
| | https://opengameart.org/content/raspberry-jam | Raspberry Jam | congusbongus | CC0 | ogg 2.9 MB | ok: New Jack Swing |
| | https://opengameart.org/content/funky-sweet-70s | (Funky) Sweet 70s | Clement Panchout | CC-BY 4.0 | wav 19.8 MB | good: 70s soul-funk |
| | https://opengameart.org/content/laid-back | laid-back | VViard | CC-BY 4.0 | mp3 2.6 MB | ok: simple blues |
| | https://opengameart.org/content/funkorama | Funkorama | Kevin MacLeod (posted by bart) | CC-BY 3.0 | ogg 5.1 MB | ok: credit Kevin MacLeod |
| New Orleans: brass band jazz | https://opengameart.org/content/catchy-swing | Catchy Swing | Doge | CC0 | ogg 1.1 MB, loopable | ok: swing, not a brass band |
| | https://opengameart.org/content/a-cloudy-morning-jazz | A Cloudy Morning (Jazz) | Matthew Pablo | CC-BY 3.0 | mp3 5.7 MB, live sax | ok: jazz, not second-line |
| | https://opengameart.org/content/time-to-business-guys | Time to business, guys | Alexandr Zhelanov | CC-BY 3.0 | mp3 0.25 MB | ok: short jazz cue |
| | https://opengameart.org/content/swing-along | Swing Along | bramd | CC-BY 4.0 | mp3 5.3 MB | ok: electro swing |
| Denver: folk/bluegrass | https://opengameart.org/content/windle-pixel-and-his-banjo-buddies-looping | Windle Pixel and His Banjo Buddies (Looping) | Eric Matyas | CC-BY 3.0 | ogg 4.3 MB, 1:15 loop | good: banjo, made to loop |
| | https://opengameart.org/content/banjosomething | Banjo_something | G_P | CC0 | mp3 3.6 MB | ok |
| | https://opengameart.org/content/down-the-river | Down The River | Loyalty Freak Music (Komiku) | CC0 | mp3 4.6 MB | ok: folky adventure |
| Seattle: grunge/indie rock | https://opengameart.org/content/neon-grunge-looping | Neon Grunge (Looping) | Eric Matyas | CC-BY 3.0 | ogg 2.7 MB, 0:54 loop | ok: "grunge" in name, synth-leaning |
| | https://opengameart.org/content/easy-ride | Easy Ride | Alexandr Zhelanov | CC-BY 3.0 | mp3 2.6 MB | good: indie rock |
| | https://opengameart.org/content/garage-0 | Garage | Umplix | CC0 | mp3 2.6 MB | ok (not heard) |
| LA: surf rock / West Coast hip-hop | https://opengameart.org/content/beach-sports-theme-loop | Beach Sports Theme (Loop) | Trex0n | CC0 | ogg 0.6 MB, loop | ok: beachy, not surf rock |
| | https://opengameart.org/content/wild-west-coast-racing-looping | Wild West Coast Racing (Looping) | Eric Matyas | CC-BY 4.0 | ogg 5.1 MB | ok |
| | https://opengameart.org/content/midnight-cruiser | Midnight Cruiser | Zane Little Music | CC0 | mp3 5.6 MB | ok: chill cruising |
| | https://opengameart.org/content/surf-riot | Surf Riot | joeBaxterWebb | CC-BY 4.0 | mp3 1.6 MB | poor-ok: breakbeat despite the name |
| NYC: boom-bap hip-hop | https://opengameart.org/content/hiphop-old-school-chill-themes | Hiphop / Old School / Chill Themes | vandalorum | CC-BY 4.0 | 4 mp3s, 1.4-2.5 MB | good: old-school beats ("New Hip Hop Beat") |
| | https://opengameart.org/content/gangtazz | Gang$tazz | Alexandr Zhelanov | CC-BY 4.0 | ogg 6.3 MB | ok: West Coast style, also fits LA |
| | https://opengameart.org/content/lofi-hip-hop-loop | Lofi Hip Hop Loop | omfgdude | CC0 | ogg 1.4 MB, loop | ok |
| | https://opengameart.org/content/urban-theme | Urban Theme | MintoDog | CC0 | ogg 2.9 MB, loopable | ok |
| Menu | https://opengameart.org/content/hella-bumps-menu-music | Hella Bumps (menu music) | cynicmusic | CC0 | mp3 0.9 MB | good: upbeat menu loop |
| | https://opengameart.org/content/opening-theme-for-soccer-video-games | Opening Theme For Soccer Video Games | ISAo | OGA-BY 3.0 | mp3 0.9 MB, 40 s | ok: stadium feel; OGA-BY needs approval (see below) |
| | https://opengameart.org/content/loop-box-1-beats-for-rpg-platformers-visual-novels-adventure-puzzle-games-simulators-menu | LOOP BOX #1 | Of Far Different Nature | CC-BY 4.0 | 15 loops, ogg zip 21 MB | good: seamless loops in many styles, mine for menu and fallbacks |

## 6. Swish and bounce

No real basketball, net or ball-bounce recordings on OpenGameArt (searches: basketball, swish, net, ball bounce,
dribble, sneaker, squeak, buzzer, rubber ball). Best leads:

| Page | Title | Author | License | Contents | Fit |
|---|---|---|---|---|---|
| https://opengameart.org/content/body-hitting-ground | Body Hitting Ground | dklon | CC-BY 3.0 | A towel-wrapped book hitting a floor, several hits (wav 0.9 MB) | ok: a dull thump closer to a ball bounce than today's thwack |
| https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | 75 CC0 breaking / falling / hit sfx | rubberduck | CC0 | 75 phone-recorded hits and falls | ok: might hold a usable bounce |
| https://opengameart.org/content/swishes-sound-pack | Swishes Sound Pack | artisticdude | CC0 | 13 whooshes (wav) | poor-ok: air whooshes, not net |
| https://opengameart.org/content/footsteps-on-different-surfaces | Footsteps on different surfaces | congusbongus | CC-BY 3.0 | Includes "polished floor (gym floor)" steps | ok: gym footsteps/ambience |
| https://opengameart.org/content/super-foley-pack | Super Foley Pack | dklon | CC-BY 3.0 | Raw foley incl. shuffling feet, leather hits (15 MB zip) | ok: sneaker shuffle, leather-ish ball hits |

## Licenses that need the owner's approval

- **CC-BY-SA** (commercial use allowed, but changes must be shared under the same license): LPC character bases and
  most LPC art, e.g. https://opengameart.org/content/football-sprite-based-on-lpc-set (CC-BY-SA 3.0),
  https://opengameart.org/content/lpc-beach-desert (CC-BY-SA 3.0),
  https://opengameart.org/content/topdown-characters (16Pixel, CC-BY-SA 4.0),
  https://opengameart.org/content/8-directional-character-template (14Hertz, CC-BY-SA 3.0, 32x32 twin-stick character, 8 frames),
  https://opengameart.org/content/pixel-art-smoke-puff (CC-BY-SA 4.0),
  https://opengameart.org/content/blue-wave-theory-surf-rock-edited-for-games (IoriBranford, CC-BY-SA 4.0: the
  only real **surf rock** found, with ready-made intro/loop .ogg files 0.4-3.7 MB),
  https://opengameart.org/content/neocrey-miami-soul (CC-BY-SA 3.0).
- **OGA-BY 3.0/4.0** (OpenGameArt's CC-BY variant without the anti-DRM clause; allows commercial use with credit):
  https://opengameart.org/content/lpc-expanded-sit-run-jump-more (LPC 4-direction bodies with run and jump; the
  big zips mix files from many LPC authors, each needs its own license check),
  https://opengameart.org/content/opening-theme-for-soccer-video-games, https://opengameart.org/content/farm-music.
- **GPL only**: https://opengameart.org/content/hip-hop-boss-man-boss-music. Not recommended.

## Gaps and fallbacks

- **Top-down basketball players**: none exist. Fallback: draw our own 32x32 overhead sprite with a script in `tools/`
  (2-4 frame leg swing), one base recolored per team with a palette shader. Or keep the Kenney figures.
- **3/4 basketball players with turn frames**: Pixel Baller is the only basketball pack, front-facing only, 80x140.
  Fallback: Puny Characters or 24x32 Bases (CC0, 4-8 directions) with jerseys painted on by script; less "basketball".
- **Top-down hoop, court lines, crowd**: keep code-drawn (rims, nets and lines are already drawn in `court.gd`); add a
  simple code-drawn crowd strip or use RPG Urban Pack people around the court.
- **Court floors**: covered by tiles above, but Chicago rooftop, Seattle wet court and LA sand need code-drawn
  touches (ledge, puddles/rain, sand texture noise).
- **Swish and bounce**: no real recordings on OpenGameArt. Options: (a) synthesize them with a script, as was done for
  the whistle (filtered noise burst for the net, pitched decaying thump for the bounce); (b) the owner downloads CC0
  basketball recordings from freesound.org (blocked here), we process them.
- **Music styles that are weak here**: New Orleans brass band (only swing/jazz found), surf rock (only the CC-BY-SA
  Blue Wave Theory clips), boom-bap (old-school beats are OK, not true boom-bap), Chicago house (Funky House is beachy
  house). Owner-download option: Kevin MacLeod's incompetech.com catalogue (CC-BY 4.0, genre-searchable incl. jazz,
  blues, folk/bluegrass and rock; not checked from here) or Eric Matyas's soundimage.org (CC-BY-style "free with
  attribution" terms; read them first), both outside OpenGameArt.
