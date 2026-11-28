extends CanvasLayer
# HALL OF LEGENDS (P9-19, board Phase 9; Flow screen "hall", args {"back": "legends" | "crew"}).
#   Left: the era rows (LegendsData.chapter_rows(), timeline order) in a list that scrolls (drag or wheel). Every built
#   chapter (P10-03: any number of them) is a row of its 6 plaques in plaque order: an unlocked legend is his card in
#   his era's frame with his name on the plate and his best tokens under it; a locked one is the locked frame with the
#   silhouette and "?" (a built chapter whose gate is not met says OPENS AT <gate>). A chapter that is not built is a
#   locked row: 6 small empty locked frames, COMING LATER and its gate.
#   Right: the picked plaque in detail. Unlocked: the plaque at 3x, name, full name, archetype, number, best tokens,
#   the rating shape (five bars around his level), the signature move, the mentor perk and REPLAY STORY (his unlock
#   scene in story.gd, back here on the same plaque). Locked: the silhouette, his challenge line and how to get it.
#   A locked row: its chapter, COMING LATER, the feel line and the gate.
#   Header: BACK (top-left, to args.back), HALL OF LEGENDS, a hint line, the legends unlocked and the tokens.
#   P12-18: once every era's finale is won (Legends.legends_complete()) the title and hint sit on the full Hall banner
#   (gold), and a tap on it replays the ending scene (Legends.complete_scene()), then back here.
# The layout is a 1280 x 720 box centred on wider or taller screens (like lineup.gd). Nothing mirrors for the
# left-handed layout (a menu screen has no joystick). Taps are ignored for ARM_T s after the screen opens.
# Art: assets/legends/ui.json and its frames / silhouette (P9-11); the cards are Sheets.card_info() of the legend's
# sheet (P9-09). A missing card falls back to his portrait (assets/portraits/<portrait>.png, cropped into the frame's
# window), then to the silhouette; a missing frame is a drawn box. So new art just drops in.
# Optional args: "pick" (a legend id or "ch:<chapter>": the plaque picked when the screen opens), "back_args" (a
# Dictionary handed to args.back, e.g. {"chapter": "grand"} so the tour reopens on the chapter view).
# Mentors (P9-27, owner L8 a): on an unlocked plaque the detail panel says who he trains ("TRAINS: JOJO") and that
#   perks work in Road Trip games only; TRAIN (SWITCH once he trains someone) opens the mentor picker: your players
#   (this trip's roster, loaded the way the tour loads it, never written; without a trip the underdogs,
#   Cities.START_CREW) as tiles with their card, YOU / STARTER / BENCH, and each one's mentor ("HIS PUPIL", "TRAINED
#   BY GATE", "NO MENTOR"). A tap on a free player with a free legend trains him at once; anything that breaks a pair
#   (the legend's old pupil, the player's old mentor) opens the SWITCH confirm first (NOT YET / YES, SWITCH). STOP
#   TRAINING (confirmed too) frees the legend. Everything goes through legends.gd's mentor API (mentor_of, pupil_of,
#   can_mentor, assign, release); the perk in play is P9-24's. The tiles scroll (drag, the bar, the wheel).
#   P10-B2: a mentor this build doesn't know (a newer build's legends.json, e.g. "lg_future") counts as no mentor here
#   (known_mentor(): the tile says "NO MENTOR", no confirm names him); the pair stays in the file until the player
#   is given a known mentor (the one-mentor rule then drops it, as any switch does).
# Desktop: Escape = BACK (main.gd turns the Android back into one; it closes the confirm, then the picker, first),
# Left / Right = the plaque before / after, Enter = REPLAY STORY. auto_step() (test drivers): closes the picker, then
# BACK; asked to train (args "train": true, auto_train = true or --hall-train) it first assigns one pupil: the first
# legend who can train and trains nobody on this list, on the first listed player without a mentor (YOU first).
# train(legend, player) assigns as a confirmed tap would; open_picker(legend) / close_picker() and var _picker for the
# back test.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const LegendsData = preload("res://scripts/legends_data.gd")
const Legends = preload("res://scripts/legends.gd")
const Sheets = preload("res://scripts/sheets.gd")
const StoryText = preload("res://scripts/story_text.gd")
const Trip = preload("res://scripts/trip.gd")       # P9-27: your players (the roster, its starters, the human)
const Cities = preload("res://scripts/cities.gd")   # P9-27: the underdogs without a trip, a pupil's name

# ---------------------------------------------------------------------------------------------------- tuning
const ARM_T := 0.4                       # s the taps are ignored after the screen opens
const FRAME_SIZE := Vector2(1280, 720)   # the layout box, centred on wider / taller screens
const BACK_POS := Vector2(16, 8)         # BACK, top-left (UI.SMALL_SIZE)
const TITLE_RECT := Rect2(232, 2, 760, 72)
const HINT_RECT := Rect2(232, 74, 760, 40)
const HINT_FONT := 22
const HINT_T := 2.4                      # s a tap message stays on the hint line
const COUNT_RECT := Rect2(1004, 14, 260, 100)   # legends unlocked and tokens, top-right
const COUNT_FONT := 36
const COUNT_SUB_FONT := 22
const LIST_RECT := Rect2(16, 126, 762, 580)     # the era rows (scrolls)
const SCROLL_BAR_W := 36                 # wide enough to drag with a thumb
const LIST_W := 718.0                    # px of row content (LIST_RECT minus the scroll bar and a gap)
const DETAIL_RECT := Rect2(792, 126, 472, 580)  # the picked plaque in detail
# rows
const ROW_HEAD_H := 40.0                 # px: "CHAPTER 1  THE GRANDFATHERS" over a row
const ROW_HEAD_FONT := 26
const ROW_SUB_FONT := 20
const ROW_GAP := 18.0                    # px between rows
const PLAQUE_SCALE := 2.0                # a built row's plaques: 56 x 88 texels drawn at 2x (112 x 176)
const PLAQUE_GAP := 6.0                  # px between plaques in a row
const PIPS_H := 22.0                     # px under a plaque: his best tokens
const PIP_R := 6.0
const LOCKED_ROW_SCALE := 1.0            # a chapter that is not built: small empty frames (56 x 88)
const LOCKED_ROW_GAP := 6.0
const LOCKED_TEXT_X := 384.0             # px: COMING LATER and the gate, right of the small frames
const ROW_FILL := Color(0.1, 0.12, 0.18, 0.92)
const ROW_LOCKED_FILL := Color(0.07, 0.08, 0.11, 0.9)
const ROW_PAD := 8.0
const PICK_BORDER_W := 4.0               # the gold outline around the picked plaque
const PICK_OUT := 3.0                    # px the outline sits outside the plaque
const TAP_SLOP := 14.0                   # px a finger may move and still tap (more = a scroll drag)
const JUMP_PX := 80.0                    # px: one motion longer than this is the emulated mouse jumping, not a drag
# the detail panel (px inside DETAIL_RECT)
const DETAIL_PAD := 14.0
const DETAIL_SCALE := 3.0                # the picked plaque at 3x (168 x 264)
const DETAIL_COL_X := 196.0              # the column right of the plaque
const DETAIL_NAME_FONT := 36
const DETAIL_FULL_FONT := 19
const DETAIL_FULL_MIN := 14              # the full name shrinks down to this to fit one line
const DETAIL_TEXT_FONT := 20
const DETAIL_HEAD_FONT := 18             # "SIGNATURE MOVE", "MENTOR PERK"
const SHAPE_Y := 188.0                   # the rating shape bars in the right column
const SHAPE_ROW := 18.0
const SHAPE_LABEL_W := 44.0
const SHAPE_NUM_W := 40.0
const SHAPE_MAX := 25.0                  # an offset of this fills half the bar
const SHAPE_BAR_H := 10.0
const SIG_Y := 290.0                     # SIGNATURE MOVE under the plaque
const PERK_Y := 380.0                    # MENTOR PERK (lower when the signature text needs it, P10-B6)
const PERK_GAP := 6.0                    # P10-B6: px at least between the signature text and MENTOR PERK
const PERK_BLOCK_H := 52.0               # MENTOR PERK and its one line (22 + 30), kept above MENTOR_RECT
const SIG_TEXT_MIN := 14                 # a long signature text shrinks down to this so the perk block fits
const DETAIL_ARCH_MIN := 12              # P10-B5: a long archetype shrinks down to this to fit one line
const MENTOR_RECT := Rect2(14, 434, 444, 20)    # P9-27: the strip for "TRAINS: ..."
const REPLAY_RECT := Rect2(14, 456, 444, 110)   # REPLAY STORY and TRAIN share it (each >= UI.MIN_BUTTON)
const REPLAY_FONT := 40
# P9-27: the mentor panel
const TRAIN_GAP := 8.0                   # px between REPLAY STORY and TRAIN (REPLAY_RECT split in two)
const HALF_BTN_FONT := 30                # their font (shrinks to fit, down to HALF_BTN_MIN)
const HALF_BTN_MIN := 18
const MENTOR_FONT := 18
const RT_ONLY_TEXT := "ROAD TRIP GAMES ONLY"   # right on the MENTOR PERK line (owner L8 a)
const PICKER_ARM_T := 0.3                # s the picker ignores taps after it opens (the TRAIN tap can't pick)
const CONFIRM_ARM_T := 0.3               # s YES stays off once the confirm is up (the tile tap can't confirm)
const PICKER_RECT := Rect2(40, 14, 1200, 692)       # the picker panel (frame px)
const PICKER_TITLE_FONT := 40
const PICKER_LINE_FONT := 22
const PICK_LIST_RECT := Rect2(64, 160, 1152, 388)   # the player tiles (scrolls)
const PICK_COLS := 4
const TILE_SIZE := Vector2(270, 120)     # one player tile: the tap target (>= UI.MIN_BUTTON)
const TILE_GAP := 10
const TILE_PAD := 8.0
const TILE_SPRITE_SCALE := 1.5           # his card in a 40 x 64 box at this scale
const TILE_SHEET_BOX := Vector2(40, 64)
const TILE_NAME_FONT := 24
const TILE_TEXT_FONT := 16
const TILE_FILL := Color(0.13, 0.16, 0.24)
const TILE_PUPIL_FILL := Color(0.3, 0.24, 0.08)
const TILE_BORDER_W := 3
const TILE_PUPIL_BORDER_W := 6
const FALLBACK_SHEET := "ud_jojo"        # a tile whose player has no card of his own
const PICKER_BTN_Y := 570.0              # CLOSE and STOP TRAINING (frame px)
const CLOSE_SIZE := Vector2(240, 110)
const STOP_SIZE := Vector2(340, 110)
const CONFIRM_BOX := Vector2(860, 420)
const CONFIRM_BTN := Vector2(300, 120)
const CONFIRM_FONT := 24
const MENTOR_COLOR := Color(0.55, 0.78, 1.0)   # "TRAINED BY ..." (another legend)
const AUTO_TRAIN_FLAG := "--hall-train"  # test only: auto_step() assigns one pupil before BACK
const LOCK_LINE_Y := 300.0               # a locked plaque: how to unlock him
# colors
const GOLD := Color(1.0, 0.82, 0.25)
const DIM_TEXT := Color(0.7, 0.72, 0.78)
const LOCKED_TEXT := Color(0.55, 0.57, 0.63)
const HINT_COLOR := Color(0.85, 0.87, 0.92)
const WARN_COLOR := Color(1.0, 0.6, 0.35)
const PIP_ON := Color(1.0, 0.82, 0.25)
const PIP_OFF := Color(0.3, 0.31, 0.37)
const SHAPE_BG := Color(0.25, 0.27, 0.33)
const SHAPE_UP := Color(1.0, 0.82, 0.25)
const SHAPE_DOWN := Color(0.45, 0.65, 1.0)
const PLATE_TEXT := Color(0.16, 0.1, 0.04)     # the name on the era frame's gold plate
const PLATE_LOCKED_TEXT := Color(0.82, 0.82, 0.88)
const PLATE_FONT_MAX := 12               # texel-scaled: the plate font is this x the plaque scale at most
const PLATE_FONT_MIN := 7
const FALLBACK_FRAME := Color(0.42, 0.3, 0.16)  # a frame file is missing: a drawn box in this color
const FALLBACK_LOCKED := Color(0.25, 0.26, 0.3)
const SILHOUETTE_COLOR := Color(0.05, 0.05, 0.08)
# art (assets/legends/ui.json; these are its values, used while the file is missing)
const UI_DIR := "res://assets/legends/"
const UI_JSON := "res://assets/legends/ui.json"
const PORTRAIT_DIR := "res://assets/portraits/"
const DEF_FRAME := Vector2(56, 88)
const DEF_WINDOW := Rect2(8, 8, 40, 60)
const DEF_CARD_CROP := Rect2(12, 34, 40, 60)
const DEF_PLATE := Rect2(6, 72, 44, 11)
const DEF_FRAMES := {"grand": "frame_grand.png", "locked": "frame_locked.png"}
const DEF_SILHOUETTE := "silhouette.png"
# P10-03: per-chapter art, as legends_tour.gd. A chapter's frame that ui.json doesn't list (or whose file is missing)
# is this chapter's (Chapter 1's). ui.json's optional "colors": {"<chapter>": {"title": "#rrggbb", "plate_text":
# "#rrggbb"}} tint a built row's heading and his name plates (not listed = GOLD / PLATE_TEXT, as in Phase 9).
const ART_BASE_CHAPTER := "grand"
const FALLBACK_DARKEN := 0.35            # a missing era frame is drawn in its crew's ui_color, this much darker
const V2_CARD := Vector2(64, 96)         # a v2 card frame (card_crop is inside it)
const STAT_NAMES := [["speed", "SPD"], ["shooting", "SHT"], ["finishing", "FIN"], ["defense", "DEF"],
		["stamina", "STA"]]
