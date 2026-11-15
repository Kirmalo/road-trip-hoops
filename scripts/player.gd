extends Node2D
# One basketball player. Either driven by the touch controls (the human) or by the CPU brain below.
# CPU defense lives in defense.gd (one instance per player, `def`).

const Defense = preload("res://scripts/defense.gd")

var game
var team := 0
var index := 0
var sprite: Sprite2D
var velocity := Vector2.ZERO
var facing := 0.0
var speed := 170.0
var target := Vector2.ZERO
var speed_mult := 1.0
var spot_index := 0
var spot_timer := 0.0
var decision_timer := 0.0
var steal_cooldown := 0.0
var steal_timer := 0.0
var shooting := false
var shot_charge := 0.0
var cpu_shot_time := 0.0
var def                           # defense brain (defense.gd), created in setup()

# ---- shared move state (Phase 2 contract; later tasks fill these in) ----
const BLOCK_JUMP_TIME := 0.5      # seconds in the air for a defender's block jump
const BLOCK_JUMP_PX := 26.0       # block jump height in pixels (drawn through jump_z)
const BLOCK_JUMP_MOMENTUM := 0.4  # fraction of the take-off velocity kept while airborne (no steering)
const STUMBLE_SPEED_MULT := 0.35  # speed multiplier while off balance (no turbo either)
const GUARD_FT := 4.0             # close guarding: a defender this close in front of the handler slows him
const GUARD_CONE := 50.0          # degrees either side of the handler's movement direction that count as "in front"
const GUARD_SLOW := 0.82          # handler speed multiplier while closely guarded (turbo still applies on top)

var stumble_t := 0.0              # seconds left off balance (slow, can't steal or jump)
var poke_t := 0.0                 # seconds left standing still after a steal attempt (main.STEAL_POKE_FREEZE)
var block_jump_t := -1.0          # seconds since a block jump started (< 0 = not jumping)
var block_jump_vel := Vector2.ZERO
var cross_t := 0.0                # seconds left in a crossover/spin (P2-05)
var move_kind := ""               # "cross" or "spin" (P2-05)
var dribble_side := 1.0           # +1 right hand, -1 left hand (P2-05)
var fake_t := 0.0                 # seconds left in a pump fake (P2-06)
var alley_cut := false            # cutting to the rim for a lob (P2-09)

# ---- player ratings (0-100, 50 = average). Read them with rating("steal") / rating("block"). ----
# Per roster slot (index 0-2), the same for both teams so they stay balanced (each column sums to 150).
const RATINGS_BY_INDEX := [
	{"steal": 75, "block": 40},   # quick hands
	{"steal": 40, "block": 75},   # shot-blocker
	{"steal": 35, "block": 35},
]
const BLOCK_GOOD_BASE := 0.7      # well-timed block jump at block rating 50: success chance
const BLOCK_RATING_SPAN := 0.2    # +/- this across ratings 0..100 (0.5 at 0, 0.9 at 100)
const BLOCK_BAD_CHANCE := 0.03    # badly timed block jump: success chance (any rating)
const RIM_BLOCK_RATING_SPAN := 0.5  # rim-block dice (defense.rim_blocker) x0.5 at rating 0, x1.5 at 100

var ratings := {"steal": 50, "block": 50}

# ---- crossover and the dribble hand (P2-05; owner Q1: crossover only, a "spin" flick is a crossover too) ----
const CROSS_TIME := 0.3           # seconds of the crossover burst
const CROSS_SPEED_MULT := 1.25    # speed multiplier during the burst
const CROSS_ACCEL := 3200.0       # px/s^2 during the burst (normal 1600): the cut is sharp
const CROSS_COOLDOWN := 0.6       # seconds from the start of one crossover to the next
const CROSS_BEAT_FT := 5.0        # a defender this close in front of the handler can be beaten
const CROSS_BEAT_CONE := 75.0     # degrees either side of the handler's facing that count as "in front"
const CROSS_STUN := 0.45          # seconds a beaten defender stumbles
const CROSS_BEAT_CHANCE := 0.5    # CPU defender not moving the wrong way: chance he is beaten (until def decides)
const CROSS_WRONG_WAY_SPEED := 40.0  # px/s: a defender moving at least this fast away from the cut is beaten
const CROSS_HAND_RATE := 13.0     # dribble hand travel per second during a crossover (2.0 = one hand to the other)
const HAND_SWITCH_RATE := 4.0     # same for the slow switch away from a defender
const HAND_SWITCH_FT := 8.0       # the nearest defender inside this, on the ball side ...
const HAND_SWITCH_DELAY := 0.5    # ... for this long: the handler moves the ball to the other hand
const CPU_CROSS_CHANCE := 0.04    # CPU handler, defender close in front and the lane shut: chance per decision
const CPU_CROSS_FT := 5.0         # "close" for that decision
const CPU_CROSS_COMMIT := 0.7     # seconds the CPU keeps going the new way after a crossover
const BEAT_POPUP_COLOR := Color(1.0, 0.95, 0.3)

var cross_cd := 0.0               # seconds until the next crossover is allowed
var cross_dir := Vector2.ZERO     # direction of the current crossover burst
var hand_x := 1.0                 # where the ball is drawn sideways, -1 left hand .. +1 right hand (follows dribble_side)
var hand_switch_t := 0.0          # seconds the nearest defender has been on the ball side
var cpu_side := 0.0               # CPU: sidestep side committed to after a crossover
var cpu_side_t := 0.0

