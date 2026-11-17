extends Node
# Sound effects manager. Safe to call any time, even when no sound files exist.
#
# Usage from any script:  game.audio.play("swish")   or   game.audio.play("rim", -6.0, 0.1)
#
# Files: put sounds in res://assets/sfx/ named <name>.ogg (preferred) or <name>.wav.
# Fixed names:  swish, rim, bounce, crowd, whistle
# Optional:     dunk, block, fire
# A missing file (or an unknown name) is silently skipped: one print per name, never an error.
# Every play() call counts a stat "sfx_<name>", even when the file is missing.
# Headless runs (tests) look files up but never start playback: nothing is audible there, and a sound
# still playing when a test quits would show up as a "resources still in use" error at exit.
#
# Music (P4-02):  game.audio.play_music("menu")   game.audio.stop_music()   game.audio.set_music_on(false)
#                 game.audio.set_music_ducked(true)   (softer during play, Q5 a)
# Tracks are res://assets/music/<track>.ogg (or .wav), looped. A missing file is skipped with one print per track.
# Two players crossfade: the new track fades in while the old one fades out. play_music() with the track already
# playing does nothing (no restart). With music off, play_music() only remembers the track; set_music_on(true)
# starts it. music_on is not saved here: the panel task saves it and calls set_music_on() at launch.
# Every play_music() call that changes the track counts a stat "music_<track>", even when the file is missing.
# Sound volume (P5-07):  game.audio.set_sfx_volume(0.5)   (0..1 for the effects; 0 = silent; music unaffected)
# sfx_volume is saved in user://settings.cfg (the file and section menu.gd keeps the music choice in) and read once
# per run (the first audio node reads it). Stats still count at volume 0. set_sfx_volume(v, false) changes it without
# saving (a slider being dragged); save_sfx_volume() writes it.
# Music volume (P7-02):  game.audio.set_music_volume(0.5)   (0..1; 0 = silent; 1.0 = the music exactly as before)
# music_volume is saved as "music_volume" in the same file and section, read once per run with sfx_volume.
# set_music_volume(v, false) changes it without saving; save_music_volume() writes it. It is one more gain on top of
# the fades and the ducking (same SFX_VOLUME_CURVE as the effects). Volume 0 does not turn MUSIC ON/OFF off.
# The test flag --music-volume X (Difficulty.music_volume_flag, >= 0 when given) wins for the run and is never saved.
# On the web, browsers keep audio locked until the first tap: the music waits until the page's audio context runs
# (the head script in export_presets.cfg resumes it on tap/lift), then starts.
#
# Ambience (P6-15):  game.audio.play_ambience("rain")   game.audio.stop_ambience()   game.audio.set_ambience_paused(true)
# One looped background sound at a time (a city twist's rain, wind or loud crowd; twist_fx.gd starts it). Files are
# res://assets/sfx/<name>.ogg (or .wav), looped here; a missing file is silent (one print per name). It fades in and
# out, follows the SOUND volume (sfx_volume) and is ducked with the music. A name starting with "crowd" also gets the
# twist's Twists.value("crowd_db") (Memphis: much louder). The player is PROCESS_MODE_PAUSABLE, so it stops by itself
# while the tree is paused (pause.gd); set_ambience_paused() does the same by hand. Counts a stat "ambience_<name>".

const SFX_DIR := "res://assets/sfx/"
const EXTENSIONS := ["ogg", "wav"]
const POOL_SIZE := 6              # how many sounds can play at the same time
const MASTER_DB := 0.0            # overall effects volume in dB (lower = quieter)
const MUSIC_DIR := "res://assets/music/"
const MUSIC_DB := -14.0           # music volume in dB, well below the effects
const MUSIC_DUCK_DB := -8.0       # extra dB down while ducked (during play, Q5 a)
const MUSIC_DUCK_FADE := 0.6      # seconds to duck or unduck
const MUSIC_SILENT_DB := -60.0    # a fade ends here, then the player stops
const UNLOCK_POLL := 0.25         # web: seconds between checks of the page's audio state
const SETTINGS_PATH := "user://settings.cfg"   # same file and section as difficulty.gd / menu.gd
const SETTINGS_SECTION := "settings"
const SAVE_SFX_VOLUME := "sfx_volume"          # key of the effects volume (0..1)
const SFX_VOLUME_DEFAULT := 1.0   # first launch: full volume
const SAVE_MUSIC_VOLUME := "music_volume"      # key of the music volume (0..1, P7-02)
const MUSIC_VOLUME_DEFAULT := 1.0 # first launch: 1.0 = MUSIC_DB, today's music level
const DIFFICULTY_PATH := "res://scripts/difficulty.gd"   # holds music_volume_flag (--music-volume X); loaded at run
                                                         # time and read by name, so audio.gd has no preload of it
