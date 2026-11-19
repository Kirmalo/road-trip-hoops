extends CanvasLayer
# THE ERA TOUR (P9-18, board Phase 9; Flow screen "legends", args {"chapter": id} opens that chapter's view, else the
# timeline). Built in code like hall.gd; art from assets/legends/ (P9-11, docs/art/legends_ui.png is the mock-up).
#   Timeline: the backdrop (timeline.png at 2x) with the 4 chapter panels left to right. Each panel: its pin (open /
#   done / locked), CHAPTER n, the name, the status (PLAY, LOCKED, COMING LATER, FINALE WON), the gate or its tokens.
#   An open chapter has a gold PLAY button (and the whole panel is a tap target); a locked one says why on the hint
#   line. Header: LEGENDS, THE ERA TOUR - TOKENS n/max, HALL and BACK (to the title).
#   Chapter view: the 6 legend plaques (locked = the silhouette and "?", beaten = his card and his best tokens), the
#   era finale card (locked until all 6 are beaten), YOUR CREW (Legends.crew_for_challenge() / crew_for_finale(): the
#   trip's starters, "NO TRIP: THE KINGS PLAY", or the swap of a drafted legend), on the right the picked game (name,
#   challenge line, best tokens), the level picker (EASY / NORMAL / HARD, LEGEND once Stars.legend_open(); opens on
#   Legends.default_level(), or on the level of the legends game just played) and PLAY. Header: BACK (to the
#   timeline), the chapter, TOKENS n/max, HALL (back here on this chapter).
#   The first time a chapter opens its intro scene plays (story.gd, back to the chapter view); the first PLAY of a
#   finale plays its "before" scene, then the game. PLAY sets Flow.match (Legends.match_for_challenge() /
#   match_for_finale()) and goes to "game". Nothing here writes the trip; only Legends.mark_seen() writes (scenes).
# The layout is a 1280 x 720 box centred on wider or taller screens (like hall.gd). Nothing mirrors for the
# left-handed layout (a menu screen has no joystick). Every button is at least UI.MIN_BUTTON (200 x 110). Taps are
# ignored for ARM_T s after the screen opens.
# Desktop: Escape = BACK (main.gd turns the Android back into one), Left / Right = the game before / after, Enter =
# PLAY. auto_step() (test drivers): on the timeline opens the first open chapter; on a chapter view plays the first
# open challenge (the first legend not yet beaten, then the finale while it is not won, else the first legend).

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const LegendsData = preload("res://scripts/legends_data.gd")
const Legends = preload("res://scripts/legends.gd")
const Sheets = preload("res://scripts/sheets.gd")
const StoryText = preload("res://scripts/story_text.gd")
const Stars = preload("res://scripts/stars.gd")

# ---------------------------------------------------------------------------------------------------- tuning
const ARM_T := 0.4                       # s the taps are ignored after the screen opens
const FRAME_SIZE := Vector2(1280, 720)   # the layout box, centred on wider / taller screens
const ART_SCALE := 2.0                   # the timeline art (640 x 360 texels) drawn at 2 px per texel
const TAP_SLOP := 14.0                   # px a finger may move and still tap
const HINT_T := 2.4                      # s a tap message stays on the hint line
# timeline
const TL_TITLE_RECT := Rect2(24, 0, 300, 72)     # "LEGENDS" in the header band (ui.json header_h 36 texels)
const TL_TITLE_FONT := 46
const TL_SUB_RECT := Rect2(300, 0, 520, 72)      # THE ERA TOUR - TOKENS n/max
const TL_SUB_FONT := 28
const TL_HALL_POS := Vector2(844, 8)             # HALL, top-right beside BACK (reaches over the locked panels' art)
const TL_BACK_POS := Vector2(1064, 8)
const TL_HINT_RECT := Rect2(16, 76, 816, 36)     # the hint / tap message, under the header over the panels' tops
const TL_HINT_FONT := 24
const TL_HINT_BG := Color(0.02, 0.02, 0.05, 0.7)  # behind the hint line (it sits on the panels' art)
const PANEL_FONTS := [22, 34, 24, 18]            # CHAPTER n / the name / the status / the gate or tokens
const PANEL_LINE_Y := [12.0, 46.0, 74.0, 98.0]  # px under ui.json label_y (x2) for each line's baseline
const PANEL_NAME_MIN := 20                       # the name shrinks down to this to fit the panel
const PANEL_PLAY_SIZE := Vector2(240, 110)       # an open chapter's PLAY (UI.MIN_BUTTON tall)
const PANEL_PLAY_GAP := 4.0                      # px left under the PLAY button inside the panel
const PANEL_LOCK_DIM := Color(0.02, 0.02, 0.05, 0.58)   # over a built chapter whose gate is not met (its art is lit)
# chapter view
const CV_DIM := Color(0.03, 0.03, 0.07, 0.8)     # over the timeline art behind the chapter view
const CV_BACK_POS := Vector2(16, 8)
const CV_HALL_POS := Vector2(1064, 8)
const CV_TITLE_RECT := Rect2(232, 0, 816, 54)
const CV_TITLE_FONT := 44
const CV_SUB_RECT := Rect2(232, 52, 816, 32)
const CV_SUB_FONT := 22
const CV_HINT_RECT := Rect2(232, 84, 816, 36)
const CV_HINT_FONT := 22
const PLAQUES_RECT := Rect2(16, 126, 752, 226)   # the 6 legends
const PLAQUE_SCALE := 2.0                        # 56 x 88 texels at 2x (112 x 176)
const PLAQUE_GAP := 12.0
const PLAQUE_TOP := 8.0                          # px from the panel's top to the plaques
const PIP_R := 6.0
const FINALE_RECT := Rect2(16, 360, 752, 124)    # the era finale card
const FINALE_MINI_SCALE := 1.0                   # its 3 legends as small plaques (56 x 88)
const FINALE_TEXT_X := 210.0
const CREW_RECT := Rect2(16, 492, 752, 214)      # YOUR CREW
const CREW_SLOT_W := 150.0                       # px per crew player
const CREW_SPRITE_SCALE := 2.0                   # a v1-sized 40 x 64 box at 2x (Sheets.card_rect fits v2 cards)
const CREW_SPRITE_TOP := 40.0                    # px from the strip's top to the sprite box
const CREW_NOTE_X := 486.0                       # px: the crew note column
const DETAIL_RECT := Rect2(780, 126, 484, 222)   # the picked game
const LEVEL_POS := Vector2(780, 356)             # the 2 x 2 level buttons
const LEVEL_SIZE := Vector2(235, 110)
const LEVEL_GAP := Vector2(14, 8)
const PLAY_RECT := Rect2(780, 594, 484, 112)
const PLAY_FONT := 50
const LEVEL_FONT := 36
const NAME_FONT := 34
const TEXT_FONT := 21
const HEAD_FONT := 18
const STATUS_CUT := 136.0                        # px kept free right of the detail's status line (BEST and the pips)
# colors
const GOLD := Color(1.0, 0.82, 0.25)
const DIM_TEXT := Color(0.7, 0.72, 0.78)
const LOCKED_TEXT := Color(0.6, 0.62, 0.68)
const HINT_COLOR := Color(0.85, 0.87, 0.92)
const WARN_COLOR := Color(1.0, 0.6, 0.35)
const OPEN_GREEN := Color(0.55, 0.95, 0.45)      # "PLAY" on the open panel (the mock-up's green)
const PIP_ON := Color(1.0, 0.82, 0.25)
const PIP_OFF := Color(0.3, 0.31, 0.37)
const BOX_FILL := Color(0.1, 0.12, 0.18, 0.94)
const BOX_LOCKED_FILL := Color(0.07, 0.08, 0.11, 0.94)
const PLATE_TEXT := Color(0.16, 0.1, 0.04)
const PLATE_LOCKED_TEXT := Color(0.82, 0.82, 0.88)
const PLATE_FONT_MAX := 12
const PLATE_FONT_MIN := 7
const FALLBACK_FRAME := Color(0.42, 0.3, 0.16)
const FALLBACK_LOCKED := Color(0.25, 0.26, 0.3)
const SILHOUETTE_COLOR := Color(0.05, 0.05, 0.08)
const YOU_COLOR := Color(1.0, 0.82, 0.25)
# art (assets/legends/ui.json; these are its values, used while the file is missing)
const UI_DIR := "res://assets/legends/"
const UI_JSON := "res://assets/legends/ui.json"
const PORTRAIT_DIR := "res://assets/portraits/"
const DEF_TIMELINE := "timeline.png"
const DEF_HEADER_H := 36.0
const DEF_BAR_BG := Color(0.07, 0.06, 0.12)
const DEF_PANELS := [[7, 44, 152, 309], [165, 44, 152, 309], [323, 44, 152, 309], [481, 44, 152, 309]]
const DEF_LABEL_Y := 240.0
const DEF_PIN_POINTS := [[83, 226], [241, 226], [399, 226], [557, 226]]
const DEF_PIN_SIZE := Vector2(32, 40)
const DEF_PIN_ANCHOR := Vector2(16, 37)
const DEF_FRAME := Vector2(56, 88)
const DEF_WINDOW := Rect2(8, 8, 40, 60)
const DEF_CARD_CROP := Rect2(12, 34, 40, 60)
const DEF_PLATE := Rect2(6, 72, 44, 11)
const DEF_FRAMES := {"grand": "frame_grand.png", "locked": "frame_locked.png"}
const DEF_SILHOUETTE := "silhouette.png"
const V2_CARD := Vector2(64, 96)
const CREW_FALLBACK_SHEET := "ud_jojo"           # a crew player without a sheet (lineup.gd's fallback for your side)
const LEVEL_NAMES := {"easy": "EASY", "normal": "NORMAL", "hard": "HARD", "legend": "LEGEND"}
const FINALE_PICK := "finale"                    # the pick of the era finale card
const SELF_SCREEN := "legends"
const STORY_SCREEN := "story"
const HALL_SCREEN := "hall"
const TL_HINT := "Tap an era. Beat its legends to hang them in the Hall."
const CV_HINT := "Tap a legend, pick a level, PLAY."

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd
var music := "menu"          # the chapter view plays its era's music (Legends.music_for)