# ---- turbo and stamina (tuning) ----
# (how far to pull the joystick to sprint is TURBO_PULL in touch_controls.gd)
const TURBO_SPEED_MULT := 1.35    # speed multiplier while sprinting
const TURBO_BALL_MULT := 0.95     # ball handler sprints at this fraction of the turbo speed
const STAMINA_DRAIN := 0.4        # stamina per second while sprinting (1.0 = full bar, 2.5 s of sprint)
const STAMINA_REFILL := 0.25      # stamina per second while not sprinting
const REFILL_DELAY := 0.5         # seconds after easing off before stamina starts to refill
const TURBO_MIN_RESTART := 0.25   # after running empty, turbo is off until stamina is back above this
const CPU_TURBO_RESUME := 0.5     # CPU stops at TURBO_MIN_RESTART and waits for this much before sprinting again
const CPU_BEATEN_FT := 4.0        # CPU defender sprints when his man is this many feet closer to the hoop
const CPU_BREAK_FT := 20.0        # CPU fast break: sprint when at least this far from the hoop
const TURBO_SHOT_WINDOW := 0.6    # seconds after sprinting that a jump shot is still "shaky"
const TURBO_SHOT_PENALTY := 0.8   # shot quality multiplier for a jumper right after sprinting
const TURBO_SHOT_EXEMPT_FT := 6.0 # shots this close to the rim (dunks, layups) get no penalty

var stamina := 1.0
var turbo := false                # sprinting this frame
var turbo_locked := false         # ran empty, waiting to reach TURBO_MIN_RESTART
var cpu_tired := false
var cpu_turbo_want := false
var refill_wait := 0.0
var since_turbo := 99.0           # seconds since this player last sprinted
var humantest := false

# ---- dunks and layups (tuning) ----
const DUNK_RANGE := 6.0           # feet from the rim: a dunk is possible inside this
const LAYUP_RANGE := 9.0          # feet from the rim: Shoot inside this is a layup (or dunk), no shot meter
const DUNK_SPEED_FRAC := 0.7      # dunk needs at least this fraction of top speed (or turbo)
const DUNK_TIME := 0.55           # seconds in the air for a dunk
const LAYUP_TIME := 0.45          # seconds in the air for a layup
const DUNK_JUMP_PX := 30.0        # jump height in pixels (drawn as an upward offset)
const LAYUP_JUMP_PX := 20.0
const DUNK_RELEASE := 0.55        # fraction of the jump when the ball leaves the hand
const LAYUP_RELEASE := 0.5
const RIM_GLIDE := 0.45           # fraction of top speed the jumper keeps drifting toward the rim
const DUNK_OPEN_PCT := 0.92       # make chance of an open dunk (P1-09: was 0.85; keeps dunks ahead of layups after the layup change)
const LAYUP_OPEN_PCT := 0.75      # make chance of an open layup (P1-09: was 0.65; contested layups made less than 15 ft jumpers)
const CONTEST_FT := 4.0           # nearest defender inside this contests the take-off
# (rim block chances live in defense.gd: DUNK_BLOCK_CHANCE, LAYUP_BLOCK_CHANCE, RIM_CONTEST_FT)
const CONTEST_MAKE_MULT := 1.0    # extra make-odds multiplier with a defender right on you (eases off with distance). P1-09: was 0.9; shot_probability() already applies the openness penalty, so 1.0 avoids counting it twice
const CPU_FINISH_FT := 4.5        # CPU handler finishes at the rim inside this (any speed)
const CPU_LAYUP_CHANCE := 0.45    # CPU entering LAYUP_RANGE with a defender close: chance it pulls up for a layup
const CPU_LAYUP_OPEN_CHANCE := 0.15  # same with nobody close (otherwise it keeps going for the dunk)

# ---- CPU ball handler decisions (tuning; one roll per decision, every CPU_DECIDE_MIN..MAX s) ----
const CPU_DECIDE_MIN := 0.3       # seconds between handler decisions
const CPU_DECIDE_MAX := 0.5
const CPU_CLOCK_SHOOT := 4.0      # shot clock under this: shoot from anywhere inside CPU_CLOCK_SHOOT_FT
const CPU_CLOCK_SHOOT_FT := 32.0
const CPU_GOOD_SHOT_P := 0.40     # make chance above this with the defender CPU_GOOD_SHOT_OPEN_FT off: shoot...
const CPU_GOOD_SHOT_OPEN_FT := 4.0
const CPU_GOOD_SHOT_CHANCE := 0.5 # ...with this chance
const CPU_OPEN_SHOT_FT := 6.0     # wide open (defender this far off) inside CPU_OPEN_SHOT_RANGE: shoot...
const CPU_OPEN_SHOT_RANGE := 26.0
const CPU_OPEN_SHOT_CHANCE := 0.3 # ...with this chance
const CPU_PASS_CHANCE := 0.15     # otherwise, chance to look for an open teammate
const CPU_PASS_OPEN_EDGE := 2.0   # a teammate must be this many feet more open than me
# pull-up jumpers (R1): mid-range off the dribble when the defender gives room or is beaten
const CPU_PULLUP_MIN_FT := 12.0   # pull-up range from the rim
const CPU_PULLUP_MAX_FT := 22.0
const CPU_PULLUP_ROOM_FT := 3.0   # defender at least this far off (or behind me) to pull up
const CPU_PULLUP_CHANCE := 0.28   # chance per decision when a pull-up is on
const CPU_THREE_MAX_FT := 28.0    # deep pull-up: beyond the arc but inside this
const CPU_THREE_OPEN_FT := 4.0    # and the defender at least this far off
const CPU_THREE_CHANCE := 0.25    # chance per decision

