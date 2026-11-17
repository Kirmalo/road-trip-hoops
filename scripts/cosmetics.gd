extends RefCounted
# Cosmetics (Phase 8, P8-03; board "Cosmetics" contract). Static only:
#   const Cosmetics = preload("res://scripts/cosmetics.gd")
# The star rewards you wear: 3 jerseys, 3 balls, 3 van paints (picked on the LOCKER screen), and 2 Quick Game court
# looks (no pick: once open they join the Quick Game COURT button). stars.gd decides what is unlocked
# (Stars.is_unlocked(id)); this file keeps the picks and turns them into file paths.
#
#   Cosmetics.picked("ball")           "" (the default) or "ball_2"
#   Cosmetics.pick("ball", "ball_2")   true when saved; locked, unknown or wrong-kind ids are refused; "" = default
#   Cosmetics.ball_sheet()             res://assets/ball/ball_<N>.png or the default ball.png
#   Cosmetics.van_path()               res://assets/map/van_<N>.png or the default van.png
#   Cosmetics.jersey_suffix()          "" or "_j1".."_j3" (sheets.gd falls back per sheet when a palette is missing)
#   Cosmetics.open_court_looks()       court_looks.gd ids of the unlocked reward courts, in reward order
#
# Every function falls back to the default when a file is missing, when stars.gd is missing (nothing is unlocked) or
# when a saved pick is locked again (e.g. a lower --stars N): nothing a pick names can break a game.
# Picks live in section "cosmetics" of Difficulty.unlock_path(); any test run (any user argument after "--") uses
# Difficulty.UNLOCK_TEST_PATH, never the owner's settings.cfg.
# Test flags: --cosmetictest (self_test(): prints COSMETICTEST OK or FAILED), --wear id[,id...] (or --wear=...):
# wear these unlocked items this run, never saved (e.g. --stars 72 --wear ball_1,jersey_2).

const Difficulty = preload("res://scripts/difficulty.gd")   # unlock_path(), is_test_run()
const Looks = preload("res://scripts/court_looks.gd")       # the reward court rows ("reward": "court_<N>")

const STARS_PATH := "res://scripts/stars.gd"   # loaded at run time: a missing stars.gd means nothing is unlocked
const SECTION := "cosmetics"                   # keys: the pick kinds below, values: item ids ("" = default)
const PICK_KINDS := ["jersey", "ball", "van"]  # picked on the LOCKER screen
const KINDS := ["jersey", "ball", "van", "court"]
const DEFAULT_BALL := "res://assets/ball/ball.png"   # ball.gd's sheet today (4 spin frames of 16 x 16)
const DEFAULT_VAN := "res://assets/map/van.png"      # trip_map.gd's van today
const JERSEY_PROBE_SHEET := "ud_deuce"               # a jersey counts as made when this underdog's palette exists
const PALETTE_DIR := "res://assets/players2/palettes/"
const WEAR_FLAG := "--wear"
const TEST_FLAG := "--cosmetictest"
const SELFTEST_PATH := "user://cosmetics_selftest.cfg"   # self_test() only; deleted afterwards

# The items. name: shown on the LOCKER (placeholders until the art tasks name them); n: the number in the file names;
# files: what must exist for the item to show (court looks: their row in court_looks.gd is the truth, its textures
# already fall back to plain colors).
const ITEMS := {
	"jersey_1": {"kind": "jersey", "name": "JERSEY 1", "n": 1, "files": [PALETTE_DIR + JERSEY_PROBE_SHEET + "_j1.png"]},
	"jersey_2": {"kind": "jersey", "name": "JERSEY 2", "n": 2, "files": [PALETTE_DIR + JERSEY_PROBE_SHEET + "_j2.png"]},
	"jersey_3": {"kind": "jersey", "name": "JERSEY 3", "n": 3, "files": [PALETTE_DIR + JERSEY_PROBE_SHEET + "_j3.png"]},
	"ball_1": {"kind": "ball", "name": "BALL 1", "n": 1, "files": ["res://assets/ball/ball_1.png"]},
	"ball_2": {"kind": "ball", "name": "BALL 2", "n": 2, "files": ["res://assets/ball/ball_2.png"]},
	"ball_3": {"kind": "ball", "name": "BALL 3", "n": 3, "files": ["res://assets/ball/ball_3.png"]},
	"van_1": {"kind": "van", "name": "VAN PAINT 1", "n": 1, "files": ["res://assets/map/van_1.png"]},
	"van_2": {"kind": "van", "name": "VAN PAINT 2", "n": 2, "files": ["res://assets/map/van_2.png"]},
	"van_3": {"kind": "van", "name": "VAN PAINT 3", "n": 3, "files": ["res://assets/map/van_3.png"]},
	"court_1": {"kind": "court", "name": "COURT 1", "n": 1, "files": []},
	"court_2": {"kind": "court", "name": "COURT 2", "n": 2, "files": []},
}

