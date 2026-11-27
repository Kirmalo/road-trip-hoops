extends RefCounted
# Era teams in Quick Game (P11-32, owner P8 b; board "Era teams in Quick Game"). Static only, loaded at run time by
# its callers (difficulty.gd, trip.gd, menu.gd), so no preload cycle:
#   var et: GDScript = load("res://scripts/era_teams.gd")
#   et.call("ids")  /  et.call("is_open", "fathers")  /  et.call("team", "fathers")
#
# Everything comes from LegendsData.CHAPTERS / LEGENDS: an era team exists for every built chapter row with a crew,
# ERA_TEAM_MIN+ legends and a lineup of 3 (no chapter id in the logic; the Present's team appears by itself once its
# row is built). Its id is the crew name in lower case with "_", a leading "the_" dropped (grandfathers, fathers).
#   open      (finale pick, owner) the team's own three unlocked; (shape pick) ERA_TEAM_MIN of the chapter's legends unlocked in the Legends file (Legends.is_unlocked(), legends.gd
#             loaded at run time; missing = no era teams). Never the trip save, never stars. --legends-unlock-all /
#             -none act through Legends.is_unlocked(); --unlock-all opens every era team, --unlock-none closes them
#             (--unlock-all wins, as in Difficulty.team_unlocked()). Nothing is ever saved.
#   lineup    ERA_PICK: "finale" (owner, VISION "Phase 11 era teams") the chapter's finale three in data order (the
#             first is YOU); "shape" (the old stand-in, Q11-E1 a) the 3 with the highest single shape stat among the
#             unlocked ones (all of them when fewer are unlocked, e.g. a test run naming a locked team), ties in data order.
#   team      the keys of Trip.quick_team(): id, name, style, color, players, colors. Each player is Trip.player_dict()
#             of his lg_ id (his sheet in his own era kit, own_colors true, his signature move kept) with his shape
#             shifted to average Trip.QUICK_AVG 50 (the Trip.quick_ratings() shift, each stat clamped). No "perk":
#             mentor perks are Road Trip only.
#   courts    look_of(id) the chapter's court look; twist_of_look(look) the twist of the chapter with that look.

const LegendsData = preload("res://scripts/legends_data.gd")   # preloads nothing
const Ratings = preload("res://scripts/ratings.gd")            # preloads nothing

# ---------------------------------------------------------------------------------------------------- tuning
const ERA_TEAM_MIN := 3             # legends of an era unlocked before its team opens (owner P8 b)
const ERA_PICK := "finale"          # "finale" (owner) or "shape" (Q11-E1 a): which three play
const ERA_TEAM_SIZE := 3            # players on a Quick Game team
const QUICK_AVG_FALLBACK := 50      # = Trip.QUICK_AVG when trip.gd can't be read
const ID_DROP_PREFIX := "the_"      # dropped from the crew name's id ("THE FATHERS" -> fathers)

const LEGENDS_PATH := "res://scripts/legends.gd"
const TRIP_PATH := "res://scripts/trip.gd"
const DIFFICULTY_PATH := "res://scripts/difficulty.gd"
const UNLOCK_ALL_FLAG := "--unlock-all"      # = Difficulty.UNLOCK_ALL_FLAG
const UNLOCK_NONE_FLAG := "--unlock-none"    # = Difficulty.UNLOCK_NONE_FLAG
const FLAG_IGNORE := "-"                     # flag_override: act as if neither flag were given (self_test)

static var flag_override: String = ""          # self_test(): "all" / "none" stand in for the flags, "-" = no flag,
                                               # "" = the command line
static var _test_unlocked = null               # self_test(): an Array of unlocked ids instead of the Legends file

# ---------------------------------------------------------------------------------------------------- data

# the era team id of a chapter row ("" when the row has no era team)
static func _id_of_row(row: Dictionary) -> String:
	if not bool(row.get("built", false)):
		return ""
	var crew = row.get("crew", {})
	if not (crew is Dictionary) or str((crew as Dictionary).get("name", "")).strip_edges() == "":
		return ""
	if (row.get("legends", []) as Array).size() < ERA_TEAM_MIN:
		return ""
	if _pick(row, false).size() != ERA_TEAM_SIZE:
		return ""
	var id: String = str((crew as Dictionary)["name"]).strip_edges().to_lower().replace(" ", "_")
	if id.begins_with(ID_DROP_PREFIX):
		id = id.substr(ID_DROP_PREFIX.length())
	return id

