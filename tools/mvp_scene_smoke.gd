extends SceneTree
## MVP integration smoke: launch/return through the real simulator wrapper.
## Run with Godot 4.7.1:
##   godot --headless --path . --script res://tools/mvp_scene_smoke.gd

const MENU_SCRIPT_PATH := "res://tools/test_doubles/mvp_menu_free_world_test_double.gd"
const SPACE_RACE_SCENE_PATH := "res://space_racing/SpaceRace.tscn"
const EXPECTED_CORE_GAMES := 10
const EXPECTED_PLANET_GAMES := 24

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("MVP_SCENE_SMOKE_FAIL: " + message)


func _wait_frames(count: int = 3) -> void:
	for _frame in range(count):
		await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 720)
	# Runtime loads happen after project autoload singletons (MobileLocale,
	# LanguageService, EmbeddedGamePortal) have entered the tree.
	var menu_script: Script = load(MENU_SCRIPT_PATH) as Script
	_check(menu_script != null, "Free World simulator script loads")
	if menu_script == null:
		quit(1)
		return
	var menu: Control = menu_script.new() as Control
	root.add_child(menu)
	menu.size = Vector2(1280, 720)
	await _wait_frames()

	var core_cards: Array = menu.get("_cards") as Array
	var grid_cards: Array = menu.get("_grid_cards") as Array
	var planet_games: Dictionary = menu.get("_v1151p24_by_id") as Dictionary
	_check(core_cards.size() == EXPECTED_CORE_GAMES, "ten approved simulator games are connected")
	_check(planet_games.size() == EXPECTED_PLANET_GAMES, "24 Free World/planet games are registered")
	_check(grid_cards.size() == EXPECTED_CORE_GAMES + EXPECTED_PLANET_GAMES,
		"simulator grid contains ten main and 24 additional games")

	menu.set("_mika_is_free_world", true)
	menu.call("_mika_refresh_catalog", false)
	var first_ten_visible := true
	var extras_hidden := true
	for index in range(grid_cards.size()):
		var card: CanvasItem = grid_cards[index] as CanvasItem
		if index < EXPECTED_CORE_GAMES:
			first_ten_visible = first_ten_visible and card.visible
		else:
			extras_hidden = extras_hidden and not card.visible
	_check(first_ten_visible and extras_hidden, "Free World opens with exactly the ten main games")
	menu.call("_mika_toggle_more_games")
	await _wait_frames()
	var extras_visible := true
	for index in range(EXPECTED_CORE_GAMES, grid_cards.size()):
		extras_visible = extras_visible and (grid_cards[index] as CanvasItem).visible
	_check(extras_visible, "Free World expands all additional games")

	for raw_info in core_cards:
		var info: Dictionary = raw_info as Dictionary
		var scene_path := str(info.get("scene_path", ""))
		var game_id := str(info.get("id", scene_path))
		menu.call("_open_game", scene_path)
		await _wait_frames()
		var viewport: SubViewport = menu.get("_game_viewport") as SubViewport
		_check(bool(menu.get("_playing")) and viewport.get_child_count() == 1,
			"core game launches: " + game_id)
		menu.call("_return_to_cards")
		await _wait_frames()
		_check(not bool(menu.get("_playing")) and viewport.get_child_count() == 0,
			"core game returns: " + game_id)

	var catalog_data: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://simulator_ui/data/temp_planet_cards_v1151p24.json")
	)
	var entries: Array = (catalog_data as Dictionary).get("entries", []) as Array
	for raw_entry in entries:
		var entry: Dictionary = raw_entry as Dictionary
		var game_id := str(entry.get("id", ""))
		var resolved_path := str(menu.call("_v1151p24_find_scene", entry))
		_check(not resolved_path.is_empty(), "planet game resolves: " + game_id)
		if resolved_path.is_empty():
			continue
		menu.call("_v1151p24_open_card", game_id)
		await _wait_frames(4)
		var viewport: SubViewport = menu.get("_game_viewport") as SubViewport
		_check(bool(menu.get("_playing")) and viewport.get_child_count() == 1,
			"planet game launches: " + game_id)
		menu.call("_return_to_cards")
		await _wait_frames()
		_check(not bool(menu.get("_playing")) and viewport.get_child_count() == 0,
			"planet game returns: " + game_id)

	menu.call("open_bubble_care_direct", Vector2(1280, 720))
	await _wait_frames(4)
	var bubble_viewport: SubViewport = menu.get("_game_viewport") as SubViewport
	_check(bool(menu.get("_playing")) and bubble_viewport.get_child_count() == 1,
		"current Bubble Care scene launches")
	menu.call("_return_to_cards")
	await _wait_frames()
	_check(not bool(menu.get("_playing")), "Bubble Care returns to Free World")

	var race_scene: PackedScene = load(SPACE_RACE_SCENE_PATH) as PackedScene
	_check(race_scene != null, "Space Racing scene resource loads")
	if race_scene == null:
		menu.queue_free()
		quit(1)
		return
	var race: Node = race_scene.instantiate()
	root.add_child(race)
	await _wait_frames(5)
	_check(is_instance_valid(race) and race.is_inside_tree(), "Space Racing launches")
	race.queue_free()
	await _wait_frames()

	menu.queue_free()
	await _wait_frames()
	print("MVP scene smoke: ", "PASS" if _failures == 0 else "%d FAILED" % _failures)
	quit(0 if _failures == 0 else 1)
