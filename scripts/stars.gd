extends RefCounted
# Stars and the star reward ladder (Phase 8, P8-02; docs/progression-plan.md parts 3 and 4). Static only:
#   const Stars = preload("res://scripts/stars.gd")
#   var got: int = Stars.record(Stars.key("chicago", 2), "hard")   # stars gained now (0 = no better than before)
#   Stars.total()  Stars.slots()  Stars.is_unlocked("ball_1")  Stars.legend_open()  Stars.next_reward()
# Each city game and each New York round gives 1 / 2 / 3 stars for a win on Easy / Normal / Hard (LEGEND 3). Only the
# best result of each game counts: 8 cities x 3 games x 3 = 72. Stars are kept for good, in section "stars" of the
# settings file (Difficulty.unlock_path(); any test run uses the test file user://settings_test.cfg, never the owner's
# settings.cfg). A NEW TRIP keeps them. The rewards are the ladder REWARDS: a reward is open once the total reaches its
# "at" (open for good, since the total never goes down).
# Test flags: --startest (self_test(), prints STARTEST OK and quits), --stars N (this run acts as if the total were N;
# never saved; the per-game bests stay the real ones).
# difficulty.gd is loaded at call time (not preloaded), so difficulty.gd may preload this script later (LEGEND).

const Cities = preload("res://scripts/cities.gd")   # ROUTE: the 8 cities whose games give stars

const MAX := 72                     # every game 3 stars: 8 cities x GAMES x 3
const GAMES := 3                    # games per city; New York has 3 rounds
const STARS_BY_LEVEL := {"easy": 1, "normal": 2, "hard": 3, "legend": 3}   # owner Q3 a
const LEVEL_ORDER := ["easy", "normal", "hard", "legend"]   # an int level: Difficulty.EASY.. (3 = LEGEND)
const SECTION := "stars"
const BEST_KEY := "best"            # Dictionary {"chicago:2": 3, ...} in SECTION (other keys, e.g. migrated_v1, are
                                    # left alone)
const DIFFICULTY_PATH := "res://scripts/difficulty.gd"      # unlock_path(): the settings or the test settings file
const SETTINGS_PATH := "user://settings.cfg"                # the owner's file (Difficulty.SAVE_PATH)
const TEST_SETTINGS_PATH := "user://settings_test.cfg"      # every test run (Difficulty.UNLOCK_TEST_PATH)
const SELFTEST_PATH := "user://stars_selftest.cfg"          # --startest only, deleted afterwards
const STARS_FLAG := "--stars"       # --stars N or --stars=N
const STARTEST_FLAG := "--startest"

# The reward ladder (owner answers: slots at 12/24/36/48, the plan's cosmetics, LEGEND at 72). Sorted by "at"; rows
# with the same "at" open together. Kinds: slot, jersey, ball, van, court, legend. Cosmetic ids are cosmetics.gd's.
const REWARDS := [
	{"at": 6, "kind": "jersey", "id": "jersey_1"},
	{"at": 12, "kind": "slot", "id": "slot_1"},
	{"at": 18, "kind": "ball", "id": "ball_1"},
	{"at": 24, "kind": "slot", "id": "slot_2"},
	{"at": 24, "kind": "van", "id": "van_1"},
	{"at": 30, "kind": "court", "id": "court_1"},
	{"at": 36, "kind": "slot", "id": "slot_3"},
	{"at": 36, "kind": "jersey", "id": "jersey_2"},
	{"at": 42, "kind": "ball", "id": "ball_2"},
	{"at": 48, "kind": "slot", "id": "slot_4"},
	{"at": 48, "kind": "van", "id": "van_2"},
	{"at": 54, "kind": "jersey", "id": "jersey_3"},
	{"at": 60, "kind": "court", "id": "court_2"},
	{"at": 60, "kind": "ball", "id": "ball_3"},
	{"at": 66, "kind": "van", "id": "van_3"},
	{"at": 72, "kind": "legend", "id": "legend"},
]

static var force_total: int = _parse_stars_flag()   # --stars N (-1 = none): total() returns N this run
static var _path_override := ""                     # self_test() only

# ---------------- keys and levels ----------------

# "chicago:2"; New York rounds are "new_york:1".."new_york:3"
static func key(city_id: String, n: int) -> String:
	return "%s:%d" % [city_id, n]

# every key that gives stars, in route order (24)
static func all_keys() -> Array:
	var out: Array = []
	for c in Cities.ROUTE:
		for n in range(1, GAMES + 1):
			out.append(key(str(c), n))
	return out

