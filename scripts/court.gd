extends Node2D
# Draws the full basketball court. All sizes are in feet times FT (pixels per foot).
# Two instances (main.gd): the floor (in game.floor_layer) and the hoops (draw_rims = true).
# FLAT view: today's top-down drawing, colors from the court look. ANGLED view (P4-07): the floor, lines and the
# scenery behind the far sideline drawn through View.to_screen, and per hoop three y-sorted nodes in game.world:
# pole + backboard (sort y = hoop screen y - 3), back half of the rim (- 1), front half of the rim + net (+ 1).
# The floor and the hoop structures are drawn once (Godot keeps the drawing); only the nets redraw while they swing.

const View = preload("res://scripts/view.gd")
const Looks = preload("res://scripts/court_looks.gd")

var game
var draw_rims := false  # one instance draws the floor, a second (on top) draws rims

const LW := 3.0
const NET_STRINGS := 8            # strings hanging from the rim
const NET_LENGTH := 1.3           # feet the net hangs below the rim (drawn downward on screen)
const NET_BOTTOM := 0.5           # radius in feet of the narrow bottom of the net
const SWISH_TIME := 0.4           # seconds the net animates after swish()
const SWISH_STRETCH := 0.8        # extra net length at the peak of a full swish (x NET_LENGTH)
const SWISH_SWAY := 4.0           # pixels of side to side sway at the start of a full swish
const SWISH_SWAY_HZ := 5.0        # sway speed

# ---- ANGLED hoop structure (feet; heights above the floor) ----
const RIM_R_FT := 0.9             # rim radius (as the FLAT rim)
const RIM_W := 3.0                # rim line width (px)
const NET_LENGTH_ANGLED := 1.7    # feet the net hangs below the rim in the 3/4 view
const BOARD_BACK_FT := 1.25       # backboard plane this far behind the rim center (toward the baseline)
const BOARD_HALF_FT := 3.0        # half the board width (6 ft board)
const BOARD_BOTTOM_FT := 9.5      # board bottom edge height
const BOARD_TOP_FT := 13.0        # board top edge height
const BOARD_SKEW := 0.35          # fake turn toward the camera: screen px of x shift per sim px along the board, so
                                  # a board seen edge-on from the sideline still shows its face (0 = edge-on line)
const SQUARE_HALF_FT := 1.0       # the shooter's square: 2 ft wide, from the rim up SQUARE_H_FT
const SQUARE_H_FT := 1.5
const POLE_BACK_FT := 1.5         # the pole stands this far behind the baseline
const POLE_TOP_FT := 11.75        # pole height (the arm leaves it here)
const POLE_W := 7.0               # pole thickness (px)
const ARM_W := 5.0                # arm thickness (px)
const PAD_FT := 0.6               # the padded pole base: half its depth (feet, across the court)
const PAD_H_FT := 2.5             # and its height
const HOOP_SHADOW := Color(0, 0, 0, 0.18)   # the hoop's shadow on the floor under the rim
const SORT_BOARD := -3.0          # y-sort offsets from the hoop's screen y (board contract)
const SORT_RIM_BACK := -1.0
const SORT_RIM_FRONT := 1.0

# ---- ANGLED floor and scenery ----
const APRON_FT := 40.0            # apron drawn this far around the court (past anything the camera can show)
const BACK_GAP_FT := 4.0          # floor between the far sideline and the backdrop (feet; the art expects 4)
const BACK_SIDE_FT := 20.0        # the backdrop runs this far past each baseline
const BACK_H_FT := 60.0           # backdrop height (feet): well above the camera's top limit
const BARRIER_H_FT := 2.5         # gym: the low wall in front of the bleachers
const ROW_H_FT := 1.6             # gym: height of one bleacher row
const SEAT_W_FT := 1.6            # gym: room per fan in a row
const CROWD_ROWS := 7             # gym: rows of fans (the camera shows the lowest 5-6)
const CROWD_FILL := 0.82          # gym: share of seats with a fan
const CROWD_SEED := 4021          # fixed, so the crowd is the same every game
const FENCE_H_FT := 10.0          # blacktop: chain fence height
const FENCE_POST_FT := 10.0       # blacktop: distance between fence posts
const FENCE_MESH_FT := 1.0        # blacktop: diamond mesh size
const STREET_FT := 24.0           # blacktop: sidewalk + street depth behind the fence
const SPECKLE_SEED := 77          # blacktop: worn patches, same every game

