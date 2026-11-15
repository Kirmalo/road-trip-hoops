extends Node
# Human input: what the A (orange) and B (blue) buttons do, the pass target, switching player, and the stick
# gestures (crossover / spin flick, short tap of A), and CALL for the ball (B on offense without it). Created by
# main.gd as `game.input`; main.gd keeps the signal connections, the keyboard handler and the humantest script,
# and forwards to a_pressed / a_released / b_pressed.
# update(delta, stick) runs every physics frame with the same stick vector the human player gets.

# ---- flick (crossover / spin) detection (tuning) ----
# A flick: the stick direction turns by at least FLICK_ANGLE within FLICK_WINDOW, pushed at least FLICK_MIN_LEN
# both before and after. Turbo is the finger's distance from the center, so pulling out past the ring changes the
# length, not the angle, and can't make a flick. Normal steering turns slower than FLICK_ANGLE per FLICK_WINDOW.
const FLICK_ANGLE := 100.0        # degrees the stick must turn to count as a flick
const SPIN_ANGLE := 150.0         # a flick that turns more than this is a "spin" (a flick back), less is a "cross"
const FLICK_WINDOW := 0.12        # seconds the turn must happen in (about 7 frames)
const FLICK_MIN_LEN := 0.6        # stick length (fraction of the ring) needed before and after the turn
const FLICK_COOLDOWN := 0.5       # seconds after a flick before the next one can fire
const FLICK_FRAME_GRACE_MAX := 0.15 # at most this much extra window at low frame rates (two frames' time)
const FLICK_TOUCH_IGNORE := 0.15  # seconds after the thumb touches down that are ignored (new floating center)

# ---- short tap of A (pump fake input, used by P2-06) ----
const SHORT_TAP_MAX := 0.15       # seconds: A released this soon after starting the shot meter is a short tap

# ---- the defense button (P2-07, owner Q3): A picks STEAL or BLOCK automatically ----
# BLOCK when the opponent with the ball is shooting (or pump faking, or in a rim move), or is within BLOCK_RIM_FT of
# his rim, and the human is within BLOCK_CLOSE_FT of him. Otherwise STEAL. A jump at a fake leaves you in the air.
const BLOCK_CLOSE_FT := 6.0       # the human must be this close to the shooter for BLOCK
const BLOCK_RIM_FT := 9.0         # a handler this close to his rim gets BLOCK even before he shoots (LAYUP_RANGE)
const BLOCK_SHOT_WINDOW := 0.25   # seconds after a release a jump can still block (defense.JUMPER_BLOCK_WINDOW)
# (the defensive assist, P2.5-02, lives in player.gd defense_assist(); a STEAL/BLOCK press turns it off for
# player.ASSIST_PRESS_OFF seconds)

# ---- call for the ball (P2-10, owner Q4): B on offense without the ball = CALL ----
# The CPU teammate with the ball passes to the human as soon as the lane is clear, within CALL_WINDOW. Calling while
# cutting to the rim sets the human's `alley_cut`, so ball.gd (P2-09) throws it as a lob.
const CALL_WINDOW := 1.5          # seconds a call stays alive; no clear lane by then and it's cancelled
const CALL_LANE_FT := 3.0         # the lane is clear when no defender is within this many feet of the pass line
const CALL_PASSER_FT := 5.0       # the first feet of the line are left out: the passer throws around his own man
                                  # (ball.gd can't pick off a pass this close to the passer either)
const CALL_CALLER_FT := 3.0       # and the last feet: a man glued to the caller is beaten by the pass (or picks it off)
const CALL_REACT := 0.15          # seconds the passer takes to turn and throw after hearing the call
const CALL_COOLDOWN := 0.75       # seconds after a call ends before B can call again (no spamming)
const CALL_CUT_FT := 12.0         # within this many feet of the rim ... (ball.gd ALLEY_FT)
const CALL_CUT_SPEED := 0.6       # ... and moving toward it at this fraction of top speed = cutting: the pass is a lob
const CALL_TURN_RATE := 14.0      # how fast the passer turns to face the caller while the call is live

var game

# gesture results other scripts can read
var flick_count := 0              # flicks detected this game
var last_flick_kind := ""         # "cross" or "spin"
var last_flick_dir := Vector2.ZERO
var last_flick_angle := 0.0       # degrees the stick turned in the last flick
var short_tap_count := 0          # short taps of A on a jump shot
var last_a_hold := -1.0           # seconds A was held at the last release (-1 = none yet)
var last_a_short := false         # the last A release was a short tap on the shot meter

