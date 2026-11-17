extends Node
# The --anim-test driver (Phase 6, P6-24). Test only: main.gd adds it to a game when run with -- --anim-test (and
# sets `main` and `game`); the game itself is stopped. It works on v1 sheets now and on v2 sheets once
# assets/players2/ exists (sheets.gd reads both, the board's "Player sheet format v2").
#
#   godot --headless --path . -- --anim-test                    checks every sheet, prints ANIM OK (exit 0) or the
#                                                               problems and ANIM FAILED (exit 1)
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 -- --anim-test
#                                                               the checks, then contact sheets (below)
# Flags (after --):
#   --anim-sheet id[,id...]   only these sheets (default: all v1 and v2 sheets)
#   --anim-out DIR            where the images go (default /tmp)
#   --anim-shots              write the images headless too (they are made on the CPU, no renderer needed)
#   --anim-fake-v2            also builds a small v2 sheet set in user://anim_test_v2/ (blocks for bodies, the approved
#                             sample's hand and ball points) and runs the v2 checks and images on it (test of the
#                             v2 path before the real v2 sheets exist)
#
# Checks, per sheet (v1: assets/players/<id>.png, v2: assets/players2/):
#   - the format: every animation inside the columns, no two overlapping, frame counts and fps sane, pages within
#     2048 px; every name in the board's animation table resolves (an alias is listed, not a problem);
#   - the file loads at the format's size (a wrong size is refused by sheets.gd: a problem);
#   - every frame of every animation in every direction has pixels (an empty frame is a problem);
#   - hand points: v1 hands.json has every frame; v2 hands.json maps the sheet to a body, each animation and
#     direction with points has exactly the format's frame count, every point is inside the frame, and the
#     ball-holding animations have a ball point on their first frame (directions without points are only counted);
#   - v2: a card in cards/ (missing = a note, the card is then cut from the sheet).
#   - v2.1 indexed sheets (format.json "indexed": true): the gray pages are painted through the sheet's palette
#     (Sheets.load_sheet()'s "palette", index 0 clear) before the checks and images, so an empty frame is one with only
#     index 0 (or indexes the palette leaves clear), and the images show the real colors. A recolor (a palette only,
#     drawn on its base sheet's pages) is checked and drawn too; pixels whose index the palette leaves clear are a note.
#   Also Sheets.self_test() (SHEETS lines).
# Images (CPU-made, the frames 2x on a plain court color like the game, the ball drawn in the hand):
#   <out>/hoops_anim_<sheet>_<anim>.png        every frame (columns) in 8 directions (rows E, SE, S, SW, W, NW, N, NE);
#                                              hand points marked (L red, R green), the floor point as a tick
#   <out>/hoops_anim_<sheet>_<anim>_strip.png  the frames facing SE in a row at 3x: a moving preview, frame by frame
#   <out>/hoops_anim_<sheet>.png               overview: one row per animation (SE), every frame
# The per-animation images are written for the sheets in --anim-sheet, else for ud_deuce and every v2 sheet; the
# overview for every sheet.

const Sheets = preload("res://scripts/sheets.gd")

const OUT_DIR := "/tmp"
const DEFAULT_DETAIL := ["ud_deuce"]   # per-animation images for these (plus every v2 sheet) without --anim-sheet
# the board's "Animation table" names (a sheet without one plays its alias)
const TABLE_ANIMS := ["idle", "run", "dribble", "run_dribble", "cross", "hold", "catch", "shoot", "layup",
	"dunk_one", "dunk_two", "dunk_tomahawk", "dunk_windmill", "rim_hang", "pass_chest", "pass_bounce", "pass_lob",
	"slide", "steal", "block", "stumble", "fall", "celebrate_a", "celebrate_b", "land"]
