extends RefCounted
# CPU defense brain for one player (player.def), plus shared block rules used by everyone.
# player.gd creates one in setup(); player.defense_ai() just calls cpu_update().
# CPU skill knobs go through Difficulty.value(team, key, CONST) at the point of use (P3-03; Hard = the constant).

const Difficulty = preload("res://scripts/difficulty.gd")
const Twists = preload("res://scripts/twists.gd")   # foul_mult (era_grand, P9-08): x every foul call chance; 1.0 = today

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

# ---- fouls (P3-06; owner Q3: bad timing only). Both the human and the CPU can foul; the call itself (whistle, free
# throws, sideline ball) is rules.call_foul (P3-05). Target: about 3-6 fouls a game for both teams together. ----
const FOUL_BAD_JUMP_CHANCE := 0.5   # a badly timed block jump that reaches the shooter's body: chance it is a foul (P3-09: was 0.35)
const FOUL_CONTACT_FT := 3.0      # "reaches the shooter": the jumping defender is this close to the shooter's body
                                  # (tighter than the block reach: a bad jump further off just misses)
const FOUL_LATE_WINDOW := 0.2     # seconds after the block window that a late jump (still rising) into him fouls
const FOUL_LATE_MULT := 0.35      # a late jump fouls with FOUL_BAD_JUMP_CHANCE x this (late jumps at layups are
                                  # common and mostly catch only air: without it ~7 fouls a game)
const FOUL_FAKE_WINDOW := 0.4    # a bad jump that started this soon after the shooter's pump fake: "bit on the fake"
# reaching fouls (P3-09: rolled only here, in try_reach_foul; main.attempt_steal's own roll was removed)
const REACH_FOUL_CHANCE := 0.3    # CPU: a poke that reaches a ball behind the handler's body fouls with this chance
                                  # (replaces main.gd's old FOUL_REACH_CHANCE)
const REACH_FOUL_HUMAN_CHANCE := 0.1   # the human: lower, so a player who pokes a lot isn't whistled all game
                                  # (0.3 gave a STEAL-mashing humantest 2-5 reach fouls a game, of 3-6 in all)
const FOUL_SHIELD_DEG := 120.0    # shielded: the angle handler->ball vs handler->defender is at least this (exposure 0)
const CPU_SHIELD_REACH := 0.06    # CPU: ball shielded and his poke gap is up: chance he reaches in anyway (bad timing)
const FOUL_POPUP_COLOR := Color(1.0, 0.85, 0.2)
const FOUL_POPUP_SIZE := 34
const FOUL_POPUP_RISE_FT := 6.0   # the reason popup floats this far above the fouler (over rules' "FOUL!" popup)
const FOUL_REASONS := {           # what the popup over the fouler says, so the human sees why
	"early": "FOUL: TOO EARLY",   # came down on the shooter (jumped before the shot)
	"late": "FOUL: TOO LATE",     # jumped after the ball was gone, into his body
	"fake": "FOUL: BIT ON FAKE",  # still up from jumping at a pump fake
	"reach": "FOUL: REACH",       # poked through a shielded ball
}

# ---- CPU block jumps (P2-07) ----
const CPU_JUMP_FT := 6.0          # the CPU defender jumps at a shooter this close when the shot (or fake) starts
const CPU_JUMP_REACT_MIN := 0.12  # reaction delay in seconds, random between these
const CPU_JUMP_REACT_MAX := 0.3
const CPU_JUMP_CHANCE := 0.5      # chance he jumps at a dunk/layup (at block rating 50)
const CPU_JUMPER_JUMP_CHANCE := 0.2  # chance he jumps at a jump shot (P2-11: was CPU_JUMP_CHANCE 0.5; ~1 in 4 jumpers got blocked)
const CPU_JUMP_RATING_SPAN := 0.3 # jump chance x(1 -/+ this) across block ratings 0..100: shot-blockers jump more
const CPU_FAKE_BITE := 0.35       # chance he jumps at a pump fake (bites; at block rating 50; P2-11: was 0.45, P2-13: 0.4)
const CPU_JUMP_CHARGE := 0.65     # human shooter: he waits until the shot meter is this full (the shooter's rhythm)

