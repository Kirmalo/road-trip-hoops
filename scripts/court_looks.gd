extends RefCounted
# Court looks (Phase 4, P4-07): how each court is drawn, as plain data, easy to edit on the tablet.
# Use it through   const Looks = preload("res://scripts/court_looks.gd")   (static functions only, never instanced).
#
# court.gd reads Looks.look() when it draws. Pick a look before the game scene is built (the COURT button on the
# panels sets it and restarts, like the level buttons): Looks.set_current("blacktop"). Test flag: -- --court <any look>
# (or --court=blacktop).
#
# Textures (made by tools/art/make_courts.py): when a file below exists it is used, otherwise the colors here draw a
# plain look (procedural fallback), so a missing file never breaks the game. New files are picked up by name.
#   floor_texture     a seamless floor tile, already foreshortened for the 3/4 view: repeated in screen space over the
#                     court and the apron, never stretched (ANGLED view; FLAT keeps the plain colors)
#   backdrop_texture  a strip standing 4 ft behind the far sideline, bottom on the floor, repeated left to right; the
#                     wall above it takes the strip's top-left color (ANGLED)
# Both are drawn at their *_scale (2 = each texture pixel is 2x2 sim pixels, like the 2x player sprites).
#
# Keys of a look:
#   name              shown on the COURT button
#   music             track name for audio.play_music (res://assets/music/<music>.ogg)
#   floor             main floor color; floor_stripe + stripe_ft: plank stripes every stripe_ft feet (0 = none)
#   speckle           number of small darker patches on the floor (worn asphalt), 0 = none
#   line              court line color; paint: the keys; logo: the center circle fill
#   apron             the floor around the court
#   backdrop          what stands behind the far sideline (ANGLED): "bleachers" (gym crowd), "fence" (fence and street),
#                     "none" (a plain dark border, owner Q3 b)
#   wall, wall_dark   backdrop base colors (the gym wall and bleachers; the street side for the fence)
#   backboard         "glass", "metal" or "wood" (P6-13: planks); board_square: the color of the square on the board
#   pole              hoop pole and arm color (a "wood" board also gets a wooden post); rim; net
# Optional keys (Phase 6, P6-12 / P6-13; court.gd ignores a missing key):
#   ambience          an ambience loop name for audio / twist_fx ("rain", "wind", "crowd")
#   front_fence       true: low fence posts and mesh along the near sideline, drawn on the floor under the players (cage)
#   floor_overlay     "puddles" (rain_park: shiny puddles) or "sand_drift" (beach: drifts of sand over the lines)
# Phase 8 (P8-06), only on the star reward looks (midnight, gold_hall):
#   reward            the star reward id that opens this look ("court_1", "court_2"; stars.gd / cosmetics.gd)
#   twist             always "none" (a reward look brings no twist)
#
# The city looks (barn ... cage) belong to the Road Trip cities (cities.gd "look"). In Quick Game the COURT button
# offers ALWAYS_OPEN plus the court of every city whose boss you have beaten (owner Q9, menu.gd quick_courts()).
# The reward looks (midnight, gold_hall) belong to no city and are not ALWAYS_OPEN, so quick_courts() leaves them out
# until the star rewards are wired in (Cosmetics.open_court_looks()); --court <look> shows them in a test run.
const LOOKS := {
	"gym": {
		"name": "GYM",
		"music": "gym",
		"floor_texture": "res://assets/courts/gym_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.80, 0.58, 0.34),
		"floor_stripe": Color(0.77, 0.55, 0.31),
		"stripe_ft": 3.0,
		"speckle": 0,
		"line": Color(1, 1, 1, 0.92),
		"paint": Color(0.18, 0.36, 0.72, 0.9),
		"logo": Color(0.18, 0.36, 0.72, 0.9),
		"apron": Color(0.16, 0.18, 0.24),
		"backdrop": "bleachers",
		"backdrop_texture": "res://assets/courts/gym_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.33, 0.27, 0.24),
		"wall_dark": Color(0.20, 0.16, 0.15),
		"backboard": "glass",
		"board_square": Color(1, 1, 1, 0.95),
		"pole": Color(0.22, 0.30, 0.55),
		"rim": Color(0.95, 0.42, 0.1),
		"net": Color(1, 1, 1, 0.75),
	},
	"blacktop": {
		"name": "BLACKTOP",
		"music": "blacktop",
		"floor_texture": "res://assets/courts/blacktop_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.25, 0.26, 0.28),
		"floor_stripe": Color(0.25, 0.26, 0.28),
		"stripe_ft": 0.0,
		"speckle": 260,
		"line": Color(0.96, 0.95, 0.88, 0.88),
		"paint": Color(0.62, 0.20, 0.16, 0.85),
		"logo": Color(0.62, 0.20, 0.16, 0.85),
		"apron": Color(0.42, 0.42, 0.40),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/blacktop_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.30, 0.31, 0.33),
		"wall_dark": Color(0.17, 0.18, 0.21),
		"backboard": "metal",
		"board_square": Color(0.95, 0.45, 0.12),
		"pole": Color(0.38, 0.40, 0.42),
		"rim": Color(0.92, 0.38, 0.10),
		"net": Color(0.80, 0.82, 0.86, 0.9),
	},
	# ---- Phase 6 city courts (P6-12; art and suggested colors from tools/art/make_courts.py --print-looks) ----
	"barn": {
		"name": "BARN",
		"music": "hometown",
		"floor_texture": "res://assets/courts/barn_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.76, 0.73, 0.66),
		"floor_stripe": Color(0.76, 0.73, 0.66),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(0.62, 0.17, 0.13, 0.95),   # barn red: white lines got lost on the light concrete
		"paint": Color(0.24, 0.54, 0.29, 0.75),
		"logo": Color(0.24, 0.54, 0.29, 0.75),
		"apron": Color(0.71, 0.68, 0.61),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/barn_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.42, 0.54, 0.24),
		"wall_dark": Color(0.30, 0.42, 0.35),
		"backboard": "wood",
		"board_square": Color(0.96, 0.94, 0.89),
		"pole": Color(0.61, 0.46, 0.31),
		"rim": Color(0.91, 0.38, 0.16),
		"net": Color(0.96, 0.94, 0.89, 0.85),
	},
	"rooftop": {
		"name": "ROOFTOP",
		"music": "chicago",
		"floor_texture": "res://assets/courts/rooftop_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.35, 0.45, 0.58),
		"floor_stripe": Color(0.35, 0.45, 0.58),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(1.00, 1.00, 1.00, 0.92),
		"paint": Color(0.48, 0.29, 0.69, 0.80),
		"logo": Color(0.48, 0.29, 0.69, 0.80),
		"apron": Color(0.31, 0.40, 0.53),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/rooftop_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.66, 0.43, 0.31),
		"wall_dark": Color(0.37, 0.23, 0.18),
		"ambience": "wind",
		"backboard": "glass",
		"board_square": Color(1.00, 1.00, 1.00),
		"pole": Color(0.23, 0.24, 0.28),
		"rim": Color(0.94, 0.42, 0.12),
		"net": Color(1.00, 1.00, 1.00, 0.80),
	},
	"soul_gym": {
		"name": "SOUL GYM",
		"music": "memphis",
		"floor_texture": "res://assets/courts/soul_gym_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.76, 0.51, 0.29),
		"floor_stripe": Color(0.70, 0.46, 0.25),
		"stripe_ft": 2.0,
		"speckle": 0,
		"line": Color(1.00, 0.97, 0.91, 0.92),
		"paint": Color(0.16, 0.42, 0.27, 0.85),
		"logo": Color(0.16, 0.42, 0.27, 0.85),
		"apron": Color(0.53, 0.31, 0.17),
		"backdrop": "bleachers",
		"backdrop_texture": "res://assets/courts/soul_gym_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.58, 0.31, 0.24),
		"wall_dark": Color(0.36, 0.19, 0.15),
		"ambience": "crowd",
		"backboard": "glass",
		"board_square": Color(1.00, 1.00, 1.00),
		"pole": Color(0.16, 0.42, 0.27),
		"rim": Color(0.94, 0.42, 0.12),
		"net": Color(1.00, 1.00, 1.00, 0.80),
	},
	"bayou": {
		"name": "BAYOU",
		"music": "new_orleans",
		"floor_texture": "res://assets/courts/bayou_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.29, 0.32, 0.29),
		"floor_stripe": Color(0.29, 0.32, 0.29),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(0.96, 0.94, 0.85, 0.85),
		"paint": Color(0.54, 0.29, 0.69, 0.70),
		"logo": Color(0.85, 0.63, 0.25, 0.70),
		"apron": Color(0.23, 0.25, 0.23),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/bayou_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.31, 0.38, 0.44),
		"wall_dark": Color(0.16, 0.21, 0.27),
		"backboard": "metal",
		"board_square": Color(0.85, 0.63, 0.25),
		"pole": Color(0.31, 0.24, 0.18),
		"rim": Color(0.91, 0.38, 0.16),
		"net": Color(0.88, 0.89, 0.85, 0.85),
	},
	"mountain": {
		"name": "MOUNTAIN",
		"music": "denver",
		"floor_texture": "res://assets/courts/mountain_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.37, 0.56, 0.35),
		"floor_stripe": Color(0.37, 0.56, 0.35),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(1.00, 1.00, 1.00, 0.92),
		"paint": Color(0.69, 0.35, 0.23, 0.80),
		"logo": Color(0.69, 0.35, 0.23, 0.80),
		"apron": Color(0.29, 0.46, 0.27),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/mountain_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.48, 0.64, 0.29),
		"wall_dark": Color(0.20, 0.42, 0.27),
		"backboard": "metal",
		"board_square": Color(1.00, 1.00, 1.00),
		"pole": Color(0.29, 0.35, 0.29),
		"rim": Color(0.94, 0.42, 0.12),
		"net": Color(1.00, 1.00, 1.00, 0.85),
	},
	"rain_park": {
		"name": "RAIN PARK",
		"music": "seattle",
		"floor_texture": "res://assets/courts/rain_park_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.25, 0.27, 0.30),
		"floor_stripe": Color(0.25, 0.27, 0.30),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(0.91, 0.93, 0.94, 0.85),
		"paint": Color(0.16, 0.48, 0.42, 0.75),
		"logo": Color(0.16, 0.48, 0.42, 0.75),
		"apron": Color(0.22, 0.24, 0.27),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/rain_park_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.29, 0.41, 0.25),
		"wall_dark": Color(0.16, 0.27, 0.23),
		"ambience": "rain",
		"backboard": "metal",
		"board_square": Color(0.91, 0.93, 0.94),
		"pole": Color(0.16, 0.18, 0.21),
		"rim": Color(0.91, 0.38, 0.16),
		"net": Color(0.78, 0.82, 0.85, 0.85),
		"floor_overlay": "puddles",
	},
	"beach": {
		"name": "BEACH",
		"music": "los_angeles",
		"floor_texture": "res://assets/courts/beach_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.90, 0.80, 0.58),
		"floor_stripe": Color(0.90, 0.80, 0.58),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(0.16, 0.42, 0.69, 0.85),
		"paint": Color(1.00, 0.48, 0.35, 0.55),
		"logo": Color(1.00, 0.48, 0.35, 0.55),
		"apron": Color(0.85, 0.74, 0.52),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/beach_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.66, 0.47, 0.31),
		"wall_dark": Color(0.37, 0.26, 0.17),
		"backboard": "metal",
		"board_square": Color(1.00, 0.48, 0.35),
		"pole": Color(0.91, 0.89, 0.86),
		"rim": Color(0.94, 0.42, 0.12),
		"net": Color(1.00, 1.00, 1.00, 0.90),
		"floor_overlay": "sand_drift",
	},
	"cage": {
		"name": "CAGE",
		"music": "newyork",
		"floor_texture": "res://assets/courts/cage_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.33, 0.31, 0.30),
		"floor_stripe": Color(0.33, 0.31, 0.30),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(0.96, 0.94, 0.88, 0.85),
		"paint": Color(0.16, 0.48, 0.29, 0.75),
		"logo": Color(0.75, 0.23, 0.19, 0.75),
		"apron": Color(0.29, 0.27, 0.27),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/cage_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.43, 0.42, 0.47),
		"wall_dark": Color(0.24, 0.24, 0.27),
		"backboard": "metal",
		"board_square": Color(0.96, 0.94, 0.88),
		"pole": Color(0.23, 0.26, 0.30),
		"rim": Color(0.91, 0.38, 0.16),
		"net": Color(0.60, 0.63, 0.66, 0.90),
		"front_fence": true,
	},
	# ---- Phase 8 star rewards (P8-06; tools/art/make_courts.py --print-looks): Quick Game courts opened by stars,
	# "reward" is the Stars / Cosmetics id. No twist. Never in quick_courts() until Cosmetics.open_court_looks()
	# says they are open (menu.gd, a later task) ----
	"midnight": {
		"name": "MIDNIGHT",
		"music": "blacktop",
		"floor_texture": "res://assets/courts/midnight_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.17, 0.18, 0.27),
		"floor_stripe": Color(0.17, 0.18, 0.27),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(0.85, 0.96, 1.00, 0.92),
		"paint": Color(0.75, 0.23, 0.62, 0.70),
		"logo": Color(0.16, 0.71, 0.82, 0.70),
		"apron": Color(0.13, 0.14, 0.22),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/midnight_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.10, 0.12, 0.26),
		"wall_dark": Color(0.05, 0.05, 0.15),
		"backboard": "glass",
		"board_square": Color(0.42, 0.94, 1.00),
		"pole": Color(0.08, 0.09, 0.16),
		"rim": Color(0.94, 0.42, 0.12),
		"net": Color(0.91, 0.93, 1.00, 0.85),
		"reward": "court_1",
		"twist": "none",
	},
	"gold_hall": {
		"name": "GOLD HALL",
		"music": "gym",
		"floor_texture": "res://assets/courts/gold_hall_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.92, 0.77, 0.49),
		"floor_stripe": Color(0.89, 0.72, 0.44),
		"stripe_ft": 3.0,
		"speckle": 0,
		"line": Color(1.00, 1.00, 1.00, 0.95),
		"paint": Color(0.15, 0.19, 0.49, 0.88),
		"logo": Color(0.78, 0.59, 0.16, 0.85),
		"apron": Color(0.10, 0.09, 0.19),
		"backdrop": "bleachers",
		"backdrop_texture": "res://assets/courts/gold_hall_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.13, 0.13, 0.24),
		"wall_dark": Color(0.07, 0.07, 0.15),
		"backboard": "glass",
		"board_square": Color(0.94, 0.78, 0.25),
		"pole": Color(0.10, 0.09, 0.19),
		"rim": Color(0.94, 0.42, 0.12),
		"net": Color(1.00, 1.00, 1.00, 0.85),
		"reward": "court_2",
		"twist": "none",
	},
	# ---- Phase 9 era court (P9-05; tools/art/make_courts.py --era, --print-looks): the Legends Chapter 1 court, an
	# old wood gym. No twist key (the legends match brings era_grand), no reward, not a city: never in quick_courts().
	# Music: the era's own track, Bebop (P9-16, owner's pick; assets/music/legends_grand.ogg) ----
	"era_grand": {
		"name": "OLD GYM",
		"music": "legends_grand",
		"floor_texture": "res://assets/courts/era_grand_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.80, 0.60, 0.33),
		"floor_stripe": Color(0.75, 0.55, 0.29),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(1.00, 0.96, 0.86, 0.92),
		"paint": Color(0.59, 0.23, 0.18, 0.82),
		"logo": Color(0.78, 0.57, 0.23, 0.82),
		"apron": Color(0.43, 0.27, 0.14),
		"backdrop": "bleachers",
		"backdrop_texture": "res://assets/courts/era_grand_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.82, 0.75, 0.61),
		"wall_dark": Color(0.31, 0.18, 0.09),
		"backboard": "wood",
		"board_square": Color(0.94, 0.90, 0.80),
		"pole": Color(0.48, 0.31, 0.19),
		"rim": Color(0.91, 0.38, 0.16),
		"net": Color(0.96, 0.94, 0.89, 0.85),
	},
	# ---- Phase 10 era court (P10-05; tools/art/make_courts.py --era fathers, --print-looks): the Legends Chapter 2
	# court, a night playground under light towers. No twist key (the legends match brings the era twist), no reward,
	# not a city: never in quick_courts(). Music: an existing track until the era's own (P10-20) ----
	"era_fathers": {
		"name": "NIGHT PARK",
		"music": "blacktop",
		"floor_texture": "res://assets/courts/era_fathers_floor.png",
		"floor_scale": 2.0,
		"floor": Color(0.33, 0.30, 0.29),
		"floor_stripe": Color(0.33, 0.30, 0.29),
		"stripe_ft": 0.0,
		"speckle": 0,
		"line": Color(1.00, 0.97, 0.93, 0.92),
		"paint": Color(0.16, 0.43, 0.32, 0.78),
		"logo": Color(0.94, 0.66, 0.23, 0.72),
		"apron": Color(0.24, 0.22, 0.22),
		"backdrop": "fence",
		"backdrop_texture": "res://assets/courts/era_fathers_backdrop.png",
		"backdrop_scale": 2.0,
		"wall": Color(0.23, 0.11, 0.19),
		"wall_dark": Color(0.09, 0.05, 0.11),
		"backboard": "glass",
		"board_square": Color(1.00, 0.90, 0.63),
		"pole": Color(0.20, 0.17, 0.20),
		"rim": Color(0.94, 0.42, 0.12),
		"net": Color(1.00, 0.96, 0.89, 0.85),
	},
}
const DEFAULT := "gym"
const ALWAYS_OPEN := ["gym", "blacktop"]   # Quick Game courts that need no unlock (twist none)

