extends Node
# Legends test driver (P9-25; every built chapter P10-09). Flow adds one to every scene under -- --legends-test
# (Flow.attach_test: screens and games, like trip_test.gd), so the driver lives in static vars across the reloads. It
# plays every built chapter headless, in data order:
#   title -> LEGENDS -> timeline -> the chapter's intro scene -> chapter view -> 6 challenges (each unlock scene) ->
#   the finale (its "before" and "after" scenes) -> one replay (best tokens kept) -> HALL and back -> BACK to the
#   timeline (the chapter is done; the next chapter's gate is checked against the data: open by its stars or tokens,
#   locked, or not built) -> the next chapter from its timeline panel while it is open -> ... -> BACK to the title ->
#   LEGENDS END
# On today's data (Chapters 1-2 built) that is the Phase 10 run: two chapters, then the "LEGENDS gate" line of the
# Present (not built). Once its row is built (P11-11) the same run plays it too, when its gate is open by then.
# On a screen it calls the screen's auto_step() (the default choice) every STEP_WAIT frames; on the title it taps
# LEGENDS, on the chapter view it picks the run's level first (set_level), and taps HALL / BACK at the end.
# Every game is decided at once (FORCE_FRAMES after tip-off), so the run is fast and deterministic:
#   win      your side reaches the target with the goal met (a "stop" challenge gets its stops)
#   loss     --legends-force-loss N: the Nth legends game of this run is lost by the score (then retried)
#   broken   GOAL_TESTS: the first try of the first "hold" challenge, the legend scores his limit (challenge.check()
#            ends the game at once as a broken goal, "CHALLENGE FAILED: ... SCORED n"); retried
#   short    GOAL_TESTS: the first try of the first "stop" challenge is WON on the score with no stops (the verdict
#            "ONLY 0 OF n STOPS": a won game, the goal not met, no tokens); retried
# With --legends-play the games are played out CPU vs CPU instead (checks follow the real verdicts; slow, not
# deterministic).
#
#   godot --headless --path . --fixed-fps 60 --quit-after 2000000 -- --legends-test --stars 24 --target 3
#   ... --difficulty easy|normal|hard (|legend with --stars 72)   the level picked on the chapter view (tokens 1/2/3)
#   ... --legends-force-loss 2[,5]   those legends games of this run are lost (the retry must replay the same game)
#   ... --legends-no-trip            erases the TEST trip save first (user://trip_test.json): the Kings play
#   ... --legends-chapter <id>       plays only that built chapter (its gate forced open for this run: --tokens or
#                                    --stars as its gate says, never saved; no next-chapter gate check)
#   ... --legends-test-two           the stand-in second chapter (LegendsData.two_chapter_test_data(): "fathers", 6
#                                    copies of Chapter 1's legends, gate 36 stars or 12 tokens) for the whole run
#   ... --legends-test-three         P11-09: three built chapters: the shipped rows with the timeline's third row (the
#                                    Present) built as a stand-in (LegendsData.stand_in_test_data(): 6 copies of
#                                    Chapter 1's legends, lg_zz_present_1..6, its own gate from the data); wins over
#                                    --legends-test-two. Chapter 3 opens by its gate like any other: after a Hard run
#                                    of Chapters 1-2 by tokens, after a Normal one only with its stars (--stars 48)
#   ... --legends-test-four          P12-03: four built chapters: the shipped rows with the timeline's fourth row (the
#                                    New Generation, "next") built as a stand-in (lg_zz_next_1..6, its own gate from
#                                    the data: 72 stars or 48 tokens); wins over --legends-test-three and -two. Chapter
#                                    4 opens by its tokens after a Hard run of Chapters 1-3 (63), after a Normal one
#                                    (42) only with its stars (--stars 72). It is the last row: after it the driver
#                                    prints "LEGENDS gate: <id> is the last chapter" and goes BACK to the title
# Three chapters (P11-09): the same walk, chapter after chapter in data order, each next gate checked against the data
# after the last chapter played; --legends-chapter <id> also takes the stand-in's id under --legends-test-three (and
# -four). After the last row there is no next gate: the run ends cleanly.
# Per chapter: --legends-force-loss N counts that chapter's games (the Nth game of each chapter is lost), and the
# GOAL_TESTS run once in each chapter. After every game the other chapters' tokens and finales must not move.
# The crew: with a test trip save (e.g. after `--trip-test --target 3 --trip-stop-after chicago`) your trip's
# starters, else the Kings at even ratings; the driver checks the match has the side Legends.your_side() promises.
# Checks after every game (any broken one is a LEGENDS ERROR): the verdict in Flow.last_result.challenge, the outcome
# (won only when the goal was met), the key's tokens (max(before, the level's 1/2/3) on a win, unchanged otherwise;
# in memory and in the legends file), the unlock (the first win of a legend, then his unlock scene), the chapter
# closing on the finale (its "after" scene), where the game led, and the test trip save byte for byte unchanged.
# At the end: all 6 unlocked, the chapter done, every token as won, the file agrees, the intro and the 6 unlock
# scenes seen, the Hall visited, every forced loss and goal test retried and won.
# P12-18, the end of the mode: the finale that wins the last open chapter with every timeline row built plays the
# finale's "after" scene, then Legends.COMPLETE_SCENE once, then the chapter view; the timeline then shows LEGENDS
# COMPLETE and the Hall its full banner (the driver taps it once: the ending replays, back to the Hall). A run that
# leaves a chapter locked (e.g. Normal, 42 tokens: Chapter 4 shut) must show neither and never play the ending.
# Prints LEGENDS lines and ends with "LEGENDS END" (exit 0) or "LEGENDS ERROR: <why>" (exit 1). Test files only:
# user://legends_test.json (erased at the start), user://trip_test.json (only read, or erased by --legends-no-trip).

const Flow = preload("res://scripts/flow.gd")
const Legends = preload("res://scripts/legends.gd")
const LegendsData = preload("res://scripts/legends_data.gd")
const LegendsSave = preload("res://scripts/legends_save.gd")
const Trip = preload("res://scripts/trip.gd")
const Save = preload("res://scripts/save.gd")
const Stars = preload("res://scripts/stars.gd")
const Ratings = preload("res://scripts/ratings.gd")
const StoryText = preload("res://scripts/story_text.gd")

const STEP_WAIT := 12             # frames on a screen between steps
const STALL_FRAMES := 1800        # a screen doing nothing this long (30 s) fails the test
const FORCE_FRAMES := 90          # a decided game ends this many frames after the driver sees it start
const GAME_FRAMES := 60 * 60 * 45 # a played game (--legends-play) longer than 45 min fails the test
const MAX_GAMES := 60             # more legends games than this = a loop
const MAX_SCREENS := 600          # more screen visits than this = a loop
const GOAL_TESTS := true          # the broken "hold" goal and the won-but-short "stop" goal, once each
const REPLAY_TEST := true         # after the finale: replay the first legend at another level (best tokens kept)
const HALL_TEST := true           # after that: HALL from the chapter view, the Hall's auto_step() must come back
const FINALE_PICK := "finale"     # = legends_tour.gd's pick id of the finale
const FORCE_FLAG := "--legends-force-loss"
const NO_TRIP_FLAG := "--legends-no-trip"
const PLAY_FLAG := "--legends-play"
const CHAPTER_FLAG := "--legends-chapter"   # P10-09: only this chapter (gate forced open, nothing saved)
const TWO_FLAG := "--legends-test-two"      # P10-09: LegendsData.two_chapter_test_data() for the run
const THREE_FLAG := "--legends-test-three"  # P11-09: the timeline's third row as a built stand-in for the run
const THREE_ROW := 2                        # its index in LegendsData.chapter_ids() (the Present today)
const FOUR_FLAG := "--legends-test-four"    # P12-03: the timeline's fourth row as a built stand-in for the run
const FOUR_ROW := 3                         # its index in LegendsData.chapter_ids() (the New Generation, "next")