# ---- P9-20 keep_block (Gate): his block is tipped to a teammate or to himself instead of swatted away ----
const KEEP_TIP_MAX_FT := 22.0     # a teammate this close to the ball can get the tip ...
const KEEP_TIP_OPEN_FT := 5.0     # ... if he is at least this open (else Gate keeps it himself)

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

# fouls (P3-06)
var foul_pending := ""       # a bad rim-block jump that fouled: called once the shot is in the air (call_pending_fouls)
var foul_rolled := -1        # game.shot_serial this defender's foul dice were rolled for (once per shot)

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
		p.target = p.target.lerp(ball.position, Difficulty.value(p.team, "help_side", HELP_SIDE))  # help side
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
	_cross_react = game.rng.randf_range(Difficulty.value(p.team, "cross_react_min", CPU_CROSS_REACT_MIN),
			Difficulty.value(p.team, "cross_react_max", CPU_CROSS_REACT_MAX))
	_cross_beat = _cross_react > Difficulty.value(p.team, "cross_beat_react", CPU_CROSS_BEAT_REACT)
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
		# P10-22 quick_hands: his steal_window_mult perk widens the floor-touch window he waits for (x1.0 without it)
		var touch: bool = game.steal_timing(h, game.STEAL_CPU_GRACE * game.steal_window_mult(p)) > 0.0
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
		if is_shielded(game, p, h) and game.rng.randf() < Difficulty.value(p.team, "shield_reach", CPU_SHIELD_REACH):
			game.stat("cpu_shield_reaches")   # reaches in at a shielded ball anyway (badly timed): may foul
			_poke(h)
		return
	if game.rng.randf() >= Difficulty.value(p.team, "poke_chance", CPU_POKE_CHANCE):
		_poke_gap = CPU_POKE_RECHECK
		return
	_poke_on_time = game.rng.randf() < Difficulty.value(p.team, "poke_on_time", CPU_POKE_ON_TIME) * (1.0 + CPU_POKE_RATING_SPAN * p.rating_frac("steal"))
	_poke_wait = CPU_POKE_WAIT_MAX

func _poke(h) -> void:
	_poke_wait = -1.0
	var crossing: bool = "cross_t" in h and h.cross_t > 0.0
	_poke_gap = CPU_POKE_CROSS_GAP if crossing else CPU_POKE_GAP
	game.stat("cpu_pokes")
	if try_reach_foul(game, p, h):
		return
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
		var reach_ft: float = CPU_JUMP_FT
		if phase == "rim" and p.signature == p.SIG_CHASE_DOWN and p.is_behind(s):
			reach_ft = p.CHASE_DOWN_JUMP_FT   # P10-17: the chase-down man goes up at a rim move from behind
		if phase != "" and p.position.distance_to(s.position) < reach_ft * game.FT:
			_jump_wait = game.rng.randf_range(Difficulty.value(p.team, "jump_react_min", CPU_JUMP_REACT_MIN),
					Difficulty.value(p.team, "jump_react_max", CPU_JUMP_REACT_MAX))
	if _jump_wait < 0.0:
		return
	_jump_wait -= delta
	if _jump_wait > 0.0:
		return
	if phase == "shot" and s.shooting and game.is_human(s) and s.shot_charge < CPU_JUMP_CHARGE:
		return   # a human's meter: wait for his rhythm (a short tap turns into a fake and is judged as one)
	_jump_wait = -1.0
	var chance: float = Difficulty.value(p.team, "jump_chance", CPU_JUMP_CHANCE)
	if phase == "fake":
		chance = Difficulty.value(p.team, "fake_bite", CPU_FAKE_BITE)
	elif phase == "shot":
		chance = Difficulty.value(p.team, "jumper_jump_chance", CPU_JUMPER_JUMP_CHANCE)
	chance *= 1.0 + CPU_JUMP_RATING_SPAN * p.rating_frac("block")
	if game.rng.randf() < chance and p.start_block_jump():
		game.stat("cpu_block_jumps")
		if phase == "fake":
			game.stat("cpu_fake_bites")
			game.stat("cpu_fake_bites_t%d" % p.team)
	elif phase == "fake":
		game.stat("cpu_fake_reads")

