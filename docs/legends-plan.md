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
| Hold him | Win while the legend scores fewer than N points | Hold the hook-shot center under 7 |
| Beat the fire | He starts on fire and cools down only on two misses in a row; win | The deep shooter |
| One on one | 1-on-1 to 11, you against him | The crossover artist |
| Stop the move | Block or steal his signature move N times and win | The high flyer: 2 blocks |
| Race | Reach N before his team reaches M | The speedster: 11 before he gets 10 |
| Comeback | Start down 0-2 in a game to 15 | The no-look passer's crew |
| Score on him | You yourself score at least N of your team's points and win (Phase 10) | The lockdown defender: 6 |

The numbers in the examples are the shipped ones (one on one is not built; `scripts/legends_data.gd`; Chapter 1 tuned
in P9-26, docs/qa/phase9-challenges.md; Chapter 2 in P10-23, docs/qa/phase10-challenges.md).

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
As shipped in Phase 10 (owner, VISION "Phase 10 names and numbers"; the draft names Vance, Ridley and Shane were changed
by the name check; looks spread so no legend copies one famous player; challenges as tuned by P10-23 and the owner):
| Legend | # | Archetype | Look notes | Signature move | Challenge | Shape (spd/sht/fin/def/sta) |
|---|---|---|---|---|---|---|
| Dorian "Rooftop" Ashcombe | 27 | High-flying shooting guard | Lanky, cornrows, left arm sleeve, baggy shorts | Cradle dunk (slips part of a contest) | 2 blocks or steals on him and win (to 15) | +10 / 0 / +15 / -10 / -15 |
| Tremaine "Ankles" Pettaway | 16 | Crossover artist | Small and quick, short twists, headband, wristbands | Double crossover (more ankle-breaker falls) | Race: 11 before his crew gets 10 | +15 / +5 / -5 / -5 / -10 |
| Darnell "Midrange" Kingsley | 28 | Isolation scorer | Wiry wing, low fade, long shorts, leg sleeve | Turnaround fadeaway (its own animation) | He starts on fire (to 15) | 0 / +20 / 0 / -10 / -10 |
| Bartholomew "Freight" Thackeray | 48 | Low-post bulldozer center | Huge, shaved head, goatee, headband | Shoulder-in power dunk (hard to block) | Hold him under 7 (to 15) | -15 / -15 / +25 / +10 / -5 |
| Keon "Eyes Closed" Pemberton | 14 | No-look passer | Slim, durag, wristbands, leg sleeve | No-look and behind-the-back passes | Comeback from 0-1 (to 15) | +5 / 0 / -5 / -5 / +5 |
| Corwin "Lockbox" Hollister | 36 | Lockdown wing defender | Rangy, buzz cut, right arm sleeve | Chase-down block from behind | Score 6 yourself on him and win (to 11) | +5 / -10 / -5 / +20 / -10 |

The finale: Rooftop, Midrange and Freight to 21, no goal.

### Chapter 3: Present
As shipped in Phase 11 (owner, VISION "Phase 11 answers P1-P8", "Phase 11 names (after P11-02)", "Phase 11 look
check" and "Phase 11 Zigzag first name"; the draft names Briggs, Swiss Knife, Ozren, Idris, Ferreira and Santi were
changed by the name check; looks spread so no legend copies one famous player; era kits teal and coral; challenges as
tuned by P11-23 and the owner):
| Legend | # | Archetype | Look notes | Signature move | Challenge | Shape (spd/sht/fin/def/sta) |
|---|---|---|---|---|---|---|
| Calloway "Deep End" Whitlock | 26 | Step-back shooter | Slim guard, waves, thin mustache, no beard, right-leg tights | Step-back jumper (its own animation) | He starts on fire (to 15) | +5 / +25 / -10 / -10 / -10 |
| Theo "Toolbox" Lindqvist | 38 | Point-forward | Big and strong, low man bun, clean-shaven, no headband | Coast to coast (no tiring after a defensive rebound) | Comeback from 0-1 (to 15) | +5 / 0 / +5 / 0 / -10 |
| Sigurd "Stretch" Halvorsen | 49 | Stretch big | Tall, medium build, close-cropped dark hair, short boxed beard, full tights | Pick-and-pop (drifts to the arc, catch-and-shoot) | Race: 11 before his crew gets 10 | -10 / +15 / 0 / +5 / -10 |
| Ellery "Switch" Achterberg | 29 | Two-way wing | Long arms, bald, short beard, bare arms | Steal and run (a burst of speed after his steals) | Score 5 yourself on him and win (to 11) | +5 / -5 / 0 / +15 / -15 |
| Bodie "Skylight" Castellano | 52 | Rim-running big | Athletic, high-top fade | Alley-oop catcher (lobs caught from further out) | 2 blocks or steals on him and win (to 15) | 0 / -20 / +20 / +5 / -5 |
| Bastien "Zigzag" Moreau | 58 | Slasher | Slim, short brown curls, left knee sleeve, no headband | Euro-step layup (its own animation) | Hold him under 6 (to 11) | +10 / -5 / +10 / -10 / -5 |

The finale: Deep End, Toolbox and Skylight to 21, no goal. The era's rules: SPACE THE FLOOR (part 4); the court: the
BIG STAGE; the music: "Techno drive" by Centurion_of_war (CC-BY 4.0).