const CH_PICK := "ch:"                   # a pick of a locked row: "ch:<chapter id>"
const HINT_TEXT := "Tap a plaque. Beat a legend on the LEGENDS tour to hang him here."
const STORY_SCREEN := "story"
const SELF_SCREEN := "hall"
# P12-18 (Q8 a): the full Hall banner. Once Legends.legends_complete() (every era's finale won, so every plaque is up)
# the header (HALL OF LEGENDS and the hint line) sits on a gold banner; the hint says the Hall is full, and a tap on the
# banner (a tap target the size of the title and hint, >= UI.MIN_BUTTON) replays the ending, Legends.complete_scene(),
# then back here on the same plaque. Drawn in code (ui_kit look), no art file.
const BANNER_RECT := Rect2(224, 4, 776, 114)    # behind TITLE_RECT and HINT_RECT
const BANNER_FILL := Color(0.3, 0.2, 0.04, 0.94)
const BANNER_BORDER := 5                        # px, UI.LIT_COLOR
const BANNER_PRESSED_FILL := Color(0.42, 0.3, 0.07, 0.96)
const FULL_HINT := "THE HALL IS FULL: LEGENDS COMPLETE. TAP HERE FOR THE ENDING."
const FULL_HINT_COLOR := Color(1.0, 0.93, 0.7)

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd
var music := "menu"

var _root: Control
var _frame: Control
var _scroll: ScrollContainer
var _list: HallList
var _detail: Control
var _art: DetailArt
var _hint: Label
var _hint_t := 0.0
var _replay: Button = null
var _banner: Button = null   # P12-18: the full Hall banner (null until the mode is complete)
var _back := "legends"
var _back_args := {}
var _arm_t := ARM_T
var _busy := false
var _pick := ""              # the picked plaque: a legend id or "ch:<chapter id>"
var _rows: Array = []        # the list layout: {"ch", "built", "rect", "plaques": [{"id", "rect"}]}
var _order: Array = []       # every pick in list order (Left / Right)
var _scroll_frames := 0      # frames until the list scrolls the picked plaque into view (after layout)
var _ui := {}                # ui.json
# P9-27: the mentor panel
var _train: Button = null    # TRAIN / SWITCH on an unlocked plaque
var _picker: Control = null  # the mentor picker (null = closed)
var _picker_for := ""        # the legend the picker is for
var _picker_scroll: ScrollContainer = null
var _picker_arm_t := 0.0
var _tiles: Array = []       # the picker's PlayerTile nodes
var _confirm: Control = null # the SWITCH / STOP confirm (null = closed)
var _yes: Button = null
var _confirm_t := 0.0
var _confirm_pair: Array = []   # [legend id, player id] to assign, or [legend id, ""] to stop training
var _players: Array = []     # your players: {"id", "name", "number", "role", "sheet", "tag"}, YOU first
var _has_trip := false       # a trip is loaded (else _players are the underdogs)
var auto_train := false      # test drivers: auto_step() assigns one pupil first (args "train", --hall-train)
var _auto_trained := false
var _tex := {}               # path -> Texture2D (null = missing)
var _cards := {}             # legend id -> {"tex", "src"} (empty = silhouette)

func _ready() -> void:
	Legends.load_state()
	var a: Dictionary = Flow.args if str(Flow.screen) == SELF_SCREEN else {}
	var b: String = str(a.get("back", "legends"))
	_back = b if Flow.HALL_BACKS.has(b) else "legends"
	var ba = a.get("back_args", {})
	_back_args = (ba as Dictionary).duplicate(true) if ba is Dictionary else {}
	_ui = _read_ui()
	auto_train = bool(a.get("train", false)) or OS.get_cmdline_user_args().has(AUTO_TRAIN_FLAG)
	_load_players()
	_root = UI.screen_root(self)
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.size = FRAME_SIZE
	_root.add_child(_frame)
	_root.resized.connect(_center)
	_center()
	_layout()
	_pick = _first_pick(str(a.get("pick", "")))
	_build_head()
	_build_list()
	_build_detail()
	_show_pick()
	_scroll_frames = 2
	_stat("hall_screen")
	print("HALL screen | unlocked %d/%d %s | tokens %d/%d | pick %s | back %s%s%s" % [
			Legends.unlocked_ids().size(), LegendsData.legend_ids().size(), str(Legends.unlocked_ids()),
			Legends.tokens_total(), LegendsData.max_tokens(), _pick, _back,
			(" " + JSON.stringify(_back_args)) if not _back_args.is_empty() else "",
			" | FULL HALL banner" if banner_shown() else ""])
	print("HALL mentors | %s %d players %s | pairs %s" % ["trip" if _has_trip else "no trip (underdogs)",
			_players.size(), str(player_ids()), JSON.stringify(Legends.mentors)])

func _center() -> void:
	_frame.position = ((_root.size - FRAME_SIZE) / 2.0).floor()

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
	if _picker_arm_t > 0.0:
		_picker_arm_t -= delta
	if _confirm_t > 0.0:
		_confirm_t -= delta
		if _confirm_t <= 0.0 and _yes != null:
			UI.set_enabled(_yes, true)
	if _hint_t > 0.0:
		_hint_t -= delta
		if _hint_t <= 0.0:
			_set_hint(_hint_default(), _hint_default_color())
	if _scroll_frames > 0:
		_scroll_frames -= 1
		if _scroll_frames == 0:
			_scroll_to_pick()

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _confirm != null:
			_close_confirm()
		elif _picker != null:
			close_picker()
		else:
			_on_back()
	elif _picker != null:
		return   # the picker is up: the plaque keys wait
	elif k.keycode == KEY_LEFT or k.keycode == KEY_RIGHT:
		var i: int = _order.find(_pick)
		if i >= 0 and not _order.is_empty():
			i = clampi(i + (1 if k.keycode == KEY_RIGHT else -1), 0, _order.size() - 1)
			pick(str(_order[i]))
			_scroll_to_pick()
	elif k.keycode == KEY_ENTER:
		_on_replay()

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

