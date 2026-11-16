extends CanvasLayer
# Lineup screen (P5-11, Flow screen "lineup"): pick your 3 starters before every trip game. Built in code (ui_kit.gd).
#   Left: your roster (the 3 underdogs + recruits, up to about 10) as big cards in a scrolling list: idle sprite in
#   your colors, name, number and role, the 5 stat bars. Tap a card to put him in the lineup; the FIRST one you pick
#   is the one you control (badge YOU), the others get 2 and 3. Tap a starter again to bench him (the ones after him
#   move up). With 3 picked, a tap on a bench player says to bench one first.
#   Right: the crew you face (their 3 for this game, from Trip.match_for()) and PLAY.
#   PLAY: Trip.set_starters(picks, picks[0]) (saved, so the lineup is remembered for the next game), then
#   Trip.match_for() builds Flow.match and the game starts. BACK: the map (New York: the bracket).
# Drag the list (or its wide scroll bar) to scroll; a drag never counts as a tap. Taps are ignored for ARM_T s when the
# screen opens and once PLAY is on its way, so nothing leaks into the next screen or the game.
# Desktop testing: Enter = PLAY, Escape = BACK. Trip test: auto_step() keeps the lineup and taps PLAY;
# tap_player(id) is the card tap (the trip test's pick check uses it).

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Cities = preload("res://scripts/cities.gd")

const ARM_T := 0.4                       # s the screen ignores taps after it opens (a tap from the last screen)
const FRAME_SIZE := Vector2(1280, 720)   # the layout box, centred on wider / taller screens
const BACK_POS := Vector2(16, 8)
const HEAD_Y := 4.0                      # px: the title row
const HINT_X := 232.0                    # px: the hint line, right of BACK
const HINT_Y := 82.0
const LIST_POS := Vector2(16, 126)       # the roster list (scrolls)
const LIST_SIZE := Vector2(872, 580)
const SCROLL_BAR_W := 36                 # wide enough to drag with a thumb
const COLS := 2
const CARD_SIZE := Vector2(400, 184)     # one roster card (the tap target)
const CARD_GAP := 14
const CARD_PAD := 12.0
const SIDE_POS := Vector2(904, 126)      # the opponent panel
const SIDE_SIZE := Vector2(360, 440)
const OPP_ROW := 124.0                   # px per opponent
const PLAY_SIZE := Vector2(360, 130)
const PLAY_POS := Vector2(904, 578)
const TAP_SLOP := 14.0                   # px a finger may move and still tap (more = a scroll drag)
const JUMP_PX := 80.0                    # px: one motion longer than this is a jump of the emulated mouse, not a drag
const HINT_FLASH := 1.6                  # s the "bench one first" hint stays
const SPRITE_SCALE := 2.0                # idle frame 40 x 64 source px on a card
const OPP_SPRITE_SCALE := 1.5
const SHEET_FRAME := Vector2(40, 64)     # player.gd SHEET_FRAME; idle facing the camera = column 0, row 0
const SHEET_SIZE := Vector2(1480, 320)   # a full sheet; anything else is drawn as a silhouette
const SHEET_DIR := "res://assets/players/"
const CREW_SUFFIX := "_crew"
const FALLBACK_SHEETS := ["blue_1", "red_1"]   # today's sheets when a player's own is missing (yours / theirs)
const NAME_FONT := 30
const SMALL_FONT := 20
const STAT_FONT := 18
const STAT_ROW := 21.0                   # px per stat row
const STAT_LABEL_W := 46.0
const STAT_NUM_W := 34.0
const STAT_BAR_H := 11.0
const STAT_BAR_BG := Color(0.25, 0.27, 0.33)
const STAT_BAR := Color(0.45, 0.65, 1.0)
const STAT_HIGH := Color(1.0, 0.82, 0.25)   # 60 and up in gold
const STAT_HIGH_AT := 60
const CARD_FILL := Color(0.1, 0.12, 0.18, 0.95)
const CARD_FILL_PICKED := Color(0.18, 0.2, 0.28, 0.98)
const CARD_BORDER_W := 3
const PICKED_BORDER_W := 8
const BADGE_R := 26.0                    # the YOU / 2 / 3 badge
const DIM_TEXT := Color(0.7, 0.72, 0.78)
const HINT_COLOR := Color(0.85, 0.87, 0.92)
const WARN_COLOR := Color(1.0, 0.6, 0.35)
const THEIR_RING := Color(0.85, 0.16, 0.23)   # the opponents' ring is always red (owner Q11 a)
const STAT_NAMES := [["speed", "SPD"], ["shooting", "SHT"], ["finishing", "FIN"], ["defense", "DEF"],
		["stamina", "STA"]]