var _time := 0.0                  # physics time, so it works the same at --fixed-fps and in the browser
var _frame_dt := 1.0 / 60.0      # time of the last drawn frame (input arrives once per drawn frame)
var _samples: Array = []          # Vector2(time, angle) of stick samples pushed past FLICK_MIN_LEN
var _cooldown := 0.0
var _touch_age := 99.0            # seconds since the joystick thumb touched down
var _last_joy_index := -1
var _last_joy_center := Vector2.ZERO
var _a_down_at := -1.0
var _a_meter := false             # the last A press started the jump-shot meter
var _turbo_was := false
var call_t := -1.0                # seconds since the live call started (< 0 = no call)
var call_cd := 0.0                # seconds until B can call again
var _lob_player = null            # human whose alley_cut we set for a called lob (cleared when that pass ends)
var _debug_log := false           # web build with ?debug_input in the URL: print gestures to the browser console

func _process(delta: float) -> void:
	_frame_dt = clampf(delta, 0.0, 0.25)

func _ready() -> void:
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		_debug_log = q != null and str(q).contains("debug_input")
		if _debug_log:
			print("human_input: debug log on")

# ---------------- buttons ----------------

func a_pressed() -> void:
	if game.game_over:
		get_tree().reload_current_scene()
		return
	var h = game.human_player
	if h == null:
		return
	_a_down_at = _time
	_a_meter = false
	if h.has_ball():
		h.start_shot()
		_a_meter = h.shooting and h.rim_kind == ""
	elif game.possession != game.HUMAN_TEAM or game.ball.state == game.ball.SHOT:
		if "assist_off_t" in h:
			h.assist_off_t = h.ASSIST_PRESS_OFF   # STEAL/BLOCK takes over from the defensive assist (player.gd)
		if defense_action() == "BLOCK":
			block_jump(h)
		else:
			game.attempt_steal(h)

# the opponent the human would jump at: the handler, or the shooter of a ball still in its block window
func block_threat():
	var ball = game.ball
	var h = game.human_player
	if h == null:
		return null
	if ball.state == ball.HELD and ball.holder != null and ball.holder.team != h.team:
		return ball.holder
	if ball.state == ball.SHOT and ball.shooter != null and ball.shooter.team != h.team \
			and ball.shot_t * ball.shot_time < BLOCK_SHOT_WINDOW:
		return ball.shooter
	return null

# "BLOCK" or "STEAL": what A does on defense right now (main.gd shows it on the button)
func defense_action() -> String:
	var h = game.human_player
	# a lob (alley-oop) coming to a player you're close to: BLOCK, so you can jump to meet the catch
	var b = game.ball
	if h != null and b.has_method("is_lob") and b.is_lob() and b.receiver != null and b.receiver.team != h.team:
		if h.position.distance_to(b.receiver.position) <= BLOCK_CLOSE_FT * game.FT:
			return "BLOCK"
	var t = block_threat()
	if h == null or t == null or h.position.distance_to(t.position) > BLOCK_CLOSE_FT * game.FT:
		return "STEAL"
	var ball = game.ball
	if ball.state == ball.SHOT or t.shooting or t.rim_kind != "" or ("fake_t" in t and t.fake_t > 0.0):
		return "BLOCK"
	if t.position.distance_to(game.attack_hoop(t.team)) <= BLOCK_RIM_FT * game.FT:
		return "BLOCK"
	return "STEAL"

func block_jump(h) -> void:
	if not h.has_method("start_block_jump") or not h.start_block_jump():
		return   # already in the air (bit on a fake?) or off balance
	game.stat("human_block_jumps")
	var t = block_threat()
	if t != null and "fake_t" in t and t.fake_t > 0.0:
		game.stat("human_fake_jumps")   # jumped at a pump fake
	_log("block jump")

func a_released() -> void:
	var h = game.human_player
	last_a_hold = _time - _a_down_at if _a_down_at >= 0.0 else -1.0
	last_a_short = _a_meter and last_a_hold >= 0.0 and last_a_hold <= SHORT_TAP_MAX
	if last_a_short and h != null and h.shooting:
		short_tap_count += 1
		game.stat("human_short_taps")
		_log("short tap %.3f s" % last_a_hold)
	_a_meter = false
	_a_down_at = -1.0
	if h != null and h.shooting:
		h.release_shot()

