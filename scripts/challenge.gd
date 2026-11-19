extends Node
# Challenge goals (P9-13, board "Shared contract: Challenge goals"). main.gd adds one when Flow.match.challenge is not
# empty (a Legends challenge game; never in Quick Game, the Road Trip or a finale), after start_game():
#   challenge = ChallengeScript.new(); challenge.game = self; challenge.data = Flow.match.challenge
#   add_child(challenge); challenge.start(hud_root)
# The goal types and their numbers come from the legend's challenge row (legends_data.gd, CHALLENGE_TYPES):
#   hold      win while the legend scores fewer than "limit" points (his "limit"th point ends the game: failed)
#   fire      the legend starts on fire and cools only after "cool_misses" misses in a row; win
#   stop      block or steal on the legend "count" times (any of your 3) and win; a win with fewer: failed
#   race      reach the game's target before his team reaches "their_target" (that ends the game: failed)
#   comeback  the game starts at "start_score" [you, them]; win
# A HUD line under the top bar shows the goal and its count ("HOLD STEEPLE UNDER 6: 3"); a broken goal ends the game
# at once as a loss (main.end_challenge(false)), the line then says "CHALLENGE FAILED: <why>". The verdict
# (verdict(), {"type", "met", "why"}) goes to Flow.last_result["challenge"] when the game ends (main.on_game_over), so
# Flow.game_finished() hands it to Legends.record_result().
# main.gd calls: count_points(p, pts) before rules.add_score (the scorer's points), check() after it (a broken goal
# ends the game), on_stop(defender, victim, kind) on a block or steal, fire_misses(p, default) in on_shot_missed.
# Drawing only on the HUD; the only sim changes are the start (start score, the legend on fire) and the end.
# Test: -- --autoplay --challenge <legend id> prints "CHALLENGE <id> <level> met|failed <score> | ..." (main.gd).

const LegendsData = preload("res://scripts/legends_data.gd")

# ---------------------------------------------------------------------------------------------------- tuning
const LINE_TOP := 56.0              # screen px: top of the goal line (just under the 54 px HUD bar)
const LINE_H := 30.0                # its height
const LINE_W := 720.0               # its width (centered: 280..1000 at 1280, clear of the clock, the shot clock and
                                    # the pause button; the joystick and A / B are at the bottom)
const LINE_SIZE := 22               # font size
const LINE_COLOR := Color(1.0, 0.86, 0.45)       # the goal
const LINE_FLASH_COLOR := Color(1.0, 1.0, 1.0)   # the count just changed
const LINE_MET_COLOR := Color(0.55, 1.0, 0.55)   # CHALLENGE MET
const LINE_FAIL_COLOR := Color(1.0, 0.42, 0.38)  # CHALLENGE FAILED
const LINE_BG := Color(0.0, 0.0, 0.0, 0.5)
const LINE_FLASH_TIME := 0.6        # seconds the line flashes after its count changes
const FT_LABEL_TOP := 90.0          # in a challenge game main.gd's "FREE THROW 1 OF 2" line moves under the goal line
const FIRE_POPUP_RISE := 5.0        # ft over the legend's head for the "ON FIRE!" popup at tip-off
const DEFAULT_COOL_MISSES := 2      # fire: when the row has no cool_misses (= main.FIRE_MISSES)

var game                            # main.gd
var data := {}                      # Flow.match.challenge: {"type", "legend", "name", "target", ...the type's numbers}
var type := ""
var legend_id := ""
var legend_name := ""
var legend = null                   # his player node (team 1)
var limit := 0                      # hold
var count := 0                      # stop
var their_target := 0               # race
var start_score: Array = [0, 0]     # comeback
var cool_misses := DEFAULT_COOL_MISSES   # fire
var legend_points := 0              # his points this game (free throws too)
var stops := 0                      # blocks and steals on him by your side
var cooled := false                 # fire: he cooled down at least once
var broken := ""                    # why the goal broke ("" = not broken)
var _ended := false
var _label: Label
var _bg: ColorRect
var _flash := 0.0
var _final := ""                    # the verdict line once the game is over
var _final_met := false

