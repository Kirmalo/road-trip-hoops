extends CanvasLayer
# DRAFT screen (P8-16, Flow screen "draft", args {"back": "lineup"}): fill an open roster slot (stars.gd: 12 / 24 /
# 36 / 48 stars) with any player of a crew beaten on this trip, bosses too (owner Q2 a; at most one boss starts, trip.gd BOSS_LIMIT, P8-14b). Built in code
# with ui_kit.gd.
#   Header: BACK (top-left, to args.back), DRAFT, a hint / reason line, and top-right the open slots ("2 OPEN SLOTS")
#   with one pip per star slot (drafted = gold, open = blue ring, locked = grey with the stars it needs).
#   List: Trip.draft_pool_by_crew(), one section per beaten crew (a band in its colour, its name and city / New York
#   round), its players as cards: the idle card sprite in your colors (the pool's "sheet": <sheet>_crew plus the
#   jersey suffix), number and name, tier and role, a BOSS tag, and the 5 stats he would join with. The list scrolls:
#   drag anywhere on it (a drag never counts as a tap), the wide scroll bar, or the mouse wheel.
#   Tap a card to pick him (gold border), then SIGN <NAME>; a draft is final for the trip, so SIGN opens a confirm
#   panel (YES, SIGN / NOT YET). Trip.draft(id) adds him (saved). Then he says his joining line (story_text.gd
#   RECRUIT_LINES) if he has one, else a short banner, and the screen goes back to args.back.
#   With no open slot (none earned yet, or all filled) the cards still show, SIGN is off and the line says why.
#   P9-22: the LEGENDS row (Trip.draft_pool_by_crew()'s last row, "city" Trip.LEGENDS_ROW, players with "legend":
#   true): its header reads the row's "name" and the legends' chapters ("UNLOCKED IN LEGENDS - THE GRANDFATHERS"), each
#   legend's card stands in his era's card frame (assets/legends/frame_<chapter>.png, ui.json's window and card crop)
#   in your colors, with a LEGEND tag in the row's colour; picking one says only one legend can start (Trip.LEGEND_RULE).
#   P10-19: one LEGENDS row per chapter (Trip.legends_rows(), timeline order): "UNLOCKED IN LEGENDS - THE GRANDFATHERS",
#   then "... - THE FATHERS", each in its chapter's colour (band, tag) with its chapter's frame (assets/legends/ui.json
#   "frames", else frame_<chapter>.png, else LEGEND_FRAME_DEFAULT's). One legend starts, whatever his era.
# Taps are ignored for ARM_T s when the screen opens and SIGN for PICK_ARM_T s after a pick (a double tap can't
# confirm). Desktop: Escape = BACK (closes the confirm panel first; on the joining line it goes on); main.gd turns the
# Android back gesture into an Escape press. auto_step() (test drivers): draft the first card if a slot is open (no
# confirm), else go BACK.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Cities = preload("res://scripts/cities.gd")
const Stars = preload("res://scripts/stars.gd")
const Sheets = preload("res://scripts/sheets.gd")
const StoryText = preload("res://scripts/story_text.gd")   # RECRUIT_LINES: what he says when he joins (if he has one)

