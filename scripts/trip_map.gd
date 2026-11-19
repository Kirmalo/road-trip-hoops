extends CanvasLayer
# Trip map (P5-09, owner Q7 a: fixed route, tap GO; P8-20: replays from the pins). Flow screen "map", built in
# code with ui_kit.gd.
#   - the approved pixel USA map (assets/map/usa.png, 640 x 360 drawn 2x, centred; the bars above and below in
#     map.json bar_bg), the 8 city pins: beaten = trophy (pin_done), the city you play next = gold (pin_current, it
#     bobs), a built city still ahead = blue (pin), not built yet = grey (pin_locked) with "(soon)"
#   - the van "The Biscuit" parked on the road at your city; after a city is beaten it drives the road to the next
#     one in DRIVE_TIME s (a tap anywhere skips the drive)
#   - header: ROAD TRIP, your crew, the next city, the record; MENU (back to the title) top-right
#   - city card bottom-left: name, state, game n of 3, target, the crew you face, record and level. Tap a pin to see
#     that city on the card (a grey one says "coming soon"); tap the map to go back to your city
#   - P6-16: the card's last line is the city's twist ("WIND: long shots and lobs drift"), none for Hometown
#   - GO bottom-right: the city's arrival story the first time, then the lineup (New York: the bracket). When the trip
#     is between steps (points / recruit / bracket after a CONTINUE) GO goes to that screen.
#   - P8-20: every built pin shows its best stars ("7/9", Stars.city_total(); New York's 3 rounds out of 9). Tapping a
#     pin with games won on this trip (Trip.can_replay) opens the replay picker: its 3 games (New York: the rounds)
#     with their best stars and PLAY (Trip.start_replay(), then the lineup). Replays pay stars only, the opponents
#     play at the trip's current stage. CLOSE, a tap outside the panel, Escape or the Android back close it.
#   - P8-20: the van is the picked van paint (Cosmetics.van_path(), the same sheet layout as van.png)
#   - P8-20: a finished trip opens in replay mode: no GO, the picker works, TITLE bottom-right (where GO stands)
#   - P9 (owner bug: no level choice on replays): the picker's level row, EASY / NORMAL / HARD and LEGEND once open
#     (Difficulty.offered_levels(); LEGEND purple, the picked one gold), opens on the trip's level; the hint under it
#     says what a win there earns ("A WIN ON HARD: 3 STARS"); PLAY = Trip.start_replay(city, n, level). The trip's own
#     level (Settings) never changes.
#   - P8-20: opening the map drops a replay marker left over (BACK out of a replay's lineup: Trip.cancel_replay())
# Works without the art: a missing usa.png / pin / van / map.json is drawn with plain shapes (FALLBACK_CITIES).
# Desktop testing: Enter / Space = GO, Escape = MENU (or closes the picker). Trip test: auto_step() skips the drive,
# then taps GO (a finished trip: the title); it never starts a replay.
# Test: -- --trip-test --trip-resume --mapshot DIR [--map-pick city]: on the first map, saves DIR/hoops_map*.png (the
# map, the open picker, P9: the picker with another level picked), starts a replay at that level and comes back to the
# map (the marker must be gone), then PLAYs it for real at another level than the trip's (the trip test plays the
# replay game and checks its stars at that level); prints MAPSHOT lines. Screenshots need xvfb.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Cities = preload("res://scripts/cities.gd")
const MenuScript = preload("res://scripts/menu.gd")   # twist_line(): the twist's one line (P6-16)
const Stars = preload("res://scripts/stars.gd")       # best(), city_total(), key() (P8-20)
const Cosmetics = preload("res://scripts/cosmetics.gd")   # van_path(): the picked van paint (P8-20)

const MAP_DIR := "res://assets/map/"
const MAP_JSON := MAP_DIR + "map.json"
const BASE := Vector2(1280, 720)               # the map's drawn size (640 x 360 source at 2x)
const SRC_SCALE := 2.0                         # source px -> screen px
const HEADER_SRC_H := 36.0                     # source rows kept clear for the header (map.json header_h)
const BAR_BG := Color("#12101e")               # bars around the map and the header (map.json bar_bg)
const HEADER_ALPHA := 1.0                     # opaque: no seam with the top bar on taller screens
const GOLD_LINE := Color("#f2b62c")            # the header's bottom edge, the card border
const GOLD_TEXT := Color("#ffe68a")
const LINE_W := 3.0

# the van
const DRIVE_TIME := 3.0                        # s for the drive to the next city (owner: about 3 s)
const PARK_BACK := 18.0                        # source px the parked van stands back from the pin, on the road
const START_PARK := Vector2(0, 24)             # source px below the first city's pin, where the van starts
const VAN_FPS := 8.0                           # drive frames per second
const VAN_BOB := 1.0                           # source px the van bounces while driving
const VAN_FALLBACK_SIZE := Vector2(48, 32)     # source px of the drawn box van (no van.png)
const VAN_FALLBACK_ANCHOR := Vector2(24, 29)
const VAN_COLOR := Color(0.88, 0.72, 0.46)     # biscuit (title.gd)
const VAN_TRIM := Color(0.16, 0.30, 0.60)
const HORN_SOUND := "horn"                     # P5-A4 sound, if it exists (audio.play ignores a missing name)
const TAP_SOUND := "bounce"

# pins
const PIN_SIZE := Vector2(16, 20)              # source px (map.json pin_size)
const PIN_ANCHOR := Vector2(8, 18)             # the tip (map.json pin_anchor)
const PIN_BOB := 2.0                           # source px the current pin bobs
const PIN_BOB_HZ := 1.6
const PIN_TAP_R := 56.0                        # screen px: a tap this close to a pin picks it (thumb sized)
const PIN_COLORS := {"done": Color(1.0, 0.82, 0.25), "current": Color(1.0, 0.6, 0.15),
		"open": Color(0.3, 0.55, 1.0), "locked": Color(0.55, 0.55, 0.62)}   # drawn pins (no pin art)

# labels on the map
const CITY_FONT := 20
const CITY_OUTLINE := 6
const CITY_COLOR := Color.WHITE
const LOCKED_COLOR := Color("#9a9ab0")
const OUTLINE_COLOR := Color(0.08, 0.06, 0.12)
const LABEL_DX := 20.0                         # screen px from the pin to a side label
const LABEL_DY := -18.0
const SOON := "  (soon)"

