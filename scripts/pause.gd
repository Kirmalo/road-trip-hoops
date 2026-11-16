extends CanvasLayer
# Pause screen (P5-08, owner Q10 a). main.gd adds it in every game a human plays (not under --autoplay).
#
# A pause button (two bars) sits in the top-RIGHT corner during play, away from the joystick half and from A/B (bottom
# right); the shot clock moves left of it. A tap pauses the game (get_tree().paused); this node and audio.gd run with
# PROCESS_MODE_ALWAYS, so the panel and the music keep working. The panel: the score and a stats table for both teams
# (points, field goals made/taken and FG%, dunks, steals, blocks from main.team_stats()), a big RESUME, RESTART (the
# same matchup again from 0-0) and QUIT (to the title in a Quick Game, to the trip map in a trip game; the quit game
# isn't recorded, so it starts again at 0-0), MUSIC ON/OFF and the SOUND volume slider (audio.set_sfx_volume, P5-07).
# Both settings are saved in user://settings.cfg (menu.gd's music key, audio.gd's sfx_volume).
#
# No input leaks: on pause the joystick, A and B let go (a held A is released as if the thumb lifted) and take no
# touches until RESUME_INPUT_DELAY after Resume; while paused the game doesn't run, and the panel stops every tap.
# The pause button ignores taps for RESUME_GUARD s after Resume. RESTART and QUIT need a second tap (CONFIRM_TAPS).
# Desktop testing: Escape or P pauses / resumes. --humantest pauses once (TEST_AT), sends a stray tap on A and checks
# that nothing moved: stats pause_opens, pause_resumes, pause_test_ok or pause_leaks.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const MenuScript = preload("res://scripts/menu.gd")
const AudioScript = preload("res://scripts/audio.gd")

const LAYER := UI.LAYER + 1              # over the HUD (10) and the level panel (20)
const BTN_SIZE := 80.0                   # pause button, px square at the 1280x720 base: thumb-sized
const BTN_MARGIN := 6.0                  # px from the top and right edges (the top bar is 54 px high)
const BTN_COLOR := Color(0.2, 0.22, 0.27, 0.7)   # grey like the option buttons, see-through over the court
const BAR_SIZE := Vector2(9, 30)         # each of the two bars of the pause icon (px)
const BAR_GAP := 10.0                    # px between the two bars
const SHOT_CLOCK_GAP := 14.0             # px between the shot clock text and the pause button
const RESUME_GUARD := 0.5                # s after Resume during which the pause button ignores taps (board risk list)
const RESUME_INPUT_DELAY := 0.15         # s after Resume before the joystick and A/B take touches again
const CONFIRM_TAPS := true               # RESTART and QUIT ask for a second tap (a stray tap must not end the game)
const CONFIRM_TIME := 2.5                # s the second tap may come in
const RESUME_SIZE := Vector2(540, 150)   # the big RESUME
const HALF_SIZE := Vector2(250, 110)     # RESTART / QUIT side by side (board minimum 200 x 110)
const WIDE_SIZE := Vector2(540, 110)     # MUSIC
const RIGHT_GAP := 18                    # px between the rows on the right
const COLUMNS_GAP := 44                  # px between the stats panel and the buttons
const SCORE_FONT := 60                   # the score, each number in its team's color
const STATS_FONT := 28
const HEAD_FONT := 24                    # team names over the stats columns (long crew names wrap onto two lines)
const NAME_WRAP := 10                    # a team name longer than this breaks at its spaces
const STAT_COL_W := 150                  # px, each team's column
const SAMPLE_SFX := "bounce"             # played at the new volume when the slider is let go
const TEST_AT := 20.0                    # --humantest: s of game time before the scripted pause
const TEST_HOLD := 30                    # --humantest: frames it stays paused

var game                                 # main.gd (set before _ready)
var _btn: Button
var _root: Control
var _score_row: HBoxContainer
var _grid: GridContainer
var _music_btn: Button
var _restart_btn: Button
var _quit_btn: Button
var _vol_label: Label
var _slider: HSlider
var _open := false
var _guard_t := 0.0
var _input_t := 0.0
var _confirm := ""                       # "restart" / "quit": waiting for the second tap
var _confirm_t := 0.0
var _vol_dirty := false
var _test := false
var _test_done := false
var _test_frames := 0
var _test_time := 0.0
var _test_ball := Vector2.ZERO
var _test_leaks := 0                     # A / B presses the game saw while paused (must stay 0)

