extends Node
# Road Trip Hoops: the rules (P3-01). Owns the format (first to TARGET_SCORE, 1s and 2s), every change of the score,
# the win check, the side switch (P3-02), dead balls and inbounds. main.gd keeps the loop, the HUD, input routing,
# steals, the shot clock and the humantest script. Created in main._ready() as game.rules.
#
# Pending owner choices (docs/BOARD.md Q1, Q2): each is a constant set to the recommended option.

const TARGET_SCORE := 21             # first team to this many points wins (Q1). Test override: --target N
const WIN_BY := 1                    # Q1 a: 1 (21-20 wins). Q1 b: 2 (play on until someone leads by 2)
const GAME_TIME_CAP := 0.0           # Q1 c: seconds of live play before the team ahead wins (tied: next basket wins).
                                     # 0 = no time limit (Q1 a, b)
const SWITCH_AT := 11                # the first basket that brings a team to this switches sides (once per game).
                                     # With --target N it is (N + 1) / 2
const SWITCH_PAUSE := 2.0            # seconds the game stops for "SWITCH SIDES" (after the made basket's pause)
const FIRST_BALL_TEAM := 0           # BLUE has the first ball (to confirm at the Phase 3 check-in)
const POINTS_INSIDE := 1             # streetball scoring: a basket inside the arc ...
const POINTS_BEYOND := 2             # ... and beyond it (game.is_three() means "beyond the arc")
const POINTS_FT := 1                 # a free throw (P3-05)
const MADE_WAIT := 1.0               # dead-ball pause after a made basket
const START_MSG_TIME := 1.5          # "FIRST TO 21" at tip-off
const INBOUND_BACK_FT := 3.5         # inbound spot: this far behind the hoop the team defends ...
const INBOUND_SIDE_FT := 5.0         # ... and this far to one side (mirrored by attack direction: B1)
const GAME_POINT_BASKET := POINTS_INSIDE   # GAME POINT shows when a basket worth this much wins (1: from 20 of 21;
                                     # POINTS_BEYOND would show it from 19, but 2s are rare)

# fouls and free throws (P3-05, owner Q3/Q4: bad timing only; 1 FT inside the arc, 2 beyond, and-one 1, reaching =
# sideline ball, a missed last FT is a live rebound). Who commits fouls: defense.gd (P3-06; reach fouls too, P3-09).
const FT_INSIDE := 1                 # free throws for a missed shot fouled inside the arc ...
const FT_BEYOND := 2                 # ... and beyond it
const FT_AND_ONE := 1                # a made shot that was fouled
const FT_VALUE_MODE := "one_each"    # "one_each": FT_INSIDE/FT_BEYOND shots worth 1 each (Q4 a); "shot_value": one
                                     # free throw worth the shot's value (Q4 b)
const BONUS_FOULS := 0               # > 0: from this many team fouls on, reaching fouls give FT_INSIDE free throws
                                     # (Q4 c); 0 = off
const FOUL_WAIT := 1.2               # dead-ball pause after a reaching foul ("FOUL!"), then the sideline inbound
const FOUL_MIN_CLOCK := 10.0         # after a reaching foul the shot clock keeps running, but is at least this
const FOUL_SIDELINE_INSET_FT := 6.0  # sideline inbound spot: x is the ball's, kept this far from the baselines
const PENDING_FOUL_MAX := 2.0        # a shooting foul before the release waits this long for the shot to go up
const FT_LINE_FT := 13.75            # free-throw line: this far from the hoop center
const FT_LANE_LOW_FT := 3.5          # lane spots: this far in front of the hoop (defenders) ...
const FT_LANE_HIGH_FT := 8.0         # ... and this far (the shooter's teammates)
const FT_LANE_SIDE_FT := 9.5         # ... this far to each side of the hoop line (just outside the 16 ft key)
const FT_ARC_FT := 27.0              # the defender left over stands behind the arc, this far from the hoop
const FT_ARRIVE_FT := 1.5            # a player this close to his spot has arrived
const FT_WALK_MAX := 3.0             # seconds players may take to walk to their spots; then they are placed there
const FT_SETUP_TIME := 1.0           # seconds everyone stands set before the shooter gets the ball
const FT_HUMAN_WAIT := 10.0          # a human at the line who doesn't shoot within this shoots at quality 1.0
const FT_CPU_FORCE_WAIT := 4.0       # safety: a CPU shooter who hasn't started within this shoots at quality 1.0
const FT_AIR_MAX := 3.0              # safety: a free throw "in the air" this long without a result counts as missed
const SWITCH_SKIPS_FT_REBOUND := false # a missed last free throw while the side switch waits: no live rebound, the
                                     # defense gets the ball after "SWITCH SIDES" (false: live rebound, the switch waits
                                     # for the next dead ball)

