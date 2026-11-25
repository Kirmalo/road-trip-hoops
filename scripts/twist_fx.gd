extends Node2D
# Twist effects (Phase 6, P6-14): what makes each city's twist readable on screen. Visual (and ambience) only: it
# reads the sim (players' positions, velocities, stamina, sliding, jumps; the ball; Twists.wind / gust) and never
# writes to it. Everything in the world is drawn through View (to_screen of a sim floor point and a height).
#
# main.gd adds this node (with `game` set) only when a twist is on, and calls show_banner() at tip-off. The banner
# also shows again after the side switch (seen from game.rules.sides_swapped).
#   wind      wind streaks and tumbling leaves blowing with Twists.wind (faster in a gust), a wind gauge under the HUD
#   crowd     camera flashes in the stands (a burst after every basket), the loud crowd loop
#   humid     heat shimmer over the floor, a warm tint, sweat flying off tired players
#   thin_air  breath puffs (quicker when sprinting or tired), a faint trail along the high arc of shots and lobs
#   wet       rain with splashes on the floor, a cool tint, splashes at running feet (a spray while a cut slides)
#   sand      sand puffs at the feet (bigger on turbo and landings)
#   cage      the banner only (the fence is court.gd's, the rattle ball.gd's)
# Ambience: audio.play_ambience() with the court look's "ambience" key if it has one, else AMBIENCE below.
# For P6-23's dust: ground_kind() ("sand", "wet" or "") and dust_color(default).
# Cost: one draw node on the floor (decals), one in the air (overlay) and the HUD; at most about 150 particles.

const View = preload("res://scripts/view.gd")
const Twists = preload("res://scripts/twists.gd")
const Looks = preload("res://scripts/court_looks.gd")

const FT := 12.0

# ---- banner ----
const BANNER_TIME := 4.5          # seconds on screen (slide in, hold, slide out)
const BANNER_SLIDE := 0.35        # seconds of the slide in and out
const BANNER_Y := 62.0            # screen px: top of the banner (under the 54 px HUD bar)
var banner_y: float = BANNER_Y     # P9-B4: a challenge game moves it under its goal line (challenge.gd)
const BANNER_W := 660.0
const BANNER_H := 76.0
const BANNER_NAME_SIZE := 32
const BANNER_LINE_SIZE := 19
const BANNER_BG := Color(0.07, 0.08, 0.13, 0.86)
const BANNER_EDGE := Color(1.0, 0.82, 0.25)
const BANNER_NAME_COLOR := Color(1.0, 0.9, 0.55)
const BANNER_LINE_COLOR := Color(1, 1, 1, 0.95)
const HIDE_MAIN_TWIST_LINE := true   # the banner carries main.gd's twist line too: hide main's copy while it shows

# ---- ambience (sfx loop names from P6-A5; a court look's "ambience" key wins) ----
const AMBIENCE := {"wind": "wind", "wet": "rain", "crowd": "crowd_loud"}
const AMBIENCE_DB := 0.0          # extra dB on top of audio.gd's level (crowd also gets Twists crowd_db there)

# ---- wind ----
const WIND_STREAKS := 30          # streaks in view
const WIND_LEAVES := 12           # tumbling leaves / paper bits
const WIND_SPEED := 260.0         # sim px/s of a streak at full gust (half of it at no gust)
const WIND_STREAK_LEN := 90.0     # sim px
const WIND_H_MIN := 8.0           # height range of the streaks (sim px)
const WIND_H_MAX := 150.0
const WIND_LIFE := 1.1            # seconds a streak lives (fades in and out)
const WIND_COLOR := Color(1, 1, 1, 0.75)
const LEAF_COLORS := [Color(0.85, 0.55, 0.2), Color(0.7, 0.75, 0.3), Color(0.92, 0.9, 0.82)]
const GAUGE_POS := Vector2(20, 64) # screen px: the wind gauge's top-left (under the clock)
const GAUGE_SIZE := Vector2(116, 46)

# ---- rain (wet) ----
const RAIN_DROPS := 110           # drops in view
const RAIN_FALL := 950.0          # sim px/s down
const RAIN_TOP := 420.0           # a drop starts this high (sim px), plus up to RAIN_TOP_JITTER
const RAIN_TOP_JITTER := 200.0
const RAIN_LEN := 22.0            # streak length (sim px of height)
const RAIN_SLANT := 3.0           # screen px the streak leans
const RAIN_COLOR := Color(0.78, 0.86, 1.0, 0.5)
const RAIN_SPLASH_CHANCE := 0.4   # a drop that lands in view leaves a ring this often
const WET_TINT := Color(0.25, 0.35, 0.55, 0.10)
const SPLASH_TIME := 0.35         # seconds a splash ring lasts
const SPLASH_COLOR := Color(0.8, 0.9, 1.0, 0.75)
const RING_SEGMENTS := 10         # sides of a splash ring
const SLIDE_SPRAY_EVERY := 0.05   # seconds between sprays while a player's cut slides
const SPLASH_SFX := "splash"
const SPLASH_SFX_DB := -8.0
const SPLASH_SFX_GAP := 1.2       # seconds between two splash sounds (slides are common: about one a second)

# ---- feet (wet splashes, sand puffs) ----
const STEP_MIN_SPEED := 70.0      # px/s: slower than this leaves no marks
const STEP_STRIDE := 52.0         # sim px per footstep
const SAND_COLOR := Color(0.93, 0.82, 0.6)
const SAND_PUFF_TIME := 0.5       # seconds a sand puff lasts
const SAND_PUFF_R := 9.0          # sim px radius of a normal puff (turbo x1.5, landing x2)
const SAND_SFX := "sand_step"
const SAND_SFX_DB := -12.0        # the human's turbo steps and anyone's landing near him
const SAND_SFX_GAP := 0.22

