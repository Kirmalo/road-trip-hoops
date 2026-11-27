extends RefCounted
# Legends data (P9-07, board "Shared contract: Legends data"): the era chapters, the legends, their challenges, the
# mentor perks and the rating rules, as const data. Static only, used through preload:
#   const LegendsData = preload("res://scripts/legends_data.gd")
#   var p: Dictionary = LegendsData.legend("lg_steeple")      # {} for an unknown id
#   var r: Dictionary = LegendsData.challenge_ratings("lg_steeple", bonus)
# Safe to edit on the tablet: a typo shows as a parse error in the Godot editor right away.
#
# THE HARD RULE (docs/legends-plan.md part 1): every legend is our own character. No real player's name or nickname,
# face, number in a team's colors, signature accessory, trademark, slogan, team, arena or league. self_test() runs the
# name check against the list in docs/legends-namecheck.md (copied below as REAL_NAMES / REAL_NICKNAMES); the doc says
# how the list was made and what it found. Any new legend gets a row in that doc and must pass --legendtest.
#
# This file preloads nothing (cities.gd and trip.gd call it, so it must not call them back): the stage averages and
# the cap are passed in or copied here as named constants. self_test() loads story_text.gd, twists.gd and
# court_looks.gd at run time.
#
# CHAPTERS rows (ordered, the era timeline):
#   id, name             "grand" | "fathers" | "present" | "next"; the name on the timeline
#   built                false = a locked pin only ("COMING LATER"): no legends, art or games (Phase 12: every row is built)
#   rules                the era rules' name (the twist's banner name; "" when not built)
#   feel                 one short line for the timeline
#   twist, look, music   twists.gd id, court_looks.gd id, res://assets/music/<music>.ogg ("" when not built)
#   fallback_music       the track while <music>.ogg is missing (an existing track)
#   gate                 {"stars": n, "tokens": n}: the chapter opens at n trip stars (Stars.total()) OR at n legend
#                        tokens; "tokens": 0 = no token path (Chapter 1 opens by stars only, L4 a)
#   crew                 the legends' side in a challenge: name (top bar), style (ratings.gd STYLES), colors (era
#                        palette names in tools/art/crews.json, main + trim), ui_color (drawn fallbacks)
#   legends              the chapter's 6 legend ids, in plaque order
#   finale               {"target", "legends": [3 ids], "label"}: the era finale (opens once all 6 are beaten)
#   intro_scene          story_text.gd scene played the first time the chapter opens
#   finale_scenes        {"before", "after"}: story_text.gd scenes around the finale
#   challenge_avg,       optional (P10-02): this chapter's CHALLENGE_AVG, MATE_DROP and FINALE_STAGE_AVG; a row
#   mate_drop,           without one uses that constant (Chapter 1 has none, so its games are exactly Phase 9's).
#   finale_stage_avg     Read through challenge_avg(ch) / mate_drop(ch) / finale_stage_avg(ch)
#
# LEGENDS rows (keys shared with cities.gd PLAYERS where they overlap, so Cities.player(id) can return them):
#   name, full           short name (plates, HUD) and full name ("Ezekiel \"Steeple\" Oakhurst")
#   first, last          the name parts the name check reads (full = first "name" last)
#   chapter              CHAPTERS id
#   archetype, role      his play style (role = archetype, the key PLAYERS uses)
#   tier                 "legend" (trip.gd: not a boss; LEGEND_LIMIT one among the starters)
#   sheet, portrait      assets/players2/<sheet>_p<N>.png (P9-09), assets/portraits/<portrait>.png (P9-10); missing
#                        ones fall back (Sheets' fallback chain, story.gd's silhouette)
#   number               jersey number (a placeholder list until the owner approves one; never NUMBER_AVOID)
#   shape                offsets on the five stats around his level, sum 0 (docs/legends-plan.md part 3)
#   spec                 his stats with a shape of +SPEC_MIN or more (PLAYERS' "spec", for the draft cards)
#   steal_bias,          like PLAYERS: how eager he is to poke and to jump for blocks
#   block_bias
#   signature            {"id", "text"}: his play edge (P9-20 reads the id; the text is for the Hall)
#   challenge            {"type", "target", "line", "mates": [2 legend ids], ...the type's numbers}:
#                          hold      "limit": you win while he scores fewer than limit
#                          fire      "cool_misses": he starts on fire and cools only after that many misses in a row
#                          stop      "count": block or steal on him that many times, and win
#                          race      "their_target": reach target before his team reaches their_target
#                          comeback  "start_score": [you, them] at tip-off; win
#                          score     "min": you (the human, Trip.human) score at least min points yourself, and
#                                    your team wins; checked at the end like stop (P10-13 builds it in challenge.gd)
#                        target is the points to win the game; line is the goal sentence (locked plaque, chapter view)
#   perk                 PERKS id he teaches as a mentor (P9-23 / P9-24; Road Trip games only, L8 a)
#   look, bio            art notes (P9-09 / P9-10) and the Hall's short bio
#   colors               his own era kit (palette names; P9-09 may change them, the owner allows kit changes)
#   unlock_scene         story_text.gd scene played when he is unlocked (P9-14)
#
# PERKS rows: {"key", "value", "text"}. The sim reads p.perk(key, default) (P9-24); default = today's game, so the
# value is a multiplier (default 1.0) for "_mult" keys and an added chance (default 0.0) for "_bonus" keys. A "_mult"
# value is within PERK_MULT_MAX of 1.0 either way (under 1.0: a chance the other side gets smaller, e.g. steals on him).

# ---------------------------------------------------------------------------------------------------- tuning
const TOKENS_BY_LEVEL := {"easy": 1, "normal": 2, "hard": 3, "legend": 3}   # best kept per challenge / finale
const TOKEN_MAX := 3                # the most one challenge or finale can give
const CHALLENGE_AVG := 66           # the challenge legend's stat average before his shape (fixed: your crew grows, L3 b;
                                    # P9-26 QA: 80 -> 66, docs/qa/phase9-challenges.md)
const MATE_DROP := 14               # his 2 legend teammates play this much under CHALLENGE_AVG (P9-26: 8 -> 14)
const DRAFT_TIER := 20              # L7 a: a drafted legend = stage average + this, shaped (like a boss's +20)
const FINALE_STAGE_AVG := 55        # the finale's base (+ DRAFT_TIER, shaped): P9-26 78 -> 52, so the finale legends
                                    # keep their shapes under the 95 cap (78 + 20 put nearly every stat at 95);
                                    # owner after P10-23: 52 -> 55, Chapter 1's finale a bit harder (Hard 50% of 80)
const CHAPTER_AVG_RANGE := [30, 90]          # a row's optional challenge_avg must be in this range (self_test)
const CHAPTER_DROP_RANGE := [0, 30]          # ... its mate_drop
const CHAPTER_FINALE_RANGE := [30, 78]       # ... its finale_stage_avg (78 = the last trip stage)
const RATING_CAP := 95              # = Trip.BOSS_CAP: no legend stat above this (also with the LEGEND bonus)
const RATING_MIN := 1               # no legend stat below this (shapes go down to -20)
const SPEC_MIN := 15                # a shape of +15 or more makes the stat one of his "spec" stats
const ID_PREFIX := "lg_"            # every legend id; trip.gd tells a legend by it (Trip.is_legend)
const STATS := ["speed", "shooting", "finishing", "defense", "stamina"]   # = Ratings.STATS (no preload here)
const CHALLENGE_TYPES := {          # each goal type and the numbers its row must have
	"hold": ["limit"],
	"fire": ["cool_misses"],
	"stop": ["count"],
	"race": ["their_target"],
	"comeback": ["start_score"],
	"score": ["min"],               # P10-11 / P10-13 (F3 a): you score min points yourself and win
}
# jersey numbers we never give a legend: the most famous numbers in the game's history (an era kit is our own colors
# anyway; this keeps a "his number" reading out entirely). The legends' numbers are placeholders until the owner
# approves a list (docs/legends-plan.md part 1). P10-11 added the 2000s era's famous numbers (2, 5, 10, 11, 15, 20, 21,
# 22, 31, 41, 42, 44, 50, 55; docs/legends-namecheck.md "Chapter 2"); no Chapter 1 number is among them. P11-02 /
# P11-11 added today's era (4, 7, 77; "Chapter 3"); no shipped number is among them.
const NUMBER_AVOID := [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 13, 15, 20, 21, 22, 23, 24, 30, 31, 32, 33, 34, 35, 41, 42,
		44, 45, 50, 55, 77, 99]
const PERK_MULT_MAX := 0.2          # a perk's "_mult" value is in 1.0 +- this, never 1.0 itself (small, L8 a)
const PERK_BONUS_MAX := 0.06        # a perk's "_bonus" value is in (0, this]

const SHEET_DIR := "res://assets/players2/"
const CARD_DIR := "res://assets/players2/cards/"
const PORTRAIT_DIR := "res://assets/portraits/"
const MUSIC_DIR := "res://assets/music/"
const STORY_PATH := "res://scripts/story_text.gd"
const TWISTS_PATH := "res://scripts/twists.gd"
const LOOKS_PATH := "res://scripts/court_looks.gd"
const NAMECHECK_DOC := "res://docs/legends-namecheck.md"
const LEGENDTEST_FLAG := "--legendtest"

# ---------------------------------------------------------------------------------------------------- chapters
const CHAPTERS := [
	{
		"id": "grand", "name": "THE GRANDFATHERS", "built": true,
		"rules": "OLD SCHOOL", "feel": "Short shorts, tall socks, big men rule",
		"twist": "era_grand", "look": "era_grand", "music": "legends_grand", "fallback_music": "memphis",
		"gate": {"stars": 24, "tokens": 0},   # L4 a: 24 stars from any games (a finished Easy trip)
		"crew": {"name": "THE GRANDFATHERS", "style": "inside", "colors": ["ERA_RUST", "ERA_CREAM"],
			"ui_color": Color(0.77, 0.35, 0.16)},
		"legends": ["lg_steeple", "lg_gate", "lg_set_shot", "lg_boxcar", "lg_velvet", "lg_quarterback"],
		"finale": {"target": 21, "legends": ["lg_steeple", "lg_velvet", "lg_quarterback"],
			"label": "GRANDFATHERS FINALE"},
		"intro_scene": "legends_grand_intro",
		"finale_scenes": {"before": "legends_grand_finale_before", "after": "legends_grand_finale_after"},
	},
	{
		# P10-11 (owner F1 a, F3 a, F6 a, F7 a). Art, story, twist and music landed in their own tasks (music: P10-20,
		# Headspin); a missing file still plays the fallbacks (Sheets' chain, the silhouette, twist none, the gym,
		# fallback_music)
		"id": "fathers", "name": "THE FATHERS", "built": true,
		"rules": "ISO BALL", "feel": "Baggy shorts, high flyers, isolation scorers",
		"twist": "era_fathers", "look": "era_fathers", "music": "legends_fathers", "fallback_music": "newyork",
		"gate": {"stars": 36, "tokens": 12},   # F7 a: 36 trip stars or 12 legend tokens, whichever comes first
		"crew": {"name": "THE FATHERS", "style": "balanced", "colors": ["ERA2_CHARCOAL", "ERA2_SEAFOAM"],
			"ui_color": Color(0.36, 0.78, 0.63)},
		"legends": ["lg_rooftop", "lg_ankles", "lg_midrange", "lg_freight", "lg_eyes_closed", "lg_lockbox"],
		"finale": {"target": 21, "legends": ["lg_rooftop", "lg_midrange", "lg_freight"], "label": "FATHERS FINALE"},
		"intro_scene": "legends_fathers_intro",
		"finale_scenes": {"before": "legends_fathers_finale_before", "after": "legends_fathers_finale_after"},
		# F6 a: a step harder than Chapter 1 (CHALLENGE_AVG 66, MATE_DROP 14, FINALE_STAGE_AVG 52, 55 after P10-23). P10-23
		# (docs/qa/phase10-challenges.md): 69 / 14 / 56 (from the 69 / 13 / 52 guesses), Eyes Closed from 0-1 (was 0-2),
		# Lockbox min 6 (owner, after P10-23 measured 3: keep 6, the hardest challenge on purpose)
		"challenge_avg": 69, "mate_drop": 14, "finale_stage_avg": 56,
	},
	{
		# P11-11 (owner P1 a, P3 a, P4 c, P5 a, P6 a, P7 a; the names row after P11-02; the look check: era color teal +
		# coral, music "Techno drive"). Art, story, twist and music land in their own tasks (P11-05..P11-20); a missing
		# file still plays the fallbacks (Sheets' chain, the silhouette, twist none, fallback_music)
		"id": "present", "name": "THE PRESENT", "built": true,
		"rules": "SPACE THE FLOOR", "feel": "Spacing, step-backs, long shots",
		"twist": "era_present", "look": "era_present", "music": "legends_present", "fallback_music": "newyork",
		"gate": {"stars": 48, "tokens": 30},   # P7 a: 48 trip stars or 30 legend tokens, no Chapter 2 finale needed
		"crew": {"name": "THE PRESENT", "style": "outside", "colors": ["ERA3_TEAL", "ERA3_CORAL"],
			"ui_color": Color(0.04, 0.45, 0.52)},   # the look check: teal + coral; P11-B2 (owner): darker teal #0a7385
		"legends": ["lg_deep_end", "lg_toolbox", "lg_stretch", "lg_switch", "lg_skylight", "lg_zigzag"],
		"finale": {"target": 21, "legends": ["lg_deep_end", "lg_toolbox", "lg_skylight"], "label": "PRESENT FINALE"},
		"intro_scene": "legends_present_intro",
		"finale_scenes": {"before": "legends_present_finale_before", "after": "legends_present_finale_after"},
		# P6 a: a step harder than Chapter 2 (69 / 14 / 56). P11-23 (docs/qa/phase11-challenges.md): 72 / 14 kept (the
		# first guess; expected crew Normal 50%, Hard 40% on 240 games each), finale_stage_avg 57 -> 63 (finale Hard 55%
		# at 57, 33% at 63; Normal 75 -> 53)
		"challenge_avg": 72, "mate_drop": 14, "finale_stage_avg": 63,
	},
	{
		# P12-11 (owner Q1 a, Q2 a, Q3 a, Q5 a, Q6 a; VISION "Phase 12 roster (after the cyber redo)" and "Phase 12
		# Halfcourt's first name"): three cyber legends (Overclock, Glitch, Firewall), three natural (Long Shadow,
		# Updraft, Halfcourt). Art, story, twist, court and music land in their own tasks (P12-05..P12-20); a missing
		# file still plays the fallbacks (Sheets' chain, the silhouette, twist none, the gym, fallback_music)
		"id": "next", "name": "THE NEW GENERATION", "built": true,
		"rules": "FAST BREAK", "feel": "Chrome, neon and the fastest pace",
		"twist": "era_next", "look": "era_next", "music": "legends_next", "fallback_music": "newyork",
		"gate": {"stars": 72, "tokens": 48},   # Q6 a: 72 trip stars or 48 legend tokens, no Chapter 3 finale needed
		"crew": {"name": "THE NEW GENERATION", "style": "balanced", "colors": ["ERA4_NIGHT", "ERA4_LIME"],
			"ui_color": Color(0.2745, 0.4314, 0.0784)},   # lime + violet on near-black (P12-05); owner after P12-07: darker lime #466e14 for the tags
		"legends": ["lg_overclock", "lg_long_shadow", "lg_glitch", "lg_updraft", "lg_halfcourt", "lg_firewall"],
		"finale": {"target": 21, "legends": ["lg_overclock", "lg_updraft", "lg_halfcourt"],
			"label": "NEW GENERATION FINALE"},   # owner R2: also the 4th era team in Quick Game
		"intro_scene": "legends_next_intro",
		"finale_scenes": {"before": "legends_next_finale_before", "after": "legends_next_finale_after"},
		# Q3 a: a step harder than Chapter 3 (72 / 14 / 63). First guesses; P12-23 tunes them (Normal about 45%, Hard
		# about 30-35%, the finale a bit harder than Chapter 3's)
		"challenge_avg": 75, "mate_drop": 14, "finale_stage_avg": 66,
	},
]

