extends Node2D
# One basketball player. Either driven by the touch controls (the human) or by the CPU brain below.
# CPU defense lives in defense.gd (one instance per player, `def`).

const Defense = preload("res://scripts/defense.gd")
const Difficulty = preload("res://scripts/difficulty.gd")   # CPU skill knobs by level (P3-03; Hard = the constant)
const View = preload("res://scripts/view.gd")               # projection (Phase 4): FLAT draws as before, ANGLED below
const Ratings = preload("res://scripts/ratings.gd")         # stat -> gameplay multipliers (P5; rating 50 = 1.0)
const Twists = preload("res://scripts/twists.gd")           # Phase 6 city twists (speed, turbo, stamina, wet grip)
const Sheets = preload("res://scripts/sheets.gd")           # sprite sheet formats v1 / v2 (P6-05; drawing only)

var game
var team := 0
var index := 0
var sprite: Sprite2D
var velocity := Vector2.ZERO
var facing := 0.0
const BASE_SPEED := 170.0         # top speed in px/s at speed rating 50 (Ratings.speed_px scales it)
var speed := BASE_SPEED
var target := Vector2.ZERO
var speed_mult := 1.0
var spot_index := 0
var spot_timer := 0.0
var decision_timer := 0.0
var _cpu_had_ball := false       # CPU: had the ball last frame (a catch resets the decision timer)
var kick_catch := false           # CPU: a kick-out pass is coming to me (spot up for it)
var _cpu_catch_t := 0.0          # CPU: seconds since he caught the ball (cpu_twos_catch / _dribble counters)
var cpu_three_try := false        # this CPU jumper was chosen as a 2 (beyond the arc): counts cpu_threes_inside
var steal_cooldown := 0.0
var steal_timer := 0.0
var shooting := false
var shot_charge := 0.0
var cpu_shot_time := 0.0
var shot_contest_t := 0.0        # seconds a defender has been within CLOSEOUT_FT during this jump shot
var shot_elapsed := 0.0           # seconds since this jump shot (or meter) started
var shot_grace := 0.35            # this shot's closeout grace (CLOSEOUT_GRACE, shorter for a CPU windup)
var def                           # defense brain (defense.gd), created in setup()

# ---- shared move state (Phase 2 contract; later tasks fill these in) ----
const BLOCK_JUMP_TIME := 0.5      # seconds in the air for a defender's block jump
const BLOCK_JUMP_PX := 26.0       # block jump height in pixels (drawn through jump_z)
const BLOCK_JUMP_MOMENTUM := 0.4  # fraction of the take-off velocity kept while airborne (no steering)
const STUMBLE_SPEED_MULT := 0.35  # speed multiplier while off balance (no turbo either)
const GUARD_FT := 4.0             # close guarding: a defender this close in front of the handler slows him
const GUARD_CONE := 50.0          # degrees either side of the handler's movement direction that count as "in front"
const GUARD_SLOW := 0.82          # handler speed multiplier while closely guarded (turbo still applies on top)

var stumble_t := 0.0              # seconds left off balance (slow, can't steal or jump)
var poke_t := 0.0                 # seconds left standing still after a steal attempt (main.STEAL_POKE_FREEZE)
var block_jump_t := -1.0          # seconds since a block jump started (< 0 = not jumping)
var block_jump_vel := Vector2.ZERO
var cross_t := 0.0                # seconds left in a crossover/spin (P2-05)
var move_kind := ""               # "cross" or "spin" (P2-05)
var dribble_side := 1.0           # +1 right hand, -1 left hand (P2-05)
var fake_t := 0.0                 # seconds left in a pump fake (P2-06)
var alley_cut := false            # cutting to the rim for a lob (P2-09)

# ---- player ratings (0-100, 50 = average). Read them with rating("steal") / rating("block"). ----
# Per roster slot (index 0-2), the same for both teams so they stay balanced (each column sums to 150).
const RATINGS_BY_INDEX := [
	{"steal": 75, "block": 40},   # quick hands
	{"steal": 40, "block": 75},   # shot-blocker
	{"steal": 35, "block": 35},
]
const BLOCK_GOOD_BASE := 0.7      # well-timed block jump at block rating 50: success chance
const BLOCK_RATING_SPAN := 0.2    # +/- this across ratings 0..100 (0.5 at 0, 0.9 at 100)
const BLOCK_BAD_CHANCE := 0.03    # badly timed block jump: success chance (any rating)
const BLOCK_HUMAN_GOOD_BONUS := 0.1   # human (P2.5): a well-timed block jump's chance + this (rating 50: 0.7 -> 0.8)
const RIM_BLOCK_RATING_SPAN := 0.5  # rim-block dice (defense.rim_blocker) x0.5 at rating 0, x1.5 at 100

var ratings := {"steal": 50, "block": 50}

# ---- P9-20 signature moves (owner L6 b): a legend's small play edge, read from "signature" in his player dict
# (legends.gd legend_player, trip.gd player_dict). "" (everyone else) = today's game, every rule below is skipped.
const SIG_HOOK := "hook"                  # Steeple: close jumpers are hook shots (the "hook" frames), hard to block
const SIG_KEEP_BLOCK := "keep_block"      # Gate: his blocks stay in play (defense.gd keep_block)
const SIG_DEEP_SET := "deep_set"          # Set Shot: his long-range falloff starts further out
const SIG_LONG_DUNK := "long_dunk"        # Boxcar: dunks from further out
const SIG_FINGER_ROLL := "finger_roll"    # Velvet: layups slip past contests
const SIG_OUTLET := "outlet"              # Quarterback: long outlet passes (ball.gd flies them faster, safer)
const HOOK_MAX_FT := 14.0         # a hook man's jumper this close to the rim (outside LAYUP_RANGE) is a hook shot
const HOOK_BLOCK_MULT := 0.4      # block chance x this on his hooks and his layups (defense.gd asks sig_block_mult)
const HOOK_CPU_CHANCE := 0.45     # CPU hook man inside HOOK_MAX_FT with a defender within HOOK_CPU_GUARD_FT: chance per
const HOOK_CPU_GUARD_FT := 6.0    # decision to go up with the hook (a defender on him is why he shoots it)
const DEEP_SET_EXTRA_FT := 4.0    # main.shot_probability's long falloff (from 23.75 ft) starts this much further out
const DEEP_SET_ARC_FT := 23.75    # (main.gd's arc distance, as shot_probability uses it)
const LONG_DUNK_EXTRA_FT := 3.0   # dunk range DUNK_RANGE + this (6 -> 9 ft, the layup range)
const LONG_DUNK_GLIDE := 0.9      # a long dunk glides to the rim at this fraction of top speed (RIM_GLIDE otherwise)
const FINGER_ROLL_KEEP := 0.25    # a finger roll keeps this fraction of main's rim contest penalty (0 = none)
const FINGER_ROLL_CPU_LAYUP := 0.8  # CPU finger roller: chance he pulls up for the layup entering LAYUP_RANGE
const OUTLET_MIN_FT := 34.0       # an outlet: an outlet passer's pass this long or longer (ball.gd reads it)
const OUTLET_OPEN_FT := 8.0       # CPU outlet passer in his backcourt: a teammate this open in the frontcourt ...
const OUTLET_HOOP_FT := 30.0      # ... and this close to the hoop, with at most OUTLET_AHEAD opponents between him
const OUTLET_AHEAD := 0           # and the hoop, gets the long pass
var signature := ""               # P9-20: his move id ("" = none)
var hook_shot := false            # the current / last jumper is a hook (drawn with the hook frames; harder to block)
var long_dunk := false            # this dunk took off beyond DUNK_RANGE (glides further; drawn two-handed)
var _sig_print := false           # test runs (any user argument) print a SIGNATURE line when a move fires
# P5-03: the player dict from Flow.match (board "Match config"); {} in Quick Game. Ratings missing from it are 50.
const CREW_SHEET_SUFFIX := "_crew"           # a city player's recolor in your colors, used when he plays for team 0
# Quick Game (no match dict) and the last fallback of a trip player: the sheet of each slot (P6-25; the old v1
# blue_n / red_n sheets are gone). BLUE wears your underdogs, RED the Bridge Runners (New York quarterfinal, red and
# black), matched to the slot's steal / block (RATINGS_BY_INDEX): 0 quick hands, 1 shot-blocker, 2 the third man.
# Sheets.load_first() finds them in assets/players2/; with no sheet at all the Kenney sprite (assets/blue_n.png) draws.
const QUICK_SHEETS := [["ud_jojo", "ud_tank", "ud_deuce"], ["ny_q2", "ny_q1", "ny_q3"]]
var pdata := {}
var pid := ""                     # cities.gd PLAYERS id ("" in Quick Game)
var pname := ""                   # shown name ("" in Quick Game)

# ---- crossover and the dribble hand (P2-05; owner Q1: crossover only, a "spin" flick is a crossover too) ----
const CROSS_TIME := 0.3           # seconds of the crossover burst
const CROSS_SPEED_MULT := 1.25    # speed multiplier during the burst
const CROSS_ACCEL := 3200.0       # px/s^2 during the burst (normal 1600): the cut is sharp
const CROSS_COOLDOWN := 0.6       # seconds from the start of one crossover to the next
const CROSS_BEAT_FT := 5.0        # a defender this close in front of the handler can be beaten
const CROSS_BEAT_CONE := 75.0     # degrees either side of the handler's facing that count as "in front"
const CROSS_STUN := 0.45          # seconds a beaten defender stumbles
const CROSS_BEAT_CHANCE := 0.5    # CPU defender not moving the wrong way: chance he is beaten (until def decides)
const CROSS_WRONG_WAY_SPEED := 40.0  # px/s: a defender moving at least this fast away from the cut is beaten
const CROSS_HAND_RATE := 13.0     # dribble hand travel per second during a crossover (2.0 = one hand to the other)
const HAND_SWITCH_RATE := 4.0     # same for the slow switch away from a defender
const HAND_SWITCH_FT := 8.0       # the nearest defender inside this, on the ball side ...
const HAND_SWITCH_DELAY := 0.5    # ... for this long: the handler moves the ball to the other hand
const CPU_CROSS_CHANCE := 0.04    # CPU handler, defender close in front and the lane shut: chance per decision
const CPU_CROSS_FT := 5.0         # "close" for that decision
const CPU_CROSS_COMMIT := 0.7     # seconds the CPU keeps going the new way after a crossover
const BEAT_POPUP_COLOR := Color(1.0, 0.95, 0.3)

var cross_cd := 0.0               # seconds until the next crossover is allowed
var cross_dir := Vector2.ZERO     # direction of the current crossover burst
var hand_x := 1.0                 # where the ball is drawn sideways, -1 left hand .. +1 right hand (follows dribble_side)
var hand_switch_t := 0.0          # seconds the nearest defender has been on the ball side
var cpu_side := 0.0               # CPU: sidestep side committed to after a crossover
var cpu_side_t := 0.0
var _call_held := false           # CPU handler is holding the ball for the human's live call (counted once per call)

# ---- pump fake (P2-06; owner Q2: only away from the rim, where the shot meter shows) ----
const PUMP_TAP_MAX := 0.15        # human: A released this soon after the meter started = pump fake (human_input.SHORT_TAP_MAX)
const PUMP_TIME := 0.3            # seconds the fake lasts (ball raised, small hop)
const PUMP_HOP_PX := 7.0          # height of the little hop
const PUMP_MOVE_MULT := 0.35      # human can move slowly during the fake
const PUMP_BITE_WINDOW := 0.4     # a defender starting a block jump this soon after the fake "bit"
const PUMP_SCORE_WINDOW := 2.5    # a make this soon after a fake counts as pump_and_score
const CPU_PUMP_CHANCE := 0.04     # CPU handler, defender close in front, outside the rim range: chance per decision
const CPU_PUMP_FT := 5.0          # "close" for that decision
const CPU_PUMP_MAX_FT := 24.0     # CPU only fakes inside this distance from the rim (a believable shot)
const CPU_BITE_SHOOT_CHANCE := 0.5  # after a bite: chance to step in for the shot (else drive past on turbo)
const CPU_BITE_SHOOT_FT := 20.0   # shoot after a bite only inside this
const CPU_BITE_DRIVE := 0.8       # seconds the CPU sprints to the rim after a bite

var cpu_faking := false           # CPU fake in progress (shooting is true for the fake's time)
var since_fake := 99.0            # seconds since this player's last pump fake started
var fake_bit := false             # a defender bit on the current/last fake
var cpu_drive_t := 0.0            # CPU: seconds left driving to the rim after a bite

# ---- defensive assist (P2.5-02, owner: hard to stay in front of the ball handler). Human only. While you guard
# the ball handler and steer roughly toward him (or toward the spot between him and the basket), your defender
# slides to that spot and matches his sideways moves. You still steer: pulling clearly away, sprinting off, pressing
# STEAL/BLOCK, or being off balance (a crossover that beat you) turns it off. ----
const ASSIST_RANGE_FT := 8.0      # the handler must be this close (no assist from further away)
const ASSIST_FULL_FT := 6.0       # full strength inside this, fading to 0 at ASSIST_RANGE_FT
const ASSIST_STRENGTH := 0.6      # 0 = none, 1 = the assist alone decides the direction (autopilot)
const ASSIST_GAP_FT := 3.0        # the spot: this far in front of the handler, on the line to the basket
const ASSIST_LEAD := 0.15         # seconds of the handler's movement the spot leads by (matches his sideways moves)
const ASSIST_GAIN := 4.0          # 1/s: how hard the assist pulls toward the spot (closing speed per pixel off it)
const ASSIST_ANGLE := 75.0        # degrees: the stick must point within this of the handler or of the spot
const ASSIST_TURBO_ANGLE := 55.0  # ... and within this while sprinting (a sprint elsewhere turns it off)
const ASSIST_MIN_STICK := 0.3     # the stick must be pushed at least this far (no assist while you stand still)
const ASSIST_PRESS_OFF := 0.4     # seconds without assist after STEAL/BLOCK is pressed (human_input.gd sets it)

var assist_off_t := 0.0           # seconds left with the assist off (after a button press)
var assist_on := false            # the assist steered this frame (drawn / counted)

# ---- turbo and stamina (tuning) ----
# (how far to pull the joystick to sprint is TURBO_PULL in touch_controls.gd)
const TURBO_SPEED_MULT := 1.35    # speed multiplier while sprinting
const TURBO_BALL_MULT := 0.95     # ball handler sprints at this fraction of the turbo speed
const STAMINA_DRAIN := 0.4        # stamina per second while sprinting (1.0 = full bar, 2.5 s of sprint)
const STAMINA_REFILL := 0.25      # stamina per second while not sprinting
const REFILL_DELAY := 0.5         # seconds after easing off before stamina starts to refill
const TURBO_MIN_RESTART := 0.25   # after running empty, turbo is off until stamina is back above this
const CPU_TURBO_RESUME := 0.5     # CPU stops at TURBO_MIN_RESTART and waits for this much before sprinting again
const CPU_BEATEN_FT := 4.0        # CPU defender sprints when his man is this many feet closer to the hoop
const CPU_BREAK_FT := 20.0        # CPU fast break: sprint when at least this far from the hoop
const TURBO_SHOT_WINDOW := 0.6    # seconds after sprinting that a jump shot is still "shaky"
const TURBO_SHOT_PENALTY := 0.8   # shot quality multiplier for a jumper right after sprinting
const TURBO_SHOT_EXEMPT_FT := 6.0 # shots this close to the rim (dunks, layups) get no penalty

# ---- wet court (P6-03, Seattle twist): a sharp turn at speed slides before the new direction grips. The numbers
# (cut_grip, cut_min_speed, cut_angle_deg) are in twists.gd; without that twist cut_grip is 1.0 and nothing slides.
const SLIDE_END_DEG := 20.0       # the slide ends once he is moving within this of where he wants to go ...
const SLIDE_END_SPEED := 0.3      # ... or has slowed under this fraction of top speed ...
const SLIDE_MAX_TIME := 0.6       # ... or after this many seconds
const SLIDE_MIN_WANT := 0.9       # a cut is a slide only if he wants to go the new way at this fraction of top speed
                                  # or more (easing into a spot or stopping is not a hard cut). P6-30: was 0.5; a ball
                                  # handler's full stick is 0.94, so he still slides on a hard cut
var sliding := false              # read-only for the effects (twist_fx, P6-23 dust): a hard cut is sliding now
var _slide_t := 0.0

var stamina := 1.0
var turbo := false                # sprinting this frame
var turbo_locked := false         # ran empty, waiting to reach TURBO_MIN_RESTART
var cpu_tired := false
var cpu_turbo_want := false
var refill_wait := 0.0
var since_turbo := 99.0           # seconds since this player last sprinted
var humantest := false

# ---- dunks and layups (tuning) ----
const DUNK_RANGE := 6.0           # feet from the rim: a dunk is possible inside this
const LAYUP_RANGE := 9.0          # feet from the rim: Shoot inside this is a layup (or dunk), no shot meter
const DUNK_SPEED_FRAC := 0.7      # dunk needs at least this fraction of top speed (or turbo)
const DUNK_TIME := 0.55           # seconds in the air for a dunk
const LAYUP_TIME := 0.45          # seconds in the air for a layup
const DUNK_JUMP_PX := 30.0        # jump height in pixels (drawn as an upward offset)
const LAYUP_JUMP_PX := 20.0
const DUNK_RELEASE := 0.55        # fraction of the jump when the ball leaves the hand
const LAYUP_RELEASE := 0.5
const RIM_GLIDE := 0.45           # fraction of top speed the jumper keeps drifting toward the rim
const DUNK_OPEN_PCT := 0.92       # make chance of an open dunk (P1-09: 0.85 -> 0.92; P2-11: 0.82, scores ran high with better jumpers; P7-T1: 0.82 -> 0.92)
const LAYUP_OPEN_PCT := 0.72      # make chance of an open layup (P1-09: 0.65 -> 0.75; P2-11: back to 0.65, scores ran high; P7-T1: 0.65 -> 0.72)
const CONTEST_FT := 3.0           # nearest defender inside this contests the take-off (P2-11: was 4.0; only a defender in the play counts, see contests_me)
# (rim block chances live in defense.gd: DUNK_BLOCK_CHANCE, LAYUP_BLOCK_CHANCE, RIM_CONTEST_FT)
const CONTEST_MAKE_MULT := 1.0    # extra make-odds multiplier with a defender right on you (eases off with distance). P1-09: was 0.9; shot_probability() already applies the openness penalty, so 1.0 avoids counting it twice
const CPU_FINISH_FT := 4.5        # CPU handler finishes at the rim inside this (any speed)
const CPU_LAYUP_CHANCE := 0.45    # CPU entering LAYUP_RANGE with a defender close: chance it pulls up for a layup
const CPU_LAYUP_OPEN_CHANCE := 0.15  # same with nobody close (otherwise it keeps going for the dunk)
const CPU_LAYUP_GUARD_FT := 4.0   # "a defender close" for that roll (was CONTEST_FT before P2-11 lowered it)