# the chapter row of an era team id ({} for an unknown id)
static func _row(id: String) -> Dictionary:
	if id == "":
		return {}
	for row in LegendsData.chapter_rows():
		if _id_of_row(row) == id:
			return row
	return {}

# every era team id, in timeline order (open or not)
static func ids() -> Array:
	var out: Array = []
	for row in LegendsData.chapter_rows():
		var id: String = _id_of_row(row)
		if id != "" and not out.has(id):
			out.append(id)
	return out

# the open era team ids, in timeline order
static func open_ids() -> Array:
	var out: Array = []
	for id in ids():
		if is_open(str(id)):
			out.append(id)
	return out

static func is_era_id(id: String) -> bool:
	return not _row(id).is_empty()

# the chapter id behind an era team ("" for an unknown id); for tests and the art lookups only
static func chapter_of(id: String) -> String:
	return str(_row(id).get("id", ""))

# a Difficulty.all_teams()-style entry: {"id", "name", "city": "", "game": 0, "color", "era": true} ({} if unknown)
static func info(id: String) -> Dictionary:
	var row: Dictionary = _row(id)
	if row.is_empty():
		return {}
	var crew: Dictionary = row.get("crew", {})
	return {"id": id, "name": str(crew.get("name", "")), "city": "", "game": 0,
		"color": crew.get("ui_color", Color.GRAY), "era": true}

# ---------------------------------------------------------------------------------------------------- gate

static func _flag() -> String:
	if flag_override == FLAG_IGNORE:
		return ""
	if flag_override != "":
		return flag_override
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has(UNLOCK_ALL_FLAG):
		return "all"
	if args.has(UNLOCK_NONE_FLAG):
		return "none"
	return ""

static func _legends() -> GDScript:
	if not ResourceLoader.exists(LEGENDS_PATH):
		return null
	var g: GDScript = load(LEGENDS_PATH) as GDScript
	if g == null or not g.has_method("is_unlocked"):
		return null
	return g

static func _unlocked(lid: String) -> bool:
	if _test_unlocked is Array:
		return (_test_unlocked as Array).has(lid)
	var g: GDScript = _legends()
	return g != null and bool(g.call("is_unlocked", lid))

# how many of the era's legends are unlocked in the Legends file
static func unlocked_count(id: String) -> int:
	var n: int = 0
	for lid in _row(id).get("legends", []):
		if _unlocked(str(lid)):
			n += 1
	return n

# the era team can be picked in Quick Game
static func is_open(id: String) -> bool:
	if _row(id).is_empty():
		return false
	var f: String = _flag()
	if f == "all":
		return true
	if f == "none":
		return false
	if not (_test_unlocked is Array) and _legends() == null:
		return false
	if ERA_PICK == "finale":
		# owner (VISION "Phase 11 era teams"): the team opens once its own three (the finale three) are unlocked,
		# so Quick Game never plays a legend you haven't unlocked
		var three: Array = _pick(_row(id), false)
		if three.size() != ERA_TEAM_SIZE:
			return false
		for lid in three:
			if not _unlocked(str(lid)):
				return false
		return true
	return unlocked_count(id) >= ERA_TEAM_MIN

# ---------------------------------------------------------------------------------------------------- lineup

# the highest single stat of a legend's shape
static func _top_stat(lid: String) -> int:
	var shape: Dictionary = LegendsData.legend(lid).get("shape", {})
	var best: int = -1000
	for s in LegendsData.STATS:
		best = maxi(best, int(shape.get(s, 0)))
	return best

