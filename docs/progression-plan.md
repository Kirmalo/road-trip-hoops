# Progression plan: stat points after every win, stars, rewards and replays (Phase 8)

Planning document (lead-producer, 2026-11-17). Updated the same day with the owner's answers to Q1-Q6 (VISION row
"Progression plan answers"). The tasks are on `docs/BOARD.md` (Phase 8). Four smaller questions are still open
(part 9). No game code has changed yet.

The owner asked for "stat allocation after each match instead of just after boss matches. Any player who played in
a win should get stats or a stat. Also, there should be a star system for beating levels, 1 star for easy, 3 stars
for hard. We want to have a reason to go back and play again."

A separate task (P7-T1) is raising shot make rates in every mode right now. The ramp retune (part 6) waits for it.

## 1. How progression works today (1.0.0)

- **Points.** Every win gives the crew 2 stat points, all in one shared pool. One point = +3 on one stat of any
  roster player. They are spent on the STAT POINTS screen after a city's boss game and between New York rounds.
  A loss gives nothing and you retry the game. No stat goes above 90 from points.
- **Totals.** 7 cities x 3 wins x 2 = 42 points before New York, +2 per New York round.
- **Roster.** The 3 underdogs plus one recruit per city (a good player or the boss): 10 players at New York.
  Before each game you pick 3 starters. Today you may start 3 recruited bosses.
- **The ramp.** Every city player is built from his city's stage average (40, 45, 50, 54, 58, 62, 66, 70 from
  Hometown to New York). Good players get +12 in two specialties, the boss +20 on everything. A recruit joins with
  the ratings he had in his city.
- **Level.** Easy / Normal / Hard only changes how sharp the CPU plays. It changes no points and no ratings.
- **Replays.** None: the route is fixed and a beaten city is never played again.

## 2. Stat points after every win (answered: Q1 a, Q2 a)

- After every win, each of the 3 starters gets his own points: **1 point for city games 1 and 2, 2 points for the
  boss game and for each New York round** (4 per starter per city). The bench gets nothing; a bench player earns
  points by starting. The same on Easy, Normal, Hard and LEGEND.
- One point is still +3 on one stat of that player; the 90 cap stays. Points are kept per player.
- **Each game pays once per trip.** The save keeps the games that have paid ("chicago:2"). Replays (part 5) pay
  stars only.
- **When.** A short STAT POINTS screen after every win shows only the 3 starters who just earned points (about 10
  seconds). SKIP keeps the points for later; a "points to spend" badge on the lineup screen opens the screen again.
- **1.0.0 saves.** The old shared pool becomes "crew points", spendable on anyone, like today. A one-time catch-up
  pays what the new rule would have paid on top: +6 crew points per beaten city and +4 per won New York round.

## 3. Stars (answered: Q3 a)

- Each city game and each New York round: win it on Easy for 1 star, Normal 2, Hard 3 (LEGEND also 3). Only the best
  result counts. 24 games, **72 stars** in all.
- Stars are kept for good (in `settings.cfg`, like the court and team unlocks, never in the trip save). A NEW TRIP
  keeps them. Trip tests keep theirs in the test file.
- Shown under each map pin ("7/9"), on the result screen ("NEW STAR", "NEW BEST: 3 STARS", and any reward just
  unlocked) and on the title ("STARS 41/72").
- **1.0.0 saves** have no star record. On the first load, every game already won is credited at the save's current
  level (a replay can raise it).

## 4. What stars unlock (answered: Q4, the owner's own mix; no bonus stat points)

### The ladder (recommended values; the slot milestones are part 9 Q1)

| Stars | Reward |
|---|---|
| 6 | Jersey 1 |
| 12 | Roster slot 1 |
| 18 | Ball 1 |
| 24 | Roster slot 2, van paint 1 |
| 30 | Quick Game court look 1 |
| 36 | Roster slot 3, jersey 2 |
| 42 | Ball 2 |
| 48 | Roster slot 4, van paint 2 |
| 54 | Jersey 3 |
| 60 | Quick Game court look 2, ball 3 |
| 66 | Van paint 3 |
| 72 | LEGEND level |

