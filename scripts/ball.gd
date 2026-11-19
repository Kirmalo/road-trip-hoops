extends Node2D
# The basketball. position = spot on the floor; z = height above the floor (drawn as an upward offset).
# FLAT draws with `sprite` and _draw() here; ANGLED draws with the view nodes at the end of the file (P4-10).

const View = preload("res://scripts/view.gd")   # projection (Phase 4)
const Sheets = preload("res://scripts/sheets.gd")   # v2 player sheets: hand and ball points (drawing only)
const Twists = preload("res://scripts/twists.gd")   # Phase 6 city twists: wind drift, thin air, the cage's fence
const Cosmetics = preload("res://scripts/cosmetics.gd")   # P8-10: the picked ball (ball_sheet(); the default without a pick)

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
var _dribble_half := 0     # which half-cycle of the dribble the ball is in; a change means a floor touch
var lob := false           # the current PASS is an alley-oop lob (P2-09)
var lob_t := 0.0           # 0..1 along the lob's flight
var lob_time := 0.6        # seconds of the lob's flight
var lob_start := Vector2.ZERO
var lob_takeoff_sent := false
var next_alley := false    # set by the alley-oop dunker just before release (like next_shot_kind)
var shot_alley := false    # the shot in flight is an alley-oop dunk
var last_touch_team := -1  # team that touched the ball last (P3-07): the other team gets it if it goes out
var loose_cause := ""      # why the ball is loose: "steal", "block", "rebound", "pass" (out-of-bounds stats)
var lob_drift := Vector2.ZERO   # wind (P6-04): where the lob lands, off its receiver (sim px), set at the throw
var shot_curve := Vector2.ZERO  # wind (P6-04): how far a long jump shot bows downwind mid-flight (drawn only)
var outlet := false        # P9-20: the current PASS is an outlet (faster, harder to pick off)

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
const DRIBBLE_RATE := 9.0       # the sim's dribble: z = 4 + |sin(anim_time x this)| x 16 (one bounce per PI / 9 s;
                                # steal timing reads it, so don't change it; the animation follows it, dribble_phase())

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
const LOB_REACH_FT := 1.9         # wind: a lob blown further than this off its receiver is out of his reach (loose).
                                  # The drift is 1-2 ft (half to full gust), so only the strongest gusts beat him
const LOB_BLOWN_SPEED := 70.0     # px/s downwind a lob he can't reach keeps as a loose ball
const FENCE_SFX := "fence"        # cage (P6-04): the rattle when a loose ball hits the sideline fence (silent if missing)

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
# P9-20 outlet (Quarterback): a pass of player.OUTLET_MIN_FT or more by a passer whose signature is "outlet"
const OUTLET_SPEED_MULT := 1.35   # flies this much faster than PASS_SPEED (a full-court strike)
const OUTLET_PICK_MULT := 0.35    # interception chance x this along its way (thrown over the defense)
const GRAVITY := 900.0

func setup(g) -> void:
	game = g
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/ball.png")
	sprite.scale = Vector2(1.1, 1.1)
	add_child(sprite)
	z_index = 20
	if View.angled():
		_build_view()

func hold(p) -> void:
	if outlet and state == PASS and p == receiver and passer != null and passer.has_method("sig_log"):
		game.stat("sig_outlet_catches_t%d" % p.team)
		passer.sig_log("outlet", "outlet caught by %s %.0f ft from the rim" % [p.pname if p.pname != "" else p.pid,
				p.position.distance_to(game.attack_hoop(p.team)) / game.FT])
	outlet = false
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
	outlet = false
	if make_lob and to_p != null:
		throw_lob(from_p, to_p)
	elif to_p != null and from_p != null and "signature" in from_p and from_p.signature == from_p.SIG_OUTLET \
			and from_p.position.distance_to(to_p.position) >= from_p.OUTLET_MIN_FT * game.FT:
		outlet = true   # P9-20: the long outlet pass
		from_p.sig_log(from_p.SIG_OUTLET, "outlet pass %.0f ft to %s" % [from_p.position.distance_to(to_p.position) / game.FT,
				to_p.pname if to_p.pname != "" else to_p.pid])

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
	# thin air: the lob hangs longer (receivers, CPU lob readers and the take-off all use lob_time)
	var time_mult: float = Twists.value("lob_time_mult", 1.0)
	if time_mult != 1.0:
		lob_time *= time_mult
		game.stat("%s_lobs" % Twists.current)
	# wind: it lands downwind of the receiver, more in a strong gust
	lob_drift = Twists.wind * Twists.value("lob_drift_ft", 0.0) * game.FT
	if lob_drift != Vector2.ZERO:
		game.stat("wind_lobs")
		game.stat_add("wind_drift_px", int(lob_drift.length()))
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
	# wind: a jump shot beyond the arc bows downwind in the air (drawn only; the make was rolled in main.shot_probability)
	shot_curve = Vector2.ZERO
	var free_throw: bool = game.rules != null and game.rules.ft_shot_live
	if shot_kind == "" and not free_throw and Twists.wind != Vector2.ZERO and game.is_three(p.position, hoop):
		shot_curve = Twists.wind * Twists.value("shot_curve_ft", 0.0) * game.FT
		if shot_curve != Vector2.ZERO:
			game.stat("wind_curved_shots")
			game.stat_add("wind_curve_px", int(shot_curve.length()))

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
	outlet = false
	position = from
	vel = v
	z = height
	vz = up

