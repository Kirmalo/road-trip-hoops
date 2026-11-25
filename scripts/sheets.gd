extends RefCounted
# Player sprite sheets (P6-05, board "Player sheet format v2"): one place that knows the sheet layouts, so nothing
# else hardcodes 40 x 64 frames or 37 columns. Static only, no game state; use it through
#   const Sheets = preload("res://scripts/sheets.gd")
#
# Two formats:
#   v1 (built in, the Phase 4/5 layout): assets/players/<sheet>.png, 37 columns x 5 rows of 40 x 64 frames, the
#      floor on row 59; hands in assets/players/hands.json ("players".<sheet>[row][column] = {L, R}). P6-25 removed
#      the v1 files (every player has a v2 sheet), so the folder is gone and nothing ships as v1; the reader stays
#      (a v1 sheet dropped back into the folder still draws) and self_test() checks it on a fixture it builds.
#   v2 (owner-approved animation sample v1, docs/art/anim_sample_v1.md): assets/players2/format.json is the truth.
#      64 x 96 frames, art scale 1.25, drawn 2x in the game; the floor point under the pelvis is on row 88, x 32.
#      Each direction is one row of `cols` logical columns (animation "start" + frame). The columns are stored in
#      pages of at most `page_cols` (32) columns, so no texture is wider than 2048 px:
#        cols <= page_cols:  assets/players2/<sheet>.png              (one page; <sheet>_p0.png also accepted)
#        cols >  page_cols:  assets/players2/<sheet>_p0.png, _p1.png ...  (page p holds columns p*page_cols ...)
#      Every page is len(dirs) rows high (5 x 96 = 480 px); the last page may be narrower (or padded).
#      format.json: {"version": 2, "frame": [64, 96], "feet_row": 88, "center_x": 32, "head_px": 50,
#                    "draw_scale": 2.0, "dirs": ["S", "SE", "E", "NE", "N"], "cols": N, "page_cols": 32,
#                    "anims": {"idle": {"start": 0, "frames": 6, "fps": 6, "loop": true}, ...}}
#      hands.json (the sample's points file, keyed by animation and direction, so it doesn't depend on the columns):
#                   {"frame": [64, 96], "feet_row": 88,
#                    "bodies": {"<body>": {"<anim>": {"<DIR>": [{"hands": {"L": [x, y], "R": [x, y]},
#                               "ball": [x, y, front] or null, "ball_floor": [x, y], "ball_h": h}, ...per frame]}}},
#                    "sheets": {"<sheet>": "<body>"}}       # recolors share their body's points
#      cards/<sheet>.png: the idle frame facing the camera (one 64 x 96 frame) for the lineup / recruit / bracket.
# Fallback chain: a v2 sheet, then a v1 sheet, of each id the caller lists (load_first / card_first: e.g. the _crew
# recolor, then his own sheet, then the Quick Game sheet of his slot); nothing at all = {} / null (the caller draws
# the Kenney sprite, assets/blue_n.png / red_n.png, or a silhouette). v1 and v2 players can share a court.
# Directions: rows 0..4 = S, SE, E, NE, N; SW, W and NW are SE, E and NE mirrored (x' = width - 1 - x, L and R swap).
# Animation names are the board's "Animation table". A sheet without one gets the nearest it has (ALIASES), e.g. on a
# v1 sheet run_dribble -> dribble, slide -> run, dunk_* -> dunk, pass_* -> pass, fall -> stumble, land -> idle.
# v2.1 (board "v2.1: indexed pages + palettes"): format.json "indexed": true. Pages are 8-bit grayscale (L8), the gray
#      value a palette index (0 = transparent); palettes/<id>.png (256 x 1 RGBA) per sheet AND per recolor. A recolor
#      (<sheet>_crew) has only a palette and draws its base sheet's pages (palettes.json or format.json "recolors":
#      {"<recolor>": "<base>"}, else the plain id before _crew). load_sheet() then has "indexed": true and "palette";
#      the player draws it through material(sheet) (scripts/shaders/palette.gdshader). Cards stay RGBA files.
# Jerseys (P8-10): your crew's sheet ids may carry a jersey, <sheet>_j<N> (an underdog) or <sheet>_crew_j<N> (anyone
#      else; cities.gd crew_sheet()). A jersey id whose palette is missing falls back to the normal look: with_base()
#      lists it before <sheet>_crew and <sheet>, and load_sheet() / card_info() of a missing jersey id give the first of
#      those that exists (so a sheet without that jersey wears the plain crew colors, never the Quick Game slot sheet).
# Extra animations (P9-04c, board "Art files", L6 b): an animation only some sheets carry (the legends' hook shot).
#      format.json "extra": {"hook": {"start": 0, "frames": 10, "fps": 0, "loop": false, "ms": [...], events...,
#      "sheets": ["lg_...", ...]}}: the same keys as an "anims" row, plus the sheets that carry it (page ids, or any id
#      along with_base(); a recolor draws its base sheet's). "start" is the column in the extra column space (an extra
#      without it goes after the ones before it); every direction row as usual. A sheet that carries extras has extra
#      pages <pages id>_x0.png, _x1.png ... after its normal pages, page_cols(fmt) columns each (x page q holds extra
#      columns q*page_cols ...; the last may be narrower), the same rows and the same palettes, so every recolor and
#      jersey works. load_sheet() of such a sheet gives its own "fmt": the format with the extras it carries added to
#      "anims" (start = page_count * page_cols + the extra start, "cols" grown to match, "extras": [names]), and the
#      x pages appended to "pages"; frame_index(), frame_region(), hand() and the anim_* helpers then work on them like
#      on any animation (hand and ball points: hands.json body "<extra name>"). Every other sheet keeps the shared
#      format (the same Dictionary as v2_format()), so it draws exactly as before; a format.json without "extra" reads
#      as before. A listed sheet with a missing or wrong-sized x page loads without its extras (one warning), and an
#      extra name resolves through ALIASES (hook -> shoot) on any sheet without it. has_anim(sheet, anim) says which.
# Test: Sheets.self_test() (prints SHEETS lines, ends with SHEETS OK / FAILED); it builds a v2 sheet in user://.
# Test flag: -- --players2-dir DIR reads the v2 files from DIR (res://, user:// or an absolute path) instead.

const V1_DIR := "res://assets/players/"
const V2_DIR := "res://assets/players2/"
const FORMAT_FILE := "format.json"
const HANDS_FILE := "hands.json"
const CARD_SUBDIR := "cards/"
const CREW_SUFFIX := "_crew"          # a city player's recolor in your colors (cities.gd crew_sheet)
const JERSEY_TAG := "_j"              # P8-10: a jersey palette <sheet>_j<N> / <sheet>_crew_j<N> (a star reward)
const PAGE_SUFFIX := "_p"             # v2 page files: <sheet>_p0.png, <sheet>_p1.png ...
const MAX_TEXTURE := 2048             # px: no page may be wider or taller (GLES3 / WebGL2 minimum)
const DIR_NAMES := ["S", "SE", "E", "NE", "N"]
const PALETTE_SUBDIR := "palettes/"   # v2.1: palettes/<sheet>.png, 256 x 1 RGBA (index 0 transparent)
const PALETTES_FILE := "palettes.json"  # v2.1 (optional): {"<recolor>": "<base sheet>"} (or {"recolors": {...}})
const PALETTE_SIZE := 256
const PALETTE_SHADER := "res://scripts/shaders/palette.gdshader"
const DIR_FLAG := "--players2-dir"    # test flag: read the v2 files from another folder
const GRAY_SAMPLES := 48              # an index page imported as RGB: this x this pixels checked to be gray
const EXTRA_SECTION := "extra"        # P9-04c: format.json's extra animations (only the sheets they list carry them)
const EXTRA_SHEETS := "sheets"        # P9-04c: an extra's list of the sheet ids that carry it
const EXTRA_PAGE_SUFFIX := "_x"       # P9-04c: extra pages <pages id>_x0.png, _x1.png ... after the normal pages

# today's v1 sheet (player.gd SHEET_FRAME, SHEET_COLS, SHEET_FEET_Y, ANIMS and the *_FPS constants). fps 0 = the
# frame comes from a progress (jump, shot meter), not a clock.
const V1_FORMAT := {
	"version": 1, "frame": [40, 64], "feet_row": 59, "center_x": 20, "head_px": 40, "draw_scale": 2.0,
	"dirs": ["S", "SE", "E", "NE", "N"], "cols": 37, "page_cols": 37,
	"anims": {
		"idle": {"start": 0, "frames": 2, "fps": 2.0, "loop": true},
		"run": {"start": 2, "frames": 6, "fps": 11.0, "loop": true},
		"dribble": {"start": 8, "frames": 4, "fps": 7.0, "loop": true},
		"shoot": {"start": 12, "frames": 4, "fps": 0.0, "loop": false},
		"dunk": {"start": 16, "frames": 5, "fps": 0.0, "loop": false},
		"layup": {"start": 21, "frames": 3, "fps": 0.0, "loop": false},
		"block": {"start": 24, "frames": 3, "fps": 0.0, "loop": false},
		"poke": {"start": 27, "frames": 2, "fps": 8.0, "loop": false},
		"stumble": {"start": 29, "frames": 2, "fps": 6.0, "loop": true},
		"pass": {"start": 31, "frames": 2, "fps": 8.0, "loop": false},
		"celebrate": {"start": 33, "frames": 4, "fps": 6.0, "loop": true},
	},
}

