extends RefCounted
# Court looks (Phase 4, P4-07): how each court is drawn, as plain data, easy to edit on the tablet.
# Use it through   const Looks = preload("res://scripts/court_looks.gd")   (static functions only, never instanced).
#
# court.gd reads Looks.look() when it draws. Pick a look before the game scene is built (the COURT button on the
# panels sets it and restarts, like the level buttons): Looks.set_current("blacktop"). Test flag: -- --court gym|blacktop
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
#   backboard         "glass" or "metal"; board_square: the color of the square on the board
#   pole              hoop pole and arm color; rim; net
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
}
const DEFAULT := "gym"

static var current := DEFAULT
static var _args_done := false

# the current look's data
static func look() -> Dictionary:
	return LOOKS.get(current, LOOKS[DEFAULT])

# the look names in button order (the COURT button cycles through them)
static func names() -> Array:
	return LOOKS.keys()

# select a look by name; returns false (and keeps the current one) for an unknown name
static func set_current(n: String) -> bool:
	if not LOOKS.has(n):
		return false
	current = n
	return true

# the next look after the current one (for a COURT button that cycles)
static func next_name() -> String:
	var keys: Array = LOOKS.keys()
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

# test flag -- --court gym|blacktop (or --court=gym); read once per run, court.gd calls it
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
