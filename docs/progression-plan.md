# Progression plan: stat points after every win, stars, and ways to keep leveling up

Planning document (lead-producer, 2026-11-17). This is a proposal. Nothing here is decided until you answer the
questions at the end, and no game code has changed. It answers your request: "stat allocation after each match
instead of just after boss matches. Any player who played in a win should get stats or a stat. Also, there should
be a star system for beating levels, 1 star for easy, 3 stars for hard. We want to have a reason to go back and play
again."

Note: a separate task (P7-T1) is raising shot make rates right now. Shooting will matter a bit more after it, so the
numbers in part 2 get one more QA check once P7-T1 is in.

## 1. How progression works today (1.0.0)

**Points.** Every win gives the crew 2 stat points, put in one shared pool. That counts all 3 city games and the
New York rounds. One point = +3 on one stat of any player on your roster, starters or bench. You spend them on the
STAT POINTS screen after a city's boss game (and between New York rounds). Unspent points are kept. A loss gives
nothing and you replay the same game, with no penalty.

**Cap.** No stat goes above 90 by points. Some starting ratings are already higher, and they are not lowered. There
is no cap per player: all the points can go to one man.

**Totals over a trip.** 7 cities x 3 wins x 2 = 42 points (+126 rating) before New York, plus 2 after the
quarterfinal and 2 after the semifinal. The 2 points from the final come after the trip is over, so they are wasted.

**Your underdogs start at** (speed / shooting / finishing / defense / stamina):
Deuce 52/62/48/48/50, Jojo 62/50/46/50/54, Tank 42/38/62/58/48. Each one averages about 50.

**The city ramp.** Every city player is built from his city's "stage average":

| City | Hometown | Chicago | Memphis | New Orleans | Denver | Seattle | Los Angeles | New York |
|---|---|---|---|---|---|---|---|---|
| Stage average | 40 | 45 | 50 | 54 | 58 | 62 | 66 | 70 |
| Good player (2 specialties) | 44 (56) | 49 (61) | 54 (66) | 58 (70) | 62 (74) | 66 (78) | 70 (82) | 74 (86) |
| Boss (every stat) | 60 | 65 | 70 | 74 | 78 | 82 | 86 | 90 |

A recruit joins with the ratings he had in his city. A Los Angeles boss joins at 86 in every stat, which is stronger
than anything points can make out of an underdog.

**A fully built crew at New York.** The QA "expected roster" spends every point on the lowest stat of the first
player, so all 42 go to Deuce. He reaches 76/77/78/78/77 (average 77). Jojo and Tank stay at about 50. Your 3 starters
then average about 60, against New York crews that average 70 to 90. The real strength of a late-trip crew comes from
recruits (7 of them on the bench, the late ones at 70 to 86). The level (Easy / Normal / Hard) only changes how sharp
the CPU plays. It does not change the points or any ratings.

## 2. Proposed new progression

**Who gets points.** After every win, each of the 3 starters gets his own points. The bench doesn't, because only the
3 starters play a game (there are no subs during a game). A bench player earns points by starting a game. This
gives you a reason to rotate recruits in. Points are kept per player. One point is still +3 on one stat of that
player.

