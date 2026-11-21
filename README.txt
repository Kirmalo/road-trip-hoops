ROAD TRIP HOOPS - 3v3 full court streetball (version 1.0.0)

Three underdogs from a small town in Indiana load up their van and drive across the USA to a streetball tournament
in New York. Beat the local crew in every city, sign its best players, and win the cage in New York. Top-down 3v3
full court basketball, first to 21, made for touch: a joystick and two buttons.
Made with Godot 4 (GDScript). The version shows on the title screen (bottom right) and on CREW & CREDITS.

=====================================================================================================================
PART 1: FOR PLAYERS
=====================================================================================================================

WHERE TO PLAY
- In the browser: open the game's itch.io page (or the test build at https://kirmalo.github.io/road-trip-hoops/) in
  Chrome. Tap once to start (browsers keep sound off until you touch the screen). On a tablet, Chrome menu > Add to
  Home screen gives you an app-style icon. If an update doesn't show, pull down to refresh.
- On Android: download the APK from the itch.io page and open it. Android asks once to allow installs from your
  browser or file app ("install unknown apps"); allow it, then tap Install. The game runs landscape and full screen.
- In the Godot editor: see PART 2.

HOW TO PLAY (THE SHORT VERSION)
The title screen has a HOW TO PLAY button: ten pages with a picture each (controls, turbo, shooting, dunks and
alley-oops, crossover, calling for the ball, defense, on fire, the Road Trip, stars). Swipe left or right, or tap
the big < > arrows, to turn the page; BACK goes back to the title.

You are BLUE: the player with the arrow over his head. The arrow next to BLUE in the top bar shows which hoop you
attack (it flips when the teams switch sides).
- Move: put your thumb anywhere on the left half of the screen and drag. The joystick appears under your thumb.
- A (orange button, bottom right): SHOOT with the ball; STEAL or BLOCK on defense.
- B (blue button): PASS with the ball, CALL for it without the ball, SWITCH player on defense.
- Sprint (turbo): pull your thumb past the joystick ring, out to the faint orange outer ring.
- SHOOT: hold A and let go when the white marker is in the green zone. Perfect timing = much better odds.
  Defenders nearby lower your odds. Near the rim A dunks or lays up right away.
- PASS: throws to your most open teammate, or to the teammate in the direction you are pushing.
- Left-handed? SETTINGS > LEFT-HANDED: ON swaps the sides (see LEFT-HANDED below).
- Pause: the button with two bars in the top right corner (on Android the back gesture also pauses).
On a computer: WASD moves, J is A, K is B (for testing; the game is made for touch).

LEFT-HANDED
SETTINGS > LEFT-HANDED: ON mirrors the controls: the joystick moves to the right half of the screen and the A and B
buttons to the bottom left. It starts with the next game and the game remembers it. Everything else is the same.

THE TITLE SCREEN
The game opens on the title screen:
- ROAD TRIP: the campaign (see THE ROAD TRIP below). It shows CONTINUE (your saved trip, lit gold) and NEW TRIP.
  NEW TRIP then asks for the level: EASY, NORMAL or HARD (and LEGEND once you have all 72 stars). If you already
  have a saved trip, NEW TRIP first asks START OVER (your old trip is gone; your stars stay) or KEEP MY TRIP. The
  ROAD TRIP button carries your stars ("STARS n/72").
- QUICK GAME: one game to 21 against the CPU. Its panel has the level (EASY / NORMAL / HARD, LEGEND once open; tap
  one to play), the teams, the COURT and the MUSIC (see QUICK GAME below). After the game the panel comes back; its
  TITLE button goes back to the title.
- LOCKER: your star rewards (see STARS AND THE LOCKER below).
- LEGENDS: the era tour (see LEGENDS below). It opens at 24 stars; until then it is dark with a "24 STARS" tab, and
  a tap on it says how many stars you have.
