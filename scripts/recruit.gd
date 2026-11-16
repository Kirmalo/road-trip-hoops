extends CanvasLayer
# Recruit screen (P5-13, Flow screen "recruit"): after beating a city's crew you pick ONE of its 3 recruitable
# players (its 2 good players or the boss, owner rule) to join your bench. Built in code with ui_kit.gd.
#   Each candidate is a big card: his portrait (if the file exists), his idle sprite in the city's colors and, next to
#   it, the same sprite in your blue and gold (<sheet>_crew.png, owner Q11 a: recruits switch to your colors), his
#   name, role, tier, specialty and the 5 ratings he would join with (Trip.recruit_candidates()).
#   Tap a card to pick him (the card lights gold), then tap SIGN <NAME> to confirm. There is no SKIP or BACK, the
#   screen ignores taps for ARM_T s when it opens and SIGN for PICK_ARM_T s after a pick, so it can't be skipped or
#   confirmed by accident. Trip.recruit(id) adds him (saved) and moves the trip to the next city; then the map.
# Touch only (Escape does nothing here on purpose). auto_step() (trip test) signs the first candidate.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Cities = preload("res://scripts/cities.gd")

const ARM_T := 0.5                       # s the screen ignores taps after it opens (a tap from the last screen)
const PICK_ARM_T := 0.25                 # s SIGN stays off after a pick (a double tap on a card can't confirm)
const JOIN_SHOW := 1.2                   # s the "joins the crew" banner shows before the map
const FRAME_SIZE := Vector2(1280, 720)   # the layout box, centred on wider / taller screens
const HEAD_TOP := 6.0                    # px: the title
const CARD_TOP := 136.0                  # px: top of the cards
const CARD_SIZE := Vector2(392, 450)     # one candidate card (the tap target)
const CARD_GAP := 24.0                   # px between cards
const CARD_PAD := 14.0                   # inner padding
const SIGN_SIZE := Vector2(560, 110)     # the confirm button
const SIGN_Y := 600.0                    # px: top of the confirm button
const CARD_FILL := Color(0.1, 0.12, 0.18, 0.95)
const CARD_FILL_PICKED := Color(0.17, 0.18, 0.24, 0.98)
const CARD_BORDER_W := 3
const PICKED_BORDER_W := 9
const BAND_H := 10.0                     # the crew-colour band at the top of a card
const ART_H := 164.0                     # px: the portrait / sprite row
const PORTRAIT_SCALE := 1.45             # portraits are 96 x 112 source px
const SPRITE_SCALE := 2.0                # idle frame 40 x 64 source px
const SPRITE_SCALE_ALONE := 2.5          # no portrait: bigger sprites
const SHEET_FRAME := Vector2(40, 64)     # player.gd SHEET_FRAME; the idle frame facing the camera is column 0, row 0
const SHEET_SIZE := Vector2(1480, 320)   # a full sheet (37 x 5 frames); anything else is drawn as a silhouette
const SHEET_DIR := "res://assets/players/"
const PORTRAIT_DIR := "res://assets/portraits/"
const NAME_FONT := 30
const SMALL_FONT := 20
const STAT_FONT := 20
const STAT_ROW := 25.0                   # px per stat row
const STAT_LABEL_W := 54.0
const STAT_NUM_W := 40.0
const STAT_BAR_H := 12.0
const STAT_BAR_BG := Color(0.25, 0.27, 0.33)
const STAT_BAR := Color(0.45, 0.65, 1.0)
const STAT_SPEC := Color(1.0, 0.82, 0.25)   # a specialty stat (and every stat of a boss) in gold
const DIM_TEXT := Color(0.7, 0.72, 0.78)
const ARROW_COLOR := Color(1.0, 0.82, 0.25)
const TIER_TEXT := {"good": "GOOD", "boss": "BOSS"}
const STAT_NAMES := [["speed", "SPD"], ["shooting", "SHT"], ["finishing", "FIN"], ["defense", "DEF"],
		["stamina", "STA"]]

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd

var _root: Control
var _frame: Control
var _cands: Array = []       # Trip.recruit_candidates(): player dicts
var _cards: Array = []       # Buttons, one per candidate
var _sign: Button
var _picked := -1
var _arm_t := ARM_T
var _sign_arm_t := 0.0
var _busy := false           # signed: waiting for the banner, then the map
var _leave_t := -1.0
var _leave_to := "map"
var _ok := true              # false: nothing to recruit here (shows CONTINUE)