const CROWD_COLORS := [Color(0.85, 0.25, 0.22), Color(0.25, 0.45, 0.85), Color(0.92, 0.85, 0.35),
	Color(0.92, 0.92, 0.92), Color(0.30, 0.65, 0.35), Color(0.55, 0.35, 0.70), Color(0.95, 0.55, 0.20),
	Color(0.20, 0.20, 0.22)]
const SKIN_COLORS := [Color(0.96, 0.80, 0.62), Color(0.80, 0.58, 0.40), Color(0.55, 0.36, 0.22),
	Color(0.36, 0.24, 0.16)]

var _swish_t := [0.0, 0.0]        # time left in each hoop's net animation
var _swish_k := [1.0, 1.0]        # strength of each hoop's current animation
var _look: Dictionary
var _parts := []                  # ANGLED hoops instance: per hoop [board, rim_back, rim_front] nodes in game.world
var _drawn_flip := false          # View.flipped when last drawn (only changes with View.SIDE_FLIP)
var _floor_tex: Texture2D        # the look's textures (null = procedural); kept here, because the drawing only
var _backdrop_tex: Texture2D     # references them and a freed texture would draw white          # View.flipped when last drawn (only changes with View.SIDE_FLIP)

func _ready() -> void:
	Looks.parse_args()
	_load_look()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED   # floor and backdrop tiles
	if draw_rims and View.angled() and game != null and game.get("world") != null:
		for i in game.hoops.size():
			var nodes := []
			for part in 3:
				var n := Node2D.new()
				n.name = "Hoop%d_%s" % [i, ["Board", "RimBack", "RimFront"][part]]
				n.draw.connect(_draw_hoop_part.bind(n, i, part))
				game.world.add_child(n)
				nodes.append(n)
			_parts.append(nodes)
		_place_parts()
	set_process(View.SIDE_FLIP and View.angled())

# re-read the look and draw everything again (after Looks.set_current, if the scene isn't rebuilt)
func refresh() -> void:
	_load_look()
	_place_parts()
	queue_redraw()
	for nodes in _parts:
		for n in nodes:
			n.queue_redraw()

func _load_look() -> void:
	_look = Looks.look()
	_drawn_flip = View.flipped
	_floor_tex = null
	_backdrop_tex = null
	if View.angled() and not draw_rims:
		_floor_tex = Looks.texture("floor_texture")
		_backdrop_tex = Looks.texture("backdrop_texture")

# the hoop's screen y (its rim center's floor point, projected): the ball sorts at exactly this y near the rim (P4-10)
func hoop_sort_y(i: int) -> float:
	return View.to_screen(game.hoops[i], 0.0).y

func _place_parts() -> void:
	var offs := [SORT_BOARD, SORT_RIM_BACK, SORT_RIM_FRONT]
	for i in _parts.size():
		var base: Vector2 = View.to_screen(game.hoops[i], 0.0)
		for part in 3:
			_parts[i][part].position = Vector2(base.x, base.y + offs[part])

# Animate the net of hoop 0 (left) or 1 (right). strength 1 = made shot, ~0.3 = small wiggle (rim out).
func swish(hoop_index: int, strength := 1.0) -> void:
	if not draw_rims or hoop_index < 0 or hoop_index > 1:
		return
	_swish_t[hoop_index] = SWISH_TIME
	_swish_k[hoop_index] = clampf(strength, 0.0, 2.0)
	set_process(true)

func _process(delta: float) -> void:
	if View.flipped != _drawn_flip:
		refresh()   # View.SIDE_FLIP: the camera moved to the other sideline
	var active := false
	for i in 2:
		if _swish_t[i] > 0.0:
			_swish_t[i] = maxf(0.0, _swish_t[i] - delta)
			active = true
	if _parts.is_empty():
		queue_redraw()
	else:
		for i in _parts.size():
			_parts[i][2].queue_redraw()   # only the front rim + net node animates
	if not active and not (View.SIDE_FLIP and View.angled()):
		set_process(false)

# net stretch and sway of hoop i right now (0, 0 when still)
func _net_motion(i: int) -> Vector2:
	if _swish_t[i] <= 0.0:
		return Vector2.ZERO
	var t: float = 1.0 - _swish_t[i] / SWISH_TIME     # 0 -> 1 over the animation
	var k: float = _swish_k[i]
	var stretch: float = SWISH_STRETCH * k * sin(PI * minf(1.0, t * 1.6)) * (1.0 - t * 0.5)
	var sway: float = SWISH_SWAY * k * sin(TAU * SWISH_SWAY_HZ * t * SWISH_TIME) * (1.0 - t)
	return Vector2(stretch, sway)