func make_dead() -> void:
	state = DEAD
	holder = null
	receiver = null
	lob = false
	outlet = false

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
				z = 4.0 + abs(sin(anim_time * DRIBBLE_RATE)) * 16.0
				_dribble_sound()
		PASS:
			if receiver == null:
				make_loose(position, Vector2.ZERO)
				return
			var to: Vector2 = receiver.position - position
			var step := PASS_SPEED * delta * (OUTLET_SPEED_MULT if outlet else 1.0)
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
					if game.rng.randf() < 0.15 * (OUTLET_PICK_MULT if outlet else 1.0):
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
	# the cage (owner Q2 a): past a sideline (further past it than past a baseline, as rules.ball_out judges the line)
	# the ball hits the fence and comes back into play. Baselines are out as always.
	if Twists.flag("sideline_fence") and maxf(-position.y, position.y - H) > maxf(-position.x, position.x - W):
		_fence_bounce()
		return false
	if game.rules == null or not game.rules.has_method("ball_out"):
		return false
	if not game.rules.ball_out(position, last_touch_team):
		return false
	if game.has_method("rebound_out"):
		game.rebound_out()   # rebound stats: a missed shot's ball went out
	sprite.position = Vector2(0, -z)
	queue_redraw()
	return true

# Cage: a loose ball off the sideline fence. It comes back in with fence_bounce of its speed, plus the rattle.
func _fence_bounce() -> void:
	var keep: float = Twists.value("fence_bounce", 0.6)
	position.y = clampf(position.y, 0.0, game.COURT_H)
	vel = Vector2(vel.x, -vel.y) * keep
	game.stat("fence_bounces")
	_fence_t = 0.0
	if game.audio:
		game.audio.play(FENCE_SFX, 0.0, 0.1)

# The lob's flight: a high, slow arc that homes on the receiver. Only the first LOB_PICK_FRAC can be picked off.
# Near the end the receiver is told to take off (player.start_alley_dunk) so he catches it in the air.
func _update_lob(delta: float) -> void:
	lob_t = minf(1.0, lob_t + delta / lob_time)
	var aim: Vector2 = receiver.position + lob_drift   # wind: it drifts off the receiver as it flies (else + zero)
	position = lob_start.lerp(aim, lob_t)
	var end_z: float = LOB_CATCH_Z if receiver.is_airborne() else 26.0
	z = 18.0 * (1.0 - lob_t) + end_z * lob_t + 4.0 * LOB_PEAK * lob_t * (1.0 - lob_t)
	if not lob_takeoff_sent and receiver.has_method("alley_takeoff_lead") \
			and lob_time_left() <= receiver.alley_takeoff_lead():
		lob_takeoff_sent = true
		receiver.start_alley_dunk()
	if lob_t >= 1.0:
		var r = receiver
		if lob_drift.length() > LOB_REACH_FT * game.FT:
			# wind: blown out of his reach. It drops loose by him, the closest player picks it up
			game.stat("wind_lob_drops")
			make_loose(position, lob_drift.normalized() * LOB_BLOWN_SPEED, z, 0.0)
			return
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

# Where the sim's dribble is (read-only, P6-22): 0 = in the hand at the top of the bounce, 0.5 = on the floor, back to
# 1 at the top. The players' dribble animations lock to it (player.gd _v2_phase_x).
func dribble_phase() -> float:
	return fposmod(anim_time * DRIBBLE_RATE / PI - 0.5, 1.0)

