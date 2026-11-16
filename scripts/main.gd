extends Node2D
# Road Trip Hoops: 3v3 full court basketball.
# First to 21 (1 inside the arc, 2 beyond), switch sides at 11: the rules are in rules.gd.
# You control the BLUE team (the player with the yellow ring). BLUE shoots at the RIGHT hoop until the side switch
# at 11 (rules.sides_swapped), then at the left one. The arrow next to BLUE in the top bar shows the way.
#
# Touch: drag anywhere on the left half to move.
#   Offense: hold SHOOT, release in the green zone of the meter. PASS throws to the open teammate
#            (or the teammate in the direction you are pushing). Without the ball, CALL asks the teammate who has
#            it for a pass (a lob if you're cutting to the rim).
#   Defense: the orange button is STEAL or BLOCK (picked for you). STEAL pokes at the ball: poke when the dribble is
#            low and the ball is not behind his body. BLOCK (your man shoots, or is near the rim, and you're close)
#            jumps: time it so you're high when the ball leaves his hand. Don't bite on pump fakes. SWITCH changes player.
#   Fouls (rules.gd): a badly timed block jump into the shooter, or poking at a ball he shields with his body.
#   Free throws: hold SHOOT at the line and release in the green zone, as on a jump shot.
# Keyboard (for testing): WASD/arrows move, J = shoot/steal, K = pass/switch.

const PlayerScript = preload("res://scripts/player.gd")
const BallScript = preload("res://scripts/ball.gd")
const CourtScript = preload("res://scripts/court.gd")
const ControlsScript = preload("res://scripts/touch_controls.gd")
const AudioScript = preload("res://scripts/audio.gd")
const FxScript = preload("res://scripts/fx.gd")
const HumanInputScript = preload("res://scripts/human_input.gd")
const DefenseScript = preload("res://scripts/defense.gd")
const RulesScript = preload("res://scripts/rules.gd")
const MenuScript = preload("res://scripts/menu.gd")
const View = preload("res://scripts/view.gd")   # projection sim -> screen (FLAT / ANGLED), stick mapping (Phase 4)
const Looks = preload("res://scripts/court_looks.gd")   # court looks; Looks.music() is the court's music track

const FT := 12.0                     # pixels per foot
const COURT_W := 94.0 * FT
const COURT_H := 50.0 * FT
const SHOT_CLOCK_LENGTH := 24.0      # seconds; the shot clock stays with first to 21 (Q1). Format: rules.gd
const HUMAN_TEAM := 0
const TEAM_NAMES := ["BLUE", "RED"]
const TEAM_COLORS := [Color(0.7, 0.88, 1.0), Color(1.0, 0.42, 0.38)]   # popups and score messages

# game-event feedback (P1-06)
const SCORE_POPUP_SIZE := 64         # font size of the "+1"/"+2" popup at the hoop
const SCORE_POPUP_RISE := 3.0 * FT   # popup starts this far above the rim
const SCORE_MSG_TIME := 0.8          # the center "BLUE SCORES" message is short, the popup carries it
const BLOCK_SHAKE := 6.0             # screen shake on a block: strength in pixels
const BLOCK_SHAKE_TIME := 0.25       # and how long it lasts
const MSG_FONT_SIZE := 56            # center message font size
const MSG_POP_TIME := 0.15           # center message scale-in time in seconds
const MSG_POP_SCALE := 1.35          # center message start scale
const SIDE_ARROW_RIGHT := ">>"       # top bar: next to BLUE, the way BLUE attacks (P3-02)
const SIDE_ARROW_LEFT := "<<"

# camera (P4-01, framing P4-11). FLAT keeps the old top-down camera. ANGLED follows the owner's framing (Q1 a): the
# camera follows the ball left and right, about 2/3 of the court length on screen, both sidelines always visible (it
# doesn't move up and down), and it stays on the same sideline at the side switch (Q2 a, View.SIDE_FLIP false).
# View.TILT_Y 0.48 makes the court 288 px deep; with zoom 1.68 the 1280x720 screen shows 762 px = 63.5 ft (68% of the
# court length) and 429 px of height: HUD bar 32 + far players' heads 84 + court 288 + near margin 24 = 428.
# 1280x800 (stretch expand) shows more height: the framing grows evenly and the court stays centered.
const CAM_ZOOM_FLAT := 1.15          # FLAT: the old zoom
const CAM_ZOOM := 1.68               # ANGLED zoom (at most; a screen too short for both sidelines zooms out to fit)
const CAM_ZOOM_MIN := 1.2            # ANGLED: never zoom out further than this to fit (then it follows up and down)
const CAM_SMOOTHING := 4.0           # Camera2D position smoothing speed (both modes, as today)
const CAM_FOLLOW_X := 1.0            # ANGLED: 1 = the camera follows the ball left/right, 0 = stays at half court
const CAM_FOLLOW_Y := 0.0            # ANGLED: 0 = fixed depth (both sidelines in view), 1 = follows the ball up/down
                                     # (it follows anyway on a screen too short to show both sidelines)
const CAM_MARGIN_FT := 2.0           # ANGLED: room past the baselines and the near sideline (feet, floor)
const CAM_TOP_FT := 7.0              # ANGLED: room above the far sideline for the players standing on it (feet, height)
const CAM_HUD_PX := 54.0             # the HUD top bar (screen px): the far sideline stays below it
const FPS_PRINT_EVERY := 5.0         # -- --fps: seconds between "FPS n" lines

# on fire (P1-07)
const FIRE_STREAK := 3               # makes in a row by one player (dunks and layups count) to catch fire
const FIRE_MISSES := 2               # misses or blocks by the on-fire player that put the fire out (a make resets)
const FIRE_COLOR := Color(1.0, 0.45, 0.1)   # "ON FIRE!" popup and the ball trail
const FIRE_POPUP_SIZE := 52

# skill-based steals (P2-04). Owner (Q6): the poke's timing and the ball's exposure decide a good or a bad attempt,
# and the defender's steal rating scales a good one. Same rule for the human and the CPU.
const STEAL_REACH_FT := 2.5          # the defender must be this close to the BALL (not the handler's body)
const STEAL_BALL_PX := 15.0          # where the dribble is when the ball isn't held by this handler (ball.gd draws it here)
const STEAL_POKE_PX := 40.0          # a poke further than this from the handler is no poke at all (nothing happens)
const STEAL_OPEN_DEG := 60.0         # angle between handler->ball and handler->defender: under this the ball is fully exposed
const STEAL_SHIELD_DEG := 120.0      # over this the handler's body shields the ball (exposure 0); linear between
const STEAL_BASE := 0.7              # success chance of a fully exposed poke by a defender with steal rating 50
const STEAL_RATING_SPAN := 0.2       # steal rating 0 gives STEAL_BASE - this, rating 100 gives STEAL_BASE + this
const STEAL_LUCK := 1.0              # 1: chance grows with exposure; 0: pure skill (good poke always works, bad never)
const STEAL_GOOD_EXPOSURE := 0.5     # exposure x timing at or above this is a good poke (counted; decides alone at STEAL_LUCK 0)
const STEAL_CROSS_MULT := 1.6        # handler in a crossover: the ball crosses in front of the body
const STEAL_SPIN_MULT := 0.3         # handler in a spin move: the ball is protected
const STEAL_TURBO_MULT := 1.3        # handler sprinting
const STEAL_FAKE_MULT := 1.3         # handler in a pump fake
const STEAL_MAX_CHANCE := 0.95
const STEAL_POKE_FREEZE := 0.3      # seconds a defender stands still after every steal attempt, hit or miss (owner)
const STEAL_COOLDOWN := 0.7          # seconds between pokes by one defender
# timing: a poke is well timed within STEAL_GRACE seconds of a floor touch of the dribble (time based, so it doesn't
# depend on the frame rate). The STEAL button lights up while the human's poke would be well timed.
# Set STEAL_TIMING false to judge pokes by exposure only.
const STEAL_TIMING := true
const DRIBBLE_PERIOD := PI / 9.0     # seconds between floor touches; must match ball.gd (z = 4 + |sin(anim_time * 9)| * 16)
const STEAL_GRACE := 0.04            # human: seconds before a floor touch that count as a well-timed poke (P2.5: was 0.05)
const STEAL_HUMAN_LATE := 0.10       # human: seconds after a floor touch that still count (P2.5: was 0.05; a thumb
                                     # reacts to the lit button a little late). Window 0.14 s = 40% of the 0.35 s
                                     # dribble (was 0.10 s, 29%); the STEAL button and the ring under the ball stay lit
                                     # ~8 frames per bounce instead of ~6
const STEAL_CPU_GRACE := 0.05        # CPU pokes: seconds either side of a floor touch (unchanged; defense.gd times them)
const STEAL_HUMAN_BONUS := 0.12      # human (P2.5): a well-timed poke's success chance + this (rating 50: 0.7 -> 0.82)
const STEAL_HUMAN_LUCK := 0.5        # human (P2.5): STEAL_LUCK for the human's pokes; a good poke depends less on how
                                     # exposed the ball is (CPU keeps STEAL_LUCK)
