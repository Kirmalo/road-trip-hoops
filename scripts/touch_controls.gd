extends Control
# Floating joystick (touch anywhere on the left side) plus two action buttons on the right.
# Left-handed (Difficulty.is_left_handed()): the same layout mirrored, joystick on the right half, buttons bottom left.

const Difficulty = preload("res://scripts/difficulty.gd")   # is_left_handed() (P7-01)

signal a_pressed
signal a_released
signal b_pressed

var joy_index := -1
var joy_center := Vector2.ZERO
var joy_knob := Vector2.ZERO
const JOY_RADIUS := 80.0
const TURBO_PULL := 1.5            # sprint only when the finger is this many joystick radii from the center (past the ring)
var joy_finger := Vector2.ZERO     # where the joystick finger really is (the knob stops at the ring)

var a_index := -1
var b_index := -1
var a_text := "SHOOT"
var b_text := "PASS"
var a_glow := false                # set by main.gd: STEAL lights up while a poke would be well timed
var a_block := false               # set by main.gd: the orange button says BLOCK (it jumps); drawn with an up arrow
var b_glow := false                # set by main.gd: CALL lights up while the call is live (the teammate heard it)
var b_dim := false                 # set by main.gd: CALL is cooling down after a call
const CALL_LIT_COLOR := Color(0.45, 0.8, 1.0)
const BLOCK_COLOR := Color(0.9, 0.3, 0.12)   # BLOCK is a deeper orange than STEAL, so the switch is noticed
var _glow_t := 0.0
const JOY_HINT_POS := Vector2(150, -150)   # the idle joystick hint: x from the left, y from the bottom (right-handed)
var left_handed := false           # mirrored layout: joystick on the right half, A/B at the bottom left

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_handed = Difficulty.is_left_handed()

# a right-handed layout point, mirrored across the screen when left-handed
func mirror_x(p: Vector2) -> Vector2:
	return Vector2(size.x - p.x, p.y) if left_handed else p

# true where a touch starts the joystick: the left half (right-handed) or the right half (left-handed)
func on_joy_side(pos: Vector2) -> bool:
	return pos.x >= size.x * 0.5 if left_handed else pos.x < size.x * 0.5

func joystick() -> Vector2:
	if joy_index < 0:
		return Vector2.ZERO
	var v := (joy_knob - joy_center) / JOY_RADIUS
	return v if v.length() > 0.15 else Vector2.ZERO

# true while the joystick finger is pulled well past the ring: that's the sprint (turbo) gesture
func turbo_pull() -> bool:
	return joy_index >= 0 and joy_finger.distance_to(joy_center) >= JOY_RADIUS * TURBO_PULL

func a_center() -> Vector2:
	return mirror_x(Vector2(size.x - 120, size.y - 130))

func b_center() -> Vector2:
	return mirror_x(Vector2(size.x - 280, size.y - 90))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(a_center()) < 85.0:
				a_index = event.index
				a_pressed.emit()
			elif event.position.distance_to(b_center()) < 70.0:
				b_index = event.index
				b_pressed.emit()
			elif on_joy_side(event.position) and joy_index < 0:
				joy_index = event.index
				joy_center = event.position
				joy_knob = event.position
				joy_finger = event.position
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
			joy_finger = event.position
			joy_knob = joy_center + (event.position - joy_center).limit_length(JOY_RADIUS)

func _process(delta: float) -> void:
	_glow_t = _glow_t + delta if (a_glow or b_glow) else 0.0
	queue_redraw()

func _draw() -> void:
	# joystick
	if joy_index >= 0:
		draw_circle(joy_center, JOY_RADIUS, Color(1, 1, 1, 0.15))
		draw_arc(joy_center, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.5), 3.0)
		# faint outer ring: pull your thumb past it to sprint; the knob turns orange while sprinting
		var sprint := turbo_pull()
		draw_arc(joy_center, JOY_RADIUS * TURBO_PULL, 0, TAU, 64, Color(1.0, 0.6, 0.2, 0.55 if sprint else 0.22), 2.0)
		draw_circle(joy_knob, 34.0, Color(1.0, 0.6, 0.2, 0.8) if sprint else Color(1, 1, 1, 0.55))
	else:
		var hint := mirror_x(Vector2(JOY_HINT_POS.x, size.y + JOY_HINT_POS.y))
		draw_arc(hint, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.25), 3.0)
		draw_circle(hint, 34.0, Color(1, 1, 1, 0.18))
	# buttons
	if a_glow:
		# lit STEAL: bright yellow-white button and a thick pulsing ring around it
		var pulse := 0.5 + 0.5 * sin(_glow_t * 30.0)
		draw_arc(a_center(), 86.0 + 4.0 * pulse, 0, TAU, 48, Color(1.0, 0.95, 0.4, 0.9), 8.0)
		_button(a_center(), 75.0, a_text, Color(1.0, 0.85, 0.3, 1.0))
	elif a_block:
		var col := BLOCK_COLOR
		col.a = 0.85 if a_index < 0 else 1.0
		_button(a_center(), 75.0, a_text, col)
		# up arrow over the label: this press jumps
		var c := a_center() + Vector2(0, -36)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-16, 12), c + Vector2(16, 12), c + Vector2(0, -6)]), Color.WHITE)
	else:
		_button(a_center(), 75.0, a_text, Color(0.95, 0.45, 0.1, 0.75 if a_index < 0 else 0.95))
	if b_glow:
		# lit CALL: light blue button and a pulsing ring, the teammate with the ball heard you
		var bp := 0.5 + 0.5 * sin(_glow_t * 18.0)
		draw_arc(b_center(), 68.0 + 4.0 * bp, 0, TAU, 48, Color(0.75, 0.92, 1.0, 0.9), 7.0)
		_button(b_center(), 58.0, b_text, CALL_LIT_COLOR)
	else:
		_button(b_center(), 58.0, b_text, Color(0.2, 0.5, 0.95, (0.4 if b_dim else 0.75) if b_index < 0 else 0.95))

func _button(c: Vector2, r: float, text: String, col: Color) -> void:
	draw_circle(c, r, col)
	draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.8), 3.0)
	var font := ThemeDB.fallback_font
	var fs := 22
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, c + Vector2(-w / 2, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
