extends CanvasLayer
# Lineup screen (P5-11, Flow screen "lineup"): pick your 3 starters before every trip game. Built in code (ui_kit.gd).
#   Left: your roster (the 3 underdogs + recruits, up to about 10) as big cards in a scrolling list: idle sprite in
#   your colors, name, number and role, the 5 stat bars. Tap a card to put him in the lineup; the FIRST one you pick
#   is the one you control (badge YOU), the others get 2 and 3. Tap a starter again to bench him (the ones after him
#   move up). With 3 picked, a tap on a bench player says to bench one first.
#   Right: the crew you face (their 3 for this game, from Trip.match_for()) and PLAY.
#   A replay (P8-17, Trip.replaying()): the label reads "REPLAY - ..." plus STARS ONLY; BACK cancels it (the map).
#   PLAY: Trip.set_starters(picks, picks[0]) (saved, so the lineup is remembered for the next game), then
#   Trip.match_for() builds Flow.match and the game starts. BACK: the map (New York: the bracket).
# Phase 8 (P8-18):
#   - Stat points: a gold badge ("2 PTS") bottom-left on every card with points of his own, and a gold STAT POINTS
#     card first in the list when anyone has points or there are crew points (it names who has some and the crew
#     points). Tapping the badge (or that card) opens the points screen in its per-win mode with args.ids = the
#     tapped player and the others with points (the save's starters never change); its then_args bring back the
#     picks here (arg "picks").
#   - Roster slots: one OPEN SLOT card per Trip.open_slots() after the roster (tap = the draft, back to here), then
#     one locked card for the next star slot ("OPENS AT 24 STARS"); drafted players carry a DRAFTED tag.
#   Leaving for the draft keeps a full lineup (Trip.set_starters, like PLAY).
# One boss in the starting three (P8-14b, owner): boss cards carry a BOSS tag; tapping a second boss flashes
# Trip.BOSS_RULE and doesn't pick him; PLAY stays off until Trip.starters_ok() is happy. After a load that benched
# boss starters (Trip.boss_repair), the hint line shows Trip.boss_repair_note() until the first tap.
# One legend in the starting three (P9-22, Trip.LEGEND_LIMIT): legend cards carry a LEGEND tag (era colour, gold) in
# the same place; tapping a second legend flashes Trip.LEGEND_RULE and doesn't pick him. A legend is not a boss, so one
# legend and one boss may start together. P10-19: the limit counts every chapter together (a Grandfather and a Father
# never start together; the flash names the one already picked); each tag is in its own chapter's colour.
# P11-19: three eras, nothing new in the logic: a Grandfather, a Father or a Present legend starts, never two of them,
# and each one's tag takes his chapter's ui_color from the data (the Present's teal).
# P12-19: four eras the same way: a New Generation legend's tag is Chapter 4's darker lime (#466e14); one legend of
# any of the four starts.
# Drag the list (or its wide scroll bar) to scroll; a drag never counts as a tap. Taps are ignored for ARM_T s when the
# screen opens and once PLAY is on its way, so nothing leaks into the next screen or the game.
# Desktop testing: Enter = PLAY, Escape = BACK. Trip test: auto_step() keeps the lineup and taps PLAY;
# tap_player(id) is the card tap (the trip test's pick check uses it); tap_badge(id), tap_points_card() and
# tap_open_slot() are the new taps for test drivers.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Cities = preload("res://scripts/cities.gd")
const Sheets = preload("res://scripts/sheets.gd")   # cards: v2 card / v2 sheet / v1 sheet (P6-06)
const Stars = preload("res://scripts/stars.gd")     # P8-18: the star count of the next roster slot

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
const SHEET_FRAME := Vector2(40, 64)     # the layout box of a card sprite (a v1 frame); Sheets.card_rect() fits v2
const FALLBACK_SHEETS := ["ud_jojo", "ny_q2"]  # when a player's own sheet is missing (yours / theirs): Quick Game's
                                               # slot-0 sheets (player.gd QUICK_SHEETS; the v1 blue_1 / red_1 are gone)
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
const SUB_MIN_FONT := 13                 # P10-19: a card's number + role line shrinks down to this to clear the badge
const SUB_BADGE_GAP := 8.0               # px between that line and the badge
const DIM_TEXT := Color(0.7, 0.72, 0.78)
const HINT_COLOR := Color(0.85, 0.87, 0.92)
const WARN_COLOR := Color(1.0, 0.6, 0.35)
const THEIR_RING := Color(0.85, 0.16, 0.23)   # the opponents' ring is always red (owner Q11 a)
const STAT_NAMES := [["speed", "SPD"], ["shooting", "SHT"], ["finishing", "FIN"], ["defense", "DEF"],
		["stamina", "STA"]]