# ---- CPU ball handler decisions (tuning; one roll per decision, every CPU_DECIDE_MIN..MAX s) ----
const CPU_DECIDE_MIN := 0.3       # seconds between handler decisions
const CPU_DECIDE_MAX := 0.5
const CPU_CLOCK_SHOOT := 4.0      # shot clock under this: shoot from anywhere inside CPU_CLOCK_SHOOT_FT
const CPU_CLOCK_SHOOT_FT := 32.0
const CPU_GOOD_SHOT_P := 0.40     # make chance above this with the defender CPU_GOOD_SHOT_OPEN_FT off: shoot...
const CPU_GOOD_SHOT_OPEN_FT := 4.0
const CPU_GOOD_SHOT_CHANCE := 0.5 # ...with this chance
const CPU_OPEN_SHOT_FT := 6.0     # wide open (defender this far off) inside CPU_OPEN_SHOT_RANGE: shoot...
const CPU_OPEN_SHOT_RANGE := 26.0
const CPU_OPEN_SHOT_CHANCE := 0.3 # ...with this chance
const CPU_PASS_CHANCE := 0.15     # otherwise, chance to look for an open teammate
const CPU_PASS_OPEN_EDGE := 2.0   # a teammate must be this many feet more open than me
# pull-up jumpers (R1): mid-range off the dribble when the defender gives room or is beaten
const CPU_PULLUP_MIN_FT := 12.0   # pull-up range from the rim
const CPU_PULLUP_MAX_FT := 22.0
const CPU_PULLUP_ROOM_FT := 3.0   # defender at least this far off (or behind me) to pull up
const CPU_PULLUP_CHANCE := 0.2    # chance per decision when a pull-up is on (P2-11: was 0.28)
const CPU_THREE_MAX_FT := 28.5    # deep pull-up: beyond the arc but inside this (P2-11: was 28.0)
const CPU_THREE_OPEN_FT := 3.0    # and the defender at least this far off (P2-11: was 4.0; P3-09 tried 4.0 again: 2s fell to 5 a game)
const CPU_THREE_CHANCE := 0.9     # chance per decision (P2-11: 0.25 -> 0.75; P3-09: 0.9, a 2 is worth twice a 1 now)
# kick-outs and catch-and-shoot 2s (P3-09: with 1 inside / 2 beyond, an open 2 is worth ~0.85 points a shot, a
# contested drive less; before this the CPU took only ~7 2s a game, ~12% of the points)
const CPU_KICK_MAX_FT := 20.0     # driving handler this close to the rim ...
const CPU_KICK_PRESSURE_FT := 6.0 # ... with a defender this close (or the lane shut) looks for an open shooter ...
const CPU_KICK_OPEN_FT := 4.5     # ... a teammate beyond the arc this open ...
const CPU_KICK_LANE_FT := 4.0     # ... with no opponent this close to the pass line (interceptions) ...
const CPU_KICK_CHANCE := 0.6      # ... and kicks it out with this chance per decision
const CPU_CATCH_SHOT_T := 1.0     # a 2 this soon after the catch counts as catch and shoot (cpu_twos_catch)
const CPU_CATCH_WINDUP_MIN := 0.2  # a CPU catch-and-shoot jumper: quicker windup than CPU_WINDUP_MIN..MAX
const CPU_CATCH_WINDUP_MAX := 0.3
const CPU_CATCH_DECIDE := 0.1     # a CPU who just caught the ball decides this soon (catch and shoot)
const CPU_THREE_LEAD := 0.08      # P3-09: seconds of drift ahead the 2 must still be beyond the arc (he slides about
                                  # v/(2 x 1600 px/s^2) on while stopping; without it a third of his 2s landed inside)
const CPU_SHOT_QUALITY_MIN := 1.05  # CPU jump-shot quality, random between these (P2-11: was 0.85..1.1; P2-13: 0.95..1.2 -> 1.05..1.25;
const CPU_SHOT_QUALITY_MAX := 1.25  # a human's normal release is 1.0, a perfect one 1.3)
const CPU_WINDUP_MIN := 0.3       # seconds from a CPU jumper's start to its release, random between these
const CPU_WINDUP_MAX := 0.45
# late closeouts (P2-11): main.shot_probability() judges the contest at the release. A defender who only got within
# CLOSEOUT_FT during the shot itself, or is stumbling (beaten), trailing behind the shooter, or still in the air from
# biting on a fake, gives a lighter contest (jumpers and dunks/layups).
const CLOSEOUT_FT := 3.0          # mirrors the "right on you" distance in main.shot_probability
const CLOSEOUT_GRACE := 0.35      # seconds a defender must have been that close during the shot for a full contest
const CLOSEOUT_SOFT_MULT := 0.9 / 0.55  # jumper: turns main's x0.55 (right on you) into x0.9 (a hand late in the face)
const RIM_SOFT_MULT := 0.93 / 0.85  # dunk/layup: main's RIM_CONTEST_TIGHT_MULT x0.85 becomes x0.93 (P7-T1: was x0.55 -> x0.7)
const CLOSEOUT_TRAIL_DOT := -0.3  # a defender further behind me than this (cosine to the hoop direction) is trailing
# call for the ball (P2-10/P2-11): while the human's call is live, his CPU teammate with the ball waits for it
const CPU_CALL_HOLD_CLOCK := 5.0  # ... unless the shot clock is under this (then he plays on)
const PUMP_COOLDOWN := 0.8        # seconds from one pump fake's start before another fake (a quick tap then does nothing)

# ---- alley-oop (P2-09; owner Q5: automatic. The lob rule itself is ball.is_lob_target) ----
const ALLEY_JUMP_TIME := 0.6      # seconds in the air for an alley-oop dunk
const ALLEY_JUMP_PX := 36.0       # its jump height (a normal dunk is DUNK_JUMP_PX)
const ALLEY_CATCH_F := 0.4        # fraction of the jump when the lob reaches his hands (release is at DUNK_RELEASE)
const ALLEY_MAKE_MULT := 1.3      # make-odds bonus: he catches it above the rim (P7-T1: a contested one now reaches main.SHOT_CAP 0.92; was ~65%)
const ALLEY_REACH_FT := 7.0       # the receiver only goes up for the lob this close to the rim (else a floor catch)
const ALLEY_SPOT_FT := 3.0        # a cutter heads for this spot, this far out from the rim
const ALLEY_SPOT_SIDE_FT := 3.0   # ... and at most this far to the side of it
const CPU_CUT_CHANCE := 0.08      # CPU off-ball: chance that a spot change is a cut to the rim instead
const CPU_CUT_TIME := 1.5         # seconds a cut lasts (alley_cut stays on; P2-10 cuts get the same)
const CPU_CUT_MIN_FT := 14.0      # a cut starts at least this far from the rim (time to throw the lob)
const CPU_CUT_MAN_FT := 3.0       # ... and only if my man isn't this close (tight on me: no back-door)
const CPU_LOB_CHANCE := 0.15      # CPU handler: chance per decision to lob to a teammate the lob rule allows (P2-13: was 0.25; P3-12: 0.18)
const CPU_LOB_READ_FT := 10.0     # CPU defenders this close to the receiver or the rim read a lob in the air ...
const CPU_LOB_JUMP_CHANCE := 0.45 # ... and jump to block the dunk with this chance (x CPU_LOB_RATING_SPAN)
const CPU_LOB_RATING_SPAN := 0.3  # that chance x(1 -/+ this) across block ratings 0..100
const CPU_LOB_JUMP_JITTER := 0.12 # +/- seconds of error on the timing of that jump

var alley_oop := false            # this rim move is an alley-oop (catching a lob in the air)
var alley_cut_t := 0.0            # seconds left in the current cut (alley_cut)
var _cut_on := false
var lob_jump_wait := -1.0         # CPU defender: seconds until he jumps at a lob's dunk (< 0 = none planned)
var lob_read_target = null        # CPU defender: the lob receiver he is running at

# ---- free throws (P3-06; the sequence itself is rules.gd, P3-05). While rules.ft_active everyone walks to
# rules.ft_spot(self) and stands: no turbo, crossovers, pokes or block jumps. On the last free throw everyone is
# released when the ball leaves the hand; the CPU boxes out for the live rebound. ----
const CPU_FT_WAIT_MIN := 0.8      # CPU at the line: seconds with the ball before he shoots, random between these
const CPU_FT_WAIT_MAX := 1.4
const CPU_FT_WAIT_CAP := 3.0      # ... he shoots by then even if he never got right onto his spot
const CPU_FT_QUALITY_MIN := 0.97  # CPU free-throw quality, random between these (x main's FT_BASE 0.72: ~70-77%)
const CPU_FT_QUALITY_MAX := 1.07
const FT_SPOT_TOL_FT := 1.0       # "at the spot": this close to rules.ft_spot()
const FT_WALK_MULT := 0.8         # walking to the free-throw spots (no sprint)
const BOXOUT_FT := 2.5            # box-out: get this far in front of the nearest opponent, on his line to the rim
const BOXOUT_SPEED := 0.9         # speed multiplier while boxing out
const BOXOUT_CRASH_T := 0.6       # fraction of the free throw's flight after which the chasers go for the ball

static var ft_box_serial := -1    # game.shot_serial of the last free throw of a trip, in the air (everyone released)
var ft_wait := -1.0               # CPU at the line: seconds until he shoots (< 0 = not counting)
var ft_wait_total := 0.0
var _box_counted := -1

var rim_kind := ""                # "dunk" or "layup" while in the air, "" otherwise
var jump_t := 0.0                 # seconds since take-off
var jump_time := 0.0
var jump_z := 0.0                 # current height of the jump in pixels
var jump_released := false
var rim_quality := 1.0
var cpu_rim_rolled := false       # CPU already decided layup-or-keep-going on this drive

# ---- on fire (tuning; streak rules live in main.gd) ----
const FIRE_GREEN_LO := 0.70       # human shot meter: green ("perfect") zone while on fire (normal 0.78..0.95)
const FIRE_GREEN_HI := 1.0
const GREEN_LO := 0.78            # normal green zone
const GREEN_HI := 0.95
const FIRE_SHOT_BONUS := 1.15     # make-odds multiplier for CPU jumpers and everyone's dunks/layups while on fire
const FIRE_RING_COLOR := Color(1.0, 0.45, 0.1)

var make_streak := 0              # makes in a row by this player
var on_fire := false
var fire_misses := 0              # misses/blocks while on fire (main.FIRE_MISSES puts it out)
var fire_anim := 0.0

# Offensive spots, in feet: (distance out from the baseline side of the hoop, sideways offset)
# P3-09: the top, wings and corners sit just beyond the arc (23.75 ft; 22 ft in the corners) so a kick-out there is
# a 2 (top was 24, wings 18/16 = 24.1 ft, corners 3/21: inside the corner line)
const SPOTS := [
	Vector2(24.8, 0),  # top of the key
	Vector2(18.3, -16.7),  # left wing (24.8 ft)
	Vector2(18.3, 16.7),   # right wing
	Vector2(3, -22.5),   # left corner
	Vector2(3, 22.5),    # right corner
	Vector2(5, -8),    # left block
	Vector2(5, 8),     # right block
	Vector2(17, -7),   # left elbow
	Vector2(17, 7),    # right elbow
]

# `pdict` (optional, P5-03): {"id", "name", "sheet", "ratings": {speed, shooting, finishing, defense, stamina, steal,
# block}}. Without it (Quick Game, tests) the player is today's: RATINGS_BY_INDEX steal/block, every other stat 50.
func setup(g, t: int, i: int, tex: Texture2D, pdict: Dictionary = {}) -> void:
	game = g
	team = t
	index = i
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2(1.75, 1.75)
	add_child(sprite)
	z_index = 5
	spot_index = [0, 1, 4][i]
	facing = 0.0 if team == 0 else PI
	sprite.rotation = facing
	humantest = OS.get_cmdline_user_args().has("--humantest")
	def = Defense.new(self, g)
	ratings = (RATINGS_BY_INDEX[i] as Dictionary).duplicate()
	_apply_pdict(pdict)
	speed = Ratings.speed_px(BASE_SPEED, rating("speed")) * Twists.value("speed_mult", 1.0)   # crowd 1.04, sand 0.9
	if t == Difficulty.CPU_TEAM and i == 0:
		Difficulty.init_once()   # saved level, then --difficulty (autoplay/humantest default to Hard)
		game.stat("difficulty_" + Difficulty.level_name(Difficulty.effective_level()))
	if t == 0 and i == 0:
		ft_box_serial = -1       # static: a restarted game starts shot_serial at 0 again
	if View.angled():
		_build_view()

# Ratings from the match dict. steal/block come from the dict (trip.gd derives them from defense + bias); a dict
# with defense but no steal/block derives them here (bias from the dict, 0 if absent).
func _apply_pdict(pdict: Dictionary) -> void:
	pdata = pdict
	if pdict.is_empty():
		return
	pid = str(pdict.get("id", ""))
	pname = str(pdict.get("name", ""))
	var sig = pdict.get("signature", "")
	signature = str((sig as Dictionary).get("id", "")) if sig is Dictionary else str(sig)
	_sig_print = signature != "" and OS.get_cmdline_user_args().size() > 0
	var r: Dictionary = pdict.get("ratings", {})
	for k in r:
		ratings[k] = clampi(int(r[k]), Ratings.MIN_RATING, Ratings.MAX_RATING)
	if r.has("defense"):
		var dfn: int = int(r["defense"])
		if not r.has("steal"):
			ratings["steal"] = Ratings.derived(dfn, int(pdict.get("steal_bias", 0)))
		if not r.has("block"):
			ratings["block"] = Ratings.derived(dfn, int(pdict.get("block_bias", 0)))

func has_ball() -> bool:
	return game.ball.state == game.ball.HELD and game.ball.holder == self

func update(delta: float, is_human: bool, input_vec: Vector2) -> void:
	steal_cooldown = max(0.0, steal_cooldown - delta)
	stumble_t = maxf(0.0, stumble_t - delta)
	poke_t = maxf(0.0, poke_t - delta)
	cross_cd = maxf(0.0, cross_cd - delta)
	cpu_side_t = maxf(0.0, cpu_side_t - delta)
	cpu_drive_t = maxf(0.0, cpu_drive_t - delta)
	update_pump_fake(delta)
	update_alley(delta)
	if cross_t > 0.0:
		cross_t = maxf(0.0, cross_t - delta)
		if not has_ball() or shooting or is_airborne():
			cross_t = 0.0
	if team == 0 and index == 0:
		game.stat("frames")
	var desired := Vector2.ZERO
	var want_turbo := false
	if rim_kind != "":
		desired = update_rim_move(delta)
	elif block_jump_t >= 0.0:
		desired = update_block_jump(delta)
	elif shooting:
		shot_elapsed += delta
		if has_ball() and is_closely_contested():
			shot_contest_t += delta
		if not has_ball():
			shooting = false
		elif is_human:
			shot_charge += delta / 0.9
			if shot_charge >= 1.2:
				release_shot()
		elif not cpu_faking:          # a CPU pump fake ends in update_pump_fake, not with a shot
			cpu_shot_time -= delta
			if cpu_shot_time <= 0.0:
				release_shot()
	elif ft_frozen():
		desired = ft_stand(delta, is_human)   # free throws: walk to the spot and stand (the shooter shoots from it)
	elif is_human:
		desired = input_vec.limit_length(1.0) * speed * (0.94 if has_ball() else 1.0)
		var ball = game.ball
		if desired.length() < 1.0 and ball.state == ball.PASS and ball.receiver == self:
			desired = seek(alley_spot() if ball.lob else ball.position, 1.0)
		want_turbo = human_turbo_input() and desired.length() > 1.0
		if fake_t > 0.0:
			desired *= PUMP_MOVE_MULT     # pump fake: ball up, only a slow shuffle
			want_turbo = false
		desired = defense_assist(delta, input_vec, desired, want_turbo)
	else:
		ai(delta)
		desired = seek(target, speed_mult)
		want_turbo = cpu_turbo_want and desired.length() > 1.0
	var accel := 1600.0
	if cross_t > 0.0:
		desired = cross_dir * speed * CROSS_SPEED_MULT   # the burst: a sharp cut the new way
		accel = CROSS_ACCEL
	if poke_t > 0.0 and rim_kind == "" and block_jump_t < 0.0:
		desired = Vector2.ZERO        # reaching for the ball: stands still, hit or miss
		want_turbo = false
		game.stat("poke_freeze_frames_t%d" % team)
	elif stumble_t > 0.0:
		desired *= STUMBLE_SPEED_MULT
		want_turbo = false
	elif has_ball() and not is_airborne() and cross_t <= 0.0 and is_guarded(desired):
		desired *= GUARD_SLOW
		game.stat("guard_slow_frames_t%d" % team)
	if update_turbo(delta, want_turbo, is_human):
		desired *= Twists.value("turbo_mult", TURBO_SPEED_MULT) * (TURBO_BALL_MULT if has_ball() else 1.0)
	desired *= Difficulty.value(team, "speed_mult", 1.0)   # Q6 b knob (1.0 on every level until answered)
	update_dribble_hand(delta)
	accel *= wet_grip(delta, desired)
	velocity = velocity.move_toward(desired, accel * delta)
	position += velocity * delta
	position = game.clamp_to_court(position)
	var lift := jump_z / DUNK_JUMP_PX
	sprite.position = Vector2(0, -jump_z)
	sprite.scale = Vector2(1.75, 1.75) * (1.0 + 0.15 * lift)
	# face where we are going, or the ball when standing still
	var look := velocity
	if look.length() < 15.0 or poke_t > 0.0:
		look = game.ball.position - position
	if look.length() > 1.0:
		facing = lerp_angle(facing, look.angle(), min(1.0, 10.0 * delta))
	sprite.rotation = facing
	if on_fire:
		fire_anim += delta
	queue_redraw()

# ---------------- defensive assist (P2.5-02) ----------------

# The human's desired velocity on defense, blended toward the spot between the ball handler and the basket when the
# stick points roughly that way. Returns `desired` unchanged when the assist doesn't apply.
func defense_assist(delta: float, stick: Vector2, desired: Vector2, sprinting: bool) -> Vector2:
	assist_off_t = maxf(0.0, assist_off_t - delta)
	assist_on = false
	var ball = game.ball
	var h = ball.holder
	if ball.state != ball.HELD or h == null or h.team == team or has_ball():
		return desired
	if assist_off_t > 0.0 or stumble_t > 0.0 or poke_t > 0.0 or is_airborne():
		return desired   # just pressed STEAL/BLOCK, beaten by a crossover, reaching or in the air: you're on your own
	if not guarding_handler(h):
		return desired   # helping on someone else (a cutter, your own man): no pull toward the ball
	var FT: float = game.FT
	var to_h: Vector2 = h.position - position
	var d_ft: float = to_h.length() / FT
	if d_ft > ASSIST_RANGE_FT or stick.length() < ASSIST_MIN_STICK:
		return desired
	var spot: Vector2 = assist_spot(h)
	var to_spot: Vector2 = spot - position
	if not assist_aim_ok(stick, h, sprinting):
		game.stat("human_assist_pulled_away")   # in range but steering elsewhere: no assist
		return desired
	var k: float = ASSIST_STRENGTH * clampf((ASSIST_RANGE_FT - d_ft) / (ASSIST_RANGE_FT - ASSIST_FULL_FT), 0.0, 1.0)
	var top: float = desired.length()
	var help: Vector2 = (to_spot * ASSIST_GAIN + h.velocity).limit_length(top)
	assist_on = true
	game.stat("human_assist_frames")
	return desired.lerp(help, k)

# true when this player is the one guarding the handler: the handler is his man, or he's his team's closest defender
func guarding_handler(h) -> bool:
	if game.teams[1 - team][index] == h:
		return true
	var mine: float = position.distance_squared_to(h.position)
	for mate in game.teams[team]:
		if mate != self and mate.position.distance_squared_to(h.position) < mine:
			return false
	return true

# where the assist slides the defender: a few feet in front of the handler on his line to the basket, led by his move
func assist_spot(h) -> Vector2:
	var line: Vector2 = game.attack_hoop(h.team) - h.position
	var gap: float = minf(ASSIST_GAP_FT * game.FT, line.length() * 0.5)
	return h.position + h.velocity * ASSIST_LEAD + (line.normalized() * gap if line.length() > 1.0 else Vector2.ZERO)