# out of bounds (P3-07, owner Q5: simple, only a loose ball crossing a line is out; ball.gd calls ball_out)
const OOB_WAIT := 1.2                # dead-ball pause after "OUT OF BOUNDS"
const OOB_SIDELINE_INSET_FT := 6.0   # sideline inbound: x is where it went out, kept this far from the baselines
const OOB_BASELINE_KEY_FT := 9.5     # baseline inbound: at least this far to the side of the hoop (outside the 16 ft
                                     # key, so it never sits under the basket where made-basket inbounds start)
const OOB_CORNER_FT := 4.0           # ... and this far from the sidelines
const OOB_MIN_CLOCK := 5.0           # the team that had the ball keeps it: the shot clock runs on, but is at least this
const OOB_CLEAR_FT := 6.0            # opponents closer than this to the inbounder are moved back to this distance

var game
var target := TARGET_SCORE
var switch_at := SWITCH_AT
var sides_swapped := false           # false: team 0 attacks the right hoop. Read through game.attack_hoop() only
var switched := false                # the switch happened (or is pending) this game
var pending_switch := false          # a basket reached switch_at: switch when the dead ball pause ends
var dead_timer := 0.0
var pending_inbound := -1            # team that gets the ball when the dead ball pause ends
var pending_spot := Vector2.INF
var play_time := 0.0                 # all game time, dead-ball pauses included
var live_time := 0.0                 # game time with the ball live (GAME_TIME_CAP counts this)
var dead_time := 0.0
var time_up := false                 # GAME_TIME_CAP ran out with the score tied: the next basket wins
var _leader := -1                    # last team that led (ties don't reset it): lead_changes
var _game_point := [false, false]
var _poss_team := -1

# fouls (P3-05)
var team_fouls := [0, 0]
var pending_foul := false            # a shooting foul waits for the shot's result (made: and-one, missed: free throws)
var _pf_shooter = null
var _pf_beyond := false
var _pf_t := 0.0
var _clock_after_inbound := -1.0     # reaching foul: the shot clock value to restore after the inbound
var _clear_inbound := false          # out of bounds: move defenders off the inbounder when the pause ends
# free throws (P3-05; shared contract: ft_active, ft_shooter, ft_left, ft_spot(), ft_released())
var ft_active := false               # players stand at ft_spot(); false again once the last free throw leaves the hand
var ft_shooter = null
var ft_left := 0                     # free throws still to shoot (the one in the air no longer counts)
var ft_total := 0
var ft_cur := 0                      # 1-based number of the current free throw (HUD)
var ft_value := 1                    # points per made free throw
var ft_and_one := false
var ft_phase := ""                   # "", "walk", "setup", "shoot" (shooter has the ball), "air"
var ft_ready := false                # the shooter has the ball and may shoot
var ft_shot_live := false            # a free throw is in the air (main.on_shot_made / on_shot_missed -> ft_result)
var ft_hoop := Vector2.ZERO
var _ft_timer := 0.0
var _ft_order := {}                  # player -> lineup slot name

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--target")
	if i >= 0 and i + 1 < args.size() and args[i + 1].is_valid_int():
		target = maxi(1, args[i + 1].to_int())
		switch_at = floori((target + 1) / 2.0)

# ---------------- scoring ----------------

# 2 beyond the arc, else 1 (dunks and layups are inside). Free throws use POINTS_FT.
func points_for(shooter, hoop: Vector2) -> int:
	return POINTS_BEYOND if game.is_three(shooter.position, hoop) else POINTS_INSIDE