# ---------------------------------------------------------------------------------------------------- legends
# Chapter 1 (L1 a, docs/legends-plan.md part 3; challenges L2 a). Name check: docs/legends-namecheck.md (no swap).
const LEGENDS := {
	"lg_steeple": {
		"name": "STEEPLE", "full": "Ezekiel \"Steeple\" Oakhurst", "first": "Ezekiel", "last": "Oakhurst",
		"chapter": "grand", "archetype": "hook-shot center", "role": "hook-shot center", "tier": "legend",
		"sheet": "lg_steeple", "portrait": "lg_steeple", "number": 18,
		"shape": {"speed": -15, "shooting": 0, "finishing": 20, "defense": 5, "stamina": -10},
		"spec": ["finishing"], "steal_bias": -8, "block_bias": 10,
		"signature": {"id": "hook", "text": "High hook shot over the defender: close shots are hard to block"},
		"challenge": {"type": "hold", "target": 15, "limit": 7, "mates": ["lg_set_shot", "lg_quarterback"],
			"line": "HOLD STEEPLE UNDER 7 POINTS AND WIN (TO 15)"},
		"perk": "close_touch",
		"colors": ["ERA_RUST", "ERA_CREAM"],
		"look": "very tall and wiry, umber skin, black buzz cut, mutton chops, mustard terry headband, rust tank with cream trim, short shorts, tall striped socks",
		"bio": "Played center when the rims were nailed to barn walls. Still says the hook shot is the only shot a grown man needs.",
		"unlock_scene": "lg_steeple_unlock",
	},
	"lg_gate": {
		"name": "GATE", "full": "Augustus \"Gate\" Fenwick", "first": "Augustus", "last": "Fenwick",
		"chapter": "grand", "archetype": "shot-blocking wall", "role": "shot-blocking wall", "tier": "legend",
		"sheet": "lg_gate", "portrait": "lg_gate", "number": 54,
		"shape": {"speed": -10, "shooting": -15, "finishing": 5, "defense": 25, "stamina": -5},
		"spec": ["defense"], "steal_bias": -10, "block_bias": 20,
		"signature": {"id": "keep_block", "text": "Blocks that stay in play: he keeps the ball or tips it to a teammate"},
		"challenge": {"type": "race", "target": 11, "their_target": 10, "mates": ["lg_velvet", "lg_quarterback"],
			"line": "REACH 11 BEFORE GATE'S CREW GETS 10"},
		"perk": "block_timing",
		"colors": ["ERA_OLIVE", "ERA_CREAM"],
		"look": "broad heavy big, light skin, brown flat-top, knee pads, olive tank with cream trim, short shorts, tall striped socks",
		"bio": "Kept the gym's front door shut for forty years, and the lane too. Nobody remembers seeing him jump. Everybody remembers the block.",
		"unlock_scene": "lg_gate_unlock",
	},
	"lg_set_shot": {
		"name": "SET SHOT", "full": "Harlan \"Set Shot\" Vickery", "first": "Harlan", "last": "Vickery",
		"chapter": "grand", "archetype": "deep shooter", "role": "deep shooter", "tier": "legend",
		"sheet": "lg_set_shot", "portrait": "lg_set_shot", "number": 9,
		"shape": {"speed": -5, "shooting": 25, "finishing": -10, "defense": -5, "stamina": -5},
		"spec": ["shooting"], "steal_bias": 0, "block_bias": -10,
		"signature": {"id": "deep_set", "text": "Two-hand set shot from deep: his long range starts further out"},
		"challenge": {"type": "fire", "target": 15, "cool_misses": 2, "mates": ["lg_gate", "lg_boxcar"],
			"line": "SET SHOT STARTS ON FIRE: WIN THE GAME TO 15"},
		"perk": "deep_range",
		"colors": ["ERA_POWDER", "ERA_BROWN"],
		"look": "lean, light skin, neat side part, powder blue tank with brown trim, short shorts, very tall striped socks",
		"bio": "Shoots with both hands, feet planted, from where other folks park their cars. Calls the dunk a fad.",
		"unlock_scene": "lg_set_shot_unlock",
	},
	"lg_boxcar": {
		"name": "BOXCAR", "full": "Cornelius \"Boxcar\" Dunmore", "first": "Cornelius", "last": "Dunmore",
		"chapter": "grand", "archetype": "bruising power forward", "role": "bruising power forward", "tier": "legend",
		"sheet": "lg_boxcar", "portrait": "lg_boxcar", "number": 46,
		"shape": {"speed": -10, "shooting": -10, "finishing": 20, "defense": 10, "stamina": -10},
		"spec": ["finishing"], "steal_bias": -6, "block_bias": 6,
		"signature": {"id": "long_dunk", "text": "Power drop-step to a two-hand dunk: he dunks from further out"},
		"challenge": {"type": "stop", "target": 15, "count": 2, "mates": ["lg_set_shot", "lg_velvet"],
			"line": "BLOCK OR STEAL ON BOXCAR 2 TIMES AND WIN (TO 15)"},
		"perk": "long_dunk",
		"colors": ["ERA_BROWN", "ERA_MUSTARD"],
		"look": "heavy and wide, deep brown skin, bald, wristbands, brown tank with mustard trim, short shorts, tall striped socks",
		"bio": "Worked the rail yard by day and the low post by night. Says he has never been moved, only delayed.",
		"unlock_scene": "lg_boxcar_unlock",
	},
	"lg_velvet": {
		"name": "VELVET", "full": "Desmond \"Velvet\" Ashby", "first": "Desmond", "last": "Ashby",
		"chapter": "grand", "archetype": "smooth slasher", "role": "smooth slasher", "tier": "legend",
		"sheet": "lg_velvet", "portrait": "lg_velvet", "number": 19,
		"shape": {"speed": 10, "shooting": -5, "finishing": 15, "defense": -10, "stamina": -10},
		"spec": ["finishing"], "steal_bias": 6, "block_bias": -4,
		"signature": {"id": "finger_roll", "text": "Soaring finger roll: his layups slip past contests"},
		"challenge": {"type": "hold", "target": 11, "limit": 6, "mates": ["lg_steeple", "lg_set_shot"],
			"line": "HOLD VELVET UNDER 6 POINTS AND WIN (TO 11)"},
		"perk": "soft_layup",
		"colors": ["ERA_MUSTARD", "ERA_BROWN"],
		"look": "long and loose, brown skin, big afro under a cream terry headband, mustard tank with brown trim, short shorts, tall striped socks",
		"bio": "Never ran when he could glide. Still dresses better than anyone in the gym, and tells you so.",
		"unlock_scene": "lg_velvet_unlock",
	},
	"lg_quarterback": {
		"name": "QUARTERBACK", "full": "Otis \"Quarterback\" Brannigan", "first": "Otis", "last": "Brannigan",
		"chapter": "grand", "archetype": "no-look floor general", "role": "no-look floor general", "tier": "legend",
		"sheet": "lg_quarterback", "portrait": "lg_quarterback", "number": 12,
		"shape": {"speed": 5, "shooting": 5, "finishing": -10, "defense": 0, "stamina": 0},
		"spec": [], "steal_bias": 12, "block_bias": -12,
		"signature": {"id": "outlet", "text": "Full-court outlet pass for a lay-in"},
		"challenge": {"type": "comeback", "target": 15, "start_score": [0, 2], "mates": ["lg_boxcar", "lg_gate"],
			"line": "START DOWN 0-2: COME BACK AND WIN (TO 15)"},
		"perk": "quick_pass",
		"colors": ["ERA_CREAM", "ERA_RUST"],
		"look": "short and quick, tan skin, dark buzz cut, thick mustache, cream tank with rust trim, short shorts, high striped socks",
		"bio": "Throws the ball the length of the court without looking, then acts surprised you caught it. Has a whistle he never uses.",
		"unlock_scene": "lg_quarterback_unlock",
	},
	# Chapter 2, the Fathers (F1 a, docs/legends-plan.md part 3; challenges F3 a, signatures F4 b, perks F5 a). Name
	# check: docs/legends-namecheck.md "Chapter 2" (new surnames for Rooftop and Eyes Closed, a new first name for
	# Lockbox; shown to the owner). The hard rule's look spread: Ankles (the small quick crossover guard) has twists
	# and a headband, no cornrows and no arm sleeve; the cornrows go to Rooftop (left arm sleeve, no headband); the
	# other arm sleeve to Lockbox (right arm, buzz cut, no headband). Numbers: placeholders until the owner approves.
	"lg_rooftop": {
		"name": "ROOFTOP", "full": "Dorian \"Rooftop\" Ashcombe", "first": "Dorian", "last": "Ashcombe",
		"chapter": "fathers", "archetype": "high-flying shooting guard", "role": "high-flying shooting guard",
		"tier": "legend", "sheet": "lg_rooftop", "portrait": "lg_rooftop", "number": 27,
		"shape": {"speed": 10, "shooting": 0, "finishing": 15, "defense": -10, "stamina": -15},
		"spec": ["finishing"], "steal_bias": 4, "block_bias": 4,
		"signature": {"id": "cradle", "text": "Cradle dunk: he rocks the ball in his arm in the air, and his dunks slip past part of a contest"},
		"challenge": {"type": "stop", "target": 15, "count": 2, "mates": ["lg_eyes_closed", "lg_freight"],
			"line": "BLOCK OR STEAL ON ROOFTOP 2 TIMES AND WIN (TO 15)"},
		"perk": "rise_up",
		"colors": ["ERA2_SEAFOAM", "ERA2_CHARCOAL"],
		"look": "tall and lanky wing, brown skin, black cornrows, charcoal left arm sleeve, no headband, seafoam tank with white trim, baggy seafoam shorts with charcoal side panels, white crew socks (the approved look sample)",
		"bio": "Grew up dunking on the garage roof's gutter until his mother hid the ladder. Says the rim is just a step on the way up.",
		"unlock_scene": "lg_rooftop_unlock",
	},
	"lg_ankles": {
		"name": "ANKLES", "full": "Tremaine \"Ankles\" Pettaway", "first": "Tremaine", "last": "Pettaway",
		"chapter": "fathers", "archetype": "crossover artist", "role": "crossover artist", "tier": "legend",
		"sheet": "lg_ankles", "portrait": "lg_ankles", "number": 16,
		"shape": {"speed": 15, "shooting": 5, "finishing": -5, "defense": -5, "stamina": -10},
		"spec": ["speed"], "steal_bias": 10, "block_bias": -10,
		"signature": {"id": "double_cross", "text": "Double crossover: he beats his man more often, and more defenders fall"},
		"challenge": {"type": "race", "target": 11, "their_target": 10, "mates": ["lg_midrange", "lg_lockbox"],
			"line": "REACH 11 BEFORE ANKLES' CREW GETS 10"},
		"perk": "handle",
		"colors": ["ERA2_CITRUS", "ERA2_CHARCOAL"],
		"look": "small and quick, tan skin, short twists under a white headband, no arm sleeve, wristbands, citrus tank with charcoal trim, baggy citrus shorts, white crew socks",
		"bio": "Counts the defenders he has sat down the way other folks count sheep. Keeps a list. It is a long list.",
		"unlock_scene": "lg_ankles_unlock",
	},
	"lg_midrange": {
		"name": "MIDRANGE", "full": "Darnell \"Midrange\" Kingsley", "first": "Darnell", "last": "Kingsley",
		"chapter": "fathers", "archetype": "isolation scorer", "role": "isolation scorer", "tier": "legend",
		"sheet": "lg_midrange", "portrait": "lg_midrange", "number": 28,
		"shape": {"speed": 0, "shooting": 20, "finishing": 0, "defense": -10, "stamina": -10},
		"spec": ["shooting"], "steal_bias": 0, "block_bias": -6,
		"signature": {"id": "fadeaway", "text": "Turnaround fadeaway: his jumpers inside the arc lose less to a contest"},
		"challenge": {"type": "fire", "target": 15, "cool_misses": 2, "mates": ["lg_eyes_closed", "lg_freight"],
			"line": "MIDRANGE STARTS ON FIRE: WIN THE GAME TO 15"},
		"perk": "pull_up",
		"colors": ["ERA2_GRAPE", "ERA2_ICE"],
		"look": "wiry wing, brown skin, low fade haircut, grape tank with white trim, long baggy grape shorts, a white leg sleeve, white crew socks",
		"bio": "Clears out one side of the floor, waves everybody away and takes the shot the coach told him not to. It goes in.",
		"unlock_scene": "lg_midrange_unlock",
	},
	"lg_freight": {
		"name": "FREIGHT", "full": "Bartholomew \"Freight\" Thackeray", "first": "Bartholomew", "last": "Thackeray",
		"chapter": "fathers", "archetype": "low-post bulldozer center", "role": "low-post bulldozer center",
		"tier": "legend", "sheet": "lg_freight", "portrait": "lg_freight", "number": 48,
		"shape": {"speed": -15, "shooting": -15, "finishing": 25, "defense": 10, "stamina": -5},
		"spec": ["finishing"], "steal_bias": -8, "block_bias": 12,
		"signature": {"id": "shoulder", "text": "Shoulder-in power dunk: his close shots and dunks are harder to block"},
		"challenge": {"type": "hold", "target": 15, "limit": 7, "mates": ["lg_rooftop", "lg_ankles"],
			"line": "HOLD FREIGHT UNDER 7 POINTS AND WIN (TO 15)"},
		"perk": "strong_hold",
		"colors": ["ERA2_STEEL", "ERA2_CITRUS"],
		"look": "huge and heavy, umber skin, shaved head, short goatee, steel headband, steel tank with citrus trim, baggy steel shorts, white crew socks",
		"bio": "Backs his man under the rim one bump at a time and never asks for a foul. Calls the paint his driveway.",
		"unlock_scene": "lg_freight_unlock",
	},
	"lg_eyes_closed": {
		"name": "EYES CLOSED", "full": "Keon \"Eyes Closed\" Pemberton", "first": "Keon", "last": "Pemberton",
		"chapter": "fathers", "archetype": "no-look passer", "role": "no-look passer", "tier": "legend",
		"sheet": "lg_eyes_closed", "portrait": "lg_eyes_closed", "number": 14,
		"shape": {"speed": 5, "shooting": 0, "finishing": -5, "defense": -5, "stamina": 5},
		"spec": [], "steal_bias": 12, "block_bias": -12,
		"signature": {"id": "no_look", "text": "No-look and behind-the-back passes: his passes are harder to intercept"},
		"challenge": {"type": "comeback", "target": 15, "start_score": [0, 1], "mates": ["lg_lockbox", "lg_rooftop"],
			"line": "START DOWN 0-1: COME BACK AND WIN (TO 15)"},
		"perk": "blind_pass",
		"colors": ["ERA2_BRICK", "ERA2_TANGERINE"],
		"look": "slim guard, deep brown skin, tangerine durag, white wristbands, steel right leg sleeve, brick tank with tangerine trim, baggy brick shorts, white crew socks (the approved look sample)",
		"bio": "Looks at the crowd, the clock, the hot dog stand, anywhere but the man he is passing to. The ball always finds him anyway.",
		"unlock_scene": "lg_eyes_closed_unlock",
	},
	"lg_lockbox": {
		"name": "LOCKBOX", "full": "Corwin \"Lockbox\" Hollister", "first": "Corwin", "last": "Hollister",
		"chapter": "fathers", "archetype": "lockdown wing defender", "role": "lockdown wing defender", "tier": "legend",
		"sheet": "lg_lockbox", "portrait": "lg_lockbox", "number": 36,
		"shape": {"speed": 5, "shooting": -10, "finishing": -5, "defense": 20, "stamina": -10},
		"spec": ["defense"], "steal_bias": 14, "block_bias": 10,
		"signature": {"id": "chase_down", "text": "Chase-down block: his blocks from behind work more often"},
		"challenge": {"type": "score", "target": 11, "min": 6, "mates": ["lg_ankles", "lg_midrange"],
			"line": "SCORE 6 POINTS YOURSELF ON LOCKBOX AND WIN (TO 11)"},
		"perk": "quick_hands",
		"colors": ["ERA2_CHARCOAL", "ERA2_TANGERINE"],
		"look": "rangy wing, light skin, brown buzz cut, no headband, charcoal right arm sleeve, charcoal tank with tangerine trim, baggy charcoal shorts, white crew socks",
		"bio": "Picks up his man at the far free-throw line and walks him back the whole way. Has never once been in a hurry to shoot.",
		"unlock_scene": "lg_lockbox_unlock",
	},
	# Chapter 3, the Present (P1 a and VISION "Phase 11 names (after P11-02)"; challenges P3 a, signatures P4 c, perks
	# P5 a). Name check: docs/legends-namecheck.md "Chapter 3" (final table). The hard rule's look spread (the board's
	# six risky sets): Deep End no beard, no mouthguard (a thin mustache, waves, a normal guard's height); Toolbox a low
	# man bun, no headband; Stretch close-cropped dark hair and a short boxed beard, a medium build; Switch bald with a
	# short beard, bare arms (no braids, no twists); Skylight a high-top fade; Zigzag curly hair and a knee sleeve, no
	# headband. Numbers: the look check's (coordinator, from the passing list). Kits: ERA3_* palettes (made up; P11-14
	# may change them, never to a current team's color pair).
	"lg_deep_end": {
		"name": "DEEP END", "full": "Calloway \"Deep End\" Whitlock", "first": "Calloway", "last": "Whitlock",
		"chapter": "present", "archetype": "step-back shooter", "role": "step-back shooter", "tier": "legend",
		"sheet": "lg_deep_end", "portrait": "lg_deep_end", "number": 26,
		"shape": {"speed": 5, "shooting": 25, "finishing": -10, "defense": -10, "stamina": -10},
		"spec": ["shooting"], "steal_bias": 4, "block_bias": -8,
		"signature": {"id": "step_back", "text": "Step-back jumper: his long jumpers after a crossover lose half the contest"},
		"challenge": {"type": "fire", "target": 15, "cool_misses": 2, "mates": ["lg_stretch", "lg_switch"],
			"line": "DEEP END STARTS ON FIRE: WIN THE GAME TO 15"},
		"perk": "off_dribble",
		"colors": ["ERA3_GRAPHITE", "ERA3_TEAL"],
		"look": "slim guard of normal height, brown skin, waves, thin mustache, no beard, no mouthguard, graphite tank with teal trim, modern mid-thigh graphite shorts with teal stripes, right-leg tights, low socks (the approved look sample)",
		"bio": "Learned to shoot at the public pool's outdoor hoop, from the far side of the water. Still backs up one more step before every shot, just to be sure.",
		"unlock_scene": "lg_deep_end_unlock",
	},
	"lg_toolbox": {
		"name": "TOOLBOX", "full": "Theo \"Toolbox\" Lindqvist", "first": "Theo", "last": "Lindqvist",
		"chapter": "present", "archetype": "point-forward", "role": "point-forward", "tier": "legend",
		"sheet": "lg_toolbox", "portrait": "lg_toolbox", "number": 38,
		"shape": {"speed": 5, "shooting": 0, "finishing": 5, "defense": 0, "stamina": -10},
		"spec": [], "steal_bias": 4, "block_bias": 0,
		"signature": {"id": "coast", "text": "Coast to coast: after a defensive rebound he runs the floor without tiring"},
		"challenge": {"type": "comeback", "target": 15, "start_score": [0, 1], "mates": ["lg_switch", "lg_zigzag"],
			"line": "START DOWN 0-1: COME BACK AND WIN (TO 15)"},
		"perk": "extra_pass",
		"colors": ["ERA3_CORAL", "ERA3_GRAPHITE"],
		"look": "big and strong forward, light skin, low man bun, clean-shaven, no headband, coral tank with graphite trim, modern mid-thigh shorts, low socks (the approved look sample's build)",
		"bio": "Grabs the rebound, brings it up, runs the play and fixes the scoreboard on the way back. Carries a little screwdriver in his gym bag, just in case.",
		"unlock_scene": "lg_toolbox_unlock",
	},
	"lg_stretch": {
		"name": "STRETCH", "full": "Sigurd \"Stretch\" Halvorsen", "first": "Sigurd", "last": "Halvorsen",
		"chapter": "present", "archetype": "stretch big", "role": "stretch big", "tier": "legend",
		"sheet": "lg_stretch", "portrait": "lg_stretch", "number": 49,
		"shape": {"speed": -10, "shooting": 15, "finishing": 0, "defense": 5, "stamina": -10},
		"spec": ["shooting"], "steal_bias": -6, "block_bias": 6,
		"signature": {"id": "pop", "text": "Pick-and-pop: he drifts to the arc when his man helps, and his catch-and-shoot shots are hard to contest"},
		"challenge": {"type": "race", "target": 11, "their_target": 10, "mates": ["lg_deep_end", "lg_skylight"],
			"line": "REACH 11 BEFORE STRETCH'S CREW GETS 10"},
		"perk": "catch_shoot",
		"colors": ["ERA3_LIGHT", "ERA3_TEAL"],
		"look": "tall big of medium build, light skin, close-cropped dark hair, short boxed beard, white tank with teal trim, modern mid-thigh white shorts with teal stripes, full ink tights, low socks",
		"bio": "Sets the screen, steps back to the line and waits. Says a big man near the rim is just in the way of the view.",
		"unlock_scene": "lg_stretch_unlock",
	},
	"lg_switch": {
		"name": "SWITCH", "full": "Ellery \"Switch\" Achterberg", "first": "Ellery", "last": "Achterberg",
		"chapter": "present", "archetype": "two-way wing", "role": "two-way wing", "tier": "legend",
		"sheet": "lg_switch", "portrait": "lg_switch", "number": 29,
		"shape": {"speed": 5, "shooting": -5, "finishing": 0, "defense": 15, "stamina": -15},
		"spec": ["defense"], "steal_bias": 14, "block_bias": 6,
		"signature": {"id": "steal_break", "text": "Steal and run: a burst of speed right after his steals"},
		"challenge": {"type": "score", "target": 11, "min": 5, "mates": ["lg_toolbox", "lg_zigzag"],
			"line": "SCORE 5 POINTS YOURSELF ON SWITCH AND WIN (TO 11)"},
		"perk": "contest",
		"colors": ["ERA3_INK", "ERA3_TEAL"],
		"look": "long-armed wing, deep brown skin, bald, short beard, bare arms, ink tank with teal trim, modern mid-thigh shorts, low socks",
		"bio": "Guards the point guard, then the center, then whoever is left. Says about four words a game, and three of them are \"mine\".",
		"unlock_scene": "lg_switch_unlock",
	},
	"lg_skylight": {
		"name": "SKYLIGHT", "full": "Bodie \"Skylight\" Castellano", "first": "Bodie", "last": "Castellano",
		"chapter": "present", "archetype": "rim-running big", "role": "rim-running big", "tier": "legend",
		"sheet": "lg_skylight", "portrait": "lg_skylight", "number": 52,
		"shape": {"speed": 0, "shooting": -20, "finishing": 20, "defense": 5, "stamina": -5},
		"spec": ["finishing"], "steal_bias": -6, "block_bias": 14,
		"signature": {"id": "lob_magnet", "text": "Alley-oop catcher: lobs to him are caught from further out"},
		"challenge": {"type": "stop", "target": 15, "count": 2, "mates": ["lg_deep_end", "lg_toolbox"],
			"line": "BLOCK OR STEAL ON SKYLIGHT 2 TIMES AND WIN (TO 15)"},
		"perk": "board_work",
		"colors": ["ERA3_DEEP_TEAL", "ERA3_LIGHT"],
		"look": "athletic big, brown skin, high-top fade, deep teal tank with white trim, modern mid-thigh deep teal shorts with white stripes, low socks",
		"bio": "Runs the floor like the rim owes him money. Throw it anywhere near the glass and he goes up to collect.",
		"unlock_scene": "lg_skylight_unlock",
	},
	"lg_zigzag": {
		"name": "ZIGZAG", "full": "Bastien \"Zigzag\" Moreau", "first": "Bastien", "last": "Moreau",
		"chapter": "present", "archetype": "slasher", "role": "slasher", "tier": "legend",
		"sheet": "lg_zigzag", "portrait": "lg_zigzag", "number": 58,
		"shape": {"speed": 10, "shooting": -5, "finishing": 10, "defense": -10, "stamina": -5},
		"spec": [], "steal_bias": 6, "block_bias": -6,
		"signature": {"id": "euro_step", "text": "Euro-step layup: his layups slip past the man in front"},
		"challenge": {"type": "hold", "target": 11, "limit": 6, "mates": ["lg_stretch", "lg_skylight"],
			"line": "HOLD ZIGZAG UNDER 6 POINTS AND WIN (TO 11)"},
		"perk": "side_step",
		"colors": ["ERA3_LIGHT", "ERA3_CORAL"],
		"look": "slim slasher, tan skin, short brown curls, no headband, an ink left knee sleeve, white tank with coral trim, modern mid-thigh coral shorts with white stripes, low socks",
		"bio": "Never takes the straight road to the rim when a crooked one is open. Leaves defenders guarding the spot where he used to be.",
		"unlock_scene": "lg_zigzag_unlock",
	},
	# Chapter 4, the New Generation (Q1 a, docs/legends-plan.md 12.9; VISION "Phase 12 roster (after the cyber redo)",
	# Halfcourt's first name Emrys; challenges Q3 a, perks Q5 a). Name check: docs/legends-namecheck.md "Chapter 4"
	# (final table). THE CYBER RULE: Overclock (leg braces), Glitch (chrome forearm) and Firewall (visor) wear visible
	# parts; a part is look only (in "look" and the story, no data key, no stat): the edge is the signature move, the
	# same size as any legend's. Long Shadow, Updraft and Halfcourt are all natural: no chrome, no glow, no dyed hair.
	# The look spread (the board's five real-player sets and the cyborg looks, kept apart in the namecheck doc): no
	# very thin seven-footer (Long Shadow broad, locs), no tall flashy guard with neck tattoos and a low number
	# (Overclock small, Glitch medium height, no tattoos), no leaper guard in a headband in 12 (Updraft a forward with a
	# mohawk; the headband on Halfcourt, 39), no bulldozer forward (Firewall medium build, finishing 0), no twins; one
	# hair part each (lime crop, locs, two-tone, mohawk, sandy curls + headband, buzz cut). Kits: ERA4_* (P12-05's look
	# sample: near-black with lime or violet; never navy, never a silver trim). The look texts follow 12.9 and the
	# sample; the owner's look check (P12-05) may still adjust them
	"lg_overclock": {
		"name": "OVERCLOCK", "full": "Tavian \"Overclock\" Brightwell", "first": "Tavian", "last": "Brightwell",
		"chapter": "next", "archetype": "speedster point guard", "role": "speedster point guard", "tier": "legend",
		"sheet": "lg_overclock", "portrait": "lg_overclock", "number": 17,
		"shape": {"speed": 25, "shooting": 0, "finishing": 0, "defense": -10, "stamina": -15},
		"spec": ["speed"], "steal_bias": 10, "block_bias": -10,
		"signature": {"id": "top_gear", "text": "Top gear: his sprint is the fastest on the floor"},
		"challenge": {"type": "race", "target": 11, "their_target": 10, "mates": ["lg_halfcourt", "lg_firewall"],
			"line": "REACH 11 BEFORE OVERCLOCK'S CREW GETS 10"},
		"perk": "fresh_legs",
		"colors": ["ERA4_NIGHT", "ERA4_LIME"],
		"look": "small speedster guard, dark brown skin, short lime-dyed crop, no tattoos; cyber: chrome struts down the outside of both shins from knee to ankle with a lime light line on each, his own legs showing between them (no metal feet, no mask or goggles); near-black tank with lime trim, modern mid-thigh near-black shorts with lime stripes, low socks, low-cut shoes",
		"bio": "Hurt his knee as a kid and built himself a better brace, then a better one, then one for each leg. Now he is at the other end before the ball comes down.",
		"unlock_scene": "lg_overclock_unlock",
	},
	"lg_long_shadow": {
		"name": "LONG SHADOW", "full": "Calder \"Long Shadow\" Ostrander", "first": "Calder", "last": "Ostrander",
		"chapter": "next", "archetype": "seven-foot rim runner", "role": "seven-foot rim runner", "tier": "legend",
		"sheet": "lg_long_shadow", "portrait": "lg_long_shadow", "number": 56,
		"shape": {"speed": 5, "shooting": -10, "finishing": 15, "defense": 10, "stamina": -20},
		"spec": ["finishing"], "steal_bias": -6, "block_bias": 14,
		"signature": {"id": "rim_run", "text": "Run the floor: a burst of speed right after his team gets the ball"},
		"challenge": {"type": "comeback", "target": 15, "start_score": [0, 2], "mates": ["lg_overclock", "lg_firewall"],
			"line": "START DOWN 0-2: COME BACK AND WIN (TO 15)"},
		"perk": "head_start",
		"colors": ["ERA4_NIGHT", "ERA4_LIME"],
		"look": "very tall and broad center (not wiry), deep brown skin, locs tied up with a wooden bead tie, bare arms, plain cotton knee pads; natural: no chrome, no glow; near-black tank with lime trim, modern mid-thigh near-black shorts with lime stripes, low socks, low-cut shoes",
		"bio": "Ran mountain trails before he ran the floor. By the time the defense turns around, he is already standing under the rim.",
		"unlock_scene": "lg_long_shadow_unlock",
	},
	"lg_glitch": {
		"name": "GLITCH", "full": "Cosimo \"Glitch\" Draycott", "first": "Cosimo", "last": "Draycott",
		"chapter": "next", "archetype": "trick handler", "role": "trick handler", "tier": "legend",
		"sheet": "lg_glitch", "portrait": "lg_glitch", "number": 25,
		"shape": {"speed": 15, "shooting": 5, "finishing": -5, "defense": -5, "stamina": -10},
		"spec": ["speed"], "steal_bias": 10, "block_bias": -8,
		"signature": {"id": "hesitation", "text": "Hesitation: after his crossover his man stands still for a moment"},
		"challenge": {"type": "stop", "target": 15, "count": 2, "mates": ["lg_long_shadow", "lg_updraft"],
			"line": "BLOCK OR STEAL ON GLITCH 2 TIMES AND WIN (TO 15)"},
		"perk": "pump_fake",
		"colors": ["ERA4_NIGHT", "ERA4_LIME"],
		"look": "slim trick handler of medium height, light olive skin, no tattoos, two-tone hair (black sides, a platinum top); cyber: his right forearm and hand chrome from the elbow down (forearm only, a hand of normal size, no star or emblem, no sunglasses), violet light seams at the wrist and knuckles; near-black tank with lime trim, near-black shorts with violet stripes, low socks, low-cut shoes",
		"bio": "Built his own hand in the school workshop, one finger at a time. Now the ball seems to skip a frame every time he crosses over.",
		"unlock_scene": "lg_glitch_unlock",
	},
	"lg_updraft": {
		"name": "UPDRAFT", "full": "Silvan \"Updraft\" Ingleby", "first": "Silvan", "last": "Ingleby",
		"chapter": "next", "archetype": "highest leaper", "role": "highest leaper", "tier": "legend",
		"sheet": "lg_updraft", "portrait": "lg_updraft", "number": 57,
		"shape": {"speed": 5, "shooting": -15, "finishing": 20, "defense": 5, "stamina": -15},
		"spec": ["finishing"], "steal_bias": 0, "block_bias": 12,
		"signature": {"id": "putback", "text": "Putback: a miss he reaches in the air near the rim goes straight back up"},
		"challenge": {"type": "hold", "target": 11, "limit": 6, "mates": ["lg_glitch", "lg_halfcourt"],
			"line": "HOLD UPDRAFT UNDER 6 POINTS AND WIN (TO 11)"},
		"perk": "second_chance",
		"colors": ["ERA4_NIGHT", "ERA4_VIOLET"],
		"look": "wiry forward, tan skin, a natural black mohawk, no headband, taped fingers, bare knees; natural: no chrome, no glow; near-black tank with violet trim, modern mid-thigh near-black shorts with lime stripes, plain low socks, low-cut shoes",
		"bio": "Learned to jump off the sand dunes by the sea, where every landing is soft. A miss near the rim is just a second try on the way up.",
		"unlock_scene": "lg_updraft_unlock",
	},
	"lg_halfcourt": {
		"name": "HALFCOURT", "full": "Emrys \"Halfcourt\" Tregarth", "first": "Emrys", "last": "Tregarth",
		"chapter": "next", "archetype": "range shooter", "role": "range shooter", "tier": "legend",
		"sheet": "lg_halfcourt", "portrait": "lg_halfcourt", "number": 39,
		"shape": {"speed": 0, "shooting": 25, "finishing": -10, "defense": -5, "stamina": -10},
		"spec": ["shooting"], "steal_bias": 2, "block_bias": -8,
		"signature": {"id": "hot_hand", "text": "Hot hand: he catches fire after 2 makes in a row"},
		"challenge": {"type": "fire", "target": 15, "cool_misses": 2, "mates": ["lg_long_shadow", "lg_updraft"],
			"line": "HALFCOURT STARTS ON FIRE: WIN THE GAME TO 15"},
		"perk": "early_shot",
		"colors": ["ERA4_NIGHT", "ERA4_LIME"],
		"look": "lean shooter, pale skin with freckles, sandy curls under a plain white cotton headband, clean-shaven, no ponytail, one cotton wristband; natural: no chrome, no glow; near-black tank with lime trim, modern mid-thigh near-black shorts with lime stripes, low socks, low-cut shoes",
		"bio": "Grew up on old film of the Grandfathers and shoots from wherever he happens to be standing. Let him hit two in a row and nobody can cool him down.",
		"unlock_scene": "lg_halfcourt_unlock",
	},
	"lg_firewall": {
		"name": "FIREWALL", "full": "Kasimir \"Firewall\" Oyelaran", "first": "Kasimir", "last": "Oyelaran",
		"chapter": "next", "archetype": "switching shot blocker", "role": "switching shot blocker", "tier": "legend",
		"sheet": "lg_firewall", "portrait": "lg_firewall", "number": 51,
		"shape": {"speed": 5, "shooting": -10, "finishing": 0, "defense": 20, "stamina": -15},
		"spec": ["defense"], "steal_bias": 10, "block_bias": 16,
		"signature": {"id": "swat", "text": "Swat: his blocks on jump shots work more often and reach further"},
		"challenge": {"type": "score", "target": 11, "min": 5, "mates": ["lg_overclock", "lg_glitch"],
			"line": "SCORE 5 POINTS YOURSELF ON FIREWALL AND WIN (TO 11)"},
		"perk": "closeout",
		"colors": ["ERA4_NIGHT", "ERA4_LIME"],
		"look": "strong forward of medium build (not a bulldozer), brown skin, buzz cut (not bald); cyber: a thin flat lime visor across the eyes in a chrome frame that ends at the temples (front only, no slats, nothing round the back of the head); near-black tank with lime trim, near-black shorts with violet stripes, low socks, low-cut shoes",
		"bio": "Wore a training visor that showed the ball's flight and simply never took it off. Reads the release before the shooter knows he is shooting.",
		"unlock_scene": "lg_firewall_unlock",
	},
}