func b_pressed() -> void:
	var h = game.human_player
	if h == null or game.game_over:
		return
	if h.has_ball():
		var to = pass_target(game._input_vector())
		game.do_pass(h, to)
		if to != null and pass_is_lob():
			game.stat("human_alley_lobs")   # PASS to a teammate cutting to the rim (P2-09 decides the lob)
	elif game.possession != game.HUMAN_TEAM:
		switch_player()
	elif game.ball.state != game.ball.DEAD:
		call_for_ball()

# the open teammate, or the teammate in the direction the stick is pushed
func pass_target(dir: Vector2):
	var h = game.human_player
	var best = null
	var best_score := -INF
	for mate in game.teams[game.HUMAN_TEAM]:
		if mate == h:
			continue
		var to: Vector2 = mate.position - h.position
		var s: float = game.openness(mate) - to.length() / game.FT * 0.3
		if dir.length() > 0.3:
			s += dir.normalized().dot(to.normalized()) * 30.0
		if s > best_score:
			best_score = s
			best = mate
	return best

# on defense: take over the teammate closest to the ball
func switch_player() -> void:
	var best = null
	var best_d := INF
	for p in game.teams[game.HUMAN_TEAM]:
		if p == game.human_player:
			continue
		var d: float = p.position.distance_to(game.ball.position)
		if d < best_d:
			best_d = d
			best = p
	if best != null:
		game.human_player = best

# ---------------- call for the ball ----------------

func call_active() -> bool:
	return call_t >= 0.0

func call_for_ball() -> void:
	var h = game.human_player
	if h == null or h.has_ball() or call_active() or call_cd > 0.0:
		return
	call_t = 0.0
	game.stat("human_calls")
	game.fx.popup("BALL!", h.position + Vector2(0, -4.5 * game.FT), game.TEAM_COLORS[h.team], 28)
	_log("call")

func _end_call(cooldown: bool) -> void:
	call_t = -1.0
	if cooldown:
		call_cd = CALL_COOLDOWN

# the teammate who would answer the call: the one holding the ball
func call_passer():
	var h = game.human_player
	var ball = game.ball
	if h == null or ball.state != ball.HELD or ball.holder == null or ball.holder == h or ball.holder.team != h.team:
		return null
	return ball.holder

# the passer can throw now: on the floor, not shooting, faking, crossing over or in a rim move
func passer_ready(q) -> bool:
	if q.shooting or q.rim_kind != "":
		return false
	if q.has_method("is_airborne") and q.is_airborne():
		return false
	if ("fake_t" in q and q.fake_t > 0.0) or ("cross_t" in q and q.cross_t > 0.0):
		return false
	return true

# no defender within CALL_LANE_FT of the line from the passer to the caller (leaving out CALL_PASSER_FT at the
# passer's end and CALL_CALLER_FT at the caller's)
func call_lane_clear(q, h) -> bool:
	var line: Vector2 = h.position - q.position
	if line.length() <= (CALL_PASSER_FT + CALL_CALLER_FT) * game.FT:
		return true
	var dir: Vector2 = line.normalized()
	var a: Vector2 = q.position + dir * CALL_PASSER_FT * game.FT
	var b: Vector2 = h.position - dir * CALL_CALLER_FT * game.FT
	for o in game.teams[1 - h.team]:
		var c: Vector2 = Geometry2D.get_closest_point_to_segment(o.position, a, b)
		if o.position.distance_to(c) < CALL_LANE_FT * game.FT:
			return false
	return true

# cutting to the rim: close to the hoop he attacks and moving at it fast
func is_cutting(h) -> bool:
	var hoop: Vector2 = game.attack_hoop(h.team)
	var to: Vector2 = hoop - h.position
	if to.length() > CALL_CUT_FT * game.FT or to.length() < 1.0:
		return false
	return h.velocity.dot(to.normalized()) >= CALL_CUT_SPEED * h.speed

# true if ball.gd (P2-09) made the pass in flight a lob; false while P2-09 isn't merged
func pass_is_lob() -> bool:
	var ball = game.ball
	if ball.has_method("is_lob"):
		return ball.is_lob()
	for k in ["lob", "is_lob", "pass_lob"]:
		if k in ball:
			return bool(ball.get(k))
	return false

