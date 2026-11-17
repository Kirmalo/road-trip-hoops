extends CanvasLayer
# Title screen (P5-06): one script for three Flow screens ("title", "settings", "crew"), built in code with ui_kit.gd.
#   title     the game name, the Cornfield Kings and their van The Biscuit on the road, and four buttons:
#             ROAD TRIP -> CONTINUE / NEW TRIP (NEW TRIP over a saved trip asks to confirm) -> EASY / NORMAL / HARD
#             QUICK GAME -> today's game (its start panel picks the level and court, as before)
#             SETTINGS, CREW & CREDITS (their own Flow screens)
#   settings  MUSIC on/off, FULL SCREEN on/off (P6-T2), SOUND volume, the default LEVEL (Quick Game and new trips)
#   crew      your crew (from the trip save if there is one) and the art and music credits, in a scrolling list
# The Road Trip sub-panels swap in place (no reload); every other move is Flow.go(). Each panel ignores taps for
# PANEL_ARM s, so a quick double tap can't fall through onto the next panel's button in the same spot.
# trip.gd / save.gd (P5-05) and audio.set_sfx_volume (P5-07) are called only if they exist, so this runs alone:
# without save.gd CONTINUE is off; without trip.gd NEW TRIP goes to the flow's "not built yet" map panel.
# FULL SCREEN (P6-T2): Difficulty.set_fullscreen() inside the tap (a browser needs the gesture); the label follows the
# real window mode every frame (the browser's Esc / back gesture). The first tap of a run puts a saved ON back
# (Difficulty.restore_fullscreen(), from _input here and in pause.gd).
# Desktop testing: Escape = BACK. Test: -- --titletest walks every screen and button (screenshots with xvfb).

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const MenuScript = preload("res://scripts/menu.gd")
const Difficulty = preload("res://scripts/difficulty.gd")
const Cities = preload("res://scripts/cities.gd")

const TRIP_PATH := "res://scripts/trip.gd"     # P5-05: new_trip(level), continue_trip(), set_level(level) optional
const SAVE_PATH := "res://scripts/save.gd"     # P5-05: exists()
const TRIP_FILE := "user://trip.json"          # the trip save (board "Save format"), read for the summary and crew
const SFX_KEY := "sfx_volume"                  # settings.cfg key of the sound volume (P5-07 reads it at launch)
const SFX_DEFAULT := 1.0
const SFX_SAVE_DELAY := 0.4                    # s after the last slider move before the volume is saved and previewed
const SFX_PREVIEW := "bounce"                  # sound played after a volume change

const PANEL_ARM := 0.3                         # s a new panel ignores taps
const PANEL_TOP := 250.0                       # px: the title's buttons start under the name
const PANEL_GAP := 18                          # px between the rows of a title panel
const NAME_FONT := 96                          # "ROAD TRIP HOOPS"
const NAME_COLOR := Color(1.0, 0.82, 0.25)     # gold, like the lit button
const CREW_FONT := 36                          # "THE CORNFIELD KINGS"
const VAN_FONT := 24                           # "on the road in The Biscuit"
const MAIN_BTN := Vector2(400, 130)            # ROAD TRIP / QUICK GAME
const SIDE_BTN := Vector2(400, 110)            # SETTINGS / CREW & CREDITS
const LEVEL_BTN := Vector2(240, 110)           # EASY / NORMAL / HARD in Settings
const BACK_POS := Vector2(24, 20)              # BACK, top-left on Settings and Crew
const ROW_LABEL_W := 220                       # left column of the Settings rows
const STUB_COLOR := Color(0.65, 0.65, 0.7)
const SCROLL_SIZE := Vector2(1180, 560)        # the crew & credits list
const SCROLL_BAR_W := 36                       # wide enough to drag with a thumb
const SECTION_FONT := 40
const ENTRY_FONT := 28
const DETAIL_FONT := 22
const STAT_W := 130                            # px per rating column in the crew list
const STAT_NAMES := [["speed", "SPD"], ["shooting", "SHT"], ["finishing", "FIN"], ["defense", "DEF"],
		["stamina", "STA"]]

