extends RefCounted
# City twists (Phase 6, P6-01). Static only: `const Twists = preload("res://scripts/twists.gd")`.
# One twist is on per game. main.gd sets it at game build time from Flow.match.twist (the --twist <id> test flag wins)
# and calls new_game() and tick(). Every hook in the sim is one Twists.value(key, default) around today's constant:
# with twist "none" (or a key the twist doesn't list) value() returns `default`, so the game is exactly today's.
# Every twist acts on all players and both teams the same way: nothing here (or in a hook) reads a team.
#
# The owner can edit the numbers below (owner Q1 a "as proposed", Q2 a "fenced cage"). Keys:
#   name, banner, icon       text for the tip-off banner, the trip map and the pause screen (twist_fx draws the icon)
#   long_shot_mult           x make chance of jump shots beyond the arc (main.shot_probability); 1.0 = today
#   inside_mult              x make chance of close shots: jumpers inside main.SHOT_CLOSE_FT, every layup and dunk
#                            (main.shot_probability, P9-08); 1.0 = today
#   foul_mult                x the chance a foul is called: bad block jumps into the shooter and reaching fouls
#                            (defense._foul_roll, defense.try_reach_foul; P9-08); 1.0 = today
#   shot_clock               seconds on the shot clock (main.SHOT_CLOCK_LENGTH, 24 today)
#   speed_mult               x every player's top speed (player.speed, after the speed rating)
#   turbo_mult               the turbo speed multiplier itself (player.TURBO_SPEED_MULT, 1.35 today)
#   stamina_drain_mult       x stamina drain while sprinting (after the stamina rating)
#   stamina_refill_mult      x stamina refill while not sprinting (after the stamina rating)
#   cut_grip                 x acceleration while a hard cut slides (wet court); 1.0 = full grip (today)
#   cut_min_speed            a cut only slides at this fraction of top speed or more ...
#   cut_angle_deg            ... turning at least this many degrees from where he is going
#   lob_drift_ft             a lob lands this far downwind (sim), at full gust
#   shot_curve_ft            a jump shot beyond the arc bows this far downwind in the air (drawn only), at full gust
#   lob_time_mult            x a lob's flight time (sim)
#   arc_mult                 x the drawn arc of jump shots and lobs (drawn only)
#   sideline_fence           1 = a loose ball crossing a sideline bounces off a fence back into play (no sideline out)
#   fence_bounce             fraction of its speed the ball keeps off the fence
#   crowd_db                 extra volume of the crowd loop (audio / twist_fx)
#   gust_min                 wind only: the gust strength swings between this and 1.0 (full gust)
#   gust_keys                wind only: these keys scale with the gust (value() = default -> number as gust 0 -> 1)