# An animation a sheet doesn't have -> the nearest ones it may have, in order (then "idle"). Covers the v2 names on a
# v1 sheet (board: run_dribble -> dribble, slide -> run, dunk_* -> dunk, pass_* -> pass, fall -> stumble,
# land -> idle) and today's v1 names on a v2 sheet (dunk -> dunk_two, pass -> pass_chest, poke -> steal, ...).
const ALIASES := {
	"run_dribble": ["rundribble", "dribble"],
	"rundribble": ["run_dribble", "dribble"],
	"cross": ["dribble"],
	# *_l = the left-hand versions (mirrored in the body); a sheet without them uses the right-hand one
	"dribble_l": ["dribble"],
	"run_dribble_l": ["run_dribble", "rundribble", "dribble"],
	"cross_l": ["cross", "dribble"],
	"dunk_alley": ["dunk_two", "dunk"],
	"hold": ["idle"],
	"catch": ["dribble", "idle"],
	"slide": ["run"],
	"dunk_one": ["dunk_two", "dunk"],
	"dunk_two": ["dunk"],
	"dunk_tomahawk": ["dunk_one", "dunk_two", "dunk"],
	"dunk_windmill": ["dunk_tomahawk", "dunk_two", "dunk"],
	"rim_hang": ["dunk_two", "dunk"],
	"dunk": ["dunk_two", "dunk_one"],
	"pass_chest": ["pass"],
	"pass_bounce": ["pass_chest", "pass"],
	"pass_lob": ["pass_chest", "pass"],
	"pass": ["pass_chest"],
	"steal": ["poke"],
	"poke": ["steal"],
	"fall": ["stumble"],
	"land": ["idle"],
	"celebrate_a": ["celebrate"],
	"celebrate_b": ["celebrate_a", "celebrate"],
	"celebrate": ["celebrate_a"],
	# P9-04c extras: a sheet without the extra plays the normal animation
	"hook": ["shoot"],
	"fadeaway": ["shoot"],   # P10: Midrange's extra; any other sheet plays the jump shot
	"stepback": ["shoot"],   # P11: Deep End's extra; any other sheet plays the jump shot
	"eurostep": ["layup"],   # P11: Zigzag's extra; any other sheet plays the layup
}

static var v2_dir := V2_DIR           # tests point this at a scratch folder (then clear_cache())
static var v1_dir := V1_DIR           # the same for v1 (self_test's fixture; no v1 files ship since P6-25)
static var _fmt2 = null               # format.json (Dictionary), {} when missing or invalid; null = not read yet
static var _hands1 = null             # v1 hands.json "players"; {} when missing
static var _hands2 = null             # v2 hands.json; {} when missing
static var _sheets := {}              # sheet id -> load_sheet() result ({} = no sheet of either format)
static var _cards := {}               # sheet id -> card_info() result
static var _ranges := {}              # fmt version -> [[start, end, anim], ...] (hand() lookups)
static var _recolors = null           # v2.1: recolor id -> base sheet id (palettes.json / format.json "recolors")
static var _materials := {}           # v2.1: palette texture -> ShaderMaterial (players with one sheet share it)
static var _shader: Shader = null
static var _dir_checked := false      # the --players2-dir flag was read
static var _warned_rgb := false
static var _xfmts := {}               # P9-04c: "names|need" -> the format with those extras added (shared by the sheets)
static var _warned_extra := {}        # P9-04c: pages id -> true once its missing extra pages were warned about

# ---------------- formats ----------------

# the v2 format from format.json ({} when there is none or it is not a usable v2 format)
static func v2_format() -> Dictionary:
	_check_dir()
	if _fmt2 == null:
		_fmt2 = {}
		var d = _read_json(v2_dir + FORMAT_FILE)
		if d is Dictionary and _valid_format(d):
			_fmt2 = d
		elif d != null:
			push_warning("Sheets: %s%s is not a usable v2 format" % [v2_dir, FORMAT_FILE])
	return _fmt2

# the --players2-dir test flag (read once)
static func _check_dir() -> void:
	if _dir_checked:
		return
	_dir_checked = true
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = args.find(DIR_FLAG)
	if i >= 0 and i + 1 < args.size():
		v2_dir = args[i + 1].trim_suffix("/") + "/"
		print("SHEETS v2 files from %s" % v2_dir)

static func v1_format() -> Dictionary:
	return V1_FORMAT

static func _valid_format(d: Dictionary) -> bool:
	if int(d.get("version", 0)) != 2:
		return false
	var fr = d.get("frame", [])
	if not (fr is Array) or (fr as Array).size() != 2 or int(fr[0]) <= 0 or int(fr[1]) <= 0:
		return false
	if int(d.get("cols", 0)) <= 0 or not (d.get("anims", null) is Dictionary):
		return false
	var dirs = d.get("dirs", [])
	return dirs is Array and (dirs as Array).size() > 0

static func frame_size(fmt: Dictionary) -> Vector2:
	var fr: Array = fmt.get("frame", [40, 64])
	return Vector2(float(fr[0]), float(fr[1]))

# the floor row inside a frame (the feet / floor point)
static func feet_y(fmt: Dictionary) -> float:
	return float(fmt.get("feet_row", 59))

# the body's centre column (the floor point's x)
static func center_x(fmt: Dictionary) -> float:
	return float(fmt.get("center_x", frame_size(fmt).x / 2.0))

# the character's height in frame pixels (v1 40, v2 about 50); the art scale between formats is head_px / 40
static func head_px(fmt: Dictionary) -> float:
	return float(fmt.get("head_px", 40))

# the in-game draw scale of a frame pixel (2x for both formats)
static func draw_scale(fmt: Dictionary) -> float:
	return float(fmt.get("draw_scale", 2.0))

static func cols(fmt: Dictionary) -> int:
	return int(fmt.get("cols", 37))

static func page_cols(fmt: Dictionary) -> int:
	var pc: int = int(fmt.get("page_cols", cols(fmt)))
	return clampi(pc, 1, maxi(1, cols(fmt)))

static func page_count(fmt: Dictionary) -> int:
	return int(ceil(float(cols(fmt)) / float(page_cols(fmt))))

static func dir_rows(fmt: Dictionary) -> int:
	return (fmt.get("dirs", DIR_NAMES) as Array).size()

# v2.1: the pages are palette indexes (draw them through material())
static func indexed(fmt: Dictionary) -> bool:
	return bool(fmt.get("indexed", false))

# ---------------- animations ----------------

# the animation this format really plays for `anim` (itself, else the nearest in ALIASES, else "idle"; "" if none)
static func resolve(fmt: Dictionary, anim: String) -> String:
	var anims: Dictionary = fmt.get("anims", {})
	if anims.has(anim):
		return anim
	for alt in ALIASES.get(anim, []):
		if anims.has(str(alt)):
			return str(alt)
	return "idle" if anims.has("idle") else ""

# Does this sheet really carry `anim` (not an alias)? `sheet` is a sheet id (String), a load_sheet() result, or a
# format Dictionary. P9-04c: true for an extra only on a sheet that lists it and has its x pages.
static func has_anim(sheet, anim: String) -> bool:
	var fmt: Dictionary = {}
	if sheet is String or sheet is StringName:
		var sh: Dictionary = load_sheet(str(sheet))
		fmt = sh.get("fmt", {})
	elif sheet is Dictionary:
		var d: Dictionary = sheet
		if d.has("fmt"):
			fmt = d["fmt"]
		else:
			fmt = d
	return (fmt.get("anims", {}) as Dictionary).has(anim)

# P9-04c: the format's extra animations, name -> its row (a copy, "start" filled in: the column in the extra space;
# "sheets" kept). Rows without frames, or named like a normal animation, are left out. {} without an "extra" section.
static func extra_anims(fmt: Dictionary) -> Dictionary:
	var out := {}
	var src = fmt.get(EXTRA_SECTION, null)
	if not (src is Dictionary):
		return out
	var normal: Dictionary = fmt.get("anims", {})
	var next := 0
	for a in src:
		var e = src[a]
		if not (e is Dictionary) or int((e as Dictionary).get("frames", 0)) <= 0 or normal.has(str(a)):
			continue
		var row: Dictionary = (e as Dictionary).duplicate(true)
		if not row.has("start"):
			row["start"] = next
		row["start"] = maxi(0, int(row["start"]))
		next = maxi(next, int(row["start"]) + int(row["frames"]))
		out[str(a)] = row
	return out

# P9-04c: the extras the format lists for this sheet id (by its pages id or any id along with_base()), in format
# order. Whether the sheet really has their pages: has_anim().
static func extras_for(sheet_id: String, fmt: Dictionary = {}) -> Array:
	var out: Array = []
	if sheet_id == "":
		return out
	var f: Dictionary = fmt if not fmt.is_empty() else v2_format()
	var ex: Dictionary = extra_anims(f)
	if ex.is_empty():
		return out
	var ids: Array = with_base(sheet_id)
	var base: String = pages_id(sheet_id)
	if not ids.has(base):
		ids.append(base)
	for a in ex:
		var list = (ex[a] as Dictionary).get(EXTRA_SHEETS, [])
		if not (list is Array):
			continue
		for id in ids:
			if (list as Array).has(id):
				out.append(a)
				break
	return out

