extends CanvasLayer
# Difficulty panel (P3-08, owner Q7 a): three big EASY / NORMAL / HARD buttons, built in code. main.gd shows it when
# the game opens (the game waits behind it) and after each game under the final score. The remembered level is lit.
# One tap on a level: Difficulty.level = it, Difficulty.save() (user://settings.cfg), reload the scene; the start
# panel is shown only once per run, so the reloaded game starts at once.
# Under the levels (P4-11, owner Q4 a and Q5 a): COURT: <look> cycles the court looks (court_looks.gd), saves it and
# reloads the scene back to the start panel, so the new court shows behind it; MUSIC ON/OFF switches the music
# (audio.gd) at once. Both are remembered in user://settings.cfg and read once per run by prepare_settings().
# Touch first: the panel stops taps (main.gd also turns the joystick and A/B off while it's up). Desktop: mouse, or
# A/D (left/right arrows) or K to move the light and J / Space / Enter to play the lit level; C = COURT, M = MUSIC.
# --autoplay and --humantest never show it (main.gd); they keep Difficulty.from_cmdline() (Hard by default).
# P5-06: a TITLE button next to COURT and MUSIC goes back to the title screen (title.gd), where QUICK GAME brings
# this start panel back. title.gd's Settings use set_music() and save_setting() below. Desktop: T or Escape = TITLE.
# P6-17 (owner Q9): COURT cycles the gym, the blacktop and the courts of the cities whose boss you have beaten on a
# Road Trip (Difficulty.unlock_court; a locked city's court doesn't show). A city court brings its city's twist
# (quick_twist(), read by main.gd), shown in a line under the buttons. Test flags: --unlock-all, --unlock-none.
# P6-T3 (owner): YOUR TEAM and OPPONENT under the levels cycle through the Quick Game teams (Difficulty.quick_teams():
# the Cornfield Kings, the Bridge Runners and every crew beaten on a Road Trip); each tap = the next team, saved, and
# the scene reloads back to this panel with the new crews on the court. The same crew can't be on both sides: the
# other side moves on to the next team. main.gd reads quick_team_ids(). Desktop: Y = YOUR TEAM, O = OPPONENT.
# Test runs (autoplay, humantest, screenshots) play the Kings vs the Bridge Runners unless --quick-teams <blue>,<red>.
# P8-19: a 4th level button, LEGEND, once the stars open it (Difficulty.offered_levels(); --stars 72 in a test run),
# and the COURT button also cycles the star reward courts (Cosmetics.open_court_looks(): MIDNIGHT, GOLD HALL; no twist).
# P11-34 (owner P8 b): the era teams (era_teams.gd, open once their finale three are unlocked in Legends) are in the
# YOUR TEAM / OPPONENT lists (Difficulty.quick_teams(), the button in the era crew's color), and each open era team's
# court (EraTeams.look_of(): OLD GYM, NIGHT PARK, BIG STAGE) joins the COURT list after the city courts and before the
# star reward courts. An era court brings its chapter's twist (EraTeams.twist_of_look(): OLD SCHOOL, ISO BALL, SPACE
# THE FLOOR) in the twist line, the banner and the pause line, and its era's music (the look's "music" track). A closed
# era's court is not offered; --court era_grand plays its twist only when that era is open (or --unlock-all).

const Difficulty = preload("res://scripts/difficulty.gd")
const Looks = preload("res://scripts/court_looks.gd")
const Flow = preload("res://scripts/flow.gd")
const Cities = preload("res://scripts/cities.gd")     # which city owns a court look, and its twist (P6-17)
const Twists = preload("res://scripts/twists.gd")     # the twist's line under the buttons
const Cosmetics = preload("res://scripts/cosmetics.gd")   # open_court_looks(): the star reward courts (P8-19)
const ERA_TEAMS_PATH := "res://scripts/era_teams.gd"     # era teams and their courts (P11-34), loaded at run time

const BUTTON_SIZE := Vector2(300, 140)   # px at the 1280x720 base: finger-sized on a tablet (board: at least 200x110)
const BUTTON_GAP := 40                   # px between the buttons
const BUTTON_FONT := 46
const BUTTON_SIZE_4 := Vector2(270, 140)  # P8-19: with LEGEND, four level buttons (4 x 270 + 3 x 24 fits 1280 px)
const BUTTON_GAP_4 := 24
const LEGEND_OFF_COLOR := Color(0.45, 0.16, 0.42)   # the LEGEND button when not lit (purple, apart from the others)
const LEGEND_OFF_BORDER := Color(1.0, 0.7, 0.95, 0.8)
const OPT_SIZE := Vector2(380, 110)      # COURT and MUSIC buttons: wide enough for "COURT: BLACKTOP", a bit lower than a
                                         # level button (board min 200x110)
