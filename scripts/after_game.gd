extends CanvasLayer
# After a trip game (P5-12): one script for two Flow screens, built in code with ui_kit.gd.
#   result  the final score, WIN / LOSS, "HOMETOWN - GAME 2 OF 3" (or the tournament round), the points won and a
#           small stats table for both crews. A loss: RETRY (the same game again, after the "first_loss" scene the
#           first time). A win: NEXT (the next game, or the city's "won" scene and then the points screen).
#           Where it goes is trip.gd's after_result(); a won tournament round with points to spend goes to the
#           points screen first and then back to the bracket.
#   points  stat points: points left, a player picker (your whole roster, scrolls), the picked player's 5 stats with
#           a +3 button each (cap 90 shown), UNDO (the last point, until DONE) and DONE. DONE after a city = the
#           recruit screen (Trip.finish_points() / resume_screen()); from the bracket = back to args.then ("bracket").
#           Unspent points are kept for later. Reachable from anywhere as Flow.go("points", {"then": "bracket"}).
# Every button ignores taps for ARM_TIME after the screen opens (the tap that ended the game, or the last tap on the
# screen before, can't fall through) and once a Flow.go() is on its way.
# Desktop testing: Enter = the lit button (RETRY / NEXT / DONE), Backspace = UNDO.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Cities = preload("res://scripts/cities.gd")
const Trip = preload("res://scripts/trip.gd")
const Ratings = preload("res://scripts/ratings.gd")

const ARM_TIME := 0.8                      # s before the first tap counts (menu.gd's game-over arm time)
const TAP_SFX := "bounce"
const POINT_SFX := "swish"                 # a point spent (P5-A4 may add "stat_up"; see POINT_SFX_NEW)
const POINT_SFX_NEW := "stat_up"           # used instead when assets/sfx/stat_up.ogg exists

# result screen
const SCORE_FONT := 100
const WIN_FONT := 64
const WIN_COLOR := Color(1.0, 0.82, 0.25)  # gold
const LOSS_COLOR := Color(0.85, 0.35, 0.3)
const THEM_COLOR := Color(0.85, 0.85, 0.9)
const POINTS_COLOR := Color(0.55, 0.9, 0.55)
const TABLE_FONT := 24
const TABLE_COL_W := 150                   # px per stats column
const TABLE_NAME_W := 300                  # the crew-name column
const STAT_COLS := [["points", "PTS"], ["fg", "FG"], ["dunks", "DUNKS"], ["steals", "STL"], ["blocks", "BLK"]]

# points screen
const STATS := [["speed", "SPEED"], ["shooting", "SHOOTING"], ["finishing", "FINISHING"], ["defense", "DEFENSE"],
		["stamina", "STAMINA"]]
const HEAD_H := 120.0                      # px: the header row (title, points left, UNDO, DONE)
const LIST_W := 290.0                      # the player list column
const LIST_BTN := Vector2(260, 110)
const ROW_H := 110.0                       # one stat row (the + button is the board minimum, 200 x 110)
const ROW_GAP := 4
const STAT_LABEL_W := 210
const BAR_SIZE := Vector2(300, 44)
const VALUE_W := 140
const PLUS_SIZE := Vector2(200, 110)
const BAR_BG := Color(0.12, 0.13, 0.18)
const BAR_FILL := Color(0.29, 0.41, 0.66)    # your crew's blue (ui_kit OFF_COLOR, a bit lighter)
const BAR_CAP := Color(1.0, 0.82, 0.25)    # the cap line at 90 and a stat at the cap
const BAR_MAX := 100.0                     # a full bar
const CAP_TEXT_COLOR := Color(1.0, 0.82, 0.25)
const NOTE_COLOR := Color(0.65, 0.65, 0.7)

var main                    # main.gd (set by Flow.build_screen)
var audio                   # this screen's audio.gd
var music := "menu"

var _root: Control
var _arm_t := ARM_TIME
var _busy := false
var _buttons: Array = []    # every button (armed together)
var _default: Button        # the lit button (Enter, auto_step)
var _default_tap: Callable

# result
var _outcome := {}
var _won := false

# points
var _then := ""
var _then_args := {}
var _pick := ""             # roster id being raised
var _left_label: Label
var _undo_btn: Button
var _done_btn: Button
var _list_btns := {}        # id -> Button
var _plus_btns := {}        # stat -> Button
var _bars := {}             # stat -> StatBar
var _values := {}           # stat -> Label
var _point_sfx := POINT_SFX