# ---- humid ----
const HUMID_TINT := Color(1.0, 0.55, 0.2, 0.12)
const SHIMMER_COLUMNS := 7        # heat haze columns in view
const SHIMMER_H := 110.0          # sim px tall
const SHIMMER_LIFE := 3.0         # seconds a column lives
const SHIMMER_COLOR := Color(1.0, 0.92, 0.75, 0.10)
const SWEAT_STAMINA := 0.4        # a player under this stamina (or turbo locked) sweats
const SWEAT_EVERY := 0.16         # seconds between drops
const SWEAT_COLOR := Color(0.7, 0.88, 1.0, 0.95)
const DROP_GRAVITY := 520.0       # sim px/s^2 (sweat, spray)

# ---- thin air ----
const BREATH_EVERY := 1.5         # seconds between breaths at rest
const BREATH_EVERY_HARD := 0.6    # ... sprinting or tired
const BREATH_TIME := 0.9
const BREATH_COLOR := Color(0.95, 0.97, 1.0, 0.75)
const ARC_TRAIL_LEN := 36         # remembered ball positions of a shot / lob in the air
const ARC_COLOR := Color(0.8, 0.92, 1.0, 0.55)

# ---- crowd ----
const FLASH_RATE := 10.0          # flashes per second in the stands
const FLASH_MAKE_BURST := 9       # extra flashes after a basket
const FLASH_TIME := 0.25
const FLASH_STANDS_Y_FT := -4.5   # the stands: just behind court.gd's backdrop line (BACK_GAP_FT 4) ...
const FLASH_H_MIN := 8.0          # ... at these heights (sim px), up to the top of the view
const FLASH_H_MAX := 190.0
const FLASH_HUD_PX := 58.0        # screen px: no flashes under the HUD bar

# player heights (sim px of height; HEIGHT_SCALE 1 = screen px): mouth and head of a v1 player (player.gd HEAD_PX 80).
# Taller sheets (v2, about 100) scale both by the player's view_head_scale() (P6-26).
const HEAD_H := 74.0
const MOUTH_H := 62.0

var game
var kind := ""                    # the twist id this node draws
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _floor_node: Node2D           # game.decals: splashes, puffs, flashes in the stands, heat haze
var _air_node: Node2D             # game.overlay: rain, wind, sweat, breath, the arc trail
var _hud: CanvasLayer
var _hud_node: Control            # banner and wind gauge
var _tint: ColorRect
var _font: Font
var _view := Rect2()              # the floor rect in view (sim px), refreshed every frame
var _parts: Array = []            # air particles: {c, p (floor), h, v (floor vel), vh, g (gravity), t, life, k}
var _drops: Array = []            # rain: {p (floor), h}, recycled in place
var _marks: Array = []            # floor marks: {p, t, life, k, c (kind)}
var _feet := {}                   # player instance id -> {step, last_jump, slide, breath, sweat}
var _trail: Array = []            # thin air: screen points of the ball in flight
var _banner_t := -1.0             # seconds since the banner started (< 0: hidden)
var _banner_info := {}
var _was_swapped := false
var _last_score := 0
var _sfx_gap := 0.0
var _amb_stopped := false
var _shot_dir := ""               # test only: -- --twistshots DIR
var _shot_frame := 0

# test only: -- --twistshots DIR (xvfb, not headless): screenshots of this twist to DIR/hoops_twist_<id>_<frame>.png
# at these frames (the first with the banner), then quits. Its own file names, so parallel test runs that use
# main.gd's /tmp/hoops_<frame>.png don't overwrite them.
const TWIST_SHOT_FRAMES := [100, 600, 1300]

func _ready() -> void:
	_rng.randomize()
	kind = Twists.current
	if game == null or not Twists.active():
		set_process(false)
		return
	_font = ThemeDB.fallback_font
	_banner_info = Twists.info()
	_floor_node = Node2D.new()
	_floor_node.name = "TwistFloor"
	_floor_node.draw.connect(_draw_floor)
	game.decals.add_child(_floor_node)
	_air_node = Node2D.new()
	_air_node.name = "TwistAir"
	_air_node.draw.connect(_draw_air)
	game.overlay.add_child(_air_node)
	_hud = CanvasLayer.new()
	_hud.layer = 11               # over the game HUD (10), under nothing that takes taps (it ignores the mouse)
	add_child(_hud)
	var tint_col: Color = HUMID_TINT if kind == "humid" else (WET_TINT if kind == "wet" else Color(0, 0, 0, 0))
	if tint_col.a > 0.0:
		var tl := CanvasLayer.new()
		tl.layer = 1              # over the game world, under the HUD
		add_child(tl)
		_tint = ColorRect.new()
		_tint.color = tint_col
		_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
		tl.add_child(_tint)
	_hud_node = Control.new()
	_hud_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_node.draw.connect(_draw_hud)
	_hud.add_child(_hud_node)
	_last_score = _score_sum()
	_start_ambience()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var at: int = args.find("--twistshots")
	if at >= 0 and DisplayServer.get_name() != "headless":
		_shot_dir = args[at + 1] if at + 1 < args.size() else "/tmp"
		DirAccess.make_dir_recursive_absolute(_shot_dir)

func _twist_shots() -> void:
	_shot_frame += 1
	if not TWIST_SHOT_FRAMES.has(_shot_frame):
		return
	var path: String = "%s/hoops_twist_%s_%d.png" % [_shot_dir.trim_suffix("/"), kind, _shot_frame]
	get_viewport().get_texture().get_image().save_png(path)
	print("TWISTSHOT ", path)
	if _shot_frame == TWIST_SHOT_FRAMES[TWIST_SHOT_FRAMES.size() - 1]:
		get_tree().quit()