# the only place game.score changes. kind: "shot", "dunk", "layup", "ft"
func add_score(team: int, pts: int, kind: String) -> void:
	if game.game_over:
		return
	game.score[team] += pts
	game.stat("points%d_t%d" % [pts, team])
	var right: bool = game.attack_hoop(team).x > game.COURT_W / 2
	game.stat_add("points_%s_hoop" % ("right" if right else "left"), pts)
	game.stat_add("points_%s_hoop_t%d" % ["right" if right else "left", team], pts)
	game.stat_add("points_half%d_t%d" % [2 if sides_swapped else 1, team], pts)
	game.stat_add("points_%s_t%d" % [kind, team], pts)
	_track_lead()
	for t in 2:
		var gp: bool = is_game_point(t)
		if gp and not _game_point[t]:
			game.stat("game_points")
		_game_point[t] = gp
	var w: int = _winner()
	if w >= 0:
		_end_game(w)
		return
	if not switched and game.score[team] >= switch_at:
		switched = true
		pending_switch = true

# one basket (worth GAME_POINT_BASKET) away from winning
func is_game_point(team: int) -> bool:
	if game.game_over or _winner() >= 0:
		return false
	var s: int = game.score[team] + GAME_POINT_BASKET
	return s >= target and s - game.score[1 - team] >= WIN_BY

func _winner() -> int:
	for t in 2:
		var lead: int = game.score[t] - game.score[1 - t]
		if game.score[t] >= target and lead >= WIN_BY:
			return t
		if time_up and lead > 0:
			return t
	return -1

func _track_lead() -> void:
	var d: int = game.score[0] - game.score[1]
	if d == 0:
		return
	var now: int = 0 if d > 0 else 1
	if _leader >= 0 and now != _leader:
		game.stat("lead_changes")
	_leader = now

func _end_game(winner: int) -> void:
	game.stats["game_seconds"] = int(play_time)
	game.stats["dead_seconds"] = int(dead_time)
	game.on_game_over(winner)

# a team gained the ball (main.on_ball_held)
func on_possession(team: int) -> void:
	if team != _poss_team:
		_poss_team = team
		game.stat("possessions_t%d" % team)

# ---------------- clock, dead balls and inbounds ----------------

# called every frame by main before play updates. Returns true while the ball is dead (pause running).
func update(delta: float) -> bool:
	if game.game_over:
		return true
	play_time += delta
	if dead_timer > 0.0:
		dead_time += delta
		dead_timer -= delta
		if dead_timer <= 0.0:
			if pending_switch:
				_switch_sides()
				return true
			if pending_inbound >= 0:
				inbound(pending_inbound, pending_spot)
			pending_inbound = -1
			pending_spot = Vector2.INF
		return true
	if ft_phase != "":
		_update_ft(delta)
		return true
	if pending_foul:
		_update_pending_foul(delta)
	live_time += delta
	if GAME_TIME_CAP > 0.0 and not time_up and live_time >= GAME_TIME_CAP and game.ball.state != game.ball.SHOT:
		time_up = true
		var w: int = _winner()
		if w >= 0:
			_end_game(w)
			return true
		game.show_message("TIME! NEXT BASKET WINS", 1.5)
	return false

# seconds of the time limit left (GAME_TIME_CAP > 0), for the HUD
func time_left() -> float:
	return maxf(GAME_TIME_CAP - live_time, 0.0)

func dead_ball(next_team: int, wait: float, spot := Vector2.INF) -> void:
	game.ball.make_dead()
	_clear_inbound = false
	pending_inbound = next_team
	pending_spot = spot
	dead_timer = wait
	game.shot_clock_running = false

# inbound from `spot`, or (Vector2.INF) from the baseline under the hoop this team defends, on the side mirrored by
# the attack direction so both halves play the same (B1)
func inbound(team: int, spot := Vector2.INF) -> void:
	var own: Vector2 = game.attack_hoop(1 - team)
	var dir: float = game.inward(own)
	if spot == Vector2.INF:
		spot = Vector2(own.x - dir * INBOUND_BACK_FT * game.FT, own.y + dir * INBOUND_SIDE_FT * game.FT)
	var best = game.teams[team][0]
	var best_d := INF
	for p in game.teams[team]:
		var d: float = p.position.distance_to(spot)
		if d < best_d:
			best_d = d
			best = p
	best.position = game.clamp_to_court(spot)
	if _clear_inbound:
		_clear_inbound = false
		_clear_around(best)
	game.give_ball(best)
	if _clock_after_inbound >= 0.0:
		game.shot_clock = _clock_after_inbound   # reaching foul: the clock kept running (at least FOUL_MIN_CLOCK)
		_clock_after_inbound = -1.0

