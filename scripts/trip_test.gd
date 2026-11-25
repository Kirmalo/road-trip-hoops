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
#        --target 3 --screens      screenshots of every screen to /tmp/hoops_screen_NN_<screen>.png (each trip game
#                                  is then decided at once: won, or lost when forced; the screens are the point)
# Prints TRIP lines (screen, city, game, phase, points, record, roster, save check, each game's result) and ends with
# "TRIP END" (exit 0), "TRIP STOP" (exit 0) or "TRIP ERROR: <why>" (exit 1). Uses user://trip_test.json (save.gd).
# Phase 8 checks (P8-23), each with its own TRIP line, any broken one is a TRIP ERROR:
#   - after every trip game (the result screen): the game's stars (best = max(before, Stars.stars_for(level)) on a
#     win, unchanged on a loss), its key paid once with Trip.game_points() each (a loss or a replay pays nothing);
#     at TRIP END all 24 games paid and every game's best >= the level's stars, and the level is --difficulty's
#   - LOCKER: on the first title of a run (before NEW TRIP) the driver taps LOCKER; the locker's auto_step() must
#     land back on the title
#   - DRAFT: at the first lineup with an open star slot (Trip.open_slots(), e.g. --stars 12) and a draft pool, the
#     lineup's OPEN SLOT card (tap_open_slot()), then the draft screen's auto_step() signs the first card; back on
#     the lineup he must be on the roster as drafted (and in the save). TRIP END fails if slots were open but no one
#     was drafted
#   - REPLAY: on the first map once REPLAY_AFTER is beaten (between games), the driver opens that pin's picker
#     (open_picker) and presses its first PLAY; the replay plays like any game, then back on the map the trip must
#     not have moved (city, game, phase, bracket, record, points, paid, beaten and starters as before, marker gone).
#     Starters: the driver keeps the trip's starters in a replay (the lineup's auto_step keeps the picks; the pick
#     test and the draft never run on a replay's lineup), so they are part of the check. A real player may change
#     them in a replay's lineup (P8-20 allows it); this test does not cover that.
#     P9: before PLAY the driver taps another level in the picker than the trip's (the highest offered, or the
#     lowest when the trip is on it); the marker and the match must have that level, the result's stars are checked
#     at it, and Trip.level (part of the trip's progress) must not change.
#   With --mapshot the map drives its own replay: the driver then skips its replay but still checks the one played.
# Phase 9 checks (P9-29), only in a run whose first draft finds a legend in the pool (--legends-unlock-all, or legends
# unlocked in user://legends_test.json); without one every step above is exactly the Phase 8 driver:
#   - LEGEND DRAFT: that first open slot drafts the first legend of the DRAFT screen's LEGENDS row by its taps (his
#     card, whose hint must say Trip.LEGEND_RULE, then SIGN and YES, SIGN); back on the lineup he is on the roster as
#     drafted, the starters and Trip.human (the underdog you play) did not change. A second open slot (--stars 24)
#     drafts a second legend the same way (LEGEND_DRAFTS).
#   - ONE LEGEND: with two legends on the roster, the lineup's taps [you, legend 1] then legend 2 must be refused
#     (legend_in_the_way(), the LEGEND_RULE flash, Trip.starters_ok() says LEGEND_RULE); the picks are put back.
#     Also in a --trip-resume run that loads two legends.
#   - LEGEND + BOSS: the first recruit screen with a legend on the roster and no boss signs the city's boss (the card
#     tap); the next lineup after the pick test's game taps [Cities.START_CREW[0], legend, boss] and PLAYs: the game
#     and the save must start them, you play the underdog. They stay the starters from then on (the lineup's
#     auto_step keeps the picks). The driver never makes a legend YOU (checked at every tip-off; P10-B3: a
#     --trip-resume save whose YOU is a drafted legend plays him until the driver picks a lineup itself).
#   - TRIP END fails when a legend run missed one of these (the refusal only with 2+ slots and 2+ legends open).
#   The pick test's "newest recruit" is the newest roster player who joined as a recruit (never a drafted one).
# Phase 10 (P10-24), two eras in the draft (Trip.legends_rows(): one LEGENDS row per chapter, its "chapter" key):
#   - the first legend draft signs the first legend of the Fathers row (chapter "fathers"), the second one the first of
#     the Grandfathers row ("grand"), LEGEND_DRAFT_CHAPTERS; a chapter without a row then: the first legend offered.
#     The draft screen must show him in his own chapter's row.
#   - ONE LEGEND tries a Grandfather then a Father (when both are on the roster): refused, LEGEND_LIMIT counts every era
#   - LEGEND + BOSS starts the Father (when one is on the roster); TRIP END checks all three ("TRIP legend eras")
#   - P10-B1: a lineup visit that runs the pick test and then the first draft (a resumed trip with an open slot):
#     OPEN SLOT saves the tapped picks, so the starters and YOU the legend draft must keep are those picks
# Phase 11 (P11-24), three eras: LEGEND_DRAFT_CHAPTERS starts with "present", so the first legend draft signs a
#   Present legend (his chapter's row, scrolled to on the draft screen as a finger would), the second one of the next
#   era offered (the Fathers), a third slot (--stars 48+) the next (the Grandfathers). ONE LEGEND tries two legends of
#   different eras (the oldest era on the roster first), LEGEND + BOSS starts the first draft's era (the Present).
#   TRIP END ("TRIP legend eras") checks every built chapter with an open legend was offered a row (three with
#   --legends-unlock-all), the drafts followed LEGEND_DRAFT_CHAPTERS over the rows offered, each from another era.

const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Save = preload("res://scripts/save.gd")
const Cities = preload("res://scripts/cities.gd")
const Ratings = preload("res://scripts/ratings.gd")
const Stars = preload("res://scripts/stars.gd")    # P8-23: the stars each win records, the star slots

