extends RefCounted
# The Legends save file (P9-02, board "Shared contract: Legends save"). Static only, used through preload:
#   const LegendsSave = preload("res://scripts/legends_save.gd")
#   LegendsSave.write(d)                      # true when the file is on disk
#   var d: Dictionary = LegendsSave.read()    # {} = no Legends progress (missing, broken, too big or not ours)
# The Legends progress is its own file, user://legends.json, kept across NEW TRIP (trip.json stays version 2).
# legends.gd (P9-12) owns the meaning of the data; this file only writes and reads it safely, like save.gd:
#   - written to a temp file first, then renamed over the save, so a crash or a closed tab never leaves half a file
#   - every save has "version" (VERSION) and "serial" (counts up on each write). If a temp file is left over (the
#     rename never happened), read() takes whichever of the two is valid and newer
#   - a missing, empty, corrupt, oversized or non-Legends file reads as {}: never an error, never a crash
#   - read() returns a clean dictionary: the five fields always there with the right types, bad entries dropped,
#     token values clamped to 0..TOKEN_MAX. A newer version loads what fits (the known fields; anything else is
#     dropped and the next write saves version VERSION)
#   - on the web, user:// is IndexedDB; Godot syncs it when a file is closed, so after the rename a tiny marker file is
#     written and closed to sync the renamed save too (survives a page reload)
# File: {"version": 1, "serial": n, "tokens": {"lg:<id>": 0..3, "fin:<chapter>": 0..3}, "unlocked": [ids],
#        "seen": [scene ids], "finales": [chapter ids won], "mentors": {"<legend id>": "<roster player id>"}}
# Test runs (any user argument after `--`, or use_test_file = true) use user://legends_test.json, never the owner's.
# self_test() checks all of it in a scratch file (user://legends_selftest.json) and returns "" when OK.

const VERSION := 1                           # bump when the format changes; read() loads what fits of a newer one
const PATH := "user://legends.json"
const TEST_PATH := "user://legends_test.json"
const SELFTEST_PATH := "user://legends_selftest.json"   # self_test() only
const TMP_SUFFIX := ".tmp"
const SYNC_PATH := "user://legends.sync"     # closed after each save: makes the web build flush IndexedDB again
const MAX_BYTES := 200000                    # a Legends save is well under 2 KB; anything bigger is not ours
const TOKEN_MAX := 3                         # best tokens per challenge or finale (1 / 2 / 3 per level)
const TOKEN_PREFIXES := ["lg:", "fin:"]      # the token keys: "lg:<legend id>", "fin:<chapter id>"
const MAX_ID_LEN := 64                       # longer ids or keys are dropped (not ours)
const FIELDS := ["tokens", "unlocked", "seen", "finales", "mentors"]

static var use_test_file := false            # set by tests to force TEST_PATH
static var last_error := ""                  # why the last read() or write() failed ("" = fine); for test prints
static var _serial := 0                      # the newest serial written or read this run
static var _path_override := ""              # self_test() only

# the save file in use (the test file in any test run)
static func path() -> String:
	if _path_override != "":
		return _path_override
	if use_test_file or not OS.get_cmdline_user_args().is_empty():
		return TEST_PATH
	return PATH

# true when a valid Legends save exists
static func exists() -> bool:
	return not read().is_empty()

# an empty Legends state (what a fresh install has); legends.gd may start from it
static func blank() -> Dictionary:
	return {"version": VERSION, "tokens": {}, "unlocked": [], "seen": [], "finales": [], "mentors": {}}

# Writes the Legends dictionary (cleaned like read(), adds "version" and "serial"). Returns false (and sets
# last_error) when it could not.
static func write(data: Dictionary) -> bool:
	last_error = ""
	var p: String = path()
	var tmp: String = p + TMP_SUFFIX
	var d: Dictionary = clean(data)
	_serial += 1
	d["version"] = VERSION
	d["serial"] = _serial
	var text: String = JSON.stringify(d, "\t")
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		last_error = "open %s: %s" % [tmp, error_string(FileAccess.get_open_error())]
		push_warning("LegendsSave: " + last_error)
		return false
	f.store_string(text)
	f.flush()
	f.close()
	# rename the temp file over the save; some platforms won't rename over an existing file, so remove it then
	var err: int = DirAccess.rename_absolute(tmp, p)
	if err != OK:
		DirAccess.remove_absolute(p)
		err = DirAccess.rename_absolute(tmp, p)
	if err != OK:
		# the temp file is complete and newer: read() will pick it up next time
		last_error = "rename %s: %s" % [tmp, error_string(err)]
		push_warning("LegendsSave: " + last_error)
	_sync()
	return err == OK

