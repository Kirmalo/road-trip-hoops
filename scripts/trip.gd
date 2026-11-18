extends RefCounted
# The Road Trip: progress, rules and the next match (P5-05, board "Match config" and "Save format"). Static only,
# used through preload (state lives in static vars, so it survives reload_current_scene(); the save is the truth on
# launch):
#   const Trip = preload("res://scripts/trip.gd")
#   Trip.new_trip("normal")            # the title's NEW TRIP (after its confirmation): fresh trip, saved
#   if Trip.continue_trip(): Flow.go(Trip.resume_screen())   # CONTINUE (false = no save / broken save)
#   Trip.match_for()                   # lineup PLAY: builds Flow.match for the current game, then Flow.go("game")
#   Trip.record_result(Flow.last_result)   # flow.gd calls it after a trip game; then Trip.after_result() says where to go
#
# Owner rules (docs/VISION.md, board "Owner answers"):
#   - each city has one crew, played 3 times: game 1 = 1 good + 2 average, game 2 = 2 good + 1 average,
#     game 3 = 2 good + the boss (crew_for_game); targets 11 / 15 / 21 (cities.gd game_target)
#   - win all 3 to move on; a loss just retries that game (no penalty)
#   - Phase 8 (P8-08): every win pays each of the 3 starters his own points (POINTS_CITY_GAME for city games 1-2,
#     POINTS_BOSS_GAME for the boss game and each New York round), each game once per trip ("paid"); the bench gets
#     nothing. Crew points (a 1.0.0 save's pool + its catch-up) go to anyone. Each point +3 on one stat of one
#     player; no stat above 90; spent on the STAT POINTS screen after every win, from the lineup / map between games,
#     after each city and between New York rounds (SPEND_PHASES)
#   - Phase 8 (P8-11): every win records the game's stars (Stars.record(key, level): best kept, in the settings file);
#     a 1.0.0 save gets its won games' stars at its level once (stars section key V1_STAR_MARK)
#   - after a city: recruit ONE of its 2 good players or the boss (he keeps his ratings, wears your colors)
#   - roster = the 3 underdogs + recruits + drafted players (P8-14: one per star slot, Stars.slots(), from any crew
#     beaten on this trip; final for the trip; see draft()); 3 starters picked before each game (remembered); starter
#     0 = you
#   - level (easy / normal / hard, legend once the stars open it) picked at trip start, changeable (set_level)
#   - fixed route (cities.gd ROUTE), cities with "built": false are skipped
#   - Phase 8 (P8-17): replays (start_replay): any game won on this trip (a city game, a New York round), from the map
#     between games or after the trip; the opponents at the stage reached (stage_reached()), stars only (no points,
#     story, recruit, unlocks or record); the trip's city, game, bracket and phase never move; the "replay" marker
#     (saved) makes CONTINUE open that replay's lineup; after the result, the map. A finished trip resumes on the map.
#   - opponents' ratings: city_ratings() at the stage, + Difficulty.rating_bonus(level) (LEGEND), each stat <= BOSS_CAP
#   - New York tournament: 3 rounds, all to 21; a loss replays that round
# Phases (where CONTINUE resumes): "map" (next game from the map), "win_points" (the STAT POINTS screen after a won
# city game 1 or 2; CONTINUE opens "points", DONE goes on to the next game), "points" (spend after a city),
# "recruit", "bracket" (New York), "done" (trip complete; CONTINUE opens the map, for replays).
# The flow after a win (after_result): city game 1-2 -> points -> lineup; a boss game -> the city's "won" story ->
# points -> recruit; a New York round -> points -> bracket; the final -> story "ending" -> title; a replay -> map.
# Test: godot --headless --path . -- --triptest-data           prints every city game's lineups + save checks,
#       godot --headless --path . -- --triptest-data --load    (a second process) loads that save and compares.
# Both use user://trip_test.json (save.gd), never the owner's save.
# Phase 6 (P6-10): match_for() adds the city's "twist"; a city look or track that doesn't exist yet falls back to the
# city's "fallback" look / music; --expected-roster (with --city) plays a city game with the crew a trip would have
# there (expected_roster()), --best-roster the strongest legal three (best_roster(), P8-21); a won boss game unlocks the city's court for Quick Game (P6-17, Difficulty.unlock_court)
# and its crew as a Quick Game team (P6-T3, Difficulty.unlock_team; a New York crew when its round is won).
# quick_team(crew_id) builds such a team for main.gd.
# Save version 2 (P8-08, board "Save"): each roster entry has "pts" (his unspent points) and "via" (start / recruit /
# draft); the trip has "crew_points", "paid" (game keys, Stars.key) and "replay" ({} or {"city", "game"}); "points"
# is still written (the total of all unspent points) so a 1.0.0 build reads it as its shared pool. A version 1 save
# migrates on load (from_dict): its pool + the catch-up become crew points, every game already won is paid, "via"
# comes from the player data.
# One boss in the starting three (P8-14b, owner: VISION "Phase 8 boss limit"): at most BOSS_LIMIT boss (tier "boss",
# is_boss()) among the 3 starters, however he joined (recruited or drafted). set_starters() refuses more
# (starters_ok() says why), so no screen or test gets around it. A save of any version with more boss starters is
# repaired on load (_repair_bosses): the first boss stays, the others are swapped for the strongest non-boss bench
# players (rating sum), boss_repair lists who went to the bench (the lineup's one-line note) and CONTINUE saves at once.

const Flow = preload("res://scripts/flow.gd")
const Cities = preload("res://scripts/cities.gd")
const Ratings = preload("res://scripts/ratings.gd")
const Save = preload("res://scripts/save.gd")
const Stars = preload("res://scripts/stars.gd")            # key(city, n): the "paid" game keys ("chicago:2")
const Looks = preload("res://scripts/court_looks.gd")      # which look ids exist (city look or its fallback)
const StoryText = preload("res://scripts/story_text.gd")   # the data check: every scene a city names exists
const DIFFICULTY_PATH := "res://scripts/difficulty.gd"     # loaded at call time: unlock_court() (P6-17) if it exists
const MUSIC_DIR := "res://assets/music/"                   # <music>.ogg (audio.gd); missing = the city's fallback
const EXPECTED_ROSTER_FLAG := "--expected-roster"          # test flag (with --city): the crew a trip would have there
const REPLAY_LABEL := "REPLAY - "   # P8-17: in front of a replay's match label ("REPLAY - CHICAGO - GAME 2 OF 3")

const LEVELS := ["easy", "normal", "hard", "legend"]   # difficulty.gd NAMES + legend (P8: opened by 72 stars)
const DEFAULT_LEVEL := "normal"     # a trip with no level given; also the --city test matches
const POINTS_CITY_GAME := 1         # P8 (owner Q1 a): each starter, city games 1 and 2
const POINTS_BOSS_GAME := 2         # P8: each starter, a city's boss game (game 3) and each New York round
const POINTS_PER_WIN := 2           # 1.0.0's crew pool per win: only award_points()'s default (crew points) now
const CATCHUP_CITY := 6             # a version 1 save: crew points per beaten city (3 x (1 + 1 + 2) - 3 x 2)
const CATCHUP_ROUND := 4            # a version 1 save: crew points per won New York round (3 x 2 - 2)
const CATCHUP_CITY_GAME := 1        # a version 1 save: per won game of the city being played (3 x 1 - 2)
const VIAS := ["start", "recruit", "draft"]   # how a roster player joined (save "via")
const DRAFT_VIA := "draft"          # P8-14: a player drafted into a star slot (drafted_ids(), open_slots())
const RULE_MARK := "rule:per_starter"   # a "seen" entry in every version 2 trip; a 1.0.0 build keeps it when it saves
                                        # (as version 1), so loading that save again gives no second catch-up
const POINT_GAIN := 3               # one point = +3 on one stat
const STAT_CAP := 90                # spending stops at 90 (starting ratings may be higher; they are not lowered)
const BOSS_CAP := 95                # P8-17: no city / New York player stat above this (stage + tier + LEGEND bonus);
                                    # P8-25 tunes it with the ramp
const GAMES_PER_CITY := 3
const STARTERS := 3
const SPEND_PHASES := ["points", "win_points", "map", "bracket", "done"]   # where spend() is allowed: after any win,
                                    # from the lineup / map between games (P8-18's badge), between New York rounds, and
                                    # after the trip (the final's points, for replays)
const REPLAY_PHASES := ["map", "bracket", "done"]   # P8-17: where a replay may start (between games, after the trip;
                                    # never with a points / recruit step pending)
const PHASES := ["map", "win_points", "points", "recruit", "bracket", "done"]
const POINTS_AFTER_EVERY_WIN := true   # P8-11: the STAT POINTS screen after every win (false = 1.0.0: only after a
                                       # city, a won city game 1-2 goes straight to the lineup)
const V1_STAR_MARK := "migrated_v1"    # Stars.SECTION key: a 1.0.0 save's stars were credited (once per settings file)
const STARS_TEST_PATH := "user://trip_stars_selftest.cfg"   # --triptest-data's star checks only, deleted afterwards
const MAX_POINTS := 999             # sanity cap for a loaded save
const QUICK_KINGS := ["ud_jojo", "ud_tank", "ud_deuce"]   # P6-T3: the Kings in Quick Game (today's BLUE slots; Jojo = you)
const QUICK_AVG := 50               # P6-T3: a Quick Game player's five stats average this (50 = today's Quick Game)
const BOSS_LIMIT := 1               # P8-14b (owner): at most this many bosses among the starters
const BOSS_RULE := "ONLY ONE BOSS CAN START"   # starters_ok()'s reason for too many bosses (the lineup shows it)

# --- the trip (static: survives scene reloads) ---
static var active := false          # a trip is loaded (new_trip / continue_trip)
static var level := DEFAULT_LEVEL
static var city := ""               # the city being played (stays the beaten city during points / recruit)
static var game := 1                # 1..3 in a city; in New York = bracket round + 1
static var beaten: Array = []       # city ids, in route order
static var points := 0              # every unspent point: crew_points + each player's "pts" (_sync_points; read-only)
static var crew_points := 0         # points anyone may spend (a 1.0.0 pool + its catch-up; award_points())
static var paid: Array = []         # game keys that have paid their points this trip ("hometown:1", "new_york:2")
static var replay := {}             # {} or {"city", "game"}: a replay in progress (saved; start_replay() sets it,
                                    # record_result() / cancel_replay() clear it)
static var loaded_version := 0      # the save version from_dict() read (0 = a new trip); 1 = migrated from 1.0.0
static var roster_data: Array = []  # [{"id", "ratings": {speed, shooting, finishing, defense, stamina}, "pts": int,
                                    #   "via": "start" | "recruit" | "draft"}]
static var starters: Array = []     # 3 roster ids; the human plays starters[0] (== human)
static var human := ""
static var bracket := {"round": 0}  # New York: rounds won so far (0..3)
static var seen: Array = []         # story scene ids already shown
static var record := {"wins": 0, "losses": 0}
static var phase := "map"
static var last_outcome := {}       # record_result()'s answer, for the result screen (see record_result)
static var _spend_log: Array = []   # [[id, stat, old], ...] this points session, for undo_spend()
static var saving := true           # false = state changes are not written (tests)
static var _star_test := false      # --triptest-data: stars recorded (in STARS_TEST_PATH) while saving is off
static var boss_repair: Array = []  # P8-14b: boss starters the last load benched (ids; [] = none); the lineup's note

# ---------------- starting, continuing, saving ----------------

# A fresh trip at Hometown (the title asks to confirm before calling this over an existing save). Saved at once.
static func new_trip(lv: String = DEFAULT_LEVEL) -> void:
	_reset()
	active = true
	level = lv if LEVELS.has(lv) else DEFAULT_LEVEL
	seen.append(RULE_MARK)
	save()

# Loads the save; true when a trip was loaded. A missing or broken save = false, and the state is left empty.
static func continue_trip() -> bool:
	var d: Dictionary = Save.read()
	if d.is_empty():
		active = false
		return false
	var ok: bool = from_dict(d)
	if ok and loaded_version == 1:
		_credit_v1_stars()
	if ok and (loaded_version < Save.VERSION or not boss_repair.is_empty()):
		save()   # a migrated version 1 save is written as version 2 at once; a repaired lineup too
	return ok

# a valid save exists (the title shows CONTINUE)
static func has_save() -> bool:
	return Save.exists()

# the screen CONTINUE goes to: "map", "points" (also after a won city game: "win_points"), "recruit", "bracket";
# "lineup" while a replay is marked (its match: match_for()); "map" when the trip is done (replays, P8-17); "title"
# without a trip
static func resume_screen() -> String:
	if not active:
		return "title"
	if replaying():
		return "lineup"
	if phase == "done":
		return "map"
	if phase == "win_points":
		return "points"
	return phase

static func is_done() -> bool:
	return active and phase == "done"

static func save() -> bool:
	if not active or not saving:
		return false
	return Save.write(to_dict())

# the level for team 1 in trip games (owner Q4 a: changeable in Settings); saved
static func set_level(lv: String) -> void:
	if not LEVELS.has(lv):
		return
	level = lv
	save()

# "points" is the total (crew + every player's), for a 1.0.0 build (its shared pool); version 2 reads "crew_points"
# and each roster entry's "pts" instead.
static func to_dict() -> Dictionary:
	_sync_points()
	return {
		"level": level, "city": city, "game": game, "beaten": beaten.duplicate(), "points": points,
		"roster": roster_data.duplicate(true), "starters": starters.duplicate(), "human": human,
		"bracket": bracket.duplicate(), "seen": seen.duplicate(), "record": record.duplicate(), "phase": phase,
		"crew_points": crew_points, "paid": paid.duplicate(), "replay": replay.duplicate(),
	}

