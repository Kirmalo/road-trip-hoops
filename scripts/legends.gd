extends RefCounted
# Legends progress and matches (P9-12, board "Shared contract: Legends progress"). Static only, used through preload:
#   const Legends = preload("res://scripts/legends.gd")
#   Legends.load_state()                              # once per run (safe to call again)
#   if Legends.mode_open(): Flow.go("legends")        # the title's LEGENDS button
#   Legends.match_for_challenge("lg_steeple", "normal"); Flow.go("game")   # the chapter view's PLAY
#   Legends.record_result(Flow.last_result)           # flow.gd calls it after a legends game, then after_result()
# State lives in static vars (survives reload_current_scene()); legends_save.gd's file is the truth on launch
# (user://legends.json; every test run user://legends_test.json). A NEW TRIP never touches it.
#
# Rules (VISION "Phase 9 answers L1-L8", board "Phase 9"):
#   - tokens: a won challenge or finale gives LegendsData.TOKENS_BY_LEVEL[level] (1 / 2 / 3, LEGEND 3), best kept per
#     key ("lg:<legend id>", "fin:<chapter>"); a loss, or a win with the challenge goal broken, gives none
#   - unlocks: the first won challenge of a legend unlocks him for good (unlock scene, the Hall, the draft)
#   - the finale opens once all 6 of the chapter are beaten; winning it closes the chapter (finales)
#   - gates (L4 a): a chapter opens at its gate's stars (Stars.total()) OR its gate's tokens (when > 0); only built
#     chapters open; mode_open() = any built chapter is open (gates rise along the timeline, so in practice the
#     first one). Every chapter is data (P10-02): nothing here names a chapter; a chapter's ratings may differ by its
#     row's optional challenge_avg / mate_drop / finale_stage_avg (legends_data.gd)
#   - your side (L3 b): the trip's current 3 starters at their ratings now, the human = Trip.human, no perks. The
#     saved trip is loaded (Trip.continue_trip(), saving off: no migration write) when none is active. A challenge
#     never changes the trip: Flow.match.mode "legends" never reaches Trip.record_result(), nothing here calls
#     Trip.save() (self_test() checks the trip file byte for byte)
#   - no trip save (technical choice): the Cornfield Kings (Trip.QUICK_KINGS) at even ratings (Trip.quick_ratings(),
#     every player's five stats averaging 50); the chapter view says NO_TRIP_NOTE
#   - a legend on both sides (technical choice): a drafted legend who is one of the opponents sits this game and the
#     strongest bench non-legend (rating sum) takes his place (his slot; if he was you, you play the new man)
#   - the level (technical choice): picked on the chapter view; default_level() is the trip's level (Quick Game's
#     saved level without a trip); LEGEND only when Stars.legend_open() (else Hard). The trip's level never changes
#   - opponents: the challenge legend at LegendsData.challenge_ratings(), his 2 mates at mate_ratings(), the finale's
#     3 at finale_ratings(), each + Difficulty.rating_bonus(level) (LEGEND), every stat <= 95 (legends_data.gd)
#   - court, music, twist: the chapter's look (court_looks.gd; GYM when missing), music (its fallback_music while the
#     .ogg is missing) and era twist (none while twists.gd doesn't have it yet)
#   - mentors (P9-23, owner L8 a): an unlocked legend trains one roster player (mentors {legend id: player id}, in
#     legends.json, so a NEW TRIP keeps them); one perk per player (one mentor each), one pupil per legend; assign()
#     switches any time (the legend's old pupil and the player's old mentor are freed). perks_for() gives the perk;
#     Trip.roster_player() adds it as "perk" on a loaded trip (Road Trip games only); your_side() strips it (no perks
#     in a challenge or a finale). A pupil not on the trip's roster just has no effect; a locked or unknown legend's
#     pair is kept in the file but gives nothing. A file with two legends on one player keeps the first (load repair)
# Test flags (any run): --legends-unlock-all / --legends-unlock-none (this run, never saved), --tokens N (this run
# acts as if the token total were N), --challenge <id> (main.gd: test_match(); with --expected-roster /
# --best-roster the end-of-trip crew, Trip.end_of_trip_crew(best), P9-21). --legendtest: legendtest().

const LegendsData = preload("res://scripts/legends_data.gd")
const LegendsSave = preload("res://scripts/legends_save.gd")
const Flow = preload("res://scripts/flow.gd")
const Trip = preload("res://scripts/trip.gd")
const Save = preload("res://scripts/save.gd")
const Stars = preload("res://scripts/stars.gd")
const Difficulty = preload("res://scripts/difficulty.gd")
const Ratings = preload("res://scripts/ratings.gd")
const Twists = preload("res://scripts/twists.gd")
const Looks = preload("res://scripts/court_looks.gd")
const StoryText = preload("res://scripts/story_text.gd")
const Cities = preload("res://scripts/cities.gd")

# ---------------------------------------------------------------------------------------------------- tuning
const MODE := "legends"               # = Flow.LEGENDS_MODE: Flow.match.mode of a challenge or finale
const SCREEN := "legends"             # the era tour (args {"chapter": id}); where every legends game ends
const LEVELS := ["easy", "normal", "hard", "legend"]
const FALLBACK_LEVEL := "normal"      # an unknown level name
const LEGEND_LEVEL := "legend"
const CLOSED_LEGEND_LEVEL := "hard"   # LEGEND asked for while the stars don't open it
const FALLBACK_LOOK := "gym"          # the chapter's look while court_looks.gd doesn't have it
const NO_TWIST := "none"
const MUSIC_DIR := "res://assets/music/"
const CREW_TRIP := "trip"             # Flow.match.crew: your trip's starters
const CREW_KINGS := "kings"           # Flow.match.crew: no trip save, the Kings at even ratings
const NO_TRIP_NOTE := "NO TRIP: THE KINGS PLAY"
const SWAP_NOTE := "%s SITS: %s PLAYS"   # a legend on both sides: "<legend> SITS: <bench player> PLAYS"
const CHALLENGE_LABEL := "%s - %s"    # "THE GRANDFATHERS - STEEPLE" (the chapter's name, the legend's)
const KEY_CHALLENGE := "lg:"
const KEY_FINALE := "fin:"
const UNLOCK_ALL_FLAG := "--legends-unlock-all"
const UNLOCK_NONE_FLAG := "--legends-unlock-none"
const TOKENS_FLAG := "--tokens"
const CHALLENGE_FLAG := "--challenge"   # --challenge <legend id | short name | finale | fin:<ch> | <chapter id>>
const EXPECTED_FLAG := "--expected-roster"
const BEST_FLAG := "--best-roster"
const DIFFICULTY_FLAG := "--difficulty"
const TRIP_PATH := "res://scripts/trip.gd"
const ERA_TEAMS_PATH := "res://scripts/era_teams.gd"   # P11-33: legendtest() runs its self_test() (loaded at run time)
const SELFTEST_PATH := "user://legends_progress_selftest.json"   # self_test()'s own Legends file, deleted after
const SELFTEST_TRIP_LEVEL := "hard"   # self_test()'s scripted trip (in place of any left-over test trip, P9-28)
const PERK_KEY := "perk"              # = Trip.PERK_KEY: a player dict's mentor perk; never on your side in a challenge
# self_test() only (test expectations, never game logic): every chapter row's gate as the owner set it, in timeline
# order (L4 a: 24 stars; F7 a: 36 stars or 12 tokens; P7 a: 48 stars or 30 tokens; P12 Q6 a: 72 stars or 48 tokens;
# never an earlier finale needed). SHIPPED_CHAPTERS: the fewest built rows the shipped data may have (the first rows of
# SHIPPED_GATES; P12-03: a build with Chapter 4's row built too passes, P12-11)
const SHIPPED_CHAPTERS := 3
const SHIPPED_GATES := {"grand": {"stars": 24, "tokens": 0}, "fathers": {"stars": 36, "tokens": 12},
	"present": {"stars": 48, "tokens": 30}, "next": {"stars": 72, "tokens": 48}}
const TOUR_PATH := "res://scripts/legends_tour.gd"   # self_test(): its static _intro_scene() / _finale_before()

# ---------------------------------------------------------------------------------------------------- state
static var tokens := {}               # {"lg:<id>" | "fin:<ch>": 1..3}, best kept
static var unlocked: Array = []       # legend ids, in the order they were won
static var seen: Array = []           # story scene ids already shown (intro, unlock, finale scenes)
static var finales: Array = []        # chapter ids whose finale was won
static var mentors := {}              # {"<legend id>": "<roster player id>"} (P9-23: one pupil each, one mentor each)
static var last_outcome := {}         # record_result()'s answer, for after_result() and the screens
static var saving := true             # false = record_result() and friends don't write (tests)
static var unlock_override: String = _parse_unlock_flag()   # "all" / "none" / "" (this run only, never saved)
static var force_tokens: int = _parse_tokens_flag()         # --tokens N (-1 = none): tokens_total() returns N
static var _loaded := false
static var _skip_trip_load := false   # self_test(): act as if there were no trip save

# ---------------------------------------------------------------------------------------------------- load and save

# Reads the Legends file once per run (force = read again). A missing or broken file is a fresh start.
static func load_state(force: bool = false) -> void:
	if _loaded and not force:
		return
	_loaded = true
	_from_dict(LegendsSave.read())

# Writes the state (temp file + rename, legends_save.gd). False when saving is off or the write failed.
static func save() -> bool:
	if not saving:
		return false
	return LegendsSave.write(to_dict())

static func to_dict() -> Dictionary:
	return {"tokens": tokens.duplicate(), "unlocked": unlocked.duplicate(), "seen": seen.duplicate(),
		"finales": finales.duplicate(), "mentors": mentors.duplicate()}

static func _from_dict(d: Dictionary) -> void:
	var c: Dictionary = LegendsSave.clean(d)
	tokens = c["tokens"]
	unlocked = c["unlocked"]
	seen = c["seen"]
	finales = c["finales"]
	mentors = _one_mentor_each(c["mentors"])

