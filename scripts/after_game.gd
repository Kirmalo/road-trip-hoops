extends CanvasLayer
# After a trip game (P5-12): one script for two Flow screens, built in code with ui_kit.gd.
#   result  the final score, WIN / LOSS, "HOMETOWN - GAME 2 OF 3" (or the tournament round), the points each starter
#           won (P8-12: "+1 STAT POINT EACH: JOJO, TANK, DEUCE"; a replay pays stars only), the game's stars (NEW STAR
#           / NEW BEST, the total n/72; sound "star"), any star reward just unlocked (sound "unlock") and a small
#           stats table for both crews. A loss: RETRY (the same game again, after the "first_loss" scene the
#           first time). A win: NEXT (the next game, or the city's "won" scene and then the points screen).
#           Where it goes is trip.gd's after_result(); a won tournament round with points to spend goes to the
#           points screen first and then back to the bracket.
#   points  stat points: a player picker (each with his own points), the picked player's 5 stats with a +3 button
#           each (cap 90 shown), his points and the crew points (anyone may use them), UNDO (the last point, until
#           DONE) and DONE. Two modes (P8-12):
#           - per win (Trip.phase "win_points", args.then "lineup", or args.per_win after a won New York round): only
#             the 3 starters who just earned points, and SKIP (it reads DONE once a point is spent or none is left);
#             unspent points are kept (the lineup's badge reopens the screen). DONE / SKIP = Trip.finish_points(),
#             then args.then (or where CONTINUE would go).
#           - city end (phase "points") or from anywhere else: the whole roster (scrolls). DONE after a city = the
#             recruit screen (Trip.finish_points() / resume_screen()); otherwise args.then ("bracket", ...).
#           Reachable from anywhere as Flow.go("points", {"then": "bracket"}).
# Every button ignores taps for ARM_TIME after the screen opens (the tap that ended the game, or the last tap on the
# screen before, can't fall through) and once a Flow.go() is on its way.
# Desktop testing: Enter = the lit button (RETRY / NEXT / DONE), Backspace = UNDO.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Cities = preload("res://scripts/cities.gd")
const Trip = preload("res://scripts/trip.gd")
const Ratings = preload("res://scripts/ratings.gd")
const Stars = preload("res://scripts/stars.gd")
const Cosmetics = preload("res://scripts/cosmetics.gd")   # the reward names (item_name)

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
const RESULT_GAP := 6                      # px between the result rows (they must fit 720 with stars and rewards)
const RESULT_BTN := Vector2(300, 120)      # NEXT / RETRY (a bit lower than UI.BUTTON_SIZE, so everything fits 720)
const TABLE_PAD_V := 12                    # px: the stats panel's top and bottom padding (UI.PANEL_PAD on the sides)
const STAR_COLOR := Color(1.0, 0.82, 0.25) # a star won (gold)
const STAR_NEW_COLOR := Color(1.0, 0.95, 0.6)    # a star won just now, while it pops in
const STAR_NEW_EDGE := Color(1.0, 1.0, 1.0)      # a star won just now keeps a white edge
const STAR_EMPTY := Color(0.22, 0.24, 0.3) # a star not won yet
const STAR_EDGE := Color(0.03, 0.03, 0.06)
const STAR_PX := 46.0                      # one star's box (px)
const STAR_GAP := 8.0
const STAR_POP_DELAY := 0.15               # s before the first new star pops in
const STAR_POP_STEP := 0.15                # s between new stars
const STAR_POP_TIME := 0.25                # s one star takes to pop (overshoots a little)
const STAR_SFX := "star"                   # assets/sfx/star.ogg: a new star / new best
const STAR_SFX_AT := 0.2                   # s after the result opens
const UNLOCK_SFX := "unlock"               # assets/sfx/unlock.ogg: a star reward unlocked
const UNLOCK_SFX_AT := 0.9                 # s after the result opens (after the star sound)
const UNLOCK_COLOR := Color(0.55, 0.85, 1.0)
const LEVEL_FOR_STARS := ["", "EASY", "NORMAL", "HARD"]   # the level that gives n stars (the "win on" hint)
const REWARD_KIND_NAMES := {"slot": "ROSTER SLOT", "jersey": "JERSEY", "ball": "BALL", "van": "VAN PAINT",
		"court": "QUICK GAME COURT", "legend": "LEGEND LEVEL"}
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
const LIST_FONT := 30                      # a list button: the name, then "2 POINTS" under it
const LIST_NOTE_FONT := 22                 # the note under the per-win list
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
var _t := 0.0               # s since the screen opened (the sounds' timing)
var _star_sfx_due := false
var _unlock_sfx_due := false

