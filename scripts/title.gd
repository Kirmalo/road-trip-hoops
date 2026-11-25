extends CanvasLayer
# Title screen (P5-06): one script for three Flow screens ("title", "settings", "crew"), built in code with ui_kit.gd.
#   title     the game name, the Cornfield Kings and their van The Biscuit on the road, and six buttons:
#             ROAD TRIP -> CONTINUE / NEW TRIP (NEW TRIP over a saved trip asks to confirm) -> EASY / NORMAL / HARD;
#             CONTINUE on a finished trip opens the map in replay mode (P8-20)
#             QUICK GAME -> today's game (its start panel picks the level and court, as before)
#             LOCKER (P8-13, owner Q3 a: Flow screen "locker", args {"back": "title"}; the star ladder and the
#             jersey / ball / van picks, P8-15), with a "STARS n/72" tab on the ROAD TRIP button (Stars.total())
#             LEGENDS (P9-15, owner L4 a: Flow screen "legends", the era tour) last on the top row; until
#             Chapter 1's gate (24 stars from any games) it shows locked with the gate on a tab ("24 STARS") and a
#             tap shows a line saying so. Read through legends.gd's mode_open() / gate_text() (P9-12), with a safe
#             fallback while legends.gd is missing (the gate from legends_data.gd, else 24, against Stars.total())
#             SETTINGS, CREW & CREDITS (their own Flow screens), HOW TO PLAY (Flow screen "howto", P7-H3)
#             and the version ("v1.0.0", from project.godot application/config/version) bottom-right (P7-04)
#             The level pickers (new trip, Settings) add LEGEND once Stars.legend_open() and difficulty.gd knows the
#             level (its NAMES has "legend", P8-19); until then they show EASY / NORMAL / HARD as before.
#   settings  MUSIC on/off and the MUSIC volume (P7-04), SOUND volume, the default LEVEL (Quick Game and new trips),
#             FULL SCREEN on/off (P6-T2) and LEFT-HANDED on/off (P7-04: Difficulty.set_left_handed, from the next game)
#   crew      the version, your crew (from the trip save if there is one: each player's unspent stat points, a
#             DRAFTED tag, the crew points; P8-13), the art and music credits (every CC-BY item
#             with title, author, license, source and changes) and the Godot license notice, in a scrolling list;
#             a HALL OF LEGENDS button top-right (Flow screen "hall", args {"back": "crew"}) once one legend is
#             unlocked (Legends.unlocked_ids(), else the Legends save's list; P9-15)
# The Road Trip sub-panels swap in place (no reload); every other move is Flow.go(). Each panel ignores taps for
# PANEL_ARM s, so a quick double tap can't fall through onto the next panel's button in the same spot.
# trip.gd / save.gd (P5-05) and audio.set_sfx_volume (P5-07) are called only if they exist, so this runs alone:
# without save.gd CONTINUE is off; without trip.gd NEW TRIP goes to the flow's "not built yet" map panel.
# FULL SCREEN (P6-T2): Difficulty.set_fullscreen() inside the tap (a browser needs the gesture); the label follows the
# real window mode every frame (the browser's Esc / back gesture). The first tap of a run puts a saved ON back
# (Difficulty.restore_fullscreen(), from _input here and in pause.gd).
# Desktop testing: Escape = BACK. Test: -- --titletest walks every screen and button (LOCKER and back too; checks the
# STARS tab and the level pickers; add --stars 72 for LEGEND; LEGENDS locked or open, e.g. --stars 0 / --stars 24,
# and CREW's HALL OF LEGENDS with --legends-unlock-all; screenshots with xvfb), puts every
# setting back and restores settings.cfg byte for byte at the end.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const MenuScript = preload("res://scripts/menu.gd")
const Difficulty = preload("res://scripts/difficulty.gd")
const Cities = preload("res://scripts/cities.gd")
const Stars = preload("res://scripts/stars.gd")     # total(), MAX, legend_open() (P8-02)

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
const MAIN_BTN := Vector2(400, 130)            # CONTINUE / NEW TRIP, START OVER / KEEP MY TRIP
const STAR_FONT := 24                          # "STARS 41/72" on the ROAD TRIP button's tab
const STAR_TAB_RISE := 24.0                    # px the stars tab sits above the ROAD TRIP button's top edge
const STAR_TAB_PAD := Vector2(14, 2)           # px inside the stars tab
const STAR_TAB_FILL := Color(0.10, 0.12, 0.30)   # the night sky's blue, gold border and text
const LOCKER_SCREEN := "locker"                # Flow screen (scripts/locker.gd, P8-15; "not built yet" until then)
const LEGEND_NAME := "legend"                  # the 4th level's name in Difficulty.NAMES (P8-19)
const TRIP_LEVEL_BTN4 := Vector2(260, 140)     # the new-trip level buttons when LEGEND makes four
const SIDE_BTN := Vector2(360, 110)            # SETTINGS / HOW TO PLAY / CREW & CREDITS (three fit 1280 px)
# P9-15 (owner L4 a): LEGENDS joins the top row, so the four top buttons share 1280 px
const TOP_BTN4 := Vector2(270, 130)            # ROAD TRIP / QUICK GAME / LOCKER / LEGENDS (4 x 270 + 3 gaps = 1200 px)
const TOP_FONT4 := 38                          # their text ("QUICK GAME" fits 270 px)
const LEGENDS_SCREEN := "legends"              # Flow screen (scripts/legends_tour.gd, P9-18; "not built yet" until then)
const HALL_SCREEN := "hall"                    # Flow screen (scripts/hall.gd, P9-19), args {"back": "crew"} from CREW
const LEGENDS_PATH := "res://scripts/legends.gd"           # P9-12: mode_open(), gate_text(), unlocked_ids() (optional)
const LEGENDS_DATA_PATH := "res://scripts/legends_data.gd" # P9-07: CHAPTERS[0].gate.stars, the fallback gate
const LEGENDS_SAVE_PATH := "res://scripts/legends_save.gd" # P9-02: read().unlocked, the fallback unlock count
const LEGENDS_GATE_STARS := 24                 # Chapter 1's gate when legends_data.gd isn't there (L4 a: 24 stars)
const LEGENDS_LOCK_FILL := Color(0.22, 0.18, 0.26)   # the locked LEGENDS button: dark purple-grey
const LEGENDS_LOCK_TEXT := Color(0.72, 0.66, 0.78)
const LEGENDS_TAB_FILL := Color(0.30, 0.10, 0.28)    # the gate tab ("24 STARS") on the locked button
const LEGENDS_MSG_TIME := 3.0                  # s the "LEGENDS OPEN AT 24 STARS" line stays after a tap on the lock
const LEGENDS_MSG_FONT := 26
const LEGENDS_MSG_Y := 522.0                   # px: the line's top, under the button rows, above the road
const LEGENDS_MSG_PAD := Vector2(18, 4)        # px inside its plate
const HALL_BTN := Vector2(330, 110)            # HALL OF LEGENDS, top-right on CREW & CREDITS (clear of the title)
const HALL_FONT := 30
const HALL_MARGIN := 24                        # px from the top-right corner (BACK is BACK_POS top-left)
const LEVEL_BTN := Vector2(240, 110)           # EASY / NORMAL / HARD in Settings
const LEVEL_BTN4 := Vector2(200, 110)          # ... and LEGEND: four fit next to the row label (1180 px)
const LEVEL_FONT4 := 34                        # their text then (NORMAL / LEGEND fit 200 px)
const BACK_POS := Vector2(24, 20)              # BACK, top-left on Settings and Crew
const ROW_LABEL_W := 220                       # left column of the Settings rows
const SETTINGS_GAP := 18                       # px between the Settings rows (6 rows fit 720 px high)
const MUSIC_BTN := Vector2(200, 110)           # MUSIC ON / OFF, left of the music volume slider
const TOGGLE_BTN := Vector2(380, 110)          # FULL SCREEN / LEFT-HANDED, side by side
const AUDIO_PATH := "res://scripts/audio.gd"   # music_volume, read_settings(), save_music_volume() (P7-02)
const VERSION_FONT := 22                       # "v1.0.0" on the title
const VERSION_MARGIN := 14                     # px from the bottom-right corner
const LICENSE_FONT := 18                       # the Godot license text in CREW & CREDITS
const CREDITS_FILE := "res://CREDITS.md"       # --titletest checks every CC-BY row in it is shown here
const STUB_COLOR := Color(0.65, 0.65, 0.7)
const SCROLL_SIZE := Vector2(1180, 560)        # the crew & credits list
const SCROLL_BAR_W := 36                       # wide enough to drag with a thumb
const SECTION_FONT := 40
const ENTRY_FONT := 28
const DETAIL_FONT := 22
const STAT_W := 120                            # px per rating column in the crew list
const NAME_W := 340                            # px: the crew list's name column
const ROLE_W := 175                            # px: the crew list's role column
const ROLE_MIN_FONT := 15                      # the smallest a long role shrinks to (P8-B4)
const TAG_W := 110                             # px: the crew list's last column (his points, DRAFTED)
const TAG_FONT := 20
const NAME_MIN_FONT := 20                      # a long nicknamed name shrinks down to this to fit NAME_W
const PTS_COLOR := Color(1.0, 0.82, 0.25)      # gold: points to spend
const DRAFT_COLOR := Color(0.55, 0.85, 1.0)    # the DRAFTED tag
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
const SIGN_POS := Vector2(1080, 518)   # below the three-button row (P7-04 made CREW & CREDITS reach x 1220)

