extends RefCounted
# City and crew data for the Road Trip (P5-04, Phase 6 P6-10): plain const data plus a few tiny getters.
# Use it through   const Cities = preload("res://scripts/cities.gd")   (static functions only, never instanced).
# Safe to edit on the tablet: a typo shows as a parse error in the Godot editor right away.
#
# How the numbers are used (trip.gd):
#   a city player's rating on every stat = STAGE_AVG[city stage] + TIER[tier].all, plus TIER[tier].spec on each stat
#   listed in his "spec". Stats: speed, shooting, finishing, defense, stamina (0-100, 50 = today's Quick Game player).
#   steal = clampi(defense + steal_bias, 0, 100), block = clampi(defense + block_bias, 0, 100).
#   City games (owner): game 1 = 1 good + 2 average, game 2 = 2 good + 1 average, game 3 = 2 good + the boss.
#   A recruit keeps the ratings he had when he joined; stat points raise them later.
# Sprite sheets: assets/players2/ (v2, scripts/sheets.gd; a missing sheet = his slot's Quick Game sheet, then the
# Kenney sprite, so a crew without art still plays). A recruit playing for you wears <sheet>_crew (your blue and gold,
# owner Q11 a), see crew_sheet().
# Portraits: assets/portraits/<portrait>.png (missing = a silhouette in the crew's ui_color).

# your crew and van (owner Q2)
const CREW_NAME := "CORNFIELD KINGS"
const VAN_NAME := "THE BISCUIT"
const CREW_COLORS := ["BLUE", "GOLD"]   # your crew always wears blue and gold (palette names in tools/art/crews.json)
const START_CREW := ["ud_deuce", "ud_jojo", "ud_tank"]   # starter 0 is the one you control by default
const COSMETICS_PATH := "res://scripts/cosmetics.gd"     # P8-10: the picked jersey (crew_sheet(); loaded at run time)
static var _cosmetics: GDScript = null

# the fixed route (owner Q7); a city with "built": false would be skipped (map pin marked "coming soon")
const ROUTE := ["hometown", "chicago", "memphis", "new_orleans", "denver", "seattle", "los_angeles", "new_york"]

# average player rating per trip stage (owner Q3: about 40 in Hometown rising to about 70 in New York).
# QA (P6-30) may nudge these within that range to even out the ramp.
# P8-25: raised from 40/45/50/54/58/62/66/70 (the progression plan's starting point) because every starter now earns
# points after every win; trip.gd's BOSS_CAP (95) caps the New York boss (78 + 20). docs/qa/phase8-ramp.md.
const STAGE_AVG := {1: 40, 2: 46, 3: 52, 4: 58, 5: 63, 6: 68, 7: 73, 8: 78}

# tier bonuses on top of STAGE_AVG (owner Q3: good +12 in two specialties and a little better overall,
# boss +20 at everything, no special moves). "spec" is added on the player's specialty stats only.
const TIER := {
	"avg": {"all": 0, "spec": 0},
	"good": {"all": 4, "spec": 12},
	"boss": {"all": 20, "spec": 0},
}

# game lengths (owner Q8, kept in Phase 6 Q10): in EVERY city game 1 to 11, game 2 to 15, game 3 (the boss game) to 21
const CITY_TARGETS := [11, 15, 21]
# the New York tournament (owner Q8b): quarterfinal, semifinal and final all to 21; a loss replays that round
const TOURNAMENT_TARGET := 21

# Known ids, for the data check (trip.gd self_test). The looks are court_looks.gd's (P6-12 adds the city ones), the
# twists are twists.gd's (P6-01), the music is res://assets/music/<id>.ogg (P6-A3 adds the new tracks).
const LOOK_IDS := ["barn", "rooftop", "soul_gym", "bayou", "mountain", "rain_park", "beach", "cage"]
const MUSIC_IDS := ["hometown", "chicago", "memphis", "new_orleans", "denver", "seattle", "los_angeles", "newyork"]
const TWIST_IDS := ["none", "wind", "crowd", "humid", "thin_air", "wet", "sand", "cage"]

