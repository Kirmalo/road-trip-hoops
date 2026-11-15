extends Node2D
# Visual feedback layer: screen shake, floating text popups and a ball trail.
# Every function is safe to call any time (also before the game has fully started).
#
#   game.fx.shake(6.0, 0.3)                                   # strength in pixels, time in seconds
#   game.fx.popup("+2", hoop_pos, Color.WHITE, 40)            # world position, font size in pixels
#   game.fx.set_trail(true, Color(1.0, 0.45, 0.1))            # fire trail behind game.ball
#   game.fx.set_trail(false)

const POPUP_TIME := 1.0           # seconds a popup stays on screen
const POPUP_RISE := 46.0          # pixels a popup floats up over its life
const POPUP_POP_TIME := 0.12      # quick scale-in at the start
const POPUP_POP_SCALE := 1.5      # start scale of the scale-in
const POPUP_OUTLINE := 6          # outline thickness in pixels
const TRAIL_LENGTH := 20          # number of remembered ball positions
const TRAIL_RADIUS := 8.5         # radius of the newest trail puff (the ball is about 7)
const TRAIL_HOT := Color(1.0, 0.92, 0.35)   # color near the ball; set_trail's color fades in behind it
const SHAKE_HZ := 30.0            # how often the shake changes direction per second

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
	_popups.append({"text": text, "pos": world_pos, "color": color, "size": maxi(8, size), "t": 0.0})
	queue_redraw()

func set_trail(on: bool, color := Color(1.0, 0.45, 0.1)) -> void:
	_trail_on = on
	_trail_color = color

# ---------------- update ----------------

func _process(delta: float) -> void:
	_update_shake(delta)
	_update_trail()
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
	if _trail_on and b != null:
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
		_trail_node.draw_circle(_trail[i], TRAIL_RADIUS * (0.35 + 0.65 * k), col)
