extends SceneTree
## Run explicitly: godot --headless --path . --script res://planet_hub/tests/dialogue_smoke.gd
## Makes a temporary change to user:// dialogue progress and restores it.

const EngineScript = preload("res://planet_hub/scripts/dialogue_engine.gd")
const SAVE_PATH := "user://miko_dialogue_progress.json"
var _fails: int = 0

func _check(ok: bool, description: String) -> void:
	if ok:
		print("PASS ", description)
	else:
		_fails += 1
		push_error("FAIL " + description)

func _initialize() -> void:
	var original_exists: bool = FileAccess.file_exists(SAVE_PATH)
	var original: String = FileAccess.get_file_as_string(SAVE_PATH) if original_exists else ""
	_run_checks()
	# Never leave test activity in a child's saved conversation progress.
	if original_exists:
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(original)
			file.close()
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Dialogue smoke test: ", "PASS" if _fails == 0 else "%d FAILED" % _fails)
	quit(0 if _fails == 0 else 1)

func _run_checks() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/dialogue_worlds.json"))
	_check(raw is Dictionary, "world database parses")
	if not (raw is Dictionary):
		return
	var all_worlds: Dictionary = raw.get("worlds", {})
	_check(all_worlds.size() == 54, "48 planets plus six stations")
	var planets: int = 0
	var nature: int = 0
	var active: int = 0
	for id in all_worlds:
		var world: Dictionary = all_worlds[id]
		if not bool(world.get("is_station", false)):
			planets += 1
		if bool(world.get("inhabited", false)):
			active += 1
		else:
			nature += 1
			_check(str(world.get("structure", {}).get("ru", "")).is_empty(), "nature-only " + str(id))
	_check(planets == 48 and active == 30 and nature == 24, "24 inhabited planets, 24 nature-only, 6 station crews")
	var phrases: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/dialogue_phrases.json"))
	_check(phrases is Dictionary and phrases.get("topics", {}).size() == 10, "ten dialogue topics")
	for lang in ["ru", "en", "fr", "de", "es", "pt_BR"]:
		var e: RefCounted = EngineScript.new()
		var result: Dictionary = e.call("begin", "mw_p01", lang)
		_check(bool(result.get("available", false)) and result.get("choices", []).size() == 3, "greeting options: " + lang)
		if not bool(result.get("available", false)):
			continue
		_check(str(e.call("get_hint", 1)) == str(result["choices"][1]), "selected hint: " + lang)
		var greeting: String = str(result["choices"][2])
		var advanced: Dictionary = e.call("accept", greeting)
		_check(bool(advanced.get("accepted", false)) and advanced.get("choices", []).size() == 3, "greeting recognized: " + lang)
		var query: String = str(phrases["topics"]["world"][lang][0])
		var response: Dictionary = e.call("accept", query)
		_check(bool(response.get("accepted", false)) and str(response.get("npc", "")).length() > 30, "world reply: " + lang)
	var invalid_world: RefCounted = EngineScript.new()
	var absent: Dictionary = invalid_world.call("begin", "m33_p08", "ru")
	_check(not bool(absent.get("available", true)), "uninhabited world has no resident dialogue")
	var station: RefCounted = EngineScript.new()
	var welcome: Dictionary = station.call("begin", "st_m31", "en")
	station.call("accept", "Hello!")
	var story: Dictionary = station.call("accept", "Tell me about this station.")
	_check(bool(story.get("accepted", false)), "station-specific question")
	_check(str(story.get("npc", "")).contains("pyramid"), "station-specific architecture")
	var alternatives: RefCounted = EngineScript.new()
	alternatives.call("begin", "lmc_p02", "en")
	var accepted: Dictionary = alternatives.call("accept", "Hi!")
	_check(bool(accepted.get("accepted", false)), "synonym accepted independently of selected default hint")
	var bad: Dictionary = alternatives.call("accept", "unrelated words")
	_check(not bool(bad.get("accepted", true)), "unrecognized question does not advance")