static func is_key(k: String) -> bool:
	return all_keys().has(k)

# stars for a win on this level: a name ("easy", "normal", "hard", "legend") or an int (Difficulty.EASY.., 3 = legend)
static func stars_for(level) -> int:
	var lv_name := ""
	if level is int:
		var i: int = level
		if i >= 0 and i < LEVEL_ORDER.size():
			lv_name = LEVEL_ORDER[i]
	else:
		lv_name = str(level).strip_edges().to_lower()
	return int(STARS_BY_LEVEL.get(lv_name, 0))

# ---------------- the store ----------------

# the file the stars live in: the settings file, the test settings file in any test run
static func path() -> String:
	if _path_override != "":
		return _path_override
	if not OS.get_cmdline_user_args().is_empty():
		return TEST_SETTINGS_PATH
	var d = load(DIFFICULTY_PATH)
	if d != null:
		return str(d.unlock_path())
	return SETTINGS_PATH

static func _bests() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(path()) != OK:
		return {}
	var v = cfg.get_value(SECTION, BEST_KEY, {})
	var out: Dictionary = {}
	if v is Dictionary:
		for k in v:
			var ks: String = str(k)
			var s = v[k]
			if is_key(ks) and (s is int or s is float):
				out[ks] = clampi(int(s), 0, 3)
	return out

# A win of game `k` on `level`. Saves the new best and returns the stars gained now (0 if no better, or not a game).
static func record(k: String, level) -> int:
	var s: int = stars_for(level)
	if s <= 0 or not is_key(k):
		return 0
	var old: int = best(k)
	if s <= old:
		return 0
	var p: String = path()
	var cfg := ConfigFile.new()
	cfg.load(p)   # keep the other settings in the file
	var bests: Dictionary = _bests()
	bests[k] = s
	cfg.set_value(SECTION, BEST_KEY, bests)
	cfg.save(p)
	print("STARS %s %d -> %d (total %d)" % [k, old, s, real_total()])
	return s - old

# the best stars of one game (0 = never won)
static func best(k: String) -> int:
	return int(_bests().get(k, 0))

# the stored total (the per-game bests), never --stars
static func real_total() -> int:
	var t := 0
	for v in _bests().values():
		t += int(v)
	return mini(t, MAX)

# the total the rewards use: --stars N when given, else the stored total
static func total() -> int:
	if force_total >= 0:
		return mini(force_total, MAX)
	return real_total()

# a city's stars (0..9), from the stored bests
static func city_total(city_id: String) -> int:
	var b: Dictionary = _bests()
	var t := 0
	for n in range(1, GAMES + 1):
		t += int(b.get(key(city_id, n), 0))
	return t

# ---------------- rewards ----------------

# the extra roster slots open now (0..4)
static func slots() -> int:
	var t: int = total()
	var n := 0
	for r in REWARDS:
		if str(r["kind"]) == "slot" and t >= int(r["at"]):
			n += 1
	return n

# true when reward `reward_id` ("jersey_1", "slot_2", "legend", ...) is open; an unknown id is never open
static func is_unlocked(reward_id: String) -> bool:
	var t: int = total()
	for r in REWARDS:
		if str(r["id"]) == reward_id:
			return t >= int(r["at"])
	return false

static func legend_open() -> bool:
	return is_unlocked("legend")

# the rewards opened when the total went from a to b (a < at <= b), in ladder order (the result screen)
static func rewards_between(a: int, b: int) -> Array:
	var out: Array = []
	for r in REWARDS:
		var at: int = r["at"]
		if at > a and at <= b:
			out.append((r as Dictionary).duplicate())
	return out

# the first reward not open yet ({} when everything is open)
static func next_reward() -> Dictionary:
	var t: int = total()
	for r in REWARDS:
		if int(r["at"]) > t:
			return (r as Dictionary).duplicate()
	return {}

# ---------------- test flags ----------------

static func _parse_stars_flag() -> int:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		var a: String = args[i]
		var s := ""
		if a.begins_with(STARS_FLAG + "="):
			s = a.substr(STARS_FLAG.length() + 1)
		elif a == STARS_FLAG and i + 1 < args.size():
			s = args[i + 1]
		else:
			continue
		if s.is_valid_int():
			return clampi(s.to_int(), 0, MAX)
	return -1