# Loads a saved dictionary, checking every field (unknown ids dropped, numbers clamped, missing fields = the
# defaults), so an old, newer or hand-edited save still gives a playable trip. False only when it isn't a trip at all.
# Version 1 (1.0.0) migrates: crew points = its pool + CATCHUP_CITY per beaten city + CATCHUP_ROUND per won New York
# round + CATCHUP_CITY_GAME per won game of the city being played; every game already won is paid; nobody has own
# points yet; "via" from the data (the underdogs "start", everyone else "recruit").
static func from_dict(d: Dictionary) -> bool:
	var ver: int = int(d.get("version", 0))
	if ver < 1:
		return false
	if ver > Save.VERSION:
		push_warning("Trip: save version %d is newer than %d; loading what fits" % [ver, Save.VERSION])
	_reset()
	active = true
	loaded_version = ver
	var v1: bool = ver < 2
	var lv: String = str(d.get("level", DEFAULT_LEVEL))
	level = lv if LEVELS.has(lv) else DEFAULT_LEVEL
	# beaten cities, in route order
	var b = d.get("beaten", [])
	if b is Array:
		for id in Cities.ROUTE:
			if (b as Array).has(id):
				beaten.append(id)
	# roster: known players only, once each, ratings clamped; the 3 underdogs are always there
	roster_data = []   # _reset() put the 3 underdogs at their starting ratings in; the save's own come first
	var r = d.get("roster", [])
	if r is Array:
		for e in r:
			if not (e is Dictionary):
				continue
			var id: String = str((e as Dictionary).get("id", ""))
			if Cities.player(id).is_empty() or _on_roster(id):
				continue
			var base: Dictionary = _start_ratings(id)
			var got = (e as Dictionary).get("ratings", {})
			var rt: Dictionary = {}
			for s in Ratings.STATS:
				var v = got.get(s, base[s]) if got is Dictionary else base[s]
				rt[s] = clampi(int(v) if (v is int or v is float) else int(base[s]), Ratings.MIN_RATING, Ratings.MAX_RATING)
			var ne: Dictionary = _new_entry(id)
			ne["ratings"] = rt
			if not v1:
				ne["pts"] = _int_in((e as Dictionary).get("pts", 0), 0, MAX_POINTS)
				var via: String = str((e as Dictionary).get("via", ""))
				if VIAS.has(via) and (via == "start") == (_via_of(id) == "start"):
					ne["via"] = via   # "recruit" or "draft" as saved; "start" only for the underdogs
			roster_data.append(ne)
	for id in Cities.START_CREW:
		if not _on_roster(id):
			roster_data.append(_new_entry(id))
	# starters and the human
	var st = d.get("starters", [])
	var ids: Array = []
	if st is Array:
		for e in st:
			ids.append(str(e))
	ids = _repair_bosses(ids)
	if not set_starters(ids, str(d.get("human", "")), false):
		set_starters(Cities.START_CREW, "", false)
	# where we are
	var c: String = str(d.get("city", ""))
	if not Cities.is_built(c):
		c = _first_unbeaten()
	city = c
	var p: String = str(d.get("phase", "map"))
	phase = p if PHASES.has(p) else "map"
	if (phase == "points" or phase == "recruit") and not beaten.has(city):
		phase = "map"
	if phase == "win_points" and is_tournament(city):
		phase = "bracket"
	if beaten.has(city) and (phase == "map" or phase == "bracket" or phase == "win_points"):
		city = next_city(city)   # a beaten city is never replayed (Q7)
		phase = "map"
	# an older save (Phase 5 had Hometown -> Chicago -> New York) can point past cities added since: go back to the
	# first unbeaten city on today's route, from its first game
	var moved_back := false
	if city != "" and not beaten.has(city):
		var first: String = _first_unbeaten()
		if first != "" and first != city:
			city = first
			phase = "map"
			moved_back = true
	if city == "":
		phase = "done"
	var bd = d.get("bracket", {})
	var br: int = int(bd.get("round", 0)) if bd is Dictionary and not moved_back else 0
	bracket = {"round": clampi(br, 0, _rounds(city).size())}
	var gv = d.get("game", 1) if not moved_back else 1
	game = clampi(int(gv) if (gv is int or gv is float) else 1, 1, GAMES_PER_CITY)
	if is_tournament(city):
		game = clampi(int(bracket["round"]) + 1, 1, maxi(1, _rounds(city).size()))
	var sn = d.get("seen", [])
	if sn is Array:
		for e in sn:
			if not seen.has(str(e)):
				seen.append(str(e))
	var rc = d.get("record", {})
	if rc is Dictionary:
		record = {"wins": maxi(0, int(rc.get("wins", 0))), "losses": maxi(0, int(rc.get("losses", 0)))}
	# points: a version 1 pool becomes crew points (+ the catch-up); version 2 has crew_points and each "pts"
	paid = _won_keys()
	if v1:
		var add: int = _catch_up() if not seen.has(RULE_MARK) else 0   # with the mark: a version 2 trip saved by 1.0.0
		crew_points = clampi(_int_in(d.get("points", 0), 0, MAX_POINTS) + add, 0, MAX_POINTS)
	else:
		crew_points = _int_in(d.get("crew_points", 0), 0, MAX_POINTS)
		var pd = d.get("paid", [])
		if pd is Array:
			for k in pd:
				if Stars.is_key(str(k)) and not paid.has(str(k)):
					paid.append(str(k))
		var rp = d.get("replay", {})
		if rp is Dictionary:
			var rp_city: String = str(rp.get("city", ""))
			var rp_game: int = _int_in(rp.get("game", 0), 0, 99)
			if can_replay(rp_city, rp_game):   # a game won on this trip, between games: else the marker is dropped
				replay = {"city": rp_city, "game": rp_game}
	if not seen.has(RULE_MARK):
		seen.append(RULE_MARK)
	_sync_points()
	return true

static func _reset() -> void:
	active = false
	level = DEFAULT_LEVEL
	city = _first_unbeaten_of([])
	game = 1
	beaten = []
	points = 0
	crew_points = 0
	paid = []
	replay = {}
	loaded_version = 0
	roster_data = []
	for id in Cities.START_CREW:
		roster_data.append(_new_entry(id))
	starters = Cities.START_CREW.duplicate()
	human = str(starters[0])
	bracket = {"round": 0}
	seen = []
	record = {"wins": 0, "losses": 0}
	phase = "map"
	last_outcome = {}
	_spend_log = []
	_slots_override = -1
	boss_repair = []

# a new roster entry: his starting ratings, no points, "via" from the data
static func _new_entry(id: String, via: String = "") -> Dictionary:
	return {"id": id, "ratings": _start_ratings(id), "pts": 0, "via": via if VIAS.has(via) else _via_of(id)}

# how a player joined when the save doesn't say (1.0.0 had no draft): the underdogs "start", a recruitable player
# (a city's good players and boss) "recruit", anyone else "draft" (a version 2 draft that a 1.0.0 build saved again)
static func _via_of(id: String) -> String:
	var p: Dictionary = Cities.player(id)
	if str(p.get("tier", "")) == "start":
		return "start"
	return "recruit" if bool(p.get("recruitable", false)) else "draft"

# a saved number as an int in lo..hi (anything else = lo)
static func _int_in(v, lo: int, hi: int) -> int:
	return clampi(int(v) if (v is int or v is float) else lo, lo, hi)

# the game keys this trip has won (so they have paid): every game of a beaten city, the city being played's games
# before the current one, the New York rounds won
static func _won_keys() -> Array:
	var out: Array = []
	for cid in Cities.ROUTE:
		var n: int = 0
		if is_tournament(cid):
			if beaten.has(cid):
				n = _rounds(cid).size()
			elif cid == city:
				n = bracket_round()
		elif beaten.has(cid):
			n = GAMES_PER_CITY
		elif cid == city:
			n = game - 1
		for i in range(1, n + 1):
			out.append(Stars.key(cid, i))
	return out

# a version 1 save's catch-up (the per-starter rule's extra over 1.0.0's 2 per win), from the loaded progress
static func _catch_up() -> int:
	var add := 0
	for k in _won_keys():
		var cid: String = str(k).get_slice(":", 0)
		if is_tournament(cid):
			add += CATCHUP_ROUND
		elif not beaten.has(cid):
			add += CATCHUP_CITY_GAME   # a beaten city's 3 games are CATCHUP_CITY below
	for cid in beaten:
		if not is_tournament(str(cid)):
			add += CATCHUP_CITY
	return add

# ---------------- route ----------------

# the next built city on the route after `from` ("" = the first); "" at the end of the route
static func next_city(from: String = "") -> String:
	var i: int = Cities.ROUTE.find(from) if from != "" else -1
	for j in range(i + 1, Cities.ROUTE.size()):
		var id: String = Cities.ROUTE[j]
		if Cities.is_built(id):
			return id
	return ""

static func is_tournament(id: String) -> bool:
	return bool(Cities.city(id).get("tournament", false))

static func _rounds(id: String) -> Array:
	var r = Cities.city(id).get("rounds", [])
	return r if r is Array else []

static func _first_unbeaten() -> String:
	return _first_unbeaten_of(beaten)

static func _first_unbeaten_of(done: Array) -> String:
	for id in Cities.built_route():
		if not done.has(id):
			return id
	return ""

# New York: the round being played (0 = quarterfinal); the round names for the bracket screen
static func bracket_round() -> int:
	return int(bracket.get("round", 0))

static func round_names() -> Array:
	var out: Array = []
	for r in _rounds(_tournament_id()):
		out.append(str((r as Dictionary).get("round", "")))
	return out

static func _tournament_id() -> String:
	for id in Cities.ROUTE:
		if is_tournament(id):
			return id
	return ""

# ---------------- players and crews ----------------

# Game n's opponents in a city (PLAYERS ids): 1 = 1 good + 2 average, 2 = 2 good + 1 average, 3 = 2 good + boss.
# In the tournament, n is the round (1..3) and the round's 3 players.
static func crew_for_game(city_id: String, n: int) -> Array:
	var c: Dictionary = Cities.city(city_id)
	if c.get("tournament", false):
		var rs: Array = _rounds(city_id)
		if rs.is_empty():
			return []
		var rd: Dictionary = rs[clampi(n - 1, 0, rs.size() - 1)]
		return (rd.get("players", []) as Array).duplicate()
	var crew: Dictionary = c.get("crew", {})
	var good: Array = crew.get("good", [])
	var avg: Array = crew.get("avg", [])
	var boss: String = str(crew.get("boss", ""))
	if good.size() < 2 or avg.size() < 2 or boss == "":
		return []
	match clampi(n, 1, GAMES_PER_CITY):
		1:
			return [good[0], avg[0], avg[1]]
		2:
			return [good[0], good[1], avg[0]]
	return [good[0], good[1], boss]

# a city player's ratings at a trip stage: STAGE_AVG + TIER.all on every stat, + TIER.spec on his specialties, + the
# level's rating bonus when a level is given (an opponent: Difficulty.rating_bonus, LEGEND_BONUS on LEGEND, else 0;
# "" = none, a recruit or a drafted player), every stat capped at BOSS_CAP
static func city_ratings(id: String, stage: int, lv: String = "") -> Dictionary:
	var p: Dictionary = Cities.player(id)
	var tier: Dictionary = Cities.TIER.get(str(p.get("tier", "avg")), Cities.TIER["avg"])
	var spec: Array = p.get("spec", [])
	var bonus: int = rating_bonus(lv) if lv != "" else 0
	var out: Dictionary = {}
	for s in Ratings.STATS:
		var v: int = Cities.stage_avg(stage) + int(tier.get("all", 0)) + bonus
		if spec.has(s):
			v += int(tier.get("spec", 0))
		out[s] = clampi(v, Ratings.MIN_RATING, mini(BOSS_CAP, Ratings.MAX_RATING))
	return out

# the opponents' rating bonus on a level (difficulty.gd's rating_bonus(): LEGEND_BONUS on legend, else 0; 0 when
# difficulty.gd doesn't have it)
static func rating_bonus(lv: String) -> int:
	if not ResourceLoader.exists(DIFFICULTY_PATH):
		return 0
	var d: GDScript = load(DIFFICULTY_PATH) as GDScript
	if d == null or not d.has_method("rating_bonus"):
		return 0
	return int(d.call("rating_bonus", lv))

# the ratings a player starts with on your roster: the underdogs' own, a recruit's at his city's stage
static func _start_ratings(id: String) -> Dictionary:
	var p: Dictionary = Cities.player(id)
	if str(p.get("tier", "")) == "start":
		var r: Dictionary = p.get("ratings", {})
		var out: Dictionary = {}
		for s in Ratings.STATS:
			out[s] = int(r.get(s, Ratings.AVG_RATING))
		return out
	return city_ratings(id, _stage_of_player(id))

# the stage of the city whose crew a player belongs to (8 for the tournament, 1 if unknown)
static func _stage_of_player(id: String) -> int:
	for cid in Cities.CITIES:
		var c: Dictionary = Cities.CITIES[cid]
		var crew: Dictionary = c.get("crew", {})
		var named: Array = []
		named.append_array(crew.get("good", []))
		named.append_array(crew.get("avg", []))
		named.append(crew.get("boss", ""))
		for r in c.get("rounds", []):
			named.append_array((r as Dictionary).get("players", []))
		if named.has(id):
			return int(c.get("stage", 1))
	return 1

# The match-config player dict (board "Match config" P) plus card info for the screens:
# {"id", "name", "full", "sheet", "role", "number", "tier", "ratings": {5 stats + steal + block}}
static func player_dict(id: String, ratings: Dictionary, for_your_crew: bool) -> Dictionary:
	var p: Dictionary = Cities.player(id)
	var r: Dictionary = {}
	for s in Ratings.STATS:
		r[s] = int(ratings.get(s, Ratings.AVG_RATING))
	r["steal"] = Ratings.derived(int(r["defense"]), int(p.get("steal_bias", 0)))
	r["block"] = Ratings.derived(int(r["defense"]), int(p.get("block_bias", 0)))
	return {"id": id, "name": str(p.get("name", id)), "full": str(p.get("full", p.get("name", id))),
		"sheet": Cities.crew_sheet(id, for_your_crew), "role": str(p.get("role", "")),
		"number": int(p.get("number", 0)), "tier": str(p.get("tier", "")), "ratings": r}

# your roster as player dicts (underdogs first, then recruits in the order they joined)
static func roster() -> Array:
	var out: Array = []
	for e in _roster_or_default():
		out.append(player_dict(str(e["id"]), e["ratings"], true))
	return out

static func roster_ids() -> Array:
	var out: Array = []
	for e in _roster_or_default():
		out.append(str(e["id"]))
	return out

# one roster player's dict, {} if not on the roster
static func roster_player(id: String) -> Dictionary:
	var e: Dictionary = _entry(id)
	return player_dict(id, e["ratings"], true) if not e.is_empty() else {}

static func _roster_or_default() -> Array:
	if active and roster_data.size() > 0:
		return roster_data
	var out: Array = []
	for id in Cities.START_CREW:
		out.append(_new_entry(id))
	return out

static func _entry(id: String) -> Dictionary:
	for e in _roster_or_default():
		if str(e["id"]) == id:
			return e
	return {}

static func _on_roster(id: String) -> bool:
	for e in roster_data:
		if str(e["id"]) == id:
			return true
	return false

# Picks the 3 starters (roster ids, all different, at most BOSS_LIMIT boss); the human plays `who` (one of them;
# "" = the first). Saved. False (nothing changed) when starters_ok() gives a reason.
static func set_starters(ids: Array, who: String = "", do_save: bool = true) -> bool:
	if starters_ok(ids) != "":
		return false
	var picked: Array = []
	for e in ids:
		picked.append(str(e))
	if who == "" or not picked.has(who):
		who = str(picked[0])
	picked.erase(who)
	picked.push_front(who)   # starter 0 = the one you control (match config)
	starters = picked
	human = who
	if do_save:
		save()
	return true

# ---------------- the match ----------------

