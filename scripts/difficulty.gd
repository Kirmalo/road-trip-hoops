extends RefCounted
# Easy / Normal / Hard (P3-03). Used through preload, no instance needed:
#   const Difficulty = preload("res://scripts/difficulty.gd")
#   var q: float = Difficulty.value(team, "shot_quality_min", CPU_SHOT_QUALITY_MIN)
# Every CPU skill knob is read through value() at its point of use. Hard (today's CPU) returns the script's own
# constant untouched, and so does the human's team (team 0) on every level: only the other team gets weaker.
# The choice is saved in user://settings.cfg; --difficulty easy|normal|hard (or --difficulty=normal) overrides it.
# P8-19: a 4th level, LEGEND (open at 72 stars): the Hard values, plus rating_bonus() on the opponents' ratings.

const Flow = preload("res://scripts/flow.gd")         # Flow.match: the trip game's level and team styles (P5-03)
const Ratings = preload("res://scripts/ratings.gd")   # Ratings.style_mult(): play style multipliers
const Cities = preload("res://scripts/cities.gd")     # the crews Quick Game can field (P6-T3)
const Save = preload("res://scripts/save.gd")         # Save.path(): a trip test run keeps its unlocks in a test file
const Stars = preload("res://scripts/stars.gd")       # legend_open(): LEGEND is offered at 72 stars (P8-19; stars.gd
                                                      # loads this script only at call time, so no preload cycle)

const EASY := 0
const NORMAL := 1
const HARD := 2
const LEGEND := 3                     # P8-19: the Hard CPU values plus LEGEND_BONUS on the opponents' ratings
const NAMES := ["easy", "normal", "hard", "legend"]
const LEGEND_BONUS := 12              # added to every stat of the opponents on LEGEND (P8-25: 6 -> 12; +6 played like Hard)
const LEGEND_CAP := 95                # no stat goes over this with the bonus (Quick Game; trip.gd has its own BOSS_CAP)

const CPU_TEAM := 1                   # the only team the level changes (team 0 is the human's, on every level)
const SAVE_PATH := "user://settings.cfg"
const SAVE_SECTION := "settings"
const SAVE_KEY := "difficulty"
# P6-17 (owner Q9): Quick Game court unlocks. A city's court unlocks when its boss game is won on any Road Trip
# (trip.gd calls unlock_court(city)); kept for good (a new trip doesn't lock it again), saved here with the settings,
# not in the trip save. Test flags: --unlock-all (every city open), --unlock-none (a fresh install; nothing saved is read).
const UNLOCK_KEY := "unlocked_courts"    # an Array of city ids in SAVE_SECTION
const UNLOCK_ALL_FLAG := "--unlock-all"
const UNLOCK_NONE_FLAG := "--unlock-none"
# P6-T3 (owner): Quick Game team pick. A city crew is a Quick Game team once its boss game is won on any Road Trip
# (trip.gd calls unlock_team() at the same moment as unlock_court()); each New York bracket crew once you beat it in
# its round. The Cornfield Kings (your crew) and the Bridge Runners are always open. Kept for good, like the courts;
# --unlock-all / --unlock-none cover the teams too. Trip test runs (Save.path() is the test save) read and write both
# kinds of unlock in UNLOCK_TEST_PATH, never the owner's settings.
const TEAM_UNLOCK_KEY := "unlocked_teams"   # an Array of crew ids in SAVE_SECTION
const UNLOCK_TEST_PATH := "user://settings_test.cfg"
const KINGS := "cornfield_kings"            # crew ids: the crew name in lower case, "_" for spaces
const RUNNERS := "bridge_runners"
const ALWAYS_TEAMS := [KINGS, RUNNERS]
const KINGS_UI_COLOR := Color(0.16, 0.3, 0.6)   # your crew's blue (cities.gd gives each city crew a ui_color)
# P11-33 (owner P8 b): the era teams (era_teams.gd, loaded at run time: it loads this script, so no preload) join the
# Quick Game lists after the crews once open (EraTeams.is_open(): its own three unlocked in the Legends file, or
# --unlock-all; --unlock-none closes them). all_teams() stays the crews only (the trip's unlocks never see an era id).
const ERA_TEAMS_PATH := "res://scripts/era_teams.gd"