const MUSIC_VOLUME_FLAG := "music_volume_flag"
const SFX_VOLUME_CURVE := 2.0     # gain = volume ^ this: a slider at half sounds about half as loud (not just -6 dB)
const AMBIENCE_DB := -20.0        # ambience loop volume in dB. The loops are loud files (-1 dB peak, RMS about -13 to
                                  # -16 dBFS): -20 here, -4 ducked, puts them about -40 dBFS RMS in play, a bed under the
                                  # ducked music (-20 LUFS tracks at -22 dB) and well under the effects
const AMBIENCE_TRIM := {          # dB per loop, evening out the measured RMS (P6-A5) to wind's -16 dBFS
	"rain": -1.5, "wind": 0.0, "crowd_loud": -2.5,
}
const AMBIENCE_DUCK_DB := -4.0    # extra dB down while ducked (with the music during play)
const AMBIENCE_FADE := 1.2        # seconds to fade an ambience loop in or out
const AMBIENCE_CROWD_PREFIX := "crowd"   # ambience names starting with this get the twist's crowd_db

const Twists = preload("res://scripts/twists.gd")   # crowd_db for the crowd loop (P6-15)

static var sfx_volume := SFX_VOLUME_DEFAULT   # 0..1, the effects volume (survives reload_current_scene)
static var music_volume := MUSIC_VOLUME_DEFAULT   # 0..1, the music volume (P7-02, survives reload_current_scene)
static var _volume_read := false
static var _flag_script: Script = null   # difficulty.gd, for the --music-volume flag

var game
var _pool: Array = []
var _next := 0
var _cache := {}                  # name -> AudioStream, or null when no file was found
var _rng := RandomNumberGenerator.new()
var _headless := DisplayServer.get_name() == "headless"

var music_on := true              # the on/off choice (saved later by the panel task)
var music_track := ""             # the track asked for last ("" = none), kept while music is off
var music_ducked := false
var _music: Array = []            # two AudioStreamPlayers for crossfades
var _music_gain: Array = [0.0, 0.0]   # linear gain 0..1 of each player (its fade position)
var _music_tween: Array = [null, null]
var _music_cur := 0               # index of the player with the current track
var _music_cache := {}            # track -> AudioStream, or null when no file was found
var _duck := 0.0                  # 0..1, how far the duck is applied
var _duck_tween: Tween = null
var _unlocked := true             # web: false until the page's audio runs
var _tap_seen := false
var _poll_t := 0.0

var ambience_name := ""           # the ambience loop asked for ("" = none)
var ambience_db := 0.0            # its extra volume (play_ambience's db)
var _amb: AudioStreamPlayer       # the ambience loop (PROCESS_MODE_PAUSABLE: silent while the tree is paused)
var _amb_gain := 0.0              # 0..1 fade position
var _amb_tween: Tween = null
var _amb_paused := false
var _amb_cache := {}              # name -> looped AudioStream (its own copy, so a one-shot of the same file stays one-shot)

func _ready() -> void:
	_rng.randomize()
	read_settings()
	process_mode = Node.PROCESS_MODE_ALWAYS   # fades keep going if the tree is ever paused
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.volume_db = MUSIC_SILENT_DB
		add_child(m)
		_music.append(m)
	_amb = AudioStreamPlayer.new()
	_amb.volume_db = MUSIC_SILENT_DB
	_amb.process_mode = Node.PROCESS_MODE_PAUSABLE   # the tree's pause (pause.gd) pauses the loop, resume continues it
	add_child(_amb)
	_unlocked = not OS.has_feature("web")
	set_process(not _unlocked)
	set_process_input(not _unlocked)

