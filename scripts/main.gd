extends Node2D
# Road Trip Hoops: 3v3 full court basketball.
# You control the BLUE team (the player with the yellow ring). BLUE shoots at the RIGHT hoop.
#
# Touch: drag anywhere on the left half to move.
#   Offense: hold SHOOT, release in the green zone of the meter. PASS throws to the open teammate
#            (or the teammate in the direction you are pushing).
#   Defense: the orange button is STEAL or BLOCK (picked for you). STEAL pokes at the ball: poke when the dribble is
#            low and the ball is not behind his body. BLOCK (your man shoots, or is near the rim, and you're close)
#            jumps: time it so you're high when the ball leaves his hand. Don't bite on pump fakes. SWITCH changes player.
# Keyboard (for testing): WASD/arrows move, J = shoot/steal, K = pass/switch.

const PlayerScript = preload("res://scripts/player.gd")
const BallScript = preload("res://scripts/ball.gd")
const CourtScript = preload("res://scripts/court.gd")
const ControlsScript = preload("res://scripts/touch_controls.gd")
const AudioScript = preload("res://scripts/audio.gd")
const FxScript = preload("res://scripts/fx.gd")
const HumanInputScript = preload("res://scripts/human_input.gd")
const DefenseScript = preload("res://scripts/defense.gd")

const FT := 12.0                     # pixels per foot
const COURT_W := 94.0 * FT
const COURT_H := 50.0 * FT
const QUARTER_LENGTH := 120.0        # seconds per quarter (change to make games longer)
const OVERTIME_LENGTH := 60.0
const SHOT_CLOCK_LENGTH := 24.0
const HUMAN_TEAM := 0
const TEAM_NAMES := ["BLUE", "RED"]
const TEAM_COLORS := [Color(0.7, 0.88, 1.0), Color(1.0, 0.42, 0.38)]   # popups and score messages

# game-event feedback (P1-06)
const SCORE_POPUP_SIZE := 64         # font size of the "+2"/"+3" popup at the hoop
const SCORE_POPUP_RISE := 3.0 * FT   # popup starts this far above the rim
const SCORE_MSG_TIME := 0.8          # the center "BLUE SCORES" message is short, the popup carries it
const BLOCK_SHAKE := 6.0             # screen shake on a block: strength in pixels
const BLOCK_SHAKE_TIME := 0.25       # and how long it lasts
const MSG_FONT_SIZE := 56            # center message font size
const MSG_POP_TIME := 0.15           # center message scale-in time in seconds
const MSG_POP_SCALE := 1.35          # center message start scale

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
const STEAL_GRACE := 0.05            # seconds either side of a floor touch that count as a well-timed poke (human).
                                     # The dribble touches the floor every 0.35 s, so 0.05 is 29% of the cycle; the
                                     # STEAL button stays lit about 6 frames per bounce. 0.1 would be 57% (mashing works)
const STEAL_CPU_GRACE := STEAL_GRACE # CPU pokes: same window as the human (defense.gd times them on the floor touch)
const STEAL_HELD_TIMING := 0.25      # timing factor when the ball is held up (gathering a shot, pump fake, at the rim)

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
const HT_BLOCK_DELAY := 0.15         # on defense: press BLOCK this long after a CPU shot starts (every 2nd shot; else at once)

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
var score := [0, 0]
var quarter := 1
var game_clock := QUARTER_LENGTH
var shot_clock := SHOT_CLOCK_LENGTH
var shot_clock_running := true
var possession := 0
var human_player = null
var dead_timer := 0.0
var pending_inbound := -1           # team that gets the ball when the dead ball pause ends
var pending_new_quarter := false
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
var shot_serial := 0                # counts released shots, so each defender gets one block try per shot (defense.gd)

func stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

var score_label: Label
var clock_label: Label
var shot_label: Label
var msg_label: Label
var msg_timer := 0.0
var msg_age := 0.0

# ---------------- setup ----------------

