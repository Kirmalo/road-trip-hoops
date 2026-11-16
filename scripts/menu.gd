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

const Difficulty = preload("res://scripts/difficulty.gd")
const Looks = preload("res://scripts/court_looks.gd")

const BUTTON_SIZE := Vector2(300, 140)   # px at the 1280x720 base: finger-sized on a tablet (board: at least 200x110)
const BUTTON_GAP := 40                   # px between the buttons
const BUTTON_FONT := 46
const OPT_SIZE := Vector2(380, 110)      # COURT and MUSIC buttons: wide enough for "COURT: BLACKTOP", a bit lower than a
                                         # level button (board min 200x110)
const OPT_FONT := 34
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

static var start_done := false           # the launch panel was answered this run (survives reload_current_scene())
static var _prepared := false
static var _settings_done := false
static var music_on := true              # the MUSIC choice (main.gd passes it to audio.set_music_on at launch)

var game                                 # main.gd
var showing := false
var _lit: int = Difficulty.NORMAL
var _arm_t := 0.0
var _root: Control
var _title: Label
var _sub: Label
var _buttons: Array = []
var _court_btn: Button
var _music_btn: Button

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
	Looks.set_current(str(cfg.get_value(Difficulty.SAVE_SECTION, SAVE_COURT, Looks.current)))
	music_on = bool(cfg.get_value(Difficulty.SAVE_SECTION, SAVE_MUSIC, music_on))

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
	box.add_theme_constant_override("separation", 26)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	_title = _label(box, TITLE_FONT)
	_sub = _label(box, SUB_FONT)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", BUTTON_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	for lv in [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD]:
		var b := Button.new()
		b.text = String(Difficulty.NAMES[lv]).to_upper()
		b.custom_minimum_size = BUTTON_SIZE
		b.focus_mode = Control.FOCUS_NONE   # the light is ours (_lit), not the focus box
		b.add_theme_font_size_override("font_size", BUTTON_FONT)
		b.pressed.connect(_pick.bind(lv))
		row.add_child(b)
		_buttons.append(b)
	var opts := HBoxContainer.new()
	opts.alignment = BoxContainer.ALIGNMENT_CENTER
	opts.add_theme_constant_override("separation", BUTTON_GAP)
	opts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(opts)
	_court_btn = _opt_button(opts, _pick_court)
	_music_btn = _opt_button(opts, _toggle_music)

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
	_title.modulate = Color.WHITE
	_sub.text = "Pick your level"
	_open(0.0)

# after a game: the final score on top, a tap on a level plays again (replaces "tap to play again")
func show_game_over(score: Array, winner: int, color: Color) -> void:
	_title.text = "FINAL  %d - %d   %s WINS!" % [score[0], score[1], game.TEAM_NAMES[winner]]
	_title.modulate = color
	_sub.text = "Tap a level to play again"
	_open(ARM_TIME_OVER)

func _open(arm: float) -> void:
	showing = true
	_arm_t = arm
	_lit = Difficulty.level
	_root.visible = true
	_refresh()
	if game != null:
		game.stat("menu_shown")
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
		var col: Color = LIT_COLOR if lit else OFF_COLOR
		var sb := _style(col, LIT_BORDER if lit else OFF_BORDER, 8 if lit else 3)
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
	_music_btn.text = "MUSIC: ON" if music_on else "MUSIC: OFF"
	var mc: Color = OFF_TEXT if music_on else OPT_OFF_TEXT
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		_court_btn.add_theme_color_override(k, OFF_TEXT)
		_music_btn.add_theme_color_override(k, mc)
	for b in [_court_btn, _music_btn]:
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
			_lit = maxi(_lit - 1, Difficulty.EASY)
			_refresh()
		KEY_D, KEY_RIGHT, KEY_K:
			_lit = (_lit + 1) % _buttons.size() if event.keycode == KEY_K else mini(_lit + 1, Difficulty.HARD)
			_refresh()
		KEY_J, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			_pick(_lit)
		KEY_C:
			_pick_court()
		KEY_M:
			_toggle_music()

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
	Looks.set_current(Looks.next_name())
	_save_setting(SAVE_COURT, Looks.current)
	start_done = false
	if game != null:
		game.stat("menu_court_" + Looks.current)
	get_tree().call_deferred("reload_current_scene")

# MUSIC: on/off at once, saved; the panel stays up
func _toggle_music() -> void:
	if not showing or _arm_t > 0.0:
		return
	music_on = not music_on
	_save_setting(SAVE_MUSIC, music_on)
	if game != null:
		game.audio.set_music_on(music_on)
		game.stat("menu_music_" + ("on" if music_on else "off"))
	_refresh()
