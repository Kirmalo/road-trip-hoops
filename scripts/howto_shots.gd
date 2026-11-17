extends Node
# How to Play capture driver (P7-H1, test only). main.gd adds it to the game under
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 \
#       -- --howto-shots DIR --court gym --difficulty hard --quick-teams cornfield_kings,bridge_runners
# (the last three pin what a saved setting could change, so the pictures don't depend on this machine's settings).
# The game is a --humantest game (the scripted thumb drives the real joystick and buttons: drives, flicks, turbo
# pulls, shots, pump fakes, CALL, lobs, steals, blocks) with fixed seeds (main.gd seeds with HOWTO_SEED), so a rerun
# gives the same pictures. This node only watches: it polls the game state each physics frame and saves the viewport
# to DIR/howto_<id>.png (1280x720) at the moments in docs/BOARD.md "How to Play pages", plus the insets
# DIR/howto_dunks_b.png (an alley-oop lob in the air) and DIR/howto_defense_b.png (BLOCK at a shooter). It never
# changes the sim.
# Each picture is saved at the first moment close to it (loose), and saved again over it at a better one: the named
# moment, then the named moment in clear view (clean). The run ends when every picture is clean, at the game's end, or
# after TIME_LIMIT seconds of game time, and prints "HOWTO SHOTS <n>/9" with the missing ids and how good each is.
# The `trip` page (the trip map, with the lineup or points screen as an inset) is NOT captured here: it comes from
#   xvfb-run ... -- --trip-test --target 3 --screens   (/tmp/hoops_screen_NN_map.png, ..._lineup.png, ..._points.png)
# so this run reports it as missing, with that note.
# Headless (no window) it still runs the watch and prints what it would capture, so the logic can be checked fast.

const FLAG := "--howto-shots"            # --howto-shots DIR or --howto-shots=DIR
const DEFAULT_DIR := "/tmp/howto"         # when the flag has no DIR after it
const PAGES := ["controls", "turbo", "shoot", "dunks", "moves", "call", "defense", "fire", "trip"]
const INSETS := ["dunks_b", "defense_b"]  # optional second pictures (the trip inset comes with the trip screens)
const NOT_HERE := {"trip": "from --trip-test --screens"}   # pages this driver doesn't capture
const TIME_LIMIT := 1200.0               # seconds of game time before it gives up on the missing pictures
const SETTLE_TIME := 2.5                 # seconds after tip-off before any capture (the start message fades)
const SAVE_DELAY := 1                    # physics frames between the moment and the save (the moment is drawn by then)
const MOVES_DELAY := 9                   # a beaten crossover: frames later, so the stumble and SHOOK! show
const CONTROLS_HOLD := 0.6               # controls: seconds the human has held the ball with the stick steering
const TURBO_STAMINA_HI := 0.75           # turbo: the stamina bar visibly drained, ...
const TURBO_STAMINA_LO := 0.3            # ... but not yet empty (red)
const TURBO_MIN_SPEED := 0.6             # turbo: moving at least this fraction of top speed
const SHOOT_LOOSE_CHARGE := 0.3          # shoot (loose): the meter at least this full
const DUNK_PEAK_FRAC := 0.35             # dunks: this far into the jump (rising to the rim)
const LOB_T_LO := 0.35                   # dunks_b: the lob this far along its flight ...
const LOB_T_HI := 0.65                   # ... and not further
const CALL_LIT_AFTER := 0.08             # call: seconds into the live call (as main.gd's --shots call_cue)
const SHOOT_MIN_FT := 10.0               # shoot (clean): a jumper from at least this far out
const SHOOT_ROOM_PX := 40.0              # shoot (clean): screen room around the shooter (see _room_px)
const CLEAR_PX := 110.0                  # clean (turbo, fire): screen room around the subject (see _room_px)
const ROOM_Y_WEIGHT := 2.0               # _room_px: a player above or below on screen overlaps the tall sprites sooner
const FIRE_RECT := Rect2(200, 320, 880, 260)    # fire (clean): the hot hand near the middle of the picture
const FIRE_RIM_FT := 10.0                # fire (clean): the hot hand dribbling at least this far from both rims
const PICTURE_SIZE := Vector2(1280, 720)  # the capture size (project.godot's window)
const FRAME_RECT := Rect2(100, 240, 1080, 370)   # clean: the subject's feet inside this part of the 1280x720 picture
const LOOSE := 1                         # picture quality: close to the moment
const NAMED := 2                         # exactly the moment the page names
const CLEAN := 3                         # the named moment with nothing in the way (the run stops when all are clean)
const QUALITY_NAMES := ["none", "loose", "named", "clean"]

var main                                  # main.gd (set by main.gd before add_child)
var dir := DEFAULT_DIR
var _frame := 0
var _time := 0.0
var _quality := {}                       # id -> LOOSE, NAMED or CLEAN of the saved picture
var _pending: Array = []                 # [id, quality, save at frame]
var _hold_t := 0.0                       # controls: seconds the human has had the ball in a calm stretch
var _cross_beats := 0                    # main.stats["human_cross_beats"] last frame
var _done := false
var _headless := false

