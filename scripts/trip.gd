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
#   - 2 stat points per win; each point +3 on one stat of one player; no stat above 90; spent after each city
#   - after a city: recruit ONE of its 2 good players or the boss (he keeps his ratings, wears your colors)
#   - roster = the 3 underdogs + recruits; 3 starters picked before each game (remembered); starter 0 = you
#   - level (easy / normal / hard) picked at trip start, changeable (set_level)
#   - fixed route (cities.gd ROUTE), cities with "built": false are skipped, no replays
#   - New York tournament: 3 rounds, all to 21; a loss replays that round
# Phases (where CONTINUE resumes): "map" (next game from the map), "points" (spend after a city), "recruit",
# "bracket" (New York), "done" (trip complete).
# Test: godot --headless --path . -- --triptest-data           prints every city game's lineups + save checks,
#       godot --headless --path . -- --triptest-data --load    (a second process) loads that save and compares.
# Both use user://trip_test.json (save.gd), never the owner's save.
# Phase 6 (P6-10): match_for() adds the city's "twist"; a city look or track that doesn't exist yet falls back to the
# city's "fallback" look / music; --expected-roster (with --city) plays a city game with the crew a trip would have
# there (expected_roster()); a won boss game unlocks the city's court for Quick Game (P6-17, Difficulty.unlock_court).

const Flow = preload("res://scripts/flow.gd")
const Cities = preload("res://scripts/cities.gd")
const Ratings = preload("res://scripts/ratings.gd")
const Save = preload("res://scripts/save.gd")
const Looks = preload("res://scripts/court_looks.gd")      # which look ids exist (city look or its fallback)
const StoryText = preload("res://scripts/story_text.gd")   # the data check: every scene a city names exists
const DIFFICULTY_PATH := "res://scripts/difficulty.gd"     # loaded at call time: unlock_court() (P6-17) if it exists
const MUSIC_DIR := "res://assets/music/"                   # <music>.ogg (audio.gd); missing = the city's fallback
const EXPECTED_ROSTER_FLAG := "--expected-roster"          # test flag (with --city): the crew a trip would have there

const LEVELS := ["easy", "normal", "hard"]   # difficulty.gd NAMES
const DEFAULT_LEVEL := "normal"     # a trip with no level given; also the --city test matches
const POINTS_PER_WIN := 2           # owner Q5 a
const POINT_GAIN := 3               # one point = +3 on one stat
const STAT_CAP := 90                # spending stops at 90 (starting ratings may be higher; they are not lowered)
const GAMES_PER_CITY := 3
const STARTERS := 3
const TOURNAMENT_POINTS := true     # tournament wins also earn points (owner: "2 per win"); spendable on the bracket
const SPEND_PHASES := ["points", "bracket"]   # where spend() is allowed (the points screen; between NY rounds)
const PHASES := ["map", "points", "recruit", "bracket", "done"]
const MAX_POINTS := 999             # sanity cap for a loaded save

# --- the trip (static: survives scene reloads) ---
static var active := false          # a trip is loaded (new_trip / continue_trip)
static var level := DEFAULT_LEVEL
static var city := ""               # the city being played (stays the beaten city during points / recruit)
static var game := 1                # 1..3 in a city; in New York = bracket round + 1
static var beaten: Array = []       # city ids, in route order
static var points := 0              # unspent stat points
static var roster_data: Array = []  # [{"id": String, "ratings": {speed, shooting, finishing, defense, stamina}}]
static var starters: Array = []     # 3 roster ids; the human plays starters[0] (== human)
static var human := ""
static var bracket := {"round": 0}  # New York: rounds won so far (0..3)
static var seen: Array = []         # story scene ids already shown
static var record := {"wins": 0, "losses": 0}
static var phase := "map"
static var last_outcome := {}       # record_result()'s answer, for the result screen (see record_result)
static var _spend_log: Array = []   # [[id, stat, old], ...] this points session, for undo_spend()
static var saving := true           # false = state changes are not written (tests)

# ---------------- starting, continuing, saving ----------------

# A fresh trip at Hometown (the title asks to confirm before calling this over an existing save). Saved at once.
static func new_trip(lv: String = DEFAULT_LEVEL) -> void:
	_reset()
	active = true
	level = lv if LEVELS.has(lv) else DEFAULT_LEVEL
	save()