# --startest: checks the store and the ladder in a scratch file (never the owner's or the trip test's). Prints
# STARTEST OK or STARTEST FAILED: <why> and returns true when everything passed.
static func self_test() -> bool:
	var errs: Array = []
	var saved_force: int = force_total
	var flag_force: int = force_total
	_path_override = SELFTEST_PATH
	force_total = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SELFTEST_PATH))

	# data: 24 keys, MAX matches, ladder sorted, ids unique, kinds known, 4 slots at 12/24/36/48, LEGEND at MAX
	var keys: Array = all_keys()
	_check(errs, keys.size() == Cities.ROUTE.size() * GAMES, "key count %d" % keys.size())
	_check(errs, keys.size() * 3 == MAX, "MAX %d != %d games x 3" % [MAX, keys.size()])
	_check(errs, key("chicago", 2) == "chicago:2" and key("new_york", 1) == "new_york:1", "key format")
	_check(errs, stars_for("easy") == 1 and stars_for("normal") == 2 and stars_for("hard") == 3
		and stars_for("legend") == 3, "stars_for names")
	_check(errs, stars_for(0) == 1 and stars_for(1) == 2 and stars_for(2) == 3 and stars_for(3) == 3,
		"stars_for ints")
	_check(errs, stars_for("bogus") == 0 and stars_for(-1) == 0 and stars_for(9) == 0, "stars_for unknown")
	var kinds := ["slot", "jersey", "ball", "van", "court", "legend"]
	var counts := {"slot": 0, "jersey": 0, "ball": 0, "van": 0, "court": 0, "legend": 0}
	var seen: Dictionary = {}
	var prev_at := 0
	var slot_ats: Array = []
	for r in REWARDS:
		var at: int = r["at"]
		var kind: String = str(r["kind"])
		var id: String = str(r["id"])
		_check(errs, at >= prev_at and at > 0 and at <= MAX, "ladder order at %s" % id)
		prev_at = at
		_check(errs, kinds.has(kind), "unknown kind %s" % kind)
		_check(errs, not seen.has(id), "duplicate id %s" % id)
		seen[id] = true
		counts[kind] = int(counts.get(kind, 0)) + 1
		if kind == "slot":
			slot_ats.append(at)
	_check(errs, slot_ats == [12, 24, 36, 48], "slot rows %s" % str(slot_ats))
	_check(errs, counts["jersey"] == 3 and counts["ball"] == 3 and counts["van"] == 3 and counts["court"] == 2
		and counts["legend"] == 1, "cosmetic counts %s" % str(counts))
	_check(errs, int(REWARDS[REWARDS.size() - 1]["at"]) == MAX and str(REWARDS[REWARDS.size() - 1]["kind"]) == "legend",
		"LEGEND is not the last row at MAX")

	# a fresh store
	_check(errs, total() == 0 and real_total() == 0, "fresh total %d" % total())
	_check(errs, best("chicago:2") == 0 and city_total("chicago") == 0, "fresh best")
	_check(errs, slots() == 0 and not legend_open() and not is_unlocked("jersey_1"), "fresh rewards")
	_check(errs, str(next_reward().get("id", "")) == "jersey_1", "fresh next %s" % str(next_reward()))

	# record and best: better counts, worse or equal gains 0, bad keys and levels gain 0
	_check(errs, record("chicago:2", "normal") == 2, "record normal")
	_check(errs, best("chicago:2") == 2 and total() == 2, "best after normal")
	_check(errs, record("chicago:2", "easy") == 0 and best("chicago:2") == 2, "worse kept the best")
	_check(errs, record("chicago:2", "normal") == 0, "equal gains 0")
	_check(errs, record("chicago:2", "hard") == 1 and best("chicago:2") == 3, "record hard gains 1")
	_check(errs, record("chicago:2", "legend") == 0, "legend after hard gains 0")
	_check(errs, record("chicago:4", "hard") == 0 and record("atlantis:1", "hard") == 0, "bad key recorded")
	_check(errs, record("memphis:1", "bogus") == 0 and best("memphis:1") == 0, "bad level recorded")
	_check(errs, record("new_york:1", "easy") == 1, "new york round")
	_check(errs, total() == 4 and city_total("chicago") == 3 and city_total("new_york") == 1, "totals %d" % total())
	# other keys in the section and other sections survive
	var cfg := ConfigFile.new()
	cfg.load(SELFTEST_PATH)
	cfg.set_value(SECTION, "migrated_v1", true)
	cfg.set_value("settings", "difficulty", "hard")
	cfg.save(SELFTEST_PATH)
	_check(errs, record("memphis:3", 2) == 3 and total() == 7, "record with an int level")
	cfg = ConfigFile.new()
	cfg.load(SELFTEST_PATH)
	_check(errs, bool(cfg.get_value(SECTION, "migrated_v1", false)) and str(cfg.get_value("settings", "difficulty", ""))
		== "hard", "record lost other keys")
	_check(errs, rewards_between(0, total()).size() == 1, "rewards_between after 7")

	# a full store: every game on Hard, then LEGEND changes nothing; 72 is the cap
	var gained := 0
	for k in keys:
		gained += record(str(k), "hard")
	_check(errs, gained == MAX - 7, "full gain %d" % gained)
	_check(errs, total() == MAX and real_total() == MAX, "full total %d" % total())
	for k in keys:
		_check(errs, record(str(k), "legend") == 0, "legend over hard gained at %s" % k)
	_check(errs, total() == MAX, "cap %d" % total())
	for c in Cities.ROUTE:
		_check(errs, city_total(str(c)) == 9, "city total %s" % c)
	_check(errs, slots() == 4 and legend_open() and next_reward().is_empty(), "full rewards")
	for r in REWARDS:
		_check(errs, is_unlocked(str(r["id"])), "full: %s closed" % r["id"])
	_check(errs, not is_unlocked("jersey_9") and not is_unlocked(""), "unknown id open")
	# a hand-edited file: a value over 3 or a bad key never raises the total over MAX
	cfg = ConfigFile.new()
	cfg.load(SELFTEST_PATH)
	var b: Dictionary = cfg.get_value(SECTION, BEST_KEY, {})
	b["chicago:1"] = 99
	b["moon:1"] = 3
	cfg.set_value(SECTION, BEST_KEY, b)
	cfg.save(SELFTEST_PATH)
	_check(errs, total() == MAX and best("chicago:1") == 3 and best("moon:1") == 0, "edited file %d" % total())

	# every ladder row: at its own count it is open, one star below it is closed; rewards_between and next_reward agree
	for r in REWARDS:
		var at: int = r["at"]
		var id: String = str(r["id"])
		force_total = at - 1
		_check(errs, not is_unlocked(id), "%s open at %d" % [id, at - 1])
		_check(errs, int(next_reward().get("at", -1)) == at, "next_reward at %d" % (at - 1))
		force_total = at
		_check(errs, is_unlocked(id), "%s closed at %d" % [id, at])
		var ids: Array = []
		for x in rewards_between(at - 1, at):
			ids.append(str(x["id"]))
		_check(errs, ids.has(id), "rewards_between(%d, %d) misses %s" % [at - 1, at, id])
	var expect_slots := {0: 0, 11: 0, 12: 1, 23: 1, 24: 2, 35: 2, 36: 3, 47: 3, 48: 4, 72: 4}
	for t in expect_slots:
		force_total = int(t)
		_check(errs, slots() == int(expect_slots[t]), "slots at %d: %d" % [t, slots()])
	force_total = 71
	_check(errs, not legend_open(), "legend at 71")
	force_total = 500
	_check(errs, total() == MAX and legend_open(), "--stars over MAX")
	_check(errs, rewards_between(0, MAX).size() == REWARDS.size() and rewards_between(MAX, MAX).is_empty()
		and rewards_between(10, 5).is_empty(), "rewards_between range")
	_check(errs, rewards_between(23, 24).size() == 2 and rewards_between(59, 60).size() == 2, "same-count rows")

	# the --stars flag of this run, if given, parsed and clamped
	if flag_force >= 0:
		_check(errs, flag_force <= MAX, "--stars %d" % flag_force)
		print("STARTEST --stars %d: slots %d, legend %s" % [flag_force, _slots_at(flag_force), str(flag_force >= MAX)])

	# the ladder table
	for r in REWARDS:
		print("STARTEST ladder %2d %-6s %s" % [int(r["at"]), str(r["kind"]), str(r["id"])])

	force_total = saved_force
	_path_override = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SELFTEST_PATH))
	# the real store is never the owner's in a test run
	_check(errs, path() == TEST_SETTINGS_PATH, "test run path %s" % path())
	if errs.is_empty():
		print("STARTEST OK")
		return true
	for e in errs:
		print("STARTEST FAIL: %s" % e)
	print("STARTEST FAILED: %d" % errs.size())
	return false

static func _slots_at(t: int) -> int:
	var n := 0
	for r in REWARDS:
		if str(r["kind"]) == "slot" and t >= int(r["at"]):
			n += 1
	return n

static func _check(errs: Array, ok: bool, why: String) -> void:
	if not ok:
		errs.append(why)