# Builds the match config (board "Match config") for game n of a city ("" / 0 = the trip's current city and game, or
# the marked replay while replaying()), sets Flow.match to it and returns it. {} for an unknown or not-built city.
# The replay's match (P8-17) has "replay": true, a "REPLAY - " label and the opponents at stage_reached() (never
# below the city's own stage). The opponents get the level's rating bonus (LEGEND), capped at BOSS_CAP. Without a
# loaded trip (the --city tests) your side is the 3 underdogs at their starting ratings, level DEFAULT_LEVEL (or
# --difficulty's, so --city QA runs on LEGEND get the bonus too).
static func match_for(city_id: String = "", n: int = 0) -> Dictionary:
	if city_id == "" and replaying():
		city_id = str(replay["city"])
		n = int(replay["game"])
	if city_id == "":
		city_id = city
	if n <= 0:
		n = game if city_id == city else 1
	var c: Dictionary = Cities.city(city_id)
	if c.is_empty() or not bool(c.get("built", false)):
		return {}
	if not active:
		var cmd: PackedStringArray = OS.get_cmdline_user_args()
		if cmd.has(BEST_ROSTER_FLAG) or cmd.has(EXPECTED_ROSTER_FLAG):
			return _test_roster_match(city_id, n, cmd.has(BEST_ROSTER_FLAG))
	var stage: int = int(c.get("stage", 1))
	var is_replay: bool = _is_replay_of(city_id, n)
	if is_replay:
		stage = maxi(stage, stage_reached())
	var lv: String = level if active else _test_level()
	var label: String = "%s - GAME %d OF %d" % [str(c.get("name", city_id)).to_upper(), n, GAMES_PER_CITY]
	var crew: Dictionary = c.get("crew", {})
	if c.get("tournament", false):
		var rs: Array = _rounds(city_id)
		if rs.is_empty():
			return {}
		n = clampi(n, 1, rs.size())
		var rd: Dictionary = rs[n - 1]
		crew = rd.get("crew", {})
		label = "%s - %s" % [str(c.get("name", city_id)).to_upper(), str(rd.get("round", "ROUND %d" % n))]
	if is_replay:
		label = REPLAY_LABEL + label
	var mine: Array = []
	var lineup: Array = starters if active and starters.size() == STARTERS else Cities.START_CREW
	for id in lineup:
		mine.append(roster_player(str(id)))
	var theirs: Array = []
	for id in crew_for_game(city_id, n):
		theirs.append(player_dict(str(id), city_ratings(str(id), stage, lv), false))
	var m := {
		"mode": "trip",
		"label": label,
		"target": Cities.game_target(city_id, n),
		"look": look_for(city_id), "music": music_for(city_id), "twist": Cities.twist(city_id),
		"level": lv,
		"city": city_id, "game": n, "stage": stage, "replay": is_replay,
		"teams": [
			{"name": Cities.CREW_NAME, "style": "", "players": mine},
			{"name": str(crew.get("name", "")), "style": str(crew.get("style", "")), "players": theirs},
		],
	}
	Flow.match = m
	return m

# the level of a --city test match (no trip loaded): --difficulty's (or --difficulty=), else DEFAULT_LEVEL
static func _test_level() -> String:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	for i in cmd.size():
		var v := ""
		if cmd[i] == "--difficulty" and i + 1 < cmd.size():
			v = cmd[i + 1]
		elif cmd[i].begins_with("--difficulty="):
			v = cmd[i].get_slice("=", 1)
		v = v.strip_edges().to_lower()
		if LEVELS.has(v):
			return v
	return DEFAULT_LEVEL

# The city's court look: its own once court_looks.gd has it (P6-12), else the city's "fallback" look.
static func look_for(city_id: String) -> String:
	var c: Dictionary = Cities.city(city_id)
	var own: String = str(c.get("look", ""))
	if own != "" and Looks.LOOKS.has(own):
		return own
	var fb = c.get("fallback", {})
	var alt: String = str((fb as Dictionary).get("look", "")) if fb is Dictionary else ""
	return alt if alt != "" else own

# The city's music track: its own once res://assets/music/<id>.ogg exists (P6-A3), else the city's "fallback" track.
static func music_for(city_id: String) -> String:
	var c: Dictionary = Cities.city(city_id)
	var own: String = str(c.get("music", ""))
	if own != "" and ResourceLoader.exists(MUSIC_DIR + own + ".ogg"):
		return own
	var fb = c.get("fallback", {})
	var alt: String = str((fb as Dictionary).get("music", "")) if fb is Dictionary else ""
	return alt if alt != "" else own

# ---------------- --expected-roster and --best-roster (QA, P6-30, P8-21) ----------------
# The two bounds of the ramp (docs/progression-plan.md part 6), both built by playing a trip in memory (nothing
# saved, no stars, no unlocks) up to game n of city_id, every game won on the first try, the points of every win
# spent at once (P8-11: the STAT POINTS screen after every win), with the per-starter rule (P8-08: each starter gets
# his own points; spend() takes his own first, so a player's points only ever raise that player).
#
# Lower bound, expected_roster(): what the trip test's default choices give (each screen's auto_step()):
#   - points (after_game.gd): one point at a time on the lowest stat (first in Ratings.STATS order on a tie) of the
#     first roster player who can still take one, until none is left;
#   - recruit (recruit.gd): the first candidate (the city's first good player); he sits on the bench;
#   - lineup (lineup.gd): keeps the starters it opens with, so the 3 underdogs start every game and earn every point;
#   - no drafts (no star slots).
# Upper bound, best_roster(): the strongest three a trip could legally field there:
#   - BEST_ROSTER_SLOTS star slots open from the start (a trip after earlier trips earned 48+ stars; stars are kept
#     across trips, so this is legal);
#   - before every game the strongest legal three start (P8-14b: at most BOSS_LIMIT boss, so the best boss and the 2
#     best non-bosses, or the 3 best non-bosses; rating sum, the strongest is you): _best_three();
#   - recruit: the candidate who raises that three the most (the boss while the roster has none, then a good player
#     unless the city's boss beats every boss on the roster; on a tie the strongest);
#   - drafts: held until just before game n, then each slot takes the pool player who raises the legal three the most
#     (none left who would = the slot stays open; a player drafted early would earn a few points, but a later crew's
#     player joins at a higher stage; holding the slots also keeps every crew in the pool);
#   - points: the starters' own points, each on his lowest stat (the same rule as above).
# Each returns false for an unknown or not-built city. The caller clears the state (_reset()) when done.

const BEST_ROSTER_FLAG := "--best-roster"   # test flag (with --city): BLUE = the strongest legal three (best_roster())
const BEST_ROSTER_SLOTS := 4                # --best-roster: star slots open (Stars REWARDS has 4 slot rewards)
static var _slots_override := -1            # >= 0: slot_count() returns this (the in-memory roster sims only)

static func expected_roster(city_id: String, n: int = 1) -> bool:
	return _sim_roster(city_id, n, false)

static func best_roster(city_id: String, n: int = 1) -> bool:
	return _sim_roster(city_id, n, true)

static func _sim_roster(city_id: String, n: int, best: bool) -> bool:
	if not Cities.is_built(city_id):
		return false
	var was: bool = saving
	saving = false
	new_trip(DEFAULT_LEVEL)
	_slots_override = BEST_ROSTER_SLOTS if best else 0
	var games: int = maxi(1, _rounds(city_id).size()) if is_tournament(city_id) else GAMES_PER_CITY
	var want: int = clampi(n, 1, games)
	var guard: int = (Cities.ROUTE.size() + 1) * (GAMES_PER_CITY + 2)
	while city != "" and guard > 0:
		guard -= 1
		var at: int = bracket_round() + 1 if is_tournament(city) else game
		if city == city_id and at >= want:
			break
		if best:
			_start_strongest()
		record_result({"won": true})
		_auto_spend_all()
		if phase == "win_points" or phase == "points":
			finish_points()
		if phase == "recruit":
			var cands: Array = recruit_candidates()
			if cands.size() > 0:
				var pick: Dictionary = cands[0]
				if best:
					pick = _best_addition(cands)
				recruit(str(pick.get("id", "")))
	if city != city_id:
		saving = was
		return false
	if is_tournament(city_id):
		phase = "bracket"
	if best:
		_draft_strongest()
		_start_strongest()
	saving = was
	return true

# after_game.gd auto_step()'s points rule, until no point can be spent
static func _auto_spend_all() -> void:
	var spent := true
	while spent and points > 0:
		spent = false
		for id in roster_ids():
			var best := ""
			var low: int = 1000
			var r: Dictionary = _entry(str(id)).get("ratings", {})
			for st in Ratings.STATS:
				if can_spend(str(id), str(st)) and int(r.get(st, 0)) < low:
					low = int(r.get(st, 0))
					best = str(st)
			if best != "":
				spend(str(id), best)
				spent = true
				break
	_spend_log = []

# the five stats added up (how the roster sims rank players)
static func _sum_of(r: Dictionary) -> int:
	var t := 0
	for s in Ratings.STATS:
		t += int(r.get(s, 0))
	return t

# the strongest legal three start (_best_three of the roster), the strongest first (you)
static func _start_strongest() -> void:
	var top: Array = _best_three(_rated(roster_ids()))
	if starters_ok(top) == "":
		set_starters(top, str(top[0]), false)

