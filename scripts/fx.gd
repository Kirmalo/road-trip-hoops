extends Node2D
# Visual feedback layer: screen shake, floating text popups and a ball trail.
# Every function is safe to call any time (also before the game has fully started).
#
#   game.fx.shake(6.0, 0.3)                                   # strength in pixels, time in seconds
#   game.fx.popup("+2", hoop_pos, Color.WHITE, 40)            # world position, font size in pixels
#   game.fx.set_trail(true, Color(1.0, 0.45, 0.1))            # fire trail behind game.ball
#   game.fx.set_trail(false)
#   game.fx.dust(floor_pos, 0.7)                              # ANGLED only: a dust puff on the floor (0..1)
#
# Phase 4 (P4-10): positions are sim positions. In ANGLED, popups are placed through View.to_screen (callers' "above"
# offsets are foreshortened by the tilt, so the popup is lifted to head height, or rim height near a hoop), the fire
# trail follows the ball as drawn (ball.v_screen) and sorts just under it in game.world, and dust lies in game.decals.
# FLAT looks exactly as before.

const View = preload("res://scripts/view.gd")

const POPUP_TIME := 1.0           # seconds a popup stays on screen
const POPUP_RISE := 46.0          # pixels a popup floats up over its life
const POPUP_POP_TIME := 0.12      # quick scale-in at the start
const POPUP_POP_SCALE := 1.5      # start scale of the scale-in
const POPUP_OUTLINE := 6          # outline thickness in pixels
const TRAIL_LENGTH := 20          # number of remembered ball positions
const TRAIL_RADIUS := 8.5         # radius of the newest trail puff (the ball is about 7)
const TRAIL_HOT := Color(1.0, 0.92, 0.35)   # color near the ball; set_trail's color fades in behind it
const SHAKE_HZ := 30.0            # how often the shake changes direction per second
# ANGLED (P4-10)
const POPUP_HEAD_LIFT := 80.0     # popups are lifted this much (sim px of height) over their projected point ...
const POPUP_RIM_LIFT := 150.0     # ... or this much (above the rim, View.RIM_Z 120) when the point is near a hoop
const POPUP_HOOP_FT := 9.0        # "near a hoop": within this of the hoop's floor point
const DUST_TIME := 0.45           # seconds a dust puff lasts
const DUST_R := 14.0              # sim px: radius a full-strength puff grows to (on the floor, foreshortened)
const DUST_COLOR := Color(0.85, 0.8, 0.7)

var game
var _popups: Array = []           # each: {text, pos, color, size, t}
var _font: Font
var _shake_strength := 0.0
var _shake_time := 0.0
var _shake_left := 0.0
var _shake_tick := 0.0
var _trail_on := false
var _trail_color := Color(1.0, 0.45, 0.1)
var _trail: Array = []            # Vector2 points, oldest first
var _trail_node: Node2D
var _rng := RandomNumberGenerator.new()
var _dust: Array = []             # ANGLED: each {pos (sim), k (strength), t}
var _dust_node: Node2D            # in game.decals (made on the first puff)

func _ready() -> void:
	_rng.randomize()
	z_index = 50
	_font = ThemeDB.fallback_font
	# the trail sits just under the ball (ball z_index is 20), the popups above everything
	_trail_node = Node2D.new()
	_trail_node.z_as_relative = false
	_trail_node.z_index = 19
	_trail_node.draw.connect(_draw_trail)
	add_child(_trail_node)

# ---------------- public API ----------------

func shake(strength: float, time: float) -> void:
	if game != null:
		game.stat("shakes")
	if time <= 0.0 or strength <= 0.0:
		return
	# a new shake never weakens one that is already running
	if strength >= _current_shake_strength():
		_shake_strength = strength
		_shake_time = time
		_shake_left = time
	_shake_tick = 0.0

func popup(text: String, world_pos: Vector2, color: Color, size: int) -> void:
	if game != null:
		game.stat("popups")
	_popups.append({"text": text, "pos": _popup_screen(world_pos), "color": color, "size": maxi(8, size), "t": 0.0})
	queue_redraw()

func set_trail(on: bool, color := Color(1.0, 0.45, 0.1)) -> void:
	_trail_on = on
	_trail_color = color

# a dust puff on the floor at sim point pos (strength 0..1); ANGLED only, FLAT draws no dust here
func dust(pos: Vector2, strength := 1.0) -> void:
	if not View.angled() or game == null or game.get("decals") == null:
		return
	if _dust_node == null:
		_dust_node = Node2D.new()
		_dust_node.name = "BallDust"
		_dust_node.draw.connect(_draw_dust)
		game.decals.add_child(_dust_node)
	game.stat("dust_puffs")
	_dust.append({"pos": pos, "k": clampf(strength, 0.0, 1.0), "t": 0.0})