# where the ball is in each animation (resolved name): "dribble" (the dribbling hand), "up" (the higher hand, until
# BALL_UNTIL of the animation), "both" (between the hands, until BALL_UNTIL). Others: no ball. v2 sheets use their own
# ball points instead.
const BALL_RULE := {
	"dribble": "dribble", "run_dribble": "dribble", "rundribble": "dribble", "cross": "dribble",
	"hold": "both", "catch": "both",
	"shoot": "up", "layup": "up", "dunk": "up", "dunk_one": "up", "dunk_two": "up", "dunk_tomahawk": "up",
	"dunk_windmill": "up",
	"pass": "both", "pass_chest": "both", "pass_bounce": "both", "pass_lob": "up",
}
const BALL_UNTIL := {"shoot": 0.75, "layup": 0.5, "dunk": 0.55, "dunk_one": 0.55, "dunk_two": 0.55,
	"dunk_tomahawk": 0.55, "dunk_windmill": 0.55, "pass": 0.5, "pass_chest": 0.5, "pass_bounce": 0.5, "pass_lob": 0.5}
# v2: these animations must have a ball point on frame 0 (where the points exist)
const V2_BALL_ANIMS := ["dribble", "run_dribble", "cross", "hold", "catch", "shoot", "layup", "dunk_one", "dunk_two",
	"dunk_tomahawk", "dunk_windmill", "pass_chest", "pass_bounce", "pass_lob"]
# 8 screen directions as player.gd draws them: [sheet row, mirrored, name]
const OCTANTS := [[2, false, "E"], [1, false, "SE"], [0, false, "S"], [1, true, "SW"], [2, true, "W"],
	[3, true, "NW"], [4, false, "N"], [3, false, "NE"]]
const SE_ROW := 1
const CELL_SCALE := 2             # frames drawn 2x (as in the game)
const STRIP_SCALE := 3
const PAD := 4                    # px between cells
const COURT_COLOR := Color(0.80, 0.58, 0.34)   # the gym floor's color
const BACK_COLOR := Color(0.16, 0.18, 0.24)    # between cells
const FLOOR_TICK := Color(1, 1, 1, 0.7)
const HAND_L := Color(1.0, 0.2, 0.2)
const HAND_R := Color(0.2, 1.0, 0.3)
const BALL_PATH := "res://assets/ball/ball.png"   # 4 spin frames of 16 x 16 (art px, the same size for v1 and v2)
const BALL_FRAME := 16
const BALL_R := 6.0               # art px: the ball's radius in a frame
const DRIBBLE_UNDER_HAND := 0.7   # as ball.gd: the ball's center this many radii under the hand at the top
const HELD_ON_HAND := 0.6         # as ball.gd: held up, the center this many radii above the hand
const FAKE_DIR := "user://anim_test_v2/"

var main
var game
var _problems: PackedStringArray = []
var _notes: PackedStringArray = []
var _images := {}                 # page texture -> Image (CPU copy)
var _painted := {}                # v2.1: "page:palette" instance ids -> the page painted in the palette (RGBA Image)
var _clear_ix := {}               # v2.1: sheet id -> pixels with an index > 0 that its palette leaves clear
var _ball_img: Image
var _out := OUT_DIR
var _write := false
var _written := 0

func _ready() -> void:
	if main != null:
		main.set_physics_process(false)   # the game stands still; only this runs
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = _arg("--anim-out", OUT_DIR).trim_suffix("/")
	_write = DisplayServer.get_name() != "headless" or args.has("--anim-shots")
	var only: Array = []
	var s: String = _arg("--anim-sheet", "")
	if s != "":
		for id in s.split(",", false):
			only.append(id.strip_edges())
	print("ANIM TEST: sheets.gd self test")
	if not Sheets.self_test():
		# reported, not counted: the self test checks sheets.gd's code against fixtures (e.g. that some sheet does not
		# exist yet), ANIM checks the sheets themselves
		_notes.append("sheets.gd self_test FAILED (see the SHEETS ... WRONG lines)")
	_load_ball()
	_check_set(only)
	if args.has("--anim-fake-v2"):
		print("ANIM TEST: fake v2 set in %s" % FAKE_DIR)
		_build_fake_v2()
		Sheets.v2_dir = FAKE_DIR
		Sheets.clear_cache()
		_images.clear()
		_painted.clear()
		_check_set(["fake_v2"])
		Sheets.v2_dir = Sheets.V2_DIR
		Sheets.clear_cache()
	for n in _notes:
		print("ANIM note: ", n)
	for p in _problems:
		print("ANIM PROBLEM: ", p)
	if _write:
		print("ANIM images: %d written to %s" % [_written, _out])
	print("ANIM OK" if _problems.is_empty() else "ANIM FAILED (%d problems)" % _problems.size())
	get_tree().quit(0 if _problems.is_empty() else 1)