const ARM_T := 0.4                       # s the taps are ignored after the screen opens (a tap from the last screen)
const PICK_ARM_T := 0.25                 # s SIGN stays off after a pick
const CONFIRM_ARM_T := 0.3               # s YES stays off once the confirm panel is up (the SIGN tap can't confirm)
const JOIN_SHOW := 1.2                   # s the "joins" banner shows (no joining line) before going back
const JOIN_ARM_T := 0.8                  # s before a tap can leave the joining line
const DEFAULT_BACK := "lineup"
const FRAME_SIZE := Vector2(1280, 720)   # the layout box, centred on wider / taller screens
const BACK_POS := Vector2(16, 10)        # BACK, top-left (UI.SMALL_SIZE)
const TITLE_Y := 4.0
const HINT_RECT := Rect2(228, 74, 800, 44)   # the hint / reason line under the title
const HINT_FONT := 24
const SLOTS_RECT := Rect2(1040, 14, 226, 100)   # open slots, top-right
const SLOTS_FONT := 28
const PIP_R := 17.0                      # slot pip radius
const LIST_POS := Vector2(16, 124)       # the scrolling list
const LIST_SIZE := Vector2(1248, 470)
const SCROLL_BAR_W := 36                 # wide enough to drag with a thumb
const COLS := 6                          # cards per row (a city crew has 6 players)
const CARD_SIZE := Vector2(192, 314)     # one card (the tap target, >= UI.MIN_BUTTON)
const CARD_GAP := 10
const CREW_HEAD_H := 44.0                # px: the crew's band and name over its cards
const CREW_GAP := 18                     # px between crew sections
const CARD_PAD := 10.0
const BAND_H := 8.0                      # the crew colour band at the top of a card
const SPRITE_SCALE := 2.0                # the 40 x 64 card box (as on the recruit cards)
const SHEET_FRAME := Vector2(40, 64)     # the layout box of a card sprite (a v1 frame); Sheets.card_rect() fits v2
const FALLBACK_SHEET := "ud_jojo"        # a card with no sheet of its own
const SIGN_SIZE := Vector2(560, 110)     # the SIGN button (bottom centre)
const SIGN_Y := 604.0
const CONFIRM_BOX := Vector2(760, 330)
const CONFIRM_BTN := Vector2(300, 120)
const JOIN_BOX := Vector2(1080, 350)     # the joining line box
const JOIN_PAD := 26.0
const JOIN_PORTRAIT_SCALE := 2.4         # x PORTRAIT_BOX
const PORTRAIT_BOX := Vector2(96, 112)
const PORTRAIT_DIR := "res://assets/portraits/"
const JOIN_MOOD := "happy"
const JOIN_TITLE_FONT := 34
const JOIN_LINE_FONT := 30
const JOIN_HINT_FONT := 22
const TAP_SLOP := 14.0                   # px a finger may move and still tap (more = a scroll drag)
const JUMP_PX := 80.0                    # px: one motion longer than this is a jump of the emulated mouse, not a drag
const NAME_FONT := 22
const NUM_FONT := 26                     # "#7" on a card
const TAG_SIZE := Vector2(80, 30)        # the BOSS tag
const SMALL_FONT := 16
const HEAD_FONT := 26
const STAT_FONT := 16
const STAT_ROW := 20.0
const STAT_LABEL_W := 40.0
const STAT_NUM_W := 30.0
const STAT_BAR_H := 10.0
const STAT_BAR_BG := Color(0.25, 0.27, 0.33)
const STAT_BAR := Color(0.45, 0.65, 1.0)
const STAT_HIGH := Color(1.0, 0.82, 0.25)   # 60 and up in gold (as on the lineup)
const STAT_HIGH_AT := 60
const CARD_FILL := Color(0.1, 0.12, 0.18, 0.95)
const CARD_FILL_PICKED := Color(0.18, 0.2, 0.28, 0.98)
const CARD_BORDER_W := 3
const PICKED_BORDER_W := 8
const BOSS_FILL := Color(0.85, 0.2, 0.22)
const DIM_TEXT := Color(0.7, 0.72, 0.78)
const HINT_COLOR := Color(0.85, 0.87, 0.92)
const WARN_COLOR := Color(1.0, 0.6, 0.35)
const PIP_OPEN := Color(0.45, 0.65, 1.0)
const PIP_LOCKED := Color(0.42, 0.43, 0.5)
const TIER_TEXT := {"good": "GOOD", "boss": "BOSS", "avg": "", "start": ""}
const STAT_NAMES := [["speed", "SPD"], ["shooting", "SHT"], ["finishing", "FIN"], ["defense", "DEF"],
		["stamina", "STA"]]
# P9-22: the LEGENDS row
const LEGEND_UI_PATH := "res://assets/legends/ui.json"   # P10-19: its "frames" map names each chapter's frame file
const LEGEND_DIR := "res://assets/legends/"
const LEGEND_FRAME_PATH := "res://assets/legends/frame_%s.png"   # the era card frame per chapter id (56 x 88 texels)
const LEGEND_FRAME_DEFAULT := "grand"    # a chapter without a frame of its own uses this one
const LEGEND_FRAME_SCALE := 1.5          # px per frame texel (84 x 132 on a card, where the 80 x 128 sprite box was)
const LEGEND_WINDOW := Rect2(8, 8, 40, 60)     # texels: the frame's window (assets/legends/ui.json "window")
const LEGEND_CARD_CROP := Rect2(12, 34, 40, 60)   # px of a 64 x 96 v2 card shown in it (ui.json "card_crop")
const LEGEND_CARD_FRAME := Vector2(64, 96)     # the v2 card size the crop is for (else the card draws as usual)
const LEGEND_PLATE := Rect2(6, 72, 44, 11)     # texels: the frame's name plate (ui.json "name_plate"): his name
const LEGEND_PLATE_FONT := 12
const LEGEND_PLATE_MIN_FONT := 8         # a long name shrinks down to this on the plate
const LEGEND_PLATE_TEXT := Color(0.24, 0.14, 0.08)   # dark brown ink on the cream plate
const LEGEND_TAG_TEXT := "LEGEND"
const LEGEND_TAG_FONT := 17
const LEGEND_TAG_COLOR := Color(1.0, 0.82, 0.25)   # gold text and border on the row's colour
const LEGEND_WHERE := "UNLOCKED IN LEGENDS"     # the LEGENDS header's line (then the chapter names)
const ROLE_MIN_FONT := 12                # a long role ("no-look floor general") shrinks down to this to fit

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd
var music := "menu"

var _root: Control
var _frame: Control
var _back := DEFAULT_BACK
var _crews: Array = []       # Trip.draft_pool_by_crew()
var _cards: Array = []       # Card nodes, in list order
var _picked := ""            # the picked player id ("" = none)
var _arm_t := ARM_T
var _sign_arm_t := 0.0
var _busy := false           # signed or leaving
var _scroll: ScrollContainer
var _hint: Label
var _back_btn: Button
var _sign: Button
var _confirm: Control = null # the confirm panel (null = closed)
var _yes: Button = null
var _confirm_t := 0.0
var _leave_t := -1.0
var _join_t := -1.0          # s the joining line has been up (-1: not shown)
var _join_hint: Label
var _ui_cache = null         # P10-19: assets/legends/ui.json (_legend_ui(); null = not read yet)