# Credits (kept here as a const list, board P5-06; copy new rows from CREDITS.md):
#   [what, title, author, license, source, changes]   (changes: "" = none; every CC-BY item says what was changed)
# --titletest checks that every CC-BY row of CREDITS.md has an entry here with its source URL and license.
const CREDITS_LIST := [
	["Players, legends (Grandfathers and Fathers), jerseys, courts, era courts, balls, portraits, trip map, van paints, Legends screens, icon, How to Play pictures",
		"Original pixel art made for this project",
		"Road Trip Hoops project", "Original",
		"tools/art (make_players_v2.py, make_courts.py, make_portraits_v2.py, make_map.py, make_legends_ui.py, make_icon.py, make_howto.py)", ""],
	["Fallback sprites", "Sports Pack", "Kenney", "CC0 1.0", "https://www.kenney.nl", ""],
	["Menu music", "Stage 1 (4 Chiptunes, Adventure)", "Juhani Junkala (SubspaceAudio)", "CC0",
		"https://opengameart.org/content/4-chiptunes-adventure", ""],
	["Gym music", "Stage 2 (4 Chiptunes, Adventure)", "Juhani Junkala (SubspaceAudio)", "CC0",
		"https://opengameart.org/content/4-chiptunes-adventure", ""],
	["Blacktop music", "Level 1 (5 Chiptunes, Action)", "Juhani Junkala (SubspaceAudio)", "CC0",
		"https://opengameart.org/content/5-chiptunes-action", ""],
	["Hometown music", "[Chiptune] Medieval: Minstrel Dance", "RandomMind", "CC0",
		"https://opengameart.org/content/chiptune-medieval-minstrel-dance", ""],
	["Chicago music", "8-Bit Bluesy Battle Theme", "emanresU", "CC0",
		"https://opengameart.org/content/8-bit-bluesy-battle-theme", ""],
	["Memphis music", "New Blue Shoes", "congusbongus", "CC-BY 4.0",
		"https://opengameart.org/content/new-blue-shoes",
		"Cut to a loop (41.90-76.46 s), loop crossfade, mono, loudness levelled, Ogg Vorbis"],
	["New Orleans music", "NES chiptune \"Swingshot\" (Swing Jazz)", "Haley Halcyon", "CC0",
		"https://opengameart.org/content/nes-chiptune-swingshot-swing-jazz", ""],
	["Denver music", "Lasso Lady (seamless loop)", "congusbongus", "CC0",
		"https://opengameart.org/content/lasso-lady-seamless-loop", ""],
	["Seattle music", "My Friends Will Cry. (title theme)", "Music by Christovix Games", "CC-BY 3.0",
		"https://opengameart.org/content/my-friends-will-cry",
		"Cut to a loop (11.20-93.25 s), loop crossfade, mono, loudness levelled, Ogg Vorbis"],
	["Los Angeles music", "Happy Ukelele Island Surfing Theme", "Tarush Singhal", "CC0",
		"https://opengameart.org/content/happy-ukelele-island-surfing-theme", ""],
	["Grandfathers era music", "Bebop (Chiptune)", "Pro Sensory (Alex McCulloch)", "CC0",
		"https://opengameart.org/content/bebop-chiptune",
		"De-clipped, cut to a loop (28.25-78.25 s), loop crossfade, mono, loudness levelled, Ogg Vorbis"],
	["Fathers era music", "Headspin", "congusbongus", "CC0",
		"https://opengameart.org/content/headspin",
		"Cut to a loop (76.34-173.75 s), loop crossfade, mono, loudness levelled, Ogg Vorbis"],
	["Present era music", "Techno drive", "Centurion_of_war", "CC-BY 4.0",
		"https://opengameart.org/content/techno-drive",
		"The chiptune version (v2.5), cut to a loop (47.86-87.86 s), loop crossfade, mono, loudness levelled, Ogg Vorbis"],
	["New York music", "NES chiptune \"Slam-Funk\"", "Haley Halcyon", "CC-BY 4.0",
		"https://opengameart.org/content/nes-chiptune-slam-funk",
		"Cut to a loop (6.10-45.45 s), loop crossfade, mono, loudness levelled, Ogg Vorbis"],
	["Crowd", "Free Crowd Cheering Sounds (03 - Strong cheering - I)", "Gregor Quendel (www.gregorquendel.com)",
		"CC-BY 4.0", "https://opengameart.org/content/free-crowd-cheering-sounds",
		"Cut 5.5-10.5 s into a seamless loop, mono, normalized, Ogg Vorbis"],
	["Loud crowd (Memphis)", "Free Crowd Cheering Sounds (03 - Strong cheering - I)",
		"Gregor Quendel (www.gregorquendel.com)", "CC-BY 4.0",
		"https://opengameart.org/content/free-crowd-cheering-sounds",
		"The crowd loop layered 4 times with a synthesized roar, claps and stomps (tools/make_twist_sfx.py)"],
	["Rim", "Metal Impact Sounds", "BMacZero", "CC0", "https://opengameart.org/content/metal-impact-sounds", ""],
	["Dunk", "100 CC0 metal and wood SFX", "rubberduck", "CC0",
		"https://opengameart.org/content/100-cc0-metal-and-wood-sfx", ""],
	["Block", "10 Impact/Shield Blocks", "StarNinjas", "CC0",
		"https://opengameart.org/content/10-impactshield-blocks", ""],
	["On fire", "Catching fire", "themightyglider", "CC0", "https://opengameart.org/content/catching-fire", ""],
	["Swish, bounce, whistle, rain, wind, fence, splash, sand, star, stat-up, unlock, countdown, GO!",
		"Synthesized sounds made for this project", "Road Trip Hoops project", "Original",
		"tools/make_swish.py, tools/make_bounce.py, tools/make_whistle.py, tools/make_twist_sfx.py, tools/make_ui_sfx.py",
		""],
	["Game engine", "Godot Engine", "Juan Linietsky, Ariel Manzur and contributors", "MIT",
		"https://godotengine.org", ""],
]
# the license text each CC-BY version points to (shown under every CC-BY item)
const LICENSE_URLS := {
	"CC-BY 4.0": "https://creativecommons.org/licenses/by/4.0/",
	"CC-BY 3.0": "https://creativecommons.org/licenses/by/3.0/",
}

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
var _lh_btn: Button          # LEFT-HANDED: ON / OFF (Settings, P7-04)
var _music_slider: HSlider   # the music volume (Settings, P7-04)
var _music_dirty_t := -1.0
var _scroll: ScrollContainer
var _art: Control
var _legends_msg: Label      # the line a tap on the locked LEGENDS button shows (P9-15)
var _legends_msg_t := 0.0

