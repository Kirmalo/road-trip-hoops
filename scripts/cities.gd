extends RefCounted
# City and crew data for the Road Trip (Phase 5, P5-04): plain const data plus a few tiny getters.
# Use it through   const Cities = preload("res://scripts/cities.gd")   (static functions only, never instanced).
# Safe to edit on the tablet: a typo shows as a parse error in the Godot editor right away.
#
# How the numbers are used (trip.gd, P5-05):
#   a city player's rating on every stat = STAGE_AVG[city stage] + TIER[tier].all, plus TIER[tier].spec on each stat
#   listed in his "spec". Stats: speed, shooting, finishing, defense, stamina (0-100, 50 = today's Quick Game player).
#   steal = clampi(defense + steal_bias, 0, 100), block = clampi(defense + block_bias, 0, 100).
#   City games (owner): game 1 = 1 good + 2 average, game 2 = 2 good + 1 average, game 3 = 2 good + the boss.
#   A recruit keeps the ratings he had when he joined; stat points raise them later.
# Sprite sheets: assets/players/<sheet>.png (missing file = today's blue_n / red_n). A recruit playing for you uses
# <sheet>_crew.png (your blue and gold, owner Q11 a), see crew_sheet(). Portraits: assets/portraits/<portrait>.png.

# your crew and van (owner Q2)
const CREW_NAME := "CORNFIELD KINGS"
const VAN_NAME := "THE BISCUIT"
const CREW_COLORS := ["BLUE", "GOLD"]   # your crew always wears blue and gold (palette names in tools/art/crews.json)
const START_CREW := ["ud_deuce", "ud_jojo", "ud_tank"]   # starter 0 is the one you control by default

# the fixed route (owner Q7); cities with "built": false are skipped in Phase 5 (map pins marked "coming soon")
const ROUTE := ["hometown", "chicago", "memphis", "new_orleans", "denver", "seattle", "los_angeles", "new_york"]

# average player rating per trip stage (owner Q3: about 40 in Hometown rising to about 70 in New York)
const STAGE_AVG := {1: 40, 2: 45, 3: 50, 4: 54, 5: 58, 6: 62, 7: 66, 8: 70}

# tier bonuses on top of STAGE_AVG (owner Q3: good +12 in two specialties and a little better overall,
# boss +20 at everything, no special moves). "spec" is added on the player's specialty stats only.
const TIER := {
	"avg": {"all": 0, "spec": 0},
	"good": {"all": 4, "spec": 12},
	"boss": {"all": 20, "spec": 0},
}

# game lengths (owner Q8): in EVERY city game 1 to 11, game 2 to 15, game 3 (the boss game) to 21
const CITY_TARGETS := [11, 15, 21]
# the New York tournament (owner Q8b): quarterfinal, semifinal and final all to 21; a loss replays that round
const TOURNAMENT_TARGET := 21