# The Legends dictionary (clean, see clean()), or {} when there is none or it is broken. Never fails.
static func read() -> Dictionary:
	last_error = ""
	var p: String = path()
	var main: Dictionary = _read_file(p)
	var main_err: String = last_error
	var tmp: Dictionary = _read_file(p + TMP_SUFFIX)
	var d: Dictionary = main
	if not tmp.is_empty() and (main.is_empty() or int(tmp.get("serial", 0)) > int(main.get("serial", 0))):
		d = tmp
	if d.is_empty():
		if main_err != "":
			last_error = main_err
		elif last_error == "":
			last_error = "no save"
		return {}
	last_error = ""
	_serial = maxi(_serial, int(d.get("serial", 0)))
	var out: Dictionary = clean(d)
	out["serial"] = int(d.get("serial", 0))
	return out

# Deletes the Legends save (and a left-over temp file).
static func erase() -> void:
	var p: String = path()
	for f in [p, p + TMP_SUFFIX]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	_sync()

# Any dictionary -> the five fields with the right types: tokens {"lg:x"|"fin:x": int 0..TOKEN_MAX}, unlocked /
# seen / finales [unique non-empty strings, in order], mentors {legend id: player id, both non-empty strings}.
# Bad entries are dropped, never an error. "version" is VERSION (a newer file's own number is not kept).
static func clean(src: Dictionary) -> Dictionary:
	var out: Dictionary = blank()
	var t = src.get("tokens", null)
	if t is Dictionary:
		var tokens: Dictionary = {}
		for k in t:
			var v = t[k]
			if not (k is String) or not _token_key_ok(k):
				continue
			if not (v is float or v is int):
				continue
			var n: int = clampi(int(v), 0, TOKEN_MAX)
			if n > 0:
				tokens[k] = n
		out["tokens"] = tokens
	for field in ["unlocked", "seen", "finales"]:
		out[field] = _id_list(src.get(field, null))
	var m = src.get("mentors", null)
	if m is Dictionary:
		var mentors: Dictionary = {}
		for k in m:
			var v = m[k]
			if _id_ok(k) and _id_ok(v):
				mentors[k] = v
		out["mentors"] = mentors
	return out

static func _token_key_ok(k: String) -> bool:
	if k.length() > MAX_ID_LEN:
		return false
	for pre in TOKEN_PREFIXES:
		var s: String = pre
		if k.begins_with(s) and k.length() > s.length():
			return true
	return false

static func _id_ok(v) -> bool:
	if not (v is String):
		return false
	var s: String = v
	return s != "" and s.length() <= MAX_ID_LEN

static func _id_list(v) -> Array:
	var out: Array = []
	if not (v is Array):
		return out
	for x in v:
		if _id_ok(x) and not out.has(x):
			out.append(x)
	return out