const OPT_FONT := 34
const TITLE_BTN_SIZE := Vector2(220, 110)        # TITLE: the smallest option (board min 200x110)
const OPT_COLOR := Color(0.2, 0.22, 0.27)        # COURT / MUSIC: neutral, so they don't look like a level
const OPT_BORDER := Color(0.85, 0.85, 0.9, 0.8)
const OPT_OFF_TEXT := Color(0.65, 0.65, 0.7)     # MUSIC OFF
const SAVE_COURT := "court"              # keys in Difficulty.SAVE_PATH, section Difficulty.SAVE_SECTION
const SAVE_MUSIC := "music"
const TITLE_FONT := 60
const SUB_FONT := 28
const DIM_COLOR := Color(0, 0, 0, 0.62)  # darkens the court behind the panel
const LIT_COLOR := Color(1.0, 0.82, 0.25)        # the remembered level
const LIT_BORDER := Color(1.0, 1.0, 1.0)
const OFF_COLOR := Color(0.16, 0.3, 0.6)         # the other levels
const OFF_BORDER := Color(0.6, 0.75, 1.0, 0.8)
const LIT_TEXT := Color(0.12, 0.1, 0.05)
const OFF_TEXT := Color.WHITE
const ARM_TIME_OVER := 0.8               # seconds before the game-over panel takes a tap (a thumb still on SHOOT
                                         # when the game ends must not pick a level by accident)
const LAYER := 20                        # over the HUD (10)
const TWIST_FONT := 28                   # the court's twist line under the buttons (P6-17)
const TWIST_COLOR := Color(1.0, 0.9, 0.55)   # as main.gd's tip-off twist line
const BOX_GAP := 18                      # px between the panel's rows (6 rows fit 720 px high)
const TEAM_BTN_SIZE := Vector2(470, 110) # YOUR TEAM / OPPONENT (P6-T3): two lines, "BOARDWALK BOMBERS" fits
const TEAM_FONT := 30
const TEAM_DARKEN := 0.45                # the button wears its crew's ui color, darkened for white text
const VS_FONT := 34
const TITLE_FONT_LONG := 42              # the game-over line with long crew names
const TITLE_LONG_CHARS := 30             # ... from this many characters
const SAVE_TEAMS := ["quick_team", "quick_opponent"]   # keys in Difficulty.SAVE_PATH: BLUE's and RED's crew ids
const QUICK_TEAMS_FLAG := "--quick-teams"   # test flag: --quick-teams <blue>,<red> (any known crew, locked or not)
const TEST_RUN_FLAGS := ["--autoplay", "--humantest", "--shots", "--ballshots", "--menushot", "--twistshots",
		"--anim-test", "--howto-shots"]

static var start_done := false           # the launch panel was answered this run (survives reload_current_scene())
static var _prepared := false
static var _settings_done := false
static var music_on := true              # the MUSIC choice (main.gd passes it to audio.set_music_on at launch)
static var team_picks: Array = [Difficulty.KINGS, Difficulty.RUNNERS]   # P6-T3: BLUE's and RED's crew ids

var game                                 # main.gd
var showing := false
var _lit: int = Difficulty.NORMAL
var _arm_t := 0.0
var _root: Control
var _title: Label
var _sub: Label
var _buttons: Array = []
var _levels: Array = []                  # the level of each button in _buttons (P8-19: LEGEND when open)
var _court_btn: Button
var _music_btn: Button
var _title_btn: Button
var _twist_lbl: Label
var _team_btns: Array = []               # [YOUR TEAM, OPPONENT]

# Once per run, before the players are made (player.gd calls Difficulty.init_once() too, later, which is then a no-op):
# first launch (nothing saved) plays Normal; a saved level wins; --difficulty (and autoplay/humantest = Hard) win over both.
static func prepare_level() -> void:
	if _prepared:
		return
	_prepared = true
	Difficulty.level = Difficulty.NORMAL
	Difficulty.init_once()