# Keys of a city:
#   name, state       shown on the map and at tip-off ("HOMETOWN - GAME 2 OF 3")
#   stage             1..8, picks STAGE_AVG
#   targets           points to win games 1, 2, 3
#   look              court_looks.gd look name; music: track name (res://assets/music/<music>.ogg)
#   fallback          {"look", "music"}: used by trip.gd while the city's own look or track doesn't exist yet
#   twist             gameplay twist id (twists.gd; the same for both teams)
#   built             false = a map pin only (the route skips it); every city is built in Phase 6
#   crew              name (top bar), style (ratings.gd STYLES: inside / outside / balanced), colors (palette names
#                     main + trim, for the art), ui_color (drawn fallbacks), good / boss / avg: PLAYERS ids
#   story             story_text.gd scene ids: arrive (first visit), won (after game 3)
#   tournament        true for New York: "rounds" lists each round's crew, its 3 players and the target
const CITIES := {
	"hometown": {
		"name": "HOMETOWN", "state": "Indiana", "stage": 1, "targets": CITY_TARGETS,
		"look": "barn",                 # the barn driveway hoop with a cornfield
		"music": "hometown", "twist": "none",   # the tutorial city: no twist
		"fallback": {"look": "blacktop", "music": "hometown"},
		"built": true,
		"crew": {
			"name": "COUNTY LINE",
			"style": "balanced", "colors": ["GREEN", "WHITE"], "ui_color": Color(0.20, 0.60, 0.30),
			"good": ["ht_g1", "ht_g2"], "boss": "ht_boss", "avg": ["ht_a1", "ht_a2"],
		},
		"story": {"arrive": "hometown_arrive", "won": "hometown_won"},
	},
	"chicago": {
		"name": "CHICAGO", "state": "Illinois", "stage": 2, "targets": CITY_TARGETS,
		"look": "rooftop",              # a lakefront rooftop with a skyline
		"music": "chicago", "twist": "wind",    # wind off the lake: long shots and lobs drift
		"fallback": {"look": "gym", "music": "chicago"},
		"built": true,
		"crew": {
			"name": "LAKESHORE GUSTS",
			"style": "outside", "colors": ["PURPLE", "WHITE"], "ui_color": Color(0.50, 0.28, 0.70),
			"good": ["chi_g1", "chi_g2"], "boss": "chi_boss", "avg": ["chi_a1", "chi_a2"],
		},
		"story": {"arrive": "chicago_arrive", "won": "chicago_won"},
	},
	"memphis": {
		"name": "MEMPHIS", "state": "Tennessee", "stage": 3, "targets": CITY_TARGETS,
		"look": "soul_gym",             # an old-school gym with a packed crowd
		"music": "memphis", "twist": "crowd",   # full house: 18 s shot clock, everyone a bit faster, loud
		"fallback": {"look": "gym", "music": "gym"},
		"built": true,
		"crew": {
			"name": "RIVERSIDE SOUL",   # inside game
			"style": "inside", "colors": ["ORANGE", "BLACK"], "ui_color": Color(0.95, 0.50, 0.12),
			"good": ["mem_g1", "mem_g2"], "boss": "mem_boss", "avg": ["mem_a1", "mem_a2"],
		},
		"story": {"arrive": "memphis_arrive", "won": "memphis_won"},
	},
	"new_orleans": {
		"name": "NEW ORLEANS", "state": "Louisiana", "stage": 4, "targets": CITY_TARGETS,
		"look": "bayou",                # bayou blacktop with cypress trees and string lights
		"music": "new_orleans", "twist": "humid",   # humid: stamina refills slower
		"fallback": {"look": "blacktop", "music": "blacktop"},
		"built": true,
		"crew": {
			"name": "BAYOU BRASS",      # fast break (no "fast" style table yet: balanced, with speed specialists)
			"style": "balanced", "colors": ["TEAL", "WHITE"], "ui_color": Color(0.10, 0.62, 0.62),
			"good": ["nol_g1", "nol_g2"], "boss": "nol_boss", "avg": ["nol_a1", "nol_a2"],
		},
		"story": {"arrive": "new_orleans_arrive", "won": "new_orleans_won"},
	},
	"denver": {
		"name": "DENVER", "state": "Colorado", "stage": 5, "targets": CITY_TARGETS,
		"look": "mountain",             # a mountain park court with peaks
		"music": "denver", "twist": "thin_air",   # thin air: long shots carry, the ball floats, stamina drains faster
		"fallback": {"look": "blacktop", "music": "hometown"},
		"built": true,
		"crew": {
			"name": "SWITCHBACKS",      # long range
			"style": "outside", "colors": ["FOREST", "SILVER"], "ui_color": Color(0.14, 0.40, 0.26),
			"good": ["den_g1", "den_g2"], "boss": "den_boss", "avg": ["den_a1", "den_a2"],
		},
		"story": {"arrive": "denver_arrive", "won": "denver_won"},
	},
	"seattle": {
		"name": "SEATTLE", "state": "Washington", "stage": 6, "targets": CITY_TARGETS,
		"look": "rain_park",            # a rainy park, wet sheen and puddles
		"music": "seattle", "twist": "wet",     # wet court: a sharp cut at full speed slides
		"fallback": {"look": "blacktop", "music": "blacktop"},
		"built": true,
		"crew": {
			"name": "PUDDLE JUMPERS",   # balanced
			"style": "balanced", "colors": ["NAVY", "LIME"], "ui_color": Color(0.56, 0.80, 0.16),
			"good": ["sea_g1", "sea_g2"], "boss": "sea_boss", "avg": ["sea_a1", "sea_a2"],
		},
		"story": {"arrive": "seattle_arrive", "won": "seattle_won"},
	},
	"los_angeles": {
		"name": "LOS ANGELES", "state": "California", "stage": 7, "targets": CITY_TARGETS,
		"look": "beach",                # a beach court on the sand, a boardwalk behind
		"music": "los_angeles", "twist": "sand",   # sand: everyone slower, turbo matters more
		"fallback": {"look": "blacktop", "music": "chicago"},
		"built": true,
		"crew": {
			"name": "BOARDWALK BOMBERS",   # slashers
			"style": "inside", "colors": ["SKY", "SAND"], "ui_color": Color(0.42, 0.74, 0.95),
			"good": ["la_g1", "la_g2"], "boss": "la_boss", "avg": ["la_a1", "la_a2"],
		},
		"story": {"arrive": "los_angeles_arrive", "won": "los_angeles_won"},
	},
	# the finale: a knockout bracket, the final against the champions and their boss
	"new_york": {
		"name": "NEW YORK", "state": "New York", "stage": 8, "targets": [TOURNAMENT_TARGET],
		"look": "cage",                 # a fenced cage court between city blocks
		"music": "newyork", "twist": "cage",    # owner Q2 a: a loose ball bounces off the sideline fence
		"fallback": {"look": "blacktop", "music": "newyork"},
		"built": true, "tournament": true,
		"tournament_name": "BIG CITY SHOWDOWN",
		"rounds": [
			{"round": "QUARTERFINAL", "target": TOURNAMENT_TARGET,
				"crew": {"name": "BRIDGE RUNNERS",
					"style": "inside", "colors": ["RED", "BLACK"], "ui_color": Color(0.85, 0.16, 0.23)},
				"players": ["ny_q1", "ny_q2", "ny_q3"]},
			{"round": "SEMIFINAL", "target": TOURNAMENT_TARGET,
				"crew": {"name": "BODEGA BANDITS",   # renamed from "Subway Sparks" (a real pro team name), owner Q3
					"style": "outside", "colors": ["GREYW", "PLUM"], "ui_color": Color(0.55, 0.30, 0.50)},
				"players": ["ny_s1", "ny_s2", "ny_s3"]},
			{"round": "FINAL", "target": TOURNAMENT_TARGET,
				"crew": {"name": "CONCRETE CROWNS",
					"style": "balanced", "colors": ["BLACK", "GOLD"], "ui_color": Color(0.20, 0.20, 0.25)},
				"players": ["ny_f1", "ny_f2", "ny_boss"]},
		],
		"story": {"arrive": "final_before", "won": "ending"},
	},
}