var rim_kind := ""                # "dunk" or "layup" while in the air, "" otherwise
var jump_t := 0.0                 # seconds since take-off
var jump_time := 0.0
var jump_z := 0.0                 # current height of the jump in pixels
var jump_released := false
var rim_quality := 1.0
var cpu_rim_rolled := false       # CPU already decided layup-or-keep-going on this drive

# ---- on fire (tuning; streak rules live in main.gd) ----
const FIRE_GREEN_LO := 0.70       # human shot meter: green ("perfect") zone while on fire (normal 0.78..0.95)
const FIRE_GREEN_HI := 1.0
const GREEN_LO := 0.78            # normal green zone
const GREEN_HI := 0.95
const FIRE_SHOT_BONUS := 1.15     # make-odds multiplier for CPU jumpers and everyone's dunks/layups while on fire
const FIRE_RING_COLOR := Color(1.0, 0.45, 0.1)

var make_streak := 0              # makes in a row by this player
var on_fire := false
var fire_misses := 0              # misses/blocks while on fire (main.FIRE_MISSES puts it out)
var fire_anim := 0.0

# Offensive spots, in feet: (distance out from the baseline side of the hoop, sideways offset)
const SPOTS := [
	Vector2(24, 0),    # top of the key
	Vector2(18, -16),  # left wing
	Vector2(18, 16),   # right wing
	Vector2(3, -21),   # left corner
	Vector2(3, 21),    # right corner
	Vector2(5, -8),    # left block
	Vector2(5, 8),     # right block
	Vector2(17, -7),   # left elbow
	Vector2(17, 7),    # right elbow
]

func setup(g, t: int, i: int, tex: Texture2D) -> void:
	game = g
	team = t
	index = i
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2(1.75, 1.75)
	add_child(sprite)
	z_index = 5
	spot_index = [0, 1, 4][i]
	facing = 0.0 if team == 0 else PI
	sprite.rotation = facing
	humantest = OS.get_cmdline_user_args().has("--humantest")
	def = Defense.new(self, g)
	ratings = (RATINGS_BY_INDEX[i] as Dictionary).duplicate()

func has_ball() -> bool:
	return game.ball.state == game.ball.HELD and game.ball.holder == self

func update(delta: float, is_human: bool, input_vec: Vector2) -> void:
	steal_cooldown = max(0.0, steal_cooldown - delta)
	stumble_t = maxf(0.0, stumble_t - delta)
	poke_t = maxf(0.0, poke_t - delta)
	cross_cd = maxf(0.0, cross_cd - delta)
	cpu_side_t = maxf(0.0, cpu_side_t - delta)
	if cross_t > 0.0:
		cross_t = maxf(0.0, cross_t - delta)
		if not has_ball() or shooting or is_airborne():
			cross_t = 0.0
	if team == 0 and index == 0:
		game.stat("frames")
	var desired := Vector2.ZERO
	var want_turbo := false
	if rim_kind != "":
		desired = update_rim_move(delta)
	elif block_jump_t >= 0.0:
		desired = update_block_jump(delta)
	elif shooting:
		if not has_ball():
			shooting = false
		elif is_human:
			shot_charge += delta / 0.9
			if shot_charge >= 1.2:
				release_shot()
		else:
			cpu_shot_time -= delta
			if cpu_shot_time <= 0.0:
				release_shot()
	elif is_human:
		desired = input_vec.limit_length(1.0) * speed * (0.94 if has_ball() else 1.0)
		var ball = game.ball
		if desired.length() < 1.0 and ball.state == ball.PASS and ball.receiver == self:
			desired = seek(ball.position, 1.0)
		want_turbo = human_turbo_input() and desired.length() > 1.0
	else:
		ai(delta)
		desired = seek(target, speed_mult)
		want_turbo = cpu_turbo_want and desired.length() > 1.0
	var accel := 1600.0
	if cross_t > 0.0:
		desired = cross_dir * speed * CROSS_SPEED_MULT   # the burst: a sharp cut the new way
		accel = CROSS_ACCEL
	if poke_t > 0.0 and rim_kind == "" and block_jump_t < 0.0:
		desired = Vector2.ZERO        # reaching for the ball: stands still, hit or miss
		want_turbo = false
		game.stat("poke_freeze_frames_t%d" % team)
	elif stumble_t > 0.0:
		desired *= STUMBLE_SPEED_MULT
		want_turbo = false
	elif has_ball() and not is_airborne() and cross_t <= 0.0 and is_guarded(desired):
		desired *= GUARD_SLOW
		game.stat("guard_slow_frames_t%d" % team)
	if update_turbo(delta, want_turbo, is_human):
		desired *= TURBO_SPEED_MULT * (TURBO_BALL_MULT if has_ball() else 1.0)
	update_dribble_hand(delta)
	velocity = velocity.move_toward(desired, accel * delta)
	position += velocity * delta
	position = game.clamp_to_court(position)
	var lift := jump_z / DUNK_JUMP_PX
	sprite.position = Vector2(0, -jump_z)
	sprite.scale = Vector2(1.75, 1.75) * (1.0 + 0.15 * lift)
	# face where we are going, or the ball when standing still
	var look := velocity
	if look.length() < 15.0 or poke_t > 0.0:
		look = game.ball.position - position
	if look.length() > 1.0:
		facing = lerp_angle(facing, look.angle(), min(1.0, 10.0 * delta))
	sprite.rotation = facing
	if on_fire:
		fire_anim += delta
	queue_redraw()

