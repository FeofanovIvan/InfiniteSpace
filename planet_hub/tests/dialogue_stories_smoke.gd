extends SceneTree
## Tests 30 inhabited locations, every game locale and branch persistence.
## godot --headless --path . --script res://planet_hub/tests/dialogue_stories_smoke.gd
const EngineScript = preload("res://planet_hub/scripts/dialogue_engine.gd")
const SAVE_PATH := "user://miko_dialogue_progress.json"
const LANGS := ["ru", "en", "fr", "de", "es", "pt_BR"]
var failures: int = 0

func _check(ok: bool, desc: String) -> void:
	if ok:
		print("PASS: ", desc)
	else:
		failures += 1
		push_error("FAIL: " + desc)

func _initialize() -> void:
	var had_file: bool = FileAccess.file_exists(SAVE_PATH)
	var original: String = FileAccess.get_file_as_string(SAVE_PATH) if had_file else ""
	_verify()
	if had_file:
		var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(original)
			f.close()
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Six-race story smoke: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(0 if failures == 0 else 1)

func _verify() -> void:
	var dat: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/dialogue_story_scenes.json"))
	var atlas: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/dialogue_worlds.json"))
	var words: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/dialogue_phrases.json"))
	var quizzes: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/dialogue_story_quizzes.json"))
	_check(dat is Dictionary and atlas is Dictionary and words is Dictionary and quizzes is Dictionary, "all story JSON files parse")
	if not (dat is Dictionary and atlas is Dictionary and words is Dictionary and quizzes is Dictionary):
		return
	var scenes: Dictionary = dat.get("scenes", {})
	var places: Dictionary = atlas.get("worlds", {})
	var playable: Array[String] = []
	for id in places:
		if bool(places[id].get("inhabited", false)):
			playable.append(str(id))
	_check(playable.size() == 30 and scenes.size() == 30, "thirty inhabited locations exactly")
	for id in playable:
		_check(scenes.has(id), "unique story: " + id)
		if not scenes.has(id):
			continue
		var scene: Dictionary = scenes[id]
		_check(scene.get("responses", []).size() == 3, "three story branches: " + id)
		for lang in ["ru", "en"]:
			_check(not str(scene.get("hook", {}).get(lang, "")).is_empty(), "story intro: " + id + " " + lang)
			for response in scene.get("responses", []):
				_check(not str(response.get(lang, "")).is_empty(), "branch answer: " + id + " " + lang)
	var race_choices: Dictionary = dat.get("choices_by_race", {})
	var race_reactions: Dictionary = dat.get("reactions_by_race", {})
	var race_quizzes: Dictionary = quizzes.get("quizzes", {})
	_check(race_reactions.size() == 6 and race_quizzes.size() == 6, "all six races have localized reactions and quiz data")
	_check(race_choices.size() == 6, "six species personalities")
	for race_id in race_choices:
		for lang in LANGS:
			var c: Array = race_choices[race_id].get(lang, [])
			_check(c.size() == 3, "three localized prompts: " + race_id + " " + lang)
			_check(race_reactions.get(race_id, {}).get(lang, []).size() == 3, "three reactions per locale: " + race_id + " " + lang)
			_check(race_quizzes.get(race_id, {}).get("options", {}).get(lang, []).size() == 3, "three quiz options: " + race_id + " " + lang)
			_check(c.size() == 3 and c[0] != c[1] and c[0] != c[2] and c[1] != c[2], "unique prompts per branch: " + race_id + " " + lang)
	var run_count: int = 0
	for id in playable:
		var is_station: bool = bool(places[id].get("is_station", false))
		for lang in LANGS:
			var e: RefCounted = EngineScript.new()
			var welcome: Dictionary = e.call("begin", id, lang)
			if not bool(welcome.get("available", false)) or welcome.get("choices", []).size() != 3:
				_check(false, "welcome: " + id + " " + lang)
				continue
			var greeting: Dictionary = e.call("accept", str(welcome["choices"][1]))
			_check(bool(greeting.get("accepted", false)), "greeting: " + id + " " + lang)
			var question: String = str(words.get("station_world", {}).get(lang, [])[0]) if is_station else str(words.get("topics", {}).get("world", {}).get(lang, [])[0])
			var story: Dictionary = e.call("accept", question)
			_check(bool(story.get("accepted", false)) and str(e.get("stage")) == "story", "world opens story: " + id + " " + lang)
			var options: Array = story.get("choices", [])
			_check(options.size() == 3, "three story choices: " + id + " " + lang)
			if options.size() != 3:
				continue
			var invalid: Dictionary = e.call("accept", "a nonsensical string not in the story")
			_check(not bool(invalid.get("accepted", true)) and str(e.get("stage")) == "story", "unknown story choice leaves state: " + id + " " + lang)
			# Every branch can be selected, regardless of the highlighted default.
			var branch: Dictionary = e.call("accept", str(options[2]))
			_check(bool(branch.get("accepted", false)), "third branch accepted: " + id + " " + lang)
			_check(str(e.get("stage")) == "story_adventure" and branch.get("choices", []).size() == 3, "third story branch opens character adventure: " + id + " " + lang)
			var adventure_options: Array = branch.get("choices", [])
			if adventure_options.size() != 3:
				continue
			var adventure_result: Dictionary = e.call("accept", str(adventure_options[1]))
			_check(bool(adventure_result.get("accepted", false)) and str(e.get("stage")) == "story_quiz", "adventure resolves and continues to optional quiz: " + id + " " + lang)
			var quiz_options: Array = adventure_result.get("choices", [])
			if quiz_options.size() != 3:
				continue
			var quiz_wrong: Dictionary = e.call("accept", str(quiz_options[1]))
			_check(not bool(quiz_wrong.get("accepted", true)) and str(e.get("stage")) == "story_quiz", "wrong quiz answer does not advance: " + id + " " + lang)
			var quiz_ok: Dictionary = e.call("accept", str(quiz_options[0]))
			_check(bool(quiz_ok.get("accepted", false)) and str(e.get("stage")) == "choose", "correct answer returns to conversation: " + id + " " + lang)
			run_count += 1
	_check(run_count == 180, "all 30 locations × 6 locales exercised")
	# Returning to a familiar world should acknowledge the previous conversation.
	var repeat: RefCounted = EngineScript.new()
	repeat.call("begin", "mw_p01", "en")
	repeat.call("accept", "Hello!")
	var again: Dictionary = repeat.call("accept", "Tell me about this world.")
	_check(str(again.get("npc", "")).contains("Remember"), "revisit callback acknowledges past talk")
	# Child may ask a normal topic while a three-choice story is on screen.
	var leap: RefCounted = EngineScript.new()
	leap.call("begin", "m33_p02", "en")
	leap.call("accept", "Hello!")
	leap.call("accept", "Tell me about this world.")
	var alternative: Dictionary = leap.call("accept", "Tell me about your species.")
	_check(bool(alternative.get("accepted", false)), "normal topic accepted outside story choices")
	var lifeless: RefCounted = EngineScript.new()
	var disallowed: Dictionary = lifeless.call("begin", "m33_p08", "en")
	_check(not bool(disallowed.get("available", true)), "uninhabited world has no story or NPC")