# header, card, buttons (screen px at the 1280 x 720 base)
const HEADER_FONT := 34                        # "ROAD TRIP"
const INFO_FONT := 22                          # the header's middle line
const CARD_POS := Vector2(24, 24)              # from the bottom-left corner (x right, y up)
const CARD_SIZE := Vector2(660, 150)           # grows upward when the lines need more room (the twist line)
const CARD_TITLE_FONT := 30
const CARD_FONT := 22
const TWIST_COLOR := Color(0.55, 0.85, 1.0)    # the twist line on the card (P6-16)
const GO_SIZE := Vector2(280, 130)
const GO_MARGIN := Vector2(24, 20)             # from the bottom-right corner
const MENU_SIZE := Vector2(200, 110)
const MENU_MARGIN := Vector2(16, 8)            # from the top-right corner
const PANEL_ARM := 0.3                         # s the screen ignores taps (a double tap from the last screen)

# P8-20: the stars under every pin
const PIN_STARS_FONT := 18                     # "7/9" under the city name
const PIN_STARS_DY := 20.0                     # screen px from the name's baseline down to the stars line
const PIN_STAR_R := 7.0                        # screen px: the little star in front of "7/9"
const PIN_STARS_ABOVE := ["new_york"]         # these show their stars above the name (under it New York's line runs
                                               # into Hometown's name, and the van parks under its pin at the end)
const STAR_GOLD := Color("#ffd23f")
const STAR_EMPTY := Color(0.42, 0.42, 0.5)     # no stars yet (and the empty stars in the picker)
const STAR_EDGE := Color(0.08, 0.06, 0.12)

# P8-20: the replay picker
const PICK_SIZE := Vector2(1040, 0)            # width; the height fits the rows
const PICK_TITLE_FONT := 34
const PICK_INFO_FONT := 22
const PICK_ROW_FONT := 26
const PICK_ROW_W := 560.0                      # the game's text column
const PICK_STARS := Vector2(150, 44)           # the 3 stars of a row
const PICK_STAR_R := 19.0
const PICK_PLAY := Vector2(220, 110)           # PLAY (the board minimum height)
const PICK_CLOSE := Vector2(200, 110)
const PICK_GAP := 10
const PICK_LEVEL := Vector2(170, 110)          # P9: a level button in the picker (touch height)
const PICK_LEVEL_FONT := 28
const PICK_LEVEL_GAP := 10
const PICK_HINT_FONT := 26                     # P9: "A WIN ON HARD: 3 STARS" under the level row
const PICK_HINT := "A WIN ON %s: %d STAR%s"
const PICK_HINT_BEST := "  (no new stars: your best is kept)"   # when every game here already has that many
const LEVEL_NAMES := {"easy": "EASY", "normal": "NORMAL", "hard": "HARD", "legend": "LEGEND"}
const CLOSED_LEGEND := "hard"                  # the picker's start when the trip is on LEGEND but LEGEND is closed
const PICK_INFO := "Replays pay stars only: no stat points, your record stays. The opponents play at your trip's" \
		+ " current strength."
const PICK_INFO_DONE := "Trip complete! Replays pay stars only, against opponents at full strength."
const PICK_NOT_WON := "not won yet"
const STARS_PER_GAME := 3
const MAPSHOT_FLAG := "--mapshot"              # test: screenshots of the map and the picker, a replay (see the top)
const MAPSHOT_PICK_FLAG := "--map-pick"        # test: the city whose picker --mapshot opens (default: the last won)
const MAPSHOT_WAIT := 0.8                      # s before each --mapshot step (drawing settled)

# map.json cities, used when the file is missing (source px)
const FALLBACK_CITIES := {
	"hometown": [408.5, 157.1], "chicago": [391.2, 140.2], "memphis": [376.9, 217.9],
	"new_orleans": [380.4, 277.5], "denver": [251.3, 164.6], "seattle": [132.9, 62.4],
	"los_angeles": [129.8, 219.9], "new_york": [501.8, 143.7],
}

var main
var audio
var music := "menu"

static var _van_at := ""                       # the city the van was last shown at (survives the scene reloads)

var _data := {}                                # map.json
var _tex := {}                                 # name -> Texture2D (missing = not in the dict)
var _root: Control
var _art: MapArt
var _skip: Control                             # catches the tap that skips the drive
var _go_btn: Button
var _menu_btn: Button
var _info: Label
var _head: Label
var _card_title: Label
var _card_lines: Label
var _card_twist: Label
var _shown := ""                               # the city on the card
var _picker: Control                           # the open replay picker (null = closed)
var _picker_city := ""
var _play_btns := {}                           # game n -> its PLAY button in the open picker
var _level_btns := {}                          # P9: level name -> its button in the open picker
var _pick_level := ""                          # P9: the level the open picker's PLAY starts the replay at
var _hint: Label                               # P9: the picker's "A WIN ON ..." line
var _arm_t := PANEL_ARM
var _busy := false
var _t := 0.0
# the drive: screen-independent source-px polyline, its cumulative lengths, progress 0..1
var _path: Array = []
var _lens: Array = []
var _drive_t := -1.0                           # s into the drive; < 0 = parked
var _park := Vector2.ZERO
var _park_dir := 1.0                           # +1 faces right, -1 left

static var _shot_stage := -1                   # --mapshot: -1 off, 0 first map, 1 back after a cancel, 2 played, 3 done
var _shot_t := 0.0
var _shot_step := 0

func _ready() -> void:
	if not Trip.active:
		Trip.continue_trip()   # e.g. a reload straight onto the map: the save is the truth
	var dropped: bool = Trip.replaying() and Trip.cancel_replay()   # BACK out of a replay's lineup: GO plays the trip
	if dropped:
		print("MAP replay marker dropped")
	_load_art()
	_root = UI.screen_root(self)
	(_root.get_child(0) as ColorRect).color = BAR_BG
	_art = MapArt.new()
	_art.screen = self
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_STOP
	_art.gui_input.connect(_on_map_input)
	_root.add_child(_art)
	_build_header()
	_build_card()
	_go_btn = UI.button(_root, "GO", _tap.bind(_on_go), UI.KIND_LIT, GO_SIZE)
	_go_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_go_btn.offset_left = -GO_MARGIN.x - GO_SIZE.x
	_go_btn.offset_right = -GO_MARGIN.x
	_go_btn.offset_top = -GO_MARGIN.y - GO_SIZE.y
	_go_btn.offset_bottom = -GO_MARGIN.y
	_skip = Control.new()
	_skip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skip.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip.gui_input.connect(_on_skip_input)
	_skip.visible = false
	_root.add_child(_skip)
	_setup_van()
	_show_city(Trip.city)
	_refresh_buttons()
	_stat("map_screen")
	_mapshot_ready(dropped)

