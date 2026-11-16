extends RefCounted
# View (Phase 4): the one place that knows how the 2D top-down simulation is drawn on screen.
# Use it through   const View = preload("res://scripts/view.gd")   (static functions only, never instanced).
#
# The simulation never changes: positions, velocities, z / jump_z (heights in sim pixels), facing and all timers keep
# their top-down meaning. Drawing code turns them into canvas pixels with these functions and never writes back.
#
# Two modes:
#   ANGLED the game's view (default since P4-11, owner: angled 3/4 view): seen from the near sideline (sim y = COURT_H,
#          the bottom of the flat view). The court is tilted: its depth shrinks to TILT_Y, heights stay upright
#          (HEIGHT_SCALE), and with PERSPECTIVE > 0 the far side narrows. Sim x stays screen x (the baselines stay left
#          and right), the far sideline (y = 0) is up on screen.
#   FLAT   the old top-down look, kept as a test and fallback mode. to_screen(p, h) = p - (0, h): the identity on the floor.
# main.gd sets `mode` from the test flag --view flat|angled (default DEFAULT_MODE).

const FLAT := 0
const ANGLED := 1
const DEFAULT_MODE := ANGLED
static var mode := DEFAULT_MODE

# ---- tuning ----
const TILT_Y := 0.48                 # court depth on screen as a fraction of its true depth (1 = top-down). P4-11:
                                     # 0.48 (was 0.55) so main.gd's zoom can show ~2/3 of the court length and still
                                     # both sidelines, the far players' heads and the HUD bar on 1280x720
const PERSPECTIVE := 0.0             # 0 = parallel tilt; 0.1-0.2 narrows the far side (size_at: 1 - k/2 far, 1 + k/2 near).
                                     # P4-11 tried 0.15 (test flag --perspective 0.15) and kept 0: the floor tile is
                                     # repeated in screen space (its planks can't converge) and scaled 2x pixel
                                     # sprites (size_at != 1) shimmer more
const HEIGHT_SCALE := 1.0            # screen pixels per sim pixel of height (ball.z, jump_z, RIM_Z)
const RIM_Z := 10.0 * 12             # rim height in sim pixels (10 ft); the sim itself treats the rim as height 0
const SIDE_FLIP := false             # owner Q2 (a): the camera stays on the same sideline at the side switch (BLUE then
                                     # attacks left). true = option (b), view from the other sideline (main sets `flipped`)

# court geometry (same numbers as main.gd: FT = 12 px, 94 x 50 ft)
const FT := 12.0
const COURT_W := 94.0 * FT
const COURT_H := 50.0 * FT
# the floor point that stays where it is in both modes (the center circle), so anything not converted yet is still
# drawn near the right place, and FLAT vs ANGLED screenshots line up around the middle
const ANCHOR := Vector2(COURT_W / 2.0, COURT_H / 2.0)

static var perspective: float = PERSPECTIVE   # PERSPECTIVE, as a var so --perspective and --viewtest can try other values
static var flipped := false          # SIDE_FLIP is on and the sides have switched: the camera looks from the far side

static func angled() -> bool:
	return mode == ANGLED

# the camera on the other sideline turns the court 180 degrees around the center
static func _flip(p: Vector2) -> Vector2:
	return ANCHOR * 2.0 - p if flipped else p

# sprite scale for a (flipped) sim y: 1 at the center line of depth, smaller toward the far sideline
static func _scale_y(y: float) -> float:
	return maxf(0.1, 1.0 + perspective * (y - ANCHOR.y) / COURT_H)

# sim floor point p (pixels) at height h (sim pixels, like ball.z and jump_z) -> canvas pixels
static func to_screen(p: Vector2, h := 0.0) -> Vector2:
	if mode != ANGLED:
		return Vector2(p.x, p.y - h)
	var q: Vector2 = _flip(p)
	var s: float = _scale_y(q.y)
	return Vector2(ANCHOR.x + (q.x - ANCHOR.x) * s,
			ANCHOR.y + (q.y - ANCHOR.y) * TILT_Y - h * HEIGHT_SCALE * s)