# "good", "bad" or "wait" (still rising, not high yet): how well timed this defender's block jump is right now.
# P9-24 block_window_mult (a mentor perk): his "good" stretch of the jump lasts that much longer, on each side of the
# peak (x1.0 = today's heights, untouched)
static func _jump_timing(d) -> String:
	return _jump_timing_at(d, d.perk("block_window_mult", 1.0))

static func _jump_timing_at(d, window_mult: float) -> String:
	var rising: bool = d.block_jump_t < d.BLOCK_JUMP_TIME * 0.5
	var need: float = BLOCK_HEIGHT_MIN
	if d.game.is_human(d):
		need = BLOCK_HUMAN_RISE_MIN if rising else BLOCK_HUMAN_FALL_MIN
	if window_mult != 1.0:
		need = _widened_need(need, window_mult)
	if d.block_height_frac() >= need:
		return "good"
	if rising:
		return "wait"
	return "bad"

# the height fraction that makes the time above it `mult` times as long: the jump is sin(PI x t), so a need n is good
# from asin(n) / PI to the peak (0.5); that half-window x mult, back to a height (never below 0)
static func _widened_need(need: float, mult: float) -> float:
	var half: float = 0.5 - asin(clampf(need, 0.0, 1.0)) / PI
	var edge: float = maxf(0.0, 0.5 - half * mult)
	return sin(PI * edge)

# P9-24: this good try was good only thanks to his block_window_mult perk (counted, and logged the first time)
static func _perk_block_check(d, good: bool, what: String) -> void:
	if good and d.perk_key != "" and _jump_timing_at(d, 1.0) != "good":
		d.perk_log("well timed %s block try (window x%.2f)" % [what, d.perk("block_window_mult", 1.0)])

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
		if d.position.distance_to(shooter.position) > (RIM_BLOCK_REACH_FT + _reach_bonus(g, d) + d.chase_down_reach(shooter)) * g.FT:
			continue   # (P10-17 chase_down: more reach from behind; + 0 for everyone else)
		var tim := _jump_timing(d)
		if tim == "wait" and not dunk:
			continue   # still rising: a layup can be blocked on the way up (check_jump_shot_block)
		d.def.rolled_shot = g.shot_serial + 1   # the shot about to be released, if this try fails
		d.def._air_saw_release = true
		var good := tim == "good"
		_count_try(g, d, good)
		_perk_block_check(d, good, kind)
		var chance: float = d.block_chance(good) * (DUNK_BLOCK_MULT if dunk else 1.0)
		var base_chance: float = chance
		chance = _chase_chance(d, shooter, chance)   # P10-17 chase_down from behind; the same chance for everyone else
		var roll: float = g.rng.randf()
		var sm: float = shooter.sig_block_mult(kind)   # P9-20 hook, P10-17 shoulder: x1.0 for everyone else
		if roll < chance * sm:
			_chase_log(g, d, shooter, true, roll >= base_chance * sm, kind)
			_shoulder_log(g, shooter, d, sm, true, kind)
			clear_pending_fouls(g, shooter)   # blocked: no foul on this shot
			return d
		_chase_log(g, d, shooter, false, false, kind)
		_shoulder_log(g, shooter, d, sm, false, kind)
		if roll < chance:
			_sig_escape(g, shooter, d)   # his layup went over a block that would have been
		if not good:
			# a bad jump into him at the release (late: still rising; early: coming down): maybe a foul, called once
			# the shot is in the air (player.release_rim_shot -> call_pending_fouls)
			var why: String = "late" if tim == "wait" else _early_reason(d, shooter)
			if _foul_roll(g, d, shooter, g.shot_serial + 1, why):
				d.def.foul_pending = why
	return null

# ---------------- signature moves (P9-20) ----------------
# Only for a player whose "signature" (player.gd) is the move; everyone else plays today's rules.

# the hook (or P10-17 shoulder) man's shot got past a block try that would have stopped anyone else (counted, logged)
static func _sig_escape(g, shooter, d) -> void:
	var sig: String = str(shooter.signature)
	g.stat("sig_%s_escapes_t%d" % [sig, shooter.team])
	shooter.sig_log(sig, "%s the block try of %s" % ["through" if sig == shooter.SIG_SHOULDER else "over",
			d.pname if d.pname != "" else d.pid])