# --- the run (static: survives reload_current_scene) ---
static var _started := false
static var _finished := false
static var _phase := "title"      # title, chapter (the 6 + finale), replay, hall, hall_back, timeline, back, done
static var _chapter := ""         # the chapter under test now
static var _only := ""            # --legends-chapter: the one chapter of this run ("" = every built chapter)
static var _records: Array = []   # the finished chapters: _record() dicts, in play order
static var _ch_games := 0         # games of the chapter under test (--legends-force-loss counts these)
static var _gate_line := false    # the next chapter's gate was checked (or skipped) after the last chapter
static var _level := ""           # the level this run plays ("" until the first chapter view without --difficulty)
static var _games := 0
static var _screens := 0
static var _force: Array = []     # game numbers (1-based, this run) that are lost
static var _losses_forced := 0
static var _play := false
static var _prev_screen := ""
static var _trip_bytes := PackedByteArray()
static var _trip_had := false
static var _crew_want := ""       # "trip" or "kings"
static var _scenes: Array = []    # story scenes shown, in order
static var _last_scene := ""      # the story scene just before this screen ("" if the last screen was no story)
static var _broke_hold := false   # GOAL_TESTS done
static var _short_stop := false
static var _goal_tests := 0
static var _retry_key := ""       # a game not won: the next game must be the same one
static var _retries := 0
static var _replay_key := ""      # REPLAY_TEST: its key and level
static var _replay_level := ""
static var _replay_done := false
static var _hall_done := false
static var _expect := {}          # where the last game must lead: {"screen", "scene"} or {"screen", "chapter"}
# the game being played
static var _g_key := ""
static var _g_lid := ""
static var _g_type := ""
static var _g_level := ""
static var _g_plan := ""          # win, loss, broken, short, play
static var _g_before := 0         # the key's best tokens before
static var _g_was_unlocked := false
static var _g_unlock_scene_new := false   # his unlock scene exists and was not seen before
static var _g_after_scene_new := false    # the finale's "after" scene exists and was not seen before
static var _results := 0
static var _finale_games := 0     # finale games started in the chapter phase
static var _g_complete_new := false      # P12-18: winning this finale completes the mode (the ending is due)
static var _ending_game := 0      # P12-18: the ending scene after a game (must be 1 once complete, else 0)
static var _ending_hall := 0      # ... replayed from the Hall's full banner
static var _ending_tap := false   # the Hall's banner was tapped: the next screen is the ending, then the Hall again
static var _complete_seen := false   # the timeline showed LEGENDS COMPLETE (checked on the "back" step)
static var _g_others := {}        # {chapter: [tokens, done]} of every other built chapter when the game started

var main                          # main.gd (Flow sets it)
var _screen := ""
var _frames := 0
var _idle := 0
var _decided := false
var _over_seen := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen = str(Flow.screen)
	if not _started:
		_started = true
		if not _begin():
			return
	if _screen == Flow.GAME:
		_start_game()
	else:
		_screens += 1
		if _screens > MAX_SCREENS:
			_fail("more than %d screen visits: a loop?" % MAX_SCREENS)
			return
		var a: String = (" " + JSON.stringify(Flow.args)) if Flow.args.size() > 0 else ""
		print("LEGENDS screen %s%s | %s" % [_screen, a, _state()])
		_on_arrive()
	_last_scene = str(Flow.args.get("scene", "")) if _screen == "story" else ""
	_prev_screen = _screen

# once per run: the flags, the test files, the starting checks. False after a LEGENDS ERROR.
func _begin() -> bool:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	_play = cmd.has(PLAY_FLAG)
	for part in _arg_after(FORCE_FLAG, "").split(",", false):
		if part.is_valid_int():
			_force.append(int(part))
	Save.use_test_file = true   # only ever the test trip save (Legends does the same in a test run)
	LegendsSave.use_test_file = true
	if cmd.has(FOUR_FLAG):
		var ignored: Array = []
		for f in [THREE_FLAG, TWO_FLAG]:
			if cmd.has(f):
				ignored.append(f)
		if not _stand_in(FOUR_FLAG, FOUR_ROW, "four", ignored):
			return false
	elif cmd.has(THREE_FLAG):
		if not _stand_in(THREE_FLAG, THREE_ROW, "three", [TWO_FLAG] if cmd.has(TWO_FLAG) else []):
			return false
	elif cmd.has(TWO_FLAG):
		LegendsData.set_test_data(LegendsData.two_chapter_test_data())
		print("LEGENDS TEST two chapters (stand-in data) | built %s" % str(LegendsData.built_chapters()))
	if cmd.has(NO_TRIP_FLAG):
		Save.erase()
	LegendsSave.erase()   # a fresh Legends progress every run (the test file only)
	Legends.load_state(true)
	var built: Array = LegendsData.built_chapters()
	if built.is_empty():
		_fail("legends_data.gd has no built chapter")
		return false
	_chapter = str(built[0])
	_only = _arg_after(CHAPTER_FLAG, "").strip_edges().to_lower()
	if _only != "":
		if not built.has(_only):
			_fail("%s %s is not a built chapter (built %s)" % [CHAPTER_FLAG, _only, str(built)])
			return false
		_chapter = _only
		print("LEGENDS TEST chapter %s only | %s" % [_only, _force_gate(_only)])
	_trip_had = FileAccess.file_exists(Save.path())
	_trip_bytes = _bytes(Save.path())
	_crew_want = Legends.CREW_TRIP if not Save.read().is_empty() else Legends.CREW_KINGS
	var want: String = _level_want()
	if want != "":
		_level = want
	print("LEGENDS TEST start | legends file %s | trip save %s (%s, %d bytes) -> crew %s | chapter %s | level %s | target %s | force loss %s | %s | stars %d, legend level %s | tokens max %d" % [
			LegendsSave.path(), Save.path(), "there" if _trip_had else "none", _trip_bytes.size(), _crew_want,
			_chapter if _only != "" else ",".join(PackedStringArray(built)), _level if _level != "" else "(the chapter view's)", _arg_after("--target", "-"), str(_force),
			"played out (--legends-play)" if _play else "decided at once", Stars.total(),
			"open" if Stars.legend_open() else "closed", LegendsData.max_tokens()])
	if not Legends.mode_open():
		_fail("the Legends mode is locked (stars %d, gate %s): run with --stars 24" % [Stars.total(),
				Legends.mode_gate_text()])
		return false
	return true