func _start_ambience() -> void:
	var amb: String = str(Looks.look().get("ambience", ""))
	if amb == "":
		amb = str(AMBIENCE.get(kind, ""))
	if amb != "" and game.audio != null and game.audio.has_method("play_ambience"):
		game.audio.play_ambience(amb, AMBIENCE_DB)

# ---------------- public ----------------

# The banner: the twist's icon, name and line, sliding in under the HUD bar (main.gd: tip-off; here: side switch)
func show_banner() -> void:
	if not Twists.active():
		return
	_banner_info = Twists.info()
	_banner_t = 0.0
	if game != null:
		game.stat("twist_banners")

# P6-23 (dust on hard cuts and landings): "sand", "wet" or "" for this court
func ground_kind() -> String:
	if kind == "sand":
		return "sand"
	if kind == "wet":
		return "wet"
	return ""

# P6-23: the color for dust puffs here (sand-colored on the beach, splash-colored on the wet court)
func dust_color(default := Color(0.85, 0.8, 0.7)) -> Color:
	match kind:
		"sand":
			return SAND_COLOR
		"wet":
			return SPLASH_COLOR
	return default

# ---------------- update ----------------

func _process(delta: float) -> void:
	_t += delta
	_sfx_gap = maxf(0.0, _sfx_gap - delta)
	_update_view_rect()
	_watch_game()
	match kind:
		"wind":
			_update_wind(delta)
		"wet":
			_update_rain(delta)
			_update_feet(delta)
		"sand":
			_update_feet(delta)
		"humid":
			_update_humid(delta)
		"thin_air":
			_update_thin_air(delta)
		"crowd":
			_update_crowd(delta)
	_age(delta)
	_floor_node.queue_redraw()
	_air_node.queue_redraw()
	if _banner_t >= 0.0:
		_banner_t += delta
		if HIDE_MAIN_TWIST_LINE and game.get("twist_label") != null:
			(game.twist_label as Label).visible = false
		if _banner_t > BANNER_TIME:
			_banner_t = -1.0
			_hud_node.queue_redraw()   # P10-B7: clear the last banner frame
	if _banner_t >= 0.0 or kind == "wind":
		_hud_node.queue_redraw()
	if _shot_dir != "":
		_twist_shots()

# the side switch (banner again), baskets (crowd flashes) and the end of the game (ambience off)
func _watch_game() -> void:
	var r = game.rules
	if r != null:
		var sw: bool = bool(r.sides_swapped)
		if sw != _was_swapped:
			_was_swapped = sw
			show_banner()
	if game.game_over and not _amb_stopped:
		_amb_stopped = true
		if game.audio != null and game.audio.has_method("stop_ambience"):
			game.audio.stop_ambience()

func _score_sum() -> int:
	return int(game.score[0]) + int(game.score[1])

# the floor rectangle in view (sim px), from the canvas transform (camera, zoom and shake)
func _update_view_rect() -> void:
	var inv: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
	var sz: Vector2 = get_viewport().get_visible_rect().size
	var a: Vector2 = View.to_floor(inv * Vector2.ZERO)
	var b: Vector2 = View.to_floor(inv * sz)
	_view = Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs())

func _rand_floor(margin := 0.0) -> Vector2:
	return Vector2(_rng.randf_range(_view.position.x - margin, _view.end.x + margin),
			_rng.randf_range(_view.position.y - margin, _view.end.y + margin))

func _age(delta: float) -> void:
	if not _marks.is_empty():
		for m in _marks:
			m.t += delta
		_marks = _marks.filter(func(m): return m.t < m.life)

func _count(c: String) -> int:
	var n := 0
	for q in _parts:
		if q.c == c:
			n += 1
	return n

# moves the air particles: floor velocity v, height speed vh (gravity when g), drops dead ones
func _move_parts(delta: float) -> void:
	var dead := false
	for q in _parts:
		q.t += delta
		q.p += q.v * delta
		q.h += q.vh * delta
		if q.g:
			q.vh -= DROP_GRAVITY * delta
			dead = dead or q.h <= -2.0   # falling bits end on the floor
		dead = dead or q.t >= q.life
	if dead:
		_parts = _parts.filter(func(q): return q.t < q.life and (q.h > -2.0 or not q.g))

# ---- wind ----

func _update_wind(delta: float) -> void:
	var w: Vector2 = Twists.wind
	if w == Vector2.ZERO:
		return
	var spd: float = WIND_SPEED * lerpf(0.5, 1.0, Twists.gust)
	for q in _parts:
		q.v = w * spd * float(q.k)   # gusts change the speed of everything in the air
	_move_parts(delta)
	var span: float = _view.size.y + 2.0 * WIND_STREAK_LEN
	for i in WIND_STREAKS - _count("streak"):
		var p: Vector2 = _rand_floor(WIND_STREAK_LEN)
		_parts.append({"c": "streak", "g": false, "p": p, "h": _rng.randf_range(WIND_H_MIN, WIND_H_MAX), "v": w * spd,
				"vh": 0.0, "t": 0.0, "life": WIND_LIFE * _rng.randf_range(0.7, 1.3), "k": _rng.randf_range(0.8, 1.2),
				"ph": _rng.randf_range(0.0, TAU)})
	for i in WIND_LEAVES - _count("leaf"):
		var p2: Vector2 = _rand_floor(0.0)
		p2 -= w * span * 0.5 * _rng.randf()   # upwind, so it crosses the view
		_parts.append({"c": "leaf", "g": false, "p": p2, "h": _rng.randf_range(4.0, 60.0), "v": w * spd, "vh": 0.0, "t": 0.0,
				"life": 2.5, "k": _rng.randf_range(0.9, 1.3), "ph": _rng.randf_range(0.0, TAU),
				"col": LEAF_COLORS[_rng.randi() % LEAF_COLORS.size()]})

