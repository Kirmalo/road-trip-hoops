extends RefCounted
# CPU defense brain for one player (player.def), plus shared block rules used by everyone.
# player.gd creates one in setup(); player.defense_ai() just calls cpu_update().

# ---- tuning ----
const GAP_FT := 5.5               # off-ball: stay this far off my man, on the hoop side
const GAP_BALL_FT := 2.5          # on the ball handler: this close
const WAIT_PAST_HALF_FT := 6.0    # no full-court press: wait this far past half court
const HELP_SIDE := 0.15           # off-ball: lean this fraction toward the ball
const DEF_SPEED_MULT := 0.9       # normal defensive speed
const POKE_RANGE_PX := 34.0       # poke at the ball handler inside this distance
const POKE_EVERY := 2.0           # seconds between pokes
const POKE_CHANCE := 0.06         # legacy flat steal chance (main.attempt_steal may ignore it)

# ---- blocks on jump timing (P2-07). A block needs a defender in a block jump (player.start_block_jump), close
# enough and high enough. Timing decides a good or a bad try; player.block_chance(good) scales a good one by the
# defender's block rating (Q6). No airborne defender = no block. ----
const BLOCK_HEIGHT_MIN := 0.6     # fraction of the block jump's height needed for a well-timed block
const RIM_BLOCK_REACH_FT := 4.0   # dunk/layup: an airborne defender this close to the shooter at the release
const DUNK_BLOCK_MULT := 0.6      # dunks are harder to block than layups (x this on the block chance)
const JUMPER_BLOCK_WINDOW := 0.25 # seconds after a jump shot (or a layup) leaves the hand that it can still be blocked
const JUMPER_BLOCK_REACH_FT := 3.5  # an airborne defender this close to the ball blocks the shot in that window
const LAYUP_AIR_BLOCKS := true    # layups can also be blocked on the way up, dunks only at the release
const LAYUP_AIR_WINDOW := 0.12    # seconds after a layup leaves the hand that it can still be blocked
const LAYUP_AIR_BLOCK_MULT := 0.5 # block chance x this on a layup already on its way up

# ---- CPU block jumps (P2-07) ----
const CPU_JUMP_FT := 6.0          # the CPU defender jumps at a shooter this close when the shot (or fake) starts
const CPU_JUMP_REACT_MIN := 0.12  # reaction delay in seconds, random between these
const CPU_JUMP_REACT_MAX := 0.3
const CPU_JUMP_CHANCE := 0.5      # chance he jumps at a real shot (at block rating 50)
const CPU_JUMP_RATING_SPAN := 0.3 # jump chance x(1 -/+ this) across block ratings 0..100: shot-blockers jump more
const CPU_FAKE_BITE := 0.45       # chance he jumps at a pump fake (bites; at block rating 50)
const CPU_JUMP_CHARGE := 0.65     # human shooter: he waits until the shot meter is this full (the shooter's rhythm)

var p        # the player this brain belongs to
var game

# block state (P2-07)
var rolled_shot := -1        # game.shot_serial this defender's block try was already rolled for (once per shot)
var _watch_phase := ""       # what the shooter I watch is doing: "", "shot", "fake" or "rim"
var _jump_wait := -1.0       # seconds until my block jump (< 0 = none planned)
var _was_air := false
var _air_saw_release := false  # a shot left the hand during my current block jump (else it was an early jump)

func _init(player, g) -> void:
	p = player
	game = g

# Man-to-man CPU defense: sets p.target, p.speed_mult, p.cpu_turbo_want.
func cpu_update(delta: float) -> void:
	var FT: float = game.FT
	var man = game.teams[1 - p.team][p.index]
	var guard_hoop: Vector2 = game.attack_hoop(man.team)
	var ball = game.ball
	var gap := GAP_FT * FT
	if ball.holder == man:
		gap = GAP_BALL_FT * FT
	var to_hoop: Vector2 = guard_hoop - man.position
	p.target = man.position + to_hoop.normalized() * minf(gap, to_hoop.length() * 0.5)
	if not game.in_frontcourt(man.position, man.team):
		# no full-court press: wait just past half court
		var toward: float = -game.inward(guard_hoop)
		p.target = Vector2(game.COURT_W / 2 + toward * WAIT_PAST_HALF_FT * FT, lerpf(man.position.y, game.COURT_H / 2, 0.3))
	if ball.holder != man and ball.state != ball.DEAD:
		p.target = p.target.lerp(ball.position, HELP_SIDE)  # help side
	p.speed_mult = DEF_SPEED_MULT
	# beaten by my man: sprint to recover
	var beaten: float = (p.position.distance_to(guard_hoop) - man.position.distance_to(guard_hoop)) / FT
	if beaten > p.CPU_BEATEN_FT and game.in_frontcourt(man.position, man.team):
		p.cpu_turbo_want = true
		p.speed_mult = 1.0
	# poke at the ball now and then (not while off balance)
	if ball.holder == man and p.position.distance_to(man.position) < POKE_RANGE_PX and p.stumble_t <= 0.0:
		p.steal_timer -= delta
		if p.steal_timer <= 0.0:
			p.steal_timer = POKE_EVERY
			game.attempt_steal(p, POKE_CHANCE)
	_update_block_jump(delta)