# title art (drawn, no image files): sunset sky, a cornfield, the road, the van
const SKY_TOP := Color(0.10, 0.12, 0.30)
const SKY_LOW := Color(0.95, 0.52, 0.30)
const SKY_BANDS := 12                          # flat colour bands (pixel look)
const HORIZON_Y := 560.0
const SUN_POS := Vector2(1000, 560)
const SUN_R := 90.0
const SUN_COLOR := Color(1.0, 0.78, 0.35)
const CORN_COLOR := Color(0.55, 0.50, 0.12)
const CORN_TOP := Color(0.90, 0.78, 0.25)
const ROAD_Y := 600.0
const ROAD_COLOR := Color(0.16, 0.16, 0.18)
const VERGE_COLOR := Color(0.30, 0.42, 0.16)
const LINE_COLOR := Color(1.0, 0.82, 0.25)
const DASH_LEN := 60.0
const DASH_GAP := 50.0
const ROAD_SPEED := 120.0                      # px/s the road dashes slide (the van drives)
const VAN_POS := Vector2(60, 578)              # top-left of the van body
const VAN_SIZE := Vector2(230, 92)
const VAN_COLOR := Color(0.88, 0.72, 0.46)     # biscuit
const VAN_TRIM := Color(0.16, 0.30, 0.60)      # your crew's blue
const VAN_GLASS := Color(0.55, 0.75, 0.90)
const VAN_BOB := 2.0                           # px the van bounces
const VAN_BOB_HZ := 3.0
const BALL_COLOR := Color(0.92, 0.45, 0.12)
const SIGN_POS := Vector2(1080, 470)

# Credits (kept here as a const list, board P5-06; copy new rows from CREDITS.md): [what, title, author, license, source]
const CREDITS_LIST := [
	["Players, courts, ball (pixel art)", "Original art made for this project", "Road Trip Hoops project",
		"Original", "tools/art/make_players.py, tools/art/make_courts.py"],
	["Fallback sprites", "Sports Pack", "Kenney", "CC0 1.0", "kenney.nl"],
	["Menu music", "Stage 1 (4 Chiptunes, Adventure)", "Juhani Junkala (SubspaceAudio)", "CC0",
		"opengameart.org/content/4-chiptunes-adventure"],
	["Gym music", "Stage 2 (4 Chiptunes, Adventure)", "Juhani Junkala (SubspaceAudio)", "CC0",
		"opengameart.org/content/4-chiptunes-adventure"],
	["Blacktop music", "Level 1 (5 Chiptunes, Action)", "Juhani Junkala (SubspaceAudio)", "CC0",
		"opengameart.org/content/5-chiptunes-action"],
	["Hometown music", "Medieval: Minstrel Dance", "RandomMind", "CC0",
		"opengameart.org/content/chiptune-medieval-minstrel-dance"],
	["Chicago music", "8-Bit Bluesy Battle Theme", "emanresU", "CC0",
		"opengameart.org/content/8-bit-bluesy-battle-theme"],
	["New York music", "NES chiptune \"Slam-Funk\"", "Haley Halcyon", "CC-BY 4.0",
		"opengameart.org/content/nes-chiptune-slam-funk"],
	["Crowd", "Free Crowd Cheering Sounds", "Gregor Quendel (www.gregorquendel.com)", "CC-BY 4.0",
		"opengameart.org/content/free-crowd-cheering-sounds"],
	["Rim", "Metal Impact Sounds", "BMacZero", "CC0", "opengameart.org/content/metal-impact-sounds"],
	["Dunk", "100 CC0 metal and wood SFX", "rubberduck", "CC0",
		"opengameart.org/content/100-cc0-metal-and-wood-sfx"],
	["Block", "10 Impact/Shield Blocks", "StarNinjas", "CC0", "opengameart.org/content/10-impactshield-blocks"],
	["On fire", "Catching fire", "themightyglider", "CC0", "opengameart.org/content/catching-fire"],
	["Swish, bounce, whistle", "Synthesized sounds made for this project", "Road Trip Hoops project", "Original",
		"tools/make_swish.py, tools/make_bounce.py, tools/make_whistle.py"],
	["Game engine", "Godot Engine", "Juan Linietsky, Ariel Manzur and contributors", "MIT", "godotengine.org"],
]

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd
var music := "menu"          # Flow plays it after _ready()

