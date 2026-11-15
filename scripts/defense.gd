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

# ---- CPU defense reads the moves (P2-08) ----
# pokes: only at an exposed ball, timed on the dribble's floor touch (main.steal_timing) when he's sharp enough
const CPU_POKE_EXPOSURE := 0.5    # pokes only when main.steal_exposure() is at least this
const CPU_POKE_GAP := 2.0         # seconds between his pokes at most
const CPU_POKE_CROSS_GAP := 0.6   # ... against a handler in a crossover (the ball crosses in front: poke more)
const CPU_POKE_RECHECK := 0.25    # ball shielded (or he passed on it): look again this soon
const CPU_POKE_CHANCE := 0.3      # when the ball is exposed and the gap is up: chance he goes for it now
const CPU_POKE_ON_TIME := 0.11    # chance he times a poke on the dribble's floor touch, at steal 50; otherwise he
                                  # mistimes it (pokes while the ball is up). This sets how many CPU steals there are
const CPU_POKE_RATING_SPAN := 0.3 # on-time chance x(1 -/+ this) across steal ratings 0..100
const CPU_POKE_WAIT_MAX := 0.4    # he waits at most this long for his moment, then pokes anyway
# crossovers: a reaction time; too slow and the crossover beats him (P2-05 asks beaten_by_cross())
const CPU_CROSS_REACT_MIN := 0.2  # seconds he keeps going the old way after a crossover starts, random between these
const CPU_CROSS_REACT_MAX := 0.4
const CPU_CROSS_BEAT_REACT := 0.33  # a reaction slower than this: beaten (about 35% of crossovers)
const CPU_RECOVER_TIME := 1.2     # after being beaten he sprints this long to recover
# close guarding: on the ball he stays in front of the way the handler is going, so the handler is slowed
const CPU_GUARD_LEAD := 0.6       # how much the handler's movement turns the "in front" spot (0 = hoop side only)
const CPU_ON_BALL_SPEED := 1.0    # speed multiplier while guarding the ball (others use DEF_SPEED_MULT)

# ---- blocks on jump timing (P2-07). A block needs a defender in a block jump (player.start_block_jump), close
# enough and high enough. Timing decides a good or a bad try; player.block_chance(good) scales a good one by the
# defender's block rating (Q6). No airborne defender = no block. ----
const BLOCK_HEIGHT_MIN := 0.6     # fraction of the block jump's height needed for a well-timed block (CPU)
# the human's window (P2.5: blocks were too hard): wider on the way up, a little stricter on the way down, so a late
# jump still counts and a jump that is already coming down when the ball goes up (too early, or at a fake) doesn't
const BLOCK_HUMAN_RISE_MIN := 0.35  # human, still rising: this fraction of the jump height is enough (was 0.6)
const BLOCK_HUMAN_FALL_MIN := 0.8   # human, coming down: needs this much (was 0.6)
const BLOCK_HUMAN_REACH_FT := 0.5  # human: this much more reach on RIM_BLOCK_REACH_FT and JUMPER_BLOCK_REACH_FT
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
const CPU_JUMP_CHANCE := 0.5      # chance he jumps at a dunk/layup (at block rating 50)
const CPU_JUMPER_JUMP_CHANCE := 0.2  # chance he jumps at a jump shot (P2-11: was CPU_JUMP_CHANCE 0.5; ~1 in 4 jumpers got blocked)
const CPU_JUMP_RATING_SPAN := 0.3 # jump chance x(1 -/+ this) across block ratings 0..100: shot-blockers jump more
const CPU_FAKE_BITE := 0.35       # chance he jumps at a pump fake (bites; at block rating 50; P2-11: was 0.45, P2-13: 0.4)
const CPU_JUMP_CHARGE := 0.65     # human shooter: he waits until the shot meter is this full (the shooter's rhythm)

var p        # the player this brain belongs to
var game

# block state (P2-07)
var rolled_shot := -1        # game.shot_serial this defender's block try was already rolled for (once per shot)
var _watch_phase := ""       # what the shooter I watch is doing: "", "shot", "fake" or "rim"
var _jump_wait := -1.0       # seconds until my block jump (< 0 = none planned)
var _was_air := false
var _air_saw_release := false  # a shot left the hand during my current block jump (else it was an early jump)