### Chapter 4: New Generation
The first draft below (2026-11-18). Phase 12 reworks it for the hard rule and the overlaps with Chapters 1-3: see
"Phase 12 plan" at the end of this file.

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
| `era_fathers` "ISO BALL" | `arc_mult` 1.05 | `cross_beat_mult` 1.2 (crossovers beat the defender more), `dunk_range_mult` 1.1 (dunks from a little further out) |
| `era_present` "SPACE THE FLOOR" (as shipped, P11-12; P11-21 and the owner kept the numbers) | `long_shot_mult` 1.08 | `spacing_ft` 2.0 (off-ball players stand 2 ft further from the hoop), `pullup_mult` 1.10 (a jump shot within 1.0 s of a crossover or spin, everyone) |
| `era_next` "HYPERSPEED" (first draft; Phase 12 proposes "FAST BREAK" with two new keys, see "Phase 12 plan") | `speed_mult` 1.08, `turbo_mult` 1.45, `stamina_refill_mult` 1.2, `shot_clock` 18 | none |

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
  (Shipped after P9-26: Steeple under 7, Gate 11 before 10, Boxcar 2 stops, Velvet under 6, Quarterback 0-2.)
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
  (start down 0-2, to 15; shipped 0-1, P10-23); Lockbox: one cheap new goal, "score on him" (you yourself score at least 6 of your team's
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

## Phase 11 open questions (lead-producer, 2026-11-25; ANSWERED 2026-11-25)

**Answered by the owner: see `docs/VISION.md` "Phase 11 answers P1-P8"** (all a, except P4 c: both the step-back and
the Euro-step animations; P8 b: era teams in Quick Game, and each era court with its era rules on COURT once that era's
team is open), then "Phase 11 names (after P11-02)" (Sigurd "Stretch" Halvorsen, was Ozren) and "Phase 11 era music".
The questions stay below as asked; `docs/BOARD.md` carries the answers into the tasks.

Phase 11 builds Chapter 3, the Present, end to end (`docs/BOARD.md`). Wave 1 of the board starts without these
answers; each question names the tasks it blocks.

**P1. The six Present legends.** Today's stars are the players everyone knows by sight, so the draft in part 3 sits
too close to some of them. (blocks P11-11 data, P11-14 sheets, P11-15 portraits, P11-16 story)
- a) The same six types, with these changes (P11-02 checks every new name against the real-player lists first):
  Calloway "Deep End" **Whitlock**, step-back shooter, no beard (Briggs is one letter from a real surname; step-back plus
  beard is one famous guard); Theo "**Toolbox**" Lindqvist, point-forward ("Swiss Knife" is too close to a knife
  maker's trademark); Ozren "Stretch" Halvorsen, stretch big, short hair instead of shaggy (a famous European big's
  look); **Ellery** "Switch" Achterberg, two-way wing, bald with a short beard ("Idris" points at a famous actor);
  Bodie "Skylight" **Castellano**, rim-running big (Ferreira is a real player's surname); **Lucien** "Zigzag" Moreau,
  slasher, no headband ("Santi" is a current player's name). Numbers and kits shown to you at the look check
  **(recommended)**
- b) The same six types, but the team brings two full new name sets to pick from
- c) You change some of them (say which names, types or looks)

**P2. The SPACE THE FLOOR era rules.** One rule set for both teams, like OLD SCHOOL and ISO BALL. (blocks P11-12, P11-21)
- a) Shots from beyond the arc go in about 8% more, players away from the ball stand about 2 ft wider (more room to
  drive and kick), and a jumper right after a crossover or spin goes in about 10% more (everyone) **(recommended)**
- b) Only the first two: long shots +8% and the wider spacing (one hook less to tune)
- c) As a), plus a shorter shot clock (20 s instead of 24): a faster, modern pace
- d) No era rules (the era is its court, music and legends only)

**P3. Which challenge each Present legend gives, and the finale.** Numbers start from Chapter 2's tuned ones and QA
tunes them, as before. (blocks P11-11, P11-13, P11-16, P11-23)
- a) Deep End: beat the fire (he starts on fire, to 15). Toolbox: comeback (start down 0-1, to 15). Stretch: race
  (reach 11 before his crew gets 10). Switch: score on him (you score 5 of your team's points yourself and win, to 11;
  one less than Lockbox). Skylight: stop the move (2 blocks or steals on him and win, to 15). Zigzag: hold him under 6
  (to 11). The finale: Deep End, Toolbox and Skylight, to 21 **(recommended)**
- b) As a), but Switch gets a hold (under 6, to 11) instead, so only one "score on him" game in the whole mode
- c) As a), plus one cheap new goal for the era: Stretch's game becomes "from deep" (your team scores 6 points from
  beyond the arc and wins, to 15)

**P4. Signature moves, and one new animation?** Every legend gets a small play edge only he has, on today's moves:
Deep End's long jumpers after his crossover lose half the contest (a step-back); Toolbox runs coast to coast after a
defensive rebound without tiring; Stretch drifts to the arc when his man helps, and his catch-and-shoot long shots are
hard to contest; Switch gets a burst of speed after a steal; lobs to Skylight are caught from further out; Zigzag's
layups slip past the man in front (a Euro-step). No new buttons: they come out of today's controls. (blocks P11-05b,
P11-14, P11-17)
- a) The edges, plus one new animation: Deep End's step-back (a slide back before the jumper, like Midrange's fadeaway;
  a preview for your look check first) **(recommended)**
- b) The edges, plus Zigzag's Euro-step as a new animation instead
- c) The edges, plus both new animations (more art and test time)
- d) The edges only, no new frames

**P5. The Present mentor perks.** One per legend, each worth about 2 stat points like the Phase 10 perks after their
resize, one per player, Road Trip games only. (blocks P11-11 PERKS, P11-22, P11-26)
- a) Six new perks, none the same as an earlier one: Deep End jumpers right after a crossover +1.5%; Toolbox a
  teammate's shot right after his pass +1.5%; Stretch catch-and-shoot jumpers +1.5%; Switch the man he guards shoots
  1.5% worse; Skylight reaches rebounds 5% further; Zigzag 5% harder to block on layups (QA resizes any that measure
  weak, with your yes) **(recommended)**
- b) Reuse earlier perks where they fit (Deep End "shots beyond the arc +1.5%" like Set Shot, Zigzag "contested
  layups +1.5%" like Velvet, Switch "steal window 5% wider" like Lockbox), new ones only for Toolbox, Stretch and
  Skylight
- c) No perks for the Present (they unlock, play in the draft and hang in the Hall only)

**P6. How hard is Chapter 3 next to Chapter 2?** Chapter 2 measured about 64% on Easy, 63% on Normal and 44% on Hard
with the end-of-trip crew. The goal numbers decide most of it, the legends' ratings a little. (blocks P11-11 rating
keys, P11-23 bands)
- a) A step harder again: Normal about 55-60%, Hard about 35%, the finale a bit harder than Chapter 2's
  **(recommended)**
- b) The same as Chapter 2
- c) Clearly harder: Normal about 45%, Hard about 25% (the mode's last built chapter as a real wall)

**P7. What opens Chapter 3?** The data says 48 trip stars or 30 legend tokens, whichever comes first. 48 stars is a
whole trip on Normal. Both chapters won on Normal give 28 tokens, so that player also needs 2 tokens more (two
challenges replayed on Hard) or the stars. (blocks P11-18, P11-09's gate check)
- a) Keep 48 stars or 30 tokens; Chapter 2's finale is not needed **(recommended)**
- b) 48 stars or 28 tokens, so both chapters on Normal open it
- c) 48 stars or 30 tokens, and Chapter 2's finale won