const STEAL_CUE_RING_COLOR := Color(1.0, 0.95, 0.4, 0.9)   # ring on the floor under the ball while STEAL is lit
const STEAL_HELD_TIMING := 0.25      # timing factor when the ball is held up (gathering a shot, pump fake, at the rim)

# fouls and free throws (P3-05; the sequence and the counts are in rules.gd). Owner Q3: fouls come from bad timing only
const REACH_FOULS := true            # a poke that reaches a ball shielded by the handler's body can be a reaching foul
const FT_BASE := 0.72                # free throw made chance at quality 1.0 (normal release); no contest, no blocks
const FT_CAP := 0.95                 # at most this (a perfect release is quality 1.3: 0.94)
const FT_PERFECT_Q := 1.25           # a free throw at or above this quality counts as a perfect release (human_ft_perfect)
const FORCE_FOUL_CHANCE := 0.12      # test only (-- --force-fouls): a released field goal is fouled with this chance
const HT_FT_GOOD_CHARGE := 0.865     # --humantest at the line: release a "good" free throw at this meter charge
                                     # (middle of the 0.78-0.95 green zone) ...
const HT_FT_EARLY_CHARGE := 0.5      # ... and an "early" one here (a bad release, quality 0.6)
const HT_FT_DELAY := 0.5             # seconds the scripted thumb waits at the line before pressing SHOOT
const FT_LABEL_COLOR := Color(1.0, 0.92, 0.45)

# call for the ball (P2-10). human_input.gd has the call rules; main.gd decides who the human controls and draws the cue
const CONTROL_FOLLOWS_CATCH := false # false: a teammate who gets the ball (inbound, rebound, steal, CPU pass) runs it
                                     # and you keep your player and CALL for it; true: you always take over the ball
                                     # (Phase 1 behavior). Your own PASS always hands control to the receiver.
const CALL_CUE_RISE := 4.0 * FT      # the "!" bubble floats this far above the caller's feet
const CALL_CUE_COLOR := Color(1.0, 0.92, 0.3)
const MENUSHOT_FRAMES := 40          # test only (--menushot): frames the panel is up before its screenshot

# --humantest scripted thumb (developer testing only): drives the real touch joystick with synthetic touch events
const HT_FINGER_POS := Vector2(260, 460)   # where the scripted thumb touches down (left half of the screen)
const HT_STEER_RATE := 450.0         # degrees per second the thumb turns while steering (a flick needs 100 in 0.12 s)
const HT_SNAP_EVERY := 3.0           # seconds of ball time between 120-degree snaps (should each be one flick)
const HT_SNAP_DEG := 120.0
const HT_SNAP_FRAMES := 3
const HT_TURN_EVERY := 5.0           # seconds of ball time between a smooth 180-degree turn + a radial pull (no flicks)
const HT_TURN_TIME := 0.4
const HT_PULL_FROM := 0.8            # radial pull: finger distance in ring radii, from ...
const HT_PULL_TO := 1.6              # ... to (past touch_controls.TURBO_PULL, so turbo comes on)
const HT_PULL_TIME := 0.3
const HT_PULL_HOLD := 0.3
const HT_TAP_EVERY := 4.0            # seconds of ball time between short A taps (pump fake input) outside the rim range
const HT_TAP_FRAMES := 5
const HT_SHOOT_MAX_FT := 24.0        # the scripted human only shoots or taps A with the ball inside this distance
const HT_TIMED_POKE_GAP := 20.0      # seconds between the scripted human's well-timed pokes (low dribble, ball exposed)
const HT_CALL_EVERY := 3.0           # on offense without the ball: press CALL every this many seconds
const HT_LOB_GAP := 6.0              # with the ball: pass to a teammate near the rim at most this often (alley-oop try)
const HT_LOB_FT := 12.0              # "near the rim" for that pass
const HT_BLOCK_DELAY := 0.15         # on defense: press BLOCK this long after a CPU shot starts (every 2nd shot; else at once)
const HT_EARLY_DRIVE_SPEED := 0.4    # "early" block turn: a CPU handler driving at his rim at this fraction of top speed
const HT_EARLY_HOLD := 1.0           # ... after that early jump, his take-off within this many seconds isn't a new try
const HT_AWAY_EVERY := 6.0           # on defense: every this many seconds, steer away from the handler ...
const HT_AWAY_TIME := 0.7            # ... for this long (the defensive assist must not hold him)
const HT_GUARD_FT := 8.0             # stay-in-front metric: a CPU handler (frontcourt) this close to the human is "guarded"
const HT_BEAT_MARGIN_FT := 1.0       # ... and he is past the human once he is this much closer to the rim (hysteresis)

var hoops := [Vector2(5.25 * FT, COURT_H / 2), Vector2(COURT_W - 5.25 * FT, COURT_H / 2)]

var rng := RandomNumberGenerator.new()
var players: Array = []
var teams := [[], []]
var ball
var controls
var camera: Camera2D
var audio                           # sound effects: audio.play("swish")
var fx                              # shake, popups, ball trail: fx.shake(6.0, 0.3)
var input                           # human_input.gd: buttons, pass target, switch, flick and tap detection
var rims                            # court instance that draws rims and nets: rims.swish(hoop_index)
var rules                           # rules.gd: format, score changes, side switch, dead balls, inbounds
var score := [0, 0]                 # changed only by rules.add_score()
var shot_clock := SHOT_CLOCK_LENGTH
var shot_clock_running := true
var possession := 0
var human_player = null
var game_over := false
var autoplay := false
var chasers := []
var key_a_down := false
var stats := {}
var _trail_on := false              # fire trail currently shown behind the ball
var humantest := false
# humantest scripted thumb state
var ht_angle := 0.0
var ht_dist := 1.0
var ht_mode := ""                   # "", "snap", "turn", "pull", "tap"
var ht_t := 0.0
var ht_frames := 0
var ht_ok := true                   # the human could flick on every frame of the current snap
var ht_snap_clock := 0.0
var ht_turn_clock := 0.0
var ht_tap_clock := 0.0
var ht_poke_wait := 0.0
var ht_block_wait := -1.0           # seconds until the scripted human presses BLOCK (< 0 = none planned)
var ht_block_n := 0                 # CPU shots seen by the block script (alternates timed / early)
var ht_jump_kind := "random"        # what the last scripted press that jumped was: "random", "timed" or "early"
var ht_threat_shooting := false
var ht_pre_t := 0.0                 # an early jump at a drive was just scripted: don't count his take-off as a new try
var ht_jump_phase := ""             # what the shooter was doing at the scripted block press: "shot", "fake", "rim"
var ht_call_clock := 0.0
var ht_lob_wait := 0.0
var ht_away_clock := 0.0
var ht_away_t := 0.0
var ht_guard_on := false            # stay-in-front metric: guarding a handler this frame
var ht_guard_front := true          # ... and the human is between him and the rim
var ht_guard_holder = null
var _call_node: Node2D               # draws the "!" over the human while his call is live (in overlay)
var _steal_node: Node2D              # draws the lit-STEAL ring on the floor under the ball (decals; FLAT: overlay)
# drawing layers (P4-01, see the Shared contract in docs/BOARD.md). All Node2D children of main.
var floor_layer: Node2D              # z -10: the court floor
var decals: Node2D                   # z -5: things lying on the floor under everyone (shadows, rings, dust, steal cue)
var world: Node2D                    # z 0, y-sorted: upright things, each positioned at its projected floor point
var overlay: Node2D                  # z 30: cues, arrow, stamina bar, shot meter; always on top, never sorted
var fps_print := false               # test only (-- --fps): print "FPS n" every FPS_PRINT_EVERY seconds
var _fps_t := 0.0
var shot_serial := 0                # counts released shots, so each defender gets one block try per shot (defense.gd)
var menu                            # menu.gd: the EASY / NORMAL / HARD panel (launch and game over, P3-08)
var menu_wait := false              # the launch panel is up: the game waits behind it
var menushot := false               # test only (-- --menushot): screenshots of both panels, see _debug_screenshots
var _menu_frames := 0
var force_fouls := false            # test only: -- --force-fouls fouls some field goals (until P3-06 commits fouls)
var ht_ft_t := 0.0                  # humantest: seconds the human has had the ball at the line
var ht_ft_n := 0                    # humantest: free throws the scripted thumb started (every 2nd is "good")
var ht_ft_kind := ""                # humantest: "good" or "early" for the free throw on the meter now

func stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

func stat_add(k: String, n: int) -> void:
	stats[k] = stats.get(k, 0) + n

var score_label: Label
var clock_label: Label
var shot_label: Label
var msg_label: Label
var ft_label: Label
var msg_timer := 0.0
var msg_age := 0.0

# ---------------- setup ----------------

