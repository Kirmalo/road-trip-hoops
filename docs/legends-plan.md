# Legends plan: an era tour to unlock original legends (long-term, after Phase 8)

Planning document (lead-producer, 2026-11-18). It follows the owner's VISION row "Legends (long-term)". Nothing here
is decided beyond that row: the numbers, names and rules below are a **first draft** for the owner to change, and
part 9 asks the questions that decide the rest. Timing: the owner decides after Phase 8. No game code has changed.

## 1. The hard rule: every legend is our own character

Legends are **original archetype characters**. They are built on classic *play styles* (the hook-shot center, the
high flyer, the crossover artist), never on a real person. For every legend, court, card and story line:

- **No real player's name or nickname**, not even a well-known nickname on its own (no "Air", "Magic", "Dream",
  "Mailman", "Answer", "Admiral", "Glove", "Black Mamba", "Greek Freak", "Chef", no "King" as a nickname). A name
  check against a list of real NBA and ABA players and their nicknames is part of the roster task, before any art.
- **No real faces or likenesses.** Looks come from the generator's parts (body, skin, hair, outfit) mixed freely,
  never tuned to resemble someone. Signature accessories that point at one real player (his goggles, his single arm
  sleeve plus his number, his famous headband style) are out.
- **No real numbers tied to a player, and no real team colors plus a number.** Legend jerseys use era colors we
  invent; numbers are picked by script from a list the owner approves, never a famous player's number in his team's
  colors.
- **No signature trademarks or brand marks**: no logos, shoe brands, trademarked move names or slogans. Moves are
  named in plain basketball words ("hook shot", "step-back", "chase-down block").
- **No real teams, arenas or leagues.** Courts are made up, like the city courts.
- **The owner's reference picture** (fan art of real players across generations) is **inspiration for the mood
  only**: the idea of eras and of grandfathers, fathers and sons. It is never traced, copied, used as an asset or
  shown to an art script. Art is made by the `tools/art` scripts in the approved style, as always.

A review rejects any change that breaks this rule, the same way it rejects an asset without a license.

## 2. The mode loop

**Where:** a new LEGENDS button on the title opens the **era tour**: a timeline of four chapters (like the trip map,
one pin per era). Each chapter has its own court, music, era rules and 6 legends.

| Chapter | Feel | Court | Era rules (part 4) |
|---|---|---|---|
| 1. Grandfathers | Old school: short shorts, tall striped socks, headbands | Wood gym with banners | Rougher defense, slower pace, big men rule |
| 2. Fathers | The 2000s: baggy shorts, arm sleeves, cornrows | Blacktop under lights | Isolation scorers, high flyers |
| 3. Present | Modern | Arena | Spacing, step-backs, more long shots |
| 4. New Generation | Bold and neon | Futuristic court | The fastest pace |

