extends Node2D
# Road Trip Hoops: 3v3 full court basketball.
# First to 21 (1 inside the arc, 2 beyond), switch sides at 11: the rules are in rules.gd.
# You control the BLUE team (the player with the yellow ring). BLUE shoots at the RIGHT hoop until the side switch
# at 11 (rules.sides_swapped), then at the left one. The arrow next to BLUE in the top bar shows the way.
#
# Touch: drag anywhere on the left half to move.
#   Offense: hold SHOOT, release in the green zone of the meter. PASS throws to the open teammate
#            (or the teammate in the direction you are pushing). Without the ball, CALL asks the teammate who has
#            it for a pass (a lob if you're cutting to the rim).
#   Defense: the orange button is STEAL or BLOCK (picked for you). STEAL pokes at the ball: poke when the dribble is
#            low and the ball is not behind his body. BLOCK (your man shoots, or is near the rim, and you're close)
#            jumps: time it so you're high when the ball leaves his hand. Don't bite on pump fakes. SWITCH changes player.
#   Fouls (rules.gd): a badly timed block jump into the shooter, or poking at a ball he shields with his body.
#   Free throws: hold SHOOT at the line and release in the green zone, as on a jump shot.
# Keyboard (for testing): WASD/arrows move, J = shoot/steal, K = pass/switch.
# Phase 5: _ready() first hands non-game screens to Flow.build_screen(). A trip game reads Flow.match (target, look,
# music, level, crew names, per-player sheet and ratings) and ends with Flow.game_finished(); Flow.match empty =
# Quick Game exactly as before. Test flags: -- --ratingtest, -- --city <id> --cgame N, -- --backtest (P7-10, the
# Android back gesture on every screen).

const PlayerScript = preload("res://scripts/player.gd")
const BallScript = preload("res://scripts/ball.gd")
const CourtScript = preload("res://scripts/court.gd")
const ControlsScript = preload("res://scripts/touch_controls.gd")
const AudioScript = preload("res://scripts/audio.gd")
const FxScript = preload("res://scripts/fx.gd")
const HumanInputScript = preload("res://scripts/human_input.gd")
const DefenseScript = preload("res://scripts/defense.gd")
const RulesScript = preload("res://scripts/rules.gd")
const MenuScript = preload("res://scripts/menu.gd")
const View = preload("res://scripts/view.gd")   # projection sim -> screen (FLAT / ANGLED), stick mapping (Phase 4)
const Looks = preload("res://scripts/court_looks.gd")   # court looks; Looks.music() is the court's music track
const Flow = preload("res://scripts/flow.gd")       # screens and the trip match (Phase 5). Always `Flow.match`:
                                                    # a bare `match` is the GDScript keyword
const Ratings = preload("res://scripts/ratings.gd") # stat formulas: rating 50 = x1.0 (Quick Game unchanged)
const Cities = preload("res://scripts/cities.gd")   # city data (names, targets) for the --city test flags
const Twists = preload("res://scripts/twists.gd")   # Phase 6 city twists: every twist hook is Twists.value(key, today)

const FT := 12.0                     # pixels per foot
const COURT_W := 94.0 * FT
const COURT_H := 50.0 * FT
const SHOT_CLOCK_LENGTH := 24.0      # seconds; the shot clock stays with first to 21 (Q1). Format: rules.gd. A twist
                                     # may change it (Twists "shot_clock": Memphis 18): read shot_clock_length()
const HUMAN_TEAM := 0
# field-goal make odds (shot_probability(); P7-T1 tuning round: too many misses). A jumper's base by distance, then the
# contest by the nearest defender's distance at the release. Dunks and layups aim at player.DUNK_OPEN_PCT /
# LAYUP_OPEN_PCT and get the lighter RIM_ contest (player.release_rim_shot mirrors the close base).
const SHOT_CLOSE_FT := 5.0           # inside this: the close base
const SHOT_CLOSE_BASE := 0.66        # a jumper inside SHOT_CLOSE_FT (and the base the rim moves divide out)
const SHOT_MID_BASE := 0.56          # inside the arc at SHOT_CLOSE_FT (P7-T1: 0.52 -> 0.56) ...
const SHOT_MID_FALLOFF := 0.0075     # ... minus this per foot further out
const SHOT_LONG_BASE := 0.42         # beyond the arc (P7-T1: 0.38 -> 0.42) ...
const SHOT_LONG_FALLOFF := 0.025     # ... minus this per foot beyond 23.75 ft (deep shots fall off fast)
const SHOT_MIN := 0.02               # odds never go under this (or over SHOT_CAP)
const SHOT_CAP := 0.92
const CONTEST_TIGHT_FT := 3.0        # nearest defender inside this: a full contest ...
const CONTEST_NEAR_FT := 6.0         # ... inside this: a light one
const CONTEST_TIGHT_MULT := 0.55     # jumper: odds x this with a full contest
const CONTEST_NEAR_MULT := 0.8       # jumper: odds x this with a light one
const RIM_CONTEST_TIGHT_MULT := 0.85 # dunk/layup with a full contest (P7-T1: was the jumper's 0.55; nearly every rim
                                     # move has a defender within 3 ft, so this set most rim misses)
const RIM_CONTEST_NEAR_MULT := 0.9   # dunk/layup with a light contest (P7-T1: was the jumper's 0.8)
# Team names in the top bar and the messages. A var (rules.gd, menu.gd read game.TEAM_NAMES): a trip game puts the
# crew names from Flow.match here (owner Q11 a); a Quick Game its picked crews' names (P6-T3); BLUE / RED only when
# trip.gd can't build the crews.
var TEAM_NAMES: Array = ["BLUE", "RED"]
var quick_teams: Array = []         # P6-T3: a Quick Game's two crews (Trip.quick_team() dicts); [] in a trip game
const TEAM_COLORS := [Color(0.7, 0.88, 1.0), Color(1.0, 0.42, 0.38)]   # popups and score messages

# game-event feedback (P1-06)
const SCORE_POPUP_SIZE := 64         # font size of the "+1"/"+2" popup at the hoop
const SCORE_POPUP_RISE := 3.0 * FT   # popup starts this far above the rim
const SCORE_MSG_TIME := 0.8          # the center "BLUE SCORES" message is short, the popup carries it
const BLOCK_SHAKE := 6.0             # screen shake on a block: strength in pixels
const BLOCK_SHAKE_TIME := 0.25       # and how long it lasts
const MSG_FONT_SIZE := 56            # center message font size
const MSG_POP_TIME := 0.15           # center message scale-in time in seconds
const MSG_POP_SCALE := 1.35          # center message start scale
const SIDE_ARROW_RIGHT := ">>"       # top bar: next to BLUE, the way BLUE attacks (P3-02)
const SIDE_ARROW_LEFT := "<<"

# camera (P4-01, framing P4-11). FLAT keeps the old top-down camera. ANGLED follows the owner's framing (Q1 a): the
# camera follows the ball left and right, about 2/3 of the court length on screen, both sidelines always visible (it
# doesn't move up and down), and it stays on the same sideline at the side switch (Q2 a, View.SIDE_FLIP false).
# View.TILT_Y 0.48 makes the court 288 px deep; with zoom 1.68 the 1280x720 screen shows 762 px = 63.5 ft (68% of the
# court length) and 429 px of height: HUD bar 32 + far players' heads 84 + court 288 + near margin 24 = 428.
# v2 sheets (heads about 100 px, P6-26) need 104 over the far sideline (frame 448 px): 1280x720 zoomed out to 1.60.
# P6-T1 (owner: closer again): zoom 1.72 shows 744 px (62 ft) and 419 px of height, 29 px short of the frame, so
# the camera slides those 29 px up and down with the ball's depth (CAM_DEPTH_SLACK_FT). A far player's head reaches
# under the (translucent) HUD bar only while the ball is at the near sideline. 1280x800 (stretch expand) fits the
# whole frame at 1.72: no slide, the framing grows evenly and the court stays centered.
const CAM_ZOOM_FLAT := 1.15          # FLAT: the old zoom
const CAM_ZOOM := 1.72               # ANGLED zoom (at most; P6-T1: a bit closer than Phase 5's 1.68 at 1280x720)
const CAM_ZOOM_MIN := 1.2            # ANGLED: never zoom out further than this to fit (then it follows up and down)
const CAM_SMOOTHING := 4.0           # Camera2D position smoothing speed (both modes, as today)
const CAM_FOLLOW_X := 1.0            # ANGLED: 1 = the camera follows the ball left/right, 0 = stays at half court
const CAM_FOLLOW_Y := 0.0            # ANGLED: 0 = fixed depth (both sidelines in view), 1 = follows the ball up/down
                                     # (it follows anyway on a screen too short to show both sidelines)
const CAM_MARGIN_FT := 2.0           # ANGLED: room past the baselines and the near sideline (feet, floor)
const CAM_TOP_FT := 7.0              # ANGLED: room above the far sideline for the players standing on it (feet, height),
                                     # at least: taller sheets (v2) raise it to their head plus CAM_TOP_PAD_PX (P6-26)
const CAM_TOP_PAD_PX := 4.0          # ANGLED: room over the tallest far head (sim px of height), under the HUD bar
                                     # (v1: 80 + 4 = CAM_TOP_FT exactly; v2 about 104)
const CAM_DEPTH_SLACK_FT := 3.0      # ANGLED (P6-T1): how much of the framed height (far heads + court + near margin,
                                     # feet of floor) the screen may lack before zooming out; the camera then slides up
                                     # and down over that bit with the ball's depth (far heads in view when the ball is
                                     # far, the near margin when it is near). 1280x720: zoom 1.72 and ~29 px of slide
const CAM_HUD_PX := 54.0             # the HUD top bar (screen px): the far sideline stays below it
const FPS_PRINT_EVERY := 5.0         # -- --fps: seconds between "FPS n" lines

# on fire (P1-07)
const FIRE_STREAK := 3               # makes in a row by one player (dunks and layups count) to catch fire
const FIRE_MISSES := 2               # misses or blocks by the on-fire player that put the fire out (a make resets)
const FIRE_COLOR := Color(1.0, 0.45, 0.1)   # "ON FIRE!" popup and the ball trail
const FIRE_POPUP_SIZE := 52

# skill-based steals (P2-04). Owner (Q6): the poke's timing and the ball's exposure decide a good or a bad attempt,
# and the defender's steal rating scales a good one. Same rule for the human and the CPU.
const STEAL_REACH_FT := 2.5          # the defender must be this close to the BALL (not the handler's body)
const STEAL_BALL_PX := 15.0          # where the dribble is when the ball isn't held by this handler (ball.gd draws it here)
const STEAL_POKE_PX := 40.0          # a poke further than this from the handler is no poke at all (nothing happens)
const STEAL_OPEN_DEG := 60.0         # angle between handler->ball and handler->defender: under this the ball is fully exposed
const STEAL_SHIELD_DEG := 120.0      # over this the handler's body shields the ball (exposure 0); linear between
const STEAL_BASE := 0.7              # success chance of a fully exposed poke by a defender with steal rating 50
const STEAL_RATING_SPAN := 0.2       # steal rating 0 gives STEAL_BASE - this, rating 100 gives STEAL_BASE + this
const STEAL_LUCK := 1.0              # 1: chance grows with exposure; 0: pure skill (good poke always works, bad never)
const STEAL_GOOD_EXPOSURE := 0.5     # exposure x timing at or above this is a good poke (counted; decides alone at STEAL_LUCK 0)
const STEAL_CROSS_MULT := 1.6        # handler in a crossover: the ball crosses in front of the body
const STEAL_SPIN_MULT := 0.3         # handler in a spin move: the ball is protected
const STEAL_TURBO_MULT := 1.3        # handler sprinting
const STEAL_FAKE_MULT := 1.3         # handler in a pump fake
const STEAL_MAX_CHANCE := 0.95
const STEAL_POKE_FREEZE := 0.3      # seconds a defender stands still after every steal attempt, hit or miss (owner)
const STEAL_COOLDOWN := 0.7          # seconds between pokes by one defender
# timing: a poke is well timed within STEAL_GRACE seconds of a floor touch of the dribble (time based, so it doesn't
# depend on the frame rate). The STEAL button lights up while the human's poke would be well timed.
# Set STEAL_TIMING false to judge pokes by exposure only.
const STEAL_TIMING := true
const DRIBBLE_PERIOD := PI / 9.0     # seconds between floor touches; must match ball.gd (z = 4 + |sin(anim_time * 9)| * 16)
const STEAL_GRACE := 0.04            # human: seconds before a floor touch that count as a well-timed poke (P2.5: was 0.05)
const STEAL_HUMAN_LATE := 0.10       # human: seconds after a floor touch that still count (P2.5: was 0.05; a thumb
                                     # reacts to the lit button a little late). Window 0.14 s = 40% of the 0.35 s
                                     # dribble (was 0.10 s, 29%); the STEAL button and the ring under the ball stay lit
                                     # ~8 frames per bounce instead of ~6
const STEAL_CPU_GRACE := 0.05        # CPU pokes: seconds either side of a floor touch (unchanged; defense.gd times them)
const STEAL_HUMAN_BONUS := 0.12      # human (P2.5): a well-timed poke's success chance + this (rating 50: 0.7 -> 0.82)
const STEAL_HUMAN_LUCK := 0.5        # human (P2.5): STEAL_LUCK for the human's pokes; a good poke depends less on how
                                     # exposed the ball is (CPU keeps STEAL_LUCK)
const STEAL_CUE_RING_COLOR := Color(1.0, 0.95, 0.4, 0.9)   # ring on the floor under the ball while STEAL is lit
const STEAL_HELD_TIMING := 0.25      # timing factor when the ball is held up (gathering a shot, pump fake, at the rim)

# fouls and free throws (P3-05; the sequence and the counts are in rules.gd). Owner Q3: fouls come from bad timing only
const REACH_FOULS := true            # a poke that reaches a ball shielded by the handler's body can be a reaching foul
const FT_BASE := 0.72                # free throw made chance at quality 1.0 (normal release); no contest, no blocks
const FT_CAP := 0.95                 # at most this (a perfect release is quality 1.3: 0.94)
const FT_PERFECT_Q := 1.25           # a free throw at or above this quality counts as a perfect release (human_ft_perfect)
const FORCE_FOUL_CHANCE := 0.12      # test only (-- --force-fouls): a released field goal is fouled with this chance
const HT_FT_GOOD_CHARGE := 0.865     # --humantest at the line: release a "good" free throw at this meter charge
                                     # (middle of the 0.78-0.95 green zone) ...