func _arg(flag: String, default: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		if args[i].begins_with(flag + "="):
			return args[i].get_slice("=", 1)
		if args[i] == flag and i + 1 < args.size():
			return args[i + 1]
	return default

# ---------------- the sheets ----------------

func _check_set(only: Array) -> void:
	var v1_ids: Array = _list_v1()
	var v2_ids: Array = _list_v2()
	var fmt2: Dictionary = Sheets.v2_format()
	if not fmt2.is_empty():
		_check_format(fmt2, "v2 format.json")
	elif FileAccess.file_exists(Sheets.v2_dir + Sheets.FORMAT_FILE):
		_problems.append("%s%s is not a usable v2 format" % [Sheets.v2_dir, Sheets.FORMAT_FILE])
	if not only.is_empty():
		v1_ids = v1_ids.filter(func(id): return only.has(id))
		v2_ids = v2_ids.filter(func(id): return only.has(id))
		for id in only:
			if not v1_ids.has(id) and not v2_ids.has(id):
				_problems.append("%s: no v1 or v2 sheet" % id)
	print("ANIM TEST: %d v1 sheets, %d v2 sheets%s" % [v1_ids.size(), v2_ids.size(),
			"" if fmt2.is_empty() else " (v2: %d columns, %d pages)" % [Sheets.cols(fmt2), Sheets.page_count(fmt2)]])
	_check_format(Sheets.v1_format(), "v1 table")
	for id in v1_ids:
		var sh: Dictionary = Sheets._load_v1(id)
		if sh.is_empty():
			_problems.append("v1 %s: the png is not %s" % [id, str(Sheets.frame_size(Sheets.V1_FORMAT) * Vector2(37, 5))])
			continue
		_check_sheet(sh)
		_draw_sheet(sh, only.has(id) or (only.is_empty() and DEFAULT_DETAIL.has(id)))
	for id in v2_ids:
		var sh2: Dictionary = Sheets._load_v2(id)
		if sh2.is_empty():
			_problems.append("v2 %s: missing pages, a page of the wrong size%s" % [id,
					" or no usable palette (indexed)" if Sheets.indexed(Sheets.v2_format()) else ""])
			continue
		_check_sheet(sh2)
		if int(_clear_ix.get(id, 0)) > 0:
			_notes.append("v2 %s: %d pixels have an index the palette leaves clear" % [id, int(_clear_ix[id])])
		if not FileAccess.file_exists(Sheets.v2_dir + Sheets.CARD_SUBDIR + id + ".png") \
				and not ResourceLoader.exists(Sheets.v2_dir + Sheets.CARD_SUBDIR + id + ".png"):
			_notes.append("v2 %s: no card (cut from the sheet instead)" % id)
		_draw_sheet(sh2, only.is_empty() or only.has(id))

func _list_v1() -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(Sheets.V1_DIR):
		var fn: String = f.trim_suffix(".import")
		if fn.ends_with(".png") and not out.has(fn.get_basename()):
			out.append(fn.get_basename())
	out.sort()
	return out

func _list_v2() -> Array:
	var out: Array = []
	if not DirAccess.dir_exists_absolute(Sheets.v2_dir):
		return out
	for f in DirAccess.get_files_at(Sheets.v2_dir):
		var fn: String = f.trim_suffix(".import")
		if not fn.ends_with(".png"):
			continue
		var id: String = fn.get_basename()
		var at: int = id.rfind(Sheets.PAGE_SUFFIX)
		if at > 0 and id.substr(at + Sheets.PAGE_SUFFIX.length()).is_valid_int():
			id = id.substr(0, at)
		if not out.has(id):
			out.append(id)
	# v2.1: a recolor has only a palette (palettes/<id>.png) drawn on its base sheet's pages
	if Sheets.indexed(Sheets.v2_format()) and DirAccess.dir_exists_absolute(Sheets.v2_dir + Sheets.PALETTE_SUBDIR):
		for f in DirAccess.get_files_at(Sheets.v2_dir + Sheets.PALETTE_SUBDIR):
			var pn: String = f.trim_suffix(".import")
			if pn.ends_with(".png") and not out.has(pn.get_basename()):
				out.append(pn.get_basename())
	out.sort()
	return out

# the format's animation table: inside the columns, no overlaps, sane counts; the board's names resolve
func _check_format(fmt: Dictionary, what: String) -> void:
	var anims: Dictionary = fmt.get("anims", {})
	var c: int = Sheets.cols(fmt)
	var used := {}
	for a in anims:
		var e: Dictionary = anims[a]
		var st: int = int(e.get("start", -1))
		var n: int = int(e.get("frames", 0))
		if st < 0 or n <= 0 or st + n > c:
			_problems.append("%s: %s columns %d..%d outside 0..%d" % [what, a, st, st + n - 1, c - 1])
		if float(e.get("fps", 0.0)) < 0.0:
			_problems.append("%s: %s fps < 0" % [what, a])
		for k in range(maxi(st, 0), st + n):
			if used.has(k):
				_problems.append("%s: %s overlaps %s at column %d" % [what, a, used[k], k])
				break
			used[k] = a
	if not anims.has("idle"):
		_problems.append("%s: no idle animation" % what)
	var fs: Vector2 = Sheets.frame_size(fmt)
	if Sheets.page_cols(fmt) * int(fs.x) > Sheets.MAX_TEXTURE or Sheets.dir_rows(fmt) * int(fs.y) > Sheets.MAX_TEXTURE:
		_problems.append("%s: a page would be over %d px" % [what, Sheets.MAX_TEXTURE])
	var aliased: PackedStringArray = []
	for a in TABLE_ANIMS:
		var r: String = Sheets.resolve(fmt, a)
		if r == "":
			_problems.append("%s: %s resolves to nothing" % [what, a])
		elif r != a:
			aliased.append("%s->%s" % [a, r])
	print("ANIM %s: %d animations, %d columns; aliases: %s" % [what, anims.size(), c, ", ".join(aliased) if not aliased.is_empty() else "none"])

# one sheet: every frame has pixels, the hand (and ball) points
func _check_sheet(sh: Dictionary) -> void:
	var fmt: Dictionary = sh["fmt"]
	var id: String = sh["id"]
	var v: int = int(sh["version"])
	var tag: String = "v%d %s" % [v, id]
	if bool(sh.get("indexed", false)):
		tag += " (indexed, pages of %s)" % str(sh.get("pages_id", id))
	var fs: Vector2 = Sheets.frame_size(fmt)
	var empty := 0
	var no_hands := 0
	var outside := 0
	var frames := 0
	var anims: Dictionary = fmt.get("anims", {})
	for a in anims:
		var n: int = Sheets.anim_frames(fmt, a)
		for row in Sheets.dir_rows(fmt):
			for k in n:
				frames += 1
				var idx: int = Sheets.frame_index(fmt, row, a, k)
				var img: Image = _frame_image(sh, idx)
				if img == null or img.is_invisible():
					empty += 1
					if empty <= 3:
						_problems.append("%s: %s %s frame %d is empty" % [tag, a, Sheets.DIR_NAMES[row], k])
				var h: Dictionary = Sheets.hand(fmt, id, idx)
				if h.is_empty():
					no_hands += 1
					continue
				for key in ["L", "R", "ball"]:
					if h.has(key) and not Rect2(Vector2(-0.5, -0.5), fs + Vector2(1, 1)).has_point(h[key]):
						outside += 1
						if outside <= 3:
							_problems.append("%s: %s %s frame %d: %s point %s is outside the frame" % [tag, a,
									Sheets.DIR_NAMES[row], k, key, str(h[key])])
	if empty > 3:
		_problems.append("%s: %d empty frames in all" % [tag, empty])
	if outside > 3:
		_problems.append("%s: %d points outside the frame in all" % [tag, outside])
	if v == 1:
		if no_hands > 0:
			_problems.append("%s: %d of %d frames have no hands in hands.json" % [tag, no_hands, frames])
	else:
		_check_v2_points(sh)
	print("ANIM %s: %d frames, %d empty, %d without points" % [tag, frames, empty, no_hands])

# v2 hands.json: a body for the sheet; per animation and direction the format's frame count; ball points
func _check_v2_points(sh: Dictionary) -> void:
	var fmt: Dictionary = sh["fmt"]
	var id: String = sh["id"]
	var d = Sheets._read_json(Sheets.v2_dir + Sheets.HANDS_FILE)
	if not (d is Dictionary):
		_problems.append("v2 %s: no %s" % [id, Sheets.HANDS_FILE])
		return
	var bodies: Dictionary = (d as Dictionary).get("bodies", {})
	var sheets: Dictionary = (d as Dictionary).get("sheets", {})
	var body = null
	for sid in Sheets.with_base(id):
		if sheets.has(sid) and bodies.has(str(sheets[sid])):
			body = bodies[str(sheets[sid])]
			break
		if bodies.has(sid):
			body = bodies[sid]
			break
	if not (body is Dictionary):
		_problems.append("v2 %s: hands.json has no body for it" % id)
		return
	var anims: Dictionary = fmt.get("anims", {})
	var missing: PackedStringArray = []
	for a in anims:
		var per_dir = (body as Dictionary).get(a, null)
		if not (per_dir is Dictionary):
			missing.append(str(a))
			continue
		var n: int = Sheets.anim_frames(fmt, a)
		for dn in (per_dir as Dictionary):
			var list = per_dir[dn]
			if not (fmt.get("dirs", Sheets.DIR_NAMES) as Array).has(dn):
				_problems.append("v2 %s: %s has points for an unknown direction %s" % [id, a, dn])
			elif not (list is Array) or (list as Array).size() != n:
				_problems.append("v2 %s: %s %s has %d point frames, the format %d" % [id, a, dn,
						(list as Array).size() if list is Array else 0, n])
			elif V2_BALL_ANIMS.has(a) and (list as Array).size() > 0 and (list[0] as Dictionary).get("ball", null) == null:
				_problems.append("v2 %s: %s %s frame 0 has no ball point (the ball must be in the hand)" % [id, a, dn])
		var dirs_with: int = (per_dir as Dictionary).size()
		if dirs_with < Sheets.dir_rows(fmt):
			_notes.append("v2 %s: %s has points in %d of %d directions" % [id, a, dirs_with, Sheets.dir_rows(fmt)])
	if not missing.is_empty():
		_problems.append("v2 %s: no points for %s" % [id, ", ".join(missing)])

# ---------------- images ----------------

# the CPU copy of a page (the texture's image; headless, the png read directly)
func _page_image(tex: Texture2D) -> Image:
	if tex == null:
		return null
	if _images.has(tex):
		return _images[tex]
	var img: Image = tex.get_image()
	var path: String = tex.resource_path
	if (img == null or img.is_empty()) and path.ends_with(".png") and FileAccess.file_exists(path):
		img = Image.load_from_file(path)   # (headless: the dummy renderer keeps no pixels; prints a warning)
	if img != null and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
	_images[tex] = img
	return img

func _frame_image(sh: Dictionary, idx: int) -> Image:
	var reg: Dictionary = Sheets.frame_region(sh, idx)
	if reg.is_empty():
		return null
	var page: Image = null
	if bool(sh.get("indexed", false)):
		page = _painted_page(sh, reg["texture"])
	else:
		page = _page_image(reg["texture"])
	if page == null:
		return null
	var r: Rect2i = Rect2i(reg["region"])
	if r.end.x > page.get_width() or r.end.y > page.get_height():
		return null
	return page.get_region(r)

# v2.1: the CPU copy of an index page or a palette: the texture's own image, else (headless, or a scratch folder that
# Sheets._texture() read into an ImageTexture without a path) the png at its resource path or at fallback.
func _raw_image(tex: Texture2D, fallback: String) -> Image:
	if tex == null:
		return null
	if _images.has(tex):
		return _images[tex]
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		img = null
		for path in [tex.resource_path, fallback]:
			if str(path).ends_with(".png") and FileAccess.file_exists(str(path)):
				img = Image.load_from_file(str(path))
				break
	if img != null and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)   # gray (L8, or gray RGB) -> r = g = b = the index
	else:
		img = null
	_images[tex] = img
	return img