func _ready() -> void:
	rng.randomize()
	_parse_view_args()
	if OS.get_cmdline_user_args().has("--viewtest"):
		_viewtest()
		return
	autoplay = OS.get_cmdline_user_args().has("--autoplay")
	humantest = OS.get_cmdline_user_args().has("--humantest")
	force_fouls = OS.get_cmdline_user_args().has("--force-fouls")
	menushot = OS.get_cmdline_user_args().has("--menushot")
	MenuScript.prepare_level()   # before the players: first launch = Normal, then the saved level, then --difficulty
	MenuScript.prepare_settings()   # before the court: the saved court look (-- --court wins) and music on/off

	rules = RulesScript.new()
	rules.game = self
	add_child(rules)

	audio = AudioScript.new()
	audio.game = self
	add_child(audio)
	audio.set_music_on(MenuScript.music_on)

	floor_layer = _make_layer("FloorLayer", -10)
	decals = _make_layer("Decals", -5)
	world = _make_layer("World", 0)
	world.y_sort_enabled = true        # children sit at their projected floor point: y-sort = depth sort
	overlay = _make_layer("Overlay", 30)

	var floor_node = CourtScript.new()
	floor_node.game = self
	floor_layer.add_child(floor_node)
	rims = CourtScript.new()
	rims.game = self
	rims.draw_rims = true
	rims.z_index = 15
	add_child(rims)

	var looks := [[1, 3, 5], [2, 4, 1]]
	for t in 2:
		for i in 3:
			var p = PlayerScript.new()
			var color := "blue" if t == 0 else "red"
			p.setup(self, t, i, load("res://assets/%s_%d.png" % [color, looks[t][i]]))
			add_child(p)
			players.append(p)
			teams[t].append(p)

	ball = BallScript.new()
	ball.setup(self)
	add_child(ball)

	camera = Camera2D.new()
	var zm: float = CAM_ZOOM if View.angled() else CAM_ZOOM_FLAT
	camera.zoom = Vector2(zm, zm)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAM_SMOOTHING
	camera.limit_left = int(-6 * FT)
	camera.limit_top = int(-10 * FT)
	camera.limit_right = int(COURT_W + 6 * FT)
	camera.limit_bottom = int(COURT_H + 10 * FT)
	add_child(camera)
	camera.make_current()

	fx = FxScript.new()
	fx.game = self
	add_child(fx)

	input = HumanInputScript.new()
	input.game = self
	add_child(input)

	_call_node = Node2D.new()          # in overlay (z 30): over the players and the ball, under the fx popups
	_call_node.draw.connect(_draw_call_cue)
	overlay.add_child(_call_node)
	_steal_node = Node2D.new()         # ANGLED: in decals (a ring on the floor, under the upright players);
	_steal_node.draw.connect(_draw_steal_cue)   # FLAT: in overlay as before, where top-down sprites would hide it
	(decals if View.angled() else overlay).add_child(_steal_node)

	_build_hud()
	menu = MenuScript.new()
	menu.game = self
	add_child(menu)
	start_game()
	if View.angled():
		_update_camera()               # set the ANGLED zoom and limits and start on the ball
		camera.reset_smoothing()
	# the launch panel: once per run, never in the headless tests (or --shots, unless -- --menushot)
	var shots_run: bool = OS.get_cmdline_user_args().has("--shots") or OS.get_cmdline_user_args().has("--ballshots")
	var tests: bool = autoplay or humantest or (shots_run and not menushot)
	if not tests and not MenuScript.start_done:
		menu_wait = true
		msg_label.visible = false   # no "FIRST TO 21" under the panel; the reloaded game shows it
		_menu_input(true)
		menu.show_start()
	elif not tests:
		MenuScript.start_done = true
	if not menu_wait:
		_play_court_music()

# in play: the court's track, softly (owner Q5 a). The panels play the menu music (menu.gd)
func _play_court_music() -> void:
	audio.play_music(Looks.music())
	audio.set_music_ducked(true)

func _make_layer(n: String, z: int) -> Node2D:
	var l := Node2D.new()
	l.name = n
	l.z_index = z
	add_child(l)
	return l

# test flags: -- --view flat|angled (or --view=angled) sets View.mode (default ANGLED); -- --perspective k tries
# View.perspective k (e.g. 0.15); -- --fps prints the frame rate
func _parse_view_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	fps_print = args.has("--fps")
	for i in args.size():
		if args[i] == "--perspective" and i + 1 < args.size():
			View.perspective = clampf(args[i + 1].to_float(), 0.0, 0.5)
		var v := ""
		if args[i].begins_with("--view="):
			v = args[i].substr("--view=".length())
		elif args[i] == "--view" and i + 1 < args.size():
			v = args[i + 1]
		if v == "angled":
			View.mode = View.ANGLED
		elif v == "flat":
			View.mode = View.FLAT
		elif v != "":
			print("--view: unknown mode '%s' (flat or angled)" % v)

# test only (-- --viewtest): check the projection round trip and the stick mapping, print the result and quit
func _viewtest() -> void:
	set_physics_process(false)
	set_process(false)
	var errs: PackedStringArray = View.self_test()
	if errs.is_empty():
		print("VIEWTEST OK")
	else:
		for e in errs.slice(0, 20):
			print(e)
		print("VIEWTEST FAILED (%d)" % errs.size())
	get_tree().quit(0 if errs.is_empty() else 1)

# the panel is up: the joystick and A/B take no touches (touch_controls reads _input, before the GUI) and are hidden,
# so the tap on a level can't also move or shoot
func _menu_input(on: bool) -> void:
	controls.set_process_input(not on)
	controls.visible = not on and not autoplay
	if on:
		controls.joy_index = -1
		controls.a_index = -1
		controls.b_index = -1

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)

	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.55)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 54
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)

	score_label = _make_label(root, 30, Control.PRESET_TOP_WIDE, 8)
	clock_label = _make_label(root, 20, Control.PRESET_TOP_LEFT, 14)
	clock_label.offset_left = 20
	clock_label.offset_right = 260
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	shot_label = _make_label(root, 20, Control.PRESET_TOP_RIGHT, 14)
	shot_label.offset_left = -260
	shot_label.offset_right = -20
	shot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	msg_label = _make_label(root, MSG_FONT_SIZE, Control.PRESET_CENTER, 0)
	msg_label.offset_left = -500
	msg_label.offset_right = 500
	msg_label.offset_top = -160
	msg_label.offset_bottom = -60
	ft_label = _make_label(root, 26, Control.PRESET_TOP_WIDE, 62)   # "FREE THROW 1 OF 2" under the top bar
	ft_label.modulate = FT_LABEL_COLOR

	controls = ControlsScript.new()
	root.add_child(controls)
	controls.a_pressed.connect(_on_a_pressed)
	controls.a_released.connect(_on_a_released)
	controls.b_pressed.connect(_on_b_pressed)
	if autoplay:
		controls.visible = false

func _make_label(parent: Control, size: int, preset: int, top: float) -> Label:
	var l := Label.new()
	l.set_anchors_preset(preset)
	l.offset_top = top
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.outline_size = 6
	ls.outline_color = Color(0, 0, 0, 0.8)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func start_game() -> void:
	rules.start_game()

# line both teams up: `team` (which gets the ball) on its own half, the other just past half court. The rows are
# mirrored by the attack direction (y times dir) so both halves of the court play the same (B1)
func reset_positions(team: int) -> void:
	var own: Vector2 = attack_hoop(1 - team)   # the hoop this team defends
	var dir := inward(own)
	for i in 3:
		var row: float = [0.0, -12.0, 12.0][i] * dir * FT
		var o = teams[team][i]
		o.position = own + Vector2(dir * (5 + i * 12) * FT, row)
		var d = teams[1 - team][i]
		d.position = Vector2(COURT_W / 2 + dir * 10 * FT, COURT_H / 2 + row)
		for p in [o, d]:
			p.velocity = Vector2.ZERO
			p.shooting = false
			p.facing = 0.0 if attack_hoop(p.team).x > COURT_W / 2 else PI   # face the hoop it attacks

# ---------------- court helpers ----------------

# the only place that knows which hoop a team attacks: team 0 attacks the right hoop until the side switch (P3-02)
func attack_hoop(team: int) -> Vector2:
	var right: bool = (team == 0) != rules.sides_swapped
	return hoops[1] if right else hoops[0]

func inward(hoop: Vector2) -> float:
	return 1.0 if hoop.x < COURT_W / 2 else -1.0

func in_frontcourt(pos: Vector2, team: int) -> bool:
	return (pos.x > COURT_W / 2) == (attack_hoop(team).x > COURT_W / 2)

func clamp_to_court(pos: Vector2) -> Vector2:
	return Vector2(clamp(pos.x, 10.0, COURT_W - 10.0), clamp(pos.y, 10.0, COURT_H - 10.0))

func is_human(p) -> bool:
	return not autoplay and p == human_player

func nearest_opponent(p):
	var best = null
	var best_d := INF
	for o in teams[1 - p.team]:
		var d: float = o.position.distance_to(p.position)
		if d < best_d:
			best_d = d
			best = o
	return best

func openness(p) -> float:
	var o = nearest_opponent(p)
	return 99.0 if o == null else o.position.distance_to(p.position) / FT

func is_chaser(p) -> bool:
	return chasers.has(p)

func is_three(pos: Vector2, hoop: Vector2) -> bool:
	var from_baseline: float = abs(pos.x - (0.0 if inward(hoop) > 0 else COURT_W)) / FT
	if from_baseline < 14.0:
		return abs(pos.y - hoop.y) / FT >= 22.0
	return pos.distance_to(hoop) / FT > 23.75