# Keys of a player:
#   name              short name shown in game (top bar, lineup); full: full name for story and cards
#   sheet, portrait   file ids (assets/players2/ through sheets.gd, assets/portraits/<portrait>.png)
#   number, role      jersey digit and role text for the lineup cards
#   tier              "start" (your underdogs, fixed ratings below), "avg", "good" or "boss"
#   ratings           only for "start"; city players are computed from STAGE_AVG + TIER (see the top)
#   spec              the stats that get TIER[tier].spec (good players: two)
#   steal_bias, block_bias   steal / block = defense + bias
#   recruitable       true = offered on the recruit screen after his city (the 2 good players and the boss)
#   look              what the art agent draws: body (crews.json bodies), skin (crews.json skins), hair, outfit in
#                     the crew's colors (<sheet>_crew.png in blue and gold for recruitable players)
#   bio               one line for cards and story
const PLAYERS := {
	# --- the Cornfield Kings (owner Q1, approved) ---
	"ud_deuce": {"name": "DEUCE", "full": "Deuce Carter", "sheet": "ud_deuce", "portrait": "ud_deuce",
		"number": 2, "role": "shooting wing", "tier": "start", "leader": true,
		"ratings": {"speed": 52, "shooting": 62, "finishing": 48, "defense": 48, "stamina": 50},
		"steal_bias": 4, "block_bias": -4, "spec": ["shooting"],
		"look": "long and lean, deep brown skin, white headband over short hair, blue tank with gold trim, navy arm sleeve, knee-length shorts",
		"bio": "Hometown's old high-school star. A knee injury cost him his college offer; this trip is his second shot."},
	"ud_jojo": {"name": "JOJO", "full": "Jojo Reyes", "sheet": "ud_jojo", "portrait": "ud_jojo",
		"number": 5, "role": "point guard", "tier": "start",
		"ratings": {"speed": 62, "shooting": 50, "finishing": 46, "defense": 50, "stamina": 54},
		"steal_bias": 12, "block_bias": -15, "spec": ["speed"],
		"look": "slim, tan skin, backwards gold cap, long blue tee, long shorts, leg sleeve",
		"bio": "Loud, funny, never stops talking. Found the tournament flyer at his uncle's gas station."},
	"ud_tank": {"name": "TANK", "full": "Tobias \"Tank\" Lind", "sheet": "ud_tank", "portrait": "ud_tank",
		"number": 9, "role": "big man", "tier": "start",
		"ratings": {"speed": 42, "shooting": 38, "finishing": 62, "defense": 58, "stamina": 48},
		"steal_bias": -10, "block_bias": 12, "spec": ["finishing", "defense"],
		"look": "wide and heavy, light skin, red-brown buzz cut and short beard, sleeveless navy hoodie, gold shorts",
		"bio": "Quiet farm kid who learned on the barn driveway hoop and fixed up the van in his family's barn."},

	# --- Hometown: County Line (green and white), balanced ---
	"ht_g1": {"name": "SKIP", "full": "Skip Morrow",
		"sheet": "ht_g1", "portrait": "ht_g1", "number": 3, "role": "shooter", "tier": "good",
		"spec": ["shooting", "speed"], "steal_bias": 4, "block_bias": -8, "recruitable": true,
		"look": "lanky, tan skin, short twists, green tank with white trim, long shorts",
		"bio": "Feed-store clerk with a quick release."},
	"ht_g2": {"name": "BUCK", "full": "Buck Halvorsen",
		"sheet": "ht_g2", "portrait": "ht_g2", "number": 6, "role": "post scorer", "tier": "good",
		"spec": ["finishing", "defense"], "steal_bias": -6, "block_bias": 10, "recruitable": true,
		"look": "power forward, light skin, blond buzz cut, white tee with green trim, knee-length shorts",
		"bio": "Throws hay bales all summer and bodies everyone in the paint."},
	"ht_boss": {"name": "MAYOR", "full": "Earl \"Mayor\" Pruitt",
		"sheet": "ht_boss", "portrait": "ht_boss", "number": 1, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 6, "block_bias": 6, "recruitable": true,
		"look": "stocky big, deep brown skin, bald, grey goatee, green sleeveless hoodie, white shorts",
		"bio": "Ran the county rec league for twenty years and still never loses on his own court."},
	"ht_a1": {"name": "DALE", "full": "Dale Whitcomb",
		"sheet": "ht_a1", "portrait": "ht_a1", "number": 4, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 6, "block_bias": -6,
		"look": "stocky guard, light skin, backwards green cap, white tee, short shorts",
		"bio": "Weekend hooper, weekday mechanic."},
	"ht_a2": {"name": "RUSTY", "full": "Rusty Kowal",
		"sheet": "ht_a2", "portrait": "ht_a2", "number": 8, "role": "forward", "tier": "avg",
		"spec": [], "steal_bias": -4, "block_bias": 4,
		"look": "wiry center, light skin, auburn hair with headband, green tank, long shorts",
		"bio": "Tall, willing, a little slow."},

	# --- Chicago: Lakeshore Gusts (purple and white), outside shooting ---
	"chi_g1": {"name": "NICO", "full": "Nico Vance",
		"sheet": "chi_g1", "portrait": "chi_g1", "number": 7, "role": "deep shooter", "tier": "good",
		"spec": ["shooting", "stamina"], "steal_bias": 2, "block_bias": -8, "recruitable": true,
		"look": "lanky wing, umber skin, high-top hair, purple tank with white trim, arm sleeve",
		"bio": "Practices long shots into the lake wind until they stop drifting."},
	"chi_g2": {"name": "RIO", "full": "Rio Delgado",
		"sheet": "chi_g2", "portrait": "chi_g2", "number": 0, "role": "slasher", "tier": "good",
		"spec": ["speed", "finishing"], "steal_bias": 8, "block_bias": -4, "recruitable": true,
		"look": "lanky guard, brown skin, short twists, white long tee with purple trim, leg sleeve",
		"bio": "Bike messenger who cuts through a defense like downtown traffic."},
	"chi_boss": {"name": "BIG LOU", "full": "Louis \"Big Lou\" Okafor",
		"sheet": "chi_boss", "portrait": "chi_boss", "number": 5, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 0, "block_bias": 12, "recruitable": true,
		"look": "power forward, deep brown skin, bald, full beard, purple sleeveless hoodie, white shorts",
		"bio": "King of the rooftop courts; nobody scores on him twice."},
	"chi_a1": {"name": "MARCO", "full": "Marco Bellini",
		"sheet": "chi_a1", "portrait": "chi_a1", "number": 2, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 6, "block_bias": -6,
		"look": "stocky guard, tan skin, backwards purple cap, white tee, short shorts",
		"bio": "Runs the pizza counter and the pick-and-roll."},
	"chi_a2": {"name": "TERRELL", "full": "Terrell Banks",
		"sheet": "chi_a2", "portrait": "chi_a2", "number": 9, "role": "center", "tier": "avg",
		"spec": [], "steal_bias": -6, "block_bias": 8,
		"look": "wiry center, deep brown skin, buzz cut, purple tee, knee-length shorts",
		"bio": "Long arms, short temper."},

	# --- Memphis: Riverside Soul (orange and black), inside game ---
	"mem_g1": {"name": "HONEY", "full": "Calvin \"Honey\" Brooks",
		"sheet": "mem_g1", "portrait": "mem_g1", "number": 33, "role": "post scorer", "tier": "good",
		"spec": ["finishing", "defense"], "steal_bias": -6, "block_bias": 12, "recruitable": true,
		"look": "power forward, deep brown skin, short waves, orange tank with black trim, black knee-length shorts",
		"bio": "Sings in the church choir on Sunday and owns the paint the rest of the week."},
	"mem_g2": {"name": "LAMONT", "full": "Lamont Price",
		"sheet": "mem_g2", "portrait": "mem_g2", "number": 4, "role": "slasher", "tier": "good",
		"spec": ["speed", "finishing"], "steal_bias": 8, "block_bias": -6, "recruitable": true,
		"look": "lanky guard, brown skin, cornrows, black tee with orange trim, orange shorts, wristbands",
		"bio": "Delivers records across town on a bike with one working brake."},
	"mem_boss": {"name": "SMOKE", "full": "Darnell \"Smoke\" Whitfield",
		"sheet": "mem_boss", "portrait": "mem_boss", "number": 1, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 4, "block_bias": 10, "recruitable": true,
		"look": "boss big, umber skin, bald, thick grey-flecked beard, black sleeveless hoodie with orange trim, orange shorts, a towel over one shoulder",
		"bio": "Runs the best barbecue pit on the river. You can smell his hook shot coming."},
	"mem_a1": {"name": "BOOKER", "full": "Booker Lane",
		"sheet": "mem_a1", "portrait": "mem_a1", "number": 10, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 8, "block_bias": -8,
		"look": "stocky guard, tan skin, flat-top hair, orange tee, black short shorts",
		"bio": "Sweeps the gym floor every morning and talks trash all afternoon."},
	"mem_a2": {"name": "WENDELL", "full": "Wendell Rowe",
		"sheet": "mem_a2", "portrait": "mem_a2", "number": 50, "role": "center", "tier": "avg",
		"spec": [], "steal_bias": -6, "block_bias": 8,
		"look": "wiry center, deep brown skin, short afro, black tank with orange trim, long shorts, knee pads",
		"bio": "Seven feet of elbows, by his own measurement."},

	# --- New Orleans: Bayou Brass (teal and white), fast break ---
	"nol_g1": {"name": "LUCIEN", "full": "Lucien Batiste",
		"sheet": "nol_g1", "portrait": "nol_g1", "number": 3, "role": "fast-break guard", "tier": "good",
		"spec": ["speed", "stamina"], "steal_bias": 10, "block_bias": -8, "recruitable": true,
		"look": "slim guard, brown skin, short locs tied back, teal tank with white trim, white shorts, headband",
		"bio": "Plays trumpet in the street parades and runs the floor like he's late for one."},
	"nol_g2": {"name": "BEAU", "full": "Beau Thibodeaux",
		"sheet": "nol_g2", "portrait": "nol_g2", "number": 12, "role": "slasher", "tier": "good",
		"spec": ["speed", "finishing"], "steal_bias": 6, "block_bias": -2, "recruitable": true,
		"look": "lanky wing, light skin, shaggy brown hair, white tee with teal trim, teal shorts, leg sleeve",
		"bio": "Shrimp-boat deckhand who has never once slowed down for a corner."},
	"nol_boss": {"name": "GATOR", "full": "Andre \"Gator\" Fontenot",
		"sheet": "nol_boss", "portrait": "nol_boss", "number": 7, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 10, "block_bias": 4, "recruitable": true,
		"look": "boss big, deep brown skin, shaved sides with a short top, gold-rimmed grin, teal sleeveless hoodie with white trim, white shorts",
		"bio": "Trombone player by night, bayou-court legend by day. Smiles a lot. Too many teeth."},
	"nol_a1": {"name": "PIERRE", "full": "Pierre Landry",
		"sheet": "nol_a1", "portrait": "nol_a1", "number": 5, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 6, "block_bias": -6,
		"look": "stocky guard, tan skin, curly black hair, white tee with teal trim, short shorts",
		"bio": "Sells pralines courtside at halftime, and also during the game."},
	"nol_a2": {"name": "MOOSE", "full": "Jules \"Moose\" Arceneaux",
		"sheet": "nol_a2", "portrait": "nol_a2", "number": 44, "role": "center", "tier": "avg",
		"spec": [], "steal_bias": -6, "block_bias": 8,
		"look": "heavy big, light skin, red beard, teal tank, white knee-length shorts",
		"bio": "Plays bass drum in the band. Slow feet, big hands, bigger laugh."},

	# --- Denver: Switchbacks (forest green and silver), long range ---
	"den_g1": {"name": "WES", "full": "Wes Calloway",
		"sheet": "den_g1", "portrait": "den_g1", "number": 30, "role": "deep shooter", "tier": "good",
		"spec": ["shooting", "stamina"], "steal_bias": 2, "block_bias": -8, "recruitable": true,
		"look": "lanky wing, light skin, sandy hair under a knit beanie, forest green tank with silver trim, long shorts",
		"bio": "Trail runner who shoots from so far out he can see the next state."},
	"den_g2": {"name": "THEO", "full": "Theo Abernathy",
		"sheet": "den_g2", "portrait": "den_g2", "number": 11, "role": "shooter", "tier": "good",
		"spec": ["shooting", "speed"], "steal_bias": 6, "block_bias": -6, "recruitable": true,
		"look": "slim guard, umber skin, short twists, silver tee with green trim, green shorts, climbing chalk on his hands",
		"bio": "Rock-climbing instructor whose arms never seem to get tired."},
	"den_boss": {"name": "RIDGE", "full": "Hank \"Ridge\" Larsen",
		"sheet": "den_boss", "portrait": "den_boss", "number": 8, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 2, "block_bias": 10, "recruitable": true,
		"look": "power forward, light skin, blond hair and a big blond beard, forest green sleeveless hoodie with a silver cross patch, silver shorts",
		"bio": "Ski patrol all winter, court patrol all summer. Has never once been out of breath."},
	"den_a1": {"name": "GUS", "full": "Gus Pellegrino",
		"sheet": "den_a1", "portrait": "den_a1", "number": 2, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 8, "block_bias": -8,
		"look": "stocky guard, tan skin, backwards green cap, silver tee, short shorts",
		"bio": "Runs the food truck by the trailhead. His jumper is a little half-baked."},
	"den_a2": {"name": "CODY", "full": "Cody Stroud",
		"sheet": "den_a2", "portrait": "den_a2", "number": 21, "role": "forward", "tier": "avg",
		"spec": [], "steal_bias": -4, "block_bias": 6,
		"look": "wiry center, light skin, messy brown hair, green tank, silver long shorts, goggle tan",
		"bio": "Snowboarder. Falls down a lot, gets back up a lot."},

	# --- Seattle: Puddle Jumpers (navy and lime), balanced ---
	"sea_g1": {"name": "DEX", "full": "Dex Okoye",
		"sheet": "sea_g1", "portrait": "sea_g1", "number": 1, "role": "point guard", "tier": "good",
		"spec": ["speed", "defense"], "steal_bias": 12, "block_bias": -8, "recruitable": true,
		"look": "slim guard, deep brown skin, short fade, navy tank with lime trim, lime shorts",
		"bio": "Barista. Four espressos before tip-off, every single game."},
	"sea_g2": {"name": "IGGY", "full": "Iggy Larkin",
		"sheet": "sea_g2", "portrait": "sea_g2", "number": 13, "role": "stretch forward", "tier": "good",
		"spec": ["shooting", "finishing"], "steal_bias": 0, "block_bias": 4, "recruitable": true,
		"look": "lanky wing, light skin, long dark hair in a bun, flannel-check sleeveless shirt in navy, lime shorts",
		"bio": "Plays bass in three garage bands at once and never misses a practice."},
	"sea_boss": {"name": "DOWNPOUR", "full": "Kenji \"Downpour\" Sato",
		"sheet": "sea_boss", "portrait": "sea_boss", "number": 9, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 8, "block_bias": 6, "recruitable": true,
		"look": "power forward, tan skin, short black hair with a headband, navy sleeveless hoodie with lime trim, navy shorts, a yellow rain jacket tied at the waist",
		"bio": "Works the fishing boats in any weather. Rain doesn't slow him down; it slows YOU down."},
	"sea_a1": {"name": "MILO", "full": "Milo Fairbanks",
		"sheet": "sea_a1", "portrait": "sea_a1", "number": 6, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 6, "block_bias": -6,
		"look": "stocky guard, light skin, curly red hair, lime tee, navy short shorts",
		"bio": "Always carries an umbrella. Has never once opened it."},
	"sea_a2": {"name": "RAY", "full": "Ray Lindqvist",
		"sheet": "sea_a2", "portrait": "sea_a2", "number": 40, "role": "center", "tier": "avg",
		"spec": [], "steal_bias": -6, "block_bias": 8,
		"look": "wiry center, light skin, blond buzz cut, navy tee, lime knee-length shorts",
		"bio": "Ferry mechanic. Tall, damp and completely unbothered."},

	# --- Los Angeles: Boardwalk Bombers (sky blue and sand), slashers ---
	"la_g1": {"name": "TREY", "full": "Trey Castillo",
		"sheet": "la_g1", "portrait": "la_g1", "number": 23, "role": "slasher", "tier": "good",
		"spec": ["speed", "finishing"], "steal_bias": 8, "block_bias": -4, "recruitable": true,
		"look": "lanky guard, brown skin, short curls, sky blue tank with sand trim, sand shorts",
		"bio": "Skateboards to every game and attacks the rim like it's a half-pipe."},
	"la_g2": {"name": "KAI", "full": "Kai Mendoza",
		"sheet": "la_g2", "portrait": "la_g2", "number": 15, "role": "wing", "tier": "good",
		"spec": ["finishing", "defense"], "steal_bias": 4, "block_bias": 6, "recruitable": true,
		"look": "power forward, tan skin, sun-bleached shaggy hair, sand tee with sky blue trim, sky blue board shorts",
		"bio": "Surf instructor who rides every bump all the way to the rim."},
	"la_boss": {"name": "SUNSET", "full": "Malik \"Sunset\" Rivers",
		"sheet": "la_boss", "portrait": "la_boss", "number": 0, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 8, "block_bias": 8, "recruitable": true,
		"look": "champion build, deep brown skin, short locs, sky blue sleeveless hoodie with sand trim, red-orange lifeguard shorts, whistle on a cord",
		"bio": "Head lifeguard of the beach courts. Sprints in the sand like it's a gym floor."},
	"la_a1": {"name": "BRODY", "full": "Brody Fitch",
		"sheet": "la_a1", "portrait": "la_a1", "number": 3, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 6, "block_bias": -6,
		"look": "slim guard, light skin, swoopy blond hair, sky blue tee, sand short shorts",
		"bio": "Aspiring actor. Fakes everything, including injuries."},
	"la_a2": {"name": "DUKE", "full": "Duke Ashby",
		"sheet": "la_a2", "portrait": "la_a2", "number": 34, "role": "forward", "tier": "avg",
		"spec": [], "steal_bias": -4, "block_bias": 6,
		"look": "heavy big, umber skin, buzz cut, sand tank, sky blue long shorts, three pairs of sunglasses",
		"bio": "Sells sunglasses on the boardwalk. Wears four pairs at once, just in case."},

	# --- New York: the Big City Showdown (tournament crews; not recruitable) ---
	# quarterfinal: Bridge Runners (red and black), inside
	"ny_q1": {"name": "ACE", "full": "Ace Moreno",
		"sheet": "ny_q1", "portrait": "ny_q1", "number": 5, "role": "big", "tier": "good",
		"spec": ["finishing", "defense"], "steal_bias": -6, "block_bias": 10,
		"look": "power forward, tan skin, slicked-back black hair, red tank with black trim, black shorts, taped fingers",
		"bio": "Iron worker on the bridges. Treats the paint like a construction site."},
	"ny_q2": {"name": "DASH", "full": "Dash Whitaker",
		"sheet": "ny_q2", "portrait": "ny_q2", "number": 9, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 8, "block_bias": -8,
		"look": "slim guard, deep brown skin, short fade with a part, black tee with red trim, red shorts",
		"bio": "Bike courier who knows every shortcut, on the street and on the court."},
	"ny_q3": {"name": "KNOX", "full": "Knox Albright",
		"sheet": "ny_q3", "portrait": "ny_q3", "number": 8, "role": "center", "tier": "avg",
		"spec": [], "steal_bias": -4, "block_bias": 6,
		"look": "wiry center, light skin, red buzz cut, red tank, black knee-length shorts, knee brace",
		"bio": "Toll-booth operator. Nothing gets past him without paying."},
	# semifinal: Bodega Bandits (grey and plum), outside
	"ny_s1": {"name": "JAX", "full": "Jax Carrow",
		"sheet": "ny_s1", "portrait": "ny_s1", "number": 3, "role": "shooter", "tier": "good",
		"spec": ["shooting", "speed"], "steal_bias": 6, "block_bias": -8,
		"look": "lanky guard, umber skin, high-top hair, grey tank with plum trim, plum shorts",
		"bio": "Works the corner-store counter and hits from the corner just as fast."},
	"ny_s2": {"name": "OMAR", "full": "Omar Latimer",
		"sheet": "ny_s2", "portrait": "ny_s2", "number": 11, "role": "wing", "tier": "good",
		"spec": ["shooting", "stamina"], "steal_bias": 2, "block_bias": 0,
		"look": "lanky wing, brown skin, neat beard, plum tee with grey trim, grey long shorts, arm sleeve",
		"bio": "Night-shift baker. Shoots soft and smells like fresh bread."},
	"ny_s3": {"name": "BRUNO", "full": "Bruno Vasko",
		"sheet": "ny_s3", "portrait": "ny_s3", "number": 4, "role": "big", "tier": "avg",
		"spec": [], "steal_bias": -6, "block_bias": 8,
		"look": "heavy big, light skin, dark crew cut, grey sleeveless hoodie, plum shorts",
		"bio": "Stacks crates at the bodega. Sets screens like he's stacking crates."},
	# final: Concrete Crowns (black and gold), the champions
	"ny_f1": {"name": "SLIM", "full": "Slim Ortega",
		"sheet": "ny_f1", "portrait": "ny_f1", "number": 1, "role": "slasher", "tier": "good",
		"spec": ["speed", "finishing"], "steal_bias": 8, "block_bias": -6,
		"look": "lanky guard, tan skin, braids, black tank with gold trim, black shorts, gold wristbands",
		"bio": "The quickest first step in five boroughs, and he'll tell you so."},
	"ny_f2": {"name": "HAMMER", "full": "Vic \"Hammer\" Doyle",
		"sheet": "ny_f2", "portrait": "ny_f2", "number": 6, "role": "big", "tier": "good",
		"spec": ["finishing", "defense"], "steal_bias": -8, "block_bias": 12,
		"look": "heavy big, light skin, shaved head, black sleeveless hoodie with gold trim, black long shorts",
		"bio": "Subway track worker. Hits like the express train."},
	"ny_boss": {"name": "KING", "full": "Marcus \"King\" Sterling",
		"sheet": "ny_boss", "portrait": "ny_boss", "number": 0, "role": "champion boss", "tier": "boss",
		"spec": [], "steal_bias": 6, "block_bias": 6,
		"look": "muscular wing, umber skin, high-top hair, black tank with gold trim, gold arm sleeve, long black shorts",
		"bio": "The reigning champion of the city's cage courts."},
}