const TIER_TEXT := {"start": "", "avg": "", "good": "GOOD", "boss": "BOSS"}

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd
var music := "menu"

var _root: Control
var _frame: Control
var _scroll: ScrollContainer
var _cards: Array = []       # Card nodes, roster order
var _roster: Array = []      # Trip.roster() player dicts
var _picks: Array = []       # ids in pick order; [0] = you
var _hint: Label
var _hint_t := 0.0
var _play: Button
var _back: Button
var _arm_t := ARM_T
var _busy := false
var _match := {}
var _tex := {}               # sheet id -> Texture2D or null (cache)

func _ready() -> void:
	if not Trip.active:
		Trip.continue_trip()   # a reload straight onto the lineup: the save is the truth
	_roster = Trip.roster()
	_match = Trip.match_for() if Trip.active else {}
	var ids: Array = Trip.roster_ids()
	for id in Trip.starters:
		if ids.has(str(id)) and not _picks.has(str(id)) and _picks.size() < Trip.STARTERS:
			_picks.append(str(id))
	_root = UI.screen_root(self)
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.size = FRAME_SIZE
	_root.add_child(_frame)
	_root.resized.connect(_center)
	_center()
	_build_head()
	_build_list()
	_build_side()
	_refresh()
	_stat("lineup_screen")

func _center() -> void:
	_frame.position = ((_root.size - FRAME_SIZE) / 2.0).floor()

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_refresh()
	if _hint_t > 0.0:
		_hint_t -= delta
		if _hint_t <= 0.0:
			_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_ESCAPE:
		_on_back()
	elif k.keycode == KEY_ENTER:
		_on_play()

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

# ---------------- building ----------------

func _build_head() -> void:
	_back = UI.button(_frame, "BACK", _on_back, UI.KIND_OPT, UI.SMALL_SIZE)
	_back.position = BACK_POS
	var head := UI.title(_frame, "LINEUP")
	head.position = Vector2(240, HEAD_Y)
	head.size = Vector2(800, 76)
	var sub: String = str(_match.get("label", ""))
	if _match.has("target"):
		sub += "\nFIRST TO %d" % int(_match.get("target", 0))
	var lbl := UI.subtitle(_frame, sub, UI.LIT_COLOR)
	lbl.position = SIDE_POS - Vector2(0, SIDE_POS.y - HEAD_Y)
	lbl.size = Vector2(SIDE_SIZE.x, SIDE_POS.y - HEAD_Y - 6.0)
	_hint = UI.label(_frame, "", SMALL_FONT + 4, HINT_COLOR)
	_hint.position = Vector2(HINT_X, HINT_Y)
	_hint.size = Vector2(LIST_POS.x + LIST_SIZE.x - HINT_X, 36)

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
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", CARD_GAP)
	grid.add_theme_constant_override("v_separation", CARD_GAP)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(grid)
	for p in _roster:
		var c := Card.new()
		c.screen = self
		c.p = p
		c.tex = _sheet(str(p.get("sheet", "")), 0)
		c.custom_minimum_size = CARD_SIZE
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(c)
		_cards.append(c)

func _build_side() -> void:
	var side := Side.new()
	side.screen = self
	side.position = SIDE_POS
	side.size = SIDE_SIZE
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var teams: Array = _match.get("teams", [])
	if teams.size() == 2:
		side.crew = str((teams[1] as Dictionary).get("name", ""))
		for p in (teams[1] as Dictionary).get("players", []):
			side.players.append(p)
			side.texs.append(_sheet(str((p as Dictionary).get("sheet", "")), 1))
	_frame.add_child(side)
	_play = UI.button(_frame, "PLAY", _on_play, UI.KIND_LIT, PLAY_SIZE)
	_play.position = PLAY_POS