# Once per run, before the court is built: the saved court look and music choice. court.gd reads -- --court later,
# which wins over the saved look.
static func prepare_settings() -> void:
	if _settings_done:
		return
	_settings_done = true
	var cfg := ConfigFile.new()
	if cfg.load(Difficulty.SAVE_PATH) != OK:
		return
	var saved: String = str(cfg.get_value(Difficulty.SAVE_SECTION, SAVE_COURT, Looks.current))
	if quick_courts().has(saved):   # a city court only while it is unlocked (else the default court)
		Looks.set_current(saved)
	music_on = bool(cfg.get_value(Difficulty.SAVE_SECTION, SAVE_MUSIC, music_on))
	if not _test_run():   # the tests play the default teams (or --quick-teams), never the saved picks
		for t in 2:
			team_picks[t] = str(cfg.get_value(Difficulty.SAVE_SECTION, SAVE_TEAMS[t], team_picks[t]))

# the MUSIC choice, saved (title.gd's Settings; the panel's own MUSIC button too)
static func set_music(on: bool) -> void:
	music_on = on
	save_setting(SAVE_MUSIC, music_on)

# ---------------- Quick Game courts and twists (P6-17) ----------------

# The courts the COURT button offers: gym, blacktop, every unlocked city's court (Looks.names() order), then the court
# of every open era team (P11-34, timeline order), then the star reward courts that are open (P8-19,
# Cosmetics.open_court_looks())
static func quick_courts() -> Array:
	var open_cities: Array = Difficulty.unlocked_cities(Cities.ROUTE)
	var rewards: Array = Cosmetics.open_court_looks()
	var out: Array = []
	var tail: Array = []
	for n in Looks.names():
		var c: String = city_of_look(str(n))
		if Looks.always_open(str(n)) or (c != "" and open_cities.has(c)):
			out.append(str(n))
		elif rewards.has(str(n)):
			tail.append(str(n))
	for look in open_era_looks():
		if not out.has(look) and not tail.has(look):
			out.append(look)
	return out + tail

# the city whose court this look is ("" for gym, blacktop or an unknown look)
static func city_of_look(look_id: String) -> String:
	for id in Cities.ROUTE:
		if str(Cities.city(id).get("look", "")) == look_id:
			return str(id)
	return ""

# era_teams.gd, or null when it is missing (then no era courts)
static func _era_teams() -> GDScript:
	if not ResourceLoader.exists(ERA_TEAMS_PATH):
		return null
	return load(ERA_TEAMS_PATH) as GDScript

# the court looks of the open era teams, in timeline order (only looks court_looks.gd has)
static func open_era_looks() -> Array:
	var out: Array = []
	var et: GDScript = _era_teams()
	if et == null:
		return out
	for eid in et.call("open_ids"):
		var look: String = str(et.call("look_of", str(eid)))
		if look != "" and Looks.LOOKS.has(look) and not out.has(look):
			out.append(look)
	return out

# the twist an era court brings in Quick Game: its chapter's twist while its era team is open, else "" (also "" for
# every other look)
static func era_twist(look_id: String) -> String:
	var et: GDScript = _era_teams()
	if et == null:
		return ""
	var eid: String = str(et.call("era_of_look", look_id))
	if eid == "" or not bool(et.call("is_open", eid)):
		return ""
	var t: String = str(et.call("twist_of_look", look_id))
	return t if Twists.TWISTS.has(t) else ""

# The twist of a Quick Game on the current court: the city's twist on an unlocked city court, the chapter's twist on
# an open era team's court (P11-34), else "none". main.gd calls it before the court is built, so the -- --court test
# flag is read here first (a locked court from --court plays without the twist, unless --unlock-all).
static func quick_twist() -> String:
	Looks.parse_args()
	var et_twist: String = era_twist(Looks.current)
	if et_twist != "":
		return et_twist
	var c: String = city_of_look(Looks.current)
	if c == "" or Looks.always_open(Looks.current) or not Difficulty.is_court_unlocked(c):
		return "none"
	return Cities.twist(c)

# "WIND: long shots and lobs drift" for a twist id (the banner with its first word in capitals); "" for none. Used by
# this panel, the trip map's city card and the pause screen.
static func twist_line(twist_id: String) -> String:
	if twist_id == "" or twist_id == "none":
		return ""
	var banner: String = str(Twists.info(twist_id).get("banner", ""))
	var cut: int = banner.find(":")
	if cut < 0:
		return banner
	return banner.substr(0, cut).to_upper() + banner.substr(cut)