func _process(delta: float) -> void:
	_t += delta
	if _shot_stage >= 0 and _shot_stage < 3:
		_mapshot_tick(delta)
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_refresh_buttons()
	if _drive_t >= 0.0:
		_drive_t += delta
		if _drive_t >= DRIVE_TIME:
			_end_drive()
	_art.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_ESCAPE:
		if _picker != null:
			close_picker()   # the Android back closes the picker too (main.gd sends it as Escape)
		else:
			_tap(_on_menu)
	elif k.keycode == KEY_ENTER or k.keycode == KEY_SPACE:
		if _picker != null:
			return
		if _drive_t >= 0.0:
			_end_drive()
		else:
			_tap(_on_go)

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

# ---------------- art and data ----------------

func _load_art() -> void:
	if ResourceLoader.exists(MAP_JSON):
		var j = load(MAP_JSON)
		if j is JSON and j.data is Dictionary:
			_data = j.data
	var names := {"usa": "usa.png", "van": "van.png", "open": "pin.png", "current": "pin_current.png",
			"done": "pin_done.png", "locked": "pin_locked.png"}
	var pins = _data.get("pins", {})
	if pins is Dictionary:
		for k in pins:
			names[str(k)] = str(pins[k])
	for k in names:
		var p: String = MAP_DIR + str(names[k])
		if ResourceLoader.exists(p):
			var t = load(p)
			if t is Texture2D:
				_tex[k] = t
	# the picked van paint (same sheet layout as van.png); the default van when it is missing
	var vp: String = Cosmetics.van_path()
	if vp != "" and ResourceLoader.exists(vp):
		var vt = load(vp)
		if vt is Texture2D:
			_tex["van"] = vt

# a city's pin tip in source px
func city_src(id: String) -> Vector2:
	var cs = _data.get("cities", {})
	var v = cs.get(id, null) if cs is Dictionary else null
	if not (v is Array) or (v as Array).size() < 2:
		v = FALLBACK_CITIES.get(id, [320.0, 180.0])
	return Vector2(float(v[0]), float(v[1]))

# the road a>b in source px (straight when map.json has none)
func road(a: String, b: String) -> Array:
	var rs = _data.get("roads", {})
	var r = rs.get(a + ">" + b, null) if rs is Dictionary else null
	var out: Array = []
	if r is Array and (r as Array).size() >= 2:
		for p in r:
			out.append(Vector2(float(p[0]), float(p[1])))
		return out
	return [city_src(a), city_src(b)]

func label_side(id: String) -> String:
	var ls = _data.get("label", {})
	return str(ls.get(id, "right")) if ls is Dictionary else "right"

# where the 1280 x 720 map sits on the screen (centred; bars around it)
func map_origin() -> Vector2:
	var vs: Vector2 = _root.size if _root != null else BASE
	return ((vs - BASE) / 2.0).floor()

func to_screen(src: Vector2) -> Vector2:
	return map_origin() + src * SRC_SCALE

func header_h() -> float:
	return map_origin().y + HEADER_SRC_H * SRC_SCALE

# "done", "current", "open" or "locked"
func pin_state(id: String) -> String:
	if Trip.beaten.has(id):
		return "done"
	if not Cities.is_built(id):
		return "locked"
	if id == Trip.city:
		return "current"
	return "open"

# ---------------- the van ----------------

func _setup_van() -> void:
	var to: String = Trip.city
	var from: String = _van_at
	_van_at = to
	var ri: int = Cities.ROUTE.find(to)
	var fi: int = Cities.ROUTE.find(from)
	if to == "" or ri < 0:
		to = Trip.beaten.back() if Trip.beaten.size() > 0 else Cities.ROUTE[0]
		ri = Cities.ROUTE.find(to)
	# the road into the city (or out of it for the first city): the van parks PARK_BACK px before the pin
	var inbound: Array = road(Cities.ROUTE[ri - 1], to) if ri > 0 else []
	if inbound.is_empty():
		_park = city_src(to) + START_PARK   # the first city: parked under its pin, facing the road ahead
		_park_dir = 1.0
	else:
		_set_park(inbound, _poly_len(inbound) - PARK_BACK)
	if fi >= 0 and fi < ri and Trip.phase == "map":
		# drive the route from the last city to this one (through the "coming soon" pins on the way)
		_path = []
		for i in range(fi, ri):
			var seg: Array = road(Cities.ROUTE[i], Cities.ROUTE[i + 1])
			if not _path.is_empty():
				seg = seg.slice(1)
			_path.append_array(seg)
		if fi == 0:
			_path.push_front(city_src(from) + START_PARK)   # from where the van stood under the first pin
		_lens = [0.0]
		for i in range(1, _path.size()):
			_lens.append(float(_lens[i - 1]) + (_path[i] as Vector2).distance_to(_path[i - 1]))
		_drive_t = 0.0
		_skip.visible = true
		_stat("map_drive")

func _set_park(poly: Array, at: float) -> void:
	if poly.size() < 2:
		_park = city_src(Trip.city)
		return
	var r: Array = _along(poly, maxf(at, 0.0))
	_park = r[0]
	_park_dir = 1.0 if float(r[1]) >= 0.0 else -1.0

static func _poly_len(poly: Array) -> float:
	var n := 0.0
	for i in range(1, poly.size()):
		n += (poly[i] as Vector2).distance_to(poly[i - 1])
	return n

# [point, dx sign] at distance d along a polyline
static func _along(poly: Array, d: float) -> Array:
	var left: float = d
	for i in range(1, poly.size()):
		var a: Vector2 = poly[i - 1]
		var b: Vector2 = poly[i]
		var seg: float = a.distance_to(b)
		if left <= seg or i == poly.size() - 1:
			var f: float = clampf(left / maxf(seg, 0.001), 0.0, 1.0)
			return [a.lerp(b, f), b.x - a.x]
		left -= seg
	return [poly[0], 1.0]