func _sfx(sfx_name: String, db := 0.0) -> void:
	if audio != null:
		audio.play(sfx_name, db)

# ---------------------------------------------------------------------------------------------------- state

# the plaque picked when the screen opens: args.pick if it is on the list, else the first unlocked legend, else the
# first plaque
func _first_pick(want: String) -> String:
	if want != "" and _order.has(want):
		return want
	for id in Legends.unlocked_ids():
		if _order.has(str(id)):
			return str(id)
	return str(_order[0]) if not _order.is_empty() else ""

# picks a plaque (a tap, Left / Right, the test drivers); false for something not on the list
func pick(what: String) -> bool:
	if not _order.has(what):
		return false
	if what != _pick:
		_pick = what
		_sfx("bounce", -6.0)
		_stat("hall_pick")
		_show_pick()
	return true

func picked() -> String:
	return _pick

# a legend's plaque state: "open" (unlocked), "locked"
static func plaque_state(id: String) -> String:
	return "open" if Legends.is_unlocked(id) else "locked"

# the unlock scene REPLAY STORY plays ("" when he is locked or story_text.gd has no such scene)
static func replay_scene(id: String) -> String:
	if not LegendsData.is_legend_id(id) or not Legends.is_unlocked(id):
		return ""
	var sc: String = str(LegendsData.legend(id).get("unlock_scene", ""))
	return sc if sc != "" and StoryText.has_scene(sc) else ""

# ---------------------------------------------------------------------------------------------------- layout

# the rows, their plaques and the pick order, in list coordinates
func _layout() -> void:
	_rows = []
	_order = []
	var fs: Vector2 = _frame_size()
	var y: float = 0.0
	var n: int = 0
	for row in LegendsData.chapter_rows():
		n += 1
		var ch: String = str(row.get("id", ""))
		var built: bool = bool(row.get("built", false)) and not (row.get("legends", []) as Array).is_empty()
		var r := {"ch": ch, "num": n, "built": built, "plaques": []}
		var top: float = y
		var py: float = top + ROW_HEAD_H
		if built:
			var sz: Vector2 = fs * PLAQUE_SCALE
			var ids: Array = row.get("legends", [])
			var w: float = ids.size() * sz.x + maxf(0.0, ids.size() - 1.0) * PLAQUE_GAP
			var x: float = floorf((LIST_W - w) / 2.0)
			for id in ids:
				(r["plaques"] as Array).append({"id": str(id), "rect": Rect2(Vector2(x, py), sz)})
				_order.append(str(id))
				x += sz.x + PLAQUE_GAP
			y = py + sz.y + PIPS_H + ROW_PAD
		else:
			var sz: Vector2 = fs * LOCKED_ROW_SCALE
			var x: float = ROW_PAD + 6.0
			for i in 6:
				(r["plaques"] as Array).append({"id": "", "rect": Rect2(Vector2(x, py + 2.0), sz)})
				x += sz.x + LOCKED_ROW_GAP
			_order.append(CH_PICK + ch)
			y = py + sz.y + ROW_PAD + 6.0
		r["rect"] = Rect2(0.0, top, LIST_W, y - top)
		_rows.append(r)
		y += ROW_GAP
	if _list != null:
		_list.custom_minimum_size = Vector2(LIST_W, maxf(0.0, y - ROW_GAP))

# what is under a point of the list ("" = nothing): a plaque's legend id, or "ch:<id>" anywhere on a locked row
func pick_at(p: Vector2) -> String:
	for r in _rows:
		if not (r["rect"] as Rect2).has_point(p):
			continue
		if not bool(r["built"]):
			return CH_PICK + str(r["ch"])
		for q in r["plaques"]:
			if (q["rect"] as Rect2).grow(PLAQUE_GAP / 2.0).has_point(p):
				return str(q["id"])
	return ""

# the picked plaque's rect in list coordinates (the whole row for a locked row)
func _pick_rect() -> Rect2:
	for r in _rows:
		if _pick == CH_PICK + str(r["ch"]):
			return r["rect"]
		for q in r["plaques"]:
			if str(q["id"]) == _pick and _pick != "":
				return q["rect"]
	return Rect2()

func _scroll_to_pick() -> void:
	if _scroll == null:
		return
	var r: Rect2 = _pick_rect()
	var top: float = r.position.y - ROW_HEAD_H
	var bottom: float = r.end.y + PIPS_H
	var view_h: float = LIST_RECT.size.y
	var s: float = float(_scroll.scroll_vertical)
	if top < s:
		_scroll.scroll_vertical = int(maxf(0.0, top))
	elif bottom > s + view_h:
		_scroll.scroll_vertical = int(bottom - view_h)

# ---------------------------------------------------------------------------------------------------- building

func _build_head() -> void:
	var back: Button = UI.button(_frame, "BACK", _on_back, UI.KIND_OPT, UI.SMALL_SIZE)
	back.position = BACK_POS
	if hall_full():
		# P12-18: the full Hall banner, under the title and the hint (labels ignore the mouse: the tap reaches it)
		_banner = UI.button(_frame, "", replay_ending, UI.KIND_LIT, BANNER_RECT.size)
		_banner.name = "HallFullBanner"
		var sb: StyleBoxFlat = UI.style_box(BANNER_FILL, UI.LIT_COLOR, BANNER_BORDER)
		for k in ["normal", "hover", "disabled"]:
			_banner.add_theme_stylebox_override(k, sb)
		_banner.add_theme_stylebox_override("pressed", UI.style_box(BANNER_PRESSED_FILL, UI.LIT_BORDER, BANNER_BORDER))
		_banner.position = BANNER_RECT.position
		_banner.size = BANNER_RECT.size
	var head: Label = UI.title(_frame, "HALL OF LEGENDS", GOLD)
	head.position = TITLE_RECT.position
	head.size = TITLE_RECT.size
	_hint = UI.label(_frame, _hint_default(), HINT_FONT, _hint_default_color())
	_hint.position = HINT_RECT.position
	_hint.size = HINT_RECT.size
	_hint.clip_text = true
	var count := CountBox.new()
	count.screen = self
	count.position = COUNT_RECT.position
	count.size = COUNT_RECT.size
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(count)

func _build_list() -> void:
	_scroll = ScrollContainer.new()
	_scroll.position = LIST_RECT.position
	_scroll.size = LIST_RECT.size
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(SCROLL_BAR_W, 0)
	bar.add_theme_stylebox_override("scroll", UI.style_box(UI.OPT_COLOR, UI.OPT_BORDER, 2))
	for k in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(k, UI.style_box(UI.LIT_COLOR, UI.LIT_BORDER, 2))
	_frame.add_child(_scroll)
	_list = HallList.new()
	_list.screen = self
	_list.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll.add_child(_list)
	_layout()   # again: sets the list's height now that it exists

func _build_detail() -> void:
	var p: PanelContainer = UI.panel(_frame, DETAIL_RECT.size)
	p.position = DETAIL_RECT.position
	p.size = DETAIL_RECT.size
	_detail = Control.new()
	_detail.position = DETAIL_RECT.position
	_detail.size = DETAIL_RECT.size
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_detail)

# fills the detail panel for the picked plaque
func _show_pick() -> void:
	if _list != null:
		_list.queue_redraw()
	if _detail == null:
		return
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	_replay = null
	_train = null
	_art = DetailArt.new()
	_art.screen = self
	_art.pick = _pick
	_art.size = DETAIL_RECT.size
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(_art)
	if _pick.begins_with(CH_PICK):
		_detail_chapter(_pick.substr(CH_PICK.length()))
	elif _pick != "" and plaque_state(_pick) == "open":
		_detail_open(_pick)
	elif _pick != "":
		_detail_locked(_pick)