**A chapter, step by step:**
1. An intro story scene (portraits and text, like the trip's arrival scenes).
2. **6 challenge games**, one per legend, in any order. Win one and that legend is **unlocked**: a short unlock
   scene (he speaks, like a recruit's joining line), his card goes into the Hall of Legends.
3. **The era finale**, opened once all 6 are beaten: your crew against the era's three best legends, to 21, under
   the era rules. Winning it closes the chapter and opens the next one (if the tokens allow, part 5).

**Challenge types** (each challenge is one row of data; a legend's challenge fits his skill):

| Type | Goal | Example |
|---|---|---|
(Shipped Chapter 1 goal numbers: see `scripts/legends_data.gd` and docs/qa/phase9-challenges.md, P9-26.)

| Hold him | Win while the legend scores fewer than N points | Hold the hook-shot center under 6 |
| Beat the fire | He starts on fire and cools down only on two misses in a row; win | The deep shooter |
| One on one | 1-on-1 to 11, you against him | The crossover artist |
| Stop the move | Block or steal his signature move N times and win | The high flyer: 3 blocks |
| Race | Reach N before his team reaches M | The speedster: 11 before he gets 7 |
| Comeback | Start down 0-6 in a game to 15 | The no-look passer's crew |

Games are short: to 11 or 15 (finales to 21). With retries a chapter is about 7 games and 45-60 minutes, so **the
whole tour is about 3-4 hours**, about as long as the Road Trip, and longer for a player who chases 3 tokens
everywhere (part 5).

## 3. First draft roster (4 eras x 6 legends; every name is a placeholder for the owner to rename)

Rating shape = how his five stats sit around his level (speed, shooting, finishing, defense, stamina; the offsets
add up to 0). The level itself depends on where he plays (part 5), so a shape never breaks the balance on its own.

### Chapter 1: Grandfathers
| Legend | Archetype | Look notes | Signature move | Shape (spd/sht/fin/def/sta) |
|---|---|---|---|---|
| Ezekiel "Steeple" Oakhurst | Hook-shot center | Very tall and wiry, mutton chops, headband | High hook over the defender (hard to block) | -15 / 0 / +20 / +5 / -10 |
| Augustus "Gate" Fenwick | Shot-blocking wall | Broad big, flat-top, knee pads | Block that stays in play (he keeps it or tips it to a teammate) | -10 / -15 / +5 / +25 / -5 |
| Harlan "Set Shot" Vickery | Deep shooter, old style | Lean, side part, tall socks | Two-hand set shot from deep | -5 / +25 / -10 / -5 / -5 |
| Cornelius "Boxcar" Dunmore | Bruising power forward | Heavy, bald, wristbands | Power drop-step to a two-hand dunk | -10 / -10 / +20 / +10 / -10 |
| Desmond "Velvet" Ashby | Smooth slasher | Long, afro with a headband | Soaring finger roll | +10 / -5 / +15 / -10 / -10 |
| Otis "Quarterback" Brannigan | No-look floor general | Short, mustache, high socks | Full-court outlet pass for a lay-in | +5 / +5 / -10 / 0 / 0 |

### Chapter 2: Fathers
| Legend | Archetype | Look notes | Signature move | Shape |
|---|---|---|---|---|
| Dorian "Rooftop" Vance | High-flying shooting guard | Lanky, cornrows, arm sleeve, baggy shorts | Cradle dunk (ball rocked in the arm in the air) | +10 / 0 / +15 / -10 / -15 |
| Tremaine "Ankles" Pettaway | Crossover artist | Small and quick, braids, headband | Double crossover (more ankle-breaker falls) | +15 / +5 / -5 / -5 / -10 |
| Darnell "Midrange" Kingsley | Isolation scorer | Wiry wing, fade haircut, long shorts | Turnaround fadeaway | 0 / +20 / 0 / -10 / -10 |
| Bartholomew "Freight" Thackeray | Low-post bulldozer center | Huge, goatee, headband | Shoulder-in power dunk | -15 / -15 / +25 / +10 / -5 |
| Keon "Eyes Closed" Ridley | No-look passer | Slim, durag, wristbands | No-look and behind-the-back passes | +5 / 0 / -5 / -5 / +5 |
| Shane "Lockbox" Hollister | Lockdown wing defender | Rangy, buzz cut, arm sleeve | Chase-down block from behind | +5 / -10 / -5 / +20 / -10 |

### Chapter 3: Present
| Legend | Archetype | Look notes | Signature move | Shape |
|---|---|---|---|---|
| Calloway "Deep End" Briggs | Step-back shooter | Slim guard, beard, tight shorts | Step-back from deep | +5 / +25 / -10 / -10 / -10 |
| Theo "Swiss Knife" Lindqvist | Point-forward | Big and strong, man bun | Coast-to-coast drive and kick | +5 / 0 / +5 / 0 / -10 |
| Ozren "Stretch" Halvorsen | Stretch big | Seven-footer, shaggy hair | Pick-and-pop long shot | -10 / +15 / 0 / +5 / -10 |
| Idris "Switch" Achterberg | Two-way wing | Long arms, short twists | Steal straight into a breakaway | +5 / -5 / 0 / +15 / -15 |
| Bodie "Skylight" Ferreira | Rim-running big | Athletic, high-top fade | Alley-oop slam from anywhere near the rim | 0 / -20 / +20 / +5 / -5 |
| Santi "Zigzag" Moreau | Slasher | Slim, curly hair, headband | Euro-step layup | +10 / -5 / +10 / -10 / -5 |

### Chapter 4: New Generation
| Legend | Archetype | Look notes | Signature move | Shape |
|---|---|---|---|---|
| Kai "Hyperdrive" Starling | Speedster point guard | Small, neon dyed hair | Turbo burst past the defender | +25 / 0 / 0 / -10 / -15 |
| Atlas "Long Shadow" Varga | Seven-foot guard | Very tall, locs tied up | Step-back over a smaller defender | 0 / +10 / +5 / +5 / -20 |
| Juno "Glitch" Takeda | Trick handler | Slim, two-tone hair | Between-the-legs into behind-the-back combo | +15 / +5 / -5 / -5 / -10 |
| Rocco "Pogo" Delacroix | Highest leaper | Wiry, mohawk | Putback tip-dunk off a miss | +5 / -15 / +20 / +5 / -15 |
| Orion "Halfcourt" Mbeki | Unlimited range | Lean, plain headband, beard | Shots from far past the arc | 0 / +25 / -10 / -5 / -10 |
| Dex "Firewall" Adeyemi | Guards everyone | Muscular, buzz cut, neon sleeves | Switch-and-swat block on a guard | +5 / -10 / 0 / +20 / -15 |

The owner's eight archetypes are all in: hook-shot center, high-flying shooting guard, crossover artist,
point-forward, deep shooter (three of them, one per style of era), shot-blocking wall, bruising power forward,
no-look passer. Ages and story: grandfathers, fathers and sons only as a theme (a Grandfathers legend can call a New
Generation legend "kid"); they are not related to real families.

## 4. Era rules as twist values

Each era is one twist in `scripts/twists.gd` (one twist per game, the same for both teams, twist "none" stays
today's game). Keys that exist today are used as they are; new keys get a default in `DEFAULTS` that is exactly
today's game, like every hook. Starting values, QA tunes them.

| Era twist | Existing keys | New keys (default = today) |
|---|---|---|
| `era_grand` "OLD SCHOOL" | `speed_mult` 0.94, `long_shot_mult` 0.88 | `foul_mult` 0.6 (fewer fouls called: rougher defense), `inside_mult` 1.08 (layups, dunks and close shots go in more) |
| `era_fathers` "ISO BALL" | `arc_mult` 1.05 | `cross_beat_mult` 1.2 (crossovers beat the defender more), `dunk_reach_mult` 1.1 (dunks from a little further out) |
| `era_present` "SPACE THE FLOOR" | `long_shot_mult` 1.08 | `spacing_ft` 2.0 (off-ball players stand 2 ft wider), `stepback_mult` 1.1 (pull-ups after a move a little better) |
| `era_next` "HYPERSPEED" | `speed_mult` 1.08, `turbo_mult` 1.45, `stamina_refill_mult` 1.2, `shot_clock` 18 | none |

Every new key is one `Twists.value(key, default)` in the sim. None of them reads a team, so the era rules are fair.
An open idea (part 9 is the place to ask, not this list): an old-school "every basket counts 1" rule.

## 5. Unlocks, tokens, the Hall, mentors, the draft and era matchups

**Opening the mode.** Trip stars are the first rung: stars open the chapters. Inside the mode, **legend tokens**
work like stars: a challenge won on Easy gives 1, Normal 2, Hard 3 (LEGEND 3), best kept. 24 challenges and 4 finales
give at most **84 tokens**. Draft gates (part 9 Q2): Chapter 1 at 24 trip stars (a finished Easy trip), Chapter 2 at
36 stars or 12 tokens, Chapter 3 at 48 stars or 30 tokens, Chapter 4 at 72 stars or 48 tokens. Tokens also open a
few Legends-only cosmetics (era jerseys, an era ball), on a ladder like `stars.gd`'s.

**The Hall of Legends** (a new screen from the LEGENDS tour and from CREW & CREDITS): four era rows of six plaques.
A locked legend is a silhouette in an era frame with "?" and his challenge line. An unlocked one shows his card (the
sheet's idle card, in the era's frame), name, archetype, signature move, rating shape and his mentor perk; tapping
REPLAY STORY plays his unlock scene again (portraits, like `story.gd`).

**Mentors.** An unlocked legend can train one of your players: a small permanent perk tied to his skill. Draft list:

(Shipped Chapter 1 values: shot perks +1.5%, the others 5%, owner after P9-30; see `scripts/legends_data.gd` PERKS.)

| Legend | Perk (on one of your players) |
|---|---|
| Steeple (hook shot) | +4% on close shots and layups |
| Gate (blocks) | block timing window 10% wider |
| Set Shot (deep shooter) | +3% on shots beyond the arc |
| Ankles (crossover) | crossovers beat the defender a little more often |
| Lockbox (defense) | steal timing window 10% wider |
| Hyperdrive (speed) | turbo drains 10% slower |
| Eyes Closed (passer) | passes a little faster (fewer interceptions) |
| Boxcar (power) | dunks from a little further out |

Balance limits: **one perk per player**, never stacked; one legend trains at most one player at a time (he can
switch, part 9); a perk is worth about 2 stat points at most and never lifts a stat above the 90 cap; perks change
nothing for the CPU and never apply in a challenge's "hold him" goal numbers. QA's `--best-roster` bound includes the
best perk, so the trip ramp still holds.

**Drafting a legend into the Road Trip.** An unlocked legend joins the draft pool of the star roster slots (the same
DRAFT screen). **At most one legend among the 3 starters**, enforced in `Trip.set_starters()` like the one-boss rule.
Recommended: a legend also counts as the boss (so the three starters hold one boss *or* one legend), and he joins at
the stage reached with a boss's level shaped by his rating shape (capped at `BOSS_CAP`), so the trip ramp is not
broken. Whether legends belong in the Road Trip at all is part 9 Q5.

**Era matchups in Quick Game.** Once three legends of an era are unlocked, an era team ("GRANDFATHERS", ...) joins the
YOUR TEAM / OPPONENT buttons (its 3 best unlocked legends; stats averaged to 50 like the Quick Game crews, so it is a
fair game), and the era's court joins the COURT button with its era rules. Single legends also play in Quick Game: a
legend replaces one player of a team. Grandfathers vs New Generation on any court is the headline matchup.

## 6. Save data

- **A new file `user://legends.json`** (temp file + rename, like `trip.json`; tests use `user://legends_test.json`):
  tokens per challenge, unlocked legends, seen scenes, the chapter reached, mentor pairs (legend -> player). Kept for
  good: a NEW TRIP never touches it.
- **`settings.cfg`** keeps what it keeps today (stars, cosmetics, unlocks). The Legends cosmetic picks go in its
  `cosmetics` section, so the LOCKER stays one place.
- **`trip.json` version 3**: a drafted legend is a normal roster entry (`via: "draft"`, a `lg_` id). A perk lives in
  `legends.json`, not the trip, so it survives a NEW TRIP.
- **Migration.** A 1.x save has no `legends.json`: the mode starts fresh, and stars already earned count at once
  toward the chapter gates. A 1.x build opening a version 3 trip drops the unknown legend id (it already drops
  unknown ids) and keeps the rest; it never reads `legends.json`. QA commits fixtures of 1.0.0 and 1.1 saves.

## 7. The art and animation cost, honestly

What one legend needs today, in the approved pipeline (`tools/art/make_players_v2.py` with the approved sample
`make_anim_sample.py`, the layout in `assets/players2/format.json`):
- **A full player sheet**: 29 animations, 237 frames x 5 directions, 8 indexed pages, about **0.4 MB** each. 24
  legends add about **10 MB** to the download (today about 31 MB). Plus a card and a portrait set (about 3 portraits
  each, `make_portraits_v2.py`).
- **Era outfits** are new generator parts: short shorts, tall striped socks, headbands, baggy shorts, arm sleeves,
  neon trims, plus a few new hair styles (some exist: afro, cornrows, hightop, mohawk, locs). They are drawn once and
  reused by every legend of the era. Medium work in `make_players.py`'s parts and `crews.json`.
- **Signature moves are the expensive part.** Every animation in `format.json` is in every sheet today, so a new
  animation makes all 47 sheets wider. A legend-only move needs an "extra pages" rule in `sheets.gd` (a sheet may
  carry animations the others lack). And a move like the hook shot or the step-back is also new gameplay (a sim
  change), not just drawing. One-on-one is new gameplay too (the game is built for 3 a side).
- **4 era courts** (`make_courts.py`; a floor and a backdrop each, as for a city), 4 era card frames, the Hall and
  tour screens, 4 music tracks (CC0 or CC-BY, chiptune, a listening list first).

Ways to cut it:
1. **Shared bodies**: the 10 existing bodies cover most legends; the hand and ball points are body-keyed, so they
   come free.
2. **Palettes**: era colors and every "your colors" version are palettes only (no new pages).
3. **Reuse animations**: most signatures are an existing move with a twist: the cradle dunk is a dunk style, the
   finger roll a layup, the chase-down a block, the no-look a pass. Only a few need truly new frames.
4. **One signature move per legend**, and at first only in his challenge and when he plays (not on every player).
5. **Fewer legends per era** (4 instead of 6, part 9 Q1) cuts sheets, portraits and scenes by a third.
6. Ship era by era: each phase adds one or two eras.

## 8. Phased roadmap (a draft; timing after Phase 8)

**Phase 9: the Hall, the first era, the challenge system.**
| Task | Size | Files |
|---|---|---|
| Legends data: roster, challenges, chapters, gates (const data) | M | `scripts/legends.gd` (new) |
| Name check against real players (doc and a data check) | S | `scripts/legends.gd`, `docs/legends-plan.md` |
| Legends save and test file | M | `scripts/legends_save.gd` (new) |
| Era twist for the first era plus its new keys | M | `scripts/twists.gd`, the sim hook spots (`main.gd`, `player.gd`, `defense.gd`, `rules.gd`) |
| Challenge goals (hold him, beat the fire, stop the move, race, comeback) | L | `scripts/main.gd`, `scripts/rules.gd` |
| Era tour and Hall screens | M + M | `scripts/legends_tour.gd`, `scripts/hall.gd` (new), `scripts/flow.gd`, `scripts/title.gd` |
| Era outfits and the first era's 6 sheets | L | `tools/art/make_players.py`, `make_players_v2.py`, `crews.json`, `assets/players2/` |
| Era court, card frames, portraits, scenes | M + M | `tools/art/make_courts.py`, `make_portraits_v2.py`, `scripts/court_looks.gd`, `scripts/story_text.gd` |
| Legend-only animation pages (if one signature needs new frames) | M | `scripts/sheets.gd`, `assets/players2/format.json` |
| QA: challenge win shares per level, era rules stats, saves | M | `docs/qa/` |

**Phase 10: the remaining eras, mentors, matchups, the draft.**
| Task | Size | Files |
|---|---|---|
| Eras 2-4: sheets, courts, portraits, scenes, music | L (x3) | as in Phase 9 |
| Era twists 2-4 | M | `scripts/twists.gd`, hook spots |
| One-on-one challenge (if kept) | L | `scripts/main.gd`, `scripts/player.gd`, `scripts/defense.gd`, `scripts/rules.gd` |
| Mentor perks and their screen | M | `scripts/legends.gd`, `scripts/ratings.gd`, a mentor panel in `scripts/hall.gd` |
| Legends in the draft, one-legend rule, version 3 save | M | `scripts/trip.gd`, `scripts/draft.gd`, `scripts/lineup.gd`, `scripts/save.gd` |
| Era teams and legends in Quick Game | M | `scripts/menu.gd`, `scripts/difficulty.gd`, `scripts/trip.gd` (`quick_team`) |
| Ramp and balance QA with legends and perks | M | `docs/qa/` |

## 9. Questions for the owner (answer with the letter)

**Q1. How many legends per era?**
- a) 6 per era, 24 in all (the full plan) **(recommended)**
- b) 4 per era, 16 in all (a third less art and story; ships sooner)
- c) 8 per era, 32 in all (the longest mode, the most art)

**Q2. When does the Legends mode open?**
- a) Chapter 1 with a finished trip on any level (24 stars); later chapters at 36 / 48 / 72 stars or with legend
  tokens **(recommended)**