const STEP_WAIT := 12             # frames on a screen between auto_step() calls
const SHOT_WAIT := 40             # with --screens: frames before a screen's screenshot (layout and drawing settled)
const SHOTS_PER_SCREEN := 2       # screenshots per screen name (the map: van driving, then parked)
const SHOT_PATH := "/tmp/hoops_screen_%02d_%s.png"
const STALL_FRAMES := 1800        # a screen doing nothing this long (30 s) fails the test
const GAME_FRAMES := 60 * 60 * 45 # a trip game longer than 45 min (frames at 60 fps) fails the test
const FORCE_LOSS_FRAMES := 90     # a forced loss ends its game this many frames after tip-off
const MAX_GAMES := 400            # more trip games than this = a loop
const MAX_SCREENS := 3000         # more screen visits than this = a loop
const PICK_TEST := true           # on the first lineup with a recruit: pick [recruit, underdog 2, underdog 1] by taps
const LOCKER_TEST := true         # P8-23: visit the LOCKER from the first title of a run (back to the title)
const DRAFT_TEST := true          # P8-23: draft one player through the lineup's OPEN SLOT card at the first chance
const REPLAY_AFTER := "memphis"   # P8-23: replay this city's first won game from the map once it is beaten ("" = off)
const ALL_GAMES := 24             # games that pay at TRIP END (Stars.all_keys(): 8 cities x 3)
const MAPSHOT_FLAG := "--mapshot" # trip_map.gd's test: it drives its own replay on the first map
const LEGEND_DRAFTS := 3          # P9-29: legends a legend run drafts (one per open slot; the 2nd tests the refusal;
                                  # P11-24: up to one per era, a 3rd only with a 3rd slot open)
const LEGEND_DRAFT_CHAPTERS := ["present", "fathers", "grand"]   # P10-24 / P11-24: the chapter row each legend draft
                                  # picks from, in order (that row's first legend; a chapter without a row is skipped;
                                  # no row of these left: the first legend offered)

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
static var _pick_want: Array = [] # the lineup the pick test chose; the next game's team 0 must be it
static var _prev_screen := ""     # the screen (or "game") before this one
static var _locker_state := 0     # 0 not yet, 1 tapped (the locker must lead back to the title), 2 checked
static var _drafted := false      # the draft test ran (once per run)
static var _draft_before: Array = []   # drafted ids before the OPEN SLOT tap
static var _draft_wait := false        # OPEN SLOT tapped: the next screen after the draft is checked
static var _replay_state := 0     # 0 not yet, 1 picker opened by the driver, 2 PLAY pressed, 3 checked
static var _replay_snap := ""     # _progress() when the replay started ("" = no replay to check)
static var _replays := 0          # replays played and checked in this run
static var _game_key := ""        # the key (Stars.key) of the game being played
static var _game_city := ""
static var _game_n := 0
static var _game_replay := false
static var _game_level := ""      # P9: the level the game plays at (the trip's, a replay's own)
static var _star_before := 0      # that game's best stars before it
static var _paid_before := 0      # Trip.paid.size() before it
static var _star_checks := 0      # result screens checked
# P9-29: a drafted legend
static var _lg_mode := false      # the first draft of this run found a legend in the pool: the legend checks run
static var _lg_drafts := 0        # legends drafted by the driver in this run
static var _draft_pick := ""      # the legend the driver signs on the draft screen ("" = auto_step's first card)
static var _lg_keep := {}         # before a legend draft: {"human", "starters"} (they must not change)
static var _lg_refused := false   # ONE LEGEND checked
static var _lg_boss_recruit := "" # the boss the recruit screen signed for LEGEND + BOSS ("" = not yet, "-" = none)
static var _lg_boss_state := 0    # 0 not yet, 1 picked by taps (the next game checks), 2 played and checked
static var _draft_row_ch := ""    # P10-24: the chapter row the driver's legend pick must sit in on the draft screen
static var _lg_offered := {}      # P10-24: chapter -> true for every chapter row a legend draft was offered
static var _lg_chapters: Array = []   # P10-24: the chapter of each legend the driver drafted, in order
static var _lg_refused_eras: Array = []   # P10-24: the chapters of the two legends the refusal tried together
static var _lg_boss_ch := ""      # P10-24: the chapter of the legend who started next to the boss
static var _save_you := ""        # P10-B3: a --trip-resume save's YOU when he is a drafted legend ("" = none, or the
                                  # driver has picked a lineup since): the save's pick, not the driver's

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
		if _shoot:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)   # xvfb: don't wait for frames
		print("TRIP TEST start | save file %s | target %s | force loss %s | stop after %s | resume %s | level %s | stars %d (real %d), slots %d, legend %s" % [
				Save.path(), _arg_after("--target", "-"), str(_force), _stop_after if _stop_after != "" else "-",
				"yes" if _resume else "no", _level_want() if _level_want() != "" else "(saved)", Stars.total(),
				Stars.real_total(), Stars.slots(), "open" if Stars.legend_open() else "closed"])
		if _resume:
			if not Trip.continue_trip():
				_fail("--trip-resume: no trip save to load (%s)" % Save.last_error)
				return
			print("TRIP resume | %s" % _state())
			if Trip.is_legend(Trip.human):
				_save_you = Trip.human
				print("TRIP resume: the save's YOU is the drafted legend %s (the save's pick: allowed)" % _save_you)
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
		_on_arrive()
	_prev_screen = _screen

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
		if _shoot and _shot_count.get(_shot_key(), 0) < 1:
			if _frames == SHOT_WAIT:
				_screenshot("title_champions")
			if _frames < SHOT_WAIT + 4:
				return
		_end()
		return
	if _stop_after != "" and _screen == "map" and Trip.beaten.has(_stop_after) and Trip.city != _stop_after:
		var saved: Dictionary = Save.read()
		print("TRIP STOP after %s | %s | saved: city %s game %s phase %s" % [_stop_after, _state(),
				str(saved.get("city", "?")), str(saved.get("game", "?")), str(saved.get("phase", "?"))])
		_quit(0 if not saved.is_empty() else 1)
		return
	var wait: int = STEP_WAIT
	if _shoot and _shot_count.get(_shot_key(), 0) < SHOTS_PER_SCREEN:
		wait = SHOT_WAIT + 4
		if _frames == SHOT_WAIT:
			_screenshot()
	if _frames < wait:
		return
	_frames = 0
	if _screen == "lineup" and PICK_TEST and not _picked and not Trip.replaying() \
			and _newest_recruit() != "":
		_pick_test()
		return
	if _screen == "lineup" and DRAFT_TEST and _draft_due():
		_draft_test()
		return
	if _screen == "lineup" and _refusal_due():
		_legend_refusal_test()
		return
	if _screen == "lineup" and _legend_boss_due():
		_legend_boss_test()
		return
	if _screen == "draft" and _draft_pick != "" and not Trip.roster_ids().has(_draft_pick):
		_draft_pick_step()
		return
	if _screen == "recruit" and _boss_recruit_due():
		_boss_recruit_step()   # then auto_step below signs him
	if _screen == "title" and LOCKER_TEST and _locker_state == 0 and not Trip.is_done():
		_locker_test()
		return
	if _screen == "map" and _replay_wanted():
		_replay_step()
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
	if _pick_want.size() > 0:
		var same: bool = mine == _pick_want and Trip.starters == _pick_want and Trip.human == str(_pick_want[0]) \
				and str(Save.read().get("human", "")) == str(_pick_want[0])
		print("TRIP lineup in the game and the save: %s" % ("ok, you play " + str(mine[0]) if same else "WRONG"))
		if not same:
			_fail("the picked lineup is not the game's or the save's")
			return
		_pick_want = []
		if _lg_boss_state == 1:
			_lg_boss_state = 2
			_lg_boss_ch = Trip.LegendsData.chapter_of(str(mine[1]))
			print("TRIP legend + boss start: ok | %s (you), legend %s (chapter %s), boss %s" % [str(mine[0]),
					str(mine[1]), Trip.LegendsData.chapter_of(str(mine[1])), str(mine[2])])
	if mine.size() > 0 and Trip.is_legend(str(mine[0])) and str(mine[0]) == _save_you:
		print("TRIP game %d: you play the legend %s, the resumed save's pick (not the driver's): ok" % [_games,
				_save_you])
	elif mine.size() > 0 and Trip.is_legend(str(mine[0])):
		_fail("the driver made a legend YOU (%s): a legend run keeps you on a player you picked" % str(mine[0]))
		return
	if mine.size() != Trip.STARTERS or theirs.size() != Trip.STARTERS:
		_fail("the match does not have 3 players a side")
		return
	# P8-23: what this game's result must record (checked on the result screen)
	_game_replay = Trip.replaying()
	if _game_replay:
		_game_city = str(Trip.replay.get("city", ""))
		_game_n = int(Trip.replay.get("game", 1))
		if _replay_snap == "":
			_replay_snap = _progress()   # a replay the driver did not start (--mapshot)
	else:
		_game_city = Trip.city
		_game_n = Trip.bracket_round() + 1 if Trip.is_tournament(Trip.city) else Trip.game
	_game_key = Stars.key(_game_city, _game_n)
	_game_level = Trip.replay_level() if _game_replay else Trip.level
	if str(m.get("level", "")) != _game_level:
		_fail("the match plays %s, the %s is on %s" % [str(m.get("level", "")), "replay" if _game_replay else "trip",
				_game_level])
		return
	_star_before = Stars.best(_game_key)
	_paid_before = Trip.paid.size()