const HT_FT_EARLY_CHARGE := 0.5      # ... and an "early" one here (a bad release, quality 0.6)
const HT_FT_DELAY := 0.5             # seconds the scripted thumb waits at the line before pressing SHOOT
const FT_LABEL_COLOR := Color(1.0, 0.92, 0.45)

# call for the ball (P2-10). human_input.gd has the call rules; main.gd decides who the human controls and draws the cue
const CONTROL_FOLLOWS_CATCH := false # false: a teammate who gets the ball (inbound, rebound, steal, CPU pass) runs it
                                     # and you keep your player and CALL for it; true: you always take over the ball
                                     # (Phase 1 behavior). Your own PASS always hands control to the receiver.
const CALL_CUE_GAP := 20.0           # the "!" bubble's tail tip: this far (screen px) over the caller's drawn head, above
                                     # player.gd's arrow (head - 16..6); the head is read from the sheet (v1 80, v2 ~100)
const CALL_CUE_TAIL := 18.0          # the bubble's center this far above its tail tip (screen px)
const CALL_CUE_COLOR := Color(1.0, 0.92, 0.3)
const MENUSHOT_FRAMES := 40          # test only (--menushot): frames the panel is up before its screenshot

# Phase 5 hooks (P5-02): the trip match (Flow.match), the pause screen, the --city test flags
const TRIP_PATH := "res://scripts/trip.gd"      # P5-05: Trip.match_for(city, n) builds Flow.match (if it exists)
const PAUSE_PATH := "res://scripts/pause.gd"    # P5-08: added to the HUD if the file exists
# P7-10: the Android back gesture (NOTIFICATION_WM_GO_BACK_REQUEST; project.godot has quit_on_go_back = false)
const BACKTEST_FLAG := "--backtest"  # test only: sends the back request on every screen and checks where it lands
const BACKTEST_ARM_FRAMES := 90      # frames on a screen before the request (every screen's tap guard has passed)
const BACKTEST_LAND_FRAMES := 30     # frames after the request before the check (a Flow.go reload has happened)
const BACKTEST_GAME_WAIT := 1200     # most frames to wait in a game for the pause to be allowed (tip-off)
static var _backtest_node: Node = null   # the --backtest driver (on the root, survives the reloads)
const TOP_BAR_FONT_TRIP := 24       # top bar font in a trip game (crew names are longer than BLUE / RED; Quick Game 30)
# --city <id> --cgame N without trip.gd: this hand-built match (your 3 underdogs vs a Hometown-like crew; ratings
# near the contract's example). The flags set its label, target, look and music from cities.gd. Sheets fall back to
# blue_n / red_n until the art exists (player.gd, P5-03).
const TEST_MATCH := {
	"mode": "trip", "label": "HOMETOWN - GAME 1 OF 3", "target": 11, "look": "blacktop", "music": "hometown",
	"level": "normal",
	"teams": [
		{"name": "CORNFIELD KINGS", "style": "", "players": [
			{"id": "ud_deuce", "name": "DEUCE", "sheet": "ud_deuce", "ratings": {"speed": 55, "shooting": 62,
				"finishing": 50, "defense": 48, "stamina": 50, "steal": 58, "block": 38}},
			{"id": "ud_jojo", "name": "JOJO", "sheet": "ud_jojo", "ratings": {"speed": 62, "shooting": 52,
				"finishing": 48, "defense": 50, "stamina": 55, "steal": 65, "block": 35}},
			{"id": "ud_tank", "name": "TANK", "sheet": "ud_tank", "ratings": {"speed": 45, "shooting": 40,
				"finishing": 60, "defense": 58, "stamina": 50, "steal": 40, "block": 72}}]},
		{"name": "COUNTY LINE", "style": "balanced", "players": [
			{"id": "ht_g1", "name": "SKIP", "sheet": "ht_g1", "ratings": {"speed": 56, "shooting": 56,
				"finishing": 44, "defense": 44, "stamina": 44, "steal": 54, "block": 34}},
			{"id": "ht_a1", "name": "DALE", "sheet": "ht_a1", "ratings": {"speed": 40, "shooting": 40,
				"finishing": 40, "defense": 40, "stamina": 40, "steal": 45, "block": 35}},
			{"id": "ht_a2", "name": "RUSTY", "sheet": "ht_a2", "ratings": {"speed": 40, "shooting": 40,
				"finishing": 40, "defense": 40, "stamina": 40, "steal": 35, "block": 50}}]},
	],
}
# Phase 6 hooks (P6-02): the twist, its banner and effects, the camera punch, the --anim-test driver
const TWIST_FX_PATH := "res://scripts/twist_fx.gd"    # P6-14: added to the game when a twist is on (if the file exists)
const ANIM_TEST_PATH := "res://scripts/anim_test.gd"  # P6-24: -- --anim-test adds it to the game (if the file exists)
const HOWTO_SHOTS_PATH := "res://scripts/howto_shots.gd"  # P7-H1: -- --howto-shots DIR adds it to a seeded humantest game
const HOWTO_SHOTS_FLAG := "--howto-shots"
const HOWTO_SEED := 7031             # P7-H1: fixed seed of a --howto-shots game (the same pictures on every rerun)
const TWIST_LINE_SIZE := 28          # the twist's banner line under the tip-off message (font size)
const TWIST_LINE_TIME := 3.5         # seconds it shows at tip-off (fades out over the last TWIST_LINE_FADE)
const TWIST_LINE_FADE := 0.6
const TWIST_LINE_COLOR := Color(1.0, 0.9, 0.55)
# Quick Game settings a trip game overrides (static, so they survive reload_current_scene): put back when a game
# without a trip match starts, so a Quick Game after a trip game has the saved court and level again
static var _quick_look := ""
static var _quick_level := -1

# --humantest scripted thumb (developer testing only): drives the real touch joystick with synthetic touch events
const HT_FINGER_POS := Vector2(260, 460)   # where the scripted thumb touches down (left half of the screen; mirrored by controls.mirror_x() when left-handed)
const HT_STEER_RATE := 450.0         # degrees per second the thumb turns while steering (a flick needs 100 in 0.12 s)
const HT_SNAP_EVERY := 3.0           # seconds of ball time between 120-degree snaps (should each be one flick)
const HT_SNAP_DEG := 120.0
const HT_SNAP_FRAMES := 3
const HT_TURN_EVERY := 5.0           # seconds of ball time between a smooth 180-degree turn + a radial pull (no flicks)
const HT_TURN_TIME := 0.4
const HT_PULL_FROM := 0.8            # radial pull: finger distance in ring radii, from ...
const HT_PULL_TO := 1.6              # ... to (past touch_controls.TURBO_PULL, so turbo comes on)
const HT_PULL_TIME := 0.3
const HT_PULL_HOLD := 0.3
const HT_TAP_EVERY := 4.0            # seconds of ball time between short A taps (pump fake input) outside the rim range
const HT_TAP_FRAMES := 5
const HT_SHOOT_MAX_FT := 24.0        # the scripted human only shoots or taps A with the ball inside this distance
const HT_TIMED_POKE_GAP := 20.0      # seconds between the scripted human's well-timed pokes (low dribble, ball exposed)
const HT_CALL_EVERY := 3.0           # on offense without the ball: press CALL every this many seconds
const HT_LOB_GAP := 6.0              # with the ball: pass to a teammate near the rim at most this often (alley-oop try)
const HT_LOB_FT := 12.0              # "near the rim" for that pass
const HT_BLOCK_DELAY := 0.15         # on defense: press BLOCK this long after a CPU shot starts (every 2nd shot; else at once)
const HT_EARLY_DRIVE_SPEED := 0.4    # "early" block turn: a CPU handler driving at his rim at this fraction of top speed
const HT_EARLY_HOLD := 1.0           # ... after that early jump, his take-off within this many seconds isn't a new try
const HT_AWAY_EVERY := 6.0           # on defense: every this many seconds, steer away from the handler ...
const HT_AWAY_TIME := 0.7            # ... for this long (the defensive assist must not hold him)
const HT_GUARD_FT := 8.0             # stay-in-front metric: a CPU handler (frontcourt) this close to the human is "guarded"
const HT_BEAT_MARGIN_FT := 1.0       # ... and he is past the human once he is this much closer to the rim (hysteresis)

var hoops := [Vector2(5.25 * FT, COURT_H / 2), Vector2(COURT_W - 5.25 * FT, COURT_H / 2)]

var rng := RandomNumberGenerator.new()
var players: Array = []
var teams := [[], []]
var ball
var controls
var camera: Camera2D
var audio                           # sound effects: audio.play("swish")
var fx                              # shake, popups, ball trail: fx.shake(6.0, 0.3)
var input                           # human_input.gd: buttons, pass target, switch, flick and tap detection
var rims                            # court instance that draws rims and nets: rims.swish(hoop_index)
var rules                           # rules.gd: format, score changes, side switch, dead balls, inbounds
var score := [0, 0]                 # changed only by rules.add_score()
var shot_clock := SHOT_CLOCK_LENGTH
var shot_clock_running := true
var possession := 0
var human_player = null
var game_over := false
var autoplay := false
var chasers := []
var key_a_down := false
var stats := {}
var _trail_on := false              # fire trail currently shown behind the ball
var humantest := false
# humantest scripted thumb state
var ht_angle := 0.0
var ht_dist := 1.0
var ht_mode := ""                   # "", "snap", "turn", "pull", "tap"
var ht_t := 0.0
var ht_frames := 0
var ht_ok := true                   # the human could flick on every frame of the current snap
var ht_snap_clock := 0.0
var ht_turn_clock := 0.0
var ht_tap_clock := 0.0
var ht_poke_wait := 0.0
var ht_block_wait := -1.0           # seconds until the scripted human presses BLOCK (< 0 = none planned)
var ht_block_n := 0                 # CPU shots seen by the block script (alternates timed / early)
var ht_jump_kind := "random"        # what the last scripted press that jumped was: "random", "timed" or "early"
var ht_threat_shooting := false
var ht_pre_t := 0.0                 # an early jump at a drive was just scripted: don't count his take-off as a new try
var ht_jump_phase := ""             # what the shooter was doing at the scripted block press: "shot", "fake", "rim"
var ht_call_clock := 0.0
var ht_lob_wait := 0.0
var ht_away_clock := 0.0
var ht_away_t := 0.0
var ht_guard_on := false            # stay-in-front metric: guarding a handler this frame
var ht_guard_front := true          # ... and the human is between him and the rim
var ht_guard_holder = null
var _call_node: Node2D               # draws the "!" over the human while his call is live (in overlay)
var _steal_node: Node2D              # draws the lit-STEAL ring on the floor under the ball (decals; FLAT: overlay)
# drawing layers (P4-01, see the Shared contract in docs/BOARD.md). All Node2D children of main.
var floor_layer: Node2D              # z -10: the court floor
var decals: Node2D                   # z -5: things lying on the floor under everyone (shadows, rings, dust, steal cue)
var world: Node2D                    # z 0, y-sorted: upright things, each positioned at its projected floor point
var overlay: Node2D                  # z 30: cues, arrow, stamina bar, shot meter; always on top, never sorted
var fps_print := false               # test only (-- --fps): print "FPS n" every FPS_PRINT_EVERY seconds
var _fps_t := 0.0
var shot_serial := 0                # counts released shots, so each defender gets one block try per shot (defense.gd)
var menu                            # menu.gd: the EASY / NORMAL / HARD panel (launch and game over, P3-08)
var pause_node: Node = null         # pause.gd (P5-08), null in CPU-only games; the back gesture closes it (P7-10)
var menu_wait := false             # the launch panel is up: the game waits behind it
var menushot := false               # test only (-- --menushot): screenshots of both panels, see _debug_screenshots
var _menu_frames := 0
var force_fouls := false            # test only: -- --force-fouls fouls some field goals (until P3-06 commits fouls)
var ht_ft_t := 0.0                  # humantest: seconds the human has had the ball at the line
var ht_ft_n := 0                    # humantest: free throws the scripted thumb started (every 2nd is "good")
var ht_ft_kind := ""                # humantest: "good" or "early" for the free throw on the meter now
var twist_fx                         # P6-14 twist_fx.gd node (null: no twist or no file)
var anim_test := false               # test only (-- --anim-test): the animation driver runs on this game
var howto_shots := false             # test only (-- --howto-shots DIR, P7-H1): the How to Play capture driver watches
var twist_label: Label               # the twist's banner line under the tip-off message
var _twist_line_t := 0.0

func stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

func stat_add(k: String, n: int) -> void:
	stats[k] = stats.get(k, 0) + n

var score_label: Label
var clock_label: Label
var shot_label: Label
var msg_label: Label
var ft_label: Label
var msg_timer := 0.0
var msg_age := 0.0

# ---------------- setup ----------------