# ---------------- Quick Game teams (P6-T3) ----------------

# BLUE's and RED's crew ids for this Quick Game: --quick-teams <blue>,<red> in a test run, else the picks, each one
# open (else the Kings for BLUE, the Bridge Runners for RED) and never the same crew twice (RED moves on)
static func quick_team_ids() -> Array:
	var flag: Array = _flag_teams()
	if flag.size() == 2:
		return flag
	var avail: Array = Difficulty.quick_teams()
	var out: Array = [str(team_picks[0]), str(team_picks[1])]
	if not avail.has(out[0]):
		out[0] = Difficulty.KINGS
	if not avail.has(out[1]):
		out[1] = Difficulty.RUNNERS
	if out[1] == out[0]:
		out[1] = _next_team(avail, out[1])
	return out

# the team after `id` in `avail` (wraps; the first one for an id not in it)
static func _next_team(avail: Array, id: String) -> String:
	if avail.is_empty():
		return id
	return str(avail[(avail.find(id) + 1) % avail.size()])

# --quick-teams blue,red (or --quick-teams=blue,red): two different known crew ids, else [] (with a warning line)
static func _flag_teams() -> Array:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var v := ""
	for i in args.size():
		if args[i].begins_with(QUICK_TEAMS_FLAG + "="):
			v = args[i].substr(QUICK_TEAMS_FLAG.length() + 1)
		elif args[i] == QUICK_TEAMS_FLAG and i + 1 < args.size():
			v = args[i + 1]
	if v == "":
		return []
	var parts: PackedStringArray = v.to_lower().split(",")
	if parts.size() != 2 or parts[0] == parts[1] or Difficulty.team_info(parts[0]).is_empty() \
			or Difficulty.team_info(parts[1]).is_empty():
		print("%s: want two different crews out of %s; playing the picks" % [QUICK_TEAMS_FLAG,
				", ".join(PackedStringArray(_all_ids()))])
		return []
	return [parts[0], parts[1]]

static func _all_ids() -> Array:
	var out: Array = []
	for t in Difficulty.all_teams():
		out.append(str((t as Dictionary)["id"]))
	var et: GDScript = _era_teams()
	if et != null:
		for eid in et.call("ids"):   # the era teams too (P11-34), open or not, like the crews
			out.append(str(eid))
	return out

static func _test_run() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for f in TEST_RUN_FLAGS:
		if args.has(f):
			return true
	return false

static func save_setting(key: String, value) -> void:
	_save_setting(key, value)

static func _save_setting(key: String, value) -> void:
	var cfg := ConfigFile.new()
	cfg.load(Difficulty.SAVE_PATH)   # keep the other settings in the file
	cfg.set_value(Difficulty.SAVE_SECTION, key, value)
	cfg.save(Difficulty.SAVE_PATH)

func _ready() -> void:
	layer = LAYER
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP   # nothing under the panel gets a tap or a click
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", BOX_GAP)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	_title = _label(box, TITLE_FONT)
	_sub = _label(box, SUB_FONT)
	_levels = Difficulty.offered_levels()
	var four: bool = _levels.size() > 3
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", BUTTON_GAP_4 if four else BUTTON_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	for lv in _levels:
		var b := Button.new()
		b.text = String(Difficulty.NAMES[lv]).to_upper()
		b.custom_minimum_size = BUTTON_SIZE_4 if four else BUTTON_SIZE
		b.focus_mode = Control.FOCUS_NONE   # the light is ours (_lit), not the focus box
		b.add_theme_font_size_override("font_size", BUTTON_FONT)
		b.pressed.connect(_pick.bind(lv))
		row.add_child(b)
		_buttons.append(b)
	var trow := HBoxContainer.new()   # YOUR TEAM  VS  OPPONENT (P6-T3)
	trow.alignment = BoxContainer.ALIGNMENT_CENTER
	trow.add_theme_constant_override("separation", BUTTON_GAP)
	trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(trow)
	for side in 2:
		var tb := _opt_button(trow, _pick_team.bind(side))
		tb.custom_minimum_size = TEAM_BTN_SIZE
		tb.add_theme_font_size_override("font_size", TEAM_FONT)
		tb.clip_text = true
		_team_btns.append(tb)
		if side == 0:
			var vs := _label(trow, VS_FONT)
			vs.text = "VS"
			vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vs.size_flags_vertical = Control.SIZE_FILL
	var opts := HBoxContainer.new()
	opts.alignment = BoxContainer.ALIGNMENT_CENTER
	opts.add_theme_constant_override("separation", BUTTON_GAP)
	opts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(opts)
	_court_btn = _opt_button(opts, _pick_court)
	_music_btn = _opt_button(opts, _toggle_music)
	_title_btn = _opt_button(opts, _go_title)
	_title_btn.custom_minimum_size = TITLE_BTN_SIZE
	_title_btn.text = "TITLE"
	_twist_lbl = _label(box, TWIST_FONT)
	_twist_lbl.modulate = TWIST_COLOR

