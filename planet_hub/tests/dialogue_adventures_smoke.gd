extends SceneTree
## No visual/UI changes: verifies the deterministic adventure dialog layer.
## godot --headless --path . --script res://planet_hub/tests/dialogue_adventures_smoke.gd
const EngineScript = preload("res://planet_hub/scripts/dialogue_engine.gd")
const SAVE_PATH: String = "user://miko_dialogue_progress.json"
const LANGS := ["ru","en","fr","de","es","pt_BR"]
const EXAMPLES := ["mw_p01","lmc_p02","smc_p01","ngc6822_p01","m31_p03","m33_p01"]
var fails: int = 0
var _words: Dictionary = {}
var _adventures: Dictionary = {}

func _check(ok: bool, explanation: String) -> void:
	if not ok:
		fails += 1
		push_error("FAIL: " + explanation)

func _delete_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _initialize() -> void:
	var old_exists: bool = FileAccess.file_exists(SAVE_PATH)
	var old_text: String = FileAccess.get_file_as_string(SAVE_PATH) if old_exists else ""
	_delete_test_save()
	_verify()
	_delete_test_save()
	if old_exists:
		var handle: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if handle != null:
			handle.store_string(old_text)
			handle.close()
	print("Dialogue adventures smoke: ", "PASS" if fails == 0 else "%d FAILED" % fails)
	quit(0 if fails == 0 else 1)

func _read_json(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}

func _open_story(target: String, lang: String) -> RefCounted:
	var d: RefCounted = EngineScript.new()
	var greeting: Dictionary = d.call("begin", target, lang)
	_check(greeting.get("choices", []).size() == 3, "greeting contains three choices " + target + " " + lang)
	if greeting.get("choices", []).size() != 3:
		return d
	var hello: Dictionary = d.call("accept", str(greeting["choices"][1]))
	_check(bool(hello.get("accepted", false)), "greeting accepted " + target + " " + lang)
	var world_question: String = str(_words.get("topics", {}).get("world", {}).get(lang, [])[0])
	var world: Dictionary = d.call("accept", world_question)
	_check(bool(world.get("accepted", false)) and str(d.get("stage")) == "story", "world story opened " + target + " " + lang)
	return d