func _ready() -> void:
	rng.randomize()
	_parse_view_args()
	if OS.get_cmdline_user_args().has("--viewtest"):
		_viewtest()
		return
	if OS.get_cmdline_user_args().has("--ratingtest"):
		_ratingtest()
		return
	if OS.get_cmdline_user_args().has("--triptest-data"):
		# test only: prints every city game's lineups and ratings and checks the trip rules and save cases
		var trip_script = load("res://scripts/trip.gd")
		var ok: bool = trip_script.self_test(OS.get_cmdline_user_args().has("--load"))
		print("TRIPDATA ", "OK" if ok else "FAILED")
		set_physics_process(false)
		set_process(false)
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--startest"):
		var ok_s: bool = load("res://scripts/stars.gd").self_test()   # test only: the star store and ladder (P8-02)
		set_physics_process(false)
		set_process(false)
		get_tree().quit(0 if ok_s else 1)
		return
	if OS.get_cmdline_user_args().has("--cosmetictest"):
		var ok_c: bool = load("res://scripts/cosmetics.gd").self_test()   # test only: the cosmetics store (P8-03)
		set_physics_process(false)
		set_process(false)
		get_tree().quit(0 if ok_c else 1)
		return
	if OS.get_cmdline_user_args().has("--twisttest"):
		var ok_t: bool = Twists.self_test()   # test only: the twist table's defaults (P6-01)
		set_physics_process(false)
		set_process(false)
		get_tree().quit(0 if ok_t else 1)
		return
	# test only (-- --anim-test, P6-24): a game is built (CPU vs CPU, no panels) and the driver added to it
	anim_test = OS.get_cmdline_user_args().has("--anim-test")
	if anim_test:
		if not ResourceLoader.exists(ANIM_TEST_PATH):
			print("ANIM TEST: %s is missing" % ANIM_TEST_PATH)
			set_physics_process(false)
			set_process(false)
			get_tree().quit(1)
			return
		Flow.screen = Flow.GAME
	# test only (-- --howto-shots DIR, P7-H1): a --humantest game with fixed seeds, watched by howto_shots.gd
	howto_shots = OS.get_cmdline_user_args().has(HOWTO_SHOTS_FLAG) and ResourceLoader.exists(HOWTO_SHOTS_PATH)
	if howto_shots:
		Flow.screen = Flow.GAME
		rng.seed = HOWTO_SEED
		seed(HOWTO_SEED)
	if OS.get_cmdline_user_args().has(BACKTEST_FLAG) and _backtest_node == null:
		_backtest_node = BackTest.new()   # test only (P7-10): starts on the title, walks the screens
		get_tree().root.add_child.call_deferred(_backtest_node)
	# screen hand-off (Phase 5): the test modes play a game at once, as before; otherwise Flow decides the screen
	if Flow.skip_title():
		Flow.screen = Flow.GAME
	if Flow.screen != Flow.GAME:
		set_physics_process(false)   # no game here: the screen node runs itself
		set_process(false)
		set_process_unhandled_input(false)
		Flow.build_screen(self)   # title, map, story, ...: that screen's node and its music; no court
		return
	_parse_city_args()   # --city <id> --cgame N: Flow.match = that trip matchup
	autoplay = OS.get_cmdline_user_args().has("--autoplay") or _city_autoplay() or anim_test
	humantest = OS.get_cmdline_user_args().has("--humantest") or howto_shots
	force_fouls = OS.get_cmdline_user_args().has("--force-fouls")
	menushot = OS.get_cmdline_user_args().has("--menushot")
	Flow.attach_test(self)   # --trip-test: the driver (trip_test.gd, P5-15) watches this game too
	MenuScript.prepare_level()   # before the players: first launch = Normal, then the saved level, then --difficulty
	MenuScript.prepare_settings()   # before the court: the saved court look (-- --court wins) and music on/off
	_apply_match_settings()      # a trip game: its court look and level (a Quick Game gets the saved ones back)
	_apply_twist()               # before the players and the ball: the twist's numbers are read at setup

	rules = RulesScript.new()
	rules.game = self
	add_child(rules)
	_apply_match_rules()         # a trip game: its target and the crew names
	_apply_quick_teams()         # a Quick Game: the picked crews (P6-T3), before the players

	audio = AudioScript.new()
	audio.game = self
	add_child(audio)
	audio.set_music_on(MenuScript.music_on)

	floor_layer = _make_layer("FloorLayer", -10)
	decals = _make_layer("Decals", -5)
	world = _make_layer("World", 0)
	world.y_sort_enabled = true        # children sit at their projected floor point: y-sort = depth sort
	overlay = _make_layer("Overlay", 30)

	var floor_node = CourtScript.new()
	floor_node.game = self
	floor_layer.add_child(floor_node)
	rims = CourtScript.new()
	rims.game = self
	rims.draw_rims = true
	rims.z_index = 15
	add_child(rims)

	var looks := [[1, 3, 5], [2, 4, 1]]
	for t in 2:
		for i in 3:
			var p = PlayerScript.new()
			var color := "blue" if t == 0 else "red"
			_setup_player(p, t, i, load("res://assets/%s_%d.png" % [color, looks[t][i]]), _match_player(t, i))
			add_child(p)
			players.append(p)
			teams[t].append(p)

	ball = BallScript.new()
	ball.setup(self)
	add_child(ball)

	camera = Camera2D.new()
	var zm: float = CAM_ZOOM if View.angled() else CAM_ZOOM_FLAT
	camera.zoom = Vector2(zm, zm)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAM_SMOOTHING
	camera.limit_left = int(-6 * FT)
	camera.limit_top = int(-10 * FT)
	camera.limit_right = int(COURT_W + 6 * FT)
	camera.limit_bottom = int(COURT_H + 10 * FT)
	add_child(camera)
	camera.make_current()

	fx = FxScript.new()
	fx.game = self
	add_child(fx)

	input = HumanInputScript.new()
	input.game = self
	add_child(input)

	_call_node = Node2D.new()          # in overlay (z 30): over the players and the ball, under the fx popups
	_call_node.draw.connect(_draw_call_cue)
	overlay.add_child(_call_node)
	_steal_node = Node2D.new()         # ANGLED: in decals (a ring on the floor, under the upright players);
	_steal_node.draw.connect(_draw_steal_cue)   # FLAT: in overlay as before, where top-down sprites would hide it
	(decals if View.angled() else overlay).add_child(_steal_node)

	_build_hud()
	_add_twist_fx()
	menu = MenuScript.new()
	menu.game = self
	add_child(menu)
	shot_clock = shot_clock_length()
	start_game()
	if Flow.in_trip() and str(Flow.match.get("label", "")) != "":
		show_message(str(Flow.match.get("label", "")), rules.START_MSG_TIME)   # instead of "FIRST TO N"
	_add_anim_test()
	if howto_shots:
		var hs = (load(HOWTO_SHOTS_PATH) as GDScript).new()
		hs.main = self
		add_child(hs)
	if View.angled():
		_update_camera()               # set the ANGLED zoom and limits and start on the ball
		camera.reset_smoothing()
	# the launch panel: once per run, never in the headless tests (or --shots, unless -- --menushot), never in a trip
	# game (the lineup screen came before it)
	var shots_run: bool = OS.get_cmdline_user_args().has("--shots") or OS.get_cmdline_user_args().has("--ballshots")
	var tests: bool = autoplay or humantest or (shots_run and not menushot) or Flow.in_trip()
	if not tests and not MenuScript.start_done:
		menu_wait = true
		msg_label.visible = false   # no "FIRST TO 21" under the panel; the reloaded game shows it
		_menu_input(true)
		menu.show_start()
	elif not tests:
		MenuScript.start_done = true
	if not menu_wait:
		_play_court_music()
		_show_twist_banner()   # (behind the launch panel it would be hidden: the reloaded game shows it)

# in play: the court's track, softly (owner Q5 a). The panels play the menu music (menu.gd)
func _play_court_music() -> void:
	var track: String = Looks.music()
	if Flow.in_trip() and str(Flow.match.get("music", "")) != "":
		track = str(Flow.match.get("music", ""))   # the city's track
	audio.play_music(track)
	audio.set_music_ducked(true)

# ---------------- Phase 5: the trip match (Flow.match) ----------------
# With Flow.match empty (Quick Game, the tests) none of this changes anything.

# player i of team t from Flow.match ({} in Quick Game): {"id", "name", "sheet", "ratings": {...}}
func _match_player(t: int, i: int) -> Dictionary:
	if not Flow.in_trip():
		return _quick_player(t, i)
	var tms: Array = Flow.match.get("teams", [])
	if t >= tms.size():
		return {}
	var tm: Dictionary = tms[t]
	var ps: Array = tm.get("players", [])
	if i >= ps.size() or not (ps[i] is Dictionary):
		return {}
	return ps[i]

# ---------------- P6-T3: Quick Game teams ----------------
# A Quick Game (no trip match) fields the two crews picked on the menu panel (menu.gd quick_team_ids(): the Kings vs
# the Bridge Runners by default, --quick-teams <blue>,<red> in tests), built by Trip.quick_team(): the crew's
# players, sheets in its own colors, ratings averaging 50 per player. The crew names go to the top bar like a trip
# game's. Nothing else of the trip match is used (court, level, music and twist stay the Quick Game's).

# player i of team t of the Quick Game crews ({} when there are none)
func _quick_player(t: int, i: int) -> Dictionary:
	if quick_teams.size() != 2:
		return {}
	var ps: Array = (quick_teams[t] as Dictionary).get("players", [])
	if i >= ps.size() or not (ps[i] is Dictionary):
		return {}
	return ps[i]

func _apply_quick_teams() -> void:
	quick_teams = []
	MenuScript.Difficulty.quick_styles = []
	if Flow.in_trip() or not ResourceLoader.exists(TRIP_PATH):
		return
	var trip: GDScript = load(TRIP_PATH) as GDScript
	if trip == null or not trip.has_method("quick_team"):
		return
	var ids: Array = MenuScript.quick_team_ids()
	var built: Array = []
	for t in 2:
		var tm = trip.call("quick_team", str(ids[t]))
		if not (tm is Dictionary) or ((tm as Dictionary).get("players", []) as Array).size() != 3:
			print("QUICK TEAMS: no team '%s', playing BLUE vs RED" % str(ids[t]))
			return
		built.append(tm)
	quick_teams = built
	for t in 2:
		TEAM_NAMES[t] = str((built[t] as Dictionary).get("name", TEAM_NAMES[t]))
		MenuScript.Difficulty.quick_styles.append(str((built[t] as Dictionary).get("style", "")))
	if autoplay or humantest:
		var lines: Array = []
		for t in 2:
			var ps: Array = []
			for p in (built[t] as Dictionary).get("players", []):
				var r: Dictionary = (p as Dictionary).get("ratings", {})
				ps.append("%s %d/%d/%d/%d/%d" % [str(p.get("name", "")), int(r.get("speed", 0)), int(r.get("shooting", 0)),
						int(r.get("finishing", 0)), int(r.get("defense", 0)), int(r.get("stamina", 0))])
			lines.append("%s (%s)" % [TEAM_NAMES[t], ", ".join(PackedStringArray(ps))])
		print("QUICK TEAMS %s vs %s | spd/sht/fin/def/sta | RED style %s" % [lines[0], lines[1],
				MenuScript.Difficulty.team_style(1) if MenuScript.Difficulty.team_style(1) != "" else "-"])

# the top bar shows crew names (smaller font): a trip game, or a Quick Game with its crews
func _crew_names() -> bool:
	return Flow.in_trip() or quick_teams.size() == 2

# player.setup() with the player dict (P5-03 adds the optional 5th argument: sheet and ratings). Called the old way
# when the dict is empty or player.gd doesn't take it yet; then the dict's ratings are copied in here, so steal,
# block and shooting work before P5-03 lands.
func _setup_player(p, t: int, i: int, tex: Texture2D, pdata: Dictionary) -> void:
	var n_args := 0
	for m in p.get_method_list():
		if m.name == "setup":
			n_args = (m.args as Array).size()
	if pdata.size() > 0 and n_args >= 5:
		p.setup(self, t, i, tex, pdata)
		return
	p.setup(self, t, i, tex)
	var r = pdata.get("ratings", {})
	if r is Dictionary:
		for k in r:
			p.ratings[k] = int(r[k])

# before the court and the players: a trip game's court look and level (Difficulty for team 1, owner Q4; a
# --difficulty flag wins, for tests). A game without a trip match gets the Quick Game look and level back.
func _apply_match_settings() -> void:
	var diff = MenuScript.Difficulty
	if not Flow.in_trip():
		if _quick_look != "":
			Looks.set_current(_quick_look)
			_quick_look = ""
		if _quick_level >= 0:
			diff.level = _quick_level
			_quick_level = -1
		return
	var look: String = str(Flow.match.get("look", ""))
	if look != "":
		if _quick_look == "":
			_quick_look = Looks.current
		Looks.set_current(look)
	var lv: int = diff.parse(str(Flow.match.get("level", "")))
	if lv >= 0 and not _has_difficulty_flag():
		if _quick_level < 0:
			_quick_level = diff.level
		diff.level = lv

func _has_difficulty_flag() -> bool:
	for a in OS.get_cmdline_user_args():
		if a == "--difficulty" or a.begins_with("--difficulty="):
			return true
	return false

func _difficulty_flag_value() -> String:
	return _flag_value("--difficulty")