# Keys of a city:
#   name, state       shown on the map and at tip-off ("HOMETOWN - GAME 2 OF 3")
#   stage             1..8, picks STAGE_AVG
#   targets           points to win games 1, 2, 3
#   look              court_looks.gd look name; music: track name (res://assets/music/<music>.ogg)
#   twist             gameplay twist id (Phase 6 builds them; "none" for now)
#   built             false = a map pin only in Phase 5 (the route skips it)
#   crew              name (top bar), style (ratings.gd STYLES: inside / outside / balanced), colors (palette names
#                     main + trim, for the art), ui_color (drawn fallbacks), good / boss / avg: PLAYERS ids
#   story             story_text.gd scene ids: arrive (first visit), won (after game 3)
#   tournament        true for New York: "rounds" lists each round's crew, its 3 players and the target
const CITIES := {
	"hometown": {
		"name": "HOMETOWN", "state": "Indiana", "stage": 1, "targets": CITY_TARGETS,
		"look": "blacktop",   # placeholder court (Phase 6: barn driveway hoop)
		"music": "hometown", "twist": "none", "built": true,
		"crew": {
			"name": "COUNTY LINE",   # placeholder (Phase 6)
			"style": "balanced", "colors": ["GREEN", "WHITE"], "ui_color": Color(0.20, 0.60, 0.30),
			"good": ["ht_g1", "ht_g2"], "boss": "ht_boss", "avg": ["ht_a1", "ht_a2"],
		},
		"story": {"arrive": "hometown_arrive", "won": "hometown_won"},
	},
	"chicago": {
		"name": "CHICAGO", "state": "Illinois", "stage": 2, "targets": CITY_TARGETS,
		"look": "gym",   # placeholder court (Phase 6: lakefront rooftop)
		"music": "chicago", "twist": "none",   # Phase 6: "wind" (pushes long shots and lobs)
		"built": true,
		"crew": {
			"name": "LAKESHORE GUSTS",   # placeholder (Phase 6)
			"style": "outside", "colors": ["PURPLE", "WHITE"], "ui_color": Color(0.50, 0.28, 0.70),
			"good": ["chi_g1", "chi_g2"], "boss": "chi_boss", "avg": ["chi_a1", "chi_a2"],
		},
		"story": {"arrive": "chicago_arrive", "won": "chicago_won"},
	},
	# pins only in Phase 5; Phase 6 adds look, music, crew and story (twists from docs/VISION.md)
	"memphis": {"name": "MEMPHIS", "state": "Tennessee", "stage": 3, "targets": CITY_TARGETS,
		"look": "", "music": "", "twist": "crowd", "built": false},
	"new_orleans": {"name": "NEW ORLEANS", "state": "Louisiana", "stage": 4, "targets": CITY_TARGETS,
		"look": "", "music": "", "twist": "humid", "built": false},
	"denver": {"name": "DENVER", "state": "Colorado", "stage": 5, "targets": CITY_TARGETS,
		"look": "", "music": "", "twist": "thin_air", "built": false},
	"seattle": {"name": "SEATTLE", "state": "Washington", "stage": 6, "targets": CITY_TARGETS,
		"look": "", "music": "", "twist": "wet", "built": false},
	"los_angeles": {"name": "LOS ANGELES", "state": "California", "stage": 7, "targets": CITY_TARGETS,
		"look": "", "music": "", "twist": "sand", "built": false},
	# the finale: a knockout bracket, the final against the champions and their boss (stub in Phase 5)
	"new_york": {
		"name": "NEW YORK", "state": "New York", "stage": 8, "targets": [TOURNAMENT_TARGET],
		"look": "blacktop",   # placeholder court (Phase 6: fenced cage court)
		"music": "newyork", "twist": "none",   # Phase 6: "cage" (tight sidelines)
		"built": true, "tournament": true,
		"tournament_name": "BIG CITY SHOWDOWN",   # placeholder (Phase 6)
		"rounds": [
			{"round": "QUARTERFINAL", "target": TOURNAMENT_TARGET,
				"crew": {"name": "BRIDGE RUNNERS",   # placeholder (Phase 6)
					"style": "inside", "colors": ["RED", "BLACK"], "ui_color": Color(0.85, 0.16, 0.23)},
				"players": ["ny_q1", "ny_q2", "ny_q3"]},
			{"round": "SEMIFINAL", "target": TOURNAMENT_TARGET,
				"crew": {"name": "SUBWAY SPARKS",   # placeholder (Phase 6)
					"style": "outside", "colors": ["RED", "BLACK"], "ui_color": Color(0.85, 0.16, 0.23)},
				"players": ["ny_s1", "ny_s2", "ny_s3"]},
			{"round": "FINAL", "target": TOURNAMENT_TARGET,
				"crew": {"name": "CONCRETE CROWNS",   # placeholder (Phase 6)
					"style": "balanced", "colors": ["BLACK", "GOLD"], "ui_color": Color(0.20, 0.20, 0.25)},
				"players": ["ny_f1", "ny_f2", "ny_boss"]},
		],
		"story": {"arrive": "final_before", "won": "ending"},
	},
}

