extends RefCounted
# Easy / Normal / Hard (P3-03). Used through preload, no instance needed:
#   const Difficulty = preload("res://scripts/difficulty.gd")
#   var q: float = Difficulty.value(team, "shot_quality_min", CPU_SHOT_QUALITY_MIN)
# Every CPU skill knob is read through value() at its point of use. Hard (today's CPU) returns the script's own
# constant untouched, and so does the human's team (team 0) on every level: only the other team gets weaker.
# The choice is saved in user://settings.cfg; --difficulty easy|normal|hard (or --difficulty=normal) overrides it.

const EASY := 0
const NORMAL := 1
const HARD := 2
const NAMES := ["easy", "normal", "hard"]

const CPU_TEAM := 1                   # the only team the level changes (team 0 is the human's, on every level)
const SAVE_PATH := "user://settings.cfg"
const SAVE_SECTION := "settings"
const SAVE_KEY := "difficulty"

# PLACEHOLDER VALUES until the owner answers Q6 (real tuning is P3-10). Each entry is [mode, amount] applied to the
# Hard value: "mul" multiplies it, "add" adds to it (seconds for reaction times). A key missing here = the Hard value,
# so a later Hard retune carries over to Normal and Easy.
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
#   speed_mult            movement speed multiplier (Q6 b; 1.0 on every level until answered)
#   stamina_drain         stamina per second while sprinting (player.STAMINA_DRAIN; Q6 b, Hard on every level)
const LEVELS := {
	NORMAL: {
		"shot_quality_min": ["mul", 0.92],
		"shot_quality_max": ["mul", 0.92],
		"cross_react_min": ["add", 0.05],
		"cross_react_max": ["add", 0.05],
		"jump_react_min": ["add", 0.05],
		"jump_react_max": ["add", 0.05],
		"jump_chance": ["mul", 0.85],
		"jumper_jump_chance": ["mul", 0.85],
		"lob_jump_chance": ["mul", 0.85],
		"poke_chance": ["mul", 0.85],
		"poke_on_time": ["mul", 0.7],
		"fake_bite": ["mul", 1.3],
		"help_side": ["mul", 0.7],
		"speed_mult": ["mul", 1.0],
		"stamina_drain": ["mul", 1.0],
	},
	EASY: {
		"shot_quality_min": ["mul", 0.84],
		"shot_quality_max": ["mul", 0.84],
		"cross_react_min": ["add", 0.1],
		"cross_react_max": ["add", 0.1],
		"jump_react_min": ["add", 0.1],
		"jump_react_max": ["add", 0.1],
		"jump_chance": ["mul", 0.7],
		"jumper_jump_chance": ["mul", 0.7],
		"lob_jump_chance": ["mul", 0.7],
		"poke_chance": ["mul", 0.7],
		"poke_on_time": ["mul", 0.4],
		"fake_bite": ["mul", 1.6],
		"help_side": ["mul", 0.4],
		"speed_mult": ["mul", 1.0],
		"stamina_drain": ["mul", 1.0],
	},
}

static var level := HARD              # survives reload_current_scene()
static var _inited := false

# The level's value for `key`, given today's (Hard) value. Hard, and the human's team on any level, get hard_value.
static func value(team: int, key: String, hard_value: float) -> float:
	if team != CPU_TEAM or level == HARD:
		return hard_value
	var table: Dictionary = LEVELS.get(level, {})
	if not table.has(key):
		return hard_value
	var rule: Array = table[key]
	var amount: float = float(rule[1])
	if String(rule[0]) == "add":
		return hard_value + amount
	return hard_value * amount

static func level_name() -> String:
	return String(NAMES[clampi(level, EASY, HARD)])

# "easy" / "normal" / "hard" -> the level, or -1
static func parse(s: String) -> int:
	return NAMES.find(s.strip_edges().to_lower())

# Reads the saved level (keeps the current one if nothing is saved yet).
static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var lv: int = parse(str(cfg.get_value(SAVE_SECTION, SAVE_KEY, level_name())))
	if lv >= 0:
		level = lv

static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)   # keep any other settings in the file
	cfg.set_value(SAVE_SECTION, SAVE_KEY, level_name())
	cfg.save(SAVE_PATH)

# Test override: --difficulty easy|normal|hard or --difficulty=easy. Without it, --autoplay and --humantest play Hard
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
			level = lv
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