var _root: Control
var _content: Control        # the swappable part of the title (main grid or a Road Trip panel)
var _panel := "main"         # title sub-panel: "main", "trip", "confirm", "level"
var _arm_t := 0.0
var _buttons: Array = []     # the buttons that wait out PANEL_ARM
var _busy := false           # a Flow.go() is on its way: ignore further taps
var _music_btn: Button
var _fs_btn: Button          # FULL SCREEN: ON / OFF (Settings)
var _fs_shown := false       # the real state the label shows
var _level_btns: Array = []
var _sfx_slider: HSlider
var _sfx_dirty_t := -1.0
var _scroll: ScrollContainer
var _art: Control

# --titletest driver (survives the reloads between screens)
static var _test_step := 0
var _test_on := false
var _test_t := 0
var _test_fs := false        # the saved FULL SCREEN before the test pressed it

func _ready() -> void:
	MenuScript.start_done = false   # a Quick Game from here shows its start panel (level, court) again
	_test_on = OS.get_cmdline_user_args().has("--titletest")
	_root = UI.screen_root(self)
	match str(Flow.screen):
		"settings":
			_build_settings()
		"crew":
			_build_crew()
		_:
			_build_title()
	_stat("title_screen_" + str(Flow.screen))

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			for b in _buttons:
				if is_instance_valid(b):
					UI.set_enabled(b, not b.has_meta("off"))
	if _sfx_dirty_t > 0.0:
		_sfx_dirty_t -= delta
		if _sfx_dirty_t <= 0.0:
			_save_sfx()
	if _art != null:
		_art.queue_redraw()
	if _fs_btn != null and Difficulty.is_fullscreen() != _fs_shown:
		_refresh_settings()   # left (or entered) full screen through the browser
	if _test_on:
		_test_tick()

# the first tap of the run puts a saved FULL SCREEN back (a browser only allows it during a tap)
func _input(event: InputEvent) -> void:
	if Difficulty.is_release_tap(event):
		Difficulty.restore_fullscreen()

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or k.keycode != KEY_ESCAPE:
		return
	if str(Flow.screen) != "title":
		_go("title")
	elif _panel != "main":
		_show_panel("main")

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

# ---------------- title ----------------

func _build_title() -> void:
	_art = TitleArt.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_art)
	var head := UI.vbox(_root, 4, false)
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	head.offset_top = 24
	head.offset_bottom = 210
	UI.label(head, "ROAD TRIP HOOPS", NAME_FONT, NAME_COLOR)
	UI.label(head, "THE " + Cities.CREW_NAME, CREW_FONT)
	UI.label(head, "on the road in " + Cities.VAN_NAME.capitalize(), VAN_FONT)
	_show_panel("main")

func _show_panel(which: String) -> void:
	_panel = which
	if _content != null:
		_content.queue_free()
	_buttons.clear()
	var box := UI.vbox(_root, PANEL_GAP)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.offset_top = PANEL_TOP
	_content = box
	match which:
		"trip":
			UI.subtitle(box, _trip_summary() if _has_trip() else "No trip saved yet. Start one and hit the road!")
			var row := UI.hbox(box)
			# a finished trip has nothing to continue: NEW TRIP is the gold button then
			var can_go: bool = _has_trip() and not _trip_finished()
			var cont: Button = _btn(row, "CONTINUE", _on_continue, UI.KIND_LIT if can_go else UI.KIND_MAIN,
					MAIN_BTN)
			if not can_go:
				cont.set_meta("off", true)
			_btn(row, "NEW TRIP", _on_new_trip, UI.KIND_MAIN if can_go else UI.KIND_LIT, MAIN_BTN)
			_btn(UI.hbox(box), "BACK", _show_panel.bind("main"), UI.KIND_OPT, UI.SMALL_SIZE)
		"confirm":
			UI.subtitle(box, "Start a new trip? Your saved trip will be lost:")
			UI.subtitle(box, _trip_summary(), NAME_COLOR)
			var row2 := UI.hbox(box)
			_btn(row2, "START OVER", _show_panel.bind("level"), UI.KIND_MAIN, MAIN_BTN)
			_btn(row2, "KEEP MY TRIP", _show_panel.bind("trip"), UI.KIND_LIT, MAIN_BTN)
		"level":
			UI.subtitle(box, "Pick your level for this trip (change it any time in Settings)")
			var row3 := UI.hbox(box)
			for lv in [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD]:
				_btn(row3, String(Difficulty.NAMES[lv]).to_upper(), _on_trip_level.bind(lv),
						UI.KIND_LIT if lv == Difficulty.level else UI.KIND_MAIN)
			_btn(UI.hbox(box), "BACK", _show_panel.bind("trip"), UI.KIND_OPT, UI.SMALL_SIZE)
		_:
			var r1 := UI.hbox(box)
			_btn(r1, "ROAD TRIP", _show_panel.bind("trip"), UI.KIND_LIT, MAIN_BTN)
			_btn(r1, "QUICK GAME", _on_quick_game, UI.KIND_MAIN, MAIN_BTN)
			var r2 := UI.hbox(box)
			_btn(r2, "SETTINGS", _go.bind("settings"), UI.KIND_OPT, SIDE_BTN)
			_btn(r2, "CREW & CREDITS", _go.bind("crew"), UI.KIND_OPT, SIDE_BTN)
	_arm(PANEL_ARM)