# poke and crossover state (P2-08)
var _poke_gap := 0.0         # seconds until he may poke again
var _poke_wait := -1.0       # waiting for his moment to poke (seconds left; < 0 = not waiting)
var _poke_on_time := false   # this poke waits for the floor touch (else for the ball to be up: a mistimed poke)
var _cross_seen := false     # reacting to the current crossover
var _cross_react := 0.0      # seconds left of his reaction to it
var _cross_beat := false     # this crossover beats him
var _cross_target := Vector2.ZERO   # where he was heading when the crossover started (he keeps going there)
var _recover_t := 0.0        # seconds left of a recovery sprint

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
	var front: Vector2 = to_hoop.normalized()
	if ball.holder == man and man.velocity.length() > 20.0:
		# close guarding: stay in front of where he's going (that's what slows a driver), still on the hoop side
		front = (front + man.velocity / man.speed * CPU_GUARD_LEAD).normalized()
		if front.dot(to_hoop) <= 0.0:
			front = to_hoop.normalized()
	p.target = man.position + front * minf(gap, to_hoop.length() * 0.5)
	if not game.in_frontcourt(man.position, man.team):
		# no full-court press: wait just past half court
		var toward: float = -game.inward(guard_hoop)
		p.target = Vector2(game.COURT_W / 2 + toward * WAIT_PAST_HALF_FT * FT, lerpf(man.position.y, game.COURT_H / 2, 0.3))
	if ball.holder != man and ball.state != ball.DEAD:
		p.target = p.target.lerp(ball.position, HELP_SIDE)  # help side
	p.speed_mult = CPU_ON_BALL_SPEED if ball.holder == man else DEF_SPEED_MULT
	# beaten by my man: sprint to recover
	var beaten: float = (p.position.distance_to(guard_hoop) - man.position.distance_to(guard_hoop)) / FT
	if beaten > p.CPU_BEATEN_FT and game.in_frontcourt(man.position, man.team):
		p.cpu_turbo_want = true
		p.speed_mult = 1.0
	_update_crossover(delta, man)
	_update_pokes(delta, man)
	_update_block_jump(delta)

# Called by player.gd (P2-05) when a crossover starts near this CPU defender: true if it beats him (he stumbles).
# Picks his reaction time for this crossover (beaten if slower than CPU_CROSS_BEAT_REACT, about 35%);
# cpu_update keeps him going the old way while he reacts.
func beaten_by_cross(_handler, _dir: Vector2 = Vector2.ZERO) -> bool:
	_start_cross_read()
	return _cross_beat

# Called by player.gd (P2-06) when a pump fake starts. Nothing to do here: _update_block_jump reads the faker's
# fake_t every frame (a human fake has shooting false and fake_t > 0) and rolls CPU_FAKE_BITE once per fake.
func on_pump_fake(_faker) -> void:
	pass

func _start_cross_read() -> void:
	_cross_seen = true
	_cross_react = game.rng.randf_range(CPU_CROSS_REACT_MIN, CPU_CROSS_REACT_MAX)
	_cross_beat = _cross_react > CPU_CROSS_BEAT_REACT
	_cross_target = p.target
	if not _cross_beat:
		_poke_gap = 0.0   # he read it: the ball is crossing in front of him, go for it

func _update_crossover(delta: float, man) -> void:
	var h = game.ball.holder
	var crossing: bool = h == man and "cross_t" in h and h.cross_t > 0.0
	if crossing and not _cross_seen:
		_start_cross_read()
	if _cross_seen:
		if _cross_react > 0.0:
			_cross_react -= delta
			p.target = _cross_target   # still reacting: keeps going the old way
			if _cross_react <= 0.0:
				if p.stumble_t > 0.0:
					_recover_t = CPU_RECOVER_TIME   # beaten: sprint back once he has his balance
					game.stat("recover_sprints")
				else:
					game.stat("cpu_cross_reads")    # inside his reaction window, but it didn't beat him
		elif not crossing:
			_cross_seen = false
	if _recover_t > 0.0:
		_recover_t -= delta
		p.cpu_turbo_want = true
		p.speed_mult = 1.0

