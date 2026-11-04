extends SceneTree
## Run: godot --headless --path . --script res://glossary/tests/glossary_smoke.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://glossary/scenes/glossary_screen.tscn") as PackedScene
	if scene == null:
		push_error("Glossary smoke: scene cannot be loaded.")
		quit(1)
		return
	var screen: Control = scene.instantiate() as Control
	root.add_child(screen)
	await process_frame
	screen.call("open_glossary", Vector2(1280.0, 720.0))
	var expected: Dictionary = {
		"planets": 49, # 48 normal worlds + separate Crossroads entry
		"stations": 6,
		"races": 9,
		"characters": 30,
		"science": 48,
		"terms": 16
	}
	var failed: bool = false
	for category in expected:
		var entries: Array = screen.call("_entries_for", category)
		if entries.size() != int(expected[category]):
			push_error("Glossary smoke: %s got %d, expected %d" % [category, entries.size(), expected[category]])
			failed = true
	screen.call("_open_category", "characters")
	screen.call("_go_back")
	screen.call("_open_category", "science")
	screen.call("_go_back")
	screen.call("close_glossary")
	if failed:
		quit(1)
	else:
		print("Glossary smoke: 48 planets, Crossroads, 6 stations, 9 life forms, 30 NPCs, 48 science topics, 16 terms loaded.")
		quit(0)