func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS   # the panel works while the tree is paused
	_test = OS.get_cmdline_user_args().has("--humantest")
	AudioScript.read_settings()
	_build_button()
	_build_panel()
	if game != null and game.shot_label != null:
		game.shot_label.offset_right = -(BTN_MARGIN + BTN_SIZE + SHOT_CLOCK_GAP)   # the shot clock, left of the button

# ---------------- the pause button ----------------

func _build_button() -> void:
	_btn = Button.new()
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn.offset_left = -(BTN_MARGIN + BTN_SIZE)
	_btn.offset_right = -BTN_MARGIN
	_btn.offset_top = BTN_MARGIN
	_btn.offset_bottom = BTN_MARGIN + BTN_SIZE
	var sb := UI.style_box(BTN_COLOR, UI.OPT_BORDER, UI.BORDER)
	_btn.add_theme_stylebox_override("normal", sb)
	_btn.add_theme_stylebox_override("hover", sb)
	_btn.add_theme_stylebox_override("disabled", sb)
	_btn.add_theme_stylebox_override("pressed", UI.style_box(UI.OPT_COLOR.lightened(0.2), UI.LIT_BORDER, 6))
	_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_btn.icon = _pause_icon()
	_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn.pressed.connect(open)
	_btn.visible = false
	add_child(_btn)

func _pause_icon() -> Texture2D:
	var w: int = int(BAR_SIZE.x * 2.0 + BAR_GAP)
	var h: int = int(BAR_SIZE.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(0, 0, int(BAR_SIZE.x), h), Color.WHITE)
	img.fill_rect(Rect2i(w - int(BAR_SIZE.x), 0, int(BAR_SIZE.x), h), Color.WHITE)
	return ImageTexture.create_from_image(img)

func can_pause() -> bool:
	if game == null or _open or get_tree().paused:
		return false
	if game.game_over or game.menu_wait:
		return false
	return not (game.menu != null and game.menu.showing)

# ---------------- the panel ----------------

func _build_panel() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP   # nothing under the panel gets a tap
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = UI.DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	var cols := UI.hbox(center, COLUMNS_GAP)

	# left: PAUSED, the score, the stats table
	var panel := UI.panel(cols)
	var left := UI.vbox(panel, 14, false)
	UI.title(left, "PAUSED")
	_score_row = UI.hbox(left, 20)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_grid)

	# right: RESUME, RESTART / QUIT, MUSIC, SOUND
	var right := UI.vbox(cols, RIGHT_GAP, false)
	UI.button(right, "RESUME", resume, UI.KIND_LIT, RESUME_SIZE)
	var row := UI.hbox(right, RIGHT_GAP)
	_restart_btn = UI.button(row, "RESTART", _on_restart, UI.KIND_MAIN, HALF_SIZE)
	_quit_btn = UI.button(row, "QUIT", _on_quit, UI.KIND_MAIN, HALF_SIZE)
	_music_btn = UI.button(right, "", _toggle_music, UI.KIND_OPT, WIDE_SIZE)
	_vol_label = UI.label(right, "", UI.OPT_FONT)
	_slider = UI.slider(right, AudioScript.sfx_volume, _on_volume)
	_slider.drag_ended.connect(_on_volume_let_go)
	_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func open() -> void:
	if not can_pause() or _guard_t > 0.0:
		return
	_open = true
	_confirm = ""
	_release_controls()
	get_tree().paused = true
	_refresh()
	_btn.visible = false
	_root.visible = true
	game.stat("pause_opens")

# the joystick, A and B let go and take no touches until after Resume
func _release_controls() -> void:
	var c = game.controls
	if c == null:
		return
	if c.a_index >= 0 or game.key_a_down:
		c.a_index = -1
		game.key_a_down = false
		c.a_released.emit()   # as if the thumb lifted (a shot already rising goes up now, not after the pause)
	c.joy_index = -1
	c.b_index = -1
	c.set_process_input(false)
	c.visible = false   # no joystick or A/B under the panel