func _ready() -> void:
	_root = UI.screen_root(self)
	if str(Flow.screen) == "points":
		_build_points()
	else:
		_build_result()
	for b in _buttons:
		UI.set_enabled(b, false)

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_refresh_enabled()

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER) and _default != null:
		_tap(_default_tap)
	elif k.keycode == KEY_BACKSPACE and _undo_btn != null:
		_tap(_on_undo)

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

func _btn(parent: Control, text: String, on_tap: Callable, kind: String, size := Vector2.ZERO) -> Button:
	var b: Button = UI.button(parent, text, _tap.bind(on_tap), kind, size)
	_buttons.append(b)
	return b

func _tap(on_tap: Callable) -> void:
	if _busy or _arm_t > 0.0:
		return
	if audio != null:
		audio.play(TAP_SFX, -8.0)
	on_tap.call()

func _go(to: String, to_args := {}) -> void:
	if _busy:
		return
	_busy = true
	for b in _buttons:
		UI.set_enabled(b, false)
	Flow.go(to, to_args)

func _refresh_enabled() -> void:
	if _busy or _arm_t > 0.0:
		return
	for b in _buttons:
		UI.set_enabled(b, true)
	if str(Flow.screen) == "points":
		_refresh_points()

# ---------------- result ----------------

func _build_result() -> void:
	_outcome = Trip.last_outcome
	var res: Dictionary = Flow.last_result
	_won = bool(_outcome.get("won", res.get("won", false)))
	var score: Array = res.get("score", [0, 0])
	var a: int = int(score[0]) if score.size() > 0 else 0
	var b: int = int(score[1]) if score.size() > 1 else 0
	var teams: Array = Flow.match.get("teams", [])
	var mine: String = Cities.CREW_NAME
	var theirs: String = "THEM"
	if teams.size() > 1:
		mine = str((teams[0] as Dictionary).get("name", mine))
		theirs = str((teams[1] as Dictionary).get("name", theirs))
	var box := UI.vbox(_root, 14)
	UI.subtitle(box, _game_label())
	var trip_done: bool = bool(_outcome.get("trip_done", false))
	var head: String = ("CHAMPIONS!" if trip_done else "WIN!") if _won else "LOSS"
	UI.label(box, head, WIN_FONT, WIN_COLOR if _won else LOSS_COLOR)
	var row := UI.hbox(box, 30)
	var ln: Label = UI.label(row, mine, UI.OPT_FONT)
	ln.custom_minimum_size = Vector2(TABLE_NAME_W, 0)
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.label(row, "%d - %d" % [a, b], SCORE_FONT, WIN_COLOR if _won else LOSS_COLOR)
	var rn: Label = UI.label(row, theirs, UI.OPT_FONT, THEM_COLOR)
	rn.custom_minimum_size = Vector2(TABLE_NAME_W, 0)
	rn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var pw: int = int(_outcome.get("points_won", 0))
	if pw > 0:
		UI.label(box, "+%d STAT POINTS  (%d to spend)" % [pw, Trip.points], UI.SUB_FONT, POINTS_COLOR)
	elif not _won:
		UI.label(box, "No penalty: run it back!", UI.SUB_FONT, NOTE_COLOR)
	_stats_table(box, res, mine, theirs)
	var brow := UI.hbox(box)
	if _won:
		_default_tap = _on_next
		_default = _btn(brow, "NEXT", _on_next, UI.KIND_LIT)
	else:
		_default_tap = _on_retry
		_default = _btn(brow, "RETRY", _on_retry, UI.KIND_LIT)
	_stat("result_" + ("win" if _won else "loss"))

# "HOMETOWN - GAME 2 OF 3" for the game just played (the match label, else from the outcome)
func _game_label() -> String:
	var lab: String = str(Flow.match.get("label", ""))
	if lab != "":
		return lab
	var cid: String = str(_outcome.get("city", ""))
	if cid == "":
		return ""
	return "%s - GAME %d OF %d" % [str(Cities.city(cid).get("name", cid)), int(_outcome.get("game", 1)),
			Trip.GAMES_PER_CITY]