# the value of a test flag given as `--name value` or `--name=value` (lower case), or ""
func _flag_value(flag_name: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		if args[i].begins_with(flag_name + "="):
			return args[i].get_slice("=", 1).to_lower()
		if args[i] == flag_name and i + 1 < args.size():
			return args[i + 1].to_lower()
	return ""

# ---------------- Phase 6: the twist (P6-02) ----------------

# the twist of this game: Flow.match.twist (trip.gd adds it, P6-10), in a Quick Game ({}) the chosen court's (an
# unlocked city court brings its city's twist, P6-17; gym and blacktop "none"), or the test flag -- --twist <id>
func _twist_id() -> String:
	var id: String = str(Flow.match.get("twist", "none"))
	if Flow.match.is_empty():
		id = MenuScript.quick_twist()
	var flag: String = _flag_value("--twist")
	if flag != "":
		id = flag
	return id

# before the players and the ball are made: Twists.current (static, so set on every game build) and the wind
func _apply_twist() -> void:
	Twists.set_current(_twist_id())
	Twists.new_game(rng)
	if Twists.active():
		stat("twist_" + Twists.current)
		if autoplay or humantest:
			print("TWIST %s: %s | %s" % [Twists.current, Twists.info().name, Twists.info().banner])

# the shot clock's length: 24 s, or the twist's (Memphis 18)
func shot_clock_length() -> float:
	return Twists.value("shot_clock", SHOT_CLOCK_LENGTH)

# P6-14's effects node (rain, wind streaks, banner ...), only when a twist is on and the file exists
func _add_twist_fx() -> void:
	if not Twists.active() or not ResourceLoader.exists(TWIST_FX_PATH):
		return
	var s: GDScript = load(TWIST_FX_PATH) as GDScript
	if s == null:
		return
	var node = s.new()
	if not (node is Node):
		return
	if "game" in node:
		node.set("game", self)
	twist_fx = node
	add_child(node)

# at tip-off: twist_fx's banner (icon, name and line); without twist_fx, the twist's line under the "FIRST TO N" /
# match label message instead (one banner, never both)
func _show_twist_banner() -> void:
	if not Twists.active():
		return
	if twist_fx != null and twist_fx.has_method("show_banner"):
		twist_fx.show_banner()
		return
	var line: String = str(Twists.info().banner)
	if twist_label != null and line != "":
		twist_label.text = line
		twist_label.visible = true
		twist_label.modulate.a = 1.0
		_twist_line_t = TWIST_LINE_TIME

# test only (-- --anim-test): P6-24's driver, like the trip test's (it gets `main`)
func _add_anim_test() -> void:
	if not anim_test:
		return
	var s: GDScript = load(ANIM_TEST_PATH) as GDScript
	if s == null:
		print("ANIM TEST: %s did not load" % ANIM_TEST_PATH)
		return
	var node = s.new()
	if not (node is Node):
		print("ANIM TEST: %s is not a Node" % ANIM_TEST_PATH)
		return
	if "main" in node:
		node.set("main", self)
	if "game" in node:
		node.set("game", self)
	add_child(node)

# camera punch (P6-23): fx.zoom_punch() is 1.0 at rest, a little more on a big dunk
func _zoom_punch() -> float:
	if fx != null and fx.has_method("zoom_punch"):
		return float(fx.zoom_punch())
	return 1.0

# the TWIST line of the test printout: what the twist did this game
func _twist_summary() -> String:
	var g := func(k: String) -> int:
		return int(stats.get(k, 0))
	var secs: int = int(rules.play_time)
	var line: String = "TWIST %s (%s) | game %d:%02d" % [Twists.current, Twists.info().name, secs / 60, secs % 60]
	var long_shots: int = g.call("jumper_threes_t0") + g.call("jumper_threes_t1")
	var long_makes: int = g.call("jumper_three_makes_t0") + g.call("jumper_three_makes_t1")
	var turbo_s: float = float(g.call("turbo_frames_t0") + g.call("turbo_frames_t1")) / 60.0
	match Twists.current:
		"wind":
			line += " | long shots %d/%d (wind-hit %d) | shots curved %d, avg %.2f ft | lobs %d, avg drift %.2f ft, blown out of reach %d" % [
					long_makes, long_shots, g.call("wind_long_shots"), g.call("wind_curved_shots"),
					float(g.call("wind_curve_px")) / FT / maxf(1.0, float(g.call("wind_curved_shots"))),
					g.call("wind_lobs"), float(g.call("wind_drift_px")) / FT / maxf(1.0, float(g.call("wind_lobs"))),
					g.call("wind_lob_drops")]
		"crowd":
			line += " | shot clock %d s, violations %d, possessions %d" % [int(shot_clock_length()), g.call("shotclock"),
					g.call("possessions_t0") + g.call("possessions_t1")]
		"humid":
			line += " | stamina ran empty %d, turbo %.0f s, slow refill frames %d" % [g.call("stamina_empty"), turbo_s,
					g.call("twist_refill_frames")]
		"thin_air":
			line += " | long shots %d/%d (thin-air %d) | lobs %d (longer flight) | stamina ran empty %d, turbo %.0f s" % [
					long_makes, long_shots, g.call("thin_air_long_shots"), g.call("thin_air_lobs"),
					g.call("stamina_empty"), turbo_s]
		"wet":
			line += " | slides %d (%.1f s), crossovers %d (keep their grip)" % [g.call("slides"),
					float(g.call("slide_frames")) / 60.0, g.call("crossovers_t0") + g.call("crossovers_t1")]
		"sand":
			line += " | turbo %.0f s, stamina ran empty %d" % [turbo_s, g.call("stamina_empty")]
		"cage":
			line += " | fence bounces %d, out of bounds %d (sideline %d, baseline %d)" % [g.call("fence_bounces"),
					g.call("out_of_bounds"), g.call("oob_sideline"), g.call("oob_baseline")]
	return line

# after rules.gd is made: a trip game's target (side switch at (target + 1) / 2, as --target does; a --target flag
# wins) and the crew names for the top bar and the messages
func _apply_match_rules() -> void:
	if not Flow.in_trip():
		return
	var tg: int = int(Flow.match.get("target", 0))
	if tg > 0 and not OS.get_cmdline_user_args().has("--target"):
		rules.target = tg
		rules.switch_at = floori((tg + 1) / 2.0)
	var tms: Array = Flow.match.get("teams", [])
	for t in mini(2, tms.size()):
		var nm: String = str((tms[t] as Dictionary).get("name", ""))
		if nm != "":
			TEAM_NAMES[t] = nm

# test flags -- --city <id> --cgame N (N = 1..3, default 1): play that trip matchup. Built by Trip.match_for(id, N)
# when trip.gd exists (P5-05), else TEST_MATCH with the city's name, target, look and music from cities.gd.
# With neither --humantest nor a screenshot mode it is an --autoplay game (see _city_autoplay).
func _parse_city_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var ci: int = args.find("--city")
	if ci < 0 or ci + 1 >= args.size():
		return
	var city: String = args[ci + 1]
	var n := 1
	var gi: int = args.find("--cgame")
	if gi >= 0 and gi + 1 < args.size() and args[gi + 1].is_valid_int():
		n = clampi(args[gi + 1].to_int(), 1, 3)
	var built := {}
	if ResourceLoader.exists(TRIP_PATH):
		var trip: GDScript = load(TRIP_PATH) as GDScript
		if trip != null and trip.has_method("match_for"):
			var r = trip.call("match_for", city, n)
			if r is Dictionary and (r as Dictionary).size() > 0:
				built = r
			elif Flow.in_trip():
				built = Flow.match   # match_for() set Flow.match itself
	if built.is_empty():
		built = TEST_MATCH.duplicate(true)
		var c: Dictionary = Cities.city(city)
		if c.is_empty():
			print("--city: unknown city '%s', playing the test match" % city)
		else:
			built["label"] = "%s - GAME %d OF 3" % [str(c.get("name", city)).to_upper(), n]
			built["target"] = Cities.game_target(city, n)
			if str(c.get("look", "")) != "":
				built["look"] = str(c["look"])
			if str(c.get("music", "")) != "":
				built["music"] = str(c["music"])
			var crew: Dictionary = c.get("crew", {})
			if str(crew.get("name", "")) != "":
				built["teams"][1]["name"] = str(crew["name"])
				built["teams"][1]["style"] = str(crew.get("style", ""))
	var lvl: String = _difficulty_flag_value()
	if lvl != "":
		built["level"] = lvl   # --difficulty sets the city crew's level in --city games too
	Flow.match = built
	var tms: Array = built.get("teams", [])
	var names: Array = []
	for tm in tms:
		names.append(str((tm as Dictionary).get("name", "?")))
	print("MATCH %s | to %d | %s | level %s | twist %s" % [str(built.get("label", "")), int(built.get("target", 21)),
			" vs ".join(PackedStringArray(names)), str(built.get("level", "")), _twist_id()])

# --city plays CPU vs CPU unless the run is a --humantest or a screenshot mode
func _city_autoplay() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.has("--city"):
		return false
	for f in ["--humantest", "--shots", "--ballshots", "--menushot"]:
		if args.has(f):
			return false
	return true

# test only (-- --ratingtest): print the ratings table (ratings.gd) and quit
func _ratingtest() -> void:
	set_physics_process(false)
	set_process(false)
	var ok: bool = Ratings.self_test()
	get_tree().quit(0 if ok else 1)

# the shooting rating of a player (50 when he has none: Quick Game)
func _shooting(p) -> int:
	if p != null and p.has_method("rating"):
		return int(p.rating("shooting"))
	return Ratings.AVG_RATING

# per-team numbers for the pause screen (P5-08): points, shots made / taken (field goals incl. dunks and layups),
# dunks made, steals, blocks
func team_stats(t: int) -> Dictionary:
	var g := func(k: String) -> int:
		return int(stats.get(k, 0))
	return {"points": int(score[t]), "shots": g.call("shots_t%d" % t), "makes": g.call("makes_t%d" % t),
			"dunks": g.call("dunk_makes_t%d" % t), "steals": g.call("steals_t%d" % t),
			"blocks": g.call("blocks_t%d" % t)}

# the pause screen (P5-08) on the HUD, once pause.gd exists; not in CPU-only games
func _add_pause(hud: CanvasLayer, root: Control) -> void:
	if autoplay or not ResourceLoader.exists(PAUSE_PATH):
		return
	var s: GDScript = load(PAUSE_PATH) as GDScript
	if s == null:
		return
	var node = s.new()
	if not (node is Node):
		return
	pause_node = node
	if "game" in node:
		node.set("game", self)
	if node is Control:
		root.add_child(node)
	elif node is CanvasLayer:
		add_child(node)
	else:
		hud.add_child(node)

func _make_layer(n: String, z: int) -> Node2D:
	var l := Node2D.new()
	l.name = n
	l.z_index = z
	add_child(l)
	return l

# test flags: -- --view flat|angled (or --view=angled) sets View.mode (default ANGLED); -- --perspective k tries
# View.perspective k (e.g. 0.15); -- --fps prints the frame rate
func _parse_view_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	fps_print = args.has("--fps")
	for i in args.size():
		if args[i] == "--perspective" and i + 1 < args.size():
			View.perspective = clampf(args[i + 1].to_float(), 0.0, 0.5)
		var v := ""
		if args[i].begins_with("--view="):
			v = args[i].substr("--view=".length())
		elif args[i] == "--view" and i + 1 < args.size():
			v = args[i + 1]
		if v == "angled":
			View.mode = View.ANGLED
		elif v == "flat":
			View.mode = View.FLAT
		elif v != "":
			print("--view: unknown mode '%s' (flat or angled)" % v)

# test only (-- --viewtest): check the projection round trip and the stick mapping, print the result and quit
func _viewtest() -> void:
	set_physics_process(false)
	set_process(false)
	var errs: PackedStringArray = View.self_test()
	if errs.is_empty():
		print("VIEWTEST OK")
	else:
		for e in errs.slice(0, 20):
			print(e)
		print("VIEWTEST FAILED (%d)" % errs.size())
	get_tree().quit(0 if errs.is_empty() else 1)

# the panel is up: the joystick and A/B take no touches (touch_controls reads _input, before the GUI) and are hidden,
# so the tap on a level can't also move or shoot
func _menu_input(on: bool) -> void:
	controls.set_process_input(not on)
	controls.visible = not on and not autoplay
	if on:
		controls.joy_index = -1
		controls.a_index = -1
		controls.b_index = -1

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)

	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.55)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 54
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)

	score_label = _make_label(root, TOP_BAR_FONT_TRIP if _crew_names() else 30, Control.PRESET_TOP_WIDE, 8)
	if _crew_names():
		score_label.offset_top = 11   # same middle of the bar with the smaller font
	clock_label = _make_label(root, 20, Control.PRESET_TOP_LEFT, 14)
	clock_label.offset_left = 20
	clock_label.offset_right = 260
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	shot_label = _make_label(root, 20, Control.PRESET_TOP_RIGHT, 14)
	shot_label.offset_left = -260
	shot_label.offset_right = -20
	shot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	msg_label = _make_label(root, MSG_FONT_SIZE, Control.PRESET_CENTER, 0)
	msg_label.offset_left = -500
	msg_label.offset_right = 500
	msg_label.offset_top = -160
	msg_label.offset_bottom = -60
	ft_label = _make_label(root, 26, Control.PRESET_TOP_WIDE, 62)   # "FREE THROW 1 OF 2" under the top bar
	ft_label.modulate = FT_LABEL_COLOR
	twist_label = _make_label(root, TWIST_LINE_SIZE, Control.PRESET_CENTER, 0)   # under msg_label (-160..-60)
	twist_label.offset_left = -560
	twist_label.offset_right = 560
	twist_label.offset_top = -58
	twist_label.offset_bottom = -18
	twist_label.modulate = TWIST_LINE_COLOR
	twist_label.visible = false

	controls = ControlsScript.new()
	root.add_child(controls)
	controls.a_pressed.connect(_on_a_pressed)
	controls.a_released.connect(_on_a_released)
	controls.b_pressed.connect(_on_b_pressed)
	if autoplay:
		controls.visible = false
	_add_pause(hud, root)

func _make_label(parent: Control, size: int, preset: int, top: float) -> Label:
	var l := Label.new()
	l.set_anchors_preset(preset)
	l.offset_top = top
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.outline_size = 6
	ls.outline_color = Color(0, 0, 0, 0.8)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func start_game() -> void:
	rules.start_game()

# line both teams up: `team` (which gets the ball) on its own half, the other just past half court. The rows are
# mirrored by the attack direction (y times dir) so both halves of the court play the same (B1)
func reset_positions(team: int) -> void:
	var own: Vector2 = attack_hoop(1 - team)   # the hoop this team defends
	var dir := inward(own)
	for i in 3:
		var row: float = [0.0, -12.0, 12.0][i] * dir * FT
		var o = teams[team][i]
		o.position = own + Vector2(dir * (5 + i * 12) * FT, row)
		var d = teams[1 - team][i]
		d.position = Vector2(COURT_W / 2 + dir * 10 * FT, COURT_H / 2 + row)
		for p in [o, d]:
			p.velocity = Vector2.ZERO
			p.shooting = false
			p.facing = 0.0 if attack_hoop(p.team).x > COURT_W / 2 else PI   # face the hoop it attacks

# ---------------- court helpers ----------------

# the only place that knows which hoop a team attacks: team 0 attacks the right hoop until the side switch (P3-02)
func attack_hoop(team: int) -> Vector2:
	var right: bool = (team == 0) != rules.sides_swapped
	return hoops[1] if right else hoops[0]

func inward(hoop: Vector2) -> float:
	return 1.0 if hoop.x < COURT_W / 2 else -1.0

func in_frontcourt(pos: Vector2, team: int) -> bool:
	return (pos.x > COURT_W / 2) == (attack_hoop(team).x > COURT_W / 2)

func clamp_to_court(pos: Vector2) -> Vector2:
	return Vector2(clamp(pos.x, 10.0, COURT_W - 10.0), clamp(pos.y, 10.0, COURT_H - 10.0))

func is_human(p) -> bool:
	return not autoplay and p == human_player

func nearest_opponent(p):
	var best = null
	var best_d := INF
	for o in teams[1 - p.team]:
		var d: float = o.position.distance_to(p.position)
		if d < best_d:
			best_d = d
			best = o
	return best

func openness(p) -> float:
	var o = nearest_opponent(p)
	return 99.0 if o == null else o.position.distance_to(p.position) / FT

func is_chaser(p) -> bool:
	return chasers.has(p)

func is_three(pos: Vector2, hoop: Vector2) -> bool:
	var from_baseline: float = abs(pos.x - (0.0 if inward(hoop) > 0 else COURT_W)) / FT
	if from_baseline < 14.0:
		return abs(pos.y - hoop.y) / FT >= 22.0
	return pos.distance_to(hoop) / FT > 23.75

func shot_probability(p, quality: float) -> float:
	var hoop := attack_hoop(p.team)
	var d: float = p.position.distance_to(hoop) / FT
	var base: float
	if d < SHOT_CLOSE_FT:
		base = SHOT_CLOSE_BASE
	elif not is_three(p.position, hoop):
		base = SHOT_MID_BASE - (d - SHOT_CLOSE_FT) * SHOT_MID_FALLOFF
	else:
		base = SHOT_LONG_BASE - maxf(0.0, d - 23.75) * SHOT_LONG_FALLOFF
		base *= Twists.value("long_shot_mult", 1.0)   # wind (gusting) and thin air; 1.0 without a twist
	base = maxf(base, SHOT_MIN)
	var rim: bool = p.rim_kind != ""
	var cont := openness(p)
	if cont < CONTEST_TIGHT_FT:
		base *= RIM_CONTEST_TIGHT_MULT if rim else CONTEST_TIGHT_MULT
	elif cont < CONTEST_NEAR_FT:
		base *= RIM_CONTEST_NEAR_MULT if rim else CONTEST_NEAR_MULT
	# the shooting rating moves jump shots only (dunks and layups use finishing, in player.gd); 50 = x1.0
	var rate: float = 1.0 if rim else Ratings.shot_mult(_shooting(p))
	return clampf(base * quality * rate, SHOT_MIN, SHOT_CAP)