func _ready() -> void:
	_back = str(Flow.args.get("back", DEFAULT_BACK))
	if _back == "" or _back == "draft" or (_back != Flow.GAME and not Flow.SCREENS.has(_back)):
		_back = DEFAULT_BACK
	_crews = Trip.draft_pool_by_crew()
	_root = UI.screen_root(self)
	_frame = Control.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.offset_left = -FRAME_SIZE.x / 2.0
	_frame.offset_top = -FRAME_SIZE.y / 2.0
	_frame.offset_right = FRAME_SIZE.x / 2.0
	_frame.offset_bottom = FRAME_SIZE.y / 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frame)
	_build()
	_refresh()
	_stat("draft_screen")
	print("DRAFT screen | %d crews, %d players | slots %d, open %d, drafted %s | back %s" % [_crews.size(),
			_cards.size(), Trip.slot_count(), Trip.open_slots(), str(Trip.drafted_ids()), _back])

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_refresh()
	if _sign_arm_t > 0.0:
		_sign_arm_t -= delta
		if _sign_arm_t <= 0.0:
			_refresh()
	if _confirm_t > 0.0:
		_confirm_t -= delta
		if _confirm_t <= 0.0 and _yes != null:
			UI.set_enabled(_yes, true)
	if _leave_t > 0.0:
		_leave_t -= delta
		if _leave_t <= 0.0:
			Flow.go(_back)
	if _join_t >= 0.0:
		_join_t += delta
		if _join_hint != null:
			_join_hint.visible = _join_t >= JOIN_ARM_T

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _join_t >= 0.0:
			_join_done()
		elif _confirm != null:
			_close_confirm()
		else:
			_on_back()

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

func _sfx(sfx_name: String, db := 0.0) -> void:
	if audio != null:
		audio.play(sfx_name, db)

# ---------------- building ----------------

func _build() -> void:
	_back_btn = UI.button(_frame, "BACK", _on_back, UI.KIND_OPT, UI.SMALL_SIZE)
	_back_btn.position = BACK_POS
	var head := VBoxContainer.new()
	head.position = Vector2(0, TITLE_Y)
	head.size = Vector2(FRAME_SIZE.x, 64)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(head)
	UI.title(head, "DRAFT")
	_hint = UI.label(_frame, "", HINT_FONT, HINT_COLOR)
	_hint.position = HINT_RECT.position
	_hint.size = HINT_RECT.size
	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hint.clip_text = true
	var sl := SlotsArt.new()
	sl.screen = self
	sl.position = SLOTS_RECT.position
	sl.size = SLOTS_RECT.size
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(sl)
	if _crews.is_empty():
		_build_nobody()
	else:
		_build_list()
	_sign = UI.button(_frame, "TAP A PLAYER", _on_sign, UI.KIND_LIT, SIGN_SIZE)
	_sign.position = Vector2((FRAME_SIZE.x - SIGN_SIZE.x) / 2.0, SIGN_Y)