const TIER_TEXT := {"start": "", "avg": "", "good": "GOOD", "boss": "BOSS", "legend": "LEGEND"}
# P8-18: points badge, STAT POINTS card, slot cards, DRAFTED tag
const PTS_BADGE := Rect2(8, 128, 96, 44)   # px in a card: the gold "2 PTS" badge, bottom-left over the sprite's feet
const PTS_ZONE := Rect2(0, 108, 128, 76)   # px in a card: a tap here (badge shown) opens the points screen
const PTS_FONT := 22
const PTS_COLOR := Color(1.0, 0.82, 0.25)   # gold (UI.LIT_COLOR)
const DRAFTED_TAG := Rect2(8, 6, 96, 24)  # px in a card: the DRAFTED tag, top-left over the sprite's head
const DRAFTED_FONT := 16
const DRAFTED_COLOR := Color(0.55, 0.85, 1.0)
const BOSS_TAG := Rect2(8, 6, 72, 24)     # px in a card: the BOSS tag, top-left (a drafted boss: DRAFTED goes below it)
const BOSS_TAG_FILL := Color(0.42, 0.08, 0.1, 0.97)
const BOSS_TAG_COLOR := Color(1.0, 0.82, 0.25)
const TAG_GAP := 4.0                       # px between the BOSS and DRAFTED tags
const LEGEND_TAG := Rect2(8, 6, 88, 24)   # P9-22: px in a card: the LEGEND tag, top-left (DRAFTED goes below it)
const LEGEND_TAG_FILL := Color(0.77, 0.35, 0.16, 0.97)   # when his chapter has no ui_color (the Grandfathers' rust)
const LEGEND_TAG_COLOR := Color(1.0, 0.82, 0.25)
const LEGEND_TAG_TEXT := "LEGEND"
const NOTE_MIN_FONT := 16                  # the repair note shrinks down to this to fit its one line
const POINTS_CARD_FILL := Color(0.26, 0.21, 0.07, 0.97)
const SLOT_FILL := Color(0.08, 0.14, 0.26, 0.95)       # an OPEN SLOT card
const LOCKED_FILL := Color(0.08, 0.09, 0.12, 0.9)      # the next locked slot
const LOCKED_TEXT := Color(0.55, 0.57, 0.63)
const SLOT_TITLE_FONT := 34
const SLOT_PLUS_R := 34.0                  # the "+" circle on an OPEN SLOT card
const STAR_COLOR := Color(1.0, 0.82, 0.25)
const STAR_R := 22.0                       # the star drawn on the locked slot card
const POINTS_NAMES_MAX := 3                # names listed on the STAT POINTS card (then "+n more")
const REPLAY_NOTE := "  STARS ONLY"     # P8-17: after FIRST TO n on a replay (its label starts "REPLAY - ")
const PICKS_ARG := "picks"                 # args back from the points screen (see the top)
const STARTERS_ARG := "starters"
const HUMAN_ARG := "human"

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
var _tex := {}               # "sheet/team" -> Sheets.card_info() ({} = a silhouette) (cache)
var _drafted: Array = []     # Trip.drafted_ids() (the DRAFTED tag)
var _points_card: Control = null   # the STAT POINTS card (null = nobody has points)
var _pool_any := false       # someone can be drafted (the OPEN SLOT card's line)
var _note := ""              # P8-14b: the boss repair note (shown on the hint line until the first tap)