# the van now: [source point, facing (+1 right / -1 left), driving]
func van_now() -> Array:
	if _drive_t < 0.0 or _path.size() < 2:
		return [_park, _park_dir, false]
	var total: float = float(_lens[_lens.size() - 1])
	var f: float = clampf(_drive_t / DRIVE_TIME, 0.0, 1.0)
	var e: float = f * f * (3.0 - 2.0 * f)   # ease in and out
	var end_d: float = maxf(total - PARK_BACK, 0.0)
	var r: Array = _along(_path, e * end_d)
	var dir: float = 1.0 if float(r[1]) >= 0.0 else -1.0
	if absf(float(r[1])) < 0.5:
		dir = _park_dir   # vertical stretch: keep facing where it was
	_park_dir = dir
	return [r[0], dir, true]

func _end_drive() -> void:
	if _drive_t < 0.0:
		return
	_drive_t = -1.0
	_skip.visible = false
	# park where the drive ended (the same spot _setup_van chose, facing the way it came)
	if _path.size() >= 2:
		var r: Array = _along(_path, maxf(float(_lens[_lens.size() - 1]) - PARK_BACK, 0.0))
		_park = r[0]
		if absf(float(r[1])) >= 0.5:
			_park_dir = 1.0 if float(r[1]) >= 0.0 else -1.0
	if audio != null:
		audio.play(HORN_SOUND)
	_refresh_buttons()

func _on_skip_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	var st := event as InputEventScreenTouch
	if (mb != null and mb.pressed) or (st != null and st.pressed):
		_skip.accept_event()
		_end_drive()
		_arm_t = PANEL_ARM   # the same finger lifting must not tap GO
		_refresh_buttons()
		_stat("map_drive_skipped")

# ---------------- header, card, buttons ----------------

func _build_header() -> void:
	var t := UI.label(_root, "ROAD TRIP", HEADER_FONT, GOLD_TEXT)
	_head = t
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	t.position = Vector2(24, 0)
	t.size = Vector2(300, HEADER_SRC_H * SRC_SCALE)
	_info = UI.label(_root, "", INFO_FONT)
	_info.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_info.offset_top = 0
	_info.offset_bottom = HEADER_SRC_H * SRC_SCALE
	_info.text = _header_text()
	_menu_btn = UI.button(_root, "MENU", _tap.bind(_on_menu), UI.KIND_OPT, MENU_SIZE)
	_menu_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_menu_btn.offset_left = -MENU_MARGIN.x - MENU_SIZE.x
	_menu_btn.offset_right = -MENU_MARGIN.x
	_menu_btn.offset_top = MENU_MARGIN.y
	_menu_btn.offset_bottom = MENU_MARGIN.y + MENU_SIZE.y
	_root.resized.connect(_on_resized)
	_on_resized()

func _on_resized() -> void:
	# the header labels sit in the header band, which grows with the top bar on taller screens
	var hh: float = header_h()
	_info.offset_bottom = hh
	_head.size = Vector2(300, hh)

func _header_text() -> String:
	var rec: String = "RECORD %d-%d" % [int(Trip.record.get("wins", 0)), int(Trip.record.get("losses", 0))]
	if Trip.is_done():
		return "%s  -  TRIP COMPLETE  -  %s" % [Cities.CREW_NAME, rec]
	var c: Dictionary = Cities.city(Trip.city)
	return "%s  -  NEXT: %s  -  %s" % [Cities.CREW_NAME, str(c.get("name", "?")), rec]

func _build_card() -> void:
	var p := UI.panel(_root, CARD_SIZE)
	var sb := p.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	sb.bg_color = Color(BAR_BG, 0.88)
	sb.border_color = GOLD_LINE
	sb.set_border_width_all(2)
	sb.set_content_margin_all(16)
	p.add_theme_stylebox_override("panel", sb)
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	p.offset_left = CARD_POS.x
	p.offset_right = CARD_POS.x + CARD_SIZE.x
	p.offset_top = -CARD_POS.y - CARD_SIZE.y
	p.offset_bottom = -CARD_POS.y
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN   # a taller card grows up, never off the bottom edge
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	_card_title = UI.label(box, "", CARD_TITLE_FONT, GOLD_TEXT)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_card_lines = UI.label(box, "", CARD_FONT)
	_card_lines.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_card_lines.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_card_twist = UI.label(box, "", CARD_FONT, TWIST_COLOR)
	_card_twist.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_card_twist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_twist.custom_minimum_size = Vector2(CARD_SIZE.x - 32.0, 0)   # inside the 16 px margins
	_card_twist.visible = false

# the card for a city: yours (game, target, crew), a beaten one, one ahead, or a "coming soon" one
func _show_city(id: String) -> void:
	_shown = id
	var c: Dictionary = Cities.city(id)
	_show_twist(id)
	if c.is_empty():
		_card_title.text = "NO TRIP"
		_card_lines.text = "Start a Road Trip from the title screen."
		return
	_card_title.text = "%s, %s" % [str(c.get("name", id)), str(c.get("state", ""))]
	var lines: Array = []
	var st: String = pin_state(id)
	if Trip.is_done():
		lines.append("Trip complete! Every trophy is in the van.")
		lines.append("Tap a city to replay its games for stars.")
	elif st == "locked":
		lines.append("Coming soon: this city opens in a later update.")
		lines.append("The Biscuit drives on by for now.")
	elif st == "done" and id == Trip.city:
		lines.append("Beaten! " + ("Spend your stat points." if Trip.phase == "points" else
				"Pick a new player for the bench." if Trip.phase == "recruit" else "On to the next city."))
	elif st == "done":
		lines.append("Beaten! The trophy rides in the van." + (" Tap the pin to replay." if replayable(id) else ""))
	elif Trip.is_tournament(id):
		var rn: Array = Trip.round_names()
		var r: int = clampi(Trip.bracket_round(), 0, maxi(rn.size() - 1, 0))
		var rname: String = str(rn[r]) if rn.size() > 0 else "ROUND %d" % (r + 1)
		lines.append("%s  -  %s" % [str(c.get("tournament_name", "TOURNAMENT")), rname if id == Trip.city else
				"3 rounds"])
		lines.append("Every game to %d  -  %s" % [Cities.game_target(id, 1), _crew_line(id)])
	else:
		var n: int = Trip.game if id == Trip.city else 1
		lines.append("Game %d of %d  -  to %d  -  vs %s" % [n, Trip.GAMES_PER_CITY, Cities.game_target(id, n),
				str(c.get("crew", {}).get("name", "?"))])
		if id != Trip.city:
			lines.append("Coming up later on the road.")
	if id == Trip.city or Trip.is_done():
		lines.append("Record %d-%d  -  level %s" % [int(Trip.record.get("wins", 0)), int(Trip.record.get("losses", 0)),
				Trip.level.to_upper()])
	_card_lines.text = "\n".join(PackedStringArray(lines))

