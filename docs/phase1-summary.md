# Phase 1 is ready to play: "feel"

Phase 1 was about making every possession feel more exciting. Here's what changed, how to get it, and what we'd
like you to check.

## What's new
- **Turbo.** Push the joystick all the way to the edge to sprint. The bar under your player is your stamina: it
  drains while you sprint and refills when you ease off. You're a little slower with the ball, and a jump shot right
  after sprinting is less accurate. The CPU sprints too (fast breaks, chasing loose balls, catching up on defense).
- **Dunks and layups.** Press SHOOT near the rim (about 9 ft) and it goes up right away, no meter. Very close and
  moving fast (or sprinting) is a dunk, otherwise a layup. A defender right on you can block it.
- **On fire.** Make 3 in a row with the same player and he catches fire: bigger green zone, stamina doesn't drain,
  flaming ball trail and an orange ring. Your rule is in: the first miss shows "He's cooling down.", a make heats him
  back up, and a second miss (or block) puts the fire out. The CPU can catch fire too.
- **Sounds.** Swish, rim, bounce, dribble, dunk, block, crowd, whistle and a fire sound.
- **Effects.** Screen shake on dunks and blocks, nets that swing on a make, big score popups, "SLAM DUNK!" and
  "ON FIRE!" popups.

## How to get it on the tablet
1. On GitHub, open **Kirmalo/road-trip-hoops**.
2. Tap the branch menu (it usually says `main`) and pick **ccr-f5c087b2-3ojk5f**.
3. Tap **Code**, then **Download ZIP**.
4. Extract the ZIP. The folder will be named something like `road-trip-hoops-ccr-f5c087b2-3ojk5f`; keep it together.
5. Open Godot, tap **Import**, and pick the `project.godot` file inside that folder.
6. Open the project and press **Play** (top right). The first open takes a moment while Godot imports the images
   and sounds.

Tip: turn the volume up. This is the first build with sound.

## Try this in one game
- [ ] Sprint the length of the court with the stick at the edge until the stamina bar runs empty. Watch it refill.
- [ ] Sprint at the rim and press SHOOT close in for a dunk. Feel the shake.
- [ ] Press SHOOT a bit further out (6-9 ft) for a layup.
- [ ] Try a dunk with a defender right on you and see if he blocks it.
- [ ] Make 3 in a row with one player to catch fire. Then miss once ("He's cooling down."), and see what a make does.
- [ ] Take a jump shot right after sprinting, then one after standing still, and compare.
- [ ] Listen to every sound: swish, rim, bounce, the dribble, dunk, block, crowd, whistle, fire.
- [ ] Watch the CPU on a fast break: does it look like it's trying?

## Known issues
- **The CPU barely takes jump shots** (about 1 per game). Almost everything is a dunk or layup. Planned fix in
  Phase 2.
- **Nobody has heard the sounds yet.** Our test machine has no speakers, so they've only been checked for errors.
- **Swish and bounce are stand-ins.** We couldn't find real basketball recordings with a free license yet.
- **Team balance needs a recheck.** Over 80 CPU-vs-CPU games RED won a bit more often (46 to 34). It's probably just
  chance, and we'll check it again after Phase 2 changes the CPU.
- Stamina doesn't refill between quarters (tell us if you'd like it to).
- Most games go to overtime more than you'd expect, because nearly every basket is 2 points. First to 21 in Phase 3
  removes overtime.

## Questions for you after playing
Pick one answer for each. The first option is our recommendation.

**1. How does turbo feel?**
- a) About right, keep it (recommended)
- b) Sprint should be faster
- c) Stamina should last longer or refill faster
- d) Too strong, tone it down

**2. How do dunks feel?**
- a) Good: powerful and about the right amount (recommended)
- b) They should go in more often
- c) Too many dunks, make them rarer
- d) It's not clear when I'll dunk and when I'll lay it up

**3. Should the CPU start taking jump shots?**
- a) Yes, teach it to pull up from mid-range and sometimes from deep in Phase 2 (recommended)
- b) No, keep it attacking the rim

**4. The dribble sound (your player, every other bounce):**
- a) Keep it, but quieter (recommended)
- b) Keep it as it is
- c) Drop it

Anything else that sounded or looked wrong, just tell us in your own words.