# ---- rain and splashes ----

func _update_rain(delta: float) -> void:
	_move_parts(delta)
	if _drops.is_empty():
		for i in RAIN_DROPS:   # the first frame: rain already everywhere
			_drops.append({"p": _rand_floor(FT), "h": _rng.randf_range(0.0, RAIN_TOP + RAIN_TOP_JITTER)})
	var fall: float = RAIN_FALL * delta
	for q in _drops:
		q.h -= fall
		if q.h > 0.0:
			continue
		# landed: maybe a ring, then the same drop starts again from the top somewhere in view
		if _view.has_point(q.p) and _rng.randf() < RAIN_SPLASH_CHANCE:
			_marks.append({"c": "ring", "p": q.p, "t": 0.0, "life": SPLASH_TIME, "k": 0.6})
		q.p = _rand_floor(FT)
		q.h = RAIN_TOP + _rng.randf_range(0.0, RAIN_TOP_JITTER)

# footsteps: splashes (wet) or sand puffs (sand), a spray while a cut slides, a bigger mark on a landing
func _update_feet(delta: float) -> void:
	for p in game.players:
		var key: int = p.get_instance_id()
		if not _feet.has(key):
			_feet[key] = {"step": _rng.randf(), "air": false, "slide": false, "spray": 0.0}
		var f: Dictionary = _feet[key]
		var pos: Vector2 = p.position
		var vel: Vector2 = p.velocity
		var spd: float = vel.length()
		var in_air: bool = float(p.jump_z) > 0.5 or float(p.block_jump_t) >= 0.0
		if bool(f.air) and not in_air:
			_foot_mark(pos, 2.0, p)   # landing
		f.air = in_air
		var sliding: bool = kind == "wet" and bool(p.get("sliding"))
		if sliding:
			f.spray = float(f.spray) - delta
			if float(f.spray) <= 0.0:
				f.spray = SLIDE_SPRAY_EVERY
				_spray(pos, vel)
			if not bool(f.slide):
				game.stat("twist_fx_slide_sprays")
				if _view.has_point(pos):
					_play_sfx(SPLASH_SFX, SPLASH_SFX_DB)
		f.slide = sliding
		if in_air or spd < STEP_MIN_SPEED:
			continue
		f.step = float(f.step) - delta * spd / STEP_STRIDE
		if float(f.step) <= 0.0:
			f.step = 1.0
			var big: float = 1.5 if bool(p.turbo) else 1.0
			_foot_mark(pos - vel.normalized() * 6.0, big, p)
			if kind == "sand" and bool(p.turbo) and game.is_human(p):
				_play_sfx(SAND_SFX, SAND_SFX_DB)

func _foot_mark(pos: Vector2, k: float, p) -> void:
	if kind == "sand":
		_marks.append({"c": "sand", "p": pos, "t": 0.0, "life": SAND_PUFF_TIME * (1.0 + 0.3 * (k - 1.0)), "k": k})
		if k >= 2.0 and game.is_human(p):
			_play_sfx(SAND_SFX, SAND_SFX_DB)
	else:
		_marks.append({"c": "ring", "p": pos, "t": 0.0, "life": SPLASH_TIME, "k": 0.8 * k})

func _spray(pos: Vector2, vel: Vector2) -> void:
	_marks.append({"c": "ring", "p": pos, "t": 0.0, "life": SPLASH_TIME, "k": 1.4})
	var fwd: Vector2 = vel.normalized()
	for i in 3:
		var side: Vector2 = fwd.orthogonal() * _rng.randf_range(-1.0, 1.0)
		_parts.append({"c": "spray", "p": pos, "h": 2.0, "v": (fwd * 0.6 + side) * _rng.randf_range(60.0, 140.0),
				"vh": _rng.randf_range(90.0, 170.0), "g": true, "t": 0.0, "life": 0.6, "k": 1.0})

func _play_sfx(n: String, db: float) -> void:
	if _sfx_gap > 0.0 or game.audio == null:
		return
	_sfx_gap = SPLASH_SFX_GAP if n == SPLASH_SFX else SAND_SFX_GAP
	game.audio.play(n, db, 0.1)

# ---- humid ----

func _update_humid(delta: float) -> void:
	_move_parts(delta)
	for i in SHIMMER_COLUMNS - _count("haze"):
		_parts.append({"c": "haze", "g": false, "p": _rand_floor(0.0), "h": 0.0, "v": Vector2.ZERO, "vh": 0.0, "t": 0.0,
				"life": SHIMMER_LIFE * _rng.randf_range(0.7, 1.3), "k": _rng.randf_range(0.7, 1.2),
				"ph": _rng.randf_range(0.0, TAU)})
	for p in game.players:
		var key: int = p.get_instance_id()
		if not _feet.has(key):
			_feet[key] = {"sweat": _rng.randf() * SWEAT_EVERY}
		var f: Dictionary = _feet[key]
		if float(p.stamina) >= SWEAT_STAMINA and not bool(p.turbo_locked):
			continue
		f.sweat = float(f.sweat) - delta
		if float(f.sweat) > 0.0:
			continue
		f.sweat = SWEAT_EVERY
		var dir: Vector2 = Vector2.from_angle(_rng.randf_range(0.0, TAU))
		_parts.append({"c": "sweat", "p": p.position + dir * 5.0, "h": _lift(p) + HEAD_H * _head_scale(p), "v": dir * _rng.randf_range(30.0, 70.0),
				"vh": _rng.randf_range(40.0, 110.0), "g": true, "t": 0.0, "life": 0.7, "k": 1.0})

