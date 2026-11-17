extends Node2D
# Visual feedback layer: screen shake, floating text popups and a ball trail.
# Every function is safe to call any time (also before the game has fully started).
#
#   game.fx.shake(6.0, 0.3)                                   # strength in pixels, time in seconds
#   game.fx.popup("+2", hoop_pos, Color.WHITE, 40)            # world position, font size in pixels
#   game.fx.set_trail(true, Color(1.0, 0.45, 0.1))            # fire trail behind game.ball
#   game.fx.set_trail(false)
#   game.fx.dust(floor_pos, 0.7)                              # ANGLED only: a dust puff on the floor (0..1)
#   game.fx.foot_dust(floor_pos, 0.6, cut_dir)                # ANGLED only: a puff at a player's feet (P6-23)
#   game.fx.punch(1.0)                                        # camera punch on a big dunk (P6-23)
#   game.fx.zoom_punch()                                      # main.gd: camera zoom x this (1.0 at rest)
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
# P6-23 motion effects (visual only; Q7 "medium")
const FOOT_DUST_TIME := 0.4       # seconds a puff at the feet lasts (cuts and landings)
const FOOT_DUST_R := 18.0         # sim px: radius a full-strength foot puff grows to
const FOOT_DUST_ALPHA := 0.75     # its opacity at the start (x strength)
const FOOT_DUST_PUSH := 0.6       # a cut's puff drifts this x its radius against the new direction (kicked back)
const SPLASH_RISE := 10.0         # sim px of height: wet court puffs are splashes, droplets thrown up this high
const PUNCH_ZOOM := 0.04          # zoom_punch() peaks at 1 + this at strength 1 (board: +3-5%)
const PUNCH_TIME := 0.25          # seconds of the punch: in fast, eased back out
const PUNCH_ATTACK := 0.2         # fraction of PUNCH_TIME spent zooming in
const PUNCH_SHAKE := 4.0          # px of extra shake with a punch (stacks with ball.gd's dunk shake; the bigger wins)
const PUNCH_SHAKE_TIME := 0.25
const POPUP_HEAD_GAP := 6.0       # screen px between a player's head and the bottom of popup_head()'s text
const POPUP_HEAD_MAX := 1.5      # P6-23: taller (v2) players lift POPUP_HEAD_LIFT by their head scale, at most this

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
var _punch_t := -1.0              # seconds into the current camera punch (< 0: none)
var _punch_k := 0.0               # its strength
var _head_scale := -1.0           # tallest player's head scale (cached on the first popup; < 0: not yet)

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
	_start_shake(strength, time)

func _start_shake(strength: float, time: float) -> void:
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
	_ensure_dust_node()
	game.stat("dust_puffs")
	_dust.append({"pos": pos, "k": clampf(strength, 0.0, 1.0), "t": 0.0})

# P6-23: a popup over player p's drawn head (main.player_head_screen: his real head height, v1 or v2, and his jump).
# FLAT, or without that function: popup() at flat_pos as before.
func popup_head(text: String, p, flat_pos: Vector2, color: Color, size: int) -> void:
	if not View.angled() or game == null or p == null or not game.has_method("player_head_screen"):
		popup(text, flat_pos, color, size)
		return
	game.stat("popups")
	var head: Vector2 = game.player_head_screen(p)
	var at: Vector2 = head - Vector2(0, POPUP_HEAD_GAP + float(maxi(8, size)) * 0.5)
	_popups.append({"text": text, "pos": at, "color": color, "size": maxi(8, size), "t": 0.0})
	queue_redraw()

# P6-23: a puff at a player's feet (sim point pos, strength 0..1) on a hard cut (dir: the new direction, pushed
# back against it) or a landing (dir ZERO: a ring). Sand-colored on the sand court, a splash on the wet court
# (twist_fx's colors when it is there). ANGLED only.
func foot_dust(pos: Vector2, strength := 1.0, dir := Vector2.ZERO) -> void:
	if not View.angled() or game == null or game.get("decals") == null:
		return
	_ensure_dust_node()
	game.stat("dust_feet")
	var col: Color = DUST_COLOR
	var wet := false
	var tf = game.get("twist_fx")
	if tf != null and tf.has_method("dust_color"):
		col = tf.dust_color(DUST_COLOR)
		wet = tf.has_method("ground_kind") and str(tf.ground_kind()) == "wet"
	var k: float = clampf(strength, 0.0, 1.0)
	var push: Vector2 = Vector2.ZERO
	if dir.length() > 0.01:
		push = -dir.normalized() * FOOT_DUST_R * k * FOOT_DUST_PUSH
	_dust.append({"pos": pos, "k": k, "t": 0.0, "foot": true, "col": col, "wet": wet, "push": push})