# a text label in the detail panel (wraps when h > one line)
func _text(text: String, rect: Rect2, fs: int, col: Color, wrap := false,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: Label = UI.label(null, text, fs, col)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # before the size: else the label grows to one line
	else:
		l.clip_text = true
	(l.label_settings as LabelSettings).outline_size = 6
	_detail.add_child(l)
	l.position = rect.position
	l.size = rect.size
	l.set_deferred("size", rect.size)
	return l

func _detail_open(id: String) -> void:
	var p: Dictionary = LegendsData.legend(id)
	var ch: Dictionary = LegendsData.chapter(str(p.get("chapter", "")))
	var x: float = DETAIL_COL_X
	var w: float = DETAIL_RECT.size.x - x - DETAIL_PAD
	var nm: Label = _text(str(p.get("name", id)), Rect2(x, 10, w, 44), DETAIL_NAME_FONT, GOLD)
	_fit_font(nm, w)
	var full: Label = _text(str(p.get("full", "")), Rect2(x, 60, w, 30), DETAIL_FULL_FONT, UI.TEXT_COLOR)
	_fit_font(full, w, DETAIL_FULL_MIN)
	var arch: Label = _text(str(p.get("archetype", "")).to_upper(), Rect2(x, 108, w, 26), DETAIL_TEXT_FONT - 2,
			UI.TEXT_COLOR)
	_fit_font(arch, w, DETAIL_ARCH_MIN)
	var num: int = int(p.get("number", 0))
	_text(("#%d  " % num if num > 0 else "") + str(ch.get("name", "")), Rect2(x, 134, w, 24), DETAIL_HEAD_FONT,
			DIM_TEXT)
	_text("BEST", Rect2(x, 158, 70, 24), DETAIL_HEAD_FONT, DIM_TEXT)   # the pips are drawn by DetailArt
	var full_w: float = DETAIL_RECT.size.x - 2.0 * DETAIL_PAD
	var sig: Dictionary = p.get("signature", {})
	_text("SIGNATURE MOVE", Rect2(DETAIL_PAD, SIG_Y, full_w, 22), DETAIL_HEAD_FONT, GOLD)
	# P10-B6: the perk block goes under the signature text's measured height; a text too tall for the space above
	# the mentor strip shrinks (down to SIG_TEXT_MIN)
	var sig_text: String = str(sig.get("text", ""))
	var sig_fs: int = DETAIL_TEXT_FONT
	var sig_h: float = _wrapped_height(sig_text, full_w, sig_fs)
	var perk_y: float = maxf(PERK_Y, SIG_Y + 22.0 + sig_h + PERK_GAP)
	while sig_fs > SIG_TEXT_MIN and perk_y + PERK_BLOCK_H > MENTOR_RECT.position.y:
		sig_fs -= 1
		sig_h = _wrapped_height(sig_text, full_w, sig_fs)
		perk_y = maxf(PERK_Y, SIG_Y + 22.0 + sig_h + PERK_GAP)
	_text(sig_text, Rect2(DETAIL_PAD, SIG_Y + 22.0, full_w, sig_h), sig_fs, UI.TEXT_COLOR, true)
	var perk: Dictionary = LegendsData.perk_of(id)
	_text("MENTOR PERK", Rect2(DETAIL_PAD, perk_y, full_w, 22), DETAIL_HEAD_FONT, GOLD)
	if not perk.is_empty():
		_text(RT_ONLY_TEXT, Rect2(DETAIL_PAD, perk_y, full_w, 22), DETAIL_HEAD_FONT, DIM_TEXT, false,
				HORIZONTAL_ALIGNMENT_RIGHT)
	var perk_lbl: Label = _text(str(perk.get("text", "none")), Rect2(DETAIL_PAD, perk_y + 22.0, full_w, 30),
			DETAIL_TEXT_FONT, UI.TEXT_COLOR)
	_fit_font(perk_lbl, full_w, 14)   # P12-B1: the longest perk texts (Glitch's, Firewall's) shrink instead of clipping
	var mentor: bool = _mentor_hook(id, MENTOR_RECT)
	var rr: Rect2 = REPLAY_RECT
	if mentor:
		rr.size.x = (REPLAY_RECT.size.x - TRAIN_GAP) / 2.0
	_replay = UI.button(_detail, "REPLAY STORY", _on_replay, UI.KIND_MAIN, rr.size)
	_replay.position = rr.position
	_replay.add_theme_font_size_override("font_size", REPLAY_FONT if not mentor else HALF_BTN_FONT)
	if replay_scene(id) == "":
		UI.set_enabled(_replay, false)
		_replay.text = "STORY COMING SOON" if not mentor else "STORY SOON"
	if mentor:
		_fit_button(_replay, rr.size.x)
		_train.reset_size()
	_replay.reset_size()   # back to its minimum: UI.button sized it for its first font

# P9-27: "TRAINS: <player>" in box and the TRAIN / SWITCH button (the right half of REPLAY_RECT). Reads and writes
# mentors only through legends.gd's mentor API. False when this legend can't train (no perk): no button.
func _mentor_hook(id: String, box: Rect2) -> bool:
	_train = null
	if not Legends.can_mentor(id):
		return false
	var pupil: String = Legends.pupil_of(id)
	var txt: String = "TRAINS: NOBODY YET  -  tap TRAIN"
	var col: Color = DIM_TEXT
	if pupil != "":
		txt = "TRAINS: " + player_name(pupil).to_upper()
		col = GOLD
		if not has_player(pupil):
			txt += "  (NOT ON %s)" % ("THIS TRIP" if _has_trip else "YOUR CREW")
			col = WARN_COLOR
	var l: Label = _text(txt, box, MENTOR_FONT, col)
	l.clip_text = true
	var w: float = (REPLAY_RECT.size.x - TRAIN_GAP) / 2.0
	_train = UI.button(_detail, "SWITCH" if pupil != "" else "TRAIN", _on_train, UI.KIND_LIT,
			Vector2(w, REPLAY_RECT.size.y))
	_train.position = REPLAY_RECT.position + Vector2(w + TRAIN_GAP, 0.0)
	_train.add_theme_font_size_override("font_size", HALF_BTN_FONT)
	_fit_button(_train, w)
	return true

# shrinks a button's font (down to HALF_BTN_MIN) until its text fits w
static func _fit_button(b: Button, w: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var fs: int = b.get_theme_font_size("font_size")
	while fs > HALF_BTN_MIN and font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w - 28.0:
		fs -= 2
	b.add_theme_font_size_override("font_size", fs)

func _detail_locked(id: String) -> void:
	var p: Dictionary = LegendsData.legend(id)
	var chid: String = str(p.get("chapter", ""))
	var c: Dictionary = LegendsData.challenge(id)
	var x: float = DETAIL_COL_X
	var w: float = DETAIL_RECT.size.x - x - DETAIL_PAD
	_text("?", Rect2(x, 10, w, 44), DETAIL_NAME_FONT, LOCKED_TEXT)
	_text("LEGEND LOCKED", Rect2(x, 58, w, 26), DETAIL_TEXT_FONT, LOCKED_TEXT)
	_text("HIS CHALLENGE", Rect2(x, 100, w, 22), DETAIL_HEAD_FONT, GOLD)
	_text(str(c.get("line", "")), Rect2(x, 124, w, 140), DETAIL_TEXT_FONT, UI.TEXT_COLOR, true)
	var full_w: float = DETAIL_RECT.size.x - 2.0 * DETAIL_PAD
	var how: String = "Win this challenge on the LEGENDS tour and he joins the Hall: his card, his story and the perk he teaches."
	_text(how, Rect2(DETAIL_PAD, LOCK_LINE_Y, full_w, 100), DETAIL_TEXT_FONT, DIM_TEXT, true)
	if not Legends.chapter_open(chid):
		_text("CHAPTER OPENS AT %s" % Legends.gate_text(chid), Rect2(DETAIL_PAD, LOCK_LINE_Y + 110.0, full_w, 30),
				DETAIL_TEXT_FONT, WARN_COLOR)

func _detail_chapter(chid: String) -> void:
	var row: Dictionary = LegendsData.chapter(chid)
	var x: float = DETAIL_COL_X
	var w: float = DETAIL_RECT.size.x - x - DETAIL_PAD
	_text("CHAPTER %d" % (LegendsData.chapter_ids().find(chid) + 1), Rect2(x, 14, w, 26), DETAIL_HEAD_FONT + 2,
			DIM_TEXT)
	_text(str(row.get("name", chid)), Rect2(x, 40, w, 90), DETAIL_NAME_FONT - 6, LOCKED_TEXT, true)
	_text("COMING LATER", Rect2(x, 136, w, 28), DETAIL_TEXT_FONT + 2, GOLD)
	_text(str(row.get("feel", "")), Rect2(x, 170, w, 90), DETAIL_TEXT_FONT, UI.TEXT_COLOR, true)
	var full_w: float = DETAIL_RECT.size.x - 2.0 * DETAIL_PAD
	var gate: String = Legends.gate_text(chid)
	if gate != "":
		_text("OPENS AT " + gate, Rect2(DETAIL_PAD, LOCK_LINE_Y, full_w, 30), DETAIL_TEXT_FONT, WARN_COLOR)
	_text("Six more legends wait in this era. Their plaques go up here when the chapter is built.",
			Rect2(DETAIL_PAD, LOCK_LINE_Y + 40.0, full_w, 100), DETAIL_TEXT_FONT, DIM_TEXT, true)

# the height of a wrapped _text() label (word-smart wrap at width w, font size fs, the default line spacing)
static func _wrapped_height(text: String, w: float, fs: int) -> float:
	if text == "":
		return 0.0
	var font: Font = ThemeDB.fallback_font
	var flags: int = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var line_h: float = font.get_height(fs)
	var lines: int = maxi(1, roundi(font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, fs, -1,
			flags).y / line_h))
	return lines * (line_h + LabelSettings.new().line_spacing)

# shrinks a one-line label's font (down to min_size) until its text fits max_w
static func _fit_font(lbl: Label, max_w: float, min_size := 16) -> void:
	var ls: LabelSettings = lbl.label_settings
	var font: Font = ls.font if ls.font != null else ThemeDB.fallback_font
	while ls.font_size > min_size and font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ls.font_size).x \
			+ 2.0 * ls.outline_size > max_w:
		ls.font_size -= 2

func _set_hint(text: String, col: Color) -> void:
	_hint.text = text
	_hint.label_settings.font_color = col

func _flash(text: String, col := WARN_COLOR) -> void:
	_set_hint(text, col)
	_hint_t = HINT_T

# ---------------------------------------------------------------------------------------------------- mentors (P9-27)