# ---------------- shared moves: stumble, block jump, close guarding ----------------

func rating(key: String) -> int:
	return int(ratings.get(key, 50))

# -1..+1 for ratings 0..100
func rating_frac(key: String) -> float:
	return clampf((float(rating(key)) - 50.0) / 50.0, -1.0, 1.0)

# Success chance of a block jump: timing decides good vs bad, the block rating scales a good one.
func block_chance(good_timing: bool) -> float:
	if not good_timing:
		return BLOCK_BAD_CHANCE
	return clampf(BLOCK_GOOD_BASE + BLOCK_RATING_SPAN * rating_frac("block"), 0.0, 1.0)

# Knocked off balance for `time` seconds (slow, no turbo, can't steal or jump).
func stumble(time: float) -> void:
	if time <= 0.0:
		return
	stumble_t = maxf(stumble_t, time)
	game.stat("stumbles")

# A defender jumps to block. False if already airborne, off balance or holding the ball.
func start_block_jump() -> bool:
	if is_airborne() or stumble_t > 0.0 or has_ball():
		return false
	block_jump_t = 0.0
	block_jump_vel = velocity * BLOCK_JUMP_MOMENTUM
	game.stat("block_jumps_t%d" % team)
	return true

func is_airborne() -> bool:
	return rim_kind != "" or block_jump_t >= 0.0

# 0 on the floor, 1 at the top of a block jump
func block_height_frac() -> float:
	if block_jump_t < 0.0:
		return 0.0
	return sin(PI * clampf(block_jump_t / BLOCK_JUMP_TIME, 0.0, 1.0))

# Runs every frame during a block jump; returns the desired velocity (momentum only, no steering).
func update_block_jump(delta: float) -> Vector2:
	block_jump_t += delta
	if block_jump_t >= BLOCK_JUMP_TIME:
		block_jump_t = -1.0
		jump_z = 0.0
		return Vector2.ZERO
	jump_z = BLOCK_JUMP_PX * block_height_frac()
	return block_jump_vel

# A defender within GUARD_FT, inside GUARD_CONE of the way I'm heading.
func is_guarded(move: Vector2) -> bool:
	if move.length() < 1.0:
		return false
	var dir := move.normalized()
	var reach: float = GUARD_FT * game.FT
	var cos_cone := cos(deg_to_rad(GUARD_CONE))
	for o in game.teams[1 - team]:
		if o.stumble_t > 0.0:
			continue   # a stumbling defender doesn't slow the driver
		var r: Vector2 = o.position - position
		var d := r.length()
		if d < reach and d > 0.1 and dir.dot(r / d) >= cos_cone:
			return true
	return false

# ---------------- crossover and the dribble hand (P2-05) ----------------

# A quick cut toward `dir` with the ball switching hands in front of the body. Called by human_input.gd on a flick
# and by the CPU handler. Owner (Q1): crossover only, so every kind (including "spin") is a crossover.
func start_crossover(dir: Vector2, kind: String) -> void:
	if not has_ball() or shooting or is_airborne() or stumble_t > 0.0:
		return
	if cross_cd > 0.0 or cross_t > 0.0:
		if game.is_human(self):
			game.stat("human_cross_cooldown")   # a flick that came too soon after the last crossover
		return
	if dir.length() < 0.01:
		dir = Vector2.from_angle(facing + PI / 2.0 * dribble_side)
	if kind != "cross":
		game.stat("cross_from_" + kind)   # the detector called it a spin: played as a crossover (Q1)
	move_kind = "cross"
	cross_dir = dir.normalized()
	cross_t = CROSS_TIME
	cross_cd = CROSS_COOLDOWN
	dribble_side = -dribble_side
	hand_switch_t = 0.0
	game.stat("crossovers_t%d" % team)
	if game.is_human(self):
		game.stat("human_crossovers")
	else:
		game.stat("cpu_crossovers")
	cross_beat_check()

# The defender close in front can be beaten: he stumbles if he was moving the wrong way, or (CPU) if he is still
# inside his reaction time. Until defense.gd decides that (P2-08 hook `def.beaten_by_cross(handler, dir)`), a flat
# CROSS_BEAT_CHANCE. Only the closest defender in front can be beaten.
func cross_beat_check() -> void:
	var look := Vector2.from_angle(facing)
	var cos_cone := cos(deg_to_rad(CROSS_BEAT_CONE))
	var best = null
	var best_d: float = CROSS_BEAT_FT * game.FT
	for o in game.teams[1 - team]:
		var r: Vector2 = o.position - position
		var d := r.length()
		if d < best_d and d > 0.1 and look.dot(r / d) >= cos_cone and o.stumble_t <= 0.0 and not o.is_airborne():
			best_d = d
			best = o
	if best == null:
		return
	var beaten := false
	var ov: Vector2 = best.velocity
	if ov.length() >= CROSS_WRONG_WAY_SPEED and ov.normalized().dot(cross_dir) < -0.3:
		beaten = true   # leaning the wrong way: the cut goes behind him
	elif not game.is_human(best):
		if best.def != null and best.def.has_method("beaten_by_cross"):
			beaten = best.def.beaten_by_cross(self, cross_dir)
		else:
			beaten = game.rng.randf() < CROSS_BEAT_CHANCE
	if not beaten:
		return
	best.stumble(CROSS_STUN)
	game.stat("cross_beats_t%d" % team)
	if game.is_human(self):
		game.stat("human_cross_beats")
	if game.fx:
		game.fx.popup("SHOOK!", best.position + Vector2(0, -40), BEAT_POPUP_COLOR, 30)

