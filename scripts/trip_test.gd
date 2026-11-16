extends Node
# Trip test driver (P5-15). Flow adds one to every scene under -- --trip-test (Flow.attach_test: screens and games),
# so the driver lives in static vars across the reloads. It plays a whole Road Trip headless:
#   title -> new trip -> Hometown (3 games) -> points -> recruit -> Chicago -> New York bracket -> ending -> TRIP END
# On a screen it calls the screen's auto_step() (the default choice) every STEP_WAIT frames. A screen whose script is
# not built yet shows the flow's "not built yet" panel; when that panel has nowhere to go, the driver takes the
# screen's default choice itself through trip.gd (FALLBACK below), so the test runs with whichever screens exist.
# In a game it makes both teams CPU (main.autoplay) and waits for the FINAL; trip games play to --target if given.
#
#   godot --headless --path . --fixed-fps 60 --quit-after 2000000 -- --trip-test --target 3
#   ... -- --trip-test --target 3 --trip-force-loss 2        the 2nd trip game played in this run is lost (retry)
#   ... -- --trip-test --target 3 --trip-stop-after hometown  quits on the map once Hometown is done (saved)
#   ... -- --trip-test --target 3 --trip-resume               loads the save (a new process) and goes on
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- --trip-test
#        --target 3 --screens      screenshots of every screen to /tmp/hoops_screen_NN_<screen>.png
# Prints TRIP lines (screen, city, game, phase, points, record, roster, save check, each game's result) and ends with
# "TRIP END" (exit 0), "TRIP STOP" (exit 0) or "TRIP ERROR: <why>" (exit 1). Uses user://trip_test.json (save.gd).

const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Save = preload("res://scripts/save.gd")
const Cities = preload("res://scripts/cities.gd")
const Ratings = preload("res://scripts/ratings.gd")

const STEP_WAIT := 12             # frames on a screen between auto_step() calls
const SHOT_WAIT := 40             # with --screens: frames before a screen's screenshot (layout and drawing settled)
const SHOTS_PER_SCREEN := 2       # screenshots per screen name (the map: van driving, then parked)
const SHOT_PATH := "/tmp/hoops_screen_%02d_%s.png"
const STALL_FRAMES := 1800        # a screen doing nothing this long (30 s) fails the test
const GAME_FRAMES := 60 * 60 * 45 # a trip game longer than 45 min (frames at 60 fps) fails the test
const FORCE_LOSS_FRAMES := 90     # a forced loss ends its game this many frames after tip-off
const MAX_GAMES := 40             # more trip games than this = a loop
const MAX_SCREENS := 300          # more screen visits than this = a loop
const PICK_TEST := true           # on the first lineup with a recruit: pick [recruit, underdog 2, underdog 1] by taps

# --- the run (static: survives reload_current_scene) ---
static var _started := false
static var _finished := false
static var _games := 0            # trip games started in this run
static var _screens := 0          # screen visits
static var _force: Array = []     # game numbers (1-based, this run) that count as a loss
static var _stop_after := ""
static var _resume := false
static var _shoot := false
static var _shot_n := 0
static var _shot_count := {}      # screen name -> screenshots taken
static var _picked := false       # PICK_TEST done
static var _losses_forced := 0

var main                          # main.gd (Flow sets it)
var _screen := ""
var _frames := 0
var _idle := 0
var _over_seen := false
var _forcing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen = str(Flow.screen)
	if not _started:
		_started = true
		_parse_args()
		print("TRIP TEST start | save file %s | target %s | force loss %s | stop after %s | resume %s" % [
				Save.path(), _arg_after("--target", "-"), str(_force), _stop_after if _stop_after != "" else "-",
				"yes" if _resume else "no"])
		if _resume:
			if not Trip.continue_trip():
				_fail("--trip-resume: no trip save to load (%s)" % Save.last_error)
				return
			print("TRIP resume | %s" % _state())
			Flow.go(Trip.resume_screen())
			return
		Save.erase()   # a fresh trip every run (the test file only)
	if _screen == Flow.GAME:
		_start_game()
	else:
		_screens += 1
		if _screens > MAX_SCREENS:
			_fail("more than %d screen visits: a loop?" % MAX_SCREENS)
			return
		var built: String = "" if _script_exists(_screen) else " (not built yet)"
		var a: String = (" " + JSON.stringify(Flow.args)) if Flow.args.size() > 0 else ""
		print("TRIP screen %s%s%s | %s | %s" % [_screen, built, a, _state(), _save_check()])

func _parse_args() -> void:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	_resume = cmd.has("--trip-resume")
	_shoot = cmd.has("--screens")
	_stop_after = _arg_after("--trip-stop-after", "")
	var f: String = _arg_after("--trip-force-loss", "")
	for part in f.split(",", false):
		if part.is_valid_int():
			_force.append(int(part))

static func _arg_after(flag: String, def: String) -> String:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = cmd.find(flag)
	if i >= 0 and i + 1 < cmd.size():
		return cmd[i + 1]
	return def