func _stats_table(parent: Control, res: Dictionary, mine: String, theirs: String) -> void:
	var st: Dictionary = res.get("stats", {})
	var ts = st.get("team_stats", [])
	if not (ts is Array) or (ts as Array).size() < 2:
		return
	var p := UI.panel(parent)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var grid := GridContainer.new()
	grid.columns = STAT_COLS.size() + 1
	grid.add_theme_constant_override("h_separation", 8)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(grid)
	_cell(grid, "", TABLE_NAME_W, NOTE_COLOR)
	for c in STAT_COLS:
		_cell(grid, str(c[1]), TABLE_COL_W, NOTE_COLOR)
	var names: Array = [mine, theirs]
	for t in 2:
		var d: Dictionary = ts[t] if ts[t] is Dictionary else {}
		_cell(grid, str(names[t]), TABLE_NAME_W, UI.TEXT_COLOR)
		for c in STAT_COLS:
			var v: String = ""
			if str(c[0]) == "fg":
				v = "%d/%d" % [int(d.get("makes", 0)), int(d.get("shots", 0))]
			else:
				v = str(int(d.get(str(c[0]), 0)))
			_cell(grid, v, TABLE_COL_W, UI.TEXT_COLOR)

func _cell(grid: GridContainer, text: String, w: int, col: Color) -> void:
	var l: Label = UI.label(grid, text, TABLE_FONT, col)
	l.custom_minimum_size = Vector2(w, 0)

func _on_retry() -> void:
	_stat("result_retry")
	_follow_trip()

func _on_next() -> void:
	_stat("result_next")
	var o: Dictionary = _outcome
	# a won tournament round (not the final): spend the round's points first, then the bracket
	if bool(o.get("won", false)) and Trip.is_tournament(str(o.get("city", ""))) and not bool(o.get("trip_done", false)) \
			and Trip.points > 0 and Trip.SPEND_PHASES.has(Trip.phase):
		_go("points", {"then": "bracket"})
		return
	_follow_trip()

func _follow_trip() -> void:
	if not Trip.active:
		_go("title")   # no trip loaded (should not happen in the flow)
		return
	var r: Dictionary = Trip.after_result()
	_go(str(r.get("screen", "map")), r.get("args", {}))

# ---------------- points ----------------