static func _anim(fmt: Dictionary, anim: String) -> Dictionary:
	var a: String = resolve(fmt, anim)
	if a == "":
		return {}
	return (fmt.get("anims", {}) as Dictionary).get(a, {})

# frames in the animation (as resolved for this format), at least 1
static func anim_frames(fmt: Dictionary, anim: String) -> int:
	return maxi(1, int(_anim(fmt, anim).get("frames", 1)))

# frames per second of a clock-driven animation (0 = progress-driven)
static func anim_fps(fmt: Dictionary, anim: String) -> float:
	return float(_anim(fmt, anim).get("fps", 0.0))

static func anim_loops(fmt: Dictionary, anim: String) -> bool:
	return bool(_anim(fmt, anim).get("loop", false))

# an event frame of an animation (format.json, e.g. "release", "floor", "swat"), or `default` when it has none.
# A [first, last] range gives its first frame.
static func anim_event(fmt: Dictionary, anim: String, key: String, default: int = -1) -> int:
	var v = _anim(fmt, anim).get(key, null)
	if v is Array:
		return int(v[0]) if (v as Array).size() > 0 else default
	if v == null or not (v is float or v is int):
		return default
	return int(v)

# the drawn time of each frame in seconds (format.json "ms"; else 1 / fps; else 0.1 s)
static func anim_times(fmt: Dictionary, anim: String) -> PackedFloat32Array:
	var a: Dictionary = _anim(fmt, anim)
	var n: int = maxi(1, int(a.get("frames", 1)))
	var out := PackedFloat32Array()
	var ms = a.get("ms", null)
	var fps: float = float(a.get("fps", 0.0))
	for k in n:
		var t: float = 1.0 / fps if fps > 0.0 else 0.1
		if ms is Array and k < (ms as Array).size() and float(ms[k]) > 0.0:
			t = float(ms[k]) / 1000.0
		out.append(t)
	return out

# The frame index (dir_row * cols + column) of frame k of an animation, facing dir_row (0..4 = S, SE, E, NE, N).
# k wraps for a looping animation and is clamped for a one-shot. Feed it to frame_region() / hand().
static func frame_index(fmt: Dictionary, dir_row: int, anim: String, k: int) -> int:
	var a: Dictionary = _anim(fmt, anim)
	var n: int = maxi(1, int(a.get("frames", 1)))
	k = posmod(k, n) if bool(a.get("loop", false)) else clampi(k, 0, n - 1)
	var row: int = clampi(dir_row, 0, dir_rows(fmt) - 1)
	return row * cols(fmt) + int(a.get("start", 0)) + k

# frame_index() for a progress f in 0..1 through the animation (jumps, shot windups)
static func progress_index(fmt: Dictionary, dir_row: int, anim: String, f: float) -> int:
	var n: int = anim_frames(fmt, anim)
	return frame_index(fmt, dir_row, anim, int(clampf(f, 0.0, 0.999) * float(n)))

# ---------------- loading ----------------

# One sheet id, v2 first, then v1: {"id", "version", "fmt", "texture" (page 0), "pages": [Texture2D, ...]}.
# {} when neither exists (or the file doesn't match its format). Cached.
static func load_sheet(sheet_id: String) -> Dictionary:
	if sheet_id == "":
		return {}
	if _sheets.has(sheet_id):
		return _sheets[sheet_id]
	var out: Dictionary = _load_v2(sheet_id)
	if out.is_empty():
		out = _load_v1(sheet_id)
	if out.is_empty() and is_jersey(sheet_id):
		# P8-10: no such jersey for this sheet: the look without it (its "id" says which one is drawn)
		var ids: Array = with_base(sheet_id)
		out = load_first(ids.slice(1))
	_sheets[sheet_id] = out
	return out

# The first of these ids that has a sheet (each tried v2 then v1), e.g. [<sheet>_crew, <sheet>, "ny_q2"]. {} if none.
static func load_first(ids: Array) -> Dictionary:
	for id in ids:
		var s: Dictionary = load_sheet(str(id))
		if not s.is_empty():
			return s
	return {}

# [id] plus, for a _crew recolor, the plain sheet after it (the order the screens fall back in). A jersey id (P8-10)
# lists the look without the jersey after it: x_crew_j2 -> [x_crew_j2, x_crew, x], ud_deuce_j1 -> [ud_deuce_j1,
# ud_deuce], ud_deuce_j1_crew -> [ud_deuce_j1_crew, ud_deuce_j1, ud_deuce].
static func with_base(sheet_id: String) -> Array:
	var out: Array = [sheet_id]
	var rest := ""
	if sheet_id.ends_with(CREW_SUFFIX):
		rest = sheet_id.substr(0, sheet_id.length() - CREW_SUFFIX.length())
	else:
		rest = strip_jersey(sheet_id)
	if rest != "":
		out.append_array(with_base(rest))
	return out

# P8-10: the id without its jersey (x_crew_j2 -> x_crew, ud_deuce_j1 -> ud_deuce); "" when it ends in no _j<N>
static func strip_jersey(sheet_id: String) -> String:
	var at: int = sheet_id.rfind(JERSEY_TAG)
	if at <= 0:
		return ""
	var num: String = sheet_id.substr(at + JERSEY_TAG.length())
	if num == "" or num.lstrip("0123456789") != "":
		return ""
	return sheet_id.substr(0, at)

# P8-10: a jersey id (with_base() strips a jersey somewhere along it, e.g. x_crew_j1 or ud_deuce_j1_crew)
static func is_jersey(sheet_id: String) -> bool:
	if sheet_id.ends_with(CREW_SUFFIX):
		return is_jersey(sheet_id.substr(0, sheet_id.length() - CREW_SUFFIX.length()))
	return strip_jersey(sheet_id) != ""

static func _load_v2(sheet_id: String) -> Dictionary:
	var fmt: Dictionary = v2_format()
	if fmt.is_empty():
		return {}
	if indexed(fmt):
		return _load_indexed(fmt, sheet_id)
	var files: Array = []
	var pages: Array = _v2_pages(fmt, sheet_id, files)
	if pages.is_empty():
		return {}
	return _add_extras({"id": sheet_id, "version": 2, "fmt": fmt, "texture": pages[0], "pages": pages,
		"page_files": files}, sheet_id)

# v2.1: the palette of this id, drawn on its own pages or (a recolor) on its base sheet's pages
static func _load_indexed(fmt: Dictionary, sheet_id: String) -> Dictionary:
	var pal: Texture2D = _texture(v2_dir + PALETTE_SUBDIR + sheet_id + ".png")
	if pal == null:
		return {}
	if int(pal.get_width()) != PALETTE_SIZE or int(pal.get_height()) < 1:
		push_warning("Sheets: palette %s is %dx%d, want %dx1" % [sheet_id, pal.get_width(), pal.get_height(), PALETTE_SIZE])
		return {}
	var base: String = pages_id(sheet_id)
	var files: Array = []
	var pages: Array = _v2_pages(fmt, base, files)
	if pages.is_empty() and base != sheet_id:
		files = []
		pages = _v2_pages(fmt, sheet_id, files)
		base = sheet_id
	if pages.is_empty():
		return {}
	var img: Image = (pages[0] as Texture2D).get_image()
	if img != null and not [Image.FORMAT_L8, Image.FORMAT_R8].has(img.get_format()):
		# Godot's default lossless import stores a grayscale PNG as WebP, which comes back as RGB: it still draws right
		# (the shader reads the red channel) but takes 3-4x the video memory. A color page is refused.
		if not _gray_image(img):
			push_warning("Sheets: %s pages are not index images (format %d)" % [base, img.get_format()])
			return {}
		if not _warned_rgb:
			_warned_rgb = true
			push_warning("Sheets: %s index pages were imported as format %d, not L8 (3-4x the video memory): set the project's rendering/textures/lossless_compression/force_png = true" % [base, img.get_format()])
	return _add_extras({"id": sheet_id, "version": 2, "fmt": fmt, "texture": pages[0], "pages": pages, "indexed": true,
		"palette": pal, "pages_id": base, "page_files": files}, sheet_id)

# an image whose pixels are all gray (r = g = b), checked on a grid of samples: an index page stored as RGB
static func _gray_image(img: Image) -> bool:
	if img.is_compressed():
		return false
	var w: int = img.get_width()
	var h: int = img.get_height()
	for gy in GRAY_SAMPLES:
		for gx in GRAY_SAMPLES:
			var c: Color = img.get_pixel(int((float(gx) + 0.5) * float(w) / float(GRAY_SAMPLES)),
					int((float(gy) + 0.5) * float(h) / float(GRAY_SAMPLES)))
			if not is_equal_approx(c.r, c.g) or not is_equal_approx(c.g, c.b):
				return false
	return true

# v2.1: whose pages an id draws (a recolor -> its base sheet; anyone else -> himself)
static func pages_id(sheet_id: String) -> String:
	if _recolors == null:
		_recolors = {}
		var src = (v2_format() as Dictionary).get("recolors", null)
		var d = _read_json(v2_dir + PALETTES_FILE)
		if d is Dictionary:
			src = (d as Dictionary).get("recolors", d)
		if src is Dictionary:
			for k in src:
				if src[k] is String:
					_recolors[str(k)] = str(src[k])
	if (_recolors as Dictionary).has(sheet_id):
		return str(_recolors[sheet_id])
	var ids: Array = with_base(sheet_id)
	return str(ids[ids.size() - 1])

