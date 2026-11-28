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
| Phase 7 signing key | The release key needs keytool on a computer (not possible on the tablet). Owner: decide later; ship the web version on itch.io first, the Android app when ready. The team still finishes the Android build (debug APK, release script, ANDROID.md) so it is ready |
| Phase 7 check-in | Icon and cover (van under the ball sunset): keep. Store screenshots: all 5 in order (Memphis dunk, rainy Seattle, trip map, story, New York cage). P7-B1 (second QUIT? tap): not tried on the tablet yet, stays open. Next: a small tuning round before the itch.io upload (owner to say what) |
| Progression plan answers (docs/progression-plan.md) | Shots should go in more often in every mode (P7-T1). Stat points per player after every Road Trip win: each starter gets 1 point for city games 1-2, 2 for the boss game and each New York round (4 per starter per city); the same on every level. Stars per city game and New York round: Easy 1, Normal 2, Hard 3, best kept (72 in all). Stars unlock: a LEGEND level (every game 3 stars), cosmetics (alternate jerseys, special balls, van paint jobs, Quick Game court looks), and extra roster slots at star milestones; a slot drafts any player from a crew you have beaten, bosses included, but only one boss may be in the 3 starters. Replay any beaten city game from the map, opponents raised to the stage reached, stars only (no points). Hold the itch.io upload until this progression phase (Phase 8) is done; 1.0.0 saves must carry over |
| Phase 8 plan answers | 4 extra roster slots at 12, 24, 36 and 48 stars (roster up to 14). A slot drafts any player from a crew beaten on this trip; the pick is final for the trip. Jersey, ball and van paint are picked on a new LOCKER screen from the title (the star ladder too); the new court looks join the Quick Game COURT button. Skip the one-boss-among-starters rule for now (this replaces that part of the row above). Version number for the release: still to ask |
| Phase 8 boss limit | Bring back the one-boss limit: at most one boss among the 3 starters, however he joined (recruited or drafted). Reason: without it the best possible New York lineup is three recruited bosses (about 87 per stat against the final crew's 82), so the city games could not be tuned for both kinds of crew. 1.0.0 saves with more boss starters are repaired when they load |
| Legends (long-term) | A much longer mode whose goal is unlocking legends. Legends are ORIGINAL archetype characters (own names and looks, classic play styles such as the sky-hook center or the crossover king; no real players' names, faces, numbers or trademarks; the owner's reference picture is inspiration only, never an asset). Built as an era tour: four era chapters (Grandfathers, Fathers, Present, New Generation), each with its own courts, rules (twist-style) and legends unlocked through challenge games. Unlocked legends: playable everywhere (Quick Game; draftable into the Road Trip crew, one legend among the starters), mentor your players (a small permanent perk), era matchups in Quick Game, and a Hall of Legends trophy room. Plan now (docs/legends-plan.md); timing decided after Phase 8 |
| Legends plan answers (docs/legends-plan.md) | 6 legends per era, 24 in all. Opens staggered: Chapter 1 after a finished trip (24 stars), later chapters at 36 / 48 / 72 stars or with legend tokens. Grandfathers era first. Challenge games: a mix per legend (hold him under N, beat the fire, stop the move, race, comeback), one-on-one added later. Legends in the Road Trip: drafted through the star roster slots; one legend among the starters, and he may start next to one boss (one legend + one boss allowed). Mentor perks small: about 2 stat points' worth, one per player, a legend trains one player at a time and can switch. Timing still decided after Phase 8 |
| Phase 8 jersey and version (P8-27 / P8-28) | Jersey clash (P8-B7): auto-switch: when the opponent crew's colors are too close to your star jersey, your team wears its normal jersey for that game (AFTER HOURS against black / navy / plum crews, HOME WHITES against grey-white / silver, THROWBACK against orange). Version: keep 1.0.0 for the Phase 8 update (no new number on the title, credits, web ZIP or APK) |
| Phase 9 start (after Phase 8) | Legends is Phase 9, next after Phase 8 (owner, 2026-11-19). Plan first on the board from docs/legends-plan.md, shown to the owner before building |
| Phase 9 answers L1-L8 (docs/legends-plan.md) | L1 a: the six Grandfathers as written (Steeple, Gate, Set Shot, Boxcar, Velvet, Quarterback), names swapped only if the real-name check flags one. L2 a: a different challenge goal per legend, then a finale to 21. L3 b: you play the challenges with your current Road Trip crew and starters (they get easier as the crew grows). L4 a: a LEGENDS button on the title, locked until 24 stars from any games; the Hall from Legends and from CREW & CREDITS. L5 a: OLD SCHOOL era rules (6% slower, long shots -12%, fouls 60%, close shots +8%). L6 b: a small play edge per legend plus one new animation, the hook shot, on the legend sheets. L7 a: a drafted legend is boss-level at the stage reached (cap 95), QA tunes it down if New York on Hard can no longer be lost. L8 a: mentors in Phase 9, one perk each, switch any time from the Hall, Road Trip games only |
| Phase 9 look check and era music | Legend look sample v1 (docs/art/legends_sample_v1.*, Steeple) and the hook shot (docs/art/hook_shot_v1.gif) approved as shown (owner, 2026-11-19); kit colors may still change per legend. Grandfathers era music: D, "Bebop (Chiptune)" by Pro Sensory, CC0 (opengameart.org/content/bebop-chiptune), brought down to the game loudness |
| Phase 9 names and numbers | The six Grandfathers names pass the real-name check, no swap (owner confirmed). Jersey numbers: Steeple 18, Gate 54, Set Shot 9, Boxcar 46, Velvet 19, Quarterback 12 (owner). Legend sheets: the three dark kits (Steeple rust, Velvet mustard, Boxcar brown) get brighter colors that stand out on the OLD GYM wood; portraits follow (owner) |
| Phase 9 mentors and era tuning | Mentors coach your regular players only: a drafted legend has no mentor (owner). A first pairing happens on the tap; only a switch or STOP TRAINING asks to confirm (owner). OLD SCHOOL long shots tuned 0.88 -> 0.80 after P9-17 found the 12% hard to notice (docs/qa/phase9-era.md) |
| Replay level (owner bug report) | Replays get a level picker in the map's replay picker (EASY / NORMAL / HARD, LEGEND once open), opening on the trip's level; a replay plays and records its stars at the picked level; the trip's own level never changes |
| Mentor perk size (after P9-30) | Shrunk to about 2 stat points each (owner): shot perks +1.5% (close shots, threes, contested layups), blocks / dunk reach / pass speed 5% |
| Challenge goals tuned (P9-26) | To keep every challenge winnable with the end-of-trip crew: Steeple hold under 7 (to 15), Gate race to 11 before his crew gets 10, Boxcar 2 stops, Velvet hold under 6 (to 11), Quarterback comeback from 0-2; legends rated lower (challenge average 66, finale 72 + shape). Results per level in docs/qa/phase9-challenges.md. Shown to the owner at the Phase 9 check-in |
| Rebounding (owner) | Offensive rebounds were too many (56% of misses); now about 25% (defense boxes out, only the nearest attacker crashes). Game length won back with a small make-rate nudge to about 9.5 min. A light box-out assist for the human defender when not steering (any stick input takes over) |
| Phase 10 start (owner, 2026-11-21) | "Go on to the next": Phase 10 is Legends Chapter 2, the Fathers, planned on the board first like Phase 9 (open questions to the owner before building) |
| Phase 10 answers F1-F8 (docs/legends-plan.md) | F1 a: the six Fathers as written (Rooftop, Ankles, Midrange, Freight, Eyes Closed, Lockbox), new surnames for Rooftop and Eyes Closed and spread looks (no legend copies one famous player), names and numbers shown to the owner. F2 a: ISO BALL = crossovers beat the defender ~20% more (everyone), dunks ~10% further out, a slightly higher arc. F3 a: Rooftop stop, Ankles race, Midrange fire, Freight hold, Eyes Closed comeback, Lockbox a new "score on him" goal (you score 6+ yourself and win, to 11); finale Rooftop, Midrange, Freight to 21. F4 b: play edges plus one new animation, Midrange's turnaround fadeaway (preview to the owner first). F5 a: six new perks (contested dunks +1.5%, crossovers 5%, inside-arc jumpers +1.5%, 5% harder to strip, passes 5% harder to intercept, steal window 5% wider). F6 a: a step harder than Chapter 1 (Normal ~60-65%, Hard ~40% with the end-of-trip crew). F7 a: opens at 36 stars or 12 tokens. F8 a: Chapter 2 only |
| Phase 10 look check | Fathers look sample v1 (docs/art/legends_fathers_sample_v1.*, Rooftop and Eyes Closed) approved as shown (owner); kit colors may still change per legend so they read on the blacktop. Midrange's turnaround fadeaway (docs/art/fadeaway_v1.gif) approved as shown, with the 1.5 ft slide back in the air (owner) |
| Phase 10 names and numbers | Dorian "Rooftop" Ashcombe #27, Tremaine "Ankles" Pettaway #16, Darnell "Midrange" Kingsley #28, Bartholomew "Freight" Thackeray #48, Keon "Eyes Closed" Pemberton #14, Corwin "Lockbox" Hollister #36 (Corwin replaces Shane: name check). Approved by the owner |
| On fire: bonus | Bigger green zone on the shot meter, stamina doesn't drain, flaming ball trail |
| Phase 10 tuning (after P10-23) | Lockbox keeps the owner's 6 points (P10-23 measured 3; the score goal is meant to be the hardest, met about 17% or less in tests). Eyes Closed starts 0-1 (P10-23). Chapter 1's finale a bit harder: `FINALE_STAGE_AVG` 52 -> 55 (Hard had won 50% of 80 games, aim 35-50) |
| Phase 10 perk sizes (after P10-26) | Owner: raise the three weak Fathers perks to about 2 stat points like the rest: rise_up +2.5% (was 1.5), handle 15% (was 5), blind_pass 15% fewer interceptions (was 5); pull_up, strong_hold, quick_hands stay (docs/qa/phase10-ramp.md) |
| Phase 10 era music | Owner: A, "Headspin" by congusbongus (CC0, OpenGameArt) as `legends_fathers` (docs/audio_preview/LIST.md) |
| Phase 11 start (owner, 2026-11-25) | "Go on to the next" after Phase 10: Phase 11 is Legends Chapter 3, the Present, planned on the board first like Phases 9-10 (open questions to the owner before building) |
| Phase 11 answers P1-P8 (docs/legends-plan.md) | P1 a: the six Present types with the name-check fixes (Calloway "Deep End" Whitlock, no beard; Theo "Toolbox" Lindqvist; Ozren "Stretch" Halvorsen with short hair; Ellery "Switch" Achterberg; Bodie "Skylight" Castellano; Bastien "Zigzag" Moreau), new names checked again, numbers and kits shown at the look check. P2 a: SPACE THE FLOOR = shots beyond the arc +8%, off-ball players 2 ft wider, a jumper right after a crossover or spin +10% (everyone). P3 a: Deep End fire (to 15), Toolbox comeback from 0-1 (to 15), Stretch race 11 before 10, Switch score 5 yourself and win (to 11), Skylight 2 stops (to 15), Zigzag hold under 6 (to 11); finale Deep End, Toolbox, Skylight to 21. P4 c: the play edges plus **both** new animations, Deep End's step-back and Zigzag's Euro-step (previews to the owner first). P5 a: six new perks (about 2 stat points each). P6 a: a step harder than Chapter 2 (Normal about 55-60%, Hard about 35%, the finale a bit harder). P7 a: 48 stars or 30 tokens, no Chapter 2 finale needed. P8 b: era teams in Quick Game (GRANDFATHERS, FATHERS, PRESENT on YOUR TEAM / OPPONENT once 3 of an era are unlocked; their 3 best, stats averaged to 50), and (owner, follow-up) each era court with its era rules joins the Quick Game COURT list once that era's team is open |
| Phase 11 names (after P11-02) | Owner: Sigurd "Stretch" Halvorsen (was Ozren; dark hair, never blond, medium build); Skylight keeps Castellano (no basketball match); Deep End keeps his thin mustache; Whitlock and "Stretch" kept. The six: Calloway "Deep End" Whitlock, Theo "Toolbox" Lindqvist, Sigurd "Stretch" Halvorsen, Ellery "Switch" Achterberg, Bodie "Skylight" Castellano, Bastien "Zigzag" Moreau; numbers at the look check |
| Phase 11 era music | Owner: D, "Techno DRIVE!!!" (v2.5, the chiptune version) by Centurion_of_war (CC-BY 4.0, OpenGameArt) as `legends_present`; credit title "Techno drive" as the author asks, and tell the author it is used (a request, not a license term) (docs/audio_preview/LIST.md "Legends: Present") |
| Phase 11 era teams (Q11-E1, Q11-E2) | Owner: an era team in Quick Game is its chapter's finale three (Grandfathers: Steeple, Velvet, Quarterback; Fathers: Rooftop, Midrange, Freight; Present: Deep End, Toolbox, Skylight), stats shifted to average 50; legends keep their signature moves in Quick Game (perks never apply); an era team opens once its own three (the finale three) are unlocked in Legends (owner, after P11-32) |
| Phase 11 look check | Owner: Deep End and Toolbox looks approved as shown (docs/art/legends_present_sample_v1.*); the step-back and Euro-step approved as shown (docs/art/stepback_v1.gif, eurostep_v1.gif: 2.0 ft slide, 1.5 ft sway); era color **teal + coral** for the whole era (court, card frame, pins, era kits; the magenta first guess is dropped); the Present court is named **BIG STAGE**. Numbers (coordinator, from the passing list): Deep End 26, Toolbox 38, Stretch 49, Switch 29, Skylight 52, Zigzag 58 |
| Phase 11 Zigzag first name (after P11-27) | Owner: rename Zigzag (Lucien clashes with the New Orleans recruit Lucien Batiste); the team picks a first name that passes the name check and shows it at the check-in. Applied: **Bastien** "Zigzag" Moreau (runner-up Anatole) |
| Phase 11 spacing (after P11-21) | Owner: keep SPACE THE FLOOR's 2 ft spacing (off-ball spots move 2 ft straight out from the hoop, kept inside the lines) although rim shots fall about 29% (34 to 24 a game) and offensive rebounds dip a little under 25%: the era should feel like a shooting era; pull-up numbers stay (PULLUP_CPU_CHANCE 0.5, PULLUP_WINDOW 1.0; docs/qa/phase11-era.md) |
| Phase 11 tuning (after P11-23) | Owner: accept Chapter 3 as measured (end-of-trip crew: six challenges Normal 50%, Hard 40%; finale at `finale_stage_avg` 63: Normal 53%, Hard 33%); Switch keeps `min` 5 (met ~15%, the hardest on purpose like Lockbox); no per-level offset (docs/qa/phase11-challenges.md) |
| Phase 11 teal (after P11-28) | Owner: the Present's `ui_color` goes darker, #0a7385 (P11-B2), so its LEGEND tags and draft band read apart from the Fathers' mint; also darkens its Quick Game team button. The era court's paint keeps its teal |
| Phase 11 era team balance (after P11-36) | Owner: leave both as measured: the Present is the strongest Quick Game team (~62% vs the crews on Hard), a reward for the last era; the Grandfathers stay weak on their own OLD GYM (~38%, the OLD SCHOOL twist helps their opponents), no Quick Game home edge (docs/qa/phase11-quick-eras.md) |
| Phase 11 perk sizes (after P11-26) | Owner: all six Present perks resized to about 2 stat points each: `off_dribble` +2.5%, `extra_pass` +1%, `catch_shoot` +1%, `contest` 0.5% (was 3x a perk at 1.5%), `board_work` reach x1.15, `side_step` layup blocks x0.80 (was 1.5% / 1.5% / 1.5% / 1.5% / 1.05 / 0.95; docs/qa/phase11-ramp.md) |
| Phase 11 check-in | Owner: likes how everything looks. Midrange's skin is brown (the portrait is right; his player sheet and card go brown). Rooftop's cradle dunk gets its own look (P11-10, preview first). The Techno drive loop point: the owner still has to listen. Next: Chapter 4, the New Generation (Phase 12) |
| Phase 12 answers Q1-Q8 | Owner: Q1 make the chapter more futuristic: about half the legends (3 of 6) have cybernetic parts, the other 3 are all natural; the cybernetics are visible parts tied to each one's signature move, which keeps a small play edge like every legend (the six types stay, names and looks redone with that in mind, checked by the hard rule). Q2 a FAST BREAK (speed +5%, stamina back +15%, dead-ball pauses -40%, shots in the first 5 s after getting the ball +10%, everyone). Q3 a a step harder than Chapter 3 (Normal ~45%, Hard ~30-35%, the finale a bit harder). Q4 a one new animation: Glitch's combo dribble (preview first). Q5 a six new perks, about 2 stat points each. Q6 a gate 72 stars or 48 tokens, no Chapter 3 finale needed. Q7 a the 4th era team and its court in Quick Game like the others. Q8 a an ending: a closing scene with a legend from each era, LEGENDS COMPLETE on the timeline, a full Hall banner |
| Phase 12 roster (after the cyber redo) | Owner: approves all six (legends-plan 12.9): cyber Tavian "Overclock" Brightwell #17 (glowing leg braces), Cosimo "Glitch" Draycott #25 (chrome forearm), Kasimir "Firewall" Oyelaran #51 (lime visor); natural Calder "Long Shadow" Ostrander #56, Silvan "Updraft" Ingleby #57, Ezra "Halfcourt" Tregarth #39. R2 finale and era team: Overclock, Updraft, Halfcourt. R3 no CYBER / NATURAL tag on cards. R4 a steady glow (no pulse). P12-02's final name check still runs before art |
| Phase 12 Halfcourt's first name (after P12-02) | Owner: Emrys (Emrys "Halfcourt" Tregarth), not Ezra (2 letters from Earl, the Hometown boss: our own first-name rule) |
| Phase 12 look check 1 (after P12-05) | Owner: approves the look sample `docs/art/legends_next_sample_v1.*` as is (Overclock's chrome leg braces with a lime line, Glitch's chrome right forearm with violet seams, Firewall's thin lime visor; Long Shadow's locs and bead tie, Updraft's mohawk and taped fingers, Halfcourt's freckles, curls and headband; glow and chrome kept in every recolor). Era colors lime + violet on near-black for all six kits. Era music: "Escalate" by congusbongus (CC-BY 3.0, OpenGameArt; `docs/audio_preview/next_a_escalate.ogg`; check the loop for grit at the ceiling) |
| Phase 12 combo dribble (after P12-05b) | Owner: approves Glitch's combo `docs/art/combo_v1.gif` as is (between the legs, behind the back, back to the chrome hand; the crossover's timing). It ends in his starting hand, so the game keeps his ball hand after it |
| Phase 12 court (after P12-06) | Owner: approves the court `era_next` as is and its name NEON DOME (dark glass floor, lime lines, violet key, black dome with violet light rings, chrome rail; `docs/art/era_next_preview.png`) |
| Phase 12 portraits (after P12-15) | Owner: approves the twelve portraits `docs/art/legends_next_portraits.png` as is; Overclock's braces shown by their lime glow up the tank (no lower framing) |
| Phase 12 UI art (after P12-07) | Owner: approves the Chapter 4 timeline panel, pins and card frame as shown; Chapter 4's `ui_color` goes darker, #466e14 (tags, draft row, Quick Game team button readable), the court and kits keep their bright lime |
| Phase 12 FAST BREAK (after P12-21) | Owner: the middle step: `speed_mult` 1.08 (was 1.05) and `break_mult` 1.20 (was 1.10); `stamina_refill_mult` 1.15 and `dead_ball_mult` 0.6 kept. The effect stays subtle (early shots about +2 points over later ones in 40 games, `docs/qa/phase12-era.md`); not the tester's 1.30 |
| Phase 12 challenges (after P12-23) | Owner: takes all of the tester's changes: `next` row `challenge_avg` 74 (was 75; `mate_drop` 14 and `finale_stage_avg` 66 kept), Long Shadow comeback from 0-1 (was 0-2) and his rim run `RIM_RUN_SPEED_MULT` 1.06 (was 1.12), Halfcourt `cool_misses` 3 (was 2), Firewall `score` `min` 4 (was 5; about 14% met). Measured together: Normal about 45%, Hard about 33%, the finale 45% / 30% (`docs/qa/phase12-challenges.md`). The story lines follow (0-1, three misses, four points) |
| Phase 12 perk sizes (after P12-26) | Owner: applies all four: `fresh_legs` 0.93 (was 0.90), `pump_fake` 1.20 (was 1.15), `second_chance` 0.06 (was 0.025), `closeout` 1.15 (was 1.10); `head_start` 1.04 and `early_shot` 0.010 kept. Pump fake and second chance stay under 2 stat points (they seldom come up); their hooks stay as built. The Hard bound with a New Generation legend is 41% (Phase 11 44%), no change (`docs/qa/phase12-ramp.md`) |
| Phase 12 era team balance (after P12-36) | Owner: keep everything as measured (`docs/qa/phase12-quick-eras.md`: the New Generation about 57% in Quick Game, the Grandfathers weakest on OLD GYM); Firewall's swat stays x1.5 (a sure block on Hard) |

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