# Loads the save; true when a trip was loaded. A missing or broken save = false, and the state is left empty.
static func continue_trip() -> bool:
	var d: Dictionary = Save.read()
	if d.is_empty():
		active = false
		return false
	return from_dict(d)

# a valid save exists (the title shows CONTINUE)
static func has_save() -> bool:
	return Save.exists()

# the screen CONTINUE goes to: "map", "points", "recruit", "bracket", or "title" when the trip is done
static func resume_screen() -> String:
	if not active or phase == "done":
		return "title"
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

static func to_dict() -> Dictionary:
	return {
		"level": level, "city": city, "game": game, "beaten": beaten.duplicate(), "points": points,
		"roster": roster_data.duplicate(true), "starters": starters.duplicate(), "human": human,
		"bracket": bracket.duplicate(), "seen": seen.duplicate(), "record": record.duplicate(), "phase": phase,
	}

# Loads a saved dictionary, checking every field (unknown ids dropped, numbers clamped, missing fields = the
# defaults), so an old, newer or hand-edited save still gives a playable trip. False only when it isn't a trip at all.
static func from_dict(d: Dictionary) -> bool:
	var ver: int = int(d.get("version", 0))
	if ver < 1:
		return false
	if ver > Save.VERSION:
		push_warning("Trip: save version %d is newer than %d; loading what fits" % [ver, Save.VERSION])
	_reset()
	active = true
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
			roster_data.append({"id": id, "ratings": rt})
	for id in Cities.START_CREW:
		if not _on_roster(id):
			roster_data.append({"id": id, "ratings": _start_ratings(id)})
	# starters and the human
	var st = d.get("starters", [])
	var ids: Array = []
	if st is Array:
		for e in st:
			ids.append(str(e))
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
	if beaten.has(city) and (phase == "map" or phase == "bracket"):
		city = next_city(city)   # a beaten city is never replayed (Q7)
		phase = "map"
	if city == "":
		phase = "done"
	var bd = d.get("bracket", {})
	var br: int = int(bd.get("round", 0)) if bd is Dictionary else 0
	bracket = {"round": clampi(br, 0, _rounds(city).size())}
	var gv = d.get("game", 1)
	game = clampi(int(gv) if (gv is int or gv is float) else 1, 1, GAMES_PER_CITY)
	if is_tournament(city):
		game = clampi(int(bracket["round"]) + 1, 1, maxi(1, _rounds(city).size()))
	var pv = d.get("points", 0)
	points = clampi(int(pv) if (pv is int or pv is float) else 0, 0, MAX_POINTS)
	var sn = d.get("seen", [])
	if sn is Array:
		for e in sn:
			if not seen.has(str(e)):
				seen.append(str(e))
	var rc = d.get("record", {})
	if rc is Dictionary:
		record = {"wins": maxi(0, int(rc.get("wins", 0))), "losses": maxi(0, int(rc.get("losses", 0)))}
	return true

static func _reset() -> void:
	active = false
	level = DEFAULT_LEVEL
	city = _first_unbeaten_of([])
	game = 1
	beaten = []
	points = 0
	roster_data = []
	for id in Cities.START_CREW:
		roster_data.append({"id": id, "ratings": _start_ratings(id)})
	starters = Cities.START_CREW.duplicate()
	human = str(starters[0])
	bracket = {"round": 0}
	seen = []
	record = {"wins": 0, "losses": 0}
	phase = "map"
	last_outcome = {}
	_spend_log = []

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

# a city player's ratings at a trip stage: STAGE_AVG + TIER.all on every stat, + TIER.spec on his specialties
static func city_ratings(id: String, stage: int) -> Dictionary:
	var p: Dictionary = Cities.player(id)
	var tier: Dictionary = Cities.TIER.get(str(p.get("tier", "avg")), Cities.TIER["avg"])
	var spec: Array = p.get("spec", [])
	var out: Dictionary = {}
	for s in Ratings.STATS:
		var v: int = Cities.stage_avg(stage) + int(tier.get("all", 0))
		if spec.has(s):
			v += int(tier.get("spec", 0))
		out[s] = clampi(v, Ratings.MIN_RATING, Ratings.MAX_RATING)
	return out

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
		out.append({"id": id, "ratings": _start_ratings(id)})
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