**P8. Anything beyond Chapter 3 in Phase 11?** (adds tasks; a) adds none)
- a) No: Chapter 4, era teams and single legends in Quick Game, one-on-one, Legends cosmetics and the token ladder stay
  for later phases **(recommended)**
- b) Add era teams in Quick Game: GRANDFATHERS, FATHERS and PRESENT on YOUR TEAM / OPPONENT once 3 of an era are
  unlocked (their 3 best, stats averaged to 50), with the era court and its rules on COURT
- c) Add the token ladder with Legends cosmetics (an era jersey and an era ball in the LOCKER)
- d) Start Chapter 4, the New Generation, in the same phase (about twice the art and test time)

## Phase 12 plan: Chapter 4, the New Generation (lead-producer, 2026-11-27; the owner answered Q1-Q8 the same day)

**Answered** (VISION "Phase 12 answers Q1-Q8"): Q2 a, Q3 a, Q4 a, Q5 a, Q6 a, Q7 a, Q8 a. **Q1 was not (a)**: the
owner wants the chapter more futuristic, 3 of the 6 legends with visible cybernetic parts (each tied to his signature
move, a small play edge like any legend's, never a bigger one) and 3 all natural. So the names and looks in 12.1-12.6
are the first proposal only; **12.9 is the roster now** (a draft for the owner's first check, P12-02 + P12-05).

The owner said "Chapter 4" at the Phase 11 check-in (VISION "Phase 11 check-in"). Phase 12 builds Chapter 4 end to end
on the Phase 9-11 machinery (a chapter is data in `legends_data.gd`, plus art, story and one era twist). It also
closes the mode, because Chapter 4 is the last row of the timeline. Everything below is the team's proposal. The
questions Q1-Q8 at the end decide it. The board's draft is in `docs/BOARD.md` (Phase 12, DRAFT).

### 12.1 Where the first draft breaks the rules

The New Generation is the era of today's youngest stars, so the risk is the highest yet. These are the players every
kid knows by sight right now, plus the 2024-2026 draft classes (P12-02 adds them to the lists). What the first draft
gets wrong:

| Draft | Problem | Proposed fix |
|---|---|---|
| Atlas "Long Shadow" **Varga**, **seven-foot guard**, step-back over a smaller defender | A seven-foot guard who shoots step-backs **is** today's most famous young center, by type alone (and it is close to a second very thin seven-footer). The step-back is Deep End's move (Chapter 3). Varga is 1 letter from two real surnames (Verga, Varda). This was flagged in Phase 9, and Briggs was swapped for the same reason | A **broad** seven-foot rim-runner big (not wiry) with locs tied up. **No** guard handle, no threes, no step-back. His move is running the floor (12.3). New surname (first idea **Ostrander**, P12-02 checks it) |
| Juno "Glitch" **Takeda**, **small, slim** trick handler | A small, flashy guard with a Japanese surname points at one current small guard | Medium height and slim, two-tone hair kept, and a new surname (first idea **Marchetti**, P12-02 checks it) |
| Orion "Halfcourt" **Mbeki**, shots from far past the arc | Mbeki is a famous statesman's surname (a famous person's name, like "Idris" in Phase 11). "Shots from far past the arc" repeats Set Shot's `deep_set` (Chapter 1). "Logo" anything, and "heat check" as a celebration, are on the banned list | New surname (first idea **Ballantyne**). A new edge, the **hot hand**: he catches fire after 2 makes in a row instead of 3. Plain words only, never "logo three" |
| Kai "**Hyperdrive**" Starling, speedster point guard | "Hyper..." is a common word, but it is also a shoe-line prefix. The plan's era name "HYPERSPEED" would sit next to it | Keep the nickname if P12-02 finds no shoe or product line with that name (fallback "**Overdrive**"). The era rules get another name (12.4) |
| Rocco "Pogo" Delacroix, highest leaper, mohawk | Passes a first look (Delacroix is a painter, not a player, and there is no real "Pogo") | Keep; P12-02 checks |
| Dex "Firewall" Adeyemi, guards everyone | Passes a first look (Adeyemi is 3 letters from Adebayo, a real center's surname, so not a near miss under our 1-letter rule) | Keep. Neon sleeves on him only (no sleeve + headband + number set) |

The look spread (the board's rule since Phase 10): no legend carries a whole famous set of look, build, number and
move. Sets to keep apart in this era:
- the very thin seven-footer with short hair
- the tall flashy point guard with neck tattoos and a low number
- the explosive leaper guard with a headband and number 12
- the big, quick bulldozer forward
- the athletic twin wings

Neon dyed hair, a mohawk, two-tone hair, locs tied up, a buzz cut and neon sleeves go one to each legend.

### 12.2 Overlap with Chapters 1-3

There are 18 signature moves and 18 perks today. The six proposed below are new mechanics, none of them a copy:
- Moves today: `hook`, `keep_block`, `deep_set`, `long_dunk`, `finger_roll`, `outlet`, `cradle`, `double_cross`,
  `fadeaway`, `shoulder`, `no_look`, `chase_down`, `step_back`, `coast`, `pop`, `steal_break`, `lob_magnet`,
  `euro_step`.
- The closest calls:
  - Hyperdrive's `top_gear` (always on, in his turbo) vs Switch's `steal_break` (only for 2 s after his own steal).
  - Long Shadow's `rim_run` (3 s after his team gets the ball, a big) vs both of those.
  - Firewall's `swat` (jump shots) vs Gate's `keep_block` (where the block goes) and Lockbox's `chase_down` (blocks
    from behind).
  - Glitch's `hesitation` (his man stands still for a moment) vs Ankles' `double_cross` (a second roll, more falls).
- Perks today: `close_touch`, `block_timing`, `deep_range`, `long_dunk`, `soft_layup`, `quick_pass`, `rise_up`,
  `handle`, `pull_up`, `strong_hold`, `blind_pass`, `quick_hands`, `off_dribble`, `extra_pass`, `catch_shoot`,
  `contest`, `board_work`, `side_step`. The six below use new keys, and none of them equals a twist key.

### 12.3 The proposed roster (Q1, Q3, Q5) (first proposal; replaced by 12.9 after Q1)

Numbers to avoid:
- `NUMBER_AVOID`
- the 18 numbers in use (9, 12, 14, 16, 18, 19, 26, 27, 28, 29, 36, 38, 46, 48, 49, 52, 54, 58)
- the numbers today's young stars made famous (1, 2, 5, 7 and 12 are already taken or avoided)
- 47, a famous long-armed defender's number, so not for Long Shadow
- 43, a current forward's number

P12-02 checks the numbers again, and the owner sees them at the look check.

| Legend | # | Archetype | Look notes | Signature move (id) | Challenge | Mentor perk (key) | Shape (spd/sht/fin/def/sta) |
|---|---|---|---|---|---|---|---|
| Kai "Hyperdrive" Starling | 17 | Speedster point guard | Small, neon dyed hair, no tattoos | **Top gear** (`top_gear`): his turbo is 10% faster (1.35 -> about 1.45 for him) | Race: 11 before his crew gets 10 | **Fresh legs** (`sprint_drain_mult` 0.90): turbo drains 10% slower | +25 / 0 / 0 / -10 / -15 |
| Atlas "Long Shadow" Ostrander (surname to check) | 56 | Rim-running seven-footer | Very tall and **broad**, locs tied up | **Run the floor** (`rim_run`): for 3 s after his team gets the ball he runs 12% faster, and the CPU sprints him to the rim | Comeback from 0-2 (to 15) | **Head start** (`break_speed_mult` 1.04): 4% faster for 3 s after his team gets the ball | +5 / -10 / +15 / +10 / -20 |
| Juno "Glitch" Marchetti (surname to check) | 25 | Trick handler | Slim, medium height, two-tone hair | **Hesitation** (`hesitation`): after his crossover his man stands still for 0.3 s (his combo dribble; Q4 may draw it) | Stop the move: 2 blocks or steals on him and win (to 15) | **Pump fake** (`fake_bite_mult` 1.15): defenders bite on his pump fakes 15% more often | +15 / +5 / -5 / -5 / -10 |
| Rocco "Pogo" Delacroix | 57 | Highest leaper | Wiry, mohawk | **Putback** (`putback`): when he reaches a miss near the rim while in the air, he tips or dunks it back at once | Hold him under 6 (to 11) | **Second chance** (`putback_bonus` 0.025): +2.5% on his shots within 1.5 s of his own offensive rebound | +5 / -15 / +20 / +5 / -15 |
| Orion "Halfcourt" Ballantyne (surname to check) | 39 | Range shooter | Lean, plain headband, beard | **Hot hand** (`hot_hand`): he catches fire after 2 makes in a row (everyone else needs 3) | He starts on fire and cools after 2 misses in a row (to 15) | **Early shot** (`early_shot_bonus` 0.010): +1% on his jumpers within 6 s of his team getting the ball | 0 / +25 / -10 / -5 / -10 |
| Dex "Firewall" Adeyemi | 51 | Switches onto everyone | Muscular, buzz cut, neon sleeves | **Swat** (`swat`): block chance on jump shots x1.5 and 1 ft more reach on them (layups and dunks as today) | Score 5 yourself on him and win (to 11): the hardest, like Lockbox and Switch | **Closeout** (`jumper_block_mult` 1.10): his blocks on jump shots 10% more likely | +5 / -10 / 0 / +20 / -15 |

The finale is **Hyperdrive, Pogo and Halfcourt** to 21, with no goal: a guard, a leaper and a shooter. The same three
are the era team in Quick Game (12.6). Challenge numbers start from Chapter 3's tuned ones, and QA tunes them as in
P9-26, P10-23 and P11-23. The perk sizes are first guesses at about 2 stat points each (the owner's size since
P10-26); QA measures them (P12-26).

### 12.4 The era rules: "FAST BREAK" (Q2)

The era's feel is "the fastest pace". The plan's first draft (speed 1.08, turbo 1.45, stamina refill 1.2, shot clock
18) is Memphis' FULL HOUSE plus Los Angeles' sand turbo, so it would feel like two city twists, not an era. The
proposal is two existing keys plus two new ones. Each new key has a default that is exactly today's game:

| Key | Value | What it does | Where |
|---|---|---|---|
| `speed_mult` (exists) | 1.08 (owner, after P12-21; was 1.05) | everyone 8% faster | player.gd, as today |
| `stamina_refill_mult` (exists) | 1.15 | stamina comes back 15% faster, so the pace lasts | player.gd, as today |
| `dead_ball_mult` (new, default 1.0) | 0.6 | the dead-ball pauses after a make, an out of bounds and a reaching foul are 40% shorter (`MADE_WAIT`, `OOB_WAIT`, `FOUL_WAIT`), so the ball is back in play at once | rules.gd |
| `break_mult` (new, default 1.0) | 1.20 (owner, after P12-21; was 1.10) | a shot within `BREAK_WINDOW` 5 s of his team getting the ball (a steal, a rebound or an inbound) goes in 20% more often: fast-break shots, for everyone | main.gd `shot_probability()`, with the window as a constant at the top of main.gd |

The shot clock does not change (Memphis keeps its 18 s as its own). The banner says "Fast break: a quicker game,
early shots fall". The twist is not called "HYPERSPEED", because that would sit next to Hyperdrive's nickname. What
QA should expect (P12-21): games a little shorter in time, more shots in the first seconds of a possession, and stats
otherwise in the normal bands.

### 12.5 Court, colors, music, gate, rating keys

- **Court** `era_next` (P12-06, `make_courts.py --era next`): a made-up arena of the future. It has a dark glass floor
  with glowing lines, a light edge around the court, light rings hanging above, and a dark crowd with phone-light
  dots. No word, digit, logo, sponsor, real arena or league. It must not read as MIDNIGHT (the star reward night
  court) or BIG STAGE. The name comes at the look check (first idea **NEON DOME**).
- **Era colors**: first idea **electric lime + violet** on near-black. That is no current NBA or WNBA color pair, and
  it is neither the Fathers' mint nor the Present's teal and coral. The owner picks at the look check, as he did with
  teal + coral.
- **Music** `legends_next` (P12-08 makes the listening list, P12-20 wires the pick in): fast chiptune or electro at
  160-175 bpm (a drum and bass or "hyper" chiptune feel), with bright neon synth leads. Not New York's track, Bebop,
  Headspin or Techno drive. CC0 or CC-BY only (no share-alike, no non-commercial), with each license checked on its
  page. `fallback_music` `newyork` covers a missing file. The owner picks.
- **Gate** (Q6): the data says 72 stars or 48 tokens. 72 stars means every trip game won on Hard, so tokens are the
  real way in. Chapters 1-3 give at most 63 tokens:
  - all three chapters on Normal give 42 tokens, 6 short
  - Chapters 1-2 on Normal plus Chapter 3 on Hard give 49 tokens, enough to open it
- **Rating keys** (Q3): a step harder than the Present's 72 / 14 / 63. First guess: `challenge_avg` 75, `mate_drop`
  14, `finale_stage_avg` 66, every stat at most `RATING_CAP` 95. The goal numbers set most of the win share (Phase 9
  learned this), and P12-23 tunes both. Chapter 3 measured Normal 50% / Hard 40% (finale 53% / 33%) with the
  end-of-trip crew.
- **Tokens**: 84 in all (4 chapters x 7 games x 3). `max_tokens()` reads this from the data.

### 12.6 The last chapter: an end to Legends, and a 4th era team (Q7, Q8)

- **What "finished" means today**: a chapter closes when its finale is won. Nothing happens when the last one closes;
  the timeline just shows four FINALE WON panels. Q8 asks two things:
  - whether the mode gets an ending: a closing scene with all four eras (the "kid" theme of part 3), LEGENDS COMPLETE
    on the timeline and a full Hall banner
  - whether anything new to play comes with it: an ALL-TIME game, or the token ladder with Legends cosmetics (both
    put off since Phase 9)
- **The 4th era team** comes from the data, with no new logic (`era_teams.gd`, P11-32). Crew "THE NEW GENERATION",
  id `new_generation`, the finale three (Hyperdrive, Pogo, Halfcourt) at average 50, signature moves on, no perks.
  It opens once those three are unlocked in Legends. Its court joins the Quick Game COURT list after BIG STAGE
  (timeline order), with FAST BREAK. "GRANDFATHERS vs NEW GENERATION" is the plan's headline matchup; P12-36 measures
  it.
- **The chapter id stays `next`** in the data and the art keys (`fin:next`, `frame_next.png`, `pin_next*.png`); no
  save holds it yet. The player never sees the id.

### 12.7 Checked: four panels is enough

- The timeline draws the 4 `panels` in `ui.json` (`legends_tour.gd` `DEF_PANELS` has 4 too). `ui.json` already has a
  `next` pin row, and `pin_next_locked.png` exists. Chapter 4 needs `pin_next.png`, `pin_next_done.png`,
  `frame_next.png` and its timeline panel lit (P12-07, as P11-07 did for Chapter 3). **No 5th panel and no layout
  change.**
- Once all four rows are built, nothing is "COMING LATER". These never show again: the tour's "later" state, the Hall's
  locked last row ("Six more legends wait in this era...") and the timeline hint for an unbuilt chapter. P12-04 checks
  the screens with four built rows (a stand-in first), and checks that nothing assumes a not-built row exists.
- The tests assume a next chapter in a few places: `--legends-test`'s next-chapter gate check after the last chapter,
  `legends.gd` `SHIPPED_CHAPTERS` 3 and its gates, `--legends-test-three` (a 4th stand-in is needed: P12-03), the trip
  test's `LEGEND_DRAFT_CHAPTERS` order, and `BACKTEST_CHAPTER3`. Each one has a planned task.
- Hard rule for the code: no `"next"` in game logic outside `legends_data.gd`, the art lookups and the tests.

### 12.8 Carry-overs from the Phase 11 check-in (the owner asked; not Chapter 4)
- Midrange's skin goes brown on his player sheet and card (the portrait is already right) (P12-09).
- Rooftop's cradle dunk gets its own look, with a preview first (P12-10a makes the preview, P12-10b puts it on his
  sheet).
- The Techno drive loop point: the owner still has to listen. Fix it only if he asks.

### 12.9 The roster after Q1: three cyber, three natural (lead-producer, 2026-11-27; a draft for the owner's first check)

The owner (Q1): "Let's make this chapter more futuristic. Let's add some players with cybernetic. Not every player,
some need to be all natural." Follow-ups: 3 of the 6 have cybernetic parts and 3 are all natural; the parts are
visible (a chrome arm, glowing leg braces, a visor, ...), each tied to that legend's signature move; the move keeps a
small play edge like every legend's, **not a bigger one**.

What stays from 12.1-12.6: the six types (spread over guards, bigs and wings as before), the six moves (`top_gear`,
`rim_run`, `hesitation`, `putback`, `hot_hand`, `swat`), the challenges (Q3 a), the six perks (Q5 a), the numbers 17 /
56 / 25 / 57 / 39 / 51 and the fixes of 12.1 (no seven-foot guard, no step-back, no Mbeki, plain move words). What
changes: every name gets a second look, two nicknames go, and the looks are redone around the parts.

**The cyber rule (the board's, P12-05 / P12-11 / P12-17):** a part is look only. The play edge is the signature move,
the same size as any legend's move in Chapters 1-3; a cyber legend gets no stat, speed or rating bonus for his part,
and a natural legend's move is as strong as a cyber one's. The shapes below sum to 0 like every legend's.

#### The six (names checked once, 2026-11-27, see "Name check" below; P12-02 checks them again)

| Legend (id) | # | Archetype | Cyber / natural | Look (64 x 96 sheet) | Move (id) | Challenge | Perk (key) | Shape spd/sht/fin/def/sta |
|---|---|---|---|---|---|---|---|---|
| Tavian "**Overclock**" Brightwell (`lg_overclock`) | 17 | speedster point guard | **cyber**: glowing leg braces | small, dark brown skin, short lime-dyed crop, no tattoos; chrome struts down the outside of both shins, knee to ankle, a lime light line on each | **Top gear** (`top_gear`): his turbo is 10% faster | race: 11 before his crew gets 10 | fresh legs (`sprint_drain_mult` 0.90) | +25 / 0 / 0 / -10 / -15 |
| Calder "**Long Shadow**" Ostrander (`lg_long_shadow`) | 56 | rim-running seven-footer | **natural** | very tall and **broad** (not wiry), deep brown skin, locs tied up with a wooden bead tie, bare arms, plain cotton knee pads | **Run the floor** (`rim_run`): 12% faster for 3 s after his team gets the ball, the CPU sprints him to the rim | comeback from 0-2 (to 15) | head start (`break_speed_mult` 1.04) | +5 / -10 / +15 / +10 / -20 |
| Cosimo "**Glitch**" Draycott (`lg_glitch`) | 25 | trick handler | **cyber**: chrome forearm | slim, medium height, light olive skin, two-tone hair (black with a platinum top); his dribble arm chrome from the elbow down (forearm and hand only), violet light seams at the wrist and knuckles | **Hesitation** (`hesitation`): after his crossover his man stands still 0.3 s; drawn as the **combo dribble** (Q4 a, between the legs into behind the back) | stop: 2 blocks or steals on him and win (to 15) | pump fake (`fake_bite_mult` 1.15) | +15 / +5 / -5 / -5 / -10 |
| Silvan "**Updraft**" Ingleby (`lg_updraft`) | 57 | highest leaper | **natural** | wiry forward, tan skin, a natural black mohawk, taped fingers, bare knees, plain low socks | **Putback** (`putback`): a miss he reaches near the rim while in the air goes back up at once (tip or dunk) | hold him under 6 (to 11) | second chance (`putback_bonus` 0.025) | +5 / -15 / +20 / +5 / -15 |
| Emrys "**Halfcourt**" Tregarth (`lg_halfcourt`) | 39 | range shooter | **natural** | lean, pale skin with freckles, sandy curls under a plain white cotton headband, **clean-shaven** (no beard: "beard" is a listed nickname), one cotton wristband | **Hot hand** (`hot_hand`): on fire after 2 makes in a row (everyone else 3) | he starts on fire and cools after 2 misses (to 15) | early shot (`early_shot_bonus` 0.010) | 0 / +25 / -10 / -5 / -10 |
| Kasimir "**Firewall**" Oyelaran (`lg_firewall`) | 51 | switches onto everyone | **cyber**: a visor | strong medium build (a forward, not a bulldozer), brown skin, buzz cut (not bald); a thin lime-lit visor across the eyes in a chrome frame that ends at the temples | **Swat** (`swat`): block chance on jump shots x1.5, 1 ft more reach on them | score 5 yourself on him and win (to 11), the hardest | closeout (`jumper_block_mult` 1.10) | +5 / -10 / 0 / +20 / -15 |

The ids follow the nicknames (the board's rule), so two change from the first proposal: `lg_hyperdrive` ->
`lg_overclock`, `lg_pogo` -> `lg_updraft`. No art, save or code holds the old ids yet.

#### Why each part fits its move (and its story hook for P12-16)
- **Overclock, leg braces -> top gear.** The braces are what make his turbo the fastest on the floor. Story hook: they
  started as a knee brace after an injury and he kept improving them (a part that helps, not a cheat).
- **Glitch, chrome forearm -> hesitation / the combo dribble.** The arm the ball lives on; the violet seams show the
  combo dribble's path on every crossover, so the new animation and the part read together. Story hook: he built the
  hand in a school workshop and the ball "skips a frame" when he crosses.
- **Firewall, visor -> swat.** The visor reads the shooter's release, so he times blocks on jump shots. Story hook: it
  was a training visor that shows the ball's flight; he never took it off.

#### Why the natural three read as natural (and stay as interesting)
No chrome, no glow and no dyed hair on them; skin, cloth and tape only, warm natural hair colors. Each has his own
bold trait instead: Long Shadow's size and locs, Updraft's mohawk and the highest jump in the game, Halfcourt's
freckles, headband and the hottest hand. Story hooks: they learned on the old courts from the earlier eras (Halfcourt
grew up on old film of the Grandfathers' set shots; Long Shadow ran mountain trails; Updraft learned to jump off the
dunes by the sea). The point of the chapter: a chrome hand or a bare one, it is the same game.

#### How the parts read as a pixel sprite (64 x 96 frames drawn 2x, the approved style)
- **The pipeline can do it in palettes.** `pixel3d.py` already has `FLAT` materials (unshaded, no contour line: eyes,
  teeth, sweat). P12-05 adds two FLAT glow tones, **lime** and **violet** (own RGB values, not the kit's tones, so the
  jersey recolor map never touches them) and a shaded **chrome** ramp (cool steel, a white glint). Every recolor
  (`_crew`, `_crew_j1..3`) keeps the parts as they are: only kit ramps change.
- **Static glow only.** A palette is fixed per sheet, so the glow does not pulse or brighten in turbo. A pulse would be
  a drawing change (a shader or a modulate in `view.gd` / `player.gd`), not in this plan; the owner can ask later.
  The glow stays inside the outline (no halo past the silhouette, so the hand and ball points and the frame checks do
  not move).
- **Overclock**: on each shin a 2-pixel chrome strut and a 1-pixel lime line, both legs, so it reads the same in all 8
  directions. At game size: two bright lime streaks at his feet when he runs.
- **Glitch**: the forearm and hand in the chrome ramp, a 1-pixel violet line at the wrist and over the knuckles. One
  arm only: like Deep End's one-leg tights it swaps sides in the mirrored directions (SW, W, NW), accepted before.
- **Firewall**: a 1-2 pixel lime band across the eyes, 1 chrome pixel at each temple, in front only (no band round the
  back of the head). The face under it keeps the normal shading.
- **Portraits** (busts, `comic.py`): Firewall's visor and Glitch's hand (raised, the ball on his chrome fingers) show
  naturally; Overclock's braces are below the bust, so P12-15 frames his portrait lower or shows the lime under-glow
  of the braces, the owner sees it at the look check.

#### The hard rule for this roster
- **Real players**: each first, last and full name checked against the `nba_api` 1.12.0 list (6,426 NBA and WNBA
  entries, read as text) and the in-game lists (`REAL_NAMES`, `REAL_NICKNAMES`): no exact match, no surname within 1
  letter, and no first name within 2 letters of a first name in `cities.gd` or `legends_data.gd` (the Bastien rule).
  Results under "Name check".
- **Famous fictional cyborgs (film, games, comics) kept apart, look by look:**
  - Glitch: forearm only (never the whole arm or the shoulder), no star or emblem, no sunglasses, short two-tone hair,
    violet seams. Not the comic soldier with the silver left arm and the red star, not the game rocker with the silver
    arm and aviators, not the anime alchemist with the metal right arm and the blond braid, not the fighting-game
    fighter with two metal arms.
  - Firewall: a thin lime lens with hair above it. Not the red ruby visor of the comic team leader, not the curved
    gold band of the TV starship engineer, not the bald man with the chrome band round the back of his head from the
    space films.
  - Overclock: shin struts on a small guard in a basketball kit. No full leg replacement, no armor plates, no helmet.
  - No word "cyborg", "bionic", "robo", "terminator", "android" or "iron" in any name, nickname or text.
- **Brands**: "Hyperdrive" goes (a shoe-line prefix and a famous space-film word); "Pogo" goes (a famous comic-strip
  character and a game-site brand). "Overclock", "Glitch", "Firewall", "Updraft", "Long Shadow" and "Halfcourt" are
  plain words; P12-02 checks each against shoe and product lines and fictional names (Firewall is also a film title,
  not a character: a caution, not a fail).
- **Famous people** (the Mbeki rule): Delacroix (a famous painter), Ballantyne (1 letter from a whisky brand and a
  book publisher), Marchetti (a famous American football player), Adeyemi (a best-selling author), Atlas (also a famous
  robot), Kai and Dex (players in our own `cities.gd`), Juno and Orion (2 letters from Bruno / Jojo and Dorian in the
  game) are all swapped.
- **The look spread** (the board's five sets): no very thin seven-footer (Long Shadow is broad with locs); no tall
  flashy point guard with neck tattoos and a low number (Overclock is small, no tattoos, 17); no explosive leaper guard
  with a headband and 12 (Updraft is a forward with a mohawk and no headband, 57; the headband is on the shooter, 39);
  no big quick bulldozer forward (Firewall is a medium-build defender, finishing 0); no twins. Hair parts one each:
  lime crop, locs, two-tone, mohawk, sandy curls + headband, buzz cut.
- **Numbers**: 17 / 56 / 25 / 57 / 39 / 51 stay (none in `NUMBER_AVOID`, none of the 18 in use, not 43 or 47); the
  owner sees them with the names.

#### Name check (first pass, lead, 2026-11-27; P12-02 makes it final with the extended lists)
Every one of the twelve name parts: no exact NBA / WNBA first or last name, no surname within 2 letters except
Ostrander (2 from Strawder, a 1990s role player; passes the 1-letter rule) and Ingleby (2 from Ingelsby and Ingles;
passes), no first name within 2 letters of a game first name, no listed nickname, and the in-game test rules
(`name_hit()`, dry run) pass. Backups if one fails: Overclock -> "Turbine", Updraft -> "Liftoff", Brightwell ->
Penhallow, Draycott -> Quennell, Tregarth -> Kittredge, Oyelaran -> Akande, Cosimo -> Severin, Emrys -> Leander.

#### The finale and the era team
- Suggested finale three (to 21, no goal), the same three as the 4th era team in Quick Game (Q7 a): **Overclock
  (cyber), Updraft (natural), Halfcourt (natural)**: a guard, a leaper and a shooter, the trio Q7 a named under its old
  names.
- Owner pick: Glitch (cyber) in for Overclock puts the one new animation (the combo dribble) in the finale and in
  Quick Game; still 1 cyber + 2 natural, a handler instead of the speedster.

#### Challenges, perks, rules: no change from the answers
- Challenges (Q3 a, a step harder than Chapter 3): as in the table; only the names in the lines change ("HOLD UPDRAFT
  UNDER 6", "SCORE 5 ON FIREWALL"). Firewall's score goal stays the hardest. No new goal type.
- Perks (Q5 a): the six answered perks, kept with their archetypes; all six ids and keys are new (none of the 18
  earlier perks, no twist key: `break_speed_mult` is not FAST BREAK's `break_mult`). Note for P12-22 / P12-26:
  `early_shot` shares its trigger (a shot soon after getting the ball) with FAST BREAK's `break_mult`, but they never
  meet: perks work in Road Trip games only, and the era twist is never on in a Road Trip game.
- Rules: FAST BREAK (Q2 a) as in 12.4.

#### Era colors, court and music (first guesses, the owner picks at the look checks)
- **Colors**: electric **lime + violet** on near-black stays (it already reads as the future), with **chrome** as the
  third tone, only on the cyber parts (never a kit color). The glow tones are the era's lime and violet.
- **Court** `era_next`: as in 12.5 (dark glass floor, glowing lines, a light edge, hanging light rings, a dark crowd
  with phone lights), plus chrome rails round the court and the rings in violet, the lines in lime, so it matches the
  parts. No word, digit, logo or real arena. First name idea still **NEON DOME** (not SKYDOME: a real stadium's old
  name).
- **Music**: as in 12.5 (fast chiptune or electro, 160-175 bpm, bright synth leads), leaning a little more synthetic
  and "machine" for the futuristic feel. CC0 or CC-BY only.

#### The ending scene (Q8 a)
After the Chapter 4 finale's after scene, once: `legends_complete`. A legend of each era on one court, the
grandfathers, fathers and sons theme: Steeple, Rooftop and Deep End, and from the New Generation one cyber and one
natural legend side by side (suggested Glitch and Halfcourt). The old laced ball goes hand to hand down the eras, last
to the chrome hand and the bare one together: the game is the same game. Then LEGENDS COMPLETE on the timeline and the
full Hall banner. Nothing new to play.

#### Owner picks at the first check (with the names and the look sample)
- R1 the six names (two nicknames new: Overclock, Updraft) and which three are cyber (as above)
- R2 the finale and era team three: Overclock, Updraft, Halfcourt (suggested) or Glitch in for Overclock
- R3 a CYBER / NATURAL tag on the Hall and draft cards, or none (suggested none: the look and the bio say it)
- R4 static glow (suggested; palettes only) or a pulse later (a drawing change)

## Phase 12 open questions (lead-producer, 2026-11-27; ANSWERED 2026-11-27, VISION "Phase 12 answers Q1-Q8"; Q1 led to 12.9)

Phase 12 builds Chapter 4, the New Generation (`docs/BOARD.md`, DRAFT). Wave 1 of the board starts without these
answers; each question names the tasks it blocks.

**Q1. The six New Generation legends.** Today's youngest stars are the players everyone knows by sight right now, so
the first draft sits too close to some of them (12.1). (blocks P12-05 look sample, P12-11 data, P12-14 sheets, P12-15
portraits, P12-16 story)
- a) The six types with these fixes (P12-02 checks every new name first):
  - Kai "Hyperdrive" Starling, speedster point guard. The nickname stays if no shoe line uses it, else "Overdrive".
  - Atlas "Long Shadow" **Ostrander**. No longer a seven-foot guard who shoots step-backs (that is one famous young
    center, and the step-back is Deep End's); now a broad seven-foot big who runs the floor.
  - Juno "Glitch" **Marchetti**, trick handler, medium height instead of small (a small flashy guard with the old
    surname points at one current guard).
  - Rocco "Pogo" Delacroix, the leaper, kept.
  - Orion "Halfcourt" **Ballantyne**, range shooter (Mbeki is a famous statesman's name).
  - Dex "Firewall" Adeyemi, the defender who switches onto everyone, kept.

  Numbers 17 / 56 / 25 / 57 / 39 / 51 and the kits are shown to you at the look check **(recommended)**
- b) The same six types, but the team brings two full new name sets to pick from
- c) You change some of them (say which names, types or looks)

**Q2. The era rules for "the fastest pace".** One rule set for both teams, like the other eras. (blocks P12-12, P12-21)
- a) "FAST BREAK": everyone 5% faster, stamina back 15% faster, the pauses after a basket, an out of bounds or a foul
  40% shorter, and a shot in the first 5 seconds after getting the ball goes in 10% more often (everyone)
  **(recommended)**
- b) The plan's first draft, "HYPERSPEED": everyone 8% faster, turbo stronger, stamina back 20% faster, an 18-second
  shot clock (no new rule to build, but it is Memphis' and Los Angeles' twists put together)
- c) As a), plus a 20-second shot clock
- d) No era rules (the era is its court, music and legends only)