# v2.1: an index page painted in the sheet's palette (index 0 and clear palette entries transparent), cached per page
# and palette. Mapped byte by byte (a page is up to 2048 x 480).
func _painted_page(sh: Dictionary, page_tex: Texture2D) -> Image:
	var pal_tex: Texture2D = sh.get("palette", null)
	var id: String = str(sh["id"])
	var key: String = "%d:%d" % [page_tex.get_instance_id() if page_tex != null else 0,
			pal_tex.get_instance_id() if pal_tex != null else 0]
	if _painted.has(key):
		return _painted[key]
	var pages: Array = sh.get("pages", [])
	var p: int = maxi(0, pages.find(page_tex))
	var base: String = str(sh.get("pages_id", id))
	var page_file: String = Sheets.v2_dir + base + Sheets.PAGE_SUFFIX + str(p) + ".png"
	if pages.size() == 1 and not FileAccess.file_exists(page_file):
		page_file = Sheets.v2_dir + base + ".png"
	var src: Image = _raw_image(page_tex, page_file)
	var pal: Image = _raw_image(pal_tex, Sheets.v2_dir + Sheets.PALETTE_SUBDIR + id + ".png")
	if src == null or pal == null:
		_problems.append("v2 %s: page %d or its palette could not be read" % [id, p])
		_painted[key] = null
		return null
	var lut := PackedByteArray()
	lut.resize(Sheets.PALETTE_SIZE * 4)   # zeros: index 0 (and any index past the palette) clear
	var pd: PackedByteArray = pal.get_data()
	for i in range(1, mini(pal.get_width(), Sheets.PALETTE_SIZE)):
		for c in 4:
			lut[i * 4 + c] = pd[i * 4 + c]
	var sd: PackedByteArray = src.get_data()
	var n: int = src.get_width() * src.get_height()
	var out := PackedByteArray()
	out.resize(n * 4)
	var clear := 0
	for i in n:
		var o: int = sd[i * 4] * 4
		if o == 0:
			continue
		if lut[o + 3] == 0:
			clear += 1
			continue
		var j: int = i * 4
		out[j] = lut[o]
		out[j + 1] = lut[o + 1]
		out[j + 2] = lut[o + 2]
		out[j + 3] = lut[o + 3]
	_clear_ix[id] = int(_clear_ix.get(id, 0)) + clear
	var img: Image = Image.create_from_data(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8, out)
	_painted[key] = img
	return img

