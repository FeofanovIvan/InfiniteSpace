extends RefCounted
const RaceProgress = preload("res://space_racing/RaceProgress.gd")
## Launch bridge: call RaceSession.launch(tree, station_id, difficulty) from station card.
## Root metadata survives the scene switch and is consumed once by the race.
const SESSION_KEY: String = "mika_race_session_v8"

static func launch(tree: SceneTree, station_id: String, difficulty: String = "normal", return_scene: String = "res://scenes/main.tscn") -> Error:
	if not station_id.is_empty() and not station_id.begins_with("mw"):
		if not RaceProgress.is_unlocked(station_id):
			return ERR_UNAUTHORIZED
	if not difficulty in ["easy", "normal", "hard"]:
		return ERR_INVALID_PARAMETER
	tree.root.set_meta(SESSION_KEY, {"planet": station_id, "difficulty": difficulty, "return_scene": return_scene})
	return tree.change_scene_to_file("res://space_racing/SpaceRace.tscn")

static func take() -> Dictionary:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or not tree.root.has_meta(SESSION_KEY):
		return {}
	var data: Dictionary = tree.root.get_meta(SESSION_KEY)
	tree.root.remove_meta(SESSION_KEY)
	return data