# P6-23: a camera punch (main.gd zooms by zoom_punch()) plus a little shake; big dunks only
func punch(strength := 1.0) -> void:
	if game != null:
		game.stat("cam_punches")
	_punch_t = 0.0
	_punch_k = clampf(strength, 0.0, 1.5)
	_start_shake(PUNCH_SHAKE * _punch_k, PUNCH_SHAKE_TIME)   # not counted in "shakes" (that stays ball.gd's)

# 1.0 at rest; up to 1 + PUNCH_ZOOM during a punch (fast in, eased out)
func zoom_punch() -> float:
	if _punch_t < 0.0:
		return 1.0
	var u: float = _punch_t / PUNCH_TIME
	var e := 0.0
	if u < PUNCH_ATTACK:
		e = smoothstep(0.0, 1.0, u / PUNCH_ATTACK)
	else:
		var v: float = (u - PUNCH_ATTACK) / (1.0 - PUNCH_ATTACK)
		e = (1.0 - v) * (1.0 - v)
	return 1.0 + PUNCH_ZOOM * _punch_k * e

func _ensure_dust_node() -> void:
	if _dust_node == null:
		_dust_node = Node2D.new()
		_dust_node.name = "BallDust"
		_dust_node.draw.connect(_draw_dust)
		game.decals.add_child(_dust_node)

# where a popup for sim point p goes on screen (FLAT: p itself)
func _popup_screen(p: Vector2) -> Vector2:
	if not View.angled():
		return p
	var lift: float = POPUP_HEAD_LIFT * _popup_head_scale()
	if game != null and game.get("hoops") != null:
		for h in game.hoops:
			if (h as Vector2).distance_to(p) < POPUP_HOOP_FT * View.FT:
				lift = POPUP_RIM_LIFT
	return View.to_screen(p, lift)

# P6-23: the tallest player's drawn head over a v1 head (1.0 with v1 sheets), so popups clear the taller v2 heads
func _popup_head_scale() -> float:
	if _head_scale > 0.0:
		return _head_scale
	if game == null or game.get("players") == null:
		return 1.0
	var best := 1.0
	for p in game.players:
		if p != null and p.has_method("view_head_scale"):
			best = maxf(best, float(p.view_head_scale()))
	_head_scale = minf(best, POPUP_HEAD_MAX)
	return _head_scale

# ---------------- update ----------------

func _process(delta: float) -> void:
	_update_shake(delta)
	_update_trail()
	if _punch_t >= 0.0:
		_punch_t += delta
		if _punch_t >= PUNCH_TIME:
			_punch_t = -1.0
	if not _dust.is_empty():
		for d in _dust:
			d.t += delta
		_dust = _dust.filter(func(d): return d.t < (FOOT_DUST_TIME if d.get("foot", false) else DUST_TIME))
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
		if d.get("foot", false):
			_draw_foot_dust(d)
			continue
		var a: float = d.t / DUST_TIME
		var k: float = d.k
		var r: float = DUST_R * k * (0.4 + 0.6 * a)
		var col := Color(DUST_COLOR, 0.5 * k * (1.0 - a))
		for i in 6:
			var off: Vector2 = Vector2.from_angle(TAU * float(i) / 6.0 + 0.4) * r
			var c: Vector2 = View.to_screen(d.pos + off, 2.0 + 4.0 * a)
			_dust_node.draw_circle(c, (3.0 + 3.0 * k) * (1.0 - 0.5 * a), col)

# P6-23: a foot puff. Dust: soft blobs that spread low over the floor and fade (pushed back on a cut). Wet: a splash,
# droplets thrown up and out that fall back
func _draw_foot_dust(d: Dictionary) -> void:
	var a: float = d.t / FOOT_DUST_TIME
	var k: float = d.k
	var ease_out: float = 1.0 - (1.0 - a) * (1.0 - a)
	var r: float = FOOT_DUST_R * k * (0.35 + 0.65 * ease_out)
	var center: Vector2 = d.pos + (d.push as Vector2) * ease_out
	var col: Color = d.col
	col.a = FOOT_DUST_ALPHA * k * (1.0 - a)
	var wet: bool = d.wet
	for i in 7:
		var ang: float = TAU * float(i) / 7.0 + 0.3
		var off: Vector2 = Vector2.from_angle(ang) * r * (0.8 + 0.2 * float(i % 2))
		var h: float = 1.5 + 3.0 * a
		if wet:
			h = 1.0 + SPLASH_RISE * k * 4.0 * a * (1.0 - a)
		var c: Vector2 = View.to_screen(center + off, h)
		var br: float = (3.0 + 4.0 * k) * (1.0 - 0.5 * a)
		if wet:
			br *= 0.6
		_dust_node.draw_circle(c, br, col)