# the v2 pages of one sheet id ([] when any is missing or of the wrong size); their file paths are appended to `files`
static func _v2_pages(fmt: Dictionary, sheet_id: String, files: Array) -> Array:
	var n: int = page_count(fmt)
	var pages: Array = []
	for p in n:
		var tries: Array = [v2_dir + sheet_id + PAGE_SUFFIX + str(p) + ".png"]
		if n == 1:
			tries.push_front(v2_dir + sheet_id + ".png")
		var tex: Texture2D = null
		var used := ""
		for path in tries:
			tex = _texture(str(path))
			if tex != null:
				used = str(path)
				break
		if tex == null:
			return []
		var want_w: int = mini(page_cols(fmt), cols(fmt) - p * page_cols(fmt)) * int(frame_size(fmt).x)
		if not _page_ok(fmt, tex, want_w, "%s page %d" % [sheet_id, p]):
			return []
		pages.append(tex)
		files.append(used)
	return pages

# a page texture of the format's height, at least want_w wide, inside MAX_TEXTURE (a warning when not)
static func _page_ok(fmt: Dictionary, tex: Texture2D, want_w: int, what: String) -> bool:
	var h: int = int(frame_size(fmt).y) * dir_rows(fmt)
	var sz: Vector2 = tex.get_size()
	if int(sz.y) != h or int(sz.x) < want_w or sz.x > MAX_TEXTURE or sz.y > MAX_TEXTURE:
		push_warning("Sheets: %s is %dx%d, want %dx%d" % [what, int(sz.x), int(sz.y), want_w, h])
		return false
	return true

# P9-04c: a loaded v2 sheet plus the extras the format lists for it: its own format (the extras in "anims") and the
# x pages after its pages. Unchanged (the shared format) when it lists none or an x page is missing or wrong.
static func _add_extras(out: Dictionary, sheet_id: String) -> Dictionary:
	var fmt: Dictionary = out["fmt"]
	var names: Array = extras_for(sheet_id, fmt)
	if names.is_empty():
		return out
	var ex: Dictionary = extra_anims(fmt)
	var need := 0
	for a in names:
		need = maxi(need, int(ex[a]["start"]) + int(ex[a]["frames"]))
	var base: String = str(out.get("pages_id", sheet_id))
	var files: Array = []
	var xp: Array = _x_pages(fmt, base, need, files)
	if xp.is_empty():
		if not _warned_extra.has(base):
			_warned_extra[base] = true
			push_warning("Sheets: %s carries %s but its extra pages %s%s<N>.png are missing or the wrong size: it plays the normal animation instead" % [
					base, ", ".join(PackedStringArray(names)), base, EXTRA_PAGE_SUFFIX])
		return out
	var pages: Array = (out["pages"] as Array).duplicate()
	pages.append_array(xp)
	var pf: Array = (out.get("page_files", []) as Array).duplicate()
	pf.append_array(files)
	out["fmt"] = _extra_format(fmt, names, need)
	out["pages"] = pages
	out["page_files"] = pf
	out["extras"] = names
	return out

# P9-04c: the x pages of a pages id for `need` extra columns ([] when one is missing or of the wrong size)
static func _x_pages(fmt: Dictionary, base: String, need: int, files: Array) -> Array:
	var pc: int = page_cols(fmt)
	var n: int = int(ceil(float(need) / float(pc)))
	var out: Array = []
	for q in n:
		var path: String = v2_dir + base + EXTRA_PAGE_SUFFIX + str(q) + ".png"
		var tex: Texture2D = _texture(path)
		if tex == null:
			return []
		if not _page_ok(fmt, tex, mini(pc, need - q * pc) * int(frame_size(fmt).x), "%s extra page %d" % [base, q]):
			return []
		out.append(tex)
		files.append(path)
	return out

# P9-04c: the format with these extras added after the normal pages (cached: the sheets with the same extras share it)
static func _extra_format(fmt: Dictionary, names: Array, need: int) -> Dictionary:
	var key: String = "%s|%d" % [",".join(PackedStringArray(names)), need]
	if _xfmts.has(key):
		return _xfmts[key]
	var pc: int = page_cols(fmt)
	var first: int = page_count(fmt) * pc
	var ex: Dictionary = extra_anims(fmt)
	var anims: Dictionary = (fmt.get("anims", {}) as Dictionary).duplicate()
	for a in names:
		var row: Dictionary = (ex[a] as Dictionary).duplicate(true)
		row.erase(EXTRA_SHEETS)
		row["start"] = first + int(row["start"])
		row["extra"] = true
		anims[a] = row
	var f: Dictionary = fmt.duplicate()
	f["anims"] = anims
	f["cols"] = first + need
	f["page_cols"] = pc
	f["base_cols"] = cols(fmt)
	f["extra_page0"] = page_count(fmt)
	f["extras"] = names.duplicate()
	_xfmts[key] = f
	return f

# v2.1: the material that draws an indexed sheet in its palette (one per palette, shared by everyone wearing it; the
# sprite's flip and modulate still work). null for an RGBA sheet (draw it without a material).
static func material(sheet: Dictionary) -> ShaderMaterial:
	if not bool(sheet.get("indexed", false)) or sheet.get("palette", null) == null:
		return null
	var pal: Texture2D = sheet["palette"]
	var key: String = str(pal.get_instance_id())
	if _materials.has(key):
		return _materials[key]
	if _shader == null:
		_shader = load(PALETTE_SHADER) as Shader
	if _shader == null:
		return null
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("palette", pal)
	_materials[key] = m
	return m

static func _load_v1(sheet_id: String) -> Dictionary:
	var tex: Texture2D = _texture(v1_dir + sheet_id + ".png")
	if tex == null:
		return {}
	var want: Vector2 = frame_size(V1_FORMAT) * Vector2(cols(V1_FORMAT), dir_rows(V1_FORMAT))
	if tex.get_size() != want:
		return {}
	return {"id": sheet_id, "version": 1, "fmt": V1_FORMAT, "texture": tex, "pages": [tex]}

# The texture and source rectangle of a frame index (frame_index()) in a loaded sheet: {"texture", "region"}.
static func frame_region(sheet: Dictionary, index: int) -> Dictionary:
	if sheet.is_empty():
		return {}
	var fmt: Dictionary = sheet["fmt"]
	var c: int = cols(fmt)
	var row: int = clampi(floori(float(index) / float(c)), 0, dir_rows(fmt) - 1)
	var col: int = posmod(index, c)
	var pc: int = page_cols(fmt)
	var pages: Array = sheet.get("pages", [])
	var p: int = clampi(floori(float(col) / float(pc)), 0, maxi(0, pages.size() - 1))
	var fs: Vector2 = frame_size(fmt)
	return {"texture": pages[p] if pages.size() > 0 else null,
		"region": Rect2(Vector2(float(col - p * pc) * fs.x, float(row) * fs.y), fs)}

# ---------------- hands and ball points ----------------

# The hand points of a frame index in frame pixels: {"L": Vector2, "R": Vector2} (the player's own hands), plus
# "ball": Vector2, "ball_front": bool, "ball_h": float when the v2 data has a ball point. {} without data.
# flip = the mirrored directions (SW, W, NW): x' = width - 1 - x and L / R swap.
static func hand(fmt: Dictionary, sheet_id: String, frame: int, flip: bool = false) -> Dictionary:
	var e = null
	var c: int = cols(fmt)
	var row: int = floori(float(frame) / float(c))
	var col: int = posmod(frame, c)
	if int(fmt.get("version", 1)) == 2:
		e = _hand_v2(fmt, sheet_id, row, col)
	else:
		e = _hand_v1(sheet_id, row, col)
	if not (e is Dictionary):
		return {}
	var hd: Dictionary = (e as Dictionary).get("hands", e)
	if not hd.has("L") or not hd.has("R"):
		return {}
	var out := {"L": _v2(hd["L"]), "R": _v2(hd["R"])}
	var b = (e as Dictionary).get("ball", null)
	if b is Array and (b as Array).size() >= 2:
		out["ball"] = Vector2(float(b[0]), float(b[1]))
		out["ball_front"] = (b as Array).size() < 3 or int(b[2]) != 0
		out["ball_h"] = float((e as Dictionary).get("ball_h", 0.0))
	if flip:
		var w: float = frame_size(fmt).x - 1.0
		var l: Vector2 = out["L"]
		var r: Vector2 = out["R"]
		out["L"] = Vector2(w - r.x, r.y)
		out["R"] = Vector2(w - l.x, l.y)
		if out.has("ball"):
			out["ball"] = Vector2(w - (out["ball"] as Vector2).x, (out["ball"] as Vector2).y)
	return out

static func _v2(a) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO

static func _hand_v1(sheet_id: String, row: int, col: int):
	if _hands1 == null:
		_hands1 = {}
		var d = _read_json(v1_dir + HANDS_FILE)
		if d is Dictionary and (d as Dictionary).get("players", null) is Dictionary:
			_hands1 = d["players"]
	var rows = null
	for id in with_base(sheet_id):
		if (_hands1 as Dictionary).has(id):
			rows = _hands1[id]
			break
	if not (rows is Array) or row < 0 or row >= (rows as Array).size():
		return null
	var r = rows[row]
	if not (r is Array) or col < 0 or col >= (r as Array).size():
		return null
	return r[col]