func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	dir = flag_dir()
	# the effects' own rngs (screen shake, popups: drawing only) start from the seed too, so reruns match
	for n in [main.fx, main.twist_fx]:
		if n != null and "_rng" in n and n.get("_rng") is RandomNumberGenerator:
			(n.get("_rng") as RandomNumberGenerator).seed = main.HOWTO_SEED
	if not _headless:
		DirAccess.make_dir_recursive_absolute(dir)
	print("HOWTO SHOTS to %s%s" % [dir, " (headless: nothing is saved)" if _headless else ""])

# the folder after --howto-shots (DEFAULT_DIR when none is given)
static func flag_dir() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		if args[i].begins_with(FLAG + "="):
			return args[i].substr(FLAG.length() + 1)
		if args[i] == FLAG and i + 1 < args.size() and not args[i + 1].begins_with("--"):
			return args[i + 1]
	return DEFAULT_DIR

func _physics_process(delta: float) -> void:
	if _done or main == null:
		return
	_frame += 1
	_time += delta
	_save_pending()
	if main.game_over:
		_finish("game over")
		return
	if _time >= TIME_LIMIT:
		_finish("time limit")
		return
	if _time >= SETTLE_TIME and not main.menu_wait and main.human_player != null:
		_watch(delta)
	if _all_clean() and _pending.is_empty():
		_finish("all pictures")

func _exit_tree() -> void:
	_finish("quit")   # the game ended the run first (humantest quits at FINAL)

# ---------------- the moments ----------------
# Quality of a picture: LOOSE (close to the moment), NAMED (exactly the moment the page names), CLEAN (the named moment
# with nothing in the way: no centre message, the subject well inside the picture, room around him where it matters).

func _watch(delta: float) -> void:
	var g = main
	var c = g.controls
	var h = g.human_player
	var ball = g.ball
	var ft: bool = g.rules.ft_active
	var joy: bool = c.joy_index >= 0
	var quiet: bool = g.msg_timer <= 0.0   # no centre message (BLOCKED!, SHOT CLOCK!, ...) over the court

	# 1 controls: joystick out, the human dribbling (A = SHOOT, B = PASS), a calm moment
	var calm: bool = joy and not ft and h.has_ball() and not h.shooting and not h.is_airborne() and not h.turbo \
			and h.cross_t <= 0.0 and g.ht_mode == "" and quiet and c.a_text == "SHOOT"
	_hold_t = _hold_t + delta if calm else 0.0
	if _hold_t >= CONTROLS_HOLD:
		_want("controls", CLEAN if _in_frame(h) else NAMED)
	elif joy and h.has_ball() and not ft:
		_want("controls", LOOSE)

	# 2 turbo: thumb past the ring, sprinting, the stamina bar going down
	if joy and c.turbo_pull() and h.turbo and not ft:
		var fast: bool = h.velocity.length() >= TURBO_MIN_SPEED * h.speed
		var draining: bool = h.stamina < TURBO_STAMINA_HI and h.stamina > TURBO_STAMINA_LO
		if fast and draining:
			_want("turbo", CLEAN if quiet and _in_frame(h) and _room_px(h) >= CLEAR_PX else NAMED)
		else:
			_want("turbo", LOOSE)

	# 3 shoot: the human's jump-shot meter in the green (not a pump fake, not a free throw); clean: a real jumper
	if h.shooting and h.rim_kind == "" and h.fake_t <= 0.0 and h.has_ball():
		var in_green: bool = h.shot_charge >= h.green_lo() and h.shot_charge <= h.green_hi()
		if in_green and not ft:
			var jumper: bool = h.position.distance_to(g.attack_hoop(h.team)) >= SHOOT_MIN_FT * g.FT
			_want("shoot", CLEAN if jumper and quiet and _in_frame(h) and _room_px(h) >= SHOOT_ROOM_PX else NAMED)
		elif h.shot_charge >= SHOOT_LOOSE_CHARGE:
			_want("shoot", LOOSE)

	# 4 dunks: a dunk rising to the rim (the human's; any player's is loose), and an alley-oop lob in the air (dunks_b)
	for p in g.players:
		if p.rim_kind == "dunk" and p.jump_time > 0.0 and p.jump_t >= DUNK_PEAK_FRAC * p.jump_time:
			if p == h:
				_want("dunks", CLEAN if quiet and (p.v_turbo_dunk or p.alley_oop) else NAMED)
			else:
				_want("dunks", LOOSE)
	if ball.state == ball.PASS and ball.lob and ball.lob_t >= LOB_T_LO and ball.lob_t <= LOB_T_HI:
		var ours: bool = ball.passer != null and ball.passer.team == g.HUMAN_TEAM
		var rcv_in: bool = ball.receiver != null and _in_frame(ball.receiver)
		_want("dunks_b", (CLEAN if quiet and rcv_in else NAMED) if ours else LOOSE)

	# 5 moves: the human's crossover beats his man (SHOOK!, he stumbles); any human crossover is loose
	var beats: int = int(g.stats.get("human_cross_beats", 0))
	if beats > _cross_beats:
		_want("moves", CLEAN if quiet and _in_frame(h) else NAMED, MOVES_DELAY)
	elif h.has_ball() and h.cross_t > 0.0 and h.move_kind == "cross":
		_want("moves", LOOSE)
	_cross_beats = beats

	# 6 call: the CALL bubble, B lit as CALL
	if c.b_glow and g.input.call_t > CALL_LIT_AFTER:
		_want("call", CLEAN if quiet and _in_frame(h) else NAMED)

	# 7 defense: STEAL glowing next to the handler; BLOCK at a shooter (defense_b)
	if c.a_glow:
		_want("defense", CLEAN if quiet and _in_frame(h) else NAMED)
	if c.a_block:
		var th = g.input.block_threat()
		if th != null and (th.shooting or th.rim_kind != ""):
			_want("defense_b", CLEAN if quiet and _in_frame(th) else NAMED)
		else:
			_want("defense_b", LOOSE)

	# 8 fire: a player on fire with the flaming ball (any player: the page shows the effect; clean: in clear view)
	var fp = ball.holder if ball.state == ball.HELD else (ball.shooter if ball.state == ball.SHOT else null)
	if fp != null and fp.on_fire and g._trail_on:
		var off_rim: bool = fp.position.distance_to(g.hoops[0]) >= FIRE_RIM_FT * g.FT \
				and fp.position.distance_to(g.hoops[1]) >= FIRE_RIM_FT * g.FT
		var clear: bool = quiet and not ft and ball.state == ball.HELD and off_rim and not fp.is_airborne() \
				and _in_frame(fp, FIRE_RECT) and _room_px(fp) >= CLEAR_PX
		_want("fire", CLEAN if clear else NAMED)