# ---------------- ball events ----------------

func give_ball(p) -> void:
	ball.position = p.position
	ball.hold(p)

func on_ball_held(p) -> void:
	if p.team != possession or not shot_clock_running:
		shot_clock = shot_clock_length()
	shot_clock_running = true
	possession = p.team
	rules.on_possession(p.team)
	if p.team == HUMAN_TEAM:
		if CONTROL_FOLLOWS_CATCH or human_player == null or human_player.team != HUMAN_TEAM:
			human_player = p
	elif human_player == null or human_player.team != HUMAN_TEAM:
		human_player = teams[HUMAN_TEAM][0]

func release_shot(p, quality: float) -> void:
	if not p.has_ball():
		return
	if rules.ft_active and p == rules.ft_shooter:
		_release_free_throw(p, quality)
		return
	var hoop := attack_hoop(p.team)
	var prob := shot_probability(p, quality)
	var made := rng.randf() < prob
	var pts: int = rules.points_for(p, hoop)
	shot_clock_running = false
	shot_serial += 1
	stat("shots")
	stat("shots_t%d" % p.team)
	stat("shots_half%d_t%d" % [2 if rules.sides_swapped else 1, p.team])
	stat("shot_d%d" % int(p.position.distance_to(hoop) / FT / 5) )
	if Twists.base_value("long_shot_mult", 1.0) != 1.0 and p.rim_kind == "" and is_three(p.position, hoop):
		stat(Twists.current + "_long_shots")   # a long shot the twist moved (wind_long_shots, thin_air_long_shots)
	# P7-T1: shot quality bands (kind x openness at the release) with their rolled makes and summed odds (per mille),
	# to see where misses come from: shotq_<dunk|layup|jumper|three>_<open|mid|cont>
	var band: String = "cont" if openness(p) < CONTEST_TIGHT_FT else ("mid" if openness(p) < CONTEST_NEAR_FT else "open")
	var kind: String = p.rim_kind if p.rim_kind != "" else ("three" if is_three(p.position, hoop) else "jumper")
	var qk: String = "shotq_%s_%s" % [kind, band]
	stat(qk)
	stat_add(qk + "_odds", int(prob * 1000.0))
	if made:
		stat(qk + "_makes")
		stat("makes")
		stat("makes_t%d" % p.team)
	if p.on_fire:
		stat("fire_shots")
		if made: stat("fire_makes")
	ball.shoot(p, hoop, made, pts)
	if force_fouls and rng.randf() < FORCE_FOUL_CHANCE:
		var d = nearest_opponent(p)   # test only: as if he had jumped badly into the shooter
		stat("forced_fouls")
		rules.call_foul(d, p, "shooting")

# a free throw (rules.ft_active): FT_BASE x the release quality, 1 point, no contest, no blocks, no interceptions
func _release_free_throw(p, quality: float) -> void:
	var prob: float = clampf(FT_BASE * Ratings.shot_mult(_shooting(p)) * quality, 0.0, FT_CAP)
	var made: bool = rng.randf() < prob
	shot_clock_running = false
	stat("free_throws")
	stat("ft_attempts_t%d" % p.team)
	if is_human(p):
		stat("human_ft_attempts")
		if quality >= FT_PERFECT_Q:
			stat("human_ft_perfect")
	ball.next_shot_kind = ""
	ball.next_alley = false
	rules.ft_released()
	ball.shoot(p, attack_hoop(p.team), made, rules.ft_value)

# a dunk or layup blocked at take-off: counts as a missed shot, the ball is swatted out of the shooter's hands
func rim_shot_blocked(p, defender) -> void:
	shot_clock_running = false
	shot_serial += 1   # it counts as a shot: lets the blocker (defense.gd rolled_shot) try again on the next one
	stat("shots")
	stat("shots_t%d" % p.team)
	if p.on_fire:
		stat("fire_shots")
	block_shot(defender)
	on_shot_missed(p)

func block_shot(defender) -> void:
	var missed_shooter = null
	if ball.state == ball.SHOT:
		# a jump shot swatted in the air: it was rolled at release, so take a rolled make back off the books
		if ball.shot_made:
			stats["makes"] = stats.get("makes", 1) - 1
			if ball.shooter != null:
				var mk: String = "makes_t%d" % ball.shooter.team
				stats[mk] = stats.get(mk, 1) - 1
			if ball.shooter != null and ball.shooter.on_fire:
				stats["fire_makes"] = stats.get("fire_makes", 1) - 1
		missed_shooter = ball.shooter
	var away: Vector2 = (ball.position - defender.position).normalized()
	ball.make_loose(ball.position, away * rng.randf_range(200.0, 300.0), ball.z, 80.0)
	show_message("BLOCKED!")
	stat("blocks")
	stat("blocks_t%d" % defender.team)
	if is_human(defender):
		stat("human_blocks")
		if humantest:
			stat("humantest_%s_blocks" % ht_jump_kind)
			if ht_jump_kind != "random":
				stat("humantest_%s_blocks_%s" % [ht_jump_kind, ht_jump_phase])
	fx.shake(BLOCK_SHAKE, BLOCK_SHAKE_TIME)
	audio.play("block")
	if missed_shooter != null:
		on_shot_missed(missed_shooter)   # after "BLOCKED!" so a "cooling down" message wins

func on_shot_made(shooter, pts: int) -> void:
	var hoop := attack_hoop(shooter.team)   # before add_score: the side switch may flip it
	if rules.ft_shot_live:
		# a free throw: no "SCORES" banner and no on-fire streak, just the +1 at the hoop
		fx.popup("+%d" % pts, hoop + Vector2(0, -SCORE_POPUP_RISE), TEAM_COLORS[shooter.team], SCORE_POPUP_SIZE)
		rules.ft_result(true)
		return
	show_message("%s %s" % [TEAM_NAMES[shooter.team], "FOR TWO!" if pts >= 2 else "SCORES"], SCORE_MSG_TIME,
			TEAM_COLORS[shooter.team])
	if ball.shot_kind != "dunk":   # a dunk already shows "SLAM!"
		fx.popup("+%d" % pts, hoop + Vector2(0, -SCORE_POPUP_RISE), TEAM_COLORS[shooter.team], SCORE_POPUP_SIZE)
	audio.play("crowd")
	if ball.shot_kind == "dunk":
		stat("dunk_makes_t%d" % shooter.team)   # pause screen (team_stats)
	_update_fire_on_make(shooter)
	rules.add_score(shooter.team, pts, ball.shot_kind if ball.shot_kind != "" else "shot")
	if game_over:
		return
	if rules.resolve_pending_foul(shooter, true):
		return   # fouled on the make: and-one free throw
	possession = 1 - shooter.team
	rules.dead_ball(1 - shooter.team, rules.MADE_WAIT)

func on_shot_missed(shooter) -> void:
	if rules.ft_shot_live:
		rules.ft_result(false)   # a missed free throw doesn't touch the on-fire streak
		return
	if shooter == null:
		return
	if rules.resolve_pending_foul(shooter, false):
		return   # fouled on the miss: free throws (the fire streak isn't charged with this miss)
	shooter.make_streak = 0
	if shooter.on_fire:
		shooter.fire_misses += 1
		if shooter.fire_misses >= FIRE_MISSES:
			_end_fire(shooter)
		else:
			show_message("He's cooling down.")
			stat("fire_cooldowns")

# ---------------- on fire ----------------

func _update_fire_on_make(shooter) -> void:
	shooter.make_streak += 1
	shooter.fire_misses = 0   # a make while cooling down makes him fully hot again
	if shooter.make_streak >= FIRE_STREAK and not shooter.on_fire:
		shooter.on_fire = true
		stat("fire_starts_t%d" % shooter.team)
		fx.popup("ON FIRE!", shooter.position + Vector2(0, -5.0 * FT), FIRE_COLOR, FIRE_POPUP_SIZE)
		audio.play("fire")

func _end_fire(p) -> void:
	p.on_fire = false
	p.make_streak = 0
	p.fire_misses = 0
	stat("fire_ends")
	p.queue_redraw()   # drop the flame ring even when the player stops updating (game over)

# flaming trail while an on-fire player holds or shoots the ball
func _update_fire_trail() -> void:
	var p = null
	if ball.state == ball.HELD:
		p = ball.holder
	elif ball.state == ball.SHOT:
		p = ball.shooter
	var want: bool = p != null and p.on_fire
	if want != _trail_on:
		_trail_on = want
		fx.set_trail(want, FIRE_COLOR)

func do_pass(from_p, to_p) -> void:
	if not from_p.has_ball() or to_p == from_p:
		return
	ball.pass_to(from_p, to_p)
	stat("passes")
	if from_p.team == HUMAN_TEAM and (CONTROL_FOLLOWS_CATCH or from_p == human_player):
		human_player = to_p

# 0..1: how open the ball is to this defender's poke. 0 when the ball is out of reach or behind the handler's body.
func steal_exposure(defender, handler) -> float:
	if defender == null or handler == null:
		return 0.0
	var ball_pos: Vector2 = handler.position + Vector2.from_angle(handler.facing) * STEAL_BALL_PX
	if ball.state == ball.HELD and ball.holder == handler:
		ball_pos = ball.position   # where ball.gd really draws the dribble (includes the hand once P2-05 lands)
	if defender.position.distance_to(ball_pos) > STEAL_REACH_FT * FT:
		return 0.0
	var to_ball: Vector2 = ball_pos - handler.position
	var to_def: Vector2 = defender.position - handler.position
	if to_ball.length() < 0.01 or to_def.length() < 0.01:
		return 1.0
	var ang: float = rad_to_deg(absf(to_ball.angle_to(to_def)))
	return clampf((STEAL_SHIELD_DEG - ang) / (STEAL_SHIELD_DEG - STEAL_OPEN_DEG), 0.0, 1.0)

# the handler's body is between this defender and the ball (angle at least STEAL_SHIELD_DEG): a poke from here goes
# through the body. (Distance is checked by the caller: the poke reached the handler, STEAL_POKE_PX.)
func _ball_behind_body(defender, handler) -> bool:
	var ball_pos: Vector2 = handler.position + Vector2.from_angle(handler.facing) * STEAL_BALL_PX
	if ball.state == ball.HELD and ball.holder == handler:
		ball_pos = ball.position
	var to_ball: Vector2 = ball_pos - handler.position
	var to_def: Vector2 = defender.position - handler.position
	if to_ball.length() < 0.01 or to_def.length() < 0.01:
		return false
	return rad_to_deg(absf(to_ball.angle_to(to_def))) >= STEAL_SHIELD_DEG

# how well a poke at this handler's ball is timed right now: 1 within `grace` s of a dribble floor touch, else 0
# (STEAL_HELD_TIMING while the ball is held up). grace < 0 means STEAL_GRACE. late >= 0: the window after the floor
# touch is `late` s instead of `grace` (the human's reaction allowance).
func steal_timing(handler, grace := -1.0, late := -1.0) -> float:
	if not STEAL_TIMING:
		return 1.0
	if handler == null or not (ball.state == ball.HELD and ball.holder == handler):
		return 0.0
	if handler.shooting or handler.rim_kind != "" or ("fake_t" in handler and handler.fake_t > 0.0):
		return STEAL_HELD_TIMING
	var g: float = STEAL_GRACE if grace < 0.0 else grace
	var after: float = g if late < 0.0 else late
	var ph: float = fposmod(ball.anim_time, DRIBBLE_PERIOD)   # seconds since the last floor touch
	return 1.0 if ph <= after or DRIBBLE_PERIOD - ph <= g else 0.0

# 0..1: exposure x timing. At or over STEAL_GOOD_EXPOSURE it's a good poke.
func steal_quality(defender, handler) -> float:
	if is_human(defender):
		return steal_exposure(defender, handler) * steal_timing(handler, STEAL_GRACE, STEAL_HUMAN_LATE)
	return steal_exposure(defender, handler) * steal_timing(handler, STEAL_CPU_GRACE)

# true while a poke by the human would be a good one: drives the lit STEAL button
func human_steal_cue() -> bool:
	var d = human_player
	var h = ball.holder
	if d == null or ball.state != ball.HELD or h == null or h.team == d.team:
		return false
	if d.steal_cooldown > 0.0 or ("stumble_t" in d and d.stumble_t > 0.0) or d.position.distance_to(h.position) > STEAL_POKE_PX:
		return false
	return steal_quality(d, h) >= STEAL_GOOD_EXPOSURE

# chance that a poke by defender at handler works now: exposure, timing, the defender's steal rating and the move
func steal_chance(defender, handler) -> float:
	var q: float = steal_quality(defender, handler)
	var good: float = 1.0 if q >= STEAL_GOOD_EXPOSURE else 0.0
	var human: bool = is_human(defender)
	var k: float = lerpf(good, q, STEAL_HUMAN_LUCK if human else STEAL_LUCK)
	if k <= 0.0:
		return 0.0
	var r: float = 50.0
	if defender.has_method("rating"):
		r = float(defender.rating("steal"))
	var base: float = STEAL_BASE + (STEAL_HUMAN_BONUS * good if human else 0.0)
	var c: float = (base + (clampf(r, 0.0, 100.0) / 50.0 - 1.0) * STEAL_RATING_SPAN) * k
	if "cross_t" in handler and handler.cross_t > 0.0:
		c *= STEAL_SPIN_MULT if handler.move_kind == "spin" else STEAL_CROSS_MULT
	if handler.turbo:
		c *= STEAL_TURBO_MULT
	if "fake_t" in handler and handler.fake_t > 0.0:
		c *= STEAL_FAKE_MULT
	return clampf(c, 0.0, STEAL_MAX_CHANCE)

