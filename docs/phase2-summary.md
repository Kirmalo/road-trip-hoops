# Phase 2 is ready to play: "moves"

Phase 2 gives you (and the CPU) new moves on offense and defense. Here's what changed, how to get it, and what we'd
like you to check.

## What's new
- **Crossover.** While dribbling, flick the stick quickly to a new direction. Your player cuts hard and the ball
  switches hands. A defender close in front of you can stumble and get left behind (about 1 time in 3). Smooth turns
  never trigger it. The ball is a bit easier to steal during a crossover.
- **Pump fake.** A very quick tap of SHOOT (away from the rim, where the meter shows) fakes a shot. Tap again or hold
  to shoot for real. A defender who jumps at the fake is stuck in the air. Near the rim SHOOT still dunks or lays up
  right away. There's a short wait (under a second) before you can fake again.
- **Alley-oops.** PASS to a teammate cutting to the rim and you throw a lob that he dunks in the air. The CPU throws
  them too, about 3 per game.
- **CALL and who you control.** On offense without the ball, the blue button says CALL. Press it to ask for the ball:
  a "!" shows over you and your teammate passes as soon as the lane is clear. Call while cutting to the rim and you
  get a lob. When you pass, you take over the player who caught it. When a teammate gets the ball another way
  (rebound, steal, inbound), he plays it himself and you press CALL to get it.
- **STEAL or BLOCK, picked for you.** On defense the orange button switches by itself. It says BLOCK (deeper orange,
  up arrow) when your man starts a shot or is near the rim with you close. Otherwise it says STEAL.
- **Timed steals.** The STEAL button turns solid yellow with a ring at the moment a poke would be well timed (as the
  dribble hits the floor). Well-timed pokes on a ball that isn't hidden behind the handler's body work most of the
  time; random pokes almost never do. Every poke freezes you for a moment, hit or miss, so don't spam it.
- **Timed blocks.** BLOCK is a jump. Jump as he goes up; too early or too late and you miss.
- **Close guarding.** A defender right in front of the ball handler slows him down. Beat him with a crossover or a
  fake.
- **Player ratings.** Every player has a steal rating and a block rating. Each team has a quick-hands guard, a
  shot-blocker and an all-round player, with the same totals for both teams. Good timing makes a steal or block
  possible; the better player turns it into one more often.
- **The CPU uses all of it.** It now takes pull-up jump shots (about 15 per game) and the odd three, crosses over,
  pump fakes and throws lobs. On defense it pokes at loose dribbles, jumps at shots, sometimes bites on fakes and can
  be beaten by a crossover.

## How to get it
Open https://kirmalo.github.io/road-trip-hoops/ in Chrome on the tablet, as before. If you still see the old version,
pull down on the page to refresh. If you check right after we publish, give it a minute or two, then refresh again.
Tap the screen once to turn sound on.

(The ZIP from GitHub still works in the Godot editor too, same steps as in Phase 1.)

## Try this in one or two games
- [ ] Dribble at a defender and flick the stick sideways for a crossover. Watch whether he stumbles.
- [ ] Steer normally for a while, and lift and re-place your thumb a few times. Did a crossover ever happen by accident?
- [ ] Outside the paint, tap SHOOT very quickly for a pump fake. If the defender jumps, shoot or drive past him.
- [ ] Cut to the rim without the ball and press CALL. Do you get a lob and dunk it in the air?
- [ ] Pass to a teammate who is running to the rim for an alley-oop.
- [ ] Get a rebound with a teammate, then press CALL to get the ball back. Does it feel clear who you control?
- [ ] On defense, wait for the yellow STEAL button and poke. Then try poking at random times and compare.
- [ ] Jump with BLOCK just as a CPU shooter goes up. Then try jumping early.
- [ ] Notice how long you stand still after a poke. Does it feel like a fair price?
- [ ] Watch the CPU from outside: does it feel like a threat with its jump shots and threes?

## Known issues
- **The PASS and SHOOT buttons can cover a teammate** standing in the bottom-right corner when play is near the right
  hoop. We can move or shrink the buttons (see question 4).
- **The team attacking the right hoop has a tiny edge** (about 0.7 points per game in CPU-vs-CPU tests). Right now
  that's your team, so it's in your favor. Switching sides at 11 in Phase 3 cancels it out.
- **Jumping a little early for a block still works fairly often** (about 1 in 5, against about 1 in 4 when timed
  well). Easy to make stricter if blocking feels too easy.
- **On a slow device a quick flick can occasionally be missed.** Fixed for most cases (9 of 10 flicks register even at
  very low frame rates); tablets running smoothly shouldn't notice.
- **The lob's high arc is hard to see**, because the catch happens early in the ball's flight.
- **Swish and bounce are still stand-in sounds** until Phase 4.
- **The game is still 4 quarters with 2 and 3 pointers.** First to 21 with 1s and 2s comes in Phase 3.

## Questions for you after playing
Pick one answer for each. The first option is our recommendation.

**1. How does the crossover feel?**
- a) About right: easy to do on purpose, never by accident (recommended)
- b) Too hard to trigger: make the flick easier
- c) It happens by accident: make it stricter
- d) Easy to do, but it doesn't beat defenders often enough

**2. Do steals and blocks feel fair?**
- a) Yes: the yellow STEAL cue is easy to time and blocks feel earned (recommended)
- b) Blocks are too easy: jumping early shouldn't work as often
- c) Steals are hard: the yellow cue is hard to see or too short
- d) The freeze after a poke is too long (or too short)

**3. How hard is the CPU overall?** (This sets "Normal" for Phase 3's Easy / Normal / Hard.)
- a) About right: make this Normal (recommended)
- b) Too hard: make this Hard and build an easier Normal
- c) Too easy: make this Easy and build a tougher Normal

**4. The PASS and SHOOT buttons over the bottom-right corner:**
- a) Move them a little lower and make them a bit smaller (recommended)
- b) Keep the buttons, move the view so the ball stays above them
- c) It didn't bother me, leave it

Anything else that felt wrong or confusing, just tell us in your own words.