static func _hand_v2(fmt: Dictionary, sheet_id: String, row: int, col: int):
	if _hands2 == null:
		_hands2 = {}
		var d = _read_json(v2_dir + HANDS_FILE)
		if d is Dictionary:
			_hands2 = d
	var bodies: Dictionary = (_hands2 as Dictionary).get("bodies", {})
	var sheets: Dictionary = (_hands2 as Dictionary).get("sheets", {})
	var body = null
	for id in with_base(sheet_id):
		if sheets.has(id) and bodies.has(str(sheets[id])):
			body = bodies[str(sheets[id])]
			break
		if bodies.has(id):
			body = bodies[id]
			break
	if not (body is Dictionary):
		return null
	var hit: Array = _anim_at(fmt, col)
	if hit.is_empty():
		return null
	var per_dir = (body as Dictionary).get(str(hit[0]), {})
	var dirs: Array = fmt.get("dirs", DIR_NAMES)
	if not (per_dir is Dictionary) or row < 0 or row >= dirs.size():
		return null
	var frames = (per_dir as Dictionary).get(str(dirs[row]), [])
	var k: int = int(hit[1])
	if not (frames is Array) or k >= (frames as Array).size():
		return null
	return frames[k]

# the animation and frame that a column belongs to: [anim, k], or [] for an unused column
static func _anim_at(fmt: Dictionary, col: int) -> Array:
	var key: String = "%d/%d/%s" % [int(fmt.get("version", 1)), cols(fmt), ",".join(PackedStringArray(fmt.get("extras", [])))]
	if not _ranges.has(key):
		var list: Array = []
		var anims: Dictionary = fmt.get("anims", {})
		for a in anims:
			var s: int = int((anims[a] as Dictionary).get("start", 0))
			list.append([s, s + maxi(1, int((anims[a] as Dictionary).get("frames", 1))), str(a)])
		_ranges[key] = list
	for r in _ranges[key]:
		if col >= int(r[0]) and col < int(r[1]):
			return [str(r[2]), col - int(r[0])]
	return []

# ---------------- cards (lineup, recruit, bracket) ----------------

# The card image of one sheet id: cards/<sheet>.png (v2), else the idle frame facing the camera cut from its v2 or
# v1 sheet. null when there is nothing.
static func card(sheet_id: String) -> Texture2D:
	var info: Dictionary = card_info(sheet_id)
	return info.get("texture", null)

# card() with what a screen needs to place it: {"id", "texture", "frame" (Vector2), "feet" (Vector2: the floor
# point in the image), "head_px", "version"}. {} when there is nothing. Cached.
static func card_info(sheet_id: String) -> Dictionary:
	if sheet_id == "":
		return {}
	if _cards.has(sheet_id):
		return _cards[sheet_id]
	var out := {}
	var fmt: Dictionary = v2_format()
	var img: Texture2D = _texture(v2_dir + CARD_SUBDIR + sheet_id + ".png") if not fmt.is_empty() else null
	if img != null:
		var sz: Vector2 = img.get_size()
		var fit: bool = sz == frame_size(fmt)
		out = {"id": sheet_id, "texture": img, "frame": sz, "version": 2,
			"feet": Vector2(center_x(fmt), feet_y(fmt)) if fit else Vector2(sz.x / 2.0, sz.y - 1.0),
			"head_px": head_px(fmt) if fit else sz.y * 0.85}
	else:
		var s: Dictionary = load_sheet(sheet_id)
		if not s.is_empty() and str(s.get("id", sheet_id)) != sheet_id:
			out = card_info(str(s["id"]))   # P8-10: a missing jersey: the card of the look drawn instead
		elif not s.is_empty():
			var f: Dictionary = s["fmt"]
			var reg: Dictionary = frame_region(s, frame_index(f, 0, "idle", 0))
			var tex: Texture2D = null
			if bool(s.get("indexed", false)):
				tex = _paint_indexed(reg["texture"], reg["region"], s["palette"])   # screens draw no shader
			else:
				var at := AtlasTexture.new()
				at.atlas = reg["texture"]
				at.region = reg["region"]
				tex = at
			if tex != null:
				out = {"id": sheet_id, "texture": tex, "frame": frame_size(f), "version": int(s["version"]),
					"feet": Vector2(center_x(f), feet_y(f)), "head_px": head_px(f)}
	_cards[sheet_id] = out
	return out

# v2.1: one frame of an index page painted in its palette, as an RGBA texture (the card of an indexed sheet without a
# card file). null if the images can't be read.
static func _paint_indexed(page: Texture2D, region: Rect2, palette: Texture2D) -> Texture2D:
	var src: Image = page.get_image() if page != null else null
	var pal: Image = palette.get_image() if palette != null else null
	if src == null or pal == null or src.is_compressed() or pal.is_compressed():
		return null
	var w: int = int(region.size.x)
	var h: int = int(region.size.y)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var ox: int = int(region.position.x)
	var oy: int = int(region.position.y)
	for y in h:
		for x in w:
			var idx: int = int(round(src.get_pixel(ox + x, oy + y).r * 255.0))
			if idx > 0:
				out.set_pixel(x, y, pal.get_pixel(mini(idx, pal.get_width() - 1), 0))
	return ImageTexture.create_from_image(out)

# the first of these ids with a card ({} if none), e.g. Sheets.card_first(Sheets.with_base(sheet) + ["ny_q2"])
static func card_first(ids: Array) -> Dictionary:
	for id in ids:
		var c: Dictionary = card_info(str(id))
		if not c.is_empty():
			return c
	return {}

# Where to draw a card so it stands where today's v1 card stood: v1_pos is the top-left of a 40 x 64 frame drawn at
# v1_scale (the screens' layout). A v1 card fills exactly that box; a v2 card keeps the same floor point and the
# same character height (so the layout doesn't move), and its taller frame reaches above the box.
static func card_rect(info: Dictionary, v1_pos: Vector2, v1_scale: float) -> Rect2:
	var v1: Dictionary = V1_FORMAT
	var floor_pt: Vector2 = v1_pos + Vector2(center_x(v1), feet_y(v1)) * v1_scale
	if info.is_empty():
		return Rect2(v1_pos, frame_size(v1) * v1_scale)
	var k: float = v1_scale * head_px(v1) / maxf(1.0, float(info.get("head_px", head_px(v1))))
	var feet: Vector2 = info.get("feet", Vector2(center_x(v1), feet_y(v1)))
	var fr: Vector2 = info.get("frame", frame_size(v1))
	return Rect2(floor_pt - feet * k, fr * k)

# ---------------- files ----------------

