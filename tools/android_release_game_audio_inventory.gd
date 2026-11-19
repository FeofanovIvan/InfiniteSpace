extends SceneTree
## Launches every simulator game through the production wrapper and inventories
## its runtime audio players. This does not simulate every gameplay gesture;
## connected effects with a deferred stream are counted as players, while loaded
## streams show what is ready immediately after scene startup.

const MENU_SCRIPT_PATH := "res://tools/test_doubles/mvp_menu_free_world_test_double.gd"
const PLANET_CATALOG := "res://simulator_ui/data/temp_planet_cards_v1151p24.json"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("GAME_AUDIO_INVENTORY_FAIL: " + message)


func _wait_frames(count: int = 4) -> void:
	for _frame in range(count):
		await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var menu_script := load(MENU_SCRIPT_PATH) as Script
	_check(menu_script != null, "simulator wrapper compiles")
	if menu_script == null:
		quit(1)
		return
	var menu := menu_script.new() as Control
	root.add_child(menu)
	menu.size = Vector2(1280, 720)
	await _wait_frames()
	var core_cards: Array = menu.get("_cards") as Array
	for raw_info in core_cards:
		var info := raw_info as Dictionary
		await _audit_route(menu, str(info.get("id", "")), str(info.get("scene_path", "")), false)

	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLANET_CATALOG))
	var entries: Array = (catalog as Dictionary).get("entries", []) as Array
	for raw_entry in entries:
		var entry := raw_entry as Dictionary
		var game_id := str(entry.get("id", ""))
		var scene_path := str(menu.call("_v1151p24_find_scene", entry))
		await _audit_route(menu, game_id, scene_path, true)

	menu.queue_free()
	await _wait_frames()
	print("Game audio inventory: ", "PASS" if _failures == 0 else "%d FAILED" % _failures)
	quit(0 if _failures == 0 else 1)


func _audit_route(menu: Control, game_id: String, scene_path: String, planet_route: bool) -> void:
	_check(not scene_path.is_empty(), "scene resolves: " + game_id)
	if scene_path.is_empty():
		return
	if planet_route:
		menu.call("_v1151p24_open_card", game_id)
	else:
		menu.call("_open_game", scene_path)
	await _wait_frames(5)
	var viewport := menu.get("_game_viewport") as SubViewport
	_check(bool(menu.get("_playing")) and viewport.get_child_count() == 1, "scene launches: " + game_id)
	if viewport.get_child_count() == 1:
		var stats := {"music": 0, "music_playing": 0, "effects": 0, "effects_loaded": 0, "voice": 0, "voice_loaded": 0, "invalid_bus": 0}
		_collect_audio(viewport.get_child(0), stats)
		var result := "PASS"
		if int(stats.music_playing) > 1 or int(stats.invalid_bus) > 0:
			result = "FAIL"
			_failures += 1
		print("AUDIO_ROW\t%s\tMusic %d/%d playing\tEffects %d/%d loaded\tVoice %d/%d loaded\t%s" % [
			game_id,
			int(stats.music), int(stats.music_playing),
			int(stats.effects), int(stats.effects_loaded),
			int(stats.voice), int(stats.voice_loaded),
			result,
		])
	menu.call("_return_to_cards")
	await _wait_frames()


func _collect_audio(node: Node, stats: Dictionary) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		var bus_name := str(node.get("bus"))
		var stream: AudioStream = node.get("stream") as AudioStream
		var signature := (str(node.name) + " " + (stream.resource_path if stream != null else "")).to_lower()
		if AudioServer.get_bus_index(bus_name) < 0:
			stats.invalid_bus = int(stats.invalid_bus) + 1
		if bus_name == "Music" or "music" in signature or "ambient" in signature:
			stats.music = int(stats.music) + 1
			if bool(node.get("playing")):
				stats.music_playing = int(stats.music_playing) + 1
		elif bus_name == "VOICE" or _looks_like_voice(signature):
			stats.voice = int(stats.voice) + 1
			if stream != null:
				stats.voice_loaded = int(stats.voice_loaded) + 1
		else:
			stats.effects = int(stats.effects) + 1
			if stream != null:
				stats.effects_loaded = int(stats.effects_loaded) + 1
	for child in node.get_children():
		_collect_audio(child, stats)


func _looks_like_voice(signature: String) -> bool:
	for token in ["voice", "speaker", "instruction", "spoken", "narrat", "hintplayer"]:
		if token in signature:
			return true
	return false