# P10-17 chase_down: his block chance at `shooter` from behind (x CHASE_DOWN_MULT, at most 1.0); `chance` for anyone else
static func _chase_chance(d, shooter, chance: float) -> float:
	var m: float = d.chase_down_mult(shooter)
	return chance if m == 1.0 else minf(1.0, chance * m)

# P10-17 chase_down: a block try of his from behind (counted, logged; `extra`: only the chase-down made it a block)
static func _chase_log(g, d, shooter, blocked: bool, extra: bool, what: String) -> void:
	if d.chase_down_mult(shooter) == 1.0:
		return
	if blocked:
		g.stat("sig_chase_down_blocks_t%d" % d.team)
	if extra:
		g.stat("sig_chase_down_extra_t%d" % d.team)
	d.sig_log(d.SIG_CHASE_DOWN, "chase-down try from behind on %s's %s: %s" % [
			shooter.pname if shooter.pname != "" else shooter.pid, what,
			("blocked (only from behind)" if extra else "blocked") if blocked else "missed"])

# P10-17 shoulder: a block try at his close shot or dunk (block chance x SHOULDER_BLOCK_MULT; counted, logged)
static func _shoulder_log(g, shooter, d, sm: float, blocked: bool, what: String) -> void:
	if sm == 1.0 or str(shooter.signature) != shooter.SIG_SHOULDER:
		return
	if not blocked:
		g.stat("sig_shoulder_holds_t%d" % shooter.team)
	shooter.sig_log(shooter.SIG_SHOULDER, "%s through %s's block try (chance x%.2f): %s" % [what,
			d.pname if d.pname != "" else d.pid, sm, "blocked anyway" if blocked else "not blocked"])

# Gate's blocks stay in play: right after main.block_shot knocked the ball loose (away from him, often out of
# bounds), a keep_block blocker tips it instead to the most open teammate within KEEP_TIP_MAX_FT (at least
# KEEP_TIP_OPEN_FT open; a tip flies like a pass, so it can still be picked off), or keeps it himself (he catches his
# own block). Nobody else's block changes.
static func keep_block(g, d) -> void:
	if d == null or str(d.signature) != d.SIG_KEEP_BLOCK:
		return
	var ball = g.ball
	if ball.state != ball.LOOSE:
		return
	var to = null
	var best_open: float = KEEP_TIP_OPEN_FT
	for mate in g.teams[d.team]:
		if mate == d or mate.is_airborne() or mate.position.distance_to(ball.position) > KEEP_TIP_MAX_FT * g.FT:
			continue
		var o: float = g.openness(mate)
		if o >= best_open:
			best_open = o
			to = mate
	if to != null:
		ball.pass_to(d, to, 0)   # the tip (never a lob)
		g.stat("sig_keep_block_tips_t%d" % d.team)
		d.sig_log(d.SIG_KEEP_BLOCK, "block tipped to %s" % (to.pname if to.pname != "" else to.pid))
	else:
		ball.hold(d)
		g.stat("sig_keep_block_keeps_t%d" % d.team)
		d.sig_log(d.SIG_KEEP_BLOCK, "block kept: he caught his own swat")

# ---------------- fouls (P3-06) ----------------

# free throws are on (rules.ft_active, P3-05; false while that isn't merged)
static func ft_on(g) -> bool:
	return g.rules != null and "ft_active" in g.rules and bool(g.rules.ft_active)

# A bad block jump that reaches the shooter: rolls FOUL_BAD_JUMP_CHANCE once per shot (serial). Good timing never
# calls this. The CPU doesn't change its jumping to avoid fouls.
static func _foul_roll(g, d, shooter, serial: int, why: String) -> bool:
	if d.def.foul_rolled == serial:
		return false
	if d.position.distance_to(shooter.position) > FOUL_CONTACT_FT * g.FT:
		return false   # a bad jump, but not into his body: just a miss
	d.def.foul_rolled = serial
	g.stat("bad_jump_contacts_" + why)
	var chance: float = Difficulty.value(d.team, "foul_bad_jump", FOUL_BAD_JUMP_CHANCE)
	chance *= Twists.value("foul_mult", 1.0)   # era_grand: fewer whistles; 1.0 without a twist
	return g.rng.randf() < chance * (FOUL_LATE_MULT if why == "late" else 1.0)

