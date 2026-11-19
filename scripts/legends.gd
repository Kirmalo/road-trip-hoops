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
#     chapters open; mode_open() = the first built chapter is open
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
const SELFTEST_PATH := "user://legends_progress_selftest.json"   # self_test()'s own Legends file, deleted after

# ---------------------------------------------------------------------------------------------------- state
static var tokens := {}               # {"lg:<id>" | "fin:<ch>": 1..3}, best kept
static var unlocked: Array = []       # legend ids, in the order they were won
static var seen: Array = []           # story scene ids already shown (intro, unlock, finale scenes)
static var finales: Array = []        # chapter ids whose finale was won
static var mentors := {}              # {"<legend id>": "<roster player id>"} (P9-23 owns the meaning)
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
	mentors = c["mentors"]

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
	load_state()
	var t: int = 0
	for k in tokens:
		t += int(tokens[k])
	return t

# the stored total (never --tokens)
static func real_tokens_total() -> int:
	load_state()
	var t: int = 0
	for k in tokens:
		t += int(tokens[k])
	return t

# a chapter's tokens and its most (6 challenges + the finale, x3)
static func chapter_tokens(ch: String) -> int:
	var t: int = token_best(finale_key(ch))
	for id in LegendsData.legend_ids(ch):
		t += token_best(challenge_key(str(id)))
	return t

static func chapter_max_tokens(ch: String) -> int:
	if not LegendsData.is_built(ch):
		return 0
	var n: int = LegendsData.legend_ids(ch).size()
	if not (LegendsData.chapter(ch).get("finale", {}) as Dictionary).is_empty():
		n += 1
	return n * LegendsData.TOKEN_MAX

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

# the Legends mode is open: the first built chapter (Chapter 1) is
static func mode_open() -> bool:
	var built: Array = LegendsData.built_chapters()
	return not built.is_empty() and chapter_open(str(built[0]))

# the gate of the mode ("24 STARS"): the title's locked LEGENDS button
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
	if ids.is_empty() or (LegendsData.chapter(ch).get("finale", {}) as Dictionary).is_empty():
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
		var pd: Dictionary = Trip.roster_player(sid)
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
		var pd: Dictionary = Trip.roster_player(id)
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
	var ch: String = str(m.get("chapter", ""))
	var lv: String = level_ok(str(m.get("level", "")))
	var is_finale: bool = key.begins_with(KEY_FINALE)
	var lid: String = key.substr(KEY_CHALLENGE.length()) if key.begins_with(KEY_CHALLENGE) else ""
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
	if key == "" or (lid == "" and not is_finale) or (lid != "" and not LegendsData.is_legend_id(lid)):
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
# "fin:<chapter>" or a chapter id -> "lg:<id>" / "fin:<ch>", or "" for anything else
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
	if not (LegendsData.chapter(ch).get("finale", {}) as Dictionary).is_empty():
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
				var ps: Array = (got as Array).duplicate(true)
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
	var all: Array = []
	for w in [why, why_save, why_prog]:
		if str(w) != "":
			all.append(str(w))
	if not all.is_empty():
		print("LEGENDTEST FAILED: ", "; ".join(PackedStringArray(all)))
		return false
	print("LEGENDTEST OK")
	return true

# ---------------------------------------------------------------------------------------------------- self test

# Records, gates, unlocks, both crew sources, the swap, the match fields, the trip file unchanged byte for byte after
# a challenge, a save round trip. Its own Legends file (SELFTEST_PATH); the test trip save is only read (made and
# removed again when there is none); every static of this file, Trip's and Stars' --stars is put back. "" = OK.
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
	_check(errs, gate_met("fathers") and not chapter_open("fathers"), "fathers: 12 tokens gate / not built")
	_check(errs, tokens_total() == 12 and real_tokens_total() == 0, "--tokens override")
	force_tokens = -1
	Stars.force_total = 72
	_check(errs, not chapter_open("next") and gate_met("next"), "next at 72 stars")
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
	_check(errs, is_unlocked(first) and unlocked_ids().size() == 6 and finale_open("grand") and not chapter_done("grand"),
			"--legends-unlock-all")
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

	# your trip: the test trip save if there is one (read only), else a scripted trip written there and removed after
	Trip.saving = false
	var made_trip: bool = false
	if not trip_had or Save.read().is_empty():
		Trip.new_trip("hard")
		Trip.saving = true
		Trip.save()
		Trip.saving = false
		made_trip = true
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
			and parse_challenge("fin:grand") == "fin:grand" and parse_challenge("fathers") == ""
			and parse_challenge("nobody") == "", "parse_challenge")

	# put everything back
	if made_trip:
		for f in [trip_path, trip_path + Save.TMP_SUFFIX]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(f)
	_check(errs, FileAccess.file_exists(trip_path) == trip_had and _bytes(trip_path) == trip_bytes
			and FileAccess.file_exists(trip_path + Save.TMP_SUFFIX) == trip_tmp_had, "the test trip file was not put back")
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

static func _wipe() -> void:
	for f in [SELFTEST_PATH, SELFTEST_PATH + LegendsSave.TMP_SUFFIX]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