func _build_nobody() -> void:
	var p := UI.panel(_frame, Vector2(900, 220))
	p.position = Vector2((FRAME_SIZE.x - 900.0) / 2.0, LIST_POS.y + 100.0)
	p.size = Vector2(900, 220)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(col)
	UI.label(col, "NOBODY TO DRAFT YET", UI.OPT_FONT, UI.LIT_COLOR)
	var why: String = "Beat a crew on this trip: its players can join you here." if Trip.active \
			else "Start a Road Trip: beaten crews' players can join you here."
	var l := UI.label(col, why, UI.SUB_FONT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_list() -> void:
	_scroll = ScrollContainer.new()
	_scroll.position = LIST_POS
	_scroll.size = LIST_SIZE
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(SCROLL_BAR_W, 0)
	bar.add_theme_stylebox_override("scroll", UI.style_box(UI.OPT_COLOR, UI.OPT_BORDER, 2))
	for k in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(k, UI.style_box(UI.LIT_COLOR, UI.LIT_BORDER, 2))
	_frame.add_child(_scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", CREW_GAP)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(col)
	for row in _crews:
		var crew: Dictionary = row
		var color: Color = _color_of(crew)
		var hd := CrewHead.new()
		hd.screen = self
		hd.title = str(crew.get("name", crew.get("city", ""))).to_upper()
		hd.where = _where(crew)
		hd.color = color
		hd.count = (crew.get("players", []) as Array).size()
		hd.custom_minimum_size = Vector2(LIST_SIZE.x - SCROLL_BAR_W - 8.0, CREW_HEAD_H)
		hd.mouse_filter = Control.MOUSE_FILTER_STOP   # a drag on the header scrolls too
		col.add_child(hd)
		var grid := GridContainer.new()
		grid.columns = COLS
		grid.add_theme_constant_override("h_separation", CARD_GAP)
		grid.add_theme_constant_override("v_separation", CARD_GAP)
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(grid)
		for pl in crew.get("players", []):
			var c := Card.new()
			c.screen = self
			c.p = pl
			c.color = color
			c.card = _card_of(str((pl as Dictionary).get("sheet", "")))
			if bool((pl as Dictionary).get("legend", false)):
				var lch: String = str((pl as Dictionary).get("chapter", ""))
				c.frame = _legend_frame(lch)
				c.plate_color = _plate_color(lch)
				c.legend = true
			c.custom_minimum_size = CARD_SIZE
			c.mouse_filter = Control.MOUSE_FILTER_STOP
			grid.add_child(c)
			_cards.append(c)

func _color_of(crew: Dictionary) -> Color:
	var c = crew.get("color", UI.OPT_COLOR)
	return c if c is Color else UI.OPT_COLOR

# "CHICAGO" for a city crew, "NEW YORK - ROUND 2" for a bracket crew, "UNLOCKED IN LEGENDS - THE GRANDFATHERS" for
# a LEGENDS row (P9-22; P10-19: the row's "chapter", else its legends' chapters)
func _where(crew: Dictionary) -> String:
	if str(crew.get("city", "")) == Trip.LEGENDS_ROW:
		var chs: Array = []
		var row_ch: String = str(Trip.LegendsData.chapter(str(crew.get("chapter", ""))).get("name", "")).to_upper()
		if row_ch != "":
			chs.append(row_ch)
		for pl in ([] if row_ch != "" else crew.get("players", [])):
			var ch: String = str(Trip.LegendsData.chapter(str((pl as Dictionary).get("chapter", ""))).get("name", ""))
			if ch != "" and not chs.has(ch.to_upper()):
				chs.append(ch.to_upper())
		return LEGEND_WHERE + ("" if chs.is_empty() else " - " + ", ".join(PackedStringArray(chs)))
	var city_name: String = str(Cities.city(str(crew.get("city", ""))).get("name", str(crew.get("city", "")))).to_upper()
	var rd: int = int(crew.get("round", 0))
	return city_name if rd <= 0 else "%s - ROUND %d" % [city_name, rd]

# his card in your colors (the sheet, its base sheets, then a fallback); {} = a silhouette
func _card_of(sheet: String) -> Dictionary:
	var tries: Array = Sheets.with_base(sheet) if sheet != "" else []
	tries.append(FALLBACK_SHEET)
	return Sheets.card_first(tries)

# P9-22: the era card frame of a chapter (its own, else the default one; null = none, the card draws as usual).
# P10-19: ui.json's "frames" entry for the chapter first, then frame_<chapter>.png.
func _legend_frame(chapter: String) -> Texture2D:
	var frames = _legend_ui().get("frames", {})
	for ch in [chapter, LEGEND_FRAME_DEFAULT]:
		if str(ch) == "":
			continue
		var paths: Array = []
		if frames is Dictionary and str((frames as Dictionary).get(str(ch), "")) != "":
			paths.append(LEGEND_DIR + str((frames as Dictionary)[str(ch)]).get_file())
		paths.append(LEGEND_FRAME_PATH % str(ch))
		for path in paths:
			if ResourceLoader.exists(str(path)):
				var tex: Texture2D = load(str(path)) as Texture2D
				if tex != null:
					return tex
	return null

# P10-19: the name plate ink of a chapter's frame: ui.json's optional "colors": {"<chapter>": {"plate_text":
# "#rrggbb"}} (as hall.gd reads it), else LEGEND_PLATE_TEXT
func _plate_color(chapter: String) -> Color:
	var cols = _legend_ui().get("colors", {})
	var row = (cols as Dictionary).get(chapter, {}) if cols is Dictionary else {}
	var hex: String = str((row as Dictionary).get("plate_text", "")) if row is Dictionary else ""
	return Color.from_string(hex, LEGEND_PLATE_TEXT) if hex != "" else LEGEND_PLATE_TEXT

# assets/legends/ui.json, read once ({} when missing or broken)
func _legend_ui() -> Dictionary:
	if _ui_cache == null:
		_ui_cache = {}
		if FileAccess.file_exists(LEGEND_UI_PATH):
			var got = JSON.parse_string(FileAccess.get_file_as_string(LEGEND_UI_PATH))
			if got is Dictionary:
				_ui_cache = got
	return _ui_cache as Dictionary

# ---------------- state ----------------

func _player(id: String) -> Dictionary:
	for c in _cards:
		if str((c as Card).p.get("id", "")) == id:
			return (c as Card).p
	return {}

# the stars the next star slot opens at (0 = every slot is open)
static func next_slot_at() -> int:
	var t: int = Stars.total()
	for r in Stars.REWARDS:
		if str(r["kind"]) == "slot" and int(r["at"]) > t:
			return int(r["at"])
	return 0

# why SIGN is off for every card ("" = a slot is open)
func _slot_reason() -> String:
	if not Trip.active:
		return "No Road Trip going: start one to draft players."
	if Trip.open_slots() > 0:
		return ""
	var at: int = next_slot_at()
	var n: int = Trip.slot_count()
	if n == 0:
		return "NO OPEN SLOT: the first opens at %d stars (you have %d)." % [at, Stars.total()]
	if at > 0:
		return "ALL %d SLOTS FILLED: the next opens at %d stars (you have %d)." % [n, at, Stars.total()]
	return "ALL %d SLOTS FILLED for this trip." % n

func _refresh() -> void:
	var armed: bool = _arm_t <= 0.0 and not _busy and _confirm == null
	UI.set_enabled(_back_btn, not _busy and _confirm == null)
	var reason: String = _slot_reason()
	if _crews.is_empty():
		_hint.text = reason if reason != "" else "Nobody to draft yet."
		_hint.label_settings.font_color = HINT_COLOR
		_sign.text = "NOBODY TO DRAFT"
		UI.set_enabled(_sign, false)
	elif reason != "":
		_hint.text = reason
		_hint.label_settings.font_color = WARN_COLOR
		_sign.text = "NO OPEN SLOT"
		UI.set_enabled(_sign, false)
	else:
		_hint.label_settings.font_color = HINT_COLOR
		if _picked == "":
			_hint.text = "Tap a player, then SIGN. A draft is final for this trip."
			_sign.text = "TAP A PLAYER"
		else:
			var p: Dictionary = _player(_picked)
			if bool(p.get("legend", false)):
				_hint.text = "%s joins at these stats. %s." % [str(p.get("name", _picked)), Trip.LEGEND_RULE]
			else:
				_hint.text = "%s joins at these stats, with 0 points. Final for this trip." % str(p.get("name", _picked))
			_sign.text = "SIGN " + str(p.get("name", _picked)).to_upper()
		UI.set_enabled(_sign, armed and _picked != "" and _sign_arm_t <= 0.0)
	for c in _cards:
		(c as Control).queue_redraw()

func is_picked(id: String) -> bool:
	return id != "" and id == _picked

# ---------------- taps ----------------

# a tap on a card (Card._gui_input)
func card_tapped(id: String) -> void:
	if _busy or _arm_t > 0.0 or _confirm != null:
		return
	if id == _picked:
		return
	_picked = id
	_sign_arm_t = PICK_ARM_T
	_sfx("bounce", -8.0)
	_stat("draft_pick")
	_refresh()

func _on_sign() -> void:
	if _busy or _arm_t > 0.0 or _sign_arm_t > 0.0 or _picked == "" or _confirm != null:
		return
	if not Trip.can_draft(_picked):
		_hint.text = "Can't sign him: %s." % Trip.draft_refusal(_picked)
		_hint.label_settings.font_color = WARN_COLOR
		return
	_open_confirm()

# The confirm panel: a draft is final, so SIGN asks once more (YES, SIGN arms after CONFIRM_ARM_T).
func _open_confirm() -> void:
	var p: Dictionary = _player(_picked)
	var dim := ColorRect.new()
	dim.color = UI.DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_confirm = dim
	var frame := _layout_frame(dim)
	var box := UI.panel(frame, CONFIRM_BOX)
	box.position = (FRAME_SIZE - CONFIRM_BOX) / 2.0
	box.size = CONFIRM_BOX
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 16)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(col)
	var t := UI.label(col, "SIGN %s?" % str(p.get("full", p.get("name", _picked))).to_upper(), UI.OPT_FONT, UI.LIT_COLOR)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var left: int = Trip.open_slots() - 1
	var sub: String = "A draft is final for this trip. %s" % ("%d open slot%s left after him." % [left,
			"" if left == 1 else "s"] if left > 0 else "He fills your last open slot.")
	var l := UI.label(col, sub, HINT_FONT, HINT_COLOR)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := UI.hbox(col)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.button(row, "NOT YET", _close_confirm, UI.KIND_OPT, CONFIRM_BTN)
	_yes = UI.button(row, "YES, SIGN", _on_yes, UI.KIND_LIT, CONFIRM_BTN)
	UI.set_enabled(_yes, false)
	_confirm_t = CONFIRM_ARM_T
	_sfx("bounce", -8.0)
	_refresh()

func _close_confirm() -> void:
	if _confirm == null or _busy:
		return
	_confirm.queue_free()
	_confirm = null
	_yes = null
	_confirm_t = 0.0
	_sfx("bounce", -10.0)
	_refresh()

func _on_yes() -> void:
	if _busy or _confirm == null or _confirm_t > 0.0:
		return
	_confirm.queue_free()
	_confirm = null
	_yes = null
	_sign_now(_picked)

# Trip.draft(id) (saved), then his joining line or the banner, then back. False if the trip refused him.
func _sign_now(id: String) -> bool:
	var p: Dictionary = _player(id)
	if not Trip.draft(id):
		push_warning("Draft: Trip.draft('%s') refused: %s" % [id, Trip.draft_refusal(id)])
		_refresh()
		return false
	_busy = true
	_stat("draft_signed")
	_stat("draft_" + id)
	_refresh()
	_sfx("swish")
	_sfx("crowd", -10.0)
	var title: String = "%s JOINS THE %s!" % [str(p.get("full", p.get("name", id))).to_upper(), Cities.CREW_NAME]
	var line: String = StoryText.recruit_line(id)
	if line != "":
		_join_line(id, title, line)
		_stat("draft_line")
	else:
		_banner(title)
		_leave_t = JOIN_SHOW
	return true

func _on_back() -> void:
	if _busy or _confirm != null:
		return
	_busy = true
	_refresh()
	_sfx("bounce", -8.0)
	Flow.go(_back)

# the 1280 x 720 layout box inside `parent`, centred like _frame
func _layout_frame(parent: Control) -> Control:
	var frame := Control.new()
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -FRAME_SIZE.x / 2.0
	frame.offset_top = -FRAME_SIZE.y / 2.0
	frame.offset_right = FRAME_SIZE.x / 2.0
	frame.offset_bottom = FRAME_SIZE.y / 2.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	return frame

func _banner(text: String) -> void:
	var dim := ColorRect.new()
	dim.color = UI.DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	var box := UI.vbox(dim)
	var p := UI.panel(box)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UI.label(p, text, UI.BUTTON_FONT, UI.LIT_COLOR)

# His joining line (as on the recruit screen): his portrait (happy if drawn), the JOINS title and the line; a tap
# anywhere after JOIN_ARM_T goes back.
func _join_line(id: String, title: String, line: String) -> void:
	var dim := ColorRect.new()
	dim.color = UI.DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_join_input.bind(dim))
	_root.add_child(dim)
	var frame := _layout_frame(dim)
	var box := UI.panel(frame, JOIN_BOX)
	box.position = (FRAME_SIZE - JOIN_BOX) / 2.0
	box.size = JOIN_BOX
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(JOIN_PAD))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var por: Texture2D = _join_portrait(id)
	if por != null:
		var tr := TextureRect.new()
		tr.texture = por
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		tr.custom_minimum_size = PORTRAIT_BOX * JOIN_PORTRAIT_SCALE
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tr)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var t := UI.label(col, title, JOIN_TITLE_FONT, UI.LIT_COLOR)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var said := UI.label(col, "\"%s\"" % _fill(line), JOIN_LINE_FONT)
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	said.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	said.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_join_hint = UI.label(col, "TAP TO GO ON", JOIN_HINT_FONT, DIM_TEXT)
	_join_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_join_hint.visible = false
	_join_t = 0.0