static var _picks: Dictionary = {}       # kind -> id as saved (read once per run, kept in step by pick())
static var _loaded := false
static var _wear: Dictionary = {}        # kind -> id from --wear (this run only)
static var _wear_read := false
# self_test() only: replaces the save path, the Stars lookup and the file checks
static var _path_override := ""
static var _test_unlocked = null         # null = ask stars.gd; an Array = exactly these ids are unlocked
static var _test_missing: Array = []     # ids treated as having a missing file

# ---------------- what you have ----------------

# the item ids of one kind, in ladder order
static func ids_of(kind: String) -> Array:
	var out: Array = []
	for id in ITEMS:
		if str((ITEMS[id] as Dictionary)["kind"]) == kind:
			out.append(id)
	return out

# the name shown for an item ("" for an unknown id)
static func item_name(id: String) -> String:
	return str((ITEMS.get(id, {}) as Dictionary).get("name", ""))

# unlocked by stars (stars.gd; false when stars.gd is missing)
static func is_unlocked(id: String) -> bool:
	if not ITEMS.has(id):
		return false
	if _test_unlocked is Array:
		return (_test_unlocked as Array).has(id)
	if not ResourceLoader.exists(STARS_PATH):
		return false
	var s: GDScript = load(STARS_PATH) as GDScript
	if s == null or not s.has_method("is_unlocked"):
		return false
	return bool(s.call("is_unlocked", id))

# every file the item needs exists
static func has_files(id: String) -> bool:
	if not ITEMS.has(id) or _test_missing.has(id):
		return false
	for f in (ITEMS[id] as Dictionary)["files"]:
		if not ResourceLoader.exists(str(f)):
			return false
	if str((ITEMS[id] as Dictionary)["kind"]) == "court":
		return court_look_of(id) != ""
	return true

# unlocked and made: it can be picked (or, for a court, played)
static func available(id: String) -> bool:
	return is_unlocked(id) and has_files(id)

# ---------------- picks ----------------

# the item worn for a pick kind: "" = the default (no pick, or the pick is locked or its file is missing).
# --wear wins over the saved pick.
static func picked(kind: String) -> String:
	_read_wear()
	var id: String = str(_wear.get(kind, ""))
	if id == "":
		_load()
		id = str(_picks.get(kind, ""))
	if id == "" or not ITEMS.has(id) or str((ITEMS[id] as Dictionary)["kind"]) != kind:
		return ""
	return id if available(id) else ""

# Pick an item (saved at once). "" puts the default back. Refused (false): a kind that is not picked (court), an
# unknown id, an id of another kind, a locked id, or one whose file is missing.
static func pick(kind: String, id: String) -> bool:
	if not PICK_KINDS.has(kind):
		return false
	if id != "":
		if not ITEMS.has(id) or str((ITEMS[id] as Dictionary)["kind"]) != kind or not available(id):
			return false
	_load()
	_picks[kind] = id
	var path: String = save_path()
	var cfg := ConfigFile.new()
	cfg.load(path)   # keep the other settings in the file
	cfg.set_value(SECTION, kind, id)
	cfg.save(path)
	return true

# where the picks are saved: the settings (Difficulty.unlock_path()), the test file in any test run
static func save_path() -> String:
	if _path_override != "":
		return _path_override
	if Difficulty.is_test_run():
		return Difficulty.UNLOCK_TEST_PATH
	return Difficulty.unlock_path()

# ---------------- what the game uses ----------------

# the ball's sheet (4 spin frames of 16 x 16)
static func ball_sheet() -> String:
	var id: String = picked("ball")
	return str(((ITEMS[id] as Dictionary)["files"] as Array)[0]) if id != "" else DEFAULT_BALL

# the van on the trip map
static func van_path() -> String:
	var id: String = picked("van")
	return str(((ITEMS[id] as Dictionary)["files"] as Array)[0]) if id != "" else DEFAULT_VAN

# added to your crew's sheet ids ("" = the plain crew colors); a sheet without that jersey palette falls back in
# sheets.gd
static func jersey_suffix() -> String:
	var id: String = picked("jersey")
	return "_j%d" % int((ITEMS[id] as Dictionary)["n"]) if id != "" else ""

# the court_looks.gd ids of the unlocked reward courts, for the Quick Game COURT button
static func open_court_looks() -> Array:
	var out: Array = []
	for id in ids_of("court"):
		if available(id):
			out.append(court_look_of(id))
	return out

# the court_looks.gd id whose row says "reward": id ("" when no row does yet)
static func court_look_of(id: String) -> String:
	for look in Looks.LOOKS:
		if str((Looks.LOOKS[look] as Dictionary).get("reward", "")) == id:
			return str(look)
	return ""