func _load_ball() -> void:
	var img: Image = null
	if ResourceLoader.exists(BALL_PATH):
		img = _page_image(load(BALL_PATH) as Texture2D)
	if img == null or img.is_empty():
		_ball_img = Image.create(BALL_FRAME, BALL_FRAME, false, Image.FORMAT_RGBA8)
		for y in BALL_FRAME:
			for x in BALL_FRAME:
				if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(8, 8)) <= BALL_R:
					_ball_img.set_pixel(x, y, Color(0.9, 0.45, 0.12))
		return
	img.convert(Image.FORMAT_RGBA8)
	_ball_img = img.get_region(Rect2i(0, 0, BALL_FRAME, BALL_FRAME))

# one frame on the court color, the ball in the hand (under or over the sprite), the marks; scaled by sc
func _cell(sh: Dictionary, anim: String, row: int, flip: bool, k: int, sc: int, marks: bool) -> Image:
	var fmt: Dictionary = sh["fmt"]
	var fs: Vector2i = Vector2i(Sheets.frame_size(fmt))
	var cell := Image.create(fs.x, fs.y, false, Image.FORMAT_RGBA8)
	cell.fill(COURT_COLOR)
	var idx: int = Sheets.frame_index(fmt, row, anim, k)
	var spr: Image = _frame_image(sh, idx)
	if spr != null and flip:
		spr.flip_x()
	var ball = _ball_point(sh, anim, idx, k, flip)   # [Vector2, front] or null
	if ball != null and not bool(ball[1]):
		_blend_ball(cell, ball[0])
	if spr != null:
		cell.blend_rect(spr, Rect2i(Vector2i.ZERO, fs), Vector2i.ZERO)
	if ball != null and bool(ball[1]):
		_blend_ball(cell, ball[0])
	if marks:
		var fx: int = int(Sheets.center_x(fmt))
		if flip:
			fx = fs.x - 1 - fx
		var fy: int = int(Sheets.feet_y(fmt))
		for dx in range(-3, 4):
			_px(cell, fx + dx, fy, FLOOR_TICK)
		var h: Dictionary = Sheets.hand(fmt, str(sh["id"]), idx, flip)
		if not h.is_empty():
			_px(cell, int(round((h["L"] as Vector2).x)), int(round((h["L"] as Vector2).y)), HAND_L)
			_px(cell, int(round((h["R"] as Vector2).x)), int(round((h["R"] as Vector2).y)), HAND_R)
	if sc != 1:
		cell.resize(fs.x * sc, fs.y * sc, Image.INTERPOLATE_NEAREST)
	return cell

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _blend_ball(cell: Image, c: Vector2) -> void:
	var at := Vector2i(int(round(c.x - BALL_FRAME / 2.0)), int(round(c.y - BALL_FRAME / 2.0)))
	cell.blend_rect(_ball_img, Rect2i(0, 0, BALL_FRAME, BALL_FRAME), at)