func _ready() -> void:
	if not Trip.active:
		Trip.continue_trip()   # a reload straight onto the lineup: the save is the truth
	var a: Dictionary = Flow.args if str(Flow.screen) == "lineup" else {}
	var back_starters = a.get(STARTERS_ARG, null)
	if Trip.active and back_starters is Array:
		Trip.set_starters(back_starters, str(a.get(HUMAN_ARG, "")))   # back from the points screen: the real lineup
	_roster = Trip.roster()
	_match = Trip.match_for() if Trip.active else {}
	var ids: Array = Trip.roster_ids()
	var back_picks = a.get(PICKS_ARG, null)
	var want: Array = back_picks if back_picks is Array else Trip.starters
	for id in want:
		if ids.has(str(id)) and not _picks.has(str(id)) and _picks.size() < Trip.STARTERS:
			_picks.append(str(id))
	_drafted = Trip.drafted_ids() if Trip.active else []
	_note = Trip.boss_repair_note() if Trip.active else ""
	Trip.boss_repair = []   # shown once
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
	print("LINEUP screen | roster %d, picks %s | points %d (crew %d) | slots %d, open %d, drafted %s%s" % [
			_roster.size(), str(_picks), Trip.points, Trip.crew_points, Trip.slot_count(), Trip.open_slots(),
			str(_drafted), (" | note: " + _note) if _note != "" else ""])

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
	if bool(_match.get("replay", false)):
		sub += REPLAY_NOTE
	var lbl := UI.subtitle(_frame, sub, UI.LIT_COLOR)
	lbl.position = SIDE_POS - Vector2(0, SIDE_POS.y - HEAD_Y)
	lbl.size = Vector2(SIDE_SIZE.x, SIDE_POS.y - HEAD_Y - 6.0)
	_fit_font(lbl, SIDE_SIZE.x - 16.0, Vector2(SIDE_SIZE.x, SIDE_POS.y - HEAD_Y - 6.0))
	_hint = UI.label(_frame, "", SMALL_FONT + 4, HINT_COLOR)
	_hint.position = Vector2(HINT_X, HINT_Y)
	_hint.size = Vector2(LIST_POS.x + LIST_SIZE.x - HINT_X, 36)

# shrinks a label's font until its longest line fits max_w (long match labels such as "NEW YORK - QUARTERFINAL" or
# "REPLAY - CHICAGO - GAME 1 OF 3"), then puts the label back into box. P8-B3: a label grows to its text's width at
# the first font size and never shrinks by itself, so the centred text ended up drawn ~40 px to the right.
static func _fit_font(lbl: Label, max_w: float, box: Vector2 = Vector2.ZERO) -> void:
	var ls: LabelSettings = lbl.label_settings
	var font: Font = ls.font if ls.font != null else lbl.get_theme_font("font")
	if font == null:
		return
	while ls.font_size > 14:
		var widest: float = 0.0
		for line in lbl.text.split("\n"):
			widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, ls.font_size).x)
		if widest + 2.0 * ls.outline_size <= max_w:
			break
		ls.font_size -= 2
	if box != Vector2.ZERO:
		lbl.size = box
		lbl.set_deferred("size", box)   # again once the label has redone its minimum size at the new font size

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
	if can_spend_now():
		_points_card = _add_card(grid, "points", {})
	for p in _roster:
		var c: Control = _add_card(grid, "player", p)
		c.set("tex", _sheet(str(p.get("sheet", "")), 0))
	if Trip.active:
		_pool_any = Trip.open_slots() > 0 and Trip.draft_pool().size() > 0
		for i in Trip.open_slots():
			_add_card(grid, "open", {})
		if next_slot_at() > 0:
			_add_card(grid, "locked", {})

func _add_card(grid: Control, kind: String, p: Dictionary) -> Control:
	var c := Card.new()
	c.screen = self
	c.kind = kind
	c.p = p
	c.custom_minimum_size = CARD_SIZE
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	grid.add_child(c)
	_cards.append(c)
	return c

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

# a card ({} = draw a silhouette): the player's own, without _crew, then the team's fallback sheet (Sheets.card_first)
func _sheet(sheet: String, team: int) -> Dictionary:
	var key: String = "%s/%d" % [sheet, team]
	if _tex.has(key):
		return _tex[key]
	var tries: Array = Sheets.with_base(sheet) if sheet != "" else []
	tries.append(FALLBACK_SHEETS[team])
	var out: Dictionary = Sheets.card_first(tries)
	_tex[key] = out
	return out

# ---------------- state ----------------

