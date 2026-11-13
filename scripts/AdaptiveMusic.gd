class_name AdaptiveMusic
extends Node

## Keeps exploration music quiet and switches it without audible cuts.
## The encoded files are already normalized to about -20 LUFS; these player
## gains place them well behind speech, interface sounds and game effects.

const ACTION_STREAM: AudioStream = preload("res://assets/audio/music/singularity_action_bg.ogg")
const CALM_STREAM: AudioStream = preload("res://assets/audio/music/singularity_calm_bg.ogg")
const SILENT_DB: float = -60.0
const FADE_SECONDS: float = 2.5
const TARGET_DB := {
	"flight": -13.0,
	"calm": -12.0,
}

var _players: Dictionary = {}
var _fades: Array[Tween] = []
var _current_context: String = "silent"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_players["flight"] = _make_player("FlightActionMusic", ACTION_STREAM)
	_players["calm"] = _make_player("PlanetCalmMusic", CALM_STREAM)
	set_context("flight", true)


func _make_player(player_name: String, source: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	player.volume_db = SILENT_DB
	# Duplicate before enabling looping so the imported resource remains immutable.
	var looping_stream: AudioStream = source.duplicate() as AudioStream
	looping_stream.set("loop", true)
	player.stream = looping_stream
	add_child(player)
	return player


func set_context(context: String, immediate: bool = false) -> void:
	var next_context := context if TARGET_DB.has(context) else "silent"
	if next_context == _current_context and not immediate:
		return
	_current_context = next_context
	_kill_fades()

	for key: String in _players:
		var player: AudioStreamPlayer = _players[key] as AudioStreamPlayer
		var is_active := key == next_context
		var destination := float(TARGET_DB[key]) if is_active else SILENT_DB
		if is_active and not player.playing:
			player.play()
		if immediate:
			player.volume_db = destination
			if not is_active:
				player.stop()
			continue
		var fade := create_tween()
		fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade.tween_property(player, "volume_db", destination, FADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if not is_active:
			fade.tween_callback(Callable(self, "_stop_if_inactive").bind(player, key))
		_fades.append(fade)


func get_context() -> String:
	return _current_context


func is_context_playing(context: String) -> bool:
	if not _players.has(context):
		return false
	return (_players[context] as AudioStreamPlayer).playing


func _stop_if_inactive(player: AudioStreamPlayer, context: String) -> void:
	if context != _current_context and is_instance_valid(player):
		player.stop()


func _kill_fades() -> void:
	for fade: Tween in _fades:
		if fade != null and fade.is_valid():
			fade.kill()
	_fades.clear()