func _on_join_input(event: InputEvent, dim: Control) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		dim.accept_event()
		_join_done()

# leave (once the line has been up JOIN_ARM_T); false if it can't yet
func _join_done() -> bool:
	if _join_t < JOIN_ARM_T:
		return false
	_join_t = -1.0
	_sfx("bounce", -8.0)
	Flow.go(_back)
	return true

# {crew} and {van} as in story.gd
func _fill(s: String) -> String:
	return s.replace("{crew}", Cities.CREW_NAME.capitalize()).replace("{van}", Cities.VAN_NAME.capitalize())

func _join_portrait(id: String) -> Texture2D:
	var base: String = PORTRAIT_DIR + str(Cities.player(id).get("portrait", id))
	for path in [base + "_" + JOIN_MOOD + ".png", base + ".png"]:
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				return tex
	return null

# ---------------- scrolling (a drag on a card or a crew header) ----------------

# Shared by Card and CrewHead: true when this event finished a tap (not a drag). Distances are measured from the
# press point on the screen: the web build can send one motion with a big jump, which is not a drag.
func drag_input(ctl: Control, event: InputEvent, st: Dictionary) -> bool:
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
			st["press"] = g   # a jump, not a finger moving: start measuring again from here
		elif g.distance_to(press) > TAP_SLOP:
			st["drag"] = true
		if bool(st.get("drag", false)) and step.length() <= JUMP_PX and _scroll != null:
			_scroll.scroll_vertical -= int(step.y)
		ctl.accept_event()
	return false   # the wheel goes on to the scroll container