# points
var _then := ""
var _then_args := {}
var _pick := ""             # roster id being raised
var _left_label: Label
var _undo_btn: Button
var _done_btn: Button
var _per_win := false       # per-win mode: the 3 starters and SKIP (see the top)
var _ids: Array = []        # the players listed
var _spent_here := 0        # points spent on this screen (SKIP reads DONE after one)
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
	_t += delta
	if _star_sfx_due and _t >= STAR_SFX_AT:
		_star_sfx_due = false
		if audio != null:
			audio.play(STAR_SFX, -2.0, 0.0)
	if _unlock_sfx_due and _t >= UNLOCK_SFX_AT:
		_unlock_sfx_due = false
		if audio != null:
			audio.play(UNLOCK_SFX, -2.0, 0.0)
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
	var box := UI.vbox(_root, RESULT_GAP)
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
	var pl: String = points_line(_outcome)
	if pl != "":
		UI.label(box, pl, UI.SUB_FONT, POINTS_COLOR if _won else NOTE_COLOR)
	if _won and str(_outcome.get("star_key", "")) != "":
		_stars_row(box)
	_stats_table(box, res, mine, theirs)
	var brow := UI.hbox(box)
	if _won:
		_default_tap = _on_next
		_default = _btn(brow, "NEXT", _on_next, UI.KIND_LIT, RESULT_BTN)
	else:
		_default_tap = _on_retry
		_default = _btn(brow, "RETRY", _on_retry, UI.KIND_LIT, RESULT_BTN)
	_stat("result_" + ("win" if _won else "loss"))

# The result's points line: "+1 STAT POINT EACH: JOJO, TANK, DEUCE  (5 to spend)" (points_each, per starter); a
# replay "REPLAY: STARS ONLY"; a loss "No penalty: run it back!"; "" when a win paid nothing (paid before).
static func points_line(o: Dictionary) -> String:
	if not bool(o.get("won", false)):
		return "No penalty: run it back!"
	var each: int = int(o.get("points_each", 0))
	if each <= 0:
		return "REPLAY: STARS ONLY" if bool(o.get("replay", false)) else ""
	var names: Array = []
	for id in Trip.starters:
		names.append(str(Cities.player(str(id)).get("name", id)))
	var who: String = (": " + ", ".join(PackedStringArray(names))) if names.size() > 0 else ""
	return "+%d STAT POINT%s EACH%s  (%d to spend)" % [each, "" if each == 1 else "S", who, Trip.points]

# The result's star texts for a won game: [main line, its color, the total line]. A new best: "+2 NEW STARS!" (the
# game's first win) or "NEW BEST: 3 STARS!"; else "BEST: 2 STARS" and the level that gives one more.
static func star_lines(o: Dictionary) -> Array:
	var best: int = clampi(int(o.get("stars_game", 0)), 0, 3)
	var gained: int = clampi(int(o.get("stars_gained", 0)), 0, 3)
	var main_line := ""
	var col: Color = NOTE_COLOR
	if bool(o.get("new_best", false)) and gained > 0:
		col = STAR_COLOR
		if best - gained <= 0:
			main_line = "+%d NEW STAR%s!" % [gained, "" if gained == 1 else "S"]
		else:
			main_line = "NEW BEST: %d STARS!" % best
	else:
		main_line = "BEST: %d STAR%s" % [best, "" if best == 1 else "S"]
		if best < 3:
			main_line += "  (win on %s for %d)" % [str(LEVEL_FOR_STARS[best + 1]), best + 1]
	var total_line: String = "STARS %d/%d" % [int(o.get("stars_now", Stars.total())), Stars.MAX]
	return [main_line, col, total_line]

# The rewards the game's stars unlocked ("ROSTER SLOT 1", "JERSEY: HOME WHITES", "LEGEND LEVEL"), in ladder order.
static func reward_names(o: Dictionary) -> Array:
	var out: Array = []
	var a: int = int(o.get("stars_before", 0))
	var b: int = int(o.get("stars_now", a))
	if b <= a:
		return out
	for r in Stars.rewards_between(a, b):
		var kind: String = str((r as Dictionary).get("kind", ""))
		var id: String = str((r as Dictionary).get("id", ""))
		var kn: String = str(REWARD_KIND_NAMES.get(kind, kind.to_upper()))
		if kind == "slot":
			out.append("%s %s" % [kn, id.get_slice("_", 1)])
		elif kind == "legend":
			out.append(kn)
		else:
			var nm: String = Cosmetics.item_name(id)
			out.append(("%s: %s" % [kn, nm]) if nm != "" else kn)
	return out

