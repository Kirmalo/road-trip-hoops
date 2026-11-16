extends RefCounted
# Player ratings and how each stat maps onto the gameplay (P5-01, board "Ratings and how each stat maps onto the
# gameplay"). Static only, used through preload, no instance needed:
#   const Ratings = preload("res://scripts/ratings.gd")
#   speed = Ratings.speed_px(170.0, rating)        # player speed in px/s
#   prob *= Ratings.shot_mult(rating)              # jump shots and free throws
# All ratings are 0-100; 50 = average = today's players, and rating 50 gives multiplier 1.0 exactly, so Quick Game
# (every rating 50) plays as before. f = (rating - 50) / 50, from -1 to +1.
# Ratings act on both teams the same way and do NOT depend on the difficulty level (difficulty.gd stays CPU sharpness
# for team 1 only). The human's shot meter and timing windows are untouched: ratings only move the odds.
#
# Stats (the five a player has, plus steal and block derived from defense):
#   speed      player speed (170 px/s), so turbo, defense and rim moves scale with it
#   shooting   jump shots (main.shot_probability() result) and free throws (main.FT_BASE)
#   finishing  dunk / layup make chance (player.DUNK_OPEN_PCT, LAYUP_OPEN_PCT) and the dunk speed (DUNK_SPEED_FRAC)
#   defense    no multiplier of its own: steal = defense + steal_bias, block = defense + block_bias (derived()), and the
#              existing steal/block rating code does the rest
#   stamina    sprint drain (player.STAMINA_DRAIN, lower is better) and refill (player.STAMINA_REFILL, higher is better)
# Run the table:  godot --headless --path . -- --ratingtest   (main.gd calls self_test())

const MIN_RATING := 0
const MAX_RATING := 100
const AVG_RATING := 50            # today's players; multiplier 1.0
const SPEED_SPAN := 0.08          # speed x (1 + 0.08 f): 156 / 184 px/s at rating 0 / 100 (base 170)
const SHOOT_SPAN := 0.15          # shot and free-throw chance x (1 + 0.15 f): x0.85 / x1.15
const FINISH_SPAN := 0.12         # dunk / layup make chance x (1 + 0.12 f): x0.88 / x1.12
const DUNK_EASE := 0.05           # dunk speed fraction - 0.05 f: 0.75 / 0.65 at rating 0 / 100 (base 0.7)
const STAM_SPAN := 0.25           # drain x (1 - 0.25 f), refill x (1 + 0.25 f): drain x1.25 / x0.75

const STATS := ["speed", "shooting", "finishing", "defense", "stamina"]   # the five a player raises with points
const DERIVED := ["steal", "block"]                                      # from defense + the player's bias

# Play style (team 1 only; P5-03 applies it inside Difficulty.value() after the level rule). Each style is a small
# table of multipliers on CPU tendency keys; a key missing from the table = 1.0 (no change). "balanced" and "" = no
# change at all, so Quick Game is untouched. Keys and where they are read:
#   three_chance   player.CPU_THREE_CHANCE    pullup_chance  player.CPU_PULLUP_CHANCE
#   lob_chance     player.CPU_LOB_CHANCE      cut_chance     player.CPU_CUT_CHANCE
#   kick_chance    player.CPU_KICK_CHANCE     poke_chance    defense.CPU_POKE_CHANCE
#   help_side      defense.HELP_SIDE (off-ball lean toward the ball)
# Starting values (Phase 6 tunes them).
const STYLES := {
	"inside": {                   # attacks the rim: fewer threes and pull-ups, more cuts and lobs, packs the paint
		"three_chance": 0.6,
		"pullup_chance": 0.7,
		"lob_chance": 1.4,
		"cut_chance": 1.5,
		"kick_chance": 0.7,
		"help_side": 1.2,
	},
	"outside": {                  # shooters: more threes, pull-ups and kick-outs, fewer cuts, gambles for steals
		"three_chance": 1.1,
		"pullup_chance": 1.4,
		"lob_chance": 0.7,
		"cut_chance": 0.7,
		"kick_chance": 1.3,
		"poke_chance": 1.15,
		"help_side": 0.85,
	},
	"balanced": {},
}

# -1..+1 for a rating (clamped to 0-100)
static func f(rating: int) -> float:
	return float(clampi(rating, MIN_RATING, MAX_RATING) - AVG_RATING) / float(AVG_RATING)

# The multiplier a stat puts on its gameplay value. "stamina" is the drain multiplier (lower = lasts longer);
# "stamina_refill" the refill one; "defense" is always 1.0 (it works through steal and block, see derived()).
# Unknown stats give 1.0. Rating 50 gives exactly 1.0 for every stat.
static func mult(stat: String, rating: int) -> float:
	var x: float = f(rating)
	match stat:
		"speed":
			return 1.0 + SPEED_SPAN * x
		"shooting":
			return 1.0 + SHOOT_SPAN * x
		"finishing":
			return 1.0 + FINISH_SPAN * x
		"stamina", "stamina_drain":
			return 1.0 - STAM_SPAN * x
		"stamina_refill":
			return 1.0 + STAM_SPAN * x
	return 1.0

static func speed_px(base: float, rating: int) -> float:
	return base * mult("speed", rating)