**How many (recommended, Q1 a):** 1 point per starter for a win in city games 1 and 2. 2 points per starter for the
boss game and for each New York round. That is 4 points per starter per city (12 for the crew, double today's 6).

**When.** A short STAT POINTS screen comes after every win. It shows only the 3 players who just earned points, so
it takes about 10 seconds. You can also skip it, and the points wait (a "points to spend" badge on the lineup screen).
Points left over from a 1.0.0 save stay as "crew points" that you can spend on anyone, like today.

**Caps.** A stat still can't go above 90 from points. There is no extra cap per player on the trip, because 4 points
per city already limits it: a starter can gain at most +12 per city. A per-player "potential" cap is only needed if
replays or New Game+ come later (part 4).

**Levels.** Recommended (Q2 a): the same points on Easy, Normal and Hard. The level already makes the CPU sharper,
and stars (part 3) are the reward for playing on Hard. Giving more points on Hard would make Hard easier later in the
trip, and Easy players are the ones who need the help most.

**Losses, retries and farming.**
- A loss gives no points, as today. The retry pays normally when you win it.
- Each game pays points only once per trip. The save remembers which games have paid ("chicago:2"). Any replay
  feature we add later (part 4) pays stars, never points again.
- Changing the level in the middle of a trip is allowed. The star records the level you won on.
- Rotating bench players so everyone gets points is fine. That's the point of the system.

**The ramp has to rise.** With 3 starters earning, the starting three average about 68 at New York instead of
about 60 (the QA rule, every game won the first time). The extra strength grows about +1.2 per city, so the stage
averages should grow by the same amount:

| City | Hometown | Chicago | Memphis | New Orleans | Denver | Seattle | Los Angeles | New York |
|---|---|---|---|---|---|---|---|---|
| Stage average today | 40 | 45 | 50 | 54 | 58 | 62 | 66 | 70 |
| Proposed | 40 | 46 | 52 | 58 | 63 | 68 | 73 | 78 |

At 78, the New York boss would be 98. We would cap opponents at 95 or trim the boss bonus late in the trip, and QA
sets the final numbers with `--expected-roster` on all three levels. Recruits join stronger too, because they are
built from the same table. In your Phase 5 check-in you said "leave the ramp as is". This change is only needed
because points grow, so it rides on your answer to Q1. If you pick Q1 b (1 point per win, about +4 at New York), the
ramp needs only about half of this.

**Worked example: Deuce on a Hard trip** (recommended rule; he starts every game and you build him as a shooter):

| When | Points earned | Speed / Shooting / Finishing / Defense / Stamina | Average |
|---|---|---|---|
| Start | 0 | 52 / 62 / 48 / 48 / 50 | 52 |
| After Chicago | 8 (6 shooting, 2 speed) | 58 / 80 / 48 / 48 / 50 | 57 |
| After Denver | 20 (+3 shooting, +4 speed, +3 finishing, +2 stamina) | 70 / 89 / 57 / 48 / 56 | 64 |
| At New York | 28 (+1 shooting to the 90 cap, +4 defense, +3 finishing) | 70 / 90 / 66 / 60 / 56 | 68 |

He gets +2 more after the quarterfinal and +2 after the semifinal. Jojo and Tank grow the same amount if they start
too. Today, a Deuce who got all of the crew's points would be at 77, but Jojo and Tank would still be at 50. On Easy
or Normal the numbers are the same (the level changes the CPU, not the points).

## 3. The star system

**What a star is attached to (recommended, Q3 a): each city game and each New York round.** Win it on Easy for 1
star, Normal for 2, Hard for 3. Only the best result counts. 7 cities x 3 games + 3 rounds = 24 games, so 72 stars in
all. Per game is clearer than per city: a hard boss game on Easy doesn't wipe out the two games you won on Hard.

**Optional extra goals (options only, not proposed for the first build):**
- a "clean" star: the city won with no losses;
- a "blowout" star: won by a third of the target or more (4 in a game to 11, 7 in a game to 21);
- a "defense" star: the opponent kept under half the target;
- a "player" star: the human player scored a set number of dunks or steals in the game.

Each one would show as a small extra mark next to the level stars, so the 1 / 2 / 3 rule stays simple.

**Where stars show.**
- Map pins: up to 9 small stars under each city ("7/9"), and 9 for New York.
- The result screen: "NEW STAR" or "NEW BEST: 3 STARS" after a win.
- The title: "STARS 41/72" next to ROAD TRIP.
- Quick Game (an option, Q3 c): stars for each opponent crew you beat, on the OPPONENT button.

**Kept for good.** Stars live with the court and team unlocks (saved in the settings, not in the trip). A NEW TRIP
keeps them, so a second trip on Hard is a way to earn the stars you missed.

**What stars unlock (Q4, options):**
- bonus stat points at star milestones (for example, every 6 stars = 1 point for every roster player in your current
  trip);
- cosmetics: alternate jerseys for your crew or a special ball at 24, 48 and 72 stars (new palettes from the art
  scripts);
- a LEGEND level once every game has 3 stars: opponents with higher ratings (today's Hard is already the sharpest
  CPU);
- the beaten crews in Quick Game with their real trip ratings instead of the evened-out 50s.

**Replaying with today's linear trip.** Today the route is fixed and a beaten city is never replayed (your Phase 5
answer: "no replays"). Stars need a way back. The options are in Q5:
- replay a beaten city's games from the map at any time, with opponents raised to the stage you have reached so it
  stays a challenge (pays stars only);