# ---- thin air ----

func _update_thin_air(delta: float) -> void:
	for q in _parts:
		q.k = float(q.k) + delta * 12.0   # breath grows (radius in px)
	_move_parts(delta)
	for p in game.players:
		var key: int = p.get_instance_id()
		if not _feet.has(key):
			_feet[key] = {"breath": _rng.randf() * BREATH_EVERY}
		var f: Dictionary = _feet[key]
		f.breath = float(f.breath) - delta
		if float(f.breath) > 0.0:
			continue
		var hard: bool = bool(p.turbo) or float(p.stamina) < 0.5
		f.breath = (BREATH_EVERY_HARD if hard else BREATH_EVERY) * _rng.randf_range(0.85, 1.15)
		var fwd: Vector2 = Vector2.from_angle(float(p.facing))
		_parts.append({"c": "breath", "g": false, "p": p.position + fwd * 8.0, "h": _lift(p) + MOUTH_H * _head_scale(p),
				"v": fwd * 14.0 + p.velocity * 0.3, "vh": 16.0, "t": 0.0, "life": BREATH_TIME, "k": 4.0})
	# the arc trail: the ball's drawn point while a jump shot or a lob is in the air
	var b = game.ball
	var flying: bool = b != null and ((b.state == b.SHOT and str(b.shot_kind) == "") or (b.state == b.PASS and bool(b.lob)))
	if flying:
		_trail.append(b.v_screen)
		while _trail.size() > ARC_TRAIL_LEN:
			_trail.pop_front()
	elif not _trail.is_empty():
		_trail.pop_front()
		if not _trail.is_empty():
			_trail.pop_front()

# ---- crowd ----

func _update_crowd(delta: float) -> void:
	_move_parts(delta)
	var n: int = 0
	if _rng.randf() < FLASH_RATE * delta:
		n = 1
	var s: int = _score_sum()
	if s != _last_score:
		_last_score = s
		n += FLASH_MAKE_BURST
	if n == 0:
		return
	# the stands seen between the HUD bar and the floor: heights up to the top of the view
	var inv: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
	var top_y: float = (inv * Vector2(0, FLASH_HUD_PX)).y
	for i in n:
		var p := Vector2(_rng.randf_range(_view.position.x, _view.end.x), FLASH_STANDS_Y_FT * FT - _rng.randf_range(0.0, FT))
		var h_max: float = clampf(View.to_screen(p, 0.0).y - top_y, FLASH_H_MIN + 1.0, FLASH_H_MAX)
		_marks.append({"c": "flash", "p": p, "h": _rng.randf_range(FLASH_H_MIN, h_max), "t": -_rng.randf_range(0.0, 0.5) if n > 1 else 0.0,
				"life": FLASH_TIME, "k": _rng.randf_range(0.7, 1.2)})

# drawn jump height of a player (player.gd's own, else jump_z)
func _lift(p) -> float:
	var l = p.get("_v_lift")
	return float(l) if l != null else float(p.jump_z)

# how much taller p is drawn than a v1 player (player.gd view_head_scale(): 1.0 on v1, about 1.25 on v2)
func _head_scale(p) -> float:
	if p.has_method("view_head_scale"):
		return float(p.view_head_scale())
	return 1.0

# ---------------- drawing ----------------

# floor layer (decals: over the floor and the backdrop, under the players)
func _draw_floor() -> void:
	var n := _floor_node
	var ring_pts := PackedVector2Array()   # every splash ring in one draw call
	var ring_cols := PackedColorArray()
	for m in _marks:
		var a: float = clampf(float(m.t) / float(m.life), 0.0, 1.0)
		if float(m.t) < 0.0:
			continue
		match str(m.c):
			"ring":
				var r: float = 4.0 + 10.0 * float(m.k) * a
				var rc := Color(SPLASH_COLOR, SPLASH_COLOR.a * (1.0 - a))
				var pts: PackedVector2Array = _ring(m.p, r, RING_SEGMENTS)
				for i in RING_SEGMENTS:
					ring_pts.append(pts[i])
					ring_pts.append(pts[i + 1])
					ring_cols.append(rc)
			"sand":
				var k: float = float(m.k)
				var r2: float = SAND_PUFF_R * k * (0.4 + 0.6 * a)
				var col := Color(SAND_COLOR, 0.55 * (1.0 - a))
				for i in 5:
					var off: Vector2 = Vector2.from_angle(TAU * float(i) / 5.0 + 0.3) * r2
					n.draw_circle(View.to_screen(m.p + off, 2.0 + 6.0 * a * k), (2.5 + 2.0 * k) * (1.0 - 0.4 * a), col)
			"flash":
				var c: Vector2 = View.to_screen(m.p, m.h)
				var fk: float = (1.0 - a) * float(m.k)
				n.draw_circle(c, 10.0 * fk, Color(1, 1, 0.9, 0.3 * (1.0 - a)))
				n.draw_circle(c, 5.0 * fk, Color(1, 1, 0.95, 0.6 * (1.0 - a)))
				n.draw_line(c - Vector2(12, 0) * fk, c + Vector2(12, 0) * fk, Color(1, 1, 1, 0.95 * (1.0 - a)), 2.0)
				n.draw_line(c - Vector2(0, 12) * fk, c + Vector2(0, 12) * fk, Color(1, 1, 1, 0.95 * (1.0 - a)), 2.0)
				n.draw_circle(c, 3.0 * fk, Color.WHITE)
	if not ring_pts.is_empty():
		n.draw_multiline_colors(ring_pts, ring_cols, 1.5)
	if kind == "humid":
		for q in _parts:
			if q.c != "haze":
				continue
			var life_a: float = sin(PI * clampf(float(q.t) / float(q.life), 0.0, 1.0))
			var pts := PackedVector2Array()
			for i in 9:
				var h: float = SHIMMER_H * float(i) / 8.0
				var base: Vector2 = View.to_screen(q.p, h)
				pts.append(base + Vector2(3.0 * float(q.k) * sin(_t * 3.0 + h * 0.09 + float(q.ph)), 0))
			n.draw_polyline(pts, Color(SHIMMER_COLOR, SHIMMER_COLOR.a * life_a), 6.0 * float(q.k))
			n.draw_polyline(pts, Color(SHIMMER_COLOR, SHIMMER_COLOR.a * life_a * 1.5), 2.0)

