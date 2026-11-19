extends CanvasLayer
# Story scenes (P5-10), the Flow screen "story": fighting-game style, big portraits left and right, a name plate on
# the speaker's side and a text box that types the line out. Built in code with ui_kit.gd; the lines are data in
# story_text.gd.
#   Flow.go("story", {"scene": "hometown_arrive", "then": "lineup"})        # then_args: optional args for `then`
#   optional args: "city" (the {city} in the text; default the trip's city)
# Tap anywhere: the first tap finishes the typing, the next one shows the next line; after the last line the flow
# goes to args.then (the map if none). SKIP (top-right) skips the rest of the scene. The scene is marked seen in the
# trip save (Trip.mark_seen; trip.gd's after_result() already marks the ones it sends here).
# Portraits: assets/portraits/<portrait>.png (or <portrait>_<mood>.png), 96 x 112 drawn at PORTRAIT_SCALE, facing
# right (the right side is mirrored). A missing file = a silhouette in the crew's color, so new art just drops in.
# Both sides keep their last speaker; the one not talking is dimmed. A "narrator" line has no portrait or plate.
# Desktop testing: Space / Enter = tap, Escape = SKIP.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Cities = preload("res://scripts/cities.gd")
const Trip = preload("res://scripts/trip.gd")
const StoryText = preload("res://scripts/story_text.gd")
const LegendsData = preload("res://scripts/legends_data.gd")   # P9-14: a legend's name plate (lg_ ids)

const PORTRAIT_DIR := "res://assets/portraits/"
const PORTRAIT_SRC := Vector2(96, 112)     # source px of a portrait
const PORTRAIT_SCALE := 3.0                # drawn at 3x (288 x 336)
const PORTRAIT_INSET := 110.0              # px from the screen edge to a portrait
const PORTRAIT_SINK := 24.0                # px a portrait's bottom hides behind the text box
const DIM := Color(0.42, 0.42, 0.5)        # the portrait that isn't talking
const SPEAK_LIFT := 10.0                   # px the speaker rises (a small "step forward")
const SILHOUETTE_CREW := Color(0.16, 0.3, 0.6)   # your crew's silhouettes (blue, ui_kit OFF_COLOR)
const SILHOUETTE_OTHER := Color(0.45, 0.45, 0.5) # a player with no crew color

const BOX_H := 200.0                       # text box height
const BOX_MARGIN := 40.0                   # px from the left / right screen edge
const BOX_BOTTOM := 24.0                   # px from the bottom edge
const BOX_FILL := Color(0.05, 0.05, 0.08, 0.95)
const BOX_BORDER_W := 5
const TEXT_FONT := 32
const NARRATOR_COLOR := Color(1.0, 0.9, 0.6)   # narrator lines in a pale gold, no plate
const PLATE_SIZE := Vector2(300, 54)       # the name plate (gold, over the box's top edge)
const PLATE_INSET := 70.0                  # px from the box edge
const PLATE_FONT := 32
const HINT_FONT := 22                      # "TAP >"
const HINT_BLINK_HZ := 2.0

const TYPE_CPS := 48.0                     # letters per second of the typing effect
const ARM_TIME := 0.35                     # s the screen ignores taps (the tap that opened it can't skip a line)
const SKIP_POS := Vector2(24, 20)          # SKIP: px from the top-right corner
const BLIP_SFX := "story_blip"             # P5-A4 sound, played while typing if the file exists
const BLIP_EVERY := 3                      # letters per blip
const TAP_SFX := "bounce"                  # a line advanced (title.gd's tap sound)

# the backdrop (the mock-up's purple sunburst)
const BG_TOP := Color(0.10, 0.09, 0.20)
const BG_LOW := Color(0.18, 0.15, 0.32)
const RAY_COLOR := Color(0.30, 0.28, 0.52, 0.55)
const RAYS := 28
const RAY_WIDTH := 3.0
const RAY_SPIN := 0.03                     # rad/s the rays turn

var main                    # main.gd (set by Flow.build_screen)
var audio                   # this screen's audio.gd
var music := "menu"

var _lines: Array = []
var _index := -1
var _shown := 0.0           # letters typed so far
var _total := 0
var _arm_t := ARM_TIME
var _busy := false
var _then := "map"
var _then_args := {}
var _city_name := ""
var _blip_ok := false
var _last_blip := 0
var _t := 0.0