func _refresh() -> void:
	var full: bool = _picks.size() == Trip.STARTERS
	UI.set_enabled(_play, full and lineup_ok() and _arm_t <= 0.0 and not _busy)
	UI.set_enabled(_back, _arm_t <= 0.0 and not _busy)
	_hint.label_settings.font_size = SMALL_FONT + 4
	if _hint_t > 0.0:
		_hint.label_settings.font_color = WARN_COLOR
	elif _note != "":
		_hint.label_settings.font_color = WARN_COLOR
		_hint.text = _note
		_fit_line(_hint, _hint.size.x)
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

# shrinks a one-line label's font (down to NOTE_MIN_FONT) until its text fits max_w
static func _fit_line(lbl: Label, max_w: float) -> void:
	var ls: LabelSettings = lbl.label_settings
	var font: Font = ls.font if ls.font != null else lbl.get_theme_font("font")
	if font == null:
		return
	while ls.font_size > NOTE_MIN_FONT:
		var w: float = font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ls.font_size).x
		if w + 2.0 * ls.outline_size <= max_w:
			return
		ls.font_size -= 1

# the badge of a roster player: 0 = bench, 1 = YOU, 2, 3
func slot_of(id: String) -> int:
	return _picks.find(id) + 1

# the picks are a legal lineup (3 different roster players, one boss at most: Trip.starters_ok)
func lineup_ok() -> bool:
	return Trip.starters_ok(_picks) == ""

# the boss already picked when `id` is a second one ("" = he may be picked)
func boss_in_the_way(id: String) -> String:
	if not Trip.is_boss(id):
		return ""
	for e in _picks:
		if str(e) != id and Trip.is_boss(str(e)):
			return str(e)
	return ""

# P9-22: the legend already picked when `id` is a second one ("" = he may be picked)
func legend_in_the_way(id: String) -> String:
	if not Trip.is_legend(id):
		return ""
	for e in _picks:
		if str(e) != id and Trip.is_legend(str(e)):
			return str(e)
	return ""

# P9-22: a legend's tag colour: his chapter's ui_color (legends_data.gd), else LEGEND_TAG_FILL (P10-19: the same
# colour as his chapter's LEGENDS row on the DRAFT screen, Trip.chapter_color())
static func legend_color(id: String) -> Color:
	var ch: String = Trip.LegendsData.chapter_of(id)
	var c = (Trip.LegendsData.chapter(ch).get("crew", {}) as Dictionary).get("ui_color", null)
	return Color(Trip.chapter_color(ch), LEGEND_TAG_FILL.a) if c is Color else LEGEND_TAG_FILL

# a tap on a roster card (also the trip test's tap)
func tap_player(id: String) -> void:
	if _busy:
		return
	_note = ""
	var other: String = boss_in_the_way(id) if not _picks.has(id) else ""
	var other_legend: String = legend_in_the_way(id) if not _picks.has(id) else ""
	if _picks.has(id):
		_picks.erase(id)
		_stat("lineup_bench")
	elif other != "":
		_stat("lineup_boss_refused")
		_flash("%s. Bench %s first." % [Trip.BOSS_RULE, _name_of(other)])
		print("LINEUP %s refused: %s (%s already starts)" % [id, Trip.BOSS_RULE, other])
		return
	elif other_legend != "":
		_stat("lineup_legend_refused")
		_flash("%s. Bench %s first." % [Trip.LEGEND_RULE, _name_of(other_legend)])
		print("LINEUP %s refused: %s (%s already starts)" % [id, Trip.LEGEND_RULE, other_legend])
		return
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

# a tap on a card of any kind (Card._gui_input); at = the press point in the card
func _on_card_tap(c: Control, at: Vector2) -> void:
	if _arm_t > 0.0 or _busy:
		return
	var kind: String = str(c.get("kind"))
	var id: String = str((c.get("p") as Dictionary).get("id", ""))
	match kind:
		"points":
			tap_points_card()
		"open":
			tap_open_slot()
		"locked":
			_flash("This slot opens at %d stars (you have %d). Win games on a higher level for more stars." % [
					next_slot_at(), Stars.total()])
		_:
			if has_badge(id) and PTS_ZONE.has_point(at):
				tap_badge(id)
			else:
				tap_player(id)