# a sheet texture (null = draw a silhouette): the player's own, without _crew, then today's team sheet
func _sheet(sheet: String, team: int) -> Texture2D:
	var key: String = "%s/%d" % [sheet, team]
	if _tex.has(key):
		return _tex[key]
	var tries: Array = [sheet]
	if sheet.ends_with(CREW_SUFFIX):
		tries.append(sheet.substr(0, sheet.length() - CREW_SUFFIX.length()))
	tries.append(FALLBACK_SHEETS[team])
	var out: Texture2D = null
	for s in tries:
		var path: String = SHEET_DIR + str(s) + ".png"
		if str(s) != "" and ResourceLoader.exists(path):
			var t = load(path)
			if t is Texture2D and (t as Texture2D).get_size() == SHEET_SIZE:
				out = t
				break
	_tex[key] = out
	return out

# ---------------- state ----------------

func _refresh() -> void:
	var full: bool = _picks.size() == Trip.STARTERS
	UI.set_enabled(_play, full and _arm_t <= 0.0 and not _busy)
	UI.set_enabled(_back, _arm_t <= 0.0 and not _busy)
	if _hint_t > 0.0:
		_hint.label_settings.font_color = WARN_COLOR
	else:
		_hint.label_settings.font_color = HINT_COLOR
		if _picks.is_empty():
			_hint.text = "Tap 3 starters. The first one you pick is YOU."
		elif full:
			_hint.text = "You play %s. Tap PLAY, or tap a starter to bench him." % _name_of(str(_picks[0]))
		else:
			_hint.text = "Pick %d more. You play %s." % [Trip.STARTERS - _picks.size(), _name_of(str(_picks[0]))]
	for c in _cards:
		(c as Control).queue_redraw()

func _name_of(id: String) -> String:
	for p in _roster:
		if str(p.get("id", "")) == id:
			return str(p.get("name", id))
	return id

# the badge of a roster player: 0 = bench, 1 = YOU, 2, 3
func slot_of(id: String) -> int:
	return _picks.find(id) + 1

# a tap on a roster card (also the trip test's tap)
func tap_player(id: String) -> void:
	if _busy:
		return
	if _picks.has(id):
		_picks.erase(id)
		_stat("lineup_bench")
	elif _picks.size() < Trip.STARTERS:
		_picks.append(id)
		_stat("lineup_pick")
	else:
		_hint.text = "3 starters picked: tap one of them to bench him first."
		_hint_t = HINT_FLASH
		_refresh()
		return
	if audio != null:
		audio.play("bounce", -8.0)
	_hint_t = 0.0
	_refresh()

func _card_tapped(id: String) -> void:
	if _arm_t > 0.0:
		return
	tap_player(id)

func _on_play() -> void:
	if _busy or _arm_t > 0.0 or _picks.size() != Trip.STARTERS:
		return
	if not Trip.set_starters(_picks, str(_picks[0])):
		_hint.text = "That lineup doesn't work: pick 3 different players."
		_hint_t = HINT_FLASH
		_refresh()
		return
	if audio != null:
		audio.play("bounce", -4.0)
	_stat("lineup_play")
	Trip.match_for()   # Flow.match with these starters (starter 0 = you)
	_go(Flow.GAME)

func _on_back() -> void:
	if _busy or _arm_t > 0.0:
		return
	_go("bracket" if Trip.is_tournament(Trip.city) else "map")

func _go(to: String) -> void:
	_busy = true
	_refresh()
	Flow.go(to)

# trip test: keep the lineup (fill it from the roster if it isn't 3) and PLAY
func auto_step() -> bool:
	if _busy:
		return false
	for id in Trip.roster_ids():
		if _picks.size() >= Trip.STARTERS:
			break
		if not _picks.has(str(id)):
			_picks.append(str(id))
	_arm_t = 0.0
	_on_play()
	return _busy

# ---------------- drawing helpers (cards and the side panel) ----------------