func _ready() -> void:
	_root = UI.screen_root(self)
	_frame = Control.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.offset_left = -FRAME_SIZE.x / 2.0
	_frame.offset_top = -FRAME_SIZE.y / 2.0
	_frame.offset_right = FRAME_SIZE.x / 2.0
	_frame.offset_bottom = FRAME_SIZE.y / 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frame)
	_ok = Trip.active and Trip.phase == "recruit"
	if _ok:
		_cands = Trip.recruit_candidates()
		_ok = _cands.size() > 0
	if _ok:
		_build()
	else:
		_build_nothing()
	_stat("recruit_screen")

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_refresh()
	if _sign_arm_t > 0.0:
		_sign_arm_t -= delta
		if _sign_arm_t <= 0.0:
			_refresh()
	if _leave_t > 0.0:
		_leave_t -= delta
		if _leave_t <= 0.0:
			Flow.go(_leave_to)

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

func _sfx(sfx_name: String, db := 0.0) -> void:
	if audio != null:
		audio.play(sfx_name, db)

# ---------------- building ----------------

func _crew_name() -> String:
	var crew: Dictionary = Cities.city(Trip.city).get("crew", {})
	return str(crew.get("name", "THE LOCAL CREW"))

func _crew_color() -> Color:
	var crew: Dictionary = Cities.city(Trip.city).get("crew", {})
	var c = crew.get("ui_color", UI.OPT_COLOR)
	return c if c is Color else UI.OPT_COLOR

func _build() -> void:
	var head := _place(UI.vbox(_frame, 0, false), Vector2(0, HEAD_TOP), Vector2(FRAME_SIZE.x, 110))
	UI.title(head, "PICK YOUR RECRUIT")
	UI.subtitle(head, "You beat %s! ONE of them joins the %s." % [_crew_name(), Cities.CREW_NAME])
	var x0: float = (FRAME_SIZE.x - CARD_SIZE.x * _cands.size() - CARD_GAP * (_cands.size() - 1)) / 2.0
	for i in _cands.size():
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = CARD_SIZE
		b.size = CARD_SIZE
		b.position = Vector2(x0 + i * (CARD_SIZE.x + CARD_GAP), CARD_TOP)
		b.pressed.connect(_on_card.bind(i))
		_frame.add_child(b)
		var art := CardArt.new()
		art.setup(_cands[i], _crew_color())
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(art)
		_cards.append(b)
	_sign = UI.button(_frame, "TAP A PLAYER", _on_sign, UI.KIND_LIT, SIGN_SIZE)
	_sign.position = Vector2((FRAME_SIZE.x - SIGN_SIZE.x) / 2.0, SIGN_Y)
	_refresh()

func _build_nothing() -> void:
	var box := UI.vbox(_frame)
	UI.title(box, "NOBODY TO RECRUIT")
	UI.subtitle(box, "Everyone here is already on your bench.")
	_leave_to = Trip.resume_screen() if Trip.active else "title"
	if _leave_to == "recruit":
		_leave_to = "map"
	_sign = UI.button(UI.hbox(box), "CONTINUE", _on_continue, UI.KIND_LIT)
	_refresh()

func _place(c: Control, pos: Vector2, sz: Vector2) -> Control:
	c.position = pos
	c.size = sz
	return c

func _card_style(picked: bool) -> StyleBoxFlat:
	var sb := UI.style_box(CARD_FILL_PICKED if picked else CARD_FILL, UI.LIT_COLOR if picked else UI.OFF_BORDER,
			PICKED_BORDER_W if picked else CARD_BORDER_W)
	return sb