# --legends-test-three / -four: the timeline's row-th row built as a stand-in for the whole run
# (LegendsData.stand_in_test_data(): 6 copies of Chapter 1's legends, lg_zz_<chapter>_1..6, its own gate from the
# data). Prints the LEGENDS TEST line; false after a LEGENDS ERROR (fewer rows, or the stand-in not built).
func _stand_in(flag: String, row: int, word: String, ignored: Array) -> bool:
	var rows: Array = LegendsData.chapter_ids()
	if rows.size() <= row:
		_fail("%s: only %d chapter rows" % [flag, rows.size()])
		return false
	var ch: String = str(rows[row])
	LegendsData.set_test_data(LegendsData.stand_in_test_data(ch))
	var built: Array = LegendsData.built_chapters()
	var extra: String = ""
	if not ignored.is_empty():
		extra = " | %s ignored" % " ".join(PackedStringArray(ignored))
	print("LEGENDS TEST %s chapters (stand-in %s: %s) | built %s | gate %s | tokens max %d%s" % [word, ch,
			",".join(PackedStringArray(LegendsData.legend_ids(ch))), str(built),
			JSON.stringify(LegendsData.chapter(ch).get("gate", {})), LegendsData.max_tokens(), extra])
	if built.size() < row + 1 or not built.has(ch):
		_fail("%s: the stand-in did not build %s chapters (built %s)" % [flag, word, str(built)])
		return false
	return true

static func _arg_after(flag: String, def: String) -> String:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	for i in cmd.size():
		if cmd[i].begins_with(flag + "="):
			return cmd[i].substr(flag.length() + 1)
		if cmd[i] == flag and i + 1 < cmd.size():
			return cmd[i + 1]
	return def

# --legends-chapter: opens the chapter's gate for this run if it is not met (never saved): --tokens to its token gate
# if it has one, else --stars to its star gate. Returns what it did.
static func _force_gate(ch: String) -> String:
	if Legends.chapter_open(ch):
		return "gate %s already met (stars %d, tokens %d)" % [Legends.gate_text(ch), Stars.total(), Legends.tokens_total()]
	var gate: Dictionary = LegendsData.chapter(ch).get("gate", {})
	if int(gate.get("tokens", 0)) > 0:
		Legends.force_tokens = int(gate.get("tokens", 0))
		return "gate %s forced open: tokens %d this run" % [Legends.gate_text(ch), Legends.tokens_total()]
	Stars.force_total = int(gate.get("stars", 0))
	return "gate %s forced open: stars %d this run" % [Legends.gate_text(ch), Stars.total()]

# --difficulty's level as the chapter view offers it ("" = none asked): LEGEND without the stars plays Hard
static func _level_want() -> String:
	var v: String = _arg_after("--difficulty", "").strip_edges().to_lower()
	if v == "":
		return ""
	return Legends.level_ok(v)

# ---------------------------------------------------------------------------------------------------- the loop

func _process(_delta: float) -> void:
	if _finished:
		return
	_frames += 1
	if _screen == Flow.GAME:
		_watch_game()
		return
	if _frames < STEP_WAIT:
		return
	_frames = 0
	var done: bool = _step()
	if _finished:
		return
	if done:
		_idle = 0
	else:
		_idle += STEP_WAIT
		if _idle >= STALL_FRAMES:
			_fail("stuck on screen %s (nothing to do for %d frames)" % [_screen, STALL_FRAMES])

# one step on a screen; true when it did something
func _step() -> bool:
	var node: Node = Flow.current_screen()
	match _screen:
		"title":
			if _phase == "done":
				_end()
				return true
			if _phase != "title":
				_fail("back on the title during phase %s" % _phase)
				return false
			return _tap_legends(node)
		"legends":
			if node == null or not node.has_method("chapter"):
				_fail("the legends screen is not the era tour (legends_tour.gd)")
				return false
			if str(node.call("chapter")) == "":
				return _timeline_step(node)
			return _chapter_step(node)
		"story", "hall":
			if _screen == "hall" and _phase == "hall_back":
				# P12-18: the full Hall banner once the mode is complete (and only then); tapped once, it replays the ending
				var full: bool = Legends.legends_complete()
				var shown: bool = node != null and node.has_method("banner_shown") and bool(node.call("banner_shown"))
				if shown != full:
					print("LEGENDS hall banner: %s, want %s | WRONG" % [str(shown), str(full)])
					_fail("the Hall's full banner is %s with legends_complete() %s" % [str(shown), str(full)])
					return false
				if full and _ending_hall == 0 and not _ending_tap:
					node.set("_arm_t", 0.0)
					_ending_tap = true
					print("LEGENDS hall banner: shown | tap it (the ending again)")
					return bool(node.call("replay_ending"))
				print("LEGENDS hall: BACK (auto_step)%s" % (" | banner shown" if shown else ""))
			return Flow.auto_step()
	_fail("an unexpected screen %s" % _screen)
	return false

# the title: tap LEGENDS (the real button)
func _tap_legends(node: Node) -> bool:
	if node == null:
		_fail("no title screen")
		return false
	var b = node.find_child("LegendsButton", true, false)
	if not (b is Button):
		_fail("the title has no LEGENDS button")
		return false
	node.set("_arm_t", 0.0)
	print("LEGENDS title: tap LEGENDS | mode open %s (stars %d)" % [str(Legends.mode_open()), Stars.total()])
	_phase = "chapter"
	(b as Button).pressed.emit()
	return true

func _timeline_step(node: Node) -> bool:
	if _phase == "back":
		var st: String = str(node.call("chapter_state", _chapter))
		print("LEGENDS timeline: %s is %s | tokens %d/%d | %s" % [_chapter, st, Legends.tokens_total(),
				LegendsData.max_tokens(), "ok" if st == "done" else "WRONG (want done)"])
		if st != "done":
			_fail("the timeline does not show the finished chapter as done")
			return false
		# P12-18: LEGENDS COMPLETE on the timeline exactly when every chapter's finale is won
		var shown: bool = bool(node.call("complete_shown"))
		var sub = node.find_child("TimelineSub", true, false)
		var sub_text: String = str((sub as Label).text) if sub is Label else ""
		var full: bool = Legends.legends_complete()
		var ok_c: bool = shown == full and sub_text.begins_with("LEGENDS COMPLETE") == full
		print("LEGENDS timeline complete: %s | '%s' | %s" % [str(shown), sub_text, "ok" if ok_c else
				"WRONG (want %s)" % str(full)])
		if not ok_c:
			_fail("the timeline's LEGENDS COMPLETE does not match legends_complete() %s" % str(full))
			return false
		_complete_seen = _complete_seen or shown
		var nxt: String = _gate_check(node)
		if _finished:
			return false
		if nxt != "":
			_records.append(_record())
			_next_chapter(nxt)
			print("LEGENDS next chapter %s: tap its timeline panel" % nxt)
			node.set("_arm_t", 0.0)
			node.call("_on_panel_tap", nxt)
			return bool(node.get("_busy"))
		_phase = "done"
		node.set("_arm_t", 0.0)
		node.call("_on_back")   # the timeline's BACK: the title
		return true
	if _phase != "chapter":
		_fail("on the timeline during phase %s" % _phase)
		return false
	var open: Array = node.call("_open_chapters")
	if not open.is_empty() and str(open[0]) == _chapter:
		return Flow.auto_step()   # opens the first open chapter (its intro scene first, once)
	if not Legends.chapter_open(_chapter):
		_fail("chapter %s is not open on the timeline (open %s)" % [_chapter, str(open)])
		return false
	node.set("_arm_t", 0.0)
	node.call("_on_panel_tap", _chapter)   # a later chapter (or --legends-chapter): its panel, as a tap
	return bool(node.get("_busy"))

