extends CanvasLayer
# Tournament bracket (P5-14, Flow screen "bracket"): the New York finale. Built in code with ui_kit.gd.
#   Owner rules: 3 knockout rounds (quarterfinal, semifinal, final), all to 21; a loss replays that round; the final
#   is against the champions (the final round's crew in cities.gd, "CONCRETE CROWNS") and their boss ny_boss (KING).
#   Drawn as a bracket: your path from the quarterfinal to the trophy, one box per round (your row on top, the
#   opponent below), won rounds marked WON, the current round lit gold, later rounds dim; the champions' boss
#   stands over the final box.
#   Buttons: PLAY (the current round: Trip.match_for() then the lineup), POINTS (n) when trip.gd has stat points
#   waiting (Trip.can_spend() for some player and stat; the points screen gets {"then": "bracket"}), TITLE (top-left; the trip is saved).
#   After the final is won trip.gd's after_result() goes to story "ending" and then the title; if this screen is
#   reached with the trip done it shows CHAMPIONS and a TITLE button.
# On the first visit (the trip's phase still "map") the phase becomes "bracket" and is saved, so CONTINUE comes back
# here and points can be spent between rounds (trip.gd SPEND_PHASES).
# Touch first; desktop testing: Escape = TITLE. auto_step() (trip test) taps PLAY (TITLE once the trip is done).

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Cities = preload("res://scripts/cities.gd")
const Ratings = preload("res://scripts/ratings.gd")

const ARM_T := 0.5                       # s the screen ignores taps after it opens (a tap from the last screen)
const FRAME_SIZE := Vector2(1280, 720)   # the layout box, centred on wider / taller screens
const HEAD_TOP := 6.0
const BOX_SIZE := Vector2(320, 120)      # one round's match box (two rows)
const BOX_POS := [Vector2(40, 170), Vector2(400, 255), Vector2(760, 340)]   # quarterfinal, semifinal, final
const TROPHY_POS := Vector2(1175, 400)   # centre of the trophy
const BOSS_SCALE := 2.0                  # the boss sprite over the final box (40 x 64 idle frame)
const BOSS_POS := Vector2(985, 168)      # top-left of the boss sprite
const INFO_Y := 486.0                    # px: the "next round" line
const BUTTON_Y := 590.0                  # px: top of the PLAY row
const PLAY_SIZE := Vector2(340, 120)
const POINTS_SIZE := Vector2(300, 120)
const TITLE_SIZE := Vector2(200, 110)
const TITLE_POS := Vector2(24, 16)
const ROW_FONT := 26
const TAG_FONT := 20
const ROUND_FONT := 24
const LINE_W := 5.0
const DIM_BOX := Color(0.13, 0.14, 0.19, 0.9)
const DIM_BORDER := Color(0.4, 0.42, 0.5, 0.8)
const DIM_TEXT := Color(0.55, 0.57, 0.63)
const WON_COLOR := Color(0.35, 0.85, 0.45)
const LINE_DIM := Color(0.35, 0.37, 0.45)
const SHEET_FRAME := Vector2(40, 64)     # player.gd SHEET_FRAME; column 0, row 0 = idle facing the camera
const SHEET_SIZE := Vector2(1480, 320)
const SHEET_DIR := "res://assets/players/"
const TOURNAMENT := "new_york"           # fallback id if the trip isn't at the tournament

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd
var music := "menu"          # set in _ready to the tournament city's track

var _root: Control
var _frame: Control
var _art: BracketArt
var _buttons: Array = []
var _arm_t := ARM_T
var _busy := false
var _state := "play"         # "play" (a round to play), "done" (champions), "away" (the trip isn't in New York)
var _city := TOURNAMENT

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
	if Trip.active and Trip.is_done():
		_state = "done"
	elif Trip.active and Trip.is_tournament(Trip.city):
		_state = "play"
		_city = Trip.city
		if Trip.phase == "map":
			Trip.phase = "bracket"   # CONTINUE comes back here; points can be spent between rounds
			Trip.save()
	else:
		_state = "away"
	var m: String = str(Cities.city(_city).get("music", ""))
	if m != "":
		music = m
	_build()
	_stat("bracket_screen")

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			for b in _buttons:
				UI.set_enabled(b, true)

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
		_tap(_go.bind("title", {}))

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

# ---------------- building ----------------

func _rounds() -> Array:
	var r = Cities.city(_city).get("rounds", [])
	return r if r is Array else []

# rounds won so far (3 = champions)
func _won() -> int:
	if _state == "done":
		return _rounds().size()
	if _state == "away":
		return 0
	return Trip.bracket_round()

