extends RefCounted
# Scene flow between the screens (P5-01, board "Scene flow"). Static only, used through preload:
#   const Flow = preload("res://scripts/flow.gd")
#   Flow.go("map")                                              # reloads the scene into the trip map
#   Flow.go("story", {"scene": "hometown_arrive", "then": "lineup"})
#   if Flow.in_trip(): var target: int = int(Flow.match.get("target", 21))
# main.tscn stays the only scene. go() sets Flow.screen and reloads the scene (deferred, like menu.gd); in _ready()
# main.gd builds the game when Flow.screen == "game", else calls Flow.build_screen(self), which adds that screen's
# CanvasLayer (built in code by its own script) plus an audio.gd for the menu music, and the court is not built.
# State lives in static vars, so it survives reload_current_scene(); the trip save (save.gd) is the truth on launch.
#
# NOTE: `match` is a GDScript keyword. Other scripts use it as `Flow.match` (with the dot, that parses); inside this
# file it is only reached through _me().match.
#
# Screen scripts (SCREENS below) extend CanvasLayer (or any Node) and build their UI in code with ui_kit.gd. Before
# the node enters the tree, build_screen() sets these properties if the script declares them:
#   var main      the main.gd node (its rng, stat(), get_tree())
#   var audio     the audio.gd node for this screen (audio.play("tap"), play_music())
# and after _ready() it plays `var music: String` if the script has it ("" = silence), else MENU_MUSIC.
# One script can serve several screens (title.gd: "title", "settings", "crew"); it reads Flow.screen and Flow.args.
# Every screen script implements `func auto_step() -> bool` for the trip test: take the default choice (first city,
# first option, keep the lineup, spend points on the lowest stat of the first player, recruit the first candidate,
# advance the story one line); false when there is nothing to do. Only the trip test calls it (Flow.auto_step()).
# A missing script shows a plain "screen not built yet" panel (CONTINUE to args.then, BACK, or QUICK GAME on the
# title), so the flow runs before every screen exists.

const SELF_PATH := "res://scripts/flow.gd"
const AUDIO_PATH := "res://scripts/audio.gd"       # loaded at run time (no preload cycles with the screens)
const MENU_PATH := "res://scripts/menu.gd"         # prepare_level() / prepare_settings() / music_on
const TRIP_PATH := "res://scripts/trip.gd"         # P5-05: record_result(last_result) records and saves
const TRIP_TEST_PATH := "res://scripts/trip_test.gd"   # P5-15: added under --trip-test

const RESULT_DELAY := 2.5         # s after a trip game ends (FINAL shown) before main.gd calls game_finished()
const MENU_MUSIC := "menu"        # track for screens that don't name one
const GAME := "game"              # the one screen main.gd builds itself
const SCREENS := {
	"title": "res://scripts/title.gd",        # P5-06 (title, settings, crew & credits)
	"settings": "res://scripts/title.gd",
	"crew": "res://scripts/title.gd",
	"map": "res://scripts/trip_map.gd",       # P5-09
	"story": "res://scripts/story.gd",        # P5-10
	"lineup": "res://scripts/lineup.gd",      # P5-11
	"result": "res://scripts/after_game.gd",  # P5-12 (result, points)
	"points": "res://scripts/after_game.gd",
	"recruit": "res://scripts/recruit.gd",    # P5-13
	"bracket": "res://scripts/bracket.gd",    # P5-14
	"howto": "res://scripts/howto.gd",        # P7-H3 (How to Play), args {"back": "<screen>"} (default "title");
	                                          # a missing howto.gd shows the "not built yet" panel (BACK to the title)
	"draft": "res://scripts/draft.gd",        # P8-16 (draft a player into an open roster slot), args {"back": "lineup"}
	"locker": "res://scripts/locker.gd",      # P8-15 (star ladder, jersey / ball / van picks), args {"back": "title"};
	                                          # nothing routes to either before its script exists (else "not built yet")
}
# Test modes that skip the title and play a game at once, as today (main.gd checks skip_title()).
const TEST_FLAGS := ["--autoplay", "--humantest", "--shots", "--ballshots", "--menushot", "--viewtest", "--city",
		"--howto-shots"]
const TRIP_TEST_FLAG := "--trip-test"

static var screen := "title"      # "title", "settings", "crew", "howto", "map", "story", "lineup", "game",
                                  # "result", "points", "recruit", "bracket", "draft", "locker"
static var args := {}             # arguments for the screen, e.g. story: {"scene": "hometown_arrive", "then": "lineup"}
static var match := {}            # the next game (board "Match config", built by trip.gd); {} = Quick Game / tests
static var last_result := {}      # {"won": bool, "winner": int, "score": [a, b], "stats": {...}} after a trip game
static var test := ""             # "trip" under --trip-test
static var _inited := false
static var _current: WeakRef = null   # the screen node build_screen() made (gone after the next reload)

static func _me() -> GDScript:
	return load(SELF_PATH) as GDScript

# Once per run: the command line (safe to call again).
static func init_once() -> void:
	if _inited:
		return
	_inited = true
	if OS.get_cmdline_user_args().has(TRIP_TEST_FLAG):
		test = "trip"

# True in the test modes that play a game at once (autoplay, humantest, shots, menushot, viewtest, --city,
# --howto-shots).
static func skip_title() -> bool:
	init_once()
	if test != "":
		return false
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	for flag in TEST_FLAGS:
		if cmd.has(flag):
			return true
	return false

# A trip game is next (or being played).
static func in_trip() -> bool:
	var m: Dictionary = _me().match
	return str(m.get("mode", "")) == "trip"