# one file -> its raw dictionary, or {} (sets last_error) when missing, too big, not JSON, or not a Legends save
static func _read_file(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var f: FileAccess = FileAccess.open(p, FileAccess.READ)
	if f == null:
		last_error = "open %s: %s" % [p, error_string(FileAccess.get_open_error())]
		return {}
	if f.get_length() <= 0 or f.get_length() > MAX_BYTES:
		last_error = "%s: bad size %d" % [p, f.get_length()]
		f.close()
		return {}
	var text: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		last_error = "%s: not JSON (line %d: %s)" % [p, json.get_error_line(), json.get_error_message()]
		return {}
	var v = json.data
	if not (v is Dictionary):
		last_error = "%s: not an object" % p
		return {}
	var d: Dictionary = v
	var ver = d.get("version", null)
	if not (ver is float or ver is int) or int(ver) < 1:
		last_error = "%s: no version" % p
		return {}
	# ours = at least one Legends field (every write has all five); a trip save or another file is not
	var any_field := false
	for k in FIELDS:
		if d.has(k):
			any_field = true
	if not any_field:
		last_error = "%s: not a Legends save" % p
		return {}
	return d

# the web build syncs user:// to IndexedDB when a file is closed: close one more after the rename
static func _sync() -> void:
	if not OS.has_feature("web"):
		return
	var f: FileAccess = FileAccess.open(SYNC_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(str(_serial))
		f.close()

# --- self test ---------------------------------------------------------------------------------------------------

# Round-trips a full and an empty file and feeds read() broken, oversized, foreign, newer and left-over temp files,
# all in SELFTEST_PATH (never the owner's or a test run's file). Returns "" when OK, else the first reasons.
static func self_test() -> String:
	var errs: Array = []
	var saved_serial: int = _serial
	var saved_test: bool = use_test_file
	_path_override = SELFTEST_PATH
	_wipe()

	# the paths: the owner's, the test file in any test run
	_check(errs, path() == SELFTEST_PATH, "override path %s" % path())
	_path_override = ""
	var expect: String = TEST_PATH if not OS.get_cmdline_user_args().is_empty() else PATH
	_check(errs, path() == expect, "run path %s (want %s)" % [path(), expect])
	use_test_file = true
	_check(errs, path() == TEST_PATH, "use_test_file path %s" % path())
	use_test_file = saved_test
	_path_override = SELFTEST_PATH

	# missing: {} and no crash
	_check(errs, read().is_empty() and not exists(), "missing file read as a save")
	_check(errs, last_error == "no save", "missing last_error '%s'" % last_error)

	# a full file round-trips exactly (the order of the lists kept)
	var full: Dictionary = {
		"tokens": {"lg:lg_alpha": 3, "lg:lg_bravo": 1, "lg:lg_charlie": 2, "fin:grand": 2},
		"unlocked": ["lg_alpha", "lg_charlie", "lg_bravo"],
		"seen": ["grand_intro", "lg_alpha_unlock"],
		"finales": ["grand"],
		"mentors": {"lg_alpha": "p_rookie", "lg_bravo": "p_kid"},
	}
	_check(errs, write(full), "write full: %s" % last_error)
	_check(errs, FileAccess.file_exists(SELFTEST_PATH) and not FileAccess.file_exists(SELFTEST_PATH + TMP_SUFFIX),
		"write full left no file or a temp file")
	var back: Dictionary = read()
	_check(errs, exists(), "full: exists() false")
	_check(errs, int(back.get("version", 0)) == VERSION and int(back.get("serial", 0)) > 0, "full: version/serial")
	for k in FIELDS:
		_check(errs, _same(back.get(k), full[k]), "full: %s %s != %s" % [k, str(back.get(k)), str(full[k])])
	_check(errs, back["unlocked"] == ["lg_alpha", "lg_charlie", "lg_bravo"], "full: unlocked order")
	_check(errs, back["tokens"]["lg:lg_alpha"] is int, "full: tokens are not ints")
	# write(read()) is stable
	_check(errs, write(back), "rewrite: %s" % last_error)
	var back2: Dictionary = read()
	for k in FIELDS:
		_check(errs, _same(back2.get(k), full[k]), "rewrite: %s changed" % k)
	_check(errs, int(back2["serial"]) > int(back["serial"]), "serial did not count up")

	# an empty file round-trips: every field there and empty
	_check(errs, write({}), "write empty: %s" % last_error)
	var e: Dictionary = read()
	_check(errs, not e.is_empty(), "empty save read as missing")
	for k in FIELDS:
		_check(errs, e.has(k) and e[k].is_empty(), "empty: %s = %s" % [k, str(e.get(k))])
	_check(errs, e["tokens"] is Dictionary and e["mentors"] is Dictionary and e["unlocked"] is Array
		and e["seen"] is Array and e["finales"] is Array, "empty: field types")
	_check(errs, _same(blank(), {"version": VERSION, "tokens": {}, "unlocked": [], "seen": [], "finales": [],
		"mentors": {}}), "blank()")

	# broken, empty, oversized, not an object, no version, a trip save: all {}
	var bad: Dictionary = {
		"not JSON": "{\"version\": 1, \"tokens\": {",
		"empty file": "",
		"array": "[1, 2, 3]",
		"string": "\"legends\"",
		"no version": "{\"tokens\": {\"lg:lg_alpha\": 3}}",
		"version 0": "{\"version\": 0, \"tokens\": {}}",
		"text version": "{\"version\": \"1\", \"tokens\": {}}",
		"trip save": "{\"version\": 2, \"serial\": 4, \"city\": \"chicago\", \"roster\": []}",
		"oversized": "{\"version\": 1, \"seen\": [\"" + "x".repeat(MAX_BYTES) + "\"]}",
	}
	for why in bad:
		_put(SELFTEST_PATH, str(bad[why]))
		_check(errs, read().is_empty(), "%s read as a save" % why)
		_check(errs, last_error != "", "%s: no last_error" % why)
		_check(errs, not exists(), "%s: exists() true" % why)

	# a newer version with odd values: what fits loads, the rest is dropped, never a crash
	var newer: Dictionary = {
		"version": 7, "serial": 3, "gems": 99, "era_teams": {"x": 1},
		"tokens": {"lg:lg_alpha": 9, "lg:lg_bravo": -2, "fin:grand": 2.0, "lg:": 3, "fin:": 1, "zz:x": 3,
			"lg:lg_delta": "3", "lg:lg_echo": [1], "lg:lg_fox": 0},
		"unlocked": ["lg_alpha", "lg_alpha", "", 5, null, {"a": 1}, "lg_bravo", "x".repeat(MAX_ID_LEN + 1)],
		"seen": "grand_intro",
		"finales": [["grand"], "grand"],
		"mentors": {"lg_alpha": "p_rookie", "lg_bravo": 7, "lg_charlie": "", "": "p_kid"},
	}
	_put(SELFTEST_PATH, JSON.stringify(newer))
	var n: Dictionary = read()
	_check(errs, not n.is_empty(), "newer version did not load: %s" % last_error)
	_check(errs, _same(n.get("tokens"), {"lg:lg_alpha": 3, "fin:grand": 2}), "newer tokens %s" % str(n.get("tokens")))
	_check(errs, _same(n.get("unlocked"), ["lg_alpha", "lg_bravo"]), "newer unlocked %s" % str(n.get("unlocked")))
	_check(errs, _same(n.get("seen"), []), "newer seen %s" % str(n.get("seen")))
	_check(errs, _same(n.get("finales"), ["grand"]), "newer finales %s" % str(n.get("finales")))
	_check(errs, _same(n.get("mentors"), {"lg_alpha": "p_rookie"}), "newer mentors %s" % str(n.get("mentors")))
	_check(errs, not n.has("gems") and not n.has("era_teams") and int(n.get("version", 0)) == VERSION,
		"newer: unknown fields kept or version %s" % str(n.get("version")))
	# a file with only some fields loads the rest empty
	_put(SELFTEST_PATH, "{\"version\": 1, \"unlocked\": [\"lg_alpha\"]}")
	var part: Dictionary = read()
	_check(errs, _same(part.get("unlocked"), ["lg_alpha"]) and part.get("tokens") is Dictionary
		and part["tokens"].is_empty() and part.get("mentors") is Dictionary, "partial file %s" % str(part))
	# write() cleans too
	_check(errs, write({"tokens": {"lg:lg_alpha": 5, "bogus": 1}, "seen": ["a", "a", 3]}), "write dirty")
	var w: Dictionary = read()
	_check(errs, _same(w.get("tokens"), {"lg:lg_alpha": 3}) and _same(w.get("seen"), ["a"]), "write did not clean")

	# a left-over temp file: the newer valid one wins, a broken one is ignored
	_wipe()
	_check(errs, write({"unlocked": ["lg_alpha"]}), "temp: base write")
	var base_serial: int = int(read().get("serial", 0))
	_put(SELFTEST_PATH + TMP_SUFFIX, JSON.stringify({"version": 1, "serial": base_serial + 1,
		"unlocked": ["lg_alpha", "lg_bravo"]}))
	_check(errs, _same(read().get("unlocked"), ["lg_alpha", "lg_bravo"]), "newer temp file not taken")
	_put(SELFTEST_PATH + TMP_SUFFIX, JSON.stringify({"version": 1, "serial": base_serial - 1, "unlocked": []}))
	_check(errs, _same(read().get("unlocked"), ["lg_alpha"]), "older temp file taken")
	_put(SELFTEST_PATH + TMP_SUFFIX, "{broken")
	_check(errs, _same(read().get("unlocked"), ["lg_alpha"]), "broken temp file hid the save")
	DirAccess.remove_absolute(SELFTEST_PATH)
	_put(SELFTEST_PATH + TMP_SUFFIX, JSON.stringify({"version": 1, "serial": 1, "finales": ["grand"]}))
	_check(errs, _same(read().get("finales"), ["grand"]), "temp file alone not taken")
	# the next write after a read counts on from the newest serial seen, so it wins over the temp
	_put(SELFTEST_PATH + TMP_SUFFIX, JSON.stringify({"version": 1, "serial": 500, "finales": ["grand"]}))
	read()
	_check(errs, write({"finales": []}), "write after temp")
	_check(errs, _same(read().get("finales"), []) and int(read().get("serial", 0)) > 500, "write lost to an old temp")

	# erase() removes the save and a temp file
	_put(SELFTEST_PATH + TMP_SUFFIX, "{}")
	erase()
	_check(errs, not FileAccess.file_exists(SELFTEST_PATH) and not FileAccess.file_exists(SELFTEST_PATH + TMP_SUFFIX),
		"erase left a file")
	_check(errs, read().is_empty(), "read after erase")

	_wipe()
	_path_override = ""
	_serial = maxi(saved_serial, _serial)
	use_test_file = saved_test
	last_error = ""
	if errs.is_empty():
		return ""
	var shown: Array = errs.slice(0, 6)
	return "; ".join(PackedStringArray(shown)) + ("" if errs.size() <= 6 else " (+%d more)" % (errs.size() - 6))

static func _check(errs: Array, ok: bool, why: String) -> void:
	if not ok:
		errs.append(why)

# equal by value (JSON numbers come back as floats; clean() makes token values ints, so compare as text)
static func _same(a, b) -> bool:
	return JSON.stringify(a, "", true) == JSON.stringify(b, "", true)

static func _put(p: String, text: String) -> void:
	var f: FileAccess = FileAccess.open(p, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()

static func _wipe() -> void:
	for f in [SELFTEST_PATH, SELFTEST_PATH + TMP_SUFFIX]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