func _ready() -> void:
	rng.randomize()
	autoplay = OS.get_cmdline_user_args().has("--autoplay")
	humantest = OS.get_cmdline_user_args().has("--humantest")

	audio = AudioScript.new()
	audio.game = self
	add_child(audio)

	var floor_node = CourtScript.new()
	floor_node.game = self
	floor_node.z_index = -10
	add_child(floor_node)
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
	camera.zoom = Vector2(1.15, 1.15)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
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

	_build_hud()
	start_period()

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

func start_period() -> void:
	game_clock = QUARTER_LENGTH if quarter <= 4 else OVERTIME_LENGTH
	var team := 0 if quarter in [1, 4, 5] else 1
	reset_positions(team)
	give_ball(teams[team][0])
	if quarter <= 4:
		show_message("QUARTER %d" % quarter, 1.5)
	else:
		show_message("OVERTIME", 1.5)

func reset_positions(team: int) -> void:
	var own: Vector2 = attack_hoop(1 - team)   # the hoop this team defends
	var dir := inward(own)
	for i in 3:
		var o = teams[team][i]
		o.position = own + Vector2(dir * (5 + i * 12) * FT, [0.0, -12.0, 12.0][i] * FT)
		o.velocity = Vector2.ZERO
		var d = teams[1 - team][i]
		d.position = Vector2(COURT_W / 2 + dir * 10 * FT, COURT_H / 2 + [0.0, -12.0, 12.0][i] * FT)
		d.velocity = Vector2.ZERO
		o.shooting = false
		d.shooting = false

# ---------------- court helpers ----------------

func attack_hoop(team: int) -> Vector2:
	return hoops[1] if team == 0 else hoops[0]

func inward(hoop: Vector2) -> float:
	return 1.0 if hoop.x < COURT_W / 2 else -1.0

func in_frontcourt(pos: Vector2, team: int) -> bool:
	return pos.x > COURT_W / 2 if team == 0 else pos.x < COURT_W / 2

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
	if p.team == HUMAN_TEAM:
		human_player = p
	elif human_player == null or human_player.team != HUMAN_TEAM:
		human_player = teams[HUMAN_TEAM][0]

func release_shot(p, quality: float) -> void:
	if not p.has_ball():
		return
	var hoop := attack_hoop(p.team)
	var prob := shot_probability(p, quality)
	var made := rng.randf() < prob
	var pts := 3 if is_three(p.position, hoop) else 2
	shot_clock_running = false
	shot_serial += 1
	stat("shots")
	stat("shot_d%d" % int(p.position.distance_to(hoop) / FT / 5) )
	if made: stat("makes")
	if p.on_fire:
		stat("fire_shots")
		if made: stat("fire_makes")
	ball.shoot(p, hoop, made, pts)

# a dunk or layup blocked at take-off: counts as a missed shot, the ball is swatted out of the shooter's hands
func rim_shot_blocked(p, defender) -> void:
	shot_clock_running = false
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
	fx.shake(BLOCK_SHAKE, BLOCK_SHAKE_TIME)
	audio.play("block")
	if missed_shooter != null:
		on_shot_missed(missed_shooter)   # after "BLOCKED!" so a "cooling down" message wins

func on_shot_made(shooter, pts: int) -> void:
	score[shooter.team] += pts
	show_message("%s %s!" % [TEAM_NAMES[shooter.team], "THREE" if pts == 3 else "SCORES"], SCORE_MSG_TIME,
			TEAM_COLORS[shooter.team])
	var hoop := attack_hoop(shooter.team)
	if ball.shot_kind != "dunk":   # a dunk already shows "SLAM!"
		fx.popup("+%d" % pts, hoop + Vector2(0, -SCORE_POPUP_RISE), TEAM_COLORS[shooter.team], SCORE_POPUP_SIZE)
	audio.play("crowd")
	_update_fire_on_make(shooter)
	possession = 1 - shooter.team
	_dead_ball(1 - shooter.team, 1.0)