# ---------------- out of bounds (P3-07) ----------------

# ball.gd: a loose ball crossed a sideline or baseline at `pos`; `last_team` touched it last (-1: unknown, then the
# team that had possession counts). The other team inbounds near where it went out. Returns false if the call is
# ignored (dead ball, free throws, game over); ball.gd then bounces it back in.
func ball_out(pos: Vector2, last_team: int) -> bool:
	if game.game_over or dead_timer > 0.0 or ft_phase != "" or game.ball.state != game.ball.LOOSE:
		return false
	if pending_foul and _pf_shooter != null:
		resolve_pending_foul(_pf_shooter, false)   # a fouled shooter lost it out: his free throws first
		return true
	var W: float = game.COURT_W
	var H: float = game.COURT_H
	if last_team < 0:
		last_team = game.possession
	var team: int = 1 - last_team
	# which line: the one it is further past (a corner counts for the baseline on a tie)
	var past_x: float = maxf(-pos.x, pos.x - W)
	var past_y: float = maxf(-pos.y, pos.y - H)
	var baseline: bool = past_x >= past_y
	var spot: Vector2
	if baseline:
		var key: float = OOB_BASELINE_KEY_FT * game.FT
		var cy: float = H / 2.0
		var y: float = clampf(pos.y, OOB_CORNER_FT * game.FT, H - OOB_CORNER_FT * game.FT)
		if absf(y - cy) < key:
			y = cy + (key if y >= cy else -key)
		spot = Vector2(10.0 if pos.x < W / 2.0 else W - 10.0, y)
	else:
		var inset: float = OOB_SIDELINE_INSET_FT * game.FT
		spot = Vector2(clampf(pos.x, inset, W - inset), 10.0 if pos.y < H / 2.0 else H - 10.0)
	# shot clock: kept (at least OOB_MIN_CLOCK) when the team that had it keeps it and no shot hit the rim
	var cause: String = String(game.ball.loose_cause)
	var keep: bool = team == game.possession and cause != "rebound"
	_clock_after_inbound = maxf(game.shot_clock, OOB_MIN_CLOCK) if keep else -1.0
	game.stat("out_of_bounds")
	game.stat("oob_t%d" % team)
	game.stat("oob_baseline" if baseline else "oob_sideline")
	if cause != "":
		game.stat("oob_after_" + cause)
	if keep:
		game.stat("oob_clock_kept")
	if game.audio:
		game.audio.play("whistle")
	game.show_message("OUT OF BOUNDS\n%s BALL" % game.TEAM_NAMES[team], OOB_WAIT, game.TEAM_COLORS[team])
	if game.autoplay or game.humantest:
		print("OUT OF BOUNDS %s (%s, after %s) at x %d y %d: %s ball" % ["baseline" if baseline else "sideline",
				game.TEAM_NAMES[last_team], cause, int(pos.x / game.FT), int(pos.y / game.FT), game.TEAM_NAMES[team]])
	for p in game.players:
		p.shooting = false
	game.possession = team
	dead_ball(team, OOB_WAIT, spot)
	_clear_inbound = true
	return true

# out-of-bounds inbound: opponents right on top of the inbounder step back to OOB_CLEAR_FT (toward the court)
func _clear_around(inbounder) -> void:
	var r: float = OOB_CLEAR_FT * game.FT
	var center := Vector2(game.COURT_W / 2.0, game.COURT_H / 2.0)
	for o in game.teams[1 - inbounder.team]:
		var off: Vector2 = o.position - inbounder.position
		if off.length() >= r:
			continue
		var dir: Vector2 = off.normalized() if off.length() > 1.0 else (center - inbounder.position).normalized()
		if dir.dot(center - inbounder.position) < 0.0:
			dir = (center - inbounder.position).normalized()   # never pushed off the court
		o.position = game.clamp_to_court(inbounder.position + dir * r)
		o.velocity = Vector2.ZERO

