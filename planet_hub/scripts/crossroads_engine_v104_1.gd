extends RefCounted
## Content-only adapter for the ORIGINAL v96/v98 TranslatorTablet.
## No replacement keyboard, chat bubbles, hint system or send controls.
const MATCHER = preload("res://planet_hub/scripts/dialogue_input_matcher.gd")
const LANGUAGES: Array[String] = ["ru", "en", "fr", "de", "es", "pt_BR"]
var _library: Dictionary = {}
var _locale: String = "en"
var _topic: Dictionary = {}

func configure(encyclopedia: Dictionary) -> void:
	_library = encyclopedia

func set_topic(topic_id: String) -> void:
	_topic = {}
	for item in _library.get("topics", []):
		if item is Dictionary and str(item.get("id", "")) == topic_id:
			_topic = item
			return

func set_locale(value: String) -> void:
	_locale = value if LANGUAGES.has(value) else "en"

func _localized(value: Variant) -> String:
	if value is Dictionary:
		return str(value.get(_locale, value.get("en", "")))
	return str(value)

func get_choices() -> Array:
	var by_language: Dictionary = _topic.get("questions", {})
	return by_language.get(_locale, by_language.get("en", []))

func get_hint(index: int) -> String:
	var choices: Array = get_choices()
	return str(choices[index]) if index >= 0 and index < choices.size() else ""

func begin(_world_id: String, language: String, _profile_store: Node) -> Dictionary:
	set_locale(language)
	var introduction: String = _localized(_topic.get("title", {}))
	var group_id: String = str(_topic.get("group", ""))
	for group_entry in _library.get("groups", []):
		if group_entry is Dictionary and str(group_entry.get("id", "")) == group_id:
			introduction = _localized(group_entry.get("prompt", {}))
			break
	return {"available": not _topic.is_empty(), "npc": introduction, "choices": get_choices()}

func accept(typed: String) -> Dictionary:
	if _topic.is_empty():
		return {"accepted": false, "npc": ""}
	var by_language: Dictionary = _topic.get("questions", {})
	var winner: int = -1
	var best_score: int = MATCHER.NO_MATCH
	# Correct alternatives are accepted independently of which cloud is selected.
	# Prefer the displayed language; the others are allowed for bilingual children.
	var search_languages: Array[String] = [_locale]
	for lang in LANGUAGES:
		if lang != _locale:
			search_languages.append(lang)
	for lang in search_languages:
		var choices: Array = by_language.get(lang, [])
		for index in range(choices.size()):
			var score: int = MATCHER.score(typed, str(choices[index]))
			if score < best_score:
				best_score = score
				winner = index
		if best_score == 0:
			break
	if winner < 0:
		return {"accepted": false, "npc": ""}
	var answer_languages: Dictionary = _topic.get("answers", {})
	var answers: Array = answer_languages.get(_locale, answer_languages.get("en", []))
	if winner >= answers.size():
		return {"accepted": false, "npc": ""}
	return {"accepted": true, "npc": str(answers[winner]), "choices": get_choices()}