# a win: the stars row (3 stars, the new ones pop in; the star line; the total) and the rewards line, with sounds
func _stars_row(box: Control) -> void:
	var lines: Array = star_lines(_outcome)
	var row := UI.hbox(box, 20)
	var sr := StarRow.new()
	sr.filled = clampi(int(_outcome.get("stars_game", 0)), 0, 3)
	sr.fresh = clampi(int(_outcome.get("stars_gained", 0)), 0, sr.filled) if bool(_outcome.get("new_best", false)) \
			else 0
	sr.custom_minimum_size = Vector2(STAR_PX * 3.0 + STAR_GAP * 2.0, STAR_PX)
	sr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sr)
	var col: Color = lines[1]
	UI.label(row, str(lines[0]), UI.OPT_FONT, col)
	UI.label(row, str(lines[2]), UI.SUB_FONT, NOTE_COLOR)
	if sr.fresh > 0:
		_star_sfx_due = true
		_stat("result_new_star")
	var rw: Array = reward_names(_outcome)
	if not rw.is_empty():
		UI.label(box, "UNLOCKED: " + ",  ".join(PackedStringArray(rw)), UI.OPT_FONT, UNLOCK_COLOR)
		_unlock_sfx_due = true
		_stat("result_unlock")

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
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		sb.content_margin_top = TABLE_PAD_V
		sb.content_margin_bottom = TABLE_PAD_V
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
	# a won tournament round (not the final, not a replay: P8-17): spend the round's points first, then the bracket
	if bool(o.get("won", false)) and not bool(o.get("replay", false)) and Trip.is_tournament(str(o.get("city", ""))) \
			and not bool(o.get("trip_done", false)) \
			and Trip.points > 0 and Trip.SPEND_PHASES.has(Trip.phase):
		_go("points", {"then": "bracket", "per_win": true})
		return
	_follow_trip()

func _follow_trip() -> void:
	if not Trip.active:
		_go("title")   # no trip loaded (should not happen in the flow)
		return
	var r: Dictionary = Trip.after_result()
	_go(str(r.get("screen", "map")), r.get("args", {}))

# ---------------- points ----------------

# per-win mode (see the top): right after a won city game 1-2 (phase "win_points"; its "then" is the lineup), or
# after a won New York round (args.per_win, set by _on_next)
static func is_per_win(a: Dictionary) -> bool:
	if Trip.phase == "points":
		return false   # the city-end screen (then the recruit)
	return Trip.phase == "win_points" or str(a.get("then", "")) == "lineup" or bool(a.get("per_win", false))

func _build_points() -> void:
	var a: Dictionary = Flow.args
	_then = str(a.get("then", ""))
	var ta = a.get("then_args", {})
	_then_args = ta if ta is Dictionary else {}
	_per_win = is_per_win(a)
	if ResourceLoader.exists("res://assets/sfx/" + POINT_SFX_NEW + ".ogg"):
		_point_sfx = POINT_SFX_NEW
	_ids = []
	if _per_win:
		for id in Trip.starters:
			if Trip.roster_ids().has(str(id)):
				_ids.append(str(id))
	if _ids.is_empty():
		_per_win = false
		_ids = Trip.roster_ids()
	_pick = Trip.human if _ids.has(Trip.human) else (str(_ids[0]) if _ids.size() > 0 else "")
	if _per_win and Trip.player_points(_pick) <= 0:
		for id in _ids:
			if Trip.player_points(str(id)) > 0:
				_pick = str(id)   # open on a starter who has points of his own
				break
	# header: title and points left on the left, UNDO and DONE (SKIP) on the right
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
	_done_btn = _btn(head, "SKIP" if _per_win else "DONE", _on_done, UI.KIND_MAIN, Vector2(240, 110))
	_done_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_default = _done_btn
	_default_tap = _on_done
	# left: the players (the 3 starters, or the roster: scrolls with more than 5)
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
	for id in _ids:
		var b: Button = _btn(list, "", _on_pick.bind(str(id)), UI.KIND_MAIN, LIST_BTN)
		b.add_theme_font_size_override("font_size", LIST_FONT)
		b.mouse_filter = Control.MOUSE_FILTER_PASS   # a drag on a name still scrolls the list
		_list_btns[str(id)] = b
	if _per_win:
		var note: Label = UI.label(list, "Points you skip are kept:\nspend them from the lineup.", LIST_NOTE_FONT,
				NOTE_COLOR)
		note.custom_minimum_size = Vector2(LIST_BTN.x, 80)
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
	_stat("points_screen_win" if _per_win else "points_screen")

# "2 POINTS" / "1 POINT" / "NO POINTS"
static func points_text(n: int) -> String:
	if n <= 0:
		return "NO POINTS"
	return "%d POINT%s" % [n, "" if n == 1 else "S"]