**Phase 8: progression** (before the first itch.io upload). Stat points for each starter after every win, stars per
city game and New York round, star rewards (extra roster slots that draft from beaten crews, cosmetics, a LEGEND
level), replays of beaten city games from the map, the ramp retuned, 1.0.0 saves carried over. Plan:
`docs/progression-plan.md`.

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
- Phase 8 (progression), before work starts: `docs/progression-plan.md` part 9 Q1-Q4: roster slot milestones and the
  maximum roster size, which players a slot can draft (this trip's beaten crews or any ever beaten; releasing),
  where jerseys, balls and van paints are picked (a LOCKER screen, Settings, or where each is used), and the version
  number of the first public release (answered: keep 1.0.0).
- Phase 9 (Legends, Chapter 1), before and during the build: `docs/legends-plan.md` "Phase 9 open questions" L1-L8:
  the six Grandfathers legends, the challenge per legend, who plays the challenge games and how hard, where the mode
  is entered and what opens it, the OLD SCHOOL era rules, signature moves, a drafted legend's strength, mentor details.
  Each names the board tasks it blocks.
- Phase 10 (Legends, Chapter 2, the Fathers), before the build past wave 1: `docs/legends-plan.md` "Phase 10 open
  questions" F1-F8: the six Fathers legends, the ISO BALL era rules, the challenge per legend, signature moves and a
  new animation, the Fathers perks, how hard Chapter 2 is, what opens it, and anything beyond Chapter 2. Each names the
  board tasks it blocks.
- (Answered 2026-11-25, see "Phase 11 answers P1-P8") Phase 11 (Legends, Chapter 3, the Present), before the build past wave 1: `docs/legends-plan.md` "Phase 11 open
  questions" P1-P8: the six Present legends after the name and look check, the SPACE THE FLOOR era rules, the challenge
  per legend and the finale, signature moves and a new animation, the Present perks, how hard Chapter 3 is, what opens
  it, and anything beyond Chapter 3. Each names the board tasks it blocks.
- (Answered 2026-11-27, see "Phase 12 answers Q1-Q8") Phase 12 (Legends, Chapter 4, the New Generation), before the build past wave 1: `docs/legends-plan.md` "Phase 12
  open questions" Q1-Q8: the six New Generation legends after the name check (the first draft's seven-foot guard,
  three surnames and a nickname need fixes), the era rules for "the fastest pace", the challenges and how hard
  Chapter 4 is, new animations, the perks, the gate (72 stars = every star, so is 48 tokens the real path?), the 4th
  era team and court in Quick Game, and an ending for the mode. Each names the board tasks it blocks.