# Moves the drawn dribble hand (hand_x) toward dribble_side; the ball is centered while shooting or in the air.
# Out of a move, the handler slowly switches hands away from the nearest defender.
func update_dribble_hand(delta: float) -> void:
	if not has_ball():
		hand_switch_t = 0.0
		return
	var goal := dribble_side
	if shooting or is_airborne():
		goal = 0.0
	elif cross_t <= 0.0:
		var o = game.nearest_opponent(self)
		var right := Vector2.from_angle(facing + PI / 2.0)
		if o != null and o.position.distance_to(position) < HAND_SWITCH_FT * game.FT \
				and right.dot(o.position - position) * dribble_side > 0.0:
			hand_switch_t += delta
			if hand_switch_t >= HAND_SWITCH_DELAY:
				hand_switch_t = 0.0
				dribble_side = -dribble_side
				game.stat("hand_switches")
		else:
			hand_switch_t = 0.0
	var rate := CROSS_HAND_RATE if cross_t > 0.0 else HAND_SWITCH_RATE
	hand_x = move_toward(hand_x, goal, rate * delta)

# ---------------- turbo ----------------

func human_turbo_input() -> bool:
	if humantest:
		return true  # developer testing: the scripted thumb is always pushed to the edge
	if Input.is_key_pressed(KEY_SHIFT):
		return true  # desktop testing only
	return game.controls.turbo_pull()   # thumb pulled past the joystick ring (touch_controls.TURBO_PULL)

# Drains or refills stamina and returns true if this player sprints this frame.
func update_turbo(delta: float, want: bool, is_human: bool) -> bool:
	if not is_human:
		# the CPU keeps a reserve: it never sprints itself below TURBO_MIN_RESTART
		if stamina <= TURBO_MIN_RESTART:
			cpu_tired = true
		elif stamina >= CPU_TURBO_RESUME:
			cpu_tired = false
		if cpu_tired:
			want = false
	if turbo_locked and stamina >= TURBO_MIN_RESTART:
		turbo_locked = false
	turbo = want and not turbo_locked and not shooting and not is_airborne()
	if turbo:
		since_turbo = 0.0
		if on_fire:
			game.stat("fire_turbo_frames")   # on fire: stamina doesn't drain
		else:
			stamina = maxf(0.0, stamina - STAMINA_DRAIN * delta)
		refill_wait = REFILL_DELAY
		game.stat("turbo_frames_t%d" % team)
		if stamina <= 0.0:
			turbo_locked = true
			game.stat("stamina_empty")
	else:
		since_turbo += delta
		refill_wait -= delta
		if refill_wait <= 0.0:
			stamina = minf(1.0, stamina + STAMINA_REFILL * delta)
	return turbo

# opponents closer to this hoop than me (0 or 1 means a fast break)
func opponents_ahead(hoop: Vector2) -> int:
	var n := 0
	var my_d := position.distance_to(hoop)
	for o in game.teams[1 - team]:
		if o.position.distance_to(hoop) < my_d:
			n += 1
	return n

func seek(t: Vector2, mult: float) -> Vector2:
	var to := t - position
	var d := to.length()
	if d < 5.0:
		return Vector2.ZERO
	return to / d * speed * mult * min(1.0, d / 35.0)

# ---------------- shooting ----------------

func start_shot() -> void:
	if has_ball() and not shooting and rim_kind == "":
		var d_ft: float = position.distance_to(game.attack_hoop(team)) / game.FT
		if d_ft <= LAYUP_RANGE:
			start_rim_move(d_ft)
			return
		shooting = true
		shot_charge = 0.0
		cpu_shot_time = game.rng.randf_range(0.3, 0.45)

func release_shot() -> void:
	if not shooting or rim_kind != "":
		return  # dunks and layups release on their own
	shooting = false
	var quality := 1.0
	if game.is_human(self):
		var c := shot_charge
		if c >= green_lo() and c <= green_hi():
			quality = 1.3
			game.show_message("PERFECT RELEASE", 0.8)
		elif c >= 0.6 and c <= 1.05:
			quality = 1.0
		else:
			quality = 0.6
	else:
		quality = game.rng.randf_range(0.85, 1.1)
		if on_fire:
			quality *= FIRE_SHOT_BONUS
	# shaky jumper right after sprinting (not at the rim)
	var hoop: Vector2 = game.attack_hoop(team)
	if since_turbo <= TURBO_SHOT_WINDOW and position.distance_to(hoop) > TURBO_SHOT_EXEMPT_FT * game.FT:
		quality *= TURBO_SHOT_PENALTY
		game.stat("turbo_jumpers")
	# jump-shot counters: attempts per team, 5 ft distance bands, threes, and makes
	var counted := has_ball()
	var three: bool = game.is_three(position, hoop)
	if counted:
		game.stat("jumpers_t%d" % team)
		game.stat("jumper_d%d" % int(position.distance_to(hoop) / game.FT / 5.0))
		if three:
			game.stat("jumper_threes_t%d" % team)
	game.release_shot(self, quality)
	var ball = game.ball
	if counted and ball.state == ball.SHOT and ball.shot_made:
		game.stat("jumper_makes_t%d" % team)
		if three:
			game.stat("jumper_three_makes_t%d" % team)