# Picks the 3 starters (roster ids, all different); the human plays `who` (one of them; "" = the first). Saved.
# False (nothing changed) when the ids aren't 3 different roster players.
static func set_starters(ids: Array, who: String = "", do_save: bool = true) -> bool:
	var roster_list: Array = roster_ids()
	var picked: Array = []
	for e in ids:
		var id: String = str(e)
		if not roster_list.has(id) or picked.has(id):
			return false
		picked.append(id)
	if picked.size() != STARTERS:
		return false
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

# Builds the match config (board "Match config") for game n of a city ("" / 0 = the trip's current city and game),
# sets Flow.match to it and returns it. {} for an unknown or not-built city. Without a loaded trip (the --city tests)
# your side is the 3 underdogs at their starting ratings, level DEFAULT_LEVEL.
static func match_for(city_id: String = "", n: int = 0) -> Dictionary:
	if city_id == "":
		city_id = city
	if n <= 0:
		n = game if city_id == city else 1
	var c: Dictionary = Cities.city(city_id)
	if c.is_empty() or not bool(c.get("built", false)):
		return {}
	if not active and OS.get_cmdline_user_args().has(EXPECTED_ROSTER_FLAG):
		return _expected_match(city_id, n)
	var stage: int = int(c.get("stage", 1))
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
	var mine: Array = []
	var lineup: Array = starters if active and starters.size() == STARTERS else Cities.START_CREW
	for id in lineup:
		mine.append(roster_player(str(id)))
	var theirs: Array = []
	for id in crew_for_game(city_id, n):
		theirs.append(player_dict(str(id), city_ratings(str(id), stage), false))
	var m := {
		"mode": "trip",
		"label": label,
		"target": Cities.game_target(city_id, n),
		"look": look_for(city_id), "music": music_for(city_id), "twist": Cities.twist(city_id),
		"level": level if active else DEFAULT_LEVEL,
		"city": city_id, "game": n, "stage": stage,
		"teams": [
			{"name": Cities.CREW_NAME, "style": "", "players": mine},
			{"name": str(crew.get("name", "")), "style": str(crew.get("style", "")), "players": theirs},
		],
	}
	Flow.match = m
	return m

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

# ---------------- --expected-roster (QA, P6-30) ----------------

# Puts the trip state (in memory, nothing saved) where a trip would be at game n of city_id when every game is won
# on the first try and every screen takes the trip test's default choice (each screen's auto_step()):
#   - points (after_game.gd): one point at a time on the lowest stat (first in Ratings.STATS order on a tie) of the
#     first roster player who can still take one, until none is left;
#   - recruit (recruit.gd): the first candidate (the city's first good player);
#   - lineup (lineup.gd): keeps the starters it opens with, so the 3 underdogs start every game;
#   - New York: points won in earlier rounds stay unspent (the bracket's PLAY doesn't spend them).
# False for an unknown or not-built city. The caller clears the state (_reset()) when done.
static func expected_roster(city_id: String, n: int = 1) -> bool:
	if not Cities.is_built(city_id):
		return false
	var was: bool = saving
	saving = false
	new_trip(DEFAULT_LEVEL)
	var guard: int = Cities.ROUTE.size() + 1
	while city != "" and city != city_id and guard > 0:
		guard -= 1
		for i in GAMES_PER_CITY:
			record_result({"won": true})
		_auto_spend_all()
		finish_points()
		if phase == "recruit":
			var cands: Array = recruit_candidates()
			if cands.size() > 0:
				recruit(str((cands[0] as Dictionary).get("id", "")))
	if city != city_id:
		saving = was
		return false
	if is_tournament(city_id):
		var rounds: int = maxi(1, _rounds(city_id).size())
		for i in clampi(n, 1, rounds) - 1:
			record_result({"won": true})   # the earlier rounds won: +2 points each, unspent
		phase = "bracket"
	else:
		game = clampi(n, 1, GAMES_PER_CITY)
		points = POINTS_PER_WIN * (game - 1)   # this city's earlier games, not spent yet
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

# match_for() under --expected-roster with no trip loaded: the expected crew's match; the state is cleared after
static func _expected_match(city_id: String, n: int) -> Dictionary:
	if not expected_roster(city_id, n):
		_reset()
		return {}
	var m: Dictionary = match_for(city_id, n)
	var lines: Array = []
	for e in roster_data:
		var rt: Dictionary = e["ratings"]
		lines.append("%s %d/%d/%d/%d/%d" % [str(e["id"]), int(rt["speed"]), int(rt["shooting"]),
				int(rt["finishing"]), int(rt["defense"]), int(rt["stamina"])])
	print("EXPECTED ROSTER %s | starters %s | roster (spd/sht/fin/def/sta) %s" % [str(m.get("label", "")),
			", ".join(PackedStringArray(starters)), " | ".join(PackedStringArray(lines))])
	_reset()
	return m