func on_shot_missed(shooter) -> void:
	if shooter == null:
		return
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
	if from_p.team == HUMAN_TEAM:
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

# how well a poke at this handler's ball is timed right now: 1 within `grace` s of a dribble floor touch, else 0
# (STEAL_HELD_TIMING while the ball is held up). grace < 0 means STEAL_GRACE.
func steal_timing(handler, grace := -1.0) -> float:
	if not STEAL_TIMING:
		return 1.0
	if handler == null or not (ball.state == ball.HELD and ball.holder == handler):
		return 0.0
	if handler.shooting or handler.rim_kind != "" or ("fake_t" in handler and handler.fake_t > 0.0):
		return STEAL_HELD_TIMING
	var g: float = STEAL_GRACE if grace < 0.0 else grace
	var ph: float = fposmod(ball.anim_time, DRIBBLE_PERIOD)
	return 1.0 if minf(ph, DRIBBLE_PERIOD - ph) <= g else 0.0

# 0..1: exposure x timing. At or over STEAL_GOOD_EXPOSURE it's a good poke.
func steal_quality(defender, handler) -> float:
	var grace: float = STEAL_GRACE if is_human(defender) else STEAL_CPU_GRACE
	return steal_exposure(defender, handler) * steal_timing(handler, grace)

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
	var k: float = lerpf(good, q, STEAL_LUCK)
	if k <= 0.0:
		return 0.0
	var r: float = 50.0
	if defender.has_method("rating"):
		r = float(defender.rating("steal"))
	var c: float = (STEAL_BASE + (clampf(r, 0.0, 100.0) / 50.0 - 1.0) * STEAL_RATING_SPAN) * k
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
	if defender.steal_cooldown > 0.0:
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

func _dead_ball(next_team: int, wait: float) -> void:
	ball.make_dead()
	pending_inbound = next_team
	dead_timer = wait
	shot_clock_running = false

func _inbound(team: int) -> void:
	# inbound from the baseline under the hoop this team defends
	var own := attack_hoop(1 - team)
	var spot := Vector2(own.x - inward(own) * 3.5 * FT, own.y + 5 * FT)
	var best = teams[team][0]
	var best_d := INF
	for p in teams[team]:
		var d: float = p.position.distance_to(own)
		if d < best_d:
			best_d = d
			best = p
	best.position = clamp_to_court(spot)
	give_ball(best)

# ---------------- input ----------------

func _on_a_pressed() -> void:
	input.a_pressed()

func _on_a_released() -> void:
	input.a_released()

func _on_b_pressed() -> void:
	input.b_pressed()

func _unhandled_input(event: InputEvent) -> void:
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

func _input_vector() -> Vector2:
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

func _debug_screenshots() -> void:
	# developer testing only: run with -- --shots to save a few screenshots to /tmp
	_frame += 1
	if OS.get_cmdline_user_args().has("--shots") and controls.a_glow and not _cue_shot:
		_cue_shot = true   # first frame with the STEAL button lit (try -- --shots --humantest)
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_steal_cue.png")
	if OS.get_cmdline_user_args().has("--shots") and controls.a_block and not _block_shot:
		_block_shot = true   # first frame the orange button says BLOCK (try -- --shots --humantest)
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_block_label.png")
	if OS.get_cmdline_user_args().has("--shots") and _frame in [240, 900, 1800]:
		get_viewport().get_texture().get_image().save_png("/tmp/hoops_%d.png" % _frame)
		if _frame == 1800:
			get_tree().quit()