- a city select after the trip is finished;
- New Game+: a new trip that keeps your crew, against stronger opponents;
- no replays: you earn stars only by starting a new trip.

## 4. Roadmap

**Phase 8: Progression (points after every win, stars).**

| Item | Size | Files | Save notes |
|---|---|---|---|
| Points per starter after every win, paid once per game | M | `trip.gd`, `save.gd` | Save version 1 -> 2: each roster entry gets `pts`, the trip gets `paid` (games already paid). A 1.0.0 save loads: its pool becomes the crew points, every beaten game counts as paid. A 1.0.0 build opening a version 2 save warns, loads, and loses the per-player points (it already loads "what fits") |
| Catch-up for 1.0.0 saves mid-trip (the ramp rises) | S | `trip.gd` | One-time grant on the first load of a version 1 save (for example, +2 crew points per beaten city) |
| STAT POINTS after every win, skip, lineup badge | M | `after_game.gd`, `lineup.gd` | none |
| Ramp retune | M (mostly QA) | `cities.gd`, `trip.gd` (expected roster) | Recruits already on a roster keep their saved ratings |
| Star store and rules | S | new `scripts/stars.gd` | New section in `settings.cfg` (the test file in test runs), like the unlocks. Not in `trip.json` |
| Stars on the map, result and title | M | `trip_map.gd`, `after_game.gd`, `title.gd` | none |
| A star sound and a stat-up sound | S | `tools/`, `assets/sfx/` | none |
| How to Play trip page text | S | `howto.gd` | none |

**Phase 9: Reasons to replay.**

| Item | Size | Files | Save notes |
|---|---|---|---|
| Replay beaten city games from the map (scaled opponents, stars only) | M | `trip.gd`, `trip_map.gd`, `flow.gd`, `after_game.gd` | `trip.json` gets a "replaying" marker, so CONTINUE resumes right; it must never move the trip's own city or game |
| Star rewards (whichever Q4 picks) | S-M | `stars.gd`, `after_game.gd` or `tools/art` + `cities.gd` palettes | Rewards claimed are kept with the stars |
| Quick Game stars per opponent crew | S | `menu.gd`, `main.gd` (game over), `stars.gd` | Same section as the trip stars |
| New Game+ (keep the crew, opponents +X) | L | `trip.gd`, `title.gd`, `cities.gd`, `save.gd` | `trip.json` version 3: an `ng_plus` count; per-player potential caps start to matter here |
| LEGEND level | M | `difficulty.gd`, `cities.gd`, `title.gd` | A new level name in `trip.json`. An older build resets an unknown level to Normal (`from_dict`), which is safe |

**Phase 10: Growing players in new ways.**

| Item | Size | Files | Save notes |
|---|---|---|---|
| Challenge games: one goal per city game ("win with 5 dunks") for a bonus point | M | new `challenges.gd` (data), `after_game.gd`, `main.gd` (stats it already counts) | Completed challenges kept with the stars |
| Training mini-games: a shooting drill and a free-throw contest that pay a small capped bonus | L | new mode in `main.gd` plus a new screen script | Per-player training caps in `trip.json` |
| Player levels and badges (XP from in-game stats, "Sniper", "Lockdown") | M-L | `trip.gd`, `ratings.gd`, `after_game.gd`, `lineup.gd` | Per-player `xp` and `badges` in `trip.json`. Badges must stay small and visible, to keep "skill over dice" |
| Season or ladder: a Quick Game ladder through every unlocked crew, with a record | L | new screen script, `menu.gd`, `flow.gd` | Its own save file, so the trip save stays one trip |

## 5. Recommended order for Phase 8 (proposed tasks; BOARD.md is not changed yet)

Everything waits on your answers to Q1-Q5. The ramp work also waits for P7-T1 (shot rates) to be merged.