# --titletest driver (survives the reloads between screens)
static var _test_step := 0
var _test_on := false
var _test_t := 0
var _test_fs := false        # the saved FULL SCREEN before the test pressed it
static var _test_cfg_taken := false            # settings.cfg as it was before the test (restored at the end)
static var _test_cfg_had := false
static var _test_cfg_bytes := PackedByteArray()

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
	if _music_dirty_t > 0.0:
		_music_dirty_t -= delta
		if _music_dirty_t <= 0.0:
			_save_music_volume()
	if _art != null:
		_art.queue_redraw()
	if _legends_msg_t > 0.0:
		_legends_msg_t -= delta
		if _legends_msg_t <= 0.0 and is_instance_valid(_legends_msg):
			_legends_msg.visible = false
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
	var v: String = version()
	if v != "":
		var vl := UI.label(_root, "v" + v, VERSION_FONT, STUB_COLOR)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, VERSION_MARGIN)
		vl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		vl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_show_panel("main")

# the game's version, single source project.godot (P7-08); "" = no label
static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))

func _show_panel(which: String) -> void:
	_panel = which
	if _content != null:
		_content.queue_free()
	if is_instance_valid(_legends_msg):
		_legends_msg.queue_free()
	_legends_msg = null
	_legends_msg_t = 0.0
	_buttons.clear()
	var box := UI.vbox(_root, PANEL_GAP)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.offset_top = PANEL_TOP
	_content = box
	match which:
		"trip":
			UI.subtitle(box, _trip_summary() if _has_trip() else "No trip saved yet. Start one and hit the road!")
			var row := UI.hbox(box)
			# a finished trip continues on the map in replay mode (P8-20); NEW TRIP is the gold button then
			var can_go: bool = _has_trip()
			var lit_new: bool = can_go and _trip_finished()
			var cont: Button = _btn(row, "CONTINUE", _on_continue,
					UI.KIND_LIT if can_go and not lit_new else UI.KIND_MAIN, MAIN_BTN)
			if not can_go:
				cont.set_meta("off", true)
			_btn(row, "NEW TRIP", _on_new_trip, UI.KIND_LIT if lit_new or not can_go else UI.KIND_MAIN, MAIN_BTN)
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
			var levels: Array = level_choices()
			for lv in levels:
				_btn(row3, String(Difficulty.NAMES[lv]).to_upper(), _on_trip_level.bind(lv),
						UI.KIND_LIT if lv == Difficulty.level else _level_kind(lv),
						TRIP_LEVEL_BTN4 if levels.size() > 3 else Vector2.ZERO)
			_btn(UI.hbox(box), "BACK", _show_panel.bind("trip"), UI.KIND_OPT, UI.SMALL_SIZE)
		_:
			var r1 := UI.hbox(box)
			var road: Button = _top_btn(r1, "ROAD TRIP", _show_panel.bind("trip"), UI.KIND_LIT)
			_star_tab(road)
			_top_btn(r1, "QUICK GAME", _on_quick_game, UI.KIND_MAIN)
			_top_btn(r1, "LOCKER", _on_locker, UI.KIND_MAIN)
			_legends_button(r1)   # last: its gate tab stays clear of the "on the road" line above the middle
			var r2 := UI.hbox(box)
			_btn(r2, "SETTINGS", _go.bind("settings"), UI.KIND_OPT, SIDE_BTN)
			_btn(r2, "HOW TO PLAY", _on_how_to_play, UI.KIND_OPT, SIDE_BTN)
			_btn(r2, "CREW & CREDITS", _go.bind("crew"), UI.KIND_OPT, SIDE_BTN)
	if which == "main":
		# on a dark plate like the tabs, so it reads over the cornfield and the road sign at any width
		_legends_msg = UI.label(_root, "", LEGENDS_MSG_FONT, NAME_COLOR)
		var sb := UI.style_box(STAR_TAB_FILL, NAME_COLOR, UI.BORDER)
		sb.content_margin_left = LEGENDS_MSG_PAD.x
		sb.content_margin_right = LEGENDS_MSG_PAD.x
		sb.content_margin_top = LEGENDS_MSG_PAD.y
		sb.content_margin_bottom = LEGENDS_MSG_PAD.y
		_legends_msg.add_theme_stylebox_override("normal", sb)
		_legends_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_legends_msg.anchor_left = 0.5
		_legends_msg.anchor_right = 0.5
		_legends_msg.offset_left = 0.0
		_legends_msg.offset_right = 0.0
		_legends_msg.offset_top = LEGENDS_MSG_Y
		_legends_msg.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_legends_msg.visible = false
	_arm(PANEL_ARM)

# a top-row button: four share the row since LEGENDS (P9-15)
func _top_btn(parent: Control, text: String, on_tap: Callable, kind: String) -> Button:
	var b: Button = _btn(parent, text, on_tap, kind, TOP_BTN4)
	b.add_theme_font_size_override("font_size", TOP_FONT4)
	return b

# LEGENDS (P9-15, owner L4 a): open = purple, opens the era tour; locked = dark with the gate on a tab ("24 STARS"),
# and a tap says what opens it (it stays tappable)
func _legends_button(parent: Control) -> Button:
	var open: bool = legends_open()
	var b: Button = _top_btn(parent, "LEGENDS", _on_legends, UI.KIND_LEGEND if open else UI.KIND_OPT)
	b.name = "LegendsButton"
	if not open:
		var sb := UI.style_box(LEGENDS_LOCK_FILL, UI.LEGEND_BORDER.darkened(0.4), UI.BORDER)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("disabled", sb)
		UI.set_text_color(b, LEGENDS_LOCK_TEXT)
		_tab(b, legends_gate_text(), LEGENDS_TAB_FILL, "GateTab")
	return b

func _on_legends() -> void:
	if legends_open():
		_stat("title_legends")
		_go(LEGENDS_SCREEN)
		return
	_stat("title_legends_locked")
	if is_instance_valid(_legends_msg):
		_legends_msg.text = legends_locked_text()
		_legends_msg.visible = true
		_legends_msg_t = LEGENDS_MSG_TIME

# "LEGENDS OPEN AT 24 STARS. YOU HAVE 9: WIN TRIP GAMES!" (the line under the buttons after a tap on the locked button)
static func legends_locked_text() -> String:
	return "LEGENDS OPEN AT %s. YOU HAVE %d: WIN TRIP GAMES!" % [legends_gate_text(), Stars.total()]