static func draw_text(c: CanvasItem, pos: Vector2, text: String, fs: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	var font: Font = ThemeDB.fallback_font
	c.draw_string_outline(font, pos, text, align, w, fs, 6, UI.OUTLINE_COLOR)
	c.draw_string(font, pos, text, align, w, fs, col)

static func draw_sprite(c: CanvasItem, tex: Texture2D, pos: Vector2, sc: float, fallback: Color) -> void:
	var sz: Vector2 = SHEET_FRAME * sc
	if tex != null:
		c.draw_texture_rect_region(tex, Rect2(pos, sz), Rect2(Vector2.ZERO, SHEET_FRAME))
	else:
		c.draw_circle(pos + Vector2(sz.x / 2.0, sz.y * 0.2), sz.x * 0.22, fallback)
		c.draw_rect(Rect2(pos + Vector2(sz.x * 0.22, sz.y * 0.34), Vector2(sz.x * 0.56, sz.y * 0.6)), fallback)

static func draw_ring(c: CanvasItem, feet: Vector2, w: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a: float = TAU * i / 24.0
		pts.append(feet + Vector2(cos(a) * w / 2.0, sin(a) * w / 6.0))
	c.draw_polyline(pts, col, 3.0)


# One roster card: tap = pick / bench; a drag scrolls the list instead.
class Card extends Control:
	var screen               # lineup.gd
	var p := {}
	var tex: Texture2D
	var _down := false
	var _drag := false
	var _press := Vector2.ZERO   # where the finger went down (screen px; the card moves while the list scrolls)
	var _last := Vector2.ZERO

	# Distances are measured from the press point on the screen, not summed from motion events: the web build can
	# send one motion with a big jump (the emulated mouse catching up with a new finger), which is not a drag.
	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_down = true
				_drag = false
				_press = mb.global_position
				_last = _press
			elif _down:
				_down = false
				if not _drag and mb.global_position.distance_to(_press) <= screen.TAP_SLOP:
					screen._card_tapped(str(p.get("id", "")))
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
				_press = g   # a jump, not a finger moving: start measuring again from here
			elif g.distance_to(_press) > screen.TAP_SLOP:
				_drag = true
			if _drag and step.length() <= screen.JUMP_PX:
				screen._scroll.scroll_vertical -= int(step.y)
			accept_event()

	func _draw() -> void:
		var s = screen
		var id: String = str(p.get("id", ""))
		var slot: int = s.slot_of(id)
		var r := Rect2(Vector2.ZERO, size)
		var fill: Color = s.CARD_FILL_PICKED if slot > 0 else s.CARD_FILL
		var border: Color = s.UI.LIT_COLOR if slot > 0 else s.UI.OFF_BORDER
		var sb: StyleBoxFlat = s.UI.style_box(fill, border, s.PICKED_BORDER_W if slot > 0 else s.CARD_BORDER_W)
		draw_style_box(sb, r)
		var pad: float = s.CARD_PAD
		# the sprite on a blue ring
		var sc: float = s.SPRITE_SCALE
		var spr: Vector2 = s.SHEET_FRAME * sc
		var sp := Vector2(pad + 4.0, (size.y - spr.y) / 2.0)
		s.draw_ring(self, sp + Vector2(spr.x / 2.0, spr.y * 59.0 / 64.0), spr.x * 0.9, s.UI.OFF_BORDER)
		s.draw_sprite(self, tex, sp, sc, s.UI.OFF_COLOR)
		# name, number, role
		var x: float = sp.x + spr.x + 12.0
		var tw: float = size.x - x - pad
		s.draw_text(self, Vector2(x, pad + 26.0), str(p.get("name", id)), s.NAME_FONT, s.UI.TEXT_COLOR)
		var role: String = str(p.get("role", ""))
		var num: int = int(p.get("number", 0))
		var tier: String = str(s.TIER_TEXT.get(str(p.get("tier", "")), ""))
		var sub: String = ("#%d  " % num if num > 0 else "") + role + (("  " + tier) if tier != "" else "")
		s.draw_text(self, Vector2(x, pad + 50.0), sub, s.SMALL_FONT, s.DIM_TEXT, HORIZONTAL_ALIGNMENT_LEFT, tw)
		# the 5 stats
		var rt: Dictionary = p.get("ratings", {})
		var y: float = pad + 62.0
		var bar_w: float = tw - s.STAT_LABEL_W - s.STAT_NUM_W - 8.0
		for e in s.STAT_NAMES:
			var v: int = int(rt.get(e[0], 0))
			s.draw_text(self, Vector2(x, y + 15.0), str(e[1]), s.STAT_FONT, s.UI.TEXT_COLOR)
			var bx: float = x + s.STAT_LABEL_W
			var by: float = y + (s.STAT_ROW - s.STAT_BAR_H) / 2.0
			draw_rect(Rect2(bx, by, bar_w, s.STAT_BAR_H), s.STAT_BAR_BG)
			var col: Color = s.STAT_HIGH if v >= s.STAT_HIGH_AT else s.STAT_BAR
			draw_rect(Rect2(bx, by, bar_w * clampf(v / 100.0, 0.0, 1.0), s.STAT_BAR_H), col)
			s.draw_text(self, Vector2(bx + bar_w + 6.0, y + 15.0), str(v), s.STAT_FONT, s.UI.TEXT_COLOR)
			y += s.STAT_ROW
		# the badge: YOU (the one you control), 2, 3
		if slot > 0:
			var txt: String = "YOU" if slot == 1 else str(slot)
			var bw: float = s.BADGE_R * (3.2 if slot == 1 else 2.0)
			var br := Rect2(size.x - pad - bw, pad, bw, s.BADGE_R * 2.0)
			draw_style_box(s.UI.style_box(s.UI.LIT_COLOR, s.UI.LIT_BORDER, 3), br)
			var font: Font = ThemeDB.fallback_font
			var fs: int = 24
			draw_string(font, Vector2(br.position.x, br.get_center().y + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER,
					bw, fs, s.UI.LIT_TEXT)


# The crew you face: their name and the 3 players for this game (red ring, owner Q11 a).
class Side extends Control:
	var screen
	var crew := ""
	var players: Array = []
	var texs: Array = []

	func _draw() -> void:
		var s = screen
		draw_style_box(s.UI.style_box(s.UI.PANEL_COLOR, s.UI.PANEL_BORDER, s.UI.BORDER), Rect2(Vector2.ZERO, size))
		s.draw_text(self, Vector2(0, 40), "VS " + crew, s.NAME_FONT - 4, s.UI.LIT_COLOR, HORIZONTAL_ALIGNMENT_CENTER,
				size.x)
		var y: float = 56.0
		for i in players.size():
			var p: Dictionary = players[i]
			var sc: float = s.OPP_SPRITE_SCALE
			var spr: Vector2 = s.SHEET_FRAME * sc
			var sp := Vector2(18.0, y + (s.OPP_ROW - spr.y) / 2.0)
			s.draw_ring(self, sp + Vector2(spr.x / 2.0, spr.y * 59.0 / 64.0), spr.x * 0.9, s.THEIR_RING)
			s.draw_sprite(self, texs[i] if i < texs.size() else null, sp, sc, s.THEIR_RING)
			var x: float = sp.x + spr.x + 14.0
			s.draw_text(self, Vector2(x, y + 44.0), str(p.get("name", "?")), s.NAME_FONT - 4, s.UI.TEXT_COLOR)
			var tier: String = str(s.TIER_TEXT.get(str(p.get("tier", "")), ""))
			var role: String = str(p.get("role", ""))
			var sub: String = (tier + "  " if tier != "" else "") + role
			s.draw_text(self, Vector2(x, y + 72.0), sub, s.SMALL_FONT, s.STAT_HIGH if tier == "BOSS" else s.DIM_TEXT,
					HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 12.0)
			var rt: Dictionary = p.get("ratings", {})
			var tot := 0
			for e in s.STAT_NAMES:
				tot += int(rt.get(e[0], 0))
			s.draw_text(self, Vector2(x, y + 98.0), "rating %d" % int(round(tot / 5.0)), s.SMALL_FONT, s.DIM_TEXT)
			y += s.OPP_ROW