# where the ball is drawn in this frame (frame px), [point, in front] or null: v2 from its ball point, v1 like ball.gd
# from the hands (BALL_RULE)
func _ball_point(sh: Dictionary, anim: String, idx: int, k: int, flip: bool):
	var fmt: Dictionary = sh["fmt"]
	var h: Dictionary = Sheets.hand(fmt, str(sh["id"]), idx, flip)
	if int(sh["version"]) == 2:
		if h.has("ball"):
			return [h["ball"], bool(h.get("ball_front", true))]
		return null
	var a: String = Sheets.resolve(fmt, anim)
	var rule: String = str(BALL_RULE.get(a, ""))
	if rule == "" or h.is_empty():
		return null
	var n: int = Sheets.anim_frames(fmt, a)
	if BALL_UNTIL.has(a) and float(k) / float(n) >= float(BALL_UNTIL[a]):
		return null
	var l: Vector2 = h["L"]
	var r: Vector2 = h["R"]
	match rule:
		"dribble":
			var hand: Vector2 = l if flip else r   # the sheet dribbles with the right hand (mirrored: the left)
			return [hand + Vector2(0, BALL_R * DRIBBLE_UNDER_HAND), true]
		"up":
			var hi: Vector2 = l if l.y < r.y else r
			return [hi + Vector2(0, -BALL_R * HELD_ON_HAND), true]
	return [(l + r) / 2.0, true]

