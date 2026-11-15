extends Node2D
# Road Trip Hoops: 3v3 full court basketball.
# You control the BLUE team (the player with the yellow ring). BLUE shoots at the RIGHT hoop.
#
# Touch: drag anywhere on the left half to move.
#   Offense: hold SHOOT, release in the green zone of the meter. PASS throws to the open teammate
#            (or the teammate in the direction you are pushing).
#   Defense: STEAL pokes at the ball (or blocks a shot that was just released). SWITCH changes player.
# Keyboard (for testing): WASD/arrows move, J = shoot/steal, K = pass/switch.

const PlayerScript = preload("res://scripts/player.gd")
const BallScript = preload("res://scripts/ball.gd")
const CourtScript = preload("res://scripts/court.gd")
const ControlsScript = preload("res://scripts/touch_controls.gd")
const AudioScript = preload("res://scripts/audio.gd")
const FxScript = preload("res://scripts/fx.gd")

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

var hoops := [Vector2(5.25 * FT, COURT_H / 2), Vector2(COURT_W - 5.25 * FT, COURT_H / 2)]

var rng := RandomNumberGenerator.new()
var players: Array = []
var teams := [[], []]
var ball
var controls
var camera: Camera2D
var audio                           # sound effects: audio.play("swish")
var fx                              # shake, popups, ball trail: fx.shake(6.0, 0.3)
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

func attempt_steal(defender, chance: float) -> void:
	if defender.steal_cooldown > 0.0:
		return
	defender.steal_cooldown = 0.7
	if ball.state == ball.SHOT and ball.shot_t < 0.3 and ball.shooter.team != defender.team:
		if defender.position.distance_to(ball.shooter.position) < 45.0 and rng.randf() < 0.3:
			block_shot(defender)
		return
	var h = ball.holder
	if ball.state != ball.HELD or h == null or h.team == defender.team:
		return
	if defender.position.distance_to(h.position) > 40.0:
		return
	if rng.randf() < chance:
		var v: Vector2 = (defender.position - h.position).normalized().rotated(rng.randf_range(-0.8, 0.8)) * 160.0
		h.shooting = false
		ball.make_loose(ball.position, v, 8.0, 60.0)
		show_message("STEAL!")
		stat("steals")

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
	if game_over:
		get_tree().reload_current_scene()
		return
	if human_player == null:
		return
	if human_player.has_ball():
		human_player.start_shot()
	elif possession != HUMAN_TEAM or ball.state == ball.SHOT:
		attempt_steal(human_player, 0.28)

func _on_a_released() -> void:
	if human_player != null and human_player.shooting:
		human_player.release_shot()

func _on_b_pressed() -> void:
	if human_player == null or game_over:
		return
	if human_player.has_ball():
		var dir: Vector2 = _input_vector()
		var best = null
		var best_score := -INF
		for mate in teams[HUMAN_TEAM]:
			if mate == human_player:
				continue
			var to: Vector2 = mate.position - human_player.position
			var s: float = openness(mate) - to.length() / FT * 0.3
			if dir.length() > 0.3:
				s += dir.normalized().dot(to.normalized()) * 30.0
			if s > best_score:
				best_score = s
				best = mate
		do_pass(human_player, best)
	elif possession != HUMAN_TEAM:
		_switch_player()

func _switch_player() -> void:
	var best = null
	var best_d := INF
	for p in teams[HUMAN_TEAM]:
		if p == human_player:
			continue
		var d: float = p.position.distance_to(ball.position)
		if d < best_d:
			best_d = d
			best = p
	if best != null:
		human_player = best

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
	var v: Vector2 = controls.joystick()
	if OS.get_cmdline_user_args().has("--humantest") and human_player != null:
		# developer testing only: a simple scripted "thumb" exercising every control
		var goal: Vector2 = attack_hoop(HUMAN_TEAM) if possession == HUMAN_TEAM else ball.position
		v = (goal - human_player.position).normalized()
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	return v.limit_length(1.0)

# ---------------- main loop ----------------

var _frame := 0

func _debug_screenshots() -> void:
	# developer testing only: run with -- --shots to save a few screenshots to /tmp
	_frame += 1
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

	if OS.get_cmdline_user_args().has("--humantest") and human_player != null:
		if _frame % 97 == 0: _on_a_pressed()
		if _frame % 97 == 50: _on_a_released()
		if _frame % 211 == 0: _on_b_pressed()
	var input := _input_vector()
	for p in players:
		p.update(delta, is_human(p), input)
	_separate_players()
	ball.update(delta)
	_update_fire_trail()

	camera.position = ball.position
	_update_hud()

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
		if autoplay or OS.get_cmdline_user_args().has("--humantest"):
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
		controls.a_text = "STEAL"
		controls.b_text = "SWITCH"
