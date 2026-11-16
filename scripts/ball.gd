extends Node2D
# The basketball. position = spot on the floor; z = height above the floor (drawn as an upward offset).

enum { HELD, PASS, SHOT, LOOSE, DEAD }

var game
var state := DEAD
var holder = null          # player holding the ball
var receiver = null        # pass target
var passer = null
var shooter = null
var shot_start := Vector2.ZERO
var shot_hoop := Vector2.ZERO
var shot_t := 0.0
var shot_time := 1.0
var shot_peak := 80.0
var shot_made := false
var shot_points := 2
var blocked_checked := false
var z := 0.0
var vz := 0.0
var vel := Vector2.ZERO
var intercept_checked := {}
var sprite: Sprite2D
var anim_time := 0.0
var next_shot_kind := ""   # set by the shooter just before release: "dunk", "layup" or "" (jump shot)
var shot_kind := ""
var shot_z0 := 26.0        # height the shot leaves the hand
var bounce_cooldown := 0.0
var dribble_count := 0
var dribble_phase := 0     # which half-cycle of the dribble the ball is in; a change means a floor touch
var lob := false           # the current PASS is an alley-oop lob (P2-09)
var lob_t := 0.0           # 0..1 along the lob's flight
var lob_time := 0.6        # seconds of the lob's flight
var lob_start := Vector2.ZERO
var lob_takeoff_sent := false
var next_alley := false    # set by the alley-oop dunker just before release (like next_shot_kind)
var shot_alley := false    # the shot in flight is an alley-oop dunk
var last_touch_team := -1  # team that touched the ball last (P3-07): the other team gets it if it goes out
var loose_cause := ""      # why the ball is loose: "steal", "block", "rebound", "pass" (out-of-bounds stats)

# ---- dunk and layup flight (tuning) ----
const DUNK_FLIGHT := 0.12      # seconds from the hand to the rim on a dunk (a quick slam)
const LAYUP_FLIGHT := 0.4      # seconds for a layup's short soft arc
const LAYUP_PEAK := 26.0       # extra arc height of a layup in pixels
const HAND_Z := 22.0           # ball height above a jumping player's jump height
const SLAM_COLOR := Color(1.0, 0.55, 0.1)

# ---- held ball and the dribble hand (P2-05; player.hand_x is -1 left hand .. +1 right hand) ----
const HAND_FORWARD_PX := 13.0  # ball this far in front of the handler (main.STEAL_BALL_PX is 15 with no hand)
const HAND_SIDE_PX := 9.0      # and this far to the side of the dribbling hand
const CROSS_FRONT_PX := 6.0    # extra reach in front of the body while the ball crosses between the hands
const PUMP_BALL_LIFT := 1.6     # pump fake: the ball rises this many times the hop height (P2-06)

# ---- ball and rim sounds (tuning) ----
const BOUNCE_MIN_SPEED := 120.0   # a loose ball must hit the floor at least this fast (px/s down) to make a sound
const BOUNCE_LOUD_SPEED := 380.0  # impact speed that plays at full volume
const BOUNCE_QUIET_DB := -14.0    # volume of the softest audible bounce
const BOUNCE_GAP := 0.15          # seconds between bounce sounds, so a rolling ball can't spam them
const RIM_DB := -2.0              # volume of the clank on a missed shot
const RIM_WIGGLE := 0.3           # net movement on a rim-out (1.0 = full swish)
const LAYUP_SWISH_DB := -4.0      # a made layup gets a softer swish than a jump shot
const DUNK_NET := 1.6             # dunks yank the net harder (the dunk sound itself is in slam_feedback)
const DRIBBLE_DB := -8.0          # soft dribble for the human's handler only (owner: -18 was inaudible on the tablet)
const DRIBBLE_EVERY := 2          # play the dribble sound on every Nth floor touch