**Q3. The challenges, and how hard Chapter 4 is.** Chapter 3 measured Normal 50% and Hard 40% (finale 53% / 33%) with
the end-of-trip crew. Each challenge fits the legend's move (12.3):
- Hyperdrive: race (11 before his crew gets 10)
- Long Shadow: comeback from 0-2 (to 15)
- Glitch: 2 blocks or steals on him and win (to 15)
- Pogo: hold him under 6 (to 11)
- Halfcourt: he starts on fire (to 15)
- Firewall: score 5 yourself and win (to 11), the hardest on purpose
- the finale: Hyperdrive, Pogo and Halfcourt to 21

(blocks P12-11, P12-16, P12-23)
- a) These challenges, a step harder than Chapter 3: Normal about 45%, Hard about 30-35%, the finale a bit harder than
  Chapter 3's **(recommended)**
- b) These challenges, as hard as Chapter 3
- c) These challenges, clearly harder: Normal about 40%, Hard about 25% (the last chapter as a real wall)
- d) Change some challenges (say which)

**Q4. New animations: how many, and which?** Every legend gets his play edge on today's moves (12.3), with no new
button. Phase 11 drew two (the step-back and the Euro-step). Rooftop's own cradle dunk gets drawn this phase anyway
(you asked at the check-in). (blocks P12-05b, P12-14, P12-17)
- a) One: Glitch's combo dribble (between the legs into behind the back) on his sheet. It plays on his crossovers,
  which happen many times a game. A preview for your look check comes first **(recommended)**