# --- tiny getters ---

# a city's data ({} for an unknown id)
static func city(id: String) -> Dictionary:
	return CITIES.get(id, {})

# a player's data ({} for an unknown id)
static func player(id: String) -> Dictionary:
	return PLAYERS.get(id, {})

static func is_built(id: String) -> bool:
	return bool(city(id).get("built", false))

# the route without the "coming soon" cities
static func built_route() -> Array:
	var out: Array = []
	for id in ROUTE:
		if is_built(id):
			out.append(id)
	return out

# a city's twist id ("none" for an unknown city or a missing key)
static func twist(id: String) -> String:
	return str(city(id).get("twist", "none"))

# the average player rating of a stage (clamped to the table)
static func stage_avg(stage: int) -> int:
	return int(STAGE_AVG.get(clampi(stage, 1, 8), 50))

# points to win game n (1-based) in a city; the tournament uses TOURNAMENT_TARGET for every round
static func game_target(city_id: String, n: int) -> int:
	var c: Dictionary = city(city_id)
	if c.get("tournament", false):
		return TOURNAMENT_TARGET
	var t: Array = c.get("targets", CITY_TARGETS)
	return int(t[clampi(n - 1, 0, t.size() - 1)])

# the sheet id a player wears: <sheet>_crew in your colors when a recruit plays for you (Q11 a)
# his sheet; for_your_crew: anyone but your 3 starting underdogs (a recruit or a drafted player, P8-05) wears
# <sheet>_crew, your blue and gold (Sheets falls back to the plain sheet if that recolor is missing)
# P8-10: your crew also wears the picked jersey (a star reward, Cosmetics.jersey_suffix(): "" = none, else "_j<N>"):
# <sheet>_j<N> on an underdog, <sheet>_crew_j<N> on anyone else (Sheets falls back to the plain look when that
# palette is missing). The underdogs (tier "start") always wear it, so in Quick Game the Kings wear it on either side
# (progression plan part 5: "your crew on the trip, the Kings in Quick Game"); no other crew ever does.
static func crew_sheet(id: String, for_your_crew: bool) -> String:
	var p: Dictionary = player(id)
	var s: String = p.get("sheet", id)
	var underdog: bool = str(p.get("tier", "")) == "start" and not p.is_empty()
	if for_your_crew and not underdog and not p.is_empty():
		return s + "_crew" + jersey_suffix()
	if underdog:
		return s + jersey_suffix()
	return s