# ---------------------------------------------------------------------------------------------------- perks
# L8 a: one perk per player, about 2 stat points' worth, Road Trip games only. P9-24 reads p.perk(key, default);
# QA (P9-30) may tune the values.
const PERKS := {
	# owner (after P9-30): about 2 stat points each, so shot perks +1.5%, the others 5% (docs/qa/phase9-ramp.md)
	"close_touch": {"key": "close_shot_bonus", "value": 0.015, "text": "Close shots and layups +1.5%"},
	"block_timing": {"key": "block_window_mult", "value": 1.05, "text": "Block timing window 5% wider"},
	"deep_range": {"key": "three_bonus", "value": 0.015, "text": "Shots beyond the arc +1.5%"},
	"long_dunk": {"key": "dunk_reach_mult", "value": 1.05, "text": "Dunks from a little further out"},
	"soft_layup": {"key": "contested_layup_bonus", "value": 0.015, "text": "Contested layups +1.5%"},
	"quick_pass": {"key": "pass_speed_mult", "value": 1.05, "text": "Passes 5% faster"},
	# Chapter 2 (F5 a, the board's contract; data only here, P10-22 hooks them). The two "on him" keys make the other
	# side's chance smaller, so their value is under 1.0 (default 1.0 = today's game)
	# P10-26 QA (docs/qa/phase10-ramp.md): at the F5 a sizes rise_up, handle and blind_pass were worth only 0.2-0.6 of
	# "2 stat points" (handle and blind_pass fired in 1-6 of 30 games), so rise_up 0.015 -> 0.025, handle 1.05 -> 1.15,
	# blind_pass 0.95 -> 0.85; pull_up, strong_hold and quick_hands measured about 2 stat points and stay
	"rise_up": {"key": "contested_dunk_bonus", "value": 0.025, "text": "Contested dunks +2.5%"},
	"handle": {"key": "cross_win_mult", "value": 1.15, "text": "Crossovers beat the defender 15% more often"},
	"pull_up": {"key": "mid_shot_bonus", "value": 0.015, "text": "Jumpers inside the arc +1.5%"},
	"strong_hold": {"key": "strip_guard_mult", "value": 0.95, "text": "5% harder to strip"},
	"blind_pass": {"key": "pass_safe_mult", "value": 0.85, "text": "Passes 15% harder to intercept"},
	"quick_hands": {"key": "steal_window_mult", "value": 1.05, "text": "Steal timing window 5% wider"},
	# Chapter 3 (P5 a, the board's contract; data only here, P11-22 hooks them, P11-26 measures them). layup_block_mult
	# is "on him" (block chance on his layups), so its value is under 1.0
	"off_dribble": {"key": "pullup_bonus", "value": 0.025, "text": "Jumpers right after his crossover +2.5%"},
	"extra_pass": {"key": "assist_shot_bonus", "value": 0.010, "text": "A teammate's shot right after his pass +1%"},
	"catch_shoot": {"key": "catch_shot_bonus", "value": 0.010, "text": "Jumpers right after a catch +1%"},
	"contest": {"key": "guard_contest_bonus", "value": 0.005, "text": "The man he guards shoots 0.5% worse"},
	"board_work": {"key": "rebound_reach_mult", "value": 1.15, "text": "Reaches rebounds 15% further"},
	"side_step": {"key": "layup_block_mult", "value": 0.80, "text": "Layups 20% harder to block"},
	# Chapter 4 (Q5 a, the board's contract; data only here, P12-22 hooks them, P12-26 measures them). Every key is
	# new: none of the 18 earlier perks' and no twist key (break_speed_mult is not FAST BREAK's break_mult). Defaults
	# 1.0 for _mult, 0.0 for _bonus; sprint_drain_mult is under 1.0 (his sprint tires him less)
	"fresh_legs": {"key": "sprint_drain_mult", "value": 0.90, "text": "Sprinting tires him 10% less"},
	"head_start": {"key": "break_speed_mult", "value": 1.04, "text": "4% faster right after his team gets the ball"},
	"pump_fake": {"key": "fake_bite_mult", "value": 1.15, "text": "His pump fakes get the defender up 15% more often"},
	"second_chance": {"key": "putback_bonus", "value": 0.025, "text": "Putbacks after an offensive rebound +2.5%"},
	"early_shot": {"key": "early_shot_bonus", "value": 0.010, "text": "Shots soon after getting the ball +1%"},
	"closeout": {"key": "jumper_block_mult", "value": 1.10, "text": "His blocks on jump shots work 10% more often"},
}