- b) One: Pogo's putback, a tip-dunk caught in the air at the rim (rarer in play, very loud when it happens)
- c) Both (more art and test time)
- d) None: the edges only

**Q5. The New Generation mentor perks.** One per legend, each worth about 2 stat points (your size since Phase 10), one
per player, Road Trip games only. (blocks P12-11 PERKS, P12-22, P12-26)
- a) Six new perks, none the same as an earlier one **(recommended)**:
  - Hyperdrive: turbo drains 10% slower
  - Long Shadow: 4% faster for 3 s after his team gets the ball
  - Glitch: defenders bite on his pump fakes 15% more often
  - Pogo: +2.5% on shots right after his own offensive rebound
  - Halfcourt: +1% on jumpers in the first 6 s after getting the ball
  - Firewall: his blocks on jump shots 10% more likely

  QA resizes any that measure weak, with your yes.
- b) Reuse earlier perks where they fit (Halfcourt "shots beyond the arc +1.5%" like Set Shot, Firewall "block timing
  window wider" like Gate), new ones for the other four
- c) No perks for the New Generation

**Q6. What opens Chapter 4?** The data says 72 trip stars or 48 legend tokens. 72 stars means every trip game won on
Hard, so for most players tokens are the way in. Chapters 1-3 on Normal give 42 tokens (6 short); Chapters 1-2 on
Normal plus Chapter 3 on Hard give 49. (blocks P12-18, P12-03's gate check)
- a) Keep 72 stars or 48 tokens; Chapter 3's finale is not needed **(recommended)**
- b) 72 stars or 42 tokens, so all three chapters on Normal open it
- c) 48 tokens only, and Chapter 3's finale won (no stars path)
- d) 72 stars or 48 tokens, and Chapter 3's finale won