# P3-10 values (owner Q6: the CPU is less sharp, not slower: worse shooting, slower reactions, worse steal/block
# timing, bites on fakes more, less help defense; speed and stamina stay Hard on every level). Each entry is
# [mode, amount] applied to the Hard value: "mul" multiplies it, "add" adds to it (seconds for reaction times). A key
# missing here = the Hard value, so a later Hard retune carries over to Normal and Easy.
# Tuned with --autoplay --difficulty=<level> (RED plays the level, BLUE plays Hard), 40 games each:
# RED won 62% on Hard, 30% on Normal, 20% on Easy, and still used every move on Easy.
# Keys (and where they are read):
#   shot_quality_min/max  CPU jump-shot quality range (player.CPU_SHOT_QUALITY_MIN/MAX)
#   cross_react_min/max   seconds a defender keeps going the old way after a crossover (defense.CPU_CROSS_REACT_*)
#   cross_beat_react      a reaction slower than this is beaten (defense.CPU_CROSS_BEAT_REACT)
#   jump_react_min/max    block-jump reaction delay (defense.CPU_JUMP_REACT_*)
#   jump_chance           jump at a dunk/layup (defense.CPU_JUMP_CHANCE)
#   jumper_jump_chance    jump at a jump shot (defense.CPU_JUMPER_JUMP_CHANCE)
#   lob_jump_chance       read a lob and jump at the dunk (player.CPU_LOB_JUMP_CHANCE)
#   poke_chance           go for an exposed ball (defense.CPU_POKE_CHANCE)
#   poke_on_time          time the poke on the floor touch (defense.CPU_POKE_ON_TIME)
#   fake_bite             jump at a pump fake (defense.CPU_FAKE_BITE)
#   help_side             off-ball lean toward the ball (defense.HELP_SIDE)
#   cross_beat_human      chance a CPU crossover beats a human defender caught leaning the wrong way (1.0 on Hard)
#   speed_mult            movement speed multiplier (Q6 b; 1.0 on every level until answered)
#   stamina_drain         stamina per second while sprinting (player.STAMINA_DRAIN; Q6 b, Hard on every level)
# Offense tendencies read through value() too (P5-03; no level entry, so only a play style changes them):
#   three_chance / pullup_chance / lob_chance / cut_chance / kick_chance   player.CPU_THREE_CHANCE ... CPU_KICK_CHANCE
const LEVELS := {
	NORMAL: {
		"shot_quality_min": ["mul", 0.94],   # jumpers a bit off (Hard 1.05..1.25 -> ~0.99..1.18)
		"shot_quality_max": ["mul", 0.94],
		"cross_react_min": ["add", 0.04],    # a step slower to read a crossover (beaten more often)
		"cross_react_max": ["add", 0.04],
		"jump_react_min": ["add", 0.04],     # block jumps a little late
		"jump_react_max": ["add", 0.04],
		"jump_chance": ["mul", 0.9],
		"jumper_jump_chance": ["mul", 0.9],
		"lob_jump_chance": ["mul", 0.9],
		"poke_chance": ["mul", 0.9],
		"poke_on_time": ["mul", 0.75],       # fewer pokes timed on the floor touch
		"fake_bite": ["mul", 1.4],           # bites on pump fakes more (P3-12: was 1.25; the slower jump_react cancelled it)
		"help_side": ["mul", 0.75],          # less help defense
		"cross_beat_human": ["mul", 0.75],   # a CPU crossover beats a wrong-footed human 75% of the time (Hard: always)
		"speed_mult": ["mul", 1.0],          # owner Q6: less sharp, not slower (Hard on every level)
		"stamina_drain": ["mul", 1.0],
	},
	EASY: {
		"shot_quality_min": ["mul", 0.83],   # Hard 1.05..1.25 -> ~0.87..1.04
		"shot_quality_max": ["mul", 0.83],
		"cross_react_min": ["add", 0.08],
		"cross_react_max": ["add", 0.08],
		"jump_react_min": ["add", 0.06],
		"jump_react_max": ["add", 0.06],
		"jump_chance": ["mul", 0.8],
		"jumper_jump_chance": ["mul", 0.8],
		"lob_jump_chance": ["mul", 0.8],
		"poke_chance": ["mul", 0.8],
		"poke_on_time": ["mul", 0.55],
		"fake_bite": ["mul", 1.8],
		"help_side": ["mul", 0.5],
		"cross_beat_human": ["mul", 0.5],
		"speed_mult": ["mul", 1.0],
		"stamina_drain": ["mul", 1.0],
	},
}

static var level := HARD              # survives reload_current_scene(); the saved / chosen level
static var _inited := false