# where a popup for sim point p goes on screen (FLAT: p itself)
func _popup_screen(p: Vector2) -> Vector2:
	if not View.angled():
		return p
	var lift := POPUP_HEAD_LIFT
	if game != null and game.get("hoops") != null:
		for h in game.hoops:
			if (h as Vector2).distance_to(p) < POPUP_HOOP_FT * View.FT:
				lift = POPUP_RIM_LIFT
	return View.to_screen(p, lift)

# ---------------- update ----------------

func _process(delta: float) -> void:
	_update_shake(delta)
	_update_trail()
	if not _dust.is_empty():
		for d in _dust:
			d.t += delta
		_dust = _dust.filter(func(d): return d.t < DUST_TIME)
		_dust_node.queue_redraw()
	if not _popups.is_empty():
		for p in _popups:
			p.t += delta
		_popups = _popups.filter(func(p): return p.t < POPUP_TIME)
		queue_redraw()

func _current_shake_strength() -> float:
	if _shake_left <= 0.0 or _shake_time <= 0.0:
		return 0.0
	return _shake_strength * (_shake_left / _shake_time)

func _update_shake(delta: float) -> void:
	if game == null or game.camera == null:
		return
	var cam: Camera2D = game.camera
	if _shake_left <= 0.0:
		return
	_shake_left -= delta
	if _shake_left <= 0.0:
		_shake_left = 0.0
		cam.offset = Vector2.ZERO
		return
	_shake_tick -= delta
	if _shake_tick <= 0.0:
		_shake_tick = 1.0 / SHAKE_HZ
		var s := _current_shake_strength()
		cam.offset = Vector2(_rng.randf_range(-s, s), _rng.randf_range(-s, s))

func _update_trail() -> void:
	var b = game.ball if game != null else null
	if View.angled() and b != null:
		if _trail_node.get_parent() != game.world:
			# ANGLED: the trail lives in the y-sorted world, sorted just under the ball
			_trail_node.reparent(game.world, false)
			_trail_node.z_as_relative = true
			_trail_node.z_index = 0
		var sy: float = b.v_sort_y - 0.01
		if absf(_trail_node.position.y - sy) > 0.001:
			_trail_node.position = Vector2(0, sy)
			_trail_node.queue_redraw()
	if _trail_on and b != null:
		if View.angled():
			_trail.append(b.v_screen)
		else:
			var bz: float = b.z
			var bpos: Vector2 = b.position
			_trail.append(bpos + Vector2(0, -bz))
		while _trail.size() > TRAIL_LENGTH:
			_trail.pop_front()
		_trail_node.queue_redraw()
	elif not _trail.is_empty():
		# fade out: drop the oldest point each frame
		_trail.pop_front()
		_trail_node.queue_redraw()

# ---------------- drawing ----------------

func _draw() -> void:
	for p in _popups:
		var k: float = p.t / POPUP_TIME
		var scale_k := 1.0
		if p.t < POPUP_POP_TIME:
			scale_k = lerpf(POPUP_POP_SCALE, 1.0, p.t / POPUP_POP_TIME)
		var alpha := 1.0 if k < 0.6 else 1.0 - (k - 0.6) / 0.4
		var size: int = p.size
		var text: String = p.text
		var center: Vector2 = p.pos + Vector2(0, -POPUP_RISE * k)
		var w: Vector2 = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var base := Vector2(-w.x / 2.0, size * 0.35)   # center the text on the point
		var col: Color = p.color
		col.a *= alpha
		var outline := Color(0.05, 0.05, 0.1, 0.9 * alpha)
		draw_set_transform(center, 0.0, Vector2(scale_k, scale_k))
		draw_string_outline(_font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, POPUP_OUTLINE, outline)
		draw_string(_font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_trail() -> void:
	var n := _trail.size()
	for i in n:
		var k := float(i + 1) / float(n)       # 0 = oldest, 1 = newest
		var col := _trail_color.lerp(TRAIL_HOT, k)
		col.a = 0.75 * k
		_trail_node.draw_circle(_trail[i] - _trail_node.position, TRAIL_RADIUS * (0.35 + 0.65 * k), col)

# ANGLED: a dust puff, a ring of soft blobs on the floor that spreads and fades
func _draw_dust() -> void:
	for d in _dust:
		var a: float = d.t / DUST_TIME
		var k: float = d.k
		var r: float = DUST_R * k * (0.4 + 0.6 * a)
		var col := Color(DUST_COLOR, 0.5 * k * (1.0 - a))
		for i in 6:
			var off: Vector2 = Vector2.from_angle(TAU * float(i) / 6.0 + 0.4) * r
			var c: Vector2 = View.to_screen(d.pos + off, 2.0 + 4.0 * a)
			_dust_node.draw_circle(c, (3.0 + 3.0 * k) * (1.0 - 0.5 * a), col)