func shot_probability(p, quality: float) -> float:
	var hoop := attack_hoop(p.team)
	var d: float = p.position.distance_to(hoop) / FT
	var base: float
	if d < 5.0:
		base = 0.66
	elif not is_three(p.position, hoop):
		base = 0.52 - (d - 5.0) * 0.0075
	else:
		base = 0.38 - max(0.0, d - 23.75) * 0.025
	base = max(base, 0.02)
	var cont := openness(p)
	if cont < 3.0:
		base *= 0.55
	elif cont < 6.0:
		base *= 0.8
	return clamp(base * quality, 0.02, 0.92)

# ---------------- ball events ----------------

func give_ball(p) -> void:
	ball.position = p.position
	ball.hold(p)

func on_ball_held(p) -> void:
	if p.team != possession or not shot_clock_running:
		shot_clock = SHOT_CLOCK_LENGTH
	shot_clock_running = true
	possession = p.team
	rules.on_possession(p.team)
	if p.team == HUMAN_TEAM:
		if CONTROL_FOLLOWS_CATCH or human_player == null or human_player.team != HUMAN_TEAM:
			human_player = p
	elif human_player == null or human_player.team != HUMAN_TEAM:
		human_player = teams[HUMAN_TEAM][0]

func release_shot(p, quality: float) -> void:
	if not p.has_ball():
		return
	if rules.ft_active and p == rules.ft_shooter:
		_release_free_throw(p, quality)
		return
	var hoop := attack_hoop(p.team)
	var prob := shot_probability(p, quality)
	var made := rng.randf() < prob
	var pts: int = rules.points_for(p, hoop)
	shot_clock_running = false
	shot_serial += 1
	stat("shots")
	stat("shots_half%d_t%d" % [2 if rules.sides_swapped else 1, p.team])
	stat("shot_d%d" % int(p.position.distance_to(hoop) / FT / 5) )
	if made: stat("makes")
	if p.on_fire:
		stat("fire_shots")
		if made: stat("fire_makes")
	ball.shoot(p, hoop, made, pts)
	if force_fouls and rng.randf() < FORCE_FOUL_CHANCE:
		var d = nearest_opponent(p)   # test only: as if he had jumped badly into the shooter
		stat("forced_fouls")
		rules.call_foul(d, p, "shooting")

# a free throw (rules.ft_active): FT_BASE x the release quality, 1 point, no contest, no blocks, no interceptions
func _release_free_throw(p, quality: float) -> void:
	var prob: float = clampf(FT_BASE * quality, 0.0, FT_CAP)
	var made: bool = rng.randf() < prob
	shot_clock_running = false
	stat("free_throws")
	stat("ft_attempts_t%d" % p.team)
	if is_human(p):
		stat("human_ft_attempts")
		if quality >= FT_PERFECT_Q:
			stat("human_ft_perfect")
	ball.next_shot_kind = ""
	ball.next_alley = false
	rules.ft_released()
	ball.shoot(p, attack_hoop(p.team), made, rules.ft_value)

# a dunk or layup blocked at take-off: counts as a missed shot, the ball is swatted out of the shooter's hands
func rim_shot_blocked(p, defender) -> void:
	shot_clock_running = false
	shot_serial += 1   # it counts as a shot: lets the blocker (defense.gd rolled_shot) try again on the next one
	stat("shots")
	if p.on_fire:
		stat("fire_shots")
	block_shot(defender)
	on_shot_missed(p)

func block_shot(defender) -> void:
	var missed_shooter = null
	if ball.state == ball.SHOT:
		# a jump shot swatted in the air: it was rolled at release, so take a rolled make back off the books
		if ball.shot_made:
			stats["makes"] = stats.get("makes", 1) - 1
			if ball.shooter != null and ball.shooter.on_fire:
				stats["fire_makes"] = stats.get("fire_makes", 1) - 1
		missed_shooter = ball.shooter
	var away: Vector2 = (ball.position - defender.position).normalized()
	ball.make_loose(ball.position, away * rng.randf_range(200.0, 300.0), ball.z, 80.0)
	show_message("BLOCKED!")
	stat("blocks")
	stat("blocks_t%d" % defender.team)
	if is_human(defender):
		stat("human_blocks")
		if humantest:
			stat("humantest_%s_blocks" % ht_jump_kind)
			if ht_jump_kind != "random":
				stat("humantest_%s_blocks_%s" % [ht_jump_kind, ht_jump_phase])
	fx.shake(BLOCK_SHAKE, BLOCK_SHAKE_TIME)
	audio.play("block")
	if missed_shooter != null:
		on_shot_missed(missed_shooter)   # after "BLOCKED!" so a "cooling down" message wins

func on_shot_made(shooter, pts: int) -> void:
	var hoop := attack_hoop(shooter.team)   # before add_score: the side switch may flip it
	if rules.ft_shot_live:
		# a free throw: no "SCORES" banner and no on-fire streak, just the +1 at the hoop
		fx.popup("+%d" % pts, hoop + Vector2(0, -SCORE_POPUP_RISE), TEAM_COLORS[shooter.team], SCORE_POPUP_SIZE)
		rules.ft_result(true)
		return
	show_message("%s %s" % [TEAM_NAMES[shooter.team], "FOR TWO!" if pts >= 2 else "SCORES"], SCORE_MSG_TIME,
			TEAM_COLORS[shooter.team])
	if ball.shot_kind != "dunk":   # a dunk already shows "SLAM!"
		fx.popup("+%d" % pts, hoop + Vector2(0, -SCORE_POPUP_RISE), TEAM_COLORS[shooter.team], SCORE_POPUP_SIZE)
	audio.play("crowd")
	_update_fire_on_make(shooter)
	rules.add_score(shooter.team, pts, ball.shot_kind if ball.shot_kind != "" else "shot")
	if game_over:
		return
	if rules.resolve_pending_foul(shooter, true):
		return   # fouled on the make: and-one free throw
	possession = 1 - shooter.team
	rules.dead_ball(1 - shooter.team, rules.MADE_WAIT)

func on_shot_missed(shooter) -> void:
	if rules.ft_shot_live:
		rules.ft_result(false)   # a missed free throw doesn't touch the on-fire streak
		return
	if shooter == null:
		return
	if rules.resolve_pending_foul(shooter, false):
		return   # fouled on the miss: free throws (the fire streak isn't charged with this miss)
	shooter.make_streak = 0
	if shooter.on_fire:
		shooter.fire_misses += 1
		if shooter.fire_misses >= FIRE_MISSES:
			_end_fire(shooter)
		else:
			show_message("He's cooling down.")
			stat("fire_cooldowns")

# ---------------- on fire ----------------

func _update_fire_on_make(shooter) -> void:
	shooter.make_streak += 1
	shooter.fire_misses = 0   # a make while cooling down makes him fully hot again
	if shooter.make_streak >= FIRE_STREAK and not shooter.on_fire:
		shooter.on_fire = true
		stat("fire_starts_t%d" % shooter.team)
		fx.popup("ON FIRE!", shooter.position + Vector2(0, -5.0 * FT), FIRE_COLOR, FIRE_POPUP_SIZE)
		audio.play("fire")

func _end_fire(p) -> void:
	p.on_fire = false
	p.make_streak = 0
	p.fire_misses = 0
	stat("fire_ends")
	p.queue_redraw()   # drop the flame ring even when the player stops updating (game over)

# flaming trail while an on-fire player holds or shoots the ball
func _update_fire_trail() -> void:
	var p = null
	if ball.state == ball.HELD:
		p = ball.holder
	elif ball.state == ball.SHOT:
		p = ball.shooter
	var want: bool = p != null and p.on_fire
	if want != _trail_on:
		_trail_on = want
		fx.set_trail(want, FIRE_COLOR)

func do_pass(from_p, to_p) -> void:
	if not from_p.has_ball() or to_p == from_p:
		return
	ball.pass_to(from_p, to_p)
	stat("passes")
	if from_p.team == HUMAN_TEAM and (CONTROL_FOLLOWS_CATCH or from_p == human_player):
		human_player = to_p

# 0..1: how open the ball is to this defender's poke. 0 when the ball is out of reach or behind the handler's body.
func steal_exposure(defender, handler) -> float:
	if defender == null or handler == null:
		return 0.0
	var ball_pos: Vector2 = handler.position + Vector2.from_angle(handler.facing) * STEAL_BALL_PX
	if ball.state == ball.HELD and ball.holder == handler:
		ball_pos = ball.position   # where ball.gd really draws the dribble (includes the hand once P2-05 lands)
	if defender.position.distance_to(ball_pos) > STEAL_REACH_FT * FT:
		return 0.0
	var to_ball: Vector2 = ball_pos - handler.position
	var to_def: Vector2 = defender.position - handler.position
	if to_ball.length() < 0.01 or to_def.length() < 0.01:
		return 1.0
	var ang: float = rad_to_deg(absf(to_ball.angle_to(to_def)))
	return clampf((STEAL_SHIELD_DEG - ang) / (STEAL_SHIELD_DEG - STEAL_OPEN_DEG), 0.0, 1.0)