# Go to a screen: sets screen and args, then reloads the scene (deferred: a Button may still be handling the tap).
# Going to "title" clears Flow.match, so a Quick Game from the title is today's game.
static func go(to: String, to_args := {}) -> void:
	if to != GAME and not SCREENS.has(to):
		push_warning("Flow.go: unknown screen '%s'" % to)
	screen = to
	args = to_args.duplicate(true)
	if to == "title":
		_me().match = {}
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.call_deferred("reload_current_scene")

# main.gd calls this RESULT_DELAY s after a trip game ends (winner 0 = your crew). Fills last_result, asks trip.gd to
# record it and save (Trip.record_result(last_result), if trip.gd exists yet), then goes to the result screen.
static func game_finished(winner: int, score: Array, stats: Dictionary) -> void:
	last_result = {"won": winner == 0, "winner": winner, "score": score.duplicate(), "stats": stats.duplicate(true)}
	_call_script(TRIP_PATH, "record_result", [last_result])
	go("result")

# main.gd calls this in _ready() when screen != "game": adds the screen node and its audio, returns the node.
static func build_screen(main: Node) -> Node:
	init_once()
	var menu: GDScript = _load(MENU_PATH)
	if menu != null:
		menu.call("prepare_level")      # the saved level, for screens that show it
		menu.call("prepare_settings")   # music on/off
	var audio: Node = null
	var audio_script: GDScript = _load(AUDIO_PATH)
	if audio_script != null:
		audio = audio_script.new()
		if main.has_method("stat"):
			audio.set("game", main)   # sfx_/music_ stats, as in a game
		main.add_child(audio)
		if menu != null:
			audio.call("set_music_on", bool(menu.get("music_on")))
	var node: Node = null
	var path: String = str(SCREENS.get(screen, ""))
	var s: GDScript = _load(path)
	if s != null:
		var made = s.new()
		if made is Node:
			node = made
		else:
			push_warning("Flow: %s is not a Node" % path)
	if node == null:
		node = NotBuilt.new()
	if "main" in node:
		node.set("main", main)
	if "audio" in node:
		node.set("audio", audio)
	main.add_child(node)
	_current = weakref(node)
	if audio != null:
		var track: String = MENU_MUSIC
		if "music" in node:
			track = str(node.get("music"))
		if track == "":
			audio.call("stop_music")
		else:
			audio.call("play_music", track)
	attach_test(main)
	return node

# Under --trip-test: adds trip_test.gd (P5-15) to main, if it exists. build_screen() calls it; main.gd calls it too
# when it builds a game, so the driver sees every screen. Returns the node or null.
static func attach_test(main: Node) -> Node:
	init_once()
	if test != "trip":
		return null
	var s: GDScript = _load(TRIP_TEST_PATH)
	if s == null:
		return null
	var node = s.new()
	if not (node is Node):
		return null
	if "main" in node:
		node.set("main", main)
	main.add_child(node)
	return node

# The trip test's step: the current screen's auto_step(); false when there is no screen or nothing to do.
static func auto_step() -> bool:
	if _current == null:
		return false
	var node = _current.get_ref()
	if node == null or not is_instance_valid(node) or not node.has_method("auto_step"):
		return false
	return bool(node.call("auto_step"))

# The screen node build_screen() made this scene, or null.
static func current_screen() -> Node:
	if _current == null:
		return null
	var node = _current.get_ref()
	return node as Node if node != null and is_instance_valid(node) else null

static func _load(path: String) -> GDScript:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as GDScript

# Calls a static function of an optional script (trip.gd may not exist yet). Returns its result, or null.
static func _call_script(path: String, fn: String, call_args: Array):
	var s: GDScript = _load(path)
	if s == null or not s.has_method(fn):
		return null
	return s.callv(fn, call_args)


# The "screen not built yet" panel for a screen whose script is missing. CONTINUE follows args.then (story scenes
# say where they lead), BACK goes to the map in a trip or the title, and the title offers QUICK GAME.
class NotBuilt extends CanvasLayer:
	const _UI = preload("res://scripts/ui_kit.gd")
	var main
	var audio
	var _then := ""
	var _then_args := {}
	var _back := "title"

	func _flow() -> GDScript:
		return load("res://scripts/flow.gd") as GDScript

	func _ready() -> void:
		var flow: GDScript = _flow()
		var scr: String = str(flow.get("screen"))
		var a: Dictionary = flow.get("args")
		_then = str(a.get("then", ""))
		var ta = a.get("then_args", {})
		_then_args = ta if ta is Dictionary else {}
		_back = "map" if bool(flow.call("in_trip")) and scr != "map" else "title"
		var root: Control = _UI.screen_root(self)
		var box: VBoxContainer = _UI.vbox(root)
		_UI.title(box, "SCREEN NOT BUILT YET")
		_UI.subtitle(box, scr.to_upper() + (("  " + JSON.stringify(a)) if a.size() > 0 else ""))
		var row: HBoxContainer = _UI.hbox(box)
		if _then != "":
			_UI.button(row, "CONTINUE", _continue, _UI.KIND_LIT)
		if scr == "title":
			_UI.button(row, "QUICK GAME", _quick_game, _UI.KIND_LIT, _UI.OPT_SIZE)
		else:
			_UI.button(row, "BACK", _go_back, _UI.KIND_OPT, _UI.SMALL_SIZE)

	func _continue() -> void:
		_flow().call("go", _then, _then_args)

	func _go_back() -> void:
		_flow().call("go", _back)

	func _quick_game() -> void:
		_flow().call("go", "game")

	# trip test: follow args.then if the flow says where to go; otherwise nothing to do
	func auto_step() -> bool:
		if _then == "":
			return false
		_continue()
		return true