# ---------------------------------------------------------------------------------------------------- name check
# Copied from docs/legends-namecheck.md (keep the two in step). Compared after normalize(): lower case, letters and
# spaces only, a leading "the " dropped. A legend fails when:
#   - his nickname equals a real nickname, or holds one as whole words (nickname phrases of 1 word are checked as
#     whole words of his nickname, first and last name too, so "Air Oakhurst" or "Magic" would fail)
#   - "first last" equals a real full name, his last name equals a listed real surname, or is one letter away from
#     one (5 letters or more)
#   - his bio, look, signature or challenge text holds a real full name or a nickname of 2 words or more, or
#     (P12-11) one of the CYBER_WORDS
const REAL_NICKNAMES := [
	"air", "air jordan", "his airness", "magic", "bird", "larry legend", "hick from french lick", "dr j", "doctor j",
	"doctor", "big o", "iceman", "ice", "pistol", "pistol pete", "wilt the stilt", "stilt", "big dipper", "dipper",
	"chief", "hondo", "logo", "mr clutch", "zeke", "microwave", "worm", "mailman", "admiral", "dream", "hakeem the dream",
	"glove", "answer", "ai", "black mamba", "mamba", "greek freak", "chef", "chef curry", "king", "king james", "lbj",
	"truth", "big ticket", "kg", "big fundamental", "shaq", "diesel", "big aristotle", "superman", "penny", "flash",
	"agent zero", "white chocolate", "glide", "clyde the glide", "clyde", "pearl", "earl the pearl", "black jesus",
	"round mound of rebound", "sir charles", "chuck", "human highlight film", "nique", "spud", "skywalker",
	"kangaroo kid", "hawk", "a train", "captain late", "bad news", "dr dunk", "jet", "mr big shot", "big shot bob",
	"big shot rob", "starbury", "beard", "brow", "joker", "dame time", "slim reaper", "uncle drew", "spida",
	"big game james", "zo", "tiny", "nate the great", "sky hook", "skyhook", "cap", "big smooth", "boogie", "melo",
	"cp3", "d wade", "process", "unicorn", "ant", "alien", "point god", "splash brothers", "russ", "brodie",
	"houdini of the hardwood", "cooz", "easy ed", "jumping joe", "hot rod", "bad boys", "showtime", "rifleman",
	"rocket", "thunder dan", "vinsanity", "half man half amazing", "air canada", "big dog", "reign man", "big country",
	"bones", "mad max", "matrix", "big e", "chairman of the boards", "goat", "the goat", "hook", "destroyer",
	"pee wee", "skip to my lou", "hot sauce", "professor", "helicopter", "jumpin jackie", "fly", "meadowlark",
	"curly", "goose", "sweet lou", "mikan", "kareem", "the hook", "hammer", "black hole", "manimal", "white mamba",
	"the kid", "big shamrock", "the mule", "the bus", "big baby", "birdman", "the claw", "klaw", "steady eddie",
	"mr triple double", "the stopper", "the general", "the hammer", "dr k", "mr basketball", "big red",
	"air georgia", "sky", "j kidd", "mutombo", "sleepy floyd", "world b free", "world", "pops", "bobo", "smush",
	"tmac", "t mac", "sweet pea", "rainman", "the dream team", "the jet", "mr fundamentals",
	# P10-11: the 2000s era (players, and the streetball mixtape tour names of the time)
	"sheed", "big ben", "rip", "franchise", "stevie franchise", "manu", "big z", "ak47", "ak 47", "captain jack",
	"j rich", "candy man", "grindfather", "tru warrior", "hibachi", "krypto nate", "kryptonate", "j will", "big shot",
	"baby shaq", "baby jordan", "bonzi", "peja", "stat", "big three", "main event", "bone collector", "escalade",
	"sik wit it", "spyda", "go get it", "air up there", "black widow", "high octane", "headache", "dribbling machine",
	"ao", "god shammgod", "shammgod", "killer crossover", "utep two step", "cat", "the mayor", "bubba chuck",
	"human joystick", "jumpman", "big nasty", "boston strangler", "k mart", "kmart", "chosen one", "lob city",
	"sky walker", "dr dunkenstein", "slim",
	# P11-02 / P11-11: today (about 2015-2026, NBA and WNBA), and the trademark next to a draft nickname
	"steph", "baby faced assassin", "durantula", "easy money sniper", "kd", "bron", "kid from akron", "playoff p",
	"pg13", "pg 13", "pandemic p", "jimmy buckets", "playoff jimmy", "himmy", "buckets", "book", "d book", "ice trae",
	"dame dolla", "logo lillard", "board man", "fun guy", "stifle tower", "french rejection", "wemby", "mutant",
	"zinger", "porzingod", "kat", "bam", "luka magic", "sga", "ant man", "iso joe", "scary terry", "swaggy p",
	"lou will", "linsanity", "dragon", "zanos", "hood melo", "big body", "cardiac kemba", "point gawd", "unibrow",
	"stewie", "ace", "phee", "bayou barbie", "chi barbie", "paige buckets", "sabi",
	"swiss army", "swiss army knife", "swiss knife",
	# P11-02: today's celebrations and slogans (words that must never appear; all 2+ words, so every text is checked)
	"night night", "ice in my veins", "too small", "let him cook", "trust the process", "board man gets paid",
	"rock the baby", "light the beam", "fear the deer", "we the north", "strength in numbers", "grit and grind",
	"heat culture", "thunder up", "dub nation", "bucks in six",
	# P12-02 / P12-11: the young stars of 2024-2026 and the dunk contest
	"j dub", "jdub", "hali", "podz", "bub", "hachi", "wonder boy", "maple jordan", "hillbilly kobe", "airplane mode",
	"splash mountain", "thompson twins", "bronny", "honey dip", "eastbay", "eastbay funk dunk",
	# P12-11: the finger-wag block line (docs/legends-namecheck.md "Cautions": never in Firewall's texts)
	"not in my house",
	# P12-02 / P12-11: shoe and product lines whose names could be a nickname ("all star" and "why not" are 2 words, so
	# no text may hold them either)
	"hyper", "hyperdunk", "hyperdrive", "hyperfuse", "hyperrev", "zoom", "zoom freak", "freak", "air max",
	"foamposite", "uptempo", "air force", "air force one", "kyrie", "why not", "gt cut", "curry flow", "hovr",
	"way of wade", "shaqnosis", "kamikaze", "the pump", "chuck taylor", "all star", "boost", "crazy explosive",
	# P12-02 / P12-11: famous fictional cyborgs and robots (film, TV, games, comics); the six cyber words are also
	# checked one by one in every text (CYBER_WORDS)
	"winter soldier", "bucky", "silverhand", "johnny silverhand", "edward elric", "elric", "fullmetal",
	"full metal alchemist", "jax briggs", "cyclops", "geordi", "la forge", "lobot", "robocop", "robo cop", "robo",
	"terminator", "t 800", "t 1000", "cyborg", "bionic", "bionic man", "bionic woman", "six million dollar man",
	"android", "iron", "iron man", "ironman", "war machine", "ultron", "inspector gadget", "gadget", "motoko",
	"kusanagi", "ghost in the shell", "adam jensen", "deus ex", "genji", "raiden", "sektor", "cyrax", "deathlok",
	"cable", "nebula", "seven of nine", "borg", "baymax", "wall e", "astro boy", "mega man", "megaman", "alita",
	"octane", "doomfist", "junkrat", "kay o", "master chief", "tron", "daft punk", "vanellope", "optimus prime",
	"megatron", "starscream",
]
# P12-11 (the namecheck doc's proposal, the board's cyber rule): these words never appear in a legend's name or in any
# of his texts (bio, look, signature, challenge line, archetype), checked one word at a time (REAL_NICKNAMES checks
# 1-word entries only against the names)
const CYBER_WORDS := ["cyborg", "bionic", "robo", "terminator", "android", "iron"]
const REAL_NAMES := [
	"michael jordan", "magic johnson", "earvin johnson", "larry bird", "kareem abdul jabbar", "wilt chamberlain",
	"bill russell", "oscar robertson", "jerry west", "elgin baylor", "julius erving", "george mikan", "bob cousy",
	"bob pettit", "pete maravich", "walt frazier", "earl monroe", "dave bing", "john havlicek", "willis reed",
	"wes unseld", "elvin hayes", "nate archibald", "moses malone", "george gervin", "connie hawkins",
	"cornelius hawkins", "artis gilmore", "dan issel", "mel daniels", "rick barry", "spencer haywood", "bill walton",
	"dave cowens", "david thompson", "bob lanier", "bob mcadoo", "isiah thomas", "kevin mchale", "robert parish",
	"dennis johnson", "james worthy", "dominique wilkins", "clyde drexler", "charles barkley", "karl malone",
	"john stockton", "patrick ewing", "hakeem olajuwon", "david robinson", "scottie pippen", "dennis rodman",
	"shaquille oneal", "kobe bryant", "tim duncan", "kevin garnett", "allen iverson", "gary payton", "jason kidd",
	"steve nash", "dirk nowitzki", "paul pierce", "ray allen", "reggie miller", "vince carter", "tracy mcgrady",
	"dwyane wade", "lebron james", "carmelo anthony", "chris paul", "dwight howard", "kevin durant",
	"stephen curry", "james harden", "russell westbrook", "kawhi leonard", "giannis antetokounmpo", "nikola jokic",
	"luka doncic", "joel embiid", "anthony davis", "damian lillard", "kyrie irving", "jayson tatum",
	"victor wembanyama", "shai gilgeous alexander", "anthony edwards", "zion williamson", "alonzo mourning",
	"dikembe mutombo", "anfernee hardaway", "grant hill", "chris webber", "ben wallace", "manu ginobili",
	"tony parker", "yao ming", "pau gasol", "paul george", "jimmy butler", "ja morant", "klay thompson",
	"draymond green", "bernard king", "adrian dantley", "alex english", "sidney moncrief", "calvin murphy",
	"hal greer", "sam jones", "paul arizin", "dolph schayes", "nate thurmond", "jerry lucas", "billy cunningham",
	"lenny wilkens", "gail goodrich", "louie dampier", "roger brown", "zelmo beaty", "warren jabali", "mack calvin",
	"ron boone", "willie wise", "james silas", "darnell hillman", "marvin barnes", "freddie lewis", "jimmy jones",
	"earl manigault", "demetrius mitchell", "joe hammond", "richard kirkland", "rafer alston", "herman knowings",
	"jackie jackson", "james williams", "meadowlark lemon", "fred neal", "marques haynes", "reece tatum",
	"lou dunbar", "neil johnston", "bill sharman", "tom heinsohn", "kc jones", "k c jones", "jo jo white",
	"dave debusschere", "bill bradley", "wally szczerbiak", "chet walker", "gus johnson", "jack twyman",
	"maurice stokes", "bob davies", "max zaslofsky", "joe fulks", "jim pollard", "vern mikkelsen", "slater martin",
	"cliff hagan", "ed macauley", "frank selvy", "tom gola", "guy rodgers", "walt bellamy",
	"dick barnett", "cazzie russell", "lou hudson", "bob love", "jerry sloan", "norm van lier", "tiny archibald",
	# P10-11: the 2000s era (and the two Phase 9 heads-up surnames, Vance and Riley; docs/legends-namecheck.md)
	"gene vance", "larry nance", "pat riley", "eric riley",
	"rasheed wallace", "chauncey billups", "richard hamilton", "tayshaun prince", "shane battier", "tony allen",
	"bruce bowen", "ron artest", "metta world peace", "stephen jackson", "jason terry", "jason richardson",
	"gilbert arenas", "stephon marbury", "steve francis", "baron davis", "jason williams", "antoine walker",
	"shawn marion", "amare stoudemire", "elton brand", "jermaine oneal", "peja stojakovic", "mike bibby",
	"andrei kirilenko", "zydrunas ilgauskas", "michael redd", "rashard lewis", "ben gordon", "gerald wallace",
	"josh smith", "nate robinson", "jamal crawford", "lamar odom", "michael finley", "glenn robinson",
	"latrell sprewell", "kenyon martin", "desmond mason", "cuttino mobley", "larry hughes", "jamaal tinsley",
	"steve smith", "raja bell", "ricky davis", "corey maggette", "bonzi wells", "brad miller", "sam cassell",
	"mike miller", "joe johnson", "chris bosh", "deron williams", "rajon rondo", "andre iguodala", "monta ellis",
	"tyson chandler", "marcus camby", "theo ratliff", "tim hardaway", "mitch richmond", "glen rice",
	"allan houston", "antawn jamison", "shareef abdur rahim", "darius miles", "quentin richardson",
	"kirk hinrich", "andre miller", "mike dunleavy", "caron butler", "luol deng", "josh howard", "richard jefferson",
	"vlade divac", "predrag stojakovic", "hedo turkoglu", "emeka okafor", "al jefferson", "kevin martin",
	"jalen rose", "eddie jones", "keith van horn", "derek fisher", "robert horry", "bobby jackson", "mo williams",
	"chucky atkins", "eric snow", "aaron mckie", "derrick coleman", "nick van exel", "damon stoudamire",
	"jerry stackhouse", "rod strickland", "terrell brandon", "kenny anderson", "derek anderson", "brent barry",
	"jason kapono", "fred jones", "dee brown", "harold miner", "god shammgod",
	"grayson boucher", "philip champion", "aaron owens", "waliyy dixon", "troy jackson", "shane woney",
	# P11-02 / P11-11: the draft names' matches, today's NBA (about 2015-2026) and the WNBA (suffixes left off)
	"torraye braggs", "rolando ferreira", "santi aldama", "rick calloway", "theo maledon", "lucian whitaker",
	"devin booker", "donovan mitchell", "trae young", "jaylen brown", "bam adebayo", "jrue holiday",
	"kristaps porzingis", "rudy gobert", "karl anthony towns", "jalen brunson", "tyrese haliburton", "deaaron fox",
	"domantas sabonis", "pascal siakam", "lauri markkanen", "demar derozan", "zach lavine", "bradley beal",
	"kemba walker", "kyle lowry", "mikal bridges", "og anunoby", "paolo banchero", "chet holmgren", "cade cunningham",
	"evan mobley", "scottie barnes", "jaren jackson", "desmond bane", "tyrese maxey", "jamal murray",
	"michael porter", "aaron gordon", "alperen sengun", "franz wagner", "jalen williams", "jalen green",
	"jalen duren", "jalen johnson", "jalen suggs", "lamelo ball", "lonzo ball", "ben simmons", "brandon ingram",
	"cj mccollum", "fred vanvleet", "kevin love", "kyle kuzma", "dangelo russell", "marcus smart", "al horford",
	"tobias harris", "khris middleton", "dejounte murray", "darius garland", "jarrett allen", "julius randle",
	"deandre ayton", "clint capela", "steven adams", "myles turner", "nikola vucevic", "brook lopez",
	"deandre jordan", "blake griffin", "isaiah thomas", "derrick rose", "john wall", "demarcus cousins",
	"gordon hayward", "kyle korver", "jj redick", "patrick beverley", "lou williams", "andre drummond", "jeremy lin",
	"terry rozier", "jordan poole", "anfernee simons", "josh giddey", "victor oladipo", "jabari smith",
	"amen thompson", "ausar thompson", "cooper flagg", "dylan harper", "zaccharie risacher", "alex sarr",
	"stephon castle", "austin reaves", "dereck lively", "brandon miller", "scoot henderson", "josh hart",
	"donte divincenzo", "alex caruso", "naz reid", "herbert jones", "derrick white", "ivica zubac",
	"bogdan bogdanovic", "goran dragic", "jusuf nurkic", "jonas valanciunas", "dennis schroder", "nicolas batum",
	"evan fournier", "danilo gallinari", "marc gasol", "serge ibaka", "hassan whiteside", "mark williams",
	"kevin porter", "jonathan kuminga", "tyler herro", "jaden mcdaniels",
	"aja wilson", "breanna stewart", "caitlin clark", "angel reese", "sabrina ionescu", "paige bueckers",
	"napheesa collier", "diana taurasi", "sue bird", "candace parker", "maya moore", "elena delle donne",
	"brittney griner", "kelsey plum", "jewell loyd", "arike ogunbowale", "aliyah boston", "jonquel jones",
	"alyssa thomas", "skylar diggins smith", "chelsea gray", "nneka ogwumike", "tina charles", "sylvia fowles",
	"lindsay whalen", "kahleah copper", "jackie young", "kelsey mitchell", "rhyne howard", "cameron brink",
	"kamilla cardoso", "courtney vandersloot", "allie quigley", "dewanna bonner", "satou sabally", "natasha cloud",
	"dearica hamby", "seimone augustus", "lisa leslie", "sheryl swoopes", "cynthia cooper", "tamika catchings",
	"lauren jackson", "becky hammon", "juju watkins",
	# P12-02 / P12-11: the 2024 draft class
	"reed sheppard", "ron holland", "donovan clingan", "rob dillingham", "zach edey", "cody williams", "matas buzelis",
	"nikola topic", "devin carter", "carlton carrington", "kelel ware", "jared mccain", "dalton knecht",
	"tristan da silva", "jakobe walter", "yves missi", "kyshawn george", "bronny james", "jaylen wells",
	"ajay mitchell", "isaiah collier", "tidjane salaun", "kyle filipowski",
	# 2025
	"vj edgecombe", "kon knueppel", "ace bailey", "tre johnson", "jeremiah fears", "egor demin",
	"collin murray boyles", "khaman maluach", "cedric coward", "noa essengue", "derik queen", "carter bryant",
	"thomas sorber", "yang hansen", "joan beringer", "walter clayton", "nolan traore", "kasparas jakucionis",
	"will riley", "drake powell", "asa newell", "jase richardson", "ben saraf", "danny wolf", "hugo gonzalez",
	"liam mcneeley", "rasheer fleming", "noah penda",
	# 2026, and the WNBA's
	"aj dybantsa", "darryn peterson", "cameron boozer", "caleb wilson", "nate ament", "mikel brown",
	"kingston flemings", "jayden quaintance", "koa peat", "darius acuff", "chris cenac", "brayden burries",
	"keaton wagler", "hannes steinbach", "karim lopez", "henri veesaar", "aday mara", "zuby ejiofor", "azzi fudd",
	"lauren betts", "olivia miles", "flaujae johnson", "kiki rice",
	# today's young stars and role players
	"payton pritchard", "dyson daniels", "jaden ivey", "bennedict mathurin", "keegan murray", "walker kessler",
	"jaime jaquez", "trey murphy", "deni avdija", "keyonte george", "brandin podziemski", "trayce jackson davis",
	"gradey dick", "bilal coulibaly", "cason wallace", "jarace walker", "anthony black", "cam whitmore",
	"shaedon sharpe", "jeremy sochan", "kevin huerter", "duncan robinson", "sam hauser", "grayson allen",
	"nic claxton", "mitchell robinson", "daniel gafford", "jordan clarkson", "bones hyland", "andrew wiggins",
	"kate martin", "rickea jackson", "dominique malonga", "sonia citron", "kiki iriafen", "aneesah morrow",
	"hailey van lith",
	# the dunk contest
	"mac mcclung", "derrick jones", "obi toppin", "hamidou diallo", "jaxson hayes", "jericho sims", "gerald green",
	"jeremy evans", "spud webb", "cedric ceballos", "isaiah rider",
	# Japan
	"rui hachimura", "yuta watanabe", "yuki kawamura", "yudai baba", "yuta tabuse", "rui machida", "yuki togashi",
	# Europe
	"moritz wagner", "isaiah hartenstein", "daniel theis", "goga bitadze", "sasha vezenkov", "vasilije micic",
	"dario saric", "sergio llull", "facundo campazzo", "edy tavares", "mike james", "nikola mirotic",
	"kostas sloukas", "mathias lessort", "shane larkin", "will clyburn", "kevin punter", "tornike shengelia",
	"nigel hayes davis", "nadir hifi", "sylvain francisco", "mario hezonja", "jan vesely", "nick calathes",
	# the close matches of the Chapter 4 names
	"leandro barbosa", "joe ingles", "tom ingelsby", "joe strawder",
]