# after a finished chapter, on the timeline: the next chapter in data order, its gate as the data says (built and its
# stars or tokens reached = open; built otherwise = locked; not built = later) against the timeline's state,
# Legends.gate_met() and Legends.chapter_open(). A panel that isn't open must refuse a tap. Returns the next chapter
# to play, or "".
func _gate_check(node: Node) -> String:
	_gate_line = true
	if _only != "":
		return ""   # --legends-chapter: this chapter only (its gate was forced)
	var ids: Array = LegendsData.chapter_ids()
	var i: int = ids.find(_chapter)
	if i < 0 or i + 1 >= ids.size():
		print("LEGENDS gate: %s is the last chapter" % _chapter)
		return ""
	var nxt: String = str(ids[i + 1])
	var row: Dictionary = LegendsData.chapter(nxt)
	var gate: Dictionary = row.get("gate", {})
	var need_s: int = int(gate.get("stars", 0))
	var need_t: int = int(gate.get("tokens", 0))
	var stars: int = Stars.total()
	var toks: int = Legends.tokens_total()
	var by: Array = []
	if need_s > 0 and stars >= need_s:
		by.append("stars")
	if need_t > 0 and toks >= need_t:
		by.append("tokens")
	var met: bool = not by.is_empty() or (need_s <= 0 and need_t <= 0)
	var built: bool = bool(row.get("built", false))
	var want: String = "later" if not built else ("open" if met else "locked")
	var st: String = str(node.call("chapter_state", nxt))
	var errs: Array = []
	if st != want:
		errs.append("the timeline shows %s, want %s" % [st, want])
	if Legends.chapter_open(nxt) != (want == "open"):
		errs.append("Legends.chapter_open %s" % str(Legends.chapter_open(nxt)))
	if Legends.gate_met(nxt) != met:
		errs.append("Legends.gate_met %s, want %s" % [str(Legends.gate_met(nxt)), str(met)])
	if want != "open":
		node.set("_arm_t", 0.0)
		node.call("_on_panel_tap", nxt)
		if bool(node.get("_busy")):
			errs.append("a tap on the %s panel opened it" % want)
	print("LEGENDS gate %s (after %s): %s | gate %s: stars %d, tokens %d -> %s | timeline %s | %s" % [nxt, _chapter,
			"not built" if not built else want, Legends.gate_text(nxt), stars, toks,
			("met by " + " and ".join(PackedStringArray(by))) if not by.is_empty() else ("met" if met else "not met"),
			st, "ok" if errs.is_empty() else "WRONG: " + "; ".join(PackedStringArray(errs))])
	if not errs.is_empty():
		_fail("the gate of %s does not match the data" % nxt)
		return ""
	return nxt if want == "open" else ""

# the finished chapter's numbers, for _end()
static func _record() -> Dictionary:
	return {"chapter": _chapter, "games": _ch_games, "losses_forced": _losses_forced, "goal_tests": _goal_tests,
		"retries": _retries, "retry_key": _retry_key, "replay_key": _replay_key, "replay_level": _replay_level,
		"replay_done": _replay_done, "hall_done": _hall_done}

# a fresh chapter: the per-chapter counters start again (forced losses, goal tests, replay, Hall)
static func _next_chapter(ch: String) -> void:
	_chapter = ch
	_phase = "chapter"
	_ch_games = 0
	_losses_forced = 0
	_goal_tests = 0
	_retries = 0
	_retry_key = ""
	_broke_hold = false
	_short_stop = false
	_replay_key = ""
	_replay_level = ""
	_replay_done = false
	_hall_done = false
	_finale_games = 0

func _chapter_step(node: Node) -> bool:
	if str(node.call("chapter")) != _chapter:
		_fail("the chapter view shows %s, not %s" % [str(node.call("chapter")), _chapter])
		return false
	node.set("_arm_t", 0.0)
	match _phase:
		"chapter":
			if _level == "":
				_level = str(node.call("level"))
				print("LEGENDS level: the chapter view's %s (no --difficulty)" % _level)
			if not bool(node.call("set_level", _level)):
				_fail("the chapter view does not offer level %s" % _level)
				return false
			return Flow.auto_step()   # plays the first open challenge (the finale once all 6 are beaten)
		"replay":
			if not bool(node.call("set_level", _replay_level)) or not bool(node.call("pick", _replay_key.substr(3))):
				_fail("the replay of %s at %s could not be picked" % [_replay_key, _replay_level])
				return false
			print("LEGENDS replay: %s at %s (best %d)" % [_replay_key, _replay_level, Legends.token_best(_replay_key)])
			node.call("_on_play")
			return true
		"hall":
			_phase = "hall_back"
			print("LEGENDS hall: tap HALL on the chapter view")
			node.call("_on_hall")
			return true
		"timeline":
			_phase = "back"
			print("LEGENDS chapter view: BACK to the timeline")
			node.call("_on_back")
			return true
	_fail("on the chapter view during phase %s" % _phase)
	return false

# ---------------------------------------------------------------------------------------------------- games

func _start_game() -> void:
	_games += 1
	_ch_games += 1
	if main != null:
		main.set("autoplay", true)   # both teams CPU (main.gd still sends the result to Flow under --legends-test)
	if _games > MAX_GAMES:
		_fail("more than %d legends games: a loop?" % MAX_GAMES)
		return
	if not Flow.in_legends():
		_fail("a game started without a legends match (Flow.match mode %s)" % str(Flow.match.get("mode", "")))
		return
	var m: Dictionary = Flow.match
	_g_key = str(m.get("key", ""))
	_g_lid = _g_key.substr(3) if _g_key.begins_with(Legends.KEY_CHALLENGE) else ""
	var c: Dictionary = m.get("challenge", {})
	_g_type = str(c.get("type", "")) if _g_lid != "" else "finale"
	_g_level = str(m.get("level", ""))
	_g_before = Legends.token_best(_g_key)
	_g_others = {}
	for ch in LegendsData.built_chapters():
		if str(ch) != _chapter:
			_g_others[str(ch)] = [Legends.chapter_tokens(str(ch)), Legends.chapter_done(str(ch))]
	_g_was_unlocked = _g_lid != "" and Legends.is_unlocked(_g_lid)
	_g_unlock_scene_new = false
	_g_after_scene_new = false
	if _g_lid != "":
		var us: String = str(LegendsData.legend(_g_lid).get("unlock_scene", ""))
		_g_unlock_scene_new = us != "" and StoryText.has_scene(us) and not Legends.has_seen(us)
	else:
		var asc: String = str((LegendsData.chapter(_chapter).get("finale_scenes", {}) as Dictionary).get("after", ""))
		_g_after_scene_new = asc != "" and StoryText.has_scene(asc) and not Legends.has_seen(asc)
	# P12-18: this finale is the last one missing (every row built, every other chapter done) and the ending is unseen
	_g_complete_new = false
	if _g_lid == "" and Legends.complete_scene() != "" and not Legends.has_seen(Legends.COMPLETE_SCENE):
		_g_complete_new = true
		for ch in LegendsData.chapter_ids():
			if not LegendsData.is_built(str(ch)) or (str(ch) != _chapter and not Legends.chapter_done(str(ch))):
				_g_complete_new = false
	# the plan
	if _play:
		_g_plan = "play"
	elif _phase == "replay":
		_g_plan = "win"
	elif _force.has(_ch_games):
		_g_plan = "loss"
	elif GOAL_TESTS and _g_type == "hold" and not _broke_hold:
		_broke_hold = true
		_g_plan = "broken"
	elif GOAL_TESTS and _g_type == "stop" and not _short_stop:
		_short_stop = true
		_g_plan = "short"
	else:
		_g_plan = "win"
	var errs: Array = _check_match(m)
	var tm: Array = m.get("teams", [])
	print("LEGENDS game %d | %s | %s | to %d (rules %s) | level %s | crew %s | %s vs %s | best %d | plan %s%s%s" % [
			_games, _g_key, _g_type, int(m.get("target", 0)), _arg_after("--target", "match"), _g_level,
			str(m.get("crew", "")), str(_ids(tm[0] if tm.size() > 0 else {})), str(_ids(tm[1] if tm.size() > 1 else {})),
			_g_before, _g_plan, (" | retry of " + _retry_key) if _retry_key != "" else "",
			(" | " + str(m.get("note", ""))) if str(m.get("note", "")) != "" else ""])
	if _retry_key != "":
		if _g_key != _retry_key:
			errs.append("the retry plays %s, not %s" % [_g_key, _retry_key])
		_retries += 1
		_retry_key = ""
	if _g_lid == "" and _phase == "chapter":
		# the finale: its "before" scene came first (once), when the chapter has one
		var bs: String = str((LegendsData.chapter(_chapter).get("finale_scenes", {}) as Dictionary).get("before", ""))
		_finale_games += 1
		if _finale_games == 1 and bs != "" and StoryText.has_scene(bs) and _last_scene != bs:
			errs.append("the finale's first PLAY did not show its before scene %s (last scene '%s')" % [bs, _last_scene])
	if not errs.is_empty():
		_fail("game %d: %s" % [_games, "; ".join(PackedStringArray(errs))])