func _build_points() -> void:
	var a: Dictionary = Flow.args
	_then = str(a.get("then", ""))
	var ta = a.get("then_args", {})
	_then_args = ta if ta is Dictionary else {}
	if ResourceLoader.exists("res://assets/sfx/" + POINT_SFX_NEW + ".ogg"):
		_point_sfx = POINT_SFX_NEW
	var ids: Array = Trip.roster_ids()
	_pick = Trip.human if ids.has(Trip.human) else (str(ids[0]) if ids.size() > 0 else "")
	# header: title and points left on the left, UNDO and DONE on the right
	var head := HBoxContainer.new()
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	head.offset_left = 24
	head.offset_right = -24
	head.offset_top = 6
	head.offset_bottom = HEAD_H
	head.add_theme_constant_override("separation", 24)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(head)
	var tcol := UI.vbox(head, 0, false)
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.alignment = BoxContainer.ALIGNMENT_CENTER
	var t: Label = UI.title(tcol, "STAT POINTS")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_left_label = UI.label(tcol, "", UI.SUB_FONT, POINTS_COLOR)
	_left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_undo_btn = _btn(head, "UNDO", _on_undo, UI.KIND_OPT, UI.SMALL_SIZE)
	_undo_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_done_btn = _btn(head, "DONE", _on_done, UI.KIND_MAIN, Vector2(240, 110))
	_done_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_default = _done_btn
	_default_tap = _on_done
	# left: the roster (scrolls with more than 5 players)
	var scroll := ScrollContainer.new()
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 24
	scroll.offset_right = 24 + LIST_W
	scroll.offset_top = HEAD_H + 10
	scroll.offset_bottom = -10
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", ROW_GAP)
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(list)
	for id in ids:
		var p: Dictionary = Cities.player(str(id))
		var b: Button = _btn(list, str(p.get("name", id)), _on_pick.bind(str(id)), UI.KIND_MAIN, LIST_BTN)
		b.add_theme_font_size_override("font_size", UI.OPT_FONT)
		b.mouse_filter = Control.MOUSE_FILTER_PASS   # a drag on a name still scrolls the list
		_list_btns[str(id)] = b
	# right: the picked player's 5 stats
	var right := VBoxContainer.new()
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	right.offset_left = 24 + LIST_W + 30
	right.offset_right = -24
	right.offset_top = HEAD_H + 4
	right.offset_bottom = -6
	right.add_theme_constant_override("separation", ROW_GAP)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(right)
	for s in STATS:
		var key: String = str(s[0])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		row.custom_minimum_size = Vector2(0, ROW_H)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		right.add_child(row)
		var l: Label = UI.label(row, str(s[1]), UI.OPT_FONT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.custom_minimum_size = Vector2(STAT_LABEL_W, 0)
		var bar := StatBar.new()
		bar.custom_minimum_size = BAR_SIZE
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
		_bars[key] = bar
		var v: Label = UI.label(row, "", UI.OPT_FONT)
		v.custom_minimum_size = Vector2(VALUE_W, 0)
		_values[key] = v
		var plus: Button = _btn(row, "+%d" % Trip.POINT_GAIN, _on_plus.bind(key), UI.KIND_LIT, PLUS_SIZE)
		_plus_btns[key] = plus
	_refresh_points()
	_stat("points_screen")

func _refresh_points() -> void:
	var left: int = Trip.points
	var spending: bool = Trip.active and Trip.SPEND_PHASES.has(Trip.phase)
	if not spending:
		_left_label.text = "Points are spent after a city or between tournament rounds."
	elif left > 0:
		_left_label.text = "%d POINT%s LEFT  (+%d each, max %d; unspent points are kept)" % [left,
				"" if left == 1 else "S", Trip.POINT_GAIN, Trip.STAT_CAP]
	else:
		_left_label.text = "No points left. Tap DONE."
	var e: Dictionary = Trip.roster_player(_pick)
	var r: Dictionary = e.get("ratings", {})
	for s in STATS:
		var key: String = str(s[0])
		var val: int = int(r.get(key, 0))
		var bar: StatBar = _bars[key]
		bar.value = val
		bar.queue_redraw()
		var at_cap: bool = val >= Trip.STAT_CAP
		var vl: Label = _values[key]
		vl.text = ("%d MAX" % val) if at_cap else ("%d / %d" % [val, Trip.STAT_CAP])
		vl.label_settings.font_color = CAP_TEXT_COLOR if at_cap else UI.TEXT_COLOR
		var plus: Button = _plus_btns[key]
		var can: bool = Trip.can_spend(_pick, key)
		if not _busy and _arm_t <= 0.0:
			UI.set_enabled(plus, can)
		UI.set_kind(plus, UI.KIND_LIT if can else UI.KIND_OPT)
	for id in _list_btns:
		UI.set_kind(_list_btns[id], UI.KIND_LIT if id == _pick else UI.KIND_MAIN)
	if not _busy and _arm_t <= 0.0:
		UI.set_enabled(_undo_btn, Trip.can_undo())
	UI.set_kind(_done_btn, UI.KIND_LIT if left <= 0 or not spending else UI.KIND_MAIN)

func _on_pick(id: String) -> void:
	_pick = id
	_refresh_points()

func _on_plus(stat: String) -> void:
	if Trip.spend(_pick, stat):
		_stat("points_spent")
		if audio != null:
			audio.play(_point_sfx, -4.0)
	_refresh_points()

func _on_undo() -> void:
	if Trip.undo_spend():
		_stat("points_undo")
	_refresh_points()

func _on_done() -> void:
	_stat("points_done")
	var was_points: bool = Trip.phase == "points"
	Trip.finish_points()
	if was_points:
		_go(Trip.resume_screen())   # recruit, or the map when nobody is left to recruit
	elif _then != "":
		_go(_then, _then_args)
	else:
		_go(Trip.resume_screen() if Trip.active else "title")

# ---------------- trip test ----------------

# result: RETRY / NEXT. points: one point on the lowest stat of the first player that can take one, then DONE.
func auto_step() -> bool:
	if _busy:
		return false
	_arm_t = 0.0
	if str(Flow.screen) == "points":
		for id in Trip.roster_ids():
			var best := ""
			var low: int = 1000
			var r: Dictionary = Trip.roster_player(str(id)).get("ratings", {})
			for s in STATS:
				var key: String = str(s[0])
				if Trip.can_spend(str(id), key) and int(r.get(key, 0)) < low:
					low = int(r.get(key, 0))
					best = key
			if best != "":
				_pick = str(id)
				_on_plus(best)
				return true
		_on_done()
		return true
	_default_tap.call()
	return true


# a stat bar: filled to the rating, with a gold line at the cap
class StatBar extends Control:
	var value := 0

	func _draw() -> void:
		var sz: Vector2 = size
		draw_rect(Rect2(Vector2.ZERO, sz), BAR_BG)
		var f: float = clampf(float(value) / BAR_MAX, 0.0, 1.0)
		var capped: bool = value >= Trip.STAT_CAP
		draw_rect(Rect2(Vector2.ZERO, Vector2(sz.x * f, sz.y)), BAR_CAP if capped else BAR_FILL)
		var cx: float = sz.x * float(Trip.STAT_CAP) / BAR_MAX
		draw_line(Vector2(cx, -4), Vector2(cx, sz.y + 4), BAR_CAP, 3.0)
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.6, 0.75, 1.0, 0.8), false, 2.0)