func resume() -> void:
	if not _open:
		return
	_close()
	_guard_t = RESUME_GUARD
	_input_t = RESUME_INPUT_DELAY
	if game.controls != null:
		game.controls.visible = not game.autoplay
	get_tree().set_deferred("paused", false)   # deferred: the RESUME tap finishes while the game still waits
	game.stat("pause_resumes")

func _close() -> void:
	_open = false
	_root.visible = false
	_confirm = ""
	if _vol_dirty:
		_vol_dirty = false
		AudioScript.save_sfx_volume()

func _on_restart() -> void:
	if not _confirmed("restart"):
		return
	_close()
	game.stat("pause_restarts")
	get_tree().paused = false
	Flow.go(Flow.GAME)   # the same matchup (Flow.match is kept; Quick Game: the same level and court) from 0-0

func _on_quit() -> void:
	if not _confirmed("quit"):
		return
	_close()
	game.stat("pause_quits")
	get_tree().paused = false
	Flow.go("map" if Flow.in_trip() else "title")   # nothing is recorded: the quit game starts again at 0-0

# first tap arms the button ("RESTART?"), the second within CONFIRM_TIME does it
func _confirmed(what: String) -> bool:
	if not CONFIRM_TAPS or _confirm == what:
		return true
	_confirm = what
	_confirm_t = CONFIRM_TIME
	_refresh_buttons()
	return false

func _toggle_music() -> void:
	MenuScript.music_on = not MenuScript.music_on
	game.audio.set_music_on(MenuScript.music_on)
	game.stat("pause_music_" + ("on" if MenuScript.music_on else "off"))
	if not _test:
		var cfg := ConfigFile.new()
		cfg.load(AudioScript.SETTINGS_PATH)   # keep the other settings in the file
		cfg.set_value(AudioScript.SETTINGS_SECTION, MenuScript.SAVE_MUSIC, MenuScript.music_on)
		cfg.save(AudioScript.SETTINGS_PATH)
	_refresh_buttons()

func _on_volume(v: float) -> void:
	game.audio.set_sfx_volume(v, false)   # saved when the panel closes
	_vol_dirty = true
	_refresh_buttons()

func _on_volume_let_go(_changed: bool) -> void:
	game.audio.play(SAMPLE_SFX)   # hear the new level
	game.stat("pause_volume_set")

func _refresh() -> void:
	for ch in _score_row.get_children():
		ch.queue_free()
	for ch in _grid.get_children():
		ch.queue_free()
	var s0: Dictionary = game.team_stats(0)
	var s1: Dictionary = game.team_stats(1)
	var c0: Color = game.TEAM_COLORS[0]
	var c1: Color = game.TEAM_COLORS[1]
	UI.label(_score_row, str(int(s0.points)), SCORE_FONT, c0)   # the names are over the table's columns
	UI.label(_score_row, "-", SCORE_FONT)
	UI.label(_score_row, str(int(s1.points)), SCORE_FONT, c1)
	_cell("", HEAD_FONT, UI.TEXT_COLOR, false)
	_cell(_wrap(str(game.TEAM_NAMES[0])), HEAD_FONT, c0, true)
	_cell(_wrap(str(game.TEAM_NAMES[1])), HEAD_FONT, c1, true)
	_row("POINTS", str(s0.points), str(s1.points))
	_row("SHOTS", "%d/%d" % [int(s0.makes), int(s0.shots)], "%d/%d" % [int(s1.makes), int(s1.shots)])
	_row("FG %", _pct(s0), _pct(s1))
	_row("DUNKS", str(s0.dunks), str(s1.dunks))
	_row("STEALS", str(s0.steals), str(s1.steals))
	_row("BLOCKS", str(s0.blocks), str(s1.blocks))
	_slider.set_value_no_signal(AudioScript.sfx_volume)
	_refresh_buttons()