func _build() -> void:
	var c: Dictionary = Cities.city(_city)
	var head := UI.vbox(_frame, 0, false)
	head.position = Vector2(0, HEAD_TOP)
	head.size = Vector2(FRAME_SIZE.x, 120)
	UI.title(head, str(c.get("tournament_name", "THE TOURNAMENT")))
	UI.subtitle(head, "%s  -  KNOCKOUT, EVERY ROUND FIRST TO %d" % [str(c.get("name", "")),
			Cities.TOURNAMENT_TARGET])
	_art = BracketArt.new()
	_art.rounds = _rounds()
	_art.won = _won()
	_art.lost_round = _lost_round()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.load_boss()
	_frame.add_child(_art)
	var info := UI.label(_frame, _info_text(), UI.SUB_FONT, UI.LIT_COLOR if _state == "done" else UI.TEXT_COLOR)
	info.position = Vector2(0, INFO_Y)
	info.size = Vector2(FRAME_SIZE.x, 90)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := UI.hbox(_frame)
	row.position = Vector2(0, BUTTON_Y)
	row.size = Vector2(FRAME_SIZE.x, PLAY_SIZE.y)
	match _state:
		"done":
			_btn(row, "TITLE", _go.bind("title", {}), UI.KIND_LIT, PLAY_SIZE)
		"away":
			_btn(row, "TRIP MAP", _go.bind("map", {}), UI.KIND_LIT, PLAY_SIZE)
		_:
			_btn(row, "PLAY", _on_play, UI.KIND_LIT, PLAY_SIZE)
			if _points_waiting():
				_btn(row, "POINTS (%d)" % Trip.points, _go.bind("points", {"then": "bracket"}), UI.KIND_MAIN,
						POINTS_SIZE)
			var t: Button = _btn(_frame, "TITLE", _go.bind("title", {}), UI.KIND_OPT, TITLE_SIZE)
			t.position = TITLE_POS
	for b in _buttons:
		UI.set_enabled(b, false)

# stat points can be spent now (trip.gd can_spend() for any roster player and stat)
static func _points_waiting() -> bool:
	if Trip.points <= 0:
		return false
	for id in Trip.roster_ids():
		for s in Ratings.STATS:
			if Trip.can_spend(str(id), str(s)):
				return true
	return false

# the round just lost (0-based), or -1: the result screen sends a loss back here to replay it
func _lost_round() -> int:
	if _state != "play":
		return -1
	var o: Dictionary = Trip.last_outcome
	if o.is_empty() or bool(o.get("won", true)) or str(o.get("city", "")) != _city:
		return -1
	return Trip.bracket_round()

func _info_text() -> String:
	var rs: Array = _rounds()
	match _state:
		"done":
			return "CHAMPIONS! The %s rule %s." % [Cities.CREW_NAME, str(Cities.city(_city).get("name", ""))]
		"away":
			return "The tournament waits at the end of the road. Win every city to get here."
	var n: int = clampi(Trip.bracket_round(), 0, maxi(0, rs.size() - 1))
	if rs.is_empty():
		return ""
	var rd: Dictionary = rs[n]
	var crew: Dictionary = rd.get("crew", {})
	var opp: String = str(crew.get("name", ""))
	var rname: String = str(rd.get("round", "ROUND %d" % (n + 1)))
	var tail: String = "first to %d" % int(rd.get("target", Cities.TOURNAMENT_TARGET))
	if n == rs.size() - 1:
		tail = "the champions and their boss %s, %s" % [_boss_name(rs), tail]
	if _lost_round() >= 0:
		return "So close! Run the %s back: %s, %s." % [rname, opp, tail]
	return "NEXT: %s vs %s  -  %s" % [rname, opp, tail]

static func _boss_name(rs: Array) -> String:
	if rs.is_empty():
		return ""
	for id in (rs[rs.size() - 1] as Dictionary).get("players", []):
		var p: Dictionary = Cities.player(str(id))
		if str(p.get("tier", "")) == "boss":
			return str(p.get("name", id))
	return ""

func _btn(parent: Control, text: String, on_tap: Callable, kind: String, sz: Vector2) -> Button:
	var b: Button = UI.button(parent, text, _tap.bind(on_tap), kind, sz)
	_buttons.append(b)
	return b

# ---------------- taps ----------------

func _tap(on_tap: Callable) -> void:
	if _busy or _arm_t > 0.0:
		return
	if audio != null:
		audio.play("bounce", -8.0)
	on_tap.call()