# the per-sheet images: per animation (8 directions) and its strip, and the overview
func _draw_sheet(sh: Dictionary, detail: bool) -> void:
	if not _write:
		return
	var fmt: Dictionary = sh["fmt"]
	var id: String = sh["id"]
	var fs: Vector2i = Vector2i(Sheets.frame_size(fmt))
	var cw: int = fs.x * CELL_SCALE + PAD
	var ch: int = fs.y * CELL_SCALE + PAD
	var done: Array = []
	var list: Array = []
	for a in TABLE_ANIMS:
		var r: String = Sheets.resolve(fmt, a)
		if r != "" and not done.has(r):
			done.append(r)
			list.append(r)
	for a in (fmt.get("anims", {}) as Dictionary):
		if not done.has(str(a)):
			done.append(str(a))
			list.append(str(a))
	var most := 1
	for a in list:
		most = maxi(most, Sheets.anim_frames(fmt, a))
	var over := Image.create(cw * most + PAD, ch * list.size() + PAD, false, Image.FORMAT_RGBA8)
	over.fill(BACK_COLOR)
	for ai in list.size():
		var a: String = list[ai]
		var n: int = Sheets.anim_frames(fmt, a)
		for k in n:
			over.blit_rect(_cell(sh, a, SE_ROW, false, k, CELL_SCALE, false), Rect2i(0, 0, cw - PAD, ch - PAD),
					Vector2i(PAD + k * cw, PAD + ai * ch))
		if not detail:
			continue
		var img := Image.create(cw * n + PAD, ch * OCTANTS.size() + PAD, false, Image.FORMAT_RGBA8)
		img.fill(BACK_COLOR)
		for oi in OCTANTS.size():
			var o: Array = OCTANTS[oi]
			for k in n:
				img.blit_rect(_cell(sh, a, int(o[0]), bool(o[1]), k, CELL_SCALE, true), Rect2i(0, 0, cw - PAD, ch - PAD),
						Vector2i(PAD + k * cw, PAD + oi * ch))
		_save(img, "%s/hoops_anim_%s_%s.png" % [_out, id, a])
		var sw: int = fs.x * STRIP_SCALE
		var strip := Image.create(sw * n, fs.y * STRIP_SCALE, false, Image.FORMAT_RGBA8)
		for k in n:
			strip.blit_rect(_cell(sh, a, SE_ROW, false, k, STRIP_SCALE, false), Rect2i(0, 0, sw, fs.y * STRIP_SCALE),
					Vector2i(k * sw, 0))
		_save(strip, "%s/hoops_anim_%s_%s_strip.png" % [_out, id, a])
	_save(over, "%s/hoops_anim_%s.png" % [_out, id])