# "STARS 41/72": a small tab on the top edge of the ROAD TRIP button (the stars come from trip games); taps go through
func _star_tab(b: Button) -> void:
	_tab(b, stars_text(), STAR_TAB_FILL, "StarTab")

# a small tab on a button's top edge (the STARS count, the LEGENDS gate); taps go through to the button
func _tab(b: Button, text: String, fill: Color, tab_name: String) -> void:
	var tab := PanelContainer.new()
	var sb := UI.style_box(fill, NAME_COLOR, UI.BORDER)
	sb.content_margin_left = STAR_TAB_PAD.x
	sb.content_margin_right = STAR_TAB_PAD.x
	sb.content_margin_top = STAR_TAB_PAD.y
	sb.content_margin_bottom = STAR_TAB_PAD.y
	tab.add_theme_stylebox_override("panel", sb)
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab.name = tab_name
	UI.label(tab, text, STAR_FONT, NAME_COLOR)
	b.add_child(tab)
	tab.anchor_left = 0.5
	tab.anchor_right = 0.5
	tab.anchor_top = 0.0
	tab.anchor_bottom = 0.0
	tab.offset_left = 0.0
	tab.offset_right = 0.0
	tab.offset_top = -STAR_TAB_RISE
	tab.offset_bottom = -STAR_TAB_RISE
	tab.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tab.grow_vertical = Control.GROW_DIRECTION_END

static func stars_text() -> String:
	return "STARS %d/%d" % [Stars.total(), Stars.MAX]

# the levels a picker offers: EASY / NORMAL / HARD, and LEGEND once 72 stars open it and difficulty.gd has the level
# (Difficulty.NAMES gets "legend" in P8-19; before that a picked 3 would save as "hard", so it stays out)
static func level_choices() -> Array:
	var out: Array = [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD]
	var lg: int = Difficulty.NAMES.find(LEGEND_NAME)
	if lg > Difficulty.HARD and Stars.legend_open():
		out.append(lg)
	return out

# an unpicked level button's look: LEGEND purple like the Quick Game panel (P8-B6), the others blue
static func _level_kind(lv: int) -> String:
	return UI.KIND_LEGEND if lv == Difficulty.NAMES.find(LEGEND_NAME) else UI.KIND_MAIN

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

func _on_locker() -> void:
	_stat("title_locker")
	_go(LOCKER_SCREEN, {"back": "title"})

func _on_how_to_play() -> void:
	_stat("title_how_to_play")
	_go("howto", {"back": "title"})