var _root: Control
var _frame: Control
var _hint: Label
var _hint_t := 0.0
var _hint_text := ""
var _chapter := ""           # "" = the timeline, else the chapter view of this chapter id
var _pick := ""              # chapter view: a legend id or FINALE_PICK
var _level := "normal"
var _arm_t := ARM_T
var _busy := false
var _ui := {}                # ui.json
var _tex := {}               # path -> Texture2D (null = missing)
var _cards := {}             # legend id -> {"tex", "src", "kind"} (empty = silhouette)
var _crew_cache := {}        # pick -> Legends.your_side() answer
var _level_buttons := {}     # level -> Button
var _play: Button = null
var _detail: Control = null  # chapter view: the labels of the picked game
var _view: Control = null    # chapter view: the drawn plaques, finale card and crew (ChapterArt)
var _panels: Array = []      # timeline: {"ch", "rect"}
var _redirect := ""          # a chapter asked for that is not open: the reason, flashed on the timeline

func _ready() -> void:
	Legends.load_state()
	var a: Dictionary = Flow.args if str(Flow.screen) == SELF_SCREEN else {}
	var want: String = str(a.get("chapter", ""))
	if want != "":
		if LegendsData.chapter(want).is_empty():
			want = ""
		elif not Legends.chapter_open(want):
			_redirect = _locked_line(want)
			want = ""
	_chapter = want
	_ui = _read_ui()
	_root = UI.screen_root(self)
	var bg := _root.get_child(0) as ColorRect
	if bg != null:
		bg.color = bar_color()   # the bars beside the 1280 frame on wide screens (ui.json bar_bg)
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.size = FRAME_SIZE
	_root.add_child(_frame)
	_root.resized.connect(_center)
	_center()
	var bd := Backdrop.new()
	bd.screen = self
	bd.size = FRAME_SIZE
	bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(bd)
	if _chapter == "":
		_build_timeline()
		if _redirect != "":
			_flash(_redirect)
	else:
		music = Legends.music_for(_chapter)
		_level = _start_level()
		_pick = _start_pick()
		_build_chapter()
		_show_pick()
		var intro: String = _intro_scene(_chapter)
		if intro != "":
			call_deferred("_play_intro", _chapter)
	_stat("legends_screen")
	print("LEGENDS TOUR %s | tokens %d/%d | stars %d | open %s | unlocked %d/%d%s" % [
			("chapter " + _chapter) if _chapter != "" else "timeline", Legends.tokens_total(),
			LegendsData.max_tokens(), Stars.total(), str(_open_chapters()), Legends.unlocked_ids().size(),
			LegendsData.legend_ids().size(), (" | pick %s level %s crew %s" % [_pick, _level,
			str(_crew(_pick).get("crew", ""))]) if _chapter != "" else ""])