- b) Only at 72 stars (every trip game on Hard), as the game's true endgame
- c) From the start, beside the Road Trip

**Q3. Which era comes first (Phase 9)?**
- a) Grandfathers: the tour starts at the beginning of the timeline, and its slower, big-man game is the most
  different from today's **(recommended)**
- b) New Generation: the flashiest, the fastest pace
- c) Fathers: the closest to today's streetball look, so the least new art

**Q4. What style of challenge games?**
- a) A mix, chosen per legend (hold him, beat the fire, stop the move, race, comeback), plus one-on-one later
  **(recommended)**
- b) A mix without one-on-one (saves the biggest new game mode)
- c) Always a normal game to 15 or 21 against his crew, no special goals

**Q5. Do legends appear in the Road Trip?**
- a) Yes, through the star roster slots, one legend among the starters, and he counts as the boss (one boss or one
  legend) **(recommended)**
- b) Yes, one legend and one boss may both start
- c) No: legends stay in the Legends mode and Quick Game

**Q6. How strong are the mentor perks?**
- a) Small: about 2 stat points' worth, one per player, a legend trains one player at a time and may switch
  **(recommended)**
- b) Tiny: about 1 stat point's worth, a flavor reward
- c) None: the Hall and the playable legends are reward enough

Answered (VISION "Legends plan answers"): Q1 a, Q2 a, Q3 a, Q4 a, Q5 b, Q6 a.