func _on_continue() -> void:
	if not _has_trip():
		return
	_stat("title_continue")
	var trip: GDScript = _script(TRIP_PATH)
	var before: String = str(Flow.screen)
	var loaded: bool = false
	if trip != null and trip.has_method("continue_trip"):
		loaded = bool(trip.call("continue_trip"))
	if not _busy and str(Flow.screen) == before:
		# continue where the trip left off (map, points, recruit or bracket); a finished trip opens the map (replays)
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
	var box := UI.vbox(_root, SETTINGS_GAP)
	box.offset_top = 20
	UI.title(box, "SETTINGS")
	# MUSIC: ON / OFF, then its volume (the sliders line up: SOUND has a gap where MUSIC has its button)
	var r1 := _row(box, "MUSIC")
	_music_btn = UI.button(r1, "", _tap.bind(_toggle_music), UI.KIND_OPT, MUSIC_BTN)
	_buttons.append(_music_btn)
	_music_slider = UI.slider(r1, _saved_music(), _on_music_volume)
	var r2 := _row(box, "SOUND")
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(MUSIC_BTN.x, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r2.add_child(gap)
	_sfx_slider = UI.slider(r2, _saved_sfx(), _on_sfx)
	var r3 := _row(box, "LEVEL")
	var levels: Array = level_choices()
	for lv in levels:
		var b: Button = UI.button(r3, String(Difficulty.NAMES[lv]).to_upper(), _tap.bind(_pick_level.bind(lv)),
				UI.KIND_MAIN, LEVEL_BTN4 if levels.size() > 3 else LEVEL_BTN)
		if levels.size() > 3:
			b.add_theme_font_size_override("font_size", LEVEL_FONT4)
		_level_btns.append(b)
		_buttons.append(b)
	UI.label(box, "LEVEL is for Quick Game and new trips" + (", and your saved trip" if _has_trip() else ""),
			UI.SUB_FONT, STUB_COLOR)
	var r4 := UI.hbox(box)
	_fs_btn = UI.button(r4, "", _tap.bind(_toggle_fullscreen), UI.KIND_OPT, TOGGLE_BTN)
	_buttons.append(_fs_btn)
	_lh_btn = UI.button(r4, "", _tap.bind(_toggle_left_handed), UI.KIND_OPT, TOGGLE_BTN)
	_buttons.append(_lh_btn)
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
	var lh: bool = Difficulty.is_left_handed()
	_lh_btn.text = "LEFT-HANDED: ON" if lh else "LEFT-HANDED: OFF"
	UI.set_text_color(_lh_btn, UI.OFF_TEXT if lh else UI.OPT_OFF_TEXT)
	for i in _level_btns.size():
		UI.set_kind(_level_btns[i], UI.KIND_LIT if i == Difficulty.level else _level_kind(i))

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

# joystick on the right, buttons on the left from the next game (touch_controls.gd reads it); saved at once
func _toggle_left_handed() -> void:
	var on: bool = not Difficulty.is_left_handed()
	Difficulty.set_left_handed(on)
	_stat("title_left_handed_" + ("on" if on else "off"))
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

static func _audio_script() -> GDScript:
	return _script(AUDIO_PATH)

# the saved music volume (audio.gd reads it once per run); 1.0 = the music as before P7-02
static func _saved_music() -> float:
	var a: GDScript = _audio_script()
	if a == null or not a.has_method("read_settings"):
		return 1.0
	a.call("read_settings")
	return clampf(float(a.get("music_volume")), 0.0, 1.0)

# previews on the playing menu music at once; saved SFX_SAVE_DELAY s after the last move
func _on_music_volume(v: float) -> void:
	if audio != null and audio.has_method("set_music_volume"):
		audio.call("set_music_volume", v, false)
	_music_dirty_t = SFX_SAVE_DELAY

# a test run keeps the volume for the run only (like the left-handed switch), so it never writes the owner's file
func _save_music_volume() -> void:
	_music_dirty_t = -1.0
	var a: GDScript = _audio_script()
	if not Difficulty.is_test_run() and a != null and a.has_method("save_music_volume"):
		a.call("save_music_volume")
	_stat("title_music_volume_saved")

func _back_button() -> void:
	var b: Button = UI.button(_root, "BACK", _tap.bind(_go.bind("title")), UI.KIND_OPT, UI.SMALL_SIZE)
	b.position = BACK_POS
	_buttons.append(b)

func _exit_tree() -> void:
	if _sfx_dirty_t > 0.0 and _sfx_slider != null:
		_save_sfx()   # leaving right after a slider move still keeps it
	if _music_dirty_t > 0.0 and _music_slider != null:
		_save_music_volume()

# ---------------- crew & credits ----------------

func _build_crew() -> void:
	_back_button()
	var t := UI.title(_root, "CREW & CREDITS")
	t.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	t.offset_top = 30
	t.offset_bottom = 130
	_hall_button()
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
	var v: String = version()
	if v != "":
		_left(list, "ROAD TRIP HOOPS  v" + v, ENTRY_FONT, NAME_COLOR)
		_spacer(list, 12)
	_crew_section(list)
	_spacer(list, 24)
	_section(list, "CREDITS")
	for row in CREDITS_LIST:
		var e: Array = row
		_left(list, str(e[0]).to_upper(), ENTRY_FONT, NAME_COLOR)
		_left(list, "\"%s\"  -  %s  (%s)" % [e[1], e[2], e[3]], DETAIL_FONT)
		_left(list, "Source: " + str(e[4]), DETAIL_FONT, STUB_COLOR)
		if LICENSE_URLS.has(str(e[3])):
			_left(list, "License: %s  %s" % [e[3], LICENSE_URLS[str(e[3])]], DETAIL_FONT, STUB_COLOR)
		if e.size() > 5 and str(e[5]) != "":
			_left(list, "Changes: " + str(e[5]), DETAIL_FONT, STUB_COLOR)
		_spacer(list, 6)
	_left(list, "Only CC0 and CC-BY assets are used. The CC-BY crowd sounds and the Memphis, Seattle, New York and " +
			"Present era music need the credit above.", DETAIL_FONT, STUB_COLOR)
	_left(list, "Full list: CREDITS.md in the game folder.", DETAIL_FONT, STUB_COLOR)
	_spacer(list, 24)
	_section(list, "GODOT ENGINE LICENSE")
	_left(list, "This game uses Godot Engine, available under the following license:", DETAIL_FONT)
	_left(list, Engine.get_license_text(), LICENSE_FONT, STUB_COLOR)
	_spacer(list, 20)
	_arm(PANEL_ARM)

# HALL OF LEGENDS (P9-15): top-right on CREW & CREDITS once one legend is unlocked; opens "hall" with back "crew"
func _hall_button() -> void:
	if legends_unlocked_count() <= 0:
		return
	var b: Button = UI.button(_root, "HALL OF LEGENDS", _tap.bind(_on_hall), UI.KIND_LEGEND, HALL_BTN)
	b.add_theme_font_size_override("font_size", HALL_FONT)
	b.name = "HallButton"
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -HALL_MARGIN - HALL_BTN.x
	b.offset_right = -HALL_MARGIN
	b.offset_top = BACK_POS.y
	b.offset_bottom = BACK_POS.y + HALL_BTN.y
	_buttons.append(b)

func _on_hall() -> void:
	_stat("crew_hall")
	_go(HALL_SCREEN, {"back": "crew"})

func _crew_section(list: Control) -> void:
	_section(list, "THE " + Cities.CREW_NAME)
	var save: Dictionary = _read_save()
	if save.is_empty():
		_left(list, "Van: %s.  No trip yet: tap ROAD TRIP on the title to start one." % Cities.VAN_NAME.capitalize(),
				DETAIL_FONT)
	else:
		# P8-B5: the record is in _trip_summary() already ("DENVER, GAME 1 - 12-1 - HARD")
		_left(list, "Van: %s.   %s.   Crew points: %d." % [Cities.VAN_NAME.capitalize(), _trip_summary(),
				crew_points_of(save)], DETAIL_FONT)
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
		row.add_theme_constant_override("separation", 6)
		list.add_child(row)
		var who: String = "#%s %s" % [str(p.get("number", "")), str(p.get("full", id))]
		var name_text: String = who + ("  *" if starters.has(id) else "")
		var nl := _left(row, name_text, _fit_font(name_text, NAME_W, ENTRY_FONT, NAME_MIN_FONT))
		nl.custom_minimum_size = Vector2(NAME_W, 0)
		var role_text: String = str(p.get("role", ""))
		# P8-B4: a long role ("fast-break guard") shrinks to keep a gap before SPD
		var role := _left(row, role_text, _fit_font(role_text, ROLE_W - 12, DETAIL_FONT, ROLE_MIN_FONT), STUB_COLOR)
		role.custom_minimum_size = Vector2(ROLE_W, 0)
		for s in STAT_NAMES:
			var sl := _left(row, "%s %d" % [s[1], int(ratings.get(s[0], 50))], DETAIL_FONT)
			sl.custom_minimum_size = Vector2(STAT_W - 30, 0)
		# his own unspent points and how he joined (P8-08 "pts" / "via"; a 1.0.0 save has neither: no tags)
		var tags := VBoxContainer.new()
		tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tags.add_theme_constant_override("separation", 0)
		tags.alignment = BoxContainer.ALIGNMENT_CENTER
		tags.custom_minimum_size = Vector2(TAG_W, 0)
		row.add_child(tags)
		var pv = entry.get("pts", 0)
		var pts: int = maxi(0, int(pv) if (pv is int or pv is float) else 0)
		if pts > 0:
			_left(tags, "%d PT%s" % [pts, "" if pts == 1 else "S"], TAG_FONT, PTS_COLOR)
		if str(entry.get("via", "")) == "draft":
			_left(tags, "DRAFTED", TAG_FONT, DRAFT_COLOR)
	_left(list, "* = starter    PTS = his own stat points to spend    DRAFTED = signed into a star slot", DETAIL_FONT,
			STUB_COLOR)

# the biggest font size from `size` down to `min_size` at which `text` fits `width` px (long nicknamed names)
static func _fit_font(text: String, width: int, size: int, min_size: int) -> int:
	var f: Font = ThemeDB.fallback_font
	var s: int = size
	while s > min_size and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + UI.OUTLINE > width:
		s -= 1
	return s

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

# the crew points of a saved trip: version 2 "crew_points"; a 1.0.0 save's shared pool "points" (its catch-up is
# added when the trip is loaded, P8-08)
static func crew_points_of(save: Dictionary) -> int:
	var v = save.get("crew_points", 0) if save.has("crew_points") else save.get("points", 0)
	return maxi(0, int(v) if (v is int or v is float) else 0)

# the trip save as a Dictionary ({} = none); read only when save.gd says there is a trip (save.gd's read(): the test
# file in a trip test, a newer temp file after a cut-off write)
static func _read_save() -> Dictionary:
	if not _has_trip():
		return {}
	var sv: GDScript = _script(SAVE_PATH)
	if sv != null and sv.has_method("read"):
		var d = sv.call("read")
		return d if d is Dictionary else {}
	if not FileAccess.file_exists(TRIP_FILE):
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
		return "TRIP COMPLETE - CHAMPIONS!  %d-%d  -  %s  -  CONTINUE to replay, or a NEW TRIP" % [
				int(rec.get("wins", 0)), int(rec.get("losses", 0)), str(s.get("level", "normal")).to_upper()]
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

# ---------------- legends.gd (P9-12), guarded ----------------
# legends.gd may not exist yet: its contract functions are called when it has them, else a safe fallback (the gate
# from legends_data.gd or LEGENDS_GATE_STARS against Stars.total(); the unlocked legends from the Legends save file,
# with --legends-unlock-all / --legends-unlock-none). All loaded at run time, like cities.gd loads cosmetics.gd.

const UNLOCK_ALL_FLAG := "--legends-unlock-all"
const UNLOCK_NONE_FLAG := "--legends-unlock-none"
static var _legends_loaded := false   # Legends.load_state() asked once this run

static func _legends() -> GDScript:
	var lg: GDScript = _script(LEGENDS_PATH)
	if lg != null and not _legends_loaded and lg.has_method("load_state"):
		_legends_loaded = true
		lg.call("load_state")
	return lg

# Chapter 1 is open: Legends.mode_open(), else Stars.total() >= the gate
static func legends_open() -> bool:
	var lg: GDScript = _legends()
	if lg != null and lg.has_method("mode_open"):
		return bool(lg.call("mode_open"))
	return Stars.total() >= _fallback_gate_stars()

# "24 STARS": Legends.gate_text(<chapter 1>), else from the fallback gate
static func legends_gate_text() -> String:
	var lg: GDScript = _legends()
	if lg != null and lg.has_method("gate_text"):
		var t: String = str(lg.call("gate_text", _first_chapter_id()))
		if t != "":
			return t
	return "%d STARS" % _fallback_gate_stars()

# how many legends are unlocked for good: Legends.unlocked_ids(), else the Legends save's "unlocked" list
static func legends_unlocked_count() -> int:
	var lg: GDScript = _legends()
	if lg != null and lg.has_method("unlocked_ids"):
		var ids = lg.call("unlocked_ids")
		return (ids as Array).size() if ids is Array else 0
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	if cmd.has(UNLOCK_NONE_FLAG):
		return 0
	if cmd.has(UNLOCK_ALL_FLAG):
		return 1
	var sv: GDScript = _script(LEGENDS_SAVE_PATH)
	if sv == null or not sv.has_method("read"):
		return 0
	var d = sv.call("read")
	if not (d is Dictionary):
		return 0
	var u = (d as Dictionary).get("unlocked", null)
	return (u as Array).size() if u is Array else 0

# Chapter 1's id from legends_data.gd ("grand" when it isn't there)
static func _first_chapter_id() -> String:
	return str(_first_chapter().get("id", "grand"))

static func _first_chapter() -> Dictionary:
	var data: GDScript = _script(LEGENDS_DATA_PATH)
	if data == null:
		return {}
	var rows = data.get("CHAPTERS")
	if rows is Array and (rows as Array).size() > 0 and (rows as Array)[0] is Dictionary:
		return (rows as Array)[0]
	return {}

static func _fallback_gate_stars() -> int:
	var g = _first_chapter().get("gate", {})
	if g is Dictionary:
		var st = (g as Dictionary).get("stars", null)
		if st is int or st is float:
			return int(st)
	return LEGENDS_GATE_STARS

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

const TEST_WAIT := 30          # frames between test steps
const TEST_HOWTO_WAIT := 1.0   # s on the How to Play screen before paging (its PANEL_ARM has passed)
const TEST_HOWTO_PAGE := 0.5   # s on the next page before BACK
const TEST_MUSIC_VOL := 0.3    # where the test moves the MUSIC slider (and back)
const TEST_SHOT_DELAY := 0.2   # s after the locked LEGENDS tap before its screenshot (the line is drawn by then)

static var _test_errors := 0

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
			_test_keep_settings_file()
			_shot("title")
			print("TITLE TEST version label: %s" % ("v" + version() if version() != "" else "(none)"))
			_test_check_stars()
			_press("ROAD TRIP")
		2:
			_shot("title_trip")
			_press("NEW TRIP")
		3:
			_shot("title_" + _panel)
			if _panel == "confirm":
				_press("KEEP MY TRIP")
			else:
				_test_check_levels("new trip", _count_level_buttons())
				_press("BACK")
		4:
			_press("BACK")
		5:
			_press("SETTINGS")
		6:
			_shot("settings")
			_test_check_levels("settings", _level_btns.size())
			_press("ON" if MenuScript.music_on else "OFF")
			_press(_lh_btn.text)                              # LEFT-HANDED: ON (kept on to reach the game)
		7:
			print("TITLE TEST music_on=%s left_handed=%s (%s)" % [MenuScript.music_on, Difficulty.is_left_handed(),
					_lh_btn.text])
			_check(Difficulty.is_left_handed() and _lh_btn.text == "LEFT-HANDED: ON", "LEFT-HANDED did not turn on")
			_shot("settings_left_handed")
			_press("ON" if MenuScript.music_on else "OFF")   # back to how it was
			_test_fs = Difficulty.fullscreen_saved()
			_press(_fs_btn.text)                              # FULL SCREEN (headless: no window, stays OFF)
			var keep: float = _sfx_slider.value
			_sfx_slider.value = 0.5
			_sfx_slider.value = keep
			var keep_music: float = _music_slider.value
			_music_slider.value = TEST_MUSIC_VOL
			var a: GDScript = _audio_script()
			var now: float = float(a.get("music_volume")) if a != null else -1.0
			print("TITLE TEST music volume slider %.2f -> audio %.2f" % [_music_slider.value, now])
			_check(absf(now - TEST_MUSIC_VOL) < 0.001, "the MUSIC slider did not reach audio.gd")
			_music_slider.value = keep_music
		8:
			print("TITLE TEST music_on=%s sfx=%.2f music_volume=%.2f level=%s fullscreen=%s (%s, saved %s)" % [
					MenuScript.music_on, _sfx_slider.value, _music_slider.value, Difficulty.level_name(),
					Difficulty.is_fullscreen(), _fs_btn.text, Difficulty.fullscreen_saved()])
			Difficulty.set_fullscreen(_test_fs)   # back to how it was
			_press(Difficulty.level_name().to_upper())
			_press("BACK")
		9:
			_test_howto(get_tree())
			_press("HOW TO PLAY")
		10:
			_check(scr == "title", "How to Play BACK did not come back to the title")
			_press("CREW & CREDITS")
		11:
			_shot("crew")
			_test_check_credits()
			_test_check_hall_button()
			_scroll.scroll_vertical = 100000
		12:
			_shot("crew_end")
			print("TITLE TEST crew list scrolled to %d" % _scroll.scroll_vertical)
			if _find_named(_root, "HallButton") != null:
				_test_hall(get_tree())   # HALL OF LEGENDS, then its BACK lands on CREW again (step 13)
				_press("HALL OF LEGENDS")
			else:
				_press("BACK")
		13:
			if scr == "crew":
				_check(_test_hall_done, "came back to CREW without visiting the Hall")
				_press("BACK")
			else:
				_check(not _test_hall_done, "the hall's BACK went to '%s', not CREW" % scr)
				_check(scr == "title", "CREW BACK did not come back to the title")
		14:
			_check(scr == "title", "not on the title before LOCKER")
			_test_locker(get_tree())
			_press("LOCKER")
		15:
			_check(scr == "title", "LOCKER BACK did not come back to the title")
			_test_legends_button()
		16:
			_check(scr == "title", "LEGENDS did not come back to the title")
			_test_quick_game(get_tree())
			_press("QUICK GAME")

# the STARS tab on ROAD TRIP shows Stars.total() (--stars N sets it) of Stars.MAX
func _test_check_stars() -> void:
	var tab: Node = null
	for b in _buttons:
		if is_instance_valid(b) and b.text == "ROAD TRIP":
			tab = b.get_node_or_null("StarTab")
	var shown: String = (tab.get_child(0) as Label).text if tab != null and tab.get_child_count() > 0 else "(none)"
	print("TITLE TEST stars tab: %s (Stars.total %d, legend open %s)" % [shown, Stars.total(), Stars.legend_open()])
	# with --stars N the total is fixed; otherwise the test settings file may change under us (other test runs
	# record stars in it), so only the form is checked
	if Stars.force_total >= 0:
		_check(shown == "STARS %d/%d" % [Stars.total(), Stars.MAX], "the STARS tab does not show Stars.total()")
	else:
		var re := RegEx.new()
		re.compile("^STARS \\d+/%d$" % Stars.MAX)
		_check(re.search(shown) != null, "the STARS tab reads '%s'" % shown)
	var lk: bool = false
	for b in _buttons:
		lk = lk or (is_instance_valid(b) and b.text == "LOCKER")
	_check(lk, "no LOCKER button on the title")

func _count_level_buttons() -> int:
	var n := 0
	for b in _buttons:
		if is_instance_valid(b) and Difficulty.NAMES.has(b.text.to_lower()):
			n += 1
	return n

# the level pickers offer LEGEND exactly when level_choices() does (Stars.legend_open() and difficulty.gd's level)
static func _test_check_levels(where: String, n: int) -> void:
	var want: int = level_choices().size()
	print("TITLE TEST %s level buttons: %d (want %d; legend open %s, difficulty.gd has legend %s)" % [where, n, want,
			Stars.legend_open(), Difficulty.NAMES.has(LEGEND_NAME)])
	_check(n == want, "the %s level picker shows %d levels, not %d" % [where, n, want])

# LOCKER (P8-13): the "locker" screen opens with args.back = "title" (locker.gd, or the flow's "not built yet" panel
# until P8-15), then its BACK (Escape if it has none) lands on the title again
static func _test_locker(tree: SceneTree) -> void:
	tree.create_timer(TEST_HOWTO_WAIT).timeout.connect(func():
		var node: Node = Flow.current_screen()
		print("TITLE TEST locker: screen=%s back=%s node=%s" % [str(Flow.screen), str(Flow.args.get("back", "")),
				node.get_script().resource_path if node != null and node.get_script() != null else "none"])
		_check(str(Flow.screen) == LOCKER_SCREEN, "LOCKER did not open the locker screen")
		_check(str(Flow.args.get("back", "")) == "title", "LOCKER did not pass back = title")
		_shot("locker")
		var back: Button = _find_back(node)
		if back != null:
			print("TITLE TEST locker: BACK")
			back.emit_signal("pressed")
		else:
			print("TITLE TEST locker: Escape")
			var k := InputEventKey.new()
			k.keycode = KEY_ESCAPE
			k.pressed = true
			Input.parse_input_event(k)
		tree.create_timer(TEST_HOWTO_WAIT).timeout.connect(func():
			if str(Flow.screen) == LOCKER_SCREEN:
				_check(false, "the locker's BACK did not leave the screen")
				Flow.go("title")))

# P9-15: the title's buttons all lie inside the window (four on the top row since LEGENDS), the LEGENDS button shows
# the gate tab exactly when Chapter 1 is locked; open: it opens "legends" and that screen's BACK lands on the title
# (step 16); locked: a tap stays on the title and shows the gate line
func _test_legends_button() -> void:
	var view: Rect2 = get_viewport().get_visible_rect()
	for b in _buttons:
		if is_instance_valid(b):
			var r: Rect2 = (b as Button).get_global_rect()
			_check(view.encloses(r), "title button '%s' at %s is outside the window %s" % [b.text, r, view])
	var lb: Node = _find_named(_root, "LegendsButton")
	_check(lb != null, "no LEGENDS button on the title")
	if lb == null:
		return
	var open: bool = legends_open()
	var tab: Node = lb.get_node_or_null("GateTab")
	var tab_text: String = (tab.get_child(0) as Label).text if tab != null and tab.get_child_count() > 0 else "(none)"
	print("TITLE TEST legends: open %s (stars %d, gate %s), tab %s, legends.gd %s" % [open, Stars.total(),
			legends_gate_text(), tab_text, ResourceLoader.exists(LEGENDS_PATH)])
	_check((tab != null) == (not open), "the LEGENDS gate tab is %s on a %s mode" % [
			"shown" if tab != null else "missing", "open" if open else "locked"])
	if tab != null:
		_check(tab_text == legends_gate_text(), "the LEGENDS tab reads '%s'" % tab_text)
	if open:
		_test_legends_screen(get_tree())
		_press("LEGENDS")
		return
	_press("LEGENDS")
	var shown: bool = is_instance_valid(_legends_msg) and _legends_msg.visible
	print("TITLE TEST legends locked tap: screen %s, line '%s'" % [str(Flow.screen),
			_legends_msg.text if shown else "(none)"])
	_check(not _busy and str(Flow.screen) == "title", "the locked LEGENDS button left the title")
	_check(shown and _legends_msg.text == legends_locked_text(), "the locked LEGENDS tap showed no gate line")
	get_tree().create_timer(TEST_SHOT_DELAY).timeout.connect(func(): _shot("title_legends_locked"))

static func _test_legends_screen(tree: SceneTree) -> void:
	tree.create_timer(TEST_HOWTO_WAIT).timeout.connect(func():
		var node: Node = Flow.current_screen()
		print("TITLE TEST legends screen: screen=%s node=%s" % [str(Flow.screen),
				node.get_script().resource_path if node != null and node.get_script() != null else "none"])
		_check(str(Flow.screen) == LEGENDS_SCREEN, "LEGENDS did not open the legends screen")
		_shot("legends")
		var back: Button = _find_back(node)
		if back != null:
			print("TITLE TEST legends screen: BACK")
			back.emit_signal("pressed")
		else:
			print("TITLE TEST legends screen: Escape")
			var k := InputEventKey.new()
			k.keycode = KEY_ESCAPE
			k.pressed = true
			Input.parse_input_event(k)
		tree.create_timer(TEST_HOWTO_WAIT).timeout.connect(func():
			if str(Flow.screen) == LEGENDS_SCREEN:
				_check(false, "the legends screen's BACK did not leave it")
				Flow.go("title")))

static var _test_hall_done := false

# CREW & CREDITS shows HALL OF LEGENDS exactly when a legend is unlocked
func _test_check_hall_button() -> void:
	var n: int = legends_unlocked_count()
	var hb: Node = _find_named(_root, "HallButton")
	print("TITLE TEST crew: legends unlocked %d, HALL OF LEGENDS %s" % [n, "shown" if hb != null else "not shown"])
	_check((hb != null) == (n > 0), "HALL OF LEGENDS is %s with %d legends unlocked" % [
			"shown" if hb != null else "missing", n])
	if hb != null:
		_check(get_viewport().get_visible_rect().encloses((hb as Button).get_global_rect()),
				"HALL OF LEGENDS is outside the window")

# HALL OF LEGENDS opens "hall" with back = crew, and its BACK (Escape if none) lands on CREW & CREDITS again
static func _test_hall(tree: SceneTree) -> void:
	tree.create_timer(TEST_HOWTO_WAIT).timeout.connect(func():
		var node: Node = Flow.current_screen()
		print("TITLE TEST hall: screen=%s back=%s node=%s" % [str(Flow.screen), str(Flow.args.get("back", "")),
				node.get_script().resource_path if node != null and node.get_script() != null else "none"])
		_check(str(Flow.screen) == HALL_SCREEN, "HALL OF LEGENDS did not open the hall screen")
		_check(str(Flow.args.get("back", "")) == "crew", "HALL OF LEGENDS did not pass back = crew")
		_shot("hall")
		_test_hall_done = true
		var back: Button = _find_back(node)
		if back != null:
			print("TITLE TEST hall: BACK")
			back.emit_signal("pressed")
		else:
			print("TITLE TEST hall: Escape")
			var k := InputEventKey.new()
			k.keycode = KEY_ESCAPE
			k.pressed = true
			Input.parse_input_event(k)
		tree.create_timer(TEST_HOWTO_WAIT).timeout.connect(func():
			if str(Flow.screen) == HALL_SCREEN:   # where it landed is checked on CREW (step 13)
				_check(false, "the hall's BACK did not leave it")
				Flow.go("title")))

static func _find_named(node: Node, n: String) -> Node:
	if node == null:
		return null
	return node.find_child(n, true, false)

func _press(text: String) -> void:
	for b in _buttons:
		if is_instance_valid(b) and b.text == text and not b.disabled:
			b.emit_signal("pressed")
			return
	_check(false, "no button '%s'" % text)

static func _check(ok: bool, what: String) -> void:
	if ok:
		return
	_test_errors += 1
	push_error("TITLE TEST: " + what)

static func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tree := Engine.get_main_loop() as SceneTree
	var img: Image = tree.root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("/tmp/hoops_%s.png" % name)

# settings.cfg as it is now (or that there is none), so the end of the test puts it back byte for byte: the test
# presses MUSIC, FULL SCREEN, SOUND and LEVEL, which save at once (each pressed back, but the file is rewritten)
static func _test_keep_settings_file() -> void:
	if _test_cfg_taken:
		return
	_test_cfg_taken = true
	_test_cfg_had = FileAccess.file_exists(Difficulty.SAVE_PATH)
	if _test_cfg_had:
		_test_cfg_bytes = FileAccess.get_file_as_bytes(Difficulty.SAVE_PATH)

static func _test_restore_settings_file() -> void:
	if not _test_cfg_taken:
		return
	if _test_cfg_had:
		var f := FileAccess.open(Difficulty.SAVE_PATH, FileAccess.WRITE)
		if f != null:
			f.store_buffer(_test_cfg_bytes)
			f.close()
	elif FileAccess.file_exists(Difficulty.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Difficulty.SAVE_PATH))
	var same: bool = FileAccess.file_exists(Difficulty.SAVE_PATH) == _test_cfg_had
	if same and _test_cfg_had:
		same = FileAccess.get_file_as_bytes(Difficulty.SAVE_PATH) == _test_cfg_bytes
	print("TITLE TEST settings.cfg put back as it was: %s" % same)
	_check(same, "settings.cfg was not put back")