# a button that waits out the panel's arm time and ignores taps once a screen change is on its way
func _btn(parent: Control, text: String, on_tap: Callable, kind: String, size := Vector2.ZERO) -> Button:
	var b: Button = UI.button(parent, text, _tap.bind(on_tap), kind, size)
	_buttons.append(b)
	return b

func _tap(on_tap: Callable) -> void:
	if _busy or _arm_t > 0.0:
		return
	if audio != null:
		audio.play("bounce", -8.0)
	on_tap.call()

func _arm(t: float) -> void:
	_arm_t = t
	for b in _buttons:
		UI.set_enabled(b, false)

func _go(to: String, to_args := {}) -> void:
	if _busy:
		return
	_busy = true
	Flow.go(to, to_args)

func _on_quick_game() -> void:
	_stat("title_quick_game")
	_go(Flow.GAME)

func _on_continue() -> void:
	if not _has_trip() or _trip_finished():
		return
	_stat("title_continue")
	var trip: GDScript = _script(TRIP_PATH)
	var before: String = str(Flow.screen)
	var loaded: bool = false
	if trip != null and trip.has_method("continue_trip"):
		loaded = bool(trip.call("continue_trip"))
	if not _busy and str(Flow.screen) == before:
		# continue where the trip left off (map, points, recruit or bracket); a finished trip stays on the title
		var where: String = "map"
		if loaded and trip.has_method("resume_screen"):
			where = str(trip.call("resume_screen"))
		if where == "title":
			_show_panel("trip")
		else:
			_go(where)

func _on_new_trip() -> void:
	_show_panel("confirm" if _has_trip() else "level")

func _on_trip_level(lv: int) -> void:
	_stat("title_new_trip_" + String(Difficulty.NAMES[lv]))
	var trip: GDScript = _script(TRIP_PATH)
	if trip == null or not trip.has_method("new_trip"):
		_go("map")   # trip.gd isn't built yet: the flow's "not built yet" panel
		return
	var before: String = str(Flow.screen)
	trip.call("new_trip", _level_arg(trip, "new_trip", lv))
	if not _busy and str(Flow.screen) == before:
		_go("story", {"scene": "trip_start", "then": "map"})   # board flow: trip start story, then the map

# ---------------- settings ----------------

func _build_settings() -> void:
	_back_button()
	var box := UI.vbox(_root)
	box.offset_top = 20
	UI.title(box, "SETTINGS")
	var r1 := _row(box, "MUSIC")
	_music_btn = UI.button(r1, "", _tap.bind(_toggle_music), UI.KIND_OPT)
	_buttons.append(_music_btn)
	var r2 := _row(box, "SCREEN")
	_fs_btn = UI.button(r2, "", _tap.bind(_toggle_fullscreen), UI.KIND_OPT)
	_buttons.append(_fs_btn)
	_sfx_slider = UI.slider_row(box, "SOUND", _saved_sfx(), _on_sfx)
	var r3 := _row(box, "LEVEL")
	for lv in [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD]:
		var b: Button = UI.button(r3, String(Difficulty.NAMES[lv]).to_upper(), _tap.bind(_pick_level.bind(lv)),
				UI.KIND_MAIN, LEVEL_BTN)
		_level_btns.append(b)
		_buttons.append(b)
	UI.label(box, "LEVEL is for Quick Game and new trips" + (", and your saved trip" if _has_trip() else ""),
			UI.SUB_FONT, STUB_COLOR)
	_refresh_settings()
	_arm(PANEL_ARM)

