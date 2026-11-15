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
const SHOT_BLOCK_WINDOW := 0.3    # jump shot can be blocked in its first this-many seconds
const SHOT_BLOCK_RANGE_PX := 30.0 # defender must be this close to the shooter
const SHOT_BLOCK_CHANCE := 0.12

# rim blocks (dunks/layups), asked when the ball leaves the hand. Same odds as Phase 1.
const RIM_CONTEST_FT := 4.0       # nearest defender inside this can block (player.CONTEST_FT)
const DUNK_BLOCK_CHANCE := 0.18   # block chance with a defender right on you (less further away)
const LAYUP_BLOCK_CHANCE := 0.12

var p        # the player this brain belongs to
var game

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
	# contest jump shots
	if ball.state == ball.SHOT and ball.shooter == man and not ball.blocked_checked:
		ball.blocked_checked = true
		if ball.shot_t < SHOT_BLOCK_WINDOW and p.position.distance_to(man.position) < SHOT_BLOCK_RANGE_PX \
				and game.rng.randf() < SHOT_BLOCK_CHANCE:
			game.block_shot(p)

# The defender who blocks this dunk/layup as it leaves the hand, or null. kind is "dunk" or "layup".
static func rim_blocker(g, shooter, kind: String):
	var d = g.nearest_opponent(shooter)
	if d == null or d.stumble_t > 0.0:
		return null
	var c_ft: float = d.position.distance_to(shooter.position) / g.FT
	if c_ft >= RIM_CONTEST_FT:
		return null
	var close := clampf(1.5 * (1.0 - c_ft / RIM_CONTEST_FT), 0.0, 1.0)
	var chance := (DUNK_BLOCK_CHANCE if kind == "dunk" else LAYUP_BLOCK_CHANCE) * close
	chance *= 1.0 + d.RIM_BLOCK_RATING_SPAN * d.rating_frac("block")   # shot-blockers block more
	if g.rng.randf() < chance:
		return d
	return null

# Jump-shot blocks on timing (P2-07 fills this in; called every frame from main.gd).
# Use defender.block_chance(good_timing) for the odds so the block rating counts.
static func check_jump_shot_block(_g) -> void:
	pass
