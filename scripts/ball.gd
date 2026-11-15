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
	receiver = null
	shooter = null
	vel = Vector2.ZERO
	game.on_ball_held(p)

func pass_to(from_p, to_p) -> void:
	state = PASS
	passer = from_p
	receiver = to_p
	holder = null
	intercept_checked = {}
	z = 18.0

func shoot(p, hoop: Vector2, made: bool, points: int) -> void:
	state = SHOT
	shooter = p
	holder = null
	shot_start = position
	shot_hoop = hoop
	shot_t = 0.0
	var dist := position.distance_to(hoop)
	shot_time = 0.55 + dist / 900.0
	shot_peak = 40.0 + dist * 0.22
	shot_made = made
	shot_points = points
	blocked_checked = false

func make_loose(from: Vector2, v: Vector2, height := 20.0, up := 150.0) -> void:
	state = LOOSE
	holder = null
	receiver = null
	position = from
	vel = v
	z = height
	vz = up

func make_dead() -> void:
	state = DEAD
	holder = null
	receiver = null

func update(delta: float) -> void:
	anim_time += delta
	match state:
		HELD:
			if holder == null:
				return
			var dir := Vector2.from_angle(holder.facing)
			position = holder.position + dir * 15.0
			if holder.shooting:
				z = 26.0
			else:
				z = 4.0 + abs(sin(anim_time * 9.0)) * 16.0
		PASS:
			if receiver == null:
				make_loose(position, Vector2.ZERO)
				return
			var to: Vector2 = receiver.position - position
			var step := PASS_SPEED * delta
			if to.length() <= max(step, 16.0):
				hold(receiver)
				return
			position += to.normalized() * step
			# defenders near the passing lane may pick it off
			for p in game.players:
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
					game.on_shot_made(shooter, shot_points)
				else:
					# rim out: bounce back toward the court
					var inward := 1.0 if shot_hoop.x < game.COURT_W / 2 else -1.0
					var ang: float = game.rng.randf_range(-1.2, 1.2)
					var v: Vector2 = Vector2(inward, 0).rotated(ang) * game.rng.randf_range(140.0, 280.0)
					make_loose(shot_hoop + v.normalized() * 10.0, v, 30.0, 220.0)
					game.on_shot_missed(shooter)
				return
			position = shot_start.lerp(shot_hoop, shot_t)
			z = 26.0 * (1.0 - shot_t) + 4.0 * shot_peak * shot_t * (1.0 - shot_t)
		LOOSE:
			position += vel * delta
			vel *= pow(0.35, delta)
			vz -= GRAVITY * delta
			z += vz * delta
			if z <= 0.0:
				z = 0.0
				vz = abs(vz) * 0.55
				if vz < 40.0:
					vz = 0.0
			# bounce off the edges of the court
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

func _draw() -> void:
	# shadow on the floor
	var r := 7.0 - minf(z, 60.0) / 20.0
	draw_set_transform(Vector2(0, 3), 0, Vector2(1, 0.55))
	draw_circle(Vector2.ZERO, max(r, 3.0), Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
