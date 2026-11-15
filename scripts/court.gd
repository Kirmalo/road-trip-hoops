extends Node2D
# Draws the full basketball court. All sizes are in feet times FT (pixels per foot).

var game
var draw_rims := false  # one instance draws the floor, a second (on top) draws rims

const WOOD := Color(0.80, 0.58, 0.34)
const WOOD_DARK := Color(0.77, 0.55, 0.31)
const PAINT_BLUE := Color(0.18, 0.36, 0.72, 0.9)
const LINE := Color(1, 1, 1, 0.92)
const LW := 3.0

func _draw() -> void:
	var FT: float = game.FT
	var W: float = game.COURT_W
	var H: float = game.COURT_H
	if draw_rims:
		for h in game.hoops:
			var inward := 1.0 if h.x < W / 2 else -1.0
			# backboard: 4 ft from baseline, 6 ft wide
			var bx: float = h.x - inward * 1.25 * FT
			draw_line(Vector2(bx, h.y - 3 * FT), Vector2(bx, h.y + 3 * FT), Color.WHITE, 5.0)
			draw_line(Vector2(bx, h.y), h + Vector2(-inward * 0.75 * FT, 0), Color(0.9, 0.4, 0.1), 3.0)
			draw_arc(h, 0.9 * FT, 0, TAU, 24, Color(0.95, 0.42, 0.1), 3.0)
			draw_arc(h, 0.55 * FT, 0, TAU, 16, Color(1, 1, 1, 0.6), 1.5)
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
