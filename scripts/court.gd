extends Node2D
# Draws the full basketball court. All sizes are in feet times FT (pixels per foot).

var game
var draw_rims := false  # one instance draws the floor, a second (on top) draws rims

const WOOD := Color(0.80, 0.58, 0.34)
const WOOD_DARK := Color(0.77, 0.55, 0.31)
const PAINT_BLUE := Color(0.18, 0.36, 0.72, 0.9)
const LINE := Color(1, 1, 1, 0.92)
const LW := 3.0
const NET_COLOR := Color(1, 1, 1, 0.75)
const NET_STRINGS := 8            # strings hanging from the rim
const NET_LENGTH := 1.3           # feet the net hangs below the rim (drawn downward on screen)
const NET_BOTTOM := 0.5           # radius in feet of the narrow bottom of the net
const SWISH_TIME := 0.4           # seconds the net animates after swish()
const SWISH_STRETCH := 0.8        # extra net length at the peak of a full swish (x NET_LENGTH)
const SWISH_SWAY := 4.0           # pixels of side to side sway at the start of a full swish
const SWISH_SWAY_HZ := 5.0        # sway speed

var _swish_t := [0.0, 0.0]        # time left in each hoop's net animation
var _swish_k := [1.0, 1.0]        # strength of each hoop's current animation

func _ready() -> void:
	set_process(false)

# Animate the net of hoop 0 (left) or 1 (right). strength 1 = made shot, ~0.3 = small wiggle (rim out).
func swish(hoop_index: int, strength := 1.0) -> void:
	if not draw_rims or hoop_index < 0 or hoop_index > 1:
		return
	_swish_t[hoop_index] = SWISH_TIME
	_swish_k[hoop_index] = clampf(strength, 0.0, 2.0)
	set_process(true)

func _process(delta: float) -> void:
	var active := false
	for i in 2:
		if _swish_t[i] > 0.0:
			_swish_t[i] = maxf(0.0, _swish_t[i] - delta)
			active = true
	queue_redraw()
	if not active:
		set_process(false)

func _draw_net(i: int, h: Vector2, FT: float) -> void:
	var stretch := 0.0
	var sway := 0.0
	if _swish_t[i] > 0.0:
		var t: float = 1.0 - _swish_t[i] / SWISH_TIME     # 0 -> 1 over the animation
		var k: float = _swish_k[i]
		stretch = SWISH_STRETCH * k * sin(PI * minf(1.0, t * 1.6)) * (1.0 - t * 0.5)
		sway = SWISH_SWAY * k * sin(TAU * SWISH_SWAY_HZ * t * SWISH_TIME) * (1.0 - t)
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
		draw_line(tops[s], mids[n], NET_COLOR, 1.5)
		draw_line(tops[n], mids[s], NET_COLOR, 1.5)
		draw_line(mids[s], bots[n], NET_COLOR, 1.5)
		draw_line(mids[n], bots[s], NET_COLOR, 1.5)
		draw_line(bots[s], bots[n], NET_COLOR, 1.5)

func _draw() -> void:
	var FT: float = game.FT
	var W: float = game.COURT_W
	var H: float = game.COURT_H
	if draw_rims:
		for i in game.hoops.size():
			var h: Vector2 = game.hoops[i]
			var inward := 1.0 if h.x < W / 2 else -1.0
			# backboard: 4 ft from baseline, 6 ft wide
			var bx: float = h.x - inward * 1.25 * FT
			draw_line(Vector2(bx, h.y - 3 * FT), Vector2(bx, h.y + 3 * FT), Color.WHITE, 5.0)
			draw_line(Vector2(bx, h.y), h + Vector2(-inward * 0.75 * FT, 0), Color(0.9, 0.4, 0.1), 3.0)
			_draw_net(i, h, FT)
			draw_arc(h, 0.9 * FT, 0, TAU, 24, Color(0.95, 0.42, 0.1), 3.0)
		return

	# apron and floor
	draw_rect(Rect2(-6 * FT, -6 * FT, W + 12 * FT, H + 12 * FT), Color(0.16, 0.18, 0.24))
	draw_rect(Rect2(0, 0, W, H), WOOD)
	var plank := 3.0 * FT
	var y := 0.0
	var k := 0
	while y < H:
		if k % 2 == 0:
			draw_rect(Rect2(0, y, W, min(plank, H - y)), WOOD_DARK)
		y += plank
		k += 1

	# boundary, half court line, center circle
	draw_rect(Rect2(0, 0, W, H), LINE, false, LW)
	draw_line(Vector2(W / 2, 0), Vector2(W / 2, H), LINE, LW)
	draw_circle(Vector2(W / 2, H / 2), 6 * FT, PAINT_BLUE)
	draw_arc(Vector2(W / 2, H / 2), 6 * FT, 0, TAU, 48, LINE, LW)

	for h in game.hoops:
		var inward := 1.0 if h.x < W / 2 else -1.0
		var baseline_x := 0.0 if inward > 0 else W
		# the key (paint): 16 ft wide, 19 ft from baseline
		var key_x := baseline_x if inward > 0 else baseline_x - 19 * FT
		var key := Rect2(key_x, H / 2 - 8 * FT, 19 * FT, 16 * FT)
		draw_rect(key, PAINT_BLUE)
		draw_rect(key, LINE, false, LW)
		# free throw circle
		var ft_center := Vector2(baseline_x + inward * 19 * FT, H / 2)
		draw_arc(ft_center, 6 * FT, 0, TAU, 40, LINE, LW)
		# restricted area
		var a0 := -PI / 2 if inward > 0 else PI / 2
		draw_arc(h, 4 * FT, a0, a0 + PI, 24, LINE, 2.0)
		# three point line: corners at 22 ft, arc of 23.75 ft
		var corner_dx := sqrt(23.75 * 23.75 - 22.0 * 22.0) * FT
		var cx: float = h.x + inward * corner_dx
		for side in [-1.0, 1.0]:
			draw_line(Vector2(baseline_x, h.y + side * 22 * FT), Vector2(cx, h.y + side * 22 * FT), LINE, LW)
		var ang := asin(22.0 / 23.75)
		var start := -ang if inward > 0 else PI - ang
		draw_arc(h, 23.75 * FT, start, start + 2 * ang, 64, LINE, LW)