# a texture: an imported resource, else (a test folder in user://) the PNG read directly. null when missing.
static func _texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if (path.begins_with("user://") or path.begins_with("/")) and FileAccess.file_exists(path):
		var img: Image = Image.load_from_file(path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

static func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d

# forget everything loaded (tests; after the art changes on disk)
static func clear_cache() -> void:
	_fmt2 = null
	_hands1 = null
	_hands2 = null
	_sheets = {}
	_cards = {}
	_ranges = {}
	_recolors = null
	_materials = {}
	_xfmts = {}
	_warned_extra = {}

# ---------------- test ----------------

const TEST_DIR := "user://sheets_test/"
const SAMPLE_POINTS := "res://docs/art/anim_sample_v1_points.json"   # the approved sample's hand and ball points
const V1_TEST_SUBDIR := "v1/"         # self_test's v1 fixture folder (inside TEST_DIR)
const V1_TEST_ID := "test_v1"
const SAMPLE_ANIM_NAMES := {"run": "run", "rundribble": "run_dribble", "dribble": "dribble", "dunk": "dunk_two"}

# Checks the v1 numbers against player.gd, then builds a v1 fixture sheet (with its hands.json) and a 2-page v2 sheet
# (with the sample's points) in user://sheets_test/ and checks frames, pages, aliases, hands, mirroring, cards and the
# fallback chain. Needs no shipped sheet of either format.
static func self_test() -> bool:
	var ok := true
	_check_dir()
	var real_v2: String = v2_dir
	var real_v1: String = v1_dir
	v2_dir = TEST_DIR + "no_v2/"   # the v1 checks see only the v1 fixture
	v1_dir = TEST_DIR + V1_TEST_SUBDIR
	_v1_fixture()
	clear_cache()
	# v1: today's numbers
	var pl: GDScript = load("res://scripts/player.gd") as GDScript
	var consts: Dictionary = pl.get_script_constant_map() if pl != null else {}
	var anims1: Dictionary = consts.get("ANIMS", {})
	var same := anims1.size() == (V1_FORMAT["anims"] as Dictionary).size()
	for a in anims1:
		var v: Dictionary = (V1_FORMAT["anims"] as Dictionary).get(a, {})
		same = same and int(v.get("start", -1)) == int(anims1[a][0]) and int(v.get("frames", -1)) == int(anims1[a][1])
	ok = _t(same and consts.get("SHEET_FRAME", Vector2.ZERO) == frame_size(V1_FORMAT)
			and int(consts.get("SHEET_COLS", 0)) == cols(V1_FORMAT)
			and float(consts.get("SHEET_FEET_Y", 0.0)) == feet_y(V1_FORMAT), "v1 table = player.gd's") and ok
	var s1: Dictionary = load_sheet(V1_TEST_ID)
	ok = _t(int(s1.get("version", 0)) == 1 and (s1.get("texture", null) as Texture2D) != null, "v1 fixture loads") and ok
	var f1: Dictionary = V1_FORMAT
	ok = _t(frame_index(f1, 1, "run", 3) == 1 * 37 + 2 + 3 and frame_index(f1, 0, "run", 8) == 2 + 2
			and frame_index(f1, 2, "shoot", 9) == 2 * 37 + 12 + 3, "v1 frame_index (loop wraps, one-shot clamps)") and ok
	ok = _t(resolve(f1, "run_dribble") == "dribble" and resolve(f1, "slide") == "run"
			and resolve(f1, "dunk_windmill") == "dunk" and resolve(f1, "pass_lob") == "pass"
			and resolve(f1, "fall") == "stumble" and resolve(f1, "land") == "idle" and resolve(f1, "steal") == "poke"
			and resolve(f1, "celebrate_b") == "celebrate" and resolve(f1, "nonsense") == "idle", "v1 aliases") and ok
	ok = _t(anim_frames(f1, "dunk_two") == 5 and anim_fps(f1, "run_dribble") == 7.0, "v1 frames / fps via alias") and ok
	var r1: Dictionary = frame_region(s1, frame_index(f1, 2, "dribble", 1))
	ok = _t(r1.get("region", Rect2()) == Rect2(9 * 40, 2 * 64, 40, 64), "v1 frame_region") and ok
	var raw = _read_json(v1_dir + HANDS_FILE)
	var want = raw["players"][V1_TEST_ID][1][9] if raw is Dictionary else null
	var h1: Dictionary = hand(f1, V1_TEST_ID, frame_index(f1, 1, "dribble", 1))
	ok = _t(want is Dictionary and h1.get("R", Vector2(-1, -1)) == _v2(want["R"])
			and h1.get("R", Vector2.ZERO) == _v1_fixture_hand(1, 9, "R"), "v1 hand = hands.json") and ok
	var h1f: Dictionary = hand(f1, V1_TEST_ID, frame_index(f1, 1, "dribble", 1), true)
	var wr: Vector2 = _v2(want["R"]) if want is Dictionary else Vector2(-99, -99)
	ok = _t(h1f.get("L", Vector2.ZERO) == Vector2(39.0 - wr.x, wr.y), "v1 hand mirrored") and ok
	var hc: Dictionary = hand(f1, V1_TEST_ID + CREW_SUFFIX, frame_index(f1, 0, "idle", 0))
	ok = _t(not hc.is_empty(), "v1 hand of a _crew recolor (its base sheet's)") and ok
	var c1: Dictionary = card_info(V1_TEST_ID)
	ok = _t((c1.get("texture", null) is AtlasTexture) and (c1["texture"] as AtlasTexture).region == Rect2(0, 0, 40, 64)
			and card_rect(c1, Vector2(10, 20), 2.0) == Rect2(10, 20, 80, 128), "v1 card = column 0 row 0, today's box") and ok
	ok = _t(load_sheet("no_such_player").is_empty() and card("no_such_player") == null
			and str(load_first(["no_such_crew", "no_such", V1_TEST_ID]).get("id", "")) == V1_TEST_ID
			and str(card_first(with_base(V1_TEST_ID + CREW_SUFFIX)).get("id", "")) == V1_TEST_ID + CREW_SUFFIX
			and str(card_first(with_base("no_such_crew") + [V1_TEST_ID]).get("id", "")) == V1_TEST_ID, "fallback chain") and ok
	# v2: a built test sheet
	ok = _v2_test() and ok
	ok = _indexed_test() and ok
	ok = _extra_test() and ok
	_remove_files(TEST_DIR + V1_TEST_SUBDIR)
	v2_dir = real_v2
	v1_dir = real_v1
	clear_cache()
	print("SHEETS %s" % ("OK" if ok else "FAILED"))
	return ok

# the id of the sheet load_sheet() gives for an id ("" for none)
static func _sid(sheet_id: String) -> String:
	return str(load_sheet(sheet_id).get("id", ""))

static func _t(good: bool, what: String) -> bool:
	print("SHEETS check %-60s %s" % [what, "ok" if good else "WRONG"])
	return good

static func _v2_test() -> bool:
	var ok := true
	DirAccess.make_dir_recursive_absolute(TEST_DIR + CARD_SUBDIR)
	v2_dir = TEST_DIR
	# 100 columns: pages of 32 columns (2048 px): 0-31, 32-63, 64-95, 96-99; run_dribble starts on page 2
	var fmt := {"version": 2, "frame": [64, 96], "feet_row": 88, "center_x": 32, "head_px": 50, "draw_scale": 2.0,
		"dirs": DIR_NAMES, "cols": 100, "page_cols": 32,
		"anims": {"idle": {"start": 0, "frames": 6, "fps": 6, "loop": true},
			"run": {"start": 6, "frames": 12, "fps": 20, "loop": true},
			"dribble": {"start": 18, "frames": 8, "fps": 13.3, "loop": true},
			"dunk_two": {"start": 26, "frames": 10, "fps": 0, "loop": false},
			"run_dribble": {"start": 66, "frames": 10, "fps": 16.7, "loop": true}}}
	_write_text(TEST_DIR + FORMAT_FILE, JSON.stringify(fmt))
	var pts = _read_json(SAMPLE_POINTS)
	var body := {}
	if pts is Dictionary:
		for a in (pts as Dictionary).get("anims", {}):
			body[str(SAMPLE_ANIM_NAMES.get(a, a))] = pts["anims"][a]
	_write_text(TEST_DIR + HANDS_FILE, JSON.stringify({"frame": [64, 96], "feet_row": 88,
			"bodies": {"lanky": body}, "sheets": {"test_v2": "lanky", "test_v2_crew": "lanky"}}))
	var widths := [32, 32, 32, 4]
	var last: Image = null
	for pi in widths.size():
		var img := Image.create(int(widths[pi]) * 64, 96 * 5, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 0, 0, 1) if pi % 2 == 0 else Color(0, 0, 1, 1))
		img.save_png(TEST_DIR + "test_v2" + PAGE_SUFFIX + str(pi) + ".png")
		last = img
	last.save_png(TEST_DIR + "bad_v2" + PAGE_SUFFIX + "0.png")   # wrong size: not a usable sheet
	clear_cache()
	var s: Dictionary = load_sheet("test_v2")
	var f: Dictionary = s.get("fmt", {})
	ok = _t(int(s.get("version", 0)) == 2 and (s.get("pages", []) as Array).size() == 4, "v2 loads in 4 pages") and ok
	ok = _t(load_sheet("bad_v2").is_empty(), "v2 page of the wrong size is refused") and ok
	if f.is_empty():
		return false
	var i_rd: int = frame_index(f, 1, "run_dribble", 4)
	var reg: Dictionary = frame_region(s, i_rd)
	ok = _t(i_rd == 100 + 66 + 4 and reg.get("texture", null) == s["pages"][2]
			and reg.get("region", Rect2()) == Rect2((70 - 64) * 64, 96, 64, 96), "v2 frame on page 2") and ok
	var reg0: Dictionary = frame_region(s, frame_index(f, 2, "run", 11))
	ok = _t(reg0.get("texture", null) == s["pages"][0] and reg0.get("region", Rect2()) == Rect2(17 * 64, 2 * 96, 64, 96),
			"v2 frame on page 0") and ok
	ok = _t(resolve(f, "dunk") == "dunk_two" and resolve(f, "dunk_windmill") == "dunk_two"
			and resolve(f, "rundribble") == "run_dribble" and resolve(f, "cross") == "dribble"
			and anim_frames(f, "dunk_tomahawk") == 10 and anim_fps(f, "run") == 20.0, "v2 anims and aliases") and ok
	var h: Dictionary = hand(f, "test_v2", i_rd)
	ok = _t(h.get("R", Vector2.ZERO) == Vector2(29, 74) and h.get("ball", Vector2.ZERO) == Vector2(31.0, 88.9)
			and bool(h.get("ball_front", false)) and float(h.get("ball_h", -1.0)) == 0.0,
			"v2 hand + ball (sample run_dribble SE frame 4)") and ok
	var hf: Dictionary = hand(f, "test_v2_crew", i_rd, true)
	ok = _t(hf.get("L", Vector2.ZERO) == Vector2(63 - 29, 74) and hf.get("ball", Vector2.ZERO) == Vector2(63 - 31.0, 88.9),
			"v2 hand mirrored, recolor shares the body") and ok
	ok = _t(hand(f, "test_v2", frame_index(f, 1, "dunk_two", 8)).get("ball", null) == null
			and not hand(f, "test_v2", frame_index(f, 1, "dunk_two", 8)).is_empty(), "v2 dunk frame 8: hands, no ball") and ok
	ok = _t(hand(f, "test_v2", frame_index(f, 0, "run", 0)).is_empty(), "v2 no points for S in the sample = {}") and ok
	var c: Dictionary = card_info("test_v2")
	var cr: Rect2 = card_rect(c, Vector2(10, 20), 2.0)
	ok = _t(int(c.get("version", 0)) == 2 and (c["texture"] as AtlasTexture).region == Rect2(0, 0, 64, 96)
			and is_equal_approx(cr.size.y, 96.0 * 1.6) and (cr.position + Vector2(32, 88) * 1.6).is_equal_approx(
			Vector2(10, 20) + Vector2(20, 59) * 2.0), "v2 card from the sheet, same floor point and height") and ok
	var cimg := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	cimg.save_png(TEST_DIR + CARD_SUBDIR + "test_v2.png")
	clear_cache()
	var c2: Dictionary = card_info("test_v2")
	ok = _t(c2.get("texture", null) is ImageTexture and c2.get("feet", Vector2.ZERO) == Vector2(32, 88),
			"v2 card image file wins") and ok
	ok = _t(str(load_first(with_base("no_such_crew") + [V1_TEST_ID]).get("id", "")) == V1_TEST_ID
			and int(load_sheet(V1_TEST_ID).get("version", 0)) == 1 and int(load_sheet("test_v2").get("version", 0)) == 2,
			"v1 and v2 side by side") and ok
	for fn in DirAccess.get_files_at(TEST_DIR + CARD_SUBDIR):
		DirAccess.remove_absolute(TEST_DIR + CARD_SUBDIR + fn)
	for fn in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR + fn)
	return ok