func _row(parent: Control, text: String) -> HBoxContainer:
	var row := UI.hbox(parent)
	var l := UI.label(row, text, UI.OPT_FONT)
	l.custom_minimum_size = Vector2(ROW_LABEL_W, 0)
	return row

func _refresh_settings() -> void:
	_music_btn.text = "ON" if MenuScript.music_on else "OFF"
	UI.set_text_color(_music_btn, UI.OFF_TEXT if MenuScript.music_on else UI.OPT_OFF_TEXT)
	_fs_shown = Difficulty.is_fullscreen()
	_fs_btn.text = "FULL SCREEN: ON" if _fs_shown else "FULL SCREEN: OFF"
	UI.set_text_color(_fs_btn, UI.OFF_TEXT if _fs_shown else UI.OPT_OFF_TEXT)
	for i in _level_btns.size():
		UI.set_kind(_level_btns[i], UI.KIND_LIT if i == Difficulty.level else UI.KIND_MAIN)

func _toggle_music() -> void:
	MenuScript.set_music(not MenuScript.music_on)
	if audio != null:
		audio.set_music_on(MenuScript.music_on)
	_stat("title_music_" + ("on" if MenuScript.music_on else "off"))
	_refresh_settings()

# switches inside this tap (the browser's user gesture) and saves the choice; on the web the window mode changes a
# moment later, and _process updates the label then
func _toggle_fullscreen() -> void:
	var on: bool = not Difficulty.is_fullscreen()
	Difficulty.set_fullscreen(on)
	_stat("title_fullscreen_" + ("on" if on else "off"))
	_refresh_settings()

func _pick_level(lv: int) -> void:
	Difficulty.level = lv
	Difficulty.save()
	var trip: GDScript = _script(TRIP_PATH)
	if _has_trip() and trip != null and trip.has_method("set_level"):
		trip.call("set_level", _level_arg(trip, "set_level", lv))   # owner Q4: the trip level changes in Settings
	_stat("title_level_" + Difficulty.level_name())
	_refresh_settings()

static func _saved_sfx() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(Difficulty.SAVE_PATH) != OK:
		return SFX_DEFAULT
	return clampf(float(cfg.get_value(Difficulty.SAVE_SECTION, SFX_KEY, SFX_DEFAULT)), 0.0, 1.0)

func _on_sfx(v: float) -> void:
	if audio != null and audio.has_method("set_sfx_volume"):
		audio.call("set_sfx_volume", v)   # P5-07
	_sfx_dirty_t = SFX_SAVE_DELAY

func _save_sfx() -> void:
	_sfx_dirty_t = -1.0
	MenuScript.save_setting(SFX_KEY, _sfx_slider.value)
	_stat("title_sfx_saved")
	if audio != null:
		audio.play(SFX_PREVIEW)

func _back_button() -> void:
	var b: Button = UI.button(_root, "BACK", _tap.bind(_go.bind("title")), UI.KIND_OPT, UI.SMALL_SIZE)
	b.position = BACK_POS
	_buttons.append(b)

func _exit_tree() -> void:
	if _sfx_dirty_t > 0.0 and _sfx_slider != null:
		_save_sfx()   # leaving right after a slider move still keeps it

# ---------------- crew & credits ----------------