# the match has what Legends promises: the key's opponents, the run's level, your side (trip starters or the Kings)
func _check_match(m: Dictionary) -> Array:
	var errs: Array = []
	var tm: Array = m.get("teams", [])
	if tm.size() != 2:
		return ["the match has %d teams" % tm.size()]
	var mine: Array = _ids(tm[0])
	var theirs: Array = _ids(tm[1])
	if mine.size() != Trip.STARTERS or theirs.size() != Trip.STARTERS:
		errs.append("not 3 players a side (%d / %d)" % [mine.size(), theirs.size()])
	var want_opp: Array = LegendsData.challenge_team(_g_lid) if _g_lid != "" else LegendsData.finale_team(_chapter)
	if theirs != want_opp:
		errs.append("opponents %s, want %s" % [str(theirs), str(want_opp)])
	var want_lv: String = _replay_level if _phase == "replay" else _level
	if _g_level != want_lv:
		errs.append("level %s, want %s" % [_g_level, want_lv])
	if str(m.get("crew", "")) != _crew_want:
		errs.append("crew %s, want %s" % [str(m.get("crew", "")), _crew_want])
	if _g_lid != "" and _g_type == "":
		errs.append("challenge %s has no type" % _g_lid)
	if _g_lid == "" and not (m.get("challenge", {}) as Dictionary).is_empty():
		errs.append("the finale has a challenge row")
	if str(m.get("human", "")) != str(mine[0] if not mine.is_empty() else ""):
		errs.append("human %s is not the first player %s" % [str(m.get("human", "")), str(mine)])
	var swaps: Array = m.get("swaps", [])
	for i in (tm[0] as Dictionary).get("players", []).size():
		var pd: Dictionary = (tm[0] as Dictionary).get("players", [])[i]
		var id: String = str(pd.get("id", ""))
		if pd.has(Legends.PERK_KEY):
			errs.append("%s has a mentor perk in a legends game" % id)
		if theirs.has(id):
			errs.append("%s plays on both sides" % id)
		var want_r: Dictionary = {}
		if _crew_want == Legends.CREW_KINGS:
			if id != str(Trip.QUICK_KINGS[i]):
				errs.append("the Kings are %s, want %s" % [str(mine), str(Trip.QUICK_KINGS)])
				break
			want_r = Trip.quick_ratings(id)
		else:
			if swaps.is_empty() and not Trip.starters.has(id):
				errs.append("%s is not a trip starter %s" % [id, str(Trip.starters)])
			want_r = (Trip.roster_player(id).get("ratings", {}) as Dictionary)
		var r: Dictionary = pd.get("ratings", {})
		for s in Ratings.STATS:
			if int(r.get(s, -1)) != int(want_r.get(s, -2)):
				errs.append("%s %s %d, want %d" % [id, s, int(r.get(s, -1)), int(want_r.get(s, -2))])
				break
	if _crew_want == Legends.CREW_TRIP and swaps.is_empty():
		var a: Array = mine.duplicate()
		var b: Array = Trip.starters.duplicate()
		a.sort()
		b.sort()
		if a != b:
			errs.append("your side %s, the trip's starters %s" % [str(mine), str(Trip.starters)])
		elif Trip.starters.has(Trip.human) and str(mine[0]) != Trip.human:
			errs.append("you play %s, the trip's human is %s" % [str(mine[0]), Trip.human])
	return errs

static func _ids(team) -> Array:
	var out: Array = []
	if team is Dictionary:
		for p in (team as Dictionary).get("players", []):
			out.append(str((p as Dictionary).get("id", "?")))
	return out

func _watch_game() -> void:
	if main == null:
		return
	if not _decided and _g_plan != "play" and _frames >= FORCE_FRAMES and not bool(main.get("game_over")):
		_decided = true
		_decide()
	if bool(main.get("game_over")):
		if not _over_seen:
			_over_seen = true
			var sc: Array = main.score
			var v = Flow.last_result.get("challenge", {})
			print("LEGENDS result game %d | %s %d - %d | %s | verdict %s" % [_games,
					"WON" if int(sc[0]) > int(sc[1]) else "LOST", int(sc[0]), int(sc[1]), _g_plan,
					JSON.stringify(v) if v is Dictionary and not (v as Dictionary).is_empty() else "- (finale)"])
		return
	if _frames > GAME_FRAMES:
		_fail("game %d did not end in %d frames" % [_games, GAME_FRAMES])

# ends the game as planned
func _decide() -> void:
	var tg: int = int(main.rules.get("target"))
	var ch = main.get("challenge")
	if ch == null and (_g_plan == "short" or _g_plan == "broken"):
		_fail("a %s challenge game has no challenge node (main.challenge)" % _g_type)
		return
	var start1: int = 0
	if ch != null and _g_type == "comeback":
		start1 = int((ch.get("start_score") as Array)[1])
	match _g_plan:
		"win":
			if ch != null and _g_type == "stop":
				ch.set("stops", int(ch.get("count")))
			if ch != null and _g_type == "score":
				ch.set("your_points", int(ch.get("score_min")))   # P10: the score goal needs your own points
			main.score[0] = tg
			main.score[1] = mini(start1, tg - 1)
			main.rules.call("_end_game", 0)
		"short":
			ch.set("stops", 0)
			main.score[0] = tg
			main.score[1] = 0
			main.rules.call("_end_game", 0)
		"broken":
			var lim: int = int(ch.get("limit"))
			ch.set("legend_points", lim)   # as if he had scored them (challenge.count_points)
			main.score[1] = lim
			main.score[0] = 0
			ch.call("check")   # the broken goal ends the game at once (main.end_challenge(false))
			if not bool(main.get("game_over")):
				_fail("a broken hold goal (%d points) did not end the game" % lim)
		"loss":
			_losses_forced += 1
			main.score[1] = tg
			main.score[0] = 0
			main.rules.call("_end_game", 1)