# the handler's body is between this defender and the ball (angle at least STEAL_SHIELD_DEG): a poke from here goes
# through the body. (Distance is checked by the caller: the poke reached the handler, STEAL_POKE_PX.)
func _ball_behind_body(defender, handler) -> bool:
	var ball_pos: Vector2 = handler.position + Vector2.from_angle(handler.facing) * STEAL_BALL_PX
	if ball.state == ball.HELD and ball.holder == handler:
		ball_pos = ball.position
	var to_ball: Vector2 = ball_pos - handler.position
	var to_def: Vector2 = defender.position - handler.position
	if to_ball.length() < 0.01 or to_def.length() < 0.01:
		return false
	return rad_to_deg(absf(to_ball.angle_to(to_def))) >= STEAL_SHIELD_DEG

# how well a poke at this handler's ball is timed right now: 1 within `grace` s of a dribble floor touch, else 0
# (STEAL_HELD_TIMING while the ball is held up). grace < 0 means STEAL_GRACE. late >= 0: the window after the floor
# touch is `late` s instead of `grace` (the human's reaction allowance).
func steal_timing(handler, grace := -1.0, late := -1.0) -> float:
	if not STEAL_TIMING:
		return 1.0
	if handler == null or not (ball.state == ball.HELD and ball.holder == handler):
		return 0.0
	if handler.shooting or handler.rim_kind != "" or ("fake_t" in handler and handler.fake_t > 0.0):
		return STEAL_HELD_TIMING
	var g: float = STEAL_GRACE if grace < 0.0 else grace
	var after: float = g if late < 0.0 else late
	var ph: float = fposmod(ball.anim_time, DRIBBLE_PERIOD)   # seconds since the last floor touch
	return 1.0 if ph <= after or DRIBBLE_PERIOD - ph <= g else 0.0

# 0..1: exposure x timing. At or over STEAL_GOOD_EXPOSURE it's a good poke.
func steal_quality(defender, handler) -> float:
	if is_human(defender):
		return steal_exposure(defender, handler) * steal_timing(handler, STEAL_GRACE, STEAL_HUMAN_LATE)
	return steal_exposure(defender, handler) * steal_timing(handler, STEAL_CPU_GRACE)

# true while a poke by the human would be a good one: drives the lit STEAL button
func human_steal_cue() -> bool:
	var d = human_player
	var h = ball.holder
	if d == null or ball.state != ball.HELD or h == null or h.team == d.team:
		return false
	if d.steal_cooldown > 0.0 or ("stumble_t" in d and d.stumble_t > 0.0) or d.position.distance_to(h.position) > STEAL_POKE_PX:
		return false
	return steal_quality(d, h) >= STEAL_GOOD_EXPOSURE

# chance that a poke by defender at handler works now: exposure, timing, the defender's steal rating and the move
func steal_chance(defender, handler) -> float:
	var q: float = steal_quality(defender, handler)
	var good: float = 1.0 if q >= STEAL_GOOD_EXPOSURE else 0.0
	var human: bool = is_human(defender)
	var k: float = lerpf(good, q, STEAL_HUMAN_LUCK if human else STEAL_LUCK)
	if k <= 0.0:
		return 0.0
	var r: float = 50.0
	if defender.has_method("rating"):
		r = float(defender.rating("steal"))
	var base: float = STEAL_BASE + (STEAL_HUMAN_BONUS * good if human else 0.0)
	var c: float = (base + (clampf(r, 0.0, 100.0) / 50.0 - 1.0) * STEAL_RATING_SPAN) * k
	if "cross_t" in handler and handler.cross_t > 0.0:
		c *= STEAL_SPIN_MULT if handler.move_kind == "spin" else STEAL_CROSS_MULT
	if handler.turbo:
		c *= STEAL_TURBO_MULT
	if "fake_t" in handler and handler.fake_t > 0.0:
		c *= STEAL_FAKE_MULT
	return clampf(c, 0.0, STEAL_MAX_CHANCE)

# a poke at the ball (A on defense, or the CPU). The second argument is ignored (old callers passed a flat chance).
func attempt_steal(defender, _legacy := -1.0) -> void:
	if "stumble_t" in defender and defender.stumble_t > 0.0:
		return   # off balance: can't poke
	if defender.steal_cooldown > 0.0 or rules.ft_active:
		return
	defender.steal_cooldown = STEAL_COOLDOWN
	var h = ball.holder
	if ball.state != ball.HELD or h == null or h.team == defender.team:
		return
	if "poke_t" in defender:
		defender.poke_t = STEAL_POKE_FREEZE   # stands still while reaching, hit or miss
	if defender.position.distance_to(h.position) > STEAL_POKE_PX:
		return
	stat("steal_pokes_t%d" % defender.team)
	var good: bool = steal_quality(defender, h) >= STEAL_GOOD_EXPOSURE
	if is_human(defender):
		stat("human_steal_pokes")
		if good:
			stat("human_pokes_on_cue")   # the STEAL button was lit (well-timed, exposed ball)
	if steal_exposure(defender, h) <= 0.0:
		stat("steal_shielded")
		# reaching foul (P3-05, Q3 a): the poke reached the handler, but the ball was behind his body
		if REACH_FOULS and _ball_behind_body(defender, h):
			stat("steal_shielded_body")   # the reach-foul roll itself is defense.try_reach_foul (P3-09)
	if good:
		stat("steal_good_pokes_t%d" % defender.team)
	if rng.randf() < steal_chance(defender, h):
		stat("steals_good" if good else "steals_bad")
		var v: Vector2 = (defender.position - h.position).normalized().rotated(rng.randf_range(-0.8, 0.8)) * 160.0
		h.shooting = false
		ball.make_loose(ball.position, v, 8.0, 60.0)
		show_message("STEAL!")
		stat("steals")
		stat("steals_t%d" % defender.team)
		if is_human(defender):
			stat("human_steals")

# ---------------- input ----------------

# during free throws A only shoots (the human at the line) and B does nothing (human_input.gd gets the same rule in P3-06)
func _ft_blocks_buttons() -> bool:
	return rules.ft_active and not game_over and not (human_player == rules.ft_shooter and human_player.has_ball())

func _on_a_pressed() -> void:
	if menu.showing:
		return
	if _ft_blocks_buttons():
		return
	input.a_pressed()

func _on_a_released() -> void:
	if menu.showing:
		return
	input.a_released()

func _on_b_pressed() -> void:
	if menu.showing:
		return
	if rules.ft_active and not game_over:
		return
	input.b_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and menu.showing:
		menu.key(event)   # desktop: A/D or arrows (or K) move the light, J / Space / Enter plays it
		return
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_J or event.keycode == KEY_SPACE:
			if event.pressed:
				key_a_down = true
				_on_a_pressed()
			elif key_a_down:
				key_a_down = false
				_on_a_released()
		elif event.keycode == KEY_K and event.pressed:
			_on_b_pressed()

# the stick in sim (world) terms: what the human player, human_input (flicks, pass direction) and the assist get
func _input_vector() -> Vector2:
	return View.stick_to_world(_stick_screen())

# the stick (or the keys) in screen terms: up = up on screen. View.stick_to_world turns it into a sim direction of the
# same length (FLAT: the same vector)
func _stick_screen() -> Vector2:
	var v: Vector2 = controls.joystick()   # in --humantest the scripted thumb drives this too
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	return v.limit_length(1.0)

# ---------------- main loop ----------------

var _frame := 0
var _cue_shot := false
var _block_shot := false
var _switch_shot := false

func _debug_screenshots() -> void:
	# developer testing only: run with -- --shots to save a few screenshots to /tmp
	_frame += 1
	_menushots()
	if OS.get_cmdline_user_args().has("--shots") and controls.a_glow and not _cue_shot:
		_cue_shot = true   # first frame with the STEAL button lit (try -- --shots --humantest)
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_steal_cue.png")
	if OS.get_cmdline_user_args().has("--shots") and controls.a_block and not _block_shot:
		_block_shot = true   # first frame the orange button says BLOCK (try -- --shots --humantest)
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_block_label.png")
	# the side switch, 1 s into its pause (try -- --shots --target 3 so it comes early; then it quits after this shot)
	if OS.get_cmdline_user_args().has("--shots") and rules.sides_swapped and not _switch_shot \
			and rules.dead_timer > 0.0 and rules.dead_timer < rules.SWITCH_PAUSE - 1.0:
		_switch_shot = true
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_switch.png")
		if OS.get_cmdline_user_args().has("--target"):
			get_tree().quit()
	if OS.get_cmdline_user_args().has("--shots") and _frame in [240, 900, 1800]:
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_%d.png" % _frame)
		if _frame == 1800 and not OS.get_cmdline_user_args().has("--target"):
			get_tree().quit()