**Q7. The 4th era team and the era court in Quick Game.** (blocks P12-33, P12-36)
- a) The same as the other eras: NEW GENERATION on YOUR TEAM / OPPONENT once its finale three (Hyperdrive, Pogo,
  Halfcourt) are unlocked, stats evened to 50, signature moves on, no perks. Its court joins COURT after BIG STAGE,
  with the FAST BREAK rules and its music **(recommended)**
- b) As a), but the court plays without the era rules in Quick Game
- c) No 4th era team (Chapter 4 stays in Legends only)

**Q8. Anything at the end of the mode?** Chapter 4 is the last row of the timeline. Today, winning the last finale
just shows four FINALE WON panels. (adds tasks; a) adds one story scene and a small timeline change)
- a) An ending: after the Chapter 4 finale, a closing scene with a legend from each era (the grandfathers, fathers and
  sons theme), then LEGENDS COMPLETE on the timeline and a full Hall banner. Nothing new to play **(recommended)**
- b) As a), plus an ALL-TIME game to replay: your crew against three legends from three eras, to 21, no goal and no
  tokens
- c) As a), plus the token ladder with Legends cosmetics (an era jersey and an era ball in the LOCKER, put off since
  Phase 9)
- d) Nothing: the timeline shows four FINALE WON panels