func _flash(text: String) -> void:
	_hint.text = text
	_hint_t = HINT_FLASH
	_refresh()

# ---------------- stat points (P8-18) ----------------

# true when points can be spent from here (a trip in a spending phase with any point left)
static func can_spend_now() -> bool:
	return Trip.active and Trip.SPEND_PHASES.has(Trip.phase) and Trip.points > 0

# the gold badge: his own points, while they can be spent
func has_badge(id: String) -> bool:
	return Trip.player_points(id) > 0 and can_spend_now()

# the players on the STAT POINTS card: [[name, points], ...] in roster order
func points_list() -> Array:
	var out: Array = []
	for p in _roster:
		var n: int = Trip.player_points(str(p.get("id", "")))
		if n > 0:
			out.append([str(p.get("name", "")), n])
	return out

# the 3 the points screen lists: `focus` first, then everyone else with points of his own, then the picks here, then
# the saved starters, then the roster
func spend_group(focus: String) -> Array:
	var out: Array = []
	var order: Array = [focus]
	for p in _roster:
		if Trip.player_points(str(p.get("id", ""))) > 0:
			order.append(str(p.get("id", "")))
	order.append_array(_picks)
	order.append_array(Trip.starters)
	order.append_array(Trip.roster_ids())
	var ids: Array = Trip.roster_ids()
	for e in order:
		var id: String = str(e)
		if id != "" and ids.has(id) and not out.has(id) and out.size() < Trip.STARTERS:
			out.append(id)
	return out

# the badge tap: the points screen (per-win mode) on this player, then back here with the same picks. False when
# it can't open.
func tap_badge(id: String) -> bool:
	if _busy or not can_spend_now():
		return false
	var group: Array = spend_group(id)
	var back := {PICKS_ARG: _picks.duplicate()}
	if group.is_empty():
		return false
	if audio != null:
		audio.play("bounce", -4.0)
	_stat("lineup_points")
	_go("points", {"then": "lineup", "then_args": back, "per_win": true, "ids": group})
	return true

# the STAT POINTS card: the first player with points of his own (else you), see tap_badge()
func tap_points_card() -> bool:
	var focus: String = str(_picks[0]) if _picks.size() > 0 else Trip.human
	for p in _roster:
		if Trip.player_points(str(p.get("id", ""))) > 0:
			focus = str(p.get("id", ""))
			break
	return tap_badge(focus)

# ---------------- roster slots (P8-18) ----------------

# the stars the next star slot opens at (0 = every slot is open)
static func next_slot_at() -> int:
	var t: int = Stars.total()
	for r in Stars.REWARDS:
		if str(r["kind"]) == "slot" and int(r["at"]) > t:
			return int(r["at"])
	return 0

# the star counts of the slots still locked after the next one ("36, 48")
static func later_slots_text() -> String:
	var t: int = Stars.total()
	var ats: Array = []
	for r in Stars.REWARDS:
		if str(r["kind"]) == "slot" and int(r["at"]) > t:
			ats.append(str(r["at"]))
	ats.pop_front()
	return ", ".join(PackedStringArray(ats))

# an OPEN SLOT card's tap: the draft (it comes back here). A full lineup is kept (saved, like PLAY).
func tap_open_slot() -> bool:
	if _busy or Trip.open_slots() <= 0:
		return false
	if _picks.size() == Trip.STARTERS and lineup_ok():
		Trip.set_starters(_picks, str(_picks[0]))
	if audio != null:
		audio.play("bounce", -4.0)
	_stat("lineup_draft")
	_go("draft", {"back": "lineup"})
	return true

func _on_play() -> void:
	if _busy or _arm_t > 0.0 or _picks.size() != Trip.STARTERS:
		return
	var why: String = Trip.starters_ok(_picks)
	if why == Trip.BOSS_RULE or why == Trip.LEGEND_RULE:
		_flash(why + ".")
		return
	if not Trip.set_starters(_picks, str(_picks[0])):
		_flash("That lineup doesn't work: pick 3 different players.")
		return
	if audio != null:
		audio.play("bounce", -4.0)
	_stat("lineup_play")
	Trip.match_for()   # Flow.match with these starters (starter 0 = you)
	_go(Flow.GAME)