# Your players: the loaded trip's roster (Legends loads the saved trip the way the tour does, saving off: the Hall
# never writes the trip), YOU first, then the starters, then the bench in roster order. Without a trip: the underdogs
# (Cities.START_CREW, who start every new trip; the first is YOU by default).
func _load_players() -> void:
	_has_trip = Trip.active or Legends._trip_loaded()
	_players = []
	var ids: Array = []
	if _has_trip:
		var roster: Array = Trip.roster_ids()
		if roster.has(Trip.human):
			ids.append(Trip.human)
		for id in Trip.starters:
			if roster.has(str(id)) and not ids.has(str(id)):
				ids.append(str(id))
		for id in roster:
			if not ids.has(str(id)):
				ids.append(str(id))
	else:
		for id in Cities.START_CREW:
			ids.append(str(id))
	for id in ids:
		var sid: String = str(id)
		if LegendsData.is_legend_id(sid):
			continue   # owner: legends coach your regular players only (a drafted legend has no mentor)
		var tag: String = "BENCH"
		if _has_trip:
			if sid == Trip.human:
				tag = "YOU"
			elif Trip.starters.has(sid):
				tag = "STARTER"
		else:
			tag = "UNDERDOG"   # P9-B5: no trip yet, so nobody is YOU (the tour's Kings order differs)
		var pd: Dictionary = Cities.player(sid)
		_players.append({"id": sid, "name": str(pd.get("name", sid)), "number": int(pd.get("number", 0)),
			"role": str(pd.get("role", "")), "sheet": Cities.crew_sheet(sid, true), "tag": tag,
			"legend": Trip.is_legend(sid)})

func player_ids() -> Array:
	var out: Array = []
	for p in _players:
		out.append(str(p["id"]))
	return out

func has_player(id: String) -> bool:
	return id != "" and player_ids().has(id)

# a player's short name (one of yours, else his data row, else the id)
func player_name(id: String) -> String:
	for p in _players:
		if str(p["id"]) == id:
			return str(p["name"])
	var pd: Dictionary = Cities.player(id)
	return str(pd.get("name", id)) if not pd.is_empty() else id

static func legend_name(id: String) -> String:
	return str(LegendsData.legend(id).get("name", id))

# this player's mentor if this build knows him, else "" (P10-B2: a newer file's legend shows as no mentor; the pair
# itself is left in the file)
static func known_mentor(player_id: String) -> String:
	var m: String = Legends.mentor_of(player_id)
	return m if LegendsData.is_legend_id(m) else ""

# the mentor line on this player's tile in this legend's picker
static func tile_status(player_id: String, legend_id: String) -> String:
	var m: String = known_mentor(player_id)
	if m == "":
		return "NO MENTOR"
	if m == legend_id:
		return "HIS PUPIL"
	return "TRAINED BY " + legend_name(m).to_upper()

func _on_train() -> void:
	if _busy or _arm_t > 0.0 or _picker != null:
		return
	open_picker(_pick)