# the player's feet on screen (where player.gd draws him: his body node sits at the projected floor point), measured in
# the centred PICTURE_SIZE part of the viewport. A viewport bigger than that (headless: 1280x1280 with the "expand"
# stretch) shows more around the same centre, so headless runs predict the xvfb pictures.
func _feet(p) -> Vector2:
	var body = p.get("_v_body")
	if not (body is Node2D):
		return Vector2(-9999, -9999)
	var feet: Vector2 = (body as Node2D).get_global_transform_with_canvas().origin
	return feet - (get_viewport().get_visible_rect().size - PICTURE_SIZE) / 2.0

# the player's feet inside `rect` of the picture (FRAME_RECT: clear of the top bar, the edges and the buttons)
func _in_frame(p, rect := FRAME_RECT) -> bool:
	return rect.has_point(_feet(p))

# screen pixels from this player's feet to the nearest other player's, the vertical part weighted by ROOM_Y_WEIGHT
func _room_px(p) -> float:
	var me: Vector2 = _feet(p)
	var best := INF
	for o in main.players:
		if o != p:
			var d: Vector2 = _feet(o) - me
			best = minf(best, Vector2(d.x, d.y * ROOM_Y_WEIGHT).length())
	return best

# a picture of `id` at this quality, unless one as good is saved or on its way
func _want(id: String, quality: int, delay := SAVE_DELAY) -> void:
	if int(_quality.get(id, 0)) >= quality:
		return
	for q in _pending:
		if str(q[0]) == id and int(q[1]) >= quality:
			return
	_pending.append([id, quality, _frame + delay])

func _save_pending() -> void:
	var keep: Array = []
	for q in _pending:
		if int(q[2]) > _frame:
			keep.append(q)
			continue
		var id: String = str(q[0])
		var quality: int = int(q[1])
		if int(_quality.get(id, 0)) >= quality:
			continue
		_quality[id] = quality
		var path: String = dir.path_join("howto_%s.png" % id)
		if _headless:
			print("HOWTO SHOT %s (%s) t=%.1f [headless, not saved]" % [id, QUALITY_NAMES[quality], _time])
			continue
		var img: Image = get_viewport().get_texture().get_image()
		var err: int = img.save_png(path) if img != null else FAILED
		print("HOWTO SHOT %s (%s) t=%.1f -> %s%s" % [id, QUALITY_NAMES[quality], _time, path, "" if err == OK else " FAILED"])
	_pending = keep

func _all_clean() -> bool:
	for id in PAGES + INSETS:
		if not NOT_HERE.has(id) and int(_quality.get(id, 0)) < CLEAN:
			return false
	return true

func _finish(why: String) -> void:
	if _done:
		return
	_done = true
	var have := 0
	var missing: Array = []
	var got: Array = []
	for id in PAGES:
		if _quality.has(id):
			have += 1
		elif NOT_HERE.has(id):
			missing.append("%s (%s)" % [id, NOT_HERE[id]])
		else:
			missing.append(id)
	for id in PAGES + INSETS:
		if _quality.has(id):
			got.append("%s %s" % [id, QUALITY_NAMES[int(_quality[id])]])
	print("HOWTO SHOTS %d/%d (%s, %.0f s of play)%s | %s" % [have, PAGES.size(), why, _time,
			" | missing: " + ", ".join(PackedStringArray(missing)) if not missing.is_empty() else "",
			", ".join(PackedStringArray(got))])
	if why != "quit" and is_inside_tree():
		get_tree().quit()
