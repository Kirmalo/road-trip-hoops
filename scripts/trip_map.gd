extends CanvasLayer
# Trip map (P5-09, owner Q7 a: fixed route, tap GO, no replays). Flow screen "map", built in code with ui_kit.gd.
#   - the approved pixel USA map (assets/map/usa.png, 640 x 360 drawn 2x, centred; the bars above and below in
#     map.json bar_bg), the 8 city pins: beaten = trophy (pin_done), the city you play next = gold (pin_current, it
#     bobs), a built city still ahead = blue (pin), not built yet = grey (pin_locked) with "(soon)"
#   - the van "The Biscuit" parked on the road at your city; after a city is beaten it drives the road to the next
#     one in DRIVE_TIME s (a tap anywhere skips the drive)
#   - header: ROAD TRIP, your crew, the next city, the record; MENU (back to the title) top-right
#   - city card bottom-left: name, state, game n of 3, target, the crew you face, record and level. Tap a pin to see
#     that city on the card (a grey one says "coming soon"); tap the map to go back to your city
#   - GO bottom-right: the city's arrival story the first time, then the lineup (New York: the bracket). When the trip
#     is between steps (points / recruit / bracket after a CONTINUE) GO goes to that screen.
# Works without the art: a missing usa.png / pin / van / map.json is drawn with plain shapes (FALLBACK_CITIES).
# Desktop testing: Enter / Space = GO, Escape = MENU. Trip test: auto_step() skips the drive, then taps GO.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Cities = preload("res://scripts/cities.gd")

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
const CARD_SIZE := Vector2(560, 150)
const CARD_TITLE_FONT := 30
const CARD_FONT := 22
const GO_SIZE := Vector2(280, 130)
const GO_MARGIN := Vector2(24, 20)             # from the bottom-right corner
const MENU_SIZE := Vector2(200, 110)
const MENU_MARGIN := Vector2(16, 8)            # from the top-right corner
const PANEL_ARM := 0.3                         # s the screen ignores taps (a double tap from the last screen)

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
var _shown := ""                               # the city on the card
var _arm_t := PANEL_ARM
var _busy := false
var _t := 0.0
# the drive: screen-independent source-px polyline, its cumulative lengths, progress 0..1
var _path: Array = []
var _lens: Array = []
var _drive_t := -1.0                           # s into the drive; < 0 = parked
var _park := Vector2.ZERO
var _park_dir := 1.0                           # +1 faces right, -1 left

func _ready() -> void:
	if not Trip.active:
		Trip.continue_trip()   # e.g. a reload straight onto the map: the save is the truth
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

func _process(delta: float) -> void:
	_t += delta
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
		_tap(_on_menu)
	elif k.keycode == KEY_ENTER or k.keycode == KEY_SPACE:
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
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	_card_title = UI.label(box, "", CARD_TITLE_FONT, GOLD_TEXT)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_card_lines = UI.label(box, "", CARD_FONT)
	_card_lines.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_card_lines.vertical_alignment = VERTICAL_ALIGNMENT_TOP

# the card for a city: yours (game, target, crew), a beaten one, one ahead, or a "coming soon" one
func _show_city(id: String) -> void:
	_shown = id
	var c: Dictionary = Cities.city(id)
	if c.is_empty():
		_card_title.text = "NO TRIP"
		_card_lines.text = "Start a Road Trip from the title screen."
		return
	_card_title.text = "%s, %s" % [str(c.get("name", id)), str(c.get("state", ""))]
	var lines: Array = []
	var st: String = pin_state(id)
	if Trip.is_done():
		lines.append("Trip complete! Every trophy is in the van.")
	elif st == "locked":
		lines.append("Coming soon: this city opens in a later update.")
		lines.append("The Biscuit drives on by for now.")
	elif st == "done" and id == Trip.city:
		lines.append("Beaten! " + ("Spend your stat points." if Trip.phase == "points" else
				"Pick a new player for the bench." if Trip.phase == "recruit" else "On to the next city."))
	elif st == "done":
		lines.append("Beaten! The trophy rides in the van.")
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

func _crew_line(id: String) -> String:
	if id != Trip.city:
		return "the best crews in the land"
	var rs = Cities.city(id).get("rounds", [])
	var r: int = Trip.bracket_round()
	if rs is Array and r < (rs as Array).size():
		return "vs " + str(((rs as Array)[r] as Dictionary).get("crew", {}).get("name", "?"))
	return ""

func _refresh_buttons() -> void:
	var can_go: bool = Trip.active and not Trip.is_done() and _drive_t < 0.0 and _arm_t <= 0.0 and not _busy
	UI.set_enabled(_go_btn, can_go)
	_go_btn.visible = Trip.active and not Trip.is_done()
	UI.set_enabled(_menu_btn, _arm_t <= 0.0 and not _busy)

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
	if id_now != _shown:
		if audio != null:
			audio.play(TAP_SOUND, -10.0)
		_show_city(id_now)
		_stat("map_pin_" + pin_state(id_now))

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
	if not Trip.active or Trip.is_done() or _drive_t >= 0.0:
		return
	var t: Array = go_target()
	_stat("map_go")
	_go(str(t[0]), t[1])

# trip test: skip the drive, then GO
func auto_step() -> bool:
	if _busy:
		return false
	if _drive_t >= 0.0:
		_end_drive()
		return true
	if not Trip.active or Trip.is_done():
		_go("title")
		return true
	_arm_t = 0.0
	_on_go()
	return true


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
		# the header band and the gold edges
		var hh: float = s.header_h()
		draw_rect(Rect2(0, 0, size.x, hh), Color(s.BAR_BG, s.HEADER_ALPHA))
		draw_line(Vector2(0, hh), Vector2(size.x, hh), s.GOLD_LINE, s.LINE_W)
		var bottom: float = o.y + base.y
		if bottom < size.y - 1.0:
			draw_line(Vector2(0, bottom), Vector2(size.x, bottom), s.GOLD_LINE, s.LINE_W)

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
