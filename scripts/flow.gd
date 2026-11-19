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
# Phase 9 (P9-03, board "Flow"): the Legends mode. All loaded at run time, so a missing script changes nothing.
const LEGENDS_PATH := "res://scripts/legends.gd"            # P9-12: record_result(last_result), after_result()
const LEGENDS_DATA_PATH := "res://scripts/legends_data.gd"  # P9-07: chapter_of(legend id)
const LEGENDS_TEST_PATH := "res://scripts/legends_test.gd"  # P9-25: added under --legends-test
const LEGENDS_SCREEN := "legends"   # the era tour (args {"chapter": id} opens that chapter); where a legends game ends
const LEGENDS_MODE := "legends"     # Flow.match.mode of a challenge or finale game

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
	                                          # the title's LOCKER button routes there already; a missing script shows "not built yet"
	"legends": "res://scripts/legends_tour.gd",   # P9-18 (era timeline; args {"chapter": id} opens that chapter);
	                                              # BACK to the title. "not built yet" until P9-18
	"hall": "res://scripts/hall.gd",          # P9-19 (Hall of Legends), args {"back": "legends" | "crew"} (default
	                                          # "legends"); "not built yet" until P9-19
}
# Test modes that skip the title and play a game at once, as today (main.gd checks skip_title()).
const TEST_FLAGS := ["--autoplay", "--humantest", "--shots", "--ballshots", "--menushot", "--viewtest", "--city",
		"--howto-shots"]
const TRIP_TEST_FLAG := "--trip-test"
const LEGENDS_TEST_FLAG := "--legends-test"   # P9-03: adds legends_test.gd (P9-25) like --trip-test adds trip_test.gd
const HALL_BACKS := ["legends", "crew"]       # where the Hall's BACK may go (anything else: "legends")

static var screen := "title"      # "title", "settings", "crew", "howto", "map", "story", "lineup", "game",
                                  # "result", "points", "recruit", "bracket", "draft", "locker", "legends", "hall"
static var args := {}             # arguments for the screen, e.g. story: {"scene": "hometown_arrive", "then": "lineup"}
static var match := {}            # the next game (board "Match config", built by trip.gd or legends.gd); {} = Quick
                                  # Game / tests
static var last_result := {}      # {"won": bool, "winner": int, "score": [a, b], "stats": {...}} after a trip game;
                                  # a legends game adds "challenge": {"type", "met", "why"} (challenge.gd, P9-13)
static var test := ""             # "trip" under --trip-test, "legends" under --legends-test (trip wins if both)
static var _inited := false
static var _current: WeakRef = null   # the screen node build_screen() made (gone after the next reload)

static func _me() -> GDScript:
	return load(SELF_PATH) as GDScript

# Once per run: the command line (safe to call again).
static func init_once() -> void:
	if _inited:
		return
	_inited = true
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	if cmd.has(TRIP_TEST_FLAG):
		test = "trip"
	elif cmd.has(LEGENDS_TEST_FLAG):
		test = "legends"

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

# P9-03: a Legends challenge or finale is next (or being played): Flow.match.mode == "legends".
static func in_legends() -> bool:
	var m: Dictionary = _me().match
	return str(m.get("mode", "")) == LEGENDS_MODE

# P9-03: a game built from Flow.match (a trip game or a legends game); false in Quick Game and the plain tests.
static func in_match() -> bool:
	return in_trip() or in_legends()

# P9-03: the chapter of the legends game in Flow.match ("" when unknown): match.chapter if set, else from match.key
# ("fin:<chapter>", or "lg:<legend id>" through LegendsData.chapter_of()), else from match.challenge.legend.
static func legends_chapter() -> String:
	var m: Dictionary = _me().match
	var ch: String = str(m.get("chapter", ""))
	if ch != "":
		return ch
	var key: String = str(m.get("key", ""))
	if key.begins_with("fin:"):
		return key.substr(4)
	var lid: String = ""
	if key.begins_with("lg:"):
		lid = key.substr(3)
	else:
		var c = m.get("challenge", {})
		if c is Dictionary:
			lid = str(c.get("legend", ""))
	if lid == "":
		return ""
	var got = _call_script(LEGENDS_DATA_PATH, "chapter_of", [lid])
	return str(got) if got != null else ""

# P9-03: the args for the Legends screen after a legends game: that game's chapter view, else the timeline ({}).
static func legends_args() -> Dictionary:
	var ch: String = legends_chapter()
	return {"chapter": ch} if ch != "" else {}

# P9-03: where the pause panel's QUIT leads: the trip map in a trip game, the Legends screen (on the game's chapter)
# in a legends game, else the title. quit_args() are the args for it. (pause.gd today asks for "title" outside a
# trip; go() turns that into the Legends screen in a legends game, so pause.gd needs no change.)
static func quit_screen() -> String:
	if in_trip():
		return "map"
	if in_legends():
		return LEGENDS_SCREEN
	return "title"