static var current := DEFAULT
static var _args_done := false

# the current look's data
static func look() -> Dictionary:
	return LOOKS.get(current, LOOKS[DEFAULT])

# the look names in button order: gym, blacktop, the city courts in route order, then the reward looks (menu.gd
# keeps only the open ones for the COURT button)
static func names() -> Array:
	return LOOKS.keys()

# the star reward id of a look ("court_1", "court_2"), "" for every other look (P8-06)
static func reward_of(n: String) -> String:
	return str((LOOKS.get(n, {}) as Dictionary).get("reward", ""))

# the look opened by a star reward id ("court_1" -> "midnight"), "" when none
static func look_for_reward(reward_id: String) -> String:
	for n in LOOKS.keys():
		if reward_of(str(n)) == reward_id and reward_id != "":
			return str(n)
	return ""

# true for gym and blacktop (always in Quick Game)
static func always_open(n: String) -> bool:
	return ALWAYS_OPEN.has(n)

# select a look by name; returns false (and keeps the current one) for an unknown name
static func set_current(n: String) -> bool:
	if not LOOKS.has(n):
		return false
	current = n
	return true

# the next look after the current one (for a COURT button that cycles); skips the reward looks, as before P8-06
static func next_name() -> String:
	var keys: Array = []
	for n in LOOKS.keys():
		if reward_of(str(n)) == "":
			keys.append(n)
	var i: int = keys.find(current)
	return keys[(i + 1) % keys.size()]

# the music track of the current look (P4-11 passes it to audio.play_music)
static func music() -> String:
	return look().get("music", "")

# a texture of the current look by key ("floor_texture", "backdrop_texture"), or null when the file isn't there yet
static func texture(key: String) -> Texture2D:
	var path: String = look().get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

# test flag -- --court <look> (or --court=gym), any look, locked or not; read once per run (court.gd, menu.gd call it)
static func parse_args() -> void:
	if _args_done:
		return
	_args_done = true
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		var v := ""
		if args[i].begins_with("--court="):
			v = args[i].substr("--court=".length())
		elif args[i] == "--court" and i + 1 < args.size():
			v = args[i + 1]
		if v != "" and not set_current(v):
			print("--court: unknown look '%s' (%s)" % [v, ", ".join(PackedStringArray(LOOKS.keys()))])