func _build_crew() -> void:
	_back_button()
	var t := UI.title(_root, "CREW & CREDITS")
	t.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	t.offset_top = 30
	t.offset_bottom = 130
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2((1280.0 - SCROLL_SIZE.x) / 2.0, 145)
	_scroll.size = SCROLL_SIZE
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(SCROLL_BAR_W, 0)
	var track := UI.style_box(UI.OPT_COLOR, UI.OPT_BORDER, 2)
	var grab := UI.style_box(UI.LIT_COLOR, UI.LIT_BORDER, 2)
	bar.add_theme_stylebox_override("scroll", track)
	for k in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(k, grab)
	_root.add_child(_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(SCROLL_SIZE.x - SCROLL_BAR_W - 16, 0)
	list.add_theme_constant_override("separation", 10)
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(list)
	_crew_section(list)
	_spacer(list, 24)
	_section(list, "CREDITS")
	for row in CREDITS_LIST:
		var e: Array = row
		_left(list, str(e[0]).to_upper(), ENTRY_FONT, NAME_COLOR)
		_left(list, "%s  -  %s  (%s)" % [e[1], e[2], e[3]], DETAIL_FONT)
		_left(list, str(e[4]), DETAIL_FONT, STUB_COLOR)
		_spacer(list, 6)
	_left(list, "Only CC0 and CC-BY assets are used. The CC-BY crowd sound and New York music need the credit above.",
			DETAIL_FONT, STUB_COLOR)
	_left(list, "Full list: CREDITS.md in the game folder.", DETAIL_FONT, STUB_COLOR)
	_spacer(list, 20)
	_arm(PANEL_ARM)

func _crew_section(list: Control) -> void:
	_section(list, "THE " + Cities.CREW_NAME)
	var save: Dictionary = _read_save()
	if save.is_empty():
		_left(list, "Van: %s.  No trip yet: tap ROAD TRIP on the title to start one." % Cities.VAN_NAME.capitalize(),
				DETAIL_FONT)
	else:
		var rec: Dictionary = save.get("record", {}) if save.get("record", {}) is Dictionary else {}
		_left(list, "Van: %s.   Record %d-%d.   %s." % [Cities.VAN_NAME.capitalize(), int(rec.get("wins", 0)),
				int(rec.get("losses", 0)), _trip_summary()], DETAIL_FONT)
	var roster: Array = []
	var starters: Array = []
	if save.get("roster", null) is Array:
		roster = save["roster"]
	if save.get("starters", null) is Array:
		starters = save["starters"]
	if roster.is_empty():
		for id in Cities.START_CREW:
			roster.append({"id": id, "ratings": Cities.player(id).get("ratings", {})})
		starters = Cities.START_CREW.duplicate()
	for entry in roster:
		if not (entry is Dictionary):
			continue
		var id: String = str(entry.get("id", ""))
		var p: Dictionary = Cities.player(id)
		var r = entry.get("ratings", {})
		var ratings: Dictionary = r if r is Dictionary else {}
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)
		var who: String = "#%s %s" % [str(p.get("number", "")), str(p.get("full", id))]
		var nl := _left(row, who + ("  *" if starters.has(id) else ""), ENTRY_FONT)
		nl.custom_minimum_size = Vector2(400, 0)
		var role := _left(row, str(p.get("role", "")), DETAIL_FONT, STUB_COLOR)
		role.custom_minimum_size = Vector2(180, 0)
		for s in STAT_NAMES:
			var sl := _left(row, "%s %d" % [s[1], int(ratings.get(s[0], 50))], DETAIL_FONT)
			sl.custom_minimum_size = Vector2(STAT_W - 30, 0)
	_left(list, "* = starter", DETAIL_FONT, STUB_COLOR)

func _section(list: Control, text: String) -> void:
	_left(list, text, SECTION_FONT, UI.OFF_BORDER)