func green_lo() -> float:
	return FIRE_GREEN_LO if on_fire else GREEN_LO

func green_hi() -> float:
	return FIRE_GREEN_HI if on_fire else GREEN_HI

# ---------------- dunks and layups ----------------

func is_dunk_speed() -> bool:
	return turbo or since_turbo < 0.2 or velocity.length() >= DUNK_SPEED_FRAC * speed

# Shoot near the rim: take off for a dunk (very close and fast) or a layup. No shot meter.
func start_rim_move(d_ft: float) -> void:
	var dunk := d_ft <= DUNK_RANGE and is_dunk_speed()
	rim_kind = "dunk" if dunk else "layup"
	jump_time = DUNK_TIME if dunk else LAYUP_TIME
	jump_t = 0.0
	jump_z = 0.0
	jump_released = false
	shooting = true
	game.stat(rim_kind + "s")
	game.stat("%ss_t%d" % [rim_kind, team])
	if game.is_human(self):
		game.stat("human_" + rim_kind + "s")
	# make-odds contest at take-off (the block is asked at release, see release_rim_shot)
	rim_quality = 1.0
	var d = game.nearest_opponent(self)
	if d != null:
		var c_ft: float = d.position.distance_to(position) / game.FT
		if c_ft < CONTEST_FT:
			var close := clampf(1.5 * (1.0 - c_ft / CONTEST_FT), 0.0, 1.0)
			rim_quality *= lerpf(1.0, CONTEST_MAKE_MULT, close)
			game.stat("rim_contested")

# Runs every frame while in the air; returns the desired velocity (a glide toward the rim).
func update_rim_move(delta: float) -> Vector2:
	jump_t += delta
	var f := clampf(jump_t / jump_time, 0.0, 1.0)
	var peak := DUNK_JUMP_PX if rim_kind == "dunk" else LAYUP_JUMP_PX
	jump_z = peak * sin(PI * f)
	var release_at := DUNK_RELEASE if rim_kind == "dunk" else LAYUP_RELEASE
	if not jump_released and f >= release_at:
		jump_released = true
		shooting = false
		if has_ball():
			release_rim_shot()
	elif not jump_released and not has_ball():
		jump_released = true  # stripped or the period ended: just land
		shooting = false
	if f >= 1.0:
		rim_kind = ""
		jump_z = 0.0
		shooting = false
		return Vector2.ZERO
	var hoop: Vector2 = game.attack_hoop(team)
	var under: Vector2 = hoop + Vector2(game.inward(hoop) * 1.5 * game.FT, 0)
	return seek(under, RIM_GLIDE)

func release_rim_shot() -> void:
	var ball = game.ball
	ball.next_shot_kind = rim_kind
	var blocker = Defense.rim_blocker(game, self, rim_kind)
	if blocker != null:
		# blocked at the rim: swatted out of the hands (counts as a missed shot, never as a make)
		ball.next_shot_kind = ""
		game.rim_shot_blocked(self, blocker)
		game.stat("rim_blocks")
		return
	# aim the open make chance at DUNK_OPEN_PCT / LAYUP_OPEN_PCT; shot_probability() then applies its own
	# openness penalty (about x0.55 with a defender on you)
	var d_ft: float = position.distance_to(game.attack_hoop(team)) / game.FT
	var base := 0.66 if d_ft < 5.0 else maxf(0.02, 0.52 - (d_ft - 5.0) * 0.0075)  # mirrors main.shot_probability
	var target := DUNK_OPEN_PCT if rim_kind == "dunk" else LAYUP_OPEN_PCT
	var fire_mult := FIRE_SHOT_BONUS if on_fire else 1.0
	game.release_shot(self, target / base * rim_quality * fire_mult)
	if ball.state == ball.SHOT:
		ball.blocked_checked = true  # the take-off contest replaces the CPU jump-shot contest

# ---------------- CPU brain ----------------

func ai(delta: float) -> void:
	var ball = game.ball
	speed_mult = 1.0
	cpu_turbo_want = false
	var my_hoop: Vector2 = game.attack_hoop(team)

	# chase loose balls and rebounds (sprint for them)
	if ball.state == ball.LOOSE:
		if game.is_chaser(self):
			target = ball.position
			cpu_turbo_want = position.distance_to(target) > 3.0 * game.FT
			return
	if ball.state == ball.SHOT and ball.shot_t > 0.4 and game.is_chaser(self):
		target = ball.shot_hoop + Vector2(game.inward(ball.shot_hoop) * 6.0 * game.FT, 0)
		cpu_turbo_want = position.distance_to(target) > 6.0 * game.FT
		return
	if ball.state == ball.PASS and ball.receiver == self:
		target = ball.position
		return

	if game.possession == team:
		if has_ball():
			handler_ai(delta, my_hoop)
		else:
			offball_ai(delta, my_hoop)
	else:
		defense_ai(delta)