# The other team's shooter worth jumping at: the handler, or the shooter of a ball still in its block window.
func _shot_threat():
	var ball = game.ball
	if ball.state == ball.HELD and ball.holder != null and ball.holder.team != p.team:
		return ball.holder
	if ball.state == ball.SHOT and ball.shooter != null and ball.shooter.team != p.team \
			and ball.shot_t * ball.shot_time < JUMPER_BLOCK_WINDOW:
		return ball.shooter
	return null

# CPU block jumps: when the shooter near me starts a shot, a pump fake or a rim move, jump after a reaction delay.
func _update_block_jump(delta: float) -> void:
	var ball = game.ball
	var s = _shot_threat()
	var phase := ""
	if s != null:
		if s.rim_kind != "":
			phase = "rim"
		elif "fake_t" in s and s.fake_t > 0.0:
			phase = "fake"
		elif s.shooting or ball.state == ball.SHOT:
			phase = "shot"
	if phase != _watch_phase:
		_watch_phase = phase
		_jump_wait = -1.0
		if phase != "" and p.position.distance_to(s.position) < CPU_JUMP_FT * game.FT:
			_jump_wait = game.rng.randf_range(CPU_JUMP_REACT_MIN, CPU_JUMP_REACT_MAX)
	if _jump_wait < 0.0:
		return
	_jump_wait -= delta
	if _jump_wait > 0.0:
		return
	if phase == "shot" and s.shooting and game.is_human(s) and s.shot_charge < CPU_JUMP_CHARGE:
		return   # a human's meter: wait for his rhythm (a short tap turns into a fake and is judged as one)
	_jump_wait = -1.0
	var chance: float = CPU_FAKE_BITE if phase == "fake" else CPU_JUMP_CHANCE
	chance *= 1.0 + CPU_JUMP_RATING_SPAN * p.rating_frac("block")
	if game.rng.randf() < chance and p.start_block_jump():
		game.stat("cpu_block_jumps")
		if phase == "fake":
			game.stat("cpu_fake_bites")
			game.stat("cpu_fake_bites_t%d" % p.team)
	elif phase == "fake":
		game.stat("cpu_fake_reads")

# "good", "bad" or "wait" (still rising, not high yet): how well timed this defender's block jump is right now
static func _jump_timing(d) -> String:
	if d.block_height_frac() >= BLOCK_HEIGHT_MIN:
		return "good"
	if d.block_jump_t < d.BLOCK_JUMP_TIME * 0.5:
		return "wait"
	return "bad"

# The defender who blocks this dunk/layup as it leaves the hand, or null. kind is "dunk" or "layup".
static func rim_blocker(g, shooter, kind: String):
	var dunk := kind == "dunk"
	for d in g.teams[1 - shooter.team]:
		if d.block_jump_t < 0.0 or d.stumble_t > 0.0:
			continue   # only a defender in a block jump can block (no dice for the ones on the floor)
		if d.position.distance_to(shooter.position) > RIM_BLOCK_REACH_FT * g.FT:
			continue
		var tim := _jump_timing(d)
		if tim == "wait" and not dunk:
			continue   # still rising: a layup can be blocked on the way up (check_jump_shot_block)
		d.def.rolled_shot = g.shot_serial + 1   # the shot about to be released, if this try fails
		d.def._air_saw_release = true
		var good := tim == "good"
		g.stat("block_tries_good" if good else "block_tries_bad")
		var chance: float = d.block_chance(good) * (DUNK_BLOCK_MULT if dunk else 1.0)
		if g.rng.randf() < chance:
			return d
	return null

# Jump-shot (and layup) blocks on timing, every frame from main.gd: while the shot is in its first
# JUMPER_BLOCK_WINDOW seconds, an airborne defender near the ball gets one try per shot. Also counts early jumps.
static func check_jump_shot_block(g) -> void:
	var ball = g.ball
	for pl in g.players:
		var air: bool = pl.block_jump_t >= 0.0
		var dd = pl.def
		if air and not dd._was_air:
			dd._air_saw_release = false
		if air and ball.state == ball.SHOT:
			dd._air_saw_release = true
		if dd._was_air and not air and not dd._air_saw_release:
			g.stat("jumps_early")   # landed before any shot left the hand (jumped too soon, or at a fake)
			g.stat("jumps_early_t%d" % pl.team)
		dd._was_air = air
	if ball.state != ball.SHOT or ball.shooter == null:
		return
	if ball.shot_kind == "dunk" or (ball.shot_kind == "layup" and not LAYUP_AIR_BLOCKS):
		return
	var layup: bool = ball.shot_kind == "layup"
	if ball.shot_t * ball.shot_time >= (LAYUP_AIR_WINDOW if layup else JUMPER_BLOCK_WINDOW):
		return
	for d in g.teams[1 - ball.shooter.team]:
		if d.block_jump_t < 0.0 or d.def.rolled_shot == g.shot_serial:
			continue
		if d.position.distance_to(ball.position) > JUMPER_BLOCK_REACH_FT * g.FT:
			continue
		var tim := _jump_timing(d)
		if tim == "wait":
			continue
		d.def.rolled_shot = g.shot_serial
		var good := tim == "good"
		g.stat("block_tries_good" if good else "block_tries_bad")
		if g.rng.randf() < d.block_chance(good) * (LAYUP_AIR_BLOCK_MULT if layup else 1.0):
			g.stat("layup_air_blocks" if layup else "jumper_blocks")
			g.block_shot(d)
			return