func _center() -> void:
	_frame.position = ((_root.size - FRAME_SIZE) / 2.0).floor()

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
	if _hint_t > 0.0:
		_hint_t -= delta
		if _hint_t <= 0.0:
			_set_hint(_hint_text, HINT_COLOR)

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_back()
	elif _chapter != "" and (k.keycode == KEY_LEFT or k.keycode == KEY_RIGHT):
		var order: Array = _pick_order()
		var i: int = order.find(_pick)
		if i >= 0:
			i = clampi(i + (1 if k.keycode == KEY_RIGHT else -1), 0, order.size() - 1)
			pick(str(order[i]))
	elif k.keycode == KEY_ENTER:
		if _chapter != "":
			_on_play()
		else:
			var open: Array = _open_chapters()
			if not open.is_empty():
				_open_chapter(str(open[0]))

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

func _sfx(sfx_name: String, db := 0.0) -> void:
	if audio != null:
		audio.play(sfx_name, db)

# ---------------------------------------------------------------------------------------------------- state

# the built chapters whose gate is met, in timeline order
static func _open_chapters() -> Array:
	var out: Array = []
	for ch in LegendsData.built_chapters():
		if Legends.chapter_open(str(ch)):
			out.append(str(ch))
	return out

# a chapter's state on the timeline: "open", "done" (finale won), "locked" (built, gate not met), "later" (not built)
static func chapter_state(ch: String) -> String:
	if not LegendsData.is_built(ch):
		return "later"
	if not Legends.chapter_open(ch):
		return "locked"
	return "done" if Legends.chapter_done(ch) else "open"

static func _locked_line(ch: String) -> String:
	var row: Dictionary = LegendsData.chapter(ch)
	var nm: String = _short_chapter_name(ch)
	if not bool(row.get("built", false)):
		return "%s: COMING LATER (OPENS AT %s)" % [nm, Legends.gate_text(ch)]
	return "%s OPENS AT %s. YOU HAVE %d STARS." % [nm, Legends.gate_text(ch), Stars.total()]

# "THE GRANDFATHERS" -> "GRANDFATHERS"
static func _short_chapter_name(ch: String) -> String:
	var nm: String = str(LegendsData.chapter(ch).get("name", ch)).to_upper()
	return nm.substr(4) if nm.begins_with("THE ") else nm

# the chapter's intro scene if it has not been seen yet and story_text.gd has it, else ""
static func _intro_scene(ch: String) -> String:
	var sc: String = str(LegendsData.chapter(ch).get("intro_scene", ""))
	if sc == "" or not StoryText.has_scene(sc) or Legends.has_seen(sc):
		return ""
	return sc

# the finale's "before" scene if not seen yet, else ""
static func _finale_before(ch: String) -> String:
	var fs = LegendsData.chapter(ch).get("finale_scenes", {})
	var sc: String = str((fs as Dictionary).get("before", "")) if fs is Dictionary else ""
	if sc == "" or not StoryText.has_scene(sc) or Legends.has_seen(sc):
		return ""
	return sc

# the level the picker opens on: the level of the legends game just played (Flow.match is kept until the title), else
# Legends.default_level() (the trip's level, Quick Game's without a trip)
func _start_level() -> String:
	var lv: String = ""
	if Flow.in_legends() and str(Flow.match.get("chapter", "")) == _chapter:
		lv = Legends.level_ok(str(Flow.match.get("level", "")))
	if lv == "" or not Legends.offered_levels().has(lv):
		lv = Legends.default_level()
	if not Legends.offered_levels().has(lv):
		lv = str(Legends.offered_levels()[0])
	return lv

# the game picked when the view opens: the one just played, else the first open challenge
func _start_pick() -> String:
	if Flow.in_legends() and str(Flow.match.get("chapter", "")) == _chapter:
		var key: String = str(Flow.match.get("key", ""))
		if key == Legends.finale_key(_chapter):
			return FINALE_PICK
		if key.begins_with("lg:") and _pick_order().has(key.substr(3)):
			return key.substr(3)
	return first_open_pick()

# the first open challenge of the chapter view: the first legend not yet beaten, then the finale while it is open and
# not won, else the first legend
func first_open_pick() -> String:
	var ids: Array = LegendsData.legend_ids(_chapter)
	for id in ids:
		if not Legends.is_unlocked(str(id)):
			return str(id)
	if Legends.finale_open(_chapter) and not Legends.chapter_done(_chapter):
		return FINALE_PICK
	return str(ids[0]) if not ids.is_empty() else FINALE_PICK

# every pick of the chapter view, left to right (the 6 legends, then the finale)
func _pick_order() -> Array:
	var out: Array = LegendsData.legend_ids(_chapter).duplicate()
	if not (LegendsData.chapter(_chapter).get("finale", {}) as Dictionary).is_empty():
		out.append(FINALE_PICK)
	return out

# your side for a pick (cached: it loads the trip save once)
func _crew(what: String) -> Dictionary:
	if _chapter == "" or what == "":
		return {}
	if not _crew_cache.has(what):
		_crew_cache[what] = Legends.crew_for_finale(_chapter) if what == FINALE_PICK \
				else Legends.crew_for_challenge(what)
	return _crew_cache[what]

# a pick can be played now
func pick_playable(what: String) -> bool:
	if what == FINALE_PICK:
		return Legends.finale_open(_chapter)
	return Legends.challenge_open(what)

# picks a game on the chapter view (a tap, Left / Right, the tests); false for something not on the view
func pick(what: String) -> bool:
	if _chapter == "" or not _pick_order().has(what):
		return false
	if what != _pick:
		_pick = what
		_sfx("bounce", -6.0)
		_stat("legends_pick")
		_show_pick()
	return true

func picked() -> String:
	return _pick

func level() -> String:
	return _level

# picks a level (a tap on a level button); false for a level not offered
func set_level(lv: String) -> bool:
	if not Legends.offered_levels().has(lv):
		return false
	if lv != _level:
		_level = lv
		_sfx("bounce", -6.0)
		_stat("legends_level")
	_refresh_levels()
	return true

func chapter() -> String:
	return _chapter

# ---------------------------------------------------------------------------------------------------- timeline