var _root: Control
var _bg: Control
var _por: Array = []        # [left TextureRect, right TextureRect]
var _por_who: Array = ["", ""]
var _box: PanelContainer
var _text: Label
var _plate: PanelContainer
var _plate_label: Label
var _hint: Label
var _skip: Button
static var _sil_cache := {}

func _ready() -> void:
	var a: Dictionary = Flow.args
	var scene_id: String = str(a.get("scene", ""))
	_then = str(a.get("then", "map"))
	if _then == "":
		_then = "map"
	var ta = a.get("then_args", {})
	_then_args = ta if ta is Dictionary else {}
	var cid: String = str(a.get("city", Trip.city))
	_city_name = str(Cities.city(cid).get("name", cid)).capitalize()
	_lines = StoryText.scene(scene_id)
	_blip_ok = ResourceLoader.exists("res://assets/sfx/" + BLIP_SFX + ".ogg") \
			or ResourceLoader.exists("res://assets/sfx/" + BLIP_SFX + ".wav")
	if scene_id.begins_with("lg_") or scene_id.begins_with("legends_"):
		pass   # a Legends scene never writes the trip (legends.gd after_result() marks it in the Legends file)
	elif scene_id != "":
		Trip.mark_seen(scene_id)   # saved; nothing happens if it was marked already or no trip is loaded
	_build()
	_stat("story_scene")
	if _lines.is_empty():
		push_warning("story: no scene '%s'" % scene_id)
		_finish()
		return
	_preset_sides()
	_next_line()

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

# ---------------- building ----------------

func _build() -> void:
	_root = UI.screen_root(self)
	_bg = Backdrop.new()
	_bg.story = self
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP   # the tap area: anywhere but SKIP
	_bg.gui_input.connect(_on_input)
	_root.add_child(_bg)
	for side in 2:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # comic portraits are drawn art (smooth), not pixels
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.flip_h = side == 1
		tr.visible = false
		var w: float = PORTRAIT_SRC.x * PORTRAIT_SCALE
		var h: float = PORTRAIT_SRC.y * PORTRAIT_SCALE
		var bottom: float = -(BOX_BOTTOM + BOX_H - PORTRAIT_SINK)
		tr.anchor_top = 1.0
		tr.anchor_bottom = 1.0
		tr.anchor_left = 0.0 if side == 0 else 1.0
		tr.anchor_right = tr.anchor_left
		tr.offset_bottom = bottom
		tr.offset_top = bottom - h
		if side == 0:
			tr.offset_left = PORTRAIT_INSET
			tr.offset_right = PORTRAIT_INSET + w
		else:
			tr.offset_left = -PORTRAIT_INSET - w
			tr.offset_right = -PORTRAIT_INSET
		_root.add_child(tr)
		_por.append(tr)
	# the text box
	_box = PanelContainer.new()
	var sb: StyleBoxFlat = UI.style_box(BOX_FILL, UI.LIT_COLOR, BOX_BORDER_W)
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 34
	sb.content_margin_bottom = 26
	_box.add_theme_stylebox_override("panel", sb)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.anchor_left = 0.0
	_box.anchor_right = 1.0
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = BOX_MARGIN
	_box.offset_right = -BOX_MARGIN
	_box.offset_bottom = -BOX_BOTTOM
	_box.offset_top = -BOX_BOTTOM - BOX_H
	_root.add_child(_box)
	_text = UI.label(_box, "", TEXT_FONT)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING   # no re-wrapping while typing
	_text.label_settings.line_spacing = 8
	_hint = UI.label(_root, "TAP >", HINT_FONT, UI.LIT_COLOR)
	_hint.anchor_left = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_right = -BOX_MARGIN - 24
	_hint.offset_left = -BOX_MARGIN - 124
	_hint.offset_bottom = -BOX_BOTTOM - 8
	_hint.offset_top = -BOX_BOTTOM - 40
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# the name plate
	_plate = PanelContainer.new()
	var ps: StyleBoxFlat = UI.style_box(UI.LIT_COLOR, Color(0.35, 0.25, 0.05), 3)
	ps.set_corner_radius_all(8)
	_plate.add_theme_stylebox_override("panel", ps)
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.custom_minimum_size = PLATE_SIZE
	_plate.anchor_top = 1.0
	_plate.anchor_bottom = 1.0
	_plate.offset_top = -BOX_BOTTOM - BOX_H - PLATE_SIZE.y / 2.0
	_plate.offset_bottom = _plate.offset_top + PLATE_SIZE.y
	_root.add_child(_plate)
	_plate_label = Label.new()
	var ls := LabelSettings.new()
	ls.font_size = PLATE_FONT
	ls.font_color = UI.LIT_TEXT
	_plate_label.label_settings = ls
	_plate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plate_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_plate_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(_plate_label)
	_plate.visible = false
	# SKIP, top-right
	_skip = UI.button(_root, "SKIP", _on_skip, UI.KIND_OPT, UI.SMALL_SIZE)
	_skip.anchor_left = 1.0
	_skip.anchor_right = 1.0
	_skip.offset_right = -SKIP_POS.x
	_skip.offset_left = -SKIP_POS.x - UI.SMALL_SIZE.x
	_skip.offset_top = SKIP_POS.y
	_skip.offset_bottom = SKIP_POS.y + UI.SMALL_SIZE.y
	UI.set_enabled(_skip, false)

