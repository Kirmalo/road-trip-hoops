extends RefCounted
# Shared look for every screen built in code (P5-01): big buttons, panels, titles, text boxes and sliders, taken from
# menu.gd's difficulty panel, so the title, trip map, story, lineup, result, points, recruit, bracket and pause screens
# all match. Static only, used through preload:
#   const UI = preload("res://scripts/ui_kit.gd")
#   var root := UI.screen_root(self)                       # self = the screen's CanvasLayer
#   var box := UI.vbox(root)                               # centred column
#   UI.title(box, "ROAD TRIP HOOPS")
#   UI.button(box, "ROAD TRIP", _on_trip)                  # big blue button
#   UI.button(box, "CONTINUE", _on_continue, UI.KIND_LIT)  # the gold "default" button
# Touch first: buttons are at least 200 x 110 px at the 1280x720 base (board rule); focus boxes are off (a tap is the
# input). Your crew is blue and gold (owner Q11): blue = a normal button, gold = the lit / default one.

const LAYER := 20                        # screens and the pause panel sit over the HUD (10), like menu.gd

# sizes (px at the 1280x720 base)
const MIN_BUTTON := Vector2(200, 110)    # board minimum for anything tappable
const BUTTON_SIZE := Vector2(300, 140)   # main choices (menu.gd level buttons)
const OPT_SIZE := Vector2(380, 110)      # options and secondary buttons (menu.gd COURT / MUSIC)
const SMALL_SIZE := Vector2(200, 110)    # BACK, SKIP, +: the minimum
const BUTTON_GAP := 40                   # px between buttons in a row
const COLUMN_GAP := 26                   # px between rows in a column
const CORNER := 18                       # corner radius of buttons and panels
const BORDER := 3                        # normal border width
const LIT_BORDER_W := 8                  # the lit button's border width
const PANEL_PAD := 28                    # inner padding of a panel / text box
const SLIDER_SIZE := Vector2(520, 90)    # a slider: long and tall enough to drag with a thumb
const GRABBER_PX := 56                   # slider knob diameter
const SLIDER_TRACK := 14                 # slider track height

# fonts (Godot's default font, sizes as menu.gd)
const TITLE_FONT := 60
const SUB_FONT := 28
const BUTTON_FONT := 46
const OPT_FONT := 34
const TEXT_FONT := 30                    # story / info text
const OUTLINE := 8                       # label outline size

# colors (menu.gd)
const DIM_COLOR := Color(0, 0, 0, 0.62)          # darkens what is behind a panel
const BG_COLOR := Color(0.07, 0.08, 0.12)        # screen background when there is no court behind
const LIT_COLOR := Color(1.0, 0.82, 0.25)        # gold: the lit / default choice
const LIT_BORDER := Color(1.0, 1.0, 1.0)
const LIT_TEXT := Color(0.12, 0.1, 0.05)
const OFF_COLOR := Color(0.16, 0.3, 0.6)         # blue: a normal button
const OFF_BORDER := Color(0.6, 0.75, 1.0, 0.8)
const OFF_TEXT := Color.WHITE
const OPT_COLOR := Color(0.2, 0.22, 0.27)        # grey: options, BACK
const OPT_BORDER := Color(0.85, 0.85, 0.9, 0.8)
const OPT_OFF_TEXT := Color(0.65, 0.65, 0.7)     # an option that is off (MUSIC OFF)
const PANEL_COLOR := Color(0.1, 0.12, 0.18, 0.92)
const PANEL_BORDER := Color(0.6, 0.75, 1.0, 0.8)
const TEXT_COLOR := Color.WHITE
const OUTLINE_COLOR := Color(0, 0, 0, 0.85)
const DISABLED_ALPHA := 0.6                      # a button that can't be tapped yet

const KIND_MAIN := "main"                # blue
const KIND_LIT := "lit"                  # gold
const KIND_OPT := "opt"                  # grey

const _FONT_KEYS := ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]

static func style_box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(CORNER)
	return sb

# A full-screen Control for a screen's CanvasLayer (sets the layer). It stops taps from reaching anything below.
# with_bg: an opaque background (screens without a court behind); false = the dim used over the game (pause).
static func screen_root(layer_node: CanvasLayer, with_bg := true) -> Control:
	layer_node.layer = LAYER
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer_node.add_child(root)
	var bg := ColorRect.new()
	bg.color = BG_COLOR if with_bg else DIM_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)
	return root

# A centred column / row that lets taps through to its buttons. Pass full := true to fill the parent (a column
# that centres its content on the screen).
static func vbox(parent: Control, separation := COLUMN_GAP, full := true) -> VBoxContainer:
	var box := VBoxContainer.new()
	if full:
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	return box

static func hbox(parent: Control, separation := BUTTON_GAP) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", separation)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	return row

# A label with menu.gd's outline. parent may be null (add it yourself).
static func label(parent: Control, text: String, size := SUB_FONT, color := TEXT_COLOR) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = OUTLINE
	ls.outline_color = OUTLINE_COLOR
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent != null:
		parent.add_child(l)
	return l

