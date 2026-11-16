extends CanvasLayer
# Difficulty panel (P3-08, owner Q7 a): three big EASY / NORMAL / HARD buttons, built in code. main.gd shows it when
# the game opens (the game waits behind it) and after each game under the final score. The remembered level is lit.
# One tap on a level: Difficulty.level = it, Difficulty.save() (user://settings.cfg), reload the scene; the start
# panel is shown only once per run, so the reloaded game starts at once.
# Touch first: the panel stops taps (main.gd also turns the joystick and A/B off while it's up). Desktop: mouse, or
# A/D (left/right arrows) or K to move the light and J / Space / Enter to play the lit level.
# --autoplay and --humantest never show it (main.gd); they keep Difficulty.from_cmdline() (Hard by default).

const Difficulty = preload("res://scripts/difficulty.gd")

const BUTTON_SIZE := Vector2(300, 140)   # px at the 1280x720 base: finger-sized on a tablet (board: at least 200x110)
const BUTTON_GAP := 40                   # px between the buttons
const BUTTON_FONT := 46
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

var game                                 # main.gd
var showing := false
var _lit: int = Difficulty.NORMAL
var _arm_t := 0.0
var _root: Control
var _title: Label
var _sub: Label
var _buttons: Array = []

# Once per run, before the players are made (player.gd calls Difficulty.init_once() too, later, which is then a no-op):
# first launch (nothing saved) plays Normal; a saved level wins; --difficulty (and autoplay/humantest = Hard) win over both.
static func prepare_level() -> void:
	if _prepared:
		return
	_prepared = true
	Difficulty.level = Difficulty.NORMAL
	Difficulty.init_once()

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