func _build_timeline() -> void:
	var head: Label = UI.label(_frame, "LEGENDS", TL_TITLE_FONT, GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.position = TL_TITLE_RECT.position
	head.size = TL_TITLE_RECT.size
	var sub: Label = UI.label(_frame, "THE ERA TOUR  -  TOKENS %d/%d" % [Legends.tokens_total(),
			LegendsData.max_tokens()], TL_SUB_FONT, UI.TEXT_COLOR)
	sub.position = TL_SUB_RECT.position
	sub.size = TL_SUB_RECT.size
	var ids: Array = LegendsData.chapter_ids()
	var rects: Array = _ui.get("panels", DEF_PANELS)
	if not (rects is Array) or (rects as Array).size() < ids.size():
		rects = DEF_PANELS
	var open: Array = _open_chapters()
	_panels = []
	for i in ids.size():
		var ch: String = str(ids[i])
		var v: Array = rects[i]
		var r := Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
		r = Rect2(r.position * ART_SCALE, r.size * ART_SCALE)
		var p := TimelinePanel.new()
		p.screen = self
		p.ch = ch
		p.num = i + 1
		p.position = r.position
		p.size = r.size
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		_frame.add_child(p)
		_panels.append({"ch": ch, "rect": r})
		var st: String = chapter_state(ch)
		if st == "open" or st == "done":
			var b: Button = UI.button(p, "PLAY", _open_chapter.bind(ch), UI.KIND_LIT, PANEL_PLAY_SIZE)
			b.position = Vector2(floorf((r.size.x - PANEL_PLAY_SIZE.x) / 2.0),
					r.size.y - PANEL_PLAY_SIZE.y - PANEL_PLAY_GAP)
	var hall: Button = UI.button(_frame, "HALL", _on_hall, UI.KIND_MAIN, UI.SMALL_SIZE)
	hall.position = TL_HALL_POS
	var back: Button = UI.button(_frame, "BACK", _on_back, UI.KIND_OPT, UI.SMALL_SIZE)
	back.position = TL_BACK_POS
	_hint_text = TL_HINT if not open.is_empty() else _locked_line(str(ids[0]))
	_hint = _hint_label(TL_HINT_RECT, TL_HINT_FONT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = TL_HINT_BG
	sb.set_corner_radius_all(10)
	_hint.add_theme_stylebox_override("normal", sb)
	_set_hint(_hint_text, HINT_COLOR)

func _hint_label(r: Rect2, fs: int) -> Label:
	var l: Label = UI.label(_frame, "", fs, HINT_COLOR)
	l.position = r.position
	l.size = r.size
	l.clip_text = true
	return l

# a tap on a timeline panel
func _on_panel_tap(ch: String) -> void:
	if _busy or _arm_t > 0.0:
		return
	var st: String = chapter_state(ch)
	if st == "open" or st == "done":
		_open_chapter(ch)
	else:
		_sfx("bounce", -10.0)
		_flash(_locked_line(ch))

# opens a chapter's view (its intro scene first, the first time)
func _open_chapter(ch: String) -> void:
	if _busy or _arm_t > 0.0 or not Legends.chapter_open(ch):
		return
	_stat("legends_open_chapter")
	var intro: String = _intro_scene(ch)
	if intro != "":
		_play_intro(ch)
		return
	_go(SELF_SCREEN, {"chapter": ch})

# the chapter's intro scene (marked seen, so once), then its view
func _play_intro(ch: String) -> void:
	if _busy:
		return
	var intro: String = _intro_scene(ch)
	if intro == "":
		return
	Legends.mark_seen(intro)
	print("LEGENDS TOUR intro %s (%s)" % [intro, ch])
	_go(STORY_SCREEN, {"scene": intro, "then": SELF_SCREEN, "then_args": {"chapter": ch}})

# ---------------------------------------------------------------------------------------------------- chapter view

func _build_chapter() -> void:
	var row: Dictionary = LegendsData.chapter(_chapter)
	var back: Button = UI.button(_frame, "BACK", _on_back, UI.KIND_OPT, UI.SMALL_SIZE)
	back.position = CV_BACK_POS
	var hall: Button = UI.button(_frame, "HALL", _on_hall, UI.KIND_MAIN, UI.SMALL_SIZE)
	hall.position = CV_HALL_POS
	var head: Label = UI.label(_frame, str(row.get("name", _chapter)), CV_TITLE_FONT, GOLD)
	head.position = CV_TITLE_RECT.position
	head.size = CV_TITLE_RECT.size
	_fit_font(head, CV_TITLE_RECT.size.x, 28)
	var rules: String = str(row.get("rules", ""))
	var sub_txt: String = "CHAPTER %d" % (LegendsData.chapter_ids().find(_chapter) + 1)
	if rules != "":
		sub_txt += "  -  %s RULES" % rules
	sub_txt += "  -  TOKENS %d/%d" % [Legends.tokens_total(), LegendsData.max_tokens()]
	var sub: Label = UI.label(_frame, sub_txt, CV_SUB_FONT, UI.TEXT_COLOR)
	sub.position = CV_SUB_RECT.position
	sub.size = CV_SUB_RECT.size
	_fit_font(sub, CV_SUB_RECT.size.x, 16)
	_hint_text = CV_HINT
	_hint = _hint_label(CV_HINT_RECT, CV_HINT_FONT)
	_set_hint(_hint_text, HINT_COLOR)
	_view = ChapterArt.new()
	_view.screen = self
	_view.size = FRAME_SIZE
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.add_child(_view)
	var dp: PanelContainer = UI.panel(_frame, DETAIL_RECT.size)
	dp.position = DETAIL_RECT.position
	dp.size = DETAIL_RECT.size
	_detail = Control.new()
	_detail.position = DETAIL_RECT.position
	_detail.size = DETAIL_RECT.size
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_detail)
	var slots: Array = ["easy", "normal", "hard", "legend"]
	for i in slots.size():
		var lv: String = str(slots[i])
		if not Legends.offered_levels().has(lv):
			continue
		var b: Button = UI.button(_frame, str(LEVEL_NAMES.get(lv, lv.to_upper())), set_level.bind(lv),
				UI.KIND_MAIN, LEVEL_SIZE)
		b.add_theme_font_size_override("font_size", LEVEL_FONT)
		b.position = LEVEL_POS + Vector2((i % 2) * (LEVEL_SIZE.x + LEVEL_GAP.x), (i >> 1) * (LEVEL_SIZE.y + LEVEL_GAP.y))
		_level_buttons[lv] = b
	_play = UI.button(_frame, "PLAY", _on_play, UI.KIND_LIT, PLAY_RECT.size)
	_play.position = PLAY_RECT.position
	_play.add_theme_font_size_override("font_size", PLAY_FONT)
	_refresh_levels()

func _refresh_levels() -> void:
	for lv in _level_buttons:
		var b: Button = _level_buttons[lv]
		if str(lv) == _level:
			UI.set_kind(b, UI.KIND_LIT)
		else:
			UI.set_kind(b, UI.KIND_LEGEND if str(lv) == "legend" else UI.KIND_MAIN)

# a text label in the detail panel
func _text(text: String, rect: Rect2, fs: int, col: Color, wrap := false) -> Label:
	var l: Label = UI.label(null, text, fs, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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

# the detail panel, the PLAY button and the drawn view for the picked game
func _show_pick() -> void:
	if _view != null:
		_view.queue_redraw()
	if _detail == null:
		return
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	var pad: float = 16.0
	var w: float = DETAIL_RECT.size.x - 2.0 * pad
	var best: int = 0
	if _pick == FINALE_PICK:
		var f: Dictionary = LegendsData.chapter(_chapter).get("finale", {})
		_text("ERA FINALE", Rect2(pad, 10, w, 24), HEAD_FONT, DIM_TEXT)
		var nm: Label = _text(str(f.get("label", "FINALE")), Rect2(pad, 32, w, 42), NAME_FONT, GOLD)
		_fit_font(nm, w, 20)
		var names: Array = []
		for id in LegendsData.finale_team(_chapter):
			names.append(str(LegendsData.legend(str(id)).get("name", id)))
		_text("TO %d AGAINST %s" % [int(f.get("target", 21)), ", ".join(PackedStringArray(names))],
				Rect2(pad, 80, w, 64), TEXT_FONT, UI.TEXT_COLOR, true)
		best = Legends.token_best(Legends.finale_key(_chapter))
		var st: String = "FINALE WON" if Legends.chapter_done(_chapter) else (
				"OPEN: CLOSE THE ERA" if Legends.finale_open(_chapter) else
				"BEAT ALL %d TO OPEN IT" % LegendsData.legend_ids(_chapter).size())
		_text(st, Rect2(pad, 184, w - STATUS_CUT, 28), HEAD_FONT,
				GOLD if Legends.chapter_done(_chapter) else (OPEN_GREEN if Legends.finale_open(_chapter) else WARN_COLOR))
	else:
		var p: Dictionary = LegendsData.legend(_pick)
		var open: bool = Legends.is_unlocked(_pick)
		_text("CHALLENGE %d" % (LegendsData.legend_ids(_chapter).find(_pick) + 1) + (
				"  -  " + str(p.get("archetype", "")).to_upper() if open else ""), Rect2(pad, 10, w, 24), HEAD_FONT,
				DIM_TEXT)
		var nm: Label = _text(str(p.get("name", _pick)) if open else "? ? ?", Rect2(pad, 32, w, 42), NAME_FONT,
				GOLD if open else LOCKED_TEXT)
		_fit_font(nm, w, 20)
		_text(str(LegendsData.challenge(_pick).get("line", "")), Rect2(pad, 80, w, 96), TEXT_FONT, UI.TEXT_COLOR,
				true)
		best = Legends.token_best(Legends.challenge_key(_pick))
		_text("BEATEN: IN THE HALL" if open else "WIN IT: HE JOINS THE HALL", Rect2(pad, 184, w - STATUS_CUT, 28),
				HEAD_FONT,
				GOLD if open else OPEN_GREEN)
	_text("BEST", Rect2(w - 128.0, 184, 64, 28), HEAD_FONT, DIM_TEXT)
	var ok: bool = pick_playable(_pick)
	_play.text = ("PLAY FINALE" if _pick == FINALE_PICK else "PLAY") if ok else "LOCKED"
	UI.set_kind(_play, UI.KIND_LIT if ok else UI.KIND_OPT)
	UI.set_enabled(_play, ok)
	var pips := Pips.new()
	pips.best = best
	pips.n = LegendsData.TOKEN_MAX
	pips.position = Vector2(w - 24.0, 197.0)
	_detail.add_child(pips)

# a tap on the chapter view's drawn part (plaques, finale card), at = frame coordinates
func _on_view_tap(at: Vector2) -> void:
	if _busy or _arm_t > 0.0:
		return
	var what: String = pick_at(at)
	if what == "":
		return
	pick(what)
	if what == FINALE_PICK and not Legends.finale_open(_chapter):
		_flash("Beat all %d legends to open the finale." % LegendsData.legend_ids(_chapter).size())

# what is under a point of the chapter view ("" = nothing): a legend id or FINALE_PICK
func pick_at(p: Vector2) -> String:
	for q in plaque_rects():
		if (q["rect"] as Rect2).grow(PLAQUE_GAP / 2.0).has_point(p):
			return str(q["id"])
	if FINALE_RECT.has_point(p) and _pick_order().has(FINALE_PICK):
		return FINALE_PICK
	return ""

# the 6 plaques' rects (frame coordinates)
func plaque_rects() -> Array:
	var out: Array = []
	var ids: Array = LegendsData.legend_ids(_chapter)
	var sz: Vector2 = _frame_size() * PLAQUE_SCALE
	var w: float = ids.size() * sz.x + maxf(0.0, ids.size() - 1.0) * PLAQUE_GAP
	var x: float = PLAQUES_RECT.position.x + floorf((PLAQUES_RECT.size.x - w) / 2.0)
	for id in ids:
		out.append({"id": str(id), "rect": Rect2(Vector2(x, PLAQUES_RECT.position.y + PLAQUE_TOP), sz)})
		x += sz.x + PLAQUE_GAP
	return out

# PLAY: sets Flow.match for the picked game at the picked level and goes to the game (a finale's "before" scene
# first, the first time)
func _on_play() -> void:
	if _busy or _arm_t > 0.0 or _chapter == "":
		return
	if not pick_playable(_pick):
		_flash("Beat all %d legends to open the finale." % LegendsData.legend_ids(_chapter).size())
		return
	var m: Dictionary = {}
	if _pick == FINALE_PICK:
		m = Legends.match_for_finale(_chapter, _level)
	else:
		m = Legends.match_for_challenge(_pick, _level)
	if m.is_empty():
		_flash("This game can't be built.")
		return
	_stat("legends_play")
	_sfx("bounce", -4.0)
	print("LEGENDS TOUR play %s %s crew %s%s" % [str(m.get("key", "")), str(m.get("level", "")),
			str(m.get("crew", "")), (" | " + str(m.get("note", ""))) if str(m.get("note", "")) != "" else ""])
	if _pick == FINALE_PICK:
		var sc: String = _finale_before(_chapter)
		if sc != "":
			Legends.mark_seen(sc)
			_go(STORY_SCREEN, {"scene": sc, "then": Flow.GAME})
			return
	_go(Flow.GAME)

# ---------------------------------------------------------------------------------------------------- common actions

func _on_hall() -> void:
	if _busy or _arm_t > 0.0:
		return
	_stat("legends_hall")
	var ba: Dictionary = {"chapter": _chapter} if _chapter != "" else {}
	_go(HALL_SCREEN, {"back": SELF_SCREEN, "back_args": ba})

# BACK: the chapter view goes to the timeline, the timeline to the title
func _on_back() -> void:
	if _busy:
		return
	_stat("legends_back")
	if _chapter != "":
		_go(SELF_SCREEN, {})
	else:
		_go("title")

func _go(to: String, to_args := {}) -> void:
	_busy = true
	Flow.go(to, to_args)

func _set_hint(text: String, col: Color) -> void:
	if _hint == null:
		return
	_hint.text = text
	_hint.label_settings.font_color = col

func _flash(text: String) -> void:
	_set_hint(text, WARN_COLOR)
	_hint_t = HINT_T

# test drivers: the timeline opens the first open chapter; a chapter view plays its first open challenge
func auto_step() -> bool:
	if _busy:
		return false
	_arm_t = 0.0
	if _chapter == "":
		var open: Array = _open_chapters()
		if open.is_empty():
			return false
		_open_chapter(str(open[0]))
		return _busy
	pick(first_open_pick())
	_on_play()
	return _busy

# shrinks a one-line label's font (down to min_size) until its text fits max_w
static func _fit_font(lbl: Label, max_w: float, min_size := 16) -> void:
	var ls: LabelSettings = lbl.label_settings
	var font: Font = ls.font if ls.font != null else ThemeDB.fallback_font
	while ls.font_size > min_size and font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ls.font_size).x \
			+ 2.0 * ls.outline_size > max_w:
		ls.font_size -= 2

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

func _ui_vec(key: String, def: Vector2) -> Vector2:
	var v = _ui.get(key, null)
	if v is Array and (v as Array).size() == 2:
		return Vector2(float(v[0]), float(v[1]))
	return def

func _frame_size() -> Vector2:
	return _ui_vec("frame_size", DEF_FRAME)

func _texture(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path]
	var t: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_tex[path] = t
	return t

func timeline_tex() -> Texture2D:
	return _texture(UI_DIR + DEF_TIMELINE)

func bar_color() -> Color:
	var s: String = str(_ui.get("bar_bg", ""))
	return Color.from_string(s, DEF_BAR_BG) if s != "" else DEF_BAR_BG

func header_px() -> float:
	return float(_ui.get("header_h", DEF_HEADER_H)) * ART_SCALE

# a chapter's pin texture for its state (null = a drawn pin)
func pin_tex(ch: String, st: String) -> Texture2D:
	var pins = _ui.get("pins", {})
	var row: Dictionary = (pins as Dictionary).get(ch, {}) if pins is Dictionary else {}
	var key: String = "locked"
	if st == "open":
		key = "open"
	elif st == "done":
		key = "done" if row.has("done") else "open"
	var file: String = str(row.get(key, row.get("locked", "")))
	if file == "":
		file = "pin_%s_%s.png" % [ch, key]
	return _texture(UI_DIR + file)

# where a chapter's pin is drawn (frame coordinates) and its size
func pin_rect(i: int) -> Rect2:
	var pts = _ui.get("pin_points", DEF_PIN_POINTS)
	if not (pts is Array) or i >= (pts as Array).size():
		pts = DEF_PIN_POINTS
	var v: Array = pts[mini(i, (pts as Array).size() - 1)]
	var tip := Vector2(float(v[0]), float(v[1]))
	var sz: Vector2 = _ui_vec("pin_size", DEF_PIN_SIZE)
	var anchor: Vector2 = _ui_vec("pin_anchor", DEF_PIN_ANCHOR)
	return Rect2((tip - anchor) * ART_SCALE, sz * ART_SCALE)

func label_y_px() -> float:
	return float(_ui.get("label_y", DEF_LABEL_Y)) * ART_SCALE

func frame_tex(kind: String) -> Texture2D:
	var frames = _ui.get("frames", DEF_FRAMES)
	if not (frames is Dictionary):
		frames = DEF_FRAMES
	var file: String = str((frames as Dictionary).get(kind, (frames as Dictionary).get("grand", "")))
	return _texture(UI_DIR + file) if file != "" else null

func silhouette_tex() -> Texture2D:
	return _texture(UI_DIR + str(_ui.get("silhouette", DEF_SILHOUETTE)))

# a legend's picture for the plaque window (as hall.gd): his sheet's card, else his portrait; {} = the silhouette
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
			var win: Rect2 = _ui_rect("window", DEF_WINDOW)
			var aspect: float = win.size.x / maxf(1.0, win.size.y)
			var sz: Vector2 = pt.get_size()
			var cw: float = minf(sz.x, sz.y * aspect)
			out = {"tex": pt, "src": Rect2((sz.x - cw) / 2.0, 0.0, cw, cw / aspect), "kind": "portrait"}
	_cards[id] = out
	return out

# a crew player's card ({} = a silhouette): his own sheet's, then the fallback
func crew_card(pd: Dictionary) -> Dictionary:
	var sheet: String = str(pd.get("sheet", ""))
	var key: String = "crew/" + sheet
	if _cards.has(key):
		return _cards[key]
	var tries: Array = Sheets.with_base(sheet) if sheet != "" else []
	tries.append(CREW_FALLBACK_SHEET)
	var out: Dictionary = Sheets.card_first(tries)
	_cards[key] = out
	return out

# A plaque at pos, scale sc: the frame, the card / portrait / silhouette in its window, the name on the plate.
# state "open" (his card), "locked" (silhouette, "?").
func draw_plaque(c: CanvasItem, pos: Vector2, sc: float, id: String, state: String) -> void:
	var fs: Vector2 = _frame_size()
	var win: Rect2 = _ui_rect("window", DEF_WINDOW)
	var plate: Rect2 = _ui_rect("name_plate", DEF_PLATE)
	var open: bool = state == "open"
	var ft: Texture2D = frame_tex(LegendsData.chapter_of(id) if open else "locked")
	var dest := Rect2(pos, fs * sc)
	if ft != null:
		c.draw_texture_rect(ft, dest, false)
	else:
		c.draw_style_box(UI.style_box(FALLBACK_FRAME if open else FALLBACK_LOCKED, UI.OPT_BORDER, 2), dest)
	var wr := Rect2(pos + win.position * sc, win.size * sc)
	var card: Dictionary = card_for(id) if open else {}
	if not card.is_empty():
		var src: Rect2 = card["src"]
		var k: float = minf(wr.size.x / maxf(1.0, src.size.x), wr.size.y / maxf(1.0, src.size.y))
		var sz: Vector2 = src.size * k
		var stand: bool = str(card.get("kind", "")) == "card"
		var at := Vector2(wr.position.x + (wr.size.x - sz.x) / 2.0,
				wr.end.y - sz.y if stand else wr.position.y + (wr.size.y - sz.y) / 2.0)
		c.draw_texture_rect_region(card["tex"], Rect2(at, sz), src)
	else:
		var st: Texture2D = silhouette_tex()
		if st != null:
			c.draw_texture_rect(st, wr, false)
		else:
			c.draw_circle(wr.position + Vector2(wr.size.x / 2.0, wr.size.y * 0.24), wr.size.x * 0.2, SILHOUETTE_COLOR)
			c.draw_rect(Rect2(wr.position + Vector2(wr.size.x * 0.22, wr.size.y * 0.38), Vector2(wr.size.x * 0.56,
					wr.size.y * 0.56)), SILHOUETTE_COLOR)
	var pr := Rect2(pos + plate.position * sc, plate.size * sc)
	var txt: String = str(LegendsData.legend(id).get("name", "?")) if open else "?"
	var font: Font = ThemeDB.fallback_font
	var f: int = int(PLATE_FONT_MAX * sc / 1.5)
	var min_f: int = int(PLATE_FONT_MIN * sc / 1.5)
	while f > min_f and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x > pr.size.x - 4.0:
		f -= 1
	f = mini(f, int(pr.size.y * 0.9))
	c.draw_string(font, Vector2(pr.position.x, pr.get_center().y + f * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER,
			pr.size.x, f, PLATE_TEXT if open else PLATE_LOCKED_TEXT)

# TOKEN_MAX pips centred at center, the first `best` lit
static func draw_pips(c: CanvasItem, center: Vector2, best: int, r := PIP_R) -> void:
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

# one line, its font shrunk (down to min_fs) to fit w
static func draw_fit(c: CanvasItem, pos: Vector2, text: String, fs: int, min_fs: int, col: Color, w: float,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var font: Font = ThemeDB.fallback_font
	var f: int = fs
	while f > min_fs and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x + 12.0 > w:
		f -= 2
	draw_text(c, pos, text, f, col, align, w)

static func draw_wrapped(c: CanvasItem, pos: Vector2, text: String, fs: int, col: Color, w: float,
		max_lines := 3) -> void:
	var font: Font = ThemeDB.fallback_font
	c.draw_multiline_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, w, fs, max_lines, 6, UI.OUTLINE_COLOR)
	c.draw_multiline_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, w, fs, max_lines, col)


# The timeline art (or a plain fill without it); the chapter view dims it.
class Backdrop extends Control:
	var screen

	func _draw() -> void:
		var s = screen
		var tex: Texture2D = s.timeline_tex()
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2.ZERO, tex.get_size() * s.ART_SCALE), false)
		else:
			draw_rect(Rect2(Vector2.ZERO, size), s.bar_color())
		if s._chapter != "":
			draw_rect(Rect2(Vector2.ZERO, size), s.CV_DIM)
		else:
			draw_rect(Rect2(0, 0, size.x, s.header_px()), Color(s.bar_color(), 0.6))