# test only: -- --menushot (with xvfb, see _debug_screenshots; add --target 3 for a short game): saves the launch
# panel to /tmp/hoops_menu_start.png, picks the lit level as a tap would, then the game-over panel to
# /tmp/hoops_menu_over.png once it takes taps, and quits. The human stands still, so RED wins.
func _menushots() -> void:
	if not menushot or not menu.showing:
		_menu_frames = 0
		return
	_menu_frames += 1
	if menu_wait and _menu_frames == MENUSHOT_FRAMES:
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_menu_start.png")
		menu._pick(MenuScript.Difficulty.level)
	elif game_over and _menu_frames == MENUSHOT_FRAMES + int(MenuScript.ARM_TIME_OVER * 60.0):
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_menu_over.png")
		get_tree().quit()

func _physics_process(delta: float) -> void:
	_debug_screenshots()
	_update_message(delta)
	if game_over or menu_wait:
		return

	if not rules.update(delta):
		if shot_clock_running and ball.state != ball.DEAD:
			shot_clock -= delta
			if shot_clock <= 0.0:
				show_message("SHOT CLOCK!")
				stat("shotclock")
				audio.play("whistle")
				var p = ball.holder if ball.holder != null else ball.passer
				var next_team: int = 1 - (p.team if p != null else possession)
				rules.dead_ball(next_team, 1.0)
	if game_over:
		return

	# who chases loose balls and rebounds: the closest player on each team
	chasers = []
	if ball.state == ball.LOOSE or ball.state == ball.SHOT:
		var spot: Vector2 = ball.position if ball.state == ball.LOOSE else ball.shot_hoop
		for t in 2:
			var best = null
			var best_d := INF
			for p in teams[t]:
				if ball.state == ball.SHOT and p == ball.shooter:
					continue
				var d: float = p.position.distance_to(spot)
				if d < best_d:
					best_d = d
					best = p
			chasers.append(best)
		# your player hunts the loose ball for you if you are not steering
		if ball.state == ball.LOOSE and not autoplay:
			var mine = chasers[HUMAN_TEAM]
			if human_player != mine and human_player.position.distance_to(ball.position) > mine.position.distance_to(ball.position) + 60.0:
				human_player = mine

	if humantest and human_player != null:
		if rules.ft_active:
			_humantest_free_throw(delta)   # at the line: the scripted thumb shoots with the meter
		else:
			if _frame % 97 == 0 and not (human_player.has_ball() and _ht_hoop_ft() > HT_SHOOT_MAX_FT):
				ht_jump_kind = "random"
				_ht_poke("random")   # on offense: a shot (meter held 50 frames); on defense: a randomly timed poke
			if _frame % 97 == 50: _on_a_released()
			if _frame % 211 == 0: _on_b_pressed()
		_humantest_thumb(delta)
		if not rules.ft_active:
			_humantest_timed_poke(delta)
			_humantest_block(delta)
			_humantest_call(delta)
			_humantest_guard_metric()
	# free throws: nobody moves with the stick (no walking off the line, no crossovers)
	var stick := Vector2.ZERO if rules.ft_active else _input_vector()
	input.update(delta, stick)
	for p in players:
		p.update(delta, is_human(p), stick)   # during free throws player.at_free_throw() handles positions
	input.face_caller(delta)
	_call_node.queue_redraw()
	_steal_node.queue_redraw()
	if not rules.ft_active:
		_separate_players()
	ball.update(delta)
	if not rules.ft_shot_live:
		DefenseScript.check_jump_shot_block(self)   # free throws can't be blocked
	_update_fire_trail()

	_update_camera()
	_update_hud()

# FLAT: the camera sits on the ball (as before). ANGLED: it follows the ball's projected floor point left and right
# (CAM_FOLLOW_X) at a fixed depth (CAM_FOLLOW_Y), inside limits from the projected court corners plus margins. The
# zoom is CAM_ZOOM, or less if the screen is too short to show the HUD bar, the far heads and the whole court depth.
func _update_camera() -> void:
	View.flipped = View.SIDE_FLIP and rules.sides_swapped
	var target: Vector2 = View.to_screen(ball.position, 0.0)
	if not View.angled():
		camera.position = target
		return
	var corners := [View.to_screen(Vector2(0, 0)), View.to_screen(Vector2(COURT_W, 0)),
			View.to_screen(Vector2(0, COURT_H)), View.to_screen(Vector2(COURT_W, COURT_H))]
	var lo: Vector2 = corners[0]
	var hi: Vector2 = corners[0]
	for c in corners:
		lo = Vector2(minf(lo.x, c.x), minf(lo.y, c.y))
		hi = Vector2(maxf(hi.x, c.x), maxf(hi.y, c.y))
	var screen: Vector2 = get_viewport_rect().size
	var need_y: float = hi.y - lo.y + CAM_TOP_FT * FT * View.HEIGHT_SCALE + CAM_MARGIN_FT * FT
	var zm: float = clampf((screen.y - CAM_HUD_PX) / need_y, CAM_ZOOM_MIN, CAM_ZOOM)
	camera.zoom = Vector2(zm, zm)
	var vis: Vector2 = screen / camera.zoom
	var left: float = lo.x - CAM_MARGIN_FT * FT
	var right: float = hi.x + CAM_MARGIN_FT * FT
	var top: float = lo.y - CAM_TOP_FT * FT * View.HEIGHT_SCALE - CAM_HUD_PX / camera.zoom.y
	var bottom: float = hi.y + CAM_MARGIN_FT * FT
	var mid := Vector2((left + right) / 2.0, (top + bottom) / 2.0)
	var follow_y: float = CAM_FOLLOW_Y
	if bottom - top > vis.y:
		follow_y = 1.0   # the screen can't show both sidelines: follow the ball up and down instead
	# a screen bigger than the framed area: grow the limits evenly, so the court stays centered
	if right - left < vis.x:
		left = mid.x - vis.x / 2.0
		right = mid.x + vis.x / 2.0
	if bottom - top < vis.y:
		top = mid.y - vis.y / 2.0
		bottom = mid.y + vis.y / 2.0
	camera.limit_left = int(floorf(left))
	camera.limit_right = int(ceilf(right))
	camera.limit_top = int(floorf(top))
	camera.limit_bottom = int(ceilf(bottom))
	camera.position = Vector2(lerpf(mid.x, target.x, CAM_FOLLOW_X), lerpf(mid.y, target.y, follow_y))

func _process(delta: float) -> void:
	if not fps_print:
		return
	_fps_t += delta
	if _fps_t >= FPS_PRINT_EVERY:
		_fps_t = 0.0
		print("FPS %d" % Engine.get_frames_per_second())

# ---------------- humantest scripted thumb ----------------

# developer testing only: a scripted thumb on the real touch joystick. It steers toward the hoop (or the ball on
# defense) turning at most HT_STEER_RATE, and while the human holds the ball it injects gestures: 120-degree snaps
# (flicks), smooth 180-degree turns and radial turbo pulls (not flicks), and short A taps.
func _humantest_thumb(delta: float) -> void:
	if controls.joy_index < 0:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = HT_FINGER_POS
		controls._input(down)
	var goal: Vector2 = attack_hoop(HUMAN_TEAM) if possession == HUMAN_TEAM else ball.position
	var goal_angle: float = (goal - human_player.position).angle()
	# on defense, now and then pull the stick away from the handler: the defensive assist must let go
	if possession != HUMAN_TEAM and ball.state == ball.HELD:
		ht_away_clock += delta
		if ht_away_clock >= HT_AWAY_EVERY:
			ht_away_clock = 0.0
			ht_away_t = HT_AWAY_TIME
			stat("humantest_pull_aways")
	if ht_away_t > 0.0:
		ht_away_t -= delta
		goal_angle += PI
		# last frame's stick (assist_on is from last frame's update): aimed away from the handler and his spot?
		if ball.holder != null and not human_player.assist_aim_ok(View.stick_to_world(controls.joystick()), ball.holder, false):
			stat("humantest_away_frames")
			if human_player.assist_on:
				stat("humantest_away_assist_frames")   # should stay 0: pulling away turns the assist off
	var can_flick: bool = input.flick_ready() and not rules.ft_active   # no gestures at the line
	if can_flick:
		ht_snap_clock += delta
		ht_turn_clock += delta
		ht_tap_clock += delta
	ht_t += delta
	ht_frames += 1
	match ht_mode:
		"snap":
			ht_ok = ht_ok and can_flick
			ht_angle += deg_to_rad(HT_SNAP_DEG / HT_SNAP_FRAMES)
			if ht_frames >= HT_SNAP_FRAMES:
				ht_mode = ""
				if ht_ok:
					stat("humantest_snaps")   # the detector sees this frame after this function: same state
				else:
					stat("humantest_snaps_interrupted")
		"turn":
			ht_angle += deg_to_rad(180.0) * delta / HT_TURN_TIME
			if ht_t >= HT_TURN_TIME:
				stat("humantest_smooth_turns")
				_ht_start("pull")
				stat("humantest_pulls")
		"pull":
			ht_dist = lerpf(HT_PULL_FROM, HT_PULL_TO, minf(ht_t / HT_PULL_TIME, 1.0))
			if controls.turbo_pull():
				stat("humantest_pull_turbo_frames")
			if ht_t >= HT_PULL_TIME + HT_PULL_HOLD:
				ht_dist = 1.0
				ht_mode = ""
		"tap":
			if ht_frames >= HT_TAP_FRAMES:
				_on_a_released()
				ht_mode = ""
		_:
			var diff: float = wrapf(goal_angle - ht_angle, -PI, PI)
			var step: float = deg_to_rad(HT_STEER_RATE) * delta
			ht_angle += clampf(diff, -step, step)
			if can_flick:
				var far: bool = _ht_hoop_ft() > PlayerScript.LAYUP_RANGE + 1.0 and _ht_hoop_ft() < HT_SHOOT_MAX_FT
				if ht_snap_clock >= HT_SNAP_EVERY:
					ht_snap_clock = 0.0
					ht_ok = true
					_ht_start("snap")
				elif ht_turn_clock >= HT_TURN_EVERY:
					ht_turn_clock = 0.0
					_ht_start("turn")
				elif ht_tap_clock >= HT_TAP_EVERY and far:
					ht_tap_clock = 0.0
					_on_a_pressed()
					if human_player.shooting and human_player.rim_kind == "":
						stat("humantest_taps")
						_ht_start("tap")
	ht_angle = wrapf(ht_angle, -PI, PI)   # a sim direction; the thumb pushes the stick that moves that way on screen
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = controls.joy_center + View.world_to_stick(Vector2.from_angle(ht_angle)) * ht_dist * controls.JOY_RADIUS
	controls._input(drag)