# Both sides show their first speaker from the start (dimmed until he talks), as a fighting game's face-off.
func _preset_sides() -> void:
	for side in 2:
		for line in _lines:
			var who: String = str(line.get("who", "narrator"))
			if who != "narrator" and _side_of(line) == side:
				_set_portrait(side, who, "")
				break
	for tr in _por:
		(tr as TextureRect).modulate = DIM

# ---------------- playing ----------------

func _process(delta: float) -> void:
	_t += delta
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			UI.set_enabled(_skip, true)
	if _index >= 0 and _shown < _total:
		_shown = minf(_shown + TYPE_CPS * delta, float(_total))
		_text.visible_characters = int(_shown)
		if _blip_ok and audio != null and int(_shown) - _last_blip >= BLIP_EVERY:
			_last_blip = int(_shown)
			audio.play(BLIP_SFX, -14.0)
	_hint.visible = _index >= 0 and _shown >= _total and fmod(_t * HINT_BLINK_HZ, 1.0) < 0.6
	_bg.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_ESCAPE:
		_on_skip()
	elif k.keycode == KEY_SPACE or k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		_tap()

func _on_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_tap()
		_bg.accept_event()

# The first tap finishes the typing, the next one shows the next line.
func _tap() -> void:
	if _busy or _arm_t > 0.0 or _index < 0:
		return
	if _shown < _total:
		_shown = float(_total)
		_text.visible_characters = -1
		return
	if audio != null:
		audio.play(TAP_SFX, -10.0)
	_next_line()

func _next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		_finish()
		return
	var line: Dictionary = _lines[_index]
	var who: String = str(line.get("who", "narrator"))
	var side: int = _side_of(line)
	_text.text = _fill(str(line.get("text", "")))
	_text.label_settings.font_color = NARRATOR_COLOR if who == "narrator" else UI.TEXT_COLOR
	_total = _text.text.length()
	_shown = 0.0
	_last_blip = 0
	_text.visible_characters = 0
	if who == "narrator":
		_plate.visible = false
		for tr in _por:
			_speak(tr, false)
	else:
		_set_portrait(side, who, str(line.get("mood", "")))
		for s in 2:
			_speak(_por[s], s == side)
		var p: Dictionary = Cities.player(who)
		if p.is_empty() and LegendsData.is_legend_id(who):
			p = LegendsData.legend(who)
		_plate_label.text = str(p.get("name", who.to_upper()))
		_plate.visible = true
		if side == 0:
			_plate.anchor_left = 0.0
			_plate.anchor_right = 0.0
			_plate.offset_left = BOX_MARGIN + PLATE_INSET
			_plate.offset_right = _plate.offset_left + PLATE_SIZE.x
		else:
			_plate.anchor_left = 1.0
			_plate.anchor_right = 1.0
			_plate.offset_right = -BOX_MARGIN - PLATE_INSET
			_plate.offset_left = _plate.offset_right - PLATE_SIZE.x
	_stat("story_line")

func _speak(tr: TextureRect, on: bool) -> void:
	tr.modulate = Color.WHITE if on else DIM
	var h: float = PORTRAIT_SRC.y * PORTRAIT_SCALE
	var bottom: float = -(BOX_BOTTOM + BOX_H - PORTRAIT_SINK) - (SPEAK_LIFT if on else 0.0)
	tr.offset_bottom = bottom
	tr.offset_top = bottom - h

func _side_of(line: Dictionary) -> int:
	return 1 if str(line.get("side", "left")) == "right" else 0

func _fill(s: String) -> String:
	return s.replace("{crew}", Cities.CREW_NAME.capitalize()).replace("{van}", Cities.VAN_NAME.capitalize()) \
			.replace("{city}", _city_name)