# [[id, rating sum, boss], ...] for these roster ids
static func _rated(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append([str(id), _sum_of(_entry(str(id)).get("ratings", {})), is_boss(str(id))])
	return out

# The strongest legal three of [[id, sum, boss], ...]: the strongest first, a boss skipped once BOSS_LIMIT are in
# (greedy; with one limit on one kind this is the best sum). Order of the list on a tie.
static func _best_three(rated: Array) -> Array:
	var top: Array = []
	var bosses := 0
	while top.size() < STARTERS:
		var pick: Array = []
		for r in rated:
			if top.has(str(r[0])) or (bool(r[2]) and bosses >= BOSS_LIMIT):
				continue
			if pick.is_empty() or int(r[1]) > int(pick[1]):
				pick = r
		if pick.is_empty():
			break
		top.append(str(pick[0]))
		if bool(pick[2]):
			bosses += 1
	return top

# the rating sum of a list's strongest legal three
static func _three_sum(rated: Array) -> int:
	var t := 0
	var top: Array = _best_three(rated)
	for r in rated:
		if top.has(str(r[0])):
			t += int(r[1])
	return t

# of these candidate player dicts, the one who raises the roster's strongest legal three the most (the strongest
# candidate on a tie); {} for none
static func _best_addition(cands: Array) -> Dictionary:
	var base: Array = _rated(roster_ids())
	var pick: Dictionary = {}
	var gain: int = -1
	for c in cands:
		var id: String = str((c as Dictionary).get("id", ""))
		var plus: Array = base.duplicate()
		plus.append([id, _sum_of((c as Dictionary).get("ratings", {})), is_boss(id)])
		var g: int = _three_sum(plus) - _three_sum(base)
		if g > gain or (g == gain and _sum_of((c as Dictionary).get("ratings", {})) > _sum_of(pick.get("ratings", {}))):
			gain = g
			pick = c
	return pick

# each open slot takes the pool player who raises the strongest legal three the most (quietly; draft() would print
# each one); a slot stays open when nobody would
static func _draft_strongest() -> void:
	while open_slots() > 0:
		var pool: Array = draft_pool()
		if pool.is_empty():
			return
		var pick: Dictionary = _best_addition(pool)
		var id: String = str(pick.get("id", ""))
		var plus: Array = _rated(roster_ids())
		plus.append([id, _sum_of(pick.get("ratings", {})), is_boss(id)])
		if _three_sum(plus) <= _three_sum(_rated(roster_ids())) or not can_draft(id):
			return
		roster_data.append(_new_entry(id, DRAFT_VIA))

# match_for() under --expected-roster / --best-roster with no trip loaded: that crew's match (best wins if both are
# given); prints the whole roster and a one-line summary for the ramp (RAMP ...); the state is cleared after
static func _test_roster_match(city_id: String, n: int, best: bool) -> Dictionary:
	if not _sim_roster(city_id, n, best):
		_reset()
		return {}
	level = _test_level()   # --difficulty legend: the opponents get the LEGEND bonus
	var m: Dictionary = match_for(city_id, n)
	var lines: Array = []
	for e in roster_data:
		lines.append("%s%s %s" % [str(e["id"]), "*" if str(e.get("via", "")) == DRAFT_VIA else "",
				_stat_line(e["ratings"])])
	print("%s ROSTER %s | starters %s | roster (spd/sht/fin/def/sta, * drafted) %s" % [
			"BEST" if best else "EXPECTED", str(m.get("label", "")), ", ".join(PackedStringArray(starters)),
			" | ".join(PackedStringArray(lines))])
	print(ramp_line(m, "best" if best else "expected"))
	_reset()
	return m

# "RAMP <kind> <city> game <n> <level> | BLUE id s/s/s/s/s, ... (avg A) | RED ... (avg B)": one line per --city run
static func ramp_line(m: Dictionary, kind: String) -> String:
	var parts: Array = []
	for t in 2:
		var ps: Array = []
		var sum := 0
		var cnt := 0
		for p in (m["teams"][t] as Dictionary).get("players", []):
			var r: Dictionary = (p as Dictionary).get("ratings", {})
			ps.append("%s %s" % [str(p.get("id", "")), _stat_line(r)])
			sum += _sum_of(r)
			cnt += Ratings.STATS.size()
		parts.append("%s %s (avg %.1f)" % ["BLUE" if t == 0 else "RED", ", ".join(PackedStringArray(ps)),
				float(sum) / float(maxi(1, cnt))])
	return "RAMP %s %s game %d %s | %s" % [kind, str(m.get("city", "")), int(m.get("game", 0)),
			str(m.get("level", "")), " | ".join(PackedStringArray(parts))]

static func _stat_line(r: Dictionary) -> String:
	return "%d/%d/%d/%d/%d" % [int(r.get("speed", 0)), int(r.get("shooting", 0)), int(r.get("finishing", 0)),
			int(r.get("defense", 0)), int(r.get("stamina", 0))]

# Records a finished trip game (flow.gd's game_finished calls it with Flow.last_result) and saves. Returns and keeps
# in last_outcome: {"won", "city", "game", "points_won", "points_each", "city_done", "trip_done", "first_loss",
# "star_key", "stars_before", "stars_now", "new_best", "stars_gained", "stars_game", "replay"}.
# Lost: the same game again. Won: each starter gets points_each (game_points(); 0 if the game has paid before),
# points_won = all of them; the game's stars are recorded (Stars.record at the trip's level: stars_gained > 0 =
# new_best; stars_game = the game's best now, so stars_game - stars_gained was the best before; stars_before /
# stars_now = Stars.total() around it, for Stars.rewards_between()); the next game ("win_points": the points screen
# first), or after game 3 the city is beaten -> points phase.
# New York: a won round moves the bracket on (the final = trip done); a lost round is replayed.
# A replay (replaying()): see _record_replay() (stars only, the marker cleared, nothing else moves).
static func record_result(result: Dictionary) -> Dictionary:
	if not active:
		return {}
	if replaying():
		return _record_replay(result)
	if phase == "done":
		return {}
	var won: bool = bool(result.get("won", false))
	var n: int = bracket_round() + 1 if is_tournament(city) else game
	var k: String = Stars.key(city, n)
	var total_before: int = Stars.total()
	var out := {"won": won, "city": city, "game": game, "points_won": 0, "points_each": 0, "city_done": false,
		"trip_done": false, "first_loss": false, "star_key": k, "stars_before": total_before,
		"stars_now": total_before, "new_best": false, "stars_gained": 0, "stars_game": Stars.best(k),
		"replay": not replay.is_empty()}
	if won:
		out["points_each"] = _pay_starters(k, game_points(city, n))
		out["points_won"] = int(out["points_each"]) * starters.size()
		var gained: int = _record_star(k)
		out["stars_gained"] = gained
		out["new_best"] = gained > 0
		out["stars_game"] = Stars.best(k)
		out["stars_now"] = Stars.total()
	if won:
		record["wins"] = int(record["wins"]) + 1
	else:
		record["losses"] = int(record["losses"]) + 1
		out["first_loss"] = not seen.has("first_loss")
	if is_tournament(city):
		phase = "bracket"
		if won:
			bracket["round"] = bracket_round() + 1
			if bracket_round() >= _rounds(city).size():
				beaten.append(city)
				phase = "done"
				out["city_done"] = true
				out["trip_done"] = true
			else:
				game = bracket_round() + 1
	elif won:
		if game >= GAMES_PER_CITY:
			beaten.append(city)
			phase = "points"
			_spend_log = []
			out["city_done"] = true
		else:
			game += 1
			phase = "win_points" if POINTS_AFTER_EVERY_WIN and points > 0 else "map"   # nothing to spend: lineup
	else:
		phase = "map"   # retry the same game, no penalty
	last_outcome = out
	save()
	if bool(out["city_done"]):
		_unlock_court(str(out["city"]))
	if won and (bool(out["city_done"]) or is_tournament(str(out["city"]))):
		_unlock_team(str(out["city"]), int(out["game"]))
	return out

# A replay's result (P8-17): a win records the game's stars at the trip's level (best kept); no points (points_each
# 0), no record, no story (first_loss false), no unlocks; city, game, bracket, phase, paid and seen stay as they are.
# The marker is cleared (win or loss) and the trip saved. Same keys as record_result(), "replay": true; "city" and
# "game" are the replayed game's.
static func _record_replay(result: Dictionary) -> Dictionary:
	var won: bool = bool(result.get("won", false))
	var rc: String = str(replay.get("city", ""))
	var rn: int = int(replay.get("game", 1))
	var k: String = Stars.key(rc, rn)
	var total_before: int = Stars.total()
	var out := {"won": won, "city": rc, "game": rn, "points_won": 0, "points_each": 0, "city_done": false,
		"trip_done": false, "first_loss": false, "star_key": k, "stars_before": total_before,
		"stars_now": total_before, "new_best": false, "stars_gained": 0, "stars_game": Stars.best(k), "replay": true}
	if won:
		var gained: int = _record_star(k)
		out["stars_gained"] = gained
		out["new_best"] = gained > 0
		out["stars_game"] = Stars.best(k)
		out["stars_now"] = Stars.total()
	replay = {}
	last_outcome = out
	save()
	print("TRIP REPLAY %s %s | stars %d (+%d) | trip stays at %s game %d phase %s" % [k, "won" if won else "lost",
			int(out["stars_game"]), int(out["stars_gained"]), city if city != "" else "-", game, phase])
	return out

# the stars of a won game (Stars.record at the trip's level); never in the in-memory test trips (saving off), except
# --triptest-data's star checks (_star_test, in their own file). Returns the stars gained now.
static func _record_star(k: String) -> int:
	if not saving and not _star_test:
		return 0
	return Stars.record(k, level)

# A 1.0.0 save (loaded_version 1) has no stars: every game it has won counts at its level, once per settings file
# (the stars section key V1_STAR_MARK; a second 1.0.0 save loaded later gets none). Returns the stars gained.
static func _credit_v1_stars() -> int:
	if not saving and not _star_test:
		return 0
	var p: String = Stars.path()
	var cfg := ConfigFile.new()
	cfg.load(p)
	if bool(cfg.get_value(Stars.SECTION, V1_STAR_MARK, false)):
		return 0
	var got := 0
	for k in paid:
		got += Stars.record(str(k), level)
	cfg = ConfigFile.new()
	cfg.load(p)   # Stars.record wrote the bests; keep them and every other setting
	cfg.set_value(Stars.SECTION, V1_STAR_MARK, true)
	cfg.save(p)
	print("TRIP STARS 1.0.0 save: %d games won at %s, +%d stars (total %d)" % [paid.size(), level, got,
			Stars.real_total()])
	return got

# P6-17 hook: a won boss game (a city's game 3, or the New York final) unlocks that city's court for Quick Game.
# Only when difficulty.gd has unlock_court() (P6-17), and never in the in-memory test trips (saving off).
static func _unlock_court(city_id: String) -> void:
	if not saving or not ResourceLoader.exists(DIFFICULTY_PATH):
		return
	var d: GDScript = load(DIFFICULTY_PATH) as GDScript
	if d != null and d.has_method("unlock_court"):
		d.call("unlock_court", city_id)

# P6-T3 hook: the crew just beaten is a Quick Game team from now on (a city's crew after its boss game, a New York
# crew after its round). Same rules as _unlock_court().
static func _unlock_team(city_id: String, n: int) -> void:
	if not saving or not ResourceLoader.exists(DIFFICULTY_PATH):
		return
	var d: GDScript = load(DIFFICULTY_PATH) as GDScript
	if d != null and d.has_method("unlock_team") and d.has_method("team_of"):
		d.call("unlock_team", str(d.call("team_of", city_id, n)))

# ---------------- Quick Game teams (P6-T3) ----------------

# A crew as a Quick Game team (difficulty.gd all_teams() id): {"id", "name", "style", "color", "players"}, the
# players as player_dict()s with "own_colors" (each crew wears its own palette, also as team 0). Lineup: the Kings
# are Jojo, Tank, Deuce (today's BLUE); a city crew its boss game's three, a New York crew its round's three, the
# boss first, then the good players (the first is the one the human controls on team 0). Ratings: each player's own
# (the Kings' starting ratings, a city player's at his stage), shifted so his five stats average 50: the stat shape
# stays, the level is today's Quick Game player (difficulty still changes RED only). {} for an unknown id.
static func quick_team(crew_id: String) -> Dictionary:
	if not ResourceLoader.exists(DIFFICULTY_PATH):
		return {}
	var d: GDScript = load(DIFFICULTY_PATH) as GDScript
	if d == null or not d.has_method("team_info"):
		return {}
	var info: Dictionary = d.call("team_info", crew_id)
	if info.is_empty():
		return {}
	var cid: String = str(info.get("city", ""))
	var ids: Array = QUICK_KINGS.duplicate()
	var style := ""
	if cid != "":
		ids = _star_first(crew_for_game(cid, int(info.get("game", GAMES_PER_CITY))))
		var c: Dictionary = Cities.city(cid)
		var crew: Dictionary = c.get("crew", {})
		if is_tournament(cid):
			var rs: Array = _rounds(cid)
			crew = (rs[clampi(int(info.get("game", 1)) - 1, 0, rs.size() - 1)] as Dictionary).get("crew", {})
		style = str(crew.get("style", ""))
	var players: Array = []
	for id in ids:
		var pd: Dictionary = player_dict(str(id), quick_ratings(str(id)), false)
		pd["own_colors"] = true
		players.append(pd)
	return {"id": crew_id, "name": str(info.get("name", "")), "style": style, "color": info.get("color", Color.GRAY),
		"players": players}

# a player's ratings shifted so the five stats average QUICK_AVG (each rounded, clamped to 0..100)
static func quick_ratings(id: String) -> Dictionary:
	var base: Dictionary = _start_ratings(id)
	var sum := 0.0
	for s in Ratings.STATS:
		sum += float(base[s])
	var shift: float = float(QUICK_AVG) - sum / float(Ratings.STATS.size())
	var out: Dictionary = {}
	for s in Ratings.STATS:
		out[s] = clampi(roundi(float(base[s]) + shift), Ratings.MIN_RATING, Ratings.MAX_RATING)
	return out

# boss first, then good, then average players (stable within a tier)
static func _star_first(ids: Array) -> Array:
	var out: Array = []
	for tier in ["boss", "good", "avg"]:
		for id in ids:
			if str(Cities.player(str(id)).get("tier", "")) == tier:
				out.append(id)
	for id in ids:
		if not out.has(id):
			out.append(id)
	return out

# Where the result screen goes next: {"screen": String, "args": Dictionary} (Flow.go(r.screen, r.args)).
# Lost -> story "first_loss" once, then the lineup (retry). Won with games left -> the points screen
# ({"then": "lineup"}; phase "win_points", its DONE / finish_points() goes on), then the lineup. City done -> the
# city's "won" story, then points (then recruit). Tournament: a won round -> the points screen ({"then": "bracket"})
# when there are points to spend, then the bracket; a lost round -> the bracket; the final won -> story "ending", then
# the title. With POINTS_AFTER_EVERY_WIN off: 1.0.0 (a won game 1-2 -> lineup, a won round -> bracket).
# A replay (won or lost): the map, always (no points, story or recruit screen; P8-17).
static func after_result() -> Dictionary:
	var o: Dictionary = last_outcome
	if o.is_empty() or bool(o.get("replay", false)):
		return {"screen": "map", "args": {}}
	var next := "lineup"
	var won: bool = bool(o.get("won", false))
	if bool(o.get("trip_done", false)):
		return _story_or("ending", "title")
	if is_tournament(str(o.get("city", ""))):
		next = "bracket"
		if won and POINTS_AFTER_EVERY_WIN and points > 0 and SPEND_PHASES.has(phase):
			return {"screen": "points", "args": {"then": next}}
	elif bool(o.get("city_done", false)):
		var st: Dictionary = Cities.city(str(o.get("city", ""))).get("story", {})
		return _story_or(str(st.get("won", "")), "points")
	elif won and phase == "win_points":
		return {"screen": "points", "args": {"then": next}}
	if not won and bool(o.get("first_loss", false)):
		return _story_or("first_loss", next)
	return {"screen": next, "args": {}}

# story scene first if not seen yet (marked seen here), else straight to `then`
static func _story_or(scene: String, then: String) -> Dictionary:
	if scene != "" and mark_seen(scene):
		return {"screen": "story", "args": {"scene": scene, "then": then}}
	return {"screen": then, "args": {}}

# ---------------- stat points ----------------

# what a win of game n pays each starter: POINTS_BOSS_GAME for a boss game (game 3) or a New York round, else
# POINTS_CITY_GAME (the same on every level)
static func game_points(city_id: String, n: int) -> int:
	if is_tournament(city_id) or n >= GAMES_PER_CITY:
		return POINTS_BOSS_GAME
	return POINTS_CITY_GAME

# the game key's points to each starter, once per trip (the key goes into paid); returns what each got (0 = paid
# before). Not saved here (record_result saves).
static func _pay_starters(k: String, each: int) -> int:
	if paid.has(k) or each <= 0:
		return 0
	paid.append(k)
	for id in starters:
		var e: Dictionary = _entry(str(id))
		if not e.is_empty():
			e["pts"] = clampi(int(e.get("pts", 0)) + each, 0, MAX_POINTS)
	_sync_points()
	return each

# true when this game key has paid its points this trip
static func is_paid(k: String) -> bool:
	return paid.has(k)

# a roster player's own unspent points (0 if not on the roster)
static func player_points(id: String) -> int:
	return int(_entry(id).get("pts", 0))

# points keeps the total of every unspent point (the screens show it; the save writes it for 1.0.0 builds)
static func _sync_points() -> void:
	var sum: int = crew_points
	for e in roster_data:
		sum += int((e as Dictionary).get("pts", 0))
	points = clampi(sum, 0, MAX_POINTS)

# adds crew points (anyone may spend them); returns how many were added
static func award_points(n: int = POINTS_PER_WIN, do_save: bool = true) -> int:
	crew_points = clampi(crew_points + n, 0, MAX_POINTS)
	_sync_points()
	if do_save:
		save()
	return n

# true when one point can go into this stat of this player (his own points or crew points left, below the cap, in a
# spending phase)
static func can_spend(id: String, stat: String) -> bool:
	if not active or not SPEND_PHASES.has(phase) or not Ratings.STATS.has(stat):
		return false
	var e: Dictionary = _entry(id)
	if e.is_empty() or int(e.get("pts", 0)) + crew_points <= 0:
		return false
	return int(e["ratings"][stat]) < STAT_CAP

# one point: +3 on one stat of one roster player (to 90 at most), from his own points first, then crew points.
# Saved. False when it can't.
static func spend(id: String, stat: String) -> bool:
	if not can_spend(id, stat):
		return false
	var e: Dictionary = _entry(id)
	var old: int = int(e["ratings"][stat])
	e["ratings"][stat] = mini(old + POINT_GAIN, STAT_CAP)
	var from := "crew"
	if int(e.get("pts", 0)) > 0:
		from = "pts"
		e["pts"] = int(e["pts"]) - 1
	else:
		crew_points -= 1
	_sync_points()
	_spend_log.append([id, stat, old, from])
	save()
	return true

# undoes the last point spent on this points screen (before DONE). Saved. False when there is nothing to undo.
static func undo_spend() -> bool:
	if _spend_log.is_empty():
		return false
	var last: Array = _spend_log.pop_back()
	var e: Dictionary = _entry(str(last[0]))
	if e.is_empty():
		return false
	e["ratings"][str(last[1])] = int(last[2])
	if last.size() > 3 and str(last[3]) == "pts":
		e["pts"] = int(e.get("pts", 0)) + 1
	else:
		crew_points += 1
	_sync_points()
	save()
	return true

static func can_undo() -> bool:
	return not _spend_log.is_empty()

# the points screen's DONE (or SKIP): after a city on to the recruit screen (or the map if nobody is left to
# recruit); after a won city game 1-2 ("win_points") back to "map" (the screen goes on to its "then", the lineup);
# unspent points are kept. Saved.
static func finish_points() -> void:
	_spend_log = []
	if phase == "win_points":
		phase = "map"
	if phase == "points":
		phase = "recruit" if recruit_candidates().size() > 0 else "map"
		if phase == "map":
			_advance_city()
	save()

# ---------------- recruiting ----------------

# the beaten city's 2 good players and boss as player dicts (with the ratings they would join with), minus anyone
# already on the roster
static func recruit_candidates() -> Array:
	var out: Array = []
	for id in Cities.recruits(city):
		if not _on_roster(str(id)):
			out.append(player_dict(str(id), _start_ratings(str(id)), true))
	return out

# He joins the bench (keeps his ratings, wears your colors); the van moves on to the next city. Saved.
static func recruit(id: String) -> bool:
	if not active or phase != "recruit" or _on_roster(id) or not Cities.recruits(city).has(id):
		return false
	roster_data.append(_new_entry(id, "recruit"))
	_advance_city()
	save()
	return true

static func _advance_city() -> void:
	city = next_city(city)
	game = 1
	bracket = {"round": 0}
	phase = "map" if city != "" else "done"

# ---------------- roster slots and the draft (P8-14) ----------------
# Owner answers (VISION "Phase 8 plan answers"): Stars.slots() extra roster slots (12 / 24 / 36 / 48 stars, kept for
# good); each holds one player drafted from a crew beaten ON THIS TRIP (bosses and average players too; a New York
# crew once its round is won), minus anyone on the roster. A draft is final for the trip (no release); a NEW TRIP
# starts with empty slots. He joins like a recruit: his own city's stage ratings, 0 points, via "draft", your colors
# (Cities.crew_sheet). Any number of bosses may be on the roster; at most BOSS_LIMIT start (starters_ok). While the recruit screen is up ("recruit" phase), the city's recruit
# candidates are that screen's pick, not the draft's.

# the players drafted on this trip (via "draft"), in the order they joined
static func drafted_ids() -> Array:
	var out: Array = []
	for e in roster_data:
		if str((e as Dictionary).get("via", "")) == DRAFT_VIA:
			out.append(str(e["id"]))
	return out

# the star slots open for good (Stars.slots(), 0..4), filled or not
static func slot_count() -> int:
	if _slots_override >= 0:
		return _slots_override   # the --expected-roster / --best-roster sims
	return Stars.slots()

# slots still free on this trip: the star slots minus the players drafted (0 without a trip; never below 0, also if a
# --stars test run drafted more than this run's slots)
static func open_slots() -> int:
	if not active:
		return 0
	return maxi(0, slot_count() - drafted_ids().size())

# the roster's size limit now: the underdogs and recruits on it plus one per star slot (never below the roster size)
static func roster_limit() -> int:
	var size: int = roster_ids().size()
	return maxi(size, size - drafted_ids().size() + slot_count())

static func is_boss(id: String) -> bool:
	return str(Cities.player(id).get("tier", "")) == "boss"

# the crews beaten on this trip, in route order: [{"city", "round" (0 = a city crew, 1..3 = a New York round), "name",
# "style", "color" (ui_color), "ids": [player ids, boss first, then good, then average]}]
static func beaten_crews() -> Array:
	var out: Array = []
	if not active:
		return out
	for cid in Cities.ROUTE:
		var c: Dictionary = Cities.city(cid)
		if is_tournament(cid):
			var won: int = 0
			if beaten.has(cid):
				won = _rounds(cid).size()
			elif cid == city:
				won = bracket_round()
			for i in won:
				var rd: Dictionary = _rounds(cid)[i]
				var rc: Dictionary = rd.get("crew", {})
				out.append({"city": cid, "round": i + 1, "name": str(rc.get("name", "")),
					"style": str(rc.get("style", "")), "color": rc.get("ui_color", Color.GRAY),
					"ids": _star_first(rd.get("players", []))})
		elif beaten.has(cid):
			var crew: Dictionary = c.get("crew", {})
			out.append({"city": cid, "round": 0, "name": str(crew.get("name", "")), "style": str(crew.get("style", "")),
				"color": crew.get("ui_color", Color.GRAY), "ids": _star_first(Cities.city_players(cid))})
	return out

# The draft pool grouped by crew (the DRAFT screen): beaten_crews() rows with "players" (player dicts at the ratings
# they would join with, in your colors, plus "city", "crew", "boss": bool); crews with nobody left are dropped.
static func draft_pool_by_crew() -> Array:
	var out: Array = []
	for row in beaten_crews():
		var players: Array = []
		for id in row["ids"]:
			if _draftable(str(id)):
				var pd: Dictionary = player_dict(str(id), _start_ratings(str(id)), true)
				pd["city"] = str(row["city"])
				pd["crew"] = str(row["name"])
				pd["boss"] = is_boss(str(id))
				players.append(pd)
		if players.size() > 0:
			var r: Dictionary = (row as Dictionary).duplicate()
			r.erase("ids")
			r["players"] = players
			out.append(r)
	return out

# the draft pool as one list (player dicts, crews in route order); the same with no open slot (the screen shows it)
static func draft_pool() -> Array:
	var out: Array = []
	for row in draft_pool_by_crew():
		out.append_array(row["players"])
	return out

# in the pool: from a crew beaten on this trip, not on the roster, not the recruit screen's pick right now
static func _draftable(id: String) -> bool:
	if _on_roster(id):
		return false
	if phase == "recruit" and Cities.recruits(city).has(id):
		return false
	for row in beaten_crews():
		if (row["ids"] as Array).has(id):
			return true
	return false

# why `id` can't be drafted now ("" = he can): no trip, unknown, on the roster, not from a beaten crew, no open slot
static func draft_refusal(id: String) -> String:
	if not active:
		return "no trip"
	if Cities.player(id).is_empty():
		return "unknown player"
	if _on_roster(id):
		return "already on the roster"
	if not _draftable(id):
		return "not from a crew beaten on this trip"
	if open_slots() <= 0:
		return "no open slot"
	return ""

static func can_draft(id: String) -> bool:
	return draft_refusal(id) == ""

# Drafts `id` into an open slot: he joins the bench at his city's stage ratings, 0 points, via "draft". Final for the
# trip. Saved. False (nothing changed) when draft_refusal() says why not.
static func draft(id: String) -> bool:
	var why: String = draft_refusal(id)
	if why != "":
		print("TRIP DRAFT %s refused: %s" % [id, why])
		return false
	roster_data.append(_new_entry(id, DRAFT_VIA))
	print("TRIP DRAFT %s (%d open slots left)" % [id, open_slots()])
	save()
	return true

# "" when `ids` are 3 different roster players with at most BOSS_LIMIT boss (set_starters() would take them), else
# the reason (BOSS_RULE for too many bosses; P8-14b, owner).
static func starters_ok(ids: Array) -> String:
	var roster_list: Array = roster_ids()
	var picked: Array = []
	for e in ids:
		var id: String = str(e)
		if not roster_list.has(id):
			return "%s is not on the roster" % id
		if picked.has(id):
			return "%s picked twice" % id
		picked.append(id)
	if picked.size() != STARTERS:
		return "pick %d starters" % STARTERS
	if boss_count(picked) > BOSS_LIMIT:
		return BOSS_RULE
	return ""

# how many of these ids are bosses
static func boss_count(ids: Array) -> int:
	var n := 0
	for id in ids:
		if is_boss(str(id)):
			n += 1
	return n

# A loaded lineup with more than BOSS_LIMIT bosses (a 1.0.0 save, or any older one): the first bosses stay, every
# later one is swapped in place for the strongest non-boss roster player not starting (rating sum; roster order on a
# tie). boss_repair gets the benched ids. Other lineups come back unchanged (set_starters() checks the rest).
static func _repair_bosses(ids: Array) -> Array:
	if boss_count(ids) <= BOSS_LIMIT:
		return ids
	var out: Array = ids.duplicate()
	var kept := 0
	for i in out.size():
		var id: String = str(out[i])
		if not is_boss(id):
			continue
		if kept < BOSS_LIMIT:
			kept += 1
			continue
		var pick := ""
		var hi: int = -1
		for rid in roster_ids():
			var v: int = _sum_of(_entry(str(rid)).get("ratings", {}))
			if not is_boss(str(rid)) and not out.has(str(rid)) and v > hi:
				hi = v
				pick = str(rid)
		if pick == "":
			return ids   # no one to swap in (can't happen: the 3 underdogs are always on the roster)
		out[i] = pick
		boss_repair.append(id)
	print("TRIP lineup repaired on load (%s): %s -> %s" % [BOSS_RULE.to_lower(), str(ids), str(out)])
	return out

# the lineup note after a repair ("" = none): who went to the bench, by name
static func boss_repair_note() -> String:
	if boss_repair.is_empty():
		return ""
	var names: Array = []
	for id in boss_repair:
		names.append(str(Cities.player(str(id)).get("name", id)))
	return "%s: %s moved to the bench." % [BOSS_RULE, " and ".join(PackedStringArray(names))]

# ---------------- replays (P8-17) ----------------
# Owner answers (VISION "Progression plan answers", docs/progression-plan.md part 5): any game won on this trip (city
# games of beaten cities and the city being played, New York rounds once won) can be played again from the map,
# between games (REPLAY_PHASES: "map", "bracket", "done"; not with a points / recruit step pending). The opponents
# are the game's own crew, target, court, twist and music, at the stage reached (stage_reached(), never below the
# city's own), at the trip's level (LEGEND bonus too). Stars only. The flow: the map's picker calls
# start_replay(city, n) (marker + Flow.match), then the lineup (its match_for() builds the replay), the game, the
# result (record_result: _record_replay), after_result() = the map. CONTINUE with the marker set opens the lineup
# (resume_screen); backing out of the replay = cancel_replay() (the map does it when it opens).

# the trip stage the opponents of a replay are raised to: the stage of the city being played (New York in the
# bracket), the last stage (New York's, 8) once the trip is done; 1 without a trip
static func stage_reached() -> int:
	if not active:
		return 1
	if phase == "done" or city == "":
		return _last_stage()
	return int(Cities.city(city).get("stage", 1))

static func _last_stage() -> int:
	var top: int = 1
	for cid in Cities.built_route():
		top = maxi(top, int(Cities.city(str(cid)).get("stage", 1)))
	return top

# true while a replay is marked (start_replay() until its result or cancel_replay())
static func replaying() -> bool:
	return active and not replay.is_empty()

# true when game n of city_id can be replayed now: a trip is loaded, between games (REPLAY_PHASES), and that game
# (a city game 1..3, a New York round 1..3) was won on this trip
static func can_replay(city_id: String, n: int) -> bool:
	if not active or not REPLAY_PHASES.has(phase) or not Cities.is_built(city_id):
		return false
	var games: int = _rounds(city_id).size() if is_tournament(city_id) else GAMES_PER_CITY
	if n < 1 or n > games:
		return false
	return _won_keys().has(Stars.key(city_id, n))

# the games that can be replayed now, in route order: [{"city", "game", "key", "stars" (best so far)}]
static func replay_games() -> Array:
	var out: Array = []
	if not active or not REPLAY_PHASES.has(phase):
		return out
	for k in _won_keys():
		var cid: String = str(k).get_slice(":", 0)
		var n: int = int(str(k).get_slice(":", 1))
		if can_replay(cid, n):
			out.append({"city": cid, "game": n, "key": str(k), "stars": Stars.best(str(k))})
	return out

# Marks game n of city_id as the replay (saved) and builds its match (Flow.match, match_for()); then go to the
# lineup. False (nothing changed) when can_replay() says no. A second call replaces the marker.
static func start_replay(city_id: String, n: int) -> bool:
	if not can_replay(city_id, n):
		print("TRIP REPLAY %s refused (phase %s)" % [Stars.key(city_id, n), phase])
		return false
	replay = {"city": city_id, "game": n}
	save()
	match_for()
	print("TRIP REPLAY %s start | stage %d | level %s" % [Stars.key(city_id, n), stage_reached(), level])
	return true

# drops the replay marker (BACK out of a replay's lineup; the map calls it when it opens). Saved if it was set. True
# when there was one.
static func cancel_replay() -> bool:
	if replay.is_empty():
		return false
	replay = {}
	if active:
		Flow.match = {}
		save()
	return true

# the replay's own match: a trip is replaying exactly this game
static func _is_replay_of(city_id: String, n: int) -> bool:
	return replaying() and str(replay["city"]) == city_id and int(replay["game"]) == n

# ---------------- story ----------------

static func has_seen(scene: String) -> bool:
	return seen.has(scene)

# marks a story scene seen (saved); true the first time
static func mark_seen(scene: String) -> bool:
	if seen.has(scene):
		return false
	seen.append(scene)
	save()
	return true

# ---------------- test: -- --triptest-data [--load] ----------------
# Prints every city game's lineups and ratings, checks the save (write + read back, missing / corrupt / truncated /
# newer-version / left-over temp files) and writes the round-trip save. With --load (run it in a second process)
# it loads that save and compares it with the same scripted trip rebuilt in memory. Prints TRIPDATA OK / FAILED.
static func self_test(load_only: bool = false) -> bool:
	Save.use_test_file = true
	var ok := true
	if load_only:
		ok = _check_loaded()
		print("TRIPDATA %s" % ("OK" if ok else "FAILED"))
		return ok
	_reset()
	var missing: Array = Cities.missing_ids()
	print("TRIPDATA route (built): %s | missing ids: %s" % [", ".join(PackedStringArray(Cities.built_route())),
			str(missing)])
	if missing.size() > 0:
		ok = false
	for cid in Cities.built_route():
		var n_games: int = _rounds(cid).size() if is_tournament(cid) else GAMES_PER_CITY
		for n in range(1, n_games + 1):
			var m: Dictionary = match_for(cid, n)
			if m.is_empty():
				print("TRIPDATA %s game %d: NO MATCH" % [cid, n])
				ok = false
				continue
			print("TRIPDATA %s | to %d | %s | %s | twist %s | level %s" % [m.label, int(m.target), m.look, m.music,
					m.twist, m.level])
			for t in 2:
				var tm: Dictionary = m.teams[t]
				print("TRIPDATA   %-16s %-8s" % [tm.name, tm.style if tm.style != "" else "-"])
				for p in tm.players:
					print("TRIPDATA     " + _player_line(p))
				if (tm.players as Array).size() != STARTERS:
					ok = false
			ok = _check_tiers(cid, n) and ok
	var rc: Array = []
	for id in Cities.built_route():
		rc.append("%s: %s" % [id, ", ".join(PackedStringArray(Cities.recruits(id)))])
	print("TRIPDATA recruits %s" % " | ".join(PackedStringArray(rc)))
	ok = _check_city_data() and ok
	ok = _check_expected_rosters() and ok
	ok = _check_best_rosters() and ok
	ok = _check_rules() and ok
	ok = _check_stars() and ok
	ok = _check_draft() and ok
	ok = _check_boss_rule() and ok
	ok = _check_replays() and ok
	ok = _check_v1_fixtures() and ok
	ok = _check_save_files() and ok
	# the round trip: the scripted trip saved for the --load process
	_scripted_trip(true)
	var wrote: bool = Save.write(to_dict())
	print("TRIPDATA round trip written to %s: %s | %s" % [Save.path(), "ok" if wrote else "FAILED " + Save.last_error,
			_digest()])
	ok = ok and wrote
	Flow.match = {}
	print("TRIPDATA %s" % ("OK" if ok else "FAILED"))
	return ok

static func _player_line(p: Dictionary) -> String:
	var r: Dictionary = p.ratings
	return "%-8s %-13s %-5s spd %2d sht %2d fin %2d def %2d sta %2d | stl %2d blk %2d" % [p.name, p.sheet, p.tier,
			r.speed, r.shooting, r.finishing, r.defense, r.stamina, r.steal, r.block]

# Every city's data (P6-10): built, a known look / music / twist id, a fallback look that exists today, story scenes
# that exist, a crew of 2 good + 2 avg + a boss (the good players and the boss recruitable, the avg not), no player
# in two crews, and the New York rounds shaped like the 3 city games.
static func _check_city_data() -> bool:
	var ok := true
	var owner_of: Dictionary = {}   # player id -> city id
	for cid in Cities.ROUTE:
		var c: Dictionary = Cities.city(cid)
		var bad: Array = []
		if not bool(c.get("built", false)):
			bad.append("not built")
		if not Cities.LOOK_IDS.has(str(c.get("look", ""))):
			bad.append("look '%s'" % str(c.get("look", "")))
		if not Cities.MUSIC_IDS.has(str(c.get("music", ""))):
			bad.append("music '%s'" % str(c.get("music", "")))
		if not Cities.TWIST_IDS.has(str(c.get("twist", ""))):
			bad.append("twist '%s'" % str(c.get("twist", "")))
		if not Looks.LOOKS.has(look_for(cid)):
			bad.append("no playable look (fallback)")
		var st: Dictionary = c.get("story", {})
		for k in ["arrive", "won"]:
			if not StoryText.has_scene(str(st.get(k, ""))):
				bad.append("story %s '%s'" % [k, str(st.get(k, ""))])
		var crew: Dictionary = c.get("crew", {})
		if not is_tournament(cid):
			if (crew.get("good", []) as Array).size() != 2 or (crew.get("avg", []) as Array).size() != 2 \
					or str(crew.get("boss", "")) == "" or str(crew.get("name", "")) == "":
				bad.append("crew shape")
			for id in Cities.city_players(cid):
				var p: Dictionary = Cities.player(str(id))
				var want_rec: bool = str(p.get("tier", "")) != "avg"
				if bool(p.get("recruitable", false)) != want_rec:
					bad.append("%s recruitable" % str(id))
				if str(p.get("look", "")) == "" or str(p.get("bio", "")) == "":
					bad.append("%s look/bio" % str(id))
		else:
			for r in _rounds(cid):
				if str(((r as Dictionary).get("crew", {}) as Dictionary).get("name", "")) == "":
					bad.append("round crew name")
			for id in Cities.city_players(cid):
				if bool(Cities.player(str(id)).get("recruitable", false)):
					bad.append("%s recruitable" % str(id))
		for id in Cities.city_players(cid):
			if owner_of.has(id) and str(owner_of[id]) != cid:
				bad.append("%s also in %s" % [str(id), str(owner_of[id])])
			owner_of[id] = cid
		ok = _check(bad.is_empty(), "city %s data %s" % [cid, "" if bad.is_empty() else str(bad)]) and ok
	ok = _check(StoryText.has_scene("trip_start") and StoryText.has_scene("first_loss"),
			"story trip_start, first_loss") and ok
	return ok

# --expected-roster: for every city's game 1 the expected crew (one recruit per city before it); printed for QA
static func _check_expected_rosters() -> bool:
	var ok := true
	var before := 0
	for cid in Cities.built_route():
		var good: bool = expected_roster(cid, 1)
		var size: int = roster_ids().size()
		var deuce: Dictionary = _entry("ud_deuce").get("ratings", {})
		ok = _check(good and size == Cities.START_CREW.size() + before and starters == Cities.START_CREW,
				"expected roster at %s: %d players, Deuce %d/%d/%d/%d/%d" % [cid, size, int(deuce.get("speed", 0)),
				int(deuce.get("shooting", 0)), int(deuce.get("finishing", 0)), int(deuce.get("defense", 0)),
				int(deuce.get("stamina", 0))]) and ok
		before += 1
		_reset()
	return ok

# --best-roster (P8-21): at every city's game 1 and every New York round, the strongest three are legal starters
# (P8-14b: at most BOSS_LIMIT boss),
# at most BEST_ROSTER_SLOTS drafted, never weaker than the expected three; printed for QA
static func _starters_sum() -> int:
	var t := 0
	for id in starters:
		t += _sum_of(_entry(str(id)).get("ratings", {}))
	return t

static func _check_best_rosters() -> bool:
	var ok := true
	for cid in Cities.built_route():
		var n_games: int = _rounds(cid).size() if is_tournament(cid) else 1
		for n in range(1, n_games + 1):
			var low_ok: bool = expected_roster(cid, n)
			var low: int = _starters_sum()
			_reset()
			var good: bool = best_roster(cid, n) and low_ok
			var high: int = _starters_sum()
			var lines: Array = []
			for id in starters:
				lines.append("%s %s" % [str(id), _stat_line(_entry(str(id)).get("ratings", {}))])
			ok = _check(good and starters_ok(starters) == "" and boss_count(starters) <= BOSS_LIMIT
					and drafted_ids().size() <= BEST_ROSTER_SLOTS
					and high >= low, "best roster at %s %d: %s (sum %d >= %d)" % [cid, n,
					", ".join(PackedStringArray(lines)), high, low]) and ok
			_reset()
	return ok

# the 3-game rule: game 1 = 1 good + 2 avg, 2 = 2 good + 1 avg, 3 = 2 good + boss (New York rounds the same)
static func _check_tiers(cid: String, n: int) -> bool:
	var want: Array = [["good", "avg", "avg"], ["good", "good", "avg"], ["good", "good", "boss"]][n - 1]
	var got: Array = []
	for id in crew_for_game(cid, n):
		got.append(str(Cities.player(str(id)).get("tier", "")))
	var good: bool = got == want
	if not good:
		print("TRIPDATA %s game %d tiers %s, want %s: WRONG" % [cid, n, str(got), str(want)])
	return good

static func _check(ok: bool, what: String) -> bool:
	print("TRIPDATA check %-52s %s" % [what, "ok" if ok else "WRONG"])
	return ok

# the trip rules, played through in memory (nothing saved)
static func _check_rules() -> bool:
	saving = false
	var ok := true
	new_trip("hard")
	ok = _check(city == "hometown" and game == 1 and phase == "map" and roster_ids() == Cities.START_CREW,
			"new trip at Hometown game 1 with the 3 underdogs") and ok
	ok = _check(int(match_for().target) == 11 and str(match_for().level) == "hard", "game 1 to 11, level hard") and ok
	record_result({"won": false})
	ok = _check(game == 1 and points == 0 and bool(last_outcome.first_loss), "a loss retries game 1, no points") and ok
	var ar: Dictionary = after_result()
	ok = _check(ar.screen == "story" and after_result().screen == "lineup", "first loss story once") and ok
	record_result({"won": true})
	ok = _check(game == 2 and points == 3 and int(last_outcome.points_each) == POINTS_CITY_GAME
			and int(last_outcome.points_won) == 3 and player_points("ud_jojo") == 1 and crew_points == 0
			and int(match_for().target) == 15, "a win: game 2 to 15, 1 point each starter") and ok
	ar = after_result()
	ok = _check(phase == "win_points" and resume_screen() == "points" and ar.screen == "points"
			and ar.args.get("then", "") == "lineup" and int(last_outcome.stars_gained) == 0,
			"a won game 1: points screen, then the lineup (no stars in memory)") and ok
	finish_points()
	ok = _check(phase == "map" and points == 3 and can_spend("ud_deuce", "speed"),
			"DONE / SKIP keeps the points, spendable between games") and ok
	record_result({"won": true})
	record_result({"won": true})
	ok = _check(phase == "points" and beaten == ["hometown"] and points == 12 and player_points("ud_tank") == 4
			and int(last_outcome.points_each) == POINTS_BOSS_GAME and bool(last_outcome.city_done)
			and paid == ["hometown:1", "hometown:2", "hometown:3"], "3 wins: Hometown beaten, 4 each, paid") and ok
	ar = after_result()
	ok = _check(ar.screen == "story" and ar.args.then == "points", "hometown_won story, then points") and ok
	var before: int = int(_entry("ud_tank").ratings.finishing)
	ok = _check(spend("ud_tank", "finishing") and int(_entry("ud_tank").ratings.finishing) == before + 3
			and player_points("ud_tank") == 3 and points == 11, "a point = +3, from his own points") and ok
	ok = _check(undo_spend() and int(_entry("ud_tank").ratings.finishing) == before and points == 12
			and player_points("ud_tank") == 4, "undo gives his point back") and ok
	award_points(10, false)   # crew points: Deuce's 4 + 6 of these reach the cap
	while spend("ud_deuce", "shooting"):
		pass
	ok = _check(int(_entry("ud_deuce").ratings.shooting) == STAT_CAP and player_points("ud_deuce") == 0
			and crew_points == 4 and points == 12, "cap at 90 (62 -> 90 in 10): his 4, then 6 crew points") and ok
	ok = _check(spend("ud_deuce", "speed") and crew_points == 3 and undo_spend() and crew_points == 4,
			"no own points left: crew points, undo gives them back") and ok
	finish_points()
	ok = _check(phase == "recruit" and recruit_candidates().size() == 3, "recruit: 3 candidates") and ok
	ok = _check(not recruit("ht_a1") and not recruit("chi_g1"), "only the city's good players or boss") and ok
	ok = _check(recruit("ht_boss") and city == "chicago" and game == 1 and phase == "map"
			and roster_ids().size() == 4, "recruit the boss, on to Chicago") and ok
	ok = _check(roster_player("ht_boss").sheet == Cities.crew_sheet("ht_boss", true) \
			and str(roster_player("ht_boss").sheet).begins_with("ht_boss_crew")
			and int(roster_player("ht_boss").ratings.speed) == 60,
			"recruit wears your colors, keeps 40 + 20") and ok
	ok = _check(not recruit("ht_g1"), "only one recruit per city") and ok
	ok = _check(str(_entry("ht_boss").via) == "recruit" and str(_entry("ud_jojo").via) == "start"
			and player_points("ht_boss") == 0, "via: start / recruit; a recruit joins with 0 points") and ok
	ok = _check(not set_starters(["ud_deuce", "ud_deuce", "ud_tank"]) and set_starters(
			["ud_deuce", "ht_boss", "ud_tank"], "ht_boss") and starters[0] == "ht_boss" and human == "ht_boss",
			"starters: 3 different, the human first") and ok
	ok = _check(match_for().teams[0].players[0].id == "ht_boss" and str(match_for().label) == "CHICAGO - GAME 1 OF 3",
			"the match uses the lineup") and ok
	ok = _check(str(match_for().twist) == "wind" and str(match_for("hometown", 1).twist) == "none",
			"the match carries the twist (Chicago wind)") and ok
	var jojo: int = player_points("ud_jojo")
	record_result({"won": true})
	ok = _check(player_points("ht_boss") == 1 and player_points("ud_jojo") == jojo, "the bench gets nothing") and ok
	game = 1   # white box: the same game won again (a replay later) pays nothing
	record_result({"won": true})
	ok = _check(int(last_outcome.points_each) == 0 and player_points("ht_boss") == 1 and game == 2,
			"each game pays once") and ok
	for i in 2:
		record_result({"won": true})
	ok = _check(player_points("ht_boss") == 4 and spend("ht_boss", "speed") and player_points("ht_boss") == 3
			and crew_points == 4, "his own points first, crew points kept") and ok
	finish_points()
	recruit("chi_g2")
	ok = _check(city == "memphis" and phase == "map" and str(match_for().label) == "MEMPHIS - GAME 1 OF 3"
			and str(match_for().twist) == "crowd", "Chicago beaten, on to Memphis (crowd)") and ok
	var guard := 10
	while city != "new_york" and city != "" and guard > 0:
		guard -= 1
		for i in 3:
			record_result({"won": true})
		finish_points()
		recruit(str(Cities.recruits(city)[0]))
	ok = _check(city == "new_york" and phase == "map" and beaten.size() == 7 and roster_ids().size() == 10,
			"all 7 cities beaten, 7 recruits, on to New York") and ok
	ok = _check(str(match_for().twist) == "cage", "New York: the cage") and ok
	ok = _check(int(match_for().target) == 21 and str(match_for().label) == "NEW YORK - QUARTERFINAL"
			and match_for().teams[1].players.size() == 3, "tournament round 1 to 21") and ok
	record_result({"won": false})
	ok = _check(bracket_round() == 0 and phase == "bracket" and after_result().screen == "bracket",
			"a lost round is replayed") and ok
	record_result({"won": true})
	record_result({"won": true})
	ok = _check(str(match_for().label) == "NEW YORK - FINAL" and str(match_for().teams[1].players[2].id) == "ny_boss",
			"the final against ny_boss") and ok
	ok = _check(int(last_outcome.points_each) == POINTS_BOSS_GAME and paid.has("new_york:2")
			and not paid.has("new_york:3"), "a New York round pays 2 each") and ok
	ar = after_result()
	ok = _check(phase == "bracket" and ar.screen == "points" and ar.args.get("then", "") == "bracket",
			"a won round: points screen, then the bracket") and ok
	record_result({"won": true})
	ok = _check(paid == Stars.all_keys(), "every game paid once: %d" % paid.size()) and ok
	ok = _check(phase == "done" and is_done() and after_result().args.get("scene", "") == "ending"
			and record_result({"won": true}).is_empty(), "final won: ending, trip done") and ok
	saving = true
	_reset()
	return ok

# P8-11: stars on a win (best kept, new_best, the totals), the per-win flow and CONTINUE, the 1.0.0 star credit once.
# In memory (saving off), the stars in their own scratch file (STARS_TEST_PATH), never the test settings file.
static func _check_stars() -> bool:
	var was: bool = saving
	saving = false
	_star_test = true
	var old_force: int = Stars.force_total
	Stars.force_total = -1   # --stars N would hide the totals
	Stars._path_override = STARS_TEST_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STARS_TEST_PATH))
	var ok := true
	new_trip("normal")
	record_result({"won": false})
	var o: Dictionary = last_outcome
	ok = _check(not bool(o.new_best) and int(o.stars_gained) == 0 and int(o.stars_now) == 0
			and str(o.star_key) == "hometown:1", "stars: a loss gives none") and ok
	record_result({"won": true})
	o = last_outcome
	ok = _check(bool(o.new_best) and int(o.stars_gained) == 2 and int(o.stars_game) == 2 and int(o.stars_before) == 0
			and int(o.stars_now) == 2 and Stars.best("hometown:1") == 2 and not bool(o.replay),
			"stars: a Normal win = 2, new best") and ok
	var ar: Dictionary = after_result()
	ok = _check(ar.screen == "points" and ar.args.get("then", "") == "lineup" and resume_screen() == "points",
			"stars: then the points screen (CONTINUE too)") and ok
	# CONTINUE on the per-win points screen: the save keeps "win_points"
	var d: Dictionary = to_dict()
	d["version"] = Save.VERSION
	ok = _check(from_dict(d) and phase == "win_points" and resume_screen() == "points" and game == 2,
			"stars: CONTINUE resumes on the points screen") and ok
	finish_points()
	level = "hard"
	record_result({"won": true})
	o = last_outcome
	ok = _check(int(o.stars_gained) == 3 and int(o.stars_before) == 2 and int(o.stars_now) == 5
			and Stars.rewards_between(int(o.stars_before), int(o.stars_now)).is_empty(), "stars: a Hard win = 3") and ok
	level = "easy"
	record_result({"won": true})
	o = last_outcome
	ok = _check(int(o.stars_gained) == 1 and bool(o.city_done) and int(o.stars_now) == 6
			and Stars.rewards_between(int(o.stars_before), int(o.stars_now)).size() == 1, "stars: Easy boss = 1, "
			+ "reward at 6") and ok
	game = 1   # white box: the same game won again on Hard (a replay later): the best goes up, no points
	phase = "map"
	level = "hard"
	record_result({"won": true})
	o = last_outcome
	ok = _check(int(o.stars_gained) == 1 and int(o.stars_game) == 3 and int(o.points_each) == 0
			and Stars.real_total() == 7, "stars: a better win raises the best, pays no points") and ok
	record_result({"won": true})
	ok = _check(int(last_outcome.stars_gained) == 0 and not bool(last_outcome.new_best) and Stars.real_total() == 7,
			"stars: the same level again gains none") and ok
	# the 1.0.0 credit: every won game at the save's level, once (needs the P8-01 fixture)
	var fpath: String = FIXTURE_DIR + "trip_v1_chicago.json"
	if FileAccess.file_exists(fpath):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STARS_TEST_PATH))
		var jd = JSON.parse_string(FileAccess.get_file_as_string(fpath))
		var fd: Dictionary = jd if jd is Dictionary else {}
		var got: int = _credit_v1_stars() if from_dict(fd) and loaded_version == 1 else -1
		var again: int = _credit_v1_stars()
		ok = _check(got == 4 and again == 0 and Stars.real_total() == 4 and Stars.best("chicago:1") == 1
				and Stars.best("chicago:2") == 0, "stars: 1.0.0 save credited once (4 games on Easy)") and ok
	else:
		print("TRIPDATA fixture %s: not here, skipped" % fpath)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STARS_TEST_PATH))
	Stars._path_override = ""
	Stars.force_total = old_force
	_star_test = false
	saving = was
	_reset()
	return ok