# ---------------------------------------------------------------------------------------------------- arrivals

func _on_arrive() -> void:
	if _screen == "story":
		var sc: String = str(Flow.args.get("scene", ""))
		_scenes.append(sc)
		print("LEGENDS story %s (then %s %s)" % [sc, str(Flow.args.get("then", "")),
				JSON.stringify(Flow.args.get("then_args", {}))])
	if _prev_screen == Flow.GAME:
		_check_outcome()
		if _finished:
			return
	elif not _expect.is_empty() and _prev_screen == "story" and _screen == str(_expect.get("then", "")):
		_check_then()
		if _finished:
			return
	if _ending_tap and _prev_screen == "hall":
		var ok_t: bool = _screen == "story" and str(Flow.args.get("scene", "")) == Legends.COMPLETE_SCENE \
				and str(Flow.args.get("then", "")) == "hall"
		print("LEGENDS hall banner tap: %s" % ("ok, the ending" if ok_t else "WRONG (on %s %s)" % [_screen,
				JSON.stringify(Flow.args)]))
		if not ok_t:
			_fail("the Hall's banner did not replay the ending")
			return
		_ending_hall += 1
		return
	if _ending_tap and _prev_screen == "story":
		_ending_tap = false
		print("LEGENDS hall banner: the ending -> %s %s" % [_screen, "ok" if _screen == "hall" else "WRONG"])
		if _screen != "hall":
			_fail("the ending from the Hall did not come back to the Hall")
			return
	if _phase == "hall_back" and _screen == "hall":
		print("LEGENDS hall: open | back %s" % JSON.stringify(Flow.args))
	elif _phase == "hall_back" and _prev_screen == "hall":
		var ok: bool = _screen == "legends" and str(Flow.args.get("chapter", "")) == _chapter
		print("LEGENDS hall back: %s" % ("ok, on the chapter view" if ok else "WRONG (on %s %s)" % [_screen,
				JSON.stringify(Flow.args)]))
		if not ok:
			_fail("the Hall's BACK did not lead to the chapter view")
			return
		_hall_done = true
		_phase = "timeline"

# the first screen after a game: the outcome, its tokens and unlocks, the save files, where it led
func _check_outcome() -> void:
	_results += 1
	var errs: Array = []
	var o: Dictionary = Legends.last_outcome
	var v = Flow.last_result.get("challenge", null)
	var game_won: bool = bool(Flow.last_result.get("won", false))
	var met: bool = true
	if _g_lid != "":
		if not (v is Dictionary):
			errs.append("no challenge verdict in Flow.last_result")
		else:
			met = bool((v as Dictionary).get("met", false))
			if str((v as Dictionary).get("type", "")) != _g_type:
				errs.append("verdict type %s, want %s" % [str((v as Dictionary).get("type", "")), _g_type])
			if not met and str((v as Dictionary).get("why", "")) == "":
				errs.append("a failed verdict without a reason")
	if _g_lid == "" and v is Dictionary and not (v as Dictionary).is_empty():
		errs.append("the finale has a challenge verdict %s" % JSON.stringify(v))
	var want_won: bool = game_won and met
	match _g_plan:
		"win":
			if not want_won:
				errs.append("a decided win was not won with the goal met (won %s, met %s)" % [str(game_won), str(met)])
		"loss", "broken":
			if game_won or (met and _g_lid != ""):
				errs.append("a %s came out won %s, met %s" % [_g_plan, str(game_won), str(met)])
		"short":
			if not game_won or met:
				errs.append("a short stop goal came out won %s, met %s (want won, not met)" % [str(game_won), str(met)])
	if bool(o.get("won", false)) != want_won or str(o.get("key", "")) != _g_key:
		errs.append("outcome %s %s, want %s %s" % [str(o.get("key", "")), str(o.get("won", "")), _g_key, str(want_won)])
	if want_won == (str(o.get("failed", "")) != ""):
		errs.append("outcome failed '%s' on a %s" % [str(o.get("failed", "")), "win" if want_won else "loss"])
	# tokens: the level's on a win, best kept
	var per: int = LegendsData.tokens_for(_g_level)
	var want_t: int = maxi(_g_before, per) if want_won else _g_before
	var disk: Dictionary = LegendsSave.read()
	var disk_t: int = int((disk.get("tokens", {}) as Dictionary).get(_g_key, 0))
	if Legends.token_best(_g_key) != want_t or int(o.get("tokens_now", -1)) != want_t or disk_t != want_t:
		errs.append("tokens %d (outcome %s, file %d), want %d" % [Legends.token_best(_g_key), str(o.get("tokens_now", "?")),
				disk_t, want_t])
	if int(o.get("tokens_got", -1)) != (per if want_won else 0):
		errs.append("tokens got %s, want %d" % [str(o.get("tokens_got", "?")), per if want_won else 0])
	# the unlock
	var new_unlock: bool = want_won and _g_lid != "" and not _g_was_unlocked
	if str(o.get("unlocked", "")) != (_g_lid if new_unlock else ""):
		errs.append("unlocked '%s', want '%s'" % [str(o.get("unlocked", "")), _g_lid if new_unlock else ""])
	if _g_lid != "":
		var now_u: bool = Legends.is_unlocked(_g_lid)
		var file_u: bool = (disk.get("unlocked", []) as Array).has(_g_lid)
		if now_u != (_g_was_unlocked or want_won) or (now_u and not file_u):
			errs.append("%s unlocked %s (file %s)" % [_g_lid, str(now_u), str(file_u)])
	# the chapter closing
	var closes: bool = want_won and _g_lid == ""
	if closes:
		if not bool(o.get("chapter_done", false)) or not Legends.chapter_done(_chapter) \
				or not (disk.get("finales", []) as Array).has(_chapter):
			errs.append("the won finale did not close %s (outcome %s, file %s)" % [_chapter,
					str(o.get("chapter_done", "")), str(disk.get("finales", []))])
	elif _g_lid == "" and Legends.chapter_done(_chapter):
		errs.append("a lost finale closed the chapter")
	# the other chapters: their tokens and finales did not move (a finale closes only its own chapter)
	for ch in _g_others:
		var was: Array = _g_others[ch]
		if Legends.chapter_tokens(str(ch)) != int(was[0]) or Legends.chapter_done(str(ch)) != bool(was[1]):
			errs.append("chapter %s moved: tokens %d -> %d, done %s -> %s" % [str(ch), int(was[0]),
					Legends.chapter_tokens(str(ch)), str(was[1]), str(Legends.chapter_done(str(ch)))])
		if bool(was[1]) != (disk.get("finales", []) as Array).has(str(ch)):
			errs.append("chapter %s done %s, the file's finales %s" % [str(ch), str(was[1]), str(disk.get("finales", []))])
	# the trip save, byte for byte
	var trip_ok: String = _trip_check()
	if trip_ok != "":
		errs.append(trip_ok)
	# where it led
	var ch_args: Dictionary = {"chapter": _chapter}
	_expect = {}
	if new_unlock and _g_unlock_scene_new:
		_expect = {"screen": "story", "scene": str(LegendsData.legend(_g_lid).get("unlock_scene", "")),
			"then": "legends"}
	elif closes and _g_after_scene_new:
		_expect = {"screen": "story", "scene": str((LegendsData.chapter(_chapter).get("finale_scenes", {})
				as Dictionary).get("after", "")), "then": "legends"}
		if _g_complete_new:
			_expect["chain"] = Legends.COMPLETE_SCENE   # P12-18: the ending after the "after" scene
	elif closes and _g_complete_new:
		_expect = {"screen": "story", "scene": Legends.COMPLETE_SCENE, "then": "legends"}
	if closes and Legends.legends_complete() != _g_complete_new and not Legends.has_seen(Legends.COMPLETE_SCENE):
		errs.append("legends_complete() %s after this finale, want %s" % [str(Legends.legends_complete()),
				str(_g_complete_new)])
	if not _expect.is_empty():
		if _screen != "story" or str(Flow.args.get("scene", "")) != str(_expect["scene"]):
			errs.append("led to %s %s, want the story %s" % [_screen, JSON.stringify(Flow.args), str(_expect["scene"])])
		var ta: Dictionary = Flow.args.get("then_args", {})
		if str(_expect.get("chain", "")) != "" and (str(Flow.args.get("then", "")) != "story"
				or str(ta.get("scene", "")) != str(_expect["chain"]) or str(ta.get("then", "")) != "legends"
				or str((ta.get("then_args", {}) as Dictionary).get("chapter", "")) != _chapter):
			errs.append("the ending does not follow the after scene: %s" % JSON.stringify(Flow.args))
	elif _screen != "legends" or Flow.args != ch_args:
		errs.append("led to %s %s, want the chapter view" % [_screen, JSON.stringify(Flow.args)])
	if not closes and (str(Flow.args.get("scene", "")) == Legends.COMPLETE_SCENE
			or str((Flow.args.get("then_args", {}) as Dictionary).get("scene", "")) == Legends.COMPLETE_SCENE):
		errs.append("the ending after %s (not a finale win)" % _g_key)
	print("LEGENDS tokens %s %s %s | level %s (%d a win) | best %d -> %d | unlocked %s (%d/%d) | chapter done %s | trip save %s | %s" % [
			_g_key, _g_plan, "won" if want_won else "lost" if not game_won else "won, goal not met", _g_level, per,
			_g_before, Legends.token_best(_g_key), str(o.get("unlocked", "")) if str(o.get("unlocked", "")) != "" else "-",
			_unlocked_in(_chapter), LegendsData.legend_ids(_chapter).size(), str(Legends.chapter_done(_chapter)),
			"unchanged" if trip_ok == "" else "CHANGED", "ok" if errs.is_empty() else "WRONG: " + "; ".join(PackedStringArray(errs))])
	if not errs.is_empty():
		_fail("the result of %s did not record right" % _g_key)
		return
	if _g_plan == "short" or _g_plan == "broken":
		_goal_tests += 1
	# what comes next
	if not want_won and _phase == "chapter":
		_retry_key = _g_key
	if _phase == "replay":
		_replay_done = true
		_phase = "hall" if HALL_TEST else "timeline"
	elif closes:
		_start_after_finale()