# Records a finished trip game (flow.gd's game_finished calls it with Flow.last_result) and saves. Returns and keeps
# in last_outcome: {"won", "city", "game", "points_won", "city_done", "trip_done", "first_loss"}.
# Lost: the same game again. Won: +2 points; the next game, or after game 3 the city is beaten -> points phase.
# New York: a won round moves the bracket on (the final = trip done); a lost round is replayed.
static func record_result(result: Dictionary) -> Dictionary:
	if not active or phase == "done":
		return {}
	var won: bool = bool(result.get("won", false))
	var out := {"won": won, "city": city, "game": game, "points_won": 0, "city_done": false, "trip_done": false,
		"first_loss": false}
	if won:
		record["wins"] = int(record["wins"]) + 1
	else:
		record["losses"] = int(record["losses"]) + 1
		out["first_loss"] = not seen.has("first_loss")
	if is_tournament(city):
		phase = "bracket"
		if won:
			if TOURNAMENT_POINTS:
				out["points_won"] = award_points(POINTS_PER_WIN, false)
			bracket["round"] = bracket_round() + 1
			if bracket_round() >= _rounds(city).size():
				beaten.append(city)
				phase = "done"
				out["city_done"] = true
				out["trip_done"] = true
			else:
				game = bracket_round() + 1
	elif won:
		out["points_won"] = award_points(POINTS_PER_WIN, false)
		if game >= GAMES_PER_CITY:
			beaten.append(city)
			phase = "points"
			_spend_log = []
			out["city_done"] = true
		else:
			game += 1
			phase = "map"
	else:
		phase = "map"   # retry the same game, no penalty
	last_outcome = out
	save()
	if bool(out["city_done"]):
		_unlock_court(str(out["city"]))
	return out

# P6-17 hook: a won boss game (a city's game 3, or the New York final) unlocks that city's court for Quick Game.
# Only when difficulty.gd has unlock_court() (P6-17), and never in the in-memory test trips (saving off).
static func _unlock_court(city_id: String) -> void:
	if not saving or not ResourceLoader.exists(DIFFICULTY_PATH):
		return
	var d: GDScript = load(DIFFICULTY_PATH) as GDScript
	if d != null and d.has_method("unlock_court"):
		d.call("unlock_court", city_id)

# Where the result screen goes next: {"screen": String, "args": Dictionary} (Flow.go(r.screen, r.args)).
# Lost -> story "first_loss" once, then the lineup (retry). Won with games left -> lineup. City done -> the city's
# "won" story, then points. Tournament: back to the bracket; the final won -> story "ending", then the title.
static func after_result() -> Dictionary:
	var o: Dictionary = last_outcome
	if o.is_empty():
		return {"screen": "map", "args": {}}
	var next := "lineup"
	if bool(o.get("trip_done", false)):
		return _story_or("ending", "title")
	if is_tournament(str(o.get("city", ""))):
		next = "bracket"
	elif bool(o.get("city_done", false)):
		var st: Dictionary = Cities.city(str(o.get("city", ""))).get("story", {})
		return _story_or(str(st.get("won", "")), "points")
	if not bool(o.get("won", false)) and bool(o.get("first_loss", false)):
		return _story_or("first_loss", next)
	return {"screen": next, "args": {}}

# story scene first if not seen yet (marked seen here), else straight to `then`
static func _story_or(scene: String, then: String) -> Dictionary:
	if scene != "" and mark_seen(scene):
		return {"screen": "story", "args": {"scene": scene, "then": then}}
	return {"screen": then, "args": {}}

# ---------------- stat points ----------------

# adds stat points (2 per win); returns how many were added
static func award_points(n: int = POINTS_PER_WIN, do_save: bool = true) -> int:
	points = clampi(points + n, 0, MAX_POINTS)
	if do_save:
		save()
	return n

# true when one point can go into this stat of this player (points left, below the cap, in a spending phase)
static func can_spend(id: String, stat: String) -> bool:
	if not active or points <= 0 or not SPEND_PHASES.has(phase) or not Ratings.STATS.has(stat):
		return false
	var e: Dictionary = _entry(id)
	return not e.is_empty() and int(e["ratings"][stat]) < STAT_CAP