func _draw_net(i: int, h: Vector2, FT: float) -> void:
	var m: Vector2 = _net_motion(i)
	var stretch: float = m.x
	var sway: float = m.y
	var net_color: Color = _look["net"]
	var top_r := 0.9 * FT
	var bottom_c := h + Vector2(sway, NET_LENGTH * (1.0 + stretch) * FT)
	var bottom_r := NET_BOTTOM * FT * (1.0 - 0.3 * stretch / maxf(SWISH_STRETCH, 0.01))
	var mid_c := (h + bottom_c) / 2.0 + Vector2(sway * 0.3, 0)
	var mid_r := (top_r + bottom_r) / 2.0
	var tops: Array = []
	var mids: Array = []
	var bots: Array = []
	for s in NET_STRINGS:
		var a := TAU * float(s) / float(NET_STRINGS)
		var d := Vector2(cos(a), sin(a) * 0.45)     # flattened: the net is seen from above at an angle
		tops.append(h + Vector2(cos(a), sin(a)) * top_r)
		mids.append(mid_c + d * mid_r)
		bots.append(bottom_c + d * bottom_r)
	for s in NET_STRINGS:
		var n := (s + 1) % NET_STRINGS
		# strings go down and across, crossing the neighbour's string: a simple diamond mesh
		draw_line(tops[s], mids[n], net_color, 1.5)
		draw_line(tops[n], mids[s], net_color, 1.5)
		draw_line(mids[s], bots[n], net_color, 1.5)
		draw_line(mids[n], bots[s], net_color, 1.5)
		draw_line(bots[s], bots[n], net_color, 1.5)

func _draw() -> void:
	if View.angled():
		if not draw_rims:
			_draw_floor_angled()
		return   # ANGLED hoops draw in their own nodes in game.world
	var FT: float = game.FT
	var W: float = game.COURT_W
	var H: float = game.COURT_H
	var line: Color = _look["line"]
	var paint: Color = _look["paint"]
	if draw_rims:
		var board: Color = Color.WHITE if _look["backboard"] == "glass" else _look["pole"]
		var rim: Color = _look["rim"]
		for i in game.hoops.size():
			var h: Vector2 = game.hoops[i]
			var inward := 1.0 if h.x < W / 2 else -1.0
			# backboard: 4 ft from baseline, 6 ft wide
			var bx: float = h.x - inward * 1.25 * FT
			draw_line(Vector2(bx, h.y - 3 * FT), Vector2(bx, h.y + 3 * FT), board, 5.0)
			draw_line(Vector2(bx, h.y), h + Vector2(-inward * 0.75 * FT, 0), Color(0.9, 0.4, 0.1), 3.0)
			_draw_net(i, h, FT)
			draw_arc(h, 0.9 * FT, 0, TAU, 24, rim, 3.0)
		return

	_count("court_floor_draws")
	# apron and floor
	draw_rect(Rect2(-6 * FT, -6 * FT, W + 12 * FT, H + 12 * FT), _look["apron"])
	draw_rect(Rect2(0, 0, W, H), _look["floor"])
	var plank: float = float(_look["stripe_ft"]) * FT
	if plank > 0.0:
		var y := 0.0
		var k := 0
		while y < H:
			if k % 2 == 0:
				draw_rect(Rect2(0, y, W, minf(plank, H - y)), _look["floor_stripe"])
			y += plank
			k += 1
	for r in _speckles():
		draw_rect(r, _speckle_color())

	# boundary, half court line, center circle
	draw_rect(Rect2(0, 0, W, H), line, false, LW)
	draw_line(Vector2(W / 2, 0), Vector2(W / 2, H), line, LW)
	draw_circle(Vector2(W / 2, H / 2), 6 * FT, _look["logo"])
	draw_arc(Vector2(W / 2, H / 2), 6 * FT, 0, TAU, 48, line, LW)

	for h in game.hoops:
		var inward := 1.0 if h.x < W / 2 else -1.0
		var baseline_x := 0.0 if inward > 0 else W
		# the key (paint): 16 ft wide, 19 ft from baseline
		var key_x := baseline_x if inward > 0 else baseline_x - 19 * FT
		var key := Rect2(key_x, H / 2 - 8 * FT, 19 * FT, 16 * FT)
		draw_rect(key, paint)
		draw_rect(key, line, false, LW)
		# free throw circle
		var ft_center := Vector2(baseline_x + inward * 19 * FT, H / 2)
		draw_arc(ft_center, 6 * FT, 0, TAU, 40, line, LW)
		# restricted area
		var a0 := -PI / 2 if inward > 0 else PI / 2
		draw_arc(h, 4 * FT, a0, a0 + PI, 24, line, 2.0)
		# three point line: corners at 22 ft, arc of 23.75 ft
		var corner_dx := sqrt(23.75 * 23.75 - 22.0 * 22.0) * FT
		var cx: float = h.x + inward * corner_dx
		for side in [-1.0, 1.0]:
			draw_line(Vector2(baseline_x, h.y + side * 22 * FT), Vector2(cx, h.y + side * 22 * FT), line, LW)
		var ang := asin(22.0 / 23.75)
		var start := -ang if inward > 0 else PI - ang
		draw_arc(h, 23.75 * FT, start, start + 2 * ang, 64, line, LW)