A first trip earns 24 stars on Easy, 48 on Normal and 72 on Hard, so a full Normal trip opens every slot, and a full
Hard trip opens everything. The ladder is one data table at the top of `scripts/stars.gd`.

### Extra roster slots and the draft

- **Roster size.** Today: 3 underdogs + up to 7 recruits = 10. With 4 slots: up to **14** (part 9 Q1 sets the
  count). The lineup list already scrolls (2 cards per row).
- **What a slot is.** Each open slot holds one drafted player for the current trip. Slots come from stars, so they
  are kept for good, but the players drafted into them belong to the trip: a NEW TRIP starts with empty slots.
- **Who can be drafted.** Any player of a crew you have beaten, bosses and average players included, minus anyone
  already on the roster. Recommended: crews beaten on this trip only (part 9 Q2), so a second trip can't put a Los
  Angeles boss in Hometown. A New York crew counts as beaten once its round is won (draft between rounds).
- **Where.** An empty slot shows as an OPEN SLOT card on the lineup screen. Tapping it opens a new DRAFT screen
  (`scripts/draft.gd`): the beaten crews' players as cards (like the recruit screen), SIGN, BACK. A draft is final
  for the trip (part 9 Q2 c asks about releasing).
- **His stats.** He joins like a recruit: his ratings at his own city's stage, in your colors (every city and New
  York player gets a blue-and-gold recolor, made by the art script), with 0 points. From then on he earns points
  like anyone who starts.
- **No boss limit (for now).** The owner chose to skip a one-boss rule: any players can start, as today.

### Cosmetics

All original, made by the `tools/art` scripts in the approved style, never copied from any game, team or brand. A
preview sheet goes to the owner at the check-in; a generator rerun changes any of them.

| Kind | How many | Made by | Used |
|---|---|---|---|
| Alternate jerseys | 3 | `make_players_v2.py`: palettes `<sheet>_j<N>` / `<sheet>_crew_j<N>` for every player who can wear your colors | your crew on the trip, the Kings in Quick Game |
| Special balls | 3 | `make_courts.py`: `assets/ball/ball_<N>.png` (same 4 spin frames) | every game |
| Van paint jobs | 3 | `make_map.py`: `assets/map/van_<N>.png` | the trip map |
| Quick Game court looks | 2 | `make_courts.py`: new floor and backdrop, rows in `court_looks.gd` | added to the Quick Game COURT button (no twist) |

Where jerseys, balls and vans are picked is part 9 Q3 (recommended: a new LOCKER screen from the title that also
shows the whole ladder). Court looks need no picking: once open they join the COURT button.

### LEGEND level

- Opens at 72 stars (every game 3 stars). Then it is a fourth level everywhere a level is picked (Settings, new
  trip, Quick Game).