## Phase 9 open questions (lead-producer, 2026-11-19; answer with the letter, (a) is the recommendation)

Phase 9 builds Chapter 1 end to end (`docs/BOARD.md`).

**Answered (VISION "Phase 9 answers L1-L8", 2026-11-19): L1 a, L2 a, L3 b, L4 a, L5 a, L6 b, L7 a, L8 a.** All eight
are closed. L3 b and L6 b changed the board (challenges with your Road Trip crew; the hook-shot animation, P9-04b and
P9-04c). Technical choices for L3 b, shown to the owner at the check-in: without a trip save the Kings play at even
ratings; the level is picked on the chapter view and opens on the trip's level; a drafted legend never plays against
himself (he sits for that game).

**L1. The six Grandfathers legends** (blocks P9-07 data, P9-09 sheets, P9-10 portraits, P9-14 story; P9-04's look
sample uses one of them)
- a) The six of part 3 as written: Ezekiel "Steeple" Oakhurst (hook-shot center), Augustus "Gate" Fenwick
  (shot-blocking wall), Harlan "Set Shot" Vickery (deep shooter), Cornelius "Boxcar" Dunmore (bruising power forward),
  Desmond "Velvet" Ashby (smooth slasher), Otis "Quarterback" Brannigan (no-look floor general), with the looks and
  rating shapes of part 3; any name the name check flags is swapped and shown to you **(recommended)**