# Keys of a player:
#   name              short name shown in game (top bar, lineup); full: full name for story and cards
#   sheet, portrait   file ids (assets/players/<sheet>.png, assets/portraits/<portrait>.png)
#   number, role      jersey digit and role text for the lineup cards
#   tier              "start" (your underdogs, fixed ratings below), "avg", "good" or "boss"
#   ratings           only for "start"; city players are computed from STAGE_AVG + TIER (see the top)
#   spec              the stats that get TIER[tier].spec (good players: two)
#   steal_bias, block_bias   steal / block = defense + bias
#   recruitable       true = offered on the recruit screen after his city (the 2 good players and the boss)
#   look              what the art agent draws (sheet in the city's colors; <sheet>_crew.png in blue and gold)
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

	# --- Hometown: County Line (green and white); names are placeholders (Phase 6) ---
	"ht_g1": {"name": "SKIP", "full": "Skip Morrow",   # placeholder (Phase 6)
		"sheet": "ht_g1", "portrait": "ht_g1", "number": 3, "role": "shooter", "tier": "good",
		"spec": ["shooting", "speed"], "steal_bias": 4, "block_bias": -8, "recruitable": true,
		"look": "lanky, tan skin, short twists, green tank with white trim, long shorts",
		"bio": "Feed-store clerk with a quick release."},
	"ht_g2": {"name": "BUCK", "full": "Buck Halvorsen",   # placeholder (Phase 6)
		"sheet": "ht_g2", "portrait": "ht_g2", "number": 6, "role": "post scorer", "tier": "good",
		"spec": ["finishing", "defense"], "steal_bias": -6, "block_bias": 10, "recruitable": true,
		"look": "power forward, light skin, blond buzz cut, white tee with green trim, knee-length shorts",
		"bio": "Throws hay bales all summer and bodies everyone in the paint."},
	"ht_boss": {"name": "MAYOR", "full": "Earl \"Mayor\" Pruitt",   # placeholder (Phase 6)
		"sheet": "ht_boss", "portrait": "ht_boss", "number": 1, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 6, "block_bias": 6, "recruitable": true,
		"look": "stocky big, deep brown skin, bald, grey goatee, green sleeveless hoodie, white shorts",
		"bio": "Ran the county rec league for twenty years and still never loses on his own court."},
	"ht_a1": {"name": "DALE", "full": "Dale Whitcomb",   # placeholder (Phase 6)
		"sheet": "ht_a1", "portrait": "ht_a1", "number": 4, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 6, "block_bias": -6,
		"look": "stocky guard, light skin, backwards green cap, white tee, short shorts",
		"bio": "Weekend hooper, weekday mechanic."},
	"ht_a2": {"name": "RUSTY", "full": "Rusty Kowal",   # placeholder (Phase 6)
		"sheet": "ht_a2", "portrait": "ht_a2", "number": 8, "role": "forward", "tier": "avg",
		"spec": [], "steal_bias": -4, "block_bias": 4,
		"look": "wiry center, light skin, auburn hair with headband, green tank, long shorts",
		"bio": "Tall, willing, a little slow."},

	# --- Chicago: Lakeshore Gusts (purple and white); names are placeholders (Phase 6) ---
	"chi_g1": {"name": "NICO", "full": "Nico Vance",   # placeholder (Phase 6)
		"sheet": "chi_g1", "portrait": "chi_g1", "number": 7, "role": "deep shooter", "tier": "good",
		"spec": ["shooting", "stamina"], "steal_bias": 2, "block_bias": -8, "recruitable": true,
		"look": "lanky wing, umber skin, high-top hair, purple tank with white trim, arm sleeve",
		"bio": "Practices long shots into the lake wind until they stop drifting."},
	"chi_g2": {"name": "RIO", "full": "Rio Delgado",   # placeholder (Phase 6)
		"sheet": "chi_g2", "portrait": "chi_g2", "number": 0, "role": "slasher", "tier": "good",
		"spec": ["speed", "finishing"], "steal_bias": 8, "block_bias": -4, "recruitable": true,
		"look": "lanky guard, brown skin, short twists, white long tee with purple trim, leg sleeve",
		"bio": "Bike messenger who cuts through a defense like downtown traffic."},
	"chi_boss": {"name": "BIG LOU", "full": "Louis \"Big Lou\" Okafor",   # placeholder (Phase 6)
		"sheet": "chi_boss", "portrait": "chi_boss", "number": 5, "role": "all-around boss", "tier": "boss",
		"spec": [], "steal_bias": 0, "block_bias": 12, "recruitable": true,
		"look": "power forward, deep brown skin, bald, full beard, purple sleeveless hoodie, white shorts",
		"bio": "King of the rooftop courts; nobody scores on him twice."},
	"chi_a1": {"name": "MARCO", "full": "Marco Bellini",   # placeholder (Phase 6)
		"sheet": "chi_a1", "portrait": "chi_a1", "number": 2, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 6, "block_bias": -6,
		"look": "stocky guard, tan skin, backwards purple cap, white tee, short shorts",
		"bio": "Runs the pizza counter and the pick-and-roll."},
	"chi_a2": {"name": "TERRELL", "full": "Terrell Banks",   # placeholder (Phase 6)
		"sheet": "chi_a2", "portrait": "chi_a2", "number": 9, "role": "center", "tier": "avg",
		"spec": [], "steal_bias": -6, "block_bias": 8,
		"look": "wiry center, deep brown skin, buzz cut, purple tee, knee-length shorts",
		"bio": "Long arms, short temper."},

	# --- New York tournament stub (Phase 5): stub crews reuse today's red sheets; names are placeholders ---
	"ny_q1": {"name": "ACE", "full": "Ace Moreno",   # placeholder (Phase 6)
		"sheet": "red_1", "portrait": "red_1", "number": 5, "role": "big", "tier": "good",
		"spec": ["finishing", "defense"], "steal_bias": -6, "block_bias": 10},
	"ny_q2": {"name": "DASH", "full": "Dash Whitaker",   # placeholder (Phase 6)
		"sheet": "red_2", "portrait": "red_2", "number": 9, "role": "guard", "tier": "avg",
		"spec": [], "steal_bias": 8, "block_bias": -8},
	"ny_q3": {"name": "KNOX", "full": "Knox Albright",   # placeholder (Phase 6)
		"sheet": "red_3", "portrait": "red_3", "number": 8, "role": "center", "tier": "avg",
		"spec": [], "steal_bias": -4, "block_bias": 6},
	"ny_s1": {"name": "JAX", "full": "Jax Carrow",   # placeholder (Phase 6)
		"sheet": "red_2", "portrait": "red_2", "number": 3, "role": "shooter", "tier": "good",
		"spec": ["shooting", "speed"], "steal_bias": 6, "block_bias": -8},
	"ny_s2": {"name": "OMAR", "full": "Omar Latimer",   # placeholder (Phase 6)
		"sheet": "red_3", "portrait": "red_3", "number": 11, "role": "wing", "tier": "good",
		"spec": ["shooting", "stamina"], "steal_bias": 2, "block_bias": 0},
	"ny_s3": {"name": "BRUNO", "full": "Bruno Vasko",   # placeholder (Phase 6)
		"sheet": "red_1", "portrait": "red_1", "number": 4, "role": "big", "tier": "avg",
		"spec": [], "steal_bias": -6, "block_bias": 8},
	"ny_f1": {"name": "SLIM", "full": "Slim Ortega",   # placeholder (Phase 6)
		"sheet": "red_2", "portrait": "red_2", "number": 1, "role": "slasher", "tier": "good",
		"spec": ["speed", "finishing"], "steal_bias": 8, "block_bias": -6},
	"ny_f2": {"name": "HAMMER", "full": "Hank \"Hammer\" Doyle",   # placeholder (Phase 6)
		"sheet": "red_1", "portrait": "red_1", "number": 6, "role": "big", "tier": "good",
		"spec": ["finishing", "defense"], "steal_bias": -8, "block_bias": 12},
	"ny_boss": {"name": "KING", "full": "Marcus \"King\" Sterling",   # placeholder (Phase 6)
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
static func crew_sheet(id: String, for_your_crew: bool) -> String:
	var p: Dictionary = player(id)
	var s: String = p.get("sheet", id)
	if for_your_crew and p.get("recruitable", false):
		return s + "_crew"
	return s

# the 3 recruit candidates of a city (its 2 good players and the boss)
static func recruits(city_id: String) -> Array:
	var crew: Dictionary = city(city_id).get("crew", {})
	var out: Array = []
	for id in crew.get("good", []):
		out.append(id)
	if crew.has("boss"):
		out.append(crew["boss"])
	return out

# every PLAYERS id named in START_CREW and CITIES that is missing; [] = the data is consistent
static func missing_ids() -> Array:
	var named: Array = START_CREW.duplicate()
	for cid in CITIES:
		var c: Dictionary = CITIES[cid]
		var crew: Dictionary = c.get("crew", {})
		named.append_array(crew.get("good", []))
		named.append_array(crew.get("avg", []))
		if crew.has("boss"):
			named.append(crew["boss"])
		for r in c.get("rounds", []):
			named.append_array(r.get("players", []))
	var out: Array = []
	for id in named:
		if not PLAYERS.has(id):
			out.append(id)
	for cid in ROUTE:
		if not CITIES.has(cid):
			out.append("city:" + cid)
	return out