func _physics_process(delta: float) -> void:
	_debug_screenshots()
	_update_message(delta)
	if game_over:
		return

	if dead_timer > 0.0:
		dead_timer -= delta
		if dead_timer <= 0.0:
			if pending_new_quarter:
				pending_new_quarter = false
				start_period()
			elif pending_inbound >= 0:
				_inbound(pending_inbound)
			pending_inbound = -1
	else:
		game_clock -= delta
		if shot_clock_running and ball.state != ball.DEAD:
			shot_clock -= delta
			if shot_clock <= 0.0:
				show_message("SHOT CLOCK!")
				stat("shotclock")
				audio.play("whistle")
				var p = ball.holder if ball.holder != null else ball.passer
				var next_team: int = 1 - (p.team if p != null else possession)
				_dead_ball(next_team, 1.0)
		if game_clock <= 0.0 and ball.state != ball.SHOT:
			_end_period()
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
		if _frame % 97 == 0 and not (human_player.has_ball() and _ht_hoop_ft() > HT_SHOOT_MAX_FT):
			ht_jump_kind = "random"
			_ht_poke("random")   # on offense: a shot (meter held 50 frames); on defense: a randomly timed poke
		if _frame % 97 == 50: _on_a_released()
		if _frame % 211 == 0: _on_b_pressed()
		_humantest_thumb(delta)
		_humantest_timed_poke(delta)
		_humantest_block(delta)
	var stick := _input_vector()
	input.update(delta, stick)
	for p in players:
		p.update(delta, is_human(p), stick)
	_separate_players()
	ball.update(delta)
	DefenseScript.check_jump_shot_block(self)
	_update_fire_trail()

	camera.position = ball.position
	_update_hud()

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
	var can_flick: bool = input.flick_ready()
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
	ht_angle = wrapf(ht_angle, -PI, PI)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = controls.joy_center + Vector2.from_angle(ht_angle) * ht_dist * controls.JOY_RADIUS
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
	if shooting and not ht_threat_shooting and input.defense_action() == "BLOCK":
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

func _end_period() -> void:
	game_clock = 0.0
	audio.play("whistle")
	if autoplay:
		print("End of period %d: BLUE %d - RED %d" % [quarter, score[0], score[1]])
	if quarter >= 4 and score[0] != score[1]:
		game_over = true
		ball.make_dead()
		# _physics_process stops updating after game over: put out the fire and the trail now
		for p in players:
			if p.on_fire:
				_end_fire(p)
		_trail_on = false
		fx.set_trail(false)
		var winner := "BLUE" if score[0] > score[1] else "RED"
		audio.play("whistle", 3.0, 0.0)   # second, louder whistle: game over
		show_message("FINAL  %d - %d\n%s WINS!  Tap to play again" % [score[0], score[1], winner], 9999.0)
		if autoplay or humantest:
			print("FINAL BLUE %d - RED %d" % [score[0], score[1]])
			print(stats)
			get_tree().quit()
		return
	quarter += 1
	show_message("END OF %s" % ("QUARTER %d" % (quarter - 1) if quarter <= 5 else "OVERTIME"), 1.5)
	ball.make_dead()
	pending_new_quarter = true
	dead_timer = 2.0

# ---------------- HUD ----------------

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
	score_label.text = "BLUE  %d   -   %d  RED" % [score[0], score[1]]
	var t: float = max(game_clock, 0.0)
	var period := ("Q%d" % quarter) if quarter <= 4 else "OT"
	clock_label.text = "%s  %d:%02d" % [period, int(t) / 60, int(t) % 60]
	shot_label.text = "SHOT %d" % int(ceil(max(shot_clock, 0.0)))
	if human_player != null and human_player.has_ball():
		controls.a_text = "SHOOT"
		controls.b_text = "PASS"
	elif possession == HUMAN_TEAM and ball.state != ball.DEAD:
		controls.a_text = "-"
		controls.b_text = "-"
	else:
		controls.a_text = input.defense_action()   # "STEAL" or "BLOCK" (human_input.gd picks)
		controls.b_text = "SWITCH"
	controls.a_block = controls.a_text == "BLOCK"
	if controls.a_block and not autoplay:
		stat("human_block_label_frames")
	controls.a_glow = controls.a_text == "STEAL" and not autoplay and human_steal_cue()
	if controls.a_glow:
		stat("human_steal_cue_frames")