- b) The same six archetypes, but the team proposes two new name sets for you to pick from
- c) You change some of them (tell us which names, archetypes or looks)

**L2. Which challenge each legend gives** (blocks P9-07, P9-13 challenge goals, P9-26 balance)
- a) Steeple: hold him under 6 (game to 15); Gate: race (reach 11 before his crew gets 7); Set Shot: beat the fire
  (to 15); Boxcar: stop the move (3 blocks or steals on him, and win, to 15); Velvet: hold him under 5 (to 11);
  Quarterback: comeback (start down 0-6, to 15); the finale a normal game to 21 **(recommended)**
- b) Every Chapter 1 legend a "hold him" game (one goal type to build and tune first; the others in Phase 10)
- c) A normal game against his crew for all six in Phase 9, the special goals later

**L3. Who plays the challenge games, and how hard are they?** (blocks P9-07, P9-12 matches, P9-13, P9-26)
- a) You play the Cornfield Kings at even ratings (every stat averaging 50, like Quick Game; no trip needed, the same
  every time); the legend plays with 2 other Grandfathers legends as teammates (no new art); the finale is the Kings
  against the era's three best; the level picks the CPU as in Quick Game, and a challenge on Normal should be won
  about as often as a New York game on Normal **(recommended)**
- b) You play your current Road Trip crew and starters (needs a trip save; challenges get easier as your trip grows)
- c) Like a), but the legend's teammates are plain era role players (2 more sheets per era)