# the stick points roughly at the handler or at the assist spot (a tighter aim while sprinting)
func assist_aim_ok(stick: Vector2, h, sprinting: bool) -> bool:
	if stick.length() < ASSIST_MIN_STICK:
		return false
	var cone: float = deg_to_rad(ASSIST_TURBO_ANGLE if sprinting else ASSIST_ANGLE)
	var sdir: Vector2 = stick.normalized()
	var to_h: Vector2 = h.position - position
	var to_spot: Vector2 = assist_spot(h) - position
	var aim_h: float = absf(sdir.angle_to(to_h)) if to_h.length() > 1.0 else 0.0
	var aim_s: float = absf(sdir.angle_to(to_spot)) if to_spot.length() > 4.0 else 0.0
	return minf(aim_h, aim_s) <= cone

# ---------------- shared moves: stumble, block jump, close guarding ----------------

func rating(key: String) -> int:
	return int(ratings.get(key, 50))

# -1..+1 for ratings 0..100
func rating_frac(key: String) -> float:
	return clampf((float(rating(key)) - 50.0) / 50.0, -1.0, 1.0)

# Success chance of a block jump: timing decides good vs bad, the block rating scales a good one.
func block_chance(good_timing: bool) -> float:
	if not good_timing:
		return BLOCK_BAD_CHANCE
	var bonus: float = BLOCK_HUMAN_GOOD_BONUS if game.is_human(self) else 0.0
	return clampf(BLOCK_GOOD_BASE + bonus + BLOCK_RATING_SPAN * rating_frac("block"), 0.0, 1.0)

# Knocked off balance for `time` seconds (slow, no turbo, can't steal or jump).
func stumble(time: float) -> void:
	if time <= 0.0:
		return
	stumble_t = maxf(stumble_t, time)
	game.stat("stumbles")

# A defender jumps to block. False if already airborne, off balance or holding the ball.
func start_block_jump() -> bool:
	if is_airborne() or stumble_t > 0.0 or has_ball() or ft_frozen():   # (no block jumps during free throws)
		return false
	block_jump_t = 0.0
	block_jump_vel = velocity * BLOCK_JUMP_MOMENTUM
	game.stat("block_jumps_t%d" % team)
	return true

func is_airborne() -> bool:
	return rim_kind != "" or block_jump_t >= 0.0

# 0 on the floor, 1 at the top of a block jump
func block_height_frac() -> float:
	if block_jump_t < 0.0:
		return 0.0
	return sin(PI * clampf(block_jump_t / BLOCK_JUMP_TIME, 0.0, 1.0))

# Runs every frame during a block jump; returns the desired velocity (momentum only, no steering).
func update_block_jump(delta: float) -> Vector2:
	block_jump_t += delta
	if block_jump_t >= BLOCK_JUMP_TIME:
		block_jump_t = -1.0
		jump_z = 0.0
		return Vector2.ZERO
	jump_z = BLOCK_JUMP_PX * block_height_frac()
	return block_jump_vel

# A defender within GUARD_FT, inside GUARD_CONE of the way I'm heading.
func is_guarded(move: Vector2) -> bool:
	if move.length() < 1.0:
		return false
	var dir := move.normalized()
	var reach: float = GUARD_FT * game.FT
	var cos_cone := cos(deg_to_rad(GUARD_CONE))
	for o in game.teams[1 - team]:
		if o.stumble_t > 0.0:
			continue   # a stumbling defender doesn't slow the driver
		var r: Vector2 = o.position - position
		var d := r.length()
		if d < reach and d > 0.1 and dir.dot(r / d) >= cos_cone:
			return true
	return false

# ---------------- crossover and the dribble hand (P2-05) ----------------

# A quick cut toward `dir` with the ball switching hands in front of the body. Called by human_input.gd on a flick
# and by the CPU handler. Owner (Q1): crossover only, so every kind (including "spin") is a crossover.
func start_crossover(dir: Vector2, kind: String) -> void:
	if not has_ball() or shooting or is_airborne() or stumble_t > 0.0 or ft_frozen():
		return
	if cross_cd > 0.0 or cross_t > 0.0:
		if game.is_human(self):
			game.stat("human_cross_cooldown")   # a flick that came too soon after the last crossover
		return
	if dir.length() < 0.01:
		dir = Vector2.from_angle(facing + PI / 2.0 * dribble_side)
	if kind != "cross":
		game.stat("cross_from_" + kind)   # the detector called it a spin: played as a crossover (Q1)
	if fake_t > 0.0:
		end_pump_fake()   # out of a pump fake into a crossover
	move_kind = "cross"
	cross_dir = dir.normalized()
	cross_t = CROSS_TIME
	cross_cd = CROSS_COOLDOWN
	dribble_side = -dribble_side
	hand_switch_t = 0.0
	game.stat("crossovers_t%d" % team)
	if game.is_human(self):
		game.stat("human_crossovers")
	else:
		game.stat("cpu_crossovers")
	cross_beat_check()

# The defender close in front can be beaten: he stumbles if he was moving the wrong way, or (CPU) if he is still
# inside his reaction time. Until defense.gd decides that (P2-08 hook `def.beaten_by_cross(handler, dir)`), a flat
# CROSS_BEAT_CHANCE. Only the closest defender in front can be beaten.
func cross_beat_check() -> void:
	var look := Vector2.from_angle(facing)
	var cos_cone := cos(deg_to_rad(CROSS_BEAT_CONE))
	var best = null
	var best_d: float = CROSS_BEAT_FT * game.FT
	for o in game.teams[1 - team]:
		var r: Vector2 = o.position - position
		var d := r.length()
		if d < best_d and d > 0.1 and look.dot(r / d) >= cos_cone and o.stumble_t <= 0.0 and not o.is_airborne():
			best_d = d
			best = o
	if best == null:
		return
	if game.is_human(best):
		game.stat("human_cross_faced")   # a crossover at the human defender (human_cross_beaten: how many beat him)
	var beaten := false
	var ov: Vector2 = best.velocity
	if ov.length() >= CROSS_WRONG_WAY_SPEED and ov.normalized().dot(cross_dir) < -0.3:
		beaten = true   # leaning the wrong way: the cut goes behind him
		if game.is_human(best) and not game.is_human(self):
			# owner (Phase 3 check-in): on Easy/Normal a CPU crossover beats the human less often (always on Hard)
			beaten = game.rng.randf() < Difficulty.value(team, "cross_beat_human", 1.0)
	elif not game.is_human(best):
		if best.def != null and best.def.has_method("beaten_by_cross"):
			beaten = best.def.beaten_by_cross(self, cross_dir)
		else:
			beaten = game.rng.randf() < CROSS_BEAT_CHANCE
	if not beaten:
		return
	best.stumble(CROSS_STUN)
	best.view_crossed(self, best_d / game.FT)   # drawing only: a close one is an ankle-breaker (he falls)
	game.stat("cross_beats_t%d" % team)
	if game.is_human(best):
		game.stat("human_cross_beaten")
		if best.assist_on:
			game.stat("human_cross_beaten_assisted")   # the assist was steering him when the crossover came
	if game.is_human(self):
		game.stat("human_cross_beats")
	if game.fx:
		game.fx.popup("SHOOK!", best.position + Vector2(0, -40), BEAT_POPUP_COLOR, 30)

# Moves the drawn dribble hand (hand_x) toward dribble_side; the ball is centered while shooting or in the air.
# Out of a move, the handler slowly switches hands away from the nearest defender.
func update_dribble_hand(delta: float) -> void:
	if not has_ball():
		hand_switch_t = 0.0
		return
	var goal := dribble_side
	if shooting or is_airborne() or fake_t > 0.0:
		goal = 0.0
	elif cross_t <= 0.0:
		var o = game.nearest_opponent(self)
		var right := Vector2.from_angle(facing + PI / 2.0)
		if o != null and o.position.distance_to(position) < HAND_SWITCH_FT * game.FT \
				and right.dot(o.position - position) * dribble_side > 0.0:
			hand_switch_t += delta
			if hand_switch_t >= HAND_SWITCH_DELAY:
				hand_switch_t = 0.0
				dribble_side = -dribble_side
				game.stat("hand_switches")
		else:
			hand_switch_t = 0.0
	var rate := CROSS_HAND_RATE if cross_t > 0.0 else HAND_SWITCH_RATE
	hand_x = move_toward(hand_x, goal, rate * delta)

# ---------------- pump fake (P2-06) ----------------

# The human's A release ended the meter this quickly: a pump fake. Uses human_input's short-tap flag when it is
# there, and always checks the meter time itself (the meter's auto-release at full charge is never a tap).
func is_pump_tap() -> bool:
	if shot_charge * 0.9 > PUMP_TAP_MAX + 0.02:
		return false
	var inp = game.input
	if inp != null and "last_a_short" in inp:
		return inp.last_a_short
	return true

# Human: the shot meter was started and A released at once. Keeps the ball; A again shoots right away.
func start_pump_fake() -> void:
	shooting = false
	shot_charge = 0.0
	_begin_fake()
	if game.is_human(self):
		game.stat("human_pump_fakes")

# CPU: a fake looks like a real shot start (`shooting` is true for the fake's time) so defenders that react to
# shots can bite. It ends in update_pump_fake().
func start_cpu_pump_fake() -> void:
	if not has_ball() or shooting or rim_kind != "":
		return
	shooting = true
	cpu_faking = true
	_begin_fake()
	game.stat("cpu_pump_fakes")

func _begin_fake() -> void:
	fake_t = PUMP_TIME
	since_fake = 0.0
	fake_bit = false
	game.stat("pump_fakes_t%d" % team)
	# hook for defense.gd (P2-07/P2-08): a CPU defender may jump at the fake
	for o in game.teams[1 - team]:
		if o.def != null and o.def.has_method("on_pump_fake"):
			o.def.on_pump_fake(self)

func end_pump_fake() -> void:
	fake_t = 0.0
	if not is_airborne():
		jump_z = 0.0
	if cpu_faking:
		cpu_faking = false
		shooting = false

# Runs every frame: the fake's hop, its end, and whether a defender bit (started a block jump right after it).
func update_pump_fake(delta: float) -> void:
	since_fake += delta
	if cpu_faking and not shooting:
		end_pump_fake()       # main.gd reset the play (new possession, period end)
	if fake_t > 0.0:
		if not has_ball() or is_airborne():
			end_pump_fake()   # stripped, or the ball is gone
		else:
			fake_t = maxf(0.0, fake_t - delta)
			jump_z = PUMP_HOP_PX * sin(PI * (1.0 - fake_t / PUMP_TIME))
			if fake_t <= 0.0:
				var was_cpu := cpu_faking
				end_pump_fake()
				if was_cpu and fake_bit:
					cpu_punish_bite()
	if not fake_bit and since_fake <= PUMP_BITE_WINDOW:
		for o in game.teams[1 - team]:
			if o.block_jump_t >= 0.0 and o.block_jump_t <= since_fake + 0.001:
				fake_bit = true
				game.stat("pump_bites_t%d" % team)
				if game.is_human(self):
					game.stat("human_pump_bites")
				if fake_t <= 0.0 and not game.is_human(self):
					cpu_punish_bite()
				break

# CPU after a defender bit: step in for the shot, or drive past him on turbo.
func cpu_punish_bite() -> void:
	if not has_ball() or shooting or rim_kind != "" or cpu_call_hold():
		return
	var d_ft: float = position.distance_to(game.attack_hoop(team)) / game.FT
	if d_ft <= CPU_BITE_SHOOT_FT and game.rng.randf() < CPU_BITE_SHOOT_CHANCE:
		game.stat("pump_bite_shots")
		start_shot()
	else:
		game.stat("pump_bite_drives")
		cpu_drive_t = CPU_BITE_DRIVE

# Counts a make shortly after this player's pump fake (call right after game.release_shot).
func count_pump_and_score() -> void:
	if since_fake > PUMP_SCORE_WINDOW:
		return
	var ball = game.ball
	game.stat("pump_then_shots")
	if ball.state == ball.SHOT and ball.shot_made and ball.shooter == self:
		game.stat("pump_and_score")

# ---------------- turbo ----------------

func human_turbo_input() -> bool:
	if humantest:
		return true  # developer testing: the scripted thumb is always pushed to the edge
	if Input.is_key_pressed(KEY_SHIFT):
		return true  # desktop testing only
	return game.controls.turbo_pull()   # thumb pulled past the joystick ring (touch_controls.TURBO_PULL)

# Drains or refills stamina and returns true if this player sprints this frame.
func update_turbo(delta: float, want: bool, is_human: bool) -> bool:
	if not is_human:
		# the CPU keeps a reserve: it never sprints itself below TURBO_MIN_RESTART
		if stamina <= TURBO_MIN_RESTART:
			cpu_tired = true
		elif stamina >= CPU_TURBO_RESUME:
			cpu_tired = false
		if cpu_tired:
			want = false
	if turbo_locked and stamina >= TURBO_MIN_RESTART:
		turbo_locked = false
	turbo = want and not turbo_locked and not shooting and not is_airborne()
	if turbo:
		since_turbo = 0.0
		if on_fire:
			game.stat("fire_turbo_frames")   # on fire: stamina doesn't drain
		else:
			stamina = maxf(0.0, stamina - Ratings.stamina_drain(Difficulty.value(team, "stamina_drain", STAMINA_DRAIN),
					rating("stamina")) * Twists.value("stamina_drain_mult", 1.0) * delta)   # thin air 1.2
		refill_wait = REFILL_DELAY
		game.stat("turbo_frames_t%d" % team)
		if stamina <= 0.0:
			turbo_locked = true
			game.stat("stamina_empty")
	else:
		since_turbo += delta
		refill_wait -= delta
		if refill_wait <= 0.0:
			var refill_mult: float = Twists.value("stamina_refill_mult", 1.0)   # humid 0.7
			stamina = minf(1.0, stamina + Ratings.stamina_refill(STAMINA_REFILL, rating("stamina")) * refill_mult * delta)
			if refill_mult != 1.0 and stamina < 1.0:
				game.stat("twist_refill_frames")
	return turbo

# Wet court: the acceleration multiplier this frame (1.0 = full grip). A slide starts on a turn of cut_angle_deg or more
# at cut_min_speed of top speed or faster, and lasts until he moves the new way, slows down, or SLIDE_MAX_TIME. A
# crossover burst keeps its grip (and ends a slide); in the air, reaching or at the free-throw line nothing slides.
func wet_grip(delta: float, desired: Vector2) -> float:
	var grip: float = Twists.value("cut_grip", 1.0)
	if grip >= 1.0 or cross_t > 0.0 or is_airborne() or poke_t > 0.0 or ft_frozen():
		sliding = false
		return 1.0
	var v: float = velocity.length()
	var turn_deg: float = 0.0
	if v > 1.0 and desired.length() >= SLIDE_MIN_WANT * speed:
		turn_deg = rad_to_deg(absf(velocity.angle_to(desired)))
	if sliding:
		_slide_t += delta
		game.stat("slide_frames")
		if turn_deg < SLIDE_END_DEG or v < SLIDE_END_SPEED * speed or _slide_t >= SLIDE_MAX_TIME:
			sliding = false
	elif turn_deg >= Twists.value("cut_angle_deg", 60.0) and v >= Twists.value("cut_min_speed", 0.8) * speed:
		sliding = true
		_slide_t = 0.0
		game.stat("slides")
		game.stat("slides_t%d" % team)
		if game.is_human(self):
			game.stat("human_slides")
	return grip if sliding else 1.0

# opponents closer to this hoop than me (0 or 1 means a fast break)
func opponents_ahead(hoop: Vector2) -> int:
	var n := 0
	var my_d := position.distance_to(hoop)
	for o in game.teams[1 - team]:
		if o.position.distance_to(hoop) < my_d:
			n += 1
	return n

func seek(t: Vector2, mult: float) -> Vector2:
	var to := t - position
	var d := to.length()
	if d < 5.0:
		return Vector2.ZERO
	return to / d * speed * mult * min(1.0, d / 35.0)

# ---------------- shooting ----------------

func start_shot() -> void:
	if has_ball() and not shooting and rim_kind == "":
		cpu_three_try = false
		hook_shot = false
		if fake_t > 0.0:
			end_pump_fake()   # out of a pump fake straight into the real shot
			game.stat("pump_then_shoot_t%d" % team)
		var d_ft: float = position.distance_to(game.attack_hoop(team)) / game.FT
		if d_ft <= LAYUP_RANGE and not at_free_throw():
			start_rim_move(d_ft)
			return
		shooting = true
		shot_charge = 0.0
		hook_shot = signature == SIG_HOOK and d_ft <= HOOK_MAX_FT and not at_free_throw()   # P9-20
		cpu_shot_time = game.rng.randf_range(CPU_WINDUP_MIN, CPU_WINDUP_MAX)
		if _cpu_catch_t <= CPU_CATCH_SHOT_T and not game.is_human(self) and not at_free_throw():
			cpu_shot_time = game.rng.randf_range(CPU_CATCH_WINDUP_MIN, CPU_CATCH_WINDUP_MAX)   # catch and shoot
		shot_elapsed = 0.0
		# a CPU closeout must arrive in the first half of the windup to count fully; a human meter uses CLOSEOUT_GRACE
		shot_grace = CLOSEOUT_GRACE if game.is_human(self) else minf(CLOSEOUT_GRACE, 0.5 * cpu_shot_time)
		shot_contest_t = shot_grace if is_closely_contested() else 0.0   # already on me: never a late closeout

func release_shot() -> void:
	if not shooting or rim_kind != "":
		return  # dunks and layups release on their own
	if game.is_human(self) and is_pump_tap():
		if at_free_throw():
			shooting = false      # no pump fake at the line: a short tap is ignored (hold and release to shoot)
			shot_charge = 0.0
			game.stat("human_ft_taps_ignored")
			return
		if since_fake < PUMP_COOLDOWN:
			shooting = false      # another fake too soon after the last one: the tap does nothing
			shot_charge = 0.0
			game.stat("pump_cooldown_taps")
			return
		start_pump_fake()     # a short tap of SHOOT: pump fake instead of a near-useless 0.6 shot (owner Q2)
		return
	shooting = false
	if at_free_throw():
		release_free_throw()
		return
	var quality := 1.0
	if game.is_human(self):
		var c := shot_charge
		if c >= green_lo() and c <= green_hi():
			quality = 1.3
			game.show_message("PERFECT RELEASE", 0.8)
		elif c >= 0.6 and c <= 1.05:
			quality = 1.0
		else:
			quality = 0.6
	else:
		quality = game.rng.randf_range(Difficulty.value(team, "shot_quality_min", CPU_SHOT_QUALITY_MIN),
				Difficulty.value(team, "shot_quality_max", CPU_SHOT_QUALITY_MAX))
		if on_fire:
			quality *= FIRE_SHOT_BONUS
	# a closeout that only arrived during the shot (or a defender who is beaten, trailing or still up from a bite)
	# is a lighter contest
	if game.openness(self) < CLOSEOUT_FT and (shot_contest_t < shot_grace or not is_closely_contested()):
		quality *= CLOSEOUT_SOFT_MULT
		game.stat("late_closeouts_t%d" % team)
	# shaky jumper right after sprinting (not at the rim)
	var hoop: Vector2 = game.attack_hoop(team)
	if since_turbo <= TURBO_SHOT_WINDOW and position.distance_to(hoop) > TURBO_SHOT_EXEMPT_FT * game.FT:
		quality *= TURBO_SHOT_PENALTY
		game.stat("turbo_jumpers")
	# jump-shot counters: attempts per team, 5 ft distance bands, threes, and makes
	var counted := has_ball()
	var three: bool = game.is_three(position, hoop)
	if counted and signature == SIG_DEEP_SET and three:
		var dm: float = deep_set_mult()
		if dm > 1.0:
			quality *= dm   # P9-20 deep set: the long falloff starts DEEP_SET_EXTRA_FT further out
			sig_log(SIG_DEEP_SET, "set shot from %.1f ft (odds x%.2f)" % [position.distance_to(hoop) / game.FT, dm])
	if counted and hook_shot:
		sig_log(SIG_HOOK, "hook shot from %.1f ft" % (position.distance_to(hoop) / game.FT))
	if cpu_three_try and counted and not three:
		game.stat("cpu_threes_inside")   # a CPU 2 that drifted inside the arc during the windup (worth 1)
	var two_src := ""
	if cpu_three_try and counted and three:
		two_src = "catch" if _cpu_catch_t <= CPU_CATCH_SHOT_T else "dribble"
		game.stat("cpu_twos_" + two_src)   # CPU 2s: catch and shoot vs off the dribble (and makes, below)
	cpu_three_try = false
	if counted:
		game.stat("jumpers_t%d" % team)
		game.stat("jumper_d%d" % int(position.distance_to(hoop) / game.FT / 5.0))
		if three:
			game.stat("jumper_threes_t%d" % team)
	game.release_shot(self, quality)
	var ball = game.ball
	count_pump_and_score()
	if counted and ball.state == ball.SHOT and ball.shot_made:
		game.stat("jumper_makes_t%d" % team)
		if three:
			game.stat("jumper_three_makes_t%d" % team)
		if two_src != "":
			game.stat("cpu_twos_%s_makes" % two_src)

