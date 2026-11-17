extends RefCounted
# Player sprite sheets (P6-05, board "Player sheet format v2"): one place that knows the sheet layouts, so nothing
# else hardcodes 40 x 64 frames or 37 columns. Static only, no game state; use it through
#   const Sheets = preload("res://scripts/sheets.gd")
#
# Two formats:
#   v1 (built in, today's Phase 4/5 sheets): assets/players/<sheet>.png, 37 columns x 5 rows of 40 x 64 frames, the
#      floor on row 59; hands in assets/players/hands.json ("players".<sheet>[row][column] = {L, R}).
#   v2 (owner-approved animation sample v1, docs/art/anim_sample_v1.md): assets/players2/format.json is the truth.
#      64 x 96 frames, art scale 1.25, drawn 2x in the game; the floor point under the pelvis is on row 88, x 32.
#      Each direction is one row of `cols` logical columns (animation "start" + frame). The columns are stored in
#      pages of at most `page_cols` (64) columns, so no texture is wider than 4096 px:
#        cols <= page_cols:  assets/players2/<sheet>.png              (one page; <sheet>_p0.png also accepted)
#        cols >  page_cols:  assets/players2/<sheet>_p0.png, _p1.png ...  (page p holds columns p*page_cols ...)
#      Every page is len(dirs) rows high (5 x 96 = 480 px); the last page may be narrower (or padded).
#      format.json: {"version": 2, "frame": [64, 96], "feet_row": 88, "center_x": 32, "head_px": 50,
#                    "draw_scale": 2.0, "dirs": ["S", "SE", "E", "NE", "N"], "cols": N, "page_cols": 64,
#                    "anims": {"idle": {"start": 0, "frames": 6, "fps": 6, "loop": true}, ...}}
#      hands.json (the sample's points file, keyed by animation and direction, so it doesn't depend on the columns):
#                   {"frame": [64, 96], "feet_row": 88,
#                    "bodies": {"<body>": {"<anim>": {"<DIR>": [{"hands": {"L": [x, y], "R": [x, y]},
#                               "ball": [x, y, front] or null, "ball_floor": [x, y], "ball_h": h}, ...per frame]}}},
#                    "sheets": {"<sheet>": "<body>"}}       # recolors share their body's points
#      cards/<sheet>.png: the idle frame facing the camera (one 64 x 96 frame) for the lineup / recruit / bracket.
# Fallback chain: a v2 sheet, then a v1 sheet, of each id the caller lists (load_first / card_first: e.g. the _crew
# recolor, then his own sheet, then today's blue_n / red_n); nothing at all = {} / null (the caller draws the Kenney
# sprite or a silhouette). v1 and v2 players can share a court.
# Directions: rows 0..4 = S, SE, E, NE, N; SW, W and NW are SE, E and NE mirrored (x' = width - 1 - x, L and R swap).
# Animation names are the board's "Animation table". A sheet without one gets the nearest it has (ALIASES), e.g. on a
# v1 sheet run_dribble -> dribble, slide -> run, dunk_* -> dunk, pass_* -> pass, fall -> stumble, land -> idle.
# Test: Sheets.self_test() (prints SHEETS lines, ends with SHEETS OK / FAILED); it builds a v2 sheet in user://.

const V1_DIR := "res://assets/players/"
const V2_DIR := "res://assets/players2/"
const FORMAT_FILE := "format.json"
const HANDS_FILE := "hands.json"
const CARD_SUBDIR := "cards/"
const CREW_SUFFIX := "_crew"          # a city player's recolor in your colors (cities.gd crew_sheet)
const PAGE_SUFFIX := "_p"             # v2 page files: <sheet>_p0.png, <sheet>_p1.png ...
const MAX_TEXTURE := 4096             # px: no page may be wider or taller (Android GL Compatibility)
const DIR_NAMES := ["S", "SE", "E", "NE", "N"]

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
}

static var v2_dir := V2_DIR           # tests point this at a scratch folder (then clear_cache())
static var _fmt2 = null               # format.json (Dictionary), {} when missing or invalid; null = not read yet
static var _hands1 = null             # v1 hands.json "players"; {} when missing
static var _hands2 = null             # v2 hands.json; {} when missing
static var _sheets := {}              # sheet id -> load_sheet() result ({} = no sheet of either format)
static var _cards := {}               # sheet id -> card_info() result
static var _ranges := {}              # fmt version -> [[start, end, anim], ...] (hand() lookups)

# ---------------- formats ----------------