# ---------------- game start and the side switch ----------------

func start_game() -> void:
	# CPU-vs-CPU test games pick the first ball at random so balance tests aren't tilted by it (about +0.25 points)
	var first: int = game.rng.randi() % 2 if game.autoplay else FIRST_BALL_TEAM
	game.reset_positions(first)
	game.give_ball(game.teams[first][0])
	game.show_message("FIRST TO %d" % target, START_MSG_TIME)

# P3-02: after the made basket's pause, stop SWITCH_PAUSE s, whistle, flip the hoops and line both teams up on their
# new halves; then the team that was scored on inbounds as usual
func _switch_sides() -> void:
	pending_switch = false
	sides_swapped = not sides_swapped
	game.stat("side_switches")
	game.audio.play("whistle")
	game.show_message("SWITCH SIDES", SWITCH_PAUSE)
	var team: int = pending_inbound if pending_inbound >= 0 else game.possession
	game.reset_positions(team)
	game.ball.position = Vector2(game.COURT_W / 2, game.COURT_H / 2)   # the camera follows the ball: show both halves
	game.ball.z = 0.0
	dead_timer = SWITCH_PAUSE
	if game.autoplay or game.humantest:
		print("SWITCH SIDES at BLUE %d - RED %d" % [game.score[0], game.score[1]])

# ---------------- fouls (P3-05) ----------------

# A foul by `defender` on `fouled`. kind "shooting" (a badly timed block jump that reached the shooter), "reach"
# (a poke at a shielded ball) or "drive" (Q3 c, treated like a reach). Ignored while the ball is dead, during free
# throws, or while another shooting foul waits for its shot. Returns true if the foul was called.
func call_foul(defender, fouled, kind: String) -> bool:
	if game.game_over or defender == null or fouled == null or defender.team == fouled.team:
		return false
	if ft_phase != "" or pending_foul or dead_timer > 0.0 or game.ball.state == game.ball.DEAD:
		return false
	team_fouls[defender.team] += 1
	game.stat("fouls_t%d" % defender.team)
	game.stat("fouls_%s" % kind)
	if game.is_human(defender):
		game.stat("human_fouls")
	if game.is_human(fouled):
		game.stat("human_fouled")
	game.audio.play("whistle")
	game.fx.popup("FOUL!", defender.position + Vector2(0, -5.0 * game.FT), game.TEAM_COLORS[defender.team], 40)
	var what: String = "ON THE SHOT" if kind == "shooting" else "REACHING"
	game.show_message("FOUL ON %s\n%s" % [game.TEAM_NAMES[defender.team], what], 1.2, game.TEAM_COLORS[defender.team])
	if game.autoplay or game.humantest:
		print("FOUL %s by %s at BLUE %d - RED %d" % [kind, game.TEAM_NAMES[defender.team], game.score[0], game.score[1]])
	if kind == "shooting":
		pending_foul = true
		_pf_shooter = fouled
		_pf_beyond = game.is_three(fouled.position, game.attack_hoop(fouled.team))
		_pf_t = 0.0
		if not _pf_shot_coming():
			resolve_pending_foul(fouled, false)   # not in a shot after all: free throws now
		return true
	# reaching: the fouled team keeps the ball, from the sideline at the ball's x (or free throws in the bonus)
	if BONUS_FOULS > 0 and team_fouls[defender.team] >= BONUS_FOULS:
		game.stat("bonus_free_throws")
		start_free_throws(fouled, FT_INSIDE, POINTS_FT, false)
		return true
	var side_y: float = 10.0 if game.ball.position.y < game.COURT_H / 2 else game.COURT_H - 10.0
	var inset: float = FOUL_SIDELINE_INSET_FT * game.FT
	var spot := Vector2(clampf(game.ball.position.x, inset, game.COURT_W - inset), side_y)
	_clock_after_inbound = maxf(game.shot_clock, FOUL_MIN_CLOCK)
	fouled.shooting = false
	game.possession = fouled.team
	dead_ball(fouled.team, FOUL_WAIT, spot)
	return true