# a story scene after a game has ended: it must lead back to the chapter view
func _check_then() -> void:
	var ok: bool = _screen == "legends" and str(Flow.args.get("chapter", "")) == _chapter
	var chain: String = str(_expect.get("chain", ""))
	var sc: String = str(_expect.get("scene", ""))
	if sc == Legends.COMPLETE_SCENE or chain != "":
		# P12-18: the ending played right before this view (after the "after" scene when there is one)
		var tail: Array = _scenes.slice(maxi(0, _scenes.size() - (2 if chain != "" else 1)))
		var want: Array = [sc, chain] if chain != "" else [sc]
		_ending_game += 1
		print("LEGENDS ending: %s | %s" % [str(tail), "ok" if tail == want and Legends.has_seen(Legends.COMPLETE_SCENE)
				else "WRONG (want %s)" % str(want)])
		if tail != want or not Legends.has_seen(Legends.COMPLETE_SCENE):
			ok = false
	print("LEGENDS after %s: %s" % [str(_expect.get("scene", "")), "ok, back on the chapter view" if ok else
			"WRONG (on %s %s)" % [_screen, JSON.stringify(Flow.args)]])
	_expect = {}
	if not ok:
		_fail("a scene after a game did not lead back to the chapter view")

# the chapter is done: one replay at another level (easy -> hard goes up; otherwise easy, the best stays)
func _start_after_finale() -> void:
	if not REPLAY_TEST:
		_phase = "hall" if HALL_TEST else "timeline"
		return
	_replay_key = Legends.challenge_key(str(LegendsData.legend_ids(_chapter)[0]))
	_replay_level = "hard" if _level == "easy" else "easy"
	_phase = "replay"

# "" when the test trip save is as it was at the start (byte for byte, no temp file left), else why not
func _trip_check() -> String:
	var p: String = Save.path()
	if p != Save.TEST_PATH:
		return "the trip save in use is %s, not the test file" % p
	if FileAccess.file_exists(p) != _trip_had:
		return "the trip save %s" % ("appeared" if not _trip_had else "is gone")
	if _bytes(p) != _trip_bytes:
		return "the trip save changed (%d -> %d bytes)" % [_trip_bytes.size(), _bytes(p).size()]
	if FileAccess.file_exists(p + Save.TMP_SUFFIX):
		return "a trip temp file was left"
	return ""

static func _bytes(p: String) -> PackedByteArray:
	if not FileAccess.file_exists(p):
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(p)

# ---------------------------------------------------------------------------------------------------- the end

# the legends of one chapter that are unlocked
static func _unlocked_in(ch: String) -> int:
	var n: int = 0
	for id in LegendsData.legend_ids(ch):
		if Legends.is_unlocked(str(id)):
			n += 1
	return n

# one finished chapter (a _record()): every legend unlocked, every token as won (in memory and in the file), the
# chapter done, its scenes once, the Hall, the replay, that chapter's forced losses and goal tests. Puts the
# chapter's wanted token sum in rec["want"].
func _chapter_checks(rec: Dictionary) -> Array:
	var errs: Array = []
	var ch: String = str(rec["chapter"])
	var ids: Array = LegendsData.legend_ids(ch)
	var per: int = LegendsData.tokens_for(_level)
	var disk: Dictionary = LegendsSave.read()
	var dt: Dictionary = disk.get("tokens", {})
	var sum: int = 0
	for id in ids:
		var k: String = Legends.challenge_key(str(id))
		var want: int = per
		if k == str(rec["replay_key"]) and bool(rec["replay_done"]):
			want = maxi(per, LegendsData.tokens_for(str(rec["replay_level"])))
		if not Legends.is_unlocked(str(id)) or not (disk.get("unlocked", []) as Array).has(str(id)):
			errs.append("%s not unlocked" % id)
		if Legends.token_best(k) != want or int(dt.get(k, 0)) != want:
			errs.append("%s tokens %d (file %d), want %d" % [k, Legends.token_best(k), int(dt.get(k, 0)), want])
		sum += want
		var us: String = str(LegendsData.legend(str(id)).get("unlock_scene", ""))
		if us != "" and StoryText.has_scene(us) and _scenes.count(us) != 1:
			errs.append("unlock scene %s shown %d times" % [us, _scenes.count(us)])
	var fk: String = Legends.finale_key(ch)
	if Legends.token_best(fk) != per or int(dt.get(fk, 0)) != per:
		errs.append("%s tokens %d, want %d" % [fk, Legends.token_best(fk), per])
	sum += per
	rec["want"] = sum
	if Legends.chapter_tokens(ch) != sum:
		errs.append("chapter tokens %d, want %d" % [Legends.chapter_tokens(ch), sum])
	if not Legends.chapter_done(ch) or not (disk.get("finales", []) as Array).has(ch):
		errs.append("the chapter is not done")
	var row: Dictionary = LegendsData.chapter(ch)
	var scenes: Array = [str(row.get("intro_scene", ""))]
	var fs: Dictionary = row.get("finale_scenes", {})
	scenes.append(str(fs.get("before", "")))
	scenes.append(str(fs.get("after", "")))
	for sc in scenes:
		if sc != "" and StoryText.has_scene(sc) and _scenes.count(sc) != 1:
			errs.append("scene %s shown %d times" % [sc, _scenes.count(sc)])
	if HALL_TEST and not bool(rec["hall_done"]):
		errs.append("the Hall was not visited")
	if REPLAY_TEST and not bool(rec["replay_done"]):
		errs.append("the replay did not run")
	var forced_due: int = 0
	for n in _force:
		if int(n) <= int(rec["games"]):
			forced_due += 1
	if int(rec["losses_forced"]) != forced_due:
		errs.append("forced losses %d of %d" % [int(rec["losses_forced"]), forced_due])
	if not _play and GOAL_TESTS and int(rec["goal_tests"]) != 2:
		errs.append("goal tests %d of 2" % int(rec["goal_tests"]))
	if str(rec["retry_key"]) != "":
		errs.append("%s was never retried" % str(rec["retry_key"]))
	return errs