# the v2 format from format.json ({} when there is none or it is not a usable v2 format)
static func v2_format() -> Dictionary:
	if _fmt2 == null:
		_fmt2 = {}
		var d = _read_json(v2_dir + FORMAT_FILE)
		if d is Dictionary and _valid_format(d):
			_fmt2 = d
		elif d != null:
			push_warning("Sheets: %s%s is not a usable v2 format" % [v2_dir, FORMAT_FILE])
	return _fmt2

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

static func has_anim(fmt: Dictionary, anim: String) -> bool:
	return (fmt.get("anims", {}) as Dictionary).has(anim)

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
	_sheets[sheet_id] = out
	return out

# The first of these ids that has a sheet (each tried v2 then v1), e.g. [<sheet>_crew, <sheet>, "red_1"]. {} if none.
static func load_first(ids: Array) -> Dictionary:
	for id in ids:
		var s: Dictionary = load_sheet(str(id))
		if not s.is_empty():
			return s
	return {}

# [id] plus, for a _crew recolor, the plain sheet after it (the order the screens fall back in)
static func with_base(sheet_id: String) -> Array:
	var out: Array = [sheet_id]
	if sheet_id.ends_with(CREW_SUFFIX):
		out.append(sheet_id.substr(0, sheet_id.length() - CREW_SUFFIX.length()))
	return out

static func _load_v2(sheet_id: String) -> Dictionary:
	var fmt: Dictionary = v2_format()
	if fmt.is_empty():
		return {}
	var n: int = page_count(fmt)
	var fs: Vector2 = frame_size(fmt)
	var h: int = int(fs.y) * dir_rows(fmt)
	var pages: Array = []
	for p in n:
		var tries: Array = [v2_dir + sheet_id + PAGE_SUFFIX + str(p) + ".png"]
		if n == 1:
			tries.push_front(v2_dir + sheet_id + ".png")
		var tex: Texture2D = null
		for path in tries:
			tex = _texture(str(path))
			if tex != null:
				break
		if tex == null:
			return {}
		var want_w: int = mini(page_cols(fmt), cols(fmt) - p * page_cols(fmt)) * int(fs.x)
		var sz: Vector2 = tex.get_size()
		if int(sz.y) != h or int(sz.x) < want_w or sz.x > MAX_TEXTURE or sz.y > MAX_TEXTURE:
			push_warning("Sheets: %s page %d is %dx%d, want %dx%d" % [sheet_id, p, int(sz.x), int(sz.y), want_w, h])
			return {}
		pages.append(tex)
	return {"id": sheet_id, "version": 2, "fmt": fmt, "texture": pages[0], "pages": pages}

static func _load_v1(sheet_id: String) -> Dictionary:
	var tex: Texture2D = _texture(V1_DIR + sheet_id + ".png")
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
		var d = _read_json(V1_DIR + HANDS_FILE)
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
	var key: String = "%d/%d" % [int(fmt.get("version", 1)), cols(fmt)]
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
		if not s.is_empty():
			var f: Dictionary = s["fmt"]
			var reg: Dictionary = frame_region(s, frame_index(f, 0, "idle", 0))
			var at := AtlasTexture.new()
			at.atlas = reg["texture"]
			at.region = reg["region"]
			out = {"id": sheet_id, "texture": at, "frame": frame_size(f), "version": int(s["version"]),
				"feet": Vector2(center_x(f), feet_y(f)), "head_px": head_px(f)}
	_cards[sheet_id] = out
	return out

# the first of these ids with a card ({} if none), e.g. Sheets.card_first(Sheets.with_base(sheet) + ["red_1"])
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
	if path.begins_with("user://") and FileAccess.file_exists(path):
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

# ---------------- test ----------------

const TEST_DIR := "user://sheets_test/"
const SAMPLE_POINTS := "res://docs/art/anim_sample_v1_points.json"   # the approved sample's hand and ball points
const SAMPLE_ANIM_NAMES := {"run": "run", "rundribble": "run_dribble", "dribble": "dribble", "dunk": "dunk_two"}