# P5-03: a trip game (Flow.match, board "Match config") may set its own level ("level": "normal"; "" or absent = the
# saved level above) and a play style per team ("style": "inside" / "outside" / "balanced" / ""). The style
# multiplies CPU tendency keys (Ratings.STYLES) after the level rule, for CPU_TEAM only. Quick Game (Flow.match
# empty) has neither, so value() returns exactly what it did before.
# (`match` is a GDScript keyword: always written Flow.match, with the dot.)
const STYLE_TEAM := CPU_TEAM
static var quick_styles: Array = []   # Quick Game: [blue style, red style] of the picked crews ("" = none)          # the only team a play style changes (board: "Play style (team 1 only)")

# The level's value for `key`, given today's (Hard) value. Hard, and the human's team on any level, get hard_value;
# then team 1's play style (if any) multiplies it.
static func value(team: int, key: String, hard_value: float) -> float:
	if team != CPU_TEAM:
		return hard_value
	var v: float = _level_value(effective_level(), key, hard_value)
	if team == STYLE_TEAM:
		v *= Ratings.style_mult(team_style(team), key)
	return v

static func _level_value(lv: int, key: String, hard_value: float) -> float:
	if lv == HARD or lv == LEGEND:   # LEGEND plays the Hard values; its edge is rating_bonus()
		return hard_value
	var table: Dictionary = LEVELS.get(lv, {})
	if not table.has(key):
		return hard_value
	var rule: Array = table[key]
	var amount: float = float(rule[1])
	if String(rule[0]) == "add":
		return hard_value + amount
	return hard_value * amount

# The level this game plays: Flow.match.level when a trip game sets one, else the saved / chosen level.
static func effective_level() -> int:
	var m: Dictionary = Flow.match
	if m.is_empty():
		return level
	var lv: int = parse(str(m.get("level", "")))
	return lv if lv >= 0 else level

# A team's play style from Flow.match ("" in Quick Game or when the match doesn't name one).
static func team_style(team: int) -> String:
	var m: Dictionary = Flow.match
	if m.is_empty():
		# Quick Game: the picked crews' road-trip styles (owner, Phase 6 tuning check-in); set by main.gd
		return str(quick_styles[team]) if team >= 0 and team < quick_styles.size() else ""
	var teams: Array = m.get("teams", [])
	if team < 0 or team >= teams.size() or not (teams[team] is Dictionary):
		return ""
	var t: Dictionary = teams[team]
	return str(t.get("style", ""))

# The name of a level (default: the saved / chosen one, which is what save() writes).
static func level_name(lv: int = -1) -> String:
	if lv < 0:
		lv = level
	return String(NAMES[clampi(lv, EASY, LEGEND)])

# "easy" / "normal" / "hard" / "legend" -> the level, or -1
static func parse(s: String) -> int:
	return NAMES.find(s.strip_edges().to_lower())

# P8-19: the rating bonus the opponents get on a level (a level int or name): LEGEND_BONUS on LEGEND, else 0.
# trip.gd's city_ratings() adds it (capped at its BOSS_CAP); bonus_ratings() below does the same for Quick Game.
static func rating_bonus(lv) -> int:
	var i: int = -1
	if lv is int:
		i = lv
	else:
		i = parse(str(lv))
	return LEGEND_BONUS if i == LEGEND else 0

# a copy of a ratings dict with rating_bonus(lv) added to every number, each capped at `cap` (never lowered by the cap)
static func bonus_ratings(ratings: Dictionary, lv, cap: int = LEGEND_CAP) -> Dictionary:
	var out: Dictionary = ratings.duplicate()
	var b: int = rating_bonus(lv)
	if b == 0:
		return out
	for k in out.keys():
		var v = out[k]
		if v is int or v is float:
			var n: int = int(v)
			out[k] = maxi(n, mini(n + b, cap))
	return out

# LEGEND only once the stars open it (Stars.legend_open()); a closed LEGEND plays Hard
static func open_level(lv: int) -> int:
	if lv == LEGEND and not Stars.legend_open():
		return HARD
	return lv

# the levels a picker offers: Easy, Normal, Hard, and LEGEND once the stars open it
static func offered_levels() -> Array:
	var out: Array = [EASY, NORMAL, HARD]
	if Stars.legend_open():
		out.append(LEGEND)
	return out