static func _script_exists(scr: String) -> bool:
	var p: String = str(Flow.SCREENS.get(scr, ""))
	return p != "" and ResourceLoader.exists(p)

# ---------------- the loop ----------------

func _process(_delta: float) -> void:
	if _finished:
		return
	_frames += 1
	if _screen == Flow.GAME:
		_watch_game()
		return
	# end conditions are checked before any step (the title would start a new trip)
	if _screen == "title" and Trip.is_done():
		_end()
		return
	if _stop_after != "" and _screen == "map" and Trip.beaten.has(_stop_after) and Trip.city != _stop_after:
		var saved: Dictionary = Save.read()
		print("TRIP STOP after %s | %s | saved: city %s game %s phase %s" % [_stop_after, _state(),
				str(saved.get("city", "?")), str(saved.get("game", "?")), str(saved.get("phase", "?"))])
		_quit(0 if not saved.is_empty() else 1)
		return
	var wait: int = STEP_WAIT
	if _shoot and _shot_count.get(_screen, 0) < SHOTS_PER_SCREEN:
		wait = SHOT_WAIT + 4
		if _frames == SHOT_WAIT:
			_screenshot()
	if _frames < wait:
		return
	_frames = 0
	if _screen == "lineup" and PICK_TEST and not _picked and Trip.roster_ids().size() > Trip.STARTERS:
		_pick_test()
		return
	var done: bool = Flow.auto_step()
	if not done:
		done = _fallback()
	if done:
		_idle = 0
	else:
		_idle += wait
		if _idle >= STALL_FRAMES:
			_fail("stuck on screen %s (auto_step did nothing for %d frames)" % [_screen, STALL_FRAMES])

func _start_game() -> void:
	_games += 1
	if main != null:
		main.set("autoplay", true)   # both teams CPU (main.gd still sends the result to Flow under --trip-test)
	if _games > MAX_GAMES:
		_fail("more than %d trip games: a loop?" % MAX_GAMES)
		return
	_forcing = _force.has(_games)
	var m: Dictionary = Flow.match
	if not Flow.in_trip():
		_fail("a game started without a trip match (Flow.match is empty)")
		return
	var tm: Array = m.get("teams", [])
	var mine: Array = []
	var theirs: Array = []
	if tm.size() == 2:
		for p in (tm[0] as Dictionary).get("players", []):
			mine.append(str((p as Dictionary).get("id", "?")))
		for p in (tm[1] as Dictionary).get("players", []):
			theirs.append(str((p as Dictionary).get("id", "?")))
	print("TRIP game %d | %s | to %d%s | level %s | %s %s vs %s %s%s" % [_games, str(m.get("label", "")),
			int(m.get("target", 0)), (" (--target %s)" % _arg_after("--target", "")) if _arg_after("--target", "") != "" else "",
			str(m.get("level", "")), Cities.CREW_NAME, str(mine),
			str((tm[1] as Dictionary).get("name", "")) if tm.size() == 2 else "?", str(theirs),
			" | FORCED LOSS" if _forcing else ""])
	if mine.size() != Trip.STARTERS or theirs.size() != Trip.STARTERS:
		_fail("the match does not have 3 players a side")

func _watch_game() -> void:
	if main == null:
		return
	if _forcing and _frames == FORCE_LOSS_FRAMES and not bool(main.get("game_over")):
		var tg: int = int(main.rules.get("target"))
		main.score[0] = 0
		main.score[1] = tg
		_losses_forced += 1
		main.rules.call("_end_game", 1)   # the CPU crew "wins": the flow records a loss
	if bool(main.get("game_over")):
		if not _over_seen:
			_over_seen = true
			var secs: int = int(main.rules.get("play_time"))
			var sc: Array = main.score
			var st: Dictionary = main.stats
			print("TRIP result game %d | %s %d - %d | %s | length %d:%02d | shots %d | fouls %d" % [_games,
					"WON" if int(sc[0]) > int(sc[1]) else "LOST", int(sc[0]), int(sc[1]),
					"forced" if _forcing else "played", secs / 60, secs % 60, int(st.get("shots", 0)),
					int(st.get("fouls_t0", 0)) + int(st.get("fouls_t1", 0))])
		return
	if _frames > GAME_FRAMES:
		_fail("game %d did not end in %d frames" % [_games, GAME_FRAMES])

# ---------------- default choices for screens that are not built yet ----------------