func _on_skip() -> void:
	if _busy or _arm_t > 0.0:
		return
	_stat("story_skip")
	if audio != null:
		audio.play(TAP_SFX, -10.0)
	_finish()

func _finish() -> void:
	if _busy:
		return
	_busy = true
	UI.set_enabled(_skip, false)
	Flow.go(_then, _then_args)

# trip test: one line (finishing the typing first), and on past the last line
func auto_step() -> bool:
	if _busy:
		return false
	_arm_t = 0.0
	if _index >= 0 and _shown < _total:
		_shown = float(_total)
		_text.visible_characters = -1
	_next_line()
	return true

# ---------------- portraits ----------------

func _set_portrait(side: int, who: String, mood: String) -> void:
	var tr: TextureRect = _por[side]
	var key: String = who + "|" + mood
	if _por_who[side] == key:
		return
	_por_who[side] = key
	tr.texture = _portrait(who, mood)
	tr.visible = true

# assets/portraits/<portrait>_<mood>.png, else <portrait>.png, else a silhouette in the crew's color
func _portrait(who: String, mood: String) -> Texture2D:
	var id: String = str(Cities.player(who).get("portrait", who))
	var tries: Array = []
	if mood != "":
		tries.append(PORTRAIT_DIR + id + "_" + mood + ".png")
	tries.append(PORTRAIT_DIR + id + ".png")
	for path in tries:
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				return tex
	return _silhouette(_crew_color(who))

static func _crew_color(who: String) -> Color:
	if str(Cities.player(who).get("tier", "")) == "start":
		return SILHOUETTE_CREW
	for cid in Cities.CITIES:
		var c: Dictionary = Cities.CITIES[cid]
		var crew: Dictionary = c.get("crew", {})
		var named: Array = []
		named.append_array(crew.get("good", []))
		named.append_array(crew.get("avg", []))
		named.append(crew.get("boss", ""))
		if named.has(who):
			return crew.get("ui_color", SILHOUETTE_OTHER)
		for r in c.get("rounds", []):
			if (r.get("players", []) as Array).has(who):
				return (r.get("crew", {}) as Dictionary).get("ui_color", SILHOUETTE_OTHER)
	return SILHOUETTE_OTHER

# a bust shape (head, neck, shoulders) at the portrait's source size, dark with a lighter rim, facing right
static func _silhouette(col: Color) -> Texture2D:
	var key: String = col.to_html()
	if _sil_cache.has(key):
		return _sil_cache[key]
	var w: int = int(PORTRAIT_SRC.x)
	var h: int = int(PORTRAIT_SRC.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill: Color = col.darkened(0.55)
	var rim: Color = col.lightened(0.15)
	var inside := func(x: float, y: float) -> bool:
		var head: bool = Vector2((x - 50.0) / 22.0, (y - 42.0) / 26.0).length() <= 1.0
		var neck: bool = x >= 40.0 and x <= 60.0 and y >= 60.0 and y <= 80.0
		var shoulders: bool = y >= 76.0 and Vector2((x - 48.0) / 46.0, (y - 112.0) / 36.0).length() <= 1.0
		return head or neck or shoulders
	for y in h:
		for x in w:
			if not inside.call(float(x), float(y)):
				continue
			var edge: bool = not (inside.call(float(x - 2), float(y)) and inside.call(float(x + 2), float(y))
					and inside.call(float(x), float(y - 2)))
			img.set_pixel(x, y, rim if edge else fill)
	var tex: Texture2D = ImageTexture.create_from_image(img)
	_sil_cache[key] = tex
	return tex


# the purple sunburst behind the portraits (as in docs/art/portraits_sample_v1.png)
class Backdrop extends Control:
	var story

	func _draw() -> void:
		var sz: Vector2 = size
		var bands: int = 10
		for i in bands:
			var c: Color = BG_TOP.lerp(BG_LOW, float(i) / float(bands - 1))
			draw_rect(Rect2(0, sz.y * i / bands, sz.x, sz.y / bands + 1.0), c)
		var centre := Vector2(sz.x * 0.5, sz.y * 0.36)
		var reach: float = sz.length()
		var spin: float = story._t * RAY_SPIN
		for i in RAYS:
			var a: float = spin + TAU * float(i) / float(RAYS)
			var d := Vector2(cos(a), sin(a))
			draw_line(centre + d * 120.0, centre + d * reach, RAY_COLOR, RAY_WIDTH)