const TWISTS := {
	"none": {},
	# Chicago: a steady crosswind off the lake (across the court, so both baskets play the same), gusting
	"wind": {
		"name": "WIND OFF THE LAKE", "banner": "Wind: long shots and lobs drift", "icon": "wind",
		"long_shot_mult": 0.92,   # full gust: shots beyond the arc go in 8% less often
		"shot_curve_ft": 1.5,     # full gust: they curve about 1.5 ft in the air (drawn)
		"lob_drift_ft": 2.0,      # full gust: lobs land up to 2 ft downwind (usually still caught)
		"gust_min": 0.5,          # the gust swings between half and full strength
		"gust_keys": ["long_shot_mult", "shot_curve_ft", "lob_drift_ft"],
	},
	# Memphis: a full house, a faster game
	"crowd": {
		"name": "FULL HOUSE", "banner": "Full house: 18-second shot clock, a faster game", "icon": "crowd",
		"shot_clock": 18.0,       # 24 today
		"speed_mult": 1.04,       # everyone 4% faster
		"crowd_db": 6.0,          # the crowd much louder
	},
	# New Orleans: humid night
	"humid": {
		"name": "BAYOU HEAT", "banner": "Humid: stamina refills slowly", "icon": "humid",
		"stamina_refill_mult": 0.7,   # stamina refills 30% slower
	},
	# Denver: thin air
	"thin_air": {
		"name": "THIN AIR", "banner": "Thin air: the ball floats, long shots fall, you tire faster", "icon": "thin_air",
		"long_shot_mult": 1.08,       # shots beyond the arc go in 8% more often
		"lob_time_mult": 1.15,        # lobs hang about 15% longer
		"arc_mult": 1.15,             # shots and lobs drawn about 15% higher
		"stamina_drain_mult": 1.2,    # stamina drains 20% faster
	},
	# Seattle: wet court
	"wet": {
		"name": "WET COURT", "banner": "Wet court: hard cuts slide (crossovers keep their grip)", "icon": "wet",
		"cut_grip": 0.42,             # a sharp turn at full speed slides about 1.5 ft further before he changes direction
		"cut_min_speed": 0.9,         # only at 90% of top speed or more (P6-30: was 0.8)
		"cut_angle_deg": 150.0,       # and only turning 150 degrees or more: a reversal (P6-30: was 60, about 500 slides
		                              # a CPU game; now about 75)
	},
	# Los Angeles: sand
	"sand": {
		"name": "BEACH SAND", "banner": "Sand: everyone is slower, turbo matters more", "icon": "sand",
		"speed_mult": 0.9,            # everyone 10% slower
		"turbo_mult": 1.45,           # turbo boost 35% -> 45%
	},
	# New York: the fenced cage (owner Q2 a)
	"cage": {
		"name": "THE CAGE", "banner": "The cage: the fence keeps the ball in on the sides", "icon": "cage",
		"sideline_fence": 1.0,        # no out of bounds on the sidelines; baselines as now
		"fence_bounce": 0.6,          # the ball keeps 60% of its speed off the fence
	},
	# Legends, Chapter 1 (P9-08, owner L5 a): the Grandfathers era, "OLD SCHOOL". Starting values; QA tunes them (P9-17)
	"era_grand": {
		"name": "OLD SCHOOL", "banner": "Old school: slower, more inside, fewer threes and fouls",
		"icon": "era_grand",
		"speed_mult": 0.94,           # everyone 6% slower
		"long_shot_mult": 0.80,       # shots beyond the arc go in 20% less often (P9-17: at 0.88 nobody noticed)
		"inside_mult": 1.08,          # close jumpers, layups and dunks go in 8% more often
		"foul_mult": 0.6,             # fouls are called 60% as often as today (rougher defense)
	},
}

# Today's value of every hook key (what each hook passes as `default`; listed so the table can be checked)
const DEFAULTS := {
	"long_shot_mult": 1.0, "shot_clock": 24.0, "speed_mult": 1.0, "turbo_mult": 1.35,
	"stamina_drain_mult": 1.0, "stamina_refill_mult": 1.0, "cut_grip": 1.0, "cut_min_speed": 0.8,
	"cut_angle_deg": 60.0, "lob_drift_ft": 0.0, "shot_curve_ft": 0.0, "lob_time_mult": 1.0, "arc_mult": 1.0,
	"sideline_fence": 0.0, "fence_bounce": 0.6, "crowd_db": 0.0, "inside_mult": 1.0, "foul_mult": 1.0,
}
const TEXT_KEYS := ["name", "banner", "icon", "gust_min", "gust_keys"]

static var current := "none"
static var wind := Vector2.ZERO   # wind twist: unit direction the wind blows to (sim), set once per game; else zero
static var gust := 1.0            # wind twist: 0..1 gust factor (gust_min..1 mapped onto 0..1 of the effect); else 1
static var _t := 0.0
static var _phase_a := 0.0
static var _phase_b := 0.0
const GUST_RATE_A := 0.55         # rad/s of the slow gust wave (about 11 s a cycle)
const GUST_RATE_B := 1.7          # rad/s of the quick flutter on top (about 4 s)
const GUST_MIX_B := 0.35          # share of the flutter in the gust

# Set the twist for the next game. Unknown id -> "none" (and a printed warning).
static func set_current(id: String) -> void:
	if id == "":
		id = "none"
	if not TWISTS.has(id):
		print("Twists: unknown twist '%s', playing without one" % id)
		id = "none"
	current = id
	wind = Vector2.ZERO
	gust = 1.0
	_t = 0.0

