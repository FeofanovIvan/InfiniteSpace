extends Node
## Dedicated race audio: no shared minigame music and no changes to Main/Bubble.
const RACE_MUSIC: AudioStream = preload("res://space_racing/audio/neon_sign_race_loop.ogg")
const RED_SIGNAL: AudioStream = preload("res://space_racing/audio/traffic_red.wav")
const YELLOW_SIGNAL: AudioStream = preload("res://space_racing/audio/traffic_yellow.wav")
const GREEN_SIGNAL: AudioStream = preload("res://space_racing/audio/traffic_green.wav")
const MUSIC_VOLUME_DB: float = -10.0 # Roughly half as loud perceptually.

var _music: AudioStreamPlayer
var _signal: AudioStreamPlayer
var _fade: Tween
var _exploration_music: Node
var _previous_context: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.name = "RaceMusicOnly"
	_music.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	_music.volume_db = -40.0
	# Duplicate before configuring looping; imported assets are shared resources.
	var repeatable: AudioStream = RACE_MUSIC.duplicate() as AudioStream
	repeatable.set("loop", true)
	_music.stream = repeatable
	add_child(_music)
	_signal = AudioStreamPlayer.new()
	_signal.name = "ThreeRaceLightSignals"
	_signal.volume_db = -3.0
	add_child(_signal)
	# The existing station background music must not play over this track.
	# Restore the original context when this racing scene is removed.
	_exploration_music = get_tree().root.find_child("AdaptiveExplorationMusic", true, false)
	if is_instance_valid(_exploration_music) and _exploration_music.has_method("get_context"):
		_previous_context = str(_exploration_music.call("get_context"))
		_exploration_music.call("set_context", "silent", true)


func signal_light(index: int) -> void:
	if not is_instance_valid(_signal):
		return
	match index:
		0: _signal.stream = RED_SIGNAL
		1: _signal.stream = YELLOW_SIGNAL
		2: _signal.stream = GREEN_SIGNAL
		_: return
	_signal.stop()
	_signal.play()


func start_music() -> void:
	if not is_instance_valid(_music) or _music.playing:
		return
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_music.volume_db = -40.0
	_music.play()
	_fade = create_tween()
	_fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade.tween_property(_music, "volume_db", MUSIC_VOLUME_DB, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func stop_all() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if is_instance_valid(_music):
		_music.stop()
	if is_instance_valid(_signal):
		_signal.stop()


func _exit_tree() -> void:
	stop_all()
	if is_instance_valid(_exploration_music) and not _previous_context.is_empty():
		_exploration_music.call("set_context", _previous_context, true)