# ---- alley-oop lob (P2-09; owner Q5: automatic, a pass to a cutter is a lob he dunks in the air) ----
const ALLEY_FT := 12.0            # the receiver must be this close to the rim he attacks
const ALLEY_MIN_FT := 2.0         # ... and not already under it
const ALLEY_CUT_SPEED := 0.6      # "cutting" without alley_cut: moving toward the rim at this fraction of top speed
const ALLEY_FRONT_FT := 4.0       # no defender in front of the receiver (toward the rim) within this
const ALLEY_FRONT_CONE := 60.0    # degrees either side of the receiver-to-rim line that count as "in front"
const ALLEY_PASS_MIN_FT := 8.0    # passer at least this far from the receiver (no lob to the man next to you)
const ALLEY_PASS_MAX_FT := 45.0   # ... and at most this far
const LOB_SPEED := 480.0          # px/s along the floor (a normal pass is PASS_SPEED)
const LOB_TIME_MIN := 0.45        # seconds of flight, clamped to these
const LOB_TIME_MAX := 1.0
const LOB_PEAK := 70.0            # extra arc height in pixels
const LOB_CATCH_Z := 50.0         # height where the jumping receiver catches it
const LOB_PICK_FRAC := 0.4        # only the first 40% of the flight can be picked off (then it's over everyone)
const ALLEY_POPUP_COLOR := Color(0.35, 0.85, 1.0)

# ---- out of bounds (P3-07, owner Q5: simple, only a loose ball crossing a sideline or baseline is out) ----
const OOB_MARGIN_PX := 2.0        # the ball's center must be this far past the line (on the line is still in)
const RIM_LONG_CHANCE := 0.08     # a missed shot kicks long off the back of the rim (toward the baseline, usually out)
const RIM_LONG_ANGLE := 0.7       # radians either side of straight back
const RIM_LONG_SPEED_MIN := 230.0 # px/s
const RIM_LONG_SPEED_MAX := 340.0
const RIM_WIDE_CHANCE := 0.06     # ... or hard off the side of the rim, a long rebound toward a sideline
const RIM_WIDE_ANGLE_MIN := 1.15  # radians from straight out toward the court (PI / 2 = along the baseline)
const RIM_WIDE_ANGLE_MAX := 1.55
const RIM_WIDE_SPEED_MIN := 430.0 # px/s
const RIM_WIDE_SPEED_MAX := 540.0

const PASS_SPEED := 720.0
const GRAVITY := 900.0

func setup(g) -> void:
	game = g
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/ball.png")
	sprite.scale = Vector2(1.1, 1.1)
	add_child(sprite)
	z_index = 20

func hold(p) -> void:
	state = HELD
	holder = p
	last_touch_team = p.team
	receiver = null
	lob = false
	shooter = null
	vel = Vector2.ZERO
	game.on_ball_held(p)

# lob: -1 = decide by the alley-oop rule (is_lob_target), 0 = never a lob, 1 = always a lob.
# game.do_pass (the human's PASS, the CPU, P2-10's call) goes through here, so every pass to a cutter is a lob.
func pass_to(from_p, to_p, lob_mode := -1) -> void:
	var make_lob := lob_mode == 1 or (lob_mode < 0 and is_lob_target(to_p, from_p))
	state = PASS
	passer = from_p
	if from_p != null:
		last_touch_team = from_p.team
	receiver = to_p
	holder = null
	intercept_checked = {}
	z = 18.0
	lob = false
	if make_lob and to_p != null:
		throw_lob(from_p, to_p)

# The alley-oop rule (board "Touch gestures"): the receiver is cutting (alley_cut, or running at the rim at
# ALLEY_CUT_SPEED of top speed), within ALLEY_FT of the rim he attacks, on the floor, with no defender in front of
# him toward the rim within ALLEY_FRONT_FT. from_p (optional) must be a teammate between ALLEY_PASS_MIN_FT and
# ALLEY_PASS_MAX_FT away.
func is_lob_target(p, from_p = null) -> bool:
	if p == null or game == null:
		return false
	if p.is_airborne() or p.stumble_t > 0.0 or p.has_ball():
		return false
	var FT: float = game.FT
	if from_p != null:
		if from_p.team != p.team or from_p == p:
			return false
		var pd: float = from_p.position.distance_to(p.position) / FT
		if pd < ALLEY_PASS_MIN_FT or pd > ALLEY_PASS_MAX_FT:
			return false
	var hoop: Vector2 = game.attack_hoop(p.team)
	var to_hoop: Vector2 = hoop - p.position
	var d_ft := to_hoop.length() / FT
	if d_ft > ALLEY_FT or d_ft < ALLEY_MIN_FT:
		return false
	var dir := to_hoop.normalized()
	var cutting: bool = p.alley_cut or p.velocity.dot(dir) >= ALLEY_CUT_SPEED * p.speed
	if not cutting:
		return false
	var cos_cone := cos(deg_to_rad(ALLEY_FRONT_CONE))
	for o in game.teams[1 - p.team]:
		var r: Vector2 = o.position - p.position
		var rd := r.length()
		if rd < ALLEY_FRONT_FT * FT and (rd < 0.1 or dir.dot(r / rd) >= cos_cone):
			return false
	return true