# air layer (overlay: over the players)
func _draw_air() -> void:
	var n := _air_node
	var rain := PackedVector2Array()   # every rain streak in one draw call
	var streaks := PackedVector2Array()   # every wind streak in one draw call
	var streak_cols := PackedColorArray()
	for q in _drops:
		rain.append(View.to_screen(q.p, q.h + RAIN_LEN) + Vector2(RAIN_SLANT, 0))
		rain.append(View.to_screen(q.p, maxf(0.0, q.h)))
	for q in _parts:
		match str(q.c):
			"streak":
				var a: float = sin(PI * clampf(float(q.t) / float(q.life), 0.0, 1.0))
				var w: Vector2 = Twists.wind
				var sc := Color(WIND_COLOR, WIND_COLOR.a * a * (0.5 + 0.5 * Twists.gust))
				var prev := Vector2.ZERO
				for i in 6:
					var f: float = float(i) / 5.0
					var p: Vector2 = q.p - w * WIND_STREAK_LEN * float(q.k) * f
					var pt: Vector2 = View.to_screen(p, q.h) + Vector2(7.0 * sin(f * 4.0 + float(q.ph) + _t * 6.0), 0)
					if i > 0:
						streaks.append(prev)
						streaks.append(pt)
						streak_cols.append(sc)
					prev = pt
			"leaf":
				var c: Vector2 = View.to_screen(q.p, q.h + 6.0 * sin(_t * 5.0 + float(q.ph)))
				var ang: float = _t * 8.0 * float(q.k) + float(q.ph)
				var d: Vector2 = Vector2.from_angle(ang) * 6.0
				var e: Vector2 = d.orthogonal() * 0.5
				var col: Color = q.col
				n.draw_colored_polygon(PackedVector2Array([c - d, c - e, c + d, c + e]), col)
			"spray", "sweat":
				var col2: Color = SWEAT_COLOR if q.c == "sweat" else SPLASH_COLOR
				var c2: Vector2 = View.to_screen(q.p, maxf(0.0, q.h))
				n.draw_circle(c2, 2.0 if q.c == "sweat" else 1.8, col2)
			"breath":
				var a2: float = clampf(float(q.t) / float(q.life), 0.0, 1.0)
				var c3: Vector2 = View.to_screen(q.p, q.h)
				var col3 := Color(BREATH_COLOR, BREATH_COLOR.a * (1.0 - a2))
				n.draw_circle(c3, float(q.k), col3)
				n.draw_circle(c3 + Vector2(float(q.k) * 0.7, -float(q.k) * 0.4), float(q.k) * 0.7, col3)
	if not rain.is_empty():
		n.draw_multiline(rain, RAIN_COLOR, 1.5)
	if not streaks.is_empty():
		n.draw_multiline_colors(streaks, streak_cols, 2.5)
	var nt: int = _trail.size()
	for i in nt:
		if i % 2 == 1:
			continue   # dotted
		var k: float = float(i + 1) / float(nt)
		n.draw_circle(_trail[i], 1.5 + 2.0 * k, Color(ARC_COLOR, ARC_COLOR.a * k))

# a ring on the floor of radius r (sim px) around sim point c, projected
# (the projection is affine on the floor, so the ring's two projected axes give every point: 3 View calls, not 11)
func _ring(c: Vector2, r: float, segments: int) -> PackedVector2Array:
	var o: Vector2 = View.to_screen(c)
	var ex: Vector2 = View.to_screen(c + Vector2(r, 0)) - o
	var ey: Vector2 = View.to_screen(c + Vector2(0, r)) - o
	var pts := PackedVector2Array()
	for i in segments + 1:
		var a: float = TAU * float(i) / float(segments)
		pts.append(o + ex * cos(a) + ey * sin(a))
	return pts

# HUD layer: the banner and the wind gauge (screen space)
func _draw_hud() -> void:
	var n := _hud_node
	if kind == "wind":
		_draw_wind_gauge(n)
	if _banner_t < 0.0:
		return
	var sw: float = n.size.x
	var x_in: float = 1.0
	if _banner_t < BANNER_SLIDE:
		x_in = _ease(_banner_t / BANNER_SLIDE)
	elif _banner_t > BANNER_TIME - BANNER_SLIDE:
		x_in = _ease((BANNER_TIME - _banner_t) / BANNER_SLIDE)
	var x: float = lerpf(-BANNER_W, (sw - BANNER_W) / 2.0, x_in)
	var r := Rect2(x, banner_y, BANNER_W, BANNER_H)
	n.draw_rect(r, BANNER_BG)
	n.draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), BANNER_EDGE)
	n.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 3), Vector2(r.size.x, 3)), BANNER_EDGE)
	var icon_c := Vector2(x + 44.0, banner_y + BANNER_H / 2.0)
	n.draw_circle(icon_c, 28.0, Color(0.16, 0.2, 0.32))
	n.draw_arc(icon_c, 28.0, 0.0, TAU, 32, BANNER_EDGE, 2.0)
	_draw_icon(n, str(_banner_info.get("icon", "")), icon_c, 20.0)
	var tx: float = x + 88.0
	var name_s: String = str(_banner_info.get("name", ""))
	var line_s: String = str(_banner_info.get("banner", ""))
	n.draw_string_outline(_font, Vector2(tx, banner_y + 36.0), name_s, HORIZONTAL_ALIGNMENT_LEFT, BANNER_W - 100.0,
			BANNER_NAME_SIZE, 5, Color(0, 0, 0, 0.85))
	n.draw_string(_font, Vector2(tx, banner_y + 36.0), name_s, HORIZONTAL_ALIGNMENT_LEFT, BANNER_W - 100.0,
			BANNER_NAME_SIZE, BANNER_NAME_COLOR)
	n.draw_string_outline(_font, Vector2(tx, banner_y + 63.0), line_s, HORIZONTAL_ALIGNMENT_LEFT, BANNER_W - 100.0,
			BANNER_LINE_SIZE, 4, Color(0, 0, 0, 0.85))
	n.draw_string(_font, Vector2(tx, banner_y + 63.0), line_s, HORIZONTAL_ALIGNMENT_LEFT, BANNER_W - 100.0,
			BANNER_LINE_SIZE, BANNER_LINE_COLOR)