# the three of a chapter row by ERA_PICK (only_unlocked: the "shape" rule picks among the unlocked ones when 3 are)
static func _pick(row: Dictionary, only_unlocked: bool) -> Array:
	var all: Array = []
	for lid in row.get("legends", []):
		if not LegendsData.legend(str(lid)).is_empty():
			all.append(str(lid))
	if ERA_PICK == "finale":
		var out: Array = []
		for lid in (row.get("finale", {}) as Dictionary).get("legends", []):
			if all.has(str(lid)) and not out.has(str(lid)):
				out.append(str(lid))
		return out if out.size() == ERA_TEAM_SIZE else []
	var pool: Array = all
	if only_unlocked:
		var un: Array = []
		for lid in all:
			if _unlocked(str(lid)):
				un.append(lid)
		if un.size() >= ERA_TEAM_SIZE:
			pool = un
	var ranked: Array = []
	for i in pool.size():
		ranked.append([str(pool[i]), _top_stat(str(pool[i])), i])
	ranked.sort_custom(func(a, b): return a[1] > b[1] if a[1] != b[1] else a[2] < b[2])
	var picked: Array = []
	for i in mini(ERA_TEAM_SIZE, ranked.size()):
		picked.append(str(ranked[i][0]))
	var ordered: Array = []   # data order, so the first in data order is YOU
	for lid in pool:
		if picked.has(str(lid)):
			ordered.append(str(lid))
	return ordered if ordered.size() == ERA_TEAM_SIZE else []

# the era team's 3 legend ids, the first is YOU ([] for an unknown id)
static func lineup(id: String) -> Array:
	var row: Dictionary = _row(id)
	if row.is_empty():
		return []
	return _pick(row, true)

# a legend's five stats shifted to average QUICK_AVG (the Trip.quick_ratings() rule on his shape), each in range
static func ratings_of(lid: String, avg: int = -1) -> Dictionary:
	var target: int = avg if avg >= 0 else _quick_avg()
	var shape: Dictionary = LegendsData.legend(lid).get("shape", {})
	var sum: float = 0.0
	for s in Ratings.STATS:
		sum += float(target + int(shape.get(s, 0)))
	var shift: float = float(target) - sum / float(Ratings.STATS.size())
	var out: Dictionary = {}
	for s in Ratings.STATS:
		out[s] = clampi(roundi(float(target + int(shape.get(s, 0))) + shift), Ratings.MIN_RATING, Ratings.MAX_RATING)
	return out

static func _trip() -> GDScript:
	if not ResourceLoader.exists(TRIP_PATH):
		return null
	return load(TRIP_PATH) as GDScript

static func _quick_avg() -> int:
	var t: GDScript = _trip()
	if t != null:
		var m: Dictionary = t.get_script_constant_map()
		if m.has("QUICK_AVG"):
			return int(m["QUICK_AVG"])
	return QUICK_AVG_FALLBACK

# The Quick Game team dict (Trip.quick_team()'s keys); {} for an unknown id. Open or not: the callers gate it.
static func team(id: String) -> Dictionary:
	var row: Dictionary = _row(id)
	var t: GDScript = _trip()
	if row.is_empty() or t == null or not t.has_method("player_dict"):
		return {}
	var crew: Dictionary = row.get("crew", {})
	var players: Array = []
	for lid in lineup(id):
		var pd: Dictionary = t.call("player_dict", str(lid), ratings_of(str(lid)), false)
		pd["own_colors"] = true
		pd.erase("perk")
		players.append(pd)
	if players.size() != ERA_TEAM_SIZE:
		return {}
	return {"id": id, "name": str(crew.get("name", "")), "style": str(crew.get("style", "")),
		"color": crew.get("ui_color", Color.GRAY), "players": players,
		"colors": (crew.get("colors", []) as Array).duplicate()}

# ---------------------------------------------------------------------------------------------------- courts

# the era's court look ("" for an unknown id or a row without one)
static func look_of(id: String) -> String:
	return str(_row(id).get("look", ""))

# the twist of the era whose look this is ("" when no era team's chapter has it)
static func twist_of_look(look: String) -> String:
	if look == "":
		return ""
	for id in ids():
		var row: Dictionary = _row(str(id))
		if str(row.get("look", "")) == look:
			return str(row.get("twist", ""))
	return ""

# the era team id whose court this is ("" if none)
static func era_of_look(look: String) -> String:
	if look == "":
		return ""
	for id in ids():
		if str(_row(str(id)).get("look", "")) == look:
			return str(id)
	return ""

# ---------------------------------------------------------------------------------------------------- self test

