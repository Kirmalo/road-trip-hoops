extends CanvasLayer
# How to Play (P7-H3, board "How to Play pages"): Flow screen "howto", built in code with ui_kit.gd.
# One page at a time: the title on top, the picture in the middle (assets/howto/<id>.png, 960 x 540, made by
# tools/art/make_howto.py from the game's own captures), 2-4 short lines under it and the page dots at the bottom.
# A missing picture shows a framed placeholder with the page title, so the screen works before the pictures exist.
# Paging: the big < > buttons, or a horizontal swipe anywhere (a drag of at least SWIPE_MIN px; a tap does nothing).
# BACK (top-left) goes to Flow.args.back (default "title"). Desktop testing: Escape = BACK, Left / Right = page.
# Like title.gd, the buttons and swipes ignore taps for PANEL_ARM s after the screen opens, so a quick double tap on
# the title's HOW TO PLAY button can't fall through onto BACK.
# The lines are plain data in PAGES (not baked into the pictures), so the owner can edit them on the tablet.
# Args: {"back": "<screen>"} and, optionally, {"page": <index or id>} to open on a page.
# Test flag: --howto-dir DIR reads the pictures as DIR/<id>.png (absolute path, res:// or user://) instead of
# assets/howto/ (to try pictures that are not imported yet).
# auto_step(): the next page; false on the last page (the trip and title test drivers).

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Difficulty = preload("res://scripts/difficulty.gd")

const PICTURE_DIR := "res://assets/howto/"
const DIR_FLAG := "--howto-dir"

# The pages, in the board's order: id, title, and the lines (at most 4, short and plain). The picture is <id>.png, or
# <pic>.png when a page has "pic" (P8-22: the STARS page reuses the trip picture, so the captures stay 9).
const PAGES := [
	{"id": "controls", "title": "CONTROLS", "lines": [
		"Touch and drag on the left side to move.",
		"A (orange) shoots. B (blue) passes.",
		"You play the one with the arrow over his head.",
		"Left-handed? Turn on LEFT-HANDED in Settings to swap the sides.",
	]},
	{"id": "turbo", "title": "TURBO", "lines": [
		"Drag your thumb far out past the ring to sprint.",
		"Sprinting drains the stamina bar under your feet.",
		"Ease back inside the ring and it fills up again.",
	]},
	{"id": "shoot", "title": "SHOOTING", "lines": [
		"Hold A, then let go when the meter is in the green.",
		"A basket inside the arc is 1 point, from beyond it 2.",
		"A quick tap of A is a pump fake: make them jump!",
	]},
	{"id": "dunks", "title": "DUNKS AND ALLEY-OOPS", "lines": [
		"Press A close to the rim to lay it up.",
		"Come in fast (sprint!) and you dunk it.",
		"Pass to a teammate running at the rim for an alley-oop.",
	]},
	{"id": "moves", "title": "CROSSOVER", "lines": [
		"While you dribble, flick the stick quickly the other way.",
		"Your player crosses over and bursts past.",
		"Do it right in front of a defender to leave him behind.",
	]},
	{"id": "call", "title": "CALL FOR THE BALL", "lines": [
		"Without the ball, B says CALL: press it to ask for a pass.",
		"Call while you run at the rim and you get a lob.",
		"You always play the one you pass to.",
	]},
	{"id": "defense", "title": "DEFENSE", "lines": [
		"On defense A is STEAL. Press it when it glows.",
		"When your man shoots near you, A turns into BLOCK: jump!",
		"Bad timing is a foul. Don't fall for pump fakes.",
		"B (SWITCH) takes over the teammate nearest the ball.",
	]},
	{"id": "fire", "title": "ON FIRE", "lines": [
		"Score 3 times in a row and you are on fire.",
		"On fire: a bigger green zone and no stamina drain.",
		"Two misses put the fire out.",
	]},
	{"id": "trip", "title": "THE ROAD TRIP", "lines": [
		"Beat each city's crew 3 times, then sign one of its players.",
		"Before a game, pick your 3 starters. The first one is you.",
		"Every win gives each starter 1 stat point (2 for a boss or New York).",
		"Spend them after the game, or later from the lineup.",
	]},
	{"id": "stars", "pic": "trip", "title": "STARS", "lines": [
		"Each win earns stars: Easy 1, Normal 2, Hard 3. Best kept, 72 in all.",
		"Stars open roster slots: draft a player from a crew you've beaten, or a legend.",
		"And jerseys, balls, van paints, courts and LEGEND. See the LOCKER.",
		"Lost? Just retry. Won? Replay it from the map, on any level, for more stars.",
	]},
]