# How to Play (P7-H3): on its screen, page once (its auto_step()), then tap its BACK (Escape if it has none)
static func _test_howto(tree: SceneTree) -> void:
	tree.create_timer(TEST_HOWTO_WAIT).timeout.connect(func():
		var node: Node = Flow.current_screen()
		print("TITLE TEST how to play: screen=%s back=%s node=%s" % [str(Flow.screen), str(Flow.args.get("back", "")),
				node.get_script().resource_path if node != null and node.get_script() != null else "none"])
		_check(str(Flow.screen) == "howto", "HOW TO PLAY did not open the howto screen")
		_shot("howto")
		print("TITLE TEST how to play: next page %s" % Flow.auto_step())
		tree.create_timer(TEST_HOWTO_PAGE).timeout.connect(func():
			_shot("howto_page2")
			var back: Button = _find_back(Flow.current_screen())
			if back != null:
				print("TITLE TEST how to play: BACK")
				back.emit_signal("pressed")
			else:
				print("TITLE TEST how to play: Escape")
				var k := InputEventKey.new()
				k.keycode = KEY_ESCAPE
				k.pressed = true
				Input.parse_input_event(k)
			tree.create_timer(TEST_HOWTO_WAIT).timeout.connect(func():
				if str(Flow.screen) == "howto":
					_check(false, "How to Play BACK did not leave the screen")
					Flow.go("title"))))

