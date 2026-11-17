# Phase 5 summary: the Road Trip framework and the pause screen

Play it at https://kirmalo.github.io/road-trip-hoops/ (reload the page once to get the new build).

## What's new
- **Title screen**: ROAD TRIP, QUICK GAME, SETTINGS (music, sound volume, level), CREW & CREDITS.
- **Road Trip**: the Cornfield Kings (Deuce, Jojo, Tank) leave home in the van The Biscuit.
  - **Hometown**: 3 games against County Line, to 11, 15 and 21. Each game swaps in a better player, and the Mayor
    (the boss) plays game 3.
  - **Chicago**: 3 games against the Lakeshore Gusts, with Big Lou as the boss.
  - **New York**: a 3-round knockout, every round to 21, ending against King and the Concrete Crowns.
  - The 5 cities in between show as "coming soon" on the map (Phase 6).
- **Between games**:
  - Story scenes with comic-style portraits.
  - The USA map with the van driving between pins.
  - Lineup: pick 3 starters; the first one is you.
  - Result screen with RETRY or NEXT; a loss replays the game, with no limit.
  - After a city: spend stat points, then sign 1 of 3 players from the crew you beat.
- **Saving**: the game saves after every step. CONTINUE on the title picks up where you left off, and the save
  survives closing the browser.
- **Pause**: a button at the top right in every game, with RESUME, RESTART, SETTINGS and QUIT.

## QA (docs/qa/phase5.md)
- The whole trip plays through with no errors, including a loss and retry, and quitting and resuming.
- Quick Game plays exactly as before.
- The web build works by touch, and the download is 5.5 MB.
- Five small bugs were found and fixed:
  - the bracket and lineup text was cut off;
  - CONTINUE did nothing on a finished trip;
  - two problems in the test tools.
- **Open: difficulty inside a city.** On Normal, with the computer playing your crew, your crew wins about 60-70% of
  every city game. Game 3 against the boss is not clearly harder than game 1.