# true when one more point can go anywhere on the listed players
func _can_spend_any() -> bool:
	for id in _ids:
		for s in STATS:
			if Trip.can_spend(str(id), str(s[0])):
				return true
	return false

# the header line: the picked player's own points and the crew points (anyone's)
func _points_header() -> String:
	var spending: bool = Trip.active and Trip.SPEND_PHASES.has(Trip.phase)
	if not spending:
		return "Points are spent after a win, between games or between tournament rounds."
	var own: int = Trip.player_points(_pick)
	var crew: int = Trip.crew_points
	var nm: String = str(Cities.player(_pick).get("name", _pick))
	if own + crew <= 0 and not _can_spend_any():
		return "No points left. Tap DONE."
	var line: String = "%s: %s" % [nm, points_text(own)]
	if crew > 0:
		line += "   CREW POINTS: %d (anyone)" % crew
	return line + "   (+%d each, max %d)" % [Trip.POINT_GAIN, Trip.STAT_CAP]

func _refresh_points() -> void:
	var spending: bool = Trip.active and Trip.SPEND_PHASES.has(Trip.phase)
	_left_label.text = _points_header()
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
		var b: Button = _list_btns[id]
		b.text = "%s\n%s" % [str(Cities.player(str(id)).get("name", id)), points_text(Trip.player_points(str(id)))]
		UI.set_kind(b, UI.KIND_LIT if id == _pick else UI.KIND_MAIN)
	if not _busy and _arm_t <= 0.0:
		UI.set_enabled(_undo_btn, Trip.can_undo())
	var finished: bool = not spending or not _can_spend_any()
	if _per_win:
		_done_btn.text = "DONE" if finished or _spent_here > 0 else "SKIP"
	UI.set_kind(_done_btn, UI.KIND_LIT if finished else UI.KIND_MAIN)

func _on_pick(id: String) -> void:
	_pick = id
	_refresh_points()

func _on_plus(stat: String) -> void:
	if Trip.spend(_pick, stat):
		_spent_here += 1
		_stat("points_spent")
		if audio != null:
			audio.play(_point_sfx, -4.0)
		if _per_win and Trip.player_points(_pick) <= 0 and Trip.crew_points <= 0:
			for id in _ids:
				if Trip.player_points(str(id)) > 0:
					_pick = str(id)   # his points are gone: on to the next starter who has some (one tap less)
					break
	_refresh_points()

func _on_undo() -> void:
	if Trip.undo_spend():
		_spent_here = maxi(_spent_here - 1, 0)
		_stat("points_undo")
	_refresh_points()

func _on_done() -> void:
	if _per_win and _spent_here == 0 and _can_spend_any():
		_stat("points_skip")
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

# result: RETRY / NEXT. points: one point on the lowest stat of the first listed player that can take one (per win:
# the starters), then DONE.
func auto_step() -> bool:
	if _busy:
		return false
	_arm_t = 0.0
	if str(Flow.screen) == "points":
		for id in _ids:
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


# the result's 3 stars: filled = the game's best, the last `fresh` of them were won just now (they pop in)
class StarRow extends Control:
	var filled := 0
	var fresh := 0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t > STAR_POP_DELAY + STAR_POP_STEP * 3.0 + STAR_POP_TIME:
			set_process(false)

	func _draw() -> void:
		for i in 3:
			var c := Vector2(STAR_PX * 0.5 + float(i) * (STAR_PX + STAR_GAP), STAR_PX * 0.5)
			var col: Color = STAR_COLOR if i < filled else STAR_EMPTY
			var sc := 1.0
			var edge_col: Color = STAR_EDGE
			var first_new: int = filled - fresh
			if i >= first_new and i < filled:
				var u: float = (_t - STAR_POP_DELAY - STAR_POP_STEP * float(i - first_new)) / STAR_POP_TIME
				if u <= 0.0:
					col = STAR_EMPTY   # not popped yet
				else:
					edge_col = STAR_NEW_EDGE
					if u < 1.0:
						sc = 1.0 + 0.35 * sin(u * PI)   # grows past full size and settles
						col = STAR_NEW_COLOR
			_star(c, STAR_PX * 0.5 * sc, col, edge_col)

	func _star(c: Vector2, r: float, col: Color, edge_col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 10:
			var rr: float = r if k % 2 == 0 else r * 0.45
			var ang: float = -PI * 0.5 + float(k) * PI / 5.0
			pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
		draw_colored_polygon(pts, col)
		var edge := pts.duplicate()
		edge.append(pts[0])
		draw_polyline(edge, edge_col, 3.0, true)


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