# v2.1: an indexed one-page sheet with its palette and a recolor palette that draws the same pages
static func _indexed_test() -> bool:
	var ok := true
	var dir: String = TEST_DIR + "idx/"
	DirAccess.make_dir_recursive_absolute(dir + PALETTE_SUBDIR)
	v2_dir = dir
	var fmt := {"version": 2, "indexed": true, "frame": [64, 96], "feet_row": 88, "center_x": 32, "head_px": 50,
		"draw_scale": 2.0, "dirs": DIR_NAMES, "cols": 8, "page_cols": 32,
		"anims": {"idle": {"start": 0, "frames": 6, "fps": 6, "loop": true, "ms": [100, 200, 100, 100, 100, 100]},
			"dribble": {"start": 6, "frames": 2, "fps": 10, "loop": true, "floor": 1}}}
	_write_text(dir + FORMAT_FILE, JSON.stringify(fmt))
	var page := Image.create(8 * 64, 5 * 96, false, Image.FORMAT_L8)
	page.set_pixel(32, 50, Color8(5, 5, 5))
	page.save_png(dir + "test_ix_p0.png")
	var rgba := Image.create(8 * 64, 5 * 96, false, Image.FORMAT_RGBA8)
	rgba.fill(Color(0.8, 0.2, 0.1, 1.0))
	rgba.save_png(dir + "test_rgba_p0.png")   # flagged indexed but a color page: refused
	var gray := Image.create(8 * 64, 5 * 96, false, Image.FORMAT_RGB8)
	gray.set_pixel(32, 50, Color8(5, 5, 5))
	gray.save_png(dir + "test_gray_p0.png")   # an index page stored as RGB (Godot's WebP import): drawn, with a warning
	var pal_colors := {"test_ix_crew": Color(0, 0, 1, 1), "test_ix_j1": Color(0, 1, 0, 1), "test_ix_crew_j2": Color(1, 1, 0, 1)}
	for pal_id in ["test_ix", "test_ix_crew", "test_rgba", "test_gray", "test_ix_j1", "test_ix_crew_j2"]:
		var pal := Image.create(PALETTE_SIZE, 1, false, Image.FORMAT_RGBA8)
		pal.set_pixel(5, 0, pal_colors.get(pal_id, Color(1, 0, 0, 1)))
		pal.save_png(dir + PALETTE_SUBDIR + pal_id + ".png")
	clear_cache()
	var s: Dictionary = load_sheet("test_ix")
	var sc: Dictionary = load_sheet("test_ix_crew")
	ok = _t(bool(s.get("indexed", false)) and s.get("palette", null) is Texture2D and (s.get("pages", []) as Array).size() == 1,
			"v2.1 indexed sheet + palette") and ok
	ok = _t(str(sc.get("pages_id", "")) == "test_ix" and bool(sc.get("indexed", false)), "v2.1 recolor = a palette on the base pages") and ok
	var m: ShaderMaterial = material(s)
	ok = _t(m != null and m == material(s) and material(sc) != m and m.get_shader_parameter("palette") == s["palette"]
			and material(load_sheet(V1_TEST_ID)) == null, "v2.1 one material per palette, none for RGBA") and ok
	ok = _t(load_sheet("test_rgba").is_empty() and load_sheet("test_ix_nopal").is_empty(), "v2.1 color page or no palette is refused") and ok
	ok = _t(bool(load_sheet("test_gray").get("indexed", false)), "v2.1 index page stored as gray RGB still loads") and ok
	var c1: Texture2D = card("test_ix")
	var c2: Texture2D = card("test_ix_crew")
	var px1: Color = c1.get_image().get_pixel(32, 50) if c1 != null else Color.BLACK
	var px2: Color = c2.get_image().get_pixel(32, 50) if c2 != null else Color.BLACK
	var px0: Color = c1.get_image().get_pixel(10, 10) if c1 != null else Color.WHITE
	ok = _t(px1.is_equal_approx(Color(1, 0, 0, 1)) and px2.is_equal_approx(Color(0, 0, 1, 1)) and px0.a == 0.0,
			"v2.1 card painted in its palette (index 0 clear)") and ok
	# P8-10 jerseys: a jersey palette draws on the base pages; a missing one falls back to the look without it
	ok = _t(_sid("test_ix_j1") == "test_ix_j1" and str(load_sheet("test_ix_j1").get("pages_id", "")) == "test_ix"
			and _sid("test_ix_crew_j2") == "test_ix_crew_j2"
			and str(load_sheet("test_ix_crew_j2").get("pages_id", "")) == "test_ix", "v2.1 jersey palettes on the base pages") and ok
	ok = _t(_sid("test_ix_j3") == "test_ix" and _sid("test_ix_crew_j3") == "test_ix_crew"
			and _sid("test_ix_j1_crew") == "test_ix_j1" and _sid("test_ix_j3_crew") == "test_ix"
			and load_sheet("test_none_j1").is_empty(), "v2.1 a missing jersey falls back (crew, then base)") and ok
	ok = _t(with_base("a_crew_j2") == ["a_crew_j2", "a_crew", "a"] and with_base("ud_deuce_j1") == ["ud_deuce_j1", "ud_deuce"]
			and with_base("ud_jojo") == ["ud_jojo"] and with_base("a_j") == ["a_j"] and with_base("a_jx1") == ["a_jx1"]
			and with_base("a_crew") == ["a_crew", "a"] and not is_jersey("ud_jojo") and is_jersey("a_j1_crew"),
			"jersey ids in with_base()") and ok
	var cj: Texture2D = card("test_ix_j1")
	var cm: Texture2D = card("test_ix_crew_j3")
	ok = _t(cj != null and cj.get_image().get_pixel(32, 50).is_equal_approx(Color(0, 1, 0, 1)) and cm != null
			and cm.get_image().get_pixel(32, 50).is_equal_approx(Color(0, 0, 1, 1)), "v2.1 jersey cards (and the fallback's)") and ok
	var tt: PackedFloat32Array = anim_times(fmt, "idle")
	ok = _t(tt.size() == 6 and is_equal_approx(tt[1], 0.2) and is_equal_approx(anim_times(fmt, "dribble")[0], 0.1)
			and anim_event(fmt, "dribble", "floor") == 1 and anim_event(fmt, "idle", "floor", -7) == -7
			and resolve(fmt, "dribble_l") == "dribble" and resolve(fmt, "dunk_alley") == "idle", "v2 times, events, *_l aliases") and ok
	for fn in DirAccess.get_files_at(dir + PALETTE_SUBDIR):
		DirAccess.remove_absolute(dir + PALETTE_SUBDIR + fn)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + fn)
	return ok