# A free throw leaves the hand: the human's meter (perfect 1.3, normal 1.0, bad 0.6) or the CPU's
# CPU_FT_QUALITY range; no contest or sprint penalties. main.release_shot scores it with rules' FT odds (P3-05).
func release_free_throw() -> void:
	var quality := 1.0
	if game.is_human(self):
		var c := shot_charge
		if c >= green_lo() and c <= green_hi():
			quality = 1.3
			game.show_message("PERFECT RELEASE", 0.8)
		elif c >= 0.6 and c <= 1.05:
			quality = 1.0
		else:
			quality = 0.6
	else:
		var q: float = game.rng.randf_range(CPU_FT_QUALITY_MIN, CPU_FT_QUALITY_MAX)
		quality = Difficulty.value(team, "ft_quality", q)
	# the last free throw of the trip (ft_left still counts the one in my hands): its flight releases everyone
	var last: bool = not ("ft_left" in game.rules) or int(game.rules.ft_left) <= 1
	game.release_shot(self, quality)
	var ball = game.ball
	if ball.state == ball.SHOT and ball.shooter == self:
		game.stat("ft_releases_t%d" % team)
		if last:
			ft_box_serial = game.shot_serial

# the nearest defender is right on me (main.shot_probability's full contest), on balance, not trailing behind me,
# and not still in the air from biting on an earlier fake
func is_closely_contested() -> bool:
	return contests_me(game.nearest_opponent(self), CLOSEOUT_FT, shot_elapsed)

# defender `o` is within `reach_ft` and in the play: on balance, not trailing behind me, and not still in the air
# from a jump that started more than `since` seconds ago (he bit on a fake or jumped early)
func contests_me(o, reach_ft: float, since: float) -> bool:
	if o == null or o.stumble_t > 0.0:
		return false
	var r: Vector2 = o.position - position
	if r.length() >= reach_ft * game.FT:
		return false
	if o.block_jump_t > since:
		return false
	var to_hoop: Vector2 = (game.attack_hoop(team) - position).normalized()
	return r.length() < 0.1 or r.normalized().dot(to_hoop) > CLOSEOUT_TRAIL_DOT

# ---------------- signature moves (P9-20) ----------------
# Each rule runs only for a player whose "signature" is that move; with signature "" every helper returns today's
# value (x1.0, DUNK_RANGE), so a game without legends plays exactly as before.

# a move fired: counts sig_<id>_t<team> (in the stats printout) and, in test runs, prints a SIGNATURE line
func sig_log(id: String, what: String) -> void:
	game.stat("sig_%s_t%d" % [id, team])
	if _sig_print:
		print("SIGNATURE %s %s (team %d, %d-%d): %s" % [id, pname if pname != "" else pid, team,
				int(game.score[0]), int(game.score[1]), what])

# how far out he can take off for a dunk
func dunk_range() -> float:
	return DUNK_RANGE + (LONG_DUNK_EXTRA_FT if signature == SIG_LONG_DUNK else 0.0)

# defense.gd: x this on a block try at my shot of `kind` ("" jumper, "layup", "dunk"); 1.0 for everyone but the hook man
func sig_block_mult(kind: String) -> float:
	if signature != SIG_HOOK:
		return 1.0
	if kind == "layup" or (kind == "" and hook_shot):
		return HOOK_BLOCK_MULT
	return 1.0

# deep set: main.shot_probability's long base with the falloff moved DEEP_SET_EXTRA_FT out, over today's (>= 1.0)
func deep_set_mult() -> float:
	var d: float = position.distance_to(game.attack_hoop(team)) / game.FT
	var tw: float = Twists.value("long_shot_mult", 1.0)
	var now: float = maxf((game.SHOT_LONG_BASE - maxf(0.0, d - DEEP_SET_ARC_FT) * game.SHOT_LONG_FALLOFF) * tw, game.SHOT_MIN)
	var want: float = maxf((game.SHOT_LONG_BASE - maxf(0.0, d - DEEP_SET_ARC_FT - DEEP_SET_EXTRA_FT) * game.SHOT_LONG_FALLOFF) * tw,
			game.SHOT_MIN)
	return maxf(1.0, want / now)

# finger roll: undoes all but FINGER_ROLL_KEEP of main.shot_probability's rim contest (1.0 when nobody contests)
func finger_roll_mult() -> float:
	var cont: float = game.openness(self)
	var pen: float = 1.0
	if cont < game.CONTEST_TIGHT_FT:
		pen = game.RIM_CONTEST_TIGHT_MULT
	elif cont < game.CONTEST_NEAR_FT:
		pen = game.RIM_CONTEST_NEAR_MULT
	if pen >= 1.0:
		return 1.0
	return lerpf(1.0 / pen, 1.0, FINGER_ROLL_KEEP)

# CPU outlet passer with the ball in his backcourt: the long pass to a teammate who is open near the hoop with at most
# OUTLET_AHEAD opponents between him and it (no dice: he sees it, he throws it)
func try_cpu_outlet(hoop: Vector2) -> bool:
	var best = null
	var best_open: float = OUTLET_OPEN_FT
	for mate in game.teams[team]:
		if mate == self or not game.in_frontcourt(mate.position, team) or mate.is_airborne():
			continue
		if mate.position.distance_to(position) < OUTLET_MIN_FT * game.FT:
			continue
		if mate.position.distance_to(hoop) > OUTLET_HOOP_FT * game.FT or mate.opponents_ahead(hoop) > OUTLET_AHEAD:
			continue
		var o: float = game.openness(mate)
		if o >= best_open:
			best_open = o
			best = mate
	if best == null:
		return false
	game.stat("cpu_outlets_t%d" % team)
	game.do_pass(self, best)   # ball.gd sees the length and flies it as an outlet (and logs it)
	return true

func green_lo() -> float:
	return FIRE_GREEN_LO if on_fire else GREEN_LO

func green_hi() -> float:
	return FIRE_GREEN_HI if on_fire else GREEN_HI

# ---------------- dunks and layups ----------------

func is_dunk_speed() -> bool:
	return turbo or since_turbo < 0.2 or velocity.length() >= Ratings.dunk_speed_frac(DUNK_SPEED_FRAC, rating("finishing")) * speed

# Shoot near the rim: take off for a dunk (very close and fast) or a layup. No shot meter.
func start_rim_move(d_ft: float) -> void:
	var dunk := d_ft <= dunk_range() and is_dunk_speed()
	long_dunk = dunk and d_ft > DUNK_RANGE   # P9-20: only a long_dunk signature reaches past DUNK_RANGE
	if long_dunk:
		sig_log(SIG_LONG_DUNK, "power dunk from %.1f ft" % d_ft)
	alley_oop = false
	rim_kind = "dunk" if dunk else "layup"
	jump_time = DUNK_TIME if dunk else LAYUP_TIME
	jump_t = 0.0
	jump_z = 0.0
	jump_released = false
	shooting = true
	game.stat(rim_kind + "s")
	game.stat("%ss_t%d" % [rim_kind, team])
	if game.is_human(self):
		game.stat("human_" + rim_kind + "s")
	rim_contest()

# make-odds contest at take-off (the block is asked at release, see release_rim_shot)
func rim_contest() -> void:
	rim_quality = 1.0
	var d = game.nearest_opponent(self)
	if contests_me(d, CONTEST_FT, 0.0):
		var c_ft: float = d.position.distance_to(position) / game.FT
		if c_ft < CONTEST_FT:
			var close := clampf(1.5 * (1.0 - c_ft / CONTEST_FT), 0.0, 1.0)
			rim_quality *= lerpf(1.0, CONTEST_MAKE_MULT, close)
			game.stat("rim_contested")

# Runs every frame while in the air; returns the desired velocity (a glide toward the rim).
func update_rim_move(delta: float) -> Vector2:
	jump_t += delta
	var f := clampf(jump_t / jump_time, 0.0, 1.0)
	var peak := DUNK_JUMP_PX if rim_kind == "dunk" else LAYUP_JUMP_PX
	if alley_oop:
		peak = ALLEY_JUMP_PX
	jump_z = peak * sin(PI * f)
	var release_at := DUNK_RELEASE if rim_kind == "dunk" else LAYUP_RELEASE
	if not jump_released and f >= release_at:
		jump_released = true
		shooting = false
		if has_ball():
			release_rim_shot()
	elif not jump_released and not has_ball() and not lob_coming():
		jump_released = true  # stripped or the period ended (or the lob never came): just land
		shooting = false
	if f >= 1.0:
		rim_kind = ""
		alley_oop = false
		jump_z = 0.0
		shooting = false
		return Vector2.ZERO
	var hoop: Vector2 = game.attack_hoop(team)
	var under: Vector2 = hoop + Vector2(game.inward(hoop) * 1.5 * game.FT, 0)
	return seek(under, LONG_DUNK_GLIDE if long_dunk else RIM_GLIDE)

func release_rim_shot() -> void:
	var ball = game.ball
	ball.next_shot_kind = rim_kind
	ball.next_alley = alley_oop
	var blocker = Defense.rim_blocker(game, self, rim_kind)
	if blocker != null:
		# blocked at the rim: swatted out of the hands (counts as a missed shot, never as a make)
		ball.next_shot_kind = ""
		ball.next_alley = false
		if alley_oop:
			game.stat("alleyoop_blocks")
		game.rim_shot_blocked(self, blocker)
		game.stat("rim_blocks")
		Defense.keep_block(game, blocker)   # P9-20: a keep_block blocker's swat stays in play
		return
	# aim the open make chance at DUNK_OPEN_PCT / LAYUP_OPEN_PCT; shot_probability() then applies its own
	# rim contest (x RIM_CONTEST_TIGHT_MULT with a defender on you)
	var d_ft: float = position.distance_to(game.attack_hoop(team)) / game.FT
	var base: float = game.SHOT_CLOSE_BASE if d_ft < game.SHOT_CLOSE_FT \
			else maxf(game.SHOT_MIN, game.SHOT_MID_BASE - (d_ft - game.SHOT_CLOSE_FT) * game.SHOT_MID_FALLOFF)  # mirrors main.shot_probability
	var target: float = (DUNK_OPEN_PCT if rim_kind == "dunk" else LAYUP_OPEN_PCT) * Ratings.finish_mult(rating("finishing"))
	var fire_mult := FIRE_SHOT_BONUS if on_fire else 1.0
	var alley_mult := ALLEY_MAKE_MULT if alley_oop else 1.0
	var soft := 1.0
	if game.openness(self) < CLOSEOUT_FT and not contests_me(game.nearest_opponent(self), CLOSEOUT_FT, jump_t):
		soft = RIM_SOFT_MULT   # the man on me is beaten (stumbling), trailing, or came down from an early jump
		game.stat("rim_soft_contests_t%d" % team)
	if signature == SIG_FINGER_ROLL and rim_kind == "layup":
		var fr: float = finger_roll_mult()
		if fr > 1.0:
			soft = maxf(soft, fr)   # P9-20 finger roll: slips past the contest (not on top of the soft-contest ease)
			sig_log(SIG_FINGER_ROLL, "finger roll past a contest (odds x%.2f)" % fr)
	game.release_shot(self, target / base * rim_quality * fire_mult * alley_mult * soft)
	count_pump_and_score()
	if ball.state == ball.SHOT:
		ball.blocked_checked = true  # the take-off contest replaces the CPU jump-shot contest
		Defense.call_pending_fouls(game, self)   # a bad block jump into me at the release (P3-06): and-one or FTs
	else:
		Defense.clear_pending_fouls(game, self)

# ---------------- CPU brain ----------------

func ai(delta: float) -> void:
	var ball = game.ball
	speed_mult = 1.0
	cpu_turbo_want = false
	var my_hoop: Vector2 = game.attack_hoop(team)
	if not has_ball():
		_cpu_had_ball = false
		if not (ball.state == ball.PASS and ball.receiver == self):
			kick_catch = false

	# the last free throw is up: box out first, the chasers crash the glass late in its flight
	if ft_box_live() and ball.shooter != self and not (ball.shot_t > BOXOUT_CRASH_T and game.is_chaser(self)):
		target = boxout_spot()
		speed_mult = BOXOUT_SPEED
		if _box_counted != ft_box_serial:
			_box_counted = ft_box_serial
			game.stat("ft_boxouts_t%d" % team)
		return
	# chase loose balls and rebounds (sprint for them)
	if ball.state == ball.LOOSE:
		if game.is_chaser(self):
			target = ball.position
			cpu_turbo_want = position.distance_to(target) > 3.0 * game.FT
			return
	if ball.state == ball.SHOT and ball.shot_t > 0.4 and game.is_chaser(self):
		target = ball.shot_hoop + Vector2(game.inward(ball.shot_hoop) * 6.0 * game.FT, 0)
		cpu_turbo_want = position.distance_to(target) > 6.0 * game.FT
		return
	if ball.state == ball.PASS and ball.receiver == self:
		target = ball.position
		if kick_catch:
			target = position   # kick-out: spot up beyond the arc and wait for it (running at it steps inside)
		if ball.lob:
			target = alley_spot()   # go to the rim for the lob
			cpu_turbo_want = true
		return

	if game.possession == team:
		if has_ball():
			if not _cpu_had_ball:
				_cpu_had_ball = true
				if kick_catch:
					game.stat("cpu_kick_catches_beyond" if game.is_three(position, my_hoop) else "cpu_kick_catches_inside")
				kick_catch = false
				decision_timer = minf(decision_timer, CPU_CATCH_DECIDE)   # just caught it: catch and shoot
				_cpu_catch_t = 0.0
			_cpu_catch_t += delta
			handler_ai(delta, my_hoop)
		else:
			offball_ai(delta, my_hoop)
	else:
		defense_ai(delta)
		lob_defense()

# the sideways offset is mirrored by the attack direction too, so both hoops are mirror images (like
# main.reset_positions and the inbound spot: B1)
func spot_pos(hoop: Vector2, i: int) -> Vector2:
	var s: Vector2 = SPOTS[i]
	var dir: float = game.inward(hoop)
	return hoop + Vector2(dir * s.x * game.FT, dir * s.y * game.FT)

# ---------------- free throws (P3-06) ----------------

# rules.ft_active (P3-05); false while that isn't merged
func ft_on() -> bool:
	return Defense.ft_on(game)

# this player is the one at the line
func at_free_throw() -> bool:
	return ft_on() and game.rules.ft_shooter == self

# the last free throw of the trip is in the air: everyone is released (the CPU boxes out)
func ft_box_live() -> bool:
	var ball = game.ball
	return ft_box_serial >= 0 and ball.state == ball.SHOT and game.shot_serial == ft_box_serial

# standing for a free throw: from the setup until the last one leaves the hand
func ft_frozen() -> bool:
	return ft_on() and not ft_box_live()

# During free throws: walk to my spot and stand. The CPU shooter shoots CPU_FT_WAIT after he has the ball.
func ft_stand(delta: float, is_human: bool) -> Vector2:
	cross_t = 0.0
	cpu_drive_t = 0.0
	alley_cut = false
	lob_jump_wait = -1.0
	lob_read_target = null
	if def != null:
		def._jump_wait = -1.0
		def._poke_wait = -1.0
		def.foul_pending = ""
	var spot: Vector2 = position
	if game.rules.has_method("ft_spot"):
		spot = game.rules.ft_spot(self)
	var desired: Vector2 = seek(spot, FT_WALK_MULT)
	if not is_human and at_free_throw() and has_ball() and not shooting:
		if ft_wait < 0.0:
			ft_wait = game.rng.randf_range(CPU_FT_WAIT_MIN, CPU_FT_WAIT_MAX)
			ft_wait_total = 0.0
		ft_wait_total += delta
		if position.distance_to(spot) <= FT_SPOT_TOL_FT * game.FT:
			ft_wait -= delta
		if ft_wait <= 0.0 or ft_wait_total >= CPU_FT_WAIT_CAP:
			ft_wait = -1.0
			game.stat("cpu_ft_shots")
			start_shot()
			return Vector2.ZERO
	elif not has_ball():
		ft_wait = -1.0
	return desired

# CPU box-out while the last free throw is in the air: get between the nearest opponent and the rim
func boxout_spot() -> Vector2:
	var hoop: Vector2 = game.ball.shot_hoop
	var o = game.nearest_opponent(self)
	if o == null:
		return position
	var line: Vector2 = hoop - o.position
	if line.length() < 1.0:
		return position
	return o.position + line.normalized() * minf(BOXOUT_FT * game.FT, line.length() * 0.5)

func offball_ai(delta: float, hoop: Vector2) -> void:
	spot_timer -= delta
	if alley_cut:
		target = alley_spot()     # cutting to the rim for a lob
		cpu_turbo_want = true
		return
	if spot_timer <= 0.0:
		spot_timer = game.rng.randf_range(2.5, 5.0)
		if try_cpu_cut(hoop):
			return
		# cut to a spot no teammate is using
		var used := []
		for p in game.teams[team]:
			if p != self:
				used.append(p.spot_index)
		var choices := []
		for i in SPOTS.size():
			if not used.has(i) and i != spot_index:
				choices.append(i)
		if choices.size() > 0:
			spot_index = choices[game.rng.randi() % choices.size()]
	target = spot_pos(hoop, spot_index)
	# stay out of the ball handler's way
	var ball = game.ball
	if ball.holder != null and ball.holder != self:
		var away: Vector2 = target - ball.holder.position
		if away.length() < 8.0 * game.FT:
			target = ball.holder.position + away.normalized() * 10.0 * game.FT
	# fill the lane on a fast break
	if ball.state == ball.HELD and opponents_ahead(hoop) <= 1 \
			and position.distance_to(target) > 15.0 * game.FT:
		cpu_turbo_want = true

