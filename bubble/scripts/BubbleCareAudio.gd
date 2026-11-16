extends Node
## Room-only Bubble soundtrack and foley. No audio is added to ball play or racing.

const ROOM_MUSIC: AudioStream = preload("res://bubble/audio/feel_good_island_loop.ogg")
const SHOWER_VALVE: AudioStream = preload("res://bubble/audio/shower_valve.wav")
const SHOWER_WATER: AudioStream = preload("res://bubble/audio/shower_water.ogg")
const SHOWER_SCRUB: AudioStream = preload("res://bubble/audio/shower_scrub.wav")
const FOOD_POUR: AudioStream = preload("res://bubble/audio/food_pour.wav")
const FOOD_MUNCH: AudioStream = preload("res://bubble/audio/food_munch.ogg")
const WATER_SIP: AudioStream = preload("res://bubble/audio/water_sip.ogg")
const TOOTHBRUSH: AudioStream = preload("res://bubble/audio/toothbrush.wav")
const SLEEP_YAWN: AudioStream = preload("res://bubble/audio/sleep_yawn.wav")
const SLEEP_BREATH: AudioStream = preload("res://bubble/audio/sleep_breath.ogg")

const ROOM_MUSIC_DB: float = -16.0
const EFFECT_LOOP_DB: float = -12.0
const EFFECT_ONESHOT_DB: float = -9.0
const EFFECT_GESTURE_DB: float = -11.0

var _music: AudioStreamPlayer
var _loop_effect: AudioStreamPlayer
var _one_shot: AudioStreamPlayer
var _gesture: AudioStreamPlayer
var _fade: Tween
var _exploration: Node
var _previous_context: String = ""
var _active_action: String = ""
var _feed_phase: String = ""
var _last_progress: float = 0.0
var _next_gesture_msec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = _new_player("BubbleCareMusic", -48.0, true)
	_loop_effect = _new_player("BubbleCareActionLoop", EFFECT_LOOP_DB, false)
	_one_shot = _new_player("BubbleCareEventSound", EFFECT_ONESHOT_DB, false)
	_gesture = _new_player("BubbleCareBrushSound", EFFECT_GESTURE_DB, false)
	_music.stream = _as_loop(ROOM_MUSIC)
	# The main game's exploration soundtrack must not overlap the room track.
	_exploration = get_tree().root.find_child("AdaptiveExplorationMusic", true, false)
	if is_instance_valid(_exploration) and _exploration.has_method("get_context"):
		_previous_context = str(_exploration.call("get_context"))
		_exploration.call("set_context", "silent", true)
	_music.play()
	_fade = create_tween()
	_fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade.tween_property(_music, "volume_db", ROOM_MUSIC_DB, 0.90).set_trans(Tween.TRANS_SINE)


func _new_player(node_name: String, decibels: float, music_bus: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = "Music" if music_bus and AudioServer.get_bus_index("Music") >= 0 else "Master"
	player.volume_db = decibels
	add_child(player)
	return player


func _as_loop(source: AudioStream) -> AudioStream:
	var copy: AudioStream = source.duplicate() as AudioStream
	copy.set("loop", true)
	return copy


func _play_loop(source: AudioStream, volume_db: float = EFFECT_LOOP_DB) -> void:
	_loop_effect.stop()
	_loop_effect.volume_db = volume_db
	_loop_effect.stream = _as_loop(source)
	_loop_effect.play()


func _play_once(source: AudioStream, volume_db: float = EFFECT_ONESHOT_DB) -> void:
	_one_shot.stop()
	_one_shot.volume_db = volume_db
	_one_shot.stream = source
	_one_shot.play()


func start_action(action: String) -> void:
	stop_action()
	_active_action = action
	_last_progress = 0.0
	_next_gesture_msec = 0
	match action:
		"shower":
			_play_once(SHOWER_VALVE)
			_play_loop(SHOWER_WATER, -13.0)
		"food":
			_feed_phase = "filling"
			_play_once(FOOD_POUR, -7.0)
		"water":
			_play_loop(WATER_SIP, -12.0)
		"bed":
			_play_once(SLEEP_YAWN, -12.0)
			_play_loop(SLEEP_BREATH, -16.0)
		# Teeth are heard only while the child actually brushes plaque.
		"mirror":
			pass


func update_feed_phase(phase: String) -> void:
	if _active_action != "food" or phase == _feed_phase:
		return
	_feed_phase = phase
	match phase:
		"eating":
			_one_shot.stop()
			_play_loop(FOOD_MUNCH, -14.0)
		"clearing", "empty":
			_loop_effect.stop()


func on_care_progress(action: String, progress: float) -> void:
	if action != _active_action or action not in ["shower", "mirror"]:
		return
	var gained: float = progress - _last_progress
	_last_progress = progress
	if gained <= 0.0005:
		return
	var now: int = Time.get_ticks_msec()
	if now < _next_gesture_msec:
		return
	_next_gesture_msec = now + (260 if action == "shower" else 220)
	_gesture.stop()
	_gesture.stream = SHOWER_SCRUB if action == "shower" else TOOTHBRUSH
	_gesture.pitch_scale = randf_range(0.95, 1.06)
	_gesture.play()


func stop_action() -> void:
	_active_action = ""
	_feed_phase = ""
	_last_progress = 0.0
	if is_instance_valid(_loop_effect):
		_loop_effect.stop()
	if is_instance_valid(_one_shot):
		_one_shot.stop()
	if is_instance_valid(_gesture):
		_gesture.stop()


func _exit_tree() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	stop_action()
	if is_instance_valid(_music):
		_music.stop()
	if is_instance_valid(_exploration) and not _previous_context.is_empty():
		_exploration.call("set_context", _previous_context, true)