func _count(k: String) -> void:
	if game != null and game.has_method("stat"):
		game.stat(k)

# worn patches on an outdoor floor (sim rects, the same every game)
func _speckles() -> Array:
	var out := []
	var n: int = int(_look.get("speckle", 0))
	if n <= 0:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = SPECKLE_SEED
	var FT: float = game.FT
	for s in n:
		var w: float = rng.randf_range(0.4, 2.2) * FT
		var hh: float = rng.randf_range(0.3, 1.2) * FT
		var x: float = rng.randf_range(0.0, game.COURT_W - w)
		var y: float = rng.randf_range(0.0, game.COURT_H - hh)
		out.append(Rect2(x, y, w, hh))
	return out

func _speckle_color() -> Color:
	return (_look["floor"] as Color).darkened(0.12)

# ---------------- ANGLED: floor, lines and scenery ----------------

func _p(sim: Vector2, h := 0.0) -> Vector2:
	return View.to_screen(sim, h)

# a sim floor polygon, filled
func _fill(pts: PackedVector2Array, c: Color) -> void:
	var out := PackedVector2Array()
	for q in pts:
		out.append(_p(q))
	draw_colored_polygon(out, c)

# a sim floor polyline (closed adds the first point again)
func _stroke(pts: PackedVector2Array, c: Color, w: float, closed := false) -> void:
	var out := PackedVector2Array()
	for q in pts:
		out.append(_p(q))
	if closed and pts.size() > 0:
		out.append(_p(pts[0]))
	draw_polyline(out, c, w)

static func _rect_pts(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])

