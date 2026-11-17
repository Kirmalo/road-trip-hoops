# Road Trip Hoops: Vision

This is the shared design doc for everyone working on the game, people and agents. If a design question isn't
answered here, ask the owner and record the answer in this file. Don't guess.

## Pitch
An arcade-lite 3v3 streetball game in pixel art. A small-town crew of underdogs piles into a beat-up van and drives
across America, beating local crews city by city, to reach a big streetball tournament. It's played by touch on a
tablet with a joystick and two buttons.

## Pillars
1. **Every possession is exciting.** Turbo, dunks, alley-oops, blocks and steals, with strong feedback: sound, shake,
   effects and popups.
2. **Skill over dice.** Offense and defense reward timing and positioning, not random rolls.
3. **The trip is the reason to keep playing.** Each city looks, sounds and plays differently, and your crew grows.
4. **Touch first, easy to learn.** Joystick plus two buttons does everything. No hidden inputs.

## Decisions so far
| Topic | Decision |
|---|---|
| Tone | Arcade-lite: real rules, exaggerated moves, fast pace |
| Audience | Public release; free on itch.io first, Google Play decided later |
| Main mode | Road Trip campaign |
| Game format | Full court (as built now), first to 21 |
| Scoring | Streetball: 1 point inside the arc, 2 beyond |
| Turbo | Pull the thumb past the joystick ring (to a faint outer ring) to sprint; a normal full push never sprints (owner, Phase 1 check-in: sprinting was too easy to trigger). Drains a stamina bar, refills when you ease off |
| Offense moves | Auto-dunk or layup on Shoot near the rim; alley-oop (Pass to a teammate cutting to the rim); pump fake (very short tap of Shoot); crossover or spin (quick flick of the stick while dribbling) |
| Defense | Skill-based: steals depend on timing and the handler's exposure, blocks on jump timing, close guarding slows a driver |
| Teammates | Smart automatic movement; the human can call for the ball or switch player |
| Rules to add | Fouls and free throws, out of bounds, switching sides at the midpoint of the game (first team to 11) |
| Difficulty | Easy early cities, harder later ones, plus an Easy / Normal / Hard setting |
| Trip size | About 8 cities x 3 games, roughly 2-3 hours |
| Story | Underdog story with a few short dialogue scenes; final city is the tournament |
| Cities | Real city names. No real courts, teams, players, logos or brands |
| Each city has | A unique pixel-art court, a gameplay twist, music in a local style |
| Your crew | 3 named underdogs to start; recruit a player from each city you beat onto a bench; choose 3 starters before each game; players earn stat points |
| Art | Pixel art from free CC0 packs, recolored and assembled by agents |
| Music and sound | CC0 or royalty-free tracks, a style per city; CC0 sound effects |
| Check-ins | The owner plays a ZIP build on the tablet after each phase |
| Dunk or layup | Decided by distance and speed: very close and moving fast (or on turbo) dunks, otherwise a layup. Player ratings may add to this in the campaign |
| Turbo with the ball | Slightly slower than without the ball; a jump shot right after sprinting is less accurate (dunks and layups aren't affected) |
| On fire: streak | One player, 3 makes in a row (dunks and layups count). CPU players can catch fire. The first miss or block shows "He's cooling down." and a make resets it; a second miss or block ends it. The other team scoring does not end it (changed after test games showed fire lasting 0-2 shots) |
| Phase 1 check-in | Dunks and layups feel good as is. CPU should learn pull-up jump shots (Phase 2). Sound works on the tablet; dribble raised to -8 dB (audible but soft) |
| Dribble moves | Crossover only for now (quick flick while dribbling); spin maybe later |
| Pump fake | Short tap of SHOOT, only away from the rim; near the rim SHOOT always dunks or lays up at once |
| Defense button | Orange picks STEAL or BLOCK automatically (BLOCK when your man shoots or is near the rim and you're close) |
| Call for the ball | Blue becomes CALL on offense without the ball; teammate passes when the lane is clear (~1.5 s); a lob if you're cutting |
| Who you control on offense | When you pass, you take over the receiver. When a teammate gets the ball another way (rebound, steal, inbound, CPU pass) he plays it himself and you press CALL to get it (owner-approved in Phase 2) |
| Alley-oops | Automatic: a pass to a teammate cutting to the rim is a lob he dunks in the air |
| Steals and blocks | Timing based and dependent on each player's attributes (steal and block ratings, 0-100). Player attributes start here and grow in the campaign. No stumble after a missed steal: instead a defender stands still while attempting a steal (hit or miss), so poking has a cost |
| Phase 2 check-in | Crossover feels about right. Steals and blocks both too hard: make them easier. CPU too hard, mainly because it's hard to stay in front of the ball handler: add a defensive assist (your defender slides to stay between his man and the basket while you steer roughly toward him; you still steer). PASS/SHOOT covering the bottom-right corner: leave it. Tuning round P2.5 before Phase 3. After P2.5 the owner said defense is "much better now" |
| Game end | First to 21 (21-20 counts, no win-by-2). No game clock or quarters; the 24 s shot clock stays |
| Game length | Quick Game plays to 21. On the Road Trip every city's games go to 11, 15 and 21 (boss game); tournament games to 21 (Phase 5 answer) |
| Fouls | Bad timing only: a badly timed block jump that hits the shooter, or poking at a ball the handler shields with his body (about 3-6 per game) |
| Free throws | Fouled inside the arc: 1 free throw; beyond: 2; and-one: 1 extra. Reaching foul: ball from the sideline. A missed last free throw is a live rebound |
| Out of bounds | Simple: only a loose ball crossing a line is out; the ball handler can't step out by accident |
| Easy / Normal | Today's CPU = Hard. Easy and Normal make the CPU less sharp, not slower: worse shooting, slower reactions, worse steal/block timing, more bites on fakes, less help defense |
| Picking the level | Big EASY / NORMAL / HARD buttons on a start panel and after each game; the choice is remembered |
| Phase 3 check-in | Difficulty levels well spaced. Keep games to 21 in the test build. Keep the long rim bounces that go out of bounds. Crossovers beating the assisted defender: fine on Hard, but on Easy/Normal a CPU crossover beats you less often (difficulty knob cross_beat_human: Hard 1.0, Normal 0.75, Easy 0.5) |
| Camera view | Angled 3/4 view (court seen at an angle from the sideline, upright players, visible backboards, like classic arcade basketball). The game simulation stays 2D top-down underneath; only drawing and joystick mapping change. Decided before Phase 4 art (owner, Phase 4 start) |
| Player sprites | Our own original 3/4-view players, drawn by the team (scripts in tools/), designed with the owner step by step and improved over time |
| Asset licenses (Phase 4) | CC0 and CC-BY only; no share-alike (CC-BY-SA, OGA-BY) art or music |
| Swish and bounce | Synthesized by script (like the referee whistle), replacing the stand-ins |
| Player art direction | Original characters in an angled 3/4 view, inspired by the 90s arcade fighting-game look (owner: "similar to the Street Fighter games"): muscular athletic builds, bold dark outlines, rich shading (3-4 shades per color, light from the upper left), dynamic poses, expressive faces. Never copy characters, costumes or art from any existing game. Arcade athletic proportions (head about 1/4 of height, long limbs), base size about 24x40 px drawn 2x. Streetball mix of outfits with a shared team color theme plus a soft team-colored ring under each player. 8 directions (5 drawn, 3 mirrored). Medium animation: run 6, dribble 4, shoot 4, dunk 5, block jump 3, celebrate 4, idle 2. Step 1: a style sample sheet for owner review. Owner approved style sample v1 (docs/art/style_sample_v1.png, tools/art/draw_style_sample.py): "I like how it looks" |
| Camera framing (3/4) | Follows the ball left and right, about two thirds of the court length on screen, both sidelines always visible. The camera stays on the same sideline at the side switch (BLUE attacks left after 11) |
| Court backgrounds | Scenery behind the far sideline that fits the court: bleachers and a crowd in the gym, a fence and a street behind the blacktop |
| Trying courts | A COURT button on the start and game-over panels switches Gym and Blacktop until the Road Trip exists; the music follows the court |
| Music | Menu music on the panels, the court's track softly during play, MUSIC ON/OFF button on the panels (remembered) |
| Phase 4 check-in | Camera angle and zoom feel right; runs smoothly on the tablet; keep the camera following the ball on long passes; players, courts and the new swish/bounce are good. Music: wrong style; owner wants **upbeat chiptune** (retro 16-bit synth, high energy) |
| Music style | Upbeat chiptune for all music (replaces the earlier per-city local styles). Each city's track may still lean toward its city's flavor in chiptune form where good CC0/CC-BY tracks exist |
| Campaign: city rule | Each city has ONE local crew played 3 times, getting stronger: game 1 = 1 good + 2 average players (for that point of the trip), game 2 = 2 good + 1 average, game 3 = 2 good + the crew's boss. Win all 3 to move on (owner, Phase 5 design) |
| Campaign: losing | Just retry the game, no penalty |
| Title screen | Road Trip (start/continue), Quick Game (today's single game with level and court), Settings (music, sound volume, default level, more in Phase 7), Crew / Credits (your crew and stats; art and music credits) |
| Pause screen | A pause button in a top corner during play. Resume / Restart / Quit (to the title or the trip map), music on/off and sound volume, current score and a few game stats for both teams |
| Recruiting | After beating a city's crew, pick ONE of its 3 (either good player or the boss) to join your bench |
| Stat growth | Wins earn stat points; after each city you spend them on Speed, Shooting, Finishing, Defense (steal/block), Stamina for any player |
| Roster | Your 3 underdogs plus up to one recruit per city (bench grows to about 10); before each game pick 3 starters on a lineup screen |
| Starting crew | The team proposes 3 original underdogs (names, looks, personalities, hometown backstory) for the owner to approve or tweak |
| Trip map | Pixel-art USA map with the 8 cities as pins; the van drives along the road; beaten cities get a trophy marker |
| Story scenes | Fighting-game style: big pixel portraits + text box, tap to advance; before and after each city plus a few key moments |
| Saving | Auto-save after every game; one trip at a time; "New trip" asks to confirm |
| Finale | New York tournament: a short knockout bracket (quarterfinal, semifinal, final) against the toughest crews; the final against the champions with a special boss; big ending scene |
| Phase 5 plan answers | Starting crew: Deuce Carter (shooting wing, leader), Jojo Reyes (quick point guard), Tobias "Tank" Lind (big man). Crew "Cornfield Kings", van "The Biscuit". Tiers: average = trip stage (~40 to ~70), good +12 in two specialties, boss +20 at everything. EASY/NORMAL/HARD picked at trip start, changeable. 2 stat points per win, +3 each, cap 90. Story: arrival + after-win scene per city, plus trip start, first loss, before the final, ending. Fixed route, GO, no replays. Every city: game 1 to 11, game 2 to 15, boss game to 21. Tournament: 3 rounds all to 21, a loss replays the round. Quick Game unchanged. Pause button top-right with RESUME, RESTART, QUIT, music, volume, score and stats. Your crew in blue and gold, city crews in their own colors with a red ring, recruits switch to your colors, crew names in the top bar |
| Portrait style | Owner on sample v1: higher quality, a drawn comic-book style (inked outlines, comic shading), still original characters. Map v1 approved as is. Owner approved portrait sample v2 (comic style, docs/art/portraits_sample_v2.png, tools/art/comic.py) after the neck seam fix: draw every story character in it |
| Phase 5 check-in | City games: leave the ramp as is (the better players swapped in are enough; difficulty grows city to city). Campaign difficulty on the owner's level: about right. Screens between games: good, keep the style. Start Phase 6, and also spend time on animations: the owner wants the animations to be one of the highlights of the game (e.g. today's dribble is low quality and the legs don't move while dribbling) |
| Phase 6 design: animation | Animations are a highlight of the game. Bigger, more detailed player sprites, a bit bigger on screen (about 100 px tall on the 720 px screen, today about 80), with many more frames. Upgrade all of them: dribbling (standing and a real running dribble with the legs moving, the ball in time with the hand, crossovers), dunks and layups (several dunk styles, jump, hang, rim grab), shooting and passing (gather, release, follow-through; chest, bounce, lob), defense and reactions (slide, steal swipe, block swat, falling on a crossover, celebrations). Plus motion effects: squash and stretch on jumps and landings, dust on hard cuts, a hang at the top of a dunk, a camera punch on big dunks. A sample first (one player: run, running dribble, a dunk, as a moving preview) for the owner to approve before all players are redrawn. Done side by side with the city work |
| Phase 6 design: cities | Keep the draft list and order: Hometown, Chicago, Memphis, New Orleans, Denver, Seattle, Los Angeles, New York. Twists noticeable but fair: you feel them and adjust (e.g. sand about 10% slower, wind bends a long shot a little), shown with a banner and effects, the same for both teams |
| Phase 6 plan answers | Twists as proposed (Chicago wind, Memphis full crowd with an 18 s shot clock, New Orleans humid, Denver thin air, Seattle wet court, LA sand), New York a fenced cage. New crews: Memphis Riverside Soul, New Orleans Bayou Brass, Denver Switchbacks, Seattle Puddle Jumpers, LA Boardwalk Bombers (Subway Sparks renamed). Story: light comedy with heart. Music: listening list first. 4 dunk styles (one-hand, two-hand, tomahawk, windmill). Motion medium (dunk hang, rim hang, camera punch on big dunks, ankle-breaker falls). Download 15-20 MB is fine. Trip length kept (11/15/21, about 3.5 h). Quick Game: every city court with its twist, unlocked once you beat that city's boss on the Road Trip. Animation sample v1 approved, with the dribbling arm made readable and the running-dribble ball pushed a bit to the side |
| Phase 6 music picks | Memphis "New Blue Shoes" (congusbongus, CC-BY 4.0), New Orleans "Swingshot" (Haley Halcyon, CC0), Denver "Lasso Lady" (congusbongus, CC0), Seattle "My Friends Will Cry" (Christovix, CC-BY 3.0, credit "Music by Christovix Games"), Los Angeles "Happy Ukelele Island Surfing Theme" (Tarush Singhal, CC0); listening list in docs/audio_preview/LIST.md |
| Phase 6 court details | New York cage: the near-sideline fence about 2 ft tall (lowered from 3.5). Hometown driveway: barn-red court lines on the light concrete |
| Phase 6 animation preview | Owner on docs/art/players_v3_moves.gif (the 3 underdogs, every animation): looks good. Redraw every player in this style |
| Phase 6 download size | Owner: about 31 MB for the web download is fine (all the new animation frames kept; only the first load is slower) |
| Phase 6 check-in | New players and moves: good as is (dust, bounce passes, ankle-breakers kept). Twists and late-trip difficulty: all good. Recruit lines kept. Download 30.8 MB fine. Tune Phase 6 before Phase 7: (1) camera closer again (undo the 5% zoom-out that came with the bigger players); (2) a FULL SCREEN option in Settings and on the pause panel, remembered; (3) Quick Game team pick on both sides: your team and the opponent, from the Cornfield Kings plus every crew you have beaten on the Road Trip (unlocked for good, like the courts) |
| Phase 6 tuning check-in | Camera at 1.72 (closer, small depth slide on 16:9): good now. Quick Game crews play their road-trip style (inside/outside etc.), stats stay even (each player averages 50). Start Phase 7 |
| Phase 7 design | Release on itch.io: the web version plus a downloadable Android APK on the same page; no Google Play for now. Price: pay what you want (free with an optional tip). How to Play: picture pages from the title (controls, flicks, steals, blocks, dunks), no playable tutorial. The owner uploads: the team builds the release files (web ZIP, APK signed with a key the owner creates), writes step-by-step upload instructions and the store page text and screenshots |
| Phase 7 plan answers | App name "Road Trip Hoops", Android package id io.github.kirmalo.roadtriphoops, version 1.0.0 (code 1), itch tagline "Drive your underdog crew across America and win the 3v3 streetball tournament in New York." LEFT-HANDED switch and MUSIC volume slider in Settings only (pause panel unchanged). The itch page doesn't link the source; GitHub Pages stays as the owner's test build. The owner makes the release signing key (exact steps from the team, two backups, never in the repo) |
| On fire: bonus | Bigger green zone on the shot meter, stamina doesn't drain, flaming ball trail |

## Technical constraints
- Godot 4.3+ (GDScript), GL Compatibility renderer, 1280x720 landscape. See `CLAUDE.md` for code conventions.
- The owner has no Git on the tablet: they download the repo as a ZIP and re-import it. Every commit on the main
  branch must open and run in the Godot Android editor as is.
- Keep the scene count low. The game is built in code; data (cities, players) should live in plain GDScript
  dictionaries or JSON so it's easy to edit on the tablet.
- **Asset licensing:** only CC0, or licenses that allow commercial redistribution (and say exactly that). Record every
  asset in `CREDITS.md`: name, author, source URL, license. If the license is unclear, don't use the asset.
- Fix the in-game sprite sizes before the art phase (proposed: players drawn at 32x32 source pixels, scaled 2x), so
  gameplay work doesn't depend on the final art.

## Starting city list (draft, open to change)
Each twist has to be readable at a glance and fair. The difficulty ramp goes top to bottom.

| # | City | Court | Twist | Music style |
|---|---|---|---|---|
| 1 | Hometown (small town, Indiana) | Barn driveway hoop | None (tutorial city) | Acoustic / Americana |
| 2 | Chicago | Lakefront rooftop | Wind pushes long shots and lobs | Chicago blues / house |
| 3 | Memphis | Old-school indoor gym | Full crowd: louder, faster game | Soul / blues |
| 4 | New Orleans | Bayou blacktop | Humid: stamina refills more slowly | Brass band jazz |
| 5 | Denver | Mountain park court | Thin air: the ball floats more, longer range, less stamina | Folk / bluegrass |
| 6 | Seattle | Rainy park | Wet court: players slide on hard cuts | Grunge / indie rock |
| 7 | Los Angeles | Beach court | Sand: everyone is slower, turbo matters more | Surf rock / West Coast hip-hop |
| 8 | New York City | Fenced cage court (tournament) | Tight sidelines, best crews, finals | Boom-bap hip-hop |

## Roadmap
Each phase ends with a playable build the owner tests on the tablet before the next phase starts.

**Phase 1: feel.** Turbo with a stamina bar (human and CPU). Auto-dunk or layup near the rim, with a jump
animation and contest check. "On fire" after 3 makes in a row. Feedback effects: CC0 sound effects (swish, rim,
bounce, crowd, whistle), screen shake on dunks and blocks, a net animation, bigger score popups, a ball trail when on fire.

**Phase 2: moves.** Crossover or spin (flick), pump fake (short tap), alley-oop (pass to a cutter), and call for the
ball. Skill-based steals and blocks; close guarding slows the driver. Retune the CPU so it uses and defends these moves.

**Phase 3: rules and format.** First to 21 with 1s and 2s. Switch sides at 11. Fouls and free throws (reusing the shot
meter), out of bounds, Easy / Normal / Hard. Check game length: if full-court games to 21 run past about 8 minutes,
propose a fix (e.g. a shorter target in early cities).

**Phase 4: 3/4 view, pixel art and audio.** First switch the camera to the angled 3/4 view (court drawn with depth, depth-sorted upright sprites, new hoops with backboards, joystick mapped to the view). Replace the Kenney sprites with CC0 pixel art: players (team colors through recolor or
a palette shader), ball, courts, effects. Court art is set per city by data. Music player with a track per city. Fill in
`CREDITS.md`.

**Phase 5: campaign framework.** Title screen, trip map, city data (court, twist, music, opponent ratings), 3 games per
city, recruiting, bench and starter choice, stat points, save and load (`user://`), short dialogue scenes.

**Phase 6: content.** All 8 cities with their courts, twists, opponents, music and story text. Balance the difficulty ramp.

**Phase 7: release.** Settings (volume, difficulty, left-handed layout), a How to Play screen, an itch.io HTML5
export and an Android export, store page text and screenshots.

## Open questions
- Are full-court games to 21 too long? Answer from data in Phase 3.
- Can this environment download from the asset sites (OpenGameArt, itch.io, Kenney)? Check at the start of Phase 1.
  If blocked, the owner allows the hosts or downloads the packs themselves.
- Names and personalities of the 3 starting underdogs, and the name of the tournament.
- Opponent crews: answered in Phase 5 design: each city has one crew with good players and a boss.
- GAME POINT in the top bar: show it at 20 (a 1 wins; the current build) or already at 19 (a 2 also wins)?
- Fouled shots: today a fouled layup or dunk goes in as often as an unfouled one, so most shooting fouls are
  and-ones (about 60%; real basketball is nearer 25%). Should a foul make the shot miss more often?
- Side switch after a free throw that is missed: when the free throw brings a team to 11 and then the last one misses,
  (a) live rebound as usual, and the switch waits for the next dead ball (a possession or more later), or (b) no
  rebound: SWITCH SIDES right away, the defense gets the ball? (`rules.SWITCH_SKIPS_FT_REBOUND`; rare.)
- Out of bounds is very rare on its own (about 0.15 per game). Phase 3 added rare hard bounces off the back or side
  of the rim (about 2 per game go out, almost all over the baseline, so the defense gets the ball). Keep them,
  make them rarer, or remove them? (`ball.RIM_LONG_CHANCE`, `ball.RIM_WIDE_CHANCE`.)