func _ease(f: float) -> float:
	var g: float = clampf(f, 0.0, 1.0)
	return 1.0 - (1.0 - g) * (1.0 - g)

# a small panel under the clock: an arrow the way the wind blows on screen, longer and brighter in a gust
func _draw_wind_gauge(n: Control) -> void:
	var w: Vector2 = Twists.wind
	if w == Vector2.ZERO:
		return
	var r := Rect2(GAUGE_POS, GAUGE_SIZE)
	n.draw_rect(r, Color(0, 0, 0, 0.5))
	n.draw_string(_font, GAUGE_POS + Vector2(8, 28), "WIND", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.9))
	var c: Vector2 = GAUGE_POS + Vector2(GAUGE_SIZE.x - 30.0, GAUGE_SIZE.y / 2.0)
	var mid := Vector2(View.COURT_W / 2.0, View.COURT_H / 2.0)
	var d: Vector2 = (View.to_screen(mid + w * FT) - View.to_screen(mid)).normalized()
	var g: float = Twists.gust
	var l: float = lerpf(9.0, 18.0, g)
	var col := Color(1.0, 0.9, 0.55).lerp(Color.WHITE, g)
	var tip: Vector2 = c + d * l
	n.draw_line(c - d * l, tip, col, 4.0)
	var o: Vector2 = d.orthogonal() * 7.0
	n.draw_colored_polygon(PackedVector2Array([tip + d * 6.0, tip + o, tip - o]), col)
	# gust bars
	for i in 3:
		var on: bool = g > float(i) / 3.0 + 0.1
		n.draw_rect(Rect2(GAUGE_POS + Vector2(54.0 + 6.0 * float(i), 34.0 - 4.0 * float(i)), Vector2(4, 6 + 4.0 * float(i))),
				Color(1, 1, 1, 0.9 if on else 0.2))