func _watch_game() -> void:
	if main == null:
		return
	if (_forcing or _shoot) and _frames == FORCE_LOSS_FRAMES and not bool(main.get("game_over")):
		# a forced loss: the CPU crew "wins"; under --screens every game is decided at once (the screens matter)
		var tg: int = int(main.rules.get("target"))
		var w: int = 1 if _forcing else 0
		main.score[w] = tg
		main.score[1 - w] = 0
		if _forcing:
			_losses_forced += 1
		main.rules.call("_end_game", w)
	if bool(main.get("game_over")):
		if not _over_seen:
			_over_seen = true
			var secs: int = int(main.rules.get("play_time"))
			var sc: Array = main.score
			var st: Dictionary = main.stats
			print("TRIP result game %d | %s %d - %d | %s | length %d:%02d | shots %d | fouls %d" % [_games,
					"WON" if int(sc[0]) > int(sc[1]) else "LOST", int(sc[0]), int(sc[1]),
					"forced" if _forcing else "decided (--screens)" if _shoot else "played", secs / 60, secs % 60, int(st.get("shots", 0)),
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

# the newest roster player who joined as a recruit ("" = none yet; a drafted player never counts, P9-29)
static func _newest_recruit() -> String:
	var out := ""
	for e in Trip.roster_data:
		if str((e as Dictionary).get("via", "")) == "recruit":
			out = str(e["id"])
	return out

# the lineup's tap path: bench everyone, then pick the newest recruit first (you play him), then two underdogs
func _pick_test() -> void:
	_picked = true
	var node: Node = Flow.current_screen()
	var ids: Array = Trip.roster_ids()
	var want: Array = [_newest_recruit(), str(ids[1]), str(ids[0])]
	if node == null or not node.has_method("tap_player"):
		print("TRIP lineup pick test skipped (no lineup screen)")
		Trip.set_starters(want, want[0])
		return
	for id in Trip.starters.duplicate():
		node.call("tap_player", str(id))   # tap a starter = bench him
	for id in want:
		node.call("tap_player", id)
	var got: Array = node.get("_picks")
	print("TRIP lineup picked by taps %s (you play %s): %s" % [str(got), str(got[0]) if got.size() > 0 else "-",
			"ok" if got == want else "WRONG (wanted %s)" % str(want)])
	if got != want:
		_fail("lineup taps did not pick %s" % str(want))
		return
	_pick_want = want   # PLAY saves them; the next game must use them (checked in _start_game)
	_save_you = ""      # the driver picked YOU from here on
	if _shoot:
		_screenshot("lineup_picked")

# ---------------- Phase 8 checks (P8-23) ----------------

# a new screen (not a game): the checks that look at where the last step led
func _on_arrive() -> void:
	if _locker_state == 1 and _prev_screen == "locker":
		_locker_state = 2
		print("TRIP locker back: %s" % ("ok, on the title" if _screen == "title" else "WRONG (on %s)" % _screen))
		if _screen != "title":
			_fail("the locker's auto_step did not go back to the title")
			return
	if _screen == "result":
		_check_result()
	if _draft_wait and _prev_screen == "draft":
		_check_draft()
	if _screen == "map" and _replay_snap != "" and not Trip.replaying() \
			and bool(Trip.last_outcome.get("replay", false)):
		_check_replay_back()

# the trip's progress, everything a replay must leave alone (the save is checked by _save_check)
static func _progress() -> String:
	return "city %s game %d phase %s bracket %d level %s | record %d-%d | points %d | paid %d | beaten %s | starters %s" % [
			Trip.city, Trip.game, Trip.phase, Trip.bracket_round(), Trip.level, int(Trip.record.get("wins", 0)),
			int(Trip.record.get("losses", 0)), Trip.points, Trip.paid.size(), str(Trip.beaten), str(Trip.starters)]

# the result screen: the game's stars and points as the rules say (Trip.last_outcome, recorded by flow.gd)
func _check_result() -> void:
	var o: Dictionary = Trip.last_outcome
	if _game_key == "":
		return   # no game of this run before this result
	_star_checks += 1
	var won: bool = bool(o.get("won", false))
	var per: int = Stars.stars_for(_game_level)
	var want_best: int = maxi(_star_before, per) if won else _star_before
	var now: int = Stars.best(_game_key)
	var errs: Array = []
	if str(o.get("star_key", "")) != _game_key:
		errs.append("outcome key %s, game %s" % [str(o.get("star_key", "")), _game_key])
	if bool(o.get("replay", false)) != _game_replay:
		errs.append("outcome replay %s" % str(o.get("replay", false)))
	if str(o.get("level", "")) != _game_level:
		errs.append("outcome level %s, the game was on %s" % [str(o.get("level", "")), _game_level])
	if now != want_best or int(o.get("stars_game", -1)) != want_best:
		errs.append("stars %d (outcome %s), want %d" % [now, str(o.get("stars_game", "?")), want_best])
	if int(o.get("stars_gained", -1)) != want_best - _star_before:
		errs.append("gained %s, want %d" % [str(o.get("stars_gained", "?")), want_best - _star_before])
	var each: int = int(o.get("points_each", -1))
	if won and not _game_replay:
		if not Trip.is_paid(_game_key) or Trip.paid.size() != _paid_before + 1:
			errs.append("not paid once (paid %d -> %d)" % [_paid_before, Trip.paid.size()])
		if each != Trip.game_points(_game_city, _game_n):
			errs.append("points each %d, want %d" % [each, Trip.game_points(_game_city, _game_n)])
	elif Trip.paid.size() != _paid_before or each != 0:
		errs.append("paid %d -> %d, points each %d (a %s pays nothing)" % [_paid_before, Trip.paid.size(), each,
				"replay" if _game_replay else "loss"])
	print("TRIP stars %s%s %s | level %s (%d a win) | best %d -> %d (+%s) | points each %d | paid %d/%d | %s" % [
			_game_key, " (replay)" if _game_replay else "", "won" if won else "lost",
			_game_level + ((" (trip %s)" % Trip.level) if _game_level != Trip.level else ""), per, _star_before,
			now, str(o.get("stars_gained", "?")), each, Trip.paid.size(), ALL_GAMES,
			"ok" if errs.is_empty() else "WRONG: " + "; ".join(PackedStringArray(errs))])
	var k: String = _game_key
	_game_key = ""
	if not errs.is_empty():
		_fail("the result of %s did not record its stars / points right" % k)

# LOCKER from the title (the title's own button), then the locker's auto_step() must bring us back
func _locker_test() -> void:
	_locker_state = 1
	var node: Node = Flow.current_screen()
	if node == null:
		_fail("no title screen to tap LOCKER on")
		return
	node.set("_arm_t", 0.0)
	var tapped := false
	var btns = node.get("_buttons")
	if btns is Array:
		for b in btns:
			if b is Button and is_instance_valid(b) and (b as Button).text == "LOCKER":   # (greyed while armed)
				(b as Button).pressed.emit()
				tapped = true
				break
	print("TRIP locker: %s | stars %d (real %d) | slots %d" % ["tapped LOCKER on the title" if tapped else "NO BUTTON",
			Stars.total(), Stars.real_total(), Stars.slots()])
	if not tapped:
		_fail("the title has no LOCKER button")

# the lineup's OPEN SLOT card -> the draft screen (its auto_step signs the first card) -> back to the lineup
func _draft_test() -> void:
	if not _drafted:
		_lg_mode = not _legend_pool().is_empty()   # P9-29: legends in the first draft's pool = a legend run
	_drafted = true
	var node: Node = Flow.current_screen()
	if node == null or not node.has_method("tap_open_slot"):
		_fail("the lineup has no OPEN SLOT tap (tap_open_slot)")
		return
	_draft_before = Trip.drafted_ids()
	_draft_pick = ""
	_draft_row_ch = ""
	if _lg_mode:
		var offered: Array = _offered_chapters()
		var want_ch: String = _want_chapter(offered)
		var pick: Dictionary = _legend_pick(want_ch)
		_draft_pick = str(pick.get("id", ""))
		_draft_row_ch = str(pick.get("chapter", ""))
		# P10-B1: OPEN SLOT saves the lineup's picks first (a pick test on this same visit may have changed them), so
		# the starters and YOU that must survive the draft are the picks it saves, not Trip.starters before the tap
		var keep_st: Array = Trip.starters.duplicate()
		var picks = node.get("_picks")
		if picks is Array and (picks as Array).size() == Trip.STARTERS and bool(node.call("lineup_ok")):
			keep_st = (picks as Array).duplicate()
		var keep_you: String = str(keep_st[0]) if keep_st.size() > 0 else Trip.human
		_lg_keep = {"human": keep_you, "starters": keep_st}
		print("TRIP legend draft %d: %s from the LEGENDS row of chapter %s (wanted %s; rows offered %s) | you play %s | starters %s" % [
				_lg_drafts + 1, _draft_pick, _draft_row_ch, want_ch if want_ch != "" else "-", str(offered), keep_you,
				str(keep_st)])
		if _draft_pick == "" or (want_ch != "" and offered.has(want_ch) and _draft_row_ch != want_ch):
			_fail("legend draft %d: the %s row was offered but the pick '%s' is from '%s'" % [_lg_drafts + 1, want_ch,
					_draft_pick, _draft_row_ch])
			return
	print("TRIP draft: OPEN SLOT tapped | slots %d, open %d | pool %d players | drafted before %s" % [
			Trip.slot_count(), Trip.open_slots(), Trip.draft_pool().size(), str(_draft_before)])
	_draft_wait = true
	if not bool(node.call("tap_open_slot")):
		_fail("the lineup's OPEN SLOT tap did nothing (open slots %d)" % Trip.open_slots())

func _check_draft() -> void:
	_draft_wait = false
	var now: Array = Trip.drafted_ids()
	var added: Array = []
	for id in now:
		if not _draft_before.has(id):
			added.append(str(id))
	var saved := 0
	for e in Save.read().get("roster", []):
		if e is Dictionary and str((e as Dictionary).get("via", "")) == Trip.DRAFT_VIA:
			saved += 1
	var ok: bool = added.size() == 1 and Trip.roster_ids().has(added[0]) and saved == now.size() \
			and _screen == "lineup"
	print("TRIP draft %s | back on %s | roster %s | open slots %d | in the save %d | %s" % [str(added), _screen,
			str(Trip.roster_ids()), Trip.open_slots(), saved, "ok" if ok else "WRONG"])
	if not ok:
		_fail("the draft did not add exactly one player (saved) and come back to the lineup")
		return
	if _draft_pick == "":
		return
	# P9-29: the legend, drafted to the bench; nobody starts or plays differently because of it
	var want: String = _draft_pick
	_draft_pick = ""
	var lg_ok: bool = added[0] == want and Trip.is_legend(want) and not Trip.is_boss(want) \
			and Trip.human == str(_lg_keep.get("human", "")) and Trip.starters == _lg_keep.get("starters", []) \
			and not Trip.is_legend(Trip.human) and str(Save.read().get("human", "")) == Trip.human
	print("TRIP legend drafted %s | legend %s, boss %s | you still play %s | starters %s | %s" % [str(added[0]),
			str(Trip.is_legend(str(added[0]))), str(Trip.is_boss(str(added[0]))), Trip.human, str(Trip.starters),
			"ok" if lg_ok else "WRONG (wanted %s, you %s, starters %s)" % [want, str(_lg_keep.get("human", "")),
			str(_lg_keep.get("starters", []))]])
	if not lg_ok:
		_fail("the legend draft did not sign %s to the bench (or it changed the starters or who you play)" % want)
		return
	_lg_drafts += 1
	_lg_chapters.append(Trip.LegendsData.chapter_of(want))

# ---------------- Phase 9 checks (P9-29): a drafted legend ----------------

# the legends the draft offers now (pool order)
static func _legend_pool() -> Array:
	var out: Array = []
	for p in Trip.draft_pool():
		if bool((p as Dictionary).get("legend", false)):
			out.append(str((p as Dictionary).get("id", "")))
	return out

# P10-24: the chapters of the draft's LEGENDS rows now (Trip.legends_rows(): one row per chapter, its "chapter")
static func _offered_chapters() -> Array:
	var out: Array = []
	for row in Trip.legends_rows():
		var ch: String = str((row as Dictionary).get("chapter", ""))
		if not out.has(ch) and ((row as Dictionary).get("players", []) as Array).size() > 0:
			out.append(ch)
			_lg_offered[ch] = true
	return out

# P11-24: the chapter the next legend draft picks from: the first of LEGEND_DRAFT_CHAPTERS with a row offered and
# no legend drafted from it yet ("" = none left: the first legend offered)
static func _want_chapter(offered: Array) -> String:
	for ch in LEGEND_DRAFT_CHAPTERS:
		if offered.has(str(ch)) and not _lg_chapters.has(str(ch)):
			return str(ch)
	return ""

# P11-24: the drafts a legend run should make, in order: LEGEND_DRAFT_CHAPTERS over the rows offered
static func _want_chapters() -> Array:
	var out: Array = []
	for ch in LEGEND_DRAFT_CHAPTERS:
		if _lg_offered.has(str(ch)):
			out.append(str(ch))
	return out

# P10-24: the first legend of the LEGENDS row whose "chapter" is ch, else the first legend of the first row:
# {"id", "chapter"} ({} = no legend offered)
static func _legend_pick(ch: String) -> Dictionary:
	var rows: Array = Trip.legends_rows()
	for row in rows:
		var pl: Array = (row as Dictionary).get("players", [])
		if str((row as Dictionary).get("chapter", "")) == ch and pl.size() > 0:
			return {"id": str((pl[0] as Dictionary).get("id", "")), "chapter": ch}
	for row in rows:
		var pl: Array = (row as Dictionary).get("players", [])
		if pl.size() > 0:
			return {"id": str((pl[0] as Dictionary).get("id", "")), "chapter": str((row as Dictionary).get("chapter", ""))}
	return {}

# the legends on the roster (roster order)
static func _roster_legends() -> Array:
	var out: Array = []
	for id in Trip.roster_ids():
		if Trip.is_legend(str(id)):
			out.append(str(id))
	return out

# a boss on the roster ("" = none)
static func _roster_boss() -> String:
	for id in Trip.roster_ids():
		if Trip.is_boss(str(id)):
			return str(id)
	return ""

static var _draft_chance := false   # P9-B1: set once a lineup offered a draft (a finished trip resumed never does)

# the first draft of the run (as in Phase 8), then in a legend run one more legend per open slot (LEGEND_DRAFTS)
static func _draft_due() -> bool:
	if Trip.replaying() or Trip.open_slots() <= 0 or Trip.draft_pool().is_empty() or _draft_wait:
		return false
	_draft_chance = true   # P9-B1: a lineup gave the driver its chance to draft
	if not _drafted:
		return true
	return _lg_mode and _lg_drafts < LEGEND_DRAFTS and not _legend_pool().is_empty()

# the draft screen while the driver signs a legend: his card (the hint must say the one-legend rule), SIGN, YES, SIGN
func _draft_pick_step() -> void:
	var node: Node = Flow.current_screen()
	if node == null or not node.has_method("tap_player"):
		_fail("the draft screen has no tap_player")
		return
	if bool(node.get("_busy")):
		return
	if not bool(node.call("tap_player", _draft_pick)):
		_fail("the draft screen has no card for %s (the LEGENDS row)" % _draft_pick)
		return
	# P10-24: his card sits in his chapter's LEGENDS row on the screen (the row's "chapter")
	var row_ch := "?"
	var row_i := -1
	var crews = node.get("_crews")
	if crews is Array:
		for i in (crews as Array).size():
			var row: Dictionary = (crews as Array)[i]
			for pl in row.get("players", []):
				if str((pl as Dictionary).get("id", "")) == _draft_pick:
					row_ch = str(row.get("chapter", "-"))
					row_i = i
	# P11-24: scroll the list to his row first, as a finger would (three LEGENDS rows sit low in the list)
	var scrolled: bool = row_i >= 0 and node.has_method("scroll_to_row") and bool(node.call("scroll_to_row", row_i))
	print("TRIP draft scrolled to row %d (%s): %s" % [row_i, row_ch, "ok" if scrolled else "NO"])
	if not scrolled:
		_fail("the draft screen did not scroll to the row of %s (row %d)" % [_draft_pick, row_i])
		return
	var his_ch: String = Trip.LegendsData.chapter_of(_draft_pick)
	print("TRIP draft row of %s on the screen: chapter %s (his %s, wanted %s)" % [_draft_pick, row_ch, his_ch,
			_draft_row_ch])
	if row_ch != _draft_row_ch or row_ch != his_ch:
		_fail("the draft screen shows %s in the '%s' row, not his chapter's (%s)" % [_draft_pick, row_ch, his_ch])
		return
	var hl = node.get("_hint")
	var hint: String = (hl as Label).text if hl is Label else ""
	var says: bool = hint.contains(Trip.LEGEND_RULE)
	print("TRIP draft card %s tapped | hint \"%s\" | %s" % [_draft_pick, hint,
			"ok, the one-legend rule" if says else "WRONG (no %s)" % Trip.LEGEND_RULE])
	if not says:
		_fail("picking legend %s on the draft did not say %s" % [_draft_pick, Trip.LEGEND_RULE])
		return
	node.set("_sign_arm_t", 0.0)
	node.call("_on_sign")
	if node.get("_confirm") == null:
		_fail("SIGN on legend %s did not open the confirm panel" % _draft_pick)
		return
	node.set("_confirm_t", 0.0)
	node.call("_on_yes")
	if not Trip.roster_ids().has(_draft_pick):
		_fail("YES, SIGN did not draft legend %s (%s)" % [_draft_pick, Trip.draft_refusal(_draft_pick)])
		return
	print("TRIP draft signed %s by SIGN and YES, SIGN" % _draft_pick)

# ONE LEGEND: with 2 legends on the roster (between games, once; also in a --trip-resume run that loaded them)
func _refusal_due() -> bool:
	return not _lg_refused and not Trip.replaying() and _pick_want.is_empty() \
			and _roster_legends().size() >= 2

func _legend_refusal_test() -> void:
	_lg_refused = true
	var node: Node = Flow.current_screen()
	if node == null or not node.has_method("legend_in_the_way"):
		_fail("the lineup has no legend_in_the_way (P9-22)")
		return
	var lgs: Array = _roster_legends()
	var l1: String = str(lgs[0])
	var l2: String = str(lgs[1])
	# P10-24 / P11-24: with legends of two eras on the roster, the oldest era's first, then one of another era
	# (LEGEND_LIMIT counts all chapters)
	var found := false
	for ch in Trip.LegendsData.built_chapters():
		for id in lgs:
			if Trip.LegendsData.chapter_of(str(id)) == str(ch):
				l1 = str(id)
				found = true
				break
		if found:
			break
	for id in lgs:
		if str(id) != l1 and Trip.LegendsData.chapter_of(str(id)) != Trip.LegendsData.chapter_of(l1):
			l2 = str(id)
			break
	if l2 == l1:
		l2 = str(lgs[1]) if str(lgs[0]) == l1 else str(lgs[0])
	_lg_refused_eras = [Trip.LegendsData.chapter_of(l1), Trip.LegendsData.chapter_of(l2)]
	print("TRIP one legend: %s (chapter %s) then %s (chapter %s)" % [l1, _lg_refused_eras[0], l2, _lg_refused_eras[1]])
	var orig: Array = (node.get("_picks") as Array).duplicate()
	if orig.size() != Trip.STARTERS or Trip.is_legend(str(orig[0])):
		_fail("the lineup's picks %s are not 3 with a non-legend YOU" % str(orig))
		return
	var me: String = str(orig[0])
	for id in orig:
		if str(id) != me:
			node.call("tap_player", str(id))   # bench the other two
	node.call("tap_player", l1)
	var before: Array = (node.get("_picks") as Array).duplicate()
	node.call("tap_player", l2)            # must be refused
	var after: Array = (node.get("_picks") as Array).duplicate()
	var hl = node.get("_hint")
	var hint: String = (hl as Label).text if hl is Label else ""
	var why: String = Trip.starters_ok([me, l1, l2])
	var ok: bool = before == [me, l1] and after == before and str(node.call("legend_in_the_way", l2)) == l1 \
			and hint.contains(Trip.LEGEND_RULE) and why == Trip.LEGEND_RULE
	# put the picks back: bench legend 1, pick the other two again
	node.call("tap_player", l1)
	for id in orig:
		if str(id) != me:
			node.call("tap_player", str(id))
	var back: Array = (node.get("_picks") as Array).duplicate()
	ok = ok and back == orig
	print("TRIP one legend: picks %s, tap %s -> %s | hint \"%s\" | starters_ok %s | picks back %s | %s" % [
			str(before), l2, "refused" if after == before else "TAKEN " + str(after), hint,
			why if why != "" else "\"\" (allowed)", str(back), "ok" if ok else "WRONG"])
	if not ok:
		_fail("the lineup did not refuse a second legend (%s next to %s)" % [l2, l1])

# LEGEND + BOSS: the first recruit screen with a legend on the roster and no boss signs the city's boss
func _boss_recruit_due() -> bool:
	return _lg_boss_recruit == "" and not _roster_legends().is_empty() and _roster_boss() == ""

func _boss_recruit_step() -> void:
	var node: Node = Flow.current_screen()
	if node == null or bool(node.get("_busy")):
		return
	var cands = node.get("_cands")
	if not (cands is Array):
		return
	for i in (cands as Array).size():
		var id: String = str(((cands as Array)[i] as Dictionary).get("id", ""))
		if Trip.is_boss(id):
			node.set("_arm_t", 0.0)
			node.call("_on_card", i)   # the card's tap
			_lg_boss_recruit = id
			print("TRIP recruit: tapped the boss %s (for the legend + boss lineup)" % id)
			return
	_lg_boss_recruit = "-"   # no boss on this recruit screen: auto_step's first card, no second try
	print("TRIP recruit: no boss among %d candidates" % (cands as Array).size())

# the lineup after the pick test's game, with a legend and a boss on the roster (once, between games)
func _legend_boss_due() -> bool:
	return _lg_boss_state == 0 and not Trip.replaying() and _pick_want.is_empty() and (_picked or not PICK_TEST) \
			and not _roster_legends().is_empty() and _roster_boss() != "" \
			and Trip.roster_ids().has(str(Cities.START_CREW[0]))

func _legend_boss_test() -> void:
	var node: Node = Flow.current_screen()
	if node == null or not node.has_method("tap_player"):
		_fail("no lineup screen for the legend + boss lineup")
		return
	var lgs: Array = _roster_legends()
	var lg: String = str(lgs[0])
	# P10-24 / P11-24: the first draft's era (a Present legend) when one is on the roster
	var want_eras: Array = _want_chapters()
	var first_ch: String = str(_lg_chapters[0]) if not _lg_chapters.is_empty() else \
			(str(want_eras[0]) if not want_eras.is_empty() else "")
	for id in lgs:
		if Trip.LegendsData.chapter_of(str(id)) == first_ch:
			lg = str(id)
			break
	var want: Array = [str(Cities.START_CREW[0]), lg, _roster_boss()]
	for id in (node.get("_picks") as Array).duplicate():
		node.call("tap_player", str(id))   # bench everyone
	for id in want:
		node.call("tap_player", id)
	var got: Array = (node.get("_picks") as Array).duplicate()
	var why: String = Trip.starters_ok(want)
	var ok: bool = got == want and bool(node.call("lineup_ok")) and why == ""
	print("TRIP legend + boss picked by taps %s (you play %s) | starters_ok \"%s\" | %s" % [str(got),
			str(got[0]) if got.size() > 0 else "-", why, "ok" if ok else "WRONG (wanted %s)" % str(want)])
	if not ok:
		_fail("the lineup did not accept a legend and a boss together (%s)" % str(want))
		return
	_lg_boss_state = 1
	_pick_want = want   # PLAY saves them; the next game must start them (checked in _start_game)
	_save_you = ""      # the driver picked YOU from here on

# the map: replay REPLAY_AFTER's first won game once, between games (not when --mapshot drives the map)
func _replay_wanted() -> bool:
	if REPLAY_AFTER == "" or _replay_state >= 2 or Trip.is_done() or Trip.phase != "map" or Trip.replaying():
		return false
	if OS.get_cmdline_user_args().has(MAPSHOT_FLAG) or not Trip.beaten.has(REPLAY_AFTER):
		return false
	for n in range(1, Trip.GAMES_PER_CITY + 1):
		if Trip.can_replay(REPLAY_AFTER, n):
			return true
	return false

func _replay_step() -> void:
	var node: Node = Flow.current_screen()
	if node == null or not node.has_method("open_picker"):
		_fail("the map has no replay picker (open_picker)")
		return
	if float(node.get("_drive_t")) >= 0.0:
		node.call("_end_drive")   # the van parks first, as auto_step would
		return
	if _replay_state == 0 or node.get("_picker") == null:
		_replay_state = 1
		node.call("open_picker", REPLAY_AFTER)   # what a tap on the pin does (prints MAP PICKER)
		return
	var btns = node.get("_play_btns")
	if not (btns is Dictionary) or (btns as Dictionary).is_empty():
		_fail("the %s picker has no PLAY button" % REPLAY_AFTER)
		return
	var n: int = int((btns as Dictionary).keys()[0])
	# P9: the picker opens on the trip's level; tap another one (a level button, as a finger would)
	var opened: String = str(node.call("replay_level"))
	var lv: String = str(node.call("other_level", opened))
	var lbtns = node.get("_level_btns")
	if opened != str(node.call("start_level")) or not (lbtns is Dictionary) or not (lbtns as Dictionary).has(lv) \
			or lv == opened:
		_fail("the %s picker's level row: opened on %s (trip %s), no other level button (%s)" % [REPLAY_AFTER, opened,
				Trip.level, str(lbtns.keys()) if lbtns is Dictionary else "none"])
		return
	node.set("_arm_t", 0.0)
	((lbtns as Dictionary)[lv] as Button).pressed.emit()
	if str(node.call("replay_level")) != lv:
		_fail("the %s level button did not pick %s (picked %s)" % [REPLAY_AFTER, lv, str(node.call("replay_level"))])
		return
	_replay_snap = _progress()
	_replay_state = 2
	print("TRIP replay: PLAY %s at %s from the map's picker (opened on %s, trip %s) | before: %s" % [
			Stars.key(REPLAY_AFTER, n), lv, opened, Trip.level, _replay_snap])
	node.set("_arm_t", 0.0)
	((btns as Dictionary)[n] as Button).pressed.emit()
	if not Trip.replaying() or str(Trip.replay.get("city", "")) != REPLAY_AFTER or int(Trip.replay.get("game", 0)) != n:
		_fail("PLAY did not start the replay of %s (marker %s)" % [Stars.key(REPLAY_AFTER, n), str(Trip.replay)])
		return
	if Trip.replay_level() != lv or str(Save.read().get("replay", {}).get("level", "")) != lv:
		_fail("the replay marker plays %s (saved %s), the picker asked for %s" % [Trip.replay_level(),
				str(Save.read().get("replay", {}).get("level", "")), lv])

# back on the map after a replay's result: the trip did not move, the marker is gone, the save agrees
func _check_replay_back() -> void:
	var now: String = _progress()
	var sc: String = _save_check()
	var ok: bool = now == _replay_snap and not Trip.replaying() and sc == "saved ok"
	print("TRIP replay back on the map | %s %s at %s (trip level %s) | trip %s | %s" % [
			str(Trip.last_outcome.get("star_key", "?")), "won" if bool(Trip.last_outcome.get("won", false)) else "lost",
			str(Trip.last_outcome.get("level", "?")), Trip.level,
			"unchanged" if now == _replay_snap else "MOVED (now: %s)" % now, sc])
	_replay_snap = ""
	_replay_state = 3
	_replays += 1
	if not ok:
		_fail("the replay moved the trip (or left its marker / a different save)")

# the level this run asked for ("" = none): --difficulty's; LEGEND needs the stars open, else the game plays hard
static func _level_want() -> String:
	var v: String = _arg_after("--difficulty", "")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--difficulty="):
			v = a.get_slice("=", 1)
	v = v.strip_edges().to_lower()
	if not Trip.LEVELS.has(v):
		return ""
	if v == "legend" and not Stars.legend_open():
		return "hard"
	return v

# TRIP END: every game paid, every game's stars at least the level's, the level asked for, the draft and the replay
# checked when they had their chance. False (after TRIP ERROR) when one fails.
func _end_checks() -> bool:
	var per: int = Stars.stars_for(Trip.level)
	var unpaid: Array = []
	var low: Array = []
	for k in Stars.all_keys():
		if not Trip.is_paid(str(k)):
			unpaid.append(str(k))
		if Stars.best(str(k)) < per:
			low.append(str(k))
	print("TRIP stars at the end | level %s (%d a win) | paid %d/%d%s | every game >= %d stars: %s | total %d (real %d)"
			% [Trip.level, per, Trip.paid.size(), ALL_GAMES, (" missing " + str(unpaid)) if unpaid.size() > 0 else "",
			per, "ok" if low.is_empty() else "NO " + str(low), Stars.total(), Stars.real_total()])
	if Trip.paid.size() != ALL_GAMES or unpaid.size() > 0 or low.size() > 0:
		_fail("the finished trip did not pay all %d games or record their stars" % ALL_GAMES)
		return false
	var want: String = _level_want()
	if want != "" and Trip.level != want:
		_fail("the trip played %s, --difficulty asked for %s" % [Trip.level, want])
		return false
	print("TRIP draft at the end | slots %d | drafted %s | %s" % [Trip.slot_count(), str(Trip.drafted_ids()),
			"ok" if Trip.slot_count() == 0 or Trip.drafted_ids().size() > 0 else "NO DRAFT"])
	if DRAFT_TEST and _draft_chance and Trip.slot_count() > 0 and Trip.drafted_ids().is_empty():
		_fail("star slots were open but no one was drafted")
		return false
	if _replay_state == 1 or _replay_state == 2 or _replay_snap != "":
		_fail("a replay was started but never checked back on the map")
		return false
	if not _legend_end_checks():
		return false
	print("TRIP checks | replays %d | locker %s | draft %s" % [_replays,
			"ok" if _locker_state == 2 else "not visited (no fresh title in this run)",
			"done in this run" if _drafted else "not in this run"])
	return true

# P9-29: a legend run drafted its legend(s), refused a second starting legend (with 2+ slots and 2+ legends open) and
# started a legend next to a boss. A run without legends in its first draft checks nothing here.
func _legend_end_checks() -> bool:
	var open_legends := 0
	for id in Trip.LegendsData.legend_ids():
		if Trip.legend_available(str(id)):
			open_legends += 1
	var need_refusal: bool = Trip.slot_count() >= 2 and open_legends >= 2
	var miss: String = "NOT CHECKED" if _lg_mode else "-"
	print("TRIP legends at the end | %s | open legends %d | drafted by the driver %d | roster legends %s | one legend %s | legend + boss %s" % [
			"legend run" if _lg_mode else "no legend drafted in this run", open_legends, _lg_drafts,
			str(_roster_legends()), "ok" if _lg_refused else (miss if need_refusal else "- (needs 2 slots and 2 legends)"),
			"ok" if _lg_boss_state == 2 else miss])
	if not _lg_mode:
		return true
	if _lg_drafts == 0:
		_fail("a legend run drafted no legend")
		return false
	if need_refusal and not _lg_refused:
		_fail("2 slots and 2 legends were open but the lineup's one-legend refusal was never checked")
		return false
	if _lg_boss_state != 2:
		_fail("a legend run never started a legend next to a boss")
		return false
	# P10-24 / P11-24: the eras. Every built chapter with an open legend had a row; the drafts followed
	# LEGEND_DRAFT_CHAPTERS over the rows offered (each from another era); with two eras on the roster the refusal tried
	# one of each; the legend who started next to the boss is from the first draft's era
	var rows_want: Array = []
	for ch in Trip.LegendsData.built_chapters():
		for id in Trip.LegendsData.legend_ids():
			if Trip.LegendsData.chapter_of(str(id)) == str(ch) and Trip.legend_available(str(id)):
				rows_want.append(str(ch))
				break
	var seq: Array = _want_chapters()
	var why_not := ""
	for ch in rows_want:
		if not _lg_offered.has(ch):
			why_not = "no %s row offered" % ch
	for k in _lg_chapters.size():
		if k < seq.size() and str(_lg_chapters[k]) != str(seq[k]):
			why_not = "draft %d from %s, wanted %s" % [k + 1, str(_lg_chapters[k]), str(seq[k])]
	var eras_seen: Dictionary = {}
	for ch in _lg_chapters:
		eras_seen[str(ch)] = true
	if eras_seen.size() != _lg_chapters.size() and _lg_chapters.size() <= seq.size():
		why_not = "two drafts from one era %s" % str(_lg_chapters)
	if eras_seen.size() >= 2 and _lg_refused and (_lg_refused_eras.size() != 2 \
			or str(_lg_refused_eras[0]) == str(_lg_refused_eras[1])):
		why_not = "the refusal tried one era twice %s" % str(_lg_refused_eras)
	if not _lg_chapters.is_empty() and _lg_boss_ch != str(_lg_chapters[0]):
		why_not = "legend + boss started %s, not the first draft's era %s" % [_lg_boss_ch, str(_lg_chapters[0])]
	var eras_ok: bool = why_not == ""
	print("TRIP legend eras at the end | rows offered %s (built with open legends %s) | drafted %s (wanted %s) | one legend tried %s | legend + boss %s | %s" % [
			str(_lg_offered.keys()), str(rows_want), str(_lg_chapters), str(seq), str(_lg_refused_eras),
			_lg_boss_ch if _lg_boss_ch != "" else "-", "ok" if eras_ok else "WRONG (%s)" % why_not])
	if not eras_ok:
		_fail("the legend run did not draft / refuse / start the eras as P10-24 / P11-24 ask: %s" % why_not)
		return false
	return true

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
	if ok and not _end_checks():
		return
	print("TRIP END | %s | games %d (forced losses %d) | screens %d | results checked %d | replays %d | %s" % [
			_state(), _games, _losses_forced, _screens, _star_checks, _replays, "complete" if ok else "INCOMPLETE"])
	_quit(0 if ok else 1)

func _fail(why: String) -> void:
	print("TRIP ERROR: %s | %s" % [why, _state()])
	push_error("TRIP ERROR: " + why)
	_quit(1)

func _quit(code: int) -> void:
	_finished = true
	get_tree().quit(code)

# screenshots are counted per screen, per story scene (every scene and the ending get theirs) and for the finished
# trip's title (CHAMPIONS); the lineup once per city
func _shot_key() -> String:
	if _screen == "story":
		return "story:" + str(Flow.args.get("scene", ""))
	if _screen == "title" and Trip.is_done():
		return "title_done"
	if _screen == "lineup":
		return "lineup:" + str(Trip.city)
	return _screen

func _screenshot(tag: String = "") -> void:
	var key: String = _shot_key()
	_shot_count[key] = int(_shot_count.get(key, 0)) + 1
	_shot_n += 1
	var path: String = SHOT_PATH % [_shot_n, tag if tag != "" else _screen]
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		print("TRIP screenshot %s: no image (headless? run under xvfb)" % path)
		return
	img.save_png(path)
	print("TRIP screenshot %s" % path)