# Reads the saved level (keeps the current one if nothing is saved yet). An unknown name loads as Normal; a saved
# "legend" while LEGEND isn't open (e.g. the stars were reset) loads as Hard.
static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	if not cfg.has_section_key(SAVE_SECTION, SAVE_KEY):
		return
	var lv: int = parse(str(cfg.get_value(SAVE_SECTION, SAVE_KEY, "")))
	level = open_level(lv) if lv >= 0 else NORMAL

static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)   # keep any other settings in the file
	cfg.set_value(SAVE_SECTION, SAVE_KEY, level_name())
	cfg.save(SAVE_PATH)

# Test override: --difficulty easy|normal|hard|legend (legend needs the stars: --stars 72) or --difficulty=easy. Without it, --autoplay and --humantest play Hard
# (so numbers compare with Phase 2). Returns true if the command line set the level.
static func from_cmdline() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		var a: String = args[i]
		var lv := -1
		if a.begins_with("--difficulty="):
			lv = parse(a.substr("--difficulty=".length()))
		elif a == "--difficulty" and i + 1 < args.size():
			lv = parse(args[i + 1])
		if lv >= 0:
			level = open_level(lv)
			if level != lv:
				print("--difficulty legend: LEGEND isn't open (72 stars; try --stars 72), playing hard")
			return true
	if args.has("--autoplay") or args.has("--humantest"):
		level = HARD
	return false

# Once per run (player.gd calls it; safe to call from main.gd too): the saved level, then the command line.
static func init_once() -> void:
	if _inited:
		return
	_inited = true
	load_saved()
	from_cmdline()

# ---------------- Quick Game court unlocks (P6-17) ----------------

# A won boss game (trip.gd): the city's court is open in Quick Game from now on. Saved at once; a city already open
# changes nothing.
static func unlock_court(city_id: String) -> void:
	if city_id == "":
		return
	var path: String = unlock_path()
	var cfg := ConfigFile.new()
	cfg.load(path)   # keep the other settings in the file
	var got: Array = _as_ids(cfg.get_value(SAVE_SECTION, UNLOCK_KEY, []))
	if got.has(city_id):
		return
	got.append(city_id)
	cfg.set_value(SAVE_SECTION, UNLOCK_KEY, got)
	cfg.save(path)
	print("COURT UNLOCKED %s" % city_id)

# The city ids whose court is open (saved; every city in `all_ids` under --unlock-all, none under --unlock-none)
static func unlocked_cities(all_ids: Array = []) -> Array:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has(UNLOCK_ALL_FLAG):
		return all_ids.duplicate()
	if args.has(UNLOCK_NONE_FLAG):
		return []
	var cfg := ConfigFile.new()
	if cfg.load(unlock_path()) != OK:
		return []
	return _as_ids(cfg.get_value(SAVE_SECTION, UNLOCK_KEY, []))

static func is_court_unlocked(city_id: String) -> bool:
	return unlocked_cities([city_id]).has(city_id)

# the file the unlocks (courts and teams) live in: the settings, or the test file in a trip test run
static func unlock_path() -> String:
	return UNLOCK_TEST_PATH if Save.path() == Save.TEST_PATH else SAVE_PATH

# ---------------- Quick Game teams (P6-T3) ----------------

# a crew's id from its name: "BAYOU BRASS" -> "bayou_brass"
static func crew_id(crew_name: String) -> String:
	return crew_name.strip_edges().to_lower().replace(" ", "_")

# Every crew Quick Game knows, in route order: {"id", "name", "city" ("" = your crew), "game" (the city game or New
# York round whose lineup it plays: a city's boss game, 3), "color" (its ui color)}. The Kings first.
static func all_teams() -> Array:
	var out: Array = [{"id": KINGS, "name": Cities.CREW_NAME, "city": "", "game": 0, "color": KINGS_UI_COLOR}]
	for cid in Cities.built_route():
		var c: Dictionary = Cities.city(cid)
		if bool(c.get("tournament", false)):
			var rs: Array = c.get("rounds", [])
			for i in rs.size():
				var rcrew: Dictionary = (rs[i] as Dictionary).get("crew", {})
				out.append({"id": crew_id(str(rcrew.get("name", ""))), "name": str(rcrew.get("name", "")), "city": cid,
						"game": i + 1, "color": rcrew.get("ui_color", Color.GRAY)})
		else:
			var crew: Dictionary = c.get("crew", {})
			out.append({"id": crew_id(str(crew.get("name", ""))), "name": str(crew.get("name", "")), "city": cid,
					"game": 3, "color": crew.get("ui_color", Color.GRAY)})
	return out