# The test's own check that the name check works: these must fail it.
const NAMECHECK_PROBES := [
	{"first": "Ezekiel", "last": "Oakhurst", "name": "AIR"},
	{"first": "Bob", "last": "Pettit", "name": "STEEPLE"},
	{"first": "Harlan", "last": "Malone", "name": "SET SHOT"},
	{"first": "Harlan", "last": "Malon", "name": "SET SHOT"},
	{"first": "Otis", "last": "Brannigan", "name": "THE SKY HOOK"},
	{"first": "Desmond", "last": "Ashby", "name": "MAGIC TOUCH"},
	# P10-11: the 2000s list bites (a real surname, one letter from one, a 2000s nickname as a word)
	{"first": "Dorian", "last": "Vance", "name": "ROOFTOP"},
	{"first": "Keon", "last": "Ridley", "name": "EYES CLOSED"},
	{"first": "Shane", "last": "Battier", "name": "LOCKBOX"},
	{"first": "Tremaine", "last": "Pettaway", "name": "THE ANSWER"},
	{"first": "Darnell", "last": "Kingsley", "name": "BIG SHOT"},
	# P11-11: the flagged Present draft names, a present-day nickname and a celebration in a text
	{"first": "Calloway", "last": "Briggs", "name": "DEEP END"},
	{"first": "Bodie", "last": "Ferreira", "name": "SKYLIGHT"},
	{"first": "Theo", "last": "Lindqvist", "name": "SWISS KNIFE"},
	{"first": "Sigurd", "last": "Halvorsen", "name": "STIFLE TOWER"},
	{"first": "Calloway", "last": "Whitlock", "name": "DEEP END", "bio": "Hits the shot, then puts the crowd to bed: night night."},
	# P12-02 / P12-11: a shoe line, a young star's nickname, a real surname, a fictional cyborg, a cyborg's look, a TV
	# cyborg and a block line in a text, and one cyber word alone in a text (CYBER_WORDS)
	{"first": "Tavian", "last": "Brightwell", "name": "HYPERDRIVE"},
	{"first": "Silvan", "last": "Ingleby", "name": "AIRPLANE MODE"},
	{"first": "Silvan", "last": "Ingles", "name": "UPDRAFT"},
	{"first": "Kasimir", "last": "Oyelaran", "name": "CYCLOPS"},
	{"first": "Cosimo", "last": "Draycott", "name": "GLITCH", "look": "a whole silver arm like the winter soldier"},
	{"first": "Calder", "last": "Ostrander", "name": "LONG SHADOW", "bio": "Runs like the six million dollar man."},
	{"first": "Emrys", "last": "Tregarth", "name": "HALFCOURT", "bio": "Swats it away and wags a finger: not in my house."},
	{"first": "Kasimir", "last": "Oyelaran", "name": "FIREWALL", "bio": "Reads every shot through his bionic visor."},
]