# the banner icon for Twists.info().icon, drawn in a circle of radius s around c
func _draw_icon(n: CanvasItem, icon: String, c: Vector2, s: float) -> void:
	var white := Color(1, 1, 1, 0.95)
	match icon:
		"wind":
			for i in 3:
				var y: float = c.y - s * 0.5 + s * 0.5 * float(i)
				var pts := PackedVector2Array()
				for k in 9:
					var f: float = float(k) / 8.0
					pts.append(Vector2(c.x - s + 2.0 * s * f * (0.7 + 0.15 * float(i % 2)), y + 3.0 * sin(f * 6.0)))
				n.draw_polyline(pts, white, 3.0)
		"crowd":
			for i in 4:
				var hx: float = c.x - s * 0.75 + s * 0.5 * float(i)
				var hy: float = c.y + (2.0 if i % 2 == 0 else -2.0)
				n.draw_circle(Vector2(hx, hy - 5.0), 5.0, white)
				n.draw_rect(Rect2(hx - 6.0, hy + 1.0, 12.0, 10.0), white)
			n.draw_line(c + Vector2(s * 0.5, -s * 0.9), c + Vector2(s * 0.8, -s * 0.5), Color(1, 0.9, 0.4), 2.0)
		"humid":
			n.draw_circle(c + Vector2(-4, -3), s * 0.45, Color(1.0, 0.75, 0.3))
			for i in 3:
				var pts2 := PackedVector2Array()
				for k in 7:
					var f2: float = float(k) / 6.0
					pts2.append(Vector2(c.x - s * 0.8 + s * 1.6 * f2, c.y + s * 0.35 + 5.0 * float(i) + 2.0 * sin(f2 * 9.0)))
				n.draw_polyline(pts2, white, 2.0)
		"thin_air":
			n.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, s * 0.7), c + Vector2(-s * 0.2, -s * 0.7),
					c + Vector2(s * 0.3, s * 0.1), c + Vector2(s * 0.55, -s * 0.3), c + Vector2(s, s * 0.7)]), white)
			n.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, -s * 0.3), c + Vector2(-s * 0.2, -s * 0.7),
					c + Vector2(s * 0.02, -s * 0.3)]), Color(0.6, 0.8, 1.0))
		"wet":
			n.draw_circle(c + Vector2(-6, -5), 8.0, white)
			n.draw_circle(c + Vector2(5, -7), 10.0, white)
			n.draw_rect(Rect2(c.x - 14.0, c.y - 6.0, 28.0, 8.0), white)
			for i in 3:
				var dx: float = -10.0 + 10.0 * float(i)
				n.draw_line(c + Vector2(dx + 2.0, 6.0), c + Vector2(dx - 1.0, 15.0), Color(0.6, 0.85, 1.0), 2.5)
		"sand":
			n.draw_circle(c + Vector2(6, -6), s * 0.38, Color(1.0, 0.8, 0.3))
			n.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, s * 0.7), c + Vector2(-s * 0.3, s * 0.05),
					c + Vector2(s * 0.3, s * 0.4), c + Vector2(s, s * 0.15), c + Vector2(s, s * 0.7)]), SAND_COLOR)
		"cage":
			var r := Rect2(c - Vector2(s, s) * 0.8, Vector2(s, s) * 1.6)
			n.draw_rect(r, white, false, 2.0)
			for i in 4:
				var f3: float = float(i + 1) / 5.0
				n.draw_line(Vector2(r.position.x + r.size.x * f3, r.position.y), Vector2(r.position.x, r.position.y + r.size.y * f3), white, 1.5)
				n.draw_line(Vector2(r.position.x + r.size.x * f3, r.end.y), Vector2(r.end.x, r.position.y + r.size.y * f3), white, 1.5)
		"era_grand":
			# an old laced leather ball: brown panels, two curved seams and the laced slit across the top
			var br: float = s * 0.8
			n.draw_circle(c, br + 2.0, Color(0.16, 0.09, 0.05))
			n.draw_circle(c, br, Color(0.62, 0.38, 0.2))
			n.draw_circle(c + Vector2(-br * 0.3, -br * 0.3), br * 0.35, Color(0.74, 0.5, 0.3))
			var seam := Color(0.22, 0.12, 0.06)
			n.draw_arc(c + Vector2(-br * 1.35, 0.0), br * 1.05, -0.85, 0.85, 12, seam, 2.0)
			n.draw_arc(c + Vector2(br * 1.35, 0.0), br * 1.05, PI - 0.85, PI + 0.85, 12, seam, 2.0)
			var ly: float = c.y - br * 0.45
			n.draw_line(Vector2(c.x - br * 0.45, ly), Vector2(c.x + br * 0.45, ly), seam, 3.0)
			for i in 4:
				var lx: float = c.x - br * 0.36 + br * 0.24 * float(i)
				n.draw_line(Vector2(lx - 2.0, ly - 3.0), Vector2(lx + 2.0, ly + 3.0), Color(0.96, 0.92, 0.8), 1.5)
		"era_fathers":
			# ISO BALL (P10-12): a modern orange ball with black seams, and the crossover's zigzag arrow beside it
			var bc: Vector2 = c + Vector2(s * 0.28, -s * 0.12)
			var r2: float = s * 0.62
			n.draw_circle(bc, r2 + 2.0, Color(0.08, 0.05, 0.04))
			n.draw_circle(bc, r2, Color(0.95, 0.5, 0.14))
			n.draw_circle(bc + Vector2(-r2 * 0.3, -r2 * 0.3), r2 * 0.32, Color(1.0, 0.66, 0.32))
			var sm := Color(0.1, 0.06, 0.04)
			n.draw_line(bc + Vector2(-r2, 0.0), bc + Vector2(r2, 0.0), sm, 2.0)
			n.draw_line(bc + Vector2(0.0, -r2), bc + Vector2(0.0, r2), sm, 2.0)
			n.draw_arc(bc + Vector2(-r2 * 1.2, 0.0), r2 * 0.95, -0.8, 0.8, 10, sm, 2.0)
			n.draw_arc(bc + Vector2(r2 * 1.2, 0.0), r2 * 0.95, PI - 0.8, PI + 0.8, 10, sm, 2.0)
			var zz := PackedVector2Array([c + Vector2(-s * 0.95, -s * 0.2), c + Vector2(-s * 0.55, s * 0.3),
					c + Vector2(-s * 0.2, s * 0.05), c + Vector2(s * 0.25, s * 0.75)])
			n.draw_polyline(zz, Color(1.0, 0.95, 0.3), 3.0)
			var tip: Vector2 = zz[3]
			var d2: Vector2 = (zz[3] - zz[2]).normalized()
			var o2: Vector2 = d2.orthogonal() * 5.0
			n.draw_colored_polygon(PackedVector2Array([tip + d2 * 6.0, tip + o2, tip - o2]), Color(1.0, 0.95, 0.3))
		"era_present":
			# SPACE THE FLOOR (P11-12): a half court from above in the era's teal and coral: the arc, the hoop, and
			# three shooters' dots spread out beyond it with little arrows pointing wider
			var teal := Color(0.18, 0.78, 0.74)
			var coral := Color(1.0, 0.5, 0.4)
			var hp: Vector2 = c + Vector2(0.0, s * 0.75)
			n.draw_arc(hp, s * 0.75, PI + 0.15, TAU - 0.15, 16, teal, 3.0)
			n.draw_line(hp + Vector2(-s * 0.3, s * 0.05), hp + Vector2(s * 0.3, s * 0.05), white, 2.0)
			n.draw_circle(hp + Vector2(0.0, -s * 0.12), s * 0.12, coral)
			for i in 3:
				var a: float = PI + 0.45 + (PI - 0.9) * float(i) / 2.0
				var u := Vector2(cos(a), sin(a))
				var dp: Vector2 = hp + u * s * 1.02
				n.draw_circle(dp, s * 0.17 + 1.0, Color(0.05, 0.08, 0.1))
				n.draw_circle(dp, s * 0.17, coral)
				n.draw_line(hp + u * s * 0.4, hp + u * s * 0.66, white, 1.5)
		_:
			n.draw_circle(c, s * 0.4, white)

func _exit_tree() -> void:
	if _floor_node != null and is_instance_valid(_floor_node):
		_floor_node.queue_free()
	if _air_node != null and is_instance_valid(_air_node):
		_air_node.queue_free()