static func shot_mult(rating: int) -> float:
	return mult("shooting", rating)

static func finish_mult(rating: int) -> float:
	return mult("finishing", rating)

# good finishers dunk at a lower speed: player.DUNK_SPEED_FRAC - DUNK_EASE x f
static func dunk_speed_frac(base: float, rating: int) -> float:
	return base - DUNK_EASE * f(rating)

static func stamina_drain(base: float, rating: int) -> float:
	return base * mult("stamina_drain", rating)

static func stamina_refill(base: float, rating: int) -> float:
	return base * mult("stamina_refill", rating)

# steal or block from defense and the player's bias (cities.gd steal_bias / block_bias), 0-100
static func derived(defense: int, bias: int) -> int:
	return clampi(defense + bias, MIN_RATING, MAX_RATING)

# A rating from a ratings dictionary, 50 when missing (Quick Game players have no speed/shooting/... entries)
static func get_rating(ratings: Dictionary, stat: String) -> int:
	return int(ratings.get(stat, AVG_RATING))

# The style multiplier for a CPU tendency key; 1.0 for no style, "balanced", or a key the style doesn't list
static func style_mult(style: String, key: String) -> float:
	var table: Dictionary = STYLES.get(style, {})
	return float(table.get(key, 1.0))

# -- --ratingtest: prints the stat table on today's base values and checks rating 50 = 1.0 for every stat.
# Returns true when every check passes. The base values are read from player.gd / main.gd at run time.
static func self_test() -> bool:
	var pc: Dictionary = _consts("res://scripts/player.gd")
	var mc: Dictionary = _consts("res://scripts/main.gd")
	var speed_base: float = 170.0   # player.gd `var speed` (a var, not a constant)
	var dunk_pct: float = float(pc.get("DUNK_OPEN_PCT", 0.82))
	var layup_pct: float = float(pc.get("LAYUP_OPEN_PCT", 0.65))
	var dunk_frac: float = float(pc.get("DUNK_SPEED_FRAC", 0.7))
	var drain: float = float(pc.get("STAMINA_DRAIN", 0.4))
	var refill: float = float(pc.get("STAMINA_REFILL", 0.25))
	var ft_base: float = float(mc.get("FT_BASE", 0.72))
	var cols: Array = [0, 25, 40, 50, 60, 75, 90, 100]
	var head := "RATINGTEST %-22s" % "stat \\ rating"
	for r in cols:
		head += "%8d" % r
	print(head)
	var rows: Array = [
		["speed mult", func(r: int) -> float: return mult("speed", r)],
		["  speed px/s", func(r: int) -> float: return speed_px(speed_base, r)],
		["shooting mult", func(r: int) -> float: return shot_mult(r)],
		["  free throw", func(r: int) -> float: return ft_base * shot_mult(r)],
		["finishing mult", func(r: int) -> float: return finish_mult(r)],
		["  open dunk", func(r: int) -> float: return dunk_pct * finish_mult(r)],
		["  open layup", func(r: int) -> float: return layup_pct * finish_mult(r)],
		["  dunk speed frac", func(r: int) -> float: return dunk_speed_frac(dunk_frac, r)],
		["defense mult", func(r: int) -> float: return mult("defense", r)],
		["  steal (bias +10)", func(r: int) -> float: return float(derived(r, 10))],
		["  block (bias -10)", func(r: int) -> float: return float(derived(r, -10))],
		["stamina mult (drain)", func(r: int) -> float: return mult("stamina", r)],
		["  drain /s", func(r: int) -> float: return stamina_drain(drain, r)],
		["  refill mult", func(r: int) -> float: return mult("stamina_refill", r)],
		["  refill /s", func(r: int) -> float: return stamina_refill(refill, r)],
	]
	for row in rows:
		var line := "RATINGTEST %-22s" % String(row[0])
		var fn: Callable = row[1]
		for r in cols:
			line += "%8.3f" % float(fn.call(r))
		print(line)
	var ok := true
	for stat in STATS + ["stamina_drain", "stamina_refill"]:
		var m: float = mult(stat, AVG_RATING)
		print("RATINGTEST at 50: %-15s %.6f %s" % [stat, m, "ok" if m == 1.0 else "WRONG"])
		if m != 1.0:
			ok = false
	var exact: bool = speed_px(speed_base, 50) == speed_base and dunk_speed_frac(dunk_frac, 50) == dunk_frac \
			and stamina_drain(drain, 50) == drain and stamina_refill(refill, 50) == refill
	if not exact:
		ok = false
	print("RATINGTEST at 50: helpers return the base value exactly: %s" % ("ok" if exact else "WRONG"))
	for style in STYLES:
		var t: Dictionary = STYLES[style]
		var parts: Array = []
		for k in t:
			parts.append("%s x%.2f" % [k, float(t[k])])
		print("RATINGTEST style %-9s %s" % [style, ", ".join(parts) if parts.size() > 0 else "(no change)"])
	if style_mult("", "three_chance") != 1.0 or style_mult("balanced", "lob_chance") != 1.0:
		ok = false
	print("RATINGTEST %s" % ("OK" if ok else "FAILED"))
	return ok

static func _consts(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var s: Script = load(path) as Script
	return s.get_script_constant_map() if s != null else {}