static func _arc_pts(c: Vector2, r: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for s in n + 1:
		out.append(c + Vector2.from_angle(lerpf(a0, a1, float(s) / float(n))) * r)
	return out

func _draw_floor_angled() -> void:
	_count("court_floor_draws")
	var FT: float = game.FT
	var W: float = game.COURT_W
	var H: float = game.COURT_H
	var line: Color = _look["line"]
	var paint: Color = _look["paint"]
	# apron, then the scenery behind the far sideline, then the court
	var apron := Rect2(-APRON_FT * FT, -BACK_GAP_FT * FT, W + 2 * APRON_FT * FT, H + (APRON_FT + BACK_GAP_FT) * FT)
	if _floor_tex != null:
		_draw_floor_texture(apron, _floor_tex)   # the tile covers the apron too (the court is painted on the same floor)
	else:
		_fill(_rect_pts(apron), _look["apron"])
		_draw_floor_plain()
	_draw_backdrop()

	# boundary, half court line, center circle
	_stroke(_rect_pts(Rect2(0, 0, W, H)), line, LW, true)
	_stroke(PackedVector2Array([Vector2(W / 2, 0), Vector2(W / 2, H)]), line, LW)
	var center := Vector2(W / 2, H / 2)
	_fill(_arc_pts(center, 6 * FT, 0, TAU, 48), _look["logo"])
	_stroke(_arc_pts(center, 6 * FT, 0, TAU, 48), line, LW)

	for i in game.hoops.size():
		var h: Vector2 = game.hoops[i]
		var inward := 1.0 if h.x < W / 2 else -1.0
		var baseline_x := 0.0 if inward > 0 else W
		var key_x := baseline_x if inward > 0 else baseline_x - 19 * FT
		var key := Rect2(key_x, H / 2 - 8 * FT, 19 * FT, 16 * FT)
		_fill(_rect_pts(key), paint)
		_stroke(_rect_pts(key), line, LW, true)
		var ft_center := Vector2(baseline_x + inward * 19 * FT, H / 2)
		_stroke(_arc_pts(ft_center, 6 * FT, 0, TAU, 40), line, LW)
		var a0 := -PI / 2 if inward > 0 else PI / 2
		_stroke(_arc_pts(h, 4 * FT, a0, a0 + PI, 24), line, 2.0)
		var corner_dx := sqrt(23.75 * 23.75 - 22.0 * 22.0) * FT
		var cx: float = h.x + inward * corner_dx
		for side in [-1.0, 1.0]:
			_stroke(PackedVector2Array([Vector2(baseline_x, h.y + side * 22 * FT), Vector2(cx, h.y + side * 22 * FT)]),
					line, LW)
		var ang := asin(22.0 / 23.75)
		var start := -ang if inward > 0 else PI - ang
		_stroke(_arc_pts(h, 23.75 * FT, start, start + 2 * ang, 64), line, LW)
		# the hoop's shadow on the floor, under the rim (helps read where the rim is over the floor)
		_fill(_arc_pts(h, RIM_R_FT * FT, 0, TAU, 20), HOOP_SHADOW)
		var pole: Vector2 = _pole_floor(i)
		_fill(_rect_pts(Rect2(pole.x - 1.0 * FT, pole.y - PAD_FT * FT, 2.0 * FT, 2.0 * PAD_FT * FT)), HOOP_SHADOW)

# the court floor without a texture: plain color, plank stripes, worn patches (the procedural fallback)
func _draw_floor_plain() -> void:
	var FT: float = game.FT
	var W: float = game.COURT_W
	var H: float = game.COURT_H
	_fill(_rect_pts(Rect2(0, 0, W, H)), _look["floor"])
	var plank: float = float(_look["stripe_ft"]) * FT
	if plank > 0.0:
		var y := 0.0
		var k := 0
		while y < H:
			if k % 2 == 0:
				_fill(_rect_pts(Rect2(0, y, W, minf(plank, H - y))), _look["floor_stripe"])
			y += plank
			k += 1
	var sc: Color = _speckle_color()
	for r in _speckles():
		_fill(_rect_pts(r), sc)

# the look's floor tile over the sim rect r. The art is drawn already foreshortened for the 3/4 view, so it repeats in
# screen space at a uniform floor_scale (canvas px per art pixel), never stretched by the tilt.
func _draw_floor_texture(r: Rect2, tex: Texture2D) -> void:
	var tile: Vector2 = tex.get_size() * float(_look.get("floor_scale", 2.0))
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for q in _rect_pts(r):
		var sp: Vector2 = _p(q)
		pts.append(sp)
		uvs.append(Vector2(sp.x / tile.x, sp.y / tile.y))
	draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, tex)

