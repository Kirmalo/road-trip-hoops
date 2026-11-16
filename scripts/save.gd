extends RefCounted
# The Road Trip save file (P5-05, board "Save format"). Static only, used through preload:
#   const Save = preload("res://scripts/save.gd")
#   Save.write(data)          # true when the file is on disk
#   var d: Dictionary = Save.read()   # {} = no trip (missing, broken, or not a trip save)
# One trip at a time in user://trip.json. trip.gd builds and checks the dictionary (Trip.to_dict / from_dict); this
# file only writes and reads it safely:
#   - written to a temp file first, then renamed over the save, so a crash or a closed tab never leaves half a file
#   - every save has "version" (VERSION) and "serial" (counts up on each write). If a temp file is left over (the
#     rename never happened), read() takes whichever of the two is valid and newer
#   - a missing, empty, corrupt or non-trip file reads as {} (no trip): never an error, never a crash
#   - on the web, user:// is IndexedDB; Godot syncs it when a file is closed, so after the rename a tiny marker file is
#     written and closed to sync the renamed save too (survives a page reload)
# Test runs (--trip-test, --triptest-data, or use_test_file = true) use user://trip_test.json, never the owner's save.
# Settings stay in user://settings.cfg (menu.gd / difficulty.gd), not here.

const VERSION := 1                          # bump when the format changes; trip.gd from_dict() reads older versions
const PATH := "user://trip.json"
const TEST_PATH := "user://trip_test.json"
const TMP_SUFFIX := ".tmp"
const SYNC_PATH := "user://trip.sync"       # closed after each save: makes the web build flush IndexedDB again
const TEST_FLAGS := ["--trip-test", "--triptest-data"]
const MAX_BYTES := 1000000                  # a trip save is a few KB; anything bigger is not ours

static var use_test_file := false           # set by tests to force TEST_PATH
static var last_error := ""                 # why the last read() or write() failed ("" = fine); for test prints
static var _serial := 0                     # the newest serial written or read this run

# the save file in use (the test file in test runs)
static func path() -> String:
	if use_test_file:
		return TEST_PATH
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	for f in TEST_FLAGS:
		if cmd.has(f):
			return TEST_PATH
	return PATH

# true when a valid trip save exists (the title shows CONTINUE)
static func exists() -> bool:
	return not read().is_empty()

# Writes the trip dictionary (adds "version" and "serial"). Returns false (and sets last_error) when it could not.
static func write(data: Dictionary) -> bool:
	last_error = ""
	var p: String = path()
	var tmp: String = p + TMP_SUFFIX
	var d: Dictionary = data.duplicate(true)
	_serial += 1
	d["version"] = VERSION
	d["serial"] = _serial
	var text: String = JSON.stringify(d, "\t")
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		last_error = "open %s: %s" % [tmp, error_string(FileAccess.get_open_error())]
		push_warning("Save: " + last_error)
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
		push_warning("Save: " + last_error)
	_sync()
	return err == OK

# The trip dictionary, or {} when there is none or it is broken. Never fails.
static func read() -> Dictionary:
	last_error = ""
	var p: String = path()
	var main: Dictionary = _read_file(p)
	var tmp: Dictionary = _read_file(p + TMP_SUFFIX)
	var d: Dictionary = main
	if not tmp.is_empty() and (main.is_empty() or int(tmp.get("serial", 0)) > int(main.get("serial", 0))):
		d = tmp
	if d.is_empty():
		if last_error == "":
			last_error = "no save"
		return {}
	last_error = ""
	_serial = maxi(_serial, int(d.get("serial", 0)))
	return d

# Deletes the trip (and a left-over temp file). New trip after the title's confirmation writes over it anyway.
static func erase() -> void:
	var p: String = path()
	for f in [p, p + TMP_SUFFIX]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	_sync()

# one file -> its dictionary, or {} (sets last_error) when missing, too big, not JSON, or not a trip save
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
	return d

# the web build syncs user:// to IndexedDB when a file is closed: close one more after the rename
static func _sync() -> void:
	if not OS.has_feature("web"):
		return
	var f: FileAccess = FileAccess.open(SYNC_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(str(_serial))
		f.close()