# The "not built yet" panel continues by itself when it knows where to go (args.then). Otherwise the driver takes
# the screen's default choice through trip.gd, like the real screen's auto_step() would. True when it did something.
func _fallback() -> bool:
	if _script_exists(_screen):
		return false   # a real screen with nothing to do: that is a stall, not ours to fix
	match _screen:
		"title":
			Trip.new_trip(Trip.DEFAULT_LEVEL)
			Flow.go("story", {"scene": "trip_start", "then": "map"})
		"map":
			var c: String = Trip.city
			if Trip.phase != "map":
				Flow.go(Trip.resume_screen())
			else:
				var arrive: String = str(Cities.city(c).get("story", {}).get("arrive", ""))
				var then: String = "bracket" if Trip.is_tournament(c) else "lineup"
				if arrive != "" and Trip.mark_seen(arrive):
					Flow.go("story", {"scene": arrive, "then": then})
				else:
					Flow.go(then)
		"lineup":
			Trip.match_for()
			Flow.go(Flow.GAME)
		"result":
			var r: Dictionary = Trip.after_result()
			Flow.go(str(r.get("screen", "map")), r.get("args", {}))
		"points":
			var spent: Array = []
			var ids: Array = Trip.roster_ids()
			while Trip.points > 0 and ids.size() > 0:
				var id: String = str(ids[0])
				var stat: String = _lowest_stat(id)
				if stat == "" or not Trip.spend(id, stat):
					break
				spent.append("%s %s" % [id, stat])
			print("TRIP points spent: %s | left %d" % [str(spent), Trip.points])
			Trip.finish_points()
			Flow.go(Trip.resume_screen())
		"recruit":
			var cands: Array = Trip.recruit_candidates()
			if cands.is_empty():
				return false
			var rid: String = str((cands[0] as Dictionary).get("id", ""))
			print("TRIP recruit %s: %s" % [rid, "ok" if Trip.recruit(rid) else "FAILED"])
			Flow.go(Trip.resume_screen())
		"bracket":
			if Trip.is_done():
				Flow.go("title")
			else:
				Trip.match_for()
				Flow.go("lineup")
		"story":
			Flow.go(str(Flow.args.get("then", "map")), {})
		_:
			Flow.go("title")
	return true

# the stat of a roster player that is lowest and still below the cap ("" = all capped)
static func _lowest_stat(id: String) -> String:
	var p: Dictionary = Trip.roster_player(id)
	var best := ""
	var low: int = 1000
	for s in Ratings.STATS:
		var v: int = int((p.get("ratings", {}) as Dictionary).get(s, 0))
		if v < Trip.STAT_CAP and v < low:
			low = v
			best = s
	return best

# the lineup's tap path: bench everyone, then pick the newest recruit first (you play him), then two underdogs
func _pick_test() -> void:
	_picked = true
	var node: Node = Flow.current_screen()
	var ids: Array = Trip.roster_ids()
	var want: Array = [str(ids[ids.size() - 1]), str(ids[1]), str(ids[0])]
	if node == null or not node.has_method("tap_player"):
		print("TRIP lineup pick test skipped (no lineup screen)")
		Trip.set_starters(want, want[0])
		return
	for id in Trip.starters.duplicate():
		node.call("tap_player", str(id))   # tap a starter = bench him
	for id in want:
		node.call("tap_player", id)
	var ok: bool = Trip.starters == want and Trip.human == want[0]
	print("TRIP lineup picked by taps %s, you play %s: %s" % [str(Trip.starters), Trip.human,
			"ok" if ok else "WRONG (wanted %s)" % str(want)])
	if not ok:
		_fail("lineup taps did not set the starters")

# ---------------- prints ----------------

static func _state() -> String:
	return "city %s game %d phase %s | points %d | record %d-%d | roster %s | starters %s | beaten %s" % [
			Trip.city if Trip.city != "" else "-", Trip.game, Trip.phase, Trip.points, int(Trip.record.get("wins", 0)),
			int(Trip.record.get("losses", 0)), str(Trip.roster_ids()), str(Trip.starters), str(Trip.beaten)]

# the save on disk agrees with the trip in memory ("no trip" before one starts)
static func _save_check() -> String:
	if not Trip.active:
		return "no trip yet"
	var d: Dictionary = Save.read()
	if d.is_empty():
		return "saved: NONE (%s)" % Save.last_error
	var same: bool = str(d.get("city", "")) == Trip.city and int(d.get("game", 0)) == Trip.game \
			and str(d.get("phase", "")) == Trip.phase and int(d.get("points", -1)) == Trip.points \
			and (d.get("roster", []) as Array).size() == Trip.roster_ids().size()
	return "saved %s" % ("ok" if same else "DIFFERENT (disk: city %s game %s phase %s points %s)" % [
			str(d.get("city", "")), str(d.get("game", "")), str(d.get("phase", "")), str(d.get("points", ""))])

func _end() -> void:
	var ok: bool = Trip.beaten.has("new_york") and Trip.is_done()
	print("TRIP END | %s | games %d (forced losses %d) | screens %d | %s" % [_state(), _games, _losses_forced,
			_screens, "complete" if ok else "INCOMPLETE"])
	_quit(0 if ok else 1)

func _fail(why: String) -> void:
	print("TRIP ERROR: %s | %s" % [why, _state()])
	push_error("TRIP ERROR: " + why)
	_quit(1)

func _quit(code: int) -> void:
	_finished = true
	get_tree().quit(code)

func _screenshot() -> void:
	_shot_count[_screen] = int(_shot_count.get(_screen, 0)) + 1
	_shot_n += 1
	var path: String = SHOT_PATH % [_shot_n, _screen]
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		print("TRIP screenshot %s: no image (headless? run under xvfb)" % path)
		return
	img.save_png(path)
	print("TRIP screenshot %s" % path)