# Pokes at an exposed ball, timed on the dribble's floor touch when he's sharp enough.
func _update_pokes(delta: float, man) -> void:
	_poke_gap -= delta
	var h = game.ball.holder
	if h != man or p.position.distance_to(man.position) >= POKE_RANGE_PX or p.stumble_t > 0.0 \
			or p.poke_t > 0.0 or p.steal_cooldown > 0.0 or p.is_airborne():
		_poke_wait = -1.0
		return
	var exposed: bool = game.steal_exposure(p, h) >= CPU_POKE_EXPOSURE
	if _poke_wait >= 0.0:
		_poke_wait -= delta
		var touch: bool = game.steal_timing(h, game.STEAL_CPU_GRACE) > 0.0
		if exposed and touch == _poke_on_time:
			if touch:
				game.stat("cpu_pokes_timed")
			_poke(h)
		elif _poke_wait < 0.0:
			_poke(h)   # waited too long: pokes anyway
		return
	if _poke_gap > 0.0:
		return
	if not exposed:
		game.stat("cpu_poke_skipped_shielded")
		_poke_gap = CPU_POKE_RECHECK
		return
	if game.rng.randf() >= CPU_POKE_CHANCE:
		_poke_gap = CPU_POKE_RECHECK
		return
	_poke_on_time = game.rng.randf() < CPU_POKE_ON_TIME * (1.0 + CPU_POKE_RATING_SPAN * p.rating_frac("steal"))
	_poke_wait = CPU_POKE_WAIT_MAX

func _poke(h) -> void:
	_poke_wait = -1.0
	var crossing: bool = "cross_t" in h and h.cross_t > 0.0
	_poke_gap = CPU_POKE_CROSS_GAP if crossing else CPU_POKE_GAP
	game.stat("cpu_pokes")
	game.attempt_steal(p)

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
	var chance: float = CPU_JUMP_CHANCE
	if phase == "fake":
		chance = CPU_FAKE_BITE
	elif phase == "shot":
		chance = CPU_JUMPER_JUMP_CHANCE
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
	var rising: bool = d.block_jump_t < d.BLOCK_JUMP_TIME * 0.5
	var need: float = BLOCK_HEIGHT_MIN
	if d.game.is_human(d):
		need = BLOCK_HUMAN_RISE_MIN if rising else BLOCK_HUMAN_FALL_MIN
	if d.block_height_frac() >= need:
		return "good"
	if rising:
		return "wait"
	return "bad"

static func _reach_bonus(g, d) -> float:
	return BLOCK_HUMAN_REACH_FT if g.is_human(d) else 0.0

static func _count_try(g, d, good: bool) -> void:
	g.stat("block_tries_good" if good else "block_tries_bad")
	if g.is_human(d):
		g.stat("human_block_tries_good" if good else "human_block_tries_bad")

# The defender who blocks this dunk/layup as it leaves the hand, or null. kind is "dunk" or "layup".
static func rim_blocker(g, shooter, kind: String):
	var dunk := kind == "dunk"
	for d in g.teams[1 - shooter.team]:
		if d.block_jump_t < 0.0 or d.stumble_t > 0.0:
			continue   # only a defender in a block jump can block (no dice for the ones on the floor)
		if d.position.distance_to(shooter.position) > (RIM_BLOCK_REACH_FT + _reach_bonus(g, d)) * g.FT:
			continue
		var tim := _jump_timing(d)
		if tim == "wait" and not dunk:
			continue   # still rising: a layup can be blocked on the way up (check_jump_shot_block)
		d.def.rolled_shot = g.shot_serial + 1   # the shot about to be released, if this try fails
		d.def._air_saw_release = true
		var good := tim == "good"
		_count_try(g, d, good)
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
		if d.position.distance_to(ball.position) > (JUMPER_BLOCK_REACH_FT + _reach_bonus(g, d)) * g.FT:
			continue
		var tim := _jump_timing(d)
		if tim == "wait":
			continue
		d.def.rolled_shot = g.shot_serial
		var good := tim == "good"
		_count_try(g, d, good)
		if g.rng.randf() < d.block_chance(good) * (LAYUP_AIR_BLOCK_MULT if layup else 1.0):
			g.stat("layup_air_blocks" if layup else "jumper_blocks")
			g.block_shot(d)
			return