func _left(parent: Control, text: String, size: int, color := UI.TEXT_COLOR) -> Label:
	var l := UI.label(parent, text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if parent is VBoxContainer else TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL if parent is VBoxContainer else Control.SIZE_FILL
	return l

func _spacer(list: Control, h: int) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(c)

# ---------------- trip.gd / save.gd (P5-05), guarded ----------------

static func _script(path: String) -> GDScript:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as GDScript

static func _has_trip() -> bool:
	var t: GDScript = _script(TRIP_PATH)
	if t != null and t.has_method("has_save"):
		return bool(t.call("has_save"))
	var s: GDScript = _script(SAVE_PATH)
	if s != null and s.has_method("exists"):
		return bool(s.call("exists"))
	return false

static func _trip_finished() -> bool:
	return _has_trip() and str(_read_save().get("phase", "")) == "done"

# the trip save as a Dictionary ({} = none); read only when save.gd says there is a trip
static func _read_save() -> Dictionary:
	if not _has_trip() or not FileAccess.file_exists(TRIP_FILE):
		return {}
	var f := FileAccess.open(TRIP_FILE, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}

# "CHICAGO, GAME 2 - NORMAL" from the save
static func _trip_summary() -> String:
	var s: Dictionary = _read_save()
	if s.is_empty():
		return "Saved trip"
	var city: String = str(Cities.city(str(s.get("city", ""))).get("name", str(s.get("city", "")).to_upper()))
	var rec: Dictionary = s.get("record", {}) if s.get("record", {}) is Dictionary else {}
	if str(s.get("phase", "")) == "done":
		return "TRIP COMPLETE - CHAMPIONS!  %d-%d  -  %s  -  start a NEW TRIP to go again" % [int(rec.get("wins", 0)),
				int(rec.get("losses", 0)), str(s.get("level", "normal")).to_upper()]
	return "%s, GAME %d  -  %d-%d  -  %s" % [city, int(s.get("game", 1)), int(rec.get("wins", 0)),
			int(rec.get("losses", 0)), str(s.get("level", "normal")).to_upper()]

# trip.gd takes the level as a String ("normal") if its parameter is typed so, else the Difficulty int
static func _level_arg(s: GDScript, fn: String, lv: int):
	for m in s.get_script_method_list():
		if str(m.get("name", "")) == fn:
			var a: Array = m.get("args", [])
			if a.size() > 0 and int(a[0].get("type", TYPE_NIL)) == TYPE_STRING:
				return String(Difficulty.NAMES[lv])
	return lv

# ---------------- trip test (P5-15) ----------------

# The default choice: continue a saved trip, else a new trip on the remembered level; settings/crew go back.
func auto_step() -> bool:
	if _busy:
		return false
	if str(Flow.screen) != "title":
		_go("title")
		return true
	_arm_t = 0.0
	if _has_trip():
		_on_continue()
	else:
		_on_trip_level(Difficulty.level)
	return true

# ---------------- -- --titletest: taps every screen's buttons (screenshots with xvfb) ----------------

const TEST_WAIT := 30   # frames between test steps

func _test_tick() -> void:
	_test_t += 1
	if _test_t < TEST_WAIT or _busy:
		return
	_test_t = 0
	var scr: String = str(Flow.screen)
	_test_step += 1
	var s: int = _test_step
	print("TITLE TEST step %d on %s/%s" % [s, scr, _panel])
	match s:
		1:
			_shot("title")
			_press("ROAD TRIP")
		2:
			_shot("title_trip")
			_press("NEW TRIP")
		3:
			_shot("title_" + _panel)
			if _panel == "confirm":
				_press("KEEP MY TRIP")
			else:
				_press("BACK")
		4:
			_press("BACK")
		5:
			_press("SETTINGS")
		6:
			_shot("settings")
			_press("ON" if MenuScript.music_on else "OFF")
		7:
			print("TITLE TEST music_on=%s" % MenuScript.music_on)
			_press("ON" if MenuScript.music_on else "OFF")   # back to how it was
			_test_fs = Difficulty.fullscreen_saved()
			_press(_fs_btn.text)                              # FULL SCREEN (headless: no window, stays OFF)
			var keep: float = _sfx_slider.value
			_sfx_slider.value = 0.5
			_sfx_slider.value = keep
		8:
			print("TITLE TEST music_on=%s sfx=%.2f level=%s fullscreen=%s (%s, saved %s)" % [MenuScript.music_on,
					_sfx_slider.value, Difficulty.level_name(), Difficulty.is_fullscreen(), _fs_btn.text,
					Difficulty.fullscreen_saved()])
			Difficulty.set_fullscreen(_test_fs)   # back to how it was
			_press(Difficulty.level_name().to_upper())
			_press("BACK")
		9:
			_press("CREW & CREDITS")
		10:
			_shot("crew")
			_scroll.scroll_vertical = 100000
		11:
			_shot("crew_end")
			print("TITLE TEST crew list scrolled to %d" % _scroll.scroll_vertical)
			_press("BACK")
		12:
			_test_quick_game(get_tree())
			_press("QUICK GAME")

func _press(text: String) -> void:
	for b in _buttons:
		if is_instance_valid(b) and b.text == text and not b.disabled:
			b.emit_signal("pressed")
			return
	push_error("TITLE TEST: no button '%s'" % text)

static func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tree := Engine.get_main_loop() as SceneTree
	var img: Image = tree.root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("/tmp/hoops_%s.png" % name)

# after QUICK GAME: the start panel (with its TITLE button) is up, then quit
static func _test_quick_game(tree: SceneTree) -> void:
	tree.create_timer(1.5).timeout.connect(func():
		print("TITLE TEST quick game: screen=%s start panel=%s" % [str(Flow.screen), not MenuScript.start_done])
		_shot("quick_start")
		print("TITLE TEST DONE")
		tree.quit())


# The title art: sunset sky in flat bands, sun, cornfield, the road with sliding dashes, the van with a ball on the
# roof and its name on the side, and a road sign. Drawn every frame (the road moves, the van bobs).
class TitleArt extends Control:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var band_h: float = HORIZON_Y / float(SKY_BANDS)
		for i in SKY_BANDS:
			draw_rect(Rect2(0, i * band_h, w, band_h + 1.0), SKY_TOP.lerp(SKY_LOW, float(i) / float(SKY_BANDS - 1)))
		draw_circle(SUN_POS, SUN_R, SUN_COLOR)
		draw_rect(Rect2(0, HORIZON_Y, w, h - HORIZON_Y), VERGE_COLOR)
		# cornfield: rows of stalks on the horizon
		var x := 0.0
		var k := 0
		while x < w:
			var sh: float = 22.0 + float((k * 7) % 5) * 4.0
			draw_rect(Rect2(x, HORIZON_Y - sh, 6, sh + 4), CORN_COLOR)
			draw_rect(Rect2(x - 2, HORIZON_Y - sh, 10, 6), CORN_TOP)
			x += 14.0
			k += 1
		# road
		draw_rect(Rect2(0, ROAD_Y, w, h - ROAD_Y), ROAD_COLOR)
		draw_rect(Rect2(0, ROAD_Y, w, 4), Color(0.4, 0.4, 0.42))
		var period: float = DASH_LEN + DASH_GAP
		var shift: float = fmod(_t * ROAD_SPEED, period)
		var dx: float = -shift
		var line_y: float = ROAD_Y + (h - ROAD_Y) * 0.62
		while dx < w:
			draw_rect(Rect2(dx, line_y, DASH_LEN, 8), LINE_COLOR)
			dx += period
		_draw_van(VAN_POS + Vector2(0, roundf(sin(_t * TAU * VAN_BOB_HZ) * VAN_BOB)))
		_draw_sign(SIGN_POS)

	func _draw_van(p: Vector2) -> void:
		var s: Vector2 = VAN_SIZE
		draw_rect(Rect2(p + Vector2(10, -8), Vector2(s.x - 40, 8)), Color(0.3, 0.3, 0.32))   # roof rack
		draw_circle(p + Vector2(s.x * 0.45, -22), 14.0, BALL_COLOR)                        # a ball on the rack
		draw_line(p + Vector2(s.x * 0.45 - 14, -22), p + Vector2(s.x * 0.45 + 14, -22), Color(0.2, 0.1, 0.05), 2)
		draw_rect(Rect2(p, s), VAN_COLOR)
		draw_rect(Rect2(p + Vector2(s.x - 8, 30), Vector2(14, s.y - 34)), VAN_COLOR)   # nose
		draw_rect(Rect2(p + Vector2(0, s.y * 0.55), Vector2(s.x + 6, 10)), VAN_TRIM)   # blue stripe
		draw_rect(Rect2(p + Vector2(0, s.y * 0.55 + 10), Vector2(s.x + 6, 4)), LINE_COLOR)   # gold stripe
		for i in 3:
			draw_rect(Rect2(p + Vector2(14 + i * 58, 10), Vector2(46, 28)), VAN_GLASS)
		draw_rect(Rect2(p + Vector2(s.x - 40, 10), Vector2(38, 28)), VAN_GLASS)   # windscreen side
		var font: Font = ThemeDB.fallback_font
		draw_string(font, p + Vector2(12, s.y * 0.55 - 4), Cities.VAN_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				VAN_TRIM)
		for wx in [42.0, s.x - 42.0]:
			draw_circle(p + Vector2(wx, s.y + 4), 20.0, Color(0.08, 0.08, 0.09))
			draw_circle(p + Vector2(wx, s.y + 4), 8.0, Color(0.6, 0.6, 0.62))

	func _draw_sign(p: Vector2) -> void:
		draw_rect(Rect2(p + Vector2(70, 60), Vector2(10, 80)), Color(0.45, 0.45, 0.48))
		draw_rect(Rect2(p, Vector2(160, 70)), Color(0.10, 0.45, 0.25))
		draw_rect(Rect2(p + Vector2(4, 4), Vector2(152, 62)), Color.WHITE, false, 2.0)
		var font: Font = ThemeDB.fallback_font
		draw_string(font, p + Vector2(12, 30), "NEW YORK", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		draw_string(font, p + Vector2(12, 56), "1,100 MI  >", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
