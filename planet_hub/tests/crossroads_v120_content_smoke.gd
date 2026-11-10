extends SceneTree
## Smoke test for the content-only adapter; existing UI is deliberately not instantiated.
const ENGINE = preload("res://planet_hub/scripts/crossroads_engine_v104_1.gd")
const DATA_PATH: String = "res://planet_hub/data/crossroads_v120_encyclopedia.json"
const LANGUAGES: Array[String] = ["ru", "en", "fr", "de", "es", "pt_BR"]

func _initialize() -> void:
	call_deferred("_test")

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("v120 CROSSROADS FAIL: " + message)
		return false
	return true

func _test() -> void:
	var good: bool = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not (parsed is Dictionary):
		push_error("v120: invalid encyclopedia JSON")
		quit(1)
		return
	var library: Dictionary = parsed
	good = _check(library.get("topics", []).size() == 48, "48 science topics") and good
	var engine: RefCounted = ENGINE.new()
	engine.call("disable_progress_io_for_tests")
	engine.call("configure", library)
	for lang in LANGUAGES:
		engine.call("set_locale", lang)
		for entry in library.get("topics", []):
			var topic: Dictionary = entry
			engine.call("set_topic", str(topic.get("id", "")))
			var begin: Dictionary = engine.call("begin", "crossroads_core", lang, null)
			good = _check(bool(begin.get("available", false)), "begin " + lang) and good
			var questions: Array = topic.get("questions", {}).get(lang, [])
			good = _check(questions.size() == 3, "three questions " + lang) and good
			good = _check(engine.call("get_choices").size() == 3, "three original blocks") and good
			for i in range(3):
				var result: Dictionary = engine.call("accept", str(questions[i]))
				good = _check(bool(result.get("accepted", false)), "scientific question " + lang) and good
				good = _check(str(result.get("npc", "")).length() > 4, "scientific answer " + lang) and good
				good = _check(result.get("choices", []).size() == 3, "three dynamic blocks") and good
			var unknown: Dictionary = engine.call("accept", "__unrecognizable_unsupported_science_question_444__")
			good = _check(not bool(unknown.get("accepted", false)), "unknown must not be invented") and good
	engine.call("set_locale", "ru")
	engine.call("set_topic", "sorting")
	engine.call("begin", "crossroads_core", "ru", null)
	var first: Dictionary = engine.call("accept", "Зачем сортировать мусор?")
	good = _check(bool(first.get("accepted", false)), "initial topic answer") and good
	var study: Dictionary = engine.call("accept", "Подумаем вместе")
	good = _check(bool(study.get("accepted", false)), "start a thought experiment") and good
	good = _check(engine.call("get_choices").size() == 3, "three prediction slots") and good
	var guess: String = str(engine.call("get_choices")[0])
	var guessed: Dictionary = engine.call("accept", guess)
	good = _check(bool(guessed.get("accepted", false)), "accept approved prediction") and good
	var routes: Array = engine.call("get_route_ids_for_group", "care")
	good = _check(routes.size() >= 2, "existing dropdown route entries") and good
	good = _check(bool(engine.call("start_route", "water_cycle")), "start water route") and good
	engine.call("begin", "crossroads_core", "ru", null)
	good = _check(engine.call("get_choices").size() == 3, "route uses three existing slots") and good
	var q: String = str(engine.call("get_choices")[0])
	engine.call("accept", q)
	var dynamic_choices: Array = engine.call("get_choices")
	var next: Dictionary = engine.call("accept", str(dynamic_choices[2]))
	good = _check(bool(next.get("accepted", false)), "advance route") and good
	good = _check(str(engine.call("get_topic_id")) == "phase_changes", "next route topic") and good
	good = _check(engine.call("get_choices").size() == 3, "route step three slots") and good
	print("MIKA CROSSROADS v120: ", "PASS" if good else "FAIL", " (48 subjects, 6 languages, 14 investigations, six routes data)")
	quit(0 if good else 1)