# P8-14: slots by star count (Stars.force_total, like --stars N), the pool after Hometown / Chicago / a New York
# round, a draft fills a slot (his city's ratings, 0 points, via draft, your colors), is final, survives a save round
# trip, and every refusal (not beaten, on the roster, no slot, the recruit screen's pick). In memory, nothing saved.
static func _check_draft() -> bool:
	var was: bool = saving
	saving = false
	var old_force: int = Stars.force_total
	var ok := true
	Stars.force_total = 0
	new_trip("normal")
	ok = _check(slot_count() == 0 and open_slots() == 0 and roster_limit() == 3 and draft_pool().is_empty(),
			"draft: 0 stars, no slot, empty pool") and ok
	for t in [[11, 0], [12, 1], [24, 2], [35, 2], [36, 3], [48, 4], [72, 4]]:
		Stars.force_total = int(t[0])
		ok = _check(open_slots() == int(t[1]) and roster_limit() == 3 + int(t[1]),
				"draft: %d stars = %d slots" % [int(t[0]), int(t[1])]) and ok
	Stars.force_total = 12
	ok = _check(not draft("ht_a1") and draft_refusal("ht_a1") == "not from a crew beaten on this trip"
			and draft_refusal("ud_jojo") == "already on the roster" and draft_refusal("ghost") == "unknown player",
			"draft: refuses an unbeaten crew, the roster, an unknown id") and ok
	for i in GAMES_PER_CITY:
		record_result({"won": true})
	finish_points()
	ok = _check(phase == "recruit" and _pool_ids() == ["ht_a1", "ht_a2"] and not can_draft("ht_boss"),
			"draft: on the recruit screen the pool is County Line's average players") and ok
	recruit("ht_g1")
	var rows: Array = draft_pool_by_crew()
	ok = _check(city == "chicago" and _pool_ids() == ["ht_boss", "ht_g2", "ht_a1", "ht_a2"] and rows.size() == 1
			and str(rows[0].name) == "COUNTY LINE" and str(rows[0].city) == "hometown" and int(rows[0].round) == 0
			and bool(rows[0].players[0].boss) and not bool(rows[0].players[1].boss),
			"draft: after Hometown, County Line minus the recruit") and ok
	ok = _check(not draft("chi_g1") and draft("ht_boss") and str(_entry("ht_boss").via) == DRAFT_VIA
			and player_points("ht_boss") == 0 and _entry("ht_boss").ratings == city_ratings("ht_boss", 1)
			and str(roster_player("ht_boss").sheet).begins_with("ht_boss_crew") and drafted_ids() == ["ht_boss"],
			"draft: the boss joins at 40 + 20, 0 points, via draft, your colors") and ok
	ok = _check(open_slots() == 0 and roster_limit() == 5 and roster_ids().size() == 5 and not draft("ht_a1")
			and draft_refusal("ht_a1") == "no open slot" and draft_refusal("ht_boss") == "already on the roster",
			"draft: the slot is filled, no second draft") and ok
	ok = _check(set_starters(["ht_boss", "ud_jojo", "ud_deuce"]) and starters_ok(["ht_boss", "ht_g1", "ud_tank"]) == ""
			and starters_ok(["ht_boss", "ht_boss", "ud_tank"]) != "" and starters_ok(["ht_a1", "ud_jojo", "ud_tank"]) != "",
			"draft: a drafted player starts") and ok
	record_result({"won": true})
	ok = _check(player_points("ht_boss") == POINTS_CITY_GAME, "draft: a drafted starter earns points") and ok
	Stars.force_total = 48
	for i in GAMES_PER_CITY - 1:
		record_result({"won": true})
	finish_points()
	recruit("chi_g1")
	rows = draft_pool_by_crew()
	ok = _check(open_slots() == 3 and rows.size() == 2 and str(rows[1].city) == "chicago"
			and (rows[0].players as Array).size() == 3 and (rows[1].players as Array).size() == 4,
			"draft: after Chicago, 2 crews (3 + 4), 3 slots open at 48 stars") and ok
	ok = _check(draft("chi_a1") and draft("ht_a2") and drafted_ids() == ["ht_boss", "chi_a1", "ht_a2"]
			and open_slots() == 1, "draft: average players from both crews") and ok
	# a save round trip keeps the drafts; fewer slots later (no --stars) keeps them too, with no slot open
	var dg: String = _digest()
	var d: Dictionary = JSON.parse_string(JSON.stringify(to_dict()))
	d["version"] = Save.VERSION
	Stars.force_total = 0
	ok = _check(from_dict(d) and _digest() == dg and drafted_ids().size() == 3 and open_slots() == 0
			and roster_ids().size() == 8, "draft: final, kept by the save (also with fewer slots)") and ok
	# New York: a round's crew is draftable once that round is won
	Stars.force_total = 72
	var guard := 10
	while city != "new_york" and city != "" and guard > 0:
		guard -= 1
		for i in GAMES_PER_CITY:
			record_result({"won": true})
		finish_points()
		var cands: Array = recruit_candidates()
		recruit(str((cands[0] as Dictionary).id))
	var before_ny: int = beaten_crews().size()
	record_result({"won": true})
	rows = draft_pool_by_crew()
	var last: Dictionary = rows[rows.size() - 1]
	ok = _check(city == "new_york" and before_ny == 7 and beaten_crews().size() == 8 and int(last.round) == 1
			and str(last.name) == "BRIDGE RUNNERS" and (last.players as Array).size() == 3 and can_draft("ny_q1")
			and draft("ny_q1") and _entry("ny_q1").ratings == city_ratings("ny_q1", 8) and open_slots() == 0,
			"draft: a won New York round's crew (stage 8)") and ok
	new_trip("normal")
	ok = _check(drafted_ids().is_empty() and open_slots() == 4 and draft_pool().is_empty(),
			"draft: a new trip starts with empty slots") and ok
	Stars.force_total = old_force
	saving = was
	_reset()
	return ok