# canvas pixels -> the sim floor point drawn there (the inverse of to_screen at h = 0)
static func to_floor(s: Vector2) -> Vector2:
	if mode != ANGLED:
		return s
	var y: float = ANCHOR.y + (s.y - ANCHOR.y) / TILT_Y
	var k: float = _scale_y(y)
	return _flip(Vector2(ANCHOR.x + (s.x - ANCHOR.x) / k, y))

# sprite scale at sim floor point p (1.0 without perspective, and always 1.0 in FLAT)
static func size_at(p: Vector2) -> float:
	if mode != ANGLED:
		return 1.0
	return _scale_y(_flip(p).y)

# a stick vector in screen terms (x right, y down; "up" = toward the far sideline as seen on screen) -> the sim
# direction that looks like that on screen, with the SAME LENGTH, so speed, turbo and the flick thresholds don't
# change. Uses the parallel part of the projection (perspective only bends directions slightly near the corners).
static func stick_to_world(v: Vector2) -> Vector2:
	if mode != ANGLED:
		return v
	var l: float = v.length()
	if l < 0.000001:
		return v
	var w: Vector2 = Vector2(v.x, v.y / TILT_Y).normalized() * l
	return -w if flipped else w

# the inverse: a sim direction -> the stick vector (screen terms) that moves that way (--humantest's thumb)
static func world_to_stick(v: Vector2) -> Vector2:
	if mode != ANGLED:
		return v
	var l: float = v.length()
	if l < 0.000001:
		return v
	var w: Vector2 = -v if flipped else v
	return Vector2(w.x, w.y * TILT_Y).normalized() * l

# a sim facing angle (radians, like player.facing) as it looks on screen at sim point p (choosing the sprite direction)
static func screen_angle(p: Vector2, world_angle: float) -> float:
	if mode != ANGLED:
		return world_angle
	var d: Vector2 = to_screen(p + Vector2.from_angle(world_angle) * FT) - to_screen(p)
	return d.angle()

# --viewtest (main.gd): round trips on a grid in both modes, with and without perspective and the side flip, and
# stick_to_world keeping length and inverting. Returns the failures (empty = OK). Leaves mode and flags as it found them.
static func self_test() -> PackedStringArray:
	var errs := PackedStringArray()
	var keep_mode: int = mode
	var keep_persp: float = perspective
	var keep_flip: bool = flipped
	for m in [FLAT, ANGLED]:
		for k in [PERSPECTIVE, 0.15]:
			for f in [false, true]:
				mode = m
				perspective = k
				flipped = f
				var tag := "mode %d persp %.2f flip %s" % [m, k, str(f)]
				var x := -6.0 * FT
				while x <= COURT_W + 6.0 * FT:
					var y := -6.0 * FT
					while y <= COURT_H + 6.0 * FT:
						var p := Vector2(x, y)
						var back: Vector2 = to_floor(to_screen(p, 0.0))
						if back.distance_to(p) >= 0.5:
							errs.append("%s: to_floor(to_screen(%s)) = %s" % [tag, str(p), str(back)])
						if to_screen(p, 30.0).y >= to_screen(p, 0.0).y:
							errs.append("%s: height doesn't go up at %s" % [tag, str(p)])
						y += 2.5 * FT
					x += 2.5 * FT
				for a in range(0, 360, 15):
					for l in [0.2, 0.7, 1.0]:
						var v: Vector2 = Vector2.from_angle(deg_to_rad(float(a))) * l
						var w: Vector2 = stick_to_world(v)
						if absf(w.length() - v.length()) > 0.0001:
							errs.append("%s: stick_to_world length %.4f -> %.4f" % [tag, v.length(), w.length()])
						if world_to_stick(w).distance_to(v) > 0.0001:
							errs.append("%s: world_to_stick(stick_to_world(%s)) = %s" % [tag, str(v), str(world_to_stick(w))])
						# the sim direction must look like the stick on screen (same screen angle)
						var c := Vector2(ANCHOR.x, ANCHOR.y)
						var seen: Vector2 = to_screen(c + w * 2.0 * FT) - to_screen(c)
						if m == ANGLED and k == 0.0 and absf(seen.angle_to(v)) > 0.001:
							errs.append("%s: stick %s moves on screen at %.1f deg" % [tag, str(v), rad_to_deg(seen.angle())])
	mode = keep_mode
	perspective = keep_persp
	flipped = keep_flip
	return errs