# one crew's entry of all_teams(), or an era team's EraTeams.info() entry ("era": true, P11-33); {} for an unknown id
static func team_info(id: String) -> Dictionary:
	for t in all_teams():
		if str((t as Dictionary)["id"]) == id:
			return t
	var et: GDScript = _era_teams()
	if et != null and bool(et.call("is_era_id", id)):
		return et.call("info", id)
	return {}

# era_teams.gd, or null when it is missing (then there are no era teams)
static func _era_teams() -> GDScript:
	if not ResourceLoader.exists(ERA_TEAMS_PATH):
		return null
	var g: GDScript = load(ERA_TEAMS_PATH) as GDScript
	if g == null or not g.has_method("is_era_id") or not g.has_method("is_open") or not g.has_method("info"):
		return null
	return g

# an era team id (never a crew id; never unlocked or saved here)
static func is_era_team(id: String) -> bool:
	var et: GDScript = _era_teams()
	return et != null and bool(et.call("is_era_id", id))

# the crew a won game unlocks (trip.gd): a city's crew (any n), or New York round n's crew; "" if none
static func team_of(city_id: String, n: int) -> String:
	for t in all_teams():
		var d: Dictionary = t
		if str(d["city"]) != city_id:
			continue
		if not bool(Cities.city(city_id).get("tournament", false)) or int(d["game"]) == n:
			return str(d["id"])
	return ""

# A beaten crew (trip.gd): a Quick Game team from now on. Saved at once; a crew already open changes nothing.
static func unlock_team(id: String) -> void:
	if id == "" or ALWAYS_TEAMS.has(id) or team_info(id).is_empty() or is_era_team(id):
		return
	var path: String = unlock_path()
	var cfg := ConfigFile.new()
	cfg.load(path)   # keep the other settings in the file
	var got: Array = _as_ids(cfg.get_value(SAVE_SECTION, TEAM_UNLOCK_KEY, []))
	if got.has(id):
		return
	got.append(id)
	cfg.set_value(SAVE_SECTION, TEAM_UNLOCK_KEY, got)
	cfg.save(path)
	print("TEAM UNLOCKED %s" % id)

# open in Quick Game: always the Kings and the Bridge Runners; every known crew under --unlock-all, only those two
# under --unlock-none; else the saved unlocks. An era team: EraTeams.is_open() (the Legends file's rule and the same
# two flags; never this file)
static func team_unlocked(id: String) -> bool:
	if ALWAYS_TEAMS.has(id):
		return true
	if team_info(id).is_empty():
		return false
	if is_era_team(id):
		return bool(_era_teams().call("is_open", id))
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has(UNLOCK_ALL_FLAG):
		return true
	if args.has(UNLOCK_NONE_FLAG):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(unlock_path()) != OK:
		return false
	return _as_ids(cfg.get_value(SAVE_SECTION, TEAM_UNLOCK_KEY, [])).has(id)

# the crew ids the Quick Game pickers offer, in all_teams() order, then the open era teams in timeline order (P11-33)
static func quick_teams() -> Array:
	var out: Array = []
	for t in all_teams():
		var id: String = str((t as Dictionary)["id"])
		if team_unlocked(id):
			out.append(id)
	var et: GDScript = _era_teams()
	if et != null and et.has_method("open_ids"):
		for eid in et.call("open_ids"):
			if not out.has(str(eid)):
				out.append(str(eid))
	return out

static func _as_ids(v) -> Array:
	var out: Array = []
	if v is Array:
		for x in v:
			out.append(str(x))
	return out

# ---------------- Full screen (P6-T2) ----------------
# The FULL SCREEN button (title.gd's Settings, pause.gd's panel) calls set_fullscreen(), which switches at once (inside
# the tap, as a browser needs) and saves the choice. The label shows is_fullscreen(), the real state, so leaving with
# the browser (Esc, back gesture) shows OFF without changing the saved choice. A browser can't enter full screen at
# page load, so restore_fullscreen() (title.gd and pause.gd call it on a finger / mouse release) puts a saved ON back on
# the first tap of the run, once. Where full screen isn't supported nothing happens (the label stays OFF).
const FULLSCREEN_KEY := "fullscreen"     # bool in SAVE_SECTION

static var _fs_restored := false         # restore_fullscreen() has had its one try this run