# ---------------- internals ----------------

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	_picks = {}
	var cfg := ConfigFile.new()
	if cfg.load(save_path()) != OK:
		return
	for kind in PICK_KINDS:
		_picks[kind] = str(cfg.get_value(SECTION, kind, ""))

# --wear id[,id...] / --wear=id[,id...]: this run's picks by kind (unknown ids ignored)
static func _read_wear() -> void:
	if _wear_read:
		return
	_wear_read = true
	_wear = {}
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var s := ""
	for i in args.size():
		if args[i].begins_with(WEAR_FLAG + "="):
			s = args[i].substr(WEAR_FLAG.length() + 1)
		elif args[i] == WEAR_FLAG and i + 1 < args.size():
			s = args[i + 1]
	for part in s.split(",", false):
		var id: String = part.strip_edges()
		if ITEMS.has(id) and PICK_KINDS.has(str((ITEMS[id] as Dictionary)["kind"])):
			_wear[str((ITEMS[id] as Dictionary)["kind"])] = id

# ---------------- self test (--cosmetictest) ----------------

# Checks the item table, a fresh store, locked and wrong ids refused, picks saved and read back, missing files and
# relocked picks falling back, the reward courts and (when stars.gd exists) that its ladder names only these ids.
# Uses its own file (SELFTEST_PATH, deleted afterwards), never the settings. Prints COSMETICTEST OK or FAILED.
static func self_test() -> bool:
	var errs: PackedStringArray = []
	var all_ids: Array = ITEMS.keys()
	_path_override = SELFTEST_PATH
	_test_unlocked = []
	_test_missing = []
	_wear = {}
	_wear_read = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SELFTEST_PATH))
	_reset_cache()

	# the table
	var want := {"jersey": 3, "ball": 3, "van": 3, "court": 2}
	for kind in want:
		if ids_of(kind).size() != int(want[kind]):
			errs.append("%s: %d items, want %d" % [kind, ids_of(kind).size(), int(want[kind])])
	for id in ITEMS:
		var it: Dictionary = ITEMS[id]
		if not KINDS.has(str(it["kind"])) or item_name(id) == "" or str(id) != "%s_%d" % [it["kind"], int(it["n"])]:
			errs.append("%s: bad row" % id)

	# a fresh store, nothing unlocked: the defaults
	for kind in PICK_KINDS:
		if picked(kind) != "":
			errs.append("fresh: %s picked" % kind)
	if ball_sheet() != DEFAULT_BALL or van_path() != DEFAULT_VAN or jersey_suffix() != "":
		errs.append("fresh: not the defaults")
	if not open_court_looks().is_empty():
		errs.append("fresh: court looks open")

	# locked ids refused
	for id in all_ids:
		var kind: String = str((ITEMS[id] as Dictionary)["kind"])
		if pick(kind, id):
			errs.append("locked %s was picked" % id)

	# everything unlocked; files as they are on disk
	_test_unlocked = all_ids.duplicate()
	var made := {}
	for id in all_ids:
		made[id] = has_files(id)
	print("COSMETICTEST files: ", ", ".join(PackedStringArray(all_ids.map(func(x): return "%s %s" % [x, "made" if made[x] else "missing"]))))
	# wrong kinds, unknown ids and court picks refused; "" always allowed
	if pick("ball", "van_1") or pick("van", "jersey_1") or pick("ball", "nope") or pick("court", "court_1") \
			or pick("hat", ""):
		errs.append("a wrong kind or unknown id was picked")
	for kind in PICK_KINDS:
		if not pick(kind, ""):
			errs.append("%s: the default was refused" % kind)
	for id in all_ids:
		var kind: String = str((ITEMS[id] as Dictionary)["kind"])
		if not PICK_KINDS.has(kind):
			continue
		var ok: bool = pick(kind, id)
		if ok != bool(made[id]):
			errs.append("%s: pick %s with files %s" % [id, ok, made[id]])
		if ok and picked(kind) != id:
			errs.append("%s: not picked after pick" % id)
	# the paths follow the pick (a pick refused for a missing file keeps the last good one, or the default)
	_check_paths(errs, "after picks")

	# saved: a fresh read of the file gives the same picks
	var before := {}
	for kind in PICK_KINDS:
		before[kind] = picked(kind)
	_reset_cache()
	for kind in PICK_KINDS:
		if picked(kind) != str(before[kind]):
			errs.append("%s: saved %s, read back %s" % [kind, before[kind], picked(kind)])

	# a missing file falls back: pretend every file is gone, with the picks written straight to the file
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "jersey", "jersey_2")
	cfg.set_value(SECTION, "ball", "ball_3")
	cfg.set_value(SECTION, "van", "van_1")
	cfg.save(SELFTEST_PATH)
	_reset_cache()
	if made["jersey_2"] and made["ball_3"] and made["van_1"]:
		if jersey_suffix() != "_j2" or ball_sheet() != "res://assets/ball/ball_3.png" \
				or van_path() != "res://assets/map/van_1.png":
			errs.append("saved picks: wrong paths")
	_test_missing = all_ids.duplicate()
	if ball_sheet() != DEFAULT_BALL or van_path() != DEFAULT_VAN or jersey_suffix() != "":
		errs.append("missing files: no fallback")
	if not open_court_looks().is_empty():
		errs.append("missing files: court looks open")
	for kind in PICK_KINDS:
		if pick(kind, ids_of(kind)[0]):
			errs.append("%s: picked with its file missing" % kind)
	_test_missing = []

	# a saved pick that is locked again (a lower --stars N) is not worn, and is worn again once unlocked
	_test_unlocked = []
	if ball_sheet() != DEFAULT_BALL or van_path() != DEFAULT_VAN or jersey_suffix() != "":
		errs.append("relocked: no fallback")
	_test_unlocked = all_ids.duplicate()
	_check_paths(errs, "unlocked again")

	# junk in the file: unknown ids and ids of another kind read as the default
	cfg = ConfigFile.new()
	cfg.set_value(SECTION, "jersey", "ball_1")
	cfg.set_value(SECTION, "ball", 7)
	cfg.set_value(SECTION, "van", "van_9")
	cfg.save(SELFTEST_PATH)
	_reset_cache()
	if ball_sheet() != DEFAULT_BALL or van_path() != DEFAULT_VAN or jersey_suffix() != "":
		errs.append("junk in the file: no fallback")

	# the reward courts: every open look is a court_looks.gd row with its reward, in order, only when unlocked
	var rows: Array = []
	for id in ids_of("court"):
		if court_look_of(id) != "":
			rows.append(court_look_of(id))
	if open_court_looks() != rows:
		errs.append("court looks: %s, rows %s" % [open_court_looks(), rows])
	_test_unlocked = ["court_2"]
	if open_court_looks() != ([court_look_of("court_2")] if court_look_of("court_2") != "" else []):
		errs.append("court looks: court_2 alone gives %s" % [open_court_looks()])
	print("COSMETICTEST courts: %s" % [rows])

	# stars.gd, when it exists: its ladder names only these ids, and the real lookup runs
	_test_unlocked = null
	if ResourceLoader.exists(STARS_PATH):
		var s: GDScript = load(STARS_PATH) as GDScript
		var ladder = s.get("REWARDS") if s != null else null
		if ladder is Array:
			var named: Array = []
			for r in ladder:
				var k: String = str((r as Dictionary).get("kind", ""))
				if KINDS.has(k):
					var rid: String = str((r as Dictionary).get("id", ""))
					named.append(rid)
					if not ITEMS.has(rid) or str((ITEMS[rid] as Dictionary)["kind"]) != k:
						errs.append("stars.gd ladder: %s %s is not an item" % [k, rid])
			for id in all_ids:
				if not named.has(id):
					errs.append("stars.gd ladder: %s is never unlocked" % id)
		else:
			errs.append("stars.gd has no REWARDS")
		for id in all_ids:
			is_unlocked(id)
		print("COSMETICTEST stars.gd: checked")
	else:
		print("COSMETICTEST stars.gd: missing (nothing unlocked, every pick the default)")
		for kind in PICK_KINDS:
			if picked(kind) != "":
				errs.append("no stars.gd: %s worn" % kind)

	# clean up: the test file goes, the run reads the real store again
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SELFTEST_PATH))
	_path_override = ""
	_test_unlocked = null
	_test_missing = []
	_wear_read = false
	_reset_cache()
	for e in errs:
		print("COSMETICTEST ERROR: ", e)
	print("COSMETICTEST ", "OK" if errs.is_empty() else "FAILED")
	return errs.is_empty()

static func _reset_cache() -> void:
	_loaded = false
	_picks = {}

# ball_sheet / van_path / jersey_suffix agree with picked()
static func _check_paths(errs: PackedStringArray, when: String) -> void:
	var b: String = picked("ball")
	var v: String = picked("van")
	var j: String = picked("jersey")
	var want_b: String = "res://assets/ball/ball_%d.png" % int((ITEMS[b] as Dictionary)["n"]) if b != "" else DEFAULT_BALL
	var want_v: String = "res://assets/map/van_%d.png" % int((ITEMS[v] as Dictionary)["n"]) if v != "" else DEFAULT_VAN
	var want_j: String = "_j%d" % int((ITEMS[j] as Dictionary)["n"]) if j != "" else ""
	if ball_sheet() != want_b or van_path() != want_v or jersey_suffix() != want_j:
		errs.append("%s: paths %s %s %s" % [when, ball_sheet(), van_path(), jersey_suffix()])