- SETTINGS (all remembered):
  - MUSIC: ON / OFF, and the MUSIC volume slider next to it;
  - SOUND: the volume of the sound effects;
  - LEVEL: EASY / NORMAL / HARD (LEGEND once open) for Quick Game and new trips (with a saved trip it also changes
    that trip's level);
  - FULL SCREEN: ON / OFF. In the browser it fills the whole screen (the browser's back gesture or Esc leaves it;
    if it is ON, your next tap in the game puts it back). The Android app is always full screen;
  - LEFT-HANDED: ON / OFF (see above).
- HOW TO PLAY: the picture pages (see above).
- CREW & CREDITS: the version, your crew and their stats, unspent points and DRAFTED tags (from your saved trip,
  if any), the art, music and sound
  credits, and the Godot Engine license. Drag the list to scroll. Once you have unlocked a legend, a HALL OF
  LEGENDS button sits in its top right corner (see LEGENDS below).
BACK on each screen goes back to the title (on Android the back gesture does the same; on the title it closes the
app).

QUICK GAME
- EASY / NORMAL / HARD (and LEGEND once you have all 72 stars): big buttons on the panel, before the game and again
  after every game, under the final score.
  Tap one to play. The game remembers your choice (the lit button). The first time it starts on NORMAL.
- YOUR TEAM / OPPONENT: tap to pick the next team for each side. The Cornfield Kings (your crew) and the Bridge
  Runners are always there; every crew you beat on a Road Trip joins the list for good (a city's crew when you beat
  its boss, a New York crew when you win its round). Quick Game players are evened out (their stats average 50),
  so any matchup is fair; each crew keeps its own colors. The same crew can't be on both sides.
- COURT: GYM, COURT: BLACKTOP, ... Tap it to pick the next court (an indoor gym with bleachers, an outdoor
  blacktop, and every city court you have unlocked). A city's court unlocks when you beat that city's boss on a Road
  Trip, and stays unlocked (a new trip doesn't lock it again). Two more courts open with stars: MIDNIGHT (30
  stars) and GOLD HALL (60). A city court brings its city's twist, shown in a line under the buttons; the gym, the
  blacktop and the star courts have none.
- MUSIC: ON / MUSIC: OFF switches the music at once.
The panel comes back with the new teams or court behind it; then tap a level to play. The game remembers all of it.

HOW TO PLAY (IN FULL)
WITH THE BALL
- Crossover: a quick flick of the stick to a new direction while dribbling. You cut sharply and the ball switches
  hands. A defender close in front of you can stumble and get left behind. Smooth turns don't trigger it.
  The ball crosses in front of you, so it is easier to steal during a crossover.
- Pump fake: a quick tap of SHOOT (A), away from the rim where the meter shows. He raises the ball and hops.
  Press SHOOT again to shoot for real. A defender who jumps at the fake is stuck in the air: shoot or drive past.
  Near the rim SHOOT always dunks or lays up right away (no fake there).
- Alley-oop: PASS to a teammate cutting to the rim and you throw a lob that he dunks in the air.
- Close guarding: a defender right in front of you slows you down. Beat him with a crossover or a fake.
- Keep your body between the ball and the defender: a shielded ball is very hard to steal.

WITHOUT THE BALL
- Who you control: after you pass, you take over the player who caught it. When a teammate gets the ball any other
  way (rebound, steal, inbound, a pass from a teammate), he plays it and you keep your player.
- CALL (B, the blue button): ask for the ball. A "!" shows over you and the button lights up; your teammate passes
  as soon as the lane is clear. If nothing opens up the call ends after a moment.
- Call while cutting hard to the rim and you get a lob: you go up and dunk it (alley-oop).

DEFENSE
- A (the orange button) switches between STEAL and BLOCK by itself. It says BLOCK (deeper orange, up arrow) when
  your man starts a shot, or is near the rim with you close. Otherwise it says STEAL.
- STEAL: poke at the ball. It works best just as the dribble hits the floor (the button lights up yellow then), and
  when the ball is on your side of the handler, not behind his body. Every steal try freezes you for a moment, hit
  or miss, so don't spam it.
- BLOCK: a timed jump. Jump as he goes up; too early or too late and you miss. Jumping at a pump fake leaves you
  in the air while he shoots or drives past.
- SWITCH (B, the blue button): take over the teammate closest to the ball.

TURBO
- Moving the joystick normally never sprints. To sprint, pull your thumb past the joystick ring, out to the
  faint orange outer ring. The knob turns orange while you sprint.
- The bar under your player is your stamina. Sprinting drains it; ease off and it refills after a moment.
  If it runs empty you can't sprint until it has refilled a bit.
- You sprint slightly slower with the ball.
- A jump shot right after sprinting is less accurate. Dunks and layups are not affected.

DUNKS AND LAYUPS
- Press SHOOT near the rim (within about 9 ft). There is no meter for these, the shot goes right away.
- Very close and moving fast (or on turbo) = dunk. Otherwise it's a layup.
- A defender close to you can block it, and lowers your odds.

ON FIRE
- Make 3 shots in a row with the same player (dunks and layups count) and he catches fire.
- On fire: bigger orange green zone on the meter, stamina doesn't drain, a flaming ball trail and an orange ring.
- First miss: "He's cooling down." A second miss (or block) puts the fire out. A make in between makes him fully hot
  again. CPU players can catch fire too.

THE RULES
- First to 21 wins (21-20 counts, no need to win by 2; the first Road Trip games in a city go to 11 or 15).
  Streetball scoring: a basket inside the arc is 1 point, beyond the arc 2, a free throw 1. GAME POINT shows in the
  top bar when one more basket wins.
- There is no game clock and there are no quarters, only a 24 second shot clock (18 in Memphis). It starts again
  when your team gets the ball, and also after a shot hits the rim, even if your team gets the rebound.
- Switch sides: when the first team reaches 11 (halfway in a shorter game) the game stops for a moment ("SWITCH
  SIDES") and both teams attack the other hoop for the rest of the game. This happens once per game.
- After a basket the other team inbounds from under the hoop it defends.
- Fouls come from bad timing only:
  - A badly timed block jump (too early, too late, or still in the air after biting on a pump fake) that hits the
    shooter is a shooting foul. Missed shot: 1 free throw inside the arc, 2 beyond. Made shot: it counts, plus 1
    free throw (and-one).
  - Poking at a ball the handler shields with his body can be a reaching foul. The fouled team gets the ball from
    the sideline (no free throws).
  - The CPU fouls the same way, so you get free throws too.
- Free throws: everyone lines up and stands still. To shoot one, hold SHOOT and let go when the white marker is in
  the green zone, the same meter as a jump shot (a quick tap does nothing at the line). If you wait more than
  10 seconds you shoot automatically. After a made last free throw the other team inbounds; a missed last free
  throw is a live rebound.
- Out of bounds: only a loose ball that crosses a line is out (you can't step out by accident). The team that
  didn't touch it last gets the ball from that sideline or baseline. A hard bounce off the back of the rim
  sometimes flies out over the baseline.

DIFFICULTY
- On the Road Trip you pick the level when you start a new trip (change it later in SETTINGS); in Quick Game on its
  panel.
- Only the CPU team (RED) changes; it is never slower. On NORMAL and EASY the CPU shoots worse, reacts later to
  crossovers and shots, times its steals and blocks worse, bites on pump fakes more and helps less on defense.
- LEGEND (open once you have all 72 stars): the CPU plays like HARD and every opponent gets +12 on every stat (95 at
  most). A LEGEND win gives 3 stars, like HARD.

PLAYER RATINGS
Every player has five stats from 0 to 100 (50 = average): SPEED (how fast he runs), SHOOTING (jump shots and free
throws), FINISHING (dunks and layups), DEFENSE (his steals and blocks) and STAMINA (how long he can sprint). Good
timing is what makes a steal or block possible; better defenders turn good timing into a steal or block more often.
Badly timed tries almost never work. The stats only move the odds: the shot meter and the timing windows are the
same for everyone. On the Road Trip you raise them with stat points; a recruit keeps his own.

THE CPU
CPU players use everything you can: pull-up jump shots and 2-pointers from beyond the arc, crossovers, pump fakes,
cuts and alley-oop lobs.
CPU defenders poke at exposed balls, jump at shots (and sometimes bite on fakes) and get beaten by crossovers.

THE ROAD TRIP
You are the Cornfield Kings, three underdogs from a small town in Indiana: Deuce (shooting wing, the leader), Jojo
(quick point guard) and Tank (big man). You drive your van, The Biscuit, across the country to a streetball
tournament in New York.
- The route: Hometown (Indiana), Chicago, Memphis, New Orleans, Denver, Seattle, Los Angeles, then the tournament in
  New York. Every city has its own court, music, crew, story scenes and twist (see THE CITIES AND THEIR TWISTS).
- The map: the USA with a pin for every city. Gold = where you play next, a trophy = beaten. Each pin shows its
  best stars ("7/9"). The card at the bottom left shows the city, the game (1, 2 or 3), the points to win, the crew
  you face and the city's twist. Tap a pin to look at that city; tap the map to go back to yours. GO plays on. MENU
  (top right) goes to the title.
- Replays: tap a pin where you have won games on this trip to open its picker (its 3 games, or New York's rounds,
  with their best stars), pick the level (EASY / NORMAL / HARD, and LEGEND once you have all 72 stars; it starts on
  your trip's level, and the line under it says what a win there earns, e.g. "A WIN ON HARD: 3 STARS"), then PLAY.
  The replay plays and records its stars at that level; your trip's own level does not change. The opponents play
  at the stage you have reached. A replay only earns stars:
  no stat points, no story, no recruit, and your trip stays where it was. CLOSE (or a tap outside) closes the
  picker. After the whole trip the map stays open for replays.
- Each city has one local crew, and you play them 3 times, each time stronger:
  game 1 to 11 points (1 good player and 2 average ones), game 2 to 15 (2 good, 1 average), game 3 to 21 against
  2 good players and the crew's BOSS. Win all 3 to move on. A city's first visit starts with a short story scene.
- Lose a game? No penalty: tap RETRY and play that same game again.
- Story scenes: big portraits and a text box. Tap to see the whole line, tap again for the next one. SKIP (top
  right) skips the rest of the scene.
- After each game a result screen shows the score, WIN or LOSS, the points your starters won, the game's stars
  (NEW STAR / NEW BEST) and a few stats for both crews. NEXT plays on.
- Stat points: every win gives each of your 3 starters his own points: 1 for city games 1 and 2, 2 for the boss
  game and each New York round (the same on every level; a game you win again pays nothing). The STAT POINTS
  screen comes up after every win: tap +3 next to one of a starter's stats (Speed, Shooting, Finishing, Defense,
  Stamina). Each point adds 3; no stat goes above 90. UNDO takes back the last point. SKIP keeps the points for
  later (a gold badge on his card in the lineup opens the screen again); DONE moves on. After a city the screen
  shows the whole crew. A trip from the first version (1.0.0) keeps its points as CREW POINTS, which anyone can
  use.
- Recruit: after a city you pick ONE of its 3 best players (its 2 good players or the boss) to join your bench.
  Tap his card, then tap SIGN (his name) to confirm. He says a line as he joins (tap to go on). He keeps his
  ratings and wears your blue and gold.
- Lineup: before every game you pick your 3 starters from the whole crew. Tap a card to put him in; the FIRST one
  you pick is you (he gets the YOU badge), the next two are your teammates. Tap a starter again to bench him. Only
  one BOSS may start (however he joined), and only one LEGEND (see LEGENDS below); one legend and one boss may
  start together. The game remembers your lineup for the next game. PLAY starts the game.
- Draft: stars open extra roster slots (at 12, 24, 36 and 48 stars). An OPEN SLOT card in the lineup opens the
  DRAFT screen: any player from a crew you have beaten on this trip, bosses too. Tap a card, then SIGN and YES,
  SIGN. A draft is final for the trip; he joins with his city's ratings and a DRAFTED tag. Legends you have
  unlocked are in the list too, in a LEGENDS row at the end (see LEGENDS below).
- New York: the tournament, a bracket of 3 rounds (quarterfinal, semifinal, final), all to 21, in a fenced cage.
  You meet the Bridge Runners, the Bodega Bandits and, in the final, the champions, the Concrete Crowns, with their
  boss, King. A loss just replays that round. Each won round gives every starter 2 points, spent right after the
  round; the bracket also shows a POINTS button for any left. Win the final for the ending.
- Saving: the trip saves by itself after every game and every choice. One trip at a time. Close the game whenever
  you like; ROAD TRIP > CONTINUE on the title brings you back to where you were.

STARS AND THE LOCKER
- Every city game and every New York round gives stars for a win: 1 on EASY, 2 on NORMAL, 3 on HARD or LEGEND.
  Only your best result for each game counts: 24 games x 3 = 72 stars. Stars are kept for good (a new trip keeps
  them).
- What they open: an alternate jersey (6 stars), roster slots (12, 24, 36, 48), special balls (18, 42, 60), van
  paint jobs (24, 48, 66), more jerseys (36, 54), Quick Game courts MIDNIGHT (30) and GOLD HALL (60), and the
  LEGEND level (72).
- LOCKER (on the title): the list of rewards on the left (what you have, what is next) and, on the right, JERSEY,
  BALL and VAN: tap an open tile to wear it (CLASSIC is the normal look). The jersey is your crew's on the trip and
  the Kings' in Quick Game, the ball is in every game, the van drives on the trip map. Against a crew whose colors
  are too close to your jersey, your team wears its normal jersey for that game.

LEGENDS
The Legends mode is a tour through the eras of the game. You beat old-time legends in challenge games and unlock
them for good. Every legend is a made-up character with his own name and looks, not a real player.
- Opening it: the LEGENDS button on the title opens once you have 24 stars, from any trip games (a whole trip on
  EASY gives exactly 24).
- The era tour: a timeline of four chapters. Chapter 1, THE GRANDFATHERS, opens at 24 stars; Chapter 2, THE
  FATHERS, at 36 stars or 12 legend tokens (whichever comes first; until then its panel is LOCKED with that line).
  THE PRESENT and THE NEW GENERATION show as COMING LATER, with what will open them. Tap an open chapter (or its
  PLAY button). The first time, a story scene introduces the era. A chapter whose finale you won shows FINALE WON.
  HALL opens the Hall of Legends; BACK goes to the title.
- The chapter view: the six legends' plaques (a locked one is a silhouette with "?" and his challenge), the finale
  card, YOUR CREW, the level buttons and PLAY. Tap a plaque to pick his game, pick the level (EASY / NORMAL / HARD,
  LEGEND once you have all 72 stars; it starts on your trip's level), then PLAY. BACK goes to the timeline.
- Who plays: your Road Trip crew, your 3 current starters with their stats as they are now (so the challenges get
  easier as your trip crew grows). With no saved trip, the Cornfield Kings play at even stats ("NO TRIP: THE KINGS
  PLAY"). If you drafted a legend and he is on the other side, he sits that game and your best bench player plays
  ("STEEPLE SITS: ... PLAYS"). A Legends game never changes your trip: no stat points, no stars, no record.
- Each legend plays with two other legends of his era as his teammates. The goal shows on a line under the score.
  If you break it (he scores too much, or his crew reaches its number first), the game ends at once as a loss.
  The Grandfathers:
  - Steeple, the hook-shot center: hold him under 7 points and win (to 15).
  - Gate, the shot-blocking wall: reach 11 before his crew gets 10.
  - Set Shot, the deep shooter: he starts on fire and cools down only after 2 misses in a row; win (to 15).
  - Boxcar, the bruising power forward: block or steal the ball on him 2 times and win (to 15). A win with fewer
    stops doesn't count.
  - Velvet, the smooth slasher: hold him under 6 points and win (to 11).
  - Quarterback, the no-look floor general: you start down 0-2; come back and win (to 15).
  The Fathers (a step harder than the Grandfathers):
  - Rooftop, the high-flying shooting guard: block or steal the ball on him 2 times and win (to 15).
  - Ankles, the crossover artist: reach 11 before his crew gets 10.
  - Midrange, the isolation scorer: he starts on fire and cools down only after 2 misses in a row; win (to 15).
  - Freight, the low-post bulldozer center: hold him under 7 points and win (to 15).
  - Eyes Closed, the no-look passer: you start down 0-1; come back and win (to 15).
  - Lockbox, the lockdown wing defender: you yourself (YOU, your first starter) score at least 6 of your team's
    points and win (to 11). The line shows your points so far ("SCORE 6 ON LOCKBOX: 2"). The hardest one.
- Tokens: a won challenge gives 1 token on EASY, 2 on NORMAL, 3 on HARD or LEGEND. Only your best result for each
  game counts, so play a game again on a higher level for more: 21 tokens in each chapter (6 challenges and the
  finale, 3 each), 42 in all. Your first win against a legend unlocks him for good: he says a few words, and his plaque goes into the
  Hall of Legends.
- The finale: once all six of a chapter are beaten, its finale opens: the GRANDFATHERS FINALE (Steeple, Velvet and
  Quarterback) or the FATHERS FINALE (Rooftop, Midrange and Freight), to 21, with no special goal. A story scene
  comes before and after it; winning it finishes the chapter.
- OLD SCHOOL rules: every Grandfathers game is played in the OLD GYM with the era's rules, the same for both teams
  (a banner shows them at the tip-off): everyone is 6% slower, shots beyond the arc go in 20% less often, close
  shots, layups and dunks go in 8% more often, and fouls are called a little over half as often (60%).
- ISO BALL rules: every Fathers game is played in the NIGHT PARK (a blacktop under lights) with the era's rules,
  the same for both teams: a crossover beats the defender in front about 20% more often, dunks take off from 10%
  further out, and shots fly on a slightly higher arc. The Fathers' own music track is not in yet (the owner picks
  it); until then their games play the New York music.
- Signature moves: each legend has one small edge only he has. Steeple shoots hook shots close to the rim (hard to
  block), Gate's blocks stay in play (he keeps the ball or tips it to a teammate), Set Shot's long range starts
  further out, Boxcar dunks from further out, Velvet's finger rolls slip past defenders, and Quarterback throws
  long outlet passes. Rooftop's cradle dunks slip past part of a contest, Ankles' double crossover beats his man
  more often (and more defenders fall), Midrange's turnaround fadeaway (its own animation) loses less to a contest,
  Freight's close shots and dunks are harder to block, Eyes Closed's no-look passes are harder to intercept, and
  Lockbox's chase-down blocks from behind work more often.
- The Hall of Legends: HALL on the tour, or HALL OF LEGENDS on CREW & CREDITS. One row of plaques per era. Tap an
  unlocked legend to see his card, name, archetype, number, tokens, his strengths (the rating shape), his signature
  move and his mentor perk; REPLAY STORY plays his unlock scene again.
- Mentors: in the Hall, tap TRAIN on an unlocked legend and pick one of your players (your trip's crew; without a
  trip, Deuce, Jojo and Tank). The player gets a small perk, about 2 stat points' worth:
  Steeple: close shots and layups +1.5%; Gate: block timing window 5% wider; Set Shot: shots beyond the arc +1.5%;
  Boxcar: dunks from a little further out; Velvet: contested layups +1.5%; Quarterback: passes 5% faster;
  Rooftop: contested dunks +2.5%; Ankles: crossovers beat the defender 15% more often; Midrange: jumpers inside the
  arc +1.5%; Freight: 5% harder to strip; Eyes Closed: passes 15% harder to intercept; Lockbox: steal timing window
  5% wider.
  Each player has one mentor at most and each legend trains one player at a time. SWITCH moves him to another
  player and STOP TRAINING ends it (both ask first). Mentors coach your regular players only (a drafted legend can't
  be trained). Perks work in Road Trip games only, not in Quick Game or Legends games, and they stay when you start
  a new trip.
- Drafting a legend: every legend you have unlocked joins the DRAFT list for your open star roster slots (one
  LEGENDS row per era at the end, "UNLOCKED IN LEGENDS - THE FATHERS"). He joins boss-level for the part of the trip you have reached, with his own strengths (no stat
  above 95). Only one legend can start (from any era), but he may start next to one boss.
- Saving: the Legends progress (tokens, unlocked legends, scenes seen, mentors) is saved by itself, apart from the
  trip; a NEW TRIP keeps it.

THE CITIES AND THEIR TWISTS
Each city's twist works the same for both teams. A banner shows it at the tip-off and again after the switch.
- Hometown (County Line, a barn driveway hoop): no twist, the warm-up city.
- Chicago (Lakeshore Gusts, a lakefront rooftop): WIND. Long shots beyond the arc go in a bit less often and curve
  in the air; lobs drift. Wind streaks and a wind gauge show how hard it blows.
- Memphis (Riverside Soul, an old gym with a packed crowd): FULL HOUSE. An 18-second shot clock, everyone a bit
  faster, a loud crowd and camera flashes.
- New Orleans (Bayou Brass, a bayou blacktop): HUMID. Stamina refills more slowly. Heat shimmer, sweat when tired.
- Denver (Switchbacks, a mountain park): THIN AIR. Long shots go in a bit more often, shots and lobs float higher,
  and you tire faster. Breath puffs.
- Seattle (Puddle Jumpers, a rainy park): WET COURT. A hard reversal at full speed slides before you change
  direction (crossovers keep their grip). Rain and splashes.
- Los Angeles (Boardwalk Bombers, a beach court): SAND. Everyone is slower and turbo gives a bigger boost. Sand puffs.
- New York (the tournament, a fenced cage): THE CAGE. A loose ball bounces off the side fence back into play, so there
  is no out of bounds on the sidelines (the baselines are as usual).

THE PAUSE SCREEN
In every game a pause button (two bars) sits in the top right corner. Tap it to stop the game. The pause screen
shows the score, the stats of both teams and the court's twist, and has:
- RESUME: back to the game (the controls wait a moment, so the tap doesn't leak into the game)
- RESTART: the same game again from 0-0 (tap twice to confirm)
- QUIT: to the title in a Quick Game, to the trip map in a trip game, to the chapter view in a Legends game; the quit
  game doesn't count and starts again at 0-0 next time (tap twice to confirm)
- MUSIC on/off, FULL SCREEN on/off and the SOUND volume (all remembered)

THE PLAYERS AND THEIR MOVES
The players are about 100 pixels tall and have many animation frames:
- Dribbling: a standing dribble and a running dribble with the legs moving and the ball in time with the hand,
  and a crossover that switches hands.
- Dunks: 4 styles (one-hand, two-hand, tomahawk, windmill), plus the alley-oop catch and slam. The style depends on
  speed, turbo and the dunker's finishing; it is only the look, the chance to score is the same. Windmills come on
  turbo or from great finishers. After a made dunk he hangs on the rim for a moment.
- Layups and jump shots with a gather, release and follow-through; chest, bounce and lob passes.
- Defense: a defensive slide, a steal swipe, a block swat. A defender beaten up close by a crossover sometimes falls
  down and gets back up (an "ankle-breaker", about 1-3 a game).
- Motion effects: players squash and stretch on take-offs and landings, dust flies on hard cuts (sand on the
  beach, splashes in Seattle), and the camera punches in a little on big dunks.
All of it is only the look: it never changes the odds or the timing.

THE VIEW
You see the court at an angle from the near sideline, like a TV camera in the stands: the far sideline is at the
top of the screen, the players stand upright and jump up toward the top. The camera follows the ball left and
right and shows about two thirds of the court. The baselines stay left and right, so "right" on the stick is
toward the right hoop and "up" on the stick is toward the far sideline, as you see it.

SOUND AND MUSIC
The game has sound effects (swish, rim, bounce, dunk, block, crowd, whistle, fire) and music. The panels play the
menu music; in a game each court has its own track (every city has its own), played softer so the game sounds come
through. Some twists add a background sound: wind in Chicago, a loud crowd in Memphis, rain in Seattle, plus a fence
rattle, splashes and sand steps. Switch the music off with the MUSIC button (Quick Game panel, pause screen or
SETTINGS); SETTINGS also has a MUSIC volume slider, and a SOUND slider for the effects. Credits are in CREDITS.md
and on the CREW & CREDITS screen.
No sound in the browser? Make sure the tablet's media volume is up (not just the ringer), then tap the screen once.

SAVES
The game saves by itself: the trip after every game and every choice (user://trip.json), your settings, the
unlocked courts and teams, your stars and what you wear (user://settings.cfg), and the Legends progress (tokens,
unlocked legends, mentors; user://legends.json). A trip saved by the first version (1.0.0) loads and plays on.
Where that is:
- in the browser: in the browser's storage for that site (clearing the site's data or a private window loses it;
  the itch.io page and the GitHub Pages build have separate saves);
- in the Android app: in the app's own storage (an update keeps it; uninstalling the app deletes it);
- in the Godot editor: Godot's user data folder for the project (Project > Open User Data Folder).

=====================================================================================================================
PART 2: FOR THE OWNER (building, releasing, changing things)
=====================================================================================================================

OPEN IT ON THE TABLET (Godot Android editor)
1. Extract this zip (keep the RoadTripHoops folder together).
2. Open Godot, tap Import, and pick the project.godot file inside RoadTripHoops.
3. Open the project and press the Play button (top right). The first open takes a moment while Godot imports the
   images.

THE RELEASE FILES (version 1.0.0)
The version lives in one place: project.godot, [application] config/version="1.0.0". The title screen, the credits,
the file names below and the Android app all read it. For an update, raise it there (and, for Android, the version
code in the Android export preset; see docs/release/ANDROID.md).
The files are made on a computer with Godot 4.3 and its export templates (setup in docs/TEAM.md):
- Web (itch.io): tools/build_web.sh --zip  writes build/release/road-trip-hoops-<version>-web.zip (index.html at its
  root; on itch.io it is the file "played in the browser"). tools/build_web.sh --publish updates the GitHub Pages
  test build; --zip --publish does both.
- Android: tools/build_android.sh  writes the debug APK build/release/road-trip-hoops-<version>-debug.apk (for
  testing). tools/build_android.sh --release  writes build/release/road-trip-hoops-<version>.apk, signed with YOUR
  release key, which it only takes from the environment variables GODOT_ANDROID_KEYSTORE_RELEASE_PATH, _USER and
  _PASSWORD. docs/release/ANDROID.md explains how to make the key once, back it up, and export the release APK on
  the tablet or on a computer. Never put the key or its password in the project folder.
- The itch.io page: docs/release/ has the cover (cover.png, 630 x 500), the screenshots (screenshots/), the page
  text (itch_page.md) and UPLOAD.md, the step-by-step list for creating the page and uploading the files.
- The icons are in assets/icon/ (made by tools/art/make_icon.py, which also makes the cover).

EASY THINGS TO CHANGE (at the top of each file)
The Road Trip:
scripts/cities.gd (the cities, crews and players, all plain data):
- STAGE_AVG: the rating of an average player at each stop of the trip (40, 46, 52, 58, 63, 68, 73, 78: 1 =
  Hometown 40 ... 8 = New York 78)
- TIER: what good players and bosses add on top: "good" +4 on everything and +12 on their two specialties ("spec"),
  "boss" +20 on everything
- CITY_TARGETS: points to win games 1, 2 and 3 in a city ([11, 15, 21]); TOURNAMENT_TARGET: New York rounds (21)
- CITIES: one block per city: "name", "state", "look" (the court, e.g. "barn" or "rain_park"), "music", "twist"
  (e.g. "wind" or "none"), "built" (false = "coming soon" pin, the trip skips it), and its "crew" ("name", "style":
  inside / outside / balanced, the good, boss and average players). New York's "rounds" list the 3 tournament crews.
- PLAYERS: one block per player: "name", "role", "number", "tier", "spec", "steal_bias" / "block_bias" (steal and
  block = defense + bias). Your 3 underdogs have their "ratings" written out (speed, shooting, finishing, defense,
  stamina; 0-100, 50 = a Quick Game player).
- CREW_NAME / VAN_NAME: "CORNFIELD KINGS" and "THE BISCUIT"
scripts/trip.gd (the trip rules):
- POINTS_CITY_GAME: stat points for each starter after a win in city game 1 or 2 (1)
- POINTS_BOSS_GAME: the same after a boss game or a New York round (2)
- POINT_GAIN: how much one point adds to a stat (3)
- STAT_CAP: no stat goes above this by spending points (90)
- BOSS_CAP: no opponent stat goes above this (95)
- BOSS_LIMIT: how many bosses may start (1)
- LEGEND_LIMIT: how many legends may start (1; a legend is not a boss, so one of each may start)
- DEFAULT_LEVEL: the level of a trip when none is picked ("normal")
scripts/story_text.gd (the story):
- SCENES: every scene as a list of lines. Each line has "who" (a player id from cities.gd, or "narrator"), "side"
  ("left" or "right"), "text" and maybe "mood" ("happy" or "smug"). In the text, {crew} becomes Cornfield Kings,
  {van} The Biscuit and {city} the city's name. Keep a line to about 2 short sentences.
  Scenes: trip_start, <city>_arrive and <city>_won for every city before New York (e.g. memphis_arrive), first_loss,
  final_before, ending.
- RECRUIT_LINES: the line each player says when he joins your crew.
scripts/twists.gd (the city twists):
- TWISTS: one block per twist with its numbers, each with a comment, e.g. "speed_mult": 0.9 (sand: everyone 10%
  slower), "shot_clock": 18.0 (Memphis), "stamina_refill_mult": 0.7 (humid: 30% slower). The "banner" text is what
  the banner, the map card and the pause screen show. "era_grand" is the Grandfathers' OLD SCHOOL rules
  ("inside_mult": close shots, "foul_mult": fouls called), "era_fathers" the Fathers' ISO BALL rules
  ("cross_beat_mult": crossovers that beat the man, "dunk_range_mult": how far out a dunk starts).
scripts/legends_data.gd (the Legends mode, all plain data):
- CHAPTERS: the four eras (THE GRANDFATHERS and THE FATHERS are built): name, court, music, era rules, the stars
  or tokens that open it ("gate"), its six legends and the finale; a chapter may set its own "challenge_avg",
  "mate_drop" and "finale_stage_avg" (the Fathers: 69, 14 and 56)
- LEGENDS: one block per legend: names, number, "shape" (his five stats around his level; they add up to 0),
  "signature", "challenge" (the goal and its numbers, and "line", the text the game shows), "perk", "bio"
- PERKS: the mentor perks and their sizes
- TOKENS_BY_LEVEL: tokens for a win on each level (1 / 2 / 3, LEGEND 3)
- CHALLENGE_AVG: the challenge legend's level before his shape (66); MATE_DROP: how much lower his 2 teammates play
  (14) (both for a chapter without its own)
- DRAFT_TIER: what a drafted legend adds to the stage's average player (20); FINALE_STAGE_AVG: the finale legends'
  base before that (55, for a chapter without its own)
Any new legend must pass the real-name check (--legendtest; the list is docs/legends-namecheck.md).
scripts/trip_map.gd: DRIVE_TIME: seconds the van drives to the next city (3.0)
scripts/stars.gd: REWARDS: the reward list (at how many stars each one opens)
scripts/difficulty.gd: LEGEND_BONUS: what LEGEND adds to every opponent stat (12)
scripts/story.gd: TYPE_CPS: how fast the story text types out (48 letters per second)

The game:
scripts/view.gd (the angled view):
- DEFAULT_MODE: ANGLED (the game's view) or FLAT (the old straight-down view)
- TILT_Y: how flat the court looks (0.48; 1.0 = straight down, smaller = lower camera)
- PERSPECTIVE: 0 = no narrowing; 0.1-0.2 makes the far side narrower than the near side (sprites shimmer more)
- HEIGHT_SCALE: how tall jumps, the ball's height and the rims look (1.0)
- SIDE_FLIP: false = the camera stays on the same sideline when the teams switch sides; true = it moves to the
  other sideline
scripts/main.gd (the camera):
- CAM_ZOOM: how close the camera is in the angled view (1.72 at most; bigger = closer, less court on screen). On
  a short screen it zooms out a little, so the heads at the far sideline stay under the top bar
- CAM_ZOOM_MIN: how far it may zoom out on a short screen (1.2)
- CAM_ZOOM_FLAT: the zoom of the flat view (1.15)
- CAM_FOLLOW_X / CAM_FOLLOW_Y: how much the camera follows the ball left/right (1 = fully) and up/down (0 = not)
- CAM_SMOOTHING: how quickly the camera catches up (4.0)
scripts/court_looks.gd (the courts):
- LOOKS: one block per court ("gym", "blacktop" and the 8 city courts): its name on the button, its music track,
  its background sound ("ambience"), the floor and backdrop pictures, and the colors of the floor, lines, paint,
  backboard, rim, net and pole. Colors are
  Color(red, green, blue) from 0 to 1, an optional fourth number is see-through (1 = solid).
- DEFAULT: the court the first game uses ("gym")
scripts/rules.gd (the rules):
- TARGET_SCORE: points to win (21)
- WIN_BY: 1 = 21-20 wins; 2 = play on until a team leads by 2
- SWITCH_AT: the score that switches sides (11)
- GAME_POINT_BASKET: GAME POINT shows when a basket worth this much wins (POINTS_INSIDE = from 20;
  POINTS_BEYOND = from 19)
- POINTS_INSIDE / POINTS_BEYOND / POINTS_FT: points for a basket inside the arc (1), beyond it (2), a free throw (1)
- FT_INSIDE / FT_BEYOND / FT_AND_ONE: free throws for a missed shot fouled inside the arc (1), beyond it (2), and a
  made one (1)
- FT_HUMAN_WAIT: seconds you have at the line before it shoots for you (10)
- FOUL_MIN_CLOCK: after a reaching foul the shot clock keeps running, but is at least this (10)
scripts/main.gd:
- SHOT_CLOCK_LENGTH: the shot clock (24)
- FT_BASE / FT_CAP: free-throw make chance with a normal release (0.72), and at most (0.95)
- REACH_FOULS = false turns reaching fouls off
- FIRE_STREAK: makes in a row to catch fire (3)
- FIRE_MISSES: misses that put the fire out (2)
- STEAL_POKE_FREEZE: seconds you stand still after every steal try (0.3)
- STEAL_GRACE / STEAL_HUMAN_LATE: how close to the dribble's floor touch a poke must be to count as well timed
  (0.04 s before, 0.10 s after)
- STEAL_BASE / STEAL_RATING_SPAN: chance of a good poke at rating 50, and how much the rating moves it
- STEAL_REACH_FT: how close to the ball you must be to poke it (2.5)
- STEAL_COOLDOWN: seconds between pokes (0.7)
scripts/touch_controls.gd:
- TURBO_PULL: how far past the joystick ring you pull to sprint (1.5 = 1.5x the ring size)
scripts/human_input.gd:
- FLICK_ANGLE / FLICK_WINDOW: how far (100 degrees) and how fast (0.12 s) the stick must turn for a crossover
- SHORT_TAP_MAX: a SHOOT tap shorter than this is a pump fake (0.15 s)
- BLOCK_CLOSE_FT: how close you must be to the shooter for the button to say BLOCK (6)
- BLOCK_RIM_FT: a handler this close to the rim gets BLOCK even before he shoots (9)
- CALL_WINDOW: seconds a CALL stays alive before it times out (1.5)
- CALL_COOLDOWN: seconds before you can call again (0.75)
scripts/player.gd (values are being tuned, so check the file for the current numbers):
- RATINGS_BY_INDEX: the steal and block rating of each of the 3 players when a team brings no stats of its own
- BLOCK_GOOD_BASE / BLOCK_RATING_SPAN: chance of a well-timed block, and how much the rating moves it
- CROSS_STUN: how long a beaten defender stumbles after a crossover
- GUARD_FT / GUARD_SLOW: how close a defender slows the handler, and by how much
- PUMP_TIME: how long a pump fake lasts
- CPU_PULLUP_CHANCE / CPU_THREE_CHANCE / CPU_CROSS_CHANCE / CPU_PUMP_CHANCE / CPU_LOB_CHANCE: how often the CPU
  pulls up, shoots 2-pointers (CPU_THREE_*: beyond the arc), crosses over, fakes and throws lobs
- TURBO_SPEED_MULT / TURBO_BALL_MULT: sprint speed without and with the ball
- STAMINA_DRAIN / STAMINA_REFILL: how fast the stamina bar empties and fills (per second, 1.0 = full bar)
- TURBO_SHOT_PENALTY: jump shot quality right after sprinting
- LAYUP_RANGE: feet from the rim where SHOOT becomes a layup or dunk
- DUNK_RANGE: feet from the rim where a dunk is possible
- DUNK_OPEN_PCT / LAYUP_OPEN_PCT: make chance when nobody is near you
- FIRE_GREEN_LO / FIRE_GREEN_HI: green zone while on fire (normal is GREEN_LO / GREEN_HI)
- FIRE_SHOT_BONUS: extra make odds while on fire
- ANKLE_BREAK_PCT: how often a defender beaten up close by a crossover falls down (30 = 30% of them)
- DUST_CUT, DUST_LAND, ...: how strong the dust puffs at the feet are (0 to 1)
- PUNCH_STRENGTH: how hard the camera punches in on a big dunk (1.0; 0 = off)
scripts/defense.gd (CPU defense, also being tuned):
- CPU_JUMP_CHANCE: how often a CPU defender jumps at a shot
- CPU_FAKE_BITE: how often he bites on a pump fake
- CPU_POKE_CHANCE / CPU_POKE_ON_TIME: how often he pokes at the ball, and how often his poke is well timed
- BLOCK_HEIGHT_MIN: how high in the jump a block has to be to count as well timed
- REACH_FOUL_CHANCE / REACH_FOUL_HUMAN_CHANCE: chance that a poke at a ball the handler shields with his body is a
  reaching foul, for the CPU (0.3) and for you (0.1)
- FOUL_BAD_JUMP_CHANCE: chance that a badly timed block jump that hits the shooter is a foul (0.5)
scripts/difficulty.gd:
- LEVELS: how much weaker the CPU is on NORMAL and EASY. Each line changes one Hard value: ["mul", 0.9] multiplies
  it, ["add", 0.05] adds to it (seconds). A key left out plays like Hard.
scripts/ball.gd:
- RIM_LONG_CHANCE / RIM_WIDE_CHANCE: how often a miss bounces hard off the back or side of the rim (0 = never)
scripts/audio.gd:
- MASTER_DB: sound effects volume (lower = quieter, e.g. -6.0)
- MUSIC_DB: music volume with the SETTINGS slider all the way up (-14.0; lower = quieter, e.g. -20.0)
- MUSIC_DUCK_DB: how much softer the music plays during a game than on the panels (-8.0; 0.0 = just as loud)
- AMBIENCE_DB: the volume of the twist background sounds (rain, wind, loud crowd) (-20.0; lower = quieter)
Shooting odds are in shot_probability() in main.gd. CPU behavior is in scripts/player.gd and scripts/defense.gd.

FILES
- main.gd: game loop, shot clock, HUD, input routing, steals, on fire, the test modes
- rules.gd: first to 21, scoring, switching sides, dead balls and inbounds, fouls and free throws, out of bounds
- difficulty.gd: EASY / NORMAL / HARD / LEGEND values for the CPU, and the saved settings (level, unlocked courts
  and teams, LEFT-HANDED, FULL SCREEN)
- menu.gd: the Quick Game panel (EASY / NORMAL / HARD / LEGEND, YOUR TEAM / OPPONENT, COURT and MUSIC)
- human_input.gd: your controls (crossover flicks, pump fake taps, CALL, STEAL/BLOCK button)
- player.gd: movement, turbo, crossovers, pump fakes, dunks, layups, alley-oops, ratings, CPU offense
- defense.gd: CPU defense (man-to-man, pokes, block jumps) and block rules
- ball.gd: dribbling, passes, shot arcs, rebounds
- court.gd: draws the court, rims and nets (through view.gd)
- view.gd: the angled view: turns positions on the court into spots on the screen (the game itself still plays on a
  flat top-down court), and the stick into a direction on the court
- court_looks.gd: the court looks (gym, blacktop, the 8 city courts and the 2 star courts): colors, pictures and
  music of each court
- twists.gd: the city twists (wind, crowd, humid, thin air, wet, sand, cage) and their numbers
- twist_fx.gd: what you see and hear of a twist (banner, rain, wind streaks, sand puffs, background sound)
- sheets.gd: reads the player pictures (assets/players2) and where the hands and the ball are in each frame;
  shaders/palette.gdshader colors them in
- touch_controls.gd: joystick and buttons (and their mirrored LEFT-HANDED layout)
- audio.gd: plays the sound effects (files in assets/sfx) and the music (files in assets/music), at the
  SETTINGS volumes
- fx.gd: popups, screen shake, fire trail
- countdown.gd: the 3-2-1-GO! at the start of every game
The Road Trip:
- flow.gd: moves between the screens (title, map, story, lineup, game, result, points, recruit, bracket, draft,
  locker, legends, hall)
- trip.gd: the trip's rules and progress (games, retries, stat points, recruits, drafts, starters, replays, New
  York, CONTINUE)
- stars.gd: the stars and the list of rewards they open (REWARDS at the top)
- cosmetics.gd: the jerseys, balls, van paints and star courts, and which ones you wear
- save.gd: writes and reads the trip save (user://trip.json) safely
- cities.gd: the cities, crews and players (data)
- ratings.gd: what the five stats do in a game
- ui_kit.gd: the shared look of the buttons and panels on the screens
- title.gd: the title screen, SETTINGS and CREW & CREDITS (the credits list is CREDITS_LIST at the top)
- howto.gd: the How to Play screen (the page text is in PAGES at the top; the pictures are in assets/howto)
- trip_map.gd: the trip map with the van and the replay picker
- locker.gd: the LOCKER screen
- draft.gd: the DRAFT screen
- story.gd: the story scenes (the lines are in story_text.gd)
- lineup.gd: picking your 3 starters
- after_game.gd: the result screen and the stat points screen
- recruit.gd: signing a player after a city
- bracket.gd: the New York tournament bracket
- pause.gd: the pause button and screen
- trip_test.gd: a test that plays a whole trip by itself (for the team, not used in play)
Legends:
- legends_data.gd: the eras, legends, challenges and perks (data)
- legends.gd: the Legends progress (tokens, unlocks, the finale, mentors) and how a challenge game is set up
- legends_save.gd: writes and reads the Legends save (user://legends.json) safely
- challenge.gd: the challenge goal in a game (the line under the score, the win or loss)
- legends_tour.gd: the era tour screen (the timeline and the chapter view)
- hall.gd: the Hall of Legends and the mentor picker
- legends_test.gd: a test that plays the Legends chapters by itself (for the team, not used in play)
- anim_test.gd: a test that checks every player's pictures (for the team, not used in play)
- howto_shots.gd: takes the game screenshots the How to Play pictures are made from (for the team, not used
  in play)

Art: the players, courts, ball, trip map, story portraits, icons and How to Play pictures are original art made
for this game by the scripts in tools/art. The old Kenney Sports Pack sprites (www.kenney.nl, CC0) in assets/ are
only a fallback if a player has no picture at all.
Sounds and music: see CREDITS.md.

MAKING THE ART AGAIN (for the curious; needs a computer with Python 3, Pillow and numpy)
The pictures are drawn by scripts, not by hand, so they can be changed and made again:
- python3 tools/art/make_players_v2.py --all   makes the player pictures in assets/players2: every animation
  frame of every player (gray pages plus a color palette per player, so a recruit in your colors is only a new
  palette), hands.json (where the hands and the ball are in each frame), format.json (the list of animations) and
  the cards for the lineup screen. Each player is described in tools/art/crews.json: body, skin, hair, top, shorts,
  colors, number. A new player is one more entry there; then run the script again. "--only ID" makes just one
  player. Drawing all of them takes a long time. (tools/art/make_players.py made the old, smaller players; it is
  only kept because the new script borrows its parts.)
- python3 tools/art/make_courts.py    makes the court floors and backdrops in assets/courts (gym, blacktop and the
  8 city courts) and the ball in assets/ball.
- python3 tools/art/make_portraits_v2.py   makes the story portraits in assets/portraits (comic style).
- python3 tools/art/make_map.py       makes the trip map, pins, van and van paints in assets/map.
- Legends: make_players_v2.py --only lg_steeple,... makes the legend players (the Grandfathers with their
  hook-shot pages, Midrange with his fadeaway pages, lg_<id>_x0.png); make_portraits_v2.py --legends (or --legends
  fathers) their portraits; make_courts.py --era the OLD GYM and the NIGHT PARK (--era fathers: only the NIGHT
  PARK); python3 tools/art/make_legends_ui.py   the tour timeline, chapter pins and Hall frames in assets/legends.
- python3 tools/art/make_cosmetics_preview.py   puts every star reward (jerseys, balls, vans, courts) on one
  picture, docs/art/cosmetics_preview.png.
- python3 tools/art/make_icon.py      makes the app icons in assets/icon and the itch.io cover
  docs/release/cover.png.
- python3 tools/art/make_howto.py     makes the How to Play pictures in assets/howto from the game screenshots
  in tools/art/howto_raw (the team takes new screenshots with the --howto-shots test; see CLAUDE.md).
- Preview pictures go to docs/art (not used by the game). Copy the new files into the project on the tablet and
  Godot picks them up when it re-imports.