# ---------------- test drivers ----------------

# The default choice: draft the first card when a slot is open (no confirm), else go BACK. On the joining line: tap
# through it. False while there is nothing to do (the line arming, the banner counting down).
func auto_step() -> bool:
	if _busy:
		return _join_t >= 0.0 and _join_done()
	_arm_t = 0.0
	_sign_arm_t = 0.0
	if _confirm != null:
		_confirm.queue_free()
		_confirm = null
		_yes = null
	if Trip.open_slots() > 0 and not _cards.is_empty():
		var id: String = str((_cards[0] as Card).p.get("id", ""))
		_picked = id
		if _sign_now(id):
			return true
	_on_back()
	return true

# test drivers: pick a card by id as a tap would (true if he is on the screen)
func tap_player(id: String) -> bool:
	if _player(id).is_empty():
		return false
	_arm_t = 0.0
	card_tapped(id)
	return true

# ---------------- drawing helpers ----------------

# the font size (fs, or smaller down to lo) that fits `text` in max_w px on one line
static func fit_size(text: String, fs: int, max_w: float, lo: int = ROLE_MIN_FONT) -> int:
	var font: Font = ThemeDB.fallback_font
	var n: int = fs
	while n > lo and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, n).x + 12.0 > max_w:
		n -= 1
	return n