func _row(what: String, a: String, b: String) -> void:
	_cell(what, STATS_FONT, UI.OPT_OFF_TEXT, false)
	_cell(a, STATS_FONT, UI.TEXT_COLOR, true)
	_cell(b, STATS_FONT, UI.TEXT_COLOR, true)

func _cell(text: String, size: int, color: Color, stat_col: bool) -> void:
	var l := UI.label(_grid, text, size, color)
	if stat_col:
		l.custom_minimum_size = Vector2(STAT_COL_W, 0)
	else:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _wrap(n: String) -> String:
	return n.replace(" ", "\n") if n.length() > NAME_WRAP else n

func _pct(s: Dictionary) -> String:
	if int(s.shots) <= 0:
		return "-"
	return "%d%%" % int(round(100.0 * float(s.makes) / float(s.shots)))

func _refresh_buttons() -> void:
	_music_btn.text = "MUSIC: ON" if MenuScript.music_on else "MUSIC: OFF"
	UI.set_text_color(_music_btn, UI.OFF_TEXT if MenuScript.music_on else UI.OPT_OFF_TEXT)
	_restart_btn.text = "RESTART?" if _confirm == "restart" else "RESTART"
	_quit_btn.text = "QUIT?" if _confirm == "quit" else "QUIT"
	UI.set_kind(_restart_btn, UI.KIND_LIT if _confirm == "restart" else UI.KIND_MAIN)
	UI.set_kind(_quit_btn, UI.KIND_LIT if _confirm == "quit" else UI.KIND_MAIN)
	var v: float = AudioScript.sfx_volume
	_vol_label.text = "SOUND: %d%%" % int(round(v * 100.0)) if v > 0.0 else "SOUND: OFF"

# ---------------- every frame (also while paused) ----------------

func _process(delta: float) -> void:
	if game == null:
		return
	if _guard_t > 0.0:
		_guard_t -= delta
	if _input_t > 0.0:
		_input_t -= delta
		if _input_t <= 0.0 and not _open and game.controls != null and not game.menu.showing:
			game.controls.set_process_input(true)
	if _confirm != "":
		_confirm_t -= delta
		if _confirm_t <= 0.0:
			_confirm = ""
			_refresh_buttons()
	var show: bool = not _open and can_pause()
	_btn.visible = show
	UI.set_enabled(_btn, _guard_t <= 0.0)
	if _test:
		_humantest_step()

# desktop testing: Escape or P
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		if _open:
			resume()
		else:
			open()
		get_viewport().set_input_as_handled()

# Android back gesture: pause instead of leaving
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		open()

# --humantest: one pause at TEST_AT, a stray tap on A and a joystick touch while paused, then RESUME; the game time,
# the ball and the controls must not have moved
func _humantest_step() -> void:
	if _test_done:
		return
	if not _open:
		if game.rules.play_time >= TEST_AT and can_pause():
			open()
			_test_time = game.rules.play_time
			_test_ball = game.ball.position
			_test_frames = 0
			var c = game.controls
			if not c.a_pressed.is_connected(_test_leak):
				c.a_pressed.connect(_test_leak)
				c.b_pressed.connect(_test_leak)
			_test_touch(true)
		return
	_test_frames += 1
	if _test_frames < TEST_HOLD:
		return
	var c = game.controls
	var still: bool = is_equal_approx(game.rules.play_time, _test_time) and game.ball.position == _test_ball
	var quiet: bool = _test_leaks == 0 and c.a_index < 0 and c.b_index < 0 and c.joy_index < 0
	game.stat("pause_test_ok" if still and quiet else "pause_leaks")
	_test_touch(false)   # lift the stray fingers, still paused
	_test_done = true
	resume()

# stray touches while paused: one on A, one on the joystick half (index 0 also makes the emulated mouse click)
func _test_touch(down: bool) -> void:
	var spots: Array = [game.controls.a_center(), Vector2(200, 500)]
	for i in spots.size():
		var ev := InputEventScreenTouch.new()
		ev.index = i
		ev.position = get_viewport().get_final_transform() * (spots[i] as Vector2)   # window pixels, as a real touch
		ev.pressed = down
		Input.parse_input_event(ev)

func _test_leak() -> void:
	if _open:
		_test_leaks += 1