func _on_back() -> void:
	if _busy or _arm_t > 0.0:
		return
	if Trip.replaying():
		Trip.cancel_replay()   # P8-17: a replay goes back to the map (the marker dropped), also in New York
		_go("map")
		return
	_go("bracket" if Trip.is_tournament(Trip.city) else "map")

func _go(to: String, to_args := {}) -> void:
	_busy = true
	_refresh()
	Flow.go(to, to_args)

# trip test: keep the lineup (fill it from the roster if it isn't 3, never with a second boss or a second legend: the
# BOSS_RULE and the LEGEND_RULE) and PLAY
func auto_step() -> bool:
	if _busy:
		return false
	for id in Trip.roster_ids():
		if _picks.size() >= Trip.STARTERS:
			break
		if not _picks.has(str(id)) and boss_in_the_way(str(id)) == "" and legend_in_the_way(str(id)) == "":
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

# a card standing in the SHEET_FRAME box at pos, scale sc (a v2 card keeps the floor point and the height)
static func draw_sprite(c: CanvasItem, card: Dictionary, pos: Vector2, sc: float, fallback: Color) -> void:
	var sz: Vector2 = SHEET_FRAME * sc
	var tex: Texture2D = card.get("texture", null)
	if tex != null:
		c.draw_texture_rect(tex, Sheets.card_rect(card, pos, sc), false)
	else:
		c.draw_circle(pos + Vector2(sz.x / 2.0, sz.y * 0.2), sz.x * 0.22, fallback)
		c.draw_rect(Rect2(pos + Vector2(sz.x * 0.22, sz.y * 0.34), Vector2(sz.x * 0.56, sz.y * 0.6)), fallback)