# One chapter on the timeline: its pin, its lines and (open) the PLAY button as a child. A tap opens or explains.
class TimelinePanel extends Control:
	var screen
	var ch := ""
	var num := 1
	var _down := false
	var _press := Vector2.ZERO

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_down = true
			_press = mb.global_position
		elif _down:
			_down = false
			if mb.global_position.distance_to(_press) <= screen.TAP_SLOP:
				screen._on_panel_tap(ch)
		accept_event()

	func _draw() -> void:
		var s = screen
		var st: String = s.chapter_state(ch)
		var r := Rect2(Vector2.ZERO, size)
		if st == "locked":
			draw_rect(r, s.PANEL_LOCK_DIM)
		# the pin (its tip on the rail)
		var pr: Rect2 = s.pin_rect(num - 1)
		pr.position -= position
		var pt: Texture2D = s.pin_tex(ch, st)
		if pt != null:
			draw_texture_rect(pt, pr, false)
		else:
			draw_circle(pr.position + Vector2(pr.size.x / 2.0, pr.size.y * 0.4), pr.size.x * 0.4,
					s.GOLD if st == "open" or st == "done" else s.LOCKED_TEXT)
		var y0: float = s.label_y_px() - position.y
		var w: float = size.x
		var on: bool = st == "open" or st == "done"
		var name_col: Color = s.GOLD if on else s.UI.TEXT_COLOR
		s.draw_text(self, Vector2(0, y0 + s.PANEL_LINE_Y[0]), "CHAPTER %d" % num, s.PANEL_FONTS[0],
				s.GOLD if on else s.DIM_TEXT, HORIZONTAL_ALIGNMENT_CENTER, w)
		s.draw_fit(self, Vector2(0, y0 + s.PANEL_LINE_Y[1]), s._short_chapter_name(ch), s.PANEL_FONTS[1],
				s.PANEL_NAME_MIN, name_col, w)
		var status: String = ""
		var status_col: Color = s.DIM_TEXT
		var line: String = ""
		match st:
			"open":
				status = "PLAY"
				status_col = s.OPEN_GREEN
				line = "%d LEGENDS  -  TOKENS %d/%d" % [s.LegendsData.legend_ids(ch).size(),
						s.Legends.chapter_tokens(ch), s.Legends.chapter_max_tokens(ch)]
			"done":
				status = "FINALE WON"
				status_col = s.GOLD
				line = "TOKENS %d/%d" % [s.Legends.chapter_tokens(ch), s.Legends.chapter_max_tokens(ch)]
			"locked":
				status = "LOCKED"
				status_col = s.WARN_COLOR
				line = "OPENS AT %s" % s.Legends.gate_text(ch)
			_:
				status = "COMING LATER"
				line = s.Legends.gate_text(ch)
		s.draw_text(self, Vector2(0, y0 + s.PANEL_LINE_Y[2]), status, s.PANEL_FONTS[2], status_col,
				HORIZONTAL_ALIGNMENT_CENTER, w)
		s.draw_fit(self, Vector2(0, y0 + s.PANEL_LINE_Y[3]), line, s.PANEL_FONTS[3], 12, s.UI.TEXT_COLOR, w)
		if st == "locked":
			s.draw_text(self, Vector2(0, y0 + s.PANEL_LINE_Y[3] + 26.0), "YOU HAVE %d STARS" % s.Stars.total(),
					s.PANEL_FONTS[3], s.DIM_TEXT, HORIZONTAL_ALIGNMENT_CENTER, w)


