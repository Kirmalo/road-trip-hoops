extends Control
# P8-31: the 3-2-1 countdown at the start of every match (owner: "We need a 3-2-1 countdown at the start of a match").
# main.gd adds it to the HUD (screen space, a full-screen Control that takes no taps) and calls start() once, when
# the game is built and no panel waits in front of it; never after a side switch, a timeout or free throws.
# main.gd calls step(delta) from _physics_process, so pausing the game (pause.gd pauses the tree) pauses the count.
# While frozen() is true main.gd holds the game: clocks, players, ball and the human's buttons wait; at GO! play
# starts and GO! stays on screen for GO_TIME while the game runs.
# Placement: the center of the screen, a little low (NUMBER_Y), under the "FIRST TO N" / trip label message (main.gd
# msg_label, -160..-60 from the center) and well under the twist banner (twist_fx.gd, under the top bar), so the
# banner slides in at tip-off as before and nothing overlaps.

const STEPS := ["3", "2", "1"]          # the numbers, one after the other
const STEP_TIME := 0.75                  # seconds each number shows (play is frozen through all of them)
const GO_TEXT := "GO!"
const GO_TIME := 0.5                     # seconds GO! shows; play already runs under it
const NUMBER_SIZE := 132                 # font size of the numbers (the HUD's font, much bigger)
const GO_SIZE := 112                     # font size of GO!
const NUMBER_Y := 40.0                   # screen px below the screen's center (under the match label message)
const POP_TIME := 0.18                   # seconds of the scale-in at each number
const POP_SCALE := 1.9                   # each number starts this big and settles to 1.0 (ease out)
const FADE_TIME := 0.15                  # the last seconds of each number fade out
const GO_GROW := 1.15                    # GO! grows to this while it fades
const NUMBER_COLOR := Color(1.0, 0.92, 0.45)
const GO_COLOR := Color(0.45, 1.0, 0.5)
const OUTLINE_SIZE := 18                 # thick dark outline, readable on any court
const OUTLINE_COLOR := Color(0.03, 0.03, 0.08, 0.95)
const SHADOW_OFFSET := Vector2(5, 6)     # hard drop shadow (pixel look)
const SHADOW_COLOR := Color(0, 0, 0, 0.55)
const TICK_SFX := "countdown"            # assets/sfx/countdown.ogg, at each number
const GO_SFX := "go"                     # assets/sfx/go.ogg, at GO!
const TICK_DB := 0.0
const GO_DB := 0.0
const BOX := Vector2(600, 220)           # the label's box (screen px), centered

var game                                 # main.gd (audio, stats); may be null
var _t := -1.0                           # seconds since start (< 0: not running)
var _shown := -1                         # index of the step on screen (STEPS.size() = GO!)
var _label: Label
var _settings: LabelSettings

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.offset_left = -BOX.x / 2.0
	_label.offset_right = BOX.x / 2.0
	_label.offset_top = NUMBER_Y - BOX.y / 2.0
	_label.offset_bottom = NUMBER_Y + BOX.y / 2.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_settings = LabelSettings.new()
	_settings.font_size = NUMBER_SIZE
	_settings.outline_size = OUTLINE_SIZE
	_settings.outline_color = OUTLINE_COLOR
	_settings.shadow_size = 1
	_settings.shadow_offset = SHADOW_OFFSET
	_settings.shadow_color = SHADOW_COLOR
	_label.label_settings = _settings
	_label.visible = false
	add_child(_label)

# total seconds of the frozen part (3, 2, 1)
static func frozen_time() -> float:
	return STEP_TIME * STEPS.size()

func start() -> void:
	_t = 0.0
	_shown = -1
	_show_step(0)
	if game != null:
		game.stat("countdowns")

# stop at once (game over during the count, e.g. a test that decides the game)
func stop() -> void:
	_t = -1.0
	_label.visible = false

func running() -> bool:
	return _t >= 0.0

# true while play must wait (3, 2, 1)
func frozen() -> bool:
	return _t >= 0.0 and _t < frozen_time()

# what is on screen now: "3", "2", "1", "GO!" or ""
func current_text() -> String:
	return _label.text if running() and _label.visible else ""

func step(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if _t >= frozen_time() + GO_TIME:
		stop()
		return
	var i: int = mini(int(floorf(_t / STEP_TIME)), STEPS.size())
	if i != _shown:
		_show_step(i)
	_animate()

func _show_step(i: int) -> void:
	_shown = i
	var go: bool = i >= STEPS.size()
	_label.text = GO_TEXT if go else str(STEPS[i])
	_settings.font_size = GO_SIZE if go else NUMBER_SIZE
	_label.modulate = GO_COLOR if go else NUMBER_COLOR
	_label.visible = true
	if game != null and game.audio != null:
		if go:
			game.audio.play(GO_SFX, GO_DB, 0.0)
		else:
			game.audio.play(TICK_SFX, TICK_DB, 0.0)
	_animate()

# the pop (scale in, ease out) and the fade at the end of each step
func _animate() -> void:
	var go: bool = _shown >= STEPS.size()
	var start_t: float = STEP_TIME * float(_shown)
	var len_t: float = GO_TIME if go else STEP_TIME
	var age: float = clampf(_t - start_t, 0.0, len_t)
	var k: float = minf(age / POP_TIME, 1.0)
	var sc: float = lerpf(POP_SCALE, 1.0, 1.0 - (1.0 - k) * (1.0 - k))
	var a: float = 1.0
	if go:
		sc *= lerpf(1.0, GO_GROW, age / len_t)
		a = clampf((len_t - age) / maxf(len_t - POP_TIME, 0.01), 0.0, 1.0)
	else:
		a = clampf((len_t - age) / FADE_TIME, 0.0, 1.0)
	_label.pivot_offset = BOX / 2.0
	_label.scale = Vector2(sc, sc)
	_label.modulate.a = a
