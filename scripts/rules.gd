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
const FIRST_BALL_TEAM := 0           # BLUE has the first ball (to confirm at the Phase 3 check-in)
const POINTS_INSIDE := 1             # streetball scoring: a basket inside the arc ...
const POINTS_BEYOND := 2             # ... and beyond it (game.is_three() means "beyond the arc")
const POINTS_FT := 1                 # a free throw (P3-05)
const MADE_WAIT := 1.0               # dead-ball pause after a made basket
const START_MSG_TIME := 1.5          # "FIRST TO 21" at tip-off
const INBOUND_BACK_FT := 3.5         # inbound spot: this far behind the hoop the team defends ...
const INBOUND_SIDE_FT := 5.0         # ... and this far to one side

var game
var target := TARGET_SCORE
var switch_at := SWITCH_AT
var sides_swapped := false           # false: team 0 attacks the right hoop. Read through game.attack_hoop() only
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

# one basket (a 2) away from winning
func is_game_point(team: int) -> bool:
	if game.game_over or _winner() >= 0:
		return false
	var s: int = game.score[team] + POINTS_BEYOND
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
			if pending_inbound >= 0:
				inbound(pending_inbound, pending_spot)
			pending_inbound = -1
			pending_spot = Vector2.INF
		return true
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
	pending_inbound = next_team
	pending_spot = spot
	dead_timer = wait
	game.shot_clock_running = false

# inbound from `spot`, or (Vector2.INF) from the baseline under the hoop this team defends
func inbound(team: int, spot := Vector2.INF) -> void:
	var own: Vector2 = game.attack_hoop(1 - team)
	var dir: float = game.inward(own)
	if spot == Vector2.INF:
		spot = Vector2(own.x - dir * INBOUND_BACK_FT * game.FT, own.y + INBOUND_SIDE_FT * game.FT)
	var best = game.teams[team][0]
	var best_d := INF
	for p in game.teams[team]:
		var d: float = p.position.distance_to(spot)
		if d < best_d:
			best_d = d
			best = p
	best.position = game.clamp_to_court(spot)
	game.give_ball(best)

# ---------------- game start ----------------

func start_game() -> void:
	game.reset_positions(FIRST_BALL_TEAM)
	game.give_ball(game.teams[FIRST_BALL_TEAM][0])
	game.show_message("FIRST TO %d" % target, START_MSG_TIME)