func play(sfx_name: String, volume_db := 0.0, pitch_jitter := 0.05) -> void:
	if game != null:
		game.stat("sfx_" + sfx_name)
	var stream: AudioStream = _get_stream(sfx_name)
	if stream == null or _headless or sfx_volume <= 0.0:
		return
	var p: AudioStreamPlayer = _free_player()
	p.stream = stream
	p.volume_db = MASTER_DB + volume_db + linear_to_db(pow(sfx_volume, SFX_VOLUME_CURVE))
	p.pitch_scale = maxf(0.05, 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter))
	p.play()

func _get_stream(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var stream: AudioStream = null
	if sfx_name != "" and sfx_name.is_valid_filename():
		for ext in EXTENSIONS:
			var path: String = SFX_DIR + sfx_name + "." + ext
			if ResourceLoader.exists(path):
				stream = load(path) as AudioStream
				if stream != null:
					break
	if stream == null:
		print("audio: no sound file for '%s' (looked in %s), skipping" % [sfx_name, SFX_DIR])
	_cache[sfx_name] = stream
	return stream

func _free_player() -> AudioStreamPlayer:
	# prefer an idle player; if all are busy, reuse the next one in turn
	for i in POOL_SIZE:
		var p: AudioStreamPlayer = _pool[(_next + i) % POOL_SIZE]
		if not p.playing:
			_next = (_next + i + 1) % POOL_SIZE
			return p
	var q: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	return q

# ---------------- sound volume (P5-07) ----------------

# Once per run: the saved effects volume (safe to call again).
static func read_settings() -> void:
	if _volume_read:
		return
	_volume_read = true
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	sfx_volume = clampf(float(cfg.get_value(SETTINGS_SECTION, SAVE_SFX_VOLUME, sfx_volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value(SETTINGS_SECTION, SAVE_MUSIC_VOLUME, music_volume)), 0.0, 1.0)

static func save_sfx_volume() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)   # keep the other settings in the file
	cfg.set_value(SETTINGS_SECTION, SAVE_SFX_VOLUME, sfx_volume)
	cfg.save(SETTINGS_PATH)

# 0..1; 0 silences the effects (music unaffected). save := false while a slider is being dragged.
func set_sfx_volume(v: float, save := true) -> void:
	read_settings()   # a call before _ready must not be overwritten by the saved value later
	sfx_volume = clampf(v, 0.0, 1.0)
	if save:
		save_sfx_volume()
	_update_ambience_volume()

# ---------------- music volume (P7-02) ----------------

static func save_music_volume() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)   # keep the other settings in the file
	cfg.set_value(SETTINGS_SECTION, SAVE_MUSIC_VOLUME, music_volume)
	cfg.save(SETTINGS_PATH)

# 0..1; 0 silences the music (MUSIC ON/OFF unchanged). save := false while a slider is being dragged.
func set_music_volume(v: float, save := true) -> void:
	read_settings()   # a call before _ready must not be overwritten by the saved value later
	music_volume = clampf(v, 0.0, 1.0)
	if save:
		save_music_volume()
	if _music.size() == 2:
		_update_music_volume(0)
		_update_music_volume(1)

# the volume the music plays at: the --music-volume flag (Difficulty.music_volume_flag >= 0) for this run, else the
# saved / set music_volume. A difficulty.gd without the flag (or a flag < 0) means no flag.
static func effective_music_volume() -> float:
	read_settings()
	if _flag_script == null and ResourceLoader.exists(DIFFICULTY_PATH):
		_flag_script = load(DIFFICULTY_PATH) as Script
	if _flag_script != null:
		var f = _flag_script.get(MUSIC_VOLUME_FLAG)
		if f != null and float(f) >= 0.0:
			return clampf(float(f), 0.0, 1.0)
	return music_volume

# ---------------- music ----------------

func play_music(track: String, fade := 1.0) -> void:
	if track == music_track:
		return
	music_track = track
	if game != null and track != "":
		game.stat("music_" + track)
	_music_apply(fade)

func stop_music(fade := 1.0) -> void:
	music_track = ""
	_music_apply(fade)

func set_music_on(on: bool) -> void:
	if on == music_on:
		return
	music_on = on
	_music_apply(0.5)