func _update_call(delta: float) -> void:
	call_cd = maxf(0.0, call_cd - delta)
	var ball = game.ball
	if _lob_player != null and not (ball.state == ball.PASS and ball.receiver == _lob_player):
		if "alley_cut" in _lob_player:
			_lob_player.alley_cut = false   # the called lob has landed (or was picked off)
		_lob_player = null
	if not call_active():
		return
	var h = game.human_player
	if h == null or game.game_over or game.possession != game.HUMAN_TEAM or h.has_ball() or ball.state == ball.DEAD:
		game.stat("human_calls_cancelled")   # got the ball some other way, or lost it
		_end_call(false)
		return
	call_t += delta
	var q = call_passer()
	if q != null and call_t >= CALL_REACT and passer_ready(q) and call_lane_clear(q, h):
		var lob: bool = is_cutting(h)
		if lob and "alley_cut" in h:
			h.alley_cut = true
			_lob_player = h
		game.do_pass(q, h)
		game.stat("human_calls_answered")
		if lob:
			game.stat("human_calls_lob")
		if pass_is_lob():
			game.stat("human_alley_lobs")
		_log("call answered%s" % (" (lob)" if lob else ""))
		_end_call(true)
	elif call_t >= CALL_WINDOW:
		game.stat("human_calls_timeout")
		_log("call timed out")
		_end_call(true)

# after the players moved: while the call is live the passer turns to face the caller (the call was heard)
func face_caller(delta: float) -> void:
	if not call_active():
		return
	var q = call_passer()
	var h = game.human_player
	if q == null or q.shooting or q.rim_kind != "":
		return
	var to: Vector2 = h.position - q.position
	if to.length() > 1.0:
		q.facing = lerp_angle(q.facing, to.angle(), minf(1.0, CALL_TURN_RATE * delta))
		q.sprite.rotation = q.facing

# ---------------- stick gestures ----------------

# flicks only count while the human holds the ball on the floor and isn't in the shot meter
func flick_ready() -> bool:
	if game.autoplay or game.game_over:
		return false
	var h = game.human_player
	if h == null or not h.has_ball() or h.shooting or h.rim_kind != "":
		return false
	if h.has_method("is_airborne") and h.is_airborne():
		return false
	return true

func update(delta: float, stick: Vector2) -> void:
	_time += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_touch_age += delta
	var c = game.controls
	var ji: int = c.joy_index
	if ji >= 0 and (_last_joy_index < 0 or c.joy_center != _last_joy_center):
		_touch_age = 0.0          # a new thumb touch: its first moments are not a flick
		_samples.clear()
		_log("touch down")
	elif ji < 0 and _last_joy_index >= 0:
		_samples.clear()          # thumb lifted
	_last_joy_index = ji
	_last_joy_center = c.joy_center
	var tp: bool = c.turbo_pull()
	if tp and not _turbo_was and not game.autoplay:
		game.stat("human_turbo_pulls")
		_log("turbo pull")
	_turbo_was = tp
	if _debug_log and int(_time / 1.0) != int((_time - delta) / 1.0):
		_log("status fps %d ball %s stick %.2f" % [Engine.get_frames_per_second(), str(flick_ready()), stick.length()])

	_update_call(delta)

	if not flick_ready():
		_samples.clear()
		return
	# the window grows by two drawn frames (capped) so a flick spread over several frames at a low frame rate
	# (slow tablet or browser) still sees the stick direction from just before it. Input arrives once per drawn
	# frame while this runs every physics tick, so use the drawn frame time, not delta.
	var frame_time: float = _frame_dt
	var window: float = FLICK_WINDOW + minf(2.0 * frame_time, FLICK_FRAME_GRACE_MAX)
	while _samples.size() > 0 and _time - _samples[0].x > window:
		_samples.pop_front()
	if stick.length() < FLICK_MIN_LEN:
		return                    # inside the dead zone or barely pushed: keep the last strong samples
	var ang: float = stick.angle()
	var turn := 0.0
	for s in _samples:
		turn = maxf(turn, absf(rad_to_deg(wrapf(ang - s.y, -PI, PI))))
	if turn >= FLICK_ANGLE and _cooldown <= 0.0 and _touch_age >= FLICK_TOUCH_IGNORE:
		_samples.clear()
		_cooldown = FLICK_COOLDOWN
		_on_flick(stick.normalized(), "spin" if turn > SPIN_ANGLE else "cross", turn)
	_samples.append(Vector2(_time, ang))

func _on_flick(dir: Vector2, kind: String, turn: float) -> void:
	flick_count += 1
	last_flick_kind = kind
	last_flick_dir = dir
	last_flick_angle = turn
	game.stat("human_flicks")
	game.stat("human_flick_" + kind)
	_log("flick %s %.0f deg (%.2f s after touch-down)" % [kind, turn, _touch_age])
	var h = game.human_player
	if h.has_method("start_crossover"):
		h.start_crossover(dir, kind)

func _log(text: String) -> void:
	if _debug_log:
		print("human_input: ", text)