**L4. Where is the mode entered, and what exactly opens Chapter 1?** (blocks P9-07 gate data, P9-12, P9-15 title)
- a) A LEGENDS button on the title (shown locked with "24 STARS" until then); Chapter 1 opens at 24 stars from any
  mix of games; the Hall opens from the Legends screen and from CREW & CREDITS **(recommended)**
- b) The same button, but Chapter 1 opens only once a trip is finished (the New York final won), whatever the stars
- c) Inside the ROAD TRIP panel (no new title button), at 24 stars

**L5. The Grandfathers era rules ("OLD SCHOOL")** (blocks P9-08 era twist, P9-17)
- a) As in part 4: everyone 6% slower, long shots go in 12% less, fewer fouls called (60% of today), close shots go in
  8% more **(recommended)**
- b) Only slower and fewer long shots (no new rules in the sim)
- c) As a), plus every basket counts 1 (no 2-pointers in that era)
- d) No era rules in Phase 9 (the era is its court, music and legends only)

**L6. Signature moves in Phase 9** (blocks P9-09 sheets, P9-20 signature moves)
- a) Each legend's move is an existing animation with a small play difference only he has (Steeple's close shots are
  harder to block, Gate's blocks stay in play, Set Shot's long range starts further out, Boxcar dunks from further out,
  Velvet's layups slip past contests, Quarterback throws long outlet passes); no new animation frames
  **(recommended)**