func _verify() -> void:
	_adventures = _read_json("res://planet_hub/data/dialogue_adventures.json")
	_words = _read_json("res://planet_hub/data/dialogue_phrases.json")
	var atlas: Dictionary = _read_json("res://planet_hub/data/dialogue_worlds.json")
	var races: Dictionary = _adventures.get("races", {})
	_check(races.size() == 6, "six races have independent mini-adventures")
	for race_id in races:
		var episodes: Array = races[race_id]
		_check(episodes.size() == 2, "two story episodes for " + race_id)
		for episode in episodes:
			_check(episode.get("choices", []).size() == 3 and episode.get("outcomes", []).size() == 3, "three causes and consequences: " + race_id)
			for loc in LANGS:
				_check(not str(episode.get("intro", {}).get(loc, "")).is_empty(), "intro localized: " + race_id + " " + loc)
				for choice in episode.get("choices", []):
					_check(not str(choice.get(loc, "")).is_empty(), "choice localized: " + race_id + " " + loc)
				for outcome in episode.get("outcomes", []):
					_check(not str(outcome.get(loc, "")).is_empty(), "consequence localized: " + race_id + " " + loc)
	var checks: int = 0
	for target in EXAMPLES:
		var race_id: String = str(atlas.get("worlds", {}).get(target, {}).get("race", ""))
		_check(races.has(race_id), "race mapping for " + target)
		for lang in LANGS:
			_delete_test_save()
			var first: RefCounted = _open_story(target, lang)
			var story_options: Array = first.call("get_choices")
			if story_options.size() != 3:
				continue
			var adventure: Dictionary = first.call("accept", str(story_options[0]))
			_check(bool(adventure.get("accepted", false)) and str(first.get("stage")) == "story_adventure", "first episode: " + target + " " + lang)
			var options: Array = adventure.get("choices", [])
			if options.size() != 3:
				_check(false, "adventure contains three choices: " + target + " " + lang)
				continue
			_check(str(first.call("get_hint", 2)) == str(options[2]), "only selected hint is returned: " + lang)
			var wrong: Dictionary = first.call("accept", "unrelated nonsensical words")
			_check(not bool(wrong.get("accepted", true)) and str(first.get("stage")) == "story_adventure", "bad input does not complete the adventure")
			var result: Dictionary = first.call("accept", str(options[1]))
			_check(bool(result.get("accepted", false)) and str(first.get("stage")) == "choose", "first adventure solved without quiz")
			var saved: Dictionary = first.get("_state")
			_check(saved.get("character_adventures", {}).size() == 1, "no typed child info stored with adventure")
			var first_count: int = int(first.get("_visited").get("adventures_completed", 0))
			_check(first_count == 1, "one completed episode in location")
			var second: RefCounted = _open_story(target, lang)
			var next_story: Array = second.call("get_choices")
			var event_2: Dictionary = second.call("accept", str(next_story[0]))
			var memory_prefix: String = str(_adventures.get("revisit_prefix", {}).get(lang, ""))
			var marker: String = memory_prefix.split("%s")[0].strip_edges()
			_check(marker.is_empty() or str(event_2.get("npc", "")).contains(marker), "character recalls previous choice: " + target + " " + lang)
			var next_options: Array = event_2.get("choices", [])
			if next_options.size() != 3:
				_check(false, "second episode contains three choices")
				continue
			var solve_second: Dictionary = second.call("accept", str(next_options[2]))
			_check(bool(solve_second.get("accepted", false)), "second episode completed " + target + " " + lang)
			var memory: Dictionary = second.get("_state").get("character_adventures", {})
			var key: String = str(second.call("_adventure_memory_key"))
			var record: Dictionary = memory.get(key, {})
			_check(int(record.get("completed", 0)) == 2 and record.get("history", []).size() == 2, "two chapters saved with choices")
			checks += 1
	_check(checks == 36, "six races across six locales twice")
	# A character is still remembered on a different planet, but not by another character.
	_delete_test_save()
	var human_a: RefCounted = _open_story("mw_p01", "en")
	var first_result: Dictionary = human_a.call("accept", str(human_a.call("get_choices")[0]))
	human_a.call("accept", str(first_result["choices"][0]))
	var human_same: RefCounted = _open_story("mw_p03", "en")
	var same_result: Dictionary = human_same.call("accept", str(human_same.call("get_choices")[0]))
	_check(not str(same_result["npc"]).contains("I remember our last choice"), "same portrait is NOT the same person on different planets")
	var human_other: RefCounted = _open_story("mw_p02", "en")
	var other_result: Dictionary = human_other.call("accept", str(human_other.call("get_choices")[0]))
	_check(not str(other_result["npc"]).contains("I remember our last choice"), "different representative does not inherit memory")
	# The third v97 choice still leads to an optional race quiz, after the adventure.
	_delete_test_save()
	var quiz_dialog: RefCounted = _open_story("m31_p03", "en")
	var story_options: Array = quiz_dialog.call("get_choices")
	var event: Dictionary = quiz_dialog.call("accept", str(story_options[2]))
	_check(str(quiz_dialog.get("stage")) == "story_adventure", "quiz path starts with adventure")
	var post: Dictionary = quiz_dialog.call("accept", str(event["choices"][0]))
	_check(str(quiz_dialog.get("stage")) == "story_quiz" and post.get("choices", []).size() == 3, "adventure continues to existing quiz")
	# Child can skip without penalty or ask a known unrelated topic.
	_delete_test_save()
	var skip_dialog: RefCounted = _open_story("smc_p01", "en")
	skip_dialog.call("accept", str(skip_dialog.call("get_choices")[0]))
	var skipped: Dictionary = skip_dialog.call("accept", "Skip")
	_check(bool(skipped.get("accepted", false)) and str(skip_dialog.get("stage")) == "choose", "optional episode can be skipped")
	_check(skip_dialog.get("_state").get("character_adventures", {}).is_empty(), "skip does not register a completed episode")
	var leap: RefCounted = _open_story("m33_p01", "en")
	leap.call("accept", str(leap.call("get_choices")[0]))
	var new_topic: Dictionary = leap.call("accept", "Tell me about your species.")
	_check(bool(new_topic.get("accepted", false)) and str(leap.get("stage")) in ["choose","personal"], "general topic interrupts an optional adventure")
	# All options are recognized across supported languages, not just visible text.
	_delete_test_save()
	var multi: RefCounted = _open_story("lmc_p02", "ru")
	multi.call("accept", str(multi.call("get_choices")[0]))
	var english_options: Array = races["mold"][0]["choices"]
	var foreign_choice: String = str(english_options[2]["en"])
	var foreign: Dictionary = multi.call("accept", foreign_choice)
	_check(bool(foreign.get("accepted", false)) and str(multi.get("stage")) == "choose", "English alternative accepted while Russian hints stay selected")
	var uninhabited: RefCounted = EngineScript.new()
	var absent: Dictionary = uninhabited.call("begin", "m33_p08", "en")
	_check(not bool(absent.get("available", true)), "uninhabited planets have no representatives")