static func draw_ring(c: CanvasItem, feet: Vector2, w: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a: float = TAU * i / 24.0
		pts.append(feet + Vector2(cos(a) * w / 2.0, sin(a) * w / 6.0))
	c.draw_polyline(pts, col, 3.0)


# One card in the list: tap = pick / bench (a player; his points badge opens the points screen), the points screen
# (the STAT POINTS card), the draft (OPEN SLOT) or a hint (the locked slot); a drag scrolls the list instead.
class Card extends Control:
	var screen               # lineup.gd
	var kind := "player"     # "player", "points", "open", "locked"
	var p := {}
	var tex: Dictionary = {}   # Sheets.card_info()
	var _down := false
	var _drag := false
	var _press := Vector2.ZERO   # where the finger went down (screen px; the card moves while the list scrolls)
	var _press_local := Vector2.ZERO   # the same in the card (the badge zone)
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
				_press_local = mb.position
				_last = _press
			elif _down:
				_down = false
				if not _drag and mb.global_position.distance_to(_press) <= screen.TAP_SLOP:
					screen._on_card_tap(self, _press_local)
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
				_press_local = mm.position
			elif g.distance_to(_press) > screen.TAP_SLOP:
				_drag = true
			if _drag and step.length() <= screen.JUMP_PX:
				screen._scroll.scroll_vertical -= int(step.y)
			accept_event()

	func _draw() -> void:
		if kind == "points":
			_draw_points()
			return
		if kind == "open" or kind == "locked":
			_draw_slot()
			return
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
		var tagged: bool = Trip.is_boss(id) or Trip.is_legend(id)
		var tier: String = str(s.TIER_TEXT.get(str(p.get("tier", "")), "")) if not tagged else ""   # the tag says it
		var sub: String = ("#%d  " % num if num > 0 else "") + role + (("  " + tier) if tier != "" else "")
		# P10-19: a long role (the Fathers' "high-flying shooting guard") shrinks to clear the YOU / 2 / 3 badge
		var sub_w: float = tw - (s.BADGE_R * (3.2 if slot == 1 else 2.0) + s.SUB_BADGE_GAP if slot > 0 else 0.0)
		var sub_fs: int = s.SMALL_FONT
		var font_s: Font = ThemeDB.fallback_font
		while sub_fs > s.SUB_MIN_FONT and font_s.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs).x > sub_w:
			sub_fs -= 1
		s.draw_text(self, Vector2(x, pad + 50.0), sub, sub_fs, s.DIM_TEXT, HORIZONTAL_ALIGNMENT_LEFT, sub_w)
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
		# P8-18: DRAFTED tag (top-left) and the points badge (bottom-left)
		var boss: bool = Trip.is_boss(id)
		if boss:
			var bt: Rect2 = s.BOSS_TAG
			draw_style_box(s.UI.style_box(s.BOSS_TAG_FILL, s.BOSS_TAG_COLOR, 2), bt)
			_centered(bt, "BOSS", s.DRAFTED_FONT + 2, s.BOSS_TAG_COLOR, false)
		var legend: bool = Trip.is_legend(id)
		if legend:
			var lt: Rect2 = s.LEGEND_TAG
			draw_style_box(s.UI.style_box(s.legend_color(id), s.LEGEND_TAG_COLOR, 2), lt)
			_centered(lt, s.LEGEND_TAG_TEXT, s.DRAFTED_FONT + 1, s.LEGEND_TAG_COLOR, false)
		if s._drafted.has(id):
			var tr: Rect2 = s.DRAFTED_TAG
			if boss:
				tr.position.y += s.BOSS_TAG.size.y + s.TAG_GAP
			elif legend:
				tr.position.y += s.LEGEND_TAG.size.y + s.TAG_GAP
			draw_style_box(s.UI.style_box(s.SLOT_FILL, s.DRAFTED_COLOR, 2), tr)
			_centered(tr, "DRAFTED", s.DRAFTED_FONT, s.DRAFTED_COLOR, false)
		if s.has_badge(id):
			var pr: Rect2 = s.PTS_BADGE
			draw_style_box(s.UI.style_box(s.PTS_COLOR, s.UI.LIT_BORDER, 3), pr)
			var n: int = Trip.player_points(id)
			_centered(pr, "%d PT%s" % [n, "" if n == 1 else "S"], s.PTS_FONT, s.UI.LIT_TEXT, false)

	# one line of text centred in r (outlined or plain)
	func _centered(r: Rect2, txt: String, fs: int, col: Color, outline: bool) -> void:
		var font: Font = ThemeDB.fallback_font
		var at := Vector2(r.position.x, r.get_center().y + fs * 0.36)
		if outline:
			screen.draw_text(self, at, txt, fs, col, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:
			draw_string(font, at, txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, col)

	# the STAT POINTS card: who has points, the crew points, TAP TO SPEND
	func _draw_points() -> void:
		var s = screen
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(s.UI.style_box(s.POINTS_CARD_FILL, s.PTS_COLOR, s.PICKED_BORDER_W), r)
		var pad: float = s.CARD_PAD
		var w: float = size.x - 2.0 * pad
		s.draw_text(self, Vector2(pad, pad + 32.0), "STAT POINTS", s.SLOT_TITLE_FONT, s.PTS_COLOR,
				HORIZONTAL_ALIGNMENT_CENTER, w)
		var names: Array = []
		var lst: Array = s.points_list()
		for i in mini(lst.size(), s.POINTS_NAMES_MAX):
			names.append("%s %d" % [str(lst[i][0]), int(lst[i][1])])
		var line: String = ", ".join(PackedStringArray(names))
		if lst.size() > s.POINTS_NAMES_MAX:
			line += "  +%d more" % (lst.size() - s.POINTS_NAMES_MAX)
		var y: float = pad + 72.0
		if line != "":
			s.draw_text(self, Vector2(pad, y), line, s.SMALL_FONT, s.UI.TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, w)
			y += 30.0
		if Trip.crew_points > 0:
			s.draw_text(self, Vector2(pad, y), "CREW POINTS: %d (anyone)" % Trip.crew_points, s.SMALL_FONT,
					s.PTS_COLOR, HORIZONTAL_ALIGNMENT_CENTER, w)
		var br := Rect2(pad + 60.0, size.y - pad - 48.0, w - 120.0, 48.0)
		draw_style_box(s.UI.style_box(s.PTS_COLOR, s.UI.LIT_BORDER, 3), br)
		_centered(br, "TAP TO SPEND", 24, s.UI.LIT_TEXT, false)

	# OPEN SLOT (tap = the draft) or the next locked slot (its star count)
	func _draw_slot() -> void:
		var s = screen
		var r := Rect2(Vector2.ZERO, size)
		var open: bool = kind == "open"
		draw_style_box(s.UI.style_box(s.SLOT_FILL if open else s.LOCKED_FILL,
				s.UI.OFF_BORDER if open else s.UI.OPT_BORDER.darkened(0.35), s.CARD_BORDER_W), r)
		var pad: float = s.CARD_PAD
		var c := Vector2(pad + 48.0, size.y / 2.0)
		var x: float = c.x + 64.0
		var w: float = size.x - x - pad
		if open:
			draw_circle(c, s.SLOT_PLUS_R, s.UI.OFF_COLOR)
			draw_arc(c, s.SLOT_PLUS_R, 0.0, TAU, 32, s.UI.OFF_BORDER, 3.0)
			draw_rect(Rect2(c - Vector2(18, 4), Vector2(36, 8)), s.UI.TEXT_COLOR)
			draw_rect(Rect2(c - Vector2(4, 18), Vector2(8, 36)), s.UI.TEXT_COLOR)
			s.draw_text(self, Vector2(x, pad + 56.0), "OPEN SLOT", s.SLOT_TITLE_FONT, s.UI.TEXT_COLOR)
			var lines: Array = ["Tap to draft a player", "from a crew you beat."]
			if not s._pool_any:
				lines = ["Beat a crew, then draft", "one of its players."]
			s.draw_text(self, Vector2(x, pad + 92.0), str(lines[0]), s.SMALL_FONT, s.DIM_TEXT,
					HORIZONTAL_ALIGNMENT_LEFT, w)
			s.draw_text(self, Vector2(x, pad + 118.0), str(lines[1]), s.SMALL_FONT, s.DIM_TEXT,
					HORIZONTAL_ALIGNMENT_LEFT, w)
		else:
			_star(c, s.STAR_R * 1.4, s.STAR_COLOR.darkened(0.45))
			var at: int = s.next_slot_at()
			s.draw_text(self, Vector2(x, pad + 48.0), "SLOT LOCKED", s.SLOT_TITLE_FONT, s.LOCKED_TEXT)
			s.draw_text(self, Vector2(x, pad + 84.0), "OPENS AT %d STARS" % at, s.SMALL_FONT + 2, s.STAR_COLOR,
					HORIZONTAL_ALIGNMENT_LEFT, w)
			s.draw_text(self, Vector2(x, pad + 112.0), "You have %d of %d." % [Stars.total(), Stars.MAX],
					s.SMALL_FONT, s.DIM_TEXT, HORIZONTAL_ALIGNMENT_LEFT, w)
			var later: String = s.later_slots_text()
			if later != "":
				s.draw_text(self, Vector2(x, pad + 138.0), "More slots at %s." % later, s.SMALL_FONT, s.DIM_TEXT,
						HORIZONTAL_ALIGNMENT_LEFT, w)

	# a five-point star centred on c
	func _star(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var a: float = -PI / 2.0 + PI * i / 5.0
			var rr: float = r if i % 2 == 0 else r * 0.45
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, col)
		pts.append(pts[0])
		draw_polyline(pts, screen.UI.OUTLINE_COLOR, 2.0)


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
			s.draw_sprite(self, texs[i] if i < texs.size() else {}, sp, sc, s.THEIR_RING)
			var x: float = sp.x + spr.x + 14.0
			s.draw_text(self, Vector2(x, y + 44.0), str(p.get("name", "?")), s.NAME_FONT - 4, s.UI.TEXT_COLOR)
			var tier: String = str(s.TIER_TEXT.get(str(p.get("tier", "")), ""))
			var role: String = str(p.get("role", ""))
			var sub: String = (tier + "  " if tier != "" else "") + role
			s.draw_text(self, Vector2(x, y + 72.0), sub, s.SMALL_FONT, s.STAT_HIGH if tier == "BOSS" or tier == "LEGEND" else s.DIM_TEXT,
					HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 12.0)
			var rt: Dictionary = p.get("ratings", {})
			var tot := 0
			for e in s.STAT_NAMES:
				tot += int(rt.get(e[0], 0))
			s.draw_text(self, Vector2(x, y + 98.0), "rating %d" % int(round(tot / 5.0)), s.SMALL_FONT, s.DIM_TEXT)
			y += s.OPP_ROW