- The CPU plays like Hard (today's sharpest) and the opponents' ratings get a bonus (`LEGEND_BONUS`, start +6 on
  every stat, cap 95; QA tunes it). A LEGEND win gives 3 stars, like Hard. The points are the same as on every level.
- An older build that meets "legend" in a save falls back to Normal (it already does that for unknown levels).

## 5. Replays from the map (answered: Q5 a; moved into Phase 8)

- Tap a beaten city's pin: its 3 games show with their stars; pick one, then the lineup, then the game.
- Opponents are raised to the **stage reached** (the trip's current city; 8 once the trip is over): the city's
  own crew, tiers, target, court, twist and music, with the ratings of that stage.
- **Stars only.** No points, no recruit, no story scenes, no unlocks, and the trip's win/loss record stays as it is.
  A loss costs nothing. After the result, back to the map.
- A replay never moves the trip's own city, game or bracket. The save carries a `replay` marker so CONTINUE resumes
  the right place if the app closes in the middle.
- New York rounds become replayable once they are won. After the ending, CONTINUE opens the map in replay mode
  (today it goes to the title).

## 6. The ramp, re-planned with drafting

What makes your three stronger at city N, compared with today:
1. **Points per starter:** +2.4 average per starter per city instead of today's +1.2 (the crew gets 12 points per
   city instead of 6).
2. **Drafting:** up to 4 extra players, which adds choice but not a new top end. Drafted players are no stronger
   than recruits from the same city.
3. **The one-boss rule lowers the top end.** Today a crew may start 3 recruited bosses; now the strongest legal three
   is the newest boss plus the 2 best good players.

QA measures two bounds, on Easy, Normal, Hard and LEGEND:
- **Lower bound** `--expected-roster` (today's rule, updated): the 3 underdogs start every game and get every
  point they earned; no recruits or drafts.
- **Upper bound** `--best-roster` (new): the strongest legal three from the recruits and drafts a trip could have
  there (newest boss + 2 best good players), with the points the starters would have earned.

Starting point for the stage averages (QA sets the final numbers):

| City | Hometown | Chicago | Memphis | New Orleans | Denver | Seattle | Los Angeles | New York |
|---|---|---|---|---|---|---|---|---|
| Stage average today | 40 | 45 | 50 | 54 | 58 | 62 | 66 | 70 |
| Starting point | 40 | 46 | 52 | 58 | 63 | 68 | 73 | 78 |

The New York boss would be 98, so a `BOSS_CAP` (start 95) caps every opponent stat. Targets: the lower bound keeps
roughly today's win shares on each level (`docs/qa/phase6.md`); the upper bound on Hard still loses some games
(RED wins at least about 20%). Recruits and drafted players are built from the same table, so they join stronger
too; players already on a 1.0.0 roster keep their saved ratings. Replays use the same table at the stage reached.
The Phase 5 check-in said "leave the ramp as is"; this change follows only from the points now growing (Q1).

## 7. Saves

- **`trip.json` version 2.** Each roster entry gets `pts` (his unspent points) and `via` (`start`, `recruit`,
  `draft`); the trip gets `crew_points` (from a 1.0.0 pool and the catch-up), `paid` (games that have paid) and
  `replay` (`{}` or `{"city", "game"}`). The level may be `legend`.
- **A 1.0.0 save loads** (part 2 catch-up, part 3 star credit, part 4 boss repair). QA commits 1.0.0 save fixtures
  first and tests every one.
- **A 1.0.0 build opening a version 2 save** warns and loads what fits (it already does): the per-player points and
  the replay marker are lost, drafted players stay, LEGEND becomes Normal. Not a crash.
- **Stars, rewards and cosmetic picks** live in `settings.cfg` (sections `stars` and `cosmetics`), the test file
  in test runs.

## 8. Later (not in Phase 8, nothing decided)
Quick Game stars per crew (Q3 c, not picked), extra star goals (clean sweep, blowout), New Game+, challenge games,
training drills, player badges, a Quick Game ladder. Each would be its own owner question.

## 9. Questions for the owner (answered: Q1 a, Q2 a, Q3 a; Q4 version asked later; the one-boss rule skipped)

**Q1. How many extra roster slots, and at which star counts?**
- a) 4 slots at 12, 24, 36 and 48 stars; the roster grows to at most 14 (a full Normal trip opens all four)
  **(recommended)**
- b) 6 slots, one every 12 stars (12 to 72); the roster grows to at most 16
- c) 3 slots at 24, 48 and 72 stars; the roster grows to at most 13
- d) 2 slots at 36 and 72 stars; the roster grows to at most 12

**Q2. Which players can a slot draft?**
- a) Any player from a crew beaten on this trip; a draft is final for the trip **(recommended)**
- b) Any player from a crew you have ever beaten (like the Quick Game team unlocks), even at the start of a new trip
- c) Like a), but you can also release a drafted player to free his slot for someone else

**Q3. Where do you pick the jersey, ball and van paint?**
- a) A new LOCKER screen from the title: the star ladder (what you have, what's next) and the three picks; court
  looks join the Quick Game COURT button **(recommended)**
- b) Three more rows in Settings; the star ladder on CREW & CREDITS; court looks on the COURT button
- c) Where each is used: jersey on the lineup screen, van on the trip map, ball and court on the Quick Game panel

**Q4. Which version number does the first public release (with Phase 8) get?**
- a) 1.1.0 (Android version code 2): your tablet and the test site already show 1.0.0, so the new number tells the
  builds apart **(recommended)**
- b) 1.0.0: it is still the first public release
- c) 2.0.0: mark it as a big update