# a jump that is already coming down at the release: "fake" if it started at the shooter's pump fake, else "early"
static func _early_reason(d, shooter) -> String:
	if "since_fake" in shooter:
		var after_fake: float = shooter.since_fake - d.block_jump_t
		if after_fake >= 0.0 and after_fake <= FOUL_FAKE_WINDOW:
			return "fake"
	return "early"

# called by player.release_rim_shot once the dunk/layup is in the air: the first pending bad-jump foul is called
static func call_pending_fouls(g, shooter) -> void:
	var fouler = null
	var why := ""
	for d in g.teams[1 - shooter.team]:
		if d.def.foul_pending != "" and fouler == null:
			fouler = d
			why = d.def.foul_pending
		d.def.foul_pending = ""
	if fouler != null:
		commit_foul(g, fouler, shooter, "shooting", why)

static func clear_pending_fouls(g, shooter) -> void:
	for d in g.teams[1 - shooter.team]:
		d.def.foul_pending = ""

# Counts the foul, shows why over the fouler, and calls the rules (P3-05; guarded so this branch runs alone).
# kind: "shooting" or "reach"; why: a FOUL_REASONS key.
static func commit_foul(g, d, fouled, kind: String, why: String) -> void:
	var human: bool = g.is_human(d)
	if g.rules != null and g.rules.has_method("call_foul"):
		if not g.rules.call_foul(d, fouled, kind):
			return   # the call was ignored (dead ball, free throws, a foul already pending): no popup, no stats
	else:
		g.stat("fouls_uncalled")   # rules.call_foul missing: counted, play goes on
		if human:
			g.stat("human_fouls")
	if kind == "reach":
		g.stat("fouls_shield_poke")
		g.stat("fouls_shield_poke_t%d" % d.team)
		if human:
			g.stat("human_fouls_reach")
	else:
		g.stat("foul_bad_jumps")
		g.stat("fouls_block")
		g.stat("fouls_block_t%d" % d.team)
		g.stat("fouls_block_" + why)
		if human:
			g.stat("human_fouls_block")
	if g.fx != null:
		var col: Color = FOUL_POPUP_COLOR if human else g.TEAM_COLORS[d.team]
		g.fx.popup(String(FOUL_REASONS.get(why, "FOUL")), d.position + Vector2(0, -FOUL_POPUP_RISE_FT * g.FT), col,
				FOUL_POPUP_SIZE + (6 if human else 0))

# The handler's body is between the defender and the ball: a poke now reaches through him.
static func is_shielded(g, d, h) -> bool:
	var ball = g.ball
	if h == null or d == null or ball.state != ball.HELD or ball.holder != h or h.team == d.team:
		return false
	if h.shooting or h.rim_kind != "" or ("fake_t" in h and h.fake_t > 0.0) or ("cross_t" in h and h.cross_t > 0.0):
		return false   # the ball is up or crossing in front: not shielded
	if d.position.distance_to(h.position) > g.STEAL_POKE_PX:
		return false
	var to_ball: Vector2 = ball.position - h.position
	var to_def: Vector2 = d.position - h.position
	if to_ball.length() < 0.01 or to_def.length() < 0.01:
		return false
	return rad_to_deg(absf(to_ball.angle_to(to_def))) >= FOUL_SHIELD_DEG