# layout (px at the 1280x720 base, inside a centred 1280x720 frame; BACK sits on the screen's top-left corner)
const BASE := Vector2(1280, 720)
const BACK_POS := Vector2(24, 20)               # like title.gd
const TITLE_FONT := 56
const TITLE_TOP := 18.0
const TITLE_H := 90.0
const PIC_SIZE := Vector2(640, 360)             # the 960 x 540 picture at 2/3 (16:9), leaves room for 4 lines
const PIC_TOP := 110.0
const PIC_BORDER := 4                           # the frame around the picture
const LINES_GAP := 10.0                         # px between the picture and the first line
const LINE_FONT := 30                           # big and plain (UI.TEXT_FONT)
const LINE_SEP := 0                             # px between lines
const LINES_W := 1180.0
const ARROW_SIZE := Vector2(200, 170)           # the < > buttons, beside the picture
const ARROW_FONT := 80
const DOTS_Y := 696.0                           # centre line of the page dots
const DOT_R := 9.0
const DOT_R_ON := 13.0                          # the current page's dot
const DOT_GAP := 40.0                           # px between dot centres
const DOT_OFF := Color(0.6, 0.65, 0.75, 0.7)
const PLACEHOLDER_NOTE := "picture coming soon"
const PLACEHOLDER_NOTE_FONT := 26

const PANEL_ARM := 0.3                          # s the screen ignores taps and swipes after it opens
const SWIPE_MIN := 80.0                         # px a drag must travel sideways to turn the page
const SWIPE_SLOPE := 1.2                        # ... and more sideways than up/down by this factor

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd
var music := "menu"          # Flow plays it after _ready()

var page := 0                # index into PAGES
var _back := "title"
var _root: Control
var _frame: Control          # the centred 1280x720 frame
var _title: Label
var _pic_rect: TextureRect
var _placeholder: Control
var _ph_title: Label
var _lines: VBoxContainer
var _dots: Control
var _prev_btn: Button
var _next_btn: Button
var _buttons: Array = []
var _arm_t := 0.0
var _busy := false
var _pic_dir := ""           # --howto-dir
var _textures := {}          # id -> Texture2D (null = missing), loaded once
var _swipe_index := -1       # the finger being watched for a swipe (-1 = none)
var _swipe_from := Vector2.ZERO
var _swipe_done := false     # this drag already turned a page

func _ready() -> void:
	var a: Dictionary = Flow.args
	_back = str(a.get("back", "title"))
	if _back == "" or _back == "howto":
		_back = "title"
	_pic_dir = _arg_value(DIR_FLAG)
	page = _start_page(a.get("page", 0))
	_root = UI.screen_root(self)
	_build()
	_show_page()
	_arm(PANEL_ARM)
	_stat("howto_screen")

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_refresh_arrows()

# the first tap of the run puts a saved FULL SCREEN back (as title.gd); then the swipe
func _input(event: InputEvent) -> void:
	if Difficulty.is_release_tap(event):
		Difficulty.restore_fullscreen()
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _swipe_index < 0:
				_swipe_index = t.index
				_swipe_from = t.position
				_swipe_done = false
		elif t.index == _swipe_index:
			if not _swipe_done:
				_try_swipe(t.position)
			_swipe_index = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _swipe_index and not _swipe_done:
			_try_swipe(d.position)

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_ESCAPE:
			_on_back()
		KEY_LEFT:
			_turn(-1)
		KEY_RIGHT:
			_turn(1)