# the city's twist line under the card (hidden for Hometown, a city not built yet, an unknown id, a finished trip)
func _show_twist(id: String) -> void:
	var tl: String = ""
	if not Cities.city(id).is_empty() and Cities.is_built(id) and not Trip.is_done():
		tl = MenuScript.twist_line(Cities.twist(id))
	_card_twist.text = tl
	_card_twist.visible = tl != ""
	if OS.get_cmdline_user_args().has("--trip-test"):
		print("MAP CARD %s | twist line: %s" % [id, tl if tl != "" else "(none)"])

func _crew_line(id: String) -> String:
	if id != Trip.city:
		return "the best crews in the land"
	var rs = Cities.city(id).get("rounds", [])
	var r: int = Trip.bracket_round()
	if rs is Array and r < (rs as Array).size():
		return "vs " + str(((rs as Array)[r] as Dictionary).get("crew", {}).get("name", "?"))
	return ""

func _refresh_buttons() -> void:
	# a finished trip: GO's place holds TITLE (replay mode, P8-20)
	var done: bool = Trip.is_done()
	var label: String = "TITLE" if done else "GO"
	if _go_btn.text != label:
		_go_btn.text = label
		UI.set_kind(_go_btn, UI.KIND_MAIN if done else UI.KIND_LIT)
	var free: bool = _drive_t < 0.0 and _arm_t <= 0.0 and not _busy and _picker == null
	UI.set_enabled(_go_btn, Trip.active and free)
	_go_btn.visible = Trip.active
	UI.set_enabled(_menu_btn, _arm_t <= 0.0 and not _busy and _picker == null)

func _on_map_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _arm_t > 0.0:
		return
	var best := ""
	var best_d: float = PIN_TAP_R
	for id in Cities.ROUTE:
		var tip: Vector2 = to_screen(city_src(id))
		var mid: Vector2 = tip - Vector2(0, (PIN_ANCHOR.y - PIN_SIZE.y / 2.0) * SRC_SCALE)
		var d: float = minf(mb.position.distance_to(tip), mb.position.distance_to(mid))
		if d < best_d:
			best_d = d
			best = id
	var id_now: String = best if best != "" else Trip.city
	var pick: bool = best != "" and replayable(best)
	if id_now != _shown or pick:
		if audio != null:
			audio.play(TAP_SOUND, -10.0)
	if id_now != _shown:
		_show_city(id_now)
		_stat("map_pin_" + pin_state(id_now))
	if pick:
		open_picker(best)

# ---------------- actions ----------------

func _tap(on_tap: Callable) -> void:
	if _busy or _arm_t > 0.0:
		return
	if audio != null:
		audio.play(TAP_SOUND, -8.0)
	on_tap.call()

func _go(to: String, to_args := {}) -> void:
	if _busy:
		return
	_busy = true
	_refresh_buttons()
	Flow.go(to, to_args)

func _on_menu() -> void:
	_stat("map_menu")
	_go("title")

# Where GO leads: [screen, args]. Phase "map": the city's arrival story the first time (marked seen), then the
# lineup (New York: the bracket). Between steps (a CONTINUE into points / recruit / bracket): that screen.
static func go_target() -> Array:
	if not Trip.active or Trip.is_done():
		return ["title", {}]
	if Trip.phase != "map":
		return [Trip.resume_screen(), {}]
	var c: String = Trip.city
	var then: String = "bracket" if Trip.is_tournament(c) else "lineup"
	var st = Cities.city(c).get("story", {})
	var arrive: String = str(st.get("arrive", "")) if st is Dictionary else ""
	if arrive != "" and Trip.mark_seen(arrive):
		return ["story", {"scene": arrive, "then": then}]
	return [then, {}]

func _on_go() -> void:
	if not Trip.active or _drive_t >= 0.0 or _picker != null:
		return
	if Trip.is_done():
		_stat("map_title")   # replay mode: the button in GO's place is TITLE
		_go("title")
		return
	var t: Array = go_target()
	_stat("map_go")
	_go(str(t[0]), t[1])

# trip test: skip the drive, then GO
func auto_step() -> bool:
	if _busy:
		return false
	if _shot_stage >= 0 and _shot_stage < 3:
		return true   # --mapshot is driving this map
	if _picker != null:
		close_picker()
		return true
	if _drive_t >= 0.0:
		_end_drive()
		return true
	if not Trip.active or Trip.is_done():
		_go("title")
		return true
	_arm_t = 0.0
	_on_go()
	return true

# ---------------- the replay picker (P8-20) ----------------

# how many games a city has: 3, New York its rounds
static func games_of(id: String) -> int:
	if Trip.is_tournament(id):
		var rs = Cities.city(id).get("rounds", [])
		return (rs as Array).size() if rs is Array else 0
	return Trip.GAMES_PER_CITY

# a game of this city can be replayed now (won on this trip, between games)
static func replayable(id: String) -> bool:
	for n in range(1, games_of(id) + 1):
		if Trip.can_replay(id, n):
			return true
	return false

# "GAME 2  -  to 11  -  vs County Line", "SEMIFINAL  -  to 21  -  vs ..."
static func game_line(id: String, n: int) -> String:
	var c: Dictionary = Cities.city(id)
	var crew: String = str(c.get("crew", {}).get("name", "?"))
	var what: String = "GAME %d" % n
	if Trip.is_tournament(id):
		var rs = c.get("rounds", [])
		if rs is Array and n >= 1 and n <= (rs as Array).size():
			var r: Dictionary = (rs as Array)[n - 1]
			what = str(r.get("round", what))
			crew = str(r.get("crew", {}).get("name", "?"))
	elif n == Trip.GAMES_PER_CITY:
		what += " (BOSS)"
	return "%s  -  to %d  -  vs %s" % [what, Cities.game_target(id, n), crew]