static func _find_back(node: Node) -> Button:
	if node == null:
		return null
	if node is Button and (node as Button).text.strip_edges().to_upper().ends_with("BACK"):
		return node as Button
	for c in node.get_children():
		var b: Button = _find_back(c)
		if b != null:
			return b
	return null

# Every CC-BY row of CREDITS.md has a CREDITS_LIST entry with the same source URL and license (as many entries as
# rows per URL: the crowd and the loud crowd share one), with an author and the changes made
static func _test_check_credits() -> void:
	if not FileAccess.file_exists(CREDITS_FILE):
		print("TITLE TEST credits: %s not found, not checked" % CREDITS_FILE)
		return
	var url_re := RegEx.new()
	url_re.compile("https?://[^\\s,)`]+")
	var rows := {}       # "url|license" -> CC-BY rows in CREDITS.md
	for line in FileAccess.get_file_as_string(CREDITS_FILE).split("\n"):
		var cells: PackedStringArray = line.split("|")
		if cells.size() < 8 or not cells[5].contains("CC-BY"):
			continue
		var m: RegExMatch = url_re.search(cells[4])
		var lic: String = cells[5].strip_edges().split(" (")[0]
		var key: String = (m.get_string() if m != null else cells[4].strip_edges()) + "|" + lic
		rows[key] = int(rows.get(key, 0)) + 1
	var shown := {}
	for row in CREDITS_LIST:
		var e: Array = row
		if not str(e[3]).begins_with("CC-BY"):
			continue
		_check(str(e[2]) != "" and str(e[5]) != "" and LICENSE_URLS.has(str(e[3])),
				"credit '%s' lacks the author, changes or license link" % e[0])
		var key: String = str(e[4]) + "|" + str(e[3])
		shown[key] = int(shown.get(key, 0)) + 1
	var n := 0
	for key in rows:
		n += int(rows[key])
		_check(int(shown.get(key, 0)) >= int(rows[key]), "CC-BY credit missing on screen: " + str(key))
	print("TITLE TEST credits: %d CC-BY rows in CREDITS.md, %d CC-BY entries shown" % [n, _sum(shown)])

