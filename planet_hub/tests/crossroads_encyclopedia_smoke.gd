extends SceneTree
## godot --headless --path . --script res://planet_hub/tests/crossroads_encyclopedia_smoke.gd
const Encyclopedia = preload("res://planet_hub/scripts/crossroads_encyclopedia.gd")
const Conversation = preload("res://planet_hub/scripts/dialogue_engine.gd")
const SAVE_PATH := "user://mika_crossroads_encyclopedia.json"
var failures: int = 0

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	var had_save: bool = FileAccess.file_exists(SAVE_PATH)
	var original: String = FileAccess.get_file_as_string(SAVE_PATH) if had_save else ""
	_run()
	# A test must never overwrite an existing child's learning history.
	if had_save:
		var handle: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if handle != null:
			handle.store_string(original)
			handle.close()
	else:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Crossroads encyclopedia: ", "PASS" if failures == 0 else "%d failures" % failures)
	quit(0 if failures == 0 else 1)

func _run() -> void:
	var file: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/crossroads_encyclopedia.json"))
	_check(file is Dictionary, "JSON parses")
	if not (file is Dictionary):
		return
	var topics: Array = file.get("topics", [])
	_check(topics.size() == 12, "twelve topics")
	var groups: Array = file.get("groups", [])
	_check(groups.size() == 3, "three categories")
	var count_by_group: Dictionary = {}
	for item in topics:
		var group: String = str(item.get("group", ""))
		count_by_group[group] = int(count_by_group.get(group, 0)) + 1
		_check(item.get("questions", {}).get("ru", []).size() == 3, "three Russian questions: " + str(item.get("id", "")))
		_check(item.get("questions", {}).get("en", []).size() == 3, "three English questions: " + str(item.get("id", "")))
		_check(item.get("answers", {}).get("ru", []).size() == 3, "three Russian answers: " + str(item.get("id", "")))
		_check(item.get("answers", {}).get("en", []).size() == 3, "three English answers: " + str(item.get("id", "")))
	for group_id in ["care", "science", "universe"]:
		_check(int(count_by_group.get(group_id, 0)) == 4, "four topics in " + group_id)
	for lang in ["ru", "en", "fr", "de", "es", "pt_BR"]:
		var engine: RefCounted = Encyclopedia.new()
		var first: Dictionary = engine.call("begin", "crossroads_core", lang)
		_check(bool(first.get("available", false)) and first.get("choices", []).size() == 3, "three category hints " + lang)
		var selected: String = str(first.get("choices", [])[1])
		_check(str(engine.call("get_hint", 1)) == selected, "only selected hint " + lang)
		var group: Dictionary = engine.call("accept", selected)
		_check(bool(group.get("accepted", false)) and group.get("choices", []).size() == 3, "category selection " + lang)
		var bad: Dictionary = engine.call("accept", "nonsense unrelated")
		_check(not bool(bad.get("accepted", true)), "unrecognized does not advance " + lang)
		# An unshown correct question about gravity must still be recognized.
		var gravity_question: String = str(topics[6].get("questions", {}).get(lang, topics[6].get("questions", {}).get("en", []))[0])
		var result: Dictionary = engine.call("accept", gravity_question)
		_check(bool(result.get("accepted", false)) and str(result.get("npc", "")).length() > 35, "topic synonym outside selected category " + lang)
		_check(result.get("choices", []).size() == 3, "three next choices " + lang)
		var back: String = str(file.get("ui", {}).get(lang, {}).get("back_choice", ""))
		var returned: Dictionary = engine.call("accept", back)
		_check(returned.get("choices", []).size() == 3, "return to category menu " + lang)
	var unified: RefCounted = Conversation.new()
	var opened: Dictionary = unified.call("begin", "crossroads_core", "en")
	_check(bool(opened.get("available", false)) and opened.get("choices", []).size() == 3, "existing translator routes to encyclopedia")
	var noone: RefCounted = Conversation.new()
	var empty: Dictionary = noone.call("begin", "smc_p08", "en")
	_check(not bool(empty.get("available", true)), "uninhabited world remains without resident")