# P9-04c: extra animations. An indexed format of 40 columns (pages of 32: p0, p1) with two extras: "hook" (extra
# columns 0..4) on test_ex (and so its recolors), "twirl" (columns 30..33, across x0 and x1) on test_ex2; test_plain
# lists none, test_nox and test_badx list the hook but have no x page / a wrong-sized one.
static func _extra_test() -> bool:
	var ok := true
	var dir: String = TEST_DIR + "ext/"
	DirAccess.make_dir_recursive_absolute(dir + PALETTE_SUBDIR)
	v2_dir = dir
	var fmt := {"version": 2, "indexed": true, "frame": [64, 96], "feet_row": 88, "center_x": 32, "head_px": 50,
		"draw_scale": 2.0, "dirs": DIR_NAMES, "cols": 40, "page_cols": 32,
		"anims": {"idle": {"start": 0, "frames": 6, "fps": 6, "loop": true},
			"shoot": {"start": 6, "frames": 10, "fps": 0, "loop": false, "release": 6}},
		"extra": {"hook": {"start": 0, "frames": 5, "fps": 0, "loop": false, "release": 3, "ms": [60, 60, 60, 80, 120],
				"sheets": ["test_ex", "test_nox", "test_badx"]},
			"twirl": {"start": 30, "frames": 4, "fps": 8, "loop": true, "sheets": ["test_ex2"]},
			"idle": {"start": 40, "frames": 2, "sheets": ["test_ex"]}}}   # named like a normal one: ignored
	_write_text(dir + FORMAT_FILE, JSON.stringify(fmt))
	var hook_pts: Array = []
	for k in 5:
		hook_pts.append({"hands": {"L": [20 + k, 40], "R": [40, 30 - k]}, "ball": [40, 26 - k, 1], "ball_h": 0})
	_write_text(dir + HANDS_FILE, JSON.stringify({"frame": [64, 96], "feet_row": 88,
			"bodies": {"tall": {"idle": {"E": [{"hands": {"L": [1, 2], "R": [3, 4]}}, {"hands": {"L": [1, 2], "R": [3, 4]}},
				{"hands": {"L": [5, 6], "R": [7, 8]}}, {"hands": {"L": [1, 2], "R": [3, 4]}},
				{"hands": {"L": [1, 2], "R": [3, 4]}}, {"hands": {"L": [1, 2], "R": [3, 4]}}]}, "hook": {"E": hook_pts}}},
			"sheets": {"test_ex": "tall", "test_ex2": "tall", "test_plain": "tall"}}))
	var page_w := {"p0": 32, "p1": 8}
	for id in ["test_ex", "test_ex2", "test_plain", "test_nox", "test_badx"]:
		for pg in page_w:
			var img := Image.create(int(page_w[pg]) * 64, 5 * 96, false, Image.FORMAT_L8)
			img.fill(Color8(3, 3, 3))
			img.save_png(dir + id + "_" + str(pg) + ".png")
		var pal := Image.create(PALETTE_SIZE, 1, false, Image.FORMAT_RGBA8)
		pal.set_pixel(3, 0, Color(1, 0, 0, 1))
		pal.set_pixel(7, 0, Color(0, 1, 0, 1))
		pal.save_png(dir + PALETTE_SUBDIR + id + ".png")
	var crew := Image.create(PALETTE_SIZE, 1, false, Image.FORMAT_RGBA8)
	crew.set_pixel(7, 0, Color(0, 0, 1, 1))
	crew.save_png(dir + PALETTE_SUBDIR + "test_ex_crew.png")
	crew.save_png(dir + PALETTE_SUBDIR + "test_ex_crew_j1.png")
	var xw := {"test_ex": [5], "test_ex2": [32, 2], "test_badx": [5]}
	for id in xw:
		for q in (xw[id] as Array).size():
			var h: int = 5 * 96 if id != "test_badx" else 96
			var xi := Image.create(int(xw[id][q]) * 64, h, false, Image.FORMAT_L8)
			xi.fill(Color8(7, 7, 7))
			xi.save_png(dir + id + EXTRA_PAGE_SUFFIX + str(q) + ".png")
	clear_cache()
	var base: Dictionary = v2_format()
	var ex: Dictionary = extra_anims(base)
	ok = _t(ex.size() == 2 and int(ex["hook"]["start"]) == 0 and int(ex["twirl"]["start"]) == 30
			and not (base["anims"] as Dictionary).has("hook") and extra_anims(fmt.duplicate().merged({"extra": 5}, true)).is_empty(),
			"extra: the format's extra section (a clash with a normal name ignored)") and ok
	var s: Dictionary = load_sheet("test_ex")
	var f: Dictionary = s.get("fmt", {})
	var plain: Dictionary = load_sheet("test_plain")
	ok = _t(is_same(plain.get("fmt", null), base) and not has_anim(plain, "hook") and resolve(base, "hook") == "shoot"
			and (plain.get("pages", []) as Array).size() == 2, "extra: an unlisted sheet keeps the shared format") and ok
	ok = _t(has_anim(s, "hook") and has_anim("test_ex", "hook") and not has_anim(s, "twirl") and not has_anim(base, "hook")
			and (s.get("pages", []) as Array).size() == 3 and cols(f) == 64 + 5 and int(f.get("base_cols", 0)) == 40
			and str(s.get("extras", [""])[0]) == "hook", "extra: a listed sheet carries it (3 pages, its own format)") and ok
	var i_h: int = frame_index(f, 2, "hook", 4)
	var reg: Dictionary = frame_region(s, i_h)
	ok = _t(i_h == 2 * 69 + 64 + 4 and reg.get("texture", null) == s["pages"][2]
			and reg.get("region", Rect2()) == Rect2(4 * 64, 2 * 96, 64, 96)
			and str(s["page_files"][2]).ends_with("test_ex_x0.png"), "extra: hook frame on the x0 page") and ok
	var reg_i: Dictionary = frame_region(s, frame_index(f, 2, "shoot", 3))
	var reg_b: Dictionary = frame_region(plain, frame_index(base, 2, "shoot", 3))
	ok = _t(reg_i.get("region", Rect2(1, 1, 1, 1)) == reg_b.get("region", Rect2()) and reg_i["texture"] == s["pages"][0],
			"extra: the normal frames of a listed sheet are where they were") and ok
	ok = _t(anim_frames(f, "hook") == 5 and anim_event(f, "hook", "release") == 3 and is_equal_approx(anim_times(f, "hook")[4], 0.12)
			and not anim_loops(f, "hook") and resolve(f, "hook") == "hook", "extra: frames, events and times") and ok
	var hh: Dictionary = hand(f, "test_ex", i_h)
	var hi: Dictionary = hand(f, "test_ex", frame_index(f, 2, "idle", 2))
	var hb: Dictionary = hand(base, "test_plain", frame_index(base, 2, "idle", 2))
	var hf: Dictionary = hand(f, "test_ex_crew", i_h, true)
	ok = _t(hh.get("R", Vector2.ZERO) == Vector2(40, 26) and hh.get("ball", Vector2.ZERO) == Vector2(40, 22)
			and hi.get("L", Vector2.ZERO) == Vector2(5, 6) and hb.get("L", Vector2.ZERO) == Vector2(5, 6)
			and hf.get("L", Vector2.ZERO) == Vector2(63 - 40, 26), "extra: hook hand and ball points (and the normal ones)") and ok
	var sc: Dictionary = load_sheet("test_ex_crew")
	var sj: Dictionary = load_sheet("test_ex_crew_j1")
	ok = _t(has_anim(sc, "hook") and is_same(sc.get("fmt", null), f) and sc["page_files"] == s["page_files"]
			and has_anim(sj, "hook") and str(sj.get("pages_id", "")) == "test_ex" and extras_for("test_ex_crew_j1") == ["hook"]
			and material(sc) != material(s), "extra: recolors and jerseys carry it (same pages, own palette)") and ok
	var s2: Dictionary = load_sheet("test_ex2")
	var f2: Dictionary = s2.get("fmt", {})
	var reg2: Dictionary = frame_region(s2, frame_index(f2, 1, "twirl", 3))
	ok = _t(has_anim(s2, "twirl") and not has_anim(s2, "hook") and (s2.get("pages", []) as Array).size() == 4
			and reg2.get("texture", null) == s2["pages"][3] and reg2.get("region", Rect2()) == Rect2(1 * 64, 96, 64, 96)
			and frame_index(f2, 0, "twirl", 6) == 64 + 30 + 2, "extra: across two x pages (x1), loops wrap") and ok
	var nx: Dictionary = load_sheet("test_nox")
	var bx: Dictionary = load_sheet("test_badx")
	ok = _t(not nx.is_empty() and not has_anim(nx, "hook") and is_same(nx.get("fmt", null), base)
			and frame_index(nx["fmt"], 0, "hook", 2) == 6 + 2 and not bx.is_empty() and not has_anim(bx, "hook")
			and extras_for("test_nox") == ["hook"], "extra: a missing or wrong x page falls back to the shot") and ok
	ok = _t(card("test_ex") != null and card("test_ex").get_image().get_pixel(10, 10).is_equal_approx(Color(1, 0, 0, 1)),
			"extra: the card is still the idle frame") and ok
	for fn in DirAccess.get_files_at(dir + PALETTE_SUBDIR):
		DirAccess.remove_absolute(dir + PALETTE_SUBDIR + fn)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + fn)
	return ok

# the v1 fixture: <V1_TEST_ID>.png and its _crew recolor (37 x 5 frames of 40 x 64) and a hands.json for the plain
# sheet only (a recolor uses its base sheet's points), in TEST_DIR + V1_TEST_SUBDIR
static func _v1_fixture() -> void:
	var dir: String = TEST_DIR + V1_TEST_SUBDIR
	DirAccess.make_dir_recursive_absolute(dir)
	var sz: Vector2 = frame_size(V1_FORMAT) * Vector2(cols(V1_FORMAT), dir_rows(V1_FORMAT))
	for id in [V1_TEST_ID, V1_TEST_ID + CREW_SUFFIX]:
		var img := Image.create(int(sz.x), int(sz.y), false, Image.FORMAT_RGBA8)
		img.fill(Color(0.2, 0.4, 1.0, 1.0) if id == V1_TEST_ID else Color(1.0, 0.8, 0.2, 1.0))
		img.save_png(dir + id + ".png")
	var rows: Array = []
	for r in dir_rows(V1_FORMAT):
		var row: Array = []
		for c in cols(V1_FORMAT):
			var hl: Vector2 = _v1_fixture_hand(r, c, "L")
			var hr: Vector2 = _v1_fixture_hand(r, c, "R")
			row.append({"L": [hl.x, hl.y], "R": [hr.x, hr.y]})
		rows.append(row)
	_write_text(dir + HANDS_FILE, JSON.stringify({"players": {V1_TEST_ID: rows}}))

# the fixture's hand point of a row and column: different on every frame, inside the 40 x 64 frame
static func _v1_fixture_hand(row: int, col: int, side: String) -> Vector2:
	return Vector2(float(8 + col % 10 + (12 if side == "R" else 0)), float(20 + row * 4 + col % 7))

static func _remove_files(dir: String) -> void:
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + fn)

static func _write_text(path: String, text: String) -> void:
	var fw: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if fw != null:
		fw.store_string(text)
		fw.close()