# The pass in flight is an alley-oop lob (the receiver will jump for it)
func is_lob() -> bool:
	return state == PASS and lob

# Seconds until a lob in flight reaches its receiver (0 if there is none)
func lob_time_left() -> float:
	return (1.0 - lob_t) * lob_time if is_lob() else 0.0

func throw_lob(from_p, to_p) -> void:
	lob = true
	lob_t = 0.0
	lob_start = position
	lob_takeoff_sent = false
	lob_time = clampf(position.distance_to(to_p.position) / LOB_SPEED, LOB_TIME_MIN, LOB_TIME_MAX)
	game.stat("alleyoops_t%d" % from_p.team)
	if game.is_human(from_p):
		game.stat("human_alleyoop_lobs")
	if game.is_human(to_p):
		game.stat("human_alleyoop_targets")
	if from_p.has_method("on_lob_thrown"):
		from_p.on_lob_thrown(to_p, lob_time)

func shoot(p, hoop: Vector2, made: bool, points: int) -> void:
	state = SHOT
	shooter = p
	holder = null
	shot_start = position
	shot_hoop = hoop
	shot_t = 0.0
	shot_kind = next_shot_kind
	next_shot_kind = ""
	shot_alley = next_alley and shot_kind == "dunk"
	next_alley = false
	shot_z0 = z if shot_kind != "" else 26.0
	var dist := position.distance_to(hoop)
	shot_time = 0.55 + dist / 900.0
	shot_peak = 40.0 + dist * 0.22
	if shot_kind == "dunk":
		shot_time = DUNK_FLIGHT
		shot_peak = 0.0
	elif shot_kind == "layup":
		shot_time = LAYUP_FLIGHT
		shot_peak = LAYUP_PEAK
	shot_made = made
	shot_points = points
	blocked_checked = false

# Who knocked it loose is judged from the state before (main.attempt_steal and main.block_shot call this while the
# handler still holds it or the shot is still in the air): a held ball or a shot came loose off a defender's hand.
# The rim-out below overrides it with the shooter's team.
func make_loose(from: Vector2, v: Vector2, height := 20.0, up := 150.0) -> void:
	if state == HELD and holder != null:
		last_touch_team = 1 - holder.team
		loose_cause = "block" if holder.rim_kind != "" else "steal"
	elif state == SHOT and shooter != null:
		last_touch_team = 1 - shooter.team
		loose_cause = "block"
	elif state == PASS and passer != null:
		last_touch_team = passer.team
		loose_cause = "pass"
	state = LOOSE
	holder = null
	receiver = null
	lob = false
	position = from
	vel = v
	z = height
	vz = up

func make_dead() -> void:
	state = DEAD
	holder = null
	receiver = null
	lob = false