func _save(img: Image, path: String) -> void:
	if img.save_png(path) == OK:
		_written += 1
	else:
		_problems.append("could not write %s" % path)

# ---------------- a fake v2 set (--anim-fake-v2) ----------------

# A 2-page v2 sheet "fake_v2" (+ a _crew recolor) with the sample's 4 animations: each frame a block body whose
# height follows the frame, so the images show the layout; the hand and ball points are the approved sample's.
func _build_fake_v2() -> void:
	DirAccess.make_dir_recursive_absolute(FAKE_DIR + Sheets.CARD_SUBDIR)
	for f in DirAccess.get_files_at(FAKE_DIR):
		DirAccess.remove_absolute(FAKE_DIR + f)
	var fmt := {"version": 2, "frame": [64, 96], "feet_row": 88, "center_x": 32, "head_px": 50, "draw_scale": 2.0,
		"dirs": Sheets.DIR_NAMES, "cols": 46, "page_cols": 32,
		"anims": {"idle": {"start": 0, "frames": 6, "fps": 6, "loop": true},
			"run": {"start": 6, "frames": 12, "fps": 20, "loop": true},
			"dribble": {"start": 18, "frames": 8, "fps": 13.3, "loop": true},
			"run_dribble": {"start": 26, "frames": 10, "fps": 16.7, "loop": true},
			"dunk_two": {"start": 36, "frames": 10, "fps": 0, "loop": false}}}
	Sheets._write_text(FAKE_DIR + Sheets.FORMAT_FILE, JSON.stringify(fmt))
	var pts = Sheets._read_json(Sheets.SAMPLE_POINTS)
	var body := {}
	if pts is Dictionary:
		for a in (pts as Dictionary).get("anims", {}):
			body[str(Sheets.SAMPLE_ANIM_NAMES.get(a, a))] = pts["anims"][a]
	body["idle"] = {}
	Sheets._write_text(FAKE_DIR + Sheets.HANDS_FILE, JSON.stringify({"frame": [64, 96], "feet_row": 88,
			"bodies": {"lanky": body}, "sheets": {"fake_v2": "lanky", "fake_v2_crew": "lanky"}}))
	for pi in 2:
		var w: int = 32 if pi == 0 else 46 - 32
		var img := Image.create(w * 64, 5 * 96, false, Image.FORMAT_RGBA8)
		for row in 5:
			for c in w:
				var col: int = pi * 32 + c
				var top: int = 40 + (col * 7 + row * 3) % 12
				img.fill_rect(Rect2i(c * 64 + 24, row * 96 + top, 16, 88 - top), Color(0.2, 0.3, 0.8))
				img.fill_rect(Rect2i(c * 64 + 26, row * 96 + top - 10, 12, 10), Color(0.55, 0.36, 0.25))
		img.save_png(FAKE_DIR + "fake_v2" + Sheets.PAGE_SUFFIX + str(pi) + ".png")