- Phase 12 roster (draft for the owner; the lead's proposal after Q1, NOT an owner answer; `docs/legends-plan.md`
  12.9, shown at owner check 1 with the look sample): cyber Tavian "Overclock" Brightwell (17, speedster point guard,
  glowing leg braces -> top gear), Cosimo "Glitch" Draycott (25, trick handler, chrome forearm -> hesitation and the
  combo dribble), Kasimir "Firewall" Oyelaran (51, switches onto everyone, a visor -> swat); natural Calder "Long
  Shadow" Ostrander (56, rim-running seven-footer), Silvan "Updraft" Ingleby (57, highest leaper; "Pogo" dropped: a
  comic-strip character and a game-site brand), Ezra "Halfcourt" Tregarth (39, range shooter). "Hyperdrive" dropped
  (a shoe-line prefix). A part is look only, no bigger edge; static glow (lime, violet) and a chrome ramp in the
  palettes. Challenges and perks as Q3 a / Q5 a. For the owner to pick: R1 the names and the cyber three, R2 the
  finale and era team three (suggested Overclock, Updraft, Halfcourt; or Glitch in for Overclock), R3 a CYBER /
  NATURAL card tag or none (suggested none), R4 static glow (suggested) or a pulse later. Era colors lime + violet
  with chrome on the parts, court NEON DOME, fast electro: first guesses kept.
- From the Phase 10 check-in, still open: Rooftop's cradle dunk is drawn as a windmill; keep it, or give it its own look
  (board P11-10)?
