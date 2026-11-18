extends Node
## Only foley for Bubble's ball-throwing game. No music player is created.

const THROW_WHOOSH: AudioStream = preload("res://bubble/ball_play/audio/throw_whoosh.wav")
const FLIGHT_WHISTLE: AudioStream = preload("res://bubble/ball_play/audio/flight_whistle.ogg")
const LANDING_BOUNCE: AudioStream = preload("res://bubble/ball_play/audio/landing_bounce.wav")
const RETURN_PLOP: AudioStream = preload("res://bubble/ball_play/audio/return_plop.wav")
const WHISTLE_DURATION: float = 2.20

var _whoosh: AudioStreamPlayer
var _flight: AudioStreamPlayer
var _impact: AudioStreamPlayer
var _exploration_music: Node
var _previous_context: String = ""
var _finished: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_whoosh = _new_player("BallThrowWhoosh", -9.5)
	_flight = _new_player("BallFlightWhistle", -15.0)
	_impact = _new_player("BallSoftLanding", -11.0)
	_whoosh.stream = THROW_WHOOSH
	_flight.stream = FLIGHT_WHISTLE
	# The ball game is intentionally without background music. Temporarily
	# silence main exploration music while this minigame is shown.
	_exploration_music = get_tree().root.find_child("AdaptiveExplorationMusic", true, false)
	if is_instance_valid(_exploration_music) and _exploration_music.has_method("get_context"):
		_previous_context = str(_exploration_music.call("get_context"))
		_exploration_music.call("set_context", "silent", true)


func _new_player(label: String, gain_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = label
	player.volume_db = gain_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func throw_ball(flight_seconds: float, strength: float) -> void:
	if not is_instance_valid(_whoosh):
		return
	_whoosh.stop()
	_flight.stop()
	_impact.stop()
	_whoosh.pitch_scale = lerpf(0.94, 1.16, clampf(strength, 0.0, 1.0))
	_whoosh.play()
	# Adjust the whistle to end at the real landing, even on a short throw.
	_flight.pitch_scale = clampf(WHISTLE_DURATION / maxf(0.4, flight_seconds), 0.85, 1.75)
	_flight.play()


func land_ball(strength: float) -> void:
	if not is_instance_valid(_impact):
		return
	_flight.stop()
	_impact.stop()
	_impact.stream = LANDING_BOUNCE
	_impact.pitch_scale = lerpf(1.06, 0.90, clampf(strength, 0.0, 1.0))
	_impact.volume_db = lerpf(-15.0, -10.0, clampf(strength, 0.0, 1.0))
	_impact.play()


func ball_returned() -> void:
	if not is_instance_valid(_impact):
		return
	_impact.stop()
	_impact.stream = RETURN_PLOP
	_impact.pitch_scale = randf_range(0.96, 1.04)
	_impact.volume_db = -13.0
	_impact.play()


func finish_play() -> void:
	if _finished:
		return
	_finished = true
	for player in [_whoosh, _flight, _impact]:
		if is_instance_valid(player):
			player.stop()
	if is_instance_valid(_exploration_music) and not _previous_context.is_empty():
		_exploration_music.call("set_context", _previous_context, true)


func _exit_tree() -> void:
	finish_play()