# a poke at the ball (A on defense, or the CPU). The second argument is ignored (old callers passed a flat chance).
func attempt_steal(defender, _legacy := -1.0) -> void:
	if "stumble_t" in defender and defender.stumble_t > 0.0:
		return   # off balance: can't poke
	if defender.steal_cooldown > 0.0 or rules.ft_active:
		return
	defender.steal_cooldown = STEAL_COOLDOWN
	var h = ball.holder
	if ball.state != ball.HELD or h == null or h.team == defender.team:
		return
	if "poke_t" in defender:
		defender.poke_t = STEAL_POKE_FREEZE   # stands still while reaching, hit or miss
	if defender.position.distance_to(h.position) > STEAL_POKE_PX:
		return
	stat("steal_pokes_t%d" % defender.team)
	var good: bool = steal_quality(defender, h) >= STEAL_GOOD_EXPOSURE
	if is_human(defender):
		stat("human_steal_pokes")
		if good:
			stat("human_pokes_on_cue")   # the STEAL button was lit (well-timed, exposed ball)
	if steal_exposure(defender, h) <= 0.0:
		stat("steal_shielded")
		# reaching foul (P3-05, Q3 a): the poke reached the handler, but the ball was behind his body
		if REACH_FOULS and _ball_behind_body(defender, h):
			stat("steal_shielded_body")   # the reach-foul roll itself is defense.try_reach_foul (P3-09)
	if good:
		stat("steal_good_pokes_t%d" % defender.team)
	if rng.randf() < steal_chance(defender, h):
		stat("steals_good" if good else "steals_bad")
		var v: Vector2 = (defender.position - h.position).normalized().rotated(rng.randf_range(-0.8, 0.8)) * 160.0
		h.shooting = false
		ball.make_loose(ball.position, v, 8.0, 60.0)
		show_message("STEAL!")
		stat("steals")
		stat("steals_t%d" % defender.team)
		if is_human(defender):
			stat("human_steals")

# ---------------- input ----------------

# during free throws A only shoots (the human at the line) and B does nothing (human_input.gd gets the same rule in P3-06)
func _ft_blocks_buttons() -> bool:
	return rules.ft_active and not game_over and not (human_player == rules.ft_shooter and human_player.has_ball())

func _on_a_pressed() -> void:
	if menu.showing:
		return
	if _ft_blocks_buttons():
		return
	input.a_pressed()

func _on_a_released() -> void:
	if menu.showing:
		return
	input.a_released()

func _on_b_pressed() -> void:
	if menu.showing:
		return
	if rules.ft_active and not game_over:
		return
	input.b_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and menu.showing:
		menu.key(event)   # desktop: A/D or arrows (or K) move the light, J / Space / Enter plays it
		return
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_J or event.keycode == KEY_SPACE:
			if event.pressed:
				key_a_down = true
				_on_a_pressed()
			elif key_a_down:
				key_a_down = false
				_on_a_released()
		elif event.keycode == KEY_K and event.pressed:
			_on_b_pressed()

# P7-10: the Android back gesture. In a game: the pause panel opens (pause.gd does that itself on this same request)
# or, when it is open, closes (RESUME); the Quick Game start / game-over panel gets Escape (to the title). On the
# title's main panel it quits the app. Every other screen (and the title's sub-panels) gets an Escape press, so it
# does exactly what its own BACK / Escape does; a screen without one (result, points, recruit) does nothing.
# Desktop Escape stays with each screen's own handler (nothing here reads ui_cancel, so it is never handled twice).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_go_back()

func _on_go_back() -> void:
	var scr: String = str(Flow.screen)
	var did := "escape"
	if scr == Flow.GAME:
		stat("back_requests")
		if pause_node != null and is_instance_valid(pause_node) and bool(pause_node.get("_open")):
			pause_node.call("resume")   # main gets the request before its child pause.gd, whose open() is then a no-op
			did = "resume"
		elif menu != null and menu.showing:
			menu.key(_escape_key(true))   # straight to menu.gd: pause.gd's _input marks every Escape as handled
		else:
			did = "pause"   # pause.gd opens the panel on this same request (when the game allows it)
	elif scr == "title" and _title_main_panel():
		did = "quit"
	else:
		_send_escape()
	print("BACK on %s -> %s" % [scr, did])
	if _backtest_node != null and is_instance_valid(_backtest_node):
		_backtest_node.call("note", did)   # the test stays alive instead of quitting
	elif did == "quit":
		get_tree().quit()

# the title screen shows its main panel (not ROAD TRIP / START OVER / the level pick)
func _title_main_panel() -> bool:
	var node: Node = Flow.current_screen()
	if node == null:
		return true
	var panel = node.get("_panel")
	return panel == null or str(panel) == "main"

# an Escape press and release, as from a keyboard (each screen's _unhandled_key_input, pause.gd and menu.gd take it)
func _send_escape() -> void:
	Input.parse_input_event(_escape_key(true))
	Input.parse_input_event(_escape_key(false))

func _escape_key(down: bool) -> InputEventKey:
	var k := InputEventKey.new()
	k.keycode = KEY_ESCAPE
	k.physical_keycode = KEY_ESCAPE
	k.pressed = down
	return k

# the stick in sim (world) terms: what the human player, human_input (flicks, pass direction) and the assist get
func _input_vector() -> Vector2:
	return View.stick_to_world(_stick_screen())

# the stick (or the keys) in screen terms: up = up on screen. View.stick_to_world turns it into a sim direction of the
# same length (FLAT: the same vector)
func _stick_screen() -> Vector2:
	var v: Vector2 = controls.joystick()   # in --humantest the scripted thumb drives this too
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	return v.limit_length(1.0)

# ---------------- main loop ----------------

var _frame := 0
var _cue_shot := false
var _block_shot := false
var _switch_shot := false
var _call_shot := false

