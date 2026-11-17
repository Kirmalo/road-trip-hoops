# Phase 6 summary: all 8 cities and the new animated players

Play it at https://kirmalo.github.io/road-trip-hoops/ (reload the page once to get the new build). The first load
takes a few seconds longer than before, because the new players are bigger.

## What's new
- **The whole trip**: Hometown, Chicago, Memphis, New Orleans, Denver, Seattle, Los Angeles, then the New York
  tournament. No more "coming soon" pins.
- **Every city has its own**:
  - court (a barn driveway, a lakefront rooftop, an old soul gym, a bayou blacktop, a mountain park, a rainy park,
    a beach court and a fenced cage in New York);
  - crew, with a boss for game 3 (for example Riverside Soul in Memphis, the Boardwalk Bombers in Los Angeles);
  - story scenes when you arrive and after you win, in the comic portrait style;
  - music, picked from your listening list;
  - **twist**, the same for both teams, shown with a banner at the tip-off, on the map card and on the pause screen:
    - Chicago: wind (long shots and lobs drift);
    - Memphis: full house (18-second shot clock, a faster game, a loud crowd);
    - New Orleans: humid (stamina refills more slowly);
    - Denver: thin air (the ball floats, long shots fall more, you tire faster);
    - Seattle: wet court (a hard turn at full speed slides);
    - Los Angeles: sand (everyone slower, turbo matters more);
    - New York: the cage (the ball bounces off the side fence instead of going out).
- **New players**: every player is redrawn, bigger (about 100 px tall) and with many more frames.
  - A running dribble with the legs moving, the ball in time with the hand.
  - 4 dunk styles (one-hand, two-hand, tomahawk, windmill), a hang on the rim after a dunk.
  - Chest, bounce and lob passes; a steal swipe and a block swat.
  - A defender beaten up close by a crossover can fall down ("ankle-breaker").
  - Motion effects: squash and stretch on jumps, dust on hard cuts and landings, a small camera punch on big dunks.
- **Recruits talk**: the player you sign says a line with his portrait.
- **Quick Game courts**: beat a city's boss on the Road Trip and its court (with its twist) joins the COURT button.
  It stays unlocked, even on a new trip.

## QA (docs/qa/phase6.md)
- 1,212 test games with no crash or stuck game. The whole trip plays through all 8 cities to the ending.
- **Difficulty ramp**: with the computer playing your crew on Normal, your crew wins about 60-75% of games in the
  first four cities, and about 45-55% from Denver on. That is the shape we aimed for.
  - The test plays your 3 starting players all trip and puts every stat point on Deuce. A real player who starts
    his recruits is stronger, so these numbers are the hard end.
  - Two games are tougher than the rest: the Denver boss game (your crew wins 30%) and the New York final (38%).
- **Twists are fair**: none of them helps one team more than the other.
  - Clearly felt: wet court, sand, thin air and the cage.
  - Barely visible when the computer plays both sides: the humid air and the Memphis crowd (the computer never runs
    out of stamina, and always shoots within 18 seconds). You feel them more when you play.
  - The wet court was far too slippery at first (about 500 slides a game). It's now about 68 a game, even between
    the teams.
- **Animations**:
  - They don't change how the game plays: steals, blocks and scores are the same as before.
  - About 2-3 ankle-breakers a game.
  - A third of all passes are bounce passes.
- **Speed and size**:
  - The web game runs about as fast as Phase 5 (2.5% slower in our test, inside the normal spread).
  - The download is **30.8 MB**, inside the 31 MB you OK'd.
- Two small bugs were found and fixed: the BALL! call could be cut off at the screen edge, and a trip saved in
  Phase 5 would have skipped the new cities (it now continues in Memphis).

## How to try it
- On the title, ROAD TRIP > CONTINUE picks up your Phase 5 trip at Memphis, the first new city. NEW TRIP starts
  over from Hometown.
- Quick Game still has the gym and the blacktop. A city court shows up there after you beat that city's boss.

## Questions while you play
1. **The new players and moves.** (a) Good as is. (b) The dust is too strong. (c) The dust is too weak. (d) Too many
   bounce passes (now a third of all passes). (e) Too many ankle-breakers (about 2-3 a game).
2. **The twists.** (a) All good. (b) Humid (New Orleans) and the crowd (Memphis) should be stronger. (c) Sand
   (Los Angeles) should be stronger. (d) Something else (tell us which).
3. **Difficulty late in the trip.** The Denver boss game and the New York final are the hardest games. (a) Fine,
   hard is good there. (b) Make the Denver boss a little easier. (c) Make both a little easier.
4. **The look and sound.** (a) All fine. (b) The camera is about 5% further out (so the bigger players fit); I'd
   like it closer. (c) The background sounds (rain, wind, crowd) are too loud. (d) Too quiet.
5. **Small calls.** For each, tell us yes or no:
   - Recruits' joining lines: keep them?
   - Quick Game: the computer team wears the Bridge Runners (a New York crew). OK?
6. **Next.** (a) Start Phase 7, the release phase: settings (volume, difficulty, a left-handed layout), a How to Play
   screen, the itch.io web and Android versions, store page text and screenshots. (b) A tuning round on Phase 6
   first.
