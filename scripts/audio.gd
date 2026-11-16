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
# On the web, browsers keep audio locked until the first tap: the music waits until the page's audio context runs
# (the head script in export_presets.cfg resumes it on tap/lift), then starts.

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

func _ready() -> void:
	_rng.randomize()
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
	_unlocked = not OS.has_feature("web")
	set_process(not _unlocked)
	set_process_input(not _unlocked)

func play(sfx_name: String, volume_db := 0.0, pitch_jitter := 0.05) -> void:
	if game != null:
		game.stat("sfx_" + sfx_name)
	var stream: AudioStream = _get_stream(sfx_name)
	if stream == null or _headless:
		return
	var p: AudioStreamPlayer = _free_player()
	p.stream = stream
	p.volume_db = MASTER_DB + volume_db
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

func _update_music_volume(i: int) -> void:
	var g: float = _music_gain[i]
	var db: float = MUSIC_SILENT_DB
	if g > 0.001:
		db = maxf(MUSIC_SILENT_DB, MUSIC_DB + linear_to_db(g) + MUSIC_DUCK_DB * _duck)
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
