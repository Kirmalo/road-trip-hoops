extends Node2D
# One basketball player. Either driven by the touch controls (the human) or by the CPU brain below.

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

func has_ball() -> bool:
	return game.ball.state == game.ball.HELD and game.ball.holder == self

func update(delta: float, is_human: bool, input_vec: Vector2) -> void:
	steal_cooldown = max(0.0, steal_cooldown - delta)
	var desired := Vector2.ZERO
	if shooting:
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
	else:
		ai(delta)
		desired = seek(target, speed_mult)
	velocity = velocity.move_toward(desired, 1600.0 * delta)
	position += velocity * delta
	position = game.clamp_to_court(position)
	# face where we are going, or the ball when standing still
	var look := velocity
	if look.length() < 15.0:
		look = game.ball.position - position
	if look.length() > 1.0:
		facing = lerp_angle(facing, look.angle(), min(1.0, 10.0 * delta))
	sprite.rotation = facing
	queue_redraw()

func seek(t: Vector2, mult: float) -> Vector2:
	var to := t - position
	var d := to.length()
	if d < 5.0:
		return Vector2.ZERO
	return to / d * speed * mult * min(1.0, d / 35.0)

# ---------------- shooting ----------------

func start_shot() -> void:
	if has_ball() and not shooting:
		shooting = true
		shot_charge = 0.0
		cpu_shot_time = game.rng.randf_range(0.3, 0.45)

func release_shot() -> void:
	if not shooting:
		return
	shooting = false
	var quality := 1.0
	if game.is_human(self):
		var c := shot_charge
		if c >= 0.78 and c <= 0.95:
			quality = 1.3
			game.show_message("PERFECT RELEASE", 0.8)
		elif c >= 0.6 and c <= 1.05:
			quality = 1.0
		else:
			quality = 0.6
	else:
		quality = game.rng.randf_range(0.85, 1.1)
	game.release_shot(self, quality)

# ---------------- CPU brain ----------------

func ai(delta: float) -> void:
	var ball = game.ball
	speed_mult = 1.0
	var my_hoop: Vector2 = game.attack_hoop(team)

	# chase loose balls and rebounds
	if ball.state == ball.LOOSE:
		if game.is_chaser(self):
			target = ball.position
			return
	if ball.state == ball.SHOT and ball.shot_t > 0.4 and game.is_chaser(self):
		target = ball.shot_hoop + Vector2(game.inward(ball.shot_hoop) * 6.0 * game.FT, 0)
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

func handler_ai(delta: float, hoop: Vector2) -> void:
	var FT: float = game.FT
	var to_hoop := hoop - position
	var dist_ft := to_hoop.length() / FT
	speed_mult = 1.0
	if not game.in_frontcourt(position, team):
		target = spot_pos(hoop, 0)
		return
	# drive to the rim, sidestepping a defender who is in the way
	target = hoop + Vector2(game.inward(hoop) * 3.0 * FT, 0)
	var d: Vector2 = to_hoop.normalized()
	var def = game.nearest_opponent(self)
	var open_ft := 99.0
	if def != null:
		var r: Vector2 = def.position - position
		open_ft = r.length() / FT
		if open_ft < 5.0 and r.dot(d) > 0.0:
			var side := 1.0 if d.cross(r) > 0.0 else -1.0
			target = position + (d * 0.4 - d.orthogonal() * side) * 120.0
	decision_timer -= delta
	if decision_timer > 0.0:
		return
	decision_timer = game.rng.randf_range(0.3, 0.5)
	var p: float = game.shot_probability(self, 1.0)
	if dist_ft < 4.5:
		start_shot()
	elif game.shot_clock < 4.0 and dist_ft < 32.0:
		start_shot()
	elif p > 0.40 and open_ft > 4.0 and game.rng.randf() < 0.5:
		start_shot()
	elif open_ft > 6.0 and dist_ft < 26.0 and game.rng.randf() < 0.3:
		start_shot()
	elif game.rng.randf() < 0.15:
		var best = null
		var best_open := open_ft + 2.0
		for mate in game.teams[team]:
			if mate == self or not game.in_frontcourt(mate.position, team):
				continue
			var o: float = game.openness(mate)
			if o > best_open:
				best_open = o
				best = mate
		if best != null:
			game.do_pass(self, best)

func defense_ai(delta: float) -> void:
	var FT: float = game.FT
	var man = game.teams[1 - team][index]
	var guard_hoop: Vector2 = game.attack_hoop(man.team)
	var ball = game.ball
	var gap := 5.5 * FT
	if ball.holder == man:
		gap = 2.5 * FT
	var to_hoop: Vector2 = guard_hoop - man.position
	target = man.position + to_hoop.normalized() * min(gap, to_hoop.length() * 0.5)
	if not game.in_frontcourt(man.position, man.team):
		# no full-court press: wait just past half court
		var toward: float = -game.inward(guard_hoop)
		target = Vector2(game.COURT_W / 2 + toward * 6.0 * FT, lerpf(man.position.y, game.COURT_H / 2, 0.3))
	if ball.holder != man and ball.state != ball.DEAD:
		target = target.lerp(ball.position, 0.15)  # help side
	speed_mult = 0.9
	# poke at the ball now and then
	if ball.holder == man and position.distance_to(man.position) < 34.0:
		steal_timer -= delta
		if steal_timer <= 0.0:
			steal_timer = 2.0
			game.attempt_steal(self, 0.06)
	# contest jump shots
	if ball.state == ball.SHOT and ball.shooter == man and not ball.blocked_checked:
		ball.blocked_checked = true
		if ball.shot_t < 0.3 and position.distance_to(man.position) < 30.0 and game.rng.randf() < 0.12:
			game.block_shot(self)

func _draw() -> void:
	if game.is_human(self):
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 32, Color(1, 0.9, 0.2), 3.0)
		var tri := PackedVector2Array([Vector2(-7, -44), Vector2(7, -44), Vector2(0, -34)])
		draw_colored_polygon(tri, Color(1, 0.9, 0.2))
	if shooting and game.is_human(self):
		var w := 56.0
		var o := Vector2(-w / 2, -58)
		draw_rect(Rect2(o, Vector2(w, 10)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(o + Vector2(w * 0.78 / 1.2, 0), Vector2(w * 0.17 / 1.2, 10)), Color(0.2, 0.9, 0.3))
		var c: float = min(shot_charge, 1.2) / 1.2
		draw_rect(Rect2(o + Vector2(w * c - 2, -3), Vector2(4, 16)), Color.WHITE)