# press A and count it as a "random" or "timed" poke if it really poked the handler (and if it stole the ball)
func _ht_poke(kind: String) -> void:
	var pokes: int = stats.get("steal_pokes_t%d" % HUMAN_TEAM, 0)
	var steals: int = stats.get("human_steals", 0)
	_on_a_pressed()
	if stats.get("steal_pokes_t%d" % HUMAN_TEAM, 0) > pokes:
		stat("humantest_%s_pokes" % kind)
		if stats.get("human_steals", 0) > steals:
			stat("humantest_%s_steals" % kind)

# on defense, now and then poke at the right moment: next to the handler, ball exposed and low on the dribble
func _humantest_timed_poke(delta: float) -> void:
	ht_poke_wait -= delta
	var h = ball.holder
	if ht_poke_wait > 0.0 or ball.state != ball.HELD or h == null or h.team == HUMAN_TEAM:
		return
	if human_player.steal_cooldown > 0.0 or human_player.position.distance_to(h.position) > STEAL_POKE_PX:
		return
	if human_steal_cue():
		ht_poke_wait = HT_TIMED_POKE_GAP
		_ht_poke("timed")
		_on_a_released()

# on defense: when the CPU shooter near the human starts a shot (jumper, pump fake or rim move) and A says BLOCK,
# press it HT_BLOCK_DELAY later on every 2nd shot ("timed") and at once on the others ("early")
func _humantest_block(delta: float) -> void:
	var t = ball.holder if ball.state == ball.HELD else null
	var shooting: bool = t != null and t.team != HUMAN_TEAM and t.shooting
	ht_pre_t -= delta
	# an "early" turn on a drive: jump as soon as A says BLOCK (handler driving inside BLOCK_RIM_FT), before he takes
	# off. That is the earliest a thumb can jump at a rim move; on a take-off right there it is on time anyway
	if ht_block_n % 2 == 0 and ht_block_wait < 0.0 and ht_pre_t <= 0.0 and t != null and t.team != HUMAN_TEAM \
			and not shooting and not t.is_airborne() and input.defense_action() == "BLOCK" \
			and t.velocity.dot((attack_hoop(t.team) - t.position).normalized()) > HT_EARLY_DRIVE_SPEED * t.speed:
		ht_block_n += 1
		ht_block_wait = 0.0
		ht_pre_t = HT_EARLY_HOLD
		stat("humantest_block_tries")
	elif shooting and not ht_threat_shooting and input.defense_action() == "BLOCK" and ht_pre_t <= 0.0:
		ht_block_n += 1
		ht_block_wait = HT_BLOCK_DELAY if ht_block_n % 2 == 0 else 0.0
		stat("humantest_block_tries")
	ht_threat_shooting = shooting
	if ht_block_wait < 0.0:
		return
	ht_block_wait -= delta
	if ht_block_wait > 0.0:
		return
	var kind := "timed" if ht_block_n % 2 == 0 else "early"
	ht_block_wait = -1.0
	var jumps: int = stats.get("human_block_jumps", 0)
	ht_jump_kind = kind
	_on_a_pressed()
	_on_a_released()
	if stats.get("human_block_jumps", 0) > jumps:
		stat("humantest_%s_jumps" % kind)
		var th = input.block_threat()
		ht_jump_phase = "none"
		if th != null:
			ht_jump_phase = "rim" if th.rim_kind != "" else ("fake" if th.fake_t > 0.0 else ("shot" if th.shooting else "drive"))
		stat("humantest_%s_jumps_%s" % [kind, ht_jump_phase])

# on offense without the ball: CALL every HT_CALL_EVERY s (the thumb runs at the rim, so some calls are lobs).
# With the ball: now and then PASS when a teammate is near the rim (an alley-oop try once P2-09 lands).
func _humantest_call(delta: float) -> void:
	ht_lob_wait -= delta
	if possession != HUMAN_TEAM or ball.state == ball.DEAD:
		return
	if human_player.has_ball():
		if ht_lob_wait > 0.0 or human_player.shooting or human_player.rim_kind != "":
			return
		for mate in teams[HUMAN_TEAM]:
			if mate != human_player and mate.position.distance_to(attack_hoop(HUMAN_TEAM)) < HT_LOB_FT * FT:
				ht_lob_wait = HT_LOB_GAP
				stat("humantest_rim_passes")
				_on_b_pressed()
				return
		return
	if ball.state != ball.HELD or ball.holder == null or ball.holder.team != HUMAN_TEAM:
		return
	ht_call_clock += delta
	if ht_call_clock >= HT_CALL_EVERY:
		ht_call_clock = 0.0
		var calls: int = stats.get("human_calls", 0)
		_on_b_pressed()
		if stats.get("human_calls", 0) > calls:
			stat("humantest_calls")

# at the free-throw line: press SHOOT HT_FT_DELAY after getting the ball, release in the green zone on every 2nd free
# throw ("good") and early on the others; count attempts and makes of each
func _humantest_free_throw(delta: float) -> void:
	var h = human_player
	if rules.ft_shooter != h or not h.has_ball():
		ht_ft_t = 0.0
		return
	if not h.shooting:
		ht_ft_kind = ""
		ht_ft_t += delta
		if ht_ft_t >= HT_FT_DELAY:
			ht_ft_t = 0.0
			ht_ft_n += 1
			ht_ft_kind = "good" if ht_ft_n % 2 == 0 else "early"
			_on_a_pressed()
		return
	if ht_ft_kind == "":
		return
	if h.shot_charge >= (HT_FT_GOOD_CHARGE if ht_ft_kind == "good" else HT_FT_EARLY_CHARGE):
		var k: String = ht_ft_kind
		ht_ft_kind = ""
		stat("humantest_ft_%s" % k)
		_on_a_released()
		if ball.state == ball.SHOT and ball.shot_made:
			stat("humantest_ft_%s_makes" % k)

# stay-in-front metric: while a CPU handler in his frontcourt is within HT_GUARD_FT of the human, count the frames
# the human is between him and the rim, and each time the handler gets past him (closer to the rim by the margin)
func _humantest_guard_metric() -> void:
	var h = ball.holder if ball.state == ball.HELD else null
	var d = human_player
	var on: bool = h != null and h.team != HUMAN_TEAM and in_frontcourt(h.position, h.team) \
			and not h.is_airborne() and d.position.distance_to(h.position) <= HT_GUARD_FT * FT
	if not on:
		ht_guard_on = false
		return
	var hoop: Vector2 = attack_hoop(h.team)
	var lead_ft: float = (h.position.distance_to(hoop) - d.position.distance_to(hoop)) / FT
	if not ht_guard_on or h != ht_guard_holder:
		stat("humantest_guard_spells")
		ht_guard_holder = h
		ht_guard_front = lead_ft > 0.0
	elif ht_guard_front and lead_ft < -HT_BEAT_MARGIN_FT:
		ht_guard_front = false
		stat("humantest_guard_beaten")   # was in front, now the handler is past him
	elif not ht_guard_front and lead_ft > HT_BEAT_MARGIN_FT:
		ht_guard_front = true
	ht_guard_on = true
	stat("humantest_guard_frames")
	if ht_guard_front:
		stat("humantest_guard_front_frames")

func _ht_summary() -> String:
	var f := func(a: String, b: String) -> String:
		return "%d/%d" % [stats.get(a, 0), stats.get(b, 0)]
	var gf: int = stats.get("humantest_guard_frames", 0)
	var front_pct: float = 100.0 * float(stats.get("humantest_guard_front_frames", 0)) / float(maxi(gf, 1))
	return "HUMANTEST steals timed %s random %s | blocks timed %s early %s | in front %.0f%% beaten %d in %d spells | assist %d frames, %d while pulling away, crossovers beat him %s | free throws good %s early %s" % [
		f.call("humantest_timed_steals", "humantest_timed_pokes"), f.call("humantest_random_steals", "humantest_random_pokes"),
		f.call("humantest_timed_blocks", "humantest_timed_jumps"), f.call("humantest_early_blocks", "humantest_early_jumps"),
		front_pct, stats.get("humantest_guard_beaten", 0), stats.get("humantest_guard_spells", 0),
		stats.get("human_assist_frames", 0), stats.get("humantest_away_assist_frames", 0),
		f.call("human_cross_beaten", "human_cross_faced"),
		f.call("humantest_ft_good_makes", "humantest_ft_good"), f.call("humantest_ft_early_makes", "humantest_ft_early")]