# card looks, SIGN text and what can be tapped now
func _refresh() -> void:
	var armed: bool = _arm_t <= 0.0 and not _busy
	for i in _cards.size():
		var b: Button = _cards[i]
		var sb: StyleBoxFlat = _card_style(i == _picked)
		for k in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(k, sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.disabled = not armed
		(b.get_child(0) as CardArt).picked = i == _picked
		b.get_child(0).queue_redraw()
	if _sign == null:
		return
	if not _ok:
		UI.set_enabled(_sign, armed)
		return
	if _picked >= 0:
		_sign.text = "SIGN " + str(_cands[_picked].get("name", ""))
	else:
		_sign.text = "TAP A PLAYER"
	UI.set_enabled(_sign, armed and _picked >= 0 and _sign_arm_t <= 0.0)

# ---------------- taps ----------------

func _on_card(i: int) -> void:
	if _busy or _arm_t > 0.0 or i < 0 or i >= _cands.size():
		return
	if i != _picked:
		_picked = i
		_sign_arm_t = PICK_ARM_T
		_sfx("bounce", -8.0)
		_stat("recruit_pick")
	_refresh()

func _on_sign() -> void:
	if _busy or _arm_t > 0.0 or _sign_arm_t > 0.0 or _picked < 0:
		return
	var p: Dictionary = _cands[_picked]
	var id: String = str(p.get("id", ""))
	if not Trip.recruit(id):
		push_warning("Recruit: Trip.recruit('%s') refused" % id)
		_leave_to = Trip.resume_screen() if Trip.active else "title"
	else:
		_leave_to = Trip.resume_screen()
		if _leave_to == "recruit":
			_leave_to = "map"
	_stat("recruit_signed")
	_stat("recruit_" + id)
	_busy = true
	_refresh()
	_sfx("swish")
	_sfx("crowd", -10.0)
	_banner("%s JOINS THE %s!" % [str(p.get("full", p.get("name", id))).to_upper(), Cities.CREW_NAME])
	_leave_t = JOIN_SHOW

func _on_continue() -> void:
	if _busy or _arm_t > 0.0:
		return
	_busy = true
	Flow.go(_leave_to)

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

# ---------------- trip test (P5-15) ----------------

# The default choice: sign the first candidate (or CONTINUE when there is nobody). False once signed.
func auto_step() -> bool:
	if _busy:
		return false
	_arm_t = 0.0
	_sign_arm_t = 0.0
	if not _ok:
		_on_continue()
		return true
	if _picked < 0:
		_picked = 0
	_on_sign()
	return true


# ---------------- a candidate card (drawn; the Button under it takes the tap) ----------------

class CardArt extends Control:
	var p: Dictionary = {}
	var crew_color := Color.GRAY
	var picked := false
	var _city_tex: Texture2D
	var _crew_tex: Texture2D
	var _portrait: Texture2D
	var _spec: Array = []
	var _tier := ""

	func setup(player: Dictionary, color: Color) -> void:
		p = player
		crew_color = color
		var id: String = str(p.get("id", ""))
		var data: Dictionary = Cities.player(id)
		_city_tex = _sheet(Cities.crew_sheet(id, false))
		_crew_tex = _sheet(Cities.crew_sheet(id, true))
		var por: String = PORTRAIT_DIR + str(data.get("portrait", id)) + ".png"
		_portrait = load(por) as Texture2D if ResourceLoader.exists(por) else null
		var sp = data.get("spec", [])
		_spec = sp if sp is Array else []
		_tier = str(p.get("tier", data.get("tier", "")))

	static func _sheet(sheet: String) -> Texture2D:
		var path: String = SHEET_DIR + sheet + ".png"
		if not ResourceLoader.exists(path):
			return null
		var t: Texture2D = load(path) as Texture2D
		if t == null or t.get_size() != SHEET_SIZE:
			return null
		return t

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		var w: float = size.x
		var pad: float = CARD_PAD
		draw_rect(Rect2(pad, pad, w - pad * 2.0, BAND_H), crew_color)
		# art row: portrait, then the sprite now -> in your colors
		var top: float = pad + BAND_H + 8.0
		var x: float = pad + 4.0
		var sc: float = SPRITE_SCALE if _portrait != null else SPRITE_SCALE_ALONE
		var spr: Vector2 = SHEET_FRAME * sc
		var spr_y: float = top + ART_H - spr.y
		if _portrait != null:
			var ps: Vector2 = _portrait.get_size() * PORTRAIT_SCALE
			draw_texture_rect(_portrait, Rect2(Vector2(x, top + ART_H - ps.y), ps), false)
			x += ps.x + 6.0
		var room: float = w - pad - 4.0 - x
		var gap: float = maxf(0.0, (room - spr.x * 2.0) / 3.0)
		var a: Vector2 = Vector2(x + gap, spr_y)
		var b: Vector2 = Vector2(x + gap * 2.0 + spr.x, spr_y)
		_sprite(_city_tex, a, spr, crew_color)
		_sprite(_crew_tex, b, spr, UI.OFF_COLOR)
		var mid: float = (a.x + spr.x + b.x) / 2.0
		var ay: float = spr_y + spr.y * 0.45
		draw_line(Vector2(mid - 9.0, ay), Vector2(mid + 7.0, ay), ARROW_COLOR, 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2(mid + 12.0, ay), Vector2(mid + 3.0, ay - 9.0),
				Vector2(mid + 3.0, ay + 9.0)]), ARROW_COLOR)
		_text(font, "NOW", Vector2(a.x, top + ART_H + 4.0), spr.x, SMALL_FONT - 4, DIM_TEXT)
		_text(font, "WITH YOU", Vector2(b.x - 20.0, top + ART_H + 4.0), spr.x + 40.0, SMALL_FONT - 4, UI.LIT_COLOR)
		# name, role, tier and specialty
		var y: float = top + ART_H + 28.0
		var num: int = int(p.get("number", 0))
		_text(font, "#%d %s" % [num, str(p.get("full", p.get("name", "")))], Vector2(pad, y), w - pad * 2.0,
				NAME_FONT, UI.LIT_COLOR if picked else UI.TEXT_COLOR)
		y += 34.0
		var tier: String = str(TIER_TEXT.get(_tier, _tier.to_upper()))
		var role: String = str(p.get("role", "")).to_upper()
		_text(font, role if role.contains(tier) else "%s  -  %s" % [tier, role], Vector2(pad, y), w - pad * 2.0,
				SMALL_FONT, STAT_SPEC if _tier == "boss" else DIM_TEXT)
		y += 26.0
		_text(font, _spec_text(), Vector2(pad, y), w - pad * 2.0, SMALL_FONT, UI.TEXT_COLOR)
		y += 30.0
		# the 5 ratings he joins with
		var r: Dictionary = p.get("ratings", {})
		var bar_x: float = pad + 10.0 + STAT_LABEL_W
		var bar_w: float = w - bar_x - pad - 10.0 - STAT_NUM_W
		for s in STAT_NAMES:
			var v: int = int(r.get(s[0], 50))
			var hot: bool = _tier == "boss" or _spec.has(s[0])
			_text(font, s[1], Vector2(pad + 10.0, y), STAT_LABEL_W, STAT_FONT, STAT_SPEC if hot else DIM_TEXT,
					HORIZONTAL_ALIGNMENT_LEFT)
			var by: float = y + (STAT_ROW - STAT_BAR_H) / 2.0 - 2.0
			draw_rect(Rect2(bar_x, by, bar_w, STAT_BAR_H), STAT_BAR_BG)
			draw_rect(Rect2(bar_x, by, bar_w * clampf(v / 100.0, 0.0, 1.0), STAT_BAR_H), STAT_SPEC if hot else STAT_BAR)
			_text(font, str(v), Vector2(bar_x + bar_w + 4.0, y), STAT_NUM_W, STAT_FONT, UI.TEXT_COLOR,
					HORIZONTAL_ALIGNMENT_RIGHT)
			y += STAT_ROW
		if picked:
			_text(font, "PICKED", Vector2(w - pad - 120.0, pad + BAND_H + 6.0), 112.0, SMALL_FONT, UI.LIT_COLOR,
					HORIZONTAL_ALIGNMENT_RIGHT)

	func _spec_text() -> String:
		if _tier == "boss":
			return "BOSS: STRONG AT EVERYTHING"
		var names: Array = []
		for s in _spec:
			names.append(str(s).to_upper())
		if names.is_empty():
			return ""
		return "BEST AT " + " + ".join(PackedStringArray(names))

	func _sprite(tex: Texture2D, pos: Vector2, sz: Vector2, fallback: Color) -> void:
		if tex != null:
			draw_texture_rect_region(tex, Rect2(pos, sz), Rect2(Vector2.ZERO, SHEET_FRAME))
			return
		# no sheet: a simple silhouette in the colour he would wear
		draw_circle(pos + Vector2(sz.x / 2.0, sz.y * 0.16), sz.x * 0.16, fallback.lightened(0.3))
		draw_rect(Rect2(pos + Vector2(sz.x * 0.25, sz.y * 0.28), Vector2(sz.x * 0.5, sz.y * 0.62)), fallback)

	func _text(font: Font, t: String, pos: Vector2, width: float, fsize: int, color: Color,
			align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
		var base: Vector2 = pos + Vector2(0, fsize)
		draw_string_outline(font, base, t, align, width, fsize, 6, UI.OUTLINE_COLOR)
		draw_string(font, base, t, align, width, fsize, color)