static func quit_args() -> Dictionary:
	return legends_args() if in_legends() else {}

# Go to a screen: sets screen and args, then reloads the scene (deferred: a Button may still be handling the tap).
# Going to "title" clears Flow.match, so a Quick Game from the title is today's game.
# P9-03: leaving a legends game for the title (the pause panel's QUIT asks for "title" outside a trip) goes to the
# Legends screen instead, on that game's chapter; Flow.match is kept until the title clears it. Starting a game drops
# the last game's "challenge" entry from last_result, so the verdict game_finished() reads is always this game's.
static func go(to: String, to_args := {}) -> void:
	if to != GAME and not SCREENS.has(to):
		push_warning("Flow.go: unknown screen '%s'" % to)
	if to == "title" and screen == GAME and in_legends():
		to = LEGENDS_SCREEN
		to_args = legends_args()
	if to == GAME:
		last_result.erase("challenge")
	screen = to
	args = to_args.duplicate(true)
	if to == "title":
		_me().match = {}
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.call_deferred("reload_current_scene")

# main.gd calls this RESULT_DELAY s after a trip game ends (winner 0 = your crew). Fills last_result, asks trip.gd to
# record it and save (Trip.record_result(last_result), if trip.gd exists yet), then goes to the result screen.
# P9-03: a legends game (in_legends()) never reaches trip.gd: last_result keeps the challenge verdict (the
# last_result.challenge challenge.gd set, else stats.challenge), Legends.record_result(last_result) records it, and
# Legends.after_result() says where to go ({"screen", "args"}; a missing or unknown answer: the Legends screen on this
# game's chapter). A missing legends.gd goes to the title.
static func game_finished(winner: int, score: Array, stats: Dictionary) -> void:
	var legends: bool = in_legends()
	var verdict = last_result.get("challenge", stats.get("challenge", null))
	last_result = {"won": winner == 0, "winner": winner, "score": score.duplicate(), "stats": stats.duplicate(true)}
	if not legends:
		_call_script(TRIP_PATH, "record_result", [last_result])
		go("result")
		return
	if verdict is Dictionary:
		last_result["challenge"] = (verdict as Dictionary).duplicate(true)
	var ls: GDScript = _load(LEGENDS_PATH)
	if ls == null:
		_me().match = {}   # no longer in_legends(), so go() really goes to the title
		go("title")
		return
	if ls.has_method("record_result"):
		ls.call("record_result", last_result)
	var to: String = LEGENDS_SCREEN
	var to_args: Dictionary = legends_args()
	if ls.has_method("after_result"):
		var nxt = ls.call("after_result")
		if nxt is Dictionary and str(nxt.get("screen", "")) != "":
			var s: String = str(nxt.get("screen", ""))
			if s == GAME or SCREENS.has(s):
				to = s
				var a = nxt.get("args", {})
				to_args = a if a is Dictionary else {}
	if to == "title":
		_me().match = {}   # legends.gd asked for the title: no redirect to the Legends screen
	go(to, to_args)

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
# when it builds a game, so the driver sees every screen. Under --legends-test the same with legends_test.gd (P9-25).
# Returns the node or null.
static func attach_test(main: Node) -> Node:
	init_once()
	var path: String = ""
	if test == "trip":
		path = TRIP_TEST_PATH
	elif test == "legends":
		path = LEGENDS_TEST_PATH
	if path == "":
		return null
	var s: GDScript = _load(path)
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
# say where they lead), BACK goes to the map in a trip or the title, and the title offers QUICK GAME. P9-03: the
# Legends screen's BACK is the title, the Hall's its args.back ("legends" or "crew", default "legends"); Escape (so
# the Android back too, main.gd sends it as Escape) is BACK on every panel but the title's.
class NotBuilt extends CanvasLayer:
	const _UI = preload("res://scripts/ui_kit.gd")
	const _HALL_BACKS := ["legends", "crew"]   # = Flow.HALL_BACKS (this class reaches flow.gd only by load)
	var main
	var audio
	var _then := ""
	var _then_args := {}
	var _back := "title"
	var _scr := ""
	var _gone := false   # a Flow.go() is on its way: no second one

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
		if scr == "legends":
			_back = "title"
		elif scr == "hall":
			var hb: String = str(a.get("back", "legends"))
			_back = hb if _HALL_BACKS.has(hb) else "legends"
		_scr = scr
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
		if _gone:
			return
		_gone = true
		_flow().call("go", _back)

	# desktop Escape (main.gd turns the Android back into one): BACK, except on the title (main.gd quits there)
	func _unhandled_key_input(event: InputEvent) -> void:
		if _scr == "title" or not (event is InputEventKey):
			return
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_go_back()

	func _quick_game() -> void:
		_flow().call("go", "game")

	# trip test: follow args.then if the flow says where to go; otherwise nothing to do
	func auto_step() -> bool:
		if _then == "":
			return false
		_continue()
		return true