# The chapter view's drawn parts: the 6 plaques with their pips, the finale card, YOUR CREW. A tap picks.
class ChapterArt extends Control:
	var screen
	var _down := false
	var _press := Vector2.ZERO
	var _press_local := Vector2.ZERO

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_down = true
			_press = mb.global_position
			_press_local = mb.position
		elif _down:
			_down = false
			if mb.global_position.distance_to(_press) <= screen.TAP_SLOP:
				screen._on_view_tap(_press_local)
		accept_event()

	# taps only on the plaques and the finale card; the rest of the frame lets them through (the buttons are on top
	# anyway, this keeps the empty parts from eating taps)
	func _has_point(p: Vector2) -> bool:
		var s = screen
		return s.PLAQUES_RECT.has_point(p) or s.FINALE_RECT.has_point(p)

	func _draw() -> void:
		var s = screen
		var ch: String = s._chapter
		# the legends
		draw_style_box(s.UI.style_box(s.BOX_FILL, s.UI.PANEL_BORDER, s.UI.BORDER), s.PLAQUES_RECT)
		for q in s.plaque_rects():
			var id: String = str(q["id"])
			var qr: Rect2 = q["rect"]
			var open: bool = s.Legends.is_unlocked(id)
			s.draw_plaque(self, qr.position, s.PLAQUE_SCALE, id, "open" if open else "locked")
			s.draw_pips(self, Vector2(qr.get_center().x, qr.end.y + 18.0), s.Legends.token_best(
					s.Legends.challenge_key(id)))
			if id == s._pick:
				draw_rect(qr.grow(4.0), s.GOLD, false, 4.0)
		# the finale
		var fr: Rect2 = s.FINALE_RECT
		var f_open: bool = s.Legends.finale_open(ch)
		var done: bool = s.Legends.chapter_done(ch)
		draw_style_box(s.UI.style_box(s.BOX_FILL if f_open else s.BOX_LOCKED_FILL,
				s.GOLD if done else s.UI.PANEL_BORDER, s.UI.BORDER), fr)
		var team: Array = s.LegendsData.finale_team(ch)
		var msz: Vector2 = s._frame_size() * s.FINALE_MINI_SCALE
		var mx: float = fr.position.x + 14.0
		var my: float = fr.position.y + floorf((fr.size.y - msz.y) / 2.0)
		for id in team:
			s.draw_plaque(self, Vector2(mx, my), s.FINALE_MINI_SCALE, str(id),
					"open" if s.Legends.is_unlocked(str(id)) else "locked")
			mx += msz.x + 6.0
		var f: Dictionary = s.LegendsData.chapter(ch).get("finale", {})
		var tx: float = fr.position.x + s.FINALE_TEXT_X
		var tw: float = fr.end.x - tx - 14.0
		s.draw_text(self, Vector2(tx, fr.position.y + 32.0), "ERA FINALE", 26, s.GOLD)
		s.draw_text(self, Vector2(tx, fr.position.y + 62.0), "%s  -  TO %d" % [str(f.get("label", "FINALE")),
				int(f.get("target", 21))], 20, s.UI.TEXT_COLOR)
		var st: String = "FINALE WON" if done else ("OPEN" if f_open else "LOCKED: BEAT ALL %d LEGENDS" %
				s.LegendsData.legend_ids(ch).size())
		s.draw_text(self, Vector2(tx, fr.position.y + 96.0), st, 20,
				s.GOLD if done else (s.OPEN_GREEN if f_open else s.WARN_COLOR))
		s.draw_pips(self, Vector2(fr.end.x - 50.0, fr.position.y + 90.0), s.Legends.token_best(
				s.Legends.finale_key(ch)))
		if s._pick == s.FINALE_PICK:
			draw_rect(fr.grow(-2.0), s.GOLD, false, 4.0)
		# your crew
		var cr: Rect2 = s.CREW_RECT
		draw_style_box(s.UI.style_box(s.BOX_FILL, s.UI.PANEL_BORDER, s.UI.BORDER), cr)
		var crew: Dictionary = s._crew(s._pick)
		var kings: bool = str(crew.get("crew", "")) == s.Legends.CREW_KINGS
		s.draw_text(self, cr.position + Vector2(16, 30), "YOUR CREW", 24, s.GOLD)
		s.draw_text(self, cr.position + Vector2(170, 30), "THE KINGS AT EVEN RATINGS" if kings else
				"YOUR ROAD TRIP STARTERS", 18, s.DIM_TEXT)
		var ps: Array = crew.get("players", [])
		var swapped: Array = []
		for sw in crew.get("swaps", []):
			swapped.append(str((sw as Dictionary).get("in", "")))
		for i in ps.size():
			var pd: Dictionary = ps[i]
			var x: float = cr.position.x + 16.0 + i * s.CREW_SLOT_W
			var box := Vector2(x + (s.CREW_SLOT_W - 40.0 * s.CREW_SPRITE_SCALE) / 2.0 - 8.0,
					cr.position.y + s.CREW_SPRITE_TOP)
			var info: Dictionary = s.crew_card(pd)
			var tex: Texture2D = info.get("texture", null)
			if tex != null:
				var rr: Rect2 = s.Sheets.card_rect(info, box, s.CREW_SPRITE_SCALE)
				draw_texture_rect(tex, rr, false)
			else:
				draw_circle(box + Vector2(40, 30), 22.0, s.SILHOUETTE_COLOR)
				draw_rect(Rect2(box + Vector2(16, 56), Vector2(48, 70)), s.SILHOUETTE_COLOR)
			var name_y: float = cr.end.y - 16.0
			s.draw_fit(self, Vector2(x - 8.0, name_y), str(pd.get("name", pd.get("id", ""))), 22, 14,
					s.WARN_COLOR if swapped.has(str(pd.get("id", ""))) else s.UI.TEXT_COLOR, s.CREW_SLOT_W)
			if i == 0:
				var bc := Vector2(x + 14.0, cr.position.y + 58.0)
				draw_circle(bc, 22.0, s.YOU_COLOR)
				draw_arc(bc, 22.0, 0.0, TAU, 24, s.UI.OUTLINE_COLOR, 2.0)
				draw_string(ThemeDB.fallback_font, Vector2(bc.x - 22.0, bc.y + 6.0), "YOU", HORIZONTAL_ALIGNMENT_CENTER,
						44.0, 16, s.UI.LIT_TEXT)
		var nx: float = cr.position.x + s.CREW_NOTE_X
		var nw: float = cr.end.x - nx - 14.0
		var note: String = str(crew.get("note", ""))
		var txt: String = ""
		var col: Color = s.DIM_TEXT
		if kings:
			txt = "%s. Start a Road Trip and your own starters play these games." % note
			col = s.WARN_COLOR
		elif note != "":
			txt = "%s. A legend never plays against himself." % note
			col = s.WARN_COLOR
		else:
			txt = "Your trip's starters, as they are now. A stronger crew makes these games easier."
		s.draw_wrapped(self, Vector2(nx, cr.position.y + 66.0), txt, 19, col, nw, 6)


# The picked game's best tokens (detail panel).
class Pips extends Control:
	var best := 0
	var n := 3
	var r := 7.0

	func _draw() -> void:
		for i in n:
			var p := Vector2(-r * 3.0 * (n - 1) / 2.0 + r * 3.0 * i, 0.0)
			draw_circle(p, r, Color(1.0, 0.82, 0.25) if i < best else Color(0.3, 0.31, 0.37))
			draw_arc(p, r, 0.0, TAU, 16, Color(0, 0, 0, 0.85), 2.0)
