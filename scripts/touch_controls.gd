extends Control
# Floating joystick (touch anywhere on the left side) plus two action buttons on the right.

signal a_pressed
signal a_released
signal b_pressed

var joy_index := -1
var joy_center := Vector2.ZERO
var joy_knob := Vector2.ZERO
const JOY_RADIUS := 80.0

var a_index := -1
var b_index := -1
var a_text := "SHOOT"
var b_text := "PASS"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func joystick() -> Vector2:
	if joy_index < 0:
		return Vector2.ZERO
	var v := (joy_knob - joy_center) / JOY_RADIUS
	return v if v.length() > 0.15 else Vector2.ZERO

func a_center() -> Vector2:
	return Vector2(size.x - 120, size.y - 130)

func b_center() -> Vector2:
	return Vector2(size.x - 280, size.y - 90)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(a_center()) < 85.0:
				a_index = event.index
				a_pressed.emit()
			elif event.position.distance_to(b_center()) < 70.0:
				b_index = event.index
				b_pressed.emit()
			elif event.position.x < size.x * 0.5 and joy_index < 0:
				joy_index = event.index
				joy_center = event.position
				joy_knob = event.position
		else:
			if event.index == joy_index:
				joy_index = -1
			if event.index == a_index:
				a_index = -1
				a_released.emit()
			if event.index == b_index:
				b_index = -1
	elif event is InputEventScreenDrag:
		if event.index == joy_index:
			joy_knob = joy_center + (event.position - joy_center).limit_length(JOY_RADIUS)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# joystick
	if joy_index >= 0:
		draw_circle(joy_center, JOY_RADIUS, Color(1, 1, 1, 0.15))
		draw_arc(joy_center, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.5), 3.0)
		draw_circle(joy_knob, 34.0, Color(1, 1, 1, 0.55))
	else:
		var hint := Vector2(150, size.y - 150)
		draw_arc(hint, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.25), 3.0)
		draw_circle(hint, 34.0, Color(1, 1, 1, 0.18))
	# buttons
	_button(a_center(), 75.0, a_text, Color(0.95, 0.45, 0.1, 0.75 if a_index < 0 else 0.95))
	_button(b_center(), 58.0, b_text, Color(0.2, 0.5, 0.95, 0.75 if b_index < 0 else 0.95))

func _button(c: Vector2, r: float, text: String, col: Color) -> void:
	draw_circle(c, r, col)
	draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.8), 3.0)
	var font := ThemeDB.fallback_font
	var fs := 22
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, c + Vector2(-w / 2, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