# a drag far enough sideways (and more sideways than up or down) turns the page: left = next, right = back
func _try_swipe(pos: Vector2) -> void:
	var dx: float = pos.x - _swipe_from.x
	var dy: float = pos.y - _swipe_from.y
	if absf(dx) < SWIPE_MIN or absf(dx) < absf(dy) * SWIPE_SLOPE:
		return
	_swipe_done = true
	if _busy or _arm_t > 0.0:
		return
	if _turn(1 if dx < 0.0 else -1):
		_stat("howto_swipes")

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

# ---------------- building ----------------

func _build() -> void:
	_frame = Control.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.offset_left = -BASE.x / 2.0
	_frame.offset_right = BASE.x / 2.0
	_frame.offset_top = -BASE.y / 2.0
	_frame.offset_bottom = BASE.y / 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frame)

	_title = UI.label(_frame, "", TITLE_FONT)
	_title.position = Vector2(0, TITLE_TOP)
	_title.size = Vector2(BASE.x, TITLE_H)

	# the picture, in a frame
	var pic_pos := Vector2((BASE.x - PIC_SIZE.x) / 2.0, PIC_TOP)
	var border := Panel.new()
	var sb: StyleBoxFlat = UI.style_box(UI.PANEL_COLOR, UI.PANEL_BORDER, PIC_BORDER)
	sb.set_corner_radius_all(6)
	border.add_theme_stylebox_override("panel", sb)
	border.position = pic_pos - Vector2(PIC_BORDER, PIC_BORDER)
	border.size = PIC_SIZE + Vector2(PIC_BORDER, PIC_BORDER) * 2.0
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(border)
	_pic_rect = TextureRect.new()
	_pic_rect.position = pic_pos
	_pic_rect.size = PIC_SIZE
	_pic_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # scaled down from 960 x 540: smooth, not jagged
	_pic_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_pic_rect)

	# the placeholder: the page title in a framed box (until P7-H2's pictures exist)
	_placeholder = VBoxContainer.new()
	_placeholder.position = pic_pos
	_placeholder.size = PIC_SIZE
	(_placeholder as VBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_placeholder)
	_ph_title = UI.label(_placeholder, "", UI.TITLE_FONT, UI.LIT_COLOR)
	UI.label(_placeholder, PLACEHOLDER_NOTE, PLACEHOLDER_NOTE_FONT, UI.OPT_OFF_TEXT)

	# the lines
	_lines = VBoxContainer.new()
	_lines.position = Vector2((BASE.x - LINES_W) / 2.0, PIC_TOP + PIC_SIZE.y + PIC_BORDER + LINES_GAP)
	_lines.size = Vector2(LINES_W, DOTS_Y - DOT_R_ON - 4.0 - _lines.position.y)
	_lines.add_theme_constant_override("separation", LINE_SEP)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_lines)

	# the dots
	_dots = PageDots.new()
	_dots.set("owner_screen", self)
	_dots.position = Vector2(0, DOTS_Y - DOT_R_ON)
	_dots.size = Vector2(BASE.x, DOT_R_ON * 2.0)
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_dots)

	# < > beside the picture
	var arrow_y: float = PIC_TOP + (PIC_SIZE.y - ARROW_SIZE.y) / 2.0
	var side_gap: float = ((BASE.x - PIC_SIZE.x) / 2.0 - ARROW_SIZE.x) / 2.0
	_prev_btn = _btn(_frame, "<", _turn_tap.bind(-1), UI.KIND_MAIN, ARROW_SIZE)
	_prev_btn.position = Vector2(side_gap, arrow_y)
	_next_btn = _btn(_frame, ">", _turn_tap.bind(1), UI.KIND_MAIN, ARROW_SIZE)
	_next_btn.position = Vector2(BASE.x - side_gap - ARROW_SIZE.x, arrow_y)
	for b in [_prev_btn, _next_btn]:
		b.add_theme_font_size_override("font_size", ARROW_FONT)

	var back: Button = _btn(_root, "BACK", _on_back, UI.KIND_OPT, UI.SMALL_SIZE)
	back.position = BACK_POS

func _btn(parent: Control, text: String, on_tap: Callable, kind: String, size := Vector2.ZERO) -> Button:
	var b: Button = UI.button(parent, text, _tap.bind(on_tap), kind, size)
	_buttons.append(b)
	return b