func spot_pos(hoop: Vector2, i: int) -> Vector2:
	var s: Vector2 = SPOTS[i]
	return hoop + Vector2(game.inward(hoop) * s.x * game.FT, s.y * game.FT)

func offball_ai(delta: float, hoop: Vector2) -> void:
	spot_timer -= delta
	if spot_timer <= 0.0:
		spot_timer = game.rng.randf_range(2.5, 5.0)
		# cut to a spot no teammate is using
		var used := []
		for p in game.teams[team]:
			if p != self:
				used.append(p.spot_index)
		var choices := []
		for i in SPOTS.size():
			if not used.has(i) and i != spot_index:
				choices.append(i)
		if choices.size() > 0:
			spot_index = choices[game.rng.randi() % choices.size()]
	target = spot_pos(hoop, spot_index)
	# stay out of the ball handler's way
	var ball = game.ball
	if ball.holder != null and ball.holder != self:
		var away: Vector2 = target - ball.holder.position
		if away.length() < 8.0 * game.FT:
			target = ball.holder.position + away.normalized() * 10.0 * game.FT
	# fill the lane on a fast break
	if ball.state == ball.HELD and opponents_ahead(hoop) <= 1 \
			and position.distance_to(target) > 15.0 * game.FT:
		cpu_turbo_want = true

func handler_ai(delta: float, hoop: Vector2) -> void:
	var FT: float = game.FT
	var to_hoop := hoop - position
	var dist_ft := to_hoop.length() / FT
	speed_mult = 1.0
	var fast_break := opponents_ahead(hoop) <= 1 and dist_ft > CPU_BREAK_FT
	if not game.in_frontcourt(position, team):
		target = spot_pos(hoop, 0)
		if fast_break:
			target = hoop + Vector2(game.inward(hoop) * 3.0 * FT, 0)
			cpu_turbo_want = true
		return
	# drive to the rim, sidestepping a defender who is in the way
	target = hoop + Vector2(game.inward(hoop) * 3.0 * FT, 0)
	var d: Vector2 = to_hoop.normalized()
	var guard = game.nearest_opponent(self)
	var open_ft := 99.0
	var guard_behind := false         # nearest defender is not between me and the hoop
	var step_side := 0.0              # which way the sidestep goes (0 = no sidestep)
	if guard != null:
		var r: Vector2 = guard.position - position
		open_ft = r.length() / FT
		guard_behind = r.dot(d) <= 0.0
		if open_ft < 5.0 and r.dot(d) > 0.0:
			var side := 1.0 if d.cross(r) > 0.0 else -1.0
			if cpu_side_t > 0.0:
				side = cpu_side   # keep going the way the crossover went
			step_side = side
			target = position + (d * 0.4 - d.orthogonal() * side) * 120.0
	# sprint on a fast break, or when the lane to the rim is open
	if fast_break or (open_ft > 6.0 and dist_ft > 8.0 and lane_open(hoop)):
		cpu_turbo_want = true
	# attack the rim: once per drive, maybe pull up early for a layup; at full speed close in, dunk
	if dist_ft > LAYUP_RANGE + 2.0:
		cpu_rim_rolled = false
	elif dist_ft <= LAYUP_RANGE and dist_ft > DUNK_RANGE and not cpu_rim_rolled:
		cpu_rim_rolled = true
		if game.rng.randf() < (CPU_LAYUP_CHANCE if open_ft < CONTEST_FT else CPU_LAYUP_OPEN_CHANCE):
			start_shot()
			return
	if dist_ft <= DUNK_RANGE and is_dunk_speed():
		start_shot()
		return
	decision_timer -= delta
	if decision_timer > 0.0:
		return
	decision_timer = game.rng.randf_range(CPU_DECIDE_MIN, CPU_DECIDE_MAX)
	var p: float = game.shot_probability(self, 1.0)
	var three: bool = game.is_three(position, hoop)
	if dist_ft < CPU_FINISH_FT:
		start_shot()
	elif game.shot_clock < CPU_CLOCK_SHOOT and dist_ft < CPU_CLOCK_SHOOT_FT:
		start_shot()
	elif step_side != 0.0 and open_ft < CPU_CROSS_FT and dist_ft > LAYUP_RANGE and cross_cd <= 0.0 \
			and not lane_open(hoop) and game.rng.randf() < CPU_CROSS_CHANCE:
		# crossover: cut back the other way, behind a defender sliding with the sidestep
		cpu_side = -step_side
		cpu_side_t = CPU_CROSS_COMMIT
		start_crossover((d * 0.4 - d.orthogonal() * cpu_side).normalized(), "cross")
	elif dist_ft >= CPU_PULLUP_MIN_FT and dist_ft <= CPU_PULLUP_MAX_FT and not three \
			and (open_ft >= CPU_PULLUP_ROOM_FT or guard_behind) and game.rng.randf() < CPU_PULLUP_CHANCE:
		game.stat("pullups_t%d" % team)
		start_shot()
	elif three and dist_ft <= CPU_THREE_MAX_FT and open_ft >= CPU_THREE_OPEN_FT \
			and game.rng.randf() < CPU_THREE_CHANCE:
		game.stat("cpu_threes")
		start_shot()
	elif p > CPU_GOOD_SHOT_P and open_ft > CPU_GOOD_SHOT_OPEN_FT and game.rng.randf() < CPU_GOOD_SHOT_CHANCE:
		start_shot()
	elif open_ft > CPU_OPEN_SHOT_FT and dist_ft < CPU_OPEN_SHOT_RANGE and game.rng.randf() < CPU_OPEN_SHOT_CHANCE:
		start_shot()
	elif game.rng.randf() < CPU_PASS_CHANCE:
		var best = null
		var best_open := open_ft + CPU_PASS_OPEN_EDGE
		for mate in game.teams[team]:
			if mate == self or not game.in_frontcourt(mate.position, team):
				continue
			var o: float = game.openness(mate)
			if o > best_open:
				best_open = o
				best = mate
		if best != null:
			game.do_pass(self, best)