func set_music_ducked(ducked: bool) -> void:
	if ducked == music_ducked:
		return
	music_ducked = ducked
	if _duck_tween != null:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(_set_duck, _duck, 1.0 if ducked else 0.0, MUSIC_DUCK_FADE)

# fade the current player out and start the wanted track (if any, music on, audio unlocked) on the other one
func _music_apply(fade: float) -> void:
	var stream: AudioStream = null
	if music_track != "":
		stream = _get_music(music_track)   # looked up even headless, so a missing file prints in tests too
	if _headless or not _unlocked:
		return
	if not music_on:
		stream = null
	var cur: AudioStreamPlayer = _music[_music_cur]
	if stream != null and cur.playing and cur.stream == stream:
		_fade_player(_music_cur, 1.0, fade)   # same track (e.g. music back on mid fade-out): fade it back in
		return
	if cur.playing:
		_fade_player(_music_cur, 0.0, fade)
	if stream == null:
		return
	_music_cur = 1 - _music_cur
	var p: AudioStreamPlayer = _music[_music_cur]
	if _music_tween[_music_cur] != null:
		_music_tween[_music_cur].kill()
	p.stop()
	p.stream = stream
	_set_gain(0.0, _music_cur)
	p.play()
	_fade_player(_music_cur, 1.0, fade)

func _fade_player(i: int, to: float, fade: float) -> void:
	if _music_tween[i] != null:
		_music_tween[i].kill()
		_music_tween[i] = null
	if fade <= 0.0:
		_set_gain(to, i)
		if to <= 0.0:
			_music[i].stop()
		return
	var t := create_tween()
	t.tween_method(_set_gain.bind(i), _music_gain[i], to, fade)
	if to <= 0.0:
		t.tween_callback(_music[i].stop)
	_music_tween[i] = t

func _set_gain(g: float, i: int) -> void:
	_music_gain[i] = g
	_update_music_volume(i)

func _set_duck(d: float) -> void:
	_duck = d
	_update_music_volume(0)
	_update_music_volume(1)
	_update_ambience_volume()

func _update_music_volume(i: int) -> void:
	var g: float = _music_gain[i]
	var vol: float = pow(effective_music_volume(), SFX_VOLUME_CURVE)   # 1.0 = today's level exactly
	var db: float = MUSIC_SILENT_DB
	if g > 0.001 and vol > 0.0:
		db = maxf(MUSIC_SILENT_DB, MUSIC_DB + linear_to_db(g * vol) + MUSIC_DUCK_DB * _duck)
	_music[i].volume_db = db

func _get_music(track: String) -> AudioStream:
	if _music_cache.has(track):
		return _music_cache[track]
	var stream: AudioStream = null
	if track.is_valid_filename():
		for ext in EXTENSIONS:
			var path: String = MUSIC_DIR + track + "." + ext
			if ResourceLoader.exists(path):
				stream = load(path) as AudioStream
				if stream != null:
					break
	if stream == null:
		print("audio: no music file for '%s' (looked in %s), skipping" % [track, MUSIC_DIR])
	else:
		_set_loop(stream)
	_music_cache[track] = stream
	return stream

func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var w := stream as AudioStreamWAV
		if w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * float(w.mix_rate))
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

# ---------------- ambience (P6-15) ----------------

# Start a looped ambience sound (fading in; the one before fades out). Same name again: only the volume changes.
func play_ambience(amb_name: String, db := 0.0) -> void:
	if amb_name == "":
		stop_ambience()
		return
	ambience_db = db
	if amb_name == ambience_name:
		_update_ambience_volume()
		return
	ambience_name = amb_name
	if game != null:
		game.stat("ambience_" + amb_name)
	_ambience_apply()

# Fade the ambience out and stop it.
func stop_ambience(fade := AMBIENCE_FADE) -> void:
	ambience_name = ""
	_amb_fade(0.0, fade)

# Pause or resume the loop by hand (the tree's pause already does it: the player is PROCESS_MODE_PAUSABLE).
func set_ambience_paused(paused: bool) -> void:
	_amb_paused = paused
	if _amb != null and _amb.playing:
		_amb.stream_paused = paused