# P8-17: the replay rules, in memory (saving off; stars in their own scratch file like _check_stars): only won games,
# only between games; the stage reached; LEGEND bonus and BOSS_CAP; stars only (no points, record, story, paid,
# seen); the trip never moves; the marker survives a save round trip and is dropped when it doesn't fit; New York
# rounds once won; a finished trip resumes on the map and replays every game.
static func _check_replays() -> bool:
	var was: bool = saving
	saving = false
	_star_test = true
	var old_force: int = Stars.force_total
	Stars.force_total = -1
	Stars._path_override = STARS_TEST_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STARS_TEST_PATH))
	var ok := true
	new_trip("normal")
	ok = _check(not can_replay("hometown", 1) and not start_replay("hometown", 1) and not replaying()
			and stage_reached() == 1 and replay_games().is_empty(), "replay: nothing won, nothing to replay") and ok
	record_result({"won": true})
	ok = _check(phase == "win_points" and not can_replay("hometown", 1), "replay: not with the points screen pending") \
			and ok
	finish_points()
	ok = _check(can_replay("hometown", 1) and not can_replay("hometown", 2) and not can_replay("hometown", 0)
			and not can_replay("hometown", 4) and not can_replay("chicago", 1) and not can_replay("nowhere", 1)
			and replay_games().size() == 1, "replay: a won game of the city being played, only that one") and ok
	for i in 2:
		record_result({"won": true})
	ok = _check(phase == "points" and not can_replay("hometown", 1), "replay: not on the after-city points step") and ok
	finish_points()
	ok = _check(phase == "recruit" and not can_replay("hometown", 2), "replay: not on the recruit step") and ok
	recruit("ht_g1")
	ok = _check(city == "chicago" and stage_reached() == 2 and replay_games().size() == 3,
			"replay: in Chicago, stage 2 reached, Hometown's 3 games") and ok
	# a lost replay: nothing moves, no first_loss story, back to the map
	var before: String = _digest()
	var pts: int = points
	ok = _check(start_replay("hometown", 1) and replaying() and resume_screen() == "lineup"
			and str(Flow.match.get("city", "")) == "hometown" and bool(Flow.match.get("replay", false)),
			"replay: start sets the marker and Flow.match, CONTINUE = lineup") and ok
	var m: Dictionary = match_for()
	var raised := true
	var ids: Array = crew_for_game("hometown", 1)
	for i in ids.size():
		raised = raised and str(m.teams[1].players[i].id) == str(ids[i]) \
				and _same_stats(m.teams[1].players[i].ratings, city_ratings(str(ids[i]), 2))
	ok = _check(raised and int(m.stage) == 2 and int(m.game) == 1 and int(m.target) == 11 and str(m.twist) == "none"
			and str(m.label) == REPLAY_LABEL + "HOMETOWN - GAME 1 OF 3" and str(m.look) == look_for("hometown")
			and str(m.teams[0].players[0].id) == human, "replay: Hometown game 1's crew and court at stage 2") and ok
	var own: Dictionary = match_for("hometown", 2)
	ok = _check(int(own.stage) == 1 and not bool(own.replay) and int(match_for("chicago", 1).stage) == 2
			and not bool(match_for("chicago", 1).replay), "replay: other matches keep their own stage") and ok
	# the marker survives a save round trip; a marker that doesn't fit is dropped
	var d: Dictionary = JSON.parse_string(JSON.stringify(to_dict()))
	d["version"] = Save.VERSION
	ok = _check(from_dict(d) and replaying() and str(replay.city) == "hometown" and int(replay.game) == 1
			and resume_screen() == "lineup", "replay: the marker is saved, CONTINUE resumes it") and ok
	for bad in [{"city": "chicago", "game": 1}, {"city": "hometown", "game": 7}, {"city": "nowhere", "game": 1}, 5]:
		var bd: Dictionary = d.duplicate(true)
		bd["replay"] = bad
		ok = _check(from_dict(bd) and not replaying() and resume_screen() == "map",
				"replay: marker %s dropped on load" % JSON.stringify(bad)) and ok
	from_dict(d)
	record_result({"won": false})
	var o: Dictionary = last_outcome
	ok = _check(not replaying() and bool(o.replay) and not bool(o.first_loss) and int(o.points_each) == 0
			and str(o.city) == "hometown" and int(o.game) == 1 and after_result().screen == "map"
			and (after_result().args as Dictionary).is_empty() and _digest() == before and not seen.has("first_loss"),
			"replay: a loss costs nothing, no story, back to the map") and ok
	# a won replay on Hard: stars only
	level = "hard"
	before = _digest()
	start_replay("hometown", 3)
	m = match_for()
	ok = _check(str(m.level) == "hard" and str(m.teams[1].players[2].id) == "ht_boss"
			and int(m.teams[1].players[2].ratings.speed) == Cities.stage_avg(2) + 20,
			"replay: the boss game at stage 2 (stage avg + 20)") and ok
	record_result({"won": true})
	o = last_outcome
	ok = _check(bool(o.won) and bool(o.replay) and int(o.points_each) == 0 and int(o.points_won) == 0
			and int(o.stars_gained) == 1 and int(o.stars_game) == 3 and bool(o.new_best) and points == pts
			and not bool(o.city_done) and after_result().screen == "map" and _digest() == before and not replaying(),
			"replay: a win on Hard = +1 star (2 -> 3), no points, record, paid or city change") and ok
	ok = _check(int(record.wins) == 3 and int(record.losses) == 0 and city == "chicago" and game == 1 and phase == "map"
			and paid.size() == 3, "replay: record 3-0, Chicago game 1, 3 games paid") and ok
	# cancel: back out of a replay's lineup
	start_replay("hometown", 2)
	ok = _check(cancel_replay() and not replaying() and not cancel_replay() and str(match_for().label) ==
			"CHICAGO - GAME 1 OF 3" and not bool(match_for().replay) and resume_screen() == "map",
			"replay: cancel drops the marker, the trip's own game again") and ok
	# LEGEND: the opponents' bonus, capped at BOSS_CAP; no bonus for recruits / drafts or on other levels
	var bonus: int = rating_bonus("legend")
	level = "legend"
	m = match_for("chicago", 1)
	var with_bonus := true
	for pd in m.teams[1].players:
		var base: Dictionary = city_ratings(str(pd.id), 2)
		for st in Ratings.STATS:
			with_bonus = with_bonus and int(pd.ratings[st]) == mini(int(base[st]) + bonus, BOSS_CAP)
	var boss8: Dictionary = city_ratings("ny_boss", 8, "legend")
	var plain8: Dictionary = city_ratings("ny_boss", 8)
	var capped := true
	for st in Ratings.STATS:
		capped = capped and int(boss8[st]) == mini(int(plain8[st]) + bonus, BOSS_CAP) and int(boss8[st]) <= BOSS_CAP
	ok = _check(bonus > 0 and with_bonus and capped and int(plain8.speed) + bonus > BOSS_CAP
			and int(boss8.speed) == BOSS_CAP and _same_stats(city_ratings("ht_boss", 1, "hard"), city_ratings("ht_boss", 1))
			and rating_bonus("normal") == 0 and rating_bonus("easy") == 0 and rating_bonus("hard") == 0,
			"LEGEND: +%d on the opponents, capped at %d (ny_boss %d)" % [bonus, BOSS_CAP, int(boss8.speed)]) and ok
	Stars.force_total = 12
	for i in GAMES_PER_CITY:
		record_result({"won": true})
	finish_points()
	recruit("chi_g1")
	draft("chi_a1")
	ok = _check(_same_stats(_entry("chi_g1").ratings, city_ratings("chi_g1", 2))
			and _same_stats(_entry("chi_a1").ratings, city_ratings("chi_a1", 2)) and drafted_ids() == ["chi_a1"],
			"LEGEND: recruits and drafts join without the bonus") and ok
	Stars.force_total = -1
	level = "normal"
	# New York: a round is replayable once won; the bracket never moves
	var guard := 10
	while city != "new_york" and city != "" and guard > 0:
		guard -= 1
		for i in GAMES_PER_CITY:
			record_result({"won": true})
		finish_points()
		recruit(str((recruit_candidates()[0] as Dictionary).id))
	ok = _check(city == "new_york" and stage_reached() == 8 and not can_replay("new_york", 1)
			and can_replay("memphis", 2) and replay_games().size() == 21, "replay: in New York, 21 city games") and ok
	record_result({"won": true})
	ok = _check(phase == "bracket" and can_replay("new_york", 1) and not can_replay("new_york", 2),
			"replay: a New York round once won") and ok
	before = _digest()
	start_replay("new_york", 1)
	m = match_for()
	ok = _check(str(m.label) == REPLAY_LABEL + "NEW YORK - QUARTERFINAL" and int(m.stage) == 8,
			"replay: the quarterfinal") and ok
	record_result({"won": true})
	ok = _check(bracket_round() == 1 and game == 2 and phase == "bracket" and _digest() == before
			and after_result().screen == "map" and resume_screen() == "bracket", "replay: the bracket stays") and ok
	start_replay("hometown", 1)
	record_result({"won": false})
	ok = _check(bracket_round() == 1 and _digest() == before and after_result().screen == "map",
			"replay: a lost replay in New York, the bracket stays") and ok
	# the trip done: CONTINUE = the map, every game replayable at the last stage
	record_result({"won": true})
	record_result({"won": true})
	ok = _check(is_done() and resume_screen() == "map" and stage_reached() == 8 and replay_games().size() == 24
			and can_replay("hometown", 1) and can_replay("new_york", 3) and record_result({"won": true}).is_empty(),
			"replay: trip done, CONTINUE = map, all 24 games") and ok
	before = _digest()
	ok = _check(start_replay("hometown", 2) and int(match_for().stage) == 8 and resume_screen() == "lineup",
			"replay: after the trip, Hometown at stage 8") and ok
	var w: int = int(record.wins)
	record_result({"won": true})
	ok = _check(is_done() and _digest() == before and int(record.wins) == w and not replaying()
			and after_result().screen == "map", "replay: the trip stays done") and ok
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STARS_TEST_PATH))
	Stars._path_override = ""
	Stars.force_total = old_force
	_star_test = false
	saving = was
	_reset()
	return ok