func _ht_hoop_ft() -> float:
	return human_player.position.distance_to(attack_hoop(HUMAN_TEAM)) / FT

func _ht_start(mode: String) -> void:
	ht_mode = mode
	ht_t = 0.0
	ht_frames = 0
	if mode == "pull":
		ht_dist = HT_PULL_FROM

func _separate_players() -> void:
	var min_d := 24.0
	for i in players.size():
		for j in range(i + 1, players.size()):
			var a = players[i]
			var b = players[j]
			var d: Vector2 = b.position - a.position
			var l := d.length()
			if l < min_d and l > 0.01:
				var push := d / l * (min_d - l) * 0.5
				a.position -= push
				b.position += push

# the game is won (rules.gd decides when): stop play, show the result and the level panel (P3-08), print the test lines
func on_game_over(winner: int) -> void:
	game_over = true
	audio.play("whistle")
	ball.make_dead()
	# _physics_process stops updating after game over: put out the fire and the trail now
	for p in players:
		if p.on_fire:
			_end_fire(p)
	_trail_on = false
	fx.set_trail(false)
	audio.play("whistle", 3.0, 0.0)   # second, louder whistle: game over
	_update_hud()
	if autoplay or humantest:
		show_message("FINAL  %d - %d\n%s WINS!" % [score[0], score[1], TEAM_NAMES[winner]], 9999.0, TEAM_COLORS[winner])
	else:
		# P3-08: the level panel under the final score; a tap on a level plays again
		msg_label.visible = false
		_menu_input(true)
		menu.show_game_over(score, winner, TEAM_COLORS[winner])
	if autoplay or humantest:
		var secs: int = int(rules.play_time)
		print("FINAL BLUE %d - RED %d" % [score[0], score[1]])
		print("GAME LENGTH %d:%02d" % [secs / 60, secs % 60])
		var g := func(k: String) -> int:
			return int(stats.get(k, 0))
		print("FOULS BLUE %d RED %d (shooting %d, reach %d, and-ones %d) | FREE THROWS %d/%d (BLUE %d/%d, RED %d/%d), last missed %d, timeouts %d" % [
				g.call("fouls_t0"), g.call("fouls_t1"), g.call("fouls_shooting"), g.call("fouls_reach"), g.call("and_ones"),
				g.call("free_throw_makes"), g.call("free_throws"), g.call("ft_makes_t0"), g.call("ft_attempts_t0"),
				g.call("ft_makes_t1"), g.call("ft_attempts_t1"), g.call("ft_last_misses"), g.call("ft_timeouts")])
		print(stats)
		if humantest:
			print(_ht_summary())
		get_tree().quit()

# ---------------- HUD ----------------

# lit STEAL: a pulsing ring on the floor where the dribble bounces (P2.5), next to where the eyes are (decals layer)
func _draw_steal_cue() -> void:
	if controls.a_glow and ball.state == ball.HELD and ball.holder != null:
		var pulse: float = 0.5 + 0.5 * sin(float(_frame) * 0.5)
		draw_floor_ring(_steal_node, ball.position, 9.0 + 2.0 * pulse, STEAL_CUE_RING_COLOR, 2.5)

# a circle of radius r (sim px) lying on the floor at sim point center, drawn through the view: FLAT a circle (as
# before), ANGLED the projected ellipse. For any decal node (shadows, rings): call it from that node's draw callback.
func draw_floor_ring(node: CanvasItem, center: Vector2, r: float, color: Color, width: float, segments := 24) -> void:
	if not View.angled():
		node.draw_arc(center, r, 0, TAU, segments, color, width)
		return
	var pts := PackedVector2Array()
	for i in segments + 1:
		pts.append(View.to_screen(center + Vector2.from_angle(TAU * float(i) / float(segments)) * r))
	node.draw_polyline(pts, color, width)

# the call was heard: a "!" speech bubble over the caller, plus a faint line from the teammate with the ball
# (overlay layer; the bubble floats CALL_CUE_RISE above the caller's projected feet)
func _draw_call_cue() -> void:
	if autoplay or not input.call_active() or human_player == null:
		return
	var h = human_player
	var pulse: float = 0.5 + 0.5 * sin(input.call_t * 18.0)
	var c: Vector2 = View.to_screen(h.position, CALL_CUE_RISE + 3.0 * pulse)
	var q = input.call_passer()
	if q != null:
		_call_node.draw_line(View.to_screen(q.position), View.to_screen(h.position), Color(CALL_CUE_COLOR, 0.35), 2.0)
	_call_node.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 9), c + Vector2(5, 9),
			View.to_screen(h.position, CALL_CUE_RISE - 18.0)]), Color.WHITE)
	_call_node.draw_circle(c, 12.0, Color.WHITE)
	_call_node.draw_arc(c, 12.0, 0, TAU, 24, CALL_CUE_COLOR, 2.5)
	var font := ThemeDB.fallback_font
	var fs := 20
	var w: float = font.get_string_size("!", HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	_call_node.draw_string(font, c + Vector2(-w / 2.0, fs * 0.36), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.2, 0.5))

func show_message(text: String, time := 1.2, color := Color.WHITE) -> void:
	msg_label.text = text
	msg_label.modulate = color
	msg_label.modulate.a = 1.0
	msg_timer = time
	msg_age = 0.0
	msg_label.pivot_offset = msg_label.size / 2.0
	msg_label.scale = Vector2(MSG_POP_SCALE, MSG_POP_SCALE)

func _update_message(delta: float) -> void:
	if msg_timer > 0.0:
		msg_timer -= delta
		msg_age += delta
		var k: float = minf(msg_age / MSG_POP_TIME, 1.0)
		var sc: float = lerpf(MSG_POP_SCALE, 1.0, 1.0 - (1.0 - k) * (1.0 - k))   # ease out
		msg_label.pivot_offset = msg_label.size / 2.0
		msg_label.scale = Vector2(sc, sc)
		if msg_timer < 0.4:
			msg_label.modulate.a = maxf(0.0, msg_timer / 0.4)

func _update_hud() -> void:
	# the arrow next to BLUE shows which way BLUE attacks; it flips at the side switch
	if attack_hoop(HUMAN_TEAM).x > COURT_W / 2:
		score_label.text = "BLUE %s  %d   -   %d  RED" % [SIDE_ARROW_RIGHT, score[0], score[1]]
	else:
		score_label.text = "%s BLUE  %d   -   %d  RED" % [SIDE_ARROW_LEFT, score[0], score[1]]
	var gp := -1
	for t in 2:
		if rules.is_game_point(t):
			gp = t if gp < 0 else 2   # 2: both teams at game point
	if gp >= 0:
		clock_label.text = "GAME POINT"
		clock_label.modulate = TEAM_COLORS[gp] if gp < 2 else Color.WHITE
	else:
		clock_label.text = "FIRST TO %d" % rules.target
		clock_label.modulate = Color.WHITE
	if rules.GAME_TIME_CAP > 0.0:
		var t: float = rules.time_left()
		clock_label.text += "  %d:%02d" % [int(t) / 60, int(t) % 60]
	shot_label.text = "SHOT %d" % int(ceil(max(shot_clock, 0.0)))
	ft_label.text = rules.ft_hud_text()
	if rules.ft_phase != "" and rules.ft_shooter != null:
		ft_label.modulate = TEAM_COLORS[rules.ft_shooter.team]
	if rules.ft_active and not (human_player != null and human_player == rules.ft_shooter):
		controls.a_text = "-"   # someone else is at the line: wait
		controls.b_text = "-"
	elif rules.ft_active:
		controls.a_text = "SHOOT"
		controls.b_text = "-"
	elif human_player != null and human_player.has_ball():
		controls.a_text = "SHOOT"
		controls.b_text = "PASS"
	elif possession == HUMAN_TEAM and ball.state != ball.DEAD:
		controls.a_text = "-"
		controls.b_text = "CALL"
	else:
		controls.a_text = input.defense_action()   # "STEAL" or "BLOCK" (human_input.gd picks)
		controls.b_text = "SWITCH"
	controls.b_glow = controls.b_text == "CALL" and not autoplay and input.call_active()
	controls.b_dim = controls.b_text == "CALL" and input.call_cd > 0.0 and not input.call_active()
	if controls.b_glow:
		stat("human_call_cue_frames")
	controls.a_block = controls.a_text == "BLOCK"
	if controls.a_block and not autoplay:
		stat("human_block_label_frames")
	controls.a_glow = controls.a_text == "STEAL" and not autoplay and human_steal_cue()
	if controls.a_glow:
		stat("human_steal_cue_frames")