func _opt_button(parent: Control, on_tap: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = OPT_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", OPT_FONT)
	b.pressed.connect(on_tap)
	var sb := _style(OPT_COLOR, OPT_BORDER, 3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", _style(OPT_COLOR.lightened(0.2), LIT_BORDER, 6))
	b.add_theme_stylebox_override("disabled", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	parent.add_child(b)
	return b

func _label(parent: Control, size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.outline_size = 8
	ls.outline_color = Color(0, 0, 0, 0.85)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

# at launch: the game waits behind the panel
func show_start() -> void:
	_title.text = "ROAD TRIP HOOPS"
	_title.label_settings.font_size = TITLE_FONT
	_title.modulate = Color.WHITE
	_sub.text = "Pick your level"
	_open(0.0)

# after a game: the final score on top, a tap on a level plays again (replaces "tap to play again")
func show_game_over(score: Array, winner: int, color: Color) -> void:
	_title.text = "FINAL  %d - %d   %s WINS!" % [score[0], score[1], game.TEAM_NAMES[winner]]
	_title.label_settings.font_size = TITLE_FONT_LONG if _title.text.length() >= TITLE_LONG_CHARS else TITLE_FONT
	_title.modulate = color
	_sub.text = "Tap a level to play again"
	_open(ARM_TIME_OVER)

func _open(arm: float) -> void:
	showing = true
	_arm_t = arm
	_lit = _levels.find(Difficulty.level)   # the button of the remembered level
	if _lit < 0:                            # LEGEND remembered but not offered (closed): light HARD
		_lit = _levels.find(Difficulty.HARD)
	_root.visible = true
	_refresh()
	if game != null:
		game.stat("menu_shown")
		if game.get("menushot"):
			print("QUICK COURTS %s | court %s | twist %s" % [", ".join(PackedStringArray(quick_courts())), Looks.current,
					quick_twist()])
			print("QUICK TEAMS %s | picked %s" % [", ".join(PackedStringArray(Difficulty.quick_teams())),
					" vs ".join(PackedStringArray(quick_team_ids()))])
		game.audio.play_music("menu")   # menu music on the panels, full volume (owner Q5 a)
		game.audio.set_music_ducked(false)

func _process(delta: float) -> void:
	if showing and _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_refresh()

func _refresh() -> void:
	for i in _buttons.size():
		var b: Button = _buttons[i]
		var lit: bool = i == _lit
		var legend: bool = int(_levels[i]) == Difficulty.LEGEND
		var col: Color = LIT_COLOR if lit else (LEGEND_OFF_COLOR if legend else OFF_COLOR)
		var sb := _style(col, LIT_BORDER if lit else (LEGEND_OFF_BORDER if legend else OFF_BORDER), 8 if lit else 3)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", _style(col.darkened(0.25), LIT_BORDER, 8))
		b.add_theme_stylebox_override("disabled", sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var tc: Color = LIT_TEXT if lit else OFF_TEXT
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(k, tc)
		b.disabled = _arm_t > 0.0
		b.modulate.a = 0.6 if _arm_t > 0.0 else 1.0
	_court_btn.text = "COURT: " + str(Looks.look().get("name", Looks.current))
	_twist_lbl.text = twist_line(quick_twist())   # "" on gym and blacktop
	_music_btn.text = "MUSIC: ON" if music_on else "MUSIC: OFF"
	var mc: Color = OFF_TEXT if music_on else OPT_OFF_TEXT
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		_court_btn.add_theme_color_override(k, OFF_TEXT)
		_music_btn.add_theme_color_override(k, mc)
		_title_btn.add_theme_color_override(k, OFF_TEXT)
	var ids: Array = quick_team_ids()
	for side in _team_btns.size():
		var tb: Button = _team_btns[side]
		var info: Dictionary = Difficulty.team_info(str(ids[side]))
		tb.text = "%s\n%s" % ["YOUR TEAM" if side == 0 else "OPPONENT", str(info.get("name", ids[side]))]
		var crew_col: Color = info.get("color", OPT_COLOR)
		var fill: Color = crew_col.darkened(TEAM_DARKEN)
		var sb := _style(fill, OPT_BORDER, 3)
		tb.add_theme_stylebox_override("normal", sb)
		tb.add_theme_stylebox_override("hover", sb)
		tb.add_theme_stylebox_override("pressed", _style(fill.lightened(0.2), LIT_BORDER, 6))
		tb.add_theme_stylebox_override("disabled", sb)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			tb.add_theme_color_override(k, OFF_TEXT)
	for b in [_court_btn, _music_btn, _title_btn] + _team_btns:
		b.disabled = _arm_t > 0.0
		b.modulate.a = 0.6 if _arm_t > 0.0 else 1.0

func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(18)
	return sb

# desktop testing: main.gd hands key presses here while the panel is up
func key(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_A, KEY_LEFT:
			_lit = maxi(_lit - 1, 0)
			_refresh()
		KEY_D, KEY_RIGHT, KEY_K:
			_lit = (_lit + 1) % _buttons.size() if event.keycode == KEY_K else mini(_lit + 1, _buttons.size() - 1)
			_refresh()
		KEY_J, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			_pick(int(_levels[_lit]))
		KEY_C:
			_pick_court()
		KEY_M:
			_toggle_music()
		KEY_Y:
			_pick_team(0)
		KEY_O:
			_pick_team(1)
		KEY_T, KEY_ESCAPE:
			_go_title()

func _pick(lv: int) -> void:
	if not showing or _arm_t > 0.0:
		return
	showing = false
	start_done = true
	Difficulty.level = lv
	Difficulty.save()
	if game != null:
		game.stat("menu_picks_" + Difficulty.level_name())
	get_tree().call_deferred("reload_current_scene")   # deferred: the Button is still handling this tap

# COURT: the next look, saved; reload back to the start panel (the new court behind it, the level still to pick)
func _pick_court() -> void:
	if not showing or _arm_t > 0.0:
		return
	showing = false
	var open: Array = quick_courts()
	var i: int = open.find(Looks.current)   # -1 (a court opened by --court only) -> the first one
	Looks.set_current(str(open[(i + 1) % open.size()]))
	_save_setting(SAVE_COURT, Looks.current)
	start_done = false
	if game != null:
		game.stat("menu_court_" + Looks.current)
	get_tree().call_deferred("reload_current_scene")

# YOUR TEAM (side 0) / OPPONENT (side 1): that side's next open team, saved; the other side moves on if it would be
# the same crew. Reload back to the start panel (the new crews behind it, the level still to pick), like COURT.
func _pick_team(side: int) -> void:
	if not showing or _arm_t > 0.0:
		return
	var avail: Array = Difficulty.quick_teams()
	if avail.size() < 2:
		return
	showing = false
	var ids: Array = quick_team_ids()
	ids[side] = _next_team(avail, str(ids[side]))
	if ids[1 - side] == ids[side]:
		ids[1 - side] = _next_team(avail, str(ids[1 - side]))
	for t in 2:
		team_picks[t] = str(ids[t])
		_save_setting(SAVE_TEAMS[t], team_picks[t])
	start_done = false
	if game != null:
		game.stat("menu_team_%s_%s" % ["blue" if side == 0 else "red", str(ids[side])])
	get_tree().call_deferred("reload_current_scene")

# MUSIC: on/off at once, saved; the panel stays up
func _toggle_music() -> void:
	if not showing or _arm_t > 0.0:
		return
	set_music(not music_on)
	if game != null:
		game.audio.set_music_on(music_on)
		game.stat("menu_music_" + ("on" if music_on else "off"))
	_refresh()

# TITLE: back to the title screen (P5-06); its QUICK GAME shows the start panel again
func _go_title() -> void:
	if not showing or _arm_t > 0.0:
		return
	showing = false
	start_done = false
	if game != null:
		game.stat("menu_title")
	Flow.go("title")   # deferred reload, like _pick()
