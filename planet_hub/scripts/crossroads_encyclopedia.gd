extends RefCounted
## The Living World encyclopedia is independent of the six-race dialogue flow.
## Three displayed question choices; only the selected choice is a typing hint.
## Recognize all known synonymous questions; save topics locally, never ask for PII.

const DATA_PATH: String = "res://planet_hub/data/crossroads_encyclopedia.json"
const SAVE_PATH: String = "user://mika_crossroads_encyclopedia.json"
const CORE_ID: String = "crossroads_core"
const LOCALES := ["ru", "en", "fr", "de", "es", "pt_BR"]

var language: String = "ru"
var stage: String = "group"
var choices: Array[String] = []
var _data: Dictionary = {}
var _progress: Dictionary = {}
var _group_id: String = ""
var _visit: int = 0

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func _save() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_progress, "  "))
		file.close()

func _lang(value: Variant) -> String:
	if value is Dictionary:
		return str(value.get(language, value.get("en", value.get("ru", ""))))
	return str(value)

func _phrase(key: String) -> String:
	var ui: Dictionary = _data.get("ui", {})
	var loc: Dictionary = ui.get(language, ui.get("en", {}))
	return str(loc.get(key, key))

func _normalize(value: String) -> String:
	var output: String = value.to_lower().strip_edges()
	for ch in ["!", "?", ".", ",", ":", ";", "¡", "¿", "«", "»", "'", "\"", "—", "–"]:
		output = output.replace(ch, " ")
	while output.contains("  "):
		output = output.replace("  ", " ")
	return output.strip_edges()

func _same(text: String, candidates: Array) -> bool:
	var normalized: String = _normalize(text)
	for candidate in candidates:
		if normalized == _normalize(str(candidate)):
			return true
	return false

func _localized_questions(entry: Dictionary) -> Array:
	var q: Dictionary = entry.get("questions", {})
	return q.get(language, q.get("en", []))

func _all_questions(entry: Dictionary) -> Array:
	var q: Dictionary = entry.get("questions", {})
	var candidates: Array = []
	for local_set in q.values():
		if local_set is Array:
			candidates.append_array(local_set)
	return candidates

func _find_topic(text: String) -> Dictionary:
	for item in _data.get("topics", []):
		if item is Dictionary and _same(text, _all_questions(item)):
			return item
	return {}

func _find_group(text: String) -> Dictionary:
	for item in _data.get("groups", []):
		if item is Dictionary:
			var prompt: Dictionary = item.get("prompt", {})
			if _same(text, prompt.values()):
				return item
	return {}

func _choose_group() -> Dictionary:
	stage = "group"
	choices.clear()
	for item in _data.get("groups", []):
		choices.append(_lang(item.get("prompt", {})))
	return {"accepted": true, "available": true, "npc": _phrase("back"), "choices": choices.duplicate()}

func _topic_choices() -> Array[String]:
	# Three question strings total; after at least one answer, one is the
	# explicit way back to the three encyclopedia categories.
	var candidates: Array[String] = []
	var seen: Dictionary = _progress.get("seen", {})
	var group_topics: Array = []
	for item in _data.get("topics", []):
		if item is Dictionary and str(item.get("group", "")) == _group_id:
			group_topics.append(item)
	# First topics not yet asked, then already seen. No random duplicates.
	group_topics.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_count: int = int(seen.get(str(a.get("id", "")), 0))
		var b_count: int = int(seen.get(str(b.get("id", "")), 0))
		if a_count == b_count:
			return str(a.get("id", "")) < str(b.get("id", ""))
		return a_count < b_count
	)
	var room: int = 3 if _group_is_new() else 2
	for item in group_topics:
		if candidates.size() >= room:
			break
		var variants: Array = _localized_questions(item)
		if variants.is_empty():
			continue
		var topic_id: String = str(item.get("id", ""))
		var variant_index: int = int(seen.get(topic_id, 0)) % variants.size()
		candidates.append(str(variants[variant_index]))
	if room == 2:
		candidates.append(_phrase("back_choice"))
	return candidates

func _group_is_new() -> bool:
	var seen: Dictionary = _progress.get("seen", {})
	for item in _data.get("topics", []):
		if item is Dictionary and str(item.get("group", "")) == _group_id:
			if int(seen.get(str(item.get("id", "")), 0)) > 0:
				return false
	return true

func _choose_topics(prefix: String) -> Dictionary:
	stage = "topic"
	choices = _topic_choices()
	return {"accepted": true, "available": true, "npc": prefix, "choices": choices.duplicate()}

func begin(target: String, locale: String, _profile: Node = null) -> Dictionary:
	_data = _read(DATA_PATH)
	if target != CORE_ID or _data.is_empty():
		return {"accepted": false, "available": false, "npc": "", "choices": []}
	language = locale if LOCALES.has(locale) else "en"
	_progress = _read(SAVE_PATH)
	if not _progress.has("seen"):
		_progress["seen"] = {}
	_visit = int(_progress.get("visits", 0)) + 1
	_progress["visits"] = _visit
	_save()
	_group_id = ""
	var welcome: Dictionary = _choose_group()
	welcome["npc"] = _phrase("greeting")
	return welcome

func get_choices() -> Array[String]:
	return choices.duplicate()

func get_hint(selected_index: int) -> String:
	if selected_index >= 0 and selected_index < choices.size():
		return choices[selected_index]
	return ""

func accept(text: String) -> Dictionary:
	if _normalize(text).is_empty():
		return {"accepted": false, "npc": _phrase("misunderstood"), "choices": choices.duplicate()}
	if stage == "group":
		var group: Dictionary = _find_group(text)
		if group.is_empty():
			# A child who already knows a question can ask it immediately.
			var direct: Dictionary = _find_topic(text)
			if not direct.is_empty():
				_group_id = str(direct.get("group", ""))
				return _answer(direct)
			return {"accepted": false, "npc": _phrase("misunderstood"), "choices": choices.duplicate()}
		_group_id = str(group.get("id", ""))
		return _choose_topics(_phrase("group_intro"))
	if stage == "topic":
		for local in _data.get("ui", {}).values():
			if local is Dictionary and _normalize(text) == _normalize(str(local.get("back_choice", ""))):
				return _choose_group()
		var topic: Dictionary = _find_topic(text)
		if topic.is_empty():
			return {"accepted": false, "npc": _phrase("misunderstood"), "choices": choices.duplicate()}
		_group_id = str(topic.get("group", _group_id))
		return _answer(topic)
	return {"accepted": false, "npc": _phrase("misunderstood"), "choices": choices.duplicate()}

func _answer(topic: Dictionary) -> Dictionary:
	var id: String = str(topic.get("id", ""))
	var seen: Dictionary = _progress.get("seen", {})
	var previous: int = int(seen.get(id, 0))
	var responses: Dictionary = topic.get("answers", {})
	# Native RU/EN explanatory prose. Missing locale deliberately falls
	# back to English, never manufactures a translated science claim.
	var variants: Array = responses.get(language, responses.get("en", []))
	var answer: String = str(variants[previous % variants.size()]) if not variants.is_empty() else ""
	seen[id] = previous + 1
	_progress["seen"] = seen
	_progress["last_topic"] = id
	_save()
	return _choose_topics(answer + "\n\n" + _phrase("again"))