static func _sum(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n

# after QUICK GAME: the start panel (with its TITLE button) is up, and the LEFT-HANDED choice made in Settings
# reached the game; then every setting is put back and the test quits
static func _test_quick_game(tree: SceneTree) -> void:
	tree.create_timer(1.5).timeout.connect(func():
		print("TITLE TEST quick game: screen=%s start panel=%s" % [str(Flow.screen), not MenuScript.start_done])
		var game: Node = tree.current_scene
		var controls = game.get("controls") if game != null else null
		var ctl_lh = controls.get("left_handed") if controls != null else null
		print("TITLE TEST quick game: left_handed=%s, touch controls left_handed=%s" % [Difficulty.is_left_handed(),
				"n/a (before P7-03)" if ctl_lh == null else str(ctl_lh)])
		_check(Difficulty.is_left_handed(), "the LEFT-HANDED choice did not reach the game")
		if ctl_lh != null:
			_check(bool(ctl_lh), "the touch controls are not left-handed")
		_shot("quick_start")
		Difficulty.set_left_handed(false)   # back to how it was (a test run never saves it)
		_test_restore_settings_file()
		if _test_errors > 0:
			print("TITLE TEST FAILED: %d errors" % _test_errors)
			tree.quit(1)
			return
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
		draw_rect(Rect2(p + Vector2(70, 60), Vector2(10, maxf(20.0, ROAD_Y + 10.0 - p.y - 60.0))), Color(0.45, 0.45, 0.48))
		draw_rect(Rect2(p, Vector2(160, 70)), Color(0.10, 0.45, 0.25))
		draw_rect(Rect2(p + Vector2(4, 4), Vector2(152, 62)), Color.WHITE, false, 2.0)
		var font: Font = ThemeDB.fallback_font
		draw_string(font, p + Vector2(12, 30), "NEW YORK", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		draw_string(font, p + Vector2(12, 56), "1,100 MI  >", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