# the fouled shooter's shot is in the air, or he is still in his shot (windup, rim move, pump fake)
func _pf_shot_coming() -> bool:
	var b = game.ball
	var p = _pf_shooter
	if b.state == b.SHOT and b.shooter == p:
		return true
	if not p.has_ball():
		return false
	return p.shooting or p.rim_kind != "" or ("fake_t" in p and p.fake_t > 0.0)

func _update_pending_foul(delta: float) -> void:
	_pf_t += delta
	var b = game.ball
	if b.state == b.SHOT and b.shooter == _pf_shooter:
		return   # main.on_shot_made / on_shot_missed resolve it when the shot lands
	if not _pf_shot_coming() or _pf_t >= PENDING_FOUL_MAX:
		resolve_pending_foul(_pf_shooter, false)   # no shot went up (stolen, held too long): free throws

# main.on_shot_made / on_shot_missed: the fouled shot's result. Returns true if it started free throws.
func resolve_pending_foul(shooter, made: bool) -> bool:
	if not pending_foul or shooter != _pf_shooter:
		return false
	pending_foul = false
	_pf_shooter = null
	if game.game_over:
		return false
	if made:
		game.stat("and_ones")
		game.show_message("AND ONE!", 1.0, game.TEAM_COLORS[shooter.team])
		start_free_throws(shooter, FT_AND_ONE, POINTS_FT, true)
	else:
		var pts: int = POINTS_BEYOND if _pf_beyond else POINTS_INSIDE
		if FT_VALUE_MODE == "shot_value":
			start_free_throws(shooter, 1, pts, false)
		else:
			start_free_throws(shooter, FT_BEYOND if _pf_beyond else FT_INSIDE, POINTS_FT, false)
	return true

# ---------------- free throws (P3-05) ----------------

func start_free_throws(shooter, count: int, value: int, and_one: bool) -> void:
	var b = game.ball
	b.make_dead()
	dead_timer = 0.0
	pending_inbound = -1
	pending_spot = Vector2.INF
	ft_active = true
	ft_shooter = shooter
	ft_left = count
	ft_total = count
	ft_cur = 1
	ft_value = value
	ft_and_one = and_one
	ft_ready = false
	ft_shot_live = false
	ft_hoop = game.attack_hoop(shooter.team)
	ft_phase = "walk"
	_ft_timer = 0.0
	game.shot_clock_running = false
	game.possession = shooter.team
	_ft_lineup()
	b.position = ft_spot(shooter)
	if shooter.team == game.HUMAN_TEAM and not game.autoplay:
		game.human_player = shooter   # the human shoots BLUE's free throws with the shot meter
	if "call_t" in game.input:
		game.input.call_t = -1.0
	game.stat("ft_trips")

# player.gd runs the free-throw behavior itself (P3-06: at_free_throw, ft_stand). main.gd still asks; its ft_walk
# fallback branch is never taken and can go with main.gd's next owner.
func ft_native() -> bool:
	return true

# lane slots: the defenders take the low spots (one per side) and the arc, the shooter's teammates the high spots
func _ft_lineup() -> void:
	_ft_order = {}
	_ft_order[ft_shooter] = "line"
	var mates: Array = []
	for p in game.teams[ft_shooter.team]:
		if p != ft_shooter:
			mates.append(p)
	var defs: Array = game.teams[1 - ft_shooter.team].duplicate()
	var hoop: Vector2 = ft_hoop
	defs.sort_custom(func(a, c): return a.position.distance_to(hoop) < c.position.distance_to(hoop))
	var low := ["low_a", "low_b", "arc"]
	for i in defs.size():
		_ft_order[defs[i]] = low[mini(i, 2)]
	var high := ["high_b", "high_a"]
	for i in mates.size():
		_ft_order[mates[i]] = high[mini(i, 1)]