static func draw_text(c: CanvasItem, pos: Vector2, text: String, fs: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	var font: Font = ThemeDB.fallback_font
	c.draw_string_outline(font, pos, text, align, w, fs, 6, UI.OUTLINE_COLOR)
	c.draw_string(font, pos, text, align, w, fs, col)

static func draw_sprite(c: CanvasItem, card: Dictionary, pos: Vector2, sc: float, fallback: Color) -> void:
	var sz: Vector2 = SHEET_FRAME * sc
	var tex: Texture2D = card.get("texture", null)
	if tex != null:
		c.draw_texture_rect(tex, Sheets.card_rect(card, pos, sc), false)
	else:
		c.draw_circle(pos + Vector2(sz.x / 2.0, sz.y * 0.2), sz.x * 0.22, fallback)
		c.draw_rect(Rect2(pos + Vector2(sz.x * 0.22, sz.y * 0.34), Vector2(sz.x * 0.56, sz.y * 0.6)), fallback)

# a small padlock centred at c (h = body height)
static func padlock(ci: CanvasItem, c: Vector2, h: float, color: Color) -> void:
	var w: float = h * 1.25
	ci.draw_arc(c + Vector2(0, -h * 0.45), w * 0.32, PI, TAU, 12, color, maxf(2.0, h * 0.18))
	ci.draw_rect(Rect2(c + Vector2(-w / 2.0, -h * 0.45), Vector2(w, h)), color)


# ---------------- one player card (drawn; tap = pick, drag = scroll) ----------------

class Card extends Control:
	var screen               # draft.gd
	var p := {}
	var color := Color.GRAY  # his old crew's colour (the band)
	var card: Dictionary = {}   # Sheets.card_info() in your colors
	var frame: Texture2D = null   # P9-22: a legend's era card frame (null = none)
	var legend := false        # P9-22: a legend (the LEGEND tag)
	var plate_color := Color(0.24, 0.14, 0.08)   # P10-19: his frame's name plate ink (_plate_color())
	var _st := {}

	func _gui_input(event: InputEvent) -> void:
		if screen.drag_input(self, event, _st):
			screen.card_tapped(str(p.get("id", "")))

	func _draw() -> void:
		var s = screen
		var id: String = str(p.get("id", ""))
		var picked: bool = s.is_picked(id)
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(s.UI.style_box(s.CARD_FILL_PICKED if picked else s.CARD_FILL,
				s.UI.LIT_COLOR if picked else s.UI.OFF_BORDER, s.PICKED_BORDER_W if picked else s.CARD_BORDER_W), r)
		var pad: float = s.CARD_PAD
		var w: float = size.x
		draw_rect(Rect2(pad, pad, w - pad * 2.0, s.BAND_H), color)
		# the sprite (left); number, GOOD / BOSS tag and PICKED (right)
		var sc: float = s.SPRITE_SCALE
		var spr: Vector2 = s.SHEET_FRAME * sc
		var sp := Vector2(pad + 4.0, pad + s.BAND_H + 4.0)
		var box_w: float = spr.x
		if frame != null:
			box_w = maxf(box_w, _draw_framed(sp).x)
		else:
			s.draw_sprite(self, card, sp, sc, s.UI.OFF_COLOR)
		var x: float = sp.x + box_w + 6.0
		var tw: float = w - x - pad
		var num: int = int(p.get("number", 0))
		if num > 0:
			s.draw_text(self, Vector2(x, sp.y + 34.0), "#%d" % num, s.NUM_FONT, s.DIM_TEXT, HORIZONTAL_ALIGNMENT_CENTER, tw)
		var boss: bool = bool(p.get("boss", false))
		var tier: String = str(s.TIER_TEXT.get(str(p.get("tier", "")), ""))
		if legend:
			var lw: float = minf(tw, s.TAG_SIZE.x)
			var lr := Rect2(x + (tw - lw) / 2.0, sp.y + 52.0, lw, s.TAG_SIZE.y)
			draw_style_box(s.UI.style_box(color, s.LEGEND_TAG_COLOR, 2), lr)
			s.draw_text(self, Vector2(lr.position.x, lr.position.y + 21.0), s.LEGEND_TAG_TEXT, s.LEGEND_TAG_FONT,
					s.LEGEND_TAG_COLOR, HORIZONTAL_ALIGNMENT_CENTER, lr.size.x)
		elif boss:
			var br := Rect2(x + (tw - s.TAG_SIZE.x) / 2.0, sp.y + 52.0, s.TAG_SIZE.x, s.TAG_SIZE.y)
			draw_style_box(s.UI.style_box(s.BOSS_FILL, s.UI.LIT_BORDER, 2), br)
			s.draw_text(self, Vector2(br.position.x, br.position.y + 22.0), "BOSS", 20, s.UI.TEXT_COLOR,
					HORIZONTAL_ALIGNMENT_CENTER, br.size.x)
		elif tier != "":
			s.draw_text(self, Vector2(x, sp.y + 74.0), tier, s.SMALL_FONT + 4, s.STAT_HIGH, HORIZONTAL_ALIGNMENT_CENTER, tw)
		if picked:
			s.draw_text(self, Vector2(x, sp.y + spr.y - 8.0), "PICKED", s.SMALL_FONT + 2, s.UI.LIT_COLOR,
					HORIZONTAL_ALIGNMENT_CENTER, tw)
		# the name and role, full width
		var y: float = sp.y + spr.y + 24.0
		s.draw_text(self, Vector2(pad, y), str(p.get("name", id)).to_upper(), s.NAME_FONT,
				s.UI.LIT_COLOR if picked else s.UI.TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, w - pad * 2.0)
		y += 22.0
		var role: String = str(p.get("role", "")).to_upper()
		s.draw_text(self, Vector2(pad, y), role, s.fit_size(role, s.SMALL_FONT, w - pad * 2.0), s.DIM_TEXT,
				HORIZONTAL_ALIGNMENT_CENTER, w - pad * 2.0)
		y += 8.0
		# the 5 stats he joins with
		var rt: Dictionary = p.get("ratings", {})
		var bx: float = pad + s.STAT_LABEL_W
		var bar_w: float = w - bx - pad - s.STAT_NUM_W
		for e in s.STAT_NAMES:
			var v: int = int(rt.get(e[0], 0))
			s.draw_text(self, Vector2(pad + 2.0, y + 15.0), str(e[1]), s.STAT_FONT, s.UI.TEXT_COLOR)
			var by: float = y + (s.STAT_ROW - s.STAT_BAR_H) / 2.0
			draw_rect(Rect2(bx, by, bar_w, s.STAT_BAR_H), s.STAT_BAR_BG)
			var col: Color = s.STAT_HIGH if v >= s.STAT_HIGH_AT else s.STAT_BAR
			draw_rect(Rect2(bx, by, bar_w * clampf(v / 100.0, 0.0, 1.0), s.STAT_BAR_H), col)
			s.draw_text(self, Vector2(bx + bar_w, y + 15.0), str(v), s.STAT_FONT, s.UI.TEXT_COLOR,
					HORIZONTAL_ALIGNMENT_RIGHT, s.STAT_NUM_W)
			y += s.STAT_ROW

	# P9-22: the era frame at `at` with his card's crop in its window; returns the frame's size on the card
	func _draw_framed(at: Vector2) -> Vector2:
		var s = screen
		var k: float = s.LEGEND_FRAME_SCALE
		var fsz: Vector2 = frame.get_size() * k
		draw_texture_rect(frame, Rect2(at, fsz), false)
		var win := Rect2(at + s.LEGEND_WINDOW.position * k, s.LEGEND_WINDOW.size * k)
		var tex: Texture2D = card.get("texture", null)
		if tex != null and tex.get_size() == s.LEGEND_CARD_FRAME:
			draw_texture_rect_region(tex, win, s.LEGEND_CARD_CROP)
		elif tex != null:
			draw_texture_rect(tex, Rect2(win.position, win.size), false)
		var plate := Rect2(at + s.LEGEND_PLATE.position * k, s.LEGEND_PLATE.size * k)
		var nm: String = str(p.get("name", "")).to_upper()
		var fs: int = s.fit_size(nm, s.LEGEND_PLATE_FONT, plate.size.x + 8.0, s.LEGEND_PLATE_MIN_FONT)
		draw_string(ThemeDB.fallback_font, Vector2(plate.position.x, plate.get_center().y + fs * 0.36), nm,
				HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, fs, plate_color)
		return fsz


# ---------------- a crew's header in the list (its colour, name and city; drag = scroll) ----------------

class CrewHead extends Control:
	var screen
	var title := ""
	var where := ""
	var color := Color.GRAY
	var count := 0
	var _st := {}

	func _gui_input(event: InputEvent) -> void:
		screen.drag_input(self, event, _st)

	func _draw() -> void:
		var s = screen
		var h: float = size.y
		draw_rect(Rect2(0, 6.0, 14.0, h - 12.0), color)
		draw_rect(Rect2(14.0, h - 6.0, size.x - 14.0, 3.0), Color(color, 0.7))
		var font: Font = ThemeDB.fallback_font
		var tw: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, s.HEAD_FONT).x
		s.draw_text(self, Vector2(26.0, h - 14.0), title, s.HEAD_FONT, s.UI.TEXT_COLOR)
		s.draw_text(self, Vector2(26.0 + tw + 20.0, h - 14.0), where, s.SMALL_FONT + 2, s.DIM_TEXT)
		s.draw_text(self, Vector2(0, h - 14.0), "%d TO DRAFT" % count, s.SMALL_FONT + 2, s.DIM_TEXT,
				HORIZONTAL_ALIGNMENT_RIGHT, size.x - 8.0)