static var notes: Array = []        # self_test(): things that fall back for now (art or story not merged yet)

# ---------------------------------------------------------------------------------------------------- test data hook
# P10-02: a test-only stand-in for the rows, so the multi-chapter paths are tested before a chapter's real data is
# merged (Legends.self_test(): set_test_data(stand_in_test_data(ch)), then clear_test_data()). Never set in a game;
# empty = the shipped CHAPTERS / LEGENDS. Every getter below reads the rows through chapter_rows() / legend_rows();
# the name check and self_test() read the shipped consts only. P11-03: stand_in_test_data(chapter_id) builds any row
# (two_chapter_test_data() = the Phase 10 one, "fathers"), so three built chapters run before Chapter 3's rows land.
# P12-03: stand_in_test_data("next") the same way (ids lg_zz_next_1..6), four built chapters before Chapter 4's rows
# land; with every row built there is no chapter after the last (no unbuilt row is ever needed).
static var _test_chapters: Array = []
static var _test_legends: Dictionary = {}

const TEST_CHAPTER := "fathers"     # two_chapter_test_data(): the chapter row it builds (a stand-in, not the real one)
const TEST_PREFIX := "lg_zz_"       # stand-in legend ids: lg_zz_1 .. lg_zz_6 for TEST_CHAPTER (as in Phase 10),
                                    # lg_zz_<chapter>_1 .. 6 for any other row (never a shipped id)
const TEST_CHALLENGE_AVG := 70      # its per-chapter rating keys (all unlike the defaults, so the test sees them)
const TEST_MATE_DROP := 10
const TEST_FINALE_STAGE_AVG := 56

static func set_test_data(data: Dictionary) -> void:
	_test_chapters = (data.get("chapters", []) as Array).duplicate(true)
	_test_legends = (data.get("legends", {}) as Dictionary).duplicate(true)

static func clear_test_data() -> void:
	_test_chapters = []
	_test_legends = {}

static func test_data_on() -> bool:
	return not _test_chapters.is_empty() or not _test_legends.is_empty()

static func chapter_rows() -> Array:
	return _test_chapters if not _test_chapters.is_empty() else CHAPTERS

static func legend_rows() -> Dictionary:
	return _test_legends if not _test_legends.is_empty() else LEGENDS

# The Phase 10 stand-in: stand_in_test_data(TEST_CHAPTER), the same rows as before P11-03.
static func two_chapter_test_data() -> Dictionary:
	return stand_in_test_data(TEST_CHAPTER)

# The stand-in id prefix of a chapter's copies: "lg_zz_" for TEST_CHAPTER, "lg_zz_<chapter>_" for any other.
static func stand_in_prefix(chapter_id: String) -> String:
	return TEST_PREFIX if chapter_id == TEST_CHAPTER else TEST_PREFIX + chapter_id + "_"

# The shipped rows with chapter_id's row replaced by a built stand-in (built or not before: its real legends, once it
# has some, step aside): 6 legends <stand_in_prefix()>1..6 (copies of the first other built chapter's: shapes,
# challenges, perks; names "ZZ ONE".. "ZZ SIX"), its finale (the copies of that chapter's finale three), the
# per-chapter keys TEST_*, its own gate and name, a look, twist and music that don't exist (so the fallbacks play:
# gym, none, the source chapter's fallback_music) and story scenes that don't exist (skipped). An unknown chapter id
# (or no other built chapter to copy): the shipped rows unchanged.
# Returns {"chapters": [...], "legends": {...}} for set_test_data().
static func stand_in_test_data(chapter_id: String) -> Dictionary:
	var src: Dictionary = {}
	var known: bool = false
	for row in CHAPTERS:
		var rid: String = str(row.get("id", ""))
		if rid == chapter_id:
			known = true
		elif src.is_empty() and bool(row.get("built", false)):
			src = row
	if not known or src.is_empty():
		return {"chapters": CHAPTERS.duplicate(true), "legends": LEGENDS.duplicate(true)}
	var prefix: String = stand_in_prefix(chapter_id)
	var tag: String = "zz_" if chapter_id == TEST_CHAPTER else "zz_" + chapter_id + "_"   # its scene and file names
	var words: Array = ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX"]
	var map: Dictionary = {}
	var src_ids: Array = src.get("legends", [])
	for i in src_ids.size():
		map[str(src_ids[i])] = prefix + str(i + 1)
	var legends: Dictionary = {}
	for id in LEGENDS:
		if str(LEGENDS[id].get("chapter", "")) != chapter_id:   # the real row's legends (once built) step aside
			legends[id] = (LEGENDS[id] as Dictionary).duplicate(true)
	var new_ids: Array = []
	for i in src_ids.size():
		var old: String = str(src_ids[i])
		var nid: String = str(map[old])
		var p: Dictionary = (LEGENDS[old] as Dictionary).duplicate(true)
		var word: String = str(words[i]) if i < words.size() else str(i + 1)
		p["name"] = "ZZ " + word
		p["first"] = "Test"
		p["last"] = "Standin"
		p["full"] = "Test \"%s\" Standin" % str(p["name"]).capitalize()
		p["chapter"] = chapter_id
		p["unlock_scene"] = nid + "_unlock"
		var c: Dictionary = p.get("challenge", {})
		var mates: Array = []
		for m in c.get("mates", []):
			mates.append(str(map.get(str(m), str(m))))
		c["mates"] = mates
		p["challenge"] = c
		legends[nid] = p
		new_ids.append(nid)
	var fin_src: Dictionary = src.get("finale", {})
	var fin_ids: Array = []
	for id in fin_src.get("legends", []):
		fin_ids.append(str(map.get(str(id), str(id))))
	var chapters: Array = []
	for row in CHAPTERS:
		var r: Dictionary = (row as Dictionary).duplicate(true)
		if str(row.get("id", "")) == chapter_id:
			r["built"] = true
			r["rules"] = "ZZ RULES"
			r["twist"] = tag + "no_twist"
			r["look"] = tag + "no_look"
			r["music"] = tag + "no_music"
			r["fallback_music"] = str(src.get("fallback_music", ""))
			r["crew"] = {"name": "ZZ CREW", "style": str((src.get("crew", {}) as Dictionary).get("style", "")),
				"colors": ((src.get("crew", {}) as Dictionary).get("colors", []) as Array).duplicate(),
				"ui_color": Color(0.2, 0.4, 0.8)}
			r["legends"] = new_ids
			r["finale"] = {"target": int(fin_src.get("target", 21)), "legends": fin_ids, "label": "ZZ FINALE"}
			r["intro_scene"] = tag + "intro"
			r["finale_scenes"] = {"before": tag + "finale_before", "after": tag + "finale_after"}
			r["challenge_avg"] = TEST_CHALLENGE_AVG
			r["mate_drop"] = TEST_MATE_DROP
			r["finale_stage_avg"] = TEST_FINALE_STAGE_AVG
		chapters.append(r)
	return {"chapters": chapters, "legends": legends}