func _go(to: String, to_args: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	_stat("bracket_to_" + to)
	Flow.go(to, to_args)

func _on_play() -> void:
	if _busy:
		return
	Trip.match_for()   # Flow.match = this round (the lineup builds it again with the picked starters)
	_stat("bracket_play_%d" % (Trip.bracket_round() + 1))
	_go("lineup", {})

# ---------------- trip test (P5-15) ----------------

# The default choice: PLAY the current round (TITLE once the trip is done, the map if not in New York).
func auto_step() -> bool:
	if _busy:
		return false
	_arm_t = 0.0
	match _state:
		"done":
			_go("title", {})
		"away":
			_go("map", {})
		_:
			_on_play()
	return true


# ---------------- the bracket drawing ----------------

class BracketArt extends Control:
	var rounds: Array = []
	var won := 0                 # rounds won (the current round = won, if below rounds.size())
	var lost_round := -1         # the round just lost (shown as "REPLAY")
	var _boss_tex: Texture2D
	var _boss_name := ""
	var _t := 0.0

	func load_boss() -> void:
		if rounds.is_empty():
			return
		for id in (rounds[rounds.size() - 1] as Dictionary).get("players", []):
			var p: Dictionary = Cities.player(str(id))
			if str(p.get("tier", "")) != "boss":
				continue
			_boss_name = str(p.get("name", id))
			var path: String = SHEET_DIR + str(p.get("sheet", id)) + ".png"
			if ResourceLoader.exists(path):
				var t: Texture2D = load(path) as Texture2D
				if t != null and t.get_size() == SHEET_SIZE:
					_boss_tex = t

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()   # the lit box pulses

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		var n: int = mini(rounds.size(), BOX_POS.size())
		# connectors: each box's winner row feeds the next box's top row; the trophy after the final
		for i in n:
			var a: Vector2 = BOX_POS[i] + Vector2(BOX_SIZE.x, BOX_SIZE.y / 2.0)
			var b: Vector2 = TROPHY_POS + Vector2(-60, 0)
			if i + 1 < n:
				b = BOX_POS[i + 1] + Vector2(0, BOX_SIZE.y / 4.0)
			var col: Color = WON_COLOR if i < won else LINE_DIM
			var mx: float = (a.x + b.x) / 2.0
			draw_polyline(PackedVector2Array([a, Vector2(mx, a.y), Vector2(mx, b.y), b]), col, LINE_W)
			if i > 0:   # the opponent came through the other side of the bracket: a stub into the bottom row
				var s: Vector2 = BOX_POS[i] + Vector2(0, BOX_SIZE.y * 0.75)
				draw_line(s + Vector2(-34, 0), s, LINE_DIM, LINE_W)
				draw_circle(s + Vector2(-38, 0), 6.0, LINE_DIM)
		for i in n:
			_draw_box(font, i)
		_draw_trophy(font, won >= rounds.size() and rounds.size() > 0)
		_draw_boss(font)

	func _draw_box(font: Font, i: int) -> void:
		var rd: Dictionary = rounds[i]
		var pos: Vector2 = BOX_POS[i]
		var r := Rect2(pos, BOX_SIZE)
		var current: bool = i == won
		var done: bool = i < won
		var fill: Color = UI.PANEL_COLOR if (current or done) else DIM_BOX
		var border: Color = DIM_BORDER
		var bw: float = 3.0
		if current:
			border = UI.LIT_COLOR.lerp(UI.LIT_BORDER, 0.5 + 0.5 * sin(_t * 5.0))
			bw = 7.0
		elif done:
			border = WON_COLOR
		var sb := UI.style_box(fill, border, int(bw))
		draw_style_box(sb, r)
		# round name over the box, with its state
		var rname: String = str(rd.get("round", "ROUND %d" % (i + 1)))
		var tag: String = ""
		var tag_col: Color = DIM_TEXT
		if done:
			tag = "WON"
			tag_col = WON_COLOR
		elif current:
			tag = "REPLAY" if lost_round == i else "NOW"
			tag_col = UI.LIT_COLOR
		_text(font, rname, pos + Vector2(4, -34), BOX_SIZE.x, ROUND_FONT, UI.LIT_COLOR if current else UI.TEXT_COLOR,
				HORIZONTAL_ALIGNMENT_LEFT)
		if tag != "":
			_text(font, tag, pos + Vector2(0, -32), BOX_SIZE.x - 4.0, TAG_FONT, tag_col, HORIZONTAL_ALIGNMENT_RIGHT)
		# your row (top) and the opponent (bottom)
		var row_h: float = BOX_SIZE.y / 2.0
		draw_line(pos + Vector2(10, row_h), pos + Vector2(BOX_SIZE.x - 10, row_h), DIM_BORDER, 2.0)
		var you_here: bool = i <= won
		var you: String = Cities.CREW_NAME
		if not you_here and i > 0:
			you = str((rounds[i - 1] as Dictionary).get("round", "")) + " WINNER"
		var you_col: Color = UI.TEXT_COLOR if you_here else DIM_TEXT
		draw_rect(Rect2(pos + Vector2(14, row_h / 2.0 - 9), Vector2(18, 18)), UI.OFF_COLOR if you_here else LINE_DIM)
		draw_rect(Rect2(pos + Vector2(14, row_h / 2.0 + 3), Vector2(18, 6)), UI.LIT_COLOR if you_here else LINE_DIM)
		_text(font, you, pos + Vector2(42, row_h / 2.0 - ROW_FONT * 0.7), BOX_SIZE.x - 52.0,
				ROW_FONT if you_here else TAG_FONT, you_col, HORIZONTAL_ALIGNMENT_LEFT)
		var crew: Dictionary = rd.get("crew", {})
		var cc = crew.get("ui_color", LINE_DIM)
		var ccol: Color = cc if cc is Color else LINE_DIM
		var opp_col: Color = DIM_TEXT if done else UI.TEXT_COLOR
		var sw := Rect2(pos + Vector2(14, row_h * 1.5 - 9), Vector2(18, 18))
		draw_rect(sw, ccol.darkened(0.4) if done else ccol)
		draw_rect(sw, DIM_TEXT, false, 2.0)   # dark crew colours still show
		var oname: String = str(crew.get("name", "?"))
		_text(font, oname, pos + Vector2(42, row_h * 1.5 - ROW_FONT * 0.7), BOX_SIZE.x - 52.0, ROW_FONT, opp_col,
				HORIZONTAL_ALIGNMENT_LEFT)
		if done:   # knocked out
			var y: float = pos.y + row_h * 1.5
			draw_line(Vector2(pos.x + 40, y), Vector2(pos.x + 44 + font.get_string_size(oname,
					HORIZONTAL_ALIGNMENT_LEFT, -1, ROW_FONT).x, y), DIM_TEXT, 3.0)

	func _draw_trophy(font: Font, champs: bool) -> void:
		var c: Vector2 = TROPHY_POS
		var gold: Color = UI.LIT_COLOR if champs else UI.LIT_COLOR.darkened(0.45)
		var dark: Color = gold.darkened(0.35)
		# cup, handles, stem, base
		draw_colored_polygon(PackedVector2Array([c + Vector2(-42, -62), c + Vector2(42, -62), c + Vector2(30, -12),
				c + Vector2(10, 0), c + Vector2(-10, 0), c + Vector2(-30, -12)]), gold)
		draw_arc(c + Vector2(-42, -44), 16.0, PI * 0.5, PI * 1.5, 12, dark, 6.0)
		draw_arc(c + Vector2(42, -44), 16.0, -PI * 0.5, PI * 0.5, 12, dark, 6.0)
		draw_rect(Rect2(c + Vector2(-7, 0), Vector2(14, 22)), dark)
		draw_rect(Rect2(c + Vector2(-34, 22), Vector2(68, 16)), gold)
		draw_rect(Rect2(c + Vector2(-40, 38), Vector2(80, 10)), dark)
		draw_circle(c + Vector2(-16, -46), 6.0, gold.lightened(0.4))
		_text(font, "CHAMPIONS", c + Vector2(-80, 54), 160.0, TAG_FONT, gold if champs else DIM_TEXT,
				HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_boss(font: Font) -> void:
		if _boss_name == "":
			return
		var sz: Vector2 = SHEET_FRAME * BOSS_SCALE
		var champs_beaten: bool = won >= rounds.size()
		if _boss_tex != null:
			draw_texture_rect_region(_boss_tex, Rect2(BOSS_POS, sz), Rect2(Vector2.ZERO, SHEET_FRAME),
					Color(1, 1, 1, 0.5) if champs_beaten else Color.WHITE)
		else:
			draw_circle(BOSS_POS + Vector2(sz.x / 2.0, sz.y * 0.16), sz.x * 0.16, DIM_TEXT)
			draw_rect(Rect2(BOSS_POS + Vector2(sz.x * 0.25, sz.y * 0.28), Vector2(sz.x * 0.5, sz.y * 0.62)), LINE_DIM)
		_text(font, _boss_name, BOSS_POS + Vector2(sz.x + 6, sz.y * 0.35), 160.0, ROW_FONT, UI.LIT_COLOR,
				HORIZONTAL_ALIGNMENT_LEFT)
		_text(font, "THE BOSS", BOSS_POS + Vector2(sz.x + 6, sz.y * 0.35 + 30), 160.0, TAG_FONT, DIM_TEXT,
				HORIZONTAL_ALIGNMENT_LEFT)

	func _text(font: Font, t: String, pos: Vector2, width: float, fsize: int, color: Color,
			align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
		var base: Vector2 = pos + Vector2(0, fsize)
		draw_string_outline(font, base, t, align, width, fsize, 6, UI.OUTLINE_COLOR)
		draw_string(font, base, t, align, width, fsize, color)