# the picked jersey's suffix ("" = none). cosmetics.gd is loaded at run time (it preloads difficulty.gd, which
# preloads this file); a missing cosmetics.gd = no jersey.
static func jersey_suffix() -> String:
	if _cosmetics == null:
		_cosmetics = load(COSMETICS_PATH) as GDScript if ResourceLoader.exists(COSMETICS_PATH) else null
		if _cosmetics == null:
			return ""
	return str(_cosmetics.call("jersey_suffix")) if _cosmetics.has_method("jersey_suffix") else ""

# the 3 recruit candidates of a city (its 2 good players and the boss)
static func recruits(city_id: String) -> Array:
	var crew: Dictionary = city(city_id).get("crew", {})
	var out: Array = []
	for id in crew.get("good", []):
		out.append(id)
	if crew.has("boss"):
		out.append(crew["boss"])
	return out

# every player id of a city: its crew (good, avg, boss) or the tournament rounds' players
static func city_players(city_id: String) -> Array:
	var c: Dictionary = city(city_id)
	var crew: Dictionary = c.get("crew", {})
	var out: Array = []
	out.append_array(crew.get("good", []))
	out.append_array(crew.get("avg", []))
	if crew.has("boss"):
		out.append(crew["boss"])
	for r in c.get("rounds", []):
		out.append_array((r as Dictionary).get("players", []))
	return out

# every PLAYERS id named in START_CREW and CITIES that is missing; [] = the data is consistent
static func missing_ids() -> Array:
	var named: Array = START_CREW.duplicate()
	for cid in CITIES:
		named.append_array(city_players(cid))
	var out: Array = []
	for id in named:
		if not PLAYERS.has(id):
			out.append(id)
	for cid in ROUTE:
		if not CITIES.has(cid):
			out.append("city:" + cid)
	return out