func handler_ai(delta: float, hoop: Vector2) -> void:
	var FT: float = game.FT
	var to_hoop := hoop - position
	var dist_ft := to_hoop.length() / FT
	speed_mult = 1.0
	var fast_break := opponents_ahead(hoop) <= 1 and dist_ft > CPU_BREAK_FT
	if not game.in_frontcourt(position, team):
		target = spot_pos(hoop, 0)
		if fast_break:
			target = hoop + Vector2(game.inward(hoop) * 3.0 * FT, 0)
			cpu_turbo_want = true
		if signature == SIG_OUTLET and not cpu_call_hold():
			try_cpu_outlet(hoop)   # P9-20: the long pass to a teammate who leaked out
		return
	# drive to the rim, sidestepping a defender who is in the way
	target = hoop + Vector2(game.inward(hoop) * 3.0 * FT, 0)
	var d: Vector2 = to_hoop.normalized()
	var guard = game.nearest_opponent(self)
	var open_ft := 99.0
	var guard_behind := false         # nearest defender is not between me and the hoop
	var step_side := 0.0              # which way the sidestep goes (0 = no sidestep)
	if guard != null:
		var r: Vector2 = guard.position - position
		open_ft = r.length() / FT
		guard_behind = r.dot(d) <= 0.0
		if open_ft < 5.0 and r.dot(d) > 0.0:
			var side := 1.0 if d.cross(r) > 0.0 else -1.0
			if cpu_side_t > 0.0:
				side = cpu_side   # keep going the way the crossover went
			step_side = side
			target = position + (d * 0.4 - d.orthogonal() * side) * 120.0
	# a defender bit on my pump fake: drive past him
	if cpu_drive_t > 0.0:
		target = hoop + Vector2(game.inward(hoop) * 3.0 * FT, 0)
		cpu_turbo_want = true
	# sprint on a fast break, or when the lane to the rim is open
	if fast_break or (open_ft > 6.0 and dist_ft > 8.0 and lane_open(hoop)):
		cpu_turbo_want = true
	# the human called for the ball: no new shot, pass or move until the call is answered or ends
	if cpu_call_hold():
		return
	# attack the rim: once per drive, maybe pull up early for a layup; at full speed close in, dunk
	if dist_ft > LAYUP_RANGE + 2.0:
		cpu_rim_rolled = false
	elif dist_ft <= LAYUP_RANGE and dist_ft > dunk_range() and not cpu_rim_rolled:
		cpu_rim_rolled = true
		var lay_p: float = CPU_LAYUP_CHANCE if open_ft < CPU_LAYUP_GUARD_FT else CPU_LAYUP_OPEN_CHANCE
		if signature == SIG_FINGER_ROLL:
			lay_p = FINGER_ROLL_CPU_LAYUP   # P9-20: the finger roller goes up for it
		if game.rng.randf() < lay_p:
			start_shot()
			return
	if dist_ft <= dunk_range() and is_dunk_speed():
		start_shot()
		return
	decision_timer -= delta
	if decision_timer > 0.0:
		return
	decision_timer = game.rng.randf_range(CPU_DECIDE_MIN, CPU_DECIDE_MAX)
	var p: float = game.shot_probability(self, 1.0)
	var three: bool = game.is_three(position, hoop)
	var three_set: bool = three and game.is_three(position + velocity * CPU_THREE_LEAD, hoop)
	if dist_ft < CPU_FINISH_FT:
		start_shot()
	elif game.shot_clock < CPU_CLOCK_SHOOT and dist_ft < CPU_CLOCK_SHOOT_FT:
		start_shot()
	elif try_cpu_lob():
		pass   # alley-oop lob to a cutter
	elif signature == SIG_HOOK and dist_ft > LAYUP_RANGE and dist_ft <= HOOK_MAX_FT and open_ft < HOOK_CPU_GUARD_FT \
			and game.rng.randf() < HOOK_CPU_CHANCE:
		game.stat("cpu_hooks_t%d" % team)
		start_shot()   # P9-20: the hook over the man on him
	elif step_side != 0.0 and open_ft < CPU_CROSS_FT and dist_ft > LAYUP_RANGE and cross_cd <= 0.0 \
			and not lane_open(hoop) and game.rng.randf() < CPU_CROSS_CHANCE:
		# crossover: cut back the other way, behind a defender sliding with the sidestep
		cpu_side = -step_side
		cpu_side_t = CPU_CROSS_COMMIT
		start_crossover((d * 0.4 - d.orthogonal() * cpu_side).normalized(), "cross")
	elif step_side != 0.0 and open_ft < CPU_PUMP_FT and dist_ft > LAYUP_RANGE + 1.0 and dist_ft <= CPU_PUMP_MAX_FT \
			and since_fake > 2.0 * PUMP_SCORE_WINDOW and game.rng.randf() < CPU_PUMP_CHANCE:
		start_cpu_pump_fake()   # sell the shot to a defender right in front
	elif dist_ft >= CPU_PULLUP_MIN_FT and dist_ft <= CPU_PULLUP_MAX_FT and not three \
			and (open_ft >= CPU_PULLUP_ROOM_FT or guard_behind) and game.rng.randf() < Difficulty.value(team, "pullup_chance", CPU_PULLUP_CHANCE):
		game.stat("pullups_t%d" % team)
		start_shot()
	elif three_set and dist_ft <= CPU_THREE_MAX_FT + (DEEP_SET_EXTRA_FT if signature == SIG_DEEP_SET else 0.0) \
			and open_ft >= CPU_THREE_OPEN_FT \
			and game.rng.randf() < Difficulty.value(team, "three_chance", CPU_THREE_CHANCE) * Twists.value("long_shot_mult", 1.0):
		# (a twist that makes long shots harder or easier makes the CPU take them less or more: wind, thin air)
		game.stat("cpu_threes")
		start_shot()
		cpu_three_try = shooting
	elif dist_ft <= CPU_KICK_MAX_FT and (open_ft < CPU_KICK_PRESSURE_FT or not lane_open(hoop)) and try_cpu_kickout():
		pass   # kick-out to an open shooter beyond the arc
	elif p > CPU_GOOD_SHOT_P and open_ft > CPU_GOOD_SHOT_OPEN_FT and game.rng.randf() < CPU_GOOD_SHOT_CHANCE:
		start_shot()
	elif open_ft > CPU_OPEN_SHOT_FT and dist_ft < CPU_OPEN_SHOT_RANGE and game.rng.randf() < CPU_OPEN_SHOT_CHANCE:
		start_shot()
	elif game.rng.randf() < CPU_PASS_CHANCE:
		var best = null
		var best_open := open_ft + CPU_PASS_OPEN_EDGE
		for mate in game.teams[team]:
			if mate == self or not game.in_frontcourt(mate.position, team):
				continue
			var o: float = game.openness(mate)
			if o > best_open:
				best_open = o
				best = mate
		if best != null:
			game.do_pass(self, best)

# True while the human's call for the ball (human_input.gd, P2-10) is live and I'm the teammate who would answer it,
# unless the shot clock is under CPU_CALL_HOLD_CLOCK. human_input.gd makes the pass itself once the lane is clear.
func cpu_call_hold() -> bool:
	var inp = game.input
	if inp == null or not inp.has_method("call_active") or not inp.call_active() or inp.call_passer() != self:
		_call_held = false
		return false
	if game.shot_clock < CPU_CALL_HOLD_CLOCK:
		if _call_held:
			game.stat("cpu_call_late_clock")   # held for the call, then the clock ran low: plays on
		_call_held = false
		return false
	if not _call_held:
		_call_held = true
		game.stat("cpu_call_holds")
	return true

# ---------------- alley-oop (P2-09) ----------------

# Where a cutter goes to catch a lob: just out from the rim, on the side he comes from.
func alley_spot() -> Vector2:
	var hoop: Vector2 = game.attack_hoop(team)
	var side: float = clampf(position.y - hoop.y, -ALLEY_SPOT_SIDE_FT * game.FT, ALLEY_SPOT_SIDE_FT * game.FT)
	return hoop + Vector2(game.inward(hoop) * ALLEY_SPOT_FT * game.FT, side)

# A lob is in the air to me
func lob_coming() -> bool:
	var ball = game.ball
	return ball.state == ball.PASS and ball.lob and ball.receiver == self

# ball.gd asks: how many seconds before the lob arrives should I take off (the catch is at ALLEY_CATCH_F of the jump)
func alley_takeoff_lead() -> float:
	return ALLEY_CATCH_F * ALLEY_JUMP_TIME

func is_alley_jumping() -> bool:
	return alley_oop and rim_kind != ""

# The lob receiver goes up for it (called by ball.gd just before the lob arrives, for the human and the CPU alike).
# Reuses the dunk rim move: he catches in the air and dunks at DUNK_RELEASE, blockable through Defense.rim_blocker.
# Too far from the rim (or off balance): no jump, he catches it on the floor.
func start_alley_dunk() -> void:
	if is_airborne() or stumble_t > 0.0 or has_ball():
		return
	var d_ft: float = position.distance_to(game.attack_hoop(team)) / game.FT
	if d_ft > ALLEY_REACH_FT:
		game.stat("alleyoop_too_far")
		return
	if fake_t > 0.0:
		end_pump_fake()
	cross_t = 0.0
	alley_oop = true
	long_dunk = false
	rim_kind = "dunk"
	jump_time = ALLEY_JUMP_TIME
	jump_t = 0.0
	jump_z = 0.0
	jump_released = false
	shooting = true
	game.stat("dunks")
	game.stat("dunks_t%d" % team)
	game.stat("alleyoop_dunks")
	if game.is_human(self):
		game.stat("human_dunks")
	rim_contest()

# Runs every frame: the cut's timer (CPU cuts and P2-10's human cuts alike) and a CPU defender's planned lob jump.
func update_alley(delta: float) -> void:
	if alley_cut:
		if not _cut_on:
			_cut_on = true
			if alley_cut_t <= 0.0:
				alley_cut_t = CPU_CUT_TIME   # set from outside (P2-10): same length as a CPU cut
		if not lob_coming():
			alley_cut_t -= delta
		if alley_cut_t <= 0.0 or game.possession != team or has_ball() or is_airborne():
			alley_cut = false
	if not alley_cut:
		_cut_on = false
		alley_cut_t = 0.0
	if lob_jump_wait >= 0.0:
		lob_jump_wait -= delta
		if lob_jump_wait < 0.0 and start_block_jump():
			game.stat("cpu_lob_jumps")

# CPU off-ball: a spot change can be a cut to the rim (handler in the frontcourt, me far enough out, my man not tight)
func try_cpu_cut(hoop: Vector2) -> bool:
	var ball = game.ball
	if ball.state != ball.HELD or ball.holder == null or ball.holder == self or ball.holder.team != team:
		return false
	if not game.in_frontcourt(ball.holder.position, team) or not game.in_frontcourt(position, team):
		return false
	if position.distance_to(hoop) < CPU_CUT_MIN_FT * game.FT:
		return false
	var man = game.teams[1 - team][index]
	if man.position.distance_to(position) < CPU_CUT_MAN_FT * game.FT:
		return false
	if game.rng.randf() >= Difficulty.value(team, "cut_chance", CPU_CUT_CHANCE):
		return false
	alley_cut_t = CPU_CUT_TIME
	alley_cut = true
	game.stat("rim_cuts_t%d" % team)
	target = alley_spot()
	cpu_turbo_want = true
	return true

# CPU handler driving into traffic: pass to a teammate who is open beyond the arc, when the pass line is clear
func try_cpu_kickout() -> bool:
	var hoop: Vector2 = game.attack_hoop(team)
	var best = null
	var best_open: float = CPU_KICK_OPEN_FT
	for mate in game.teams[team]:
		if mate == self or not game.is_three(mate.position, hoop) or mate.alley_cut:
			continue
		var o: float = game.openness(mate)
		if o >= best_open and pass_lane_clear(mate):
			best_open = o
			best = mate
	if best == null or game.rng.randf() >= Difficulty.value(team, "kick_chance", CPU_KICK_CHANCE):
		return false
	game.stat("cpu_kickouts_t%d" % team)
	best.kick_catch = not game.is_human(best)   # (the human catches it his own way)
	game.do_pass(self, best)
	return true

# no opponent within CPU_KICK_LANE_FT of the line from me to `mate` (my own defender, right on me, can't pick it off)
func pass_lane_clear(mate) -> bool:
	var a: Vector2 = position
	var b: Vector2 = mate.position
	for o in game.teams[1 - team]:
		if o.position.distance_to(a) < 5.0 * game.FT:
			continue
		var t: float = clampf((o.position - a).dot(b - a) / maxf((b - a).length_squared(), 1.0), 0.0, 1.0)
		if o.position.distance_to(a + (b - a) * t) < CPU_KICK_LANE_FT * game.FT:
			return false
	return true

# CPU handler: lob to a teammate the alley-oop rule allows (the human too, when he cuts)
func try_cpu_lob() -> bool:
	var ball = game.ball
	for mate in game.teams[team]:
		if mate == self or not ball.is_lob_target(mate, self):
			continue
		if game.rng.randf() < Difficulty.value(team, "lob_chance", CPU_LOB_CHANCE):
			game.stat("cpu_lobs")
			game.do_pass(self, mate)
			return true
	return false

# ball.gd calls this on the passer when a lob is thrown: CPU defenders near the receiver or the rim read it and
# may time a block jump at the dunk (on block rating; their timing has some error, so it can come too early or late).
func on_lob_thrown(to_p, flight: float) -> void:
	var hoop: Vector2 = game.attack_hoop(team)
	var reach: float = CPU_LOB_READ_FT * game.FT
	var release_in: float = flight + (DUNK_RELEASE - ALLEY_CATCH_F) * ALLEY_JUMP_TIME
	for o in game.teams[1 - team]:
		if game.is_human(o):
			continue
		if o.position.distance_to(to_p.position) > reach and o.position.distance_to(hoop) > reach:
			continue
		var chance: float = Difficulty.value(o.team, "lob_jump_chance", CPU_LOB_JUMP_CHANCE) * (1.0 + CPU_LOB_RATING_SPAN * o.rating_frac("block"))
		if game.rng.randf() < chance:
			o.lob_read_target = to_p
			game.stat("cpu_lob_reads")
			var wait: float = release_in - BLOCK_JUMP_TIME * 0.5 \
					+ game.rng.randf_range(-CPU_LOB_JUMP_JITTER, CPU_LOB_JUMP_JITTER)
			o.lob_jump_wait = maxf(0.0, wait)

# CPU defender who read a lob: run at the receiver while it's in the air and he goes up for it
func lob_defense() -> void:
	if lob_read_target == null:
		return
	var r = lob_read_target
	if not (r.lob_coming() or r.is_alley_jumping()):
		lob_read_target = null
		return
	target = r.position
	speed_mult = 1.0
	cpu_turbo_want = true

# no opponent in a corridor between me and the hoop
func lane_open(hoop: Vector2) -> bool:
	var FT: float = game.FT
	var to_hoop := hoop - position
	var d := to_hoop.normalized()
	for o in game.teams[1 - team]:
		var r: Vector2 = o.position - position
		var along := r.dot(d)
		if along > 0.0 and along < to_hoop.length() and absf(d.cross(r)) < 5.0 * FT:
			return false
	return true

func defense_ai(delta: float) -> void:
	def.cpu_update(delta)

func _draw() -> void:
	if View.angled():
		return   # ANGLED: the view nodes in game.world / decals / overlay draw this player (see the end of the file)
	if jump_z > 0.5:
		# shadow on the floor under a jumping player
		var sr := 16.0 - jump_z * 0.15
		draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.55))
		draw_circle(Vector2.ZERO, sr, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if on_fire:
		draw_fire_ring()
	if turbo and velocity.length() > 20.0:
		# dust puffs behind a sprinting player
		var back := -velocity.normalized()
		draw_circle(back * 18.0, 6.0, Color(1, 1, 1, 0.35))
		draw_circle(back * 30.0 + back.orthogonal() * 4.0, 4.5, Color(1, 1, 1, 0.22))
		draw_circle(back * 40.0 - back.orthogonal() * 3.0, 3.0, Color(1, 1, 1, 0.12))
	if cross_t > 0.0 and cross_dir.length() > 0.1:
		# crossover: speed lines behind the cut
		var a := cross_t / CROSS_TIME
		var bk := -cross_dir
		var sd := bk.orthogonal()
		for k in 3:
			var off := sd * (float(k) - 1.0) * 9.0
			draw_line(bk * 16.0 + off, bk * (38.0 + 10.0 * float(k % 2)) + off, Color(1, 1, 1, 0.9 * a), 4.0)
	if game.is_human(self):
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 32, Color(1, 0.9, 0.2), 3.0)
		var tri := PackedVector2Array([Vector2(-7, -44), Vector2(7, -44), Vector2(0, -34)])
		draw_colored_polygon(tri, Color(1, 0.9, 0.2))
		# stamina bar under the ring
		var bw := 48.0
		var bo := Vector2(-bw / 2, 27)
		draw_rect(Rect2(bo - Vector2(2, 2), Vector2(bw + 4, 14)), Color(0, 0, 0, 0.75))
		var col := Color(0.25, 0.9, 0.35)
		if turbo_locked:
			col = Color(0.55, 0.55, 0.55)
		elif stamina < 0.3:
			col = Color(0.95, 0.25, 0.2)
		elif stamina < 0.6:
			col = Color(1.0, 0.8, 0.2)
		draw_rect(Rect2(bo, Vector2(bw * stamina, 10)), col)
		var mark := bo.x + bw * TURBO_MIN_RESTART
		draw_line(Vector2(mark, bo.y), Vector2(mark, bo.y + 10), Color(1, 1, 1, 0.5), 1.0)
	if shooting and game.is_human(self):
		var w := 56.0
		var o := Vector2(-w / 2, -58)
		draw_rect(Rect2(o, Vector2(w, 10)), Color(0, 0, 0, 0.7))
		var glo := green_lo()
		var gcol := Color(1.0, 0.6, 0.15) if on_fire else Color(0.2, 0.9, 0.3)
		draw_rect(Rect2(o + Vector2(w * glo / 1.2, 0), Vector2(w * (green_hi() - glo) / 1.2, 10)), gcol)
		var c: float = min(shot_charge, 1.2) / 1.2
		draw_rect(Rect2(o + Vector2(w * c - 2, -3), Vector2(4, 16)), Color.WHITE)

# flickering flame ring on the floor around an on-fire player (visible without the ball)
func draw_fire_ring() -> void:
	var t := fire_anim
	var r := 26.0 + 1.5 * sin(t * 9.0)
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(1.0, 0.25, 0.05, 0.85), 4.0)
	draw_arc(Vector2.ZERO, r - 3.0, 0, TAU, 40, Color(1.0, 0.75, 0.2, 0.9), 2.0)
	var n := 8
	for i in n:
		var a: float = TAU * float(i) / float(n) + t * 1.5
		var h: float = 9.0 + 4.0 * sin(t * 13.0 + float(i) * 1.7)
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal() * 4.0
		var base := dir * r
		var flame := PackedVector2Array([base - side, base + side, base + dir * h])
		var col := FIRE_RING_COLOR if i % 2 == 0 else Color(1.0, 0.8, 0.2)
		draw_colored_polygon(flame, col)

# ---------------- drawing in the 3/4 view (P4-06, ANGLED only; FLAT draws with `sprite` and _draw() above) ----------------
# Visual only: everything here reads the sim state (position, velocity, facing, jump_z, timers) and never writes it.
# Three nodes per player: the upright sprite in game.world (y-sorted: its position is the projected floor point),
# the floor things (shadow, team ring, fire ring, dust, crossover lines) in game.decals, and the human's arrow,
# stamina bar and shot meter in game.overlay. Sheet layout: docs/BOARD.md "Player sprite sheets".