func update(delta: float) -> void:
	anim_time += delta
	bounce_cooldown = maxf(0.0, bounce_cooldown - delta)
	match state:
		HELD:
			if holder == null:
				return
			var dir := Vector2.from_angle(holder.facing)
			# dribble hand (P2-05): off to the side of the body, crossing in front of it when switching hands
			var hx: float = holder.hand_x if "hand_x" in holder else 0.0
			var right := Vector2.from_angle(holder.facing + PI / 2.0)
			position = holder.position + dir * (HAND_FORWARD_PX + CROSS_FRONT_PX * (1.0 - hx * hx)) \
					+ right * HAND_SIDE_PX * hx
			if holder.rim_kind != "":
				z = holder.jump_z + HAND_Z  # carried up in the jump
			elif "fake_t" in holder and holder.fake_t > 0.0:
				z = 26.0 + holder.jump_z * PUMP_BALL_LIFT   # pump fake: ball up as if shooting, with the hop
			elif holder.shooting:
				z = 26.0
			else:
				z = 4.0 + abs(sin(anim_time * 9.0)) * 16.0
				_dribble_sound()
		PASS:
			if receiver == null:
				make_loose(position, Vector2.ZERO)
				return
			var to: Vector2 = receiver.position - position
			var step := PASS_SPEED * delta
			var lobbed := lob
			if lobbed:
				_update_lob(delta)   # its own catch and pick-off rules
			elif to.length() <= max(step, 16.0):
				hold(receiver)
				return
			else:
				position += to.normalized() * step
			# defenders near the passing lane may pick it off
			for p in ([] if lobbed else game.players):
				if p.team == passer.team or intercept_checked.has(p):
					continue
				if p.position.distance_to(position) < 20.0 and passer.position.distance_to(position) > 60.0:
					intercept_checked[p] = true
					if game.rng.randf() < 0.15:
						game.show_message("PICKED OFF!")
						game.stat("intercepts")
						hold(p)
						return
		SHOT:
			shot_t += delta / shot_time
			if shot_t >= 1.0:
				position = shot_hoop
				z = 0.0
				if shot_made:
					make_dead()
					_make_feedback()
					if shot_kind != "":
						game.stat(shot_kind + "_makes")
					if shot_kind == "dunk":
						slam_feedback()
					if shot_alley:
						game.stat("alleyoop_makes")
						if game.fx:
							game.fx.popup("ALLEY-OOP!", shot_hoop + Vector2(0, -100), ALLEY_POPUP_COLOR, 40)
					game.on_shot_made(shooter, shot_points)
				else:
					# rim out: bounce back toward the court
					var inward := 1.0 if shot_hoop.x < game.COURT_W / 2 else -1.0
					var ang: float = game.rng.randf_range(-1.2, 1.2)
					var v: Vector2 = Vector2(inward, 0).rotated(ang) * game.rng.randf_range(140.0, 280.0)
					var ft_miss: bool = game.rules != null and game.rules.ft_shot_live   # free throws: a soft miss
					if game.rng.randf() < RIM_LONG_CHANCE and not ft_miss:
						# off the back iron: long toward the baseline (P3-07: these are most baseline out-of-bounds)
						ang = game.rng.randf_range(-RIM_LONG_ANGLE, RIM_LONG_ANGLE)
						v = Vector2(-inward, 0).rotated(ang) * game.rng.randf_range(RIM_LONG_SPEED_MIN, RIM_LONG_SPEED_MAX)
						game.stat("rim_long")
					elif game.rng.randf() < RIM_WIDE_CHANCE and not ft_miss:
						ang = game.rng.randf_range(RIM_WIDE_ANGLE_MIN, RIM_WIDE_ANGLE_MAX) * (1.0 if game.rng.randf() < 0.5 else -1.0)
						v = Vector2(inward, 0).rotated(ang) * game.rng.randf_range(RIM_WIDE_SPEED_MIN, RIM_WIDE_SPEED_MAX)
						game.stat("rim_wide")
					make_loose(shot_hoop + v.normalized() * 10.0, v, 30.0, 220.0)
					if shooter != null:
						last_touch_team = shooter.team   # off the rim: the shooter's team touched it last
					loose_cause = "rebound"
					_rim_feedback()
					game.on_shot_missed(shooter)
				return
			position = shot_start.lerp(shot_hoop, shot_t)
			z = shot_z0 * (1.0 - shot_t) + 4.0 * shot_peak * shot_t * (1.0 - shot_t)
		LOOSE:
			position += vel * delta
			vel *= pow(0.35, delta)
			vz -= GRAVITY * delta
			z += vz * delta
			if z <= 0.0:
				z = 0.0
				_bounce_sound(abs(vz))
				vz = abs(vz) * 0.55
				if vz < 40.0:
					vz = 0.0
			# out of bounds (P3-07): rules.ball_out makes it dead and gives it to the other team
			if _went_out():
				return
			# bounce off the edges of the court (only when rules.gd can't call it out)
			if position.x < 0 or position.x > game.COURT_W:
				vel.x = -vel.x
				position.x = clamp(position.x, 0.0, game.COURT_W)
			if position.y < 0 or position.y > game.COURT_H:
				vel.y = -vel.y
				position.y = clamp(position.y, 0.0, game.COURT_H)
			if z < 30.0:
				var best = null
				var best_d := 20.0
				for p in game.players:
					var d: float = p.position.distance_to(position)
					if d < best_d:
						best_d = d
						best = p
				if best != null:
					hold(best)
		DEAD:
			z = max(0.0, z - 60.0 * delta)
	sprite.position = Vector2(0, -z)
	var s := 1.1 + z / 160.0
	sprite.scale = Vector2(s, s)
	queue_redraw()