# a --shots / --menushot screenshot path: /tmp/hoops_<name>.png, or <DIR>/hoops_<name>.png with -- --shots-dir DIR
# (so parallel test runs don't overwrite each other's files)
func _shot_path(shot_name: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dir: String = "/tmp"
	for i in args.size():
		if args[i].begins_with("--shots-dir="):
			dir = args[i].get_slice("=", 1)
		elif args[i] == "--shots-dir" and i + 1 < args.size():
			dir = args[i + 1]
	return dir.path_join("hoops_%s.png" % shot_name)

func _debug_screenshots() -> void:
	# developer testing only: run with -- --shots to save a few screenshots to /tmp
	_frame += 1
	_menushots()
	if OS.get_cmdline_user_args().has("--shots") and controls.a_glow and not _cue_shot:
		_cue_shot = true   # first frame with the STEAL button lit (try -- --shots --humantest)
		get_viewport().get_texture().get_image().save_png(_shot_path("steal_cue"))
	if OS.get_cmdline_user_args().has("--shots") and controls.b_glow and not _call_shot \
			and input.call_t > 0.08:
		_call_shot = true   # the CALL bubble, a moment after the call (try -- --shots --humantest)
		get_viewport().get_texture().get_image().save_png(_shot_path("call_cue"))
	if OS.get_cmdline_user_args().has("--shots") and controls.a_block and not _block_shot:
		_block_shot = true   # first frame the orange button says BLOCK (try -- --shots --humantest)
		get_viewport().get_texture().get_image().save_png(_shot_path("block_label"))
	# the side switch, 1 s into its pause (try -- --shots --target 3 so it comes early; then it quits after this shot)
	if OS.get_cmdline_user_args().has("--shots") and rules.sides_swapped and not _switch_shot \
			and rules.dead_timer > 0.0 and rules.dead_timer < rules.SWITCH_PAUSE - 1.0:
		_switch_shot = true
		get_viewport().get_texture().get_image().save_png(_shot_path("switch"))
		if OS.get_cmdline_user_args().has("--target"):
			get_tree().quit()
	if OS.get_cmdline_user_args().has("--shots") and _frame in [240, 900, 1800]:
		get_viewport().get_texture().get_image().save_png(_shot_path(str(_frame)))
		if _frame == 1800 and not OS.get_cmdline_user_args().has("--target"):
			get_tree().quit()

# test only: -- --menushot (with xvfb, see _debug_screenshots; add --target 3 for a short game): saves the launch
# panel to /tmp/hoops_menu_start.png, picks the lit level as a tap would, then the game-over panel to
# /tmp/hoops_menu_over.png once it takes taps, and quits. The human stands still, so RED wins.
func _menushots() -> void:
	if not menushot or not menu.showing:
		_menu_frames = 0
		return
	_menu_frames += 1
	if menu_wait and _menu_frames == MENUSHOT_FRAMES:
		get_viewport().get_texture().get_image().save_png(_shot_path("menu_start"))
		menu._pick(MenuScript.Difficulty.level)
	elif game_over and _menu_frames == MENUSHOT_FRAMES + int(MenuScript.ARM_TIME_OVER * 60.0):
		get_viewport().get_texture().get_image().save_png(_shot_path("menu_over"))
		get_tree().quit()

func _physics_process(delta: float) -> void:
	_debug_screenshots()
	_update_message(delta)
	if game_over or menu_wait:
		return
	Twists.tick(delta)   # the wind's gusts (nothing for the other twists)

	if not rules.update(delta):
		if shot_clock_running and ball.state != ball.DEAD:
			shot_clock -= delta
			if shot_clock <= 0.0:
				show_message("SHOT CLOCK!")
				stat("shotclock")
				audio.play("whistle")
				var p = ball.holder if ball.holder != null else ball.passer
				var next_team: int = 1 - (p.team if p != null else possession)
				rules.dead_ball(next_team, 1.0)
	if game_over:
		return

	# who chases loose balls and rebounds: the closest player on each team
	chasers = []
	if ball.state == ball.LOOSE or ball.state == ball.SHOT:
		var spot: Vector2 = ball.position if ball.state == ball.LOOSE else ball.shot_hoop
		for t in 2:
			var best = null
			var best_d := INF
			for p in teams[t]:
				if ball.state == ball.SHOT and p == ball.shooter:
					continue
				var d: float = p.position.distance_to(spot)
				if d < best_d:
					best_d = d
					best = p
			chasers.append(best)
		# your player hunts the loose ball for you if you are not steering
		if ball.state == ball.LOOSE and not autoplay:
			var mine = chasers[HUMAN_TEAM]
			if human_player != mine and human_player.position.distance_to(ball.position) > mine.position.distance_to(ball.position) + 60.0:
				human_player = mine

	if humantest and human_player != null:
		if rules.ft_active:
			_humantest_free_throw(delta)   # at the line: the scripted thumb shoots with the meter
		else:
			if _frame % 97 == 0 and not (human_player.has_ball() and _ht_hoop_ft() > HT_SHOOT_MAX_FT):
				ht_jump_kind = "random"
				_ht_poke("random")   # on offense: a shot (meter held 50 frames); on defense: a randomly timed poke
			if _frame % 97 == 50: _on_a_released()
			if _frame % 211 == 0: _on_b_pressed()
		_humantest_thumb(delta)
		if not rules.ft_active:
			_humantest_timed_poke(delta)
			_humantest_block(delta)
			_humantest_call(delta)
			_humantest_guard_metric()
	# free throws: nobody moves with the stick (no walking off the line, no crossovers)
	var stick := Vector2.ZERO if rules.ft_active else _input_vector()
	input.update(delta, stick)
	for p in players:
		p.update(delta, is_human(p), stick)   # during free throws player.at_free_throw() handles positions
	input.face_caller(delta)
	_call_node.queue_redraw()
	_steal_node.queue_redraw()
	if not rules.ft_active:
		_separate_players()
	ball.update(delta)
	if not rules.ft_shot_live:
		DefenseScript.check_jump_shot_block(self)   # free throws can't be blocked
	_update_fire_trail()

	_update_camera()
	_update_hud()

# ANGLED: screen px above the far sideline kept clear of the HUD bar: CAM_TOP_FT, or the tallest player's drawn head
# (player.gd view_head_px(): v1 80, v2 about 100) at the far sideline plus CAM_TOP_PAD_PX, whichever is more
func _cam_top_room() -> float:
	var head: float = 0.0
	for p in players:
		if p.has_method("view_head_px"):
			head = maxf(head, float(p.view_head_px()))
	var far: float = minf(View.size_at(Vector2(COURT_W / 2.0, 0.0)), View.size_at(Vector2(COURT_W / 2.0, COURT_H)))
	return maxf(CAM_TOP_FT * FT, head * far + CAM_TOP_PAD_PX) * View.HEIGHT_SCALE

# FLAT: the camera sits on the ball (as before). ANGLED: it follows the ball's projected floor point left and right
# (CAM_FOLLOW_X) at a fixed depth (CAM_FOLLOW_Y), inside limits from the projected court corners plus margins. The
# zoom is CAM_ZOOM, or less if the screen is too short to show the HUD bar, the far heads and the whole court depth
# (less CAM_DEPTH_SLACK_FT, which the camera covers by sliding with the ball's depth).
func _update_camera() -> void:
	View.flipped = View.SIDE_FLIP and rules.sides_swapped
	var target: Vector2 = View.to_screen(ball.position, 0.0)
	if not View.angled():
		camera.position = target
		camera.zoom = Vector2(CAM_ZOOM_FLAT, CAM_ZOOM_FLAT) * _zoom_punch()
		return
	var corners := [View.to_screen(Vector2(0, 0)), View.to_screen(Vector2(COURT_W, 0)),
			View.to_screen(Vector2(0, COURT_H)), View.to_screen(Vector2(COURT_W, COURT_H))]
	var lo: Vector2 = corners[0]
	var hi: Vector2 = corners[0]
	for c in corners:
		lo = Vector2(minf(lo.x, c.x), minf(lo.y, c.y))
		hi = Vector2(maxf(hi.x, c.x), maxf(hi.y, c.y))
	var screen: Vector2 = get_viewport_rect().size
	var top_room: float = _cam_top_room()
	var need_y: float = hi.y - lo.y + top_room + CAM_MARGIN_FT * FT
	var fit_y: float = maxf(need_y - CAM_DEPTH_SLACK_FT * FT, 1.0)
	var zm: float = clampf((screen.y - CAM_HUD_PX) / fit_y, CAM_ZOOM_MIN, CAM_ZOOM)
	camera.zoom = Vector2(zm, zm)
	var vis: Vector2 = screen / Vector2(zm, zm)
	var left: float = lo.x - CAM_MARGIN_FT * FT
	var right: float = hi.x + CAM_MARGIN_FT * FT
	var top: float = lo.y - top_room - CAM_HUD_PX / zm
	var bottom: float = hi.y + CAM_MARGIN_FT * FT
	var mid := Vector2((left + right) / 2.0, (top + bottom) / 2.0)
	var cam_y: float = lerpf(mid.y, target.y, CAM_FOLLOW_Y)
	if bottom - top > vis.y:
		# the screen can't show the whole frame: slide over the part it lacks with the ball's depth (far sideline =
		# frame top in view, near sideline = frame bottom), so a far head nears the HUD bar only when play is near
		var depth: float = clampf((target.y - lo.y) / maxf(hi.y - lo.y, 1.0), 0.0, 1.0)
		cam_y = lerpf(top + vis.y / 2.0, bottom - vis.y / 2.0, depth)
	# a screen bigger than the framed area: grow the limits evenly, so the court stays centered
	if right - left < vis.x:
		left = mid.x - vis.x / 2.0
		right = mid.x + vis.x / 2.0
	if bottom - top < vis.y:
		top = mid.y - vis.y / 2.0
		bottom = mid.y + vis.y / 2.0
	camera.limit_left = int(floorf(left))
	camera.limit_right = int(ceilf(right))
	camera.limit_top = int(floorf(top))
	camera.limit_bottom = int(ceilf(bottom))
	camera.position = Vector2(lerpf(mid.x, target.x, CAM_FOLLOW_X), cam_y)
	camera.zoom = Vector2(zm, zm) * _zoom_punch()   # the limits above use the zoom without the punch

func _process(delta: float) -> void:
	if not fps_print:
		return
	_fps_t += delta
	if _fps_t >= FPS_PRINT_EVERY:
		_fps_t = 0.0
		print("FPS %d" % Engine.get_frames_per_second())

# ---------------- humantest scripted thumb ----------------

# developer testing only: a scripted thumb on the real touch joystick. It steers toward the hoop (or the ball on
# defense) turning at most HT_STEER_RATE, and while the human holds the ball it injects gestures: 120-degree snaps
# (flicks), smooth 180-degree turns and radial turbo pulls (not flicks), and short A taps.
func _humantest_thumb(delta: float) -> void:
	if controls.joy_index < 0:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = controls.mirror_x(HT_FINGER_POS)
		controls._input(down)
	var goal: Vector2 = attack_hoop(HUMAN_TEAM) if possession == HUMAN_TEAM else ball.position
	var goal_angle: float = (goal - human_player.position).angle()
	# on defense, now and then pull the stick away from the handler: the defensive assist must let go
	if possession != HUMAN_TEAM and ball.state == ball.HELD:
		ht_away_clock += delta
		if ht_away_clock >= HT_AWAY_EVERY:
			ht_away_clock = 0.0
			ht_away_t = HT_AWAY_TIME
			stat("humantest_pull_aways")
	if ht_away_t > 0.0:
		ht_away_t -= delta
		goal_angle += PI
		# last frame's stick (assist_on is from last frame's update): aimed away from the handler and his spot?
		if ball.holder != null and not human_player.assist_aim_ok(View.stick_to_world(controls.joystick()), ball.holder, false):
			stat("humantest_away_frames")
			if human_player.assist_on:
				stat("humantest_away_assist_frames")   # should stay 0: pulling away turns the assist off
	var can_flick: bool = input.flick_ready() and not rules.ft_active   # no gestures at the line
	if can_flick:
		ht_snap_clock += delta
		ht_turn_clock += delta
		ht_tap_clock += delta
	ht_t += delta
	ht_frames += 1
	match ht_mode:
		"snap":
			ht_ok = ht_ok and can_flick
			ht_angle += deg_to_rad(HT_SNAP_DEG / HT_SNAP_FRAMES)
			if ht_frames >= HT_SNAP_FRAMES:
				ht_mode = ""
				if ht_ok:
					stat("humantest_snaps")   # the detector sees this frame after this function: same state
				else:
					stat("humantest_snaps_interrupted")
		"turn":
			ht_angle += deg_to_rad(180.0) * delta / HT_TURN_TIME
			if ht_t >= HT_TURN_TIME:
				stat("humantest_smooth_turns")
				_ht_start("pull")
				stat("humantest_pulls")
		"pull":
			ht_dist = lerpf(HT_PULL_FROM, HT_PULL_TO, minf(ht_t / HT_PULL_TIME, 1.0))
			if controls.turbo_pull():
				stat("humantest_pull_turbo_frames")
			if ht_t >= HT_PULL_TIME + HT_PULL_HOLD:
				ht_dist = 1.0
				ht_mode = ""
		"tap":
			if ht_frames >= HT_TAP_FRAMES:
				_on_a_released()
				ht_mode = ""
		_:
			var diff: float = wrapf(goal_angle - ht_angle, -PI, PI)
			var step: float = deg_to_rad(HT_STEER_RATE) * delta
			ht_angle += clampf(diff, -step, step)
			if can_flick:
				var far: bool = _ht_hoop_ft() > PlayerScript.LAYUP_RANGE + 1.0 and _ht_hoop_ft() < HT_SHOOT_MAX_FT
				if ht_snap_clock >= HT_SNAP_EVERY:
					ht_snap_clock = 0.0
					ht_ok = true
					_ht_start("snap")
				elif ht_turn_clock >= HT_TURN_EVERY:
					ht_turn_clock = 0.0
					_ht_start("turn")
				elif ht_tap_clock >= HT_TAP_EVERY and far:
					ht_tap_clock = 0.0
					_on_a_pressed()
					if human_player.shooting and human_player.rim_kind == "":
						stat("humantest_taps")
						_ht_start("tap")
	ht_angle = wrapf(ht_angle, -PI, PI)   # a sim direction; the thumb pushes the stick that moves that way on screen
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = controls.joy_center + View.world_to_stick(Vector2.from_angle(ht_angle)) * ht_dist * controls.JOY_RADIUS
	controls._input(drag)

# press A and count it as a "random" or "timed" poke if it really poked the handler (and if it stole the ball)
func _ht_poke(kind: String) -> void:
	var pokes: int = stats.get("steal_pokes_t%d" % HUMAN_TEAM, 0)
	var steals: int = stats.get("human_steals", 0)
	_on_a_pressed()
	if stats.get("steal_pokes_t%d" % HUMAN_TEAM, 0) > pokes:
		stat("humantest_%s_pokes" % kind)
		if stats.get("human_steals", 0) > steals:
			stat("humantest_%s_steals" % kind)

# on defense, now and then poke at the right moment: next to the handler, ball exposed and low on the dribble
func _humantest_timed_poke(delta: float) -> void:
	ht_poke_wait -= delta
	var h = ball.holder
	if ht_poke_wait > 0.0 or ball.state != ball.HELD or h == null or h.team == HUMAN_TEAM:
		return
	if human_player.steal_cooldown > 0.0 or human_player.position.distance_to(h.position) > STEAL_POKE_PX:
		return
	if human_steal_cue():
		ht_poke_wait = HT_TIMED_POKE_GAP
		_ht_poke("timed")
		_on_a_released()

# on defense: when the CPU shooter near the human starts a shot (jumper, pump fake or rim move) and A says BLOCK,
# press it HT_BLOCK_DELAY later on every 2nd shot ("timed") and at once on the others ("early")
func _humantest_block(delta: float) -> void:
	var t = ball.holder if ball.state == ball.HELD else null
	var shooting: bool = t != null and t.team != HUMAN_TEAM and t.shooting
	ht_pre_t -= delta
	# an "early" turn on a drive: jump as soon as A says BLOCK (handler driving inside BLOCK_RIM_FT), before he takes
	# off. That is the earliest a thumb can jump at a rim move; on a take-off right there it is on time anyway
	if ht_block_n % 2 == 0 and ht_block_wait < 0.0 and ht_pre_t <= 0.0 and t != null and t.team != HUMAN_TEAM \
			and not shooting and not t.is_airborne() and input.defense_action() == "BLOCK" \
			and t.velocity.dot((attack_hoop(t.team) - t.position).normalized()) > HT_EARLY_DRIVE_SPEED * t.speed:
		ht_block_n += 1
		ht_block_wait = 0.0
		ht_pre_t = HT_EARLY_HOLD
		stat("humantest_block_tries")
	elif shooting and not ht_threat_shooting and input.defense_action() == "BLOCK" and ht_pre_t <= 0.0:
		ht_block_n += 1
		ht_block_wait = HT_BLOCK_DELAY if ht_block_n % 2 == 0 else 0.0
		stat("humantest_block_tries")
	ht_threat_shooting = shooting
	if ht_block_wait < 0.0:
		return
	ht_block_wait -= delta
	if ht_block_wait > 0.0:
		return
	var kind := "timed" if ht_block_n % 2 == 0 else "early"
	ht_block_wait = -1.0
	var jumps: int = stats.get("human_block_jumps", 0)
	ht_jump_kind = kind
	_on_a_pressed()
	_on_a_released()
	if stats.get("human_block_jumps", 0) > jumps:
		stat("humantest_%s_jumps" % kind)
		var th = input.block_threat()
		ht_jump_phase = "none"
		if th != null:
			ht_jump_phase = "rim" if th.rim_kind != "" else ("fake" if th.fake_t > 0.0 else ("shot" if th.shooting else "drive"))
		stat("humantest_%s_jumps_%s" % [kind, ht_jump_phase])

# on offense without the ball: CALL every HT_CALL_EVERY s (the thumb runs at the rim, so some calls are lobs).
# With the ball: now and then PASS when a teammate is near the rim (an alley-oop try once P2-09 lands).
func _humantest_call(delta: float) -> void:
	ht_lob_wait -= delta
	if possession != HUMAN_TEAM or ball.state == ball.DEAD:
		return
	if human_player.has_ball():
		if ht_lob_wait > 0.0 or human_player.shooting or human_player.rim_kind != "":
			return
		for mate in teams[HUMAN_TEAM]:
			if mate != human_player and mate.position.distance_to(attack_hoop(HUMAN_TEAM)) < HT_LOB_FT * FT:
				ht_lob_wait = HT_LOB_GAP
				stat("humantest_rim_passes")
				_on_b_pressed()
				return
		return
	if ball.state != ball.HELD or ball.holder == null or ball.holder.team != HUMAN_TEAM:
		return
	ht_call_clock += delta
	if ht_call_clock >= HT_CALL_EVERY:
		ht_call_clock = 0.0
		var calls: int = stats.get("human_calls", 0)
		_on_b_pressed()
		if stats.get("human_calls", 0) > calls:
			stat("humantest_calls")

# at the free-throw line: press SHOOT HT_FT_DELAY after getting the ball, release in the green zone on every 2nd free
# throw ("good") and early on the others; count attempts and makes of each
func _humantest_free_throw(delta: float) -> void:
	var h = human_player
	if rules.ft_shooter != h or not h.has_ball():
		ht_ft_t = 0.0
		return
	if not h.shooting:
		ht_ft_kind = ""
		ht_ft_t += delta
		if ht_ft_t >= HT_FT_DELAY:
			ht_ft_t = 0.0
			ht_ft_n += 1
			ht_ft_kind = "good" if ht_ft_n % 2 == 0 else "early"
			_on_a_pressed()
		return
	if ht_ft_kind == "":
		return
	if h.shot_charge >= (HT_FT_GOOD_CHARGE if ht_ft_kind == "good" else HT_FT_EARLY_CHARGE):
		var k: String = ht_ft_kind
		ht_ft_kind = ""
		stat("humantest_ft_%s" % k)
		_on_a_released()
		if ball.state == ball.SHOT and ball.shot_made:
			stat("humantest_ft_%s_makes" % k)

# stay-in-front metric: while a CPU handler in his frontcourt is within HT_GUARD_FT of the human, count the frames
# the human is between him and the rim, and each time the handler gets past him (closer to the rim by the margin)
func _humantest_guard_metric() -> void:
	var h = ball.holder if ball.state == ball.HELD else null
	var d = human_player
	var on: bool = h != null and h.team != HUMAN_TEAM and in_frontcourt(h.position, h.team) \
			and not h.is_airborne() and d.position.distance_to(h.position) <= HT_GUARD_FT * FT
	if not on:
		ht_guard_on = false
		return
	var hoop: Vector2 = attack_hoop(h.team)
	var lead_ft: float = (h.position.distance_to(hoop) - d.position.distance_to(hoop)) / FT
	if not ht_guard_on or h != ht_guard_holder:
		stat("humantest_guard_spells")
		ht_guard_holder = h
		ht_guard_front = lead_ft > 0.0
	elif ht_guard_front and lead_ft < -HT_BEAT_MARGIN_FT:
		ht_guard_front = false
		stat("humantest_guard_beaten")   # was in front, now the handler is past him
	elif not ht_guard_front and lead_ft > HT_BEAT_MARGIN_FT:
		ht_guard_front = true
	ht_guard_on = true
	stat("humantest_guard_frames")
	if ht_guard_front:
		stat("humantest_guard_front_frames")

func _ht_summary() -> String:
	var f := func(a: String, b: String) -> String:
		return "%d/%d" % [stats.get(a, 0), stats.get(b, 0)]
	var gf: int = stats.get("humantest_guard_frames", 0)
	var front_pct: float = 100.0 * float(stats.get("humantest_guard_front_frames", 0)) / float(maxi(gf, 1))
	return "HUMANTEST steals timed %s random %s | blocks timed %s early %s | in front %.0f%% beaten %d in %d spells | assist %d frames, %d while pulling away, crossovers beat him %s | free throws good %s early %s" % [
		f.call("humantest_timed_steals", "humantest_timed_pokes"), f.call("humantest_random_steals", "humantest_random_pokes"),
		f.call("humantest_timed_blocks", "humantest_timed_jumps"), f.call("humantest_early_blocks", "humantest_early_jumps"),
		front_pct, stats.get("humantest_guard_beaten", 0), stats.get("humantest_guard_spells", 0),
		stats.get("human_assist_frames", 0), stats.get("humantest_away_assist_frames", 0),
		f.call("human_cross_beaten", "human_cross_faced"),
		f.call("humantest_ft_good_makes", "humantest_ft_good"), f.call("humantest_ft_early_makes", "humantest_ft_early")]

func _ht_hoop_ft() -> float:
	return human_player.position.distance_to(attack_hoop(HUMAN_TEAM)) / FT

func _ht_start(mode: String) -> void:
	ht_mode = mode
	ht_t = 0.0
	ht_frames = 0
	if mode == "pull":
		ht_dist = HT_PULL_FROM

func _separate_players() -> void:
	var min_d := 24.0
	for i in players.size():
		for j in range(i + 1, players.size()):
			var a = players[i]
			var b = players[j]
			var d: Vector2 = b.position - a.position
			var l := d.length()
			if l < min_d and l > 0.01:
				var push := d / l * (min_d - l) * 0.5
				a.position -= push
				b.position += push

# the game is won (rules.gd decides when): stop play, show the result and the level panel (P3-08), print the test lines
func on_game_over(winner: int) -> void:
	game_over = true
	audio.play("whistle")
	ball.make_dead()
	# _physics_process stops updating after game over: put out the fire and the trail now
	for p in players:
		if p.on_fire:
			_end_fire(p)
	_trail_on = false
	fx.set_trail(false)
	audio.play("whistle", 3.0, 0.0)   # second, louder whistle: game over
	_update_hud()
	# a trip game (not the --city CPU test): FINAL, then the result screen after Flow.RESULT_DELAY s. Under
	# --trip-test always, even when its driver made the game CPU vs CPU
	var trip_end: bool = Flow.in_trip() and (Flow.test != "" or not (autoplay or humantest))
	if autoplay or humantest or trip_end:
		show_message("FINAL  %d - %d\n%s WINS!" % [score[0], score[1], TEAM_NAMES[winner]], 9999.0, TEAM_COLORS[winner])
		if trip_end:
			stats["team_stats"] = [team_stats(0), team_stats(1)]
			var fin := func() -> void:
				Flow.game_finished(winner, score, stats)
			get_tree().create_timer(Flow.RESULT_DELAY).timeout.connect(fin)
	else:
		# P3-08: the level panel under the final score; a tap on a level plays again
		msg_label.visible = false
		_menu_input(true)
		menu.show_game_over(score, winner, TEAM_COLORS[winner])
	if (autoplay or humantest) and not trip_end:
		var secs: int = int(rules.play_time)
		print("FINAL BLUE %d - RED %d" % [score[0], score[1]])
		print("GAME LENGTH %d:%02d" % [secs / 60, secs % 60])
		var g := func(k: String) -> int:
			return int(stats.get(k, 0))
		print("FOULS BLUE %d RED %d (shooting %d, reach %d, and-ones %d) | FREE THROWS %d/%d (BLUE %d/%d, RED %d/%d), last missed %d, timeouts %d" % [
				g.call("fouls_t0"), g.call("fouls_t1"), g.call("fouls_shooting"), g.call("fouls_reach"), g.call("and_ones"),
				g.call("free_throw_makes"), g.call("free_throws"), g.call("ft_makes_t0"), g.call("ft_attempts_t0"),
				g.call("ft_makes_t1"), g.call("ft_attempts_t1"), g.call("ft_last_misses"), g.call("ft_timeouts")])
		var ts := func(t: int) -> String:
			var d: Dictionary = team_stats(t)
			return "%s %d pts, shots %d/%d, dunks %d, steals %d, blocks %d" % [TEAM_NAMES[t], d.points, d.makes,
					d.shots, d.dunks, d.steals, d.blocks]
		print("TEAMS %s | %s" % [ts.call(0), ts.call(1)])   # the pause screen's numbers (team_stats)
		if Twists.active():
			print(_twist_summary())
		print(stats)
		if humantest:
			print(_ht_summary())
		get_tree().quit()

# ---------------- HUD ----------------

# lit STEAL: a pulsing ring on the floor where the dribble bounces (P2.5), next to where the eyes are (decals layer)
func _draw_steal_cue() -> void:
	if controls.a_glow and ball.state == ball.HELD and ball.holder != null:
		var pulse: float = 0.5 + 0.5 * sin(float(_frame) * 0.5)
		draw_floor_ring(_steal_node, ball.position, 9.0 + 2.0 * pulse, STEAL_CUE_RING_COLOR, 2.5)

# a circle of radius r (sim px) lying on the floor at sim point center, drawn through the view: FLAT a circle (as
# before), ANGLED the projected ellipse. For any decal node (shadows, rings): call it from that node's draw callback.
func draw_floor_ring(node: CanvasItem, center: Vector2, r: float, color: Color, width: float, segments := 24) -> void:
	if not View.angled():
		node.draw_arc(center, r, 0, TAU, segments, color, width)
		return
	var pts := PackedVector2Array()
	for i in segments + 1:
		pts.append(View.to_screen(center + Vector2.from_angle(TAU * float(i) / float(segments)) * r))
	node.draw_polyline(pts, color, width)

# the call was heard: a "!" speech bubble over the caller, plus a faint line from the teammate with the ball
# (overlay layer; the bubble floats CALL_CUE_GAP over the caller's drawn head, above his arrow)
func _draw_call_cue() -> void:
	if autoplay or not input.call_active() or human_player == null:
		return
	var h = human_player
	var pulse: float = 0.5 + 0.5 * sin(input.call_t * 18.0)
	var tip: Vector2 = player_head_screen(h) - Vector2(0, CALL_CUE_GAP)
	var c: Vector2 = tip - Vector2(0, CALL_CUE_TAIL + 3.0 * pulse)
	var q = input.call_passer()
	if q != null:
		_call_node.draw_line(View.to_screen(q.position), View.to_screen(h.position), Color(CALL_CUE_COLOR, 0.35), 2.0)
	_call_node.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 9), c + Vector2(5, 9), tip]), Color.WHITE)
	_call_node.draw_circle(c, 12.0, Color.WHITE)
	_call_node.draw_arc(c, 12.0, 0, TAU, 24, CALL_CUE_COLOR, 2.5)
	var font := ThemeDB.fallback_font
	var fs := 20
	var w: float = font.get_string_size("!", HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	_call_node.draw_string(font, c + Vector2(-w / 2.0, fs * 0.36), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.2, 0.5))