# ---------------------------------------------------------------------------------------------------- getters

# a legend's data ({} for an unknown id)
static func legend(id: String) -> Dictionary:
	return legend_rows().get(id, {})

# a chapter's row ({} for an unknown id)
static func chapter(id: String) -> Dictionary:
	for row in chapter_rows():
		if str(row.get("id", "")) == id:
			return row
	return {}

# every chapter id, in timeline order
static func chapter_ids() -> Array:
	var out: Array = []
	for row in chapter_rows():
		out.append(str(row.get("id", "")))
	return out

# the chapter a legend belongs to ("" for an unknown id)
static func chapter_of(legend_id: String) -> String:
	return str(legend(legend_id).get("chapter", ""))

# the ids of the chapters that are built (playable), in timeline order
static func built_chapters() -> Array:
	var out: Array = []
	for row in chapter_rows():
		if bool(row.get("built", false)):
			out.append(str(row.get("id", "")))
	return out

static func is_built(chapter_id: String) -> bool:
	return bool(chapter(chapter_id).get("built", false))

# a chapter's legend ids in plaque order (every built chapter's in timeline order for "")
static func legend_ids(chapter_id: String = "") -> Array:
	var out: Array = []
	for row in chapter_rows():
		if chapter_id == "" or str(row.get("id", "")) == chapter_id:
			for id in row.get("legends", []):
				out.append(str(id))
	return out

# a known legend id (an "lg_" id with a row here)
static func is_legend_id(id: String) -> bool:
	return id.begins_with(ID_PREFIX) and legend_rows().has(id)

# a chapter has a finale (every built chapter has one; self_test checks it)
static func has_finale(chapter_id: String) -> bool:
	return not (chapter(chapter_id).get("finale", {}) as Dictionary).is_empty()

# the most tokens one chapter gives: its challenges and its finale at TOKEN_MAX (0 for a chapter that isn't built)
static func chapter_max_tokens(chapter_id: String) -> int:
	if not is_built(chapter_id):
		return 0
	var n: int = legend_ids(chapter_id).size()
	if has_finale(chapter_id):
		n += 1
	return n * TOKEN_MAX

# the most tokens there are: every built chapter's chapter_max_tokens()
static func max_tokens() -> int:
	var n: int = 0
	for ch in built_chapters():
		n += chapter_max_tokens(str(ch))
	return n

# the tokens a win on this level gives (0 for an unknown level)
static func tokens_for(level: String) -> int:
	return int(TOKENS_BY_LEVEL.get(level, 0))

# a legend's challenge row ({} for an unknown id)
static func challenge(legend_id: String) -> Dictionary:
	return legend(legend_id).get("challenge", {})

# the challenge's opponents: [the legend, his 2 mates]
static func challenge_team(legend_id: String) -> Array:
	if not legend_rows().has(legend_id):
		return []
	var out: Array = [legend_id]
	for m in challenge(legend_id).get("mates", []):
		out.append(str(m))
	return out

# the finale's 3 legends ([] for a chapter without one)
static func finale_team(chapter_id: String) -> Array:
	var f: Dictionary = chapter(chapter_id).get("finale", {})
	return (f.get("legends", []) as Array).duplicate()

# a perk's row ({} for an unknown id); perk_of(): the perk a legend teaches
static func perk(perk_id: String) -> Dictionary:
	return PERKS.get(perk_id, {})

static func perk_of(legend_id: String) -> Dictionary:
	return perk(str(legend(legend_id).get("perk", "")))

# ---------------------------------------------------------------------------------------------------- ratings

# the chapter's rating keys (P10-02): its row's value, else the constant (an unknown chapter: the constant)
static func challenge_avg(chapter_id: String) -> int:
	return int(chapter(chapter_id).get("challenge_avg", CHALLENGE_AVG))

static func mate_drop(chapter_id: String) -> int:
	return int(chapter(chapter_id).get("mate_drop", MATE_DROP))

static func finale_stage_avg(chapter_id: String) -> int:
	return int(chapter(chapter_id).get("finale_stage_avg", FINALE_STAGE_AVG))

# a legend's five stats at a level: avg + his shape on each stat, each in RATING_MIN..RATING_CAP ({} for an unknown id)
static func shaped(legend_id: String, avg: int) -> Dictionary:
	var p: Dictionary = legend(legend_id)
	if p.is_empty():
		return {}
	var shape: Dictionary = p.get("shape", {})
	var out: Dictionary = {}
	for s in STATS:
		out[s] = clampi(avg + int(shape.get(s, 0)), RATING_MIN, RATING_CAP)
	return out

# the challenge legend (L3 b): his chapter's challenge_avg() + his shape + bonus (Difficulty.rating_bonus(level),
# LEGEND), capped
static func challenge_ratings(legend_id: String, bonus: int = 0) -> Dictionary:
	return shaped(legend_id, challenge_avg(chapter_of(legend_id)) + bonus)

# one of his 2 legend teammates (always of the same chapter, self_test checks it): his chapter's mate_drop() under
# its challenge_avg(), his own shape, + bonus, capped
static func mate_ratings(legend_id: String, bonus: int = 0) -> Dictionary:
	var ch: String = chapter_of(legend_id)
	return shaped(legend_id, challenge_avg(ch) - mate_drop(ch) + bonus)

# a drafted legend on the Road Trip (L7 a): stage average + DRAFT_TIER, shaped, capped (trip.gd passes the stage
# reached's Cities.stage_avg())
static func draft_ratings(legend_id: String, stage_avg: int) -> Dictionary:
	return shaped(legend_id, stage_avg + DRAFT_TIER)

# a finale legend: the drafted rule at his chapter's finale_stage_avg() (+ DRAFT_TIER), shaped, + bonus, capped
static func finale_ratings(legend_id: String, bonus: int = 0) -> Dictionary:
	return shaped(legend_id, finale_stage_avg(chapter_of(legend_id)) + DRAFT_TIER + bonus)

# ---------------------------------------------------------------------------------------------------- name check