func _tap(on_tap: Callable) -> void:
	if _busy or _arm_t > 0.0:
		return
	on_tap.call()

func _arm(t: float) -> void:
	_arm_t = t
	for b in _buttons:
		UI.set_enabled(b, false)

# ---------------- pages ----------------

func page_count() -> int:
	return PAGES.size()

func page_id() -> String:
	return str(PAGES[page]["id"])

func _turn_tap(step: int) -> void:
	if _turn(step):
		_stat("howto_arrow_taps")

# step -1 / +1; false at either end (the pages don't wrap)
func _turn(step: int) -> bool:
	if _busy:
		return false
	var to: int = clampi(page + step, 0, PAGES.size() - 1)
	if to == page:
		return false
	page = to
	if audio != null:
		audio.play("bounce", -8.0)
	_show_page()
	return true

func _show_page() -> void:
	var p: Dictionary = PAGES[page]
	var title: String = str(p["title"])
	_title.text = title
	var tex: Texture2D = _texture(str(p.get("pic", p["id"])))
	_pic_rect.texture = tex
	_pic_rect.visible = tex != null
	_placeholder.visible = tex == null
	_ph_title.text = title
	for c in _lines.get_children():
		_lines.remove_child(c)
		c.queue_free()
	for line in p["lines"]:
		var l: Label = UI.label(_lines, str(line), LINE_FONT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(LINES_W, 0)
	_dots.queue_redraw()
	_refresh_arrows()
	_stat("howto_page_" + str(p["id"]))

func _refresh_arrows() -> void:
	if _arm_t > 0.0:
		return
	for b in _buttons:
		UI.set_enabled(b, true)   # BACK and the rest come back after the arm time
	UI.set_enabled(_prev_btn, page > 0)
	UI.set_enabled(_next_btn, page < PAGES.size() - 1)

# The page's picture, or null (then the placeholder shows). Loaded once per id.
func _texture(id: String) -> Texture2D:
	if _textures.has(id):
		return _textures[id]
	var tex: Texture2D = null
	if _pic_dir != "":
		var path: String = _pic_dir.path_join(id + ".png")
		var img := Image.new()
		if FileAccess.file_exists(path) and img.load(path) == OK:
			tex = ImageTexture.create_from_image(img)
	else:
		var path: String = PICTURE_DIR + id + ".png"
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
	_textures[id] = tex
	return tex

func _start_page(v) -> int:
	if v is String:
		for i in PAGES.size():
			if str(PAGES[i]["id"]) == v:
				return i
		return 0
	if v is int or v is float:
		return clampi(int(v), 0, PAGES.size() - 1)
	return 0

static func _arg_value(flag: String) -> String:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	for i in cmd.size():
		if cmd[i] == flag and i + 1 < cmd.size():
			return cmd[i + 1]
		if cmd[i].begins_with(flag + "="):
			return cmd[i].substr(flag.length() + 1)
	return ""

func _on_back() -> void:
	if _busy or _arm_t > 0.0:
		return
	_busy = true
	_stat("howto_back")
	Flow.go(_back)

# ---------------- test drivers (trip test, --titletest) ----------------

# the next page; false on the last page (nothing left to do)
func auto_step() -> bool:
	if _busy or page >= PAGES.size() - 1:
		return false
	return _turn(1)


# The page dots: one per page, the current one bigger and gold.
class PageDots extends Control:
	var owner_screen

	func _draw() -> void:
		if owner_screen == null:
			return
		var n: int = owner_screen.page_count()
		var cur: int = owner_screen.page
		var gap: float = DOT_GAP
		var x0: float = size.x / 2.0 - gap * (n - 1) / 2.0
		var y: float = size.y / 2.0
		for i in n:
			var c := Vector2(x0 + gap * i, y)
			if i == cur:
				draw_circle(c, DOT_R_ON + 2.0, UI.OUTLINE_COLOR)
				draw_circle(c, DOT_R_ON, UI.LIT_COLOR)
			else:
				draw_circle(c, DOT_R, DOT_OFF)