func _dribble_sound() -> void:
	# soft dribble, only for the ball handler the human controls, on every DRIBBLE_EVERY-th floor touch
	var phase := int(anim_time * DRIBBLE_RATE / PI)
	if phase == _dribble_half:
		return
	_dribble_half = phase
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
	if _v_node != null:
		return   # ANGLED: the shadow is drawn in game.decals (see the end of the file)
	# shadow on the floor
	var r := 7.0 - minf(z, 60.0) / 20.0
	draw_set_transform(Vector2(0, 3), 0, Vector2(1, 0.55))
	draw_circle(Vector2.ZERO, max(r, 3.0), Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# ---------------- drawing in the 3/4 view (P4-10, ANGLED only; FLAT draws with `sprite` and _draw() above) ----------------
# Visual only: reads the sim state (state, position, z, shot_t, lob_t, the holder's view sprite) and never writes it.
# Two nodes: the ball in game.world (y-sorted: its position.y is the sort y, normally the projected floor point) and
# its shadow in game.decals. Heights follow the board's "Heights": the held ball sits in the hand drawn by the
# player's sheet (Sheets.hand: assets/players2/hands.json, or a v1 sheet's), a shot rises to View.RIM_Z at the hoop,
# a rim rebound or a block falls from where it was drawn, a make drops through the net. Every change of state blends from the drawn spot.

const BALL_SHEET := "res://assets/ball/ball.png"   # P4-08: 4 spin frames of 16 x 16 (Kenney ball.png if missing)
# P8-10: the picked ball (a star reward, Cosmetics.ball_sheet(), every game) is drawn instead; a missing file or one
# of the wrong size falls back to BALL_SHEET, then the Kenney ball
const BALL_FRAMES := 4
const BALL_VIEW_SCALE := 2.0      # the sheet is drawn at 2x (like the players)
const BALL_FALLBACK_SCALE := 1.1  # the Kenney ball, as in FLAT
const BALL_VIEW_R := 12.0         # drawn radius in screen pixels at 2x (12 px of ball in a 16 px frame)
const SHEET_COLS := 37            # v1 player sheet layout (board contract; its hands come from Sheets.hand)
const SHEET_W := 40.0
const SHEET_FEET_Y := 59.0
# drawn heights of the ball's center above the floor (sim pixels of height, through View.to_screen)
const CATCH_VIEW_Z := 40.0        # a pass arrives at chest height
const REACH_VIEW_Z := 86.0        # hands over the head (a lob caught in the air, a shot without hand data)
const DRIBBLE_VIEW_Z := 34.0      # the dribbling hand without hand data
const SHOT_VIEW_ARC := 1.0        # the jump shot's arc above the straight line, x the sim's shot_peak
const LOB_VIEW_ARC := 1.6         # the lob's arc, x LOB_PEAK (so it reads clearly as a lob)
const RIM_END_Z := 6.0            # the shot arrives this far above the rim (then drops through the net)
const DRIBBLE_FLOOR_DY := 4.0     # the dribble hits the floor this many screen px in front of the feet
const HELD_ON_HAND := 0.6         # held up (shot, dunk): the ball's center this many radii above the hand
const DRIBBLE_UNDER_HAND := 0.7   # dribble: the ball's center this many radii under the hand at the top
const BLEND_RATE := 22.0          # per second: how fast the drawn ball catches up after a change of state
const VIEW_GRAVITY := 1400.0      # a dead ball (after a make, out of bounds) falls and bounces with this
const VIEW_BOUNCE := 0.45         # ... keeping this much of its speed per bounce
# sorting against the hoop (board "Hoops"): near the rim in the air the ball sorts at exactly hoop_sort_y(i),
# behind the front of the rim and the net, in front of the backboard
const BALL_RIM_SORT_FT := 3.0
const RIM_SORT_BELOW := 34.0      # "in the air": the ball's center no more than this under the rim (the net is ~2 ft)
# shadow (screen pixels; an ellipse flattened like the court)
const SHADOW_R := 10.0            # on the floor
const SHADOW_MIN := 0.4           # x SHADOW_R at the rim and above
const SHADOW_ALPHA := 0.35
# spin: one frame per this many screen pixels the ball moves; shots also spin back
const SPIN_PX_PER_FRAME := 7.0
const SHOT_SPIN_FPS := 14.0
# floor dust when a loose or dead ball hits the floor hard (drawn by fx in game.decals)
const DUST_MIN_SPEED := 160.0     # px/s down
# v2 sheets (P6-22): the held ball sits on the frame's own ball point (hands.json "ball"); passes get a look
const BOUNCE_PASS_AT := 0.6       # a bounce pass hits the floor this far along its way (drawn only)
const BOUNCE_MIN_FT := 6.0        # a bounce pass is between these lengths ...
const BOUNCE_MAX_FT := 26.0
const BOUNCE_SHORT_FT := 8.0      # ... and either this short ...
const BOUNCE_LANE_FT := 3.0       # ... or with a defender this close to the middle of the passing lane
const BOUNCE_LANE_FROM := 0.2     # "the middle": between these fractions of the way
const BOUNCE_LANE_TO := 0.8

var _pass_look := ""              # the pass in flight looks like: "chest", "bounce" or "lob" ("" = not picked yet)
var _v_front := true              # v2: the held ball is drawn in front of the holder (hands.json "ball" front flag)
var _v_holder_anim := ""          # v2: the holder's animation last frame (a change blends the drawn ball over)

var v_screen := Vector2.ZERO      # where the ball is drawn (screen): fx's fire trail follows it
var v_sort_y := 0.0               # its sort y in game.world
var _v_node: Node2D               # game.world
var _v_spr: Sprite2D
var _v_shadow: Node2D             # game.decals
var _v_sheet := false
var _v_h := 0.0                   # drawn height of the center (sim px of height) above `position`'s floor point
var _v_floor := Vector2.ZERO      # screen point on the floor under the drawn ball
var _v_key := ""                  # state + holder: a change starts a blend
var _v_t := 0.0                   # seconds in the current state
var _v_h0 := 0.0                  # drawn height when the state began
var _v_from := Vector2.ZERO       # floor point where a pass began
var _v_extra := 0.0               # loose: drawn height above the sim's z, fading out by the first floor touch
var _v_extra_time := 0.0
var _v_vz := 0.0                  # dead ball: drawn fall speed
var _v_off := Vector2.ZERO        # screen offset still being blended out
var _v_spin := 0.0
var _v_prev_z := 0.0
var _v_ready := false

func _build_view() -> void:
	sprite.visible = false
	process_priority = 10          # after the players' views, so the ball sits in this frame's hand
	_v_node = Node2D.new()
	_v_node.name = "BallView"
	_v_spr = Sprite2D.new()
	for path in [Cosmetics.ball_sheet(), BALL_SHEET]:
		var tex: Texture2D = load(str(path)) as Texture2D if ResourceLoader.exists(str(path)) else null
		if tex != null and tex.get_width() == tex.get_height() * BALL_FRAMES:
			_v_spr.texture = tex
			_v_sheet = true
			_v_spr.hframes = BALL_FRAMES
			break
	if not _v_sheet:
		_v_spr.texture = sprite.texture
	_v_node.add_child(_v_spr)
	game.world.add_child(_v_node)
	_v_shadow = Node2D.new()
	_v_shadow.name = "BallShadow"
	_v_shadow.draw.connect(_draw_view_shadow)
	game.decals.add_child(_v_shadow)

func _process(delta: float) -> void:
	if _v_node != null:
		_update_view(delta)

func _view_lift_of(p) -> float:
	if p == null:
		return 0.0
	if p.has_method("_view_lift"):
		return p._view_lift()
	return p.jump_z

# v2: the player draws a v2 sheet (pages, format.json)
func _is_v2(p) -> bool:
	return p != null and ("_v_ver" in p) and int(p._v_ver) == 2 and p._v_spr != null

# a point in the player's drawn frame (frame pixels, already mirrored) -> screen
func _frame_to_screen(p, pt: Vector2) -> Vector2:
	var spr: Sprite2D = p._v_spr
	var fmt: Dictionary = p._v_fmt
	var local: Vector2 = (pt - Vector2(Sheets.center_x(fmt), Sheets.feet_y(fmt))) * spr.scale
	return p._v_body.position + spr.position + local.rotated(spr.rotation)

# v2: the ball point of the holder's drawn frame, blended toward the next frame by how far into this one he is
# (the dribble is phase-locked, so the ball meets the floor on the floor frame). {"pos": screen, "front": bool} or {}.
func _v2_ball(p) -> Dictionary:
	var fmt: Dictionary = p._v_fmt
	var a: Dictionary = Sheets.hand(fmt, p._v_sheet_id, p.v_frame, p.v_flip)
	if not a.has("ball"):
		return {}
	var pt: Vector2 = a["ball"]
	if p.v_frame_frac > 0.0 and p.v_next_frame != p.v_frame:
		var b: Dictionary = Sheets.hand(fmt, p._v_sheet_id, p.v_next_frame, p.v_flip)
		if b.has("ball"):
			pt = pt.lerp(b["ball"], p.v_frame_frac)
	return {"pos": _frame_to_screen(p, pt), "front": bool(a.get("ball_front", true))}

# how much taller than a v1 player p is drawn (catch and reach heights scale with it; 1.0 on v1)
func _head_k(p) -> float:
	if p != null and p.has_method("view_head_scale"):
		return p.view_head_scale()
	return 1.0

# What the pass in flight looks like (drawing only; the sim's pass is the same): "lob" (ball.lob), "bounce" (a v2
# passer, a pass of BOUNCE_MIN_FT..BOUNCE_MAX_FT that is short or has a defender in the middle of the lane) or
# "chest". "" when no pass is in flight. player.gd plays the matching throw; the drawn ball bounces once.
func pass_look() -> String:
	if state != PASS:
		return ""
	if lob:
		return "lob"
	if _pass_look != "":
		return _pass_look
	_pass_look = "chest"
	if not _is_v2(passer) or receiver == null:
		return _pass_look
	var a: Vector2 = passer.position
	var b: Vector2 = receiver.position
	var FT: float = game.FT
	var d_ft: float = a.distance_to(b) / FT
	if d_ft < BOUNCE_MIN_FT or d_ft > BOUNCE_MAX_FT:
		return _pass_look
	if d_ft <= BOUNCE_SHORT_FT:
		_pass_look = "bounce"
		return _pass_look
	for o in game.teams[1 - passer.team]:
		var t: float = clampf((o.position - a).dot(b - a) / maxf(a.distance_squared_to(b), 1.0), 0.0, 1.0)
		if t >= BOUNCE_LANE_FROM and t <= BOUNCE_LANE_TO and o.position.distance_to(a.lerp(b, t)) < BOUNCE_LANE_FT * FT:
			_pass_look = "bounce"
			break
	return _pass_look

# the screen point of the holder's hand from his sheet frame and hands.json (null without data)
func _hand_point(p, kind: String):
	if _is_v2(p):
		# v2 without a ball point in this frame: the hands of the frame (Sheets.hand, already mirrored)
		var hd: Dictionary = Sheets.hand(p._v_fmt, p._v_sheet_id, p.v_frame, p.v_flip)
		if hd.is_empty():
			return null
		var hl: Vector2 = hd["L"]
		var hr: Vector2 = hd["R"]
		var g: Vector2 = (hl + hr) / 2.0
		if kind == "dribble":
			g = hl if hl.y > hr.y else hr           # the lower hand
		elif kind == "up":
			g = hl if hl.y < hr.y else hr           # the higher hand
		return _frame_to_screen(p, g)
	# a v1 sheet (none ship since P6-25; the reader stays): its hands.json points through Sheets (null without data,
	# then the held ball uses the heights above; the Kenney fallback has no sheet id)
	if p == null or not ("_v_sheet" in p) or not p._v_sheet or p._v_spr == null or str(p._v_sheet_id) == "":
		return null
	var spr: Sprite2D = p._v_spr
	var hd1: Dictionary = Sheets.hand(Sheets.v1_format(), str(p._v_sheet_id), spr.frame, spr.flip_h)   # flip: L/R swap
	if hd1.is_empty():
		return null
	var l: Vector2 = hd1["L"]
	var r: Vector2 = hd1["R"]
	var f: Vector2
	if kind == "dribble":
		# the sheet dribbles with its right hand; mirrored (a left-hand dribble facing or backing the camera) it is L
		f = l if spr.flip_h else r
	elif kind == "up":
		f = l if l.y < r.y else r              # the higher hand (shot, dunk, pump fake)
	else:
		f = (l + r) / 2.0                       # both hands (holding it at the line, stumbling)
	var local: Vector2 = (f - Vector2(SHEET_W / 2.0, SHEET_FEET_Y)) * spr.scale
	return p._v_body.position + spr.position + local.rotated(spr.rotation)

# where the ball is drawn this frame (before the blend); sets its drawn height and the floor point under it
func _view_target(delta: float) -> Vector2:
	var fl: Vector2 = View.to_screen(position, 0.0)
	var k: float = View.HEIGHT_SCALE * View.size_at(position)
	var r: float = BALL_VIEW_R * View.size_at(position)
	_v_floor = fl
	match state:
		HELD:
			if holder != null:
				var base: Vector2 = View.to_screen(holder.position, 0.0)
				if _is_v2(holder):
					# v2: the ball point of the drawn frame (every held-ball frame has one)
					var vb: Dictionary = _v2_ball(holder)
					if not vb.is_empty():
						var s2: Vector2 = vb["pos"]
						_v_front = vb["front"]
						_v_floor = Vector2(s2.x, base.y + DRIBBLE_FLOOR_DY)
						_v_h = (fl.y - s2.y) / k
						return s2
					_v_front = true
				var anim: String = holder._v_anim if "_v_anim" in holder else ""
				var up: bool = holder.rim_kind != "" or holder.shooting or holder.fake_t > 0.0
				var dribble: bool = not up and not holder.at_free_throw() and (anim == "dribble" or anim == "")
				var frac: float = clampf((z - 4.0) / 16.0, 0.0, 1.0)
				var hp = _hand_point(holder, "up" if up else ("dribble" if dribble else "both"))
				if hp != null:
					var hand: Vector2 = hp
					var s: Vector2 = hand
					if dribble:
						var top: float = hand.y + r * DRIBBLE_UNDER_HAND
						var bottom: float = base.y + DRIBBLE_FLOOR_DY * View.size_at(holder.position) - r
						s = Vector2(hand.x, lerpf(bottom, top, frac))
					elif up:
						s = hand + Vector2(0, -r * HELD_ON_HAND)
					_v_floor = Vector2(hand.x, base.y + DRIBBLE_FLOOR_DY)
					_v_h = (fl.y - s.y) / k
					return s
				# no hand data: the sim's spot at a drawn height (scaled for a taller v2 player)
				var hk: float = _head_k(holder)
				if up:
					_v_h = _view_lift_of(holder) + REACH_VIEW_Z * hk
				elif dribble:
					_v_h = r / k + (DRIBBLE_VIEW_Z * hk - r / k) * frac
				else:
					_v_h = CATCH_VIEW_Z * hk
		PASS:
			if receiver != null:
				var to_end: float = position.distance_to(receiver.position)
				var done: float = position.distance_to(_v_from)
				var end_h: float = _view_lift_of(receiver) + (REACH_VIEW_Z if receiver.is_airborne() else CATCH_VIEW_Z) \
						* _head_k(receiver)
				if lob:
					var lob_arc: float = LOB_VIEW_ARC * Twists.value("arc_mult", 1.0)   # thin air: drawn higher
					_v_h = lerpf(_v_h0, end_h, lob_t) + 4.0 * LOB_PEAK * lob_arc * lob_t * (1.0 - lob_t)
				elif pass_look() == "bounce":
					# a bounce pass: down to the floor at BOUNCE_PASS_AT of the way, then up into his hands
					var u: float = done / maxf(done + to_end, 1.0)
					var low: float = r / k
					if u < BOUNCE_PASS_AT:
						_v_h = lerpf(_v_h0, low, u / BOUNCE_PASS_AT)
					else:
						_v_h = lerpf(low, end_h, (u - BOUNCE_PASS_AT) / (1.0 - BOUNCE_PASS_AT))
				else:
					_v_h = lerpf(_v_h0, end_h, done / maxf(done + to_end, 1.0))
		SHOT:
			var t: float = clampf(shot_t, 0.0, 1.0)
			var arc: float = SHOT_VIEW_ARC * Twists.value("arc_mult", 1.0)   # thin air: drawn higher
			_v_h = lerpf(_v_h0, View.RIM_Z + RIM_END_Z, t) + 4.0 * shot_peak * arc * t * (1.0 - t)
			if shot_curve != Vector2.ZERO:
				# wind: the drawn path bows downwind and comes back onto the rim
				var bow: Vector2 = position + shot_curve * 4.0 * t * (1.0 - t)
				_v_floor = View.to_screen(bow, 0.0)
				return View.to_screen(bow, _v_h)
		LOOSE:
			var fade: float = maxf(0.0, 1.0 - _v_t / maxf(_v_extra_time, 0.01))
			_v_h = r / k + z + _v_extra * fade
		DEAD:
			_v_vz -= VIEW_GRAVITY * delta
			_v_h += _v_vz * delta
			var lowest: float = r / k
			if _v_h <= lowest:
				_v_h = lowest
				if _v_vz < -DUST_MIN_SPEED and game.fx != null and game.fx.has_method("dust"):
					game.fx.dust(position, clampf(-_v_vz / 600.0, 0.3, 1.0))
				_v_vz = -_v_vz * VIEW_BOUNCE
				if _v_vz < 60.0:
					_v_vz = 0.0
	return View.to_screen(position, _v_h)

func _update_view(delta: float) -> void:
	var key := "%d:%d" % [state, holder.get_instance_id() if holder != null else 0]
	var changed := key != _v_key
	if changed:
		var last_h: float = _v_h
		_v_key = key
		_v_t = 0.0
		_v_h0 = last_h
		_v_from = position
		_v_vz = 0.0
		if state == LOOSE:
			# fall from where it was drawn onto the sim's own bounce, fading out by its first floor touch
			var rr: float = BALL_VIEW_R * View.size_at(position) / View.HEIGHT_SCALE
			_v_extra = last_h - (z + rr)
			_v_extra_time = (vz + sqrt(maxf(0.0, vz * vz + 2.0 * GRAVITY * z))) / GRAVITY
	else:
		_v_t += delta
	if state != PASS:
		_pass_look = ""
	var target: Vector2 = _view_target(delta)
	if changed and _v_ready:
		_v_off = v_screen - target
	# v2: a new animation in the holder's hands (say the end of a crossover into the dribble) blends over too
	var v2_anim: String = String(holder._v_anim) if state == HELD and _is_v2(holder) else ""
	if v2_anim != _v_holder_anim and v2_anim != "" and _v_holder_anim != "" and not changed and _v_ready:
		_v_off = v_screen - target
	_v_holder_anim = v2_anim
	_v_ready = true
	_v_off *= exp(-BLEND_RATE * delta)
	if _v_off.length() < 0.25:
		_v_off = Vector2.ZERO
	var s: Vector2 = target + _v_off
	# a loose ball hitting the floor hard: a dust puff (fx draws it in ANGLED only)
	if state == LOOSE and z <= 0.0 and _v_prev_z > 0.5 and game.fx != null and game.fx.has_method("dust"):
		var spd: float = _v_prev_z / maxf(delta, 0.001)
		if spd > DUST_MIN_SPEED:
			game.fx.dust(position, clampf(spd / 600.0, 0.3, 1.0))
	_v_prev_z = z
	# spin by how fast it moves on screen (and backspin on shots)
	var moved: Vector2 = s - v_screen
	var dir: float = -1.0 if moved.x < 0.0 else 1.0
	if moved.length() < 40.0:
		_v_spin += dir * moved.length() / SPIN_PX_PER_FRAME
	if state == SHOT:
		_v_spin -= dir * SHOT_SPIN_FPS * delta
	v_screen = s
	# sort: the projected floor point; held, by the holder (in front, behind when his back is to the camera);
	# near the rim in the air, exactly the hoop's sort y
	v_sort_y = View.to_screen(position, 0.0).y
	if state == HELD and holder != null and _is_v2(holder):
		v_sort_y = View.to_screen(holder.position, 0.0).y + (0.5 if _v_front else -0.5)   # the frame says in front or not
	elif state == HELD and holder != null:
		var row := 0
		if "_v_sheet" in holder and holder._v_sheet:
			row = int(holder._v_spr.frame) / SHEET_COLS
		v_sort_y = View.to_screen(holder.position, 0.0).y + (-0.5 if row == 4 else 0.5)
	else:
		var hi := _rim_hoop()
		if hi >= 0:
			v_sort_y = _hoop_sort_y(hi)
	_v_node.position = Vector2(s.x, v_sort_y)
	_v_spr.position = s - _v_node.position
	var sc: float = View.size_at(position)
	if _v_sheet:
		_v_spr.scale = Vector2(BALL_VIEW_SCALE, BALL_VIEW_SCALE) * sc
		_v_spr.frame = posmod(int(floor(_v_spin)), BALL_FRAMES)
	else:
		_v_spr.scale = Vector2(BALL_FALLBACK_SCALE, BALL_FALLBACK_SCALE) * sc
		_v_spr.rotation = _v_spin * TAU / 8.0
	_v_shadow.queue_redraw()
	_ball_shots()

# the hoop whose rim the ball is at (in the air, within BALL_RIM_SORT_FT of it), or -1
func _rim_hoop() -> int:
	if state == HELD or _v_h < View.RIM_Z - RIM_SORT_BELOW:
		return -1
	for i in 2:
		var h: Vector2 = game.hoops[i]
		if position.distance_to(h) < BALL_RIM_SORT_FT * game.FT:
			return i
	return -1

func _hoop_sort_y(i: int) -> float:
	if game.rims != null and game.rims.has_method("hoop_sort_y"):
		return game.rims.hoop_sort_y(i)
	return View.to_screen(game.hoops[i], 0.0).y   # before P4-07: the hoop's projected floor point

func _draw_view_shadow() -> void:
	var sc: float = View.size_at(position)
	var lowest: float = BALL_VIEW_R * sc / View.HEIGHT_SCALE
	var k: float = clampf((_v_h - lowest) / View.RIM_Z, 0.0, 1.0)
	var rx: float = SHADOW_R * sc * lerpf(1.0, SHADOW_MIN, k)
	var c: Vector2 = Vector2(v_screen.x, _v_floor.y) if state == HELD else _v_floor + Vector2(_v_off.x, 0.0)
	_v_shadow.draw_set_transform(c, 0.0, Vector2(1.0, View.TILT_Y))
	_v_shadow.draw_circle(Vector2.ZERO, rx, Color(0, 0, 0, SHADOW_ALPHA * lerpf(1.0, 0.6, k)))
	_v_shadow.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# test only (-- --ballshots, with xvfb and --view angled): screenshots of the ball to /tmp/hoops_ball_*.png:
# a dribble, a lob in flight, a shot at the rim (made / missed), a dunk, a loose ball and a popup. Quits when done.
var _bs_done := {}
var _bs_on := -1
var _bs_dir := "/tmp"   # -- --ballshots DIR saves there instead
var _fence_t := 99.0    # seconds since the last fence bounce (the cage's "fence" ball shot)
func _ball_shots() -> void:
	_fence_t += get_process_delta_time()
	if _bs_on < 0:
		var args: PackedStringArray = OS.get_cmdline_user_args()
		var i: int = args.find("--ballshots")
		_bs_on = 1 if i >= 0 else 0
		if i >= 0 and i + 1 < args.size() and not args[i + 1].begins_with("--"):
			_bs_dir = args[i + 1]
	if _bs_on == 0:
		return
	var tag := ""
	var need: int = 9   # tags to collect before quitting (+1 for each twist shot below)
	var twist_tag := ""
	if Twists.wind != Vector2.ZERO:
		twist_tag = "wind_curve"   # a long shot bowing downwind, mid-flight
	elif Twists.value("arc_mult", 1.0) != 1.0:
		twist_tag = "thin_air_arc" # the higher drawn arc, mid-flight
	if twist_tag != "":
		need += 1
	if twist_tag != "" and state == SHOT and shot_kind == "" and shot_t > 0.45 and shot_t < 0.6 \
			and (twist_tag != "wind_curve" or shot_curve != Vector2.ZERO):
		tag = twist_tag
	elif Twists.flag("sideline_fence") and state == LOOSE and _fence_t < 0.15:
		tag = "fence"              # just off the fence (not counted in `need`: it may never happen)
	# v2 sheets only (not counted in `need`): the running dribble, a crossover, a catch, a bounce pass on its way down
	elif state == HELD and _is_v2(holder) and String(holder._v_anim).begins_with("run_dribble") and _v_t > 1.0 \
			and game.is_human(holder) and not _bs_done.has("v2_run_dribble"):
		tag = "v2_run_dribble"
	elif state == HELD and holder != null and String(holder._v_anim).begins_with("dribble") and _v_t > 1.0 \
			and game.is_human(holder):
		tag = "dribble"
	elif state == HELD and _is_v2(holder) and String(holder._v_anim).begins_with("run_dribble") and _v_t > 1.0 \
			and game.is_human(holder):
		tag = "dribble"            # a v2 handler who never stands still: his running dribble counts as the dribble
	elif state == HELD and _is_v2(holder) and String(holder._v_anim).begins_with("cross") and holder.cross_t > 0.1 \
			and holder.cross_t < 0.2:
		tag = "v2_cross"
	elif state == HELD and _is_v2(holder) and holder._v_anim == "catch" and holder._v_catch_t < 0.1:
		tag = "v2_catch"
	elif state == PASS and not lob and _is_v2(passer) and _pass_look == "bounce" and _v_h < 20.0:
		tag = "v2_bounce_pass"
	elif state == PASS and lob and lob_t > 0.45 and lob_t < 0.6:
		tag = "lob"
	elif state == SHOT and shot_kind == "dunk":
		tag = "dunk"
	elif state == SHOT and shot_kind == "" and shot_t > 0.93:
		tag = "rim_make" if shot_made else "rim_miss"
	elif state == DEAD and _v_t > 0.08 and _v_t < 0.12 and _v_h > View.RIM_Z - 30.0:
		tag = "net_drop"
	elif state == LOOSE and loose_cause == "rebound" and _v_t > 0.3:
		tag = "loose"
	elif game.fx != null and game.fx.get("_popups") != null and not game.fx._popups.is_empty() and game.fx._popups[0].t > 0.25:
		tag = "popup"
	elif game.fx != null and game.fx.get("_trail_on") == true and state == SHOT and shot_t > 0.5:
		tag = "fire"
	if tag == "" or _bs_done.has(tag):
		return
	_bs_done[tag] = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/hoops_ball_%s.png" % [_bs_dir, tag])
	print("BALLSHOT ", tag)
	var extra: int = 0
	for t in _bs_done:
		if t == "fence" or String(t).begins_with("v2_"):
			extra += 1
	if _bs_done.size() - extra >= need:
		get_tree().quit()
