extends Node
## Bridge intercepting Play Town's scene exits while games are embedded in Miko.
signal game_finished
var active: bool = false
var current_scene: String = ""

func start_game(scene: String) -> void:
	active = true
	current_scene = scene

func stop_game() -> void:
	active = false
	current_scene = ""

func handle_scene_transition(_scene: String) -> void:
	if active:
		game_finished.emit()

func change_scene_to_file(scene: String) -> Error:
	if active:
		handle_scene_transition(scene)
		return OK
	return ERR_UNAVAILABLE

func change_scene_to_packed(_scene: PackedScene) -> Error:
	if active:
		game_finished.emit()
		return OK
	return ERR_UNAVAILABLE