| Id | Owner | Files | Done when | Depends |
|---|---|---|---|---|
| P8-01 | qa | `docs/qa/fixtures/` (new) | Two 1.0.0 saves (mid-Chicago with crew points, New York between rounds) captured from today's build and committed | none |
| P8-02 | gameplay | `trip.gd`, `save.gd` | Wins pay each starter's own `pts` (constants at the top of `trip.gd`), each game pays once, spending takes a player's own points first and then crew points, save version 2, the P8-01 saves load with a catch-up grant; `--triptest-data` passes | P8-01, Q1, Q2 |
| P8-03 | gameplay | `scripts/stars.gd` (new), one flag line in `main.gd` | Best level per game kept for good (in the test file in test runs); `--startest` prints STARTEST OK | Q3 |
| P8-04 | gameplay | `trip.gd` | `after_result()` goes to the points screen after every win, then the lineup; CONTINUE resumes there; each win records its star (`last_outcome.new_star`) | P8-02, P8-03 |
| P8-05 | gameplay | `after_game.gd` | Points screen in per-win mode (the 3 starters, their own points, SKIP), crew points line, NEW STAR on the result | P8-04 |
| P8-06 | gameplay | `lineup.gd` | "points to spend" badge on the lineup cards, which opens the points screen | P8-02 |
| P8-07 | gameplay | `trip_map.gd` | Stars under each pin, the city total | P8-03 |
| P8-08 | gameplay | `title.gd` | STARS n/72 on the title; per-player points on CREW | P8-03 |
| P8-09 | art-audio | `tools/make_twist_sfx.py` (or a new script), `assets/sfx/star.ogg`, `stat_up.ogg` | Synthesized sounds, `CREDITS.md` row "original" | none |
| P8-10 | gameplay | `trip_test.gd` | `--trip-test` takes the per-win points screen, checks stars and paid games; TRIP END | P8-05 |
| P8-11 | gameplay | `trip.gd` (`expected_roster` follows the new rule) | `--expected-roster` prints the new crews | P8-04 |
| P8-12 | qa + gameplay | `cities.gd` | New `STAGE_AVG` and the boss cap from `--expected-roster` sims on Easy, Normal and Hard (40+ games per city); win shares near today's | P8-11, P7-T1 |
| P8-13 | gameplay | `howto.gd` | Trip page text mentions points after every win and stars | P8-05 |
| P8-14 | qa | `docs/qa/phase8.md` | Trip test on 3 levels, resume, backtest, both 1.0.0 saves, autoplay unchanged (no sim change) | all |

Tasks that can run at the same time (no shared files): P8-01, P8-03 and P8-09 first. Then P8-02, P8-07 and P8-08.

## 6. Questions for you

**Q1. How many stat points does a win give?**
- a) 1 point to each starter for city games 1 and 2, 2 points each for the boss game and the New York rounds (4 per
  starter per city) **(recommended)**
- b) 1 point to each starter for every win (3 per starter per city)
- c) 2 points to each starter for every win (6 per starter per city; the ramp must rise a lot)
- d) Keep today's 2 shared points per win, but spend them after every game instead of after the city

**Q2. Should the level (Easy / Normal / Hard) change the points?**
- a) No: the same points on every level, and stars are the reward for Hard **(recommended)**
- b) Hard gives +1 point per starter for a win
- c) Easy gives +1 point per starter for a win (help for players who struggle)

**Q3. What are stars attached to?**
- a) Each city game and each New York round: 1 star on Easy, 2 on Normal, 3 on Hard, best result kept (72 in all)
  **(recommended)**
- b) Each city: the level you won all 3 of its games on (24 in all)
- c) Like a), plus Quick Game stars for each opponent crew you beat

**Q4. What should stars unlock?**
- a) Bonus stat points at star milestones (for example, every 6 stars = 1 point for every player on your roster)
  **(recommended)**
- b) Cosmetics: alternate jerseys and a special ball at 24, 48 and 72 stars
- c) A harder LEGEND level once every game has 3 stars
- d) Nothing: the stars are just for showing off

**Q5. How do you go back to earn stars you missed?**
- a) Replay any beaten city game from the map at any time; opponents are raised to the stage you have reached; it
  pays stars only **(recommended)**
- b) After the trip is finished: a city select with your finished crew
- c) New Game+: a new trip that keeps your crew, against stronger opponents
- d) No replays: start a new trip to earn more stars

**Q6. When should this ship?**
- a) Upload 1.0.0 to itch.io now as it is, and ship progression as the 1.1 update (1.0.0 saves carry over)
  **(recommended)**
- b) Hold the itch.io upload until Phase 8 is done
- c) Upload now, add only the points after every win (Q1) as a quick 1.0.1, and add stars in 1.1