# ---------------- the open slots (top-right): "2 OPEN SLOTS" and one pip per star slot ----------------

class SlotsArt extends Control:
	var screen               # draft.gd

	func _draw() -> void:
		var s = screen
		var open: int = Trip.open_slots()
		var have: int = Trip.slot_count()
		var drafted: int = mini(Trip.drafted_ids().size(), have)
		var txt: String = "%d OPEN SLOT%s" % [open, "" if open == 1 else "S"]
		s.draw_text(self, Vector2(0, 30), txt, SLOTS_FONT, UI.LIT_COLOR if open > 0 else DIM_TEXT,
				HORIZONTAL_ALIGNMENT_RIGHT, size.x)
		var n: int = 0
		for r in Stars.REWARDS:
			if str(r["kind"]) == "slot":
				n += 1
		var gap: float = PIP_R * 2.0 + 14.0
		var x0: float = size.x - PIP_R - (n - 1) * gap
		var y: float = 62.0
		var i: int = 0
		for r in Stars.REWARDS:
			if str(r["kind"]) != "slot":
				continue
			var c := Vector2(x0 + i * gap, y)
			if i < drafted:
				draw_circle(c, PIP_R, UI.LIT_COLOR)
				draw_arc(c, PIP_R, 0.0, TAU, 24, UI.LIT_BORDER, 2.0)
			elif i < have:
				draw_circle(c, PIP_R, Color(0.1, 0.12, 0.18))
				draw_arc(c, PIP_R - 1.0, 0.0, TAU, 24, PIP_OPEN, 4.0)
			else:
				draw_circle(c, PIP_R, Color(0.12, 0.12, 0.15))
				s.padlock(self, c + Vector2(0, 3.0), 12.0, PIP_LOCKED)
				s.draw_text(self, Vector2(c.x - PIP_R - 6.0, c.y + PIP_R + 18.0), str(int(r["at"])), 16, DIM_TEXT,
						HORIZONTAL_ALIGNMENT_CENTER, PIP_R * 2.0 + 12.0)
			i += 1