func _num(k: String, d: int) -> int:
	var v = data.get(k, d)
	return int(v) if (v is int or v is float) else d

# after main.start_game(): find the legend, apply the start (score, fire) and build the HUD line on `root`
func start(root: Control) -> void:
	type = str(data.get("type", ""))
	legend_id = str(data.get("legend", ""))
	legend_name = str(data.get("name", LegendsData.legend(legend_id).get("name", legend_id)))
	limit = _num("limit", 0)
	count = _num("count", 0)
	their_target = _num("their_target", 0)
	cool_misses = maxi(1, _num("cool_misses", DEFAULT_COOL_MISSES))
	var ss = data.get("start_score", [0, 0])
	if ss is Array and (ss as Array).size() == 2:
		start_score = [int(ss[0]), int(ss[1])]
	for p in game.teams[1]:
		if str(p.pid) == legend_id:
			legend = p
	if legend == null and not game.teams[1].is_empty():
		legend = game.teams[1][0]   # the match puts the legend first
	match type:
		"comeback":
			# the start score: set before any basket, like a game picked up at that score (rules.gd still decides
			# the win and the side switch from game.score)
			game.score[0] = int(start_score[0])
			game.score[1] = int(start_score[1])
		"fire":
			if legend != null:
				legend.on_fire = true
				legend.make_streak = game.FIRE_STREAK
				legend.fire_misses = 0
				game.stat("challenge_fire_starts")
	game.stat("challenge_" + type)
	if root != null:
		_build_line(root)
	_refresh()

func _build_line(root: Control) -> void:
	_bg = ColorRect.new()
	_bg.color = LINE_BG
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_bg.offset_left = -LINE_W / 2.0
	_bg.offset_right = LINE_W / 2.0
	_bg.offset_top = LINE_TOP
	_bg.offset_bottom = LINE_TOP + LINE_H
	root.add_child(_bg)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.clip_text = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ls := LabelSettings.new()
	ls.font_size = LINE_SIZE
	ls.outline_size = 5
	ls.outline_color = Color(0, 0, 0, 0.85)
	_label.label_settings = ls
	_bg.add_child(_label)

# the tip-off popup over the legend (fire), once the countdown is over (main.gd calls it with the twist banner)
func show_start() -> void:
	if type == "fire" and legend != null and legend.on_fire:
		game.fx.popup("ON FIRE!", legend.position + Vector2(0, -FIRE_POPUP_RISE * game.FT), game.FIRE_COLOR,
				game.FIRE_POPUP_SIZE)
		game.audio.play("fire")

# the goal line as it reads now
func line_text() -> String:
	match type:
		"hold":
			return "HOLD %s UNDER %d: %d" % [legend_name, limit, legend_points]
		"fire":
			var hot: bool = legend != null and legend.on_fire
			return "%s IS %s: WIN TO %d" % [legend_name, "ON FIRE" if hot else "COOLED", int(game.rules.target)]
		"stop":
			return "BLOCK OR STEAL ON %s: %d/%d" % [legend_name, stops, count]
		"race":
			return "REACH %d BEFORE %s'S CREW GETS %d" % [int(game.rules.target), legend_name, their_target]
		"comeback":
			return "COME BACK FROM %d-%d: WIN TO %d" % [int(start_score[0]), int(start_score[1]), int(game.rules.target)]
	return str(data.get("line", ""))

func _refresh() -> void:
	if _label == null:
		return
	_label.text = _final if _final != "" else line_text()