# P8-14b: the one-boss rule. starters_ok() / set_starters() refuse a second boss however he joined (recruited or
# drafted), any order; one boss is fine; the best roster is legal (also in _check_best_rosters); a version 2 save with
# 2 boss starters is repaired on load (the first stays, the strongest non-boss bench player comes in, the note), and
# a legal one is not touched. In memory, nothing saved.
static func _check_boss_rule() -> bool:
	var was: bool = saving
	saving = false
	var old_force: int = Stars.force_total
	var ok := true
	Stars.force_total = 12
	new_trip("normal")
	for i in GAMES_PER_CITY:
		record_result({"won": true})
	finish_points()
	recruit("ht_boss")
	for i in GAMES_PER_CITY:
		record_result({"won": true})
	finish_points()
	recruit("chi_g1")
	ok = _check(draft("chi_boss") and is_boss("chi_boss") and is_boss("ht_boss") and not is_boss("chi_g1")
			and not is_boss("ud_jojo"), "boss rule: a recruited and a drafted boss on the roster") and ok
	var before: Array = starters.duplicate()
	ok = _check(starters_ok(["ht_boss", "chi_boss", "ud_jojo"]) == BOSS_RULE
			and starters_ok(["ud_jojo", "chi_boss", "ht_boss"]) == BOSS_RULE
			and not set_starters(["chi_boss", "ud_tank", "ht_boss"], "ud_tank") and starters == before,
			"boss rule: two bosses refused, the lineup stays") and ok
	ok = _check(starters_ok(["chi_boss", "chi_g1", "ud_jojo"]) == "" and set_starters(["ud_jojo", "ht_boss", "chi_g1"])
			and set_starters(["chi_boss", "ud_tank", "ud_deuce"], "ud_tank") and human == "ud_tank",
			"boss rule: one boss starts (recruited or drafted)") and ok
	_start_strongest()
	ok = _check(starters_ok(starters) == "" and boss_count(starters) == 1 and starters.has("chi_boss")
			and str(starters[0]) == "chi_boss", "boss rule: the strongest legal three %s" % str(starters)) and ok
	# a version 2 save with 2 boss starters (a hand edit, an older build): repaired on load
	var d: Dictionary = JSON.parse_string(JSON.stringify(to_dict()))
	d["version"] = Save.VERSION
	d["starters"] = ["ud_deuce", "ht_boss", "chi_boss"]
	d["human"] = "ud_deuce"
	var strongest := ""
	var hi: int = -1
	for id in ["ud_jojo", "ud_tank", "chi_g1"]:
		if _sum_of(_entry(id).ratings) > hi:
			hi = _sum_of(_entry(id).ratings)
			strongest = id
	ok = _check(from_dict(d) and starters == ["ud_deuce", "ht_boss", strongest] and boss_repair == ["chi_boss"]
			and human == "ud_deuce" and boss_repair_note().contains("BIG LOU"),
			"boss rule: a version 2 save with 2 bosses repaired (%s)" % boss_repair_note()) and ok
	d["starters"] = ["ht_boss", "ud_jojo", "chi_g1"]
	ok = _check(from_dict(d) and starters == ["ht_boss", "ud_jojo", "chi_g1"] and boss_repair.is_empty()
			and boss_repair_note() == "", "boss rule: a legal save is not touched") and ok
	new_trip("normal")
	ok = _check(boss_repair.is_empty(), "boss rule: a new trip has no repair note") and ok
	Stars.force_total = old_force
	saving = was
	_reset()
	return ok

