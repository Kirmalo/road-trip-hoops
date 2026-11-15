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

const SFX_DIR := "res://assets/sfx/"
const EXTENSIONS := ["ogg", "wav"]
const POOL_SIZE := 6              # how many sounds can play at the same time
const MASTER_DB := 0.0            # overall effects volume in dB (lower = quieter)

var game
var _pool: Array = []
var _next := 0
var _cache := {}                  # name -> AudioStream, or null when no file was found
var _rng := RandomNumberGenerator.new()
var _headless := DisplayServer.get_name() == "headless"

func _ready() -> void:
	_rng.randomize()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

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
