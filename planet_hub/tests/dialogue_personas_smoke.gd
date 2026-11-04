extends SceneTree
## v101: unique per-planet characters, reused visual templates, six-locale compatibility
const EngineScript = preload("res://planet_hub/scripts/dialogue_engine.gd")
const LANGS := ["ru","en","fr","de","es","pt_BR"]
const SAVE_PATH := "user://miko_dialogue_progress.json"
var fails := 0

func _assert(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		push_error("FAIL: " + what)

func _read(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

func _start_story(id: String, locale: String) -> RefCounted:
	var dialogue: RefCounted = EngineScript.new()
	var start: Dictionary = dialogue.call("begin", id, locale)
	_assert(start.get("available", false) and start.get("choices", []).size() == 3, "NPC available for "+id+" "+locale)
	if start.get("choices", []).size() != 3:
		return dialogue
	dialogue.call("accept", str(start["choices"][0]))
	var words: Dictionary = _read("res://planet_hub/data/dialogue_phrases.json")
	var world: Dictionary = _read("res://planet_hub/data/dialogue_worlds.json").get("worlds", {}).get(id, {})
	var topic: String = str(words["station_world"][locale][0]) if bool(world.get("is_station", false)) else str(words["topics"]["world"][locale][0])
	dialogue.call("accept", topic)
	return dialogue

func _initialize() -> void:
	var had_save: bool = FileAccess.file_exists(SAVE_PATH)
	var previous: String = FileAccess.get_file_as_string(SAVE_PATH) if had_save else ""
	if had_save:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_test()
	if had_save:
		var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(previous)
			f.close()
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Local representatives smoke: ", "PASS" if fails == 0 else "%d FAILED" % fails)
	quit(0 if fails == 0 else 1)

func _test() -> void:
	var profiles: Dictionary = _read("res://planet_hub/data/representative_profiles.json").get("characters", {})
	var roster: Dictionary = _read("res://planet_hub/data/representatives.json").get("assignments", {})
	var atlas: Dictionary = _read("res://planet_hub/data/dialogue_worlds.json").get("worlds", {})
	var used_ids: Dictionary = {}
	var used_names: Dictionary = {}
	_assert(profiles.size() == 30, "30 unique local representative records")
	var inhabited := 0
	for id in atlas.keys():
		var world: Dictionary = atlas[id]
		if not bool(world.get("inhabited", false)):
			continue
		inhabited += 1
		_assert(profiles.has(id), "character for "+str(id))
		if not profiles.has(id):
			continue
		var p: Dictionary = profiles[id]
		var cid: String = str(p.get("character_id", ""))
		var name: String = str(p.get("name", ""))
		var role: String = str(p.get("role", ""))
		_assert(not used_ids.has(cid) and not used_names.has(name), "unique ID and name for "+str(id))
		used_ids[cid] = true
		used_names[name] = true
		_assert(cid == "npc_"+str(id), "stable unique NPC ID")
		_assert(not name.is_empty() and not role.is_empty() and not str(p.get("work", "")).is_empty(), "complete person card metadata")
		_assert(p.get("gender") == null, "character biography has no forced gender")
		_assert(roster.has(id), "keep original portrait assignment")
		_assert(not str(roster.get(id, {}).get("asset", "")).is_empty(), "portrait is a replaceable visual template")
		_assert(p.get("chapter_cues", []).size() == 4, "all four chapters refer to local context")
	_assert(inhabited == 30, "24 inhabited planets plus 6 stations")
	# Same portrait may occur on several worlds, but personalities and memories must not merge.
	var human_a := _start_story("mw_p01", "en")
	var human_b := _start_story("mw_p03", "en")
	_assert(str(human_a.call("_adventure_memory_key")) != str(human_b.call("_adventure_memory_key")), "same human PNG cannot merge memories")
	var lizard_a := _start_story("ngc6822_p01", "en")
	var lizard_b := _start_story("ngc6822_p03", "en")
	_assert(str(lizard_a.call("_adventure_memory_key")) != str(lizard_b.call("_adventure_memory_key")), "same lizard PNG cannot merge memories")
	_assert(str(human_a.call("_name")) == "Ari" and str(human_b.call("_name")) == "Remi", "two distinct human identities")
	_assert(str(lizard_a.call("_name")) == "Zeri" and str(lizard_b.call("_name")) == "Runi", "two distinct lizard identities")
	for loc in LANGS:
		var example: RefCounted = _start_story("mw_p02", loc)
		_assert(str(example.get("stage")) == "story", "world conversation available in locale: "+loc)
		var npc: Dictionary = example.get("_representative")
		_assert(npc.get("character_id") == "npc_mw_p02" and str(npc.get("role")).contains("computer"), "named Mars computer researcher in locale "+loc)
		var intro: Dictionary = example.call("accept", str(example.call("get_choices")[0]))
		_assert(str(example.get("stage")) == "story_adventure", "continue the four-chapter flow in locale "+loc)
		_assert(str(intro.get("npc","")).contains("Mars"), "local content personalizes the story for "+loc)
	# All game cards are outside this test and remain untouched.