# the 5 stats of two ratings dicts are the same
static func _same_stats(a: Dictionary, b: Dictionary) -> bool:
	for st in Ratings.STATS:
		if int(a.get(st, -1)) != int(b.get(st, -2)):
			return false
	return true

static func _pool_ids() -> Array:
	var out: Array = []
	for p in draft_pool():
		out.append(str(p.id))
	return out

# The 1.0.0 saves (P8-01, docs/qa/fixtures/trip_v1_*.json) load and migrate (from_dict, in memory, nothing saved):
# the level, where CONTINUE goes, crew points = pool + catch-up, the paid games, nobody's own points, "via", the
# starters as saved (trip_v1_bosses.json's 3 boss starters repaired to 1: V1_BOSS_REPAIR), and a version 2 round trip
# of the migrated state. A missing fixture (an exported build has no docs/) is skipped.
const FIXTURE_DIR := "res://docs/qa/fixtures/"
const V1_FIXTURES := {   # file: [level, resume screen, crew points, paid games]
	"trip_v1_chicago.json": ["easy", "map", 5 + 6 + 1, 4],       # pool 5, Hometown, Chicago game 1 won
	"trip_v1_points.json": ["normal", "points", 8 + 3 * 6, 9],   # pool 8, 3 cities
	"trip_v1_bosses.json": ["hard", "map", 2 + 3 * 6 + 1, 10],   # pool 2, 3 cities, New Orleans game 1 won
	"trip_v1_ny.json": ["normal", "bracket", 1 + 7 * 6 + 4, 22],   # pool 1, 7 cities, round 1 won
	"trip_v1_done.json": ["normal", "map", 2 + 7 * 6 + 3 * 4, 24],   # pool 2, the whole trip (CONTINUE: the map, P8-17)
}
# P8-14b: trip_v1_bosses.json starts chi_boss (you), ht_boss, mem_boss: Big Lou stays, the strongest non-bosses on the
# bench (Jojo 280, Deuce 278) take the other two places
const V1_BOSS_REPAIR := {"trip_v1_bosses.json": [["chi_boss", "ud_jojo", "ud_deuce"], ["ht_boss", "mem_boss"]]}

static func _check_v1_fixtures() -> bool:
	var was: bool = saving
	saving = false
	var ok := true
	for fname in V1_FIXTURES:
		var path: String = FIXTURE_DIR + str(fname)
		if not FileAccess.file_exists(path):
			print("TRIPDATA fixture %s: not here, skipped" % path)
			continue
		var want: Array = V1_FIXTURES[fname]
		var jd = JSON.parse_string(FileAccess.get_file_as_string(path))
		var d: Dictionary = jd if jd is Dictionary else {}
		var loaded: bool = from_dict(d)
		var own := 0
		var vias_ok := true
		for e in roster_data:
			own += int(e["pts"])
			vias_ok = vias_ok and str(e["via"]) == _via_of(str(e["id"]))
		var same_starters: bool = d.get("starters", []) == starters and boss_repair.is_empty()
		if V1_BOSS_REPAIR.has(fname):
			var rp: Array = V1_BOSS_REPAIR[fname]
			same_starters = starters == rp[0] and boss_repair == rp[1] and human == str(rp[0][0]) \
					and boss_count(d.get("starters", [])) == 3 and boss_repair_note() != ""
			print("TRIPDATA   %s: starters %s -> %s, note: %s" % [fname, str(d.get("starters", [])), str(starters),
					boss_repair_note()])
		var same_roster: bool = (d.get("roster", []) as Array).size() == roster_data.size()
		var good: bool = loaded and loaded_version == 1 and level == str(want[0]) and resume_screen() == str(want[1]) \
				and crew_points == int(want[2]) and points == crew_points and own == 0 and paid.size() == int(want[3]) \
				and vias_ok and same_starters and same_roster
		# the migrated trip saved as version 2 and loaded again is the same trip, no second catch-up
		var digest: String = _digest()
		var d2: Dictionary = to_dict()
		d2["version"] = Save.VERSION
		var again: bool = from_dict(JSON.parse_string(JSON.stringify(d2))) and _digest() == digest \
				and loaded_version == Save.VERSION and boss_repair.is_empty()
		ok = _check(good and again, "1.0.0 save %s: %s, crew %d, paid %d" % [str(fname).get_basename(), resume_screen(),
				crew_points, paid.size()]) and ok
		if not (good and again):
			print("TRIPDATA   loaded: " + _digest())
		# a version 2 trip that a 1.0.0 build saved again (version 1, the mark kept in seen): no second catch-up
		var back: Dictionary = d.duplicate(true)
		(back["seen"] as Array).append(RULE_MARK)
		ok = _check(from_dict(back) and crew_points == _int_in(d.get("points", 0), 0, MAX_POINTS),
				"  saved again by 1.0.0: no second catch-up (crew %d)" % crew_points) and ok
	saving = was
	_reset()
	return ok

# the save file: write + read back, then broken files of every kind = no trip, never a crash
static func _check_save_files() -> bool:
	var ok := true
	var p: String = Save.path()
	Save.erase()
	ok = _check(not continue_trip() and not active, "missing save = no trip") and ok
	for bad in ["", "{", "not json at all", "[1, 2, 3]", "{\"city\": \"hometown\"}", "{\"version\": \"x\"}"]:
		_write_raw(p, bad)
		ok = _check(not Save.exists() and not continue_trip(), "broken save %-20s = no trip" % JSON.stringify(bad)) and ok
	# hand-edited / newer-version save: loads what fits
	_write_raw(p, JSON.stringify({"version": 99, "city": "nowhere", "game": 7, "points": -5, "level": "insane",
			"roster": [{"id": "ghost"}, {"id": "ud_jojo", "ratings": {"speed": 500, "shooting": "x"}}, 3],
			"starters": ["ud_jojo"], "beaten": "x", "record": {"wins": -1}}))
	ok = _check(continue_trip() and city == "hometown" and game == 3 and points == 0 and level == DEFAULT_LEVEL
			and roster_ids().size() == 3 and int(_entry("ud_jojo").ratings.speed) == 100
			and int(_entry("ud_jojo").ratings.shooting) == 50 and starters.size() == 3, "newer / odd save loads safely") and ok
	if not ok:
		print("TRIPDATA   loaded: " + _digest())
	# a left-over temp file that is newer wins (the rename never happened)
	new_trip("easy")
	var d: Dictionary = to_dict()
	d["version"] = Save.VERSION
	d["serial"] = 1000000
	d["crew_points"] = 4
	_write_raw(p + Save.TMP_SUFFIX, JSON.stringify(d))
	ok = _check(continue_trip() and points == 4 and crew_points == 4, "newer temp file wins") and ok
	_write_raw(p + Save.TMP_SUFFIX, "{broken")
	new_trip("easy")
	ok = _check(continue_trip() and points == 0 and level == "easy", "broken temp file ignored") and ok
	Save.erase()
	return ok

static func _write_raw(p: String, text: String) -> void:
	var f: FileAccess = FileAccess.open(p, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()

# the same trip every time: Hometown lost once then beaten, points spent, the boss recruited, a lineup, Chicago 1 won
static func _scripted_trip(quiet: bool) -> void:
	var was: bool = saving
	saving = false
	new_trip("hard")
	record_result({"won": false})
	mark_seen("trip_start")
	mark_seen("hometown_arrive")
	for i in 3:
		record_result({"won": true})
	after_result()
	spend("ud_jojo", "speed")
	spend("ud_jojo", "speed")
	spend("ud_tank", "defense")
	spend("ud_deuce", "stamina")
	finish_points()
	recruit("ht_boss")
	var force: int = Stars.force_total
	Stars.force_total = Stars.MAX   # P8-14: a draft too (the same in both processes, whatever --stars says)
	draft("ht_a2")
	Stars.force_total = force
	set_starters(["ud_jojo", "ht_boss", "ht_a2"], "ud_jojo")
	record_result({"won": true})
	saving = was
	if not quiet:
		print("TRIPDATA scripted trip: " + _digest())

static func _digest() -> String:
	return JSON.stringify(to_dict())

static func _check_loaded() -> bool:
	_scripted_trip(true)
	var want: String = _digest()
	_reset()
	var loaded: bool = continue_trip()
	var got: String = _digest()
	print("TRIPDATA loaded from %s: %s" % [Save.path(), "yes" if loaded else "NO (" + Save.last_error + ")"])
	print("TRIPDATA want %s" % want)
	print("TRIPDATA got  %s" % got)
	var same: bool = loaded and got == want
	print("TRIPDATA round trip across a restart: %s" % ("same state" if same else "DIFFERENT"))
	Save.erase()
	return same
