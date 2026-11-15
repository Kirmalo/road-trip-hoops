extends Node
# Human input: what the A (orange) and B (blue) buttons do, the pass target, switching player, and the stick
# gestures (crossover / spin flick, short tap of A). Created by main.gd as `game.input`; main.gd keeps the signal
# connections, the keyboard handler and the humantest script, and forwards to a_pressed / a_released / b_pressed.
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
const FLICK_TOUCH_IGNORE := 0.15  # seconds after the thumb touches down that are ignored (new floating center)

# ---- short tap of A (pump fake input, used by P2-06) ----
const SHORT_TAP_MAX := 0.15       # seconds: A released this soon after starting the shot meter is a short tap

# ---- the defense button (P2-07, owner Q3): A picks STEAL or BLOCK automatically ----
# BLOCK when the opponent with the ball is shooting (or pump faking, or in a rim move), or is within BLOCK_RIM_FT of
# his rim, and the human is within BLOCK_CLOSE_FT of him. Otherwise STEAL. A jump at a fake leaves you in the air.
const BLOCK_CLOSE_FT := 6.0       # the human must be this close to the shooter for BLOCK
const BLOCK_RIM_FT := 9.0         # a handler this close to his rim gets BLOCK even before he shoots (LAYUP_RANGE)
const BLOCK_SHOT_WINDOW := 0.25   # seconds after a release a jump can still block (defense.JUMPER_BLOCK_WINDOW)

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
var _samples: Array = []          # Vector2(time, angle) of stick samples pushed past FLICK_MIN_LEN
var _cooldown := 0.0
var _touch_age := 99.0            # seconds since the joystick thumb touched down
var _last_joy_index := -1
var _last_joy_center := Vector2.ZERO
var _a_down_at := -1.0
var _a_meter := false             # the last A press started the jump-shot meter
var _turbo_was := false
var _debug_log := false           # web build with ?debug_input in the URL: print gestures to the browser console

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
		game.do_pass(h, pass_target(game._input_vector()))
	elif game.possession != game.HUMAN_TEAM:
		switch_player()

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

	if not flick_ready():
		_samples.clear()
		return
	while _samples.size() > 0 and _time - _samples[0].x > FLICK_WINDOW:
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