func _process(delta: float) -> void:
	if _bg == null:
		return
	if _final == "":
		_refresh()   # the fire state and the scores change without a call
	if _flash > 0.0:
		_flash -= delta
	if _final != "":
		_label.modulate = LINE_MET_COLOR if _final_met else LINE_FAIL_COLOR
	else:
		_label.modulate = LINE_FLASH_COLOR if _flash > 0.0 else LINE_COLOR
	# the twist's banner slides in over this spot for its first seconds (twist_fx.gd): the line waits under it
	var banner = game.twist_fx.get("_banner_t") if game.twist_fx != null else null
	_bg.visible = not (banner != null and float(banner) >= 0.0) or _final != ""

# ---------------------------------------------------------------------------------------------------- main.gd hooks

# a basket or free throw by p is about to be added (before rules.add_score, so a game-ending point is counted)
func count_points(p, pts: int) -> void:
	if p == null or p != legend:
		return
	legend_points += pts
	game.stat_add("challenge_legend_points", pts)
	if type == "hold":
		_flash = LINE_FLASH_TIME

# after rules.add_score: a broken goal ends the game at once as a loss
func check() -> void:
	if _ended or game.game_over:
		return
	var why: String = _broken_now()
	if why != "":
		broken = why
		game.stat("challenge_broken")
		_ended = true
		game.end_challenge(false)

# a block or a steal by `defender` on `victim` (kind "block" / "steal")
func on_stop(defender, victim, kind: String) -> void:
	if type != "stop" or defender == null or victim == null or victim != legend or defender.team == legend.team:
		return
	stops += 1
	game.stat("challenge_stops")
	game.stat("challenge_stop_%ss" % kind)
	_flash = LINE_FLASH_TIME

# fire: the misses in a row that put the legend's fire out (main.on_shot_missed); else `fallback`
func fire_misses(p, fallback: int) -> int:
	if type == "fire" and p != null and p == legend:
		return cool_misses
	return fallback

# fire: the legend cooled down (main._end_fire)
func on_fire_out(p) -> void:
	if type == "fire" and p != null and p == legend and not game.game_over and not cooled:
		cooled = true
		game.stat("challenge_fire_cooled")

func _broken_now() -> String:
	match type:
		"hold":
			if legend_points >= limit:
				return "%s SCORED %d" % [legend_name, legend_points]
		"race":
			if int(game.score[1]) >= their_target:
				return "%s'S CREW GOT %d" % [legend_name, their_target]
	return ""


# {"type", "met", "why"} for a game that ended with this winner (0 = your side). Also fixes the HUD line's verdict.
func verdict(winner: int) -> Dictionary:
	var why: String = broken if broken != "" else _broken_now()
	if why == "" and winner != 0:
		why = "LOST %d-%d" % [int(game.score[0]), int(game.score[1])]
	if why == "" and type == "stop" and stops < count:
		why = "ONLY %d OF %d STOPS ON %s" % [stops, count, legend_name]   # won the game, but not the goal
	var met: bool = winner == 0 and why == ""
	if broken == "" and why != "":
		broken = why
	_final_met = met
	_final = "CHALLENGE MET!" if met else "CHALLENGE FAILED: " + why
	_flash = 0.0
	_refresh()
	return {"type": type, "met": met, "why": why}

# the extra numbers of the test line (main.gd's CHALLENGE line)
func summary() -> String:
	match type:
		"hold":
			return "hold: %s %d pts (limit %d)" % [legend_id, legend_points, limit]
		"fire":
			return "fire: %s %d pts, cooled %s (after %d misses in a row)" % [legend_id, legend_points, str(cooled),
					cool_misses]
		"stop":
			return "stop: %d/%d on %s (blocks %d, steals %d), he scored %d" % [stops, count, legend_id,
					int(game.stats.get("challenge_stop_blocks", 0)), int(game.stats.get("challenge_stop_steals", 0)),
					legend_points]
		"race":
			return "race: to %d before %d" % [int(game.rules.target), their_target]
		"comeback":
			return "comeback: from %d-%d" % [int(start_score[0]), int(start_score[1])]
	return type