static func title(parent: Control, text: String, color := TEXT_COLOR) -> Label:
	return label(parent, text, TITLE_FONT, color)

static func subtitle(parent: Control, text: String, color := TEXT_COLOR) -> Label:
	return label(parent, text, SUB_FONT, color)

# A big button. kind: KIND_MAIN (blue), KIND_LIT (gold), KIND_OPT (grey). size: Vector2.ZERO = the kind's default
# (BUTTON_SIZE for main/lit, OPT_SIZE for opt); never smaller than MIN_BUTTON. on_tap may be an empty Callable().
static func button(parent: Control, text: String, on_tap: Callable, kind := KIND_MAIN,
		size := Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	var s: Vector2 = size
	if s == Vector2.ZERO:
		s = OPT_SIZE if kind == KIND_OPT else BUTTON_SIZE
	b.custom_minimum_size = Vector2(maxf(s.x, MIN_BUTTON.x), maxf(s.y, MIN_BUTTON.y))
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", OPT_FONT if kind == KIND_OPT else BUTTON_FONT)
	set_kind(b, kind)
	if on_tap.is_valid():
		b.pressed.connect(on_tap)
	if parent != null:
		parent.add_child(b)
	return b

# Restyle a button (e.g. light the chosen one: set_kind(b, KIND_LIT), the others KIND_MAIN).
static func set_kind(b: Button, kind: String) -> void:
	var fill: Color = OFF_COLOR
	var border: Color = OFF_BORDER
	var width: int = BORDER
	var text_col: Color = OFF_TEXT
	if kind == KIND_LIT:
		fill = LIT_COLOR
		border = LIT_BORDER
		width = LIT_BORDER_W
		text_col = LIT_TEXT
	elif kind == KIND_OPT:
		fill = OPT_COLOR
		border = OPT_BORDER
	var sb := style_box(fill, border, width)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("disabled", sb)
	var pressed: Color = fill.lightened(0.2) if kind == KIND_OPT else fill.darkened(0.25)
	b.add_theme_stylebox_override("pressed", style_box(pressed, LIT_BORDER, LIT_BORDER_W if kind == KIND_LIT else 6))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	set_text_color(b, text_col)

static func set_text_color(b: Button, color: Color) -> void:
	for k in _FONT_KEYS:
		b.add_theme_color_override(k, color)

# On/off for taps, with menu.gd's faded look while off (e.g. the first 0.8 s of a panel).
static func set_enabled(b: Button, on: bool) -> void:
	b.disabled = not on
	b.modulate.a = 1.0 if on else DISABLED_ALPHA

# A dark rounded panel with padding. size: Vector2.ZERO = fit the content.
static func panel(parent: Control, size := Vector2.ZERO) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := style_box(PANEL_COLOR, PANEL_BORDER, BORDER)
	sb.set_content_margin_all(PANEL_PAD)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent != null:
		parent.add_child(p)
	return p

# A text box (story lines, info): a panel holding a wrapping, left-aligned label. Returns the Label, so the caller
# sets .text and .visible_characters (typing effect); its panel is label.get_parent().
static func text_box(parent: Control, text: String, size := Vector2(1100, 200), font_size := TEXT_FONT) -> Label:
	var p := panel(parent, size)
	var l := label(p, text, font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return l

# A big horizontal slider (0..1 by default), knob GRABBER_PX wide in gold. on_change(value: float) may be empty.
static func slider(parent: Control, value: float, on_change: Callable, min_v := 0.0, max_v := 1.0,
		step := 0.05) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = SLIDER_SIZE
	s.focus_mode = Control.FOCUS_NONE
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	var track := StyleBoxFlat.new()
	track.bg_color = OPT_COLOR
	track.border_color = OFF_BORDER
	track.set_border_width_all(2)
	track.set_corner_radius_all(int(SLIDER_TRACK / 2.0))
	track.content_margin_top = SLIDER_TRACK / 2.0
	track.content_margin_bottom = SLIDER_TRACK / 2.0
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = OFF_COLOR.lightened(0.15)
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob: Texture2D = _knob_texture(LIT_COLOR)
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	s.add_theme_icon_override("grabber_disabled", _knob_texture(OPT_OFF_TEXT))
	if on_change.is_valid():
		s.value_changed.connect(on_change)
	if parent != null:
		parent.add_child(s)
	return s

# A label + slider row, e.g. "SOUND" and the volume slider. Returns the slider.
static func slider_row(parent: Control, text: String, value: float, on_change: Callable) -> HSlider:
	var row := hbox(parent, BUTTON_GAP)
	var l := label(row, text, OPT_FONT)
	l.custom_minimum_size = Vector2(220, 0)
	return slider(row, value, on_change)

static func _knob_texture(color: Color) -> Texture2D:
	var n: int = GRABBER_PX
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	var r: float = n / 2.0 - 1.0
	for y in n:
		for x in n:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r - 3.0:
				img.set_pixel(x, y, color)
			elif d <= r:
				img.set_pixel(x, y, LIT_BORDER)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)