static func fullscreen_saved() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return bool(cfg.get_value(SAVE_SECTION, FULLSCREEN_KEY, false))

static func save_fullscreen(on: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)   # keep the other settings in the file
	cfg.set_value(SAVE_SECTION, FULLSCREEN_KEY, on)
	cfg.save(SAVE_PATH)

static func is_fullscreen() -> bool:
	var m: int = DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

# The button: switch now and remember it. No window (headless) = nothing to switch; the choice is still saved.
static func set_fullscreen(on: bool) -> void:
	_fs_restored = true   # the player chose: no restore after this
	save_fullscreen(on)
	apply_fullscreen(on)

# Once per run, on the first tap: a saved ON goes back to full screen (the tap is the browser's user gesture).
static func restore_fullscreen() -> void:
	if _fs_restored:
		return
	_fs_restored = true
	if fullscreen_saved() and not is_fullscreen():
		apply_fullscreen(true)

static func apply_fullscreen(on: bool) -> void:
	if DisplayServer.get_name() == "headless" or on == is_fullscreen():
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

# a finger or mouse button let go (Chromium counts a release as the user gesture; a touch press isn't one)
static func is_release_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		return not (event as InputEventMouseButton).pressed
	return false

# ---------------- Left-handed layout and run-only test flags (P7-01) ----------------
# LEFT-HANDED (Settings, P7-04) puts the joystick on the right and A/B on the left (touch_controls.gd, P7-03). Saved as
# `left_handed` in SAVE_SECTION of SAVE_PATH; a fresh install reads false (today's right-handed layout).
# Test runs never write the owner's file: a run with any command-line user argument (every test mode passes one) keeps
# set_left_handed() for this run only, and reads false instead of the saved choice, so every test mode without the
# flags plays today's layout. --left-handed / --right-handed set the layout for this run and win over everything.
# --music-volume X (0..1) is only parsed here and kept in music_volume_flag for audio.gd (P7-02; < 0 = no flag).
const LEFT_HANDED_KEY := "left_handed"          # bool in SAVE_SECTION
const LEFT_HANDED_FLAG := "--left-handed"       # this run only, never saved
const RIGHT_HANDED_FLAG := "--right-handed"     # this run only, never saved
const MUSIC_VOLUME_FLAG := "--music-volume"     # --music-volume X or --music-volume=X, X in 0..1

# the --music-volume value for this run (0..1), -1.0 = no flag; read when the script loads, so it is set before any use
static var music_volume_flag: float = parse_music_volume_flag()
static var _lh_inited := false                  # the saved choice (or the test-run default) has been read
static var _left_handed := false                # the choice this run (saved, or set this run)

# true when the layout is mirrored for the left hand. The flags win; else the choice made this run; else the saved one
# (test runs: false).
static func is_left_handed() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has(LEFT_HANDED_FLAG):
		return true
	if args.has(RIGHT_HANDED_FLAG):
		return false
	if not _lh_inited:
		_lh_inited = true
		_left_handed = false if is_test_run() else left_handed_saved()
	return _left_handed

# The LEFT-HANDED switch: takes effect from the next game (touch_controls reads it in _ready()) and is saved at once;
# a test run keeps it for the run only.
static func set_left_handed(on: bool) -> void:
	_lh_inited = true
	_left_handed = on
	if is_test_run():
		return
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)   # keep the other settings in the file
	cfg.set_value(SAVE_SECTION, LEFT_HANDED_KEY, on)
	cfg.save(SAVE_PATH)

# the choice in settings.cfg (false when there is no file or no key)
static func left_handed_saved() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return bool(cfg.get_value(SAVE_SECTION, LEFT_HANDED_KEY, false))

# a developer / test run: any user argument after "--" (the owner's builds pass none)
static func is_test_run() -> bool:
	return not OS.get_cmdline_user_args().is_empty()

# --music-volume X / --music-volume=X -> X clamped to 0..1; -1.0 without the flag (or with a value that isn't a number)
static func parse_music_volume_flag() -> float:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		var a: String = args[i]
		var s := ""
		if a.begins_with(MUSIC_VOLUME_FLAG + "="):
			s = a.substr(MUSIC_VOLUME_FLAG.length() + 1)
		elif a == MUSIC_VOLUME_FLAG and i + 1 < args.size():
			s = args[i + 1]
		else:
			continue
		if s.is_valid_float():
			return clampf(s.to_float(), 0.0, 1.0)
	return -1.0