- b) As a), plus one truly new animation (the hook shot) on the legend sheets only (a new "extra pages" rule; more art
  and test time)
- c) No signature moves yet: a legend is his rating shape and his looks

**L7. How strong is a drafted legend on the Road Trip?** (blocks P9-21 draft, P9-30 ramp)
- a) Like a boss drafted at the stage reached (stage average + 20, shaped by his rating shape, every stat at most 95);
  QA checks that your best lineup (one legend + one boss + a perk) still loses some New York games on Hard, and tunes
  the number down if not **(recommended)**
- b) A bit under a boss: stage average + 12 (like a good player in every stat), so a legend and a boss together can't
  break the ramp
- c) Fixed ratings from his data, the same at every stage (strong early, average late)

**L8. Mentor details** (blocks P9-23, P9-24, P9-27; c drops them)
- a) In Phase 9: each Grandfathers legend teaches one perk (Steeple: close shots +4%; Gate: block timing window 10%
  wider; Set Shot: shots beyond the arc +3%; Boxcar: dunks from a little further out; Velvet: contested layups +3%;
  Quarterback: passes 10% faster); assigned and switched any time from the Hall; works in Road Trip games only (not
  Quick Game or challenges) **(recommended)**
- b) The same perks, but a switch only takes effect at a NEW TRIP
- c) Mentors move to Phase 10 with the other eras

## Phase 10 open questions (lead-producer, 2026-11-21; answer with the letter, (a) is the recommendation)

Phase 10 builds Chapter 2, the Fathers, end to end (`docs/BOARD.md`). Wave 1 of the board starts without these
answers; each question names the tasks it blocks.

**F1. The six Fathers legends** (blocks P10-11 data and name check, P10-14 sheets, P10-15 portraits, P10-16 story)
- a) The six of part 3: Dorian "Rooftop" Vance (high-flying shooting guard), Tremaine "Ankles" Pettaway (crossover
  artist), Darnell "Midrange" Kingsley (isolation scorer), Bartholomew "Freight" Thackeray (low-post bulldozer center),
  Keon "Eyes Closed" Ridley (no-look passer), Shane "Lockbox" Hollister (lockdown wing defender), with their rating
  shapes; two changes for the hard rule: new surnames for Vance (a real player's) and Ridley (one letter from one),
  proposed by the team and shown to you; and the looks spread so that no one legend has the small, quick crossover
  guard's cornrows + single arm sleeve + headband set (one famous real player's look): Ankles gets other hair and no
  sleeve, sleeves go to Rooftop and Lockbox. Jersey numbers from the script's list, avoiding famous ones, shown to you
  **(recommended)**
- b) The same six archetypes, but the team proposes two full new name sets for you to pick from
- c) You change some of them (tell us which names, archetypes or looks)

**F2. The ISO BALL era rules** (blocks P10-12, P10-21)
- a) Crossovers beat the defender about 20% more often (for every player, CPU and you alike), dunks from about 10%
  further out, shots drawn with a slightly higher arc; nothing else changes **(recommended)**
- b) As a), plus less help defense: the defenders away from the ball lean toward it 40% less, so one-on-one drives
  decide more (the most "isolation" feel; one more sim hook to tune)