# P9-23 load repair: a player trained by two legends (a hand edit) keeps the first in file order
static func _one_mentor_each(m: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var taken: Array = []
	for lid in m:
		var pid: String = str(m[lid])
		if taken.has(pid):
			continue
		taken.append(pid)
		out[str(lid)] = pid
	return out

# ---------------------------------------------------------------------------------------------------- mentors

# the legend who trains this player ("" = none). Raw pairs: a locked legend's pair is named too (perks_for() says if
# it works)
static func mentor_of(player_id: String) -> String:
	load_state()
	if player_id == "":
		return ""
	for lid in mentors:
		if str(mentors[lid]) == player_id:
			return str(lid)
	return ""

# the player this legend trains ("" = none)
static func pupil_of(legend_id: String) -> String:
	load_state()
	return str(mentors.get(legend_id, ""))

# a legend can train: a known legend, unlocked (--legends-unlock-all / -none win this run), with a perk
static func can_mentor(legend_id: String) -> bool:
	return LegendsData.is_legend_id(legend_id) and is_unlocked(legend_id) \
			and not LegendsData.perk_of(legend_id).is_empty()

# Puts this legend on this player (saved). Switching frees both sides: the legend's old pupil and the player's old
# mentor. False (nothing changed) for a legend that can't train (locked, unknown, no perk), an empty or too long
# player id, or a legend asked to train himself. The player need not be on this trip's roster (no effect until he
# is). True also when the pair was already in place.
static func assign(legend_id: String, player_id: String) -> bool:
	load_state()
	# owner: a legend coaches regular players only, never another legend (so never himself either)
	if not can_mentor(legend_id) or player_id == "" or LegendsData.is_legend_id(player_id) \
			or player_id.length() > LegendsSave.MAX_ID_LEN:
		return false
	if str(mentors.get(legend_id, "")) == player_id:
		return true
	var old: String = mentor_of(player_id)
	if old != "":
		mentors.erase(old)
	mentors[legend_id] = player_id
	save()
	return true

# the legend stops training (saved); false when he trained nobody
static func release(legend_id: String) -> bool:
	load_state()
	if not mentors.has(legend_id):
		return false
	mentors.erase(legend_id)
	save()
	return true

# The mentor perk this player gets: {"id", "key", "value", "text", "mentor"} or {} (nobody trains him, or his
# mentor is locked, unknown or teaches no perk). Doesn't look at the trip: Trip.roster_player() asks only for its
# roster players on a loaded trip.
static func perks_for(player_id: String) -> Dictionary:
	var lid: String = mentor_of(player_id)
	if lid == "" or not can_mentor(lid) or LegendsData.is_legend_id(player_id):
		return {}
	var row: Dictionary = LegendsData.perk_of(lid)
	return {"id": str(LegendsData.legend(lid).get("perk", "")), "key": str(row.get("key", "")),
		"value": float(row.get("value", 0.0)), "text": str(row.get("text", "")), "mentor": lid}

# a player dict without its mentor perk (your side in a challenge: Road Trip games only, L8 a)
static func _no_perk(pd: Dictionary) -> Dictionary:
	if not pd.has(PERK_KEY):
		return pd
	var out: Dictionary = pd.duplicate()
	out.erase(PERK_KEY)
	return out

# ---------------------------------------------------------------------------------------------------- keys, tokens

static func challenge_key(id: String) -> String:
	return KEY_CHALLENGE + id

static func finale_key(ch: String) -> String:
	return KEY_FINALE + ch

# the best tokens of one key (0..3)
static func token_best(key: String) -> int:
	load_state()
	return int(tokens.get(key, 0))

# every token earned (--tokens N wins this run)
static func tokens_total() -> int:
	if force_tokens >= 0:
		return force_tokens
	return real_tokens_total()

# the stored total (never --tokens). P9-B2: only the chapters this build has (a newer build's or a hand-edited file
# keeps its other keys, but they never count here, so the total never passes max_tokens())
static func real_tokens_total() -> int:
	load_state()
	var t: int = 0
	for ch in LegendsData.built_chapters():
		t += chapter_tokens(str(ch))
	return t

# a chapter's tokens and its most (6 challenges + the finale, x3)
static func chapter_tokens(ch: String) -> int:
	var t: int = token_best(finale_key(ch))
	for id in LegendsData.legend_ids(ch):
		t += token_best(challenge_key(str(id)))
	return t

static func chapter_max_tokens(ch: String) -> int:
	return LegendsData.chapter_max_tokens(ch)

# ---------------------------------------------------------------------------------------------------- gates

# the gate's stars or tokens are reached (built or not: the timeline may show "COMING LATER" with the gate met)
static func gate_met(ch: String) -> bool:
	var row: Dictionary = LegendsData.chapter(ch)
	if row.is_empty():
		return false
	var gate: Dictionary = row.get("gate", {})
	var need_stars: int = int(gate.get("stars", 0))
	var need_tokens: int = int(gate.get("tokens", 0))
	if need_stars > 0 and Stars.total() >= need_stars:
		return true
	if need_tokens > 0 and tokens_total() >= need_tokens:
		return true
	return need_stars <= 0 and need_tokens <= 0

# a chapter can be played: built and its gate met
static func chapter_open(ch: String) -> bool:
	return LegendsData.is_built(ch) and gate_met(ch)

# "24 STARS", "36 STARS OR 12 TOKENS" ("" for an unknown chapter or no gate)
static func gate_text(ch: String) -> String:
	var gate: Dictionary = LegendsData.chapter(ch).get("gate", {})
	var parts: Array = []
	if int(gate.get("stars", 0)) > 0:
		parts.append("%d STARS" % int(gate.get("stars", 0)))
	if int(gate.get("tokens", 0)) > 0:
		parts.append("%d TOKENS" % int(gate.get("tokens", 0)))
	return " OR ".join(PackedStringArray(parts))

# the Legends mode is open: a built chapter is (P10-02: any of them; with gates rising along the timeline this is the
# first built chapter, Chapter 1)
static func mode_open() -> bool:
	for ch in LegendsData.built_chapters():
		if chapter_open(str(ch)):
			return true
	return false

# the gate of the mode ("24 STARS"): the title's locked LEGENDS button (the first built chapter's, the lowest gate)
static func mode_gate_text() -> String:
	var built: Array = LegendsData.built_chapters()
	return gate_text(str(built[0])) if not built.is_empty() else ""

# ---------------------------------------------------------------------------------------------------- unlocks

# a legend is unlocked (won his challenge once; --legends-unlock-all / -none win this run)
static func is_unlocked(id: String) -> bool:
	if not LegendsData.is_legend_id(id):
		return false
	if unlock_override == "all":
		return true
	if unlock_override == "none":
		return false
	load_state()
	return unlocked.has(id)

# the unlocked legend ids in data order (chapter by chapter, plaque order)
static func unlocked_ids() -> Array:
	var out: Array = []
	for id in LegendsData.legend_ids():
		if is_unlocked(str(id)):
			out.append(str(id))
	return out

# the chapter's finale can be played: all its legends are beaten (and the chapter is open)
static func finale_open(ch: String) -> bool:
	var ids: Array = LegendsData.legend_ids(ch)
	if ids.is_empty() or not LegendsData.has_finale(ch):
		return false
	for id in ids:
		if not is_unlocked(str(id)):
			return false
	return chapter_open(ch)

# the chapter's finale was won (the chapter is closed); --legends-unlock-all does not close it
static func chapter_done(ch: String) -> bool:
	load_state()
	return finales.has(ch)

# a challenge can be played now (its chapter is open)
static func challenge_open(id: String) -> bool:
	return LegendsData.is_legend_id(id) and chapter_open(LegendsData.chapter_of(id))

static func has_seen(scene: String) -> bool:
	load_state()
	return seen.has(scene)

# marks a story scene seen (saved); true when it was new
static func mark_seen(scene: String) -> bool:
	load_state()
	if scene == "" or seen.has(scene):
		return false
	seen.append(scene)
	save()
	return true

# ---------------------------------------------------------------------------------------------------- levels

static func level_ok(lv: String) -> String:
	var s: String = lv.strip_edges().to_lower()
	if not LEVELS.has(s):
		s = FALLBACK_LEVEL
	if s == LEGEND_LEVEL and not Stars.legend_open():
		s = CLOSED_LEGEND_LEVEL
	return s

# the levels the chapter view offers: Easy, Normal, Hard, and LEGEND once the stars open it
static func offered_levels() -> Array:
	var out: Array = ["easy", "normal", "hard"]
	if Stars.legend_open():
		out.append(LEGEND_LEVEL)
	return out

# the level the chapter view opens on: the trip's (loaded if needed), else Quick Game's saved level
static func default_level() -> String:
	if _trip_loaded():
		return level_ok(Trip.level)
	Difficulty.init_once()
	return level_ok(Difficulty.level_name(Difficulty.level))

# ---------------------------------------------------------------------------------------------------- your side

# the trip is active, or the saved trip was loaded now (saving off while loading: a challenge never writes the trip,
# not even a migration or a lineup repair; the trip's own CONTINUE does that). False = no trip save.
static func _trip_loaded() -> bool:
	if Trip.active:
		return true
	if _skip_trip_load:
		return false
	if not OS.get_cmdline_user_args().is_empty():
		Save.use_test_file = true   # a test run plays with the test trip save (user://trip_test.json), never the owner's
	var was: bool = Trip.saving
	Trip.saving = false
	var ok: bool = Trip.continue_trip()
	Trip.saving = was
	return ok

static func _sum(r: Dictionary) -> int:
	var t: int = 0
	for s in Ratings.STATS:
		t += int(r.get(s, 0))
	return t

static func _is_legend(id: String) -> bool:
	return id.begins_with(LegendsData.ID_PREFIX)

static func _short_name(pd: Dictionary) -> String:
	var id: String = str(pd.get("id", ""))
	if LegendsData.is_legend_id(id):
		return str(LegendsData.legend(id).get("name", id))
	return str(pd.get("name", id))

# Your side against these opponents (legend ids): {"crew": "trip" | "kings", "players": [3 player dicts, you first],
# "human": id, "swaps": [{"out", "in", "out_name", "in_name"}], "note": "" | NO_TRIP_NOTE | the swap line}.
# Never changes the trip (its starters stay as they are). The chapter view (P9-18) shows this before PLAY.
static func your_side(opponents: Array) -> Dictionary:
	var out := {"crew": CREW_KINGS, "players": [], "human": "", "swaps": [], "note": NO_TRIP_NOTE}
	if not _trip_loaded() or Trip.starters.size() != Trip.STARTERS:
		for id in Trip.QUICK_KINGS:
			out["players"].append(Trip.player_dict(str(id), Trip.quick_ratings(str(id)), true))
		out["human"] = str(Trip.QUICK_KINGS[0])
		return out
	out["crew"] = CREW_TRIP
	out["note"] = ""
	var ids: Array = []
	var human: String = Trip.human if Trip.starters.has(Trip.human) else str(Trip.starters[0])
	ids.append(human)
	for id in Trip.starters:
		if str(id) != human:
			ids.append(str(id))
	# the bench non-legends, strongest first (rating sum; roster order on a tie)
	var bench: Array = []
	for id in Trip.roster_ids():
		var sid: String = str(id)
		if ids.has(sid) or _is_legend(sid):
			continue
		var pd: Dictionary = _no_perk(Trip.roster_player(sid))
		if pd.is_empty():
			continue
		var at: int = bench.size()
		for i in bench.size():
			if _sum(pd.get("ratings", {})) > _sum((bench[i] as Dictionary).get("ratings", {})):
				at = i
				break
		bench.insert(at, pd)
	var notes: Array = []
	for i in ids.size():
		var id: String = str(ids[i])
		var pd: Dictionary = _no_perk(Trip.roster_player(id))   # no perks in a challenge (L8 a)
		if opponents.has(id):
			var sub: Dictionary = {}
			if not bench.is_empty():
				sub = bench.pop_front()
			else:
				# nobody on the bench (never on a real trip: the 3 underdogs are always on the roster): a King at 50s
				for k in Trip.QUICK_KINGS:
					if not ids.has(str(k)):
						sub = Trip.player_dict(str(k), Trip.quick_ratings(str(k)), true)
						break
			var sw := {"out": id, "in": str(sub.get("id", "")), "out_name": _short_name(pd if not pd.is_empty()
					else {"id": id}), "in_name": _short_name(sub)}
			out["swaps"].append(sw)
			notes.append(SWAP_NOTE % [str(sw["out_name"]), str(sw["in_name"])])
			pd = sub
		out["players"].append(pd)
	out["human"] = str((out["players"][0] as Dictionary).get("id", ""))
	out["note"] = ", ".join(PackedStringArray(notes))
	return out

# your side for a challenge / a finale (see your_side())
static func crew_for_challenge(id: String) -> Dictionary:
	return your_side(LegendsData.challenge_team(id))

static func crew_for_finale(ch: String) -> Dictionary:
	return your_side(LegendsData.finale_team(ch))

# ---------------------------------------------------------------------------------------------------- opponents

# a legend as a match-config player dict (the same keys as Trip.player_dict(), in his era colors), with "signature"
# (his move id, P9-20)
static func legend_player(id: String, ratings: Dictionary) -> Dictionary:
	var p: Dictionary = LegendsData.legend(id)
	var r: Dictionary = {}
	for s in Ratings.STATS:
		r[s] = int(ratings.get(s, Ratings.AVG_RATING))
	r["steal"] = Ratings.derived(int(r["defense"]), int(p.get("steal_bias", 0)))
	r["block"] = Ratings.derived(int(r["defense"]), int(p.get("block_bias", 0)))
	return {"id": id, "name": str(p.get("name", id)), "full": str(p.get("full", p.get("name", id))),
		"sheet": str(p.get("sheet", id)), "role": str(p.get("role", "")), "number": int(p.get("number", 0)),
		"tier": str(p.get("tier", "legend")), "signature": str((p.get("signature", {}) as Dictionary).get("id", "")),
		"ratings": r}

# the challenge's 3 opponents (the legend first) at this level
static func challenge_opponents(id: String, lv: String) -> Array:
	var bonus: int = Difficulty.rating_bonus(lv)
	var out: Array = []
	var team: Array = LegendsData.challenge_team(id)
	for i in team.size():
		var lid: String = str(team[i])
		var r: Dictionary = LegendsData.challenge_ratings(lid, bonus) if i == 0 else LegendsData.mate_ratings(lid, bonus)
		out.append(legend_player(lid, r))
	return out

static func finale_opponents(ch: String, lv: String) -> Array:
	var bonus: int = Difficulty.rating_bonus(lv)
	var out: Array = []
	for lid in LegendsData.finale_team(ch):
		out.append(legend_player(str(lid), LegendsData.finale_ratings(str(lid), bonus)))
	return out

# ---------------------------------------------------------------------------------------------------- matches

static func look_for(ch: String) -> String:
	var look: String = str(LegendsData.chapter(ch).get("look", ""))
	return look if look != "" and Looks.LOOKS.has(look) else FALLBACK_LOOK

static func music_for(ch: String) -> String:
	var row: Dictionary = LegendsData.chapter(ch)
	var own: String = str(row.get("music", ""))
	if own != "" and ResourceLoader.exists(MUSIC_DIR + own + ".ogg"):
		return own
	var fb: String = str(row.get("fallback_music", ""))
	return fb if fb != "" else own

static func twist_for(ch: String) -> String:
	var t: String = str(LegendsData.chapter(ch).get("twist", ""))
	return t if t != "" and Twists.TWISTS.has(t) else NO_TWIST

# Builds a challenge game: sets Flow.match (mode "legends") and returns it; {} for an unknown legend. Never checks
# the gate (the screens do) and never writes anything.
static func match_for_challenge(id: String, level: String = "") -> Dictionary:
	if not LegendsData.is_legend_id(id):
		return {}
	var ch: String = LegendsData.chapter_of(id)
	var lv: String = level_ok(level) if level != "" else default_level()
	var c: Dictionary = (LegendsData.challenge(id) as Dictionary).duplicate(true)
	c["legend"] = id
	c["name"] = str(LegendsData.legend(id).get("name", id))
	var label: String = CHALLENGE_LABEL % [str(LegendsData.chapter(ch).get("name", ch)), str(c["name"])]
	return _build(ch, lv, label, int(c.get("target", 15)), c, challenge_key(id), your_side(LegendsData.challenge_team(id)),
			challenge_opponents(id, lv))

# Builds the chapter's finale (to 21 against its 3 legends); {} for a chapter without one.
static func match_for_finale(ch: String, level: String = "") -> Dictionary:
	var f: Dictionary = LegendsData.chapter(ch).get("finale", {})
	if f.is_empty():
		return {}
	var lv: String = level_ok(level) if level != "" else default_level()
	return _build(ch, lv, str(f.get("label", "FINALE")), int(f.get("target", 21)), {}, finale_key(ch),
			your_side(LegendsData.finale_team(ch)), finale_opponents(ch, lv))

static func _build(ch: String, lv: String, label: String, target: int, c: Dictionary, key: String, side: Dictionary,
		theirs: Array) -> Dictionary:
	var crew: Dictionary = LegendsData.chapter(ch).get("crew", {})
	var m := {
		"mode": MODE,
		"label": label,
		"target": target,
		"look": look_for(ch), "music": music_for(ch), "twist": twist_for(ch),
		"level": lv,
		"chapter": ch,
		"key": key,
		"challenge": c,
		"crew": str(side.get("crew", CREW_KINGS)),
		"human": str(side.get("human", "")),
		"swaps": (side.get("swaps", []) as Array).duplicate(true),
		"note": str(side.get("note", "")),
		"teams": [
			{"name": Cities.CREW_NAME, "style": "", "players": side.get("players", [])},
			{"name": str(crew.get("name", "")), "style": str(crew.get("style", "")), "players": theirs,
				"colors": crew.get("colors", [])},
		],
	}
	Flow.match = m
	return m

# ---------------------------------------------------------------------------------------------------- results

# Records a finished legends game (flow.gd passes Flow.last_result, Flow.match is still this game's) and saves.
# Won = result.won and the challenge goal met (result.challenge.met; no verdict = met). Returns and keeps in
# last_outcome: {"won", "key", "tokens_got", "tokens_before", "tokens_now", "unlocked": id or "", "chapter_done",
# "failed": "<why>" or "", "chapter", "legend", "finale", "level"}. tokens_before / tokens_now: this key's best.
static func record_result(result: Dictionary) -> Dictionary:
	load_state()
	var m: Dictionary = Flow.match
	var key: String = str(m.get("key", ""))
	var lv: String = level_ok(str(m.get("level", "")))
	var is_finale: bool = key.begins_with(KEY_FINALE)
	var lid: String = key.substr(KEY_CHALLENGE.length()) if key.begins_with(KEY_CHALLENGE) else ""
	# P10-02: the chapter comes from the key (the legend's chapter, or the finale's), so any built chapter records
	# and closes the same way; Flow.match.chapter only when the key names none
	var ch: String = str(m.get("chapter", ""))
	if lid != "" and LegendsData.chapter_of(lid) != "":
		ch = LegendsData.chapter_of(lid)
	elif is_finale:
		ch = key.substr(KEY_FINALE.length())
	var won: bool = bool(result.get("won", false))
	var failed: String = ""
	var v = result.get("challenge", null)
	if v is Dictionary and not bool((v as Dictionary).get("met", true)):
		won = false
		failed = str((v as Dictionary).get("why", ""))
		if failed == "":
			failed = "goal not met"
	if not won and failed == "" and not bool(result.get("won", false)):
		failed = "lost"
	var before: int = int(tokens.get(key, 0))
	var out := {"won": won, "key": key, "tokens_got": 0, "tokens_before": before, "tokens_now": before,
		"unlocked": "", "chapter_done": false, "failed": failed, "chapter": ch, "legend": lid, "finale": is_finale,
		"level": lv}
	if key == "" or (lid == "" and not is_finale) or (lid != "" and not LegendsData.is_legend_id(lid)) \
			or (is_finale and not (LegendsData.is_built(ch) and LegendsData.has_finale(ch))):
		out["failed"] = "not a legends game"
		out["won"] = false
		last_outcome = out
		return out
	if won:
		var got: int = LegendsData.tokens_for(lv)
		out["tokens_got"] = got
		if got > before:
			tokens[key] = got
		out["tokens_now"] = int(tokens.get(key, 0))
		if lid != "" and not unlocked.has(lid):
			unlocked.append(lid)
			out["unlocked"] = lid
		if is_finale and ch != "" and not finales.has(ch):
			finales.append(ch)
		out["chapter_done"] = is_finale and finales.has(ch)
		save()
	print("LEGENDS RESULT %s %s %s | tokens %d -> %d (+%d) | unlocked %s | chapter done %s%s" % [key, lv,
			"won" if won else "lost", before, int(out["tokens_now"]), int(out["tokens_got"]),
			str(out["unlocked"]) if str(out["unlocked"]) != "" else "-", str(out["chapter_done"]),
			(" | " + failed) if failed != "" else ""])
	last_outcome = out
	return out

# Where flow.gd goes after a legends game: {"screen", "args"}. A new unlock: his unlock scene (once), then the chapter
# view; a won finale: its "after" scene (once), then the chapter view; else the chapter view (the timeline without a
# chapter). A scene story_text.gd doesn't have is skipped.
static func after_result() -> Dictionary:
	var o: Dictionary = last_outcome
	var ch: String = str(o.get("chapter", ""))
	var back: Dictionary = {"chapter": ch} if ch != "" else {}
	var scene: String = ""
	if str(o.get("unlocked", "")) != "":
		scene = str(LegendsData.legend(str(o["unlocked"])).get("unlock_scene", ""))
	elif bool(o.get("won", false)) and bool(o.get("finale", false)):
		scene = str((LegendsData.chapter(ch).get("finale_scenes", {}) as Dictionary).get("after", ""))
	if scene != "" and StoryText.has_scene(scene) and mark_seen(scene):
		return {"screen": "story", "args": {"scene": scene, "then": SCREEN, "then_args": back}}
	return {"screen": SCREEN, "args": back}

# ---------------------------------------------------------------------------------------------------- test flags

static func _parse_unlock_flag() -> String:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	if cmd.has(UNLOCK_ALL_FLAG):
		return "all"
	if cmd.has(UNLOCK_NONE_FLAG):
		return "none"
	return ""

static func _parse_tokens_flag() -> int:
	var s: String = _flag(TOKENS_FLAG)
	if s.is_valid_int():
		return clampi(s.to_int(), 0, 9999)
	return -1

# `--name value` or `--name=value`, or ""
static func _flag(flag_name: String) -> String:
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	for i in cmd.size():
		if cmd[i].begins_with(flag_name + "="):
			return cmd[i].substr(flag_name.length() + 1).strip_edges()
		if cmd[i] == flag_name and i + 1 < cmd.size():
			return cmd[i + 1].strip_edges()
	return ""

# --challenge's id: a legend id, his short name ("steeple", "set_shot"), "finale" (the first built chapter's),
# "fin:<chapter>" or a chapter id (any built chapter: "fathers", "fin:fathers" once it is built) -> "lg:<id>" /
# "fin:<ch>", or "" for anything else (a chapter that isn't built has no finale)
static func parse_challenge(s: String) -> String:
	var v: String = s.strip_edges().to_lower()
	if v == "":
		return ""
	if LegendsData.is_legend_id(v):
		return challenge_key(v)
	if LegendsData.is_legend_id(LegendsData.ID_PREFIX + v):
		return challenge_key(LegendsData.ID_PREFIX + v)
	if v.begins_with(KEY_CHALLENGE) and LegendsData.is_legend_id(v.substr(KEY_CHALLENGE.length())):
		return v
	var ch: String = v.substr(KEY_FINALE.length()) if v.begins_with(KEY_FINALE) else v
	if v == "finale" and not LegendsData.built_chapters().is_empty():
		ch = str(LegendsData.built_chapters()[0])
	if LegendsData.is_built(ch) and LegendsData.has_finale(ch):
		return finale_key(ch)
	return ""

# main.gd under --challenge <id> (a test run): builds that game as Flow.match and returns it ({} without the flag or
# for an unknown id). The level: --difficulty's, else default_level(). Your side: the test trip save if there is one,
# else the Kings; with --expected-roster / --best-roster the end-of-trip crew of that kind (Trip.end_of_trip_crew(),
# P9-21; without it, the usual side and a note). Prints one LEGENDS MATCH line.
static func test_match() -> Dictionary:
	var raw: String = _flag(CHALLENGE_FLAG)
	if raw == "" and not OS.get_cmdline_user_args().has(CHALLENGE_FLAG):
		return {}
	var key: String = parse_challenge(raw)
	if key == "":
		print("LEGENDS MATCH: unknown --challenge '%s' (a legend id like lg_steeple, a short name, finale)" % raw)
		return {}
	var lv: String = level_ok(_flag(DIFFICULTY_FLAG)) if _flag(DIFFICULTY_FLAG) != "" else default_level()
	var m: Dictionary = {}
	if key.begins_with(KEY_CHALLENGE):
		m = match_for_challenge(key.substr(KEY_CHALLENGE.length()), lv)
	else:
		m = match_for_finale(key.substr(KEY_FINALE.length()), lv)
	var cmd: PackedStringArray = OS.get_cmdline_user_args()
	if not m.is_empty() and (cmd.has(EXPECTED_FLAG) or cmd.has(BEST_FLAG)):
		var best: bool = cmd.has(BEST_FLAG)
		var ts: GDScript = load(TRIP_PATH) as GDScript   # by load: end_of_trip_crew() comes with P9-21
		if ts != null and ts.has_method("end_of_trip_crew"):
			var got = ts.call("end_of_trip_crew", best)
			var opp: Array = []
			for pd in (m["teams"][1] as Dictionary).get("players", []):
				opp.append(str((pd as Dictionary).get("id", "")))
			if got is Array and (got as Array).size() == Trip.STARTERS:
				var ps: Array = []
				for gp in (got as Array):
					ps.append(_no_perk(gp).duplicate(true) if gp is Dictionary else gp)   # no perks in a challenge
				var clash: bool = false
				for pd in ps:
					if pd is Dictionary and opp.has(str((pd as Dictionary).get("id", ""))):
						clash = true
				if not clash:
					m["teams"][0]["players"] = ps
					m["crew"] = CREW_TRIP
					m["crew_test"] = "best" if best else "expected"
					m["human"] = str((ps[0] as Dictionary).get("id", ""))
					m["swaps"] = []
					m["note"] = ""
				else:
					print("LEGENDS MATCH: end_of_trip_crew(%s) holds an opponent, kept the usual side" % str(best))
		else:
			print("LEGENDS MATCH: Trip.end_of_trip_crew() is not there yet (P9-21), playing the usual side")
	if not m.is_empty():
		print(match_line(m))
	return m

# "LEGENDS MATCH <key> <level> crew <crew> | to N | twist | look | music | BLUE ... | RED ... | note"
static func match_line(m: Dictionary) -> String:
	var parts: Array = []
	for t in 2:
		var ps: Array = []
		for p in (m["teams"][t] as Dictionary).get("players", []):
			var r: Dictionary = (p as Dictionary).get("ratings", {})
			ps.append("%s %d/%d/%d/%d/%d" % [str(p.get("id", "")), int(r.get("speed", 0)), int(r.get("shooting", 0)),
					int(r.get("finishing", 0)), int(r.get("defense", 0)), int(r.get("stamina", 0))])
		parts.append("%s %s" % ["BLUE" if t == 0 else "RED", ", ".join(PackedStringArray(ps))])
	return "LEGENDS MATCH %s %s crew %s%s | to %d | twist %s | look %s | music %s | %s%s" % [str(m.get("key", "")),
			str(m.get("level", "")), str(m.get("crew", "")),
			(" (" + str(m.get("crew_test", "")) + ")") if str(m.get("crew_test", "")) != "" else "",
			int(m.get("target", 0)), str(m.get("twist", "")), str(m.get("look", "")), str(m.get("music", "")),
			" | ".join(PackedStringArray(parts)), (" | " + str(m.get("note", ""))) if str(m.get("note", "")) != "" else ""]

# ---------------------------------------------------------------------------------------------------- --legendtest

# main.gd under --legendtest: the data (LegendsData.self_test(), the name check), the save file
# (LegendsSave.self_test()) and this file (self_test()). Prints the notes, one line per part and LEGENDTEST OK or
# LEGENDTEST FAILED: <why>; true when OK (main.gd quits with 0, else 1).
static func legendtest() -> bool:
	var why: String = LegendsData.self_test()
	for n in LegendsData.notes:
		print("LEGENDTEST NOTE: ", n)
	print("LEGENDTEST data: legends %d, chapters %d built of %d, max tokens %d: %s" % [LegendsData.LEGENDS.size(),
			LegendsData.built_chapters().size(), LegendsData.CHAPTERS.size(), LegendsData.max_tokens(),
			"OK" if why == "" else why])
	var why_save: String = LegendsSave.self_test()
	print("LEGENDTEST save: %s" % ("OK" if why_save == "" else why_save))
	var why_prog: String = self_test()
	print("LEGENDTEST progress: %s" % ("OK" if why_prog == "" else why_prog))
	# P11-33: the Quick Game era teams (era_teams.gd, loaded at run time; missing = nothing to check)
	var why_era: String = ""
	if ResourceLoader.exists(ERA_TEAMS_PATH):
		var et: GDScript = load(ERA_TEAMS_PATH) as GDScript
		why_era = str(et.call("self_test")) if et != null and et.has_method("self_test") else "era_teams.gd has no self_test()"
		print("LEGENDTEST era teams %s: %s" % [str(et.call("ids")) if et != null and et.has_method("ids") else "[]",
				"OK" if why_era == "" else why_era])
	var all: Array = []
	for w in [why, why_save, why_prog, why_era]:
		if str(w) != "":
			all.append(str(w))
	if not all.is_empty():
		print("LEGENDTEST FAILED: ", "; ".join(PackedStringArray(all)))
		return false
	print("LEGENDTEST OK")
	return true

# ---------------------------------------------------------------------------------------------------- self test

# Records, gates, unlocks, both crew sources, the swap, the match fields, the trip file unchanged byte for byte after
# a challenge, a save round trip; P10-18 / P11-18: the three shipped chapters and their gates (_check_shipped_gates()),
# then every shipped built chapter (_check_chapter_walk()); P10-02 / P11-03 / P12-03: two, three and four built
# chapters on stand-in rows (_check_two_chapters(), _check_three_chapters(), _check_four_chapters()). Its own Legends file
# (SELFTEST_PATH); its own scripted trip in the test trip save
# (P9-28: whatever a trip or legends run left there is kept aside and put back byte for byte at the end, so the test
# never depends on it); every static of this file, Trip's and Stars' --stars is put back. "" = OK.
static func self_test() -> String:
	var errs: Array = []
	# keep everything this test changes
	var kept: Dictionary = to_dict()
	var kept_loaded: bool = _loaded
	var kept_outcome: Dictionary = last_outcome.duplicate(true)
	var kept_saving: bool = saving
	var kept_unlock: String = unlock_override
	var kept_force: int = force_tokens
	var kept_stars: int = Stars.force_total
	var kept_match: Dictionary = Flow.match.duplicate(true)
	var kept_trip_active: bool = Trip.active
	var kept_trip: Dictionary = Trip.to_dict() if Trip.active else {}
	var kept_trip_saving: bool = Trip.saving
	var kept_test_file: bool = Save.use_test_file
	Save.use_test_file = true   # only ever the test trip save here
	var trip_path: String = Save.path()
	var trip_bytes: PackedByteArray = _bytes(trip_path)
	var trip_had: bool = FileAccess.file_exists(trip_path)
	var trip_tmp_had: bool = FileAccess.file_exists(trip_path + Save.TMP_SUFFIX)
	var trip_tmp_bytes: PackedByteArray = _bytes(trip_path + Save.TMP_SUFFIX)
	# P9-28: never the test trip a trip or legends run left behind: a fresh scripted trip in its place (from the very
	# first match_for_challenge() on), and the old file put back byte for byte at the end
	Trip.saving = false
	_remove_trip_files(trip_path)
	Trip.new_trip(SELFTEST_TRIP_LEVEL)
	Trip.saving = true
	Trip.save()
	Trip.saving = false
	Trip.active = false
	LegendsSave._path_override = SELFTEST_PATH
	_wipe()
	saving = true
	unlock_override = ""
	force_tokens = -1
	_from_dict({})
	_loaded = true

	var ids: Array = LegendsData.legend_ids("grand")
	_check(errs, ids.size() == 6, "chapter grand has %d legends" % ids.size())
	var first: String = str(ids[0]) if not ids.is_empty() else "lg_steeple"

	# keys and gates
	_check(errs, challenge_key(first) == "lg:" + first and finale_key("grand") == "fin:grand", "keys")
	_check(errs, gate_text("grand") == "24 STARS", "gate_text grand '%s'" % gate_text("grand"))
	_check(errs, gate_text("fathers") == "36 STARS OR 12 TOKENS", "gate_text fathers '%s'" % gate_text("fathers"))
	Stars.force_total = 23
	_check(errs, not mode_open() and not chapter_open("grand"), "open at 23 stars")
	Stars.force_total = 24
	_check(errs, mode_open() and chapter_open("grand") and mode_gate_text() == "24 STARS", "closed at 24 stars")
	_check(errs, not chapter_open("fathers") and not gate_met("fathers"), "fathers open at 24 stars")
	force_tokens = 12
	_check(errs, gate_met("fathers") and chapter_open("fathers") == LegendsData.is_built("fathers"),
			"fathers: 12 tokens gate / open only once built")
	_check(errs, tokens_total() == 12 and real_tokens_total() == 0, "--tokens override")
	force_tokens = -1
	Stars.force_total = 72
	_check(errs, chapter_open("next") == LegendsData.is_built("next") and gate_met("next"), "next at 72 stars")
	_check(errs, not chapter_open("nowhere") and gate_text("nowhere") == "", "unknown chapter")
	_check(errs, level_ok("legend") == "legend" and offered_levels().size() == 4, "legend level at 72 stars")
	Stars.force_total = 24
	_check(errs, level_ok("legend") == "hard" and offered_levels().size() == 3, "legend level closed at 24 stars")
	_check(errs, level_ok("bogus") == FALLBACK_LEVEL and level_ok(" Easy ") == "easy", "level_ok")

	# records: a win unlocks once, tokens best kept, losses and broken goals give nothing
	match_for_challenge(first, "normal")
	var o: Dictionary = record_result({"won": false})
	_check(errs, not bool(o["won"]) and int(o["tokens_now"]) == 0 and str(o["unlocked"]) == "" and str(o["failed"]) != "",
			"loss recorded as %s" % str(o))
	_check(errs, not is_unlocked(first) and after_result()["screen"] == SCREEN, "loss: unlocked or not back")
	o = record_result({"won": true, "challenge": {"type": "hold", "met": false, "why": "he scored 6"}})
	_check(errs, not bool(o["won"]) and str(o["failed"]) == "he scored 6" and int(o["tokens_now"]) == 0,
			"won with the goal broken: %s" % str(o))
	o = record_result({"won": true, "challenge": {"type": "hold", "met": true, "why": ""}})
	_check(errs, bool(o["won"]) and int(o["tokens_got"]) == 2 and int(o["tokens_now"]) == 2 and str(o["unlocked"]) == first,
			"normal win: %s" % str(o))
	_check(errs, is_unlocked(first) and unlocked_ids() == [first] and token_best(challenge_key(first)) == 2,
			"after the first win")
	var nxt: Dictionary = after_result()
	var scene: String = str(LegendsData.legend(first).get("unlock_scene", ""))
	if StoryText.has_scene(scene):
		_check(errs, nxt["screen"] == "story" and nxt["args"].get("scene", "") == scene
				and nxt["args"].get("then", "") == SCREEN and nxt["args"].get("then_args", {}).get("chapter", "") == "grand",
				"unlock: after_result %s" % str(nxt))
		_check(errs, has_seen(scene) and after_result()["screen"] == SCREEN, "unlock scene shown twice")
	else:
		_check(errs, nxt["screen"] == SCREEN and nxt["args"].get("chapter", "") == "grand",
				"unlock without a scene: %s" % str(nxt))
	match_for_challenge(first, "easy")
	o = record_result({"won": true})
	_check(errs, int(o["tokens_got"]) == 1 and int(o["tokens_now"]) == 2 and str(o["unlocked"]) == "",
			"easy win after normal: %s" % str(o))
	match_for_challenge(first, "hard")
	o = record_result({"won": true})
	_check(errs, int(o["tokens_now"]) == 3 and int(o["tokens_before"]) == 2, "hard win: %s" % str(o))
	_check(errs, not finale_open("grand"), "finale open after one legend")
	# the other five, the finale opens; a finale win closes the chapter
	for i in range(1, ids.size()):
		match_for_challenge(str(ids[i]), "easy")
		record_result({"won": true})
	_check(errs, unlocked_ids().size() == 6 and finale_open("grand") and not chapter_done("grand"), "all six beaten")
	_check(errs, tokens_total() == 3 + 5 and chapter_tokens("grand") == 8 and chapter_max_tokens("grand") == 21,
			"tokens %d / chapter %d" % [tokens_total(), chapter_tokens("grand")])
	var fm: Dictionary = match_for_finale("grand", "normal")
	_check(errs, str(fm.get("key", "")) == "fin:grand" and (fm.get("challenge", null) as Dictionary).is_empty()
			and int(fm.get("target", 0)) == 21, "finale match %s" % str(fm.get("key", "")))
	o = record_result({"won": true})
	_check(errs, bool(o["won"]) and bool(o["chapter_done"]) and bool(o["finale"]) and chapter_done("grand")
			and int(o["tokens_now"]) == 2 and str(o["unlocked"]) == "", "finale win: %s" % str(o))
	_check(errs, after_result()["screen"] in ["story", SCREEN], "finale after_result")
	Flow.match = {"mode": MODE, "key": "lg:lg_nobody"}
	o = record_result({"won": true})
	_check(errs, not bool(o["won"]) and str(o["failed"]) == "not a legends game", "unknown key recorded")

	# the save round trip (in SELFTEST_PATH), then a fresh load reads it all back
	var before: String = JSON.stringify(to_dict(), "", true)
	_check(errs, save(), "save: %s" % LegendsSave.last_error)
	_from_dict({})
	load_state(true)
	_check(errs, JSON.stringify(to_dict(), "", true) == before, "round trip %s" % JSON.stringify(to_dict()))
	saving = false
	_from_dict({})
	_check(errs, not save(), "saved with saving off")
	load_state(true)
	_check(errs, unlocked.size() == 6, "saving off still wrote")
	saving = true

	# the unlock overrides (never saved)
	_from_dict({})
	unlock_override = "all"
	_check(errs, is_unlocked(first) and unlocked_ids().size() == LegendsData.legend_ids().size() and finale_open("grand")
			and not chapter_done("grand"), "--legends-unlock-all")
	unlock_override = "none"
	_from_dict({"unlocked": [first]})
	_check(errs, not is_unlocked(first) and unlocked_ids().is_empty(), "--legends-unlock-none")
	unlock_override = ""
	_check(errs, is_unlocked(first) and not is_unlocked("lg_nobody") and not is_unlocked("ud_jojo"), "is_unlocked")

	# the Kings: no trip
	Trip.active = false
	_skip_trip_load = true
	var km: Dictionary = match_for_challenge(first, "normal")
	_check(errs, str(km.get("mode", "")) == MODE and Flow.in_legends() and str(km.get("crew", "")) == CREW_KINGS
			and str(km.get("note", "")) == NO_TRIP_NOTE, "kings match crew %s" % str(km.get("crew", "")))
	var kp: Array = km["teams"][0]["players"]
	_check(errs, kp.size() == 3 and str(kp[0].get("id", "")) == str(Trip.QUICK_KINGS[0]) and str(km["human"]) == str(kp[0]["id"]),
			"kings players")
	for p in kp:
		var s: int = _sum((p as Dictionary).get("ratings", {}))
		_check(errs, absi(s - 5 * Trip.QUICK_AVG) <= 3, "king %s sum %d" % [str(p.get("id", "")), s])
	_check_match(errs, km, first, "normal")
	var lm: Dictionary = match_for_challenge(first, "legend")
	_check(errs, str(lm["level"]) == "hard", "legend level at 24 stars: %s" % str(lm["level"]))
	Stars.force_total = 72
	lm = match_for_challenge(first, "legend")
	_check_match(errs, lm, first, "legend")
	var dl: String = default_level()
	Difficulty.init_once()
	_check(errs, dl == level_ok(Difficulty.level_name(Difficulty.level)), "default level without a trip %s" % dl)
	_skip_trip_load = false

	# your trip: the scripted trip written at the start (read only from here on)
	Trip.saving = false
	Trip.active = false
	var on_disk: PackedByteArray = _bytes(trip_path)
	var trip_dict_disk: String = JSON.stringify(Save.read(), "", true)
	var tm: Dictionary = match_for_challenge(first, "")
	_check(errs, Trip.active and str(tm.get("crew", "")) == CREW_TRIP and str(tm.get("note", "")) == "",
			"trip match crew %s" % str(tm.get("crew", "")))
	_check(errs, str(tm.get("level", "")) == level_ok(Trip.level), "trip level %s vs %s" % [str(tm.get("level", "")), Trip.level])
	var tp: Array = tm["teams"][0]["players"]
	_check(errs, tp.size() == 3 and str(tp[0].get("id", "")) == Trip.human, "trip players: you first")
	for p in tp:
		var want: Dictionary = Trip.roster_player(str(p.get("id", "")))
		_check(errs, Trip.starters.has(str(p.get("id", ""))) and JSON.stringify(want) == JSON.stringify(p),
				"trip player %s is not the roster's" % str(p.get("id", "")))
	var trip_mem: String = JSON.stringify(Trip.to_dict(), "", true)
	record_result({"won": true})
	after_result()
	match_for_finale("grand", "hard")
	record_result({"won": false})
	_check(errs, _bytes(trip_path) == on_disk, "the trip file changed after a challenge")
	_check(errs, JSON.stringify(Save.read(), "", true) == trip_dict_disk, "the trip save reads differently")
	_check(errs, JSON.stringify(Trip.to_dict(), "", true) == trip_mem, "the trip in memory changed")

	# mentors (P9-23): assign, switch, one perk per player, one pupil per legend, the perk in trip games only
	_check_mentors(errs, ids)

	# the swap: a drafted legend who is an opponent sits; the strongest bench non-legend plays (in your slot if he was
	# you); a legend who isn't an opponent plays
	var mem: Dictionary = Trip.to_dict()
	var lg_r: Dictionary = LegendsData.draft_ratings(first, 60)
	Trip.roster_data.append({"id": first, "ratings": lg_r, "pts": 0, "via": "draft"})
	var bench_ids: Array = []
	for id in Trip.roster_ids():
		if not Trip.starters.has(id) and str(id) != first:
			bench_ids.append(str(id))
	var keep: Array = Trip.starters.duplicate()
	if bench_ids.is_empty():
		# a fresh roster: one starter goes to the bench, so somebody can come in
		bench_ids.append(str(keep[2]))
	var others: Array = []
	for id in keep:
		if not bench_ids.has(str(id)):
			others.append(str(id))
	Trip.starters = [first, str(others[0]), str(others[1])]
	Trip.human = first
	var strongest: String = ""
	var best_sum: int = -1
	for id in Trip.roster_ids():
		var sid: String = str(id)
		if Trip.starters.has(sid) or _is_legend(sid):
			continue
		var s: int = _sum(Trip.roster_player(sid).get("ratings", {}))
		if s > best_sum:
			best_sum = s
			strongest = sid
	var sm: Dictionary = match_for_challenge(first, "normal")
	var sp: Array = sm["teams"][0]["players"]
	_check(errs, str(sp[0].get("id", "")) == strongest and str(sm["human"]) == strongest, "swap: %s not in for %s (got %s)"
			% [strongest, first, str(sp[0].get("id", ""))])
	_check(errs, (sm["swaps"] as Array).size() == 1 and str(sm["swaps"][0]["out"]) == first
			and str(sm["note"]) == SWAP_NOTE % [str(LegendsData.legend(first)["name"]), _short_name(sp[0])],
			"swap note '%s'" % str(sm["note"]))
	for p in sp:
		_check(errs, str(p.get("id", "")) != first, "the legend plays against himself")
	var other_lg: String = ""
	for id in ids:
		if not LegendsData.challenge_team(str(id)).has(first):
			other_lg = str(id)
	if other_lg != "":
		var om: Dictionary = match_for_challenge(other_lg, "normal")
		_check(errs, str(om["teams"][0]["players"][0].get("id", "")) == first and (om["swaps"] as Array).is_empty(),
				"%s sat out against %s" % [first, other_lg])
	_check(errs, Trip.starters[0] == first, "the swap changed the trip's starters")
	mem["version"] = Save.VERSION
	Trip.from_dict(mem)

	# parse_challenge (the --challenge ids)
	_check(errs, parse_challenge(first) == "lg:" + first and parse_challenge(first.substr(3).to_upper()) == "lg:" + first
			and parse_challenge("finale") == "fin:grand" and parse_challenge("grand") == "fin:grand"
			and parse_challenge("fin:grand") == "fin:grand"
			and parse_challenge("fathers") == ("fin:fathers" if LegendsData.is_built("fathers") else "")
			and parse_challenge(_unbuilt_chapter()) == "" and parse_challenge(finale_key(_unbuilt_chapter())) == ""
			and parse_challenge("nobody") == "", "parse_challenge")

	# P10-18, P11-18: every shipped built chapter (gates, matches, records, scenes, finales, the swap, mentors of every
	# era); first the three shipped chapters and the owner's gates
	_check_shipped_gates(errs)
	_check_chapter_walk(errs, trip_path, "shipped", SHIPPED_CHAPTERS)

	# P10-02: a stand-in second built chapter (test data only), then the shipped rows again
	_check_two_chapters(errs, trip_path)

	# P11-03: three built chapters (the third row a stand-in, test data only), then the shipped rows again
	_check_three_chapters(errs, trip_path)

	# P12-03: four built chapters (the fourth row a stand-in, test data only), then the shipped rows again
	_check_four_chapters(errs, trip_path)

	# put everything back (the test trip file as it was, or none)
	_remove_trip_files(trip_path)
	if trip_had:
		_put_bytes(trip_path, trip_bytes)
	if trip_tmp_had:
		_put_bytes(trip_path + Save.TMP_SUFFIX, trip_tmp_bytes)
	_check(errs, FileAccess.file_exists(trip_path) == trip_had and _bytes(trip_path) == trip_bytes
			and FileAccess.file_exists(trip_path + Save.TMP_SUFFIX) == trip_tmp_had
			and _bytes(trip_path + Save.TMP_SUFFIX) == trip_tmp_bytes, "the test trip file was not put back")
	Trip.saving = kept_trip_saving
	if kept_trip_active:
		kept_trip["version"] = Save.VERSION
		Trip.from_dict(kept_trip)
	else:
		Trip._reset()
	Save.use_test_file = kept_test_file
	_wipe()
	LegendsSave._path_override = ""
	_from_dict(kept)
	_loaded = kept_loaded
	last_outcome = kept_outcome
	saving = kept_saving
	unlock_override = kept_unlock
	force_tokens = kept_force
	Stars.force_total = kept_stars
	Flow.match = kept_match
	_skip_trip_load = false
	if errs.is_empty():
		return ""
	var shown: Array = errs.slice(0, 6)
	return "; ".join(PackedStringArray(shown)) + ("" if errs.size() <= 6 else " (+%d more)" % (errs.size() - 6))

# P11-18: the shipped rows hold SHIPPED_CHAPTERS built chapters in timeline order, each with the gate the owner set
# (SHIPPED_GATES; the Present's P7 a: 48 stars or 30 tokens) and its gate line; at the gate of the chapter before it a
# chapter stays shut, at its own it opens with no earlier finale won (a fresh Legends state). Every --tokens and
# --stars override and the Legends state are put back (fresh).
static func _check_shipped_gates(errs: Array) -> void:
	var kept_stars: int = Stars.force_total
	var kept_force: int = force_tokens
	_from_dict({})
	_loaded = true
	var chs: Array = LegendsData.built_chapters()
	var keys: Array = SHIPPED_GATES.keys()
	# P12-03: the built rows are the first SHIPPED_CHAPTERS or more rows of SHIPPED_GATES, every row there in data order
	_check(errs, not LegendsData.test_data_on() and chs.size() >= SHIPPED_CHAPTERS and chs == keys.slice(0, chs.size())
			and LegendsData.chapter_ids() == keys, "shipped: built chapters %s, want the first %d+ of %s" % [str(chs),
			SHIPPED_CHAPTERS, str(keys)])
	for ch in SHIPPED_GATES:
		var want: Dictionary = SHIPPED_GATES[ch]
		var gate: Dictionary = LegendsData.chapter(str(ch)).get("gate", {})
		var ns: int = int(want.get("stars", 0))
		var nt: int = int(want.get("tokens", 0))
		var line: String = ("%d STARS" % ns) + ((" OR %d TOKENS" % nt) if nt > 0 else "")
		_check(errs, int(gate.get("stars", 0)) == ns and int(gate.get("tokens", 0)) == nt
				and gate_text(str(ch)) == line, "shipped: %s gate %s '%s', want '%s'" % [ch, str(gate), gate_text(str(ch)), line])
		if not chs.has(str(ch)):
			continue   # a row not built yet: its gate only (it never opens)
		force_tokens = 0
		Stars.force_total = ns - 1
		var shut: bool = not chapter_open(str(ch))
		Stars.force_total = ns
		var by_stars: bool = chapter_open(str(ch))
		var by_tokens: bool = true
		if nt > 0:
			Stars.force_total = 0
			force_tokens = nt - 1
			shut = shut and not chapter_open(str(ch))
			force_tokens = nt
			by_tokens = chapter_open(str(ch))
		var no_finale: bool = true
		for other in SHIPPED_GATES:
			no_finale = no_finale and not chapter_done(str(other)) and not finale_open(str(other))
		_check(errs, shut and by_stars and by_tokens and no_finale, "shipped: %s gate (shut %s, stars %s, tokens %s)"
				% [ch, str(shut), str(by_stars), str(by_tokens)])
	# each gate shuts the chapter after it (the Present at the Fathers' 36 stars or 12 tokens)
	for k in range(1, chs.size()):
		var gp: Dictionary = SHIPPED_GATES[keys[k - 1]]
		Stars.force_total = int(gp.get("stars", 0))
		force_tokens = int(gp.get("tokens", 0))
		_check(errs, chapter_open(str(keys[k - 1])) and not chapter_open(str(keys[k])), "shipped: %s open at %s's gate"
				% [keys[k], keys[k - 1]])
	force_tokens = kept_force
	Stars.force_total = kept_stars
	_from_dict({})
	_loaded = true

# P10-18, P11-03: every built chapter of the rows in use (the shipped ones; in _check_three_chapters() the stand-in
# three), data-driven over built_chapters(), however many there are: each gate (stars, --tokens and real tokens from
# the chapters before it, no finale needed: F7 a), every challenge and finale match of each chapter (its own opponents,
# look, twist, music, label), the intro scenes (seen once), records per chapter (tokens, unlocks in data order, the
# unlock and "after" scenes going back to their own chapter view, a finale closing only its chapter), a drafted legend
# of each era sitting only against his own opponents, mentors from every era side by side, and the test trip file
# unchanged. Shipped rows must have every scene and distinct perks; a stand-in's missing scenes are skipped. Starts and
# ends on a fresh Legends state (in SELFTEST_PATH); the trip in memory put back. tag starts every error line.
static func _check_chapter_walk(errs: Array, trip_path: String, tag: String, want: int) -> void:
	var trip_disk: PackedByteArray = _bytes(trip_path)
	var trip_mem: Dictionary = Trip.to_dict()
	var chs: Array = LegendsData.built_chapters()
	var strict: bool = not LegendsData.test_data_on()
	# P11-11: a shipped chapter's scenes are checked strictly once story_text.gd has its intro scene (LegendsData's own
	# rule: a chapter's data may land before its story, and the story screen skips the missing scenes meanwhile)
	var strict_ch: Dictionary = {}
	for ch in chs:
		strict_ch[str(ch)] = strict and StoryText.has_scene(str(LegendsData.chapter(str(ch)).get("intro_scene", "")))
	_check(errs, chs.size() >= want and chs.size() >= 2, "%s: %d built chapters, want %d+" % [tag, chs.size(), want])
	if chs.size() < want or chs.size() < 2:
		return
	var by_ch: Dictionary = {}
	var all_ids: Array = []
	for ch in chs:
		var ids: Array = LegendsData.legend_ids(str(ch))
		_check(errs, ids.size() == 6, "%s: %s has %d legends" % [tag, ch, ids.size()])
		if ids.size() != 6:
			return
		by_ch[str(ch)] = ids
		all_ids += ids
	var n: int = chs.size()
	var c1: String = str(chs[0])
	var ids1: Array = by_ch[c1]
	_from_dict({})
	_loaded = true
	unlock_override = ""

	# gates: each chapter at its stars and its tokens (--tokens), one short of each stays shut
	for ch in chs:
		var gate: Dictionary = LegendsData.chapter(str(ch)).get("gate", {})
		var ns: int = int(gate.get("stars", 0))
		var nt: int = int(gate.get("tokens", 0))
		force_tokens = 0
		if ns > 0:
			Stars.force_total = ns - 1
			_check(errs, not chapter_open(str(ch)), "%s: %s open at %d stars" % [tag, ch, ns - 1])
			Stars.force_total = ns
			_check(errs, chapter_open(str(ch)), "%s: %s closed at %d stars" % [tag, ch, ns])
		if nt > 0:
			Stars.force_total = 0
			force_tokens = nt - 1
			_check(errs, not chapter_open(str(ch)), "%s: %s open at %d tokens" % [tag, ch, nt - 1])
			force_tokens = nt
			_check(errs, chapter_open(str(ch)), "%s: %s closed at %d tokens" % [tag, ch, nt])
	# P11-18: the gates rise along the timeline: at the gate of the chapter before it (its stars and its tokens) a chapter
	# stays shut, and at its own stars every chapter before it is open too (tokens alone open only the chapters that
	# have a token gate: Chapter 1 has none, and real tokens need it open anyway)
	for k in range(1, n):
		var gp: Dictionary = LegendsData.chapter(str(chs[k - 1])).get("gate", {})
		Stars.force_total = int(gp.get("stars", 0))
		force_tokens = int(gp.get("tokens", 0))
		_check(errs, chapter_open(str(chs[k - 1])) and not chapter_open(str(chs[k])), "%s: %s open at %s's gate"
				% [tag, chs[k], chs[k - 1]])
		var gk: Dictionary = LegendsData.chapter(str(chs[k])).get("gate", {})
		if int(gk.get("stars", 0)) > 0:
			Stars.force_total = int(gk.get("stars", 0))
			force_tokens = 0
			var before_open: bool = true
			for j in k:
				before_open = before_open and chapter_open(str(chs[j]))
			_check(errs, before_open, "%s: a chapter before %s shut at its stars" % [tag, chs[k]])
	force_tokens = -1
	Stars.force_total = 0
	_check(errs, not mode_open(), "%s: open at 0 stars, 0 tokens" % tag)
	# each later chapter's token gate from real tokens of the chapters before it (Hard wins in data order), none of
	# their finales played (F7 a)
	for k in range(1, n):
		var ck: String = str(chs[k])
		var ntk: int = int((LegendsData.chapter(ck).get("gate", {}) as Dictionary).get("tokens", 0))
		if ntk <= 0:
			continue
		_from_dict({})
		_loaded = true
		var earlier: Array = []
		for j in k:
			earlier += by_ch[str(chs[j])]
		var i: int = 0
		while real_tokens_total() < ntk and i < earlier.size():
			_check(errs, not chapter_open(ck), "%s: %s open at %d real tokens" % [tag, ck, real_tokens_total()])
			match_for_challenge(str(earlier[i]), "hard")
			record_result({"won": true})
			i += 1
		# no finale won (P12-03: a finale may be open by then: 48 tokens of 3 chapters' 18 challenges need all 6 of one
		# chapter beaten, and the Fathers are open by their own 12 tokens)
		var no_finale: bool = true
		for j in k:
			if chapter_done(str(chs[j])):
				no_finale = false
		_check(errs, real_tokens_total() >= ntk and chapter_open(ck) and mode_open() and no_finale,
				"%s: %s at %d real tokens without a finale" % [tag, ck, real_tokens_total()])
	_from_dict({})
	_loaded = true

	# every match of every chapter: its own opponents, look, twist, music, label
	Stars.force_total = 72
	for ch in chs:
		var cid: String = str(ch)
		for id in LegendsData.legend_ids(cid):
			for lv in ["normal", "legend"]:
				var m: Dictionary = match_for_challenge(str(id), lv)
				_check_match(errs, m, str(id), lv)
				_check(errs, str(m.get("chapter", "")) == cid and str(m.get("label", "")) == CHALLENGE_LABEL
						% [str(LegendsData.chapter(cid).get("name", "")), str(LegendsData.legend(str(id)).get("name", ""))]
						and str(m.get("look", "")) == look_for(cid) and str(m.get("twist", "")) == twist_for(cid)
						and str(m.get("music", "")) == music_for(cid), "%s: %s %s match fields" % [tag, id, lv])
				# P11-18: the pause panel's QUIT (and every game's end) goes back to this chapter's view
				_check(errs, str(Flow.legends_args().get("chapter", "")) == cid and Flow.in_legends(),
						"%s: %s quits to %s" % [tag, id, str(Flow.legends_args())])
				for p in m["teams"][1]["players"]:
					_check(errs, LegendsData.chapter_of(str((p as Dictionary).get("id", ""))) == cid,
							"%s: %s has an opponent of another chapter" % [tag, id])
		var fm: Dictionary = match_for_finale(cid, "hard")
		var f: Dictionary = LegendsData.chapter(cid).get("finale", {})
		var fin_ok: bool = str(fm.get("key", "")) == finale_key(cid) and str(fm.get("chapter", "")) == cid \
				and int(fm.get("target", 0)) == int(f.get("target", -1)) and str(fm.get("label", "")) == str(f.get("label", "-")) \
				and (fm.get("challenge", {}) as Dictionary).is_empty() and str(fm.get("look", "")) == look_for(cid)
		var fps: Array = fm.get("teams", [{}, {}])[1].get("players", []) if fin_ok else []
		var fteam: Array = LegendsData.finale_team(cid)
		fin_ok = fin_ok and fps.size() == 3 and fteam.size() == 3
		for i in fps.size():
			if not fin_ok:
				break
			var want_r: Dictionary = LegendsData.finale_ratings(str(fteam[i]), Difficulty.rating_bonus("hard"))
			fin_ok = str((fps[i] as Dictionary).get("id", "")) == str(fteam[i]) and LegendsData.chapter_of(str(fteam[i])) == cid
			for s in Ratings.STATS:
				if fin_ok and int(fps[i]["ratings"][s]) != int(want_r[s]):
					fin_ok = false
		_check(errs, fin_ok, "%s: %s finale match %s" % [tag, cid, JSON.stringify(fm).left(200)])
		_check(errs, str(Flow.legends_args().get("chapter", "")) == cid, "%s: the %s finale quits to %s"
				% [tag, cid, str(Flow.legends_args())])
		# --challenge ids: the chapter id is its finale, every legend by id and by short name
		var parse_ok: bool = parse_challenge(cid) == finale_key(cid) and parse_challenge(finale_key(cid)) == finale_key(cid)
		for id in LegendsData.legend_ids(cid):
			parse_ok = parse_ok and parse_challenge(str(id)) == challenge_key(str(id)) \
					and parse_challenge(str(id).substr(LegendsData.ID_PREFIX.length())) == challenge_key(str(id))
		_check(errs, parse_ok, "%s: %s parse_challenge" % [tag, cid])
	Stars.force_total = 72

	# the intro scenes: in story_text.gd, unseen on a fresh file, marked once (the tour plays them on the first open)
	# P11-18: the tour's own picks (legends_tour.gd's static _intro_scene() / _finale_before(), loaded here): the intro
	# on the chapter's first open only, the finale's "before" scene on its first PLAY only
	var tour: GDScript = load(TOUR_PATH) as GDScript
	_check(errs, tour != null and tour.has_method("_intro_scene") and tour.has_method("_finale_before"),
			"%s: the tour's scene picks are missing" % tag)
	for ch in chs:
		var sc: String = str(LegendsData.chapter(str(ch)).get("intro_scene", ""))
		var on: bool = bool(strict_ch.get(str(ch), strict))
		if on or StoryText.has_scene(sc):
			var tour_first: String = str(tour.call("_intro_scene", str(ch))) if tour != null else "-"
			_check(errs, sc != "" and StoryText.has_scene(sc) and not has_seen(sc) and tour_first == sc and mark_seen(sc)
					and has_seen(sc) and not mark_seen(sc), "%s: %s intro scene '%s' (tour '%s')" % [tag, ch, sc, tour_first])
			_check(errs, tour == null or str(tour.call("_intro_scene", str(ch))) == "", "%s: %s intro twice" % [tag, ch])
		var fs: Dictionary = LegendsData.chapter(str(ch)).get("finale_scenes", {})
		var bf: String = str(fs.get("before", ""))
		if on or StoryText.has_scene(bf):
			var tour_bf: String = str(tour.call("_finale_before", str(ch))) if tour != null else "-"
			_check(errs, bf != "" and StoryText.has_scene(bf) and StoryText.has_scene(str(fs.get("after", "")))
					and tour_bf == bf and mark_seen(bf) and (tour == null or str(tour.call("_finale_before", str(ch))) == ""),
					"%s: %s finale scenes %s (tour '%s')" % [tag, ch, str(fs), tour_bf])

	# records, the last chapter first down to the second: a loss gives nothing; unlocks and their scenes go back to
	# their own chapter's view; its finale opens after its 6 and closes only it; the chapters before it untouched
	var o: Dictionary = {}
	var nx: Dictionary = {}
	var done: Array = []       # finales won, in order
	var unl: Array = []        # the legends unlocked so far, in data order
	for k in range(n - 1, 0, -1):
		var ck: String = str(chs[k])
		var idk: Array = by_ch[ck]
		var tokens_before: int = real_tokens_total()
		var a: String = str(idk[0])
		match_for_challenge(a, "normal")
		o = record_result({"won": false})
		nx = after_result()
		_check(errs, not bool(o["won"]) and str(o["chapter"]) == ck and nx["screen"] == SCREEN
				and nx["args"].get("chapter", "") == ck and not is_unlocked(a), "%s: %s loss %s / %s" % [tag, a, str(o), str(nx)])
		o = record_result({"won": true})
		nx = after_result()
		var us: String = str(LegendsData.legend(a).get("unlock_scene", ""))
		_check(errs, bool(o["won"]) and str(o["unlocked"]) == a and int(o["tokens_now"]) == 2
				and _after_ok(nx, us, ck, bool(strict_ch.get(ck, strict))), "%s: %s unlock %s" % [tag, a, str(nx)])
		nx = after_result()
		_check(errs, nx["screen"] == SCREEN and nx["args"].get("chapter", "") == ck, "%s: %s unlock scene twice" % [tag, a])
		for i in range(1, idk.size()):
			_check(errs, not finale_open(ck), "%s: %s finale open after %d" % [tag, ck, i])
			match_for_challenge(str(idk[i]), "easy")
			o = record_result({"won": true})
			var sc_i: String = str(LegendsData.legend(str(idk[i])).get("unlock_scene", ""))
			nx = after_result()
			_check(errs, str(o["unlocked"]) == str(idk[i]) and _after_ok(nx, sc_i, ck, bool(strict_ch.get(ck, strict))),
					"%s: %s unlock %s" % [tag, idk[i], str(nx)])
		unl = idk + unl
		var before_ok: bool = true
		for j in k:
			if chapter_tokens(str(chs[j])) != 0 or finale_open(str(chs[j])) or chapter_done(str(chs[j])):
				before_ok = false
		_check(errs, finale_open(ck) and before_ok and not chapter_done(ck) and unlocked_ids() == unl
				and chapter_tokens(ck) == 2 + 5 and real_tokens_total() == tokens_before + 7,
				"%s: %s after its 6 (tokens %d / %d, unlocked %s)" % [tag, ck, chapter_tokens(ck), real_tokens_total(),
				str(unlocked_ids())])
		match_for_finale(ck, "hard")
		o = record_result({"won": true})
		var after_sc: String = str((LegendsData.chapter(ck).get("finale_scenes", {}) as Dictionary).get("after", ""))
		nx = after_result()
		_check(errs, bool(o["chapter_done"]) and chapter_done(ck) and not chapter_done(c1) and finales == done + [ck]
				and int(o["tokens_now"]) == 3 and str(o["unlocked"]) == ""
				and _after_ok(nx, after_sc, ck, bool(strict_ch.get(ck, strict))),
				"%s: %s finale %s / %s" % [tag, ck, str(o), str(nx)])
		nx = after_result()
		_check(errs, nx["screen"] == SCREEN and nx["args"].get("chapter", "") == ck, "%s: %s after scene twice" % [tag, ck])
		done.append(ck)
	# Chapter 1 after them: its own unlocks, its own finale; the others stay done
	for i in ids1.size():
		match_for_challenge(str(ids1[i]), "hard")
		o = record_result({"won": true})
		nx = after_result()
		_check(errs, str(o["chapter"]) == c1 and str(o["unlocked"]) == str(ids1[i])
				and nx.get("args", {}).get("then_args", nx.get("args", {})).get("chapter", "") == c1,
				"%s: %s back to %s" % [tag, ids1[i], str(nx)])
	match_for_finale(c1, "normal")
	o = record_result({"won": true})
	nx = after_result()
	var others_ok: bool = true
	for k in range(1, n):
		if not chapter_done(str(chs[k])) or chapter_tokens(str(chs[k])) != 10:
			others_ok = false
	_check(errs, chapter_done(c1) and others_ok and finales == done + [c1]
			and nx.get("args", {}).get("then_args", nx.get("args", {})).get("chapter", "") == c1
			and chapter_tokens(c1) == 18 + 2 and real_tokens_total() == 20 + 10 * (n - 1)
			and unlocked_ids() == all_ids, "%s: every chapter done (tokens %d / %d, unlocked %s)"
			% [tag, chapter_tokens(c1), real_tokens_total(), str(unlocked_ids())])
	_from_dict({})
	_loaded = true

	# the swap, each era: a drafted legend starting for you sits against his own chapter's games he is in (as the
	# challenge legend, a mate or a finale legend) and plays against the other chapters'. P11-18: every legend of every
	# era, so each drafted Present legend sits in exactly his own games
	for lid_v in all_ids:
		var lid: String = str(lid_v)
		var mem: Dictionary = Trip.to_dict()
		Trip.roster_data.append({"id": lid, "ratings": LegendsData.draft_ratings(lid, 60), "pts": 0, "via": "draft"})
		var keep: Array = Trip.starters.duplicate()
		Trip.starters = [lid, str(keep[0]), str(keep[1])]
		Trip.human = lid
		for ch_b in chs:
			for id in LegendsData.legend_ids(str(ch_b)):
				var m: Dictionary = match_for_challenge(str(id), "normal")
				var sits: bool = LegendsData.challenge_team(str(id)).has(lid)
				var mine: Array = []
				for p in m["teams"][0]["players"]:
					mine.append(str((p as Dictionary).get("id", "")))
				_check(errs, mine.has(lid) != sits and (m["swaps"] as Array).size() == (1 if sits else 0)
						and (str(m["human"]) == lid) != sits and mine.size() == 3,
						"%s: %s against %s: %s, swaps %s" % [tag, lid, id, str(mine), str(m["swaps"])])
			var fm: Dictionary = match_for_finale(str(ch_b), "normal")
			var fsits: bool = LegendsData.finale_team(str(ch_b)).has(lid)
			var fmine: Array = []
			for p in fm["teams"][0]["players"]:
				fmine.append(str((p as Dictionary).get("id", "")))
			_check(errs, fmine.has(lid) != fsits and (fm["swaps"] as Array).size() == (1 if fsits else 0),
					"%s: %s in the %s finale: %s" % [tag, lid, ch_b, str(fmine)])
		_check(errs, Trip.starters[0] == lid and Trip.human == lid, "%s: the swap changed the trip's starters" % tag)
		mem["version"] = Save.VERSION
		Trip.from_dict(mem)

	# mentors from every era side by side: era k's first legend trains player k (the starters, then the bench; past
	# the roster a pupil off it, kept with no effect). One per player, one pupil per legend, each era's perk
	unlocked = all_ids.duplicate()
	mentors = {}
	var lgs: Array = []
	for ch in chs:
		lgs.append(str(by_ch[str(ch)][0]))
	var pool: Array = []
	for id in Trip.starters:
		pool.append(str(id))
	for id in Trip.roster_ids():
		if not pool.has(str(id)) and not _is_legend(str(id)):
			pool.append(str(id))
	var pupils: Array = []
	for i in n:
		pupils.append(str(pool[i]) if i < pool.size() else "zz_pupil_%d" % i)
	var keys_ok: bool = true
	var keys: Array = []
	for lid in lgs:
		var pk: Dictionary = LegendsData.perk_of(str(lid))
		if pk.is_empty() or (strict and keys.has(str(pk.get("key", "")))):
			keys_ok = false
		keys.append(str(pk.get("key", "")))
	_check(errs, keys_ok, "%s mentors: perks %s of %s" % [tag, str(keys), str(lgs)])
	var pairs_ok: bool = true
	for i in n:
		pairs_ok = pairs_ok and assign(str(lgs[i]), str(pupils[i]))
	pairs_ok = pairs_ok and mentors.size() == n
	for i in n:
		var want_key: String = str(LegendsData.perk_of(str(lgs[i])).get("key", "-"))
		var got: Dictionary = perks_for(str(pupils[i]))
		pairs_ok = pairs_ok and str(got.get("key", "")) == want_key and str(got.get("mentor", "")) == str(lgs[i])
		if Trip.roster_ids().has(str(pupils[i])):
			pairs_ok = pairs_ok and str((Trip.roster_player(str(pupils[i])).get(PERK_KEY, {}) as Dictionary)
					.get("mentor", "")) == str(lgs[i])
	_check(errs, pairs_ok, "%s mentors: one of each era %s" % [tag, str(mentors)])
	var g: String = str(lgs[0])
	var la: String = str(lgs[n - 1])
	var p0: String = str(pupils[0])
	var pl: String = str(pupils[n - 1])
	_check(errs, assign(la, p0) and mentor_of(p0) == la and pupil_of(g) == "" and mentor_of(pl) == ""
			and pupil_of(la) == p0 and mentors.size() == n - 1, "%s mentors: a %s legend takes a %s pupil %s"
			% [tag, chs[n - 1], c1, str(mentors)])
	_check(errs, assign(g, pl) and not assign(la, g) and not assign(g, la) and mentors.size() == n,
			"%s mentors: a legend trains a legend %s" % [tag, str(mentors)])
	for ch in chs:
		var ids_c: Array = by_ch[str(ch)]
		var cm: Dictionary = match_for_challenge(str(ids_c[ids_c.size() - 1]), "normal")
		for t in 2:
			for p in (cm["teams"][t] as Dictionary).get("players", []):
				_check(errs, not (p as Dictionary).has(PERK_KEY), "%s mentors: a perk in a %s challenge" % [tag, ch])
	unlocked.erase(la)
	_check(errs, not can_mentor(la) and perks_for(p0).is_empty() and pupil_of(la) == p0
			and str(perks_for(pl).get("mentor", "")) == g, "%s mentors: a locked %s mentor" % [tag, chs[n - 1]])
	unlocked.append(la)
	var pairs: String = JSON.stringify(mentors)
	_check(errs, save(), "%s mentors: save %s" % [tag, LegendsSave.last_error])
	mentors = {}
	load_state(true)
	_check(errs, JSON.stringify(mentors) == pairs, "%s mentors: round trip %s vs %s" % [tag, JSON.stringify(mentors), pairs])

	# put back: a fresh Legends state, the trip as it was in memory, the file never written
	trip_mem["version"] = Save.VERSION
	Trip.from_dict(trip_mem)
	_check(errs, _bytes(trip_path) == trip_disk, "%s: the trip file changed" % tag)
	_from_dict({})
	_loaded = true
	force_tokens = -1
	Stars.force_total = 24

# after_result() for a scene that plays once: the story, then this chapter's view; a scene story_text.gd doesn't have
# (a stand-in's; strict = the shipped rows, which must have it) goes straight to the view
static func _after_ok(nx: Dictionary, scene: String, ch: String, strict: bool) -> bool:
	var args: Dictionary = nx.get("args", {})
	if scene != "" and StoryText.has_scene(scene):
		return str(nx.get("screen", "")) == "story" and str(args.get("scene", "")) == scene \
				and str(args.get("then", "")) == SCREEN and str((args.get("then_args", {}) as Dictionary).get("chapter", "")) == ch
	return not strict and str(nx.get("screen", "")) == SCREEN and str(args.get("chapter", "")) == ch

# the first chapter row that isn't built in the rows in use ("nowhere" when every row is): a chapter with no finale
static func _unbuilt_chapter() -> String:
	for id in LegendsData.chapter_ids():
		if not LegendsData.is_built(str(id)):
			return str(id)
	return "nowhere"

# every challenge and finale match (JSON) of every built chapter but skip, on three levels: what another chapter's
# rows must never change
static func _all_matches(skip: String) -> Array:
	var out: Array = []
	for lv in ["easy", "hard", "legend"]:
		for ch in LegendsData.built_chapters():
			if str(ch) == skip:
				continue
			for id in LegendsData.legend_ids(str(ch)):
				out.append(JSON.stringify(match_for_challenge(str(id), lv)))
			out.append(JSON.stringify(match_for_finale(str(ch), lv)))
	return out

# P11-03: three built chapters on stand-in rows (LegendsData.stand_in_test_data() of the timeline's third row: today
# the Present, built as 6 copies of Chapter 1's legends, its own gate, the TEST_* rating keys, missing look / twist /
# music / scenes). The other chapters' matches byte for byte as without it, max_tokens() 63, the stand-in's fallbacks
# and ratings, then the whole chapter walk on three eras (gates by stars and tokens, tokens per chapter, finales,
# unlocks, the swap, mentors), a save round trip with every chapter's keys, parse_challenge(), and the shipped rows back
# (the stand-in's keys never count). The test trip file unchanged.
static func _check_three_chapters(errs: Array, trip_path: String) -> void:
	_check_stand_in_chapters(errs, trip_path, 2, "three chapters")

# P12-03: four built chapters: the timeline's fourth row (the New Generation, "next") as a stand-in (ids
# lg_zz_next_1..6) next to the shipped three. The same checks as _check_three_chapters() on four eras (max tokens 84),
# plus its gate: the owner's Q6 a, SHIPPED_GATES' last row (72 stars or 48 tokens), and no chapter after it.
static func _check_four_chapters(errs: Array, trip_path: String) -> void:
	_check_stand_in_chapters(errs, trip_path, 3, "four chapters")

# P11-03, P12-03: the rows with chapter_ids()[row_i] built as a stand-in: every built row of the data and the stand-in
# (row_i + 1 chapters or more, once later rows are built), checked as the comments above say. tag starts every error line.
static func _check_stand_in_chapters(errs: Array, trip_path: String, row_i: int, tag: String) -> void:
	var trip_disk: PackedByteArray = _bytes(trip_path)
	var row_ids: Array = LegendsData.chapter_ids()
	_check(errs, row_ids.size() > row_i, "%s: only %d chapter rows" % [tag, row_ids.size()])
	if row_ids.size() <= row_i:
		return
	var ch3: String = str(row_ids[row_i])
	var want_built: Array = []
	var shipped_built: int = 0
	for row in LegendsData.CHAPTERS:
		var rid: String = str(row.get("id", ""))
		if bool(row.get("built", false)) or rid == ch3:
			want_built.append(rid)
		if bool(row.get("built", false)) and rid != ch3:
			shipped_built += 1
	Stars.force_total = 72
	force_tokens = -1
	unlock_override = ""
	_from_dict({})
	_loaded = true
	var before: Array = _all_matches(ch3)
	LegendsData.set_test_data(LegendsData.stand_in_test_data(ch3))
	_from_dict({})
	_loaded = true
	var ids3: Array = LegendsData.legend_ids(ch3)
	var prefix_ok: bool = ids3.size() == 6
	for id in ids3:
		prefix_ok = prefix_ok and str(id).begins_with(LegendsData.stand_in_prefix(ch3)) and LegendsData.is_legend_id(str(id)) \
				and LegendsData.chapter_of(str(id)) == ch3 and not LegendsData.LEGENDS.has(str(id))
	var nb: int = want_built.size()
	_check(errs, LegendsData.test_data_on() and LegendsData.built_chapters() == want_built and nb >= row_i + 1
			and prefix_ok, "%s: built %s, legends %s" % [tag, str(LegendsData.built_chapters()), str(ids3)])
	if not prefix_ok or LegendsData.built_chapters().size() != nb or nb < row_i + 1:
		LegendsData.clear_test_data()
		_from_dict({})
		_loaded = true
		return
	_check(errs, LegendsData.max_tokens() == 21 * nb and chapter_max_tokens(ch3) == 21 and LegendsData.legend_ids().size() == 6 * nb,
			"%s: max tokens %d" % [tag, LegendsData.max_tokens()])
	# the stand-in keeps its row's own gate (the owner's, SHIPPED_GATES, when it has a row there)
	if SHIPPED_GATES.has(ch3):
		var sg: Dictionary = SHIPPED_GATES[ch3]
		var g3: Dictionary = LegendsData.chapter(ch3).get("gate", {})
		_check(errs, int(g3.get("stars", -1)) == int(sg.get("stars", 0)) and int(g3.get("tokens", -1)) == int(sg.get("tokens", 0)),
				"%s: %s gate %s, want %s" % [tag, ch3, str(g3), str(sg)])
	# the last row built: no chapter after it, nothing left unbuilt
	if nb == row_ids.size():
		_check(errs, _unbuilt_chapter() == "nowhere" and parse_challenge("nowhere") == "",
				"%s: a chapter after %s" % [tag, ch3])
	_check(errs, _all_matches(ch3) == before, "%s: a match of another chapter changed" % tag)
	_check(errs, LegendsData.challenge_avg(ch3) == LegendsData.TEST_CHALLENGE_AVG
			and LegendsData.mate_drop(ch3) == LegendsData.TEST_MATE_DROP
			and LegendsData.finale_stage_avg(ch3) == LegendsData.TEST_FINALE_STAGE_AVG, "%s: rating keys" % tag)
	# the stand-in's challenge: its chapter's fallbacks and ratings
	var a3: String = str(ids3[0])
	var m: Dictionary = match_for_challenge(a3, "normal")
	var crew3: Dictionary = LegendsData.chapter(ch3).get("crew", {})
	_check(errs, str(m.get("chapter", "")) == ch3 and str(m.get("key", "")) == challenge_key(a3)
			and str(m.get("look", "")) == FALLBACK_LOOK and str(m.get("twist", "")) == NO_TWIST
			and str(m.get("music", "")) == str(LegendsData.chapter(ch3).get("fallback_music", "-"))
			and str((m["teams"][1] as Dictionary).get("name", "")) == str(crew3.get("name", "-")),
			"%s: match fields %s" % [tag, JSON.stringify(m).left(300)])
	_check_match(errs, m, a3, "normal")
	var shape0: Dictionary = LegendsData.legend(a3).get("shape", {})
	var theirs: Array = m["teams"][1]["players"]
	var rat_ok: bool = theirs.size() == 3
	for s in Ratings.STATS:
		if rat_ok and int(theirs[0]["ratings"][s]) != clampi(LegendsData.TEST_CHALLENGE_AVG + int(shape0[s]),
				LegendsData.RATING_MIN, LegendsData.RATING_CAP):
			rat_ok = false
	_check(errs, rat_ok, "%s: %s ratings are not its chapter's keys" % [tag, a3])
	# the chapter before it opens at its own gate first (the gates rise along the timeline)
	var prev: String = str(want_built[want_built.find(ch3) - 1])
	var gate2: int = int((LegendsData.chapter(prev).get("gate", {}) as Dictionary).get("stars", 0))
	var gate3: int = int((LegendsData.chapter(ch3).get("gate", {}) as Dictionary).get("stars", 0))
	Stars.force_total = gate2
	_check(errs, gate2 < gate3 and chapter_open(prev) and not chapter_open(ch3),
			"%s: %s open at %d stars" % [tag, ch3, gate2])
	# the whole walk on every era
	_check_chapter_walk(errs, trip_path, tag, row_i + 1)
	# a save keeps every chapter's keys: a Hard challenge win and an Easy finale win in each
	Stars.force_total = 72
	_from_dict({})
	_loaded = true
	for ch in want_built:
		match_for_challenge(str(LegendsData.legend_ids(str(ch))[0]), "hard")
		record_result({"won": true})
		match_for_finale(str(ch), "easy")
		record_result({"won": true})
	var per_ok: bool = true
	for ch in want_built:
		per_ok = per_ok and chapter_tokens(str(ch)) == 4 and chapter_done(str(ch))
	_check(errs, per_ok and real_tokens_total() == 4 * nb and finales == want_built, "%s: one win each (%d)"
			% [tag, real_tokens_total()])
	_check(errs, save(), "%s: save %s" % [tag, LegendsSave.last_error])
	var saved: String = JSON.stringify(to_dict())
	load_state(true)
	_check(errs, JSON.stringify(to_dict()) == saved, "%s: round trip" % tag)
	# --challenge ids
	_check(errs, parse_challenge(ch3) == finale_key(ch3) and parse_challenge(finale_key(ch3)) == finale_key(ch3)
			and parse_challenge("finale") == finale_key(str(want_built[0])) and parse_challenge(a3) == challenge_key(a3)
			and parse_challenge(a3.substr(LegendsData.ID_PREFIX.length())) == challenge_key(a3)
			and parse_challenge(_unbuilt_chapter()) == "", "%s: parse_challenge" % tag)
	LegendsData.clear_test_data()
	# the shipped rows back: the stand-in's challenge keys never count; its finale key only once that chapter is
	# really built
	var shipped_fin: int = token_best(finale_key(ch3)) if LegendsData.is_built(ch3) else 0
	_check(errs, not LegendsData.test_data_on() and real_tokens_total() == 4 * shipped_built + shipped_fin
			and LegendsData.max_tokens() == 21 * LegendsData.built_chapters().size()
			and not LegendsData.is_legend_id(a3) and not is_unlocked(a3),
			"%s: the shipped rows back (tokens %d)" % [tag, real_tokens_total()])
	_from_dict({})
	_loaded = true
	_check(errs, _all_matches(ch3) == before, "%s: the shipped matches changed after" % tag)
	_check(errs, _bytes(trip_path) == trip_disk, "%s: the trip file changed" % tag)
	_from_dict({})
	_loaded = true
	Stars.force_total = 24

# P10-02: the multi-chapter paths on a stand-in second built chapter (LegendsData.two_chapter_test_data(): "fathers"
# built with 6 copies of Chapter 1's legends, its own rating keys, missing look / twist / music / scenes). Gates (stars,
# real and --tokens tokens, no finale needed: F7 a), Chapter 1's matches byte for byte as without it, the stand-in's
# ratings from its row's keys, the fallbacks, records, unlocks, after_result(), tokens per chapter and in total, its
# finale closing only its chapter, parse_challenge(), the Kings side; the test trip file unchanged. Starts and ends on
# a fresh Legends state (in SELFTEST_PATH) and the shipped rows.
static func _check_two_chapters(errs: Array, trip_path: String) -> void:
	var trip_disk: PackedByteArray = _bytes(trip_path)
	var kept_skip: bool = _skip_trip_load
	var kept_trip_active: bool = Trip.active
	_skip_trip_load = true
	Trip.active = false
	Stars.force_total = 72
	force_tokens = -1
	unlock_override = ""
	var grand_ids: Array = LegendsData.legend_ids("grand")
	var before: Array = []
	for lv in ["easy", "hard", "legend"]:
		for id in grand_ids:
			before.append(JSON.stringify(match_for_challenge(str(id), lv)))
		before.append(JSON.stringify(match_for_finale("grand", lv)))
	LegendsData.set_test_data(LegendsData.two_chapter_test_data())
	_from_dict({})
	_loaded = true
	var ch2: String = LegendsData.TEST_CHAPTER
	var ids2: Array = LegendsData.legend_ids(ch2)
	var want_built: Array = []   # the shipped built rows and the stand-in, in timeline order (P11-03: any number)
	for row in LegendsData.CHAPTERS:
		if bool(row.get("built", false)) or str(row.get("id", "")) == ch2:
			want_built.append(str(row.get("id", "")))
	var unbuilt: String = _unbuilt_chapter()
	_check(errs, LegendsData.test_data_on() and LegendsData.built_chapters() == want_built and want_built[0] == "grand"
			and want_built[1] == ch2 and ids2.size() == 6,
			"two chapters: built %s, %d legends" % [str(LegendsData.built_chapters()), ids2.size()])
	if ids2.size() != 6 or grand_ids.size() != 6:
		LegendsData.clear_test_data()
		_skip_trip_load = kept_skip
		Trip.active = kept_trip_active
		return
	var a2: String = str(ids2[0])
	_check(errs, LegendsData.max_tokens() == 21 * want_built.size() and chapter_max_tokens(ch2) == 21
			and chapter_max_tokens("grand") == 21 and LegendsData.legend_ids().size() == 6 * want_built.size(),
			"two chapters: max tokens %d" % LegendsData.max_tokens())
	_check(errs, LegendsData.chapter_of(a2) == ch2 and LegendsData.is_legend_id(a2) and challenge_open(a2),
			"two chapters: %s is not a playable legend of %s" % [a2, ch2])
	# Chapter 1 plays exactly as before with a second chapter built
	var after: Array = []
	for lv in ["easy", "hard", "legend"]:
		for id in grand_ids:
			after.append(JSON.stringify(match_for_challenge(str(id), lv)))
		after.append(JSON.stringify(match_for_finale("grand", lv)))
	_check(errs, after == before, "two chapters: a Chapter 1 match changed")
	# the per-chapter rating keys (Chapter 1 and an unknown chapter: the constants)
	_check(errs, LegendsData.challenge_avg("grand") == LegendsData.CHALLENGE_AVG
			and LegendsData.mate_drop("grand") == LegendsData.MATE_DROP
			and LegendsData.finale_stage_avg("grand") == LegendsData.FINALE_STAGE_AVG
			and LegendsData.challenge_avg("nowhere") == LegendsData.CHALLENGE_AVG
			and LegendsData.challenge_avg(ch2) == LegendsData.TEST_CHALLENGE_AVG
			and LegendsData.mate_drop(ch2) == LegendsData.TEST_MATE_DROP
			and LegendsData.finale_stage_avg(ch2) == LegendsData.TEST_FINALE_STAGE_AVG, "two chapters: rating keys")
	# gates: 36 stars, or 12 tokens (real ones from Chapter 1 or --tokens), no Chapter 1 finale needed (F7 a)
	Stars.force_total = 24
	_check(errs, mode_open() and chapter_open("grand") and not chapter_open(ch2), "two chapters: %s open at 24 stars" % ch2)
	Stars.force_total = 36
	_check(errs, chapter_open(ch2), "two chapters: %s closed at 36 stars" % ch2)
	Stars.force_total = 0
	force_tokens = 12
	_check(errs, chapter_open(ch2) and not chapter_open("grand") and mode_open(), "two chapters: --tokens 12 gate")
	force_tokens = -1
	_check(errs, not mode_open(), "two chapters: mode open at 0 stars, 0 tokens")
	Stars.force_total = 24
	for i in 4:
		match_for_challenge(str(grand_ids[i]), "hard")
		record_result({"won": true})
	_check(errs, real_tokens_total() == 12 and chapter_tokens("grand") == 12 and not chapter_done("grand")
			and chapter_open(ch2), "two chapters: 12 real tokens without the finale (%d)" % real_tokens_total())
	# a stand-in challenge: its chapter's look / twist / music fallbacks and ratings
	var m: Dictionary = match_for_challenge(a2, "normal")
	var crew2: Dictionary = LegendsData.chapter(ch2).get("crew", {})
	var label2: String = CHALLENGE_LABEL % [str(LegendsData.chapter(ch2).get("name", "")),
			str(LegendsData.legend(a2).get("name", ""))]
	_check(errs, str(m.get("chapter", "")) == ch2 and str(m.get("key", "")) == challenge_key(a2)
			and str(m.get("look", "")) == FALLBACK_LOOK and str(m.get("twist", "")) == NO_TWIST
			and str(m.get("music", "")) == str(LegendsData.chapter(ch2).get("fallback_music", "-"))
			and str(m.get("label", "")) == label2
			and str((m["teams"][1] as Dictionary).get("name", "")) == str(crew2.get("name", "-")),
			"two chapters: match fields %s" % JSON.stringify(m).left(300))
	_check_match(errs, m, a2, "normal")
	var team2: Array = LegendsData.challenge_team(a2)
	var shape0: Dictionary = LegendsData.legend(a2).get("shape", {})
	var theirs: Array = m["teams"][1]["players"]
	var rat_ok: bool = theirs.size() == 3 and team2.size() == 3
	if rat_ok:
		var mate_shape: Dictionary = LegendsData.legend(str(team2[1])).get("shape", {})
		for s in Ratings.STATS:
			if int(theirs[0]["ratings"][s]) != clampi(LegendsData.TEST_CHALLENGE_AVG + int(shape0[s]),
					LegendsData.RATING_MIN, LegendsData.RATING_CAP):
				rat_ok = false
			if int(theirs[1]["ratings"][s]) != clampi(LegendsData.TEST_CHALLENGE_AVG - LegendsData.TEST_MATE_DROP
					+ int(mate_shape[s]), LegendsData.RATING_MIN, LegendsData.RATING_CAP):
				rat_ok = false
	_check(errs, rat_ok, "two chapters: %s ratings are not its chapter's keys" % a2)
	for p in theirs:
		_check(errs, LegendsData.chapter_of(str((p as Dictionary).get("id", ""))) == ch2,
				"two chapters: an opponent of another chapter")
	# records: an unlock goes back to its own chapter (its scene doesn't exist: skipped); tokens per chapter
	var o: Dictionary = record_result({"won": true})
	_check(errs, bool(o["won"]) and str(o["chapter"]) == ch2 and str(o["unlocked"]) == a2 and int(o["tokens_now"]) == 2,
			"two chapters: record %s" % str(o))
	var nx: Dictionary = after_result()
	_check(errs, nx["screen"] == SCREEN and nx["args"].get("chapter", "") == ch2, "two chapters: after_result %s" % str(nx))
	_check(errs, chapter_tokens(ch2) == 2 and chapter_tokens("grand") == 12 and real_tokens_total() == 14
			and unlocked_ids().size() == 5 and unlocked_ids()[4] == a2, "two chapters: tokens %d / %d, unlocked %s"
			% [chapter_tokens(ch2), real_tokens_total(), str(unlocked_ids())])
	# a match whose Flow.match.chapter is wrong still records on the key's chapter
	match_for_challenge(str(ids2[1]), "easy")
	Flow.match["chapter"] = "grand"
	o = record_result({"won": true})
	_check(errs, str(o["chapter"]) == ch2 and after_result()["args"].get("chapter", "") == ch2,
			"two chapters: chapter from the key %s" % str(o))
	# the stand-in's finale opens after its 6 (Chapter 1's stays shut: 4 of 6 there) and closes only its chapter
	for i in range(2, ids2.size()):
		_check(errs, not finale_open(ch2), "two chapters: finale open after %d" % i)
		match_for_challenge(str(ids2[i]), "easy")
		record_result({"won": true})
	_check(errs, finale_open(ch2) and not finale_open("grand") and not chapter_done(ch2), "two chapters: finale gate")
	var fm: Dictionary = match_for_finale(ch2, "hard")
	var fin_ok: bool = str(fm.get("key", "")) == finale_key(ch2) and str(fm.get("chapter", "")) == ch2 \
			and int(fm.get("target", 0)) == 21 and (fm["teams"][1]["players"] as Array).size() == 3
	if fin_ok:
		for p in fm["teams"][1]["players"]:
			var pid: String = str((p as Dictionary).get("id", ""))
			var sh: Dictionary = LegendsData.legend(pid).get("shape", {})
			for s in Ratings.STATS:
				if int(p["ratings"][s]) != clampi(LegendsData.TEST_FINALE_STAGE_AVG + LegendsData.DRAFT_TIER + int(sh[s]),
						LegendsData.RATING_MIN, LegendsData.RATING_CAP):
					fin_ok = false
	_check(errs, fin_ok, "two chapters: finale match %s" % JSON.stringify(fm).left(300))
	o = record_result({"won": true})
	_check(errs, bool(o["chapter_done"]) and chapter_done(ch2) and not chapter_done("grand") and finales == [ch2]
			and int(o["tokens_now"]) == 3 and str(o["unlocked"]) == "", "two chapters: finale win %s" % str(o))
	nx = after_result()
	_check(errs, nx["screen"] == SCREEN and nx["args"].get("chapter", "") == ch2, "two chapters: finale after %s" % str(nx))
	_check(errs, chapter_tokens(ch2) == 2 + 5 + 3 and real_tokens_total() == 12 + 10, "two chapters: totals %d / %d"
			% [chapter_tokens(ch2), real_tokens_total()])
	# a finale key of a chapter that isn't built records nothing
	Flow.match = {"mode": MODE, "key": finale_key(unbuilt), "chapter": unbuilt, "level": "hard"}
	o = record_result({"won": true})
	_check(errs, not bool(o["won"]) and str(o["failed"]) == "not a legends game" and not finales.has(unbuilt),
			"two chapters: an unbuilt finale recorded")
	# --challenge ids
	_check(errs, parse_challenge(ch2) == finale_key(ch2) and parse_challenge(finale_key(ch2)) == finale_key(ch2)
			and parse_challenge("finale") == "fin:grand" and parse_challenge(a2) == challenge_key(a2)
			and parse_challenge(a2.substr(LegendsData.ID_PREFIX.length())) == challenge_key(a2)
			and parse_challenge(unbuilt) == "", "two chapters: parse_challenge")
	# the save keeps both chapters' keys; with the shipped rows back the stand-in's never count
	_check(errs, save(), "two chapters: save %s" % LegendsSave.last_error)
	var saved: String = JSON.stringify(to_dict())
	load_state(true)
	_check(errs, JSON.stringify(to_dict()) == saved, "two chapters: round trip")
	LegendsData.clear_test_data()
	# the stand-in's challenge keys never count with the shipped rows; its finale key "fin:<TEST_CHAPTER>" only once
	# that chapter is really built (P10-11)
	var shipped_fin: int = token_best(finale_key(ch2)) if LegendsData.is_built(ch2) else 0
	_check(errs, not LegendsData.test_data_on() and real_tokens_total() == 12 + shipped_fin
			and LegendsData.max_tokens() == 21 * LegendsData.built_chapters().size()
			and not LegendsData.is_legend_id(a2) and not is_unlocked(a2) and unlocked_ids().size() == 4,
			"two chapters: the shipped rows back (tokens %d)" % real_tokens_total())
	_check(errs, _bytes(trip_path) == trip_disk, "two chapters: the trip file changed")
	_from_dict({})
	_loaded = true
	Stars.force_total = 24
	_skip_trip_load = kept_skip
	Trip.active = kept_trip_active

# P9-23: the mentor rules on the loaded (test) trip, in SELFTEST_PATH; the trip and this file's unlocks and mentors
# are put back (the trip is never saved here: Trip.saving is off)
static func _check_mentors(errs: Array, ids: Array) -> void:
	var kept_unlocked: Array = unlocked.duplicate()
	var kept_mentors: Dictionary = mentors.duplicate()
	var kept_override: String = unlock_override
	var trip_mem: Dictionary = Trip.to_dict()
	unlock_override = ""
	unlocked = ids.duplicate()
	mentors = {}
	if ids.size() < 3 or Trip.starters.size() != Trip.STARTERS:
		_check(errs, false, "mentors: need 3 legends and a trip (%d, %s)" % [ids.size(), str(Trip.starters)])
		unlocked = kept_unlocked
		mentors = kept_mentors
		unlock_override = kept_override
		return
	var a: String = str(ids[0])
	var b: String = str(ids[1])
	var c: String = str(ids[2])
	var you: String = str(Trip.starters[0])
	var mate: String = str(Trip.starters[1])
	var pa: Dictionary = LegendsData.perk_of(a)
	# assign
	_check(errs, assign(a, you) and mentor_of(you) == a and pupil_of(a) == you and mentors.size() == 1,
			"mentors: assign %s -> %s (%s)" % [a, you, str(mentors)])
	var pk: Dictionary = perks_for(you)
	_check(errs, str(pk.get("key", "")) == str(pa.get("key", "-")) and is_equal_approx(float(pk.get("value", 0.0)),
			float(pa.get("value", -1.0))) and str(pk.get("mentor", "")) == a
			and str(pk.get("id", "")) == str(LegendsData.legend(a).get("perk", "")) and str(pk.get("text", "")) != "",
			"mentors: perks_for %s" % str(pk))
	_check(errs, assign(a, you) and mentors.size() == 1, "mentors: the same pair again")
	_check(errs, perks_for(mate).is_empty() and mentor_of(mate) == "" and pupil_of(b) == "", "mentors: untrained")
	# one perk per player: a second legend on the same player frees the first
	_check(errs, assign(b, you) and mentor_of(you) == b and pupil_of(a) == "" and mentors.size() == 1
			and str(perks_for(you).get("mentor", "")) == b, "mentors: switch the player's mentor %s" % str(mentors))
	# one pupil per legend: the legend moves to another player, the old one is freed
	_check(errs, assign(b, mate) and pupil_of(b) == mate and mentor_of(you) == "" and perks_for(you).is_empty()
			and mentors.size() == 1, "mentors: switch the legend's pupil %s" % str(mentors))
	_check(errs, assign(a, you) and assign(c, mate) and mentor_of(mate) == c and pupil_of(b) == "" and pupil_of(a) == you
			and mentors.size() == 2, "mentors: two pairs %s" % str(mentors))
	# refusals change nothing
	var before: String = JSON.stringify(mentors)
	unlocked.erase(b)
	_check(errs, not can_mentor(b) and not assign(b, you), "mentors: a locked legend trains")
	_check(errs, not assign("lg_nobody", you) and not assign("ud_jojo", you) and not assign(a, "") and not assign(a, a)
			and not assign(a, "x".repeat(LegendsSave.MAX_ID_LEN + 1)), "mentors: a bad pair accepted")
	_check(errs, JSON.stringify(mentors) == before, "mentors: a refusal changed %s" % JSON.stringify(mentors))
	# a locked mentor's pair stays in the file but gives nothing
	mentors[b] = "zz_keep"
	_check(errs, mentor_of("zz_keep") == b and perks_for("zz_keep").is_empty(), "mentors: a locked mentor's perk")
	unlock_override = "none"
	_check(errs, perks_for(you).is_empty() and Trip.roster_player(you).get(PERK_KEY, {}).is_empty(),
			"mentors: --legends-unlock-none still gives a perk")
	unlock_override = ""
	_check(errs, release(b) and not release(b) and mentor_of("zz_keep") == "", "mentors: release")
	unlocked.append(b)
	# a pupil not on the roster: kept, no effect
	_check(errs, assign(b, "zz_nobody") and pupil_of(b) == "zz_nobody" and Trip.roster_player("zz_nobody").is_empty()
			and Trip.perk_for("zz_nobody").is_empty(), "mentors: a pupil not on the roster")
	# the perk reaches the trip's player dicts and its match, never a challenge's side
	var rp: Dictionary = Trip.roster_player(you)
	_check(errs, str((rp.get(PERK_KEY, {}) as Dictionary).get("mentor", "")) == a
			and str((Trip.roster_player(mate).get(PERK_KEY, {}) as Dictionary).get("mentor", "")) == c
			and not Trip.roster_player(str(Trip.starters[2])).has(PERK_KEY), "mentors: Trip.roster_player %s" % str(rp))
	var trip_m: Dictionary = Trip.match_for()
	var with_perk: int = 0
	for p in (trip_m.get("teams", [{}])[0] as Dictionary).get("players", []):
		if (p as Dictionary).has(PERK_KEY):
			with_perk += 1
	for p in (trip_m.get("teams", [{}, {}])[1] as Dictionary).get("players", []):
		_check(errs, not (p as Dictionary).has(PERK_KEY), "mentors: an opponent has a perk")
	_check(errs, with_perk == 2, "mentors: %d trip players with a perk, want 2" % with_perk)
	var cm: Dictionary = match_for_challenge(str(ids[ids.size() - 1]), "normal")
	for t in 2:
		for p in (cm["teams"][t] as Dictionary).get("players", []):
			_check(errs, not (p as Dictionary).has(PERK_KEY), "mentors: a perk in a challenge (%s)" % str(p.get("id", "")))
	# the ramp sims field no perk (ud_jojo is in every sim crew)
	assign(a, "ud_jojo")
	for p in Trip.end_of_trip_crew(true):
		_check(errs, not (p as Dictionary).has(PERK_KEY), "mentors: a perk in the --best-roster sim")
	_check(errs, pupil_of(a) == "ud_jojo", "mentors: the sim dropped a pair")
	# the trip never holds mentors; a NEW TRIP keeps them (they are in the Legends file)
	_check(errs, not JSON.stringify(Trip.to_dict()).contains(PERK_KEY) and not JSON.stringify(Trip.to_dict()).contains("mentor"),
			"mentors: in the trip save")
	var pairs: String = JSON.stringify(mentors)
	var was_saving: bool = Trip.saving
	Trip.saving = false
	Trip.new_trip("normal")
	Trip.saving = was_saving
	_check(errs, JSON.stringify(mentors) == pairs and str((Trip.roster_player("ud_jojo").get(PERK_KEY, {}) as Dictionary)
			.get("mentor", "")) == a, "mentors: a NEW TRIP dropped them")
	# saved and loaded back; the load repair (two legends on one player: the first in file order stays)
	_check(errs, save(), "mentors: save %s" % LegendsSave.last_error)
	mentors = {}
	load_state(true)
	unlocked = ids.duplicate()
	_check(errs, JSON.stringify(mentors) == pairs, "mentors: round trip %s vs %s" % [JSON.stringify(mentors), pairs])
	_from_dict({"unlocked": ids, "mentors": {a: "p_one", b: "p_one", c: "p_two"}})
	_check(errs, mentors.size() == 2 and pupil_of(a) == "p_one" and pupil_of(b) == "" and pupil_of(c) == "p_two",
			"mentors: load repair %s" % str(mentors))
	# put back
	trip_mem["version"] = Save.VERSION
	Trip.from_dict(trip_mem)
	unlocked = kept_unlocked
	mentors = kept_mentors
	unlock_override = kept_override
	save()

# the challenge match's fields, opponents and level
static func _check_match(errs: Array, m: Dictionary, id: String, lv: String) -> void:
	var ch: String = LegendsData.chapter_of(id)
	_check(errs, str(m.get("level", "")) == lv and str(m.get("key", "")) == challenge_key(id)
			and str(m.get("chapter", "")) == ch and int(m.get("target", 0)) == int(LegendsData.challenge(id).get("target", -1)),
			"%s %s: level / key / chapter / target" % [id, lv])
	var c: Dictionary = m.get("challenge", {})
	_check(errs, str(c.get("legend", "")) == id and str(c.get("type", "")) == str(LegendsData.challenge(id).get("type", "")),
			"%s: challenge %s" % [id, str(c)])
	_check(errs, str(m.get("look", "")) == look_for(ch) and Looks.LOOKS.has(str(m.get("look", ""))), "%s: look" % id)
	_check(errs, str(m.get("twist", "")) == twist_for(ch) and Twists.TWISTS.has(str(m.get("twist", ""))), "%s: twist" % id)
	_check(errs, ResourceLoader.exists(MUSIC_DIR + str(m.get("music", "")) + ".ogg"), "%s: music %s" % [id, str(m.get("music", ""))])
	var theirs: Array = m["teams"][1]["players"]
	var team: Array = LegendsData.challenge_team(id)
	_check(errs, theirs.size() == 3, "%s: %d opponents" % [id, theirs.size()])
	var bonus: int = Difficulty.rating_bonus(lv)
	for i in mini(theirs.size(), team.size()):
		var p: Dictionary = theirs[i]
		var want: Dictionary = LegendsData.challenge_ratings(str(team[i]), bonus) if i == 0 \
				else LegendsData.mate_ratings(str(team[i]), bonus)
		_check(errs, str(p.get("id", "")) == str(team[i]) and str(p.get("tier", "")) == "legend", "%s: opponent %d" % [id, i])
		for s in Ratings.STATS:
			_check(errs, int(p["ratings"][s]) == int(want[s]) and int(p["ratings"][s]) <= LegendsData.RATING_CAP,
					"%s: %s %s %d (want %d)" % [id, str(team[i]), s, int(p["ratings"][s]), int(want[s])])
		_check(errs, p["ratings"].has("steal") and p["ratings"].has("block"), "%s: steal / block" % id)

static func _check(errs: Array, ok: bool, why: String) -> void:
	if not ok:
		errs.append(why)

static func _bytes(p: String) -> PackedByteArray:
	if not FileAccess.file_exists(p):
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(p)

# P9-28: the self test's trip file and its temp file, removed
static func _remove_trip_files(trip_path: String) -> void:
	for f in [trip_path, trip_path + Save.TMP_SUFFIX]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)

static func _put_bytes(p: String, data: PackedByteArray) -> void:
	var f: FileAccess = FileAccess.open(p, FileAccess.WRITE)
	if f == null:
		return
	f.store_buffer(data)
	f.close()

static func _wipe() -> void:
	for f in [SELFTEST_PATH, SELFTEST_PATH + LegendsSave.TMP_SUFFIX]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