# the top of p's drawn head on screen (as player.gd places its arrow): the feet lifted by the jump, plus the sheet's
# head height (view_head_px(): v1 80, v2 about 100) at the depth's size
func player_head_screen(p) -> Vector2:
	var lift = p.get("_v_lift")
	var head: float = float(p.view_head_px()) if p.has_method("view_head_px") else CAM_TOP_FT * FT
	return View.to_screen(p.position, float(lift) if lift != null else float(p.jump_z)) \
			- Vector2(0, head * View.size_at(p.position))

func show_message(text: String, time := 1.2, color := Color.WHITE) -> void:
	msg_label.text = text
	msg_label.modulate = color
	msg_label.modulate.a = 1.0
	msg_timer = time
	msg_age = 0.0
	msg_label.pivot_offset = msg_label.size / 2.0
	msg_label.scale = Vector2(MSG_POP_SCALE, MSG_POP_SCALE)

func _update_message(delta: float) -> void:
	if _twist_line_t > 0.0:
		_twist_line_t -= delta
		twist_label.modulate.a = clampf(_twist_line_t / TWIST_LINE_FADE, 0.0, 1.0)
		if _twist_line_t <= 0.0:
			twist_label.visible = false
	if msg_timer > 0.0:
		msg_timer -= delta
		msg_age += delta
		var k: float = minf(msg_age / MSG_POP_TIME, 1.0)
		var sc: float = lerpf(MSG_POP_SCALE, 1.0, 1.0 - (1.0 - k) * (1.0 - k))   # ease out
		msg_label.pivot_offset = msg_label.size / 2.0
		msg_label.scale = Vector2(sc, sc)
		if msg_timer < 0.4:
			msg_label.modulate.a = maxf(0.0, msg_timer / 0.4)

func _update_hud() -> void:
	# the arrow next to BLUE shows which way BLUE attacks; it flips at the side switch
	if attack_hoop(HUMAN_TEAM).x > COURT_W / 2:
		score_label.text = "%s %s  %d   -   %d  %s" % [TEAM_NAMES[0], SIDE_ARROW_RIGHT, score[0], score[1], TEAM_NAMES[1]]
	else:
		score_label.text = "%s %s  %d   -   %d  %s" % [SIDE_ARROW_LEFT, TEAM_NAMES[0], score[0], score[1], TEAM_NAMES[1]]
	var gp := -1
	for t in 2:
		if rules.is_game_point(t):
			gp = t if gp < 0 else 2   # 2: both teams at game point
	if gp >= 0:
		clock_label.text = "GAME POINT"
		clock_label.modulate = TEAM_COLORS[gp] if gp < 2 else Color.WHITE
	else:
		clock_label.text = "FIRST TO %d" % rules.target
		clock_label.modulate = Color.WHITE
	if rules.GAME_TIME_CAP > 0.0:
		var t: float = rules.time_left()
		clock_label.text += "  %d:%02d" % [int(t) / 60, int(t) % 60]
	shot_label.text = "SHOT %d" % int(ceil(max(shot_clock, 0.0)))
	ft_label.text = rules.ft_hud_text()
	if rules.ft_phase != "" and rules.ft_shooter != null:
		ft_label.modulate = TEAM_COLORS[rules.ft_shooter.team]
	if rules.ft_active and not (human_player != null and human_player == rules.ft_shooter):
		controls.a_text = "-"   # someone else is at the line: wait
		controls.b_text = "-"
	elif rules.ft_active:
		controls.a_text = "SHOOT"
		controls.b_text = "-"
	elif human_player != null and human_player.has_ball():
		controls.a_text = "SHOOT"
		controls.b_text = "PASS"
	elif possession == HUMAN_TEAM and ball.state != ball.DEAD:
		controls.a_text = "-"
		controls.b_text = "CALL"
	else:
		controls.a_text = input.defense_action()   # "STEAL" or "BLOCK" (human_input.gd picks)
		controls.b_text = "SWITCH"
	controls.b_glow = controls.b_text == "CALL" and not autoplay and input.call_active()
	controls.b_dim = controls.b_text == "CALL" and input.call_cd > 0.0 and not input.call_active()
	if controls.b_glow:
		stat("human_call_cue_frames")
	controls.a_block = controls.a_text == "BLOCK"
	if controls.a_block and not autoplay:
		stat("human_block_label_frames")
	controls.a_glow = controls.a_text == "STEAL" and not autoplay and human_steal_cue()
	if controls.a_glow:
		stat("human_steal_cue_frames")

# ---------------- -- --backtest (P7-10) ----------------
# On the root, so it lives across the reloads. Goes to each screen, waits until its tap guard has passed, sends the
# back request the way the engine does (propagated from the root) and checks where it landed. Trip screens use the
# test save (user://trip_test.json). Prints BACKTEST lines, then BACKTEST OK (exit 0) or BACKTEST FAILED (exit 1).
#   godot --headless --path . --fixed-fps 60 --quit-after 20000 -- --backtest
class BackTest extends Node:
	const FlowS = preload("res://scripts/flow.gd")
	const SaveS = preload("res://scripts/save.gd")
	const TripS = preload("res://scripts/trip.gd")
	const MenuS = preload("res://scripts/menu.gd")
	# go: the screen to open ("" = stay in this game); expect: the screen after back; did: what main.gd reports
	const STEPS := [
		{"go": "title", "expect": "title", "did": "quit"},
		{"go": "title", "panel": "trip", "expect": "title", "expect_panel": "main", "did": "escape"},
		{"go": "settings", "expect": "title", "did": "escape"},
		{"go": "crew", "expect": "title", "did": "escape"},
		{"go": "howto", "args": {"back": "title"}, "expect": "title", "did": "escape"},
		{"go": "map", "trip": true, "expect": "title", "did": "escape"},
		{"go": "lineup", "trip": true, "expect": "map", "did": "escape"},
		{"go": "story", "trip": true, "args": {"scene": "hometown_arrive", "then": "lineup"}, "expect": "lineup",
				"did": "escape"},
		{"go": "bracket", "trip": true, "expect": "title", "did": "escape"},
		{"go": "points", "trip": true, "args": {"then": "map"}, "expect": "points", "did": "escape"},
		{"go": "recruit", "trip": true, "expect": "recruit", "did": "escape"},
		{"go": "game", "quick": true, "expect": "title", "did": "escape"},
		{"go": "game", "trip": true, "expect": "game", "did": "pause", "paused": true},
		{"go": "", "expect": "game", "did": "resume", "paused": false},
		{"go": "", "expect": "game", "did": "pause", "paused": true},
	]
	var _i := -1
	var _t := 0
	var _phase := 0          # 0 = open the next screen, 1 = wait, then send back, 2 = wait, then check
	var _did := ""
	var _errors := 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		SaveS.use_test_file = true
		print("BACKTEST start | save file %s" % SaveS.path())

	func note(did: String) -> void:
		_did = did

	func _process(_delta: float) -> void:
		_t += 1
		match _phase:
			0:
				_i += 1
				if _i >= STEPS.size():
					_finish()
					return
				_open(STEPS[_i])
				_t = 0
				_phase = 1
			1:
				var st: Dictionary = STEPS[_i]
				if _t >= BACKTEST_ARM_FRAMES and _ready_for(st):
					if st.has("panel"):
						var node: Node = FlowS.current_screen()
						if node != null and node.has_method("_show_panel"):
							node.call("_show_panel", st["panel"])
					_did = ""
					get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
					_t = 0
					_phase = 2
				elif _t > BACKTEST_GAME_WAIT:
					_fail("step %d: %s never got ready for the back request" % [_i + 1, str(FlowS.screen)])
					_phase = 0
			2:
				if _t >= BACKTEST_LAND_FRAMES:
					_check(STEPS[_i])
					_phase = 0

	func _open(st: Dictionary) -> void:
		var to: String = str(st.get("go", ""))
		if to == "":
			return
		if bool(st.get("trip", false)) and not TripS.active:
			TripS.new_trip()
		if to == FlowS.GAME:
			if bool(st.get("quick", false)):
				MenuS.start_done = false   # the start panel (level, court) shows
				FlowS.match = {}
			else:
				FlowS.match = TripS.match_for()
		FlowS.go(to, st.get("args", {}))

	# a game: wait until the pause is allowed (after tip-off and the resume guard), or the start panel is up
	func _ready_for(st: Dictionary) -> bool:
		if str(FlowS.screen) != FlowS.GAME:
			return true
		var m: Node = get_tree().current_scene
		if m == null:
			return false
		if bool(st.get("quick", false)):
			var menu = m.get("menu")
			return menu != null and bool(menu.get("showing"))
		var p = m.get("pause_node")
		if p == null:
			return false
		if bool(p.get("_open")):
			return true
		return float(p.get("_guard_t")) <= 0.0 and bool(p.call("can_pause"))

	func _check(st: Dictionary) -> void:
		var scr: String = str(FlowS.screen)
		var name_s: String = str(st.get("go", ""))
		var what: String = "step %d (%s): did %s, now on %s" % [_i + 1, name_s if name_s != "" else "same game",
				_did, scr]
		var ok: bool = scr == str(st["expect"]) and _did == str(st["did"])
		if st.has("expect_panel"):
			var node: Node = FlowS.current_screen()
			var panel: String = str(node.get("_panel")) if node != null else ""
			what += " panel " + panel
			ok = ok and panel == str(st["expect_panel"])
		if st.has("paused"):
			var m: Node = get_tree().current_scene
			var p = m.get("pause_node") if m != null else null
			var open: bool = p != null and bool(p.get("_open"))
			what += " | pause panel %s, tree paused %s" % ["open" if open else "closed", str(get_tree().paused)]
			ok = ok and open == bool(st["paused"]) and get_tree().paused == bool(st["paused"])
		print("BACKTEST %s %s" % ["ok  " if ok else "FAIL", what])
		if not ok:
			_errors += 1

	func _fail(why: String) -> void:
		print("BACKTEST FAIL " + why)
		_errors += 1

	func _finish() -> void:
		set_process(false)
		get_tree().paused = false
		SaveS.erase()
		print("BACKTEST OK" if _errors == 0 else "BACKTEST FAILED (%d)" % _errors)
		get_tree().quit(0 if _errors == 0 else 1)