# A poke (human STEAL or CPU) that reaches the handler while the ball is behind his body (main.steal_exposure 0 and
# main._ball_behind_body, the same test main.attempt_steal uses): the one reach-foul roll. True if the poke was settled
# here (a foul, or a whiff off his body: a shielded ball can't be stolen), so the caller skips game.attempt_steal.
static func try_reach_foul(g, d, h) -> bool:
	var ball = g.ball
	if not g.REACH_FOULS or h == null or d == null or ball.state != ball.HELD or ball.holder != h or h.team == d.team:
		return false
	if d.stumble_t > 0.0 or d.steal_cooldown > 0.0 or ft_on(g):
		return false
	if d.position.distance_to(h.position) > g.STEAL_POKE_PX or g.steal_exposure(d, h) > 0.0 or not g._ball_behind_body(d, h):
		return false
	var human: bool = g.is_human(d)
	# what main.attempt_steal does for this poke (it could only miss)
	d.steal_cooldown = g.STEAL_COOLDOWN
	d.poke_t = g.STEAL_POKE_FREEZE
	g.stat("steal_pokes_t%d" % d.team)
	g.stat("steal_shielded")
	g.stat("steal_shielded_body")
	g.stat("shield_pokes_t%d" % d.team)
	if human:
		g.stat("human_steal_pokes")
		g.stat("human_shield_pokes")
	var chance: float = REACH_FOUL_HUMAN_CHANCE if human else Difficulty.value(d.team, "reach_foul", REACH_FOUL_CHANCE)
	chance *= Twists.value("foul_mult", 1.0)   # era_grand: fewer whistles; 1.0 without a twist
	if g.rng.randf() < chance:
		commit_foul(g, d, h, "reach", "reach")
	return true

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
	if ball.state != ball.SHOT or ball.shooter == null or ft_on(g):
		return   # (free throws: no blocks, no fouls)
	if ball.shot_kind == "dunk" or (ball.shot_kind == "layup" and not LAYUP_AIR_BLOCKS):
		return
	var layup: bool = ball.shot_kind == "layup"
	var window: float = LAYUP_AIR_WINDOW if layup else JUMPER_BLOCK_WINDOW
	var since: float = ball.shot_t * ball.shot_time
	if since >= window:
		_check_late_fouls(g, since, window)
		return
	for d in g.teams[1 - ball.shooter.team]:
		if d.block_jump_t < 0.0 or d.def.rolled_shot == g.shot_serial:
			continue
		if d.position.distance_to(ball.position) > (JUMPER_BLOCK_REACH_FT + _reach_bonus(g, d) + d.chase_down_reach(ball.shooter)) * g.FT:
			continue
		var tim := _jump_timing(d)
		if tim == "wait":
			continue
		d.def.rolled_shot = g.shot_serial
		var good := tim == "good"
		_count_try(g, d, good)
		_perk_block_check(d, good, "layup" if layup else "jumper")
		var c: float = d.block_chance(good) * (LAYUP_AIR_BLOCK_MULT if layup else 1.0)
		var base_c: float = c
		var shooter = ball.shooter
		c = _chase_chance(d, shooter, c)   # P10-17 chase_down from behind; the same chance for everyone else
		var roll: float = g.rng.randf()
		var sm: float = shooter.sig_block_mult(ball.shot_kind)   # P9-20 hook, P10-17 shoulder: x1.0 for everyone else
		var what: String = "layup" if layup else "jumper"
		if roll < c * sm:
			_chase_log(g, d, shooter, true, roll >= base_c * sm, what)
			_shoulder_log(g, shooter, d, sm, true, what)
			g.stat("layup_air_blocks" if layup else "jumper_blocks")
			g.block_shot(d)
			keep_block(g, d)   # P9-20: a keep_block blocker's swat stays in play
			return
		_chase_log(g, d, shooter, false, false, what)
		_shoulder_log(g, shooter, d, sm, false, what)
		if roll < c:
			_sig_escape(g, ball.shooter, d)   # the hook went over a block that would have been
		var why: String = _early_reason(d, ball.shooter)
		if not good and _foul_roll(g, d, ball.shooter, g.shot_serial, why):
			commit_foul(g, d, ball.shooter, "shooting", why)   # came down on him
			return

# Just after the block window: a defender who jumped after the ball was gone (too late to block it) and is still
# rising into the shooter can foul him (once per shot)
static func _check_late_fouls(g, since: float, window: float) -> void:
	if since >= window + FOUL_LATE_WINDOW:
		return
	var ball = g.ball
	for d in g.teams[1 - ball.shooter.team]:
		if d.block_jump_t < 0.0 or d.def.rolled_shot == g.shot_serial or d.def.foul_rolled == g.shot_serial:
			continue
		if d.block_jump_t >= since or _jump_timing(d) != "wait":
			continue   # jumped before the release, or already high: not a late jump into him
		if _foul_roll(g, d, ball.shooter, g.shot_serial, "late"):
			commit_foul(g, d, ball.shooter, "shooting", "late")
			return