# lower case, letters, digits and single spaces only; a leading "the " dropped
static func normalize(s: String) -> String:
	var low: String = s.to_lower()
	var out: String = ""
	for i in low.length():
		var c: String = low[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
		elif c != "'":
			out += " "
	var words: PackedStringArray = out.split(" ", false)
	if words.size() > 1 and words[0] == "the":
		words.remove_at(0)
	return " ".join(words)

# true when the phrase (normalized, 1+ words) appears as whole words in text (normalized)
static func _has_phrase(text: String, phrase: String) -> bool:
	if phrase == "" or text == "":
		return false
	return (" " + text + " ").contains(" " + phrase + " ")

# letters apart (Levenshtein), for "close" surnames
static func _distance(a: String, b: String) -> int:
	var prev: Array = []
	for j in b.length() + 1:
		prev.append(j)
	for i in a.length():
		var cur: Array = [i + 1]
		for j in b.length():
			var cost: int = 0 if a[i] == b[j] else 1
			cur.append(mini(mini(int(cur[j]) + 1, int(prev[j + 1]) + 1), int(prev[j]) + cost))
		prev = cur
	return int(prev[b.length()])

static func _surnames() -> Array:
	var out: Array = []
	for full in REAL_NAMES:
		var words: PackedStringArray = normalize(str(full)).split(" ", false)
		if words.size() > 0:
			out.append(words[words.size() - 1])
	return out

# "" when a name (nickname, first, last) and its texts pass the name check, else why not
static func name_hit(p: Dictionary) -> String:
	var nick: String = normalize(str(p.get("name", "")))
	var first: String = normalize(str(p.get("first", "")))
	var last: String = normalize(str(p.get("last", "")))
	var whole: String = (first + " " + nick + " " + last).strip_edges()
	for rn in REAL_NICKNAMES:
		var n: String = normalize(str(rn))
		if nick == n:
			return "nickname '%s' is a real nickname" % nick
		if _has_phrase(whole, n):
			return "'%s' holds the real nickname '%s'" % [whole, n]
	var full: String = first + " " + last
	if REAL_NAMES.has(full) or REAL_NAMES.has(normalize(full)):
		return "'%s' is a real player's name" % full
	for sur in _surnames():
		if last == sur:
			return "last name '%s' is a real player's" % last
		if last.length() >= 5 and _distance(last, str(sur)) <= 1:
			return "last name '%s' is one letter from '%s'" % [last, sur]
	var texts: Array = [p.get("bio", ""), p.get("look", ""), (p.get("signature", {}) as Dictionary).get("text", ""),
			(p.get("challenge", {}) as Dictionary).get("line", ""), p.get("archetype", "")]
	for t in texts:
		var tn: String = normalize(str(t))
		for rn in REAL_NAMES:
			if _has_phrase(tn, normalize(str(rn))):
				return "a text names '%s'" % rn
		for rn in REAL_NICKNAMES:
			var n2: String = normalize(str(rn))
			if n2.contains(" ") and _has_phrase(tn, n2):
				return "a text holds the real nickname '%s'" % n2
		for w in CYBER_WORDS:
			if _has_phrase(tn, str(w)):
				return "a text holds the word '%s' (the cyber rule)" % w
	return ""

# "" when every legend passes the name check (and the probes fail it, so the check works), else why not
static func name_check() -> String:
	for probe in NAMECHECK_PROBES:
		if name_hit(probe) == "":
			return "the name check let a probe through: %s" % JSON.stringify(probe)
	for id in LEGENDS:
		var why: String = name_hit(LEGENDS[id])
		if why != "":
			return "%s: %s" % [id, why]
	for row in CHAPTERS:
		var cn: String = normalize(str(row.get("name", "")))
		for rn in REAL_NAMES:
			if _has_phrase(cn, normalize(str(rn))):
				return "chapter %s names '%s'" % [row.get("id", ""), rn]
	return ""

# ---------------------------------------------------------------------------------------------------- self test

# "" = every row complete and consistent, else the first problem. Missing art or story that falls back is listed in
# `notes` (not a failure) until its task lands: sheets (P9-09), portraits (P9-10), the era twist (P9-08), the era
# music (P9-16). Story scenes are checked strictly once story_text.gd has the chapter's intro scene (P9-14).
static func self_test() -> String:
	notes = []
	# the shipped rows only: a test data hook left on is put aside for the check and back after
	var kept_chapters: Array = _test_chapters
	var kept_legends: Dictionary = _test_legends
	clear_test_data()
	var why: String = _self_test_rows()
	_test_chapters = kept_chapters
	_test_legends = kept_legends
	return why

static func _self_test_rows() -> String:
	var why: String = _check_chapters()
	if why != "":
		return why
	why = _check_legends()
	if why != "":
		return why
	why = _check_perks()
	if why != "":
		return why
	why = _check_ratings()
	if why != "":
		return why
	why = name_check()
	if why != "":
		return "name check: " + why
	return ""

static func _check_chapters() -> String:
	var want_ids: Array = ["grand", "fathers", "present", "next"]
	if chapter_ids() != want_ids:
		return "chapters are %s, want %s" % [str(chapter_ids()), str(want_ids)]
	var keys: Array = ["id", "name", "built", "rules", "feel", "twist", "look", "music", "fallback_music", "gate",
			"crew", "legends", "finale", "intro_scene", "finale_scenes"]
	var story: GDScript = _load(STORY_PATH)
	var twists: GDScript = _load(TWISTS_PATH)
	var looks: GDScript = _load(LOOKS_PATH)
	var last_stars: int = 0
	var last_tokens: int = -1
	var seen_legends: Array = []
	for row in CHAPTERS:
		var ch: String = str(row.get("id", ""))
		for k in keys:
			if not row.has(k):
				return "chapter %s has no '%s'" % [ch, k]
		if str(row.name) == "":
			return "chapter %s has no name" % ch
		var gate: Dictionary = row.gate
		if not gate.has("stars") or not gate.has("tokens"):
			return "chapter %s: gate needs stars and tokens" % ch
		if int(gate.stars) <= last_stars or (int(gate.tokens) <= last_tokens and int(gate.tokens) != 0):
			return "chapter %s: gates must rise along the timeline" % ch
		last_stars = int(gate.stars)
		last_tokens = maxi(last_tokens, int(gate.tokens))
		# P10-02: the optional per-chapter rating keys, when there, are whole numbers in range
		for opt in [["challenge_avg", CHAPTER_AVG_RANGE], ["mate_drop", CHAPTER_DROP_RANGE],
				["finale_stage_avg", CHAPTER_FINALE_RANGE]]:
			var k: String = str(opt[0])
			if not row.has(k):
				continue
			var v = row[k]
			var lim: Array = opt[1]
			if not (v is int) or int(v) < int(lim[0]) or int(v) > int(lim[1]):
				return "chapter %s: %s must be a whole number in %d..%d" % [ch, k, int(lim[0]), int(lim[1])]
		if not bool(row.built):
			if (row.legends as Array).size() > 0 or not (row.finale as Dictionary).is_empty():
				return "chapter %s is not built but has legends or a finale" % ch
			continue
		# a built chapter
		if ch == "grand" and (int(gate.stars) != 24 or int(gate.tokens) != 0):
			return "Chapter 1 opens at 24 stars only (L4 a)"
		var lg: Array = row.legends
		if lg.size() != 6:
			return "chapter %s has %d legends, want 6" % [ch, lg.size()]
		for id in lg:
			if not LEGENDS.has(id):
				return "chapter %s names unknown legend %s" % [ch, id]
			if chapter_of(id) != ch:
				return "%s is in chapter %s but says %s" % [id, ch, chapter_of(id)]
			if seen_legends.has(id):
				return "%s is in two chapters" % id
			seen_legends.append(id)
		var fin: Dictionary = row.finale
		var ft: Array = fin.get("legends", [])
		if int(fin.get("target", 0)) != 21 or str(fin.get("label", "")) == "" or ft.size() != 3:
			return "chapter %s: the finale needs target 21, a label and 3 legends" % ch
		for id in ft:
			if not lg.has(id) or ft.count(id) != 1:
				return "chapter %s: finale legend %s is not one of its 6 (or twice)" % [ch, id]
		var crew: Dictionary = row.crew
		for k in ["name", "style", "colors", "ui_color"]:
			if not crew.has(k):
				return "chapter %s: crew has no '%s'" % [ch, k]
		for k in ["twist", "look", "music", "fallback_music", "intro_scene"]:
			if str(row[k]) == "":
				return "chapter %s is built but has no %s" % [ch, k]
		if looks == null or not (looks.get_script_constant_map().get("LOOKS", {}) as Dictionary).has(str(row.look)):
			# the first built chapter's look must be there; a later chapter's court may land after its data (P10-11
			# before P10-05): the game plays the gym (main.gd's look fallback)
			if built_chapters().is_empty() or ch == str(built_chapters()[0]):
				return "chapter %s: look %s is not in court_looks.gd" % [ch, row.look]
			notes.append("chapter %s: look %s not in court_looks.gd yet; plays the gym" % [ch, row.look])
		if twists == null or not (twists.get_script_constant_map().get("TWISTS", {}) as Dictionary).has(str(row.twist)):
			notes.append("chapter %s: twist %s not in twists.gd yet (P9-08); plays twist none" % [ch, row.twist])
		if not ResourceLoader.exists(MUSIC_DIR + str(row.fallback_music) + ".ogg"):
			return "chapter %s: fallback music %s is missing" % [ch, row.fallback_music]
		if not ResourceLoader.exists(MUSIC_DIR + str(row.music) + ".ogg"):
			notes.append("chapter %s: music %s.ogg not there yet (P9-16); plays %s" % [ch, row.music, row.fallback_music])
		var fs: Dictionary = row.finale_scenes
		if str(fs.get("before", "")) == "" or str(fs.get("after", "")) == "":
			return "chapter %s: finale_scenes needs before and after" % ch
		var scenes: Array = [str(row.intro_scene), str(fs.before), str(fs.after)]
		for id in lg:
			scenes.append(str(legend(id).get("unlock_scene", "")))
		var strict: bool = story != null and bool(story.call("has_scene", str(row.intro_scene)))
		for sc in scenes:
			if sc == "":
				return "chapter %s: a scene id is empty" % ch
			if story != null and bool(story.call("has_scene", sc)):
				continue
			if strict:
				return "chapter %s: story scene %s is missing in story_text.gd" % [ch, sc]
		if not strict:
			notes.append("chapter %s: story scenes not written yet (P9-14); the story screen skips them" % ch)
	if built_chapters().is_empty() or built_chapters()[0] != "grand":
		return "Chapter 1 (grand) must be built"
	if seen_legends.size() != LEGENDS.size():
		return "%d legends in LEGENDS but %d in chapters" % [LEGENDS.size(), seen_legends.size()]
	var want_max: int = built_chapters().size() * 7 * TOKEN_MAX
	if max_tokens() != want_max:
		return "max_tokens() is %d, want %d (6 challenges + 1 finale, x3, per built chapter)" % [max_tokens(), want_max]
	return ""

static func _check_legends() -> String:
	var keys: Array = ["name", "full", "first", "last", "chapter", "archetype", "role", "tier", "sheet", "portrait",
			"number", "shape", "spec", "steal_bias", "block_bias", "signature", "challenge", "perk", "colors", "look",
			"bio", "unlock_scene"]
	var numbers: Array = []
	var perks_used: Array = []
	var sheets_missing: Array = []
	var portraits_missing: Array = []
	var mate_count: Dictionary = {}
	for id in LEGENDS:
		var p: Dictionary = LEGENDS[id]
		if not str(id).begins_with(ID_PREFIX):
			return "%s does not start with %s" % [id, ID_PREFIX]
		for k in keys:
			if not p.has(k):
				return "%s has no '%s'" % [id, k]
		if str(p.tier) != "legend":
			return "%s: tier must be legend" % id
		var full_want: String = "%s \"%s\" %s" % [p.first, str(p.name).capitalize(), p.last]
		if str(p.full) != full_want:
			return "%s: full '%s', want '%s'" % [id, p.full, full_want]
		if str(p.role) != str(p.archetype):
			return "%s: role and archetype differ" % id
		var shape: Dictionary = p.shape
		var sum: int = 0
		for s in STATS:
			if not shape.has(s):
				return "%s: shape has no %s" % [id, s]
			sum += int(shape[s])
		if sum != 0 or shape.size() != STATS.size():
			return "%s: shape sums to %d (want 0, five stats)" % [id, sum]
		var spec_want: Array = []
		for s in STATS:
			if int(shape[s]) >= SPEC_MIN:
				spec_want.append(s)
		if p.spec != spec_want:
			return "%s: spec %s, want %s (shape >= %d)" % [id, str(p.spec), str(spec_want), SPEC_MIN]
		var num: int = int(p.number)
		if num < 0 or num > 99 or NUMBER_AVOID.has(num) or numbers.has(num):
			return "%s: number %d is avoided, out of range or taken" % [id, num]
		numbers.append(num)
		var sig: Dictionary = p.signature
		if str(sig.get("id", "")) == "" or str(sig.get("text", "")) == "":
			return "%s: signature needs id and text" % id
		var c: Dictionary = p.challenge
		var ctype: String = str(c.get("type", ""))
		if not CHALLENGE_TYPES.has(ctype):
			return "%s: unknown challenge type '%s'" % [id, ctype]
		if int(c.get("target", 0)) <= 0 or str(c.get("line", "")) == "":
			return "%s: challenge needs a target and a line" % id
		for k in CHALLENGE_TYPES[ctype]:
			if not c.has(k):
				return "%s: a %s challenge needs '%s'" % [id, ctype, k]
		var why: String = _check_challenge_numbers(id, c)
		if why != "":
			return why
		var mates: Array = c.get("mates", [])
		if mates.size() != 2 or mates[0] == mates[1]:
			return "%s: challenge needs 2 different mates" % id
		for m in mates:
			if m == id or not LEGENDS.has(m) or chapter_of(m) != str(p.chapter):
				return "%s: mate %s is not another legend of his chapter" % [id, m]
			mate_count[m] = int(mate_count.get(m, 0)) + 1
		if not PERKS.has(str(p.perk)):
			return "%s: unknown perk %s" % [id, p.perk]
		if perks_used.has(str(p.perk)):
			return "%s: perk %s is taught by two legends" % [id, p.perk]
		perks_used.append(str(p.perk))
		if (p.colors as Array).size() != 2:
			return "%s: colors needs main and trim" % id
		if not ResourceLoader.exists(SHEET_DIR + str(p.sheet) + "_p0.png"):
			sheets_missing.append(str(p.sheet))
		elif not ResourceLoader.exists(SHEET_DIR + "palettes/" + str(p.sheet) + ".png"):
			return "%s: sheet %s has pages but no palette" % [id, p.sheet]
		if not ResourceLoader.exists(PORTRAIT_DIR + str(p.portrait) + ".png"):
			portraits_missing.append(str(p.portrait))
	for id in LEGENDS:
		if int(mate_count.get(id, 0)) == 0 and LEGENDS.size() > 3:
			notes.append("%s is never a mate (fine, but he only plays his own challenge and the finale)" % id)
	if not sheets_missing.is_empty():
		notes.append("sheets not made yet (P9-09; Sheets falls back): " + ", ".join(sheets_missing))
	if not portraits_missing.is_empty():
		notes.append("portraits not made yet (P9-10; story.gd shows a silhouette): " + ", ".join(portraits_missing))
	return ""

static func _check_challenge_numbers(id: String, c: Dictionary) -> String:
	var target: int = int(c.target)
	match str(c.type):
		"hold":
			if int(c.limit) < 1 or int(c.limit) >= target:
				return "%s: hold limit must be 1..target-1" % id
		"fire":
			if int(c.cool_misses) < 1:
				return "%s: fire cool_misses must be 1 or more" % id
		"stop":
			if int(c.count) < 1:
				return "%s: stop count must be 1 or more" % id
		"race":
			if int(c.their_target) < 1 or int(c.their_target) >= target:
				return "%s: race their_target must be 1..target-1" % id
		"comeback":
			var ss = c.start_score
			if not (ss is Array) or (ss as Array).size() != 2:
				return "%s: comeback start_score must be [you, them]" % id
			if int(ss[0]) < 0 or int(ss[1]) <= int(ss[0]) or int(ss[1]) >= target:
				return "%s: comeback must start behind and under the target" % id
		"score":
			if int(c.min) < 1 or int(c.min) > target:
				return "%s: score min must be 1..target" % id
	return ""

static func _check_perks() -> String:
	var keys_seen: Array = []
	for pid in PERKS:
		var pk: Dictionary = PERKS[pid]
		var key: String = str(pk.get("key", ""))
		if key == "" or str(pk.get("text", "")) == "" or not pk.has("value"):
			return "perk %s needs key, value and text" % pid
		if keys_seen.has(key):
			return "perk %s: key %s is used twice" % [pid, key]
		keys_seen.append(key)
		var v: float = float(pk.value)
		if key.ends_with("_mult"):
			if is_equal_approx(v, 1.0) or absf(v - 1.0) > PERK_MULT_MAX + 0.0001:
				return "perk %s: a _mult value must be 1.0 +- %.2f, not 1.0 (small, L8 a)" % [pid, PERK_MULT_MAX]
		elif key.ends_with("_bonus"):
			if v <= 0.0 or v > PERK_BONUS_MAX:
				return "perk %s: a _bonus value must be in (0, %.2f] (small, L8 a)" % [pid, PERK_BONUS_MAX]
		else:
			return "perk %s: key must end in _mult or _bonus" % pid
		var taught: int = 0
		for id in LEGENDS:
			if str(LEGENDS[id].get("perk", "")) == pid:
				taught += 1
		if taught != 1:
			return "perk %s is taught by %d legends, want 1" % [pid, taught]
	return ""

static func _check_ratings() -> String:
	if tokens_for("easy") != 1 or tokens_for("normal") != 2 or tokens_for("hard") != 3 or tokens_for("legend") != 3:
		return "TOKENS_BY_LEVEL must be 1 / 2 / 3 / 3"
	if tokens_for("nope") != 0 or not legend("nope").is_empty() or chapter_of("nope") != "" or is_legend_id("ud_deuce"):
		return "unknown ids must give empty answers"
	for id in LEGENDS:
		var tables: Array = [challenge_ratings(id), challenge_ratings(id, 12), mate_ratings(id), draft_ratings(id, 40),
				draft_ratings(id, 78), finale_ratings(id), finale_ratings(id, 12)]
		for t in tables:
			for s in STATS:
				var v: int = int((t as Dictionary).get(s, -1))
				if v < RATING_MIN or v > RATING_CAP:
					return "%s: %s %d is out of %d..%d" % [id, s, v, RATING_MIN, RATING_CAP]
		var cr: Dictionary = challenge_ratings(id)
		var mr: Dictionary = mate_ratings(id)
		var dr: Dictionary = draft_ratings(id, 40)
		var shape: Dictionary = legend(id).shape
		for s in STATS:
			if int(mr[s]) > int(cr[s]):
				return "%s: a mate is stronger than the legend at %s" % [id, s]
			if int(dr[s]) != clampi(40 + DRAFT_TIER + int(shape[s]), RATING_MIN, RATING_CAP):
				return "%s: draft_ratings(40) %s is %d" % [id, s, int(dr[s])]
		if challenge_team(id).size() != 3:
			return "%s: challenge_team is not 3" % id
	for ch in built_chapters():
		if finale_team(ch).size() != 3:
			return "chapter %s: finale_team is not 3" % ch
	return ""

static func _load(path: String) -> GDScript:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as GDScript

# --legendtest (main.gd): runs self_test(), prints its notes and LEGENDTEST OK or LEGENDTEST FAILED: <why>. Returns
# true when OK (main.gd quits with 0, else 1). P9-12 adds Legends.self_test() after this one.
static func legendtest() -> bool:
	var why: String = self_test()
	for n in notes:
		print("LEGENDTEST NOTE: ", n)
	print("LEGENDTEST legends %d, chapters %d built of %d, max tokens %d" % [LEGENDS.size(),
			built_chapters().size(), CHAPTERS.size(), max_tokens()])
	if why != "":
		print("LEGENDTEST FAILED: ", why)
		return false
	print("LEGENDTEST OK")
	return true