# A loose ball past a sideline or baseline: tell the rules. True if it was called out (the ball is dead now).
func _went_out() -> bool:
	var W: float = game.COURT_W
	var H: float = game.COURT_H
	var m := OOB_MARGIN_PX
	if position.x >= -m and position.x <= W + m and position.y >= -m and position.y <= H + m:
		return false
	if game.rules == null or not game.rules.has_method("ball_out"):
		return false
	if not game.rules.ball_out(position, last_touch_team):
		return false
	sprite.position = Vector2(0, -z)
	queue_redraw()
	return true

# The lob's flight: a high, slow arc that homes on the receiver. Only the first LOB_PICK_FRAC can be picked off.
# Near the end the receiver is told to take off (player.start_alley_dunk) so he catches it in the air.
func _update_lob(delta: float) -> void:
	lob_t = minf(1.0, lob_t + delta / lob_time)
	var aim: Vector2 = receiver.position
	position = lob_start.lerp(aim, lob_t)
	var end_z: float = LOB_CATCH_Z if receiver.is_airborne() else 26.0
	z = 18.0 * (1.0 - lob_t) + end_z * lob_t + 4.0 * LOB_PEAK * lob_t * (1.0 - lob_t)
	if not lob_takeoff_sent and receiver.has_method("alley_takeoff_lead") \
			and lob_time_left() <= receiver.alley_takeoff_lead():
		lob_takeoff_sent = true
		receiver.start_alley_dunk()
	if lob_t >= 1.0:
		var r = receiver
		var in_air: bool = r.has_method("is_alley_jumping") and r.is_alley_jumping()
		if in_air:
			game.stat("alleyoop_catches")
			if game.is_human(r):
				game.stat("human_alleyoop_catches")
		else:
			game.stat("alleyoop_floor_catches")   # he wasn't near enough the rim to go up for it
		hold(r)
		return
	if lob_t < LOB_PICK_FRAC:
		for p in game.players:
			if p.team == passer.team or intercept_checked.has(p):
				continue
			if p.position.distance_to(position) < 20.0 and passer.position.distance_to(position) > 60.0:
				intercept_checked[p] = true
				if game.rng.randf() < 0.15:
					game.show_message("PICKED OFF!")
					game.stat("intercepts")
					game.stat("alleyoop_picks")
					hold(p)
					return

func _hoop_index() -> int:
	return 0 if shot_hoop.x < game.COURT_W / 2 else 1

func _make_feedback() -> void:
	# made basket: net swish for every make; the swish sound only for jump shots and layups (dunks have their own)
	if game.rims:
		game.rims.swish(_hoop_index(), DUNK_NET if shot_kind == "dunk" else 1.0)
	if game.audio and shot_kind != "dunk":
		game.audio.play("swish", LAYUP_SWISH_DB if shot_kind == "layup" else 0.0)

func _rim_feedback() -> void:
	# missed shot off the rim: clank plus a small net wiggle
	if game.rims:
		game.rims.swish(_hoop_index(), RIM_WIGGLE)
	if game.audio:
		game.audio.play("rim", RIM_DB, 0.08)
	bounce_cooldown = BOUNCE_GAP

func _bounce_sound(impact: float) -> void:
	if impact < BOUNCE_MIN_SPEED or bounce_cooldown > 0.0 or not game.audio:
		return
	bounce_cooldown = BOUNCE_GAP
	var k := clampf((impact - BOUNCE_MIN_SPEED) / (BOUNCE_LOUD_SPEED - BOUNCE_MIN_SPEED), 0.0, 1.0)
	game.audio.play("bounce", lerpf(BOUNCE_QUIET_DB, 0.0, k), 0.08)

func _dribble_sound() -> void:
	# soft dribble, only for the ball handler the human controls, on every DRIBBLE_EVERY-th floor touch
	var phase := int(anim_time * 9.0 / PI)
	if phase == dribble_phase:
		return
	dribble_phase = phase
	if not game.is_human(holder) or not game.audio:
		return
	dribble_count += 1
	if dribble_count % DRIBBLE_EVERY == 0:
		game.stat("dribble_sounds")
		game.audio.play("bounce", DRIBBLE_DB, 0.1)

func slam_feedback() -> void:
	if game.fx:
		game.fx.popup("SLAM!", shot_hoop + Vector2(0, -56), SLAM_COLOR, 48)
		game.fx.shake(8.0, 0.35)
	if game.audio:
		game.audio.play("dunk")

func _draw() -> void:
	# shadow on the floor
	var r := 7.0 - minf(z, 60.0) / 20.0
	draw_set_transform(Vector2(0, 3), 0, Vector2(1, 0.55))
	draw_circle(Vector2.ZERO, max(r, 3.0), Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
