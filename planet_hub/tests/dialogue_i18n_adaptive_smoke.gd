extends SceneTree
## v106 localization regression test. No GUI layout is changed or required.
## godot --headless --path . --script res://planet_hub/tests/dialogue_i18n_adaptive_smoke.gd
const Dialogue = preload("res://planet_hub/scripts/dialogue_engine.gd")
const SAVE_PATH := "user://miko_dialogue_progress.json"
const LANGS := ["ru", "en", "fr", "de", "es", "pt_BR"]
var failures: int = 0

func _ok(value: bool, what: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + what)

func _data(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}

func _initialize() -> void:
	var existed: bool = FileAccess.file_exists(SAVE_PATH)
	var saved: String = FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
	if existed:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_verify()
	if existed:
		var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(saved)
			f.close()
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Six-language adaptive dialogue smoke: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(0 if failures == 0 else 1)

func _verify() -> void:
	var names: Dictionary = _data("res://planet_hub/data/representative_profiles.json").get("characters", {})
	var atlas: Dictionary = _data("res://planet_hub/data/dialogue_worlds.json")
	var worlds: Dictionary = atlas.get("worlds", {})
	var scenes: Dictionary = _data("res://planet_hub/data/dialogue_story_scenes.json").get("scenes", {})
	var race_data: Dictionary = atlas.get("races", {})
	var replies: Dictionary = _data("res://planet_hub/data/dialogue_responses_i18n.json").get("locales", {})
	var words: Dictionary = _data("res://planet_hub/data/dialogue_phrases.json")
	_ok(names.size() == 30 and scenes.size() == 30, "30 location-linked characters and stories")
	_ok(replies.size() == 6, "six reply pattern sets")
	var checked: int = 0
	for loc in LANGS:
		var r: Dictionary = replies.get(loc, {})
		_ok(r.has("self_young") and r.has("story_identity") and r.has("age"), "age-aware response patterns " + loc)
		for race in race_data:
			var info: Dictionary = race_data[race]
			_ok(not str(info.get("about_" + loc, "")).is_empty(), "about the species translated " + loc + " " + race)
			_ok(not str(info.get("ability_" + loc, "")).is_empty(), "ability translated " + loc + " " + race)
			_ok(not str(info.get("energy_" + loc, "")).is_empty(), "energy translated " + loc + " " + race)
			_ok(not str(info.get("greeting", {}).get(loc, "")).is_empty(), "race greeting " + loc + " " + race)
		for id in names:
			var person: Dictionary = names[id]
			var local: Dictionary = person.get("i18n", {}).get(loc, {})
			_ok(not str(person.get("name_localized", {}).get(loc, "")).is_empty(), "name " + loc + " " + id)
			for key in ["role", "work", "mystery", "share"]:
				_ok(not str(local.get(key, "")).is_empty(), "character " + key + " " + loc + " " + id)
			_ok(local.get("chapter_cues", []).size() == 4, "all 4 location-aware chapters " + id + " " + loc)
			var region: Dictionary = worlds.get(id, {})
			for key in ["name", "world", "structure"]:
				_ok(not str(region.get(key, {}).get(loc, "")).is_empty(), "location " + key + " " + loc + " " + id)
			var episode: Dictionary = scenes.get(id, {})
			_ok(not str(episode.get("hook", {}).get(loc, "")).is_empty(), "story hook " + loc + " " + id)
			for response in episode.get("responses", []):
				_ok(not str(response.get(loc, "")).is_empty(), "story branch translated " + loc + " " + id)
			var dialogue: RefCounted = Dialogue.new()
			var hello: Dictionary = dialogue.call("begin", id, loc)
			_ok(bool(hello.get("available", false)), "begin conversation " + loc + " " + id)
			var greeting: Array = hello.get("choices", [])
			if greeting.size() != 3:
				_ok(false, "three greeting choices " + loc + " " + id)
				continue
			var greet_reply: Dictionary = dialogue.call("accept", str(greeting[0]))
			_ok(bool(greet_reply.get("accepted", false)), "greeting recognized " + loc + " " + id)
			var question: String = str(words["topics"]["self"][loc][0])
			var about: Dictionary = dialogue.call("accept", question)
			_ok(bool(about.get("accepted", false)) and str(about.get("npc", "")).contains(str(person["name_localized"][loc])), "self-introduction localized " + loc + " " + id)
			_ok(str(dialogue.call("_role")) == str(local["role"]), "role of representative, not portrait " + loc + " " + id)
			checked += 1
	_ok(checked == 180, "180 representative-locale interactions")
	# A child can type a supported alternative language, regardless of interface language.
	var swapped: RefCounted = Dialogue.new()
	var begin: Dictionary = swapped.call("begin", "mw_p02", "pt_BR")
	_ok(bool(begin.get("available", false)), "cross-language test setup")
	var foreign: Dictionary = swapped.call("accept", str(words["personal"]["greeting"]["fr"][0]))
	_ok(bool(foreign.get("accepted", false)), "French greeting understood with Brazilian Portuguese selected")
	var spanish: Dictionary = swapped.call("accept", str(words["topics"]["self"]["es"][0]))
	_ok(bool(spanish.get("accepted", false)) and str(spanish.get("npc", "")).contains("Nevi"), "Spanish intent understood with Portuguese responses")
	# Source English must NOT leak into the biography of a French character.
	var fr: RefCounted = Dialogue.new()
	fr.call("begin", "mw_p02", "fr")
	_ok(str(fr.call("_personal_work")).contains("Mars"), "French Mars biography is location-aware")
	_ok(not str(fr.call("_personal_work")).begins_with("I "), "French personal work has no English fallback")
	# Different planets with the same PNG remain separate identities.
	var first: RefCounted = Dialogue.new()
	var second: RefCounted = Dialogue.new()
	first.call("begin", "mw_p01", "en")
	second.call("begin", "mw_p03", "en")
	_ok(str(first.call("_adventure_memory_key")) != str(second.call("_adventure_memory_key")), "reused PNG never merges memory")