- c) A mid-range era instead: jumpers inside the arc go in 8% more often and crossovers beat the defender 20% more; no
  dunk change
- d) No era rules (the era is its court, music and legends only)

**F3. Which challenge each Fathers legend gives** (blocks P10-11, P10-13, P10-16, P10-23; numbers start from Chapter
1's tuned ones and QA tunes them, as in P9-26)
- a) Rooftop: stop the move (block or steal on him 2 times and win, to 15); Ankles: race (reach 11 before his crew gets
  10); Midrange: beat the fire (he starts on fire, to 15); Freight: hold him under 7 (to 15); Eyes Closed: comeback
  (start down 0-2, to 15); Lockbox: one cheap new goal, "score on him" (you yourself score at least 6 of your team's
  points and win, to 11); the finale: Rooftop, Midrange and Freight to 21 **(recommended)**
- b) As a), but Lockbox gets a race (reach 11 before his crew gets 9): only the five Phase 9 goal types, nothing new
  to build
- c) Every Fathers challenge a "hold him" game with its own number

**F4. Signature moves and a new animation** (blocks P10-04b, P10-14, P10-17)
- a) Each legend's move is an existing animation with a small play edge only he has: Rooftop's dunks slip part of a
  contest (drawn as an existing dunk style), Ankles's crossovers beat defenders more often with more ankle-breaker
  falls, Midrange's jumpers inside the arc lose less to a contest, Freight's close shots and dunks are harder to block,
  Eyes Closed's passes are harder to intercept, Lockbox's blocks from behind succeed more often (chase-down); no new
  frames **(recommended)**
- b) As a), plus one new animation on the Fathers sheets only (extra pages, like the hook): Midrange's turnaround
  fadeaway (a preview for your look check first; a few pages per sheet)
- c) As a), plus Rooftop's cradle dunk as a new dunk animation (same way)
- d) As a), plus both b and c

**F5. The Fathers mentor perks** (blocks P10-11 PERKS, P10-22, P10-26; each about 2 stat points, one per player, Road
Trip games only, as in Phase 9)
- a) Six new perks, none the same as a Grandfather's: Rooftop contested dunks +1.5%, Ankles crossovers beat the
  defender 5% more often, Midrange jumpers inside the arc +1.5%, Freight 5% harder to strip, Eyes Closed passes 5%
  harder to intercept, Lockbox steal timing window 5% wider **(recommended)**
- b) Reuse Chapter 1's perks where they fit (Rooftop teaches "dunks from further out" like Boxcar, Eyes Closed "passes
  5% faster" like Quarterback), new ones only for Ankles, Midrange, Freight and Lockbox (fewer sim hooks; two legends
  teach the same thing)
- c) No perks for the Fathers (they unlock, play in the draft and hang in the Hall only)

**F6. How hard is Chapter 2 next to Chapter 1?** (blocks P10-11 rating keys, P10-23 bands. Phase 9 learned the goal
numbers set the win shares, the ratings barely do, so this mostly picks the goal numbers)
- a) A step harder: with the end-of-trip crew about 5-10 points fewer wins than Chapter 1 on each level (Normal about
  60-65%, Hard about 40%), the finale about as hard as Chapter 1's **(recommended)**
- b) The same as Chapter 1 (the same bands)
- c) Clearly harder: Normal about 50%, Hard about 30%

**F7. What opens Chapter 2?** (blocks P10-18, P10-09's gate check)
- a) As in the data today: 36 trip stars or 12 legend tokens, whichever comes first; Chapter 1's finale is not needed
  **(recommended)**
- b) 36 stars or 12 tokens, and Chapter 1's finale won
- c) Chapter 1's finale won, nothing else

**F8. Anything beyond Chapter 2 in Phase 10?** (adds tasks; a) adds none)
- a) No: era teams and single legends in Quick Game, one-on-one, Legends cosmetics and the token ladder stay for later
  phases **(recommended)**
- b) Add era teams in Quick Game: GRANDFATHERS and FATHERS on YOUR TEAM / OPPONENT once 3 of an era are unlocked (their
  3 best, stats averaged to 50 like the Quick Game crews), with the era court and its rules on COURT
- c) Add the token ladder with Legends cosmetics (an era jersey and an era ball in the LOCKER)