func open_picker(id: String) -> void:
	close_picker()
	_picker_city = id
	_play_btns = {}
	var dim := ColorRect.new()
	dim.color = UI.DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_picker_dim_input)
	_root.add_child(dim)
	_picker = dim
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var p := UI.panel(center, PICK_SIZE)
	p.mouse_filter = Control.MOUSE_FILTER_STOP   # a tap on the panel itself does not close it
	var sb := p.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	sb.bg_color = Color(BAR_BG, 0.96)
	sb.border_color = GOLD_LINE
	sb.set_content_margin_all(20)
	p.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", PICK_GAP)
	p.add_child(box)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top)
	var c: Dictionary = Cities.city(id)
	var head: String = str(c.get("tournament_name", c.get("name", id))) if Trip.is_tournament(id) else \
			str(c.get("name", id))
	var t := UI.label(top, "REPLAY  %s  -  %d/%d STARS" % [head.to_upper(), Stars.city_total(id),
			games_of(id) * STARS_PER_GAME], PICK_TITLE_FONT, GOLD_TEXT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# P9: the level row (the replay's level, the trip's to start with) with CLOSE at its end, the hint under it
	_pick_level = start_level()
	_level_btns = {}
	var lrow := HBoxContainer.new()
	lrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lrow.add_theme_constant_override("separation", PICK_LEVEL_GAP)
	box.add_child(lrow)
	for lv in offered_levels():
		var b: Button = UI.button(lrow, str(LEVEL_NAMES.get(lv, str(lv).to_upper())), _tap.bind(
				set_replay_level.bind(str(lv))), UI.KIND_MAIN, PICK_LEVEL)
		b.add_theme_font_size_override("font_size", PICK_LEVEL_FONT)
		_level_btns[str(lv)] = b
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lrow.add_child(gap)
	UI.button(lrow, "CLOSE", _on_picker_close, UI.KIND_OPT, PICK_CLOSE)
	_hint = UI.label(box, "", PICK_HINT_FONT, STAR_GOLD)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var info := UI.label(box, PICK_INFO_DONE if Trip.is_done() else PICK_INFO, PICK_INFO_FONT, TWIST_COLOR)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(PICK_SIZE.x - 40.0, 0)
	for n in range(1, games_of(id) + 1):
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 20)
		box.add_child(row)
		var can: bool = Trip.can_replay(id, n)
		var l := UI.label(row, game_line(id, n), PICK_ROW_FONT, CITY_COLOR if can else LOCKED_COLOR)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.custom_minimum_size = Vector2(PICK_ROW_W, PICK_PLAY.y)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st := StarIcons.new()
		st.screen = self
		st.got = Stars.best(Stars.key(id, n))
		st.custom_minimum_size = PICK_STARS
		st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(st)
		if can:
			_play_btns[n] = UI.button(row, "PLAY", _tap.bind(_on_play.bind(n)), UI.KIND_LIT, PICK_PLAY)
		else:
			var nw := UI.label(row, PICK_NOT_WON, PICK_INFO_FONT, LOCKED_COLOR)
			nw.custom_minimum_size = PICK_PLAY
	_refresh_levels()
	_arm_t = PANEL_ARM   # the finger that opened it must not tap a row
	_refresh_buttons()
	_stat("map_picker")
	if OS.get_cmdline_user_args().has("--trip-test"):
		var games: Array = []
		for n in range(1, games_of(id) + 1):
			games.append("%d:%s%d*" % [n, "PLAY " if _play_btns.has(n) else "-", Stars.best(Stars.key(id, n))])
		print("MAP PICKER %s | %s | levels %s, picked %s (trip %s) | %s" % [id, " ".join(PackedStringArray(games)),
				"/".join(PackedStringArray(_level_btns.keys())), _pick_level, Trip.level, _hint.text])

func close_picker() -> void:
	if _picker == null:
		return
	_picker.queue_free()
	_picker = null
	_play_btns = {}
	_level_btns = {}
	_hint = null
	_refresh_buttons()

func _on_picker_close() -> void:
	if _arm_t > 0.0 or _busy:
		return
	if audio != null:
		audio.play(TAP_SOUND, -8.0)
	close_picker()

# a tap on the dim around the panel closes the picker
func _on_picker_dim_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _arm_t > 0.0:
		return
	_picker.accept_event()
	close_picker()

# P9: the levels the picker offers (names): EASY, NORMAL, HARD, and LEGEND once the stars open it
static func offered_levels() -> Array:
	var out: Array = []
	for lv in MenuScript.Difficulty.offered_levels():
		out.append(MenuScript.Difficulty.level_name(int(lv)))
	return out

# the level the picker opens on: the trip's (a closed LEGEND: Hard; anything else not offered: the first one)
static func start_level() -> String:
	var lv: String = Trip.level
	var offered: Array = offered_levels()
	if lv == "legend" and not offered.has(lv):
		lv = CLOSED_LEGEND
	if not offered.has(lv):
		lv = str(offered[0]) if offered.size() > 0 else Trip.DEFAULT_LEVEL
	return lv

# the level the open picker's PLAY uses
func replay_level() -> String:
	return _pick_level

# picks the replay's level (a tap on a level button); false for a level the open picker doesn't offer
func set_replay_level(lv: String) -> bool:
	if _picker == null or not _level_btns.has(lv):
		return false
	if lv != _pick_level:
		_pick_level = lv
		_stat("map_replay_level")
	_refresh_levels()
	return true

# the picked level gold, the others blue (LEGEND purple, as everywhere); the hint says what a win there earns
func _refresh_levels() -> void:
	for lv in _level_btns:
		var b: Button = _level_btns[lv]
		var kind: String = UI.KIND_LEGEND if str(lv) == "legend" else UI.KIND_MAIN
		UI.set_kind(b, UI.KIND_LIT if str(lv) == _pick_level else kind)
	if _hint == null:
		return
	var s: int = Stars.stars_for(_pick_level)
	var txt: String = PICK_HINT % [str(LEVEL_NAMES.get(_pick_level, _pick_level.to_upper())), s, "" if s == 1 else "S"]
	var lowest := STARS_PER_GAME
	for n in range(1, games_of(_picker_city) + 1):
		if Trip.can_replay(_picker_city, n):
			lowest = mini(lowest, Stars.best(Stars.key(_picker_city, n)))
	if s <= lowest:
		txt += PICK_HINT_BEST
	_hint.text = txt

func _on_play(n: int) -> void:
	if _picker_city == "" or not Trip.start_replay(_picker_city, n, _pick_level):
		return
	_stat("map_replay")
	_go("lineup")

# ---------------- --mapshot (test) ----------------