func _end() -> void:
	_records.append(_record())
	var many: bool = _records.size() > 1
	var bad: bool = false
	var total_want: int = 0
	var t_losses: int = 0
	var t_goals: int = 0
	var t_retries: int = 0
	var parts: Array = []
	for rec in _records:
		var ch: String = str(rec["chapter"])
		var errs: Array = _chapter_checks(rec)
		if not many:
			# one chapter: the whole run's checks on this line (as in Phase 9)
			if Legends.real_tokens_total() != int(rec["want"]):
				errs.append("token total %d, want %d" % [Legends.real_tokens_total(), int(rec["want"])])
			if not _gate_line:
				errs.append("the next chapter's gate was not checked")
			var t1: String = _trip_check()
			if t1 != "":
				errs.append(t1)
		total_want += int(rec["want"])
		t_losses += int(rec["losses_forced"])
		t_goals += int(rec["goal_tests"])
		t_retries += int(rec["retries"])
		parts.append("%s %d/%d" % [ch, Legends.chapter_tokens(ch), Legends.chapter_max_tokens(ch)])
		var rk: String = str(rec["replay_key"])
		print("LEGENDS checks%s | level %s | tokens %d/%d | unlocked %d/%d | chapter done %s | scenes %d | goal tests %d | forced losses %d | retries %d | replay %s | hall %s | trip save %s | %s" % [
				(" " + ch) if many else "", _level, Legends.chapter_tokens(ch), Legends.chapter_max_tokens(ch),
				_unlocked_in(ch), LegendsData.legend_ids(ch).size(), str(Legends.chapter_done(ch)), _scenes.size(),
				int(rec["goal_tests"]), int(rec["losses_forced"]), int(rec["retries"]),
				("%s at %s -> %d" % [rk, str(rec["replay_level"]), Legends.token_best(rk)]) if bool(rec["replay_done"])
				else "-", "ok" if bool(rec["hall_done"]) else "-", "unchanged" if _trip_check() == "" else "CHANGED",
				"ok" if errs.is_empty() else "WRONG: " + "; ".join(PackedStringArray(errs))])
		if not errs.is_empty():
			bad = true
	if many:
		var errs2: Array = []
		if Legends.real_tokens_total() != total_want:
			errs2.append("token total %d, want %d" % [Legends.real_tokens_total(), total_want])
		if not _gate_line:
			errs2.append("the next chapter's gate was not checked")
		for ch in LegendsData.built_chapters():
			var played: bool = false
			for rec in _records:
				played = played or str(rec["chapter"]) == str(ch)
			if Legends.chapter_done(str(ch)) != played:
				errs2.append("chapter %s done %s, played %s" % [str(ch), str(Legends.chapter_done(str(ch))), str(played)])
		var t2: String = _trip_check()
		if t2 != "":
			errs2.append(t2)
		print("LEGENDS checks total | chapters %d | tokens %d/%d (%s) | trip save %s | %s" % [_records.size(),
				Legends.real_tokens_total(), LegendsData.max_tokens(), ", ".join(PackedStringArray(parts)),
				"unchanged" if t2 == "" else "CHANGED",
				"ok" if errs2.is_empty() else "WRONG: " + "; ".join(PackedStringArray(errs2))])
		if not errs2.is_empty():
			bad = true
	# P12-18: the ending: once after the last finale when every row is built and won (and once more from the Hall's
	# banner), never otherwise
	var want_full: bool = not LegendsData.chapter_ids().is_empty()
	for ch in LegendsData.chapter_ids():
		want_full = want_full and LegendsData.is_built(str(ch)) and Legends.chapter_done(str(ch))
	var want_scene: bool = want_full and Legends.complete_scene() != ""
	var errs3: Array = []
	if Legends.legends_complete() != want_full:
		errs3.append("legends_complete() %s, want %s" % [str(Legends.legends_complete()), str(want_full)])
	if _ending_game != (1 if want_scene else 0) or _scenes.count(Legends.COMPLETE_SCENE) != (1 + _ending_hall if want_scene else 0) \
			or _ending_hall != (1 if want_scene and HALL_TEST else 0):
		errs3.append("the ending after a game %d, from the Hall %d, shown %d" % [_ending_game, _ending_hall,
				_scenes.count(Legends.COMPLETE_SCENE)])
	if Legends.has_seen(Legends.COMPLETE_SCENE) != want_scene or _complete_seen != want_full:
		errs3.append("ending seen %s, timeline complete %s" % [str(Legends.has_seen(Legends.COMPLETE_SCENE)),
				str(_complete_seen)])
	print("LEGENDS complete | %s | ending after the last finale %d, from the Hall %d | timeline %s | %s" % [
			str(want_full), _ending_game, _ending_hall, str(_complete_seen), "ok" if errs3.is_empty() else
			"WRONG: " + "; ".join(PackedStringArray(errs3))])
	if not errs3.is_empty():
		bad = true
	if bad:
		_fail("the finished chapter%s not check out" % ("s do" if many else " does"))
		return
	print("LEGENDS END | crew %s | level %s | games %d (forced losses %d, goal tests %d, retries %d) | screens %d | results checked %d%s" % [
			_crew_want, _level, _games, t_losses, t_goals, t_retries, _screens, _results,
			(" | chapters " + ", ".join(PackedStringArray(parts))) if many else ""])
	_quit(0)

func _state() -> String:
	return "phase %s | tokens %d | unlocked %d | done %s" % [_phase, Legends.real_tokens_total(),
			Legends.unlocked_ids().size(), str(Legends.chapter_done(_chapter)) if _chapter != "" else "-"]

func _fail(why: String) -> void:
	if _finished:
		return
	print("LEGENDS ERROR: %s | %s" % [why, _state()])
	push_error("LEGENDS ERROR: " + why)
	_quit(1)

func _quit(code: int) -> void:
	_finished = true
	get_tree().quit(code)