# one point: +3 on one stat of one roster player (to 90 at most). Saved. False when it can't.
static func spend(id: String, stat: String) -> bool:
	if not can_spend(id, stat):
		return false
	var e: Dictionary = _entry(id)
	var old: int = int(e["ratings"][stat])
	e["ratings"][stat] = mini(old + POINT_GAIN, STAT_CAP)
	points -= 1
	_spend_log.append([id, stat, old])
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
	points += 1
	save()
	return true

static func can_undo() -> bool:
	return not _spend_log.is_empty()

# the points screen's DONE: on to the recruit screen (or the map if nobody is left to recruit). Saved.
static func finish_points() -> void:
	_spend_log = []
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
	roster_data.append({"id": id, "ratings": _start_ratings(id)})
	_advance_city()
	save()
	return true

static func _advance_city() -> void:
	city = next_city(city)
	game = 1
	bracket = {"round": 0}
	phase = "map" if city != "" else "done"

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
	ok = _check_rules() and ok
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
	ok = _check(after_result().screen == "story" and after_result().screen == "lineup", "first loss story once") and ok
	record_result({"won": true})
	ok = _check(game == 2 and points == 2 and int(match_for().target) == 15, "a win: game 2 to 15, 2 points") and ok
	ok = _check(not spend("ud_deuce", "speed"), "no spending during the city") and ok
	record_result({"won": true})
	record_result({"won": true})
	ok = _check(phase == "points" and beaten == ["hometown"] and points == 6 and bool(last_outcome.city_done),
			"3 wins: Hometown beaten, 6 points") and ok
	var ar: Dictionary = after_result()
	ok = _check(ar.screen == "story" and ar.args.then == "points", "hometown_won story, then points") and ok
	var before: int = int(_entry("ud_tank").ratings.finishing)
	ok = _check(spend("ud_tank", "finishing") and int(_entry("ud_tank").ratings.finishing) == before + 3,
			"a point = +3") and ok
	ok = _check(undo_spend() and int(_entry("ud_tank").ratings.finishing) == before and points == 6, "undo") and ok
	award_points(10, false)   # 16: enough to reach the cap
	while spend("ud_deuce", "shooting"):
		pass
	ok = _check(int(_entry("ud_deuce").ratings.shooting) == STAT_CAP and points == 6, "cap at 90 (62 -> 90 in 10)") and ok
	finish_points()
	ok = _check(phase == "recruit" and recruit_candidates().size() == 3, "recruit: 3 candidates") and ok
	ok = _check(not recruit("ht_a1") and not recruit("chi_g1"), "only the city's good players or boss") and ok
	ok = _check(recruit("ht_boss") and city == "chicago" and game == 1 and phase == "map"
			and roster_ids().size() == 4, "recruit the boss, on to Chicago") and ok
	ok = _check(roster_player("ht_boss").sheet == "ht_boss_crew" and int(roster_player("ht_boss").ratings.speed) == 60,
			"recruit wears your colors, keeps 40 + 20") and ok
	ok = _check(not recruit("ht_g1"), "only one recruit per city") and ok
	ok = _check(not set_starters(["ud_deuce", "ud_deuce", "ud_tank"]) and set_starters(
			["ud_deuce", "ht_boss", "ud_tank"], "ht_boss") and starters[0] == "ht_boss" and human == "ht_boss",
			"starters: 3 different, the human first") and ok
	ok = _check(match_for().teams[0].players[0].id == "ht_boss" and str(match_for().label) == "CHICAGO - GAME 1 OF 3",
			"the match uses the lineup") and ok
	ok = _check(str(match_for().twist) == "wind" and str(match_for("hometown", 1).twist) == "none",
			"the match carries the twist (Chicago wind)") and ok
	for i in 3:
		record_result({"won": true})
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
	record_result({"won": true})
	ok = _check(phase == "done" and is_done() and after_result().args.get("scene", "") == "ending"
			and record_result({"won": true}).is_empty(), "final won: ending, trip done") and ok
	saving = true
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
	d["points"] = 4
	_write_raw(p + Save.TMP_SUFFIX, JSON.stringify(d))
	ok = _check(continue_trip() and points == 4, "newer temp file wins") and ok
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
	set_starters(["ud_jojo", "ht_boss", "ud_deuce"], "ud_jojo")
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