const PLAYER_SCALE := 2.0         # sheet frames are drawn at 2x
const SHEET_FRAME := Vector2(40, 64)
const SHEET_COLS := 37
const SHEET_ROWS := 5
const SHEET_FEET_Y := 59.0        # the floor row inside a frame
# animation: [start column, frames] (board contract; P4-09 fills the columns that still hold idle frames)
const ANIMS := {
	"idle": [0, 2], "run": [2, 6], "dribble": [8, 4], "shoot": [12, 4], "dunk": [16, 5], "layup": [21, 3],
	"block": [24, 3], "poke": [27, 2], "stumble": [29, 2], "pass": [31, 2], "celebrate": [33, 4],
}
# screen octant (0 = E, 1 = SE, 2 = S ... 7 = NE, clockwise on screen) -> sheet row and mirror
const OCT_ROW := [2, 1, 0, 1, 2, 3, 4, 3]
const OCT_FLIP := [false, false, false, true, true, true, false, false]
const DIR_HYST_DEG := 8.0         # degrees past an octant's edge before the sprite turns (no flicker on the edge)
# frames per second
const IDLE_FPS := 2.0
const RUN_FPS := 11.0             # at full speed (`speed`); scaled by the actual speed, never below RUN_FPS_MIN
const RUN_FPS_MIN := 5.0
const RUN_MIN_SPEED := 22.0       # px/s: slower than this is standing (idle)
const DRIBBLE_FPS := 7.0
const CROSS_DRIBBLE_MULT := 2.2   # dribble fps x this during a crossover
const CROSS_LEAN_DEG := 12.0      # sprite lean into the cut at the start of a crossover
const POKE_FPS := 8.0
const STUMBLE_FPS := 6.0
const PASS_FPS := 8.0
const CELEBRATE_FPS := 6.0
const PASS_ANIM_TIME := 0.25      # seconds the pass pose shows after the ball leaves the hands
const FOLLOW_TIME := 0.3          # seconds the last shoot frame (follow-through) shows after a jumper's release
const CELEBRATE_TIME := 1.4       # seconds the scorer celebrates after a make (unless he runs off at speed)
const CELEBRATE_MAX_SPEED := 90.0 # px/s: faster than this he runs instead
# heights (sim pixels of height, drawn through View.to_screen)
const DUNK_VIEW_LIFT := 1.5       # a dunk / alley-oop jump drawn this much higher so the hands reach the rim (Heights)
const HEAD_PX := 80.0             # top of the head above the feet at PLAYER_SCALE (40 px character x 2)
# floor marks (sim pixels; projected, so they foreshorten with the court)
const TEAM_RING_R := 21.0
const TEAM_RING_COLORS := [Color(0.35, 0.65, 1.0), Color(1.0, 0.32, 0.3)]
const HUMAN_RING_R := 27.0
const HUMAN_COLOR := Color(1, 0.9, 0.2)
const RING_SEGMENTS := 28

var _v_body: Node2D               # game.world: sorted by its position (the projected floor point)
var _v_spr: Sprite2D              # the sheet (or the Kenney fallback texture) inside _v_body
var _v_decal: Node2D              # game.decals
var _v_over: Node2D               # game.overlay
var _v_sheet := false             # false: the sheet is missing, the Kenney top-down sprite stands in
var _v_oct := -1
var _v_anim := ""
var _v_phase := 0.0               # frames advanced in the current looping animation
var _v_lift := 0.0                # drawn jump height (sim pixels)
var _v_pass_t := 0.0
var _v_follow_t := 0.0
var _v_celebrate_t := 0.0
var _v_was_passing := false
var _v_was_shooting := false
var _v_make_seen := false

func _build_view() -> void:
	sprite.visible = false
	_v_body = Node2D.new()
	_v_body.name = "PlayerView%d_%d" % [team, index]
	_v_spr = Sprite2D.new()
	var sh: Dictionary = Sheets.load_first(sheet_ids())   # v2 then v1 of each id, in sheet_ids()'s order
	if int(sh.get("version", 0)) == 2:
		_build_view_v2(sh)
	elif int(sh.get("version", 0)) == 1:
		_v_spr.texture = sh["texture"]   # a v1 sheet (none ship since P6-25; the reader stays)
		_v_sheet_id = str(sh["id"])
	if _v_ver == 2:
		pass
	elif _v_spr.texture != null and _v_spr.texture.get_size() == SHEET_FRAME * Vector2(SHEET_COLS, SHEET_ROWS):
		_v_sheet = true
		_v_spr.hframes = SHEET_COLS
		_v_spr.vframes = SHEET_ROWS
		_v_spr.centered = false
		_v_spr.offset = Vector2(-SHEET_FRAME.x / 2.0, -SHEET_FEET_Y)   # the feet at the node's origin
	else:
		_v_spr.texture = sprite.texture   # fallback: today's top-down sprite, turned to the screen direction
	_v_body.add_child(_v_spr)
	game.world.add_child(_v_body)
	_v_decal = Node2D.new()
	_v_decal.draw.connect(_draw_view_decal)
	game.decals.add_child(_v_decal)
	_v_over = Node2D.new()
	_v_over.draw.connect(_draw_view_overlay)
	game.overlay.add_child(_v_over)
	# P6-23 motion effects listen to the view's own events (v2 emits them from its frame picker, v1 from _fx_v1_events)
	view_takeoff.connect(_fx_on_takeoff)
	view_landed.connect(_fx_on_landed)
	view_dunk_slam.connect(_fx_on_slam)

func _process(delta: float) -> void:
	if _v_body != null:
		_update_view(delta)

# the drawn height of the jump (dunks and alley-oops lifted so the hands reach the rim)
func _view_lift() -> float:
	if _v_ver == 2:
		return _v_lift   # v2: the hang curve, set with the frame (_v2_lift)
	if rim_kind == "dunk":
		return jump_z * DUNK_VIEW_LIFT
	return jump_z

func _update_view(delta: float) -> void:
	var ball = game.ball
	_v_lift = _view_lift()
	# one-shot animation triggers, seen from the sim state
	var passing: bool = ball.state == ball.PASS and ball.passer == self
	if passing and not _v_was_passing:
		_v_pass_t = PASS_ANIM_TIME
		if _v_ver == 2:
			_v2_on_pass()
	_v_was_passing = passing
	if _v_was_shooting and not shooting and rim_kind == "" and ball.state == ball.SHOT and ball.shooter == self:
		_v_follow_t = FOLLOW_TIME
		if _v_ver == 2:
			var sa: String = _v2_shot_anim()
			_v_follow_t = _v2_time_from(sa, Sheets.anim_event(_v_fmt, sa, "release", 0))
	_v_was_shooting = shooting
	if ball.state == ball.SHOT and ball.shooter == self and ball.shot_made:
		if not _v_make_seen:
			_v_celebrate_b = ball.shot_kind == "dunk"   # v2: the big celebration after a dunk
		_v_make_seen = true
	elif _v_make_seen and ball.state != ball.SHOT:
		_v_make_seen = false
		_v_celebrate_t = CELEBRATE_TIME
	_v_pass_t = maxf(0.0, _v_pass_t - delta)
	_v_follow_t = maxf(0.0, _v_follow_t - delta)
	_v_celebrate_t = maxf(0.0, _v_celebrate_t - delta)

	var base: Vector2 = View.to_screen(position, 0.0)
	_v_body.position = base
	var sc: float = View.size_at(position)
	var up: float = base.y - View.to_screen(position, _v_lift).y
	_fx_cuts(delta)
	if _v_ver == 2:
		_update_sheet_frame_v2(delta)   # also sets the drawn lift (_v_lift)
		_v_spr.scale = Vector2.ONE * Sheets.draw_scale(_v_fmt) * sc * _fx_squash(delta)   # around the feet point
		_v_spr.position = Vector2(0, -(base.y - View.to_screen(position, _v_lift).y))
		_v2_texmem()
	elif _v_sheet:
		_update_sheet_frame(delta)
		_fx_v1_events()
		_v_spr.scale = Vector2(PLAYER_SCALE, PLAYER_SCALE) * sc * _fx_squash(delta)   # the feet are the origin
		_v_spr.position = Vector2(0, -up)
	else:
		_fx_v1_events()   # the top-down fallback: dust and the punch, no squash (a centered, turned sprite)
		_fx_squash(delta)
		_v_spr.rotation = View.screen_angle(position, facing)
		_v_spr.scale = Vector2(1.75, 1.75) * sc * (1.0 + 0.15 * jump_z / DUNK_JUMP_PX)
		_v_spr.position = Vector2(0, -up - 14.0 * sc)
	_v_decal.queue_redraw()
	_v_over.queue_redraw()

# picks the direction row (8 screen directions, 3 mirrored), the animation and its frame
func _update_sheet_frame(delta: float) -> void:
	var a: float = View.screen_angle(position, facing)
	var step := PI / 4.0
	if _v_oct < 0 or absf(wrapf(a - float(_v_oct) * step, -PI, PI)) > step / 2.0 + deg_to_rad(DIR_HYST_DEG):
		_v_oct = wrapi(roundi(a / step), 0, 8)
	var row: int = OCT_ROW[_v_oct]
	var flip: bool = OCT_FLIP[_v_oct]
	var spd: float = velocity.length()
	var anim := "idle"
	var k := -1               # frame for progress-driven animations (-1: run the clock)
	var fps := IDLE_FPS
	var loop := true
	if rim_kind != "":
		anim = rim_kind       # "dunk" (also the alley-oop) or "layup"
		k = int(clampf(jump_t / maxf(jump_time, 0.01), 0.0, 0.999) * float(ANIMS[anim][1]))
	elif block_jump_t >= 0.0:
		anim = "block"
		k = int(clampf(block_jump_t / BLOCK_JUMP_TIME, 0.0, 0.999) * 3.0)
	elif fake_t > 0.0:
		anim = "shoot"        # pump fake: shoot frames 0-1 and back
		k = [0, 1, 1, 0][int(clampf(1.0 - fake_t / PUMP_TIME, 0.0, 0.999) * 4.0)]
	elif shooting:
		anim = "shoot"        # jumper or free throw: frames 0-2 through the windup / meter
		var f := 0.0
		if game.is_human(self):
			f = shot_charge
		else:
			f = shot_elapsed / maxf(shot_elapsed + maxf(cpu_shot_time, 0.0), 0.01)
		k = int(clampf(f, 0.0, 0.999) * 3.0)
	elif _v_follow_t > 0.0:
		anim = "shoot"
		k = 3
	elif poke_t > 0.0:
		anim = "poke"
		fps = POKE_FPS
		loop = false
	elif stumble_t > 0.0:
		anim = "stumble"
		fps = STUMBLE_FPS
	elif _v_pass_t > 0.0:
		anim = "pass"
		fps = PASS_FPS
		loop = false
	elif (_v_celebrate_t > 0.0 and spd < CELEBRATE_MAX_SPEED) or _won_game():
		anim = "celebrate"
		fps = CELEBRATE_FPS
	elif has_ball() and not at_free_throw():
		anim = "dribble"
		fps = DRIBBLE_FPS * (CROSS_DRIBBLE_MULT if cross_t > 0.0 else 1.0)
		# the sheet dribbles with the right hand: facing or backing the camera, mirror it for the left hand
		if hand_x < 0.0 and (row == 0 or row == 4):
			flip = not flip
	elif spd > RUN_MIN_SPEED:
		anim = "run"
		fps = maxf(RUN_FPS_MIN, RUN_FPS * spd / maxf(speed, 1.0))
	if anim != _v_anim:
		_v_anim = anim
		_v_phase = 0.0
	else:
		_v_phase += delta * fps
	var n: int = ANIMS[anim][1]
	if k < 0:
		k = int(_v_phase) % n if loop else mini(int(_v_phase), n - 1)
	_v_spr.frame = row * SHEET_COLS + int(ANIMS[anim][0]) + clampi(k, 0, n - 1)
	_v_spr.flip_h = flip
	# crossover: lean into the cut, easing out over the burst
	var lean := 0.0
	if cross_t > 0.0 and cross_dir.length() > 0.1:
		var sx: float = (View.to_screen(position + cross_dir * game.FT) - View.to_screen(position)).x
		lean = deg_to_rad(CROSS_LEAN_DEG) * signf(sx) * cross_t / CROSS_TIME
	_v_spr.rotation = lean

func _won_game() -> bool:
	return game.game_over and int(game.score[team]) > int(game.score[1 - team])

# a circle of radius r (sim px) around sim point c, on the floor, projected
func _floor_ring(c: Vector2, r: float, segments: int = RING_SEGMENTS) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments + 1:
		pts.append(View.to_screen(c + Vector2.from_angle(TAU * float(i) / float(segments)) * r))
	return pts

func _draw_view_decal() -> void:
	var n := _v_decal
	# shadow: under the feet, shrinking as he goes up
	var sr: float = maxf(8.0, 16.0 - _v_lift * 0.15)
	var shadow := _floor_ring(position + Vector2(0, 2), sr, 20)
	shadow.remove_at(shadow.size() - 1)   # (a polygon: no repeated closing point)
	n.draw_colored_polygon(shadow, Color(0, 0, 0, 0.25 if _v_lift > 0.5 else 0.18))
	# soft team ring (like the style sample: a strong edge, a fainter inside band, a faint halo)
	var col: Color = TEAM_RING_COLORS[team]
	n.draw_polyline(_floor_ring(position, TEAM_RING_R * 1.08), Color(col, 0.25), 2.0)
	n.draw_polyline(_floor_ring(position, TEAM_RING_R), Color(col, 0.85), 2.5)
	n.draw_polyline(_floor_ring(position, TEAM_RING_R * 0.82), Color(col, 0.4), 2.0)
	if game.is_human(self):
		n.draw_polyline(_floor_ring(position, HUMAN_RING_R, 36), HUMAN_COLOR, 3.0)
	if on_fire:
		_draw_view_fire_ring(n)
	if turbo and velocity.length() > 20.0:
		# dust puffs behind a sprinting player
		var back := -velocity.normalized()
		var side := back.orthogonal()
		var puffs := [[back * 18.0, 6.0, 0.35], [back * 30.0 + side * 4.0, 4.5, 0.22], [back * 40.0 - side * 3.0, 3.0, 0.12]]
		for q in puffs:
			var puff := _floor_ring(position + (q[0] as Vector2), float(q[1]), 12)
			puff.remove_at(puff.size() - 1)
			n.draw_colored_polygon(puff, Color(1, 1, 1, float(q[2])))
	if cross_t > 0.0 and cross_dir.length() > 0.1:
		# crossover: speed lines behind the cut, at knee height
		var a := cross_t / CROSS_TIME
		var bk := -cross_dir
		var sd := bk.orthogonal()
		for k in 3:
			var off := sd * (float(k) - 1.0) * 9.0
			n.draw_line(View.to_screen(position + bk * 16.0 + off, 12.0),
					View.to_screen(position + bk * (38.0 + 10.0 * float(k % 2)) + off, 12.0),
					Color(1, 1, 1, 0.9 * a), 3.0)

# the flickering flame ring of an on-fire player, on the floor; the flames stand up
func _draw_view_fire_ring(n: Node2D) -> void:
	var t := fire_anim
	var r := 26.0 + 1.5 * sin(t * 9.0)
	n.draw_polyline(_floor_ring(position, r, 40), Color(1.0, 0.25, 0.05, 0.85), 3.0)
	n.draw_polyline(_floor_ring(position, r - 3.0, 40), Color(1.0, 0.75, 0.2, 0.9), 2.0)
	var cnt := 8
	for i in cnt:
		var a: float = TAU * float(i) / float(cnt) + t * 1.5
		var h: float = 9.0 + 4.0 * sin(t * 13.0 + float(i) * 1.7)
		var dir := Vector2.from_angle(a)
		var base := position + dir * r
		var side := dir.orthogonal() * 4.0
		var flame := PackedVector2Array([View.to_screen(base - side), View.to_screen(base + side),
				View.to_screen(base + dir * 2.0, h)])
		var col := FIRE_RING_COLOR if i % 2 == 0 else Color(1.0, 0.8, 0.2)
		# draw_primitive: a flame seen edge-on is a sliver (draw_colored_polygon's triangulation would complain)
		n.draw_primitive(flame, PackedColorArray([col, col, col]), PackedVector2Array())

# the human's arrow over the head, the stamina bar under the feet and the shot meter above the arrow
func _draw_view_overlay() -> void:
	if not game.is_human(self):
		return
	var n := _v_over
	var feet: Vector2 = View.to_screen(position, 0.0)
	var head: Vector2 = View.to_screen(position, _v_lift) - Vector2(0, view_head_px() * View.size_at(position))
	var tri := PackedVector2Array([head + Vector2(-7, -16), head + Vector2(7, -16), head + Vector2(0, -6)])
	n.draw_colored_polygon(tri, HUMAN_COLOR)
	var bw := 48.0
	var bo := feet + Vector2(-bw / 2, 16)
	n.draw_rect(Rect2(bo - Vector2(2, 2), Vector2(bw + 4, 14)), Color(0, 0, 0, 0.75))
	var col := Color(0.25, 0.9, 0.35)
	if turbo_locked:
		col = Color(0.55, 0.55, 0.55)
	elif stamina < 0.3:
		col = Color(0.95, 0.25, 0.2)
	elif stamina < 0.6:
		col = Color(1.0, 0.8, 0.2)
	n.draw_rect(Rect2(bo, Vector2(bw * stamina, 10)), col)
	var mark := bo.x + bw * TURBO_MIN_RESTART
	n.draw_line(Vector2(mark, bo.y), Vector2(mark, bo.y + 10), Color(1, 1, 1, 0.5), 1.0)
	if shooting:
		var w := 56.0
		var o := head + Vector2(-w / 2, -32)
		n.draw_rect(Rect2(o, Vector2(w, 10)), Color(0, 0, 0, 0.7))
		var glo := green_lo()
		var gcol := Color(1.0, 0.6, 0.15) if on_fire else Color(0.2, 0.9, 0.3)
		n.draw_rect(Rect2(o + Vector2(w * glo / 1.2, 0), Vector2(w * (green_hi() - glo) / 1.2, 10)), gcol)
		var c: float = minf(shot_charge, 1.2) / 1.2
		n.draw_rect(Rect2(o + Vector2(w * c - 2, -3), Vector2(4, 16)), Color.WHITE)

# ---------------- v2 sheets (P6-21; board "Animation table", "Player sheet format v2") ----------------
# Visual only, like everything above: the frame comes from the sim (velocity, facing, timers, rim_kind, jump_t,
# block_jump_t, the ball's dribble phase) and nothing here writes to the sim. v1 sheets never come here
# (_update_sheet_frame above is today's mapping, unchanged). The frame counts, per-frame times (ms) and the event
# frames (release, floor, hang, rim, swat, ...) come from assets/players2/format.json through Sheets.
# Hooks for the motion effects (P6-23): the signals below, and v_anim, v_land_t, v_dunk_style, v_flip (read-only).

signal view_takeoff(kind: String)               # the drawn jump left the floor: "dunk", "layup" or "block"
signal view_landed(kind: String)                # feet back on the floor (a dunk: after the rim hang and the drop)
signal view_dunk_slam(style: String, big: bool) # a dunk's release frame (the slam); big = turbo, alley, windmill, tomahawk

