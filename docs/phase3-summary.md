# Phase 3 is ready to play: "rules and format"

Phase 3 turns the game into real streetball: first to 21, 1s and 2s, fouls, free throws and out of bounds, plus
a choice of three difficulty levels. Here's what changed, how to get it, and what we'd like you to check.

## What's new
- **EASY / NORMAL / HARD.** A panel with three big buttons shows when the game opens and again after every game,
  under the final score. Tap one to play. The first time it starts on NORMAL, and after that the game remembers your
  last choice (the lit button). **HARD is the CPU you played in Phase 2.** On NORMAL and EASY the CPU isn't slower,
  it's less sharp: it shoots worse, reacts later, times its steals and blocks worse, bites on pump fakes more and
  helps less on defense. Only the RED team changes.
- **First to 21, with 1s and 2s.** A basket inside the arc is 1 point, beyond the arc 2. The first team to 21 wins
  (21-20 counts). There are no quarters and no game clock any more. The 24 second shot clock stays.
- **GAME POINT.** The top bar says GAME POINT in the team's color when one more basket wins it (right now from 20).
- **Switch sides at 11.** When the first team reaches 11, the game stops for a moment ("SWITCH SIDES") and both
  teams attack the other hoop for the rest of the game. The little arrow next to BLUE in the top bar shows which way
  you attack and flips at the switch.
- **Fouls, only from bad timing.** A block jump that's too early, too late, or still in the air after biting on a
  pump fake, and that runs into the shooter, is a shooting foul. Poking at a ball the handler is shielding with his
  body can be a reaching foul. A popup over the player says why: "FOUL: TOO EARLY", "FOUL: TOO LATE",
  "FOUL: BIT ON FAKE" or "FOUL: REACH". Good timing never fouls. The CPU fouls the same way, so you get fouled too.
  Expect about 3-4 fouls a game.
- **Free throws, with the shot meter.** A fouled shot that misses gives 1 free throw inside the arc, 2 beyond.
  Everyone lines up and stands still. To shoot, hold SHOOT and let go in the green zone, just like a jump shot (a
  quick tap does nothing at the line). After a reaching foul there are no free throws: you get the ball from the
  sideline.
- **And-ones.** If the fouled shot goes in anyway, it counts and you get 1 extra free throw ("AND ONE!").
- **Out of bounds.** A loose ball that crosses a line is out, and the team that didn't touch it last inbounds from
  there. You can't step out by accident. Now and then a hard bounce off the back or side of the rim flies long, and
  sometimes out over the baseline. We added these so out of bounds actually happens (see question 4).
- **The CPU takes more 2s.** It now looks for shots beyond the arc, with pull-ups and kick-out passes to a shooter
  outside. Roughly a fifth of its points come from 2s.
- **Small change:** the shot clock now starts again after a shot hits the rim, even if the same team gets the rebound.

## How to get it
Open https://kirmalo.github.io/road-trip-hoops/ in Chrome on the tablet, as before. If you still see the old
version, pull down on the page to refresh. If you check right after we publish, give it a minute or two, then refresh
again. Tap the screen once to turn sound on.

(The ZIP from GitHub still works in the Godot editor too, same steps as before.)

## Try this in one or two games
- [ ] Pick a level on the start panel. Close the page, open it again: is your level still lit?
- [ ] Play one game on NORMAL and one on HARD (or EASY). Does the CPU feel clearly different?
- [ ] Hit a shot from beyond the arc and watch for "+2". Inside the arc it's "+1".
- [ ] Watch the top bar when a team gets to 20: GAME POINT should show.
- [ ] Get to 11 first (or let RED) and watch the SWITCH SIDES pause. Do you know right away which hoop you attack now?
- [ ] On defense, jump with BLOCK on purpose a bit late into a shooter. Do you see the "FOUL: TOO LATE" popup?
- [ ] Poke at a ball the handler is hiding behind his body. Does a "FOUL: REACH" call feel fair?
- [ ] Drive hard to the rim to draw a foul, then shoot your free throws with the meter. Do a good release and an
      early one feel different?
- [ ] Watch for a long bounce off the rim that goes out of bounds. Does it look natural?
- [ ] On defense, stay with a CPU dribbler using the defensive assist and see how often his crossover leaves you
      behind.
- [ ] Notice how long a game to 21 takes you.

## Known issues and notes
- **A game to 21 takes about 11-12 minutes** (anywhere from 7 to 17). That's longer than the 8 minutes we hoped
  for. The plan you picked already fixes it in the Road Trip: early cities to 11 (about 6-7 minutes), middle ones to
  15 (about 9). This test build always plays to 21 (see question 3).
- **We couldn't check the frame rate in a browser here** (our test machine has no real graphics chip). If the game
  stutters or feels slow on the tablet, tell us.
- **Swish and bounce are still stand-in sounds** until Phase 4.
- **Most shooting fouls are on layups and dunks,** so many of them end up as and-ones (about 4 in 10). Real
  basketball has fewer; tell us if it feels off (see the note after the questions).
- **On EASY the CPU steals the ball rarely** (about 2 a game, some games none) and your crossovers beat its
  defenders most of the time. That's on purpose for Easy, but tell us if Easy defense feels too soft.
- **Rare:** if a free throw brings a team to 11 and then the last free throw misses, the rebound is live and the
  side switch waits for the next dead ball, so it can come a possession or so later.

## Questions for you after playing
Pick one answer for each. The first option is our recommendation.

**1. Do the difficulty levels feel right?**
- a) Yes: EASY is easy, NORMAL is a clear step up, HARD is a real challenge (recommended)
- b) EASY is still too hard: make it easier
- c) NORMAL feels almost like HARD: make NORMAL easier
- d) NORMAL feels almost like EASY: make NORMAL tougher

**2. When you defend with the assist, a CPU crossover beats you a lot (about 11 times out of 15 in our tests, on
HARD). How does that feel?**
- a) Fair: that's what a crossover is for, leave it (recommended)
- b) Too punishing: let my defender recover faster after a crossover
- c) Fine on HARD, but on EASY and NORMAL the CPU's crossovers should beat me less often

**3. How does the length of a game to 21 feel (about 11-12 minutes)?**
- a) Fine: keep 21 in this test build; the Road Trip brings the shorter 11 and 15 games anyway (recommended)
- b) Too long: play to 15 in this test build until the Road Trip arrives

**4. The long bounces off the rim that sometimes fly out of bounds (about 2 a game):**
- a) Keep them as they are (recommended)
- b) Fewer: about half as often
- c) Remove them (then out of bounds almost never happens, about once every 6-7 games)

Two small things, if you notice them: should GAME POINT already show at 19 (a 2 would win it), or stay at 20? And do
fouled layups and dunks go in too often? Anything else that felt wrong or confusing, just tell us in your own words.