# the strip behind the far sideline (owner Q3 a): an upright wall BACK_GAP_FT behind it, from far left to far right
func _draw_backdrop() -> void:
	var kind: String = _look.get("backdrop", "none")
	var FT: float = game.FT
	var W: float = game.COURT_W
	var y: float = -BACK_GAP_FT * FT
	var x0: float = -BACK_SIDE_FT * FT
	var x1: float = W + BACK_SIDE_FT * FT
	var base_l: Vector2 = _p(Vector2(x0, y))
	var base_r: Vector2 = _p(Vector2(x1, y))
	var top_y: float = _p(Vector2(x0, y), BACK_H_FT * FT).y
	var wall := Rect2(base_l.x, top_y, base_r.x - base_l.x, base_l.y - top_y)
	if kind == "none":
		draw_rect(wall, _look["apron"].darkened(0.3))
		return
	var tex: Texture2D = _backdrop_tex
	if tex != null:
		# the art strip, bottom on the floor, tiled left to right; plain wall color above it
		var sc: float = float(_look.get("backdrop_scale", 2.0))
		var th: float = tex.get_height() * sc
		draw_rect(wall, tex.get_image().get_pixel(0, 0))   # above the strip: the art's top-left color
		draw_set_transform(Vector2(base_l.x, base_l.y - th), 0.0, Vector2(sc, sc))
		draw_texture_rect(tex, Rect2(0, 0, wall.size.x / sc, tex.get_height()), true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if kind == "bleachers":
		_draw_bleachers(x0, x1, y, wall)
	elif kind == "fence":
		_draw_fence(x0, x1, y, wall)
	else:
		draw_rect(wall, _look["wall"])

# gym placeholder: a dark wall, a low padded barrier, then bleacher rows full of fans (blocky heads and shirts)
func _draw_bleachers(x0: float, x1: float, y: float, wall: Rect2) -> void:
	var FT: float = game.FT
	var dark: Color = _look["wall_dark"]
	var mid: Color = _look["wall"]
	draw_rect(wall, dark)
	var rng := RandomNumberGenerator.new()
	rng.seed = CROWD_SEED
	var hs: float = View.HEIGHT_SCALE * View.size_at(Vector2(x0, y))
	for r in CROWD_ROWS:
		var h0: float = (BARRIER_H_FT + r * ROW_H_FT) * FT
		var row_top: float = _p(Vector2(x0, y), h0 + ROW_H_FT * FT).y
		var row_bot: float = _p(Vector2(x0, y), h0).y
		# the bench (lighter step) and the riser
		draw_rect(Rect2(wall.position.x, row_top, wall.size.x, row_bot - row_top), mid if r % 2 == 0 else mid.darkened(0.12))
		draw_rect(Rect2(wall.position.x, row_bot - 2.0, wall.size.x, 2.0), mid.lightened(0.25))
		# fans: shirt block with a head on top, sitting on this row
		var fx: float = x0 + rng.randf_range(0.0, SEAT_W_FT) * FT
		while fx < x1:
			if rng.randf() < CROWD_FILL:
				var base: Vector2 = _p(Vector2(fx, y), h0 + 0.3 * FT)
				var shirt: Color = CROWD_COLORS[rng.randi() % CROWD_COLORS.size()]
				var skin: Color = SKIN_COLORS[rng.randi() % SKIN_COLORS.size()]
				var bw: float = 0.95 * FT * hs
				var bh: float = 1.15 * FT * hs
				var hw: float = 0.6 * FT * hs
				var lift: float = rng.randf_range(0.0, 0.35) * FT * hs   # some fans sit up or stand a little
				draw_rect(Rect2(base.x - bw / 2, base.y - bh - lift, bw, bh + lift), shirt.darkened(0.15))
				draw_rect(Rect2(base.x - hw / 2, base.y - bh - lift - hw, hw, hw), skin)
			fx += SEAT_W_FT * FT * rng.randf_range(0.85, 1.15)
	# the barrier in front (padded, team blue stripe on top)
	var b_top: float = _p(Vector2(x0, y), BARRIER_H_FT * FT).y
	draw_rect(Rect2(wall.position.x, b_top, wall.size.x, wall.end.y - b_top), dark.lightened(0.08))
	draw_rect(Rect2(wall.position.x, b_top, wall.size.x, 3.0), _look["paint"])

# blacktop placeholder: buildings, the far sidewalk, the street with a dashed line, the near sidewalk, then a chain
# fence with posts in front (the street seen through the mesh)
func _draw_fence(x0: float, x1: float, y: float, wall: Rect2) -> void:
	var FT: float = game.FT
	var street_far: float = y - STREET_FT * FT
	var bld_base: float = _p(Vector2(x0, street_far)).y
	# sky and buildings behind the street
	draw_rect(wall, Color(0.42, 0.55, 0.70))
	var rng := RandomNumberGenerator.new()
	rng.seed = CROWD_SEED
	var bx: float = x0
	while bx < x1:
		var bw: float = rng.randf_range(14.0, 30.0) * FT
		var bh: float = rng.randf_range(18.0, 40.0) * FT
		var l: Vector2 = _p(Vector2(bx, street_far))
		var r: Vector2 = _p(Vector2(bx + bw, street_far), bh)
		var c: Color = [Color(0.52, 0.33, 0.27), Color(0.45, 0.42, 0.40), Color(0.60, 0.50, 0.38),
				Color(0.35, 0.33, 0.38)][rng.randi() % 4]
		draw_rect(Rect2(l.x, r.y, r.x - l.x, l.y - r.y), c)
		# windows
		var wy: float = 3.0 * FT
		while wy < bh - 2.0 * FT:
			var wx: float = bx + 1.5 * FT
			while wx < bx + bw - 2.0 * FT:
				var wp: Vector2 = _p(Vector2(wx, street_far), wy + 2.0 * FT)
				var lit := rng.randf() < 0.25
				draw_rect(Rect2(wp.x, wp.y, 1.4 * FT, 2.0 * FT), Color(0.95, 0.85, 0.5) if lit else c.darkened(0.35))
				wx += 3.0 * FT
			wy += 4.0 * FT
		bx += bw + rng.randf_range(0.0, 4.0) * FT
	# sidewalks and street (flat, seen beyond the fence)
	var walk := 5.0 * FT
	_fill(_rect_pts(Rect2(x0, street_far, x1 - x0, walk)), Color(0.60, 0.60, 0.58))
	_fill(_rect_pts(Rect2(x0, street_far + walk, x1 - x0, STREET_FT * FT - 2.0 * walk)), _look["wall_dark"])
	_fill(_rect_pts(Rect2(x0, y - walk, x1 - x0, walk)), Color(0.60, 0.60, 0.58))
	var mid_y: float = street_far + STREET_FT * FT / 2.0
	var dx: float = x0
	while dx < x1:
		_fill(_rect_pts(Rect2(dx, mid_y - 0.25 * FT, 4.0 * FT, 0.5 * FT)), Color(0.92, 0.80, 0.25))
		dx += 9.0 * FT
	# the fence: low concrete curb, mesh, posts and a top rail
	var curb_top: float = _p(Vector2(x0, y), 0.8 * FT).y
	var top: float = _p(Vector2(x0, y), FENCE_H_FT * FT).y
	var base: float = wall.end.y
	var mesh_c := Color(0.75, 0.78, 0.80, 0.55)
	var m: float = FENCE_MESH_FT * FT * View.HEIGHT_SCALE
	var hgt: float = base - top
	var sx: float = wall.position.x - hgt
	while sx < wall.end.x:
		draw_line(Vector2(sx, base), Vector2(sx + hgt, top), mesh_c, 1.0)
		draw_line(Vector2(sx + hgt, base), Vector2(sx, top), mesh_c, 1.0)
		sx += m
	var px: float = x0
	while px <= x1:
		var a: Vector2 = _p(Vector2(px, y))
		draw_line(a, Vector2(a.x, top), Color(0.62, 0.64, 0.66), 3.0)
		px += FENCE_POST_FT * FT
	draw_line(Vector2(wall.position.x, top), Vector2(wall.end.x, top), Color(0.70, 0.72, 0.74), 3.0)
	draw_rect(Rect2(wall.position.x, curb_top, wall.size.x, base - curb_top), Color(0.55, 0.55, 0.53))

# ---------------- ANGLED: hoops ----------------

func _inward(i: int) -> float:
	return 1.0 if game.hoops[i].x < game.COURT_W / 2 else -1.0

func _pole_floor(i: int) -> Vector2:
	var h: Vector2 = game.hoops[i]
	var baseline_x: float = 0.0 if _inward(i) > 0 else game.COURT_W
	return Vector2(baseline_x - _inward(i) * POLE_BACK_FT * game.FT, h.y)

# a point on the backboard: dy_ft along the board (+ = toward the near sideline), at h_ft above the floor
func _board_pt(i: int, dy_ft: float, h_ft: float) -> Vector2:
	var FT: float = game.FT
	var h: Vector2 = game.hoops[i]
	var bx: float = h.x - _inward(i) * BOARD_BACK_FT * FT
	var s: Vector2 = View.to_screen(Vector2(bx, h.y + dy_ft * FT), h_ft * FT)
	s.x -= dy_ft * FT * BOARD_SKEW * _inward(i)
	return s

# draws one hoop part into node n, in canvas coordinates
func _draw_hoop_part(n: Node2D, i: int, part: int) -> void:
	n.draw_set_transform(-n.position, 0.0, Vector2.ONE)
	if part == 0:
		_count("court_hoop_draws")
		_draw_board(n, i)
	elif part == 1:
		_count("court_hoop_draws")
		_draw_rim_half(n, i, false)
	else:
		_draw_net_angled(n, i)
		_draw_rim_half(n, i, true)

func _draw_board(n: Node2D, i: int) -> void:
	var FT: float = game.FT
	var h: Vector2 = game.hoops[i]
	var pole_c: Color = _look["pole"]
	var pole: Vector2 = _pole_floor(i)
	# pole with its padded base, and the arm out to the back of the board
	var foot: Vector2 = View.to_screen(pole)
	var head: Vector2 = View.to_screen(pole, POLE_TOP_FT * FT)
	n.draw_line(foot, head, pole_c, POLE_W)
	# the pad: a box around the pole foot, its near face toward the camera
	var pad_near: Vector2 = View.to_screen(pole + Vector2(0, PAD_FT * FT))
	var pad_far_top: Vector2 = View.to_screen(pole + Vector2(0, -PAD_FT * FT), PAD_H_FT * FT)
	var pad_w: float = 0.7 * FT
	n.draw_rect(Rect2(pad_near.x - pad_w, pad_far_top.y, 2.0 * pad_w, pad_near.y - pad_far_top.y), pole_c.darkened(0.35))
	var back: Vector2 = _board_pt(i, 0.0, POLE_TOP_FT - 0.4)
	n.draw_line(head, back, pole_c, ARM_W)
	n.draw_line(View.to_screen(pole, (POLE_TOP_FT - 1.8) * FT), _board_pt(i, 0.0, BOARD_BOTTOM_FT + 0.3), pole_c, 3.0)
	# the board: a parallelogram (BOARD_SKEW turns its face to the camera)
	var quad := PackedVector2Array([_board_pt(i, -BOARD_HALF_FT, BOARD_BOTTOM_FT), _board_pt(i, -BOARD_HALF_FT, BOARD_TOP_FT),
			_board_pt(i, BOARD_HALF_FT, BOARD_TOP_FT), _board_pt(i, BOARD_HALF_FT, BOARD_BOTTOM_FT)])
	var glass: bool = _look["backboard"] == "glass"
	n.draw_colored_polygon(quad, Color(0.80, 0.92, 1.0, 0.35) if glass else pole_c.lightened(0.15))
	var closed := quad.duplicate()
	closed.append(quad[0])
	n.draw_polyline(closed, Color(1, 1, 1, 0.95) if glass else pole_c.darkened(0.3), 3.0)
	# the shooter's square, its bottom at the rim
	var rim_ft: float = View.RIM_Z / FT
	var sq := PackedVector2Array([_board_pt(i, -SQUARE_HALF_FT, rim_ft), _board_pt(i, -SQUARE_HALF_FT, rim_ft + SQUARE_H_FT),
			_board_pt(i, SQUARE_HALF_FT, rim_ft + SQUARE_H_FT), _board_pt(i, SQUARE_HALF_FT, rim_ft)])
	sq.append(sq[0])
	n.draw_polyline(sq, _look["board_square"], 2.0)
	# the bracket from the board to the rim
	n.draw_line(_board_pt(i, 0.0, rim_ft), View.to_screen(h + Vector2(-_inward(i) * RIM_R_FT * FT, 0), View.RIM_Z),
			_look["rim"].darkened(0.1), 3.0)

# back (far) or front (near) half of the rim ellipse
func _draw_rim_half(n: Node2D, i: int, front: bool) -> void:
	var h: Vector2 = game.hoops[i]
	var r: float = RIM_R_FT * game.FT
	var a0: float = 0.0 if front else PI
	var pts := PackedVector2Array()
	for s in 13:
		pts.append(View.to_screen(h + Vector2.from_angle(a0 + PI * float(s) / 12.0) * r, View.RIM_Z))
	n.draw_polyline(pts, _look["rim"], RIM_W)

func _draw_net_angled(n: Node2D, i: int) -> void:
	var FT: float = game.FT
	var h: Vector2 = game.hoops[i]
	var m: Vector2 = _net_motion(i)
	var stretch: float = m.x
	var sway: float = m.y
	var c: Color = _look["net"]
	var top_r: float = RIM_R_FT * FT
	var length: float = NET_LENGTH_ANGLED * (1.0 + stretch) * FT
	var bottom_r: float = NET_BOTTOM * FT * (1.0 - 0.3 * stretch / maxf(SWISH_STRETCH, 0.01))
	var mid_r: float = (top_r + bottom_r) / 2.0
	var tops: Array = []
	var mids: Array = []
	var bots: Array = []
	for s in NET_STRINGS:
		var d: Vector2 = Vector2.from_angle(TAU * float(s) / float(NET_STRINGS))
		tops.append(View.to_screen(h + d * top_r, View.RIM_Z))
		mids.append(View.to_screen(h + Vector2(sway * 0.3, 0) + d * mid_r, View.RIM_Z - length / 2.0))
		bots.append(View.to_screen(h + Vector2(sway, 0) + d * bottom_r, View.RIM_Z - length))
	for s in NET_STRINGS:
		var k := (s + 1) % NET_STRINGS
		n.draw_line(tops[s], mids[k], c, 1.5)
		n.draw_line(tops[k], mids[s], c, 1.5)
		n.draw_line(mids[s], bots[k], c, 1.5)
		n.draw_line(mids[k], bots[s], c, 1.5)
		n.draw_line(bots[s], bots[k], c, 1.5)