# no opponent in a corridor between me and the hoop
func lane_open(hoop: Vector2) -> bool:
	var FT: float = game.FT
	var to_hoop := hoop - position
	var d := to_hoop.normalized()
	for o in game.teams[1 - team]:
		var r: Vector2 = o.position - position
		var along := r.dot(d)
		if along > 0.0 and along < to_hoop.length() and absf(d.cross(r)) < 5.0 * FT:
			return false
	return true

func defense_ai(delta: float) -> void:
	def.cpu_update(delta)

func _draw() -> void:
	if jump_z > 0.5:
		# shadow on the floor under a jumping player
		var sr := 16.0 - jump_z * 0.15
		draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.55))
		draw_circle(Vector2.ZERO, sr, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if on_fire:
		draw_fire_ring()
	if turbo and velocity.length() > 20.0:
		# dust puffs behind a sprinting player
		var back := -velocity.normalized()
		draw_circle(back * 18.0, 6.0, Color(1, 1, 1, 0.35))
		draw_circle(back * 30.0 + back.orthogonal() * 4.0, 4.5, Color(1, 1, 1, 0.22))
		draw_circle(back * 40.0 - back.orthogonal() * 3.0, 3.0, Color(1, 1, 1, 0.12))
	if cross_t > 0.0 and cross_dir.length() > 0.1:
		# crossover: speed lines behind the cut
		var a := cross_t / CROSS_TIME
		var bk := -cross_dir
		var sd := bk.orthogonal()
		for k in 3:
			var off := sd * (float(k) - 1.0) * 9.0
			draw_line(bk * 16.0 + off, bk * (38.0 + 10.0 * float(k % 2)) + off, Color(1, 1, 1, 0.9 * a), 4.0)
	if game.is_human(self):
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 32, Color(1, 0.9, 0.2), 3.0)
		var tri := PackedVector2Array([Vector2(-7, -44), Vector2(7, -44), Vector2(0, -34)])
		draw_colored_polygon(tri, Color(1, 0.9, 0.2))
		# stamina bar under the ring
		var bw := 48.0
		var bo := Vector2(-bw / 2, 27)
		draw_rect(Rect2(bo - Vector2(2, 2), Vector2(bw + 4, 14)), Color(0, 0, 0, 0.75))
		var col := Color(0.25, 0.9, 0.35)
		if turbo_locked:
			col = Color(0.55, 0.55, 0.55)
		elif stamina < 0.3:
			col = Color(0.95, 0.25, 0.2)
		elif stamina < 0.6:
			col = Color(1.0, 0.8, 0.2)
		draw_rect(Rect2(bo, Vector2(bw * stamina, 10)), col)
		var mark := bo.x + bw * TURBO_MIN_RESTART
		draw_line(Vector2(mark, bo.y), Vector2(mark, bo.y + 10), Color(1, 1, 1, 0.5), 1.0)
	if shooting and game.is_human(self):
		var w := 56.0
		var o := Vector2(-w / 2, -58)
		draw_rect(Rect2(o, Vector2(w, 10)), Color(0, 0, 0, 0.7))
		var glo := green_lo()
		var gcol := Color(1.0, 0.6, 0.15) if on_fire else Color(0.2, 0.9, 0.3)
		draw_rect(Rect2(o + Vector2(w * glo / 1.2, 0), Vector2(w * (green_hi() - glo) / 1.2, 10)), gcol)
		var c: float = min(shot_charge, 1.2) / 1.2
		draw_rect(Rect2(o + Vector2(w * c - 2, -3), Vector2(4, 16)), Color.WHITE)

# flickering flame ring on the floor around an on-fire player (visible without the ball)
func draw_fire_ring() -> void:
	var t := fire_anim
	var r := 26.0 + 1.5 * sin(t * 9.0)
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(1.0, 0.25, 0.05, 0.85), 4.0)
	draw_arc(Vector2.ZERO, r - 3.0, 0, TAU, 40, Color(1.0, 0.75, 0.2, 0.9), 2.0)
	var n := 8
	for i in n:
		var a: float = TAU * float(i) / float(n) + t * 1.5
		var h: float = 9.0 + 4.0 * sin(t * 13.0 + float(i) * 1.7)
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal() * 4.0
		var base := dir * r
		var flame := PackedVector2Array([base - side, base + side, base + dir * h])
		var col := FIRE_RING_COLOR if i % 2 == 0 else Color(1.0, 0.8, 0.2)
		draw_colored_polygon(flame, col)