func _mapshot_ready(dropped: bool) -> void:
	if not OS.get_cmdline_user_args().has(MAPSHOT_FLAG):
		return
	_shot_t = 0.0
	_shot_step = 0
	if _shot_stage < 0:
		_shot_stage = 0
		print("MAPSHOT start | done %s | replayable %d | stars %d" % [Trip.is_done(), Trip.replay_games().size(),
				Stars.total()])
	elif _shot_stage == 1:
		var ok: bool = dropped and not Trip.replaying() and Flow.match.is_empty()
		print("MAPSHOT cancel: %s" % ("ok, the replay marker is gone" if ok else "WRONG (marker %s)" % str(Trip.replay)))
	elif _shot_stage == 2:
		var o: Dictionary = Trip.last_outcome
		print("MAPSHOT back from the replay | replay %s | won %s | stars %s -> %s | %s" % [
				str(o.get("replay", false)), str(o.get("won", false)), str(o.get("stars_before", "-")),
				str(o.get("stars_now", "-")), "marker gone" if not Trip.replaying() else "MARKER LEFT"])

func _mapshot_tick(delta: float) -> void:
	_shot_t += delta
	if _shot_t < MAPSHOT_WAIT or _busy:
		return
	_shot_t = 0.0
	_shot_step += 1
	if _drive_t >= 0.0:
		_end_drive()
	_arm_t = 0.0
	if _shot_stage == 0:
		if _shot_step == 1:
			_mapshot_save("done" if Trip.is_done() else "stars")
			return
		var city_id: String = _mapshot_city()
		if city_id == "":
			print("MAPSHOT nothing to replay (phase %s)" % Trip.phase)
			_shot_stage = 3
			return
		if _shot_step == 2:
			open_picker(city_id)
			return
		if _shot_step == 3:
			_mapshot_save("picker")
			return
		if _shot_step == 4:
			_mapshot_tap_level()   # P9: another level, lit, with its hint
			return
		if _shot_step == 5:
			_mapshot_save("picker_level")
			return
		var n: int = int(_play_btns.keys()[0]) if _play_btns.size() > 0 else 0
		var ok: bool = Trip.start_replay(city_id, n, _pick_level)
		print("MAPSHOT start_replay %s at %s: %s, then back to the map as from the lineup" % [Stars.key(city_id, n),
				_pick_level, "marked" if ok and Trip.replaying() else "REFUSED"])
		_shot_stage = 1
		_go("map")
	elif _shot_stage == 1:
		var city_id: String = _mapshot_city()
		if _shot_step == 1:
			open_picker(city_id)
			return
		_arm_t = 0.0
		_mapshot_tap_level()
		var n: int = int(_play_btns.keys()[0]) if _play_btns.size() > 0 else 0
		print("MAPSHOT PLAY %s at %s (a tap on the picker's button; trip level %s)" % [Stars.key(city_id, n),
				_pick_level, Trip.level])
		_shot_stage = 2
		if _play_btns.has(n):
			(_play_btns[n] as Button).pressed.emit()
		if not _busy:
			print("MAPSHOT PLAY did nothing")
			_shot_stage = 3
	elif _shot_stage == 2:
		if _shot_step == 1:
			_mapshot_save("after_replay")
		else:
			_shot_stage = 3   # a step later: the screenshot is written before the trip test moves on

# P9: a level other than the one the picker opened on (other_level()), by a tap on its button
func _mapshot_tap_level() -> void:
	var lv: String = other_level(_pick_level)
	_arm_t = 0.0
	if _level_btns.has(lv):
		(_level_btns[lv] as Button).pressed.emit()
	print("MAPSHOT level %s tapped: picked %s | %s" % [lv, _pick_level, _hint.text if _hint != null else "-"])

# a level to test a replay at that isn't lv: the highest offered one, or the lowest when lv is the highest
static func other_level(lv: String) -> String:
	var offered: Array = offered_levels()
	if offered.is_empty():
		return lv
	var top: String = str(offered.back())
	return top if top != lv else str(offered[0])

# --map-pick city, else the last city with a replayable game
func _mapshot_city() -> String:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = cmd.find(MAPSHOT_PICK_FLAG)
	if i >= 0 and i + 1 < cmd.size() and replayable(cmd[i + 1]):
		return cmd[i + 1]
	var rg: Array = Trip.replay_games()
	return str((rg.back() as Dictionary).get("city", "")) if rg.size() > 0 else ""

func _mapshot_save(tag: String) -> void:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = cmd.find(MAPSHOT_FLAG)
	var dir: String = cmd[i + 1] if i >= 0 and i + 1 < cmd.size() and not cmd[i + 1].begins_with("--") else "/tmp"
	var path: String = dir.path_join("hoops_map_%s.png" % tag)
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		print("MAPSHOT %s: no image (headless? run under xvfb)" % path)
		return
	img.save_png(path)
	print("MAPSHOT saved %s" % path)