const V2_RUN_RATE_MIN := 0.45     # run / slide never play slower than this x the drawn speed (v1: RUN_FPS_MIN / RUN_FPS)
const RUN_DRIBBLE_FRAC := 0.4     # moving with the ball faster than this fraction of top speed: the running dribble
const SLIDE_RANGE_FT := 15.0      # defensive slide: the opposing ball handler within this ...
const SLIDE_MIN_DEG := 50.0       # ... and moving at least this far off the line to him (not running at him) ...
const SLIDE_MAX_FRAC := 0.85      # ... and slower than this fraction of top speed (faster is a run), no turbo
const SLIDE_FULL_FRAC := 0.6      # the slide plays at its drawn speed at this fraction of top speed
const SLIDE_HOLD := 0.25          # seconds a slide keeps going after its angle stops qualifying (no flicker)
const RUN_DRIBBLE_HYST := 0.05    # +/- this around RUN_DRIBBLE_FRAC to switch (no flicker at that speed)
const DUNK_HANG_F := 0.3          # fraction of a dunk's jump when he reaches the hang frame (the top)
const DUNK_HANG_ABOVE := 10.0     # px: the hands this far over the rim while he hangs before the slam
const DUNK_RIM_GRIP := 4.0        # px: the hands this far over the rim at the slam and while he hangs on it
const DUNK_RIM_REACH_F := 0.08    # fraction of the jump from the release frame to the hands-on-rim frame
const DUNK_REACH_HEADS := 0.92    # without hand data: the hands reach this x the drawn height at the release
const RIM_HANG_TIME := 0.3        # seconds on the rim after a made dunk (Q7 a: a short rim hang)
const RIM_HANG_MAX_MOVE_FT := 1.5 # ... cut short once he has moved this far from where he came down
const DUNK_DROP_TIME := 0.18      # seconds of the drawn drop from the rim to the floor
const LIFT_FOLLOW := 30.0         # 1/s: the drawn lift follows the hands-on-rim height this fast
const BIG_DUNK_STYLES := ["dunk_windmill", "dunk_tomahawk", "dunk_alley"]
const WINDMILL_FINISH := 70       # a finishing rating this high (or a boss) can windmill without turbo
const WINDMILL_PCT := 30          # % of the dunks that can windmill (turbo, great finisher or boss) that do ...
const WINDMILL_BOTH_PCT := 50     # ... and when he is both on turbo and a great finisher / boss
const TOMAHAWK_SPEED_FRAC := 0.9  # a dunk at this fraction of top speed (or turbo) is a tomahawk or a one-hander
const TURBO_DUNK_WINDOW := 0.6    # seconds: a dunk this soon after sprinting looks like a turbo dunk
const ANKLE_BREAK_FT := 2.25      # Q7 a: a crossover that beats a defender this close is an ankle-breaker (he falls;
const ANKLE_BREAK_PCT := 30       # ... this % of them, by a hash of the play, no random call: about 1-3 a game)
const FALL_GETUP_TIME := 0.35     # seconds of the get-up frames after an ankle-breaker's stumble ends
const PUMP_TOP_FRAME := 4         # a pump fake rises through the shoot frames to this one and back
const TEXMEM_FLAG := "--texmem"   # test: print the video memory once a game is running (xvfb, not headless)

var _v_ver := 1                   # 2: a v2 sheet (pages, format.json), drawn by _update_sheet_frame_v2
var _v_sheet_data := {}           # Sheets.load_sheet() of the drawn sheet
var _v_fmt := {}
var _v_sheet_id := ""             # the drawn sheet's id (hands.json key; "" = the Kenney fallback)
var v_anim := ""                  # v2: the animation drawn this frame (after Sheets.resolve)
var v_frame := 0                  # v2: its frame index (Sheets.frame_index: row * cols + column)
var v_next_frame := 0             # ... the next frame, and how far into this one (ball.gd blends the ball point)
var v_frame_frac := 0.0
var v_flip := false               # the frame is mirrored (SW, W, NW)
var v_dunk_style := ""            # this dunk's look (Q6: dunk_one, dunk_two, dunk_tomahawk, dunk_windmill, dunk_alley)
var v_land_t := 0.0               # seconds left of the land frames (> 0 right after a jump came down)
var v_turbo_dunk := false         # this dunk came off a sprint (TURBO_DUNK_WINDOW): a "big" dunk for the camera punch
var _v_clock := 0.0               # seconds (x the play rate) into the current clock-driven animation
var _v_was_air := false
var _v_air_kind := ""
var _v_slam := false              # this dunk went down (rim hang after it)
var _v_rel_seen := false
var _v_rim_t := -1.0              # seconds left hanging on the rim (< 0: not hanging)
var _v_drop_t := -1.0             # seconds left of the drop from the rim
var _v_rim_spot := Vector2.ZERO
var _v_hold_lift := 0.0           # the drawn lift while on the rim (the drop starts from it)
var _v_stumble_prev := 0.0
var _v_stumble_len := 0.0
var _v_fall := false              # the current stumble is an ankle-breaker
var _v_getup_t := -1.0
var _v_catch_t := 0.0
var _v_had_ball := false
var _v_ball_prev := -1            # the ball's state in the last drawn frame
var _v_pass_kind := "pass_chest"
var _v_celebrate_b := false
var _v_texmem_frames := -1
var _v_slide_hold := 0.0
var _v_hook_seen := -1            # game.shot_serial of the last hook counted in anim_hook

# the sheet ids to try, in order: team 0 his _crew recolor, his own sheet, then his slot's Quick Game sheet. A Quick
# Game team (P6-T3, "own_colors" in the dict) wears its own colors on either side: no _crew recolor.
func sheet_ids() -> Array:
	var out: Array = []
	var sheet: String = str(pdata.get("sheet", ""))
	if sheet != "":
		if team == 0 and not bool(pdata.get("own_colors", false)):
			out.append(sheet + CREW_SHEET_SUFFIX)
		out.append(sheet)
	var slot: Array = QUICK_SHEETS[clampi(team, 0, 1)]
	out.append(str(slot[clampi(index, 0, slot.size() - 1)]))
	return out

# the drawn height of the head above the feet (v1 80 px; v2 from format.json head_px x draw_scale, about 100)
func view_head_px() -> float:
	if _v_ver == 2:
		return Sheets.head_px(_v_fmt) * Sheets.draw_scale(_v_fmt)
	return HEAD_PX

# how much taller this player is drawn than a v1 player (1.0 on v1; ball.gd scales its catch and reach heights)
func view_head_scale() -> float:
	return view_head_px() / HEAD_PX

func _build_view_v2(sh: Dictionary) -> void:
	_v_ver = 2
	_v_sheet = true
	_v_sheet_data = sh
	_v_fmt = sh["fmt"]
	_v_sheet_id = str(sh["id"])
	_v_spr.texture = sh["texture"]
	_v_spr.region_enabled = true
	_v_spr.region_rect = Rect2(Vector2.ZERO, Sheets.frame_size(_v_fmt))
	_v_spr.centered = false
	_v_spr.offset = Vector2(-Sheets.center_x(_v_fmt), -Sheets.feet_y(_v_fmt))   # the floor point at the node's origin
	var mat: ShaderMaterial = Sheets.material(sh)   # v2.1 indexed pages: drawn in this sheet's palette
	if mat != null:
		_v_spr.material = mat
	if OS.get_cmdline_user_args().has(TEXMEM_FLAG) and team == 0 and index == 0:
		_v_texmem_frames = 0

# called by the handler's cross_beat_check right after this defender was beaten (drawing only)
func view_crossed(by, d_ft: float) -> void:
	if d_ft > ANKLE_BREAK_FT:
		return
	var h: int = absi(hash([by.team, by.index, team, index, game.shot_serial, int(game.score[0]), int(game.score[1])]))
	if h % 100 >= ANKLE_BREAK_PCT:
		return
	_v_fall = true
	_v_getup_t = -1.0
	game.stat("ankle_breakers")

# a pass left my hands: which throw it looks like (ball.gd picks it, so the ball flies the same way)
func _v2_on_pass() -> void:
	var ball = game.ball
	var look: String = ball.pass_look() if ball.has_method("pass_look") else "chest"
	_v_pass_kind = "pass_" + (look if look != "" else "chest")
	_v_pass_t = _v2_time_from(_v_pass_kind, Sheets.anim_event(_v_fmt, _v_pass_kind, "release", 0))
	game.stat("anim_" + _v_pass_kind)

# seconds the frames from `k` to the end take (format.json ms)
func _v2_time_from(anim: String, k: int) -> float:
	var t := 0.0
	var times: PackedFloat32Array = Sheets.anim_times(_v_fmt, anim)
	for i in range(maxi(k, 0), times.size()):
		t += times[i]
	return t

# a clock time -> frame position (frame + fraction) through the frame times; wraps or holds the last frame
func _v2_clock_x(anim: String, t: float, loop: bool) -> float:
	var times: PackedFloat32Array = Sheets.anim_times(_v_fmt, anim)
	var total := 0.0
	for d in times:
		total += d
	if total <= 0.0:
		return 0.0
	if loop:
		t = fposmod(t, total)
	elif t >= total:
		return float(times.size()) - 0.001
	t = maxf(t, 0.0)
	for i in times.size():
		if t < times[i]:
			return float(i) + t / maxf(times[i], 0.0001)
		t -= times[i]
	return float(times.size()) - 0.001

# a progress f -> frame position through [f, frame] anchors (f rising; frames rising)
func _v2_anchor_x(anchors: Array, f: float) -> float:
	if f <= float(anchors[0][0]):
		return float(anchors[0][1])
	for i in range(1, anchors.size()):
		var a: Array = anchors[i - 1]
		var b: Array = anchors[i]
		if f <= float(b[0]):
			var span: float = maxf(float(b[0]) - float(a[0]), 0.0001)
			return lerpf(float(a[1]), float(b[1]), (f - float(a[0])) / span)
	return float(anchors[anchors.size() - 1][1])

# the dribble phase (0 = in the hand at the top, 0.5 = on the floor) -> frame position, so the drawn ball touches the
# floor on the animation's "floor" frame exactly when the sim's dribble does
func _v2_phase_x(anim: String, p: float) -> float:
	var n: float = float(Sheets.anim_frames(_v_fmt, anim))
	# "bounces": 2 (P6-A7 run_dribble): the cycle is 2 steps and 2 dribbles, "floor" lists one frame per bounce; the
	# sim's bounce count picks the half (1 = the old rule: one bounce per cycle)
	var b: int = maxi(1, Sheets.anim_event(_v_fmt, anim, "bounces", 1))
	var floors = ((_v_fmt.get("anims", {}) as Dictionary).get(anim, {}) as Dictionary).get("floor", null)
	var j: int = 0
	if b > 1:
		var bl = game.ball
		j = posmod(floori(float(bl.anim_time) * float(bl.DRIBBLE_RATE) / PI - 0.5), b)
	var seg: float = n / float(b)
	var start: float = seg * float(j)
	var fl: float = start + float(int(seg / 2.0))
	if floors is Array and (floors as Array).size() > j:
		fl = float(floors[j])
	elif floors != null and j == 0:
		fl = float(Sheets.anim_event(_v_fmt, anim, "floor", int(n / 2.0)))
	if p < 0.5:
		return start + p / 0.5 * (fl - start)
	return fl + (p - 0.5) / 0.5 * (start + seg - fl)

# P9-20: a hook shot plays the sheet's "hook" frames when it carries them (Sheets.has_anim; P9-04c extra pages), else
# the normal jump shot. Drawing only: hook_shot is the sim's.
func _v2_shot_anim() -> String:
	if hook_shot and Sheets.has_anim(_v_fmt, "hook"):
		if shooting and _v_hook_seen != game.shot_serial:
			_v_hook_seen = game.shot_serial
			game.stat("anim_hook")
		return "hook"
	return "shoot"

# Q6: the dunk's look. Score chance is the sim's; this only picks the frames (a hash of the player and the play)
func _v2_dunk_style() -> String:
	if alley_oop:
		return "dunk_alley"
	if long_dunk:
		return "dunk_two"   # P9-20: the power drop-step ends in a two-hand dunk
	var roll: int = absi(hash([team, index, pid, game.shot_serial, int(game.score[0]), int(game.score[1])])) % 100
	var fast: bool = turbo or since_turbo < TURBO_DUNK_WINDOW
	var great: bool = rating("finishing") >= WINDMILL_FINISH or str(pdata.get("tier", "")) == "boss"
	if (fast or great) and roll < (WINDMILL_BOTH_PCT if fast and great else WINDMILL_PCT):
		return "dunk_windmill"
	if fast or velocity.length() >= TOMAHAWK_SPEED_FRAC * speed:
		return "dunk_tomahawk" if roll % 2 == 0 else "dunk_one"
	return "dunk_one" if roll % 3 == 0 else "dunk_two"

# the direction a defensive slide faces (to the ball handler), or ZERO when he isn't sliding
# (it holds on for SLIDE_HOLD after the angle stops qualifying, so it doesn't flicker with the run)
func _v2_slide_face(spd: float, delta: float) -> Vector2:
	_v_slide_hold = maxf(0.0, _v_slide_hold - delta)
	if spd <= RUN_MIN_SPEED or spd > SLIDE_MAX_FRAC * speed or turbo or has_ball() or is_airborne():
		_v_slide_hold = 0.0
		return Vector2.ZERO
	var ball = game.ball
	if ball.state != ball.HELD or ball.holder == null or ball.holder.team == team:
		_v_slide_hold = 0.0
		return Vector2.ZERO
	var to_h: Vector2 = ball.holder.position - position
	if to_h.length() > SLIDE_RANGE_FT * game.FT or to_h.length() < 1.0:
		_v_slide_hold = 0.0
		return Vector2.ZERO
	if absf(velocity.angle_to(to_h)) < deg_to_rad(SLIDE_MIN_DEG):
		return to_h if _v_slide_hold > 0.0 else Vector2.ZERO
	_v_slide_hold = SLIDE_HOLD
	return to_h

# the hands' height over the floor point in a frame, drawn (sim px of height)
func _v2_hand_h(idx: int) -> float:
	var hd: Dictionary = Sheets.hand(_v_fmt, _v_sheet_id, idx, false)
	if hd.is_empty():
		return DUNK_REACH_HEADS * view_head_px()
	var top: float = minf((hd["L"] as Vector2).y, (hd["R"] as Vector2).y)
	return (Sheets.feet_y(_v_fmt) - top) * Sheets.draw_scale(_v_fmt)

func _v2_land(kind: String) -> void:
	v_land_t = _v2_time_from("land", 0)
	view_landed.emit(kind)