# Opens the mentor picker for this legend (default: the picked plaque); false when he can't train or it is open.
func open_picker(legend_id := "") -> bool:
	var lid: String = legend_id if legend_id != "" else _pick
	if _busy or _picker != null or not Legends.can_mentor(lid):
		return false
	if lid != _pick:
		pick(lid)
	_picker_for = lid
	_tiles = []
	var dim := ColorRect.new()
	dim.color = UI.DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_picker = dim
	var fr: Control = _centred_frame(dim)
	var box: PanelContainer = UI.panel(fr, PICKER_RECT.size)
	box.add_theme_stylebox_override("panel", UI.style_box(Color(UI.PANEL_COLOR, 1.0), UI.PANEL_BORDER, UI.BORDER))
	box.position = PICKER_RECT.position
	box.size = PICKER_RECT.size
	var x: float = PICKER_RECT.position.x
	var w: float = PICKER_RECT.size.x
	var y: float = PICKER_RECT.position.y
	_label(fr, "WHO DOES %s TRAIN?" % legend_name(lid).to_upper(), Rect2(x, y + 4.0, w, 54), PICKER_TITLE_FONT,
			GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_label(fr, "MENTOR PERK: " + str(LegendsData.perk_of(lid).get("text", "")), Rect2(x, y + 54.0, w, 30),
			PICKER_LINE_FONT + 2, UI.TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	_label(fr, "Perks work in Road Trip games only (not in Quick Game or a Legends challenge).",
			Rect2(x, y + 86.0, w, 28), PICKER_LINE_FONT - 2, DIM_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var note: String = "One mentor per player, one pupil per legend. Switch any time."
	if not _has_trip:
		note = "NO TRIP YET: THE UNDERDOGS. The perk counts once you play the Road Trip."
	_label(fr, note, Rect2(x, y + 112.0, w, 28), PICKER_LINE_FONT - 2, WARN_COLOR if not _has_trip else DIM_TEXT,
			HORIZONTAL_ALIGNMENT_CENTER)
	_picker_scroll = ScrollContainer.new()
	_picker_scroll.position = PICK_LIST_RECT.position
	_picker_scroll.size = PICK_LIST_RECT.size
	_picker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_picker_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var bar: VScrollBar = _picker_scroll.get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(SCROLL_BAR_W, 0)
	bar.add_theme_stylebox_override("scroll", UI.style_box(UI.OPT_COLOR, UI.OPT_BORDER, 2))
	for k in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(k, UI.style_box(UI.LIT_COLOR, UI.LIT_BORDER, 2))
	fr.add_child(_picker_scroll)
	var grid := GridContainer.new()
	grid.columns = PICK_COLS
	grid.add_theme_constant_override("h_separation", TILE_GAP)
	grid.add_theme_constant_override("v_separation", TILE_GAP)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picker_scroll.add_child(grid)
	for p in _players:
		if str(p["id"]) == lid:
			continue   # a drafted legend can't train himself
		var t := PlayerTile.new()
		t.screen = self
		t.p = p
		t.card = _tile_card(str(p["sheet"]))
		t.custom_minimum_size = TILE_SIZE
		t.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(t)
		_tiles.append(t)
	var close: Button = UI.button(fr, "CLOSE", close_picker, UI.KIND_OPT, CLOSE_SIZE)
	close.position = Vector2(PICK_LIST_RECT.position.x, PICKER_BTN_Y)
	var gap: float = 20.0
	var hx: float = PICK_LIST_RECT.position.x + CLOSE_SIZE.x + gap
	var hw: float = PICK_LIST_RECT.size.x - CLOSE_SIZE.x - STOP_SIZE.x - 2.0 * gap
	var pupil: String = Legends.pupil_of(lid)
	var line: String = "Tap a player to train him."
	if pupil != "":
		line = "Now: %s. Tap another player to switch." % player_name(pupil).to_upper()
	var l: Label = _label(fr, line, Rect2(hx, PICKER_BTN_Y, hw, CLOSE_SIZE.y), PICKER_LINE_FONT, HINT_COLOR,
			HORIZONTAL_ALIGNMENT_CENTER)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.clip_text = false
	if pupil != "":
		var stop: Button = UI.button(fr, "STOP TRAINING", _on_stop, UI.KIND_MAIN, STOP_SIZE)
		stop.position = Vector2(PICK_LIST_RECT.end.x - STOP_SIZE.x, PICKER_BTN_Y)
		stop.add_theme_font_size_override("font_size", HALF_BTN_FONT)
	_picker_arm_t = PICKER_ARM_T
	_sfx("bounce", -6.0)
	_stat("hall_picker")
	print("HALL picker %s | trains %s | %d players %s" % [lid, pupil if pupil != "" else "-", _tiles.size(),
			str(player_ids())])
	var labels: PackedStringArray = PackedStringArray()
	for t in _tiles:
		var tid: String = str(t.p.get("id", ""))
		labels.append("%s: %s" % [tid, tile_status(tid, lid)])
	print("HALL picker tiles | " + ", ".join(labels))
	return true

# closes the picker (and its confirm); false when it was not open
func close_picker() -> bool:
	if _picker == null:
		return false
	_close_confirm()
	_picker.queue_free()
	_picker = null
	_picker_scroll = null
	_picker_for = ""
	_tiles = []
	_sfx("bounce", -10.0)
	return true

# a 1280 x 720 box centred in parent (an overlay's layout frame, like _frame)
func _centred_frame(parent: Control) -> Control:
	var fr := Control.new()
	fr.set_anchors_preset(Control.PRESET_CENTER)
	fr.offset_left = -FRAME_SIZE.x / 2.0
	fr.offset_top = -FRAME_SIZE.y / 2.0
	fr.offset_right = FRAME_SIZE.x / 2.0
	fr.offset_bottom = FRAME_SIZE.y / 2.0
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fr)
	return fr

# a one-line label at rect in parent (clipped)
func _label(parent: Control, text: String, rect: Rect2, fs: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: Label = UI.label(null, text, fs, col)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.clip_text = true
	(l.label_settings as LabelSettings).outline_size = 6
	parent.add_child(l)
	l.position = rect.position
	l.size = rect.size
	l.set_deferred("size", rect.size)
	return l

func _tile_card(sheet: String) -> Dictionary:
	var tries: Array = Sheets.with_base(sheet) if sheet != "" else []
	tries.append(FALLBACK_SHEET)
	return Sheets.card_first(tries)

# a tile tapped: a free player with a free legend trains at once; anything that breaks a pair asks first
func tile_tapped(pid: String) -> void:
	if _busy or _picker == null or _confirm != null or _picker_arm_t > 0.0:
		return
	var lid: String = _picker_for
	if Legends.pupil_of(lid) == pid:
		_flash("%s already trains %s." % [legend_name(lid), player_name(pid)], GOLD)
		return
	if Legends.pupil_of(lid) == "" and known_mentor(pid) == "":
		_do_assign(lid, pid)
		return
	_open_confirm([lid, pid])

func _on_stop() -> void:
	if _busy or _picker == null or _confirm != null or _picker_arm_t > 0.0:
		return
	if Legends.pupil_of(_picker_for) == "":
		return
	_open_confirm([_picker_for, ""])

# the confirm lines for a pair: [title, [lines], yes text]
func confirm_text(pair: Array) -> Array:
	var lid: String = str(pair[0])
	var pid: String = str(pair[1])
	var ln: String = legend_name(lid)
	var perk: String = str(LegendsData.perk_of(lid).get("text", ""))
	var old: String = Legends.pupil_of(lid)
	if pid == "":
		return ["STOP TRAINING?", ["%s stops training %s." % [ln, player_name(old)],
				"%s loses: %s." % [player_name(old), perk]], "YES, STOP"]
	var lines: Array = []
	if old != "" and old != pid:
		lines.append("%s stops training %s." % [ln, player_name(old)])
	var om: String = known_mentor(pid)
	if om != "" and om != lid:
		lines.append("%s leaves %s (%s then trains nobody)." % [player_name(pid), legend_name(om), legend_name(om)])
	lines.append("%s trains %s: %s." % [ln, player_name(pid), perk])
	return ["SWITCH?", lines, "YES, SWITCH"]

func _open_confirm(pair: Array) -> void:
	_confirm_pair = pair.duplicate()
	var ct: Array = confirm_text(pair)
	var dim := ColorRect.new()
	dim.color = UI.DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_confirm = dim
	var fr: Control = _centred_frame(dim)
	var box: PanelContainer = UI.panel(fr, CONFIRM_BOX)
	var sb: StyleBoxFlat = UI.style_box(Color(UI.PANEL_COLOR, 1.0), UI.LIT_COLOR, UI.BORDER)
	sb.set_content_margin_all(UI.PANEL_PAD)
	box.add_theme_stylebox_override("panel", sb)
	box.position = (FRAME_SIZE - CONFIRM_BOX) / 2.0
	box.size = CONFIRM_BOX
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(col)
	UI.label(col, str(ct[0]), UI.OPT_FONT + 6, UI.LIT_COLOR)
	for line in ct[1]:
		var l: Label = UI.label(col, str(line), CONFIRM_FONT, UI.TEXT_COLOR)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label(col, "Perks work in Road Trip games only.", CONFIRM_FONT - 4, DIM_TEXT)
	var row: HBoxContainer = UI.hbox(col)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.button(row, "NOT YET", _close_confirm, UI.KIND_OPT, CONFIRM_BTN)
	_yes = UI.button(row, str(ct[2]), _on_yes, UI.KIND_LIT, CONFIRM_BTN)
	UI.set_enabled(_yes, false)
	_confirm_t = CONFIRM_ARM_T
	_sfx("bounce", -8.0)
	print("HALL confirm %s | %s" % [str(ct[0]), " ".join(PackedStringArray(ct[1]))])

func _close_confirm() -> void:
	if _confirm == null:
		return
	_confirm.queue_free()
	_confirm = null
	_yes = null
	_confirm_t = 0.0
	_confirm_pair = []

func _on_yes() -> void:
	if _busy or _confirm == null or _confirm_t > 0.0 or _confirm_pair.size() != 2:
		return
	var pair: Array = _confirm_pair.duplicate()
	_close_confirm()
	if str(pair[1]) == "":
		var lid: String = str(pair[0])
		var old: String = Legends.pupil_of(lid)
		if Legends.release(lid):
			_stat("hall_mentor_stop")
			_sfx("bounce", -4.0)
			print("HALL mentor stop %s (was %s) | pairs %s" % [lid, old, JSON.stringify(Legends.mentors)])
			close_picker()
			_show_pick()
			_flash("%s trains nobody now." % legend_name(lid), HINT_COLOR)
		return
	_do_assign(str(pair[0]), str(pair[1]))

# Legends.assign (saved), then the picker closes and the detail shows the new pair
func _do_assign(lid: String, pid: String) -> bool:
	if not Legends.assign(lid, pid):
		push_warning("Hall: Legends.assign('%s', '%s') refused" % [lid, pid])
		_flash("%s can't train %s." % [legend_name(lid), player_name(pid)])
		return false
	_stat("hall_mentor_assign")
	_sfx("stat_up", -4.0)
	print("HALL mentor %s -> %s | perk %s | pairs %s" % [lid, pid, str(Legends.perks_for(pid).get("id", "")),
			JSON.stringify(Legends.mentors)])
	close_picker()
	if _pick != lid:
		pick(lid)
	else:
		_show_pick()
	_flash("%s now trains %s." % [legend_name(lid), player_name(pid)], GOLD)
	return true

# test drivers: train this pair as a confirmed tap would (no picker, no confirm)
func train(legend_id: String, player_id: String) -> bool:
	if _busy:
		return false
	_close_confirm()
	close_picker()
	return _do_assign(legend_id, player_id)

# the pair auto_step() assigns: the first legend who can train and trains nobody on this list, on the first listed
# player without a mentor; [] = none
func auto_pair() -> Array:
	for lid in Legends.unlocked_ids():
		var l: String = str(lid)
		if not Legends.can_mentor(l) or has_player(Legends.pupil_of(l)):
			continue
		for p in _players:
			var pid: String = str(p["id"])
			if pid != l and Legends.mentor_of(pid) == "":
				return [l, pid]
	return []

# the picker's tiles: a tap trains (tile_tapped), a drag scrolls
func tile_input(ctl: Control, event: InputEvent, st: Dictionary) -> bool:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		var tapped := false
		if mb.pressed:
			st["down"] = true
			st["drag"] = false
			st["press"] = mb.global_position
			st["last"] = mb.global_position
		elif bool(st.get("down", false)):
			st["down"] = false
			var press: Vector2 = st.get("press", mb.global_position)
			tapped = not bool(st.get("drag", false)) and mb.global_position.distance_to(press) <= TAP_SLOP
		ctl.accept_event()
		return tapped
	var mm := event as InputEventMouseMotion
	if mm != null and bool(st.get("down", false)):
		var g: Vector2 = mm.global_position
		var last: Vector2 = st.get("last", g)
		var step: Vector2 = g - last
		st["last"] = g
		var press: Vector2 = st.get("press", g)
		if step.length() > JUMP_PX:
			st["press"] = g   # the emulated mouse jumping, not a finger moving
		elif g.distance_to(press) > TAP_SLOP:
			st["drag"] = true
		if bool(st.get("drag", false)) and step.length() <= JUMP_PX and _picker_scroll != null:
			_picker_scroll.scroll_vertical -= int(step.y)
		ctl.accept_event()
	return false   # the wheel goes on to the scroll container

# ---------------------------------------------------------------------------------------------------- actions

# a tap in the list (HallList), at = list coordinates
func _on_list_tap(at: Vector2) -> void:
	if _busy or _arm_t > 0.0:
		return
	var what: String = pick_at(at)
	if what == "":
		return
	pick(what)
	if what.begins_with(CH_PICK):
		_flash("%s: COMING LATER" % str(LegendsData.chapter(what.substr(CH_PICK.length())).get("name", "")))
	elif plaque_state(what) == "locked":
		_flash("Locked: win his challenge on the LEGENDS tour.")

# P12-18: the Hall is full (the Legends mode is complete): the banner shows
static func hall_full() -> bool:
	return Legends.legends_complete()

func banner_shown() -> bool:
	return _banner != null

func _hint_default() -> String:
	return FULL_HINT if hall_full() else HINT_TEXT

func _hint_default_color() -> Color:
	return FULL_HINT_COLOR if hall_full() else HINT_COLOR

# the banner's tap: the ending (Legends.complete_scene()), then back here on the same plaque. False when the Hall is
# not full or the scene is missing
func replay_ending() -> bool:
	if _busy or _arm_t > 0.0 or _picker != null or not hall_full():
		return false
	var sc: String = Legends.complete_scene()
	if sc == "":
		return false
	_stat("hall_replay_ending")
	_sfx("bounce", -4.0)
	print("HALL replay ending %s" % sc)
	_go(STORY_SCREEN, {"scene": sc, "then": SELF_SCREEN,
			"then_args": {"back": _back, "back_args": _back_args.duplicate(true), "pick": _pick}})
	return true

# REPLAY STORY: the picked legend's unlock scene, then back here on the same plaque
func _on_replay() -> void:
	if _busy or _arm_t > 0.0:
		return
	var sc: String = replay_scene(_pick)
	if sc == "":
		return
	_stat("hall_replay_story")
	_sfx("bounce", -4.0)
	print("HALL replay story %s (%s)" % [sc, _pick])
	_go(STORY_SCREEN, {"scene": sc, "then": SELF_SCREEN,
			"then_args": {"back": _back, "back_args": _back_args.duplicate(true), "pick": _pick}})

func _on_back() -> void:
	if _busy:
		return
	_stat("hall_back")
	_go(_back, _back_args)

func _go(to: String, to_args := {}) -> void:
	_busy = true
	Flow.go(to, to_args)

# test drivers: leave the Hall (BACK); the picker and its confirm close first. Asked to train (auto_train), the
# first step assigns one pupil (auto_pair()) and the next one goes BACK.
func auto_step() -> bool:
	if _busy:
		return false
	_arm_t = 0.0
	if _picker != null:
		close_picker()
	if auto_train and not _auto_trained:
		_auto_trained = true
		var pair: Array = auto_pair()
		if not pair.is_empty() and train(str(pair[0]), str(pair[1])):
			print("HALL auto train %s -> %s" % [str(pair[0]), str(pair[1])])
			return true
		print("HALL auto train: no free legend or player")
	_on_back()
	return _busy

# ---------------------------------------------------------------------------------------------------- art

func _read_ui() -> Dictionary:
	if not FileAccess.file_exists(UI_JSON):
		return {}
	var f: FileAccess = FileAccess.open(UI_JSON, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

func _ui_rect(key: String, def: Rect2) -> Rect2:
	var v = _ui.get(key, null)
	if v is Array and (v as Array).size() == 4:
		return Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
	return def

func _frame_size() -> Vector2:
	var v = _ui.get("frame_size", null)
	if v is Array and (v as Array).size() == 2:
		return Vector2(float(v[0]), float(v[1]))
	return DEF_FRAME

func _texture(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path]
	var t: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_tex[path] = t
	return t

# the era frame of a chapter ("locked": the locked plaque); null when the file is missing (a drawn box instead)
func frame_tex(kind: String) -> Texture2D:
	var frames = _ui.get("frames", DEF_FRAMES)
	if not (frames is Dictionary):
		frames = DEF_FRAMES
	var keys: Array = [kind] if kind == "locked" else [kind, ART_BASE_CHAPTER]
	for k in keys:
		var file: String = str((frames as Dictionary).get(k, DEF_FRAMES.get(k, "")))
		var t: Texture2D = _texture(UI_DIR + file) if file != "" else null
		if t != null:
			return t
	return null

# a chapter color from ui.json's optional "colors": {"<chapter>": {"<key>": "#rrggbb"}}, else def
func chapter_color(ch: String, key: String, def: Color) -> Color:
	var cols = _ui.get("colors", {})
	var row = (cols as Dictionary).get(ch, {}) if cols is Dictionary else {}
	var s: String = str((row as Dictionary).get(key, "")) if row is Dictionary else ""
	return Color.from_string(s, def) if s != "" else def

# the drawn frame of a chapter whose frame art is missing: its crew's ui_color (legends_data.gd), else FALLBACK_FRAME
static func era_fill(ch: String) -> Color:
	var c = (LegendsData.chapter(ch).get("crew", {}) as Dictionary).get("ui_color", null)
	return (c as Color).darkened(FALLBACK_DARKEN) if c is Color else FALLBACK_FRAME

func silhouette_tex() -> Texture2D:
	return _texture(UI_DIR + str(_ui.get("silhouette", DEF_SILHOUETTE)))

# a legend's picture for the window: {"tex", "src"} (src = the part of tex to draw), {} = the silhouette.
# Sheets' chain first (his sheet's card, then the idle frame of his sheet), then his portrait.
func card_for(id: String) -> Dictionary:
	if _cards.has(id):
		return _cards[id]
	var p: Dictionary = LegendsData.legend(id)
	var out := {}
	var sheet: String = str(p.get("sheet", id))
	var info: Dictionary = Sheets.card_first(Sheets.with_base(sheet)) if sheet != "" else {}
	var tex: Texture2D = info.get("texture", null)
	if tex != null:
		var fr: Vector2 = info.get("frame", tex.get_size())
		var src := Rect2(Vector2.ZERO, fr)
		if fr == V2_CARD:
			src = _ui_rect("card_crop", DEF_CARD_CROP)
		out = {"tex": tex, "src": src, "kind": "card"}
	else:
		var pt: Texture2D = _texture(PORTRAIT_DIR + str(p.get("portrait", id)) + ".png")
		if pt != null:
			out = {"tex": pt, "src": _portrait_crop(pt.get_size()), "kind": "portrait"}
	_cards[id] = out
	return out

# the part of a portrait that fills the window (its shape, from the top, centred)
func _portrait_crop(sz: Vector2) -> Rect2:
	var win: Rect2 = _ui_rect("window", DEF_WINDOW)
	var aspect: float = win.size.x / maxf(1.0, win.size.y)
	var w: float = minf(sz.x, sz.y * aspect)
	var h: float = w / aspect
	return Rect2((sz.x - w) / 2.0, 0.0, w, h)

# A plaque at pos, scale sc, on canvas c: the frame, then the card / portrait / silhouette in its window, the name
# on the plate. state "open", "locked" (silhouette, "?") or "empty" (a locked row: no silhouette, no text).
func draw_plaque(c: CanvasItem, pos: Vector2, sc: float, id: String, state: String) -> void:
	var fs: Vector2 = _frame_size()
	var win: Rect2 = _ui_rect("window", DEF_WINDOW)
	var plate: Rect2 = _ui_rect("name_plate", DEF_PLATE)
	var open: bool = state == "open"
	var era: String = LegendsData.chapter_of(id)
	var kind: String = era if open else "locked"
	var ft: Texture2D = frame_tex(kind)
	var dest := Rect2(pos, fs * sc)
	if ft != null:
		c.draw_texture_rect(ft, dest, false)
	else:
		c.draw_style_box(UI.style_box(era_fill(era) if open else FALLBACK_LOCKED, UI.OPT_BORDER, 2), dest)
	var wr := Rect2(pos + win.position * sc, win.size * sc)
	if open:
		var card: Dictionary = card_for(id)
		if not card.is_empty():
			_draw_fit(c, card["tex"], card["src"], wr, str(card.get("kind", "")) == "card")
		else:
			_draw_silhouette(c, wr)
	elif state == "locked":
		_draw_silhouette(c, wr)
	if state == "empty":
		return
	var pr := Rect2(pos + plate.position * sc, plate.size * sc)
	var txt: String = str(LegendsData.legend(id).get("name", "?")) if open else "?"
	_plate_text(c, pr, txt, sc, chapter_color(era, "plate_text", PLATE_TEXT) if open else PLATE_LOCKED_TEXT)

# tex's src drawn into r, keeping its shape (centred; a card stands on r's bottom)
func _draw_fit(c: CanvasItem, tex: Texture2D, src: Rect2, r: Rect2, stand: bool) -> void:
	var k: float = minf(r.size.x / maxf(1.0, src.size.x), r.size.y / maxf(1.0, src.size.y))
	var sz: Vector2 = src.size * k
	var at := Vector2(r.position.x + (r.size.x - sz.x) / 2.0,
			r.end.y - sz.y if stand else r.position.y + (r.size.y - sz.y) / 2.0)
	c.draw_texture_rect_region(tex, Rect2(at, sz), src)

func _draw_silhouette(c: CanvasItem, r: Rect2) -> void:
	var st: Texture2D = silhouette_tex()
	if st != null:
		c.draw_texture_rect(st, r, false)
		return
	c.draw_circle(r.position + Vector2(r.size.x / 2.0, r.size.y * 0.24), r.size.x * 0.2, SILHOUETTE_COLOR)
	c.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.22, r.size.y * 0.38), Vector2(r.size.x * 0.56,
			r.size.y * 0.56)), SILHOUETTE_COLOR)

# one line centred on the plate, the font shrunk to fit
func _plate_text(c: CanvasItem, r: Rect2, txt: String, sc: float, col: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(PLATE_FONT_MAX * sc / 1.5)
	var min_fs: int = int(PLATE_FONT_MIN * sc / 1.5)
	while fs > min_fs and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 4.0:
		fs -= 1
	fs = mini(fs, int(r.size.y * 0.9))
	c.draw_string(font, Vector2(r.position.x, r.get_center().y + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER,
			r.size.x, fs, col)

# his best tokens: TOKEN_MAX pips centred at c
func draw_pips(c: CanvasItem, center: Vector2, id: String, r := PIP_R) -> void:
	var best: int = Legends.token_best(Legends.challenge_key(id))
	var n: int = LegendsData.TOKEN_MAX
	var step: float = r * 3.0
	var x0: float = center.x - step * (n - 1) / 2.0
	for i in n:
		var p := Vector2(x0 + step * i, center.y)
		c.draw_circle(p, r, PIP_ON if i < best else PIP_OFF)
		c.draw_arc(p, r, 0.0, TAU, 16, UI.OUTLINE_COLOR, 2.0)

static func draw_text(c: CanvasItem, pos: Vector2, text: String, fs: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	var font: Font = ThemeDB.fallback_font
	c.draw_string_outline(font, pos, text, align, w, fs, 6, UI.OUTLINE_COLOR)
	c.draw_string(font, pos, text, align, w, fs, col)


# The era rows: plaques drawn from the screen's layout; a tap picks, a drag scrolls (like lineup.gd's cards).
class HallList extends Control:
	var screen
	var _down := false
	var _drag := false
	var _press := Vector2.ZERO        # where the finger went down (screen px)
	var _press_local := Vector2.ZERO  # the same in the list
	var _last := Vector2.ZERO

	# Distances are measured from the press point, not summed from motion events: the web build can send one motion
	# with a big jump (the emulated mouse catching up with a new finger), which is not a drag.
	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_down = true
				_drag = false
				_press = mb.global_position
				_press_local = mb.position
				_last = _press
			elif _down:
				_down = false
				if not _drag and mb.global_position.distance_to(_press) <= screen.TAP_SLOP:
					screen._on_list_tap(_press_local)
			accept_event()
			return
		if mb != null and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			return   # the wheel goes on to the scroll container
		var mm := event as InputEventMouseMotion
		if mm != null and _down:
			var g: Vector2 = mm.global_position
			var step: Vector2 = g - _last
			_last = g
			if step.length() > screen.JUMP_PX:
				_press = g
				_press_local = mm.position
			elif g.distance_to(_press) > screen.TAP_SLOP:
				_drag = true
			if _drag and step.length() <= screen.JUMP_PX:
				screen._scroll.scroll_vertical -= int(step.y)
			accept_event()

	func _draw() -> void:
		var s = screen
		for r in s._rows:
			var rr: Rect2 = r["rect"]
			var built: bool = bool(r["built"])
			var chid: String = str(r["ch"])
			var row: Dictionary = s.LegendsData.chapter(chid)
			draw_style_box(s.UI.style_box(s.ROW_FILL if built else s.ROW_LOCKED_FILL,
					s.UI.PANEL_BORDER if built else s.UI.OPT_BORDER.darkened(0.4), s.UI.BORDER), rr)
			var head_y: float = rr.position.y + 29.0
			s.draw_text(self, Vector2(rr.position.x + 14.0, head_y), "CHAPTER %d  %s" % [int(r["num"]),
					str(row.get("name", chid))], s.ROW_HEAD_FONT, s.chapter_color(chid, "title", s.GOLD) if built
					else s.LOCKED_TEXT)
			var right: String = ""
			var right_col: Color = s.DIM_TEXT
			if not built:
				right = s.Legends.gate_text(chid)
				right_col = s.WARN_COLOR
			elif s.Legends.chapter_done(chid):
				right = "FINALE WON  %d/%d" % [s.Legends.chapter_tokens(chid), s.Legends.chapter_max_tokens(chid)]
				right_col = s.GOLD
			elif s.Legends.chapter_open(chid):
				right = "TOKENS %d/%d" % [s.Legends.chapter_tokens(chid), s.Legends.chapter_max_tokens(chid)]
			else:
				right = "OPENS AT " + s.Legends.gate_text(chid)
				right_col = s.WARN_COLOR
			s.draw_text(self, Vector2(rr.position.x, head_y), right, s.ROW_SUB_FONT, right_col,
					HORIZONTAL_ALIGNMENT_RIGHT, rr.size.x - 14.0)
			for q in r["plaques"]:
				var qr: Rect2 = q["rect"]
				var id: String = str(q["id"])
				if not built:
					s.draw_plaque(self, qr.position, s.LOCKED_ROW_SCALE, "", "empty")
					continue
				var st: String = s.plaque_state(id)
				s.draw_plaque(self, qr.position, s.PLAQUE_SCALE, id, st)
				if st == "open":
					s.draw_pips(self, Vector2(qr.get_center().x, qr.end.y + s.PIPS_H / 2.0 + 2.0), id)
				if id == s._pick:
					var o: Rect2 = qr.grow(s.PICK_OUT)
					draw_rect(o, s.GOLD, false, s.PICK_BORDER_W)
			if not built:
				var tx: float = rr.position.x + s.LOCKED_TEXT_X
				var tw: float = rr.size.x - s.LOCKED_TEXT_X - 14.0
				var ty: float = rr.position.y + s.ROW_HEAD_H
				s.draw_text(self, Vector2(tx, ty + 24.0), "COMING LATER", s.ROW_HEAD_FONT - 2, s.GOLD,
						HORIZONTAL_ALIGNMENT_LEFT, tw)
				var font: Font = ThemeDB.fallback_font
				var fs: int = s.ROW_SUB_FONT - 2
				var feel: String = str(row.get("feel", ""))
				var at := Vector2(tx, ty + 54.0)
				draw_multiline_string_outline(font, at, feel, HORIZONTAL_ALIGNMENT_LEFT, tw, fs, 2, 6, s.UI.OUTLINE_COLOR)
				draw_multiline_string(font, at, feel, HORIZONTAL_ALIGNMENT_LEFT, tw, fs, 2, s.DIM_TEXT)
				if s._pick == s.CH_PICK + chid:
					draw_rect(rr.grow(-2.0), s.GOLD, false, s.PICK_BORDER_W)


# The detail panel's drawn parts: the plaque at 3x, the best tokens and the rating shape (labels are children of the
# detail panel).
class DetailArt extends Control:
	var screen
	var pick := ""

	func _draw() -> void:
		var s = screen
		var at := Vector2(s.DETAIL_PAD, s.DETAIL_PAD)
		if pick.begins_with(s.CH_PICK) or pick == "":
			s.draw_plaque(self, at, s.DETAIL_SCALE, "", "empty")
			return
		var st: String = s.plaque_state(pick)
		s.draw_plaque(self, at, s.DETAIL_SCALE, pick, st)
		if st != "open":
			return
		var x: float = s.DETAIL_COL_X
		s.draw_pips(self, Vector2(x + 96.0, 170.0), pick, 8.0)
		# the rating shape: five bars around his level (the centre line), up in gold, down in blue
		var shape: Dictionary = s.LegendsData.legend(pick).get("shape", {})
		var w: float = s.DETAIL_RECT.size.x - x - s.DETAIL_PAD
		var bar_w: float = w - s.SHAPE_LABEL_W - s.SHAPE_NUM_W
		var y: float = s.SHAPE_Y
		for e in s.STAT_NAMES:
			var v: int = int(shape.get(e[0], 0))
			s.draw_text(self, Vector2(x, y + 14.0), str(e[1]), 16, s.UI.TEXT_COLOR)
			var bx: float = x + s.SHAPE_LABEL_W
			var by: float = y + (s.SHAPE_ROW - s.SHAPE_BAR_H) / 2.0
			draw_rect(Rect2(bx, by, bar_w, s.SHAPE_BAR_H), s.SHAPE_BG)
			var mid: float = bx + bar_w / 2.0
			var ln: float = bar_w / 2.0 * clampf(absf(v) / s.SHAPE_MAX, 0.0, 1.0)
			if v > 0:
				draw_rect(Rect2(mid, by, ln, s.SHAPE_BAR_H), s.SHAPE_UP)
			elif v < 0:
				draw_rect(Rect2(mid - ln, by, ln, s.SHAPE_BAR_H), s.SHAPE_DOWN)
			draw_rect(Rect2(mid - 1.0, by - 2.0, 2.0, s.SHAPE_BAR_H + 4.0), s.UI.TEXT_COLOR)
			s.draw_text(self, Vector2(bx + bar_w + 4.0, y + 14.0), ("%+d" % v) if v != 0 else "0", 16,
					s.SHAPE_UP if v > 0 else (s.SHAPE_DOWN if v < 0 else s.DIM_TEXT), HORIZONTAL_ALIGNMENT_RIGHT,
					s.SHAPE_NUM_W - 4.0)
			y += s.SHAPE_ROW


# P9-27: one of your players in the mentor picker (drawn; tap = train him, drag = scroll): his card, name, number and
# role, YOU / STARTER / BENCH, and his mentor.
class PlayerTile extends Control:
	var screen
	var p := {}
	var card: Dictionary = {}
	var _st := {}

	func _gui_input(event: InputEvent) -> void:
		if screen.tile_input(self, event, _st):
			screen.tile_tapped(str(p.get("id", "")))

	func _draw() -> void:
		var s = screen
		var id: String = str(p.get("id", ""))
		var lid: String = s._picker_for
		var mentor: String = s.known_mentor(id)
		var pupil: bool = mentor != "" and mentor == lid
		draw_style_box(s.UI.style_box(s.TILE_PUPIL_FILL if pupil else s.TILE_FILL,
				s.GOLD if pupil else s.UI.OFF_BORDER, s.TILE_PUPIL_BORDER_W if pupil else s.TILE_BORDER_W),
				Rect2(Vector2.ZERO, size))
		var pad: float = s.TILE_PAD
		var sc: float = s.TILE_SPRITE_SCALE
		var box: Vector2 = s.TILE_SHEET_BOX * sc
		var sp := Vector2(pad + 2.0, (size.y - box.y) / 2.0)
		var tex: Texture2D = card.get("texture", null)
		if tex != null:
			draw_texture_rect(tex, s.Sheets.card_rect(card, sp, sc), false)
		else:
			draw_circle(sp + Vector2(box.x / 2.0, box.y * 0.2), box.x * 0.22, s.SILHOUETTE_COLOR)
			draw_rect(Rect2(sp + Vector2(box.x * 0.22, box.y * 0.34), Vector2(box.x * 0.56, box.y * 0.6)),
					s.SILHOUETTE_COLOR)
		var x: float = sp.x + box.x + 10.0
		var w: float = size.x - x - pad
		var font: Font = ThemeDB.fallback_font
		var nm: String = str(p.get("name", id)).to_upper()
		var fs: int = s.TILE_NAME_FONT
		while fs > 14 and font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w:
			fs -= 2
		s.draw_text(self, Vector2(x, 32.0), nm, fs, s.GOLD if pupil else s.UI.TEXT_COLOR)
		var num: int = int(p.get("number", 0))
		var sub: String = (("#%d  " % num) if num > 0 else "") + str(p.get("role", "")).to_upper()
		var sfs: int = s.TILE_TEXT_FONT
		while sfs > 11 and font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x > w:
			sfs -= 1
		s.draw_text(self, Vector2(x, 54.0), sub, sfs, s.DIM_TEXT)
		var tag: String = str(p.get("tag", ""))
		if bool(p.get("legend", false)):
			tag += "  LEGEND"
		s.draw_text(self, Vector2(x, 78.0), tag, s.TILE_TEXT_FONT, s.GOLD if tag.begins_with("YOU")
				else s.UI.TEXT_COLOR)
		var st: String = s.tile_status(id, lid)
		var col: Color = s.DIM_TEXT
		if pupil:
			col = s.GOLD
		elif mentor != "":
			col = s.MENTOR_COLOR
		var mfs: int = s.MENTOR_FONT
		while mfs > 12 and font.get_string_size(st, HORIZONTAL_ALIGNMENT_LEFT, -1, mfs).x > w:
			mfs -= 1
		s.draw_text(self, Vector2(x, 106.0), st, mfs, col)


# Top-right: the legends in the Hall and the tokens.
class CountBox extends Control:
	var screen

	func _draw() -> void:
		var s = screen
		var full: bool = s.hall_full()   # P12-18: a gold border once the Hall is full
		draw_style_box(s.UI.style_box(s.UI.PANEL_COLOR, s.UI.LIT_COLOR if full else s.UI.PANEL_BORDER,
				s.BANNER_BORDER if full else s.UI.BORDER), Rect2(Vector2.ZERO, size))
		var n: int = s.Legends.unlocked_ids().size()
		var all: int = s.LegendsData.legend_ids().size()
		s.draw_text(self, Vector2(0, 44), "%d/%d" % [n, all], s.COUNT_FONT, s.GOLD, HORIZONTAL_ALIGNMENT_CENTER,
				size.x)
		s.draw_text(self, Vector2(0, 80), "LEGENDS  -  %d/%d TOKENS" % [s.Legends.tokens_total(),
				s.LegendsData.max_tokens()], s.COUNT_SUB_FONT - 4, s.UI.TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER,
				size.x)