func _ambience_apply() -> void:
	var stream: AudioStream = _get_ambience(ambience_name)   # looked up headless too, so a missing file prints
	if stream == null or _headless or not _unlocked or _amb == null:
		_amb_fade(0.0, AMBIENCE_FADE)
		return
	if _amb.playing and _amb.stream == stream:
		_amb_fade(1.0, AMBIENCE_FADE)
		return
	if _amb.playing and _amb_gain > 0.01:
		# fade the old loop out, then start the new one
		_amb_fade(0.0, AMBIENCE_FADE * 0.5, _ambience_start.bind(stream))
		return
	_ambience_start(stream)

func _ambience_start(stream: AudioStream) -> void:
	if ambience_name == "" or _get_ambience(ambience_name) != stream:
		return   # changed (or stopped) while the old loop faded out
	_amb.stop()
	_amb.stream = stream
	_amb_gain = 0.0
	_update_ambience_volume()
	_amb.play()
	_amb.stream_paused = _amb_paused
	_amb_fade(1.0, AMBIENCE_FADE)

func _amb_fade(to: float, fade: float, then := Callable()) -> void:
	if _amb_tween != null:
		_amb_tween.kill()
		_amb_tween = null
	if _amb == null:
		return
	if fade <= 0.0 or not _amb.playing:
		_set_amb_gain(to)
		if to <= 0.0:
			_amb.stop()
		if then.is_valid():
			then.call()
		return
	_amb_tween = create_tween()
	_amb_tween.tween_method(_set_amb_gain, _amb_gain, to, fade)
	if to <= 0.0:
		_amb_tween.tween_callback(_amb.stop)
	if then.is_valid():
		_amb_tween.tween_callback(then)

func _set_amb_gain(g: float) -> void:
	_amb_gain = g
	_update_ambience_volume()

func _update_ambience_volume() -> void:
	if _amb == null:
		return
	var db: float = MUSIC_SILENT_DB
	var vol: float = pow(sfx_volume, SFX_VOLUME_CURVE)
	if _amb_gain > 0.001 and vol > 0.0:
		db = AMBIENCE_DB + float(AMBIENCE_TRIM.get(ambience_name, 0.0)) + ambience_db + linear_to_db(_amb_gain * vol) + AMBIENCE_DUCK_DB * _duck
		if ambience_name.begins_with(AMBIENCE_CROWD_PREFIX):
			db += Twists.value("crowd_db", 0.0)   # Memphis' full house (0 without a twist)
		db = maxf(MUSIC_SILENT_DB, db)
	_amb.volume_db = db

# the looped stream of an ambience name (its own copy of the file), null when there is no file
func _get_ambience(amb_name: String) -> AudioStream:
	if _amb_cache.has(amb_name):
		return _amb_cache[amb_name]
	var stream: AudioStream = null
	if amb_name.is_valid_filename():
		for ext in EXTENSIONS:
			var path: String = SFX_DIR + amb_name + "." + ext
			if ResourceLoader.exists(path):
				stream = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
				if stream != null:
					break
	if stream == null:
		print("audio: no ambience file for '%s' (looked in %s), silent" % [amb_name, SFX_DIR])
	else:
		_set_loop(stream)
	_amb_cache[amb_name] = stream
	return stream

# ---------------- web audio unlock ----------------

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey:
		if event.is_pressed() or event is InputEventScreenTouch:
			_tap_seen = true

func _process(delta: float) -> void:
	_poll_t -= delta
	if _poll_t > 0.0:
		return
	_poll_t = UNLOCK_POLL
	if _web_audio_running():
		_unlocked = true
		set_process(false)
		set_process_input(false)
		_music_apply(1.0)
		if ambience_name != "":
			_ambience_apply()

# true once the page's audio context runs; without the page hook, true after the first tap
func _web_audio_running() -> bool:
	if not _tap_seen:
		return false   # a context may report "running" before any tap on some browsers, but stays silent
	var r = JavaScriptBridge.eval("(function(){var c=window.__hoopsAudio;if(!c||!c.length)return -1;" +
		"for(var i=0;i<c.length;i++){if(c[i].state!=='running')return 0;}return 1;})()", true)
	if r == null:
		return true
	return int(r) != 0

func _exit_tree() -> void:
	for m in _music:
		m.stop()
	if _amb != null:
		_amb.stop()
		_amb.stream = null   # (its own copy of the file: let it go with the node)
	_amb_cache.clear()