# where each player stands during free throws (shared contract). Not in a free throw: where he is.
func ft_spot(p) -> Vector2:
	if ft_shooter == null or not _ft_order.has(p):
		return p.position
	var dir: float = game.inward(ft_hoop)
	var off := Vector2(FT_ARC_FT, 0.0)
	match String(_ft_order[p]):
		"line":
			off = Vector2(FT_LINE_FT, 0.0)
		"low_a":
			off = Vector2(FT_LANE_LOW_FT, -FT_LANE_SIDE_FT)
		"low_b":
			off = Vector2(FT_LANE_LOW_FT, FT_LANE_SIDE_FT)
		"high_a":
			off = Vector2(FT_LANE_HIGH_FT, -FT_LANE_SIDE_FT)
		"high_b":
			off = Vector2(FT_LANE_HIGH_FT, FT_LANE_SIDE_FT)
	return ft_hoop + off * dir * game.FT

func _all_at_spots() -> bool:
	for p in game.players:
		if p.position.distance_to(ft_spot(p)) > FT_ARRIVE_FT * game.FT:
			return false
	return true

func _snap_spots() -> void:
	for p in game.players:
		p.position = ft_spot(p)
		p.velocity = Vector2.ZERO

func _update_ft(delta: float) -> void:
	_ft_timer += delta
	var b = game.ball
	match ft_phase:
		"walk":
			if _all_at_spots() or _ft_timer >= FT_WALK_MAX:
				_snap_spots()
				ft_phase = "setup"
				_ft_timer = 0.0
		"setup":
			if _ft_timer >= FT_SETUP_TIME:
				_snap_spots()
				ft_phase = "shoot"
				_ft_timer = 0.0
				ft_ready = true
				ft_shooter.shooting = false
				game.give_ball(ft_shooter)
				game.shot_clock_running = false
		"shoot":
			if not ft_shooter.has_ball():
				if b.state != b.SHOT:
					game.give_ball(ft_shooter)   # safety: the ball always comes back to the line
					game.shot_clock_running = false
				return
			var human: bool = game.is_human(ft_shooter)
			if not ft_shooter.shooting and _ft_timer >= (FT_HUMAN_WAIT if human else FT_CPU_FORCE_WAIT):
				game.stat("ft_timeouts")
				game.release_shot(ft_shooter, 1.0)
		"air":
			if _ft_timer >= FT_AIR_MAX and b.state != b.SHOT:
				ft_result(false)   # safety: no result came back

# main.release_shot: the shooter let go of a free throw. The last one releases everyone (live rebound on a miss).
func ft_released() -> void:
	ft_left -= 1
	ft_ready = false
	ft_phase = "air"
	_ft_timer = 0.0
	ft_shot_live = true
	if ft_left <= 0:
		ft_active = false

# main.on_shot_made / on_shot_missed: the free throw in the air landed
func ft_result(made: bool) -> void:
	if ft_phase != "air":
		return
	ft_shot_live = false
	var team: int = ft_shooter.team
	if made:
		game.stat("free_throw_makes")
		game.stat("ft_makes_t%d" % team)
		if game.is_human(ft_shooter):
			game.stat("human_ft_makes")
		add_score(team, ft_value, "ft")
		if game.game_over:
			_end_ft()
			return
	if ft_left > 0:
		game.ball.make_dead()   # next free throw: back to the line after the setup pause
		ft_phase = "setup"
		_ft_timer = 0.0
		ft_cur += 1
		return
	_end_ft()
	if made:
		game.possession = 1 - team
		dead_ball(1 - team, MADE_WAIT)   # like a made basket: the other team from its baseline
	else:
		game.stat("ft_last_misses")      # live rebound: ball.gd already bounced it off the rim
		if pending_switch and SWITCH_SKIPS_FT_REBOUND:
			# the switch would wait a possession or more: the defense gets the ball now, after "SWITCH SIDES"
			game.stat("switch_after_ft_miss")
			game.possession = 1 - team
			dead_ball(1 - team, MADE_WAIT)

func _end_ft() -> void:
	ft_active = false
	ft_phase = ""
	ft_ready = false
	ft_shot_live = false
	ft_shooter = null
	ft_left = 0
	_ft_order = {}

# HUD line while free throws are on ("" otherwise)
func ft_hud_text() -> String:
	if ft_phase == "":
		return ""
	if ft_and_one:
		return "AND ONE: FREE THROW"
	if ft_total <= 1:
		return "FREE THROW"
	return "FREE THROW %d OF %d" % [ft_cur, ft_total]