# Checks the v1 numbers against player.gd and hands.json, then builds a 2-page v2 sheet (with the sample's points)
# in user://sheets_test/ and checks frames, pages, aliases, hands, mirroring, cards and the fallback chain.
static func self_test() -> bool:
	var ok := true
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
	var s1: Dictionary = load_sheet("ud_deuce")
	ok = _t(int(s1.get("version", 0)) == 1 and (s1.get("texture", null) as Texture2D) != null, "ud_deuce loads as v1") and ok
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
	var raw = _read_json(V1_DIR + HANDS_FILE)
	var want = raw["players"]["ud_deuce"][1][9] if raw is Dictionary else null
	var h1: Dictionary = hand(f1, "ud_deuce", frame_index(f1, 1, "dribble", 1))
	ok = _t(want is Dictionary and h1.get("R", Vector2(-1, -1)) == _v2(want["R"]), "v1 hand = hands.json") and ok
	var h1f: Dictionary = hand(f1, "ud_deuce", frame_index(f1, 1, "dribble", 1), true)
	var wr: Vector2 = _v2(want["R"]) if want is Dictionary else Vector2(-99, -99)
	ok = _t(h1f.get("L", Vector2.ZERO) == Vector2(39.0 - wr.x, wr.y), "v1 hand mirrored") and ok
	var hc: Dictionary = hand(f1, "ht_g1_crew", frame_index(f1, 0, "idle", 0))
	ok = _t(not hc.is_empty(), "v1 hand of a _crew recolor") and ok
	var c1: Dictionary = card_info("ud_deuce")
	ok = _t((c1.get("texture", null) is AtlasTexture) and (c1["texture"] as AtlasTexture).region == Rect2(0, 0, 40, 64)
			and card_rect(c1, Vector2(10, 20), 2.0) == Rect2(10, 20, 80, 128), "v1 card = column 0 row 0, today's box") and ok
	ok = _t(load_sheet("no_such_player").is_empty() and card("no_such_player") == null
			and str(load_first(["no_such_crew", "no_such", "red_1"]).get("id", "")) == "red_1"
			and str(card_first(with_base("ht_g1_crew")).get("id", "")) == "ht_g1_crew"
			and str(card_first(with_base("mem_g1_crew") + ["blue_1"]).get("id", "")) == "blue_1", "fallback chain") and ok
	# v2: a built test sheet
	ok = _v2_test() and ok
	v2_dir = V2_DIR
	clear_cache()
	print("SHEETS %s" % ("OK" if ok else "FAILED"))
	return ok

static func _t(good: bool, what: String) -> bool:
	print("SHEETS check %-60s %s" % [what, "ok" if good else "WRONG"])
	return good

static func _v2_test() -> bool:
	var ok := true
	DirAccess.make_dir_recursive_absolute(TEST_DIR + CARD_SUBDIR)
	v2_dir = TEST_DIR
	# 100 columns: page 0 = 64 columns (4096 px), page 1 = 36; run_dribble starts on page 1
	var fmt := {"version": 2, "frame": [64, 96], "feet_row": 88, "center_x": 32, "head_px": 50, "draw_scale": 2.0,
		"dirs": DIR_NAMES, "cols": 100, "page_cols": 64,
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
	var p0 := Image.create(64 * 64, 96 * 5, false, Image.FORMAT_RGBA8)
	var p1 := Image.create(36 * 64, 96 * 5, false, Image.FORMAT_RGBA8)
	p0.fill(Color(1, 0, 0, 1))
	p1.fill(Color(0, 0, 1, 1))
	p0.save_png(TEST_DIR + "test_v2" + PAGE_SUFFIX + "0.png")
	p1.save_png(TEST_DIR + "test_v2" + PAGE_SUFFIX + "1.png")
	p1.save_png(TEST_DIR + "bad_v2" + PAGE_SUFFIX + "0.png")   # wrong size: not a usable sheet
	clear_cache()
	var s: Dictionary = load_sheet("test_v2")
	var f: Dictionary = s.get("fmt", {})
	ok = _t(int(s.get("version", 0)) == 2 and (s.get("pages", []) as Array).size() == 2, "v2 loads in 2 pages") and ok
	ok = _t(load_sheet("bad_v2").is_empty(), "v2 page of the wrong size is refused") and ok
	if f.is_empty():
		return false
	var i_rd: int = frame_index(f, 1, "run_dribble", 4)
	var reg: Dictionary = frame_region(s, i_rd)
	ok = _t(i_rd == 100 + 66 + 4 and reg.get("texture", null) == s["pages"][1]
			and reg.get("region", Rect2()) == Rect2((70 - 64) * 64, 96, 64, 96), "v2 frame on page 1") and ok
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
	ok = _t(str(load_first(with_base("ud_deuce_crew")).get("id", "")) == "ud_deuce"
			and int(load_sheet("ud_deuce").get("version", 0)) == 1, "v1 and v2 side by side") and ok
	for fn in DirAccess.get_files_at(TEST_DIR + CARD_SUBDIR):
		DirAccess.remove_absolute(TEST_DIR + CARD_SUBDIR + fn)
	for fn in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR + fn)
	return ok

static func _write_text(path: String, text: String) -> void:
	var fw: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if fw != null:
		fw.store_string(text)
		fw.close()