# picks the v2 animation and frame (and the drawn lift) from the sim state
func _update_sheet_frame_v2(delta: float) -> void:
	var ball = game.ball
	var fmt: Dictionary = _v_fmt
	var spd: float = velocity.length()
	var hb: bool = has_ball()
	var air: bool = is_airborne()
	# the direction row (as v1); a defensive slide faces the ball handler
	var slide_to: Vector2 = _v2_slide_face(spd, delta)
	var face: float = slide_to.angle() if slide_to != Vector2.ZERO else facing
	var a: float = View.screen_angle(position, face)
	var step := PI / 4.0
	if _v_oct < 0 or absf(wrapf(a - float(_v_oct) * step, -PI, PI)) > step / 2.0 + deg_to_rad(DIR_HYST_DEG):
		_v_oct = wrapi(roundi(a / step), 0, 8)
	var row: int = OCT_ROW[_v_oct]
	var flip: bool = OCT_FLIP[_v_oct]

	# events seen from the sim: take-off, the slam, landing, the rim hang, a catch, stumbles
	if air and not _v_was_air:
		_v_air_kind = "block" if block_jump_t >= 0.0 else rim_kind
		_v_slam = false
		_v_rel_seen = false
		_v_rim_t = -1.0
		_v_drop_t = -1.0
		v_land_t = 0.0
		v_turbo_dunk = rim_kind == "dunk" and (turbo or since_turbo < TURBO_DUNK_WINDOW)
		v_dunk_style = _v2_dunk_style() if rim_kind == "dunk" else ""
		if v_dunk_style != "":
			game.stat("anim_" + v_dunk_style)
		view_takeoff.emit(_v_air_kind)
	if rim_kind == "dunk" and jump_released and not _v_rel_seen:
		_v_rel_seen = true
		_v_slam = ball.state == ball.SHOT and ball.shooter == self and ball.shot_kind == "dunk" and ball.shot_made
		view_dunk_slam.emit(v_dunk_style, BIG_DUNK_STYLES.has(v_dunk_style) or v_turbo_dunk)
	if _v_was_air and not air:
		if _v_air_kind == "dunk" and _v_slam and not hb:
			_v_rim_t = RIM_HANG_TIME
			_v_rim_spot = position
			game.stat("anim_rim_hangs")
		else:
			_v2_land(_v_air_kind)
	_v_was_air = air
	if _v_rim_t >= 0.0:
		_v_rim_t -= delta
		if hb or air:
			_v_rim_t = -1.0
		elif _v_rim_t < 0.0 or position.distance_to(_v_rim_spot) > RIM_HANG_MAX_MOVE_FT * game.FT:
			_v_rim_t = -1.0
			_v_drop_t = DUNK_DROP_TIME
	elif _v_drop_t >= 0.0:
		_v_drop_t -= delta
		if hb or air:
			_v_drop_t = -1.0
		elif _v_drop_t < 0.0:
			_v2_land("dunk")
	v_land_t = maxf(0.0, v_land_t - delta)
	if hb and not _v_had_ball and not air and _v_ball_prev == ball.PASS:
		_v_catch_t = _v2_time_from("catch", 0)
	_v_had_ball = hb
	_v_ball_prev = ball.state
	_v_catch_t = maxf(0.0, _v_catch_t - delta) if hb else 0.0
	if stumble_t > _v_stumble_prev:
		_v_stumble_len = stumble_t
	if _v_fall and stumble_t <= 0.0 and _v_stumble_prev > 0.0:
		_v_getup_t = FALL_GETUP_TIME
		game.stat("anim_falls")
	_v_stumble_prev = stumble_t
	if _v_getup_t >= 0.0:
		_v_getup_t -= delta
		if _v_getup_t < 0.0 or air or poke_t > 0.0:
			_v_getup_t = -1.0
			_v_fall = false
	if _v_fall and stumble_t <= 0.0 and _v_getup_t < 0.0:
		_v_fall = false

	# the animation: x = frame position from a progress, or < 0 for the clock (x rate)
	var anim := "idle"
	var x := -1.0
	var rate := 1.0
	var loop := true
	var start := 0.0              # clock-driven one-shots: seconds into the animation they start at
	if rim_kind != "":
		var f: float = clampf(jump_t / maxf(jump_time, 0.01), 0.0, 1.0)
		if rim_kind == "dunk":
			anim = Sheets.resolve(fmt, v_dunk_style if v_dunk_style != "" else "dunk_two")
			var n: int = Sheets.anim_frames(fmt, anim)
			var rel: int = Sheets.anim_event(fmt, anim, "release", n >> 1)
			var rim: int = maxi(rel, Sheets.anim_event(fmt, anim, "rim", rel + 1))
			var hang: int = clampi(Sheets.anim_event(fmt, anim, "hang", rel - 1), 0, rel)
			var tk: int = clampi(Sheets.anim_event(fmt, anim, "takeoff", 0), 0, hang)
			var hang_f: float = DUNK_HANG_F
			var anchors: Array = [[0.0, tk]]
			if alley_oop:
				var cf: int = clampi(Sheets.anim_event(fmt, anim, "catch", hang), tk, hang)
				anchors.append([ALLEY_CATCH_F, cf])
				hang_f = (ALLEY_CATCH_F + DUNK_RELEASE) / 2.0
			anchors.append([hang_f, hang])
			anchors.append([DUNK_RELEASE, rel])
			anchors.append([minf(1.0, DUNK_RELEASE + DUNK_RIM_REACH_F), rim])
			anchors.append([1.0, float(rim) + 0.5])
			x = _v2_anchor_x(anchors, f)
		else:
			anim = Sheets.resolve(fmt, "layup")
			var n2: int = Sheets.anim_frames(fmt, anim)
			var rel2: int = Sheets.anim_event(fmt, anim, "release", n2 >> 1)
			var tk2: int = clampi(Sheets.anim_event(fmt, anim, "takeoff", 0), 0, rel2)
			var ld: int = clampi(Sheets.anim_event(fmt, anim, "land", n2 - 1), rel2, n2 - 1)
			x = _v2_anchor_x([[0.0, tk2], [LAYUP_RELEASE, rel2], [1.0, float(ld) - 0.001]], f)
	elif block_jump_t >= 0.0:
		anim = Sheets.resolve(fmt, "block")
		var nb: int = Sheets.anim_frames(fmt, anim)
		var sw: int = Sheets.anim_event(fmt, anim, "swat", nb >> 1)
		var tkb: int = clampi(Sheets.anim_event(fmt, anim, "takeoff", 0), 0, sw)
		# the swat frame at the top of the jump (block_height_frac's peak)
		x = _v2_anchor_x([[0.0, tkb], [0.5, sw], [1.0, float(nb) - 0.001]], clampf(block_jump_t / BLOCK_JUMP_TIME, 0.0, 1.0))
	elif fake_t > 0.0:
		anim = Sheets.resolve(fmt, "shoot")
		var top: int = mini(PUMP_TOP_FRAME, maxi(0, Sheets.anim_event(fmt, anim, "release", 1) - 1))
		var g: float = clampf(1.0 - fake_t / PUMP_TIME, 0.0, 1.0)
		x = (1.0 - absf(2.0 * g - 1.0)) * float(top)
	elif shooting:
		anim = Sheets.resolve(fmt, _v2_shot_anim())   # jumper or free throw: gather and rise through the windup / meter
		var fs := 0.0
		if game.is_human(self):
			fs = shot_charge
		else:
			fs = shot_elapsed / maxf(shot_elapsed + maxf(cpu_shot_time, 0.0), 0.01)
		x = clampf(fs, 0.0, 0.999) * float(maxi(1, Sheets.anim_event(fmt, anim, "release", 3)))
	elif _v_follow_t > 0.0:
		anim = Sheets.resolve(fmt, _v2_shot_anim())   # release, then the follow-through
		var r0: int = Sheets.anim_event(fmt, anim, "release", 0)
		var tot: float = _v2_time_from(anim, r0)
		x = _v2_clock_x(anim, _v2_time_from(anim, 0) - minf(_v_follow_t, tot), false)
	elif _v_rim_t >= 0.0 and not hb:
		anim = Sheets.resolve(fmt, "rim_hang")
		x = _v2_clock_x(anim, RIM_HANG_TIME - _v_rim_t, Sheets.anim_loops(fmt, anim))
	elif _v_drop_t >= 0.0 and not hb:
		anim = Sheets.resolve(fmt, v_dunk_style if v_dunk_style != "" else "dunk_two")
		var nd: int = Sheets.anim_frames(fmt, anim)
		var rimd: int = Sheets.anim_event(fmt, anim, "rim", nd - 2)
		x = float(mini(rimd + 1, nd - 1))
	elif poke_t > 0.0:
		anim = "steal"
		loop = false
	elif _v_fall and (stumble_t > 0.0 or _v_getup_t >= 0.0):
		anim = Sheets.resolve(fmt, "fall")   # ankle-breaker: down through the stumble, then up
		var nf: int = Sheets.anim_frames(fmt, anim)
		var gu: int = clampi(Sheets.anim_event(fmt, anim, "getup", nf - 1), 1, nf - 1)
		if stumble_t > 0.0:
			x = (1.0 - stumble_t / maxf(_v_stumble_len, 0.01)) * float(gu) * 0.999
		else:
			x = float(gu) + (1.0 - _v_getup_t / FALL_GETUP_TIME) * float(nf - gu) * 0.999
	elif stumble_t > 0.0:
		anim = Sheets.resolve(fmt, "stumble")
		if Sheets.anim_fps(fmt, anim) > 0.0:
			loop = Sheets.anim_loops(fmt, anim)
		else:
			x = (1.0 - stumble_t / maxf(_v_stumble_len, 0.01)) * float(Sheets.anim_frames(fmt, anim)) * 0.999
	elif _v_pass_t > 0.0:
		anim = _v_pass_kind
		loop = false
		start = _v2_time_from(anim, 0) - _v2_time_from(anim, Sheets.anim_event(fmt, anim, "release", 0))
	elif v_land_t > 0.0:
		anim = "land"
		loop = false
	elif (_v_celebrate_t > 0.0 and spd < CELEBRATE_MAX_SPEED) or _won_game():
		anim = "celebrate_b" if _v_celebrate_b or _won_game() else "celebrate_a"
	elif hb and at_free_throw():
		anim = "hold"
	elif hb:
		if _v_catch_t > 0.0:
			anim = "catch"
			loop = false
		elif cross_t > 0.0 or absf(hand_x) < 0.999:
			# the crossover (or a slow switch of hands): "cross" ends in the left hand, "cross_l" in the right;
			# a mirrored frame shows the other hand, so the mirrored version is the other one
			anim = "cross_l" if (dribble_side > 0.0) != flip else "cross"
			var pc: float = 1.0 - cross_t / CROSS_TIME if cross_t > 0.0 else (1.0 + hand_x * dribble_side) / 2.0
			x = clampf(pc, 0.0, 0.999) * float(Sheets.anim_frames(fmt, Sheets.resolve(fmt, anim)))
		else:
			# locked to the sim's dribble: the ball is on the floor on the "floor" frame when the sim's bounce is
			var was_run: bool = _v_anim.begins_with("run_dribble")
			var frac: float = RUN_DRIBBLE_FRAC + (-RUN_DRIBBLE_HYST if was_run else RUN_DRIBBLE_HYST)
			anim = "run_dribble" if spd > frac * speed else "dribble"
			if (dribble_side < 0.0) != flip:
				anim += "_l"
			var p: float = ball.dribble_phase() if ball.has_method("dribble_phase") else 0.0
			x = _v2_phase_x(Sheets.resolve(fmt, anim), p)
	elif slide_to != Vector2.ZERO:
		anim = "slide"   # drawn stepping to his left; played backwards for his right (mirrored: the other way)
		var left := Vector2.from_angle(face - PI / 2.0)
		var way: float = 1.0 if velocity.dot(left) >= 0.0 else -1.0
		if flip:
			way = -way
		rate = way * maxf(V2_RUN_RATE_MIN, spd / maxf(SLIDE_FULL_FRAC * speed, 1.0))
	elif spd > RUN_MIN_SPEED:
		anim = "run"
		rate = maxf(V2_RUN_RATE_MIN, spd / maxf(speed, 1.0))
	var res: String = Sheets.resolve(fmt, anim)
	if anim != _v_anim:
		_v_anim = anim
		_v_clock = start
		if anim in ["slide", "steal", "catch", "land", "cross", "cross_l", "run_dribble", "run_dribble_l", "fall", "hold"]:
			game.stat("anim_" + anim)
	else:
		_v_clock += delta * rate
	if x < 0.0:
		x = _v2_clock_x(res, _v_clock, loop and Sheets.anim_loops(fmt, res))
	var n_frames: int = Sheets.anim_frames(fmt, res)
	var k: int = floori(x)
	v_frame_frac = clampf(x - float(k), 0.0, 1.0)
	k = posmod(k, n_frames) if Sheets.anim_loops(fmt, res) else clampi(k, 0, n_frames - 1)
	v_anim = res
	v_flip = flip
	v_frame = Sheets.frame_index(fmt, row, res, k)
	v_next_frame = Sheets.frame_index(fmt, row, res, k + 1)
	var reg: Dictionary = Sheets.frame_region(_v_sheet_data, v_frame)
	if not reg.is_empty() and reg["texture"] != null:
		_v_spr.texture = reg["texture"]
		_v_spr.region_rect = reg["region"]
	_v_spr.flip_h = flip
	# crossover: lean into the cut, easing out over the burst (as v1)
	var lean := 0.0
	if cross_t > 0.0 and cross_dir.length() > 0.1:
		var sx: float = (View.to_screen(position + cross_dir * game.FT) - View.to_screen(position)).x
		lean = deg_to_rad(CROSS_LEAN_DEG) * signf(sx) * cross_t / CROSS_TIME
	_v_spr.rotation = lean
	_v_lift = _v2_lift(delta)

# The drawn lift (Q7 a, visual only; the sim's jump_t, jump_z, DUNK_RELEASE and block windows are untouched). A dunk
# rises to the hang frame with the hands over the rim, hangs there, slams on the release frame with the hands at the
# rim, stays on the rim while the sim comes down and RIM_HANG_TIME after (a made dunk), then drops. Everything else
# is the sim's jump_z.
func _v2_lift(delta: float) -> float:
	var rim_z: float = View.RIM_Z
	if rim_kind == "dunk":
		var f: float = clampf(jump_t / maxf(jump_time, 0.01), 0.0, 1.0)
		var row_base: int = v_frame - posmod(v_frame, Sheets.cols(_v_fmt))
		var st: int = int(((_v_fmt.get("anims", {}) as Dictionary).get(v_anim, {}) as Dictionary).get("start", 0))
		var rel: int = Sheets.anim_event(_v_fmt, v_anim, "release", 0)
		var hang: int = Sheets.anim_event(_v_fmt, v_anim, "hang", maxi(0, rel - 1))
		var top: float = maxf(0.0, rim_z + DUNK_HANG_ABOVE - _v2_hand_h(row_base + st + hang))
		var at_rel: float = maxf(0.0, rim_z + DUNK_RIM_GRIP - _v2_hand_h(row_base + st + rel))
		var hang_f: float = (ALLEY_CATCH_F + DUNK_RELEASE) / 2.0 if alley_oop else DUNK_HANG_F
		var lift := 0.0
		if f < hang_f:
			lift = top * sin(PI / 2.0 * f / hang_f)
		elif f < DUNK_RELEASE:
			lift = lerpf(top, at_rel, smoothstep(0.0, 1.0, (f - hang_f) / maxf(DUNK_RELEASE - hang_f, 0.01)))
		elif _v_slam:
			var hold: float = maxf(0.0, rim_z + DUNK_RIM_GRIP - _v2_hand_h(v_frame))
			lift = lerpf(_v_lift, hold, 1.0 - exp(-LIFT_FOLLOW * delta))
		else:
			var q: float = (f - DUNK_RELEASE) / maxf(1.0 - DUNK_RELEASE, 0.01)   # missed or blocked: come down
			lift = at_rel * (1.0 - q * q)
		_v_hold_lift = lift
		return lift
	if _v_rim_t >= 0.0 and v_anim != "" and not has_ball():
		var hold2: float = maxf(0.0, rim_z + DUNK_RIM_GRIP - _v2_hand_h(v_frame))
		_v_hold_lift = lerpf(_v_hold_lift, hold2, 1.0 - exp(-LIFT_FOLLOW * delta))
		return _v_hold_lift
	if _v_drop_t >= 0.0 and not has_ball():
		var p: float = 1.0 - clampf(_v_drop_t / DUNK_DROP_TIME, 0.0, 1.0)
		return _v_hold_lift * (1.0 - p * p)
	return jump_z

# test only (-- --texmem, xvfb): the video memory once the game has drawn for a while
func _v2_texmem() -> void:
	if _v_texmem_frames < 0:
		return
	_v_texmem_frames += 1
	if _v_texmem_frames == 120:
		_v_texmem_frames = -1
		var tex_mb: float = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
		var vid_mb: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
		var ids: Array = []
		for p in game.players:
			ids.append("%s(v%d%s)" % [p._v_sheet_id if p._v_sheet_id != "" else "kenney",
					p._v_ver, ",indexed" if bool(p._v_sheet_data.get("indexed", false)) else ""])
		print("TEXMEM texture %.1f MB, video %.1f MB, players %s" % [tex_mb, vid_mb, ", ".join(ids)])

# ---------------- motion effects (P6-23, Q7 "medium"; visual only) ----------------
# These read the sim state and the view's events and never write the sim: squash and stretch of the drawn sprite
# around its feet point on take-off and landing, dust (sand, splash) at the feet on hard cuts and landings, and a
# camera punch (fx.punch) on a made big dunk. Nothing here uses the game's random numbers.

const SQ_UP_TIME := 0.13          # seconds of the take-off stretch
const SQ_DOWN_TIME := 0.16        # seconds of the landing squash
const SQ_ATTACK := 0.25           # fraction of either spent reaching the full amount (then eased back to 1)
const SQ_UP_AMP := {"dunk": 0.11, "layup": 0.08, "block": 0.07}    # take-off: taller by this (board: at most ~12%)
const SQ_DOWN_AMP := {"dunk": 0.12, "layup": 0.09, "block": 0.08}  # landing: shorter by this
const SQ_WIDE := 0.6              # the width changes by this x the height change, the other way (keeps the volume)
const SQ_SLAM_AMP := 0.05         # a made dunk's slam: a short stretch as the arms snap down on the rim
const DUST_LAND := {"dunk": 0.95, "layup": 0.6, "block": 0.55}     # landing puff strength (fx.foot_dust 0..1)
const DUST_TAKEOFF := 0.4         # a dunk's or layup's take-off kicks up a small puff
const CUT_DEG := 75.0             # a hard cut: the run turns this far off where he was heading ...
const CUT_MIN_FRAC := 0.6         # ... at this fraction of top speed or more
const CUT_DIR_FOLLOW := 8.0       # 1/s: "where he was heading" follows the run this fast (a smoothed direction)
const CUT_COOLDOWN := 0.35        # seconds between two cut puffs of one player
const DUST_CUT := 0.5             # a cut's puff strength (on turbo: DUST_CUT_TURBO)
const DUST_CUT_TURBO := 0.75
const DUST_CROSS := 0.6           # the crossover burst start
const DUST_STUMBLE := 0.45        # a beaten defender stumbling (an ankle-breaker: DUST_FALL)
const DUST_FALL := 0.8
const PUNCH_STRENGTH := 1.0       # fx.punch strength on a made big dunk (turbo, alley-oop, windmill, tomahawk)

var _fx_sq_t := -1.0              # seconds into the current squash / stretch (< 0: none)
var _fx_sq_time := 0.1
var _fx_sq_amp := 0.0             # > 0: stretch (taller), < 0: squash (shorter)
var _fx_dir := Vector2.ZERO       # smoothed run direction (ZERO while standing)
var _fx_cut_cd := 0.0
var _fx_was_cross := false
var _fx_was_slide := false
var _fx_stumble_prev := 0.0
var _fx_was_air := false          # v1 event tracking (v2 emits the events in _update_sheet_frame_v2)
var _fx_air_kind := ""
var _fx_rel_seen := false

func _fx_start(amp: float, time: float) -> void:
	# a new pulse never cuts a stronger one short
	if _fx_sq_t >= 0.0 and absf(_fx_sq_amp) * _fx_env() > absf(amp):
		return
	_fx_sq_t = 0.0
	_fx_sq_time = time
	_fx_sq_amp = amp

func _fx_env() -> float:
	if _fx_sq_t < 0.0:
		return 0.0
	var u: float = clampf(_fx_sq_t / maxf(_fx_sq_time, 0.01), 0.0, 1.0)
	if u < SQ_ATTACK:
		return smoothstep(0.0, 1.0, u / SQ_ATTACK)
	var v: float = (u - SQ_ATTACK) / (1.0 - SQ_ATTACK)
	return (1.0 - v) * (1.0 - v)

# the sprite scale multiplier this frame (Vector2.ONE at rest); the sprite's origin is the feet point
func _fx_squash(delta: float) -> Vector2:
	if _fx_sq_t < 0.0:
		return Vector2.ONE
	var e: float = _fx_env()
	_fx_sq_t += delta
	if _fx_sq_t >= _fx_sq_time:
		_fx_sq_t = -1.0
	var h: float = _fx_sq_amp * e
	return Vector2(1.0 - SQ_WIDE * h, 1.0 + h)

func _fx_dust(strength: float, dir: Vector2 = Vector2.ZERO) -> void:
	if game.fx != null and game.fx.has_method("foot_dust"):
		game.fx.foot_dust(position, strength, dir)

func _fx_on_takeoff(kind: String) -> void:
	_fx_start(float(SQ_UP_AMP.get(kind, 0.07)), SQ_UP_TIME)
	game.stat("fx_stretches")
	if kind == "dunk" or kind == "layup":
		_fx_dust(DUST_TAKEOFF)

func _fx_on_landed(kind: String) -> void:
	_fx_start(-float(SQ_DOWN_AMP.get(kind, 0.08)), SQ_DOWN_TIME)
	game.stat("fx_squashes")
	_fx_dust(float(DUST_LAND.get(kind, 0.5)))

func _fx_on_slam(_style: String, big: bool) -> void:
	var ball = game.ball
	var made: bool = ball.state == ball.SHOT and ball.shooter == self and ball.shot_kind == "dunk" and ball.shot_made
	if not made:
		return
	_fx_start(SQ_SLAM_AMP, SQ_UP_TIME)
	if big and game.fx != null and game.fx.has_method("punch"):
		game.fx.punch(PUNCH_STRENGTH)

# v1 sheets (and the fallback) have no frame picker events: the same take-off, slam and landing, seen from the sim
func _fx_v1_events() -> void:
	var air: bool = is_airborne()
	if air and not _fx_was_air:
		_fx_air_kind = "block" if block_jump_t >= 0.0 else rim_kind
		_fx_rel_seen = false
		v_turbo_dunk = rim_kind == "dunk" and (turbo or since_turbo < TURBO_DUNK_WINDOW)
		view_takeoff.emit(_fx_air_kind)
	if rim_kind == "dunk" and jump_released and not _fx_rel_seen:
		_fx_rel_seen = true
		view_dunk_slam.emit("", alley_oop or v_turbo_dunk)
	if _fx_was_air and not air:
		view_landed.emit(_fx_air_kind)
	_fx_was_air = air

# dust at the feet on hard cuts (a sharp turn at speed, the crossover burst, a wet slide starting) and stumbles
func _fx_cuts(delta: float) -> void:
	_fx_cut_cd = maxf(0.0, _fx_cut_cd - delta)
	var air: bool = is_airborne()
	var spd: float = velocity.length()
	var crossing: bool = cross_t > 0.0
	if crossing and not _fx_was_cross and not air:
		_fx_dust(DUST_CROSS, cross_dir)
		_fx_cut_cd = CUT_COOLDOWN
		game.stat("dust_cuts")
	_fx_was_cross = crossing
	if sliding and not _fx_was_slide and not air:
		_fx_dust(DUST_CUT_TURBO, velocity)
		_fx_cut_cd = CUT_COOLDOWN
		game.stat("dust_cuts")
	_fx_was_slide = sliding
	if stumble_t > _fx_stumble_prev and not air:
		_fx_dust(DUST_FALL if _v_fall else DUST_STUMBLE)
	_fx_stumble_prev = stumble_t
	if air or spd <= RUN_MIN_SPEED:
		_fx_dir = Vector2.ZERO
		return
	var now: Vector2 = velocity / spd
	if _fx_dir == Vector2.ZERO:
		_fx_dir = now
		return
	if _fx_cut_cd <= 0.0 and spd >= CUT_MIN_FRAC * speed and absf(now.angle_to(_fx_dir)) > deg_to_rad(CUT_DEG):
		_fx_dust(DUST_CUT_TURBO if turbo else DUST_CUT, now)
		_fx_cut_cd = CUT_COOLDOWN
		_fx_dir = now
		game.stat("dust_cuts")
		return
	var d: Vector2 = _fx_dir.lerp(now, 1.0 - exp(-CUT_DIR_FOLLOW * delta))
	_fx_dir = d.normalized() if d.length() > 0.01 else now