# "" or the reasons, one per line. Touches no file: the unlock state is faked through _test_unlocked, the flags
# through flag_override and Legends.unlock_override (all put back).
static func self_test() -> String:
	var errs: Array = []
	var kept_flag: String = flag_override
	var kept_unl = _test_unlocked
	var kept_data: Dictionary = {}
	if LegendsData.test_data_on():
		kept_data = {"chapters": LegendsData.chapter_rows().duplicate(true),
			"legends": LegendsData.legend_rows().duplicate(true)}
	flag_override = FLAG_IGNORE
	_test_unlocked = null
	_check_rows(errs, "shipped")
	var want_n: int = 0
	for row in LegendsData.chapter_rows():
		if bool(row.get("built", false)) and not (row.get("crew", {}) as Dictionary).is_empty():
			want_n += 1
	if ids().size() != want_n:
		errs.append("%d era teams for %d built chapters with a crew (%s)" % [ids().size(), want_n, str(ids())])
	# the stand-in Present: three teams
	LegendsData.set_test_data(LegendsData.stand_in_test_data("present"))
	var want_s: int = 0
	for row in LegendsData.chapter_rows():
		if bool(row.get("built", false)) and not (row.get("crew", {}) as Dictionary).is_empty():
			want_s += 1
	if ids().size() != want_s or want_s < 3:
		errs.append("stand-in present: %d era teams, want %d (%s)" % [ids().size(), want_s, str(ids())])
	_check_rows(errs, "stand-in present")
	LegendsData.clear_test_data()
	if not kept_data.is_empty():
		LegendsData.set_test_data(kept_data)
	# a built row without a crew, or with too few legends, gives no team
	var rows: Array = LegendsData.CHAPTERS.duplicate(true)
	var n_before: int = ids().size()
	if n_before > 0 and kept_data.is_empty():
		var first: String = str(ids()[0])
		for r in rows:
			if _id_of_row(r) == first:
				r["crew"] = {}
		LegendsData.set_test_data({"chapters": rows, "legends": LegendsData.LEGENDS.duplicate(true)})
		if ids().size() != n_before - 1 or ids().has(first):
			errs.append("a row without a crew still gives an era team: %s" % str(ids()))
		LegendsData.clear_test_data()
	# no era id may be a crew id
	var d: GDScript = load(DIFFICULTY_PATH) as GDScript if ResourceLoader.exists(DIFFICULTY_PATH) else null
	if d != null and d.has_method("all_teams"):
		for t in d.call("all_teams"):
			if is_era_id(str((t as Dictionary).get("id", ""))):
				errs.append("era id %s is also a crew id" % str(t["id"]))
	# the Legends flags, through Legends.unlock_override
	var g: GDScript = _legends()
	if g != null and ids().size() > 0:
		var kept_lo = g.get("unlock_override")
		var id0: String = str(ids()[0])
		g.set("unlock_override", "all")
		if not is_open(id0):
			errs.append("--legends-unlock-all: %s closed" % id0)
		g.set("unlock_override", "none")
		if is_open(id0):
			errs.append("--legends-unlock-none: %s open" % id0)
		flag_override = "all"
		if not is_open(id0):
			errs.append("--unlock-all with --legends-unlock-none: %s closed" % id0)
		flag_override = FLAG_IGNORE
		g.set("unlock_override", kept_lo)
	flag_override = kept_flag
	_test_unlocked = kept_unl
	return "\n".join(PackedStringArray(errs))