# a 5-pointed star around c (outer radius r)
static func star_poly(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(10):
		var a: float = -PI / 2.0 + i * PI / 5.0
		var rr: float = r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts

static func draw_star(ci: CanvasItem, c: Vector2, r: float, full: bool) -> void:
	var pts: PackedVector2Array = star_poly(c, r)
	ci.draw_colored_polygon(pts, STAR_GOLD if full else STAR_EMPTY)
	var edge: PackedVector2Array = pts.duplicate()
	edge.append(pts[0])
	ci.draw_polyline(edge, STAR_EDGE, maxf(1.5, r * 0.15))


# A picker row's 3 stars (the best so far gold, the rest grey).
class StarIcons extends Control:
	var screen   # the trip_map.gd node
	var got := 0

	func _draw() -> void:
		var r: float = screen.PICK_STAR_R
		var step: float = size.x / float(screen.STARS_PER_GAME)
		for i in range(screen.STARS_PER_GAME):
			screen.draw_star(self, Vector2(step * (i + 0.5), size.y / 2.0), r, i < got)


# The map, pins, labels, van and the header band, drawn from source px through the screen's to_screen().
class MapArt extends Control:
	var screen   # the trip_map.gd node

	func _draw() -> void:
		var s = screen
		var o: Vector2 = s.map_origin()
		var base: Vector2 = s.BASE
		var tex: Dictionary = s._tex
		# the map (bars are the root's background)
		if tex.has("usa"):
			draw_texture_rect(tex["usa"], Rect2(o, base), false)
		else:
			draw_rect(Rect2(o, base), Color("#2d6cb6"))
			draw_rect(Rect2(o + Vector2(60, 90), base - Vector2(120, 150)), Color(0.35, 0.55, 0.3))
			draw_rect(Rect2(o + Vector2(60, 90), base - Vector2(120, 150)), Color.WHITE, false, 3.0)
		# roads, only when the map art is missing (usa.png has them painted)
		if not tex.has("usa"):
			for i in range(1, s.Cities.ROUTE.size()):
				var pts: Array = s.road(s.Cities.ROUTE[i - 1], s.Cities.ROUTE[i])
				var line := PackedVector2Array()
				for p in pts:
					line.append(s.to_screen(p))
				draw_polyline(line, Color(0.25, 0.25, 0.28), 6.0)
		# the van under the pins (the pins and names stay readable)
		_draw_van()
		var font: Font = ThemeDB.fallback_font
		for id in s.Cities.ROUTE:
			var st: String = s.pin_state(id)
			var tip: Vector2 = s.to_screen(s.city_src(id))
			if st == "current":
				tip.y -= absf(sin(s._t * TAU * s.PIN_BOB_HZ)) * s.PIN_BOB * s.SRC_SCALE
			var pin_px: Vector2 = s.PIN_SIZE * s.SRC_SCALE
			var top_left: Vector2 = tip - s.PIN_ANCHOR * s.SRC_SCALE
			if tex.has(st):
				draw_texture_rect(tex[st], Rect2(top_left.round(), pin_px), false)
			else:
				var c: Vector2 = top_left + Vector2(pin_px.x / 2.0, pin_px.x / 2.0)
				draw_line(c, tip, Color(0.1, 0.1, 0.12), 4.0)
				draw_circle(c, pin_px.x / 2.0, s.PIN_COLORS.get(st, Color.WHITE))
				draw_arc(c, pin_px.x / 2.0, 0.0, TAU, 20, Color(0.1, 0.1, 0.12), 2.0)
			# the name
			var nm: String = str(s.Cities.city(id).get("name", id))
			if st == "locked":
				nm += s.SOON
			var fs: int = s.CITY_FONT
			var w: float = font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var side: String = s.label_side(id)
			var base_tip: Vector2 = s.to_screen(s.city_src(id))
			var pos: Vector2
			if side == "left":
				pos = base_tip + Vector2(-s.LABEL_DX - w, s.LABEL_DY + fs * 0.35)
			elif side == "below":
				pos = base_tip + Vector2(-w / 2.0, 14.0 + fs)
			else:
				pos = base_tip + Vector2(s.LABEL_DX, s.LABEL_DY + fs * 0.35)
			var col: Color = s.LOCKED_COLOR if st == "locked" else s.CITY_COLOR
			draw_string_outline(font, pos, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, s.CITY_OUTLINE, s.OUTLINE_COLOR)
			draw_string(font, pos, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			if st != "locked":
				_draw_pin_stars(font, id, pos, w, side)
		# the header band and the gold edges
		var hh: float = s.header_h()
		draw_rect(Rect2(0, 0, size.x, hh), Color(s.BAR_BG, s.HEADER_ALPHA))
		draw_line(Vector2(0, hh), Vector2(size.x, hh), s.GOLD_LINE, s.LINE_W)
		var bottom: float = o.y + base.y
		if bottom < size.y - 1.0:
			draw_line(Vector2(0, bottom), Vector2(size.x, bottom), s.GOLD_LINE, s.LINE_W)

	# "* 7/9" under the city name, on the name's side (P8-20)
	func _draw_pin_stars(font: Font, id: String, name_pos: Vector2, name_w: float, side: String) -> void:
		var s = screen
		var got: int = s.Stars.city_total(id)
		var txt: String = "%d/%d" % [got, s.games_of(id) * s.STARS_PER_GAME]
		var fs: int = s.PIN_STARS_FONT
		var r: float = s.PIN_STAR_R
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var full_w: float = r * 2.0 + 4.0 + tw
		var x: float = name_pos.x
		var y: float = name_pos.y + s.PIN_STARS_DY
		if s.PIN_STARS_ABOVE.has(id):
			y = name_pos.y - s.PIN_STARS_DY - 2.0
		if side == "left":
			x = name_pos.x + name_w - full_w
		elif side == "below":
			x = name_pos.x + (name_w - full_w) / 2.0
		var base: Vector2 = Vector2(x, y)
		s.draw_star(self, base + Vector2(r, -fs * 0.35), r, got > 0)
		var tp: Vector2 = base + Vector2(r * 2.0 + 4.0, 0)
		draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, s.CITY_OUTLINE, s.OUTLINE_COLOR)
		draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, s.STAR_GOLD if got > 0 else s.CITY_COLOR)

	func _draw_van() -> void:
		var s = screen
		var v: Array = s.van_now()
		var at: Vector2 = s.to_screen(v[0])
		var right: bool = float(v[1]) >= 0.0
		var driving: bool = bool(v[2])
		var z: float = s.SRC_SCALE
		var frame: int = int(s._t * s.VAN_FPS) % 2 if driving else 0
		if driving:
			at.y -= absf(sin(s._t * TAU * s.VAN_FPS / 2.0)) * s.VAN_BOB * z
		var tex: Dictionary = s._tex
		if tex.has("van"):
			var t: Texture2D = tex["van"]
			var fw: float = t.get_width() / 2.0
			var fh: float = t.get_height() / 2.0
			var anchor: Vector2 = s.VAN_FALLBACK_ANCHOR
			var va = s._data.get("van_anchor", null)
			if va is Array and (va as Array).size() >= 2:
				anchor = Vector2(float(va[0]), float(va[1]))
			var src := Rect2(frame * fw, (0.0 if right else fh), fw, fh)
			draw_texture_rect_region(t, Rect2((at - anchor * z).round(), Vector2(fw, fh) * z), src)
		else:
			var sz: Vector2 = s.VAN_FALLBACK_SIZE * z
			var tl: Vector2 = at - s.VAN_FALLBACK_ANCHOR * z
			draw_rect(Rect2(tl + Vector2(0, sz.y * 0.25), Vector2(sz.x, sz.y * 0.6)), s.VAN_COLOR)
			draw_rect(Rect2(tl + Vector2(0, sz.y * 0.55), Vector2(sz.x, sz.y * 0.1)), s.VAN_TRIM)
			var win_x: float = sz.x * 0.65 if right else sz.x * 0.1
			draw_rect(Rect2(tl + Vector2(win_x, sz.y * 0.32), Vector2(sz.x * 0.25, sz.y * 0.18)), Color(0.55, 0.75, 0.9))
			for wx in [0.22, 0.78]:
				draw_circle(tl + Vector2(sz.x * wx, sz.y * 0.85), sz.y * 0.12, Color(0.1, 0.1, 0.12))