# A new game with the current twist: the wind's direction (straight across the court, either way: both teams attack
# along the court, so a crosswind treats them the same) and the gust phases.
static func new_game(rng: RandomNumberGenerator) -> void:
	_t = 0.0
	wind = Vector2.ZERO
	gust = 1.0
	if not has_gusts():
		return
	wind = Vector2(0.0, 1.0 if rng.randf() < 0.5 else -1.0)
	_phase_a = rng.randf_range(0.0, TAU)
	_phase_b = rng.randf_range(0.0, TAU)
	_update_gust()

# Every physics frame of live or dead play (main.gd): the gust swings smoothly between gust_min and full.
static func tick(delta: float) -> void:
	if not has_gusts():
		return
	_t += delta
	_update_gust()

static func _update_gust() -> void:
	var w: float = (1.0 - GUST_MIX_B) * sin(_t * GUST_RATE_A + _phase_a) + GUST_MIX_B * sin(_t * GUST_RATE_B + _phase_b)
	var lo: float = float(_table().get("gust_min", 1.0))
	gust = lerpf(lo, 1.0, 0.5 + 0.5 * w)

static func has_gusts() -> bool:
	return _table().has("gust_min")

static func _table(id := "") -> Dictionary:
	var t = TWISTS.get(current if id == "" else id, {})
	return t if t is Dictionary else {}

# The current twist's number for `key`, or `default` (= today) when the twist doesn't have it. Wind keys listed in
# gust_keys follow the gust: default at no gust, the table number at full gust.
static func value(key: String, default: float) -> float:
	var t: Dictionary = _table()
	if not t.has(key):
		return default
	var v: float = float(t[key])
	if t.has("gust_keys") and (t["gust_keys"] as Array).has(key):
		return lerpf(default, v, gust)
	return v

# The table number itself (no gust), or default.
static func base_value(key: String, default: float) -> float:
	var t: Dictionary = _table()
	return float(t[key]) if t.has(key) else default

# A yes/no key, e.g. "sideline_fence"
static func flag(key: String) -> bool:
	return base_value(key, 0.0) != 0.0

# True when a twist is on (not "none")
static func active() -> bool:
	return current != "none"

# For the banner, the trip map and the pause screen: {"id", "name", "banner", "icon"} of `id` (default: the current
# twist). "none" (or an unknown id) gives empty strings.
static func info(id := "") -> Dictionary:
	var key: String = current if id == "" else id
	var t: Dictionary = _table(key)
	return {"id": key if TWISTS.has(key) else "none", "name": str(t.get("name", "")),
			"banner": str(t.get("banner", "")), "icon": str(t.get("icon", ""))}

# test only (main.gd -- --twisttest): "none" returns every default exactly, every twist key is a known hook key, every
# twist but "none" has its banner text. Prints the problems; leaves the current twist as it found it.
static func self_test() -> bool:
	var errs: PackedStringArray = []
	var was: String = current
	set_current("none")
	for k in DEFAULTS:
		var d: float = float(DEFAULTS[k])
		if value(k, d) != d or value(k, d + 0.5) != d + 0.5:
			errs.append("none: %s is not the default" % k)
	if flag("sideline_fence"):
		errs.append("none: sideline_fence is on")
	for id in TWISTS:
		var t: Dictionary = TWISTS[id]
		for k in t:
			if not DEFAULTS.has(k) and not TEXT_KEYS.has(k):
				errs.append("%s: unknown key %s" % [id, k])
		if id != "none" and (str(t.get("name", "")) == "" or str(t.get("banner", "")) == ""):
			errs.append("%s: no name or banner" % id)
		set_current(id)
		for k in DEFAULTS:
			if t.has(k):
				print("TWISTTEST %s %s = %s (today %s)" % [id, k, str(value(k, float(DEFAULTS[k]))), str(DEFAULTS[k])])
	set_current(was)
	for e in errs:
		print("TWISTTEST ", e)
	print("TWISTTEST ", "OK" if errs.is_empty() else "FAILED (%d)" % errs.size())
	return errs.is_empty()