# per era team: the gate at 0 / 2 / 3 / all unlocked, the lineup, the flags, the team dict and its ratings
static func _check_rows(errs: Array, tag: String) -> void:
	var seen: Array = []
	for id in ids():
		var eid: String = str(id)
		var row: Dictionary = _row(eid)
		var legs: Array = row.get("legends", [])
		var want: Array = _pick(row, false)
		if seen.has(eid):
			errs.append("%s: era id %s twice" % [tag, eid])
		seen.append(eid)
		if ERA_PICK == "finale" and want != LegendsData.finale_team(str(row.get("id", ""))):
			errs.append("%s %s: lineup %s is not the finale %s" % [tag, eid, str(want),
					str(LegendsData.finale_team(str(row.get("id", ""))))])
		_test_unlocked = []
		if is_open(eid):
			errs.append("%s %s: open with none unlocked" % [tag, eid])
		_test_unlocked = legs.slice(0, ERA_TEAM_MIN - 1)
		if is_open(eid):
			errs.append("%s %s: open with %d unlocked" % [tag, eid, ERA_TEAM_MIN - 1])
		if ERA_PICK == "finale":
			# its three unlocked opens it; two of them plus every other legend of the era does not
			_test_unlocked = want.duplicate()
			if not is_open(eid):
				errs.append("%s %s: closed with its three unlocked" % [tag, eid])
			var others: Array = []
			for lid in legs:
				if str(lid) != str(want[0]):
					others.append(lid)
			_test_unlocked = others
			if is_open(eid):
				errs.append("%s %s: open without %s" % [tag, eid, str(want[0])])
		else:
			_test_unlocked = legs.slice(0, ERA_TEAM_MIN)
			if not is_open(eid):
				errs.append("%s %s: closed with %d unlocked" % [tag, eid, ERA_TEAM_MIN])
		if ERA_PICK != "finale" and lineup(eid) != legs.slice(0, ERA_TEAM_MIN):
			errs.append("%s %s: %d unlocked, lineup %s" % [tag, eid, ERA_TEAM_MIN, str(lineup(eid))])
		_test_unlocked = legs.duplicate()
		if not is_open(eid) or lineup(eid) != want:
			errs.append("%s %s: all unlocked, open %s lineup %s want %s" % [tag, eid, str(is_open(eid)),
					str(lineup(eid)), str(want)])
		flag_override = "none"
		if is_open(eid):
			errs.append("%s %s: open under --unlock-none" % [tag, eid])
		flag_override = "all"
		_test_unlocked = []
		if not is_open(eid):
			errs.append("%s %s: closed under --unlock-all" % [tag, eid])
		flag_override = FLAG_IGNORE
		# the team dict
		var tm: Dictionary = team(eid)
		var crew: Dictionary = row.get("crew", {})
		for k in ["id", "name", "style", "color", "players", "colors"]:
			if not tm.has(k):
				errs.append("%s %s: team has no %s" % [tag, eid, k])
		if str(tm.get("name", "")) != str(crew.get("name", "")) or str(tm.get("style", "")) != str(crew.get("style", "")):
			errs.append("%s %s: team name or style is not the crew's" % [tag, eid])
		var ps: Array = tm.get("players", [])
		if ps.size() != ERA_TEAM_SIZE:
			errs.append("%s %s: %d players" % [tag, eid, ps.size()])
			continue
		for i in ps.size():
			var pd: Dictionary = ps[i]
			var lid: String = str(pd.get("id", ""))
			if lid != str(want[i]):
				errs.append("%s %s: player %d is %s, want %s" % [tag, eid, i, lid, str(want[i])])
			if pd.has("perk"):
				errs.append("%s %s: %s has a perk" % [tag, eid, lid])
			if not bool(pd.get("own_colors", false)):
				errs.append("%s %s: %s not in his own colors" % [tag, eid, lid])
			var sig: String = str((LegendsData.legend(lid).get("signature", {}) as Dictionary).get("id", ""))
			if str(pd.get("signature", "")) != sig:
				errs.append("%s %s: %s signature %s, want %s" % [tag, eid, lid, str(pd.get("signature", "")), sig])
			var r: Dictionary = pd.get("ratings", {})
			var sum: int = 0
			for s in Ratings.STATS:
				var v: int = int(r.get(s, -1))
				if v < Ratings.MIN_RATING or v > Ratings.MAX_RATING:
					errs.append("%s %s: %s %s = %d out of range" % [tag, eid, lid, s, v])
				sum += v
			var mean: float = float(sum) / float(Ratings.STATS.size())
			if absf(mean - float(_quick_avg())) > 0.5:
				errs.append("%s %s: %s averages %.1f, want %d" % [tag, eid, lid, mean, _quick_avg()])
		# the court
		var look: String = look_of(eid)
		if look != str(row.get("look", "")) or (look != "" and twist_of_look(look) != str(row.get("twist", ""))):
			errs.append("%s %s: look %s / twist %s not the chapter's" % [tag, eid, look, twist_of_look(look)])
		if look != "" and era_of_look(look) != eid:
			errs.append("%s %s: era_of_look(%s) = %s" % [tag, eid, look, era_of_look(look)])
	_test_unlocked = null
	if twist_of_look("gym") != "":
		errs.append("%s: the gym has an era twist" % tag)
	if is_open("kings") or not team("no_such_era").is_empty() or lineup("") != []:
		errs.append("%s: an unknown id gives an era team" % tag)
